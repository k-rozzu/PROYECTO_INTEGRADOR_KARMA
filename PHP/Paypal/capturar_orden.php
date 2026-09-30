<?php

require 'config.php';

$orderId = $_POST['orderID'] ?? '';

if ($orderId === '') {
    die("No se recibió el ID de la orden.");
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