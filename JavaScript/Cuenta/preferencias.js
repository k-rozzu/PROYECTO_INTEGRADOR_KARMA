/* KARMA · Tema e idioma de las páginas de cuenta y del aviso de privacidad.
   Usa las mismas llaves que el POS, el Home y los paneles (karma_tema / karma_idioma), así la preferencia se conserva
   al pasar de una pantalla a otra. Los textos traducibles llevan data-es / data-en, o bloques data-idioma-bloque="es|en". */
(function () {
  "use strict";
  const CLAVE_TEMA = "karma_tema";
  const CLAVE_IDIOMA = "karma_idioma";

  function leer(clave) { try { return localStorage.getItem(clave); } catch (_) { return null; } }
  function guardar(clave, valor) { try { localStorage.setItem(clave, valor); } catch (_) { /* sin almacenamiento */ } }

  function aplicarTema() {
    const oscuro = leer(CLAVE_TEMA) === "dark";
    document.body.classList.toggle("dark", oscuro);
    document.querySelectorAll("[data-icono-tema]").forEach(el => { el.textContent = oscuro ? "☾" : "☀"; });
  }

  function idiomaActual() { return leer(CLAVE_IDIOMA) === "en" ? "en" : "es"; }

  function aplicarIdioma() {
    const idioma = idiomaActual();
    document.documentElement.lang = idioma;
    document.querySelectorAll("[data-es]").forEach(el => {
      const texto = el.getAttribute("data-" + idioma);
      if (texto !== null) el.textContent = texto;
    });
    document.querySelectorAll("[data-placeholder-es]").forEach(el => {
      el.setAttribute("placeholder", el.getAttribute("data-placeholder-" + idioma) || "");
    });
    document.querySelectorAll("[data-idioma-bloque]").forEach(el => { el.hidden = el.getAttribute("data-idioma-bloque") !== idioma; });
    document.querySelectorAll(".lang-op").forEach(el => el.classList.toggle("is-active", el.dataset.lang === idioma));
    const titulo = document.querySelector("meta[name='titulo-" + idioma + "']");
    if (titulo) document.title = titulo.content;
    document.dispatchEvent(new CustomEvent("karma:idioma", { detail: { idioma } }));
  }

  function iniciar() {
    aplicarTema();
    aplicarIdioma();
    document.getElementById("temaToggle")?.addEventListener("click", () => {
      guardar(CLAVE_TEMA, document.body.classList.contains("dark") ? "light" : "dark");
      aplicarTema();
    });
    document.getElementById("idiomaToggle")?.addEventListener("click", () => {
      guardar(CLAVE_IDIOMA, idiomaActual() === "en" ? "es" : "en");
      aplicarIdioma();
    });
    // Si se cambia el tema o el idioma en otra pestaña del sistema, se refleja aquí
    window.addEventListener("storage", (e) => {
      if (e.key === CLAVE_TEMA) aplicarTema();
      if (e.key === CLAVE_IDIOMA) aplicarIdioma();
    });
    window.addEventListener("pageshow", (e) => { if (e.persisted) { aplicarTema(); aplicarIdioma(); } });
  }

  window.KarmaPreferencias = Object.freeze({ idioma: idiomaActual });
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", iniciar);
  else iniciar();
})();
