<?php
declare(strict_types=1);

/* KARMA · Punto de Venta — Conceptos de caja (seguros, financiamiento, trámites, impuestos y posventa).
   Lo carga api.php. El servidor es la única fuente de verdad de los importes: el navegador manda QUÉ se cobra
   (concepto, plan, vehículo o crédito de referencia y campos capturados) y aquí se recalcula todo con la
   parametrización de la BD (Database/modificaciones.sql):
     1) bootstrap          -> posCatalogoConceptosCaja(): catálogo, planes y vehículos vendidos.
     2) calcular_concepto  -> calcularConcepto(): vista previa del cálculo mientras el cajero captura.
     3) crear_venta        -> posValidarConceptosCaja() + posRegistrarConceptosVenta(): dentro de la MISMA transacción
                              de la venta (y con el mismo gafete de VENTA) se valida, se cobra y se guarda el desglose.
     4) enviar_ticket      -> posConceptosTicketHTML(): sección de conceptos del ticket en PDF, leída de la BD. */

// Límites de captura
const KARMA_CONCEPTO_TEXTO_MAX = 300;
const KARMA_CONCEPTO_AREA_MAX = 1500;
const KARMA_CONCEPTOS_MAX_TICKET = 20;
// VIN de 17 caracteres sin I, O ni Q (norma ISO 3779)
const KARMA_CONCEPTO_VIN_REGEX = '/^[A-HJ-NPR-Z0-9]{17}$/';

/* ===================== Utilidades ===================== */

// "ticket,vendido" -> ['ticket', 'vendido']
function conceptoLista(?string $csv): array {
    return array_values(array_filter(array_map('trim', explode(',', strtolower((string)$csv))), fn($v) => $v !== ''));
}

// Texto capturado: recortado y limitado
function conceptoTexto($valor, int $max = KARMA_CONCEPTO_TEXTO_MAX): string {
    return mb_substr(trim((string)($valor ?? '')), 0, $max);
}

// Número capturado dentro de un rango; null si viene vacío y no es obligatorio
function conceptoNumero($valor, string $etiqueta, float $min, float $max, bool $requerido): ?float {
    if ($valor === null || (is_string($valor) && trim($valor) === '')) {
        if ($requerido) throw new RuntimeException("Captura {$etiqueta}.");
        return null;
    }
    if (!is_numeric($valor)) throw new RuntimeException("{$etiqueta} debe ser un número.");
    $n = (float)$valor;
    if ($n < $min || $n > $max) throw new RuntimeException("{$etiqueta} está fuera del rango permitido.");
    return $n;
}

// Pesos con 2 decimales para mensajes y desglose
function conceptoPesos(float $n): string {
    return '$' . number_format($n, 2, '.', ',');
}

// Escapa texto para el HTML del ticket en PDF (equivalente a h() de correo.php, sin depender de ese archivo)
function conceptoHtml($valor): string {
    return htmlspecialchars((string)($valor ?? ''), ENT_QUOTES, 'UTF-8');
}

// Monto con el mismo formato del ticket en PDF: "$ 1,234.00" (equivalente a karmaMoneyFmt() de correo.php)
function conceptoMonedaPdf($n): string {
    return '$ ' . number_format((float)($n ?? 0), 2);
}

// Definición de los campos extra del concepto (campos_json)
function conceptoCampos(?string $json): array {
    $campos = json_decode((string)$json, true);
    return is_array($campos) ? array_values(array_filter($campos, fn($c) => is_array($c) && !empty($c['clave']))) : [];
}

/* ===================== 1. Catálogo para la interfaz ===================== */

