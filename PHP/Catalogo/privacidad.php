<?php
declare(strict_types=1);
/* KARMA · Catálogo — Aviso de privacidad (texto de demostración para el proyecto académico) */
require_once __DIR__ . '/includes/layout.php';
catCabecera(['titulo' => 'Aviso de privacidad', 'activo' => '']);
?>
<section class="cabecera-pagina"><div class="contenedor"><ol class="migas"><li><a href="index.php">Inicio</a></li><li>Aviso de privacidad</li></ol><h1>Aviso de privacidad</h1><p>Documento de demostración del proyecto integrador KARMA.</p></div></section>
<section class="seccion--compacta"><div class="contenedor contenedor--angosto pila" style="font-size:16px; line-height:1.75;">
  <p class="aviso-demo"><?= icono('info') ?><span>Este aviso es un texto de ejemplo para un proyecto académico. No sustituye un aviso de privacidad legal.</span></p>
  <h2 style="font-size:22px; margin-top:24px;">Responsable</h2>
  <p class="texto-2">KARMA Concesionario (proyecto académico), con sucursales en Manzanillo y Colima, es responsable del tratamiento de los datos que proporcionas en este sitio.</p>
  <h2 style="font-size:22px; margin-top:24px;">Datos que recabamos</h2>
  <p class="texto-2">Nombre, apellidos, correo electrónico, teléfono, dirección, sucursal preferida, preferencias de notificación, información de pedidos, citas y solicitudes. La contraseña se guarda únicamente como un hash seguro (bcrypt) y nadie puede consultarla. De las tarjetas en el pago simulado solo se guardan la marca y los últimos 4 dígitos.</p>
  <h2 style="font-size:22px; margin-top:24px;">Finalidades</h2>
  <p class="texto-2">Gestionar tu cuenta, pedidos de refacciones y accesorios, citas de visita, apartado y servicio de taller, simulaciones de crédito y atención a clientes, así como enviarte novedades si lo autorizas.</p>
  <h2 style="font-size:22px; margin-top:24px;">Derechos ARCO</h2>
  <p class="texto-2">Puedes acceder, rectificar, cancelar u oponerte al uso de tus datos desde tu perfil o escribiéndonos en la página de <a class="enlace" href="contacto.php">contacto</a>.</p>
</div></section>
<?php catPie(); ?>
