/* KARMA · Punto de Venta — Cobro con tarjeta mediante Mercado Pago Point (servidor: PHP/PuntoDeVenta/mercado_pago.php).
   F3 → «Tarjeta» muestra el importe y el resumen → «Cobrar en terminal» (gafete del empleado) → mp_iniciar_cobro manda la orden
   a la Point de la caja → esta pantalla pregunta a mp_estado_cobro cada 2 s (el servidor consulta a Mercado Pago y además recibe
   sus Webhooks) → con el pago aprobado el servidor ya registró la venta, el abono o la orden web con la lógica normal y aquí se
   muestra el mismo ticket que con efectivo. El enganche de un crédito sigue al gafete y al contrato con ese pago aprobado.
   Usa lo de script.js (apiFetch, pagoEstado, ticketItems, abrirModal, cerrarPago, mostrarTicketCliente…) y contrato_credito.js. */

// Lo manda el servidor en bootstrap: si la caja tiene terminal, en qué entorno y si quedó un cobro abierto
let MERCADO_PAGO = { disponible: false, entorno: "prueba", terminal: null, aviso: "", cobroAbierto: null };
// Cobro en pantalla: { tipo, monto, ticket, titulo, etiquetaTotal, lineas, autorizacion, datos(), volver(), alAprobar(), pago, clave, timer, fallos }
let cobroTarjeta = null;
const MP_INTERVALO_CONSULTA = 2000;
const MP_PASOS = ["Preparando", "Esperando tarjeta", "Procesando", "Aprobado"];
const MP_TITULOS = {
  preparando: "Preparando pago", esperando: "Esperando tarjeta", procesando: "Procesando pago", aprobado: "Pago aprobado",
  rechazado: "Pago rechazado", cancelado: "Pago cancelado", conexion: "Error de conexión", error: "No se pudo cobrar",
  revision: "Pago aprobado sin registrar"
};

/* ===== 1. Integración con script.js ===== */

// bootstrap: configuración de la caja. Un cobro que quedó abierto (se recargó la página a medio cobro) se retoma
function mpAlCargarDatos(config){
  if (config) MERCADO_PAGO = config;
  if (MERCADO_PAGO.cobroAbierto && !cobroTarjeta) retomarCobroTarjeta(MERCADO_PAGO.cobroAbierto);
}

// Mientras la terminal tiene el cobro, la ventana no se cierra con Esc, con el fondo ni con F6
function cobroTarjetaEnCurso(){
  return !!cobroTarjeta && (cobroTarjeta.enviando || (!!cobroTarjeta.pago && !cobroTarjeta.pago.final));
}

// cerrarPago() libera el cobro terminado (aprobado, rechazado, cancelado…) junto con la ventana
function soltarCobroTarjeta(){
  if (cobroTarjeta) clearTimeout(cobroTarjeta.timer);
  cobroTarjeta = null;
  $("#modalPago")?.classList.remove("is-cobro-tarjeta");
}

// Opción «Tarjeta» del selector de método de pago
function botonPagoTarjetaHTML(){
  const disponible = MERCADO_PAGO.disponible;
  return `
      <button class="payment-method-card ${disponible ? "" : "is-disabled"}" id="btnPagoTarjeta" type="button">
        <span class="payment-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M2.5 9h19M6 14h4"/></svg></span><strong>Tarjeta</strong><span>${disponible
          ? `Mercado Pago Point${MERCADO_PAGO.entorno === "prueba" ? " · modo prueba" : ""}`
          : escapeHTML(MERCADO_PAGO.aviso || "Terminal no disponible")}</span>
      </button>`;
}

// F3 dentro del cobro con tarjeta: envía el cobro (resumen) o continúa al contrato (enganche aprobado)
function teclaF3Tarjeta(){
  const c = cobroTarjeta;
  if (!c) return;
  if (!c.pago) iniciarCobroTarjeta();
  else if (c.pago.vista === "aprobado" && c.tipo === "enganche" && c.alAprobar) c.alAprobar(c.pago);
}

