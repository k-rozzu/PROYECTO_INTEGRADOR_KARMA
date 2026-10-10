/* ===== KARMA · Punto de Venta — Contrato de crédito automotriz (vista previa, firma con touchpad y concretar) =====
   Flujo: cobro del enganche (o $0 sin método de pago) → código de empleado → preparar_credito (contrato en pantalla)
   → el cliente firma con el touchpad → «Aceptar» → concretar_credito (venta, cliente y PDF definitivo en una transacción)
   → ticket con «Ver contrato» y «Enviar». Si el cliente no firma, el crédito no se registra.
   Usa $, $$, escapeHTML, apiFetch, avisar, formatoMonedaCentavos, solicitarAutorizacionEmpleado… de script.js y
   autorizacion_empleado.js (se cargan antes que este archivo). */

let contratoEnCurso = null;   // contrato preparado esperando firma: { id, folio, token, resumen, html, pago, items, ticketNumero, enviando }
let firmaPad = null;          // estado del lienzo de firma mientras el contrato está en pantalla

// Lienzo lógico en el que viaja la firma al servidor (el PDF la dibuja con la misma proporción)
const FIRMA_EXPORT = { ancho: 600, alto: 200, x0: 24, x1: 576, y0: 18, y1: 182 };

/* ----- 1. Verificación del empleado y contrato preparado en el servidor ----- */

// Se llama desde confirmarVentaDB() cuando el ticket trae un crédito (el enganche ya se cobró o es de $0)
async function iniciarContratoCredito(itemCredito, boton){
  const pago = { ...pagoEstado };
  const sinCobro = pago.metodo === "Sin cobro";
  // Misma verificación de la venta: gafete QR o código del empleado de la sesión
  const autorizacion = await solicitarAutorizacionEmpleado("CREDITO", ticketNumero, "Concretar crédito");
  if (!autorizacion){
    if (boton) boton.disabled = false;
    if (sinCobro) cerrarPago();   // sin ventana de pago abierta: solo se libera el estado del cobro
    return;
  }

  try {
    const data = await apiFetch("preparar_credito", {
      method: "POST",
      autorizacion,
      body: JSON.stringify({
        id_caja: CAJA_ACTUAL_ID,
        ticket_numero: ticketNumero,
        metodo_pago: sinCobro ? "Sin cobro" : "Efectivo",
        efectivo_recibido: sinCobro ? 0 : pago.recibido,
        cambio: sinCobro ? 0 : pago.cambio,
        ordenes_web: ticketItems.map(it => it.webOrderId).filter(Boolean),
        items: ticketItems.map(it => ({
          producto_id: it.productoId,
          cantidad: it.cantidad || 1,
          es_credito: !!it.esCredito,
          vin: it.vin || "",
          motor_serie: it.motorTipo || "",
          color_interior: it.colorInterior || ""
        })),
        cliente: {
          nombre: itemCredito.cliente, rfc_curp: itemCredito.rfcIne, email: itemCredito.email, celular: itemCredito.celular,
          direccion: itemCredito.direccion, identificacion_tipo: itemCredito.identificacionTipo, identificacion_numero: itemCredito.identificacionNumero
        },
        credito: {
          producto_id: itemCredito.productoId, enganche_tipo: itemCredito.engancheTipo, enganche_valor: itemCredito.engancheValor,
          plazo_meses: itemCredito.plazoMeses, tasa_anual: itemCredito.tasaAnual,
          // Lo que vio el cliente: el servidor recalcula y rechaza si no coincide
          esperado: { enganche: itemCredito.enganche, mensualidad: itemCredito.montoAbono }
        }
      })
    });

    contratoEnCurso = {
      id: data.id_contrato, folio: data.folio, token: data.token, resumen: data.resumen, html: data.html,
      pago, items: [...ticketItems], ticketNumero, enviando: false
    };
    cerrarPago();
    abrirContratoCredito();
  } catch (error) {
    if (boton) boton.disabled = false;
    if (sinCobro) cerrarPago();
    avisar(error.message);
  }
}

/* ----- 2. Pantalla del contrato (vista previa + firma) ----- */

