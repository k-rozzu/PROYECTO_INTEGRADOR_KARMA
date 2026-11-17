<?php
declare(strict_types=1);

/* API de solicitudes de garantía del Panel de Gerente (Home/gerente.html → pestaña «Notificaciones»).
   El cajero llena el formulario en el Punto de Venta (api.php → aplicar_garantia) y la solicitud llega aquí 'pendiente';
   el gerente de ESA sucursal la revisa y la acepta o la deniega con motivo. Al aceptarla, el trigger de Database/garantias.sql
   deja la garantía 'aplicada' y el cajero recibe el aviso en el POS (api.php → avisos_garantia).
   Las reglas finales (gerente activo, nunca quien la envió, motivo obligatorio, no resolver dos veces) viven en esos triggers. */
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
require_once __DIR__ . '/../PuntoDeVenta/conexion.php';
require_once __DIR__ . '/../Login/sesion_pos.php';

// Responde en JSON con su código HTTP y termina
function responder(array $datos, int $estado = 200): never {
    http_response_code($estado);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit;
}

// Exclusivo de cuentas Gerente con sucursal asignada (sesión única del sistema KARMAPOS, revalidada contra la BD)
function exigirGerente(): array {
    $u = posUsuarioValidado(db());
    if (!$u) responder(['ok' => false, 'error' => 'Inicia sesión para continuar.'], 401);
    if (posDebeCambiarPassword($u)) posResponderCambioPassword();
    if ($u['nombre_rol'] !== 'Gerente') responder(['ok' => false, 'error' => 'Solo un gerente puede revisar solicitudes de garantía.'], 403);
    if ($u['id_sucursal'] === null) responder(['ok' => false, 'error' => 'Tu cuenta no tiene sucursal asignada.'], 403);
    return $u;
}

try {
    $gerente = exigirGerente();
    switch ($_GET['action'] ?? '') {
        case 'listar':
            listarSolicitudes($gerente);
            break;
        case 'resolver':
            resolverSolicitud($gerente);
            break;
        default:
            responder(['ok' => false, 'error' => 'Acción no reconocida.'], 404);
    }
} catch (Throwable $e) {
    responder(['ok' => false, 'error' => 'Error interno del servidor.'], 500);
}

/* Solicitudes de la sucursal del gerente: las pendientes (de la más antigua a la más nueva, se atienden en orden de llegada)
   y las resueltas en los últimos 30 días como historial */
