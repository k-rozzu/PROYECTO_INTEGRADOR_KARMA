<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — datos de la CUENTA del cliente (perfil, pedidos, citas, historial).
   Reutiliza tablas existentes del POS: web_orders, ventas/detalle_ventas (compras en sucursal),
   garantias y la información de crédito guardada en clientes.
   ===================================================================================== */

require_once __DIR__ . '/datos.php';

// Estado del pedido tal como lo ve el cliente (combina estado del cajero + estado de pago + entrega)
function catEtiquetaPedido(array $o): array {
    if ($o['estado'] === 'cancelada') return ['cancelado', 'Cancelado'];
    if ($o['estado_pago'] === 'reembolsado') return ['cancelado', 'Reembolsado'];
    if ($o['metodo_entrega'] === 'envio') {
        return $o['estado_pago'] === 'pagado' ? ['pagado', 'Pagado · En preparación para envío'] : ['pendiente', 'Pago pendiente'];
    }
    if ($o['estado_pago'] === 'pagado' || $o['estado'] === 'atendida') return ['pagado', 'Pagado y entregado en sucursal'];
    return ['pendiente', 'Pendiente de pago en sucursal'];
}

// Pedidos de refacciones/accesorios del cliente con sus líneas
function catPedidosCliente(int $idCliente, ?int $idOrden = null): array {
    $sql = "SELECT w.id_orden, w.folio, w.estado, w.estado_pago, w.metodo_entrega, w.subtotal, w.costo_envio, w.total,
                   w.direccion_envio, w.tarjeta_marca, w.tarjeta_ultimos4, w.referencia_pago, w.comentarios,
                   w.fecha_creacion, w.fecha_pago, w.nombre, w.celular, w.email, w.id_venta,
                   s.nombre AS sucursal, s.direccion AS sucursal_direccion, s.telefono AS sucursal_telefono,
                   mp.nombre_metodo
              FROM web_orders w
              LEFT JOIN sucursales s ON s.id_sucursal = w.id_sucursal
              LEFT JOIN metodos_pago mp ON mp.id_metodo_pago = w.id_metodo_pago
             WHERE w.id_cliente = ? AND w.tipo = 'refaccion' AND w.folio IS NOT NULL";
    $params = [$idCliente];
    if ($idOrden) { $sql .= ' AND w.id_orden = ?'; $params[] = $idOrden; }
    $stmt = db()->prepare($sql . ' ORDER BY w.id_orden DESC');
    $stmt->execute($params);
    $pedidos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!$pedidos) return [];

    // Líneas de todos los pedidos en una sola consulta
    $ids = array_column($pedidos, 'id_orden');
    $lin = db()->prepare("
        SELECT d.id_orden, d.id_producto, d.cantidad, d.precio_unitario, d.subtotal_linea,
               COALESCE(d.descripcion, p.nombre) AS descripcion, p.marca, p.codigo_barras, pw.imagen
          FROM web_order_detalle d
          JOIN productos p ON p.id_producto = d.id_producto
          LEFT JOIN productos_web pw ON pw.id_producto = d.id_producto
         WHERE d.id_orden IN (" . implode(',', array_fill(0, count($ids), '?')) . ")
         ORDER BY d.id_detalle");
    $lin->execute($ids);
    $lineas = [];
    foreach ($lin->fetchAll(PDO::FETCH_ASSOC) as $l) {
        $lineas[(int)$l['id_orden']][] = [
            'id' => (int)$l['id_producto'], 'descripcion' => $l['descripcion'], 'marca' => $l['marca'],
            'codigo' => $l['codigo_barras'], 'cantidad' => (int)$l['cantidad'],
            'precio' => (float)$l['precio_unitario'], 'subtotal' => (float)$l['subtotal_linea'],
            'imagen' => catAsset($l['imagen'])
        ];
    }

    return array_map(function (array $o) use ($lineas) {
        [$clase, $etiqueta] = catEtiquetaPedido($o);
        return [
            'id' => (int)$o['id_orden'], 'folio' => $o['folio'], 'estado' => $o['estado'], 'estadoPago' => $o['estado_pago'],
            'clase' => $clase, 'etiqueta' => $etiqueta,
            'entrega' => $o['metodo_entrega'], 'metodoPago' => $o['nombre_metodo'],
            'subtotal' => (float)$o['subtotal'], 'envio' => (float)$o['costo_envio'], 'total' => (float)$o['total'],
            'direccion' => $o['direccion_envio'], 'tarjeta' => $o['tarjeta_ultimos4'] ? trim($o['tarjeta_marca'] . ' •••• ' . $o['tarjeta_ultimos4']) : null,
            'referencia' => $o['referencia_pago'], 'comentarios' => $o['comentarios'],
            'fecha' => $o['fecha_creacion'], 'fechaTexto' => catFecha($o['fecha_creacion']),
            'fechaPago' => $o['fecha_pago'] ? catFecha($o['fecha_pago']) : null,
            'sucursal' => $o['sucursal'], 'sucursalDireccion' => $o['sucursal_direccion'], 'sucursalTelefono' => $o['sucursal_telefono'],
            'contacto' => ['nombre' => $o['nombre'], 'celular' => $o['celular'], 'email' => $o['email']],
            'cancelable' => $o['estado'] === 'pendiente' && $o['estado_pago'] === 'pendiente' && $o['metodo_entrega'] === 'recoger',
            'lineas' => $lineas[(int)$o['id_orden']] ?? []
        ];
    }, $pedidos);
}

