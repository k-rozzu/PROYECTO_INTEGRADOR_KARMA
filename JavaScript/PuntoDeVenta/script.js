/* ==========================================================================
   KARMA · Punto de Venta — Panel de Cajero
   Datos y catálogos cargados desde la base de datos mediante API.
   ========================================================================== */

/* Datos cargados desde la base de datos */
let CAJERO_ACTUAL = "Cargando…";
let SUCURSAL_ACTUAL = "Cargando…";
let CAJA_ACTUAL = "—";
let USUARIO_ACTUAL_ID = null;
let SUCURSAL_ACTUAL_ID = null;
let CAJA_ACTUAL_ID = null;

let INVENTARIO = [];
let CLIENTES = [];
let GARANTIAS = [];
let WEBORDERS = [];
let REFACCIONES = [];

const TASA_INTERES_ANUAL_DEFAULT = 18;
const COMISION_APERTURA_PCT = 0.02;
const PLAZOS_CREDITO = [12, 24, 36, 48, 60];

/* Estado de carga y sincronización */
let datosDBCargados = false;

async function apiFetch(action, options = {}) {
  const url = `api.php?action=${encodeURIComponent(action)}`;
  const config = { headers: { "Content-Type": "application/json" }, ...options };
  const response = await fetch(url, config);
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
    CAJA_ACTUAL = String(data.caja?.numero_caja ?? "01").padStart(2, "0");
    USUARIO_ACTUAL_ID = data.usuario?.id_usuario ?? null;
    SUCURSAL_ACTUAL_ID = data.sucursal?.id_sucursal ?? null;
    CAJA_ACTUAL_ID = data.caja?.id_caja ?? null;

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
}


/* --------------------------------------------------------------------------
   2. ESTADO GLOBAL
   -------------------------------------------------------------------------- */

let currentView = "venta";          // venta | inventario | clientes | garantias | weborders
let searchQuery = "";               // texto actual del buscador (su uso cambia según la vista)

// --- Estado del formulario de venta ---
let formTipoArticulo = "Vehiculo";  // 'Vehiculo' | 'Credito' | 'Refaccion' — toggle dentro del propio formulario
let borrador = {};                  // valores prellenados (ej. desde Web Orders → Continuar)
let modoCotizacion = false;         // F5 — simula una venta sin guardarla en el ticket

// --- Estado propio del módulo de Crédito ---
let creditoTipoProducto = "Vehiculo"; // 'Vehiculo' | 'Refaccion' — qué se está financiando
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

/* --------------------------------------------------------------------------
   3. HELPERS GENERALES
   -------------------------------------------------------------------------- */
const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));