function listarSolicitudes(array $gerente): never {
    $stmt = db()->prepare("
        SELECT
            s.id_solicitud AS id, s.folio, s.estado, s.motivo_rechazo AS motivoRechazo, s.datos_json,
            DATE_FORMAT(s.fecha_solicitud, '%Y-%m-%dT%H:%i:%s') AS fechaSolicitud,
            DATE_FORMAT(s.fecha_resolucion, '%Y-%m-%dT%H:%i:%s') AS fechaResolucion,
            uc.nombre AS cajero, ur.nombre AS resolvio,
            COALESCE(g.cliente_nombre, c.nombre) AS cliente,
            COALESCE(g.cliente_celular, c.celular) AS celular,
            COALESCE(g.cliente_email, c.email) AS email,
            p.nombre AS articulo, g.vin,
            g.id_venta AS ventaId, g.id_sucursal AS sucursalVenta,
            DATE_FORMAT(g.fecha_compra, '%Y-%m-%dT%H:%i:%s') AS fechaCompra,
            DATE_FORMAT(g.fecha_expiracion, '%Y-%m-%dT%H:%i:%s') AS fechaExpiracion,
            g.fecha_expiracion > s.fecha_solicitud AS vigenteAlSolicitar
        FROM solicitudes_garantia s
        JOIN garantias g ON g.id_garantia = s.id_garantia
        JOIN productos p ON p.id_producto = g.id_producto
        LEFT JOIN clientes c ON c.id_cliente = g.id_cliente
        JOIN usuarios uc ON uc.id_usuario = s.id_usuario_solicita
        LEFT JOIN usuarios ur ON ur.id_usuario = s.id_usuario_resuelve
        WHERE s.id_sucursal = ?
          AND (s.estado = 'pendiente' OR s.fecha_resolucion >= NOW() - INTERVAL 30 DAY)
        ORDER BY s.estado = 'pendiente' DESC,
                 CASE WHEN s.estado = 'pendiente' THEN s.fecha_solicitud END ASC,
                 s.fecha_resolucion DESC
    ");
    $stmt->execute([(int)$gerente['id_sucursal']]);
    $solicitudes = $stmt->fetchAll();

    // Fechas con la zona del proyecto para que el navegador las muestre a la hora de la sucursal
    $zona = (new DateTimeImmutable('now'))->format('P');
    foreach ($solicitudes as &$s) {
        $s['id'] = (int)$s['id'];
        $s['ventaId'] = $s['ventaId'] !== null ? (int)$s['ventaId'] : null;
        $s['folioVenta'] = $s['ventaId'] ? sprintf('KRM-%02d-%06d', (int)$s['sucursalVenta'], $s['ventaId']) : null;
        $s['vigenteAlSolicitar'] = (int)$s['vigenteAlSolicitar'] === 1;
        foreach (['fechaSolicitud', 'fechaResolucion', 'fechaCompra', 'fechaExpiracion'] as $campo) {
            if ($s[$campo] !== null) $s[$campo] .= $zona;
        }
        // Formulario que llenó el cajero (propietario, VIN, kilometraje, síntoma, condiciones, evidencia, firmas…)
        $s['reporte'] = json_decode((string)$s['datos_json'], true) ?: [];
        unset($s['datos_json'], $s['sucursalVenta']);
    }
    unset($s);

    responder(['ok' => true, 'solicitudes' => $solicitudes]);
}

/* Acepta o deniega una solicitud pendiente de la sucursal del gerente (denegar exige el motivo) */
function resolverSolicitud(array $gerente): never {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') responder(['ok' => false, 'error' => 'Usa POST.'], 405);
    if (!posMismoOrigen()) responder(['ok' => false, 'error' => 'Origen no permitido.'], 403);
    // Solo JSON: un formulario de otro sitio no puede enviar este tipo de contenido sin permiso del navegador
    if (stripos((string)($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json') === false) {
        responder(['ok' => false, 'error' => 'Solicitud no válida.'], 415);
    }

    $datos = json_decode((string)file_get_contents('php://input'), true);
    $idSolicitud = (int)($datos['id_solicitud'] ?? 0);
    $decision = (string)($datos['decision'] ?? '');
    $motivo = mb_substr(trim((string)($datos['motivo'] ?? '')), 0, 500);

    $estados = ['aceptar' => 'confirmada', 'denegar' => 'denegada'];
    if (!isset($estados[$decision])) responder(['ok' => false, 'error' => 'Indica si aceptas o deniegas la solicitud.'], 400);
    if ($decision === 'denegar' && $motivo === '') responder(['ok' => false, 'error' => 'Escribe el motivo por el que se deniega la garantía.'], 400);

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT folio, estado, id_sucursal FROM solicitudes_garantia WHERE id_solicitud = ? FOR UPDATE");
        $stmt->execute([$idSolicitud]);
        $solicitud = $stmt->fetch();
        if (!$solicitud || (int)$solicitud['id_sucursal'] !== (int)$gerente['id_sucursal']) {
            $pdo->rollBack();
            responder(['ok' => false, 'error' => 'La solicitud no existe en tu sucursal.'], 404);
        }
        if ($solicitud['estado'] !== 'pendiente') {
            $pdo->rollBack();
            responder(['ok' => false, 'error' => "La solicitud {$solicitud['folio']} ya fue resuelta."], 409);
        }

        $pdo->prepare("UPDATE solicitudes_garantia SET estado = ?, motivo_rechazo = ?, id_usuario_resuelve = ? WHERE id_solicitud = ?")
            ->execute([$estados[$decision], $decision === 'denegar' ? $motivo : null, (int)$gerente['id_usuario'], $idSolicitud]);
        $pdo->commit();
    } catch (PDOException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        // Mensajes de los triggers (SIGNAL 45000): se muestran tal cual al gerente
        if (($e->errorInfo[0] ?? '') === '45000') responder(['ok' => false, 'error' => (string)($e->errorInfo[2] ?? 'No se pudo resolver la solicitud.')], 409);
        throw $e;
    }

    $folio = $solicitud['folio'];
    responder(['ok' => true, 'message' => $decision === 'aceptar'
        ? "Garantía {$folio} aceptada. Se notificó al cajero para continuar con el cliente."
        : "Garantía {$folio} denegada. El cajero verá el motivo en Garantías."]);
}
?>