// Etiqueta legible de cada tipo de cita
function catTipoCitaTexto(string $tipo): string {
    return ['visita' => 'Visita al concesionario', 'apartado' => 'Apartado de vehículo',
            'prueba_manejo' => 'Prueba de manejo', 'servicio' => 'Cita de servicio'][$tipo] ?? ucfirst($tipo);
}

// Citas del cliente (visitas, apartados, pruebas de manejo y servicio) con el estado de su orden web si la tienen
function catCitasCliente(int $idCliente): array {
    $stmt = db()->prepare("
        SELECT c.id_cita, c.folio, c.tipo, c.fecha_hora, c.estado, c.vehiculo_cliente, c.vin, c.kilometraje, c.tipo_servicio,
               c.comentarios, c.id_producto, c.id_orden, s.nombre AS sucursal, s.direccion AS sucursal_direccion,
               p.marca, p.modelo, p.anio, p.nombre AS producto, pw.imagen, w.estado AS estado_orden, w.enganche, w.color
          FROM citas c
          JOIN sucursales s ON s.id_sucursal = c.id_sucursal
          LEFT JOIN productos p ON p.id_producto = c.id_producto
          LEFT JOIN productos_web pw ON pw.id_producto = c.id_producto
          LEFT JOIN web_orders w ON w.id_orden = c.id_orden
         WHERE c.id_cliente = ?
         ORDER BY c.fecha_hora DESC
    ");
    $stmt->execute([$idCliente]);
    $ahora = time();
    return array_map(function (array $c) use ($ahora) {
        $estado = $c['estado'];
        $etiqueta = ['programada' => 'Programada', 'confirmada' => 'Confirmada', 'completada' => 'Completada', 'cancelada' => 'Cancelada'][$estado] ?? $estado;
        if ($estado !== 'cancelada' && $c['estado_orden'] === 'atendida') $etiqueta = 'Atendida por un asesor';
        $futura = strtotime($c['fecha_hora']) > $ahora;
        return [
            'id' => (int)$c['id_cita'], 'folio' => $c['folio'], 'tipo' => $c['tipo'], 'tipoTexto' => catTipoCitaTexto($c['tipo']),
            'fecha' => $c['fecha_hora'], 'fechaTexto' => catFecha($c['fecha_hora']), 'estado' => $estado, 'etiqueta' => $etiqueta,
            'sucursal' => $c['sucursal'], 'sucursalDireccion' => $c['sucursal_direccion'],
            'vehiculo' => $c['id_producto'] ? trim("{$c['marca']} {$c['modelo']} {$c['anio']}") : $c['vehiculo_cliente'],
            'imagen' => $c['imagen'] ? catAsset($c['imagen']) : null,
            'idProducto' => $c['id_producto'] ? (int)$c['id_producto'] : null,
            'tipoServicio' => $c['tipo_servicio'], 'vin' => $c['vin'], 'kilometraje' => $c['kilometraje'] !== null ? (int)$c['kilometraje'] : null,
            'comentarios' => $c['comentarios'], 'enganche' => $c['enganche'] !== null ? (float)$c['enganche'] : null, 'color' => $c['color'],
            'cancelable' => $futura && in_array($estado, ['programada', 'confirmada'], true) && $c['estado_orden'] !== 'atendida'
        ];
    }, $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Garantías registradas en el POS para este cliente (tabla garantias existente)
function catGarantiasCliente(int $idCliente): array {
    $stmt = db()->prepare("
        SELECT g.id_garantia, g.fecha_expiracion, g.estado, p.marca, p.modelo, p.anio, p.nombre
          FROM garantias g JOIN productos p ON p.id_producto = g.id_producto
         WHERE g.id_cliente = ? ORDER BY g.fecha_expiracion DESC
    ");
    $stmt->execute([$idCliente]);
    return array_map(fn($g) => [
        'id' => (int)$g['id_garantia'], 'articulo' => trim("{$g['marca']} {$g['modelo']}") ?: $g['nombre'],
        'anio' => $g['anio'], 'vence' => catFecha($g['fecha_expiracion'], false), 'estado' => $g['estado']
    ], $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Compras hechas en caja (tabla ventas del POS) asociadas al cliente: historial real de la concesionaria
function catComprasSucursal(int $idCliente): array {
    $stmt = db()->prepare("
        SELECT v.id_venta, v.fecha_hora, v.total, v.id_sucursal, s.nombre AS sucursal, mp.nombre_metodo,
               GROUP_CONCAT(CONCAT(d.cantidad, '× ', p.nombre) ORDER BY d.id_detalle SEPARATOR ', ') AS articulos
          FROM ventas v
          JOIN sucursales s ON s.id_sucursal = v.id_sucursal
          JOIN metodos_pago mp ON mp.id_metodo_pago = v.id_metodo_pago
          JOIN detalle_ventas d ON d.id_venta = v.id_venta
          JOIN productos p ON p.id_producto = d.id_producto
         WHERE v.id_cliente = ?
         GROUP BY v.id_venta
         ORDER BY v.fecha_hora DESC
    ");
    $stmt->execute([$idCliente]);
    return array_map(fn($v) => [
        'id' => (int)$v['id_venta'], 'folio' => catFolio('KRM', (int)$v['id_sucursal'], (int)$v['id_venta']),
        'fecha' => catFecha($v['fecha_hora']), 'total' => (float)$v['total'], 'sucursal' => $v['sucursal'],
        'metodo' => $v['nombre_metodo'], 'articulos' => $v['articulos']
    ], $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Solicitudes enviadas (contacto, información, cotizaciones…)
function catSolicitudesCliente(int $idCliente): array {
    $stmt = db()->prepare("
        SELECT s.id_solicitud, s.folio, s.tipo, s.asunto, s.estado, s.fecha_creacion, p.marca, p.modelo
          FROM solicitudes s LEFT JOIN productos p ON p.id_producto = s.id_producto
         WHERE s.id_cliente = ? ORDER BY s.id_solicitud DESC LIMIT 30
    ");
    $stmt->execute([$idCliente]);
    $tipos = ['informacion' => 'Solicitud de información', 'cotizacion' => 'Cotización', 'contacto' => 'Contacto',
              'queja' => 'Queja', 'sugerencia' => 'Sugerencia', 'garantia' => 'Garantía', 'seguro' => 'Seguros',
              'financiamiento' => 'Financiamiento', 'seminuevo' => 'Seminuevos', 'postventa' => 'Postventa', 'otro' => 'Otro'];
    return array_map(fn($s) => [
        'id' => (int)$s['id_solicitud'], 'folio' => $s['folio'], 'tipo' => $tipos[$s['tipo']] ?? $s['tipo'],
        'asunto' => $s['asunto'] ?: trim("{$s['marca']} {$s['modelo']}"), 'estado' => $s['estado'],
        'fecha' => catFecha($s['fecha_creacion'])
    ], $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Notificaciones del cliente (las más recientes primero)
function catNotificacionesCliente(int $idCliente, int $limite = 30): array {
    $stmt = db()->prepare("SELECT id_notificacion, tipo, titulo, mensaje, enlace, leida, fecha FROM notificaciones WHERE id_cliente = ? ORDER BY id_notificacion DESC LIMIT " . max(1, min($limite, 100)));
    $stmt->execute([$idCliente]);
    return array_map(fn($n) => [
        'id' => (int)$n['id_notificacion'], 'tipo' => $n['tipo'], 'titulo' => $n['titulo'], 'mensaje' => $n['mensaje'],
        'enlace' => $n['enlace'], 'leida' => (bool)$n['leida'], 'fecha' => catFecha($n['fecha'])
    ], $stmt->fetchAll(PDO::FETCH_ASSOC));
}

function catNotificacionesSinLeer(int $idCliente): int {
    $stmt = db()->prepare('SELECT COUNT(*) FROM notificaciones WHERE id_cliente = ? AND leida = 0');
    $stmt->execute([$idCliente]);
    return (int)$stmt->fetchColumn();
}
