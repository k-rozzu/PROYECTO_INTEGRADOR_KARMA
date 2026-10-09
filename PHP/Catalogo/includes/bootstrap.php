<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — arranque común de TODAS las páginas y de api.php
   - Reutiliza la conexión PDO del Punto de Venta (PHP/PuntoDeVenta/conexion.php → db()), misma base pos_multisede.
   - Sesión propia de CLIENTES (cookie KARMACLIENTE). Es independiente de la sesión del POS (KARMAPOS):
     un cliente del catálogo jamás obtiene acceso al Punto de Venta.
   - Sucursal elegida (Manzanillo / Colima): define inventario, recogida, pedidos y citas.
   ===================================================================================== */

require_once dirname(__DIR__, 2) . '/PuntoDeVenta/conexion.php';

// Hora de México para citas, pedidos y textos (no depende del php.ini de XAMPP)
date_default_timezone_set('America/Mexico_City');

// ===== CONFIGURACIÓN DEL CATÁLOGO =====
const CAT_SESION = 'KARMACLIENTE';              // cookie de sesión de clientes
const CAT_COOKIE_SUCURSAL = 'karma_sucursal';    // recuerda la sucursal elegida (1 año)
const CAT_MARCAS = ['Audi', 'Porsche', 'Ducati'];
const CAT_ENVIO_COSTO = 199.00;                  // envío a domicilio (refacciones / accesorios)
const CAT_ENVIO_GRATIS_DESDE = 3000.00;          // envío gratis a partir de este subtotal
const CAT_MAX_POR_PRODUCTO = 20;                 // máximo de piezas iguales por pedido
const CAT_TASA_ANUAL = 18.0;                     // misma tasa que el módulo de crédito del POS
const CAT_COMISION_APERTURA = 0.02;              // misma comisión por apertura que el POS
const CAT_PLAZOS = [12, 24, 36, 48, 60];         // mismos plazos que el POS
// SERVICIOS QUE MANEJA LA AGENCIA (los mismos nombres de servicios.php). Para agregar o quitar uno, cámbialo aquí.
// Se agregan a una visita o apartado de un vehículo del catálogo (casillas "Servicios adicionales" de agendar.php)
const CAT_SERVICIOS_COMPRA = ['Seguro Automotriz de Cobertura Amplia', 'Seguro de Vida y Desempleo', 'Seguro de Llantas y Rines',
    'Gestoría de Placas y Alta Vehicular', 'Tenencia / Refrendo Vehicular', 'Plan de Mantenimiento Prepagado', 'Garantía Extendida',
    'Accesorios Originales e Instalación', 'Película de Seguridad y/o Polarizado'];
// Tipos de cita de servicio de taller, con el vehículo del cliente (citas.tipo_servicio)
const CAT_SERVICIOS_TALLER = ['Orden de Servicio de Taller', 'Plan de Mantenimiento Prepagado', 'Garantía Extendida',
    'Accesorios Originales e Instalación', 'Película de Seguridad y/o Polarizado', 'Verificación Vehicular (Holograma 00)'];
// Imagen de respaldo si un producto no tiene imagen (cámbiala aquí si lo deseas)
const CAT_IMAGEN_RESPALDO = 'assets/Catalogo/banners/concesionario.webp';

// URL de la raíz del proyecto (ej. /PROYECTO_INTEGRADOR_KARMA/) para assets, CSS y JS. Se calcula con la ruta del
// script que atiende la petición (las páginas del catálogo y api.php viven en PHP/Catalogo/), así las rutas son
// absolutas y funcionan igual desde cualquier página, desde el JS que pinta tarjetas o con URLs como index.php/algo.
function catRaizWeb(): string {
    $script = str_replace('\\', '/', (string)($_SERVER['SCRIPT_NAME'] ?? ''));
    $raiz = trim(str_replace('\\', '/', dirname($script, 3)), '/');
    if ($script === '' || $raiz === '.') return '../../';
    return '/' . ($raiz === '' ? '' : implode('/', array_map('rawurlencode', explode('/', $raiz))) . '/');
}
define('CAT_RAIZ', catRaizWeb());

// ===== SESIÓN DEL CLIENTE =====
function catIniciarSesion(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    ini_set('session.use_strict_mode', '1');
    session_name(CAT_SESION);
    session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'httponly' => true, 'samesite' => 'Lax']);
    session_start();
}
catIniciarSesion();

// ===== UTILIDADES DE SALIDA =====

