-- =====================================================================================
-- KARMA / pos_multisede — catalogo_productos.sql
-- Productos del CATÁLOGO web: 15 Audi + 15 Porsche + 15 Ducati (45 vehículos) y 10 refacciones por
-- marca (30 refacciones) = 75 productos, más 9 accesorios de demostración (3 por marca).
--
-- * Los 75 productos YA EXISTÍAN en la base (ids 11-85, códigos KRM-CAT-*): aquí se reconstruyen con
--   EXACTAMENTE los mismos datos (códigos, VIN, precios, colores) para poder recrear la base desde cero.
--   Cada INSERT usa WHERE NOT EXISTS por codigo_barras, así que NUNCA duplica ni sobrescribe nada.
-- * productos_web guarda la ficha del sitio (imagen, galería, sección, especificaciones, textos).
-- * Sucursal COLIMA + inventario propio. El inventario es INDEPENDIENTE por sucursal: la misma fila de
--   `productos` tiene una fila en `inventarios` por cada sucursal (UNIQUE id_sucursal + id_producto).
--   Si se vende 1 unidad en Manzanillo solo baja la fila de Manzanillo.
-- * Seguro de reimportar: no borra, no reinicia existencias que ya cambiaron por ventas.
--
-- REQUISITO: importar antes catalogo_estructura.sql (crea productos_web y columnas de sucursales).
--
-- IMÁGENES: las rutas son relativas a la raíz del proyecto (assets/Catalogo/...).
--   Para cambiar la imagen de un producto basta con reemplazar el archivo .webp con el mismo nombre,
--   o actualizar la ruta:  UPDATE productos_web SET imagen = 'assets/Catalogo/...' WHERE id_producto = N;
-- =====================================================================================

SET NAMES utf8mb4;
USE pos_multisede;

-- ===== 1. CATEGORÍAS (las mismas que ya usa el POS) =====
INSERT INTO categorias (nombre_categoria, descripcion) SELECT 'Audi', 'Vehículos Audi' WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Audi');
INSERT INTO categorias (nombre_categoria, descripcion) SELECT 'Porsche', 'Vehículos Porsche' WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Porsche');
INSERT INTO categorias (nombre_categoria, descripcion) SELECT 'Ducati', 'Motocicletas Ducati' WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Ducati');
INSERT INTO categorias (nombre_categoria, descripcion) SELECT 'Refacciones', 'Refacciones y piezas' WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Refacciones');

-- ===== 2. LOS 75 PRODUCTOS DEL CATÁLOGO (datos idénticos a los de la base actual) =====
-- Audi A3 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-01', 'A3 2025', 'Audi A3 2025, motor 1.4L TFSI Turbo.', 665281.24, 'Audi', 'A3', 2025, 'auto', 'Gris Nardo', '#7A7D80', '1.4L TFSI Turbo', '1395 cc', 'Audi A3 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WAUZZZZZ0SS100296', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-01');
-- Audi A4 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-02', 'A4 2024', 'Audi A4 2024, motor 2.0L TFSI Turbo.', 812356.66, 'Audi', 'A4', 2024, 'auto', 'Blanco Glaciar', '#F2F2EF', '2.0L TFSI Turbo', '1984 cc', 'Audi A4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WAUZZZZZ0RS100333', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-02');
-- Audi A5 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-03', 'A5 2025', 'Audi A5 2025, motor 2.0L TFSI Turbo.', 946010.16, 'Audi', 'A5', 2025, 'auto', 'Gris Nardo', '#7A7D80', '2.0L TFSI Turbo', '1984 cc', 'Audi A5 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WAUZZZZZ0SS100370', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-03');
-- Audi A6 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-04', 'A6 2025', 'Audi A6 2025, motor 3.0L V6 TFSI.', 1166650.62, 'Audi', 'A6', 2025, 'auto', 'Gris Nardo', '#7A7D80', '3.0L V6 TFSI', '2995 cc', 'Audi A6 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0SS100407', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-04');
-- Audi A7 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-05', 'A7 2023', 'Audi A7 2023, motor 3.0L V6 TFSI.', 1206138.70, 'Audi', 'A7', 2023, 'auto', 'Gris Nardo', '#7A7D80', '3.0L V6 TFSI', '2995 cc', 'Audi A7 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0PS100444', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-05');
-- Audi A8 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-06', 'A8 2023', 'Audi A8 2023, motor 3.0L V6 TFSI.', 1809054.93, 'Audi', 'A8', 2023, 'auto', 'Rojo Tango', '#8C1D2B', '3.0L V6 TFSI', '2995 cc', 'Audi A8 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Beige', 'WAUZZZZZ0PS100481', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-06');
-- Audi Q3 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-07', 'Q3 2025', 'Audi Q3 2025, motor 2.0L TFSI Turbo.', 858687.40, 'Audi', 'Q3', 2025, 'auto', 'Blanco Glaciar', '#F2F2EF', '2.0L TFSI Turbo', '1984 cc', 'Audi Q3 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0SS100518', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-07');
-- Audi Q5 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-08', 'Q5 2025', 'Audi Q5 2025, motor 2.0L TFSI Turbo.', 1006865.63, 'Audi', 'Q5', 2025, 'auto', 'Rojo Tango', '#8C1D2B', '2.0L TFSI Turbo', '1984 cc', 'Audi Q5 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0SS100555', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-08');
-- Audi Q7 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-09', 'Q7 2024', 'Audi Q7 2024, motor 3.0L V6 TFSI.', 1398540.24, 'Audi', 'Q7', 2024, 'auto', 'Rojo Tango', '#8C1D2B', '3.0L V6 TFSI', '2995 cc', 'Audi Q7 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0RS100592', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-09');
-- Audi Q8 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-10', 'Q8 2023', 'Audi Q8 2023, motor 3.0L V6 TFSI.', 1743576.89, 'Audi', 'Q8', 2023, 'auto', 'Blanco Glaciar', '#F2F2EF', '3.0L V6 TFSI', '2995 cc', 'Audi Q8 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0PS100629', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-10');
-- Audi RS3 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-11', 'RS3 2024', 'Audi RS3 2024, motor 2.5L TFSI Turbo 5-cil..', 1303929.87, 'Audi', 'RS3', 2024, 'auto', 'Negro Mythos', '#101012', '2.5L TFSI Turbo 5-cil.', '2480 cc', 'Audi RS3 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0RS100666', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-11');
-- Audi RS5 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-12', 'RS5 2024', 'Audi RS5 2024, motor 2.9L V6 Biturbo.', 1579878.48, 'Audi', 'RS5', 2024, 'auto', 'Gris Nardo', '#7A7D80', '2.9L V6 Biturbo', '2894 cc', 'Audi RS5 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0RS100703', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-12');
-- Audi RS6 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-13', 'RS6 2023', 'Audi RS6 2023, motor 4.0L V8 Biturbo.', 2480657.88, 'Audi', 'RS6', 2023, 'auto', 'Negro Mythos', '#101012', '4.0L V8 Biturbo', '3993 cc', 'Audi RS6 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0PS100740', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-13');
-- Audi RS7 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-14', 'RS7 2025', 'Audi RS7 2025, motor 4.0L V8 Biturbo.', 2297617.75, 'Audi', 'RS7', 2025, 'auto', 'Negro Mythos', '#101012', '4.0L V8 Biturbo', '3993 cc', 'Audi RS7 equipado de fábrica, listo para entrega en agencia.', NULL, 'quattro (AWD)', NULL, 'Negro', 'WAUZZZZZ0SS100777', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-14');
-- Audi R8 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-AUDI-15', 'R8 2025', 'Audi R8 2025, motor 5.2L V10 FSI.', 3469997.91, 'Audi', 'R8', 2025, 'auto', 'Azul Ultra', '#1F3B66', '5.2L V10 FSI', '5204 cc', 'Audi R8 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WAUZZZZZ0SS100814', 'assets/Modelos_3D/id25_KRM-CAT-AUDI-15_audiR8_2025_AzulUltra.glb'
  FROM categorias c WHERE c.nombre_categoria = 'Audi'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-15');
