/* ===== KARMA · Punto de Venta — Panel de Cajero (datos cargados desde MySQL mediante api.php) ===== */

/* Datos cargados desde la base de datos */
let CAJERO_ACTUAL = "Cargando…";
let SUCURSAL_ACTUAL = "Cargando…";
let SUCURSAL_ACTUAL_DIRECCION = "";
let SUCURSAL_ACTUAL_TELEFONO = "";
let CAJA_ACTUAL = "—";
let USUARIO_ACTUAL_ID = null;
let SUCURSAL_ACTUAL_ID = null;
let CAJA_ACTUAL_ID = null;

let INVENTARIO = [];
let CLIENTES = [];
let GARANTIAS = [];
let WEBORDERS = [];
let REFACCIONES = [];

// Valores fijos del módulo de crédito: tasa anual, comisión por apertura y plazos
const TASA_INTERES_ANUAL_DEFAULT = 18;
const COMISION_APERTURA_PCT = 0.02;
const PLAZOS_CREDITO = [12, 24, 36, 48, 60];

/* Estado de carga y sincronización */
let datosDBCargados = false;

// Token CSRF de la sesión del POS (lo publica index.php); se manda en cada petición a api.php
const CSRF_TOKEN = document.querySelector('meta[name="karma-csrf"]')?.content || "";

// Llama a api.php con la acción indicada y regresa su JSON (lanza error si el servidor responde con falla).
// options.autorizacion = permiso de un solo uso que entregó el servidor tras validar el gafete (acciones sensibles)
async function apiFetch(action, options = {}) {
  const url = `api.php?action=${encodeURIComponent(action)}`;
  const { autorizacion, ...opciones } = options;
  const headers = { "Content-Type": "application/json", "X-CSRF-Token": CSRF_TOKEN };
  if (autorizacion) headers["X-Karma-Autorizacion"] = autorizacion;
  const config = { headers, ...opciones };
  const response = await fetch(url, config);
  // Sesión del POS vencida o inexistente: se regresa a la pantalla de login
  if (response.status === 401 && action !== "logout"){
    window.location.href = "../../index.html?destino=pos";
    throw new Error("Tu sesión del Punto de Venta expiró.");
  }
  const data = await response.json().catch(() => ({ ok:false, error:"Respuesta inválida del servidor." }));
  if (!response.ok || data.ok === false) throw new Error(data.error || "No fue posible completar la solicitud.");
  return data;
}

/* Carga los catálogos y la sesión activa desde MySQL */
async function cargarDatosDB() {
  try {
    const data = await apiFetch("bootstrap");
    CAJERO_ACTUAL = data.usuario?.nombre || "—";
    SUCURSAL_ACTUAL = data.sucursal?.nombre || "—";
    SUCURSAL_ACTUAL_DIRECCION = data.sucursal?.direccion || "";
    SUCURSAL_ACTUAL_TELEFONO = data.sucursal?.telefono || "";
    CAJA_ACTUAL = String(data.caja?.numero_caja ?? "01").padStart(2, "0");
    USUARIO_ACTUAL_ID = data.usuario?.id_usuario ?? null;
    SUCURSAL_ACTUAL_ID = data.sucursal?.id_sucursal ?? null;
    CAJA_ACTUAL_ID = data.caja?.id_caja ?? null;
    // El número de ticket viene de la BD (ventas de hoy en esta caja) para que no se reinicie
    if (data.siguiente_ticket) ticketNumero = data.siguiente_ticket;

    INVENTARIO = data.inventario || [];
    CLIENTES = data.clientes || [];
    GARANTIAS = data.garantias || [];
    WEBORDERS = data.weborders || [];
    REFACCIONES = data.refacciones || [];
    datosDBCargados = true;

    $("#statusCajero").textContent = CAJERO_ACTUAL;
    $("#sedeValue") && ($("#sedeValue").textContent = SUCURSAL_ACTUAL);
    $("#statusCaja") && ($("#statusCaja").textContent = CAJA_ACTUAL);
    renderMain();
    renderShortcutsBar();
  } catch (error) {
    datosDBCargados = false;
    mostrarErrorDB(error.message);
  }
}

/* Muestra un aviso cuando la conexión con MySQL no está disponible */
function mostrarErrorDB(mensaje) {
  const main = $("#main");
  if (main) {
    main.innerHTML = `
      <section class="panel panel-full">
        <div class="empty-state">
          <strong>No se pudo conectar con la base de datos</strong>
          ${escapeHTML(mensaje)}
          <button class="btn btn-primary" id="btnReintentarDB" style="margin-top:16px;">Reintentar</button>
        </div>
      </section>`;
    $("#btnReintentarDB")?.addEventListener("click", cargarDatosDB);
  }
}

/* Refresca únicamente los catálogos que pueden cambiar después de una venta */
async function refrescarDatosDB() {
  const data = await apiFetch("bootstrap");
  INVENTARIO = data.inventario || [];
  CLIENTES = data.clientes || [];
  GARANTIAS = data.garantias || [];
  WEBORDERS = data.weborders || [];
  REFACCIONES = data.refacciones || [];
  if (data.siguiente_ticket) ticketNumero = data.siguiente_ticket;
}


/* ===== 2. ESTADO GLOBAL ===== */

let currentView = "venta";          // venta | inventario | clientes | garantias | weborders
let searchQuery = "";               // texto actual del buscador (su uso cambia según la vista)

// --- Estado del formulario de venta ---
let formTipoArticulo = "Vehiculo";  // 'Vehiculo' | 'Credito' | 'Refaccion' — toggle dentro del propio formulario
let borrador = {};                  // valores prellenados (ej. desde Web Orders → Continuar)
let modoCotizacion = false;         // F5 — simula una venta sin guardarla en el ticket

// --- Estado propio del módulo de Crédito ---
let creditoTipoProducto = "Vehiculo"; // El crédito solo financia vehículos; ya no existe la opción de Refacción
let mostrarTablaAmortizacion = false; // controla si la tabla mes a mes está desplegada

// --- Estado del ticket de venta actual ---
let ticketItems = [];               // artículos ya registrados en el ticket
let ticketIdCounter = 0;
let ticketNumero = 1;               // número de ticket, sube cada vez que se cancela (F6)
let modoEliminarTicket = false;     // F4 — muestra las "×" para quitar artículos
let pagoEstado = null;              // Estado temporal del cobro antes de guardar la venta
let ticketCerrado = null;            // Ticket confirmado que se muestra al cliente

// --- Estado de búsqueda dentro de Venta (autocompletado → resultados) ---
let ventaResultadosActivos = false; // true = se está mostrando la cuadrícula de resultados
let ventaResultadosQuery = "";

// --- Estado de otras vistas ---
let inventarioCategoria = null;     // null | 'Porsche' | 'Audi' | 'Ducati' | 'Refacciones'
let webOrdersFiltro = "Todo";       // Todo | Porsche | Audi | Ducati | Refacciones

/* ===== 3. HELPERS GENERALES ===== */
const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));

