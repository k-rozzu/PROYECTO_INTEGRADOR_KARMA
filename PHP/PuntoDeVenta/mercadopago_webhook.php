<?php
declare(strict_types=1);

/* KARMA · Webhook de Mercado Pago (evento «Order (Mercado Pago)»). URL que se registra en Tus integraciones > Webhooks:
   https://<dominio>/PROYECTO_INTEGRADOR_KARMA/PHP/PuntoDeVenta/mercadopago_webhook.php
   Es la única ruta del Punto de Venta que no usa la sesión del cajero, por eso solo acepta avisos con la firma x-signature
   válida (clave MP_WEBHOOK_SECRET del .env). Nunca confía en el cuerpo del aviso: responde 200 de inmediato y después consulta
   la orden real en la API y la aplica con mpProcesarOrden(), que ignora avisos repetidos o fuera de orden. La venta la
   registra la caja (mp_estado_cobro), que tiene todas las reglas del POS, en cuanto su pantalla ve el pago aprobado. */

require_once __DIR__ . '/conexion.php';
require_once __DIR__ . '/mercado_pago.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    exit;
}

$cuerpo = json_decode((string)file_get_contents('php://input'), true);
$cuerpo = is_array($cuerpo) ? $cuerpo : [];
// PHP convierte el parámetro data.id de la URL en data_id
$dataId = trim((string)($_GET['data_id'] ?? ($cuerpo['data']['id'] ?? '')));
$tipo = (string)($_GET['type'] ?? ($cuerpo['type'] ?? ''));
$requestId = trim((string)($_SERVER['HTTP_X_REQUEST_ID'] ?? ''));
$evento = ['orden' => $dataId ?: null, 'accion' => mb_substr((string)($cuerpo['action'] ?? ''), 0, 40) ?: null, 'request_id' => mb_substr($requestId, 0, 80) ?: null];
$pdo = db();

if (!mpFirmaValida((string)($_SERVER['HTTP_X_SIGNATURE'] ?? ''), $requestId, $dataId, karmaEnv('MP_WEBHOOK_SECRET'))) {
    mpBitacora($pdo, null, 'webhook', $evento + ['firma' => false, 'http' => 401, 'detalle' => 'Firma inválida o falta MP_WEBHOOK_SECRET en el .env']);
    http_response_code(401);
    header('Content-Type: application/json; charset=utf-8');
    echo '{"ok":false}';
    exit;
}

// Respuesta inmediata (Mercado Pago espera 22 s como máximo); la consulta a la API continúa después de cerrar la conexión
ignore_user_abort(true);
set_time_limit(60);
$respuesta = '{"ok":true}';
http_response_code(200);
header('Content-Type: application/json; charset=utf-8');
header('Content-Length: ' . strlen($respuesta));
header('Connection: close');
echo $respuesta;
while (ob_get_level() > 0) ob_end_flush();
flush();
if (function_exists('fastcgi_finish_request')) fastcgi_finish_request();

// Solo interesan las órdenes que creó este sistema
$stmt = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE mp_order_id = ? LIMIT 1");
$stmt->execute([$dataId]);
$pago = $tipo === 'order' && $dataId !== '' ? $stmt->fetch() : false;
mpBitacora($pdo, $pago ? (int)$pago['id_pago_mp'] : null, 'webhook', $evento + ['firma' => true, 'http' => 200, 'detalle' => $pago ? null : 'Aviso sin cobro de este sistema']);
if ($pago) mpConsultarOrden($pdo, $pago, 'webhook');
