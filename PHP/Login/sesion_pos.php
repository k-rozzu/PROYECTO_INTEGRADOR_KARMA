<?php
declare(strict_types=1);

/* KARMA · Sesión del PUNTO DE VENTA (usuarios del sistema de la tabla `usuarios`: Cajero, Gerente, Administrador).
   Es una sesión distinta a la de los clientes del Catálogo: cookie KARMAPOS (POS) vs KARMACLIENTE (Catálogo),
   así un cliente con sesión en la tienda en línea NUNCA queda dentro del Punto de Venta. */

// Nombre de la cookie de sesión del POS
const POS_SESION = 'KARMAPOS';
// Roles que pueden abrir el Punto de Venta (agregar 'Gerente' aquí si en el futuro también deben entrar)
const POS_ROLES_PERMITIDOS = [
    'Cajero',
    'Gerente',
    'Administrador General',
    'Admin_General'
];
// ¿La petición llegó por HTTPS? (también detrás de un proxy o balanceador del hosting que avisa con X-Forwarded-Proto)
function karmaEsHttps(): bool {
    if (!empty($_SERVER['HTTPS']) && strtolower((string)$_SERVER['HTTPS']) !== 'off') return true;
    if ((string)($_SERVER['SERVER_PORT'] ?? '') === '443') return true;
    return strtolower((string)($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https';
}

// Abre la sesión del POS con cookie solo-HTTP y SameSite=Lax (protege contra robo de cookie y CSRF).
// En el dominio público (HTTPS) la cookie además se marca Secure para que nunca viaje sin cifrar.
function posIniciarSesion(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');
    session_name(POS_SESION);
    session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'httponly' => true, 'samesite' => 'Lax', 'secure' => karmaEsHttps()]);
    session_start();
}

/* ===== Protección CSRF de la sesión del sistema (POS, paneles de administrador y gerente, cambio de contraseña) ===== */

