/* ==========================================================================
   PROTECCIÓN DE ACCESO: Gerente o Administrador con sesión y sucursal asignada
   ========================================================================== */
const ROLES_PANEL_GERENTE = ["Gerente", "Administrador General", "Admin_General"];
let avisoAccesoMostrado = false;

function verificarAcceso(){
  let usuario = null;
  try { usuario = JSON.parse(localStorage.getItem("karma_user") || "null"); } catch (e) {}

  // Sin sesión: al login
  if (!usuario){
    window.location.replace("../index.html");
    return false;
  }
  // Contraseña temporal del administrador: primero hay que cambiarla
  if (usuario.debe_cambiar_password){
    window.location.replace("../PHP/Login/cambiar_password.php?forzado=1");
    return false;
  }
  // Con sesión, pero sin permiso o sin sucursal: avisa y regresa al Home
  if (!ROLES_PANEL_GERENTE.includes(usuario.rol) || !usuario.id_sucursal){
    if (!avisoAccesoMostrado) {
      avisoAccesoMostrado = true;
      alert(ROLES_PANEL_GERENTE.includes(usuario.rol)
        ? "Tu sesión no tiene sucursal asignada. Si ya tienes una, cierra sesión y vuelve a entrar."
        : "Tu rol no puede abrir el panel de gerente.");
    }
    window.location.replace("home.html");
    return false;
  }
  return true;
}

// También al llegar con el botón "Atrás" (el navegador puede mostrar la página guardada en caché)
window.addEventListener("pageshow", (e) => {
  if (!verificarAcceso()) return;
  // Si el navegador restauró la página desde la caché (botón Atrás), recárgala para leer el tema e idioma actuales
  if (e.persisted) window.location.reload();
});

// Si el tema o el idioma cambian en otra pestaña (por ejemplo el Home), recarga para reflejarlo
window.addEventListener("storage", (e) => {
  if (e.key === "karma_tema" || e.key === "karma_idioma") window.location.reload();
});

const $  = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));

