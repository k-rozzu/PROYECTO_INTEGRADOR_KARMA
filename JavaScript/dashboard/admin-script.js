/* ==========================================================================
   KARMA · Punto de Venta — Panel de Administrador General
   admin-script.js

   Todo el acceso a datos pasa por el objeto `DB`, que llama a la API PHP
   (PHP/Dashboard/api.php). Cada vista se dibuja con una función render*()
   a partir de los datos guardados en `state`.
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
    recentSales:"Monitor transaccional en vivo", recentSalesSub:"Últimas operaciones completadas",
    colFecha:"Fecha / hora", colSucursal:"Sucursal", colResponsable:"Cajero / cliente", colProductos:"Producto(s)", colTotal:"Total",
    criticalStock:"Monitor de stock crítico", criticalStockSub:"Existencias en o por debajo del mínimo",
    criticalEmpty:"Sin alertas de stock crítico en este momento.",
    quickTitle:"Accesos rápidos",
    qaSucursal:"Nueva sucursal", qaSucursalSub:"Registrar sede", qaArticulo:"Nuevo vehículo / artículo", qaArticuloSub:"Alta de inventario",
    qaPersonal:"Gestionar personal", qaPersonalSub:"Ir a personal", qaHistorial:"Historial de transacciones", qaHistorialSub:"Ver ventas consolidadas",
    sucursalesTitle:"Sucursales", sucursalesSub:"Gestión centralizada de sedes (alta, edición y baja)",
    newSucursal:"Nueva sucursal", filterAll:"Todas", filterActive:"Activas", filterInactive:"Inactivas",
    colNombre:"Nombre", colDireccion:"Dirección", colTelefono:"Teléfono", colGerente:"Gerente a cargo",
    colCajas:"Cajas activas", colEstado:"Estado", colAcciones:"Acciones", edit:"Editar", deactivate:"Desactivar", activate:"Activar",
    noGerente:"Sin asignar",
    formSucursalNewTitle:"Registrar nueva sucursal", formSucursalEditTitle:"Editar sucursal",
    formSucursalDesc:"Los campos marcados son obligatorios. El estatus controla si la sede puede operar ventas.",
    fName:"Nombre de la sucursal", fAddress:"Dirección física", fPhone:"Teléfono", fEmail:"Correo de contacto",
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
    hintDB:"Vista conectada a la base de datos pos_multisede (MySQL).",
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

    navCatalogo:"Catálogo", navVentas:"Ventas", navCortes:"Cortes de caja", navAuditoria:"Auditoría", helpBtn:"F1 · Ayuda",
    kpiStock:"Unidades en stock", daysSupply:"≈ {n} días de inventario", avgAging:"antigüedad prom. {n} d", agedUnits:"{n} rezagada(s) +90 d",
    kpiMargen:"Margen bruto promedio", perUnit:"por venta · últimos 6 meses", noCostData:"Sin costos capturados",
    kpiFI:"Penetración financiera (F&I)", fiSub:"{c} a crédito · {d} de contado",
    kpiSedes:"Sedes operativas", kpiPersonalActivo:"Personal activo", registersOpen:"{n} caja(s) abierta(s) en turno",
    chartByCategory:"Ingresos vs. unidades por categoría", chartByCategorySub:"Últimos 6 meses",
    colAsesor:"Asesor", colModelo:"Modelo", colVin:"VIN", colMonto:"Monto",
    fRazonSocial:"Razón social", fDireccionFiscal:"Dirección fiscal", fContacto:"Contacto operativo",
    cajasBtn:"Cajas", cajasTitle:"Cajas y terminales · {s}", cajasDesc:"Autoriza, cierra o bloquea cada terminal de cobro de la sede.",
    colCaja:"Caja", colTicketsHoy:"Tickets hoy", colTotalHoy:"Cobrado hoy", colUltimaVenta:"Última venta",
    cajaAbierta:"Abierta", cajaCerrada:"Cerrada", cajaMant:"Mantenimiento", toastCaja:"Estado de caja actualizado",
    noCajas:"Esta sucursal no tiene cajas registradas.",
    relocate:"Reubicar", relocateTitle:"Reubicar gerente", relocateDesc:"Traslada al gerente a otra agencia; el cambio queda registrado en la auditoría.",
    fNewPassword:"Nueva contraseña (opcional)", newPasswordHint:"Déjalo vacío para conservar la contraseña actual.",
    toastUsuarioEstado:"Estatus de usuario actualizado",
    catalogoTitle:"Catálogo maestro de modelos", catalogoSub:"Definición corporativa de líneas, carrocerías, equipamiento base y precios de lista",
    newModelo:"Nuevo modelo", colCarroceria:"Carrocería", colPrecioLista:"Precio de lista",
    formModeloNewTitle:"Registrar modelo", formModeloEditTitle:"Editar modelo",
    formModeloDesc:"Los cambios de precio de lista quedan registrados en la auditoría.",
    fCarroceria:"Carrocería", fPrecioLista:"Precio de lista recomendado",
    toastModeloCreated:"Modelo agregado al catálogo", toastModeloUpdated:"Modelo actualizado", toastModeloEstado:"Estatus del modelo actualizado",
    searchCatalogo:"Buscar marca, modelo o carrocería…",
    colAntiguedad:"Días en patio", priceFormTitle:"Precio base y costo", fPrecioBase:"Precio base", fCosto:"Costo de adquisición",
    toastPrecio:"Precio actualizado (registrado en auditoría)",
    ventasTitle:"Historial consolidado de ventas", ventasSub:"Todas las ventas emitidas con su método de liquidación, folios y comprobantes",
    filterContado:"Contado", filterCredito:"Crédito", searchVentas:"Buscar folio, cliente, VIN o modelo…",
    colMetodo:"Liquidación", colCliente:"Cliente", reissue:"Comprobante", totalFiltered:"{n} venta(s) · {t}",
    ticketTitle:"Ticket de venta", contractTitle:"Contrato de compraventa a crédito", print:"Imprimir",
    colCantidad:"Cant.", colPrecioU:"Precio", colSubtotal:"Subtotal", efectivoRecibido:"Recibido", cambio:"Cambio",
    enganche:"Enganche", adeudo:"Saldo financiado", abono:"Abono", plazos:"Plazos", cajaN:"Caja {n}",
    signCliente:"Firma del cliente", signAsesor:"Firma del asesor",
    cortesTitle:"Arqueos y cortes por terminal", cortesSub:"Resumen de cada turno: apertura (primer ticket), corte (último ticket) y efectivo esperado en caja",
    colDia:"Día", colCajeros:"Cajero(s)", colApertura:"Apertura", colCorte:"Corte", colTickets:"Tickets",
    colContado:"Contado", colCredito:"Crédito", colEfectivo:"Efectivo esperado", noCortes:"Aún no hay ventas registradas.",
    auditoriaTitle:"Auditoría de actividad", auditoriaSub:"Quién hizo cada cambio en sucursales, personal, catálogos, precios y pedidos",
    searchAuditoria:"Buscar usuario, acción o detalle…", colAccion:"Acción", colDetalle:"Detalle", noAuditoria:"Sin movimientos registrados.",
    helpTitle:"Atajos de teclado", helpDesc:"Navega por el panel sin usar el ratón.", kConsole:"Abrir consola rápida", kHelp:"Ayuda",
    consoleTitle:"Consola rápida", consolePlaceholder:"Escribe un comando: ventas, nueva sucursal…",
    consoleHint:"↑ ↓ para elegir · Enter ejecuta · Esc cierra",
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
    recentSales:"Live transaction monitor", recentSalesSub:"Latest completed operations",
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
    fName:"Branch name", fAddress:"Street address", fPhone:"Phone", fEmail:"Contact email",
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
    hintDB:"View connected to the pos_multisede database (MySQL).",
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

    navCatalogo:"Catalog", navVentas:"Sales", navCortes:"Cash closings", navAuditoria:"Audit trail", helpBtn:"F1 · Help",
    kpiStock:"Units in stock", daysSupply:"≈ {n} days of supply", avgAging:"avg. age {n} d", agedUnits:"{n} aged 90+ d",
    kpiMargen:"Average front-end gross", perUnit:"per sale · last 6 months", noCostData:"No cost data yet",
    kpiFI:"Finance penetration (F&I)", fiSub:"{c} financed · {d} cash",
    kpiSedes:"Operating branches", kpiPersonalActivo:"Active staff", registersOpen:"{n} register(s) open on shift",
    chartByCategory:"Revenue vs. units by category", chartByCategorySub:"Last 6 months",
    colAsesor:"Advisor", colModelo:"Model", colVin:"VIN", colMonto:"Amount",
    fRazonSocial:"Legal name", fDireccionFiscal:"Tax address", fContacto:"Operations contact",
    cajasBtn:"Registers", cajasTitle:"Registers & terminals · {s}", cajasDesc:"Authorize, close or lock every payment terminal at this branch.",
    colCaja:"Register", colTicketsHoy:"Tickets today", colTotalHoy:"Collected today", colUltimaVenta:"Last sale",
    cajaAbierta:"Open", cajaCerrada:"Closed", cajaMant:"Maintenance", toastCaja:"Register status updated",
    noCajas:"This branch has no registers yet.",
    relocate:"Relocate", relocateTitle:"Relocate manager", relocateDesc:"Move the manager to another branch; the change is logged in the audit trail.",
    fNewPassword:"New password (optional)", newPasswordHint:"Leave empty to keep the current password.",
    toastUsuarioEstado:"User status updated",
    catalogoTitle:"Master model catalog", catalogoSub:"Corporate definition of lines, body styles, base equipment and list prices",
    newModelo:"New model", colCarroceria:"Body style", colPrecioLista:"List price",
    formModeloNewTitle:"Register model", formModeloEditTitle:"Edit model",
    formModeloDesc:"List price changes are recorded in the audit trail.",
    fCarroceria:"Body style", fPrecioLista:"Recommended list price",
    toastModeloCreated:"Model added to catalog", toastModeloUpdated:"Model updated", toastModeloEstado:"Model status updated",
    searchCatalogo:"Search make, model or body style…",
    colAntiguedad:"Days in yard", priceFormTitle:"Base price & cost", fPrecioBase:"Base price", fCosto:"Acquisition cost",
    toastPrecio:"Price updated (logged in audit trail)",
    ventasTitle:"Consolidated sales history", ventasSub:"Every sale issued with its settlement method, folios and receipts",
    filterContado:"Cash", filterCredito:"Financed", searchVentas:"Search folio, client, VIN or model…",
    colMetodo:"Settlement", colCliente:"Client", reissue:"Receipt", totalFiltered:"{n} sale(s) · {t}",
    ticketTitle:"Sales ticket", contractTitle:"Installment sales contract", print:"Print",
    colCantidad:"Qty.", colPrecioU:"Price", colSubtotal:"Subtotal", efectivoRecibido:"Received", cambio:"Change",
    enganche:"Down payment", adeudo:"Financed balance", abono:"Installment", plazos:"Terms", cajaN:"Register {n}",
    signCliente:"Client signature", signAsesor:"Advisor signature",
    cortesTitle:"Register counts & closings", cortesSub:"Summary of each shift: opening (first ticket), closing (last ticket) and expected cash in drawer",
    colDia:"Day", colCajeros:"Cashier(s)", colApertura:"Opening", colCorte:"Closing", colTickets:"Tickets",
    colContado:"Cash sales", colCredito:"Financed", colEfectivo:"Expected cash", noCortes:"No sales recorded yet.",
    auditoriaTitle:"Activity audit trail", auditoriaSub:"Who made each change to branches, staff, catalogs, prices and orders",
    searchAuditoria:"Search user, action or detail…", colAccion:"Action", colDetalle:"Detail", noAuditoria:"No activity recorded.",
    helpTitle:"Keyboard shortcuts", helpDesc:"Navigate the panel without using the mouse.", kConsole:"Open quick console", kHelp:"Help",
    consoleTitle:"Quick console", consolePlaceholder:"Type a command: sales, new branch…",
    consoleHint:"↑ ↓ to choose · Enter runs · Esc closes",
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
   CAPA DE DATOS (DB) — API PHP en PHP/Dashboard/api.php (MySQL pos_multisede)
   ========================================================================== */
