<?php
declare(strict_types=1);
/* KARMA · Catálogo — agendar cita: visita, apartado de vehículo u orden de servicio de taller.
   Las visitas y apartados también se registran en web_orders para que aparezcan en POS → Web orders.
   Parámetros opcionales: ?tipo=visita|apartado|servicio &id=vehículo &servicio=nombre del servicio &nota=texto */
require_once __DIR__ . '/includes/layout.php';

$cliente = catRequerirCliente();
$sucursal = catSucursalActual();
$tipo = in_array($_GET['tipo'] ?? '', ['visita', 'apartado', 'servicio'], true) ? $_GET['tipo'] : 'visita';
$idProducto = (int)($_GET['id'] ?? 0);
$servicioInicial = mb_substr(trim((string)($_GET['servicio'] ?? '')), 0, 80);
// Nota que llega desde el configurador o el simulador; un servicio que no es casilla ni tipo de taller también va aquí
$nota = mb_substr(trim((string)($_GET['nota'] ?? '')), 0, 500);
if ($servicioInicial !== '' && !in_array($servicioInicial, CAT_SERVICIOS_COMPRA, true) && !in_array($servicioInicial, CAT_SERVICIOS_TALLER, true)) {
    $nota = trim("Me interesa: {$servicioInicial}. {$nota}");
}

// Vehículos con existencias en CADA sucursal (para mostrar dónde hay unidades)
$vehiculos = catBuscarProductos(['seccion' => ['vehiculos'], 'orden' => 'nombre'], $sucursal['id_sucursal']);
$stocks = [];
foreach (catSucursales() as $s) {
    foreach (catBuscarProductos(['seccion' => ['vehiculos']], $s['id_sucursal']) as $v) $stocks[$v['id']][$s['id_sucursal']] = $v['stock'];
}
$vehiculosJs = array_map(fn($v) => ['id' => $v['id'], 'marca' => $v['marca'], 'modelo' => $v['modelo'], 'titulo' => $v['titulo'], 'anio' => $v['anio'],
    'imagen' => $v['miniatura'], 'precio' => $v['precio'], 'precioTexto' => $v['precioTexto'], 'color' => $v['color'],
    'stocks' => $stocks[$v['id']] ?? []], $vehiculos);
$manana = (new DateTime('tomorrow'))->format('Y-m-d');
$limite = (new DateTime('+60 days'))->format('Y-m-d');
// IMAGEN DE CABECERA DE ESTA PÁGINA: assets/Catalogo/banners/
$banner = $tipo === 'servicio' ? 'assets/Catalogo/banners/servicio.webp' : 'assets/Catalogo/banners/prueba-manejo.webp';

catCabecera(['titulo' => 'Agendar cita', 'activo' => $tipo === 'servicio' ? 'servicios' : 'modelos']);
?>
<section class="cabecera-imagen" style="min-height:300px;">
  <img src="<?= catAsset($banner) ?>" alt="" width="1920" height="960">
  <div class="contenedor">
    <ol class="migas"><li><a href="index.php">Inicio</a></li><li>Agendar cita</li></ol>
    <h1>Agenda tu cita en KARMA</h1>
    <p>Visita con un asesor, apartado de vehículo u orden de servicio de taller: elige sucursal, fecha y hora.</p>
  </div>
</section>

