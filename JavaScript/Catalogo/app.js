/* =====================================================================================
   KARMA · Catálogo — núcleo de JavaScript (se carga en todas las páginas)
   - API: llamadas a PHP/Catalogo/api.php con token CSRF
   - Tema claro/oscuro, menús, buscador en vivo, selector de sucursal, idioma (traductor del proyecto)
   - Tarjetas de producto reutilizables, carrito, favoritos y solicitud de información
   El JavaScript solo mejora la experiencia: todas las reglas (stock, precios, sesiones) se validan en PHP.
   ===================================================================================== */
(function () {
  "use strict";

  const config = window.KARMA_CONFIG || {};
  const $ = (sel, ctx = document) => ctx.querySelector(sel);
  const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));

  // ===== UTILIDADES =====
  const formato0 = new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN", maximumFractionDigits: 0 });
  const formato2 = new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN", minimumFractionDigits: 2, maximumFractionDigits: 2 });
  function precio(n, centavos = false) { return (centavos ? formato2 : formato0).format(Number(n) || 0); }
  function esc(texto) {
    return String(texto ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }
  function icono(nombre, clase = "icono") {
    const trazos = (config.iconos || {})[nombre] || (config.iconos || {}).info || "";
    return `<svg class="${clase}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${trazos}</svg>`;
  }
  function retrasar(fn, ms = 250) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; }

  // ===== API =====
  async function api(accion, { metodo = "GET", datos = null, params = {} } = {}) {
    const url = new URL(config.api || "api.php", window.location.href);
    url.searchParams.set("action", accion);
    Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== "" && v !== false) url.searchParams.set(k, v); });
    const opciones = { method: metodo, headers: { Accept: "application/json" }, credentials: "same-origin" };
    if (metodo !== "GET") {
      opciones.headers["Content-Type"] = "application/json";
      opciones.headers["X-CSRF-Token"] = config.csrf || $('meta[name="csrf-token"]')?.content || "";
      opciones.body = JSON.stringify(datos || {});
    }
    let respuesta, json;
    try {
      respuesta = await fetch(url, opciones);
      json = await respuesta.json();
    } catch (_) {
      json = { ok: false, error: "No fue posible conectar con el servidor. Revisa que XAMPP (Apache y MySQL) esté encendido." };
    }
    if (!respuesta || !respuesta.ok || json.ok === false) {
      const error = new Error(json.error || "No se pudo completar la acción.");
      error.estado = respuesta ? respuesta.status : 0;
      error.datos = json;
      throw error;
    }
    return json;
  }

  // Si la acción necesita sesión, manda a login y luego regresa a esta página
  function irALogin() {
    const volver = window.location.pathname.split("/").pop() + window.location.search;
    window.location.href = "login.php?volver=" + encodeURIComponent(volver || "index.php");
  }

  // ===== AVISOS (toasts) =====
  function aviso(mensaje, tipo = "ok", enlace = null) {
    const caja = $("#avisos");
    if (!caja) return alert(mensaje);
    const iconos = { ok: "check-circulo", error: "alerta", info: "info" };
    const el = document.createElement("div");
    el.className = `aviso aviso--${tipo}`;
    el.setAttribute("role", tipo === "error" ? "alert" : "status");
    el.innerHTML = `${icono(iconos[tipo] || "info")}<div class="texto">${esc(mensaje)}${enlace ? `<br><a href="${esc(enlace.url)}">${esc(enlace.texto)} →</a>` : ""}</div><button class="cerrar" type="button" aria-label="Cerrar aviso">${icono("cerrar", "icono icono--chico")}</button>`;
    caja.appendChild(el);
    const quitar = () => { el.classList.add("saliendo"); setTimeout(() => el.remove(), 260); };
    el.querySelector(".cerrar").addEventListener("click", quitar);
    setTimeout(quitar, tipo === "error" ? 7000 : 4800);
  }

  // ===== TEMA CLARO / OSCURO =====
  function aplicarTema(tema) {
    document.documentElement.setAttribute("data-theme", tema);
    document.body.classList.toggle("dark", tema === "dark"); // el visor 3D del POS escucha esta clase
    $('meta[name="theme-color"]')?.setAttribute("content", tema === "dark" ? "#0a0a0b" : "#10213f");
    const texto = tema === "dark" ? "Cambiar a modo claro" : "Cambiar a modo oscuro";
    $("#btnTema")?.setAttribute("aria-label", texto);
    // Botón del menú móvil (en pantallas angostas el de la cabecera se oculta)
    $$("[data-alternar-tema] [data-texto-tema]").forEach(s => { s.textContent = texto; });
  }
  function iniciarTema() {
    aplicarTema(document.documentElement.getAttribute("data-theme") || "light");
    $$("#btnTema, [data-alternar-tema]").forEach(boton => boton.addEventListener("click", () => {
      const nuevo = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
      try { localStorage.setItem("karma_catalogo_tema", nuevo); } catch (_) {}
      aplicarTema(nuevo);
    }));
  }

  // ===== CABECERA: sombra, menú de modelos, submenús, cuenta =====
  function iniciarCabecera() {
    const cabecera = $("#cabecera");
    const alHacerScroll = () => cabecera?.classList.toggle("con-sombra", window.scrollY > 8);
    window.addEventListener("scroll", alHacerScroll, { passive: true });
    alHacerScroll();

    const botonMega = $("[data-mega]");
    const mega = $("#megaModelos");
    const cargarMiniaturas = (panel) => $$("img[data-src]", panel).forEach(img => { img.src = img.dataset.src; img.removeAttribute("data-src"); });
    const abrirMega = (abrir) => {
      if (!mega || !botonMega) return;
      mega.classList.toggle("abierto", abrir);
      botonMega.setAttribute("aria-expanded", String(abrir));
      if (abrir) cargarMiniaturas($(".mega-modelos:not(.oculto)", mega));
    };
    botonMega?.addEventListener("click", (e) => { e.stopPropagation(); abrirMega(!mega.classList.contains("abierto")); });
    $$("[data-mega-marca]").forEach(btn => btn.addEventListener("mouseenter", () => btn.click()));
    $$("[data-mega-marca]").forEach(btn => btn.addEventListener("click", () => {
      $$("[data-mega-marca]").forEach(b => b.classList.toggle("activo", b === btn));
      $$("[data-mega-panel]").forEach(p => {
        const visible = p.dataset.megaPanel === btn.dataset.megaMarca;
        p.classList.toggle("oculto", !visible);
        if (visible) cargarMiniaturas(p);
      });
    }));
    mega?.addEventListener("click", e => e.stopPropagation());

    // Submenú de Servicios y menú de la cuenta
    $$("[data-submenu], [data-menu-cuenta]").forEach(btn => {
      const menu = btn.nextElementSibling;
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        const abrir = !menu.classList.contains("abierto");
        cerrarMenus();
        menu.classList.toggle("abierto", abrir);
        btn.setAttribute("aria-expanded", String(abrir));
      });
    });
    function cerrarMenus() {
      $$(".submenu.abierto").forEach(m => m.classList.remove("abierto"));
      $$("[data-submenu], [data-menu-cuenta]").forEach(b => b.setAttribute("aria-expanded", "false"));
      abrirMega(false);
    }
    document.addEventListener("click", cerrarMenus);
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") cerrarMenus(); });

    // Cerrar sesión del cliente (no afecta la sesión del Punto de Venta)
    $$("[data-cerrar-sesion]").forEach(a => a.addEventListener("click", async (e) => {
      e.preventDefault();
      try { await api("logout", { metodo: "POST" }); } catch (_) {}
      window.location.href = "index.php";
    }));
  }

  // ===== MENÚ MÓVIL =====
  function iniciarCajon() {
    const cajon = $("#cajonMenu");
    if (!cajon) return;
    const abrir = (si) => {
      cajon.classList.toggle("abierto", si);
      cajon.setAttribute("aria-hidden", String(!si));
      document.body.style.overflow = si ? "hidden" : "";
    };
    $$("[data-abrir-menu]").forEach(b => b.addEventListener("click", () => abrir(true)));
    $$("[data-cerrar-cajon]", cajon).forEach(b => b.addEventListener("click", () => abrir(false)));
    cajon.addEventListener("click", e => { if (e.target === cajon) abrir(false); });
    document.addEventListener("keydown", e => { if (e.key === "Escape" && cajon.classList.contains("abierto")) abrir(false); });
    $$("[data-abrir-sucursales]", cajon).forEach(b => b.addEventListener("click", () => abrir(false)));
  }

  // ===== BUSCADOR GLOBAL CON SUGERENCIAS EN VIVO =====
  function iniciarBusqueda() {
    const capa = $("#capaBusqueda");
    const entrada = $("#entradaBusqueda");
    const lista = $("#sugerenciasBusqueda");
    if (!capa || !entrada) return;
    let indice = -1;
    const abrir = (si) => {
      capa.classList.toggle("abierta", si);
      capa.setAttribute("aria-hidden", String(!si));
      document.body.style.overflow = si ? "hidden" : "";
      if (si) setTimeout(() => entrada.focus(), 60);
    };
    $$("[data-abrir-busqueda]").forEach(b => b.addEventListener("click", () => abrir(true)));
    $$("[data-cerrar-busqueda]").forEach(b => b.addEventListener("click", () => abrir(false)));
    capa.addEventListener("click", e => { if (e.target === capa) abrir(false); });
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && capa.classList.contains("abierta")) abrir(false);
      const escribiendo = /input|textarea|select/i.test(document.activeElement?.tagName || "");
      if (e.key === "/" && !escribiendo) { e.preventDefault(); abrir(true); }
    });

    const pintar = (datos, q) => {
      indice = -1;
      if (!q) { lista.innerHTML = ""; return; }
      const productos = datos.productos || [];
      const paginas = datos.paginas || [];
      if (!productos.length && !paginas.length) {
        lista.innerHTML = `<p class="texto-2">Sin resultados para “${esc(q)}”. Intenta con otro modelo, pieza o código.</p>`;
        return;
      }
      lista.innerHTML = `
        ${productos.length ? `<div><h4>Productos</h4>${productos.map(p => `
          <a class="resultado-busqueda" href="${esc(p.url)}">
            <img src="${esc(p.esVehiculo ? p.miniatura : p.imagen)}" alt="" loading="lazy">
            <span class="info"><strong>${esc(p.titulo)} ${p.anio ? `<span class="texto-3">${p.anio}</span>` : ""}</strong>
            <span>${esc(p.esVehiculo ? (p.subcategoria || p.tipo) : `${p.marca} · ${p.compatibilidad || p.subcategoria || ""}`)} · <span class="disp disp--${p.estadoStock}">${esc(p.textoStock)}</span></span></span>
            <strong class="precio">${esc(p.precioTexto)}</strong>
          </a>`).join("")}</div>` : ""}
        ${paginas.length ? `<div><h4>Páginas y servicios</h4>${paginas.map(pg => `
          <a class="resultado-busqueda" href="${esc(pg.url)}">${icono("chevron-der")}<span class="info"><strong>${esc(pg.titulo)}</strong></span></a>`).join("")}</div>` : ""}
        <a class="enlace" href="buscar.php?q=${encodeURIComponent(q)}">Ver todos los resultados de “${esc(q)}” →</a>`;
    };
    const buscar = retrasar(async () => {
      const q = entrada.value.trim();
      $("#busquedasSugeridas")?.classList.toggle("oculto", q.length > 0);
      if (q.length < 2) { pintar({}, ""); return; }
      try { pintar(await api("buscar", { params: { q } }), q); } catch (e) { lista.innerHTML = `<p class="texto-2">${esc(e.message)}</p>`; }
    }, 220);
    entrada.addEventListener("input", buscar);
    entrada.addEventListener("keydown", (e) => {
      const items = $$(".resultado-busqueda", lista);
      if (!items.length || !["ArrowDown", "ArrowUp", "Enter"].includes(e.key)) return;
      if (e.key === "Enter" && indice >= 0) { e.preventDefault(); items[indice].click(); return; }
      if (e.key === "Enter") return;
      e.preventDefault();
      indice = (indice + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length;
      items.forEach((it, i) => it.classList.toggle("activo", i === indice));
      items[indice].scrollIntoView({ block: "nearest" });
    });
  }

  // ===== SELECTOR DE SUCURSAL =====
  function iniciarSucursales() {
    const modal = $("#modalSucursales");
    if (!modal) return;
    $$("[data-abrir-sucursales]").forEach(b => b.addEventListener("click", () => modal.showModal()));
    $$("[data-cerrar-modal]").forEach(b => b.addEventListener("click", () => b.closest("dialog")?.close()));
    $$("dialog.modal").forEach(d => d.addEventListener("click", e => { if (e.target === d) d.close(); }));
    $$("[data-elegir-sucursal]").forEach(b => b.addEventListener("click", () => cambiarSucursal(Number(b.dataset.elegirSucursal))));
  }
  // Cambia la sucursal en el servidor y recarga: todo el inventario mostrado se vuelve a consultar
  async function cambiarSucursal(id) {
    if (Number(id) === Number(config.sucursal?.id)) { $("#modalSucursales")?.close(); return; }
    try {
      const r = await api("set_sucursal", { metodo: "POST", datos: { id_sucursal: id } });
      try { sessionStorage.setItem("karma_aviso", r.mensaje + (r.carritoConProblemas ? " Revisa tu carrito: algunas piezas tienen otra disponibilidad aquí." : "")); } catch (_) {}
      window.location.reload();
    } catch (e) { aviso(e.message, "error"); }
  }
  // Muestra el aviso pendiente después de recargar (por ejemplo, al cambiar de sucursal)
  function avisoPendiente() {
    try {
      const m = sessionStorage.getItem("karma_aviso");
      if (m) { sessionStorage.removeItem("karma_aviso"); aviso(m, "info"); }
    } catch (_) {}
  }

  // ===== IDIOMA (reutiliza JavaScript/Traduccion/traductor.js del proyecto) =====
  function iniciarIdioma() {
    const boton = $("#btnIdioma");
    const marcar = () => {
      const idioma = window.KarmaTraductor?.getIdioma() || "es";
      $$(".idioma .op").forEach(op => op.classList.toggle("activo", op.dataset.lang === idioma));
    };
    boton?.addEventListener("click", () => {
      if (!window.KarmaTraductor) return aviso("El traductor no está disponible en este momento.", "error");
      window.KarmaTraductor.alternar();
    });
    document.addEventListener("karma:idioma", marcar);
    let avisado = false;
    document.addEventListener("karma:traduccion-error", (e) => {
      if (avisado) return;
      avisado = true;
      aviso("No se pudo traducir la página: " + (e.detail?.mensaje || "servicio no disponible") + ". Se mostrará en español.", "error");
      window.KarmaTraductor?.setIdioma("es");
    });
    marcar();
  }

  // ===== TARJETAS DE PRODUCTO (las usan inicio, catálogo, búsqueda y detalle) =====
  function tarjetaVehiculo(p, favoritos = []) {
    const fav = favoritos.includes(p.id);
    const sucursal = esc(config.sucursal?.nombre || "");
    return `
      <article class="tarjeta revelar${p.stock <= 0 ? " tarjeta--agotada" : ""}">
        <a class="tarjeta-media" href="${esc(p.url)}" aria-label="Ver ${esc(p.titulo)}">
          <!-- IMAGEN DEL VEHÍCULO: productos_web.imagen (assets/Catalogo/vehiculos/{marca}/{modelo}.webp) -->
          <img src="${esc(p.imagen)}" alt="${esc(p.titulo)} ${p.anio || ""}" loading="lazy" width="600" height="375">
        </a>
        <div class="tarjeta-insignias">
          <span class="insignia insignia--marca" translate="no">${esc(p.marca)}</span>
          ${p.destacado ? `<span class="insignia">Destacado</span>` : ""}
          ${/eléctric/i.test(p.motor || "") ? `<span class="insignia">Eléctrico</span>` : ""}
        </div>
        <button class="btn-favorito${fav ? " activo" : ""}" type="button" data-favorito="${p.id}" aria-pressed="${fav}" aria-label="Guardar ${esc(p.titulo)} en vehículos de interés">${icono("corazon")}</button>
        <div class="tarjeta-cuerpo">
          <span class="tarjeta-marca"><span translate="no">${esc(p.marca)}</span> · ${esc(p.subcategoria || (p.tipo === "moto" ? "Motocicleta" : "Automóvil"))}</span>
          <h3><a href="${esc(p.url)}" translate="no">${esc(p.titulo)}</a><span class="anio">${p.anio || ""}</span></h3>
          <div class="tarjeta-resumen">
            ${p.motor ? `<span>${icono("motor")}${esc(p.motor)}</span>` : ""}
            ${p.potencia ? `<span>${icono("velocimetro")}${esc(p.potencia)}</span>` : ""}
            ${p.traccion ? `<span>${icono("engranaje")}${esc(p.traccion)}</span>` : ""}
          </div>
          <div class="tarjeta-precio"><small>Desde</small><span class="precio" translate="no">${esc(p.precioTexto)}</span><small>MXN</small></div>
          <div class="tarjeta-disp"><span class="disp disp--${p.estadoStock}">${esc(p.textoStock)}</span><span>en ${sucursal}</span></div>
          <div class="tarjeta-acciones">
            <a class="btn btn--primario ancho" href="${esc(p.url)}">Ver modelo ${icono("flecha", "icono icono--chico flecha")}</a>
            <a class="btn btn--secundario" href="agendar.php?tipo=visita&id=${p.id}">Agendar cita</a>
            <a class="btn btn--secundario" href="agendar.php?tipo=apartado&id=${p.id}">Apartar</a>
          </div>
        </div>
      </article>`;
  }

  function tarjetaPieza(p) {
    const sucursal = esc(config.sucursal?.nombre || "");
    const agotado = p.stock <= 0;
    return `
      <article class="tarjeta revelar${agotado ? " tarjeta--agotada" : ""}">
        <a class="tarjeta-media tarjeta-media--pieza" href="${esc(p.url)}" aria-label="Ver ${esc(p.nombre)}">
          <!-- IMAGEN DE LA PIEZA: productos_web.imagen (assets/Catalogo/refacciones/... o accesorios/...) -->
          <img src="${esc(p.imagen)}" alt="${esc(p.nombre)}" loading="lazy" width="500" height="375">
        </a>
        <div class="tarjeta-insignias">
          <span class="insignia insignia--marca" translate="no">${esc(p.marca)}</span>
          ${p.subcategoria ? `<span class="insignia">${esc(p.subcategoria)}</span>` : ""}
        </div>
        <div class="tarjeta-cuerpo">
          <span class="tarjeta-marca" translate="no">${esc(p.codigo)}</span>
          <h3><a href="${esc(p.url)}">${esc(p.nombre)}</a></h3>
          <p class="tarjeta-compat">Compatible con <strong translate="no">${esc(p.compatibilidad || `${p.marca} ${p.modelo || ""}`)}</strong>${p.motorCompatible ? ` · Motor <span translate="no">${esc(p.motorCompatible)}</span>` : ""}</p>
          <div class="tarjeta-precio"><span class="precio" translate="no">${esc(p.precioTexto)}</span><small>MXN</small></div>
          <div class="tarjeta-disp"><span class="disp disp--${p.estadoStock}">${esc(p.textoStock)}</span><span>en ${sucursal}</span></div>
          <div class="tarjeta-acciones">
            <a class="btn btn--secundario" href="${esc(p.url)}">Ver detalle</a>
            <button class="btn btn--primario" type="button" data-agregar-carrito="${p.id}" ${agotado ? "disabled" : ""}>${agotado ? "Agotado" : `${icono("carrito", "icono icono--chico")} Agregar al carrito`}</button>
          </div>
        </div>
      </article>`;
  }

  function tarjetasEsqueleto(n = 6) {
    return Array.from({ length: n }, () => `
      <div class="tarjeta-esqueleto" aria-hidden="true"><div class="esqueleto esqueleto--media"></div>
      <div class="lineas"><div class="esqueleto linea" style="width:40%"></div><div class="esqueleto linea" style="width:75%;height:18px"></div>
      <div class="esqueleto linea" style="width:60%"></div><div class="esqueleto linea" style="width:50%;height:22px"></div></div></div>`).join("");
  }

  // ===== CARRITO =====
  function actualizarContadorCarrito(n) {
    $$("[data-contador-carrito]").forEach(c => { c.textContent = n > 0 ? n : ""; c.dataset.valor = n; });
  }
  async function agregarAlCarrito(idProducto, cantidad = 1, boton = null) {
    boton?.classList.add("cargando");
    try {
      const r = await api("carrito_agregar", { metodo: "POST", datos: { id_producto: idProducto, cantidad } });
      actualizarContadorCarrito(r.carrito);
      aviso(r.mensaje, "ok", { url: "carrito.php", texto: "Ver carrito" });
      return true;
    } catch (e) {
      aviso(e.message, "error");
      return false;
    } finally {
      boton?.classList.remove("cargando");
    }
  }

  // ===== FAVORITOS (vehículos de interés) =====
  async function alternarFavorito(boton) {
    if (!config.cliente) {
      aviso("Inicia sesión para guardar vehículos de interés.", "info", { url: "login.php?volver=" + encodeURIComponent(location.pathname.split("/").pop() + location.search), texto: "Iniciar sesión" });
      return;
    }
    try {
      const r = await api("favorito", { metodo: "POST", datos: { id_producto: Number(boton.dataset.favorito) } });
      $$(`[data-favorito="${boton.dataset.favorito}"]`).forEach(b => { b.classList.toggle("activo", r.favorito); b.setAttribute("aria-pressed", String(r.favorito)); });
      aviso(r.mensaje, "ok");
    } catch (e) { aviso(e.message, "error"); }
  }

  // ===== EVENTOS DELEGADOS (sirven también para tarjetas creadas después) =====
  function iniciarDelegados() {
    document.addEventListener("click", (e) => {
      const agregar = e.target.closest("[data-agregar-carrito]");
      if (agregar && !agregar.disabled) {
        e.preventDefault();
        const cantidadEl = agregar.dataset.cantidadDe ? document.querySelector(agregar.dataset.cantidadDe) : null;
        agregarAlCarrito(Number(agregar.dataset.agregarCarrito), cantidadEl ? Number(cantidadEl.value) || 1 : 1, agregar);
        return;
      }
      const fav = e.target.closest("[data-favorito]");
      if (fav) { e.preventDefault(); alternarFavorito(fav); return; }
      const paso = e.target.closest("[data-paso-cantidad]");
      if (paso) {
        const input = paso.parentElement.querySelector("input");
        const max = Number(input.max) || 20;
        input.value = Math.min(max, Math.max(Number(input.min) || 1, (Number(input.value) || 1) + Number(paso.dataset.pasoCantidad)));
        input.dispatchEvent(new Event("change", { bubbles: true }));
      }
    });
  }

  // ===== ANIMACIÓN SUAVE AL APARECER =====
  let observadorRevelar = null;
  function revelar(ctx = document) {
    const elementos = $$(".revelar:not(.visible)", ctx);
    if (!("IntersectionObserver" in window)) { elementos.forEach(el => el.classList.add("visible")); return; }
    observadorRevelar = observadorRevelar || new IntersectionObserver((entradas) => {
      entradas.forEach(en => { if (en.isIntersecting) { en.target.classList.add("visible"); observadorRevelar.unobserve(en.target); } });
    }, { rootMargin: "0px 0px -40px 0px", threshold: 0.05 });
    elementos.forEach(el => observadorRevelar.observe(el));
  }

  // ===== CARRUSEL HORIZONTAL GENÉRICO =====
  function iniciarCarrusel(contenedor) {
    const pista = $(".carrusel-pista", contenedor);
    const [izq, der] = $$(".carrusel-flechas button", contenedor);
    if (!pista) return;
    const actualizar = () => {
      if (izq) izq.disabled = pista.scrollLeft < 8;
      if (der) der.disabled = pista.scrollLeft + pista.clientWidth >= pista.scrollWidth - 8;
    };
    const mover = (dir) => pista.scrollBy({ left: dir * pista.clientWidth * 0.85, behavior: "smooth" });
    izq?.addEventListener("click", () => mover(-1));
    der?.addEventListener("click", () => mover(1));
    pista.addEventListener("scroll", retrasar(actualizar, 60), { passive: true });
    window.addEventListener("resize", retrasar(actualizar, 120));
    actualizar();
    return actualizar;
  }

  // ===== CRÉDITO (misma fórmula que calcularCredito() del Punto de Venta: anualidad + comisión por apertura) =====
  function calcularCredito({ precio: monto, engancheMonto = 0, plazoMeses = 48, tasaAnualPct = config.tasaAnual ?? 18 }) {
    const baseFinanciar = Math.max(monto - (engancheMonto || 0), 0);
    const comisionApertura = baseFinanciar * (config.comisionApertura ?? 0.02);
    const montoFinanciado = baseFinanciar + comisionApertura;
    const i = (Number(tasaAnualPct) || 0) / 100 / 12;
    const n = Number(plazoMeses) || 1;
    const mensualidad = i > 0 ? montoFinanciado * (i * Math.pow(1 + i, n)) / (Math.pow(1 + i, n) - 1) : montoFinanciado / n;
    const montoFinal = mensualidad * n;
    return { baseFinanciar, comisionApertura, montoFinanciado, i, n, mensualidad, montoFinal, montoInteres: montoFinal - montoFinanciado };
  }
  // Tabla de amortización mes a mes (cuota, capital, interés, saldo)
  function tablaAmortizacion(calc) {
    let saldo = calc.montoFinanciado;
    const filas = [];
    for (let mes = 1; mes <= calc.n; mes++) {
      const interes = saldo * calc.i;
      const capital = calc.mensualidad - interes;
      saldo = Math.max(saldo - capital, 0);
      filas.push(`<tr><td>${mes}</td><td class="num">${precio(calc.mensualidad, true)}</td><td class="num">${precio(capital, true)}</td><td class="num">${precio(interes, true)}</td><td class="num">${precio(saldo, true)}</td></tr>`);
    }
    return `<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Pago</th><th class="num">Mensualidad</th><th class="num">Capital</th><th class="num">Interés</th><th class="num">Saldo</th></tr></thead><tbody>${filas.join("")}</tbody></table></div>`;
  }

  // ===== ARRANQUE =====
  document.addEventListener("DOMContentLoaded", () => {
    iniciarTema();
    iniciarCabecera();
    iniciarCajon();
    iniciarBusqueda();
    iniciarSucursales();
    iniciarIdioma();
    iniciarDelegados();
    avisoPendiente();
    revelar();
    $$("[data-carrusel]").forEach(iniciarCarrusel);
  });

  // Funciones públicas para los demás archivos de JavaScript del catálogo
  window.KARMA = Object.freeze({
    config, $, $$, api, esc, precio, icono, aviso, irALogin, retrasar, revelar,
    tarjetaVehiculo, tarjetaPieza, tarjetasEsqueleto, agregarAlCarrito, actualizarContadorCarrito,
    cambiarSucursal, iniciarCarrusel, calcularCredito, tablaAmortizacion
  });
})();
