<?php
declare(strict_types=1);
/* KARMA · Catálogo — página de detalle de un vehículo (vehiculo.php?id=25 o vehiculo.php?codigo=KRM-CAT-AUDI-15) */
require_once __DIR__ . '/includes/layout.php';

$p = catProducto((int)($_GET['id'] ?? 0), isset($_GET['codigo']) ? (string)$_GET['codigo'] : null);
if ($p && !$p['esVehiculo']) { header('Location: refaccion.php?id=' . $p['id']); exit; }

$sucursal = catSucursalActual();
$cliente = catClienteActual();

if (!$p) {
    http_response_code(404);
    catCabecera(['titulo' => 'Vehículo no encontrado', 'activo' => 'modelos']);
    echo '<div class="contenedor" style="padding:96px 0"><div class="vacio">' . icono('auto', 'icono-grande') .
         '<h3>No encontramos ese vehículo</h3><p>Es posible que ya no esté publicado en el catálogo.</p><a class="btn btn--primario" href="vehiculos.php">Ver todos los modelos</a></div></div>';
    catPie();
    exit;
}

$stockSucursales = catStockPorSucursal($p['id']);
$opciones = catOpcionesConfigurador($p['marca'], $p['tipo']);
$compatibles = catCompatiblesConVehiculo($p, 8);
$favorito = in_array($p['id'], catFavoritosIds($cliente ? (int)$cliente['id_cliente'] : null), true);
$otras = array_values(array_filter($stockSucursales, fn($s) => $s['id_sucursal'] !== $sucursal['id_sucursal']));
// IMAGEN: cada vehículo muestra UNA sola foto (productos_web.imagen); no se usan imágenes extra
$imagen = $p['imagen'];
$tituloCompleto = $p['titulo'] . ($p['anio'] ? ' ' . $p['anio'] : '');
$tiene3D = !empty($p['modelo3d']);

$ficha = [
    'Marca' => $p['marca'], 'Modelo' => $p['modelo'], 'Año' => $p['anio'], 'Tipo' => $p['tipo'] === 'moto' ? 'Motocicleta' : 'Automóvil',
    'Carrocería / estilo' => $p['subcategoria'], 'Motor' => $p['motor'], 'Cilindraje' => $p['cilindraje'], 'Potencia' => $p['potencia'],
    'Aceleración 0–100 km/h' => $p['aceleracion'], 'Transmisión' => $p['transmision'], 'Tracción' => $p['traccion'],
    'Color exterior de la unidad' => $p['color'], 'Color interior' => $p['colorInterior'], 'Código de producto' => $p['codigo'],
    'VIN de la unidad en inventario' => $p['vin'] ?? null
];

