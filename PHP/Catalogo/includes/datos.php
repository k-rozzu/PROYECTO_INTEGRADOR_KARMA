<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — consultas reutilizables (productos, inventario por sucursal, opciones del configurador).
   Todas usan sentencias preparadas. El inventario SIEMPRE se lee de `inventarios` filtrando por la sucursal
   elegida: el mismo producto tiene existencias distintas en Manzanillo y en Colima.
   ===================================================================================== */

require_once __DIR__ . '/bootstrap.php';

// Columnas comunes de un producto del catálogo (productos + ficha web + inventario de UNA sucursal)
const CAT_SQL_PRODUCTO = "
    SELECT p.id_producto, p.codigo_barras, p.nombre, p.descripcion, p.precio_base, p.marca, p.modelo, p.anio, p.tipo,
           p.color, p.color_hex, p.color_interior, p.motor, p.cilindraje, p.detalle, p.compatibilidad, p.traccion, p.lado,
           p.vin, p.modelo_3d, c.nombre_categoria,
           pw.seccion, pw.destacado, pw.condicion, pw.subcategoria, pw.imagen, pw.galeria, pw.transmision, pw.potencia,
           pw.aceleracion, pw.descripcion_larga, pw.caracteristicas, pw.orden,
           COALESCE(i.stock_actual, 0) AS stock, COALESCE(i.stock_minimo, 2) AS stock_minimo,
           vm.motor AS motor_compatible
      FROM productos p
      JOIN productos_web pw ON pw.id_producto = p.id_producto AND pw.publicado = 1
      JOIN categorias c ON c.id_categoria = p.id_categoria
      LEFT JOIN inventarios i ON i.id_producto = p.id_producto AND i.id_sucursal = ?
      LEFT JOIN (SELECT marca, modelo, MIN(motor) AS motor FROM productos WHERE tipo IN ('auto','moto') GROUP BY marca, modelo) vm
             ON p.tipo = 'refaccion' AND vm.marca = p.marca AND vm.modelo = p.modelo
";

// Texto y estado de disponibilidad: 0 = agotado · hasta stock_minimo = pocas unidades · más = disponible
function catEstadoStock(int $stock, int $minimo): array {
    if ($stock <= 0) return ['agotado', '0 unidades disponibles'];
    $texto = $stock === 1 ? '1 unidad disponible' : "{$stock} unidades disponibles";
    return [$stock <= max(1, $minimo) ? 'pocas' : 'disponible', $texto];
}

// Convierte una fila de la BD al formato que usan las páginas y el JS
function catFormatearProducto(array $r): array {
    $stock = (int)$r['stock'];
    [$estado, $textoStock] = catEstadoStock($stock, (int)$r['stock_minimo']);
    $esVehiculo = in_array($r['tipo'], ['auto', 'moto'], true);
    // Los vehículos muestran una sola foto: su galería extra (productos_web.galeria) no se usa
    $galeria = $esVehiculo ? [] : array_values(array_filter(array_map('trim', explode("\n", (string)$r['galeria']))));
    return [
        'id' => (int)$r['id_producto'],
        'codigo' => $r['codigo_barras'],
        'nombre' => $r['nombre'],
        'titulo' => $esVehiculo ? trim("{$r['marca']} {$r['modelo']}") : $r['nombre'],
        'descripcion' => $r['descripcion'],
        'descripcionLarga' => $r['descripcion_larga'] ?: $r['descripcion'],
        'precio' => (float)$r['precio_base'],
        'precioTexto' => catPrecio((float)$r['precio_base'], !$esVehiculo),
        'marca' => $r['marca'],
        'modelo' => $r['modelo'],
        'anio' => $r['anio'] !== null ? (int)$r['anio'] : null,
        'tipo' => $r['tipo'],
        'esVehiculo' => $esVehiculo,
        'seccion' => $r['seccion'],
        'categoria' => $r['nombre_categoria'],
        'subcategoria' => $r['subcategoria'],
        'condicion' => $r['condicion'],
        'destacado' => (bool)$r['destacado'],
        'color' => $r['color'],
        'colorHex' => $r['color_hex'],
        'colorInterior' => $r['color_interior'],
        'motor' => $r['motor'] ?: $r['motor_compatible'],
        'motorCompatible' => $r['motor_compatible'],
        'cilindraje' => $r['cilindraje'],
        'transmision' => $r['transmision'],
        'traccion' => $r['traccion'],
        'potencia' => $r['potencia'],
        'aceleracion' => $r['aceleracion'],
        'lado' => $r['lado'],
        'compatibilidad' => $r['compatibilidad'],
        'detalle' => $r['detalle'],
        'caracteristicas' => array_values(array_filter(array_map('trim', explode("\n", (string)$r['caracteristicas'])))),
        // IMAGEN DEL PRODUCTO: viene de productos_web.imagen (ej. assets/Catalogo/vehiculos/audi/a3.webp)
        'imagen' => catAsset($r['imagen']),
        'miniatura' => catMiniatura($r['imagen']),
        'galeria' => array_map(fn($g) => catAsset($g), $galeria),
        'modelo3d' => $r['modelo_3d'] ?: null,
        'vin' => $esVehiculo ? $r['vin'] : null,
        'stock' => $stock,
        'estadoStock' => $estado,
        'textoStock' => $textoStock,
        'url' => ($esVehiculo ? 'vehiculo.php' : 'refaccion.php') . '?id=' . (int)$r['id_producto']
    ];
}