// Escapa texto para HTML
function e(?string $texto): string {
    return htmlspecialchars((string)$texto, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

// Archivo real de una ruta de assets: la ruta tal cual o, si no existe, el mismo nombre con otra extensión de imagen
// (ej. la BD dice a3.webp y en la carpeta hay a3.png). Devuelve null si no hay ningún archivo.
function catArchivoAsset(string $ruta): ?string {
    $raiz = dirname(__DIR__, 3) . '/';
    if (is_file($raiz . $ruta)) return $ruta;
    $base = preg_replace('/\.(webp|png|jpe?g|gif|avif)$/i', '', $ruta);
    foreach (['webp', 'png', 'jpg', 'jpeg', 'avif', 'gif'] as $ext) {
        if (is_file("{$raiz}{$base}.{$ext}")) return "{$base}.{$ext}";
    }
    return null;
}

// URL pública de un archivo de assets guardado en la BD (ej. assets/Catalogo/vehiculos/audi/a3.webp).
// IMÁGENES: las rutas se guardan relativas a la raíz del proyecto; aquí se convierten en URL absoluta (CAT_RAIZ).
// Si el archivo no existe con esa extensión se usa el que sí exista; si no hay ninguno, la imagen de respaldo.
function catAsset(?string $ruta, string $respaldo = CAT_IMAGEN_RESPALDO): string {
    $ruta = trim((string)$ruta);
    if ($ruta === '' || str_contains($ruta, '..') || !preg_match('#^assets/[A-Za-z0-9_\-/. ]+$#', $ruta)) {
        $ruta = $respaldo;
    }
    $ruta = catArchivoAsset($ruta) ?? catArchivoAsset($respaldo) ?? $respaldo;
    // ?v=fecha del archivo: si reemplazas una imagen con el mismo nombre, el navegador descarga la nueva
    $archivo = dirname(__DIR__, 3) . '/' . $ruta;
    $version = is_file($archivo) ? '?v=' . filemtime($archivo) : '';
    return CAT_RAIZ . str_replace(' ', '%20', $ruta) . $version;
}

// Miniatura ligera (480 px) para menús y carruseles: assets/.../miniaturas/archivo.webp si existe; si no, la imagen normal.
// Para cambiarla, reemplaza el archivo dentro de la carpeta miniaturas/ junto a la imagen original.
function catMiniatura(?string $ruta): string {
    $ruta = trim((string)$ruta);
    if ($ruta !== '' && !str_contains($ruta, '..')) {
        $mini = catArchivoAsset(dirname($ruta) . '/miniaturas/' . basename($ruta));
        if ($mini) return catAsset($mini);
    }
    return catAsset($ruta);
}

// Formato de precio en pesos: vehículos sin centavos, refacciones con centavos
function catPrecio(float $monto, bool $centavos = false): string {
    return '$' . number_format($monto, $centavos ? 2 : 0, '.', ',');
}

// Fecha legible en español (ej. 15 oct 2026, 11:30)
function catFecha(?string $fecha, bool $conHora = true): string {
    if (!$fecha) return '—';
    $t = strtotime($fecha);
    if (!$t) return '—';
    $meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    $texto = date('j', $t) . ' ' . $meses[(int)date('n', $t) - 1] . ' ' . date('Y', $t);
    return $conHora ? $texto . ', ' . date('H:i', $t) : $texto;
}

// ===== PROTECCIÓN CSRF (token por sesión que el JS manda en la cabecera X-CSRF-Token) =====
function catCsrf(): string {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf'];
}
function catCsrfValido(): bool {
    $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
    return is_string($token) && $token !== '' && hash_equals(catCsrf(), $token);
}

// ===== SUCURSALES =====

// Sucursales activas con sus datos de contacto (de la tabla sucursales)
function catSucursales(): array {
    static $lista = null;
    if ($lista !== null) return $lista;
    $lista = db()->query("
        SELECT id_sucursal, nombre, direccion, telefono, ciudad, email, horario_ventas, horario_servicio, servicios, imagen
        FROM sucursales WHERE estado = 'activo' ORDER BY id_sucursal
    ")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($lista as &$s) $s['id_sucursal'] = (int)$s['id_sucursal'];
    return $lista;
}

// Busca una sucursal activa por id (null si no existe)
function catSucursalPorId(int $id): ?array {
    foreach (catSucursales() as $s) if ($s['id_sucursal'] === $id) return $s;
    return null;
}

// Sucursal con la que el visitante está navegando: sesión → cookie → preferida del cliente → primera activa
function catSucursalActual(): array {
    $id = (int)($_SESSION['sucursal_id'] ?? 0);
    if (!$id && isset($_COOKIE[CAT_COOKIE_SUCURSAL])) $id = (int)$_COOKIE[CAT_COOKIE_SUCURSAL];
    if (!$id && ($cliente = catClienteActual()) && $cliente['id_sucursal_preferida']) $id = (int)$cliente['id_sucursal_preferida'];
    $sucursal = catSucursalPorId($id) ?? (catSucursales()[0] ?? null);
    if (!$sucursal) throw new RuntimeException('No hay sucursales activas registradas.');
    $_SESSION['sucursal_id'] = $sucursal['id_sucursal'];
    return $sucursal;
}

// Cambia la sucursal elegida (se valida que exista y esté activa)
function catEstablecerSucursal(int $id): array {
    $sucursal = catSucursalPorId($id);
    if (!$sucursal) throw new InvalidArgumentException('La sucursal elegida no existe o no está activa.');
    $_SESSION['sucursal_id'] = $sucursal['id_sucursal'];
    setcookie(CAT_COOKIE_SUCURSAL, (string)$sucursal['id_sucursal'], [
        'expires' => time() + 31536000, 'path' => '/', 'httponly' => false, 'samesite' => 'Lax'
    ]);
    return $sucursal;
}

// ===== CLIENTE CON SESIÓN =====

// Cliente que inició sesión (de la tabla clientes) o null; se revalida en cada petición
function catClienteActual(bool $recargar = false): ?array {
    static $cache = false;
    if ($cache !== false && !$recargar) return $cache;
    $id = (int)($_SESSION['cliente_id'] ?? 0);
    if (!$id) return $cache = null;
    $stmt = db()->prepare("
        SELECT id_cliente, nombre, nombres, apellidos, email, celular, direccion, ciudad, entidad_federativa,
               codigo_postal, id_sucursal_preferida, marca_interes, notif_email, notif_sms, notif_promociones,
               fecha_registro, ultimo_acceso, rfc_ine, articulo, total_adeudo, monto_abono, enganche,
               abonos_pagados, abonos_totales
        FROM clientes
        WHERE id_cliente = ? AND estado = 'activo' AND password_hash IS NOT NULL
        LIMIT 1
    ");
    $stmt->execute([$id]);
    $cliente = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    if (!$cliente) unset($_SESSION['cliente_id']);
    return $cache = $cliente;
}

// Primer nombre para saludos ("Hola, Ana")
function catNombreCorto(?array $cliente): string {
    if (!$cliente) return '';
    $base = trim((string)($cliente['nombres'] ?: $cliente['nombre']));
    return explode(' ', $base)[0] ?? $base;
}

// Páginas privadas (perfil, checkout…): sin sesión se manda a login y luego se regresa
function catRequerirCliente(): array {
    $cliente = catClienteActual();
    if (!$cliente) {
        $volver = basename($_SERVER['SCRIPT_NAME'] ?? 'perfil.php') . (empty($_SERVER['QUERY_STRING']) ? '' : '?' . $_SERVER['QUERY_STRING']);
        header('Location: login.php?volver=' . rawurlencode($volver));
        exit;
    }
    return $cliente;
}

// Valida que un destino de "volver" sea una página interna del catálogo (evita redirecciones abiertas)
function catVolverSeguro(?string $volver, string $defecto = 'perfil.php'): string {
    $volver = (string)$volver;
    return preg_match('#^[a-z_]+\.php(\?[A-Za-z0-9_=&%.\-]*)?$#', $volver) ? $volver : $defecto;
}

// ===== CARRITO (en la sesión: [id_producto => cantidad]) =====
function catCarrito(): array {
    $carrito = $_SESSION['carrito'] ?? [];
    return is_array($carrito) ? $carrito : [];
}
function catCarritoCantidad(): int {
    return array_sum(array_map('intval', catCarrito()));
}

// ===== FOLIOS =====
function catFolio(string $prefijo, int $sucursal, int $id): string {
    return sprintf('%s-%02d-%06d', $prefijo, $sucursal, $id);
}

// ===== NOTIFICACIONES DEL CLIENTE =====
function catNotificar(PDO $pdo, int $idCliente, string $tipo, string $titulo, string $mensaje, ?string $enlace = null): void {
    $stmt = $pdo->prepare("INSERT INTO notificaciones (id_cliente, tipo, titulo, mensaje, enlace) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$idCliente, $tipo, mb_substr($titulo, 0, 150), mb_substr($mensaje, 0, 500), $enlace]);
}
