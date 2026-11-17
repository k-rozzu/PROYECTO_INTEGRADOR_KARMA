<?php
declare(strict_types=1);

/* API del Panel de Gerente (Home/gerente.html) en PHP.
   Antes estas rutas vivían solo en el servidor Node (backend/server.js, puerto 3000), sin ninguna validación de sesión:
   cualquiera podía consultar o modificar el inventario y las cajas de cualquier sucursal, y en un hosting con Apache el
   panel no funcionaba porque el puerto 3000 no existe. Ahora usan la sesión del sistema (cookie KARMAPOS): solo un Gerente
   o el Administrador General con sucursal asignada, y SIEMPRE sobre su propia sucursal (la de la sesión, no la que mande
   el navegador). Las respuestas conservan el mismo formato que daba Node para no cambiar el panel.
     GET  ?action=sucursal | cajeros | cajas | productos | categorias | ventas
     POST ?action=crear_caja | estado_caja | asignar_cajero | crear_producto | actualizar_producto | retirar_producto | stock */
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
require_once __DIR__ . '/../PuntoDeVenta/conexion.php';
require_once __DIR__ . '/../Login/sesion_pos.php';

const GER_ROLES = ['Gerente', 'Administrador General', 'Admin_General'];
const GER_LECTURA = ['sucursal', 'cajeros', 'cajas', 'productos', 'categorias', 'ventas'];

// Responde en JSON con su código HTTP y termina
function gerResponder($datos, int $estado = 200): never {
    http_response_code($estado);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit;
}

// Error con el mismo formato que usaba el servidor Node: { mensaje }
function gerError(string $mensaje, int $estado = 400): never {
    gerResponder(['mensaje' => $mensaje], $estado);
}

// Cuerpo JSON de la petición
function gerEntrada(): array {
    $datos = json_decode((string)file_get_contents('php://input'), true);
    return is_array($datos) ? $datos : [];
}

// Entero estricto (como Number.isInteger del servidor Node); null si no lo es
function gerEntero($valor): ?int {
    if (is_int($valor)) return $valor;
    if (is_string($valor) && preg_match('/^-?\d+$/', trim($valor))) return (int)$valor;
    if (is_float($valor) && floor($valor) === $valor) return (int)$valor;
    return null;
}

// Gerente o Administrador con sesión, contraseña propia y sucursal asignada. Regresa el id de SU sucursal
function gerExigirSesion(): int {
    $u = posUsuarioValidado(db());
    if (!$u) gerResponder(['mensaje' => 'Inicia sesión para continuar.', 'sesion' => false], 401);
    if (posDebeCambiarPassword($u)) gerResponder(['mensaje' => 'Antes de continuar debes cambiar tu contraseña temporal.', 'cambiar_password' => true], 403);
    if (!in_array($u['nombre_rol'], GER_ROLES, true)) gerError('Tu rol no puede abrir el panel de gerente.', 403);
    if ($u['id_sucursal'] === null) gerError('Tu cuenta no tiene sucursal asignada.', 403);
    return (int)$u['id_sucursal'];
}

try {
    $sucursal = gerExigirSesion();
    $accion = (string)($_GET['action'] ?? '');
    // Protección CSRF: lo que modifica datos llega solo por POST con JSON desde este mismo sitio
    if (!in_array($accion, GER_LECTURA, true) && ($rechazo = posRechazoEscritura()) !== null) gerError($rechazo, 403);
    $in = gerEntrada();

    switch ($accion) {
        case 'sucursal':            gerSucursal($sucursal);
        case 'cajeros':             gerCajeros($sucursal);
        case 'cajas':               gerCajas($sucursal);
        case 'crear_caja':          gerCrearCaja($sucursal, $in);
        case 'estado_caja':         gerEstadoCaja($sucursal, $in);
        case 'asignar_cajero':      gerAsignarCajero($sucursal, $in);
        case 'productos':           gerProductos($sucursal);
        case 'categorias':          gerCategorias();
        case 'crear_producto':      gerGuardarProducto($sucursal, null, $in);
        case 'actualizar_producto': gerGuardarProducto($sucursal, gerEntero($in['id'] ?? null) ?? gerError('Datos inválidos'), $in);
        case 'retirar_producto':    gerRetirarProducto($sucursal, $in);
        case 'stock':               gerActualizarStock($sucursal, $in);
        case 'ventas':              gerVentas($sucursal);
        default:                    gerError('Acción no reconocida.', 404);
    }
} catch (Throwable $e) {
    try { if (db()->inTransaction()) db()->rollBack(); } catch (Throwable) {}
    error_log('[Gerente API] ' . ($accion ?? '') . ': ' . $e->getMessage());
    gerError('Error interno del servidor', 500);
}

