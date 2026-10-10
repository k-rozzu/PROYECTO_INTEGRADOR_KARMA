<?php
declare(strict_types=1);

/* Ticket completo en PDF (Dompdf) enviado por correo con la API de Brevo; el cuadrito en pantalla sigue siendo el resumen breve */

// Lector de claves del archivo .env (BREVO_API_KEY, remitente, etc.)
require_once dirname(__DIR__) . '/entorno.php';

// Marcas que llevan la garantía de 4 años de la agencia
const KARMA_MARCAS_GARANTIA_4A = ['audi', 'porsche', 'ducati'];

// Dirección oficial de la API de Brevo para correos transaccionales
const KARMA_BREVO_URL = 'https://api.brevo.com/v3/smtp/email';

// Escapa texto para meterlo sin riesgo dentro del HTML del PDF
function h($valor): string {
    return htmlspecialchars((string)($valor ?? ''), ENT_QUOTES, 'UTF-8');
}

// Logo vectorial y sello corporativo azul de KARMA guardados en assets/ (los usan el ticket y el contrato de crédito)
function karmaAssetSvg(string $archivo): string {
    $ruta = dirname(__DIR__, 2) . '/assets/' . $archivo;
    return is_file($ruta) ? (string)file_get_contents($ruta) : '';
}

// Imagen SVG lista para <img src="..."> (funciona igual en el navegador y en dompdf, que la dibuja sin la extensión GD)
function karmaSvgDataUri(string $svg): string {
    return 'data:image/svg+xml;base64,' . base64_encode($svg);
}

// Formatea un monto como "$ 1,234.00"
function karmaMoneyFmt($n): string {
    return '$ ' . number_format((float)($n ?? 0), 2);
}

// Convierte un monto a letras con formato de factura mexicana: "___ PESOS XX/100 M.N."
function numeroALetras(float $monto): string {
    $monto = round($monto, 2);
    $entero = (int) floor($monto);
    $centavos = (int) round(($monto - $entero) * 100);
    $letras = karmaConvertirEntero($entero);
    $letras = $letras === '' ? 'CERO' : $letras;
    return sprintf('%s PESOS %02d/100 M.N.', $letras, $centavos);
}

// Convierte un número entero (incluye millones) a palabras en mayúsculas
function karmaConvertirEntero(int $n): string {
    if ($n === 0) return 'CERO';
    if ($n < 0) return 'MENOS ' . karmaConvertirEntero(-$n);
    if ($n < 1000000) return karmaConvertirMenorMillon($n);

    $millones = intdiv($n, 1000000);
    $resto = $n % 1000000;
    $prefijo = ($millones === 1) ? 'UN MILLON' : karmaApocope(trim(karmaConvertirMenorMillon($millones))) . ' MILLONES';
    return trim($prefijo . ($resto > 0 ? ' ' . karmaConvertirMenorMillon($resto) : ''));
}

// Convierte a palabras un número menor a un millón (miles + centenas)
function karmaConvertirMenorMillon(int $n): string {
    if ($n === 0) return '';
    if ($n < 1000) return karmaConvertirCentenas($n);

    $miles = intdiv($n, 1000);
    $resto = $n % 1000;
    $prefijo = ($miles === 1) ? 'MIL' : karmaApocope(trim(karmaConvertirCentenas($miles))) . ' MIL';
    return trim($prefijo . ($resto > 0 ? ' ' . karmaConvertirCentenas($resto) : ''));
}

// Antes de MIL o MILLONES "UNO" se escribe "UN" (CINCUENTA Y UN MIL, VEINTIUN MILLONES)
function karmaApocope(string $texto): string {
    return (string)preg_replace('/UNO$/', 'UN', $texto);
}