function formatoMoneda(n){
  return new Intl.NumberFormat("es-MX", { style:"currency", currency:"MXN", maximumFractionDigits:0 }).format(n || 0);
}
function formatoNumero(n){
  return new Intl.NumberFormat("es-MX").format(n || 0);
}
function escapeHTML(str){
  return String(str ?? "").replace(/[&<>"']/g, s => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[s]));
}
function delay(ms){ return new Promise(res => setTimeout(res, ms)); }
function uid(prefix){ return prefix + "_" + Math.random().toString(36).slice(2, 9); }
function iniciales(nombre){
  return (nombre || "").split(" ").filter(Boolean).slice(0,2).map(p => p[0].toUpperCase()).join("");
}
function formatFecha(iso){
  if (!iso) return "—";
  const d = new Date(iso);
  return d.toLocaleDateString(state.lang === "es" ? "es-MX" : "en-US", { day:"2-digit", month:"short", year:"numeric" });
}
function formatHora(iso){
  if (!iso) return "—";
  const d = new Date(iso);
  return d.toLocaleTimeString(state.lang === "es" ? "es-MX" : "en-US", { hour:"2-digit", minute:"2-digit" });
}
// Lee una variable CSS del tema actual (los gráficos no entienden var(--x))
function cssVar(nombre, respaldo){
  const valor = getComputedStyle(document.body).getPropertyValue(nombre).trim();
  return valor || respaldo;
}
// Traduce el tipo de producto (vehiculo / moto / refaccion)
function etiquetaTipo(tipo){
  const claves = { vehiculo:"tipoVehiculo", moto:"tipoMoto", refaccion:"tipoRefaccion" };
  return claves[tipo] ? t(claves[tipo]) : tipo;
}
/*I18N — diccionario bilingüe ES / EN */
const I18N = {
  es:{
    topHome:"Ir al Inicio", brandSlogan:"Panel de Gerencia",
    logout:"Cerrar sesión", changePassword:"Cambiar contraseña", role:"Rol", roleGerente:"Gerente de Sede",
    navDashboard:"Dashboard", navProductos:"Productos", navInventario:"Inventario",
    navCajas:"Cajas", navVentas:"Ventas",
    syncOk:"Datos en vivo", syncOff:"Sin conexión a BD",
    date:"Fecha", time:"Hora", manager:"Gerente", branch:"Sucursal", session:"Sesión", active:"Activa",

    /* Dashboard */
    dashEyebrow:"Sede", dashTitle:"Dashboard de Gerencia",
    kpiVentas:"Ventas del mes", kpiProductos:"Productos en catálogo",
    kpiBajoStock:"Alertas de stock", kpiCajas:"Cajas activas",
    vsLastMonth:"vs. mes anterior", unitsInCatalog:"artículos en catálogo",
    alertsThisBranch:"alertas en esta sede",
    chartVentasTitulo:"Ventas mensuales de la sede", chartVentasSub:"Ingresos y unidades vendidas",
    revenue:"Ingresos", units:"Unidades",
    chartStockTitulo:"Distribución de inventario", chartStockSub:"Existencias por categoría",
    stockCriticoTitulo:"Productos con stock crítico", stockCriticoSub:"Existencias en o por debajo del mínimo",
    stockEmpty:"Sin alertas de stock crítico en este momento.",
    quickTitle:"Accesos rápidos",
    qaProducto:"Nuevo producto", qaProductoSub:"Registrar en catálogo",
    qaStock:"Actualizar stock", qaStockSub:"Ajustar existencias",
    qaCaja:"Nueva caja", qaCajaSub:"Registrar punto de cobro",
    qaVentas:"Ver ventas", qaVentasSub:"Historial de ventas",
    sucursalInfoTitle:"Información de la sucursal",

    /* Productos */
    productosTitle:"Catálogo de productos", productosSub:"Vehículos y refacciones registrados en esta sucursal",
    newProducto:"Nuevo producto", filterAll:"Todos",
    filterVehiculos:"Vehículos", filterRefacciones:"Refacciones", filterMotos:"Motocicletas",
    searchPlaceholder:"Buscar producto, marca…",
    colProducto:"Producto", colMarca:"Marca", colCategoria:"Categoría",
    colPrecio:"Precio", colStock:"Stock", colAcciones:"Acciones",
    edit:"Editar", delete:"Eliminar",
    formProductoNewTitle:"Registrar producto", formProductoEditTitle:"Editar producto",
    formProductoDesc:"Completa los datos del producto. El stock inicial se reflejará en inventario.",
    fTipo:"Tipo", tipoVehiculo:"Vehículo", tipoRefaccion:"Refacción", tipoMoto:"Motocicleta",
    fMarca:"Marca", fModelo:"Modelo / nombre del producto", fCategoria:"Categoría",
    fPrecio:"Precio de venta (MXN)", fStockInicial:"Stock inicial", fStockMin:"Stock mínimo",
    fDescripcion:"Descripción (opcional)",
    save:"Guardar", cancel:"Cancelar", saveChanges:"Guardar cambios",
    toastProductoCreated:"Producto registrado correctamente",
    toastProductoUpdated:"Producto actualizado",
    toastProductoDeleted:"Producto eliminado",
    confirmDelete:"¿Eliminar este producto? Esta acción no se puede deshacer.",

    /* Inventario */
    inventarioTitle:"Control de inventario", inventarioSub:"Existencias de tu sucursal con filtros por categoría y alertas de stock bajo",
    filterLow:"Bajo stock", filterCritical:"Crítico",
    colStockActual:"Stock actual", colStockMinimo:"Stock mínimo",
    adjustStock:"Ajustar stock",
    modalStockTitle:"Ajustar existencias",
    modalStockDesc:"Modifica la cantidad actual del producto en inventario.",
    stockCurrentLabel:"Stock actual", newStockLabel:"Nuevo valor",
    motivo:"Motivo del ajuste", motivoEntrada:"Entrada de mercancía",
    motivoSalida:"Corrección / salida", motivoInventario:"Toma de inventario", motivoOtro:"Otro",
    toastStockUpdated:"Existencias actualizadas correctamente",
    hintDB:"Existencias en vivo de tu sucursal.",
    critical:"Crítico", low:"Bajo", ok:"Suficiente",

    /* Cajas */
    cajasTitle:"Gestión de cajas", cajasSub:"Puntos de cobro activos e inactivos de tu sucursal",
    newCaja:"Nueva caja", colCaja:"Caja", colCajero:"Cajero asignado", colEstado:"Estado",
    formCajaNewTitle:"Registrar caja", formCajaDesc:"Asigna un nombre y cajero a la nueva caja.",
    fNombreCaja:"Número de caja", fCajeroAsignado:"Cajero asignado",
    statusActive:"Activa", statusInactive:"Inactiva",
    deactivate:"Desactivar", activate:"Activar",
    toastCajaCreated:"Caja registrada correctamente",
    assignCajero:"Asignar cajero",
    toastCajaAsignada:"Cajero asignado correctamente",
    toastCajaStatus:"Estado de la caja actualizado",
    toastCajaDeleted:"Caja eliminada",
    confirmDeleteCaja:"¿Eliminar esta caja? Esta acción no se puede deshacer.",

    /* Ventas */
    ventasTitle:"Historial de ventas", ventasSub:"Transacciones registradas en tu sucursal",
    filterToday:"Hoy", filterWeek:"Esta semana", filterMonth:"Este mes",
    colFecha:"Fecha / hora", colCajero:"Cajero", colProductos:"Producto(s)",
    colTotal:"Total", colMetodo:"Método de pago",
    viewDetail:"Ver detalle",
    modalVentaTitle:"Detalle de venta",
    metodoEfectivo:"Efectivo", metodoTarjeta:"Tarjeta", metodoTransferencia:"Transferencia", metodoPaypal:"PayPal",
    noVentas:"Sin ventas en este periodo.",
    required:"Este campo es obligatorio",
    loading:"Cargando…", noResults:"Sin resultados", noCajas:"Sin cajas",
    noCajasHint:'Registra la primera caja con el botón "Nueva caja".',
    cajasOf:"{a} de {b} cajas", transactions:"transacciones", unassigned:"— Sin asignar —",
    lblNombre:"Nombre", lblDireccion:"Dirección", lblTelefono:"Teléfono", lblEstado:"Estado",
    colCant:"Cant.", saleTotal:"Total de la venta", close:"Cerrar",
    confirmLogout:"¿Cerrar sesión?", placeholderCaja:"Ej: 4",
    errSaveProducto:"No se pudo guardar el producto", errDeleteProducto:"No se pudo eliminar el producto",

    /* Notificaciones: solicitudes de garantía enviadas desde caja */
    navNotificaciones:"Notificaciones",
    notifEyebrow:"Garantías", notifTitle:"Solicitudes de garantía",
    notifDesc:"Solicitudes que los cajeros de esta sede envían desde el Punto de Venta. Revisa el reporte y acepta la garantía o deniégala indicando el motivo.",
    notifPendientes:"Pendientes de revisión", notifResueltas:"Resueltas (últimos 30 días)",
    notifSinPendientes:"No hay solicitudes de garantía pendientes.", notifSinResueltas:"Aún no hay solicitudes resueltas.",
    notifErrCarga:"No se pudieron cargar las solicitudes de garantía.", notifNuevas:"Tienes solicitudes de garantía nuevas por revisar.",
    colFolio:"Folio", colCliente:"Cliente", colVehiculo:"Vehículo", colResolucion:"Resolución",
    estadoPendiente:"Pendiente", estadoAceptada:"Aceptada", estadoDenegada:"Denegada", btnRevisar:"Revisar",
    garTitulo:"Solicitud de garantía", garDatosGarantia:"Garantía del vehículo", garReporte:"Reporte del cajero",
    garCompra:"Compra", garVence:"Vence", garFolioVenta:"Factura / contrato",
    garVigente:"Vigente al solicitar", garNoVigente:"Vencida al solicitar",
    garVinRegistrado:"VIN registrado", garVinReportado:"VIN reportado", garVinNoCoincide:"No coincide con el VIN registrado",
    garPropietario:"Propietario", garContacto:"Contacto", garPlaca:"Placa y año", garKm:"Kilometraje",
    garHistorial:"Historial de servicios", garFechaFalla:"Inicio de la falla", garFechaRecepcion:"Recepción de la unidad",
    garSintoma:"Síntoma", garCondiciones:"Condiciones de la falla", garEvidencia:"Evidencia",
    garAsesor:"Asesor", garConformidad:"Conformidad del cliente",
    garSolicito:"Envió", garResolvio:"Resolvió", garMotivo:"Motivo de la negación",
    garMotivoPlaceholder:"Ej. La falla se debe a falta de mantenimiento o a uso indebido, fuera de la cobertura.",
    btnAceptarGarantia:"Aceptar garantía", btnDenegarGarantia:"Denegar", btnConfirmarDenegar:"Confirmar negación",
    confirmAceptarGarantia:"¿Aceptar la garantía? Se notificará al cajero para continuar con el cliente.",
    garMotivoRequerido:"Escribe el motivo de la negación.", garErrResolver:"No se pudo resolver la solicitud.",
    toastGarantiaAceptada:"Garantía aceptada. Se notificó al cajero.", toastGarantiaDenegada:"Garantía denegada. El cajero verá el motivo.",
  },
  en:{
    topHome:"Go to Home", brandSlogan:"Store Management Panel",
    logout:"Log out", changePassword:"Change password", role:"Role", roleGerente:"Store Manager",
    navDashboard:"Dashboard", navProductos:"Products", navInventario:"Inventory",
    navCajas:"Registers", navVentas:"Sales",
    syncOk:"Live data", syncOff:"DB disconnected",
    date:"Date", time:"Time", manager:"Manager", branch:"Branch", session:"Session", active:"Active",

    dashEyebrow:"Branch", dashTitle:"Management Dashboard",
    kpiVentas:"Sales this month", kpiProductos:"Products in catalog",
    kpiBajoStock:"Stock alerts", kpiCajas:"Active registers",
    vsLastMonth:"vs. last month", unitsInCatalog:"items in catalog",
    alertsThisBranch:"alerts at this branch",
    chartVentasTitulo:"Monthly branch sales", chartVentasSub:"Revenue and units sold",
    revenue:"Revenue", units:"Units",
    chartStockTitulo:"Inventory distribution", chartStockSub:"Stock by category",
    stockCriticoTitulo:"Critical stock products", stockCriticoSub:"Stock at or below minimum",
    stockEmpty:"No critical stock alerts right now.",
    quickTitle:"Quick actions",
    qaProducto:"New product", qaProductoSub:"Register in catalog",
    qaStock:"Update stock", qaStockSub:"Adjust existing stock",
    qaCaja:"New register", qaCajaSub:"Add checkout point",
    qaVentas:"View sales", qaVentasSub:"Sales history",
    sucursalInfoTitle:"Branch information",

    productosTitle:"Product catalog", productosSub:"Vehicles and parts registered at this branch",
    newProducto:"New product", filterAll:"All",
    filterVehiculos:"Vehicles", filterRefacciones:"Parts", filterMotos:"Motorcycles",
    searchPlaceholder:"Search product, make…",
    colProducto:"Product", colMarca:"Make", colCategoria:"Category",
    colPrecio:"Price", colStock:"Stock", colAcciones:"Actions",
    edit:"Edit", delete:"Delete",
    formProductoNewTitle:"Register product", formProductoEditTitle:"Edit product",
    formProductoDesc:"Fill in the product details. Initial stock will be reflected in inventory.",
    fTipo:"Type", tipoVehiculo:"Vehicle", tipoRefaccion:"Part", tipoMoto:"Motorcycle",
    fMarca:"Make", fModelo:"Model / product name", fCategoria:"Category",
    fPrecio:"Sale price (MXN)", fStockInicial:"Initial stock", fStockMin:"Minimum stock",
    fDescripcion:"Description (optional)",
    save:"Save", cancel:"Cancel", saveChanges:"Save changes",
    toastProductoCreated:"Product registered successfully",
    toastProductoUpdated:"Product updated",
    toastProductoDeleted:"Product deleted",
    confirmDelete:"Delete this product? This action cannot be undone.",

    inventarioTitle:"Inventory control", inventarioSub:"Stock at your branch with category filters and low stock alerts",
    filterLow:"Low stock", filterCritical:"Critical",
    colStockActual:"Current stock", colStockMinimo:"Min. stock",
    adjustStock:"Adjust stock",
    modalStockTitle:"Adjust stock",
    modalStockDesc:"Modify the current quantity for this product in inventory.",
    stockCurrentLabel:"Current stock", newStockLabel:"New value",
    motivo:"Reason for adjustment", motivoEntrada:"Incoming stock",
    motivoSalida:"Correction / outgoing", motivoInventario:"Inventory count", motivoOtro:"Other",
    toastStockUpdated:"Stock updated successfully",
    hintDB:"Live stock for your branch.",
    critical:"Critical", low:"Low", ok:"Sufficient",

    cajasTitle:"Register management", cajasSub:"Active and inactive checkout points at your branch",
    newCaja:"New register", colCaja:"Register", colCajero:"Assigned cashier", colEstado:"Status",
    formCajaNewTitle:"Register checkout", formCajaDesc:"Assign a name and cashier to the new register.",
    fNombreCaja:"Register number", fCajeroAsignado:"Assigned cashier",
    statusActive:"Active", statusInactive:"Inactive",
    deactivate:"Deactivate", activate:"Activate",
    toastCajaCreated:"Register created successfully",
    assignCajero:"Assign cashier",
    toastCajaAsignada:"Cashier assigned successfully",
    toastCajaStatus:"Register status updated",
    toastCajaDeleted:"Register deleted",
    confirmDeleteCaja:"Delete this register? This action cannot be undone.",

    ventasTitle:"Sales history", ventasSub:"Transactions recorded at your branch",
    filterToday:"Today", filterWeek:"This week", filterMonth:"This month",
    colFecha:"Date / time", colCajero:"Cashier", colProductos:"Product(s)",
    colTotal:"Total", colMetodo:"Payment method",
    viewDetail:"View detail",
    modalVentaTitle:"Sale detail",
    metodoEfectivo:"Cash", metodoTarjeta:"Card", metodoTransferencia:"Transfer", metodoPaypal:"PayPal",
    noVentas:"No sales in this period.",
    required:"This field is required",
    loading:"Loading…", noResults:"No results", noCajas:"No registers",
    noCajasHint:'Add your first register with the "New register" button.',
    cajasOf:"{a} of {b} registers", transactions:"transactions", unassigned:"— Unassigned —",
    lblNombre:"Name", lblDireccion:"Address", lblTelefono:"Phone", lblEstado:"Status",
    colCant:"Qty.", saleTotal:"Sale total", close:"Close",
    confirmLogout:"Log out?", placeholderCaja:"E.g. 4",
    errSaveProducto:"Could not save the product", errDeleteProducto:"Could not delete the product",

    /* Notifications: warranty requests sent from the register */
    navNotificaciones:"Notifications",
    notifEyebrow:"Warranties", notifTitle:"Warranty requests",
    notifDesc:"Requests that this branch's cashiers send from the Point of Sale. Review the report and approve the warranty or deny it with a reason.",
    notifPendientes:"Pending review", notifResueltas:"Resolved (last 30 days)",
    notifSinPendientes:"No pending warranty requests.", notifSinResueltas:"No resolved requests yet.",
    notifErrCarga:"Could not load the warranty requests.", notifNuevas:"You have new warranty requests to review.",
    colFolio:"Folio", colCliente:"Customer", colVehiculo:"Vehicle", colResolucion:"Resolution",
    estadoPendiente:"Pending", estadoAceptada:"Approved", estadoDenegada:"Denied", btnRevisar:"Review",
    garTitulo:"Warranty request", garDatosGarantia:"Vehicle warranty", garReporte:"Cashier's report",
    garCompra:"Purchase", garVence:"Expires", garFolioVenta:"Invoice / contract",
    garVigente:"Valid when requested", garNoVigente:"Expired when requested",
    garVinRegistrado:"Registered VIN", garVinReportado:"Reported VIN", garVinNoCoincide:"Does not match the registered VIN",
    garPropietario:"Owner", garContacto:"Contact", garPlaca:"Plate and year", garKm:"Mileage",
    garHistorial:"Service history", garFechaFalla:"Failure started", garFechaRecepcion:"Vehicle received",
    garSintoma:"Symptom", garCondiciones:"Failure conditions", garEvidencia:"Evidence",
    garAsesor:"Advisor", garConformidad:"Customer acknowledgment",
    garSolicito:"Sent by", garResolvio:"Resolved by", garMotivo:"Reason for denial",
    garMotivoPlaceholder:"E.g. The failure is due to lack of maintenance or misuse, outside coverage.",
    btnAceptarGarantia:"Approve warranty", btnDenegarGarantia:"Deny", btnConfirmarDenegar:"Confirm denial",
    confirmAceptarGarantia:"Approve the warranty? The cashier will be notified to continue with the customer.",
    garMotivoRequerido:"Write the reason for the denial.", garErrResolver:"Could not resolve the request.",
    toastGarantiaAceptada:"Warranty approved. The cashier was notified.", toastGarantiaDenegada:"Warranty denied. The cashier will see the reason.",
  }
};
function t(key){
  const dict = I18N[state.lang] || I18N.es;
  return dict[key] ?? key;
}
const MESES = {
  es:["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"],
  en:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
};

/* ==========================================================================
   CAPA DE DATOS (DB) — seed en memoria, lista para reemplazar por fetch()
   ========================================================================== */
// API del panel en PHP con la sesión del sistema (antes vivía en el servidor Node del puerto 3000, sin validar la sesión)
const API_GERENTE = "../PHP/Dashboard/gerente_api.php";
// Solicitudes de garantía del POS: API en PHP (Apache) con la sesión del sistema, solo para cuentas Gerente
const API_GARANTIAS = "../PHP/Dashboard/garantias_gerente.php";

/* ---- Sucursal actual del gerente (en producción vendría del JWT / sesión) ---- */
const SUCURSAL_ID = "s1";

const SEED = (() => {
  const sucursal = {
    id: SUCURSAL_ID,
    nombre:"Manzanillo",
    direccion:"Blvd. Costero 1450, Manzanillo, Col.",
    telefono:"314 333 0101",
    email:"manzanillo@karma.mx",
    estado:"activo",
  };

  const cajeros = [
    { id:"u5", nombre:"Ana Martínez",   correo:"ana.martinez@karma.mx",   estado:"activo" },
    { id:"u6", nombre:"Luis Ortega",    correo:"luis.ortega@karma.mx",    estado:"activo" },
    { id:"u10", nombre:"Paola Fuentes", correo:"paola.fuentes@karma.mx",  estado:"activo" },
  ];

  const cajas = [
    { id:"c1", nombre:"Caja 1", cajeroId:"u5",  estado:"activo" },
    { id:"c2", nombre:"Caja 2", cajeroId:"u6",  estado:"activo" },
    { id:"c3", nombre:"Caja 3", cajeroId:"u10", estado:"inactivo" },
  ];

  const productos = [
    { id:"p1",  tipo:"vehiculo",   nombre:"911 Carrera GTS",          marca:"Porsche", categoria:"Autos deportivos", precio:2850000, stockActual:3, stockMinimo:2 },
    { id:"p2",  tipo:"vehiculo",   nombre:"Cayenne Turbo",            marca:"Porsche", categoria:"SUV de lujo",       precio:2190000, stockActual:2, stockMinimo:2 },
    { id:"p3",  tipo:"vehiculo",   nombre:"Taycan Turbo S",           marca:"Porsche", categoria:"Autos deportivos", precio:3120000, stockActual:1, stockMinimo:2 },
    { id:"p4",  tipo:"vehiculo",   nombre:"RS6 Avant",                marca:"Audi",    categoria:"Autos deportivos", precio:2340000, stockActual:4, stockMinimo:2 },
    { id:"p5",  tipo:"vehiculo",   nombre:"Q8 e-tron",                marca:"Audi",    categoria:"SUV de lujo",       precio:1780000, stockActual:0, stockMinimo:2 },
    { id:"p6",  tipo:"vehiculo",   nombre:"R8 V10",                   marca:"Audi",    categoria:"Autos deportivos", precio:3980000, stockActual:2, stockMinimo:1 },
    { id:"p7",  tipo:"moto",       nombre:"Panigale V4 S",            marca:"Ducati",  categoria:"Motocicletas",      precio:695000,  stockActual:3, stockMinimo:2 },
    { id:"p8",  tipo:"moto",       nombre:"Multistrada V4",           marca:"Ducati",  categoria:"Motocicletas",      precio:585000,  stockActual:1, stockMinimo:2 },
    { id:"p9",  tipo:"moto",       nombre:"Streetfighter V2",         marca:"Ducati",  categoria:"Motocicletas",      precio:398000,  stockActual:5, stockMinimo:2 },
    { id:"p10", tipo:"refaccion",  nombre:"Kit de frenos cerámicos",  marca:"Genérico",categoria:"Refacciones",       precio:68000,   stockActual:8, stockMinimo:3 },
    { id:"p11", tipo:"refaccion",  nombre:"Turbo de reemplazo",       marca:"Genérico",categoria:"Refacciones",       precio:112000,  stockActual:2, stockMinimo:3 },
    { id:"p12", tipo:"refaccion",  nombre:"Set de suspensión deportiva",marca:"Genérico",categoria:"Refacciones",     precio:89000,   stockActual:0, stockMinimo:3 },
  ];

  const metodoPago = ["efectivo","tarjeta","transferencia","paypal"];
  const now = new Date();
  const ventas = [];
  let ventaId = 1;
  for (let m = 5; m >= 0; m--){
    const monthDate = new Date(now.getFullYear(), now.getMonth() - m, 1);
    const numVentas = 5 + Math.floor(Math.random()*5);
    for (let i = 0; i < numVentas; i++){
      const prod = productos[Math.floor(Math.random()*productos.length)];
      const caj  = cajeros[Math.floor(Math.random()*cajeros.length)];
      const day  = 1 + Math.floor(Math.random()*27);
      const fecha = new Date(monthDate.getFullYear(), monthDate.getMonth(), day, 9+Math.floor(Math.random()*9), Math.floor(Math.random()*60));
      ventas.push({
        id:"v"+(ventaId++),
        fecha: fecha.toISOString(),
        cajeroId: caj.id,
        cajeroNombre: caj.nombre,
        productoId: prod.id,
        productoNombre: prod.nombre,
        marca: prod.marca,
        total: Math.round(prod.precio * (0.96 + Math.random()*0.08)),
        metodoPago: metodoPago[Math.floor(Math.random()*metodoPago.length)],
        cantidad: 1,
      });
    }
  }

  return { sucursal, cajeros, cajas, productos, ventas };
})();

// Llama a la API del panel (PHP/Dashboard/gerente_api.php). Con `datos` hace POST JSON; sin datos, GET.
// La sucursal la decide el servidor con la sesión (no se manda desde el navegador). Lanza error con el mensaje del servidor.
async function gerenteApi(accion, datos, mensajeError){
  const opciones = datos === undefined
    ? { cache:"no-store" }
    : { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(datos) };
  let respuesta;
  try {
    respuesta = await fetch(`${API_GERENTE}?action=${encodeURIComponent(accion)}`, opciones);
  } catch (_) {
    throw new Error(mensajeError);
  }
  const json = await respuesta.json().catch(() => ({}));
  // Sin sesión: al login; con contraseña temporal: a cambiarla
  if (respuesta.status === 401) { window.location.replace("../index.html"); throw new Error(json.mensaje || mensajeError); }
  if (json.cambiar_password) { window.location.replace("../PHP/Login/cambiar_password.php?forzado=1"); throw new Error(json.mensaje || mensajeError); }
  if (!respuesta.ok) throw new Error(json.mensaje || mensajeError);
  return json;
}

const DB = {
  async getSucursal(){
    return gerenteApi("sucursal", undefined, "No se pudo cargar la sucursal");
  },
  async getCajeros(){
    return gerenteApi("cajeros", undefined, "No se pudieron cargar los cajeros");
  },
  async getCajas(){
    const cajas = await gerenteApi("cajas", undefined, "No se pudieron cargar las cajas");
    return cajas.map(c => ({ ...c, id: String(c.id) }));
  },
  async createCaja(payload){
    return gerenteApi("crear_caja", { numero: payload.numero, cajeroId: payload.cajeroId }, "No se pudo crear la caja");
  },
  async setCajaEstado(id, estado){
    return gerenteApi("estado_caja", { id, estado }, "No se pudo cambiar el estado de la caja");
  },
  async asignarCajero(idCaja, cajeroId){
    return gerenteApi("asignar_cajero", { id: idCaja, cajeroId }, "No se pudo asignar el cajero");
  },
  async getProductos(){
      const productos = await gerenteApi("productos", undefined, "No se pudieron cargar los productos");
      return productos.map(p => ({ ...p, id: String(p.id), precio: Number(p.precio) }));
  },
  async createProducto(payload){
    return gerenteApi("crear_producto", { ...payload }, "No se pudo crear el producto");
  },
  async updateProducto(id, payload){
    return gerenteApi("actualizar_producto", { ...payload, id }, "No se pudo actualizar el producto");
  },
  async deleteProducto(id){
    return gerenteApi("retirar_producto", { id }, "No se pudo retirar el producto");
  },
  async getCategorias(){
    return gerenteApi("categorias", undefined, "No se pudieron cargar las categorías");
  },
  async updateStock(id, nuevoStock){
    return gerenteApi("stock", { id, stockActual: nuevoStock }, "No se pudo actualizar el stock");
  },
  async getVentas(){
    const ventas = await gerenteApi("ventas", undefined, "No se pudieron cargar las ventas");
    return ventas.map(v => ({ ...v, total: Number(v.total) }));
  },
  // Solicitudes de garantía: viven en PHP (sesión del sistema) porque aceptar o denegar exige saber qué gerente lo hace
  async getSolicitudesGarantia(){
    const respuesta = await fetch(`${API_GARANTIAS}?action=listar`, { cache:"no-store" });
    const datos = await respuesta.json().catch(() => ({}));
    if (!respuesta.ok || !datos.ok) throw new Error(datos.error || t("notifErrCarga"));
    return datos.solicitudes || [];
  },
  async resolverSolicitudGarantia(id, decision, motivo){
    const respuesta = await fetch(`${API_GARANTIAS}?action=resolver`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id_solicitud: id, decision, motivo })
    });
    const datos = await respuesta.json().catch(() => ({}));
    if (!respuesta.ok || !datos.ok) throw new Error(datos.error || t("garErrResolver"));
    return datos;
  },
};

