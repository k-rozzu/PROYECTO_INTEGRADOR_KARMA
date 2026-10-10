<?php
declare(strict_types=1);
/* KARMA · Catálogo — Simular crédito: crédito KARMA, comisión por apertura, seguros ligados al crédito y simulador.
   Para tramitarlo, el cliente agenda una cita (la simulación viaja como nota de la cita). */
require_once __DIR__ . '/includes/layout.php';
$cliente = catClienteActual();
$vehiculos = catBuscarProductos(['seccion' => ['vehiculos'], 'orden' => 'nombre']);
$precioInicial = (float)($_GET['precio'] ?? 0);
$codigo = (string)($_GET['codigo'] ?? '');
$elegido = $codigo ? (array_values(array_filter($vehiculos, fn($v) => $v['codigo'] === $codigo))[0] ?? null) : null;
$tasaInicial = (float)($_GET['tasa'] ?? CAT_TASA_ANUAL);
if ($tasaInicial < 5 || $tasaInicial > 40) $tasaInicial = CAT_TASA_ANUAL;
catCabecera(['titulo' => 'Simular crédito', 'activo' => 'financiamiento', 'descripcion' => 'Simula tu crédito automotriz: enganche, plazo, tasa, comisión por apertura y mensualidad para vehículos Audi, Porsche y Ducati en KARMA.']);
?>
<section class="cabecera-imagen">
  <img src="<?= catAsset('assets/Catalogo/banners/financiamiento.webp') ?>" alt="" width="1920" height="960">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Simular crédito</li></ol>
    <span class="mayus">KARMA Financial</span>
    <h1>El camino a tu próximo vehículo</h1>
    <p>Calcula tu mensualidad en segundos con la misma tasa y comisión por apertura de nuestras cajas. Después agenda tu cita o aparta tu vehículo.</p>
    <div class="fila fila--envolver" style="margin-top:24px;"><a class="btn btn--claro btn--grande" href="#simulador"><?= icono('porcentaje') ?> Simular mi crédito</a><a class="btn btn--contorno-claro btn--grande" href="agendar.php?tipo=visita">Agendar cita</a></div>
  </div>
</section>

<section class="seccion" id="credito">
  <div class="contenedor">
    <div class="titulo-seccion"><div><span class="mayus">Tu crédito</span><h2>Así funciona el crédito KARMA</h2><p>Datos de referencia del proyecto. Tu asesor confirma las condiciones en tu cita.</p></div></div>
    <div class="planes">
      <div class="plan"><span class="icono-caja"><?= icono('documento') ?></span><h3>Crédito KARMA</h3><p>Mensualidades fijas de 12 a 60 meses con enganche desde 10%.</p><ul><li>Tasa fija de referencia <?= CAT_TASA_ANUAL ?>% anual</li><li>Autos y motocicletas</li></ul></div>
      <div class="plan"><span class="icono-caja"><?= icono('porcentaje') ?></span><h3>Comisión por Apertura de Crédito</h3><p>Cargo único del <?= CAT_COMISION_APERTURA * 100 ?>% sobre el monto a financiar, ya incluido en el simulador.</p><ul><li>Misma comisión que en caja</li><li>Se suma al monto financiado</li></ul></div>
      <div class="plan"><span class="icono-caja"><?= icono('paraguas') ?></span><h3>Seguro de Vida y Desempleo</h3><p>Cubre el saldo de tu crédito por fallecimiento o invalidez, y algunas mensualidades si pierdes tu empleo.</p><ul><li>Protege a tu familia</li><li>Ligado a tu crédito</li></ul></div>
      <div class="plan"><span class="icono-caja"><?= icono('escudo') ?></span><h3>Seguro Automotriz de Cobertura Amplia</h3><p>Requisito para financiar: daños, robo total, responsabilidad civil y gastos médicos.</p><ul><li>Puede incluirse en tus mensualidades</li><li>Asistencia vial las 24 horas</li></ul></div>
    </div>
  </div>
</section>