-- Porsche 718 Cayman 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-01', '718 Cayman 2024', 'Porsche 718 Cayman 2024, motor 2.0L Turbo Flat-4.', 1361240.78, 'Porsche', '718 Cayman', 2024, 'auto', 'Blanco Carrara', '#EDEDEA', '2.0L Turbo Flat-4', '1988 cc', 'Porsche 718 Cayman equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0RS100851', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-01');
-- Porsche 718 Boxster 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-02', '718 Boxster 2025', 'Porsche 718 Boxster 2025, motor 2.0L Turbo Flat-4.', 1465107.75, 'Porsche', '718 Boxster', 2025, 'auto', 'Azul Gentian', '#1B3A6B', '2.0L Turbo Flat-4', '1988 cc', 'Porsche 718 Boxster equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0SS100888', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-02');
-- Porsche 911 Carrera 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-03', '911 Carrera 2024', 'Porsche 911 Carrera 2024, motor 3.0L Boxer Biturbo.', 1996608.97, 'Porsche', '911 Carrera', 2024, 'auto', 'Azul Gentian', '#1B3A6B', '3.0L Boxer Biturbo', '2981 cc', 'Porsche 911 Carrera equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0RS100925', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-03');
-- Porsche 911 Carrera S 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-04', '911 Carrera S 2023', 'Porsche 911 Carrera S 2023, motor 3.0L Boxer Biturbo.', 2338828.86, 'Porsche', '911 Carrera S', 2023, 'auto', 'Blanco Carrara', '#EDEDEA', '3.0L Boxer Biturbo', '2981 cc', 'Porsche 911 Carrera S equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0PS100962', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-04');
-- Porsche 911 Turbo 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-05', '911 Turbo 2024', 'Porsche 911 Turbo 2024, motor 3.7L Boxer Biturbo.', 3646135.38, 'Porsche', '911 Turbo', 2024, 'auto', 'Blanco Carrara', '#EDEDEA', '3.7L Boxer Biturbo', '3745 cc', 'Porsche 911 Turbo equipado de fábrica, listo para entrega en agencia.', NULL, 'AWD', NULL, 'Negro', 'WP0ZZZZZ0RS100999', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-05');
-- Porsche 911 GT3 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-06', '911 GT3 2023', 'Porsche 911 GT3 2023, motor 4.0L Boxer Atmosférico.', 3520336.58, 'Porsche', '911 GT3', 2023, 'auto', 'Rojo Carmín', '#9E1B2E', '4.0L Boxer Atmosférico', '3996 cc', 'Porsche 911 GT3 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0PS101036', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-06');
-- Porsche 911 GT3 RS 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-07', '911 GT3 RS 2025', 'Porsche 911 GT3 RS 2025, motor 4.0L Boxer Atmosférico.', 4209809.72, 'Porsche', '911 GT3 RS', 2025, 'auto', 'Gris GT Plata', '#9EA0A1', '4.0L Boxer Atmosférico', '3996 cc', 'Porsche 911 GT3 RS equipado de fábrica, listo para entrega en agencia.', NULL, 'AWD', NULL, 'Negro', 'WP0ZZZZZ0SS101073', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-07');
-- Porsche 911 Targa 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-08', '911 Targa 2024', 'Porsche 911 Targa 2024, motor 3.0L Boxer Biturbo.', 2413985.87, 'Porsche', '911 Targa', 2024, 'auto', 'Negro Jeweled', '#141414', '3.0L Boxer Biturbo', '2981 cc', 'Porsche 911 Targa equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0RS101110', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-08');
-- Porsche Taycan 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-09', 'Taycan 2025', 'Porsche Taycan 2025, motor Eléctrico de doble motor.', 2492779.35, 'Porsche', 'Taycan', 2025, 'auto', 'Blanco Carrara', '#EDEDEA', 'Eléctrico de doble motor', '—', 'Porsche Taycan equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0SS101147', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-09');
-- Porsche Taycan Turbo 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-10', 'Taycan Turbo 2023', 'Porsche Taycan Turbo 2023, motor Eléctrico de doble motor.', 3296579.71, 'Porsche', 'Taycan Turbo', 2023, 'auto', 'Azul Gentian', '#1B3A6B', 'Eléctrico de doble motor', '—', 'Porsche Taycan Turbo equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0PS101184', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-10');
-- Porsche Panamera 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-11', 'Panamera 2023', 'Porsche Panamera 2023, motor 2.9L V6 Biturbo.', 2010461.38, 'Porsche', 'Panamera', 2023, 'auto', 'Rojo Carmín', '#9E1B2E', '2.9L V6 Biturbo', '2894 cc', 'Porsche Panamera equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0PS101221', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-11');
-- Porsche Panamera Turbo 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-12', 'Panamera Turbo 2025', 'Porsche Panamera Turbo 2025, motor 4.0L V8 Biturbo.', 2846312.51, 'Porsche', 'Panamera Turbo', 2025, 'auto', 'Azul Gentian', '#1B3A6B', '4.0L V8 Biturbo', '3996 cc', 'Porsche Panamera Turbo equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, 'Negro', 'WP0ZZZZZ0SS101258', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-12');
-- Porsche Macan 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-13', 'Macan 2024', 'Porsche Macan 2024, motor 2.0L Turbo.', 1387139.15, 'Porsche', 'Macan', 2024, 'auto', 'Blanco Carrara', '#EDEDEA', '2.0L Turbo', '1984 cc', 'Porsche Macan equipado de fábrica, listo para entrega en agencia.', NULL, 'AWD', NULL, 'Negro', 'WP0ZZZZZ0RS101295', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-13');
-- Porsche Cayenne 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-14', 'Cayenne 2023', 'Porsche Cayenne 2023, motor 3.0L V6 Turbo.', 1751851.73, 'Porsche', 'Cayenne', 2023, 'auto', 'Gris GT Plata', '#9EA0A1', '3.0L V6 Turbo', '2995 cc', 'Porsche Cayenne equipado de fábrica, listo para entrega en agencia.', NULL, 'AWD', NULL, 'Negro', 'WP0ZZZZZ0PS101332', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-14');
-- Porsche Cayenne Turbo 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-POR-15', 'Cayenne Turbo 2023', 'Porsche Cayenne Turbo 2023, motor 4.0L V8 Biturbo.', 2825169.72, 'Porsche', 'Cayenne Turbo', 2023, 'auto', 'Negro Jeweled', '#141414', '4.0L V8 Biturbo', '3996 cc', 'Porsche Cayenne Turbo equipado de fábrica, listo para entrega en agencia.', NULL, 'AWD', NULL, 'Negro', 'WP0ZZZZZ0PS101369', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Porsche'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-15');
-- Ducati Panigale V2 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-01', 'Panigale V2 2025', 'Ducati Panigale V2 2025, motor V2 90°.', 400688.50, 'Ducati', 'Panigale V2', 2025, 'moto', 'Gris Antracita', '#4A4A4A', 'V2 90°', '955 cc', 'Ducati Panigale V2 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0SS101406', 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb'
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-01');
-- Ducati Panigale V4 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-02', 'Panigale V4 2024', 'Ducati Panigale V4 2024, motor V4 Desmosedici Stradale.', 615698.60, 'Ducati', 'Panigale V4', 2024, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Desmosedici Stradale', '1103 cc', 'Ducati Panigale V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0RS101443', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-02');
-- Ducati Panigale V4 S 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-03', 'Panigale V4 S 2025', 'Ducati Panigale V4 S 2025, motor V4 Desmosedici Stradale.', 584572.86, 'Ducati', 'Panigale V4 S', 2025, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Desmosedici Stradale', '1103 cc', 'Ducati Panigale V4 S equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0SS101480', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-03');
-- Ducati Monster 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-04', 'Monster 2023', 'Ducati Monster 2023, motor V2 Testastretta.', 332543.44, 'Ducati', 'Monster', 2023, 'moto', 'Negro Mate', '#1A1A1A', 'V2 Testastretta', '937 cc', 'Ducati Monster equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0PS101517', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-04');
-- Ducati Monster SP 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-05', 'Monster SP 2025', 'Ducati Monster SP 2025, motor V2 Testastretta.', 374228.00, 'Ducati', 'Monster SP', 2025, 'moto', 'Gris Antracita', '#4A4A4A', 'V2 Testastretta', '937 cc', 'Ducati Monster SP equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0SS101554', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-05');
-- Ducati Multistrada V2 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-06', 'Multistrada V2 2024', 'Ducati Multistrada V2 2024, motor V2 Testastretta.', 371609.38, 'Ducati', 'Multistrada V2', 2024, 'moto', 'Blanco Dark', '#E7E7E4', 'V2 Testastretta', '937 cc', 'Ducati Multistrada V2 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0RS101591', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-06');
-- Ducati Multistrada V4 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-07', 'Multistrada V4 2023', 'Ducati Multistrada V4 2023, motor V4 Granturismo.', 485963.66, 'Ducati', 'Multistrada V4', 2023, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Granturismo', '1158 cc', 'Ducati Multistrada V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0PS101628', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-07');
-- Ducati Diavel V4 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-08', 'Diavel V4 2023', 'Ducati Diavel V4 2023, motor V4 Granturismo.', 510005.49, 'Ducati', 'Diavel V4', 2023, 'moto', 'Rojo Ducati', '#9E1B2E', 'V4 Granturismo', '1158 cc', 'Ducati Diavel V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0PS101665', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-08');
-- Ducati Streetfighter V2 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-09', 'Streetfighter V2 2023', 'Ducati Streetfighter V2 2023, motor V2 Testastretta.', 416324.43, 'Ducati', 'Streetfighter V2', 2023, 'moto', 'Blanco Dark', '#E7E7E4', 'V2 Testastretta', '955 cc', 'Ducati Streetfighter V2 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0PS101702', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-09');
-- Ducati Streetfighter V4 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-10', 'Streetfighter V4 2024', 'Ducati Streetfighter V4 2024, motor V4 Desmosedici Stradale.', 599051.87, 'Ducati', 'Streetfighter V4', 2024, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Desmosedici Stradale', '1103 cc', 'Ducati Streetfighter V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0RS101739', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-10');
-- Ducati Scrambler Icon 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-11', 'Scrambler Icon 2024', 'Ducati Scrambler Icon 2024, motor L-Twin Desmodue.', 279596.86, 'Ducati', 'Scrambler Icon', 2024, 'moto', 'Gris Antracita', '#4A4A4A', 'L-Twin Desmodue', '803 cc', 'Ducati Scrambler Icon equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0RS101776', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-11');
-- Ducati Scrambler Nightshift 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-12', 'Scrambler Nightshift 2023', 'Ducati Scrambler Nightshift 2023, motor L-Twin Desmodue.', 288140.62, 'Ducati', 'Scrambler Nightshift', 2023, 'moto', 'Rojo Ducati', '#9E1B2E', 'L-Twin Desmodue', '803 cc', 'Ducati Scrambler Nightshift equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0PS101813', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-12');
-- Ducati DesertX 2025
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-13', 'DesertX 2025', 'Ducati DesertX 2025, motor L-Twin Testastretta.', 438049.83, 'Ducati', 'DesertX', 2025, 'moto', 'Gris Antracita', '#4A4A4A', 'L-Twin Testastretta', '937 cc', 'Ducati DesertX equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0SS101850', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-13');
-- Ducati Hypermotard 2024
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-14', 'Hypermotard 2024', 'Ducati Hypermotard 2024, motor V2 Testastretta.', 444801.61, 'Ducati', 'Hypermotard', 2024, 'moto', 'Rojo Ducati', '#9E1B2E', 'V2 Testastretta', '937 cc', 'Ducati Hypermotard equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0RS101887', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-14');
-- Ducati SuperSport 950 2023
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-DUC-15', 'SuperSport 950 2023', 'Ducati SuperSport 950 2023, motor V2 Testastretta.', 359002.51, 'Ducati', 'SuperSport 950', 2023, 'moto', 'Blanco Dark', '#E7E7E4', 'V2 Testastretta', '937 cc', 'Ducati SuperSport 950 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, NULL, NULL, 'ZDMZZZZZ0PS101924', NULL
  FROM categorias c WHERE c.nombre_categoria = 'Ducati'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-15');