const API_BASE = "../PHP/Dashboard/api.php"; // relativa a dasboard/admin.html
const AUTH_URL = "../PHP/Login/auth.php";
const LOGIN_URL = "../index.html";
const HOME_URL = "../Home/home.html";

// Llama a una acción de la API; con `datos` hace POST JSON. Muestra un toast y lanza error si falla.
async function api(accion, datos, id){
  const url = `${API_BASE}?action=${encodeURIComponent(accion)}` + (id ? `&id=${encodeURIComponent(id)}` : "");
  const opciones = datos === undefined ? {} : {
    method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(datos)
  };
  let json = null, status = 0;
  try{
    const respuesta = await fetch(url, opciones);
    status = respuesta.status;
    json = await respuesta.json();
  }catch(err){
    console.error("Error de red / respuesta no JSON", err);
  }
  if (!json || !json.ok){
    const mensaje = json?.error || (state.lang === "en" ? "Could not connect to the server" : "No se pudo conectar con el servidor");
    mostrarToast(mensaje, "err");
    // 401 = sin sesión → login; 403 = rol sin permiso → Home
    if (status === 401) setTimeout(() => window.location.replace(LOGIN_URL), 1200);
    if (status === 403) setTimeout(() => window.location.replace(HOME_URL), 1200);
    throw new Error(mensaje);
  }
  return json.data;
}

const DB = {
  getSucursales(){ return api("sucursales"); },
  createSucursal(payload){ return api("crear_sucursal", payload); },
  updateSucursal(id, payload){ return api("actualizar_sucursal", payload, id); },
  setSucursalEstado(id, estado){ return api("estado_sucursal", { estado }, id); },

  getCajas(){ return api("cajas"); },
  setCajaEstado(id, estado){ return api("estado_caja", { estado }, id); },

  getUsuarios(){ return api("usuarios"); },
  // La contraseña se hashea en el servidor con password_hash()
  createUsuario(payload){ return api("crear_usuario", payload); },
  updateUsuario(id, payload){ return api("actualizar_usuario", payload, id); },
  setUsuarioEstado(id, estado){ return api("estado_usuario", { estado }, id); },

  getCatalogo(){ return api("catalogo"); },
  createModelo(payload){ return api("crear_modelo", payload); },
  updateModelo(id, payload){ return api("actualizar_modelo", payload, id); },
  setModeloEstado(id, estado){ return api("estado_modelo", { estado }, id); },

  getInventario(){ return api("inventario"); },
  createInventarioItem(payload){ return api("crear_articulo", payload); },
  updatePrecioProducto(payload){ return api("precio_producto", payload); },

  getVentas(){ return api("ventas"); },
  getVentaDetalle(id){ return api("venta_detalle", undefined, id); },
  getCortes(){ return api("cortes"); },
  getAuditoria(){ return api("auditoria"); },
  setIdioma(idioma){ return api("idioma", { idioma }); },

  getPedidos(){ return api("pedidos"); },
  createPedido(payload){ return api("crear_pedido", payload); },
  updatePedido(id, payload){ return api("actualizar_pedido", payload, id); },
  setPedidoEstado(id, estado){ return api("estado_pedido", { estado }, id); },
  /**
   * Confirma la recepción del pedido: en el servidor incrementa stock_actual
   * en `inventarios` de la sucursal receptora por cada vehículo del lote
   * (o da de alta el producto si aún no existe en esa sucursal).
   * Regresa { pedido, afectados }.
   */
  confirmarRecepcion(pedidoId){ return api("recibir_pedido", {}, pedidoId); },
};

/* ==========================================================================
   ESTADO GLOBAL
   ========================================================================== */
