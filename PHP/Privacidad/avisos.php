<?php
declare(strict_types=1);

/* KARMA · Avisos de privacidad para empleados.
   Al dar de alta a un empleado (panel de administrador → Personal) se le manda por correo, con Brevo, el aviso de privacidad
   simplificado junto con sus datos de acceso y la indicación de cambiar su contraseña temporal. El empleado no tiene que
   aceptar nada: el correo solo informa. El administrador ve el estado de cada aviso en la pestaña «Avisos de privacidad»:
     pendiente = todavía no se envía o el envío falló · enviado = Brevo aceptó el correo · revisado = el empleado lo abrió
   (se detecta con la imagen de apertura del correo, PHP/Privacidad/abierto.php, o al entrar al enlace del aviso integral,
   PHP/Privacidad/aviso.php). Tabla: Database/avisos_privacidad.sql */

require_once dirname(__DIR__) . '/PuntoDeVenta/correo.php';

// Fecha de la versión vigente del aviso (la del documento «Aviso de Privacidad para Empleados — KARMA»)
const AVISO_VERSION = '2026-10-20';
const AVISO_VERSION_TEXTO = '20 de octubre de 2026';
// Datos del responsable que aparecen en el correo
const AVISO_EMPRESA = 'Grupo Automotriz Karma, S.A. de C.V.';
const AVISO_ENCARGADO = 'DevCorp Soluciones Tecnológicas, S.A. de C.V.';
const AVISO_DOMICILIO = 'Av. Miguel de la Madrid Hurtado No. 100, Col. Salahua, C.P. 28869, Manzanillo, Colima, México';
const AVISO_CORREO_PRIVACIDAD = 'privacidad@karma-automotriz.mx';

// ¿La base ya tiene la tabla de avisos? (se importa con Database/avisos_privacidad.sql)
function avisosTablaLista(PDO $pdo): bool {
    static $lista = null;
    if ($lista === null) {
        $lista = (bool)$pdo->query("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'avisos_privacidad'")->fetchColumn();
    }
    return $lista;
}

// ¿La tabla usuarios tiene la columna indicada? (columnas opcionales de Database/avisos_privacidad.sql)
function avisosColumnaUsuarios(PDO $pdo, string $columna): bool {
    static $columnas = null;
    if ($columnas === null) {
        $columnas = $pdo->query("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios'")
            ->fetchAll(PDO::FETCH_COLUMN);
    }
    return in_array($columna, $columnas, true);
}

// Nombre del rol para mostrar en el correo
function avisoNombreRol(string $rol): string {
    return match ($rol) {
        'Admin_General', 'Administrador General' => 'Administrador General',
        default => $rol,
    };
}

