/* KARMA · Vista previa 3D (Three.js): muestra el vehículo o la refacción elegida con el color guardado en la base de datos */
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";

// ===== CONFIGURACIÓN =====

// Carpeta raíz del proyecto (para resolver rutas como assets/models/12.glb)
const RAIZ = new URL("../../", import.meta.url);
// Color de respaldo cuando el producto no tiene color en la BD
const COLOR_RESPALDO = "#8C9096";
// Ángulo inicial de la cámara: 38° de lado y 16° desde arriba
const ANGULO_LADO = THREE.MathUtils.degToRad(38);
const ANGULO_ALTURA = THREE.MathUtils.degToRad(16);
// Respeta la opción del sistema "reducir movimiento" (empieza sin rotar)
const REDUCIR_MOVIMIENTO = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

// Luces y sombra de cada tema: claro = blanco + azul marino, oscuro = negro + rojo oscuro
const TEMAS = {
  claro:  { cielo: 0xffffff, suelo: 0xc9d3e6, hemi: 1.1, clave: 0xffffff, claveInt: 2.2, contra: 0x2a4f9a, contraInt: 2.6, relleno: 0xe4ebf7, rellenoInt: 0.7, sombra: 0x10213f, sombraOpacidad: 0.32, entorno: 0.85, exposicion: 1.0 },
  oscuro: { cielo: 0x40404a, suelo: 0x060607, hemi: 0.5, clave: 0xfff1ec, claveInt: 1.7, contra: 0xc4142f, contraInt: 5.0, relleno: 0x6b1422, rellenoInt: 1.1, sombra: 0x000000, sombraOpacidad: 0.7, entorno: 0.45, exposicion: 0.95 }
};

// Nombres de material que cuentan como pintura/acabado principal en un .glb (CarPaint, Paint, livery, Pintura…)
const MATERIAL_PINTURA = /pintura|carrocer|carpaint|paint|livery|body|acabado/i;
// Nombres que nunca se pintan aunque se parezcan (molduras, carbono, negro sólido, cromo, vidrio, llantas, interior)
const MATERIAL_EXCLUIDO = /trim|carbon|solid|chrome|cromo|glass|vidrio|rubber|tyre|tire|llanta|rim|interior/i;

// Proporciones (metros) de los 3 tipos de carrocería genérica
const PERFILES_AUTO = {
  deportivo: { largo: 4.35, ancho: 1.86, piso: 0.24, cintura: 0.84, nariz: 0.64, cola: 0.86, techo: 1.27, rueda: 0.35, ejeDel: 1.36, ejeTras: -1.30, cabDel: 0.52, cabTras: -1.85, techoDel: -0.10, techoTras: -0.80 },
  sedan:     { largo: 4.85, ancho: 1.90, piso: 0.26, cintura: 0.95, nariz: 0.74, cola: 0.98, techo: 1.43, rueda: 0.36, ejeDel: 1.50, ejeTras: -1.42, cabDel: 0.82, cabTras: -1.42, techoDel: 0.18, techoTras: -0.82 },
  suv:       { largo: 4.85, ancho: 1.96, piso: 0.36, cintura: 1.12, nariz: 0.95, cola: 1.12, techo: 1.72, rueda: 0.40, ejeDel: 1.46, ejeTras: -1.46, cabDel: 0.92, cabTras: -2.12, techoDel: 0.30, techoTras: -1.90 }
};

// ===== ESTADO DEL MOTOR 3D (se crea una sola vez y se reutiliza en cada redibujado del formulario) =====

let renderer = null;
let escena, camara, controles, reloj, grupoGiro, sombra;
let envoltura, capaCarga, etiquetaTipo, chipColor, btnPausa;
const luces = {};
let modeloActual = null;
let claveActual = "";
let cargaActual = 0;
let animando = false;
let girando = !REDUCIR_MOVIMIENTO;
let giroObjetivo = 0;
const cacheGLB = new Map();
const cargadorGLB = new GLTFLoader();
// Si el cuadro cambia de tamaño, se ajusta el canvas y se vuelve a encuadrar el modelo
const observadorTamano = new ResizeObserver(() => { if (ajustarTamano() && modeloActual) encuadrar(modeloActual); });
let ultimoTamano = "";

// Íconos SVG de los controles flotantes
const ICONOS = {
  izquierda: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M15 6l-6 6 6 6"/></svg>`,
  derecha: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 6l6 6-6 6"/></svg>`,
  pausa: `<svg viewBox="0 0 24 24" fill="currentColor"><rect x="7" y="6" width="3.2" height="12" rx="1"/><rect x="13.8" y="6" width="3.2" height="12" rx="1"/></svg>`,
  reanudar: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l10.5-6.5z"/></svg>`,
  reajustar: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4.5 12a7.5 7.5 0 1 0 2.2-5.3"/><path d="M4.5 4.5v4h4"/></svg>`
};

// ===== ARRANQUE DEL MOTOR =====

// Crea renderer, escena, cámara, luces y controles la primera vez que se necesita (false si no hay WebGL)
function iniciarMotor() {
  if (renderer) return true;
  try {
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  } catch (_) {
    renderer = null;
    return false;
  }
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.setClearColor(0x000000, 0);

  // Escena con reflejos de "estudio" para que la pintura se vea brillante
  escena = new THREE.Scene();
  const pmrem = new THREE.PMREMGenerator(renderer);
  escena.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
  pmrem.dispose();

  // Cámara y controles de órbita: arrastrar para girar, rueda para zoom, rotación automática suave
  camara = new THREE.PerspectiveCamera(32, 1, 0.05, 200);
  controles = new OrbitControls(camara, renderer.domElement);
  controles.enableDamping = true;
  controles.dampingFactor = 0.08;
  controles.enablePan = false;
  controles.autoRotate = girando;
  controles.autoRotateSpeed = 1.6;
  controles.minPolarAngle = 0.15;
  controles.maxPolarAngle = Math.PI * 0.49;

  // Luces de estudio: ambiente, principal, contraluz de color del tema y relleno
  luces.hemi = new THREE.HemisphereLight();
  luces.clave = new THREE.DirectionalLight();
  luces.clave.position.set(5, 7, 6);
  luces.contra = new THREE.DirectionalLight();
  luces.contra.position.set(-6, 3.5, -6);
  luces.relleno = new THREE.DirectionalLight();
  luces.relleno.position.set(-5, 2, 5);
  escena.add(luces.hemi, luces.clave, luces.contra, luces.relleno);

  // Grupo que giran las flechas; dentro van el modelo y su sombra
  grupoGiro = new THREE.Group();
  sombra = crearSombra();
  grupoGiro.add(sombra);
  escena.add(grupoGiro);
  reloj = new THREE.Timer();

  construirEnvoltura();
  new MutationObserver(aplicarTema).observe(document.body, { attributes: true, attributeFilter: ["class"] });
  aplicarTema();
  return true;
}

