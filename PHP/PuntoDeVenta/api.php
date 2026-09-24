<?php
declare(strict_types=1);

/* API principal del Punto de Venta */
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/conexion.php';

function jsonInput(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function ok(array $data = []): never {
    echo json_encode(['ok' => true] + $data, JSON_UNESCAPED_UNICODE);
    exit;
}

function fail(string $message, int $status = 400): never {
    http_response_code($status);
    echo json_encode(['ok' => false, 'error' => $message], JSON_UNESCAPED_UNICODE);
    exit;
}

function money(float $value): float {
    return round($value, 2);
}

try {
    $action = $_GET['action'] ?? '';
    switch ($action) {
        case 'bootstrap':
            bootstrap();
            break;
        case 'crear_venta':
            crearVenta();
            break;
        case 'enviar_ticket':
            enviarTicket();
            break;
        case 'logout':
            ok(['message' => 'Sesión cerrada.']);
            break;
        default:
            fail('Acción no reconocida.', 404);
    }
} catch (Throwable $e) {
    fail($e->getMessage(), 500);
}

/* Carga todos los catálogos que utiliza la interfaz */
function bootstrap(): never {
    $pdo = db();
    $usuario = $pdo->query("
        SELECT u.id_usuario, u.nombre, u.correo, u.id_sucursal
        FROM usuarios u
        JOIN roles r ON r.id_rol = u.id_rol
        WHERE r.nombre_rol = 'Cajero' AND u.estado = 'activo'
        ORDER BY u.id_usuario
        LIMIT 1
    ")->fetch();

    if (!$usuario) {
        fail('No existe un usuario activo con rol Cajero. Ejecuta Database/datos_prueba_cajero.txt.', 503);
    }

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

    /* Inventario disponible de la sucursal del cajero */
$inventario = $pdo->prepare("
    SELECT
        p.id_producto AS id,
        p.codigo_barras AS codigo,
        p.marca,
        p.modelo,
        p.anio,
        p.tipo,
        p.color,
        p.color_hex AS colorHex,
        p.motor,
        p.cilindraje,
        p.detalle,
        p.nombre,
        p.compatibilidad,
        p.precio_base AS precio,
        i.stock_actual AS unidades,
        c.nombre_categoria AS categoria
    FROM productos p
    JOIN inventarios i ON i.id_producto = p.id_producto
    JOIN categorias c ON c.id_categoria = p.id_categoria
    JOIN sucursales s ON s.id_sucursal = i.id_sucursal
    WHERE s.id_sucursal = ? AND i.stock_actual > 0
    ORDER BY p.marca, p.modelo, p.anio, p.nombre
");

$inventario->execute([$sucursal['id_sucursal']]);
$inventarioRows = $inventario->fetchAll(PDO::FETCH_ASSOC);

    $clientes = $pdo->query("
        SELECT id_cliente AS id, nombre, rfc_ine AS rfcIne, celular, email,
               articulo, total_adeudo AS totalAdeudo, monto_abono AS montoAbono,
               enganche, abonos_pagados AS abonosPagados, abonos_totales AS abonosTotales
        FROM clientes
        WHERE estado='activo'
        ORDER BY nombre
    ")->fetchAll();

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

    $webOrders = $pdo->query("
        SELECT
            w.id_orden AS id,
            w.tipo,
            w.nombre,
            w.celular,
            w.email,
            w.enganche,
            DATE_FORMAT(w.fecha_visita, '%d/%m/%Y · %H:%i') AS fechaVisita,
            w.color,
            w.pieza,
            w.modelo_compatibilidad AS modelo,
            w.marca_vehiculo AS marcaVehiculo,
            w.motor,
            w.cilindraje,
            w.traccion,
            w.transmision,
            w.lado,
            p.id_producto AS productoId,
            p.marca,
            p.modelo AS productoModelo,
            p.anio,
            p.nombre AS articulo
        FROM web_orders w
        LEFT JOIN productos p ON p.id_producto = w.id_producto
        WHERE w.estado='pendiente'
        ORDER BY w.fecha_visita, w.id_orden
    ")->fetchAll();

    $refStmt = $pdo->prepare("
        SELECT
            p.id_producto AS id,
            p.nombre,
            p.precio_base AS precio,
            p.modelo,
            p.compatibilidad,
            i.stock_actual AS unidades
        FROM productos p
        JOIN categorias c ON c.id_categoria=p.id_categoria
        JOIN inventarios i ON i.id_producto=p.id_producto AND i.id_sucursal=?
        WHERE c.nombre_categoria='Refacciones' AND p.tipo='refaccion' AND i.stock_actual > 0
        ORDER BY p.nombre
    ");
    $refStmt->execute([$sucursal['id_sucursal']]);
    $refacciones = $refStmt->fetchAll();

    ok([
        'usuario' => $usuario,
        'sucursal' => $sucursal,
        'caja' => $caja,
        'inventario' => array_map(function(array $r) {
            $r['id'] = (int)$r['id'];
            $r['anio'] = $r['anio'] !== null ? (int)$r['anio'] : null;
            $r['precio'] = (float)$r['precio'];
            $r['unidades'] = (int)$r['unidades'];
            return $r;
        }, $inventarioRows),
        'clientes' => $clientes,
        'garantias' => $garantias,
        'weborders' => $webOrders,
        'refacciones' => array_map(function(array $r) {
            $r['id'] = (int)$r['id'];
            $r['precio'] = (float)$r['precio'];
            $r['unidades'] = (int)$r['unidades'];
            return $r;
        }, $refacciones)
    ]);
}

/* Registra una venta y descuenta existencias dentro de una transacción */
function crearVenta(): never {
    $data = jsonInput();
    $items = $data['items'] ?? [];
    if (!$items || !is_array($items)) {
        fail('El ticket está vacío.');
    }

    $idUsuario = (int)($data['id_usuario'] ?? 0);
    $idSucursal = (int)($data['id_sucursal'] ?? 0);
    $idCaja = (int)($data['id_caja'] ?? 0);
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

        foreach ($items as $item) {
            $productoId = (int)($item['producto_id'] ?? 0);
            $cantidad = max(1, (int)($item['cantidad'] ?? 1));

            if (!$productoId) throw new RuntimeException('Hay un artículo sin producto asociado.');

            $stmt = $pdo->prepare("
                SELECT p.id_producto, p.precio_base, p.nombre, i.stock_actual
                FROM productos p
                JOIN inventarios i ON i.id_producto=p.id_producto
                WHERE p.id_producto=? AND i.id_sucursal=?
                FOR UPDATE
            ");
            $stmt->execute([$productoId, $idSucursal]);
            $producto = $stmt->fetch();

            if (!$producto) throw new RuntimeException('Uno de los productos ya no está disponible.');
            if ((int)$producto['stock_actual'] < $cantidad) {
                throw new RuntimeException("Stock insuficiente para {$producto['nombre']}.");
            }

            $precio = money((float)$producto['precio_base']);
            $linea = money($precio * $cantidad);
            $total += $linea;

            $productosVenta[] = [
                'id' => $productoId,
                'cantidad' => $cantidad,
                'precio' => $precio,
                'subtotal' => $linea
            ];
        }

        $total = money($total);

        if ($recibido < $total) {
            throw new RuntimeException('El dinero recibido es menor al total de la venta.');
        }

        $cambioCalculado = money($recibido - $total);
        if (abs($cambio - $cambioCalculado) > 0.01) {
            $cambio = $cambioCalculado;
        }

        $clienteId = null;
        $nombre = trim((string)($data['cliente'] ?? ''));
        $email = trim((string)($data['email'] ?? ''));
        $celular = trim((string)($data['celular'] ?? ''));
        $rfcIne = trim((string)($data['rfc_ine'] ?? ''));

        if ($nombre) {
            if ($email) {
                $find = $pdo->prepare("SELECT id_cliente FROM clientes WHERE email=? LIMIT 1");
                $find->execute([$email]);
                $clienteId = $find->fetchColumn() ?: null;
            }

            if ($clienteId) {
                $up = $pdo->prepare("
                    UPDATE clientes
                    SET nombre=?, rfc_ine=?, celular=?, email=?
                    WHERE id_cliente=?
                ");
                $up->execute([$nombre, $rfcIne ?: null, $celular ?: null, $email ?: null, $clienteId]);
            } else {
                $ins = $pdo->prepare("
                    INSERT INTO clientes(nombre,rfc_ine,celular,email,estado)
                    VALUES(?,?,?,?, 'activo')
                ");
                $ins->execute([$nombre, $rfcIne ?: null, $celular ?: null, $email ?: null]);
                $clienteId = (int)$pdo->lastInsertId();
            }
        }

        $metodo = $pdo->query("SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo='Efectivo' LIMIT 1")->fetchColumn();
        if (!$metodo) throw new RuntimeException('No existe el método de pago Efectivo.');

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

        $detalle = $pdo->prepare("
            INSERT INTO detalle_ventas
            (id_venta,id_producto,cantidad,precio_unitario,subtotal_linea)
            VALUES(?,?,?,?,?)
        ");
        $stock = $pdo->prepare("
            UPDATE inventarios
            SET stock_actual=stock_actual-?
            WHERE id_producto=? AND id_sucursal=?
        ");

        foreach ($productosVenta as $p) {
            $detalle->execute([$ventaId, $p['id'], $p['cantidad'], $p['precio'], $p['subtotal']]);
            $stock->execute([$p['cantidad'], $p['id'], $idSucursal]);
        }

        $pdo->commit();

        ok([
            'venta_id' => $ventaId,
            'fecha' => date('d/m/Y H:i:s'),
            'total' => $total,
            'cambio' => $cambio
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
}

/* Envía el ticket mediante Gmail cuando se instalen las dependencias */
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
    $resultado = enviarTicketGmail($email, $nombre, $ticket);

    if (!$resultado['ok']) {
        fail($resultado['message'], 503);
    }

    ok(['message' => $resultado['message']]);
}
?>