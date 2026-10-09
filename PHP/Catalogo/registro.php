<?php
declare(strict_types=1);
/* KARMA · Catálogo — registro de clientes: crea el cliente en la tabla `clientes` existente (contraseña con hash) */
require_once __DIR__ . '/includes/layout.php';

$volver = catVolverSeguro($_GET['volver'] ?? null);
if (catClienteActual()) { header('Location: ' . $volver); exit; }
$sucursal = catSucursalActual();
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
        <label class="casilla"><input type="checkbox" name="acepta_privacidad" required> <span>He leído y acepto el <a class="enlace" href="privacidad.php" target="_blank">aviso de privacidad</a> y los <a class="enlace" href="terminos.php" target="_blank">términos y condiciones</a>.</span></label>
        <div class="mensaje-form" id="rgMensaje" role="alert"></div>
        <button class="btn btn--primario btn--grande btn--bloque" type="submit">Crear mi cuenta</button>
      </form>
      <div class="acceso-pie"><span>¿Ya tienes cuenta? <a class="enlace" href="login.php<?= $volver !== 'perfil.php' ? '?volver=' . rawurlencode($volver) : '' ?>">Inicia sesión</a></span></div>
    </div>
  </div>
</section>
<?php catPie(['scripts' => ['cuenta.js']]); ?>
