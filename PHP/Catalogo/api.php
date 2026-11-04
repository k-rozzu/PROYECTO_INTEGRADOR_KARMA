<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — API JSON del sitio web de clientes (mismo estilo que PHP/PuntoDeVenta/api.php).
   Uso: api.php?action=NOMBRE   ·   GET = consultas   ·   POST (JSON + cabecera X-CSRF-Token) = cambios.

   Reglas importantes:
   - TODO se valida aquí en el servidor (el JavaScript solo mejora la experiencia).
   - El inventario es por sucursal: cada compra descuenta ÚNICAMENTE la fila inventarios(id_sucursal, id_producto)
     de la sucursal del pedido, dentro de una transacción con bloqueo de fila (SELECT … FOR UPDATE).
   - Recoger en sucursal + efectivo  → web_orders.estado = 'pendiente' (aparece en POS → Web orders para cobrar).
   - Envío + tarjeta (pago simulado) → web_orders.estado = 'atendida', estado_pago = 'pagado' (NO queda pendiente en caja).
   ===================================================================================== */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
require_once __DIR__ . '/includes/cuenta.php';

// ===== RESPUESTAS =====
function apiOk(array $datos = []): never {
    echo json_encode(['ok' => true] + $datos, JSON_UNESCAPED_UNICODE);
    exit;
}
function apiError(string $mensaje, int $estado = 400, array $extra = []): never {
    http_response_code($estado);
    echo json_encode(['ok' => false, 'error' => $mensaje] + $extra, JSON_UNESCAPED_UNICODE);
    exit;
}

// ===== LECTURA Y VALIDACIÓN DE DATOS =====
function apiEntrada(): array {
    $datos = json_decode((string)file_get_contents('php://input'), true);
    return is_array($datos) ? $datos : [];
}
// Texto de una línea: recorta espacios, valida obligatorio y longitud máxima
function apiTexto(array $d, string $clave, int $max, bool $requerido = true, string $etiqueta = 'este campo'): string {
    $valor = trim(preg_replace('/\s+/u', ' ', (string)($d[$clave] ?? '')));
    if ($requerido && $valor === '') throw new InvalidArgumentException("Escribe {$etiqueta}.");
    if (mb_strlen($valor) > $max) throw new InvalidArgumentException("El campo «{$etiqueta}» admite máximo {$max} caracteres.");
    return $valor;
}
// Texto largo (permite saltos de línea)
function apiTextoLargo(array $d, string $clave, int $max, bool $requerido = false, string $etiqueta = 'el mensaje'): string {
    $valor = trim(str_replace("\r", '', (string)($d[$clave] ?? '')));
    if ($requerido && mb_strlen($valor) < 10) throw new InvalidArgumentException("Escribe {$etiqueta} (mínimo 10 caracteres).");
    if (mb_strlen($valor) > $max) throw new InvalidArgumentException("El campo «{$etiqueta}» admite máximo {$max} caracteres.");
    return $valor;
}
function apiEmail(array $d, string $clave = 'email'): string {
    $email = mb_strtolower(trim((string)($d[$clave] ?? '')));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 120) {
        throw new InvalidArgumentException('Escribe un correo electrónico válido.');
    }
    return $email;
}
// Teléfono mexicano: 10 dígitos (se aceptan espacios, guiones y lada +52)
function apiTelefono(array $d, string $clave = 'celular', bool $requerido = true): string {
    $digitos = preg_replace('/\D+/', '', (string)($d[$clave] ?? ''));
    if (strlen($digitos) === 12 && str_starts_with($digitos, '52')) $digitos = substr($digitos, 2);
    if ($digitos === '' && !$requerido) return '';
    if (strlen($digitos) !== 10) throw new InvalidArgumentException('Escribe un teléfono de 10 dígitos.');
    return $digitos;
}
function apiCodigoPostal(array $d, string $clave = 'codigo_postal', bool $requerido = false): string {
    $cp = trim((string)($d[$clave] ?? ''));
    if ($cp === '' && !$requerido) return '';
    if (!preg_match('/^\d{5}$/', $cp)) throw new InvalidArgumentException('El código postal debe tener 5 dígitos.');
    return $cp;
}
// Contraseña: mínimo 8 caracteres con letras y números (y máximo 72 bytes, límite de bcrypt)
function apiPasswordNueva(string $password): void {
    if (strlen($password) < 8 || !preg_match('/[A-Za-zÁÉÍÓÚÑáéíóúñ]/u', $password) || !preg_match('/\d/', $password)) {
        throw new InvalidArgumentException('La contraseña debe tener al menos 8 caracteres e incluir letras y números.');
    }
    if (strlen($password) > 72) throw new InvalidArgumentException('La contraseña es demasiado larga (máximo 72 caracteres).');
}
// Exige que haya un cliente con sesión iniciada
function apiRequerirCliente(): array {
    $cliente = catClienteActual();
    if (!$cliente) apiError('Inicia sesión para continuar.', 401, ['sesion' => false]);
    return $cliente;
}
// Limita acciones repetidas por sesión (registro, solicitudes…)
function apiLimite(string $clave, int $maximo, int $segundos): void {
    $ahora = time();
    $marcas = array_filter($_SESSION['limites'][$clave] ?? [], fn($t) => $ahora - $t < $segundos);
    if (count($marcas) >= $maximo) apiError('Demasiadas solicitudes seguidas. Espera unos minutos e inténtalo de nuevo.', 429);
    $marcas[] = $ahora;
    $_SESSION['limites'][$clave] = array_values($marcas);
}
// Resumen del cliente que se envía al navegador (sin datos sensibles)
function apiResumenCliente(array $c): array {
    return [
        'id' => (int)$c['id_cliente'], 'nombre' => $c['nombre'], 'nombreCorto' => catNombreCorto($c),
        'nombres' => $c['nombres'], 'apellidos' => $c['apellidos'], 'email' => $c['email'], 'celular' => $c['celular'],
        'notificaciones' => catNotificacionesSinLeer((int)$c['id_cliente'])
    ];
}
// Sucursal en formato corto para el navegador
function apiSucursal(array $s): array {
    return ['id' => $s['id_sucursal'], 'nombre' => $s['nombre'], 'direccion' => $s['direccion'], 'telefono' => $s['telefono'],
            'ciudad' => $s['ciudad'], 'email' => $s['email'], 'horarioVentas' => $s['horario_ventas'],
            'horarioServicio' => $s['horario_servicio'], 'imagen' => catAsset($s['imagen'])];
}

// ===== CARRITO: detalle con validación de existencias en la sucursal elegida =====
function apiCarritoDetalle(): array {
    $sucursal = catSucursalActual();
    $carrito = catCarrito();
    $items = [];
    $subtotal = 0.0;
    $hayProblemas = false;
    $limpio = [];
    if ($carrito) {
        $productos = catBuscarProductos(['ids' => array_keys($carrito), 'seccion' => ['refacciones', 'accesorios']], $sucursal['id_sucursal']);
        $porId = array_column($productos, null, 'id');
        foreach ($carrito as $id => $cantidad) {
            $p = $porId[(int)$id] ?? null;
            if (!$p) continue; // productos que ya no se venden en línea se quitan solos
            $cantidad = max(1, min((int)$cantidad, CAT_MAX_POR_PRODUCTO));
            $limpio[(int)$id] = $cantidad;
            $suficiente = $p['stock'] >= $cantidad;
            if (!$suficiente) $hayProblemas = true;
            $linea = round($p['precio'] * $cantidad, 2);
            $subtotal += $linea;
            $items[] = [
                'id' => $p['id'], 'nombre' => $p['nombre'], 'marca' => $p['marca'], 'codigo' => $p['codigo'],
                'compatibilidad' => $p['compatibilidad'], 'seccion' => $p['seccion'], 'imagen' => $p['imagen'], 'url' => $p['url'],
                'precio' => $p['precio'], 'cantidad' => $cantidad, 'subtotal' => $linea, 'stock' => $p['stock'],
                'estadoStock' => $p['estadoStock'], 'textoStock' => $p['textoStock'], 'suficiente' => $suficiente,
                'aviso' => $suficiente ? null : ($p['stock'] > 0
                    ? "Solo hay {$p['stock']} disponible(s) en {$sucursal['nombre']}. Ajusta la cantidad."
                    : "0 unidades disponibles en {$sucursal['nombre']}. Quítalo o cambia de sucursal.")
            ];
        }
    }
    $_SESSION['carrito'] = $limpio;
    $subtotal = round($subtotal, 2);
    return [
        'items' => $items, 'cantidad' => array_sum($limpio), 'subtotal' => $subtotal,
        'envio' => $subtotal >= CAT_ENVIO_GRATIS_DESDE ? 0.0 : CAT_ENVIO_COSTO, 'envioCosto' => CAT_ENVIO_COSTO,
        'envioGratisDesde' => CAT_ENVIO_GRATIS_DESDE, 'hayProblemas' => $hayProblemas,
        'sucursal' => ['id' => $sucursal['id_sucursal'], 'nombre' => $sucursal['nombre'], 'direccion' => $sucursal['direccion']]
    ];
}

