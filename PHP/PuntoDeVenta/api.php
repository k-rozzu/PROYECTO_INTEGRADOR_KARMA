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

    // Número del siguiente ticket = ventas de HOY en esta caja + 1 (así no se reinicia al recargar)
    $siguienteTicketStmt = $pdo->prepare("
        SELECT COUNT(*) FROM ventas WHERE id_caja = ? AND DATE(fecha_hora) = CURDATE()
    ");
    $siguienteTicketStmt->execute([$caja['id_caja']]);
    $siguienteTicket = (int)$siguienteTicketStmt->fetchColumn() + 1;

    // Inventario completo de la sucursal (incluye productos con 0 unidades, su VIN, color y modelo 3D)
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
        ORDER BY p.marca, p.modelo, p.anio, p.nombre
    ");
    $inventario->execute([$sucursal['id_sucursal']]);
    $inventarioRows = $inventario->fetchAll(PDO::FETCH_ASSOC);

    // Clientes con crédito activo
    $clientes = $pdo->query("
        SELECT id_cliente AS id, nombre, rfc_ine AS rfcIne, celular, email,
               direccion, identificacion_tipo AS identificacionTipo,
               articulo, total_adeudo AS totalAdeudo, monto_abono AS montoAbono,
               enganche, abonos_pagados AS abonosPagados, abonos_totales AS abonosTotales
        FROM clientes
        WHERE estado='activo' AND abonos_totales > 0
        ORDER BY nombre
    ")->fetchAll();

    // Garantías registradas, de la más lejana a la más próxima a vencer
    $garantias = $pdo->query("
        SELECT
            g.id_garantia AS id,
            c.nombre, c.celular,
            p.nombre AS articulo,
            p.marca, p.modelo, p.anio,
            DATE_FORMAT(g.fecha_expiracion, '%d/%m/%Y') AS expira,
            g.estado
        FROM garantias g
        JOIN clientes c ON c.id_cliente = g.id_cliente
        JOIN productos p ON p.id_producto = g.id_producto
        ORDER BY g.fecha_expiracion DESC
    ")->fetchAll();

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
        }, $refacciones)
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


/* Registra una venta y descuenta existencias dentro de una transacción */
function crearVenta(): never {
    $data = jsonInput();
    $items = $data['items'] ?? [];
    if (!$items || !is_array($items)) {
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
    if ($recibido <= 0) fail('El dinero recibido debe ser mayor que cero.');

    $pdo = db();
    $pdo->beginTransaction();

    try {
        $total = 0.0;
        $productosVenta = [];

        // Revisa cada artículo: existe, VIN correcto y stock suficiente
        foreach ($items as $item) {
            $productoId = (int)($item['producto_id'] ?? 0);
            $cantidad = max(1, (int)($item['cantidad'] ?? 1));
            $vin = trim((string)($item['vin'] ?? ''));
            $motorSerie = trim((string)($item['motor_serie'] ?? ''));
            $colorInterior = trim((string)($item['color_interior'] ?? ''));

            if (!$productoId) throw new RuntimeException('Hay un artículo sin producto asociado.');

            $prodStmt = $pdo->prepare("SELECT id_producto, precio_base, nombre, tipo, vin FROM productos WHERE id_producto=? FOR UPDATE");
            $prodStmt->execute([$productoId]);
            $producto = $prodStmt->fetch();
            if (!$producto) throw new RuntimeException('Uno de los productos ya no está disponible.');

            // Vehículos: el VIN se vuelve a revisar aquí por seguridad (las refacciones no llevan VIN)
            $vinOficial = verificarVinProducto($producto, $vin);
            if ($vinOficial !== '') $vin = $vinOficial;

            $stockStmt = $pdo->prepare("SELECT stock_actual FROM inventarios WHERE id_producto=? AND id_sucursal=? FOR UPDATE");
            $stockStmt->execute([$productoId, $idSucursal]);
            $stockActual = $stockStmt->fetchColumn();
            if ($stockActual === false || (int)$stockActual < $cantidad) {
                throw new RuntimeException("Stock insuficiente para {$producto['nombre']}.");
            }

            $precio = money((float)$producto['precio_base']);
            $linea = money($precio * $cantidad);
            $total += $linea;

            $productosVenta[] = [
                'id' => $productoId,
                'cantidad' => $cantidad,
                'precio' => $precio,
                'subtotal' => $linea,
                'vin' => $vin,
                'motor_serie' => $motorSerie,
                'color_interior' => $colorInterior
            ];
        }

        $total = money($total);

        if ($recibido < $total) {
            throw new RuntimeException('El dinero recibido es menor al total de la venta.');
        }

        // El cambio se recalcula en el servidor para no confiar en el navegador
        $cambioCalculado = money($recibido - $total);
        if (abs($cambio - $cambioCalculado) > 0.01) {
            $cambio = $cambioCalculado;
        }

        $clienteId = null;
        $nombre = trim((string)($data['cliente'] ?? ''));
        $email = trim((string)($data['email'] ?? ''));
        $celular = trim((string)($data['celular'] ?? ''));
        $rfcIne = trim((string)($data['rfc_ine'] ?? ''));
        $direccion = trim((string)($data['direccion'] ?? ''));
        $identificacionTipo = trim((string)($data['identificacion_tipo'] ?? ''));

        // Solo los clientes con CRÉDITO se guardan en la tabla clientes (las de contado quedan solo en ventas)
        $credito = (isset($data['credito']) && is_array($data['credito'])) ? $data['credito'] : null;

        if ($credito && $nombre) {
            $articuloCredito = trim((string)($credito['articulo'] ?? ''));
            $totalAdeudo = money((float)($credito['total_adeudo'] ?? 0));
            $montoAbono = money((float)($credito['monto_abono'] ?? 0));
            $engancheCredito = money((float)($credito['enganche'] ?? 0));
            $abonosTotales = max(0, (int)($credito['abonos_totales'] ?? 0));

            // Busca al cliente por email y, si no, por nombre + celular
            if ($email) {
                $find = $pdo->prepare("SELECT id_cliente FROM clientes WHERE email=? LIMIT 1");
                $find->execute([$email]);
                $clienteId = $find->fetchColumn() ?: null;
            }
            if (!$clienteId) {
                $find = $pdo->prepare("SELECT id_cliente FROM clientes WHERE nombre=? AND COALESCE(celular,'')=? LIMIT 1");
                $find->execute([$nombre, $celular]);
                $clienteId = $find->fetchColumn() ?: null;
            }

            if ($clienteId) {
                // Cliente existente: un crédito nuevo reemplaza al anterior (un crédito por cliente)
                $up = $pdo->prepare("
                    UPDATE clientes
                    SET nombre=?, rfc_ine=?, celular=?, email=?,
                        direccion=COALESCE(NULLIF(?,''), direccion),
                        identificacion_tipo=COALESCE(NULLIF(?,''), identificacion_tipo),
                        articulo=?, total_adeudo=?, monto_abono=?, enganche=?,
                        abonos_pagados=0, abonos_totales=?, estado='activo'
                    WHERE id_cliente=?
                ");
                $up->execute([
                    $nombre, $rfcIne ?: null, $celular ?: null, $email ?: null,
                    $direccion, $identificacionTipo,
                    $articuloCredito ?: null, $totalAdeudo, $montoAbono, $engancheCredito, $abonosTotales,
                    $clienteId
                ]);
            } else {
                // Cliente nuevo con crédito
                $ins = $pdo->prepare("
                    INSERT INTO clientes
                    (nombre,rfc_ine,celular,email,direccion,identificacion_tipo,articulo,total_adeudo,monto_abono,enganche,abonos_pagados,abonos_totales,estado)
                    VALUES(?,?,?,?,?,?,?,?,?,?,0,?, 'activo')
                ");
                $ins->execute([
                    $nombre, $rfcIne ?: null, $celular ?: null, $email ?: null,
                    $direccion ?: null, $identificacionTipo ?: null,
                    $articuloCredito ?: null, $totalAdeudo, $montoAbono, $engancheCredito, $abonosTotales
                ]);
                $clienteId = (int)$pdo->lastInsertId();
            }
        }

        $metodo = $pdo->query("SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo='Efectivo' LIMIT 1")->fetchColumn();
        if (!$metodo) throw new RuntimeException('No existe el método de pago Efectivo.');

        // Encabezado de la venta
        $venta = $pdo->prepare("
            INSERT INTO ventas
            (id_sucursal,id_usuario,id_caja,id_metodo_pago,id_cliente,subtotal,total,efectivo_recibido,cambio,ticket_numero)
            VALUES(?,?,?,?,?,?,?,?,?,?)
        ");
        $venta->execute([
            $idSucursal, $idUsuario, $idCaja, $metodo, $clienteId,
            $total, $total, $recibido, $cambio, $ticketNumero
        ]);
        $ventaId = (int)$pdo->lastInsertId();

        // Detalle de cada artículo + descuento de existencias
        $detalle = $pdo->prepare("
            INSERT INTO detalle_ventas
            (id_venta,id_producto,cantidad,precio_unitario,subtotal_linea,vin,motor_serie,color_interior)
            VALUES(?,?,?,?,?,?,?,?)
        ");
        $stock = $pdo->prepare("
            UPDATE inventarios
            SET stock_actual=stock_actual-?
            WHERE id_producto=? AND id_sucursal=?
        ");

        foreach ($productosVenta as $p) {
            $detalle->execute([
                $ventaId, $p['id'], $p['cantidad'], $p['precio'], $p['subtotal'],
                $p['vin'] ?: null, $p['motor_serie'] ?: null, $p['color_interior'] ?: null
            ]);
            $stock->execute([$p['cantidad'], $p['id'], $idSucursal]);
        }

        // Órdenes web que se atendieron con esta venta (botón "Continuar" de Web orders): quedan cobradas y ligadas a la venta.
        // Solo las que NO apartaron inventario (las que sí lo apartaron se cobran con "Cobrar" para no descontar dos veces).
        $ordenesWeb = array_values(array_unique(array_filter(array_map('intval', (array)($data['ordenes_web'] ?? [])))));
        if ($ordenesWeb) {
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

        $pdo->commit();

        ok([
            'venta_id' => $ventaId,
            'fecha' => date('d/m/Y H:i:s'),
            'total' => $total,
            'cambio' => $cambio,
            'folio' => sprintf('KRM-%02d-%06d', $idSucursal, $ventaId)
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
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

    require_once __DIR__ . '/correo.php';
    $resultado = enviarTicketPorCorreo($email, $nombre, $ticket);

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

/* Aplicar garantía: el formulario actual no guarda datos en la BD (se llena en pantalla), así que este paso no cambia ninguna tabla.
   Solo llega aquí si el enrutador ya validó y consumió la autorización del empleado (queda registrada en la auditoría). */
function aplicarGarantia(): never {
    $stmt = db()->prepare("SELECT id_garantia FROM garantias WHERE id_garantia = ?");
    $stmt->execute([(int)(jsonInput()['id_garantia'] ?? 0)]);
    if (!$stmt->fetchColumn()) fail('La garantía ya no existe.', 404);
    ok(['message' => 'Garantía autorizada.']);
}
?>
