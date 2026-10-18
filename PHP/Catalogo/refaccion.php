<?php
declare(strict_types=1);
/* KARMA · Catálogo — detalle de una refacción o accesorio (refaccion.php?id=63) */
require_once __DIR__ . '/includes/layout.php';

$p = catProducto((int)($_GET['id'] ?? 0), isset($_GET['codigo']) ? (string)$_GET['codigo'] : null);
if ($p && $p['esVehiculo']) { header('Location: vehiculo.php?id=' . $p['id']); exit; }
$sucursal = catSucursalActual();

if (!$p) {
    http_response_code(404);
    catCabecera(['titulo' => 'Producto no encontrado', 'activo' => 'refacciones']);
    echo '<div class="contenedor" style="padding:96px 0"><div class="vacio">' . icono('herramienta', 'icono-grande') .
         '<h3>No encontramos ese producto</h3><p>Es posible que ya no esté publicado.</p><a class="btn btn--primario" href="refacciones.php">Ver refacciones</a></div></div>';
    catPie();
    exit;
}

$esAccesorio = $p['seccion'] === 'accesorios';
$stockSucursales = catStockPorSucursal($p['id']);
// Relacionados: misma marca y sección (primero la misma categoría)
$relacionados = array_values(array_filter(
    catBuscarProductos(['seccion' => [$p['seccion']], 'marca' => $p['marca'], 'orden' => 'disponibles']),
    fn($r) => $r['id'] !== $p['id']
));
usort($relacionados, fn($a, $b) => ($b['subcategoria'] === $p['subcategoria']) <=> ($a['subcategoria'] === $p['subcategoria']));
$relacionados = array_slice($relacionados, 0, 8);
$listado = $esAccesorio ? ['accesorios.php', 'Accesorios'] : ['refacciones.php', 'Refacciones'];
$maximo = max(1, min($p['stock'], CAT_MAX_POR_PRODUCTO));

catCabecera(['titulo' => $p['nombre'], 'activo' => $esAccesorio ? 'accesorios' : 'refacciones', 'descripcion' => mb_substr((string)$p['descripcionLarga'], 0, 160)]);
?>
<div class="contenedor">
  <ol class="migas" style="padding-top:24px;">
    <li><a href="index.php">Inicio</a></li><li><a href="<?= $listado[0] ?>"><?= $listado[1] ?></a></li>
    <li><a href="<?= $listado[0] ?>?marca=<?= e($p['marca']) ?>" translate="no"><?= e($p['marca']) ?></a></li><li><?= e($p['nombre']) ?></li>
  </ol>

  <div class="detalle">
    <div class="galeria">
      <div class="galeria-principal pieza" style="background: radial-gradient(ellipse at 50% 42%, var(--c-surface) 0%, var(--c-media-bg) 72%);">
        <!-- IMAGEN DEL PRODUCTO: productos_web.imagen (assets/Catalogo/refacciones/{marca}/... o accesorios/...) -->
        <img src="<?= e($p['imagen']) ?>" alt="<?= e($p['nombre']) ?>" id="imagenPrincipal" width="1000" height="750">
      </div>
      <p class="texto-3" style="font-size:12.5px;"><?= $esAccesorio ? 'Fotografía de referencia.' : 'Imagen ilustrativa (render) de la pieza.' ?> Verifica la compatibilidad con tu VIN en sucursal.</p>
    </div>

    <aside class="resumen-producto">
      <div>
        <span class="mayus texto-3"><span translate="no"><?= e($p['marca']) ?></span> · <?= e($p['subcategoria'] ?? '') ?></span>
        <h1 style="margin-top:8px;"><?= e($p['nombre']) ?></h1>
        <p class="subtitulo">Código <strong translate="no"><?= e($p['codigo']) ?></strong></p>
      </div>
      <div class="bloque-precio">
        <small>Precio unitario · IVA incluido</small>
        <span class="precio" translate="no"><?= e($p['precioTexto']) ?> <small>MXN</small></span>
      </div>
      <div class="ficha-tecnica" style="grid-template-columns:1fr;">
        <div class="fila-ficha"><span>Compatible con</span><strong translate="no"><?= e($p['compatibilidad'] ?: $p['marca'] . ' ' . $p['modelo']) ?></strong></div>
        <?php if ($p['motorCompatible']): ?><div class="fila-ficha"><span>Motor del vehículo compatible</span><strong translate="no"><?= e($p['motorCompatible']) ?></strong></div><?php endif; ?>
        <?php if ($p['traccion']): ?><div class="fila-ficha"><span>Posición</span><strong><?= e($p['traccion']) ?><?= $p['lado'] ? ' · ' . e($p['lado']) : '' ?></strong></div><?php endif; ?>
        <?php if ($p['color']): ?><div class="fila-ficha"><span>Acabado</span><strong><?= e($p['color']) ?></strong></div><?php endif; ?>
      </div>
      <div class="disp-sucursales">
        <?php foreach ($stockSucursales as $s): $esActual = $s['id_sucursal'] === $sucursal['id_sucursal']; ?>
          <div class="disp-sucursal<?= $esActual ? ' actual' : '' ?>">
            <span><strong translate="no">KARMA <?= e($s['nombre']) ?></strong><?= $esActual ? ' · tu sucursal' : '' ?></span>
            <span class="fila" style="gap:10px;"><span class="disp disp--<?= e($s['estado']) ?>"><?= e($s['texto']) ?></span>
              <?php if (!$esActual): ?><button class="btn btn--fantasma btn--chico" type="button" data-elegir-sucursal="<?= $s['id_sucursal'] ?>">Comprar aquí</button><?php endif; ?>
            </span>
          </div>
        <?php endforeach; ?>
      </div>
      <?php if ($p['stock'] > 0): ?>
        <div class="fila fila--envolver">
          <div class="selector-cantidad" aria-label="Cantidad">
            <button type="button" data-paso-cantidad="-1" aria-label="Quitar una"><?= icono('menos', 'icono icono--chico') ?></button>
            <input type="number" id="cantidadPieza" value="1" min="1" max="<?= $maximo ?>" aria-label="Cantidad">
            <button type="button" data-paso-cantidad="1" aria-label="Agregar una"><?= icono('mas', 'icono icono--chico') ?></button>
          </div>
          <button class="btn btn--primario btn--grande" type="button" style="flex:1" data-agregar-carrito="<?= $p['id'] ?>" data-cantidad-de="#cantidadPieza"><?= icono('carrito') ?> Agregar al carrito</button>
        </div>
        <p class="texto-3" style="font-size:13px;">Máximo <?= $maximo ?> pieza(s) según existencias de <?= e($sucursal['nombre']) ?>.</p>
      <?php else: ?>
        <div class="mensaje-form mensaje-form--error"><?= icono('alerta') ?><span><strong>0 unidades disponibles</strong> en <?= e($sucursal['nombre']) ?>. <?= array_filter($stockSucursales, fn($s) => $s['stock'] > 0) ? 'Cámbiate a otra sucursal con existencias para comprarlo.' : 'Escríbenos y te avisamos cuándo llega.' ?></span></div>
        <a class="btn btn--secundario btn--grande" href="contacto.php?motivo=contacto"><?= icono('mensaje') ?> Contáctanos</a>
      <?php endif; ?>
      <div class="beneficios" style="grid-template-columns:1fr 1fr;">
        <div class="beneficio" style="padding:16px;"><span class="icono-caja" style="width:38px;height:38px;margin:0"><?= icono('tienda', 'icono icono--chico') ?></span><strong style="font-size:14px">Recoge en sucursal</strong><span class="texto-2" style="font-size:13px">Paga en efectivo en caja</span></div>
        <div class="beneficio" style="padding:16px;"><span class="icono-caja" style="width:38px;height:38px;margin:0"><?= icono('envio', 'icono icono--chico') ?></span><strong style="font-size:14px">Envío a domicilio</strong><span class="texto-2" style="font-size:13px">Gratis desde <?= catPrecio(CAT_ENVIO_GRATIS_DESDE) ?></span></div>
      </div>
    </aside>
  </div>
