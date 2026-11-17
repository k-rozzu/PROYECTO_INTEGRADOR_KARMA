<?php

// Solo el personal con sesión del sistema puede usar el módulo de PayPal (antes cualquiera desde internet podía llamarlo)
require_once __DIR__ . '/../PuntoDeVenta/conexion.php';
require_once __DIR__ . '/../Login/sesion_pos.php';
if (!posUsuarioValidado(db())) {
    http_response_code(401);
    exit('Inicia sesión para continuar.');
}

require 'config.php';

$orderId = (string)($_POST['orderID'] ?? '');

if ($orderId === '') {
    die("No se recibió el ID de la orden.");
}
// El id de PayPal solo lleva letras y números: cualquier otra cosa podría alterar la dirección de la API
if (!preg_match('/^[A-Za-z0-9]{5,40}$/', $orderId)) {
    http_response_code(400);
    die("El ID de la orden no es válido.");
}

$url = "https://api-m.sandbox.paypal.com/v2/checkout/orders/"
     . $orderId
     . "/capture";

$ch = curl_init($url);

curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

curl_setopt($ch, CURLOPT_POST, true);

curl_setopt($ch, CURLOPT_POSTFIELDS, "");

curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Content-Type: application/json",
    "Authorization: Bearer " . obtenerAccessToken()
]);

$respuesta = curl_exec($ch);

$codigo = curl_getinfo($ch, CURLINFO_HTTP_CODE);

curl_close($ch);

if ($codigo != 201) {
    echo "Error al capturar el pago.";
    echo "<br>Código HTTP: " . $codigo;
    echo "<br>Respuesta: " . $respuesta;
    exit;
}

$datos = json_decode($respuesta, true);

echo json_encode($datos);