catCabecera([
    'titulo' => $tituloCompleto,
    'activo' => 'modelos',
    'descripcion' => mb_substr($p['descripcionLarga'] ?? '', 0, 160),
    // Three.js para la vista 3D (misma versión fija que usa el Punto de Venta)
    'head' => $tiene3D ? '<script type="importmap">{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.186.1/build/three.module.js","three/addons/":"https://cdn.jsdelivr.net/npm/three@0.186.1/examples/jsm/"}}</script>' : ''
]);
?>
<div class="contenedor">
  <ol class="migas" style="padding-top:24px;">
    <li><a href="index.php">Inicio</a></li><li><a href="vehiculos.php">Modelos</a></li>
    <li><a href="vehiculos.php?marca=<?= e($p['marca']) ?>" translate="no"><?= e($p['marca']) ?></a></li><li translate="no"><?= e($p['modelo']) ?></li>
  </ol>

  <div class="detalle">
    <!-- ===== GALERÍA ===== -->
    <div class="galeria" id="galeria">
      <div class="galeria-principal" id="galeriaPrincipal">
        <!-- IMAGEN DEL VEHÍCULO: productos_web.imagen (una sola foto por vehículo) -->
        <img src="<?= e($imagen) ?>" alt="<?= e($tituloCompleto) ?>" id="imagenPrincipal" width="1280" height="800" fetchpriority="high">
        <div class="vista3d-lienzo" id="lienzo3D"></div>
      </div>
      <?php if ($tiene3D): ?>
        <!-- Con modelo 3D: alterna entre la fotografía y el visor -->
        <div class="galeria-miniaturas" role="tablist" aria-label="Vista del vehículo">
          <button class="activo" type="button" data-imagen="<?= e($imagen) ?>" aria-label="Ver fotografía"><img src="<?= e($p['miniatura']) ?>" alt="" loading="lazy" width="104" height="65"></button>
          <button class="boton-3d" type="button" id="boton3D" aria-label="Ver modelo 3D"><?= icono('cubo') ?></button>
        </div>
      <?php endif; ?>
      <p class="texto-3" style="font-size:12.5px;">Fotografías de referencia del modelo<?= $tiene3D ? ' · Toca el cubo para ver el modelo 3D y probar colores' : '' ?>. Ver <a class="enlace" href="creditos.php">créditos de imágenes</a>.</p>
    </div>

    <!-- ===== RESUMEN Y COMPRA ===== -->
    <aside class="resumen-producto">
      <div>
        <span class="mayus texto-3"><span translate="no"><?= e($p['marca']) ?></span> · <?= e($p['subcategoria'] ?? '') ?> · <span translate="no"><?= e((string)$p['anio']) ?></span></span>
        <h1 translate="no" style="margin-top:8px;"><?= e($p['titulo']) ?></h1>
        <p class="subtitulo"><?= e($p['detalle'] ?? '') ?></p>
      </div>
      <div class="bloque-precio">
        <small>Precio desde · IVA incluido</small>
        <span class="precio" translate="no"><?= e($p['precioTexto']) ?> <small>MXN</small></span>
        <small id="mensualidadDesde"></small>
      </div>
      <div class="specs-rapidas">
        <div class="spec-rapida"><strong translate="no"><?= e($p['potencia'] ?? '—') ?></strong><span>Potencia</span></div>
        <div class="spec-rapida"><strong translate="no"><?= e($p['aceleracion'] ?? '—') ?></strong><span>0–100 km/h</span></div>
        <div class="spec-rapida"><strong><?= e(explode(' ', (string)($p['traccion'] ?? '—'))[0]) ?></strong><span>Tracción</span></div>
      </div>
      <div class="disp-sucursales">
        <?php foreach ($stockSucursales as $s): $esActual = $s['id_sucursal'] === $sucursal['id_sucursal']; ?>
          <div class="disp-sucursal<?= $esActual ? ' actual' : '' ?>">
            <span><strong translate="no">KARMA <?= e($s['nombre']) ?></strong><?= $esActual ? ' · tu sucursal' : '' ?></span>
            <span class="fila" style="gap:10px;"><span class="disp disp--<?= e($s['estado']) ?>"><?= e($s['texto']) ?></span>
              <?php if (!$esActual): ?><button class="btn btn--fantasma btn--chico" type="button" data-elegir-sucursal="<?= $s['id_sucursal'] ?>">Ver aquí</button><?php endif; ?>
            </span>
          </div>
        <?php endforeach; ?>
      </div>
      <?php if ($p['stock'] <= 0): ?>
        <div class="mensaje-form mensaje-form--info"><?= icono('info') ?><span>Sin unidades en <?= e($sucursal['nombre']) ?>. Puedes agendar una visita para cotizarlo sobre pedido<?= array_filter($otras, fn($o) => $o['stock'] > 0) ? ' o cambiar a otra sucursal con existencias' : '' ?>.</span></div>
      <?php endif; ?>
      <div class="acciones-producto">
        <a class="btn btn--primario" href="agendar.php?tipo=visita&id=<?= $p['id'] ?>"><?= icono('calendario') ?> Agendar cita</a>
        <a class="btn btn--secundario" href="agendar.php?tipo=apartado&id=<?= $p['id'] ?>"><?= icono('etiqueta') ?> Apartar</a>
      </div>
      <div class="acciones-secundarias">
        <a href="#financiamiento"><?= icono('porcentaje') ?> Simular crédito</a>
        <button type="button" data-favorito="<?= $p['id'] ?>" class="<?= $favorito ? 'activo' : '' ?>" aria-pressed="<?= $favorito ? 'true' : 'false' ?>"><?= icono('corazon') ?> Guardar</button>
        <button type="button" id="btnCompartir"><?= icono('compartir') ?> Compartir</button>
      </div>
    </aside>
  </div>