// Lista de productos con filtros opcionales (seccion, marca, tipo, subcategoria, anio, precio, disponible, modelo, q, orden)
function catBuscarProductos(array $f, ?int $idSucursal = null, int $limite = 200): array {
    $idSucursal = $idSucursal ?? catSucursalActual()['id_sucursal'];
    $where = [];
    $params = [$idSucursal];

    $secciones = array_values(array_intersect((array)($f['seccion'] ?? []), ['vehiculos', 'refacciones', 'accesorios']));
    if ($secciones) {
        $where[] = 'pw.seccion IN (' . implode(',', array_fill(0, count($secciones), '?')) . ')';
        array_push($params, ...$secciones);
    }
    if (!empty($f['marca']) && in_array($f['marca'], CAT_MARCAS, true)) { $where[] = 'p.marca = ?'; $params[] = $f['marca']; }
    if (!empty($f['tipo']) && in_array($f['tipo'], ['auto', 'moto'], true)) { $where[] = 'p.tipo = ?'; $params[] = $f['tipo']; }
    if (!empty($f['subcategoria'])) { $where[] = 'pw.subcategoria = ?'; $params[] = (string)$f['subcategoria']; }
    if (!empty($f['condicion']) && in_array($f['condicion'], ['nuevo', 'seminuevo'], true)) { $where[] = 'pw.condicion = ?'; $params[] = $f['condicion']; }
    if (!empty($f['anio'])) { $where[] = 'p.anio = ?'; $params[] = (int)$f['anio']; }
    if (isset($f['precio_min']) && $f['precio_min'] !== '') { $where[] = 'p.precio_base >= ?'; $params[] = (float)$f['precio_min']; }
    if (isset($f['precio_max']) && $f['precio_max'] !== '') { $where[] = 'p.precio_base <= ?'; $params[] = (float)$f['precio_max']; }
    if (!empty($f['disponible'])) $where[] = 'COALESCE(i.stock_actual, 0) > 0';
    if (!empty($f['modelo'])) {
        $where[] = '(p.modelo = ? OR p.compatibilidad LIKE ?)';
        $params[] = (string)$f['modelo'];
        $params[] = '%' . (string)$f['modelo'] . '%';
    }
    if (!empty($f['ids'])) {
        $ids = array_values(array_filter(array_map('intval', (array)$f['ids'])));
        if (!$ids) return [];
        $where[] = 'p.id_producto IN (' . implode(',', array_fill(0, count($ids), '?')) . ')';
        array_push($params, ...$ids);
    }
    // Búsqueda: cada palabra debe aparecer en marca, modelo, nombre, código, categoría, compatibilidad, motor, etc.
    // (la colación utf8mb4_unicode_ci ignora mayúsculas y acentos: "bateria" encuentra "Batería")
    $q = trim((string)($f['q'] ?? ''));
    if ($q !== '') {
        foreach (array_slice(preg_split('/\s+/u', mb_substr($q, 0, 80)), 0, 6) as $palabra) {
            $where[] = "CONCAT_WS(' ', p.marca, p.modelo, p.nombre, p.codigo_barras, c.nombre_categoria, p.compatibilidad, p.motor,
                                 vm.motor, pw.subcategoria, pw.seccion, p.color, p.anio, p.cilindraje, pw.transmision, p.traccion) LIKE ?";
            $params[] = '%' . $palabra . '%';
        }
    }

    $ordenes = [
        'precio_asc' => 'p.precio_base ASC',
        'precio_desc' => 'p.precio_base DESC',
        'anio_desc' => 'p.anio DESC, p.precio_base DESC',
        'nombre' => 'p.marca, p.modelo, p.nombre',
        'disponibles' => 'COALESCE(i.stock_actual, 0) DESC, pw.orden'
    ];
    $orden = $ordenes[$f['orden'] ?? ''] ?? 'pw.destacado DESC, pw.orden ASC';

    $sql = CAT_SQL_PRODUCTO . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . " ORDER BY {$orden} LIMIT " . max(1, min($limite, 500));
    $stmt = db()->prepare($sql);
    $stmt->execute($params);
    return array_map('catFormatearProducto', $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Un producto publicado por id o por código de barras (null si no existe / no está publicado)
function catProducto(?int $id, ?string $codigo = null, ?int $idSucursal = null): ?array {
    $idSucursal = $idSucursal ?? catSucursalActual()['id_sucursal'];
    if ($id) {
        $stmt = db()->prepare(CAT_SQL_PRODUCTO . ' WHERE p.id_producto = ? LIMIT 1');
        $stmt->execute([$idSucursal, $id]);
    } elseif ($codigo) {
        $stmt = db()->prepare(CAT_SQL_PRODUCTO . ' WHERE p.codigo_barras = ? LIMIT 1');
        $stmt->execute([$idSucursal, $codigo]);
    } else {
        return null;
    }
    $fila = $stmt->fetch(PDO::FETCH_ASSOC);
    return $fila ? catFormatearProducto($fila) : null;
}

// Existencias de un producto en CADA sucursal activa (para "Disponibilidad por sucursal")
function catStockPorSucursal(int $idProducto): array {
    $stmt = db()->prepare("
        SELECT s.id_sucursal, s.nombre, COALESCE(i.stock_actual, 0) AS stock, COALESCE(i.stock_minimo, 2) AS stock_minimo
          FROM sucursales s
          LEFT JOIN inventarios i ON i.id_sucursal = s.id_sucursal AND i.id_producto = ?
         WHERE s.estado = 'activo'
         ORDER BY s.id_sucursal
    ");
    $stmt->execute([$idProducto]);
    return array_map(function (array $r) {
        [$estado, $texto] = catEstadoStock((int)$r['stock'], (int)$r['stock_minimo']);
        return ['id_sucursal' => (int)$r['id_sucursal'], 'nombre' => $r['nombre'], 'stock' => (int)$r['stock'], 'estado' => $estado, 'texto' => $texto];
    }, $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Opciones del configurador (color, versión, equipamiento) para la marca y tipo del vehículo
function catOpcionesConfigurador(string $marca, string $tipo): array {
    $stmt = db()->prepare("
        SELECT id_opcion, grupo, nombre, descripcion, precio, color_hex
          FROM catalogo_opciones
         WHERE activa = 1 AND (marca = ? OR marca IS NULL) AND (tipo_vehiculo = ? OR tipo_vehiculo IS NULL)
         ORDER BY FIELD(grupo, 'color', 'version', 'equipamiento'), orden
    ");
    $stmt->execute([$marca, $tipo]);
    $grupos = ['color' => [], 'version' => [], 'equipamiento' => []];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $o) {
        $grupos[$o['grupo']][] = [
            'id' => (int)$o['id_opcion'], 'nombre' => $o['nombre'], 'descripcion' => $o['descripcion'],
            'precio' => (float)$o['precio'], 'colorHex' => $o['color_hex']
        ];
    }
    return $grupos;
}

// Refacciones y accesorios compatibles con un vehículo (misma marca y mismo modelo / compatibilidad)
function catCompatiblesConVehiculo(array $vehiculo, int $limite = 8): array {
    $todos = catBuscarProductos(['seccion' => ['refacciones', 'accesorios'], 'marca' => $vehiculo['marca'], 'orden' => 'disponibles']);
    $modelo = mb_strtolower((string)$vehiculo['modelo']);
    $exactos = array_values(array_filter($todos, fn($p) => mb_strtolower((string)$p['modelo']) === $modelo
        || str_contains(mb_strtolower((string)$p['compatibilidad']), $modelo)));
    $idsExactos = array_column($exactos, 'id');
    $resto = array_values(array_filter($todos, fn($p) => !in_array($p['id'], $idsExactos, true)));
    return array_slice(array_merge($exactos, $resto), 0, $limite);
}

// Ids de los vehículos favoritos del cliente
function catFavoritosIds(?int $idCliente): array {
    if (!$idCliente) return [];
    $stmt = db()->prepare('SELECT id_producto FROM favoritos_catalogo WHERE id_cliente = ?');
    $stmt->execute([$idCliente]);
    return array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));
}

// Opciones de filtro (subcategorías y años) presentes en una sección del catálogo
function catValoresFiltro(string $seccion): array {
    $stmt = db()->prepare("
        SELECT DISTINCT pw.subcategoria, p.anio, p.marca, p.modelo
          FROM productos_web pw JOIN productos p ON p.id_producto = pw.id_producto
         WHERE pw.publicado = 1 AND pw.seccion = ?
    ");
    $stmt->execute([$seccion]);
    $subcats = $anios = $modelos = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
        if ($r['subcategoria']) $subcats[$r['subcategoria']] = true;
        if ($r['anio']) $anios[(int)$r['anio']] = true;
        if ($r['modelo']) $modelos[$r['marca']][$r['modelo']] = true;
    }
    ksort($subcats);
    krsort($anios);
    foreach ($modelos as &$lista) { $lista = array_keys($lista); sort($lista); }
    return ['subcategorias' => array_keys($subcats), 'anios' => array_keys($anios), 'modelos' => $modelos];
}

// Horarios de cita disponibles (lunes a viernes 9–18 h, sábado 9–13 h; domingo cerrado)
function catHorasDelDia(string $fecha): array {
    $t = strtotime($fecha);
    if (!$t) return [];
    $dia = (int)date('N', $t);
    if ($dia === 7) return [];
    $ultima = $dia === 6 ? 13 : 18;
    $horas = [];
    for ($h = 9; $h <= $ultima; $h++) $horas[] = sprintf('%02d:00', $h);
    return $horas;
}
