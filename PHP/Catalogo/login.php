<?php
declare(strict_types=1);
/* KARMA · Catálogo — inicio de sesión de CLIENTES (tabla clientes). No da acceso al Punto de Venta. */
require_once __DIR__ . '/includes/layout.php';

$volver = catVolverSeguro($_GET['volver'] ?? null);
if (catClienteActual()) { header('Location: ' . $volver); exit; }

catCabecera(['titulo' => 'Iniciar sesión', 'activo' => '']);
?>
<section class="acceso">
  <div class="acceso-media">
    <!-- IMAGEN DE ACCESO: assets/Catalogo/banners/hero-porsche.webp -->
    <img src="<?= catAsset('assets/Catalogo/banners/hero-porsche.webp') ?>" alt="" width="1920" height="960">
    <div class="texto">
      <span class="mayus" style="color:rgba(255,255,255,.75)">Mi cuenta KARMA</span>
      <h2>Tu concesionario, siempre contigo</h2>
      <ul class="lista-check">
        <li>Sigue tus pedidos de refacciones y accesorios</li>
        <li>Agenda y administra visitas, pruebas de manejo y servicios</li>
        <li>Guarda tus vehículos de interés</li>
        <li>Consulta tus compras, citas y notificaciones</li>
      </ul>
    </div>
  </div>
  <div class="acceso-panel">
    <div class="acceso-caja">
      <h1>Iniciar sesión</h1>
      <p>Bienvenido de nuevo. Ingresa con el correo y la contraseña de tu cuenta de cliente.</p>
      <form class="formulario" id="formLogin" novalidate data-volver="<?= e($volver) ?>">
        <div class="campo"><label for="lgEmail">Correo electrónico</label><input id="lgEmail" name="email" type="email" required autocomplete="email" maxlength="120"></div>
        <div class="campo">
          <label for="lgPass">Contraseña</label>
          <div class="entrada-con-boton">
            <input id="lgPass" name="password" type="password" required autocomplete="current-password" maxlength="72">
            <button class="btn-icono" type="button" data-ver-password="lgPass" aria-label="Mostrar contraseña"><?= icono('ojo') ?></button>
          </div>
        </div>
        <div class="mensaje-form" id="lgMensaje" role="alert"></div>
        <button class="btn btn--primario btn--grande btn--bloque" type="submit">Iniciar sesión</button>
      </form>
      <div class="acceso-pie">
        <span>¿Aún no tienes cuenta? <a class="enlace" href="registro.php<?= $volver !== 'perfil.php' ? '?volver=' . rawurlencode($volver) : '' ?>">Crea tu cuenta gratis</a></span>
        <span>¿Olvidaste tu contraseña? Acude a tu sucursal o escríbenos desde <a class="enlace" href="contacto.php">Contacto</a>.</span>
        <span class="texto-3" style="font-size:13px;"><?= icono('candado', 'icono icono--chico') ?> ¿Eres personal de KARMA? El acceso al <a class="enlace" href="<?= CAT_RAIZ ?>index.html?destino=pos">Punto de Venta</a> usa tu usuario del sistema.</span>
      </div>
    </div>
  </div>
</section>
<?php catPie(['scripts' => ['cuenta.js']]); ?>