</div>

<!-- ===== SUBNAVEGACIÓN DE LA FICHA ===== -->
<nav class="subnav" aria-label="Secciones del vehículo">
  <div class="contenedor">
    <a href="#resumen">Resumen</a><a href="#configurador">Configurador</a><a href="#especificaciones">Especificaciones</a>
    <a href="#financiamiento">Financiamiento</a><?php if ($compatibles): ?><a href="#compatibles">Refacciones y accesorios</a><?php endif; ?>
  </div>
</nav>

<!-- ===== RESUMEN ===== -->
<section class="seccion--compacta" id="resumen">
  <div class="contenedor dividido" style="align-items:start;">
    <div>
      <span class="mayus texto-3">Resumen</span>
      <h2 class="titulo-dividido">Conoce el <span translate="no"><?= e($p['titulo']) ?></span></h2>
      <p class="texto-2 texto-dividido"><?= e($p['descripcionLarga']) ?></p>
    </div>
    <ul class="caracteristicas" style="grid-template-columns:1fr;">
      <?php foreach ($p['caracteristicas'] as $c): ?><li><?= icono('check') ?><span><?= e($c) ?></span></li><?php endforeach; ?>
    </ul>
  </div>
</section>

<!-- ===== CONFIGURADOR ===== -->
<section class="seccion seccion--alt" id="configurador">
  <div class="contenedor">
    <div class="titulo-seccion">
      <div>
        <span class="mayus">Configurador</span>
        <h2>Personaliza tu <span translate="no"><?= e($p['titulo']) ?></span></h2>
        <p>Elige color, versión y equipamiento para obtener un precio estimado y llevarlo a tu cita. La unidad en inventario es color <strong><?= e($p['color'] ?? '—') ?></strong>; otros colores y paquetes se surten sobre pedido.</p>
      </div>
    </div>
    <div class="configurador">
      <div>
        <?php if ($opciones['color']): ?>
          <div class="grupo-config">
            <h3>Color exterior</h3>
            <p id="colorElegidoTexto">Elegido: <?= e($p['color'] ?? '') ?> (unidad en inventario)</p>
            <div class="muestras" id="muestrasColor">
              <button class="muestra-color activo" type="button" data-color="<?= e($p['color'] ?? '') ?>" data-hex="<?= e($p['colorHex'] ?? '#8C9096') ?>" data-precio="0">
                <span class="circulo" style="background:<?= e($p['colorHex'] ?? '#8C9096') ?>"></span><?= e($p['color'] ?? '') ?><span class="extra">En inventario</span>
              </button>
              <?php foreach ($opciones['color'] as $o): if (mb_strtolower($o['nombre']) === mb_strtolower((string)$p['color'])) continue; ?>
                <button class="muestra-color" type="button" data-color="<?= e($o['nombre']) ?>" data-hex="<?= e($o['colorHex'] ?? '#888') ?>" data-precio="<?= $o['precio'] ?>">
                  <span class="circulo" style="background:<?= e($o['colorHex'] ?? '#888') ?>"></span><?= e($o['nombre']) ?><span class="extra"><?= $o['precio'] > 0 ? '+' . catPrecio($o['precio']) : 'Sobre pedido' ?></span>
                </button>
              <?php endforeach; ?>
            </div>
          </div>
        <?php endif; ?>
        <?php if ($opciones['version']): ?>
          <div class="grupo-config">
            <h3>Versión</h3>
            <p>Paquetes de equipamiento de la marca para este modelo.</p>
            <div class="opciones-config">
              <?php foreach ($opciones['version'] as $i => $o): ?>
                <label class="opcion-config"><input type="radio" name="version" value="<?= $o['id'] ?>" data-nombre="<?= e($o['nombre']) ?>" data-precio="<?= $o['precio'] ?>" <?= $i === 0 ? 'checked' : '' ?>>
                  <span class="info"><strong><?= e($o['nombre']) ?></strong><small><?= e($o['descripcion']) ?></small></span>
                  <span class="precio-opcion" translate="no"><?= $o['precio'] > 0 ? '+' . catPrecio($o['precio']) : 'Incluido' ?></span></label>
              <?php endforeach; ?>
            </div>
          </div>
        <?php endif; ?>
        <?php if ($opciones['equipamiento']): ?>
          <div class="grupo-config">
            <h3>Equipamiento opcional</h3>
            <p>Agrega los opcionales que quieras incluir en tu cotización.</p>
            <div class="opciones-config">
              <?php foreach ($opciones['equipamiento'] as $o): ?>
                <label class="opcion-config"><input type="checkbox" name="equipamiento" value="<?= $o['id'] ?>" data-nombre="<?= e($o['nombre']) ?>" data-precio="<?= $o['precio'] ?>">
                  <span class="info"><strong><?= e($o['nombre']) ?></strong><small><?= e($o['descripcion']) ?></small></span>
                  <span class="precio-opcion" translate="no">+<?= catPrecio($o['precio']) ?></span></label>
              <?php endforeach; ?>
            </div>
          </div>
        <?php endif; ?>
      </div>
      <aside class="resumen-config" aria-live="polite">
        <h3>Tu configuración</h3>
        <div class="linea-resumen"><span>Precio base</span><strong translate="no"><?= e($p['precioTexto']) ?></strong></div>
        <div class="linea-resumen"><span id="resColorNombre">Color: <?= e($p['color'] ?? '') ?></span><strong id="resColorPrecio" translate="no">$0</strong></div>
        <div class="linea-resumen"><span id="resVersionNombre">Versión</span><strong id="resVersionPrecio" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Equipamiento</span><strong id="resEquipo" translate="no">$0</strong></div>
        <div class="linea-resumen linea-resumen--total"><span>Precio estimado</span><strong id="resTotal" translate="no"><?= e($p['precioTexto']) ?></strong></div>
        <p class="texto-3" style="font-size:12.5px;">Precio estimado de referencia. La cotización final la confirma tu asesor en la cita.</p>
        <a class="btn btn--primario btn--bloque" id="btnCotizar" href="agendar.php?tipo=visita&id=<?= $p['id'] ?>"><?= icono('calendario') ?> Agendar cita con esta configuración</a>
        <a class="btn btn--secundario btn--bloque" href="#financiamiento" id="btnSimularConfig"><?= icono('porcentaje') ?> Simular crédito</a>
      </aside>
    </div>
  </div>
