<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — REGISTRO CON ACEPTACIÓN DESDE EL CORREO
   1. El formulario crea una SOLICITUD (tabla registros_pendientes), no una cuenta.
   2. Se envía al correo el PDF con el Aviso de Privacidad y los Términos (includes/legal.php) y un botón
      que lleva a confirmar_registro.php?token=… (token aleatorio de 256 bits; en la BD solo se guarda su SHA-256).
   3. Abrir el enlace NO acepta nada: la página explica qué se acepta y la aceptación ocurre solo con el POST del botón.
   4. Al aceptar, en UNA transacción: se bloquea la solicitud, se verifica vigencia y versiones, se crea o activa la
      cuenta en `clientes`, se guardan las constancias (aceptaciones_documentos) y la solicitud queda completada.
   Los triggers de catalogo_registro_aceptacion.sql repiten estas reglas en la base de datos.
   Para enviar correos se reutiliza la API de Brevo del ticket del POS (PHP/PuntoDeVenta/correo.php).
   ===================================================================================== */

require_once __DIR__ . '/legal.php';
require_once dirname(__DIR__, 2) . '/PuntoDeVenta/correo.php';

const CAT_REGISTRO_VIGENCIA_HORAS = 24;   // vigencia del enlace de confirmación
const CAT_REGISTRO_ESPERA_REENVIO = 60;   // segundos entre dos correos de la misma solicitud
const CAT_REGISTRO_MAX_ENVIOS = 4;        // correos por solicitud (el primero y hasta 3 reenvíos)
const CAT_REGISTRO_MAX_POR_CORREO = 3;    // solicitudes nuevas con el mismo correo en 24 horas
const CAT_REGISTRO_MAX_POR_IP = 10;       // solicitudes nuevas desde la misma IP en 1 hora
const CAT_REGISTRO_BOTON = CAT_BOTON_ACEPTAR;     // texto exacto del botón (definido en legal.php)

// Error del flujo con un código que la página traduce a un mensaje claro (invalido, usado, vencido, documentos…)
class CatRegistroError extends RuntimeException {
    public function __construct(public readonly string $codigo, string $mensaje = '') {
        parent::__construct($mensaje !== '' ? $mensaje : $codigo);
    }
}
// Límite de envíos o de intentos alcanzado (HTTP 429)
class CatRegistroLimite extends RuntimeException {}

// ===== CONEXIÓN SEGURA Y URL PÚBLICA =====

// Desarrollo local (XAMPP / php -S): localhost, 127.0.0.1, ::1, *.localhost, *.test
function catHostLocal(string $host): bool {
    $host = strtolower(trim($host));
    $host = preg_replace('/:\d+$/', '', $host);
    $host = trim((string)$host, '[]');
    return in_array($host, ['localhost', '127.0.0.1', '::1'], true) || str_ends_with($host, '.localhost') || str_ends_with($host, '.test');
}

