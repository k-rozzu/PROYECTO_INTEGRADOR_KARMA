/* ===== KARMA · Punto de Venta — Conceptos de caja (seguros, financiamiento, trámites, impuestos y posventa) =====
   Agrega la pestaña «Servicios» al formulario de Venta (junto a Vehículo / Crédito / Refacción) para capturar y cobrar:
   seguro de cobertura amplia, co seguro de vida y desempleo, seguro de llantas y rines, comisión por apertura, gestoría
   de placas, ISAN, tenencia / refrendo, holograma 00, mantenimiento prepagado, garantía extendida, película de
   seguridad / polarizado y órdenes de servicio de taller (los accesorios originales se venden en el Catálogo).
   Flujo: el cajero elige el concepto → captura vehículo / crédito / plan / datos → el servidor calcula (calcular_concepto)
   → «Guardar» lo agrega al ticket → F3 cobra todo en la MISMA venta (crear_venta, con el gafete de VENTA) → el servidor
   recalcula, guarda el desglose (ventas_conceptos) y devuelve los folios que se muestran en el ticket.
   Igual que contrato_credito.js y autorizacion_empleado.js, usa el estado y los helpers de script.js ($, $$, escapeHTML,
   apiFetch, avisar, borrador, ticketItems…). Se engancha envolviendo algunas de sus funciones (decoradores al final del
   archivo), de modo que script.js no se modifica y las demás pestañas funcionan exactamente igual. */

const TIPO_FORM_CONCEPTOS = "Servicios";              // valor de data-form-tipo de la pestaña nueva
const ESPERA_CALCULO_CONCEPTO = 350;                   // ms sin teclear antes de pedir el cálculo al servidor
const ETIQUETAS_ORIGEN_VEHICULO = { ticket: "Del ticket", vendido: "Vendido por KARMA", externo: "Externo" };
const ETIQUETAS_ORIGEN_CREDITO = { karma: "Contrato KARMA", externo: "Financiera externa" };

let CONCEPTOS_CAJA = { disponible: false, conceptos: [], vehiculosVendidos: [] };
let conceptoCalculo = null;          // último cálculo válido del servidor para lo capturado
let conceptoMensaje = "";            // lo que falta capturar o el motivo por el que no se puede cobrar
let conceptoClaveCalculo = "";       // datos con los que se hizo el último cálculo (evita peticiones repetidas)
let conceptoTemporizador = null;
let conceptoPeticion = 0;            // descarta respuestas que llegan tarde
let foliosConceptosVenta = null;     // folios que devolvió crear_venta para el ticket recién cobrado

/* ----- 1. Datos de apoyo ----- */

// Concepto elegido en el formulario
function conceptoActual(){
  return CONCEPTOS_CAJA.conceptos.find(c => c.id === Number(borrador.conceptoId)) || null;
}

// Vehículos de contado que ya están en el ticket (referencia para ISAN, placas, seguros…)
function vehiculosDelTicket(){
  return ticketItems.filter(it => it.esVehiculo && !it.esCredito && it.vin);
}

// Unidades vendidas por KARMA que admite el concepto (por tipo de vehículo)
function vehiculosVendidosConcepto(c){
  return CONCEPTOS_CAJA.vehiculosVendidos.filter(v => c.aplicaTipos.includes(v.tipo));
}

// Créditos KARMA activos (sección Clientes)
function creditosKarmaActivos(){
  return CLIENTES.filter(k => k.contratoFolio);
}

// Tipo (auto/moto) del vehículo de referencia capturado
function tipoVehiculoConcepto(){
  const b = borrador;
  if (b.vehOrigen === "ticket"){
    const it = ticketItems.find(x => x.id === Number(b.vehTicketId));
    return it ? (INVENTARIO.find(c => c.id === it.productoId)?.tipo || null) : null;
  }
  if (b.vehOrigen === "vendido") return CONCEPTOS_CAJA.vehiculosVendidos.find(v => v.idDetalle === Number(b.vehDetalleId))?.tipo || null;
  if (b.vehOrigen === "externo") return b.vehTipo || null;
  return null;
}

// Planes que aplican al vehículo elegido
function opcionesConcepto(c){
  const tipo = tipoVehiculoConcepto();
  return c.opciones.filter(o => o.tipoVehiculo === "todos" || o.tipoVehiculo === tipo);
}

// Origen de vehículo con que arranca el concepto: el ticket si ahí hay una unidad, si no el primero permitido
function origenVehiculoInicial(c){
  if (!c.origenesVehiculo.length) return "";
  if (c.origenesVehiculo.includes("ticket") && vehiculosDelTicket().length) return "ticket";
  return c.origenesVehiculo.find(o => o !== "ticket") || c.origenesVehiculo[0];
}