// Arma el HTML fijo del visor: canvas + etiqueta + color + controles flotantes + indicador de carga
function construirEnvoltura() {
  envoltura = document.createElement("div");
  envoltura.className = "vista3d-escena";
  envoltura.innerHTML = `
    <span class="vista3d-etiqueta"></span>
    <span class="vista3d-color"><i></i><span></span></span>
    <div class="vista3d-controles">
      <button type="button" class="vista3d-btn" data-accion="izquierda" title="Girar a la izquierda">${ICONOS.izquierda}</button>
      <button type="button" class="vista3d-btn" data-accion="pausa" title="Pausar rotación">${ICONOS.pausa}</button>
      <button type="button" class="vista3d-btn" data-accion="derecha" title="Girar a la derecha">${ICONOS.derecha}</button>
      <button type="button" class="vista3d-btn" data-accion="reajustar" title="Reajustar vista">${ICONOS.reajustar}</button>
    </div>
    <div class="vista3d-cargando" hidden><span class="vista3d-spinner"></span><span>Cargando modelo 3D…</span></div>`;
  envoltura.prepend(renderer.domElement);
  capaCarga = envoltura.querySelector(".vista3d-cargando");
  etiquetaTipo = envoltura.querySelector(".vista3d-etiqueta");
  chipColor = envoltura.querySelector(".vista3d-color");
  btnPausa = envoltura.querySelector('[data-accion="pausa"]');
  envoltura.querySelectorAll("[data-accion]").forEach(btn => btn.addEventListener("click", () => accionControl(btn.dataset.accion)));
  actualizarBotonPausa();
}

// Ejecuta el control flotante presionado (girar, pausar/reanudar o reajustar)
function accionControl(accion) {
  if (accion === "izquierda") giroObjetivo += Math.PI / 4;
  else if (accion === "derecha") giroObjetivo -= Math.PI / 4;
  else if (accion === "pausa") {
    girando = !girando;
    controles.autoRotate = girando;
    actualizarBotonPausa();
  } else if (accion === "reajustar") {
    giroObjetivo = 0;
    controles.reset();
  }
}

// Cambia el ícono y el texto de ayuda del botón pausar/reanudar
function actualizarBotonPausa() {
  btnPausa.innerHTML = girando ? ICONOS.pausa : ICONOS.reanudar;
  btnPausa.title = girando ? "Pausar rotación" : "Reanudar rotación";
}

// Sombra suave bajo el modelo (círculo difuminado dibujado en un canvas)
function crearSombra() {
  const lienzo = document.createElement("canvas");
  lienzo.width = lienzo.height = 128;
  const ctx = lienzo.getContext("2d");
  const degradado = ctx.createRadialGradient(64, 64, 0, 64, 64, 64);
  degradado.addColorStop(0, "rgba(255,255,255,1)");
  degradado.addColorStop(0.45, "rgba(255,255,255,.55)");
  degradado.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = degradado;
  ctx.fillRect(0, 0, 128, 128);
  const material = new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(lienzo), transparent: true, depthWrite: false });
  const plano = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), material);
  plano.rotation.x = -Math.PI / 2;
  plano.renderOrder = -1;
  return plano;
}

// Ajusta luces, sombra y reflejos según el modo claro/oscuro (el fondo lo pone el CSS)
function aplicarTema() {
  if (!renderer) return;
  const t = document.body.classList.contains("dark") ? TEMAS.oscuro : TEMAS.claro;
  luces.hemi.color.setHex(t.cielo);
  luces.hemi.groundColor.setHex(t.suelo);
  luces.hemi.intensity = t.hemi;
  luces.clave.color.setHex(t.clave);
  luces.clave.intensity = t.claveInt;
  luces.contra.color.setHex(t.contra);
  luces.contra.intensity = t.contraInt;
  luces.relleno.color.setHex(t.relleno);
  luces.relleno.intensity = t.rellenoInt;
  sombra.material.color.setHex(t.sombra);
  sombra.material.opacity = t.sombraOpacidad;
  escena.environmentIntensity = t.entorno;
  renderer.toneMappingExposure = t.exposicion;
}

// Ajusta el canvas al tamaño del cuadro del formulario (regresa true si el tamaño cambió)
function ajustarTamano() {
  const caja = envoltura?.parentElement;
  if (!caja) return false;
  const ancho = caja.clientWidth || 320;
  const alto = caja.clientHeight || 260;
  if (`${ancho}x${alto}` === ultimoTamano) return false;
  ultimoTamano = `${ancho}x${alto}`;
  renderer.setSize(ancho, alto, false);
  camara.aspect = ancho / alto;
  camara.updateProjectionMatrix();
  return true;
}

// Ciclo de animación: gira el grupo hacia su ángulo objetivo, actualiza controles y dibuja
function cuadro(tiempo) {
  if (!envoltura.isConnected) {
    renderer.setAnimationLoop(null);
    animando = false;
    return;
  }
  reloj.update(tiempo);
  const dt = Math.min(reloj.getDelta(), 0.1);
  grupoGiro.rotation.y += (giroObjetivo - grupoGiro.rotation.y) * Math.min(1, dt * 7);
  controles.update(dt);
  renderer.render(escena, camara);
}

// Arranca el ciclo de animación si estaba detenido
function arrancar() {
  if (animando) return;
  animando = true;
  renderer.setAnimationLoop(cuadro);
}

// ===== FUNCIÓN PÚBLICA: la llama script.js cada vez que dibuja el cuadro de vista previa =====

