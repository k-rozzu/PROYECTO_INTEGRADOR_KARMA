<?php
declare(strict_types=1);
/* KARMA · Catálogo — Inicio */
require_once __DIR__ . '/includes/layout.php';

$sucursal = catSucursalActual();
$vehiculos = catBuscarProductos(['seccion' => ['vehiculos']]);
$destacados = array_values(array_filter($vehiculos, fn($p) => $p['destacado']));
$conteoMarca = array_count_values(array_column($vehiculos, 'marca'));
$disponiblesAqui = count(array_filter($vehiculos, fn($p) => $p['stock'] > 0));
$cliente = catClienteActual();
$favoritos = catFavoritosIds($cliente ? (int)$cliente['id_cliente'] : null);

// IMÁGENES DEL CARRUSEL PRINCIPAL: cambia las rutas aquí (assets/Catalogo/banners/)
$slides = [
    ['marca' => 'Audi', 'imagen' => 'assets/Catalogo/banners/hero-audi.webp', 'titulo' => 'Tecnología que se conduce',
     'texto' => 'Del A3 al R8: tracción quattro, interiores digitales y diseño progresivo. Descubre la gama Audi en KARMA.',
     'cta1' => ['Ver modelos Audi', 'vehiculos.php?marca=Audi'], 'cta2' => ['Agendar cita', 'agendar.php?tipo=visita']],
    ['marca' => 'Porsche', 'imagen' => 'assets/Catalogo/banners/hero-porsche.webp', 'titulo' => 'Deportividad sin concesiones',
     'texto' => '911, Taycan, Cayenne y más. Configura tu Porsche, simula tu crédito y agenda tu cita en Manzanillo o Colima.',
     'cta1' => ['Ver modelos Porsche', 'vehiculos.php?marca=Porsche'], 'cta2' => ['Simular crédito', 'financiamiento.php']],
    ['marca' => 'Ducati', 'imagen' => 'assets/Catalogo/banners/hero-ducati.webp', 'titulo' => 'Pasión sobre dos ruedas',
     'texto' => 'Superdeportivas, naked y adventure. Encuentra la Ducati hecha para tu estilo y llévala a la pista o a la carretera.',
     'cta1' => ['Ver motocicletas Ducati', 'vehiculos.php?marca=Ducati'], 'cta2' => ['Apartar vehículo', 'agendar.php?tipo=apartado']],
];
// IMÁGENES DEL MOSAICO DE MARCAS: un vehículo representativo por marca
$mosaico = [
    'Audi' => ['imagen' => 'assets/Catalogo/vehiculos/audi/rs6.webp', 'texto' => 'Sedanes, SUV y deportivos RS con tracción quattro.'],
    'Porsche' => ['imagen' => 'assets/Catalogo/vehiculos/porsche/911-carrera.webp', 'texto' => 'El 911, el Taycan eléctrico y las SUV más deportivas.'],
    'Ducati' => ['imagen' => 'assets/Catalogo/vehiculos/ducati/panigale-v4.webp', 'texto' => 'Superdeportivas, naked, adventure y scrambler.'],
];

catCabecera(['titulo' => 'Inicio', 'activo' => 'inicio',
    'descripcion' => 'KARMA Concesionario: Audi, Porsche y Ducati en Manzanillo y Colima. Explora modelos, simula tu crédito, agenda tu cita y aparta tu vehículo.']);
?>