</div>

<section class="seccion--compacta seccion--alt">
  <div class="contenedor dividido" style="align-items:start;">
    <div>
      <span class="mayus texto-3">Descripción</span>
      <h2 style="font-size:clamp(24px,2.6vw,32px); margin:10px 0 14px;">Detalles del producto</h2>
      <p class="texto-2" style="font-size:16px;"><?= e($p['descripcionLarga']) ?></p>
      <?php if (!$esAccesorio): ?>
        <div class="fila fila--envolver" style="margin-top:24px;">
          <a class="btn btn--secundario" href="agendar.php?tipo=servicio&servicio=<?= rawurlencode(str_contains(mb_strtolower($p['subcategoria'] ?? ''), 'freno') ? 'Servicio de frenos' : 'Mantenimiento programado') ?>"><?= icono('herramienta') ?> Agendar instalación en taller</a>
        </div>
      <?php endif; ?>
    </div>
    <ul class="caracteristicas" style="grid-template-columns:1fr;">
      <?php foreach ($p['caracteristicas'] as $c): ?><li><?= icono('check') ?><span><?= e($c) ?></span></li><?php endforeach; ?>
    </ul>
  </div>
</section>

<?php if ($relacionados): ?>
<section class="seccion">
  <div class="contenedor">
    <div class="titulo-seccion">
      <div><span class="mayus">También para tu <span translate="no"><?= e($p['marca']) ?></span></span><h2><?= $esAccesorio ? 'Más accesorios' : 'Refacciones relacionadas' ?></h2></div>
      <div class="carrusel-flechas"><button type="button" aria-label="Anteriores"><?= icono('chevron-izq') ?></button><button type="button" aria-label="Siguientes"><?= icono('chevron-der') ?></button></div>
    </div>
    <div class="carrusel-pista" id="pistaRelacionados"></div>
  </div>
</section>
<?php endif; ?>

<script type="application/json" id="datosProducto"><?= json_encode(['producto' => $p, 'relacionados' => $relacionados], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?></script>
<?php catPie(['scripts' => ['producto.js']]); ?>