// Coloca el visor dentro del cuadro y, si cambió el producto, carga su modelo con su color
function mostrar(contenedor, producto) {
  if (!contenedor) return;
  if (!producto) { contenedor.replaceChildren(); return; }
  if (!iniciarMotor()) {
    contenedor.innerHTML = `<div class="vista3d-cargando">Tu navegador no permite mostrar gráficos 3D (WebGL).</div>`;
    return;
  }
  if (envoltura.parentNode !== contenedor) contenedor.replaceChildren(envoltura);
  observadorTamano.disconnect();
  observadorTamano.observe(contenedor);
  ajustarTamano();
  actualizarChipColor(producto);
  const clave = [producto.id, producto.tipo, producto.colorHex, producto.modelo3d].join("|");
  if (clave !== claveActual) cargarProducto(producto, clave);
  arrancar();
}

// Muestra abajo a la izquierda el nombre y la muestra del color que viene de la BD
function actualizarChipColor(producto) {
  chipColor.hidden = !producto.color;
  chipColor.querySelector("i").style.background = producto.colorHex || COLOR_RESPALDO;
  chipColor.querySelector("span").textContent = producto.color || "";
}

// ===== CARGA DEL MODELO (archivo .glb o modelo genérico de respaldo) =====

// Convierte el color_hex de la BD en un color de Three.js (o usa el de respaldo)
function colorDelProducto(producto) {
  const hex = String(producto?.colorHex || "").trim();
  if (/^#?[0-9a-f]{6}$/i.test(hex)) return new THREE.Color(hex.startsWith("#") ? hex : `#${hex}`);
  return new THREE.Color(COLOR_RESPALDO);
}

// Carga el producto: primero intenta su .glb; si no tiene o falla, arma el modelo genérico con su color
async function cargarProducto(producto, clave) {
  claveActual = clave;
  const miCarga = ++cargaActual;
  const avisoCarga = setTimeout(() => { if (miCarga === cargaActual) capaCarga.hidden = false; }, 120);
  const color = colorDelProducto(producto);
  let objeto = null;
  let generico = false;

  // Modelo propio: ruta del campo modelo_3d de la BD o assets/models/{id}.glb
  if (producto.modelo3d) {
    const ruta = new URL(producto.modelo3d, RAIZ).href;
    try {
      objeto = await cargarGLB(ruta);
      pintarGLB(objeto, color);
    } catch (error) {
      console.warn("[Vista 3D] No se pudo cargar el modelo", ruta, error);
      objeto = null;
    }
  }
  // Si mientras cargaba se eligió otro producto, esta carga se descarta
  if (miCarga !== cargaActual) return;

  // Respaldo: modelo genérico armado aquí mismo con el color de la BD
  if (!objeto) {
    objeto = crearModeloGenerico(producto, color);
    generico = true;
  }

  colocarEnPiso(objeto);
  quitarModeloActual();
  modeloActual = objeto;
  giroObjetivo = 0;
  grupoGiro.rotation.y = 0;
  grupoGiro.add(objeto);
  encuadrar(objeto);
  etiquetaTipo.textContent = generico ? "Modelo genérico" : "Modelo 3D";
  clearTimeout(avisoCarga);
  capaCarga.hidden = true;
}

// Descarga un .glb una sola vez y regresa una copia lista para usarse
function cargarGLB(ruta) {
  if (!cacheGLB.has(ruta)) {
    cacheGLB.set(ruta, new Promise((resolver, rechazar) => cargadorGLB.load(ruta, gltf => resolver(gltf.scene), undefined, rechazar)));
  }
  return cacheGLB.get(ruta)
    .then(original => { const copia = original.clone(true); copia.userData.esGLB = true; return copia; })
    .catch(error => { cacheGLB.delete(ruta); throw error; });
}

// Pinta el .glb con el color de la BD: su material de pintura (sin molduras ni vidrios) o, si no hay, la pieza más grande
function pintarGLB(objeto, color) {
  const mallas = [];
  objeto.traverse(nodo => { if (nodo.isMesh) mallas.push(nodo); });
  const esPintura = material => MATERIAL_PINTURA.test(material?.name || "") && !MATERIAL_EXCLUIDO.test(material?.name || "");
  const listaDe = malla => (Array.isArray(malla.material) ? malla.material : [malla.material]);
  let objetivo = mallas.filter(malla => listaDe(malla).some(esPintura));
  // Sin nombres reconocibles: se pinta la malla con mayor volumen (normalmente la carrocería)
  if (!objetivo.length && mallas.length) {
    const volumen = malla => { const t = new THREE.Box3().setFromObject(malla).getSize(new THREE.Vector3()); return t.x * t.y * t.z; };
    objetivo = [mallas.reduce((mayor, malla) => (volumen(malla) > volumen(mayor) ? malla : mayor))];
  }
  objetivo.forEach(malla => {
    const lista = listaDe(malla);
    const hayNombrados = lista.some(esPintura);
    const nuevos = lista.map(material => {
      if (!material?.color || (hayNombrados && !esPintura(material))) return material;
      // Copia del material con el color exacto de la BD (se quita la imagen de color; el relieve se conserva)
      const copia = material.clone();
      copia.color.copy(color);
      copia.map = null;
      copia.needsUpdate = true;
      return copia;
    });
    malla.material = Array.isArray(malla.material) ? nuevos : nuevos[0];
  });
}

// Centra el modelo y lo apoya sobre el piso (y = 0)
function colocarEnPiso(objeto) {
  const caja = new THREE.Box3().setFromObject(objeto);
  const centro = caja.getCenter(new THREE.Vector3());
  objeto.position.x -= centro.x;
  objeto.position.z -= centro.z;
  objeto.position.y -= caja.min.y;
}

// Quita el modelo anterior y libera su memoria (los .glb comparten geometría con la caché, por eso no se liberan)
function quitarModeloActual() {
  if (!modeloActual) return;
  grupoGiro.remove(modeloActual);
  if (!modeloActual.userData.esGLB) {
    modeloActual.traverse(nodo => {
      if (!nodo.isMesh) return;
      nodo.geometry.dispose();
      (Array.isArray(nodo.material) ? nodo.material : [nodo.material]).forEach(m => m.dispose());
    });
  }
  modeloActual = null;
}

// Coloca la cámara para que el modelo completo quepa en el cuadro y ajusta la sombra
function encuadrar(objeto) {
  const caja = new THREE.Box3().setFromObject(objeto);
  const esfera = caja.getBoundingSphere(new THREE.Sphere());
  const tam = caja.getSize(new THREE.Vector3());
  const fovV = THREE.MathUtils.degToRad(camara.fov);
  const fovH = 2 * Math.atan(Math.tan(fovV / 2) * camara.aspect);
  const distancia = (esfera.radius / Math.sin(Math.min(fovV, fovH) / 2)) * 0.9;
  const direccion = new THREE.Vector3(
    Math.cos(ANGULO_ALTURA) * Math.sin(ANGULO_LADO),
    Math.sin(ANGULO_ALTURA),
    Math.cos(ANGULO_ALTURA) * Math.cos(ANGULO_LADO)
  );
  controles.target.copy(esfera.center);
  camara.position.copy(esfera.center).addScaledVector(direccion, distancia);
  camara.near = distancia / 50;
  camara.far = distancia * 10;
  camara.updateProjectionMatrix();
  controles.minDistance = distancia * 0.45;
  controles.maxDistance = distancia * 2.2;
  controles.update();
  controles.saveState();
  sombra.scale.set(tam.x * 1.35, tam.z * 1.6, 1);
  sombra.position.set(0, 0.002, 0);
}

// ===== MODELOS GENÉRICOS DE RESPALDO =====

// Materiales del modelo genérico: pintura con el color de la BD + llanta, rin, vidrio, faros, metal…
function crearMateriales(color, producto) {
  const nombreColor = String(producto.color || "").toLowerCase();
  const mate = nombreColor.includes("mate");
  const metalico = /acero|aluminio|plata|dorado|gris|metal/.test(nombreColor);
  return {
    pintura: new THREE.MeshPhysicalMaterial({ color, metalness: mate ? 0.1 : 0.5, roughness: mate ? 0.62 : 0.3, clearcoat: mate ? 0 : 1, clearcoatRoughness: 0.08 }),
    acabado: new THREE.MeshStandardMaterial({ color, metalness: metalico ? 0.9 : 0.15, roughness: metalico ? 0.3 : 0.55 }),
    vidrio: new THREE.MeshPhysicalMaterial({ color: 0x0d1016, metalness: 0.1, roughness: 0.05, clearcoat: 1, transparent: true, opacity: 0.9 }),
    llanta: new THREE.MeshStandardMaterial({ color: 0x111113, roughness: 0.85 }),
    rin: new THREE.MeshStandardMaterial({ color: 0x3a3d42, metalness: 0.9, roughness: 0.35 }),
    cromo: new THREE.MeshStandardMaterial({ color: 0xd4d7dc, metalness: 1, roughness: 0.18 }),
    oscuro: new THREE.MeshStandardMaterial({ color: 0x1b1c1f, metalness: 0.3, roughness: 0.6 }),
    metal: new THREE.MeshStandardMaterial({ color: 0x9da1a7, metalness: 1, roughness: 0.3 }),
    ceramica: new THREE.MeshPhysicalMaterial({ color: 0xf4f2ec, roughness: 0.25, clearcoat: 0.6 }),
    rojo: new THREE.MeshStandardMaterial({ color: 0xb3122e, roughness: 0.45 }),
    espejo: new THREE.MeshStandardMaterial({ color: 0xdfe6ee, metalness: 1, roughness: 0.03 }),
    faro: new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0xf4f7ff, emissiveIntensity: 1.4 }),
    calavera: new THREE.MeshStandardMaterial({ color: 0x5a0610, emissive: 0xd0142c, emissiveIntensity: 1.2 })
  };
}