/* ===== 2. Abrir el cobro ===== */

// Ticket de Venta: venta de contado, enganche de crédito o abono mensual
function abrirCobroTarjetaTicket(){
  if (!MERCADO_PAGO.disponible){ avisar(MERCADO_PAGO.aviso || "La terminal de tarjeta no está disponible."); return; }
  const abono = ticketItems.find(it => it.esAbono) || null;
  const credito = ticketItems.find(it => it.esCredito) || null;
  if (credito && ticketItems.some(it => it.esConcepto)){
    avisar("Un crédito no se puede cobrar junto con servicios y trámites. Quita los conceptos (F4) y cóbralos en un ticket aparte.");
    return;
  }
  const tipo = abono ? "abono" : (credito ? "enganche" : "venta");
  pagoEstado = { metodo: "Tarjeta", monto: calcularTotalTicket(), recibido: 0, cambio: 0, valido: false };
  abrirCobroTarjeta({
    tipo,
    monto: pagoEstado.monto,
    ticket: ticketNumero,
    titulo: abono ? "Abono con tarjeta" : (credito ? "Enganche con tarjeta" : "Pago con tarjeta"),
    etiquetaTotal: abono ? "Abono a cobrar" : (credito ? "Enganche a cobrar" : "Total a cobrar"),
    lineas: ticketItems.map(lineaResumenTicket),
    autorizacion: tipo === "venta" ? ["VENTA", ticketNumero, "Cobrar con tarjeta"] : (tipo === "abono" ? ["ABONO", ticketNumero, "Cobrar abono con tarjeta"] : null),
    datos: () => tipo === "abono"
      ? { id_contrato: abono.contratoId, numero_abono: abono.numeroAbono, clave: abono.clave }
      : (tipo === "enganche" ? datosCreditoTicket(credito) : datosVentaTicket()),
    volver: abrirModalPago,
    alAprobar: tipo === "abono" ? (pago) => cerrarAbonoConTarjeta(pago, abono)
      : (tipo === "enganche" ? (pago) => continuarCreditoConTarjeta(pago, credito) : cerrarVentaConTarjeta)
  });
}

// Pedido del Catálogo (Web orders → Cobrar)
function abrirCobroTarjetaOrdenWeb(orden){
  if (!orden) return;
  if (!MERCADO_PAGO.disponible){ avisar(MERCADO_PAGO.aviso || "La terminal de tarjeta no está disponible."); return; }
  pagoEstado = { metodo: "Tarjeta", monto: Number(orden.total || 0), recibido: 0, cambio: 0, valido: false };
  abrirCobroTarjeta({
    tipo: "orden_web",
    monto: pagoEstado.monto,
    ticket: ticketNumero,
    titulo: `Pedido ${orden.folio || ""} con tarjeta`.trim(),
    etiquetaTotal: "Total del pedido",
    lineas: (orden.lineas || []).map(l => ({ texto: `${l.cantidad}× ${l.descripcion}`, importe: Number(l.subtotal || 0) })),
    autorizacion: ["ORDEN_WEB", orden.id, `Cobrar pedido ${orden.folio || ""}`.trim()],
    datos: () => ({ id_orden: orden.id }),
    volver: () => { pagoEstado = null; abrirCobroOrdenWeb(orden); },
    alAprobar: (pago) => cerrarOrdenWebConTarjeta(pago, orden)
  });
}

function abrirCobroTarjeta(contexto){
  soltarCobroTarjeta();
  cobroTarjeta = { ...contexto, pago: null, clave: null, timer: null, fallos: 0, enviando: false };
  abrirModal("#modalPago");
  pintarResumenTarjeta();
}