// Formatea números como pesos mexicanos; "—" si no hay valor
function formatoMoneda(n){
  if (n === null || n === undefined || n === "") return "—";
  return Number(n).toLocaleString("es-MX", { style: "currency", currency: "MXN", maximumFractionDigits: 0 });
}
// Igual que formatoMoneda pero con centavos (importe exacto que se cobra del enganche)
function formatoMonedaCentavos(n){
  if (n === null || n === undefined || n === "") return "—";
  return Number(n).toLocaleString("es-MX", { style: "currency", currency: "MXN", minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
// Evita inyección de HTML al insertar texto libre del usuario
function escapeHTML(str){
  return String(str ?? "").replace(/[&<>"']/g, s => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[s]));
}
// Imagen de referencia compartida (mockup: mismo asset para cualquier artículo)
function imagenAuto(){
  return `<img class="car-photo" src="../../assets/porsche.jpg" alt="Vista de referencia del vehículo" loading="lazy">`;
}

// Mensaje de existencia fiel a la base de datos: rojo si no hay unidades, azul si sí hay
function badgeStockHTML(unidades){
  const n = Number(unidades) || 0;
  if (n > 0){
    return `<span class="stock-badge stock-badge--ok">${n} unidad${n === 1 ? "" : "es"} disponible${n === 1 ? "" : "s"}</span>`;
  }
  return `<span class="stock-badge stock-badge--out">0 unidades disponibles</span>`;
}

// API DE TRADUCCIÓN: muestra un mensaje emergente traducido al idioma activo (usa KarmaTraductor.traducir)
async function avisar(mensaje){
  const texto = window.KarmaTraductor ? await window.KarmaTraductor.traducir(mensaje) : mensaje;
  alert(texto);
}

// Guarda en `borrador` lo que se escribe en un campo sin redibujar el panel (así no se pierde el foco)
function bindTexto(id, key, panel){
  $(`#${id}`, panel)?.addEventListener("input", (e) => { borrador[key] = e.target.value; });
}

// Íconos de línea para los 4 tiles de categoría de Inventario
const ICONOS_TIPO = {
  Porsche: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M3 16l1.5-5.5A3 3 0 0 1 7.4 8h9.2a3 3 0 0 1 2.9 2.5L21 16"/><path d="M3 16h18v2a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-1H7v1a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-2Z"/><circle cx="7.5" cy="16" r="1.4"/><circle cx="16.5" cy="16" r="1.4"/></svg>`,
  Audi: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="6" cy="12" r="3.4"/><circle cx="11" cy="12" r="3.4"/><circle cx="16" cy="12" r="3.4"/><circle cx="21" cy="12" r="3.4"/></svg>`,
  Ducati: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="5.5" cy="17" r="2.6"/><circle cx="18.5" cy="17" r="2.6"/><path d="M5.5 17l3-8h5l4 5h3M8.5 9h4"/></svg>`,
  Refacciones: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14.7 6.3a4 4 0 0 1-5.4 5.4L4 17l3 3 5.3-5.3a4 4 0 0 1 5.4-5.4l-2.6 2.6-2-2 2.6-2.6Z"/></svg>`
};

/* ===== 2b. INVENTARIO — cascada de vehículos: Marca → Modelo → Año → Color → Color interior → Motor → VIN ===== */

// Quita repetidos y valores vacíos de una lista
const unicos = (arr) => [...new Set(arr.filter(v => v !== null && v !== undefined && v !== ""))];

// Marcas de vehículos que existen en el inventario
function marcasDisponibles(){
  return unicos(INVENTARIO.filter(c => c.tipo !== "refaccion").map(c => c.marca));
}
// Modelos de una marca
function modelosDisponibles(marca){
  return unicos(INVENTARIO.filter(c => c.marca === marca && c.tipo !== "refaccion").map(c => c.modelo));
}
// Años de una marca + modelo, ordenados
function aniosDisponibles(marca, modelo){
  return unicos(INVENTARIO.filter(c => c.marca === marca && c.modelo === modelo && c.tipo !== "refaccion").map(c => c.anio))
    .sort((a, b) => a - b);
}
// Vehículos que coinciden con lo ya elegido (lo que falte por elegir no filtra)
function vehiculosCoincidentes(b){
  return INVENTARIO.filter(c =>
    c.tipo !== "refaccion" &&
    (!b.marca || c.marca === b.marca) &&
    (!b.modelo || c.modelo === b.modelo) &&
    (!b.anio || String(c.anio) === String(b.anio)) &&
    (!b.color || c.color === b.color) &&
    (!b.colorInterior || c.colorInterior === b.colorInterior) &&
    (!b.motor || c.motor === b.motor)
  );
}
// Colores de una marca + modelo + año
function coloresDisponibles(marca, modelo, anio){
  return unicos(vehiculosCoincidentes({ marca, modelo, anio }).map(c => c.color));
}
// Colores interiores según lo ya elegido
function interioresDisponibles(b){
  return unicos(vehiculosCoincidentes({ marca: b.marca, modelo: b.modelo, anio: b.anio, color: b.color }).map(c => c.colorInterior));
}
// Motores según lo ya elegido
function motoresVehiculoDisponibles(b){
  return unicos(vehiculosCoincidentes({ marca: b.marca, modelo: b.modelo, anio: b.anio, color: b.color, colorInterior: b.colorInterior }).map(c => c.motor));
}
// VIN registrados de los vehículos que coinciden con lo elegido (sin nada elegido, salen todos)
function vinsDisponibles(b){
  return unicos(vehiculosCoincidentes({ marca: b.marca, modelo: b.modelo, anio: b.anio, color: b.color, colorInterior: b.colorInterior, motor: b.motor }).map(c => c.vin));
}
// Vehículo exacto elegido (null hasta completar la cascada); también regresa los que tienen 0 unidades
function articuloDeBorrador(b){
  if (!b.marca || !b.modelo || !b.anio || !b.color) return null;
  if (interioresDisponibles(b).length && !b.colorInterior) return null;
  if (motoresVehiculoDisponibles(b).length && !b.motor) return null;
  return vehiculosCoincidentes(b)[0] || null;
}
// Copia al borrador todos los datos de un vehículo (se usa con el código de barras y con el VIN)
function aplicarVehiculoAlBorrador(m){
  borrador.marca = m.marca; borrador.modelo = m.modelo; borrador.anio = m.anio; borrador.color = m.color;
  borrador.colorInterior = m.colorInterior || undefined; borrador.motor = m.motor || undefined;
  borrador.vin = m.vin || undefined;
}
// Tras cada cambio: autoselecciona lo que solo tenga una opción (incluido el VIN) y limpia lo que ya no aplica
function recalcularCascadaVehiculo(){
  const b = borrador;
  const modelos = b.marca ? modelosDisponibles(b.marca) : [];
  if (!modelos.includes(b.modelo)) b.modelo = modelos.length === 1 ? modelos[0] : undefined;

  const anios = (b.marca && b.modelo) ? aniosDisponibles(b.marca, b.modelo) : [];
  if (!anios.map(String).includes(String(b.anio))) b.anio = anios.length === 1 ? anios[0] : undefined;

  const colores = (b.marca && b.modelo && b.anio) ? coloresDisponibles(b.marca, b.modelo, b.anio) : [];
  if (!colores.includes(b.color)) b.color = colores.length === 1 ? colores[0] : undefined;

  const interiores = b.color ? interioresDisponibles(b) : [];
  if (!interiores.includes(b.colorInterior)) b.colorInterior = interiores.length === 1 ? interiores[0] : undefined;

  const motores = b.color ? motoresVehiculoDisponibles(b) : [];
  if (!motores.includes(b.motor)) b.motor = motores.length === 1 ? motores[0] : undefined;

  const vins = vinsDisponibles(b);
  if (!vins.includes(b.vin)) b.vin = vins.length === 1 ? vins[0] : undefined;
}

// Busca un producto por su código de barras exacto dentro del catálogo que ya existe en la BD
function buscarPorCodigoBarras(codigo, catalogo){
  const q = String(codigo || "").trim().toUpperCase();
  if (!q) return null;
  return catalogo.find(c => String(c.codigo || "").trim().toUpperCase() === q) || null;
}

// Campo de código de barras: al coincidir exacto con un producto autocompleta los cajones sin perder el cursor
function bindCodigoBarras(idInput, panel, catalogo, aplicar, onChange){
  const inp = $(`#${idInput}`, panel);
  if (!inp) return;
  inp.addEventListener("input", () => {
    borrador.codigoBarras = inp.value.trim() || undefined;
    const match = borrador.codigoBarras ? buscarPorCodigoBarras(borrador.codigoBarras, catalogo()) : null;
    if (!match) return;
    const pos = inp.selectionStart;
    aplicar(match);
    onChange();
    const nuevo = document.getElementById(idInput);
    if (nuevo){ nuevo.focus(); nuevo.setSelectionRange(pos, pos); }
  });
  inp.addEventListener("change", () => {
    borrador.codigoBarras = inp.value.trim() || undefined;
    const match = borrador.codigoBarras ? buscarPorCodigoBarras(borrador.codigoBarras, catalogo()) : null;
    if (match) aplicar(match);
    onChange();
  });
}

/* ===== 2c. REFACCIONES — cascada Marca → Modelo → Año → Tracción → Lado → Motor → Pieza (sin texto libre) ===== */

// Marcas con refacciones registradas
function refMarcasDisponibles(){
  return [...new Set(REFACCIONES.map(r => r.marca).filter(Boolean))];
}
// Modelos compatibles de una marca
function refModelosDisponibles(marca){
  return [...new Set(REFACCIONES.filter(r => r.marca === marca).map(r => r.modelo).filter(Boolean))];
}
// Años registrados para una marca + modelo
function refAniosDisponibles(marca, modelo){
  return [...new Set(REFACCIONES.filter(r => r.marca === marca && r.modelo === modelo).map(r => r.anio).filter(Boolean))]
    .sort((a, b) => a - b);
}
// Tracciones registradas según lo elegido
function refTraccionesDisponibles(marca, modelo, anio){
  return [...new Set(REFACCIONES.filter(r => r.marca === marca && r.modelo === modelo && (!anio || String(r.anio) === String(anio))).map(r => r.traccion).filter(Boolean))];
}
// Lados registrados según lo elegido
function refLadosDisponibles(marca, modelo, anio, traccion){
  return [...new Set(REFACCIONES.filter(r =>
    r.marca === marca && r.modelo === modelo && (!anio || String(r.anio) === String(anio)) && (!traccion || r.traccion === traccion)
  ).map(r => r.lado).filter(Boolean))];
}
// Motores registrados según lo elegido
function refMotoresDisponibles(marca, modelo, anio, traccion, lado){
  return [...new Set(REFACCIONES.filter(r =>
    r.marca === marca && r.modelo === modelo && (!anio || String(r.anio) === String(anio)) &&
    (!traccion || r.traccion === traccion) && (!lado || r.lado === lado)
  ).map(r => r.motor).filter(Boolean))];
}
// Indica si ya se puede elegir el detalle (el año solo es obligatorio si la marca + modelo tiene años)
function refListoParaDetalle(b){
  if (!b.marcaVehiculo || !b.modelo) return false;
  return !!b.anio || refAniosDisponibles(b.marcaVehiculo, b.modelo).length === 0;
}
// Piezas que coinciden con todo lo ya elegido (lo que falte por elegir no filtra)
function refPiezasDisponibles(b){
  if (!refListoParaDetalle(b)) return [];
  return REFACCIONES.filter(r =>
    r.marca === b.marcaVehiculo && r.modelo === b.modelo && (!b.anio || String(r.anio) === String(b.anio)) &&
    (!b.traccion || r.traccion === b.traccion) &&
    (!b.lado || r.lado === b.lado) &&
    (!b.motor || r.motor === b.motor)
  );
}
// Tras cada cambio: autoselecciona lo que solo tenga una opción y limpia lo que ya no aplica
function recalcularCascadaRefaccion(){
  const b = borrador;

  const modelos = b.marcaVehiculo ? refModelosDisponibles(b.marcaVehiculo) : [];
  if (!modelos.includes(b.modelo)) b.modelo = modelos.length === 1 ? modelos[0] : undefined;

  const anios = (b.marcaVehiculo && b.modelo) ? refAniosDisponibles(b.marcaVehiculo, b.modelo) : [];
  if (!anios.map(String).includes(String(b.anio))) b.anio = anios.length === 1 ? anios[0] : undefined;

  const tracciones = refListoParaDetalle(b) ? refTraccionesDisponibles(b.marcaVehiculo, b.modelo, b.anio) : [];
  if (!tracciones.includes(b.traccion)) b.traccion = tracciones.length === 1 ? tracciones[0] : undefined;

  const lados = refListoParaDetalle(b) ? refLadosDisponibles(b.marcaVehiculo, b.modelo, b.anio, b.traccion) : [];
  if (!lados.includes(b.lado)) b.lado = lados.length === 1 ? lados[0] : undefined;

  const motores = refListoParaDetalle(b) ? refMotoresDisponibles(b.marcaVehiculo, b.modelo, b.anio, b.traccion, b.lado) : [];
  if (!motores.includes(b.motor)) b.motor = motores.length === 1 ? motores[0] : undefined;

  const piezas = refPiezasDisponibles(b);
  if (!piezas.some(p => String(p.id) === String(b.piezaId))) b.piezaId = piezas.length === 1 ? piezas[0].id : undefined;
}

/* ===== 3. NAVEGACIÓN ENTRE VISTAS ===== */

// Cambia de pestaña: resetea estados temporales de UI y vuelve a dibujar todo
function setActiveView(view){
  currentView = view;
  inventarioCategoria = null;   // al salir de Inventario y volver, se empieza desde el inicio (sin filtro)
  ventaResultadosActivos = false;
  modoCotizacion = false;
  modoEliminarTicket = false;
  mostrarTablaAmortizacion = false;
  cerrarSugerencias();
  searchQuery = "";
  $("#searchInput").value = "";
  actualizarPlaceholderBusqueda();
  $$(".sub-nav-btn").forEach(btn => btn.classList.toggle("is-active", btn.dataset.view === view));
  renderMain();
}

// El logo "K" siempre regresa a Venta, sin importar en qué vista se esté
function irAInicio(){ setActiveView("venta"); }

// Cambia el texto de ayuda del buscador según la sección activa
function actualizarPlaceholderBusqueda(){
  const textos = {
    venta: "Buscar artículo o modelo…",
    inventario: "Buscar por nombre o código…",
    clientes: "Buscar cliente…",
    garantias: "Buscar cliente o artículo…",
    weborders: "Buscar por nombre de cliente…"
  };
  $("#searchInput").placeholder = textos[currentView] || "Buscar…";
}

// Punto de entrada de render: decide qué vista dibujar dentro de <main>
function renderMain(){
  const main = $("#main");

  if (currentView === "venta" && ventaResultadosActivos){
    // Modo "resultados de búsqueda": cuadrícula a pantalla completa
    main.innerHTML = `<section class="panel panel-full" id="panelFull"></section>`;
    renderResultadosBusqueda();
  } else if (currentView === "venta"){
    // Modo normal: formulario (3/5) + ticket (2/5)
    main.innerHTML = `
      <section class="panel panel-venta" id="panelVenta"></section>
      <section class="panel panel-lateral" id="panelLateral"></section>
    `;
    renderPanelVenta();
    renderPanelLateral();
  } else {
    // Resto de vistas: un solo panel a todo lo ancho
    main.innerHTML = `<section class="panel panel-full" id="panelFull"></section>`;
    if (currentView === "inventario") renderInventario();
    else if (currentView === "clientes") renderClientes();
    else if (currentView === "garantias") renderGarantias();
    else if (currentView === "weborders") renderWebOrders();
  }

  renderShortcutsBar();
}

/* ===== 4. VENTA — formulario de registro (izquierda, 3/5) ===== */

// Dibuja el formulario completo (toggle de tipo + campos + acciones)
function renderPanelVenta(){
  const panel = $("#panelVenta");
  if (!panel) return;
  // Se conserva la posición del scroll al redibujar (plazo, tipo de enganche, cajones…). En pantallas angostas el que se
  // desplaza es <main> (formulario y ticket apilados), por eso se guardan los dos
  const main = $("#main");
  const scroll = panel.scrollTop, scrollMain = main ? main.scrollTop : 0;
  panel.innerHTML = formularioVentaHTML();
  bindFormularioVenta();
  montarVistaPrevia3D();
  panel.scrollTop = scroll;
  if (main) main.scrollTop = scrollMain;
}

// Producto que debe verse en la vista previa 3D según la pestaña activa (null si aún no está completo)
function productoVistaPrevia(){
  if (formTipoArticulo === "Refaccion"){
    const pieza = REFACCIONES.find(r => String(r.id) === String(borrador.piezaId));
    return pieza ? { ...pieza, tipo: "refaccion" } : null;
  }
  return articuloDeBorrador(borrador);
}

// Cuadro HTML de la vista previa 3D (el visor de Three.js se coloca dentro al terminar de dibujar)
function vistaPrevia3DHTML(){
  return `
    <div class="form-field span-2">
      <label>Vista previa 3D</label>
      <div class="vista3d" id="vistaPrevia3D">
        <div class="vista3d-cargando"><span class="vista3d-spinner"></span><span>Cargando vista previa…</span></div>
      </div>
    </div>`;
}

// Coloca el visor 3D en su cuadro (o un aviso si la librería 3D no pudo cargarse)
function montarVistaPrevia3D(){
  const caja = $("#vistaPrevia3D");
  if (!caja) return;
  if (window.KarmaVista3D) window.KarmaVista3D.mostrar(caja, productoVistaPrevia());
  else if (window.KARMA_VISTA3D_FALLO) caja.innerHTML = `<div class="vista3d-cargando">No se pudo cargar la librería 3D. Revisa tu conexión a internet.</div>`;
}

// Arma el HTML del formulario según el tipo elegido y si es cotización
function formularioVentaHTML(){
  const b = borrador;
  return `
    <div class="panel-heading"><h2>${modoCotizacion ? "Cotización" : "Registrar venta"}</h2></div>

    ${modoCotizacion ? `<div class="cotizacion-banner"><span>Modo cotización — esta venta no se guardará en el ticket</span></div>` : ""}
    ${b.articuloRef ? `<div class="hint-banner">Interés registrado en la web: <strong>${escapeHTML(b.articuloRef)}</strong>${b.colorRef ? " — " + escapeHTML(b.colorRef) : ""}</div>` : ""}

    <!-- Toggle Vehículo / Crédito / Refacción: reemplaza los antiguos cuadros divisores -->
    <div class="segmented tipo-articulo-toggle">
      <button type="button" class="segmented-btn ${formTipoArticulo === "Vehiculo" ? "is-active" : ""}" data-form-tipo="Vehiculo">Vehículo</button>
      <button type="button" class="segmented-btn ${formTipoArticulo === "Credito" ? "is-active" : ""}" data-form-tipo="Credito">Crédito</button>
      <button type="button" class="segmented-btn ${formTipoArticulo === "Refaccion" ? "is-active" : ""}" data-form-tipo="Refaccion">Refacción</button>
    </div>

    ${formTipoArticulo === "Refaccion" ? camposRefaccionHTML()
      : formTipoArticulo === "Credito" ? camposCreditoHTML()
      : camposVehiculoHTML()}

    <div class="venta-actions">
      ${modoCotizacion ? `
        <button class="btn btn-primary" id="btnCalcularCotizacion">Calcular cotización</button>
        <button class="btn btn-ghost" id="btnSalirCotizacion">Salir de cotización</button>
      ` : `
        <button class="btn btn-primary" id="btnGuardarArticulo">Guardar</button>
        <button class="btn btn-ghost" id="btnCancelarArticulo">Cancelar</button>
      `}
    </div>
    <div id="cotizacionResultadoWrap"></div>
  `;
}

// Código de barras + cascada de vehículo + unidades/precio + vista 3D (se usa en Vehículo y en Crédito)
function selectoresArticuloHTML(idPrefix, b){
  const marcas = marcasDisponibles();
  const modelos = b.marca ? modelosDisponibles(b.marca) : [];
  const anios = (b.marca && b.modelo) ? aniosDisponibles(b.marca, b.modelo) : [];
  const colores = (b.marca && b.modelo && b.anio) ? coloresDisponibles(b.marca, b.modelo, b.anio) : [];
  const interiores = b.color ? interioresDisponibles(b) : [];
  const motores = b.color ? motoresVehiculoDisponibles(b) : [];
  const item = articuloDeBorrador(b);
  const matchCodigo = b.codigoBarras
    ? buscarPorCodigoBarras(b.codigoBarras, INVENTARIO.filter(c => c.tipo !== "refaccion"))
    : null;

  // Arma las <option> de un cajón marcando la que ya está elegida
  const opciones = (lista, actual) => lista.map(v => `<option value="${escapeHTML(String(v))}" ${String(actual) === String(v) ? "selected" : ""}>${escapeHTML(String(v))}</option>`).join("");

  return `
    <div class="form-field span-2">
      <label>Código de barras</label>
      <input type="text" id="sel${idPrefix}Codigo" value="${escapeHTML(b.codigoBarras || "")}" placeholder="Escanea o escribe el código de barras" autocomplete="off">
      ${!b.codigoBarras
        ? `<div class="form-field-info">Al confirmarlo, autocompleta todos los cajones. También puedes elegir manualmente abajo.</div>`
        : matchCodigo
          ? `<div class="form-field-info form-field-info--ok">Código confirmado — ${escapeHTML(matchCodigo.nombre)}</div>`
          : `<div class="form-field-info form-field-info--error">Ese código no coincide con ningún producto registrado.</div>`
      }
    </div>
    <div class="form-field">
      <label>Marca</label>
      <select id="sel${idPrefix}Marca">
        <option value="">Selecciona…</option>
        ${opciones(marcas, b.marca)}
      </select>
    </div>
    <div class="form-field">
      <label>Modelo</label>
      <select id="sel${idPrefix}Modelo" ${!b.marca ? "disabled" : ""}>
        <option value="">${b.marca ? "Selecciona…" : "Elige una marca primero"}</option>
        ${opciones(modelos, b.modelo)}
      </select>
    </div>
    <div class="form-field">
      <label>Año</label>
      <select id="sel${idPrefix}Anio" ${!b.modelo ? "disabled" : ""}>
        <option value="">${b.modelo ? "Selecciona…" : "Elige un modelo primero"}</option>
        ${opciones(anios, b.anio)}
      </select>
    </div>
    <div class="form-field">
      <label>Color</label>
      <select id="sel${idPrefix}Color" ${!b.anio ? "disabled" : ""}>
        <option value="">${b.anio ? "Selecciona…" : "Elige un año primero"}</option>
        ${opciones(colores, b.color)}
      </select>
    </div>
    <div class="form-field">
      <label>Color interior</label>
      <select id="sel${idPrefix}Interior" ${!interiores.length ? "disabled" : ""}>
        <option value="">${!b.color ? "Elige un color primero" : (interiores.length ? "Selecciona…" : "Sin dato registrado")}</option>
        ${opciones(interiores, b.colorInterior)}
      </select>
    </div>
    <div class="form-field">
      <label>Motor</label>
      <select id="sel${idPrefix}Motor" ${!motores.length ? "disabled" : ""}>
        <option value="">${!b.color ? "Elige un color primero" : (motores.length ? "Selecciona…" : "Sin dato registrado")}</option>
        ${opciones(motores, b.motor)}
      </select>
    </div>
    <div class="form-field span-2">
      ${item
        ? `<div class="stock-price-box">
             <div><span>Unidades disponibles</span><strong>${badgeStockHTML(item.unidades)}</strong></div>
             <div><span>Precio</span><strong>${formatoMoneda(item.precio)}</strong></div>
           </div>`
        : `<div class="form-field-info">Elige marca, modelo, año, color, color interior y motor para ver unidades y precio.</div>`
      }
    </div>
    ${item ? vistaPrevia3DHTML() : ""}
  `;
}

// Conecta el código de barras y los cajones de la cascada; cada cambio limpia lo dependiente y redibuja
function bindSelectoresArticulo(idPrefix, panel, onChange){
  bindCodigoBarras(`sel${idPrefix}Codigo`, panel,
    () => INVENTARIO.filter(c => c.tipo !== "refaccion"),
    aplicarVehiculoAlBorrador,
    onChange);

  // Enlaza un cajón: guarda el valor, recalcula la cascada y redibuja
  const enlazar = (sufijo, asignar) => {
    $(`#sel${idPrefix}${sufijo}`, panel)?.addEventListener("change", (e) => {
      asignar(e.target.value || undefined);
      recalcularCascadaVehiculo();
      onChange();
    });
  };
  enlazar("Marca",    v => { borrador.marca = v; borrador.modelo = borrador.anio = borrador.color = borrador.colorInterior = borrador.motor = undefined; });
  enlazar("Modelo",   v => { borrador.modelo = v; borrador.anio = borrador.color = borrador.colorInterior = borrador.motor = undefined; });
  enlazar("Anio",     v => { borrador.anio = v; borrador.color = borrador.colorInterior = borrador.motor = undefined; });
  enlazar("Color",    v => { borrador.color = v; borrador.colorInterior = borrador.motor = undefined; });
  enlazar("Interior", v => { borrador.colorInterior = v; borrador.motor = undefined; });
  enlazar("Motor",    v => { borrador.motor = v; });
}

// Campos para la venta de contado de un vehículo (el precio viene del inventario, sin enganche ni abonos)
function camposVehiculoHTML(){
  const b = borrador;
  return `
    <div class="form-grid">
      <div class="form-field"><label>Cliente</label><input type="text" id="inpCliente" value="${escapeHTML(b.cliente || "")}" placeholder="Nombre completo"></div>
      <div class="form-field"><label>RFC / INE</label><input type="text" id="inpRfcIne" value="${escapeHTML(b.rfcIne || "")}" placeholder="Identificación"></div>
      <div class="form-field"><label>Email</label><input type="email" id="inpEmail" value="${escapeHTML(b.email || "")}" placeholder="correo@ejemplo.com"></div>
      <div class="form-field"><label>Celular</label><input type="tel" id="inpCelular" value="${escapeHTML(b.celular || "")}" placeholder="10 dígitos"></div>

      ${selectoresArticuloHTML("Vehiculo", b)}

      ${camposExtraVehiculoHTML("", b)}
    </div>
  `;
}

// Campos extra del ticket completo: dirección, identificación y el VIN (cajita con los VIN registrados).
// conNumeroId = true agrega el número de la identificación (lo pide el contrato de crédito)
function camposExtraVehiculoHTML(sufijo, b, conNumeroId = false){
  const vins = vinsDisponibles(b);
  // Texto de cada VIN en la lista: VIN · marca modelo año
  const textoVin = (vin) => {
    const car = INVENTARIO.find(c => c.tipo !== "refaccion" && c.vin === vin);
    return car ? `${vin} · ${car.marca} ${car.modelo} ${car.anio ?? ""}` : vin;
  };
  return `
    <div class="form-field span-2"><label>Dirección del cliente</label><input type="text" id="inpDireccion${sufijo}" value="${escapeHTML(b.direccion || "")}" placeholder="Calle, número, colonia, ciudad"></div>
    <div class="form-field">
      <label>Identificación oficial</label>
      <select id="selIdentificacion${sufijo}">
        <option value="INE" ${(!b.identificacionTipo || b.identificacionTipo === "INE") ? "selected" : ""}>INE</option>
        <option value="Pasaporte" ${b.identificacionTipo === "Pasaporte" ? "selected" : ""}>Pasaporte</option>
        <option value="Otra" ${b.identificacionTipo === "Otra" ? "selected" : ""}>Otra</option>
      </select>
    </div>
    ${conNumeroId ? `<div class="form-field"><label>Número de identificación</label><input type="text" id="inpIdNumero${sufijo}" value="${escapeHTML(b.identificacionNumero || "")}" placeholder="Folio / número del documento" autocomplete="off"></div>` : ""}
    <div class="form-field span-2">
      <label>VIN / Número de serie de la unidad</label>
      <select id="selVin${sufijo}" ${!vins.length ? "disabled" : ""}>
        <option value="">${vins.length ? "Selecciona…" : "Sin VIN registrado para esta combinación"}</option>
        ${vins.map(v => `<option value="${escapeHTML(v)}" translate="no" ${b.vin === v ? "selected" : ""}>${escapeHTML(textoVin(v))}</option>`).join("")}
      </select>
      <div class="form-field-info">Al elegir un VIN se autocompletan marca, modelo, año, color, interior y motor.</div>
    </div>
  `;
}

// Cajita de VIN: al elegir uno se llenan todos los cajones con el vehículo al que pertenece
function bindSelectVin(idSelect, panel, onChange){
  $(`#${idSelect}`, panel)?.addEventListener("change", (e) => {
    const vin = e.target.value || undefined;
    const car = vin ? INVENTARIO.find(c => c.tipo !== "refaccion" && c.vin === vin) : null;
    if (car) aplicarVehiculoAlBorrador(car);
    else borrador.vin = undefined;
    onChange();
  });
}

// Código de barras + cascada de refacción + existencia/precio + vista 3D de la pieza elegida
function selectoresRefaccionHTML(b){
  const marcas = refMarcasDisponibles();
  const modelos = b.marcaVehiculo ? refModelosDisponibles(b.marcaVehiculo) : [];
  const anios = (b.marcaVehiculo && b.modelo) ? refAniosDisponibles(b.marcaVehiculo, b.modelo) : [];
  const tracciones = refListoParaDetalle(b) ? refTraccionesDisponibles(b.marcaVehiculo, b.modelo, b.anio) : [];
  const lados = refListoParaDetalle(b) ? refLadosDisponibles(b.marcaVehiculo, b.modelo, b.anio, b.traccion) : [];
  const motores = refListoParaDetalle(b) ? refMotoresDisponibles(b.marcaVehiculo, b.modelo, b.anio, b.traccion, b.lado) : [];
  const piezas = refPiezasDisponibles(b);
  const listo = refListoParaDetalle(b);
  const match = piezas.find(p => String(p.id) === String(b.piezaId)) || null;
  const matchCodigo = b.codigoBarras
    ? buscarPorCodigoBarras(b.codigoBarras, REFACCIONES)
    : null;

  return `
    <div class="form-field span-2">
      <label>Código de barras</label>
      <input type="text" id="selRefCodigo" value="${escapeHTML(b.codigoBarras || "")}" placeholder="Escanea o escribe el código de barras" autocomplete="off">
      ${!b.codigoBarras
        ? `<div class="form-field-info">Al confirmarlo, autocompleta marca, modelo, año, tracción, lado, motor y pieza.</div>`
        : matchCodigo
          ? `<div class="form-field-info form-field-info--ok">Código confirmado — ${escapeHTML(matchCodigo.nombre)}</div>`
          : `<div class="form-field-info form-field-info--error">Ese código no coincide con ninguna refacción registrada.</div>`
      }
    </div>
    <div class="form-field">
      <label>Marca del vehículo</label>
      <select id="selRefMarca">
        <option value="">Selecciona…</option>
        ${marcas.map(m => `<option value="${escapeHTML(m)}" ${b.marcaVehiculo === m ? "selected" : ""}>${escapeHTML(m)}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Modelo compatible</label>
      <select id="selRefModelo" ${!b.marcaVehiculo ? "disabled" : ""}>
        <option value="">${b.marcaVehiculo ? "Selecciona…" : "Elige una marca primero"}</option>
        ${modelos.map(m => `<option value="${escapeHTML(m)}" ${b.modelo === m ? "selected" : ""}>${escapeHTML(m)}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Año</label>
      <select id="selRefAnio" ${(!b.modelo || !anios.length) ? "disabled" : ""}>
        <option value="">${!b.modelo ? "Elige un modelo primero" : (anios.length ? "Selecciona…" : "Sin dato registrado")}</option>
        ${anios.map(a => `<option value="${a}" ${String(b.anio) === String(a) ? "selected" : ""}>${a}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Tracción</label>
      <select id="selRefTraccion" ${!tracciones.length ? "disabled" : ""}>
        <option value="">${tracciones.length ? "Selecciona…" : (listo ? "Sin dato registrado" : "Elige un modelo primero")}</option>
        ${tracciones.map(t => `<option value="${escapeHTML(t)}" ${b.traccion === t ? "selected" : ""}>${escapeHTML(t)}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Lado</label>
      <select id="selRefLado" ${!lados.length ? "disabled" : ""}>
        <option value="">${lados.length ? "Selecciona…" : (listo ? "Sin dato registrado" : "Elige un modelo primero")}</option>
        ${lados.map(l => `<option value="${escapeHTML(l)}" ${b.lado === l ? "selected" : ""}>${escapeHTML(l)}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Motor</label>
      <select id="selRefMotor" ${!motores.length ? "disabled" : ""}>
        <option value="">${motores.length ? "Selecciona…" : (listo ? "Sin dato registrado" : "Elige un modelo primero")}</option>
        ${motores.map(m => `<option value="${escapeHTML(m)}" ${b.motor === m ? "selected" : ""}>${escapeHTML(m)}</option>`).join("")}
      </select>
    </div>
    <div class="form-field span-2">
      <label>Pieza / refacción</label>
      <select id="selRefPieza" ${!piezas.length ? "disabled" : ""}>
        <option value="">${piezas.length ? "Selecciona…" : "No hay piezas registradas para esta combinación"}</option>
        ${piezas.map(p => `<option value="${p.id}" ${String(b.piezaId) === String(p.id) ? "selected" : ""}>${escapeHTML(p.nombre)}</option>`).join("")}
      </select>
    </div>
    <div class="form-field span-2">
      ${match
        ? `<div class="stock-price-box">
             <div><span>Unidades disponibles</span><strong>${badgeStockHTML(match.unidades)}</strong></div>
             <div><span>Precio</span><strong>${formatoMoneda(match.precio)}</strong></div>
           </div>`
        : `<div class="form-field-info">Elige marca, modelo, año y pieza para ver existencia y precio.</div>`
      }
    </div>
    ${match ? vistaPrevia3DHTML() : ""}
  `;
}

// Conecta el código de barras y los 7 cajones de Refacción; cada cambio limpia lo dependiente y redibuja
function bindSelectoresRefaccion(panel, onChange){
  // Limpiadores: borran los niveles que dependen del cajón que cambió
  const limpiarDesdeMarca = () => { borrador.modelo = borrador.anio = borrador.traccion = borrador.lado = borrador.motor = borrador.piezaId = undefined; };
  const limpiarDesdeModelo = () => { borrador.anio = borrador.traccion = borrador.lado = borrador.motor = borrador.piezaId = undefined; };
  const limpiarDesdeAnio = () => { borrador.traccion = borrador.lado = borrador.motor = borrador.piezaId = undefined; };
  const limpiarDesdeTraccion = () => { borrador.lado = borrador.motor = borrador.piezaId = undefined; };
  const limpiarDesdeLado = () => { borrador.motor = borrador.piezaId = undefined; };
  const limpiarDesdeMotor = () => { borrador.piezaId = undefined; };

  // Código de barras: autocompleta toda la cascada de la refacción
  bindCodigoBarras("selRefCodigo", panel,
    () => REFACCIONES,
    (m) => {
      borrador.marcaVehiculo = m.marca; borrador.modelo = m.modelo; borrador.anio = m.anio;
      borrador.traccion = m.traccion; borrador.lado = m.lado; borrador.motor = m.motor; borrador.piezaId = m.id;
    },
    onChange);
  // Cada cajón guarda su valor, limpia lo que depende de él, recalcula y redibuja
  $("#selRefMarca", panel)?.addEventListener("change", (e) => {
    borrador.marcaVehiculo = e.target.value || undefined; limpiarDesdeMarca();
    recalcularCascadaRefaccion(); onChange();
  });
  $("#selRefModelo", panel)?.addEventListener("change", (e) => {
    borrador.modelo = e.target.value || undefined; limpiarDesdeModelo();
    recalcularCascadaRefaccion(); onChange();
  });
  $("#selRefAnio", panel)?.addEventListener("change", (e) => {
    borrador.anio = e.target.value || undefined; limpiarDesdeAnio();
    recalcularCascadaRefaccion(); onChange();
  });
  $("#selRefTraccion", panel)?.addEventListener("change", (e) => {
    borrador.traccion = e.target.value || undefined; limpiarDesdeTraccion();
    recalcularCascadaRefaccion(); onChange();
  });
  $("#selRefLado", panel)?.addEventListener("change", (e) => {
    borrador.lado = e.target.value || undefined; limpiarDesdeLado();
    recalcularCascadaRefaccion(); onChange();
  });
  $("#selRefMotor", panel)?.addEventListener("change", (e) => {
    borrador.motor = e.target.value || undefined; limpiarDesdeMotor();
    recalcularCascadaRefaccion(); onChange();
  });
  $("#selRefPieza", panel)?.addEventListener("change", (e) => {
    borrador.piezaId = e.target.value || undefined;
    onChange();
  });
}

// Campos para la venta de una refacción: cliente + la cascada completa de arriba
function camposRefaccionHTML(){
  const b = borrador;
  return `
    <div class="form-grid">
      <div class="form-field span-2"><label>Cliente</label><input type="text" id="inpClienteP" value="${escapeHTML(b.cliente || "")}" placeholder="Nombre completo"></div>
      <div class="form-field"><label>RFC / INE</label><input type="text" id="inpRfcIneP" value="${escapeHTML(b.rfcIne || "")}" placeholder="Identificación"></div>
      <div class="form-field"><label>Email</label><input type="email" id="inpEmailP" value="${escapeHTML(b.email || "")}" placeholder="correo@ejemplo.com"></div>
      <div class="form-field"><label>Celular</label><input type="tel" id="inpCelularP" value="${escapeHTML(b.celular || "")}" placeholder="10 dígitos"></div>

      ${selectoresRefaccionHTML(b)}
    </div>
  `;
}

// Simulación del crédito con lo capturado: precio del inventario, enganche (por % o monto, redondeado a centavos), plazo y tasa

function simulacionCredito(b) {
  const tasa = b.tasaAnual ?? TASA_INTERES_ANUAL_DEFAULT;
  const plazo = Number(b.plazoMeses) || null;
  const engancheTipo = b.engancheTipo || "monto";
  const itemInventario = articuloDeBorrador(b);
  const precio = Number(itemInventario?.precio || 0);

  // El seguro es opcional y equivale al 3 % del precio del vehículo.
  const contratarSeguro = b.contratarSeguro === true;
  const seguro = contratarSeguro
    ? Math.round(precio * 0.03 * 100) / 100
    : 0;

  // El enganche se calcula únicamente sobre el vehículo.
  const engancheBruto = engancheTipo === "pct"
    ? precio * (Number(b.engancheValor || 0) / 100)
    : Number(b.engancheValor || 0);

  const engancheMonto = Math.round(engancheBruto * 100) / 100;

  // Se financia el vehículo más el seguro, menos el enganche del vehículo.
  const calculo = (precio > 0 && plazo)
    ? calcularCredito({
        precio: precio + seguro,
        engancheMonto,
        plazoMeses: plazo,
        tasaAnualPct: Number(tasa)
      })
    : null;

  return {
    tasa,
    plazo,
    engancheTipo,
    itemInventario,
    precio,
    engancheMonto,
    contratarSeguro,
    seguro,
    calculo
  };
}


// Cuadros con el resultado de la simulación (se reemplazan solos al escribir, sin redibujar el formulario)

function resultadoCreditoHTML(calculo, simulacion = null) {
  const seguro = simulacion?.seguro || 0;
  const contratarSeguro = simulacion?.contratarSeguro === true;

  return `
      ${contratarSeguro ? `
        <div class="credito-info-box">
          <span>Seguro de cobertura amplia (3%)</span>
          <strong>${formatoMoneda(seguro)}</strong>
        </div>
      ` : ""}

      <div class="credito-info-box">
        <span>Saldo base a financiar</span>
        <strong>${calculo ? formatoMoneda(calculo.baseFinanciar) : "—"}</strong>
      </div>

      <div class="credito-info-box">
        <span>Comisión por apertura (2%)</span>
        <strong>${calculo ? formatoMoneda(calculo.comisionApertura) : "—"}</strong>
      </div>

      <div class="credito-info-box">
        <span>Monto de interés</span>
        <strong>${calculo ? formatoMoneda(calculo.montoInteres) : "—"}</strong>
      </div>

      <div class="credito-info-box">
        <span>Monto final (con interés)</span>
        <strong>${calculo ? formatoMoneda(calculo.montoFinal) : "—"}</strong>
      </div>

      <div class="credito-info-box">
        <span>Mensualidad estimada</span>
        <strong>${calculo ? formatoMoneda(calculo.mensualidad) : "—"}</strong>
      </div>`;
}


// Texto bajo el enganche: su equivalente en dinero (si se captura por %) o en porcentaje (si se captura por monto)
function equivalenciaEngancheTexto(sim){
  if (!sim.precio) return "Elige el vehículo para calcular el enganche.";
  if (sim.engancheMonto <= 0) return "Sin enganche: se cobrarán $0 y se financia el precio completo.";
  const pct = sim.engancheMonto / sim.precio * 100;
  return sim.engancheTipo === "pct"
    ? `Equivale a ${formatoMoneda(sim.engancheMonto)} — es lo que se cobrará en caja.`
    : `Equivale al ${pct.toLocaleString("es-MX", { maximumFractionDigits: 2 })}% del precio — es lo que se cobrará en caja.`;
}

// Campos del módulo de Crédito (solo vehículos): enganche, plazo, tasa y simulación de intereses

function camposCreditoHTML() {
  const b = borrador;
  const sim = simulacionCredito(b);
  const { tasa, plazo, engancheTipo, calculo } = sim;

  return `
    <div class="form-grid">
      <div class="form-field">
        <label>Cliente</label>
        <input type="text" id="inpClienteC"
          value="${escapeHTML(b.cliente || "")}"
          placeholder="Nombre completo">
      </div>

      <div class="form-field">
        <label>RFC / CURP</label>
        <input type="text" id="inpRfcIneC"
          value="${escapeHTML(b.rfcIne || "")}"
          placeholder="RFC (13) o CURP (18)"
          autocapitalize="characters">
      </div>

      <div class="form-field">
        <label>Email</label>
        <input type="email" id="inpEmailC"
          value="${escapeHTML(b.email || "")}"
          placeholder="correo@ejemplo.com">
      </div>

      <div class="form-field">
        <label>Celular</label>
        <input type="tel" id="inpCelularC"
          value="${escapeHTML(b.celular || "")}"
          placeholder="10 dígitos">
      </div>

      <div class="form-field span-2">
        <p class="form-field-info" style="margin:0;">
          El crédito solo aplica para vehículos — las refacciones se venden
          de contado. Para el contrato se necesitan RFC o CURP, domicilio,
          identificación oficial y su número.
        </p>
      </div>

      ${selectoresArticuloHTML("Credito", b)}

      ${camposExtraVehiculoHTML("C", b, true)}

      <!-- Enganche: por porcentaje o por monto en dinero -->
      <div class="form-field">
        <label>Enganche</label>

        <div class="segmented">
          <button type="button"
            class="segmented-btn ${engancheTipo === "pct" ? "is-active" : ""}"
            data-eng-tipo="pct">
            Porcentaje
          </button>

          <button type="button"
            class="segmented-btn ${engancheTipo === "monto" ? "is-active" : ""}"
            data-eng-tipo="monto">
            Monto: $
          </button>
        </div>

        <input type="number"
          id="inpEngancheValor"
          style="margin-top:8px;"
          min="0"
          step="any"
          value="${escapeHTML(b.engancheValor ?? "")}"
          placeholder="${engancheTipo === "pct" ? "Ej. 20" : "$ 0.00"}">

        <div class="form-field-info" id="engancheEquivalente">
          ${escapeHTML(equivalenciaEngancheTexto(sim))}
        </div>
      </div>

      <!-- Plazo del crédito en meses -->
      <div class="form-field">
        <label>Plazo</label>

        <div class="plazo-group" id="plazoGroup">
          ${PLAZOS_CREDITO.map(m => `
            <button type="button"
              class="plazo-btn ${plazo === m ? "is-active" : ""}"
              data-plazo="${m}">
              ${m} meses
            </button>
          `).join("")}
        </div>
      </div>

      <div class="form-field">
        <label>Tasa de interés anual (%)</label>
        <input type="number"
          id="inpTasaAnual"
          value="${escapeHTML(tasa)}"
          step="0.1">
      </div>
    </div>

    <!-- Seguro automotriz opcional -->
    <div class="form-field" style="margin-top:16px;">
      <label>
        <input
          type="checkbox"
          id="chkSeguroCoberturaAmplia"
          ${b.contratarSeguro === true ? "checked" : ""}
        >
        Contratar seguro automotriz de cobertura amplia (3 %)
      </label>

      <div class="form-field-info">
        El costo corresponde al 3 % del precio del vehículo.
        Si eliges contratarlo, se incluirá en el monto financiado.
      </div>
    </div>

    <!-- Resultado de la simulación -->
    <div class="credito-info-grid" id="creditoResultado">
      ${resultadoCreditoHTML(calculo, sim)}
    </div>

    <div class="venta-actions" style="margin-top:16px;">
      <button type="button"
        class="btn btn-outline"
        id="btnTablaAmortizacion"
        ${calculo ? "" : "disabled"}>
        ${mostrarTablaAmortizacion
          ? "Ocultar"
          : "Generar"} tabla de amortización
      </button>
    </div>

    <div id="tablaAmortizacionWrap">
      ${mostrarTablaAmortizacion && calculo
        ? tablaAmortizacionHTML(calculo)
        : ""}
    </div>
  `;
}


// Al escribir el enganche o la tasa solo se actualizan los resultados: el campo conserva el foco y la página no se mueve

function actualizarSimulacionCredito(panel) {
  const sim = simulacionCredito(borrador);

  // Actualizar los importes, incluido el seguro si está seleccionado.
  const resultado = $("#creditoResultado", panel);

  if (resultado) {
    resultado.innerHTML = resultadoCreditoHTML(
      sim.calculo,
      sim
    );
  }

  // Actualizar el equivalente del enganche.
  const equivalente = $("#engancheEquivalente", panel);

  if (equivalente) {
    equivalente.textContent = equivalenciaEngancheTexto(sim);
  }

  // Habilitar o deshabilitar la tabla de amortización.
  const btnTabla = $("#btnTablaAmortizacion", panel);

  if (btnTabla) {
    btnTabla.disabled = !sim.calculo;
  }

  // Actualizar la tabla si está visible.
  const tabla = $("#tablaAmortizacionWrap", panel);

  if (tabla) {
    tabla.innerHTML =
      mostrarTablaAmortizacion && sim.calculo
        ? tablaAmortizacionHTML(sim.calculo)
        : "";
  }
}


// Fórmula de anualidades vencidas (tasa fija): calcula comisión, mensualidad, interés total y monto final
function calcularCredito({ precio, engancheMonto, plazoMeses, tasaAnualPct }){
  const baseFinanciar = Math.max(precio - (engancheMonto || 0), 0);
  const comisionApertura = baseFinanciar * COMISION_APERTURA_PCT;
  const montoFinanciado = baseFinanciar + comisionApertura;   // "P" de la fórmula
  const i = (Number(tasaAnualPct) || 0) / 100 / 12;             // tasa mensual
  const n = plazoMeses;
  const mensualidad = i > 0
    ? montoFinanciado * (i * Math.pow(1 + i, n)) / (Math.pow(1 + i, n) - 1)
    : montoFinanciado / n;
  const montoFinal = mensualidad * n;
  const montoInteres = montoFinal - montoFinanciado;
  return { baseFinanciar, comisionApertura, montoFinanciado, i, n, mensualidad, montoFinal, montoInteres };
}

// Tabla de amortización mes a mes: cuota | abono a capital | interés | saldo pendiente
function tablaAmortizacionHTML(calculo){
  let saldo = calculo.montoFinanciado;
  const filas = [];
  for (let mes = 1; mes <= calculo.n; mes++){
    const interes = saldo * calculo.i;
    const capital = calculo.mensualidad - interes;
    saldo = Math.max(saldo - capital, 0);
    filas.push({ mes, capital, interes, saldo });
  }
  return `
    <div class="table-wrap" style="margin-top:16px;">
      <table class="data-table">
        <thead><tr><th>Pago</th><th>Cuota mensual</th><th>Abono a capital</th><th>Pago de interés</th><th>Saldo pendiente</th></tr></thead>
        <tbody>
          ${filas.map(f => `
            <tr>
              <td>${f.mes}</td><td>${formatoMoneda(calculo.mensualidad)}</td>
              <td>${formatoMoneda(f.capital)}</td><td>${formatoMoneda(f.interes)}</td><td>${formatoMoneda(f.saldo)}</td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>`;
}

// Conecta todos los eventos del formulario recién dibujado
function bindFormularioVenta(){
  const panel = $("#panelVenta");

  // Toggle Vehículo / Crédito / Refacción
  $$("[data-form-tipo]", panel).forEach(btn => btn.addEventListener("click", () => {
    formTipoArticulo = btn.dataset.formTipo;
    borrador = {};
    creditoTipoProducto = "Vehiculo";
    mostrarTablaAmortizacion = false;
    renderPanelVenta();
  }));

  // Botones de acción: cambian según si estamos cotizando o registrando de verdad
  if (modoCotizacion){
    $("#btnCalcularCotizacion", panel)?.addEventListener("click", calcularCotizacion);
    $("#btnSalirCotizacion", panel)?.addEventListener("click", () => {
      modoCotizacion = false;
      renderPanelVenta();
      renderShortcutsBar();
    });
  } else {
    $("#btnGuardarArticulo", panel)?.addEventListener("click", guardarArticulo);
    $("#btnCancelarArticulo", panel)?.addEventListener("click", limpiarFormulario);
  }

  // Vehículo (contado): textos del cliente sin redibujar + cascada + cajita de VIN
  if (formTipoArticulo === "Vehiculo"){
    bindTexto("inpCliente", "cliente", panel);
    bindTexto("inpRfcIne", "rfcIne", panel);
    bindTexto("inpEmail", "email", panel);
    bindTexto("inpCelular", "celular", panel);
    bindTexto("inpDireccion", "direccion", panel);
    $("#selIdentificacion", panel)?.addEventListener("change", (e) => { borrador.identificacionTipo = e.target.value; });
    bindSelectoresArticulo("Vehiculo", panel, renderPanelVenta);
    bindSelectVin("selVin", panel, renderPanelVenta);
  }

  // Refacción: textos del cliente + cascada completa de la pieza
  if (formTipoArticulo === "Refaccion"){
    bindTexto("inpClienteP", "cliente", panel);
    bindTexto("inpRfcIneP", "rfcIne", panel);
    bindTexto("inpEmailP", "email", panel);
    bindTexto("inpCelularP", "celular", panel);
    bindSelectoresRefaccion(panel, renderPanelVenta);
  }

  // Crédito (solo vehículos): mismos cajones + VIN, y cada cambio recalcula comisión, interés y mensualidad
  if (formTipoArticulo === "Credito"){
    bindTexto("inpClienteC", "cliente", panel);
    // RFC / CURP en mayúsculas y sin espacios mientras se escribe: se guarda y se imprime tal como se ve
    $("#inpRfcIneC", panel)?.addEventListener("input", (e) => {
      const limpio = e.target.value.replace(/\s+/g, "").toUpperCase();
      if (limpio !== e.target.value) e.target.value = limpio;
      borrador.rfcIne = limpio;
    });
    bindTexto("inpEmailC", "email", panel);
    bindTexto("inpCelularC", "celular", panel);
    bindTexto("inpDireccionC", "direccion", panel);
    bindTexto("inpIdNumeroC", "identificacionNumero", panel);
    $("#selIdentificacionC", panel)?.addEventListener("change", (e) => { borrador.identificacionTipo = e.target.value; });
    bindSelectoresArticulo("Credito", panel, renderPanelVenta);
    bindSelectVin("selVinC", panel, renderPanelVenta);

    // Enganche por porcentaje o monto, plazo, tasa y tabla de amortización
    $$("[data-eng-tipo]", panel).forEach(btn => btn.addEventListener("click", () => {
      borrador.engancheTipo = btn.dataset.engTipo;
      renderPanelVenta();
    }));
    // Escribir el enganche o la tasa solo recalcula los resultados (antes redibujaba todo y la página saltaba hasta arriba)
    $("#inpEngancheValor", panel)?.addEventListener("input", (e) => { borrador.engancheValor = e.target.value; actualizarSimulacionCredito(panel); });

    $$("[data-plazo]", panel).forEach(btn => btn.addEventListener("click", () => {
      borrador.plazoMeses = btn.dataset.plazo;
      renderPanelVenta();
    }));
    $("#inpTasaAnual", panel)?.addEventListener("input", (e) => { borrador.tasaAnual = e.target.value; actualizarSimulacionCredito(panel); });

     // Seguro automotriz de cobertura amplia (3 %)
    $("#chkSeguroCoberturaAmplia", panel)?.addEventListener("change", (e) => {
      borrador.contratarSeguro = e.target.checked;
      actualizarSimulacionCredito(panel);
    });

    $("#btnTablaAmortizacion", panel)?.addEventListener("click", () => {
      mostrarTablaAmortizacion = !mostrarTablaAmortizacion;
      renderPanelVenta();
    });
  }
}

// Limpia solo los campos capturados (no toca el ticket ya guardado)
function limpiarFormulario(){
  borrador = {};
  mostrarTablaAmortizacion = false;
  renderPanelVenta();
}

// Confirma en el servidor que el VIN elegido es el registrado en productos para ese vehículo
async function validarVinEnServidor(productoId, vin){
  if (!vin) throw new Error("Elige el VIN de la unidad que vas a vender.");
  const r = await apiFetch("validar_vin", { method: "POST", body: JSON.stringify({ producto_id: productoId, vin }) });
  return r.vin || vin;
}

// Mensajes de validación del vehículo
const MSG_COMPLETAR_VEHICULO = "Completa marca, modelo, año, color, color interior y motor antes de guardar el vehículo.";
const MSG_SIN_STOCK_VEHICULO = "0 unidades disponibles: este vehículo no tiene existencia en el inventario de la sucursal.";

// Lee el formulario, arma el artículo y lo agrega al ticket
async function guardarArticulo(){
  try {
    // Un abono se cobra en su propio ticket (no es una venta)
    if (ticketEsAbono()) throw new Error("El ticket tiene un abono mensual. Cóbralo (F3) o cancélalo (F6) antes de registrar una venta.");
    let cliente = "", email = "", celular = "", rfcIne = "", productoId = null, item = null;

    if (formTipoArticulo === "Refaccion"){
      cliente = $("#inpClienteP").value.trim();
      if (!cliente){ $("#inpClienteP").focus(); return; }
      email = $("#inpEmailP").value.trim();
      celular = $("#inpCelularP").value.trim();
      rfcIne = $("#inpRfcIneP").value.trim();

      item = REFACCIONES.find(r => String(r.id) === String(borrador.piezaId));
      if (!item){
        throw new Error("Elige la pieza en el último cajón antes de guardarla.");
      }
      if (item.unidades < 1){
        throw new Error("0 unidades disponibles: esta refacción no tiene existencia en el inventario de la sucursal.");
      }

      ticketIdCounter += 1;
      ticketItems.push({
        id: ticketIdCounter,
        productoId: item.id,
        esVehiculo: false,
        articulo: item.nombre,
        precioTotal: Number(item.precio || 0),
        cantidad: 1,
        cliente, email, celular, rfcIne,
        pieza: item.nombre,
        webOrderId: borrador.webOrderId || null,
        marcaVehiculo: item.marca,
        modeloCompatible: item.modelo,
        traccion: item.traccion,
        lado: item.lado,
        motor: item.motor
      });
    } else if (formTipoArticulo === "Credito"){
      // Un contrato por operación: un solo crédito por ticket
      if (ticketItems.some(it => it.esCredito)) throw new Error("Este ticket ya tiene un crédito. Concrétalo o quítalo (F4) antes de registrar otro: cada crédito lleva su propio contrato.");
      cliente = $("#inpClienteC").value.trim();
      if (!cliente){ $("#inpClienteC").focus(); return; }
      email = $("#inpEmailC").value.trim();
      celular = $("#inpCelularC").value.trim();
      rfcIne = $("#inpRfcIneC").value.trim().replace(/\s+/g, "").toUpperCase();

      item = articuloDeBorrador(borrador);
      if (!item) throw new Error(MSG_COMPLETAR_VEHICULO);
      if (item.unidades < 1) throw new Error(MSG_SIN_STOCK_VEHICULO);

      const sim = simulacionCredito(borrador);
      const precio = sim.precio;
      const plazo = sim.plazo;
      if (!precio) throw new Error(MSG_COMPLETAR_VEHICULO);
      if (!plazo) throw new Error("Elige el plazo del crédito.");
      if (Number(borrador.engancheValor || 0) < 0) throw new Error("El enganche no puede ser negativo.");
      if (sim.engancheMonto >= precio) throw new Error("El enganche debe ser menor que el precio de contado del vehículo.");

      // Datos que el contrato necesita del acreditado
      const direccion = (borrador.direccion || "").trim();
      const identificacionNumero = (borrador.identificacionNumero || "").trim();
      // Solo la estructura (letras y números en su lugar): se aceptan RFC y CURP ficticios
      if (!/^([A-ZÑ&]{3,4}\d{6}[A-ZÑ\d]{3}|[A-ZÑ]{4}\d{6}[A-ZÑ\d]{8})$/.test(rfcIne)){
        $("#inpRfcIneC").focus();
        throw new Error("El RFC debe tener 12 o 13 caracteres (3 o 4 letras, 6 números y 3 letras o números) y la CURP 18 (4 letras, 6 números y 8 letras o números).");
      }
      if (!direccion){ $("#inpDireccionC").focus(); throw new Error("El contrato necesita el domicilio particular del cliente."); }
      if (!identificacionNumero){ $("#inpIdNumeroC").focus(); throw new Error("Escribe el número o folio de la identificación oficial."); }
      if (email && !/^\S+@\S+\.\S+$/.test(email)) throw new Error("El correo electrónico del cliente no es válido.");

      // El VIN elegido en la cajita debe coincidir con el registrado para este vehículo
      const vin = await validarVinEnServidor(item.id, $("#selVinC").value.trim());

      productoId = item.id;

      const tasa = Number(sim.tasa);
      const engancheMonto = sim.engancheMonto;
      const calculo = sim.calculo;

      ticketIdCounter += 1;
      ticketItems.push({
        id: ticketIdCounter, productoId, esVehiculo: true, esCredito: true, webOrderId: borrador.webOrderId || null,
        articulo: `${item.marca} ${item.modelo} (${item.anio})`,
        marca: item.marca, modelo: item.modelo, anio: item.anio,
        colorExterior: item.color, colorInterior: item.colorInterior || "",
        vin, motorTipo: item.motor,
        direccion, identificacionTipo: borrador.identificacionTipo || "INE", identificacionNumero,
        abonos: `${plazo} meses`, plazoMeses: plazo, enganche: engancheMonto, montoAbono: calculo.mensualidad,
       
        engancheTipo: sim.engancheTipo,
        engancheValor: Number(borrador.engancheValor || 0),

        // Selección del seguro automotriz
        contratarSeguro: sim.contratarSeguro === true,

        tasaAnual: tasa,
        comisionApertura: calculo.comisionApertura,
        montoInteres: calculo.montoInteres,

        montoFinal: calculo.montoFinal, precioContado: precio, saldoFinanciar: calculo.baseFinanciar,
        // En un crédito solo se cobra el enganche: es el importe de este artículo en el ticket
        precioTotal: engancheMonto,
        cantidad: 1, cliente, email, celular, rfcIne
      });
    } else {
      cliente = $("#inpCliente").value.trim();
      if (!cliente){ $("#inpCliente").focus(); return; }
      email = $("#inpEmail").value.trim();
      celular = $("#inpCelular").value.trim();
      rfcIne = $("#inpRfcIne").value.trim();
      item = articuloDeBorrador(borrador);
      if (!item) throw new Error(MSG_COMPLETAR_VEHICULO);
      if (item.unidades < 1) throw new Error(MSG_SIN_STOCK_VEHICULO);
      const vin = await validarVinEnServidor(item.id, $("#selVin").value.trim());

      ticketIdCounter += 1;
      ticketItems.push({
        id: ticketIdCounter, productoId: item.id, esVehiculo: true, webOrderId: borrador.webOrderId || null,
        articulo: `${item.marca} ${item.modelo} (${item.anio})`,
        marca: item.marca, modelo: item.modelo, anio: item.anio,
        colorExterior: item.color, colorInterior: item.colorInterior || "",
        vin, motorTipo: item.motor,
        direccion: borrador.direccion || "", identificacionTipo: borrador.identificacionTipo || "INE",
        precioTotal: item.precio, cantidad: 1, cliente, email, celular, rfcIne
      });
    }

    borrador = {};
    mostrarTablaAmortizacion = false;
    renderPanelVenta();
    renderPanelLateral();
    renderShortcutsBar();
  } catch (error) {
    avisar(error.message);
  }
}

// F5: calcula un total de referencia sin tocar el ticket real
function calcularCotizacion(){
  let total = 0, detalle = "";
  if (formTipoArticulo === "Refaccion"){
    const item = REFACCIONES.find(r => String(r.id) === String(borrador.piezaId));
    total = item?.precio || 0;
    detalle = item ? item.nombre : "";
  } else if (formTipoArticulo === "Credito"){
    const sim = simulacionCredito(borrador);
    const item = sim.itemInventario;
    if (sim.calculo) total = sim.engancheMonto + sim.calculo.montoFinal;
    detalle = item ? `${item.marca} ${item.modelo}` : "";
  } else {
    const item = articuloDeBorrador(borrador);
    total = item?.precio || 0;
    detalle = item ? `${item.marca} ${item.modelo}` : "";
  }
  $("#cotizacionResultadoWrap").innerHTML = `
    <div class="cotizacion-result">
      <div class="label">Cotización estimada${detalle ? " — " + escapeHTML(detalle) : ""}</div>
      <div class="value">${formatoMoneda(total)}</div>
    </div>`;
}

/* ===== 5. VENTA — ticket de la venta actual (derecha, 2/5) ===== */

// Suma el precio total de todos los artículos del ticket
function calcularTotalTicket(){
  return ticketItems.reduce((suma, it) => suma + (Number(it.precioTotal) || 0), 0);
}

// Dibuja el ticket tipo recibo y su total con IVA
function renderPanelLateral(){
  const panel = $("#panelLateral");
  if (!panel) return;

  panel.innerHTML = `
    <div class="panel-heading"><h2>Ticket #${String(ticketNumero).padStart(2, "0")}</h2></div>
    <div class="ticket-list">
      ${ticketItems.length
        ? ticketItems.map(it => ticketItemHTML(it)).join("")
        : `<div class="ticket-empty">Aún no has agregado artículos a este ticket. Usa el formulario para registrar el primero.</div>`
      }
    </div>
    <div class="ticket-total">
      <span class="label">Total con IVA incluido</span>
      <span class="value">${ticketItems.some(it => it.esCredito || it.esAbono) ? formatoMonedaCentavos(calcularTotalTicket()) : formatoMoneda(calcularTotalTicket())}</span>
    </div>
    ${ticketItems.some(it => it.esCredito) ? `<p class="ticket-credito-nota">Crédito: hoy solo se cobra el enganche${calcularTotalTicket() <= 0 ? " ($0: no se pedirá método de pago)" : ""}; el saldo se paga en mensualidades según el contrato.</p>` : ""}
  `;

  if (modoEliminarTicket){
    $$("[data-quitar-item]", panel).forEach(btn => btn.addEventListener("click", () => quitarItemTicket(Number(btn.dataset.quitarItem))));
  }
}

// Dibuja un artículo con solo los datos visibles del ticket
function ticketItemHTML(it){
  if (it.esAbono){
    return `
    <div class="ticket-item">
      <div class="ticket-item-head">
        <span class="ticket-item-articulo">Abono mensual</span>
        ${modoEliminarTicket ? `<button class="ticket-item-remove" data-quitar-item="${it.id}" title="Quitar artículo">×</button>` : ""}
      </div>
      <div class="ticket-item-grid">
        <div><span>Cliente</span><strong>${escapeHTML(it.cliente)}</strong></div>
        <div><span>Mensualidad</span><strong>${it.numeroAbono} de ${it.abonosTotales}</strong></div>
        <div><span>Contrato</span><strong>${escapeHTML(it.contratoFolio || "—")}</strong></div>
      </div>
      <div class="ticket-item-grid">
        <div><span>Vehículo</span><strong>${escapeHTML(it.vehiculo || "—")}</strong></div>
        <div><span>Saldo actual</span><strong>${formatoMonedaCentavos(it.saldoAnterior)}</strong></div>
        <div><span>Saldo después</span><strong>${formatoMonedaCentavos(it.saldoRestante)}</strong></div>
      </div>
      <div class="ticket-item-total">Importe del abono <strong>${formatoMonedaCentavos(it.precioTotal)}</strong></div>
    </div>`;
  }
  const mostrarGrid = it.esVehiculo && (it.abonos || it.enganche != null || it.montoAbono != null);
  return `
    <div class="ticket-item">
      <div class="ticket-item-head">
        <span class="ticket-item-articulo">${escapeHTML(it.articulo)}</span>
        ${modoEliminarTicket ? `<button class="ticket-item-remove" data-quitar-item="${it.id}" title="Quitar artículo">×</button>` : ""}
      </div>
      ${mostrarGrid ? `
        <div class="ticket-item-grid">
          ${it.abonos ? `<div><span>Abonos</span><strong>${it.abonos}</strong></div>` : ""}
          ${it.enganche != null ? `<div><span>Enganche</span><strong>${formatoMoneda(it.enganche)}</strong></div>` : ""}
          ${it.montoAbono != null ? `<div><span>Monto de abono</span><strong>${formatoMoneda(it.montoAbono)}</strong></div>` : ""}
        </div>` : ""
      }
      ${it.esCredito ? `
        <div class="ticket-item-grid">
          <div><span>Tasa anual</span><strong>${it.tasaAnual}%</strong></div>
          <div><span>Comisión apertura</span><strong>${formatoMoneda(it.comisionApertura)}</strong></div>
          <div><span>Monto final</span><strong>${formatoMoneda(it.montoFinal)}</strong></div>
        </div>
        <div class="ticket-item-grid">
          <div><span>Precio de contado</span><strong>${formatoMoneda(it.precioContado)}</strong></div>
          <div><span>Saldo a financiar</span><strong>${formatoMoneda(it.saldoFinanciar)}</strong></div>
          <div><span>Contrato</span><strong>Al concretar</strong></div>
        </div>` : ""
      }
      ${it.esCredito
        ? `<div class="ticket-item-total">Importe a cobrar (enganche) <strong>${formatoMonedaCentavos(it.precioTotal)}</strong></div>`
        : `<div class="ticket-item-total">Precio total <strong>${formatoMoneda(it.precioTotal)}</strong></div>`}
    </div>`;
}

// Quita un artículo del ticket (usado en modo eliminar / F4)
function quitarItemTicket(id){
  ticketItems = ticketItems.filter(it => it.id !== id);
  if (!ticketItems.length) modoEliminarTicket = false;
  renderPanelLateral();
  renderShortcutsBar();
}

/* ===== 6. VENTA — accesos rápidos F3–F6 ===== */

// Dibuja (o esconde) la barra de accesos rápidos según la vista actual
function renderShortcutsBar(){
  const bar = $("#shortcutsBar");
  if (currentView !== "venta" || ventaResultadosActivos){ bar.hidden = true; return; }

  bar.hidden = false;
  const hayItems = ticketItems.length > 0;
  const pagoActivo = !!pagoEstado;
  bar.innerHTML = `
    <button class="btn btn-primary shortcut-btn ${pagoActivo ? "is-active" : ""}" id="btnF3" ${hayItems && (!pagoActivo || pagoEstado?.valido) ? "" : "disabled"}>F3 · Concretar</button>
    <button class="btn btn-primary shortcut-btn ${modoEliminarTicket ? "is-active" : ""}" id="btnF4" ${hayItems && !pagoActivo ? "" : "disabled"}>F4 · Eliminar artículo</button>
    <button class="btn btn-primary shortcut-btn ${modoCotizacion ? "is-active" : ""}" id="btnF5" ${pagoActivo ? "disabled" : ""}>F5 · Cotizar / simular</button>
    <button class="btn btn-primary shortcut-btn" id="btnF6" ${hayItems && !pagoActivo ? "" : "disabled"}>F6 · Cancelar</button>
  `;
  $("#btnF3").addEventListener("click", () => { if (pagoEstado?.valido) confirmarVentaDB(); else concretarVenta(); });
  $("#btnF4").addEventListener("click", toggleModoEliminar);
  $("#btnF5").addEventListener("click", toggleCotizacion);
  $("#btnF6").addEventListener("click", cancelarTicket);
}

// F3 — abre el cobro; el número de ticket solo avanza cuando la venta se concreta de verdad
function concretarVenta(){
  if (!ticketItems.length || pagoEstado) return;
  // Crédito con enganche de $0 (y nada más que cobrar): no hay método de pago, se pasa directo a la verificación del empleado
  if (ticketItems.some(it => it.esCredito) && calcularTotalTicket() <= 0){
    pagoEstado = { metodo: "Sin cobro", monto: 0, recibido: 0, cambio: 0, valido: true };
    renderShortcutsBar();
    confirmarVentaDB();
    return;
  }
  abrirModalPago();
}

// ¿El ticket actual es un crédito? (el cobro es solo el enganche y termina en el contrato)
function ticketEsCredito(){
  return ticketItems.some(it => it.esCredito);
}

/* ===== 7b. COBRO — selección de método, efectivo y confirmación ===== */

/* Abre la ventana de selección de método de pago */
function abrirModalPago(){
  pagoEstado = { metodo: null, monto: calcularTotalTicket(), recibido: 0, cambio: 0, valido: false };
  const esCredito = ticketEsCredito();
  const abono = ticketItems.find(it => it.esAbono);
  $("#modalPagoContent").innerHTML = `
    <div class="payment-title">${abono ? "Cobrar abono" : (esCredito ? "Cobrar enganche" : "Concretar venta")}</div>
    <p class="payment-subtitle">${abono
      ? `Abono mensual ${abono.numeroAbono} de ${abono.abonosTotales} del contrato ${escapeHTML(abono.contratoFolio || "")} (${formatoMonedaCentavos(pagoEstado.monto)}).`
      : esCredito
      ? `Crédito: solo se cobra el enganche (${formatoMonedaCentavos(pagoEstado.monto)}). Después se verifica tu código de empleado y se genera el contrato para firma del cliente.`
      : `Selecciona el método de pago para el ticket #${String(ticketNumero).padStart(2, "0")}.`}</p>
    <div class="payment-method-grid">
      <button class="payment-method-card" id="btnPagoEfectivo" type="button">
        <span class="payment-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="2.5" y="5" width="19" height="14" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M5 9h.01M19 15h.01"/></svg></span><strong>Efectivo</strong><span>Recibir dinero y calcular cambio</span>
      </button>
      <button class="payment-method-card is-disabled" id="btnPagoTarjeta" type="button">
        <span class="payment-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M2.5 9h19M6 14h4"/></svg></span><strong>Tarjeta</strong><span>Terminal no disponible todavía</span>
      </button>
    </div>
    <button class="btn btn-ghost" id="btnCancelarPago" type="button">Cancelar</button>
  `;
  abrirModal("#modalPago");
  $("#btnPagoEfectivo").addEventListener("click", abrirCobroEfectivo);
  $("#btnPagoTarjeta").addEventListener("click", () => avisar("La terminal de tarjeta todavía no está conectada."));
  $("#btnCancelarPago").addEventListener("click", cerrarPago);
}

/* Muestra el formulario vertical para recibir efectivo */
function abrirCobroEfectivo(){
  pagoEstado.metodo = "Efectivo";
  pagoEstado.valido = false;
  const esCredito = ticketEsCredito();
  const esAbono = ticketEsAbono();
  $("#modalPagoContent").innerHTML = `
    <div class="payment-title">Pago en efectivo</div>
    <div class="payment-total-box"><span>${esAbono ? "Abono a cobrar" : (esCredito ? "Enganche a cobrar" : "Total a pagar")}</span><strong>${esCredito || esAbono ? formatoMonedaCentavos(pagoEstado.monto) : formatoMoneda(pagoEstado.monto)}</strong></div>
    <div class="cash-form">
      <label for="inpEfectivo">Dinero recibido</label>
      <input type="number" id="inpEfectivo" min="0" step="0.01" placeholder="0.00" autofocus>
      <div id="cashMessage" class="cash-message"></div>
      <div class="cash-change"><span>Cambio</span><strong id="cashChange">${formatoMoneda(0)}</strong></div>
    </div>
    <div class="payment-actions">
      <button class="btn btn-ghost" id="btnVolverMetodo" type="button">Volver</button>
      <button class="btn btn-primary" id="btnConfirmarEfectivo" type="button" disabled>${esAbono ? "F3 · Cobrar abono" : (esCredito ? "F3 · Continuar al contrato" : "F3 · Concretar venta")}</button>
    </div>
  `;
  renderShortcutsBar();
  const input = $("#inpEfectivo");
  input.addEventListener("input", actualizarEfectivo);
  $("#btnVolverMetodo").addEventListener("click", abrirModalPago);
  $("#btnConfirmarEfectivo").addEventListener("click", confirmarVentaDB);
  input.focus();
}

/* Valida el efectivo y calcula el cambio en tiempo real */
function actualizarEfectivo(){
  const recibido = Number($("#inpEfectivo").value || 0);
  const diferencia = recibido - pagoEstado.monto;
  pagoEstado.recibido = recibido;
  pagoEstado.cambio = Math.max(diferencia, 0);
  pagoEstado.valido = recibido >= pagoEstado.monto;
  const msg = $("#cashMessage");
  // En crédito el enganche se muestra con centavos: es el importe exacto que exige el cobro
  const fmt = ticketEsCredito() || ticketEsAbono() ? formatoMonedaCentavos : formatoMoneda;
  if (recibido <= 0) msg.textContent = "";
  else if (!pagoEstado.valido) msg.textContent = `Faltan ${fmt(Math.abs(diferencia))}.`;
  else msg.textContent = "Dinero correcto. Puedes presionar F3 para concretar.";
  msg.classList.toggle("is-error", recibido > 0 && !pagoEstado.valido);
  msg.classList.toggle("is-ok", pagoEstado.valido);
  $("#cashChange").textContent = fmt(pagoEstado.cambio);
  $("#btnConfirmarEfectivo").disabled = !pagoEstado.valido;
  renderShortcutsBar();
}

/* Envía la venta completa al servidor dentro de una transacción MySQL */
async function confirmarVentaDB(){
  if (!pagoEstado?.valido) return;
  const boton = $("#btnConfirmarEfectivo");
  if (boton) boton.disabled = true;

  const primerVehiculo = ticketItems.find(it => it.esVehiculo) || {};
  const itemCredito = ticketItems.find(it => it.esCredito) || null;

  // Abono mensual: se registra como pago del crédito (no genera venta ni toca el formulario de venta)
  const itemAbono = ticketItems.find(it => it.esAbono) || null;
  if (itemAbono){
    await cobrarAbonoDB(itemAbono, boton);
    return;
  }

  // Crédito: verificación del empleado → contrato → firma del cliente (contrato_credito.js). No se registra hasta firmar
  if (itemCredito){
    await iniciarContratoCredito(itemCredito, boton);
    return;
  }

  // Autorización de empleado (gafete QR o código): sin ella el servidor rechaza la venta o el crédito
  const autorizacion = await solicitarAutorizacionEmpleado(itemCredito ? "CREDITO" : "VENTA", ticketNumero);
  if (!autorizacion){ if (boton) boton.disabled = false; return; }

  try {
    const data = await apiFetch("crear_venta", {
      method: "POST",
      autorizacion,
      body: JSON.stringify({
        id_usuario: USUARIO_ACTUAL_ID,
        id_sucursal: SUCURSAL_ACTUAL_ID,
        id_caja: CAJA_ACTUAL_ID,
        metodo_pago: "Efectivo",
        efectivo_recibido: pagoEstado.recibido,
        cambio: pagoEstado.cambio,
        ticket_numero: ticketNumero,
        // Órdenes web atendidas con esta venta (llegaron con "Continuar" desde Web orders)
        ordenes_web: ticketItems.map(it => it.webOrderId).filter(Boolean),
        items: ticketItems.map(it => ({
          producto_id: it.productoId,
          cantidad: it.cantidad || 1,
          precio_unitario: Number(it.precioTotal || 0),
          es_credito: !!it.esCredito,
          articulo: it.articulo,
          vin: it.vin || "",
          motor_serie: it.motorTipo || "",
          color_interior: it.colorInterior || ""
        })),
        cliente: ticketItems[0]?.cliente || "",
        email: ticketItems[0]?.email || "",
        celular: ticketItems[0]?.celular || "",
        rfc_ine: ticketItems[0]?.rfcIne || "",
        direccion: primerVehiculo.direccion || "",
        identificacion_tipo: primerVehiculo.identificacionTipo || "",
        // Solo las ventas a crédito mandan estos datos: únicamente esos clientes se guardan en `clientes`
        credito: itemCredito ? {
          articulo: itemCredito.articulo,
          enganche: Number(itemCredito.enganche || 0),
          monto_abono: Number(itemCredito.montoAbono || 0),
          total_adeudo: Number(itemCredito.montoFinal || 0),
          abonos_totales: parseInt(itemCredito.abonos, 10) || 0
        } : null
      })
    });

    ticketCerrado = {
      numero: ticketNumero,
      ventaId: data.venta_id,
      folio: data.folio || `KRM-${String(SUCURSAL_ACTUAL_ID || 0).padStart(2, "0")}-${String(data.venta_id || 0).padStart(6, "0")}`,
      fecha: data.fecha,
      cajero: CAJERO_ACTUAL,
      sucursal: SUCURSAL_ACTUAL,
      sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION,
      sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
      caja: CAJA_ACTUAL,
      metodo: "Efectivo",
      subtotal: calcularTotalTicket(),
      total: calcularTotalTicket(),
      recibido: pagoEstado.recibido,
      cambio: pagoEstado.cambio,
      items: [...ticketItems]
    };

    cerrarPago();
    ticketItems = [];
    modoEliminarTicket = false;
    ticketNumero += 1;
    await refrescarDatosDB();
    renderPanelLateral();
    renderShortcutsBar();
    mostrarTicketCliente();
  } catch (error) {
    if (boton) boton.disabled = false;
    avisar(error.message);
  }
}

/* Cobra el abono mensual: gafete del empleado → cobrar_abono (registra el pago y actualiza el crédito) → ticket */
async function cobrarAbonoDB(item, boton){
  const autorizacion = await solicitarAutorizacionEmpleado("ABONO", ticketNumero, "Cobrar abono");
  if (!autorizacion){ if (boton) boton.disabled = false; return; }
  try {
    const data = await apiFetch("cobrar_abono", {
      method: "POST",
      autorizacion,
      body: JSON.stringify({
        id_contrato: item.contratoId, numero_abono: item.numeroAbono, clave: item.clave,
        id_caja: CAJA_ACTUAL_ID, ticket_numero: ticketNumero, metodo_pago: "Efectivo",
        efectivo_recibido: pagoEstado.recibido, cambio: pagoEstado.cambio
      })
    });
    ticketCerrado = {
      numero: ticketNumero, ventaId: null, folio: data.folio, fecha: data.fecha,
      cajero: CAJERO_ACTUAL, sucursal: SUCURSAL_ACTUAL, sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION, sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
      caja: CAJA_ACTUAL, metodo: data.metodo, subtotal: data.importe, total: data.importe, recibido: data.recibido, cambio: data.cambio,
      items: [{ ...item, precioTotal: data.importe, numeroAbono: data.numero, saldoAnterior: data.saldo_anterior, saldoRestante: data.saldo_restante }],
      abono: {
        contratoFolio: data.contrato, numero: data.numero, plazo: data.plazo, importe: data.importe, vence: item.vence,
        saldoAnterior: data.saldo_anterior, saldoRestante: data.saldo_restante, liquidado: data.liquidado,
        vehiculo: item.vehiculo, vin: item.vin, rfcIne: item.rfcIne, direccion: item.direccion,
        identificacionTipo: item.identificacionTipo, celular: item.celular
      }
    };
    cerrarPago();
    ticketItems = [];
    modoEliminarTicket = false;
    ticketNumero += 1;
    try { await refrescarDatosDB(); } catch (_) { /* el abono ya quedó registrado */ }
    renderPanelLateral();
    renderShortcutsBar();
    mostrarTicketCliente();
  } catch (error) {
    if (boton) boton.disabled = false;
    avisar(error.message);
  }
}

/* Cierra la ventana temporal de pago */
function cerrarPago(){
  pagoEstado = null;
  cerrarModales();
  renderShortcutsBar();
}

/* Muestra el ticket blanco después de confirmar la venta */
function mostrarTicketCliente(){
  const t = ticketCerrado;
  if (!t) return;
  $("#ticketClienteContent").innerHTML = `
    <div class="digital-ticket">
      <div class="digital-ticket-head"><strong>KARMA</strong><span>${t.abono ? "Abono" : "Venta"} #${String(t.numero).padStart(2,"0")}</span></div>
      <div class="digital-ticket-meta">${escapeHTML(t.sucursal)} · Caja ${escapeHTML(CAJA_ACTUAL)}<br>${escapeHTML(t.fecha)}</div>
      <div class="digital-ticket-lines">
        ${t.items.map(it => it.esAbono
          ? `<div class="digital-ticket-line"><span>Abono mensual<br><small>${escapeHTML(it.cliente)} · ${escapeHTML(it.vehiculo || "")} · pago ${it.numeroAbono} de ${it.abonosTotales}</small></span><strong>${formatoMonedaCentavos(it.precioTotal)}</strong></div>`
          : it.esCredito
          ? `<div class="digital-ticket-line"><span>${escapeHTML(it.articulo)}<br><small>Crédito ${escapeHTML(it.abonos || "")} · enganche (precio de contado ${formatoMonedaCentavos(it.precioContado)})</small></span><strong>${formatoMonedaCentavos(it.precioTotal)}</strong></div>`
          : `<div class="digital-ticket-line"><span>${escapeHTML(it.articulo)}</span><strong>${formatoMoneda(it.precioTotal)}</strong></div>`).join("")}
      </div>
      <div class="digital-ticket-total"><span>${t.contrato || t.abono ? "Total cobrado" : "Total"}</span><strong>${t.contrato || t.abono ? formatoMonedaCentavos(t.total) : formatoMoneda(t.total)}</strong></div>
      <div class="digital-ticket-paid"><span>Recibido</span><span>${formatoMoneda(t.recibido)}</span><span>Cambio</span><span>${formatoMoneda(t.cambio)}</span></div>
      ${t.abono ? `<div class="digital-ticket-contrato">Folio ${escapeHTML(t.folio)} · contrato <strong>${escapeHTML(t.abono.contratoFolio)}</strong><br>${t.abono.liquidado ? "<strong>Crédito liquidado.</strong> ¡Gracias por completar tus pagos!" : `Saldo pendiente: <strong>${formatoMonedaCentavos(t.abono.saldoRestante)}</strong> · ${t.abono.plazo - t.abono.numero} mensualidad${t.abono.plazo - t.abono.numero === 1 ? "" : "es"} por pagar`}</div>` : ""}
      ${t.contrato ? `<div class="digital-ticket-contrato">${t.metodo !== "Efectivo" ? `${escapeHTML(t.metodo)}<br>` : ""}Contrato de crédito <strong>${escapeHTML(t.contrato.folio)}</strong> firmado · ${escapeHTML(t.contrato.resumen || "")}</div>` : ""}
      <div class="digital-ticket-thanks">Gracias por tu compra.</div>
    </div>
    <div class="ticket-client-actions">
      <button class="btn btn-primary" id="btnAceptarTicket" type="button">Aceptar</button>
      ${t.contrato ? `<button class="btn btn-outline" id="btnVerContratoTicket" type="button">Ver contrato</button>` : ""}
      <button class="btn btn-ghost" id="btnEnviarTicket" type="button">Enviar</button>
    </div>
  `;
  abrirModal("#modalTicketCliente");
  $("#btnAceptarTicket").addEventListener("click", cerrarTicketCliente);
  $("#btnEnviarTicket").addEventListener("click", abrirFormularioEnvioTicket);
  $("#btnVerContratoTicket")?.addEventListener("click", () => abrirVisorContrato(t.contrato.id, t.contrato.folio));
}

/* Cierra el ticket mostrado al cliente y deja el POS listo */
function cerrarTicketCliente(){
  cerrarModales();
  ticketCerrado = null;
  renderPanelVenta();
  renderPanelLateral();
  renderShortcutsBar();
}

/* Abre el formulario de nombre, celular y correo para el envío */
function abrirFormularioEnvioTicket(){
  $("#ticketClienteContent").innerHTML = `
    <div class="payment-title">${ticketCerrado?.contrato ? "Enviar ticket y contrato" : "Enviar ticket"}</div>
    <p class="payment-subtitle">${ticketCerrado?.contrato
      ? "Ingresa los datos del cliente: se le enviarán el ticket y el contrato de crédito firmado, ambos en PDF, a su correo."
      : "Ingresa los datos del cliente: se le enviará el ticket completo en PDF a su correo."}</p>
    <div class="form-grid">
      <div class="form-field span-2"><label>Nombre completo</label><input id="envioNombre" type="text" value="${escapeHTML(ticketCerrado?.items?.[0]?.cliente || "")}"></div>
      <div class="form-field"><label>Celular</label><input id="envioCelular" type="tel" value="${escapeHTML(ticketCerrado?.items?.[0]?.celular || "")}"></div>
      <div class="form-field"><label>Email</label><input id="envioEmail" type="email" value="${escapeHTML(ticketCerrado?.items?.[0]?.email || "")}"></div>
    </div>
    <div id="envioMensaje" class="cash-message"></div>
    <div class="payment-actions">
      <button class="btn btn-ghost" id="btnVolverTicket" type="button">Volver</button>
      <button class="btn btn-primary" id="btnEnviarEmail" type="button">Enviar PDF</button>
    </div>
  `;
  $("#btnVolverTicket").addEventListener("click", mostrarTicketCliente);
  $("#btnEnviarEmail").addEventListener("click", enviarTicketPorCorreo);
}

/* API BREVO: pide a api.php (acción enviar_ticket) que genere el PDF y lo mande al correo escrito */
async function enviarTicketPorCorreo(){
  const nombre = $("#envioNombre").value.trim();
  const celular = $("#envioCelular").value.trim();
  const email = $("#envioEmail").value.trim();
  const mensaje = $("#envioMensaje");
  // Nombre y correo válido son obligatorios; el celular es opcional
  if (!nombre || !/^\S+@\S+\.\S+$/.test(email)){
    mensaje.textContent = "Escribe el nombre y un correo electrónico válido.";
    mensaje.classList.add("is-error");
    return;
  }
  const btn = $("#btnEnviarEmail");
  btn.disabled = true;
  btn.textContent = "Enviando…";
  mensaje.textContent = "";
  try {
    const data = await apiFetch("enviar_ticket", {
      method: "POST",
      // En un crédito también se adjunta el contrato firmado (el servidor lo toma de la BD, ligado a esta venta)
      body: JSON.stringify({ nombre, celular, email, ticket: ticketCerrado, id_contrato: ticketCerrado?.contrato?.id || null })
    });
    avisar(data.message || "Ticket enviado.");
    cerrarTicketCliente();
  } catch (error) {
    btn.disabled = false;
    btn.textContent = "Enviar PDF";
    mensaje.textContent = error.message;
    mensaje.classList.add("is-error");
  }
}


// F4 — activa/desactiva las "×" para quitar artículos del ticket
function toggleModoEliminar(){
  if (!ticketItems.length){ modoEliminarTicket = false; return; }
  modoEliminarTicket = !modoEliminarTicket;
  renderPanelLateral();
  renderShortcutsBar();
}

// F5 — entra/sale del modo cotización dentro del formulario
function toggleCotizacion(){
  modoCotizacion = !modoCotizacion;
  renderPanelVenta();
  renderShortcutsBar();
}

// F6 — vacía el ticket sin concretar ninguna venta: NO avanza el número de ticket
function cancelarTicket(){
  if (!ticketItems.length) return;
  ticketItems = [];
  modoEliminarTicket = false;
  renderPanelLateral();
  renderShortcutsBar();
}

/* ===== 7. VENTA — búsqueda de artículos (autocompletado → resultados) ===== */

// Muestra sugerencias mientras el cajero escribe en el buscador
function renderVentaSugerencias(q){
  const box = $("#searchSuggestions");
  if (!q){ box.classList.remove("is-open"); box.innerHTML = ""; return; }

  const coincidencias = INVENTARIO.filter(c =>
    `${c.marca} ${c.modelo} ${c.codigo}`.toLowerCase().includes(q.toLowerCase())
  ).slice(0, 6);

  box.innerHTML = coincidencias.length
    ? coincidencias.map(c => `
        <div class="search-suggestion-item" data-sugerencia="${c.id}">
          ${escapeHTML(`${c.marca} ${c.modelo}`)}
        </div>`).join("")
    : `<div class="search-suggestion-empty">Sin resultados para “${escapeHTML(q)}”</div>`;

  box.classList.add("is-open");
  $$("[data-sugerencia]", box).forEach(el => el.addEventListener("click", () => {
    const car = INVENTARIO.find(c => c.id === Number(el.dataset.sugerencia));
    entrarResultadosBusqueda(`${car.marca} ${car.modelo}`);
  }));
}

// Cierra el dropdown de sugerencias sin perder lo escrito
function cerrarSugerencias(){
  const box = $("#searchSuggestions");
  if (box){ box.classList.remove("is-open"); box.innerHTML = ""; }
}

// Cambia a la vista de resultados (cuadrícula) para no tapar el ticket
function entrarResultadosBusqueda(query){
  ventaResultadosActivos = true;
  ventaResultadosQuery = query;
  cerrarSugerencias();
  $("#searchInput").value = query;
  renderMain();
}

// Regresa del modo resultados al formulario + ticket normal
function salirResultadosBusqueda(){
  ventaResultadosActivos = false;
  ventaResultadosQuery = "";
  searchQuery = "";
  $("#searchInput").value = "";
  renderMain();
}

// Dibuja la cuadrícula de artículos que coinciden con la búsqueda
function renderResultadosBusqueda(){
  const panel = $("#panelFull");
  const q = (ventaResultadosQuery || searchQuery || "").toLowerCase();
  const lista = INVENTARIO.filter(c => !q || `${c.marca} ${c.modelo} ${c.color} ${c.codigo}`.toLowerCase().includes(q));

  panel.innerHTML = `
    <div class="section-toolbar">
      <button class="btn btn-ghost" id="btnVolverTicket">← Volver al ticket</button>
    </div>
    <div class="popular-heading">
      <h3>Resultados${ventaResultadosQuery ? ` para “${escapeHTML(ventaResultadosQuery)}”` : ""}</h3>
      <span>${lista.length} resultado${lista.length === 1 ? "" : "s"}</span>
    </div>
    <div class="popular-grid">
      ${lista.map(car => cardHTML(car)).join("") || `<p class="venta-field-sub">Sin coincidencias para esta búsqueda.</p>`}
    </div>
  `;

  $("#btnVolverTicket").addEventListener("click", salirResultadosBusqueda);
  $$(".car-card", panel).forEach(setupTilt);
  $$(".car-card", panel).forEach(el => el.addEventListener("click", () => abrirFichaInventario(Number(el.dataset.id))));
}

// Tarjeta con efecto liquid glass + tilt 3D (reutilizada en resultados de búsqueda)
function cardHTML(car){
  return `
    <article class="car-card" data-id="${car.id}" tabindex="0">
      <div class="car-card-inner">
        <span class="car-card-tipo-badge">${car.tipo === "moto" ? "Moto" : "Auto"}</span>
        <div class="car-card-3d">${imagenAuto()}</div>
        <div class="car-card-overlay">
          <div class="overlay-brand">${car.marca}</div>
          <div class="overlay-model">${car.modelo}</div>
          <div class="overlay-meta">
            <span class="overlay-dot" style="background:${car.colorHex}"></span>
            ${car.color}
          </div>
        </div>
      </div>
    </article>`;
}

// Inclinación 3D de la tarjeta al mover el mouse encima
function setupTilt(card){
  const inner = $(".car-card-inner", card);
  const MAX = 9;
  card.addEventListener("mousemove", (e) => {
    const rect = card.getBoundingClientRect();
    const px = (e.clientX - rect.left) / rect.width;
    const py = (e.clientY - rect.top) / rect.height;
    const rotY = (px - 0.5) * MAX * 2;
    const rotX = (0.5 - py) * MAX * 2;
    inner.style.transform = `rotateX(${rotX}deg) rotateY(${rotY}deg) scale(1.02)`;
  });
  card.addEventListener("mouseleave", () => { inner.style.transform = "rotateX(0deg) rotateY(0deg) scale(1)"; });
}

/* ===== 8. MODAL — ficha completa de inventario (consulta desde resultados) ===== */
// Abre la ficha completa de un artículo con botón para iniciar su venta
function abrirFichaInventario(id){
  const car = INVENTARIO.find(c => c.id === id);
  if (!car) return;

  $("#modalInventarioContent").innerHTML = `
    <p class="eyebrow-plain">Ficha de inventario</p>
    <div class="ficha-header">
      <div class="ficha-visual">${imagenAuto()}</div>
      <div class="ficha-info">
        <div class="ficha-brand">${car.marca} · ${car.codigo}</div>
        <h3 class="ficha-model">${car.modelo}</h3>
        <div class="ficha-price">${formatoMoneda(car.precio)}</div>
        <span class="ficha-unidades">${badgeStockHTML(car.unidades)}</span>
      </div>
    </div>
    <div class="ficha-specs-grid">
      <div><div class="spec-label">Color</div><div class="spec-value">${car.color}</div></div>
      <div><div class="spec-label">Motor</div><div class="spec-value">${car.motor}</div></div>
      <div><div class="spec-label">Cilindraje</div><div class="spec-value">${car.cilindraje}</div></div>
    </div>
    <div class="ficha-unique-box"><b>Descripción —</b> ${car.detalle}</div>
    <div class="venta-actions">
      <button class="btn btn-primary" id="btnIniciarVenta">Iniciar venta con este modelo</button>
      <button class="btn btn-ghost" data-close-modal>Cerrar</button>
    </div>
  `;

  $("#btnIniciarVenta").addEventListener("click", () => {
    cerrarModales();
    formTipoArticulo = "Vehiculo";
    borrador = { marca: car.marca, modelo: car.modelo };
    salirResultadosBusqueda();
  });

  abrirModal("#modalInventario");
}

/* ===== 9. INVENTARIO — filtro por categoría (o búsqueda global) ===== */
// Dibuja Inventario: búsqueda global, selector de categoría o tabla de la categoría elegida
function renderInventario(){
  const panel = $("#panelFull");
  const q = searchQuery.trim().toLowerCase();

  // Si hay texto en el buscador, ignoramos la categoría y buscamos en todo
  if (q){
    const resultados = INVENTARIO.filter(c => `${c.marca} ${c.modelo} ${c.codigo}`.toLowerCase().includes(q));
    panel.innerHTML = `
      <div class="panel-heading"><h2>Inventario</h2></div>
      <p class="hint-banner">Buscando “${escapeHTML(searchQuery)}” en todas las categorías.</p>
      ${tablaInventarioHTML(resultados)}
    `;
    return;
  }

  // Sin búsqueda activa: exige elegir una de las 4 categorías primero
  if (!inventarioCategoria){
    panel.innerHTML = `
      <div class="panel-heading"><h2>Inventario</h2></div>
      <p class="venta-empty-hint" style="margin-bottom:18px;">Elige una categoría para consultar el inventario correspondiente.</p>
      <div class="tipo-tiles">
        ${tileTipoHTML("Porsche")}${tileTipoHTML("Audi")}${tileTipoHTML("Ducati")}${tileTipoHTML("Refacciones")}
      </div>
    `;
    $$(".tipo-tile", panel).forEach(el => el.addEventListener("click", () => {
      inventarioCategoria = el.dataset.tipo;
      renderInventario();
    }));
    return;
  }

  const items = inventarioCategoria === "Refacciones"
    ? INVENTARIO.filter(c => c.tipo === "refaccion")
    : INVENTARIO.filter(c => c.marca === inventarioCategoria && c.tipo !== "refaccion");
  panel.innerHTML = `
    <div class="section-toolbar">
      <div class="tipo-chip">Categoría: ${inventarioCategoria}<button type="button" id="btnCambiarCategoria">✕</button></div>
    </div>
    <div class="hint-banner">Inventario consultado directamente desde MySQL.</div>
    ${tablaInventarioHTML(items)}
  `;
  $("#btnCambiarCategoria", panel).addEventListener("click", () => { inventarioCategoria = null; renderInventario(); });
}

// Tabla compartida entre la vista por categoría y la búsqueda global
function tablaInventarioHTML(items){
  if (!items.length){
    return `<div class="empty-state"><strong>Sin resultados</strong>No se encontraron artículos que coincidan con la búsqueda.</div>`;
  }
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead><tr><th>Código</th><th>Marca</th><th>Modelo</th><th>Año</th><th>Color</th><th>Motor</th><th>Unidades</th><th>Precio</th></tr></thead>
        <tbody>
          ${items.map(c => `
            <tr>
              <td>${c.codigo}</td><td>${c.marca}</td><td>${c.modelo}</td><td>${c.anio ?? "—"}</td><td>${c.color}</td>
              <td>${c.motor}</td><td>${badgeStockHTML(c.unidades)}</td><td>${formatoMoneda(c.precio)}</td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>`;
}

// Tile de categoría reutilizado en Inventario (y antes en Venta)
function tileTipoHTML(tipo){
  return `
    <button class="tipo-tile" data-tipo="${tipo}" type="button">
      <span class="tipo-tile-icon">${ICONOS_TIPO[tipo]}</span>
      <span class="tipo-tile-label">${tipo}</span>
    </button>`;
}

/* ===== 10. CLIENTES — tabla + detalle (con abonos pagados / totales) ===== */
// Dibuja la tabla de clientes con crédito (filtrada por el buscador)
function renderClientes(){
  const panel = $("#panelFull");
  const q = searchQuery.trim().toLowerCase();
  const lista = CLIENTES.filter(c => !q || `${c.nombre} ${c.articulo || ""}`.toLowerCase().includes(q));

  panel.innerHTML = `
    <div class="panel-heading"><h2>Clientes</h2></div>
    <p class="venta-empty-hint" style="margin-bottom:18px;">Clientes con un crédito automotriz activo y saldo pendiente. Toca una fila para ver el detalle completo; al liquidar la última mensualidad el cliente sale de la lista.</p>
    ${lista.length ? `
      <div class="table-wrap">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Artículo</th><th>Abonos</th><th>Próximo abono</th><th>Saldo pendiente</th><th></th></tr></thead>
          <tbody>
            ${lista.map(c => `
              <tr class="is-clickable" data-cliente="${c.id}">
                <td>${escapeHTML(c.nombre)}</td><td>${escapeHTML(c.celular || "—")}</td><td>${escapeHTML(c.articulo || "—")}</td>
                <td>${c.abonosPagados} de ${c.abonosTotales}</td>
                <td>${formatoMonedaCentavos(c.montoAbono)}${c.venceSiguiente ? `<br><small class="garantia-detalle">Vence ${escapeHTML(c.venceSiguiente)}</small>` : ""}</td>
                <td>${formatoMonedaCentavos(c.totalAdeudo)}</td>
                <td><button class="btn-table" type="button" data-cobrar-abono="${c.id}">Cobrar abono</button></td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>`
      : CLIENTES.length
        ? `<div class="empty-state"><strong>Sin resultados</strong>Ningún cliente coincide con “${escapeHTML(searchQuery)}”.</div>`
        : `<div class="empty-state"><strong>Sin créditos activos</strong>Los clientes aparecen aquí al concretar un crédito automotriz y salen al liquidarlo.</div>`
    }
  `;
  $$("[data-cliente]", panel).forEach(row => row.addEventListener("click", () => abrirDetalleCliente(Number(row.dataset.cliente))));
  $$("[data-cobrar-abono]", panel).forEach(btn => btn.addEventListener("click", (e) => {
    e.stopPropagation();
    iniciarCobroAbono(Number(btn.dataset.cobrarAbono));
  }));
}

// «Cobrar abono»: manda la siguiente mensualidad del crédito al ticket de Venta (el formulario de venta no se toca)
function iniciarCobroAbono(id){
  const c = CLIENTES.find(x => x.id === id);
  if (!c) return;
  if (pagoEstado){ avisar("Termina primero el cobro que está en curso."); return; }
  if (ticketItems.some(it => it.esAbono && it.contratoId === c.contratoId)){ setActiveView("venta"); return; }
  if (ticketItems.length){
    avisar("El ticket actual tiene artículos. Concrétalo o cancélalo (F6) antes de cobrar un abono: el abono se cobra en su propio ticket.");
    return;
  }
  ticketIdCounter += 1;
  ticketItems.push({
    id: ticketIdCounter, esAbono: true, articulo: "Abono mensual", cantidad: 1,
    // Importe exacto de la siguiente mensualidad según la tabla de amortización del contrato
    precioTotal: Number(c.montoAbono), contratoId: c.contratoId, contratoFolio: c.contratoFolio,
    numeroAbono: c.siguienteAbono, abonosTotales: c.abonosTotales, vence: c.venceSiguiente,
    saldoAnterior: Number(c.totalAdeudo), saldoRestante: Math.max(Math.round((Number(c.totalAdeudo) - Number(c.montoAbono)) * 100) / 100, 0),
    cliente: c.nombre, celular: c.celular || "", email: c.email || "", rfcIne: c.rfcIne || "", direccion: c.direccion || "",
    identificacionTipo: c.identificacionTipo || "", vehiculo: c.articulo, vin: c.vin || "",
    // Identificador único de este cobro: si se reenvía (doble clic, error de red) el servidor no lo registra dos veces
    clave: (window.crypto?.randomUUID ? crypto.randomUUID() : "10000000-1000-4000-8000-100000000000".replace(/[018]/g, d => (d ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> d / 4).toString(16)))
  });
  modoEliminarTicket = false;
  cerrarModales();
  setActiveView("venta");
}

// ¿El ticket actual es el cobro de un abono mensual?
function ticketEsAbono(){
  return ticketItems.some(it => it.esAbono);
}

// Ficha de detalle de un cliente, incluye "Total de abonos" (pagados de totales)
function abrirDetalleCliente(id){
  const c = CLIENTES.find(x => x.id === id);
  if (!c) return;
  // Arma un dato de solo lectura (etiqueta + valor)
  const campo = (label, valor) => `
    <div class="form-field"><label>${label}</label>
      <div class="venta-field-sub" style="font-size:14px; color:var(--text-main); font-weight:600;">${valor}</div>
    </div>`;

  $("#modalClienteContent").innerHTML = `
    <p class="eyebrow-plain">Detalle de cliente</p>
    <h3 class="modal-title">${c.nombre}</h3>
    <div class="form-grid" style="margin-top:18px;">
      ${campo("Celular", c.celular)}
      ${campo("Email", c.email)}
      ${campo("Artículo", c.articulo)}
      ${campo("Saldo pendiente", formatoMonedaCentavos(c.totalAdeudo))}
      ${campo("Monto de abono", formatoMonedaCentavos(c.montoAbono))}
      ${campo("Enganche", c.enganche ? formatoMoneda(c.enganche) : "—")}
      ${campo("Total de abonos", `${c.abonosPagados} de ${c.abonosTotales}`)}
      ${campo("Próximo abono", `${c.siguienteAbono} de ${c.abonosTotales}${c.venceSiguiente ? ` · vence ${escapeHTML(c.venceSiguiente)}` : ""}`)}
      ${campo("Contrato", escapeHTML(c.contratoFolio || "—"))}
      ${campo("RFC / CURP", escapeHTML(c.rfcIne || "—"))}
      ${campo("Identificación", escapeHTML([c.identificacionTipo, c.identificacionNumero].filter(Boolean).join(" · ") || "—"))}
      <div class="form-field span-2"><label>Domicilio</label>
        <div class="venta-field-sub" style="font-size:14px; color:var(--text-main); font-weight:600;">${escapeHTML(c.direccion || "—")}</div>
      </div>
    </div>
    ${contratosClienteHTML(c)}
    <div class="venta-actions">
      <button class="btn btn-primary" type="button" id="btnCobrarAbonoDetalle">Cobrar abono</button>
      <button class="btn btn-ghost" data-close-modal>Cerrar</button>
    </div>
  `;
  abrirModal("#modalCliente");
  $("#btnCobrarAbonoDetalle").addEventListener("click", () => iniciarCobroAbono(c.id));
  $$("[data-ver-contrato]", $("#modalClienteContent")).forEach(btn => btn.addEventListener("click", () => abrirVisorContrato(Number(btn.dataset.verContrato), btn.dataset.folio)));
}

// Lista de contratos de crédito del cliente: cada operación tiene el suyo y se abre por separado
function contratosClienteHTML(c){
  const contratos = c.contratos || [];
  if (!contratos.length){
    return `<div class="contratos-cliente"><p class="form-field-info" style="margin:0;">Sin contrato digital: este crédito se registró antes de que el POS generara contratos firmados.</p>
      <button class="btn btn-outline" type="button" disabled title="No hay un contrato firmado para este cliente">Ver contrato</button></div>`;
  }
  return `
    <div class="contratos-cliente">
      <label>Contratos de crédito (${contratos.length})</label>
      ${contratos.map(k => `
        <div class="contrato-fila">
          <div>
            <strong>${escapeHTML(k.folio)}</strong> · ${escapeHTML(k.vehiculo)}<br>
            <span>Firmado el ${escapeHTML(k.fecha || "—")} en ${escapeHTML(k.sucursal)} · ${k.plazo} meses de ${formatoMoneda(k.mensualidad)} · VIN ${escapeHTML(k.vin || "—")} · ${k.estadoCredito === "liquidado" ? "Liquidado" : `${k.abonosPagados ?? 0} de ${k.plazo} abonos`}</span>
          </div>
          <button class="btn btn-outline" type="button" data-ver-contrato="${k.id}" data-folio="${escapeHTML(k.folio)}">Ver contrato</button>
        </div>`).join("")}
    </div>`;
}

/* ===== 11. GARANTÍAS — tabla + formulario de pantalla completa ===== */
// Dibuja la tabla de garantías vigentes (filtrada por el buscador)
// Garantías que siguen vigentes en este instante (cada una desaparece justo en su fecha y hora de vencimiento)
function garantiasVigentes(){
  const ahora = Date.now();
  return GARANTIAS.filter(g => !g.expiraIso || Date.parse(g.expiraIso) > ahora);
}

// Si la pantalla de Garantías sigue abierta, se vuelve a dibujar en el momento exacto en que vence la siguiente garantía
let temporizadorGarantias = null;
function programarVencimientoGarantias(){
  clearTimeout(temporizadorGarantias);
  const ahora = Date.now();
  const proximo = Math.min(...garantiasVigentes().map(g => Date.parse(g.expiraIso)).filter(t => t > ahora));
  if (!Number.isFinite(proximo) || proximo - ahora > 2147483000) return;
  temporizadorGarantias = setTimeout(() => { if (currentView === "garantias") renderGarantias(); }, proximo - ahora + 50);
}

// Columna de estado: aplicar garantía, solicitud pendiente del gerente o solicitud denegada (con el motivo)
function estadoGarantiaHTML(g){
  if (g.solicitudEstado === "pendiente"){
    return `<span class="garantia-estado garantia-estado--pendiente">Pendiente de aprobación del gerente</span>
      <small class="garantia-detalle">Solicitud ${escapeHTML(g.solicitudFolio || "")} · ${escapeHTML(g.solicitudFecha || "")}</small>`;
  }
  const boton = (texto) => `<button class="btn btn-primary" data-garantia="${g.id}" style="padding:7px 16px; font-size:12px;">${texto}</button>`;
  if (g.solicitudEstado === "denegada"){
    return `<span class="garantia-estado garantia-estado--denegada">Denegada por el gerente</span>
      <small class="garantia-detalle">Motivo: ${escapeHTML(g.motivoRechazo || "sin motivo registrado")}</small>
      ${boton("Enviar nueva solicitud")}`;
  }
  return boton("Aplicar garantía");
}

// Garantías vigentes pendientes de atención, de la más próxima a vencer a la de mayor vigencia (orden del servidor)
function renderGarantias(){
  const panel = $("#panelFull");
  const q = searchQuery.trim().toLowerCase();
  const vigentes = garantiasVigentes();
  const lista = vigentes.filter(g => !q || `${g.nombre || ""} ${g.articulo || ""} ${g.vin || ""}`.toLowerCase().includes(q));

  panel.innerHTML = `
    <div class="panel-heading"><h2>Garantías</h2></div>
    <p class="venta-empty-hint" style="margin-bottom:18px;">Garantías de 4 años de los vehículos vendidos (contado y crédito), de la más próxima a vencer a la de mayor vigencia. El cajero envía la solicitud y el gerente la confirma o la deniega.</p>
    ${lista.length ? `
      <div class="table-wrap">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Artículo</th><th>Compra</th><th>Expira</th><th>Estado</th></tr></thead>
          <tbody>
            ${lista.map(g => `
              <tr>
                <td>${escapeHTML(g.nombre || "—")}</td><td>${escapeHTML(g.celular || "—")}</td>
                <td>${escapeHTML(g.articulo)}${g.vin ? `<br><small class="garantia-detalle" translate="no">VIN ${escapeHTML(g.vin)}</small>` : ""}</td>
                <td>${escapeHTML(g.compra || "—")}</td>
                <td>${escapeHTML(g.expira)}${g.expiraHora ? `<br><small class="garantia-detalle">${escapeHTML(g.expiraHora)} h</small>` : ""}</td>
                <td class="garantia-estado-celda">${estadoGarantiaHTML(g)}</td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>`
      : vigentes.length
        ? `<div class="empty-state"><strong>Sin resultados</strong>Ninguna garantía coincide con “${escapeHTML(searchQuery)}”.</div>`
        : `<div class="empty-state"><strong>Sin garantías vigentes</strong>Cada vehículo que se venda (de contado o a crédito) registra aquí su garantía de 4 años automáticamente.</div>`
    }
  `;
  $$("[data-garantia]", panel).forEach(btn => btn.addEventListener("click", () => abrirGarantiaForm(Number(btn.dataset.garantia))));
  programarVencimientoGarantias();
}

// Abre el formulario de garantía a pantalla completa, prellenado con el cliente y el vehículo de la garantía
function abrirGarantiaForm(id){
  const g = GARANTIAS.find(x => x.id === id);
  if (!g || !garantiasVigentes().includes(g)){ avisar("Esta garantía ya no está vigente."); renderGarantias(); return; }
  if (g.solicitudEstado === "pendiente"){ avisar("Esta garantía ya tiene una solicitud pendiente de aprobación del gerente."); return; }
  const contacto = [g.nombre, g.celular, g.email].filter(Boolean).join(" — ");

  $("#garantiaOverlayContent").innerHTML = `
    <div class="fullscreen-header">
      <div>
        <p class="eyebrow-plain">Servicio de garantía</p>
        <h2>Aplicar garantía</h2>
      </div>
      <button class="btn btn-ghost" id="btnCerrarGarantia">Cerrar</button>
    </div>
    <div class="hint-banner">La garantía no se aplica desde caja: al enviar se valida tu gafete y la solicitud queda <strong>pendiente de aprobación del gerente</strong>, que la confirma o la deniega. Vigente hasta el ${escapeHTML(g.expira)} a las ${escapeHTML(g.expiraHora || "")} h.</div>
    ${g.solicitudEstado === "denegada" ? `<div class="hint-banner garantia-denegada-banner">La solicitud anterior (${escapeHTML(g.solicitudFolio || "")}) fue denegada. Motivo: ${escapeHTML(g.motivoRechazo || "sin motivo registrado")}</div>` : ""}
    <div class="fullscreen-body">
      <div class="fullscreen-form">
        <div class="form-grid">
          <div class="form-field span-2"><label>Nombre del propietario</label><input type="text" id="gNombre" value="${escapeHTML(g?.nombre || "")}"></div>
          <div class="form-field span-2"><label>Datos de contacto (teléfono y correo)</label><input type="text" id="gContacto" value="${escapeHTML(contacto)}"></div>
          <div class="form-field"><label>Número de Identificación Vehicular (VIN)</label><input type="text" id="gVin" value="${escapeHTML(g.vin || "")}" placeholder="17 caracteres"></div>
          <div class="form-field"><label>Placa y año del modelo</label><input type="text" id="gPlaca" placeholder="Ej. KMA-2026 / 2025"></div>
          <div class="form-field"><label>Kilometraje actual</label><input type="number" id="gKm" placeholder="Ej. 8500"></div>
          <div class="form-field"><label>Factura o contrato de compra-venta</label><input type="text" id="gFactura" value="${escapeHTML(g.folioVenta || "")}" placeholder="Folio de factura / contrato"></div>
          <div class="form-field span-2"><label>Carnet / historial de servicios de mantenimiento</label><input type="text" id="gCarnet" placeholder="Referencia de historial"></div>
          <div class="form-field"><label>Fecha y hora de inicio de la falla</label><input type="datetime-local" id="gFechaFalla"></div>
          <div class="form-field"><label>Fecha de recepción de la unidad</label><input type="datetime-local" id="gFechaRecepcion"></div>
          <div class="form-field span-2"><label>Descripción detallada del síntoma (obligatoria)</label><textarea id="gSintoma"></textarea></div>
          <div class="form-field span-2"><label>Condiciones en las que ocurre la falla</label><textarea id="gCondiciones"></textarea></div>
          <div class="form-field span-2"><label>Evidencia física o digital (fotos / videos / códigos)</label><input type="text" id="gEvidencia" placeholder="Descripción de la evidencia adjunta"></div>
          <div class="form-field"><label>Nombre y firma del asesor</label><input type="text" id="gAsesor" value="${escapeHTML(CAJERO_ACTUAL)}"></div>
          <div class="form-field"><label>Firma de conformidad del cliente</label><input type="text" id="gFirmaCliente" placeholder="Nombre de conformidad"></div>
        </div>
        <div class="venta-actions">
          <button class="btn btn-primary" id="btnGuardarGarantia">Enviar solicitud al gerente</button>
          <button class="btn btn-ghost" id="btnCancelarGarantia">Cancelar</button>
        </div>
      </div>
      <div class="fullscreen-side">
        <label class="image-drop" id="dropImagenGarantia">
          <span id="dropImagenPreview"></span>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M4 16.5V6a2 2 0 0 1 2-2h5l2 2h5a2 2 0 0 1 2 2v8.5"/><path d="M4 16.5 8 12l3 3 4-4 5 5.5"/></svg>
          <span class="image-drop-label">Adjuntar imagen del auto</span>
          <span>Click para seleccionar (opcional)</span>
          <input type="file" accept="image/*" id="inpImagenGarantia">
        </label>
      </div>
    </div>
  `;

  // Vista previa real de la imagen adjunta (FileReader, sin subirla a ningún lado)
  $("#inpImagenGarantia").addEventListener("change", (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = ev => { $("#dropImagenPreview").innerHTML = `<img src="${ev.target.result}" alt="Imagen adjunta">`; };
    reader.readAsDataURL(file);
  });

  $("#btnCerrarGarantia").addEventListener("click", cerrarGarantiaForm);
  $("#btnCancelarGarantia").addEventListener("click", cerrarGarantiaForm);
  $("#btnGuardarGarantia").addEventListener("click", async () => {
    const valor = (sel) => ($(sel)?.value || "").trim();
    if (!valor("#gSintoma")){ $("#gSintoma").focus(); avisar("Describe el síntoma de la falla antes de enviar la solicitud."); return; }
    const boton = $("#btnGuardarGarantia");
    boton.disabled = true;
    // Autorización de empleado (gafete QR o código): el servidor la valida y la registra antes de guardar la solicitud
    const autorizacion = await solicitarAutorizacionEmpleado("GARANTIA", id, "Solicitud de garantía");
    if (!autorizacion){ boton.disabled = false; return; }
    try {
      const data = await apiFetch("aplicar_garantia", {
        method: "POST",
        autorizacion,
        body: JSON.stringify({
          id_garantia: id,
          formulario: {
            propietario: valor("#gNombre"), contacto: valor("#gContacto"), vin: valor("#gVin"), placa_anio: valor("#gPlaca"),
            kilometraje: valor("#gKm"), factura: valor("#gFactura"), historial_servicios: valor("#gCarnet"),
            fecha_falla: valor("#gFechaFalla"), fecha_recepcion: valor("#gFechaRecepcion"), sintoma: valor("#gSintoma"),
            condiciones: valor("#gCondiciones"), evidencia: valor("#gEvidencia"), asesor: valor("#gAsesor"), conformidad_cliente: valor("#gFirmaCliente")
          }
        })
      });
      cerrarGarantiaForm();
      try { await refrescarDatosDB(); } catch (_) { /* la solicitud ya quedó guardada */ }
      renderGarantias();
      avisar(data.message || "Solicitud enviada al gerente.");
    } catch (error) {
      boton.disabled = false;
      avisar(error.message);
    }
  });

  $("#garantiaOverlay").classList.add("is-open");
}
// Cierra el formulario de garantía
function cerrarGarantiaForm(){ $("#garantiaOverlay").classList.remove("is-open"); }

/* ===== 12. WEB ORDERS — filtro por marca + búsqueda por nombre + "continuar" ===== */
// Dibuja las órdenes web separadas en vehículos y refacciones
function renderWebOrders(){
  const panel = $("#panelFull");
  const categorias = ["Todo", "Porsche", "Audi", "Ducati", "Refacciones"];
  const q = searchQuery.trim().toLowerCase();

  // Texto seguro: los datos de las órdenes los escribe el cliente en el Catálogo web
  const t = (v) => escapeHTML(v ?? "—");
  const esRefaccion = (o) => o.tipo === "refaccion";
  const ordenes = WEBORDERS.filter(o =>
    (webOrdersFiltro === "Todo" ||
      (webOrdersFiltro === "Refacciones" ? esRefaccion(o) : (o.marca === webOrdersFiltro || (o.lineas || []).some(l => l.marca === webOrdersFiltro)))) &&
    (!q || `${o.nombre} ${o.folio || ""}`.toLowerCase().includes(q))
  );
  // Pedidos del Catálogo con varias piezas (recoger en sucursal + efectivo): se cobran directo con "Cobrar"
  const pedidosCatalogo = ordenes.filter(o => esRefaccion(o) && (o.lineas || []).length);
  const vehiculos = ordenes.filter(o => o.tipo === "vehiculo");
  const refacciones = ordenes.filter(o => esRefaccion(o) && !(o.lineas || []).length);

  panel.innerHTML = `
    <div class="panel-heading"><h2>Web orders</h2><button class="btn-table" id="btnRefrescarWeb" type="button">Actualizar</button></div>
    <div class="section-toolbar">
      <div class="filter-pills" id="webFiltros">
        ${categorias.map(c => `<button class="filter-pill ${webOrdersFiltro === c ? "is-active" : ""}" data-filtro="${c}">${c}</button>`).join("")}
      </div>
    </div>

    ${pedidosCatalogo.length ? `
      <p class="form-field-info" style="margin-bottom:10px;"><strong>Pedidos del Catálogo · pendientes de cobro en caja.</strong> Las piezas ya están apartadas del inventario de esta sucursal.</p>
      <div class="table-wrap" style="margin-bottom:22px;">
        <table class="data-table">
          <thead><tr><th>Folio</th><th>Cliente</th><th>Celular</th><th>Artículos</th><th>Total</th><th>Recibido</th><th></th></tr></thead>
          <tbody>
            ${pedidosCatalogo.map(o => `
              <tr>
                <td>${t(o.folio)}</td><td>${t(o.nombre)}</td><td>${t(o.celular)}</td>
                <td>${o.lineas.map(l => `${l.cantidad}× ${escapeHTML(l.descripcion)}`).join("<br>")}</td>
                <td>${formatoMoneda(o.total)}</td><td>${t(o.fechaCreacion)}</td>
                <td style="white-space:nowrap;"><button class="btn-table" data-cobrar-web="${o.id}">Cobrar</button> <button class="btn-table" data-cancelar-web="${o.id}">Cancelar</button></td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>` : ""
    }

    ${vehiculos.length ? `
      <div class="table-wrap" style="margin-bottom:22px;">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Email</th><th>Artículo</th><th>Color</th><th>Enganche</th><th>Fecha y hora de visita</th><th></th></tr></thead>
          <tbody>
            ${vehiculos.map(o => `
              <tr>
                <td>${t(o.nombre)}${o.folio ? `<br><small>${t(o.folio)}</small>` : ""}</td><td>${t(o.celular)}</td><td>${t(o.email)}</td>
                <td>${t(o.articulo)}</td><td>${t(o.color)}</td>
                <td>${o.enganche ? formatoMoneda(o.enganche) : "—"}</td>
                <td>${t(o.fechaVisita)}</td>
                <td style="white-space:nowrap;"><button class="btn-table" data-continuar="${o.id}">Continuar</button>${o.folio ? ` <button class="btn-table" data-cancelar-web="${o.id}">Cancelar</button>` : ""}</td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>` : ""
    }

    ${refacciones.length ? `
      <div class="table-wrap">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Pieza</th><th>Modelo</th><th>Motor</th><th>Cilindraje</th><th>Tracción</th><th>Transmisión</th><th>Lado</th><th></th></tr></thead>
          <tbody>
            ${refacciones.map(o => `
              <tr>
                <td>${t(o.nombre)}</td><td>${t(o.celular)}</td><td>${t(o.pieza)}</td><td>${t(o.modelo)}</td>
                <td>${t(o.motor)}</td><td>${t(o.cilindraje)}</td><td>${t(o.traccion)}</td><td>${t(o.transmision)}</td><td>${t(o.lado)}</td>
                <td><button class="btn-table" data-continuar="${o.id}">Continuar</button></td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>` : ""
    }

    ${!pedidosCatalogo.length && !vehiculos.length && !refacciones.length ? `
      <div class="empty-state"><strong>Sin órdenes</strong>Ninguna orden coincide con este filtro o búsqueda.</div>` : ""
    }

    <p class="form-field-info" style="margin-top:18px;">Órdenes recibidas desde el Catálogo web para esta sucursal (visitas, apartados y pedidos de refacciones con pago en efectivo). Los pedidos pagados con tarjeta no aparecen aquí porque ya están cobrados.</p>
  `;

  $$("[data-filtro]", panel).forEach(btn => btn.addEventListener("click", () => { webOrdersFiltro = btn.dataset.filtro; renderWebOrders(); }));
  $$("[data-continuar]", panel).forEach(btn => btn.addEventListener("click", () => {
    const orden = WEBORDERS.find(o => o.id === Number(btn.dataset.continuar));
    continuarDesdeWebOrder(orden);
  }));
  $$("[data-cobrar-web]", panel).forEach(btn => btn.addEventListener("click", () => abrirCobroOrdenWeb(WEBORDERS.find(o => o.id === Number(btn.dataset.cobrarWeb)))));
  $$("[data-cancelar-web]", panel).forEach(btn => btn.addEventListener("click", () => cancelarOrdenWebPOS(Number(btn.dataset.cancelarWeb))));
  $("#btnRefrescarWeb")?.addEventListener("click", async () => {
    try { await refrescarDatosDB(); renderWebOrders(); } catch (error) { avisar(error.message); }
  });
}

/* Cobro en efectivo de un pedido del Catálogo (mismo diseño del cobro normal; no descuenta inventario otra vez) */
let pagoOrdenWeb = null;
function abrirCobroOrdenWeb(orden){
  if (!orden) return;
  pagoOrdenWeb = { orden, monto: Number(orden.total || 0), recibido: 0, cambio: 0, valido: false };
  $("#modalPagoContent").innerHTML = `
    <div class="payment-title">Cobrar pedido ${escapeHTML(orden.folio || "")}</div>
    <p class="payment-subtitle">${escapeHTML(orden.nombre)} · ${orden.lineas.map(l => `${l.cantidad}× ${escapeHTML(l.descripcion)}`).join(", ")}</p>
    <div class="payment-total-box"><span>Total a pagar</span><strong>${formatoMoneda(pagoOrdenWeb.monto)}</strong></div>
    <div class="cash-form">
      <label for="inpEfectivoWeb">Dinero recibido</label>
      <input type="number" id="inpEfectivoWeb" min="0" step="0.01" placeholder="0.00">
      <div id="cashMessageWeb" class="cash-message"></div>
      <div class="cash-change"><span>Cambio</span><strong id="cashChangeWeb">${formatoMoneda(0)}</strong></div>
    </div>
    <div class="payment-actions">
      <button class="btn btn-ghost" id="btnCancelarCobroWeb" type="button">Cancelar</button>
      <button class="btn btn-primary" id="btnConfirmarCobroWeb" type="button" disabled>Cobrar pedido</button>
    </div>`;
  abrirModal("#modalPago");
  const input = $("#inpEfectivoWeb");
  input.addEventListener("input", () => {
    const recibido = Number(input.value || 0);
    pagoOrdenWeb.recibido = recibido;
    pagoOrdenWeb.cambio = Math.max(recibido - pagoOrdenWeb.monto, 0);
    pagoOrdenWeb.valido = recibido >= pagoOrdenWeb.monto;
    const msg = $("#cashMessageWeb");
    msg.textContent = recibido <= 0 ? "" : (pagoOrdenWeb.valido ? "Dinero correcto." : `Faltan ${formatoMoneda(pagoOrdenWeb.monto - recibido)}.`);
    msg.classList.toggle("is-error", recibido > 0 && !pagoOrdenWeb.valido);
    msg.classList.toggle("is-ok", pagoOrdenWeb.valido);
    $("#cashChangeWeb").textContent = formatoMoneda(pagoOrdenWeb.cambio);
    $("#btnConfirmarCobroWeb").disabled = !pagoOrdenWeb.valido;
  });
  $("#btnCancelarCobroWeb").addEventListener("click", cerrarModales);
  $("#btnConfirmarCobroWeb").addEventListener("click", confirmarCobroOrdenWeb);
  input.focus();
}

async function confirmarCobroOrdenWeb(){
  if (!pagoOrdenWeb?.valido) return;
  const boton = $("#btnConfirmarCobroWeb");
  boton.disabled = true;
  const { orden, recibido } = pagoOrdenWeb;
  // Autorización de empleado (gafete QR o código) ligada a esta orden: sin ella el servidor no cobra
  const autorizacion = await solicitarAutorizacionEmpleado("ORDEN_WEB", orden.id, `Cobrar pedido ${orden.folio || ""}`.trim());
  if (!autorizacion){ boton.disabled = false; return; }
  try {
    const data = await apiFetch("cobrar_orden_web", { method: "POST", autorizacion, body: JSON.stringify({ id_orden: orden.id, efectivo_recibido: recibido, ticket_numero: ticketNumero }) });
    // Ticket digital igual al de una venta normal
    ticketCerrado = {
      numero: ticketNumero, ventaId: data.venta_id, folio: data.folio, fecha: data.fecha,
      cajero: CAJERO_ACTUAL, sucursal: SUCURSAL_ACTUAL, sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION, sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
      caja: CAJA_ACTUAL, metodo: "Efectivo", subtotal: data.total, total: data.total, recibido, cambio: data.cambio,
      items: data.lineas.map(l => ({ articulo: `${l.cantidad}× ${l.descripcion}`, precioTotal: l.subtotal, cantidad: l.cantidad, cliente: orden.nombre, email: orden.email || "", celular: orden.celular || "" }))
    };
    pagoOrdenWeb = null;
    cerrarModales();
    ticketNumero += 1;
    await refrescarDatosDB();
    renderWebOrders();
    mostrarTicketCliente();
  } catch (error) {
    boton.disabled = false;
    avisar(error.message);
  }
}

/* Cancela una orden web pendiente; si había apartado piezas, regresan al inventario de la sucursal */
async function cancelarOrdenWebPOS(idOrden){
  if (!confirm("¿Cancelar esta orden web? Si apartó piezas, regresarán al inventario de la sucursal.")) return;
  // Autorización de empleado (gafete QR o código) ligada a esta orden: sin ella el servidor no cancela
  const autorizacion = await solicitarAutorizacionEmpleado("ORDEN_WEB", idOrden, "Cancelar orden web");
  if (!autorizacion) return;
  try {
    await apiFetch("cancelar_orden_web", { method: "POST", autorizacion, body: JSON.stringify({ id_orden: idOrden }) });
    await refrescarDatosDB();
    renderWebOrders();
  } catch (error) { avisar(error.message); }
}

// Lleva los datos de una orden web directo al formulario de Venta
function continuarDesdeWebOrder(orden){
  if (!orden) return;
  if (orden.tipo === "vehiculo"){
    // Si la orden ya trae un enganche, lo más común es que sea una venta a crédito
    const item = INVENTARIO.find(c =>
      (orden.productoId && c.id === Number(orden.productoId)) ||
      (c.marca === orden.marca && c.modelo === (orden.productoModelo || orden.articulo))
    );
    if (orden.enganche){
      formTipoArticulo = "Credito";
      borrador = {
        webOrderId: orden.id,
        cliente: orden.nombre, email: orden.email, celular: orden.celular,
        marca: item?.marca, modelo: item?.modelo, anio: item?.anio, color: item?.color,
        engancheTipo: "monto", engancheValor: orden.enganche,
        articuloRef: orden.articulo, colorRef: orden.color
      };
    } else {
      formTipoArticulo = "Vehiculo";
      borrador = {
        webOrderId: orden.id,
        cliente: orden.nombre, email: orden.email, celular: orden.celular,
        marca: item?.marca, modelo: item?.modelo, anio: item?.anio, color: item?.color,
        articuloRef: orden.articulo, colorRef: orden.color
      };
    }
  } else {
    formTipoArticulo = "Refaccion";
    borrador = {
      webOrderId: orden.id,
      cliente: orden.nombre,
      marcaVehiculo: orden.marcaVehiculo, modelo: orden.modelo,
      traccion: orden.traccion, lado: orden.lado, motor: orden.motor
    };
    recalcularCascadaRefaccion();
    if (!borrador.piezaId && orden.pieza){
      const candidato = refPiezasDisponibles(borrador).find(p => p.nombre.toLowerCase() === String(orden.pieza).toLowerCase());
      if (candidato) borrador.piezaId = candidato.id;
    }
  }
  setActiveView("venta");
}

/* ===== 13. MODALES GENÉRICOS ===== */
// Abre un modal por su selector
function abrirModal(sel){ $(sel).classList.add("is-open"); }
// Cierra todos los modales abiertos
function cerrarModales(){ $$(".modal-overlay").forEach(m => m.classList.remove("is-open")); }

/* ===== 14. RELOJ / FECHA EN VIVO ===== */
// Actualiza fecha y hora de la barra inferior con el formato del idioma activo
function actualizarReloj(){
  const ahora = new Date();
  const locale = window.KarmaTraductor?.getIdioma() === "en" ? "en-US" : "es-MX";
  $("#statusFecha").textContent = ahora.toLocaleDateString(locale, { day: "2-digit", month: "short", year: "numeric" });
  $("#statusHora").textContent = ahora.toLocaleTimeString(locale, { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

/* ===== 15. MODO OSCURO / IDIOMA / SESIÓN ===== */
// Cambia entre modo claro y modo oscuro
function toggleTema(){ document.body.classList.toggle("dark"); }

// API DE TRADUCCIÓN: el botón ES / EN pide al traductor universal que cambie el idioma de toda la página
function toggleIdioma(){
  if (!window.KarmaTraductor) return avisar("El traductor no está disponible.");
  window.KarmaTraductor.alternar();
}

// Marca en el botón ES / EN el idioma que está activo
function marcarIdiomaActivo(){
  const idioma = window.KarmaTraductor?.getIdioma() || "es";
  $$(".lang-op").forEach(el => el.classList.toggle("is-active", el.dataset.lang === idioma));
  actualizarReloj();
}

// Evita repetir el aviso de error de traducción
let avisoTraduccionMostrado = false;
// Si la traducción falla (sin clave o sin internet) avisa una sola vez y regresa a español
function alFallarTraduccion(e){
  if (avisoTraduccionMostrado) return;
  avisoTraduccionMostrado = true;
  alert(`No se pudo traducir la página: ${e.detail?.mensaje || "error desconocido"}`);
  window.KarmaTraductor?.setIdioma("es");
}

/* Cierra la sesión del POS en el servidor y regresa a la pantalla de login */
async function cerrarSesion(){
  const btn = $("#logoutBtn");
  if (btn.dataset.busy) return;
  btn.dataset.busy = "1";
  btn.textContent = "Cerrando sesión…";
  btn.disabled = true;
  try { await apiFetch("logout", { method:"POST", body:"{}" }); } catch (_) {}
  localStorage.removeItem("karma_user");
  window.location.href = "../../index.html";
}

/* ===== 16. BUSCADOR — enrutado según la vista activa ===== */
// Manda el texto del buscador a la vista que esté activa
function onSearchInput(){
  searchQuery = $("#searchInput").value.trim();

  if (currentView === "venta"){
    if (ventaResultadosActivos) renderResultadosBusqueda();
    else renderVentaSugerencias(searchQuery);
  } else if (currentView === "inventario"){
    renderInventario();
  } else if (currentView === "clientes"){
    renderClientes();
  } else if (currentView === "garantias"){
    renderGarantias();
  } else if (currentView === "weborders"){
    renderWebOrders();
  }
}

/* ===== 17. EVENTOS GLOBALES + ARRANQUE ===== */
// Conecta los eventos que no dependen de ninguna vista (logo, tema, idioma, atajos, modales)
function initEventosGlobales(){
  $("#statusCajero").textContent = CAJERO_ACTUAL;

  // Logo → siempre regresa a Venta
  $("#logoHome").addEventListener("click", irAInicio);

  // Cuenta: tema / idioma / sesión
  $("#themeToggle").addEventListener("click", toggleTema);
  $("#langToggle").addEventListener("click", toggleIdioma);
  $("#logoutBtn").addEventListener("click", cerrarSesion);
  // Catálogo web: si hay un ticket en curso se confirma antes de salir para no perder la venta
  $("#catalogLink")?.addEventListener("click", (e) => {
    if (ticketItems.length && !confirm("Hay un ticket en curso. ¿Salir al Catálogo? Se perderán los artículos capturados.")) e.preventDefault();
  });

  // Traductor: refleja el idioma activo y avisa si la API de traducción falla
  document.addEventListener("karma:idioma", marcarIdiomaActivo);
  document.addEventListener("karma:traduccion-error", alFallarTraduccion);
  marcarIdiomaActivo();

  // Vista previa 3D: se monta cuando el módulo de Three.js termina de cargar (o avisa si falló)
  window.addEventListener("karma:vista3d-lista", montarVistaPrevia3D);
  window.addEventListener("karma:vista3d-fallo", montarVistaPrevia3D);

  // Cambio de pestaña
  $("#subNav").addEventListener("click", (e) => {
    const btn = e.target.closest(".sub-nav-btn");
    if (btn) setActiveView(btn.dataset.view);
  });

  // Buscador contextual
  $("#searchInput").addEventListener("input", onSearchInput);
  document.addEventListener("click", (e) => { if (!e.target.closest(".search-box")) cerrarSugerencias(); });

  // Atajos de teclado F3–F6, solo activos dentro de la vista Venta
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape"){
      if (pagoEstado) cerrarPago();
      else cerrarModales();
      cerrarGarantiaForm(); cerrarSugerencias(); return;
    }
    if (currentView !== "venta" || !["F3", "F4", "F5", "F6"].includes(e.key)) return;
    e.preventDefault();
    if (pagoEstado && e.key !== "F3") return;
    if (e.key === "F3") {
      if (pagoEstado?.valido) confirmarVentaDB();
      else concretarVenta();
    } else if (e.key === "F4") toggleModoEliminar();
    else if (e.key === "F5") toggleCotizacion();
    else if (e.key === "F6") cancelarTicket();
  });

  // Cierre genérico de modales (fondo o botón "×")
  $$(".modal-overlay").forEach(overlay => overlay.addEventListener("click", (e) => {
    if (e.target !== overlay) return;
    if (overlay.id === "modalPago") cerrarPago();
    else cerrarModales();
  }));
  document.addEventListener("click", (e) => {
    const close = e.target.closest("[data-close-modal]");
    if (!close) return;
    if (close.closest("#modalPago")) cerrarPago();
    else cerrarModales();
  });
}

// Inicia la interfaz, reloj y eventos principales
document.addEventListener("DOMContentLoaded", () => {
  initEventosGlobales();
  actualizarPlaceholderBusqueda();
  actualizarReloj();
  setInterval(actualizarReloj, 1000);
  renderMain();
  cargarDatosDB();
});
