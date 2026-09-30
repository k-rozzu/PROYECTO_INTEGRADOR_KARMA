<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KARMA · Punto de Venta — Cajero</title>
<!-- Tipografías: Fraunces (display / elegante) + Inter (UI / datos) -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;1,9..144,500&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../../CSS/PuntoDeVenta/style.css">
</head>
<body>

<div class="app">

  <!-- ============================================================
       BARRA SUPERIOR: logo (clic = ir a Venta), idioma, tema,
       cerrar sesión, sucursal, buscador y sub-navegación de vistas
       ============================================================ -->
  <header class="topbar">

    <!-- Fila superior: marca + acciones de cuenta -->
    <div class="topbar-main">

      <!-- Logo: al hacer clic siempre regresa a la vista de Venta -->
      <button class="brand" id="logoHome" type="button" title="Ir a Venta">
        <img class="brand-logo" src="../../assets/logo-karma.png" alt="KARMA">
        <div class="brand-text">
          <span class="brand-name">KARMA</span>
          <span class="brand-slogan">Te damos el auto que te mereces</span>
        </div>
      </button>

      <!-- Idioma / tema / sesión / sucursal -->
      <div class="topbar-right">
        <button class="lang-toggle" id="langToggle" title="Cambiar idioma" aria-label="Cambiar idioma">
          <span class="lang-op is-active" data-lang="es">ES</span>
          <span class="lang-sep">/</span>
          <span class="lang-op" data-lang="en">EN</span>
        </button>
        <button class="theme-toggle" id="themeToggle" title="Cambiar modo" aria-label="Cambiar modo claro/oscuro">
          <svg class="icon-sun" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="4.2"/><path d="M12 2.5v2.4M12 19.1v2.4M4.2 4.2l1.7 1.7M18.1 18.1l1.7 1.7M2.5 12h2.4M19.1 12h2.4M4.2 19.8l1.7-1.7M18.1 5.9l1.7-1.7"/></svg>
          <svg class="icon-moon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a6.8 6.8 0 0 0 10.5 10.5Z"/></svg>
        </button>
        <button class="logout-btn" id="logoutBtn">Cerrar sesión</button>
        <div class="sede-pill">
          <span class="sede-label">Sucursal</span>
          <span class="sede-value" id="sedeValue">Cargando…</span>
        </div>
      </div>
    </div>

    <!-- Fila inferior: buscador contextual + pestañas de vista -->
    <div class="topbar-sub">

      <!-- Buscador: su comportamiento cambia según la vista activa (ver script.js) -->
      <div class="search-box">
        <div class="search-wrap">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.4-3.4"/></svg>
          <input id="searchInput" type="text" placeholder="Buscar…" autocomplete="off">
        </div>
        <!-- Sugerencias flotantes: solo se usan dentro de la vista Venta -->
        <div class="search-suggestions" id="searchSuggestions"></div>
      </div>

      <!-- Pestañas principales -->
      <nav class="sub-nav" id="subNav">
        <button class="sub-nav-btn is-active" data-view="venta">Venta</button>
        <button class="sub-nav-btn" data-view="inventario">Inventario</button>
        <button class="sub-nav-btn" data-view="clientes">Clientes</button>
        <button class="sub-nav-btn" data-view="garantias">Garantías</button>
        <button class="sub-nav-btn" data-view="weborders">Web orders</button>
      </nav>
    </div>
  </header>

  <!-- ============================================================
       CONTENIDO PRINCIPAL: se reconstruye por completo en cada
       cambio de vista dentro de script.js (ver renderMain)
       ============================================================ -->
  <main class="main" id="main"></main>

  <!-- ============================================================
       BARRA DE ACCESOS RÁPIDOS (F3–F6): solo visible en la vista
       de Venta, mientras no se esté mostrando el resultado de una
       búsqueda de artículos
       ============================================================ -->
  <div class="shortcuts-bar" id="shortcutsBar" hidden></div>

  <!-- ============================================================
       BARRA INFERIOR: fecha, hora, asesor y número de caja
       ============================================================ -->
  <footer class="statusbar">
    <div class="status-item">
      <span class="status-label">Fecha</span>
      <span class="status-value" id="statusFecha">—</span>
    </div>
    <div class="status-divider"></div>
    <div class="status-item">
      <span class="status-label">Hora</span>
      <span class="status-value" id="statusHora">—</span>
    </div>
    <div class="status-divider"></div>
    <div class="status-item">
      <span class="status-label">Asesor</span>
      <span class="status-value" id="statusCajero">Cargando…</span>
    </div>
    <div class="status-divider"></div>
    <div class="status-item">
      <span class="status-label">Caja</span>
      <span class="status-value" id="statusCaja">—</span>
    </div>
  </footer>

</div>

<!-- ============================================================
     MODAL: ficha completa de un artículo de inventario
     (se abre desde los resultados de búsqueda en Venta)
     ============================================================ -->
<div class="modal-overlay" id="modalInventario">
  <div class="modal-card modal-card--wide">
    <button class="modal-close" data-close-modal>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 5l14 14M19 5L5 19"/></svg>
    </button>
    <div id="modalInventarioContent"></div>
  </div>
</div>

<!-- ============================================================
     MODAL: detalle completo de un cliente con crédito activo
     ============================================================ -->
<div class="modal-overlay" id="modalCliente">
  <div class="modal-card modal-card--wide">
    <button class="modal-close" data-close-modal>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 5l14 14M19 5L5 19"/></svg>
    </button>
    <div id="modalClienteContent"></div>
  </div>
</div>

<!-- ============================================================
     PANTALLA COMPLETA: formulario para aplicar una garantía
     ============================================================ -->
<div class="fullscreen-overlay" id="garantiaOverlay">
  <div class="fullscreen-overlay-inner" id="garantiaOverlayContent"></div>
</div>


<!-- Modal de cobro: método de pago y efectivo -->
<div class="modal-overlay" id="modalPago">
  <div class="modal-card modal-card--payment">
    <button class="modal-close" data-close-modal aria-label="Cerrar">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 5l14 14M19 5L5 19"/></svg>
    </button>
    <div id="modalPagoContent"></div>
  </div>
</div>

<!-- Modal de ticket digital para el cliente -->
<div class="modal-overlay" id="modalTicketCliente">
  <div class="modal-card modal-card--wide">
    <div id="ticketClienteContent"></div>
  </div>
</div>

<script src="../../JavaScript/PuntoDeVenta/script.js"></script>
</body>
</html>
