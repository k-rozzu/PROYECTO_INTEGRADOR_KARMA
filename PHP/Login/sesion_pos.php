<?php
declare(strict_types=1);

/* KARMA · Sesión del PUNTO DE VENTA (usuarios del sistema de la tabla `usuarios`: Cajero, Gerente, Administrador).
   Es una sesión distinta a la de los clientes del Catálogo: cookie KARMAPOS (POS) vs KARMACLIENTE (Catálogo),
   así un cliente con sesión en la tienda en línea NUNCA queda dentro del Punto de Venta. */

// Nombre de la cookie de sesión del POS
const POS_SESION = 'KARMAPOS';
// Roles que pueden abrir el Punto de Venta (agregar 'Gerente' aquí si en el futuro también deben entrar)
const POS_ROLES_PERMITIDOS = ['Cajero'];

// Abre la sesión del POS con cookie solo-HTTP y SameSite=Lax (protege contra robo de cookie y CSRF)
function posIniciarSesion(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    ini_set('session.use_strict_mode', '1');
    session_name(POS_SESION);
    session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'httponly' => true, 'samesite' => 'Lax']);
    session_start();
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
    $stmt = $pdo->prepare("
        SELECT u.id_usuario, u.nombre, u.correo, u.id_sucursal, u.estado, u.id_rol, r.nombre_rol
        FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.id_usuario = ? LIMIT 1
    ");
    $stmt->execute([(int)$sesion['id']]);
    $u = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$u || $u['estado'] !== 'activo' || !in_array($u['nombre_rol'], POS_ROLES_PERMITIDOS, true)) return null;
    return $u;
}

// Para index.php del POS: sin sesión válida de Cajero se regresa a la pantalla de login
function posRequerirPagina(PDO $pdo): array {
    $u = posUsuarioValidado($pdo);
    if (!$u) {
        header('Location: ' . posRutaLogin());
        exit;
    }
    return $u;
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
    return $u;
}

// Cierra únicamente la sesión del POS (no toca la sesión de clientes del Catálogo)
function posCerrarSesion(): void {
    posIniciarSesion();
    $_SESSION = [];
    $p = session_get_cookie_params();
    setcookie(session_name(), '', ['expires' => time() - 3600, 'path' => $p['path'], 'httponly' => true, 'samesite' => 'Lax']);
    session_destroy();
}
