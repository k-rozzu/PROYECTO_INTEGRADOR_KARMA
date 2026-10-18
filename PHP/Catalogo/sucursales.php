<?php
declare(strict_types=1);
/* KARMA · Catálogo — Sucursales (datos de la tabla sucursales: dirección, teléfono, horarios, servicios e imagen) */
require_once __DIR__ . '/includes/layout.php';
$sucursal = catSucursalActual();
// Unidades disponibles por sucursal (vehículos y piezas) para mostrar el tamaño de cada inventario
$resumen = [];
foreach (catSucursales() as $s) {
    $todos = catBuscarProductos([], $s['id_sucursal']);
    $resumen[$s['id_sucursal']] = [
        'vehiculos' => array_sum(array_map(fn($p) => $p['esVehiculo'] ? $p['stock'] : 0, $todos)),
        'piezas' => array_sum(array_map(fn($p) => !$p['esVehiculo'] ? $p['stock'] : 0, $todos)),
    ];
}
catCabecera(['titulo' => 'Sucursales', 'activo' => 'sucursales']);
?>
<section class="cabecera-imagen" style="min-height:360px;">
  <img src="<?= catAsset('assets/Catalogo/banners/concesionario.webp') ?>" alt="" width="1920" height="960">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Sucursales</li></ol>
    <span class="mayus">Encuéntranos</span>
    <h1>Sucursales KARMA</h1>
    <p>Dos concesionarios en el estado de Colima, cada uno con su propio inventario de vehículos, refacciones y accesorios.</p>
  </div>
</section>
<section class="seccion">
  <div class="contenedor pila" style="--gap:24px;">
    <?php foreach (catSucursales() as $s): $actual = $s['id_sucursal'] === $sucursal['id_sucursal']; ?>
      <article class="tarjeta-sucursal revelar<?= $actual ? ' actual' : '' ?>" id="sucursal-<?= $s['id_sucursal'] ?>" style="margin-bottom:24px;">
        <div class="media">
          <!-- IMAGEN DE LA SUCURSAL: columna sucursales.imagen (assets/Catalogo/sucursales/) -->
          <img src="<?= catAsset($s['imagen']) ?>" alt="<?= e($s['ciudad'] ?? $s['nombre']) ?>" loading="lazy" width="1200" height="800">
        </div>
        <div class="cuerpo">
          <div class="fila fila--entre fila--envolver"><h3 translate="no">KARMA <?= e($s['nombre']) ?></h3><?php if ($actual): ?><span class="etiqueta etiqueta--solida">Tu sucursal</span><?php endif; ?></div>
          <div class="dato-contacto"><?= icono('ubicacion') ?><div><strong>Dirección</strong><?= e($s['direccion']) ?></div></div>
          <div class="dato-contacto"><?= icono('telefono') ?><div><strong>Teléfono</strong><a href="tel:<?= e($s['telefono']) ?>" translate="no"><?= e(preg_replace('/(\d{3})(\d{3})(\d{4})/', '$1 $2 $3', $s['telefono'])) ?></a></div></div>
          <?php if ($s['email']): ?><div class="dato-contacto"><?= icono('correo') ?><div><strong>Correo</strong><a href="mailto:<?= e($s['email']) ?>" translate="no"><?= e($s['email']) ?></a></div></div><?php endif; ?>
          <div class="dato-contacto"><?= icono('reloj') ?><div><strong>Horario de ventas</strong><?= e($s['horario_ventas'] ?? '—') ?><br><strong style="margin-top:6px">Horario de servicio</strong><?= e($s['horario_servicio'] ?? '—') ?></div></div>
          <div class="dato-contacto"><?= icono('auto') ?><div><strong>Inventario en línea</strong><?= $resumen[$s['id_sucursal']]['vehiculos'] ?> vehículos y <?= $resumen[$s['id_sucursal']]['piezas'] ?> refacciones/accesorios disponibles</div></div>
          <div class="lista-servicios"><?php foreach (array_filter(explode(',', (string)$s['servicios'])) as $sv): ?><span><?= e(trim($sv)) ?></span><?php endforeach; ?></div>
          <div class="acciones">
            <?php if (!$actual): ?><button class="btn btn--primario" type="button" data-elegir-sucursal="<?= $s['id_sucursal'] ?>"><?= icono('check') ?> Seleccionar sucursal</button><?php else: ?><a class="btn btn--primario" href="vehiculos.php?disponible=1"><?= icono('auto') ?> Ver su inventario</a><?php endif; ?>
            <a class="btn btn--secundario" href="https://www.google.com/maps/search/?api=1&query=<?= rawurlencode($s['direccion']) ?>" target="_blank" rel="noopener"><?= icono('mapa') ?> Cómo llegar</a>
            <a class="btn btn--fantasma" href="agendar.php?tipo=visita"><?= icono('calendario') ?> Agendar cita</a>
          </div>
        </div>
      </article>
    <?php endforeach; ?>
    <div class="aviso-sucursal"><?= icono('info') ?><span><strong>¿Por qué elegir sucursal?</strong> El mismo vehículo o pieza puede tener existencias distintas en Manzanillo y en Colima. Una compra en una sucursal solo descuenta el inventario de esa sucursal.</span></div>
  </div>
</section>
<?php catPie(); ?>