<!-- ===== HÉROE: carrusel por marca ===== -->
<section class="heroe" id="heroe" aria-roledescription="carrusel" aria-label="Marcas de KARMA">
  <?php foreach ($slides as $i => $s): ?>
    <div class="heroe-slide<?= $i === 0 ? ' activo' : '' ?>" role="group" aria-roledescription="diapositiva" aria-label="<?= $i + 1 ?> de <?= count($slides) ?>">
      <img src="<?= catAsset($s['imagen']) ?>" alt="" <?= $i === 0 ? 'fetchpriority="high"' : 'loading="lazy"' ?> width="1920" height="960">
      <div class="heroe-contenido">
        <div class="contenedor">
          <div class="heroe-texto">
            <span class="mayus" translate="no"><?= e($s['marca']) ?> · KARMA <?= e($sucursal['nombre']) ?></span>
            <h1><?= e($s['titulo']) ?></h1>
            <p><?= e($s['texto']) ?></p>
            <div class="fila">
              <a class="btn btn--claro btn--grande" href="<?= e($s['cta1'][1]) ?>"><?= e($s['cta1'][0]) ?> <?= icono('flecha', 'icono flecha') ?></a>
              <a class="btn btn--contorno-claro btn--grande" href="<?= e($s['cta2'][1]) ?>"><?= e($s['cta2'][0]) ?></a>
            </div>
          </div>
        </div>
      </div>
    </div>
  <?php endforeach; ?>
  <div class="heroe-controles">
    <div class="contenedor">
      <div class="heroe-indicadores">
        <?php foreach ($slides as $i => $s): ?>
          <button class="heroe-indicador<?= $i === 0 ? ' activo' : '' ?>" type="button" data-slide="<?= $i ?>" aria-label="Ver <?= e($s['marca']) ?>"><span translate="no"><?= e($s['marca']) ?></span></button>
        <?php endforeach; ?>
      </div>
      <button class="heroe-pausa" type="button" id="heroePausa" aria-label="Pausar carrusel"><?= icono('pausa', 'icono icono--chico') ?></button>
    </div>
  </div>
</section>

<!-- ===== BUSCADOR RÁPIDO ===== -->
<section class="buscador-rapido" aria-label="Encuentra tu vehículo">
  <div class="contenedor">
    <form id="buscadorRapido" action="vehiculos.php" method="get">
      <div class="titulo-buscador">Encuentra<br>tu vehículo</div>
      <div class="campo">
        <label for="brMarca">Marca</label>
        <select id="brMarca" name="marca">
          <option value="">Todas las marcas</option>
          <?php foreach (CAT_MARCAS as $m): ?><option value="<?= e($m) ?>"><?= e($m) ?></option><?php endforeach; ?>
        </select>
      </div>
      <div class="campo">
        <label for="brTipo">Tipo</label>
        <select id="brTipo" name="tipo">
          <option value="">Autos y motos</option>
          <option value="auto">Automóviles</option>
          <option value="moto">Motocicletas</option>
        </select>
      </div>
      <div class="campo">
        <label for="brPrecio">Precio máximo</label>
        <select id="brPrecio" name="precio_max">
          <option value="">Sin límite</option>
          <option value="500000">Hasta $500,000</option>
          <option value="1000000">Hasta $1,000,000</option>
          <option value="2000000">Hasta $2,000,000</option>
          <option value="3000000">Hasta $3,000,000</option>
        </select>
      </div>
      <button class="btn btn--primario btn--grande" type="submit" id="brBoton">Ver <?= count($vehiculos) ?> modelos <?= icono('flecha', 'icono flecha') ?></button>
    </form>
  </div>
</section>

<!-- ===== MARCAS ===== -->
<section class="seccion">
  <div class="contenedor">
    <div class="titulo-seccion revelar">
      <div>
        <span class="mayus">Nuestras marcas</span>
        <h2>Tres marcas, una misma pasión</h2>
        <p>Vehículos nuevos de Audi y Porsche y motocicletas Ducati con inventario real en Manzanillo y Colima. Hoy hay <strong><?= $disponiblesAqui ?> modelos con unidades disponibles</strong> en <?= e($sucursal['nombre']) ?>.</p>
      </div>
      <a class="btn btn--secundario" href="vehiculos.php">Ver todos los modelos <?= icono('flecha', 'icono flecha') ?></a>
    </div>
    <div class="mosaico-marcas">
      <?php foreach ($mosaico as $marca => $m): ?>
        <a class="mosaico-marca revelar" href="vehiculos.php?marca=<?= e($marca) ?>">
          <img src="<?= catAsset($m['imagen']) ?>" alt="<?= e($marca) ?>" loading="lazy" width="600" height="750">
          <div class="texto">
            <h3 translate="no"><?= e($marca) ?></h3>
            <p><?= e($m['texto']) ?> <?= (int)($conteoMarca[$marca] ?? 0) ?> modelos.</p>
            <span class="ir">Explorar <?= icono('flecha', 'icono flecha') ?></span>
          </div>
        </a>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<!-- ===== MODELOS DESTACADOS ===== -->
