<?php
declare(strict_types=1);

/* Envío del ticket por Gmail; requiere Google API + Dompdf.
   El "cuadrito" que ve el cajero en pantalla (ticketCerrado) sigue siendo el mismo
   resumen breve de siempre — ESTE archivo arma el ticket COMPLETO (fiscal/legal)
   que se manda en PDF por correo, con los 7 bloques de datos requeridos. */

const KARMA_MARCAS_GARANTIA_4A = ['audi', 'porsche', 'ducati'];

function h($valor): string {
    return htmlspecialchars((string)($valor ?? ''), ENT_QUOTES, 'UTF-8');
}

function karmaMoneyFmt($n): string {
    return '$ ' . number_format((float)($n ?? 0), 2);
}

/* Convierte un monto a letras, formato usado en facturas mexicanas: "___ PESOS XX/100 M.N." */
function numeroALetras(float $monto): string {
    $monto = round($monto, 2);
    $entero = (int) floor($monto);
    $centavos = (int) round(($monto - $entero) * 100);
    $letras = karmaConvertirEntero($entero);
    $letras = $letras === '' ? 'CERO' : $letras;
    return sprintf('%s PESOS %02d/100 M.N.', $letras, $centavos);
}

function karmaConvertirEntero(int $n): string {
    if ($n === 0) return 'CERO';
    if ($n < 0) return 'MENOS ' . karmaConvertirEntero(-$n);
    if ($n < 1000000) return karmaConvertirMenorMillon($n);

    $millones = intdiv($n, 1000000);
    $resto = $n % 1000000;
    $prefijo = ($millones === 1) ? 'UN MILLON' : trim(karmaConvertirMenorMillon($millones)) . ' MILLONES';
    return trim($prefijo . ($resto > 0 ? ' ' . karmaConvertirMenorMillon($resto) : ''));
}

function karmaConvertirMenorMillon(int $n): string {
    if ($n === 0) return '';
    if ($n < 1000) return karmaConvertirCentenas($n);

    $miles = intdiv($n, 1000);
    $resto = $n % 1000;
    $prefijo = ($miles === 1) ? 'MIL' : trim(karmaConvertirCentenas($miles)) . ' MIL';
    return trim($prefijo . ($resto > 0 ? ' ' . karmaConvertirCentenas($resto) : ''));
}