// Catálogo completo que usa la pestaña «Servicios» de la caja. Si el script SQL aún no se importó, la caja sigue
// funcionando sin la pestaña (disponible = false) en lugar de romper el bootstrap.
function posCatalogoConceptosCaja(PDO $pdo, int $idSucursal): array {
    try {
        $stmt = $pdo->prepare("
            SELECT c.*
            FROM conceptos_caja c
            LEFT JOIN conceptos_caja_sucursal cs ON cs.id_concepto = c.id_concepto AND cs.id_sucursal = ?
            WHERE c.activo = 1 AND COALESCE(cs.activo, 1) = 1 AND c.id_producto IS NOT NULL
            ORDER BY c.orden, c.nombre
        ");
        $stmt->execute([$idSucursal]);
        $filas = $stmt->fetchAll();

        $opcionesPorConcepto = [];
        foreach ($pdo->query("SELECT * FROM conceptos_caja_opciones WHERE activo = 1 ORDER BY orden, id_opcion")->fetchAll() as $o) {
            $opcionesPorConcepto[(int)$o['id_concepto']][] = [
                'id' => (int)$o['id_opcion'], 'clave' => $o['clave'], 'descripcion' => $o['descripcion'],
                'tipoVehiculo' => $o['tipo_vehiculo'], 'meses' => $o['meses'] !== null ? (int)$o['meses'] : null
            ];
        }

        $conceptos = array_map(fn(array $c) => [
            'id' => (int)$c['id_concepto'], 'clave' => $c['clave'], 'nombre' => $c['nombre'], 'grupo' => $c['grupo'],
            'descripcion' => $c['descripcion'], 'modo' => $c['modo_calculo'], 'base' => $c['base_calculo'],
            'causaIva' => (int)$c['causa_iva'] === 1, 'origenesVehiculo' => conceptoLista($c['origenes_vehiculo']),
            'vehiculoObligatorio' => (int)$c['vehiculo_obligatorio'] === 1, 'aplicaTipos' => conceptoLista($c['aplica_tipos']),
            'origenesCredito' => conceptoLista($c['origenes_credito']), 'unicoPorVin' => (int)$c['unico_por_vin'] === 1,
            'campos' => conceptoCampos($c['campos_json']), 'opciones' => $opcionesPorConcepto[(int)$c['id_concepto']] ?? []
        ], $filas);

        // Unidades vendidas por KARMA (referencia para ISAN, garantía extendida, trámites y taller)
        $vendidos = $pdo->query("
            SELECT dv.id_detalle, dv.id_producto, dv.vin, dv.precio_unitario, p.marca, p.modelo, p.anio, p.tipo,
                   DATE_FORMAT(v.fecha_hora, '%d/%m/%Y') AS fecha
            FROM detalle_ventas dv
            JOIN ventas v ON v.id_venta = dv.id_venta
            JOIN productos p ON p.id_producto = dv.id_producto
            WHERE p.tipo IN ('auto', 'moto') AND dv.vin IS NOT NULL AND dv.vin <> ''
            ORDER BY v.fecha_hora DESC, dv.id_detalle DESC
            LIMIT 500
        ")->fetchAll();

        return [
            'disponible' => true,
            'conceptos' => $conceptos,
            'vehiculosVendidos' => array_map(fn(array $v) => [
                'idDetalle' => (int)$v['id_detalle'], 'productoId' => (int)$v['id_producto'], 'vin' => $v['vin'],
                'precio' => (float)$v['precio_unitario'], 'marca' => $v['marca'], 'modelo' => $v['modelo'],
                'anio' => $v['anio'] !== null ? (int)$v['anio'] : null, 'tipo' => $v['tipo'], 'fecha' => $v['fecha']
            ], $vendidos)
        ];
    } catch (PDOException $e) {
        return ['disponible' => false, 'conceptos' => [], 'vehiculosVendidos' => [],
                'aviso' => 'Importa Database/modificaciones.sql para habilitar los conceptos de caja.'];
    }
}

/* ===================== 2. Cálculo (único para vista previa y cobro) ===================== */

// Vehículo de referencia del concepto: unidad del ticket, unidad vendida por KARMA o vehículo externo
function conceptoResolverVehiculo(PDO $pdo, array $c, $entrada, array $lineasTicket, bool $enVenta): ?array {
    $origenes = conceptoLista($c['origenes_vehiculo']);
    if (!$origenes) return null;
    $entrada = is_array($entrada) ? $entrada : [];
    $origen = strtolower(trim((string)($entrada['origen'] ?? '')));
    if ($origen === '') {
        if ((int)$c['vehiculo_obligatorio'] === 1) throw new RuntimeException('Elige el vehículo de referencia del concepto.');
        return null;
    }
    if (!in_array($origen, $origenes, true)) throw new RuntimeException('Ese origen de vehículo no está permitido para este concepto.');

    if ($origen === 'ticket') {
        $productoId = (int)($entrada['producto_id'] ?? 0);
        $vin = strtoupper(trim((string)($entrada['vin'] ?? '')));
        $stmt = $pdo->prepare("SELECT id_producto, tipo, vin, precio_base, marca, modelo, anio FROM productos WHERE id_producto = ?");
        $stmt->execute([$productoId]);
        $p = $stmt->fetch();
        if (!$p || !in_array($p['tipo'], ['auto', 'moto'], true)) throw new RuntimeException('El vehículo del ticket no es válido.');
        if ($vin === '' || $vin !== strtoupper((string)$p['vin'])) throw new RuntimeException('El VIN del vehículo del ticket no coincide con el registrado.');
        $valor = (float)$p['precio_base'];
        if ($enVenta) {
            // Debe venderse en ESTE ticket (mismo producto y mismo VIN)
            $linea = null;
            foreach ($lineasTicket as $l) {
                if ((int)$l['id'] === $productoId && strtoupper((string)($l['vin'] ?? '')) === $vin) { $linea = $l; break; }
            }
            if (!$linea) throw new RuntimeException('El vehículo de referencia de un concepto ya no está en el ticket.');
            $valor = (float)$linea['precio'];
        }
        $veh = ['origen' => 'ticket', 'id_producto' => $productoId, 'vin' => $vin, 'tipo' => $p['tipo'], 'valor' => $valor,
                'descripcion' => trim("{$p['marca']} {$p['modelo']} {$p['anio']}")];
    } elseif ($origen === 'vendido') {
        $stmt = $pdo->prepare("
            SELECT dv.id_detalle, dv.id_producto, dv.vin, dv.precio_unitario, p.tipo, p.marca, p.modelo, p.anio
            FROM detalle_ventas dv JOIN productos p ON p.id_producto = dv.id_producto
            WHERE dv.id_detalle = ? AND p.tipo IN ('auto', 'moto') AND dv.vin IS NOT NULL AND dv.vin <> ''
        ");
        $stmt->execute([(int)($entrada['id_detalle'] ?? 0)]);
        $d = $stmt->fetch();
        if (!$d) throw new RuntimeException('No se encontró la unidad vendida por KARMA que elegiste.');
        $veh = ['origen' => 'vendido', 'id_producto' => (int)$d['id_producto'], 'vin' => strtoupper((string)$d['vin']), 'tipo' => $d['tipo'],
                'valor' => (float)$d['precio_unitario'], 'descripcion' => trim("{$d['marca']} {$d['modelo']} {$d['anio']}")];
    } else {
        $vin = strtoupper(trim((string)($entrada['vin'] ?? '')));
        if (!preg_match(KARMA_CONCEPTO_VIN_REGEX, $vin)) throw new RuntimeException('El VIN del vehículo externo debe tener 17 caracteres (letras y números, sin I, O ni Q).');
        $tipo = strtolower(trim((string)($entrada['tipo'] ?? '')));
        if (!in_array($tipo, ['auto', 'moto'], true)) throw new RuntimeException('Indica si el vehículo externo es auto o moto.');
        $marca = conceptoTexto($entrada['marca'] ?? '', 80);
        $modelo = conceptoTexto($entrada['modelo'] ?? '', 120);
        if ($marca === '' || $modelo === '') throw new RuntimeException('Captura la marca y el modelo del vehículo externo.');
        $anio = (int)conceptoNumero($entrada['anio'] ?? null, 'El año del vehículo', 1950, (float)((int)date('Y') + 1), true);
        $valor = conceptoNumero($entrada['valor'] ?? null, 'El valor factura del vehículo', 0, 100000000, false);
        $veh = ['origen' => 'externo', 'id_producto' => null, 'vin' => $vin, 'tipo' => $tipo, 'valor' => $valor,
                'descripcion' => trim("{$marca} {$modelo} {$anio}")];
    }

    if (!in_array($veh['tipo'], conceptoLista($c['aplica_tipos']), true)) {
        throw new RuntimeException("{$c['nombre']} no aplica para " . ($veh['tipo'] === 'moto' ? 'motocicletas.' : 'automóviles.'));
    }
    return $veh;
}

// Crédito de referencia: contrato firmado en KARMA (se lee de la BD) o crédito con financiera externa (capturado)
function conceptoResolverCredito(PDO $pdo, array $c, $entrada): ?array {
    $origenes = conceptoLista($c['origenes_credito']);
    if (!$origenes) return null;
    $entrada = is_array($entrada) ? $entrada : [];
    $origen = strtolower(trim((string)($entrada['origen'] ?? '')));
    if (!in_array($origen, $origenes, true)) throw new RuntimeException('Elige el crédito de referencia del concepto.');

    if ($origen === 'karma') {
        $stmt = $pdo->prepare("
            SELECT id_contrato, folio, monto_financiado, plazo_meses, estado, estado_credito, vin
            FROM contratos_credito WHERE folio = ? LIMIT 1
        ");
        $stmt->execute([conceptoTexto($entrada['folio'] ?? '', 30)]);
        $k = $stmt->fetch();
        if (!$k) throw new RuntimeException('No existe un contrato de crédito KARMA con ese folio.');
        if ($k['estado'] !== 'firmado' || ($k['estado_credito'] ?? 'activo') !== 'activo') throw new RuntimeException('El contrato elegido no es un crédito activo.');
        return ['origen' => 'karma', 'id_contrato' => (int)$k['id_contrato'], 'folio' => $k['folio'], 'institucion' => 'KARMA',
                'monto' => (float)$k['monto_financiado'], 'plazo' => (int)$k['plazo_meses'], 'vin' => $k['vin']];
    }

    $institucion = conceptoTexto($entrada['institucion'] ?? '', 120);
    if ($institucion === '') throw new RuntimeException('Captura la institución financiera del crédito.');
    $monto = (float)conceptoNumero($entrada['monto'] ?? null, 'El monto del crédito', 1, 100000000, true);
    $plazo = (int)conceptoNumero($entrada['plazo'] ?? null, 'El plazo del crédito', 1, 120, true);
    return ['origen' => 'externo', 'id_contrato' => null, 'folio' => null, 'institucion' => $institucion, 'monto' => $monto, 'plazo' => $plazo, 'vin' => null];
}

// Valida los campos extra con su definición (requeridos, tipo, opciones y longitud)
function conceptoValidarCampos(array $c, $entrada): array {
    $entrada = is_array($entrada) ? $entrada : [];
    $valores = [];
    foreach (conceptoCampos($c['campos_json']) as $def) {
        $clave = (string)$def['clave'];
        $etiqueta = (string)($def['etiqueta'] ?? $clave);
        $tipo = (string)($def['tipo'] ?? 'texto');
        $requerido = !empty($def['requerido']);
        if ($tipo === 'numero') {
            $n = conceptoNumero($entrada[$clave] ?? null, $etiqueta, 0, 100000000, $requerido);
            $valores[$clave] = $n === null ? '' : (string)$n;
            continue;
        }
        $valor = conceptoTexto($entrada[$clave] ?? '', $tipo === 'area' ? KARMA_CONCEPTO_AREA_MAX : KARMA_CONCEPTO_TEXTO_MAX);
        if ($requerido && $valor === '') throw new RuntimeException("Captura {$etiqueta}.");
        if ($tipo === 'select' && $valor !== '' && !in_array($valor, (array)($def['opciones'] ?? []), true)) {
            throw new RuntimeException("Elige una opción válida en {$etiqueta}.");
        }
        $valores[$clave] = $valor;
    }
    return $valores;
}

// Cuota por tramos (ISAN): cuota fija + (base − límite inferior) × % excedente, con la tarifa del ejercicio vigente
function conceptoCuotaTarifa(PDO $pdo, int $idConcepto, float $base): array {
    $stmt = $pdo->prepare("
        SELECT limite_inferior, limite_superior, cuota_fija, porcentaje_excedente, ejercicio
        FROM conceptos_caja_tarifas
        WHERE id_concepto = ?
          AND ejercicio = (SELECT MAX(t2.ejercicio) FROM conceptos_caja_tarifas t2 WHERE t2.id_concepto = ? AND t2.ejercicio <= YEAR(CURDATE()))
          AND limite_inferior <= ?
        ORDER BY limite_inferior DESC
        LIMIT 1
    ");
    $stmt->execute([$idConcepto, $idConcepto, $base]);
    $t = $stmt->fetch();
    if (!$t) throw new RuntimeException('No hay una tarifa vigente configurada para este concepto.');
    $cuota = (float)$t['cuota_fija'] + max($base - (float)$t['limite_inferior'], 0) * (float)$t['porcentaje_excedente'] / 100;
    return ['cuota' => $cuota, 'tramo' => $t];
}

// Calcula un concepto con la parametrización de la BD. $enVenta = true bloquea filas (FOR UPDATE) y exige que el
// vehículo «del ticket» venga en las líneas de esta venta; en la vista previa ($enVenta = false) solo se valida.
function posCalcularConcepto(PDO $pdo, $entrada, int $idSucursal, array $lineasTicket, bool $enVenta): array {
    if (!is_array($entrada)) throw new RuntimeException('Concepto no válido.');
    $stmt = $pdo->prepare("
        SELECT c.*
        FROM conceptos_caja c
        LEFT JOIN conceptos_caja_sucursal cs ON cs.id_concepto = c.id_concepto AND cs.id_sucursal = ?
        WHERE c.id_concepto = ? AND c.activo = 1 AND COALESCE(cs.activo, 1) = 1
    ");
    $stmt->execute([$idSucursal, (int)($entrada['id_concepto'] ?? 0)]);
    $c = $stmt->fetch();
    if (!$c) throw new RuntimeException('El concepto ya no está disponible en esta sucursal.');
    if (!$c['id_producto']) throw new RuntimeException("{$c['nombre']} no tiene producto de servicio ligado. Vuelve a importar Database/modificaciones.sql.");

    $idConcepto = (int)$c['id_concepto'];
    $tasaIva = (float)$c['tasa_iva'];
    $veh = conceptoResolverVehiculo($pdo, $c, $entrada['vehiculo'] ?? null, $lineasTicket, $enVenta);
    $cred = conceptoResolverCredito($pdo, $c, $entrada['credito'] ?? null);
    $campos = conceptoValidarCampos($c, $entrada['campos'] ?? []);

    // Un solo cobro por VIN (ISAN, alta de placas, holograma 00)
    if ((int)$c['unico_por_vin'] === 1 && $veh && $veh['vin'] !== '') {
        $dup = $pdo->prepare("SELECT folio FROM ventas_conceptos WHERE id_concepto = ? AND vin = ? AND estado = 'cobrado' LIMIT 1" . ($enVenta ? ' FOR UPDATE' : ''));
        $dup->execute([$idConcepto, $veh['vin']]);
        if ($folio = $dup->fetchColumn()) throw new RuntimeException("El VIN {$veh['vin']} ya tiene cobrado {$c['nombre']} (folio {$folio}).");
    }

    // Plan elegido: debe pertenecer al concepto y al tipo de vehículo
    $opcion = null;
    $opc = $pdo->prepare("SELECT * FROM conceptos_caja_opciones WHERE id_concepto = ? AND activo = 1 ORDER BY orden, id_opcion");
    $opc->execute([$idConcepto]);
    $opciones = array_values(array_filter($opc->fetchAll(), fn($o) => $o['tipo_vehiculo'] === 'todos' || ($veh && $o['tipo_vehiculo'] === $veh['tipo'])));
    if ($opciones) {
        foreach ($opciones as $o) if ((int)$o['id_opcion'] === (int)($entrada['id_opcion'] ?? 0)) $opcion = $o;
        if (!$opcion) throw new RuntimeException('Elige el plan o cobertura de ' . $c['nombre'] . '.');
    }

    // Parámetros efectivos: el plan sustituye al concepto
    $pct = (float)($opcion['porcentaje'] ?? $c['porcentaje'] ?? 0);
    $fijo = (float)($opcion['monto_fijo'] ?? $c['monto_fijo'] ?? 0);
    $exentoFijo = (float)($opcion['monto_exento'] ?? $c['monto_exento'] ?? 0);
    $meses = $opcion['meses'] ?? $c['vigencia_meses'];
    $meses = $meses !== null ? (int)$meses : null;
    $modo = $c['modo_calculo'];

    // Base de cálculo
    $base = 0.0;
    switch ($c['base_calculo']) {
        case 'vehiculo': $base = (float)($veh['valor'] ?? 0); break;
        case 'vehiculo_sin_iva': $base = (float)($veh['valor'] ?? 0) / (1 + $tasaIva / 100); break;
        case 'credito': $base = (float)($cred['monto'] ?? 0); break;
    }
    $base = round($base, 2);
    $necesitaBase = $modo === 'TARIFA' || (in_array($modo, ['PORCENTAJE', 'PORCENTAJE_MENSUAL', 'FIJO'], true) && $pct > 0);
    if ($necesitaBase && $base <= 0) {
        throw new RuntimeException(($veh && $veh['origen'] === 'externo')
            ? 'Captura el valor factura del vehículo externo: es la base del cálculo.'
            : 'No hay una base válida para calcular ' . $c['nombre'] . '.');
    }

    // Parte variable según la fórmula del concepto
    $desglose = [];
    $tramo = null;
    $materiales = 0.0;
    $variable = 0.0;
    switch ($modo) {
        case 'PORCENTAJE_MENSUAL':
            $plazo = (int)($cred['plazo'] ?? 0);
            $variable = $base * $pct / 100 * $plazo;
            $meses = $plazo;
            $desglose[] = ['Monto del crédito', conceptoPesos($base)];
            $desglose[] = ['Tasa mensual × plazo', rtrim(rtrim(number_format($pct, 4), '0'), '.') . "% × {$plazo} meses"];
            break;
        case 'TARIFA':
            $t = conceptoCuotaTarifa($pdo, $idConcepto, $base);
            $variable = $t['cuota'];
            $tramo = $t['tramo'];
            $desglose[] = ['Base sin IVA', conceptoPesos($base)];
            $desglose[] = ['Tramo ' . $tramo['ejercicio'], conceptoPesos((float)$tramo['cuota_fija']) . ' + ' . (float)$tramo['porcentaje_excedente'] . '% s/excedente de ' . conceptoPesos((float)$tramo['limite_inferior'])];
            break;
        case 'MANO_OBRA':
            $horas = (float)conceptoNumero($campos['horas'] ?? null, 'Las horas de mano de obra', 0.1, 500, true);
            $materiales = (float)(conceptoNumero($campos['materiales'] ?? null, 'Refacciones y materiales', 0, 10000000, false) ?? 0);
            $variable = $horas * $fijo;
            $desglose[] = ['Mano de obra', "{$horas} h × " . conceptoPesos($fijo)];
            if ($materiales > 0) $desglose[] = ['Refacciones y materiales', conceptoPesos($materiales)];
            break;
        default:
            $variable = $base * $pct / 100;
            if ($pct > 0) {
                $desglose[] = ['Base de cálculo', conceptoPesos($base)];
                $desglose[] = ['Porcentaje', rtrim(rtrim(number_format($pct, 4), '0'), '.') . '%'];
            }
    }
    if ($variable > 0 && $c['monto_minimo'] !== null && $variable < (float)$c['monto_minimo']) {
        $variable = (float)$c['monto_minimo'];
        $desglose[] = ['Mínimo aplicado', conceptoPesos($variable)];
    }
    if ($variable > 0 && $c['monto_maximo'] !== null && $variable > (float)$c['monto_maximo']) {
        $variable = (float)$c['monto_maximo'];
        $desglose[] = ['Tope aplicado', conceptoPesos($variable)];
    }

    // Parte gravada (incluye IVA) y exenta (derechos e impuestos)
    $gravable = $modo === 'MANO_OBRA' ? $variable + $materiales : $variable + $fijo;
    $gravado = (int)$c['causa_iva'] === 1 ? $gravable : 0.0;
    $exento = ((int)$c['causa_iva'] === 1 ? 0.0 : $gravable) + $exentoFijo;
    if ($modo !== 'MANO_OBRA' && $fijo > 0) $desglose[] = ['Cuota' . ((int)$c['causa_iva'] === 1 ? ' (con IVA)' : ''), conceptoPesos($fijo)];
    if ($exentoFijo > 0) $desglose[] = ['Derechos (sin IVA)', conceptoPesos($exentoFijo)];

    // Redondeo al peso del importe del servicio (art. 20 CFF); la diferencia se aplica a la parte gravada
    $gravado = round($gravado, 2);
    $exento = round($exento, 2);
    $servicioTotal = round($gravado + $exento, 0);
    if ($gravado > 0) $gravado = round($servicioTotal - $exento, 2);
    else $exento = $servicioTotal;

    $total = $servicioTotal;
    if ($total <= 0) throw new RuntimeException("{$c['nombre']} no tiene importe a cobrar con los datos capturados.");

    $factor = 1 + $tasaIva / 100;
    $subtotal = round($exento + $gravado / $factor, 2);
    $iva = round($total - $subtotal, 2);

    // Referencia (póliza, folio de OS, placas…) y su unicidad
    $referencia = null;
    if ($c['campo_referencia']) {
        $referencia = conceptoTexto($campos[$c['campo_referencia']] ?? '', 80) ?: null;
    }
    if ($cred && $cred['origen'] === 'karma' && $referencia === null) $referencia = $cred['folio'];
    if ((int)$c['referencia_unica'] === 1 && $referencia !== null) {
        $dup = $pdo->prepare("SELECT folio FROM ventas_conceptos WHERE id_concepto = ? AND referencia = ? AND estado = 'cobrado' LIMIT 1" . ($enVenta ? ' FOR UPDATE' : ''));
        $dup->execute([$idConcepto, $referencia]);
        if ($folio = $dup->fetchColumn()) throw new RuntimeException("La referencia {$referencia} ya se cobró en {$c['nombre']} (folio {$folio}).");
    }

    // Vigencia: hoy + meses; la garantía extendida empieza cuando vence la garantía KARMA vigente del VIN
    $inicio = $fin = null;
    if ($meses) {
        $desde = new DateTimeImmutable('today');
        if ($c['clave'] === 'GARANTIA_EXT' && $veh) {
            $g = $pdo->prepare("SELECT DATE(MAX(fecha_expiracion)) FROM garantias WHERE vin = ? AND estado = 'vigente' AND fecha_expiracion > NOW()");
            $g->execute([$veh['vin']]);
            if ($vence = $g->fetchColumn()) $desde = new DateTimeImmutable((string)$vence);
        }
        $inicio = $desde->format('Y-m-d');
        $fin = $desde->modify("+{$meses} month")->format('Y-m-d');
    }

    return [
        'id_concepto' => $idConcepto, 'clave' => $c['clave'], 'nombre' => $c['nombre'], 'id_producto_servicio' => (int)$c['id_producto'],
        'unico_por_vin' => (int)$c['unico_por_vin'] === 1, 'referencia_unica' => (int)$c['referencia_unica'] === 1,
        'id_opcion' => $opcion ? (int)$opcion['id_opcion'] : null, 'opcion' => $opcion['descripcion'] ?? null,
        'vehiculo' => $veh, 'credito' => $cred, 'campos' => $campos, 'referencia' => $referencia,
        'base' => $base, 'porcentaje' => $pct > 0 ? $pct : null, 'tramo' => $tramo, 'desglose' => $desglose,
        'gravado' => $gravado, 'exento' => $exento, 'servicio_total' => $servicioTotal,
        'subtotal' => $subtotal, 'iva' => $iva, 'total' => $total, 'vigencia_inicio' => $inicio, 'vigencia_fin' => $fin,
        'descripcion_ticket' => $c['nombre'] . ($opcion ? ' · ' . $opcion['descripcion'] : '')
    ];
}

// Lo que ve la interfaz del cálculo (sin datos internos)
function conceptoRespuesta(array $r): array {
    $fecha = fn(?string $f) => $f ? (new DateTimeImmutable($f))->format('d/m/Y') : null;
    return [
        'idConcepto' => $r['id_concepto'], 'clave' => $r['clave'], 'nombre' => $r['nombre'], 'opcion' => $r['opcion'],
        'descripcion' => $r['descripcion_ticket'], 'referencia' => $r['referencia'],
        'vehiculo' => $r['vehiculo'] ? ['vin' => $r['vehiculo']['vin'], 'descripcion' => $r['vehiculo']['descripcion'], 'tipo' => $r['vehiculo']['tipo']] : null,
        'credito' => $r['credito'] ? ['origen' => $r['credito']['origen'], 'folio' => $r['credito']['folio'], 'institucion' => $r['credito']['institucion'], 'plazo' => $r['credito']['plazo']] : null,
        'base' => $r['base'], 'porcentaje' => $r['porcentaje'], 'desglose' => $r['desglose'],
        'gravado' => $r['gravado'], 'exento' => $r['exento'], 'subtotal' => $r['subtotal'], 'iva' => $r['iva'], 'total' => $r['total'],
        'vigenciaInicio' => $fecha($r['vigencia_inicio']), 'vigenciaFin' => $fecha($r['vigencia_fin'])
    ];
}

/* ===================== 3. Cobro dentro de la venta ===================== */

// Recalcula y valida TODOS los conceptos del ticket dentro de la transacción de crear_venta.
// Regresa [conceptos calculados, suma de sus totales]
function posValidarConceptosCaja(PDO $pdo, $conceptos, int $idSucursal, array $productosVenta): array {
    if (!is_array($conceptos) || !$conceptos) return [[], 0.0];
    if (count($conceptos) > KARMA_CONCEPTOS_MAX_TICKET) throw new RuntimeException('El ticket tiene demasiados conceptos.');

    $lista = [];
    $total = 0.0;
    $vinesUnicos = [];
    $referenciasUnicas = [];

    foreach (array_values($conceptos) as $entrada) {
        $r = posCalcularConcepto($pdo, $entrada, $idSucursal, $productosVenta, true);
        // Repetidos dentro del mismo ticket
        if ($r['unico_por_vin'] && $r['vehiculo']) {
            $k = $r['id_concepto'] . '|' . $r['vehiculo']['vin'];
            if (isset($vinesUnicos[$k])) throw new RuntimeException("{$r['nombre']} está dos veces para el mismo VIN.");
            $vinesUnicos[$k] = true;
        }
        if ($r['referencia_unica'] && $r['referencia'] !== null) {
            $k = $r['id_concepto'] . '|' . $r['referencia'];
            if (isset($referenciasUnicas[$k])) throw new RuntimeException("La referencia {$r['referencia']} está repetida en el ticket.");
            $referenciasUnicas[$k] = true;
        }
        $lista[] = $r;
        $total += $r['total'];
    }
    return [$lista, round($total, 2)];
}

// Guarda el desglose (ventas_conceptos) y la línea de cada concepto en detalle_ventas.
// Regresa los folios para el ticket.
function posRegistrarConceptosVenta(PDO $pdo, int $ventaId, array $lista, array $ctx): array {
    if (!$lista) return [];
    $ins = $pdo->prepare("
        INSERT INTO ventas_conceptos
        (id_venta, id_concepto, id_opcion, id_sucursal, id_caja, id_usuario, id_producto_vehiculo, vin, vehiculo_origen, vehiculo_descripcion,
         id_contrato, credito_origen, referencia, base_calculo, porcentaje, importe_gravado, importe_exento,
         subtotal, iva, total, vigencia_inicio, vigencia_fin, datos_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $folioStmt = $pdo->prepare("UPDATE ventas_conceptos SET folio = ? WHERE id_venta_concepto = ?");
    $detalle = $pdo->prepare("
        INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal_linea, vin, motor_serie, color_interior, id_venta_concepto)
        VALUES (?, ?, 1, ?, ?, NULL, NULL, NULL, ?)
    ");

    $folios = [];
    $totalConceptos = 0.0;
    foreach ($lista as $r) {
        $veh = $r['vehiculo'];
        $cred = $r['credito'];
        $datos = [
            'plan' => $r['opcion'], 'campos' => $r['campos'], 'desglose' => $r['desglose'], 'tramo' => $r['tramo'],
            'credito' => $cred ? ['origen' => $cred['origen'], 'folio' => $cred['folio'], 'institucion' => $cred['institucion'], 'monto' => $cred['monto'], 'plazo' => $cred['plazo']] : null
        ];
        $ins->execute([
            $ventaId, $r['id_concepto'], $r['id_opcion'], $ctx['id_sucursal'], $ctx['id_caja'], $ctx['id_usuario'],
            $veh['id_producto'] ?? null, $veh['vin'] ?? null, $veh['origen'] ?? null, $veh['descripcion'] ?? null,
            $cred['id_contrato'] ?? null, $cred['origen'] ?? null, $r['referencia'],
            $r['base'], $r['porcentaje'], $r['gravado'], $r['exento'], $r['subtotal'], $r['iva'], $r['total'],
            $r['vigencia_inicio'], $r['vigencia_fin'], json_encode($datos, JSON_UNESCAPED_UNICODE)
        ]);
        $idVc = (int)$pdo->lastInsertId();
        $folio = sprintf('KRM-SC-%02d-%06d', (int)$ctx['id_sucursal'], $idVc);
        $folioStmt->execute([$folio, $idVc]);

        // Línea del servicio (producto tipo servicio, sin inventario)
        if ($r['servicio_total'] > 0) {
            $detalle->execute([$ventaId, $r['id_producto_servicio'], $r['servicio_total'], $r['servicio_total'], $idVc]);
        }

        $totalConceptos += $r['total'];
        $folios[] = [
            'folio' => $folio, 'idConcepto' => $r['id_concepto'], 'nombre' => $r['nombre'], 'descripcion' => $r['descripcion_ticket'],
            'total' => $r['total'], 'subtotal' => $r['subtotal'], 'iva' => $r['iva'], 'referencia' => $r['referencia'],
            'vin' => $veh['vin'] ?? null,
            'vigenciaFin' => $r['vigencia_fin'] ? (new DateTimeImmutable($r['vigencia_fin']))->format('d/m/Y') : null
        ];
    }
    $pdo->prepare("UPDATE ventas SET total_conceptos = ? WHERE id_venta = ?")->execute([round($totalConceptos, 2), $ventaId]);
    return $folios;
}

/* ===================== 4. Acción calcular_concepto (vista previa) ===================== */

function calcularConcepto(): never {
    if (!posCsrfValido()) fail('Solicitud no válida. Recarga la página e inténtalo de nuevo.', 403);
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    try {
        $r = posCalcularConcepto(db(), $data['concepto'] ?? null, (int)$cajero['id_sucursal'], [], false);
    } catch (RuntimeException $e) {
        fail($e->getMessage(), 422);
    } catch (PDOException $e) {
        fail('Los conceptos de caja no están instalados en la base de datos (Database/modificaciones.sql).', 503);
    }
    ok(['calculo' => conceptoRespuesta($r)]);
}

/* ===================== 5. Sección del ticket en PDF (correo.php) ===================== */

// Tabla de conceptos cobrados en la venta, leída de la BD (no del navegador). Cadena vacía si no hay conceptos.
function posConceptosTicketHTML(PDO $pdo, int $ventaId): string {
    if ($ventaId <= 0) return '';
    try {
        $stmt = $pdo->prepare("
            SELECT vc.folio, c.nombre, o.descripcion AS plan, vc.vin, vc.vehiculo_descripcion, vc.referencia,
                   vc.subtotal, vc.iva, vc.importe_exento, vc.total,
                   DATE_FORMAT(vc.vigencia_inicio, '%d/%m/%Y') AS desde, DATE_FORMAT(vc.vigencia_fin, '%d/%m/%Y') AS hasta
            FROM ventas_conceptos vc
            JOIN conceptos_caja c ON c.id_concepto = vc.id_concepto
            LEFT JOIN conceptos_caja_opciones o ON o.id_opcion = vc.id_opcion
            WHERE vc.id_venta = ? AND vc.id_sucursal = ? AND vc.estado = 'cobrado'
            ORDER BY vc.id_venta_concepto
        ");
        // Solo ventas de la sucursal del cajero en sesión
        $stmt->execute([$ventaId, (int)($GLOBALS['cajeroSesion']['id_sucursal'] ?? 0)]);
        $filas = $stmt->fetchAll();
    } catch (PDOException $e) {
        return '';
    }
    if (!$filas) return '';

    $html = '';
    foreach ($filas as $f) {
        $detalle = array_filter([
            $f['plan'] ? conceptoHtml($f['plan']) : '',
            $f['vin'] ? 'VIN ' . conceptoHtml($f['vin']) . ($f['vehiculo_descripcion'] ? ' · ' . conceptoHtml($f['vehiculo_descripcion']) : '') : '',
            $f['referencia'] ? 'Ref. ' . conceptoHtml($f['referencia']) : '',
            $f['hasta'] ? 'Vigencia ' . conceptoHtml($f['desde']) . ' al ' . conceptoHtml($f['hasta']) : ''
        ]);
        $html .= '<tr><td><strong>' . conceptoHtml($f['nombre']) . '</strong><br><span class="muted">Folio ' . conceptoHtml($f['folio']) . ($detalle ? ' — ' . implode(' — ', $detalle) : '') . '</span></td>'
            . '<td class="der">' . conceptoMonedaPdf($f['subtotal']) . '</td>'
            . '<td class="der">' . conceptoMonedaPdf($f['iva']) . '</td>'
            . '<td class="der">' . conceptoMonedaPdf($f['total']) . '</td></tr>';
    }
    return '<h2>2c. Servicios, seguros y trámites</h2>
      <table class="tabla-datos">
        <tr><td class="etq">Concepto</td><td class="der etq">Subtotal</td><td class="der etq">IVA</td><td class="der etq">Total</td></tr>
        ' . $html . '
      </table>
      <div class="muted">Los derechos e impuestos (ISAN, tenencia, refrendo y derechos de control vehicular) no causan IVA. Importes redondeados al peso.</div>';
}
?>