// Decide qué modelo genérico armar según el tipo de producto (auto, moto o refacción)
function crearModeloGenerico(producto, color) {
  const m = crearMateriales(color, producto);
  if (producto.tipo === "moto") return crearMoto(m);
  if (producto.tipo === "refaccion") return crearRefaccion(producto.nombre, m);
  return crearAuto(perfilDeModelo(producto.modelo), m);
}

// Elige la carrocería según el modelo: SUV (Q3–Q8, Cayenne, Macan), deportivo (911, 718, R8) o sedán
function perfilDeModelo(modelo) {
  const texto = String(modelo || "").toLowerCase();
  if (/^q\d|cayenne|macan/.test(texto)) return PERFILES_AUTO.suv;
  if (/911|718|cayman|boxster|r8|gt3|targa/.test(texto)) return PERFILES_AUTO.deportivo;
  return PERFILES_AUTO.sedan;
}

// Extruye una silueta 2D con bordes redondeados y la centra en el eje Z
function extruir(forma, profundidad, bisel = 0) {
  const fondo = Math.max(profundidad - bisel * 2, 0.001);
  const geometria = new THREE.ExtrudeGeometry(forma, {
    depth: fondo, bevelEnabled: bisel > 0, bevelThickness: bisel, bevelSize: bisel * 0.8, bevelSegments: 4, curveSegments: 32
  });
  geometria.translate(0, 0, -fondo / 2);
  return geometria;
}

// Crea una malla y la coloca en (x, y, z)
function pieza(geometria, material, x = 0, y = 0, z = 0) {
  const malla = new THREE.Mesh(geometria, material);
  malla.position.set(x, y, z);
  return malla;
}

// Silueta lateral de la carrocería (con los huecos de las ruedas)
function siluetaCarroceria(p) {
  const s = new THREE.Shape();
  const xf = p.largo / 2;
  const xr = -p.largo / 2;
  const y0 = p.piso;
  const R = p.rueda + 0.05;
  s.moveTo(xr + 0.15, y0);
  s.lineTo(p.ejeTras - R, y0);
  s.absarc(p.ejeTras, p.rueda, R, Math.PI, 0, true);
  s.lineTo(p.ejeTras + R, y0);
  s.lineTo(p.ejeDel - R, y0);
  s.absarc(p.ejeDel, p.rueda, R, Math.PI, 0, true);
  s.lineTo(p.ejeDel + R, y0);
  s.lineTo(xf - 0.2, y0);
  s.quadraticCurveTo(xf, y0, xf, y0 + 0.18);
  s.quadraticCurveTo(xf, p.nariz, xf - 0.3, p.nariz + 0.04);
  s.quadraticCurveTo(p.cabDel + 0.75, p.cintura + 0.02, p.cabDel, p.cintura);
  s.lineTo(p.cabTras + 0.3, p.cintura);
  s.quadraticCurveTo(xr + 0.1, p.cola + 0.02, xr, p.cola - 0.1);
  s.lineTo(xr, y0 + 0.15);
  s.quadraticCurveTo(xr, y0, xr + 0.15, y0);
  return s;
}

