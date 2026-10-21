<?php
declare(strict_types=1);
/* KARMA · Catálogo — descarga del PDF vigente con el Aviso de Privacidad Integral y los Términos y Condiciones.
   Es el mismo PDF que se adjunta al correo de registro; se genera en memoria y no se guarda ningún archivo. */
require_once __DIR__ . '/includes/bootstrap.php';
require_once __DIR__ . '/includes/legal.php';

try {
    $pdf = catLegalPdf();
} catch (Throwable $e) {
    error_log('[Catalogo legal] PDF: ' . $e->getMessage());
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'No fue posible generar el PDF en este momento. Consulta los documentos en privacidad.php y terminos.php.';
    exit;
}
header('Content-Type: application/pdf');
header('Content-Disposition: inline; filename="' . catLegalNombrePdf() . '"');
header('Content-Length: ' . strlen($pdf));
header('Cache-Control: no-cache');
header('X-Content-Type-Options: nosniff');
echo $pdf;
