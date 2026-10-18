<?php
declare(strict_types=1);

/* KARMA · Login del sistema en PHP (equivalente a POST /api/login de backend/server.js).
   Lo usa la pantalla de login existente (index.html + JavaScript/login.js) cuando el proyecto corre en XAMPP:
   mismas credenciales de la tabla `usuarios`, misma verificación bcrypt y mismas respuestas que la versión Node.js.
   Además deja abierta la sesión PHP del Punto de Venta para que el POS pueda validar el acceso en el servidor. */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';
require_once __DIR__ . '/sesion_pos.php';

// Responde en JSON con su código HTTP y termina
function loginResponder(array $datos, int $estado = 200): never {
    http_response_code($estado);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit;
}

// Solo acepta peticiones enviadas desde este mismo sitio (evita que otra página inicie sesiones a escondidas)
function loginValidarOrigen(): void {
    $origen = $_SERVER['HTTP_ORIGIN'] ?? $_SERVER['HTTP_REFERER'] ?? '';
    if ($origen === '') return;
    $partes = parse_url($origen);
    $hostOrigen = ($partes['host'] ?? '') . (isset($partes['port']) ? ':' . $partes['port'] : '');
    if (strcasecmp($hostOrigen, $_SERVER['HTTP_HOST'] ?? '') !== 0) {
        loginResponder(['mensaje' => 'Origen no permitido'], 403);
    }
}

// ¿El valor guardado en usuarios.password_hash es un hash real (bcrypt $2y$/$2a$/$2b$/$2x$ o argon2)?
// password_get_info() solo reconoce $2y$, por eso se revisa el prefijo directamente.
function loginEsHash(string $valor): bool {
    return preg_match('/^\$(2[abxy]\$\d\d\$|argon2id?\$)/', $valor) === 1;
}

// Compara la contraseña escrita con la guardada. Los usuarios creados desde la app tienen hash bcrypt, pero un
// usuario insertado a mano con SQL (INSERT ... password_hash = 'micontraseña') la tiene en texto plano y
// password_verify() lo rechazaba siempre: esa era la causa de "Credenciales incorrectas" con datos correctos.
function loginPasswordCorrecta(string $password, string $guardado): bool {
    if (loginEsHash($guardado)) return password_verify($password, $guardado);
    return $guardado !== '' && hash_equals($guardado, $password);
}

// Tras un acceso correcto, si la contraseña estaba en texto plano se guarda ya como bcrypt (mismo costo 12 que las
// demás cuentas). La contraseña sigue siendo la misma para el usuario; solo deja de estar legible en la base de datos.
function loginActualizarHash(array $usuario, string $password): void {
    $guardado = (string)$usuario['password_hash'];
    if (loginEsHash($guardado)) return;
    try {
        db()->prepare("UPDATE usuarios SET password_hash = ? WHERE id_usuario = ? AND password_hash = ?")
            ->execute([password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]), (int)$usuario['id_usuario'], $guardado]);
    } catch (Throwable $e) {
        // Si no se pudo actualizar, el acceso continúa: el texto plano se volverá a validar la próxima vez
    }
}

try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') loginResponder(['mensaje' => 'Usa POST'], 405);
    loginValidarOrigen();
    posIniciarSesion();

    // Freno a intentos repetidos: después de 5 fallos seguidos hay que esperar 60 segundos
    $intentos = $_SESSION['login_intentos'] ?? ['n' => 0, 't' => 0];
    if ($intentos['n'] >= 5 && time() - $intentos['t'] < 60) {
        loginResponder(['mensaje' => 'Demasiados intentos. Espera un minuto e inténtalo de nuevo.'], 429);
    }

    $datos = json_decode((string)file_get_contents('php://input'), true);
    $correo = trim((string)($datos['correo'] ?? ''));
    $password = (string)($datos['password'] ?? '');

    if ($correo === '' || $password === '') {
        loginResponder(['mensaje' => 'Correo y contraseña son obligatorios'], 400);
    }

    // Misma consulta que server.js: usuario + nombre del rol
    $stmt = db()->prepare("
        SELECT u.id_usuario, u.nombre, u.correo, u.password_hash, u.estado, u.id_sucursal, r.nombre_rol
        FROM usuarios u
        INNER JOIN roles r ON u.id_rol = r.id_rol
        WHERE u.correo = ?
        LIMIT 1
    ");
    $stmt->execute([$correo]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    // Se verifica siempre un hash (aunque el correo no exista) para no revelar qué correos están registrados
    $hash = (string)($usuario['password_hash'] ?? '$2y$12$hwYmuOlp6nD9GMMParLSaudYeryxz7nV8celMCqEe4ual5f/kf7z2');
    $passwordCorrecta = loginPasswordCorrecta($password, $hash);

    if (!$usuario || !$passwordCorrecta) {
        $_SESSION['login_intentos'] = ['n' => $intentos['n'] + 1, 't' => time()];
        usleep(300000);
        loginResponder(['mensaje' => 'Credenciales incorrectas'], 401);
    }

    if ($usuario['estado'] !== 'activo') {
        loginResponder(['mensaje' => 'El usuario está inactivo'], 403);
    }

    // Credenciales válidas: se abre la sesión PHP del sistema (el POS solo deja entrar al rol Cajero)
    unset($_SESSION['login_intentos']);
    loginActualizarHash($usuario, $password);
    posGuardarUsuario($usuario);

    loginResponder([
        'mensaje' => 'Inicio de sesión correcto',
        'usuario' => [
            'id' => (int)$usuario['id_usuario'],
            'nombre' => $usuario['nombre'],
            'correo' => $usuario['correo'],
            'rol' => $usuario['nombre_rol']
        ]
    ]);
} catch (Throwable $e) {
    loginResponder(['mensaje' => 'Error interno del servidor'], 500);
}
