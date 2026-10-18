<?php
declare(strict_types=1);
/* KARMA · Catálogo — Términos y condiciones (texto de demostración) */
require_once __DIR__ . '/includes/layout.php';
catCabecera(['titulo' => 'Términos y condiciones', 'activo' => '']);
?>
<section class="cabecera-pagina"><div class="contenedor"><ol class="migas"><li><a href="index.php">Inicio</a></li><li>Términos y condiciones</li></ol><h1>Términos y condiciones</h1><p>Condiciones de uso del sitio de demostración KARMA.</p></div></section>
<section class="seccion--compacta"><div class="contenedor contenedor--angosto pila" style="font-size:16px; line-height:1.75;">
  <p class="aviso-demo"><?= icono('info') ?><span>Sitio de demostración de un proyecto académico. Audi, Porsche y Ducati son marcas de sus respectivos propietarios; este sitio no está afiliado a ellas.</span></p>
  <h2 style="font-size:22px; margin-top:24px;">Precios y disponibilidad</h2>
  <p class="texto-2">Los precios se muestran en pesos mexicanos con IVA incluido. La disponibilidad corresponde al inventario de la sucursal elegida y se confirma al momento de comprar o agendar.</p>
  <h2 style="font-size:22px; margin-top:24px;">Compras en línea</h2>
  <p class="texto-2">Refacciones y accesorios pueden comprarse en dos modalidades: <strong>recoger en sucursal con pago en efectivo</strong> (las piezas se apartan y se cobran en caja) o <strong>envío a domicilio con pago con tarjeta</strong>. El pago con tarjeta de este sitio es una <strong>simulación</strong>: no se realiza ningún cargo real.</p>
  <h2 style="font-size:22px; margin-top:24px;">Vehículos</h2>
  <p class="texto-2">Los vehículos no se venden en línea: puedes agendar una cita o solicitar el apartado de una unidad. La operación se concreta con un asesor en sucursal.</p>
  <h2 style="font-size:22px; margin-top:24px;">Crédito</h2>
  <p class="texto-2">El simulador de crédito es informativo y no constituye una oferta de crédito. La tasa, la comisión por apertura y las condiciones finales las confirma tu asesor.</p>
</div></section>
<?php catPie(); ?>
