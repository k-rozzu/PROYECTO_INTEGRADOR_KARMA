<?php

// Solo el personal con sesión del sistema puede usar el módulo de PayPal (antes cualquiera desde internet podía llamarlo)
require_once __DIR__ . '/../PuntoDeVenta/conexion.php';
require_once __DIR__ . '/../Login/sesion_pos.php';
if (!posUsuarioValidado(db())) {
    http_response_code(401);
    exit('Inicia sesión para continuar.');
}

require 'config.php';

$monto = "150.00";

$url = "https://api-m.sandbox.paypal.com/v2/checkout/orders";

$datos = [
    "intent" => "CAPTURE",
    "purchase_units" => [
        [
            "amount" => [
                "currency_code" => "MXN",
                "value" => $monto
            ]
        ]
    ]
];

$ch = curl_init($url);

curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

curl_setopt($ch, CURLOPT_POST, true);

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($datos));

curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Content-Type: application/json",
    "Authorization: Bearer " . obtenerAccessToken()
]);

$respuesta = curl_exec($ch);

$codigo = curl_getinfo($ch, CURLINFO_HTTP_CODE);

curl_close($ch);

if ($codigo != 201) {

    echo "Error al crear la orden.";
    echo "<br>Código HTTP: " . $codigo;
    echo "<br>Respuesta: " . $respuesta;

    exit;
}

$orden = json_decode($respuesta, true);

echo $orden['id'];