<?php
declare(strict_types=1);
/* KARMA · Catálogo — perfil del cliente: datos, pedidos, citas, vehículos de interés, historial y notificaciones */
require_once __DIR__ . '/includes/layout.php';

$c = catRequerirCliente();
$iniciales = mb_strtoupper(mb_substr((string)($c['nombres'] ?: $c['nombre']), 0, 1) . mb_substr((string)($c['apellidos'] ?? ''), 0, 1));
$entidades = ['Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche', 'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila',
    'Colima', 'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León',
    'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'];
catCabecera(['titulo' => 'Mi perfil', 'activo' => '']);
?>
<div class="contenedor">
  <div class="perfil-cabeza">
    <span class="avatar avatar--grande" translate="no"><?= e($iniciales) ?></span>
    <div>
      <span class="mayus texto-3">Mi cuenta KARMA</span>
      <h1>Hola, <?= e(catNombreCorto($c)) ?></h1>
      <p class="texto-2"><?= e($c['email']) ?> · Cliente desde <?= e(catFecha($c['fecha_registro'], false)) ?></p>
    </div>
    <div class="derecha">
      <a class="btn btn--secundario" href="agendar.php"><?= icono('calendario') ?> Agendar cita</a>
      <button class="btn btn--fantasma" type="button" data-cerrar-sesion><?= icono('salir') ?> Cerrar sesión</button>
    </div>
  </div>
  <div class="estadisticas" id="estadisticas">
    <div class="estadistica"><strong data-est="pedidos">—</strong><span>Pedidos en línea</span></div>
    <div class="estadistica"><strong data-est="citas">—</strong><span>Próximas citas</span></div>
    <div class="estadistica"><strong data-est="favoritos">—</strong><span>Vehículos de interés</span></div>
    <div class="estadistica"><strong data-est="notificaciones">—</strong><span>Notificaciones nuevas</span></div>
  </div>

  <div class="perfil-cuerpo">
    <nav class="pestanas-perfil" aria-label="Secciones de mi cuenta" role="tablist">
      <button class="pestana activa" type="button" data-pestana="resumen"><?= icono('estrella') ?> Resumen</button>
      <button class="pestana" type="button" data-pestana="datos"><?= icono('usuario') ?> Mis datos</button>
      <button class="pestana" type="button" data-pestana="pedidos"><?= icono('carrito') ?> Pedidos</button>
      <button class="pestana" type="button" data-pestana="citas"><?= icono('calendario') ?> Citas</button>
      <button class="pestana" type="button" data-pestana="favoritos"><?= icono('corazon') ?> Vehículos de interés</button>
      <button class="pestana" type="button" data-pestana="historial"><?= icono('historial') ?> Historial</button>
      <button class="pestana" type="button" data-pestana="solicitudes"><?= icono('mensaje') ?> Solicitudes</button>
      <button class="pestana" type="button" data-pestana="notificaciones"><?= icono('campana') ?> Notificaciones <span class="contador-pestana oculto" id="contadorNotif"></span></button>
      <button class="pestana" type="button" data-pestana="seguridad"><?= icono('candado') ?> Seguridad</button>
    </nav>

    <div>
      <section class="panel-perfil activo" id="panel-resumen"><h2>Resumen</h2><p class="texto-2">Lo más reciente de tu cuenta.</p><div id="resumenPerfil"><div class="esqueleto" style="height:160px"></div></div></section>

      <section class="panel-perfil" id="panel-datos">
        <h2>Mis datos</h2><p class="texto-2">Mantén tu información actualizada para agilizar pedidos y citas.</p>
        <form class="tarjeta-formulario formulario" id="formDatos" novalidate>
          <div class="campos">
            <div class="campo"><label for="pfNombres">Nombre(s)</label><input id="pfNombres" name="nombres" required maxlength="80" value="<?= e($c['nombres'] ?? '') ?>"></div>
            <div class="campo"><label for="pfApellidos">Apellidos</label><input id="pfApellidos" name="apellidos" required maxlength="100" value="<?= e($c['apellidos'] ?? '') ?>"></div>
            <div class="campo"><label for="pfEmail">Correo electrónico</label><input id="pfEmail" name="email" type="email" required maxlength="120" value="<?= e($c['email']) ?>"></div>
            <div class="campo"><label for="pfCelular">Celular</label><input id="pfCelular" name="celular" type="tel" required maxlength="20" value="<?= e($c['celular'] ?? '') ?>"></div>
            <div class="campo ancho oculto" id="campoPassEmail"><label for="pfPassActual">Contraseña actual <span class="opcional">(necesaria para cambiar tu correo)</span></label><input id="pfPassActual" name="password_actual" type="password" maxlength="72" autocomplete="current-password"></div>
            <div class="campo ancho"><label for="pfDireccion">Dirección</label><input id="pfDireccion" name="direccion" maxlength="255" value="<?= e($c['direccion'] ?? '') ?>"></div>
            <div class="campo"><label for="pfCiudad">Ciudad</label><input id="pfCiudad" name="ciudad" maxlength="100" value="<?= e($c['ciudad'] ?? '') ?>"></div>
            <div class="campo"><label for="pfCp">Código postal</label><input id="pfCp" name="codigo_postal" maxlength="5" inputmode="numeric" value="<?= e($c['codigo_postal'] ?? '') ?>"></div>
            <div class="campo"><label for="pfEntidad">Estado</label><select id="pfEntidad" name="entidad_federativa"><option value="">Elige un estado</option><?php foreach ($entidades as $en): ?><option <?= ($c['entidad_federativa'] ?? '') === $en ? 'selected' : '' ?>><?= e($en) ?></option><?php endforeach; ?></select></div>
            <div class="campo"><label for="pfSucursal">Sucursal preferida</label><select id="pfSucursal" name="id_sucursal_preferida"><option value="">Sin preferencia</option><?php foreach (catSucursales() as $s): ?><option value="<?= $s['id_sucursal'] ?>" <?= (int)$c['id_sucursal_preferida'] === $s['id_sucursal'] ? 'selected' : '' ?>><?= e($s['nombre']) ?></option><?php endforeach; ?></select></div>
            <div class="campo"><label for="pfMarca">Marca de interés</label><select id="pfMarca" name="marca_interes"><option value="">Sin preferencia</option><?php foreach (CAT_MARCAS as $m): ?><option <?= ($c['marca_interes'] ?? '') === $m ? 'selected' : '' ?>><?= e($m) ?></option><?php endforeach; ?></select></div>
          </div>
          <fieldset style="border:0; padding:0; margin:6px 0 0;">
            <legend class="etiqueta-campo" style="margin-bottom:10px;">Preferencias de notificaciones</legend>
            <div class="pila">
              <label class="interruptor"><span>Avisos de pedidos y citas por correo</span><input type="checkbox" name="notif_email" <?= $c['notif_email'] ? 'checked' : '' ?>><span class="pista"></span></label>
              <label class="interruptor"><span>Recordatorios por SMS</span><input type="checkbox" name="notif_sms" <?= $c['notif_sms'] ? 'checked' : '' ?>><span class="pista"></span></label>
              <label class="interruptor"><span>Novedades de KARMA</span><input type="checkbox" name="notif_promociones" <?= $c['notif_promociones'] ? 'checked' : '' ?>><span class="pista"></span></label>
            </div>
          </fieldset>
          <div class="mensaje-form" id="pfMensaje" role="alert"></div>
          <div><button class="btn btn--primario" type="submit">Guardar cambios</button></div>
        </form>
      </section>

      <section class="panel-perfil" id="panel-pedidos"><h2>Mis pedidos</h2><p class="texto-2">Refacciones y accesorios comprados en línea.</p><div id="listaPedidos"></div></section>
      <section class="panel-perfil" id="panel-citas"><h2>Mis citas</h2><p class="texto-2">Visitas, pruebas de manejo, apartados y servicios agendados.</p><div id="listaCitas"></div></section>
      <section class="panel-perfil" id="panel-favoritos"><h2>Vehículos de interés</h2><p class="texto-2">Los modelos que guardaste con el corazón.</p><div class="rejilla" id="listaFavoritos"></div></section>
      <section class="panel-perfil" id="panel-historial"><h2>Historial</h2><p class="texto-2">Compras en sucursal, garantías y crédito registrados en KARMA.</p><div id="listaHistorial"></div></section>
      <section class="panel-perfil" id="panel-solicitudes"><h2>Solicitudes</h2><p class="texto-2">Información, cotizaciones y mensajes que nos enviaste.</p><div id="listaSolicitudes"></div></section>
      <section class="panel-perfil" id="panel-notificaciones"><div class="fila fila--entre"><h2>Notificaciones</h2><button class="btn btn--fantasma btn--chico" type="button" id="marcarLeidas">Marcar todas como leídas</button></div><div id="listaNotificaciones"></div></section>

      <section class="panel-perfil" id="panel-seguridad">
        <h2>Seguridad</h2><p class="texto-2">Cambia tu contraseña. Se guarda cifrada (hash), nadie en KARMA puede verla.</p>
        <form class="tarjeta-formulario formulario" id="formPassword" novalidate style="max-width:520px;">
          <div class="campo"><label for="psActual">Contraseña actual</label><input id="psActual" name="actual" type="password" required autocomplete="current-password" maxlength="72"></div>
          <div class="campo"><label for="psNueva">Nueva contraseña</label><input id="psNueva" name="nueva" type="password" required minlength="8" maxlength="72" autocomplete="new-password"><span class="ayuda">Mínimo 8 caracteres con letras y números.</span></div>
          <div class="campo"><label for="psConfirm">Confirmar nueva contraseña</label><input id="psConfirm" name="confirmacion" type="password" required maxlength="72" autocomplete="new-password"></div>
          <div class="mensaje-form" id="psMensaje" role="alert"></div>
          <div><button class="btn btn--primario" type="submit">Actualizar contraseña</button></div>
        </form>
      </section>
    </div>
  </div>
</div>
<script type="application/json" id="datosPerfil"><?= json_encode(['email' => $c['email']], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG) ?></script>
<?php catPie(['scripts' => ['cuenta.js']]); ?>
