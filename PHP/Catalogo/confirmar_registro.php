<?php
declare(strict_types=1);
/* KARMA · Catálogo — página a la que lleva el botón del correo de registro.
   GET  = solo muestra qué documentos se aceptarán. Abrir el enlace NO acepta nada (los escáneres de seguridad
          del correo también abren los enlaces).
   POST = acciones explícitas de la persona: aceptar, no aceptar o pedir un correo nuevo (con token CSRF de la sesión).
   La lógica está en includes/registro_cuenta.php. */
require_once __DIR__ . '/includes/layout.php';
require_once __DIR__ . '/includes/registro_cuenta.php';

header('Referrer-Policy: no-referrer');
header('X-Robots-Tag: noindex, nofollow');
header('Cache-Control: no-store');

$metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Fuera del entorno local la confirmación solo funciona con HTTPS
if (!catRegistroConexionSegura()) {
    try {
        $destino = catRegistroUrlCatalogo() . 'confirmar_registro.php' . (empty($_SERVER['QUERY_STRING']) ? '' : '?' . $_SERVER['QUERY_STRING']);
    } catch (Throwable $e) {
        $destino = null;
    }
    if ($metodo === 'GET' && $destino && str_starts_with($destino, 'https://')) {
        header('Location: ' . $destino, true, 301);
        exit;
    }
    http_response_code(403);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'La confirmación del registro requiere una conexión segura (HTTPS).';
    exit;
}

// Límite simple por sesión para los formularios de reenvío de esta página
function confirmarLimite(string $clave, int $maximo, int $segundos): bool {
    $ahora = time();
    $marcas = array_filter($_SESSION['limites'][$clave] ?? [], fn($t) => $ahora - $t < $segundos);
    if (count($marcas) >= $maximo) return false;
    $marcas[] = $ahora;
    $_SESSION['limites'][$clave] = array_values($marcas);
    return true;
}

$token = trim((string)($metodo === 'POST' ? ($_POST['token'] ?? '') : ($_GET['token'] ?? '')));
$vista = null;      // pantalla a mostrar
$mensaje = '';      // detalle opcional de la pantalla
$fila = null;       // solicitud del token (solo para la pantalla de confirmación)
$expirada = false;  // la página estuvo abierta tanto tiempo que su token CSRF ya no coincide

if ($metodo === 'POST') {
    if (!hash_equals(catCsrf(), (string)($_POST['csrf'] ?? ''))) {
        $expirada = true;
    } else {
        try {
            switch ((string)($_POST['accion'] ?? '')) {
                case 'aceptar':
                    $r = catRegistroConfirmar($token, (int)($_POST['id_aviso'] ?? 0), (int)($_POST['id_terminos'] ?? 0),
                        catRegistroIp(), (string)($_SERVER['HTTP_USER_AGENT'] ?? ''));
                    // Cuenta creada: se inicia sesión en este navegador y se regresa al catálogo con el mensaje de éxito
                    session_regenerate_id(true);
                    $_SESSION['cliente_id'] = $r['id_cliente'];
                    unset($_SESSION['cat_login']);
                    if ($r['id_sucursal']) {
                        try { catEstablecerSucursal($r['id_sucursal']); } catch (Throwable $e) { /* la sucursal pudo desactivarse */ }
                    }
                    $_SESSION['cat_aviso'] = '¡Registro completado! Aceptaste el Aviso de Privacidad y los Términos y Condiciones y tu cuenta KARMA ya está activa.';
                    header('Location: index.php', true, 303);
                    exit;
                case 'rechazar':
                    catRegistroRechazar($token);
                    $vista = 'rechazado';
                    break;
                case 'reenviar':
                    // Los documentos cambiaron después del envío: correo nuevo con la versión vigente (y token nuevo)
                    [$estadoToken, $filaToken] = catRegistroEstadoToken($token);
                    if ($estadoToken !== 'documentos') break;
                    catRegistroReenviar((int)$filaToken['id_registro']);
                    $vista = 'reenviado';
                    break;
                case 'reenviar_correo':
                    // Enlace inválido: la persona escribe su correo. La respuesta es la misma haya o no una solicitud.
                    $email = mb_strtolower(trim((string)($_POST['email'] ?? '')));
                    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 120) {
                        $vista = 'invalido';
                        $mensaje = 'Escribe un correo electrónico válido.';
                        break;
                    }
                    if (confirmarLimite('confirmar_reenvio', 5, 600)) catRegistroReenviarPorCorreo($email);
                    $vista = 'reenvio_generico';
                    break;
            }
        } catch (CatRegistroLimite $e) {
            $vista = 'limite';
            $mensaje = $e->getMessage();
        } catch (CatRegistroError $e) {
            $vista = $e->codigo;
            $mensaje = $e->codigo === 'envio' ? $e->getMessage() : '';
        } catch (Throwable $e) {
            error_log('[Catalogo confirmar_registro] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
            $vista = 'error';
        }
    }
}