// Formatea números como pesos mexicanos; "—" si no hay valor
function formatoMoneda(n){
  if (n === null || n === undefined || n === "") return "—";
  return Number(n).toLocaleString("es-MX", { style: "currency", currency: "MXN", maximumFractionDigits: 0 });
}
// Evita inyección de HTML al insertar texto libre del usuario
function escapeHTML(str){
  return String(str ?? "").replace(/[&<>"']/g, s => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[s]));
}
// Imagen de referencia compartida (mockup: mismo asset para cualquier artículo)
function imagenAuto(){
  return `<img class="car-photo" src="../../assets/porsche.jpg" alt="Vista de referencia del vehículo" loading="lazy">`;
}

// Íconos de línea para los 4 tiles de categoría de Inventario
const ICONOS_TIPO = {
  Porsche: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M3 16l1.5-5.5A3 3 0 0 1 7.4 8h9.2a3 3 0 0 1 2.9 2.5L21 16"/><path d="M3 16h18v2a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-1H7v1a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-2Z"/><circle cx="7.5" cy="16" r="1.4"/><circle cx="16.5" cy="16" r="1.4"/></svg>`,
  Audi: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="6" cy="12" r="3.4"/><circle cx="11" cy="12" r="3.4"/><circle cx="16" cy="12" r="3.4"/><circle cx="21" cy="12" r="3.4"/></svg>`,
  Ducati: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="5.5" cy="17" r="2.6"/><circle cx="18.5" cy="17" r="2.6"/><path d="M5.5 17l3-8h5l4 5h3M8.5 9h4"/></svg>`,
  Refacciones: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14.7 6.3a4 4 0 0 1-5.4 5.4L4 17l3 3 5.3-5.3a4 4 0 0 1 5.4-5.4l-2.6 2.6-2-2 2.6-2.6Z"/></svg>`
};

/* --------------------------------------------------------------------------
   2b. INVENTARIO — helpers de cascada Marca → Modelo → Año
   Solo devuelven marcas/modelos/años que todavía tienen unidades en stock;
   si una combinación no aparece, es porque no hay inventario suficiente.
   -------------------------------------------------------------------------- */

// Marcas con al menos un artículo disponible
function marcasDisponibles(){
  return [...new Set(INVENTARIO.filter(c => c.unidades > 0 && c.tipo !== "refaccion").map(c => c.marca))];
}
// Modelos disponibles para una marca ya elegida
function modelosDisponibles(marca){
  return [...new Set(INVENTARIO.filter(c => c.marca === marca && c.unidades > 0 && c.tipo !== "refaccion").map(c => c.modelo))];
}
// Años disponibles para una combinación marca + modelo ya elegida
function aniosDisponibles(marca, modelo){
  return [...new Set(INVENTARIO.filter(c => c.marca === marca && c.modelo === modelo && c.unidades > 0 && c.tipo !== "refaccion").map(c => c.anio))]
    .sort((a, b) => a - b);
}
// Artículo exacto de inventario para marca + modelo + año (o undefined si no hay stock)
function buscarArticuloInventario(marca, modelo, anio){
  return INVENTARIO.find(c => c.marca === marca && c.modelo === modelo && String(c.anio) === String(anio) && c.unidades > 0 && c.tipo !== "refaccion");
}

/* --------------------------------------------------------------------------
   3. NAVEGACIÓN ENTRE VISTAS
   -------------------------------------------------------------------------- */

// Cambia de pestaña: resetea estados temporales de UI y vuelve a dibujar todo
function setActiveView(view){
  currentView = view;
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

/* --------------------------------------------------------------------------
   4. VENTA — formulario de registro (izquierda, 3/5)
   -------------------------------------------------------------------------- */

// Dibuja el formulario completo (toggle de tipo + campos + acciones)
function renderPanelVenta(){
  const panel = $("#panelVenta");
  if (!panel) return;
  panel.innerHTML = formularioVentaHTML();
  bindFormularioVenta();
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

// Cascada Marca → Modelo → Año + cuadrito de unidades/precio disponibles.
// Se reutiliza igual en el formulario de Vehículo (contado) y en el de Crédito.
function selectoresArticuloHTML(idPrefix, b){
  const marcas = marcasDisponibles();
  const modelos = b.marca ? modelosDisponibles(b.marca) : [];
  const anios = (b.marca && b.modelo) ? aniosDisponibles(b.marca, b.modelo) : [];
  const item = (b.marca && b.modelo && b.anio) ? buscarArticuloInventario(b.marca, b.modelo, b.anio) : null;

  return `
    <div class="form-field">
      <label>Marca</label>
      <select id="sel${idPrefix}Marca">
        <option value="">Selecciona…</option>
        ${marcas.map(m => `<option value="${m}" ${b.marca === m ? "selected" : ""}>${m}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Modelo</label>
      <select id="sel${idPrefix}Modelo" ${!b.marca ? "disabled" : ""}>
        <option value="">${b.marca ? "Selecciona…" : "Elige una marca primero"}</option>
        ${modelos.map(m => `<option value="${escapeHTML(m)}" ${b.modelo === m ? "selected" : ""}>${m}</option>`).join("")}
      </select>
    </div>
    <div class="form-field">
      <label>Año</label>
      <select id="sel${idPrefix}Anio" ${!b.modelo ? "disabled" : ""}>
        <option value="">${b.modelo ? "Selecciona…" : "Elige un modelo primero"}</option>
        ${anios.map(a => `<option value="${a}" ${String(b.anio) === String(a) ? "selected" : ""}>${a}</option>`).join("")}
      </select>
    </div>
    <div class="form-field span-2">
      ${item
        ? `<div class="stock-price-box">
             <div><span>Unidades disponibles</span><strong>${item.unidades}</strong></div>
             <div><span>Precio</span><strong>${formatoMoneda(item.precio)}</strong></div>
           </div>`
        : `<div class="form-field-info">Elige marca, modelo y año para ver unidades y precio.</div>`
      }
    </div>
  `;
}

// Conecta los 3 selects de la cascada Marca → Modelo → Año.
// onChange() se llama después de cada cambio para recalcular lo que dependa del artículo elegido.
function bindSelectoresArticulo(idPrefix, panel, onChange){
  const selMarca = $(`#sel${idPrefix}Marca`, panel);
  const selModelo = $(`#sel${idPrefix}Modelo`, panel);
  const selAnio = $(`#sel${idPrefix}Anio`, panel);
  selMarca?.addEventListener("change", () => {
    borrador.marca = selMarca.value || undefined;
    borrador.modelo = undefined;
    borrador.anio = undefined;
    onChange();
  });
  selModelo?.addEventListener("change", () => {
    borrador.modelo = selModelo.value || undefined;
    borrador.anio = undefined;
    onChange();
  });
  selAnio?.addEventListener("change", () => {
    borrador.anio = selAnio.value || undefined;
    onChange();
  });
}

// Campos para la venta de contado de un vehículo (Marca/Modelo/Año en cascada según stock;
// el precio ya viene fijo desde el inventario, por eso este registro no lleva enganche ni abonos)
function camposVehiculoHTML(){
  const b = borrador;
  return `
    <div class="form-grid">
      <div class="form-field"><label>Cliente</label><input type="text" id="inpCliente" value="${escapeHTML(b.cliente || "")}" placeholder="Nombre completo"></div>
      <div class="form-field"><label>RFC / INE</label><input type="text" id="inpRfcIne" value="${escapeHTML(b.rfcIne || "")}" placeholder="Identificación"></div>
      <div class="form-field"><label>Email</label><input type="email" id="inpEmail" value="${escapeHTML(b.email || "")}" placeholder="correo@ejemplo.com"></div>
      <div class="form-field"><label>Celular</label><input type="tel" id="inpCelular" value="${escapeHTML(b.celular || "")}" placeholder="10 dígitos"></div>

      ${selectoresArticuloHTML("Vehiculo", b)}
    </div>
  `;
}

// Campos para la venta de una refacción
function camposRefaccionHTML(){
  const b = borrador;
  return `
    <div class="form-grid">
      <div class="form-field span-2"><label>Cliente</label><input type="text" id="inpClienteP" value="${escapeHTML(b.cliente || "")}" placeholder="Nombre completo"></div>
      <div class="form-field"><label>RFC / INE</label><input type="text" id="inpRfcIneP" value="${escapeHTML(b.rfcIne || "")}" placeholder="Identificación"></div>
      <div class="form-field"><label>Email</label><input type="email" id="inpEmailP" value="${escapeHTML(b.email || "")}" placeholder="correo@ejemplo.com"></div>
      <div class="form-field"><label>Celular</label><input type="tel" id="inpCelularP" value="${escapeHTML(b.celular || "")}" placeholder="10 dígitos"></div>
      <div class="form-field span-2">
        <label>Refacción</label>
        <select id="selRefaccion">
          <option value="">Selecciona una refacción…</option>
          ${REFACCIONES.map(r => `<option value="${r.id}" ${String(b.productoId || "") === String(r.id) ? "selected" : ""}>${escapeHTML(r.nombre)} — ${formatoMoneda(r.precio)}</option>`).join("")}
        </select>
      </div>
      <div class="form-field span-2">
        ${b.productoId ? (() => {
          const r = REFACCIONES.find(x => String(x.id) === String(b.productoId));
          return r ? `<div class="stock-price-box"><div><span>Unidades disponibles</span><strong>${r.unidades}</strong></div><div><span>Precio</span><strong>${formatoMoneda(r.precio)}</strong></div><div><span>Modelo compatible</span><strong>${escapeHTML(r.modelo || "—")}</strong></div></div>` : `<div class="form-field-info">Selecciona una refacción.</div>`;
        })() : `<div class="form-field-info">Selecciona una refacción para consultar existencia y precio.</div>`}
      </div>
    </div>
  `;
}

// Campos del módulo de Crédito: plazos, enganche, tasa e info de intereses.
// Es el único lugar donde se financia — el registro de Vehículo es solo de contado.
function camposCreditoHTML(){
  const b = borrador;
  const tasa = b.tasaAnual ?? TASA_INTERES_ANUAL_DEFAULT;
  const plazo = Number(b.plazoMeses) || null;
  const engancheTipo = b.engancheTipo || "monto";

  // Precio del artículo elegido (vehículo por inventario, o refacción capturada a mano)
  const itemInventario = (b.marca && b.modelo && b.anio) ? buscarArticuloInventario(b.marca, b.modelo, b.anio) : null;
  const precio = creditoTipoProducto === "Refaccion" ? Number(b.precioRefaccion || 0) : Number(itemInventario?.precio || 0);
  const engancheMonto = engancheTipo === "pct"
    ? precio * (Number(b.engancheValor || 0) / 100)
    : Number(b.engancheValor || 0);

  const calculo = (precio > 0 && plazo) ? calcularCredito({ precio, engancheMonto, plazoMeses: plazo, tasaAnualPct: Number(tasa) }) : null;

  return `
    <div class="form-grid">
      <div class="form-field"><label>Cliente</label><input type="text" id="inpClienteC" value="${escapeHTML(b.cliente || "")}" placeholder="Nombre completo"></div>
      <div class="form-field"><label>RFC / INE</label><input type="text" id="inpRfcIneC" value="${escapeHTML(b.rfcIne || "")}" placeholder="Identificación"></div>
      <div class="form-field"><label>Email</label><input type="email" id="inpEmailC" value="${escapeHTML(b.email || "")}" placeholder="correo@ejemplo.com"></div>
      <div class="form-field"><label>Celular</label><input type="tel" id="inpCelularC" value="${escapeHTML(b.celular || "")}" placeholder="10 dígitos"></div>

      <!-- Tipo de producto a financiar: reutiliza la cascada de inventario o los campos de refacción -->
      <div class="form-field span-2">
        <label>Producto a financiar</label>
        <div class="segmented">
          <button type="button" class="segmented-btn ${creditoTipoProducto === "Vehiculo" ? "is-active" : ""}" data-credito-producto="Vehiculo">Vehículo / Moto</button>
          <button type="button" class="segmented-btn ${creditoTipoProducto === "Refaccion" ? "is-active" : ""}" data-credito-producto="Refaccion">Refacción</button>
        </div>
      </div>

      ${creditoTipoProducto === "Refaccion" ? `
        <div class="form-field"><label>Pieza</label><input type="text" id="inpPiezaC" value="${escapeHTML(b.pieza || "")}" placeholder="Ej. Disco de freno delantero"></div>
        <div class="form-field"><label>Modelo compatible</label><input type="text" id="inpModeloC" value="${escapeHTML(b.modelo || "")}" placeholder='Ej. 911 (2019)'></div>
        <div class="form-field"><label>Precio Total del Producto</label><input type="number" id="inpPrecioRefaccionC" value="${escapeHTML(b.precioRefaccion || "")}" placeholder="$ 0.00"></div>
      ` : selectoresArticuloHTML("Credito", b)}

      <!-- Enganche: por porcentaje o por monto en dinero -->
      <div class="form-field">
        <label>Enganche</label>
        <div class="segmented">
          <button type="button" class="segmented-btn ${engancheTipo === "pct" ? "is-active" : ""}" data-eng-tipo="pct">Porcentaje</button>
          <button type="button" class="segmented-btn ${engancheTipo === "monto" ? "is-active" : ""}" data-eng-tipo="monto">Monto: $</button>
        </div>
        <input type="number" id="inpEngancheValor" style="margin-top:8px;" value="${escapeHTML(b.engancheValor ?? "")}" placeholder="${engancheTipo === "pct" ? "Ej. 20" : "$ 0.00"}">
      </div>

      <!-- Plazo del crédito en meses -->
      <div class="form-field">
        <label>Plazo</label>
        <div class="plazo-group" id="plazoGroup">
          ${PLAZOS_CREDITO.map(m => `<button type="button" class="plazo-btn ${plazo === m ? "is-active" : ""}" data-plazo="${m}">${m} meses</button>`).join("")}
        </div>
      </div>

      <div class="form-field"><label>Tasa de interés anual (%)</label><input type="number" id="inpTasaAnual" value="${escapeHTML(tasa)}" step="0.1"></div>
    </div>

    <!-- Resultado de la simulación: se recalcula en vivo con cada cambio -->
    <div class="credito-info-grid">
      <div class="credito-info-box"><span>Comisión por apertura (2%)</span><strong>${calculo ? formatoMoneda(calculo.comisionApertura) : "—"}</strong></div>
      <div class="credito-info-box"><span>Monto de interés</span><strong>${calculo ? formatoMoneda(calculo.montoInteres) : "—"}</strong></div>
      <div class="credito-info-box"><span>Monto final (con interés)</span><strong>${calculo ? formatoMoneda(calculo.montoFinal) : "—"}</strong></div>
      <div class="credito-info-box"><span>Mensualidad estimada</span><strong>${calculo ? formatoMoneda(calculo.mensualidad) : "—"}</strong></div>
    </div>

    <div class="venta-actions" style="margin-top:16px;">
      <button type="button" class="btn btn-outline" id="btnTablaAmortizacion" ${calculo ? "" : "disabled"}>
        ${mostrarTablaAmortizacion ? "Ocultar" : "Generar"} tabla de amortización
      </button>
    </div>
    <div id="tablaAmortizacionWrap">${mostrarTablaAmortizacion && calculo ? tablaAmortizacionHTML(calculo) : ""}</div>
  `;
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

  // Selección de refacción desde el inventario de la base de datos
  if (formTipoArticulo === "Refaccion"){
    $("#selRefaccion", panel)?.addEventListener("change", (e) => {
      borrador.productoId = e.target.value || undefined;
      renderPanelVenta();
    });
  }

  // Cascada Marca → Modelo → Año, solo para el registro de contado de Vehículo
  if (formTipoArticulo === "Vehiculo"){
    bindSelectoresArticulo("Vehiculo", panel, renderPanelVenta);
  }

  // Todos los controles propios del módulo de Crédito (cualquier cambio vuelve a
  // dibujar el formulario para recalcular comisión / interés / mensualidad en vivo)
  if (formTipoArticulo === "Credito"){
    $$("[data-credito-producto]", panel).forEach(btn => btn.addEventListener("click", () => {
      creditoTipoProducto = btn.dataset.creditoProducto;
      borrador.marca = borrador.modelo = borrador.anio = undefined;
      renderPanelVenta();
    }));

    if (creditoTipoProducto === "Vehiculo"){
      bindSelectoresArticulo("Credito", panel, renderPanelVenta);
    } else {
      $("#inpPiezaC", panel)?.addEventListener("input", (e) => { borrador.pieza = e.target.value; });
      $("#inpModeloC", panel)?.addEventListener("input", (e) => { borrador.modelo = e.target.value; });
      $("#inpPrecioRefaccionC", panel)?.addEventListener("input", (e) => { borrador.precioRefaccion = e.target.value; renderPanelVenta(); });
    }

    $$("[data-eng-tipo]", panel).forEach(btn => btn.addEventListener("click", () => {
      borrador.engancheTipo = btn.dataset.engTipo;
      renderPanelVenta();
    }));
    $("#inpEngancheValor", panel)?.addEventListener("input", (e) => { borrador.engancheValor = e.target.value; renderPanelVenta(); });

    $$("[data-plazo]", panel).forEach(btn => btn.addEventListener("click", () => {
      borrador.plazoMeses = btn.dataset.plazo;
      renderPanelVenta();
    }));
    $("#inpTasaAnual", panel)?.addEventListener("input", (e) => { borrador.tasaAnual = e.target.value; renderPanelVenta(); });

    $("#btnTablaAmortizacion", panel)?.addEventListener("click", () => {
      mostrarTablaAmortizacion = !mostrarTablaAmortizacion;
      renderPanelVenta();
    });
  }
}

// Limpia solo los campos capturados (no toca el ticket ya guardado)
function limpiarFormulario(){
  borrador = {};
  creditoTipoProducto = "Vehiculo";
  mostrarTablaAmortizacion = false;
  renderPanelVenta();
}

// Lee el formulario, arma el artículo y lo agrega al ticket
async function guardarArticulo(){
  try {
    let cliente = "", email = "", celular = "", rfcIne = "", productoId = null, item = null;

    if (formTipoArticulo === "Refaccion"){
      cliente = $("#inpClienteP").value.trim();
      if (!cliente){ $("#inpClienteP").focus(); return; }
      email = $("#inpEmailP").value.trim();
      celular = $("#inpCelularP").value.trim();
      rfcIne = $("#inpRfcIneP").value.trim();
      productoId = Number($("#selRefaccion").value || 0);
      item = REFACCIONES.find(r => r.id === productoId);
      if (!item || item.unidades < 1) return;
      ticketIdCounter += 1;
      ticketItems.push({
        id: ticketIdCounter,
        productoId: item.id,
        esVehiculo: false,
        articulo: item.nombre,
        precioTotal: Number(item.precio || 0),
        cantidad: 1,
        cliente, email, celular, rfcIne
      });
    } else if (formTipoArticulo === "Credito"){
      cliente = $("#inpClienteC").value.trim();
      if (!cliente){ $("#inpClienteC").focus(); return; }
      email = $("#inpEmailC").value.trim();
      celular = $("#inpCelularC").value.trim();
      rfcIne = $("#inpRfcIneC").value.trim();

      const esVehiculoFinanciado = creditoTipoProducto === "Vehiculo";
      item = esVehiculoFinanciado ? buscarArticuloInventario(borrador.marca, borrador.modelo, borrador.anio) : null;
      const precio = esVehiculoFinanciado ? Number(item?.precio || 0) : Number(borrador.precioRefaccion || 0);
      const plazo = Number(borrador.plazoMeses || 0);
      if ((esVehiculoFinanciado && !item) || !precio || !plazo) return;

      if (esVehiculoFinanciado) productoId = item.id;
      else {
        const ref = REFACCIONES.find(r => r.nombre.toLowerCase() === String(borrador.pieza || "").toLowerCase());
        productoId = ref?.id || null;
      }

      const tasa = Number(borrador.tasaAnual ?? TASA_INTERES_ANUAL_DEFAULT);
      const engancheMonto = borrador.engancheTipo === "pct"
        ? precio * (Number(borrador.engancheValor || 0) / 100)
        : Number(borrador.engancheValor || 0);
      const calculo = calcularCredito({ precio, engancheMonto, plazoMeses: plazo, tasaAnualPct: tasa });

      ticketIdCounter += 1;
      ticketItems.push({
        id: ticketIdCounter, productoId, esVehiculo: true, esCredito: true,
        articulo: esVehiculoFinanciado
          ? `${item.marca} ${item.modelo} (${item.anio})`
          : `${borrador.pieza || "Pieza sin especificar"}${borrador.modelo ? " — " + borrador.modelo : ""}`,
        abonos: `${plazo} meses`, enganche: engancheMonto, montoAbono: calculo.mensualidad,
        tasaAnual: tasa, comisionApertura: calculo.comisionApertura, montoInteres: calculo.montoInteres,
        montoFinal: calculo.montoFinal, precioTotal: engancheMonto + calculo.montoFinal,
        cantidad: 1, cliente, email, celular, rfcIne
      });
    } else {
      cliente = $("#inpCliente").value.trim();
      if (!cliente){ $("#inpCliente").focus(); return; }
      email = $("#inpEmail").value.trim();
      celular = $("#inpCelular").value.trim();
      rfcIne = $("#inpRfcIne").value.trim();
      item = buscarArticuloInventario(borrador.marca, borrador.modelo, borrador.anio);
      if (!item) return;

      ticketIdCounter += 1;
      ticketItems.push({
        id: ticketIdCounter, productoId: item.id, esVehiculo: true,
        articulo: `${item.marca} ${item.modelo} (${item.anio})`,
        precioTotal: item.precio, cantidad: 1, cliente, email, celular, rfcIne
      });
    }

    borrador = {};
    creditoTipoProducto = "Vehiculo";
    mostrarTablaAmortizacion = false;
    renderPanelVenta();
    renderPanelLateral();
    renderShortcutsBar();
  } catch (error) {
    alert(error.message);
  }
}

// F5: calcula un total de referencia sin tocar el ticket real
function calcularCotizacion(){
  let total = 0, detalle = "";
  if (formTipoArticulo === "Refaccion"){
    total = Number($("#inpPrecioP").value || 0);
    detalle = $("#inpPieza").value.trim();
  } else if (formTipoArticulo === "Credito"){
    const esVehiculoFinanciado = creditoTipoProducto === "Vehiculo";
    const item = esVehiculoFinanciado ? buscarArticuloInventario(borrador.marca, borrador.modelo, borrador.anio) : null;
    const precio = esVehiculoFinanciado ? Number(item?.precio || 0) : Number(borrador.precioRefaccion || 0);
    const plazo = Number(borrador.plazoMeses || 0);
    if (precio && plazo){
      const tasa = Number(borrador.tasaAnual ?? TASA_INTERES_ANUAL_DEFAULT);
      const engancheMonto = borrador.engancheTipo === "pct" ? precio * (Number(borrador.engancheValor || 0) / 100) : Number(borrador.engancheValor || 0);
      const calculo = calcularCredito({ precio, engancheMonto, plazoMeses: plazo, tasaAnualPct: tasa });
      total = engancheMonto + calculo.montoFinal;
    }
    detalle = esVehiculoFinanciado ? (item ? `${item.marca} ${item.modelo}` : "") : (borrador.pieza || "");
  } else {
    const item = buscarArticuloInventario(borrador.marca, borrador.modelo, borrador.anio);
    total = item?.precio || 0;
    detalle = item ? `${item.marca} ${item.modelo}` : "";
  }
  $("#cotizacionResultadoWrap").innerHTML = `
    <div class="cotizacion-result">
      <div class="label">Cotización estimada${detalle ? " — " + escapeHTML(detalle) : ""}</div>
      <div class="value">${formatoMoneda(total)}</div>
    </div>`;
}

/* --------------------------------------------------------------------------
   5. VENTA — ticket de la venta actual (derecha, 2/5)
   -------------------------------------------------------------------------- */

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
      <span class="value">${formatoMoneda(calcularTotalTicket())}</span>
    </div>
  `;

  if (modoEliminarTicket){
    $$("[data-quitar-item]", panel).forEach(btn => btn.addEventListener("click", () => quitarItemTicket(Number(btn.dataset.quitarItem))));
  }
}

// Dibuja un artículo con solo los datos visibles del ticket
function ticketItemHTML(it){
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
        </div>` : ""
      }
      <div class="ticket-item-total">Precio total <strong>${formatoMoneda(it.precioTotal)}</strong></div>
    </div>`;
}

// Quita un artículo del ticket (usado en modo eliminar / F4)
function quitarItemTicket(id){
  ticketItems = ticketItems.filter(it => it.id !== id);
  if (!ticketItems.length) modoEliminarTicket = false;
  renderPanelLateral();
  renderShortcutsBar();
}

/* --------------------------------------------------------------------------
   6. VENTA — accesos rápidos F3–F6
   -------------------------------------------------------------------------- */

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
  $("#btnF3").addEventListener("click", () => pagoEstado?.valido ? confirmarVentaDB() : concretarVenta);
  $("#btnF4").addEventListener("click", toggleModoEliminar);
  $("#btnF5").addEventListener("click", toggleCotizacion);
  $("#btnF6").addEventListener("click", cancelarTicket);
}

// F3 — concreta la venta: aquí es el único lugar donde el número de ticket avanza,
// ya que solo debe subir cuando de verdad se cierra una venta (no al cancelar)
function concretarVenta(){
  if (!ticketItems.length || pagoEstado) return;
  abrirModalPago();
}

/* --------------------------------------------------------------------------
   7b. COBRO — selección de método, efectivo y confirmación
   -------------------------------------------------------------------------- */

/* Abre la ventana de selección de método de pago */
function abrirModalPago(){
  pagoEstado = { metodo: null, monto: calcularTotalTicket(), recibido: 0, cambio: 0, valido: false };
  $("#modalPagoContent").innerHTML = `
    <div class="payment-title">Concretar venta</div>
    <p class="payment-subtitle">Selecciona el método de pago para el ticket #${String(ticketNumero).padStart(2, "0")}.</p>
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
  $("#btnPagoTarjeta").addEventListener("click", () => alert("La terminal de tarjeta todavía no está conectada."));
  $("#btnCancelarPago").addEventListener("click", cerrarPago);
}

/* Muestra el formulario vertical para recibir efectivo */
function abrirCobroEfectivo(){
  pagoEstado.metodo = "Efectivo";
  pagoEstado.valido = false;
  $("#modalPagoContent").innerHTML = `
    <div class="payment-title">Pago en efectivo</div>
    <div class="payment-total-box"><span>Total a pagar</span><strong>${formatoMoneda(pagoEstado.monto)}</strong></div>
    <div class="cash-form">
      <label for="inpEfectivo">Dinero recibido</label>
      <input type="number" id="inpEfectivo" min="0" step="0.01" placeholder="0.00" autofocus>
      <div id="cashMessage" class="cash-message"></div>
      <div class="cash-change"><span>Cambio</span><strong id="cashChange">${formatoMoneda(0)}</strong></div>
    </div>
    <div class="payment-actions">
      <button class="btn btn-ghost" id="btnVolverMetodo" type="button">Volver</button>
      <button class="btn btn-primary" id="btnConfirmarEfectivo" type="button" disabled>F3 · Concretar venta</button>
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
  if (recibido <= 0) msg.textContent = "";
  else if (!pagoEstado.valido) msg.textContent = `Faltan ${formatoMoneda(Math.abs(diferencia))}.`;
  else msg.textContent = "Dinero correcto. Puedes presionar F3 para concretar.";
  msg.classList.toggle("is-error", recibido > 0 && !pagoEstado.valido);
  msg.classList.toggle("is-ok", pagoEstado.valido);
  $("#cashChange").textContent = formatoMoneda(pagoEstado.cambio);
  $("#btnConfirmarEfectivo").disabled = !pagoEstado.valido;
  renderShortcutsBar();
}

/* Envía la venta completa al servidor dentro de una transacción MySQL */
async function confirmarVentaDB(){
  if (!pagoEstado?.valido) return;
  const boton = $("#btnConfirmarEfectivo");
  if (boton) boton.disabled = true;

  try {
    const data = await apiFetch("crear_venta", {
      method: "POST",
      body: JSON.stringify({
        id_usuario: USUARIO_ACTUAL_ID,
        id_sucursal: SUCURSAL_ACTUAL_ID,
        id_caja: CAJA_ACTUAL_ID,
        metodo_pago: "Efectivo",
        efectivo_recibido: pagoEstado.recibido,
        cambio: pagoEstado.cambio,
        ticket_numero: ticketNumero,
        items: ticketItems.map(it => ({
          producto_id: it.productoId,
          cantidad: it.cantidad || 1,
          precio_unitario: Number(it.precioTotal || 0),
          es_credito: !!it.esCredito,
          articulo: it.articulo
        })),
        cliente: ticketItems[0]?.cliente || "",
        email: ticketItems[0]?.email || "",
        celular: ticketItems[0]?.celular || "",
        rfc_ine: ticketItems[0]?.rfcIne || ""
      })
    });

    ticketCerrado = {
      numero: ticketNumero,
      ventaId: data.venta_id,
      fecha: data.fecha,
      cajero: CAJERO_ACTUAL,
      sucursal: SUCURSAL_ACTUAL,
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
    alert(error.message);
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
      <div class="digital-ticket-head"><strong>KARMA</strong><span>Venta #${String(t.numero).padStart(2,"0")}</span></div>
      <div class="digital-ticket-meta">${escapeHTML(t.sucursal)} · Caja ${escapeHTML(CAJA_ACTUAL)}<br>${escapeHTML(t.fecha)}</div>
      <div class="digital-ticket-lines">
        ${t.items.map(it => `<div class="digital-ticket-line"><span>${escapeHTML(it.articulo)}</span><strong>${formatoMoneda(it.precioTotal)}</strong></div>`).join("")}
      </div>
      <div class="digital-ticket-total"><span>Total</span><strong>${formatoMoneda(t.total)}</strong></div>
      <div class="digital-ticket-paid"><span>Recibido</span><span>${formatoMoneda(t.recibido)}</span><span>Cambio</span><span>${formatoMoneda(t.cambio)}</span></div>
      <div class="digital-ticket-thanks">Gracias por tu compra.</div>
    </div>
    <div class="ticket-client-actions">
      <button class="btn btn-primary" id="btnAceptarTicket" type="button">Aceptar</button>
      <button class="btn btn-ghost" id="btnEnviarTicket" type="button">Enviar</button>
    </div>
  `;
  abrirModal("#modalTicketCliente");
  $("#btnAceptarTicket").addEventListener("click", cerrarTicketCliente);
  $("#btnEnviarTicket").addEventListener("click", abrirFormularioEnvioTicket);
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
    <div class="payment-title">Enviar ticket</div>
    <p class="payment-subtitle">Ingresa los datos del cliente para preparar el envío del PDF.</p>
    <div class="form-grid">
      <div class="form-field span-2"><label>Nombre completo</label><input id="envioNombre" type="text" value="${escapeHTML(ticketCerrado?.items?.[0]?.cliente || "")}"></div>
      <div class="form-field"><label>Celular</label><input id="envioCelular" type="tel" value="${escapeHTML(ticketCerrado?.items?.[0]?.celular || "")}"></div>
      <div class="form-field"><label>Email</label><input id="envioEmail" type="email" value="${escapeHTML(ticketCerrado?.items?.[0]?.email || "")}"></div>
    </div>
    <div class="payment-actions">
      <button class="btn btn-ghost" id="btnVolverTicket" type="button">Volver</button>
      <button class="btn btn-primary" id="btnEnviarEmail" type="button">Enviar PDF</button>
    </div>
  `;
  $("#btnVolverTicket").addEventListener("click", mostrarTicketCliente);
  $("#btnEnviarEmail").addEventListener("click", enviarTicketPorGmail);
}

/* Prepara el envío del PDF mediante el endpoint de Gmail */
async function enviarTicketPorGmail(){
  const nombre = $("#envioNombre").value.trim();
  const celular = $("#envioCelular").value.trim();
  const email = $("#envioEmail").value.trim();
  if (!nombre || !celular || !email) return;
  const btn = $("#btnEnviarEmail");
  btn.disabled = true;
  try {
    const data = await apiFetch("enviar_ticket", {
      method: "POST",
      body: JSON.stringify({ nombre, celular, email, ticket: ticketCerrado })
    });
    alert(data.message || "Ticket enviado.");
    cerrarTicketCliente();
  } catch (error) {
    btn.disabled = false;
    alert(error.message);
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

/* --------------------------------------------------------------------------
   7. VENTA — búsqueda de artículos (autocompletado → resultados)
   -------------------------------------------------------------------------- */

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

/* --------------------------------------------------------------------------
   8. MODAL — ficha completa de inventario (consulta desde resultados)
   -------------------------------------------------------------------------- */
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
        <span class="ficha-unidades">${car.unidades} unidades disponibles</span>
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

/* --------------------------------------------------------------------------
   9. INVENTARIO — filtro por categoría (o búsqueda global)
   -------------------------------------------------------------------------- */
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
        <thead><tr><th>Código</th><th>Marca</th><th>Modelo</th><th>Color</th><th>Motor</th><th>Unidades</th><th>Precio</th></tr></thead>
        <tbody>
          ${items.map(c => `
            <tr>
              <td>${c.codigo}</td><td>${c.marca}</td><td>${c.modelo}</td><td>${c.color}</td>
              <td>${c.motor}</td><td>${c.unidades}</td><td>${formatoMoneda(c.precio)}</td>
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

/* --------------------------------------------------------------------------
   10. CLIENTES — tabla + detalle (con abonos pagados / totales)
   -------------------------------------------------------------------------- */
function renderClientes(){
  const panel = $("#panelFull");
  const q = searchQuery.trim().toLowerCase();
  const lista = CLIENTES.filter(c => !q || c.nombre.toLowerCase().includes(q));

  panel.innerHTML = `
    <div class="panel-heading"><h2>Clientes</h2></div>
    <p class="venta-empty-hint" style="margin-bottom:18px;">Clientes con crédito activo o pagos en curso. Toca una fila para ver el detalle completo.</p>
    ${lista.length ? `
      <div class="table-wrap">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Artículo</th><th>Total</th></tr></thead>
          <tbody>
            ${lista.map(c => `
              <tr class="is-clickable" data-cliente="${c.id}">
                <td>${c.nombre}</td><td>${c.celular}</td><td>${c.articulo}</td><td>${formatoMoneda(c.totalAdeudo)}</td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>` : `<div class="empty-state"><strong>Sin resultados</strong>Ningún cliente coincide con “${escapeHTML(searchQuery)}”.</div>`
    }
  `;
  $$("[data-cliente]", panel).forEach(row => row.addEventListener("click", () => abrirDetalleCliente(Number(row.dataset.cliente))));
}

// Ficha de detalle de un cliente, incluye "Total de abonos" (pagados de totales)
function abrirDetalleCliente(id){
  const c = CLIENTES.find(x => x.id === id);
  if (!c) return;
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
      ${campo("Total adeudo", formatoMoneda(c.totalAdeudo))}
      ${campo("Monto de abono", formatoMoneda(c.montoAbono))}
      ${campo("Enganche", c.enganche ? formatoMoneda(c.enganche) : "—")}
      ${campo("Total de abonos", `${c.abonosPagados} de ${c.abonosTotales}`)}
    </div>
    <div class="venta-actions"><button class="btn btn-ghost" data-close-modal>Cerrar</button></div>
  `;
  abrirModal("#modalCliente");
}

/* --------------------------------------------------------------------------
   11. GARANTÍAS — tabla + formulario de pantalla completa
   -------------------------------------------------------------------------- */
function renderGarantias(){
  const panel = $("#panelFull");
  const q = searchQuery.trim().toLowerCase();
  const lista = GARANTIAS.filter(g => !q || g.nombre.toLowerCase().includes(q) || g.articulo.toLowerCase().includes(q));

  panel.innerHTML = `
    <div class="panel-heading"><h2>Garantías</h2></div>
    <p class="venta-empty-hint" style="margin-bottom:18px;">Vehículos entregados actualmente en periodo de garantía.</p>
    ${lista.length ? `
      <div class="table-wrap">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Artículo</th><th>Expira</th><th></th></tr></thead>
          <tbody>
            ${lista.map(g => `
              <tr>
                <td>${g.nombre}</td><td>${g.celular}</td><td>${g.articulo}</td><td>${g.expira}</td>
                <td><button class="btn btn-primary" data-garantia="${g.id}" style="padding:7px 16px; font-size:12px;">Aplicar garantía</button></td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>` : `<div class="empty-state"><strong>Sin resultados</strong>Ninguna garantía coincide con “${escapeHTML(searchQuery)}”.</div>`
    }
  `;
  $$("[data-garantia]", panel).forEach(btn => btn.addEventListener("click", () => abrirGarantiaForm(Number(btn.dataset.garantia))));
}

// Abre el formulario de garantía a pantalla completa, prellenado con el cliente elegido
function abrirGarantiaForm(id){
  const g = GARANTIAS.find(x => x.id === id);
  const contacto = g ? `${g.nombre} — ${g.celular}` : "";

  $("#garantiaOverlayContent").innerHTML = `
    <div class="fullscreen-header">
      <div>
        <p class="eyebrow-plain">Servicio de garantía</p>
        <h2>Aplicar garantía</h2>
      </div>
      <button class="btn btn-ghost" id="btnCerrarGarantia">Cerrar</button>
    </div>
    <div class="fullscreen-body">
      <div class="fullscreen-form">
        <div class="form-grid">
          <div class="form-field span-2"><label>Nombre del propietario</label><input type="text" id="gNombre" value="${escapeHTML(g?.nombre || "")}"></div>
          <div class="form-field span-2"><label>Datos de contacto (teléfono y correo)</label><input type="text" id="gContacto" value="${escapeHTML(contacto)}"></div>
          <div class="form-field"><label>Número de Identificación Vehicular (VIN)</label><input type="text" id="gVin" placeholder="17 caracteres"></div>
          <div class="form-field"><label>Placa y año del modelo</label><input type="text" id="gPlaca" placeholder="Ej. KMA-2026 / 2025"></div>
          <div class="form-field"><label>Kilometraje actual</label><input type="number" id="gKm" placeholder="Ej. 8500"></div>
          <div class="form-field"><label>Factura o contrato de compra-venta</label><input type="text" id="gFactura" placeholder="Folio de factura / contrato"></div>
          <div class="form-field span-2"><label>Carnet / historial de servicios de mantenimiento</label><input type="text" id="gCarnet" placeholder="Referencia de historial"></div>
          <div class="form-field"><label>Fecha y hora de inicio de la falla</label><input type="datetime-local" id="gFechaFalla"></div>
          <div class="form-field"><label>Fecha de recepción de la unidad</label><input type="datetime-local" id="gFechaRecepcion"></div>
          <div class="form-field span-2"><label>Descripción detallada del síntoma</label><textarea id="gSintoma"></textarea></div>
          <div class="form-field span-2"><label>Condiciones en las que ocurre la falla</label><textarea id="gCondiciones"></textarea></div>
          <div class="form-field span-2"><label>Evidencia física o digital (fotos / videos / códigos)</label><input type="text" id="gEvidencia" placeholder="Descripción de la evidencia adjunta"></div>
          <div class="form-field"><label>Nombre y firma del asesor</label><input type="text" id="gAsesor" value="${escapeHTML(CAJERO_ACTUAL)}"></div>
          <div class="form-field"><label>Firma de conformidad del cliente</label><input type="text" id="gFirmaCliente" placeholder="Nombre de conformidad"></div>
        </div>
        <div class="venta-actions">
          <button class="btn btn-primary" id="btnGuardarGarantia">Registrar garantía</button>
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
  $("#btnGuardarGarantia").addEventListener("click", () => { cerrarGarantiaForm(); renderGarantias(); });

  $("#garantiaOverlay").classList.add("is-open");
}
function cerrarGarantiaForm(){ $("#garantiaOverlay").classList.remove("is-open"); }

/* --------------------------------------------------------------------------
   12. WEB ORDERS — filtro por marca + búsqueda por nombre + "continuar"
   -------------------------------------------------------------------------- */
function renderWebOrders(){
  const panel = $("#panelFull");
  const categorias = ["Todo", "Porsche", "Audi", "Ducati", "Refacciones"];
  const q = searchQuery.trim().toLowerCase();

  const ordenes = WEBORDERS.filter(o =>
    (webOrdersFiltro === "Todo" || o.marca === webOrdersFiltro) &&
    (!q || o.nombre.toLowerCase().includes(q))
  );
  const vehiculos = ordenes.filter(o => o.tipo === "vehiculo");
  const refacciones = ordenes.filter(o => o.tipo === "refaccion");

  panel.innerHTML = `
    <div class="panel-heading"><h2>Web orders</h2></div>
    <div class="section-toolbar">
      <div class="filter-pills" id="webFiltros">
        ${categorias.map(c => `<button class="filter-pill ${webOrdersFiltro === c ? "is-active" : ""}" data-filtro="${c}">${c}</button>`).join("")}
      </div>
    </div>

    ${vehiculos.length ? `
      <div class="table-wrap" style="margin-bottom:22px;">
        <table class="data-table">
          <thead><tr><th>Nombre</th><th>Celular</th><th>Email</th><th>Artículo</th><th>Color</th><th>Enganche</th><th>Fecha y hora de visita</th><th></th></tr></thead>
          <tbody>
            ${vehiculos.map(o => `
              <tr>
                <td>${o.nombre}</td><td>${o.celular}</td><td>${o.email}</td>
                <td>${o.articulo}</td><td>${o.color}</td>
                <td>${o.enganche ? formatoMoneda(o.enganche) : "—"}</td>
                <td>${o.fechaVisita}</td>
                <td><button class="btn-table" data-continuar="${o.id}">Continuar</button></td>
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
                <td>${o.nombre}</td><td>${o.celular}</td><td>${o.pieza}</td><td>${o.modelo}</td>
                <td>${o.motor}</td><td>${o.cilindraje}</td><td>${o.traccion}</td><td>${o.transmision}</td><td>${o.lado}</td>
                <td><button class="btn-table" data-continuar="${o.id}">Continuar</button></td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>` : ""
    }

    ${!vehiculos.length && !refacciones.length ? `
      <div class="empty-state"><strong>Sin órdenes</strong>Ninguna orden coincide con este filtro o búsqueda.</div>` : ""
    }

    <p class="form-field-info" style="margin-top:18px;">Estas son órdenes de ejemplo — el seguimiento en tiempo real se activará cuando el sitio web esté conectado.</p>
  `;

  $$("[data-filtro]", panel).forEach(btn => btn.addEventListener("click", () => { webOrdersFiltro = btn.dataset.filtro; renderWebOrders(); }));
  $$("[data-continuar]", panel).forEach(btn => btn.addEventListener("click", () => {
    const orden = WEBORDERS.find(o => o.id === Number(btn.dataset.continuar));
    continuarDesdeWebOrder(orden);
  }));
}

// Lleva los datos de una orden web directo al formulario de Venta
function continuarDesdeWebOrder(orden){
  if (!orden) return;
  if (orden.tipo === "vehiculo"){
    // Si la orden ya trae un enganche, lo más común es que sea una venta a crédito
    const item = INVENTARIO.find(c =>
      (orden.productoId && c.id === Number(orden.productoId)) ||
      (c.marca === orden.marca && c.modelo === (orden.productoModelo || orden.articulo) && c.unidades > 0)
    );
    if (orden.enganche){
      formTipoArticulo = "Credito";
      creditoTipoProducto = "Vehiculo";
      borrador = {
        cliente: orden.nombre, email: orden.email, celular: orden.celular,
        marca: item?.marca, modelo: item?.modelo, anio: item?.anio,
        engancheTipo: "monto", engancheValor: orden.enganche,
        articuloRef: orden.articulo, colorRef: orden.color
      };
    } else {
      formTipoArticulo = "Vehiculo";
      borrador = {
        cliente: orden.nombre, email: orden.email, celular: orden.celular,
        marca: item?.marca, modelo: item?.modelo, anio: item?.anio,
        articuloRef: orden.articulo, colorRef: orden.color
      };
    }
  } else {
    formTipoArticulo = "Refaccion";
    borrador = {
      cliente: orden.nombre, pieza: orden.pieza, modelo: orden.modelo,
      marcaVehiculo: orden.marcaVehiculo, motor: orden.motor, cilindraje: orden.cilindraje,
      traccion: orden.traccion, transmision: orden.transmision, lado: orden.lado
    };
  }
  setActiveView("venta");
}

/* --------------------------------------------------------------------------
   13. MODALES GENÉRICOS
   -------------------------------------------------------------------------- */
function abrirModal(sel){ $(sel).classList.add("is-open"); }
function cerrarModales(){ $$(".modal-overlay").forEach(m => m.classList.remove("is-open")); }

/* --------------------------------------------------------------------------
   14. RELOJ / FECHA EN VIVO
   -------------------------------------------------------------------------- */
function actualizarReloj(){
  const ahora = new Date();
  $("#statusFecha").textContent = ahora.toLocaleDateString("es-MX", { day: "2-digit", month: "short", year: "numeric" });
  $("#statusHora").textContent = ahora.toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

/* --------------------------------------------------------------------------
   15. MODO OSCURO / IDIOMA / SESIÓN
   -------------------------------------------------------------------------- */
function toggleTema(){ document.body.classList.toggle("dark"); }
function toggleIdioma(){ $$(".lang-op").forEach(el => el.classList.toggle("is-active")); }

/* Cierra la sesión visualmente; la autenticación completa se integrará después */
async function cerrarSesion(){
  const btn = $("#logoutBtn");
  if (btn.dataset.busy) return;
  btn.dataset.busy = "1";
  const textoOriginal = btn.textContent;
  btn.textContent = "Cerrando sesión…";
  btn.disabled = true;
  try { await apiFetch("logout", { method:"POST", body:"{}" }); } catch (_) {}
  btn.textContent = textoOriginal;
  btn.disabled = false;
  delete btn.dataset.busy;
}

/* --------------------------------------------------------------------------
   16. BUSCADOR — enrutado según la vista activa
   -------------------------------------------------------------------------- */
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

/* --------------------------------------------------------------------------
   17. EVENTOS GLOBALES + ARRANQUE
   -------------------------------------------------------------------------- */
function initEventosGlobales(){
  $("#statusCajero").textContent = CAJERO_ACTUAL;

  // Logo → siempre regresa a Venta
  $("#logoHome").addEventListener("click", irAInicio);

  // Cuenta: tema / idioma / sesión
  $("#themeToggle").addEventListener("click", toggleTema);
  $("#langToggle").addEventListener("click", toggleIdioma);
  $("#logoutBtn").addEventListener("click", cerrarSesion);

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