/* ===== Sucursal y cajeros ===== */

function gerSucursal(int $sucursal): never {
    $stmt = db()->prepare("SELECT id_sucursal AS id, nombre, direccion, telefono, estado FROM sucursales WHERE id_sucursal = ?");
    $stmt->execute([$sucursal]);
    $fila = $stmt->fetch();
    if (!$fila) gerError('Sucursal no encontrada', 404);
    gerResponder($fila);
}

function gerCajeros(int $sucursal): never {
    $stmt = db()->prepare("
        SELECT u.id_usuario AS id, u.nombre, u.correo, u.estado
        FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
        WHERE r.nombre_rol = 'Cajero' AND u.id_sucursal = ?");
    $stmt->execute([$sucursal]);
    gerResponder($stmt->fetchAll());
}

/* ===== Cajas ===== */

function gerCajas(int $sucursal): never {
    $stmt = db()->prepare("
        SELECT c.id_caja AS id, CONCAT('Caja ', c.numero_caja) AS nombre,
               CASE WHEN c.estado = 'mantenimiento' THEN 'inactivo' ELSE 'activo' END AS estado,
               c.id_usuario_asignado AS cajeroId
        FROM cajas c WHERE c.id_sucursal = ? ORDER BY c.numero_caja");
    $stmt->execute([$sucursal]);
    gerResponder($stmt->fetchAll());
}

// Revisa que el cajero sea de la sucursal, esté activo y no tenga otra caja. Regresa el error o null
function gerValidarCajero(int $idCajero, int $sucursal, int $idCajaActual): ?string {
    $stmt = db()->prepare("
        SELECT 1 FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.id_usuario = ? AND u.id_sucursal = ? AND r.nombre_rol = 'Cajero' AND u.estado = 'activo'");
    $stmt->execute([$idCajero, $sucursal]);
    if (!$stmt->fetchColumn()) return 'El cajero no pertenece a esta sucursal o está inactivo';
    $stmt = db()->prepare("SELECT numero_caja FROM cajas WHERE id_usuario_asignado = ? AND id_caja <> ?");
    $stmt->execute([$idCajero, $idCajaActual]);
    $otra = $stmt->fetchColumn();
    return $otra !== false ? "Ese cajero ya está asignado a la Caja {$otra}" : null;
}

// Id de cajero opcional (null, "" o ausente = sin cajero)
function gerCajeroOpcional(array $in): ?int {
    $valor = $in['cajeroId'] ?? null;
    if ($valor === null || $valor === '') return null;
    return gerEntero($valor) ?? gerError('Cajero inválido');
}

function gerCrearCaja(int $sucursal, array $in): never {
    $numero = gerEntero($in['numero'] ?? null);
    if ($numero === null || $numero < 1) gerError('El número de caja debe ser un entero mayor a 0');
    $cajero = gerCajeroOpcional($in);
    $stmt = db()->prepare("SELECT 1 FROM cajas WHERE id_sucursal = ? AND numero_caja = ?");
    $stmt->execute([$sucursal, $numero]);
    if ($stmt->fetchColumn()) gerError("Ya existe la Caja {$numero} en esta sucursal", 409);
    if ($cajero !== null && ($error = gerValidarCajero($cajero, $sucursal, 0)) !== null) gerError($error, 409);
    db()->prepare("INSERT INTO cajas (id_sucursal, numero_caja, id_usuario_asignado) VALUES (?, ?, ?)")
        ->execute([$sucursal, $numero, $cajero]);
    gerResponder(['id' => (int)db()->lastInsertId()], 201);
}

function gerEstadoCaja(int $sucursal, array $in): never {
    $idCaja = gerEntero($in['id'] ?? null);
    $estado = $in['estado'] ?? '';
    if ($idCaja === null || !in_array($estado, ['activo', 'inactivo'], true)) gerError('Datos inválidos');
    $stmt = db()->prepare("SELECT estado FROM cajas WHERE id_caja = ? AND id_sucursal = ?");
    $stmt->execute([$idCaja, $sucursal]);
    $actual = $stmt->fetchColumn();
    if ($actual === false) gerError('Caja no encontrada en esta sucursal', 404);
    if ($estado === 'inactivo') {
        if ($actual === 'abierta') gerError('La caja está abierta. Pide que la cierren antes de desactivarla.', 409);
        db()->prepare("UPDATE cajas SET estado = 'mantenimiento' WHERE id_caja = ? AND id_sucursal = ?")->execute([$idCaja, $sucursal]);
    } elseif ($actual === 'mantenimiento') {
        db()->prepare("UPDATE cajas SET estado = 'cerrada' WHERE id_caja = ? AND id_sucursal = ?")->execute([$idCaja, $sucursal]);
    }
    gerResponder(['mensaje' => 'Estado actualizado']);
}

function gerAsignarCajero(int $sucursal, array $in): never {
    $idCaja = gerEntero($in['id'] ?? null);
    if ($idCaja === null) gerError('Datos inválidos');
    $cajero = gerCajeroOpcional($in);
    $stmt = db()->prepare("SELECT 1 FROM cajas WHERE id_caja = ? AND id_sucursal = ?");
    $stmt->execute([$idCaja, $sucursal]);
    if (!$stmt->fetchColumn()) gerError('Caja no encontrada en esta sucursal', 404);
    if ($cajero !== null && ($error = gerValidarCajero($cajero, $sucursal, $idCaja)) !== null) gerError($error, 409);
    db()->prepare("UPDATE cajas SET id_usuario_asignado = ? WHERE id_caja = ? AND id_sucursal = ?")->execute([$cajero, $idCaja, $sucursal]);
    gerResponder(['mensaje' => 'Cajero asignado']);
}

/* ===== Productos e inventario de la sucursal ===== */

function gerProductos(int $sucursal): never {
    $stmt = db()->prepare("
        SELECT p.id_producto AS id, p.nombre, p.marca, p.descripcion,
               CASE p.tipo WHEN 'auto' THEN 'vehiculo' ELSE p.tipo END AS tipo,
               c.nombre_categoria AS categoria, p.precio_base AS precio,
               i.stock_actual AS stockActual, i.stock_minimo AS stockMinimo
        FROM inventarios i
        JOIN productos p ON p.id_producto = i.id_producto
        JOIN categorias c ON c.id_categoria = p.id_categoria
        WHERE i.id_sucursal = ? AND i.estado = 'activo'");
    $stmt->execute([$sucursal]);
    gerResponder($stmt->fetchAll());
}

function gerCategorias(): never {
    gerResponder(db()->query("SELECT id_categoria AS id, nombre_categoria AS nombre FROM categorias ORDER BY nombre_categoria")->fetchAll());
}

// Alta (id null) o edición de un producto y de su inventario en la sucursal del gerente
function gerGuardarProducto(int $sucursal, ?int $idProducto, array $in): never {
    $tipo = ['vehiculo' => 'auto', 'moto' => 'moto', 'refaccion' => 'refaccion'][$in['tipo'] ?? ''] ?? null;
    $marca = trim((string)($in['marca'] ?? ''));
    $nombre = trim((string)($in['nombre'] ?? ''));
    $idCategoria = gerEntero($in['idCategoria'] ?? null);
    $precio = is_numeric($in['precio'] ?? null) ? (float)$in['precio'] : 0.0;
    $stock = gerEntero($in['stockActual'] ?? null);
    $minimo = gerEntero($in['stockMinimo'] ?? null);
    $descripcion = trim((string)($in['descripcion'] ?? '')) ?: null;

    if (!$tipo || $marca === '' || $nombre === '') gerError('Faltan datos del producto');
    if ($idCategoria === null) gerError('Categoría o sucursal inválida');
    if (!($precio > 0)) gerError('El precio debe ser mayor a 0');
    if ($stock === null || $stock < 0 || $minimo === null || $minimo < 0) gerError('El stock debe ser un entero de 0 o más');
    if (mb_strlen($nombre) > 150 || mb_strlen($marca) > 80) gerError('El nombre o la marca son demasiado largos');

    $pdo = db();
    $pdo->beginTransaction();
    if ($idProducto === null) {
        // codigo_barras es obligatorio y único: se genera
        $pdo->prepare("
            INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, tipo)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
            ->execute([$idCategoria, 'KRM-' . strtoupper($tipo) . '-' . (int)(microtime(true) * 1000), $nombre, $descripcion, $precio, $marca, $nombre, $tipo]);
        $nuevo = (int)$pdo->lastInsertId();
        $pdo->prepare("INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo) VALUES (?, ?, ?, ?)")
            ->execute([$sucursal, $nuevo, $stock, $minimo]);
        $pdo->commit();
        gerResponder(['id' => $nuevo], 201);
    }

    $stmt = $pdo->prepare("SELECT 1 FROM inventarios WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'");
    $stmt->execute([$idProducto, $sucursal]);
    if (!$stmt->fetchColumn()) { $pdo->rollBack(); gerError('Producto no encontrado en esta sucursal', 404); }
    $pdo->prepare("
        UPDATE productos
           SET modelo = IF(modelo = nombre, ?, modelo), nombre = ?, marca = ?, id_categoria = ?, precio_base = ?, tipo = ?, descripcion = ?
         WHERE id_producto = ?")
        ->execute([$nombre, $nombre, $marca, $idCategoria, $precio, $tipo, $descripcion, $idProducto]);
    $pdo->prepare("UPDATE inventarios SET stock_actual = ?, stock_minimo = ? WHERE id_producto = ? AND id_sucursal = ?")
        ->execute([$stock, $minimo, $idProducto, $sucursal]);
    $pdo->commit();
    gerResponder(['mensaje' => 'Producto actualizado']);
}

// Retira un producto de la sucursal (queda inactivo en su inventario; no se borra nada)
function gerRetirarProducto(int $sucursal, array $in): never {
    $idProducto = gerEntero($in['id'] ?? null);
    if ($idProducto === null) gerError('Datos inválidos');
    $stmt = db()->prepare("UPDATE inventarios SET estado = 'inactivo' WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'");
    $stmt->execute([$idProducto, $sucursal]);
    if ($stmt->rowCount() === 0) gerError('Producto no encontrado en esta sucursal', 404);
    gerResponder(['mensaje' => 'Producto desactivado']);
}

function gerActualizarStock(int $sucursal, array $in): never {
    $idProducto = gerEntero($in['id'] ?? null);
    $stock = gerEntero($in['stockActual'] ?? null);
    if ($idProducto === null || $stock === null) gerError('Datos inválidos');
    if ($stock < 0) gerError('El stock no puede ser negativo');
    $stmt = db()->prepare("SELECT 1 FROM inventarios WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'");
    $stmt->execute([$idProducto, $sucursal]);
    if (!$stmt->fetchColumn()) gerError('Producto no encontrado en esta sucursal', 404);
    db()->prepare("UPDATE inventarios SET stock_actual = ? WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'")
        ->execute([$stock, $idProducto, $sucursal]);
    gerResponder(['mensaje' => 'Stock actualizado']);
}

/* ===== Ventas de los últimos 6 meses (una fila por producto vendido) ===== */

function gerVentas(int $sucursal): never {
    $stmt = db()->prepare("
        SELECT CONCAT('V', v.id_venta, '-', d.id_detalle) AS id,
               DATE_FORMAT(v.fecha_hora, '%Y-%m-%dT%H:%i:%s') AS fecha,
               u.id_usuario AS cajeroId, u.nombre AS cajeroNombre,
               p.id_producto AS productoId, p.nombre AS productoNombre, p.marca,
               d.subtotal_linea AS total, d.cantidad,
               CASE
                   WHEN m.nombre_metodo = 'Efectivo' THEN 'efectivo'
                   WHEN m.nombre_metodo LIKE 'Tarjeta%' THEN 'tarjeta'
                   WHEN m.nombre_metodo = 'Transferencia' THEN 'transferencia'
                   ELSE LOWER(m.nombre_metodo)
               END AS metodoPago
        FROM ventas v
        JOIN detalle_ventas d ON d.id_venta = v.id_venta
        JOIN productos p ON p.id_producto = d.id_producto
        JOIN usuarios u ON u.id_usuario = v.id_usuario
        JOIN metodos_pago m ON m.id_metodo_pago = v.id_metodo_pago
        WHERE v.id_sucursal = ?
          AND v.fecha_hora >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 5 MONTH)
        ORDER BY v.fecha_hora DESC");
    $stmt->execute([$sucursal]);
    gerResponder($stmt->fetchAll());
}