const state = {
  view:"dashboard",              // dashboard | sucursales | personal | catalogo | inventario | pedidos | ventas | cortes | auditoria
  lang:"es",
  sucursalFiltro:"todas",        // filtro global de sucursal
  sucursales:[], usuarios:[], inventario:[], ventas:[], pedidos:[],
  catalogo:[], cajas:[], cortes:[], auditoria:[],
  adminId:null,                  // usuario en sesión (no puede darse de baja a sí mismo)
  catalogoQuery:"",
  ventasFiltro:"all",            // all | contado | credito (vista Ventas)
  ventasQuery:"",
  auditoriaQuery:"",
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
    const [sucursales, usuarios, inventario, ventas, pedidos, catalogo, cajas] = await Promise.all([
      DB.getSucursales(), DB.getUsuarios(), DB.getInventario(), DB.getVentas(), DB.getPedidos(), DB.getCatalogo(), DB.getCajas()
    ]);
    state.sucursales = sucursales;
    state.usuarios = usuarios;
    state.inventario = inventario;
    state.ventas = ventas;
    state.pedidos = pedidos;
    state.catalogo = catalogo;
    state.cajas = cajas;
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
function enSucursal(lista, sucursalId = state.sucursalFiltro){
  return sucursalId === "todas" ? lista : lista.filter(x => x.sucursalId === sucursalId);
}
// Ventas desde el día 1 de hace (meses - 1) meses hasta hoy
function ventasUltimosMeses(ventas, meses = 6){
  const now = new Date();
  const desde = new Date(now.getFullYear(), now.getMonth() - (meses - 1), 1);
  return ventas.filter(v => new Date(v.fecha) >= desde);
}
// Margen bruto promedio por venta (sólo ventas cuyo costo de adquisición se conoce)
function margenPromedio(ventas){
  const conCosto = ventas.filter(v => v.margen !== null);
  return conCosto.length ? conCosto.reduce((s,v) => s + v.margen, 0) / conCosto.length : null;
}
// Días de inventario (Days of Supply): unidades en stock ÷ vehículos vendidos por día en los últimos 30 días
function diasDeInventario(unidadesStock, ventas){
  const hace30 = Date.now() - 30 * 86400000;
  const vendidos = ventas.filter(v => new Date(v.fecha) >= hace30).reduce((s,v) => s + v.vehiculos, 0);
  return vendidos ? Math.round(unidadesStock / (vendidos / 30)) : null;
}
function ventasPorCategoria(ventas){
  const map = {};
  ventas.forEach(v => {
    const cat = v.categoria || "—";
    if (!map[cat]) map[cat] = { ingresos:0, unidades:0 };
    map[cat].ingresos += v.total;
    map[cat].unidades += v.unidades;
  });
  return map;
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
  else if (state.view === "catalogo") renderCatalogo();
  else if (state.view === "ventas") renderVentas();
  else if (state.view === "cortes") renderCortes();
  else if (state.view === "auditoria") renderAuditoria();
}
function irAVista(vista){
  state.view = vista;
  cerrarModales();
  renderMain();
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

  const alertas = stockCritico(inv);

  // Unidades en stock (sólo vehículos), días de inventario y unidades rezagadas en patio
  const vehiculos = inv.filter(i => i.tipo !== "refaccion" && i.stockActual > 0);
  const unidadesStock = vehiculos.reduce((s,i) => s + i.stockActual, 0);
  const dos = diasDeInventario(unidadesStock, ventas);
  const antiguedad = vehiculos.length ? Math.round(vehiculos.reduce((s,i) => s + i.diasPatio, 0) / vehiculos.length) : 0;
  const rezagadas = vehiculos.filter(i => i.diasPatio > 90).reduce((s,i) => s + i.stockActual, 0);
 
  // Margen bruto y penetración financiera (F&I) de los últimos 6 meses
  const ventas6 = ventasUltimosMeses(ventas, 6);
  const margen = margenPromedio(ventas6);
  const aCredito = ventas6.filter(v => v.credito).length;
  const penetracionFI = ventas6.length ? (aCredito / ventas6.length) * 100 : 0;

  const personalActivo = enSucursal(state.usuarios).filter(u => u.estado === "activo").length;
  const cajasAbiertas = enSucursal(state.cajas).filter(c => c.estado === "abierta").length;

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

      <div class="kpi-grid kpi-grid--6 fade-in fade-in--1">
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
          <div class="kpi-icon">${iconCar()}</div>
          <div class="kpi-label">${t("kpiStock")}</div>
          <div class="kpi-value">${formatoNumero(unidadesStock)}</div>
          <div class="kpi-sub"><span>${dos !== null ? t("daysSupply").replace("{n}", dos) + " · " : ""}${t("avgAging").replace("{n}", antiguedad)}</span></div>
          ${rezagadas ? `<div class="kpi-sub"><span class="kpi-delta is-down">${t("agedUnits").replace("{n}", rezagadas)}</span></div>` : ""}
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconChart()}</div>
          <div class="kpi-label">${t("kpiMargen")}</div>
          <div class="kpi-value">${margen !== null ? formatoMoneda(margen) : "—"}</div>
          <div class="kpi-sub"><span>${margen !== null ? t("perUnit") : t("noCostData")}</span></div>
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconCard()}</div>
          <div class="kpi-label">${t("kpiFI")}</div>
          <div class="kpi-value">${penetracionFI.toFixed(1)}%</div>
          <div class="kpi-sub"><span>${t("fiSub").replace("{c}", aCredito).replace("{d}", ventas6.length - aCredito)}</span></div>
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconBuilding()}</div>
          <div class="kpi-label">${t("kpiSedes")}</div>
          <div class="kpi-value">${sucursalesActivas}</div>
          <div class="kpi-sub"><span>${t("ofTotalBranches").replace("{n}", state.sucursales.length)}</span></div>
        </div>
        <div class="kpi-card">
          <div class="kpi-icon">${iconUsers()}</div>
          <div class="kpi-label">${t("kpiPersonalActivo")}</div>
          <div class="kpi-value">${personalActivo}</div>
          <div class="kpi-sub"><span>${t("registersOpen").replace("{n}", cajasAbiertas)}</span></div>
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

      <div class="chart-card fade-in fade-in--3" style="margin-bottom:24px;">
        <div class="chart-card-head">
          <div><h3>${t("chartByCategory")}</h3><span>${t("chartByCategorySub")}</span></div>
        </div>
        <div class="chart-canvas-wrap"><canvas id="chartByCategory"></canvas></div>
        <div class="chart-legend">
          <span class="chart-legend-item"><span class="chart-legend-dot" style="background:var(--chart-navy)"></span>${t("revenue")}</span>
          <span class="chart-legend-item"><span class="chart-legend-dot" style="background:var(--chart-red)"></span>${t("units")}</span>
        </div>
      </div>

      <div class="chart-card fade-in fade-in--4" style="margin-bottom:30px;">
        <div class="chart-card-head">
          <div><h3>${t("recentSales")}</h3><span>${t("recentSalesSub")}</span></div>
        </div>
        <div class="table-wrap">
          <table class="data-table">
            <thead><tr>
              <th>${t("colFecha")}</th><th>${t("colSucursal")}</th><th>${t("colAsesor")}</th><th>${t("colModelo")}</th><th>${t("colVin")}</th><th>${t("colMonto")}</th>
            </tr></thead>
            <tbody>
              ${ventas.slice(0,8).map(v => `
                <tr>
                  <td class="cell-muted">${formatoFechaHora(v.fecha)}</td>
                  <td>${escapeHTML(sucursalNombre(v.sucursalId))}</td>
                  <td>${escapeHTML(v.responsable)} <span class="cell-em">/ ${escapeHTML(v.cliente)}</span></td>
                  <td>${escapeHTML(v.producto)}</td>
                  <td><span class="vehiculo-detail-vin">${escapeHTML(v.vin || "—")}</span></td>
                  <td><strong>${formatoMoneda(v.total)}</strong></td>
                </tr>
              `).join("") || `<tr><td colspan="6" class="cell-muted">—</td></tr>`}
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
    else if (action === "historial") irAVista("ventas");
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

  // Ingresos vs. unidades por categoría (últimos 6 meses)
  const porCategoria = ventasPorCategoria(ventasUltimosMeses(ventas, 6));
  destroyChart("byCategory");
  const ctxC = $("#chartByCategory");
  if (ctxC){
    chartInstances.byCategory = new Chart(ctxC, {
      data:{
        labels: Object.keys(porCategoria),
        datasets:[
          { type:"bar", label:t("revenue"), data:Object.values(porCategoria).map(c => c.ingresos), backgroundColor:c.navy, borderRadius:6, yAxisID:"y", order:2, maxBarThickness:42 },
          { type:"line", label:t("units"), data:Object.values(porCategoria).map(c => c.unidades), borderColor:c.red, backgroundColor:c.red, yAxisID:"y1", order:1, pointRadius:4, borderWidth:2, tension:.35 },
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
                <td><strong>${escapeHTML(s.nombre)}</strong>${s.razonSocial ? `<br><span class="cell-em">${escapeHTML(s.razonSocial)}</span>` : ""}</td>
                <td class="cell-muted">${escapeHTML(s.direccion)}</td>
                <td class="cell-muted">${escapeHTML(s.telefono)}</td>
                <td>${g ? escapeHTML(g.nombre) : `<span class="cell-em">${t("noGerente")}</span>`}</td>
                <td>${s.cajasActivas}</td>
                <td>${s.estado === "activo" ? `<span class="badge badge-ok"><span class="badge-dot"></span>${t("statusActive")}</span>` : `<span class="badge badge-off"><span class="badge-dot"></span>${t("statusInactive")}</span>`}</td>
                <td>
                  <div class="btn-table-row">
                    <button class="btn-table" data-editar-sucursal="${s.id}">${t("edit")}</button>
                    <button class="btn-table" data-cajas-sucursal="${s.id}">${t("cajasBtn")}</button>
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
  $$("[data-cajas-sucursal]").forEach(b => b.addEventListener("click", () => abrirModalCajas(b.dataset.cajasSucursal)));
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
        <div class="form-field"><label>${t("fName")} *</label><input type="text" name="nombre" required value="${s ? escapeHTML(s.nombre) : ""}"></div>
        <div class="form-field"><label>${t("fRazonSocial")}</label><input type="text" name="razonSocial" value="${s ? escapeHTML(s.razonSocial) : ""}"></div>
        <div class="form-field span-2"><label>${t("fAddress")} *</label><input type="text" name="direccion" required value="${s ? escapeHTML(s.direccion) : ""}"></div>
        <div class="form-field span-2"><label>${t("fDireccionFiscal")}</label><input type="text" name="direccionFiscal" value="${s ? escapeHTML(s.direccionFiscal) : ""}"></div>
        <div class="form-field"><label>${t("fPhone")} *</label><input type="tel" name="telefono" required value="${s ? escapeHTML(s.telefono) : ""}"></div>
        <div class="form-field"><label>${t("fEmail")}</label><input type="email" name="email" value="${s ? escapeHTML(s.email || "") : ""}"></div>
        <div class="form-field span-2"><label>${t("fContacto")}</label><input type="text" name="contacto" value="${s ? escapeHTML(s.contacto) : ""}"></div>
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
      razonSocial: fd.get("razonSocial").trim(),
      direccion: fd.get("direccion").trim(),
      direccionFiscal: fd.get("direccionFiscal").trim(),
      telefono: fd.get("telefono").trim(),
      email: fd.get("email").trim(),
      contacto: fd.get("contacto").trim(),
      gerenteId: fd.get("gerenteId") || null,
      cajasActivas: Number(fd.get("cajasActivas")) || 0,
      estado: fd.get("estado"),
    };
    if (editando){
      Object.assign(s, await DB.updateSucursal(id, payload));
      mostrarToast(t("toastSucursalUpdated"), "ok");
    }else{
      const nueva = await DB.createSucursal(payload);
      state.sucursales.push(nueva);
      mostrarToast(t("toastSucursalCreated"), "ok");
    }
    // El gerente elegido queda asignado en usuarios y las cajas pueden haber cambiado
    [state.usuarios, state.cajas] = await Promise.all([DB.getUsuarios(), DB.getCajas()]);
    cerrarModales();
    poblarSelectorSucursales();
    if (state.view === "sucursales") renderSucursales();
    else if (state.view === "dashboard") renderDashboard();
  });

  abrirModal("#modalSucursal");
}

/* ----- Cajas y terminales de una sucursal ----- */
function estadoCajaLabel(estado){
  return { abierta:t("cajaAbierta"), cerrada:t("cajaCerrada"), mantenimiento:t("cajaMant") }[estado] || estado;
}
function abrirModalCajas(sucursalId){
  const cajas = state.cajas.filter(c => c.sucursalId === sucursalId);
  const badge = { abierta:"badge-ok", cerrada:"badge-off", mantenimiento:"badge-warn" };
  $("#modalCajasContent").innerHTML = `
    <h3 class="modal-title">${t("cajasTitle").replace("{s}", escapeHTML(sucursalNombre(sucursalId)))}</h3>
    <p class="modal-desc">${t("cajasDesc")}</p>
    ${cajas.length ? `
    <div class="table-wrap">
      <table class="data-table">
        <thead><tr><th>${t("colCaja")}</th><th>${t("colEstado")}</th><th>${t("colTicketsHoy")}</th><th>${t("colTotalHoy")}</th><th>${t("colUltimaVenta")}</th><th>${t("colAcciones")}</th></tr></thead>
        <tbody>
          ${cajas.map(c => `
            <tr>
              <td><strong>${t("cajaN").replace("{n}", c.numero)}</strong></td>
              <td><span class="badge ${badge[c.estado]}"><span class="badge-dot"></span>${estadoCajaLabel(c.estado)}</span></td>
              <td>${c.ticketsHoy}</td>
              <td>${formatoMoneda(c.totalHoy)}</td>
              <td class="cell-muted">${formatoFechaHora(c.ultimaVenta)}</td>
              <td>
                <select class="select-table" data-estado-caja="${c.id}">
                  ${["abierta", "cerrada", "mantenimiento"].map(e => `<option value="${e}" ${c.estado === e ? "selected" : ""}>${estadoCajaLabel(e)}</option>`).join("")}
                </select>
              </td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    </div>` : `<div class="empty-state"><strong>${t("noCajas")}</strong></div>`}
    <div class="form-actions"><button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button></div>
  `;
  $$("[data-estado-caja]").forEach(sel => sel.addEventListener("change", async () => {
    const actualizada = await DB.setCajaEstado(sel.dataset.estadoCaja, sel.value);
    Object.assign(state.cajas.find(c => c.id === actualizada.id), actualizada);
    state.sucursales = await DB.getSucursales(); // recalcula "cajas activas"
    mostrarToast(t("toastCaja"), "ok");
    abrirModalCajas(sucursalId);
    if (state.view === "sucursales") renderSucursales();
  }));
  abrirModal("#modalCajas");
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
                <td>
                  <div class="btn-table-row">
                    <button class="btn-table" data-editar-usuario="${u.id}">${t("edit")}</button>
                    ${u.rol === "gerente" ? `<button class="btn-table" data-reubicar-usuario="${u.id}">${t("relocate")}</button>` : ""}
                    ${u.id !== state.adminId ? `<button class="btn-table" data-toggle-usuario="${u.id}">${u.estado === "activo" ? t("deactivate") : t("activate")}</button>` : ""}
                  </div>
                </td>
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
  $$("[data-reubicar-usuario]").forEach(b => b.addEventListener("click", () => abrirModalReubicar(b.dataset.reubicarUsuario)));
  $$("[data-toggle-usuario]").forEach(b => b.addEventListener("click", async () => {
    const u = state.usuarios.find(x => x.id === b.dataset.toggleUsuario);
    Object.assign(u, await DB.setUsuarioEstado(u.id, u.estado === "activo" ? "inactivo" : "activo"));
    mostrarToast(t("toastUsuarioEstado"), "ok");
    renderPersonal();
  }));
}

// Traslado rápido de un gerente a otra sucursal (usa el mismo endpoint que la edición)
function abrirModalReubicar(id){
  const u = state.usuarios.find(x => x.id === id);
  $("#modalPersonalContent").innerHTML = `
    <h3 class="modal-title">${t("relocateTitle")}</h3>
    <p class="modal-desc">${escapeHTML(u.nombre)} · ${t("relocateDesc")}</p>
    <form id="formReubicar">
      <div class="form-grid cols-1">
        <div class="form-field"><label>${t("fAssignedBranch")}</label>
          <select name="sucursalId">
            <option value="">${t("noGerente")}</option>
            ${state.sucursales.map(s => `<option value="${s.id}" ${u.sucursalId === s.id ? "selected" : ""}>${escapeHTML(s.nombre)}</option>`).join("")}
          </select>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("cancel")}</button>
        <button type="submit" class="btn btn-primary">${t("saveChanges")}</button>
      </div>
    </form>
  `;
  $("#formReubicar").addEventListener("submit", async (e) => {
    e.preventDefault();
    const sucursalId = e.target.sucursalId.value || null;
    Object.assign(u, await DB.updateUsuario(u.id, { nombre:u.nombre, correo:u.correo, rol:u.rol, sucursalId }));
    state.sucursales = await DB.getSucursales(); // el gerente a cargo de cada sede cambia
    mostrarToast(t("toastUsuarioUpdated"), "ok");
    cerrarModales();
    renderPersonal();
  });
  abrirModal("#modalPersonal");
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
        ${!editando
          ? `<div class="form-field span-2"><label>${t("fPassword")} *</label><input type="password" name="password" required minlength="8"><p class="form-field-info">${t("passwordHint")}</p></div>`
          : `<div class="form-field span-2"><label>${t("fNewPassword")}</label><input type="password" name="password" minlength="8"><p class="form-field-info">${t("newPasswordHint")}</p></div>`}
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
      password: fd.get("password"),
    };
    if (editando){
      Object.assign(u, await DB.updateUsuario(id, payload));
      mostrarToast(t("toastUsuarioUpdated"), "ok");
    }else{
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
          <th>${t("colProducto")}</th><th>${t("colCategoria")}</th><th>${t("colStockActual")}</th><th>${t("colAntiguedad")}</th><th>${t("colPrecio")}</th><th>${t("colEstado")}</th><th></th>
        </tr></thead>
        <tbody>
          ${items.map(it => {
            const total = it.sedes.reduce((s,x) => s + x.stockActual, 0);
            const critico = it.sedes.some(x => x.stockActual <= x.stockMinimo);
            const dias = Math.max(...it.sedes.map(x => x.diasPatio));
            return `
            <tr class="is-clickable" data-producto="${escapeHTML(it.producto)}">
              <td><strong>${escapeHTML(it.producto)}</strong><br><span class="cell-em">${escapeHTML(it.marca)}</span></td>
              <td class="cell-muted">${escapeHTML(it.categoria)}</td>
              <td>${total}</td>
              <td>${dias > 90 ? `<span class="badge badge-warn"><span class="badge-dot"></span>${dias} d</span>` : `${dias} d`}</td>
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
        <thead><tr><th>${t("colSucursal")}</th><th>${t("colStockActual")}</th><th>${t("colStockMinimo")}</th><th>${t("colAntiguedad")}</th><th>${t("colEstado")}</th></tr></thead>
        <tbody>
          ${sedes.map(s => `
            <tr>
              <td>${escapeHTML(sucursalNombre(s.sucursalId))}</td>
              <td><strong>${s.stockActual}</strong></td>
              <td class="cell-muted">${s.stockMinimo}</td>
              <td class="cell-muted">${s.diasPatio} d</td>
              <td>${s.stockActual <= s.stockMinimo ? `<span class="badge badge-danger"><span class="badge-dot"></span>${t("critical")}</span>` : `<span class="badge badge-ok"><span class="badge-dot"></span>${t("ok")}</span>`}</td>
            </tr>
          `).join("")}
          <tr><td><strong>${t("totalNetwork")}</strong></td><td colspan="4"><strong>${total}</strong></td></tr>
        </tbody>
      </table>
    </div>
    <form id="formPrecio">
      <div class="panel-heading" style="margin:20px 0 10px;"><h2 style="font-size:16px;">${t("priceFormTitle")}</h2></div>
      <div class="form-grid">
        <div class="form-field"><label>${t("fPrecioBase")} *</label><input type="number" min="0" name="precio" required value="${sedes[0].precio}"></div>
        <div class="form-field"><label>${t("fCosto")}</label><input type="number" min="0" name="costo" value="${sedes[0].costo ?? ""}"></div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button>
        <button type="submit" class="btn btn-primary">${t("saveChanges")}</button>
      </div>
    </form>
  `;
  $("#formPrecio").addEventListener("submit", async (e) => {
    e.preventDefault();
    const ids = [...new Set(sedes.map(x => x.productoId))];
    state.inventario = await DB.updatePrecioProducto({ ids, precio: e.target.precio.value, costo: e.target.costo.value });
    mostrarToast(t("toastPrecio"), "ok");
    cerrarModales();
    if (state.view === "inventario") renderInventario();
  });
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
function formatoFechaHora(iso){
  if (!iso) return "—";
  return new Date(iso).toLocaleString(state.lang === "en" ? "en-US" : "es-MX", { day:"2-digit", month:"short", hour:"2-digit", minute:"2-digit" });
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
        <div class="form-field"><label>${t("fModeloV")} *</label><input type="text" name="modelo" required list="listaModelos" value="${escapeHTML(v.modelo || "")}"></div>
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
      <datalist id="listaModelos">
        ${state.catalogo.filter(m => m.estado === "activo").map(m => `<option value="${escapeHTML(m.modelo)}">${escapeHTML(`${m.marca} · ${m.version} · ${formatoMoneda(m.precioLista)}`)}</option>`).join("")}
      </datalist>
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

  // Al elegir un modelo del catálogo se llenan versión, equipamiento y precio de lista
  rowsWrap.addEventListener("change", (e) => {
    if (e.target.name !== "modelo") return;
    const m = state.catalogo.find(x => x.modelo === e.target.value);
    if (!m) return;
    const row = e.target.closest(".vehiculo-row");
    $("[name=version]", row).value ||= m.version;
    $("[name=equipamiento]", row).value ||= m.equipamiento;
    $("[name=precioProyectado]", row).value ||= m.precioLista;
  });

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
      Object.assign(p, await DB.updatePedido(id, payload));
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
    const { pedido, afectados } = await DB.confirmarRecepcion(p.id);
    Object.assign(p, pedido);
    // Sincroniza el inventario local con lo que escribió la BD
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
   VISTA: CATÁLOGO MAESTRO DE MODELOS Y VERSIONES
   ========================================================================== */
function renderCatalogo(){
  const main = $("#main");
  const q = state.catalogoQuery.trim().toLowerCase();
  const lista = state.catalogo.filter(m => !q || `${m.marca} ${m.modelo} ${m.version} ${m.carroceria}`.toLowerCase().includes(q));

  main.innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA</p><h2>${t("catalogoTitle")}</h2></div>
        <div class="panel-heading-actions">
          <button class="btn btn-primary" id="btnNuevoModelo">${iconPlus()} ${t("newModelo")}</button>
        </div>
      </div>
      <p class="modal-desc" style="margin-top:-14px;">${t("catalogoSub")}</p>

      <div class="section-toolbar fade-in fade-in--1">
        ${cajaBusqueda("inpBuscarCatalogo", t("searchCatalogo"), state.catalogoQuery)}
      </div>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr>
            <th>${t("colModelo")}</th><th>${t("fVersion")}</th><th>${t("colCarroceria")}</th><th>${t("fAnio")}</th>
            <th>${t("fEquipamiento")}</th><th>${t("colPrecioLista")}</th><th>${t("colEstado")}</th><th>${t("colAcciones")}</th>
          </tr></thead>
          <tbody>
            ${lista.map(m => `
              <tr>
                <td><strong>${escapeHTML(m.modelo)}</strong><br><span class="cell-em">${escapeHTML(m.marca)}</span></td>
                <td>${escapeHTML(m.version || "—")}</td>
                <td><span class="role-badge role-gerente">${escapeHTML(m.carroceria)}</span></td>
                <td class="cell-muted">${m.anio || "—"}</td>
                <td class="cell-muted">${escapeHTML(m.equipamiento || "—")}</td>
                <td><strong>${formatoMoneda(m.precioLista)}</strong></td>
                <td>${badgeEstado(m.estado)}</td>
                <td>
                  <div class="btn-table-row">
                    <button class="btn-table" data-editar-modelo="${m.id}">${t("edit")}</button>
                    <button class="btn-table" data-toggle-modelo="${m.id}">${m.estado === "activo" ? t("deactivate") : t("activate")}</button>
                  </div>
                </td>
              </tr>
            `).join("") || `<tr><td colspan="8"><div class="empty-state"><strong>${t("noResults")}</strong></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;

  bindBusqueda("inpBuscarCatalogo", "catalogoQuery", renderCatalogo);
  $("#btnNuevoModelo").addEventListener("click", () => abrirModalModelo());
  $$("[data-editar-modelo]").forEach(b => b.addEventListener("click", () => abrirModalModelo(b.dataset.editarModelo)));
  $$("[data-toggle-modelo]").forEach(b => b.addEventListener("click", async () => {
    const m = state.catalogo.find(x => x.id === b.dataset.toggleModelo);
    Object.assign(m, await DB.setModeloEstado(m.id, m.estado === "activo" ? "inactivo" : "activo"));
    mostrarToast(t("toastModeloEstado"), "ok");
    renderCatalogo();
  }));
}

function abrirModalModelo(id){
  const editando = !!id;
  const m = editando ? state.catalogo.find(x => x.id === id) : null;
  const carrocerias = ["Sedán", "SUV", "Supercar", "Coupé", "Pickup", "Motocicleta"];

  $("#modalCatalogoContent").innerHTML = `
    <h3 class="modal-title">${editando ? t("formModeloEditTitle") : t("formModeloNewTitle")}</h3>
    <p class="modal-desc">${t("formModeloDesc")}</p>
    <form id="formModelo">
      <div class="form-grid">
        <div class="form-field"><label>${t("fMarca")} *</label><input type="text" name="marca" required value="${m ? escapeHTML(m.marca) : ""}"></div>
        <div class="form-field"><label>${t("fModeloV")} *</label><input type="text" name="modelo" required value="${m ? escapeHTML(m.modelo) : ""}"></div>
        <div class="form-field"><label>${t("fVersion")}</label><input type="text" name="version" value="${m ? escapeHTML(m.version) : ""}"></div>
        <div class="form-field"><label>${t("fCarroceria")} *</label>
          <input type="text" name="carroceria" required list="listaCarrocerias" value="${m ? escapeHTML(m.carroceria) : ""}">
          <datalist id="listaCarrocerias">${carrocerias.map(c => `<option value="${c}">`).join("")}</datalist>
        </div>
        <div class="form-field"><label>${t("fAnio")}</label><input type="number" name="anio" value="${m && m.anio ? m.anio : new Date().getFullYear()}"></div>
        <div class="form-field"><label>${t("fPrecioLista")} *</label><input type="number" min="0" name="precioLista" required value="${m ? m.precioLista : ""}"></div>
        <div class="form-field span-2"><label>${t("fEquipamiento")}</label><textarea name="equipamiento">${m ? escapeHTML(m.equipamiento) : ""}</textarea></div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-ghost" data-close-modal>${t("cancel")}</button>
        <button type="submit" class="btn btn-primary">${editando ? t("saveChanges") : t("save")}</button>
      </div>
    </form>
  `;

  $("#formModelo").addEventListener("submit", async (e) => {
    e.preventDefault();
    const payload = Object.fromEntries(new FormData(e.target));
    if (editando){
      Object.assign(m, await DB.updateModelo(id, payload));
      mostrarToast(t("toastModeloUpdated"), "ok");
    }else{
      state.catalogo.push(await DB.createModelo(payload));
      mostrarToast(t("toastModeloCreated"), "ok");
    }
    cerrarModales();
    if (state.view === "catalogo") renderCatalogo();
  });
  abrirModal("#modalCatalogo");
}

/* ==========================================================================
   VISTA: HISTORIAL CONSOLIDADO DE VENTAS + FOLIOS Y COMPROBANTES
   ========================================================================== */
function metodoVenta(v){
  return v.credito ? t("filterCredito") : v.metodo;
}

function renderVentas(){
  const main = $("#main");
  const q = state.ventasQuery.trim().toLowerCase();
  let lista = ventasFiltradas();
  if (state.ventasFiltro === "contado") lista = lista.filter(v => !v.credito);
  if (state.ventasFiltro === "credito") lista = lista.filter(v => v.credito);
  if (q) lista = lista.filter(v => `${v.folio} ${v.ticket || ""} ${v.cliente} ${v.vin} ${v.producto} ${v.responsable}`.toLowerCase().includes(q));
  const total = lista.reduce((s,v) => s + v.total, 0);
  const filtros = [["all", t("filterAll")], ["contado", t("filterContado")], ["credito", t("filterCredito")]];

  main.innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursalFiltro === "todas" ? t("allBranches") : sucursalNombre(state.sucursalFiltro))}</p><h2>${t("ventasTitle")}</h2></div>
      </div>
      <p class="modal-desc" style="margin-top:-14px;">${t("ventasSub")}</p>

      <div class="section-toolbar fade-in fade-in--1">
        <div class="filter-pills">
          ${filtros.map(([clave, texto]) => `<button class="filter-pill ${state.ventasFiltro === clave ? "is-active" : ""}" data-vfiltro="${clave}">${texto}</button>`).join("")}
        </div>
        ${cajaBusqueda("inpBuscarVentas", t("searchVentas"), state.ventasQuery)}
      </div>
      <p class="eyebrow-plain">${t("totalFiltered").replace("{n}", lista.length).replace("{t}", formatoMoneda(total))}</p>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr>
            <th>${t("colFolio")}</th><th>${t("colFecha")}</th><th>${t("colSucursal")}</th><th>${t("colAsesor")}</th><th>${t("colCliente")}</th>
            <th>${t("colModelo")}</th><th>${t("colVin")}</th><th>${t("colMetodo")}</th><th>${t("colTotal")}</th><th></th>
          </tr></thead>
          <tbody>
            ${lista.map(v => `
              <tr>
                <td><span class="folio-chip">${escapeHTML(v.folio)}</span></td>
                <td class="cell-muted">${formatoFechaHora(v.fecha)}</td>
                <td>${escapeHTML(sucursalNombre(v.sucursalId))}</td>
                <td>${escapeHTML(v.responsable)}</td>
                <td>${escapeHTML(v.cliente)}</td>
                <td>${escapeHTML(v.producto)}</td>
                <td><span class="vehiculo-detail-vin">${escapeHTML(v.vin || "—")}</span></td>
                <td><span class="badge ${v.credito ? "badge-transito" : "badge-ok"}"><span class="badge-dot"></span>${escapeHTML(metodoVenta(v))}</span></td>
                <td><strong>${formatoMoneda(v.total)}</strong></td>
                <td><button class="btn-table" data-comprobante="${v.id}">${t("reissue")}</button></td>
              </tr>
            `).join("") || `<tr><td colspan="10"><div class="empty-state"><strong>${t("noResults")}</strong></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;

  bindBusqueda("inpBuscarVentas", "ventasQuery", renderVentas);
  $$("[data-vfiltro]").forEach(b => b.addEventListener("click", () => { state.ventasFiltro = b.dataset.vfiltro; renderVentas(); }));
  $$("[data-comprobante]").forEach(b => b.addEventListener("click", () => abrirComprobante(b.dataset.comprobante)));
}

// Reemisión del ticket (contado) o del contrato (crédito) lista para imprimir
async function abrirComprobante(id){
  const v = await DB.getVentaDetalle(id);
  const s = v.sucursal || {};
  const c = v.clienteCredito;
  $("#modalComprobanteContent").innerHTML = `
    <div style="display:flex; align-items:center; gap:10px; margin-bottom:4px; flex-wrap:wrap;">
      <span class="folio-chip">${escapeHTML(v.folio)}</span>
      ${v.ticket ? `<span class="cell-muted">Ticket #${v.ticket}</span>` : ""}
    </div>
    <h3 class="modal-title">${c ? t("contractTitle") : t("ticketTitle")}</h3>
    <p class="modal-desc">
      <strong>${escapeHTML(s.razonSocial || "KARMA")}</strong> · ${escapeHTML(s.nombre || "")}<br>
      ${escapeHTML(s.direccionFiscal || s.direccion || "")} · ${escapeHTML(s.telefono || "")}<br>
      ${formatoFechaHora(v.fecha)} · ${t("cajaN").replace("{n}", v.caja ?? "—")} · ${t("colAsesor")}: ${escapeHTML(v.responsable)}
    </p>

    <div class="table-wrap">
      <table class="data-table">
        <thead><tr><th>${t("colProducto")}</th><th>${t("colVin")}</th><th>${t("colCantidad")}</th><th>${t("colPrecioU")}</th><th>${t("colSubtotal")}</th></tr></thead>
        <tbody>
          ${v.lineas.map(l => `
            <tr>
              <td>${escapeHTML(l.producto)}</td>
              <td><span class="vehiculo-detail-vin">${escapeHTML(l.vin || "—")}</span></td>
              <td>${l.cantidad}</td>
              <td>${formatoMoneda(l.precio)}</td>
              <td>${formatoMoneda(l.subtotal)}</td>
            </tr>
          `).join("")}
          <tr><td colspan="4"><strong>${t("colTotal")}</strong></td><td><strong>${formatoMoneda(v.total)}</strong></td></tr>
        </tbody>
      </table>
    </div>

    <div class="vehiculo-detail-card" style="margin-top:14px;">
      <div class="vehiculo-detail-grid">
        <div><span>${t("colCliente")}</span><strong>${escapeHTML(v.cliente)}</strong></div>
        <div><span>${t("colMetodo")}</span><strong>${escapeHTML(metodoVenta(v))}</strong></div>
        <div><span>${t("efectivoRecibido")}</span><strong>${formatoMoneda(v.efectivoRecibido)}</strong></div>
        <div><span>${t("cambio")}</span><strong>${formatoMoneda(v.cambio)}</strong></div>
        ${c ? `
        <div><span>RFC / INE</span><strong>${escapeHTML(c.rfc_ine || "—")}</strong></div>
        <div><span>${t("enganche")}</span><strong>${formatoMoneda(c.enganche)}</strong></div>
        <div><span>${t("adeudo")}</span><strong>${formatoMoneda(c.total_adeudo)}</strong></div>
        <div><span>${t("abono")}</span><strong>${formatoMoneda(c.monto_abono)}</strong></div>
        <div><span>${t("plazos")}</span><strong>${c.abonos_totales}</strong></div>` : ""}
      </div>
    </div>

    ${c ? `<div class="firmas"><div>${t("signCliente")}</div><div>${t("signAsesor")}</div></div>` : ""}

    <div class="form-actions no-print">
      <button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button>
      <button type="button" class="btn btn-primary" id="btnImprimir">${t("print")}</button>
    </div>
  `;
  $("#btnImprimir").addEventListener("click", () => window.print());
  abrirModal("#modalComprobante");
}

/* ==========================================================================
   VISTA: ARQUEOS Y CORTES POR TERMINAL
   ========================================================================== */
async function renderCortes(){
  state.cortes = await DB.getCortes();
  const lista = enSucursal(state.cortes);

  $("#main").innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA · ${escapeHTML(state.sucursalFiltro === "todas" ? t("allBranches") : sucursalNombre(state.sucursalFiltro))}</p><h2>${t("cortesTitle")}</h2></div>
      </div>
      <p class="modal-desc" style="margin-top:-14px;">${t("cortesSub")}</p>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr>
            <th>${t("colDia")}</th><th>${t("colSucursal")}</th><th>${t("colCaja")}</th><th>${t("colCajeros")}</th>
            <th>${t("colApertura")}</th><th>${t("colCorte")}</th><th>${t("colTickets")}</th>
            <th>${t("colContado")}</th><th>${t("colCredito")}</th><th>${t("colEfectivo")}</th><th>${t("colTotal")}</th>
          </tr></thead>
          <tbody>
            ${lista.map(c => `
              <tr>
                <td>${formatoFecha(c.dia)}</td>
                <td>${escapeHTML(sucursalNombre(c.sucursalId))}</td>
                <td>${t("cajaN").replace("{n}", c.caja ?? "—")}</td>
                <td class="cell-muted">${escapeHTML(c.cajeros)}</td>
                <td>${c.apertura}</td>
                <td>${c.corte}</td>
                <td>${c.tickets}</td>
                <td>${formatoMoneda(c.contado)}</td>
                <td>${formatoMoneda(c.credito)}</td>
                <td>${formatoMoneda(c.efectivo)}</td>
                <td><strong>${formatoMoneda(c.total)}</strong></td>
              </tr>
            `).join("") || `<tr><td colspan="11"><div class="empty-state"><strong>${t("noCortes")}</strong></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

/* ==========================================================================
   VISTA: AUDITORÍA DE ACTIVIDAD (AUDIT TRAIL)
   ========================================================================== */
async function renderAuditoria(recargar = true){
  if (recargar) state.auditoria = await DB.getAuditoria();
  const q = state.auditoriaQuery.trim().toLowerCase();
  const lista = state.auditoria.filter(a => !q || `${a.usuario} ${a.accion} ${a.detalle}`.toLowerCase().includes(q));

  $("#main").innerHTML = `
    <div class="panel panel-full">
      <div class="panel-heading fade-in">
        <div><p class="eyebrow-plain">KARMA</p><h2>${t("auditoriaTitle")}</h2></div>
      </div>
      <p class="modal-desc" style="margin-top:-14px;">${t("auditoriaSub")}</p>

      <div class="section-toolbar fade-in fade-in--1">
        ${cajaBusqueda("inpBuscarAuditoria", t("searchAuditoria"), state.auditoriaQuery)}
      </div>

      <div class="table-wrap fade-in fade-in--2">
        <table class="data-table">
          <thead><tr><th>${t("colFecha")}</th><th>${t("colUsuario")}</th><th>${t("colAccion")}</th><th>${t("colDetalle")}</th></tr></thead>
          <tbody>
            ${lista.map(a => `
              <tr>
                <td class="cell-muted">${formatoFechaHora(a.fecha)}</td>
                <td>${escapeHTML(a.usuario)}</td>
                <td><span class="role-badge role-admin">${escapeHTML(a.accion)}</span></td>
                <td>${escapeHTML(a.detalle)}</td>
              </tr>
            `).join("") || `<tr><td colspan="4"><div class="empty-state"><strong>${t("noAuditoria")}</strong></div></td></tr>`}
          </tbody>
        </table>
      </div>
    </div>
  `;
  bindBusqueda("inpBuscarAuditoria", "auditoriaQuery", () => renderAuditoria(false));
}

/* ----- Piezas reutilizables de las vistas nuevas ----- */
function badgeEstado(estado){
  return estado === "activo"
    ? `<span class="badge badge-ok"><span class="badge-dot"></span>${t("statusActive")}</span>`
    : `<span class="badge badge-off"><span class="badge-dot"></span>${t("statusInactive")}</span>`;
}
// Caja de búsqueda con el mismo estilo que la de Inventario
function cajaBusqueda(id, placeholder, valor){
  return `
    <div class="search-box" style="flex:0 0 380px; max-width:100%;">
      <div class="search-wrap" style="background:var(--surface-2); border-color:var(--line); color:var(--text-muted);">
        ${iconSearch()}
        <input id="${id}" type="text" placeholder="${placeholder}" style="color:var(--text-main);" value="${escapeHTML(valor)}">
      </div>
    </div>`;
}
// Al escribir guarda el texto en state[clave] y redibuja la vista sin perder el foco del buscador
function bindBusqueda(id, clave, render){
  $("#" + id).addEventListener("input", (e) => {
    state[clave] = e.target.value;
    render();
    const input = $("#" + id);
    input.focus();
    input.setSelectionRange(input.value.length, input.value.length);
  });
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
        <div class="form-field"><label>${t("fPrecioVenta")} *</label><input type="number" min="0" name="precio" required></div>
        <div class="form-field"><label>${t("fCosto")}</label><input type="number" min="0" name="costo"></div>
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
      tipo: fd.get("tipo"),
      sucursalId: fd.get("sucursalId"),
      producto: fd.get("producto").trim(),
      marca: fd.get("marca").trim(),
      categoria: fd.get("categoria").trim(),
      precio: Number(fd.get("precio")) || 0,
      costo: fd.get("costo"),
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
function iconChart(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M4 20V4M4 20h16"/><path d="M7.5 15l4-4.5 3 3L20 7"/></svg>`; }
function iconCard(){ return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="5.5" width="18" height="13" rx="2"/><path d="M3 10h18M7 15h4"/></svg>`; }
function iconSearch(){ return `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.4-3.4"/></svg>`; }
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
  aplicarIdioma(state.lang === "es" ? "en" : "es");
  DB.setIdioma(state.lang).catch(() => {}); // se guarda en usuarios.idioma_pref del perfil
  poblarSelectorSucursales();
  renderMain();
}
function aplicarIdioma(lang){
  state.lang = lang;
  document.documentElement.lang = lang;
  $$(".lang-op").forEach(el => el.classList.toggle("is-active", el.dataset.lang === state.lang));
}

/* ==========================================================================
   ATAJOS DE TECLADO Y CONSOLA RÁPIDA
   ========================================================================== */
// Vistas del panel con su tecla de función (las que no tienen tecla se abren desde la consola)
const VISTAS = [
  { vista:"dashboard",  nav:"navDashboard" },
  { vista:"sucursales", nav:"navSucursales", tecla:"F2" },
  { vista:"ventas",     nav:"navVentas",     tecla:"F3" },
  { vista:"inventario", nav:"navInventario", tecla:"F4" },
  { vista:"pedidos",    nav:"navPedidos",    tecla:"F6" },
  { vista:"personal",   nav:"navPersonal",   tecla:"F7" },
  { vista:"catalogo",   nav:"navCatalogo",   tecla:"F8" },
  { vista:"cortes",     nav:"navCortes",     tecla:"F9" },
  { vista:"auditoria",  nav:"navAuditoria",  tecla:"F10" },
];

function comandosConsola(){
  return [
    ...VISTAS.map(v => ({ texto:t(v.nav), atajo:v.tecla || "", ejecutar:() => irAVista(v.vista) })),
    { texto:t("qaSucursal"), atajo:"", ejecutar:() => abrirModalSucursal() },
    { texto:t("newGerente"), atajo:"", ejecutar:() => abrirModalPersonal() },
    { texto:t("newModelo"), atajo:"", ejecutar:() => abrirModalModelo() },
    { texto:t("newPedido"), atajo:"", ejecutar:() => abrirModalPedido() },
    { texto:t("qaArticulo"), atajo:"", ejecutar:() => abrirModalArticulo() },
    { texto:"ES / EN", atajo:"", ejecutar:toggleIdioma },
    { texto:t("kHelp"), atajo:"F1", ejecutar:abrirAyuda },
    { texto:t("logout"), atajo:"", ejecutar:cerrarSesion },
  ];
}

function abrirAyuda(){
  const filas = [
    ["F1", t("kHelp")],
    ["Ctrl + K", t("kConsole")],
    ...VISTAS.filter(v => v.tecla).map(v => [v.tecla, t(v.nav)]),
    ["Esc", t("close")],
  ];
  $("#modalAyudaContent").innerHTML = `
    <h3 class="modal-title">${t("helpTitle")}</h3>
    <p class="modal-desc">${t("helpDesc")}</p>
    <div class="table-wrap">
      <table class="data-table">
        <tbody>${filas.map(([tecla, texto]) => `<tr><td><kbd class="kbd">${tecla}</kbd></td><td>${texto}</td></tr>`).join("")}</tbody>
      </table>
    </div>
    <div class="form-actions"><button type="button" class="btn btn-ghost" data-close-modal>${t("close")}</button></div>
  `;
  cerrarModales();
  abrirModal("#modalAyuda");
}

function abrirConsola(){
  let seleccion = 0;
  $("#modalConsolaContent").innerHTML = `
    <h3 class="modal-title">${t("consoleTitle")}</h3>
    <p class="modal-desc">${t("consoleHint")}</p>
    <div class="form-field"><input type="text" id="inpConsola" placeholder="${t("consolePlaceholder")}" autocomplete="off"></div>
    <div class="consola-lista" id="consolaLista"></div>
  `;
  const input = $("#inpConsola");
  const visibles = () => comandosConsola().filter(c => c.texto.toLowerCase().includes(input.value.trim().toLowerCase()));
  const ejecutar = (comando) => { cerrarModales(); comando.ejecutar(); };
  const pintar = () => {
    const lista = visibles();
    $("#consolaLista").innerHTML = lista.map((c, i) => `
      <button type="button" class="consola-item ${i === seleccion ? "is-active" : ""}" data-comando="${i}">
        <span>${escapeHTML(c.texto)}</span>${c.atajo ? `<kbd class="kbd">${c.atajo}</kbd>` : ""}
      </button>`).join("") || `<p class="alert-empty">${t("noResults")}</p>`;
    $$("[data-comando]").forEach(b => b.addEventListener("click", () => ejecutar(lista[b.dataset.comando])));
  };

  input.addEventListener("input", () => { seleccion = 0; pintar(); });
  input.addEventListener("keydown", (e) => {
    const lista = visibles();
    if (e.key === "ArrowDown"){ e.preventDefault(); seleccion = Math.min(seleccion + 1, lista.length - 1); pintar(); }
    if (e.key === "ArrowUp"){ e.preventDefault(); seleccion = Math.max(seleccion - 1, 0); pintar(); }
    if (e.key === "Enter" && lista[seleccion]) ejecutar(lista[seleccion]);
  });

  pintar();
  cerrarModales();
  abrirModal("#modalConsola");
  input.focus();
}

function manejarAtajos(e){
  if (e.key === "Escape"){ cerrarModales(); return; }
  if (e.ctrlKey && e.key.toLowerCase() === "k"){ e.preventDefault(); abrirConsola(); return; }
  if (e.key === "F1"){ e.preventDefault(); abrirAyuda(); return; }
  const v = VISTAS.find(x => x.tecla === e.key);
  if (v){ e.preventDefault(); irAVista(v.vista); }
}
function applyI18n(){
  $$("[data-i18n]").forEach(el => { el.textContent = t(el.dataset.i18n); });
  $$("[data-i18n-title]").forEach(el => { el.title = t(el.dataset.i18nTitle); });
}

/* ==========================================================================
   SESIÓN
   ========================================================================== */
async function cerrarSesion(){
  const btn = $("#logoutBtn");
  btn.disabled = true;
  try{
    await fetch(`${AUTH_URL}?action=logout`, { method:"POST" });
  }catch(err){
    console.error("No se pudo cerrar la sesión en el servidor", err);
  }
  try{ localStorage.removeItem("karma_user"); }catch(_){ /* navegador sin almacenamiento */ }
  window.location.replace(LOGIN_URL);
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
  document.addEventListener("keydown", manejarAtajos);
  $("#helpBtn").addEventListener("click", abrirAyuda);

  setInterval(actualizarReloj, 1000 * 30);
  actualizarReloj();
}

/* ==========================================================================
   INICIALIZACIÓN
   ========================================================================== */
document.addEventListener("DOMContentLoaded", async () => {
  initEventosGlobales();
  // Sin sesión de Administrador General no se carga nada (api() redirige al login)
  let admin;
  try{ admin = await api("sesion"); }catch(_){ setSyncStatus(false); return; }
  $("#statusAdmin").textContent = admin.nombre;
  state.adminId = admin.id;
  aplicarIdioma(admin.idioma === "en" ? "en" : "es"); // idioma guardado en el perfil
  await cargarDatos();
  poblarSelectorSucursales();
  renderMain();
});