function abrirContratoCredito(){
  const k = contratoEnCurso;
  const r = k.resumen;
  const fila = (etq, valor) => `<div class="contrato-dato"><span>${etq}</span><strong>${valor}</strong></div>`;

  $("#contratoOverlayContent").innerHTML = `
    <header class="contrato-header">
      <div>
        <p class="eyebrow-plain">Crédito automotriz · firma del contrato</p>
        <h2>Contrato ${escapeHTML(k.folio)}</h2>
        <p class="contrato-sub">Revisa el contrato con el cliente. El crédito se concreta solo cuando el cliente firma y pulsa «Aceptar».</p>
      </div>
      <button class="btn btn-ghost" id="btnCancelarContrato" type="button">Cancelar operación</button>
    </header>
    <div class="contrato-cuerpo">
      <div class="contrato-documento">
        <iframe id="contratoVistaPrevia" title="Vista previa del contrato ${escapeHTML(k.folio)}" sandbox></iframe>
      </div>
      <aside class="contrato-lateral">
        <div class="contrato-resumen">
          ${fila("Acreditado", escapeHTML(r.cliente))}
          ${fila("Vehículo", `${escapeHTML(r.vehiculo)}<br><small translate="no">VIN ${escapeHTML(r.vin)}</small>`)}
          ${fila("Precio de contado", formatoMonedaCentavos(r.precio))}
          ${fila(r.importe > 0 ? "Cobrado hoy" : "Enganche", r.importe > 0 ? `${formatoMonedaCentavos(r.importe)} <small>(${escapeHTML(r.metodo)})</small>` : `${formatoMonedaCentavos(0)} <small>(sin cobro)</small>`)}
          ${fila("Saldo a financiar", formatoMonedaCentavos(r.saldo))}
          ${fila("Mensualidades", `${r.plazo} de ${formatoMonedaCentavos(r.mensualidad)}`)}
          ${fila("Tasa / CAT", `${r.tasa}% fija · CAT ${r.cat != null ? Number(r.cat).toFixed(1) + "%" : "no aplica"} sin IVA`)}
          ${fila("Representante", escapeHTML(r.representante))}
        </div>

        <div class="firma-bloque">
          <div class="firma-titulo">Firma del acreditado</div>
          <div class="firma-zona" id="firmaZona" aria-label="Área de firma: mantén presionado el botón derecho del touchpad y mueve el cursor">
            <canvas id="firmaLienzo"></canvas>
            <span class="firma-x" aria-hidden="true">X</span>
            <div class="firma-linea" aria-hidden="true"></div>
            <div class="firma-nombre">${escapeHTML(r.cliente)}</div>
            <div class="firma-ayuda" id="firmaAyuda">Mantén presionado el <strong>botón derecho</strong> del touchpad y mueve el cursor para firmar. No necesitas apuntar a la línea: la firma se acomoda sola.</div>
          </div>
          <div class="firma-acciones" id="firmaAcciones" hidden>
            <button class="btn btn-ghost" id="btnFirmaReintentar" type="button">Volver a intentar</button>
            <button class="btn btn-primary" id="btnFirmaAceptar" type="button">Aceptar</button>
          </div>
          <div class="cash-message firma-mensaje" id="firmaMensaje" role="status"></div>
          <p class="firma-legal">Al pulsar «Aceptar», el cliente manifiesta que leyó y acepta el contrato: se genera el PDF definitivo con su firma y el crédito queda concretado.</p>
        </div>
      </aside>
    </div>
  `;
  // El HTML del contrato lo genera el servidor (mismo documento que el PDF); se muestra aislado y sin scripts
  $("#contratoVistaPrevia").srcdoc = k.html;
  $("#contratoOverlay").classList.add("is-open");
  $("#contratoOverlay").scrollTop = 0;

  $("#btnCancelarContrato").addEventListener("click", cancelarContratoCredito);
  $("#btnFirmaReintentar").addEventListener("click", reiniciarFirma);
  $("#btnFirmaAceptar").addEventListener("click", aceptarFirmaContrato);
  window.addEventListener("keydown", teclasContrato, true);
  iniciarFirmaPad();
}