// Datos que viajan al servidor (solo QUÉ se cobra; el importe lo calcula conceptos_caja.php)
function payloadConcepto(){
  const b = borrador;
  const c = conceptoActual();
  if (!c) return null;
  let vehiculo = null;
  if (c.origenesVehiculo.length && b.vehOrigen){
    if (b.vehOrigen === "ticket"){
      const it = ticketItems.find(x => x.id === Number(b.vehTicketId));
      vehiculo = { origen: "ticket", producto_id: it?.productoId || 0, vin: it?.vin || "" };
    } else if (b.vehOrigen === "vendido"){
      vehiculo = { origen: "vendido", id_detalle: Number(b.vehDetalleId) || 0 };
    } else {
      vehiculo = { origen: "externo", vin: b.vehVin || "", tipo: b.vehTipo || "", marca: b.vehMarca || "", modelo: b.vehModelo || "", anio: b.vehAnio || "", valor: b.vehValor || "" };
    }
  }
  let credito = null;
  if (c.origenesCredito.length && b.credOrigen){
    credito = b.credOrigen === "karma"
      ? { origen: "karma", folio: b.credFolio || "" }
      : { origen: "externo", institucion: b.credInstitucion || "", monto: b.credMonto || "", plazo: b.credPlazo || "" };
  }
  return {
    id_concepto: c.id,
    id_opcion: Number(b.opcionId) || 0,
    vehiculo, credito,
    campos: { ...(b.campos || {}) }
  };
}

/* ----- 2. Formulario de la pestaña «Servicios» ----- */

// Botón de la pestaña (se agrega al segmentado de Vehículo / Crédito / Refacción)
function botonTipoConceptosHTML(){
  return `<button type="button" class="segmented-btn ${formTipoArticulo === TIPO_FORM_CONCEPTOS ? "is-active" : ""}" data-form-tipo="${TIPO_FORM_CONCEPTOS}">Servicios</button>`;
}