// Dirección pública del proyecto (https://dominio/carpeta). Se puede fijar con KARMA_URL_PUBLICA en el .env;
// si no, se calcula con el dominio y la carpeta de la petición actual (cualquier script dentro de PHP/)
function avisoUrlBase(): string {
    $fija = rtrim(karmaEnv('KARMA_URL_PUBLICA'), '/');
    if ($fija !== '') return $fija;
    $https = function_exists('karmaEsHttps') ? karmaEsHttps() : (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
    $host = (string)($_SERVER['HTTP_HOST'] ?? 'localhost');
    // Solo se acepta un nombre de host válido (evita que un encabezado Host manipulado termine en los enlaces del correo)
    if (!preg_match('/^[A-Za-z0-9.\-]+(:\d+)?$/', $host)) $host = 'localhost';
    $script = str_replace('\\', '/', (string)($_SERVER['SCRIPT_NAME'] ?? ''));
    $carpeta = (string)preg_replace('#/PHP/.*$#i', '', $script);
    return ($https ? 'https' : 'http') . '://' . $host . $carpeta;
}

// Registro del aviso de un empleado; si todavía no existe se crea como «pendiente» con su token
function avisoAsegurarRegistro(PDO $pdo, int $idUsuario): array {
    $stmt = $pdo->prepare("SELECT * FROM avisos_privacidad WHERE id_usuario = ?");
    $stmt->execute([$idUsuario]);
    $aviso = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($aviso) return $aviso;
    $pdo->prepare("INSERT INTO avisos_privacidad (id_usuario, estado, token, version_aviso) VALUES (?, 'pendiente', ?, ?)")
        ->execute([$idUsuario, bin2hex(random_bytes(32)), AVISO_VERSION]);
    $stmt->execute([$idUsuario]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

// Datos del empleado que se usan en el correo
function avisoEmpleado(PDO $pdo, int $idUsuario): ?array {
    $stmt = $pdo->prepare("
        SELECT u.*, r.nombre_rol, s.nombre AS sucursal
        FROM usuarios u
        JOIN roles r ON r.id_rol = u.id_rol
        LEFT JOIN sucursales s ON s.id_sucursal = u.id_sucursal
        WHERE u.id_usuario = ?");
    $stmt->execute([$idUsuario]);
    $u = $stmt->fetch(PDO::FETCH_ASSOC);
    return $u ?: null;
}

// Cuerpo HTML del correo: aviso de privacidad simplificado + datos de acceso (si hay contraseña temporal)
function avisoCorreoHTML(array $empleado, string $token, ?string $passwordTemporal): string {
    $base = avisoUrlBase();
    $enlaceAviso = $base . '/PHP/Privacidad/aviso.php?t=' . rawurlencode($token);
    $pixel = $base . '/PHP/Privacidad/abierto.php?t=' . rawurlencode($token);
    $enlaceLogin = $base . '/index.html';
    $nombre = trim(($empleado['nombre'] ?? '') . ' ' . ($empleado['apellidos'] ?? ''));
    $rol = avisoNombreRol((string)$empleado['nombre_rol']);
    $sucursal = trim((string)($empleado['sucursal'] ?? ''));
    $alta = 'te dio de alta como <strong>' . h($rol) . '</strong>'
        . ($sucursal !== '' ? ' de la sucursal <strong>' . h($sucursal) . '</strong>' : '')
        . ' en el sistema KARMA POS';

    $p = 'margin:0 0 14px;font-size:14px;line-height:1.6;color:#17181A';
    $bloqueAcceso = '';
    if ($passwordTemporal !== null) {
        $bloqueAcceso = '
        <div style="margin:0 0 22px;padding:18px 20px;border:1px solid #E2E1DD;border-radius:12px;background:#F7F7F5">
          <p style="margin:0 0 10px;font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#9E1B2E;font-weight:bold">Tus datos de acceso</p>
          <p style="' . $p . '">Usuario (correo): <strong>' . h($empleado['correo']) . '</strong><br>
             Contraseña temporal: <strong style="font-family:Consolas,monospace;font-size:15px">' . h($passwordTemporal) . '</strong></p>
          <p style="' . $p . '">Por seguridad, <strong>cambia esta contraseña por una propia lo antes posible</strong>. El sistema te
             pedirá hacerlo la primera vez que inicies sesión y después podrás cambiarla cuando quieras desde la opción
             «Cambiar contraseña». Nunca compartas tu contraseña: nadie de KARMA te la pedirá.</p>
          <p style="margin:0"><a href="' . h($enlaceLogin) . '" style="display:inline-block;padding:10px 18px;border-radius:999px;background:#10213F;color:#FFFFFF;text-decoration:none;font-size:13px;font-weight:bold">Iniciar sesión en KARMA POS</a></p>
        </div>';
    }

    return '<!DOCTYPE html><html lang="es"><body style="margin:0;padding:0;background:#EFEFEC">
    <div style="max-width:620px;margin:0 auto;padding:28px 16px;font-family:Arial,Helvetica,sans-serif">
      <div style="background:#FFFFFF;border-radius:16px;padding:28px 26px;border:1px solid #E2E1DD">
        <p style="margin:0 0 4px;font-size:22px;font-weight:bold;letter-spacing:.12em;color:#10213F">KARMA</p>
        <p style="margin:0 0 22px;font-size:12px;color:#6E6E6C">Tu cuenta en el sistema KARMA POS y aviso de privacidad</p>
        <p style="' . $p . '">Hola, <strong>' . h($nombre) . '</strong>:</p>
        <p style="' . $p . '">El Administrador General de <strong>' . h(AVISO_EMPRESA) . '</strong> («KARMA») ' . $alta . '. Este sistema lo
           desarrolla, aloja y mantiene <strong>' . h(AVISO_ENCARGADO) . '</strong> («DevCorp»), que envía este correo por cuenta de KARMA.</p>
        ' . $bloqueAcceso . '
        <p style="margin:0 0 12px;font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#9E1B2E;font-weight:bold">Aviso de privacidad simplificado</p>
        <p style="' . $p . '"><strong>Responsable.</strong> KARMA, con domicilio en ' . h(AVISO_DOMICILIO) . ', es responsable del tratamiento de tus datos personales.</p>
        <p style="' . $p . '"><strong>¿Para qué usamos tus datos?</strong> Para integrar tu expediente laboral, crear tu cuenta y tu gafete, darte
           acceso al Punto de Venta, identificarte al autorizar operaciones, registrar las operaciones que realices, pagar tu nómina y
           cumplir las obligaciones laborales, fiscales y de seguridad social. No usamos tus datos para finalidades secundarias, como
           publicidad o mercadotecnia.</p>
        <p style="' . $p . '"><strong>Transferencias.</strong> Solo compartimos tus datos con las autoridades e instituciones que exige la ley
           (IMSS, SAT, INFONAVIT, FONACOT, autoridades del trabajo y judiciales) y con el banco que paga tu nómina. Ninguna de estas
           transferencias requiere tu consentimiento.</p>
        <p style="' . $p . '"><strong>Tus derechos ARCO.</strong> Puedes acceder a tus datos, rectificarlos, cancelarlos u oponerte a su
           tratamiento, y también revocar tu consentimiento. Para hacerlo, escribe a <strong>' . h(AVISO_CORREO_PRIVACIDAD) . '</strong> o acude
           al Departamento de Protección de Datos Personales en el domicilio indicado.</p>
        <p style="' . $p . '"><strong>Aviso integral.</strong> Puedes consultar el aviso de privacidad integral en el siguiente enlace, en el
           apartado «Aviso de privacidad» del sistema KARMA POS o pedirlo en el Departamento de Recursos Humanos de tu sucursal.</p>
        <p style="margin:0 0 18px"><a href="' . h($enlaceAviso) . '" style="display:inline-block;padding:10px 18px;border-radius:999px;background:#9E1B2E;color:#FFFFFF;text-decoration:none;font-size:13px;font-weight:bold">Leer el aviso de privacidad integral</a></p>
        <p style="' . $p . ';font-style:italic">Si después de recibir este aviso no manifiestas tu oposición, entenderemos que consientes el
           tratamiento de tus datos en los términos descritos. No necesitas responder ni aceptar nada.</p>
        <p style="margin:0;font-size:12px;color:#6E6E6C">Última actualización: ' . h(AVISO_VERSION_TEXTO) . '.</p>
      </div>
      <p style="margin:14px 0 0;font-size:11px;color:#6E6E6C;text-align:center">Correo automático del sistema KARMA POS. Si no esperabas este mensaje, avisa a ' . h(AVISO_CORREO_PRIVACIDAD) . '.</p>
    </div>
    <img src="' . h($pixel) . '" width="1" height="1" alt="" style="display:block;width:1px;height:1px;border:0">
    </body></html>';
}

// Manda (o vuelve a mandar) el aviso a un empleado. $passwordTemporal se incluye en el correo solo si se indica.
// Regresa ['ok' => bool, 'mensaje' => texto para el administrador, 'aviso' => fila actualizada]
function avisoEnviar(PDO $pdo, int $idUsuario, ?string $passwordTemporal = null): array {
    if (!avisosTablaLista($pdo)) {
        return ['ok' => false, 'mensaje' => 'Falta importar Database/avisos_privacidad.sql en la base de datos.', 'aviso' => null];
    }
    $empleado = avisoEmpleado($pdo, $idUsuario);
    if (!$empleado) return ['ok' => false, 'mensaje' => 'El empleado no existe.', 'aviso' => null];
    $aviso = avisoAsegurarRegistro($pdo, $idUsuario);

    $apiKey = karmaEnv('BREVO_API_KEY');
    $remitenteEmail = karmaEnv('BREVO_REMITENTE_EMAIL');
    $remitenteNombre = karmaEnv('BREVO_REMITENTE_NOMBRE', 'KARMA Agencia de Autos');
    if ($apiKey === '' || $remitenteEmail === '') {
        $envio = ['ok' => false, 'message' => 'El correo aún no está configurado: agrega BREVO_API_KEY y BREVO_REMITENTE_EMAIL al archivo .env.'];
    } else {
        $nombre = trim(($empleado['nombre'] ?? '') . ' ' . ($empleado['apellidos'] ?? ''));
        $envio = karmaBrevoEnviar($apiKey, [
            'sender' => ['name' => $remitenteNombre, 'email' => $remitenteEmail],
            'to' => [['email' => $empleado['correo'], 'name' => $nombre]],
            'replyTo' => ['email' => $remitenteEmail, 'name' => $remitenteNombre],
            'subject' => 'Tu cuenta en el sistema KARMA POS y aviso de privacidad',
            'htmlContent' => avisoCorreoHTML($empleado, (string)$aviso['token'], $passwordTemporal),
        ]);
    }

    if ($envio['ok']) {
        // Un reenvío no borra el «revisado»: si ya lo había abierto, sigue revisado
        $pdo->prepare("
            UPDATE avisos_privacidad
               SET estado = IF(estado = 'revisado', 'revisado', 'enviado'), fecha_envio = NOW(), intentos = intentos + 1,
                   ultimo_error = NULL, id_mensaje = ?, version_aviso = ?
             WHERE id_usuario = ?")
            ->execute([mb_substr((string)($envio['id'] ?? ''), 0, 150), AVISO_VERSION, $idUsuario]);
        $mensaje = 'Aviso de privacidad enviado a ' . $empleado['correo'] . '.';
    } else {
        $pdo->prepare("UPDATE avisos_privacidad SET intentos = intentos + 1, ultimo_error = ? WHERE id_usuario = ?")
            ->execute([mb_substr((string)$envio['message'], 0, 255), $idUsuario]);
        $mensaje = 'No se pudo enviar el aviso de privacidad: ' . $envio['message'];
    }
    return ['ok' => (bool)$envio['ok'], 'mensaje' => $mensaje, 'aviso' => avisoFila($pdo, $idUsuario)];
}

// Marca como revisado el aviso del token (abrió el correo o el enlace). Regresa el empleado o null si el token no existe
function avisoMarcarRevisado(PDO $pdo, string $token): ?array {
    if (!preg_match('/^[a-f0-9]{64}$/', $token) || !avisosTablaLista($pdo)) return null;
    $stmt = $pdo->prepare("SELECT id_usuario FROM avisos_privacidad WHERE token = ?");
    $stmt->execute([$token]);
    $idUsuario = $stmt->fetchColumn();
    if ($idUsuario === false) return null;
    $pdo->prepare("UPDATE avisos_privacidad SET estado = 'revisado', fecha_revision = COALESCE(fecha_revision, NOW()) WHERE token = ?")
        ->execute([$token]);
    return avisoEmpleado($pdo, (int)$idUsuario);
}

// Clave del rol que usa el panel de administrador
function avisoClaveRol(string $rol): string {
    return match ($rol) {
        'Administrador General', 'Admin_General' => 'admin',
        'Gerente' => 'gerente',
        'Cajero' => 'cajero',
        default => strtolower($rol),
    };
}

// Fila del panel para un empleado
function avisoFila(PDO $pdo, int $idUsuario): ?array {
    $filas = avisosListar($pdo, $idUsuario);
    return $filas[0] ?? null;
}

// Lista de empleados con el estado de su aviso (los que nunca lo han recibido aparecen como «pendiente»)
function avisosListar(PDO $pdo, ?int $idUsuario = null): array {
    $tabla = avisosTablaLista($pdo);
    $conCambio = avisosColumnaUsuarios($pdo, 'debe_cambiar_password');
    $sql = "
        SELECT u.id_usuario, u.nombre, u.apellidos, u.correo, u.estado AS estado_usuario, u.id_sucursal, r.nombre_rol,
               s.nombre AS sucursal, " . ($conCambio ? "u.debe_cambiar_password" : "0") . " AS debe_cambiar_password, " .
        ($tabla
            ? "COALESCE(a.estado, 'pendiente') AS estado_aviso, a.intentos, a.ultimo_error,
               DATE_FORMAT(a.fecha_envio, '%Y-%m-%dT%H:%i:%s') AS fecha_envio,
               DATE_FORMAT(a.fecha_revision, '%Y-%m-%dT%H:%i:%s') AS fecha_revision"
            : "'pendiente' AS estado_aviso, 0 AS intentos, NULL AS ultimo_error, NULL AS fecha_envio, NULL AS fecha_revision") . "
        FROM usuarios u
        JOIN roles r ON r.id_rol = u.id_rol
        LEFT JOIN sucursales s ON s.id_sucursal = u.id_sucursal" .
        ($tabla ? " LEFT JOIN avisos_privacidad a ON a.id_usuario = u.id_usuario" : "") .
        ($idUsuario !== null ? " WHERE u.id_usuario = ?" : "") . "
        ORDER BY FIELD(COALESCE(" . ($tabla ? "a.estado" : "'pendiente'") . ", 'pendiente'), 'pendiente', 'enviado', 'revisado'), u.nombre";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($idUsuario !== null ? [$idUsuario] : []);
    return array_map(fn($r) => [
        'id' => (string)$r['id_usuario'],
        'nombre' => trim($r['nombre'] . ' ' . ($r['apellidos'] ?? '')),
        'correo' => $r['correo'],
        'rol' => avisoClaveRol((string)$r['nombre_rol']),
        'sucursalId' => $r['id_sucursal'] !== null ? (string)$r['id_sucursal'] : null,
        'sucursal' => $r['sucursal'],
        'estadoUsuario' => $r['estado_usuario'],
        'estado' => $r['estado_aviso'],
        'intentos' => (int)$r['intentos'],
        'error' => $r['ultimo_error'],
        'fechaEnvio' => $r['fecha_envio'],
        'fechaRevision' => $r['fecha_revision'],
        'debeCambiarPassword' => (bool)$r['debe_cambiar_password'],
    ], $stmt->fetchAll(PDO::FETCH_ASSOC));
}

// Contraseña temporal aleatoria y legible (sin 0/O ni 1/l/I para que no se confundan al teclearla)
function avisoPasswordTemporal(int $largo = 12): string {
    $letras = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    $simbolos = '#$%*+-?';
    $clave = '';
    for ($i = 0; $i < $largo - 2; $i++) $clave .= $letras[random_int(0, strlen($letras) - 1)];
    $clave .= $simbolos[random_int(0, strlen($simbolos) - 1)] . random_int(2, 9);
    return str_shuffle($clave);
}
