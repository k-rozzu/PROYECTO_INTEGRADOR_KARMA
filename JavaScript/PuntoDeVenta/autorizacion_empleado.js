/* ===== KARMA · Punto de Venta — Autorización de empleado (gafete QR o código manual) =====
   Antes de concretar una venta o un crédito, aplicar una garantía o cobrar/cancelar una orden web se pide el gafete del usuario
   que tiene la sesión abierta. Este archivo SOLO obtiene el texto del gafete (cámara + jsQR, o escrito a mano) y lo envía a
   api.php?action=autorizar_empleado: quien decide es el servidor (PHP/PuntoDeVenta/autorizacion_empleado.php).
   Si autoriza, entrega un permiso de un solo uso que la operación original manda a api.php; si no, la operación no se envía.
   Nada se guarda en localStorage, no se guardan imágenes y la cámara se apaga al leer un QR, al cancelar, al cerrar o con un error.
   Usa $, escapeHTML y apiFetch de script.js (se carga antes que este archivo). */

// Librería jsQR (JavaScript/PuntoDeVenta/lib): se descarga solo la primera vez que se abre el modal
const RUTA_JSQR = new URL("lib/jsQR.js", document.currentScript.src).href;
// Formato del gafete (EMP-0001): solo para avisar en pantalla; el servidor valida contra la base de datos
const FORMATO_CODIGO_EMPLEADO = /^EMP-\d{4,16}$/;
// Texto que aparece arriba del título según la acción protegida
const ETIQUETAS_AUTORIZACION = { VENTA: "Concretar venta", CREDITO: "Concretar crédito", GARANTIA: "Aplicar garantía", ORDEN_WEB: "Orden web", ABONO: "Cobrar abono" };

let autorizacionActual = null;   // estado del modal mientras está abierto (acción, referencia, cámara, envío…)
let promesaJsQR = null;          // carga única de la librería

// Pide la autorización y resuelve con el permiso del servidor, o con null si se cancela (la acción original NO debe seguir)
function solicitarAutorizacionEmpleado(accion, referencia, etiqueta){
  if (autorizacionActual) return Promise.resolve(null);
  return new Promise(resolve => {
    autorizacionActual = {
      accion, referencia, resolver: resolve,
      etiqueta: etiqueta || ETIQUETAS_AUTORIZACION[accion] || "Acción protegida",
      modo: "camara", stream: null, raf: 0, ultimoEscaneo: 0, lienzo: null,
      iniciando: false, enviando: false, focoPrevio: document.activeElement, inertes: []
    };
    abrirModalAutorizacion();
  });
}

// Dibuja el modal, bloquea el resto del POS mientras está abierto y enciende la cámara
function abrirModalAutorizacion(){
  const ctx = autorizacionActual;
  const overlay = $("#modalAutorizacion");
  $("#modalAutorizacionContent").innerHTML = `
    <button class="modal-close" id="authCerrar" type="button" aria-label="Cerrar">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 5l14 14M19 5L5 19"/></svg>
    </button>
    <p class="auth-eyebrow">${escapeHTML(ctx.etiqueta)}</p>
    <div class="payment-title" id="authTitulo">Autorización de empleado</div>
    <p class="payment-subtitle" id="authSubtitulo">Escanea el código QR de tu gafete para continuar.</p>

    <div class="auth-camara" id="authCamara" data-estado="cargando">
      <video id="authVideo" playsinline muted></video>
      <div class="auth-marco" aria-hidden="true"><span></span></div>
      <div class="auth-camara-estado" id="authCamaraEstado" role="status">Activando cámara…</div>
      <button class="btn auth-reintentar" id="authReintentar" type="button" hidden>Activar cámara</button>
    </div>

    <form class="auth-manual" id="authManual" novalidate hidden>
      <div class="form-field">
        <label for="authCodigo">Código de empleado</label>
        <input type="text" id="authCodigo" class="auth-codigo" placeholder="EMP-0001" maxlength="20" autocomplete="off" autocapitalize="characters" spellcheck="false" translate="no">
      </div>
      <button class="btn btn-primary auth-autorizar" id="authAutorizar" type="submit">Autorizar</button>
    </form>

    <div class="cash-message auth-mensaje" id="authMensaje" role="alert"></div>

    <div class="auth-alterna">
      <span id="authAlternaTexto">¿No tienes tu gafete?</span>
      <button class="auth-enlace" id="authAlterna" type="button">Introducir código manualmente</button>
    </div>
    <div class="payment-actions"><button class="btn btn-ghost" id="authCancelar" type="button">Cancelar</button></div>
  `;

  // El resto de la página queda inerte (sin clics ni foco) hasta cerrar el modal
  ctx.inertes = [...document.body.children].filter(el => el !== overlay && !el.inert && !["SCRIPT", "STYLE"].includes(el.tagName));
  ctx.inertes.forEach(el => { el.inert = true; });
  overlay.hidden = false;
  window.addEventListener("keydown", teclasAutorizacion, true);
  document.addEventListener("visibilitychange", pausarCamaraOculta);

  $("#authCerrar").addEventListener("click", cancelarAutorizacion);
  $("#authCancelar").addEventListener("click", cancelarAutorizacion);
  $("#authAlterna").addEventListener("click", () => cambiarModoAutorizacion(autorizacionActual?.modo === "camara" ? "manual" : "camara"));
  $("#authReintentar").addEventListener("click", iniciarCamaraAutorizacion);
  $("#authManual").addEventListener("submit", (e) => { e.preventDefault(); enviarCodigoManual(); });
  $("#authCodigo").addEventListener("input", (e) => {
    e.target.value = normalizarCodigoEmpleado(e.target.value);
    mostrarMensajeAutorizacion("");
  });

  $("#authAlterna").focus();
  iniciarCamaraAutorizacion();
}