-- Audi Filtro de aceite Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-01', 'Filtro de aceite Audi', 'Filtro de aceite original/compatible para Audi RS5.', 508.87, 'Audi', 'RS5', NULL, 'refaccion', 'Blanco', '#E6E6E2', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS5', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-01');
-- Audi Filtro de aire Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-02', 'Filtro de aire Audi', 'Filtro de aire original/compatible para Audi A7.', 666.81, 'Audi', 'A7', NULL, 'refaccion', 'Blanco hueso', '#E8E4D8', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi A7', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-02');
-- Audi Juego de pastillas de freno delanteras Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-03', 'Juego de pastillas de freno delanteras Audi', 'Juego de pastillas de freno delanteras original/compatible para Audi RS6.', 3984.05, 'Audi', 'RS6', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS6', 'Delantera', NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-03');
-- Audi Juego de pastillas de freno traseras Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-04', 'Juego de pastillas de freno traseras Audi', 'Juego de pastillas de freno traseras original/compatible para Audi R8.', 3560.70, 'Audi', 'R8', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi R8', 'Trasera', NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-04');
-- Audi Disco de freno delantero Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-05', 'Disco de freno delantero Audi', 'Disco de freno delantero original/compatible para Audi RS3.', 6580.71, 'Audi', 'RS3', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS3', 'Delantera', 'Izquierdo', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-05');
-- Audi Disco de freno trasero Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-06', 'Disco de freno trasero Audi', 'Disco de freno trasero original/compatible para Audi RS3.', 5907.23, 'Audi', 'RS3', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS3', 'Trasera', 'Derecho', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-06');
-- Audi Juego de bujías Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-07', 'Juego de bujías Audi', 'Juego de bujías original/compatible para Audi A6.', 1369.46, 'Audi', 'A6', NULL, 'refaccion', 'Plata', '#BFC3C7', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi A6', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-07');
-- Audi Batería Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-08', 'Batería Audi', 'Batería original/compatible para Audi RS6.', 4918.41, 'Audi', 'RS6', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS6', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-08');
-- Audi Kit de distribución Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-09', 'Kit de distribución Audi', 'Kit de distribución original/compatible para Audi RS6.', 10462.38, 'Audi', 'RS6', NULL, 'refaccion', 'Negro', '#202124', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS6', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-09');
-- Audi Bomba de agua Audi
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-AUDI-10', 'Bomba de agua Audi', 'Bomba de agua original/compatible para Audi R8.', 3312.33, 'Audi', 'R8', NULL, 'refaccion', 'Aluminio', '#A9ADB2', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi R8', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-10');
-- Porsche Filtro de aceite Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-01', 'Filtro de aceite Porsche', 'Filtro de aceite original/compatible para Porsche 911 GT3.', 479.12, 'Porsche', '911 GT3', NULL, 'refaccion', 'Blanco', '#E6E6E2', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 911 GT3', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-01');
-- Porsche Filtro de aire Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-02', 'Filtro de aire Porsche', 'Filtro de aire original/compatible para Porsche 718 Boxster.', 662.57, 'Porsche', '718 Boxster', NULL, 'refaccion', 'Blanco hueso', '#E8E4D8', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 718 Boxster', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-02');
-- Porsche Juego de pastillas de freno delanteras Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-03', 'Juego de pastillas de freno delanteras Porsche', 'Juego de pastillas de freno delanteras original/compatible para Porsche Cayenne Turbo.', 4526.14, 'Porsche', 'Cayenne Turbo', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Cayenne Turbo', 'Delantera', NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-03');
-- Porsche Juego de pastillas de freno traseras Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-04', 'Juego de pastillas de freno traseras Porsche', 'Juego de pastillas de freno traseras original/compatible para Porsche Macan.', 3682.97, 'Porsche', 'Macan', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Macan', 'Trasera', NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-04');
-- Porsche Disco de freno delantero Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-05', 'Disco de freno delantero Porsche', 'Disco de freno delantero original/compatible para Porsche 718 Cayman.', 6518.07, 'Porsche', '718 Cayman', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 718 Cayman', 'Delantera', 'Izquierdo', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-05');
-- Porsche Disco de freno trasero Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-06', 'Disco de freno trasero Porsche', 'Disco de freno trasero original/compatible para Porsche Taycan Turbo.', 6321.92, 'Porsche', 'Taycan Turbo', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Taycan Turbo', 'Trasera', 'Derecho', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-06');
-- Porsche Juego de bujías Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-07', 'Juego de bujías Porsche', 'Juego de bujías original/compatible para Porsche 718 Boxster.', 1503.80, 'Porsche', '718 Boxster', NULL, 'refaccion', 'Plata', '#BFC3C7', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 718 Boxster', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-07');
-- Porsche Batería Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-08', 'Batería Porsche', 'Batería original/compatible para Porsche Cayenne.', 4841.58, 'Porsche', 'Cayenne', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Cayenne', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-08');
-- Porsche Kit de distribución Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-09', 'Kit de distribución Porsche', 'Kit de distribución original/compatible para Porsche Macan.', 9851.28, 'Porsche', 'Macan', NULL, 'refaccion', 'Negro', '#202124', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Macan', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-09');
-- Porsche Bomba de agua Porsche
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-POR-10', 'Bomba de agua Porsche', 'Bomba de agua original/compatible para Porsche 911 Carrera.', 3385.95, 'Porsche', '911 Carrera', NULL, 'refaccion', 'Aluminio', '#A9ADB2', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 911 Carrera', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-10');
-- Ducati Filtro de aceite Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-01', 'Filtro de aceite Ducati', 'Filtro de aceite original/compatible para Ducati Diavel V4.', 407.17, 'Ducati', 'Diavel V4', NULL, 'refaccion', 'Blanco', '#E6E6E2', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Diavel V4', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-01');
-- Ducati Filtro de aire Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-02', 'Filtro de aire Ducati', 'Filtro de aire original/compatible para Ducati Panigale V4 S.', 500.45, 'Ducati', 'Panigale V4 S', NULL, 'refaccion', 'Blanco hueso', '#E8E4D8', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Panigale V4 S', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-02');
-- Ducati Juego de pastillas de freno delanteras Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-03', 'Juego de pastillas de freno delanteras Ducati', 'Juego de pastillas de freno delanteras original/compatible para Ducati Hypermotard.', 2440.93, 'Ducati', 'Hypermotard', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Hypermotard', 'Delantera', NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-03');
-- Ducati Juego de pastillas de freno traseras Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-04', 'Juego de pastillas de freno traseras Ducati', 'Juego de pastillas de freno traseras original/compatible para Ducati Monster.', 2244.11, 'Ducati', 'Monster', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Monster', 'Trasera', NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-04');
-- Ducati Disco de freno delantero Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-05', 'Disco de freno delantero Ducati', 'Disco de freno delantero original/compatible para Ducati DesertX.', 4354.51, 'Ducati', 'DesertX', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati DesertX', 'Delantera', 'Izquierdo', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-05');
-- Ducati Cadena de transmisión Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-06', 'Cadena de transmisión Ducati', 'Cadena de transmisión original/compatible para Ducati Monster.', 3205.62, 'Ducati', 'Monster', NULL, 'refaccion', 'Dorado', '#B8923A', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Monster', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-06');
-- Ducati Kit de bujías Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-07', 'Kit de bujías Ducati', 'Kit de bujías original/compatible para Ducati Multistrada V4.', 1025.26, 'Ducati', 'Multistrada V4', NULL, 'refaccion', 'Plata', '#BFC3C7', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Multistrada V4', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-07');
-- Ducati Batería Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-08', 'Batería Ducati', 'Batería original/compatible para Ducati Scrambler Icon.', 2547.34, 'Ducati', 'Scrambler Icon', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Scrambler Icon', NULL, NULL, NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-08');
-- Ducati Maneta de freno/embrague Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-09', 'Maneta de freno/embrague Ducati', 'Maneta de freno/embrague original/compatible para Ducati SuperSport 950.', 1203.37, 'Ducati', 'SuperSport 950', NULL, 'refaccion', 'Negro anodizado', '#2A2B2F', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati SuperSport 950', NULL, 'Derecho', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-09');
-- Ducati Espejo retrovisor Ducati
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle, compatibilidad, traccion, lado, color_interior, vin, modelo_3d)
SELECT c.id_categoria, 'KRM-CAT-REF-DUC-10', 'Espejo retrovisor Ducati', 'Espejo retrovisor original/compatible para Ducati Panigale V4.', 854.10, 'Ducati', 'Panigale V4', NULL, 'refaccion', 'Negro mate', '#1A1A1A', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Panigale V4', NULL, 'Izquierdo', NULL, NULL, NULL
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-10');

-- ===== 3. ACCESORIOS DE DEMOSTRACIÓN (3 por marca) =====
-- Usan tipo 'refaccion' y la categoría Refacciones para que el POS también pueda venderlos en mostrador;
-- en el sitio web se separan por productos_web.seccion = 'accesorios'.
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-AUDI-01', 'Tapetes de hule para todo clima Audi Q5', 'Juego de tapetes de hule a la medida para Audi Q5.', 3290.00, 'Audi', 'Q5', NULL, 'refaccion', 'Negro', '#1C1C1E', 'Juego de 4 piezas con bordes elevados.', 'Audi Q5'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-AUDI-01');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-AUDI-02', 'Barras portaequipaje para techo Audi Q3', 'Barras transversales de aluminio para el techo del Audi Q3.', 6890.00, 'Audi', 'Q3', NULL, 'refaccion', 'Aluminio', '#A9ADB2', 'Par de barras con cerradura antirrobo.', 'Audi Q3'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-AUDI-02');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-AUDI-03', 'Organizador plegable de cajuela Audi', 'Organizador plegable con divisiones ajustables para cajuela.', 1450.00, 'Audi', 'A4', NULL, 'refaccion', 'Negro', '#202124', 'Divisiones ajustables y base antiderrapante.', 'Audi A4 / A6 / Q5'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-AUDI-03');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-POR-01', 'Funda de interior a la medida Porsche 911', 'Funda transpirable a la medida para el Porsche 911.', 9850.00, 'Porsche', '911 Carrera', NULL, 'refaccion', 'Gris', '#6E7175', 'Funda para uso en interior con bolsa de guardado.', 'Porsche 911 (992)'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-01');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-POR-02', 'Tapetes premium con ribete Porsche Macan', 'Tapetes de alfombra premium con ribete para Porsche Macan.', 4590.00, 'Porsche', 'Macan', NULL, 'refaccion', 'Negro', '#141414', 'Juego de 4 piezas con respaldo antiderrapante.', 'Porsche Macan'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-02');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-POR-03', 'Cargador portátil para vehículo eléctrico Porsche Taycan', 'Cargador portátil de hasta 11 kW con conector Tipo 2.', 18900.00, 'Porsche', 'Taycan', NULL, 'refaccion', 'Negro', '#1A1A1A', 'Incluye estuche de transporte.', 'Porsche Taycan'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-03');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-DUC-01', 'Maletas laterales rígidas Ducati Multistrada V4', 'Par de maletas laterales de aluminio para Multistrada V4.', 21500.00, 'Ducati', 'Multistrada V4', NULL, 'refaccion', 'Aluminio', '#BFC3C7', 'Par de maletas con soportes de liberación rápida.', 'Ducati Multistrada V4'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-DUC-01');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-DUC-02', 'Parabrisas touring Ducati Multistrada', 'Parabrisas touring de mayor altura para Multistrada.', 4250.00, 'Ducati', 'Multistrada V4', NULL, 'refaccion', 'Transparente', '#D8DDE3', 'Policarbonato de 4 mm con tratamiento antirrayas.', 'Ducati Multistrada V2 / V4'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-DUC-02');
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-DUC-03', 'Funda para motocicleta Ducati', 'Funda de exterior impermeable con protección UV.', 2890.00, 'Ducati', 'Panigale V4', NULL, 'refaccion', 'Negro', '#1A1A1A', 'Incluye orificios para candado y bolsa de transporte.', 'Ducati Panigale / Streetfighter'
  FROM categorias c WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-DUC-03');