// ===== TARJETA (PAGO SIMULADO: no se cobra nada ni se guarda el número completo) =====
function apiLuhn(string $numero): bool {
    $suma = 0;
    $doble = false;
    for ($i = strlen($numero) - 1; $i >= 0; $i--) {
        $d = (int)$numero[$i];
        if ($doble) { $d *= 2; if ($d > 9) $d -= 9; }
        $suma += $d;
        $doble = !$doble;
    }
    return $suma % 10 === 0;
}
function apiMarcaTarjeta(string $numero): string {
    if (preg_match('/^4/', $numero)) return 'Visa';
    if (preg_match('/^(5[1-5]|2[2-7])/', $numero)) return 'Mastercard';
    if (preg_match('/^3[47]/', $numero)) return 'American Express';
    return 'Tarjeta';
}
// Valida los datos de la tarjeta y simula la autorización del banco
function apiValidarTarjeta(array $t): array {
    $numero = preg_replace('/\D+/', '', (string)($t['numero'] ?? ''));
    $titular = trim((string)($t['titular'] ?? ''));
    $vence = trim((string)($t['vencimiento'] ?? ''));
    $cvv = preg_replace('/\D+/', '', (string)($t['cvv'] ?? ''));
    $tipo = ($t['tipo'] ?? 'credito') === 'debito' ? 'debito' : 'credito';
    if (mb_strlen($titular) < 4 || mb_strlen($titular) > 100) throw new InvalidArgumentException('Escribe el nombre del titular como aparece en la tarjeta.');
    if (strlen($numero) < 13 || strlen($numero) > 19 || !apiLuhn($numero)) throw new InvalidArgumentException('El número de tarjeta no es válido.');
    if (!preg_match('/^(0[1-9]|1[0-2])\/?(\d{2})$/', $vence, $m)) throw new InvalidArgumentException('La fecha de vencimiento debe tener el formato MM/AA.');
    $ultimoDia = (int)date('t', mktime(0, 0, 0, (int)$m[1], 1, 2000 + (int)$m[2]));
    if (mktime(23, 59, 59, (int)$m[1], $ultimoDia, 2000 + (int)$m[2]) < time()) throw new InvalidArgumentException('La tarjeta está vencida.');
    $marca = apiMarcaTarjeta($numero);
    if (!preg_match($marca === 'American Express' ? '/^\d{4}$/' : '/^\d{3}$/', $cvv)) throw new InvalidArgumentException('El código de seguridad (CVV) no es válido.');
    // Simulación de rechazo: cualquier tarjeta que termine en 0002 (ej. 4000 0000 0000 0002) es rechazada
    if (str_ends_with($numero, '0002')) apiError('Pago rechazado por el banco emisor (simulación). Prueba con otra tarjeta.', 402);
    return ['marca' => $marca, 'ultimos4' => substr($numero, -4), 'tipo' => $tipo, 'referencia' => 'SIM-' . strtoupper(bin2hex(random_bytes(4)))];
}

// ===== CITAS: capacidad por horario =====
// Tipos de cita que se pueden agendar (las citas antiguas de otros tipos se siguen mostrando en el perfil)
const API_TIPOS_CITA = ['visita', 'apartado', 'servicio'];
// Lugares por hora y sucursal: servicio 3 (bahías), visitas/apartados 4
function apiCapacidadCita(string $tipo): int {
    return ['servicio' => 3, 'visita' => 4, 'apartado' => 4][$tipo] ?? 2;
}
// Ocupación de un día: [hora => ['total' => n, 'mismo' => n del mismo vehículo]]
function apiOcupacion(PDO $pdo, int $idSucursal, string $fecha, string $tipo, int $idProducto, bool $bloquear = false): array {
    $grupo = in_array($tipo, ['visita', 'apartado'], true) ? ['visita', 'apartado'] : [$tipo];
    $sql = "SELECT DATE_FORMAT(fecha_hora, '%H:%i') AS hora, COUNT(*) AS total, SUM(id_producto <=> ?) AS mismo
              FROM citas
             WHERE id_sucursal = ? AND fecha_hora >= ? AND fecha_hora < DATE_ADD(?, INTERVAL 1 DAY) AND estado <> 'cancelada'
               AND tipo IN (" . implode(',', array_fill(0, count($grupo), '?')) . ")
             GROUP BY hora" . ($bloquear ? ' FOR UPDATE' : '');
    $stmt = $pdo->prepare($sql);
    $stmt->execute(array_merge([$idProducto ?: null, $idSucursal, $fecha . ' 00:00:00', $fecha . ' 00:00:00'], $grupo));
    $ocupacion = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) $ocupacion[$r['hora']] = ['total' => (int)$r['total'], 'mismo' => (int)$r['mismo']];
    return $ocupacion;
}
function apiHoraLibre(array $ocupacion, string $hora, string $tipo, int $idProducto): bool {
    $o = $ocupacion[$hora] ?? ['total' => 0, 'mismo' => 0];
    return $o['total'] < apiCapacidadCita($tipo);
}
// Fecha válida para cita: de mañana a 60 días, nunca domingo
function apiValidarFechaCita(string $fecha): void {
    $t = DateTime::createFromFormat('!Y-m-d', $fecha);
    if (!$t || $t->format('Y-m-d') !== $fecha) throw new InvalidArgumentException('Elige una fecha válida.');
    $hoy = new DateTime('today');
    $dias = (int)$hoy->diff($t)->format('%r%a');
    if ($dias < 1) throw new InvalidArgumentException('Las citas se agendan a partir de mañana.');
    if ($dias > 60) throw new InvalidArgumentException('Solo se pueden agendar citas con hasta 60 días de anticipación.');
    if ($t->format('N') === '7') throw new InvalidArgumentException('Los domingos la sucursal está cerrada. Elige otro día.');
}

// =====================================================================================
// ENRUTADOR
// =====================================================================================
$accion = (string)($_GET['action'] ?? '');
$metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$accionesPost = ['set_sucursal', 'registro', 'registro_reenviar', 'registro_cancelar', 'login', 'logout', 'carrito_agregar', 'carrito_actualizar', 'carrito_eliminar',
    'carrito_vaciar', 'checkout', 'cancelar_pedido', 'agendar', 'cancelar_cita', 'solicitud', 'favorito',
    'perfil_actualizar', 'cambiar_password', 'notificaciones_leidas'];

if (in_array($accion, $accionesPost, true)) {
    if ($metodo !== 'POST') apiError('Esta acción requiere POST.', 405);
    if (!catCsrfValido()) apiError('La sesión de la página expiró. Recarga la página e inténtalo de nuevo.', 403);
}

