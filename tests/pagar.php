<?php

require '../PHP/Paypal/config.php';

$url = "http://localhost/KARMA/PHP/Paypal/crear_orden.php";

$respuesta = file_get_contents($url);

if ($respuesta === false) {
    die("No se pudo conectar con el módulo de PayPal.");
}

$orderId = trim($respuesta);

?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Pago con PayPal</title>

    <link rel="stylesheet" href="prueba.css">
</head>

<body>

    <div class="contenedor">

        <h1>Prueba de Pago</h1>

        <p class="descripcion">Monto a pagar</p>

        <p class="monto">$150.00 MXN</p>

        <div id="paypal-button-container"></div>

    </div>

    <script src="https://www.paypal.com/sdk/js?client-id=<?php echo $paypalClientId; ?>&currency=MXN"></script>

    <script>

        console.log("SDK PayPal cargado");
        console.log(paypal);

        paypal.Buttons({

            createOrder: function() {

                return <?php echo json_encode($orderId); ?>;

            },

            onApprove: function(data) {

                const formulario = document.createElement("form");

                formulario.method = "POST";

                formulario.action = "../PHP/Paypal/capturar_orden.php";

                const input = document.createElement("input");

                input.type = "hidden";
                input.name = "orderID";
                input.value = data.orderID;

                formulario.appendChild(input);

                document.body.appendChild(formulario);

                formulario.submit();

            },

            onCancel: function() {

                alert("El pago fue cancelado.");

            },

            onError: function(error) {

                console.error(error);

                alert("Ocurrió un error con PayPal.");

            }

        }).render('#paypal-button-container');

    </script>

</body>

</html>