// Convierte a palabras un número de 1 a 999
function karmaConvertirCentenas(int $n): string {
    $centenas = ['', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'];
    if ($n === 100) return 'CIEN';
    $c = intdiv($n, 100);
    $resto = $n % 100;
    $texto = $c > 0 ? $centenas[$c] : '';
    return trim($texto . ($resto > 0 ? ' ' . karmaConvertirDecenas($resto) : ''));
}

// Convierte a palabras un número de 1 a 99 (con los casos especiales del español)
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

// Arma el HTML del ticket completo (todas sus secciones) a partir del ticketCerrado que manda script.js
function construirTicketHTML(string $nombreCliente, string $emailCliente, array $ticket): string {
    $items = is_array($ticket['items'] ?? null) ? $ticket['items'] : [];
    $vehiculos = array_values(array_filter($items, fn($it) => !empty($it['esVehiculo'])));
    $refacciones = array_values(array_filter($items, fn($it) => empty($it['esVehiculo']) && empty($it['esAbono'])));
    $primerVehiculo = $vehiculos[0] ?? null;
    $esCredito = $primerVehiculo && !empty($primerVehiculo['esCredito']);
    // Comprobante de un abono mensual (botón «Cobrar abono» de Clientes): no es una venta de vehículo ni de refacciones
    $abono = is_array($ticket['abono'] ?? null) ? $ticket['abono'] : null;

    $folioTicket = h($ticket['numero'] ?? '');
    $folioCompleto = h($ticket['folio'] ?? ('KRM-' . ($ticket['ventaId'] ?? '')));
    $serieDigital = h($abono ? ($ticket['folio'] ?? '') : 'KRM-' . ($ticket['ventaId'] ?? '0'));
    $fecha = h($ticket['fecha'] ?? date('d/m/Y H:i:s'));
    $sucursalNombre = h($ticket['sucursal'] ?? 'Manzanillo');
    $sucursalDireccion = h($ticket['sucursalDireccion'] ?? '');
    $sucursalTelefono = h($ticket['sucursalTelefono'] ?? '');
    $cajero = h($ticket['cajero'] ?? '');

    $datosComprador = $primerVehiculo ?? $abono;
    $rfcIne = h($datosComprador['rfcIne'] ?? '');
    $direccionCliente = h($datosComprador['direccion'] ?? '');
    $idTipo = h($datosComprador['identificacionTipo'] ?? 'INE');
    $celularCliente = h($datosComprador['celular'] ?? '');

    $subtotal = (float)($ticket['subtotal'] ?? ($ticket['total'] ?? 0));
    $total = (float)($ticket['total'] ?? 0);
    $recibido = (float)($ticket['recibido'] ?? 0);
    $cambio = (float)($ticket['cambio'] ?? 0);
    $totalLetras = h(numeroALetras($total));

    // Un bloque de identificación + garantía por cada vehículo del ticket
    $bloquesVehiculo = '';
    foreach ($vehiculos as $v) {
        $marcaLower = mb_strtolower(trim((string)($v['marca'] ?? '')));
        $conGarantia = in_array($marcaLower, KARMA_MARCAS_GARANTIA_4A, true);
        $bloquesVehiculo .= '
        <table class="tabla-datos">
          <tr><td class="etq">Marca / Modelo / Año</td><td>' . h(trim(($v['marca'] ?? '') . ' ' . ($v['modelo'] ?? '') . ' (' . ($v['anio'] ?? '') . ')')) . '</td></tr>
          <tr><td class="etq">VIN / Número de serie</td><td>' . h(($v['vin'] ?? '') ?: '—') . '</td></tr>
          <tr><td class="etq">Número de motor</td><td>' . h(($v['motorSerie'] ?? '') ?: ($v['motorTipo'] ?? '—')) . '</td></tr>
          <tr><td class="etq">Color exterior</td><td>' . h(($v['colorExterior'] ?? '') ?: '—') . '</td></tr>
          <tr><td class="etq">Color interior</td><td>' . h(($v['colorInterior'] ?? '') ?: '—') . '</td></tr>
          <tr><td class="etq">Kilometraje de entrega</td><td>0 km</td></tr>
          <tr><td class="etq">Estado de la unidad</td><td>Unidad Nueva</td></tr>
          <tr><td class="etq">Garantía</td><td>' . ($conGarantia ? '4 años de garantía KARMA' : 'Consultar condiciones de garantía con el vendedor') . '</td></tr>
          ' . (!empty($v['esCredito'])
            ? '<tr><td class="etq">Precio de contado</td><td>' . karmaMoneyFmt($v['precioContado'] ?? 0) . '</td></tr>
          <tr><td class="etq">Cobrado hoy (enganche)</td><td>' . karmaMoneyFmt($v['precioTotal'] ?? 0) . '</td></tr>'
            : '<tr><td class="etq">Precio</td><td>' . karmaMoneyFmt($v['precioTotal'] ?? 0) . '</td></tr>') . '
        </table>';
    }

    // Refacciones dentro del mismo ticket (si las hay): tabla simple de líneas
    $filasRefacciones = '';
    foreach ($refacciones as $r) {
        $filasRefacciones .= '<tr><td>' . h($r['articulo'] ?? '') . '</td><td class="der">' . karmaMoneyFmt($r['precioTotal'] ?? 0) . '</td></tr>';
    }

    // Condiciones del crédito, solo cuando el vehículo se vendió a crédito
    $bloqueCredito = '';
    if ($esCredito && $primerVehiculo) {
        $bloqueCredito = '
        <h2>5b. Condiciones de crédito</h2>
        <table class="tabla-datos">
          ' . (!empty($ticket['contrato']['folio']) ? '<tr><td class="etq">Contrato de crédito</td><td>' . h($ticket['contrato']['folio']) . ' (se adjunta firmado)</td></tr>' : '') . '
          <tr><td class="etq">Precio de contado</td><td>' . karmaMoneyFmt($primerVehiculo['precioContado'] ?? 0) . '</td></tr>
          <tr><td class="etq">Enganche</td><td>' . karmaMoneyFmt($primerVehiculo['enganche'] ?? 0) . '</td></tr>
          <tr><td class="etq">Saldo a financiar</td><td>' . karmaMoneyFmt($primerVehiculo['saldoFinanciar'] ?? 0) . '</td></tr>
          <tr><td class="etq">Plazo</td><td>' . h($primerVehiculo['abonos'] ?? '') . '</td></tr>
          <tr><td class="etq">Tasa de interés anual</td><td>' . h($primerVehiculo['tasaAnual'] ?? '') . '%</td></tr>
          <tr><td class="etq">Comisión por apertura</td><td>' . karmaMoneyFmt($primerVehiculo['comisionApertura'] ?? 0) . '</td></tr>
          <tr><td class="etq">Monto de interés</td><td>' . karmaMoneyFmt($primerVehiculo['montoInteres'] ?? 0) . '</td></tr>
          <tr><td class="etq">Monto final financiado</td><td>' . karmaMoneyFmt($primerVehiculo['montoFinal'] ?? 0) . '</td></tr>
          <tr><td class="etq">Mensualidad estimada</td><td>' . karmaMoneyFmt($primerVehiculo['montoAbono'] ?? 0) . '</td></tr>
        </table>';
    }

    // Leyenda de forma de pago según sea contado o crédito
    $bloqueAbono = '';
    if ($abono) {
        $bloqueAbono = '
        <h2>2. Abono a crédito automotriz</h2>
        <table class="tabla-datos">
          <tr><td class="etq">Concepto</td><td>Abono mensual</td></tr>
          <tr><td class="etq">Contrato de crédito</td><td>' . h($abono['contratoFolio'] ?? '') . '</td></tr>
          <tr><td class="etq">Vehículo</td><td>' . h($abono['vehiculo'] ?? '') . (!empty($abono['vin']) ? ' · VIN ' . h($abono['vin']) : '') . '</td></tr>
          <tr><td class="etq">Mensualidad</td><td>' . h(($abono['numero'] ?? '') . ' de ' . ($abono['plazo'] ?? '')) . (!empty($abono['vence']) ? ' · vencimiento ' . h($abono['vence']) : '') . '</td></tr>
          <tr><td class="etq">Importe del abono</td><td>' . karmaMoneyFmt($abono['importe'] ?? 0) . '</td></tr>
          <tr><td class="etq">Saldo anterior</td><td>' . karmaMoneyFmt($abono['saldoAnterior'] ?? 0) . '</td></tr>
          <tr><td class="etq">Saldo pendiente después del abono</td><td>' . karmaMoneyFmt($abono['saldoRestante'] ?? 0) . (!empty($abono['liquidado']) ? ' — CRÉDITO LIQUIDADO' : '') . '</td></tr>
        </table>';
    }

    $leyendaPago = $abono
        ? ('Forma de pago: ABONO MENSUAL A CRÉDITO — PAGO ' . h(($abono['numero'] ?? '') . ' DE ' . ($abono['plazo'] ?? '')) . (!empty($abono['liquidado']) ? ' (CRÉDITO LIQUIDADO).' : '.'))
        : ($esCredito
        ? ('Forma de pago: ENGANCHE + FINANCIAMIENTO A ' . h($primerVehiculo['abonos'] ?? '') . '.')
        : 'Forma de pago: PAGO EN UNA SOLA EXHIBICIÓN — CONTADO.');

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
      .firma{ margin-top:16px; width:230px; text-align:center; }
      .firma .sello{ width:112px; height:112px; margin:0 auto -6px; display:block; }
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

      ' . $bloqueAbono . '

      <h2>3. Desglose financiero</h2>
      <table class="tabla-datos">
        <tr><td class="etq">Subtotal</td><td>' . karmaMoneyFmt($subtotal) . '</td></tr>
        <tr><td class="etq">' . ($esCredito ? 'Total cobrado hoy (enganche y contado)' : 'Total') . '</td><td>' . karmaMoneyFmt($total) . '</td></tr>
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
        <strong>Conformidad del cliente:</strong> &ldquo;' . ($abono ? 'Recibí comprobante del abono arriba descrito.' : 'Recibí de conformidad el vehículo y los documentos arriba descritos.') . '&rdquo;
      </div>
      <div class="firma">' . (($sello = karmaAssetSvg('sello-karma.svg')) !== '' ? '<img class="sello" src="' . karmaSvgDataUri($sello) . '" alt="Sello digital de KARMA S.A. de C.V.">' : '') . '________________________________<br><span class="muted">Firma digital / sello de recepción del vendedor</span></div>

    </body></html>';
}