// Renglón del resumen para cada artículo del ticket
function lineaResumenTicket(it){
  if (it.esAbono) return { texto: `Abono ${it.numeroAbono} de ${it.abonosTotales} · ${it.cliente || ""}`, importe: Number(it.precioTotal || 0) };
  if (it.esCredito) return { texto: `${it.articulo} · enganche`, importe: Number(it.precioTotal || 0) };
  return { texto: `${(it.cantidad || 1) > 1 ? `${it.cantidad}× ` : ""}${it.articulo || "Artículo"}`, importe: Number(it.precioTotal || 0) };
}

// Mismos datos que manda crear_venta (sin efectivo): el servidor recalcula precios y existencias
function datosVentaTicket(){
  return {
    ordenes_web: ticketItems.map(it => it.webOrderId).filter(Boolean),
    items: ticketItems.filter(it => it.productoId).map(it => ({
      producto_id: it.productoId,
      cantidad: it.cantidad || 1,
      vin: it.vin || "",
      motor_serie: it.motorTipo || "",
      color_interior: it.colorInterior || ""
    })),
    conceptos: ticketItems.filter(it => it.esConcepto).map(it => it.payload),
    cliente: ticketItems[0]?.cliente || "",
    email: ticketItems[0]?.email || "",
    celular: ticketItems[0]?.celular || "",
    rfc_ine: ticketItems[0]?.rfcIne || ""
  };
}

/* ===== 3. Pantallas ===== */

// Resumen antes de enviar el cobro a la terminal
function pintarResumenTarjeta(){
  const c = cobroTarjeta;
  $("#modalPago").classList.remove("is-cobro-tarjeta");
  $("#modalPagoContent").innerHTML = `
    <div class="payment-title">${escapeHTML(c.titulo)}</div>
    <p class="payment-subtitle">Revisa el importe con el cliente. Al confirmar, el cobro aparece en la terminal y el cliente paga ahí con su tarjeta.</p>
    ${terminalTarjetaHTML()}
    <div class="payment-total-box"><span>${escapeHTML(c.etiquetaTotal)}</span><strong>${formatoMonedaCentavos(c.monto)}</strong></div>
    ${c.lineas.length ? `<ul class="mp-resumen">${c.lineas.map(l => `<li><span>${escapeHTML(l.texto)}</span><strong>${formatoMonedaCentavos(l.importe)}</strong></li>`).join("")}</ul>` : ""}
    <div class="payment-actions">
      <button class="btn btn-ghost" id="btnMpVolver" type="button">Volver</button>
      <button class="btn btn-primary" id="btnMpCobrar" type="button">${c.tipo === "orden_web" ? "" : "F3 · "}Cobrar en terminal</button>
    </div>`;
  $("#btnMpVolver").addEventListener("click", () => { soltarCobroTarjeta(); c.volver(); });
  $("#btnMpCobrar").addEventListener("click", iniciarCobroTarjeta);
  renderShortcutsBar();
}

// Estado del cobro: preparando, esperando tarjeta, procesando, aprobado, rechazado, cancelado o error de conexión
function pintarEstadoTarjeta(p){
  const c = cobroTarjeta;
  const vista = p.vista;
  $("#modalPago").classList.toggle("is-cobro-tarjeta", !p.final);
  $("#modalPagoContent").innerHTML = `
    <div class="mp-estado mp-estado--${vista}">
      <div class="mp-visual" aria-hidden="true">
        <span class="mp-onda"></span><span class="mp-onda"></span><span class="mp-onda"></span>
        <span class="mp-visual-fondo"></span><span class="mp-giro"></span>
        ${iconoEstadoTarjeta(vista)}
      </div>
      <div role="status" aria-live="polite">
        <div class="payment-title">${MP_TITULOS[vista] || "Cobro con tarjeta"}</div>
        <p class="payment-subtitle">${escapeHTML(p.mensaje || "")}</p>
      </div>
      ${pasosTarjetaHTML(vista)}
      <div class="payment-total-box"><span>${escapeHTML(c.etiquetaTotal)}</span><strong>${formatoMonedaCentavos(p.importe ?? c.monto)}</strong></div>
      ${p.tarjeta ? `<div class="mp-tarjeta"><span>${escapeHTML(p.tarjeta.metodo)}${p.tarjeta.marca ? ` · ${escapeHTML(p.tarjeta.marca)}` : ""}</span>${p.tarjeta.referencia ? `<span>Operación ${escapeHTML(p.tarjeta.referencia)}</span>` : ""}</div>` : ""}
      ${terminalTarjetaHTML()}
      <div class="payment-actions">${botonesEstadoTarjeta(p)}</div>
    </div>`;

  $("#btnMpCancelar")?.addEventListener("click", cancelarCobroTarjeta);
  $("#btnMpReintentar")?.addEventListener("click", () => { clearTimeout(c.timer); consultarCobroTarjeta(); });
  $("#btnMpOtraVez")?.addEventListener("click", () => { c.pago = null; pintarResumenTarjeta(); });
  $("#btnMpCambiar")?.addEventListener("click", () => { soltarCobroTarjeta(); c.volver(); });
  $("#btnMpCerrar")?.addEventListener("click", () => { soltarCobroTarjeta(); cerrarPago(); });
  $("#btnMpContinuar")?.addEventListener("click", () => c.alAprobar(p));
  renderShortcutsBar();
}

