/* ==========================================================================
   KARMA · Punto de Venta — Panel de Administrador General
   admin-script.js

   NOTA PARA CONECTAR A UNA BASE DE DATOS REAL
   -----------------------------------------------------------------------
   Todo el acceso a datos pasa por el objeto `DB` (ver más abajo). Cada
   método de `DB` hoy resuelve con datos de ejemplo (seed) guardados en
   memoria, simulando una llamada asíncrona. Para conectar un backend
   real basta con reemplazar el cuerpo de cada método por un `fetch()`
   a tu API (los comentarios "PROD:" muestran el endpoint sugerido) y
   dejar la firma (parámetros / forma del objeto que regresa) igual, ya
   que el resto de la aplicación sólo depende de esa forma de datos.
   ========================================================================== */

/* ==========================================================================
   UTILIDADES
   ========================================================================== */
const $  = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));

function formatoMoneda(n){
  return new Intl.NumberFormat("es-MX", { style:"currency", currency:"MXN", maximumFractionDigits:0 }).format(n || 0);
}
function formatoNumero(n){
  return new Intl.NumberFormat("es-MX").format(n || 0);
}
function escapeHTML(str){
  return String(str ?? "").replace(/[&<>"']/g, s => ({ "&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;", "'":"&#39;" }[s]));
}
function delay(ms){ return new Promise(res => setTimeout(res, ms)); }
function uid(prefix){ return prefix + "_" + Math.random().toString(36).slice(2, 9); }
function iniciales(nombre){
  return (nombre || "").split(" ").filter(Boolean).slice(0,2).map(p => p[0].toUpperCase()).join("");
}

/* ==========================================================================
   I18N — diccionario bilingüe ES / EN
   ========================================================================== */
const I18N = {
  es:{
    topHome:"Ir al Dashboard", brandSlogan:"Panel de Administración General",
    allBranches:"Todas las sucursales", logout:"Cerrar sesión", role:"Rol", roleAdmin:"Administrador General",
    navDashboard:"Dashboard", navSucursales:"Sucursales", navPersonal:"Personal", navInventario:"Inventario",
    syncOk:"Datos en vivo", syncOff:"Sin conexión a BD",
    date:"Fecha", time:"Hora", admin:"Administrador", session:"Sesión", active:"Activa",
    period:"Periodo", thisMonth:"Este mes", lastMonth:"Mes anterior", last6:"Últimos 6 meses", allTime:"Histórico",
    kpiVentas:"Ventas totales del periodo", kpiInventario:"Volumen total de inventario",
    kpiSucursales:"Sucursales activas", kpiPersonal:"Usuarios / gerentes registrados",
    vsLastMonth:"vs. mes anterior", unitsInStock:"unidades en existencia", ofTotalBranches:"de {n} sucursales totales",
    registeredUsers:"personal registrado en total",
    chartMonthly:"Rendimiento mensual de ventas", chartMonthlySub:"Ingresos y unidades vendidas",
    revenue:"Ingresos", units:"Unidades",
    chartInventory:"Inventario global por categoría", chartInventorySub:"Distribución de existencias",
    chartByProduct:"Ventas por marca / producto", chartByProductSub:"Líneas más vendidas en toda la empresa",
    recentSales:"Historial de ventas recientes", recentSalesSub:"Últimas transacciones registradas",
    colFecha:"Fecha / hora", colSucursal:"Sucursal", colResponsable:"Cajero / cliente", colProductos:"Producto(s)", colTotal:"Total",
    criticalStock:"Monitor de stock crítico", criticalStockSub:"Existencias en o por debajo del mínimo",
    criticalEmpty:"Sin alertas de stock crítico en este momento.",
    quickTitle:"Accesos rápidos",
    qaSucursal:"Nueva sucursal", qaSucursalSub:"Registrar sede", qaArticulo:"Nuevo vehículo / artículo", qaArticuloSub:"Alta de inventario",
    qaPersonal:"Manage Staff", qaPersonalSub:"Ir a personal", qaHistorial:"Historial de transacciones", qaHistorialSub:"Ver ventas consolidadas",
    sucursalesTitle:"Sucursales", sucursalesSub:"Gestión centralizada de sedes (alta, edición y baja)",
    newSucursal:"Nueva sucursal", filterAll:"Todas", filterActive:"Activas", filterInactive:"Inactivas",
    colNombre:"Nombre", colDireccion:"Dirección", colTelefono:"Teléfono", colGerente:"Gerente a cargo",
    colCajas:"Cajas activas", colEstado:"Estado", colAcciones:"Acciones", edit:"Editar", deactivate:"Desactivar", activate:"Activar",
    noGerente:"Sin asignar",
    formSucursalNewTitle:"Registrar nueva sucursal", formSucursalEditTitle:"Editar sucursal",
    formSucursalDesc:"Los campos marcados son obligatorios. El estatus controla si la sede puede operar ventas.",
    fName:"Nombre de la sucursal", fAddress:"Dirección", fPhone:"Teléfono", fEmail:"Correo de contacto",
    fManager:"Gerente a cargo", fCashiers:"Cajas activas", fStatus:"Estatus",
    statusActive:"Activo", statusInactive:"Inactivo", save:"Guardar", cancel:"Cancelar", saveChanges:"Guardar cambios",
    toastSucursalCreated:"Sucursal registrada correctamente", toastSucursalUpdated:"Sucursal actualizada",
    toastSucursalStatus:"Estatus de sucursal actualizado",
    personalTitle:"Personal", personalSub:"Directorio y asignación de personal por rol y sucursal",
    newGerente:"Nuevo gerente", filterAllRoles:"Todos", roleAdminF:"Administrador", roleGerenteF:"Gerente", roleCajeroF:"Cajero",
    colUsuario:"Usuario", colRol:"Rol", colSucursalAsig:"Sucursal asignada",
    formPersonalTitle:"Registrar gerente de sede", formPersonalEditTitle:"Editar usuario",
    formPersonalDesc:"La contraseña se almacena únicamente como password_hash en el servidor; nunca en texto plano.",
    fFullName:"Nombre completo", fEmailUser:"Correo electrónico", fPassword:"Contraseña", fRole:"Rol",
    fAssignedBranch:"Sucursal asignada", passwordHint:"Se encriptará antes de guardarse (password_hash).",
    inventarioTitle:"Inventario · Auditoría multi-sede", inventarioSub:"Consulta de existencias de cualquier producto en cada sucursal",
    searchProduct:"Buscar producto, marca o categoría…", colProducto:"Producto", colCategoria:"Categoría",
    colStockActual:"Stock actual", colStockMinimo:"Stock mínimo", colPrecio:"Precio",
    noResults:"Sin resultados", noResultsSub:"No se encontraron artículos que coincidan con tu búsqueda.",
    startSearch:"Escribe para buscar", startSearchSub:"Consulta el stock de cualquier producto a través de todas las sucursales.",
    critical:"Crítico", ok:"Suficiente", low:"Bajo",
    hintDB:"Vista conectada a DB (mock) — lista para apuntar a tu API real vía DB.*",
    formArticuloTitle:"Alta rápida de artículo", formArticuloDesc:"Registra un vehículo o refacción y asígnalo a una sucursal.",
    fTipo:"Tipo", tipoVehiculo:"Vehículo", tipoRefaccion:"Refacción", fMarca:"Marca", fModelo:"Modelo / nombre",
    fCategoria:"Categoría", fBranch:"Sucursal", fStockInicial:"Stock inicial", fStockMin:"Stock mínimo", fPrecioVenta:"Precio de venta",
    toastArticuloCreated:"Artículo registrado en inventario", toastUsuarioCreated:"Usuario registrado correctamente",
    toastUsuarioUpdated:"Usuario actualizado", required:"Este campo es obligatorio",
    stockDetailTitle:"Existencias por sucursal", stockDetailSub:"Distribución del producto seleccionado en toda la red",
    close:"Cerrar", totalNetwork:"Total en la red",

    navPedidos:"Pedidos", qaPedido:"Nuevo pedido", qaPedidoSub:"Orden a proveedor",
    pedidosTitle:"Pedidos a proveedores", pedidosSub:"Control de órdenes de compra y llegada de unidades a cada sucursal",
    newPedido:"Nuevo pedido", colFolio:"Folio", colProveedor:"Proveedor", colDestino:"Sucursal destino",
    colVehiculos:"Vehículo(s)", colETA:"ETA", colEmision:"Emisión", colRecepcion:"Recepción",
    estAll:"Todos", estSolicitado:"Solicitado", estTransito:"En tránsito", estPatio:"En patio / aduana",
    estRecibido:"Recibido", estCancelado:"Cancelado",
    viewDetail:"Ver detalle", advance:"Avanzar", confirmReception:"Confirmar recepción", cancelOrder:"Cancelar pedido",
    formPedidoNewTitle:"Registrar nuevo pedido", formPedidoEditTitle:"Editar pedido",
    formPedidoDesc:"Captura la orden de compra y el detalle de cada unidad incluida en el lote.",
    fFolio:"Folio de orden", fProveedor:"Proveedor / ensambladora", fDestino:"Sucursal de destino",
    fFechaEmision:"Fecha de emisión", fFechaETA:"Fecha estimada de arribo (ETA)",
    vehiculosSectionTitle:"Vehículos del pedido", addVehiculo:"Agregar vehículo", vehiculoN:"Vehículo",
    fModeloV:"Modelo", fAnio:"Año", fVersion:"Versión", fVin:"VIN / N.º de chasis",
    fColorExt:"Color exterior", fColorInt:"Color interior", fEquipamiento:"Equipamiento base",
    fCostoAdq:"Costo de adquisición", fPrecioProyectado:"Precio proyectado de venta",
    toastPedidoCreated:"Pedido registrado correctamente", toastPedidoUpdated:"Pedido actualizado",
    toastPedidoAdvanced:"Estado del pedido actualizado", toastPedidoCancelled:"Pedido cancelado",
    toastStockUpdated:"Recepción confirmada: stock_actual actualizado en {n} artículo(s) de {sucursal}",
    pedidoDetailTitle:"Detalle del pedido", pipelineSub:"Seguimiento del ciclo de vida de la orden",
    dbImpactTitle:"Impacto automatizado en base de datos", dbImpactDesc:"Al confirmar la recepción, el sistema incrementa automáticamente stock_actual en la tabla inventarios de la sucursal receptora, por cada unidad del pedido.",
    unitCost:"Costo unitario", projectedPrice:"Precio proyectado", noPedidos:"Aún no hay pedidos registrados",
    noPedidosSub:"Registra tu primer pedido a proveedor con el botón “Nuevo pedido”.",
    minOneVehicle:"El pedido debe incluir al menos un vehículo",
  },
  en:{
    topHome:"Go to Dashboard", brandSlogan:"General Administration Panel",
    allBranches:"All branches", logout:"Log out", role:"Role", roleAdmin:"General Administrator",
    navDashboard:"Dashboard", navSucursales:"Branches", navPersonal:"Staff", navInventario:"Inventory",
    syncOk:"Live data", syncOff:"DB disconnected",
    date:"Date", time:"Time", admin:"Administrator", session:"Session", active:"Active",
    period:"Period", thisMonth:"This month", lastMonth:"Last month", last6:"Last 6 months", allTime:"All time",
    kpiVentas:"Total sales this period", kpiInventario:"Total inventory volume",
    kpiSucursales:"Active branches", kpiPersonal:"Registered users / managers",
    vsLastMonth:"vs. last month", unitsInStock:"units in stock", ofTotalBranches:"of {n} total branches",
    registeredUsers:"total staff registered",
    chartMonthly:"Monthly sales performance", chartMonthlySub:"Revenue and units sold",
    revenue:"Revenue", units:"Units",
    chartInventory:"Global inventory by category", chartInventorySub:"Stock distribution",
    chartByProduct:"Sales by make / product", chartByProductSub:"Best-selling lines company-wide",
    recentSales:"Recent sales history", recentSalesSub:"Latest recorded transactions",
    colFecha:"Date / time", colSucursal:"Branch", colResponsable:"Cashier / client", colProductos:"Product(s)", colTotal:"Total",
    criticalStock:"Critical stock monitor", criticalStockSub:"Stock at or below minimum threshold",
    criticalEmpty:"No critical stock alerts right now.",
    quickTitle:"Quick actions",
    qaSucursal:"New branch", qaSucursalSub:"Register a location", qaArticulo:"New vehicle / item", qaArticuloSub:"Add to inventory",
    qaPersonal:"Manage Staff", qaPersonalSub:"Go to staff", qaHistorial:"Transaction history", qaHistorialSub:"View consolidated sales",
    sucursalesTitle:"Branches", sucursalesSub:"Centralized branch management (create, edit, deactivate)",
    newSucursal:"New branch", filterAll:"All", filterActive:"Active", filterInactive:"Inactive",
    colNombre:"Name", colDireccion:"Address", colTelefono:"Phone", colGerente:"Manager in charge",
    colCajas:"Active registers", colEstado:"Status", colAcciones:"Actions", edit:"Edit", deactivate:"Deactivate", activate:"Activate",
    noGerente:"Unassigned",
    formSucursalNewTitle:"Register new branch", formSucursalEditTitle:"Edit branch",
    formSucursalDesc:"Marked fields are required. Status controls whether the branch can process sales.",
    fName:"Branch name", fAddress:"Address", fPhone:"Phone", fEmail:"Contact email",
    fManager:"Manager in charge", fCashiers:"Active registers", fStatus:"Status",
    statusActive:"Active", statusInactive:"Inactive", save:"Save", cancel:"Cancel", saveChanges:"Save changes",
    toastSucursalCreated:"Branch registered successfully", toastSucursalUpdated:"Branch updated",
    toastSucursalStatus:"Branch status updated",
    personalTitle:"Staff", personalSub:"Directory and assignment of staff by role and branch",
    newGerente:"New manager", filterAllRoles:"All", roleAdminF:"Administrator", roleGerenteF:"Manager", roleCajeroF:"Cashier",
    colUsuario:"User", colRol:"Role", colSucursalAsig:"Assigned branch",
    formPersonalTitle:"Register branch manager", formPersonalEditTitle:"Edit user",
    formPersonalDesc:"The password is stored only as a password_hash on the server; never in plain text.",
    fFullName:"Full name", fEmailUser:"Email", fPassword:"Password", fRole:"Role",
    fAssignedBranch:"Assigned branch", passwordHint:"Will be encrypted before being saved (password_hash).",
    inventarioTitle:"Inventory · Multi-branch audit", inventarioSub:"Look up stock for any product across every branch",
    searchProduct:"Search product, make or category…", colProducto:"Product", colCategoria:"Category",
    colStockActual:"Current stock", colStockMinimo:"Min. stock", colPrecio:"Price",
    noResults:"No results", noResultsSub:"No items matched your search.",
    startSearch:"Type to search", startSearchSub:"Look up any product's stock across all branches.",
    critical:"Critical", ok:"Sufficient", low:"Low",
    hintDB:"View connected to DB (mock) — ready to point to your real API via DB.*",
    formArticuloTitle:"Quick item registration", formArticuloDesc:"Register a vehicle or part and assign it to a branch.",
    fTipo:"Type", tipoVehiculo:"Vehicle", tipoRefaccion:"Part", fMarca:"Make", fModelo:"Model / name",
    fCategoria:"Category", fBranch:"Branch", fStockInicial:"Initial stock", fStockMin:"Minimum stock", fPrecioVenta:"Sale price",
    toastArticuloCreated:"Item registered in inventory", toastUsuarioCreated:"User registered successfully",
    toastUsuarioUpdated:"User updated", required:"This field is required",
    stockDetailTitle:"Stock by branch", stockDetailSub:"Distribution of the selected product across the network",
    close:"Close", totalNetwork:"Total across network",

    navPedidos:"Orders", qaPedido:"New order", qaPedidoSub:"Supplier purchase order",
    pedidosTitle:"Supplier orders", pedidosSub:"Track purchase orders and incoming units for each branch",
    newPedido:"New order", colFolio:"Folio", colProveedor:"Supplier", colDestino:"Destination branch",
    colVehiculos:"Vehicle(s)", colETA:"ETA", colEmision:"Issued", colRecepcion:"Received",
    estAll:"All", estSolicitado:"Requested", estTransito:"In transit", estPatio:"In yard / customs",
    estRecibido:"Received", estCancelado:"Cancelled",
    viewDetail:"View detail", advance:"Advance", confirmReception:"Confirm reception", cancelOrder:"Cancel order",
    formPedidoNewTitle:"Register new order", formPedidoEditTitle:"Edit order",
    formPedidoDesc:"Capture the purchase order and the detail of every unit included in the batch.",
    fFolio:"Order folio", fProveedor:"Supplier / assembler", fDestino:"Destination branch",
    fFechaEmision:"Issue date", fFechaETA:"Estimated arrival (ETA)",
    vehiculosSectionTitle:"Order vehicles", addVehiculo:"Add vehicle", vehiculoN:"Vehicle",
    fModeloV:"Model", fAnio:"Year", fVersion:"Version", fVin:"VIN / chassis number",
    fColorExt:"Exterior color", fColorInt:"Interior color", fEquipamiento:"Base equipment",
    fCostoAdq:"Acquisition cost", fPrecioProyectado:"Projected sale price",
    toastPedidoCreated:"Order registered successfully", toastPedidoUpdated:"Order updated",
    toastPedidoAdvanced:"Order status updated", toastPedidoCancelled:"Order cancelled",
    toastStockUpdated:"Reception confirmed: stock_actual updated for {n} item(s) at {sucursal}",
    pedidoDetailTitle:"Order detail", pipelineSub:"Order lifecycle tracking",
    dbImpactTitle:"Automated database impact", dbImpactDesc:"On confirming reception, the system automatically increments stock_actual in the inventarios table for the receiving branch, for every unit in the order.",
    unitCost:"Unit cost", projectedPrice:"Projected price", noPedidos:"No orders registered yet",
    noPedidosSub:"Register your first supplier order with the “New order” button.",
    minOneVehicle:"The order must include at least one vehicle",
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
   CAPA DE DATOS (DB) — hoy en memoria, lista para reemplazar por fetch()
   ========================================================================== */
const API_BASE = "/api"; // TODO: apuntar a la URL real del backend

const SEED = (() => {
  const sucursales = [
    { id:"s1", nombre:"Manzanillo", direccion:"Blvd. Costero 1450, Manzanillo, Col.", telefono:"314 333 0101", email:"manzanillo@karma.mx", gerenteId:"u2", cajasActivas:3, estado:"activo" },
    { id:"s2", nombre:"Colima Centro", direccion:"Av. Rey Colimán 220, Colima, Col.", telefono:"312 314 0202", email:"colima@karma.mx", gerenteId:"u3", cajasActivas:2, estado:"activo" },
    { id:"s3", nombre:"Guadalajara Andares", direccion:"Blvd. Puerta de Hierro 4965, Zapopan, Jal.", telefono:"333 817 0303", email:"gdl@karma.mx", gerenteId:"u4", cajasActivas:4, estado:"activo" },
    { id:"s4", nombre:"Puerto Vallarta", direccion:"Av. Francisco M. Ascencio 2895, Puerto Vallarta, Jal.", telefono:"322 224 0404", email:"pv@karma.mx", gerenteId:null, cajasActivas:1, estado:"inactivo" },
  ];
  const usuarios = [
    { id:"u1", nombre:"Sofía Herrera", correo:"sofia.herrera@karma.mx", rol:"admin", sucursalId:null, estado:"activo" },
    { id:"u2", nombre:"Diego Ramírez", correo:"diego.ramirez@karma.mx", rol:"gerente", sucursalId:"s1", estado:"activo" },
    { id:"u3", nombre:"Valeria Nuño", correo:"valeria.nuno@karma.mx", rol:"gerente", sucursalId:"s2", estado:"activo" },
    { id:"u4", nombre:"Rodrigo Campos", correo:"rodrigo.campos@karma.mx", rol:"gerente", sucursalId:"s3", estado:"activo" },
    { id:"u5", nombre:"Ana Martínez", correo:"ana.martinez@karma.mx", rol:"cajero", sucursalId:"s1", estado:"activo" },
    { id:"u6", nombre:"Luis Ortega", correo:"luis.ortega@karma.mx", rol:"cajero", sucursalId:"s1", estado:"activo" },
    { id:"u7", nombre:"Camila Ríos", correo:"camila.rios@karma.mx", rol:"cajero", sucursalId:"s2", estado:"activo" },
    { id:"u8", nombre:"Emilio Vargas", correo:"emilio.vargas@karma.mx", rol:"cajero", sucursalId:"s3", estado:"activo" },
    { id:"u9", nombre:"Renata Solís", correo:"renata.solis@karma.mx", rol:"cajero", sucursalId:"s3", estado:"inactivo" },
  ];
  const productosBase = [
    { producto:"911 Carrera GTS", marca:"Porsche", categoria:"Autos deportivos", precio:2850000 },
    { producto:"Cayenne Turbo", marca:"Porsche", categoria:"SUV de lujo", precio:2190000 },
    { producto:"Taycan Turbo S", marca:"Porsche", categoria:"Autos deportivos", precio:3120000 },
    { producto:"RS6 Avant", marca:"Audi", categoria:"Autos deportivos", precio:2340000 },
    { producto:"Q8 e-tron", marca:"Audi", categoria:"SUV de lujo", precio:1780000 },
    { producto:"R8 V10", marca:"Audi", categoria:"Autos deportivos", precio:3980000 },
    { producto:"Panigale V4 S", marca:"Ducati", categoria:"Motocicletas", precio:695000 },
    { producto:"Multistrada V4", marca:"Ducati", categoria:"Motocicletas", precio:585000 },
    { producto:"Streetfighter V2", marca:"Ducati", categoria:"Motocicletas", precio:398000 },
    { producto:"Kit de frenos cerámicos", marca:"Genérico", categoria:"Refacciones", precio:68000 },
    { producto:"Turbo de reemplazo", marca:"Genérico", categoria:"Refacciones", precio:112000 },
    { producto:"Set de suspensión deportiva", marca:"Genérico", categoria:"Refacciones", precio:89000 },
  ];
  let invId = 1;
  const inventario = [];
  productosBase.forEach(p => {
    sucursales.forEach(s => {
      const base = Math.floor(Math.random()*6) + 1;
      const min = 2;
      inventario.push({
        id:"inv" + (invId++), sucursalId:s.id,
        producto:p.producto, marca:p.marca, categoria:p.categoria, precio:p.precio,
        stockActual: Math.random() < 0.22 ? Math.max(0, min - 1) : base,
        stockMinimo: min,
      });
    });
  });

  const clientes = ["Roberto Salas","Marina Islas","Fernando Tapia","Daniela Cordero","Iván Gutiérrez","Paola Duarte","Héctor Loera","Ximena Prado"];
  const now = new Date();
  const ventas = [];
  let ventaId = 1;
  for (let m = 5; m >= 0; m--){
    const monthDate = new Date(now.getFullYear(), now.getMonth() - m, 1);
    const numVentas = 6 + Math.floor(Math.random()*6);
    for (let i = 0; i < numVentas; i++){
      const s = sucursales[Math.floor(Math.random()*sucursales.length)];
      const prod = productosBase[Math.floor(Math.random()*productosBase.length)];
      const day = 1 + Math.floor(Math.random()*27);
      const fecha = new Date(monthDate.getFullYear(), monthDate.getMonth(), day, 9 + Math.floor(Math.random()*9), Math.floor(Math.random()*60));
      const cajero = usuarios.filter(u => u.rol === "cajero" && u.sucursalId === s.id)[0];
      ventas.push({
        id:"v" + (ventaId++),
        fecha: fecha.toISOString(),
        sucursalId: s.id,
        responsable: cajero ? cajero.nombre : "—",
        cliente: clientes[Math.floor(Math.random()*clientes.length)],
        producto: prod.producto,
        marca: prod.marca,
        categoria: prod.categoria,
        total: Math.round(prod.precio * (0.96 + Math.random()*0.08)),
      });
    }
  }
  const proveedores = ["Porsche AG", "Audi de México", "Ducati Motor Holding", "Ferrari SpA"];
  const estadosPedido = ["solicitado", "transito", "patio", "recibido"];
  let pedidoId = 1, folioN = 1042;
  const pedidos = [];
  for (let i = 0; i < 7; i++){
    const s = sucursales[Math.floor(Math.random()*sucursales.length)];
    const prov = proveedores[Math.floor(Math.random()*proveedores.length)];
    const estado = i === 6 ? "cancelado" : estadosPedido[Math.min(i, estadosPedido.length - 1)];
    const emision = new Date(now.getFullYear(), now.getMonth(), Math.max(1, now.getDate() - (10 + i*6)));
    const eta = new Date(emision.getTime()); eta.setDate(eta.getDate() + 35);
    const recibido = estado === "recibido" ? new Date(eta.getTime() - 86400000*2) : null;
    const numVehiculos = 1 + Math.floor(Math.random()*3);
    const vehiculos = [];
    for (let v = 0; v < numVehiculos; v++){
      const p = productosBase.filter(pb => pb.categoria !== "Refacciones")[Math.floor(Math.random()*productosBase.filter(pb=>pb.categoria!=="Refacciones").length)];
      vehiculos.push({
        modelo: p.producto, marca: p.marca, anio: 2026, version: ["Base","Performance","Sport Edition"][Math.floor(Math.random()*3)],
        vin: "WP0" + Math.random().toString(36).slice(2,10).toUpperCase() + (1000+v),
        colorExterior:["Negro Jet","Blanco Carrara","Gris GT","Azul Night"][Math.floor(Math.random()*4)],
        colorInterior:["Piel Cognac","Piel Negra","Alcántara Roja"][Math.floor(Math.random()*3)],
        equipamiento:"Paquete premium, techo panorámico, asistente de manejo",
        costoAdquisicion: Math.round(p.precio*0.74), precioProyectado: p.precio,
      });
    }
    pedidos.push({
      id:"po"+(pedidoId++), folio:"PO-"+(folioN++), proveedor:prov, sucursalId:s.id,
      fechaEmision: emision.toISOString(), fechaETA: eta.toISOString(),
      fechaRecepcion: recibido ? recibido.toISOString() : null,
      estado, vehiculos,
    });
  }

  return { sucursales, usuarios, inventario, ventas, pedidos };
})();

const DB = {
  async getSucursales(){
    // PROD: return (await fetch(`${API_BASE}/sucursales`)).json();
    await delay(80);
    return SEED.sucursales.map(s => ({ ...s }));
  },
  async createSucursal(payload){
    // PROD: return (await fetch(`${API_BASE}/sucursales`, { method:"POST", body: JSON.stringify(payload) })).json();
    await delay(120);
    const nueva = { id: uid("s"), gerenteId:null, ...payload };
    SEED.sucursales.push(nueva);
    return nueva;
  },
  async updateSucursal(id, payload){
    // PROD: return (await fetch(`${API_BASE}/sucursales/${id}`, { method:"PATCH", body: JSON.stringify(payload) })).json();
    await delay(120);
    const idx = SEED.sucursales.findIndex(s => s.id === id);
    if (idx > -1) SEED.sucursales[idx] = { ...SEED.sucursales[idx], ...payload };
    return SEED.sucursales[idx];
  },
  async setSucursalEstado(id, estado){
    return DB.updateSucursal(id, { estado });
  },
  async getUsuarios(){
    // PROD: return (await fetch(`${API_BASE}/usuarios`)).json();
    await delay(80);
    return SEED.usuarios.map(u => ({ ...u }));
  },
  async createUsuario(payload){
    // PROD: hashear password en el servidor antes de guardar (password_hash)
    // return (await fetch(`${API_BASE}/usuarios`, { method:"POST", body: JSON.stringify(payload) })).json();
    await delay(140);
    const { password, ...rest } = payload;
    const nuevo = { id: uid("u"), estado:"activo", ...rest };
    SEED.usuarios.push(nuevo);
    return nuevo;
  },
  async updateUsuario(id, payload){
    await delay(120);
    const idx = SEED.usuarios.findIndex(u => u.id === id);
    if (idx > -1) SEED.usuarios[idx] = { ...SEED.usuarios[idx], ...payload };
    return SEED.usuarios[idx];
  },
  async getInventario(){
    // PROD: return (await fetch(`${API_BASE}/inventario`)).json();
    await delay(90);
    return SEED.inventario.map(i => ({ ...i }));
  },
  async createInventarioItem(payload){
    await delay(120);
    const nuevo = { id: uid("inv"), ...payload };
    SEED.inventario.push(nuevo);
    return nuevo;
  },
  async getVentas(){
    // PROD: return (await fetch(`${API_BASE}/ventas`)).json();
    await delay(100);
    return SEED.ventas.map(v => ({ ...v }));
  },

  async getPedidos(){
    // PROD: return (await fetch(`${API_BASE}/pedidos`)).json();
    await delay(90);
    return SEED.pedidos.map(p => ({ ...p, vehiculos: p.vehiculos.map(v => ({ ...v })) }));
  },
  async createPedido(payload){
    // PROD: return (await fetch(`${API_BASE}/pedidos`, { method:"POST", body: JSON.stringify(payload) })).json();
    await delay(140);
    const folioN = 1000 + SEED.pedidos.length + Math.floor(Math.random()*50);
    const nuevo = { id: uid("po"), folio:"PO-"+folioN, fechaRecepcion:null, estado:"solicitado", ...payload };
    SEED.pedidos.push(nuevo);
    return nuevo;
  },
  async updatePedido(id, payload){
    // PROD: return (await fetch(`${API_BASE}/pedidos/${id}`, { method:"PATCH", body: JSON.stringify(payload) })).json();
    await delay(120);
    const idx = SEED.pedidos.findIndex(p => p.id === id);
    if (idx > -1) SEED.pedidos[idx] = { ...SEED.pedidos[idx], ...payload };
    return SEED.pedidos[idx];
  },
  async setPedidoEstado(id, estado){
    await delay(110);
    const p = SEED.pedidos.find(x => x.id === id);
    if (!p) return null;
    p.estado = estado;
    if (estado === "recibido") p.fechaRecepcion = new Date().toISOString();
    return p;
  },
  /**
   * Simula el disparador / consulta transaccional que, al confirmar la
   * recepción de un pedido, incrementa stock_actual en la tabla
   * `inventarios` de la sucursal receptora por cada vehículo del lote.
   * PROD (ejemplo de trigger en el backend):
   *   UPDATE inventarios SET stock_actual = stock_actual + 1
   *   WHERE sucursal_id = :sucursalId AND producto = :modelo;
   *   -- o INSERT si el producto aún no existe en esa sucursal.
   */
  async confirmarRecepcion(pedidoId){
    await delay(160);
    const pedido = SEED.pedidos.find(p => p.id === pedidoId);
    if (!pedido) return null;
    pedido.estado = "recibido";
    pedido.fechaRecepcion = new Date().toISOString();

    const afectados = [];
    pedido.vehiculos.forEach(v => {
      let item = SEED.inventario.find(i => i.sucursalId === pedido.sucursalId && i.producto === v.modelo);
      if (item){
        item.stockActual += 1;
      }else{
        item = {
          id: uid("inv"), sucursalId: pedido.sucursalId,
          producto: v.modelo, marca: v.marca, categoria: "Vehículos",
          precio: v.precioProyectado, stockActual: 1, stockMinimo: 2,
        };
        SEED.inventario.push(item);
      }
      afectados.push(item);
    });
    return { pedido, afectados };
  },
};

/* ==========================================================================
   ESTADO GLOBAL
   ========================================================================== */
const state = {
  view:"dashboard",              // dashboard | sucursales | personal | inventario | pedidos
  lang:"es",
  sucursalFiltro:"todas",        // filtro global de sucursal
  sucursales:[], usuarios:[], inventario:[], ventas:[], pedidos:[],
  sucursalesEstadoFiltro:"all",  // all | active | inactive (vista Sucursales)
  personalRolFiltro:"all",       // all | admin | gerente | cajero (vista Personal)
  inventarioQuery:"",
  pedidosEstadoFiltro:"all",     // all | solicitado | transito | patio | recibido | cancelado
  cargando:true,
};
const PEDIDO_PIPELINE = ["solicitado", "transito", "patio", "recibido"];
const chartInstances = {};

/* ==========================================================================
   CARGA INICIAL DE DATOS
   ========================================================================== */
async function cargarDatos(){
  state.cargando = true;
  try{
    const [sucursales, usuarios, inventario, ventas, pedidos] = await Promise.all([
      DB.getSucursales(), DB.getUsuarios(), DB.getInventario(), DB.getVentas(), DB.getPedidos()
    ]);
    state.sucursales = sucursales;
    state.usuarios = usuarios;
    state.inventario = inventario;
    state.ventas = ventas;
    state.pedidos = pedidos;
    setSyncStatus(true);
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
   SELECTOR GLOBAL DE SUCURSAL
   ========================================================================== */
function poblarSelectorSucursales(){
  const sel = $("#sucursalSelect");
  const valorActual = sel.value || "todas";
  sel.innerHTML = `<option value="todas">${t("allBranches")}</option>` +
    state.sucursales.map(s => `<option value="${s.id}">${escapeHTML(s.nombre)}</option>`).join("");
  sel.value = state.sucursales.some(s => s.id === valorActual) ? valorActual : "todas";
  state.sucursalFiltro = sel.value;
}

/* ==========================================================================
   HELPERS DE DATOS FILTRADOS
   ========================================================================== */
function sucursalNombre(id){
  const s = state.sucursales.find(s => s.id === id);
  return s ? s.nombre : "—";
}
function gerenteDeSucursal(id){
  const u = state.usuarios.find(u => u.sucursalId === id && u.rol === "gerente");
  return u || null;
}
function ventasFiltradas(sucursalId = state.sucursalFiltro){
  return sucursalId === "todas" ? state.ventas : state.ventas.filter(v => v.sucursalId === sucursalId);
}
function inventarioFiltrado(sucursalId = state.sucursalFiltro){
  return sucursalId === "todas" ? state.inventario : state.inventario.filter(i => i.sucursalId === sucursalId);
}
function totalVentasEnMes(ventas, offsetMeses){
  const now = new Date();
  const target = new Date(now.getFullYear(), now.getMonth() - offsetMeses, 1);
  return ventas
    .filter(v => { const d = new Date(v.fecha); return d.getFullYear() === target.getFullYear() && d.getMonth() === target.getMonth(); })
    .reduce((sum, v) => sum + v.total, 0);
}
function serieMensual(ventas, meses = 6){
  const now = new Date();
  const labels = [], ingresos = [], unidades = [];
  for (let m = meses - 1; m >= 0; m--){
    const target = new Date(now.getFullYear(), now.getMonth() - m, 1);
    const delMes = ventas.filter(v => { const d = new Date(v.fecha); return d.getFullYear() === target.getFullYear() && d.getMonth() === target.getMonth(); });
    labels.push(MESES[state.lang][target.getMonth()]);
    ingresos.push(delMes.reduce((s,v) => s + v.total, 0));
    unidades.push(delMes.length);
  }
  return { labels, ingresos, unidades };
}
function inventarioPorCategoria(inv){
  const map = {};
  inv.forEach(i => { map[i.categoria] = (map[i.categoria] || 0) + i.stockActual; });
  return map;
}
function ventasPorProducto(ventas, top = 6){
  const map = {};
  ventas.forEach(v => { map[v.producto] = (map[v.producto] || 0) + 1; });
  return Object.entries(map).sort((a,b) => b[1]-a[1]).slice(0, top);
}
function stockCritico(inv){
  return inv.filter(i => i.stockActual <= i.stockMinimo)
    .sort((a,b) => (a.stockActual - a.stockMinimo) - (b.stockActual - b.stockMinimo));
}

/* ==========================================================================
   RENDER PRINCIPAL
   ========================================================================== */
function renderMain(){
  const main = $("#main");
  if (state.cargando){
    main.innerHTML = `<div class="panel panel-full"><div class="empty-state"><strong>…</strong></div></div>`;
    return;
  }
  $$(".sub-nav-btn").forEach(b => b.classList.toggle("is-active", b.dataset.view === state.view));
  applyI18n();
  if (state.view === "dashboard") renderDashboard();
  else if (state.view === "sucursales") renderSucursales();
  else if (state.view === "personal") renderPersonal();
  else if (state.view === "inventario") renderInventario();
  else if (state.view === "pedidos") renderPedidos();
}

/* ==========================================================================
   VISTA: DASHBOARD
   ========================================================================== */
function renderDashboard(){
  const main = $("#main");
  const ventas = ventasFiltradas();
  const inv = inventarioFiltrado();
  const sucursalesActivas = state.sucursales.filter(s => s.estado === "activo").length;

  const totalMesActual = totalVentasEnMes(ventas, 0);
  const totalMesAnterior = totalVentasEnMes(ventas, 1);
  const delta = totalMesAnterior > 0 ? ((totalMesActual - totalMesAnterior) / totalMesAnterior) * 100 : (totalMesActual > 0 ? 100 : 0);
  const deltaUp = delta >= 0;

  const volumenInventario = inv.reduce((s,i) => s + i.stockActual, 0);
  const alertas = stockCritico(inv);

  main.innerHTML = `
    <div class="panel panel-full">

      <div class="panel-heading fade-in">
        <div>
          <p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursalFiltro === "todas" ? t("allBranches") : sucursalNombre(state.sucursalFiltro))}</p>
          <h2>${t("navDashboard")}</h2>
        </div>
      </div>

      <div class="quick-actions fade-in fade-in--1">
        <button class="quick-action" data-quick="sucursal">
          <span class="quick-action-icon">${iconBuilding()}</span>
          <span class="quick-action-text"><span class="quick-action-title">${t("qaSucursal")}</span><span class="quick-action-sub">${t("qaSucursalSub")}</span></span>
        </button>
        <button class="quick-action" data-quick="articulo">
          <span class="quick-action-icon">${iconCar()}</span>
          <span class="quick-action-text"><span class="quick-action-title">${t("qaArticulo")}</span><span class="quick-action-sub">${t("qaArticuloSub")}</span></span>
        </button>
        <button class="quick-action" data-quick="personal">
          <span class="quick-action-icon">${iconUsers()}</span>
          <span class="quick-action-text"><span class="quick-action-title">${t("qaPersonal")}</span><span class="quick-action-sub">${t("qaPersonalSub")}</span></span>
        </button>
        <button class="quick-action" data-quick="historial">
          <span class="quick-action-icon">${iconClock()}</span>
          <span class="quick-action-text"><span class="quick-action-title">${t("qaHistorial")}</span><span class="quick-action-sub">${t("qaHistorialSub")}</span></span>
        </button>
      </div>

      <div class="kpi-grid fade-in fade-in--1">
        <div class="kpi-card">
          <div class="kpi-icon">${iconCoin()}</div>
          <div class="kpi-label">${t("kpiVentas")}</div>
          <div class="kpi-value">${formatoMoneda(totalMesActual)}</div>
          <div class="kpi-sub">
            <span class="kpi-delta ${deltaUp ? "is-up" : "is-down"}">${deltaUp ? "▲" : "▼"} ${Math.abs(delta).toFixed(1)}%</span>
            <span>${t("vsLastMonth")}</span>
          </div>
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconBox()}</div>
          <div class="kpi-label">${t("kpiInventario")}</div>
          <div class="kpi-value">${formatoNumero(volumenInventario)}</div>
          <div class="kpi-sub"><span>${t("unitsInStock")}</span></div>
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconBuilding()}</div>
          <div class="kpi-label">${t("kpiSucursales")}</div>
          <div class="kpi-value">${sucursalesActivas}</div>
          <div class="kpi-sub"><span>${t("ofTotalBranches").replace("{n}", state.sucursales.length)}</span></div>
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconUsers()}</div>
          <div class="kpi-label">${t("kpiPersonal")}</div>
          <div class="kpi-value">${state.usuarios.length}</div>
          <div class="kpi-sub"><span>${t("registeredUsers")}</span></div>
        </div>
      </div>

      ${alertas.length ? `
      <div class="alert-panel fade-in fade-in--2">
        <div class="alert-panel-head">
          <h3>${iconAlert()} ${t("criticalStock")}</h3>
        </div>
        <div class="alert-list">
          ${alertas.slice(0,5).map(a => `
            <div class="alert-item">
              <div class="alert-item-main">
                <span class="alert-item-title">${escapeHTML(a.producto)}</span>
                <span class="alert-item-sub">${escapeHTML(a.marca)} · ${escapeHTML(sucursalNombre(a.sucursalId))}</span>
              </div>
              <span class="alert-item-stock">${a.stockActual} / ${a.stockMinimo}</span>
            </div>
          `).join("")}
        </div>
      </div>` : ""}

      <div class="charts-row fade-in fade-in--2">
        <div class="chart-card">
          <div class="chart-card-head">
            <div><h3>${t("chartMonthly")}</h3><span>${t("chartMonthlySub")}</span></div>
          </div>
          <div class="chart-canvas-wrap"><canvas id="chartMonthly"></canvas></div>
          <div class="chart-legend">
            <span class="chart-legend-item"><span class="chart-legend-dot" style="background:var(--chart-navy)"></span>${t("revenue")}</span>
            <span class="chart-legend-item"><span class="chart-legend-dot" style="background:var(--chart-red)"></span>${t("units")}</span>
          </div>
        </div>
        <div class="chart-card">
          <div class="chart-card-head">
            <div><h3>${t("chartInventory")}</h3><span>${t("chartInventorySub")}</span></div>
          </div>
          <div class="chart-canvas-wrap is-small"><canvas id="chartInventory"></canvas></div>
        </div>
      </div>

      <div class="charts-row-2 fade-in fade-in--3">
        <div class="chart-card">
          <div class="chart-card-head">
            <div><h3>${t("chartByProduct")}</h3><span>${t("chartByProductSub")}</span></div>
          </div>
          <div class="chart-canvas-wrap"><canvas id="chartByProduct"></canvas></div>
        </div>
        <div class="chart-card">
          <div class="chart-card-head">
            <div><h3>${t("criticalStock")}</h3><span>${t("criticalStockSub")}</span></div>
          </div>
          <div class="alert-list" style="margin-top:4px;">
            ${alertas.length ? alertas.slice(0,6).map(a => `
              <div class="alert-item">
                <div class="alert-item-main">
                  <span class="alert-item-title">${escapeHTML(a.producto)}</span>
                  <span class="alert-item-sub">${escapeHTML(sucursalNombre(a.sucursalId))}</span>
                </div>
                <span class="alert-item-stock">${a.stockActual}/${a.stockMinimo}</span>
              </div>
            `).join("") : `<p class="alert-empty">${t("criticalEmpty")}</p>`}
          </div>
        </div>
      </div>

      <div class="chart-card fade-in fade-in--4" style="margin-bottom:30px;">
        <div class="chart-card-head">
          <div><h3>${t("recentSales")}</h3><span>${t("recentSalesSub")}</span></div>
        </div>
        <div class="table-wrap">
          <table class="data-table">
            <thead><tr>
              <th>${t("colFecha")}</th><th>${t("colSucursal")}</th><th>${t("colResponsable")}</th><th>${t("colProductos")}</th><th>${t("colTotal")}</th>
            </tr></thead>
            <tbody>
              ${[...ventas].sort((a,b) => new Date(b.fecha) - new Date(a.fecha)).slice(0,8).map(v => `
                <tr>
                  <td class="cell-muted">${new Date(v.fecha).toLocaleString(state.lang === "en" ? "en-US" : "es-MX", { day:"2-digit", month:"short", hour:"2-digit", minute:"2-digit" })}</td>
                  <td>${escapeHTML(sucursalNombre(v.sucursalId))}</td>
                  <td>${escapeHTML(v.responsable)} <span class="cell-em">/ ${escapeHTML(v.cliente)}</span></td>
                  <td>${escapeHTML(v.producto)}</td>
                  <td><strong>${formatoMoneda(v.total)}</strong></td>
                </tr>
              `).join("") || `<tr><td colspan="5" class="cell-muted">—</td></tr>`}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  `;

  bindQuickActions();
  drawDashboardCharts(ventas, inv);
}

function bindQuickActions(){
  $$("[data-quick]").forEach(btn => btn.addEventListener("click", () => {
    const action = btn.dataset.quick;
    if (action === "sucursal") abrirModalSucursal();
    else if (action === "articulo") abrirModalArticulo();
    else if (action === "personal") { state.view = "personal"; renderMain(); }
    else if (action === "historial") { state.view = "dashboard"; renderMain(); setTimeout(() => $(".chart-card")?.scrollIntoView({ behavior:"smooth" }), 60); }
  }));
}

function chartColors(){
  const styles = getComputedStyle(document.body);
  return {
    text: styles.getPropertyValue("--text-muted").trim(),
    grid: styles.getPropertyValue("--chart-grid").trim(),
    navy: styles.getPropertyValue("--chart-navy").trim(),
    red: styles.getPropertyValue("--chart-red").trim(),
  };
}
function destroyChart(key){
  if (chartInstances[key]){ chartInstances[key].destroy(); delete chartInstances[key]; }
}
function drawDashboardCharts(ventas, inv){
  if (typeof Chart === "undefined") return;
  const c = chartColors();
  Chart.defaults.font.family = "Inter, sans-serif";
  Chart.defaults.color = c.text;

  // Rendimiento mensual (ingresos + unidades)
  const serie = serieMensual(ventas, 6);
  destroyChart("monthly");
  const ctxM = $("#chartMonthly");
  if (ctxM){
    chartInstances.monthly = new Chart(ctxM, {
      data:{
        labels: serie.labels,
        datasets:[
          { type:"bar", label:t("revenue"), data:serie.ingresos, backgroundColor:c.navy, borderRadius:6, yAxisID:"y", order:2, maxBarThickness:34 },
          { type:"line", label:t("units"), data:serie.unidades, borderColor:c.red, backgroundColor:c.red, tension:.35, yAxisID:"y1", order:1, pointRadius:3, pointBackgroundColor:c.red, borderWidth:2 },
        ]
      },
      options:{
        responsive:true, maintainAspectRatio:false,
        interaction:{ mode:"index", intersect:false },
        plugins:{ legend:{ display:false }, tooltip:{ callbacks:{ label:(ctx) => ctx.dataset.label === t("revenue") ? `${t("revenue")}: ${formatoMoneda(ctx.raw)}` : `${t("units")}: ${ctx.raw}` } } },
        scales:{
          x:{ grid:{ display:false } },
          y:{ position:"left", grid:{ color:c.grid }, ticks:{ callback:(v) => formatoNumero(v) } },
          y1:{ position:"right", grid:{ display:false }, ticks:{ precision:0 } },
        }
      }
    });
  }

  // Inventario por categoría
  const cat = inventarioPorCategoria(inv);
  destroyChart("inventory");
  const ctxI = $("#chartInventory");
  if (ctxI){
    const palette = [c.navy, c.red, "#7C93B8", "#C97E8A", "#3B4E75", "#B86470"];
    chartInstances.inventory = new Chart(ctxI, {
      type:"doughnut",
      data:{ labels:Object.keys(cat), datasets:[{ data:Object.values(cat), backgroundColor:palette, borderWidth:2, borderColor:getComputedStyle(document.body).getPropertyValue("--surface-2") }] },
      options:{
        responsive:true, maintainAspectRatio:false, cutout:"64%",
        plugins:{ legend:{ position:"bottom", labels:{ boxWidth:10, padding:12, font:{ size:11 } } } }
      }
    });
  }

  // Ventas por marca/producto
  const porProducto = ventasPorProducto(ventas, 6);
  destroyChart("byProduct");
  const ctxP = $("#chartByProduct");
  if (ctxP){
    chartInstances.byProduct = new Chart(ctxP, {
      type:"bar",
      data:{
        labels: porProducto.map(p => p[0]),
        datasets:[{ data: porProducto.map(p => p[1]), backgroundColor:c.navy, borderRadius:6, maxBarThickness:26 }]
      },
      options:{
        indexAxis:"y", responsive:true, maintainAspectRatio:false,
        plugins:{ legend:{ display:false } },
        scales:{ x:{ grid:{ color:c.grid }, ticks:{ precision:0 } }, y:{ grid:{ display:false } } }
      }
    });
  }
}

/* ==========================================================================
   VISTA: SUCURSALES (CRUD)
   ========================================================================== */
function renderSucursales(){
  const main = $("#main");
  let lista = state.sucursales;
  if (state.sucursalesEstadoFiltro === "active") lista = lista.filter(s => s.estado === "activo");
  if (state.sucursalesEstadoFiltro === "inactive") lista = lista.filter(s => s.estado === "inactivo");

  const totalCajas = state.sucursales.reduce((s,x) => s + x.cajasActivas, 0);
  const activas = state.sucursales.filter(s => s.estado === "activo").length;

  main.innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA</p><h2>${t("sucursalesTitle")}</h2></div>
        <div class="panel-heading-actions">
          <button class="btn btn-primary" id="btnNuevaSucursal">${iconPlus()} ${t("newSucursal")}</button>
        </div>
      </div>

      <div class="sucursal-summary fade-in fade-in--1">
        <div class="sucursal-mini"><div class="kpi-label">${t("kpiSucursales")}</div><div class="kpi-value">${activas} / ${state.sucursales.length}</div></div>
        <div class="sucursal-mini"><div class="kpi-label">${t("colCajas")}</div><div class="kpi-value">${totalCajas}</div></div>
        <div class="sucursal-mini"><div class="kpi-label">${t("kpiPersonal")}</div><div class="kpi-value">${state.usuarios.filter(u=>u.rol!=="admin").length}</div></div>
      </div>

      <div class="section-toolbar fade-in fade-in--1">
        <div class="filter-pills">
          <button class="filter-pill ${state.sucursalesEstadoFiltro==="all"?"is-active":""}" data-sfiltro="all">${t("filterAll")}</button>
          <button class="filter-pill ${state.sucursalesEstadoFiltro==="active"?"is-active":""}" data-sfiltro="active">${t("filterActive")}</button>
          <button class="filter-pill ${state.sucursalesEstadoFiltro==="inactive"?"is-active":""}" data-sfiltro="inactive">${t("filterInactive")}</button>
        </div>
      </div>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr>
            <th>${t("colNombre")}</th><th>${t("colDireccion")}</th><th>${t("colTelefono")}</th>
            <th>${t("colGerente")}</th><th>${t("colCajas")}</th><th>${t("colEstado")}</th><th>${t("colAcciones")}</th>
          </tr></thead>
          <tbody>
            ${lista.map(s => {
              const g = gerenteDeSucursal(s.id);
              return `
              <tr>
                <td><strong>${escapeHTML(s.nombre)}</strong></td>
                <td class="cell-muted">${escapeHTML(s.direccion)}</td>
                <td class="cell-muted">${escapeHTML(s.telefono)}</td>
                <td>${g ? escapeHTML(g.nombre) : `<span class="cell-em">${t("noGerente")}</span>`}</td>
                <td>${s.cajasActivas}</td>
                <td>${s.estado === "activo" ? `<span class="badge badge-ok"><span class="badge-dot"></span>${t("statusActive")}</span>` : `<span class="badge badge-off"><span class="badge-dot"></span>${t("statusInactive")}</span>`}</td>
                <td>
                  <div class="btn-table-row">
                    <button class="btn-table" data-editar-sucursal="${s.id}">${t("edit")}</button>
                    <button class="btn-table" data-toggle-sucursal="${s.id}">${s.estado === "activo" ? t("deactivate") : t("activate")}</button>
                  </div>
                </td>
              </tr>`;
            }).join("") || `<tr><td colspan="7"><div class="empty-state"><strong>${t("noResults")}</strong></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;

  $("#btnNuevaSucursal").addEventListener("click", () => abrirModalSucursal());
  $$("[data-sfiltro]").forEach(b => b.addEventListener("click", () => { state.sucursalesEstadoFiltro = b.dataset.sfiltro; renderSucursales(); }));
  $$("[data-editar-sucursal]").forEach(b => b.addEventListener("click", () => abrirModalSucursal(b.dataset.editarSucursal)));
  $$("[data-toggle-sucursal]").forEach(b => b.addEventListener("click", async () => {
    const id = b.dataset.toggleSucursal;
    const s = state.sucursales.find(x => x.id === id);
    const nuevoEstado = s.estado === "activo" ? "inactivo" : "activo";
    await DB.setSucursalEstado(id, nuevoEstado);
    s.estado = nuevoEstado;
    mostrarToast(t("toastSucursalStatus"), "ok");
    renderSucursales();
  }));
}

function abrirModalSucursal(id){
  const editando = !!id;
  const s = editando ? state.sucursales.find(x => x.id === id) : null;
  const gerentesDisponibles = state.usuarios.filter(u => u.rol === "gerente");

  $("#modalSucursalContent").innerHTML = `
    <h3 class="modal-title">${editando ? t("formSucursalEditTitle") : t("formSucursalNewTitle")}</h3>
    <p class="modal-desc">${t("formSucursalDesc")}</p>
    <form id="formSucursal">
      <div class="form-grid">
        <div class="form-field span-2"><label>${t("fName")} *</label><input type="text" name="nombre" required value="${s ? escapeHTML(s.nombre) : ""}"></div>
        <div class="form-field span-2"><label>${t("fAddress")} *</label><input type="text" name="direccion" required value="${s ? escapeHTML(s.direccion) : ""}"></div>
        <div class="form-field"><label>${t("fPhone")} *</label><input type="tel" name="telefono" required value="${s ? escapeHTML(s.telefono) : ""}"></div>
        <div class="form-field"><label>${t("fEmail")}</label><input type="email" name="email" value="${s ? escapeHTML(s.email || "") : ""}"></div>
        <div class="form-field"><label>${t("fManager")}</label>
          <select name="gerenteId">
            <option value="">${t("noGerente")}</option>
            ${gerentesDisponibles.map(g => `<option value="${g.id}" ${s && s.gerenteId===g.id?"selected":""}>${escapeHTML(g.nombre)}</option>`).join("")}
          </select>
        </div>
        <div class="form-field"><label>${t("fCashiers")}</label><input type="number" min="0" name="cajasActivas" value="${s ? s.cajasActivas : 1}"></div>
        <div class="form-field span-2"><label>${t("fStatus")}</label>
          <div class="segmented">
            <button type="button" class="segmented-btn ${(!s || s.estado==="activo") ? "is-active":""}" data-estado="activo">${t("statusActive")}</button>
            <button type="button" class="segmented-btn ${(s && s.estado==="inactivo") ? "is-active":""}" data-estado="inactivo">${t("statusInactive")}</button>
          </div>
          <input type="hidden" name="estado" value="${s ? s.estado : "activo"}">
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("cancel")}</button>
        <button type="submit" class="btn btn-primary">${editando ? t("saveChanges") : t("save")}</button>
      </div>
    </form>
  `;

  const form = $("#formSucursal");
  $$(".segmented-btn", form).forEach(btn => btn.addEventListener("click", () => {
    $$(".segmented-btn", form).forEach(b => b.classList.remove("is-active"));
    btn.classList.add("is-active");
    form.estado.value = btn.dataset.estado;
  }));

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const payload = {
      nombre: fd.get("nombre").trim(),
      direccion: fd.get("direccion").trim(),
      telefono: fd.get("telefono").trim(),
      email: fd.get("email").trim(),
      gerenteId: fd.get("gerenteId") || null,
      cajasActivas: Number(fd.get("cajasActivas")) || 0,
      estado: fd.get("estado"),
    };
    if (editando){
      await DB.updateSucursal(id, payload);
      Object.assign(s, payload);
      mostrarToast(t("toastSucursalUpdated"), "ok");
    }else{
      const nueva = await DB.createSucursal(payload);
      state.sucursales.push(nueva);
      mostrarToast(t("toastSucursalCreated"), "ok");
    }
    cerrarModales();
    poblarSelectorSucursales();
    if (state.view === "sucursales") renderSucursales();
    else if (state.view === "dashboard") renderDashboard();
  });

  abrirModal("#modalSucursal");
}

/* ==========================================================================
   VISTA: PERSONAL
   ========================================================================== */
function renderPersonal(){
  const main = $("#main");
  let lista = state.usuarios;
  if (state.personalRolFiltro !== "all") lista = lista.filter(u => u.rol === state.personalRolFiltro);

  main.innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA</p><h2>${t("personalTitle")}</h2></div>
        <div class="panel-heading-actions">
          <button class="btn btn-primary" id="btnNuevoGerente">${iconPlus()} ${t("newGerente")}</button>
        </div>
      </div>

      <div class="section-toolbar fade-in fade-in--1">
        <div class="filter-pills">
          <button class="filter-pill ${state.personalRolFiltro==="all"?"is-active":""}" data-rfiltro="all">${t("filterAllRoles")}</button>
          <button class="filter-pill ${state.personalRolFiltro==="admin"?"is-active":""}" data-rfiltro="admin">${t("roleAdminF")}</button>
          <button class="filter-pill ${state.personalRolFiltro==="gerente"?"is-active":""}" data-rfiltro="gerente">${t("roleGerenteF")}</button>
          <button class="filter-pill ${state.personalRolFiltro==="cajero"?"is-active":""}" data-rfiltro="cajero">${t("roleCajeroF")}</button>
        </div>
      </div>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr>
            <th>${t("colUsuario")}</th><th>${t("colRol")}</th><th>${t("colSucursalAsig")}</th><th>${t("colEstado")}</th><th>${t("colAcciones")}</th>
          </tr></thead>
          <tbody>
            ${lista.map(u => `
              <tr>
                <td>
                  <div class="cell-person">
                    <span class="avatar">${iniciales(u.nombre)}</span>
                    <div><div class="cell-person-name">${escapeHTML(u.nombre)}</div><div class="cell-person-email">${escapeHTML(u.correo)}</div></div>
                  </div>
                </td>
                <td><span class="role-badge role-${u.rol}">${u.rol === "admin" ? t("roleAdminF") : u.rol === "gerente" ? t("roleGerenteF") : t("roleCajeroF")}</span></td>
                <td class="cell-muted">${u.sucursalId ? escapeHTML(sucursalNombre(u.sucursalId)) : "—"}</td>
                <td>${u.estado === "activo" ? `<span class="badge badge-ok"><span class="badge-dot"></span>${t("statusActive")}</span>` : `<span class="badge badge-off"><span class="badge-dot"></span>${t("statusInactive")}</span>`}</td>
                <td><button class="btn-table" data-editar-usuario="${u.id}">${t("edit")}</button></td>
              </tr>
            `).join("") || `<tr><td colspan="5"><div class="empty-state"><strong>${t("noResults")}</strong></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;

  $("#btnNuevoGerente").addEventListener("click", () => abrirModalPersonal());
  $$("[data-rfiltro]").forEach(b => b.addEventListener("click", () => { state.personalRolFiltro = b.dataset.rfiltro; renderPersonal(); }));
  $$("[data-editar-usuario]").forEach(b => b.addEventListener("click", () => abrirModalPersonal(b.dataset.editarUsuario)));
}

function abrirModalPersonal(id){
  const editando = !!id;
  const u = editando ? state.usuarios.find(x => x.id === id) : null;

  $("#modalPersonalContent").innerHTML = `
    <h3 class="modal-title">${editando ? t("formPersonalEditTitle") : t("formPersonalTitle")}</h3>
    <p class="modal-desc">${t("formPersonalDesc")}</p>
    <form id="formPersonal">
      <div class="form-grid">
        <div class="form-field span-2"><label>${t("fFullName")} *</label><input type="text" name="nombre" required value="${u ? escapeHTML(u.nombre) : ""}"></div>
        <div class="form-field"><label>${t("fEmailUser")} *</label><input type="email" name="correo" required value="${u ? escapeHTML(u.correo) : ""}"></div>
        <div class="form-field"><label>${t("fRole")}</label>
          <select name="rol">
            <option value="gerente" ${(!u || u.rol==="gerente")?"selected":""}>${t("roleGerenteF")}</option>
            <option value="cajero" ${u && u.rol==="cajero"?"selected":""}>${t("roleCajeroF")}</option>
            <option value="admin" ${u && u.rol==="admin"?"selected":""}>${t("roleAdminF")}</option>
          </select>
        </div>
        ${!editando ? `<div class="form-field span-2"><label>${t("fPassword")} *</label><input type="password" name="password" required minlength="8"><p class="form-field-info">${t("passwordHint")}</p></div>` : ""}
        <div class="form-field span-2"><label>${t("fAssignedBranch")}</label>
          <select name="sucursalId">
            <option value="">—</option>
            ${state.sucursales.map(s => `<option value="${s.id}" ${u && u.sucursalId===s.id?"selected":""}>${escapeHTML(s.nombre)}</option>`).join("")}
          </select>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("cancel")}</button>
        <button type="submit" class="btn btn-primary">${editando ? t("saveChanges") : t("save")}</button>
      </div>
    </form>
  `;

  const form = $("#formPersonal");
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const payload = {
      nombre: fd.get("nombre").trim(),
      correo: fd.get("correo").trim(),
      rol: fd.get("rol"),
      sucursalId: fd.get("sucursalId") || null,
    };
    if (editando){
      await DB.updateUsuario(id, payload);
      Object.assign(u, payload);
      mostrarToast(t("toastUsuarioUpdated"), "ok");
    }else{
      payload.password = fd.get("password");
      const nuevo = await DB.createUsuario(payload);
      state.usuarios.push(nuevo);
      mostrarToast(t("toastUsuarioCreated"), "ok");
    }
    cerrarModales();
    if (state.view === "personal") renderPersonal();
  });

  abrirModal("#modalPersonal");
}

/* ==========================================================================
   VISTA: INVENTARIO — auditoría multi-sede + stock crítico
   ========================================================================== */
function renderInventario(){
  const main = $("#main");
  const alertas = stockCritico(state.inventario);
  const q = state.inventarioQuery.trim().toLowerCase();
  let resultados = [];
  if (q){
    resultados = state.inventario.filter(i =>
      i.producto.toLowerCase().includes(q) || i.marca.toLowerCase().includes(q) || i.categoria.toLowerCase().includes(q)
    );
  }
  // Agrupar resultados por producto para mostrar distribución multi-sede
  const agrupados = {};
  resultados.forEach(i => {
    const key = i.producto;
    if (!agrupados[key]) agrupados[key] = { producto:i.producto, marca:i.marca, categoria:i.categoria, precio:i.precio, sedes:[] };
    agrupados[key].sedes.push(i);
  });

  main.innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA</p><h2>${t("inventarioTitle")}</h2></div>
      </div>
      <div class="hint-banner fade-in">${iconInfo()} ${t("hintDB")}</div>

      ${alertas.length ? `
      <div class="alert-panel fade-in fade-in--1">
        <div class="alert-panel-head"><h3>${iconAlert()} ${t("criticalStock")}</h3></div>
        <div class="alert-list">
          ${alertas.map(a => `
            <div class="alert-item">
              <div class="alert-item-main">
                <span class="alert-item-title">${escapeHTML(a.producto)}</span>
                <span class="alert-item-sub">${escapeHTML(a.marca)} · ${escapeHTML(sucursalNombre(a.sucursalId))}</span>
              </div>
              <span class="alert-item-stock">${a.stockActual} / ${a.stockMinimo}</span>
            </div>
          `).join("")}
        </div>
      </div>` : `<div class="alert-panel fade-in fade-in--1" style="background:var(--ok-soft); border-color:rgba(31,122,77,.3);"><p class="alert-empty">${t("criticalEmpty")}</p></div>`}

      <div class="section-toolbar fade-in fade-in--2">
        <div class="search-box" style="flex:0 0 380px; max-width:100%;">
          <div class="search-wrap" style="background:var(--surface-2); border-color:var(--line); color:var(--text-muted);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.4-3.4"/></svg>
            <input id="inpBuscarInventario" type="text" placeholder="${t("searchProduct")}" style="color:var(--text-main);" value="${escapeHTML(state.inventarioQuery)}">
          </div>
        </div>
      </div>

      <div class="fade-in fade-in--3" id="inventarioResultados">
        ${renderInventarioResultados(agrupados, q)}
      </div>
    </div>
  `;

  const input = $("#inpBuscarInventario");
  input.addEventListener("input", () => {
    state.inventarioQuery = input.value;
    const q2 = state.inventarioQuery.trim().toLowerCase();
    let res2 = [];
    if (q2) res2 = state.inventario.filter(i => i.producto.toLowerCase().includes(q2) || i.marca.toLowerCase().includes(q2) || i.categoria.toLowerCase().includes(q2));
    const grouped2 = {};
    res2.forEach(i => {
      if (!grouped2[i.producto]) grouped2[i.producto] = { producto:i.producto, marca:i.marca, categoria:i.categoria, precio:i.precio, sedes:[] };
      grouped2[i.producto].sedes.push(i);
    });
    $("#inventarioResultados").innerHTML = renderInventarioResultados(grouped2, q2);
    bindInventarioResultados();
  });
  input.focus();
  bindInventarioResultados();
}

function renderInventarioResultados(agrupados, q){
  const items = Object.values(agrupados);
  if (!q){
    return `<div class="empty-state"><strong>${t("startSearch")}</strong><span>${t("startSearchSub")}</span></div>`;
  }
  if (!items.length){
    return `<div class="empty-state"><strong>${t("noResults")}</strong><span>${t("noResultsSub")}</span></div>`;
  }
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead><tr>
          <th>${t("colProducto")}</th><th>${t("colCategoria")}</th><th>${t("colStockActual")}</th><th>${t("colPrecio")}</th><th>${t("colEstado")}</th><th></th>
        </tr></thead>
        <tbody>
          ${items.map(it => {
            const total = it.sedes.reduce((s,x) => s + x.stockActual, 0);
            const critico = it.sedes.some(x => x.stockActual <= x.stockMinimo);
            return `
            <tr class="is-clickable" data-producto="${escapeHTML(it.producto)}">
              <td><strong>${escapeHTML(it.producto)}</strong><br><span class="cell-em">${escapeHTML(it.marca)}</span></td>
              <td class="cell-muted">${escapeHTML(it.categoria)}</td>
              <td>${total}</td>
              <td>${formatoMoneda(it.precio)}</td>
              <td>${critico ? `<span class="badge badge-danger"><span class="badge-dot"></span>${t("critical")}</span>` : `<span class="badge badge-ok"><span class="badge-dot"></span>${t("ok")}</span>`}</td>
              <td><button class="btn-table" data-ver-stock="${escapeHTML(it.producto)}">${t("colSucursal")}</button></td>
            </tr>`;
          }).join("")}
        </tbody>
      </table>
    </div>
  `;
}
function bindInventarioResultados(){
  $$("[data-ver-stock]").forEach(b => b.addEventListener("click", (e) => { e.stopPropagation(); abrirModalStock(b.dataset.verStock); }));
  $$("tr[data-producto]").forEach(tr => tr.addEventListener("click", () => abrirModalStock(tr.dataset.producto)));
}

function abrirModalStock(producto){
  const sedes = state.inventario.filter(i => i.producto === producto);
  const total = sedes.reduce((s,x) => s + x.stockActual, 0);
  $("#modalStockContent").innerHTML = `
    <h3 class="modal-title">${escapeHTML(producto)}</h3>
    <p class="modal-desc">${t("stockDetailSub")}</p>
    <div class="table-wrap">
      <table class="data-table">
        <thead><tr><th>${t("colSucursal")}</th><th>${t("colStockActual")}</th><th>${t("colStockMinimo")}</th><th>${t("colEstado")}</th></tr></thead>
        <tbody>
          ${sedes.map(s => `
            <tr>
              <td>${escapeHTML(sucursalNombre(s.sucursalId))}</td>
              <td><strong>${s.stockActual}</strong></td>
              <td class="cell-muted">${s.stockMinimo}</td>
              <td>${s.stockActual <= s.stockMinimo ? `<span class="badge badge-danger"><span class="badge-dot"></span>${t("critical")}</span>` : `<span class="badge badge-ok"><span class="badge-dot"></span>${t("ok")}</span>`}</td>
            </tr>
          `).join("")}
          <tr><td><strong>${t("totalNetwork")}</strong></td><td colspan="3"><strong>${total}</strong></td></tr>
        </tbody>
      </table>
    </div>
    <div class="form-actions"><button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button></div>
  `;
  abrirModal("#modalStock");
}

/* ==========================================================================
   MÓDULO: PEDIDOS A PROVEEDORES (órdenes de compra / logística de arribo)
   ========================================================================== */
function estadoPedidoLabel(estado){
  return { solicitado:t("estSolicitado"), transito:t("estTransito"), patio:t("estPatio"), recibido:t("estRecibido"), cancelado:t("estCancelado") }[estado] || estado;
}
function estadoPedidoBadgeClass(estado){
  return { solicitado:"badge-solicitado", transito:"badge-transito", patio:"badge-patio", recibido:"badge-recibido", cancelado:"badge-cancelado" }[estado] || "badge-off";
}
function formatoFecha(iso){
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString(state.lang === "en" ? "en-US" : "es-MX", { day:"2-digit", month:"short", year:"numeric" });
}

function renderPedidos(){
  const main = $("#main");
  let lista = state.pedidos;
  if (state.pedidosEstadoFiltro !== "all") lista = lista.filter(p => p.estado === state.pedidosEstadoFiltro);
  lista = [...lista].sort((a,b) => new Date(b.fechaEmision) - new Date(a.fechaEmision));

  const pillEstados = ["all", ...PEDIDO_PIPELINE, "cancelado"];
  const pillLabel = { all:t("estAll"), solicitado:t("estSolicitado"), transito:t("estTransito"), patio:t("estPatio"), recibido:t("estRecibido"), cancelado:t("estCancelado") };

  main.innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA</p><h2>${t("pedidosTitle")}</h2></div>
        <div class="panel-heading-actions">
          <button class="btn btn-primary" id="btnNuevoPedido">${iconPlus()} ${t("newPedido")}</button>
        </div>
      </div>
      <p class="modal-desc" style="margin-top:-14px;">${t("pedidosSub")}</p>

      <div class="section-toolbar fade-in fade-in--1">
        <div class="filter-pills">
          ${pillEstados.map(es => `<button class="filter-pill ${state.pedidosEstadoFiltro===es?"is-active":""}" data-pfiltro="${es}">${pillLabel[es]}</button>`).join("")}
        </div>
      </div>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr>
            <th>${t("colFolio")}</th><th>${t("colProveedor")}</th><th>${t("colDestino")}</th>
            <th>${t("colVehiculos")}</th><th>${t("colETA")}</th><th>${t("colEstado")}</th><th>${t("colAcciones")}</th>
          </tr></thead>
          <tbody>
            ${lista.map(p => `
              <tr class="is-clickable" data-ver-pedido="${p.id}">
                <td><span class="folio-chip">${escapeHTML(p.folio)}</span></td>
                <td>${escapeHTML(p.proveedor)}</td>
                <td>${escapeHTML(sucursalNombre(p.sucursalId))}</td>
                <td><span class="vehiculo-count">${iconCar()} ${p.vehiculos.length}</span></td>
                <td class="cell-muted">${formatoFecha(p.fechaETA)}</td>
                <td><span class="badge ${estadoPedidoBadgeClass(p.estado)}"><span class="badge-dot"></span>${estadoPedidoLabel(p.estado)}</span></td>
                <td>
                  <div class="btn-table-row">
                    <button class="btn-table" data-ver-pedido-btn="${p.id}">${t("viewDetail")}</button>
                  </div>
                </td>
              </tr>
            `).join("") || `<tr><td colspan="7"><div class="empty-state"><strong>${t("noPedidos")}</strong><span>${t("noPedidosSub")}</span></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;

  $("#btnNuevoPedido").addEventListener("click", () => abrirModalPedido());
  $$("[data-pfiltro]").forEach(b => b.addEventListener("click", () => { state.pedidosEstadoFiltro = b.dataset.pfiltro; renderPedidos(); }));
  $$("[data-ver-pedido], [data-ver-pedido-btn]").forEach(el => el.addEventListener("click", (e) => {
    const id = el.dataset.verPedido || el.dataset.verPedidoBtn;
    e.stopPropagation();
    abrirModalPedidoDetalle(id);
  }));
}

/* ----- Formulario de alta / edición (identificación + vehículos dinámicos) ----- */
function filaVehiculoHTML(idx, v = {}){
  return `
    <div class="vehiculo-row" data-vrow="${idx}">
      <button type="button" class="vehiculo-row-remove" data-remove-vehiculo="${idx}" title="${t("cancel")}">×</button>
      <div class="vehiculo-row-index">${t("vehiculoN")} ${idx + 1}</div>
      <div class="form-grid">
        <div class="form-field"><label>${t("fModeloV")} *</label><input type="text" name="modelo" required value="${escapeHTML(v.modelo || "")}"></div>
        <div class="form-field"><label>${t("fAnio")}</label><input type="number" name="anio" value="${v.anio || new Date().getFullYear()}"></div>
        <div class="form-field"><label>${t("fVersion")}</label><input type="text" name="version" value="${escapeHTML(v.version || "")}"></div>
        <div class="form-field"><label>${t("fVin")} *</label><input type="text" name="vin" required value="${escapeHTML(v.vin || "")}"></div>
        <div class="form-field"><label>${t("fColorExt")}</label><input type="text" name="colorExterior" value="${escapeHTML(v.colorExterior || "")}"></div>
        <div class="form-field"><label>${t("fColorInt")}</label><input type="text" name="colorInterior" value="${escapeHTML(v.colorInterior || "")}"></div>
        <div class="form-field span-2"><label>${t("fEquipamiento")}</label><input type="text" name="equipamiento" value="${escapeHTML(v.equipamiento || "")}"></div>
        <div class="form-field"><label>${t("fCostoAdq")} *</label><input type="number" min="0" name="costoAdquisicion" required value="${v.costoAdquisicion || ""}"></div>
        <div class="form-field"><label>${t("fPrecioProyectado")} *</label><input type="number" min="0" name="precioProyectado" required value="${v.precioProyectado || ""}"></div>
      </div>
    </div>
  `;
}
function leerFilasVehiculos(form){
  return $$(".vehiculo-row", form).map(row => ({
    modelo: $("[name=modelo]", row).value.trim(),
    anio: Number($("[name=anio]", row).value) || new Date().getFullYear(),
    version: $("[name=version]", row).value.trim(),
    vin: $("[name=vin]", row).value.trim().toUpperCase(),
    colorExterior: $("[name=colorExterior]", row).value.trim(),
    colorInterior: $("[name=colorInterior]", row).value.trim(),
    equipamiento: $("[name=equipamiento]", row).value.trim(),
    costoAdquisicion: Number($("[name=costoAdquisicion]", row).value) || 0,
    precioProyectado: Number($("[name=precioProyectado]", row).value) || 0,
  })).filter(v => v.modelo && v.vin);
}

function abrirModalPedido(id){
  const editando = !!id;
  const p = editando ? state.pedidos.find(x => x.id === id) : null;
  let vehiculoIdx = p ? p.vehiculos.length : 1;

  $("#modalPedidoContent").innerHTML = `
    <h3 class="modal-title">${editando ? t("formPedidoEditTitle") : t("formPedidoNewTitle")}</h3>
    <p class="modal-desc">${t("formPedidoDesc")}</p>
    <form id="formPedido">
      <div class="form-grid" style="margin-bottom:6px;">
        ${editando ? `<div class="form-field"><label>${t("colFolio")}</label><input type="text" value="${escapeHTML(p.folio)}" disabled></div>` : ""}
        <div class="form-field ${editando ? "" : "span-2"}"><label>${t("fProveedor")} *</label><input type="text" name="proveedor" required value="${p ? escapeHTML(p.proveedor) : ""}" placeholder="Porsche AG, Audi de México, Ferrari SpA…"></div>
        <div class="form-field"><label>${t("fDestino")} *</label>
          <select name="sucursalId" required>
            ${state.sucursales.map(s => `<option value="${s.id}" ${p && p.sucursalId===s.id?"selected":""}>${escapeHTML(s.nombre)}</option>`).join("")}
          </select>
        </div>
        <div class="form-field"><label>${t("fFechaEmision")} *</label><input type="date" name="fechaEmision" required value="${p ? p.fechaEmision.slice(0,10) : new Date().toISOString().slice(0,10)}"></div>
        <div class="form-field"><label>${t("fFechaETA")} *</label><input type="date" name="fechaETA" required value="${p ? p.fechaETA.slice(0,10) : ""}"></div>
      </div>

      <div class="panel-heading" style="margin:20px 0 4px;">
        <h2 style="font-size:16px;">${t("vehiculosSectionTitle")}</h2>
      </div>
      <div class="vehiculo-rows" id="vehiculoRows">
        ${p ? p.vehiculos.map((v,i) => filaVehiculoHTML(i, v)).join("") : filaVehiculoHTML(0)}
      </div>
      <button type="button" class="btn-add-vehiculo" id="btnAddVehiculo">${iconPlus()} ${t("addVehiculo")}</button>

      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("cancel")}</button>
        <button type="submit" class="btn btn-primary">${editando ? t("saveChanges") : t("save")}</button>
      </div>
    </form>
  `;

  const form = $("#formPedido");
  const rowsWrap = $("#vehiculoRows");

  function bindRemoveButtons(){
    $$("[data-remove-vehiculo]", rowsWrap).forEach(btn => btn.addEventListener("click", () => {
      if ($$(".vehiculo-row", rowsWrap).length <= 1) return; // al menos un vehículo
      btn.closest(".vehiculo-row").remove();
    }));
  }
  bindRemoveButtons();

  $("#btnAddVehiculo").addEventListener("click", () => {
    rowsWrap.insertAdjacentHTML("beforeend", filaVehiculoHTML(vehiculoIdx++));
    bindRemoveButtons();
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const vehiculos = leerFilasVehiculos(form);
    if (!vehiculos.length){ mostrarToast(t("minOneVehicle"), "err"); return; }
    const payload = {
      proveedor: fd.get("proveedor").trim(),
      sucursalId: fd.get("sucursalId"),
      fechaEmision: new Date(fd.get("fechaEmision")).toISOString(),
      fechaETA: new Date(fd.get("fechaETA")).toISOString(),
      vehiculos,
    };
    if (editando){
      await DB.updatePedido(id, payload);
      Object.assign(p, payload);
      mostrarToast(t("toastPedidoUpdated"), "ok");
    }else{
      const nuevo = await DB.createPedido(payload);
      state.pedidos.push(nuevo);
      mostrarToast(t("toastPedidoCreated"), "ok");
    }
    cerrarModales();
    if (state.view === "pedidos") renderPedidos();
  });

  abrirModal("#modalPedido");
}

/* ----- Detalle del pedido: pipeline de estados + acciones ----- */
function renderPipelineHTML(estado){
  if (estado === "cancelado"){
    return `
      <div class="pipeline is-cancelado">
        <div class="pipeline-line"></div>
        ${PEDIDO_PIPELINE.map(es => `
          <div class="pipeline-step">
            <div class="pipeline-dot">✕</div>
            <div class="pipeline-label">${estadoPedidoLabel(es)}</div>
          </div>
        `).join("")}
      </div>
      <p class="modal-desc" style="color:var(--red); font-weight:600;">${t("estCancelado")}</p>
    `;
  }
  const idxActual = PEDIDO_PIPELINE.indexOf(estado);
  const fillPct = idxActual <= 0 ? 0 : (idxActual / (PEDIDO_PIPELINE.length - 1)) * 100;
  return `
    <div class="pipeline">
      <div class="pipeline-line"></div>
      <div class="pipeline-line-fill" style="width:${fillPct}%"></div>
      ${PEDIDO_PIPELINE.map((es, i) => `
        <div class="pipeline-step ${i < idxActual ? "is-done" : i === idxActual ? "is-current" : ""}">
          <div class="pipeline-dot">${i < idxActual ? "✓" : i + 1}</div>
          <div class="pipeline-label">${estadoPedidoLabel(es)}</div>
        </div>
      `).join("")}
    </div>
  `;
}

function abrirModalPedidoDetalle(id){
  const p = state.pedidos.find(x => x.id === id);
  if (!p) return;
  const idxActual = PEDIDO_PIPELINE.indexOf(p.estado);
  const siguienteEstado = p.estado !== "cancelado" && idxActual > -1 && idxActual < PEDIDO_PIPELINE.length - 1 ? PEDIDO_PIPELINE[idxActual + 1] : null;
  const puedeRecibir = p.estado === "patio";
  const puedeAvanzar = siguienteEstado && !puedeRecibir;
  const puedeCancelar = p.estado !== "recibido" && p.estado !== "cancelado";

  $("#modalPedidoDetalleContent").innerHTML = `
    <div style="display:flex; align-items:center; gap:10px; margin-bottom:4px; flex-wrap:wrap;">
      <span class="folio-chip">${escapeHTML(p.folio)}</span>
      <span class="badge ${estadoPedidoBadgeClass(p.estado)}"><span class="badge-dot"></span>${estadoPedidoLabel(p.estado)}</span>
    </div>
    <h3 class="modal-title">${escapeHTML(p.proveedor)}</h3>
    <p class="modal-desc">${escapeHTML(sucursalNombre(p.sucursalId))} · ${t("colEmision")}: ${formatoFecha(p.fechaEmision)} · ${t("colETA")}: ${formatoFecha(p.fechaETA)}${p.fechaRecepcion ? ` · ${t("colRecepcion")}: ${formatoFecha(p.fechaRecepcion)}` : ""}</p>

    ${renderPipelineHTML(p.estado)}

    ${puedeRecibir ? `
    <div class="receive-banner">
      <div class="receive-banner-text">
        <strong>${t("dbImpactTitle")}</strong>
        <span>${t("dbImpactDesc")}</span>
      </div>
      <button class="btn btn-primary btn-sm" id="btnConfirmarRecepcion">${iconCheck()} ${t("confirmReception")}</button>
    </div>` : ""}

    <div class="panel-heading" style="margin:18px 0 10px;"><h2 style="font-size:16px;">${t("vehiculosSectionTitle")} (${p.vehiculos.length})</h2></div>
    ${p.vehiculos.map(v => `
      <div class="vehiculo-detail-card">
        <div class="vehiculo-detail-head">
          <span class="vehiculo-detail-title">${escapeHTML(v.marca)} ${escapeHTML(v.modelo)} ${v.anio || ""}</span>
          <span class="vehiculo-detail-vin">${escapeHTML(v.vin)}</span>
        </div>
        <div class="vehiculo-detail-grid">
          <div><span>${t("fVersion")}</span><strong>${escapeHTML(v.version || "—")}</strong></div>
          <div><span>${t("fColorExt")}</span><strong>${escapeHTML(v.colorExterior || "—")}</strong></div>
          <div><span>${t("fColorInt")}</span><strong>${escapeHTML(v.colorInterior || "—")}</strong></div>
          <div><span>${t("unitCost")}</span><strong>${formatoMoneda(v.costoAdquisicion)}</strong></div>
          <div><span>${t("projectedPrice")}</span><strong>${formatoMoneda(v.precioProyectado)}</strong></div>
        </div>
      </div>
    `).join("")}

    <div class="form-actions" style="justify-content:space-between; margin-top:24px;">
      <div class="btn-table-row">
        ${puedeCancelar ? `<button type="button" class="btn btn-outline btn-sm" id="btnCancelarPedido">${t("cancelOrder")}</button>` : ""}
        ${p.estado !== "recibido" && p.estado !== "cancelado" ? `<button type="button" class="btn btn-ghost btn-sm" id="btnEditarPedido">${t("edit")}</button>` : ""}
      </div>
      <div class="btn-table-row">
        ${puedeAvanzar ? `<button type="button" class="btn btn-primary btn-sm" id="btnAvanzarPedido">${t("advance")}: ${estadoPedidoLabel(siguienteEstado)}</button>` : ""}
        <button type="button" class="btn btn-ghost btn-sm" data-close-modal>${t("close")}</button>
      </div>
    </div>
  `;

  $("#btnAvanzarPedido")?.addEventListener("click", async () => {
    await DB.setPedidoEstado(p.id, siguienteEstado);
    p.estado = siguienteEstado;
    mostrarToast(t("toastPedidoAdvanced"), "ok");
    abrirModalPedidoDetalle(p.id);
    if (state.view === "pedidos") renderPedidos();
  });

  $("#btnConfirmarRecepcion")?.addEventListener("click", async () => {
    const { afectados } = await DB.confirmarRecepcion(p.id);
    // Sincroniza el inventario local con lo que "escribió" la BD simulada
    afectados.forEach(item => {
      const local = state.inventario.find(i => i.id === item.id);
      if (local) Object.assign(local, item);
      else state.inventario.push({ ...item });
    });
    mostrarToast(t("toastStockUpdated").replace("{n}", afectados.length).replace("{sucursal}", sucursalNombre(p.sucursalId)), "ok");
    abrirModalPedidoDetalle(p.id);
    if (state.view === "pedidos") renderPedidos();
    if (state.view === "inventario") renderInventario();
  });

  $("#btnCancelarPedido")?.addEventListener("click", async () => {
    await DB.setPedidoEstado(p.id, "cancelado");
    p.estado = "cancelado";
    mostrarToast(t("toastPedidoCancelled"), "ok");
    abrirModalPedidoDetalle(p.id);
    if (state.view === "pedidos") renderPedidos();
  });

  $("#btnEditarPedido")?.addEventListener("click", () => { cerrarModales(); abrirModalPedido(p.id); });

  abrirModal("#modalPedidoDetalle");
}

/* ==========================================================================
   MODAL: alta rápida de artículo (Quick Action)
   ========================================================================== */
function abrirModalArticulo(){
  $("#modalArticuloContent").innerHTML = `
    <h3 class="modal-title">${t("formArticuloTitle")}</h3>
    <p class="modal-desc">${t("formArticuloDesc")}</p>
    <form id="formArticulo">
      <div class="form-field span-2" style="margin-bottom:16px;">
        <label>${t("fTipo")}</label>
        <div class="segmented">
          <button type="button" class="segmented-btn is-active" data-tipo="Vehiculo">${t("tipoVehiculo")}</button>
          <button type="button" class="segmented-btn" data-tipo="Refaccion">${t("tipoRefaccion")}</button>
        </div>
        <input type="hidden" name="tipo" value="Vehiculo">
      </div>
      <div class="form-grid">
        <div class="form-field"><label>${t("fMarca")} *</label><input type="text" name="marca" required></div>
        <div class="form-field"><label>${t("fModelo")} *</label><input type="text" name="producto" required></div>
        <div class="form-field"><label>${t("fCategoria")} *</label><input type="text" name="categoria" required placeholder="Autos deportivos, SUV de lujo, Motocicletas, Refacciones…"></div>
        <div class="form-field"><label>${t("fBranch")} *</label>
          <select name="sucursalId" required>
            ${state.sucursales.map(s => `<option value="${s.id}">${escapeHTML(s.nombre)}</option>`).join("")}
          </select>
        </div>
        <div class="form-field"><label>${t("fStockInicial")}</label><input type="number" min="0" name="stockActual" value="1"></div>
        <div class="form-field"><label>${t("fStockMin")}</label><input type="number" min="0" name="stockMinimo" value="2"></div>
        <div class="form-field span-2"><label>${t("fPrecioVenta")} *</label><input type="number" min="0" name="precio" required></div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("cancel")}</button>
        <button type="submit" class="btn btn-primary">${t("save")}</button>
      </div>
    </form>
  `;
  const form = $("#formArticulo");
  $$(".segmented-btn", form).forEach(btn => btn.addEventListener("click", () => {
    $$(".segmented-btn", form).forEach(b => b.classList.remove("is-active"));
    btn.classList.add("is-active");
    form.tipo.value = btn.dataset.tipo;
  }));
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const payload = {
      sucursalId: fd.get("sucursalId"),
      producto: fd.get("producto").trim(),
      marca: fd.get("marca").trim(),
      categoria: fd.get("categoria").trim(),
      precio: Number(fd.get("precio")) || 0,
      stockActual: Number(fd.get("stockActual")) || 0,
      stockMinimo: Number(fd.get("stockMinimo")) || 0,
    };
    const nuevo = await DB.createInventarioItem(payload);
    state.inventario.push(nuevo);
    mostrarToast(t("toastArticuloCreated"), "ok");
    cerrarModales();
    if (state.view === "dashboard") renderDashboard();
    if (state.view === "inventario") renderInventario();
  });
  abrirModal("#modalArticulo");
}

/* ==========================================================================
   ICONOS SVG (inline, sin dependencias externas)
   ========================================================================== */
function iconBuilding(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M4 21V6.2L12 3l8 3.2V21"/><path d="M9 21v-6h6v6"/><path d="M9 10h.01M9 14h.01M15 10h.01M15 14h.01"/></svg>`; }
function iconCar(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M3 13l1.6-5A2 2 0 0 1 6.5 6.5h11a2 2 0 0 1 1.9 1.5L21 13"/><rect x="3" y="13" width="18" height="5.5" rx="1.5"/><circle cx="7.5" cy="18.5" r="1.4"/><circle cx="16.5" cy="18.5" r="1.4"/></svg>`; }
function iconUsers(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="9" cy="8" r="3.2"/><path d="M2.6 20a6.4 6.4 0 0 1 12.8 0"/><circle cx="17.5" cy="9" r="2.6"/><path d="M15.2 13.5a5.6 5.6 0 0 1 6.2 5.6"/></svg>`; }
function iconClock(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></svg>`; }
function iconCoin(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="8.5"/><path d="M9 15c.4 1 1.4 1.6 2.6 1.6 1.6 0 2.8-.8 2.8-2s-1-1.7-2.7-2c-1.7-.3-2.8-.9-2.8-2.1 0-1.2 1.2-2 2.8-2 1.2 0 2.1.5 2.6 1.5M12 7.3V16.7"/></svg>`; }
function iconBox(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M3.5 7.5 12 3l8.5 4.5V16.5L12 21l-8.5-4.5Z"/><path d="M3.7 7.7 12 12l8.3-4.3M12 12v9"/></svg>`; }
function iconAlert(){ return `<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3 2 20h20L12 3Z"/><path d="M12 10v4.2M12 17.2h.01"/></svg>`; }
function iconInfo(){ return `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.6h.01"/></svg>`; }
function iconPlus(){ return `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M12 5v14M5 12h14"/></svg>`; }
function iconCheck(){ return `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M4 12.5l5 5L20 6.5"/></svg>`; }
function iconErr(){ return `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M5 5l14 14M19 5L5 19"/></svg>`; }

/* ==========================================================================
   MODALES / TOASTS
   ========================================================================== */
function abrirModal(sel){ $(sel).classList.add("is-open"); }
function cerrarModales(){ $$(".modal-overlay").forEach(m => m.classList.remove("is-open")); }
function mostrarToast(mensaje, tipo = "ok"){
  const stack = $("#toastStack");
  const el = document.createElement("div");
  el.className = `toast toast-${tipo}`;
  el.innerHTML = `<span class="toast-icon">${tipo === "ok" ? iconCheck() : iconErr()}</span><span>${escapeHTML(mensaje)}</span>`;
  stack.appendChild(el);
  setTimeout(() => {
    el.classList.add("is-leaving");
    setTimeout(() => el.remove(), 260);
  }, 2600);
}

/* ==========================================================================
   RELOJ / FECHA
   ========================================================================== */
function actualizarReloj(){
  const now = new Date();
  const fechaEl = $("#statusFecha"), horaEl = $("#statusHora");
  if (fechaEl) fechaEl.textContent = now.toLocaleDateString(state.lang === "en" ? "en-US" : "es-MX", { day:"2-digit", month:"short", year:"numeric" });
  if (horaEl) horaEl.textContent = now.toLocaleTimeString(state.lang === "en" ? "en-US" : "es-MX", { hour:"2-digit", minute:"2-digit" });
}

/* ==========================================================================
   TEMA / IDIOMA
   ========================================================================== */
function toggleTema(){
  document.body.classList.toggle("dark");
  if (state.view === "dashboard") renderDashboard(); // redibuja gráficas con la paleta correcta
}
function toggleIdioma(){
  state.lang = state.lang === "es" ? "en" : "es";
  $$(".lang-op").forEach(el => el.classList.toggle("is-active", el.dataset.lang === state.lang));
  renderMain();
}
function applyI18n(){
  $$("[data-i18n]").forEach(el => { el.textContent = t(el.dataset.i18n); });
  $$("[data-i18n-title]").forEach(el => { el.title = t(el.dataset.i18nTitle); });
}

/* ==========================================================================
   SESIÓN
   ========================================================================== */
function cerrarSesion(){
  const btn = $("#logoutBtn");
  btn.disabled = true;
  mostrarToast(state.lang === "en" ? "Session closed" : "Sesión cerrada", "ok");
  $("#statusSesion").textContent = state.lang === "en" ? "Closed" : "Cerrada";
  $("#statusSesion").classList.remove("status-value--ok");
  setTimeout(() => { btn.disabled = false; }, 1200);
}

/* ==========================================================================
   EVENTOS GLOBALES
   ========================================================================== */
function initEventosGlobales(){
  $("#logoHome").addEventListener("click", () => { state.view = "dashboard"; renderMain(); });
  $("#themeToggle").addEventListener("click", toggleTema);
  $("#langToggle").addEventListener("click", toggleIdioma);
  $("#logoutBtn").addEventListener("click", cerrarSesion);

  $("#subNav").addEventListener("click", (e) => {
    const btn = e.target.closest(".sub-nav-btn");
    if (!btn) return;
    state.view = btn.dataset.view;
    renderMain();
  });

  $("#sucursalSelect").addEventListener("change", (e) => {
    state.sucursalFiltro = e.target.value;
    renderMain();
  });

  $$(".modal-overlay").forEach(overlay => overlay.addEventListener("click", (e) => { if (e.target === overlay) cerrarModales(); }));
  document.addEventListener("click", (e) => { if (e.target.closest("[data-close-modal]")) cerrarModales(); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape") cerrarModales(); });

  setInterval(actualizarReloj, 1000 * 30);
  actualizarReloj();
}

/* ==========================================================================
   INICIALIZACIÓN
   ========================================================================== */
document.addEventListener("DOMContentLoaded", async () => {
  initEventosGlobales();
  await cargarDatos();
  poblarSelectorSucursales();
  renderMain();
});