// Token CSRF de la sesión (las páginas lo publican en <meta name="karma-csrf"> o lo piden a PHP/Login/cuenta.php)
function posTokenCsrf(): string {
    posIniciarSesion();
    if (empty($_SESSION['pos_csrf'])) $_SESSION['pos_csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['pos_csrf'];
}

// Revisa que la petición traiga el token CSRF de esta sesión en el encabezado X-CSRF-Token (comparación en tiempo constante)
function posCsrfValido(): bool {
    $recibido = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    $esperado = (string)($_SESSION['pos_csrf'] ?? '');
    return $recibido !== '' && $esperado !== '' && hash_equals($esperado, $recibido);
}

// ¿La petición viene de una página de este mismo sitio? Revisa Origin (o Referer). Sin ninguno de los dos se acepta,
// porque los navegadores siempre mandan Origin en un POST hecho con fetch y una página ajena no puede quitarlo
function posMismoOrigen(): bool {
    $origen = (string)($_SERVER['HTTP_ORIGIN'] ?? $_SERVER['HTTP_REFERER'] ?? '');
    if ($origen === '') return true;
    $partes = parse_url($origen);
    $hostOrigen = ($partes['host'] ?? '') . (isset($partes['port']) ? ':' . $partes['port'] : '');
    return strcasecmp($hostOrigen, (string)($_SERVER['HTTP_HOST'] ?? '')) === 0;
}

// Para las acciones que modifican datos: solo POST, con cuerpo JSON y desde este mismo sitio.
// Un formulario de otra página no puede mandar JSON sin pasar por CORS, así que esto frena el CSRF aunque el navegador
// sea viejo y no respete SameSite. Regresa el motivo del rechazo o null si la petición es válida.
function posRechazoEscritura(): ?string {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') return 'Usa POST.';
    if (stripos((string)($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json') !== 0) return 'Formato de petición no válido.';
    if (!posMismoOrigen()) return 'Origen no permitido.';
    return null;
}

/* ===== Freno de intentos por dirección IP (login, cambio de contraseña, traductor) =====
   Complementa al freno por sesión: quien borra su cookie para seguir probando contraseñas también queda detenido.
   Guarda las marcas de tiempo en la carpeta temporal del servidor (no necesita tablas nuevas). */

// Archivo de intentos para una clave ("login", "traductor"…) y la IP de la petición
function karmaArchivoLimite(string $clave): string {
    $carpeta = rtrim(sys_get_temp_dir(), '/\\') . DIRECTORY_SEPARATOR . 'karma_limites';
    if (!is_dir($carpeta)) @mkdir($carpeta, 0700, true);
    $ip = (string)($_SERVER['REMOTE_ADDR'] ?? 'desconocida');
    return $carpeta . DIRECTORY_SEPARATOR . hash('sha256', $clave . '|' . $ip) . '.json';
}

// Lee las marcas de tiempo vigentes (dentro de la ventana) de una clave
function karmaLeerMarcas(string $clave, int $ventana): array {
    $archivo = karmaArchivoLimite($clave);
    if (!is_file($archivo)) return [];
    $marcas = json_decode((string)@file_get_contents($archivo), true);
    $limite = time() - $ventana;
    return array_values(array_filter(is_array($marcas) ? $marcas : [], fn($t) => is_int($t) && $t > $limite));
}

// ¿Ya se alcanzaron $max intentos fallidos en los últimos $ventana segundos?
function karmaDemasiadosFallos(string $clave, int $max, int $ventana): bool {
    return count(karmaLeerMarcas($clave, $ventana)) >= $max;
}

// Registra un intento (fallido o, en el traductor, cualquier petición) para la IP actual
function karmaRegistrarFallo(string $clave, int $ventana = 600): void {
    $marcas = karmaLeerMarcas($clave, $ventana);
    $marcas[] = time();
    @file_put_contents(karmaArchivoLimite($clave), json_encode(array_slice($marcas, -200)), LOCK_EX);
}

/* ===== Cambio de contraseña obligatorio (contraseña temporal que puso el administrador) ===== */

// ¿El usuario todavía usa la contraseña temporal con la que lo dieron de alta? (columna de Database/avisos_privacidad.sql;
// si la base aún no tiene esa columna, nunca se exige el cambio)
function posDebeCambiarPassword(array $usuario): bool {
    return !empty($usuario['debe_cambiar_password']);
}

// Ruta a la pantalla de cambio de contraseña desde PHP/PuntoDeVenta/ (o cualquier carpeta hermana dentro de PHP/)
function posRutaCambioPassword(): string {
    return '../Login/cambiar_password.php?forzado=1';
}

// Ruta a la pantalla de login existente (index.html en la raíz del proyecto) desde PHP/PuntoDeVenta/
function posRutaLogin(): string {
    return '../../index.html?destino=pos';
}

// Guarda en la sesión al usuario que acaba de autenticarse (cambia el id de sesión para evitar fijación)
function posGuardarUsuario(array $usuario): void {
    posIniciarSesion();
    session_regenerate_id(true);
    $_SESSION['pos_usuario'] = [
        'id' => (int)$usuario['id_usuario'],
        'nombre' => (string)$usuario['nombre'],
        'correo' => (string)$usuario['correo'],
        'rol' => (string)$usuario['nombre_rol'],
        'id_sucursal' => $usuario['id_sucursal'] !== null ? (int)$usuario['id_sucursal'] : null,
        'desde' => time()
    ];
}

// Usuario del POS en sesión, revalidado contra la BD en cada petición (si lo desactivan, pierde el acceso)
function posUsuarioValidado(PDO $pdo): ?array {
    posIniciarSesion();
    $sesion = $_SESSION['pos_usuario'] ?? null;
    if (!$sesion || empty($sesion['id'])) return null;
    // u.* trae también las columnas opcionales (debe_cambiar_password) sin fallar en bases que todavía no las tienen
    $stmt = $pdo->prepare("
        SELECT u.*, r.nombre_rol
        FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.id_usuario = ? LIMIT 1
    ");
    $stmt->execute([(int)$sesion['id']]);
    $u = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$u || $u['estado'] !== 'activo' || !in_array($u['nombre_rol'], POS_ROLES_PERMITIDOS, true)) return null;
    unset($u['password_hash']);
    return $u;
}

// Para index.php del POS: sin sesión válida de Cajero se regresa a la pantalla de login;
// con la contraseña temporal todavía activa se manda primero a cambiarla
function posRequerirPagina(PDO $pdo): array {
    $u = posUsuarioValidado($pdo);
    if (!$u) {
        header('Location: ' . posRutaLogin());
        exit;
    }
    if (posDebeCambiarPassword($u)) {
        header('Location: ' . posRutaCambioPassword());
        exit;
    }
    return $u;
}

// Respuesta JSON para las APIs cuando el usuario aún tiene su contraseña temporal (el JS lo manda a cambiarla)
function posResponderCambioPassword(): never {
    http_response_code(403);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'ok' => false,
        'error' => 'Antes de continuar debes cambiar tu contraseña temporal.',
        'cambiar_password' => true
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Para api.php del POS: sin sesión válida responde 401 en JSON (el JS redirige al login)
function posRequerirApi(PDO $pdo): array {
    $u = posUsuarioValidado($pdo);
    if (!$u) {
        http_response_code(401);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => false, 'error' => 'Tu sesión del Punto de Venta expiró. Inicia sesión de nuevo.', 'sesion' => false], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if (posDebeCambiarPassword($u)) posResponderCambioPassword();
    return $u;
}

// Cierra únicamente la sesión del POS (no toca la sesión de clientes del Catálogo)
function posCerrarSesion(): void {
    posIniciarSesion();
    $_SESSION = [];
    $p = session_get_cookie_params();
    setcookie(session_name(), '', ['expires' => time() - 3600, 'path' => $p['path'], 'httponly' => true, 'samesite' => 'Lax', 'secure' => karmaEsHttps()]);
    session_destroy();
}