function botonesEstadoTarjeta(p){
  const c = cobroTarjeta;
  switch (p.vista){
    case "esperando":
      return `<button class="btn btn-ghost" id="btnMpCancelar" type="button">Cancelar cobro</button>`;
    case "conexion":
      // La venta sigue en el ticket: se puede reintentar o salir y retomar el cobro después
      return `<button class="btn btn-ghost" id="btnMpCerrar" type="button">Salir sin cancelar</button>
              <button class="btn btn-primary" id="btnMpReintentar" type="button">Reintentar ahora</button>`;
    case "aprobado":
      if (c.tipo !== "enganche") return "";
      return c.alAprobar
        ? `<button class="btn btn-primary" id="btnMpContinuar" type="button">F3 · Continuar al contrato</button>`
        : `<button class="btn btn-primary" id="btnMpCerrar" type="button">Entendido</button>`;
    case "revision":
      return `<button class="btn btn-ghost" id="btnMpCerrar" type="button">Cerrar</button>
              <button class="btn btn-primary" id="btnMpReintentar" type="button">Reintentar registro</button>`;
    case "rechazado":
    case "cancelado":
    case "error":
      return c.retomado
        ? `<button class="btn btn-primary" id="btnMpCerrar" type="button">Cerrar</button>`
        : `<button class="btn btn-ghost" id="btnMpCambiar" type="button">Cambiar método</button>
           <button class="btn btn-primary" id="btnMpOtraVez" type="button">Intentar de nuevo</button>`;
  }
  return "";
}

function terminalTarjetaHTML(){
  return `<div class="mp-terminal"><span class="mp-terminal-punto"></span>Mercado Pago Point · ${escapeHTML(MERCADO_PAGO.terminal || "Terminal")}${MERCADO_PAGO.entorno === "prueba" ? `<em class="mp-modo-prueba">Modo prueba</em>` : ""}</div>`;
}

// Barra de pasos: Preparando → Esperando tarjeta → Procesando → Aprobado (el paso donde se detuvo queda marcado)
function pasosTarjetaHTML(vista){
  const indice = { preparando: 0, conexion: 0, error: 0, esperando: 1, cancelado: 1, procesando: 2, rechazado: 2, aprobado: 3, revision: 3 }[vista] ?? 0;
  const fallo = ["conexion", "error", "cancelado", "rechazado", "revision"].includes(vista);
  return `<ol class="mp-pasos">${MP_PASOS.map((texto, i) => {
    const clase = i < indice || vista === "aprobado" ? "is-hecho" : (i === indice ? (fallo ? "is-fallo" : "is-actual") : "");
    return `<li class="${clase}">${texto}</li>`;
  }).join("")}</ol>`;
}

