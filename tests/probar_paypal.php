<?php

require 'config.php';

$clientId = $paypalClientId;
$clientSecret = $paypalClientSecret;

$url = "https://api-m.sandbox.paypal.com/v1/oauth2/token";

$ch = curl_init($url);

curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

curl_setopt($ch, CURLOPT_USERPWD, $clientId . ":" . $clientSecret);

curl_setopt($ch, CURLOPT_POST, true);

curl_setopt($ch, CURLOPT_POSTFIELDS, "grant_type=client_credentials");

curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Accept: application/json",
    "Accept-Language: en_US",
    "Content-Type: application/x-www-form-urlencoded"
]);

$respuesta = curl_exec($ch);

$codigo = curl_getinfo($ch, CURLINFO_HTTP_CODE);

curl_close($ch);

if ($codigo != 200) {
    echo "Error al conectar con PayPal.";
    echo "<br>Código HTTP: " . $codigo;
    echo "<br>Respuesta: " . $respuesta;
    exit;
}

$datos = json_decode($respuesta, true);

echo "¡Conexión con PayPal exitosa!";

?>