// Mientras el contrato está abierto: Esc no cierra nada por accidente y los atajos F3–F6 no actúan detrás
function teclasContrato(e){
  if (!contratoEnCurso) return;
  if (e.key === "Escape" || ["F3", "F4", "F5", "F6"].includes(e.key)){
    e.preventDefault();
    e.stopImmediatePropagation();
  }
}

function cerrarContratoCredito(){
  window.removeEventListener("keydown", teclasContrato, true);
  detenerFirmaPad();
  contratoEnCurso = null;
  $("#contratoOverlay").classList.remove("is-open");
  $("#contratoOverlayContent").innerHTML = "";
}

// El cliente no firma: el contrato queda cancelado en el servidor y no se registra venta ni crédito
async function cancelarContratoCredito(){
  const k = contratoEnCurso;
  if (!k || k.enviando) return;
  const r = k.resumen;
  const aviso = r.importe > 0
    ? `¿Cancelar la operación? El crédito NO se registrará y debes devolver al cliente lo cobrado (${formatoMonedaCentavos(r.importe)}).`
    : "¿Cancelar la operación? El crédito no se registrará.";
  if (!confirm(aviso)) return;
  try {
    await apiFetch("cancelar_credito", { method: "POST", body: JSON.stringify({ id_contrato: k.id }) });
  } catch (error) {
    avisar(error.message);
  }
  cerrarContratoCredito();
  renderPanelLateral();
  renderShortcutsBar();
}

/* ----- 3. Firma con el touchpad (botón derecho presionado + mover el cursor) ----- */

function iniciarFirmaPad(){
  const zona = $("#firmaZona");
  const lienzo = $("#firmaLienzo");
  firmaPad = {
    zona, lienzo, ctx: lienzo.getContext("2d"), dpr: 1, ancho: 0, alto: 0,
    trazos: [], actual: null, pointerId: null, esRaton: false, vista: null, bloqueoMenuHasta: 0, bloqueada: false
  };
  ajustarLienzoFirma();
  zona.addEventListener("pointerdown", firmaInicio);
  zona.addEventListener("pointermove", firmaMovimiento);
  zona.addEventListener("pointerup", firmaFin);
  zona.addEventListener("pointercancel", firmaFin);
  zona.addEventListener("lostpointercapture", firmaFin);
  // El menú contextual del botón derecho se bloquea SOLO dentro del área de firma (y justo al soltar un trazo)
  zona.addEventListener("contextmenu", (e) => e.preventDefault());
  document.addEventListener("contextmenu", bloquearMenuFirma, true);
  window.addEventListener("resize", ajustarLienzoFirma);
}

function detenerFirmaPad(){
  document.removeEventListener("contextmenu", bloquearMenuFirma, true);
  window.removeEventListener("resize", ajustarLienzoFirma);
  firmaPad = null;
}

// Windows abre el menú contextual al SOLTAR el botón derecho, a veces fuera del área: se evita solo en ese instante
function bloquearMenuFirma(e){
  const p = firmaPad;
  if (!p) return;
  if (p.pointerId !== null || Date.now() < p.bloqueoMenuHasta || p.zona.contains(e.target)) e.preventDefault();
}

// Lienzo nítido en pantallas de alta densidad; si cambia el tamaño, la firma se vuelve a acomodar
function ajustarLienzoFirma(){
  const p = firmaPad;
  if (!p) return;
  const caja = p.zona.getBoundingClientRect();
  p.dpr = window.devicePixelRatio || 1;
  p.ancho = Math.max(caja.width, 1);
  p.alto = Math.max(caja.height, 1);
  p.lienzo.width = Math.round(p.ancho * p.dpr);
  p.lienzo.height = Math.round(p.alto * p.dpr);
  if (p.trazos.length && p.pointerId === null) acomodarFirma();
  dibujarFirma();
}

// Zona útil del lienzo (la línea de firma está al 74 % de la altura, igual que en el CSS)
function areaFirma(){
  const p = firmaPad;
  return { x0: p.ancho * 0.05, x1: p.ancho * 0.95, y0: p.alto * 0.08, y1: p.alto * 0.8, linea: p.alto * 0.74 };
}

