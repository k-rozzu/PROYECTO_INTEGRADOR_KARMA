/* KARMA · Traductor universal ES ⇄ EN — se agrega a cualquier página con <script src=".../JavaScript/Traduccion/traductor.js"></script> */
(function () {
  "use strict";

  // Etiqueta <script> que cargó este archivo (de ella se leen data-endpoint y data-idioma-base)
  const SCRIPT_ACTUAL = document.currentScript;
  // API DE TRADUCCIÓN: dirección del endpoint PHP (por defecto PHP/Traduccion/traductor.php, relativo a este archivo)
  const ENDPOINT = SCRIPT_ACTUAL?.dataset.endpoint
    ? new URL(SCRIPT_ACTUAL.dataset.endpoint, document.baseURI).href
    : new URL("../../PHP/Traduccion/traductor.php", SCRIPT_ACTUAL?.src || document.baseURI).href;
  // Idioma en el que está escrita la página
  const IDIOMA_BASE = (SCRIPT_ACTUAL?.dataset.idiomaBase || "es").toLowerCase();
  // Llave de localStorage donde se recuerda el idioma elegido
  const CLAVE_IDIOMA = "karma_idioma";
  // Prefijo de localStorage para la caché de traducciones de cada idioma
  const CLAVE_CACHE = "karma_traducciones_";
  // Máximo de textos por petición y de traducciones guardadas en el navegador
  const LOTE_MAX = 50;
  const MEMORIA_MAX = 4000;
  // Atributos visibles que también se traducen
  const ATRIBUTOS = ["placeholder", "title", "aria-label", "alt"];
  const SELECTOR_ATRIBUTOS = ATRIBUTOS.map(a => `[${a}]`).join(",");
  // Zonas que nunca se traducen (código, estilos, íconos o lo marcado con translate="no")
  const SELECTOR_EXCLUIDO = 'script, style, noscript, textarea, code, pre, template, svg, [translate="no"], .notranslate, [data-no-traducir]';

  // Estado interno del traductor
  let idiomaActual = leerIdiomaGuardado();
  let memoria = new Map();
  let inverso = new Map();
  let observador = null;
  let temporizador = null;
  let pausaHasta = 0;
  const pendientes = new Set();
  const enCamino = new Set();
  // Original y traducción de cada nodo de texto / atributo ya procesado
  const registroTexto = new WeakMap();
  const registroAtributos = new WeakMap();

  // Lee el idioma elegido la última vez (o el idioma base)
  function leerIdiomaGuardado() {
    try { return (localStorage.getItem(CLAVE_IDIOMA) || IDIOMA_BASE).toLowerCase(); } catch (_) { return IDIOMA_BASE; }
  }

  // Guarda el idioma elegido para la próxima visita
  function guardarIdioma(idioma) {
    try { localStorage.setItem(CLAVE_IDIOMA, idioma); } catch (_) { /* navegador sin almacenamiento */ }
  }

  // Carga las traducciones guardadas en el navegador para un idioma
  function cargarMemoria(idioma) {
    try { memoria = new Map(Object.entries(JSON.parse(localStorage.getItem(CLAVE_CACHE + idioma) || "{}"))); }
    catch (_) { memoria = new Map(); }
    inverso = new Map([...memoria].map(([original, traducido]) => [traducido, original]));
  }

  // Guarda las traducciones en el navegador (borra las más viejas si hay demasiadas)
  function guardarMemoria() {
    while (memoria.size > MEMORIA_MAX) memoria.delete(memoria.keys().next().value);
    try { localStorage.setItem(CLAVE_CACHE + idiomaActual, JSON.stringify(Object.fromEntries(memoria))); } catch (_) { /* sin espacio */ }
  }

  // Decide si un texto se traduce: debe tener letras y no ser un código, VIN, correo o URL
  function esTraducible(texto) {
    if (texto.length < 2 || !/\p{L}/u.test(texto)) return false;
    if (/^[A-Z0-9][A-Z0-9\-_.·/#:]*$/.test(texto)) return false;
    if (/^\S+@\S+\.\S+$/.test(texto) || /^https?:\/\//i.test(texto)) return false;
    return true;
  }

  // Revisa si un elemento (o alguno de sus padres) no debe traducirse
  function estaExcluido(elemento) {
    return !elemento || !!elemento.closest(SELECTOR_EXCLUIDO) || elemento.isContentEditable;
  }

  // Separa los espacios del inicio y del final para traducir solo el texto
  function partir(texto) {
    const m = texto.match(/^(\s*)([\s\S]*?)(\s*)$/);
    return { ini: m[1], nucleo: m[2], fin: m[3] };
  }

  // Si un texto ya viene traducido (la página copió una traducción), regresa su original en español
  function originalDe(texto) {
    if (memoria.has(texto) || !inverso.has(texto)) return texto;
    return inverso.get(texto);
  }

  // Traduce un nodo de texto (si todavía no hay traducción, la pide al servidor)
  function procesarTexto(nodo) {
    if (estaExcluido(nodo.parentElement)) return;
    const actual = nodo.nodeValue;
    let reg = registroTexto.get(nodo);
    // Texto nuevo o cambiado por la página: se toma como original (si ya venía traducido se busca su original)
    if (!reg || (actual !== reg.traducido && actual !== reg.original)) {
      const p = partir(actual);
      reg = { original: p.ini + originalDe(p.nucleo) + p.fin, traducido: null };
      registroTexto.set(nodo, reg);
    }
    if (actual === reg.traducido) return;
    const { ini, nucleo, fin } = partir(reg.original);
    if (!esTraducible(nucleo)) return;
    const traduccion = memoria.get(nucleo);
    if (traduccion === undefined) { pedir(nucleo); return; }
    reg.traducido = ini + traduccion + fin;
    if (nodo.nodeValue !== reg.traducido) nodo.nodeValue = reg.traducido;
  }

  // Traduce los atributos visibles de un elemento (placeholder, title, aria-label, alt)
  function procesarAtributos(elemento) {
    if (estaExcluido(elemento)) return;
    let regs = registroAtributos.get(elemento);
    if (!regs) { regs = {}; registroAtributos.set(elemento, regs); }
    for (const atributo of ATRIBUTOS) {
      if (!elemento.hasAttribute(atributo)) continue;
      const actual = elemento.getAttribute(atributo);
      let reg = regs[atributo];
      if (!reg || (actual !== reg.traducido && actual !== reg.original)) {
        reg = regs[atributo] = { original: originalDe(actual.trim()), traducido: null };
      }
      if (actual === reg.traducido) continue;
      const nucleo = reg.original.trim();
      if (!esTraducible(nucleo)) continue;
      const traduccion = memoria.get(nucleo);
      if (traduccion === undefined) { pedir(nucleo); continue; }
      reg.traducido = traduccion;
      if (actual !== traduccion) elemento.setAttribute(atributo, traduccion);
    }
  }

  // Recorre una parte de la página y traduce todos sus textos y atributos
  function escanear(raiz) {
    if (!raiz) return;
    if (raiz.nodeType === Node.TEXT_NODE) { procesarTexto(raiz); return; }
    if (raiz.nodeType !== Node.ELEMENT_NODE) return;
    const recorrido = document.createTreeWalker(raiz, NodeFilter.SHOW_TEXT);
    while (recorrido.nextNode()) procesarTexto(recorrido.currentNode);
    if (raiz.matches(SELECTOR_ATRIBUTOS)) procesarAtributos(raiz);
    raiz.querySelectorAll(SELECTOR_ATRIBUTOS).forEach(procesarAtributos);
  }

  // Traduce toda la página (incluye el título de la pestaña) sin volver a disparar el observador
  function aplicarTodo() {
    escanear(document.documentElement);
    observador?.takeRecords();
  }

  // Regresa toda la página a su texto original
  function restaurarTodo() {
    const recorrido = document.createTreeWalker(document.documentElement, NodeFilter.SHOW_TEXT);
    while (recorrido.nextNode()) {
      const nodo = recorrido.currentNode;
      const reg = registroTexto.get(nodo);
      if (reg && reg.traducido !== null && nodo.nodeValue === reg.traducido) nodo.nodeValue = reg.original;
    }
    document.querySelectorAll(SELECTOR_ATRIBUTOS).forEach(elemento => {
      const regs = registroAtributos.get(elemento) || {};
      for (const atributo of ATRIBUTOS) {
        const reg = regs[atributo];
        if (reg && reg.traducido !== null && elemento.getAttribute(atributo) === reg.traducido) elemento.setAttribute(atributo, reg.original);
      }
    });
  }

  // Atiende los cambios de la página (script.js redibuja seguido) y traduce lo nuevo antes de pintarse
  function alCambiarPagina(cambios) {
    for (const cambio of cambios) {
      if (cambio.type === "characterData") procesarTexto(cambio.target);
      else if (cambio.type === "attributes") procesarAtributos(cambio.target);
      else cambio.addedNodes.forEach(escanear);
    }
    observador.takeRecords();
  }

  // Empieza a vigilar la página completa
  function conectarObservador() {
    observador = observador || new MutationObserver(alCambiarPagina);
    observador.observe(document.documentElement, { childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ATRIBUTOS });
  }

  // Agrega un texto a la fila de pendientes y programa el envío en lote
  function pedir(texto) {
    if (enCamino.has(texto) || Date.now() < pausaHasta) return;
    pendientes.add(texto);
    if (!temporizador) temporizador = setTimeout(enviarPendientes, 40);
  }

  // API DE TRADUCCIÓN: POST JSON al endpoint PHP { textos, origen, destino } → { ok, traducciones }
  async function solicitarTraducciones(textos, destino) {
    const respuesta = await fetch(ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ textos, origen: IDIOMA_BASE, destino })
    });
    const datos = await respuesta.json().catch(() => ({ ok: false, error: "Respuesta inválida del traductor." }));
    if (!respuesta.ok || !datos.ok) throw new Error(datos.error || "No se pudo traducir.");
    return datos.traducciones;
  }

  // Guarda en memoria las traducciones recibidas (y su búsqueda inversa)
  function recordar(textos, traducciones) {
    textos.forEach((texto, i) => {
      const traduccion = traducciones[i] ?? texto;
      memoria.set(texto, traduccion);
      inverso.set(traduccion, texto);
    });
    guardarMemoria();
  }

  // Manda los pendientes en lotes de 50; al volver la respuesta, aplica las traducciones en la página
  async function enviarPendientes() {
    temporizador = null;
    if (idiomaActual === IDIOMA_BASE || !pendientes.size) { pendientes.clear(); return; }
    const lote = [...pendientes].slice(0, LOTE_MAX);
    lote.forEach(texto => { pendientes.delete(texto); enCamino.add(texto); });
    if (pendientes.size) temporizador = setTimeout(enviarPendientes, 0);
    const idiomaDelLote = idiomaActual;
    try {
      const traducciones = await solicitarTraducciones(lote, idiomaDelLote);
      if (idiomaDelLote !== idiomaActual) return;
      recordar(lote, traducciones);
      aplicarTodo();
    } catch (error) {
      pausaHasta = Date.now() + 30000;
      pendientes.clear();
      console.warn("[Traductor]", error.message);
      document.dispatchEvent(new CustomEvent("karma:traduccion-error", { detail: { mensaje: error.message } }));
    } finally {
      lote.forEach(texto => enCamino.delete(texto));
    }
  }

  // Traduce un texto suelto desde JavaScript (útil para alert, mensajes, etc.)
  async function traducir(texto) {
    const limpio = String(texto ?? "");
    const { ini, nucleo, fin } = partir(limpio);
    if (idiomaActual === IDIOMA_BASE || !esTraducible(nucleo)) return limpio;
    if (memoria.has(nucleo)) return ini + memoria.get(nucleo) + fin;
    try {
      const [traduccion] = await solicitarTraducciones([nucleo], idiomaActual);
      recordar([nucleo], [traduccion]);
      return ini + traduccion + fin;
    } catch (_) {
      return limpio;
    }
  }

  // Cambia el idioma de toda la página ("es" regresa al original, "en" traduce)
  function setIdioma(idioma) {
    idioma = String(idioma || IDIOMA_BASE).toLowerCase();
    idiomaActual = idioma;
    guardarIdioma(idioma);
    document.documentElement.lang = idioma;
    pendientes.clear();
    pausaHasta = 0;
    if (idioma === IDIOMA_BASE) {
      observador?.disconnect();
      restaurarTodo();
    } else {
      cargarMemoria(idioma);
      conectarObservador();
      aplicarTodo();
    }
    document.dispatchEvent(new CustomEvent("karma:idioma", { detail: { idioma } }));
  }

  // Alterna entre el idioma base y el inglés
  function alternar() {
    setIdioma(idiomaActual === IDIOMA_BASE ? "en" : IDIOMA_BASE);
  }

  // Funciones públicas que pueden usar otras páginas: KarmaTraductor.setIdioma("en"), .traducir("Hola")…
  window.KarmaTraductor = Object.freeze({
    setIdioma,
    alternar,
    traducir,
    getIdioma: () => idiomaActual,
    idiomaBase: IDIOMA_BASE,
    reescanear: () => { if (idiomaActual !== IDIOMA_BASE) aplicarTodo(); }
  });

  // Al cargar la página se aplica el idioma que el usuario eligió la última vez
  function iniciar() {
    if (idiomaActual !== IDIOMA_BASE) setIdioma(idiomaActual);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", iniciar);
  else iniciar();
})();
