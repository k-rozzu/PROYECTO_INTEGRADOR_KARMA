<?php
declare(strict_types=1);

/* KARMA · Autorización de empleado para las acciones sensibles del Punto de Venta (gafete con QR o código escrito a mano).
   El navegador SOLO obtiene el texto del gafete (ej. EMP-0001) y lo envía; la decisión se toma AQUÍ contra la base de datos:
   el código debe existir y pertenecer al MISMO usuario que inició sesión, con el mismo rol de esa sesión y en estado activo.
   Si todo se cumple se entrega un permiso de UN SOLO USO que vive en la sesión PHP, ligado a la acción, a su referencia
   (ticket, garantía u orden), al usuario y con vigencia corta. api.php lo exige y lo consume ANTES de ejecutar la operación.
   Documentación: docs/AUTORIZACION_EMPLEADO.md */

require_once dirname(__DIR__) . '/Login/sesion_pos.php';

// Acciones protegidas (nombres internos; al usuario no se le muestran)
const POS_ACCIONES_PROTEGIDAS = ['VENTA', 'CREDITO', 'GARANTIA', 'ORDEN_WEB', 'ABONO'];
// Segundos que dura una autorización sin usarse (el navegador envía la operación justo después de autorizar)
const POS_AUTORIZACION_VIGENCIA = 60;
// Freno a intentos: tras 5 códigos rechazados seguidos hay que esperar 60 segundos
const POS_AUTORIZACION_MAX_FALLOS = 5;
const POS_AUTORIZACION_ESPERA = 60;
// Formato del gafete (el trigger auto_codigo_empleado genera EMP- + 4 dígitos). Solo filtra basura: la BD decide.
const POS_FORMATO_CODIGO_EMPLEADO = '/^EMP-\d{4,16}$/';

/* ===== Protección CSRF de la sesión del POS ===== */