</section>

<!-- ===== ESPECIFICACIONES ===== -->
<section class="seccion" id="especificaciones">
  <div class="contenedor">
    <div class="titulo-seccion"><div><span class="mayus">Ficha técnica</span><h2>Especificaciones</h2><p>Datos de referencia del modelo registrados en el inventario de KARMA.</p></div></div>
    <div class="ficha-tecnica">
      <?php foreach ($ficha as $etiqueta => $valor): if ($valor === null || $valor === '') continue; ?>
        <div class="fila-ficha"><span><?= e($etiqueta) ?></span><strong translate="no"><?= e((string)$valor) ?></strong></div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<!-- ===== FINANCIAMIENTO ===== -->
<section class="seccion seccion--alt" id="financiamiento">
  <div class="contenedor">
    <div class="titulo-seccion">
      <div><span class="mayus">KARMA Financial</span><h2>Simula tu financiamiento</h2><p>Calculado con el precio de tu configuración. Tasa fija anual de referencia de <?= CAT_TASA_ANUAL ?>% y comisión por apertura de <?= CAT_COMISION_APERTURA * 100 ?>%, igual que en caja.</p></div>
      <a class="btn btn--secundario" href="financiamiento.php?codigo=<?= e($p['codigo']) ?>#simulador">Simulador completo <?= icono('flecha', 'icono flecha') ?></a>
    </div>
    <div class="simulador" id="simuladorVehiculo">
      <div class="simulador-entradas">
        <div class="control-rango">
          <div class="fila"><span class="etiqueta-campo">Precio a financiar</span><output id="svPrecio" translate="no"><?= e($p['precioTexto']) ?></output></div>
        </div>
        <div class="control-rango">
          <div class="fila"><label for="svEnganche">Enganche</label><output id="svEngancheTxt" translate="no">20%</output></div>
          <input type="range" id="svEnganche" min="10" max="70" step="5" value="20">
        </div>
        <div class="control-rango">
          <span class="etiqueta-campo">Plazo</span>
          <div class="botones-plazo" id="svPlazos"><?php foreach (CAT_PLAZOS as $pl): ?><button type="button" data-plazo="<?= $pl ?>" class="<?= $pl === 48 ? 'activo' : '' ?>"><?= $pl ?> meses</button><?php endforeach; ?></div>
        </div>
        <button class="btn btn--fantasma" type="button" id="svTabla"><?= icono('grafica') ?> Ver tabla de amortización</button>
        <div id="svTablaCaja"></div>
      </div>
      <div class="simulador-resultado">
        <span class="mayus">Mensualidad estimada</span>
        <div class="mensualidad" id="svMensualidad" translate="no">$0</div>
        <div class="linea-resumen"><span>Enganche</span><strong id="svEngancheMonto" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Comisión por apertura</span><strong id="svComision" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Monto financiado</span><strong id="svFinanciado" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Intereses totales</span><strong id="svIntereses" translate="no">$0</strong></div>
        <div class="linea-resumen linea-resumen--total"><span>Total a pagar</span><strong id="svTotal" translate="no">$0</strong></div>
        <a class="btn btn--claro" id="svSolicitar" href="agendar.php?tipo=visita&id=<?= $p['id'] ?>"><?= icono('calendario') ?> Agendar cita con esta simulación</a>
        <p class="nota">Simulación informativa sujeta a aprobación de crédito. No constituye una oferta vinculante.</p>
      </div>
    </div>
  </div>