// Formulario completo cuando la pestaña activa es «Servicios» (misma estructura que formularioVentaHTML de script.js)
function formularioConceptosHTML(){
  const b = borrador;
  return `
    <div class="panel-heading"><h2>${modoCotizacion ? "Cotización" : "Registrar venta"}</h2></div>

    ${modoCotizacion ? `<div class="cotizacion-banner"><span>Modo cotización — esta venta no se guardará en el ticket</span></div>` : ""}
    ${b.articuloRef ? `<div class="hint-banner">Interés registrado en la web: <strong>${escapeHTML(b.articuloRef)}</strong></div>` : ""}

    <div class="segmented tipo-articulo-toggle">
      <button type="button" class="segmented-btn" data-form-tipo="Vehiculo">Vehículo</button>
      <button type="button" class="segmented-btn" data-form-tipo="Credito">Crédito</button>
      <button type="button" class="segmented-btn" data-form-tipo="Refaccion">Refacción</button>
      ${botonTipoConceptosHTML()}
    </div>

    ${camposConceptosHTML()}

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

// Cliente + concepto + vehículo / crédito + plan + campos propios + resultado del cálculo
function camposConceptosHTML(){
  const b = borrador;
  if (!CONCEPTOS_CAJA.disponible){
    return `<div class="form-grid"><div class="form-field span-2"><div class="form-field-info form-field-info--error">${escapeHTML(CONCEPTOS_CAJA.aviso || "Los conceptos de caja no están disponibles.")}</div></div></div>`;
  }
  const c = conceptoActual();
  const primerCliente = ticketItems[0] || {};
  const valor = (k, defecto = "") => escapeHTML(b[k] ?? defecto);

  // Selector agrupado por familia (Seguros, Financiamiento, Trámites e impuestos, Posventa y taller)
  const grupos = [...new Set(CONCEPTOS_CAJA.conceptos.map(x => x.grupo))];
  const selectorConcepto = grupos.map(g => `
    <optgroup label="${escapeHTML(g)}">
      ${CONCEPTOS_CAJA.conceptos.filter(x => x.grupo === g).map(x => `<option value="${x.id}" ${c && c.id === x.id ? "selected" : ""}>${escapeHTML(x.nombre)}</option>`).join("")}
    </optgroup>`).join("");

  return `
    <div class="form-grid">
      <div class="form-field"><label>Cliente</label><input type="text" id="inpClienteS" value="${valor("cliente", primerCliente.cliente || "")}" placeholder="Nombre completo"></div>
      <div class="form-field"><label>RFC / INE</label><input type="text" id="inpRfcIneS" value="${valor("rfcIne", primerCliente.rfcIne || "")}" placeholder="Identificación"></div>
      <div class="form-field"><label>Email</label><input type="email" id="inpEmailS" value="${valor("email", primerCliente.email || "")}" placeholder="correo@ejemplo.com"></div>
      <div class="form-field"><label>Celular</label><input type="tel" id="inpCelularS" value="${valor("celular", primerCliente.celular || "")}" placeholder="10 dígitos"></div>

      <div class="form-field span-2">
        <label>Concepto</label>
        <select id="selConcepto">
          <option value="">Selecciona…</option>
          ${selectorConcepto}
        </select>
        <div class="form-field-info">${c ? escapeHTML(c.descripcion || "") : "Seguros, financiamiento, trámites vehiculares, impuestos y servicios de posventa."}</div>
      </div>

      ${c ? `
        ${seccionVehiculoConceptoHTML(c)}
        ${seccionCreditoConceptoHTML(c)}
        ${seccionOpcionConceptoHTML(c)}
        ${c.campos.map(campoConceptoHTML).join("")}
      ` : ""}
    </div>

    ${c ? `<div class="credito-info-grid" id="conceptoResultado">${resultadoConceptoHTML()}</div>` : ""}
  `;
}

// Vehículo de referencia: del ticket, vendido por KARMA o externo (según lo que permite el concepto)
function seccionVehiculoConceptoHTML(c){
  if (!c.origenesVehiculo.length) return "";
  const b = borrador;
  const enTicket = vehiculosDelTicket();
  const vendidos = vehiculosVendidosConcepto(c);
  const tipos = c.aplicaTipos;
  const usaValor = c.base === "vehiculo" || c.base === "vehiculo_sin_iva";

  let detalle = "";
  if (b.vehOrigen === "ticket"){
    detalle = `
      <div class="form-field span-2">
        <label>Vehículo del ticket</label>
        <select id="selVehTicket" ${!enTicket.length ? "disabled" : ""}>
          <option value="">${enTicket.length ? "Selecciona…" : "No hay vehículos de contado en el ticket"}</option>
          ${enTicket.map(it => `<option value="${it.id}" translate="no" ${Number(b.vehTicketId) === it.id ? "selected" : ""}>${escapeHTML(`${it.articulo} · VIN ${it.vin}`)}</option>`).join("")}
        </select>
      </div>`;
  } else if (b.vehOrigen === "vendido"){
    detalle = `
      <div class="form-field span-2">
        <label>Unidad vendida por KARMA</label>
        <select id="selVehVendido" ${!vendidos.length ? "disabled" : ""}>
          <option value="">${vendidos.length ? "Selecciona…" : "Sin unidades vendidas registradas"}</option>
          ${vendidos.map(v => `<option value="${v.idDetalle}" translate="no" ${Number(b.vehDetalleId) === v.idDetalle ? "selected" : ""}>${escapeHTML(`${v.vin} · ${v.marca} ${v.modelo} ${v.anio ?? ""} · ${v.fecha}`)}</option>`).join("")}
        </select>
      </div>`;
  } else if (b.vehOrigen === "externo"){
    detalle = `
      <div class="form-field"><label>VIN / Número de serie</label><input type="text" id="inpVehVin" maxlength="17" value="${escapeHTML(b.vehVin || "")}" placeholder="17 caracteres" autocomplete="off" autocapitalize="characters"></div>
      <div class="form-field">
        <label>Tipo de vehículo</label>
        <select id="selVehTipo">
          <option value="">Selecciona…</option>
          ${tipos.map(t => `<option value="${t}" ${b.vehTipo === t ? "selected" : ""}>${t === "moto" ? "Motocicleta" : "Automóvil"}</option>`).join("")}
        </select>
      </div>
      <div class="form-field"><label>Marca</label><input type="text" id="inpVehMarca" value="${escapeHTML(b.vehMarca || "")}" placeholder="Marca"></div>
      <div class="form-field"><label>Modelo</label><input type="text" id="inpVehModelo" value="${escapeHTML(b.vehModelo || "")}" placeholder="Modelo"></div>
      <div class="form-field"><label>Año</label><input type="number" id="inpVehAnio" min="1950" step="1" value="${escapeHTML(b.vehAnio || "")}" placeholder="Ej. ${new Date().getFullYear()}"></div>
      ${usaValor ? `<div class="form-field"><label>Valor factura (IVA incluido)</label><input type="number" id="inpVehValor" min="0" step="any" value="${escapeHTML(b.vehValor || "")}" placeholder="$ 0.00"></div>` : ""}`;
  }

  return `
    <div class="form-field span-2">
      <label>Vehículo de referencia${c.vehiculoObligatorio ? "" : " (opcional)"}</label>
      <div class="segmented">
        ${c.origenesVehiculo.map(o => `<button type="button" class="segmented-btn ${b.vehOrigen === o ? "is-active" : ""}" data-veh-origen="${o}">${ETIQUETAS_ORIGEN_VEHICULO[o] || o}</button>`).join("")}
      </div>
      ${c.unicoPorVin ? `<div class="form-field-info">Se cobra una sola vez por VIN.</div>` : ""}
    </div>
    ${detalle}`;
}

// Crédito de referencia: contrato KARMA activo o financiera externa
function seccionCreditoConceptoHTML(c){
  if (!c.origenesCredito.length) return "";
  const b = borrador;
  const creditos = creditosKarmaActivos();
  let detalle = "";
  if (b.credOrigen === "karma"){
    detalle = `
      <div class="form-field span-2">
        <label>Contrato de crédito</label>
        <select id="selCredFolio" ${!creditos.length ? "disabled" : ""}>
          <option value="">${creditos.length ? "Selecciona…" : "No hay créditos KARMA activos"}</option>
          ${creditos.map(k => `<option value="${escapeHTML(k.contratoFolio)}" translate="no" ${b.credFolio === k.contratoFolio ? "selected" : ""}>${escapeHTML(`${k.contratoFolio} · ${k.nombre} · ${k.articulo || ""}`)}</option>`).join("")}
        </select>
      </div>`;
  } else if (b.credOrigen === "externo"){
    detalle = `
      <div class="form-field span-2"><label>Institución financiera</label><input type="text" id="inpCredInstitucion" value="${escapeHTML(b.credInstitucion || "")}" placeholder="Banco o financiera"></div>
      <div class="form-field"><label>Monto del crédito</label><input type="number" id="inpCredMonto" min="0" step="any" value="${escapeHTML(b.credMonto || "")}" placeholder="$ 0.00"></div>
      <div class="form-field"><label>Plazo (meses)</label><input type="number" id="inpCredPlazo" min="1" max="120" step="1" value="${escapeHTML(b.credPlazo || "")}" placeholder="Ej. 48"></div>`;
  }
  return `
    <div class="form-field span-2">
      <label>Crédito de referencia</label>
      <div class="segmented">
        ${c.origenesCredito.map(o => `<button type="button" class="segmented-btn ${b.credOrigen === o ? "is-active" : ""}" data-cred-origen="${o}">${ETIQUETAS_ORIGEN_CREDITO[o] || o}</button>`).join("")}
      </div>
    </div>
    ${detalle}`;
}

// Plan / cobertura / paquete
function seccionOpcionConceptoHTML(c){
  if (!c.opciones.length) return "";
  const opciones = opcionesConcepto(c);
  return `
    <div class="form-field span-2">
      <label>Plan o cobertura</label>
      <select id="selOpcion" ${!opciones.length ? "disabled" : ""}>
        <option value="">${opciones.length ? "Selecciona…" : "Elige primero el vehículo de referencia"}</option>
        ${opciones.map(o => `<option value="${o.id}" ${Number(borrador.opcionId) === o.id ? "selected" : ""}>${escapeHTML(o.descripcion)}</option>`).join("")}
      </select>
    </div>`;
}

// Campo propio del concepto (texto, número, lista o área de texto)
function campoConceptoHTML(def){
  const campos = borrador.campos || {};
  const v = escapeHTML(campos[def.clave] ?? "");
  const etiqueta = `${escapeHTML(def.etiqueta)}${def.requerido ? "" : " (opcional)"}`;
  const ayuda = def.ayuda ? `<div class="form-field-info">${escapeHTML(def.ayuda)}</div>` : "";
  const id = `cmpConcepto_${def.clave}`;
  if (def.tipo === "select"){
    return `<div class="form-field"><label>${etiqueta}</label>
      <select id="${id}" data-campo-concepto="${escapeHTML(def.clave)}">
        <option value="">Selecciona…</option>
        ${(def.opciones || []).map(o => `<option value="${escapeHTML(o)}" ${campos[def.clave] === o ? "selected" : ""}>${escapeHTML(o)}</option>`).join("")}
      </select>${ayuda}</div>`;
  }
  if (def.tipo === "area"){
    return `<div class="form-field span-2"><label>${etiqueta}</label><textarea id="${id}" data-campo-concepto="${escapeHTML(def.clave)}" maxlength="1500">${v}</textarea>${ayuda}</div>`;
  }
  const tipo = def.tipo === "numero" ? "number" : "text";
  return `<div class="form-field"><label>${etiqueta}</label><input type="${tipo}" id="${id}" data-campo-concepto="${escapeHTML(def.clave)}" ${tipo === "number" ? `min="0" step="any"` : `maxlength="300"`} value="${v}">${ayuda}</div>`;
}

// Cuadros del resultado: desglose, subtotal, IVA, total y vigencia (mismo diseño que la simulación del crédito)
function resultadoConceptoHTML(){
  const r = conceptoCalculo;
  if (!r){
    return `<div class="form-field-info" style="grid-column:1 / -1;">${escapeHTML(conceptoMensaje || "Completa los datos para calcular el importe.")}</div>`;
  }
  const caja = (etq, val) => `<div class="credito-info-box"><span>${escapeHTML(etq)}</span><strong>${escapeHTML(val)}</strong></div>`;
  return `
    ${(r.desglose || []).map(([etq, val]) => caja(etq, val)).join("")}
    ${caja("Subtotal", formatoMonedaCentavos(r.subtotal))}
    ${caja("IVA", formatoMonedaCentavos(r.iva))}
    ${r.vigenciaFin ? caja("Vigencia", `${r.vigenciaInicio} — ${r.vigenciaFin}`) : ""}
    ${caja("Total a cobrar", formatoMoneda(r.total))}`;
}

// Repinta solo el resultado (los campos conservan el foco)
function pintarResultadoConcepto(){
  const caja = $("#conceptoResultado");
  if (caja) caja.innerHTML = resultadoConceptoHTML();
}

// Conecta los eventos de la pestaña «Servicios»
function bindFormularioConceptos(panel){
  bindTexto("inpClienteS", "cliente", panel);
  bindTexto("inpRfcIneS", "rfcIne", panel);
  bindTexto("inpEmailS", "email", panel);
  bindTexto("inpCelularS", "celular", panel);

  // Cambiar de concepto conserva los datos del cliente y arranca la captura con valores por omisión
  $("#selConcepto", panel)?.addEventListener("change", (e) => {
    const { cliente, rfcIne, email, celular } = borrador;
    borrador = { cliente, rfcIne, email, celular, conceptoId: e.target.value || undefined, campos: {} };
    const c = conceptoActual();
    if (c){
      borrador.vehOrigen = origenVehiculoInicial(c);
      borrador.credOrigen = c.origenesCredito[0] || "";
      c.campos.forEach(def => { if (def.predeterminado === "anio_actual") borrador.campos[def.clave] = String(new Date().getFullYear()); });
      if (borrador.vehOrigen === "ticket" && vehiculosDelTicket().length === 1) borrador.vehTicketId = vehiculosDelTicket()[0].id;
    }
    reiniciarCalculoConcepto();
    renderPanelVenta();
  });

  // Origen del vehículo y del crédito: limpian lo capturado del origen anterior
  $$("[data-veh-origen]", panel).forEach(btn => btn.addEventListener("click", () => {
    ["vehTicketId", "vehDetalleId", "vehVin", "vehTipo", "vehMarca", "vehModelo", "vehAnio", "vehValor", "opcionId"].forEach(k => { borrador[k] = undefined; });
    borrador.vehOrigen = btn.dataset.vehOrigen;
    if (borrador.vehOrigen === "ticket" && vehiculosDelTicket().length === 1) borrador.vehTicketId = vehiculosDelTicket()[0].id;
    renderPanelVenta();
  }));
  $$("[data-cred-origen]", panel).forEach(btn => btn.addEventListener("click", () => {
    ["credFolio", "credInstitucion", "credMonto", "credPlazo"].forEach(k => { borrador[k] = undefined; });
    borrador.credOrigen = btn.dataset.credOrigen;
    renderPanelVenta();
  }));

  // Listas que cambian las opciones disponibles: guardan y redibujan
  const enlazarLista = (id, clave, limpiarPlan) => $(`#${id}`, panel)?.addEventListener("change", (e) => {
    borrador[clave] = e.target.value || undefined;
    if (limpiarPlan) borrador.opcionId = undefined;
    renderPanelVenta();
  });
  enlazarLista("selVehTicket", "vehTicketId", true);
  enlazarLista("selVehVendido", "vehDetalleId", true);
  enlazarLista("selVehTipo", "vehTipo", true);
  enlazarLista("selOpcion", "opcionId", false);
  enlazarLista("selCredFolio", "credFolio", false);

  // Textos y números: guardan sin redibujar (no se pierde el foco) y piden un nuevo cálculo
  const enlazarTexto = (id, clave, transformar) => $(`#${id}`, panel)?.addEventListener("input", (e) => {
    if (transformar){
      const limpio = transformar(e.target.value);
      if (limpio !== e.target.value) e.target.value = limpio;
    }
    borrador[clave] = e.target.value;
    programarCalculoConcepto();
  });
  enlazarTexto("inpVehVin", "vehVin", v => v.replace(/\s+/g, "").toUpperCase());
  enlazarTexto("inpVehMarca", "vehMarca");
  enlazarTexto("inpVehModelo", "vehModelo");
  enlazarTexto("inpVehAnio", "vehAnio");
  enlazarTexto("inpVehValor", "vehValor");
  enlazarTexto("inpCredInstitucion", "credInstitucion");
  enlazarTexto("inpCredMonto", "credMonto");
  enlazarTexto("inpCredPlazo", "credPlazo");

  // Campos propios del concepto
  $$("[data-campo-concepto]", panel).forEach(el => {
    el.addEventListener(el.tagName === "SELECT" ? "change" : "input", () => {
      borrador.campos = { ...(borrador.campos || {}), [el.dataset.campoConcepto]: el.value };
      programarCalculoConcepto();
    });
  });

  if (conceptoActual()) programarCalculoConcepto();
}

