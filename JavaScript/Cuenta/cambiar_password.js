/* KARMA · Pantalla «Cambiar contraseña» (PHP/Login/cambiar_password.php) → PHP/Login/cuenta.php?action=cambiar_password */
(function () {
  "use strict";
  const $ = (sel) => document.querySelector(sel);
  const CSRF = document.querySelector('meta[name="karma-csrf"]')?.content || "";
  const DESTINO = document.body.dataset.destino || "../../Home/home.html";
  const FORZADO = document.body.dataset.forzado === "1";

  const MENSAJES = {
    es: {
      vacios: "Llena los tres campos.",
      noCoincide: "La confirmación no coincide con la contraseña nueva.",
      reglas: "La contraseña nueva no cumple las reglas indicadas.",
      guardando: "Guardando…",
      listo: "Tu contraseña se cambió correctamente. Te llevamos de regreso…",
      red: "No se pudo conectar con el servidor."
    },
    en: {
      vacios: "Fill in all three fields.",
      noCoincide: "The confirmation does not match the new password.",
      reglas: "The new password does not meet the rules shown.",
      guardando: "Saving…",
      listo: "Your password was changed. Taking you back…",
      red: "Could not connect to the server."
    }
  };
  // Traducción de los errores que regresa el servidor (vienen en español)
  const ERRORES_EN = {
    "Tu contraseña actual no es correcta.": "Your current password is not correct.",
    "La contraseña nueva debe ser distinta de la actual.": "The new password must be different from the current one.",
    "La contraseña nueva debe combinar letras y números.": "The new password must combine letters and numbers.",
    "La contraseña no puede ser tu correo.": "The password cannot be your email.",
    "Demasiados intentos. Espera un minuto e inténtalo de nuevo.": "Too many attempts. Wait a minute and try again.",
    "Tu sesión expiró. Inicia sesión de nuevo.": "Your session expired. Please log in again."
  };
  const idioma = () => (window.KarmaPreferencias?.idioma() === "en" ? "en" : "es");
  const msg = (clave) => MENSAJES[idioma()][clave];
  const traducirError = (texto) => (idioma() === "en" && ERRORES_EN[texto]) || texto;

  function mostrarAlerta(texto, tipo) {
    const alerta = $("#alerta");
    alerta.textContent = texto;
    alerta.classList.toggle("cuenta-alerta--ok", tipo === "ok");
    alerta.hidden = !texto;
  }

  // Marca en verde las reglas que ya se cumplen mientras se escribe
  function revisarReglas() {
    const nueva = $("#nueva").value;
    const reglas = {
      largo: nueva.length >= 8,
      mezcla: /\p{L}/u.test(nueva) && /\d/.test(nueva),
      distinta: nueva !== "" && nueva !== $("#actual").value
    };
    document.querySelectorAll("[data-regla]").forEach(li => li.classList.toggle("ok", reglas[li.dataset.regla]));
    return Object.values(reglas).every(Boolean);
  }
  $("#nueva").addEventListener("input", revisarReglas);
  $("#actual").addEventListener("input", revisarReglas);

  $("#formPassword").addEventListener("submit", async (e) => {
    e.preventDefault();
    const actual = $("#actual").value;
    const nueva = $("#nueva").value;
    const confirmacion = $("#confirmacion").value;
    if (!actual || !nueva || !confirmacion) return mostrarAlerta(msg("vacios"));
    if (!revisarReglas()) return mostrarAlerta(msg("reglas"));
    if (nueva !== confirmacion) return mostrarAlerta(msg("noCoincide"));

    const boton = $("#guardarBtn");
    const textoBoton = boton.textContent;
    boton.disabled = true;
    boton.textContent = msg("guardando");
    try {
      const respuesta = await fetch("cuenta.php?action=cambiar_password", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": CSRF },
        body: JSON.stringify({ actual, nueva, confirmacion })
      });
      const datos = await respuesta.json().catch(() => ({ ok: false, error: msg("red") }));
      if (respuesta.status === 401) { window.location.replace("../../index.html"); return; }
      if (!respuesta.ok || !datos.ok) throw new Error(datos.error || msg("red"));

      // La sesión guardada en el navegador deja de marcar la contraseña temporal
      try {
        const usuario = JSON.parse(localStorage.getItem("karma_user") || "null");
        if (usuario) { usuario.debe_cambiar_password = false; localStorage.setItem("karma_user", JSON.stringify(usuario)); }
      } catch (_) { /* sin almacenamiento */ }

      $("#formPassword").reset();
      revisarReglas();
      mostrarAlerta(msg("listo"), "ok");
      setTimeout(() => window.location.replace(datos.destino || DESTINO), 1400);
    } catch (error) {
      mostrarAlerta(traducirError(error.message));
      boton.disabled = false;
      boton.textContent = textoBoton;
    }
  });

  // Cerrar sesión (útil si la contraseña temporal no es tuya o quieres salir sin cambiarla)
  $("#salirBtn").addEventListener("click", async () => {
    try { localStorage.removeItem("karma_user"); } catch (_) { /* sin almacenamiento */ }
    try { await fetch("../PuntoDeVenta/api.php?action=logout"); } catch (_) { /* sin red */ }
    window.location.replace("../../index.html");
  });

  // Con contraseña temporal no se puede regresar con «Atrás» a una pantalla del sistema
  if (FORZADO) history.replaceState(null, "", window.location.href);
})();