/* ==========================================================================
   ESTADO GLOBAL
   ========================================================================== */
const state = {
  view:"dashboard",
  lang: localStorage.getItem("karma_idioma") === "en" ? "en" : "es", // idioma compartido con los demás módulos
  sucursal: null,
  cajeros: [],
  cajas: [],
  productos: [],
  categorias: [],
  ventas: [],
  productosFiltro:"all",  // all | vehiculo | moto | refaccion
  productosQuery:"",
  inventarioFiltro:"all", // all | low | critical
  inventarioQuery:"",
  ventasFiltro:"month",   // today | week | month
  cajasFiltro:"all",      // all | activo | inactivo
  cargando: true,
  esGerente: false,          // la pestaña Notificaciones es exclusiva del rol Gerente
  solicitudesGarantia: [],   // solicitudes de garantía de la sede (pendientes + resueltas recientes)
  errorGarantias: "",
};
const chartInstances = {};

/* ==========================================================================
   CARGA INICIAL
   ========================================================================== */
async function cargarDatos(){
  state.cargando = true;
  try{
    const [sucursal, cajeros, cajas, productos, ventas, categorias] = await Promise.all([
      DB.getSucursal(), DB.getCajeros(), DB.getCajas(), DB.getProductos(), DB.getVentas(), DB.getCategorias()
    ]);
    state.categorias = categorias;
    state.sucursal = sucursal;
    state.cajeros  = cajeros;
    state.cajas    = cajas;
    state.productos = productos;
    state.ventas    = ventas;
    setSyncStatus(true);
    // Actualizar statusbar con datos reales
    const statusGerente = $("#statusGerente");
    const statusSucursal = $("#statusSucursal");
    const usuarioGuardado = JSON.parse(localStorage.getItem("karma_user") || "null");
    if (statusGerente) statusGerente.textContent = usuarioGuardado?.nombre || "—";// vendría del JWT
    if (statusSucursal && sucursal) statusSucursal.textContent = sucursal.nombre;
  }catch(err){
    console.error("Error cargando datos", err);
    setSyncStatus(false);
  }finally{
    state.cargando = false;
  }
}

function setSyncStatus(ok){
  const el = $("#syncIndicator");
  if (!el) return;
  el.classList.toggle("is-offline", !ok);
  $(".sync-text", el).textContent = ok ? t("syncOk") : t("syncOff");
}

/* ==========================================================================
   HELPERS
   ========================================================================== */
function cajeroPorId(id){
  return state.cajeros.find(c => c.id === id) || null;
}
function cajaNombre(id){
  const c = state.cajas.find(x => x.id === id);
  return c ? c.nombre : "—";
}
function totalVentasMes(offsetMeses){
  const now = new Date();
  const target = new Date(now.getFullYear(), now.getMonth() - offsetMeses, 1);
  return state.ventas
    .filter(v => { const d = new Date(v.fecha); return d.getFullYear() === target.getFullYear() && d.getMonth() === target.getMonth(); })
    .reduce((s,v) => s + v.total, 0);
}
function serieMensual(meses = 6){
  const now = new Date();
  const labels=[], ingresos=[], unidades=[];
  for (let m = meses-1; m >= 0; m--){
    const target = new Date(now.getFullYear(), now.getMonth()-m, 1);
    const delMes = state.ventas.filter(v => { const d = new Date(v.fecha); return d.getFullYear()===target.getFullYear() && d.getMonth()===target.getMonth(); });
    labels.push(MESES[state.lang][target.getMonth()]);
    ingresos.push(delMes.reduce((s,v)=>s+v.total,0));
    unidades.push(delMes.length);
  }
  return { labels, ingresos, unidades };
}
function stockPorCategoria(){
  const map = {};
  state.productos.forEach(p => { map[p.categoria] = (map[p.categoria]||0) + p.stockActual; });
  return map;
}
function productosFiltrados(){
  let list = state.productos;
  if (state.productosFiltro !== "all") list = list.filter(p => p.tipo === state.productosFiltro);
  if (state.productosQuery){
    const q = state.productosQuery.toLowerCase();
    list = list.filter(p => p.nombre.toLowerCase().includes(q) || p.marca.toLowerCase().includes(q) || p.categoria.toLowerCase().includes(q));
  }
  return list;
}
function inventarioFiltrado(){
  let list = state.productos;
  if (state.inventarioFiltro === "low")      list = list.filter(p => p.stockActual <= p.stockMinimo);
  if (state.inventarioFiltro === "critical") list = list.filter(p => p.stockActual === 0);
  if (state.inventarioQuery){
    const q = state.inventarioQuery.toLowerCase();
    list = list.filter(p => p.nombre.toLowerCase().includes(q) || p.marca.toLowerCase().includes(q) || p.categoria.toLowerCase().includes(q));
  }
  return list;
}
function ventasFiltradas(){
  const now = new Date();
  return state.ventas.filter(v => {
    const d = new Date(v.fecha);
    if (state.ventasFiltro === "today"){
      return d.toDateString() === now.toDateString();
    }
    if (state.ventasFiltro === "week"){
      const weekAgo = new Date(now); weekAgo.setDate(weekAgo.getDate()-7);
      return d >= weekAgo;
    }
    // month
    return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
  });
}
function stockBadge(p){
  if (p.stockActual === 0)              return `<span class="badge badge-danger"><span class="badge-dot"></span>${t("critical")}</span>`;
  if (p.stockActual <= p.stockMinimo)   return `<span class="badge badge-warn"><span class="badge-dot"></span>${t("low")}</span>`;
  return `<span class="badge badge-ok"><span class="badge-dot"></span>${t("ok")}</span>`;
}
function metodoBadge(m){
  const map = { efectivo:"badge-ok", tarjeta:"badge-warn", transferencia:"badge-ok", paypal:"badge-ok" };
  const cls = map[m] || "badge-off";
  const label = { efectivo:t("metodoEfectivo"), tarjeta:t("metodoTarjeta"), transferencia:t("metodoTransferencia"), paypal:t("metodoPaypal") }[m] || m;
  return `<span class="badge ${cls}">${escapeHTML(label)}</span>`;
}

