<?php
declare(strict_types=1);

/* Envío del ticket por Gmail; requiere Google API + Dompdf */
function enviarTicketGmail(string $email, string $nombre, array $ticket): array {
    $autoload = __DIR__ . '/vendor/autoload.php';

    if (!file_exists($autoload)) {
        return [
            'ok' => false,
            'message' => 'El envío por Gmail está preparado, pero faltan las dependencias de Composer. Revisa README_instalacion.txt.'
        ];
    }

    require_once $autoload;

    if (!class_exists('Dompdf\\Dompdf') || !class_exists('Google\\Client')) {
        return [
            'ok' => false,
            'message' => 'Faltan Dompdf o Google API Client. Ejecuta los comandos indicados en README_instalacion.txt.'
        ];
    }

    $clientId = getenv('KARMA_GMAIL_CLIENT_ID') ?: '';
    $clientSecret = getenv('KARMA_GMAIL_CLIENT_SECRET') ?: '';
    $refreshToken = getenv('KARMA_GMAIL_REFRESH_TOKEN') ?: '';
    $from = getenv('KARMA_GMAIL_FROM') ?: '';

    if (!$clientId || !$clientSecret || !$refreshToken || !$from) {
        return [
            'ok' => false,
            'message' => 'Gmail todavía no está configurado. Solo faltan las credenciales OAuth indicadas en README_instalacion.txt.'
        ];
    }

    $dompdf = new Dompdf\Dompdf();
    $itemsHtml = '';
    foreach (($ticket['items'] ?? []) as $item) {
        $articulo = htmlspecialchars((string)($item['articulo'] ?? ''), ENT_QUOTES, 'UTF-8');
        $precio = number_format((float)($item['precioTotal'] ?? 0), 2);
        $itemsHtml .= "<tr><td>{$articulo}</td><td align='right'>$ {$precio}</td></tr>";
    }

    $total = number_format((float)($ticket['total'] ?? 0), 2);
    $cambio = number_format((float)($ticket['cambio'] ?? 0), 2);

    $html = "
      <html><body style='font-family:Arial,sans-serif;'>
        <h1>KARMA</h1>
        <p>Venta #".htmlspecialchars((string)($ticket['numero'] ?? ''), ENT_QUOTES, 'UTF-8')."</p>
        <p>Cliente: ".htmlspecialchars($nombre, ENT_QUOTES, 'UTF-8')."</p>
        <table width='100%' border='0' cellpadding='7'>{$itemsHtml}</table>
        <hr>
        <p><strong>Total: $ {$total}</strong></p>
        <p>Efectivo recibido: $ ".number_format((float)($ticket['recibido'] ?? 0), 2)."</p>
        <p>Cambio: $ {$cambio}</p>
        <p>Gracias por tu compra.</p>
      </body></html>";

    $dompdf->loadHtml($html, 'UTF-8');
    $dompdf->setPaper('letter', 'portrait');
    $dompdf->render();
    $pdf = $dompdf->output();

    $client = new Google\Client();
    $client->setClientId($clientId);
    $client->setClientSecret($clientSecret);
    $client->setAccessType('offline');
    $client->refreshToken($refreshToken);

    $accessToken = $client->getAccessToken()['access_token'] ?? '';
    if (!$accessToken) {
        return ['ok'=>false, 'message'=>'No se pudo obtener el token de acceso de Gmail.'];
    }

    $subject = 'Ticket KARMA #' . (string)($ticket['numero'] ?? '');
    $boundary = '=_KARMA_' . bin2hex(random_bytes(8));
    $encodedPdf = chunk_split(base64_encode($pdf));

    $raw =
        "From: {$from}\r\n" .
        "To: {$email}\r\n" .
        "Subject: =?UTF-8?B?" . base64_encode($subject) . "?=\r\n" .
        "MIME-Version: 1.0\r\n" .
        "Content-Type: multipart/mixed; boundary=\"{$boundary}\"\r\n\r\n" .
        "--{$boundary}\r\n" .
        "Content-Type: text/html; charset=UTF-8\r\n\r\n" .
        "Hola ".htmlspecialchars($nombre, ENT_QUOTES, 'UTF-8').",<br><br>Adjuntamos tu ticket de compra KARMA.<br><br>" .
        "--{$boundary}\r\n" .
        "Content-Type: application/pdf; name=\"ticket-karma.pdf\"\r\n" .
        "Content-Disposition: attachment; filename=\"ticket-karma.pdf\"\r\n" .
        "Content-Transfer-Encoding: base64\r\n\r\n" .
        $encodedPdf .
        "--{$boundary}--";

    $gmailPayload = rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');

    $ch = curl_init('https://gmail.googleapis.com/gmail/v1/users/me/messages/send');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode(['raw' => $gmailPayload])
    ]);
    $response = curl_exec($ch);
    $http = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http < 200 || $http >= 300) {
        return ['ok'=>false, 'message'=>'Gmail rechazó el envío. Revisa las credenciales OAuth y los permisos.'];
    }

    return ['ok'=>true, 'message'=>'El PDF fue enviado al correo del cliente.'];
}
?>
