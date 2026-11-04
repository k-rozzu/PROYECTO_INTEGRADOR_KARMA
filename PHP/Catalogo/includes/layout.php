<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — plantilla común: <head>, barra superior, cabecera con menú de modelos,
   menú móvil, buscador, selector de sucursal y pie de página.
   Uso en cada página:
       catCabecera(['titulo' => 'Modelos', 'activo' => 'modelos']);
       ... contenido ...
       catPie(['scripts' => ['catalogo.js']]);
   ===================================================================================== */

require_once __DIR__ . '/datos.php';
require_once __DIR__ . '/iconos.php';

// Logo de KARMA (mismo archivo que usa el Punto de Venta). Cámbialo aquí si se reemplaza el logo.
const CAT_LOGO = 'assets/logo-karma.png';

// Versión de un archivo propio (CSS/JS) según su fecha: evita que el navegador use una copia vieja
function catVersion(string $rutaRelativa): string {
    $archivo = dirname(__DIR__, 3) . '/' . $rutaRelativa;
    return CAT_RAIZ . $rutaRelativa . (is_file($archivo) ? '?v=' . filemtime($archivo) : '');
}

// Mensaje de una sola vez guardado en la sesión (ej. «registro completado» después de confirmar desde el correo)
function catTomarAviso(): ?string {
    $mensaje = $_SESSION['cat_aviso'] ?? null;
    unset($_SESSION['cat_aviso']);
    return is_string($mensaje) ? $mensaje : null;
}