-- ===== 4. TRACCIÓN de los vehículos que la tenían vacía (solo se llena donde es NULL) =====
UPDATE productos SET traccion = 'Delantera' WHERE codigo_barras = 'KRM-CAT-AUDI-01' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Delantera' WHERE codigo_barras = 'KRM-CAT-AUDI-02' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Delantera' WHERE codigo_barras = 'KRM-CAT-AUDI-03' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'quattro (AWD)' WHERE codigo_barras = 'KRM-CAT-AUDI-15' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera' WHERE codigo_barras = 'KRM-CAT-POR-01' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera' WHERE codigo_barras = 'KRM-CAT-POR-02' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera' WHERE codigo_barras = 'KRM-CAT-POR-03' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera' WHERE codigo_barras = 'KRM-CAT-POR-04' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera' WHERE codigo_barras = 'KRM-CAT-POR-06' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'AWD' WHERE codigo_barras = 'KRM-CAT-POR-08' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'AWD' WHERE codigo_barras = 'KRM-CAT-POR-09' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'AWD' WHERE codigo_barras = 'KRM-CAT-POR-10' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera' WHERE codigo_barras = 'KRM-CAT-POR-11' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'AWD' WHERE codigo_barras = 'KRM-CAT-POR-12' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-01' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-02' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-03' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-04' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-05' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-06' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-07' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-08' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-09' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-10' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-11' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-12' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-13' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-14' AND (traccion IS NULL OR traccion = '');
UPDATE productos SET traccion = 'Trasera (cadena)' WHERE codigo_barras = 'KRM-CAT-DUC-15' AND (traccion IS NULL OR traccion = '');

