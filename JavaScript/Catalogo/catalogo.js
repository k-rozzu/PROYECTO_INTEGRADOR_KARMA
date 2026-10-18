/* =====================================================================================
   KARMA · Catálogo — páginas de listado (Modelos, Refacciones, Accesorios) y página de búsqueda.
   Carga los productos de la sucursal elegida (api.php?action=productos) y filtra/ordena en el navegador
   para que los resultados cambien al instante. La URL se actualiza para poder compartir la búsqueda.
   ===================================================================================== */
(function () {
  "use strict";
  const { $, $$, api, esc, icono, tarjetaVehiculo, tarjetaPieza, tarjetasEsqueleto, revelar, aviso, retrasar } = window.KARMA;

  // Quita acentos y pasa a minúsculas para comparar ("batería" = "bateria")
  const normalizar = (t) => String(t ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

  // ===== Campos derivados que se usan como filtros =====
  function motorizacion(p) { return /electric/.test(normalizar(p.motor)) ? "Eléctrico" : "Combustión"; }
  function traccion(p) {
    const t = normalizar(p.traccion);
    if (!t) return "";
    if (t.includes("cadena")) return "Por cadena";
    if (t.includes("awd") || t.includes("quattro") || t.includes("integral")) return "Integral (AWD)";
    if (t.includes("trasera")) return "Trasera";
    if (t.includes("delantera")) return "Delantera";
    return p.traccion;
  }
  function tipoTexto(p) { return p.tipo === "moto" ? "Motocicletas" : "Automóviles"; }
  function textoBusqueda(p) {
    return normalizar([p.marca, p.modelo, p.nombre, p.titulo, p.codigo, p.subcategoria, p.compatibilidad, p.motor,
      p.motorCompatible, p.color, p.anio, p.transmision, p.traccion, p.cilindraje, p.potencia, p.categoria, motorizacion(p)].join(" "));
  }

  // ===== PÁGINAS DE LISTADO =====
  function iniciarListado() {
    const cfgEl = $("#configListado");
    if (!cfgEl) return;
    const cfg = JSON.parse(cfgEl.textContent || "{}");
    const esVehiculos = cfg.seccion === "vehiculos";
    const rejilla = $("#rejillaProductos");
    const nombrePlural = { vehiculos: ["modelo", "modelos"], refacciones: ["refacción", "refacciones"], accesorios: ["accesorio", "accesorios"] }[cfg.seccion];

    // Facetas (filtros de casillas) y cómo obtener su valor en cada producto
    const facetas = esVehiculos
      ? { tipo: tipoTexto, subcategoria: p => p.subcategoria || "", motorizacion, traccion, anio: p => p.anio ? String(p.anio) : "" }
      : { subcategoria: p => p.subcategoria || "" };

    // Estado inicial leído de la URL (ej. vehiculos.php?marca=Audi&tipo=moto o refacciones.php?categoria=Frenos)
    const url = new URLSearchParams(window.location.search);
    const estado = {
      marca: url.get("marca") || "",
      modelo: url.get("modelo") || "",
      q: url.get("q") || "",
      orden: url.get("orden") || "",
      disponible: url.get("disponible") === "1",
      precioMin: url.get("precio_min") || "",
      precioMax: url.get("precio_max") || "",
      facetas: {}
    };
    Object.keys(facetas).forEach(k => { estado.facetas[k] = new Set(); });
    const tipoUrl = url.get("tipo");
    if (tipoUrl && estado.facetas.tipo) estado.facetas.tipo.add(tipoUrl === "moto" ? "Motocicletas" : "Automóviles");
    const subUrl = url.get("subcategoria") || url.get("categoria");
    if (subUrl) estado.facetas.subcategoria.add(subUrl);
    if (url.get("anio") && estado.facetas.anio) estado.facetas.anio.add(url.get("anio"));

    let productos = [];
    let favoritos = [];

    // ¿El producto cumple todos los filtros? (excepto: ignora una faceta para calcular sus conteos)
    function coincide(p, excepto = null) {
      if (estado.marca && p.marca !== estado.marca) return false;
      if (estado.disponible && p.stock <= 0) return false;
      if (estado.precioMin !== "" && p.precio < Number(estado.precioMin)) return false;
      if (estado.precioMax !== "" && p.precio > Number(estado.precioMax)) return false;
      if (estado.modelo) {
        const m = normalizar(estado.modelo);
        if (normalizar(p.modelo) !== m && !normalizar(p.compatibilidad).includes(m)) return false;
      }
      if (estado.q) {
        const texto = p._texto || (p._texto = textoBusqueda(p));
        if (!normalizar(estado.q).split(/\s+/).filter(Boolean).every(pal => texto.includes(pal))) return false;
      }
      for (const [clave, obtener] of Object.entries(facetas)) {
        if (clave === excepto) continue;
        const elegidos = estado.facetas[clave];
        if (elegidos.size && !elegidos.has(obtener(p))) return false;
      }
      return true;
    }

    function ordenar(lista) {
      const copia = [...lista];
      const porOrden = {
        precio_asc: (a, b) => a.precio - b.precio,
        precio_desc: (a, b) => b.precio - a.precio,
        anio_desc: (a, b) => (b.anio || 0) - (a.anio || 0) || b.precio - a.precio,
        disponibles: (a, b) => b.stock - a.stock,
        nombre: (a, b) => a.titulo.localeCompare(b.titulo, "es")
      }[estado.orden];
      return porOrden ? copia.sort(porOrden) : copia; // "Recomendados": orden de la BD (destacados primero)
    }

    // Casillas de cada faceta con su conteo (las opciones sin resultados se deshabilitan)
    function pintarFacetas() {
      Object.entries(facetas).forEach(([clave, obtener]) => {
        const caja = $(`[data-faceta="${clave}"]`);
        if (!caja) return;
        const conteos = new Map();
        productos.forEach(p => {
          const v = obtener(p);
          if (!v) return;
          if (!conteos.has(v)) conteos.set(v, 0);
          if (coincide(p, clave)) conteos.set(v, conteos.get(v) + 1);
        });
        let opciones = [...conteos.keys()];
        opciones = clave === "anio" ? opciones.sort((a, b) => b - a) : opciones.sort((a, b) => a.localeCompare(b, "es"));
        caja.innerHTML = opciones.map(op => {
          const n = conteos.get(op);
          const marcado = estado.facetas[clave].has(op);
          const id = `f-${clave}-${normalizar(op).replace(/[^a-z0-9]+/g, "-")}`;
          return `<div class="opcion-filtro"><label class="izq" for="${id}"><input type="checkbox" id="${id}" data-clave="${clave}" value="${esc(op)}" ${marcado ? "checked" : ""} ${!n && !marcado ? "disabled" : ""}>${esc(op)}</label><span class="cuenta">${n}</span></div>`;
        }).join("") || `<p class="texto-3" style="font-size:13px">Sin opciones</p>`;
      });
    }

    // Modelos compatibles (refacciones/accesorios) según la marca elegida
    function pintarModelos() {
      const select = $("#fModelo");
      if (!select) return;
      const marcas = estado.marca ? [estado.marca] : Object.keys(cfg.modelos || {});
      const opciones = [];
      marcas.forEach(m => (cfg.modelos?.[m] || []).forEach(mod => opciones.push({ marca: m, modelo: mod })));
      opciones.sort((a, b) => (a.marca + a.modelo).localeCompare(b.marca + b.modelo, "es"));
      select.innerHTML = `<option value="">Todos los modelos</option>` + opciones.map(o =>
        `<option value="${esc(o.modelo)}" ${o.modelo === estado.modelo ? "selected" : ""}>${estado.marca ? "" : esc(o.marca) + " "}${esc(o.modelo)}</option>`).join("");
      if (estado.modelo && !opciones.some(o => o.modelo === estado.modelo)) estado.modelo = "";
    }

    // Etiquetas de filtros activos (se quitan con un clic)
    function pintarActivos() {
      const caja = $("#filtrosActivos");
      const chips = [];
      if (estado.marca) chips.push(["marca", estado.marca, estado.marca]);
      if (estado.modelo) chips.push(["modelo", estado.modelo, "Compatible: " + estado.modelo]);
      if (estado.q) chips.push(["q", estado.q, `“${estado.q}”`]);
      if (estado.disponible) chips.push(["disponible", "1", "Con unidades en " + cfg.sucursal]);
      if (estado.precioMin !== "") chips.push(["precioMin", "", "Desde " + window.KARMA.precio(estado.precioMin)]);
      if (estado.precioMax !== "") chips.push(["precioMax", "", "Hasta " + window.KARMA.precio(estado.precioMax)]);
      Object.entries(estado.facetas).forEach(([k, set]) => set.forEach(v => chips.push(["faceta", k + "|" + v, v])));
      caja.innerHTML = chips.map(([tipo, valor, texto]) =>
        `<button class="filtro-activo" type="button" data-quitar="${tipo}" data-valor="${esc(valor)}">${esc(texto)} ${icono("cerrar", "icono icono--chico")}</button>`).join("");
    }

    function sincronizarUrl() {
      const p = new URLSearchParams();
      if (estado.marca) p.set("marca", estado.marca);
      if (estado.modelo) p.set("modelo", estado.modelo);
      if (estado.q) p.set("q", estado.q);
      if (estado.orden) p.set("orden", estado.orden);
      if (estado.disponible) p.set("disponible", "1");
      if (estado.precioMin !== "") p.set("precio_min", estado.precioMin);
      if (estado.precioMax !== "") p.set("precio_max", estado.precioMax);
      if (estado.facetas.subcategoria?.size === 1) p.set("subcategoria", [...estado.facetas.subcategoria][0]);
      if (estado.facetas.tipo?.size === 1) p.set("tipo", [...estado.facetas.tipo][0] === "Motocicletas" ? "moto" : "auto");
      if (estado.facetas.anio?.size === 1) p.set("anio", [...estado.facetas.anio][0]);
      const texto = p.toString();
      history.replaceState(null, "", window.location.pathname + (texto ? "?" + texto : ""));
    }

    function pintar() {
      const resultado = ordenar(productos.filter(p => coincide(p)));
      const conStock = resultado.filter(p => p.stock > 0).length;
      const [uno, varios] = nombrePlural;
      $("#contadorResultados").innerHTML = `<strong>${resultado.length}</strong> ${resultado.length === 1 ? uno : varios} · ${conStock} con unidades en <span translate="no">${esc(cfg.sucursal)}</span>`;
      const botonMovil = $("#verResultadosMovil");
      if (botonMovil) botonMovil.textContent = `Ver ${resultado.length} resultado${resultado.length === 1 ? "" : "s"}`;
      if (!resultado.length) {
        rejilla.innerHTML = `<div class="vacio" style="grid-column:1/-1">${icono("buscar", "icono-grande")}<h3>No encontramos ${varios} con esos filtros</h3><p>Prueba quitando algún filtro o cambia de sucursal para ver otra disponibilidad.</p><button class="btn btn--primario" type="button" data-limpiar>Limpiar filtros</button></div>`;
      } else {
        rejilla.innerHTML = resultado.map(p => esVehiculos ? tarjetaVehiculo(p, favoritos) : tarjetaPieza(p)).join("");
        revelar(rejilla);
      }
      $$("#pestanasMarca .chip").forEach(c => c.classList.toggle("activo", c.dataset.marca === estado.marca));
      pintarFacetas();
      pintarActivos();
      sincronizarUrl();
    }

    function limpiar() {
      estado.marca = estado.modelo = estado.q = estado.precioMin = estado.precioMax = "";
      estado.disponible = false;
      Object.values(estado.facetas).forEach(s => s.clear());
      $("#fTexto").value = "";
      $("#fPrecioMin").value = "";
      $("#fPrecioMax").value = "";
      $("#fDisponible").checked = false;
      pintarModelos();
      pintar();
    }

    // ----- Eventos -----
    $$("#pestanasMarca .chip").forEach(chip => chip.addEventListener("click", () => {
      estado.marca = chip.dataset.marca;
      pintarModelos();
      pintar();
    }));
    $("#panelFiltros").addEventListener("change", (e) => {
      const casilla = e.target.closest("input[data-clave]");
      if (casilla) {
        const set = estado.facetas[casilla.dataset.clave];
        casilla.checked ? set.add(casilla.value) : set.delete(casilla.value);
        pintar();
      }
    });
    $("#fDisponible").addEventListener("change", (e) => { estado.disponible = e.target.checked; pintar(); });
    $("#fModelo")?.addEventListener("change", (e) => { estado.modelo = e.target.value; pintar(); });
    const leerPrecios = retrasar(() => { estado.precioMin = $("#fPrecioMin").value.trim(); estado.precioMax = $("#fPrecioMax").value.trim(); pintar(); }, 350);
    $("#fPrecioMin").addEventListener("input", leerPrecios);
    $("#fPrecioMax").addEventListener("input", leerPrecios);
    $("#fTexto").addEventListener("input", retrasar((e) => { estado.q = e.target.value.trim(); pintar(); }, 200));
    $("#fOrden").addEventListener("change", (e) => { estado.orden = e.target.value; pintar(); });
    $("#limpiarFiltros").addEventListener("click", limpiar);
    document.addEventListener("click", (e) => {
      if (e.target.closest("[data-limpiar]")) { limpiar(); return; }
      const quitar = e.target.closest("[data-quitar]");
      if (!quitar) return;
      const tipo = quitar.dataset.quitar;
      if (tipo === "faceta") { const [k, v] = quitar.dataset.valor.split("|"); estado.facetas[k].delete(v); }
      else if (tipo === "disponible") { estado.disponible = false; $("#fDisponible").checked = false; }
      else if (tipo === "q") { estado.q = ""; $("#fTexto").value = ""; }
      else if (tipo === "precioMin") { estado.precioMin = ""; $("#fPrecioMin").value = ""; }
      else if (tipo === "precioMax") { estado.precioMax = ""; $("#fPrecioMax").value = ""; }
      else { estado[tipo] = ""; if (tipo === "marca") pintarModelos(); }
      pintar();
    });
    // Panel de filtros en celular/tablet
    const panel = $("#panelFiltros");
    $("#abrirFiltros")?.addEventListener("click", () => { panel.classList.add("abierto"); document.body.style.overflow = "hidden"; });
    $$("[data-cerrar-filtros]").forEach(b => b.addEventListener("click", () => { panel.classList.remove("abierto"); document.body.style.overflow = ""; }));

    // Valores iniciales en los controles
    $("#fTexto").value = estado.q;
    $("#fOrden").value = estado.orden;
    $("#fDisponible").checked = estado.disponible;
    $("#fPrecioMin").value = estado.precioMin;
    $("#fPrecioMax").value = estado.precioMax;
    pintarModelos();

    // ----- Carga de datos -----
    rejilla.innerHTML = tarjetasEsqueleto(6);
    api("productos", { params: { seccion: cfg.seccion } })
      .then(r => { productos = r.productos || []; favoritos = r.favoritos || []; pintar(); })
      .catch(e => {
        rejilla.innerHTML = `<div class="vacio" style="grid-column:1/-1">${icono("alerta", "icono-grande")}<h3>No pudimos cargar el catálogo</h3><p>${esc(e.message)}</p><button class="btn btn--primario" type="button" onclick="location.reload()">Reintentar</button></div>`;
        aviso(e.message, "error");
      });
  }

  // ===== PÁGINA DE BÚSQUEDA (buscar.php?q=…) =====
  function iniciarBusqueda() {
    const caja = $("#resultadosBusqueda");
    if (!caja) return;
    const q = new URLSearchParams(window.location.search).get("q") || "";
    const entrada = $("#entradaBusquedaPagina");
    if (entrada) entrada.value = q;
    if (q.trim().length < 2) {
      caja.innerHTML = `<div class="vacio">${icono("buscar", "icono-grande")}<h3>Escribe al menos 2 letras</h3><p>Busca por marca, modelo, nombre de pieza, código, compatibilidad o motor.</p></div>`;
      return;
    }
    caja.innerHTML = `<div class="rejilla">${tarjetasEsqueleto(3)}</div>`;
    Promise.all([api("productos", { params: { q } }), api("buscar", { params: { q } })])
      .then(([r, b]) => {
        const lista = r.productos || [];
        const grupos = [["vehiculos", "Vehículos"], ["refacciones", "Refacciones"], ["accesorios", "Accesorios"]];
        const paginas = b.paginas || [];
        $("#contadorBusqueda").textContent = `${lista.length} producto${lista.length === 1 ? "" : "s"} para “${q}”`;
        if (!lista.length && !paginas.length) {
          caja.innerHTML = `<div class="vacio">${icono("buscar", "icono-grande")}<h3>Sin resultados para “${esc(q)}”</h3><p>Revisa la ortografía o intenta con el modelo (ej. “Macan”), la pieza (ej. “pastillas”) o el código (ej. KRM-CAT-REF-AUDI-08).</p><a class="btn btn--primario" href="vehiculos.php">Ver todos los modelos</a></div>`;
          return;
        }
        caja.innerHTML = grupos.map(([seccion, titulo]) => {
          const items = lista.filter(p => p.seccion === seccion);
          if (!items.length) return "";
          return `<section class="seccion--compacta" style="padding-top:8px"><div class="titulo-seccion" style="margin-bottom:20px"><div><h2 style="font-size:26px">${titulo} <span class="texto-3" style="font-size:16px">(${items.length})</span></h2></div></div>
            <div class="rejilla">${items.map(p => p.esVehiculo ? tarjetaVehiculo(p, r.favoritos || []) : tarjetaPieza(p)).join("")}</div></section>`;
        }).join("") + (paginas.length ? `<section style="padding-bottom:64px"><h2 style="font-size:22px; margin-bottom:14px">Páginas y servicios</h2><div class="fila fila--envolver">${paginas.map(pg => `<a class="chip" href="${esc(pg.url)}">${esc(pg.titulo)} ${icono("chevron-der", "icono icono--chico")}</a>`).join("")}</div></section>` : "");
        revelar(caja);
      })
      .catch(e => { caja.innerHTML = `<div class="vacio"><h3>No se pudo completar la búsqueda</h3><p>${esc(e.message)}</p></div>`; });
  }

  document.addEventListener("DOMContentLoaded", () => {
    iniciarListado();
    iniciarBusqueda();
  });
})();
