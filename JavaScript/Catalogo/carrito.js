/* =====================================================================================
   KARMA · Catálogo — carrito, checkout y detalle de pedido
   El servidor (api.php) vuelve a validar existencias, precios y datos de pago antes de crear el pedido.
   ===================================================================================== */
(function () {
  "use strict";
  const { $, $$, api, esc, precio, icono, aviso, irALogin, actualizarContadorCarrito, config } = window.KARMA;

  // ===== CARRITO =====
  function iniciarCarrito() {
    const lista = $("#listaCarrito");
    if (!lista) return;
    const continuar = $("#btnContinuar");

    const pintar = (c) => {
      actualizarContadorCarrito(c.cantidad);
      $("#carritoSubtotal").textContent = precio(c.subtotal, true);
      $("#carritoTotal").textContent = precio(c.subtotal, true);
      $("#carritoEnvio").textContent = c.subtotal >= c.envioGratisDesde ? "Gratis" : precio(c.envioCosto, true);
      const problemas = $("#carritoProblemas");
      problemas.classList.toggle("oculto", !c.hayProblemas);
      problemas.textContent = c.hayProblemas ? "Algunas piezas no tienen existencias suficientes en esta sucursal. Ajusta las cantidades para continuar." : "";
      continuar.classList.toggle("oculto", !c.items.length);
      continuar.toggleAttribute("aria-disabled", c.hayProblemas);
      continuar.style.pointerEvents = c.hayProblemas ? "none" : "";
      continuar.style.opacity = c.hayProblemas ? ".5" : "";
      if (!config.cliente) continuar.href = "login.php?volver=checkout.php";
      if (!c.items.length) {
        lista.innerHTML = `<div class="vacio">${icono("carrito", "icono-grande")}<h3>Tu carrito está vacío</h3><p>Agrega refacciones o accesorios para tu Audi, Porsche o Ducati.</p><div class="fila fila--envolver" style="justify-content:center"><a class="btn btn--primario" href="refacciones.php">Ver refacciones</a><a class="btn btn--secundario" href="accesorios.php">Ver accesorios</a></div></div>`;
        return;
      }
      lista.innerHTML = c.items.map(it => `
        <article class="item-carrito${it.suficiente ? "" : " con-problema"}" data-id="${it.id}">
          <a class="media" href="${esc(it.url)}"><img src="${esc(it.imagen)}" alt="" loading="lazy"></a>
          <div>
            <span class="meta" translate="no">${esc(it.marca)} · ${esc(it.codigo)}</span>
            <h3><a href="${esc(it.url)}">${esc(it.nombre)}</a></h3>
            <span class="meta">Compatible con <span translate="no">${esc(it.compatibilidad || it.marca)}</span> · <span translate="no">${precio(it.precio, true)}</span> c/u</span>
            <div class="controles">
              <div class="selector-cantidad">
                <button type="button" data-paso-cantidad="-1" aria-label="Quitar una">${icono("menos", "icono icono--chico")}</button>
                <input type="number" value="${it.cantidad}" min="1" max="${Math.max(it.stock, 1)}" aria-label="Cantidad de ${esc(it.nombre)}" data-cantidad="${it.id}">
                <button type="button" data-paso-cantidad="1" aria-label="Agregar una">${icono("mas", "icono icono--chico")}</button>
              </div>
              <span class="disp disp--${it.estadoStock}">${esc(it.textoStock)}</span>
              <button class="btn-quitar" type="button" data-quitar="${it.id}">${icono("basura", "icono icono--chico")} Quitar</button>
            </div>
            ${it.aviso ? `<p class="mensaje-form mensaje-form--error" style="margin-top:10px">${icono("alerta")} ${esc(it.aviso)}</p>` : ""}
          </div>
          <div class="total-linea"><span class="precio" translate="no">${precio(it.subtotal, true)}</span></div>
        </article>`).join("");
    };

    const cargar = () => api("carrito").then(r => pintar(r.carrito)).catch(e => { lista.innerHTML = `<div class="vacio"><h3>No se pudo cargar tu carrito</h3><p>${esc(e.message)}</p></div>`; });
    lista.addEventListener("change", async (e) => {
      const input = e.target.closest("[data-cantidad]");
      if (!input) return;
      try { pintar((await api("carrito_actualizar", { metodo: "POST", datos: { id_producto: Number(input.dataset.cantidad), cantidad: Number(input.value) } })).carrito); }
      catch (err) { aviso(err.message, "error"); cargar(); }
    });
    lista.addEventListener("click", async (e) => {
      const quitar = e.target.closest("[data-quitar]");
      if (!quitar) return;
      try { pintar((await api("carrito_eliminar", { metodo: "POST", datos: { id_producto: Number(quitar.dataset.quitar) } })).carrito); aviso("Producto quitado del carrito.", "ok"); }
      catch (err) { aviso(err.message, "error"); }
    });
    cargar();
  }

  // ===== CHECKOUT =====
  function iniciarCheckout() {
    const form = $("#formCheckout");
    if (!form) return;
    let carrito = null;
    const modalidad = () => form.modalidad.value;

    const pintarResumen = () => {
      if (!carrito) return;
      const envio = modalidad() === "envio_tarjeta" ? (carrito.subtotal >= carrito.envioGratisDesde ? 0 : carrito.envioCosto) : 0;
      const total = carrito.subtotal + envio;
      $("#ckItems").innerHTML = carrito.items.map(it => `
        <div class="mini-item"><img src="${esc(it.imagen)}" alt="" loading="lazy"><div class="nom"><strong>${esc(it.nombre)}</strong><span class="texto-3">${it.cantidad} × <span translate="no">${precio(it.precio, true)}</span></span></div><strong translate="no">${precio(it.subtotal, true)}</strong></div>`).join("");
      $("#ckSubtotal").textContent = precio(carrito.subtotal, true);
      $("#ckEnvio").textContent = modalidad() === "envio_tarjeta" ? (envio ? precio(envio, true) : "Gratis") : "Sin costo";
      $("#ckTotal").textContent = precio(total, true);
      $("#ckTotalEfectivo").textContent = precio(total, true);
      $("#btnConfirmar").textContent = modalidad() === "envio_tarjeta" ? `Pagar ${precio(total, true)}` : "Confirmar pedido y apartar piezas";
    };
    const alternarModalidad = () => {
      const envio = modalidad() === "envio_tarjeta";
      $("#bloqueEnvio").classList.toggle("oculto", !envio);
      $("#pagoTarjeta").classList.toggle("oculto", !envio);
      $("#pagoEfectivo").classList.toggle("oculto", envio);
      pintarResumen();
    };
    $$('input[name="modalidad"]', form).forEach(r => r.addEventListener("change", alternarModalidad));

    // Tarjeta visual y formato mientras se escribe (no sale del navegador hasta confirmar)
    const numero = $("#tjNumero"), vence = $("#tjVence"), titular = $("#tjTitular");
    numero.addEventListener("input", () => {
      const d = numero.value.replace(/\D/g, "").slice(0, 19);
      numero.value = d.replace(/(.{4})/g, "$1 ").trim();
      $("#tvNumero").textContent = (d.padEnd(16, "•").replace(/(.{4})/g, "$1 ")).trim();
      $("#tvMarca").textContent = /^4/.test(d) ? "VISA" : /^(5[1-5]|2[2-7])/.test(d) ? "Mastercard" : /^3[47]/.test(d) ? "AMEX" : "Tarjeta";
    });
    vence.addEventListener("input", () => {
      let d = vence.value.replace(/\D/g, "").slice(0, 4);
      if (d.length > 2) d = d.slice(0, 2) + "/" + d.slice(2);
      vence.value = d;
      $("#tvVence").textContent = d || "MM/AA";
    });
    titular.addEventListener("input", () => { $("#tvTitular").textContent = titular.value.toUpperCase() || "TITULAR"; });
    $("#tjCvv").addEventListener("input", (e) => { e.target.value = e.target.value.replace(/\D/g, "").slice(0, 4); });

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const msg = $("#ckMensaje");
      msg.className = "mensaje-form";
      msg.textContent = "";
      const boton = $("#btnConfirmar");
      const datos = {
        modalidad: modalidad(), id_sucursal: Number(form.id_sucursal.value),
        nombre: form.nombre.value, celular: form.celular.value, email: form.email.value, comentarios: form.comentarios.value
      };
      if (datos.modalidad === "envio_tarjeta") {
        Object.assign(datos, { calle: form.calle.value, colonia: form.colonia.value, ciudad: form.ciudad.value, estado: form.estado.value, cp: form.cp.value, referencias: form.referencias.value });
        datos.tarjeta = { titular: titular.value, numero: numero.value, vencimiento: vence.value, cvv: $("#tjCvv").value, tipo: $("#tjTipo").value };
      }
      boton.classList.add("cargando");
      try {
        const r = await api("checkout", { metodo: "POST", datos });
        actualizarContadorCarrito(0);
        window.location.href = r.url + "&nuevo=1";
      } catch (err) {
        if (err.estado === 401) return irALogin();
        msg.className = "mensaje-form mensaje-form--error";
        msg.innerHTML = `${icono("alerta")}<span>${esc(err.message)}</span>`;
        msg.scrollIntoView({ behavior: "smooth", block: "center" });
        if (err.estado === 409) setTimeout(() => { window.location.href = "carrito.php"; }, 2500);
      } finally { boton.classList.remove("cargando"); }
    });

    api("carrito").then(r => {
      carrito = r.carrito;
      if (!carrito.items.length) { window.location.href = "carrito.php"; return; }
      if (carrito.hayProblemas) {
        const msg = $("#ckMensaje");
        msg.className = "mensaje-form mensaje-form--error";
        msg.textContent = "Algunas piezas ya no tienen existencias suficientes. Regresa al carrito para ajustarlas.";
      }
      alternarModalidad();
    }).catch(e => aviso(e.message, "error"));
  }

  // ===== DETALLE DEL PEDIDO: cancelar (solo pendientes de pago en sucursal) =====
  function iniciarPedido() {
    const boton = $("#btnCancelarPedido");
    if (!boton) return;
    boton.addEventListener("click", async () => {
      if (!confirm("¿Cancelar este pedido? Las piezas regresarán al inventario de la sucursal.")) return;
      boton.classList.add("cargando");
      try {
        await api("cancelar_pedido", { metodo: "POST", datos: { id_orden: Number(boton.dataset.id) } });
        try { sessionStorage.setItem("karma_aviso", "Pedido cancelado. Las piezas regresaron al inventario de la sucursal."); } catch (_) {}
        window.location.href = window.location.pathname + "?id=" + boton.dataset.id;
      } catch (e) { aviso(e.message, "error"); boton.classList.remove("cargando"); }
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    iniciarCarrito();
    iniciarCheckout();
    iniciarPedido();
  });
})();