<div class="contenedor">
  <form class="agenda" id="formAgenda" novalidate>
    <div>
      <!-- 1. TIPO DE CITA -->
      <div class="bloque-checkout">
        <h2><span class="num">1</span> ¿Qué quieres agendar?</h2>
        <p>Las visitas y los apartados de vehículo los atiende un asesor de ventas en caja; las órdenes de servicio, el taller.</p>
        <div class="tipos-cita">
          <?php foreach ([['visita', 'calendario', 'Visita', 'Conoce el vehículo, tu cotización y tu crédito'],
                          ['apartado', 'etiqueta', 'Apartar vehículo', 'Reserva una unidad y define tu enganche'],
                          ['servicio', 'herramienta', 'Servicio de taller', 'Orden de servicio con tu propio vehículo']] as [$valor, $ic, $titulo, $desc]): ?>
            <label class="opcion-tarjeta">
              <input type="radio" name="tipo" value="<?= $valor ?>" <?= $tipo === $valor ? 'checked' : '' ?>>
              <span class="icono-caja"><?= icono($ic) ?></span>
              <span><strong><?= $titulo ?></strong><p><?= $desc ?></p></span>
            </label>
          <?php endforeach; ?>
        </div>
      </div>

      <!-- 2. VEHÍCULO -->
      <div class="bloque-checkout">
        <h2><span class="num">2</span> <span id="tituloVehiculo">Vehículo de tu interés</span></h2>
        <div id="bloqueVehiculoCatalogo">
          <div class="campos">
            <div class="campo"><label for="agMarca">Marca</label><select id="agMarca"><?php foreach (CAT_MARCAS as $m): ?><option><?= e($m) ?></option><?php endforeach; ?></select></div>
            <div class="campo"><label for="agVehiculo">Modelo</label><select id="agVehiculo" name="id_producto"></select></div>
          </div>
          <div class="vehiculo-elegido" id="vehiculoElegido" style="margin-top:16px;"></div>
        </div>
        <div id="bloqueVehiculoServicio" class="oculto">
          <div class="campos">
            <div class="campo ancho"><label for="agVehCliente">Tu vehículo (marca, modelo y año)</label><input id="agVehCliente" name="vehiculo_cliente" maxlength="150" placeholder="Ej. Audi Q5 2022"></div>
            <div class="campo"><label for="agVin">VIN <span class="opcional">(opcional, 17 caracteres)</span></label><input id="agVin" name="vin" maxlength="17" style="text-transform:uppercase" placeholder="WAUZZZ…"></div>
            <div class="campo"><label for="agKm">Kilometraje <span class="opcional">(opcional)</span></label><input id="agKm" name="kilometraje" type="number" min="0" max="999999" inputmode="numeric"></div>
            <div class="campo ancho"><label for="agServicio">Servicio</label>
              <select id="agServicio" name="tipo_servicio"><?php foreach (CAT_SERVICIOS_TALLER as $ts): ?><option <?= $servicioInicial === $ts ? 'selected' : '' ?>><?= e($ts) ?></option><?php endforeach; ?></select></div>
          </div>
        </div>
        <!-- Servicios que se agregan a la compra (visita o apartado); se envían en los comentarios de la cita -->
        <div id="bloqueExtras" class="extras-cita">
          <span class="etiqueta-campo">Servicios adicionales <span class="opcional">(opcional)</span></span>
          <div class="casillas-servicios">
            <?php foreach (CAT_SERVICIOS_COMPRA as $sv): ?>
              <label class="casilla"><input type="checkbox" name="servicios_extra" value="<?= e($sv) ?>" <?= $servicioInicial === $sv ? 'checked' : '' ?>> <span><?= e($sv) ?></span></label>
            <?php endforeach; ?>
          </div>
        </div>
      </div>

      <!-- 3. SUCURSAL -->
      <div class="bloque-checkout">
        <h2><span class="num">3</span> Sucursal</h2>
        <p id="ayudaSucursal">Cada sucursal tiene su propio inventario.</p>
        <div class="sucursales-opciones" id="opcionesSucursal">
          <?php foreach (catSucursales() as $s): ?>
            <label class="opcion-tarjeta" data-sucursal="<?= $s['id_sucursal'] ?>">
              <input type="radio" name="id_sucursal" value="<?= $s['id_sucursal'] ?>" <?= $s['id_sucursal'] === $sucursal['id_sucursal'] ? 'checked' : '' ?>>
              <span class="icono-caja"><?= icono('ubicacion') ?></span>
              <span><strong translate="no">KARMA <?= e($s['nombre']) ?></strong><p><?= e($s['direccion']) ?></p><p class="disp" data-stock-sucursal></p></span>
            </label>
          <?php endforeach; ?>
        </div>
      </div>

      <!-- 4. FECHA Y HORA -->
      <div class="bloque-checkout">
        <h2><span class="num">4</span> Fecha y hora</h2>
        <p>Lunes a viernes de 9:00 a 18:00 y sábados de 9:00 a 13:00. Domingos cerrado.</p>
        <div class="campos campos--fecha-hora">
          <div class="campo"><label for="agFecha">Fecha</label><input id="agFecha" name="fecha" type="date" min="<?= $manana ?>" max="<?= $limite ?>" required></div>
          <div class="campo"><span class="etiqueta-campo">Horarios disponibles</span><div class="horas" id="agHoras"><p class="texto-3" style="grid-column:1/-1">Elige una fecha para ver los horarios.</p></div></div>
        </div>
        <input type="hidden" name="hora" id="agHora">
      </div>

      <!-- 5. DATOS -->
      <div class="bloque-checkout">
        <h2><span class="num">5</span> Tus datos</h2>
        <div class="campos">
          <div class="campo ancho"><label for="agNombre">Nombre completo</label><input id="agNombre" name="nombre" required maxlength="150" autocomplete="name" value="<?= e($cliente['nombre']) ?>"></div>
          <div class="campo"><label for="agEmail">Correo electrónico</label><input id="agEmail" name="email" type="email" required maxlength="120" autocomplete="email" value="<?= e($cliente['email']) ?>"></div>
          <div class="campo"><label for="agTel">Teléfono</label><input id="agTel" name="telefono" type="tel" required maxlength="20" autocomplete="tel" value="<?= e($cliente['celular'] ?? '') ?>"></div>
          <div class="campo oculto" id="campoEnganche"><label for="agEnganche">Enganche que planeas dejar <span class="opcional">(opcional)</span></label><input id="agEnganche" name="enganche" type="number" min="0" step="1000" inputmode="numeric" placeholder="Ej. 300000"></div>
          <div class="campo oculto" id="campoColor"><label for="agColor">Color de preferencia <span class="opcional">(opcional)</span></label><input id="agColor" name="color" maxlength="80"></div>
          <div class="campo ancho"><label for="agComentarios">Comentarios <span class="opcional">(opcional)</span></label><textarea id="agComentarios" name="comentarios" maxlength="650" style="min-height:90px" placeholder="¿Algo que debamos saber?"><?= e($nota) ?></textarea></div>
        </div>
      </div>
    </div>

    <aside class="resumen-compra" id="resumenCita">
      <h2>Resumen de tu cita</h2>
      <div class="linea-resumen"><span>Tipo</span><strong id="rcTipo">—</strong></div>
      <div class="linea-resumen"><span>Vehículo</span><strong id="rcVehiculo" translate="no">—</strong></div>
      <div class="linea-resumen"><span>Servicios</span><strong id="rcServicios">—</strong></div>
      <div class="linea-resumen"><span>Sucursal</span><strong id="rcSucursal" translate="no">—</strong></div>
      <div class="linea-resumen"><span>Fecha</span><strong id="rcFecha">—</strong></div>
      <div class="linea-resumen"><span>Hora</span><strong id="rcHora">—</strong></div>
      <div class="mensaje-form" id="agMensaje" role="alert"></div>
      <button class="btn btn--primario btn--grande btn--bloque" type="submit" id="btnAgendar"><?= icono('calendario') ?> Confirmar cita</button>
      <p class="texto-3" style="font-size:12.5px;">Recibirás la confirmación en tu perfil. Puedes cancelar desde “Mis citas”.</p>
    </aside>
  </form>
  <div id="exitoCita" class="oculto" style="padding:48px 0 96px;"></div>
</div>

<script type="application/json" id="datosAgenda"><?= json_encode([
    'vehiculos' => $vehiculosJs, 'idProducto' => $idProducto,
    'sucursales' => array_map(fn($s) => ['id' => $s['id_sucursal'], 'nombre' => $s['nombre']], catSucursales())
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?></script>
<?php catPie(['scripts' => ['agendar.js']]); ?>
