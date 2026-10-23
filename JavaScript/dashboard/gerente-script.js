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

/*I18N — diccionario bilingüe ES / EN */
const I18N = {
  es:{
    topHome:"Ir al Dashboard", brandSlogan:"Panel de Gerencia",
    logout:"Cerrar sesión", role:"Rol", roleGerente:"Gerente de Sede",
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
    hintDB:"Vista conectada a DB (mock) — lista para apuntar a tu API real.",
    critical:"Crítico", low:"Bajo", ok:"Suficiente",

    /* Cajas */
    cajasTitle:"Gestión de cajas", cajasSub:"Puntos de cobro activos e inactivos de tu sucursal",
    newCaja:"Nueva caja", colCaja:"Caja", colCajero:"Cajero asignado", colEstado:"Estado",
    formCajaNewTitle:"Registrar caja", formCajaDesc:"Asigna un nombre y cajero a la nueva caja.",
    fNombreCaja:"Nombre / número de caja", fCajeroAsignado:"Cajero asignado",
    statusActive:"Activa", statusInactive:"Inactiva",
    deactivate:"Desactivar", activate:"Activar",
    toastCajaCreated:"Caja registrada correctamente",
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
  },
  en:{
    topHome:"Go to Dashboard", brandSlogan:"Store Management Panel",
    logout:"Log out", role:"Role", roleGerente:"Store Manager",
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
    hintDB:"View connected to DB (mock) — ready to point to your real API.",
    critical:"Critical", low:"Low", ok:"Sufficient",

    cajasTitle:"Register management", cajasSub:"Active and inactive checkout points at your branch",
    newCaja:"New register", colCaja:"Register", colCajero:"Assigned cashier", colEstado:"Status",
    formCajaNewTitle:"Register checkout", formCajaDesc:"Assign a name and cashier to the new register.",
    fNombreCaja:"Register name / number", fCajeroAsignado:"Assigned cashier",
    statusActive:"Active", statusInactive:"Inactive",
    deactivate:"Deactivate", activate:"Activate",
    toastCajaCreated:"Register created successfully",
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
const API_BASE = "/api";

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

const DB = {
  async getSucursal(){
    // PROD: return (await fetch(`${API_BASE}/sucursales/${SUCURSAL_ID}`)).json();
    await delay(60);
    return { ...SEED.sucursal };
  },
  async getCajeros(){
    // PROD: return (await fetch(`${API_BASE}/sucursales/${SUCURSAL_ID}/cajeros`)).json();
    await delay(60);
    return SEED.cajeros.map(c => ({ ...c }));
  },
  async getCajas(){
    // PROD: return (await fetch(`${API_BASE}/sucursales/${SUCURSAL_ID}/cajas`)).json();
    await delay(70);
    return SEED.cajas.map(c => ({ ...c }));
  },
  async createCaja(payload){
    // PROD: return (await fetch(`${API_BASE}/cajas`, { method:"POST", body:JSON.stringify(payload) })).json();
    await delay(120);
    const nueva = { id: uid("c"), estado:"activo", ...payload };
    SEED.cajas.push(nueva);
    return nueva;
  },
  async setCajaEstado(id, estado){
    await delay(100);
    const c = SEED.cajas.find(x => x.id === id);
    if (c) c.estado = estado;
    return c;
  },
  async deleteCaja(id){
    await delay(100);
    const idx = SEED.cajas.findIndex(x => x.id === id);
    if (idx > -1) SEED.cajas.splice(idx, 1);
    return true;
  },
  async getProductos(){
    // PROD: return (await fetch(`${API_BASE}/sucursales/${SUCURSAL_ID}/productos`)).json();
    await delay(80);
    return SEED.productos.map(p => ({ ...p }));
  },
  async createProducto(payload){
    // PROD: return (await fetch(`${API_BASE}/productos`, { method:"POST", body:JSON.stringify(payload) })).json();
    await delay(130);
    const nuevo = { id: uid("p"), ...payload };
    SEED.productos.push(nuevo);
    return nuevo;
  },
  async updateProducto(id, payload){
    // PROD: return (await fetch(`${API_BASE}/productos/${id}`, { method:"PATCH", body:JSON.stringify(payload) })).json();
    await delay(120);
    const idx = SEED.productos.findIndex(p => p.id === id);
    if (idx > -1) SEED.productos[idx] = { ...SEED.productos[idx], ...payload };
    return SEED.productos[idx];
  },
  async deleteProducto(id){
    // PROD: return (await fetch(`${API_BASE}/productos/${id}`, { method:"DELETE" })).json();
    await delay(110);
    const idx = SEED.productos.findIndex(p => p.id === id);
    if (idx > -1) SEED.productos.splice(idx, 1);
    return true;
  },
  async updateStock(id, nuevoStock){
    // PROD: return (await fetch(`${API_BASE}/inventario/${id}/stock`, { method:"PATCH", body:JSON.stringify({ stockActual: nuevoStock }) })).json();
    await delay(110);
    const p = SEED.productos.find(x => x.id === id);
    if (p) p.stockActual = nuevoStock;
    return p;
  },
  async getVentas(){
    // PROD: return (await fetch(`${API_BASE}/sucursales/${SUCURSAL_ID}/ventas`)).json();
    await delay(90);
    return SEED.ventas.map(v => ({ ...v }));
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
  ventas: [],
  productosFiltro:"all",  // all | vehiculo | moto | refaccion
  productosQuery:"",
  inventarioFiltro:"all", // all | low | critical
  inventarioQuery:"",
  ventasFiltro:"month",   // today | week | month
  cajasFiltro:"all",      // all | activo | inactivo
  cargando: true,
};
const chartInstances = {};

/* ==========================================================================
   CARGA INICIAL
   ========================================================================== */
async function cargarDatos(){
  state.cargando = true;
  try{
    const [sucursal, cajeros, cajas, productos, ventas] = await Promise.all([
      DB.getSucursal(), DB.getCajeros(), DB.getCajas(), DB.getProductos(), DB.getVentas()
    ]);
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
    main.innerHTML = `<div class="panel panel-full"><div class="empty-state"><strong>Cargando…</strong></div></div>`;
    return;
  }
  $$(".sub-nav-btn").forEach(b => b.classList.toggle("is-active", b.dataset.view === state.view));
  applyI18n();
  if      (state.view === "dashboard")  renderDashboard();
  else if (state.view === "productos")  renderProductos();
  else if (state.view === "inventario") renderInventario();
  else if (state.view === "cajas")      renderCajas();
  else if (state.view === "ventas")     renderVentas();
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
        <div class="kpi-sub"><span>${cajasActivas} de ${state.cajas.length} cajas</span></div>
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
        <div class="info-item"><span class="info-item-label">Nombre</span><span class="info-item-value">${escapeHTML(state.sucursal?.nombre||"")}</span></div>
        <div class="info-item"><span class="info-item-label">Dirección</span><span class="info-item-value">${escapeHTML(state.sucursal?.direccion||"")}</span></div>
        <div class="info-item"><span class="info-item-label">Teléfono</span><span class="info-item-value">${escapeHTML(state.sucursal?.telefono||"")}</span></div>
        <div class="info-item"><span class="info-item-label">Correo</span><span class="info-item-value">${escapeHTML(state.sucursal?.email||"")}</span></div>
        <div class="info-item"><span class="info-item-label">Estado</span><span class="info-item-value">
          ${state.sucursal?.estado === "activo"
            ? `<span class="badge badge-ok"><span class="badge-dot"></span>Activa</span>`
            : `<span class="badge badge-off"><span class="badge-dot"></span>Inactiva</span>`}
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
          { label:t("revenue"), data:ingresos, backgroundColor:"rgba(26,92,58,.75)", borderRadius:6, yAxisID:"y" },
          { label:t("units"),   data:unidades, type:"line", borderColor:"var(--chart-red)", backgroundColor:"rgba(158,27,46,.12)", tension:.4, pointRadius:4, yAxisID:"y1" },
        ]
      },
      options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false } },
        scales:{
          y:{ position:"left", grid:{ color:"var(--chart-grid)" }, ticks:{ callback:v=>formatoMoneda(v) } },
          y1:{ position:"right", grid:{ drawOnChartArea:false }, ticks:{ stepSize:1 } }
        }
      }
    });
  });

  // Gráfica stock
  mountChart("chartStock", () => {
    const cats = Object.keys(stockCat);
    const vals = Object.values(stockCat);
    const palette = ["rgba(26,92,58,.8)","rgba(158,27,46,.75)","rgba(180,121,26,.75)","rgba(62,190,133,.7)","rgba(26,92,58,.45)","rgba(158,27,46,.45)"];
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
          ${lista.length === 0 ? `<tr><td colspan="6"><div class="empty-state"><strong>Sin resultados</strong></div></td></tr>` :
            lista.map(p => `
            <tr>
              <td><strong>${escapeHTML(p.nombre)}</strong><br><span class="cell-muted" style="font-size:11.5px;">${escapeHTML(p.tipo)}</span></td>
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
          ${lista.length === 0 ? `<tr><td colspan="7"><div class="empty-state"><strong>Sin resultados</strong></div></td></tr>` :
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
      ${lista.length === 0 ? `<div class="empty-state"><strong>Sin cajas</strong><span>Registra la primera caja con el botón "Nueva caja".</span></div>` :
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
              <button class="btn-table btn-sm" data-toggle-caja="${escapeHTML(c.id)}" data-estado="${c.estado}">
                ${activa ? t("deactivate") : t("activate")}
              </button>
              <button class="btn-table-danger btn-sm" data-delete-caja="${escapeHTML(c.id)}" data-i18n="delete">Eliminar</button>
            </div>
          </div>`;
        }).join("")}
    </div>
  </div>`;

  $("#btnNuevaCaja")?.addEventListener("click", abrirModalCaja);
  $$("[data-caja-filtro]").forEach(btn => {
    btn.addEventListener("click", () => { state.cajasFiltro = btn.dataset.cajaFiltro; renderCajas(); });
  });
  $$("[data-toggle-caja]").forEach(btn => {
    btn.addEventListener("click", async () => {
      const nuevoEstado = btn.dataset.estado === "activo" ? "inactivo" : "activo";
      await DB.setCajaEstado(btn.dataset.toggleCaja, nuevoEstado);
      state.cajas = await DB.getCajas();
      toast(t("toastCajaStatus"), "ok");
      renderCajas();
    });
  });
  $$("[data-delete-caja]").forEach(btn => {
    btn.addEventListener("click", async () => {
      if (!confirm(t("confirmDeleteCaja"))) return;
      await DB.deleteCaja(btn.dataset.deleteCaja);
      state.cajas = await DB.getCajas();
      toast(t("toastCajaDeleted"), "ok");
      renderCajas();
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
      <span style="font-size:12.5px;color:var(--text-muted);">${lista.length} transacciones</span>
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
            ${["Autos deportivos","SUV de lujo","Motocicletas","Refacciones","Vehículos"].map(c=>
              `<option value="${c}" ${(prod?.categoria||""===c)?"selected":""}>${c}</option>`
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

  // Pre-seleccionar categoría
  if (prod) $("#fCategoria").value = prod.categoria;

  // Submit
  $("#formProducto").addEventListener("submit", async e => {
    e.preventDefault();
    const payload = {
      tipo:        $("#fTipo").value,
      marca:       $("#fMarca").value.trim(),
      nombre:      $("#fModelo").value.trim(),
      categoria:   $("#fCategoria").value,
      precio:      parseFloat($("#fPrecio").value),
      stockActual: parseInt($("#fStockInicial").value)||0,
      stockMinimo: parseInt($("#fStockMin").value)||2,
      descripcion: $("#fDescripcion").value.trim(),
    };
    if (!payload.marca || !payload.nombre || !payload.precio){ toast(t("required"), "err"); return; }
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
          <label for="fNombreCaja" data-i18n="fNombreCaja">${t("fNombreCaja")}</label>
          <input type="text" id="fNombreCaja" placeholder="Ej: Caja 4" required>
        </div>
        <div class="form-field">
          <label for="fCajeroAsignado" data-i18n="fCajeroAsignado">${t("fCajeroAsignado")}</label>
          <select id="fCajeroAsignado">
            <option value="">— Sin asignar —</option>
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
    const nombre = $("#fNombreCaja").value.trim();
    if (!nombre){ toast(t("required"), "err"); return; }
    await DB.createCaja({ nombre, cajeroId: $("#fCajeroAsignado").value || null });
    state.cajas = await DB.getCajas();
    toast(t("toastCajaCreated"), "ok");
    cerrarModales();
    renderMain();
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
      <div class="info-item"><span class="info-item-label">Fecha</span><span class="info-item-value">${formatFecha(v.fecha)}</span></div>
      <div class="info-item"><span class="info-item-label">Hora</span><span class="info-item-value">${formatHora(v.fecha)}</span></div>
      <div class="info-item"><span class="info-item-label">Cajero</span><span class="info-item-value">${escapeHTML(v.cajeroNombre)}</span></div>
      <div class="info-item"><span class="info-item-label">Método</span><span class="info-item-value">${metodoBadge(v.metodoPago)}</span></div>
    </div>
    <div class="table-wrap" style="margin-bottom:20px;">
      <table class="data-table">
        <thead><tr><th>Producto</th><th>Marca</th><th>Cant.</th><th>Total</th></tr></thead>
        <tbody>
          <tr>
            <td><strong>${escapeHTML(v.productoNombre)}</strong></td>
            <td>${escapeHTML(v.marca)}</td>
            <td>1</td>
            <td style="font-weight:700;">${formatoMoneda(v.total)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:baseline;padding:16px;background:var(--surface-1);border-radius:var(--radius-md);border:1px solid var(--line);">
      <span style="font-size:13px;color:var(--text-muted);">Total de la venta</span>
      <span style="font-family:var(--font-display);font-size:24px;font-weight:600;">${formatoMoneda(v.total)}</span>
    </div>
    <div class="form-actions">
      <button type="button" class="btn btn-ghost" data-close-modal>Cerrar</button>
    </div>`;

  abrirModal("modalVenta");
}