// Silueta lateral de la cabina (parabrisas, techo y medallón)
function siluetaCabina(p) {
  const c = new THREE.Shape();
  const base = p.cintura - 0.03;
  c.moveTo(p.cabDel, base);
  c.lineTo(p.techoDel + 0.12, p.techo - 0.04);
  c.quadraticCurveTo(p.techoDel, p.techo, p.techoDel - 0.18, p.techo);
  c.lineTo(p.techoTras + 0.18, p.techo);
  c.quadraticCurveTo(p.techoTras, p.techo, p.techoTras - 0.1, p.techo - 0.06);
  c.lineTo(p.cabTras, base);
  c.lineTo(p.cabDel, base);
  return c;
}

// Rueda completa: llanta, rin oscuro, rayos cromados y centro (lado = +1 derecha / -1 izquierda)
function crearRueda(radio, m, lado) {
  const rueda = new THREE.Group();
  const llanta = pieza(new THREE.TorusGeometry(radio - 0.085, 0.085, 16, 48), m.llanta);
  llanta.scale.z = 1.35;
  const rin = pieza(new THREE.CylinderGeometry(radio - 0.1, radio - 0.1, 0.2, 36), m.rin);
  rin.rotation.x = Math.PI / 2;
  const borde = pieza(new THREE.TorusGeometry(radio - 0.1, 0.016, 8, 48), m.cromo, 0, 0, lado * 0.1);
  rueda.add(llanta, rin, borde);
  for (let i = 0; i < 5; i++) {
    const rayo = pieza(new THREE.BoxGeometry((radio - 0.1) * 2, 0.05, 0.03), m.cromo, 0, 0, lado * 0.105);
    rayo.rotation.z = (i / 5) * Math.PI;
    rueda.add(rayo);
  }
  const centro = pieza(new THREE.CylinderGeometry(0.06, 0.06, 0.23, 16), m.oscuro);
  centro.rotation.x = Math.PI / 2;
  rueda.add(centro);
  return rueda;
}

// Auto genérico: carrocería con el color de la BD, cabina de vidrio, techo, ruedas, faros y calaveras
function crearAuto(p, m) {
  const auto = new THREE.Group();
  const xf = p.largo / 2;
  const xr = -p.largo / 2;
  const anchoCabina = p.ancho * 0.78;

  // Carrocería y cabina
  auto.add(pieza(extruir(siluetaCarroceria(p), p.ancho, 0.09), m.pintura));
  auto.add(pieza(extruir(siluetaCabina(p), anchoCabina, 0.05), m.vidrio));
  // Techo del color de la carrocería
  const largoTecho = p.techoDel - p.techoTras;
  auto.add(pieza(new RoundedBoxGeometry(largoTecho, 0.05, anchoCabina + 0.04, 2, 0.02), m.pintura, (p.techoDel + p.techoTras) / 2, p.techo + 0.02, 0));

  // Ruedas en los 4 lados
  [p.ejeDel, p.ejeTras].forEach(x => [1, -1].forEach(lado => {
    const rueda = crearRueda(p.rueda, m, lado);
    rueda.position.set(x, p.rueda, lado * (p.ancho / 2 - 0.2));
    auto.add(rueda);
  }));

  // Faros delanteros, parrilla y barra de calaveras
  [1, -1].forEach(lado => {
    const faro = pieza(new THREE.SphereGeometry(0.11, 20, 12), m.faro, xf + 0.02, p.nariz - 0.06, lado * (p.ancho / 2 - 0.34));
    faro.scale.set(0.7, 0.45, 1.5);
    auto.add(faro);
    auto.add(pieza(new RoundedBoxGeometry(0.16, 0.08, 0.14, 2, 0.03), m.pintura, p.cabDel - 0.12, p.cintura + 0.07, lado * (p.ancho / 2 + 0.03)));
  });
  auto.add(pieza(new RoundedBoxGeometry(0.06, 0.16, p.ancho * 0.42, 2, 0.02), m.oscuro, xf + 0.07, p.piso + 0.2, 0));
  auto.add(pieza(new RoundedBoxGeometry(0.05, 0.05, p.ancho * 0.84, 2, 0.02), m.calavera, xr - 0.1, p.cola - 0.16, 0));
  return auto;
}