-- ===== 5. FICHA WEB (productos_web) =====
-- IMAGEN DEL PRODUCTO: cambia la ruta de `imagen` o reemplaza el archivo con el mismo nombre.
-- GALERÍA: rutas extra separadas por salto de línea (se muestran en la página de detalle).
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Hatchback', 'assets/Catalogo/vehiculos/audi/a3.webp', NULL, 'S tronic de 7 velocidades', '150 hp', '8.4 s', 'El Audi A3 Sportback reúne la esencia premium de Audi en un formato compacto y versátil. Su motor TFSI turbo responde al instante con consumos contenidos, y su interior digital con Audi virtual cockpit lo convierte en el compañero ideal para la ciudad y los viajes de fin de semana.', 'Audi virtual cockpit de 10.25"
Pantalla MMI táctil con Apple CarPlay y Android Auto
Faros LED con firma luminosa diurna
Control de crucero adaptativo y asistente de carril
Modos de manejo Audi drive select
Rines de aleación de 17"', 1
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sedán', 'assets/Catalogo/vehiculos/audi/a4.webp', NULL, 'S tronic de 7 velocidades', '201 hp', '7.3 s', 'El Audi A4 Sedán es un referente del segmento ejecutivo: aplomo en carretera, aislamiento acústico sobresaliente y una cabina que equilibra tecnología y confort. Una elección inteligente para quien recorre largas distancias sin renunciar a la deportividad.', 'Motor 2.0 TFSI con sistema mild hybrid de 12 V
Climatizador automático de tres zonas
Asientos delanteros con ajuste eléctrico
Frenado de emergencia Audi pre sense city
Calaveras LED con intermitentes dinámicos
Cajuela de 460 litros', 2
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/a5.webp', NULL, 'S tronic de 7 velocidades', '201 hp', '7.7 s', 'El Audi A5 Sportback combina la silueta de un coupé con la practicidad de cinco puertas. Líneas fluidas, portón trasero de gran apertura y un habitáculo digital de última generación lo convierten en el gran turismo de la gama media.', 'Diseño Sportback de cinco puertas
Pantalla panorámica curva MMI
Head-up display
Suspensión deportiva
Sistema de audio premium de 16 bocinas
Portón trasero eléctrico', 3
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Sedán', 'assets/Catalogo/vehiculos/audi/a6.webp', NULL, 'S tronic de 7 velocidades', '340 hp', '5.1 s', 'El Audi A6 es la expresión del lujo progresivo: un sedán de gran formato con tracción quattro, motor V6 TFSI y una cabina con doble pantalla táctil con respuesta háptica. Confort de primera clase con la precisión dinámica que distingue a Audi.', 'Motor 3.0 V6 TFSI con mild hybrid de 48 V
Tracción integral quattro
Doble pantalla MMI touch response
Faros HD Matrix LED
Suspensión adaptativa
Cámara de 360° para estacionarse', 4
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-04' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/a7.webp', NULL, 'S tronic de 7 velocidades', '340 hp', '5.3 s', 'El Audi A7 Sportback es un gran turismo de cuatro puertas con alma de coupé. Su diseño escultural, el alerón trasero desplegable y la tracción quattro hacen de cada trayecto una experiencia elegante y emocionante.', 'Alerón trasero activo
Tracción integral quattro
Faros HD Matrix LED
Interior en piel Valcona
Techo panorámico
Paquete de asistentes de conducción Tour', 5
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-05' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sedán de lujo', 'assets/Catalogo/vehiculos/audi/a8.webp', NULL, 'Tiptronic de 8 velocidades', '340 hp', '5.6 s', 'El Audi A8 es el buque insignia de la marca: un sedán de representación con un nivel de refinamiento, silencio y tecnología pensado tanto para quien conduce como para quien viaja atrás. Cada detalle está diseñado para el máximo confort.', 'Suspensión neumática adaptativa
Asientos con masaje y ventilación
Iluminación ambiental de 30 colores
Climatizador de cuatro zonas
Puertas con cierre asistido
Sistema de audio 3D premium', 6
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-06' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/audi/q3.webp', NULL, 'S tronic de 7 velocidades', '190 hp', '7.3 s', 'El Audi Q3 es la SUV compacta para la vida urbana con espíritu aventurero: posición de manejo elevada, cajuela flexible gracias a la banca trasera deslizable y tracción quattro para mayor seguridad en cualquier camino.', 'Tracción integral quattro
Banca trasera deslizable y reclinable
Audi virtual cockpit
Portón trasero eléctrico
Cámara de reversa
Sensores de estacionamiento delanteros y traseros', 7
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-07' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/audi/q5.webp', NULL, 'S tronic de 7 velocidades', '261 hp', '6.1 s', 'El Audi Q5 es la SUV mediana más equilibrada de la gama: espacio para cinco ocupantes, tracción quattro y un motor TFSI que entrega potencia con suavidad. Ideal para la familia que busca versatilidad y prestigio.', 'Tracción quattro con tecnología ultra
Faros LED Matrix
Pantalla MMI de 10.1"
Alerta de tráfico cruzado trasero
Cajuela de 520 litros
Preparación para enganche de remolque', 8
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-08' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'SUV 7 plazas', 'assets/Catalogo/vehiculos/audi/q7.webp', NULL, 'Tiptronic de 8 velocidades', '335 hp', '5.9 s', 'El Audi Q7 ofrece tres filas de asientos, tracción quattro y la serenidad de un vehículo de lujo. Con su motor V6 TFSI y suspensión adaptativa, recorre ciudad y carretera con igual soltura.', 'Tres filas de asientos (7 plazas)
Suspensión neumática adaptativa
Tracción integral quattro
Climatizador de cuatro zonas
Dirección en las cuatro ruedas
Techo panorámico corredizo', 9
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-09' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'SUV coupé', 'assets/Catalogo/vehiculos/audi/q8.webp', NULL, 'Tiptronic de 8 velocidades', '335 hp', '5.9 s', 'El Audi Q8 fusiona la elegancia de un coupé con la presencia de una SUV de lujo. Su parrilla octagonal, las puertas sin marco y una cabina completamente digital lo posicionan como la cumbre de la familia Q.', 'Diseño SUV coupé con puertas sin marco
Rines de 21"
Doble pantalla MMI touch response
Tracción integral quattro
Faros HD Matrix LED
Asistente de conducción en ciudad y autopista', 10
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-10' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Deportivo compacto', 'assets/Catalogo/vehiculos/audi/rs3.webp', NULL, 'S tronic de 7 velocidades', '401 hp', '3.8 s', 'El Audi RS 3 es un compacto de altas prestaciones impulsado por el legendario cinco cilindros turbo. Su sonido inconfundible, el diferencial RS Torque Splitter y la suspensión deportiva convierten cada curva en un momento memorable.', 'Motor 2.5 TFSI de cinco cilindros
RS Torque Splitter con modo RS Torque Rear
Escape deportivo RS
Asientos deportivos RS con costura en panal
Frenos de alto desempeño
Pantallas RS en el virtual cockpit', 11
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-11' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/rs5.webp', NULL, 'Tiptronic de 8 velocidades', '444 hp', '3.9 s', 'El Audi RS 5 Sportback combina cinco puertas con un V6 biturbo de 444 hp y tracción quattro deportiva. Es la definición de un auto de uso diario capaz de emocionar en pista.', 'Motor 2.9 V6 biturbo
Tracción quattro con diferencial deportivo
Suspensión RS con Dynamic Ride Control
Paquete de diseño RS en negro
Escape deportivo RS
Volante deportivo RS en Alcantara', 12
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-12' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Avant', 'assets/Catalogo/vehiculos/audi/rs6.webp', NULL, 'Tiptronic de 8 velocidades', '591 hp', '3.6 s', 'El Audi RS 6 Avant es una de las familiares más deseadas del mundo: un V8 biturbo de 591 hp, carrocería ensanchada y la practicidad de una cajuela de gran capacidad. Desempeño de superdeportivo para el día a día.', 'Motor 4.0 V8 biturbo con mild hybrid
Carrocería ensanchada exclusiva RS
Suspensión neumática adaptativa RS
Dirección en las cuatro ruedas
Frenos RS de alto desempeño
Cajuela de 565 litros', 13
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-13' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/rs7.webp', NULL, 'Tiptronic de 8 velocidades', '591 hp', '3.6 s', 'El Audi RS 7 Sportback lleva el diseño del A7 a su máxima expresión deportiva. Su V8 biturbo, la tracción quattro y la suspensión RS ofrecen un equilibrio único entre lujo, elegancia y desempeño.', 'Motor 4.0 V8 biturbo
Tracción quattro con diferencial deportivo
Faros HD Matrix LED con luz láser
Escape deportivo RS
Asientos RS con ventilación y masaje
Rines de 22"', 14
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-14' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Superdeportivo', 'assets/Catalogo/vehiculos/audi/r8.webp', NULL, 'S tronic de 7 velocidades', '602 hp', '3.1 s', 'El Audi R8 V10 performance es el superdeportivo nacido en las pistas de competencia. Motor central V10 atmosférico, chasis de aluminio y fibra de carbono y tracción quattro para una conexión pura entre piloto y camino.', 'Motor central V10 5.2 FSI atmosférico
Chasis Audi Space Frame de aluminio y CFRP
Tracción integral quattro
Frenos cerámicos disponibles
Audi virtual cockpit con modo de pista
Edición de producción limitada', 15
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-AUDI-15' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/718-cayman.webp', NULL, 'PDK de 7 velocidades', '300 hp', '4.9 s', 'El Porsche 718 Cayman es el deportivo de motor central por excelencia: equilibrio perfecto, dirección precisa y un motor bóxer turbo que responde al instante. Diversión pura en cada curva.', 'Motor central bóxer turbo de cuatro cilindros
Transmisión PDK de 7 velocidades
Porsche Torque Vectoring
Paquete Sport Chrono
Dos cajuelas: delantera y trasera
Frenos de alto desempeño', 16
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Roadster', 'assets/Catalogo/vehiculos/porsche/718-boxster.webp', NULL, 'PDK de 7 velocidades', '300 hp', '4.9 s', 'El Porsche 718 Boxster es el roadster que convierte cualquier camino en un destino. Su capota eléctrica se abre en segundos y el motor central bóxer ofrece un equilibrio dinámico excepcional.', 'Capota eléctrica de lona (apertura en 9 s)
Motor central bóxer turbo
Transmisión PDK de 7 velocidades
Porsche Active Suspension Management (PASM)
Asientos deportivos Plus
Paquete Sport Chrono', 17
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/911-carrera.webp', NULL, 'PDK de 8 velocidades', '379 hp', '4.2 s', 'El Porsche 911 Carrera es el ícono atemporal de los autos deportivos. Su motor bóxer biturbo montado atrás, la tracción trasera y una ergonomía impecable lo hacen tan disfrutable en el día a día como en un track day.', 'Motor bóxer biturbo 3.0 de seis cilindros
Transmisión PDK de 8 velocidades
Porsche Communication Management (PCM)
Modos de manejo con Sport Response
Rines de 19" y 20"
Faros LED Matrix', 18
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/911-carrera-s.webp', NULL, 'PDK de 8 velocidades', '443 hp', '3.7 s', 'El 911 Carrera S eleva la experiencia con 443 hp, frenos de mayor diámetro y un carácter aún más afilado. La combinación perfecta de confort de gran turismo y desempeño de deportivo puro.', 'Motor bóxer biturbo de 443 hp
Calipers rojos de seis pistones
PASM de serie
Escape deportivo disponible
Sport Chrono con selector de modos
Rines de 20" y 21"', 19
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-04' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/911-turbo.webp', NULL, 'PDK de 8 velocidades', '572 hp', '2.8 s', 'El Porsche 911 Turbo es el superdeportivo para todos los días. Tracción integral, aerodinámica activa y un motor biturbo de 572 hp que impulsa de 0 a 100 km/h en menos de tres segundos con una facilidad sorprendente.', 'Tracción integral Porsche Traction Management
Aerodinámica activa: spoiler y alerón adaptativos
Motor bóxer 3.7 biturbo
Suspensión PASM deportiva
Interior en piel con costuras en contraste
Sistema de audio envolvente premium', 20
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-05' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Deportivo de pista', 'assets/Catalogo/vehiculos/porsche/911-gt3.webp', NULL, 'PDK de 7 velocidades', '502 hp', '3.4 s', 'El 911 GT3 lleva el ADN del automovilismo a la calle: motor atmosférico de 4.0 litros que gira hasta 9,000 rpm, suspensión delantera de doble horquilla derivada de competencia y alerón trasero fijo para máxima carga aerodinámica.', 'Motor bóxer atmosférico de 4.0 l y 9,000 rpm
Suspensión delantera de doble horquilla
Alerón trasero tipo cuello de cisne
Dirección en el eje trasero
Frenos cerámicos PCCB disponibles
Modo Track Screen en el tablero', 21
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-06' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Deportivo de pista', 'assets/Catalogo/vehiculos/porsche/911-gt3-rs.webp', NULL, 'PDK de 7 velocidades', '518 hp', '3.2 s', 'El 911 GT3 RS es una de las versiones más radicales homologadas para calle: aerodinámica activa con DRS, enorme carga aerodinámica y un motor atmosférico de 518 hp. Concebido para dominar el circuito.', 'Sistema de reducción de arrastre (DRS)
Hasta 860 kg de carga aerodinámica a 285 km/h
Motor atmosférico de 518 hp
Ajustes de suspensión desde el volante
Paquete Weissach disponible
Jaula antivuelco disponible', 22
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-07' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Targa', 'assets/Catalogo/vehiculos/porsche/911-targa.webp', NULL, 'PDK de 8 velocidades', '379 hp', '4.4 s', 'El 911 Targa combina la emoción de un convertible con la seguridad de un coupé gracias a su icónico arco Targa y a un techo que se retrae automáticamente. Tracción integral para disfrutarlo todo el año.', 'Techo Targa de apertura automática
Arco Targa característico
Tracción integral
Transmisión PDK de 8 velocidades
Asientos con calefacción
Faros LED Matrix', 23
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-08' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sedán eléctrico', 'assets/Catalogo/vehiculos/porsche/taycan.webp', NULL, 'Automática de 2 velocidades (eje trasero)', '402 hp', '4.8 s', 'El Porsche Taycan es el deportivo eléctrico que redefine la movilidad sin emisiones: arquitectura de 800 voltios, carga ultrarrápida y la dinámica de manejo que se espera de un Porsche.', 'Arquitectura eléctrica de 800 V
Carga rápida en corriente directa
Autonomía estimada de hasta 500 km (WLTP)
Transmisión de 2 velocidades en el eje trasero
Pantalla curva de 16.8"
Porsche Electric Sport Sound', 24
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-09' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sedán eléctrico', 'assets/Catalogo/vehiculos/porsche/taycan-turbo.webp', NULL, 'Automática de 2 velocidades (eje trasero)', '670 hp', '3.2 s', 'El Taycan Turbo lleva la electrificación al límite del desempeño: dos motores, tracción integral y una aceleración contundente que se repite una y otra vez sin perder potencia.', 'Dos motores eléctricos y tracción integral
Launch Control con overboost
Suspensión neumática adaptativa
Porsche Dynamic Chassis Control
Cargador a bordo de 22 kW disponible
Interior sin piel animal disponible', 25
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-10' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Gran turismo', 'assets/Catalogo/vehiculos/porsche/panamera.webp', NULL, 'PDK de 8 velocidades', '325 hp', '5.6 s', 'El Porsche Panamera es el gran turismo de cuatro plazas que combina el confort de una limusina con el desempeño de un deportivo. Espacio, lujo y emoción para toda la familia.', 'Motor 2.9 V6 biturbo
Suspensión neumática adaptativa de tres cámaras
Cuatro asientos individuales
Porsche Advanced Cockpit
Portón trasero eléctrico
Asistente de visión nocturna disponible', 26
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-11' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Gran turismo', 'assets/Catalogo/vehiculos/porsche/panamera-turbo.webp', NULL, 'PDK de 8 velocidades', '670 hp', '3.2 s', 'El Panamera Turbo representa la máxima expresión del gran turismo Porsche: potencia descomunal, tracción integral y una cabina de lujo artesanal. La forma más rápida de viajar en primera clase.', 'Motor V8 biturbo de alto desempeño
Tracción integral Porsche Traction Management
Porsche Active Ride disponible
Interior en piel extendida
Pantalla para el acompañante
Sistema de audio 3D de alta fidelidad', 27
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-12' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/porsche/macan.webp', NULL, 'PDK de 7 velocidades', '261 hp', '6.2 s', 'El Porsche Macan es el deportivo de su segmento: una SUV compacta con la agilidad y la precisión de manejo que caracterizan a la marca. Versátil para la ciudad y emocionante en carretera.', 'Tracción integral Porsche Traction Management
Motor 2.0 turbo
Transmisión PDK de 7 velocidades
Pantalla táctil PCM de 10.9"
Portón trasero eléctrico
Modo Offroad', 28
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-13' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/porsche/cayenne.webp', NULL, 'Tiptronic S de 8 velocidades', '335 hp', '5.9 s', 'El Porsche Cayenne es la SUV que demostró que lujo, espacio y deportividad pueden convivir: interior amplio, gran capacidad de remolque y el manejo inconfundible de un Porsche.', 'Motor 3.0 V6 turbo
Tracción integral
Suspensión neumática disponible
Capacidad de remolque de hasta 3,500 kg
Cajuela de 772 litros
Porsche InnoDrive con crucero adaptativo', 29
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-14' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'SUV coupé', 'assets/Catalogo/vehiculos/porsche/cayenne-turbo.webp', NULL, 'Tiptronic S de 8 velocidades', '541 hp', '3.9 s', 'El Cayenne Turbo combina la presencia de una SUV de lujo con la potencia de un V8 biturbo: aceleración de deportivo, tracción integral y un interior premium para cinco ocupantes.', 'Motor 4.0 V8 biturbo
Tracción integral
Porsche Dynamic Chassis Control
Frenos Porsche Surface Coated Brake
Escape deportivo
Asientos deportivos adaptativos de 18 posiciones', 30
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-POR-15' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Superdeportiva', 'assets/Catalogo/vehiculos/ducati/panigale-v2.webp', NULL, '6 velocidades con Ducati Quick Shift', '155 hp', '3.2 s', 'La Ducati Panigale V2 es la superdeportiva bicilíndrica que ofrece las sensaciones de la familia Panigale con un carácter más ligero y accesible. Ideal para dar el salto a la pista.', 'Motor Superquadro bicilíndrico de 955 cc
Ducati Quick Shift up & down
Control de tracción y ABS en curva
Pantalla TFT a color
Basculante monobrazo
Modos de manejo Race, Sport y Street', 31
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Superdeportiva', 'assets/Catalogo/vehiculos/ducati/panigale-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '215 hp', '2.9 s', 'La Panigale V4 traslada la tecnología de MotoGP a la calle: motor Desmosedici Stradale V4 de 1,103 cc, aerodinámica con alerones y un paquete electrónico de última generación.', 'Motor Desmosedici Stradale V4 de 1,103 cc
Alerones aerodinámicos de doble perfil
Ducati Traction Control y Slide Control
Launch Control
Pantalla TFT de 5"
Chasis Front Frame de aluminio', 32
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Superdeportiva', 'assets/Catalogo/vehiculos/ducati/panigale-v4-s.webp', NULL, '6 velocidades con Ducati Quick Shift', '216 hp', '2.8 s', 'La Panigale V4 S suma suspensiones electrónicas Öhlins, rines forjados y batería de litio a la fórmula de la Panigale V4. Es la referencia para quienes buscan el máximo desempeño en pista.', 'Suspensiones electrónicas Öhlins Smart EC 2.0
Rines forjados de aluminio
Batería de iones de litio
Frenos Brembo Stylema
ABS Cornering EVO
Peso reducido en orden de marcha', 33
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Naked', 'assets/Catalogo/vehiculos/ducati/monster.webp', NULL, '6 velocidades con Ducati Quick Shift', '111 hp', '3.6 s', 'La Ducati Monster es la naked deportiva que inventó un segmento: ligera, ágil y con un motor Testastretta de carácter vibrante. Perfecta para el uso diario y la diversión del fin de semana.', 'Motor Testastretta 11° de 937 cc
188 kg en orden de marcha
Ducati Quick Shift
Control de tracción y ABS en curva
Tablero TFT de 4.3"
Asiento de altura ajustable', 34
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-04' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Naked', 'assets/Catalogo/vehiculos/ducati/monster-sp.webp', NULL, '6 velocidades con Ducati Quick Shift', '111 hp', '3.5 s', 'La Monster SP es la versión más deportiva de la Monster: suspensiones Öhlins, escape deportivo homologado y frenos Brembo Stylema para un manejo aún más preciso.', 'Suspensiones Öhlins totalmente ajustables
Frenos Brembo Stylema
Escape deportivo homologado
Batería de litio
Amortiguador de dirección
Gráficos SP exclusivos', 35
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-05' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Adventure touring', 'assets/Catalogo/vehiculos/ducati/multistrada-v2.webp', NULL, '6 velocidades con Ducati Quick Shift', '113 hp', '3.9 s', 'La Multistrada V2 es la compañera ideal para viajar: posición de manejo cómoda, buena protección aerodinámica y un motor Testastretta suave y elástico. Varias motos en una para cualquier tipo de camino.', 'Motor Testastretta de 937 cc
Parabrisas ajustable
Cuatro modos de manejo
Control de crucero
Asiento de altura ajustable
Preparada para maletas laterales', 36
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-06' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Adventure touring', 'assets/Catalogo/vehiculos/ducati/multistrada-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '170 hp', '3.3 s', 'La Multistrada V4 combina un motor V4 Granturismo de 170 hp con radar delantero y trasero para una experiencia de viaje segura y tecnológica. Lista para cruzar continentes.', 'Motor V4 Granturismo de 1,158 cc
Radar delantero y trasero con crucero adaptativo
Pantalla TFT de 6.5" con navegación
Suspensión semiactiva Skyhook
Servicio de válvulas cada 60,000 km
Faros full LED con luz de curva', 37
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-07' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Power cruiser', 'assets/Catalogo/vehiculos/ducati/diavel-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '168 hp', '2.6 s', 'La Diavel V4 es la power cruiser más deportiva: diseño musculoso, motor V4 Granturismo y la capacidad de acelerar como una superdeportiva con la comodidad de una cruiser.', 'Motor V4 Granturismo de 1,158 cc
Llanta trasera de 240 mm
Ducati Power Launch
Escape de cuatro salidas
Iluminación full LED con firma distintiva
Posición de manejo relajada', 38
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-08' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Naked deportiva', 'assets/Catalogo/vehiculos/ducati/streetfighter-v2.webp', NULL, '6 velocidades con Ducati Quick Shift', '153 hp', '3.1 s', 'La Streetfighter V2 es una superdeportiva sin carenado: motor Superquadro de 955 cc, manubrio ancho y un diseño agresivo inspirado en la Panigale. Adrenalina pura para la calle.', 'Motor Superquadro de 955 cc
Manubrio ancho de aluminio
Basculante monobrazo
Control de wheelie
Frenos Brembo de anclaje radial
Pantalla TFT a color', 39
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-09' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 1, 'nuevo', 'Naked deportiva', 'assets/Catalogo/vehiculos/ducati/streetfighter-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '208 hp', '2.9 s', 'La Streetfighter V4 es una Panigale sin carenado: motor Desmosedici Stradale de 208 hp, alerones biplano y un paquete electrónico de competencia en una naked de diseño inconfundible.', 'Motor Desmosedici Stradale V4 de 1,103 cc
Alerones biplano
Control de tracción y wheelie EVO
Faros full LED con firma frontal distintiva
Ducati Quick Shift EVO
Pantalla TFT de 5"', 40
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-10' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Scrambler', 'assets/Catalogo/vehiculos/ducati/scrambler-icon.webp', NULL, '6 velocidades', '73 hp', '4.6 s', 'La Scrambler Icon es sinónimo de libertad: estilo atemporal, motor bicilíndrico enfriado por aire fácil de manejar y una ergonomía amigable para todos los niveles. Perfecta para la ciudad y las escapadas.', 'Motor L-Twin de 803 cc enfriado por aire
Peso ligero y asiento bajo
Faro con luz diurna en forma de X
Control de tracción
Cubiertas de tanque intercambiables
Tablero digital', 41
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-11' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Scrambler', 'assets/Catalogo/vehiculos/ducati/scrambler-nightshift.webp', NULL, '6 velocidades', '73 hp', '4.6 s', 'La Scrambler Nightshift interpreta el estilo café racer con un toque urbano: rines de rayos, manubrio plano y acabados oscuros que destacan en cualquier calle.', 'Rines de rayos
Manubrio plano
Espejos en los extremos del manubrio
Motor L-Twin de 803 cc
Asiento con tapizado especial
Acabados en color oscuro', 42
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-12' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Adventure off-road', 'assets/Catalogo/vehiculos/ducati/desertx.webp', NULL, '6 velocidades con Ducati Quick Shift', '110 hp', '3.9 s', 'La DesertX está inspirada en las legendarias motos de rally: rin delantero de 21", suspensiones de largo recorrido y modos de manejo off-road para explorar más allá del asfalto.', 'Rin delantero de 21" y trasero de 18"
Suspensiones de largo recorrido
Modos de manejo Rally y Enduro
Tanque de 21 litros
Pantalla TFT vertical
Protector de motor de aluminio', 43
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-13' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Motard', 'assets/Catalogo/vehiculos/ducati/hypermotard.webp', NULL, '6 velocidades con Ducati Quick Shift', '114 hp', '3.4 s', 'La Hypermotard es pura diversión: geometría de supermotard, posición elevada y un motor Testastretta que invita a jugar en cada curva. Ligera, divertida e irreverente.', 'Motor Testastretta de 937 cc
Escape bajo el asiento
Suspensiones de largo recorrido
Modo Slide by Brake
178 kg en seco
Manubrio ancho de aluminio', 44
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-14' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria, transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sport touring', 'assets/Catalogo/vehiculos/ducati/supersport-950.webp', NULL, '6 velocidades con Ducati Quick Shift', '110 hp', '3.6 s', 'La SuperSport 950 es la deportiva de uso diario: posición de manejo cómoda, protección aerodinámica y un motor Testastretta suave. Ideal para quien quiere estilo deportivo con confort para viajar.', 'Motor Testastretta 11° de 937 cc
Parabrisas ajustable
Diseño inspirado en la Panigale V4
Luces de curva Ducati Cornering Lights
Pantalla TFT de 4.3"
Asiento confortable para dos personas', 45
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-DUC-15' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/audi/filtro-aceite.webp', 'Filtro de aceite de alta eficiencia para Audi RS5. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.', 'Compatible con Audi RS5
Medio filtrante de alta retención
Incluye empaque de sellado
Reemplazo recomendado en cada servicio
Garantía de 6 meses contra defectos de fabricación', 46
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/audi/filtro-aire.webp', 'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Audi A7, protegiendo sus componentes y manteniendo el desempeño.', 'Compatible con Audi A7
Celulosa reforzada de alta captación
Marco de poliuretano flexible
Revisión recomendada cada 15,000 km
Garantía de 6 meses contra defectos de fabricación', 47
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/pastillas-delanteras.webp', 'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Audi RS6. Frenado firme y silencioso desde la primera aplicación.', 'Compatible con Audi RS6
Compuesto cerámico de bajo polvo
Incluye láminas antirruido
Juego para eje delantero
Garantía de 6 meses contra defectos de fabricación', 48
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/pastillas-traseras.webp', 'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Audi R8. Frenado estable y silencioso.', 'Compatible con Audi R8
Compuesto cerámico de bajo polvo
Incluye láminas antirruido
Juego para eje trasero
Garantía de 6 meses contra defectos de fabricación', 49
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-04' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/disco-delantero.webp', 'Disco de freno delantero ventilado de hierro de alta resistencia para Audi RS3. Disipa el calor de forma eficiente y mantiene un frenado constante.', 'Compatible con Audi RS3
Diseño ventilado y perforado
Tratamiento anticorrosión
Se recomienda cambiar en pares
Garantía de 6 meses contra defectos de fabricación', 50
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-05' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/disco-trasero.webp', 'Disco de freno trasero de hierro de alta resistencia para Audi RS3, balanceado para una operación sin vibraciones y con excelente disipación de calor.', 'Compatible con Audi RS3
Balanceado de fábrica
Tratamiento anticorrosión
Se recomienda cambiar en pares
Garantía de 6 meses contra defectos de fabricación', 51
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-06' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/audi/bujias.webp', 'Juego de bujías con electrodo de iridio para Audi A6. Encendido preciso, arranque confiable y consumo optimizado.', 'Compatible con Audi A6
Electrodo central de iridio
Calibración de fábrica
Juego completo para el motor
Garantía de 6 meses contra defectos de fabricación', 52
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-07' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/audi/bateria.webp', 'Batería de 12 V libre de mantenimiento para Audi RS6, con alta capacidad de arranque en frío y construcción resistente a vibraciones.', 'Compatible con Audi RS6
12 V libre de mantenimiento
Alta corriente de arranque en frío
Instalación incluida en sucursal
Garantía de 6 meses contra defectos de fabricación', 53
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-08' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/audi/kit-distribucion.webp', 'Kit de distribución completo para Audi RS6: incluye banda, tensor y poleas para garantizar la sincronización exacta del motor.', 'Compatible con Audi RS6
Incluye banda, tensor y poleas
Instalación recomendada en taller
Reemplazo preventivo según kilometraje
Garantía de 6 meses contra defectos de fabricación', 54
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-09' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/audi/bomba-agua.webp', 'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Audi R8. Mantiene la temperatura óptima de operación del motor.', 'Compatible con Audi R8
Carcasa de aluminio
Impulsor de alto flujo
Incluye empaque
Garantía de 6 meses contra defectos de fabricación', 55
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-AUDI-10' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/porsche/filtro-aceite.webp', 'Filtro de aceite de alta eficiencia para Porsche 911 GT3. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.', 'Compatible con Porsche 911 GT3
Medio filtrante de alta retención
Incluye empaque de sellado
Reemplazo recomendado en cada servicio
Garantía de 6 meses contra defectos de fabricación', 56
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/porsche/filtro-aire.webp', 'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Porsche 718 Boxster, protegiendo sus componentes y manteniendo el desempeño.', 'Compatible con Porsche 718 Boxster
Celulosa reforzada de alta captación
Marco de poliuretano flexible
Revisión recomendada cada 15,000 km
Garantía de 6 meses contra defectos de fabricación', 57
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/pastillas-delanteras.webp', 'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Porsche Cayenne Turbo. Frenado firme y silencioso desde la primera aplicación.', 'Compatible con Porsche Cayenne Turbo
Compuesto cerámico de bajo polvo
Incluye láminas antirruido
Juego para eje delantero
Garantía de 6 meses contra defectos de fabricación', 58
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/pastillas-traseras.webp', 'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Porsche Macan. Frenado estable y silencioso.', 'Compatible con Porsche Macan
Compuesto cerámico de bajo polvo
Incluye láminas antirruido
Juego para eje trasero
Garantía de 6 meses contra defectos de fabricación', 59
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-04' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/disco-delantero.webp', 'Disco de freno delantero ventilado de hierro de alta resistencia para Porsche 718 Cayman. Disipa el calor de forma eficiente y mantiene un frenado constante.', 'Compatible con Porsche 718 Cayman
Diseño ventilado y perforado
Tratamiento anticorrosión
Se recomienda cambiar en pares
Garantía de 6 meses contra defectos de fabricación', 60
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-05' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/disco-trasero.webp', 'Disco de freno trasero de hierro de alta resistencia para Porsche Taycan Turbo, balanceado para una operación sin vibraciones y con excelente disipación de calor.', 'Compatible con Porsche Taycan Turbo
Balanceado de fábrica
Tratamiento anticorrosión
Se recomienda cambiar en pares
Garantía de 6 meses contra defectos de fabricación', 61
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-06' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/porsche/bujias.webp', 'Juego de bujías con electrodo de iridio para Porsche 718 Boxster. Encendido preciso, arranque confiable y consumo optimizado.', 'Compatible con Porsche 718 Boxster
Electrodo central de iridio
Calibración de fábrica
Juego completo para el motor
Garantía de 6 meses contra defectos de fabricación', 62
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-07' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/porsche/bateria.webp', 'Batería de 12 V libre de mantenimiento para Porsche Cayenne, con alta capacidad de arranque en frío y construcción resistente a vibraciones.', 'Compatible con Porsche Cayenne
12 V libre de mantenimiento
Alta corriente de arranque en frío
Instalación incluida en sucursal
Garantía de 6 meses contra defectos de fabricación', 63
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-08' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/porsche/kit-distribucion.webp', 'Kit de distribución completo para Porsche Macan: incluye banda, tensor y poleas para garantizar la sincronización exacta del motor.', 'Compatible con Porsche Macan
Incluye banda, tensor y poleas
Instalación recomendada en taller
Reemplazo preventivo según kilometraje
Garantía de 6 meses contra defectos de fabricación', 64
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-09' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/porsche/bomba-agua.webp', 'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Porsche 911 Carrera. Mantiene la temperatura óptima de operación del motor.', 'Compatible con Porsche 911 Carrera
Carcasa de aluminio
Impulsor de alto flujo
Incluye empaque
Garantía de 6 meses contra defectos de fabricación', 65
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-POR-10' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/ducati/filtro-aceite.webp', 'Filtro de aceite de alta eficiencia para Ducati Diavel V4. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.', 'Compatible con Ducati Diavel V4
Medio filtrante de alta retención
Incluye empaque de sellado
Reemplazo recomendado en cada servicio
Garantía de 6 meses contra defectos de fabricación', 66
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/ducati/filtro-aire.webp', 'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Ducati Panigale V4 S, protegiendo sus componentes y manteniendo el desempeño.', 'Compatible con Ducati Panigale V4 S
Celulosa reforzada de alta captación
Marco de poliuretano flexible
Revisión recomendada cada 15,000 km
Garantía de 6 meses contra defectos de fabricación', 67
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/ducati/pastillas-delanteras.webp', 'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Ducati Hypermotard. Frenado firme y silencioso desde la primera aplicación.', 'Compatible con Ducati Hypermotard
Compuesto cerámico de bajo polvo
Incluye láminas antirruido
Juego para eje delantero
Garantía de 6 meses contra defectos de fabricación', 68
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/ducati/pastillas-traseras.webp', 'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Ducati Monster. Frenado estable y silencioso.', 'Compatible con Ducati Monster
Compuesto cerámico de bajo polvo
Incluye láminas antirruido
Juego para eje trasero
Garantía de 6 meses contra defectos de fabricación', 69
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-04' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/ducati/disco-delantero.webp', 'Disco de freno delantero ventilado de hierro de alta resistencia para Ducati DesertX. Disipa el calor de forma eficiente y mantiene un frenado constante.', 'Compatible con Ducati DesertX
Diseño ventilado y perforado
Tratamiento anticorrosión
Se recomienda cambiar en pares
Garantía de 6 meses contra defectos de fabricación', 70
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-05' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Transmisión', 'assets/Catalogo/refacciones/ducati/cadena-transmision.webp', 'Cadena de transmisión con retenes X-Ring para Ducati Monster. Mayor durabilidad y menor fricción al transmitir la potencia del motor a la rueda trasera.', 'Compatible con Ducati Monster
Retenes X-Ring
Eslabón de unión remachable
Lubricación de larga duración
Garantía de 6 meses contra defectos de fabricación', 71
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-06' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/ducati/kit-bujias.webp', 'Juego de bujías con electrodo de iridio para Ducati Multistrada V4. Encendido preciso, arranque confiable y consumo optimizado.', 'Compatible con Ducati Multistrada V4
Electrodo central de iridio
Calibración de fábrica
Juego completo para el motor
Garantía de 6 meses contra defectos de fabricación', 72
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-07' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/ducati/bateria.webp', 'Batería de 12 V libre de mantenimiento para Ducati Scrambler Icon, con alta capacidad de arranque en frío y construcción resistente a vibraciones.', 'Compatible con Ducati Scrambler Icon
12 V libre de mantenimiento
Alta corriente de arranque en frío
Instalación incluida en sucursal
Garantía de 6 meses contra defectos de fabricación', 73
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-08' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Controles', 'assets/Catalogo/refacciones/ducati/maneta-freno-embrague.webp', 'Maneta de freno/embrague de aluminio anodizado con ajuste de distancia para Ducati SuperSport 950. Tacto preciso y ergonomía mejorada.', 'Compatible con Ducati SuperSport 950
Aluminio anodizado
Ajuste de distancia en 6 posiciones
Instalación directa
Garantía de 6 meses contra defectos de fabricación', 74
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-09' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Carrocería', 'assets/Catalogo/refacciones/ducati/espejo-retrovisor.webp', 'Espejo retrovisor con cristal antirreflejante y soporte reforzado para Ducati Panigale V4. Visibilidad amplia con diseño aerodinámico.', 'Compatible con Ducati Panigale V4
Cristal antirreflejante
Soporte reforzado
Ajuste en varias posiciones
Garantía de 6 meses contra defectos de fabricación', 75
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-REF-DUC-10' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Interior', 'assets/Catalogo/accesorios/tapetes-audi.webp', 'Juego de tapetes de hule moldeados a la medida del Audi Q5. Sus bordes elevados retienen agua, lodo y arena, protegiendo la alfombra original en cualquier temporada.', 'Compatible con Audi Q5
Juego de 4 piezas a la medida
Bordes elevados que contienen líquidos
Material antiderrapante y fácil de lavar
Anclajes de fijación originales', 76
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-AUDI-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Exterior', 'assets/Catalogo/accesorios/barras-techo-audi.webp', 'Barras transversales de aluminio aerodinámico para el Audi Q3. Base ideal para portabicicletas, portaesquís o cajas de techo, con sistema de bloqueo antirrobo.', 'Compatible con Audi Q3
Perfil aerodinámico de bajo ruido
Capacidad de carga de 75 kg
Cerradura con llave antirrobo
Instalación sin herramientas especiales', 77
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-AUDI-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Organización', 'assets/Catalogo/accesorios/organizador-cajuela-audi.webp', 'Organizador plegable con divisiones ajustables que mantiene en orden las compras, herramientas y artículos deportivos dentro de la cajuela.', 'Compatible con Audi A4 / A6 / Q5
Divisiones ajustables con velcro
Base antiderrapante
Se pliega cuando no se usa
Compatible con A4, A6 y Q5', 78
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-AUDI-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Protección', 'assets/Catalogo/accesorios/funda-interior-porsche.webp', 'Funda transpirable a la medida del Porsche 911 para uso en interior. Protege la pintura del polvo y los rayones mientras permite la circulación del aire.', 'Compatible con Porsche 911 (992)
Corte a la medida del 911 (992)
Tejido suave y transpirable
Interior afelpado que cuida la pintura
Incluye bolsa de almacenamiento', 79
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Interior', 'assets/Catalogo/accesorios/tapetes-premium-porsche.webp', 'Tapetes de alfombra premium con ribete y respaldo antiderrapante, diseñados a la medida del Porsche Macan.', 'Compatible con Porsche Macan
Alfombra de alta densidad
Ribete en piel sintética
Respaldo antiderrapante
Juego de 4 piezas', 80
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Carga eléctrica', 'assets/Catalogo/accesorios/cargador-portatil-porsche.webp', 'Cargador portátil de hasta 11 kW con conector Tipo 2 para el Porsche Taycan. Permite cargar en casa o en cualquier contacto industrial compatible.', 'Compatible con Porsche Taycan
Potencia de carga de hasta 11 kW
Conector Tipo 2
Cable de 7.5 metros
Estuche de transporte incluido', 81
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Equipaje', 'assets/Catalogo/accesorios/maletas-laterales-ducati.webp', 'Par de maletas laterales rígidas de aluminio con cierre hermético para la Multistrada V4. Capacidad suficiente para viajes largos con total protección contra la lluvia.', 'Compatible con Ducati Multistrada V4
Capacidad de 30 y 37 litros
Aluminio anodizado resistente
Cierre hermético con llave
Soportes de liberación rápida', 82
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-DUC-01' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Exterior', 'assets/Catalogo/accesorios/parabrisas-touring-ducati.webp', 'Parabrisas touring de mayor altura que reduce la turbulencia y la fatiga en viajes largos. Policarbonato resistente a impactos con tratamiento antirrayas.', 'Compatible con Ducati Multistrada V2 / V4
Policarbonato de 4 mm
Tratamiento antirrayas
60 mm más alto que el original
Compatible con Multistrada V2 y V4', 83
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-DUC-02' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Protección', 'assets/Catalogo/accesorios/funda-moto-ducati.webp', 'Funda de exterior impermeable con protección UV y forro suave. Mantiene tu Ducati limpia y protegida del sol, la lluvia y el polvo.', 'Compatible con Ducati Panigale / Streetfighter
Tela impermeable con protección UV
Forro interior suave
Orificios para candado
Bolsa de transporte incluida', 84
  FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-DUC-03' AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);

