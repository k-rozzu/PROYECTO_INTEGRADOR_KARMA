<?php
declare(strict_types=1);
/* KARMA · Catálogo — Contacto y atención a clientes (las solicitudes se guardan en la tabla solicitudes) */
require_once __DIR__ . '/includes/layout.php';
$cliente = catClienteActual();
$sucursal = catSucursalActual();
$motivos = ['informacion' => 'Información de vehículos', 'cotizacion' => 'Cotización', 'postventa' => 'Postventa y taller',
    'financiamiento' => 'Crédito', 'garantia' => 'Garantía extendida', 'seguro' => 'Seguros', 'queja' => 'Queja',
    'sugerencia' => 'Sugerencia', 'contacto' => 'Refacciones y accesorios', 'otro' => 'Otro motivo'];
$motivoInicial = array_key_exists($_GET['motivo'] ?? '', $motivos) ? $_GET['motivo'] : 'informacion';
catCabecera(['titulo' => 'Contacto', 'activo' => 'contacto']);
?>
<section class="cabecera-pagina">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Contacto</li></ol>
    <h1>Atención a clientes</h1>
    <p>¿Tienes una duda, una queja o una sugerencia? Escríbenos y un asesor de la sucursal que elijas te responderá en menos de 24 horas hábiles.</p>
  </div>
</section>
<section class="seccion--compacta">
  <div class="contenedor dividido dividido--contacto">
    <form class="tarjeta-formulario formulario form-solicitud" data-tipo-campo="motivo" id="formContacto" novalidate>
      <h2>Envíanos un mensaje</h2>
      <div class="campos">
        <div class="campo"><label for="ctMotivo">Motivo</label><select id="ctMotivo" name="motivo"><?php foreach ($motivos as $k => $t): ?><option value="<?= $k ?>" <?= $k === $motivoInicial ? 'selected' : '' ?>><?= e($t) ?></option><?php endforeach; ?></select></div>
        <div class="campo"><label for="ctSucursal">Sucursal</label><select id="ctSucursal" name="id_sucursal"><?php foreach (catSucursales() as $s): ?><option value="<?= $s['id_sucursal'] ?>" <?= $s['id_sucursal'] === $sucursal['id_sucursal'] ? 'selected' : '' ?>><?= e($s['nombre']) ?></option><?php endforeach; ?></select></div>
        <div class="campo ancho"><label for="ctNombre">Nombre completo</label><input id="ctNombre" name="nombre" required maxlength="150" autocomplete="name" value="<?= e($cliente['nombre'] ?? '') ?>"></div>
        <div class="campo"><label for="ctEmail">Correo electrónico</label><input id="ctEmail" name="email" type="email" required maxlength="120" autocomplete="email" value="<?= e($cliente['email'] ?? '') ?>"></div>
        <div class="campo"><label for="ctTel">Teléfono <span class="opcional">(opcional)</span></label><input id="ctTel" name="telefono" type="tel" maxlength="20" autocomplete="tel" value="<?= e($cliente['celular'] ?? '') ?>"></div>
        <div class="campo ancho"><label for="ctAsunto">Asunto</label><input id="ctAsunto" name="asunto" maxlength="150"></div>
        <div class="campo ancho"><label for="ctMensaje">Mensaje</label><textarea id="ctMensaje" name="mensaje" required maxlength="3000"></textarea></div>
      </div>
      <label class="casilla"><input type="checkbox" name="acepto" required> <span>Acepto el <a class="enlace" href="privacidad.php" target="_blank">aviso de privacidad</a>.</span></label>
      <div class="mensaje-form" role="alert"></div>
      <button class="btn btn--primario" type="submit" style="justify-self:start;"><?= icono('mensaje') ?> Enviar mensaje</button>
    </form>
    <div class="pila">
      <?php foreach (catSucursales() as $s): ?>
        <div class="tarjeta-formulario" style="padding:24px;">
          <h3 style="font-size:19px; margin-bottom:12px;" translate="no">KARMA <?= e($s['nombre']) ?></h3>
          <div class="dato-contacto"><?= icono('telefono') ?><div><strong>Teléfono</strong><a href="tel:<?= e($s['telefono']) ?>" translate="no"><?= e(preg_replace('/(\d{3})(\d{3})(\d{4})/', '$1 $2 $3', $s['telefono'])) ?></a></div></div>
          <div class="dato-contacto" style="margin-top:10px;"><?= icono('correo') ?><div><strong>Correo</strong><span translate="no"><?= e($s['email'] ?? '') ?></span></div></div>
          <div class="dato-contacto" style="margin-top:10px;"><?= icono('reloj') ?><div><strong>Horario</strong><?= e($s['horario_ventas'] ?? '') ?></div></div>
          <div class="dato-contacto" style="margin-top:10px;"><?= icono('ubicacion') ?><div><strong>Dirección</strong><?= e($s['direccion']) ?></div></div>
        </div>
      <?php endforeach; ?>
      <div class="tarjeta-formulario" style="padding:24px;">
        <h3 style="font-size:17px; margin-bottom:10px;">Accesos rápidos</h3>
        <div class="fila fila--envolver"><a class="chip" href="agendar.php?tipo=visita">Agendar cita</a><a class="chip" href="agendar.php?tipo=apartado">Apartar vehículo</a><a class="chip" href="agendar.php?tipo=servicio">Orden de servicio</a><a class="chip" href="financiamiento.php">Simular crédito</a><a class="chip" href="servicios.php">Servicios</a></div>
      </div>
    </div>
  </div>
</section>
<?php catPie(['scripts' => ['formularios.js']]); ?>