</section>

<!-- ===== REFACCIONES Y ACCESORIOS COMPATIBLES ===== -->
<?php if ($compatibles): ?>
<section class="seccion" id="compatibles">
  <div class="contenedor" id="carruselCompatibles">
    <div class="titulo-seccion">
      <div><span class="mayus">Para tu <span translate="no"><?= e($p['marca']) ?></span></span><h2>Refacciones y accesorios</h2><p>Piezas y accesorios de <?= e($p['marca']) ?> disponibles para compra en línea en <?= e($sucursal['nombre']) ?>.</p></div>
      <div class="carrusel-flechas"><button type="button" aria-label="Anteriores"><?= icono('chevron-izq') ?></button><button type="button" aria-label="Siguientes"><?= icono('chevron-der') ?></button></div>
    </div>
    <div class="carrusel-pista" id="pistaCompatibles"></div>
  </div>
</section>
<?php endif; ?>

<section class="seccion--compacta">
  <div class="contenedor">
    <div class="cta-final cta-final--vehiculo">
      <img src="<?= e($imagen) ?>" alt="" loading="lazy" width="1280" height="800">
      <div class="contenido">
        <h2>Conoce el <span translate="no"><?= e($p['titulo']) ?></span> en persona</h2>
        <p>Agenda una cita en KARMA <?= e($sucursal['nombre']) ?>: un asesor te muestra la unidad, revisa tu crédito y te ayuda a apartarla.</p>
        <div class="fila fila--envolver">
          <a class="btn btn--claro btn--grande" href="agendar.php?tipo=visita&id=<?= $p['id'] ?>"><?= icono('calendario') ?> Agendar cita</a>
          <a class="btn btn--contorno-claro btn--grande" href="agendar.php?tipo=apartado&id=<?= $p['id'] ?>">Apartar unidad</a>
        </div>
      </div>
    </div>
  </div>
</section>

<script type="application/json" id="datosProducto"><?= json_encode([
    'producto' => $p, 'compatibles' => $compatibles, 'tiene3D' => $tiene3D,
    'visor3D' => catVersion('JavaScript/PuntoDeVenta/vista_previa_3d.js')
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?></script>
<?php catPie(['scripts' => ['producto.js']]); ?>