// Cambia entre leer el QR con la cámara y escribir el código (al escribir, la cámara se apaga)
function cambiarModoAutorizacion(modo){
  const ctx = autorizacionActual;
  if (!ctx || ctx.enviando) return;
  const manual = modo === "manual";
  ctx.modo = modo;
  mostrarMensajeAutorizacion("");
  $("#authCamara").hidden = manual;
  $("#authManual").hidden = !manual;
  $("#authSubtitulo").textContent = manual ? "Escribe el código impreso en tu gafete para continuar." : "Escanea el código QR de tu gafete para continuar.";
  $("#authAlternaTexto").textContent = manual ? "¿Tienes tu gafete a la mano?" : "¿No tienes tu gafete?";
  $("#authAlterna").textContent = manual ? "Escanear con la cámara" : "Introducir código manualmente";
  if (manual){
    detenerCamaraAutorizacion(ctx);
    $("#authCodigo").focus();
  } else {
    iniciarCamaraAutorizacion();
  }
}

// Quita espacios y pasa a mayúsculas (" emp-0001 " -> "EMP-0001"); igual lo hace el servidor
function normalizarCodigoEmpleado(texto){
  return String(texto ?? "").replace(/\s+/g, "").toUpperCase();
}

/* ----- Cámara y lectura del QR ----- */

// Carga jsQR una sola vez (si falla, se puede seguir con el código manual)
function cargarJsQR(){
  if (window.jsQR) return Promise.resolve();
  if (!promesaJsQR){
    promesaJsQR = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = RUTA_JSQR;
      script.onload = () => window.jsQR ? resolve() : reject(Object.assign(new Error("jsQR"), { name: "ErrorLectorQR" }));
      script.onerror = () => { promesaJsQR = null; reject(Object.assign(new Error("jsQR"), { name: "ErrorLectorQR" })); };
      document.head.appendChild(script);
    });
  }
  return promesaJsQR;
}

// Pide permiso y enciende la cámara (trasera si existe; en laptop, la frontal) para buscar el QR
async function iniciarCamaraAutorizacion(){
  const ctx = autorizacionActual;
  if (!ctx || ctx.modo !== "camara" || ctx.stream || ctx.iniciando || ctx.enviando) return;
  ctx.iniciando = true;
  $("#authReintentar").hidden = true;
  mostrarMensajeAutorizacion("");
  estadoCamara("Activando cámara…", "cargando");
  try {
    if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia){
      throw Object.assign(new Error("Sin cámara"), { name: "ErrorNavegador" });
    }
    await cargarJsQR();
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: "environment" }, width: { ideal: 1280 }, height: { ideal: 720 } },
      audio: false
    });
    // Si el modal se cerró o se cambió a manual mientras el navegador pedía permiso, la cámara se apaga de inmediato
    if (autorizacionActual !== ctx || ctx.modo !== "camara"){
      stream.getTracks().forEach(t => t.stop());
      return;
    }
    ctx.stream = stream;
    const video = $("#authVideo");
    // Vista en espejo con cámara frontal (más natural); la lectura usa la imagen original
    video.classList.toggle("is-espejo", stream.getVideoTracks()[0]?.getSettings?.().facingMode !== "environment");
    video.srcObject = stream;
    await video.play();
    estadoCamara("Acerca el QR de tu gafete al recuadro", "listo");
    ctx.raf = requestAnimationFrame(escanearCuadroAutorizacion);
  } catch (error) {
    if (autorizacionActual !== ctx) return;
    detenerCamaraAutorizacion(ctx);
    if (ctx.modo !== "camara") return;
    estadoCamara(mensajeErrorCamara(error), "error");
    mostrarBotonCamara("Reintentar cámara");
  } finally {
    ctx.iniciando = false;
  }
}

