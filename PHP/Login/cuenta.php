<?php
declare(strict_types=1);

/* KARMA · API de la cuenta del usuario del sistema (Cajero, Gerente o Administrador).
   POST ?action=cambiar_password  { actual, nueva, confirmacion }  → cualquier usuario cambia su propia contraseña.
   Lo usa la pantalla PHP/Login/cambiar_password.php (también la obligatoria tras recibir una contraseña temporal). */
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';
require_once __DIR__ . '/sesion_pos.php';

// Largo permitido de la contraseña (bcrypt solo toma en cuenta los primeros 72 bytes)
const CUENTA_PASSWORD_MIN = 8;
const CUENTA_PASSWORD_MAX_BYTES = 72;
// Freno a intentos con la contraseña actual equivocada
const CUENTA_MAX_FALLOS = 5;
const CUENTA_ESPERA = 60;

function cuentaResponder(array $datos, int $estado = 200): never {
    http_response_code($estado);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit;
}

// Misma comparación que el login: hash bcrypt/argon2 o, en cuentas insertadas a mano, texto plano
function cuentaPasswordCorrecta(string $password, string $guardado): bool {
    if (preg_match('/^\$(2[abxy]\$\d\d\$|argon2id?\$)/', $guardado) === 1) return password_verify($password, $guardado);
    return $guardado !== '' && hash_equals($guardado, $password);
}

// Pantalla a la que vuelve cada rol después de cambiar su contraseña (rutas relativas a PHP/Login/)
function cuentaDestino(string $rol): string {
    return $rol === 'Cajero' ? '../PuntoDeVenta/index.php' : '../../Home/home.html';
}

// Regresa el problema de la contraseña nueva o null si cumple las reglas
function cuentaErrorPassword(string $nueva, array $usuario): ?string {
    if (mb_strlen($nueva, 'UTF-8') < CUENTA_PASSWORD_MIN) return 'La contraseña nueva debe tener al menos ' . CUENTA_PASSWORD_MIN . ' caracteres.';
    if (strlen($nueva) > CUENTA_PASSWORD_MAX_BYTES) return 'La contraseña nueva es demasiado larga (máximo 72 caracteres).';
    if (!preg_match('/\p{L}/u', $nueva) || !preg_match('/\d/', $nueva)) return 'La contraseña nueva debe combinar letras y números.';
    if (strcasecmp($nueva, (string)$usuario['correo']) === 0) return 'La contraseña no puede ser tu correo.';
    return null;
}

try {
    $usuario = posUsuarioValidado(db());
    if (!$usuario) cuentaResponder(['ok' => false, 'error' => 'Tu sesión expiró. Inicia sesión de nuevo.', 'sesion' => false], 401);

    $accion = (string)($_GET['action'] ?? '');
    if ($accion !== 'cambiar_password') cuentaResponder(['ok' => false, 'error' => 'Acción no reconocida.'], 404);
    if (($rechazo = posRechazoEscritura()) !== null) cuentaResponder(['ok' => false, 'error' => $rechazo], 403);
    if (!posCsrfValido()) cuentaResponder(['ok' => false, 'error' => 'Solicitud no válida. Recarga la página e inténtalo de nuevo.'], 403);

    $fallos = $_SESSION['cuenta_fallos'] ?? ['n' => 0, 't' => 0];
    if (($fallos['n'] >= CUENTA_MAX_FALLOS && time() - $fallos['t'] < CUENTA_ESPERA) || karmaDemasiadosFallos('cuenta', 10, 600)) {
        cuentaResponder(['ok' => false, 'error' => 'Demasiados intentos. Espera un minuto e inténtalo de nuevo.'], 429);
    }

    $datos = json_decode((string)file_get_contents('php://input'), true);
    $actual = (string)($datos['actual'] ?? '');
    $nueva = (string)($datos['nueva'] ?? '');
    $confirmacion = (string)($datos['confirmacion'] ?? '');
    if ($actual === '' || $nueva === '' || $confirmacion === '') cuentaResponder(['ok' => false, 'error' => 'Llena los tres campos.'], 400);
    if ($nueva !== $confirmacion) cuentaResponder(['ok' => false, 'error' => 'La confirmación no coincide con la contraseña nueva.'], 400);

    $stmt = db()->prepare("SELECT password_hash FROM usuarios WHERE id_usuario = ?");
    $stmt->execute([(int)$usuario['id_usuario']]);
    $guardado = (string)$stmt->fetchColumn();
    if (!cuentaPasswordCorrecta($actual, $guardado)) {
        $_SESSION['cuenta_fallos'] = ['n' => $fallos['n'] + 1, 't' => time()];
        karmaRegistrarFallo('cuenta');
        usleep(300000);
        cuentaResponder(['ok' => false, 'error' => 'Tu contraseña actual no es correcta.'], 400);
    }
    unset($_SESSION['cuenta_fallos']);
    if (hash_equals($actual, $nueva)) cuentaResponder(['ok' => false, 'error' => 'La contraseña nueva debe ser distinta de la actual.'], 400);
    if (($error = cuentaErrorPassword($nueva, $usuario)) !== null) cuentaResponder(['ok' => false, 'error' => $error], 400);

    $pdo = db();
    $columnas = $pdo->query("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios'")
        ->fetchAll(PDO::FETCH_COLUMN);
    $sets = ['password_hash = ?'];
    if (in_array('debe_cambiar_password', $columnas, true)) $sets[] = 'debe_cambiar_password = 0';
    if (in_array('fecha_cambio_password', $columnas, true)) $sets[] = 'fecha_cambio_password = NOW()';
    $pdo->prepare('UPDATE usuarios SET ' . implode(', ', $sets) . ' WHERE id_usuario = ?')
        ->execute([password_hash($nueva, PASSWORD_BCRYPT, ['cost' => 12]), (int)$usuario['id_usuario']]);

    // Bitácora del panel de administrador (si la tabla existe en esta base)
    try {
        $pdo->prepare("INSERT INTO auditoria (id_usuario, accion, detalle) VALUES (?, 'Cambio de contraseña', ?)")
            ->execute([(int)$usuario['id_usuario'], mb_substr($usuario['nombre'] . ' cambió su contraseña', 0, 255)]);
    } catch (Throwable $e) { /* base sin tabla auditoria */ }

    // Sesión nueva después de cambiar credenciales (evita que un id de sesión anterior siga sirviendo)
    session_regenerate_id(true);

    cuentaResponder([
        'ok' => true,
        'mensaje' => 'Tu contraseña se cambió correctamente.',
        'destino' => cuentaDestino((string)$usuario['nombre_rol'])
    ]);
} catch (Throwable $e) {
    error_log('[Cuenta] ' . $e->getMessage());
    cuentaResponder(['ok' => false, 'error' => 'Error interno del servidor.'], 500);
}
