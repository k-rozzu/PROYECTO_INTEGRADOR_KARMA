<?php
declare(strict_types=1);
/* KARMA · Catálogo — Modelos (vehículos Audi, Porsche y motocicletas Ducati) */
require_once __DIR__ . '/includes/listado.php';

catPaginaListado([
    'seccion' => 'vehiculos',
    'titulo' => 'Modelos',
    'activo' => 'modelos',
    'intro' => 'Explora los 45 modelos de Audi, Porsche y Ducati. Filtra por marca, carrocería, motorización, tracción, año y precio, y consulta las unidades disponibles en tu sucursal.',
    'placeholder' => 'Buscar modelo, motor, color…',
    'descripcion' => 'Catálogo de vehículos Audi y Porsche y motocicletas Ducati con disponibilidad por sucursal en Manzanillo y Colima.'
]);
