/* =====================================================================================
   KARMA · Catálogo — cuenta del cliente: inicio de sesión, registro y perfil
   (sesión de clientes del catálogo; es independiente del login del Punto de Venta)
   ===================================================================================== */
(function () {
  "use strict";
  const { $, $$, api, esc, precio, icono, aviso, tarjetaVehiculo, revelar } = window.KARMA;

  function mensaje(el, texto, tipo = "error") {
    if (!el) return;
    el.className = `mensaje-form mensaje-form--${tipo}`;
    el.innerHTML = texto ? `${icono(tipo === "ok" ? "check-circulo" : "alerta")}<span>${esc(texto)}</span>` : "";
  }

  // Mostrar / ocultar contraseña
  document.addEventListener("click", (e) => {
    const b = e.target.closest("[data-ver-password]");
    if (!b) return;
    const input = document.getElementById(b.dataset.verPassword);
    input.type = input.type === "password" ? "text" : "password";
    b.setAttribute("aria-label", input.type === "password" ? "Mostrar contraseña" : "Ocultar contraseña");
  });

  // ===== INICIO DE SESIÓN =====
  function iniciarLogin() {
    const form = $("#formLogin");
    if (!form) return;
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const boton = $("[type=submit]", form);
      boton.classList.add("cargando");
      mensaje($("#lgMensaje"), "");
      try {
        await api("login", { metodo: "POST", datos: { email: form.email.value, password: form.password.value } });
        window.location.href = form.dataset.volver || "perfil.php";
      } catch (err) {
        mensaje($("#lgMensaje"), err.message);
        form.password.value = "";
        form.password.focus();
      } finally { boton.classList.remove("cargando"); }
    });
  }

  // ===== REGISTRO =====
  function fuerza(pass) {
    let p = 0;
    if (pass.length >= 8) p++;
    if (pass.length >= 12) p++;
    if (/[a-z]/i.test(pass) && /\d/.test(pass)) p++;
    if (/[^A-Za-z0-9]/.test(pass)) p++;
    return p;
  }
  function iniciarRegistro() {
    const form = $("#formRegistro");
    if (!form) return;
    const barra = $("#rgFuerza"), texto = $("#rgFuerzaTexto");
    form.password.addEventListener("input", () => {
      const f = fuerza(form.password.value);
      const niveles = [["0%", "var(--c-line)", "Mínimo 8 caracteres con letras y números."], ["30%", "var(--c-bad)", "Débil"], ["55%", "var(--c-warn)", "Aceptable"], ["80%", "var(--c-ok)", "Buena"], ["100%", "var(--c-ok)", "Muy segura"]];
      const [ancho, color, etiqueta] = niveles[form.password.value ? Math.max(1, f) : 0];
      barra.style.width = ancho;
      barra.style.background = color;
      texto.textContent = etiqueta;
    });
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const msg = $("#rgMensaje");
      if (form.password.value !== form.confirmacion.value) return mensaje(msg, "Las contraseñas no coinciden.");
      const boton = $("[type=submit]", form);
      boton.classList.add("cargando");
      mensaje(msg, "");
      const datos = Object.fromEntries(new FormData(form).entries());
      datos.notif_promociones = form.notif_promociones.checked;
      try {
        // Paso 1: el servidor crea la solicitud y envía el correo; la cuenta todavía NO existe
        const r = await api("registro", { metodo: "POST", datos });
        form.password.value = form.confirmacion.value = "";
        mostrarEspera(r);
      } catch (err) { mensaje(msg, err.message); }
      finally { boton.classList.remove("cargando"); }
    });
    iniciarEspera(form);
  }

  // ===== REGISTRO · PASO 2: «Revisa tu correo» (esperando la aceptación desde el botón del correo) =====
  let consulta = null, cuentaAtras = null, esperaSegundos = 0, reenviosRestantes = 1;

  function mostrarPaso(espera) {
    $("#rgPasoFormulario")?.classList.toggle("oculto", espera);
    $("#rgPasoEspera")?.classList.toggle("oculto", !espera);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
  function mostrarEspera(r) {
    $("#rgEsperaEmail").textContent = r.email || "";
    $("#rgEsperaVence").textContent = r.vence || "";
    mensaje($("#rgEsperaMensaje"), "");
    estadoEspera("Esperando tu confirmación…", "info");
    mostrarPaso(true);
    programarReenvio(r.reenviarEn ?? 60, r.reenviosRestantes ?? 0);
    vigilar();
  }
  function estadoEspera(texto, tipo = "info") {
    const caja = $("#rgEstado");
    if (!caja) return;
    caja.className = `estado-espera estado-espera--${tipo}`;
    $("#rgEstadoTexto").textContent = texto;
  }
  // Botón «Reenviar correo» con cuenta regresiva (el servidor aplica los mismos límites)
  function programarReenvio(segundos, restantes) {
    esperaSegundos = Math.max(0, Number(segundos) || 0);
    reenviosRestantes = Math.max(0, Number(restantes) || 0);
    clearInterval(cuentaAtras);
    const pintar = () => {
      const boton = $("#rgReenviar");
      if (!boton) return;
      const etiqueta = $("span", boton);
      if (reenviosRestantes <= 0) { boton.disabled = true; etiqueta.textContent = "Límite de reenvíos alcanzado"; return; }
      boton.disabled = esperaSegundos > 0;
      etiqueta.textContent = esperaSegundos > 0 ? `Reenviar correo (${esperaSegundos} s)` : "Reenviar correo";
    };
    pintar();
    cuentaAtras = setInterval(() => { esperaSegundos = Math.max(0, esperaSegundos - 1); pintar(); if (!esperaSegundos) clearInterval(cuentaAtras); }, 1000);
  }
  // Consulta cada 5 s si ya se confirmó (también al volver a la pestaña, por ejemplo después de abrir Gmail)
  function vigilar() {
    clearInterval(consulta);
    consulta = setInterval(revisarEstado, 5000);
  }
  async function revisarEstado() {
    if (document.hidden || $("#rgPasoEspera")?.classList.contains("oculto")) return;
    let r;
    try { r = await api("registro_estado"); } catch (_) { return; }
    if (r.estado === "pendiente") return;
    clearInterval(consulta);
    clearInterval(cuentaAtras);
    if (r.estado === "completado" && r.sesion) {
      estadoEspera("¡Registro confirmado! Entrando a tu cuenta…", "ok");
      try { sessionStorage.setItem("karma_aviso", "¡Registro completado! Tu cuenta KARMA ya está activa."); } catch (_) {}
      const form = $("#formRegistro");
      setTimeout(() => { window.location.href = form?.dataset.volver || "perfil.php"; }, 900);
    } else if (r.estado === "completado") {
      estadoEspera("Tu registro se confirmó desde otro navegador o dispositivo.", "ok");
      $("#rgEsperaAcciones").innerHTML = `<a class="btn btn--primario" href="login.php">Iniciar sesión</a>`;
    } else {
      estadoEspera("La solicitud ya no está vigente: no se creó ninguna cuenta.", "error");
      mensaje($("#rgEsperaMensaje"), "Vuelve a llenar el formulario para recibir un correo nuevo.", "info");
      $("#rgReenviar").disabled = true;
      $("#rgOtroCorreo").textContent = "Volver al formulario";
    }
  }
  function iniciarEspera(form) {
    const panel = $("#rgPasoEspera");
    if (!panel) return;
    $("#rgReenviar").addEventListener("click", async () => {
      const boton = $("#rgReenviar");
      boton.classList.add("cargando");
      mensaje($("#rgEsperaMensaje"), "");
      try {
        const r = await api("registro_reenviar", { metodo: "POST" });
        mensaje($("#rgEsperaMensaje"), r.mensaje, "ok");
        $("#rgEsperaVence").textContent = r.vence || "";
        programarReenvio(r.reenviarEn, r.reenviosRestantes);
      } catch (err) {
        mensaje($("#rgEsperaMensaje"), err.message);
        if (err.estado === 410) revisarEstado();
      } finally { boton.classList.remove("cargando"); }
    });
    $("#rgOtroCorreo").addEventListener("click", async () => {
      await api("registro_cancelar", { metodo: "POST" }).catch(() => {});
      clearInterval(consulta);
      clearInterval(cuentaAtras);
      $("#rgOtroCorreo").textContent = "Usar otro correo";
      mensaje($("#rgMensaje"), "");
      mostrarPaso(false);
      form.email.focus();
    });
    document.addEventListener("visibilitychange", () => { if (!document.hidden) revisarEstado(); });
    if (panel.dataset.activa === "1") {
      // La página se recargó con una solicitud en curso: se consulta el estado real y los límites de reenvío
      api("registro_estado").then(r => {
        if (r.estado === "pendiente") { programarReenvio(r.reenviarEn, r.reenviosRestantes); vigilar(); }
        else revisarEstado();
      }).catch(() => vigilar());
    }
  }

  // ===== PERFIL =====
  const pill = (clase, texto) => `<span class="estado-pill estado-pill--${clase}">${esc(texto)}</span>`;
  let perfil = null;

  function pedidoHTML(o) {
    return `
      <article class="tarjeta-pedido">
        <div class="cabeza">
          <div><span>Folio</span><strong translate="no">${esc(o.folio)}</strong></div>
          <div><span>Fecha</span><strong>${esc(o.fechaTexto)}</strong></div>
          <div><span>Total</span><strong translate="no">${precio(o.total, true)}</strong></div>
          <div><span>${o.entrega === "envio" ? "Envío" : "Recoger en"}</span><strong translate="no">${o.entrega === "envio" ? "A domicilio" : "KARMA " + esc(o.sucursal)}</strong></div>
          <span class="estado">${pill(o.clase, o.etiqueta)}</span>
        </div>
        <div class="cuerpo">
          ${o.lineas.map(l => `<div class="linea-pedido"><img src="${esc(l.imagen)}" alt="" loading="lazy"><div class="nom"><strong>${esc(l.descripcion)}</strong><div class="texto-3" style="font-size:13px">${l.cantidad} × <span translate="no">${precio(l.precio, true)}</span></div></div><strong translate="no">${precio(l.subtotal, true)}</strong></div>`).join("")}
          <div class="fila fila--envolver"><a class="btn btn--secundario btn--chico" href="pedido.php?id=${o.id}">Ver detalle</a>
          ${o.cancelable ? `<button class="btn btn--peligro btn--chico" type="button" data-cancelar-pedido="${o.id}">Cancelar pedido</button>` : ""}</div>
        </div>
      </article>`;
  }
  function citaHTML(c) {
    const clase = c.estado === "cancelada" ? "cancelado" : (c.estado === "completada" || c.etiqueta.startsWith("Atendida") ? "pagado" : "info");
    return `
      <article class="tarjeta-cita">
        <div class="media">${c.imagen ? `<img src="${esc(c.imagen)}" alt="" loading="lazy">` : icono(c.tipo === "servicio" ? "herramienta" : "calendario", "icono-grande")}</div>
        <div>
          <span class="mayus texto-3">${esc(c.tipoTexto)} · <span translate="no">${esc(c.folio)}</span></span>
          <div class="fecha-cita">${esc(c.fechaTexto)}</div>
          <div class="texto-2" style="font-size:14px"><span translate="no">${esc(c.vehiculo || "")}</span>${c.tipoServicio ? " · " + esc(c.tipoServicio) : ""} · KARMA <span translate="no">${esc(c.sucursal)}</span></div>
          ${c.enganche ? `<div class="texto-3" style="font-size:13px">Enganche indicado: <span translate="no">${precio(c.enganche)}</span></div>` : ""}
        </div>
        <div style="display:grid; gap:8px; justify-items:end">${pill(clase, c.etiqueta)}${c.cancelable ? `<button class="btn btn--fantasma btn--chico" type="button" data-cancelar-cita="${c.id}">Cancelar</button>` : ""}</div>
      </article>`;
  }
  const vacio = (ic, titulo, texto, enlace) => `<div class="vacio">${icono(ic, "icono-grande")}<h3>${titulo}</h3><p>${texto}</p>${enlace ? `<a class="btn btn--primario" href="${enlace[0]}">${enlace[1]}</a>` : ""}</div>`;

  function pintarPerfil() {
    const p = perfil;
    const ahora = Date.now();
    const proximas = p.citas.filter(c => c.estado !== "cancelada" && new Date(c.fecha.replace(" ", "T")).getTime() > ahora);
    const nuevas = p.notificaciones.filter(n => !n.leida).length;
    $('[data-est="pedidos"]').textContent = p.pedidos.length;
    $('[data-est="citas"]').textContent = proximas.length;
    $('[data-est="favoritos"]').textContent = p.favoritos.length;
    $('[data-est="notificaciones"]').textContent = nuevas;
    const contador = $("#contadorNotif");
    contador.textContent = nuevas;
    contador.classList.toggle("oculto", !nuevas);

    // Resumen
    const ultimo = p.pedidos[0];
    $("#resumenPerfil").innerHTML = `
      <div class="rejilla rejilla--2" style="gap:16px">
        <div class="tarjeta-formulario" style="padding:24px"><span class="mayus texto-3">Próxima cita</span>
          ${proximas.length ? (() => { const c = proximas[proximas.length - 1]; return `<h3 style="font-size:20px; margin:8px 0 4px">${esc(c.tipoTexto)}</h3><p class="texto-2">${esc(c.fechaTexto)} · KARMA <span translate="no">${esc(c.sucursal)}</span></p><p class="texto-3" translate="no">${esc(c.vehiculo || "")}</p>`; })()
            : `<p class="texto-2" style="margin:8px 0 14px">No tienes citas próximas.</p><a class="btn btn--secundario btn--chico" href="agendar.php">Agendar cita</a>`}</div>
        <div class="tarjeta-formulario" style="padding:24px"><span class="mayus texto-3">Último pedido</span>
          ${ultimo ? `<h3 style="font-size:20px; margin:8px 0 4px" translate="no">${esc(ultimo.folio)}</h3><p class="texto-2"><span translate="no">${precio(ultimo.total, true)}</span> · ${esc(ultimo.fechaTexto)}</p><div style="margin-top:8px">${pill(ultimo.clase, ultimo.etiqueta)}</div>`
            : `<p class="texto-2" style="margin:8px 0 14px">Aún no has comprado en línea.</p><a class="btn btn--secundario btn--chico" href="refacciones.php">Ver refacciones</a>`}</div>
      </div>
      ${p.credito ? `<div class="tarjeta-formulario" style="padding:24px; margin-top:16px"><span class="mayus texto-3">Tu crédito KARMA</span><h3 style="font-size:20px; margin:8px 0">${esc(p.credito.articulo || "Crédito vigente")}</h3><p class="texto-2">Abonos pagados: <strong>${p.credito.pagados} de ${p.credito.totales}</strong> · Mensualidad: <strong translate="no">${precio(p.credito.abono)}</strong> · Adeudo total: <strong translate="no">${precio(p.credito.adeudo)}</strong></p></div>` : ""}
      <div style="margin-top:22px"><h3 style="font-size:18px; margin-bottom:6px">Notificaciones recientes</h3>${p.notificaciones.slice(0, 3).map(notifHTML).join("") || '<p class="texto-3">Sin notificaciones.</p>'}</div>`;

    $("#listaPedidos").innerHTML = p.pedidos.length ? p.pedidos.map(pedidoHTML).join("") : vacio("carrito", "Sin pedidos en línea", "Cuando compres refacciones o accesorios aparecerán aquí con su estado.", ["refacciones.php", "Ver refacciones"]);
    $("#listaCitas").innerHTML = p.citas.length ? p.citas.map(citaHTML).join("") : vacio("calendario", "Sin citas", "Agenda una visita, aparta un vehículo o abre una orden de servicio.", ["agendar.php", "Agendar cita"]);
    $("#listaFavoritos").innerHTML = p.favoritos.length ? p.favoritos.map(v => tarjetaVehiculo(v, p.favoritos.map(f => f.id))).join("") : `<div style="grid-column:1/-1">${vacio("corazon", "Sin vehículos de interés", "Toca el corazón en cualquier modelo para guardarlo aquí.", ["vehiculos.php", "Explorar modelos"])}</div>`;
    revelar($("#listaFavoritos"));

    // Historial: compras en caja (tabla ventas del POS), garantías y crédito
    const compras = p.compras.length ? `<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Folio</th><th>Fecha</th><th>Sucursal</th><th>Artículos</th><th class="num">Total</th></tr></thead><tbody>${p.compras.map(v => `<tr><td translate="no">${esc(v.folio)}</td><td>${esc(v.fecha)}</td><td translate="no">${esc(v.sucursal)}</td><td>${esc(v.articulos)}</td><td class="num" translate="no">${precio(v.total, true)}</td></tr>`).join("")}</tbody></table></div>` : `<p class="texto-3">No hay compras en sucursal asociadas a tu correo.</p>`;
    const garantias = p.garantias.length ? `<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Artículo</th><th>Vence</th><th>Estado</th></tr></thead><tbody>${p.garantias.map(g => `<tr><td translate="no">${esc(g.articulo)} ${esc(g.anio || "")}</td><td>${esc(g.vence)}</td><td>${pill(g.estado === "vigente" ? "pagado" : "cancelado", g.estado)}</td></tr>`).join("")}</tbody></table></div>` : `<p class="texto-3">Sin garantías registradas.</p>`;
    $("#listaHistorial").innerHTML = `<h3 style="font-size:18px; margin:4px 0 12px">Compras en sucursal</h3>${compras}<h3 style="font-size:18px; margin:28px 0 12px">Garantías</h3>${garantias}`;

    $("#listaSolicitudes").innerHTML = p.solicitudes.length
      ? `<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Folio</th><th>Tipo</th><th>Asunto</th><th>Fecha</th><th>Estado</th></tr></thead><tbody>${p.solicitudes.map(s => `<tr><td translate="no">${esc(s.folio)}</td><td>${esc(s.tipo)}</td><td>${esc(s.asunto || "—")}</td><td>${esc(s.fecha)}</td><td>${pill(s.estado === "nueva" ? "info" : "pagado", s.estado.replace("_", " "))}</td></tr>`).join("")}</tbody></table></div>`
      : vacio("mensaje", "Sin solicitudes", "Tus solicitudes de información, cotizaciones y mensajes aparecerán aquí.", ["contacto.php", "Contactar a un asesor"]);
    $("#listaNotificaciones").innerHTML = p.notificaciones.length ? p.notificaciones.map(notifHTML).join("") : vacio("campana", "Sin notificaciones", "Te avisaremos aquí del estado de tus pedidos y citas.");
  }
  function notifHTML(n) {
    return `<div class="notificacion${n.leida ? "" : " nueva"}"><span class="punto"></span><div><strong>${esc(n.titulo)}</strong><p>${esc(n.mensaje || "")}</p><small>${esc(n.fecha)}${n.enlace ? ` · <a class="enlace" href="${esc(n.enlace)}">Ver</a>` : ""}</small></div></div>`;
  }
  async function cargarPerfil() {
    try { perfil = await api("perfil"); pintarPerfil(); }
    catch (e) { if (e.estado === 401) window.location.href = "login.php?volver=perfil.php"; else aviso(e.message, "error"); }
  }

  function iniciarPerfil() {
    if (!$("#panel-resumen")) return;
    const pestanas = $$("[data-pestana]");
    const activar = (nombre, actualizarHash = true) => {
      if (!$(`#panel-${nombre}`)) nombre = "resumen";
      pestanas.forEach(p => { p.classList.toggle("activa", p.dataset.pestana === nombre); p.setAttribute("aria-selected", String(p.dataset.pestana === nombre)); });
      $$(".panel-perfil").forEach(p => p.classList.toggle("activo", p.id === `panel-${nombre}`));
      if (actualizarHash) history.replaceState(null, "", "#" + nombre);
      if (nombre === "notificaciones" && perfil?.notificaciones.some(n => !n.leida)) {
        api("notificaciones_leidas", { metodo: "POST" }).then(() => { perfil.notificaciones.forEach(n => { n.leida = true; }); setTimeout(pintarPerfil, 1500); }).catch(() => {});
      }
    };
    pestanas.forEach(p => p.addEventListener("click", () => activar(p.dataset.pestana)));
    window.addEventListener("hashchange", () => activar(location.hash.slice(1), false));
    activar(location.hash.slice(1) || "resumen", false);

    // Mis datos (si cambia el correo se pide la contraseña actual)
    const formDatos = $("#formDatos");
    const emailOriginal = JSON.parse($("#datosPerfil").textContent).email;
    formDatos.email.addEventListener("input", () => $("#campoPassEmail").classList.toggle("oculto", formDatos.email.value.trim().toLowerCase() === emailOriginal.toLowerCase()));
    formDatos.addEventListener("submit", async (e) => {
      e.preventDefault();
      const boton = $("[type=submit]", formDatos);
      boton.classList.add("cargando");
      const datos = Object.fromEntries(new FormData(formDatos).entries());
      ["notif_email", "notif_sms", "notif_promociones"].forEach(k => { datos[k] = formDatos[k].checked; });
      try {
        const r = await api("perfil_actualizar", { metodo: "POST", datos });
        mensaje($("#pfMensaje"), r.mensaje, "ok");
        aviso(r.mensaje, "ok");
      } catch (err) { mensaje($("#pfMensaje"), err.message); }
      finally { boton.classList.remove("cargando"); }
    });

    // Seguridad
    const formPass = $("#formPassword");
    formPass.addEventListener("submit", async (e) => {
      e.preventDefault();
      if (formPass.nueva.value !== formPass.confirmacion.value) return mensaje($("#psMensaje"), "Las contraseñas nuevas no coinciden.");
      const boton = $("[type=submit]", formPass);
      boton.classList.add("cargando");
      try {
        const r = await api("cambiar_password", { metodo: "POST", datos: Object.fromEntries(new FormData(formPass).entries()) });
        formPass.reset();
        mensaje($("#psMensaje"), r.mensaje, "ok");
      } catch (err) { mensaje($("#psMensaje"), err.message); }
      finally { boton.classList.remove("cargando"); }
    });

    // Cancelar pedidos y citas desde el perfil
    document.addEventListener("click", async (e) => {
      const cp = e.target.closest("[data-cancelar-pedido]");
      const cc = e.target.closest("[data-cancelar-cita]");
      if (!cp && !cc) return;
      if (!confirm(cp ? "¿Cancelar este pedido? Las piezas regresarán al inventario de la sucursal." : "¿Cancelar esta cita?")) return;
      try {
        const r = cp ? await api("cancelar_pedido", { metodo: "POST", datos: { id_orden: Number(cp.dataset.cancelarPedido) } })
                     : await api("cancelar_cita", { metodo: "POST", datos: { id_cita: Number(cc.dataset.cancelarCita) } });
        aviso(r.mensaje, "ok");
        cargarPerfil();
      } catch (err) { aviso(err.message, "error"); }
    });
    $("#marcarLeidas")?.addEventListener("click", async () => {
      await api("notificaciones_leidas", { metodo: "POST" }).catch(() => {});
      cargarPerfil();
    });
    cargarPerfil();
  }

  document.addEventListener("DOMContentLoaded", () => {
    iniciarLogin();
    iniciarRegistro();
    iniciarPerfil();
  });
})();