-- ===== 6. SUCURSALES: Colima nueva + datos de contacto web de ambas =====
-- (Manzanillo ya existía: solo se llenan las columnas nuevas que estén vacías)
INSERT INTO sucursales (nombre, direccion, telefono, estado)
SELECT 'Colima', 'Av. Constitución 1500, Colima, Colima', '3120000000', 'activo'
WHERE NOT EXISTS (SELECT 1 FROM sucursales WHERE nombre = 'Colima');

UPDATE sucursales SET
    ciudad = COALESCE(ciudad, 'Manzanillo'),
    email = COALESCE(email, 'manzanillo@karma.local'),
    horario_ventas = COALESCE(horario_ventas, 'Lunes a viernes 9:00–19:00 · Sábado 9:00–14:00'),
    horario_servicio = COALESCE(horario_servicio, 'Lunes a viernes 8:00–18:00 · Sábado 8:00–13:00'),
    servicios = COALESCE(servicios, 'Venta de vehículos nuevos,Prueba de manejo,Financiamiento,Servicio y mantenimiento,Refacciones originales,Accesorios,Garantía'),
    imagen = COALESCE(imagen, 'assets/Catalogo/sucursales/manzanillo.webp')
WHERE nombre = 'Manzanillo';

UPDATE sucursales SET
    ciudad = COALESCE(ciudad, 'Colima'),
    email = COALESCE(email, 'colima@karma.local'),
    horario_ventas = COALESCE(horario_ventas, 'Lunes a viernes 9:00–19:00 · Sábado 9:00–14:00'),
    horario_servicio = COALESCE(horario_servicio, 'Lunes a viernes 8:00–18:00 · Sábado 8:00–13:00'),
    servicios = COALESCE(servicios, 'Venta de vehículos nuevos,Prueba de manejo,Financiamiento,Servicio y mantenimiento,Refacciones originales,Accesorios,Garantía,Seminuevos'),
    imagen = COALESCE(imagen, 'assets/Catalogo/sucursales/colima.webp')
