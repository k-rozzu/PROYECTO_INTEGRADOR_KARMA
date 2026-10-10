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

$datos = json_decode($respuesta, true);

if ($codigo != 201) {

    echo "Error al capturar el pago.";
    echo "<br>Código HTTP: " . $codigo;
    echo "<br>Respuesta: " . $respuesta;

    exit;
}

$transactionId = $datos['purchase_units'][0]['payments']['captures'][0]['id'];
$estado = $datos['status'];

?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Pago completado</title>

    <link rel="stylesheet" href="prueba.css">
</head>

<body>

    <div class="contenedor">

        <h1>¡Pago completado!</h1>

        <p class="descripcion">
            El pago fue capturado correctamente.
        </p>

        <p class="monto">
            $150.00 MXN
        </p>

        <p>Estado:</p>
        <strong><?php echo htmlspecialchars($estado); ?></strong>

        <p>ID de orden:</p>
        <strong><?php echo htmlspecialchars($orderId); ?></strong>

        <p>ID de transacción:</p>
        <strong><?php echo htmlspecialchars($transactionId); ?></strong>

    </div>

</body>

</html>