// Sin acción (GET, CSRF vencido o acción sin resultado): se muestra el estado actual del enlace, sin cambiar nada
if ($vista === null) {
    try {
        [$estadoToken, $fila] = catRegistroEstadoToken($token);
        $vista = $estadoToken === 'vigente' ? 'confirmar' : $estadoToken;
    } catch (Throwable $e) {
        error_log('[Catalogo confirmar_registro] ' . $e->getMessage());
        $vista = 'error';
    }
}

$cliente = catClienteActual();
$docs = catLegalDocumentos();
catCabecera(['titulo' => 'Confirmar registro', 'activo' => '',
    'head' => '<meta name="referrer" content="no-referrer"><meta name="robots" content="noindex, nofollow">']);

// Pantallas informativas: [icono, clase, título, texto, acciones]
$registro = '<a class="btn btn--primario" href="registro.php">Volver a registrarme</a>';
$login = $cliente ? '<a class="btn btn--primario" href="perfil.php">Ir a mi perfil</a>' : '<a class="btn btn--primario" href="login.php">Iniciar sesión</a>';
$pantallas = [
    'usado' => ['check-circulo', 'ok', 'Este enlace ya se utilizó',
        'Tu registro ya fue confirmado y tu cuenta está activa. Por seguridad, cada enlace de confirmación funciona una sola vez.', $login],
    'vencido' => ['reloj', 'aviso', 'El enlace venció',
        'Por tu seguridad, el enlace de confirmación dura ' . CAT_REGISTRO_VIGENCIA_HORAS . ' horas. Como no se confirmó a tiempo, no se creó ninguna cuenta y los datos de esa solicitud se eliminaron. Llena de nuevo el formulario para recibir un correo nuevo.', $registro],
    'cancelado' => ['info', 'aviso', 'Esta solicitud fue cancelada',
        'No se creó ninguna cuenta con esta solicitud y sus datos se eliminaron. Si quieres crear tu cuenta, regístrate de nuevo.', $registro],
    'rechazado' => ['check-circulo', 'ok', 'Cancelamos tu solicitud',
        'No aceptaste los documentos, así que no se creó ninguna cuenta y eliminamos los datos que nos diste. Si cambias de opinión, puedes registrarte de nuevo cuando quieras.',
        '<a class="btn btn--secundario" href="index.php">Ir al catálogo</a>'],
    'reenviado' => ['correo', 'ok', 'Te enviamos un correo nuevo',
        'Incluye el PDF con la versión vigente del Aviso de Privacidad y de los Términos y Condiciones. Usa el botón de ese mensaje: este enlace ya no funciona.',
        '<a class="btn btn--secundario" href="index.php">Ir al catálogo</a>'],
    'reenvio_generico' => ['correo', 'ok', 'Revisa tu correo',
        'Si hay una solicitud de registro vigente para esa dirección, te enviamos un correo nuevo con el enlace de confirmación (revisa también spam y promociones). Si tu solicitud venció, vuelve a registrarte.', $registro],
    'existente' => ['usuario', 'aviso', 'Ya existe una cuenta con este correo',
        'No creamos una cuenta nueva y cancelamos esta solicitud. Inicia sesión con tu cuenta existente; si olvidaste tu contraseña, acude a tu sucursal o escríbenos desde Contacto.', $login],
    'inactiva' => ['alerta', 'error', 'No podemos activar la cuenta en línea',
        'Este correo pertenece a un registro de cliente inactivo, así que cancelamos la solicitud. Acude a cualquiera de nuestras sucursales para reactivarlo.',
        '<a class="btn btn--primario" href="sucursales.php">Ver sucursales</a>'],
    'limite' => ['reloj', 'aviso', 'Espera un momento', $mensaje, '<a class="btn btn--secundario" href="index.php">Ir al catálogo</a>'],
    'envio' => ['alerta', 'error', 'No pudimos enviar el correo', $mensaje ?: 'Inténtalo de nuevo en unos minutos.', '<a class="btn btn--secundario" href="index.php">Ir al catálogo</a>'],
    'error' => ['alerta', 'error', 'Ocurrió un error inesperado',
        'No se aceptó ningún documento ni se creó ninguna cuenta. Vuelve a abrir el enlace del correo e inténtalo de nuevo en unos minutos.',
        '<a class="btn btn--secundario" href="index.php">Ir al catálogo</a>'],
];
?>
<section class="cabecera-pagina"><div class="contenedor">
  <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Confirmar registro</li></ol>
  <h1>Confirma tu registro</h1>
  <p>Último paso para crear tu cuenta en el catálogo en línea de KARMA.</p>
