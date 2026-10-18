<?php
declare(strict_types=1);
/* KARMA · Catálogo — Créditos de imágenes (lee assets/Catalogo/creditos.json: autor, licencia y fuente de cada foto) */
require_once __DIR__ . '/includes/layout.php';
$creditos = (json_decode((string)@file_get_contents(dirname(__DIR__, 2) . '/assets/Catalogo/creditos.json'), true) ?: []) + ['fotografias' => [], 'renders_propios' => [], 'propias' => []];
catCabecera(['titulo' => 'Créditos de imágenes', 'activo' => '']);
?>
<section class="cabecera-pagina"><div class="contenedor"><ol class="migas"><li><a href="index.php">Inicio</a></li><li>Créditos de imágenes</li></ol><h1>Créditos de imágenes</h1>
  <p>Las fotografías de vehículos, sucursales y accesorios las proporcionó el equipo KARMA; las demás provienen de Wikimedia Commons con licencias libres (CC0, CC BY y CC BY-SA). Todas se usan con fines académicos y se convirtieron a WebP. Este sitio no es oficial de ninguna marca.</p></div></section>
<section class="seccion--compacta"><div class="contenedor">
  <div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Imagen</th><th>Archivo en el proyecto</th><th>Autor</th><th>Licencia</th><th>Fuente</th></tr></thead>
    <tbody>
      <?php foreach ($creditos['fotografias'] as $c): ?>
        <tr>
          <td><img src="<?= catAsset($c['archivo']) ?>" alt="" loading="lazy" style="width:88px; height:56px; object-fit:cover; border-radius:4px;"></td>
          <td translate="no" style="font-size:13px;"><?= e($c['archivo']) ?></td>
          <td><?= e($c['autor']) ?></td>
          <td><?= $c['licencia_url'] ? '<a class="enlace" href="' . e($c['licencia_url']) . '" target="_blank" rel="noopener">' . e($c['licencia']) . '</a>' : e($c['licencia']) ?></td>
          <td><a class="enlace" href="<?= e($c['fuente']) ?>" target="_blank" rel="noopener">Wikimedia Commons</a></td>
        </tr>
      <?php endforeach; ?>
    </tbody>
  </table></div>
  <?php if ($creditos['propias']): ?>
    <h2 style="font-size:22px; margin:36px 0 10px;">Fotografías del equipo KARMA</h2>
    <p class="texto-2" style="margin-bottom:16px;"><?= count($creditos['propias']) ?> imágenes de vehículos, sucursales y accesorios proporcionadas por el equipo del proyecto; se les quitó el fondo y se ajustaron a un encuadre uniforme.</p>
    <div class="galeria-creditos">
      <?php foreach ($creditos['propias'] as $archivo): ?>
        <img src="<?= catAsset($archivo) ?>" alt="" loading="lazy" title="<?= e($archivo) ?>" width="160" height="100">
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
  <h2 style="font-size:22px; margin:36px 0 10px;">Renders propios</h2>
  <p class="texto-2">Las <?= count($creditos['renders_propios']) ?> imágenes de refacciones son renders generados para este proyecto con el visor 3D del Punto de Venta, usando el color registrado de cada pieza en la base de datos.</p>
</div></section>
<?php catPie(); ?>
