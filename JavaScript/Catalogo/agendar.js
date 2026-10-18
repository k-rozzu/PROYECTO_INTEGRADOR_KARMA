/* =====================================================================================
   KARMA · Catálogo — agendar cita (visita, apartado de vehículo u orden de servicio de taller)
   Muestra existencias por sucursal, consulta horarios libres (api.php?action=disponibilidad)
   y registra la cita (api.php?action=agendar). El servidor vuelve a validar todo.
   ===================================================================================== */
(function () {
  "use strict";
  const { $, $$, api, esc, precio, icono, aviso, irALogin } = window.KARMA;
  const datos = JSON.parse($("#datosAgenda")?.textContent || "{}");
  const form = $("#formAgenda");
  if (!form) return;
  const vehiculos = datos.vehiculos || [];
  const nombresTipo = { visita: "Visita al concesionario", apartado: "Apartado de vehículo", servicio: "Servicio de taller" };

  const tipo = () => form.tipo.value;
  const sucursalId = () => Number(form.id_sucursal.value || 0);
  const vehiculo = () => vehiculos.find(v => v.id === Number($("#agVehiculo").value));
  const requiereStock = () => tipo() === "apartado";
  // Servicios adicionales marcados (solo en visita y apartado)
  const serviciosExtra = () => tipo() === "servicio" ? [] : $$('input[name="servicios_extra"]:checked', form).map(c => c.value);

  // ----- Vehículo: marca → modelos -----
  function llenarModelos(idElegido = null) {
    const marca = $("#agMarca").value;
    const lista = vehiculos.filter(v => v.marca === marca);
    $("#agVehiculo").innerHTML = lista.map(v => `<option value="${v.id}" ${v.id === idElegido ? "selected" : ""}>${esc(v.titulo)} ${v.anio || ""}</option>`).join("");
    pintarVehiculo();
  }
  function pintarVehiculo() {
    const v = vehiculo();
    const caja = $("#vehiculoElegido");
    if (!v) { caja.innerHTML = ""; return; }
    const disp = datos.sucursales.map(s => {
      const n = v.stocks[s.id] || 0;
      return `<span class="disp disp--${n > 0 ? (n <= 2 ? "pocas" : "disponible") : "agotado"}">${esc(s.nombre)}: ${n} ${n === 1 ? "unidad" : "unidades"}</span>`;
    }).join(" &nbsp; ");
    caja.innerHTML = `<img src="${esc(v.imagen)}" alt=""><div><strong translate="no">${esc(v.titulo)} ${v.anio || ""}</strong><span class="texto-2">Desde <span translate="no">${esc(v.precioTexto)}</span> MXN</span><div style="margin-top:6px; display:flex; flex-wrap:wrap; gap:10px">${disp}</div></div>`;
    if (!$("#agColor").value && v.color) $("#agColor").placeholder = `Unidad en inventario: ${v.color}`;
    pintarSucursales();
  }

  // ----- Sucursales: existencias del vehículo y bloqueo si la cita requiere unidad -----
  function pintarSucursales() {
    const v = vehiculo();
    const conVehiculo = tipo() !== "servicio" && v;
    $$("#opcionesSucursal [data-sucursal]").forEach(op => {
      const id = Number(op.dataset.sucursal);
      const n = conVehiculo ? (v.stocks[id] || 0) : null;
      const etiqueta = $("[data-stock-sucursal]", op);
      etiqueta.className = "disp" + (n === null ? "" : ` disp--${n > 0 ? (n <= 2 ? "pocas" : "disponible") : "agotado"}`);
      etiqueta.textContent = n === null ? "" : `${n} ${n === 1 ? "unidad disponible" : "unidades disponibles"}`;
      const bloquear = requiereStock() && n === 0;
      op.classList.toggle("deshabilitada", bloquear);
      $("input", op).disabled = bloquear;
      if (bloquear && $("input", op).checked) {
        $("input", op).checked = false;
        const otra = $$("#opcionesSucursal input:not(:disabled)")[0];
        if (otra) otra.checked = true;
      }
    });
    $("#ayudaSucursal").textContent = requiereStock()
      ? "Para apartar, la sucursal debe tener unidades del vehículo; las que no tienen aparecen deshabilitadas."
      : "Cada sucursal tiene su propio inventario.";
    cargarHoras();
    resumen();
  }

  // ----- Tipo de cita -----
  function alternarTipo() {
    const esServicio = tipo() === "servicio";
    $("#bloqueVehiculoCatalogo").classList.toggle("oculto", esServicio);
    $("#bloqueVehiculoServicio").classList.toggle("oculto", !esServicio);
    $("#tituloVehiculo").textContent = esServicio ? "Tu vehículo y el servicio" : "Vehículo de tu interés";
    $("#campoEnganche").classList.toggle("oculto", tipo() !== "apartado");
    $("#campoColor").classList.toggle("oculto", !["visita", "apartado"].includes(tipo()));
    $("#bloqueExtras").classList.toggle("oculto", esServicio);
    pintarSucursales();
  }

  // ----- Horarios libres -----
  let ultimaConsulta = 0;
  async function cargarHoras() {
    const fecha = $("#agFecha").value;
    const caja = $("#agHoras");
    $("#agHora").value = "";
    resumen();
    if (!fecha || !sucursalId()) { caja.innerHTML = `<p class="texto-3" style="grid-column:1/-1">Elige una fecha para ver los horarios.</p>`; return; }
    if (new Date(fecha + "T12:00:00").getDay() === 0) { caja.innerHTML = `<p class="texto-3" style="grid-column:1/-1">Los domingos la sucursal está cerrada. Elige otro día.</p>`; return; }
    const consulta = ++ultimaConsulta;
    caja.innerHTML = `<div class="esqueleto" style="height:44px; grid-column:1/-1"></div>`;
    try {
      const r = await api("disponibilidad", { params: { tipo: tipo(), id_sucursal: sucursalId(), fecha, id_producto: tipo() === "servicio" ? "" : (vehiculo()?.id || "") } });
      if (consulta !== ultimaConsulta) return;
      caja.innerHTML = r.horas.length
        ? r.horas.map(h => `<button class="hora" type="button" data-hora="${h.hora}" ${h.disponible ? "" : "disabled title=\"Horario ocupado\""}>${h.hora}</button>`).join("")
        : `<p class="texto-3" style="grid-column:1/-1">No hay horarios ese día.</p>`;
    } catch (e) {
      caja.innerHTML = `<p class="mensaje-form mensaje-form--error" style="grid-column:1/-1">${esc(e.message)}</p>`;
    }
  }
  $("#agHoras").addEventListener("click", (e) => {
    const b = e.target.closest("[data-hora]");
    if (!b) return;
    $$("#agHoras .hora").forEach(x => x.classList.toggle("activo", x === b));
    $("#agHora").value = b.dataset.hora;
    resumen();
  });

  // ----- Resumen lateral -----
  function resumen() {
    const v = vehiculo();
    const s = datos.sucursales.find(x => x.id === sucursalId());
    const fecha = $("#agFecha").value;
    $("#rcTipo").textContent = nombresTipo[tipo()] || "—";
    $("#rcVehiculo").textContent = tipo() === "servicio" ? ($("#agVehCliente").value || "—") : (v ? `${v.titulo} ${v.anio || ""}` : "—");
    $("#rcSucursal").textContent = s ? "KARMA " + s.nombre : "—";
    $("#rcFecha").textContent = fecha ? new Date(fecha + "T12:00:00").toLocaleDateString("es-MX", { weekday: "long", day: "numeric", month: "long" }) : "—";
    $("#rcHora").textContent = $("#agHora").value || "—";
    const servicios = tipo() === "servicio" ? [$("#agServicio").value] : serviciosExtra();
    $("#rcServicios").textContent = servicios.length ? servicios.join(", ") : "—";
  }

  // ----- Envío -----
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const msg = $("#agMensaje");
    msg.className = "mensaje-form";
    msg.textContent = "";
    if (!$("#agHora").value) { msg.className = "mensaje-form mensaje-form--error"; msg.textContent = "Elige la fecha y un horario disponible."; return; }
    const boton = $("#btnAgendar");
    boton.classList.add("cargando");
    const datosCita = {
      tipo: tipo(), id_sucursal: sucursalId(), fecha: $("#agFecha").value, hora: $("#agHora").value,
      nombre: form.nombre.value, email: form.email.value, telefono: form.telefono.value, comentarios: form.comentarios.value
    };
    // Los servicios adicionales viajan al inicio de los comentarios (así también los ve el asesor en POS → Web orders)
    const extras = serviciosExtra();
    if (extras.length) datosCita.comentarios = `Servicios de interés: ${extras.join(", ")}. ${datosCita.comentarios}`.trim().slice(0, 1000);
    if (tipo() === "servicio") Object.assign(datosCita, { vehiculo_cliente: form.vehiculo_cliente.value, vin: form.vin.value, kilometraje: form.kilometraje.value, tipo_servicio: form.tipo_servicio.value });
    else Object.assign(datosCita, { id_producto: vehiculo()?.id, color: form.color.value, enganche: tipo() === "apartado" ? form.enganche.value : "" });
    try {
      const r = await api("agendar", { metodo: "POST", datos: datosCita });
      form.classList.add("oculto");
      const exito = $("#exitoCita");
      exito.classList.remove("oculto");
      exito.innerHTML = `
        <div class="exito-cabeza"><span class="icono-ok">${icono("check")}</span><div><h1>${esc(r.mensaje)}</h1><p class="texto-2">Folio <strong translate="no">${esc(r.folio)}</strong> · ${esc(r.sucursal)} · ${esc(r.fecha)}${r.folioOrden ? ` · Orden web <strong translate="no">${esc(r.folioOrden)}</strong> enviada al asesor de la sucursal` : ""}.</p></div></div>
        <div class="fila fila--envolver"><a class="btn btn--primario" href="perfil.php#citas">Ver mis citas</a><a class="btn btn--secundario" href="vehiculos.php">Seguir explorando</a></div>`;
      window.scrollTo({ top: 0, behavior: "smooth" });
    } catch (err) {
      if (err.estado === 401) return irALogin();
      msg.className = "mensaje-form mensaje-form--error";
      msg.innerHTML = `${icono("alerta")}<span>${esc(err.message)}</span>`;
      if (err.estado === 409) cargarHoras();
    } finally { boton.classList.remove("cargando"); }
  });

  // ----- Eventos y estado inicial -----
  $$('input[name="tipo"]', form).forEach(r => r.addEventListener("change", alternarTipo));
  $("#agMarca").addEventListener("change", () => llenarModelos());
  $("#agVehiculo").addEventListener("change", pintarVehiculo);
  $("#opcionesSucursal").addEventListener("change", () => { cargarHoras(); resumen(); });
  $("#agFecha").addEventListener("change", cargarHoras);
  $("#agVehCliente").addEventListener("input", resumen);
  $("#agServicio").addEventListener("change", resumen);
  $$('input[name="servicios_extra"]', form).forEach(c => c.addEventListener("change", resumen));
  const inicial = vehiculos.find(v => v.id === datos.idProducto);
  if (inicial) $("#agMarca").value = inicial.marca;
  llenarModelos(inicial ? inicial.id : null);
  alternarTipo();
})();