<section class="seccion seccion--alt">
  <div class="contenedor" id="seccionDestacados">
    <div class="titulo-seccion revelar">
      <div>
        <span class="mayus">Modelos destacados</span>
        <h2>Elegidos para ti</h2>
        <div class="pestanas-marca" id="pestanasDestacados" role="tablist">
          <button class="chip activo" type="button" data-marca="">Todos</button>
          <?php foreach (CAT_MARCAS as $m): ?><button class="chip" type="button" data-marca="<?= e($m) ?>" translate="no"><?= e($m) ?></button><?php endforeach; ?>
        </div>
      </div>
      <div class="carrusel-flechas" id="flechasDestacados">
        <button type="button" aria-label="Anteriores"><?= icono('chevron-izq') ?></button>
        <button type="button" aria-label="Siguientes"><?= icono('chevron-der') ?></button>
      </div>
    </div>
    <div class="carrusel" id="carruselDestacados">
      <div class="carrusel-pista" id="pistaDestacados"></div>
    </div>
  </div>
</section>

<!-- ===== SERVICIOS DEL CONCESIONARIO ===== -->
<section class="seccion">
  <div class="contenedor">
    <div class="titulo-seccion revelar">
      <div>
        <span class="mayus">Concesionario KARMA</span>
        <h2>Todo lo que tu vehículo necesita</h2>
        <p>Elige tu próximo auto o moto, simula tu crédito, agenda tu cita y apártalo. Nosotros nos encargamos de seguros, trámites y postventa.</p>
      </div>
    </div>
    <div class="beneficios revelar">
      <a class="beneficio" href="vehiculos.php"><span class="icono-caja"><?= icono('auto') ?></span><h3>Ver modelos</h3><p>Audi, Porsche y Ducati nuevos con inventario real en cada sucursal.</p><span class="enlace">Ver modelos <?= icono('flecha', 'icono icono--chico') ?></span></a>
      <a class="beneficio" href="financiamiento.php"><span class="icono-caja"><?= icono('porcentaje') ?></span><h3>Simular crédito</h3><p>Calcula tu mensualidad con la misma tasa y comisión por apertura de nuestras cajas.</p><span class="enlace">Simular <?= icono('flecha', 'icono icono--chico') ?></span></a>
      <a class="beneficio" href="agendar.php?tipo=visita"><span class="icono-caja"><?= icono('calendario') ?></span><h3>Agendar cita</h3><p>Elige sucursal, fecha y hora. Un asesor te atiende con la unidad lista.</p><span class="enlace">Agendar <?= icono('flecha', 'icono icono--chico') ?></span></a>
      <a class="beneficio" href="agendar.php?tipo=apartado"><span class="icono-caja"><?= icono('etiqueta') ?></span><h3>Apartar vehículo</h3><p>Reserva una unidad del inventario de tu sucursal y define tu enganche.</p><span class="enlace">Apartar <?= icono('flecha', 'icono icono--chico') ?></span></a>
      <a class="beneficio" href="servicios.php#seguros"><span class="icono-caja"><?= icono('escudo') ?></span><h3>Seguros y garantía extendida</h3><p>Cobertura amplia, vida y desempleo, llantas y rines, y garantía extendida.</p><span class="enlace">Conocer más <?= icono('flecha', 'icono icono--chico') ?></span></a>
      <a class="beneficio" href="servicios.php#tramites"><span class="icono-caja"><?= icono('documento') ?></span><h3>Trámites y taller</h3><p>Placas, ISAN, tenencia, verificación, mantenimiento prepagado y orden de servicio.</p><span class="enlace">Ver servicios <?= icono('flecha', 'icono icono--chico') ?></span></a>
    </div>
  </div>
</section>

