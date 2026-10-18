<?php
declare(strict_types=1);
/* KARMA · Catálogo — confirmación y detalle de un pedido del cliente (pedido.php?id=12) */
require_once __DIR__ . '/includes/layout.php';
require_once __DIR__ . '/includes/cuenta.php';

$cliente = catRequerirCliente();
$pedido = catPedidosCliente((int)$cliente['id_cliente'], (int)($_GET['id'] ?? 0))[0] ?? null;
$nuevo = isset($_GET['nuevo']);

catCabecera(['titulo' => $pedido ? 'Pedido ' . $pedido['folio'] : 'Pedido no encontrado', 'activo' => '']);
if (!$pedido) {
    echo '<div class="contenedor" style="padding:96px 0"><div class="vacio">' . icono('documento', 'icono-grande') .
         '<h3>No encontramos ese pedido en tu cuenta</h3><p>Revisa tus pedidos desde tu perfil.</p><a class="btn btn--primario" href="perfil.php#pedidos">Ver mis pedidos</a></div></div>';
    catPie();
    exit;
}
$esEnvio = $pedido['entrega'] === 'envio';
$pendiente = $pedido['clase'] === 'pendiente';
$cancelado = $pedido['clase'] === 'cancelado';

// Línea de tiempo del pedido según su estado real en web_orders
$pasos = $esEnvio
    ? [['Pedido recibido', $pedido['fechaTexto'], true], ['Pago aprobado (simulación)', $pedido['fechaPago'] ?? '', !$cancelado],
       ['En preparación para envío', 'Desde KARMA ' . $pedido['sucursal'], !$cancelado], ['Entregado', 'Te avisaremos por correo', false]]
    : [['Pedido recibido y piezas apartadas', $pedido['fechaTexto'], true],
       ['Pago en efectivo en caja', $pedido['fechaPago'] ? 'Pagado el ' . $pedido['fechaPago'] : 'Pendiente de pago en sucursal', !$pendiente && !$cancelado],
       ['Entregado en sucursal', $pendiente ? 'Al pagar en caja' : '', !$pendiente && !$cancelado]];