function karmaConvertirCentenas(int $n): string {
    $centenas = ['', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'];
    if ($n === 100) return 'CIEN';
    $c = intdiv($n, 100);
    $resto = $n % 100;
    $texto = $c > 0 ? $centenas[$c] : '';
    return trim($texto . ($resto > 0 ? ' ' . karmaConvertirDecenas($resto) : ''));
}

function karmaConvertirDecenas(int $n): string {
    $unidades = ['', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE'];
    $especiales = [
        10 => 'DIEZ', 11 => 'ONCE', 12 => 'DOCE', 13 => 'TRECE', 14 => 'CATORCE', 15 => 'QUINCE',
        16 => 'DIECISEIS', 17 => 'DIECISIETE', 18 => 'DIECIOCHO', 19 => 'DIECINUEVE',
        20 => 'VEINTE', 21 => 'VEINTIUNO', 22 => 'VEINTIDOS', 23 => 'VEINTITRES', 24 => 'VEINTICUATRO',
        25 => 'VEINTICINCO', 26 => 'VEINTISEIS', 27 => 'VEINTISIETE', 28 => 'VEINTIOCHO', 29 => 'VEINTINUEVE'
    ];
    $decenas = ['', '', '', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'];

    if ($n < 10) return $unidades[$n];
    if (isset($especiales[$n])) return $especiales[$n];

    $d = intdiv($n, 10);
    $u = $n % 10;
    return $u === 0 ? $decenas[$d] : $decenas[$d] . ' Y ' . $unidades[$u];
}

/* Arma el HTML del ticket completo (las 7 secciones) a partir del ticketCerrado
   que envía script.js. */
function construirTicketHTML(string $nombreCliente, string $emailCliente, array $ticket): string {
    $items = is_array($ticket['items'] ?? null) ? $ticket['items'] : [];
    $vehiculos = array_values(array_filter($items, fn($it) => !empty($it['esVehiculo'])));
    $refacciones = array_values(array_filter($items, fn($it) => empty($it['esVehiculo'])));
    $primerVehiculo = $vehiculos[0] ?? null;
    $esCredito = $primerVehiculo && !empty($primerVehiculo['esCredito']);

    $folioTicket = h($ticket['numero'] ?? '');
    $folioCompleto = h($ticket['folio'] ?? ('KRM-' . ($ticket['ventaId'] ?? '')));
    $serieDigital = h('KRM-' . ($ticket['ventaId'] ?? '0'));
    $fecha = h($ticket['fecha'] ?? date('d/m/Y H:i:s'));
    $sucursalNombre = h($ticket['sucursal'] ?? 'Manzanillo');
    $sucursalDireccion = h($ticket['sucursalDireccion'] ?? '');
    $sucursalTelefono = h($ticket['sucursalTelefono'] ?? '');
    $cajero = h($ticket['cajero'] ?? '');

    $rfcIne = h($primerVehiculo['rfcIne'] ?? '');
    $direccionCliente = h($primerVehiculo['direccion'] ?? '');
    $idTipo = h($primerVehiculo['identificacionTipo'] ?? 'INE');
    $celularCliente = h($primerVehiculo['celular'] ?? '');

    $subtotal = (float)($ticket['subtotal'] ?? ($ticket['total'] ?? 0));
    $total = (float)($ticket['total'] ?? 0);
    $recibido = (float)($ticket['recibido'] ?? 0);
    $cambio = (float)($ticket['cambio'] ?? 0);
    $totalLetras = h(numeroALetras($total));

    // Sección 3 y 6: un bloque de identificación + garantía por cada vehículo del ticket
    $bloquesVehiculo = '';
    foreach ($vehiculos as $v) {
        $marcaLower = mb_strtolower(trim((string)($v['marca'] ?? '')));
        $conGarantia = in_array($marcaLower, KARMA_MARCAS_GARANTIA_4A, true);
        $bloquesVehiculo .= '
        <table class="tabla-datos">
          <tr><td class="etq">Marca / Modelo / Año</td><td>' . h(trim(($v['marca'] ?? '') . ' ' . ($v['modelo'] ?? '') . ' (' . ($v['anio'] ?? '') . ')')) . '</td></tr>
          <tr><td class="etq">VIN / Número de serie</td><td>' . h($v['vin'] ?: '—') . '</td></tr>
          <tr><td class="etq">Número de motor</td><td>' . h($v['motorSerie'] ?: ($v['motorTipo'] ?? '—')) . '</td></tr>
          <tr><td class="etq">Color exterior</td><td>' . h($v['colorExterior'] ?: '—') . '</td></tr>
          <tr><td class="etq">Color interior</td><td>' . h($v['colorInterior'] ?: '—') . '</td></tr>
          <tr><td class="etq">Kilometraje de entrega</td><td>0 km</td></tr>
          <tr><td class="etq">Estado de la unidad</td><td>Unidad Nueva</td></tr>
          <tr><td class="etq">Garantía</td><td>' . ($conGarantia ? '4 años de garantía KARMA' : 'Consultar condiciones de garantía con el vendedor') . '</td></tr>
          <tr><td class="etq">Precio</td><td>' . karmaMoneyFmt($v['precioTotal'] ?? 0) . '</td></tr>
        </table>';
    }

    // Refacciones dentro del mismo ticket (si las hay): tabla simple de líneas
    $filasRefacciones = '';
    foreach ($refacciones as $r) {
        $filasRefacciones .= '<tr><td>' . h($r['articulo'] ?? '') . '</td><td class="der">' . karmaMoneyFmt($r['precioTotal'] ?? 0) . '</td></tr>';
    }

    $bloqueCredito = '';
    if ($esCredito && $primerVehiculo) {
        $bloqueCredito = '
        <h2>5b. Condiciones de crédito</h2>
        <table class="tabla-datos">
          <tr><td class="etq">Enganche</td><td>' . karmaMoneyFmt($primerVehiculo['enganche'] ?? 0) . '</td></tr>
          <tr><td class="etq">Plazo</td><td>' . h($primerVehiculo['abonos'] ?? '') . '</td></tr>
          <tr><td class="etq">Tasa de interés anual</td><td>' . h($primerVehiculo['tasaAnual'] ?? '') . '%</td></tr>
          <tr><td class="etq">Comisión por apertura</td><td>' . karmaMoneyFmt($primerVehiculo['comisionApertura'] ?? 0) . '</td></tr>
          <tr><td class="etq">Monto de interés</td><td>' . karmaMoneyFmt($primerVehiculo['montoInteres'] ?? 0) . '</td></tr>
          <tr><td class="etq">Monto final financiado</td><td>' . karmaMoneyFmt($primerVehiculo['montoFinal'] ?? 0) . '</td></tr>
          <tr><td class="etq">Mensualidad estimada</td><td>' . karmaMoneyFmt($primerVehiculo['montoAbono'] ?? 0) . '</td></tr>
        </table>';
    }

    $leyendaPago = $esCredito
        ? ('Forma de pago: ENGANCHE + FINANCIAMIENTO A ' . h($primerVehiculo['abonos'] ?? '') . '.')
        : 'Forma de pago: PAGO EN UNA SOLA EXHIBICIÓN — CONTADO.';

    return '<html><head><meta charset="UTF-8"><style>
      body{ font-family: Arial, sans-serif; font-size:11px; color:#17181A; }
      h1{ font-size:20px; margin:0; }
      h2{ font-size:13px; margin:18px 0 6px; border-bottom:1px solid #ccc; padding-bottom:3px; }
      .muted{ color:#666; font-size:10px; }
      table{ width:100%; border-collapse:collapse; margin-bottom:6px; }
      .tabla-datos td{ padding:3px 6px; border-bottom:1px solid #eee; vertical-align:top; }
      .etq{ color:#666; width:220px; }
      .der{ text-align:right; }
      .total-box{ margin-top:10px; padding:8px 10px; background:#f7f7f5; border:1px solid #ddd; }
      .legal{ margin-top:16px; font-size:9.5px; color:#444; line-height:1.5; }
      .firma{ margin-top:26px; }
    </style></head><body>

      <h1>KARMA — Agencia de Autos</h1>
      <div class="muted">Razón social: Karma Autos, S.A. de C.V. — Nombre comercial: Agencia de Autos Karma<br>
      Sucursal ' . $sucursalNombre . ' — ' . $sucursalDireccion . ' · Tel. ' . $sucursalTelefono . '</div>
      <div class="muted">Folio único: <strong>' . $folioCompleto . '</strong> — Ticket #' . $folioTicket . ' — Serie digital ' . $serieDigital . '</div>

      <h2>1. Datos del comprador</h2>
      <table class="tabla-datos">
        <tr><td class="etq">Nombre completo</td><td>' . h($nombreCliente) . '</td></tr>
        <tr><td class="etq">RFC / Identificación (' . $idTipo . ')</td><td>' . ($rfcIne !== '' ? $rfcIne : '—') . '</td></tr>
        <tr><td class="etq">Dirección</td><td>' . ($direccionCliente !== '' ? $direccionCliente : '—') . '</td></tr>
        <tr><td class="etq">Teléfono</td><td>' . ($celularCliente !== '' ? $celularCliente : '—') . '</td></tr>
        <tr><td class="etq">Correo electrónico</td><td>' . h($emailCliente) . '</td></tr>
      </table>

      ' . ($vehiculos ? '<h2>2. Identificación del vehículo</h2>' . $bloquesVehiculo : '') . '

      ' . ($refacciones ? '<h2>2b. Refacciones incluidas</h2><table>' . $filasRefacciones . '</table>' : '') . '

      <h2>3. Desglose financiero</h2>
      <table class="tabla-datos">
        <tr><td class="etq">Subtotal</td><td>' . karmaMoneyFmt($subtotal) . '</td></tr>
        <tr><td class="etq">Total</td><td>' . karmaMoneyFmt($total) . '</td></tr>
        <tr><td class="etq">Total con letra</td><td>' . $totalLetras . '</td></tr>
        <tr><td class="etq">Efectivo recibido</td><td>' . karmaMoneyFmt($recibido) . '</td></tr>
        <tr><td class="etq">Cambio</td><td>' . karmaMoneyFmt($cambio) . '</td></tr>
      </table>
      <div class="total-box"><strong>' . $leyendaPago . '</strong></div>

      ' . $bloqueCredito . '

      <h2>4. Transacción</h2>
      <table class="tabla-datos">
        <tr><td class="etq">Método de pago</td><td>' . h($ticket['metodo'] ?? 'Efectivo') . '</td></tr>
        <tr><td class="etq">Fecha y hora en que se acreditó el pago</td><td>' . $fecha . '</td></tr>
        <tr><td class="etq">Cajero / vendedor</td><td>' . $cajero . '</td></tr>
        <tr><td class="etq">Caja</td><td>' . h($ticket['caja'] ?? '') . '</td></tr>
      </table>

      <div class="legal">
        <strong>Validez digital:</strong> Documento firmado digitalmente por ' . $cajero . ' en representación de KARMA, Sucursal ' . $sucursalNombre . '.<br>
        <strong>Conformidad del cliente:</strong> &ldquo;Recibí de conformidad el vehículo y los documentos arriba descritos.&rdquo;
      </div>
      <div class="firma">________________________________<br><span class="muted">Firma digital / sello de recepción del vendedor</span></div>

    </body></html>';
}

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

    $html = construirTicketHTML($nombre, $email, $ticket);

    $dompdf = new Dompdf\Dompdf();
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
        return ['ok' => false, 'message' => 'No se pudo obtener el token de acceso de Gmail.'];
    }

    $folio = (string)($ticket['folio'] ?? ('#' . ($ticket['numero'] ?? '')));
    $subject = 'Ticket de compra KARMA — ' . $folio;
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
        "Hola " . htmlspecialchars($nombre, ENT_QUOTES, 'UTF-8') . ",<br><br>Adjuntamos tu ticket de compra KARMA (folio {$folio}), con los datos completos de tu vehículo, garantía y comprobante de pago.<br><br>" .
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
        return ['ok' => false, 'message' => 'Gmail rechazó el envío. Revisa las credenciales OAuth y los permisos.'];
    }

    return ['ok' => true, 'message' => 'El PDF con el ticket completo fue enviado al correo del cliente.'];
}