/* ==========================================================================
   RENDER PRINCIPAL
   ========================================================================== */
function renderMain(){
  const main = $("#main");
  if (state.cargando){
    main.innerHTML = `<div class="panel panel-full"><div class="empty-state"><strong>${t("loading")}</strong></div></div>`;
    return;
  }
  $$(".sub-nav-btn").forEach(b => b.classList.toggle("is-active", b.dataset.view === state.view));
  if      (state.view === "dashboard")  renderDashboard();
  else if (state.view === "productos")  renderProductos();
  else if (state.view === "inventario") renderInventario();
  else if (state.view === "cajas")      renderCajas();
  else if (state.view === "ventas")     renderVentas();
  else if (state.view === "notificaciones" && state.esGerente) renderNotificaciones();
  applyI18n();
}

/* ==========================================================================
   VISTA: DASHBOARD
   ========================================================================== */
function renderDashboard(){
  const main = $("#main");
  const totalMes = totalVentasMes(0);
  const totalAnterior = totalVentasMes(1);
  const delta = totalAnterior > 0 ? ((totalMes - totalAnterior)/totalAnterior)*100 : (totalMes>0?100:0);
  const deltaUp = delta >= 0;
  const alertas = state.productos.filter(p => p.stockActual <= p.stockMinimo);
  const cajasActivas = state.cajas.filter(c => c.estado === "activo").length;
  const { labels, ingresos, unidades } = serieMensual();
  const stockCat = stockPorCategoria();

  main.innerHTML = `
  <div class="panel panel-full">

    <div class="panel-heading fade-in">
      <div>
        <p class="eyebrow-plain">${t("dashEyebrow")} · ${escapeHTML(state.sucursal?.nombre || "")}</p>
        <h2>${t("dashTitle")}</h2>
      </div>
    </div>

    <!-- Quick actions -->
    <div class="quick-actions fade-in fade-in--1">
      <button class="quick-action" id="qaProductoBtn">
        <span class="quick-action-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><path d="M14 17.5h7M17.5 14v7"/></svg>
        </span>
        <span class="quick-action-text">
          <span class="quick-action-title" data-i18n="qaProducto">Nuevo producto</span>
          <span class="quick-action-sub"   data-i18n="qaProductoSub">Registrar en catálogo</span>
        </span>
      </button>
      <button class="quick-action" id="qaStockBtn">
        <span class="quick-action-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2Z"/><path d="M16 3H8L6 7h12l-2-4Z"/><path d="M12 12v4m-2-2h4"/></svg>
        </span>
        <span class="quick-action-text">
          <span class="quick-action-title" data-i18n="qaStock">Actualizar stock</span>
          <span class="quick-action-sub"   data-i18n="qaStockSub">Ajustar existencias</span>
        </span>
      </button>
      <button class="quick-action" id="qaCajaBtn">
        <span class="quick-action-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="6" width="20" height="14" rx="2"/><path d="M6 6V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v2"/><path d="M12 12v.01"/></svg>
        </span>
        <span class="quick-action-text">
          <span class="quick-action-title" data-i18n="qaCaja">Nueva caja</span>
          <span class="quick-action-sub"   data-i18n="qaCajaSub">Registrar punto de cobro</span>
        </span>
      </button>
      <button class="quick-action" id="qaVentasBtn">
        <span class="quick-action-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13l-1.5 7h13M10 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2Zm7 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"/></svg>
        </span>
        <span class="quick-action-text">
          <span class="quick-action-title" data-i18n="qaVentas">Ver ventas</span>
          <span class="quick-action-sub"   data-i18n="qaVentasSub">Historial de ventas</span>
        </span>
      </button>
    </div>

    <!-- KPIs -->
    <div class="kpi-grid fade-in fade-in--2">
      <div class="kpi-card">
        <div class="kpi-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 1 0 0 7h5a3.5 3.5 0 1 1 0 7H6"/></svg></div>
        <div class="kpi-label" data-i18n="kpiVentas">Ventas del mes</div>
        <div class="kpi-value">${formatoMoneda(totalMes)}</div>
        <div class="kpi-sub">
          <span class="kpi-delta ${deltaUp?"is-up":"is-down"}">${deltaUp?"▲":"▼"} ${Math.abs(delta).toFixed(1)}%</span>
          <span data-i18n="vsLastMonth">vs. mes anterior</span>
        </div>
      </div>
      <div class="kpi-card">
        <div class="kpi-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg></div>
        <div class="kpi-label" data-i18n="kpiProductos">Productos en catálogo</div>
        <div class="kpi-value">${formatoNumero(state.productos.length)}</div>
        <div class="kpi-sub"><span>${state.productos.length} ${t("unitsInCatalog")}</span></div>
      </div>
      <div class="kpi-card">
        <div class="kpi-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z"/><path d="M12 9v4M12 17h.01"/></svg></div>
        <div class="kpi-label" data-i18n="kpiBajoStock">Alertas de stock</div>
        <div class="kpi-value" style="color:${alertas.length>0?"var(--red)":"var(--ok)"}">${alertas.length}</div>
        <div class="kpi-sub"><span>${alertas.length} ${t("alertsThisBranch")}</span></div>
      </div>
      <div class="kpi-card">
        <div class="kpi-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="6" width="20" height="14" rx="2"/><path d="M6 6V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v2"/></svg></div>
        <div class="kpi-label" data-i18n="kpiCajas">Cajas activas</div>
        <div class="kpi-value">${cajasActivas}</div>
        <div class="kpi-sub"><span>${t("cajasOf").replace("{a}", cajasActivas).replace("{b}", state.cajas.length)}</span></div>
      </div>
    </div>

    <!-- Gráficas -->
    <div class="charts-row fade-in fade-in--3">
      <div class="chart-card">
        <div class="chart-card-head">
          <h3 data-i18n="chartVentasTitulo">Ventas mensuales de la sede</h3>
          <span data-i18n="chartVentasSub">Ingresos y unidades vendidas</span>
        </div>
        <div class="chart-canvas-wrap"><canvas id="chartVentas"></canvas></div>
        <div class="chart-legend">
          <span class="chart-legend-item"><span class="chart-legend-dot" style="background:var(--chart-green)"></span><span data-i18n="revenue">Ingresos</span></span>
          <span class="chart-legend-item"><span class="chart-legend-dot" style="background:var(--chart-red)"></span><span data-i18n="units">Unidades</span></span>
        </div>
      </div>
      <div class="chart-card">
        <div class="chart-card-head">
          <h3 data-i18n="chartStockTitulo">Distribución de inventario</h3>
          <span data-i18n="chartStockSub">Existencias por categoría</span>
        </div>
        <div class="chart-canvas-wrap is-small"><canvas id="chartStock"></canvas></div>
      </div>
    </div>

    <!-- Stock crítico -->
    ${alertas.length > 0 ? `
    <div class="alert-panel fade-in fade-in--4">
      <div class="alert-panel-head">
        <h3>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z"/><path d="M12 9v4M12 17h.01"/></svg>
          ${t("stockCriticoTitulo")}
        </h3>
        <span style="font-size:12px;color:var(--text-muted);margin-left:auto;">${t("stockCriticoSub")}</span>
      </div>
      <div class="alert-list">
        ${alertas.slice(0,6).map(p => `
        <div class="alert-item">
          <div class="alert-item-main">
            <span class="alert-item-title">${escapeHTML(p.nombre)}</span>
            <span class="alert-item-sub">${escapeHTML(p.marca)} · ${escapeHTML(p.categoria)}</span>
          </div>
          <div class="alert-item-actions">
            <span class="alert-item-stock">${p.stockActual} / mín ${p.stockMinimo}</span>
            <button class="btn-table btn-sm" data-adjust-stock="${escapeHTML(p.id)}">${t("adjustStock")}</button>
          </div>
        </div>`).join("")}
      </div>
    </div>` : `
    <div class="alert-panel fade-in fade-in--4" style="border-color:var(--ok-soft);background:var(--ok-soft);">
      <div class="alert-panel-head"><h3 style="color:var(--ok);">✓ ${t("stockEmpty")}</h3></div>
    </div>`}

    <!-- Info sucursal -->
    <div class="info-card fade-in fade-in--4">
      <div class="info-card-head">
        <h3 data-i18n="sucursalInfoTitle">Información de la sucursal</h3>
      </div>
      <div class="info-grid">
        <div class="info-item"><span class="info-item-label">${t("lblNombre")}</span><span class="info-item-value">${escapeHTML(state.sucursal?.nombre||"")}</span></div>
        <div class="info-item"><span class="info-item-label">${t("lblDireccion")}</span><span class="info-item-value">${escapeHTML(state.sucursal?.direccion||"")}</span></div>
        <div class="info-item"><span class="info-item-label">${t("lblTelefono")}</span><span class="info-item-value">${escapeHTML(state.sucursal?.telefono||"")}</span></div>
        <div class="info-item"><span class="info-item-label">${t("lblEstado")}</span><span class="info-item-value">
          ${state.sucursal?.estado === "activo"
            ? `<span class="badge badge-ok"><span class="badge-dot"></span>${t("statusActive")}</span>`
            : `<span class="badge badge-off"><span class="badge-dot"></span>${t("statusInactive")}</span>`}
        </span></div>
      </div>
    </div>

  </div>`;

  // Gráfica ventas
  mountChart("chartVentas", () => {
    const ctx = $("#chartVentas").getContext("2d");
    return new Chart(ctx, {
      type:"bar",
      data:{
        labels,
        datasets:[
          { label:t("revenue"), data:ingresos, backgroundColor:"rgba(16,33,63,.75)", borderRadius:6, yAxisID:"y" },
          { label:t("units"),   data:unidades, type:"line", borderColor: cssVar("--chart-red", "#9e1b2e") , backgroundColor:"rgba(158,27,46,.12)", tension:.4, pointRadius:4, yAxisID:"y1" },
        ]
      },
      options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false } },
        scales:{
          y:{ position:"left", grid:{ color: cssVar("--chart-grid", "rgba(0,0,0,.08)") }, ticks:{ callback:v=>formatoMoneda(v) } },
          y1:{ position:"right", grid:{ drawOnChartArea:false }, ticks:{ stepSize:1 } }
        }
      }
    });
  });

  // Gráfica stock
  mountChart("chartStock", () => {
    const cats = Object.keys(stockCat);
    const vals = Object.values(stockCat);
    const palette = ["rgba(16,33,63,.8)","rgba(158,27,46,.75)","rgba(180,121,26,.75)","rgba(124,147,184,.75)","rgba(16,33,63,.45)","rgba(158,27,46,.45)"];
    const ctx = $("#chartStock").getContext("2d");
    return new Chart(ctx, {
      type:"doughnut",
      data:{ labels:cats, datasets:[{ data:vals, backgroundColor:palette.slice(0,cats.length), borderWidth:0, hoverOffset:6 }] },
      options:{ responsive:true, maintainAspectRatio:false, cutout:"62%", plugins:{ legend:{ position:"bottom", labels:{ boxWidth:11, padding:12, font:{ size:11 } } } } }
    });
  });

  // Quick action listeners
  $("#qaProductoBtn")?.addEventListener("click", () => abrirModalProducto(null));
  $("#qaStockBtn")?.addEventListener("click",    () => { state.view="inventario"; renderMain(); });
  $("#qaCajaBtn")?.addEventListener("click",     () => abrirModalCaja());
  $("#qaVentasBtn")?.addEventListener("click",   () => { state.view="ventas"; renderMain(); });
  $$("[data-adjust-stock]").forEach(btn => {
    btn.addEventListener("click", () => abrirModalStock(btn.dataset.adjustStock));
  });
}

