<?php
declare(strict_types=1);

/* KARMA · Cobro con tarjeta mediante Mercado Pago Point (API de Orders). Lo cargan api.php y mercadopago_webhook.php.
   1) mp_iniciar_cobro  -> revisa el ticket con las MISMAS reglas del efectivo (precios de la BD, VIN y existencias; no descuenta
                           nada), guarda el cobro y manda la orden a la terminal de la caja con una clave de idempotencia.
   2) La persona paga en la Point. El resultado llega por el Webhook (mercadopago_webhook.php) o por mp_estado_cobro, que la
      pantalla de cobro consulta cada 2 s. Las dos rutas consultan la orden REAL en la API y la aplican con mpProcesarOrden().
   3) Pago aprobado -> mpRegistrarAprobado() registra la venta, el abono o la orden web con la lógica normal del POS, en una
                           transacción y una sola vez. El enganche de un crédito queda 'aprobado' y lo usa su contrato
                           (preparar_credito -> concretar_credito en contrato_credito.php).
   4) mp_cancelar_cobro -> retira la orden de la terminal mientras nadie ha pagado.
   Las credenciales viven en .env (MP_ENTORNO, MP_ACCESS_TOKEN_PRUEBA / _PRODUCCION, MP_WEBHOOK_SECRET) y nunca llegan al navegador.
   La terminal de cada caja está en la tabla terminales_point (Database/mercadopago_point.sql). */

require_once dirname(__DIR__) . '/entorno.php';

const MP_API_URL = 'https://api.mercadopago.com';
// Tiempo que la orden espera en la terminal antes de expirar (ISO 8601; Mercado Pago acepta de 30 s a 3 h)
const MP_ORDEN_EXPIRA = 'PT15M';
// Segundos mínimos entre dos consultas a la API del mismo cobro (la pantalla pregunta más seguido y recibe lo ya guardado)
const MP_CONSULTA_CADA = 3;
const MP_FORMATO_CLAVE = '/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/';
// Métodos de pago existentes en la tabla metodos_pago, según el tipo de tarjeta que reporta Mercado Pago
const MP_METODO_CREDITO = 'Tarjeta de Crédito';
const MP_METODO_DEBITO = 'Tarjeta de Débito';

/* ===================== Configuración ===================== */

// Entorno activo: 'produccion' cobra de verdad con la terminal física; cualquier otro valor usa las credenciales de prueba
function mpEntorno(): string {
    return strtolower(karmaEnv('MP_ENTORNO')) === 'produccion' ? 'produccion' : 'prueba';
}

// Access Token del entorno (vacío si falta o si todavía tiene el texto de ejemplo de la plantilla)
function mpToken(string $entorno): string {
    $token = trim(karmaEnv($entorno === 'produccion' ? 'MP_ACCESS_TOKEN_PRODUCCION' : 'MP_ACCESS_TOKEN_PRUEBA'));
    return str_starts_with($token, 'AQUI_') ? '' : $token;
}

// Terminal asignada a la caja en ese entorno
function mpTerminalCaja(PDO $pdo, int $idCaja, string $entorno): ?array {
    $stmt = $pdo->prepare("SELECT terminal_id, descripcion FROM terminales_point WHERE entorno = ? AND id_caja = ? AND activa = 1 LIMIT 1");
    $stmt->execute([$entorno, $idCaja]);
    return $stmt->fetch() ?: null;
}

// Lo que la pantalla del cajero necesita (bootstrap): si puede cobrar con tarjeta y si quedó un cobro abierto en su caja.
// Si aún no se importó Database/mercadopago_point.sql la caja sigue funcionando, solo sin la opción de tarjeta.
function mpConfiguracionCaja(PDO $pdo, int $idCaja, int $idUsuario): array {
    $entorno = mpEntorno();
    $base = ['disponible' => false, 'entorno' => $entorno, 'terminal' => null, 'aviso' => '', 'cobroAbierto' => null];
    try {
        if (mpToken($entorno) === '') return ['aviso' => 'Falta el Access Token de Mercado Pago en el archivo .env.'] + $base;
        $terminal = mpTerminalCaja($pdo, $idCaja, $entorno);
        if (!$terminal) return ['aviso' => 'Esta caja no tiene una terminal Point asignada.'] + $base;
        // Cobro que quedó abierto (por ejemplo, se recargó la página mientras el cliente pagaba): la pantalla lo retoma
        $stmt = $pdo->prepare("
            SELECT * FROM pagos_mercadopago
            WHERE id_caja = ? AND id_usuario = ? AND (estado IN ('creando', 'en_terminal') OR (estado = 'aprobado' AND tipo <> 'enganche'))
            ORDER BY id_pago_mp DESC LIMIT 1
        ");
        $stmt->execute([$idCaja, $idUsuario]);
        $abierto = $stmt->fetch();
        return ['disponible' => true, 'terminal' => $terminal['descripcion'] ?: 'Terminal Point', 'cobroAbierto' => $abierto ? mpRespuesta($abierto) : null] + $base;
    } catch (PDOException $e) {
        return ['aviso' => 'Importa Database/mercadopago_point.sql para habilitar el cobro con tarjeta.'] + $base;
    }
}

/* ===================== Cliente de la API ===================== */

// Llama a la API de Mercado Pago. Regresa ['codigo' => HTTP (0 = sin conexión), 'datos' => JSON decodificado, 'error' => texto]
function mpApi(string $entorno, string $metodo, string $ruta, ?array $cuerpo = null, ?string $idempotencia = null, array $encabezados = []): array {
    $ch = curl_init(MP_API_URL . $ruta);
    $headers = array_merge(['Authorization: Bearer ' . mpToken($entorno), 'Content-Type: application/json', 'Accept: application/json'], $encabezados);
    if ($idempotencia !== null) $headers[] = 'X-Idempotency-Key: ' . $idempotencia;
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $metodo,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_CONNECTTIMEOUT => 6,
        CURLOPT_TIMEOUT => 15
    ]);
    if ($cuerpo !== null) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($cuerpo, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    elseif ($metodo === 'POST') curl_setopt($ch, CURLOPT_POSTFIELDS, '');
    $respuesta = curl_exec($ch);
    $codigo = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = $respuesta === false ? curl_error($ch) : '';
    curl_close($ch);
    $datos = is_string($respuesta) ? json_decode($respuesta, true) : null;
    return ['codigo' => $respuesta === false ? 0 : $codigo, 'datos' => is_array($datos) ? $datos : [], 'error' => $error];
}