function firmaInicio(e){
  const p = firmaPad;
  if (!p || p.bloqueada || p.pointerId !== null) return;
  const esRaton = e.pointerType === "mouse";
  // Con touchpad o mouse se firma con el botón DERECHO presionado; con pluma o pantalla táctil, tocando
  if (esRaton && e.button !== 2){ recordarComoFirmar(); return; }
  if (!esRaton && e.button !== 0) return;
  e.preventDefault();
  p.pointerId = e.pointerId;
  p.esRaton = esRaton;
  try { p.zona.setPointerCapture(e.pointerId); } catch (_) {}
  // El primer trazo empieza sobre la línea aunque el cursor esté en otro lado del área: la posición se ajusta sola
  if (!p.vista){
    const a = areaFirma();
    p.vista = { rx: e.clientX, ry: e.clientY, s: 1, cx: a.x0 + (a.x1 - a.x0) * 0.12, cy: a.linea - (a.y1 - a.y0) * 0.3 };
  }
  p.actual = [{ x: e.clientX, y: e.clientY }];
  p.trazos.push(p.actual);
  p.zona.classList.add("is-firmando");
  $("#firmaAcciones").hidden = true;
  $("#firmaAyuda").hidden = true;
  mensajeFirma("");
  dibujarFirma();
}

function firmaMovimiento(e){
  const p = firmaPad;
  if (!p || e.pointerId !== p.pointerId || !p.actual) return;
  // Si el botón derecho ya no está presionado (se soltó fuera de la ventana), el trazo termina
  if (p.esRaton && !(e.buttons & 2)){ firmaFin(e); return; }
  const eventos = typeof e.getCoalescedEvents === "function" ? e.getCoalescedEvents() : [];
  for (const ev of (eventos.length ? eventos : [e])) p.actual.push({ x: ev.clientX, y: ev.clientY });
  if (p.trazos.reduce((n, t) => n + t.length, 0) > 5000){ firmaFin(e); return; }
  ajustarVistaSiDesborda();
  dibujarFirma();
}

function firmaFin(e){
  const p = firmaPad;
  if (!p || p.pointerId === null || (e && e.pointerId !== undefined && e.pointerId !== p.pointerId)) return;
  const id = p.pointerId;
  p.pointerId = null;
  p.actual = null;
  p.bloqueoMenuHasta = Date.now() + 700;
  try { p.zona.releasePointerCapture(id); } catch (_) {}
  p.zona.classList.remove("is-firmando");
  // Auto-ajuste: la firma completa se centra y escala dentro del área, sobre la línea
  acomodarFirma();
  dibujarFirma();
  // Al terminar el trazo aparecen «Volver a intentar» y «Aceptar»
  $("#firmaAcciones").hidden = !p.trazos.length;
}

function recordarComoFirmar(){
  const ayuda = $("#firmaAyuda");
  if (!ayuda) return;
  ayuda.hidden = false;
  ayuda.classList.remove("is-aviso");
  void ayuda.offsetWidth;
  ayuda.classList.add("is-aviso");
}

// Rectángulo que ocupan todos los puntos capturados (en coordenadas de pantalla)
function limitesFirma(){
  const pts = firmaPad.trazos.flat();
  if (!pts.length) return null;
  const xs = pts.map(q => q.x), ys = pts.map(q => q.y);
  return { minX: Math.min(...xs), maxX: Math.max(...xs), minY: Math.min(...ys), maxY: Math.max(...ys) };
}

// Centra la firma en el área y la escala para llenarla (crece hasta 2.2× si se firmó pequeño)
function acomodarFirma(){
  const p = firmaPad;
  const l = limitesFirma();
  if (!l) return;
  const a = areaFirma();
  const s = Math.min((a.x1 - a.x0) / Math.max(l.maxX - l.minX, 1), (a.y1 - a.y0) / Math.max(l.maxY - l.minY, 1), 2.2);
  p.vista = { rx: (l.minX + l.maxX) / 2, ry: (l.minY + l.maxY) / 2, s, cx: (a.x0 + a.x1) / 2, cy: (a.y0 + a.y1) / 2 };
}