WHERE nombre = 'Colima';

-- ===== 7. INVENTARIO POR SUCURSAL (independiente) =====
-- Solo se insertan filas que NO existen: las existencias que ya cambiaron por ventas nunca se reinician.
-- stock_minimo = 2 es el umbral que el sitio usa para mostrar "Pocas unidades".

-- 7a. Manzanillo: accesorios nuevos (los 75 productos ya tenían inventario en Manzanillo)
INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
SELECT s.id_sucursal, p.id_producto, t.stock, 2
  FROM sucursales s
  JOIN (
        SELECT 'KRM-CAT-ACC-AUDI-01' AS codigo, 6 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-AUDI-02' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-AUDI-03' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-POR-01' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-POR-02' AS codigo, 4 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-POR-03' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-DUC-01' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-DUC-02' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-DUC-03' AS codigo, 3 AS stock
  ) t
  JOIN productos p ON p.codigo_barras = t.codigo
 WHERE s.nombre = 'Manzanillo'
   AND NOT EXISTS (SELECT 1 FROM inventarios i WHERE i.id_sucursal = s.id_sucursal AND i.id_producto = p.id_producto);

-- 7b. Manzanillo: respaldo para una base nueva (cantidades originales de los 75 productos del catálogo)
INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
SELECT s.id_sucursal, p.id_producto, t.stock, 2
  FROM sucursales s
  JOIN (
        SELECT 'KRM-CAT-AUDI-01' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-03' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-04' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-06' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-09' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-10' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-11' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-12' AS codigo, 4 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-13' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-14' AS codigo, 7 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-15' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-01' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-03' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-04' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-06' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-09' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-10' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-11' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-12' AS codigo, 4 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-13' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-14' AS codigo, 7 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-15' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-01' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-03' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-04' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-06' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-09' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-10' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-11' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-12' AS codigo, 4 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-13' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-14' AS codigo, 6 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-15' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-01' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-03' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-04' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-06' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-09' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-10' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-01' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-02' AS codigo, 4 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-03' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-04' AS codigo, 7 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-05' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-06' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-08' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-09' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-10' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-01' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-03' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-04' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-05' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-06' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-07' AS codigo, 4 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-08' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-09' AS codigo, 7 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-10' AS codigo, 1 AS stock
  ) t
  JOIN productos p ON p.codigo_barras = t.codigo
 WHERE s.nombre = 'Manzanillo'
   AND NOT EXISTS (SELECT 1 FROM inventarios i WHERE i.id_sucursal = s.id_sucursal AND i.id_producto = p.id_producto);