// Motocicleta genérica: tanque, carenado y colín con el color de la BD
function crearMoto(m) {
  const moto = new THREE.Group();
  const radio = 0.33;

  // Ruedas con rin de 3 rayos y disco de freno
  [0.72, -0.72].forEach(x => {
    const llanta = pieza(new THREE.TorusGeometry(radio - 0.06, 0.06, 14, 48), m.llanta, x, radio, 0);
    llanta.scale.z = 1.3;
    const rin = pieza(new THREE.TorusGeometry(radio - 0.075, 0.018, 8, 40), m.rin, x, radio, 0);
    const maza = pieza(new THREE.CylinderGeometry(0.05, 0.05, 0.12, 16), m.rin, x, radio, 0);
    maza.rotation.x = Math.PI / 2;
    moto.add(llanta, rin, maza);
    for (let i = 0; i < 3; i++) {
      const rayo = pieza(new THREE.BoxGeometry(radio - 0.08, 0.03, 0.025), m.rin, x, radio, 0);
      rayo.geometry.translate((radio - 0.08) / 2, 0, 0);
      rayo.rotation.z = (i / 3) * Math.PI * 2;
      moto.add(rayo);
    }
    const disco = pieza(new THREE.CylinderGeometry(0.16, 0.16, 0.012, 32), m.metal, x, radio, 0.07);
    disco.rotation.x = Math.PI / 2;
    moto.add(disco);
  });

  // Chasis: tubos del cabezal de dirección al pivote del basculante
  [0.09, -0.09].forEach(z => {
    const tubo = pieza(new THREE.CylinderGeometry(0.022, 0.022, 0.8, 10), m.oscuro, 0.22, 0.78, z);
    tubo.rotation.z = Math.atan2(0.64, 0.46) + Math.PI / 2;
    moto.add(tubo);
  });

  // Motor, tanque, carenado frontal, parabrisas, asiento y colín
  moto.add(pieza(new RoundedBoxGeometry(0.46, 0.36, 0.28, 3, 0.05), m.rin, 0.0, 0.56, 0));
  const tanque = pieza(new THREE.SphereGeometry(0.25, 32, 20), m.pintura, 0.1, 0.99, 0);
  tanque.scale.set(1.3, 0.62, 0.72);
  const carenado = pieza(new THREE.SphereGeometry(0.25, 32, 20), m.pintura, 0.52, 0.88, 0);
  carenado.scale.set(1.3, 0.62, 0.52);
  carenado.rotation.z = -0.35;
  const parabrisas = pieza(new THREE.SphereGeometry(0.2, 20, 12), m.vidrio, 0.52, 1.07, 0);
  parabrisas.scale.set(0.55, 0.28, 0.42);
  parabrisas.rotation.z = -0.5;
  const asiento = pieza(new RoundedBoxGeometry(0.46, 0.07, 0.24, 2, 0.03), m.oscuro, -0.34, 0.99, 0);
  const colin = pieza(new THREE.ConeGeometry(0.12, 0.5, 24), m.pintura, -0.66, 1.03, 0);
  colin.rotation.z = Math.PI / 2 - 0.15;
  moto.add(tanque, carenado, parabrisas, asiento, colin);

  // Horquilla delantera, manubrio y basculante
  [0.1, -0.1].forEach(z => {
    const barra = pieza(new THREE.CylinderGeometry(0.025, 0.025, 0.71, 12), m.cromo, 0.64, 0.675, z);
    barra.rotation.z = Math.asin(0.16 / 0.71);
    moto.add(barra);
  });
  const manubrio = pieza(new THREE.CylinderGeometry(0.02, 0.02, 0.62, 12), m.oscuro, 0.5, 1.08, 0);
  manubrio.rotation.x = Math.PI / 2;
  const basculante = pieza(new THREE.BoxGeometry(0.74, 0.06, 0.05), m.oscuro, -0.36, 0.39, 0.12);
  basculante.rotation.z = Math.atan(0.12 / 0.72);
  moto.add(manubrio, basculante);

  // Escape, faro y calavera
  const escape = pieza(new THREE.CylinderGeometry(0.05, 0.06, 0.45, 16), m.cromo, -0.38, 0.5, 0.17);
  escape.rotation.z = Math.PI / 2 - 0.2;
  moto.add(escape);
  const faro = pieza(new THREE.SphereGeometry(0.06, 16, 10), m.faro, 0.83, 0.84, 0);
  faro.scale.set(0.6, 0.8, 1.4);
  moto.add(faro);
  moto.add(pieza(new RoundedBoxGeometry(0.04, 0.04, 0.12, 2, 0.015), m.calavera, -0.9, 1.1, 0));
  return moto;
}