/* ==========================================================================
   ACCIONES SOBRE PRODUCTOS
   ========================================================================== */
async function eliminarProducto(id){
  if (!confirm(t("confirmDelete"))) return;
  await DB.deleteProducto(id);
  state.productos = await DB.getProductos();
  toast(t("toastProductoDeleted"), "ok");
  renderMain();
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
  // Actualizar botón de idioma
  $$(".lang-op").forEach(op => op.classList.toggle("is-active", op.dataset.lang === state.lang));
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

  // Logo → Dashboard
  $("#logoHome")?.addEventListener("click", () => { state.view = "dashboard"; renderMain(); });

  // Cambio de idioma
  $("#langToggle")?.addEventListener("click", e => {
    const op = e.target.closest(".lang-op");
    if (!op) return;
    state.lang = op.dataset.lang;
    localStorage.setItem("karma_idioma", state.lang);
    renderMain();
  });

  // Tema claro / oscuro
  $("#themeToggle")?.addEventListener("click", () => {
    const oscuro = document.body.classList.toggle("dark");
    localStorage.setItem("karma_tema", oscuro ? "dark" : "light"); // tema compartido con los demás módulos
  });

  // Cerrar sesión
  $("#logoutBtn")?.addEventListener("click", () => {
    if (!confirm("¿Cerrar sesión?")) return;
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
    if (e.key === "Escape") cerrarModales();
  });
}

/* ==========================================================================
   INICIO
   ========================================================================== */
(async function init(){
  attachEvents();
  iniciarReloj();
  await cargarDatos();
  renderMain();
})();
