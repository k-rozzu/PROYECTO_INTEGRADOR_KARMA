<?php
declare(strict_types=1);

/* KARMA · Crédito automotriz con contrato firmado (Punto de Venta). Lo carga api.php solo en estas rutas:
   1) preparar_credito  -> ya se cobró el enganche (o es de $0) y el enrutador ya validó el gafete del empleado (acción CREDITO).
                           El servidor recalcula precio, enganche, mensualidad, CAT y tabla de amortización con la misma fórmula
                           del POS y guarda el contrato como 'pendiente_firma'. Todavía NO hay venta, ni cliente, ni inventario descontado.
   2) concretar_credito -> con la firma del cliente: en UNA transacción registra la venta, descuenta el inventario, registra o actualiza
                           al cliente, genera el PDF definitivo y deja el contrato 'firmado'. Si algo falla no se guarda nada.
   3) cancelar_credito  -> el cliente no firmó: el contrato queda 'cancelado' y no se registra ninguna venta.
   4) ver_contrato      -> entrega el PDF guardado (ticket y sección Clientes). */

// h(), karmaMoneyFmt(), numeroALetras(), karmaCargarDompdf() y el sello/logo SVG (karmaAssetSvg) del ticket en PDF
require_once __DIR__ . '/correo.php';

// Datos de la empresa: el RFC es de DEMOSTRACIÓN (no existe en el sistema) y así se indica en el contrato
const KARMA_RAZON_SOCIAL = 'KARMA S.A. de C.V.';
const KARMA_RFC_DEMO = 'KAR000000DEM';
// Mismos valores que PLAZOS_CREDITO y COMISION_APERTURA_PCT de JavaScript/PuntoDeVenta/script.js
const KARMA_CREDITO_PLAZOS = [12, 24, 36, 48, 60];
const KARMA_CREDITO_COMISION_APERTURA = 0.02;
// Tasa moratoria anual (%). KARMA todavía no la ha definido: con null el contrato lo dice así en lugar de inventar una tasa
const KARMA_CREDITO_TASA_MORATORIA = null;
// Segundos que tiene el cliente para firmar un contrato ya preparado
const KARMA_CONTRATO_VIGENCIA_FIRMA = 1800;
// Método de pago de los créditos sin enganche (Database/contrato_credito.sql)
const KARMA_METODO_SIN_COBRO = 'Sin cobro (enganche $0)';

/* ===================== Cálculos (idénticos a los del módulo de crédito del POS) ===================== */

// Misma fórmula que calcularCredito() de script.js: anualidad vencida con tasa fija y comisión por apertura financiada
function contratoCalcularCredito(float $precio, float $enganche, int $plazo, float $tasaAnualPct): array {
    $base = max($precio - $enganche, 0);
    $comision = $base * KARMA_CREDITO_COMISION_APERTURA;
    $financiado = $base + $comision;
    $i = $tasaAnualPct / 100 / 12;
    $n = $plazo;
    $mensualidad = $i > 0
        ? $financiado * ($i * pow(1 + $i, $n)) / (pow(1 + $i, $n) - 1)
        : $financiado / $n;
    $montoFinal = $mensualidad * $n;
    return [
        'baseFinanciar' => $base, 'comisionApertura' => $comision, 'montoFinanciado' => $financiado,
        'i' => $i, 'n' => $n, 'mensualidad' => $mensualidad, 'montoFinal' => $montoFinal, 'montoInteres' => $montoFinal - $financiado
    ];
}

// Fecha de la mensualidad número $meses: mismo día de la firma o el último día del mes cuando ese día no existe
function contratoFechaVencimiento(DateTimeImmutable $inicio, int $meses): DateTimeImmutable {
    $dia = (int)$inicio->format('j');
    $mes = $inicio->modify('first day of this month')->modify("+{$meses} month");
    return $mes->setDate((int)$mes->format('Y'), (int)$mes->format('n'), min($dia, (int)$mes->format('t')));
}

// Misma tabla que tablaAmortizacionHTML() de script.js (cuota, abono a capital, interés y saldo) más la fecha de cada pago
function contratoTablaAmortizacion(array $c, DateTimeImmutable $inicio): array {
    $saldo = $c['montoFinanciado'];
    $filas = [];
    for ($mes = 1; $mes <= $c['n']; $mes++) {
        $interes = $saldo * $c['i'];
        $capital = $c['mensualidad'] - $interes;
        $saldo = max($saldo - $capital, 0);
        $filas[] = [
            'pago' => $mes, 'fecha' => contratoFechaVencimiento($inicio, $mes)->format('d/m/Y'),
            'cuota' => round($c['mensualidad'], 2), 'capital' => round($capital, 2), 'interes' => round($interes, 2), 'saldo' => round($saldo, 2)
        ];
    }
    return $filas;
}

// CAT (costo anual total, sin IVA): tasa anual efectiva que iguala lo que recibe el acreditado (saldo financiado sin la comisión)
// con lo que paga (todas sus mensualidades, que ya incluyen la comisión por apertura). Se calcula con los datos reales de la operación.
function contratoCalcularCAT(float $recibido, float $pago, int $n): ?float {
    if ($recibido <= 0 || $pago <= 0 || $n <= 0) return null;
    if ($pago * $n <= $recibido + 0.000001) return 0.0;
    $valorPresente = fn(float $i): float => $pago * (1 - pow(1 + $i, -$n)) / $i;
    $bajo = 0.0000001;
    $alto = 1.0;
    for ($k = 0; $k < 200; $k++) {
        $medio = ($bajo + $alto) / 2;
        if ($valorPresente($medio) > $recibido) $bajo = $medio; else $alto = $medio;
    }
    return round((pow(1 + ($bajo + $alto) / 2, 12) - 1) * 100, 1);
}

// Hora de la base de datos (la misma de ventas.fecha_hora) en la zona horaria de las sucursales
function contratoAhora(PDO $pdo): DateTimeImmutable {
    return new DateTimeImmutable((string)$pdo->query('SELECT NOW()')->fetchColumn(), new DateTimeZone(KARMA_ZONA_HORARIA));
}

// "10 de octubre de 2026"
function contratoFechaLarga(DateTimeImmutable $f): string {
    $meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return $f->format('j') . ' de ' . $meses[(int)$f->format('n') - 1] . ' de ' . $f->format('Y');
}

/* ===================== Validación de lo que manda el navegador ===================== */

// Datos del acreditado capturados en el formulario de crédito (todo lo que el contrato necesita es obligatorio, salvo correo y celular)
function contratoNormalizarCliente(array $c): array {
    $texto = fn(string $k, int $max): string => mb_substr(trim(preg_replace('/\s+/u', ' ', (string)($c[$k] ?? ''))), 0, $max);
    $cliente = [
        'nombre' => $texto('nombre', 150),
        'rfc_curp' => strtoupper(str_replace(' ', '', $texto('rfc_curp', 20))),
        'email' => $texto('email', 120),
        'celular' => $texto('celular', 30),
        'direccion' => $texto('direccion', 255),
        'identificacion_tipo' => $texto('identificacion_tipo', 30),
        'identificacion_numero' => strtoupper($texto('identificacion_numero', 40))
    ];
    if ($cliente['nombre'] === '') fail('Escribe el nombre completo del cliente.');
    if (!contratoRfcCurpValido($cliente['rfc_curp'])) fail('El RFC debe tener 12 o 13 caracteres (3 o 4 letras, 6 números y 3 letras o números) y la CURP 18 (4 letras, 6 números y 8 letras o números).');
    if ($cliente['direccion'] === '') fail('El contrato necesita el domicilio particular del cliente.');
    if (!in_array($cliente['identificacion_tipo'], ['INE', 'Pasaporte', 'Otra'], true)) fail('Elige el tipo de identificación oficial.');
    if ($cliente['identificacion_numero'] === '') fail('Escribe el número o folio de la identificación oficial.');
    if ($cliente['email'] !== '' && !filter_var($cliente['email'], FILTER_VALIDATE_EMAIL)) fail('El correo electrónico del cliente no es válido.');
    return $cliente;
}

// Estructura de RFC (12 o 13) o CURP (18): solo letras y números en sus posiciones. No exige que el dato exista
// (ni sexo, entidad o dígito verificador reales): el proyecto usa RFC y CURP ficticios
function contratoRfcCurpValido(string $v): bool {
    return (bool)preg_match('/^([A-ZÑ&]{3,4}\d{6}[A-ZÑ\d]{3}|[A-ZÑ]{4}\d{6}[A-ZÑ\d]{8})$/u', $v);
}

// Parámetros del crédito elegidos en el formulario (enganche, plazo y tasa) + lo que calculó el navegador para comparar
function contratoNormalizarParametros(array $p): array {
    $tipo = ($p['enganche_tipo'] ?? '') === 'pct' ? 'pct' : 'monto';
    $bruto = $p['enganche_valor'] ?? 0;
    if ($bruto === '' || $bruto === null) $bruto = 0;   // enganche vacío = $0
    if (!is_numeric($bruto)) fail('El enganche no es un número válido.');
    $valor = (float)$bruto;
    $plazo = (int)($p['plazo_meses'] ?? 0);
    $tasa = is_numeric($p['tasa_anual'] ?? null) ? (float)$p['tasa_anual'] : -1.0;
    if ($valor < 0) fail('El enganche no puede ser negativo.');
    if ($tipo === 'pct' && $valor >= 100) fail('El porcentaje de enganche debe ser menor a 100%.');
    if (!in_array($plazo, KARMA_CREDITO_PLAZOS, true)) fail('Elige un plazo válido para el crédito.');
    if ($tasa < 0 || $tasa > 100) fail('La tasa de interés anual no es válida.');
    return [
        'producto_id' => (int)($p['producto_id'] ?? 0), 'enganche_tipo' => $tipo, 'enganche_valor' => $valor,
        'plazo' => $plazo, 'tasa' => round($tasa, 3),
        'esperado_enganche' => (float)($p['esperado']['enganche'] ?? -1),
        'esperado_mensualidad' => (float)($p['esperado']['mensualidad'] ?? -1)
    ];
}

