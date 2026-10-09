<?php
declare(strict_types=1);
/* KARMA · Catálogo — Servicios de la agencia: seguros y crédito, trámites e impuestos, postventa y taller.
   Solo aparecen los servicios que KARMA maneja. Cada uno se contrata en una cita con un asesor:
   visita (servicios al comprar un vehículo del catálogo) o servicio de taller (con tu propio vehículo). */
require_once __DIR__ . '/includes/layout.php';
$sucursal = catSucursalActual();

// SERVICIOS DE LA AGENCIA: [icono, nombre (igual que en agendar.php), descripción, detalles, destino]
// destino: 'visita' / 'servicio' = tipo de cita en agendar.php · 'simulador' = financiamiento.php
$grupos = [
    'seguros' => [
        'Seguros y crédito', 'Protege tu vehículo y tu crédito',
        'Contrátalos al comprar tu vehículo y, si lo financias, inclúyelos en tus mensualidades.',
        [
            ['escudo', 'Seguro Automotriz de Cobertura Amplia', 'Daños materiales, robo total, responsabilidad civil y gastos médicos a ocupantes.', ['Asistencia vial las 24 horas', 'Requisito para financiar tu vehículo'], 'visita'],
            ['paraguas', 'Seguro de Vida y Desempleo', 'Cubre el saldo de tu crédito por fallecimiento o invalidez, y algunas mensualidades si pierdes tu empleo de forma involuntaria.', ['Protege a tu familia', 'Ligado a tu crédito automotriz'], 'visita'],
            ['auto', 'Seguro de Llantas y Rines', 'Reparación o reemplazo de llantas y rines dañados por baches, golpes o ponchaduras.', ['Llantas y rines originales', 'Sin afectar tu seguro principal'], 'visita'],
            ['porcentaje', 'Comisión por Apertura de Crédito', 'Cargo único del ' . (CAT_COMISION_APERTURA * 100) . '% sobre el monto a financiar; el simulador ya lo incluye en tu mensualidad.', ['Misma comisión que en caja', 'Se suma al monto financiado'], 'simulador'],
        ],
    ],
    'tramites' => [
        'Trámites e impuestos', 'Estrena sin filas ni vueltas',
        'Te explicamos cada concepto de tu factura y hacemos los trámites por ti.',
        [
            ['documento', 'Gestoría de Placas y Alta Vehicular', 'Tramitamos placas, tarjeta de circulación y el alta de tu vehículo en el padrón vehicular.', ['Entrega con placas', 'Sin vueltas a oficinas'], 'visita'],
            ['efectivo', 'Impuesto sobre Autos Nuevos (ISAN)', 'Impuesto federal que se paga una sola vez al comprar un vehículo nuevo; lo desglosamos en tu factura.', ['Incluido en tu cotización', 'Se paga solo en vehículos nuevos'], 'visita'],
            ['calendario', 'Tenencia / Refrendo Vehicular', 'Pago anual estatal de tenencia o refrendo según tu entidad. Te ayudamos a cubrirlo y a mantener tu vehículo al corriente.', ['Cálculo según tu estado', 'Comprobante para tus trámites'], 'visita'],
            ['check-circulo', 'Verificación Vehicular (Holograma 00)', 'Gestionamos el holograma 00 de tu vehículo nuevo, que lo exenta de verificar durante sus primeros años en las entidades con programa de verificación.', ['Trámite para vehículos nuevos', 'Te avisamos cuándo renovar'], 'servicio'],
        ],
    ],
    'postventa' => [
        'Postventa y taller', 'Cuidamos tu vehículo como el primer día',
        'Técnicos especializados en Audi, Porsche y Ducati, con refacciones originales.',
        [
            ['herramienta', 'Orden de Servicio de Taller', 'Mantenimiento, diagnóstico y reparación de tu vehículo; tu asesor confirma el presupuesto antes de iniciar.', ['Recepción con tu asesor', 'Refacciones originales'], 'servicio'],
            ['historial', 'Plan de Mantenimiento Prepagado', 'Paga hoy los servicios de mantenimiento de los próximos años a precio fijo.', ['Precio congelado', 'Se puede incluir en tu crédito'], 'servicio'],
            ['escudo', 'Garantía Extendida', 'Amplía la cobertura de fábrica contra fallas mecánicas y eléctricas.', ['Cobertura en ambas sucursales', 'Atención con refacciones originales'], 'servicio'],
            ['estrella', 'Accesorios Originales e Instalación', 'Tapetes, portaequipaje, maletas, cargadores y más, instalados en nuestro taller.', ['Compatibles con tu modelo', 'Instalación profesional'], 'servicio'],
            ['sol', 'Película de Seguridad y/o Polarizado', 'Película de control solar y de seguridad que cumple la normativa vigente.', ['Protege tu interior', 'Instalación en taller'], 'servicio'],
        ],
    ],
];