// ¿La petición llegó por HTTPS? (detrás de un proxy que termina el TLS, activa KARMA_PROXY_HTTPS=1 en el .env)
function catEsHttps(): bool {
    if (!empty($_SERVER['HTTPS']) && strtolower((string)$_SERVER['HTTPS']) !== 'off') return true;
    if ((string)($_SERVER['SERVER_PORT'] ?? '') === '443') return true;
    return karmaEnv('KARMA_PROXY_HTTPS') === '1' && strtolower((string)($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https';
}

// En producción (cualquier host que no sea local) el registro y la confirmación solo funcionan con HTTPS
function catRegistroConexionSegura(): bool {
    return catEsHttps() || catHostLocal((string)($_SERVER['HTTP_HOST'] ?? ''));
}

// URL completa de la carpeta del catálogo para los enlaces del correo y del PDF.
// Se toma de KARMA_URL_PUBLICA (.env); sin ella solo se acepta el host de la petición si es local
// (así un encabezado Host manipulado nunca puede mandar el token a otro dominio).
function catRegistroUrlCatalogo(): string {
    $base = trim(karmaEnv('KARMA_URL_PUBLICA'));
    if ($base === '') {
        $host = (string)($_SERVER['HTTP_HOST'] ?? '');
        if (!preg_match('/^(\[::1\]|[A-Za-z0-9.\-]+)(:\d{1,5})?$/', $host) || !catHostLocal($host)) {
            throw new RuntimeException('Falta KARMA_URL_PUBLICA en el archivo .env (dirección pública del proyecto).');
        }
        $base = (catEsHttps() ? 'https' : 'http') . '://' . $host . CAT_RAIZ;
    }
    $partes = parse_url($base);
    if (!$partes || empty($partes['host']) || !in_array($partes['scheme'] ?? '', ['http', 'https'], true)) {
        throw new RuntimeException('KARMA_URL_PUBLICA no es una dirección válida.');
    }
    if ($partes['scheme'] !== 'https' && !catHostLocal($partes['host'])) {
        throw new RuntimeException('KARMA_URL_PUBLICA debe usar https:// fuera del entorno local.');
    }
    return rtrim($base, '/') . '/PHP/Catalogo/';
}

// IP de la petición (no se confía en X-Forwarded-For porque el navegador puede inventarla)
function catRegistroIp(): string {
    return mb_substr((string)($_SERVER['REMOTE_ADDR'] ?? ''), 0, 45);
}

// ===== TOKENS =====

// Token de 32 bytes aleatorios en base64url (43 caracteres) y su SHA-256, que es lo único que se guarda
function catRegistroToken(): array {
    $token = rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
    return [$token, hash('sha256', $token)];
}

function catRegistroTokenValido(string $token): bool {
    return (bool)preg_match('/^[A-Za-z0-9_-]{43}$/', $token);
}

function catRegistroFolio(int $id): string {
    return 'REG-' . str_pad((string)$id, 6, '0', STR_PAD_LEFT);
}

// Correo parcialmente oculto para mostrarlo en pantalla (ca•••@gmail.com)
function catRegistroEmailOculto(string $email): string {
    [$usuario, $dominio] = array_pad(explode('@', $email, 2), 2, '');
    return mb_substr($usuario, 0, 2) . '•••@' . $dominio;
}

// ===== LIMPIEZA (lo mismo que el evento ev_registros_pendientes_vencidos, por si el programador de eventos está apagado) =====
function catRegistroLimpiar(PDO $pdo): void {
    $pdo->exec("UPDATE registros_pendientes
                   SET estado = 'expirado', fecha_cierre = NOW(), email = NULL, nombres = NULL, apellidos = NULL, celular = NULL,
                       direccion = NULL, ciudad = NULL, entidad_federativa = NULL, codigo_postal = NULL,
                       id_sucursal_preferida = NULL, marca_interes = NULL, password_hash = NULL
                 WHERE estado = 'pendiente' AND fecha_expiracion <= NOW()");
    $pdo->exec("UPDATE registros_pendientes SET ip_solicitud = NULL, email_hash = NULL
                 WHERE estado <> 'pendiente' AND (ip_solicitud IS NOT NULL OR email_hash IS NOT NULL)
                   AND COALESCE(fecha_cierre, fecha_expiracion) <= NOW() - INTERVAL 1 DAY");
}

// Cierra una solicitud (cancelada) y borra sus datos personales en el mismo UPDATE
function catRegistroCerrar(PDO $pdo, int $idRegistro): void {
    $pdo->prepare("UPDATE registros_pendientes
                      SET estado = 'cancelado', fecha_cierre = NOW(), email = NULL, nombres = NULL, apellidos = NULL, celular = NULL,
                          direccion = NULL, ciudad = NULL, entidad_federativa = NULL, codigo_postal = NULL,
                          id_sucursal_preferida = NULL, marca_interes = NULL, password_hash = NULL
                    WHERE id_registro = ? AND estado = 'pendiente'")->execute([$idRegistro]);
}

// Versiones vigentes del aviso y de los términos registradas en documentos_legales: [id_aviso, id_terminos]
function catRegistroVersionesVigentes(PDO $pdo): array {
    return [catLegalRegistrarVersion($pdo, catLegalDocumento('aviso_privacidad')),
            catLegalRegistrarVersion($pdo, catLegalDocumento('terminos_condiciones'))];
}

// Reglas de reenvío de una solicitud activa (cooldown y máximo de correos)
function catRegistroValidarReenvio(array $fila): void {
    if ((int)$fila['envios'] >= CAT_REGISTRO_MAX_ENVIOS) {
        throw new CatRegistroLimite('Ya enviamos varios correos a esta dirección. Revisa tu bandeja de entrada y la carpeta de spam, o inténtalo de nuevo mañana.');
    }
    $espera = CAT_REGISTRO_ESPERA_REENVIO - (int)$fila['segundos_desde_envio'];
    if ($fila['fecha_ultimo_envio'] !== null && $espera > 0) {
        throw new CatRegistroLimite("Espera {$espera} segundos antes de pedir otro correo.");
    }
}

// Solicitud activa (pendiente o aviso a cuenta existente) de un correo, bloqueada para la transacción
function catRegistroActivaPorCorreo(PDO $pdo, string $emailHash): ?array {
    $stmt = $pdo->prepare("SELECT r.*, TIMESTAMPDIFF(SECOND, r.fecha_ultimo_envio, NOW()) AS segundos_desde_envio
                             FROM registros_pendientes r
                            WHERE r.email_hash = ? AND r.estado IN ('pendiente', 'aviso_cuenta') AND r.fecha_expiracion > NOW()
                            ORDER BY r.id_registro DESC LIMIT 1 FOR UPDATE");
    $stmt->execute([$emailHash]);
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

// ===== PASO 1: SOLICITUD DE REGISTRO =====
// $d trae los campos ya validados por api.php (nombres, apellidos, email, celular, password_hash, dirección…).
// La respuesta es la misma exista o no una cuenta con ese correo: si ya existe, solo se le envía un aviso.
function catRegistroSolicitar(array $d): array {
    $pdo = db();
    catRegistroLimpiar($pdo);
    $ip = catRegistroIp();
    $emailHash = hash('sha256', $d['email']);

    $porIp = $pdo->prepare('SELECT COUNT(*) FROM registros_pendientes WHERE ip_solicitud = ? AND fecha_solicitud > NOW() - INTERVAL 1 HOUR');
    $porIp->execute([$ip]);
    if ((int)$porIp->fetchColumn() >= CAT_REGISTRO_MAX_POR_IP) {
        throw new CatRegistroLimite('Demasiadas solicitudes de registro desde esta conexión. Inténtalo de nuevo en una hora.');
    }
    [$idAviso, $idTerminos] = catRegistroVersionesVigentes($pdo);
    $urlCatalogo = catRegistroUrlCatalogo();

    $token = null;
    $pdo->beginTransaction();
    try {
        $buscar = $pdo->prepare('SELECT id_cliente, password_hash, estado FROM clientes WHERE email = ? LIMIT 1 FOR UPDATE');
        $buscar->execute([$d['email']]);
        $cliente = $buscar->fetch(PDO::FETCH_ASSOC) ?: null;
        $conCuenta = $cliente && ($cliente['password_hash'] ?? '') !== '';
        $inactivo = $cliente && $cliente['estado'] !== 'activo';

        $activa = catRegistroActivaPorCorreo($pdo, $emailHash);
        if ($activa) {
            catRegistroValidarReenvio($activa);
        } else {
            $porCorreo = $pdo->prepare('SELECT COUNT(*) FROM registros_pendientes WHERE email_hash = ? AND fecha_solicitud > NOW() - INTERVAL 1 DAY');
            $porCorreo->execute([$emailHash]);
            if ((int)$porCorreo->fetchColumn() >= CAT_REGISTRO_MAX_POR_CORREO) {
                throw new CatRegistroLimite('Ya se hicieron varias solicitudes con este correo hoy. Inténtalo de nuevo mañana.');
            }
        }

        if ($conCuenta || $inactivo) {
            // El correo ya tiene cuenta (o pertenece a un cliente inactivo): no se guarda nada personal, solo se avisa
            $tipoCorreo = $inactivo ? 'inactiva' : 'existente';
            if ($activa && $activa['estado'] === 'pendiente') catRegistroCerrar($pdo, (int)$activa['id_registro']);
            if ($activa && $activa['estado'] === 'aviso_cuenta') {
                $idRegistro = (int)$activa['id_registro'];
                $pdo->prepare('UPDATE registros_pendientes SET envios = envios + 1, fecha_ultimo_envio = NOW() WHERE id_registro = ?')->execute([$idRegistro]);
            } else {
                $pdo->prepare("INSERT INTO registros_pendientes (estado, email_hash, envios, fecha_ultimo_envio, fecha_expiracion, ip_solicitud)
                               VALUES ('aviso_cuenta', ?, 1, NOW(), NOW() + INTERVAL " . CAT_REGISTRO_VIGENCIA_HORAS . " HOUR, ?)")
                    ->execute([$emailHash, $ip]);
                $idRegistro = (int)$pdo->lastInsertId();
            }
        } else {
            // Solicitud pendiente: si ya había una para este correo se actualiza (nuevo token, el anterior deja de servir)
            $tipoCorreo = 'confirmar';
            [$token, $tokenHash] = catRegistroToken();
            $valores = [$d['email'], $emailHash, $d['nombres'], $d['apellidos'], $d['celular'], $d['direccion'], $d['ciudad'],
                        $d['entidad_federativa'], $d['codigo_postal'], $d['id_sucursal_preferida'], $d['marca_interes'],
                        $d['notif_promociones'], $d['password_hash'], $tokenHash, $idAviso, $idTerminos, $ip];
            if ($activa && $activa['estado'] === 'pendiente') {
                $idRegistro = (int)$activa['id_registro'];
                $pdo->prepare("UPDATE registros_pendientes
                                  SET email = ?, email_hash = ?, nombres = ?, apellidos = ?, celular = ?, direccion = NULLIF(?, ''),
                                      ciudad = NULLIF(?, ''), entidad_federativa = NULLIF(?, ''), codigo_postal = NULLIF(?, ''),
                                      id_sucursal_preferida = ?, marca_interes = ?, notif_promociones = ?, password_hash = ?,
                                      token_hash = ?, id_aviso = ?, id_terminos = ?, ip_solicitud = ?, envios = envios + 1,
                                      fecha_ultimo_envio = NOW(), fecha_expiracion = NOW() + INTERVAL " . CAT_REGISTRO_VIGENCIA_HORAS . " HOUR
                                WHERE id_registro = ? AND estado = 'pendiente'")
                    ->execute(array_merge($valores, [$idRegistro]));
            } else {
                $pdo->prepare("INSERT INTO registros_pendientes
                                  (email, email_hash, nombres, apellidos, celular, direccion, ciudad, entidad_federativa, codigo_postal,
                                   id_sucursal_preferida, marca_interes, notif_promociones, password_hash, token_hash, id_aviso, id_terminos,
                                   ip_solicitud, envios, fecha_ultimo_envio, fecha_expiracion)
                               VALUES (?, ?, ?, ?, ?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), ?, ?, ?, ?, ?, ?, ?, ?, 1, NOW(),
                                       NOW() + INTERVAL " . CAT_REGISTRO_VIGENCIA_HORAS . " HOUR)")
                    ->execute($valores);
                $idRegistro = (int)$pdo->lastInsertId();
            }
        }
        $pdo->commit();
    } catch (PDOException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        // Dos envíos simultáneos del mismo correo: la llave única (1062) o el bloqueo de filas (1213/1205) detienen al segundo
        if (in_array($e->errorInfo[1] ?? 0, [1062, 1205, 1213], true)) {
            throw new CatRegistroLimite('Ya estamos procesando una solicitud con este correo. Espera un momento.');
        }
        throw $e;
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    $fila = catRegistroFila($pdo, $idRegistro);
    $envio = catRegistroEnviarCorreo($tipoCorreo, $d['email'], $d['nombres'], $token, $fila, $urlCatalogo);
    if (!$envio['ok']) {
        // Sin correo no hay forma de aceptar: la solicitud se cancela y sus datos se borran (nunca queda una cuenta activa)
        if ($tipoCorreo === 'confirmar') catRegistroCerrar($pdo, $idRegistro);
        error_log('[Catalogo registro] ' . catRegistroFolio($idRegistro) . ' no se envió: ' . $envio['message']);
        throw new CatRegistroError('envio', 'No pudimos enviar el correo de confirmación. Tu cuenta no se creó; inténtalo de nuevo en unos minutos.');
    }
    return catRegistroResumen($fila);
}

function catRegistroFila(PDO $pdo, int $idRegistro): array {
    $stmt = $pdo->prepare("SELECT r.*, r.fecha_expiracion > NOW() AS vigente,
                                  TIMESTAMPDIFF(SECOND, r.fecha_ultimo_envio, NOW()) AS segundos_desde_envio
                             FROM registros_pendientes r WHERE r.id_registro = ?");
    $stmt->execute([$idRegistro]);
    $fila = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$fila) throw new CatRegistroError('invalido');
    return $fila;
}

// Datos de la pantalla «Revisa tu correo» (iguales para solicitudes nuevas y para avisos de cuenta existente; el id solo va a la sesión)
function catRegistroResumen(array $fila): array {
    $activa = in_array($fila['estado'], ['pendiente', 'aviso_cuenta'], true) && (int)$fila['vigente'] === 1;
    $estado = $fila['estado'] === 'completado' ? 'completado' : ($activa ? 'pendiente' : ($fila['estado'] === 'cancelado' ? 'cancelado' : 'expirado'));
    return [
        'id' => (int)$fila['id_registro'],
        'estado' => $estado,
        'vence' => catFecha((string)$fila['fecha_expiracion']),
        'reenviarEn' => $activa ? max(0, CAT_REGISTRO_ESPERA_REENVIO - (int)$fila['segundos_desde_envio']) : 0,
        'reenviosRestantes' => $activa ? max(0, CAT_REGISTRO_MAX_ENVIOS - (int)$fila['envios']) : 0
    ];
}

// ===== PASO 2: CORREO CON EL PDF Y EL BOTÓN =====
// $tipo: 'confirmar' (lleva el botón), 'existente' (ya tiene cuenta) o 'inactiva' (cliente inactivo)
function catRegistroEnviarCorreo(string $tipo, string $email, string $nombre, ?string $token, array $fila, string $urlCatalogo): array {
    $apiKey = karmaEnv('BREVO_API_KEY');
    $remitenteEmail = karmaEnv('BREVO_REMITENTE_EMAIL');
    $remitenteNombre = karmaEnv('BREVO_REMITENTE_NOMBRE', 'KARMA Agencia de Autos');
    if ($apiKey === '' || $remitenteEmail === '') {
        return ['ok' => false, 'message' => 'Faltan BREVO_API_KEY o BREVO_REMITENTE_EMAIL en el archivo .env.'];
    }
    $folio = catRegistroFolio((int)$fila['id_registro']);
    try {
        $pdf = catLegalPdf(['folio' => $folio, 'email' => $email, 'fecha' => catFecha(date('Y-m-d H:i:s'))], $urlCatalogo);
    } catch (Throwable $e) {
        return ['ok' => false, 'message' => 'No se pudo generar el PDF: ' . $e->getMessage()];
    }
    $enlace = $token !== null ? $urlCatalogo . 'confirmar_registro.php?token=' . $token : null;
    $asuntos = [
        'confirmar' => 'Confirma tu registro en KARMA: Aviso de Privacidad y Términos y Condiciones',
        'existente' => 'Ya tienes una cuenta en el catálogo de KARMA',
        'inactiva' => 'Tu solicitud de registro en KARMA'
    ];
    $datos = ['tipo' => $tipo, 'nombre' => $nombre, 'enlace' => $enlace, 'folio' => $folio, 'vence' => catFecha((string)$fila['fecha_expiracion']),
              'url' => $urlCatalogo];
    $payload = [
        'sender' => ['name' => $remitenteNombre, 'email' => $remitenteEmail],
        'to' => [['email' => $email, 'name' => $nombre]],
        'replyTo' => ['email' => $remitenteEmail, 'name' => $remitenteNombre],
        'subject' => $asuntos[$tipo],
        'htmlContent' => catRegistroCorreoHtml($datos),
        'textContent' => catRegistroCorreoTexto($datos),
        'attachment' => [['name' => catLegalNombrePdf(), 'content' => base64_encode($pdf)]],
        'tags' => ['registro-catalogo']
    ];
    // Modo de prueba de Brevo (solo en entorno local): valida el correo completo pero no lo entrega
    if (karmaEnv('BREVO_MODO_PRUEBA') === '1' && catHostLocal((string)parse_url($urlCatalogo, PHP_URL_HOST))) {
        $payload['headers'] = ['X-Sib-Sandbox' => 'drop'];
    }
    return karmaBrevoEnviar($apiKey, $payload);
}

// Cuerpo HTML del correo (tablas y estilos en línea para que se vea bien en Gmail y en el celular)
function catRegistroCorreoHtml(array $c): string {
    $docs = catLegalDocumentos();
    $aviso = $docs['aviso_privacidad'];
    $terminos = $docs['terminos_condiciones'];
    $p = 'style="margin:0 0 14px;font-size:15px;line-height:1.6;color:#0d1320"';
    $chico = 'style="margin:0 0 10px;font-size:13px;line-height:1.55;color:#4a5568"';
    $versiones = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 18px;border:1px solid #e2e6ec;border-radius:8px">'
        . '<tr><td style="padding:12px 16px;font-size:14px;color:#0d1320;border-bottom:1px solid #e2e6ec"><strong>' . e($aviso['titulo']) . '</strong><br><span style="color:#636d7e;font-size:12.5px">Versión ' . e($aviso['version']) . ' · vigente desde el ' . e(catLegalFecha($aviso['vigencia'])) . '</span></td></tr>'
        . '<tr><td style="padding:12px 16px;font-size:14px;color:#0d1320"><strong>' . e($terminos['titulo']) . '</strong><br><span style="color:#636d7e;font-size:12.5px">Versión ' . e($terminos['version']) . ' · vigente desde el ' . e(catLegalFecha($terminos['vigencia'])) . '</span></td></tr>'
        . '</table>';

    if ($c['tipo'] === 'confirmar') {
        $cuerpo = '<p ' . $p . '>Recibimos una solicitud para crear tu cuenta en el catálogo en línea de KARMA con este correo. <strong>Tu registro está pendiente de confirmación.</strong></p>'
            . '<p ' . $p . '>Para finalizarlo, lee y acepta el Aviso de Privacidad y los Términos y Condiciones. Te los adjuntamos en PDF:</p>'
            . $versiones
            . '<table role="presentation" cellpadding="0" cellspacing="0" style="margin:6px 0 18px"><tr><td style="border-radius:6px;background:#10213f">'
            . '<a href="' . e($c['enlace']) . '" style="display:inline-block;padding:15px 22px;font-size:15px;font-weight:bold;line-height:1.35;color:#ffffff;text-decoration:none;border-radius:6px">' . e(CAT_REGISTRO_BOTON) . '</a>'
            . '</td></tr></table>'
            . '<p ' . $chico . '>El botón abre una página de KARMA donde confirmarás tu aceptación con un último clic; tu cuenta se crea solo en ese momento. El enlace es personal, de un solo uso y vence el <strong>' . e($c['vence']) . '</strong>.</p>'
            . '<p ' . $chico . '><strong>Si no deseas aceptar, ignora este mensaje:</strong> tu registro no se completará y los datos de la solicitud se eliminarán automáticamente cuando venza el enlace. Si tú no solicitaste este registro, también puedes ignorarlo.</p>'
            . '<p style="margin:0 0 10px;font-size:12px;line-height:1.5;color:#636d7e;word-break:break-all">Si el botón no funciona, copia esta dirección en tu navegador:<br><a href="' . e($c['enlace']) . '" style="color:#1f5bd8">' . e($c['enlace']) . '</a></p>';
    } elseif ($c['tipo'] === 'existente') {
        $cuerpo = '<p ' . $p . '>Recibimos una solicitud para crear una cuenta en el catálogo en línea de KARMA con este correo, pero <strong>ya existe una cuenta registrada con él</strong>, así que no es necesario crear otra.</p>'
            . '<p ' . $p . '>Puedes <a href="' . e($c['url']) . 'login.php" style="color:#1f5bd8">iniciar sesión aquí</a>. Si olvidaste tu contraseña, acude a tu sucursal o escríbenos desde la página de Contacto.</p>'
            . '<p ' . $chico . '>Si tú no hiciste esta solicitud, ignora este mensaje: tu cuenta no cambió. Para tu referencia adjuntamos el Aviso de Privacidad y los Términos y Condiciones vigentes.</p>';
    } else {
        $cuerpo = '<p ' . $p . '>Recibimos una solicitud para crear una cuenta en el catálogo en línea de KARMA con este correo. Este correo pertenece a un registro de cliente que está <strong>inactivo</strong>, por lo que no podemos crear el acceso en línea.</p>'
            . '<p ' . $p . '>Para reactivarlo, acude a cualquiera de nuestras sucursales de Manzanillo o Colima.</p>'
            . '<p ' . $chico . '>Si tú no hiciste esta solicitud, ignora este mensaje. Para tu referencia adjuntamos el Aviso de Privacidad y los Términos y Condiciones vigentes.</p>';
    }

    return '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>'
        . '<body style="margin:0;padding:0;background:#f3f5f8">'
        . '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f3f5f8"><tr><td align="center" style="padding:24px 12px">'
        . '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#ffffff;border-radius:10px;overflow:hidden;font-family:Arial,Helvetica,sans-serif">'
        . '<tr><td style="background:#10213f;padding:20px 28px"><span style="font-size:22px;font-weight:bold;letter-spacing:4px;color:#ffffff">KARMA</span>'
        . '<br><span style="font-size:12px;color:#c7cfdb;letter-spacing:1px">Audi · Porsche · Ducati</span></td></tr>'
        . '<tr><td style="padding:28px 28px 8px">'
        . '<p style="margin:0 0 14px;font-size:17px;font-weight:bold;color:#10213f">' . ($c['nombre'] !== '' ? 'Hola, ' . e($c['nombre']) . ':' : 'Hola:') . '</p>'
        . $cuerpo
        . '</td></tr>'
        . '<tr><td style="padding:16px 28px 22px;border-top:1px solid #e2e6ec;font-size:11.5px;line-height:1.5;color:#636d7e">'
        . 'Folio de solicitud ' . e($c['folio']) . ' · Este correo se envió automáticamente; no compartas el enlace con nadie.<br>'
        . 'KARMA es un proyecto integrador académico; los pagos con tarjeta del sitio son simulados.'
        . '</td></tr></table></td></tr></table></body></html>';
}

// Versión en texto plano del mismo mensaje (para lectores de correo sin HTML)
function catRegistroCorreoTexto(array $c): string {
    $docs = catLegalDocumentos();
    $lineas = [$c['nombre'] !== '' ? "Hola, {$c['nombre']}:" : 'Hola:', ''];
    if ($c['tipo'] === 'confirmar') {
        $lineas[] = 'Recibimos una solicitud para crear tu cuenta en el catálogo en línea de KARMA con este correo. Tu registro está pendiente de confirmación.';
        $lineas[] = 'Para finalizarlo, lee y acepta el Aviso de Privacidad y los Términos y Condiciones que adjuntamos en PDF:';
        foreach ($docs as $doc) $lineas[] = "- {$doc['titulo']}, versión {$doc['version']}, vigente desde el " . catLegalFecha($doc['vigencia']);
        $lineas[] = '';
        $lineas[] = CAT_REGISTRO_BOTON . ':';
        $lineas[] = $c['enlace'];
        $lineas[] = '';
        $lineas[] = "La página te pedirá un último clic para confirmar; tu cuenta se crea solo en ese momento. El enlace es personal, de un solo uso y vence el {$c['vence']}.";
        $lineas[] = 'Si no deseas aceptar, ignora este mensaje: tu registro no se completará y los datos de la solicitud se eliminarán cuando venza el enlace.';
    } elseif ($c['tipo'] === 'existente') {
        $lineas[] = 'Recibimos una solicitud para crear una cuenta con este correo, pero ya existe una cuenta registrada con él.';
        $lineas[] = "Inicia sesión en {$c['url']}login.php. Si olvidaste tu contraseña, acude a tu sucursal o escríbenos desde Contacto.";
        $lineas[] = 'Si tú no hiciste esta solicitud, ignora este mensaje: tu cuenta no cambió.';
    } else {
        $lineas[] = 'Recibimos una solicitud para crear una cuenta con este correo, pero pertenece a un registro de cliente inactivo.';
        $lineas[] = 'Para reactivarlo, acude a cualquiera de nuestras sucursales de Manzanillo o Colima.';
    }
    $lineas[] = '';
    $lineas[] = "Folio de solicitud {$c['folio']}. KARMA es un proyecto integrador académico.";
    return implode("\n", $lineas);
}

// ===== REENVÍOS =====

// Reenvía el correo de una solicitud activa. Las pendientes reciben un token nuevo (el anterior deja de servir)
// y la versión vigente de los documentos. $email y $nombre son los que escribió la persona (solo se usan en avisos de cuenta).
function catRegistroReenviar(int $idRegistro, ?string $email = null, string $nombre = ''): array {
    $pdo = db();
    catRegistroLimpiar($pdo);
    [$idAviso, $idTerminos] = catRegistroVersionesVigentes($pdo);
    $urlCatalogo = catRegistroUrlCatalogo();
    $token = null;
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT r.*, TIMESTAMPDIFF(SECOND, r.fecha_ultimo_envio, NOW()) AS segundos_desde_envio
                                 FROM registros_pendientes r
                                WHERE r.id_registro = ? AND r.estado IN ('pendiente', 'aviso_cuenta') AND r.fecha_expiracion > NOW() FOR UPDATE");
        $stmt->execute([$idRegistro]);
        $fila = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$fila) throw new CatRegistroError('vencido', 'Tu solicitud ya no está vigente. Vuelve a llenar el formulario de registro.');
        catRegistroValidarReenvio($fila);
        if ($fila['estado'] === 'pendiente') {
            [$token, $tokenHash] = catRegistroToken();
            $pdo->prepare("UPDATE registros_pendientes
                              SET token_hash = ?, id_aviso = ?, id_terminos = ?, envios = envios + 1, fecha_ultimo_envio = NOW(),
                                  fecha_expiracion = NOW() + INTERVAL " . CAT_REGISTRO_VIGENCIA_HORAS . " HOUR
                            WHERE id_registro = ? AND estado = 'pendiente'")
                ->execute([$tokenHash, $idAviso, $idTerminos, $idRegistro]);
            $email = (string)$fila['email'];
            $nombre = (string)$fila['nombres'];
            $tipoCorreo = 'confirmar';
        } else {
            if ($email === null || !hash_equals((string)$fila['email_hash'], hash('sha256', $email))) {
                throw new CatRegistroError('vencido', 'Tu solicitud ya no está vigente. Vuelve a llenar el formulario de registro.');
            }
            $pdo->prepare('UPDATE registros_pendientes SET envios = envios + 1, fecha_ultimo_envio = NOW() WHERE id_registro = ?')->execute([$idRegistro]);
            $cuenta = $pdo->prepare('SELECT estado FROM clientes WHERE email = ? LIMIT 1');
            $cuenta->execute([$email]);
            $tipoCorreo = $cuenta->fetchColumn() === 'activo' ? 'existente' : 'inactiva';
        }
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
    $fila = catRegistroFila($pdo, $idRegistro);
    $envio = catRegistroEnviarCorreo($tipoCorreo, $email, $nombre, $token, $fila, $urlCatalogo);
    if (!$envio['ok']) {
        error_log('[Catalogo registro] reenvío ' . catRegistroFolio($idRegistro) . ' no se envió: ' . $envio['message']);
        throw new CatRegistroError('envio', 'No pudimos reenviar el correo. Inténtalo de nuevo en unos minutos.');
    }
    return catRegistroResumen($fila);
}

// Reenvío pedido escribiendo el correo (página de enlace inválido). Nunca revela si hay solicitud o cuenta:
// la respuesta es la misma en todos los casos y los límites se aplican en silencio.
function catRegistroReenviarPorCorreo(string $email): void {
    $pdo = db();
    catRegistroLimpiar($pdo);
    $stmt = $pdo->prepare("SELECT id_registro FROM registros_pendientes
                            WHERE email_hash = ? AND estado IN ('pendiente', 'aviso_cuenta') AND fecha_expiracion > NOW()
                            ORDER BY id_registro DESC LIMIT 1");
    $stmt->execute([hash('sha256', $email)]);
    $id = $stmt->fetchColumn();
    if ($id === false) return;
    try {
        catRegistroReenviar((int)$id, $email);
    } catch (CatRegistroLimite | CatRegistroError $e) {
        // mismo mensaje para todos; el detalle no se muestra
    }
}

// ===== PASO 3: ENLACE DEL CORREO =====

// Busca la solicitud del token (solo lectura) y regresa [código de estado, fila|null]. No acepta nada.
function catRegistroEstadoToken(string $token): array {
    if (!catRegistroTokenValido($token)) return ['invalido', null];
    $pdo = db();
    catRegistroLimpiar($pdo);
    $stmt = $pdo->prepare('SELECT r.*, r.fecha_expiracion > NOW() AS vigente FROM registros_pendientes r WHERE r.token_hash = ?');
    $stmt->execute([hash('sha256', $token)]);
    $fila = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    if (!$fila) return ['invalido', null];
    if ($fila['estado'] === 'completado') return ['usado', $fila];
    if ($fila['estado'] === 'cancelado') return ['cancelado', $fila];
    if ($fila['estado'] !== 'pendiente' || (int)$fila['vigente'] !== 1) return ['vencido', $fila];
    if ((int)$fila['id_aviso'] !== catLegalIdVigente($pdo, 'aviso_privacidad') || (int)$fila['id_terminos'] !== catLegalIdVigente($pdo, 'terminos_condiciones')) {
        return ['documentos', $fila];
    }
    return ['vigente', $fila];
}

// ===== PASO 4: ACEPTACIÓN Y ACTIVACIÓN (solo con el POST del botón de la página de confirmación) =====
// $idAviso / $idTerminos = versiones que la página mostró; deben ser las enviadas en el PDF y las vigentes.
// Regresa ['id_cliente' => …, 'id_sucursal' => …]. Dos clics simultáneos: el segundo espera el bloqueo y encuentra la solicitud completada.
function catRegistroConfirmar(string $token, int $idAviso, int $idTerminos, string $ip, string $userAgent): array {
    if (!catRegistroTokenValido($token)) throw new CatRegistroError('invalido');
    $pdo = db();
    catRegistroLimpiar($pdo);
    [$idAvisoVigente, $idTerminosVigente] = catRegistroVersionesVigentes($pdo);

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare('SELECT r.*, r.fecha_expiracion > NOW() AS vigente FROM registros_pendientes r WHERE r.token_hash = ? FOR UPDATE');
        $stmt->execute([hash('sha256', $token)]);
        $r = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$r) throw new CatRegistroError('invalido');
        if ($r['estado'] === 'completado') throw new CatRegistroError('usado');
        if ($r['estado'] === 'cancelado') throw new CatRegistroError('cancelado');
        if ($r['estado'] !== 'pendiente' || (int)$r['vigente'] !== 1) throw new CatRegistroError('vencido');
        if ((int)$r['id_aviso'] !== $idAvisoVigente || (int)$r['id_terminos'] !== $idTerminosVigente
            || $idAviso !== (int)$r['id_aviso'] || $idTerminos !== (int)$r['id_terminos']) {
            throw new CatRegistroError('documentos');
        }
        $idRegistro = (int)$r['id_registro'];

        // 1) Aceptación con el token vigente (el trigger rechaza aceptar fuera de vigencia)
        $pdo->prepare('UPDATE registros_pendientes SET fecha_aceptacion = NOW() WHERE id_registro = ? AND estado = ? AND fecha_aceptacion IS NULL')
            ->execute([$idRegistro, 'pendiente']);

        // 2) El correo no debe tener ya una cuenta en línea ni pertenecer a un cliente inactivo
        $buscar = $pdo->prepare('SELECT id_cliente, password_hash, estado FROM clientes WHERE email = ? LIMIT 1 FOR UPDATE');
        $buscar->execute([$r['email']]);
        $existente = $buscar->fetch(PDO::FETCH_ASSOC) ?: null;
        if ($existente && (($existente['password_hash'] ?? '') !== '' || $existente['estado'] !== 'activo')) {
            catRegistroCerrar($pdo, $idRegistro);
            $pdo->commit();
            throw new CatRegistroError($existente['estado'] !== 'activo' ? 'inactiva' : 'existente');
        }

        // 3) Crear la cuenta, o darle acceso en línea al cliente que ya existía en el POS (sin duplicarlo)
        $nombreCompleto = trim("{$r['nombres']} {$r['apellidos']}");
        if ($existente) {
            $idCliente = (int)$existente['id_cliente'];
            $pdo->prepare("UPDATE clientes SET nombres = ?, apellidos = ?, password_hash = ?,
                                  celular = COALESCE(NULLIF(celular, ''), ?), direccion = COALESCE(NULLIF(direccion, ''), ?),
                                  ciudad = ?, entidad_federativa = ?, codigo_postal = ?, id_sucursal_preferida = ?,
                                  marca_interes = ?, notif_promociones = ?, fecha_registro = NOW()
                            WHERE id_cliente = ?")
                ->execute([$r['nombres'], $r['apellidos'], $r['password_hash'], $r['celular'], $r['direccion'], $r['ciudad'],
                           $r['entidad_federativa'], $r['codigo_postal'], $r['id_sucursal_preferida'], $r['marca_interes'],
                           (int)$r['notif_promociones'], $idCliente]);
        } else {
            $pdo->prepare("INSERT INTO clientes (nombre, nombres, apellidos, email, celular, direccion, ciudad, entidad_federativa, codigo_postal,
                                                 id_sucursal_preferida, marca_interes, notif_promociones, password_hash, estado,
                                                 abonos_pagados, abonos_totales, fecha_registro)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'activo', 0, 0, NOW())")
                ->execute([$nombreCompleto, $r['nombres'], $r['apellidos'], $r['email'], $r['celular'], $r['direccion'], $r['ciudad'],
                           $r['entidad_federativa'], $r['codigo_postal'], $r['id_sucursal_preferida'], $r['marca_interes'],
                           (int)$r['notif_promociones'], $r['password_hash']]);
            $idCliente = (int)$pdo->lastInsertId();
        }

        // 4) Constancias: una por documento, con la versión exacta enviada en el PDF
        $constancia = $pdo->prepare('INSERT INTO aceptaciones_documentos (id_cliente, id_documento, id_registro, fecha_aceptacion, ip, user_agent)
                                     VALUES (?, ?, ?, NOW(), ?, ?)');
        foreach ([(int)$r['id_aviso'], (int)$r['id_terminos']] as $idDocumento) {
            $constancia->execute([$idCliente, $idDocumento, $idRegistro, mb_substr($ip, 0, 45), mb_substr($userAgent, 0, 255)]);
        }

        catNotificar($pdo, $idCliente, 'cuenta', '¡Bienvenido a KARMA!',
            'Tu cuenta quedó lista. Aceptaste el Aviso de Privacidad y los Términos y Condiciones vigentes; puedes consultarlos cuando quieras al pie de la página.', 'perfil.php');

        // 5) Solicitud completada: el token queda inservible y se borran los datos que ya pasaron a la cuenta
        $pdo->prepare("UPDATE registros_pendientes
                          SET estado = 'completado', id_cliente = ?, fecha_cierre = NOW(), email = NULL, nombres = NULL, apellidos = NULL,
                              celular = NULL, direccion = NULL, ciudad = NULL, entidad_federativa = NULL, codigo_postal = NULL,
                              id_sucursal_preferida = NULL, marca_interes = NULL, password_hash = NULL, ip_solicitud = NULL
                        WHERE id_registro = ? AND estado = 'pendiente'")
            ->execute([$idCliente, $idRegistro]);
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
    return ['id_cliente' => $idCliente, 'id_sucursal' => $r['id_sucursal_preferida'] !== null ? (int)$r['id_sucursal_preferida'] : null];
}

// «No acepto»: cancela la solicitud del token y borra sus datos de inmediato
function catRegistroRechazar(string $token): void {
    if (!catRegistroTokenValido($token)) throw new CatRegistroError('invalido');
    $pdo = db();
    $stmt = $pdo->prepare("SELECT id_registro FROM registros_pendientes WHERE token_hash = ? AND estado = 'pendiente'");
    $stmt->execute([hash('sha256', $token)]);
    $id = $stmt->fetchColumn();
    if ($id === false) throw new CatRegistroError('invalido');
    catRegistroCerrar($pdo, (int)$id);
}

// ===== INICIO DE SESIÓN CON UNA SOLICITUD SIN CONFIRMAR =====
// Solo responde «pendiente» si la contraseña coincide, así no revela qué correos tienen solicitudes
function catRegistroPendienteConPassword(string $email, string $password): bool {
    $pdo = db();
    catRegistroLimpiar($pdo);
    $stmt = $pdo->prepare('SELECT password_hash FROM registros_pendientes WHERE email_pendiente = ? AND fecha_expiracion > NOW()');
    $stmt->execute([$email]);
    $hash = $stmt->fetchColumn();
    // Siempre se hace una verificación bcrypt (con un hash de relleno si no hay solicitud) para que el tiempo no delate nada
    $coincide = password_verify($password, $hash !== false ? (string)$hash : '$2y$12$hwYmuOlp6nD9GMMParLSaudYeryxz7nV8celMCqEe4ual5f/kf7z2');
    return $hash !== false && $coincide;
}