// Convierte el HTML del ticket en un PDF (bytes) usando Dompdf
function generarPdfTicket(string $html): string {
    $dompdf = new Dompdf\Dompdf();
    $dompdf->loadHtml($html, 'UTF-8');
    $dompdf->setPaper('letter', 'portrait');
    $dompdf->render();
    return $dompdf->output();
}

// Cuerpo (HTML) del correo que acompaña al PDF adjunto
function construirCuerpoCorreo(string $nombre, string $folio): string {
    return '<div style="font-family:Arial,sans-serif;font-size:14px;color:#17181A;line-height:1.5">'
        . '<p>Hola ' . h($nombre) . ',</p>'
        . '<p>Adjuntamos tu ticket de compra KARMA (folio <strong>' . h($folio) . '</strong>), con los datos completos de tu vehículo, garantía y comprobante de pago.</p>'
        . '<p>Gracias por tu compra.<br><strong style="color:#10213F">KARMA</strong> — Te damos el auto que te mereces</p>'
        . '</div>';
}

// Carga Dompdf (se instala con Composer en PHP/PuntoDeVenta/vendor). Regresa null si está listo o el mensaje del problema
function karmaCargarDompdf(): ?string {
    $autoload = __DIR__ . '/vendor/autoload.php';
    if (!file_exists($autoload)) {
        return 'Falta instalar Dompdf: abre una terminal en PHP/PuntoDeVenta y ejecuta "composer install" (ver explicacion_api.txt).';
    }
    require_once $autoload;
    if (!class_exists('Dompdf\\Dompdf')) {
        return 'Dompdf no está disponible. Ejecuta "composer install" en PHP/PuntoDeVenta.';
    }
    return null;
}

