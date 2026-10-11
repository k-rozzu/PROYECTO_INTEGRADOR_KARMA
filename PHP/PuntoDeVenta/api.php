<?php
declare(strict_types=1);

/* API principal del Punto de Venta */
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/conexion.php';

// Lee el cuerpo JSON de la petición y lo regresa como arreglo
function jsonInput(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

// Responde con éxito (ok = true) y termina la ejecución
function ok(array $data = []): never {
    echo json_encode(['ok' => true] + $data, JSON_UNESCAPED_UNICODE);
    exit;
}

// Responde con un error y su código HTTP, y termina la ejecución
function fail(string $message, int $status = 400): never {
    http_response_code($status);
    echo json_encode(['ok' => false, 'error' => $message], JSON_UNESCAPED_UNICODE);
    exit;
}

// Redondea un monto a 2 decimales
function money(float $value): float {
    return round($value, 2);
}

// Seguridad: todas las acciones (excepto cerrar sesión) requieren la sesión de un Cajero activo (login del sistema)
require_once dirname(__DIR__) . '/Login/sesion_pos.php';
$GLOBALS['cajeroSesion'] = ($_GET['action'] ?? '') === 'logout' ? null : posRequerirApi(db());
// Autorización de empleado (gafete QR o código) para las acciones sensibles: lógica central en autorizacion_empleado.php
require_once __DIR__ . '/autorizacion_empleado.php';
// Conceptos de caja (seguros, financiamiento, trámites, impuestos y posventa): cálculo, cobro y desglose en conceptos_caja.php
require_once __DIR__ . '/conceptos_caja.php';

// Enrutador: ejecuta la acción pedida en ?action=
try {
    $action = $_GET['action'] ?? '';

    // Capa de autorización: concretar venta, concretar crédito, aplicar garantía y cobrar/cancelar órdenes web exigen un permiso
    // vigente del gafete del MISMO usuario de la sesión. Se valida y se consume aquí, ANTES de llamar a la función original:
    // sin permiso válido la petición termina en 403 y no se toca ninguna tabla (ni ventas, ni inventario, ni órdenes).
    $accionProtegida = posAccionProtegida((string)$action, jsonInput());
    if ($accionProtegida) {
        $rechazo = posConsumirAutorizacion(db(), $GLOBALS['cajeroSesion'], $accionProtegida[0], $accionProtegida[1], (string)$action);
        if ($rechazo !== null) fail($rechazo, 403);
    }

    switch ($action) {
        case 'bootstrap':
            bootstrap();
            break;
        case 'validar_vin':
            validarVin();
            break;
        case 'crear_venta':
            crearVenta();
            break;
        // Vista previa del cálculo de un concepto de caja (el cobro real ocurre dentro de crear_venta)
        case 'calcular_concepto':
            calcularConcepto();
            break;
        case 'enviar_ticket':
            enviarTicket();
            break;
        case 'cobrar_orden_web':
            cobrarOrdenWeb();
            break;
        case 'cancelar_orden_web':
            cancelarOrdenWeb();
            break;
        case 'autorizar_empleado':
            autorizarEmpleado();
            break;
        case 'aplicar_garantia':
            aplicarGarantia();
            break;
        // Crédito automotriz con contrato: cobro del enganche → contrato → firma del cliente (lógica en contrato_credito.php)
        case 'preparar_credito':
            require_once __DIR__ . '/contrato_credito.php';
            prepararCredito();
            break;
        case 'concretar_credito':
            require_once __DIR__ . '/contrato_credito.php';
            concretarCredito();
            break;
        case 'cancelar_credito':
            require_once __DIR__ . '/contrato_credito.php';
            cancelarCredito();
            break;
        case 'ver_contrato':
            require_once __DIR__ . '/contrato_credito.php';
            verContrato();
            break;
        case 'cobrar_abono':
            require_once __DIR__ . '/contrato_credito.php';
            cobrarAbono();
            break;
        case 'logout':
            posCerrarSesion();
            ok(['message' => 'Sesión cerrada.']);
            break;
        default:
            fail('Acción no reconocida.', 404);
    }
} catch (Throwable $e) {
    fail($e->getMessage(), 500);
}

// Ruta del modelo 3D de un producto: la guardada en la BD o, si existe el archivo, assets/models/{id}.glb
function rutaModelo3D(int $id, ?string $rutaBD): ?string {
    if ($rutaBD !== null && trim($rutaBD) !== '') return trim($rutaBD);
    $relativa = "assets/models/{$id}.glb";
    return is_file(dirname(__DIR__, 2) . '/' . $relativa) ? $relativa : null;
}

/* Carga todos los catálogos que utiliza la interfaz */
function bootstrap(): never {
    $pdo = db();

    // Cajero que inició sesión en el login del sistema (validado en PHP/Login/sesion_pos.php)
    $cajero = $GLOBALS['cajeroSesion'];
    $usuario = [
        'id_usuario' => (int)$cajero['id_usuario'],
        'nombre' => $cajero['nombre'],
        'correo' => $cajero['correo'],
        'id_sucursal' => $cajero['id_sucursal'] !== null ? (int)$cajero['id_sucursal'] : null
    ];

    // Sucursal activa del cajero
    $sucursalStmt = $pdo->prepare("
        SELECT id_sucursal, nombre, direccion, telefono
        FROM sucursales
        WHERE id_sucursal = ? AND estado = 'activo'
        LIMIT 1
    ");
    $sucursalStmt->execute([$usuario['id_sucursal']]);
    $sucursal = $sucursalStmt->fetch();

    if (!$sucursal) {
        fail('El cajero no tiene una sucursal activa asignada.', 503);
    }

    // Caja 01 de esa sucursal
    $cajaStmt = $pdo->prepare("
        SELECT id_caja, numero_caja, estado
        FROM cajas
        WHERE id_sucursal = ? AND numero_caja = 1
        LIMIT 1
    ");
    $cajaStmt->execute([$sucursal['id_sucursal']]);
    $caja = $cajaStmt->fetch();

    if (!$caja) {
        fail('No existe la caja 01 para la sucursal del cajero.', 503);
    }

    // Número del siguiente ticket = ventas + abonos de HOY en esta caja + 1 (así no se reinicia al recargar)
    $siguienteTicketStmt = $pdo->prepare("
        SELECT (SELECT COUNT(*) FROM ventas WHERE id_caja = ? AND DATE(fecha_hora) = CURDATE())
             + (SELECT COUNT(*) FROM abonos_credito WHERE id_caja = ? AND DATE(fecha_hora) = CURDATE())
    ");
    $siguienteTicketStmt->execute([$caja['id_caja'], $caja['id_caja']]);
    $siguienteTicket = (int)$siguienteTicketStmt->fetchColumn() + 1;

    // Inventario completo de la sucursal (incluye productos con 0 unidades, su VIN, color y modelo 3D).
    // Los productos tipo 'servicio' (conceptos de caja) no son artículos físicos: no se listan en Inventario
    $inventario = $pdo->prepare("
        SELECT
            p.id_producto AS id,
            p.codigo_barras AS codigo,
            p.vin,
            p.marca,
            p.modelo,
            p.anio,
            p.tipo,
            p.color,
            p.color_hex AS colorHex,
            p.color_interior AS colorInterior,
            p.motor,
            p.cilindraje,
            p.detalle,
            p.nombre,
            p.compatibilidad,
            p.traccion,
            p.lado,
            p.modelo_3d AS modelo3d,
            p.precio_base AS precio,
            COALESCE(i.stock_actual, 0) AS unidades,
            c.nombre_categoria AS categoria
        FROM productos p
        JOIN categorias c ON c.id_categoria = p.id_categoria
        LEFT JOIN inventarios i ON i.id_producto = p.id_producto AND i.id_sucursal = ?
        WHERE p.tipo <> 'servicio'
        ORDER BY p.marca, p.modelo, p.anio, p.nombre
    ");
    $inventario->execute([$sucursal['id_sucursal']]);
    $inventarioRows = $inventario->fetchAll(PDO::FETCH_ASSOC);

    // Sección Clientes: SOLO créditos automotrices activos con saldo pendiente (un renglón por crédito).
    // Al liquidar la última mensualidad el crédito queda 'liquidado' y deja de aparecer; su historial se conserva.
    $creditosActivos = $pdo->query("
        SELECT cc.id_contrato, cc.folio, c.id_cliente, c.nombre, c.rfc_ine, c.celular, c.email, c.direccion,
               c.identificacion_tipo, c.identificacion_numero, CONCAT_WS(' ', p.marca, p.modelo, p.anio) AS articulo,
               cc.vin, cc.enganche, cc.mensualidad, cc.plazo_meses, cc.abonos_pagados, cc.saldo_pendiente, cc.monto_total, cc.datos_json
        FROM contratos_credito cc
        JOIN clientes c ON c.id_cliente = cc.id_cliente
        JOIN productos p ON p.id_producto = cc.id_producto
        WHERE cc.estado = 'firmado' AND cc.estado_credito = 'activo' AND cc.saldo_pendiente > 0
        ORDER BY c.nombre, cc.id_contrato
    ")->fetchAll();
    $clientes = [];
    foreach ($creditosActivos as $k) {
        // Siguiente mensualidad según la tabla de amortización guardada con el contrato
        $siguiente = (int)$k['abonos_pagados'] + 1;
        $fila = (json_decode((string)$k['datos_json'], true) ?: [])['amortizacion'][$siguiente - 1] ?? null;
        $clientes[] = [
            'id' => (int)$k['id_contrato'], 'idCliente' => (int)$k['id_cliente'],
            'contratoId' => (int)$k['id_contrato'], 'contratoFolio' => $k['folio'],
            'nombre' => $k['nombre'], 'rfcIne' => $k['rfc_ine'], 'celular' => $k['celular'], 'email' => $k['email'],
            'direccion' => $k['direccion'], 'identificacionTipo' => $k['identificacion_tipo'], 'identificacionNumero' => $k['identificacion_numero'],
            'articulo' => $k['articulo'], 'vin' => $k['vin'],
            'totalAdeudo' => (float)$k['saldo_pendiente'], 'montoTotal' => (float)$k['monto_total'],
            'montoAbono' => $fila ? (float)$fila['cuota'] : round((float)$k['mensualidad'], 2), 'enganche' => (float)$k['enganche'],
            'abonosPagados' => (int)$k['abonos_pagados'], 'abonosTotales' => (int)$k['plazo_meses'],
            'siguienteAbono' => $siguiente, 'venceSiguiente' => $fila['fecha'] ?? null
        ];
    }

    // Contratos de crédito firmados de cada cliente (botón "Ver contrato" del detalle): uno por operación
    $contratosPorCliente = [];
    $contratosStmt = $pdo->query("
        SELECT cc.id_contrato, cc.id_cliente, cc.folio, cc.id_venta, cc.plazo_meses, cc.mensualidad, cc.enganche,
               cc.estado_credito, cc.abonos_pagados,
               DATE_FORMAT(cc.fecha_firma, '%d/%m/%Y %H:%i') AS fecha, s.nombre AS sucursal,
               CONCAT_WS(' ', p.marca, p.modelo, p.anio) AS vehiculo, cc.vin
        FROM contratos_credito cc
        JOIN productos p ON p.id_producto = cc.id_producto
        JOIN sucursales s ON s.id_sucursal = cc.id_sucursal
        WHERE cc.estado = 'firmado' AND cc.id_cliente IS NOT NULL
        ORDER BY cc.fecha_firma DESC, cc.id_contrato DESC
    ");
    foreach ($contratosStmt->fetchAll() as $k) {
        $contratosPorCliente[(int)$k['id_cliente']][] = [
            'id' => (int)$k['id_contrato'], 'folio' => $k['folio'], 'fecha' => $k['fecha'], 'sucursal' => $k['sucursal'],
            'vehiculo' => $k['vehiculo'], 'vin' => $k['vin'], 'ventaId' => $k['id_venta'] !== null ? (int)$k['id_venta'] : null,
            'plazo' => (int)$k['plazo_meses'], 'mensualidad' => (float)$k['mensualidad'], 'enganche' => (float)$k['enganche'],
            'estadoCredito' => $k['estado_credito'], 'abonosPagados' => (int)$k['abonos_pagados']
        ];
    }
    foreach ($clientes as &$cliente) {
        $cliente['contratos'] = $contratosPorCliente[$cliente['idCliente']] ?? [];
    }
    unset($cliente);

    // Respaldo del evento ev_garantias_vencidas (Database/garantias.sql): si el programador de eventos de MySQL estuviera
    // apagado, las garantías cuya fecha y hora de vencimiento ya llegó dejan de estar vigentes aquí también
    $pdo->exec("UPDATE garantias SET estado = 'vencida' WHERE estado = 'vigente' AND fecha_expiracion <= NOW()");

    // Garantías vigentes pendientes de atención, de la más próxima a vencer a la de mayor vigencia, con su última solicitud.
    // Las confirmadas por el gerente quedan 'aplicadas' y ya no aparecen; las denegadas siguen aquí con el motivo.
    $garantias = $pdo->query("
        SELECT
            g.id_garantia AS id,
            COALESCE(g.cliente_nombre, c.nombre) AS nombre,
            COALESCE(g.cliente_celular, c.celular) AS celular,
            COALESCE(g.cliente_email, c.email) AS email,
            p.nombre AS articulo,
            p.marca, p.modelo, p.anio, g.vin, g.id_venta AS ventaId, g.id_sucursal AS sucursalId,
            DATE_FORMAT(g.fecha_compra, '%d/%m/%Y %H:%i') AS compra,
            DATE_FORMAT(g.fecha_expiracion, '%d/%m/%Y') AS expira,
            DATE_FORMAT(g.fecha_expiracion, '%H:%i') AS expiraHora,
            DATE_FORMAT(g.fecha_expiracion, '%Y-%m-%dT%H:%i:%s') AS expiraIso,
            g.estado,
            s.folio AS solicitudFolio, s.estado AS solicitudEstado, s.motivo_rechazo AS motivoRechazo,
            DATE_FORMAT(s.fecha_solicitud, '%d/%m/%Y %H:%i') AS solicitudFecha
        FROM garantias g
        JOIN productos p ON p.id_producto = g.id_producto
        LEFT JOIN clientes c ON c.id_cliente = g.id_cliente
        LEFT JOIN solicitudes_garantia s ON s.id_solicitud = (
            SELECT MAX(s2.id_solicitud) FROM solicitudes_garantia s2 WHERE s2.id_garantia = g.id_garantia
        )
        WHERE g.estado = 'vigente' AND g.fecha_expiracion > NOW()
        ORDER BY g.fecha_expiracion ASC, g.id_garantia ASC
    ")->fetchAll();
    foreach ($garantias as &$garantia) {
        $garantia['id'] = (int)$garantia['id'];
        $garantia['ventaId'] = $garantia['ventaId'] !== null ? (int)$garantia['ventaId'] : null;
        // Folio de la venta (factura / contrato de compra-venta) para prellenar el formulario de garantía
        $garantia['folioVenta'] = $garantia['ventaId'] ? sprintf('KRM-%02d-%06d', (int)$garantia['sucursalId'], $garantia['ventaId']) : null;
        // Vencimiento con la zona del proyecto: la pantalla oculta la garantía en el instante exacto en que vence
        $garantia['expiraIso'] .= (new DateTimeImmutable('now'))->format('P');
    }
    unset($garantia);

    // Órdenes web pendientes que llegan del Catálogo (PHP/Catalogo) para ESTA sucursal + las de ejemplo sin sucursal.
    // Los pedidos de refacciones del Catálogo traen sus líneas en web_order_detalle (un carrito = varias piezas).
    $webStmt = $pdo->prepare("
        SELECT
            w.id_orden AS id,
            w.folio,
            w.tipo,
            w.nombre,
            w.celular,
            w.email,
            w.enganche,
            DATE_FORMAT(w.fecha_visita, '%d/%m/%Y · %H:%i') AS fechaVisita,
            DATE_FORMAT(w.fecha_creacion, '%d/%m/%Y · %H:%i') AS fechaCreacion,
            w.color,
            w.pieza,
            w.modelo_compatibilidad AS modelo,
            w.marca_vehiculo AS marcaVehiculo,
            w.motor,
            w.cilindraje,
            w.traccion,
            w.transmision,
            w.lado,
            w.metodo_entrega AS entrega,
            w.estado_pago AS estadoPago,
            w.total,
            w.stock_reservado AS stockReservado,
            w.comentarios,
            p.id_producto AS productoId,
            p.marca,
            p.modelo AS productoModelo,
            p.anio,
            p.nombre AS articulo
        FROM web_orders w
        LEFT JOIN productos p ON p.id_producto = w.id_producto
        WHERE w.estado = 'pendiente' AND (w.id_sucursal = ? OR w.id_sucursal IS NULL)
        ORDER BY COALESCE(w.fecha_visita, w.fecha_creacion), w.id_orden
    ");
    $webStmt->execute([$sucursal['id_sucursal']]);
    $webOrders = $webStmt->fetchAll();
    $idsOrdenes = array_column($webOrders, 'id');
    $lineasOrden = [];
    if ($idsOrdenes) {
        $lin = $pdo->prepare("
            SELECT d.id_orden, d.id_producto, d.cantidad, d.precio_unitario, d.subtotal_linea,
                   COALESCE(d.descripcion, p.nombre) AS descripcion, p.marca, p.codigo_barras
            FROM web_order_detalle d JOIN productos p ON p.id_producto = d.id_producto
            WHERE d.id_orden IN (" . implode(',', array_fill(0, count($idsOrdenes), '?')) . ")
            ORDER BY d.id_detalle
        ");
        $lin->execute($idsOrdenes);
        foreach ($lin->fetchAll() as $l) {
            $lineasOrden[(int)$l['id_orden']][] = [
                'productoId' => (int)$l['id_producto'], 'descripcion' => $l['descripcion'], 'marca' => $l['marca'],
                'codigo' => $l['codigo_barras'], 'cantidad' => (int)$l['cantidad'],
                'precio' => (float)$l['precio_unitario'], 'subtotal' => (float)$l['subtotal_linea']
            ];
        }
    }
    foreach ($webOrders as &$orden) {
        $orden['id'] = (int)$orden['id'];
        $orden['total'] = $orden['total'] !== null ? (float)$orden['total'] : null;
        $orden['stockReservado'] = (int)$orden['stockReservado'] === 1;
        $orden['lineas'] = $lineasOrden[$orden['id']] ?? [];
    }
    unset($orden);

    // Refacciones de la sucursal (con su acabado/color y modelo 3D para la vista previa)
    $refStmt = $pdo->prepare("
        SELECT
            p.id_producto AS id,
            p.codigo_barras AS codigo,
            p.nombre,
            p.tipo,
            p.precio_base AS precio,
            p.marca,
            p.modelo,
            p.anio,
            p.motor,
            p.traccion,
            p.lado,
            p.compatibilidad,
            p.color,
            p.color_hex AS colorHex,
            p.modelo_3d AS modelo3d,
            COALESCE(i.stock_actual, 0) AS unidades
        FROM productos p
        JOIN categorias c ON c.id_categoria=p.id_categoria
        LEFT JOIN inventarios i ON i.id_producto=p.id_producto AND i.id_sucursal=?
        WHERE c.nombre_categoria='Refacciones' AND p.tipo='refaccion'
        ORDER BY p.nombre
    ");
    $refStmt->execute([$sucursal['id_sucursal']]);
    $refacciones = $refStmt->fetchAll();

    // Respuesta final con los tipos numéricos corregidos
    ok([
        'usuario' => $usuario,
        'sucursal' => $sucursal,
        'caja' => $caja,
        'siguiente_ticket' => $siguienteTicket,
        'inventario' => array_map(function(array $r) {
            $r['id'] = (int)$r['id'];
            $r['anio'] = $r['anio'] !== null ? (int)$r['anio'] : null;
            $r['precio'] = (float)$r['precio'];
            $r['unidades'] = (int)$r['unidades'];
            $r['modelo3d'] = rutaModelo3D($r['id'], $r['modelo3d']);
            return $r;
        }, $inventarioRows),
        'clientes' => $clientes,
        'garantias' => $garantias,
        'weborders' => $webOrders,
        'refacciones' => array_map(function(array $r) {
            $r['id'] = (int)$r['id'];
            $r['precio'] = (float)$r['precio'];
            $r['unidades'] = (int)$r['unidades'];
            $r['modelo3d'] = rutaModelo3D($r['id'], $r['modelo3d']);
            return $r;
        }, $refacciones),
        // Catálogo de conceptos de caja con planes, unidades vendidas y accesorios (pestaña «Servicios»)
        'conceptos' => posCatalogoConceptosCaja($pdo, (int)$sucursal['id_sucursal'])
    ]);
}


/* Normaliza un VIN para compararlo (mayúsculas, sin espacios alrededor) */
function normalizarVin(string $vin): string {
    return strtoupper(trim($vin));
}

/* Revisa que el VIN elegido coincida con productos.vin del vehículo (las refacciones no llevan VIN) */
function verificarVinProducto(array $producto, string $vinCapturado): string {
    if (($producto['tipo'] ?? '') === 'refaccion') {
        return '';
    }
    $vinCapturado = normalizarVin($vinCapturado);
    if ($vinCapturado === '') {
        throw new RuntimeException('Elige el VIN de la unidad que vas a vender.');
    }
    $vinRegistrado = normalizarVin((string)($producto['vin'] ?? ''));
    if ($vinRegistrado === '') {
        throw new RuntimeException("{$producto['nombre']} todavía no tiene un VIN registrado en la base de datos, por lo que no se puede vender.");
    }
    if ($vinCapturado !== $vinRegistrado) {
        throw new RuntimeException('El VIN elegido no coincide con el VIN registrado de este vehículo. Verifícalo antes de continuar.');
    }
    return $vinRegistrado;
}

/* Validación en vivo del VIN desde la interfaz (antes de agregar el vehículo al ticket) */
function validarVin(): never {
    $data = jsonInput();
    $productoId = (int)($data['producto_id'] ?? 0);
    $vin = (string)($data['vin'] ?? '');
    if (!$productoId) fail('Producto no válido.');

    $stmt = db()->prepare("SELECT nombre, tipo, vin FROM productos WHERE id_producto=?");
    $stmt->execute([$productoId]);
    $producto = $stmt->fetch();
    if (!$producto) fail('El producto ya no existe en el catálogo.');

    try {
        $vinOficial = verificarVinProducto($producto, $vin);
    } catch (RuntimeException $e) {
        fail($e->getMessage());
    }
    ok(['valido' => true, 'vin' => $vinOficial !== '' ? $vinOficial : normalizarVin($vin)]);
}


/* Registra una venta y descuenta existencias dentro de una transacción.
   El ticket puede traer artículos (items), conceptos de caja (conceptos) o ambos: todo se cobra en la misma venta */
function crearVenta(): never {
    $data = jsonInput();
    $items = is_array($data['items'] ?? null) ? $data['items'] : [];
    $conceptos = is_array($data['conceptos'] ?? null) ? $data['conceptos'] : [];
    if (!$items && !$conceptos) {
        fail('El ticket está vacío.');
    }

    // Cajero y sucursal salen de la sesión del servidor (no se confía en los que mande el navegador)
    $cajero = $GLOBALS['cajeroSesion'];
    $idUsuario = (int)$cajero['id_usuario'];
    $idSucursal = (int)$cajero['id_sucursal'];
    $idCaja = (int)($data['id_caja'] ?? 0);
    $cajaValida = db()->prepare("SELECT COUNT(*) FROM cajas WHERE id_caja = ? AND id_sucursal = ?");
    $cajaValida->execute([$idCaja, $idSucursal]);
    if (!(int)$cajaValida->fetchColumn()) fail('La caja no pertenece a la sucursal del cajero.');
    $recibido = money((float)($data['efectivo_recibido'] ?? 0));
    $cambio = money((float)($data['cambio'] ?? 0));
    $ticketNumero = (int)($data['ticket_numero'] ?? 0);

    if (!$idUsuario || !$idSucursal || !$idCaja) fail('Faltan datos de sesión del cajero.');
    // Los créditos ya no se registran aquí: se concretan solo con el contrato firmado (preparar_credito → concretar_credito)
    if (!empty($data['credito'])) fail('Los créditos se concretan con la firma del contrato. Vuelve a presionar F3 para iniciar el flujo de crédito.');
    if ($recibido <= 0) fail('El dinero recibido debe ser mayor que cero.');

    $pdo = db();
    $pdo->beginTransaction();

    try {
        // Revisa cada artículo: existe, VIN correcto y stock suficiente
        [$productosVenta, $total] = posValidarArticulosVenta($pdo, $items, $idSucursal);

        // Conceptos de caja: el servidor recalcula cada importe con la parametrización de la BD y lo suma al total
        [$conceptosVenta, $totalConceptos] = posValidarConceptosCaja($pdo, $conceptos, $idSucursal, $productosVenta);
        $total = money($total + $totalConceptos);

        if ($recibido < $total) {
            throw new RuntimeException('El dinero recibido es menor al total de la venta.');
        }

        // El cambio se recalcula en el servidor para no confiar en el navegador
        $cambioCalculado = money($recibido - $total);
        if (abs($cambio - $cambioCalculado) > 0.01) {
            $cambio = $cambioCalculado;
        }

        // Las ventas de contado no se guardan en la tabla clientes (solo los créditos, al firmar su contrato)
        $clienteId = null;

        $metodo = $pdo->query("SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo='Efectivo' LIMIT 1")->fetchColumn();
        if (!$metodo) throw new RuntimeException('No existe el método de pago Efectivo.');

        // Encabezado de la venta + detalle de cada artículo + descuento de existencias
        $ventaId = posInsertarVenta($pdo, [
            'id_sucursal' => $idSucursal, 'id_usuario' => $idUsuario, 'id_caja' => $idCaja, 'id_metodo_pago' => (int)$metodo,
            'id_cliente' => $clienteId, 'total' => $total, 'recibido' => $recibido, 'cambio' => $cambio, 'ticket_numero' => $ticketNumero
        ], $productosVenta);

        // Desglose e historial de los conceptos cobrados (ventas_conceptos) con sus líneas en detalle_ventas
        $foliosConceptos = posRegistrarConceptosVenta($pdo, $ventaId, $conceptosVenta, [
            'id_sucursal' => $idSucursal, 'id_usuario' => $idUsuario, 'id_caja' => $idCaja
        ]);

        // Órdenes web que se atendieron con esta venta (botón "Continuar" de Web orders)
        posMarcarOrdenesWeb($pdo, (array)($data['ordenes_web'] ?? []), $ventaId, $idSucursal);

        // Garantía de 4 años por cada vehículo vendido (sección Garantías)
        posRegistrarGarantias($pdo, $ventaId, $idSucursal, $productosVenta, [
            'nombre' => trim((string)($data['cliente'] ?? '')), 'celular' => trim((string)($data['celular'] ?? '')),
            'email' => trim((string)($data['email'] ?? ''))
        ], null);

        // Fecha y hora con que quedó registrada la venta (ventas.fecha_hora): es la que se imprime en el ticket y en el PDF
        $fechaStmt = $pdo->prepare("SELECT DATE_FORMAT(fecha_hora, '%d/%m/%Y %H:%i:%s') FROM ventas WHERE id_venta = ?");
        $fechaStmt->execute([$ventaId]);
        $fechaVenta = (string)$fechaStmt->fetchColumn();

        $pdo->commit();

        ok([
            'venta_id' => $ventaId,
            'fecha' => $fechaVenta,
            'total' => $total,
            'cambio' => $cambio,
            'folio' => sprintf('KRM-%02d-%06d', $idSucursal, $ventaId),
            'conceptos' => $foliosConceptos
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
}

/* ===== Piezas compartidas por la venta de contado (crearVenta) y el crédito con contrato (contrato_credito.php) ===== */

/* Revisa cada artículo dentro de la transacción (bloquea producto e inventario): existe, VIN correcto y stock suficiente.
   Regresa [líneas de la venta con el precio de la BD, total de esas líneas] */

function posValidarArticulosVenta(PDO $pdo, array $items, int $idSucursal): array {
    $total = 0.0;
    $productosVenta = [];

    foreach ($items as $item) {
        $productoId = (int)($item['producto_id'] ?? 0);
        $cantidad = max(1, (int)($item['cantidad'] ?? 1));
        $vin = trim((string)($item['vin'] ?? ''));
        $motorSerie = trim((string)($item['motor_serie'] ?? ''));
        $colorInterior = trim((string)($item['color_interior'] ?? ''));

        if (!$productoId) {
            throw new RuntimeException('Hay un artículo sin producto asociado.');
        }

        $prodStmt = $pdo->prepare("
            SELECT id_producto, precio_base, nombre, tipo, vin
            FROM productos
            WHERE id_producto = ?
            FOR UPDATE
        ");
        $prodStmt->execute([$productoId]);
        $producto = $prodStmt->fetch();

        if (!$producto) {
            throw new RuntimeException('Uno de los productos ya no está disponible.');
        }

        $tipo = strtolower(trim((string)$producto['tipo']));
        $esServicio = ($tipo === 'servicio');

        // Los servicios no representan artículos físicos del inventario.
        if (!$esServicio) {
            $vinOficial = verificarVinProducto($producto, $vin);

            if ($vinOficial !== '') {
                $vin = $vinOficial;
            }

            $stockStmt = $pdo->prepare("
                SELECT stock_actual
                FROM inventarios
                WHERE id_producto = ? AND id_sucursal = ?
                FOR UPDATE
            ");
            $stockStmt->execute([$productoId, $idSucursal]);
            $stockActual = $stockStmt->fetchColumn();

            if ($stockActual === false || (int)$stockActual < $cantidad) {
                throw new RuntimeException(
                    "Stock insuficiente para {$producto['nombre']}."
                );
            }
        } else {
            // Un servicio no debe llevar datos propios de un vehículo.
            $vin = '';
            $motorSerie = '';
            $colorInterior = '';
        }

        // El precio proviene de la base de datos, no del navegador.
        $precio = money((float)$producto['precio_base']);
        $linea = money($precio * $cantidad);
        $total += $linea;

        $productosVenta[] = [
            'id' => $productoId,
            'tipo' => $tipo,
            'descontar_stock' => !$esServicio,
            'cantidad' => $cantidad,
            'precio' => $precio,
            'subtotal' => $linea,
            'vin' => $vin,
            'motor_serie' => $motorSerie,
            'color_interior' => $colorInterior
        ];
    }

    return [$productosVenta, money($total)];
}


/* Inserta el encabezado de la venta, el detalle de cada artículo y descuenta las existencias. Regresa el id de la venta */

function posInsertarVenta(PDO $pdo, array $v, array $productosVenta): int {
    $venta = $pdo->prepare("
        INSERT INTO ventas
        (id_sucursal, id_usuario, id_caja, id_metodo_pago, id_cliente,
         subtotal, total, efectivo_recibido, cambio, ticket_numero)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $venta->execute([
        $v['id_sucursal'],
        $v['id_usuario'],
        $v['id_caja'],
        $v['id_metodo_pago'],
        $v['id_cliente'],
        $v['total'],
        $v['total'],
        $v['recibido'],
        $v['cambio'],
        $v['ticket_numero']
    ]);

    $ventaId = (int)$pdo->lastInsertId();

    $detalle = $pdo->prepare("
        INSERT INTO detalle_ventas
        (id_venta, id_producto, cantidad, precio_unitario,
         subtotal_linea, vin, motor_serie, color_interior)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $stock = $pdo->prepare("
        UPDATE inventarios
        SET stock_actual = stock_actual - ?
        WHERE id_producto = ? AND id_sucursal = ?
          AND stock_actual >= ?
    ");

    foreach ($productosVenta as $p) {
        $detalle->execute([
            $ventaId,
            $p['id'],
            $p['cantidad'],
            $p['precio'],
            $p['subtotal'],
            $p['vin'] ?: null,
            $p['motor_serie'] ?: null,
            $p['color_interior'] ?: null
        ]);

        // Los servicios se registran en el detalle, pero no consumen stock.
        if (!empty($p['descontar_stock'])) {
            $stock->execute([
                $p['cantidad'],
                $p['id'],
                $v['id_sucursal'],
                $p['cantidad']
            ]);

            if ($stock->rowCount() !== 1) {
                throw new RuntimeException(
                    'El inventario cambió durante la venta. Verifica las existencias e inténtalo nuevamente.'
                );
            }
        }
    }

    return $ventaId;
}

/* Órdenes web que se atendieron con esta venta (botón "Continuar" de Web orders): quedan cobradas y ligadas a la venta.
   Solo las que NO apartaron inventario (las que sí lo apartaron se cobran con "Cobrar" para no descontar dos veces). */
function posMarcarOrdenesWeb(PDO $pdo, array $ordenes, int $ventaId, int $idSucursal): void {
    $ordenesWeb = array_values(array_unique(array_filter(array_map('intval', $ordenes))));
    if (!$ordenesWeb) return;
    $marcar = $pdo->prepare("
        UPDATE web_orders SET estado = 'atendida', estado_pago = 'pagado', id_venta = ?, fecha_pago = NOW()
        WHERE id_orden = ? AND estado = 'pendiente' AND stock_reservado = 0 AND (id_sucursal = ? OR id_sucursal IS NULL)
    ");
    $citaCompletada = $pdo->prepare("UPDATE citas SET estado = 'completada' WHERE id_orden = ? AND estado IN ('programada', 'confirmada')");
    foreach ($ordenesWeb as $idOrdenWeb) {
        $marcar->execute([$ventaId, $idOrdenWeb, $idSucursal]);
        if ($marcar->rowCount()) {
            $citaCompletada->execute([$idOrdenWeb]);
            notificarClienteOrden($pdo, $idOrdenWeb, 'Tu visita fue atendida', 'Gracias por tu compra en KARMA. Tu orden web quedó atendida en caja.');
        }
    }
}

/* Garantía KARMA de 4 años para cada vehículo (auto o moto) de una venta, sin importar la marca ni el método de pago.
   La compra y el vencimiento salen de ventas.fecha_hora (el momento real en que se concretó), con la misma hora exacta.
   $idCliente: cliente de la sección Clientes (créditos); en contado se liga solo si el correo ya pertenece a un cliente. */
function posRegistrarGarantias(PDO $pdo, int $ventaId, int $idSucursal, array $lineas, array $comprador, ?int $idCliente): void {
    $tipo = $pdo->prepare("SELECT tipo FROM productos WHERE id_producto = ?");
    $vehiculos = array_values(array_filter($lineas, function (array $l) use ($tipo): bool {
        $tipo->execute([(int)$l['id']]);
        return in_array($tipo->fetchColumn(), ['auto', 'moto'], true);
    }));
    if (!$vehiculos) return;

    $email = trim((string)($comprador['email'] ?? ''));
    if ($idCliente === null && $email !== '') {
        $find = $pdo->prepare("SELECT id_cliente FROM clientes WHERE email = ? LIMIT 1");
        $find->execute([$email]);
        $idCliente = ($id = $find->fetchColumn()) ? (int)$id : null;
    }

    $ins = $pdo->prepare("
        INSERT INTO garantias
        (id_cliente, id_producto, id_venta, id_sucursal, vin, cliente_nombre, cliente_celular, cliente_email, fecha_compra, fecha_expiracion, estado)
        SELECT ?, ?, v.id_venta, ?, ?, ?, ?, ?, v.fecha_hora, v.fecha_hora + INTERVAL 4 YEAR, 'vigente'
        FROM ventas v WHERE v.id_venta = ?
    ");
    foreach ($vehiculos as $l) {
        $ins->execute([
            $idCliente, (int)$l['id'], $idSucursal, trim((string)($l['vin'] ?? '')) ?: null,
            trim((string)($comprador['nombre'] ?? '')) ?: null, trim((string)($comprador['celular'] ?? '')) ?: null, $email ?: null,
            $ventaId
        ]);
    }
}

/* Registra o actualiza al cliente con crédito en la tabla clientes (sección Clientes). Regresa su id.
   Busca al cliente por email y, si no, por nombre + celular; un crédito nuevo reemplaza los datos del anterior
   en la ficha del cliente (cada crédito conserva su propio contrato en contratos_credito). */
function posGuardarClienteCredito(PDO $pdo, array $c, array $credito): int {
    $clienteId = null;
    if ($c['email'] !== '') {
        $find = $pdo->prepare("SELECT id_cliente FROM clientes WHERE email=? LIMIT 1");
        $find->execute([$c['email']]);
        $clienteId = $find->fetchColumn() ?: null;
    }
    if (!$clienteId) {
        $find = $pdo->prepare("SELECT id_cliente FROM clientes WHERE nombre=? AND COALESCE(celular,'')=? LIMIT 1");
        $find->execute([$c['nombre'], $c['celular']]);
        $clienteId = $find->fetchColumn() ?: null;
    }

    if ($clienteId) {
        $up = $pdo->prepare("
            UPDATE clientes
            SET nombre=?, rfc_ine=?, celular=COALESCE(NULLIF(?,''), celular), email=COALESCE(NULLIF(?,''), email),
                direccion=COALESCE(NULLIF(?,''), direccion),
                identificacion_tipo=COALESCE(NULLIF(?,''), identificacion_tipo),
                identificacion_numero=COALESCE(NULLIF(?,''), identificacion_numero),
                articulo=?, total_adeudo=?, monto_abono=?, enganche=?,
                abonos_pagados=0, abonos_totales=?, estado='activo'
            WHERE id_cliente=?
        ");
        $up->execute([
            $c['nombre'], $c['rfc_curp'] ?: null, $c['celular'], $c['email'],
            $c['direccion'], $c['identificacion_tipo'], $c['identificacion_numero'],
            $credito['articulo'], $credito['total_adeudo'], $credito['monto_abono'], $credito['enganche'], $credito['abonos_totales'],
            $clienteId
        ]);
        return (int)$clienteId;
    }

    $ins = $pdo->prepare("
        INSERT INTO clientes
        (nombre,rfc_ine,celular,email,direccion,identificacion_tipo,identificacion_numero,articulo,total_adeudo,monto_abono,enganche,abonos_pagados,abonos_totales,estado)
        VALUES(?,?,?,?,?,?,?,?,?,?,?,0,?, 'activo')
    ");
    $ins->execute([
        $c['nombre'], $c['rfc_curp'] ?: null, $c['celular'] ?: null, $c['email'] ?: null,
        $c['direccion'] ?: null, $c['identificacion_tipo'] ?: null, $c['identificacion_numero'] ?: null,
        $credito['articulo'], $credito['total_adeudo'], $credito['monto_abono'], $credito['enganche'], $credito['abonos_totales']
    ]);
    return (int)$pdo->lastInsertId();
}

/* API BREVO: valida los datos y envía el ticket en PDF al correo del cliente (lógica en correo.php) */
function enviarTicket(): never {
    $data = jsonInput();
    $email = trim((string)($data['email'] ?? ''));
    $nombre = trim((string)($data['nombre'] ?? ''));
    $ticket = $data['ticket'] ?? null;

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('Ingresa un correo electrónico válido.');
    }
    if (!$nombre || !$ticket) {
        fail('Faltan datos del cliente o del ticket.');
    }

    // Crédito: además del ticket se adjunta el contrato firmado (solo si pertenece a la venta de ese mismo ticket)
    $adjuntos = [];
    $idContrato = (int)($data['id_contrato'] ?? 0);
    if ($idContrato) {
        $stmt = db()->prepare("SELECT folio, pdf FROM contratos_credito WHERE id_contrato = ? AND estado = 'firmado' AND id_venta = ? AND pdf IS NOT NULL");
        $stmt->execute([$idContrato, (int)(is_array($ticket) ? ($ticket['ventaId'] ?? 0) : 0)]);
        $contrato = $stmt->fetch();
        if (!$contrato) fail('No se encontró el contrato firmado de esta venta.');
        $adjuntos[] = [
            'name' => 'contrato-credito-' . preg_replace('/[^A-Za-z0-9\-]/', '', (string)$contrato['folio']) . '.pdf',
            'content' => base64_encode((string)$contrato['pdf'])
        ];
    }

    require_once __DIR__ . '/correo.php';
    $resultado = enviarTicketPorCorreo($email, $nombre, $ticket, $adjuntos);

    if (!$resultado['ok']) {
        fail($resultado['message'], 503);
    }

    ok(['message' => $resultado['message']]);
}

/* ===== ÓRDENES WEB DEL CATÁLOGO ===== */

/* Avisa al cliente del Catálogo (tabla notificaciones) que su orden cambió de estado */
function notificarClienteOrden(PDO $pdo, int $idOrden, string $titulo, string $mensaje): void {
    $pdo->prepare("
        INSERT INTO notificaciones (id_cliente, tipo, titulo, mensaje, enlace)
        SELECT id_cliente, 'pedido', ?, ?, CONCAT('pedido.php?id=', id_orden) FROM web_orders WHERE id_orden = ? AND id_cliente IS NOT NULL
    ")->execute([$titulo, $mensaje, $idOrden]);
}

/* Cobra en caja un pedido del Catálogo (recoger en sucursal + efectivo): registra la venta y deja la orden atendida.
   Las piezas ya se apartaron del inventario de ESTA sucursal al crear el pedido (stock_reservado = 1),
   por eso aquí NO se vuelve a descontar. Si una orden no apartó inventario, se valida y descuenta ahora. */
function cobrarOrdenWeb(): never {
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idOrden = (int)($data['id_orden'] ?? 0);
    $recibido = money((float)($data['efectivo_recibido'] ?? 0));
    $ticketNumero = (int)($data['ticket_numero'] ?? 0);
    $idSucursal = (int)$cajero['id_sucursal'];
    if (!$idOrden) fail('Orden no válida.');

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT * FROM web_orders WHERE id_orden = ? FOR UPDATE");
        $stmt->execute([$idOrden]);
        $orden = $stmt->fetch();
        if (!$orden) throw new RuntimeException('La orden ya no existe.');
        if ((int)$orden['id_sucursal'] !== $idSucursal) throw new RuntimeException('Esta orden pertenece a otra sucursal.');
        if ($orden['estado'] !== 'pendiente' || $orden['estado_pago'] !== 'pendiente') throw new RuntimeException('Esta orden ya fue cobrada o cancelada.');

        $lin = $pdo->prepare("SELECT d.id_producto, d.cantidad, d.precio_unitario, d.subtotal_linea, COALESCE(d.descripcion, p.nombre) AS descripcion
                              FROM web_order_detalle d JOIN productos p ON p.id_producto = d.id_producto WHERE d.id_orden = ? ORDER BY d.id_detalle");
        $lin->execute([$idOrden]);
        $lineas = $lin->fetchAll();
        if (!$lineas) throw new RuntimeException('La orden no tiene artículos para cobrar. Usa "Continuar" para capturarla en Venta.');

        $total = money(array_sum(array_map(fn($l) => (float)$l['subtotal_linea'], $lineas)) + (float)$orden['costo_envio']);
        if ($recibido < $total) throw new RuntimeException('El dinero recibido es menor al total de la orden.');
        $cambio = money($recibido - $total);

        $cajaStmt = $pdo->prepare("SELECT id_caja FROM cajas WHERE id_sucursal = ? AND numero_caja = 1 LIMIT 1");
        $cajaStmt->execute([$idSucursal]);
        $idCaja = (int)$cajaStmt->fetchColumn();
        if (!$idCaja) throw new RuntimeException('No existe la caja 01 de esta sucursal.');
        $metodo = (int)$pdo->query("SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo = 'Efectivo' LIMIT 1")->fetchColumn();
        if (!$metodo) throw new RuntimeException('No existe el método de pago Efectivo.');

        // Respaldo: si la orden no apartó inventario, se valida y descuenta aquí (solo en esta sucursal)
        if ((int)$orden['stock_reservado'] !== 1) {
            $ver = $pdo->prepare("SELECT stock_actual FROM inventarios WHERE id_producto = ? AND id_sucursal = ? FOR UPDATE");
            $baja = $pdo->prepare("UPDATE inventarios SET stock_actual = stock_actual - ? WHERE id_producto = ? AND id_sucursal = ?");
            foreach ($lineas as $l) {
                $ver->execute([$l['id_producto'], $idSucursal]);
                $existencia = $ver->fetchColumn();
                if ($existencia === false || (int)$existencia < (int)$l['cantidad']) throw new RuntimeException("Stock insuficiente para {$l['descripcion']}.");
                $baja->execute([$l['cantidad'], $l['id_producto'], $idSucursal]);
            }
        }

        $venta = $pdo->prepare("INSERT INTO ventas (id_sucursal, id_usuario, id_caja, id_metodo_pago, id_cliente, subtotal, total, efectivo_recibido, cambio, ticket_numero)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $venta->execute([$idSucursal, (int)$cajero['id_usuario'], $idCaja, $metodo, $orden['id_cliente'] ?: null, $total, $total, $recibido, $cambio, $ticketNumero]);
        $ventaId = (int)$pdo->lastInsertId();

        $det = $pdo->prepare("INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal_linea) VALUES (?, ?, ?, ?, ?)");
        foreach ($lineas as $l) $det->execute([$ventaId, $l['id_producto'], $l['cantidad'], $l['precio_unitario'], $l['subtotal_linea']]);
        posRegistrarGarantias($pdo, $ventaId, $idSucursal, array_map(fn($l) => ['id' => (int)$l['id_producto'], 'vin' => ''], $lineas),
            ['nombre' => (string)$orden['nombre'], 'celular' => (string)($orden['celular'] ?? ''), 'email' => (string)($orden['email'] ?? '')],
            $orden['id_cliente'] ? (int)$orden['id_cliente'] : null);

        $pdo->prepare("UPDATE web_orders SET estado = 'atendida', estado_pago = 'pagado', id_venta = ?, fecha_pago = NOW(), id_metodo_pago = ? WHERE id_orden = ?")
            ->execute([$ventaId, $metodo, $idOrden]);
        notificarClienteOrden($pdo, $idOrden, "Pedido {$orden['folio']} pagado en caja", 'Recibimos tu pago en efectivo. ¡Gracias por tu compra en KARMA!');
        $fecha = $pdo->query("SELECT DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i:%s')")->fetchColumn();
        $pdo->commit();

        ok([
            'venta_id' => $ventaId,
            'folio' => sprintf('KRM-%02d-%06d', $idSucursal, $ventaId),
            'folio_orden' => $orden['folio'],
            'fecha' => $fecha,
            'total' => $total,
            'cambio' => $cambio,
            'lineas' => array_map(fn($l) => ['descripcion' => $l['descripcion'], 'cantidad' => (int)$l['cantidad'], 'subtotal' => (float)$l['subtotal_linea']], $lineas)
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
}

/* Cancela una orden web pendiente (por ejemplo, el cliente no se presentó). Si la orden había apartado piezas,
   regresan al inventario de ESTA sucursal. La cita ligada (visita/apartado) también se cancela. */
function cancelarOrdenWeb(): never {
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idOrden = (int)($data['id_orden'] ?? 0);
    $idSucursal = (int)$cajero['id_sucursal'];
    if (!$idOrden) fail('Orden no válida.');

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT id_orden, folio, id_sucursal, estado, estado_pago, stock_reservado FROM web_orders WHERE id_orden = ? FOR UPDATE");
        $stmt->execute([$idOrden]);
        $orden = $stmt->fetch();
        if (!$orden) throw new RuntimeException('La orden ya no existe.');
        if ($orden['id_sucursal'] !== null && (int)$orden['id_sucursal'] !== $idSucursal) throw new RuntimeException('Esta orden pertenece a otra sucursal.');
        if ($orden['estado'] !== 'pendiente') throw new RuntimeException('Solo se pueden cancelar órdenes pendientes.');

        if ((int)$orden['stock_reservado'] === 1 && $orden['estado_pago'] === 'pendiente') {
            $pdo->prepare("UPDATE inventarios i JOIN web_order_detalle d ON d.id_producto = i.id_producto AND d.id_orden = ?
                           SET i.stock_actual = i.stock_actual + d.cantidad WHERE i.id_sucursal = ?")
                ->execute([$idOrden, (int)$orden['id_sucursal']]);
        }
        $pdo->prepare("UPDATE web_orders SET estado = 'cancelada', stock_reservado = 0 WHERE id_orden = ?")->execute([$idOrden]);
        $pdo->prepare("UPDATE citas SET estado = 'cancelada' WHERE id_orden = ? AND estado IN ('programada', 'confirmada')")->execute([$idOrden]);
        notificarClienteOrden($pdo, $idOrden, 'Orden ' . ($orden['folio'] ?: "#{$idOrden}") . ' cancelada por la sucursal',
            'Si tienes dudas comunícate con la sucursal. Las piezas apartadas regresaron al inventario.');
        $pdo->commit();
        ok(['message' => 'Orden cancelada.']);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
}

/* ===== AUTORIZACIÓN DE EMPLEADO (gafete QR o código manual) ===== */

/* Recibe el código del gafete, la acción y su referencia; el servidor decide contra la BD (posAutorizarEmpleado) */
function autorizarEmpleado(): never {
    $r = posAutorizarEmpleado(db(), $GLOBALS['cajeroSesion'], jsonInput());
    if (!$r['ok']) fail($r['error'], $r['estado']);
    ok(['autorizado' => true, 'autorizacion' => $r['permiso'], 'vigencia' => $r['vigencia']]);
}

/* Solicitud de garantía: el cajero llena el formulario y la ENVÍA al gerente; queda 'pendiente' (el cajero no la aprueba).
   Solo llega aquí si el enrutador ya validó y consumió la autorización del gafete ligada a esta garantía.
   Confirmar o denegar lo hará el módulo del gerente (reglas en los triggers de Database/garantias.sql). */
function aplicarGarantia(): never {
    $data = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idGarantia = (int)($data['id_garantia'] ?? 0);
    $texto = fn(string $k, int $max): string => mb_substr(trim((string)($data['formulario'][$k] ?? '')), 0, $max);
    $form = [
        'propietario' => $texto('propietario', 150), 'contacto' => $texto('contacto', 200), 'vin' => strtoupper($texto('vin', 17)),
        'placa_anio' => $texto('placa_anio', 60), 'kilometraje' => $texto('kilometraje', 10), 'factura' => $texto('factura', 80),
        'historial_servicios' => $texto('historial_servicios', 200), 'fecha_falla' => $texto('fecha_falla', 20),
        'fecha_recepcion' => $texto('fecha_recepcion', 20), 'sintoma' => $texto('sintoma', 2000), 'condiciones' => $texto('condiciones', 2000),
        'evidencia' => $texto('evidencia', 500), 'asesor' => $texto('asesor', 150), 'conformidad_cliente' => $texto('conformidad_cliente', 150)
    ];
    if ($form['sintoma'] === '') fail('Describe el síntoma de la falla antes de enviar la solicitud.');
    if ($form['kilometraje'] !== '' && !ctype_digit($form['kilometraje'])) fail('El kilometraje debe ser un número entero.');

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT id_garantia, vin, estado, fecha_expiracion > NOW() AS vigente FROM garantias WHERE id_garantia = ? FOR UPDATE");
        $stmt->execute([$idGarantia]);
        $garantia = $stmt->fetch();
        if (!$garantia) throw new RuntimeException('La garantía ya no existe.');
        if ($garantia['estado'] !== 'vigente' || !(int)$garantia['vigente']) throw new RuntimeException('Esta garantía ya no está vigente.');
        if ($form['vin'] !== '' && $garantia['vin'] && $form['vin'] !== strtoupper((string)$garantia['vin'])) {
            throw new RuntimeException('El VIN no coincide con el vehículo de esta garantía.');
        }
        $pendiente = $pdo->prepare("SELECT folio FROM solicitudes_garantia WHERE id_garantia = ? AND estado = 'pendiente' LIMIT 1");
        $pendiente->execute([$idGarantia]);
        $folioPendiente = $pendiente->fetchColumn();
        if ($folioPendiente) {
            throw new RuntimeException("Esta garantía ya tiene la solicitud {$folioPendiente} pendiente de aprobación del gerente.");
        }

        $pdo->prepare("INSERT INTO solicitudes_garantia (id_garantia, id_sucursal, id_usuario_solicita, datos_json) VALUES (?, ?, ?, ?)")
            ->execute([$idGarantia, (int)$cajero['id_sucursal'], (int)$cajero['id_usuario'], json_encode($form, JSON_UNESCAPED_UNICODE)]);
        $idSolicitud = (int)$pdo->lastInsertId();
        $folio = sprintf('KRM-SG-%02d-%06d', (int)$cajero['id_sucursal'], $idSolicitud);
        $pdo->prepare("UPDATE solicitudes_garantia SET folio = ? WHERE id_solicitud = ?")->execute([$folio, $idSolicitud]);
        $pdo->commit();
    } catch (RuntimeException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        fail($e->getMessage(), 409);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    ok(['message' => "Solicitud {$folio} enviada al gerente. Queda pendiente de su aprobación.", 'folio' => $folio]);
}
?>