// Enlace de cada servicio: agenda la cita con el servicio ya elegido, o abre el simulador
function servicioEnlace(string $nombre, string $destino): array {
    if ($destino === 'simulador') return ['financiamiento.php#simulador', 'Simular crédito', 'porcentaje'];
    return ['agendar.php?tipo=' . $destino . '&servicio=' . rawurlencode($nombre), 'Agendar cita', 'calendario'];
}

catCabecera(['titulo' => 'Servicios', 'activo' => 'servicios', 'descripcion' => 'Seguros, comisión por apertura, gestoría de placas, ISAN, tenencia, verificación, mantenimiento prepagado, garantía extendida, accesorios, polarizado y taller en KARMA Manzanillo y Colima.']);
?>
<section class="cabecera-imagen">
  <img src="<?= catAsset('assets/Catalogo/banners/servicio.webp') ?>" alt="" width="1920" height="960">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Servicios</li></ol>
    <span class="mayus">Servicios KARMA</span>
    <h1>Todo para estrenar y mantener tu vehículo</h1>
    <p>Seguros, crédito, trámites y postventa en Manzanillo y Colima. Elige el servicio y agenda tu cita con un asesor.</p>
    <div class="fila fila--envolver" style="margin-top:24px;">
      <a class="btn btn--claro btn--grande" href="agendar.php?tipo=visita"><?= icono('calendario') ?> Agendar cita</a>
      <a class="btn btn--contorno-claro btn--grande" href="agendar.php?tipo=servicio">Orden de servicio de taller</a>
    </div>
  </div>
</section>

<?php $alterna = false; foreach ($grupos as $id => [$etiqueta, $titulo, $intro, $servicios]): ?>
<section class="seccion<?= $alterna ? ' seccion--alt' : '' ?>" id="<?= $id ?>">
  <div class="contenedor">
    <div class="titulo-seccion"><div><span class="mayus"><?= e($etiqueta) ?></span><h2><?= e($titulo) ?></h2><p><?= e($intro) ?></p></div></div>
    <div class="planes planes--servicios">
      <?php foreach ($servicios as [$ic, $nombre, $desc, $detalles, $destino]): [$url, $cta, $icCta] = servicioEnlace($nombre, $destino); ?>
        <article class="plan">
          <span class="icono-caja"><?= icono($ic) ?></span>
          <h3><?= e($nombre) ?></h3>
          <p><?= e($desc) ?></p>
          <ul><?php foreach ($detalles as $d): ?><li><?= e($d) ?></li><?php endforeach; ?></ul>
          <a class="btn btn--secundario btn--chico" href="<?= e($url) ?>"><?= icono($icCta, 'icono icono--chico') ?> <?= e($cta) ?></a>
        </article>
      <?php endforeach; ?>
    </div>
    <?php if ($id === 'postventa'): ?>
      <div class="pasos-servicio" style="margin-top:48px;">
        <div class="paso-servicio"><h3>Agenda en línea</h3><p>Elige sucursal, servicio, fecha y hora desde tu cuenta.</p></div>
        <div class="paso-servicio"><h3>Recepción</h3><p>Tu asesor revisa el vehículo contigo y abre la orden de servicio.</p></div>
        <div class="paso-servicio"><h3>Servicio</h3><p>Técnicos especializados trabajan con refacciones originales.</p></div>
        <div class="paso-servicio"><h3>Entrega</h3><p>Te explicamos lo realizado y pagas en la caja de la sucursal.</p></div>
      </div>
    <?php endif; ?>
  </div>
</section>
<?php $alterna = !$alterna; endforeach; ?>

<section class="seccion--compacta seccion--alt">
  <div class="contenedor dividido">
    <div>
      <span class="mayus texto-3">Accesorios y refacciones</span>
      <h2 class="titulo-dividido">Piezas originales listas en <?= e($sucursal['nombre']) ?></h2>
      <p class="texto-2">Compra en línea y recoge en sucursal, o recibe en casa. Agenda la instalación de tus accesorios en nuestro taller.</p>
      <div class="fila fila--envolver" style="margin-top:22px;"><a class="btn btn--primario" href="accesorios.php">Ver accesorios</a><a class="btn btn--secundario" href="refacciones.php">Ver refacciones</a></div>
    </div>
    <div class="media media--pieza"><img src="<?= catAsset('assets/Catalogo/refacciones/audi/kit-distribucion.webp') ?>" alt="Kit de distribución" loading="lazy" width="1000" height="750"></div>
  </div>
</section>
<?php catPie(); ?>
