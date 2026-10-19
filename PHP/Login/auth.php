<?php
declare(strict_types=1);

/* Autenticación: ?action=login (POST correo/password), actual (usuario en sesión) y logout */
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../PuntoDeVenta/conexion.php';
require_once __DIR__ . '/sesion.php';

// Responde con el código HTTP indicado y termina la ejecución
function responder(array $data, int $status = 200): never {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    switch ($_GET['action'] ?? '') {
        case 'login':
            login();
        case 'actual':
            $usuario = usuarioActual(); 
            $usuario ? responder(['usuario' => $usuario]) : responder(['mensaje' => 'No hay sesión activa'], 401);
        case 'logout':
            cerrarSesion();
            responder(['mensaje' => 'Sesión cerrada']);
        default:
            responder(['mensaje' => 'Acción no reconocida'], 404);
    }
} catch (Throwable $e) {
    responder(['mensaje' => 'Error interno del servidor'], 500);
}

// Valida correo y contraseña contra usuarios.password_hash y guarda el usuario en $_SESSION
function login(): never {
    $in = json_decode((string)file_get_contents('php://input'), true) ?: [];
    $correo = trim((string)($in['correo'] ?? ''));
    $password = (string)($in['password'] ?? '');
    if ($correo === '' || $password === '') responder(['mensaje' => 'Correo y contraseña son obligatorios'], 400);

    $stmt = db()->prepare("
        SELECT u.id_usuario, u.nombre, u.correo, u.password_hash, u.estado, u.id_sucursal, r.nombre_rol
        FROM usuarios u
        JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.correo = ?");
    $stmt->execute([$correo]);
    $u = $stmt->fetch();

    if (!$u || !password_verify($password, $u['password_hash'])) responder(['mensaje' => 'Credenciales incorrectas'], 401);
    if ($u['estado'] !== 'activo') responder(['mensaje' => 'El usuario está inactivo'], 403);

    iniciarSesion();
    session_regenerate_id(true); // evita fijación de sesión
    $_SESSION['karma_usuario'] = [
        'id' => (int)$u['id_usuario'],
        'nombre' => $u['nombre'],
        'correo' => $u['correo'],
        'rol' => $u['nombre_rol'],
        'sucursalId' => $u['id_sucursal'] !== null ? (int)$u['id_sucursal'] : null,
    ];

    responder(['mensaje' => 'Inicio de sesión correcto', 'usuario' => $_SESSION['karma_usuario']]);
}