try {
    switch ($accion) {

        // ---------- Sesión, sucursal y búsqueda ----------
        case 'sesion': {
            $cliente = catClienteActual();
            apiOk([
                'cliente' => $cliente ? apiResumenCliente($cliente) : null,
                'sucursal' => apiSucursal(catSucursalActual()),
                'sucursales' => array_map('apiSucursal', catSucursales()),
                'carrito' => catCarritoCantidad(),
                'csrf' => catCsrf()
            ]);
        }

        case 'set_sucursal': {
            $d = apiEntrada();
            $sucursal = catEstablecerSucursal((int)($d['id_sucursal'] ?? 0));
            $carrito = apiCarritoDetalle();
            apiOk(['sucursal' => apiSucursal($sucursal), 'carritoConProblemas' => $carrito['hayProblemas'],
                   'mensaje' => "Ahora estás viendo el inventario de {$sucursal['nombre']}."]);
        }

        case 'productos': {
            $f = [
                'seccion' => array_filter(explode(',', (string)($_GET['seccion'] ?? ''))),
                'marca' => $_GET['marca'] ?? null, 'tipo' => $_GET['tipo'] ?? null,
                'subcategoria' => $_GET['subcategoria'] ?? null, 'condicion' => $_GET['condicion'] ?? null,
                'anio' => $_GET['anio'] ?? null, 'precio_min' => $_GET['precio_min'] ?? '', 'precio_max' => $_GET['precio_max'] ?? '',
                'disponible' => !empty($_GET['disponible']), 'modelo' => $_GET['modelo'] ?? null,
                'q' => $_GET['q'] ?? '', 'orden' => $_GET['orden'] ?? ''
            ];
            $cliente = catClienteActual();
            apiOk([
                'productos' => catBuscarProductos($f, null, (int)($_GET['limite'] ?? 200)),
                'sucursal' => apiSucursal(catSucursalActual()),
                'favoritos' => catFavoritosIds($cliente ? (int)$cliente['id_cliente'] : null)
            ]);
        }

        case 'producto': {
            $p = catProducto((int)($_GET['id'] ?? 0), $_GET['codigo'] ?? null);
            if (!$p) apiError('El producto no existe o ya no está publicado.', 404);
            $cliente = catClienteActual();
            $extra = ['stockPorSucursal' => catStockPorSucursal($p['id']),
                      'favorito' => in_array($p['id'], catFavoritosIds($cliente ? (int)$cliente['id_cliente'] : null), true)];
            if ($p['esVehiculo']) {
                $extra['opciones'] = catOpcionesConfigurador($p['marca'], $p['tipo']);
                $extra['compatibles'] = catCompatiblesConVehiculo($p, 6);
            }
            apiOk(['producto' => $p] + $extra);
        }

        case 'buscar': {
            $q = trim((string)($_GET['q'] ?? ''));
            if (mb_strlen($q) < 2) apiOk(['productos' => [], 'paginas' => []]);
            $paginas = [
                ['Agendar cita', 'agendar.php?tipo=visita', 'cita agendar visita asesor cotizacion'],
                ['Apartar vehículo', 'agendar.php?tipo=apartado', 'apartar apartado reservar enganche'],
                ['Simular crédito', 'financiamiento.php', 'financiamiento credito mensualidad enganche plazo simulador comision apertura'],
                ['Seguros', 'servicios.php#seguros', 'seguro seguros poliza cobertura amplia vida desempleo llantas rines'],
                ['Trámites e impuestos', 'servicios.php#tramites', 'tramites gestoria placas alta isan impuesto tenencia refrendo verificacion holograma'],
                ['Postventa y taller', 'servicios.php#postventa', 'taller servicio orden mantenimiento prepagado garantia extendida polarizado pelicula accesorios instalacion'],
                ['Orden de servicio de taller', 'agendar.php?tipo=servicio', 'orden servicio taller cita mantenimiento'],
                ['Sucursales', 'sucursales.php', 'sucursales manzanillo colima ubicacion horario direccion'],
                ['Contacto y atención a clientes', 'contacto.php', 'contacto atencion queja sugerencia telefono correo'],
                ['Accesorios', 'accesorios.php', 'accesorios tapetes portaequipaje maletas funda cargador']
            ];
            $qn = mb_strtolower(iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $q) ?: $q);
            $coinciden = array_values(array_filter($paginas, fn($pg) => str_contains($pg[2], $qn) || str_contains(mb_strtolower($pg[0]), mb_strtolower($q))));
            apiOk([
                'productos' => catBuscarProductos(['q' => $q], null, 8),
                'paginas' => array_map(fn($pg) => ['titulo' => $pg[0], 'url' => $pg[1]], array_slice($coinciden, 0, 4))
            ]);
        }

        // ---------- Cuenta: registro, login, logout ----------
        case 'registro': {
            // Paso 1 del registro: se valida el formulario y se crea una SOLICITUD pendiente (no una cuenta).
            // La cuenta solo se crea cuando la persona acepta el aviso y los términos desde el botón del correo
            // (includes/registro_cuenta.php y confirmar_registro.php).
            require_once __DIR__ . '/includes/registro_cuenta.php';
            if (!catRegistroConexionSegura()) apiError('El registro solo está disponible con una conexión segura (HTTPS).', 403);
            apiLimite('registro', 5, 600);
            $d = apiEntrada();
            $nombres = apiTexto($d, 'nombres', 80, true, 'tu nombre');
            $apellidos = apiTexto($d, 'apellidos', 100, true, 'tus apellidos');
            $email = apiEmail($d);
            $celular = apiTelefono($d, 'celular', true);
            $password = (string)($d['password'] ?? '');
            apiPasswordNueva($password);
            if ($password !== (string)($d['confirmacion'] ?? '')) throw new InvalidArgumentException('Las contraseñas no coinciden.');
            $direccion = apiTexto($d, 'direccion', 255, false);
            $ciudad = apiTexto($d, 'ciudad', 100, false);
            $entidad = apiTexto($d, 'entidad_federativa', 80, false);
            $cp = apiCodigoPostal($d);
            $idSucursal = (int)($d['id_sucursal_preferida'] ?? 0);
            if ($idSucursal && !catSucursalPorId($idSucursal)) throw new InvalidArgumentException('La sucursal preferida no es válida.');
            $marcaInteres = in_array($d['marca_interes'] ?? '', CAT_MARCAS, true) ? $d['marca_interes'] : null;
            try {
                $resumen = catRegistroSolicitar([
                    'nombres' => $nombres, 'apellidos' => $apellidos, 'email' => $email, 'celular' => $celular,
                    'direccion' => $direccion, 'ciudad' => $ciudad, 'entidad_federativa' => $entidad, 'codigo_postal' => $cp,
                    'id_sucursal_preferida' => $idSucursal ?: null, 'marca_interes' => $marcaInteres,
                    'notif_promociones' => !empty($d['notif_promociones']) ? 1 : 0,
                    'password_hash' => password_hash($password, PASSWORD_DEFAULT)
                ]);
            } catch (CatRegistroLimite $e) {
                apiError($e->getMessage(), 429);
            } catch (CatRegistroError $e) {
                apiError($e->getMessage(), 502);
            }
            // La sesión recuerda la solicitud para la pantalla «Revisa tu correo» (estado y reenvío); el navegador no recibe el id
            $_SESSION['registro_pendiente'] = ['id' => $resumen['id'], 'email' => $email, 'nombre' => $nombres];
            unset($resumen['id']);
            apiOk(['pendiente' => true, 'email' => $email,
                   'mensaje' => 'Te enviamos un correo para confirmar tu registro. Tu cuenta se activará cuando aceptes el aviso de privacidad y los términos desde ese correo.'] + $resumen);
        }

        case 'registro_estado': {
            // La pantalla «Revisa tu correo» pregunta cada pocos segundos si la persona ya aceptó (solo su propia solicitud)
            require_once __DIR__ . '/includes/registro_cuenta.php';
            $pendiente = $_SESSION['registro_pendiente'] ?? null;
            $sesion = catClienteActual() !== null;
            if (!is_array($pendiente) || empty($pendiente['id'])) apiOk(['estado' => 'ninguno', 'sesion' => $sesion]);
            try {
                $resumen = catRegistroResumen(catRegistroFila(db(), (int)$pendiente['id']));
            } catch (CatRegistroError $e) {
                unset($_SESSION['registro_pendiente']);
                apiOk(['estado' => 'ninguno', 'sesion' => $sesion]);
            }
            if ($resumen['estado'] !== 'pendiente') unset($_SESSION['registro_pendiente']);
            unset($resumen['id']);
            apiOk($resumen + ['sesion' => $sesion, 'email' => $pendiente['email']]);
        }

        case 'registro_reenviar': {
            require_once __DIR__ . '/includes/registro_cuenta.php';
            if (!catRegistroConexionSegura()) apiError('El registro solo está disponible con una conexión segura (HTTPS).', 403);
            $pendiente = $_SESSION['registro_pendiente'] ?? null;
            if (!is_array($pendiente) || empty($pendiente['id'])) apiError('No tienes una solicitud de registro en curso. Vuelve a llenar el formulario.', 404);
            apiLimite('registro_reenvio', 6, 600);
            try {
                $resumen = catRegistroReenviar((int)$pendiente['id'], (string)$pendiente['email'], (string)$pendiente['nombre']);
            } catch (CatRegistroLimite $e) {
                apiError($e->getMessage(), 429);
            } catch (CatRegistroError $e) {
                if ($e->codigo === 'vencido') unset($_SESSION['registro_pendiente']);
                apiError($e->getMessage(), $e->codigo === 'vencido' ? 410 : 502);
            }
            unset($resumen['id']);
            apiOk($resumen + ['mensaje' => 'Te enviamos un nuevo correo. Usa el enlace del mensaje más reciente.']);
        }

        case 'registro_cancelar': {
            // «Usar otro correo»: la solicitud se cancela y sus datos se borran de inmediato
            require_once __DIR__ . '/includes/registro_cuenta.php';
            $pendiente = $_SESSION['registro_pendiente'] ?? null;
            if (is_array($pendiente) && !empty($pendiente['id'])) catRegistroCerrar(db(), (int)$pendiente['id']);
            unset($_SESSION['registro_pendiente']);
            apiOk(['mensaje' => 'Cancelamos tu solicitud de registro y eliminamos sus datos.']);
        }

        case 'login': {
            $intentos = $_SESSION['cat_login'] ?? ['n' => 0, 't' => 0];
            if ($intentos['n'] >= 5 && time() - $intentos['t'] < 300) {
                apiError('Demasiados intentos fallidos. Espera 5 minutos e inténtalo de nuevo.', 429);
            }
            $d = apiEntrada();
            $email = mb_strtolower(trim((string)($d['email'] ?? '')));
            $password = (string)($d['password'] ?? '');
            if ($email === '' || $password === '') throw new InvalidArgumentException('Escribe tu correo y tu contraseña.');
            $stmt = db()->prepare('SELECT id_cliente, password_hash, estado FROM clientes WHERE email = ? LIMIT 1');
            $stmt->execute([$email]);
            $fila = $stmt->fetch(PDO::FETCH_ASSOC);
            $hash = ($fila['password_hash'] ?? null) ?: '$2y$12$hwYmuOlp6nD9GMMParLSaudYeryxz7nV8celMCqEe4ual5f/kf7z2';
            if (!$fila || empty($fila['password_hash']) || !password_verify($password, $hash)) {
                // Una solicitud de registro sin confirmar nunca inicia sesión; si la contraseña coincide se le explica por qué
                require_once __DIR__ . '/includes/registro_cuenta.php';
                if (catRegistroPendienteConPassword($email, $password)) {
                    apiError('Tu registro aún no está confirmado. Abre el correo que te enviamos y pulsa «' . CAT_REGISTRO_BOTON . '» para activar tu cuenta.', 403, ['pendiente' => true]);
                }
                $_SESSION['cat_login'] = ['n' => $intentos['n'] + 1, 't' => time()];
                usleep(300000);
                apiError('Correo o contraseña incorrectos.', 401);
            }
            if ($fila['estado'] !== 'activo') apiError('Tu cuenta está inactiva. Comunícate con la sucursal.', 403);
            if (password_needs_rehash($fila['password_hash'], PASSWORD_DEFAULT)) {
                db()->prepare('UPDATE clientes SET password_hash = ? WHERE id_cliente = ?')->execute([password_hash($password, PASSWORD_DEFAULT), $fila['id_cliente']]);
            }
            db()->prepare('UPDATE clientes SET ultimo_acceso = NOW() WHERE id_cliente = ?')->execute([$fila['id_cliente']]);
            unset($_SESSION['cat_login']);
            session_regenerate_id(true);
            $_SESSION['cliente_id'] = (int)$fila['id_cliente'];
            apiOk(['cliente' => apiResumenCliente(catClienteActual(true)), 'mensaje' => 'Sesión iniciada.']);
        }

        case 'logout': {
            unset($_SESSION['cliente_id'], $_SESSION['carrito']);
            session_regenerate_id(true);
            apiOk(['mensaje' => 'Cerraste sesión.']);
        }

        // ---------- Carrito ----------
        case 'carrito':
            apiOk(['carrito' => apiCarritoDetalle()]);

        case 'carrito_agregar': {
            $d = apiEntrada();
            $id = (int)($d['id_producto'] ?? 0);
            $cantidad = (int)($d['cantidad'] ?? 1);
            if ($cantidad < 1 || $cantidad > CAT_MAX_POR_PRODUCTO) throw new InvalidArgumentException('Elige una cantidad entre 1 y ' . CAT_MAX_POR_PRODUCTO . '.');
            $sucursal = catSucursalActual();
            $p = catProducto($id, null, $sucursal['id_sucursal']);
            if (!$p) apiError('El producto no existe o ya no está publicado.', 404);
            if (!in_array($p['seccion'], ['refacciones', 'accesorios'], true)) {
                throw new InvalidArgumentException('Los vehículos no se compran en línea: agenda una cita o aparta la unidad.');
            }
            $carrito = catCarrito();
            $nueva = ($carrito[$id] ?? 0) + $cantidad;
            if ($p['stock'] <= 0) throw new InvalidArgumentException("0 unidades disponibles de {$p['nombre']} en {$sucursal['nombre']}.");
            if ($nueva > $p['stock']) {
                throw new InvalidArgumentException("Solo hay {$p['stock']} unidad(es) disponible(s) en {$sucursal['nombre']}" . (isset($carrito[$id]) ? " y ya tienes {$carrito[$id]} en tu carrito." : '.'));
            }
            if ($nueva > CAT_MAX_POR_PRODUCTO) throw new InvalidArgumentException('Máximo ' . CAT_MAX_POR_PRODUCTO . ' piezas iguales por pedido.');
            $carrito[$id] = $nueva;
            $_SESSION['carrito'] = $carrito;
            apiOk(['mensaje' => "{$p['nombre']} se agregó a tu carrito.", 'carrito' => catCarritoCantidad()]);
        }

        case 'carrito_actualizar': {
            $d = apiEntrada();
            $id = (int)($d['id_producto'] ?? 0);
            $cantidad = (int)($d['cantidad'] ?? 0);
            $carrito = catCarrito();
            if (!isset($carrito[$id])) apiError('Ese producto no está en tu carrito.', 404);
            if ($cantidad <= 0) {
                unset($carrito[$id]);
            } else {
                if ($cantidad > CAT_MAX_POR_PRODUCTO) throw new InvalidArgumentException('Máximo ' . CAT_MAX_POR_PRODUCTO . ' piezas iguales por pedido.');
                $sucursal = catSucursalActual();
                $p = catProducto($id, null, $sucursal['id_sucursal']);
                if (!$p) apiError('El producto ya no está disponible.', 404);
                if ($cantidad > $p['stock']) throw new InvalidArgumentException("Solo hay {$p['stock']} unidad(es) disponible(s) en {$sucursal['nombre']}.");
                $carrito[$id] = $cantidad;
            }
            $_SESSION['carrito'] = $carrito;
            apiOk(['carrito' => apiCarritoDetalle()]);
        }

        case 'carrito_eliminar': {
            $d = apiEntrada();
            $carrito = catCarrito();
            unset($carrito[(int)($d['id_producto'] ?? 0)]);
            $_SESSION['carrito'] = $carrito;
            apiOk(['carrito' => apiCarritoDetalle()]);
        }

        case 'carrito_vaciar':
            $_SESSION['carrito'] = [];
            apiOk(['carrito' => apiCarritoDetalle()]);

        // ---------- Checkout: crea el pedido real en web_orders + web_order_detalle y descuenta inventario de ESA sucursal ----------
        case 'checkout': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $modalidad = (string)($d['modalidad'] ?? '');
            if (!in_array($modalidad, ['recoger_efectivo', 'envio_tarjeta'], true)) throw new InvalidArgumentException('Elige cómo quieres recibir y pagar tu pedido.');
            $esEnvio = $modalidad === 'envio_tarjeta';
            $sucursal = catSucursalActual();
            if (isset($d['id_sucursal']) && (int)$d['id_sucursal'] !== $sucursal['id_sucursal']) {
                apiError('La sucursal seleccionada cambió mientras completabas tu pedido. Revisa tu carrito.', 409);
            }
            $nombre = apiTexto($d, 'nombre', 150, true, 'el nombre de quien recibe');
            $celular = apiTelefono($d, 'celular', true);
            $email = apiEmail($d);
            $comentarios = apiTexto($d, 'comentarios', 500, false);
            $carrito = catCarrito();
            if (!$carrito) throw new InvalidArgumentException('Tu carrito está vacío.');

            $direccion = null;
            $tarjeta = null;
            if ($esEnvio) {
                $calle = apiTexto($d, 'calle', 150, true, 'la calle y número');
                $colonia = apiTexto($d, 'colonia', 100, true, 'la colonia');
                $ciudad = apiTexto($d, 'ciudad', 100, true, 'la ciudad');
                $estado = apiTexto($d, 'estado', 80, true, 'el estado');
                $cp = apiCodigoPostal($d, 'cp', true);
                $referencias = apiTexto($d, 'referencias', 150, false);
                $direccion = "{$calle}, Col. {$colonia}, {$ciudad}, {$estado}, C.P. {$cp}" . ($referencias !== '' ? " (Ref.: {$referencias})" : '');
                $tarjeta = apiValidarTarjeta(is_array($d['tarjeta'] ?? null) ? $d['tarjeta'] : []);
            }

            $pdo = db();
            $pdo->beginTransaction();
            try {
                // Productos del carrito con los datos que también muestra el POS en Web orders
                $ids = array_map('intval', array_keys($carrito));
                $stmtP = $pdo->prepare("
                    SELECT p.id_producto, p.nombre, p.precio_base, p.marca, p.modelo, p.traccion, p.lado, p.compatibilidad, pw.seccion,
                           (SELECT MIN(v.motor) FROM productos v WHERE v.tipo IN ('auto','moto') AND v.marca = p.marca AND v.modelo = p.modelo) AS motor_compatible,
                           (SELECT MIN(v.cilindraje) FROM productos v WHERE v.tipo IN ('auto','moto') AND v.marca = p.marca AND v.modelo = p.modelo) AS cilindraje_compatible
                      FROM productos p
                      JOIN productos_web pw ON pw.id_producto = p.id_producto AND pw.publicado = 1
                     WHERE p.id_producto IN (" . implode(',', array_fill(0, count($ids), '?')) . ")");
                $stmtP->execute($ids);
                $productos = array_column($stmtP->fetchAll(PDO::FETCH_ASSOC), null, 'id_producto');

                // Bloquea la fila de inventario de ESTA sucursal y valida existencias antes de confirmar
                $stmtStock = $pdo->prepare('SELECT stock_actual FROM inventarios WHERE id_sucursal = ? AND id_producto = ? FOR UPDATE');
                $lineas = [];
                $subtotal = 0.0;
                foreach ($carrito as $id => $cantidad) {
                    $id = (int)$id;
                    $cantidad = (int)$cantidad;
                    $p = $productos[$id] ?? null;
                    if (!$p || !in_array($p['seccion'], ['refacciones', 'accesorios'], true)) {
                        throw new InvalidArgumentException('Uno de los productos de tu carrito ya no está disponible en línea. Revisa tu carrito.');
                    }
                    if ($cantidad < 1 || $cantidad > CAT_MAX_POR_PRODUCTO) throw new InvalidArgumentException("Cantidad no válida para {$p['nombre']}.");
                    $stmtStock->execute([$sucursal['id_sucursal'], $id]);
                    $stock = $stmtStock->fetchColumn();
                    if ($stock === false || (int)$stock < $cantidad) {
                        throw new InvalidArgumentException("Stock insuficiente de {$p['nombre']} en {$sucursal['nombre']}: hay " . (int)$stock . " disponible(s) y pediste {$cantidad}.");
                    }
                    $precio = round((float)$p['precio_base'], 2);
                    $linea = round($precio * $cantidad, 2);
                    $subtotal += $linea;
                    $lineas[] = ['id' => $id, 'nombre' => $p['nombre'], 'cantidad' => $cantidad, 'precio' => $precio, 'subtotal' => $linea] + $p;
                }
                $subtotal = round($subtotal, 2);
                $envio = $esEnvio ? ($subtotal >= CAT_ENVIO_GRATIS_DESDE ? 0.0 : CAT_ENVIO_COSTO) : 0.0;
                $total = round($subtotal + $envio, 2);

                // Método de pago del catálogo existente metodos_pago (Efectivo / Tarjeta de Crédito / Tarjeta de Débito)
                $nombreMetodo = $esEnvio ? ($tarjeta['tipo'] === 'debito' ? 'Tarjeta de Débito' : 'Tarjeta de Crédito') : 'Efectivo';
                $stmtM = $pdo->prepare('SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo = ? LIMIT 1');
                $stmtM->execute([$nombreMetodo]);
                $idMetodo = $stmtM->fetchColumn();
                if (!$idMetodo) throw new RuntimeException("No existe el método de pago {$nombreMetodo}.");

                // Encabezado en web_orders (columnas originales llenas con la primera pieza para que el POS las muestre)
                $primera = $lineas[0];
                $pieza = $primera['nombre'] . (count($lineas) > 1 ? ' (+' . (count($lineas) - 1) . ' artículo(s) más)' : '');
                $ins = $pdo->prepare("
                    INSERT INTO web_orders
                        (tipo, id_producto, nombre, celular, email, pieza, modelo_compatibilidad, marca_vehiculo, motor, cilindraje, traccion, lado,
                         estado, id_cliente, id_sucursal, metodo_entrega, id_metodo_pago, estado_pago, subtotal, costo_envio, total,
                         direccion_envio, tarjeta_marca, tarjeta_ultimos4, referencia_pago, stock_reservado, comentarios, fecha_creacion, fecha_pago)
                    VALUES ('refaccion', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, NULLIF(?, ''), NOW(), " . ($esEnvio ? 'NOW()' : 'NULL') . ")");
                $ins->execute([
                    $primera['id'], $nombre, $celular, $email, mb_substr($pieza, 0, 150),
                    mb_substr((string)($primera['compatibilidad'] ?: $primera['modelo']), 0, 150), $primera['marca'],
                    $primera['motor_compatible'], $primera['cilindraje_compatible'], $primera['traccion'], $primera['lado'],
                    $esEnvio ? 'atendida' : 'pendiente', (int)$cliente['id_cliente'], $sucursal['id_sucursal'],
                    $esEnvio ? 'envio' : 'recoger', (int)$idMetodo, $esEnvio ? 'pagado' : 'pendiente',
                    $subtotal, $envio, $total, $direccion, $tarjeta['marca'] ?? null, $tarjeta['ultimos4'] ?? null,
                    $tarjeta['referencia'] ?? null, $comentarios
                ]);
                $idOrden = (int)$pdo->lastInsertId();
                $folio = catFolio('WEB', $sucursal['id_sucursal'], $idOrden);
                $pdo->prepare('UPDATE web_orders SET folio = ? WHERE id_orden = ?')->execute([$folio, $idOrden]);

                // Líneas del pedido + descuento de existencias SOLO en la sucursal del pedido
                $insLinea = $pdo->prepare('INSERT INTO web_order_detalle (id_orden, id_producto, cantidad, precio_unitario, subtotal_linea, descripcion) VALUES (?, ?, ?, ?, ?, ?)');
                $descuento = $pdo->prepare('UPDATE inventarios SET stock_actual = stock_actual - ? WHERE id_sucursal = ? AND id_producto = ? AND stock_actual >= ?');
                foreach ($lineas as $l) {
                    $insLinea->execute([$idOrden, $l['id'], $l['cantidad'], $l['precio'], $l['subtotal'], mb_substr($l['nombre'], 0, 200)]);
                    $descuento->execute([$l['cantidad'], $sucursal['id_sucursal'], $l['id'], $l['cantidad']]);
                    if ($descuento->rowCount() !== 1) throw new RuntimeException("No se pudo apartar el inventario de {$l['nombre']}.");
                }

                catNotificar($pdo, (int)$cliente['id_cliente'], 'pedido',
                    $esEnvio ? "Pedido {$folio} pagado" : "Pedido {$folio} recibido",
                    $esEnvio ? "Tu pago con {$tarjeta['marca']} •••• {$tarjeta['ultimos4']} fue aprobado (simulación). Preparamos tu envío desde {$sucursal['nombre']}."
                             : "Tus piezas quedaron apartadas en {$sucursal['nombre']}. Paga en efectivo al recogerlas en caja.",
                    "pedido.php?id={$idOrden}");
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                throw $e;
            }
            $_SESSION['carrito'] = [];
            apiOk(['folio' => $folio, 'id_orden' => $idOrden, 'pagado' => $esEnvio, 'total' => $total, 'url' => "pedido.php?id={$idOrden}"]);
        }

        // ---------- Pedidos del cliente ----------
        case 'mis_pedidos': {
            $cliente = apiRequerirCliente();
            apiOk(['pedidos' => catPedidosCliente((int)$cliente['id_cliente'])]);
        }

        case 'cancelar_pedido': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $idOrden = (int)($d['id_orden'] ?? 0);
            $pdo = db();
            $pdo->beginTransaction();
            try {
                $stmt = $pdo->prepare('SELECT id_orden, folio, id_sucursal, estado, estado_pago, metodo_entrega, stock_reservado FROM web_orders WHERE id_orden = ? AND id_cliente = ? FOR UPDATE');
                $stmt->execute([$idOrden, (int)$cliente['id_cliente']]);
                $o = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$o) { $pdo->rollBack(); apiError('No encontramos ese pedido en tu cuenta.', 404); }
                if (!($o['estado'] === 'pendiente' && $o['estado_pago'] === 'pendiente' && $o['metodo_entrega'] === 'recoger')) {
                    $pdo->rollBack();
                    apiError('Este pedido ya no se puede cancelar en línea. Comunícate con la sucursal.', 409);
                }
                // Regresa las piezas apartadas al inventario de LA MISMA sucursal
                if ((int)$o['stock_reservado'] === 1) {
                    $pdo->prepare('UPDATE inventarios i JOIN web_order_detalle d ON d.id_producto = i.id_producto AND d.id_orden = ?
                                      SET i.stock_actual = i.stock_actual + d.cantidad WHERE i.id_sucursal = ?')
                        ->execute([$idOrden, (int)$o['id_sucursal']]);
                }
                $pdo->prepare("UPDATE web_orders SET estado = 'cancelada', stock_reservado = 0 WHERE id_orden = ?")->execute([$idOrden]);
                catNotificar($pdo, (int)$cliente['id_cliente'], 'pedido', "Pedido {$o['folio']} cancelado",
                    'Cancelaste tu pedido y las piezas regresaron al inventario de la sucursal.', "pedido.php?id={$idOrden}");
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                throw $e;
            }
            apiOk(['mensaje' => 'Pedido cancelado.']);
        }

        // ---------- Citas: visita, apartado y servicio de taller ----------
        case 'disponibilidad': {
            $tipo = (string)($_GET['tipo'] ?? 'visita');
            if (!in_array($tipo, API_TIPOS_CITA, true)) throw new InvalidArgumentException('Tipo de cita no válido.');
            $sucursal = catSucursalPorId((int)($_GET['id_sucursal'] ?? 0)) ?? catSucursalActual();
            $fecha = (string)($_GET['fecha'] ?? '');
            apiValidarFechaCita($fecha);
            $idProducto = (int)($_GET['id_producto'] ?? 0);
            $ocupacion = apiOcupacion(db(), $sucursal['id_sucursal'], $fecha, $tipo, $idProducto);
            $horas = array_map(fn($h) => ['hora' => $h, 'disponible' => apiHoraLibre($ocupacion, $h, $tipo, $idProducto)], catHorasDelDia($fecha));
            apiOk(['horas' => $horas, 'sucursal' => $sucursal['nombre']]);
        }

        case 'agendar': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $tipo = (string)($d['tipo'] ?? '');
            if (!in_array($tipo, API_TIPOS_CITA, true)) throw new InvalidArgumentException('Elige el tipo de cita.');
            $sucursal = catSucursalPorId((int)($d['id_sucursal'] ?? 0));
            if (!$sucursal) throw new InvalidArgumentException('Elige una sucursal válida.');
            $fecha = (string)($d['fecha'] ?? '');
            apiValidarFechaCita($fecha);
            $hora = (string)($d['hora'] ?? '');
            if (!in_array($hora, catHorasDelDia($fecha), true)) throw new InvalidArgumentException('Elige un horario disponible.');
            $nombre = apiTexto($d, 'nombre', 150, true, 'tu nombre completo');
            $email = apiEmail($d);
            $telefono = apiTelefono($d, 'telefono', true);
            $comentarios = apiTextoLargo($d, 'comentarios', 1000, false, 'los comentarios');

            $producto = null;
            $vehiculoCliente = $vin = $tipoServicio = null;
            $kilometraje = null;
            $enganche = null;
            $color = apiTexto($d, 'color', 80, false) ?: null;
            if ($tipo === 'servicio') {
                $vehiculoCliente = apiTexto($d, 'vehiculo_cliente', 150, true, 'la marca, modelo y año de tu vehículo');
                $tipoServicio = (string)($d['tipo_servicio'] ?? '');
                if (!in_array($tipoServicio, CAT_SERVICIOS_TALLER, true)) throw new InvalidArgumentException('Elige el servicio de taller.');
                $vin = strtoupper(trim((string)($d['vin'] ?? '')));
                if ($vin !== '' && !preg_match('/^[A-HJ-NPR-Z0-9]{17}$/', $vin)) throw new InvalidArgumentException('El VIN debe tener 17 caracteres (sin I, O ni Q).');
                $vin = $vin ?: null;
                if (($d['kilometraje'] ?? '') !== '' && $d['kilometraje'] !== null) {
                    $kilometraje = filter_var($d['kilometraje'], FILTER_VALIDATE_INT, ['options' => ['min_range' => 0, 'max_range' => 999999]]);
                    if ($kilometraje === false) throw new InvalidArgumentException('El kilometraje debe ser un número entre 0 y 999,999.');
                }
            } else {
                $producto = catProducto((int)($d['id_producto'] ?? 0), null, $sucursal['id_sucursal']);
                if (!$producto || !$producto['esVehiculo']) throw new InvalidArgumentException('Elige el vehículo de tu interés.');
                if ($tipo === 'apartado' && $producto['stock'] <= 0) {
                    $otras = array_filter(catStockPorSucursal($producto['id']), fn($s) => $s['stock'] > 0 && $s['id_sucursal'] !== $sucursal['id_sucursal']);
                    $sugerencia = $otras ? ' Disponible en: ' . implode(', ', array_column($otras, 'nombre')) . '.' : '';
                    throw new InvalidArgumentException("El {$producto['titulo']} no tiene unidades en {$sucursal['nombre']} (0 unidades disponibles).{$sugerencia}");
                }
                if ($tipo === 'apartado' && ($d['enganche'] ?? '') !== '' && $d['enganche'] !== null) {
                    $enganche = round((float)$d['enganche'], 2);
                    if ($enganche < 0 || $enganche > $producto['precio']) throw new InvalidArgumentException('El enganche debe estar entre $0 y el precio del vehículo.');
                }
            }
            $idProducto = $producto['id'] ?? 0;
            $fechaHora = "{$fecha} {$hora}:00";

            $pdo = db();
            $pdo->beginTransaction();
            try {
                $ocupacion = apiOcupacion($pdo, $sucursal['id_sucursal'], $fecha, $tipo, $idProducto, true);
                if (!apiHoraLibre($ocupacion, $hora, $tipo, $idProducto)) {
                    $pdo->rollBack();
                    apiError('Ese horario acaba de ocuparse. Elige otro, por favor.', 409);
                }
                $idOrden = null;
                $folioOrden = null;
                // Visita y apartado de vehículo = operación del concesionario → también llegan a POS → Web orders
                if (in_array($tipo, ['visita', 'apartado'], true)) {
                    $insO = $pdo->prepare("
                        INSERT INTO web_orders (tipo, id_producto, nombre, celular, email, enganche, fecha_visita, color, estado,
                                                id_cliente, id_sucursal, comentarios, fecha_creacion)
                        VALUES ('vehiculo', ?, ?, ?, ?, ?, ?, ?, 'pendiente', ?, ?, ?, NOW())");
                    $insO->execute([$idProducto, $nombre, $telefono, $email, $enganche, $fechaHora,
                                    $color ?: $producto['color'], (int)$cliente['id_cliente'], $sucursal['id_sucursal'],
                                    mb_substr(($tipo === 'apartado' ? 'Solicitud de apartado. ' : 'Visita para conocer el vehículo. ') . $comentarios, 0, 500)]);
                    $idOrden = (int)$pdo->lastInsertId();
                    $folioOrden = catFolio('WEB', $sucursal['id_sucursal'], $idOrden);
                    $pdo->prepare('UPDATE web_orders SET folio = ? WHERE id_orden = ?')->execute([$folioOrden, $idOrden]);
                }
                $insC = $pdo->prepare("
                    INSERT INTO citas (tipo, id_cliente, id_sucursal, id_producto, id_orden, fecha_hora, nombre, email, telefono,
                                       vehiculo_cliente, vin, kilometraje, tipo_servicio, comentarios)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULLIF(?, ''))");
                $insC->execute([$tipo, (int)$cliente['id_cliente'], $sucursal['id_sucursal'], $idProducto ?: null, $idOrden, $fechaHora,
                                $nombre, $email, $telefono, $vehiculoCliente, $vin, $kilometraje, $tipoServicio, $comentarios]);
                $idCita = (int)$pdo->lastInsertId();
                $folio = catFolio('CITA', $sucursal['id_sucursal'], $idCita);
                $pdo->prepare('UPDATE citas SET folio = ? WHERE id_cita = ?')->execute([$folio, $idCita]);

                $que = $producto ? $producto['titulo'] : $tipoServicio;
                catNotificar($pdo, (int)$cliente['id_cliente'], 'cita', catTipoCitaTexto($tipo) . " agendada ({$folio})",
                    "{$que} · {$sucursal['nombre']} · " . catFecha($fechaHora) . '. Te esperamos.', 'perfil.php#citas');
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                throw $e;
            }
            apiOk(['folio' => $folio, 'folioOrden' => $folioOrden, 'fecha' => catFecha($fechaHora), 'sucursal' => $sucursal['nombre'],
                   'mensaje' => catTipoCitaTexto($tipo) . ' agendada correctamente.']);
        }

        case 'mis_citas': {
            $cliente = apiRequerirCliente();
            apiOk(['citas' => catCitasCliente((int)$cliente['id_cliente'])]);
        }

        case 'cancelar_cita': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $idCita = (int)($d['id_cita'] ?? 0);
            $cita = null;
            foreach (catCitasCliente((int)$cliente['id_cliente']) as $c) if ($c['id'] === $idCita) $cita = $c;
            if (!$cita) apiError('No encontramos esa cita en tu cuenta.', 404);
            if (!$cita['cancelable']) apiError('Esta cita ya no se puede cancelar en línea.', 409);
            $pdo = db();
            $pdo->beginTransaction();
            try {
                $pdo->prepare("UPDATE citas SET estado = 'cancelada' WHERE id_cita = ? AND id_cliente = ?")->execute([$idCita, (int)$cliente['id_cliente']]);
                $pdo->prepare("UPDATE web_orders w JOIN citas c ON c.id_orden = w.id_orden SET w.estado = 'cancelada' WHERE c.id_cita = ? AND w.estado = 'pendiente'")->execute([$idCita]);
                catNotificar($pdo, (int)$cliente['id_cliente'], 'cita', "Cita {$cita['folio']} cancelada", "{$cita['tipoTexto']} del {$cita['fechaTexto']}.", 'perfil.php#citas');
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                throw $e;
            }
            apiOk(['mensaje' => 'Cita cancelada.']);
        }

        // ---------- Solicitudes (página de contacto) ----------
        case 'solicitud': {
            apiLimite('solicitud', 6, 600);
            $d = apiEntrada();
            $tipos = ['informacion', 'cotizacion', 'contacto', 'queja', 'sugerencia', 'garantia', 'seguro', 'financiamiento', 'postventa', 'otro'];
            $tipo = (string)($d['tipo'] ?? '');
            if (!in_array($tipo, $tipos, true)) throw new InvalidArgumentException('Elige el motivo de tu solicitud.');
            $nombre = apiTexto($d, 'nombre', 150, true, 'tu nombre');
            $email = apiEmail($d);
            $telefono = apiTelefono($d, 'telefono', false);
            $asunto = apiTexto($d, 'asunto', 150, false);
            $mensaje = apiTextoLargo($d, 'mensaje', 3000, in_array($tipo, ['contacto', 'queja', 'sugerencia', 'garantia', 'otro'], true));
            $idSucursal = (int)($d['id_sucursal'] ?? 0);
            if ($idSucursal && !catSucursalPorId($idSucursal)) throw new InvalidArgumentException('La sucursal no es válida.');
            $idProducto = (int)($d['id_producto'] ?? 0);
            if ($idProducto && !catProducto($idProducto)) throw new InvalidArgumentException('El producto no es válido.');
            $datos = null;
            if (isset($d['datos']) && is_array($d['datos'])) {
                $datos = json_encode($d['datos'], JSON_UNESCAPED_UNICODE);
                if (strlen((string)$datos) > 4000) throw new InvalidArgumentException('La información adjunta es demasiado grande.');
            }
            $cliente = catClienteActual();
            $pdo = db();
            $ins = $pdo->prepare("INSERT INTO solicitudes (tipo, id_cliente, id_sucursal, id_producto, nombre, email, telefono, asunto, mensaje, datos)
                                  VALUES (?, ?, ?, ?, ?, ?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), ?)");
            $ins->execute([$tipo, $cliente['id_cliente'] ?? null, $idSucursal ?: null, $idProducto ?: null, $nombre, $email, $telefono, $asunto, $mensaje, $datos]);
            $id = (int)$pdo->lastInsertId();
            $folio = catFolio('SOL', $idSucursal, $id);
            $pdo->prepare('UPDATE solicitudes SET folio = ? WHERE id_solicitud = ?')->execute([$folio, $id]);
            if ($cliente) {
                catNotificar($pdo, (int)$cliente['id_cliente'], 'solicitud', "Recibimos tu solicitud {$folio}",
                    'Un asesor te contactará en un máximo de 24 horas hábiles.', 'perfil.php#solicitudes');
            }
            apiOk(['folio' => $folio, 'mensaje' => 'Recibimos tu solicitud. Un asesor te contactará pronto.']);
        }

        // ---------- Vehículos de interés ----------
        case 'favorito': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $p = catProducto((int)($d['id_producto'] ?? 0));
            if (!$p) apiError('El producto no existe.', 404);
            $pdo = db();
            $del = $pdo->prepare('DELETE FROM favoritos_catalogo WHERE id_cliente = ? AND id_producto = ?');
            $del->execute([(int)$cliente['id_cliente'], $p['id']]);
            $favorito = false;
            if ($del->rowCount() === 0) {
                $pdo->prepare('INSERT INTO favoritos_catalogo (id_cliente, id_producto) VALUES (?, ?)')->execute([(int)$cliente['id_cliente'], $p['id']]);
                $favorito = true;
            }
            apiOk(['favorito' => $favorito, 'mensaje' => $favorito ? "{$p['titulo']} se guardó en tus vehículos de interés." : 'Se quitó de tus vehículos de interés.']);
        }

        // ---------- Perfil ----------
        case 'perfil': {
            $cliente = apiRequerirCliente();
            $id = (int)$cliente['id_cliente'];
            $favoritosIds = catFavoritosIds($id);
            apiOk([
                'cliente' => array_intersect_key($cliente, array_flip(['id_cliente', 'nombre', 'nombres', 'apellidos', 'email', 'celular',
                    'direccion', 'ciudad', 'entidad_federativa', 'codigo_postal', 'id_sucursal_preferida', 'marca_interes',
                    'notif_email', 'notif_sms', 'notif_promociones', 'fecha_registro'])) + ['fechaRegistro' => catFecha($cliente['fecha_registro'], false)],
                'credito' => (int)$cliente['abonos_totales'] > 0 ? [
                    'articulo' => $cliente['articulo'], 'adeudo' => (float)$cliente['total_adeudo'], 'abono' => (float)$cliente['monto_abono'],
                    'pagados' => (int)$cliente['abonos_pagados'], 'totales' => (int)$cliente['abonos_totales']] : null,
                'pedidos' => catPedidosCliente($id),
                'citas' => catCitasCliente($id),
                'favoritos' => $favoritosIds ? catBuscarProductos(['ids' => $favoritosIds]) : [],
                'notificaciones' => catNotificacionesCliente($id),
                'garantias' => catGarantiasCliente($id),
                'compras' => catComprasSucursal($id),
                'solicitudes' => catSolicitudesCliente($id),
                'sucursales' => array_map('apiSucursal', catSucursales())
            ]);
        }

        case 'perfil_actualizar': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $nombres = apiTexto($d, 'nombres', 80, true, 'tu nombre');
            $apellidos = apiTexto($d, 'apellidos', 100, true, 'tus apellidos');
            $celular = apiTelefono($d, 'celular', true);
            $direccion = apiTexto($d, 'direccion', 255, false);
            $ciudad = apiTexto($d, 'ciudad', 100, false);
            $entidad = apiTexto($d, 'entidad_federativa', 80, false);
            $cp = apiCodigoPostal($d);
            $idSucursal = (int)($d['id_sucursal_preferida'] ?? 0);
            if ($idSucursal && !catSucursalPorId($idSucursal)) throw new InvalidArgumentException('La sucursal preferida no es válida.');
            $marca = in_array($d['marca_interes'] ?? '', CAT_MARCAS, true) ? $d['marca_interes'] : null;
            $email = apiEmail($d);
            $pdo = db();
            if ($email !== mb_strtolower((string)$cliente['email'])) {
                // Cambiar el correo (usuario de acceso) exige la contraseña actual y que el correo no esté en uso
                $h = $pdo->prepare('SELECT password_hash FROM clientes WHERE id_cliente = ?');
                $h->execute([(int)$cliente['id_cliente']]);
                if (!password_verify((string)($d['password_actual'] ?? ''), (string)$h->fetchColumn())) {
                    throw new InvalidArgumentException('Para cambiar tu correo escribe tu contraseña actual.');
                }
                $uso = $pdo->prepare('SELECT COUNT(*) FROM clientes WHERE email = ? AND id_cliente <> ?');
                $uso->execute([$email, (int)$cliente['id_cliente']]);
                if ((int)$uso->fetchColumn() > 0) throw new InvalidArgumentException('Ese correo ya está registrado en otra cuenta.');
            }
            $pdo->prepare("
                UPDATE clientes SET nombre = ?, nombres = ?, apellidos = ?, email = ?, celular = ?, direccion = NULLIF(?, ''),
                       ciudad = NULLIF(?, ''), entidad_federativa = NULLIF(?, ''), codigo_postal = NULLIF(?, ''),
                       id_sucursal_preferida = ?, marca_interes = ?, notif_email = ?, notif_sms = ?, notif_promociones = ?
                 WHERE id_cliente = ?")
                ->execute(["{$nombres} {$apellidos}", $nombres, $apellidos, $email, $celular, $direccion, $ciudad, $entidad, $cp,
                           $idSucursal ?: null, $marca, !empty($d['notif_email']) ? 1 : 0, !empty($d['notif_sms']) ? 1 : 0,
                           !empty($d['notif_promociones']) ? 1 : 0, (int)$cliente['id_cliente']]);
            apiOk(['mensaje' => 'Tus datos se guardaron correctamente.']);
        }

        case 'cambiar_password': {
            $cliente = apiRequerirCliente();
            $d = apiEntrada();
            $pdo = db();
            $h = $pdo->prepare('SELECT password_hash FROM clientes WHERE id_cliente = ?');
            $h->execute([(int)$cliente['id_cliente']]);
            if (!password_verify((string)($d['actual'] ?? ''), (string)$h->fetchColumn())) throw new InvalidArgumentException('La contraseña actual no es correcta.');
            $nueva = (string)($d['nueva'] ?? '');
            apiPasswordNueva($nueva);
            if ($nueva !== (string)($d['confirmacion'] ?? '')) throw new InvalidArgumentException('Las contraseñas nuevas no coinciden.');
            $pdo->prepare('UPDATE clientes SET password_hash = ? WHERE id_cliente = ?')->execute([password_hash($nueva, PASSWORD_DEFAULT), (int)$cliente['id_cliente']]);
            session_regenerate_id(true);
            catNotificar($pdo, (int)$cliente['id_cliente'], 'cuenta', 'Contraseña actualizada', 'Si no fuiste tú, comunícate con nosotros de inmediato.');
            apiOk(['mensaje' => 'Tu contraseña se actualizó.']);
        }

        case 'notificaciones_leidas': {
            $cliente = apiRequerirCliente();
            db()->prepare('UPDATE notificaciones SET leida = 1 WHERE id_cliente = ? AND leida = 0')->execute([(int)$cliente['id_cliente']]);
            apiOk();
        }

        default:
            apiError('Acción no reconocida.', 404);
    }
} catch (InvalidArgumentException $e) {
    apiError($e->getMessage(), 422);
} catch (Throwable $e) {
    error_log('[Catalogo API] ' . $accion . ': ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    apiError('Ocurrió un error inesperado. Inténtalo de nuevo en unos momentos.', 500);
}