function iconoEstadoTarjeta(vista){
  const trazo = 'class="mp-icono" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
  if (vista === "aprobado") return `<svg ${trazo}><circle cx="24" cy="24" r="17"/><path class="mp-trazo" d="M16.5 24.5l5 5 10-11"/></svg>`;
  if (vista === "rechazado" || vista === "cancelado") return `<svg ${trazo}><circle cx="24" cy="24" r="17"/><path d="M18.5 18.5l11 11M29.5 18.5l-11 11"/></svg>`;
  if (vista === "error" || vista === "revision") return `<svg ${trazo}><circle cx="24" cy="24" r="17"/><path d="M24 15.5v11M24 32.5h.01"/></svg>`;
  if (vista === "conexion") return `<svg ${trazo}><path d="M9 19a22 22 0 0 1 30 0M14.5 25a14 14 0 0 1 19 0M20 31a6 6 0 0 1 8 0M24 37h.01M10 10l28 28"/></svg>`;
  // Terminal Point
  return `<svg ${trazo}><rect x="13" y="5" width="22" height="38" rx="4"/><rect x="17" y="9.5" width="14" height="10" rx="1.5"/><path d="M18.5 26h.01M24 26h.01M29.5 26h.01M18.5 31h.01M24 31h.01M29.5 31h.01M18.5 36h.01M24 36h.01M29.5 36h.01"/></svg>`;
}

/* ===== 4. Cobro: enviar, consultar y cancelar ===== */

// Clave única del intento de cobro (también evita duplicados si el envío se repite)
function nuevaClaveCobro(){
  const b = crypto.getRandomValues(new Uint8Array(16));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  const h = [...b].map(x => x.toString(16).padStart(2, "0")).join("");
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}

async function iniciarCobroTarjeta(){
  const c = cobroTarjeta;
  if (!c || c.enviando || c.pago) return;
  c.enviando = true;
  const boton = $("#btnMpCobrar");
  if (boton) boton.disabled = true;

  // Gafete del empleado: al aprobarse el pago la operación se registra sola, por eso se valida antes de enviarlo
  let autorizacion = null;
  if (c.autorizacion){
    autorizacion = await solicitarAutorizacionEmpleado(...c.autorizacion);
    if (!autorizacion){
      c.enviando = false;
      if (boton) boton.disabled = false;
      return;
    }
  }

  c.clave = nuevaClaveCobro();
  pintarEstadoTarjeta({ vista: "preparando", final: false, importe: c.monto, mensaje: "Enviando el cobro a la terminal…" });
  try {
    const data = await apiFetch("mp_iniciar_cobro", {
      method: "POST",
      autorizacion,
      body: JSON.stringify({ tipo: c.tipo, clave: c.clave, id_caja: CAJA_ACTUAL_ID, ticket_numero: c.ticket, datos: c.datos() })
    });
    if (cobroTarjeta !== c) return;
    c.enviando = false;
    if (data.retomado) avisar("Esta caja tenía un cobro con tarjeta abierto: se retomó en lugar de enviar otro a la terminal.");
    aplicarEstadoTarjeta(data.pago);
  } catch (error) {
    if (cobroTarjeta !== c) return;
    c.enviando = false;
    if (error instanceof TypeError){
      // No se sabe si el servidor alcanzó a crear el cobro: se pregunta por su clave hasta que responda
      aplicarEstadoTarjeta({ vista: "conexion", final: false, importe: c.monto, mensaje: "Sin conexión con el servidor de la caja. Reintentando…" });
    } else {
      aplicarEstadoTarjeta({ vista: "error", final: true, importe: c.monto, mensaje: error.message });
    }
  }
}

function aplicarEstadoTarjeta(pago){
  const c = cobroTarjeta;
  if (!c) return;
  c.pago = pago;
  pintarEstadoTarjeta(pago);
  if (!pago.final){
    programarConsultaTarjeta(pago.vista === "conexion" ? Math.min(2000 * (c.fallos + 1), 10000) : MP_INTERVALO_CONSULTA);
    return;
  }
  // Breve confirmación y después el mismo ticket que con efectivo
  if (pago.vista === "aprobado" && c.tipo !== "enganche" && c.alAprobar){
    setTimeout(() => { if (cobroTarjeta === c) c.alAprobar(pago); }, 1200);
  }
}

