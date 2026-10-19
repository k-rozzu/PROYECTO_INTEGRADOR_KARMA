<?php
declare(strict_types=1);

/* Sesión PHP compartida: la abre auth.php al iniciar sesión y la consultan las demás APIs */

// Inicia (o reanuda) la sesión con una cookie que JavaScript no puede leer
function iniciarSesion(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    session_name('KARMASESSID');
    session_set_cookie_params(['path' => '/', 'httponly' => true, 'samesite' => 'Lax']);
    session_start();
} 

// Usuario autenticado ({id, nombre, correo, rol, sucursalId}) o null si no hay sesión
function usuarioActual(): ?array {
    iniciarSesion();
    return $_SESSION['karma_usuario'] ?? null;
}

// Cierra la sesión y borra su cookie
function cerrarSesion(): void {
    iniciarSesion();
    $_SESSION = [];
    $params = session_get_cookie_params();
    setcookie(session_name(), '', ['expires' => time() - 3600, 'path' => $params['path'], 'httponly' => true, 'samesite' => 'Lax']);
    session_destroy();
}