function catCabecera(array $o = []): void {
    $titulo = $o['titulo'] ?? 'Concesionario';
    $descripcion = $o['descripcion'] ?? 'KARMA: concesionario de vehículos Audi, Porsche y motocicletas Ducati en Manzanillo y Colima. Modelos, refacciones, servicio, financiamiento y citas en línea.';
    $activo = $o['activo'] ?? '';
    $cliente = catClienteActual();
    $sucursal = catSucursalActual();
    $carrito = catCarritoCantidad();
    $vehiculos = catBuscarProductos(['seccion' => ['vehiculos'], 'orden' => 'nombre']);
    $porMarca = [];
    foreach ($vehiculos as $v) $porMarca[$v['marca']][] = $v;
    $iniciales = $cliente ? mb_strtoupper(mb_substr((string)($cliente['nombres'] ?: $cliente['nombre']), 0, 1) . mb_substr((string)($cliente['apellidos'] ?? ''), 0, 1)) : '';
    $navActual = fn(string $clave) => $activo === $clave ? ' actual" aria-current="page' : '';
    ?>
<!DOCTYPE html>
<html lang="es" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($titulo) ?> · KARMA Concesionario</title>
<meta name="description" content="<?= e($descripcion) ?>">
<meta name="csrf-token" content="<?= e(catCsrf()) ?>">
<meta name="theme-color" content="#10213f">
<link rel="icon" href="<?= catAsset(CAT_LOGO) ?>">
<script>
  // Aplica el tema guardado (o el del sistema) antes de pintar la página para evitar parpadeos
  (function () {
    try {
      var t = localStorage.getItem('karma_catalogo_tema');
      if (!t) t = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', t);
    } catch (e) {}
  })();
  // Si una imagen no carga (archivo movido o renombrado) se muestra la imagen de respaldo en lugar de una imagen rota
  document.addEventListener('error', function (e) {
    var img = e.target;
    if (img && img.tagName === 'IMG' && !img.getAttribute('data-respaldo')) {
      img.setAttribute('data-respaldo', '1');
      img.src = <?= json_encode(catAsset(CAT_IMAGEN_RESPALDO), JSON_UNESCAPED_SLASHES) ?>;
    }
  }, true);
</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600&family=Inter:wght@400;500;600;700&family=Sora:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= catVersion('CSS/Catalogo/catalogo.css') ?>">
<?= $o['head'] ?? '' ?>
</head>
<body class="<?= e($o['clase'] ?? '') ?>">
<a class="saltar-contenido" href="#contenido">Saltar al contenido</a>

<!-- ===== BARRA SUPERIOR: sucursal elegida, contacto, idioma y acceso al Punto de Venta ===== -->
<div class="barra-util">
  <div class="contenedor">
    <div class="grupo">
      <button class="selector-sucursal" type="button" data-abrir-sucursales aria-haspopup="dialog">
        <?= icono('ubicacion') ?> <span class="ocultar-movil">Sucursal:</span> <strong data-sucursal-nombre translate="no"><?= e($sucursal['nombre']) ?></strong> <?= icono('chevron', 'icono icono--chico') ?>
      </button>
      <a class="ocultar-movil" href="tel:<?= e($sucursal['telefono']) ?>"><?= icono('telefono') ?> <span translate="no"><?= e(preg_replace('/(\d{3})(\d{3})(\d{4})/', '$1 $2 $3', $sucursal['telefono'])) ?></span></a>
      <span class="ocultar-movil"><?= icono('reloj') ?> <?= e($sucursal['horario_ventas'] ?? '') ?></span>
    </div>
    <div class="grupo">
      <button class="idioma" type="button" id="btnIdioma" aria-label="Cambiar idioma" translate="no"><span class="op activo" data-lang="es">ES</span> / <span class="op" data-lang="en">EN</span></button>
      <!-- ACCESO AL PUNTO DE VENTA: lleva a la pantalla de login existente; solo usuarios con rol Cajero entran -->
      <a class="enlace-pos" href="<?= CAT_RAIZ ?>index.html?destino=pos" title="Acceso para personal autorizado (requiere usuario de Cajero)"><?= icono('candado') ?> <span>Punto de Venta</span></a>
    </div>
  </div>
</div>

<!-- ===== CABECERA ===== -->
<header class="cabecera" id="cabecera">
  <div class="contenedor">
    <a class="marca-karma" href="index.php" aria-label="KARMA, ir al inicio">
      <img src="<?= catAsset(CAT_LOGO) ?>" alt="" width="40" height="40">
      <span><span class="nombre" translate="no">KARMA</span><span class="lema">Audi · Porsche · Ducati</span></span>
    </a>

    <nav class="nav-principal" aria-label="Navegación principal">
      <ul>
        <li><button class="nav-enlace<?= $activo === 'modelos' ? ' actual' : '' ?>" type="button" data-mega aria-expanded="false" aria-controls="megaModelos">Modelos <?= icono('chevron') ?></button></li>
        <li><a class="nav-enlace<?= $navActual('refacciones') ?>" href="refacciones.php">Refacciones</a></li>
        <li><a class="nav-enlace<?= $navActual('accesorios') ?>" href="accesorios.php">Accesorios</a></li>
        <li>
          <button class="nav-enlace<?= $activo === 'servicios' ? ' actual' : '' ?>" type="button" data-submenu aria-expanded="false">Servicios <?= icono('chevron') ?></button>
          <ul class="submenu">
            <li><a href="servicios.php">Todos los servicios<small>Seguros, trámites, garantía y taller</small></a></li>
            <li><a href="agendar.php?tipo=visita">Agendar cita<small>Visita con un asesor en sucursal</small></a></li>
            <li><a href="agendar.php?tipo=apartado">Apartar vehículo<small>Reserva una unidad del inventario</small></a></li>
            <li><a href="servicios.php#seguros">Seguros<small>Cobertura amplia, vida y desempleo, llantas y rines</small></a></li>
            <li><a href="servicios.php#tramites">Trámites e impuestos<small>Placas, ISAN, tenencia y verificación</small></a></li>
            <li><a href="servicios.php#postventa">Postventa y taller<small>Mantenimiento, garantía extendida y accesorios</small></a></li>
          </ul>
        </li>
        <li><a class="nav-enlace<?= $navActual('financiamiento') ?>" href="financiamiento.php">Simular crédito</a></li>
        <li><a class="nav-enlace<?= $navActual('sucursales') ?>" href="sucursales.php">Sucursales</a></li>
        <li><a class="nav-enlace<?= $navActual('contacto') ?>" href="contacto.php">Contacto</a></li>
      </ul>
    </nav>

    <div class="acciones-cabecera">
      <button class="btn-icono" type="button" data-abrir-busqueda aria-label="Buscar"><?= icono('buscar') ?></button>
      <button class="btn-icono" type="button" id="btnTema" aria-label="Cambiar modo claro u oscuro"><?= icono('luna', 'icono icono-luna') ?><?= icono('sol', 'icono icono-sol') ?></button>
      <?php if ($cliente): ?>
        <div class="contenedor-cuenta">
          <button class="boton-cuenta" type="button" data-menu-cuenta aria-expanded="false" aria-label="Mi cuenta">
            <span class="avatar" translate="no"><?= e($iniciales) ?></span><span class="nombre-cuenta"><?= e(catNombreCorto($cliente)) ?></span>
          </button>
          <ul class="submenu menu-cuenta">
            <li><a href="perfil.php">Mi perfil<small><?= e($cliente['email']) ?></small></a></li>
            <li><a href="perfil.php#pedidos">Mis pedidos</a></li>
            <li><a href="perfil.php#citas">Mis citas</a></li>
            <li><a href="perfil.php#favoritos">Vehículos de interés</a></li>
            <li><a href="#" data-cerrar-sesion>Cerrar sesión</a></li>
          </ul>
        </div>
      <?php else: ?>
        <a class="btn-icono" href="login.php" aria-label="Iniciar sesión o registrarse" title="Iniciar sesión"><?= icono('usuario') ?></a>
      <?php endif; ?>
      <a class="btn-icono" href="carrito.php" aria-label="Carrito de compras" title="Carrito"><?= icono('carrito') ?><span class="contador" data-contador-carrito data-valor="<?= $carrito ?>"><?= $carrito ?: '' ?></span></a>
      <button class="btn-icono btn-menu-movil" type="button" data-abrir-menu aria-label="Abrir menú"><?= icono('menu') ?></button>
    </div>
  </div>

  <!-- ===== MENÚ DE MODELOS (las miniaturas se cargan al abrirlo: data-src) ===== -->
  <div class="mega" id="megaModelos" role="region" aria-label="Modelos por marca">
    <div class="contenedor">
      <div class="mega-marcas" role="tablist">
        <?php foreach (CAT_MARCAS as $i => $marca): ?>
          <button class="mega-marca<?= $i === 0 ? ' activo' : '' ?>" type="button" role="tab" data-mega-marca="<?= e($marca) ?>" translate="no">
            <?= e($marca) ?> <small><?= count($porMarca[$marca] ?? []) ?> modelos</small>
          </button>
        <?php endforeach; ?>
        <div class="mega-extra">
          <a href="vehiculos.php"><?= icono('auto') ?> Ver todos los modelos</a>
          <a href="vehiculos.php?tipo=moto"><?= icono('moto') ?> Motocicletas</a>
          <a href="vehiculos.php?disponible=1"><?= icono('check-circulo') ?> Disponibles en <?= e($sucursal['nombre']) ?></a>
          <a href="agendar.php?tipo=visita"><?= icono('calendario') ?> Agendar cita</a>
          <a href="agendar.php?tipo=apartado"><?= icono('etiqueta') ?> Apartar vehículo</a>
        </div>
      </div>
      <?php foreach (CAT_MARCAS as $i => $marca): ?>
        <div class="mega-modelos<?= $i === 0 ? '' : ' oculto' ?>" data-mega-panel="<?= e($marca) ?>">
          <?php foreach ($porMarca[$marca] ?? [] as $v): ?>
            <a class="mega-modelo" href="<?= e($v['url']) ?>">
              <!-- IMAGEN DEL MENÚ: miniatura de assets/Catalogo/vehiculos/{marca}/miniaturas/ -->
              <span class="foto"><img data-src="<?= e($v['miniatura']) ?>" alt="" width="240" height="150"></span>
              <strong translate="no"><?= e($v['titulo']) ?></strong>
              <span>Desde <span translate="no"><?= e($v['precioTexto']) ?></span> · <?= e($v['subcategoria'] ?? '') ?></span>
            </a>
          <?php endforeach; ?>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</header>

<!-- ===== MENÚ MÓVIL ===== -->
<div class="cajon" id="cajonMenu" aria-hidden="true">
  <div class="cajon-panel" role="dialog" aria-label="Menú">
    <div class="cajon-cabeza">
      <span class="marca-karma"><img src="<?= catAsset(CAT_LOGO) ?>" alt="" width="34" height="34"><span class="nombre" translate="no">KARMA</span></span>
      <button class="btn-icono" type="button" data-cerrar-cajon aria-label="Cerrar menú"><?= icono('cerrar') ?></button>
    </div>
    <div class="cajon-cuerpo">
      <details>
        <summary>Modelos <?= icono('chevron') ?></summary>
        <div class="sublista">
          <a href="vehiculos.php">Todos los modelos</a>
          <?php foreach (CAT_MARCAS as $marca): ?><a href="vehiculos.php?marca=<?= e($marca) ?>" translate="no"><?= e($marca) ?></a><?php endforeach; ?>
          <a href="vehiculos.php?tipo=moto">Motocicletas</a>
        </div>
      </details>
      <a class="enlace-movil" href="refacciones.php">Refacciones</a>
      <a class="enlace-movil" href="accesorios.php">Accesorios</a>
      <details>
        <summary>Servicios <?= icono('chevron') ?></summary>
        <div class="sublista">
          <a href="servicios.php">Todos los servicios</a>
          <a href="agendar.php?tipo=visita">Agendar cita</a>
          <a href="agendar.php?tipo=apartado">Apartar vehículo</a>
          <a href="servicios.php#seguros">Seguros</a>
          <a href="servicios.php#tramites">Trámites e impuestos</a>
          <a href="servicios.php#postventa">Postventa y taller</a>
        </div>
      </details>
      <a class="enlace-movil" href="financiamiento.php">Simular crédito</a>
      <a class="enlace-movil" href="sucursales.php">Sucursales</a>
      <a class="enlace-movil" href="contacto.php">Contacto</a>
      <a class="enlace-movil" href="<?= $cliente ? 'perfil.php' : 'login.php' ?>"><?= $cliente ? 'Mi perfil' : 'Iniciar sesión / Registrarse' ?></a>
      <div style="margin-top:24px; display:grid; gap:10px;">
        <button class="btn btn--secundario btn--bloque" type="button" data-abrir-sucursales><?= icono('ubicacion') ?> Sucursal: <span data-sucursal-nombre translate="no"><?= e($sucursal['nombre']) ?></span></button>
        <button class="btn btn--fantasma btn--bloque" type="button" data-alternar-tema><?= icono('luna', 'icono icono-luna') ?><?= icono('sol', 'icono icono-sol') ?> <span data-texto-tema>Cambiar a modo oscuro</span></button>
        <a class="btn btn--fantasma btn--bloque" href="<?= CAT_RAIZ ?>index.html?destino=pos"><?= icono('candado') ?> Punto de Venta (personal)</a>
      </div>
    </div>
  </div>
</div>

<!-- ===== BUSCADOR GLOBAL ===== -->
<div class="capa-busqueda" id="capaBusqueda" aria-hidden="true">
  <div class="panel-busqueda" role="dialog" aria-label="Buscar en el catálogo">
    <div class="contenedor">
      <form class="campo-busqueda" action="buscar.php" method="get" role="search">
        <?= icono('buscar') ?>
        <input type="search" name="q" id="entradaBusqueda" placeholder="Busca por modelo, marca, pieza, código o motor…" autocomplete="off" aria-label="Buscar">
        <button class="btn-icono" type="button" data-cerrar-busqueda aria-label="Cerrar búsqueda"><?= icono('cerrar') ?></button>
      </form>
      <div class="busquedas-sugeridas" id="busquedasSugeridas">
        <a class="chip" href="buscar.php?q=Porsche%20911">Porsche 911</a>
        <a class="chip" href="buscar.php?q=quattro">quattro</a>
        <a class="chip" href="buscar.php?q=Panigale">Panigale</a>
        <a class="chip" href="buscar.php?q=eléctrico">Eléctricos</a>
        <a class="chip" href="buscar.php?q=pastillas">Pastillas de freno</a>
        <a class="chip" href="buscar.php?q=batería">Baterías</a>
        <a class="chip" href="buscar.php?q=RS6">RS 6</a>
      </div>
      <div class="sugerencias-busqueda" id="sugerenciasBusqueda" aria-live="polite"></div>
    </div>
  </div>
</div>

<main id="contenido">
<?php
}