<!-- ===== POSTVENTA ===== -->
<section class="seccion seccion--alt">
  <div class="contenedor dividido">
    <div class="media revelar">
      <!-- IMAGEN DE POSTVENTA: assets/Catalogo/servicios/mantenimiento.webp -->
      <img src="<?= catAsset('assets/Catalogo/servicios/mantenimiento.webp') ?>" alt="Técnico trabajando en el taller de servicio" loading="lazy" width="1200" height="800">
    </div>
    <div class="revelar">
      <span class="mayus texto-3">Servicio postventa</span>
      <h2 class="titulo-dividido">Postventa hecha por especialistas</h2>
      <p class="texto-2 texto-dividido">Abre tu orden de servicio de taller para tu Audi, Porsche o Ducati en Manzanillo o Colima, con refacciones originales y un asesor que te mantiene informado en cada paso.</p>
      <ul class="lista-check">
        <li>Orden de servicio de taller</li>
        <li>Plan de mantenimiento prepagado</li>
        <li>Garantía extendida</li>
        <li>Accesorios originales e instalación, película de seguridad y polarizado</li>
      </ul>
      <div class="fila fila--envolver" style="margin-top:28px;">
        <a class="btn btn--primario" href="agendar.php?tipo=servicio"><?= icono('calendario') ?> Orden de servicio</a>
        <a class="btn btn--secundario" href="servicios.php#postventa">Ver servicios</a>
      </div>
    </div>
  </div>
</section>

<!-- ===== FINANCIAMIENTO (mini simulador) ===== -->
<section class="seccion seccion--alt">
  <div class="contenedor">
    <div class="titulo-seccion revelar">
      <div>
        <span class="mayus">KARMA Financial</span>
        <h2>Calcula tu mensualidad</h2>
        <p>Ajusta el precio, el enganche y el plazo. Usamos la misma tasa y comisión del módulo de crédito de nuestras cajas.</p>
      </div>
      <a class="btn btn--secundario" href="financiamiento.php">Simulador completo <?= icono('flecha', 'icono flecha') ?></a>
    </div>
    <div class="simulador revelar" id="miniSimulador">
      <div class="simulador-entradas">
        <div class="control-rango">
          <div class="fila"><label for="msPrecio">Precio del vehículo</label><output id="msPrecioTxt" translate="no">$1,500,000</output></div>
          <input type="range" id="msPrecio" min="250000" max="4500000" step="10000" value="1500000">
        </div>
        <div class="control-rango">
          <div class="fila"><label for="msEnganche">Enganche</label><output id="msEngancheTxt" translate="no">20%</output></div>
          <input type="range" id="msEnganche" min="10" max="70" step="5" value="20">
        </div>
        <div class="control-rango">
          <span class="etiqueta-campo">Plazo</span>
          <div class="botones-plazo" id="msPlazos">
            <?php foreach (CAT_PLAZOS as $pl): ?><button type="button" data-plazo="<?= $pl ?>" class="<?= $pl === 48 ? 'activo' : '' ?>"><?= $pl ?> meses</button><?php endforeach; ?>
          </div>
        </div>
      </div>
      <div class="simulador-resultado">
        <span class="mayus">Mensualidad estimada</span>
        <div class="mensualidad" id="msMensualidad" translate="no">$0</div>
        <div class="linea-resumen"><span>Monto a financiar</span><strong id="msFinanciar" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Tasa anual fija de referencia</span><strong translate="no"><?= CAT_TASA_ANUAL ?>%</strong></div>
        <a class="btn btn--claro" href="financiamiento.php" id="msEnlace">Ver detalle de mi crédito</a>
        <p class="nota">Simulación informativa. No constituye una oferta ni aprobación de crédito.</p>
      </div>
    </div>
  </div>
</section>