/* ----- 3. Cálculo en el servidor ----- */

function reiniciarCalculoConcepto(){
  clearTimeout(conceptoTemporizador);
  conceptoPeticion += 1;
  conceptoCalculo = null;
  conceptoMensaje = "";
  conceptoClaveCalculo = "";
}

// Pide el cálculo cuando el cajero deja de escribir
function programarCalculoConcepto(){
  clearTimeout(conceptoTemporizador);
  conceptoTemporizador = setTimeout(calcularConceptoEnServidor, ESPERA_CALCULO_CONCEPTO);
}

// Llama a calcular_concepto; solo repinta si la respuesta corresponde a lo último capturado
async function calcularConceptoEnServidor(){
  const payload = payloadConcepto();
  if (!payload){ reiniciarCalculoConcepto(); pintarResultadoConcepto(); return; }
  const clave = JSON.stringify(payload);
  if (clave === conceptoClaveCalculo){ pintarResultadoConcepto(); return; }
  const numero = ++conceptoPeticion;
  try {
    const data = await apiFetch("calcular_concepto", { method: "POST", body: JSON.stringify({ concepto: payload }) });
    if (numero !== conceptoPeticion) return;
    conceptoCalculo = data.calculo;
    conceptoMensaje = "";
  } catch (error) {
    if (numero !== conceptoPeticion) return;
    conceptoCalculo = null;
    conceptoMensaje = error.message;
  }
  conceptoClaveCalculo = clave;
  pintarResultadoConcepto();
}