-- 7c. Colima: TODOS los productos (mismos productos que Manzanillo, existencias distintas)
INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
SELECT s.id_sucursal, p.id_producto, t.stock, CASE WHEN p.tipo = 'refaccion' THEN 2 ELSE 1 END
  FROM sucursales s
  JOIN (
        SELECT 'KRM-P911-24' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-P911-25' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-PTAY-25' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-ARS7-24' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-AQ8E-25' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-DPAN-24' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-DSTR-25' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-REF-DISCO-911' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-REF-PAST-AUDI' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-REF-BALATA-AUDI' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-01' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-03' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-04' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-06' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-09' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-10' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-11' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-12' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-13' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-14' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-AUDI-15' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-01' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-03' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-04' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-06' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-09' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-10' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-11' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-12' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-13' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-14' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-POR-15' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-01' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-02' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-03' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-04' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-05' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-06' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-08' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-09' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-10' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-11' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-12' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-13' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-14' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-DUC-15' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-01' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-02' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-03' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-04' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-05' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-06' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-07' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-08' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-09' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-AUDI-10' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-01' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-03' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-04' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-05' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-06' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-07' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-08' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-09' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-POR-10' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-01' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-02' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-03' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-04' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-05' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-06' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-07' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-08' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-09' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-REF-DUC-10' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-AUDI-01' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-AUDI-02' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-AUDI-03' AS codigo, 1 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-POR-01' AS codigo, 3 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-POR-02' AS codigo, 0 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-POR-03' AS codigo, 10 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-DUC-01' AS codigo, 5 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-DUC-02' AS codigo, 2 AS stock
        UNION ALL
        SELECT 'KRM-CAT-ACC-DUC-03' AS codigo, 1 AS stock
  ) t
  JOIN productos p ON p.codigo_barras = t.codigo
 WHERE s.nombre = 'Colima'
   AND NOT EXISTS (SELECT 1 FROM inventarios i WHERE i.id_sucursal = s.id_sucursal AND i.id_producto = p.id_producto);

-- ===== 8. VERIFICACIÓN (solo muestra resultados) =====
SELECT pw.seccion, p.marca, COUNT(*) AS productos
  FROM productos_web pw JOIN productos p ON p.id_producto = pw.id_producto
 WHERE pw.publicado = 1
 GROUP BY pw.seccion, p.marca ORDER BY pw.seccion, p.marca;

-- Mismo producto, inventario independiente por sucursal (ejemplo: Audi A3 y Batería Audi)
SELECT p.codigo_barras, p.nombre, s.nombre AS sucursal, i.stock_actual
  FROM inventarios i
  JOIN productos p ON p.id_producto = i.id_producto
  JOIN sucursales s ON s.id_sucursal = i.id_sucursal
 WHERE p.codigo_barras IN ('KRM-CAT-AUDI-01', 'KRM-CAT-REF-AUDI-08')
 ORDER BY p.codigo_barras, s.nombre;
