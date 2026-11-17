<?php
declare(strict_types=1);

/* KARMA · Imagen de apertura del correo del aviso de privacidad (1×1 transparente).
   Cuando el programa de correo del empleado la descarga, su aviso pasa a «revisado» en el panel de administrador.
   Siempre responde la imagen, aunque el token no exista, para no revelar nada a quien la pida. */
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';
require_once __DIR__ . '/avisos.php';

try {
    avisoMarcarRevisado(db(), (string)($_GET['t'] ?? ''));
} catch (Throwable $e) {
    error_log('[Aviso abierto] ' . $e->getMessage());
}

header('Content-Type: image/gif');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
echo base64_decode('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