// Cálculo inmediato y obligatorio (Guardar / Cotizar): regresa el cálculo o lanza el motivo
async function calculoConceptoConfirmado(){
  const payload = payloadConcepto();
  if (!payload) throw new Error("Elige el concepto que vas a cobrar.");
  clearTimeout(conceptoTemporizador);
  const numero = ++conceptoPeticion;
  const data = await apiFetch("calcular_concepto", { method: "POST", body: JSON.stringify({ concepto: payload }) });
  if (numero === conceptoPeticion){
    conceptoCalculo = data.calculo;
    conceptoMensaje = "";
    conceptoClaveCalculo = JSON.stringify(payload);
    pintarResultadoConcepto();
  }
  return { calculo: data.calculo, payload };
}

/* ----- 4. Ticket ----- */

// «Guardar» en la pestaña Servicios: valida, recalcula en el servidor y agrega el concepto al ticket
async function guardarConceptoEnTicket(){
  try {
    if (ticketEsAbono()) throw new Error("El ticket tiene un abono mensual. Cóbralo (F3) o cancélalo (F6) antes de registrar otro concepto.");
    if (ticketEsCredito()) throw new Error("Este ticket tiene un crédito: concrétalo primero y cobra los servicios y trámites en un ticket nuevo.");
    if (pagoEstado) throw new Error("Termina primero el cobro que está en curso.");
    const c = conceptoActual();
    if (!c){ $("#selConcepto")?.focus(); throw new Error("Elige el concepto que vas a cobrar."); }
    const cliente = $("#inpClienteS").value.trim();
    if (!cliente){ $("#inpClienteS").focus(); return; }
    const email = $("#inpEmailS").value.trim();
    if (email && !/^\S+@\S+\.\S+$/.test(email)) throw new Error("El correo electrónico del cliente no es válido.");

    const { calculo, payload } = await calculoConceptoConfirmado();

    // Repetidos en el mismo ticket (el servidor también lo valida al cobrar)
    if (c.unicoPorVin && calculo.vehiculo && ticketItems.some(it => it.esConcepto && it.conceptoId === c.id && it.vin === calculo.vehiculo.vin)){
      throw new Error(`${c.nombre} ya está en el ticket para el VIN ${calculo.vehiculo.vin}.`);
    }

    ticketIdCounter += 1;
    ticketItems.push({
      id: ticketIdCounter, esConcepto: true, conceptoId: c.id, clave: c.clave, cantidad: 1,
      articulo: calculo.descripcion, precioTotal: Number(calculo.total),
      subtotal: Number(calculo.subtotal), iva: Number(calculo.iva),
      vin: calculo.vehiculo?.vin || "", vehiculo: calculo.vehiculo?.descripcion || "",
      credito: calculo.credito ? (calculo.credito.folio || calculo.credito.institucion) : "",
      referencia: calculo.referencia || "",
      vigenciaFin: calculo.vigenciaFin || "",
      // Si el concepto depende de un vehículo de este ticket, se quita junto con él (F4)
      vehiculoTicketId: payload.vehiculo?.origen === "ticket" ? Number(borrador.vehTicketId) : null,
      payload,
      cliente, email, celular: $("#inpCelularS").value.trim(), rfcIne: $("#inpRfcIneS").value.trim()
    });

    borrador = {};
    reiniciarCalculoConcepto();
    renderPanelVenta();
    renderPanelLateral();
    renderShortcutsBar();
  } catch (error) {
    avisar(error.message);
  }
}