?>
<div class="contenedor contenedor--angosto" style="padding-top:40px; padding-bottom:96px;">
  <?php if ($nuevo): ?>
    <div class="exito-cabeza<?= $pendiente ? ' exito-cabeza--pendiente' : '' ?>">
      <span class="icono-ok"><?= icono($pendiente ? 'tienda' : 'check') ?></span>
      <div>
        <h1><?= $pendiente ? '¡Pedido apartado!' : '¡Pago aprobado!' ?></h1>
        <p class="texto-2"><?= $pendiente
            ? 'Tus piezas quedaron apartadas en KARMA ' . e($pedido['sucursal']) . '. Presenta tu folio en caja y paga en efectivo al recogerlas.'
            : 'Recibimos tu pago (simulación) y preparamos tu envío desde KARMA ' . e($pedido['sucursal']) . '.' ?></p>
      </div>
    </div>
  <?php endif; ?>

  <div class="fila fila--entre fila--envolver" style="margin-bottom:22px;">
    <div>
      <ol class="migas"><li><a href="perfil.php">Mi perfil</a></li><li><a href="perfil.php#pedidos">Pedidos</a></li><li translate="no"><?= e($pedido['folio']) ?></li></ol>
      <h2 style="font-size:30px; margin-top:8px;">Pedido <span translate="no"><?= e($pedido['folio']) ?></span></h2>
      <p class="texto-3"><?= e($pedido['fechaTexto']) ?></p>
    </div>
    <span class="estado-pill estado-pill--<?= e($pedido['clase']) ?>"><?= e($pedido['etiqueta']) ?></span>
  </div>

  <div class="dividido" style="align-items:start; gap:32px;">
    <div class="bloque-checkout">
      <h2 style="font-size:19px;">Seguimiento</h2>
      <ol class="linea-tiempo" style="margin-top:14px;">
        <?php if ($cancelado): ?>
          <li class="hecho"><strong>Pedido recibido</strong><small><?= e($pedido['fechaTexto']) ?></small></li>
          <li class="cancelado"><strong>Pedido cancelado</strong><small>Las piezas regresaron al inventario de la sucursal</small></li>
        <?php else: foreach ($pasos as $i => [$titulo, $detalle, $hecho]): $esActual = !$hecho && ($i === 0 || $pasos[$i - 1][2]); ?>
          <li class="<?= $hecho ? 'hecho' : ($esActual ? 'actual' : '') ?>"><strong><?= e($titulo) ?></strong><small><?= e($detalle) ?></small></li>
        <?php endforeach; endif; ?>
      </ol>
      <hr class="separador">
      <?php if ($esEnvio): ?>
        <div class="dato-contacto"><?= icono('envio') ?><div><strong>Envío a domicilio</strong><?= e($pedido['direccion']) ?></div></div>
        <div class="dato-contacto" style="margin-top:12px;"><?= icono('tarjeta') ?><div><strong>Pago con <?= e($pedido['metodoPago']) ?></strong><span translate="no"><?= e($pedido['tarjeta']) ?> · Ref. <?= e($pedido['referencia']) ?></span></div></div>
      <?php else: ?>
        <div class="dato-contacto"><?= icono('tienda') ?><div><strong>Recoger en KARMA <?= e($pedido['sucursal']) ?></strong><?= e($pedido['sucursalDireccion']) ?> · Tel. <span translate="no"><?= e($pedido['sucursalTelefono']) ?></span></div></div>
        <div class="dato-contacto" style="margin-top:12px;"><?= icono('efectivo') ?><div><strong>Pago en efectivo en caja</strong>Presenta el folio <span translate="no"><?= e($pedido['folio']) ?></span> al cajero.</div></div>
      <?php endif; ?>
      <div class="dato-contacto" style="margin-top:12px;"><?= icono('usuario') ?><div><strong>Contacto</strong><?= e($pedido['contacto']['nombre']) ?> · <span translate="no"><?= e($pedido['contacto']['celular']) ?></span></div></div>
      <?php if ($pedido['comentarios']): ?><div class="dato-contacto" style="margin-top:12px;"><?= icono('mensaje') ?><div><strong>Comentarios</strong><?= e($pedido['comentarios']) ?></div></div><?php endif; ?>
    </div>

    <div class="resumen-compra" style="position:static;">
      <h2>Artículos</h2>
      <?php foreach ($pedido['lineas'] as $l): ?>
        <div class="mini-item">
          <img src="<?= e($l['imagen']) ?>" alt="" loading="lazy" width="54" height="42">
          <div class="nom"><strong><?= e($l['descripcion']) ?></strong><span class="texto-3"><?= $l['cantidad'] ?> × <span translate="no"><?= catPrecio($l['precio'], true) ?></span></span></div>
          <strong translate="no"><?= catPrecio($l['subtotal'], true) ?></strong>
        </div>
      <?php endforeach; ?>
      <hr class="separador" style="margin:6px 0">
      <div class="linea-resumen"><span>Subtotal</span><strong translate="no"><?= catPrecio($pedido['subtotal'], true) ?></strong></div>
      <div class="linea-resumen"><span>Envío</span><strong translate="no"><?= $esEnvio ? ($pedido['envio'] > 0 ? catPrecio($pedido['envio'], true) : 'Gratis') : 'Sin costo' ?></strong></div>
      <div class="linea-resumen linea-resumen--total"><span>Total</span><strong translate="no"><?= catPrecio($pedido['total'], true) ?></strong></div>
      <?php if ($pedido['cancelable']): ?>
        <button class="btn btn--peligro btn--bloque" type="button" id="btnCancelarPedido" data-id="<?= $pedido['id'] ?>"><?= icono('cerrar') ?> Cancelar pedido</button>
      <?php endif; ?>
      <a class="btn btn--secundario btn--bloque" href="perfil.php#pedidos">Ver todos mis pedidos</a>
      <a class="btn btn--fantasma btn--bloque" href="refacciones.php">Seguir comprando</a>
    </div>
  </div>
</div>
<?php catPie(['scripts' => ['carrito.js']]); ?>