// API BREVO: genera el PDF del ticket y lo manda como adjunto al correo del cliente (POST https://api.brevo.com/v3/smtp/email).
// $adjuntosExtra = otros PDF ya generados (ej. el contrato de crédito firmado): [['name' => ..., 'content' => base64], ...]
function enviarTicketPorCorreo(string $email, string $nombre, array $ticket, array $adjuntosExtra = []): array {
    // Dompdf se instala con Composer (carpeta vendor dentro de PHP/PuntoDeVenta)
    $errorDompdf = karmaCargarDompdf();
    if ($errorDompdf !== null) {
        return ['ok' => false, 'message' => $errorDompdf];
    }

    // API BREVO: credenciales leídas del archivo .env (nunca se mandan al navegador)
    $apiKey = karmaEnv('BREVO_API_KEY');
    $remitenteEmail = karmaEnv('BREVO_REMITENTE_EMAIL');
    $remitenteNombre = karmaEnv('BREVO_REMITENTE_NOMBRE', 'KARMA Agencia de Autos');
    if ($apiKey === '' || $remitenteEmail === '') {
        return ['ok' => false, 'message' => 'El correo aún no está configurado: agrega BREVO_API_KEY y BREVO_REMITENTE_EMAIL al archivo .env (ver explicacion_api.txt).'];
    }

    // Ticket completo en HTML → PDF
    $pdf = generarPdfTicket(construirTicketHTML($nombre, $email, $ticket));
    $folio = (string)($ticket['folio'] ?? ('#' . ($ticket['numero'] ?? '')));
    $nombreArchivo = 'ticket-karma-' . preg_replace('/[^A-Za-z0-9\-]/', '', $folio) . '.pdf';

    // API BREVO: cuerpo JSON de la petición (remitente, destinatario, asunto, HTML y PDF en base64)
    $conContrato = !empty($adjuntosExtra);
    $payload = [
        'sender' => ['name' => $remitenteNombre, 'email' => $remitenteEmail],
        'to' => [['email' => $email, 'name' => $nombre]],
        'replyTo' => ['email' => $remitenteEmail, 'name' => $remitenteNombre],
        'subject' => ($conContrato ? 'Ticket y contrato de crédito KARMA — ' : 'Ticket de compra KARMA — ') . $folio,
        'htmlContent' => construirCuerpoCorreo($nombre, $folio)
            . ($conContrato ? '<p style="font-family:Arial,sans-serif;font-size:14px;color:#17181A">También adjuntamos tu contrato de crédito firmado en PDF. Consérvalo para cualquier aclaración.</p>' : ''),
        'attachment' => array_merge([['name' => $nombreArchivo, 'content' => base64_encode($pdf)]], $adjuntosExtra)
    ];

    // API BREVO: llamada HTTPS con la clave en el encabezado "api-key"
    $ch = curl_init(KARMA_BREVO_URL);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTPHEADER => [
            'accept: application/json',
            'content-type: application/json',
            'api-key: ' . $apiKey
        ],
        CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE)
    ]);
    $respuesta = curl_exec($ch);
    $http = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $errorRed = curl_error($ch);
    curl_close($ch);

    // API BREVO: sin conexión a internet o bloqueo de red
    if ($respuesta === false) {
        return ['ok' => false, 'message' => 'No se pudo conectar con Brevo: ' . $errorRed];
    }

    // API BREVO: 201 = correo aceptado; cualquier otro código trae un mensaje de error en JSON
    $datos = json_decode((string)$respuesta, true) ?: [];
    if ($http < 200 || $http >= 300) {
        $detalle = $datos['message'] ?? ('código HTTP ' . $http);
        return ['ok' => false, 'message' => 'Brevo rechazó el envío: ' . $detalle];
    }

    $enviado = $conContrato ? 'El ticket y el contrato de crédito firmado (PDF) fueron enviados a ' : 'El PDF con el ticket completo fue enviado a ';
    return ['ok' => true, 'message' => $enviado . $email . '.', 'id' => $datos['messageId'] ?? null];
}