// Tarjeta del concepto en el ticket (mismas clases que los demás artículos)
function conceptoTicketItemHTML(it){
  const referencia = it.vehiculo || it.credito || "—";
  return `
    <div class="ticket-item">
      <div class="ticket-item-head">
        <span class="ticket-item-articulo">${escapeHTML(it.articulo)}</span>
        ${modoEliminarTicket ? `<button class="ticket-item-remove" data-quitar-item="${it.id}" title="Quitar artículo">×</button>` : ""}
      </div>
      <div class="ticket-item-grid">
        <div><span>Referencia</span><strong>${escapeHTML(referencia)}</strong></div>
        <div><span>Subtotal</span><strong>${formatoMonedaCentavos(it.subtotal)}</strong></div>
        <div><span>IVA</span><strong>${formatoMonedaCentavos(it.iva)}</strong></div>
      </div>
      <div class="ticket-item-grid">
        <div><span>VIN</span><strong translate="no">${escapeHTML(it.vin || "—")}</strong></div>
        <div><span>Vigencia</span><strong>${escapeHTML(it.vigenciaFin ? `Hasta ${it.vigenciaFin}` : "—")}</strong></div>
        <div><span>Folio</span><strong>${escapeHTML(it.folio || "Al concretar")}</strong></div>
      </div>
      <div class="ticket-item-total">Importe del concepto <strong>${formatoMoneda(it.precioTotal)}</strong></div>
    </div>`;
}

