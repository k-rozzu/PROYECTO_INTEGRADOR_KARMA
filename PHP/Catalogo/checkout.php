<?php
declare(strict_types=1);
/* KARMA · Catálogo — checkout: A) Recoger en sucursal + efectivo  ·  B) Envío a domicilio + tarjeta (pago simulado) */
require_once __DIR__ . '/includes/layout.php';
$cliente = catRequerirCliente();
$sucursal = catSucursalActual();
if (!catCarrito()) { header('Location: carrito.php'); exit; }
catCabecera(['titulo' => 'Finalizar compra', 'activo' => '']);
$entidades = ['Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche', 'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila',
    'Colima', 'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León',
    'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'];
?>
<section class="cabecera-pagina">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li><a href="carrito.php">Carrito</a></li><li>Finalizar compra</li></ol>
    <h1>Finalizar compra</h1>
  </div>
</section>
<div class="contenedor">
  <form class="disposicion-compra" id="formCheckout" novalidate>
    <div>
      <div class="pasos" aria-hidden="true"><span class="paso activo">Entrega y pago</span><span class="paso activo">Tus datos</span><span class="paso">Confirmación</span></div>

      <!-- 1. MODALIDAD -->
      <div class="bloque-checkout">
        <h2><span class="num">1</span> ¿Cómo quieres recibir y pagar tu pedido?</h2>
        <p>El inventario se descuenta de <strong translate="no">KARMA <?= e($sucursal['nombre']) ?></strong> en ambos casos.</p>
        <div class="opciones-tarjeta">
          <label class="opcion-tarjeta">
            <input type="radio" name="modalidad" value="recoger_efectivo" checked>
            <span class="icono-caja"><?= icono('tienda') ?></span>
            <span><strong>Recoger en sucursal · Efectivo</strong><p>Apartamos tus piezas en <?= e($sucursal['nombre']) ?>. Pagas en efectivo en caja al recogerlas. Sin costo de envío.</p></span>
          </label>
          <label class="opcion-tarjeta">
            <input type="radio" name="modalidad" value="envio_tarjeta">
            <span class="icono-caja"><?= icono('envio') ?></span>
            <span><strong>Envío a domicilio · Tarjeta</strong><p>Pagas en línea con tarjeta de crédito o débito y lo enviamos a tu domicilio. <?= catPrecio(CAT_ENVIO_COSTO) ?> o gratis desde <?= catPrecio(CAT_ENVIO_GRATIS_DESDE) ?>.</p></span>
          </label>
        </div>
      </div>

      <!-- 2. DATOS DE CONTACTO Y ENVÍO -->
      <div class="bloque-checkout">
        <h2><span class="num">2</span> Datos de contacto</h2>
        <p>Los usaremos para avisarte del estado de tu pedido.</p>
        <div class="campos">
          <div class="campo ancho"><label for="ckNombre">Nombre de quien recibe o recoge</label><input id="ckNombre" name="nombre" required maxlength="150" autocomplete="name" value="<?= e($cliente['nombre']) ?>"></div>
          <div class="campo"><label for="ckCelular">Celular</label><input id="ckCelular" name="celular" type="tel" required maxlength="20" autocomplete="tel" value="<?= e($cliente['celular'] ?? '') ?>"></div>
          <div class="campo"><label for="ckEmail">Correo electrónico</label><input id="ckEmail" name="email" type="email" required maxlength="120" autocomplete="email" value="<?= e($cliente['email']) ?>"></div>
        </div>
        <div id="bloqueEnvio" class="oculto" style="margin-top:22px;">
          <h3 style="font-size:17px; margin-bottom:12px;">Dirección de envío</h3>
          <div class="campos">
            <div class="campo ancho"><label for="ckCalle">Calle y número</label><input id="ckCalle" name="calle" maxlength="150" autocomplete="street-address" value="<?= e($cliente['direccion'] ?? '') ?>"></div>
            <div class="campo"><label for="ckColonia">Colonia</label><input id="ckColonia" name="colonia" maxlength="100"></div>
            <div class="campo"><label for="ckCp">Código postal</label><input id="ckCp" name="cp" inputmode="numeric" maxlength="5" autocomplete="postal-code" value="<?= e($cliente['codigo_postal'] ?? '') ?>"></div>
            <div class="campo"><label for="ckCiudad">Ciudad</label><input id="ckCiudad" name="ciudad" maxlength="100" autocomplete="address-level2" value="<?= e($cliente['ciudad'] ?? '') ?>"></div>
            <div class="campo"><label for="ckEstado">Estado</label>
              <select id="ckEstado" name="estado"><option value="">Elige un estado</option>
                <?php foreach ($entidades as $en): ?><option <?= ($cliente['entidad_federativa'] ?? 'Colima') === $en ? 'selected' : '' ?>><?= e($en) ?></option><?php endforeach; ?>
              </select></div>
            <div class="campo ancho"><label for="ckRef">Referencias <span class="opcional">(opcional)</span></label><input id="ckRef" name="referencias" maxlength="150" placeholder="Entre calles, color de fachada…"></div>
          </div>
        </div>
      </div>

      <!-- 3. PAGO -->
      <div class="bloque-checkout">
        <h2><span class="num">3</span> Pago</h2>
        <div id="pagoEfectivo">
          <div class="mensaje-form mensaje-form--info"><?= icono('efectivo') ?><span>Pagarás <strong id="ckTotalEfectivo" translate="no"></strong> en efectivo en la caja de <strong translate="no">KARMA <?= e($sucursal['nombre']) ?></strong> (<?= e($sucursal['direccion']) ?>). Tu pedido aparecerá en la sucursal como <em>pendiente de cobro</em> y te pedimos recogerlo en los próximos 3 días.</span></div>
        </div>
        <div id="pagoTarjeta" class="oculto">
          <div class="sello-simulacion"><?= icono('info') ?><span><strong>Modo simulación:</strong> no se realiza ningún cargo real ni se guarda el número completo de la tarjeta. Prueba con 4242 4242 4242 4242 (aprobada) o 4000 0000 0000 0002 (rechazada).</span></div>
          <div class="dividido" style="gap:28px; margin-top:20px; align-items:start;">
            <div class="campos" style="grid-template-columns:1fr 1fr;">
              <div class="campo ancho"><label for="tjTitular">Titular de la tarjeta</label><input id="tjTitular" maxlength="100" autocomplete="cc-name" value="<?= e($cliente['nombre']) ?>"></div>
              <div class="campo ancho"><label for="tjNumero">Número de tarjeta</label><input id="tjNumero" inputmode="numeric" maxlength="23" autocomplete="cc-number" placeholder="0000 0000 0000 0000"></div>
              <div class="campo"><label for="tjVence">Vencimiento</label><input id="tjVence" inputmode="numeric" maxlength="5" autocomplete="cc-exp" placeholder="MM/AA"></div>
              <div class="campo"><label for="tjCvv">CVV</label><input id="tjCvv" inputmode="numeric" maxlength="4" autocomplete="cc-csc" placeholder="123"></div>
              <div class="campo ancho"><label for="tjTipo">Tipo de tarjeta</label><select id="tjTipo"><option value="credito">Crédito</option><option value="debito">Débito</option></select></div>
            </div>
            <div class="tarjeta-visual" aria-hidden="true">
              <div class="fila fila--entre"><span class="chip-tarjeta"></span><span id="tvMarca">Tarjeta</span></div>
              <div class="numero" id="tvNumero">•••• •••• •••• ••••</div>
              <div class="datos"><div><span>Titular</span><strong id="tvTitular"><?= e(mb_strtoupper($cliente['nombre'])) ?></strong></div><div><span>Vence</span><strong id="tvVence">MM/AA</strong></div></div>
            </div>
          </div>
        </div>
        <div class="campo" style="margin-top:18px;"><label for="ckComentarios">Comentarios del pedido <span class="opcional">(opcional)</span></label><textarea id="ckComentarios" name="comentarios" maxlength="500" style="min-height:80px" placeholder="Ej. pasaré el sábado por la mañana"></textarea></div>
      </div>
    </div>

    <aside class="resumen-compra">
      <h2>Tu pedido</h2>
      <div id="ckItems" class="pila"></div>
      <hr class="separador" style="margin:6px 0">
      <div class="linea-resumen"><span>Subtotal</span><strong id="ckSubtotal" translate="no">$0.00</strong></div>
      <div class="linea-resumen"><span>Envío</span><strong id="ckEnvio" translate="no">$0.00</strong></div>
      <div class="linea-resumen linea-resumen--total"><span>Total</span><strong id="ckTotal" translate="no">$0.00</strong></div>
      <div class="linea-resumen"><span>Sucursal</span><strong translate="no"><?= e($sucursal['nombre']) ?></strong></div>
      <div class="mensaje-form" id="ckMensaje" role="alert"></div>
      <button class="btn btn--primario btn--grande btn--bloque" type="submit" id="btnConfirmar">Confirmar pedido</button>
      <a class="btn btn--fantasma btn--bloque" href="carrito.php"><?= icono('flecha-izq', 'icono icono--chico') ?> Volver al carrito</a>
      <p class="texto-3" style="font-size:12px;">Al confirmar aceptas los <a class="enlace" href="terminos.php" target="_blank">términos y condiciones</a> y el <a class="enlace" href="privacidad.php" target="_blank">aviso de privacidad</a>.</p>
    </aside>
    <input type="hidden" name="id_sucursal" value="<?= $sucursal['id_sucursal'] ?>">
  </form>
</div>
<?php catPie(['scripts' => ['carrito.js']]); ?>