</div></section>

<section class="seccion--compacta"><div class="contenedor contenedor--angosto">
<?php if ($vista === 'confirmar'): ?>
  <div class="confirmacion-caja">
    <?php if ($expirada): ?>
      <div class="mensaje-form mensaje-form--info"><?= icono('info') ?><span>La página estuvo abierta mucho tiempo. Revisa la información y vuelve a pulsar el botón para confirmar.</span></div>
    <?php endif; ?>
    <p class="texto-2">Revisa los datos de tu solicitud y los documentos. Tu cuenta se creará <strong>solo</strong> si pulsas el botón de aceptación.</p>

    <dl class="datos-solicitud">
      <div><dt>Nombre</dt><dd><?= e(trim($fila['nombres'] . ' ' . $fila['apellidos'])) ?></dd></div>
      <div><dt>Correo</dt><dd translate="no"><?= e($fila['email']) ?></dd></div>
      <div><dt>Folio de solicitud</dt><dd translate="no"><?= e(catRegistroFolio((int)$fila['id_registro'])) ?></dd></div>
      <div><dt>Enlace vigente hasta</dt><dd><?= e(catFecha((string)$fila['fecha_expiracion'])) ?></dd></div>
    </dl>

    <h2 class="titulo-confirmacion">Documentos que vas a aceptar</h2>
    <div class="documentos-aceptar">
      <?php foreach ($docs as $doc): ?>
        <div class="documento-aceptar">
          <?= icono('documento', 'icono icono-doc') ?>
          <div>
            <strong><?= e($doc['titulo']) ?></strong>
            <span>Versión <?= e($doc['version']) ?> · vigente desde el <?= e(catLegalFecha($doc['vigencia'])) ?></span>
            <span class="huella" translate="no">Huella <?= e(catLegalHuella($doc)) ?></span>
          </div>
          <a class="enlace" href="<?= e($doc['pagina']) ?>" target="_blank" rel="noopener">Leer</a>
        </div>
      <?php endforeach; ?>
    </div>
    <p class="texto-3" style="font-size:13.5px">Son los mismos documentos del PDF adjunto al correo. También puedes <a class="enlace" href="documentos_legales.php" target="_blank" rel="noopener">descargar el PDF</a>.</p>

    <div class="al-aceptar">
      <strong>Al pulsar el botón:</strong>
      <ul class="lista-check">
        <li>Otorgas tu consentimiento expreso al Aviso de Privacidad, incluido el tratamiento de datos financieros y patrimoniales, y aceptas los Términos y Condiciones, en las versiones indicadas.</li>
        <li>Registramos la fecha, la hora, tu dirección IP y tu navegador como constancia de aceptación.</li>
        <li>Se crea tu cuenta, se inicia tu sesión y este enlace deja de funcionar.</li>
      </ul>
    </div>

    <form method="post" action="confirmar_registro.php" class="formulario-aceptar">
      <input type="hidden" name="csrf" value="<?= e(catCsrf()) ?>">
      <input type="hidden" name="token" value="<?= e($token) ?>">
      <input type="hidden" name="id_aviso" value="<?= (int)$fila['id_aviso'] ?>">
      <input type="hidden" name="id_terminos" value="<?= (int)$fila['id_terminos'] ?>">
      <button class="btn btn--primario btn--grande btn--bloque boton-aceptar" type="submit" name="accion" value="aceptar"><?= icono('check-circulo') ?> <?= e(CAT_REGISTRO_BOTON) ?></button>
    </form>
    <form method="post" action="confirmar_registro.php" class="formulario-rechazar">
      <input type="hidden" name="csrf" value="<?= e(catCsrf()) ?>">
      <input type="hidden" name="token" value="<?= e($token) ?>">
      <button class="btn btn--fantasma btn--bloque" type="submit" name="accion" value="rechazar">No acepto: cancelar mi solicitud y borrar mis datos</button>
    </form>
    <p class="texto-3" style="font-size:13px; text-align:center">Si no haces nada, tu cuenta no se creará y la solicitud se eliminará al vencer el enlace.</p>
  </div>