// Código de error que devolvió la API (para la bitácora y los mensajes)
function mpCodigoError(array $r): string {
    $d = $r['datos'];
    if ($r['codigo'] === 0) return 'sin_conexion: ' . $r['error'];
    return (string)($d['errors'][0]['code'] ?? $d['code'] ?? $d['error'] ?? ('http_' . $r['codigo']));
}

// UUID v4 (clave de idempotencia de las cancelaciones)
function mpUuid(): string {
    $b = random_bytes(16);
    $b[6] = chr((ord($b[6]) & 0x0f) | 0x40);
    $b[8] = chr((ord($b[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($b), 4));
}

// Bitácora de consultas y Webhooks. Es informativa: si falla no detiene el cobro
function mpBitacora(PDO $pdo, ?int $idPago, string $origen, array $e = []): void {
    try {
        $pdo->prepare("
            INSERT INTO pagos_mercadopago_eventos
            (id_pago_mp, origen, mp_order_id, accion, request_id, firma_valida, http_codigo, mp_estado, mp_estado_detalle, detalle)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ")->execute([
            $idPago, $origen, $e['orden'] ?? null, $e['accion'] ?? null, $e['request_id'] ?? null,
            isset($e['firma']) ? (int)$e['firma'] : null, $e['http'] ?? null, $e['estado'] ?? null, $e['estado_detalle'] ?? null,
            isset($e['detalle']) ? mb_substr((string)$e['detalle'], 0, 500) : null
        ]);
    } catch (Throwable $ex) {
        // Sin bitácora el cobro sigue igual
    }
}

/* ===================== Consultas del cobro ===================== */

function mpPagoPorId(PDO $pdo, int $id): ?array {
    $stmt = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE id_pago_mp = ?");
    $stmt->execute([$id]);
    return $stmt->fetch() ?: null;
}

// Cobro pedido por la pantalla (por id o por su clave): solo el cajero que lo inició puede verlo o moverlo
function mpPagoDeSesion(PDO $pdo, array $d): ?array {
    $id = (int)($d['id_pago'] ?? 0);
    $clave = strtolower(trim((string)($d['clave'] ?? '')));
    if ($id) {
        $p = mpPagoPorId($pdo, $id);
    } elseif (preg_match(MP_FORMATO_CLAVE, $clave)) {
        $stmt = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE clave = ?");
        $stmt->execute([$clave]);
        $p = $stmt->fetch() ?: null;
    } else {
        return null;
    }
    return $p && (int)$p['id_usuario'] === (int)$GLOBALS['cajeroSesion']['id_usuario'] ? $p : null;
}

// Nombre del método de pago de la BD según el tipo de tarjeta (débito y prepago cuentan como débito)
function mpNombreMetodo(?string $tipoTarjeta): string {
    return $tipoTarjeta === 'credit_card' ? MP_METODO_CREDITO : MP_METODO_DEBITO;
}

function mpIdMetodoPago(PDO $pdo, ?string $tipoTarjeta): int {
    $stmt = $pdo->prepare("SELECT id_metodo_pago FROM metodos_pago WHERE nombre_metodo = ? LIMIT 1");
    $stmt->execute([mpNombreMetodo($tipoTarjeta)]);
    $id = (int)$stmt->fetchColumn();
    if (!$id) throw new RuntimeException('No existe el método de pago "' . mpNombreMetodo($tipoTarjeta) . '".');
    return $id;
}

// Explicación para la persona en caja del resultado que reportó Mercado Pago
function mpTextoEstado(array $p): string {
    $detalle = (string)$p['mp_estado_detalle'];
    switch ($p['estado']) {
        case 'creando':
            return 'Enviando el cobro a la terminal…';
        case 'en_terminal':
            if ($detalle === 'cancellation_requested') return 'Cancelando el cobro en la terminal…';
            if ($p['mp_estado'] === 'action_required') return 'Confirma el resultado en la pantalla de la terminal.';
            return 'Pide al cliente que acerque, inserte o deslice su tarjeta en la terminal.';
        case 'aprobado':
            return $p['tipo'] === 'enganche' ? 'Enganche cobrado. Continúa con la verificación y el contrato.' : 'Pago aprobado. Registrando la operación…';
        case 'registrado':
            return 'Pago aprobado y registrado.';
        case 'rechazado':
            return match ($detalle) {
                'insufficient_amount' => 'Fondos insuficientes.',
                'rejected_by_issuer' => 'El banco emisor rechazó la tarjeta.',
                'card_disabled' => 'La tarjeta está bloqueada o deshabilitada.',
                'bad_filled_card_data' => 'Los datos de la tarjeta son incorrectos.',
                'high_risk' => 'Mercado Pago rechazó el pago por seguridad.',
                'required_call_for_authorize' => 'El banco pide autorizar el pago por teléfono.',
                'max_attempts_exceeded' => 'Se superó el número de intentos con esa tarjeta.',
                'amount_limit_exceeded' => 'El importe supera el límite de la tarjeta.',
                'invalid_installments' => 'La tarjeta no acepta esos meses.',
                default => 'El pago fue rechazado. Intenta con otra tarjeta.'
            };
        case 'cancelado':
            return $detalle === 'canceled_on_terminal' ? 'El cobro se canceló en la terminal.' : 'El cobro se canceló.';
        case 'expirado':
            return 'El cobro expiró sin que se pagara.';
    }
    return 'No se pudo completar el cobro.';
}

// Estado del cobro tal como lo muestra la pantalla de caja
function mpRespuesta(array $p): array {
    $estado = $p['estado'];
    $vista = match ($estado) {
        'creando' => $p['mensaje'] ? 'conexion' : 'preparando',
        'en_terminal' => ($p['mp_estado'] === 'action_required' || $p['mp_estado_detalle'] === 'cancellation_requested') ? 'procesando' : 'esperando',
        'aprobado' => $p['tipo'] === 'enganche' ? 'aprobado' : ($p['mensaje'] ? 'revision' : 'procesando'),
        'registrado' => 'aprobado',
        'rechazado' => 'rechazado',
        'cancelado', 'expirado' => 'cancelado',
        default => 'error'
    };
    return [
        'id' => (int)$p['id_pago_mp'],
        'clave' => $p['clave'],
        'tipo' => $p['tipo'],
        'estado' => $estado,
        'vista' => $vista,
        'final' => in_array($vista, ['aprobado', 'rechazado', 'cancelado', 'error', 'revision'], true),
        'mensaje' => $p['mensaje'] ?: mpTextoEstado($p),
        'importe' => (float)$p['importe'],
        'ticket' => (int)$p['ticket_numero'],
        'entorno' => $p['entorno'],
        'tarjeta' => $p['tarjeta_tipo'] ? [
            'metodo' => mpNombreMetodo($p['tarjeta_tipo']),
            'marca' => strtoupper((string)$p['tarjeta_marca']),
            'cuotas' => (int)$p['cuotas'],
            'referencia' => (string)($p['mp_referencia'] ?: $p['mp_payment_id'])
        ] : null,
        'resultado' => $p['resultado_json'] ? json_decode((string)$p['resultado_json'], true) : null
    ];
}

/* ===================== 1. Iniciar el cobro (api.php?action=mp_iniciar_cobro) ===================== */

// Importe exacto y datos para registrar después, con las mismas reglas del cobro en efectivo. Corre dentro de una transacción
// con bloqueos y no escribe nada. Regresa ['importe', 'descripcion', 'solicitud'].
function mpPrepararOperacion(PDO $pdo, string $tipo, array $d, int $idSucursal, int $ticket): array {
    switch ($tipo) {
        case 'venta':
            if (!empty($d['credito'])) throw new RuntimeException('Los créditos se cobran con su contrato.');
            $items = is_array($d['items'] ?? null) ? $d['items'] : [];
            $conceptos = is_array($d['conceptos'] ?? null) ? $d['conceptos'] : [];
            if (!$items && !$conceptos) throw new RuntimeException('El ticket está vacío.');
            [$productos, $total] = posValidarArticulosVenta($pdo, $items, $idSucursal);
            [, $totalConceptos] = posValidarConceptosCaja($pdo, $conceptos, $idSucursal, $productos);
            return [
                'importe' => money($total + $totalConceptos),
                'descripcion' => "Venta ticket #{$ticket}",
                'solicitud' => [
                    'items' => $items, 'conceptos' => $conceptos,
                    'ordenes_web' => array_values(array_filter(array_map('intval', (array)($d['ordenes_web'] ?? [])))),
                    'cliente' => trim((string)($d['cliente'] ?? '')), 'email' => trim((string)($d['email'] ?? '')),
                    'celular' => trim((string)($d['celular'] ?? ''))
                ]
            ];
        case 'enganche':
            // Mismo cálculo que preparar_credito: el importe a cobrar hoy es el enganche más lo de contado del ticket
            $items = contratoNormalizarItems($d['items'] ?? null);
            $parametros = contratoNormalizarParametros(is_array($d['credito'] ?? null) ? $d['credito'] : []);
            [$lineas] = posValidarArticulosVenta($pdo, $items, $idSucursal);
            $op = contratoCalcularOperacion($pdo, $items, $lineas, $parametros, ['metodo' => 'Tarjeta', 'recibido' => 0.0]);
            if ($op['importe'] <= 0) throw new RuntimeException('Este crédito no tiene enganche que cobrar.');
            return ['importe' => $op['importe'], 'descripcion' => "Enganche ticket #{$ticket}", 'solicitud' => []];
        case 'abono':
            $clave = strtolower(trim((string)($d['clave'] ?? '')));
            if (!preg_match(MP_FORMATO_CLAVE, $clave)) throw new RuntimeException('Solicitud de cobro no válida. Vuelve a agregar el abono al ticket.');
            $contrato = abonoContratoBloqueado($pdo, (int)($d['id_contrato'] ?? 0));
            $a = abonoSiguiente($contrato, (int)($d['numero_abono'] ?? 0));
            return [
                'importe' => $a['importe'],
                'descripcion' => "Abono {$a['numero']} de {$a['plazo']} ticket #{$ticket}",
                'solicitud' => ['id_contrato' => (int)$contrato['id_contrato'], 'numero_abono' => $a['numero'], 'clave' => $clave]
            ];
        case 'orden_web':
            $prep = posPrepararOrdenWeb($pdo, (int)($d['id_orden'] ?? 0), $idSucursal);
            return [
                'importe' => $prep['total'],
                'descripcion' => 'Pedido ' . $prep['orden']['folio'],
                'solicitud' => ['id_orden' => (int)$prep['orden']['id_orden']]
            ];
    }
    throw new RuntimeException('Tipo de cobro no válido.');
}

function mpIniciarCobro(): never {
    if (!posCsrfValido()) fail('Solicitud no válida. Recarga la página e inténtalo de nuevo.', 403);
    $d = jsonInput();
    $cajero = $GLOBALS['cajeroSesion'];
    $idUsuario = (int)$cajero['id_usuario'];
    $idSucursal = (int)$cajero['id_sucursal'];
    $tipo = (string)($d['tipo'] ?? '');
    $clave = strtolower(trim((string)($d['clave'] ?? '')));
    $idCaja = (int)($d['id_caja'] ?? 0);
    $ticket = (int)($d['ticket_numero'] ?? 0);
    $datos = is_array($d['datos'] ?? null) ? $d['datos'] : [];
    if (!in_array($tipo, ['venta', 'enganche', 'abono', 'orden_web'], true)) fail('Tipo de cobro no válido.');
    if (!preg_match(MP_FORMATO_CLAVE, $clave)) fail('Solicitud de cobro no válida. Vuelve a intentarlo.');

    $pdo = db();
    $cajaValida = $pdo->prepare("SELECT COUNT(*) FROM cajas WHERE id_caja = ? AND id_sucursal = ?");
    $cajaValida->execute([$idCaja, $idSucursal]);
    if (!(int)$cajaValida->fetchColumn()) fail('La caja no pertenece a la sucursal del cajero.');
    $entorno = mpEntorno();
    if (mpToken($entorno) === '') fail('Mercado Pago no está configurado: falta el Access Token en el archivo .env.', 503);
    $terminal = mpTerminalCaja($pdo, $idCaja, $entorno);
    if (!$terminal) fail('Esta caja no tiene una terminal Point asignada.', 409);

    // El mismo cobro reenviado (doble clic o reintento tras un corte): se responde con el que ya existe
    if ($previo = mpPagoDeSesion($pdo, ['clave' => $clave])) ok(['pago' => mpRespuesta(mpAvanzar($pdo, $previo))]);

    // Una sola orden a la vez por caja: un cobro que quedó abierto se retoma en vez de mandar otro a la terminal
    $abierto = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE id_caja = ? AND estado IN ('creando', 'en_terminal') ORDER BY id_pago_mp DESC LIMIT 1");
    $abierto->execute([$idCaja]);
    if ($fila = $abierto->fetch()) {
        if ((int)$fila['id_usuario'] !== $idUsuario) fail('La terminal de esta caja tiene un cobro en curso de otro cajero.', 409);
        ok(['pago' => mpRespuesta(mpAvanzar($pdo, $fila)), 'retomado' => true]);
    }

    $pdo->beginTransaction();
    try {
        $op = mpPrepararOperacion($pdo, $tipo, $datos, $idSucursal, $ticket);
        $importe = number_format((float)$op['importe'], 2, '.', '');
        // Enganche ya cobrado cuyo contrato se canceló: se usa ese pago en lugar de cobrarle otra vez al cliente
        if ($tipo === 'enganche') {
            $reuso = $pdo->prepare("
                SELECT * FROM pagos_mercadopago
                WHERE tipo = 'enganche' AND estado = 'aprobado' AND id_contrato IS NULL AND id_usuario = ? AND id_caja = ? AND importe = ?
                ORDER BY id_pago_mp DESC LIMIT 1 FOR UPDATE
            ");
            $reuso->execute([$idUsuario, $idCaja, $importe]);
            if ($pagado = $reuso->fetch()) {
                $pdo->commit();
                ok(['pago' => mpRespuesta($pagado), 'reutilizado' => true]);
            }
        }
        $pdo->prepare("
            INSERT INTO pagos_mercadopago
            (clave, referencia_externa, tipo, entorno, id_sucursal, id_caja, id_usuario, ticket_numero, terminal_id, importe, descripcion, solicitud_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ")->execute([
            $clave, 'KRM-' . $clave, $tipo, $entorno, $idSucursal, $idCaja, $idUsuario, $ticket, $terminal['terminal_id'], $importe,
            mb_substr('KARMA · ' . $op['descripcion'], 0, 150), json_encode($op['solicitud'], JSON_UNESCAPED_UNICODE)
        ]);
        $idPago = (int)$pdo->lastInsertId();
        $pdo->commit();
    } catch (RuntimeException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        fail($e->getMessage(), 409);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    ok(['pago' => mpRespuesta(mpCrearOrden($pdo, mpPagoPorId($pdo, $idPago)))]);
}

// Manda la orden a la terminal. La misma clave de idempotencia hace que un reintento regrese la MISMA orden en vez de crear otra
function mpCrearOrden(PDO $pdo, array $p): array {
    $id = (int)$p['id_pago_mp'];
    $r = mpApi($p['entorno'], 'POST', '/v1/orders', [
        'type' => 'point',
        'external_reference' => $p['referencia_externa'],
        'expiration_time' => MP_ORDEN_EXPIRA,
        'description' => $p['descripcion'],
        'transactions' => ['payments' => [['amount' => number_format((float)$p['importe'], 2, '.', '')]]],
        'config' => ['point' => ['terminal_id' => $p['terminal_id'], 'print_on_terminal' => 'seller_ticket']]
    ], $p['clave']);
    $orden = $r['datos'];
    $creada = in_array($r['codigo'], [200, 201], true) && !empty($orden['id']);
    mpBitacora($pdo, $id, 'creacion', [
        'http' => $r['codigo'], 'orden' => $orden['id'] ?? null, 'estado' => $orden['status'] ?? null,
        'detalle' => $creada ? null : mpCodigoError($r)
    ]);
    if ($creada) return mpProcesarOrden($pdo, $orden, 'creacion') ?? mpPagoPorId($pdo, $id);

    if ($r['codigo'] === 0 || $r['codigo'] >= 500) {
        // Sin respuesta: el cobro sigue 'creando' y el siguiente intento repite la misma orden (idempotencia)
        $pdo->prepare("UPDATE pagos_mercadopago SET mensaje = ?, ultima_consulta = NOW() WHERE id_pago_mp = ? AND estado = 'creando'")
            ->execute(['Sin conexión con Mercado Pago. Reintentando…', $id]);
    } else {
        $codigo = mpCodigoError($r);
        $mensaje = match (true) {
            $codigo === 'already_queued_order_for_terminal' => 'La terminal ya tiene otro cobro en espera. Cancélalo en la terminal o espera a que expire.',
            $codigo === 'forbidden_checking_terminal_owner' => 'La terminal no pertenece a la cuenta de Mercado Pago configurada.',
            $r['codigo'] === 401 => 'El Access Token de Mercado Pago no es válido.',
            default => 'Mercado Pago no aceptó el cobro (' . $codigo . ').'
        };
        $pdo->prepare("UPDATE pagos_mercadopago SET estado = 'error', mensaje = ?, ultima_consulta = NOW() WHERE id_pago_mp = ? AND estado = 'creando'")
            ->execute([$mensaje, $id]);
    }
    return mpPagoPorId($pdo, $id);
}

/* ===================== 2. Estado real de la orden (consulta y Webhook) ===================== */

// Consulta la orden en la API y aplica su estado. $origen: 'consulta' (pantalla de caja) o 'webhook'
function mpConsultarOrden(PDO $pdo, array $p, string $origen = 'consulta'): array {
    $r = mpApi($p['entorno'], 'GET', '/v1/orders/' . rawurlencode((string)$p['mp_order_id']));
    if ($r['codigo'] === 200 && !empty($r['datos']['id'])) return mpProcesarOrden($pdo, $r['datos'], $origen) ?? $p;
    $pdo->prepare("UPDATE pagos_mercadopago SET ultima_consulta = NOW() WHERE id_pago_mp = ?")->execute([(int)$p['id_pago_mp']]);
    mpBitacora($pdo, (int)$p['id_pago_mp'], $origen, ['http' => $r['codigo'], 'orden' => $p['mp_order_id'], 'detalle' => mpCodigoError($r)]);
    return mpPagoPorId($pdo, (int)$p['id_pago_mp']);
}

// El cobro aprobado debe coincidir con lo que se mandó: misma referencia, terminal, moneda e importe exacto
function mpCobroCoincide(array $p, array $orden, array $pago): bool {
    $pagado = $pago['paid_amount'] ?? $orden['total_paid_amount'] ?? $pago['amount'] ?? null;
    return $pagado !== null
        && (int)round((float)$pagado * 100) === (int)round((float)$p['importe'] * 100)
        && strtoupper((string)($orden['currency'] ?? 'MXN')) === 'MXN'
        && (string)($orden['external_reference'] ?? '') === $p['referencia_externa']
        && strcasecmp((string)($orden['config']['point']['terminal_id'] ?? $p['terminal_id']), $p['terminal_id']) === 0;
}

// Aplica a la BD el estado REAL de una orden (respuesta de la API, nunca el cuerpo del Webhook). Es seguro ante repeticiones:
// bloquea el cobro e ignora todo lo que llegue después de un estado final (Webhooks duplicados, tardíos o fuera de orden).
function mpProcesarOrden(PDO $pdo, array $orden, string $origen): ?array {
    $idOrden = (string)($orden['id'] ?? '');
    $referencia = (string)($orden['external_reference'] ?? '');
    $pago = $orden['transactions']['payments'][0] ?? [];
    $estadoMp = (string)($orden['status'] ?? '');
    $detalleMp = (string)($pago['status_detail'] ?? $orden['status_detail'] ?? '');

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE mp_order_id = ? OR referencia_externa = ? LIMIT 1 FOR UPDATE");
        $stmt->execute([$idOrden, $referencia]);
        $p = $stmt->fetch();
        if (!$p) {
            $pdo->commit();
            mpBitacora($pdo, null, $origen, ['orden' => $idOrden ?: null, 'estado' => $estadoMp, 'detalle' => 'Orden que no pertenece a este sistema']);
            return null;
        }
        $id = (int)$p['id_pago_mp'];
        mpBitacora($pdo, $id, $origen, ['orden' => $idOrden, 'estado' => $estadoMp, 'estado_detalle' => $detalleMp, 'http' => 200]);

        // Solo un cobro abierto puede cambiar: lo aprobado, rechazado, cancelado o registrado ya no se toca
        if (!in_array($p['estado'], ['creando', 'en_terminal'], true)) {
            $pdo->commit();
            return $p;
        }

        $pdo->prepare("
            UPDATE pagos_mercadopago
            SET mp_order_id = COALESCE(mp_order_id, ?), mp_payment_id = COALESCE(?, mp_payment_id), mp_estado = ?, mp_estado_detalle = ?,
                ultima_consulta = NOW(), mensaje = NULL
            WHERE id_pago_mp = ?
        ")->execute([$idOrden ?: null, $pago['id'] ?? null, $estadoMp, $detalleMp ?: null, $id]);

        if ($estadoMp === 'processed') {
            if (!mpCobroCoincide($p, $orden, $pago)) {
                $pdo->prepare("UPDATE pagos_mercadopago SET estado = 'error', mensaje = ? WHERE id_pago_mp = ?")
                    ->execute(['Mercado Pago reportó un cobro que no coincide con esta operación. Revísalo en tu cuenta antes de entregar.', $id]);
            } else {
                $metodoPago = is_array($pago['payment_method'] ?? null) ? $pago['payment_method'] : [];
                $pdo->prepare("
                    UPDATE pagos_mercadopago
                    SET estado = 'aprobado', fecha_aprobacion = NOW(), importe_pagado = ?, mp_referencia = ?,
                        tarjeta_tipo = ?, tarjeta_marca = ?, cuotas = ?
                    WHERE id_pago_mp = ?
                ")->execute([
                    $pago['paid_amount'] ?? $orden['total_paid_amount'] ?? $p['importe'], $pago['reference_id'] ?? null,
                    $metodoPago['type'] ?? null, $metodoPago['id'] ?? null, isset($metodoPago['installments']) ? (int)$metodoPago['installments'] : null, $id
                ]);
            }
        } elseif (in_array($estadoMp, ['failed', 'canceled', 'expired', 'refunded'], true)) {
            $nuevo = ['failed' => 'rechazado', 'canceled' => 'cancelado', 'expired' => 'expirado', 'refunded' => 'cancelado'][$estadoMp];
            $pdo->prepare("UPDATE pagos_mercadopago SET estado = ? WHERE id_pago_mp = ?")->execute([$nuevo, $id]);
        } else {
            // created, at_terminal o action_required: la orden sigue en la terminal
            $pdo->prepare("UPDATE pagos_mercadopago SET estado = 'en_terminal' WHERE id_pago_mp = ?")->execute([$id]);
        }
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
    return mpPagoPorId($pdo, $id);
}

/* ===================== 3. Registrar lo aprobado (solo dentro de api.php) ===================== */

// Registra la venta, el abono o la orden web de un cobro aprobado con la lógica normal del POS, UNA sola vez y todo o nada.
// Si algo impide registrarla (por ejemplo, otro cajero vendió la última pieza) no se guarda nada y el cobro queda en revisión.
function mpRegistrarAprobado(PDO $pdo, int $idPago): array {
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE id_pago_mp = ? FOR UPDATE");
        $stmt->execute([$idPago]);
        $p = $stmt->fetch();
        if (!$p || $p['estado'] !== 'aprobado' || $p['tipo'] === 'enganche') {
            $pdo->commit();
            return $p ?: [];
        }
        $s = json_decode((string)$p['solicitud_json'], true) ?: [];
        $idSucursal = (int)$p['id_sucursal'];
        $idUsuario = (int)$p['id_usuario'];
        $idCaja = (int)$p['id_caja'];
        $ticket = (int)$p['ticket_numero'];
        $importe = round((float)$p['importe'], 2);
        $idMetodo = mpIdMetodoPago($pdo, $p['tarjeta_tipo']);
        $enlace = ['id_venta' => null, 'id_abono' => null, 'id_orden_web' => null];

        if ($p['tipo'] === 'venta') {
            // Mismas piezas que crearVenta(): validación con bloqueo, venta + detalle + existencias, conceptos, órdenes web y garantías
            [$productos, $total] = posValidarArticulosVenta($pdo, (array)($s['items'] ?? []), $idSucursal);
            [$conceptosVenta, $totalConceptos] = posValidarConceptosCaja($pdo, $s['conceptos'] ?? [], $idSucursal, $productos);
            $total = money($total + $totalConceptos);
            if (abs($total - $importe) > 0.009) throw new RuntimeException('Un precio cambió después de iniciar el cobro.');
            $ventaId = posInsertarVenta($pdo, [
                'id_sucursal' => $idSucursal, 'id_usuario' => $idUsuario, 'id_caja' => $idCaja, 'id_metodo_pago' => $idMetodo,
                'id_cliente' => null, 'total' => $total, 'recibido' => $total, 'cambio' => 0.0, 'ticket_numero' => $ticket
            ], $productos);
            $folios = posRegistrarConceptosVenta($pdo, $ventaId, $conceptosVenta, ['id_sucursal' => $idSucursal, 'id_usuario' => $idUsuario, 'id_caja' => $idCaja]);
            posMarcarOrdenesWeb($pdo, (array)($s['ordenes_web'] ?? []), $ventaId, $idSucursal);
            posRegistrarGarantias($pdo, $ventaId, $idSucursal, $productos, [
                'nombre' => (string)($s['cliente'] ?? ''), 'celular' => (string)($s['celular'] ?? ''), 'email' => (string)($s['email'] ?? '')
            ], null);
            $fecha = $pdo->prepare("SELECT DATE_FORMAT(fecha_hora, '%d/%m/%Y %H:%i:%s') FROM ventas WHERE id_venta = ?");
            $fecha->execute([$ventaId]);
            $nombres = $pdo->prepare("SELECT nombre FROM productos WHERE id_producto = ?");
            $lineas = array_map(function (array $l) use ($nombres): array {
                $nombres->execute([$l['id']]);
                return ['descripcion' => (string)$nombres->fetchColumn(), 'cantidad' => (int)$l['cantidad'], 'subtotal' => (float)$l['subtotal']];
            }, $productos);
            $resultado = [
                'venta_id' => $ventaId, 'folio' => sprintf('KRM-%02d-%06d', $idSucursal, $ventaId), 'fecha' => (string)$fecha->fetchColumn(),
                'total' => $total, 'conceptos' => $folios, 'lineas' => $lineas
            ];
            $enlace['id_venta'] = $ventaId;
        } elseif ($p['tipo'] === 'abono') {
            $r = abonoRegistrar($pdo, [
                'id_contrato' => (int)($s['id_contrato'] ?? 0), 'numero' => (int)($s['numero_abono'] ?? 0), 'clave' => (string)($s['clave'] ?? ''),
                'id_sucursal' => $idSucursal, 'id_usuario' => $idUsuario, 'id_caja' => $idCaja, 'ticket_numero' => $ticket,
                'metodo_pago' => mpNombreMetodo($p['tarjeta_tipo']), 'recibido' => null
            ]);
            if (abs((float)$r['abono']['importe'] - $importe) > 0.009) throw new RuntimeException('El importe del abono cambió después de iniciar el cobro.');
            $resultado = abonoRespuesta($pdo, $r['abono'], $r['contrato']) + ['repetido' => $r['repetido']];
            $enlace['id_abono'] = (int)$r['abono']['id_abono'];
        } else {
            $prep = posPrepararOrdenWeb($pdo, (int)($s['id_orden'] ?? 0), $idSucursal);
            if (abs($prep['total'] - $importe) > 0.009) throw new RuntimeException('El total del pedido cambió después de iniciar el cobro.');
            $resultado = posRegistrarOrdenWeb($pdo, $prep, [
                'id_usuario' => $idUsuario, 'id_sucursal' => $idSucursal, 'id_caja' => $idCaja, 'id_metodo_pago' => $idMetodo,
                'recibido' => $prep['total'], 'cambio' => 0.0, 'ticket_numero' => $ticket,
                'aviso' => 'Recibimos tu pago con tarjeta. ¡Gracias por tu compra en KARMA!'
            ]);
            $enlace['id_venta'] = (int)$resultado['venta_id'];
            $enlace['id_orden_web'] = (int)$prep['orden']['id_orden'];
        }

        $pdo->prepare("
            UPDATE pagos_mercadopago
            SET estado = 'registrado', id_venta = ?, id_abono = ?, id_orden_web = ?, resultado_json = ?, mensaje = NULL
            WHERE id_pago_mp = ? AND estado = 'aprobado'
        ")->execute([$enlace['id_venta'], $enlace['id_abono'], $enlace['id_orden_web'], json_encode($resultado, JSON_UNESCAPED_UNICODE), $idPago]);
        $pdo->commit();
    } catch (RuntimeException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        $pdo->prepare("UPDATE pagos_mercadopago SET mensaje = ? WHERE id_pago_mp = ? AND estado = 'aprobado'")
            ->execute([mb_substr('El pago se aprobó, pero no se pudo registrar: ' . $e->getMessage(), 0, 255), $idPago]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
    return mpPagoPorId($pdo, $idPago);
}

// Hace avanzar un cobro: reintenta crear la orden, consulta su estado real (respaldo del Webhook) y registra lo aprobado
function mpAvanzar(PDO $pdo, array $p): array {
    $reciente = $p['ultima_consulta'] && (time() - strtotime((string)$p['ultima_consulta'])) < MP_CONSULTA_CADA;
    if ($p['estado'] === 'creando' && !$p['mp_order_id'] && !$reciente) {
        $p = mpCrearOrden($pdo, $p);
    } elseif (in_array($p['estado'], ['creando', 'en_terminal'], true) && $p['mp_order_id'] && !$reciente) {
        $p = mpConsultarOrden($pdo, $p);
    }
    if ($p['estado'] === 'aprobado' && $p['tipo'] !== 'enganche') $p = mpRegistrarAprobado($pdo, (int)$p['id_pago_mp']);
    return $p;
}

// api.php?action=mp_estado_cobro — la pantalla de cobro pregunta cada 2 s
function mpEstadoCobro(): never {
    if (!posCsrfValido()) fail('Solicitud no válida. Recarga la página e inténtalo de nuevo.', 403);
    $pdo = db();
    $p = mpPagoDeSesion($pdo, jsonInput());
    if (!$p) fail('No se encontró el cobro con tarjeta.', 404);
    ok(['pago' => mpRespuesta(mpAvanzar($pdo, $p))]);
}

/* ===================== 4. Cancelar (api.php?action=mp_cancelar_cobro) ===================== */

function mpCancelarCobro(): never {
    if (!posCsrfValido()) fail('Solicitud no válida. Recarga la página e inténtalo de nuevo.', 403);
    $pdo = db();
    $p = mpPagoDeSesion($pdo, jsonInput());
    if (!$p) fail('No se encontró el cobro con tarjeta.', 404);

    // Todavía no llegó a la terminal: se cancela aquí
    if ($p['estado'] === 'creando' && !$p['mp_order_id']) {
        $pdo->prepare("UPDATE pagos_mercadopago SET estado = 'cancelado', mensaje = 'El cobro se canceló desde la caja.' WHERE id_pago_mp = ? AND estado = 'creando'")
            ->execute([(int)$p['id_pago_mp']]);
        ok(['pago' => mpRespuesta(mpPagoPorId($pdo, (int)$p['id_pago_mp']))]);
    }
    if (!in_array($p['estado'], ['creando', 'en_terminal'], true)) ok(['pago' => mpRespuesta($p)]);

    // En la terminal: 'created' se cancela al momento; 'at_terminal' queda solicitada y la confirma la terminal (Webhook o consulta)
    $r = mpApi($p['entorno'], 'POST', '/v1/orders/' . rawurlencode((string)$p['mp_order_id']) . '/cancel', null, mpUuid(), ['x-allow-cancelable-status: at_terminal']);
    mpBitacora($pdo, (int)$p['id_pago_mp'], 'cancelacion', ['http' => $r['codigo'], 'orden' => $p['mp_order_id'], 'estado' => $r['datos']['status'] ?? null,
        'detalle' => $r['codigo'] >= 300 || $r['codigo'] === 0 ? mpCodigoError($r) : null]);
    if ($r['codigo'] === 200 && !empty($r['datos']['id'])) {
        $p = mpProcesarOrden($pdo, $r['datos'], 'cancelacion') ?? $p;
    } elseif ($r['codigo'] === 202) {
        $pdo->prepare("UPDATE pagos_mercadopago SET mp_estado_detalle = 'cancellation_requested' WHERE id_pago_mp = ? AND estado = 'en_terminal'")
            ->execute([(int)$p['id_pago_mp']]);
        $p = mpPagoPorId($pdo, (int)$p['id_pago_mp']);
    } elseif ($r['codigo'] === 409) {
        fail('La terminal ya está procesando la tarjeta: espera el resultado.', 409);
    } else {
        fail('No se pudo cancelar el cobro (' . mpCodigoError($r) . '). Inténtalo de nuevo.', 502);
    }
    ok(['pago' => mpRespuesta($p)]);
}

/* ===================== Enganche de crédito (lo usa contrato_credito.php) ===================== */

// Enganche cobrado con tarjeta que usará el contrato: aprobado, del mismo cajero y sin otro contrato. Bloquea el cobro.
function mpEngancheParaContrato(PDO $pdo, int $idPago, int $idUsuario): array {
    $stmt = $pdo->prepare("SELECT * FROM pagos_mercadopago WHERE id_pago_mp = ? FOR UPDATE");
    $stmt->execute([$idPago]);
    $p = $stmt->fetch();
    if (!$p || $p['tipo'] !== 'enganche' || (int)$p['id_usuario'] !== $idUsuario) throw new RuntimeException('No se encontró el cobro con tarjeta del enganche.');
    if ($p['estado'] !== 'aprobado') throw new RuntimeException('El enganche con tarjeta todavía no está aprobado.');
    if ($p['id_contrato'] !== null) throw new RuntimeException('Ese cobro con tarjeta ya pertenece a otro contrato.');
    return $p;
}

// Contratos cancelados (el cliente no firmó o venció el tiempo): su enganche con tarjeta queda libre para volver a usarse.
// Si la tabla aún no existe (BD sin Database/mercadopago_point.sql) no hay nada que liberar.
function mpLiberarEnganches(PDO $pdo, int $idUsuario): void {
    try {
        $pdo->prepare("
            UPDATE pagos_mercadopago p JOIN contratos_credito k ON k.id_contrato = p.id_contrato
            SET p.id_contrato = NULL
            WHERE p.tipo = 'enganche' AND p.estado = 'aprobado' AND p.id_usuario = ? AND k.estado = 'cancelado'
        ")->execute([$idUsuario]);
    } catch (PDOException $e) {
        if ($e->getCode() !== '42S02') throw $e;
    }
}

// Al firmarse el contrato, su enganche con tarjeta queda registrado con la venta
function mpCerrarEnganche(PDO $pdo, int $idContrato, int $ventaId): void {
    $pdo->prepare("UPDATE pagos_mercadopago SET estado = 'registrado', id_venta = ? WHERE id_contrato = ? AND tipo = 'enganche' AND estado = 'aprobado'")
        ->execute([$ventaId, $idContrato]);
}

/* ===================== Webhook (lo usa mercadopago_webhook.php) ===================== */

// Firma x-signature: HMAC-SHA256 (hex) de "id:<data.id>;request-id:<x-request-id>;ts:<ts>;" con la clave secreta del Webhook.
// Las partes sin valor se omiten (validador oficial del SDK de PHP). El id se prueba tal cual y en minúsculas, como pide la
// documentación para ids alfanuméricos; las dos variantes necesitan la clave secreta.
function mpFirmaValida(string $firma, string $requestId, string $dataId, string $secreto): bool {
    if ($secreto === '' || str_starts_with($secreto, 'AQUI_')) return false;
    $ts = '';
    $v1 = '';
    foreach (explode(',', $firma) as $parte) {
        [$k, $v] = array_map('trim', explode('=', $parte, 2) + [1 => '']);
        if ($k === 'ts') $ts = $v;
        elseif ($k === 'v1') $v1 = strtolower($v);
    }
    if ($ts === '' || $v1 === '' || !ctype_digit($ts)) return false;
    foreach (array_unique([$dataId, strtolower($dataId)]) as $id) {
        $manifiesto = ($id !== '' ? "id:{$id};" : '') . ($requestId !== '' ? "request-id:{$requestId};" : '') . "ts:{$ts};";
        if (hash_equals(hash_hmac('sha256', $manifiesto, $secreto), $v1)) return true;
    }
    return false;
}
