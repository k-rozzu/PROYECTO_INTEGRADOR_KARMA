<?php
declare(strict_types=1);
/* KARMA · Catálogo — Accesorios (misma infraestructura de compra que las refacciones) */
require_once __DIR__ . '/includes/listado.php';

catPaginaListado([
    'seccion' => 'accesorios',
    'titulo' => 'Accesorios',
    'activo' => 'accesorios',
    'intro' => 'Tapetes, portaequipaje, organizadores, fundas, equipaje y carga eléctrica para personalizar y proteger tu vehículo. Recógelos en sucursal o recíbelos en casa.',
    'placeholder' => 'Buscar accesorio o modelo…',
    'descripcion' => 'Accesorios para Audi, Porsche y Ducati: interior, exterior, protección, equipaje y carga eléctrica.'
]);