<!-- ===== REFACCIONES POR VEHÍCULO ===== -->
<section class="seccion">
  <div class="contenedor dividido">
    <div class="revelar">
      <span class="mayus texto-3">Refacciones y accesorios</span>
      <h2 class="titulo-dividido">Encuentra la pieza exacta para tu vehículo</h2>
      <p class="texto-2 texto-dividido">Filtros, frenos, baterías, distribución y accesorios compatibles. Compra en línea y elige: recoger y pagar en efectivo en tu sucursal, o envío a domicilio con tarjeta.</p>
      <form class="formulario" id="buscadorPiezas" action="refacciones.php" method="get" style="margin-top:26px;">
        <div class="campos">
          <div class="campo">
            <label for="bpMarca">Marca de tu vehículo</label>
            <select id="bpMarca" name="marca"><?php foreach (CAT_MARCAS as $m): ?><option value="<?= e($m) ?>"><?= e($m) ?></option><?php endforeach; ?></select>
          </div>
          <div class="campo">
            <label for="bpModelo">Modelo</label>
            <select id="bpModelo" name="modelo"><option value="">Todos los modelos</option></select>
          </div>
        </div>
        <div class="fila fila--envolver">
          <button class="btn btn--primario" type="submit"><?= icono('buscar') ?> Buscar refacciones</button>
          <a class="btn btn--fantasma" href="accesorios.php">Ver accesorios</a>
        </div>
      </form>
    </div>
    <div class="media media--pieza revelar">
      <!-- IMAGEN DE REFACCIONES: render de assets/Catalogo/refacciones/porsche/disco-delantero.webp -->
      <img src="<?= catAsset('assets/Catalogo/refacciones/porsche/disco-delantero.webp') ?>" alt="Disco de freno" loading="lazy" width="1000" height="750">
    </div>
  </div>
</section>

<!-- ===== SUCURSALES ===== -->
<section class="seccion seccion--alt">
  <div class="contenedor">
    <div class="titulo-seccion revelar">
      <div>
        <span class="mayus">Sucursales</span>
        <h2>Visítanos en Manzanillo o Colima</h2>
        <p>Cada sucursal tiene su propio inventario. Elige la tuya para ver disponibilidad, recoger pedidos y agendar citas.</p>
      </div>
      <a class="btn btn--secundario" href="sucursales.php">Ver sucursales <?= icono('flecha', 'icono flecha') ?></a>
    </div>
    <div class="rejilla rejilla--2">
      <?php foreach (catSucursales() as $s): $actual = $s['id_sucursal'] === $sucursal['id_sucursal']; ?>
        <article class="tarjeta-servicio revelar">
          <div class="media"><img src="<?= catAsset($s['imagen']) ?>" alt="<?= e($s['ciudad'] ?? $s['nombre']) ?>" loading="lazy" width="1200" height="800"></div>
          <div class="cuerpo">
            <div class="fila fila--entre"><h3>KARMA <?= e($s['nombre']) ?></h3><?php if ($actual): ?><span class="etiqueta">Tu sucursal</span><?php endif; ?></div>
            <p><?= icono('ubicacion', 'icono icono--chico') ?> <?= e($s['direccion']) ?></p>
            <p><?= icono('reloj', 'icono icono--chico') ?> <?= e($s['horario_ventas']) ?></p>
          </div>
          <div class="pie-tarjeta">
            <?php if (!$actual): ?><button class="btn btn--primario btn--chico" type="button" data-elegir-sucursal="<?= $s['id_sucursal'] ?>">Elegir esta sucursal</button><?php endif; ?>
            <a class="btn btn--secundario btn--chico" href="https://www.google.com/maps/search/?api=1&query=<?= rawurlencode($s['direccion']) ?>" target="_blank" rel="noopener"><?= icono('mapa', 'icono icono--chico') ?> Cómo llegar</a>
          </div>
        </article>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<!-- ===== LLAMADO A LA ACCIÓN FINAL ===== -->
<section class="seccion">
  <div class="contenedor">
    <div class="cta-final revelar">
      <img src="<?= catAsset('assets/Catalogo/banners/prueba-manejo.webp') ?>" alt="" loading="lazy" width="1920" height="960">
      <div class="contenido">
        <span class="mayus" style="color:rgba(255,255,255,.75)">Agenda tu cita</span>
        <h2>¿Listo para estrenar?</h2>
        <p>Agenda una cita o aparta tu vehículo en minutos. Un asesor te espera con la unidad lista en la sucursal que elijas.</p>
        <div class="fila fila--envolver">
          <a class="btn btn--claro btn--grande" href="agendar.php?tipo=visita"><?= icono('calendario') ?> Agendar cita</a>
          <a class="btn btn--contorno-claro btn--grande" href="agendar.php?tipo=apartado">Apartar vehículo</a>
        </div>
      </div>
    </div>
  </div>
</section>

<script type="application/json" id="datosInicio"><?= json_encode(['vehiculos' => $vehiculos, 'destacados' => $destacados, 'favoritos' => $favoritos], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?></script>
<?php catPie(['scripts' => ['inicio.js']]); ?>