function programarConsultaTarjeta(ms){
  const c = cobroTarjeta;
  if (!c) return;
  clearTimeout(c.timer);
  c.timer = setTimeout(consultarCobroTarjeta, ms);
}

async function consultarCobroTarjeta(){
  const c = cobroTarjeta;
  if (!c || !c.pago) return;
  try {
    const data = await apiFetch("mp_estado_cobro", {
      method: "POST",
      body: JSON.stringify(c.pago.id ? { id_pago: c.pago.id } : { clave: c.clave })
    });
    if (cobroTarjeta !== c) return;
    c.fallos = 0;
    aplicarEstadoTarjeta(data.pago);
  } catch (error) {
    if (cobroTarjeta !== c) return;
    if (error instanceof TypeError){
      c.fallos += 1;
      aplicarEstadoTarjeta({ ...c.pago, vista: "conexion", final: false, mensaje: "Sin conexión con el servidor de la caja. Reintentando…" });
    } else {
      aplicarEstadoTarjeta({ ...c.pago, vista: "error", final: true, mensaje: error.message });
    }
  }
}

async function cancelarCobroTarjeta(){
  const c = cobroTarjeta;
  if (!c?.pago?.id) return;
  const boton = $("#btnMpCancelar");
  if (boton){ boton.disabled = true; boton.textContent = "Cancelando…"; }
  clearTimeout(c.timer);
  try {
    const data = await apiFetch("mp_cancelar_cobro", { method: "POST", body: JSON.stringify({ id_pago: c.pago.id }) });
    if (cobroTarjeta === c) aplicarEstadoTarjeta(data.pago);
  } catch (error) {
    avisar(error.message);
    if (cobroTarjeta === c) programarConsultaTarjeta(MP_INTERVALO_CONSULTA);
  }
}

// Al recargar la página con un cobro abierto: se muestra su estado hasta que termine
function retomarCobroTarjeta(pago){
  pagoEstado = { metodo: "Tarjeta", monto: pago.importe, recibido: 0, cambio: 0, valido: false };
  cobroTarjeta = {
    tipo: pago.tipo, monto: pago.importe, ticket: pago.ticket, retomado: true,
    titulo: "Cobro con tarjeta", etiquetaTotal: "Total del cobro", lineas: [], autorizacion: null, datos: () => ({}),
    volver: cerrarPago,
    alAprobar: pago.tipo === "venta" ? cerrarVentaConTarjeta
      : pago.tipo === "abono" ? (p) => cerrarAbonoConTarjeta(p, null)
      : pago.tipo === "orden_web" ? (p) => cerrarOrdenWebConTarjeta(p, null)
      : null,
    pago: null, clave: pago.clave, timer: null, fallos: 0, enviando: false
  };
  abrirModal("#modalPago");
  // El enganche retomado ya no tiene su formulario: al capturar de nuevo el crédito se usa este pago sin cobrarlo otra vez
  if (pago.tipo === "enganche") pago = { ...pago, mensaje: pago.final ? "Enganche cobrado. Vuelve a capturar el crédito: este pago se usará sin cobrarlo otra vez." : pago.mensaje };
  aplicarEstadoTarjeta(pago);
}

/* ===== 5. Pago aprobado: mismo cierre que con efectivo ===== */