<?php elseif ($vista === 'documentos'): ?>
  <div class="confirmacion-caja confirmacion-estado">
    <span class="icono-estado icono-estado--aviso"><?= icono('documento', 'icono-grande') ?></span>
    <h2>Los documentos se actualizaron</h2>
    <p>Después de enviarte el correo publicamos una nueva versión del Aviso de Privacidad o de los Términos y Condiciones. Para que aceptes exactamente lo que recibes, te enviaremos un correo nuevo con el PDF vigente. Este enlace ya no puede usarse para aceptar.</p>
    <form method="post" action="confirmar_registro.php">
      <input type="hidden" name="csrf" value="<?= e(catCsrf()) ?>">
      <input type="hidden" name="token" value="<?= e($token) ?>">
      <button class="btn btn--primario" type="submit" name="accion" value="reenviar"><?= icono('correo') ?> Enviarme el correo actualizado</button>
    </form>
  </div>

<?php elseif ($vista === 'invalido'): ?>
  <div class="confirmacion-caja confirmacion-estado">
    <span class="icono-estado icono-estado--error"><?= icono('alerta', 'icono-grande') ?></span>
    <h2>Este enlace no es válido</h2>
    <p>Puede que esté incompleto o que ya hayas pedido un correo más reciente: cada correo nuevo reemplaza al anterior. No se aceptó nada ni se creó ninguna cuenta.</p>
    <form method="post" action="confirmar_registro.php" class="formulario formulario-reenvio" novalidate>
      <input type="hidden" name="csrf" value="<?= e(catCsrf()) ?>">
      <input type="hidden" name="accion" value="reenviar_correo">
      <div class="campo"><label for="cfEmail">¿Necesitas un correo nuevo? Escribe el correo con el que te registraste</label>
        <input id="cfEmail" name="email" type="email" required maxlength="120" autocomplete="email" inputmode="email"></div>
      <?php if ($mensaje !== ''): ?><div class="mensaje-form mensaje-form--error"><?= icono('alerta') ?><span><?= e($mensaje) ?></span></div><?php endif; ?>
      <div class="fila fila--envolver">
        <button class="btn btn--primario" type="submit"><?= icono('correo') ?> Enviar correo nuevo</button>
        <a class="btn btn--fantasma" href="registro.php">Volver a registrarme</a>
      </div>
    </form>
  </div>

<?php else: [$ic, $clase, $titulo, $texto, $acciones] = $pantallas[$vista] ?? $pantallas['error']; ?>
  <div class="confirmacion-caja confirmacion-estado">
    <span class="icono-estado icono-estado--<?= e($clase) ?>"><?= icono($ic, 'icono-grande') ?></span>
    <h2><?= e($titulo) ?></h2>
    <p><?= e($texto) ?></p>
    <div class="fila fila--envolver" style="justify-content:center"><?= $acciones ?></div>
  </div>
<?php endif; ?>
</div></section>
<?php catPie(); ?>