function mountChart(id, factory){
  if (chartInstances[id]){ chartInstances[id].destroy(); delete chartInstances[id]; }
  const el = $(`#${id}`);
  if (el) chartInstances[id] = factory();
}

/* ==========================================================================
   VISTA: PRODUCTOS
   ========================================================================== */
function renderProductos(){
  const main = $("#main");
  const lista = productosFiltrados();

  main.innerHTML = `
  <div class="panel panel-full">
    <div class="panel-heading fade-in">
      <div>
        <p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursal?.nombre||"")}</p>
        <h2 data-i18n="productosTitle">Catálogo de productos</h2>
      </div>
      <div class="panel-heading-actions">
        <button class="btn btn-primary" id="btnNuevoProducto">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M12 5v14M5 12h14"/></svg>
          <span data-i18n="newProducto">Nuevo producto</span>
        </button>
      </div>
    </div>

    <div class="section-toolbar fade-in fade-in--1">
      <div class="filter-pills">
        ${[["all","filterAll"],["vehiculo","filterVehiculos"],["moto","filterMotos"],["refaccion","filterRefacciones"]].map(([v,k])=>
          `<button class="filter-pill ${state.productosFiltro===v?"is-active":""}" data-prod-filtro="${v}" data-i18n="${k}">${t(k)}</button>`
        ).join("")}
      </div>
      <div class="search-bar">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        <input type="text" id="searchProductos" placeholder="${t("searchPlaceholder")}" value="${escapeHTML(state.productosQuery)}">
      </div>
    </div>

    <div class="table-wrap fade-in fade-in--2">
      <table class="data-table">
        <thead><tr>
          <th data-i18n="colProducto">Producto</th>
          <th data-i18n="colMarca">Marca</th>
          <th data-i18n="colCategoria">Categoría</th>
          <th data-i18n="colPrecio">Precio</th>
          <th data-i18n="colStock">Stock</th>
          <th data-i18n="colAcciones">Acciones</th>
        </tr></thead>
        <tbody>
          ${lista.length === 0 ? `<tr><td colspan="6"><div class="empty-state"><strong>${t("noResults")}</strong></div></td></tr>` :
            lista.map(p => `
            <tr>
              <td><strong>${escapeHTML(p.nombre)}</strong><br><span class="cell-muted" style="font-size:11.5px;">${escapeHTML(etiquetaTipo(p.tipo))}</span></td>
              <td>${escapeHTML(p.marca)}</td>
              <td>${escapeHTML(p.categoria)}</td>
              <td>${formatoMoneda(p.precio)}</td>
              <td>${stockBadge(p)} <span style="margin-left:6px;font-weight:600;">${p.stockActual}</span></td>
              <td>
                <div class="btn-table-row">
                  <button class="btn-table btn-sm" data-edit-producto="${escapeHTML(p.id)}" data-i18n="edit">Editar</button>
                  <button class="btn-table-danger btn-sm" data-delete-producto="${escapeHTML(p.id)}" data-i18n="delete">Eliminar</button>
                </div>
              </td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>
  </div>`;

  $("#btnNuevoProducto")?.addEventListener("click", () => abrirModalProducto(null));
  $$("[data-prod-filtro]").forEach(btn => {
    btn.addEventListener("click", () => { state.productosFiltro = btn.dataset.prodFiltro; renderProductos(); });
  });
  const searchInput = $("#searchProductos");
  if (searchInput){
    searchInput.addEventListener("input", () => { state.productosQuery = searchInput.value; renderProductos(); });
    searchInput.focus();
  }
  $$("[data-edit-producto]").forEach(btn => btn.addEventListener("click", () => abrirModalProducto(btn.dataset.editProducto)));
  $$("[data-delete-producto]").forEach(btn => btn.addEventListener("click", () => eliminarProducto(btn.dataset.deleteProducto)));
}

/* ==========================================================================
   VISTA: INVENTARIO
   ========================================================================== */
function renderInventario(){
  const main = $("#main");
  const lista = inventarioFiltrado();

  main.innerHTML = `
  <div class="panel panel-full">
    <div class="panel-heading fade-in">
      <div>
        <p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursal?.nombre||"")}</p>
        <h2 data-i18n="inventarioTitle">Control de inventario</h2>
      </div>
    </div>

    <div class="hint-banner fade-in fade-in--1">
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>
      <span data-i18n="hintDB">Vista conectada a DB (mock)</span>
    </div>

    <div class="section-toolbar fade-in fade-in--1">
      <div class="filter-pills">
        ${[["all","filterAll"],["low","filterLow"],["critical","filterCritical"]].map(([v,k])=>
          `<button class="filter-pill ${state.inventarioFiltro===v?"is-active":""}" data-inv-filtro="${v}" data-i18n="${k}">${t(k)}</button>`
        ).join("")}
      </div>
      <div class="search-bar">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        <input type="text" id="searchInventario" placeholder="${t("searchPlaceholder")}" value="${escapeHTML(state.inventarioQuery)}">
      </div>
    </div>

    <div class="table-wrap fade-in fade-in--2">
      <table class="data-table">
        <thead><tr>
          <th data-i18n="colProducto">Producto</th>
          <th data-i18n="colMarca">Marca</th>
          <th data-i18n="colCategoria">Categoría</th>
          <th data-i18n="colStockActual">Stock actual</th>
          <th data-i18n="colStockMinimo">Stock mínimo</th>
          <th data-i18n="colPrecio">Precio</th>
          <th data-i18n="colAcciones">Acciones</th>
        </tr></thead>
        <tbody>
          ${lista.length === 0 ? `<tr><td colspan="7"><div class="empty-state"><strong>${t("noResults")}</strong></div></td></tr>` :
            lista.map(p => `
            <tr>
              <td><strong>${escapeHTML(p.nombre)}</strong></td>
              <td>${escapeHTML(p.marca)}</td>
              <td>${escapeHTML(p.categoria)}</td>
              <td>${stockBadge(p)} <span style="margin-left:6px;font-weight:700;">${p.stockActual}</span></td>
              <td class="cell-muted">${p.stockMinimo}</td>
              <td>${formatoMoneda(p.precio)}</td>
              <td>
                <button class="btn-table btn-sm" data-adjust-stock="${escapeHTML(p.id)}" data-i18n="adjustStock">Ajustar stock</button>
              </td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>
  </div>`;

  $$("[data-inv-filtro]").forEach(btn => {
    btn.addEventListener("click", () => { state.inventarioFiltro = btn.dataset.invFiltro; renderInventario(); });
  });
  const searchInput = $("#searchInventario");
  if (searchInput){
    searchInput.addEventListener("input", () => { state.inventarioQuery = searchInput.value; renderInventario(); });
    searchInput.focus();
  }
  $$("[data-adjust-stock]").forEach(btn => btn.addEventListener("click", () => abrirModalStock(btn.dataset.adjustStock)));
}

/* ==========================================================================
   VISTA: CAJAS
   ========================================================================== */
function renderCajas(){
  const main = $("#main");
  const lista = state.cajasFiltro === "all"
    ? state.cajas
    : state.cajas.filter(c => c.estado === state.cajasFiltro);

  main.innerHTML = `
  <div class="panel panel-full">
    <div class="panel-heading fade-in">
      <div>
        <p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursal?.nombre||"")}</p>
        <h2 data-i18n="cajasTitle">Gestión de cajas</h2>
      </div>
      <div class="panel-heading-actions">
        <button class="btn btn-primary" id="btnNuevaCaja">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M12 5v14M5 12h14"/></svg>
          <span data-i18n="newCaja">Nueva caja</span>
        </button>
      </div>
    </div>

    <div class="section-toolbar fade-in fade-in--1">
      <div class="filter-pills">
        ${[["all","filterAll"],["activo","statusActive"],["inactivo","statusInactive"]].map(([v,k])=>
          `<button class="filter-pill ${state.cajasFiltro===v?"is-active":""}" data-caja-filtro="${v}" data-i18n="${k}">${t(k)}</button>`
        ).join("")}
      </div>
    </div>

    <div class="cajas-grid fade-in fade-in--2">
      ${lista.length === 0 ? `<div class="empty-state"><strong>${t("noCajas")}</strong><span>${t("noCajasHint")}</span></div>` :
        lista.map(c => {
          const cajero = cajeroPorId(c.cajeroId);
          const activa = c.estado === "activo";
          return `
          <div class="caja-card">
            <div class="caja-card-head">
              <div class="caja-number">${escapeHTML(c.nombre.replace(/[^0-9]/g,"") || "—")}</div>
              <span class="badge ${activa?"badge-ok":"badge-off"}">
                <span class="badge-dot"></span>
                ${activa ? t("statusActive") : t("statusInactive")}
              </span>
            </div>
            <div class="caja-card-body">
              <span class="caja-name">${escapeHTML(c.nombre)}</span>
              <span class="caja-meta">${cajero ? escapeHTML(cajero.nombre) : "—"}</span>
              ${cajero ? `<span class="caja-meta" style="font-size:11px;color:var(--text-faint);">${escapeHTML(cajero.correo)}</span>` : ""}
            </div>
            <div class="caja-card-footer">
              <button class="btn-table btn-sm" data-assign-caja="${escapeHTML(c.id)}">${t("assignCajero")}</button>
              <button class="btn-table btn-sm" data-toggle-caja="${escapeHTML(c.id)}" data-estado="${c.estado}">
                ${activa ? t("deactivate") : t("activate")}
              </button>
            </div>
          </div>`;
        }).join("")}
    </div>
  </div>`;

  $("#btnNuevaCaja")?.addEventListener("click", () => abrirModalCaja());
  $$("[data-caja-filtro]").forEach(btn => {
    btn.addEventListener("click", () => { state.cajasFiltro = btn.dataset.cajaFiltro; renderCajas(); });
  });
  $$("[data-assign-caja]").forEach(btn => {
    btn.addEventListener("click", () => abrirModalAsignarCajero(btn.dataset.assignCaja));
  });
  $$("[data-toggle-caja]").forEach(btn => {
    btn.addEventListener("click", async () => {
      const nuevoEstado = btn.dataset.estado === "activo" ? "inactivo" : "activo";
      try {
        await DB.setCajaEstado(btn.dataset.toggleCaja, nuevoEstado);
        state.cajas = await DB.getCajas();
        toast(t("toastCajaStatus"), "ok");
        renderCajas();
      } catch (err) {
        console.error(err);
        toast(err.message, "err");
      }
    });
  });
}
/* ==========================================================================
   VISTA: VENTAS
   ========================================================================== */
function renderVentas(){
  const main = $("#main");
  const lista = ventasFiltradas().sort((a,b) => new Date(b.fecha) - new Date(a.fecha));
  const totalPeriodo = lista.reduce((s,v) => s+v.total, 0);

  main.innerHTML = `
  <div class="panel panel-full">
    <div class="panel-heading fade-in">
      <div>
        <p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursal?.nombre||"")}</p>
        <h2 data-i18n="ventasTitle">Historial de ventas</h2>
      </div>
      <div class="panel-heading-actions">
        <span style="font-family:var(--font-display);font-size:22px;font-weight:600;">${formatoMoneda(totalPeriodo)}</span>
      </div>
    </div>

    <div class="section-toolbar fade-in fade-in--1">
      <div class="filter-pills">
        ${[["today","filterToday"],["week","filterWeek"],["month","filterMonth"]].map(([v,k])=>
          `<button class="filter-pill ${state.ventasFiltro===v?"is-active":""}" data-ventas-filtro="${v}" data-i18n="${k}">${t(k)}</button>`
        ).join("")}
      </div>
      <span style="font-size:12.5px;color:var(--text-muted);">${lista.length} ${t("transactions")}</span>
    </div>

    <div class="table-wrap fade-in fade-in--2">
      <table class="data-table">
        <thead><tr>
          <th data-i18n="colFecha">Fecha / hora</th>
          <th data-i18n="colCajero">Cajero</th>
          <th data-i18n="colProductos">Producto(s)</th>
          <th data-i18n="colMetodo">Método de pago</th>
          <th data-i18n="colTotal">Total</th>
          <th data-i18n="colAcciones">Acciones</th>
        </tr></thead>
        <tbody>
          ${lista.length === 0 ? `<tr><td colspan="6"><div class="empty-state"><strong>${t("noVentas")}</strong></div></td></tr>` :
            lista.map(v => `
            <tr class="is-clickable" data-venta-id="${escapeHTML(v.id)}">
              <td>
                <span style="font-weight:600;">${formatFecha(v.fecha)}</span>
                <br><span class="cell-muted" style="font-size:11.5px;">${formatHora(v.fecha)}</span>
              </td>
              <td>${escapeHTML(v.cajeroNombre)}</td>
              <td>${escapeHTML(v.productoNombre)}<br><span class="cell-muted" style="font-size:11.5px;">${escapeHTML(v.marca)}</span></td>
              <td>${metodoBadge(v.metodoPago)}</td>
              <td style="font-weight:700;">${formatoMoneda(v.total)}</td>
              <td><button class="btn-table btn-sm" data-ver-venta="${escapeHTML(v.id)}" data-i18n="viewDetail">Ver detalle</button></td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>
  </div>`;

  $$("[data-ventas-filtro]").forEach(btn => {
    btn.addEventListener("click", () => { state.ventasFiltro = btn.dataset.ventasFiltro; renderVentas(); });
  });
  $$("[data-ver-venta]").forEach(btn => btn.addEventListener("click", () => abrirModalVenta(btn.dataset.verVenta)));
}

/* ==========================================================================
   VISTA: NOTIFICACIONES — solicitudes de garantía enviadas desde caja (solo Gerente)
   ========================================================================== */
function estadoGarantiaBadge(estado){
  if (estado === "pendiente")  return `<span class="badge badge-warn"><span class="badge-dot"></span>${t("estadoPendiente")}</span>`;
  if (estado === "confirmada") return `<span class="badge badge-ok"><span class="badge-dot"></span>${t("estadoAceptada")}</span>`;
  return `<span class="badge badge-danger"><span class="badge-dot"></span>${t("estadoDenegada")}</span>`;
}
function fechaHoraGarantia(iso){
  return iso ? `${formatFecha(iso)} · ${formatHora(iso)}` : "—";
}
function vehiculoGarantiaHTML(s){
  return `${escapeHTML(s.articulo)}${s.vin ? `<br><span class="cell-muted" style="font-size:11.5px;">VIN ${escapeHTML(s.vin)}</span>` : ""}`;
}

function renderNotificaciones(){
  const main = $("#main");
  const pendientes = state.solicitudesGarantia.filter(s => s.estado === "pendiente");
  const resueltas  = state.solicitudesGarantia.filter(s => s.estado !== "pendiente");

  main.innerHTML = `
  <div class="panel panel-full">
    <div class="panel-heading fade-in">
      <div>
        <p class="eyebrow-plain">${t("notifEyebrow")}${state.sucursal?.nombre ? ` · ${escapeHTML(state.sucursal.nombre)}` : ""}</p>
        <h2>${t("notifTitle")}</h2>
      </div>
    </div>
    <p class="modal-desc fade-in">${t("notifDesc")}</p>
    ${state.errorGarantias ? `<div class="empty-state"><strong>${escapeHTML(state.errorGarantias)}</strong></div>` : ""}

    <h3 class="notif-subtitulo fade-in fade-in--1">${t("notifPendientes")} (${pendientes.length})</h3>
    <div class="table-wrap fade-in fade-in--1">
      <table class="data-table">
        <thead><tr>
          <th>${t("colFolio")}</th><th>${t("colFecha")}</th><th>${t("colCajero")}</th>
          <th>${t("colCliente")}</th><th>${t("colVehiculo")}</th><th>${t("colAcciones")}</th>
        </tr></thead>
        <tbody>
          ${pendientes.length === 0 ? `<tr><td colspan="6"><div class="empty-state"><strong>${t("notifSinPendientes")}</strong></div></td></tr>` :
            pendientes.map(s => `
            <tr class="is-clickable" data-solicitud-id="${s.id}">
              <td><strong style="font-family:monospace;">${escapeHTML(s.folio)}</strong></td>
              <td><span style="font-weight:600;">${formatFecha(s.fechaSolicitud)}</span><br><span class="cell-muted" style="font-size:11.5px;">${formatHora(s.fechaSolicitud)}</span></td>
              <td>${escapeHTML(s.cajero)}</td>
              <td>${escapeHTML(s.cliente || "—")}</td>
              <td>${vehiculoGarantiaHTML(s)}</td>
              <td><button class="btn-table btn-sm">${t("btnRevisar")}</button></td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>

    <h3 class="notif-subtitulo fade-in fade-in--2">${t("notifResueltas")}</h3>
    <div class="table-wrap fade-in fade-in--2">
      <table class="data-table">
        <thead><tr>
          <th>${t("colFolio")}</th><th>${t("colCliente")}</th><th>${t("colVehiculo")}</th>
          <th>${t("colEstado")}</th><th>${t("colResolucion")}</th><th>${t("colAcciones")}</th>
        </tr></thead>
        <tbody>
          ${resueltas.length === 0 ? `<tr><td colspan="6"><div class="empty-state"><strong>${t("notifSinResueltas")}</strong></div></td></tr>` :
            resueltas.map(s => `
            <tr class="is-clickable" data-solicitud-id="${s.id}">
              <td><strong style="font-family:monospace;">${escapeHTML(s.folio)}</strong></td>
              <td>${escapeHTML(s.cliente || "—")}</td>
              <td>${vehiculoGarantiaHTML(s)}</td>
              <td>${estadoGarantiaBadge(s.estado)}</td>
              <td>${fechaHoraGarantia(s.fechaResolucion)}<br><span class="cell-muted" style="font-size:11.5px;">${escapeHTML(s.resolvio || "")}</span></td>
              <td><button class="btn-table btn-sm">${t("viewDetail")}</button></td>
            </tr>`).join("")}
        </tbody>
      </table>
    </div>
  </div>`;

  $$("[data-solicitud-id]", main).forEach(fila => fila.addEventListener("click", () => abrirModalGarantia(Number(fila.dataset.solicitudId))));
}

/* ==========================================================================
   MODAL: REVISIÓN DE UNA SOLICITUD DE GARANTÍA (aceptar / denegar con motivo)
   ========================================================================== */
function abrirModalGarantia(id){
  const s = state.solicitudesGarantia.find(x => x.id === id);
  if (!s) return;
  const r = s.reporte || {};
  const texto = (v) => (v === null || v === undefined || String(v).trim() === "") ? "—" : escapeHTML(v);
  const dato  = (etiqueta, valor) => `<div class="info-item"><span class="info-item-label">${etiqueta}</span><span class="info-item-value">${valor}</span></div>`;
  const bloque = (etiqueta, valor) => `<div class="info-item garantia-texto"><span class="info-item-label">${etiqueta}</span><span class="info-item-value">${texto(valor)}</span></div>`;
  // Fechas del formulario del cajero (datetime-local, sin zona): se muestran como las capturó
  const fechaReporte = (v) => v ? fechaHoraGarantia(v) : "—";
  // El VIN que reporta el cajero debe ser el mismo que quedó registrado en la venta
  const vinReportado = String(r.vin || "").toUpperCase();
  const vinDistinto = vinReportado !== "" && s.vin && vinReportado !== String(s.vin).toUpperCase();
  const pendiente = s.estado === "pendiente";

  $("#modalGarantiaContent").innerHTML = `
    <h2 class="modal-title">${t("garTitulo")}</h2>
    <p class="modal-desc">
      <span style="font-family:monospace;letter-spacing:.02em;">${escapeHTML(s.folio)}</span>
      · ${t("garSolicito")}: ${escapeHTML(s.cajero)} · ${fechaHoraGarantia(s.fechaSolicitud)} &nbsp;${estadoGarantiaBadge(s.estado)}
    </p>

    <div class="info-card garantia-bloque">
      <div class="info-card-head">
        <h3>${t("garDatosGarantia")}</h3>
        ${s.vigenteAlSolicitar
          ? `<span class="badge badge-ok"><span class="badge-dot"></span>${t("garVigente")}</span>`
          : `<span class="badge badge-danger"><span class="badge-dot"></span>${t("garNoVigente")}</span>`}
      </div>
      <div class="info-grid">
        ${dato(t("colCliente"), `${texto(s.cliente)}${s.celular || s.email ? `<br><span class="cell-muted" style="font-size:12px;">${escapeHTML([s.celular, s.email].filter(Boolean).join(" · "))}</span>` : ""}`)}
        ${dato(t("colVehiculo"), texto(s.articulo))}
        ${dato(t("garVinRegistrado"), texto(s.vin))}
        ${dato(t("garFolioVenta"), texto(s.folioVenta))}
        ${dato(t("garCompra"), fechaHoraGarantia(s.fechaCompra))}
        ${dato(t("garVence"), fechaHoraGarantia(s.fechaExpiracion))}
      </div>
    </div>

    <div class="info-card garantia-bloque">
      <div class="info-card-head"><h3>${t("garReporte")}</h3></div>
      <div class="info-grid">
        ${dato(t("garPropietario"), texto(r.propietario))}
        ${dato(t("garContacto"), texto(r.contacto))}
        ${dato(t("garVinReportado"), `${texto(vinReportado)}${vinDistinto ? `<br><span class="badge badge-danger" style="margin-top:4px;"><span class="badge-dot"></span>${t("garVinNoCoincide")}</span>` : ""}`)}
        ${dato(t("garPlaca"), texto(r.placa_anio))}
        ${dato(t("garKm"), r.kilometraje ? `${formatoNumero(Number(r.kilometraje))} km` : "—")}
        ${dato(t("garFolioVenta"), texto(r.factura))}
        ${dato(t("garHistorial"), texto(r.historial_servicios))}
        ${dato(t("garFechaFalla"), fechaReporte(r.fecha_falla))}
        ${dato(t("garFechaRecepcion"), fechaReporte(r.fecha_recepcion))}
        ${dato(t("garAsesor"), texto(r.asesor))}
        ${dato(t("garConformidad"), texto(r.conformidad_cliente))}
      </div>
      ${bloque(t("garSintoma"), r.sintoma)}
      ${bloque(t("garCondiciones"), r.condiciones)}
      ${bloque(t("garEvidencia"), r.evidencia)}
    </div>

    ${pendiente ? `
      <div class="form-field" id="garMotivoCampo" hidden>
        <label for="garMotivo">${t("garMotivo")}</label>
        <textarea id="garMotivo" maxlength="500" placeholder="${escapeHTML(t("garMotivoPlaceholder"))}"></textarea>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button>
        <button type="button" class="btn btn-danger" id="btnDenegarGarantia">${t("btnDenegarGarantia")}</button>
        <button type="button" class="btn btn-primary" id="btnAceptarGarantia">${t("btnAceptarGarantia")}</button>
      </div>` : `
      <div class="info-card garantia-bloque">
        <div class="info-grid">
          ${dato(t("garResolvio"), `${texto(s.resolvio)} · ${fechaHoraGarantia(s.fechaResolucion)}`)}
          ${s.estado === "denegada" ? dato(t("garMotivo"), texto(s.motivoRechazo)) : ""}
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button>
      </div>`}`;

  if (pendiente){
    const btnAceptar = $("#btnAceptarGarantia");
    const btnDenegar = $("#btnDenegarGarantia");
    btnAceptar.addEventListener("click", () => {
      if (!confirm(t("confirmAceptarGarantia"))) return;
      resolverGarantia(s, "aceptar", "", [btnAceptar, btnDenegar]);
    });
    // Primer clic: pide el motivo; segundo clic: deniega (el motivo es obligatorio)
    btnDenegar.addEventListener("click", () => {
      const campo = $("#garMotivoCampo");
      if (campo.hidden){
        campo.hidden = false;
        btnDenegar.textContent = t("btnConfirmarDenegar");
        $("#garMotivo").focus();
        return;
      }
      const motivo = $("#garMotivo").value.trim();
      if (!motivo){ toast(t("garMotivoRequerido"), "err"); $("#garMotivo").focus(); return; }
      resolverGarantia(s, "denegar", motivo, [btnAceptar, btnDenegar]);
    });
  }
  abrirModal("modalGarantia");
}

// Envía la decisión del gerente; el cajero recibe el aviso (aceptada) o ve el motivo en Garantías (denegada)
async function resolverGarantia(s, decision, motivo, botones){
  botones.forEach(b => b.disabled = true);
  try {
    await DB.resolverSolicitudGarantia(s.id, decision, motivo);
    toast(`${s.folio} · ${t(decision === "aceptar" ? "toastGarantiaAceptada" : "toastGarantiaDenegada")}`, "ok");
    cerrarModales();
    await cargarSolicitudesGarantia();
    renderMain();
  } catch (err) {
    toast(err.message, "err");
    botones.forEach(b => b.disabled = false);
  }
}

// Carga las solicitudes de la sede y actualiza el contador de la pestaña Notificaciones
async function cargarSolicitudesGarantia(){
  if (!state.esGerente) return;
  try {
    state.solicitudesGarantia = await DB.getSolicitudesGarantia();
    state.errorGarantias = "";
  } catch (err) {
    console.error("Error cargando solicitudes de garantía", err);
    state.errorGarantias = err.message;
  }
  const pendientes = state.solicitudesGarantia.filter(s => s.estado === "pendiente").length;
  const badge = $("#notifBadge");
  if (badge){ badge.textContent = pendientes; badge.hidden = pendientes === 0; }
}

// Revisa cada minuto si llegaron solicitudes nuevas desde caja
async function vigilarSolicitudesGarantia(){
  const antes = new Set(state.solicitudesGarantia.filter(s => s.estado === "pendiente").map(s => s.id));
  await cargarSolicitudesGarantia();
  const nuevas = state.solicitudesGarantia.some(s => s.estado === "pendiente" && !antes.has(s.id));
  if (nuevas) toast(t("notifNuevas"), "ok");
  // Redibuja la pestaña solo si está abierta y no hay un modal en uso
  if (state.view === "notificaciones" && !$(".modal-overlay.is-open")) renderMain();
}

/* ==========================================================================
   MODAL: PRODUCTO (alta / edición)
   ========================================================================== */
function abrirModalProducto(id){
  const prod = id ? state.productos.find(p => p.id === id) : null;
  const isNew = !prod;
  $("#modalProductoContent").innerHTML = `
    <h2 class="modal-title" data-i18n="${isNew?"formProductoNewTitle":"formProductoEditTitle"}">${t(isNew?"formProductoNewTitle":"formProductoEditTitle")}</h2>
    <p class="modal-desc" data-i18n="formProductoDesc">${t("formProductoDesc")}</p>
    <form id="formProducto" autocomplete="off">
      <div class="form-grid">
        <div class="form-field span-2">
          <label data-i18n="fTipo">${t("fTipo")}</label>
          <div class="segmented">
            ${[["vehiculo","tipoVehiculo"],["moto","tipoMoto"],["refaccion","tipoRefaccion"]].map(([v,k])=>
              `<button type="button" class="segmented-btn ${(prod?.tipo||"vehiculo")===v?"is-active":""}" data-tipo="${v}">${t(k)}</button>`
            ).join("")}
          </div>
          <input type="hidden" id="fTipo" value="${escapeHTML(prod?.tipo||"vehiculo")}">
        </div>
        <div class="form-field">
          <label for="fMarca" data-i18n="fMarca">${t("fMarca")}</label>
          <input type="text" id="fMarca" value="${escapeHTML(prod?.marca||"")}" required>
        </div>
        <div class="form-field">
          <label for="fModelo" data-i18n="fModelo">${t("fModelo")}</label>
          <input type="text" id="fModelo" value="${escapeHTML(prod?.nombre||"")}" required>
        </div>
        <div class="form-field">
          <label for="fCategoria" data-i18n="fCategoria">${t("fCategoria")}</label>
          <select id="fCategoria">
            ${state.categorias.map(c =>
              `<option value="${c.id}" ${c.nombre === prod?.categoria ? "selected" : ""}>${escapeHTML(c.nombre)}</option>`
            ).join("")}
          </select>
        </div>
        <div class="form-field">
          <label for="fPrecio" data-i18n="fPrecio">${t("fPrecio")}</label>
          <input type="number" id="fPrecio" min="0" value="${prod?.precio||""}" required>
        </div>
        <div class="form-field">
          <label for="fStockInicial" data-i18n="fStockInicial">${t("fStockInicial")}</label>
          <input type="number" id="fStockInicial" min="0" value="${prod?.stockActual??0}">
        </div>
        <div class="form-field">
          <label for="fStockMin" data-i18n="fStockMin">${t("fStockMin")}</label>
          <input type="number" id="fStockMin" min="0" value="${prod?.stockMinimo??2}">
        </div>
        <div class="form-field span-2">
          <label for="fDescripcion" data-i18n="fDescripcion">${t("fDescripcion")}</label>
          <textarea id="fDescripcion" rows="2">${escapeHTML(prod?.descripcion||"")}</textarea>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal data-i18n="cancel">${t("cancel")}</button>
        <button type="submit" class="btn btn-primary" data-i18n="${isNew?"save":"saveChanges"}">${t(isNew?"save":"saveChanges")}</button>
      </div>
    </form>`;

  // Segmented tipo
  $$(".segmented-btn", $("#modalProductoContent")).forEach(btn => {
    btn.addEventListener("click", () => {
      $$(".segmented-btn", $("#modalProductoContent")).forEach(b => b.classList.remove("is-active"));
      btn.classList.add("is-active");
      $("#fTipo").value = btn.dataset.tipo;
    });
  });

  // Submit
  $("#formProducto").addEventListener("submit", async e => {
    e.preventDefault();
    const payload = {
      tipo:        $("#fTipo").value,
      marca:       $("#fMarca").value.trim(),
      nombre:      $("#fModelo").value.trim(),
      idCategoria: $("#fCategoria").value,
      precio:      parseFloat($("#fPrecio").value),
      stockActual: parseInt($("#fStockInicial").value)||0,
      stockMinimo: parseInt($("#fStockMin").value)||2,
      descripcion: $("#fDescripcion").value.trim(),
    };
    if (!payload.marca || !payload.nombre || !payload.precio){ toast(t("required"), "err"); return; }
    try {
      if (isNew){
        await DB.createProducto(payload);
        toast(t("toastProductoCreated"), "ok");
      } else {
        await DB.updateProducto(id, payload);
        toast(t("toastProductoUpdated"), "ok");
      }
      state.productos = await DB.getProductos();
      cerrarModales();
      renderMain();
    } catch (err) {
      console.error(err);
      toast(t("errSaveProducto"), "err");
    }
  });

  abrirModal("modalProducto");
}

/* ==========================================================================
   MODAL: STOCK (ajuste de existencias)
   ========================================================================== */
function abrirModalStock(productoId){
  const prod = state.productos.find(p => p.id === productoId);
  if (!prod) return;
  let nuevoStock = prod.stockActual;

  const render = () => {
    $("#stockAdjustVal").textContent = nuevoStock;
    $("#stockAdjustVal").style.color = nuevoStock < prod.stockMinimo ? "var(--red)" : nuevoStock === 0 ? "var(--red)" : "var(--text-main)";
  };

  $("#modalStockContent").innerHTML = `
    <h2 class="modal-title" data-i18n="modalStockTitle">${t("modalStockTitle")}</h2>
    <p class="modal-desc">${escapeHTML(prod.nombre)} · ${escapeHTML(prod.marca)}</p>
    <div class="stock-current-row">
      <span class="stock-current-label" data-i18n="stockCurrentLabel">${t("stockCurrentLabel")}</span>
      <span class="stock-current-val">${prod.stockActual}</span>
    </div>
    <div class="form-field" style="margin-bottom:12px;">
      <label data-i18n="motivo">${t("motivo")}</label>
      <select id="fMotivo">
        <option value="entrada" data-i18n="motivoEntrada">${t("motivoEntrada")}</option>
        <option value="salida"  data-i18n="motivoSalida">${t("motivoSalida")}</option>
        <option value="inventario" data-i18n="motivoInventario">${t("motivoInventario")}</option>
        <option value="otro"    data-i18n="motivoOtro">${t("motivoOtro")}</option>
      </select>
    </div>
    <div class="form-field" style="margin-bottom:8px;">
      <label data-i18n="newStockLabel">${t("newStockLabel")}</label>
    </div>
    <div class="stock-adjust">
      <button class="stock-adjust-btn" id="btnDecStock">−</button>
      <span class="stock-adjust-val" id="stockAdjustVal">${nuevoStock}</span>
      <button class="stock-adjust-btn" id="btnIncStock">+</button>
    </div>
    <div class="form-actions">
      <button type="button" class="btn btn-ghost" data-close-modal data-i18n="cancel">${t("cancel")}</button>
      <button type="button" class="btn btn-primary" id="btnGuardarStock" data-i18n="saveChanges">${t("saveChanges")}</button>
    </div>`;

  $("#btnDecStock").addEventListener("click", () => { nuevoStock = Math.max(0, nuevoStock - 1); render(); });
  $("#btnIncStock").addEventListener("click", () => { nuevoStock += 1; render(); });
  $("#btnGuardarStock").addEventListener("click", async () => {
    await DB.updateStock(productoId, nuevoStock);
    state.productos = await DB.getProductos();
    toast(t("toastStockUpdated"), "ok");
    cerrarModales();
    renderMain();
  });

  abrirModal("modalStock");
}

/* ==========================================================================
   MODAL: CAJA (alta)
   ========================================================================== */
function abrirModalCaja(){
  $("#modalCajaContent").innerHTML = `
    <h2 class="modal-title" data-i18n="formCajaNewTitle">${t("formCajaNewTitle")}</h2>
    <p class="modal-desc" data-i18n="formCajaDesc">${t("formCajaDesc")}</p>
    <form id="formCaja" autocomplete="off">
      <div class="form-grid cols-1">
        <div class="form-field">
          <label for="fNumeroCaja" data-i18n="fNombreCaja">${t("fNombreCaja")}</label>
          <input type="number" id="fNumeroCaja" min="1" step="1" placeholder="${t("placeholderCaja")}" required>
        </div>
        <div class="form-field">
          <label for="fCajeroAsignado" data-i18n="fCajeroAsignado">${t("fCajeroAsignado")}</label>
          <select id="fCajeroAsignado">
            <option value="">${t("unassigned")}</option>
            ${state.cajeros.map(c => `<option value="${c.id}">${escapeHTML(c.nombre)}</option>`).join("")}
          </select>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal data-i18n="cancel">${t("cancel")}</button>
        <button type="submit" class="btn btn-primary" data-i18n="save">${t("save")}</button>
      </div>
    </form>`;

  $("#formCaja").addEventListener("submit", async e => {
    e.preventDefault();
    const numero = parseInt($("#fNumeroCaja").value, 10);
    if (!(numero > 0)){ toast(t("required"), "err"); return; }
    try {
      await DB.createCaja({ numero, cajeroId: $("#fCajeroAsignado").value || null });
      state.cajas = await DB.getCajas();
      toast(t("toastCajaCreated"), "ok");
      cerrarModales();
      renderMain();
    } catch (err) {
      console.error(err);
      toast(err.message, "err");
    }
  });

  abrirModal("modalCaja");
}

function abrirModalAsignarCajero(cajaId){
  const caja = state.cajas.find(c => c.id === cajaId);
  if (!caja) return;

  $("#modalCajaContent").innerHTML = `
    <h2 class="modal-title">${t("assignCajero")}</h2>
    <p class="modal-desc">${escapeHTML(caja.nombre)}</p>
    <form id="formAsignarCajero" autocomplete="off">
      <div class="form-grid cols-1">
        <div class="form-field">
          <label for="fCajeroAsignado" data-i18n="fCajeroAsignado">${t("fCajeroAsignado")}</label>
          <select id="fCajeroAsignado">
            <option value="">${t("unassigned")}</option>
            ${state.cajeros.map(c => `<option value="${c.id}" ${c.id === caja.cajeroId ? "selected" : ""}>${escapeHTML(c.nombre)}</option>`).join("")}
          </select>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal data-i18n="cancel">${t("cancel")}</button>
        <button type="submit" class="btn btn-primary" data-i18n="save">${t("save")}</button>
      </div>
    </form>`;

  $("#formAsignarCajero").addEventListener("submit", async e => {
    e.preventDefault();
    try {
      await DB.asignarCajero(cajaId, $("#fCajeroAsignado").value || null);
      state.cajas = await DB.getCajas();
      toast(t("toastCajaAsignada"), "ok");
      cerrarModales();
      renderMain();
    } catch (err) {
      console.error(err);
      toast(err.message, "err");
    }
  });

  abrirModal("modalCaja");
}
/* ==========================================================================
   MODAL: DETALLE DE VENTA
   ========================================================================== */
function abrirModalVenta(ventaId){
  const v = state.ventas.find(x => x.id === ventaId);
  if (!v) return;
  $("#modalVentaContent").innerHTML = `
    <h2 class="modal-title" data-i18n="modalVentaTitle">${t("modalVentaTitle")}</h2>
    <p class="modal-desc" style="font-family:monospace;letter-spacing:.02em;">${escapeHTML(v.id)}</p>
    <div class="info-grid" style="margin-bottom:20px;">
      <div class="info-item"><span class="info-item-label">${t("date")}</span><span class="info-item-value">${formatFecha(v.fecha)}</span></div>
      <div class="info-item"><span class="info-item-label">${t("time")}</span><span class="info-item-value">${formatHora(v.fecha)}</span></div>
      <div class="info-item"><span class="info-item-label">${t("colCajero")}</span><span class="info-item-value">${escapeHTML(v.cajeroNombre)}</span></div>
      <div class="info-item"><span class="info-item-label">${t("colMetodo")}</span><span class="info-item-value">${metodoBadge(v.metodoPago)}</span></div>
    </div>
    <div class="table-wrap" style="margin-bottom:20px;">
      <table class="data-table">
        <thead><tr><th>${t("colProducto")}</th><th>${t("colMarca")}</th><th>${t("colCant")}</th><th>${t("colTotal")}</th></tr></thead>
        <tbody>
          <tr>
            <td><strong>${escapeHTML(v.productoNombre)}</strong></td>
            <td>${escapeHTML(v.marca)}</td>
            <td>${v.cantidad || 1}</td>
            <td style="font-weight:700;">${formatoMoneda(v.total)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:baseline;padding:16px;background:var(--surface-1);border-radius:var(--radius-md);border:1px solid var(--line);">
      <span style="font-size:13px;color:var(--text-muted);">${t("saleTotal")}</span>
      <span style="font-family:var(--font-display);font-size:24px;font-weight:600;">${formatoMoneda(v.total)}</span>
    </div>
    <div class="form-actions">
      <button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button>
    </div>`;

  abrirModal("modalVenta");
}

/* ==========================================================================
   ACCIONES SOBRE PRODUCTOS
   ========================================================================== */
async function eliminarProducto(id){
  if (!confirm(t("confirmDelete"))) return;
  try {
    await DB.deleteProducto(id);
    state.productos = await DB.getProductos();
    toast(t("toastProductoDeleted"), "ok");
    renderMain();
  } catch (err) {
    console.error(err);
    toast(t("errDeleteProducto"), "err");
  }
}

/* ==========================================================================
   GESTIÓN DE MODALES
   ========================================================================== */
function abrirModal(id){
  const overlay = $(`#${id}`);
  if (overlay) overlay.classList.add("is-open");
}
function cerrarModales(){
  $$(".modal-overlay.is-open").forEach(m => m.classList.remove("is-open"));
}

/* ==========================================================================
   TOASTS
   ========================================================================== */
function toast(msg, tipo = "ok"){
  const stack = $("#toastStack");
  const el = document.createElement("div");
  el.className = `toast toast-${tipo}`;
  el.innerHTML = `
    <span class="toast-icon">
      ${tipo === "ok"
        ? `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 6L9 17l-5-5"/></svg>`
        : `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 6L6 18M6 6l12 12"/></svg>`}
    </span>
    <span>${escapeHTML(msg)}</span>`;
  stack.appendChild(el);
  setTimeout(() => { el.classList.add("is-leaving"); el.addEventListener("animationend", () => el.remove()); }, 3200);
}

/* ==========================================================================
   I18N — aplicar traducciones al DOM estático (topbar, footer)
   ========================================================================== */
function applyI18n(){
  $$("[data-i18n]").forEach(el => {
    const key = el.dataset.i18n;
    if (key) el.textContent = t(key);
  });
  $$("[data-i18n-title]").forEach(el => {
    const key = el.dataset.i18nTitle;
    if (key) el.title = t(key);
  });
  // Interruptor de idioma (marcado = inglés), igual que en el Home
  const swIdioma = $("#langSwitch");
  if (swIdioma) swIdioma.checked = (state.lang === "en");
}

/* ==========================================================================
   RELOJ EN TIEMPO REAL
   ========================================================================== */
function iniciarReloj(){
  function tick(){
    const now = new Date();
    const fechaEl = $("#statusFecha");
    const horaEl  = $("#statusHora");
    if (fechaEl) fechaEl.textContent = now.toLocaleDateString(state.lang==="es"?"es-MX":"en-US", { weekday:"short", day:"2-digit", month:"short", year:"numeric" });
    if (horaEl)  horaEl.textContent  = now.toLocaleTimeString(state.lang==="es"?"es-MX":"en-US", { hour:"2-digit", minute:"2-digit", second:"2-digit" });
  }
  tick();
  setInterval(tick, 1000);
}

/* ==========================================================================
   EVENTOS GLOBALES
   ========================================================================== */
function attachEvents(){
  // Navegación por pestañas
  $$("#subNav .sub-nav-btn").forEach(btn => {
    btn.addEventListener("click", () => { state.view = btn.dataset.view; renderMain(); });
  });

  // El logo KARMA es un enlace normal a home.html (no necesita JavaScript)

  // Interruptor de idioma (marcado = inglés)
  $("#langSwitch")?.addEventListener("change", e => {
    state.lang = e.target.checked ? "en" : "es";
    localStorage.setItem("karma_idioma", state.lang);
    renderMain();
  });

  // Interruptor de tema (marcado = oscuro). Se recuerda al recargar y se comparte con el Home
  $("#themeSwitch")?.addEventListener("change", e => {
    document.body.classList.toggle("dark", e.target.checked);
    localStorage.setItem("karma_tema", e.target.checked ? "dark" : "light");
    if (state.view === "dashboard") renderMain();   // redibuja las gráficas con los colores del tema
  });

  // Menú de perfil (igual que en el Home)
  const perfil = $("#profileDropdown");
  const perfilBtn = $("#profileTrigger");
  perfilBtn?.addEventListener("click", e => {
    e.stopPropagation();
    const abierto = perfil.classList.toggle("open");
    perfilBtn.setAttribute("aria-expanded", String(abierto));
  });
  document.addEventListener("click", e => {
    if (!e.target.closest(".profile-dropdown-container")) {
      perfil?.classList.remove("open");
      perfilBtn?.setAttribute("aria-expanded", "false");
    }
  });

  // Cerrar sesión
  $("#logoutBtn")?.addEventListener("click", () => {
    if (!confirm(t("confirmLogout"))) return;
    // Igual que el Home: borra el usuario guardado y cierra la sesión PHP del Punto de Venta
    localStorage.removeItem("karma_user");
    fetch("../PHP/PuntoDeVenta/api.php?action=logout").finally(() => {
      window.location.replace("../index.html");
    });
  });

  // Cerrar modales: botones con data-close-modal o clic en overlay
  document.addEventListener("click", e => {
    if (e.target.closest("[data-close-modal]")) cerrarModales();
    if (e.target.classList.contains("modal-overlay")) cerrarModales();
  });

  // Cerrar modales con Escape
  document.addEventListener("keydown", e => {
    if (e.key === "Escape") {
      cerrarModales();
      perfil?.classList.remove("open");
      perfilBtn?.setAttribute("aria-expanded", "false");
    }
  });
}

/* ==========================================================================
   INICIO
   ========================================================================== */
(async function init(){
  if (!verificarAcceso()) return;
  if (localStorage.getItem("karma_tema") === "dark") document.body.classList.add("dark");
  const swTema = $("#themeSwitch");
  if (swTema) swTema.checked = document.body.classList.contains("dark");
  const swIdioma = $("#langSwitch");
  if (swIdioma) swIdioma.checked = (state.lang === "en");
  let usuario = null;
  try { usuario = JSON.parse(localStorage.getItem("karma_user") || "null"); } catch (e) {}
  const nombreMenu = $("#navUserName");
  if (nombreMenu && usuario && usuario.nombre) nombreMenu.textContent = usuario.nombre;
  // Notificaciones de garantía: exclusivas de las cuentas Gerente (el servidor también lo exige)
  state.esGerente = usuario?.rol === "Gerente";
  const navNotificaciones = $("#navNotificaciones");
  if (navNotificaciones) navNotificaciones.hidden = !state.esGerente;
  attachEvents();
  iniciarReloj();
  await Promise.all([cargarDatos(), cargarSolicitudesGarantia()]);
  renderMain();
  if (state.esGerente) setInterval(vigilarSolicitudesGarantia, 60000);
})();