// Mensaje claro para cada problema de cámara (en todos los casos sigue disponible el código manual)
function mensajeErrorCamara(error){
  switch (error?.name){
    case "NotAllowedError":
    case "SecurityError":       return "Permiso de cámara denegado. Introduce el código manualmente.";
    case "NotFoundError":
    case "OverconstrainedError": return "No se encontró una cámara en este equipo. Introduce el código manualmente.";
    case "NotReadableError":
    case "AbortError":          return "La cámara está ocupada por otra aplicación. Ciérrala o introduce el código manualmente.";
    case "ErrorLectorQR":       return "No se pudo cargar el lector de QR. Introduce el código manualmente.";
    case "ErrorNavegador":      return "Este navegador no permite usar la cámara aquí. Introduce el código manualmente.";
    default:                    return "No se pudo activar la cámara. Introduce el código manualmente.";
  }
}

// Revisa ~7 cuadros por segundo; al encontrar un gafete válido apaga la cámara y consulta al servidor
function escanearCuadroAutorizacion(ahora){
  const ctx = autorizacionActual;
  if (!ctx || !ctx.stream || ctx.enviando) return;
  ctx.raf = requestAnimationFrame(escanearCuadroAutorizacion);
  const video = $("#authVideo");
  if (ahora - ctx.ultimoEscaneo < 140 || !video || video.readyState < 2 || !video.videoWidth) return;
  ctx.ultimoEscaneo = ahora;

  // Cuadro reducido a máx. 720 px: suficiente para un gafete y ligero para la laptop
  const escala = Math.min(1, 720 / Math.max(video.videoWidth, video.videoHeight));
  const ancho = Math.round(video.videoWidth * escala);
  const alto = Math.round(video.videoHeight * escala);
  const lienzo = ctx.lienzo || (ctx.lienzo = document.createElement("canvas"));
  if (lienzo.width !== ancho) lienzo.width = ancho;
  if (lienzo.height !== alto) lienzo.height = alto;
  const dibujo = lienzo.getContext("2d", { willReadFrequently: true });
  dibujo.drawImage(video, 0, 0, ancho, alto);
  const lectura = window.jsQR(dibujo.getImageData(0, 0, ancho, alto).data, ancho, alto, { inversionAttempts: "dontInvert" });
  if (!lectura?.data) return;

  const codigo = normalizarCodigoEmpleado(lectura.data);
  if (!FORMATO_CODIGO_EMPLEADO.test(codigo)){
    // QR que no es un gafete: se avisa y se sigue buscando (no se envía nada)
    mostrarMensajeAutorizacion("El código QR leído no es un gafete de empleado válido.", "error");
    return;
  }
  detenerCamaraAutorizacion(ctx);
  estadoCamara("Gafete leído. Verificando…", "cargando");
  enviarCodigoAutorizacion(codigo, "qr");
}

// Apaga la cámara de verdad (detiene cada pista del stream) y suelta el video
function detenerCamaraAutorizacion(ctx = autorizacionActual){
  if (!ctx) return;
  cancelAnimationFrame(ctx.raf);
  ctx.raf = 0;
  if (ctx.stream){
    ctx.stream.getTracks().forEach(t => t.stop());
    ctx.stream = null;
  }
  const video = $("#authVideo");
  if (video){
    video.pause();
    video.srcObject = null;
  }
}

// Si se cambia de pestaña o se minimiza, la cámara se apaga; se puede volver a activar con un clic
function pausarCamaraOculta(){
  const ctx = autorizacionActual;
  if (!ctx || !document.hidden || !ctx.stream) return;
  detenerCamaraAutorizacion(ctx);
  estadoCamara("Cámara en pausa.", "error");
  mostrarBotonCamara("Activar cámara");
}

/* ----- Envío al servidor (QR y manual pasan por exactamente la misma validación) ----- */

// Valida el formato en pantalla (solo para avisar pronto) y lo envía al servidor
function enviarCodigoManual(){
  const input = $("#authCodigo");
  const codigo = normalizarCodigoEmpleado(input.value);
  input.value = codigo;
  if (!codigo){
    mostrarMensajeAutorizacion("Escribe tu código de empleado.", "error");
    input.focus();
    return;
  }
  if (!FORMATO_CODIGO_EMPLEADO.test(codigo)){
    mostrarMensajeAutorizacion("El código de empleado no es válido. Formato: EMP-0001.", "error");
    input.focus();
    return;
  }
  enviarCodigoAutorizacion(codigo, "manual");
}

