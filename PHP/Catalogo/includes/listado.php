<?php
declare(strict_types=1);

/* KARMA · Catálogo — plantilla de las páginas de listado (Modelos, Refacciones, Accesorios).
   Los productos se cargan con api.php?action=productos (inventario de la sucursal elegida) y
   JavaScript/Catalogo/catalogo.js filtra, ordena y pinta la cuadrícula sin recargar la página. */

require_once __DIR__ . '/layout.php';

function catPaginaListado(array $c): void {
    $sucursal = catSucursalActual();
    $valores = catValoresFiltro($c['seccion']);
    catCabecera(['titulo' => $c['titulo'], 'activo' => $c['activo'], 'descripcion' => $c['descripcion'] ?? null]);
    ?>
<section class="cabecera-pagina">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li><?= e($c['titulo']) ?></li></ol>
    <h1><?= e($c['titulo']) ?></h1>
    <p><?= e($c['intro']) ?></p>
    <div class="pestanas-marca" id="pestanasMarca" role="tablist" aria-label="Filtrar por marca">
      <button class="chip activo" type="button" data-marca="">Todas</button>
      <?php foreach (CAT_MARCAS as $m): ?><button class="chip" type="button" data-marca="<?= e($m) ?>" translate="no"><?= e($m) ?></button><?php endforeach; ?>
    </div>
  </div>
</section>

<div class="contenedor">
  <div class="catalogo">
    <!-- ===== FILTROS ===== -->
    <aside class="filtros" id="panelFiltros" aria-label="Filtros">
      <div class="filtros-cabeza">
        <h2>Filtros</h2>
        <div class="fila">
          <button class="btn btn--fantasma btn--chico" type="button" id="limpiarFiltros">Limpiar</button>
          <button class="btn-icono btn-filtros-movil" type="button" data-cerrar-filtros aria-label="Cerrar filtros"><?= icono('cerrar') ?></button>
        </div>
      </div>
      <div class="grupo-filtro">
        <label class="interruptor"><span>Solo con unidades en <strong translate="no"><?= e($sucursal['nombre']) ?></strong></span><input type="checkbox" id="fDisponible"><span class="pista"></span></label>
      </div>
      <?php if ($c['seccion'] === 'vehiculos'): ?>
        <div class="grupo-filtro"><h3>Tipo</h3><div data-faceta="tipo"></div></div>
        <div class="grupo-filtro"><h3>Carrocería / estilo</h3><div data-faceta="subcategoria"></div></div>
        <div class="grupo-filtro"><h3>Motorización</h3><div data-faceta="motorizacion"></div></div>
        <div class="grupo-filtro"><h3>Tracción</h3><div data-faceta="traccion"></div></div>
        <div class="grupo-filtro"><h3>Año</h3><div data-faceta="anio"></div></div>
      <?php else: ?>
        <div class="grupo-filtro">
          <h3>Vehículo compatible</h3>
          <div class="campo"><label class="solo-lector" for="fModelo">Modelo compatible</label>
            <select id="fModelo"><option value="">Todos los modelos</option></select>
          </div>
        </div>
        <div class="grupo-filtro"><h3><?= $c['seccion'] === 'accesorios' ? 'Tipo de accesorio' : 'Categoría' ?></h3><div data-faceta="subcategoria"></div></div>
      <?php endif; ?>
      <div class="grupo-filtro">
        <h3>Precio (MXN)</h3>
        <div class="rango-precio">
          <div class="campo"><label class="solo-lector" for="fPrecioMin">Precio mínimo</label><input type="number" id="fPrecioMin" placeholder="Mínimo" min="0" step="1000" inputmode="numeric"></div>
          <div class="campo"><label class="solo-lector" for="fPrecioMax">Precio máximo</label><input type="number" id="fPrecioMax" placeholder="Máximo" min="0" step="1000" inputmode="numeric"></div>
        </div>
      </div>
      <button class="btn btn--primario btn--bloque btn-filtros-movil" type="button" data-cerrar-filtros style="margin-top:18px;" id="verResultadosMovil">Ver resultados</button>
    </aside>

    <!-- ===== RESULTADOS ===== -->
    <section aria-label="Resultados">
      <div class="aviso-sucursal">
        <?= icono('ubicacion') ?>
        <span>Mostrando el inventario de <strong translate="no">KARMA <?= e($sucursal['nombre']) ?></strong>. La disponibilidad cambia por sucursal.</span>
        <button class="btn btn--fantasma btn--chico" type="button" data-abrir-sucursales>Cambiar sucursal</button>
      </div>
      <div class="barra-resultados">
        <div class="contador-resultados" id="contadorResultados" aria-live="polite">Cargando…</div>
        <div class="derecha">
          <button class="btn btn--secundario btn--chico btn-filtros-movil" type="button" id="abrirFiltros"><?= icono('filtro', 'icono icono--chico') ?> Filtros</button>
          <div class="buscador-catalogo campo">
            <?= icono('buscar', 'icono icono--chico') ?>
            <label class="solo-lector" for="fTexto">Buscar</label>
            <input type="search" id="fTexto" placeholder="<?= e($c['placeholder']) ?>" autocomplete="off">
          </div>
          <div class="campo">
            <label class="solo-lector" for="fOrden">Ordenar</label>
            <select id="fOrden">
              <option value="">Recomendados</option>
              <option value="precio_asc">Precio: menor a mayor</option>
              <option value="precio_desc">Precio: mayor a menor</option>
              <?php if ($c['seccion'] === 'vehiculos'): ?><option value="anio_desc">Año más reciente</option><?php endif; ?>
              <option value="disponibles">Más unidades disponibles</option>
              <option value="nombre">Nombre (A-Z)</option>
            </select>
          </div>
        </div>
      </div>
      <div class="filtros-activos" id="filtrosActivos"></div>
      <div class="rejilla" id="rejillaProductos"></div>
    </section>
  </div>
</div>

<script type="application/json" id="configListado"><?= json_encode([
    'seccion' => $c['seccion'],
    'modelos' => $valores['modelos'],
    'sucursal' => $sucursal['nombre']
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?></script>
<?php
    catPie(['scripts' => ['catalogo.js']]);
}
