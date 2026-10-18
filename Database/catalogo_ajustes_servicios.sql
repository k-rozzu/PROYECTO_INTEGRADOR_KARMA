-- =====================================================================================
-- KARMA · Catálogo — ajustes de servicios e imágenes (2026-10-05)
-- Idempotente: se puede ejecutar varias veces. No borra filas ni tablas.
--   1. Cada vehículo muestra UNA sola imagen: se quita la imagen extra (productos_web.galeria).
--   2. Servicios que anuncia cada sucursal: solo los que maneja la agencia (sin prueba de manejo,
--      seminuevos ni promociones).
--   3. El texto corto de los vehículos ya no menciona la prueba de manejo.
-- La tabla `promociones` se conserva sin cambios, pero el catálogo ya no la consulta.
-- =====================================================================================
USE pos_multisede;

-- 1. Una sola imagen por vehículo
UPDATE productos_web
   SET galeria = NULL
 WHERE seccion = 'vehiculos' AND galeria IS NOT NULL;

-- 2. Servicios por sucursal (se muestran en sucursales.php)
UPDATE sucursales
   SET servicios = 'Venta de vehículos nuevos,Simulación de crédito,Apartado de vehículos,Seguros,Gestoría de placas y trámites,Garantía extendida,Plan de mantenimiento prepagado,Accesorios originales e instalación,Polarizado,Orden de servicio de taller,Refacciones originales'
 WHERE servicios IS NULL
    OR servicios <> 'Venta de vehículos nuevos,Simulación de crédito,Apartado de vehículos,Seguros,Gestoría de placas y trámites,Garantía extendida,Plan de mantenimiento prepagado,Accesorios originales e instalación,Polarizado,Orden de servicio de taller,Refacciones originales';

-- 3. Textos de los vehículos: ya no se ofrece prueba de manejo
UPDATE productos
   SET detalle = REPLACE(detalle, 'listo para prueba de manejo en agencia', 'listo para entrega en agencia')
 WHERE detalle LIKE '%listo para prueba de manejo en agencia%';