function catPie(array $o = []): void {
    $sucursal = catSucursalActual();
    $cliente = catClienteActual();
    ?>
</main>

<!-- ===== PIE DE PÁGINA ===== -->
<footer class="pie">
  <div class="contenedor">
    <div class="pie-superior">
      <div class="pie-marca">
        <a class="marca-karma" href="index.php"><img src="<?= catAsset(CAT_LOGO) ?>" alt="" width="40" height="40"><span><span class="nombre" translate="no">KARMA</span></span></a>
        <p>Te damos el auto que te mereces. Vehículos Audi y Porsche, motocicletas Ducati, refacciones, servicio y financiamiento en Manzanillo y Colima.</p>
      </div>
      <div>
        <h3>Catálogo</h3>
        <ul>
          <li><a href="vehiculos.php?marca=Audi" translate="no">Audi</a></li>
          <li><a href="vehiculos.php?marca=Porsche" translate="no">Porsche</a></li>
          <li><a href="vehiculos.php?marca=Ducati" translate="no">Ducati</a></li>
          <li><a href="refacciones.php">Refacciones</a></li>
          <li><a href="accesorios.php">Accesorios</a></li>
        </ul>
      </div>
      <div>
        <h3>Servicios</h3>
        <ul>
          <li><a href="servicios.php#seguros">Seguros</a></li>
          <li><a href="servicios.php#tramites">Trámites e impuestos</a></li>
          <li><a href="servicios.php#postventa">Postventa y taller</a></li>
          <li><a href="agendar.php?tipo=servicio">Orden de servicio de taller</a></li>
        </ul>
      </div>
      <div>
        <h3>Compra tu vehículo</h3>
        <ul>
          <li><a href="vehiculos.php">Ver modelos</a></li>
          <li><a href="financiamiento.php#simulador">Simular crédito</a></li>
          <li><a href="agendar.php?tipo=visita">Agendar cita</a></li>
          <li><a href="agendar.php?tipo=apartado">Apartar vehículo</a></li>
        </ul>
      </div>
      <div>
        <h3>Atención</h3>
        <ul>
          <li><a href="contacto.php">Contacto</a></li>
          <li><a href="contacto.php?motivo=queja">Quejas y sugerencias</a></li>
          <li><a href="sucursales.php">Sucursales</a></li>
          <li><a href="<?= $cliente ? 'perfil.php' : 'login.php' ?>">Mi cuenta</a></li>
        </ul>
      </div>
      <div>
        <h3>KARMA</h3>
        <ul>
          <li><a href="privacidad.php">Aviso de privacidad</a></li>
          <li><a href="terminos.php">Términos y condiciones</a></li>
          <li><a href="creditos.php">Créditos de imágenes</a></li>
          <li><a href="<?= CAT_RAIZ ?>index.html?destino=pos"><?= icono('candado', 'icono icono--chico') ?> Punto de Venta</a></li>
        </ul>
      </div>
    </div>
    <div class="pie-sucursales">
      <?php foreach (catSucursales() as $s): ?>
        <div class="pie-sucursal">
          <strong>KARMA <?= e($s['nombre']) ?></strong>
          <?= e($s['direccion']) ?><br>
          Tel. <a href="tel:<?= e($s['telefono']) ?>" translate="no"><?= e(preg_replace('/(\d{3})(\d{3})(\d{4})/', '$1 $2 $3', $s['telefono'])) ?></a> · <?= e($s['horario_ventas'] ?? '') ?>
        </div>
      <?php endforeach; ?>
    </div>
    <div class="pie-inferior">
      <p class="pie-aviso">© <?= date('Y') ?> KARMA · Proyecto integrador académico. Audi, Porsche y Ducati son marcas registradas de sus respectivos propietarios. Este sitio es una demostración educativa: no es un sitio oficial ni está afiliado a dichas marcas. Precios y pagos en línea son de demostración.</p>
      <div class="legal">
        <a href="privacidad.php">Privacidad</a>
        <a href="terminos.php">Términos</a>
        <a href="creditos.php">Créditos</a>
      </div>
    </div>
  </div>
</footer>

<!-- ===== SELECTOR DE SUCURSAL ===== -->
<dialog class="modal" id="modalSucursales" aria-labelledby="tituloSucursales">
  <div class="modal-cabeza">
    <div>
      <h2 id="tituloSucursales">Elige tu sucursal</h2>
      <p>El inventario, la disponibilidad, la recogida de pedidos y las citas dependen de la sucursal elegida. Cada sucursal tiene sus propias existencias.</p>
    </div>
    <button class="btn-icono" type="button" data-cerrar-modal aria-label="Cerrar"><?= icono('cerrar') ?></button>
  </div>
  <div class="modal-cuerpo">
    <div class="lista-sucursales-modal">
      <?php foreach (catSucursales() as $s): ?>
        <button class="opcion-sucursal<?= $s['id_sucursal'] === $sucursal['id_sucursal'] ? ' actual' : '' ?>" type="button" data-elegir-sucursal="<?= $s['id_sucursal'] ?>">
          <!-- IMAGEN DE LA SUCURSAL: columna sucursales.imagen (assets/Catalogo/sucursales/...) -->
          <img src="<?= catAsset($s['imagen']) ?>" alt="" loading="lazy" width="110" height="82">
          <span>
            <strong>KARMA <?= e($s['nombre']) ?></strong>
            <span><?= e($s['direccion']) ?></span><br>
            <span><?= $s['id_sucursal'] === $sucursal['id_sucursal'] ? 'Sucursal actual' : 'Ver inventario de esta sucursal' ?></span>
          </span>
        </button>
      <?php endforeach; ?>
    </div>
  </div>
</dialog>

<div class="avisos" id="avisos" aria-live="polite" aria-atomic="false"></div>

<!-- Configuración que necesita el JavaScript (íconos, sucursal, sesión). No contiene datos sensibles. -->
<script>
  window.KARMA_CONFIG = <?= json_encode([
      'api' => 'api.php',
      'raiz' => CAT_RAIZ,
      'csrf' => catCsrf(),
      'sucursal' => ['id' => $sucursal['id_sucursal'], 'nombre' => $sucursal['nombre']],
      'cliente' => $cliente ? ['id' => (int)$cliente['id_cliente'], 'nombre' => catNombreCorto($cliente)] : null,
      'aviso' => catTomarAviso(),
      'iconos' => CAT_ICONOS,
      'envioCosto' => CAT_ENVIO_COSTO,
      'envioGratisDesde' => CAT_ENVIO_GRATIS_DESDE,
      'tasaAnual' => CAT_TASA_ANUAL,
      'comisionApertura' => CAT_COMISION_APERTURA,
      'plazos' => CAT_PLAZOS
  ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?>;
</script>
<!-- API DE TRADUCCIÓN existente del proyecto (botón ES / EN de la barra superior) -->
<script src="<?= CAT_RAIZ ?>JavaScript/Traduccion/traductor.js"></script>
<script src="<?= catVersion('JavaScript/Catalogo/app.js') ?>"></script>
<?php foreach ($o['scripts'] ?? [] as $script): ?>
<script src="<?= catVersion('JavaScript/Catalogo/' . $script) ?>"></script>
<?php endforeach; ?>
<?= $o['extra'] ?? '' ?>
</body>
</html>
<?php
}