// Elige la refacción genérica según su nombre (disco, pastillas, filtro, batería, bujías…)
function crearRefaccion(nombre, m) {
  const texto = String(nombre || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
  if (texto.includes("disco")) return crearDisco(m);
  if (texto.includes("pastilla") || texto.includes("balata")) return crearPastillas(m);
  if (texto.includes("filtro de aceite")) return crearFiltroAceite(m);
  if (texto.includes("filtro de aire")) return crearFiltroAire(m);
  if (texto.includes("bateria")) return crearBateria(m);
  if (texto.includes("bujia")) return crearBujias(m);
  if (texto.includes("distribucion")) return crearKitDistribucion(m);
  if (texto.includes("cadena")) return crearCadena(m);
  if (texto.includes("bomba")) return crearBombaAgua(m);
  if (texto.includes("maneta")) return crearManeta(m);
  if (texto.includes("espejo")) return crearEspejo(m);
  return crearEngrane(m);
}

// Círculo como camino (para huecos de las siluetas)
function circulo(x, y, r) {
  const c = new THREE.Path();
  c.absarc(x, y, r, 0, Math.PI * 2, true);
  return c;
}

// Disco de freno perforado con campana central
function crearDisco(m) {
  const g = new THREE.Group();
  const forma = new THREE.Shape();
  forma.absarc(0, 0, 1, 0, Math.PI * 2, false);
  forma.holes.push(circulo(0, 0, 0.42));
  for (let anillo = 0; anillo < 3; anillo++) {
    for (let i = 0; i < 12; i++) {
      const r = 0.6 + anillo * 0.12;
      const a = (i / 12) * Math.PI * 2 + anillo * 0.26;
      forma.holes.push(circulo(Math.cos(a) * r, Math.sin(a) * r, 0.035));
    }
  }
  g.add(pieza(extruir(forma, 0.14, 0.012), m.acabado));
  const campana = pieza(new THREE.CylinderGeometry(0.46, 0.46, 0.3, 48), m.metal, 0, 0, 0.15);
  campana.rotation.x = Math.PI / 2;
  const centro = pieza(new THREE.CylinderGeometry(0.16, 0.16, 0.32, 24), m.oscuro, 0, 0, 0.16);
  centro.rotation.x = Math.PI / 2;
  g.add(campana, centro);
  for (let i = 0; i < 5; i++) {
    const a = (i / 5) * Math.PI * 2;
    const birlo = pieza(new THREE.CylinderGeometry(0.04, 0.04, 0.32, 12), m.oscuro, Math.cos(a) * 0.3, Math.sin(a) * 0.3, 0.16);
    birlo.rotation.x = Math.PI / 2;
    g.add(birlo);
  }
  return g;
}

// Silueta de arco (forma de las pastillas de freno)
function arcoPastilla(rIn, rOut, apertura) {
  const forma = new THREE.Shape();
  const a0 = Math.PI / 2 - apertura;
  const a1 = Math.PI / 2 + apertura;
  forma.absarc(0, 0, rOut, a0, a1, false);
  forma.absarc(0, 0, rIn, a1, a0, true);
  return forma;
}

// Par de pastillas de freno: placa metálica + material de fricción con el color de la BD
function crearPastillas(m) {
  const g = new THREE.Group();
  [1, -1].forEach(lado => {
    g.add(pieza(extruir(arcoPastilla(0.75, 1.15, 0.45), 0.07, 0.01), m.metal, 0, 0, lado * 0.3));
    g.add(pieza(extruir(arcoPastilla(0.79, 1.11, 0.4), 0.14, 0.01), m.acabado, 0, 0, lado * 0.19));
  });
  return g;
}

// Filtro de aceite: cartucho con el color de la BD y base metálica
function crearFiltroAceite(m) {
  const g = new THREE.Group();
  const perfil = [[0, 0.02], [0.4, 0.02], [0.45, 0.06], [0.45, 0.86], [0.42, 0.93], [0.3, 0.97], [0, 0.97]].map(([x, y]) => new THREE.Vector2(x, y));
  g.add(pieza(new THREE.LatheGeometry(perfil, 48), m.acabado));
  g.add(pieza(new THREE.CylinderGeometry(0.43, 0.43, 0.05, 48), m.metal, 0, 0.02, 0));
  [0.12, 0.8].forEach(y => {
    const aro = pieza(new THREE.TorusGeometry(0.452, 0.012, 8, 48), m.metal, 0, y, 0);
    aro.rotation.x = Math.PI / 2;
    g.add(aro);
  });
  return g;
}

// Filtro de aire: marco de hule y pliegues en zigzag con el color de la BD
function crearFiltroAire(m) {
  const g = new THREE.Group();
  const zigzag = new THREE.Shape();
  zigzag.moveTo(-0.75, 0);
  for (let i = 0; i <= 24; i++) zigzag.lineTo(-0.75 + i * (1.5 / 24), i % 2 ? 0.12 : 0.02);
  zigzag.lineTo(0.75, 0);
  zigzag.lineTo(-0.75, 0);
  g.add(pieza(extruir(zigzag, 0.9), m.acabado));
  g.add(pieza(new RoundedBoxGeometry(1.66, 0.09, 0.06, 2, 0.02), m.oscuro, 0, 0.045, 0.48));
  g.add(pieza(new RoundedBoxGeometry(1.66, 0.09, 0.06, 2, 0.02), m.oscuro, 0, 0.045, -0.48));
  g.add(pieza(new RoundedBoxGeometry(0.06, 0.09, 1.02, 2, 0.02), m.oscuro, 0.8, 0.045, 0));
  g.add(pieza(new RoundedBoxGeometry(0.06, 0.09, 1.02, 2, 0.02), m.oscuro, -0.8, 0.045, 0));
  return g;
}

// Batería: caja con el color de la BD, tapa y dos bornes (+ rojo, − negro)
function crearBateria(m) {
  const g = new THREE.Group();
  g.add(pieza(new RoundedBoxGeometry(1.2, 0.75, 0.7, 4, 0.04), m.acabado, 0, 0.375, 0));
  g.add(pieza(new RoundedBoxGeometry(1.22, 0.08, 0.72, 2, 0.03), m.oscuro, 0, 0.77, 0));
  g.add(pieza(new THREE.CylinderGeometry(0.07, 0.07, 0.1, 20), m.rojo, 0.42, 0.85, 0.18));
  g.add(pieza(new THREE.CylinderGeometry(0.07, 0.07, 0.1, 20), m.oscuro, -0.42, 0.85, 0.18));
  return g;
}

// Juego de 4 bujías: porcelana blanca, hexágono con el color de la BD y cuerda metálica
function crearBujias(m) {
  const g = new THREE.Group();
  const perfilCeramica = [[0, 0], [0.07, 0], [0.075, 0.05], [0.06, 0.1], [0.055, 0.45], [0.035, 0.5], [0, 0.5]].map(([x, y]) => new THREE.Vector2(x, y));
  for (let i = 0; i < 4; i++) {
    const x = (i - 1.5) * 0.35;
    g.add(pieza(new THREE.CylinderGeometry(0.012, 0.012, 0.08, 8), m.metal, x, 0.02, 0));
    g.add(pieza(new THREE.CylinderGeometry(0.07, 0.07, 0.25, 20), m.metal, x, 0.19, 0));
    g.add(pieza(new THREE.CylinderGeometry(0.1, 0.1, 0.12, 6), m.acabado, x, 0.37, 0));
    g.add(pieza(new THREE.LatheGeometry(perfilCeramica, 24), m.ceramica, x, 0.43, 0));
    g.add(pieza(new THREE.CylinderGeometry(0.03, 0.03, 0.08, 12), m.metal, x, 0.96, 0));
  }
  return g;
}

// Contorno de cápsula (dos semicírculos unidos), usado por la banda y la cadena
function capsula(radio, separacion, huecoRadio) {
  const forma = new THREE.Shape();
  forma.absarc(separacion, 0, radio, -Math.PI / 2, Math.PI / 2, false);
  forma.absarc(-separacion, 0, radio, Math.PI / 2, Math.PI * 1.5, false);
  if (huecoRadio) {
    const hueco = new THREE.Path();
    hueco.absarc(separacion, 0, huecoRadio, -Math.PI / 2, Math.PI / 2, false);
    hueco.absarc(-separacion, 0, huecoRadio, Math.PI / 2, Math.PI * 1.5, false);
    forma.holes.push(hueco);
  }
  return forma;
}

// Kit de distribución: banda con el color de la BD, dos poleas y un tensor
function crearKitDistribucion(m) {
  const g = new THREE.Group();
  g.add(pieza(extruir(capsula(0.55, 0.7, 0.47), 0.3), m.acabado));
  [0.7, -0.7].forEach(x => {
    const polea = pieza(new THREE.CylinderGeometry(0.46, 0.46, 0.34, 40), m.metal, x, 0, 0);
    polea.rotation.x = Math.PI / 2;
    const maza = pieza(new THREE.CylinderGeometry(0.12, 0.12, 0.38, 20), m.oscuro, x, 0, 0);
    maza.rotation.x = Math.PI / 2;
    g.add(polea, maza);
  });
  const tensor = pieza(new THREE.CylinderGeometry(0.17, 0.17, 0.3, 28), m.metal, 0, 0.72, 0);
  tensor.rotation.x = Math.PI / 2;
  g.add(tensor);
  return g;
}

// Silueta de engrane (dientes alrededor y hueco central)
function formaEngrane(dientes, rExt, rInt, rHueco) {
  const forma = new THREE.Shape();
  const paso = (Math.PI * 2) / dientes;
  for (let i = 0; i < dientes; i++) {
    const a = i * paso;
    const puntos = [[rInt, a], [rExt, a + paso * 0.2], [rExt, a + paso * 0.5], [rInt, a + paso * 0.7]];
    puntos.forEach(([r, ang], j) => {
      const x = Math.cos(ang) * r;
      const y = Math.sin(ang) * r;
      if (i === 0 && j === 0) forma.moveTo(x, y); else forma.lineTo(x, y);
    });
  }
  forma.closePath();
  if (rHueco) forma.holes.push(circulo(0, 0, rHueco));
  return forma;
}

// Cadena de transmisión: eslabones con el color de la BD alrededor de dos catarinas
function crearCadena(m) {
  const g = new THREE.Group();
  const radio = 0.5;
  const separacion = 0.8;
  const recta = separacion * 2;
  const perimetro = recta * 2 + Math.PI * 2 * radio;
  const total = 52;
  for (let i = 0; i < total; i++) {
    let d = (i / total) * perimetro;
    let x, y, angulo;
    if (d < recta) { x = -separacion + d; y = radio; angulo = 0; }
    else if ((d -= recta) < Math.PI * radio) { const a = Math.PI / 2 - d / radio; x = separacion + Math.cos(a) * radio; y = Math.sin(a) * radio; angulo = a - Math.PI / 2; }
    else if ((d -= Math.PI * radio) < recta) { x = separacion - d; y = -radio; angulo = Math.PI; }
    else { d -= recta; const a = -Math.PI / 2 - d / radio; x = -separacion + Math.cos(a) * radio; y = Math.sin(a) * radio; angulo = a - Math.PI / 2; }
    const eslabon = pieza(new RoundedBoxGeometry(0.1, 0.05, 0.12, 2, 0.015), m.acabado, x, y, 0);
    eslabon.rotation.z = angulo;
    g.add(eslabon);
  }
  [separacion, -separacion].forEach(x => g.add(pieza(extruir(formaEngrane(18, 0.47, 0.42, 0.12), 0.06), m.oscuro, x, 0, 0)));
  return g;
}

// Bomba de agua: carcasa con el color de la BD, polea con ranuras y orejas de montaje
function crearBombaAgua(m) {
  const g = new THREE.Group();
  const perfil = [[0, 0], [0.5, 0], [0.52, 0.08], [0.45, 0.2], [0.25, 0.3], [0.2, 0.6], [0, 0.6]].map(([x, y]) => new THREE.Vector2(x, y));
  g.add(pieza(new THREE.LatheGeometry(perfil, 48), m.acabado));
  g.add(pieza(new THREE.CylinderGeometry(0.42, 0.42, 0.18, 40), m.metal, 0, 0.72, 0));
  [0.67, 0.72, 0.77].forEach(y => {
    const ranura = pieza(new THREE.TorusGeometry(0.42, 0.012, 8, 48), m.oscuro, 0, y, 0);
    ranura.rotation.x = Math.PI / 2;
    g.add(ranura);
  });
  for (let i = 0; i < 3; i++) {
    const a = (i / 3) * Math.PI * 2;
    g.add(pieza(new THREE.CylinderGeometry(0.09, 0.09, 0.06, 20), m.acabado, Math.cos(a) * 0.58, 0.03, Math.sin(a) * 0.58));
  }
  return g;
}

// Maneta de freno/embrague: palanca curva con el color de la BD y su pivote
function crearManeta(m) {
  const g = new THREE.Group();
  const curva = new THREE.CatmullRomCurve3([new THREE.Vector3(0, 0, 0), new THREE.Vector3(0.4, 0.02, 0), new THREE.Vector3(0.9, 0.08, 0), new THREE.Vector3(1.4, 0.2, 0)]);
  const palanca = pieza(new THREE.TubeGeometry(curva, 40, 0.04, 12, false), m.acabado);
  palanca.scale.z = 0.6;
  g.add(palanca);
  g.add(pieza(new THREE.SphereGeometry(0.05, 16, 10), m.acabado, 1.4, 0.2, 0));
  g.add(pieza(new THREE.CylinderGeometry(0.11, 0.11, 0.12, 24), m.metal, 0, 0, 0));
  g.add(pieza(new THREE.CylinderGeometry(0.05, 0.05, 0.16, 16), m.oscuro, 0.05, 0.08, 0));
  return g;
}

// Espejo retrovisor: carcasa con el color de la BD, luna reflejante y brazo
function crearEspejo(m) {
  const g = new THREE.Group();
  const carcasa = pieza(new THREE.SphereGeometry(0.5, 32, 20), m.acabado, 0, 0.9, 0);
  carcasa.scale.set(1, 0.55, 0.22);
  const luna = pieza(new THREE.CircleGeometry(0.46, 40), m.espejo, 0, 0.9, 0.112);
  luna.scale.set(1, 0.55, 1);
  const brazo = pieza(new THREE.CylinderGeometry(0.035, 0.045, 0.62, 16), m.oscuro, 0.05, 0.38, -0.02);
  brazo.rotation.z = -0.16;
  const base = pieza(new RoundedBoxGeometry(0.25, 0.06, 0.18, 2, 0.02), m.oscuro, 0.1, 0.03, -0.02);
  g.add(carcasa, luna, brazo, base);
  return g;
}

// Engrane genérico para cualquier refacción no reconocida
function crearEngrane(m) {
  const g = new THREE.Group();
  g.add(pieza(extruir(formaEngrane(20, 1, 0.86, 0.3), 0.25, 0.02), m.acabado));
  const eje = pieza(new THREE.CylinderGeometry(0.3, 0.3, 0.3, 32), m.metal);
  eje.rotation.x = Math.PI / 2;
  g.add(eje);
  return g;
}

// ===== PUBLICACIÓN =====

// Deja la función disponible para script.js y avisa que la librería 3D ya cargó
window.KarmaVista3D = Object.freeze({ mostrar });
window.dispatchEvent(new Event("karma:vista3d-lista"));

// === CREDITOS DE MODELOS 3D ===
/* 
Porsche 911 (negro):
"2022 Porsche 911 GT3 Touring (992)" (https://skfb.ly/prLB9) by Ddiaz Design is licensed under CC Attribution-NonCommercial-ShareAlike (http://creativecommons.org/licenses/by-nc-sa/4.0/).

Audi R8 (azul):
"2019 Audi R8 V10 Performance Quattro" (https://skfb.ly/p8xAZ) by Ddiaz Design is licensed under CC Attribution-NonCommercial-ShareAlike (http://creativecommons.org/licenses/by-nc-sa/4.0/).

Ducati Panigale (Gris):
"2021 Ducati Panigale V4 SP" (https://skfb.ly/pKzVq) by Carlito is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).

Balata delantera para Audi:
"Balata_3af92511c849988dda3f" (https://skfb.ly/oCM6H) by anaelsa2007mx is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).
*/