<?php
declare(strict_types=1);
/* KARMA · Catálogo — carrito de compras (refacciones y accesorios; las existencias se validan por sucursal) */
require_once __DIR__ . '/includes/layout.php';
$sucursal = catSucursalActual();
catCabecera(['titulo' => 'Carrito', 'activo' => '']);
?>
<section class="cabecera-pagina">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Carrito</li></ol>
    <h1>Tu carrito</h1>
    <p>Refacciones y accesorios con existencias de <strong translate="no">KARMA <?= e($sucursal['nombre']) ?></strong>. Al confirmar, las piezas se apartan del inventario de esta sucursal.</p>
  </div>
</section>
<div class="contenedor">
  <div class="disposicion-compra" id="paginaCarrito">
    <div>
      <div class="aviso-sucursal">
        <?= icono('tienda') ?>
        <span>Tu pedido se surtirá desde <strong translate="no">KARMA <?= e($sucursal['nombre']) ?></strong> · <?= e($sucursal['direccion']) ?></span>
        <button class="btn btn--fantasma btn--chico" type="button" data-abrir-sucursales>Cambiar</button>
      </div>
      <div class="lista-carrito" id="listaCarrito" aria-live="polite"><div class="esqueleto" style="height:140px"></div></div>
    </div>
    <aside class="resumen-compra" id="resumenCarrito">
      <h2>Resumen</h2>
      <div class="linea-resumen"><span>Subtotal</span><strong id="carritoSubtotal" translate="no">$0.00</strong></div>
      <div class="linea-resumen"><span>Recoger en sucursal</span><strong>Sin costo</strong></div>
      <div class="linea-resumen"><span>Envío a domicilio</span><strong id="carritoEnvio" translate="no"><?= catPrecio(CAT_ENVIO_COSTO, true) ?></strong></div>
      <div class="linea-resumen linea-resumen--total"><span>Total (recoger)</span><strong id="carritoTotal" translate="no">$0.00</strong></div>
      <div class="mensaje-form mensaje-form--error oculto" id="carritoProblemas"></div>
      <a class="btn btn--primario btn--grande btn--bloque" href="checkout.php" id="btnContinuar">Continuar con la compra <?= icono('flecha', 'icono flecha') ?></a>
      <a class="btn btn--fantasma btn--bloque" href="refacciones.php">Seguir comprando</a>
      <ul class="lista-check" style="margin-top:6px; font-size:13.5px;">
        <li>Recoge y paga en efectivo en caja, o recíbelo en casa pagando con tarjeta.</li>
        <li>Envío gratis en pedidos desde <?= catPrecio(CAT_ENVIO_GRATIS_DESDE) ?>.</li>
        <li>Las existencias se confirman al momento de pagar.</li>
      </ul>
    </aside>
  </div>
</div>
<?php catPie(['scripts' => ['carrito.js']]); ?>