// Manda SOLO el código, la acción y su referencia; el servidor decide y, si autoriza, regresa el permiso de un solo uso
async function enviarCodigoAutorizacion(codigo, metodo){
  const ctx = autorizacionActual;
  if (!ctx || ctx.enviando) return;
  ctx.enviando = true;
  bloquearControlesAutorizacion(true);
  mostrarMensajeAutorizacion("Verificando con el servidor…");
  try {
    const data = await apiFetch("autorizar_empleado", {
      method: "POST",
      body: JSON.stringify({ codigo_empleado: codigo, accion: ctx.accion, referencia: ctx.referencia, metodo })
    });
    if (autorizacionActual !== ctx) return;
    if (data.autorizado !== true || typeof data.autorizacion !== "string" || !data.autorizacion){
      throw new Error("Autorización rechazada.");
    }
    mostrarMensajeAutorizacion("Empleado autorizado.", "ok");
    setTimeout(() => cerrarModalAutorizacion(data.autorizacion, ctx), 350);
  } catch (error) {
    if (autorizacionActual !== ctx) return;
    ctx.enviando = false;
    bloquearControlesAutorizacion(false);
    mostrarMensajeAutorizacion(error.message || "Autorización rechazada.", "error");
    if (ctx.modo === "camara"){
      estadoCamara("No autorizado.", "error");
      mostrarBotonCamara("Escanear de nuevo");
    } else {
      $("#authCodigo").select();
      $("#authCodigo").focus();
    }
  }
}

/* ----- Cierre y utilidades del modal ----- */

// Cierra el modal (apaga la cámara, libera la página) y entrega el resultado a la acción que lo pidió
function cerrarModalAutorizacion(resultado, ctx = autorizacionActual){
  if (!ctx || autorizacionActual !== ctx) return;
  detenerCamaraAutorizacion(ctx);
  autorizacionActual = null;
  window.removeEventListener("keydown", teclasAutorizacion, true);
  document.removeEventListener("visibilitychange", pausarCamaraOculta);
  ctx.inertes.forEach(el => { el.inert = false; });
  $("#modalAutorizacion").hidden = true;
  $("#modalAutorizacionContent").innerHTML = "";
  if (ctx.focoPrevio && document.contains(ctx.focoPrevio)) ctx.focoPrevio.focus?.();
  ctx.resolver(resultado || null);
}

// Cancelar = no autorizado: la acción original no continúa
function cancelarAutorizacion(){
  cerrarModalAutorizacion(null);
}

// Mientras el modal está abierto: Esc cancela y los atajos F3–F6 del POS no se disparan detrás
function teclasAutorizacion(e){
  if (!autorizacionActual) return;
  if (e.key === "Escape"){
    e.preventDefault();
    e.stopImmediatePropagation();
    cancelarAutorizacion();
  } else if (["F3", "F4", "F5", "F6"].includes(e.key)){
    e.preventDefault();
    e.stopImmediatePropagation();
  }
}

// Texto sobre el visor de la cámara (cargando | listo | error)
function estadoCamara(texto, estado){
  const camara = $("#authCamara");
  if (!camara) return;
  camara.dataset.estado = estado;
  $("#authCamaraEstado").textContent = texto;
}

// Botón dentro del visor para volver a encender la cámara
function mostrarBotonCamara(texto){
  const boton = $("#authReintentar");
  if (!boton) return;
  boton.textContent = texto;
  boton.hidden = false;
}

// Mensaje debajo del lector (ok = verde, error = rojo)
function mostrarMensajeAutorizacion(texto, tipo){
  const msg = $("#authMensaje");
  if (!msg) return;
  msg.textContent = texto;
  msg.classList.toggle("is-error", tipo === "error");
  msg.classList.toggle("is-ok", tipo === "ok");
}

// Evita doble envío mientras el servidor responde (Cancelar sigue disponible)
function bloquearControlesAutorizacion(bloquear){
  ["#authAutorizar", "#authCodigo", "#authAlterna", "#authReintentar"].forEach(sel => {
    const el = $(sel);
    if (el) el.disabled = bloquear;
  });
}

// Clic en el fondo oscuro = cancelar
$("#modalAutorizacion")?.addEventListener("click", (e) => {
  if (e.target === e.currentTarget) cancelarAutorizacion();
});
