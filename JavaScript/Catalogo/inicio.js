/* KARMA · Catálogo — Inicio: carrusel principal, buscador rápido, destacados, mini simulador y refacciones por vehículo */
(function () {
  "use strict";
  const { $, $$, precio, tarjetaVehiculo, revelar, iniciarCarrusel, config } = window.KARMA;
  const datos = JSON.parse($("#datosInicio")?.textContent || "{}");
  const vehiculos = datos.vehiculos || [];

  // ===== CARRUSEL PRINCIPAL (avanza solo; se pausa con el botón, al pasar el mouse o con "reducir movimiento") =====
  function iniciarHeroe() {
    const heroe = $("#heroe");
    if (!heroe) return;
    const slides = $$(".heroe-slide", heroe);
    const indicadores = $$(".heroe-indicador", heroe);
    const boton = $("#heroePausa");
    const DURACION = 7000;
    const reducir = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let actual = 0, temporizador = null, pausado = reducir;
    heroe.style.setProperty("--duracion", DURACION + "ms");

    const mostrar = (i) => {
      actual = (i + slides.length) % slides.length;
      slides.forEach((s, n) => s.classList.toggle("activo", n === actual));
      indicadores.forEach((b, n) => {
        b.classList.remove("activo");
        if (n === actual) { void b.offsetWidth; b.classList.add("activo"); }
      });
      programar();
    };
    const programar = () => {
      clearTimeout(temporizador);
      if (!pausado) temporizador = setTimeout(() => mostrar(actual + 1), DURACION);
    };
    const pausar = (si) => {
      pausado = si;
      heroe.classList.toggle("pausado", si);
      boton.innerHTML = window.KARMA.icono(si ? "play" : "pausa", "icono icono--chico");
      boton.setAttribute("aria-label", si ? "Reanudar carrusel" : "Pausar carrusel");
      programar();
    };
    indicadores.forEach(b => b.addEventListener("click", () => mostrar(Number(b.dataset.slide))));
    boton?.addEventListener("click", () => pausar(!pausado));
    heroe.addEventListener("mouseenter", () => { if (!pausado) { clearTimeout(temporizador); heroe.classList.add("pausado"); } });
    heroe.addEventListener("mouseleave", () => { if (!pausado) { heroe.classList.remove("pausado"); mostrar(actual); } });
    // Deslizar con el dedo en celulares
    let x0 = null;
    heroe.addEventListener("touchstart", e => { x0 = e.touches[0].clientX; }, { passive: true });
    heroe.addEventListener("touchend", e => {
      if (x0 === null) return;
      const dx = e.changedTouches[0].clientX - x0;
      if (Math.abs(dx) > 50) mostrar(actual + (dx < 0 ? 1 : -1));
      x0 = null;
    });
    if (pausado) pausar(true); else programar();
  }

  // ===== BUSCADOR RÁPIDO: cuenta en vivo cuántos modelos coinciden =====
  function iniciarBuscadorRapido() {
    const form = $("#buscadorRapido");
    if (!form) return;
    const boton = $("#brBoton");
    const contar = () => {
      const marca = form.marca.value, tipo = form.tipo.value, max = Number(form.precio_max.value) || Infinity;
      const n = vehiculos.filter(v => (!marca || v.marca === marca) && (!tipo || v.tipo === tipo) && v.precio <= max).length;
      boton.innerHTML = `Ver ${n} modelo${n === 1 ? "" : "s"} ${window.KARMA.icono("flecha", "icono flecha")}`;
      boton.disabled = n === 0;
    };
    form.addEventListener("change", contar);
    // No se envían parámetros vacíos (URL más limpia)
    form.addEventListener("submit", () => $$("select", form).forEach(s => { if (!s.value) s.disabled = true; }));
    contar();
  }

  // ===== MODELOS DESTACADOS (con pestañas por marca y flechas) =====
  function iniciarDestacados() {
    const pista = $("#pistaDestacados");
    if (!pista) return;
    let actualizarFlechas = null;
    const pintar = (marca) => {
      const lista = (datos.destacados || []).filter(v => !marca || v.marca === marca);
      const completa = lista.length >= 4 ? lista : vehiculos.filter(v => !marca || v.marca === marca).slice(0, 8);
      pista.innerHTML = completa.map(v => tarjetaVehiculo(v, datos.favoritos || [])).join("");
      pista.scrollLeft = 0;
      revelar(pista);
      actualizarFlechas?.();
    };
    $$("#pestanasDestacados .chip").forEach(chip => chip.addEventListener("click", () => {
      $$("#pestanasDestacados .chip").forEach(c => c.classList.toggle("activo", c === chip));
      pintar(chip.dataset.marca);
    }));
    pintar("");
    actualizarFlechas = iniciarCarrusel($("#seccionDestacados"));
  }

  // ===== MINI SIMULADOR (misma fórmula del módulo de crédito del POS) =====
  function iniciarMiniSimulador() {
    const precioEl = $("#msPrecio"), engancheEl = $("#msEnganche");
    if (!precioEl) return;
    let plazo = 48;
    const calcular = () => {
      const p = Number(precioEl.value), pct = Number(engancheEl.value);
      const base = p * (1 - pct / 100);
      const financiado = base * (1 + (config.comisionApertura ?? 0.02));
      const i = (config.tasaAnual ?? 18) / 100 / 12;
      const mensual = financiado * (i * Math.pow(1 + i, plazo)) / (Math.pow(1 + i, plazo) - 1);
      $("#msPrecioTxt").textContent = precio(p);
      $("#msEngancheTxt").textContent = `${pct}% · ${precio(p * pct / 100)}`;
      $("#msMensualidad").textContent = precio(mensual);
      $("#msFinanciar").textContent = precio(financiado);
      $("#msEnlace").href = `financiamiento.php?precio=${p}&enganche=${pct}&plazo=${plazo}#simulador`;
    };
    precioEl.addEventListener("input", calcular);
    engancheEl.addEventListener("input", calcular);
    $$("#msPlazos button").forEach(b => b.addEventListener("click", () => {
      plazo = Number(b.dataset.plazo);
      $$("#msPlazos button").forEach(x => x.classList.toggle("activo", x === b));
      calcular();
    }));
    calcular();
  }

  // ===== REFACCIONES POR VEHÍCULO: marca → modelos de esa marca =====
  function iniciarBuscadorPiezas() {
    const marca = $("#bpMarca"), modelo = $("#bpModelo");
    if (!marca) return;
    const llenar = () => {
      const modelos = [...new Set(vehiculos.filter(v => v.marca === marca.value).map(v => v.modelo))].sort();
      modelo.innerHTML = `<option value="">Todos los modelos</option>` + modelos.map(m => `<option value="${window.KARMA.esc(m)}">${window.KARMA.esc(m)}</option>`).join("");
    };
    marca.addEventListener("change", llenar);
    $("#buscadorPiezas").addEventListener("submit", () => { if (!modelo.value) modelo.disabled = true; });
    llenar();
  }

  document.addEventListener("DOMContentLoaded", () => {
    iniciarHeroe();
    iniciarBuscadorRapido();
    iniciarDestacados();
    iniciarMiniSimulador();
    iniciarBuscadorPiezas();
  });
})();
