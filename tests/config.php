<?php

$archivoEnv = __DIR__ . '/.env';

if (!file_exists($archivoEnv)) {
    die("No se encontró el archivo .env");
}

$lineas = file($archivoEnv, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

$paypalClientId = "";
$paypalClientSecret = "";

foreach ($lineas as $linea) {

    $linea = trim($linea);

    if ($linea === "" || str_starts_with($linea, "#")) {
        continue;
    }

    [$nombre, $valor] = explode("=", $linea, 2);

    $nombre = trim($nombre);
    $valor = trim($valor);

    if ($nombre === "PAYPAL_CLIENT_ID") {
        $paypalClientId = $valor;
    }

    if ($nombre === "PAYPAL_CLIENT_SECRET") {
        $paypalClientSecret = $valor;
    }
}

if ($paypalClientId === "" || $paypalClientSecret === "") {
    die("No se encontraron las credenciales de PayPal en .env");
}

function obtenerAccessToken()
{
    global $paypalClientId, $paypalClientSecret;

    $url = "https://api-m.sandbox.paypal.com/v1/oauth2/token";

    $ch = curl_init($url);

    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    curl_setopt($ch, CURLOPT_USERPWD, $paypalClientId . ":" . $paypalClientSecret);

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
        die("No se pudo obtener el Access Token.");
    }

    $datos = json_decode($respuesta, true);

    return $datos['access_token'];
}