// Token CSRF de la sesión (index.php lo publica en <meta name="karma-csrf">; el JS lo manda en el encabezado X-CSRF-Token)
function posTokenCsrf(): string {
    posIniciarSesion();
    if (empty($_SESSION['pos_csrf'])) $_SESSION['pos_csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['pos_csrf'];
}

// Revisa que la petición traiga el token CSRF de esta sesión (comparación en tiempo constante)
function posCsrfValido(): bool {
    $recibido = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    $esperado = (string)($_SESSION['pos_csrf'] ?? '');
    return $recibido !== '' && $esperado !== '' && hash_equals($esperado, $recibido);
}

/* ===== Rutas de api.php que ejecutan una acción sensible ===== */

// De cada petición protegida se obtiene [acción, referencia] a la que debe estar ligada la autorización.
// crear_venta es CREDITO si trae datos de crédito (misma regla que usa crearVenta) y VENTA si no. Otras rutas: null.
function posAccionProtegida(string $ruta, array $datos): ?array {
    switch ($ruta) {
        case 'crear_venta':
            $esCredito = isset($datos['credito']) && is_array($datos['credito']) && $datos['credito'];
            return [$esCredito ? 'CREDITO' : 'VENTA', (int)($datos['ticket_numero'] ?? 0)];
        case 'cobrar_abono':
            // Abono mensual de un crédito: ligado al ticket en el que se cobra
            return ['ABONO', (int)($datos['ticket_numero'] ?? 0)];
        case 'preparar_credito':
            // Crédito: el gafete se valida después de cobrar el enganche y antes de generar el contrato
            return ['CREDITO', (int)($datos['ticket_numero'] ?? 0)];
        case 'cobrar_orden_web':
        case 'cancelar_orden_web':
            return ['ORDEN_WEB', (int)($datos['id_orden'] ?? 0)];
        case 'aplicar_garantia':
            return ['GARANTIA', (int)($datos['id_garantia'] ?? 0)];
    }
    return null;
}

/* ===== Validación del empleado contra la base de datos ===== */

// Limpia lo capturado: sin espacios y en mayúsculas (" emp-0001 " -> "EMP-0001")
function posNormalizarCodigoEmpleado(string $codigo): string {
    return strtoupper((string)preg_replace('/\s+/u', '', $codigo));
}

// Busca el código en `usuarios` (consulta preparada). LEFT JOIN con `roles` para detectar un rol inexistente en vez de ocultarlo.
function posBuscarEmpleado(PDO $pdo, string $codigo): ?array {
    $stmt = $pdo->prepare("
        SELECT u.id_usuario, u.id_rol, u.id_sucursal, u.estado, u.codigo_empleado,
               r.id_rol AS rol_registrado, r.nombre_rol
        FROM usuarios u
        LEFT JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.codigo_empleado = ?
        LIMIT 1
    ");
    $stmt->execute([$codigo]);
    $fila = $stmt->fetch(PDO::FETCH_ASSOC);
    return $fila ?: null;
}

// Decide si el dueño del código puede autorizar en ESTA sesión. Regresa la lista de motivos de rechazo (vacía = autorizado).
// $sesion = usuario de la sesión revalidado contra la BD en esta misma petición (posRequerirApi); $rolLogin = rol con el que inició sesión.
function posEvaluarEmpleado(?array $empleado, string $codigo, array $sesion, string $rolLogin): array {
    // [3] el código existe (comparación exacta: la intercalación de MySQL no distingue mayúsculas ni espacios finales)
    if (!$empleado || (string)($empleado['codigo_empleado'] ?? '') !== $codigo) return ['CODIGO_INEXISTENTE'];
    // [4] usuario asociado
    if (empty($empleado['id_usuario'])) return ['USUARIO_INEXISTENTE'];

    $motivos = [];
    // [5] tiene un id_rol que existe en `roles`
    if ($empleado['id_rol'] === null || $empleado['rol_registrado'] === null || (string)($empleado['nombre_rol'] ?? '') === '') {
        $motivos[] = 'SIN_ROL';
    } elseif ((int)$empleado['id_rol'] !== (int)($sesion['id_rol'] ?? 0)
        || $empleado['nombre_rol'] !== ($sesion['nombre_rol'] ?? null)
        || $empleado['nombre_rol'] !== $rolLogin
        || !in_array($empleado['nombre_rol'], POS_ROLES_PERMITIDOS, true)) {
        // [6] mismo rol que la sesión activa (el actual en la BD y el registrado al iniciar sesión) y con acceso al POS
        $motivos[] = 'ROL_DISTINTO';
    }
    // [6] es exactamente el mismo usuario que inició sesión: nadie puede autorizar en la sesión de otro (ni gerente ni admin)
    if ((int)$empleado['id_usuario'] !== (int)($sesion['id_usuario'] ?? 0)) $motivos[] = 'USUARIO_DISTINTO';
    // [7] usuario activo
    if (($empleado['estado'] ?? '') !== 'activo') $motivos[] = 'INACTIVO';
    return $motivos;
}

// Mensaje para la persona en caja: no revela datos internos (rol, id o estado de otros empleados); el detalle queda en la auditoría
function posMensajeRechazo(string $motivo): string {
    return match ($motivo) {
        'FORMATO_INVALIDO', 'CODIGO_INEXISTENTE', 'USUARIO_INEXISTENTE' => 'El código de empleado no es válido.',
        'SIN_ROL', 'ROL_DISTINTO' => 'El usuario no tiene permisos para realizar esta acción.',
        'USUARIO_DISTINTO' => 'Empleado no autorizado: el gafete no corresponde a la sesión activa.',
        'INACTIVO' => 'El usuario se encuentra inactivo.',
        'ACCION_NO_PROTEGIDA', 'REFERENCIA_INVALIDA', 'METODO_HTTP' => 'Solicitud de autorización no válida.',
        'CSRF' => 'Solicitud no válida. Recarga la página e inténtalo de nuevo.',
        'DEMASIADOS_INTENTOS' => 'Demasiados intentos. Espera un minuto e inténtalo de nuevo.',
        'SIN_AUTORIZACION', 'PERMISO_INVALIDO', 'PERMISO_VENCIDO', 'ACCION_DISTINTA', 'REFERENCIA_DISTINTA', 'SESION_DISTINTA'
            => 'Se requiere la autorización del empleado. Escanea tu gafete para continuar.',
        default => 'Autorización rechazada.',
    };
}

/* ===== Auditoría (tabla autorizaciones_empleado, ver Database/autorizacion_empleado.sql) ===== */

// Registra un evento. Regresa su id o null si no se pudo guardar (queda en el log de PHP)
function posRegistrarAutorizacion(PDO $pdo, array $e): ?int {
    try {
        $pdo->prepare("
            INSERT INTO autorizaciones_empleado
            (etapa, accion, referencia, codigo_empleado, metodo, id_usuario_sesion, id_usuario_empleado, id_sucursal, resultado, motivo, operacion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ")->execute([
            $e['etapa'],
            substr((string)$e['accion'], 0, 20) ?: 'DESCONOCIDA',
            !empty($e['referencia']) ? (int)$e['referencia'] : null,
            ($e['codigo'] ?? '') !== '' ? substr((string)$e['codigo'], 0, 20) : null,
            $e['metodo'] ?? null,
            $e['id_usuario_sesion'] ?? null,
            $e['id_usuario_empleado'] ?? null,
            $e['id_sucursal'] ?? null,
            $e['resultado'],
            $e['motivo'] ?? null,
            $e['operacion'] ?? null
        ]);
        return (int)$pdo->lastInsertId();
    } catch (Throwable $ex) {
        error_log('[KARMA autorización] No se pudo guardar la auditoría: ' . $ex->getMessage());
        return null;
    }
}

/* ===== Freno a intentos repetidos (por sesión) ===== */

function posAutorizacionBloqueada(): bool {
    $f = $_SESSION['pos_autorizacion_fallos'] ?? ['n' => 0, 't' => 0];
    if ($f['n'] < POS_AUTORIZACION_MAX_FALLOS) return false;
    if (time() - $f['t'] < POS_AUTORIZACION_ESPERA) return true;
    unset($_SESSION['pos_autorizacion_fallos']);
    return false;
}

function posContarFalloAutorizacion(): void {
    $f = $_SESSION['pos_autorizacion_fallos'] ?? ['n' => 0, 't' => 0];
    $_SESSION['pos_autorizacion_fallos'] = ['n' => $f['n'] + 1, 't' => time()];
}

/* ===== Paso 1: autorizar (endpoint api.php?action=autorizar_empleado) ===== */

// Recibe SOLO {codigo_empleado, accion, referencia, metodo}. Todo lo demás (usuario, rol, estado) lo resuelve el servidor.
// Regresa ['ok' => true, 'permiso' => ..., 'vigencia' => ...] o ['ok' => false, 'error' => mensaje, 'estado' => código HTTP].
function posAutorizarEmpleado(PDO $pdo, array $sesion, array $datos): array {
    $accion = strtoupper(trim((string)($datos['accion'] ?? '')));
    $evento = [
        'etapa' => 'autorizacion',
        'accion' => $accion,
        'referencia' => (int)($datos['referencia'] ?? 0),
        'codigo' => posNormalizarCodigoEmpleado((string)($datos['codigo_empleado'] ?? '')),
        'metodo' => ($datos['metodo'] ?? '') === 'qr' ? 'qr' : 'manual',
        'id_usuario_sesion' => (int)$sesion['id_usuario'],
        'id_usuario_empleado' => null,
        'id_sucursal' => $sesion['id_sucursal'] !== null ? (int)$sesion['id_sucursal'] : null
    ];
    // Un intento nuevo invalida cualquier autorización anterior que no se haya usado
    unset($_SESSION['pos_autorizacion']);

    // [8] la sesión del POS ya la validó posRequerirApi; además: POST, token CSRF y freno a intentos
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') return posRechazarAutorizacion($pdo, $evento, ['METODO_HTTP'], 405, false);
    if (!posCsrfValido()) return posRechazarAutorizacion($pdo, $evento, ['CSRF'], 403, false);
    if (posAutorizacionBloqueada()) return posRechazarAutorizacion($pdo, $evento, ['DEMASIADOS_INTENTOS'], 429, false);
    // [9] solo acciones protegidas, ligadas a una referencia concreta
    if (!in_array($accion, POS_ACCIONES_PROTEGIDAS, true)) return posRechazarAutorizacion($pdo, $evento, ['ACCION_NO_PROTEGIDA'], 400, false);
    if ($evento['referencia'] <= 0) return posRechazarAutorizacion($pdo, $evento, ['REFERENCIA_INVALIDA'], 400, false);
    // [1] código recibido y [2] con formato válido (solo filtro: no autoriza nada por sí mismo)
    if (!preg_match(POS_FORMATO_CODIGO_EMPLEADO, $evento['codigo'])) return posRechazarAutorizacion($pdo, $evento, ['FORMATO_INVALIDO'], 403, true);

    // [3]–[7] la base de datos tiene la última palabra
    $empleado = posBuscarEmpleado($pdo, $evento['codigo']);
    $evento['id_usuario_empleado'] = $empleado ? (int)$empleado['id_usuario'] : null;
    $motivos = posEvaluarEmpleado($empleado, $evento['codigo'], $sesion, (string)($_SESSION['pos_usuario']['rol'] ?? ''));
    if ($motivos) return posRechazarAutorizacion($pdo, $evento, $motivos, 403, true);

    // AUTORIZADO. Sin registro de auditoría no se autoriza (falla cerrada)
    $idRegistro = posRegistrarAutorizacion($pdo, $evento + ['resultado' => 'autorizado']);
    if (!$idRegistro) return ['ok' => false, 'error' => posMensajeRechazo('AUDITORIA'), 'estado' => 503];
    unset($_SESSION['pos_autorizacion_fallos']);

    // [10] Permiso de un solo uso: el navegador recibe el valor; la sesión solo guarda su huella SHA-256 y a qué está ligado
    $permiso = bin2hex(random_bytes(32));
    $_SESSION['pos_autorizacion'] = [
        'huella' => hash('sha256', $permiso),
        'accion' => $accion,
        'referencia' => $evento['referencia'],
        'id_usuario' => (int)$sesion['id_usuario'],
        'id_rol' => (int)$sesion['id_rol'],
        'codigo' => $evento['codigo'],
        'expira' => time() + POS_AUTORIZACION_VIGENCIA,
        'id_registro' => $idRegistro
    ];
    return ['ok' => true, 'permiso' => $permiso, 'vigencia' => POS_AUTORIZACION_VIGENCIA];
}

// Registra el rechazo, cuenta el fallo si aplica y arma la respuesta (mensaje del primer motivo)
function posRechazarAutorizacion(PDO $pdo, array $evento, array $motivos, int $estado, bool $contarFallo): array {
    if ($contarFallo) posContarFalloAutorizacion();
    posRegistrarAutorizacion($pdo, $evento + ['resultado' => 'denegado', 'motivo' => implode(',', $motivos)]);
    return ['ok' => false, 'error' => posMensajeRechazo($motivos[0]), 'estado' => $estado];
}

/* ===== Paso 2: exigir y consumir la autorización (api.php, antes de la función original) ===== */

// Regresa null si la petición trae un permiso válido para ESTA acción y referencia (y lo consume), o el mensaje de rechazo.
// Solo lee/escribe la sesión y la auditoría: si falla, la operación original nunca se ejecuta y no se toca ninguna tabla de negocio.
function posConsumirAutorizacion(PDO $pdo, array $sesion, string $accion, int $referencia, string $operacion): ?string {
    $permiso = (string)($_SERVER['HTTP_X_KARMA_AUTORIZACION'] ?? '');
    $pendiente = $_SESSION['pos_autorizacion'] ?? null;
    // Un solo uso: el permiso se descarta en cualquier intento, salga bien o mal
    unset($_SESSION['pos_autorizacion']);

    $motivo = null;
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') $motivo = 'METODO_HTTP';
    elseif (!posCsrfValido()) $motivo = 'CSRF';
    elseif ($permiso === '' || !is_array($pendiente)) $motivo = 'SIN_AUTORIZACION';
    elseif (!hash_equals((string)$pendiente['huella'], hash('sha256', $permiso))) $motivo = 'PERMISO_INVALIDO';
    elseif (time() > (int)$pendiente['expira']) $motivo = 'PERMISO_VENCIDO';
    elseif ($pendiente['accion'] !== $accion) $motivo = 'ACCION_DISTINTA';
    elseif ($referencia <= 0 || (int)$pendiente['referencia'] !== $referencia) $motivo = 'REFERENCIA_DISTINTA';
    elseif ((int)$pendiente['id_usuario'] !== (int)$sesion['id_usuario'] || (int)$pendiente['id_rol'] !== (int)$sesion['id_rol']) $motivo = 'SESION_DISTINTA';
    else {
        // También al ejecutar, la BD tiene la última palabra: el gafete debe seguir siendo válido para esta sesión
        $empleado = posBuscarEmpleado($pdo, (string)$pendiente['codigo']);
        $motivos = posEvaluarEmpleado($empleado, (string)$pendiente['codigo'], $sesion, (string)($_SESSION['pos_usuario']['rol'] ?? ''));
        if ($motivos) $motivo = implode(',', $motivos);
    }

    if ($motivo !== null) {
        posRegistrarAutorizacion($pdo, [
            'etapa' => 'operacion', 'accion' => $accion, 'referencia' => $referencia,
            'codigo' => is_array($pendiente) ? (string)$pendiente['codigo'] : '', 'metodo' => null,
            'id_usuario_sesion' => (int)$sesion['id_usuario'], 'id_usuario_empleado' => null,
            'id_sucursal' => $sesion['id_sucursal'] !== null ? (int)$sesion['id_sucursal'] : null,
            'resultado' => 'denegado', 'motivo' => $motivo, 'operacion' => $operacion
        ]);
        return posMensajeRechazo(explode(',', $motivo)[0]);
    }

    // Válido: queda registrado qué operación usó la autorización y cuándo
    $pdo->prepare("UPDATE autorizaciones_empleado SET fecha_uso = NOW(), operacion = ? WHERE id_autorizacion = ?")
        ->execute([$operacion, (int)$pendiente['id_registro']]);
    return null;
}