// Artículos del ticket: solo los campos que usa la venta
function contratoNormalizarItems($items): array {
    if (!is_array($items) || !$items) fail('El ticket está vacío.');
    $lista = [];
    foreach ($items as $it) {
        if (!is_array($it)) fail('Hay un artículo no válido en el ticket.');
        $lista[] = [
            'producto_id' => (int)($it['producto_id'] ?? 0),
            'cantidad' => max(1, (int)($it['cantidad'] ?? 1)),
            'vin' => trim((string)($it['vin'] ?? '')),
            'motor_serie' => trim((string)($it['motor_serie'] ?? '')),
            'color_interior' => trim((string)($it['color_interior'] ?? '')),
            'es_credito' => !empty($it['es_credito'])
        ];
    }
    $creditos = array_keys(array_filter($lista, fn($it) => $it['es_credito']));
    if (count($creditos) !== 1) fail('El ticket debe tener un solo vehículo a crédito (un contrato por operación).');
    if ($lista[$creditos[0]]['cantidad'] !== 1) fail('El crédito es por una sola unidad.');
    return $lista;
}

/* ===================== Datos del sistema para el contrato ===================== */

function contratoDatosVehiculo(PDO $pdo, int $idProducto): array {
    $stmt = $pdo->prepare("
        SELECT p.id_producto, p.codigo_barras, p.nombre, p.marca, p.modelo, p.anio, p.tipo, p.color, p.color_interior,
               p.motor, p.cilindraje, p.vin, p.numero_motor, pw.condicion, pw.transmision, pw.potencia
        FROM productos p
        LEFT JOIN productos_web pw ON pw.id_producto = p.id_producto
        WHERE p.id_producto = ?
    ");
    $stmt->execute([$idProducto]);
    $v = $stmt->fetch();
    if (!$v) throw new RuntimeException('El vehículo ya no existe en el catálogo.');
    if (!in_array($v['tipo'], ['auto', 'moto'], true)) throw new RuntimeException('El crédito solo aplica para vehículos.');
    return $v;
}

// Arma la copia completa de la operación que se guarda en contratos_credito.datos_json y con la que se dibuja el contrato
function contratoArmarDatos(PDO $pdo, array $cajero, int $idCaja, int $ticketNumero, array $op, DateTimeImmutable $ahora): array {
    $suc = $pdo->prepare("SELECT nombre, direccion, telefono, ciudad, email FROM sucursales WHERE id_sucursal = ?");
    $suc->execute([(int)$cajero['id_sucursal']]);
    $sucursal = $suc->fetch() ?: [];

    $emp = $pdo->prepare("SELECT u.nombre, u.apellidos, u.codigo_empleado, r.nombre_rol FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol WHERE u.id_usuario = ?");
    $emp->execute([(int)$cajero['id_usuario']]);
    $empleado = $emp->fetch() ?: [];
    $nombreRepresentante = trim(($empleado['nombre'] ?? $cajero['nombre']) . ' ' . ($empleado['apellidos'] ?? ''));

    $caja = $pdo->prepare("SELECT numero_caja FROM cajas WHERE id_caja = ?");
    $caja->execute([$idCaja]);
    $numeroCaja = str_pad((string)(int)$caja->fetchColumn(), 2, '0', STR_PAD_LEFT);

    $v = $op['vehiculo'];
    $c = $op['calculo'];
    $esNuevo = ($v['condicion'] ?? null) === 'nuevo';
    $version = implode(' · ', array_filter([$v['motor'] ?? '', $v['transmision'] ?? '', $v['potencia'] ?? '']));
    $amortizacion = contratoTablaAmortizacion($c, $ahora);

    return [
        'folio' => null,
        'operacion' => [
            'fecha' => $ahora->format('d/m/Y'), 'fecha_larga' => contratoFechaLarga($ahora), 'hora' => $ahora->format('H:i:s'),
            'fecha_iso' => $ahora->format('Y-m-d H:i:s'),
            'sucursal' => $sucursal['nombre'] ?? '', 'sucursal_ciudad' => ($sucursal['ciudad'] ?? '') ?: ($sucursal['nombre'] ?? ''),
            'caja' => $numeroCaja, 'ticket' => $ticketNumero, 'folio_venta' => null, 'id_venta' => null,
            'cajero' => $nombreRepresentante, 'codigo_empleado' => $empleado['codigo_empleado'] ?? '',
            'metodo_pago' => $op['metodo'], 'importe_cobrado' => $op['importe'], 'recibido' => $op['recibido'], 'cambio' => $op['cambio']
        ],
        'vendedor' => [
            'razon_social' => KARMA_RAZON_SOCIAL, 'rfc' => KARMA_RFC_DEMO,
            'domicilio' => $sucursal['direccion'] ?? '', 'telefono' => $sucursal['telefono'] ?? '', 'email' => $sucursal['email'] ?? '',
            'sucursal' => $sucursal['nombre'] ?? ''
        ],
        'representante' => [
            'nombre' => $nombreRepresentante, 'rol' => $empleado['nombre_rol'] ?? 'Cajero', 'codigo' => $empleado['codigo_empleado'] ?? ''
        ],
        'acreditado' => $op['cliente'],
        'vehiculo' => [
            'id_producto' => (int)$v['id_producto'], 'tipo' => $v['tipo'], 'marca' => $v['marca'], 'modelo' => $v['modelo'],
            'anio' => $v['anio'] !== null ? (int)$v['anio'] : null, 'version' => $version, 'cilindraje' => $v['cilindraje'],
            'vin' => $op['vin'], 'numero_motor' => $v['numero_motor'], 'color' => $v['color'], 'color_interior' => $v['color_interior'],
            'condicion' => $v['condicion'], 'nuevo' => $esNuevo, 'codigo' => $v['codigo_barras']
        ],
        'credito' => [
            'precio_contado' => $op['precio'], 'enganche' => $op['enganche'], 'enganche_tipo' => $op['parametros']['enganche_tipo'],
            'enganche_pct' => $op['precio'] > 0 ? round($op['enganche'] / $op['precio'] * 100, 2) : 0,
            'saldo_financiar' => round($c['baseFinanciar'], 2), 'comision_apertura_pct' => KARMA_CREDITO_COMISION_APERTURA * 100,
            'comision_apertura' => round($c['comisionApertura'], 2), 'monto_financiado' => round($c['montoFinanciado'], 2),
            'tasa_anual' => $op['parametros']['tasa'], 'tasa_mensual' => round($op['parametros']['tasa'] / 12, 4),
            'tasa_moratoria' => KARMA_CREDITO_TASA_MORATORIA,
            'cat' => contratoCalcularCAT($c['baseFinanciar'], $c['mensualidad'], $c['n']),
            'plazo_meses' => $c['n'], 'mensualidad' => round($c['mensualidad'], 2), 'monto_interes' => round($c['montoInteres'], 2),
            'monto_total' => round($c['montoFinal'], 2), 'dia_pago' => (int)$ahora->format('j'),
            'primer_vencimiento' => $amortizacion[0]['fecha'], 'ultimo_vencimiento' => end($amortizacion)['fecha']
        ],
        'amortizacion' => $amortizacion,
        'otros_articulos' => $op['otros'],
        'solicitud' => $op['solicitud']
    ];
}

// Valida y calcula la operación completa (precio de la BD, enganche, crédito, importe a cobrar y pago). Lanza fail() si algo no cuadra
function contratoCalcularOperacion(PDO $pdo, array $items, array $lineas, array $parametros, array $pago): array {
    $idx = array_key_first(array_filter($items, fn($it) => $it['es_credito']));
    $lineaCredito = $lineas[$idx];
    if ($parametros['producto_id'] !== $lineaCredito['id']) fail('Los datos del crédito no corresponden al vehículo del ticket.');
    $vehiculo = contratoDatosVehiculo($pdo, $lineaCredito['id']);

    $precio = (float)$lineaCredito['precio'];
    $enganche = $parametros['enganche_tipo'] === 'pct'
        ? money($precio * $parametros['enganche_valor'] / 100)
        : money($parametros['enganche_valor']);
    if ($enganche >= $precio) fail('El enganche debe ser menor que el precio de contado del vehículo.');

    $calculo = contratoCalcularCredito($precio, $enganche, $parametros['plazo'], $parametros['tasa']);
    // Debe coincidir con lo que vio el cliente en pantalla: así no hay diferencias entre el ticket, el contrato y lo registrado
    if (abs($enganche - $parametros['esperado_enganche']) > 0.01 || abs($calculo['mensualidad'] - $parametros['esperado_mensualidad']) > 0.01) {
        fail('Los importes del crédito no coinciden con el cálculo del sistema. Quita el crédito del ticket y vuelve a capturarlo.', 409);
    }

    // Otros artículos del mismo ticket (de contado): se cobran completos junto con el enganche
    $otros = [];
    $contado = 0.0;
    foreach ($lineas as $k => $l) {
        if ($k === $idx) continue;
        $contado += $l['subtotal'];
        $nombre = $pdo->prepare("SELECT nombre FROM productos WHERE id_producto = ?");
        $nombre->execute([$l['id']]);
        $otros[] = ['descripcion' => (string)$nombre->fetchColumn(), 'cantidad' => $l['cantidad'], 'precio' => $l['precio'], 'subtotal' => $l['subtotal']];
    }
    $importe = money($enganche + $contado);

    if ($importe > 0) {
        // Mismo cobro que una venta normal: hoy solo está habilitado el efectivo (la terminal de tarjeta aún no está conectada)
        if ($pago['metodo'] !== 'Efectivo') fail('Selecciona un método de pago disponible para cobrar el enganche.');
        if ($pago['recibido'] < $importe) fail('El dinero recibido es menor al importe a cobrar.');
        $metodo = 'Efectivo';
        $recibido = $pago['recibido'];
        $cambio = money($recibido - $importe);
    } else {
        // Enganche de $0 y nada más que cobrar: no hay pago, solo la verificación del empleado
        $metodo = KARMA_METODO_SIN_COBRO;
        $recibido = 0.0;
        $cambio = 0.0;
    }

    return [
        'vehiculo' => $vehiculo, 'vin' => $lineaCredito['vin'], 'precio' => $precio, 'enganche' => $enganche, 'calculo' => $calculo,
        'parametros' => $parametros, 'otros' => $otros, 'importe' => $importe, 'metodo' => $metodo, 'recibido' => $recibido, 'cambio' => $cambio,
        'articulo' => trim("{$vehiculo['marca']} {$vehiculo['modelo']}") . ($vehiculo['anio'] ? " ({$vehiculo['anio']})" : '')
    ];
}

/* ===================== Firma del cliente, sello y logo (SVG: dompdf los dibuja sin la extensión GD) ===================== */

// Recibe los trazos ya acomodados por el navegador en un lienzo de 600 x 200 y arma el SVG en el servidor
// (nunca se acepta un SVG del navegador: solo números, revisados uno por uno)
function contratoFirmaSVG($trazos): string {
    if (!is_array($trazos) || !$trazos) fail('Falta la firma del cliente.');
    if (count($trazos) > 80) fail('La firma tiene demasiados trazos. Pulsa «Volver a intentar».');
    $rutas = '';
    $puntos = 0;
    $minX = INF; $maxX = -INF; $minY = INF; $maxY = -INF;
    $estilo = 'fill="none" stroke="#0D1B3E" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"';
    foreach ($trazos as $trazo) {
        if (!is_array($trazo) || !$trazo) continue;
        $pts = [];
        foreach ($trazo as $p) {
            if (!is_array($p) || !isset($p[0], $p[1]) || !is_numeric($p[0]) || !is_numeric($p[1])) fail('La firma no es válida. Pulsa «Volver a intentar».');
            $x = round(max(0.0, min(600.0, (float)$p[0])), 1);
            $y = round(max(0.0, min(200.0, (float)$p[1])), 1);
            $pts[] = [$x, $y];
            $minX = min($minX, $x); $maxX = max($maxX, $x); $minY = min($minY, $y); $maxY = max($maxY, $y);
        }
        $puntos += count($pts);
        if ($puntos > 6000) fail('La firma es demasiado extensa. Pulsa «Volver a intentar».');
        if (count($pts) === 1) {
            $rutas .= sprintf('<circle cx="%.1f" cy="%.1f" r="2" fill="#0D1B3E"/>', $pts[0][0], $pts[0][1]);
            continue;
        }
        // Suavizado con curvas por los puntos medios (igual que el lienzo de firma en pantalla)
        $d = sprintf('M%.1f %.1f', $pts[0][0], $pts[0][1]);
        $total = count($pts);
        for ($k = 1; $k < $total - 1; $k++) {
            $d .= sprintf(' Q%.1f %.1f %.1f %.1f', $pts[$k][0], $pts[$k][1], ($pts[$k][0] + $pts[$k + 1][0]) / 2, ($pts[$k][1] + $pts[$k + 1][1]) / 2);
        }
        $d .= sprintf(' L%.1f %.1f', $pts[$total - 1][0], $pts[$total - 1][1]);
        $rutas .= '<path ' . $estilo . ' d="' . $d . '"/>';
    }
    if ($puntos < 8 || ($maxX - $minX) < 30) fail('La firma es demasiado corta. Pide al cliente que firme de nuevo.');
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 200" width="600" height="200">' . $rutas . '</svg>';
}

/* ===================== Documento ===================== */

function contratoDinero($n): string {
    return '$' . number_format((float)$n, 2);
}

function contratoPct($n, int $decimales = 2): string {
    return number_format((float)$n, $decimales) . '%';
}

// Cláusulas de demostración (se indican como tales en el documento y no afirman validez jurídica)
function contratoClausulas(array $d): array {
    $cr = $d['credito'];
    $op = $d['operacion'];
    $ciudad = $op['sucursal_ciudad'] ?: $op['sucursal'];
    $vehiculo = trim($d['vehiculo']['marca'] . ' ' . $d['vehiculo']['modelo'] . ' ' . $d['vehiculo']['anio']);
    $engancheTxt = $cr['enganche'] > 0
        ? 'EL ACREDITADO entrega en este acto, por concepto de enganche, la cantidad de ' . contratoDinero($cr['enganche']) . ' (' . numeroALetras((float)$cr['enganche']) . '), equivalente al ' . contratoPct($cr['enganche_pct']) . ' del precio, cobrada en la caja ' . $op['caja'] . ' de la sucursal ' . $op['sucursal'] . ' mediante ' . mb_strtolower($op['metodo_pago']) . ','
        : 'EL ACREDITADO no entrega enganche (enganche de $0.00),';
    $moratoria = $cr['tasa_moratoria'] !== null
        ? 'En caso de que EL ACREDITADO no cubra puntualmente cualquier mensualidad, la cantidad vencida causará intereses moratorios a la tasa anual de ' . contratoPct($cr['tasa_moratoria']) . ', calculados por los días de atraso y hasta su pago total, sin perjuicio de los intereses ordinarios.'
        : 'Para esta operación el sistema de KARMA no tiene pactada una tasa de interés moratoria. En caso de atraso en el pago de cualquier mensualidad, las partes se estarán a lo que disponga la legislación aplicable, sin que KARMA pueda cobrar cargos que no estén previstos en este contrato.';

    return [
        ['Objeto', 'KARMA vende a EL ACREDITADO, y éste compra, el vehículo automotor nuevo descrito en el apartado III (' . $vehiculo . ', VIN ' . $d['vehiculo']['vin'] . '). Asimismo, KARMA otorga a EL ACREDITADO un crédito simple por el saldo del precio, en los términos y condiciones de este contrato.'],
        ['Precio y enganche', 'El precio de contado del vehículo es de ' . contratoDinero($cr['precio_contado']) . ' (' . numeroALetras((float)$cr['precio_contado']) . '), impuestos incluidos. ' . $engancheTxt . ' por lo que queda un saldo neto pendiente de financiamiento de ' . contratoDinero($cr['saldo_financiar']) . ' (' . numeroALetras((float)$cr['saldo_financiar']) . ').'],
        ['Monto del crédito y comisión por apertura', 'Sobre el saldo pendiente se causa una comisión por apertura del ' . contratoPct($cr['comision_apertura_pct'], 0) . ' por ' . contratoDinero($cr['comision_apertura']) . ', que se financia junto con el saldo, de modo que el monto total financiado es de ' . contratoDinero($cr['monto_financiado']) . '. KARMA no cobra comisiones por administración del crédito ni por pago anticipado.'],
        ['Intereses ordinarios', 'El monto financiado causará intereses ordinarios a la tasa FIJA anual de ' . contratoPct($cr['tasa_anual']) . ' (' . contratoPct($cr['tasa_mensual'], 4) . ' mensual), calculados sobre saldos insolutos y pagaderos junto con cada mensualidad, conforme a la tabla de amortización del apartado IV. La tasa no variará durante la vigencia del crédito. Costo Anual Total (CAT): ' . ($cr['cat'] !== null ? contratoPct($cr['cat'], 1) : 'no aplica') . ' sin IVA, para fines informativos y de comparación.'],
        ['Plazo y forma de pago', 'EL ACREDITADO pagará el crédito en ' . $cr['plazo_meses'] . ' mensualidades fijas y consecutivas de ' . contratoDinero($cr['mensualidad']) . ' cada una, con vencimiento el día ' . $cr['dia_pago'] . ' de cada mes (o el último día natural del mes cuando éste no tenga dicho día), siendo la primera el ' . $cr['primer_vencimiento'] . ' y la última el ' . $cr['ultimo_vencimiento'] . ', por un total de ' . contratoDinero($cr['monto_total']) . '. Los pagos se realizarán en cualquier caja de KARMA o por los medios que ésta habilite, sin necesidad de requerimiento previo, y KARMA entregará comprobante de cada pago.'],
        ['Aplicación de los pagos', 'Los pagos recibidos se aplicarán en el orden siguiente: intereses moratorios que en su caso se hubieren generado, intereses ordinarios vencidos y, finalmente, capital.'],
        ['Intereses moratorios', $moratoria],
        ['Pago anticipado', 'EL ACREDITADO podrá pagar anticipadamente, en forma total o parcial, el saldo insoluto del crédito en cualquier fecha, sin penalización ni comisión alguna, siempre que esté al corriente en sus pagos. Los pagos anticipados se aplicarán a capital y, a elección de EL ACREDITADO, reducirán el número de mensualidades pendientes o el importe de cada una; KARMA entregará la tabla de amortización actualizada.'],
        ['Reserva de dominio', 'KARMA se reserva la propiedad del vehículo hasta que EL ACREDITADO haya cubierto la totalidad del crédito, sus intereses y accesorios. Mientras tanto, EL ACREDITADO tendrá la posesión y el uso del vehículo, pero no podrá venderlo, gravarlo, arrendarlo ni transmitir su posesión por ningún título sin la autorización previa y por escrito de KARMA. La factura original quedará en resguardo de KARMA y se entregará a EL ACREDITADO al liquidar el crédito. Las partes podrán inscribir esta reserva de dominio en el registro público que corresponda (por ejemplo, el Registro Único de Garantías Mobiliarias) para que surta efectos frente a terceros.'],
        ['Seguro automotriz', 'Durante toda la vigencia del crédito, EL ACREDITADO se obliga a mantener vigente un seguro de cobertura amplia sobre el vehículo, contratado con una aseguradora autorizada, en el que se designe a ' . KARMA_RAZON_SOCIAL . ' como beneficiario preferente e irrevocable hasta por el saldo insoluto del crédito, y a entregar a KARMA copia de la póliza y de sus renovaciones. En caso de siniestro, la indemnización se aplicará en primer lugar al pago del saldo insoluto y el remanente, si lo hubiere, se entregará a EL ACREDITADO.'],
        ['Obligaciones de EL ACREDITADO', 'Además del pago puntual, EL ACREDITADO se obliga a: (a) usar el vehículo conforme a su naturaleza y mantenerlo en buen estado, con los servicios de mantenimiento que indique el fabricante; (b) cubrir los impuestos, derechos, tenencias o refrendos, verificaciones y multas que correspondan al vehículo; (c) no sacarlo del país sin autorización escrita de KARMA; (d) avisar por escrito a KARMA, dentro de los tres días hábiles siguientes, cualquier cambio de domicilio, así como el robo, siniestro, embargo o cualquier hecho que afecte al vehículo, y (e) permitir, previo aviso, la revisión del estado físico del vehículo.'],
        ['Incumplimiento, vencimiento anticipado y rescisión', 'KARMA podrá dar por vencido anticipadamente el plazo del crédito y exigir el pago inmediato del saldo insoluto, o bien rescindir este contrato, cuando EL ACREDITADO: (a) deje de cubrir dos o más mensualidades consecutivas (mora); (b) no contrate, no renueve o cancele el seguro de cobertura amplia; (c) venda, grave o transmita la posesión del vehículo sin autorización; (d) permita que el vehículo sea embargado o asegurado por causas imputables a él; (e) haya proporcionado información o documentación falsa, o (f) incumpla cualquier otra de sus obligaciones. En caso de rescisión, EL ACREDITADO devolverá el vehículo a KARMA y las partes se restituirán las prestaciones que se hubieren hecho, conforme a la legislación aplicable.'],
        ['Entrega del vehículo', 'KARMA entrega en este acto el vehículo en la sucursal ' . $op['sucursal'] . ', junto con el manual del propietario, la póliza de garantía del fabricante y el comprobante de la operación. EL ACREDITADO declara recibirlo a su entera satisfacción, en las condiciones descritas en el apartado III.'],
        ['Datos personales', 'Los datos personales de EL ACREDITADO serán tratados por KARMA únicamente para la administración de este crédito y de la relación comercial, conforme a su aviso de privacidad y a la legislación en materia de protección de datos personales en posesión de los particulares.'],
        ['Domicilios y notificaciones', 'Las partes señalan como domicilios para oír y recibir notificaciones los indicados en el apartado II. Cualquier cambio deberá notificarse por escrito a la otra parte; mientras no se haga, las notificaciones hechas en el domicilio anterior surtirán todos sus efectos.'],
        ['Consentimiento y firma', 'EL ACREDITADO manifiesta que, antes de firmar, se le dieron a conocer la carátula, el CAT, la tabla de amortización y el contenido íntegro de este contrato, y que lo firma de conformidad mediante su firma autógrafa digitalizada capturada en el sistema de KARMA. Por su parte, KARMA firma por conducto de su representante, autenticado con su código de empleado, mediante su sello digital.'],
        ['Legislación y jurisdicción', 'Para la interpretación y cumplimiento de este contrato, las partes se someten a las leyes federales aplicables de los Estados Unidos Mexicanos —entre ellas el Código de Comercio, el Código Civil Federal y la Ley Federal de Protección al Consumidor— y a la jurisdicción de los tribunales competentes de ' . $ciudad . ', Colima, renunciando a cualquier otro fuero que pudiera corresponderles por razón de su domicilio presente o futuro, sin perjuicio del derecho de EL ACREDITADO de acudir a la Procuraduría Federal del Consumidor.'],
    ];
}

// Contrato completo en HTML (lo convierte dompdf a PDF; la vista previa en pantalla usa el mismo HTML)
// $firmaSvg = null mientras el cliente no firma; $paraPantalla agrega el aspecto de hoja para la vista previa
function construirContratoHTML(array $d, ?string $firmaSvg, bool $paraPantalla = false): string {
    $op = $d['operacion'];
    $ve = $d['vendedor'];
    $re = $d['representante'];
    $ac = $d['acreditado'];
    $vh = $d['vehiculo'];
    $cr = $d['credito'];
    $folio = $d['folio'] ?? 'Por asignar';
    $esMoto = $vh['tipo'] === 'moto';

    $logo = karmaAssetSvg('logo-karma-vector.svg');
    $sello = karmaAssetSvg('sello-karma.svg');
    $ordinales = ['PRIMERA', 'SEGUNDA', 'TERCERA', 'CUARTA', 'QUINTA', 'SEXTA', 'SÉPTIMA', 'OCTAVA', 'NOVENA', 'DÉCIMA',
        'DÉCIMA PRIMERA', 'DÉCIMA SEGUNDA', 'DÉCIMA TERCERA', 'DÉCIMA CUARTA', 'DÉCIMA QUINTA', 'DÉCIMA SEXTA', 'DÉCIMA SÉPTIMA', 'DÉCIMA OCTAVA'];

    $fila = fn(string $etq, string $valor): string => '<tr><td class="etq">' . h($etq) . '</td><td>' . $valor . '</td></tr>';
    $caja = fn(string $k, string $v, string $clase = ''): string => '<td class="' . $clase . '"><div class="k">' . h($k) . '</div><div class="v">' . $v . '</div></td>';

    // Kilometraje / condición: "0 km" solo cuando el sistema registra la unidad como nueva
    $condicion = $vh['nuevo']
        ? 'Unidad nueva — 0 km, entrega de planta (condición registrada en el sistema: nuevo)'
        : 'No registrada en el sistema';

    $amortizacion = '';
    foreach ($d['amortizacion'] as $k => $f) {
        $amortizacion .= '<tr class="' . ($k % 2 ? 'par' : '') . '"><td class="c">' . $f['pago'] . '</td><td class="c">' . h($f['fecha']) . '</td><td>' . contratoDinero($f['cuota'])
            . '</td><td>' . contratoDinero($f['capital']) . '</td><td>' . contratoDinero($f['interes']) . '</td><td>' . contratoDinero($f['saldo']) . '</td></tr>';
    }

    $otros = '';
    if (!empty($d['otros_articulos'])) {
        $lineas = '';
        foreach ($d['otros_articulos'] as $o) {
            $lineas .= h($o['cantidad'] . '× ' . $o['descripcion']) . ' — ' . contratoDinero($o['subtotal']) . '<br>';
        }
        $otros = $fila('Artículos de contado del mismo ticket (no financiados)', $lineas);
    }

    $clausulas = '';
    foreach (contratoClausulas($d) as $k => [$titulo, $texto]) {
        $clausulas .= '<p class="clausula"><b>' . $ordinales[$k] . '. ' . h(mb_strtoupper($titulo)) . '.</b> ' . h($texto) . '</p>';
    }

    $firmaCliente = $firmaSvg !== null
        ? '<img class="firma-img" src="' . karmaSvgDataUri($firmaSvg) . '" alt="Firma del acreditado">'
        : '<div class="firma-pendiente">Pendiente de firma del acreditado</div>';
    $momentoFirma = $firmaSvg !== null ? 'Firmado el ' . h($op['fecha']) . ' a las ' . h($op['hora']) : 'Firma pendiente';

    $estiloPantalla = $paraPantalla ? '
      html{ background:#E6E9EF; }
      body{ width:8.5in; max-width:100%; margin:18px auto; padding:16mm 15mm; background:#fff; box-sizing:border-box;
            box-shadow:0 10px 30px rgba(16,33,63,.18); }' : '';

    return '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><title>Contrato ' . h($folio) . '</title><style>
      @page{ margin:17mm 15mm 18mm 15mm; }
      body{ font-family:Helvetica, Arial, sans-serif; font-size:8.4pt; color:#1B1D21; line-height:1.4; margin:0; }
      ' . $estiloPantalla . '
      table{ width:100%; border-collapse:collapse; }
      .encabezado td{ vertical-align:middle; }
      .marca{ font-family:"Times New Roman", Times, serif; font-size:17pt; color:#10213F; letter-spacing:1px; font-weight:bold; }
      .muted{ color:#5D6270; font-size:7.6pt; }
      .folio-box{ border:1px solid #10213F; padding:5px 8px; text-align:right; }
      .folio-box .k{ font-size:6.6pt; color:#5D6270; text-transform:uppercase; letter-spacing:.4px; }
      .folio-box .v{ font-size:10pt; font-weight:bold; color:#10213F; }
      .titulo{ background:#10213F; color:#FFFFFF; text-align:center; padding:7px 10px; margin-top:8px; }
      .titulo .t1{ font-size:11.6pt; font-weight:bold; letter-spacing:.6px; }
      .titulo .t2{ font-size:8pt; color:#C9D3E6; margin-top:1px; }
      .aviso{ border:1px solid #9E1B2E; background:#FBF1F2; color:#7D1524; padding:5px 8px; font-size:7.2pt; margin:7px 0 0; }
      .aviso-previa{ border:1px dashed #B7791F; background:#FFF8E6; color:#7A4E00; padding:5px 8px; font-size:7.6pt; margin:6px 0 0; text-align:center; font-weight:bold; }
      h2{ font-size:9pt; color:#10213F; border-bottom:1.3px solid #10213F; padding-bottom:2px; margin:13px 0 5px; text-transform:uppercase; letter-spacing:.5px; }
      .datos td{ padding:3px 6px; border-bottom:.6px solid #E3E5EA; vertical-align:top; }
      .datos .etq{ color:#5D6270; width:36%; }
      .datos2 td{ padding:3px 6px; border-bottom:.6px solid #E3E5EA; vertical-align:top; width:25%; }
      .datos2 .etq{ color:#5D6270; }
      .caratula td{ border:.8px solid #C3CAD8; padding:5px 7px; width:25%; vertical-align:top; }
      .caratula .k{ font-size:6.5pt; text-transform:uppercase; color:#5D6270; letter-spacing:.3px; }
      .caratula .v{ font-size:10pt; font-weight:bold; color:#10213F; margin-top:1px; }
      .caratula td.cat{ background:#EEF2F9; }
      .caratula td.cat .v{ font-size:15pt; }
      .nota{ font-size:7pt; color:#5D6270; margin-top:3px; }
      .partes td.col{ width:50%; vertical-align:top; }
      .partes td.izq{ padding-right:5px; }
      .partes td.der{ padding-left:5px; }
      .cuadro{ border:.8px solid #C3CAD8; padding:6px 8px; }
      .cuadro .rol{ font-size:7.4pt; font-weight:bold; color:#FFFFFF; background:#10213F; padding:2px 6px; margin:-6px -8px 5px; text-transform:uppercase; letter-spacing:.4px; }
      .cuadro table td{ padding:2px 0; vertical-align:top; font-size:8pt; }
      .cuadro table td.etq{ color:#5D6270; width:38%; }
      .amort th{ background:#10213F; color:#FFFFFF; font-size:6.9pt; padding:3.5px 4px; text-align:right; font-weight:bold; }
      .amort th.c, .amort td.c{ text-align:center; }
      .amort td{ font-size:7.2pt; padding:2.2px 4px; text-align:right; border-bottom:.5px solid #E3E5EA; }
      .amort tr.par td{ background:#F4F6FA; }
      .amort thead{ display:table-header-group; }
      .clausula{ margin:0 0 5px; text-align:justify; }
      .clausula b{ color:#10213F; }
      .firmas{ page-break-inside:avoid; margin-top:16px; }
      .firmas td{ width:50%; vertical-align:bottom; text-align:center; padding:0 12px; }
      .sello{ width:122px; height:122px; }
      .firma-img{ width:230px; height:77px; }
      .firma-pendiente{ height:60px; line-height:60px; border:1px dashed #B7791F; color:#7A4E00; font-size:7.6pt; margin:0 20px 6px; }
      .linea-firma{ border-top:1px solid #1B1D21; padding-top:4px; margin-top:2px; }
      .linea-firma b{ font-size:8.6pt; }
      .pie-legal{ font-size:6.8pt; color:#5D6270; margin-top:12px; text-align:justify; border-top:.6px solid #C3CAD8; padding-top:6px; }
    </style></head><body>

      <table class="encabezado"><tr>
        <td style="width:66px;"><img src="' . karmaSvgDataUri($logo) . '" style="width:58px;height:54px;" alt="KARMA"></td>
        <td>
          <div class="marca">KARMA</div>
          <div class="muted">' . h(KARMA_RAZON_SOCIAL) . ' · Agencia automotriz · Sucursal ' . h($op['sucursal']) . '<br>' . h($ve['domicilio']) . ' · Tel. ' . h($ve['telefono']) . '</div>
        </td>
        <td style="width:190px;">
          <div class="folio-box"><div class="k">Contrato No.</div><div class="v">' . h($folio) . '</div>
          <div class="k" style="margin-top:3px;">' . h($op['sucursal']) . ', Colima · ' . h($op['fecha']) . ' · ' . h($op['hora']) . '</div></div>
        </td>
      </tr></table>

      <div class="titulo">
        <div class="t1">CONTRATO DE COMPRAVENTA A CRÉDITO CON RESERVA DE DOMINIO</div>
        <div class="t2">' . ($esMoto ? 'Motocicleta nueva' : 'Vehículo automotor nuevo') . ' · Financiamiento directo de ' . h(KARMA_RAZON_SOCIAL) . '</div>
      </div>
      <div class="aviso"><b>DOCUMENTO DE DEMOSTRACIÓN — PROYECTO ACADÉMICO KARMA.</b> El RFC de KARMA es un dato de demostración (no válido ante el SAT) y las cláusulas son ilustrativas:
        no han sido revisadas por un profesional del derecho y no garantizan validez jurídica. Los importes, tasas, plazos y datos de la unidad provienen de la operación registrada en el sistema.</div>
      ' . ($firmaSvg === null ? '<div class="aviso-previa">VISTA PREVIA · El crédito no está concretado hasta que el acreditado firme y acepte este contrato</div>' : '') . '

      <h2>Carátula</h2>
      <table class="caratula">
        <tr>' . $caja('CAT (Costo Anual Total)', ($cr['cat'] !== null ? contratoPct($cr['cat'], 1) : 'No aplica') . ' <span style="font-size:7pt;font-weight:normal;">sin IVA</span>', 'cat')
            . $caja('Tasa de interés ordinaria anual', contratoPct($cr['tasa_anual']) . ' fija')
            . $caja('Monto total del crédito', contratoDinero($cr['monto_financiado']))
            . $caja('Monto total a pagar', contratoDinero($cr['monto_total'])) . '</tr>
        <tr>' . $caja('Plazo / número de pagos', $cr['plazo_meses'] . ' meses · ' . $cr['plazo_meses'] . ' mensualidades')
            . $caja('Mensualidad fija', contratoDinero($cr['mensualidad']))
            . $caja('Primer y último vencimiento', h($cr['primer_vencimiento']) . ' — ' . h($cr['ultimo_vencimiento']))
            . $caja('Tasa de interés moratoria', $cr['tasa_moratoria'] !== null ? contratoPct($cr['tasa_moratoria']) . ' anual' : 'No pactada en el sistema') . '</tr>
        <tr>' . $caja('Precio de contado', contratoDinero($cr['precio_contado']))
            . $caja('Enganche entregado', contratoDinero($cr['enganche']) . ' <span style="font-size:7pt;font-weight:normal;">(' . contratoPct($cr['enganche_pct']) . ')</span>')
            . $caja('Comisión por apertura', contratoDinero($cr['comision_apertura']) . ' <span style="font-size:7pt;font-weight:normal;">(' . contratoPct($cr['comision_apertura_pct'], 0) . ')</span>')
            . $caja('Otras comisiones', '<span style="font-size:8pt;">Administración: no aplica<br>Pago anticipado: no aplica</span>') . '</tr>
      </table>
      <div class="nota">CAT sin IVA, para fines informativos y de comparación, calculado con el saldo financiado, la comisión por apertura y las ' . $cr['plazo_meses'] . ' mensualidades de esta operación.</div>

      <h2>I. Datos de la operación</h2>
      <table class="datos2">
        <tr><td class="etq">Folio de contrato</td><td><b>' . h($folio) . '</b></td><td class="etq">Folio de venta</td><td>' . h($op['folio_venta'] ?? 'Se asigna al firmar') . '</td></tr>
        <tr><td class="etq">Sucursal</td><td>' . h($op['sucursal']) . '</td><td class="etq">Caja / ticket</td><td>Caja ' . h($op['caja']) . ' · Ticket #' . str_pad((string)$op['ticket'], 2, '0', STR_PAD_LEFT) . '</td></tr>
        <tr><td class="etq">Fecha</td><td>' . h($op['fecha_larga']) . '</td><td class="etq">Hora</td><td>' . h($op['hora']) . ' (hora del centro de México)</td></tr>
        <tr><td class="etq">Cajero responsable</td><td>' . h($op['cajero']) . '</td><td class="etq">Código de empleado</td><td>' . h($op['codigo_empleado']) . ' (verificado)</td></tr>
        <tr><td class="etq">Cobro del enganche</td><td>' . h($op['metodo_pago']) . '</td><td class="etq">Importe cobrado</td><td>' . contratoDinero($op['importe_cobrado'])
            . ($op['importe_cobrado'] > 0 ? ' · recibido ' . contratoDinero($op['recibido']) . ' · cambio ' . contratoDinero($op['cambio']) : '') . '</td></tr>
      </table>

      <h2>II. Identificación de las partes</h2>
      <table class="partes"><tr>
        <td class="col izq"><div class="cuadro"><div class="rol">Vendedor y acreedor (KARMA)</div><table>
          <tr><td class="etq">Razón social</td><td><b>' . h($ve['razon_social']) . '</b></td></tr>
          <tr><td class="etq">RFC</td><td>' . h($ve['rfc']) . ' <i>(dato de demostración)</i></td></tr>
          <tr><td class="etq">Domicilio (sucursal)</td><td>' . h($ve['domicilio']) . '</td></tr>
          <tr><td class="etq">Teléfono / correo</td><td>' . h($ve['telefono']) . ($ve['email'] ? ' · ' . h($ve['email']) : '') . '</td></tr>
          <tr><td class="etq">Representante</td><td><b>' . h($re['nombre']) . '</b><br>' . h($re['rol']) . ' de la sucursal ' . h($ve['sucursal']) . ' · <span style="white-space:nowrap;">' . h($re['codigo']) . '</span></td></tr>
        </table></div></td>
        <td class="col der"><div class="cuadro"><div class="rol">Comprador y acreditado</div><table>
          <tr><td class="etq">Nombre completo</td><td><b>' . h($ac['nombre']) . '</b></td></tr>
          <tr><td class="etq">RFC / CURP</td><td>' . h($ac['rfc_curp']) . '</td></tr>
          <tr><td class="etq">Identificación oficial</td><td>' . h($ac['identificacion_tipo']) . ' · No. ' . h($ac['identificacion_numero']) . '</td></tr>
          <tr><td class="etq">Domicilio particular</td><td>' . h($ac['direccion']) . '</td></tr>
          <tr><td class="etq">Teléfono / correo</td><td>' . h($ac['celular'] ?: '—') . ($ac['email'] ? ' · ' . h($ac['email']) : '') . '</td></tr>
        </table></div></td>
      </tr></table>

      <h2>III. Identificación del vehículo</h2>
      <table class="datos2">
        <tr><td class="etq">Marca</td><td>' . h($vh['marca']) . '</td><td class="etq">Modelo</td><td>' . h($vh['modelo']) . '</td></tr>
        <tr><td class="etq">Año modelo</td><td>' . h($vh['anio']) . '</td><td class="etq">Tipo</td><td>' . ($esMoto ? 'Motocicleta' : 'Automóvil') . '</td></tr>
        <tr><td class="etq">Versión</td><td colspan="3">' . h($vh['version'] ?: 'No registrada') . ($vh['cilindraje'] && $vh['cilindraje'] !== '?' ? ' · ' . h($vh['cilindraje']) : '') . '</td></tr>
        <tr><td class="etq">VIN / Número de serie</td><td><b>' . h($vh['vin']) . '</b></td><td class="etq">Número de motor</td><td>' . h($vh['numero_motor'] ?: 'No registrado en el sistema') . '</td></tr>
        <tr><td class="etq">Color exterior</td><td>' . h($vh['color'] ?: '—') . '</td><td class="etq">Color interior</td><td>' . h($vh['color_interior'] ?: '—') . '</td></tr>
        <tr><td class="etq">Kilometraje / condición</td><td colspan="3">' . h($condicion) . '</td></tr>
        <tr><td class="etq">Código de inventario</td><td colspan="3">' . h($vh['codigo']) . '</td></tr>
      </table>

      <h2>IV. Condiciones financieras</h2>
      <table class="datos">
        ' . $fila('Precio de contado del vehículo', contratoDinero($cr['precio_contado']))
          . $fila('Enganche entregado', contratoDinero($cr['enganche']) . ' (' . contratoPct($cr['enganche_pct']) . ' del precio' . ($cr['enganche_tipo'] === 'pct' ? ', capturado por porcentaje' : ', capturado por monto') . ')')
          . $fila('Saldo neto pendiente de financiamiento', '<b>' . contratoDinero($cr['saldo_financiar']) . '</b>')
          . $fila('Comisión por apertura', contratoDinero($cr['comision_apertura']) . ' (' . contratoPct($cr['comision_apertura_pct'], 0) . ' del saldo, incluida en el financiamiento)')
          . $fila('Monto total financiado', contratoDinero($cr['monto_financiado']))
          . $fila('Tasa de interés ordinaria', contratoPct($cr['tasa_anual']) . ' anual FIJA (' . contratoPct($cr['tasa_mensual'], 4) . ' mensual sobre saldos insolutos)')
          . $fila('Tasa de interés moratoria', $cr['tasa_moratoria'] !== null ? contratoPct($cr['tasa_moratoria']) . ' anual' : 'No pactada en el sistema (ver cláusula SÉPTIMA)')
          . $fila('CAT (Costo Anual Total)', ($cr['cat'] !== null ? contratoPct($cr['cat'], 1) : 'No aplica') . ' sin IVA, para fines informativos y de comparación')
          . $fila('Plazo y número de mensualidades', $cr['plazo_meses'] . ' meses · ' . $cr['plazo_meses'] . ' mensualidades fijas')
          . $fila('Importe de cada mensualidad', '<b>' . contratoDinero($cr['mensualidad']) . '</b>')
          . $fila('Fechas de vencimiento', 'Día ' . $cr['dia_pago'] . ' de cada mes · primera: ' . h($cr['primer_vencimiento']) . ' · última: ' . h($cr['ultimo_vencimiento']))
          . $fila('Intereses ordinarios totales', contratoDinero($cr['monto_interes']))
          . $fila('Monto total a pagar en mensualidades', contratoDinero($cr['monto_total']))
          . $fila('Comisiones por administración y por pago anticipado', 'No aplican')
          . $otros . '
      </table>

      <h2>Tabla de amortización</h2>
      <table class="amort">
        <thead><tr><th class="c">Pago</th><th class="c">Vencimiento</th><th>Cuota mensual</th><th>Abono a capital</th><th>Pago de interés</th><th>Saldo pendiente</th></tr></thead>
        <tbody>' . $amortizacion . '</tbody>
      </table>
      <div class="nota">Tabla generada por el módulo de crédito del Punto de Venta (misma fórmula de anualidad con tasa fija que se mostró al cliente al aplicar el crédito).</div>

      <h2>Declaraciones</h2>
      <p class="clausula"><b>I. Declara KARMA, por conducto de su representante:</b> (a) que es una sociedad mercantil denominada ' . h(KARMA_RAZON_SOCIAL) . ', con el RFC de demostración indicado en el apartado II; (b) que ' . h($re['nombre']) . ' atiende esta operación en la sucursal ' . h($op['sucursal']) . ' y se identificó en el sistema con su código de empleado ' . h($re['codigo']) . '; (c) que es propietaria del vehículo descrito en el apartado III, el cual se encuentra libre de gravámenes, y (d) que tiene su domicilio en el señalado en el apartado II.</p>
      <p class="clausula"><b>II. Declara EL ACREDITADO:</b> (a) que es persona física con capacidad legal para obligarse y que se identifica con ' . h($ac['identificacion_tipo']) . ' número ' . h($ac['identificacion_numero']) . '; (b) que los datos personales que proporcionó son verdaderos; (c) que examinó el vehículo y lo recibe a su entera satisfacción, y (d) que conoce la carátula, el CAT, la tabla de amortización y el contenido de este contrato, y cuenta con capacidad económica para cumplirlo.</p>

      <h2>Cláusulas</h2>
      ' . $clausulas . '

      <div class="firmas"><table><tr>
        <td>
          <img class="sello" src="' . karmaSvgDataUri($sello) . '" alt="Sello digital de KARMA S.A. de C.V.">
          <div class="linea-firma"><b>' . h($re['nombre']) . '</b><br>Representante de ' . h(KARMA_RAZON_SOCIAL) . '<br><span class="muted">Vendedor y acreedor · Sello digital · ' . h($op['fecha']) . ' ' . h($op['hora']) . '</span></div>
        </td>
        <td>
          ' . $firmaCliente . '
          <div class="linea-firma"><b>' . h($ac['nombre']) . '</b><br>EL ACREDITADO (comprador)<br><span class="muted">Firma autógrafa digitalizada · ' . $momentoFirma . '</span></div>
        </td>
      </tr></table></div>

      <div class="pie-legal">Contrato ' . h($folio) . ' celebrado en ' . h($op['sucursal_ciudad']) . ', Colima, el ' . h($op['fecha_larga']) . '.'
        . (!empty($d['integridad']) ? ' Huella de integridad (SHA-256) de los datos y la firma: <span style="font-family:Courier;">' . h($d['integridad']) . '</span>.' : '')
        . ' Documento generado por el sistema KARMA con fines académicos y de demostración: antes de utilizarse en operaciones reales debe ser revisado por un abogado y, en su caso, registrado ante la Procuraduría Federal del Consumidor.</div>
    </body></html>';
}

// Convierte el HTML del contrato en PDF (bytes) con Dompdf y numera las páginas
function contratoGenerarPdf(string $html, string $folio): string {
    $error = karmaCargarDompdf();
    if ($error !== null) throw new RuntimeException($error);
    $opciones = new Dompdf\Options();
    $opciones->set('isRemoteEnabled', false);
    $opciones->set('defaultFont', 'Helvetica');
    $dompdf = new Dompdf\Dompdf($opciones);
    $dompdf->loadHtml($html, 'UTF-8');
    $dompdf->setPaper('letter', 'portrait');
    $dompdf->render();
    $fuente = $dompdf->getFontMetrics()->getFont('Helvetica');
    $dompdf->getCanvas()->page_text(42, 762, 'KARMA S.A. de C.V. · Contrato ' . $folio . ' · Documento de demostración', $fuente, 6.5, [0.42, 0.45, 0.5]);
    $dompdf->getCanvas()->page_text(500, 762, 'Página {PAGE_NUM} de {PAGE_COUNT}', $fuente, 6.5, [0.42, 0.45, 0.5]);
    return (string)$dompdf->output();
}

/* ===================== Endpoints (api.php) ===================== */

// Paso 1: después del cobro del enganche y de la verificación del gafete (el enrutador ya consumió la autorización CREDITO)
function prepararCredito(): never {
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idUsuario = (int)$cajero['id_usuario'];
    $idSucursal = (int)$cajero['id_sucursal'];
    $idCaja = (int)($data['id_caja'] ?? 0);
    $ticketNumero = (int)($data['ticket_numero'] ?? 0);
    $pdo = db();

    $cajaValida = $pdo->prepare("SELECT COUNT(*) FROM cajas WHERE id_caja = ? AND id_sucursal = ?");
    $cajaValida->execute([$idCaja, $idSucursal]);
    if (!(int)$cajaValida->fetchColumn()) fail('La caja no pertenece a la sucursal del cajero.');

    $items = contratoNormalizarItems($data['items'] ?? null);
    $cliente = contratoNormalizarCliente(is_array($data['cliente'] ?? null) ? $data['cliente'] : []);
    $parametros = contratoNormalizarParametros(is_array($data['credito'] ?? null) ? $data['credito'] : []);
    $pago = ['metodo' => (string)($data['metodo_pago'] ?? ''), 'recibido' => money((float)($data['efectivo_recibido'] ?? 0))];
    $ordenesWeb = array_values(array_unique(array_filter(array_map('intval', (array)($data['ordenes_web'] ?? [])))));

    $pdo->beginTransaction();
    try {
        // Un cajero solo tiene un contrato esperando firma: los anteriores que nunca se firmaron quedan cancelados
        $pdo->prepare("UPDATE contratos_credito SET estado = 'cancelado', fecha_cancelacion = NOW() WHERE estado = 'pendiente_firma' AND id_usuario = ?")
            ->execute([$idUsuario]);

        // Mismas validaciones que la venta de contado: producto, VIN registrado y existencias en la sucursal
        [$lineas] = posValidarArticulosVenta($pdo, $items, $idSucursal);
        $op = contratoCalcularOperacion($pdo, $items, $lineas, $parametros, $pago);
        $op['cliente'] = $cliente;
        // Lo necesario para concretar después exactamente la misma operación (con los precios que se mostraron)
        $op['solicitud'] = [
            'items' => $items, 'ordenes_web' => $ordenesWeb, 'cliente' => $cliente, 'precios' => array_column($lineas, 'precio'),
            'articulo' => $op['articulo']
        ];

        $datos = contratoArmarDatos($pdo, $cajero, $idCaja, $ticketNumero, $op, contratoAhora($pdo));
        $cr = $datos['credito'];
        $ins = $pdo->prepare("
            INSERT INTO contratos_credito
            (estado, id_sucursal, id_usuario, id_caja, ticket_numero, id_producto, vin, cliente_nombre,
             precio_contado, enganche, saldo_financiar, comision_apertura, monto_financiado, tasa_anual, cat, plazo_meses,
             mensualidad, monto_interes, monto_total, importe_cobrado, metodo_pago, efectivo_recibido, cambio, datos_json)
            VALUES ('pendiente_firma', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '{}')
        ");
        $ins->execute([
            $idSucursal, $idUsuario, $idCaja, $ticketNumero, $datos['vehiculo']['id_producto'], $datos['vehiculo']['vin'], $cliente['nombre'],
            $cr['precio_contado'], $cr['enganche'], $cr['saldo_financiar'], $cr['comision_apertura'], $cr['monto_financiado'], $cr['tasa_anual'],
            $cr['cat'], $cr['plazo_meses'], $cr['mensualidad'], $cr['monto_interes'], $cr['monto_total'],
            $op['importe'], $op['metodo'], $op['recibido'], $op['cambio']
        ]);
        $idContrato = (int)$pdo->lastInsertId();
        $datos['folio'] = sprintf('KRM-CC-%02d-%06d', $idSucursal, $idContrato);
        $pdo->prepare("UPDATE contratos_credito SET folio = ?, datos_json = ? WHERE id_contrato = ?")
            ->execute([$datos['folio'], json_encode($datos, JSON_UNESCAPED_UNICODE), $idContrato]);
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    // Permiso para firmar ESTE contrato en ESTA sesión (el navegador recibe el valor; la sesión guarda solo su huella)
    $token = bin2hex(random_bytes(24));
    $_SESSION['pos_contrato_pendiente'] = [
        'id' => $idContrato, 'huella' => hash('sha256', $token), 'id_usuario' => $idUsuario, 'expira' => time() + KARMA_CONTRATO_VIGENCIA_FIRMA
    ];

    ok([
        'id_contrato' => $idContrato,
        'folio' => $datos['folio'],
        'token' => $token,
        'html' => construirContratoHTML($datos, null, true),
        'resumen' => [
            'cliente' => $cliente['nombre'], 'vehiculo' => $op['articulo'], 'vin' => $datos['vehiculo']['vin'],
            'precio' => $cr['precio_contado'], 'enganche' => $cr['enganche'], 'saldo' => $cr['saldo_financiar'],
            'plazo' => $cr['plazo_meses'], 'mensualidad' => $cr['mensualidad'], 'cat' => $cr['cat'], 'tasa' => $cr['tasa_anual'],
            'importe' => $op['importe'], 'metodo' => $op['metodo'], 'recibido' => $op['recibido'], 'cambio' => $op['cambio'],
            'representante' => $datos['representante']['nombre']
        ]
    ]);
}

// Paso 2: el cliente firmó y pulsó «Aceptar»: se concreta el crédito y se guarda el PDF definitivo (todo o nada)
function concretarCredito(): never {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST' || !posCsrfValido()) fail('Solicitud no válida. Recarga la página e inténtalo de nuevo.', 403);
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idUsuario = (int)$cajero['id_usuario'];
    $idSucursal = (int)$cajero['id_sucursal'];
    $idContrato = (int)($data['id_contrato'] ?? 0);
    $pendiente = $_SESSION['pos_contrato_pendiente'] ?? null;

    if (!is_array($pendiente) || (int)$pendiente['id'] !== $idContrato || (int)$pendiente['id_usuario'] !== $idUsuario
        || !hash_equals((string)$pendiente['huella'], hash('sha256', (string)($data['token'] ?? '')))) {
        fail('Este contrato ya no está disponible para firma. Vuelve a iniciar el crédito con F3.', 409);
    }
    if (time() > (int)$pendiente['expira']) {
        db()->prepare("UPDATE contratos_credito SET estado = 'cancelado', fecha_cancelacion = NOW() WHERE id_contrato = ? AND estado = 'pendiente_firma'")->execute([$idContrato]);
        unset($_SESSION['pos_contrato_pendiente']);
        fail('Venció el tiempo para firmar el contrato. Vuelve a iniciar el crédito con F3.', 409);
    }
    $firmaSvg = contratoFirmaSVG($data['trazos'] ?? null);
    $errorDompdf = karmaCargarDompdf();
    if ($errorDompdf !== null) fail($errorDompdf, 503);

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT * FROM contratos_credito WHERE id_contrato = ? FOR UPDATE");
        $stmt->execute([$idContrato]);
        $contrato = $stmt->fetch();
        if (!$contrato || $contrato['estado'] !== 'pendiente_firma') throw new RuntimeException('Este contrato ya fue firmado o cancelado.');
        if ((int)$contrato['id_usuario'] !== $idUsuario || (int)$contrato['id_sucursal'] !== $idSucursal) throw new RuntimeException('Este contrato pertenece a otra sesión.');

        $datos = json_decode((string)$contrato['datos_json'], true);
        $sol = $datos['solicitud'];
        $cr = $datos['credito'];

        // Se vuelve a validar todo con bloqueo (otro cajero pudo vender la unidad mientras el cliente leía el contrato)
        [$lineas] = posValidarArticulosVenta($pdo, $sol['items'], $idSucursal);
        foreach ($lineas as $k => $l) {
            if (abs((float)$l['precio'] - (float)($sol['precios'][$k] ?? -1)) > 0.009) {
                throw new RuntimeException('Un precio cambió mientras se revisaba el contrato. Cancela la operación y vuelve a capturarla.');
            }
        }

        // Cliente en la sección Clientes con los datos de ESTE crédito
        $saldoInicial = round(round((float)$cr['mensualidad'], 2) * (int)$cr['plazo_meses'], 2);
        $idCliente = posGuardarClienteCredito($pdo, $sol['cliente'], [
            'articulo' => $sol['articulo'], 'total_adeudo' => $saldoInicial, 'monto_abono' => $cr['mensualidad'],
            'enganche' => $cr['enganche'], 'abonos_totales' => $cr['plazo_meses']
        ]);

        $metodoStmt = $pdo->prepare("SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo = ? LIMIT 1");
        $metodoStmt->execute([$contrato['metodo_pago']]);
        $idMetodo = (int)$metodoStmt->fetchColumn();
        if (!$idMetodo) throw new RuntimeException('No existe el método de pago "' . $contrato['metodo_pago'] . '". Ejecuta Database/contrato_credito.sql.');

        // Venta: el total es lo cobrado hoy (enganche + contado); el detalle guarda el precio real de cada artículo
        $ventaId = posInsertarVenta($pdo, [
            'id_sucursal' => $idSucursal, 'id_usuario' => $idUsuario, 'id_caja' => (int)$contrato['id_caja'], 'id_metodo_pago' => $idMetodo,
            'id_cliente' => $idCliente, 'total' => (float)$contrato['importe_cobrado'], 'recibido' => (float)$contrato['efectivo_recibido'],
            'cambio' => (float)$contrato['cambio'], 'ticket_numero' => (int)$contrato['ticket_numero']
        ], $lineas);
        posMarcarOrdenesWeb($pdo, (array)($sol['ordenes_web'] ?? []), $ventaId, $idSucursal);
        // Garantía de 4 años del vehículo a crédito (y de cualquier otro vehículo del mismo ticket)
        posRegistrarGarantias($pdo, $ventaId, $idSucursal, $lineas, $sol['cliente'], $idCliente);

        // Fecha definitiva = momento de la firma (las mensualidades se cuentan desde aquí)
        $ahora = contratoAhora($pdo);
        $calculo = contratoCalcularCredito((float)$cr['precio_contado'], (float)$cr['enganche'], (int)$cr['plazo_meses'], (float)$cr['tasa_anual']);
        $datos['amortizacion'] = contratoTablaAmortizacion($calculo, $ahora);
        $datos['credito']['dia_pago'] = (int)$ahora->format('j');
        $datos['credito']['primer_vencimiento'] = $datos['amortizacion'][0]['fecha'];
        $datos['credito']['ultimo_vencimiento'] = end($datos['amortizacion'])['fecha'];
        $datos['operacion'] = array_merge($datos['operacion'], [
            'fecha' => $ahora->format('d/m/Y'), 'fecha_larga' => contratoFechaLarga($ahora), 'hora' => $ahora->format('H:i:s'),
            'fecha_iso' => $ahora->format('Y-m-d H:i:s'), 'id_venta' => $ventaId, 'folio_venta' => sprintf('KRM-%02d-%06d', $idSucursal, $ventaId)
        ]);
        $datos['id_cliente'] = $idCliente;
        unset($datos['integridad']);
        $datos['integridad'] = hash('sha256', json_encode($datos, JSON_UNESCAPED_UNICODE) . $firmaSvg);

        $pdf = contratoGenerarPdf(construirContratoHTML($datos, $firmaSvg), (string)$datos['folio']);
        if (strlen($pdf) > 900000) throw new RuntimeException('El PDF del contrato es demasiado grande para guardarse.');

        $up = $pdo->prepare("
            UPDATE contratos_credito
            SET estado = 'firmado', estado_credito = 'activo', abonos_pagados = 0, saldo_pendiente = ?,
                id_venta = ?, id_cliente = ?, fecha_firma = ?, firma_cliente = ?, pdf = ?, pdf_sha256 = ?, datos_json = ?
            WHERE id_contrato = ?
        ");
        $up->bindValue(1, $saldoInicial);
        $up->bindValue(2, $ventaId, PDO::PARAM_INT);
        $up->bindValue(3, $idCliente, PDO::PARAM_INT);
        $up->bindValue(4, $ahora->format('Y-m-d H:i:s'));
        $up->bindValue(5, $firmaSvg);
        $up->bindValue(6, $pdf, PDO::PARAM_LOB);
        $up->bindValue(7, hash('sha256', $pdf));
        $up->bindValue(8, json_encode($datos, JSON_UNESCAPED_UNICODE));
        $up->bindValue(9, $idContrato, PDO::PARAM_INT);
        $up->execute();

        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    unset($_SESSION['pos_contrato_pendiente']);
    ok([
        'venta_id' => $ventaId,
        'folio' => $datos['operacion']['folio_venta'],
        'fecha' => $ahora->format('d/m/Y H:i:s'),
        'total' => (float)$contrato['importe_cobrado'],
        'recibido' => (float)$contrato['efectivo_recibido'],
        'cambio' => (float)$contrato['cambio'],
        'metodo' => $contrato['metodo_pago'],
        'id_cliente' => $idCliente,
        'contrato' => ['id' => $idContrato, 'folio' => $datos['folio']]
    ]);
}

// El cliente no firmó (o el cajero canceló): el contrato queda cancelado y no se registra ninguna venta ni crédito
function cancelarCredito(): never {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST' || !posCsrfValido()) fail('Solicitud no válida. Recarga la página e inténtalo de nuevo.', 403);
    $idContrato = (int)(jsonInput()['id_contrato'] ?? 0);
    $stmt = db()->prepare("UPDATE contratos_credito SET estado = 'cancelado', fecha_cancelacion = NOW() WHERE id_contrato = ? AND estado = 'pendiente_firma' AND id_usuario = ?");
    $stmt->execute([$idContrato, (int)$GLOBALS['cajeroSesion']['id_usuario']]);
    if ((int)($_SESSION['pos_contrato_pendiente']['id'] ?? 0) === $idContrato) unset($_SESSION['pos_contrato_pendiente']);
    if (!$stmt->rowCount()) fail('Ese contrato ya no está pendiente de firma (ya se firmó o se canceló).', 409);
    ok(['message' => 'El contrato se canceló y el crédito no se registró.']);
}

/* ===================== Abonos mensuales (botón «Cobrar abono» de la sección Clientes) ===================== */

// Cobra la siguiente mensualidad de un crédito activo. No es una venta: no toca ventas, inventario ni los datos del contrato.
// El enrutador ya validó y consumió la autorización del gafete (acción ABONO). Un mismo abono no se registra dos veces:
// la mensualidad se bloquea (FOR UPDATE), debe ser exactamente la siguiente pendiente y la clave del cobro es única.
function cobrarAbono(): never {
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idUsuario = (int)$cajero['id_usuario'];
    $idSucursal = (int)$cajero['id_sucursal'];
    $idCaja = (int)($data['id_caja'] ?? 0);
    $idContrato = (int)($data['id_contrato'] ?? 0);
    $numero = (int)($data['numero_abono'] ?? 0);
    $ticketNumero = (int)($data['ticket_numero'] ?? 0);
    $clave = strtolower(trim((string)($data['clave'] ?? '')));
    $recibido = money((float)($data['efectivo_recibido'] ?? 0));
    if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/', $clave)) fail('Solicitud de cobro no válida. Vuelve a agregar el abono al ticket.');
    // Mismo cobro que una venta normal: hoy solo está habilitado el efectivo (la terminal de tarjeta aún no está conectada)
    if (($data['metodo_pago'] ?? '') !== 'Efectivo') fail('Selecciona un método de pago disponible para cobrar el abono.');

    $pdo = db();
    $cajaValida = $pdo->prepare("SELECT COUNT(*) FROM cajas WHERE id_caja = ? AND id_sucursal = ?");
    $cajaValida->execute([$idCaja, $idSucursal]);
    if (!(int)$cajaValida->fetchColumn()) fail('La caja no pertenece a la sucursal del cajero.');

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT * FROM contratos_credito WHERE id_contrato = ? FOR UPDATE");
        $stmt->execute([$idContrato]);
        $contrato = $stmt->fetch();
        if (!$contrato || $contrato['estado'] !== 'firmado') throw new RuntimeException('El crédito ya no existe.');

        // Reenvío del mismo cobro (doble clic, recarga o reintento por error de red): se responde con el abono ya registrado
        $previo = $pdo->prepare("SELECT * FROM abonos_credito WHERE clave_idempotencia = ?");
        $previo->execute([$clave]);
        if ($abono = $previo->fetch()) {
            $pdo->commit();
            ok(abonoRespuesta($pdo, $abono, $contrato) + ['repetido' => true]);
        }

        if ($contrato['estado_credito'] !== 'activo') throw new RuntimeException('Este crédito ya no tiene abonos pendientes.');
        $siguiente = (int)$contrato['abonos_pagados'] + 1;
        $plazo = (int)$contrato['plazo_meses'];
        if ($siguiente > $plazo) throw new RuntimeException('Este crédito ya no tiene abonos pendientes.');
        if ($numero !== $siguiente) {
            throw new RuntimeException("El abono {$numero} ya no está pendiente: el siguiente es el {$siguiente} de {$plazo}. Quita el abono del ticket (F4) y vuelve a agregarlo desde Clientes.");
        }

        // Importe exacto de esa mensualidad en la tabla de amortización del contrato
        $datos = json_decode((string)$contrato['datos_json'], true) ?: [];
        $fila = $datos['amortizacion'][$siguiente - 1] ?? null;
        $importe = $fila ? round((float)$fila['cuota'], 2) : round((float)$contrato['mensualidad'], 2);
        $vence = $fila ? DateTimeImmutable::createFromFormat('d/m/Y', (string)$fila['fecha']) : false;
        if ($recibido < $importe) throw new RuntimeException('El dinero recibido es menor al importe del abono.');
        $cambio = money($recibido - $importe);
        $saldoAnterior = round((float)$contrato['saldo_pendiente'], 2);
        $liquida = $siguiente === $plazo;
        $saldoRestante = $liquida ? 0.0 : max(round($saldoAnterior - $importe, 2), 0.0);

        $pdo->prepare("
            INSERT INTO abonos_credito
            (id_contrato, id_cliente, numero_abono, importe, saldo_anterior, saldo_restante, fecha_vencimiento, id_sucursal, id_usuario,
             id_caja, ticket_numero, metodo_pago, efectivo_recibido, cambio, clave_idempotencia)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Efectivo', ?, ?, ?)
        ")->execute([
            $idContrato, $contrato['id_cliente'], $siguiente, $importe, $saldoAnterior, $saldoRestante, $vence ? $vence->format('Y-m-d') : null,
            $idSucursal, $idUsuario, $idCaja, $ticketNumero, $recibido, $cambio, $clave
        ]);
        $idAbono = (int)$pdo->lastInsertId();
        $pdo->prepare("UPDATE abonos_credito SET folio = ? WHERE id_abono = ?")->execute([sprintf('KRM-AB-%02d-%06d', $idSucursal, $idAbono), $idAbono]);

        // El crédito avanza; al pagar la última mensualidad queda liquidado y sale de la sección Clientes
        $pdo->prepare("
            UPDATE contratos_credito
            SET abonos_pagados = ?, saldo_pendiente = ?, estado_credito = ?, fecha_liquidacion = IF(? = 1, NOW(), fecha_liquidacion)
            WHERE id_contrato = ?
        ")->execute([$siguiente, $saldoRestante, $liquida ? 'liquidado' : 'activo', $liquida ? 1 : 0, $idContrato]);

        // La ficha del cliente (que también muestra la cuenta del Catálogo) refleja su crédito más reciente
        if ($contrato['id_cliente']) {
            $pdo->prepare("
                UPDATE clientes SET abonos_pagados = ?, total_adeudo = ?
                WHERE id_cliente = ? AND ? = (SELECT MAX(k.id_contrato) FROM contratos_credito k WHERE k.id_cliente = ? AND k.estado = 'firmado')
            ")->execute([$siguiente, $saldoRestante, (int)$contrato['id_cliente'], $idContrato, (int)$contrato['id_cliente']]);
        }

        $abono = $pdo->prepare("SELECT * FROM abonos_credito WHERE id_abono = ?");
        $abono->execute([$idAbono]);
        $registrado = $abono->fetch();
        $pdo->commit();
    } catch (RuntimeException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        fail($e->getMessage(), 409);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    ok(abonoRespuesta($pdo, $registrado, $contrato) + ['repetido' => false]);
}

// Datos del abono para el ticket (mismos campos al cobrar y al responder un reenvío)
function abonoRespuesta(PDO $pdo, array $abono, array $contrato): array {
    $fecha = $pdo->prepare("SELECT DATE_FORMAT(?, '%d/%m/%Y %H:%i:%s')");
    $fecha->execute([$abono['fecha_hora']]);
    return [
        'id_abono' => (int)$abono['id_abono'], 'folio' => $abono['folio'], 'fecha' => (string)$fecha->fetchColumn(),
        'numero' => (int)$abono['numero_abono'], 'plazo' => (int)$contrato['plazo_meses'], 'importe' => (float)$abono['importe'],
        'saldo_anterior' => (float)$abono['saldo_anterior'], 'saldo_restante' => (float)$abono['saldo_restante'],
        'liquidado' => (float)$abono['saldo_restante'] <= 0, 'recibido' => (float)$abono['efectivo_recibido'],
        'cambio' => (float)$abono['cambio'], 'metodo' => $abono['metodo_pago'], 'contrato' => $contrato['folio']
    ];
}

// PDF guardado del contrato firmado (para verlo en pantalla o descargarlo)
function verContrato(): never {
    $stmt = db()->prepare("SELECT folio, pdf FROM contratos_credito WHERE id_contrato = ? AND estado = 'firmado' AND pdf IS NOT NULL");
    $stmt->execute([(int)($_GET['id'] ?? 0)]);
    $contrato = $stmt->fetch();
    if (!$contrato) fail('No se encontró el contrato firmado.', 404);
    $archivo = 'contrato-' . preg_replace('/[^A-Za-z0-9\-]/', '', (string)$contrato['folio']) . '.pdf';
    header('Content-Type: application/pdf');
    header('Content-Disposition: ' . (isset($_GET['descargar']) ? 'attachment' : 'inline') . '; filename="' . $archivo . '"');
    header('Content-Length: ' . strlen((string)$contrato['pdf']));
    header('Cache-Control: private, no-store');
    header('X-Content-Type-Options: nosniff');
    echo $contrato['pdf'];
    exit;
}
