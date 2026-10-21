<?php
declare(strict_types=1);
/* KARMA · Catálogo — registro de clientes en dos pasos:
   1. Este formulario crea una SOLICITUD y envía al correo el Aviso de Privacidad y los Términos en PDF (api.php?action=registro).
   2. La cuenta (tabla `clientes`, contraseña con hash) se crea solo cuando la persona acepta desde el botón del correo
      (confirmar_registro.php). Mientras tanto esta página muestra «Revisa tu correo» y consulta si ya confirmó. */
require_once __DIR__ . '/includes/layout.php';
require_once __DIR__ . '/includes/legal.php';

$volver = catVolverSeguro($_GET['volver'] ?? null);
if (catClienteActual()) { header('Location: ' . $volver); exit; }
$sucursal = catSucursalActual();

// Si esta sesión ya envió una solicitud vigente, se muestra directamente la pantalla de espera
$espera = null;
$pendiente = $_SESSION['registro_pendiente'] ?? null;
if (is_array($pendiente) && !empty($pendiente['id'])) {
    $stmt = db()->prepare("SELECT fecha_expiracion FROM registros_pendientes
                            WHERE id_registro = ? AND estado IN ('pendiente', 'aviso_cuenta') AND fecha_expiracion > NOW()");
    $stmt->execute([(int)$pendiente['id']]);
    $vence = $stmt->fetchColumn();
    if ($vence !== false) $espera = ['email' => (string)$pendiente['email'], 'vence' => catFecha((string)$vence)];
}
$docs = catLegalDocumentos();
catCabecera(['titulo' => 'Crear cuenta', 'activo' => '']);
$entidades = ['Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche', 'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila',
    'Colima', 'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León',
    'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'];
?>
<section class="acceso">
  <div class="acceso-media">
    <img src="<?= catAsset('assets/Catalogo/banners/hero-ducati.webp') ?>" alt="" width="1920" height="960">
    <div class="texto">
      <span class="mayus" style="color:rgba(255,255,255,.75)">Crea tu cuenta</span>
      <h2>Empieza tu experiencia KARMA</h2>
      <ul class="lista-check">
        <li>Compra refacciones y accesorios en línea</li>
        <li>Agenda citas en Manzanillo o Colima</li>
        <li>Simula tu crédito y aparta tu vehículo</li>
      </ul>
    </div>
  </div>
  <div class="acceso-panel">
    <div class="acceso-caja" style="max-width:560px;">

      <!-- PASO 1: formulario (crea la solicitud y envía el correo) -->
      <div id="rgPasoFormulario"<?= $espera ? ' class="oculto"' : '' ?>>
        <h1>Crear cuenta</h1>
        <p>Solo te pediremos lo necesario. Tus datos se guardan de forma segura.</p>
        <form class="formulario" id="formRegistro" novalidate data-volver="<?= e($volver) ?>">
          <div class="campos">
            <div class="campo"><label for="rgNombres">Nombre(s)</label><input id="rgNombres" name="nombres" required maxlength="80" autocomplete="given-name"></div>
            <div class="campo"><label for="rgApellidos">Apellidos</label><input id="rgApellidos" name="apellidos" required maxlength="100" autocomplete="family-name"></div>
            <div class="campo"><label for="rgEmail">Correo electrónico</label><input id="rgEmail" name="email" type="email" required maxlength="120" autocomplete="email"></div>
            <div class="campo"><label for="rgCelular">Celular (10 dígitos)</label><input id="rgCelular" name="celular" type="tel" required maxlength="20" autocomplete="tel" inputmode="tel"></div>
            <div class="campo">
              <label for="rgPass">Contraseña</label>
              <div class="entrada-con-boton"><input id="rgPass" name="password" type="password" required minlength="8" maxlength="72" autocomplete="new-password"><button class="btn-icono" type="button" data-ver-password="rgPass" aria-label="Mostrar contraseña"><?= icono('ojo') ?></button></div>
              <div class="medidor-fuerza" aria-hidden="true"><span id="rgFuerza"></span></div>
              <span class="ayuda" id="rgFuerzaTexto">Mínimo 8 caracteres con letras y números.</span>
            </div>
            <div class="campo"><label for="rgConfirm">Confirmar contraseña</label><input id="rgConfirm" name="confirmacion" type="password" required maxlength="72" autocomplete="new-password"></div>
            <div class="campo"><label for="rgSucursal">Sucursal preferida</label>
              <select id="rgSucursal" name="id_sucursal_preferida"><?php foreach (catSucursales() as $s): ?><option value="<?= $s['id_sucursal'] ?>" <?= $s['id_sucursal'] === $sucursal['id_sucursal'] ? 'selected' : '' ?>><?= e($s['nombre']) ?></option><?php endforeach; ?></select></div>
            <div class="campo"><label for="rgMarca">Marca de interés <span class="opcional">(opcional)</span></label>
              <select id="rgMarca" name="marca_interes"><option value="">Sin preferencia</option><?php foreach (CAT_MARCAS as $m): ?><option><?= e($m) ?></option><?php endforeach; ?></select></div>
          </div>
          <details>
            <summary class="enlace" style="cursor:pointer;">Agregar dirección (opcional, agiliza tus envíos)</summary>
            <div class="campos" style="margin-top:14px;">
              <div class="campo ancho"><label for="rgDireccion">Calle, número y colonia</label><input id="rgDireccion" name="direccion" maxlength="255" autocomplete="street-address"></div>
              <div class="campo"><label for="rgCiudad">Ciudad</label><input id="rgCiudad" name="ciudad" maxlength="100" autocomplete="address-level2"></div>
              <div class="campo"><label for="rgCp">Código postal</label><input id="rgCp" name="codigo_postal" maxlength="5" inputmode="numeric" autocomplete="postal-code"></div>
              <div class="campo ancho"><label for="rgEntidad">Estado</label><select id="rgEntidad" name="entidad_federativa"><option value="">Elige un estado</option><?php foreach ($entidades as $en): ?><option><?= e($en) ?></option><?php endforeach; ?></select></div>
            </div>
          </details>
          <label class="casilla"><input type="checkbox" name="notif_promociones" value="1"> <span>Deseo recibir promociones y novedades de KARMA <span class="opcional">(opcional; puedes cambiarlo en tu perfil)</span></span></label>
          <div class="aviso-registro">
            <?= icono('correo') ?>
            <div>
              <strong>Confirmarás tu registro desde tu correo</strong>
              <p>Te enviaremos el <a class="enlace" href="privacidad.php" target="_blank" rel="noopener">Aviso de Privacidad</a> (versión <?= e($docs['aviso_privacidad']['version']) ?>) y los <a class="enlace" href="terminos.php" target="_blank" rel="noopener">Términos y Condiciones</a> (versión <?= e($docs['terminos_condiciones']['version']) ?>) en PDF. Tu cuenta se creará solo cuando los aceptes con el botón del correo.</p>
            </div>
          </div>
          <div class="mensaje-form" id="rgMensaje" role="alert"></div>
          <button class="btn btn--primario btn--grande btn--bloque" type="submit">Continuar y recibir el correo</button>
        </form>
        <div class="acceso-pie"><span>¿Ya tienes cuenta? <a class="enlace" href="login.php<?= $volver !== 'perfil.php' ? '?volver=' . rawurlencode($volver) : '' ?>">Inicia sesión</a></span></div>
      </div>

      <!-- PASO 2: esperando la confirmación desde el correo (la cuenta todavía no existe) -->
      <div id="rgPasoEspera" class="registro-espera<?= $espera ? '' : ' oculto' ?>" data-activa="<?= $espera ? '1' : '0' ?>">
        <span class="icono-estado icono-estado--info"><?= icono('correo', 'icono-grande') ?></span>
        <h1>Revisa tu correo</h1>
        <p>Enviamos un mensaje a <strong id="rgEsperaEmail" translate="no"><?= e($espera['email'] ?? '') ?></strong> con el Aviso de Privacidad y los Términos y Condiciones en PDF.</p>
        <ol class="pasos-espera">
          <li>Abre el correo de KARMA. Si no lo ves, revisa las carpetas de spam o promociones.</li>
          <li>Lee los documentos adjuntos.</li>
          <li>Pulsa «<?= e(CAT_BOTON_ACEPTAR) ?>» y confirma en la página que se abre.</li>
        </ol>
        <div class="estado-espera" id="rgEstado" role="status" aria-live="polite"><span class="punto-espera" aria-hidden="true"></span><span id="rgEstadoTexto">Esperando tu confirmación…</span></div>
        <p class="texto-3 nota-espera">El enlace vence el <strong id="rgEsperaVence"><?= e($espera['vence'] ?? '') ?></strong>. Tu cuenta no existe hasta que confirmes; si no aceptas, no se creará y los datos de la solicitud se eliminarán al vencer el enlace.</p>
        <div class="mensaje-form" id="rgEsperaMensaje" role="alert"></div>
        <div class="fila fila--envolver" id="rgEsperaAcciones">
          <button class="btn btn--secundario" type="button" id="rgReenviar"><?= icono('correo') ?> <span>Reenviar correo</span></button>
          <button class="btn btn--fantasma" type="button" id="rgOtroCorreo">Usar otro correo</button>
        </div>
      </div>

    </div>
  </div>
</section>
<?php catPie(['scripts' => ['cuenta.js']]); ?>
