<?php
declare(strict_types=1);
/* KARMA · Catálogo — resultados de búsqueda en vehículos, refacciones, accesorios y páginas */
require_once __DIR__ . '/includes/layout.php';

$q = trim((string)($_GET['q'] ?? ''));
catCabecera(['titulo' => $q !== '' ? "Resultados para «{$q}»" : 'Buscar', 'activo' => '']);
?>
<section class="cabecera-pagina">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Búsqueda</li></ol>
    <h1>Buscar en el catálogo</h1>
    <form class="campo-busqueda" action="buscar.php" method="get" role="search" style="margin-top:22px; max-width:760px;">
      <?= icono('buscar') ?>
      <input type="search" name="q" id="entradaBusquedaPagina" placeholder="Modelo, marca, pieza, código o motor…" aria-label="Buscar" autocomplete="off">
      <button class="btn btn--primario" type="submit">Buscar</button>
    </form>
    <p class="texto-2" id="contadorBusqueda" style="margin-top:16px;" aria-live="polite"></p>
  </div>
</section>
<div class="contenedor" style="padding-top:32px; padding-bottom:32px;">
  <div id="resultadosBusqueda"></div>
</div>
<?php catPie(['scripts' => ['catalogo.js']]); ?>
