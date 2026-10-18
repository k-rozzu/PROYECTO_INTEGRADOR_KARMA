/* =====================================================================================
   KARMA · Catálogo — páginas de detalle (vehiculo.php y refaccion.php)
   Galería, vista 3D (reutiliza JavaScript/PuntoDeVenta/vista_previa_3d.js del POS), configurador,
   simulador de financiamiento, compartir y carrusel de productos relacionados.
   La configuración y la simulación viajan a agendar.php como nota de la cita (llega al POS como orden web).
   ===================================================================================== */
(function () {
  "use strict";
  const { $, $$, esc, precio, aviso, tarjetaPieza, revelar, iniciarCarrusel, calcularCredito, tablaAmortizacion, config } = window.KARMA;
  const datos = JSON.parse($("#datosProducto")?.textContent || "{}");
  const p = datos.producto || {};

  // ===== GALERÍA =====
  function iniciarGaleria() {
    const principal = $("#imagenPrincipal");
    const miniaturas = $$(".galeria-miniaturas [data-imagen]");
    if (!principal || !miniaturas.length) return;
    let actual = 0;
    const mostrar = (i) => {
      actual = (i + miniaturas.length) % miniaturas.length;
      salirDe3D();
      principal.style.opacity = "0";
      setTimeout(() => { principal.src = miniaturas[actual].dataset.imagen; principal.style.opacity = "1"; }, 150);
      miniaturas.forEach((m, n) => m.classList.toggle("activo", n === actual));
    };
    miniaturas.forEach((m, i) => m.addEventListener("click", () => mostrar(i)));
    $$("[data-galeria]").forEach(b => b.addEventListener("click", () => mostrar(actual + Number(b.dataset.galeria))));
    $("#galeria")?.addEventListener("keydown", (e) => {
      if (e.key === "ArrowRight") mostrar(actual + 1);
      if (e.key === "ArrowLeft") mostrar(actual - 1);
    });
  }

  // ===== VISTA 3D (solo productos con modelo .glb propio en productos.modelo_3d) =====
  let visorCargado = null;
  let colorActual = { nombre: p.color, hex: p.colorHex };
  function cargarVisor() {
    if (window.KarmaVista3D) return Promise.resolve();
    if (visorCargado) return visorCargado;
    visorCargado = new Promise((resolver, rechazar) => {
      window.addEventListener("karma:vista3d-lista", () => resolver(), { once: true });
      const s = document.createElement("script");
      s.type = "module";
      s.src = datos.visor3D;
      s.onerror = () => rechazar(new Error("No se pudo cargar la vista 3D (revisa tu conexión a internet)."));
      document.head.appendChild(s);
    });
    return visorCargado;
  }
  function mostrar3D() {
    const caja = $("#galeriaPrincipal");
    const lienzo = $("#lienzo3D");
    if (!caja || !lienzo) return;
    caja.classList.add("en-3d");
    $("#boton3D")?.classList.add("activo");
    $$(".galeria-miniaturas [data-imagen]").forEach(m => m.classList.remove("activo"));
    if (!lienzo.children.length) lienzo.innerHTML = `<div class="vista3d-cargando"><span class="vista3d-spinner"></span><span>Cargando modelo 3D…</span></div>`;
    cargarVisor()
      .then(() => window.KarmaVista3D.mostrar(lienzo, { id: p.id, tipo: p.tipo, nombre: p.nombre, modelo: p.modelo, marca: p.marca, modelo3d: p.modelo3d, color: colorActual.nombre, colorHex: colorActual.hex }))
      .catch(e => { aviso(e.message, "error"); salirDe3D(); });
  }
  function salirDe3D() {
    $("#galeriaPrincipal")?.classList.remove("en-3d");
    $("#boton3D")?.classList.remove("activo");
  }

  // Enlace a "Agendar cita" (visita) de este vehículo con una nota que se precarga en los comentarios
  function enlaceCita(nota) {
    return `agendar.php?tipo=visita&id=${p.id}&nota=${encodeURIComponent(nota.slice(0, 400))}`;
  }

  // ===== CONFIGURADOR =====
  let configuracion = { total: p.precio, resumen: "", color: p.color, version: "", equipamiento: [] };
  function iniciarConfigurador() {
    const caja = $("#configurador");
    if (!caja) return;
    const calcular = () => {
      const colorBtn = $(".muestra-color.activo", caja);
      const version = $('input[name="version"]:checked', caja);
      const equipos = $$('input[name="equipamiento"]:checked', caja);
      const precioColor = Number(colorBtn?.dataset.precio || 0);
      const precioVersion = Number(version?.dataset.precio || 0);
      const precioEquipo = equipos.reduce((s, x) => s + Number(x.dataset.precio || 0), 0);
      const total = p.precio + precioColor + precioVersion + precioEquipo;
      configuracion = {
        total, color: colorBtn?.dataset.color || p.color, version: version?.dataset.nombre || "",
        equipamiento: equipos.map(x => x.dataset.nombre),
        resumen: [colorBtn?.dataset.color, version?.dataset.nombre, ...equipos.map(x => x.dataset.nombre)].filter(Boolean).join(", ") + ` · ${precio(total)}`
      };
      $("#resColorNombre").textContent = "Color: " + (colorBtn?.dataset.color || "");
      $("#resColorPrecio").textContent = precioColor ? "+" + precio(precioColor) : "Incluido";
      $("#resVersionNombre").textContent = "Versión: " + (version?.dataset.nombre || "Base");
      $("#resVersionPrecio").textContent = precioVersion ? "+" + precio(precioVersion) : "Incluida";
      $("#resEquipo").textContent = precioEquipo ? "+" + precio(precioEquipo) : "$0";
      $("#resTotal").textContent = precio(total);
      const cita = $("#btnCotizar");
      if (cita) cita.href = enlaceCita(`Configuración: ${configuracion.resumen}`);
      actualizarSimulador();
    };
    $$(".muestra-color", caja).forEach(btn => btn.addEventListener("click", () => {
      $$(".muestra-color", caja).forEach(b => b.classList.toggle("activo", b === btn));
      const enInventario = btn.dataset.color === p.color;
      $("#colorElegidoTexto").textContent = `Elegido: ${btn.dataset.color} ${enInventario ? "(unidad en inventario)" : "(sobre pedido, 8 a 12 semanas)"}`;
      colorActual = { nombre: btn.dataset.color, hex: btn.dataset.hex };
      // Si la vista 3D está abierta, el modelo se vuelve a pintar con el color elegido
      if ($("#galeriaPrincipal")?.classList.contains("en-3d")) mostrar3D();
      else if (datos.tiene3D) aviso("Toca el cubo de la galería para ver este color en el modelo 3D.", "info");
      calcular();
    }));
    caja.addEventListener("change", calcular);
    calcular();
  }

  // ===== SIMULADOR DE FINANCIAMIENTO DEL VEHÍCULO =====
  let plazo = 48;
  let calculo = null;
  function actualizarSimulador() {
    const enganche = $("#svEnganche");
    if (!enganche) return;
    const pct = Number(enganche.value);
    const total = configuracion.total;
    const engancheMonto = total * pct / 100;
    calculo = calcularCredito({ precio: total, engancheMonto, plazoMeses: plazo });
    $("#svPrecio").textContent = precio(total);
    $("#svEngancheTxt").textContent = `${pct}% · ${precio(engancheMonto)}`;
    $("#svMensualidad").textContent = precio(calculo.mensualidad);
    $("#svEngancheMonto").textContent = precio(engancheMonto);
    $("#svComision").textContent = precio(calculo.comisionApertura);
    $("#svFinanciado").textContent = precio(calculo.montoFinanciado);
    $("#svIntereses").textContent = precio(calculo.montoInteres);
    $("#svTotal").textContent = precio(calculo.montoFinal + engancheMonto);
    if ($("#svTablaCaja").innerHTML) $("#svTablaCaja").innerHTML = tablaAmortizacion(calculo);
    const cita = $("#svSolicitar");
    if (cita) cita.href = enlaceCita(`Simulación de crédito: ${precio(total)}, enganche ${pct}%, ${plazo} meses, mensualidad estimada ${precio(calculo.mensualidad)} (tasa ${config.tasaAnual}% anual)`);
    // Mensualidad "desde" bajo el precio: 30% de enganche a 60 meses
    const desde = calcularCredito({ precio: p.precio, engancheMonto: p.precio * 0.3, plazoMeses: 60 });
    const etiqueta = $("#mensualidadDesde");
    if (etiqueta) etiqueta.textContent = `o desde ${precio(desde.mensualidad)} al mes* (30% de enganche, 60 meses)`;
  }
  function iniciarSimulador() {
    if (!$("#svEnganche")) return;
    $("#svEnganche").addEventListener("input", actualizarSimulador);
    $$("#svPlazos button").forEach(b => b.addEventListener("click", () => {
      plazo = Number(b.dataset.plazo);
      $$("#svPlazos button").forEach(x => x.classList.toggle("activo", x === b));
      actualizarSimulador();
    }));
    $("#svTabla").addEventListener("click", () => {
      const caja = $("#svTablaCaja");
      const abierta = !!caja.innerHTML;
      caja.innerHTML = abierta ? "" : tablaAmortizacion(calculo);
      $("#svTabla").innerHTML = window.KARMA.icono("grafica") + (abierta ? " Ver tabla de amortización" : " Ocultar tabla de amortización");
    });
    actualizarSimulador();
  }

  // ===== COMPARTIR =====
  function iniciarCompartir() {
    $("#btnCompartir")?.addEventListener("click", async () => {
      const datosCompartir = { title: document.title, text: `${p.titulo} en KARMA`, url: window.location.href };
      try {
        if (navigator.share) { await navigator.share(datosCompartir); return; }
        await navigator.clipboard.writeText(window.location.href);
        aviso("Enlace copiado. Ya puedes compartirlo.", "ok");
      } catch (_) { /* el usuario canceló */ }
    });
  }

  // ===== DETALLE DE REFACCIÓN / ACCESORIO: cantidad =====
  function iniciarCantidad() {
    const input = $("#cantidadPieza");
    if (!input) return;
    input.addEventListener("change", () => {
      const max = Number(input.max) || 1;
      input.value = Math.min(max, Math.max(1, Math.round(Number(input.value) || 1)));
    });
  }

  // ===== CARRUSELES DE RELACIONADOS =====
  function iniciarRelacionados() {
    const pista = $("#pistaCompatibles") || $("#pistaRelacionados");
    const lista = datos.compatibles || datos.relacionados || [];
    if (!pista || !lista.length) return;
    pista.innerHTML = lista.map(tarjetaPieza).join("");
    revelar(pista);
    iniciarCarrusel(pista.parentElement);
  }

  document.addEventListener("DOMContentLoaded", () => {
    iniciarGaleria();
    $("#boton3D")?.addEventListener("click", mostrar3D);
    iniciarConfigurador();
    iniciarSimulador();
    iniciarCompartir();
    iniciarCantidad();
    iniciarRelacionados();
    // Resalta la sección visible en la subnavegación
    const enlaces = $$(".subnav a");
    if (enlaces.length && "IntersectionObserver" in window) {
      const obs = new IntersectionObserver((entradas) => {
        entradas.forEach(en => { if (en.isIntersecting) enlaces.forEach(a => a.classList.toggle("activo", a.getAttribute("href") === "#" + en.target.id)); });
      }, { rootMargin: "-45% 0px -50% 0px" });
      enlaces.forEach(a => { const s = document.querySelector(a.getAttribute("href")); if (s) obs.observe(s); });
    }
  });
})();