// Bloque de folios en el ticket digital del cliente
function conceptosTicketDigitalHTML(conceptos){
  return `<div class="digital-ticket-contrato">Servicios y trámites:<br>${conceptos.map(f =>
    `${escapeHTML(f.descripcion)} · folio <strong>${escapeHTML(f.folio)}</strong>${f.referencia ? ` · ref. ${escapeHTML(f.referencia)}` : ""}${f.vigenciaFin ? ` · vigencia al ${escapeHTML(f.vigenciaFin)}` : ""}`
  ).join("<br>")}</div>`;
}

/* ----- 5. Enganche con script.js (decoradores) ----- */

(function instalarConceptosCaja(){
  const original = {
    apiFetch, formularioVentaHTML, bindFormularioVenta, guardarArticulo, calcularCotizacion,
    ticketItemHTML, quitarItemTicket, mostrarTicketCliente
  };

  // api.php: catálogo en bootstrap y conceptos dentro de crear_venta (los artículos siguen viajando igual)
  apiFetch = async function(action, options = {}){
    if (action === "preparar_credito" && ticketItems.some(it => it.esConcepto)){
      throw new Error("Un crédito no se puede cobrar junto con servicios y trámites. Quita los conceptos (F4) y cóbralos en un ticket aparte.");
    }
    if (action === "crear_venta" && typeof options.body === "string"){
      const cuerpo = JSON.parse(options.body);
      cuerpo.items = (cuerpo.items || []).filter(it => it.producto_id);
      cuerpo.conceptos = ticketItems.filter(it => it.esConcepto).map(it => it.payload);
      foliosConceptosVenta = null;
      const data = await original.apiFetch(action, { ...options, body: JSON.stringify(cuerpo) });
      foliosConceptosVenta = Array.isArray(data.conceptos) ? data.conceptos : [];
      return data;
    }
    const data = await original.apiFetch(action, options);
    if (action === "bootstrap"){
      const cat = data.conceptos || {};
      CONCEPTOS_CAJA = {
        disponible: !!cat.disponible, aviso: cat.aviso || "",
        conceptos: cat.conceptos || [], vehiculosVendidos: cat.vehiculosVendidos || []
      };
    }
    return data;
  };

  // Formulario: la pestaña «Servicios» dibuja su propio contenido; las demás quedan igual
  formularioVentaHTML = function(){
    return formTipoArticulo === TIPO_FORM_CONCEPTOS ? formularioConceptosHTML() : original.formularioVentaHTML();
  };

  // Agrega el botón «Servicios» al segmentado y conecta sus campos (el original conecta el segmentado y las acciones)
  bindFormularioVenta = function(){
    const panel = $("#panelVenta");
    const toggle = panel ? $(".tipo-articulo-toggle", panel) : null;
    if (toggle && CONCEPTOS_CAJA.disponible && !$(`[data-form-tipo="${TIPO_FORM_CONCEPTOS}"]`, toggle)){
      toggle.insertAdjacentHTML("beforeend", botonTipoConceptosHTML());
    }
    original.bindFormularioVenta();
    if (formTipoArticulo === TIPO_FORM_CONCEPTOS && panel) bindFormularioConceptos(panel);
    else reiniciarCalculoConcepto();
  };

  // Guardar: conceptos por su lado; un crédito no se mezcla con conceptos en el mismo ticket
  guardarArticulo = async function(){
    if (formTipoArticulo === TIPO_FORM_CONCEPTOS) return guardarConceptoEnTicket();
    if (formTipoArticulo === "Credito" && ticketItems.some(it => it.esConcepto)){
      avisar("El ticket tiene servicios o trámites. Concrétalo o quítalos (F4) antes de registrar un crédito: cada crédito lleva su propio contrato.");
      return;
    }
    return original.guardarArticulo();
  };

  // F5 en la pestaña Servicios: importe calculado por el servidor, sin tocar el ticket
  calcularCotizacion = async function(){
    if (formTipoArticulo !== TIPO_FORM_CONCEPTOS) return original.calcularCotizacion();
    try {
      const { calculo } = await calculoConceptoConfirmado();
      $("#cotizacionResultadoWrap").innerHTML = `
        <div class="cotizacion-result">
          <div class="label">Cotización estimada — ${escapeHTML(calculo.descripcion)}</div>
          <div class="value">${formatoMoneda(calculo.total)}</div>
        </div>`;
    } catch (error) {
      avisar(error.message);
    }
  };

  // Tarjeta del ticket
  ticketItemHTML = function(it){
    return it.esConcepto ? conceptoTicketItemHTML(it) : original.ticketItemHTML(it);
  };

  // F4: al quitar un vehículo se quitan también los conceptos que dependen de él
  quitarItemTicket = function(id){
    const dependientes = ticketItems.filter(it => it.esConcepto && it.vehiculoTicketId === id).map(it => it.id);
    if (dependientes.length) ticketItems = ticketItems.filter(it => !dependientes.includes(it.id));
    original.quitarItemTicket(id);
    if (dependientes.length) avisar(`También se quitaron ${dependientes.length} concepto(s) ligados a ese vehículo.`);
  };

  // Ticket digital: folios de los conceptos cobrados (vienen de crear_venta)
  mostrarTicketCliente = function(){
    if (ticketCerrado && foliosConceptosVenta && !ticketCerrado.conceptos){
      const folios = [...foliosConceptosVenta];
      let i = 0;
      ticketCerrado.items = ticketCerrado.items.map(it => it.esConcepto ? { ...it, folio: folios[i++]?.folio || null } : it);
      ticketCerrado.conceptos = folios;
      foliosConceptosVenta = null;
    }
    original.mostrarTicketCliente();
    if (ticketCerrado?.conceptos?.length){
      $("#ticketClienteContent .digital-ticket-thanks")?.insertAdjacentHTML("beforebegin", conceptosTicketDigitalHTML(ticketCerrado.conceptos));
    }
  };
})();
