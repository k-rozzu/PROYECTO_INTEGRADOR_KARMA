<?php
declare(strict_types=1);

/* API del Panel de Administrador General (dasboard/admin.html) */
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../PuntoDeVenta/conexion.php';
require_once __DIR__ . '/../Login/sesion.php';

// Lee el cuerpo JSON de la petición y lo regresa como arreglo
function jsonInput(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

// Responde con éxito (ok = true) y termina la ejecución
function ok($data = null): never {
    echo json_encode(['ok' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
    exit;
}

// Responde con un error y su código HTTP, y termina la ejecución
function fail(string $message, int $status = 400): never { 
    http_response_code($status);
    echo json_encode(['ok' => false, 'error' => $message], JSON_UNESCAPED_UNICODE);
    exit;
}

// Texto obligatorio del cuerpo de la petición (falla si viene vacío)
function texto(array $in, string $campo, string $etiqueta): string {
    $valor = trim((string)($in[$campo] ?? ''));
    if ($valor === '') fail("El campo {$etiqueta} es obligatorio.");
    return $valor;
}

// Texto opcional: regresa null si viene vacío
function textoOpcional(array $in, string $campo): ?string {
    $valor = trim((string)($in[$campo] ?? ''));
    return $valor === '' ? null : $valor;
}

// Id numérico opcional (los ids viajan como texto desde el navegador)
function idOpcional($valor): ?int {
    return ($valor === null || $valor === '') ? null : (int)$valor;
}

// Monto con formato para los mensajes de auditoría ($1,250,000.00)
function dinero($monto): string {
    return '$' . number_format((float)$monto, 2);
}

// Guarda un registro en la bitácora de auditoría a nombre del administrador en sesión
function auditar(string $accion, string $detalle): void {
    db()->prepare("INSERT INTO auditoria (id_usuario, accion, detalle) VALUES (?, ?, ?)")
        ->execute([(int)$GLOBALS['admin']['id'], $accion, mb_substr($detalle, 0, 255)]);
}

// Nombre del rol en la BD ↔ clave que usa el panel
const ROLES = ['Administrador General' => 'admin', 'Gerente' => 'gerente', 'Cajero' => 'cajero'];

// Sólo un Administrador General con sesión iniciada (y que siga activo en la BD) puede usar esta API
function exigirAdministrador(): array {
    $sesion = usuarioActual();
    if (!$sesion) fail('Inicia sesión para continuar.', 401);
    $stmt = db()->prepare("
        SELECT u.id_usuario, u.nombre, u.correo, u.estado, u.idioma_pref, r.nombre_rol
        FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.id_usuario = ?");
    $stmt->execute([$sesion['id']]);
    $u = $stmt->fetch();
    if (!$u || $u['estado'] !== 'activo') {
        cerrarSesion();
        fail('Tu usuario ya no está activo.', 401);
    }
    if ($u['nombre_rol'] !== 'Administrador General') fail('Sólo el Administrador General puede usar este panel.', 403);
    return ['id' => (string)$u['id_usuario'], 'nombre' => $u['nombre'], 'correo' => $u['correo'], 'idioma' => $u['idioma_pref']];
}

// Enrutador: ejecuta la acción pedida en ?action=
try {
    $admin = exigirAdministrador();
    $action = $_GET['action'] ?? '';
    $id = (int)($_GET['id'] ?? 0);
    $in = jsonInput();
    switch ($action) {
        case 'sesion':              ok($admin);
        case 'idioma':              ok(guardarIdioma($in));
        case 'sucursales':          ok(obtenerSucursales());
        case 'crear_sucursal':      ok(guardarSucursal(null, $in));
        case 'actualizar_sucursal': ok(guardarSucursal($id, $in));
        case 'estado_sucursal':     ok(cambiarEstadoSucursal($id, $in));
        case 'cajas':               ok(obtenerCajas());
        case 'estado_caja':         ok(cambiarEstadoCaja($id, $in));
        case 'usuarios':            ok(obtenerUsuarios());
        case 'crear_usuario':       ok(guardarUsuario(null, $in));
        case 'actualizar_usuario':  ok(guardarUsuario($id, $in));
        case 'estado_usuario':      ok(cambiarEstadoUsuario($id, $in));
        case 'catalogo':            ok(obtenerCatalogo());
        case 'crear_modelo':        ok(guardarModelo(null, $in));
        case 'actualizar_modelo':   ok(guardarModelo($id, $in));
        case 'estado_modelo':       ok(cambiarEstadoModelo($id, $in));
        case 'inventario':          ok(obtenerInventario());
        case 'crear_articulo':      ok(crearArticulo($in));
        case 'precio_producto':     ok(actualizarPrecioProducto($in));
        case 'ventas':              ok(obtenerVentas());
        case 'venta_detalle':       ok(obtenerDetalleVenta($id));
        case 'cortes':              ok(obtenerCortes());
        case 'pedidos':             ok(obtenerPedidos());
        case 'crear_pedido':        ok(guardarPedido(null, $in));
        case 'actualizar_pedido':   ok(guardarPedido($id, $in));
        case 'estado_pedido':       ok(cambiarEstadoPedido($id, $in));
        case 'recibir_pedido':      ok(recibirPedido($id));
        case 'auditoria':           ok(obtenerAuditoria());
        default:                    fail('Acción no reconocida.', 404);
    }
} catch (Throwable $e) {
    try { if (db()->inTransaction()) db()->rollBack(); } catch (Throwable) {}
    fail($e->getMessage(), 500);
}

// Guarda el idioma preferido (es / en) en el perfil del administrador
function guardarIdioma(array $in): string {
    $idioma = ($in['idioma'] ?? '') === 'en' ? 'en' : 'es';
    db()->prepare("UPDATE usuarios SET idioma_pref = ? WHERE id_usuario = ?")->execute([$idioma, (int)$GLOBALS['admin']['id']]);
    return $idioma;
}

/* ==========================================================================
   SUCURSALES
   ========================================================================== */

// Lista de sucursales con su gerente (primer usuario con rol Gerente) y cajas en operación
function obtenerSucursales(?int $id = null): array {
    $sql = "
        SELECT s.*,
               (SELECT u.id_usuario FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
                 WHERE u.id_sucursal = s.id_sucursal AND r.nombre_rol = 'Gerente'
                 ORDER BY u.id_usuario LIMIT 1) AS id_gerente,
               (SELECT COUNT(*) FROM cajas c
                 WHERE c.id_sucursal = s.id_sucursal AND c.estado <> 'mantenimiento') AS cajas_activas
        FROM sucursales s" . ($id !== null ? " WHERE s.id_sucursal = ?" : "") . "
        ORDER BY s.id_sucursal";
    $stmt = db()->prepare($sql);
    $stmt->execute($id !== null ? [$id] : []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_sucursal'],
        'nombre' => $r['nombre'],
        'razonSocial' => $r['razon_social'] ?? '',
        'direccion' => $r['direccion'],
        'direccionFiscal' => $r['direccion_fiscal'] ?? '',
        'telefono' => $r['telefono'],
        'email' => $r['email'] ?? '',
        'contacto' => $r['contacto_operativo'] ?? '',
        'gerenteId' => $r['id_gerente'] !== null ? (string)$r['id_gerente'] : null,
        'cajasActivas' => (int)$r['cajas_activas'],
        'estado' => $r['estado'],
    ], $stmt->fetchAll());
}

// Alta (id = null) o edición de una sucursal, junto con su gerente y número de cajas
function guardarSucursal(?int $id, array $in): array {
    $pdo = db();
    $datos = [
        texto($in, 'nombre', 'nombre'),
        textoOpcional($in, 'razonSocial'),
        texto($in, 'direccion', 'dirección'),
        textoOpcional($in, 'direccionFiscal'),
        texto($in, 'telefono', 'teléfono'),
        textoOpcional($in, 'email'),
        textoOpcional($in, 'contacto'),
        ($in['estado'] ?? 'activo') === 'inactivo' ? 'inactivo' : 'activo',
    ];
    $cajas = max(0, (int)($in['cajasActivas'] ?? 0));

    $pdo->beginTransaction();
    if ($id === null) {
        $pdo->prepare("
            INSERT INTO sucursales (nombre, razon_social, direccion, direccion_fiscal, telefono, email, contacto_operativo, estado)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)")->execute($datos);
        $id = (int)$pdo->lastInsertId();
        auditar('Alta de sucursal', "Se registró la sucursal {$datos[0]}");
    } else {
        if (!obtenerSucursales($id)) fail('La sucursal no existe.', 404);
        $pdo->prepare("
            UPDATE sucursales SET nombre = ?, razon_social = ?, direccion = ?, direccion_fiscal = ?, telefono = ?,
                                  email = ?, contacto_operativo = ?, estado = ?
            WHERE id_sucursal = ?")->execute([...$datos, $id]);
        auditar('Edición de sucursal', "Se actualizaron los datos de la sucursal {$datos[0]}");
    }
    asignarGerente($id, idOpcional($in['gerenteId'] ?? null));
    sincronizarCajas($id, $cajas);
    $pdo->commit();

    return obtenerSucursales($id)[0];
}

// Activa o desactiva una sucursal (baja lógica)
function cambiarEstadoSucursal(int $id, array $in): array {
    $estado = ($in['estado'] ?? '') === 'inactivo' ? 'inactivo' : 'activo';
    db()->prepare("UPDATE sucursales SET estado = ? WHERE id_sucursal = ?")->execute([$estado, $id]);
    $sucursal = obtenerSucursales($id);
    if (!$sucursal) fail('La sucursal no existe.', 404);
    auditar($estado === 'activo' ? 'Activación de sucursal' : 'Baja de sucursal', "Sucursal {$sucursal[0]['nombre']} marcada como {$estado}");
    return $sucursal[0];
}

// Deja a un solo gerente asignado a la sucursal (o a ninguno si $idGerente es null)
function asignarGerente(int $idSucursal, ?int $idGerente): void {
    $pdo = db();
    $pdo->prepare("
        UPDATE usuarios SET id_sucursal = NULL
        WHERE id_sucursal = ? AND id_usuario <> ?
          AND id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'Gerente')
    ")->execute([$idSucursal, $idGerente ?? 0]);
    if ($idGerente !== null) {
        $pdo->prepare("UPDATE usuarios SET id_sucursal = ? WHERE id_usuario = ?")->execute([$idSucursal, $idGerente]);
    }
}

// Ajusta las cajas de la sucursal: las sobrantes pasan a mantenimiento y las faltantes se reactivan o se crean
function sincronizarCajas(int $idSucursal, int $deseadas): void {
    $pdo = db();
    $stmt = $pdo->prepare("SELECT id_caja, numero_caja, estado FROM cajas WHERE id_sucursal = ? ORDER BY numero_caja");
    $stmt->execute([$idSucursal]);
    $cajas = $stmt->fetchAll();
    $activas = array_values(array_filter($cajas, fn($c) => $c['estado'] !== 'mantenimiento'));
    $enMantenimiento = array_values(array_filter($cajas, fn($c) => $c['estado'] === 'mantenimiento'));

    $actualizar = $pdo->prepare("UPDATE cajas SET estado = ? WHERE id_caja = ?");
    // Sobran cajas: se desactivan las de número más alto
    foreach (array_slice(array_reverse($activas), 0, max(0, count($activas) - $deseadas)) as $caja) {
        $actualizar->execute(['mantenimiento', $caja['id_caja']]);
    }
    // Faltan cajas: primero se reactivan las que estaban en mantenimiento
    $faltan = $deseadas - count($activas);
    foreach (array_slice($enMantenimiento, 0, max(0, $faltan)) as $caja) {
        $actualizar->execute(['cerrada', $caja['id_caja']]);
        $faltan--;
    }
    // …y si aún faltan, se crean nuevas con el siguiente número
    $numero = $cajas ? (int)end($cajas)['numero_caja'] : 0;
    $insertar = $pdo->prepare("INSERT INTO cajas (id_sucursal, numero_caja, estado) VALUES (?, ?, 'cerrada')");
    for (; $faltan > 0; $faltan--) {
        $insertar->execute([$idSucursal, ++$numero]);
    }
}

/* ==========================================================================
   CAJAS Y TERMINALES DE COBRO
   ========================================================================== */

// Todas las cajas con su estado y lo que han cobrado hoy
function obtenerCajas(?int $id = null): array {
    $stmt = db()->prepare("
        SELECT c.id_caja, c.id_sucursal, c.numero_caja, c.estado,
               (SELECT DATE_FORMAT(MAX(v.fecha_hora), '%Y-%m-%dT%H:%i:%s') FROM ventas v WHERE v.id_caja = c.id_caja) AS ultima_venta,
               (SELECT COUNT(*) FROM ventas v WHERE v.id_caja = c.id_caja AND DATE(v.fecha_hora) = CURDATE()) AS tickets_hoy,
               (SELECT COALESCE(SUM(v.total), 0) FROM ventas v WHERE v.id_caja = c.id_caja AND DATE(v.fecha_hora) = CURDATE()) AS total_hoy
        FROM cajas c" . ($id !== null ? " WHERE c.id_caja = ?" : "") . "
        ORDER BY c.id_sucursal, c.numero_caja");
    $stmt->execute($id !== null ? [$id] : []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_caja'],
        'sucursalId' => (string)$r['id_sucursal'],
        'numero' => (int)$r['numero_caja'],
        'estado' => $r['estado'],
        'ultimaVenta' => $r['ultima_venta'],
        'ticketsHoy' => (int)$r['tickets_hoy'],
        'totalHoy' => (float)$r['total_hoy'],
    ], $stmt->fetchAll());
}

// Autoriza (abierta / cerrada) o bloquea (mantenimiento) una caja
function cambiarEstadoCaja(int $id, array $in): array {
    $estado = (string)($in['estado'] ?? '');
    if (!in_array($estado, ['abierta', 'cerrada', 'mantenimiento'], true)) fail('Estado de caja no válido.');
    db()->prepare("UPDATE cajas SET estado = ? WHERE id_caja = ?")->execute([$estado, $id]);
    $caja = obtenerCajas($id);
    if (!$caja) fail('La caja no existe.', 404);
    $sucursal = obtenerSucursales((int)$caja[0]['sucursalId'])[0]['nombre'];
    auditar('Cambio de estado de caja', "Caja {$caja[0]['numero']} de {$sucursal} marcada como {$estado}");
    return $caja[0];
}

/* ==========================================================================
   USUARIOS / PERSONAL
   ========================================================================== */

function obtenerUsuarios(?int $id = null): array {
    $sql = "
        SELECT u.id_usuario, u.nombre, u.correo, u.id_sucursal, u.estado, r.nombre_rol
        FROM usuarios u
        JOIN roles r ON r.id_rol = u.id_rol" . ($id !== null ? " WHERE u.id_usuario = ?" : "") . "
        ORDER BY u.id_usuario";
    $stmt = db()->prepare($sql);
    $stmt->execute($id !== null ? [$id] : []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_usuario'],
        'nombre' => $r['nombre'],
        'correo' => $r['correo'],
        'rol' => ROLES[$r['nombre_rol']] ?? strtolower($r['nombre_rol']),
        'sucursalId' => $r['id_sucursal'] !== null ? (string)$r['id_sucursal'] : null,
        'estado' => $r['estado'],
    ], $stmt->fetchAll());
}

// Nombre de una sucursal (o "sin sucursal") para los mensajes de auditoría
function nombreSucursal(?int $id): string {
    if ($id === null) return 'sin sucursal';
    $sucursal = obtenerSucursales($id);
    return $sucursal ? $sucursal[0]['nombre'] : 'sin sucursal';
}

// Alta (id = null, requiere contraseña) o edición de un usuario; en edición la contraseña es opcional
function guardarUsuario(?int $id, array $in): array {
    $pdo = db();
    $nombre = texto($in, 'nombre', 'nombre');
    $correo = texto($in, 'correo', 'correo');
    if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) fail('El correo no es válido.');
    $nombreRol = array_search($in['rol'] ?? '', ROLES, true);
    if ($nombreRol === false) fail('Rol no válido.');
    $idSucursal = idOpcional($in['sucursalId'] ?? null);
    $password = (string)($in['password'] ?? '');
    if (($id === null || $password !== '') && strlen($password) < 8) fail('La contraseña debe tener al menos 8 caracteres.');
    if ($id !== null && (string)$id === $GLOBALS['admin']['id'] && $nombreRol !== 'Administrador General') {
        fail('No puedes quitarte a ti mismo el rol de Administrador General.');
    }

    $stmt = $pdo->prepare("SELECT id_rol FROM roles WHERE nombre_rol = ?");
    $stmt->execute([$nombreRol]);
    $idRol = $stmt->fetchColumn();
    if ($idRol === false) fail("El rol {$nombreRol} no existe en la base de datos.");

    $stmt = $pdo->prepare("SELECT COUNT(*) FROM usuarios WHERE correo = ? AND id_usuario <> ?");
    $stmt->execute([$correo, $id ?? 0]);
    if ((int)$stmt->fetchColumn() > 0) fail('Ya existe un usuario con ese correo.');

    if ($id === null) {
        $pdo->prepare("INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash) VALUES (?, ?, ?, ?, ?)")
            ->execute([$idRol, $idSucursal, $nombre, $correo, password_hash($password, PASSWORD_BCRYPT)]);
        $id = (int)$pdo->lastInsertId();
        auditar('Alta de usuario', "Se registró a {$nombre} como {$nombreRol} en " . nombreSucursal($idSucursal));
    } else {
        $anterior = obtenerUsuarios($id);
        if (!$anterior) fail('El usuario no existe.', 404);
        $anterior = $anterior[0];
        $pdo->prepare("UPDATE usuarios SET id_rol = ?, id_sucursal = ?, nombre = ?, correo = ? WHERE id_usuario = ?")
            ->execute([$idRol, $idSucursal, $nombre, $correo, $id]);

        if ($anterior['sucursalId'] !== ($idSucursal !== null ? (string)$idSucursal : null)) {
            $de = nombreSucursal(idOpcional($anterior['sucursalId']));
            auditar('Reubicación de personal', "{$nombre} ({$nombreRol}) pasó de {$de} a " . nombreSucursal($idSucursal));
        } else {
            auditar('Edición de usuario', "Se actualizaron los datos de {$nombre} ({$nombreRol})");
        }
        if ($password !== '') {
            $pdo->prepare("UPDATE usuarios SET password_hash = ? WHERE id_usuario = ?")
                ->execute([password_hash($password, PASSWORD_BCRYPT), $id]);
            auditar('Cambio de credenciales', "Se restableció la contraseña de {$nombre}");
        }
    }

    return obtenerUsuarios($id)[0];
}

// Da de alta o de baja (lógica) a un usuario
function cambiarEstadoUsuario(int $id, array $in): array {
    if ((string)$id === $GLOBALS['admin']['id']) fail('No puedes desactivar tu propio usuario.');
    $estado = ($in['estado'] ?? '') === 'inactivo' ? 'inactivo' : 'activo';
    db()->prepare("UPDATE usuarios SET estado = ? WHERE id_usuario = ?")->execute([$estado, $id]);
    $usuario = obtenerUsuarios($id);
    if (!$usuario) fail('El usuario no existe.', 404);
    auditar($estado === 'activo' ? 'Activación de usuario' : 'Baja de usuario', "{$usuario[0]['nombre']} marcado como {$estado}");
    return $usuario[0];
}

/* ==========================================================================
   CATÁLOGO MAESTRO DE MODELOS Y VERSIONES
   ========================================================================== */

function obtenerCatalogo(?int $id = null): array {
    $stmt = db()->prepare("SELECT * FROM catalogo_modelos" . ($id !== null ? " WHERE id_modelo = ?" : "") . " ORDER BY marca, modelo, version");
    $stmt->execute($id !== null ? [$id] : []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_modelo'],
        'marca' => $r['marca'],
        'modelo' => $r['modelo'],
        'version' => $r['version'] ?? '',
        'carroceria' => $r['carroceria'],
        'anio' => $r['anio'] !== null ? (int)$r['anio'] : null,
        'equipamiento' => $r['equipamiento'] ?? '',
        'precioLista' => (float)$r['precio_lista'],
        'estado' => $r['estado'],
    ], $stmt->fetchAll());
}

// Alta (id = null) o edición de un modelo; los cambios de precio de lista quedan en auditoría
function guardarModelo(?int $id, array $in): array {
    $pdo = db();
    $marca = texto($in, 'marca', 'marca');
    $modelo = texto($in, 'modelo', 'modelo');
    $carroceria = texto($in, 'carroceria', 'carrocería');
    $precio = (float)($in['precioLista'] ?? 0);
    if ($precio <= 0) fail('El precio de lista debe ser mayor a 0.');
    $datos = [$marca, $modelo, textoOpcional($in, 'version'), $carroceria, idOpcional($in['anio'] ?? null), textoOpcional($in, 'equipamiento'), $precio];
    $nombre = trim("{$marca} {$modelo} " . ($datos[2] ?? ''));

    if ($id === null) {
        $pdo->prepare("INSERT INTO catalogo_modelos (marca, modelo, version, carroceria, anio, equipamiento, precio_lista) VALUES (?, ?, ?, ?, ?, ?, ?)")
            ->execute($datos);
        $id = (int)$pdo->lastInsertId();
        auditar('Alta en catálogo', "Se agregó {$nombre} con precio de lista " . dinero($precio));
    } else {
        $anterior = obtenerCatalogo($id);
        if (!$anterior) fail('El modelo no existe.', 404);
        $pdo->prepare("UPDATE catalogo_modelos SET marca = ?, modelo = ?, version = ?, carroceria = ?, anio = ?, equipamiento = ?, precio_lista = ? WHERE id_modelo = ?")
            ->execute([...$datos, $id]);
        if ($anterior[0]['precioLista'] != $precio) {
            auditar('Cambio de precio de lista', "{$nombre}: " . dinero($anterior[0]['precioLista']) . ' → ' . dinero($precio));
        } else {
            auditar('Edición de catálogo', "Se actualizó la ficha de {$nombre}");
        }
    }
    return obtenerCatalogo($id)[0];
}

function cambiarEstadoModelo(int $id, array $in): array {
    $estado = ($in['estado'] ?? '') === 'inactivo' ? 'inactivo' : 'activo';
    db()->prepare("UPDATE catalogo_modelos SET estado = ? WHERE id_modelo = ?")->execute([$estado, $id]);
    $modelo = obtenerCatalogo($id);
    if (!$modelo) fail('El modelo no existe.', 404);
    auditar('Edición de catálogo', "{$modelo[0]['marca']} {$modelo[0]['modelo']} marcado como {$estado}");
    return $modelo[0];
}

/* ==========================================================================
   INVENTARIO
   ========================================================================== */

// Existencias por sucursal con días en patio; con $ids sólo regresa esos registros de inventarios
function obtenerInventario(?array $ids = null): array {
    if ($ids === []) return [];
    $filtro = $ids !== null ? " WHERE i.id_inventario IN (" . implode(',', array_fill(0, count($ids), '?')) . ")" : "";
    $stmt = db()->prepare("
        SELECT i.id_inventario, i.id_sucursal, i.id_producto, i.stock_actual, i.stock_minimo,
               DATEDIFF(NOW(), i.fecha_ingreso) AS dias_patio,
               p.nombre, p.tipo, COALESCE(NULLIF(p.marca, ''), 'Genérico') AS marca, p.precio_base, p.costo_adquisicion,
               c.nombre_categoria
        FROM inventarios i
        JOIN productos p ON p.id_producto = i.id_producto
        JOIN categorias c ON c.id_categoria = p.id_categoria{$filtro}
        ORDER BY p.nombre, i.id_sucursal");
    $stmt->execute($ids ?? []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_inventario'],
        'productoId' => (string)$r['id_producto'],
        'sucursalId' => (string)$r['id_sucursal'],
        'producto' => $r['nombre'],
        'tipo' => $r['tipo'],
        'marca' => $r['marca'],
        'categoria' => $r['nombre_categoria'],
        'precio' => (float)$r['precio_base'],
        'costo' => $r['costo_adquisicion'] !== null ? (float)$r['costo_adquisicion'] : null,
        'stockActual' => (int)$r['stock_actual'],
        'stockMinimo' => (int)$r['stock_minimo'],
        'diasPatio' => (int)$r['stock_actual'] > 0 ? (int)$r['dias_patio'] : 0,
    ], $stmt->fetchAll());
}

// Id de una categoría por nombre; la crea si todavía no existe
function idCategoria(string $nombre): int {
    $pdo = db();
    $stmt = $pdo->prepare("SELECT id_categoria FROM categorias WHERE nombre_categoria = ?");
    $stmt->execute([$nombre]);
    $id = $stmt->fetchColumn();
    if ($id !== false) return (int)$id;
    $pdo->prepare("INSERT INTO categorias (nombre_categoria) VALUES (?)")->execute([$nombre]);
    return (int)$pdo->lastInsertId();
}

// Inserta un producto nuevo y regresa su id (el código de barras lo genera el trigger de ajustes.sql)
function insertarProducto(array $p): int {
    $pdo = db();
    $pdo->prepare("
        INSERT INTO productos (id_categoria, codigo_barras, nombre, precio_base, costo_adquisicion, marca, modelo, anio, tipo, color, color_interior)
        VALUES (?, '', ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ")->execute([
        $p['id_categoria'], $p['nombre'], $p['precio'], $p['costo'] ?? null, $p['marca'], $p['modelo'] ?? $p['nombre'],
        $p['anio'] ?? null, $p['tipo'], $p['color'] ?? null, $p['color_interior'] ?? null,
    ]);
    $id = (int)$pdo->lastInsertId();
    // Sin el trigger el código queda vacío: se asigna uno propio para no chocar con el UNIQUE
    $pdo->prepare("UPDATE productos SET codigo_barras = ? WHERE id_producto = ? AND codigo_barras = ''")
        ->execute(["KRM-ADM-{$id}", $id]);
    return $id;
}

// Alta rápida de artículo: crea el producto y su existencia en la sucursal elegida
function crearArticulo(array $in): array {
    $pdo = db();
    $nombre = texto($in, 'producto', 'modelo / nombre');
    $marca = texto($in, 'marca', 'marca');
    $categoria = texto($in, 'categoria', 'categoría');
    $idSucursal = idOpcional($in['sucursalId'] ?? null) ?? fail('Selecciona una sucursal.');
    $precio = (float)($in['precio'] ?? 0);
    if ($precio <= 0) fail('El precio de venta debe ser mayor a 0.');
    $costo = ($in['costo'] ?? '') !== '' ? (float)$in['costo'] : null;
    $tipo = ($in['tipo'] ?? '') === 'Refaccion' ? 'refaccion' : (stripos($categoria, 'moto') !== false ? 'moto' : 'auto');

    $pdo->beginTransaction();
    $idProducto = insertarProducto([
        'id_categoria' => idCategoria($categoria), 'nombre' => $nombre, 'precio' => $precio, 'costo' => $costo,
        'marca' => $marca, 'tipo' => $tipo,
    ]);
    $pdo->prepare("INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo) VALUES (?, ?, ?, ?)")
        ->execute([$idSucursal, $idProducto, max(0, (int)($in['stockActual'] ?? 0)), max(0, (int)($in['stockMinimo'] ?? 0))]);
    $idInventario = (int)$pdo->lastInsertId();
    auditar('Alta de artículo', "Se registró {$marca} {$nombre} en " . nombreSucursal($idSucursal) . ' con precio ' . dinero($precio));
    $pdo->commit();

    return obtenerInventario([$idInventario])[0];
}

// Cambia precio base y costo de los productos indicados (queda registrado en auditoría)
function actualizarPrecioProducto(array $in): array {
    $pdo = db();
    $ids = array_map('intval', is_array($in['ids'] ?? null) ? $in['ids'] : []);
    if (!$ids) fail('No se indicó ningún producto.');
    $precio = (float)($in['precio'] ?? 0);
    if ($precio <= 0) fail('El precio base debe ser mayor a 0.');
    $costo = ($in['costo'] ?? '') !== '' ? (float)$in['costo'] : null;

    $buscar = $pdo->prepare("SELECT nombre, precio_base, costo_adquisicion FROM productos WHERE id_producto = ?");
    $actualizar = $pdo->prepare("UPDATE productos SET precio_base = ?, costo_adquisicion = ? WHERE id_producto = ?");
    $pdo->beginTransaction();
    foreach ($ids as $idProducto) {
        $buscar->execute([$idProducto]);
        $p = $buscar->fetch();
        if (!$p) continue;
        $actualizar->execute([$precio, $costo, $idProducto]);
        if ((float)$p['precio_base'] != $precio) {
            auditar('Cambio de precio base', "{$p['nombre']}: " . dinero($p['precio_base']) . ' → ' . dinero($precio));
        }
        if ($p['costo_adquisicion'] === null ? $costo !== null : (float)$p['costo_adquisicion'] != $costo) {
            auditar('Cambio de costo', "{$p['nombre']}: costo de adquisición " . ($costo !== null ? dinero($costo) : 'sin capturar'));
        }
    }
    $pdo->commit();
    return obtenerInventario();
}

/* ==========================================================================
   VENTAS, COMPROBANTES Y CORTES DE CAJA
   ========================================================================== */

// Una fila por venta: productos, VIN, método de liquidación y margen bruto (si se conoce el costo)
function obtenerVentas(?int $id = null): array {
    $stmt = db()->prepare("
        SELECT v.id_venta, DATE_FORMAT(v.fecha_hora, '%Y-%m-%dT%H:%i:%s') AS fecha, v.id_sucursal, v.id_caja,
               v.total, v.ticket_numero, v.id_cliente,
               MAX(u.nombre) AS cajero, MAX(cl.nombre) AS cliente, MAX(mp.nombre_metodo) AS metodo, MAX(cj.numero_caja) AS caja,
               GROUP_CONCAT(p.nombre ORDER BY d.id_detalle SEPARATOR ', ') AS productos,
               GROUP_CONCAT(d.vin ORDER BY d.id_detalle SEPARATOR ', ') AS vins,
               COALESCE(SUM(d.cantidad), 0) AS unidades,
               COALESCE(SUM(IF(p.tipo = 'refaccion', 0, d.cantidad)), 0) AS vehiculos,
               MIN(p.marca) AS marca, MIN(c.nombre_categoria) AS categoria,
               IF(SUM(p.costo_adquisicion IS NULL) > 0, NULL, SUM((d.precio_unitario - p.costo_adquisicion) * d.cantidad)) AS margen
        FROM ventas v
        JOIN usuarios u ON u.id_usuario = v.id_usuario
        LEFT JOIN clientes cl ON cl.id_cliente = v.id_cliente
        LEFT JOIN metodos_pago mp ON mp.id_metodo_pago = v.id_metodo_pago
        LEFT JOIN cajas cj ON cj.id_caja = v.id_caja
        LEFT JOIN detalle_ventas d ON d.id_venta = v.id_venta
        LEFT JOIN productos p ON p.id_producto = d.id_producto
        LEFT JOIN categorias c ON c.id_categoria = p.id_categoria" . ($id !== null ? " WHERE v.id_venta = ?" : "") . "
        GROUP BY v.id_venta, v.fecha_hora, v.id_sucursal, v.id_caja, v.total, v.ticket_numero, v.id_cliente
        ORDER BY v.fecha_hora DESC");
    $stmt->execute($id !== null ? [$id] : []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_venta'],
        'folio' => sprintf('KRM-%02d-%06d', $r['id_sucursal'], $r['id_venta']),
        'ticket' => $r['ticket_numero'] !== null ? (int)$r['ticket_numero'] : null,
        'fecha' => $r['fecha'],
        'sucursalId' => (string)$r['id_sucursal'],
        'caja' => $r['caja'] !== null ? (int)$r['caja'] : null,
        'responsable' => $r['cajero'] ?? '—',
        'cliente' => $r['cliente'] ?? 'Público general',
        'producto' => $r['productos'] ?? '—',
        'vin' => $r['vins'] ?? '',
        'unidades' => (int)$r['unidades'],
        'vehiculos' => (int)$r['vehiculos'],
        'marca' => $r['marca'] ?? '',
        'categoria' => $r['categoria'] ?? '',
        'credito' => $r['id_cliente'] !== null,
        'metodo' => $r['metodo'] ?? '—',
        'margen' => $r['margen'] !== null ? (float)$r['margen'] : null,
        'total' => (float)$r['total'],
    ], $stmt->fetchAll());
}

// Datos completos para reemitir un ticket o contrato: venta, sucursal, líneas y crédito del cliente
function obtenerDetalleVenta(int $id): array {
    $pdo = db();
    $venta = obtenerVentas($id);
    if (!$venta) fail('La venta no existe.', 404);
    $venta = $venta[0];

    $stmt = $pdo->prepare("SELECT efectivo_recibido, cambio, id_cliente FROM ventas WHERE id_venta = ?");
    $stmt->execute([$id]);
    $pago = $stmt->fetch();

    $stmt = $pdo->prepare("
        SELECT p.nombre, p.marca, d.cantidad, d.precio_unitario, d.subtotal_linea, d.vin, d.color_interior
        FROM detalle_ventas d JOIN productos p ON p.id_producto = d.id_producto
        WHERE d.id_venta = ? ORDER BY d.id_detalle");
    $stmt->execute([$id]);
    $lineas = array_map(fn($l) => [
        'producto' => trim(($l['marca'] ?? '') . ' ' . $l['nombre']),
        'cantidad' => (int)$l['cantidad'],
        'precio' => (float)$l['precio_unitario'],
        'subtotal' => (float)$l['subtotal_linea'],
        'vin' => $l['vin'] ?? '',
        'colorInterior' => $l['color_interior'] ?? '',
    ], $stmt->fetchAll());

    $cliente = null;
    if ($pago['id_cliente'] !== null) {
        $stmt = $pdo->prepare("SELECT nombre, rfc_ine, celular, email, total_adeudo, monto_abono, enganche, abonos_totales FROM clientes WHERE id_cliente = ?");
        $stmt->execute([$pago['id_cliente']]);
        $cliente = $stmt->fetch() ?: null;
    }

    return $venta + [
        'sucursal' => obtenerSucursales((int)$venta['sucursalId'])[0] ?? null,
        'efectivoRecibido' => (float)($pago['efectivo_recibido'] ?? 0),
        'cambio' => (float)($pago['cambio'] ?? 0),
        'lineas' => $lineas,
        'clienteCredito' => $cliente,
    ];
}

// Corte por terminal: ventas agrupadas por día y caja (apertura = primer ticket, corte = último)
function obtenerCortes(): array {
    $filas = db()->query("
        SELECT DATE_FORMAT(DATE(v.fecha_hora), '%Y-%m-%dT00:00:00') AS dia, v.id_sucursal, v.id_caja,
               MAX(cj.numero_caja) AS caja, GROUP_CONCAT(DISTINCT u.nombre SEPARATOR ', ') AS cajeros,
               DATE_FORMAT(MIN(v.fecha_hora), '%H:%i') AS apertura, DATE_FORMAT(MAX(v.fecha_hora), '%H:%i') AS corte,
               COUNT(*) AS tickets, SUM(v.total) AS total,
               SUM(IF(v.id_cliente IS NULL, v.total, 0)) AS contado,
               SUM(IF(v.id_cliente IS NOT NULL, v.total, 0)) AS credito,
               SUM(COALESCE(v.efectivo_recibido, 0) - COALESCE(v.cambio, 0)) AS efectivo
        FROM ventas v
        JOIN usuarios u ON u.id_usuario = v.id_usuario
        LEFT JOIN cajas cj ON cj.id_caja = v.id_caja
        GROUP BY DATE(v.fecha_hora), v.id_sucursal, v.id_caja
        ORDER BY DATE(v.fecha_hora) DESC, v.id_sucursal, caja
    ")->fetchAll();
    return array_map(fn($r) => [
        'dia' => $r['dia'],
        'sucursalId' => (string)$r['id_sucursal'],
        'caja' => $r['caja'] !== null ? (int)$r['caja'] : null,
        'cajeros' => $r['cajeros'],
        'apertura' => $r['apertura'],
        'corte' => $r['corte'],
        'tickets' => (int)$r['tickets'],
        'contado' => (float)$r['contado'],
        'credito' => (float)$r['credito'],
        'efectivo' => (float)$r['efectivo'],
        'total' => (float)$r['total'],
    ], $filas);
}

/* ==========================================================================
   PEDIDOS A PROVEEDORES
   ========================================================================== */

function obtenerPedidos(?int $id = null): array {
    $pdo = db();
    $stmt = $pdo->prepare("
        SELECT id_pedido, folio, proveedor, id_sucursal, estado,
               DATE_FORMAT(fecha_emision, '%Y-%m-%dT00:00:00') AS fecha_emision,
               DATE_FORMAT(fecha_eta, '%Y-%m-%dT00:00:00') AS fecha_eta,
               DATE_FORMAT(fecha_recepcion, '%Y-%m-%dT%H:%i:%s') AS fecha_recepcion
        FROM pedidos" . ($id !== null ? " WHERE id_pedido = ?" : "") . "
        ORDER BY fecha_emision DESC, id_pedido DESC");
    $stmt->execute($id !== null ? [$id] : []);
    $pedidos = $stmt->fetchAll();
    if (!$pedidos) return [];

    $ids = array_column($pedidos, 'id_pedido');
    $stmt = $pdo->prepare("SELECT * FROM pedido_vehiculos WHERE id_pedido IN (" . implode(',', array_fill(0, count($ids), '?')) . ") ORDER BY id_pedido_vehiculo");
    $stmt->execute($ids);
    $vehiculos = [];
    foreach ($stmt->fetchAll() as $v) {
        $vehiculos[$v['id_pedido']][] = [
            'marca' => $v['marca'] ?? '',
            'modelo' => $v['modelo'],
            'anio' => $v['anio'] !== null ? (int)$v['anio'] : null,
            'version' => $v['version'] ?? '',
            'vin' => $v['vin'],
            'colorExterior' => $v['color_exterior'] ?? '',
            'colorInterior' => $v['color_interior'] ?? '',
            'equipamiento' => $v['equipamiento'] ?? '',
            'costoAdquisicion' => (float)$v['costo_adquisicion'],
            'precioProyectado' => (float)$v['precio_proyectado'],
        ];
    }

    return array_map(fn($p) => [
        'id' => (string)$p['id_pedido'],
        'folio' => $p['folio'],
        'proveedor' => $p['proveedor'],
        'sucursalId' => (string)$p['id_sucursal'],
        'fechaEmision' => $p['fecha_emision'],
        'fechaETA' => $p['fecha_eta'],
        'fechaRecepcion' => $p['fecha_recepcion'],
        'estado' => $p['estado'],
        'vehiculos' => $vehiculos[$p['id_pedido']] ?? [],
    ], $pedidos);
}

// Pedido existente o error 404
function pedidoOFallo(int $id): array {
    $pedido = obtenerPedidos($id);
    if (!$pedido) fail('El pedido no existe.', 404);
    return $pedido[0];
}

// Fecha 'YYYY-MM-DD' a partir del ISO que manda el navegador
function fecha(array $in, string $campo, string $etiqueta): string {
    $valor = substr(texto($in, $campo, $etiqueta), 0, 10);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $valor)) fail("La fecha {$etiqueta} no es válida.");
    return $valor;
}

// Alta (id = null) o edición de un pedido; los vehículos se reemplazan completos
function guardarPedido(?int $id, array $in): array {
    $pdo = db();
    $proveedor = texto($in, 'proveedor', 'proveedor');
    $idSucursal = idOpcional($in['sucursalId'] ?? null) ?? fail('Selecciona la sucursal de destino.');
    $emision = fecha($in, 'fechaEmision', 'de emisión');
    $eta = fecha($in, 'fechaETA', 'ETA');
    $vehiculos = is_array($in['vehiculos'] ?? null) ? $in['vehiculos'] : [];
    if (!$vehiculos) fail('El pedido debe incluir al menos un vehículo.');
    // Marca por defecto: primera palabra del proveedor ("Porsche AG" → Porsche)
    $marcaProveedor = explode(' ', $proveedor)[0];

    if ($id !== null) {
        $actual = pedidoOFallo($id);
        if (in_array($actual['estado'], ['recibido', 'cancelado'], true)) fail('Un pedido recibido o cancelado ya no se puede editar.');
    }

    $pdo->beginTransaction();
    if ($id === null) {
        $siguiente = (int)$pdo->query("SELECT COALESCE(MAX(CAST(SUBSTRING(folio, 4) AS UNSIGNED)), 1000) + 1 FROM pedidos WHERE folio LIKE 'PO-%'")->fetchColumn();
        $pdo->prepare("INSERT INTO pedidos (folio, proveedor, id_sucursal, fecha_emision, fecha_eta) VALUES (?, ?, ?, ?, ?)")
            ->execute(["PO-{$siguiente}", $proveedor, $idSucursal, $emision, $eta]);
        $id = (int)$pdo->lastInsertId();
        auditar('Alta de pedido', "Pedido PO-{$siguiente} a {$proveedor} con " . count($vehiculos) . ' vehículo(s)');
    } else {
        $pdo->prepare("UPDATE pedidos SET proveedor = ?, id_sucursal = ?, fecha_emision = ?, fecha_eta = ? WHERE id_pedido = ?")
            ->execute([$proveedor, $idSucursal, $emision, $eta, $id]);
        $pdo->prepare("DELETE FROM pedido_vehiculos WHERE id_pedido = ?")->execute([$id]);
        auditar('Edición de pedido', "Se actualizó el pedido {$actual['folio']}");
    }

    $insertar = $pdo->prepare("
        INSERT INTO pedido_vehiculos (id_pedido, marca, modelo, anio, version, vin, color_exterior, color_interior,
                                      equipamiento, costo_adquisicion, precio_proyectado)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($vehiculos as $v) {
        $modelo = texto($v, 'modelo', 'modelo');
        $vin = strtoupper(texto($v, 'vin', 'VIN'));
        if (strlen($vin) > 17) fail("El VIN {$vin} tiene más de 17 caracteres.");
        $insertar->execute([
            $id, trim((string)($v['marca'] ?? '')) ?: $marcaProveedor, $modelo,
            idOpcional($v['anio'] ?? null), trim((string)($v['version'] ?? '')), $vin,
            trim((string)($v['colorExterior'] ?? '')), trim((string)($v['colorInterior'] ?? '')),
            trim((string)($v['equipamiento'] ?? '')),
            (float)($v['costoAdquisicion'] ?? 0), (float)($v['precioProyectado'] ?? 0),
        ]);
    }
    $pdo->commit();

    return pedidoOFallo($id);
}

// Avanza o cancela un pedido (la recepción se hace con recibir_pedido porque mueve inventario)
function cambiarEstadoPedido(int $id, array $in): array {
    $estado = (string)($in['estado'] ?? '');
    if (!in_array($estado, ['solicitado', 'transito', 'patio', 'cancelado'], true)) fail('Estado de pedido no válido.');
    $pedido = pedidoOFallo($id);
    if (in_array($pedido['estado'], ['recibido', 'cancelado'], true)) fail('El pedido ya está cerrado.');
    db()->prepare("UPDATE pedidos SET estado = ? WHERE id_pedido = ?")->execute([$estado, $id]);
    auditar($estado === 'cancelado' ? 'Cancelación de pedido' : 'Avance de pedido', "Pedido {$pedido['folio']} pasó a {$estado}");
    return pedidoOFallo($id);
}

// Confirma la recepción: suma 1 a stock_actual por cada vehículo en la sucursal destino
// (si el modelo no existe en esa sucursal se da de alta el producto y su inventario)
function recibirPedido(int $id): array {
    $pdo = db();
    $pedido = pedidoOFallo($id);
    if (in_array($pedido['estado'], ['recibido', 'cancelado'], true)) fail('El pedido ya está cerrado.');
    $idSucursal = (int)$pedido['sucursalId'];

    $buscar = $pdo->prepare("
        SELECT i.id_inventario, i.id_producto
        FROM inventarios i
        JOIN productos p ON p.id_producto = i.id_producto
        WHERE i.id_sucursal = ? AND (p.nombre = ? OR p.modelo = ?)
        ORDER BY i.id_inventario LIMIT 1");
    // Si no había unidades en patio, la antigüedad empieza a contar desde hoy
    $sumar = $pdo->prepare("UPDATE inventarios SET fecha_ingreso = IF(stock_actual = 0, NOW(), fecha_ingreso), stock_actual = stock_actual + 1 WHERE id_inventario = ?");
    $costo = $pdo->prepare("UPDATE productos SET costo_adquisicion = ? WHERE id_producto = ?");
    $crear = $pdo->prepare("INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo) VALUES (?, ?, 1, 2)");

    $pdo->beginTransaction();
    $afectados = [];
    foreach ($pedido['vehiculos'] as $v) {
        $buscar->execute([$idSucursal, $v['modelo'], $v['modelo']]);
        $existente = $buscar->fetch();
        if ($existente) {
            $sumar->execute([$existente['id_inventario']]);
            $costo->execute([$v['costoAdquisicion'], $existente['id_producto']]);
            $idInventario = $existente['id_inventario'];
        } else {
            $idProducto = insertarProducto([
                'id_categoria' => idCategoria($v['marca'] ?: 'Vehículos'), 'nombre' => $v['modelo'],
                'precio' => $v['precioProyectado'], 'costo' => $v['costoAdquisicion'], 'marca' => $v['marca'], 'modelo' => $v['modelo'],
                'anio' => $v['anio'], 'tipo' => 'auto', 'color' => $v['colorExterior'], 'color_interior' => $v['colorInterior'],
            ]);
            $crear->execute([$idSucursal, $idProducto]);
            $idInventario = $pdo->lastInsertId();
        }
        $afectados[(int)$idInventario] = true;
    }
    $pdo->prepare("UPDATE pedidos SET estado = 'recibido', fecha_recepcion = NOW() WHERE id_pedido = ?")->execute([$id]);
    auditar('Recepción de pedido', "Pedido {$pedido['folio']} recibido en " . nombreSucursal($idSucursal) . ' (' . count($pedido['vehiculos']) . ' unidad(es))');
    $pdo->commit();

    return ['pedido' => pedidoOFallo($id), 'afectados' => obtenerInventario(array_keys($afectados))];
}

/* ==========================================================================
   AUDITORÍA
   ========================================================================== */

// Últimos 500 movimientos de la bitácora
function obtenerAuditoria(): array {
    $filas = db()->query("
        SELECT a.id_auditoria, DATE_FORMAT(a.fecha, '%Y-%m-%dT%H:%i:%s') AS fecha, a.accion, a.detalle, u.nombre
        FROM auditoria a
        LEFT JOIN usuarios u ON u.id_usuario = a.id_usuario
        ORDER BY a.fecha DESC, a.id_auditoria DESC
        LIMIT 500
    ")->fetchAll();
    return array_map(fn($r) => [
        'id' => (string)$r['id_auditoria'],
        'fecha' => $r['fecha'],
        'usuario' => $r['nombre'] ?? '—',
        'accion' => $r['accion'],
        'detalle' => $r['detalle'],
    ], $filas);
}