// Mientras se dibuja, si la firma se sale del área se reduce y centra (sin agrandarla) para que siempre quepa
function ajustarVistaSiDesborda(){
  const p = firmaPad;
  const l = limitesFirma();
  const a = areaFirma();
  const v = p.vista;
  const x0 = (l.minX - v.rx) * v.s + v.cx, x1 = (l.maxX - v.rx) * v.s + v.cx;
  const y0 = (l.minY - v.ry) * v.s + v.cy, y1 = (l.maxY - v.ry) * v.s + v.cy;
  if (x0 >= a.x0 - 1 && x1 <= a.x1 + 1 && y0 >= a.y0 - 1 && y1 <= a.y1 + 1) return;
  const s = Math.min(v.s, (a.x1 - a.x0) / Math.max(l.maxX - l.minX, 1), (a.y1 - a.y0) / Math.max(l.maxY - l.minY, 1));
  p.vista = { rx: (l.minX + l.maxX) / 2, ry: (l.minY + l.maxY) / 2, s, cx: (a.x0 + a.x1) / 2, cy: (a.y0 + a.y1) / 2 };
}

// Dibuja los trazos con curvas suaves por los puntos medios (el servidor usa el mismo suavizado en el PDF)
function dibujarFirma(){
  const p = firmaPad;
  if (!p) return;
  const ctx = p.ctx;
  ctx.setTransform(p.dpr, 0, 0, p.dpr, 0, 0);
  ctx.clearRect(0, 0, p.ancho, p.alto);
  if (!p.vista) return;
  const v = p.vista;
  const aLienzo = (q) => ({ x: (q.x - v.rx) * v.s + v.cx, y: (q.y - v.ry) * v.s + v.cy });
  ctx.strokeStyle = ctx.fillStyle = "#0D1B3E";
  ctx.lineWidth = 2.6;
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  for (const trazo of p.trazos){
    const pts = trazo.map(aLienzo);
    if (pts.length === 1){
      ctx.beginPath();
      ctx.arc(pts[0].x, pts[0].y, 1.6, 0, Math.PI * 2);
      ctx.fill();
      continue;
    }
    ctx.beginPath();
    ctx.moveTo(pts[0].x, pts[0].y);
    for (let i = 1; i < pts.length - 1; i++){
      ctx.quadraticCurveTo(pts[i].x, pts[i].y, (pts[i].x + pts[i + 1].x) / 2, (pts[i].y + pts[i + 1].y) / 2);
    }
    ctx.lineTo(pts[pts.length - 1].x, pts[pts.length - 1].y);
    ctx.stroke();
  }
}

// «Volver a intentar»: borra el trazo para una firma nueva
function reiniciarFirma(){
  const p = firmaPad;
  if (!p || p.bloqueada) return;
  p.trazos = [];
  p.actual = null;
  p.vista = null;
  dibujarFirma();
  $("#firmaAcciones").hidden = true;
  $("#firmaAyuda").hidden = false;
  mensajeFirma("");
}

// Firma acomodada en el lienzo lógico de 600 x 200 (solo números; el servidor arma el SVG y lo coloca en el PDF)
function exportarFirma(){
  const l = limitesFirma();
  if (!l) return [];
  const E = FIRMA_EXPORT;
  const s = Math.min((E.x1 - E.x0) / Math.max(l.maxX - l.minX, 1), (E.y1 - E.y0) / Math.max(l.maxY - l.minY, 1), 4);
  const mx = (l.minX + l.maxX) / 2, my = (l.minY + l.maxY) / 2;
  const redondear = (n) => Math.round(n * 10) / 10;
  return firmaPad.trazos.map(trazo => {
    const salida = [];
    for (const q of trazo){
      const punto = [redondear((q.x - mx) * s + E.ancho / 2), redondear((q.y - my) * s + E.alto / 2)];
      const previo = salida[salida.length - 1];
      if (!previo || Math.hypot(punto[0] - previo[0], punto[1] - previo[1]) >= 1.2) salida.push(punto);
    }
    return salida;
  }).filter(t => t.length);
}

function mensajeFirma(texto, tipo){
  const msg = $("#firmaMensaje");
  if (!msg) return;
  msg.textContent = texto;
  msg.classList.toggle("is-error", tipo === "error");
  msg.classList.toggle("is-ok", tipo === "ok");
}

/* ----- 4. «Aceptar»: PDF definitivo + crédito concretado ----- */

