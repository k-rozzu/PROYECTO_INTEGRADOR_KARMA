/* =====================================================================================
   KARMA · Catálogo — formulario de contacto y simulador completo de crédito (financiamiento.php).
   Los mensajes de contacto se guardan en la tabla `solicitudes` (api.php?action=solicitud); la simulación
   viaja como nota a agendar.php para tramitar el crédito en una cita.
   ===================================================================================== */
(function () {
  "use strict";
  const { $, $$, api, esc, precio, icono, aviso, calcularCredito, tablaAmortizacion, config } = window.KARMA;

  // ===== FORMULARIOS DE SOLICITUD =====
  // data-tipo="contacto" (tipo fijo) o data-tipo-campo="motivo" (el tipo sale de un <select>)
  // Los campos con data-extra se envían también como datos estructurados de la solicitud.
  function iniciarSolicitudes() {
    $$(".form-solicitud").forEach(form => form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const msg = $(".mensaje-form[role=alert]", form);
      const boton = $("[type=submit]", form);
      if (form.acepto && !form.acepto.checked) { msg.className = "mensaje-form mensaje-form--error"; msg.textContent = "Acepta el aviso de privacidad para enviar tu mensaje."; return; }
      const extras = {};
      $$("[data-extra]", form).forEach(c => { if (c.value.trim()) extras[c.name] = c.value.trim(); });
      const tipo = form.dataset.tipo || form.elements[form.dataset.tipoCampo]?.value || "contacto";
      let mensaje = form.mensaje?.value || "";
      // Si no hay mensaje escrito, se arma uno legible con los datos del formulario
      if (!mensaje.trim() && Object.keys(extras).length) mensaje = Object.entries(extras).map(([k, v]) => `${k}: ${v}`).join(" · ");
      const datos = {
        tipo, nombre: form.nombre?.value || "", email: form.email?.value || "", telefono: form.telefono?.value || "",
        asunto: form.asunto?.value || form.dataset.asunto || "", mensaje,
        id_sucursal: Number(form.id_sucursal?.value || config.sucursal?.id || 0),
        datos: extras
      };
      boton.classList.add("cargando");
      msg.className = "mensaje-form";
      msg.textContent = "";
      try {
        const r = await api("solicitud", { metodo: "POST", datos });
        msg.className = "mensaje-form mensaje-form--ok";
        msg.innerHTML = `${icono("check-circulo")}<span>${esc(r.mensaje)} Folio <strong translate="no">${esc(r.folio)}</strong>.</span>`;
        $$("textarea, [data-extra]", form).forEach(c => { if (c.tagName !== "SELECT") c.value = ""; });
        if (form.asunto) form.asunto.value = "";
        aviso(`Solicitud ${r.folio} enviada.`, "ok");
      } catch (err) {
        msg.className = "mensaje-form mensaje-form--error";
        msg.innerHTML = `${icono("alerta")}<span>${esc(err.message)}</span>`;
      } finally { boton.classList.remove("cargando"); }
    }));
  }

  // ===== SIMULADOR DE FINANCIAMIENTO (financiamiento.php) =====
  function iniciarSimulador() {
    const precioEl = $("#fsPrecio");
    if (!precioEl) return;
    const vehiculoEl = $("#fsVehiculo"), engancheEl = $("#fsEnganche"), tasaEl = $("#fsTasa");
    let plazo = Number($("#fsPlazos .activo")?.dataset.plazo || 48);
    let calc = null;
    const calcular = () => {
      const p = Math.max(0, Number(precioEl.value) || 0);
      const pct = Number(engancheEl.value);
      const tasa = Number(tasaEl.value);
      const enganche = p * pct / 100;
      calc = calcularCredito({ precio: p, engancheMonto: enganche, plazoMeses: plazo, tasaAnualPct: tasa });
      $("#fsEngancheTxt").textContent = `${pct}% · ${precio(enganche)}`;
      $("#fsTasaTxt").textContent = `${tasa.toFixed(1)}%`;
      $("#fsMensualidad").textContent = precio(calc.mensualidad);
      $("#fsEngancheMonto").textContent = precio(enganche);
      $("#fsComision").textContent = precio(calc.comisionApertura);
      $("#fsFinanciado").textContent = precio(calc.montoFinanciado);
      $("#fsIntereses").textContent = precio(calc.montoInteres);
      $("#fsTotal").textContent = precio(calc.montoFinal + enganche);
      if ($("#fsTablaCaja").innerHTML) $("#fsTablaCaja").innerHTML = tablaAmortizacion(calc);
      // "Agendar cita con esta simulación": lleva el vehículo elegido y la simulación como nota de la cita
      const opcion = vehiculoEl.selectedOptions[0];
      const vehiculo = opcion?.value ? opcion.textContent.trim() : "precio capturado";
      const nota = `Simulación de crédito (${vehiculo}): ${precio(p)}, enganche ${pct}%, ${plazo} meses, tasa ${tasa.toFixed(1)}%, mensualidad estimada ${precio(calc.mensualidad)}`;
      const enlace = `agendar.php?tipo=visita${opcion?.value ? `&id=${opcion.value}` : ""}&nota=${encodeURIComponent(nota.slice(0, 400))}`;
      $$("#fsCita, #fsCita2").forEach(a => { a.href = enlace; });
    };
    vehiculoEl.addEventListener("change", () => {
      const op = vehiculoEl.selectedOptions[0];
      if (op?.dataset.precio) precioEl.value = Math.round(Number(op.dataset.precio));
      calcular();
    });
    precioEl.addEventListener("input", () => { vehiculoEl.value = ""; calcular(); });
    engancheEl.addEventListener("input", calcular);
    tasaEl.addEventListener("input", calcular);
    $$("#fsPlazos button").forEach(b => b.addEventListener("click", () => {
      plazo = Number(b.dataset.plazo);
      $$("#fsPlazos button").forEach(x => x.classList.toggle("activo", x === b));
      calcular();
    }));
    $("#fsTabla").addEventListener("click", () => {
      const caja = $("#fsTablaCaja");
      const abierta = !!caja.innerHTML;
      caja.innerHTML = abierta ? "" : tablaAmortizacion(calc);
      $("#fsTabla").innerHTML = icono("grafica") + (abierta ? " Ver tabla de amortización" : " Ocultar tabla de amortización");
    });
    calcular();
  }

  document.addEventListener("DOMContentLoaded", () => {
    iniciarSolicitudes();
    iniciarSimulador();
  });
})();