<section class="seccion seccion--alt" id="simulador">
  <div class="contenedor">
    <div class="titulo-seccion"><div><span class="mayus">Simulador</span><h2>Calcula tu mensualidad</h2><p>Usa la misma fórmula del módulo de crédito de nuestras cajas (anualidad con tasa fija y comisión por apertura).</p></div></div>
    <div class="simulador">
      <div class="simulador-entradas">
        <div class="campos">
          <div class="campo"><label for="fsVehiculo">Vehículo <span class="opcional">(opcional)</span></label>
            <select id="fsVehiculo"><option value="">Escribir precio manualmente</option>
              <?php foreach (CAT_MARCAS as $m): ?><optgroup label="<?= e($m) ?>"><?php foreach ($vehiculos as $v): if ($v['marca'] !== $m) continue; ?>
                <option value="<?= $v['id'] ?>" data-precio="<?= $v['precio'] ?>" data-codigo="<?= e($v['codigo']) ?>" <?= $elegido && $elegido['id'] === $v['id'] ? 'selected' : '' ?>><?= e($v['titulo'] . ' ' . $v['anio']) ?> · <?= e($v['precioTexto']) ?></option>
              <?php endforeach; ?></optgroup><?php endforeach; ?>
            </select></div>
          <div class="campo"><label for="fsPrecio">Precio del vehículo (MXN)</label><input id="fsPrecio" type="number" min="50000" max="10000000" step="1000" inputmode="numeric" value="<?= (int)($elegido['precio'] ?? ($precioInicial ?: 1500000)) ?>"></div>
        </div>
        <div class="control-rango">
          <div class="fila"><label for="fsEnganche">Enganche</label><output id="fsEngancheTxt" translate="no"></output></div>
          <input type="range" id="fsEnganche" min="10" max="70" step="5" value="<?= min(70, max(10, (int)($_GET['enganche'] ?? 20))) ?>">
        </div>
        <div class="control-rango">
          <span class="etiqueta-campo">Plazo</span>
          <div class="botones-plazo" id="fsPlazos"><?php $plazoIni = (int)($_GET['plazo'] ?? 48); if (!in_array($plazoIni, CAT_PLAZOS, true)) $plazoIni = 48; foreach (CAT_PLAZOS as $pl): ?><button type="button" data-plazo="<?= $pl ?>" class="<?= $pl === $plazoIni ? 'activo' : '' ?>"><?= $pl ?> meses</button><?php endforeach; ?></div>
        </div>
        <div class="control-rango">
          <div class="fila"><label for="fsTasa">Tasa anual fija</label><output id="fsTasaTxt" translate="no"></output></div>
          <input type="range" id="fsTasa" min="8" max="30" step="0.1" value="<?= $tasaInicial ?>">
        </div>
        <button class="btn btn--fantasma" type="button" id="fsTabla"><?= icono('grafica') ?> Ver tabla de amortización</button>
      </div>
      <div class="simulador-resultado">
        <span class="mayus">Mensualidad estimada</span>
        <div class="mensualidad" id="fsMensualidad" translate="no">$0</div>
        <div class="linea-resumen"><span>Enganche</span><strong id="fsEngancheMonto" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Comisión por apertura (<?= CAT_COMISION_APERTURA * 100 ?>%)</span><strong id="fsComision" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Monto financiado</span><strong id="fsFinanciado" translate="no">$0</strong></div>
        <div class="linea-resumen"><span>Intereses totales</span><strong id="fsIntereses" translate="no">$0</strong></div>
        <div class="linea-resumen linea-resumen--total"><span>Costo total</span><strong id="fsTotal" translate="no">$0</strong></div>
        <a class="btn btn--claro" href="agendar.php?tipo=visita" id="fsCita"><?= icono('calendario') ?> Agendar cita con esta simulación</a>
        <p class="nota">SIMULACIÓN informativa. No constituye una oferta, cotización ni aprobación de crédito; la tasa y condiciones reales dependen del análisis crediticio.</p>
      </div>
    </div>
    <div id="fsTablaCaja" style="margin-top:20px;"></div>
  </div>
</section>

<section class="seccion" id="requisitos">
  <div class="contenedor dividido" style="align-items:start;">
    <div>
      <span class="mayus texto-3">Requisitos</span>
      <h2 class="titulo-dividido">Lo que necesitas para tu crédito</h2>
      <p class="texto-2 texto-dividido">Llévalo a tu cita: tu asesor revisa tu simulación, te explica las condiciones y te ayuda a apartar tu vehículo.</p>
      <ul class="lista-check">
        <li>Identificación oficial vigente (INE o pasaporte)</li>
        <li>Comprobante de domicilio no mayor a 3 meses</li>
        <li>Comprobantes de ingresos de los últimos 3 meses</li>
        <li>Enganche mínimo del 10% del valor del vehículo</li>
      </ul>
    </div>
    <div class="tarjeta-formulario">
      <h2>¿Listo para tramitarlo?</h2>
      <p>Agenda una cita en tu sucursal o aparta la unidad que te interesa. Tu simulación se envía como nota de la cita.</p>
      <div class="pila">
        <a class="btn btn--primario btn--bloque" href="agendar.php?tipo=visita" id="fsCita2"><?= icono('calendario') ?> Agendar cita</a>
        <a class="btn btn--secundario btn--bloque" href="agendar.php?tipo=apartado"><?= icono('etiqueta') ?> Apartar vehículo</a>
      </div>
    </div>
  </div>
</section>

<section class="seccion--compacta seccion--alt">
  <div class="contenedor contenedor--angosto">
    <div class="titulo-seccion"><div><span class="mayus">Preguntas frecuentes</span><h2>Resolvemos tus dudas</h2></div></div>
    <div class="acordeon">
      <details><summary>¿La simulación es una aprobación de crédito? <?= icono('mas') ?></summary><p>No. Es un cálculo informativo con una tasa de referencia. La aprobación y la tasa final dependen del análisis de tu historial crediticio y de tus ingresos.</p></details>
      <details><summary>¿Qué es la comisión por apertura? <?= icono('mas') ?></summary><p>Es un cargo único del <?= CAT_COMISION_APERTURA * 100 ?>% sobre el monto a financiar que se suma al crédito. Es el mismo criterio que usa el módulo de crédito en nuestras cajas.</p></details>
      <details><summary>¿Puedo adelantar pagos? <?= icono('mas') ?></summary><p>Sí. Los pagos anticipados se aplican a capital y reducen los intereses o el plazo, según elijas.</p></details>
      <details><summary>¿También financian motocicletas Ducati? <?= icono('mas') ?></summary><p>Sí. Todos los vehículos del catálogo, autos y motocicletas, pueden financiarse con los mismos plazos.</p></details>
    </div>
  </div>
</section>
<?php catPie(['scripts' => ['formularios.js']]); ?>