async function aceptarFirmaContrato(){
  const k = contratoEnCurso;
  const p = firmaPad;
  if (!k || !p || k.enviando || p.pointerId !== null) return;
  const trazos = exportarFirma();
  if (!trazos.length){ mensajeFirma("Pide al cliente que firme en el recuadro.", "error"); return; }

  k.enviando = true;
  p.bloqueada = true;
  ["#btnFirmaAceptar", "#btnFirmaReintentar", "#btnCancelarContrato"].forEach(sel => { const b = $(sel); if (b) b.disabled = true; });
  $("#btnFirmaAceptar").textContent = "Concretando…";
  mensajeFirma("Generando el PDF definitivo y registrando el crédito…");

  try {
    const data = await apiFetch("concretar_credito", {
      method: "POST",
      body: JSON.stringify({ id_contrato: k.id, token: k.token, trazos })
    });
    const r = k.resumen;
    // Ticket digital igual al de una venta, con los datos del crédito y su contrato
    ticketCerrado = {
      numero: k.ticketNumero,
      ventaId: data.venta_id,
      folio: data.folio,
      fecha: data.fecha,
      cajero: r.representante || CAJERO_ACTUAL,
      sucursal: SUCURSAL_ACTUAL,
      sucursalDireccion: SUCURSAL_ACTUAL_DIRECCION,
      sucursalTelefono: SUCURSAL_ACTUAL_TELEFONO,
      caja: CAJA_ACTUAL,
      metodo: data.metodo,
      subtotal: data.total,
      total: data.total,
      recibido: data.recibido,
      cambio: data.cambio,
      items: k.items,
      contrato: { id: data.contrato.id, folio: data.contrato.folio, resumen: `${r.plazo} mensualidades de ${formatoMonedaCentavos(r.mensualidad)}` }
    };

    cerrarContratoCredito();
    ticketItems = [];
    modoEliminarTicket = false;
    ticketNumero += 1;
    try { await refrescarDatosDB(); } catch (_) { /* el crédito ya quedó registrado; los catálogos se refrescan después */ }
    renderPanelVenta();
    renderPanelLateral();
    renderShortcutsBar();
    mostrarTicketCliente();
  } catch (error) {
    k.enviando = false;
    p.bloqueada = false;
    ["#btnFirmaAceptar", "#btnFirmaReintentar", "#btnCancelarContrato"].forEach(sel => { const b = $(sel); if (b) b.disabled = false; });
    $("#btnFirmaAceptar").textContent = "Aceptar";
    mensajeFirma(error.message, "error");
  }
}

/* ----- 5. Visor del PDF guardado (ticket y sección Clientes) ----- */

function abrirVisorContrato(id, folio){
  if (!id) return;
  const url = `api.php?action=ver_contrato&id=${encodeURIComponent(id)}`;
  $("#visorContratoContent").innerHTML = `
    <div class="visor-header">
      <div>
        <p class="eyebrow-plain">Contrato de crédito firmado</p>
        <h3 class="modal-title">${escapeHTML(folio || "")}</h3>
      </div>
      <div class="visor-acciones">
        <a class="btn btn-ghost" href="${url}" target="_blank" rel="noopener">Abrir en pestaña nueva</a>
        <a class="btn btn-ghost" href="${url}&descargar=1">Descargar PDF</a>
        <button class="btn btn-primary" id="btnCerrarVisor" type="button">Cerrar</button>
      </div>
    </div>
    <iframe class="visor-pdf" src="${url}" title="Contrato ${escapeHTML(folio || "")}"></iframe>
  `;
  $("#visorContrato").classList.add("is-open");
  $("#btnCerrarVisor").addEventListener("click", cerrarVisorContrato);
}

// Solo cierra el visor: el ticket o el detalle del cliente que estaban detrás siguen abiertos
function cerrarVisorContrato(){
  $("#visorContrato").classList.remove("is-open");
  $("#visorContratoContent").innerHTML = "";
}

$("#visorContrato")?.addEventListener("click", (e) => { if (e.target === e.currentTarget) cerrarVisorContrato(); });
window.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && $("#visorContrato")?.classList.contains("is-open")){
    e.preventDefault();
    e.stopImmediatePropagation();
    cerrarVisorContrato();
  }
}, true);