async function cerrarVentaConTarjeta(pago){
  const r = pago.resultado || {};
  ticketCerrado = {
    numero: pago.ticket || ticketNumero,
    ventaId: r.venta_id,
    folio: r.folio,
    fecha: r.fecha,
    cajero: CAJERO_ACTUAL,
    sucursal: SUCURSAL_ACTUAL,
    sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION,
    sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
    caja: CAJA_ACTUAL,
    metodo: pago.tarjeta?.metodo || "Tarjeta",
    subtotal: r.total,
    total: r.total,
    recibido: r.total,
    cambio: 0,
    tarjeta: pago.tarjeta,
    // Si se retomó tras recargar la página, los renglones vienen del servidor
    items: ticketItems.length ? [...ticketItems] : (r.lineas || []).map(l => ({ articulo: `${l.cantidad}× ${l.descripcion}`, precioTotal: l.subtotal, cantidad: l.cantidad }))
  };
  // Folios de servicios y trámites para el ticket (conceptos_caja.js los agrega al mostrarlo)
  if (Array.isArray(r.conceptos) && r.conceptos.length) foliosConceptosVenta = r.conceptos;
  cerrarPago();
  ticketItems = [];
  modoEliminarTicket = false;
  ticketNumero += 1;
  try { await refrescarDatosDB(); } catch (_) { /* la venta ya quedó registrada */ }
  renderPanelLateral();
  renderShortcutsBar();
  mostrarTicketCliente();
}

async function cerrarAbonoConTarjeta(pago, item){
  const data = pago.resultado || {};
  const it = item || ticketItems.find(x => x.esAbono) || { esAbono: true, cliente: "", abonosTotales: data.plazo };
  ticketCerrado = {
    numero: pago.ticket || ticketNumero, ventaId: null, folio: data.folio, fecha: data.fecha,
    cajero: CAJERO_ACTUAL, sucursal: SUCURSAL_ACTUAL, sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION, sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
    caja: CAJA_ACTUAL, metodo: data.metodo, subtotal: data.importe, total: data.importe, recibido: data.recibido, cambio: data.cambio,
    tarjeta: pago.tarjeta,
    items: [{ ...it, precioTotal: data.importe, numeroAbono: data.numero, saldoAnterior: data.saldo_anterior, saldoRestante: data.saldo_restante }],
    abono: {
      contratoFolio: data.contrato, numero: data.numero, plazo: data.plazo, importe: data.importe, vence: it.vence,
      saldoAnterior: data.saldo_anterior, saldoRestante: data.saldo_restante, liquidado: data.liquidado,
      vehiculo: it.vehiculo, vin: it.vin, rfcIne: it.rfcIne, direccion: it.direccion,
      identificacionTipo: it.identificacionTipo, celular: it.celular
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
}

async function cerrarOrdenWebConTarjeta(pago, orden){
  const data = pago.resultado || {};
  ticketCerrado = {
    numero: pago.ticket || ticketNumero, ventaId: data.venta_id, folio: data.folio, fecha: data.fecha,
    cajero: CAJERO_ACTUAL, sucursal: SUCURSAL_ACTUAL, sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION, sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
    caja: CAJA_ACTUAL, metodo: pago.tarjeta?.metodo || "Tarjeta", subtotal: data.total, total: data.total, recibido: data.total, cambio: 0,
    tarjeta: pago.tarjeta,
    items: (data.lineas || []).map(l => ({
      articulo: `${l.cantidad}× ${l.descripcion}`, precioTotal: l.subtotal, cantidad: l.cantidad,
      cliente: orden?.nombre || "", email: orden?.email || "", celular: orden?.celular || ""
    }))
  };
  pagoOrdenWeb = null;
  cerrarPago();
  ticketNumero += 1;
  try { await refrescarDatosDB(); } catch (_) { /* el pedido ya quedó cobrado */ }
  if (currentView === "weborders") renderWebOrders();
  mostrarTicketCliente();
}

// Enganche aprobado: sigue el flujo normal del crédito (gafete → contrato → firma) con este pago como cobro del enganche
function continuarCreditoConTarjeta(pago, itemCredito){
  if (!itemCredito) return;
  pagoEstado = { metodo: "Tarjeta", monto: pago.importe, recibido: pago.importe, cambio: 0, valido: true, idPagoMp: pago.id, tarjeta: pago.tarjeta };
  iniciarContratoCredito(itemCredito, $("#btnMpContinuar"));
}
