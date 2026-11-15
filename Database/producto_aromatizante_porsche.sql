-- KARMA · Producto "Aromatizante Porsche" (accesorio de $15.00) para probar el cobro con tarjeta.
-- Se puede ejecutar varias veces sin riesgo: no duplica el producto ni reinicia sus existencias.
-- Las 3 unidades quedan en Manzanillo, la sucursal cuya caja 01 tiene la terminal Point; Colima queda en 0.

SET NAMES utf8mb4;

INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, detalle, compatibilidad)
SELECT c.id_categoria, 'KRM-CAT-ACC-POR-04', 'Aromatizante Porsche', 'Aromatizante de ambiente en placa colgante, aroma fresa.', 15.00,
       'Porsche', 'Universal', NULL, 'refaccion', 'Multicolor', '#C9A15A', 'Placa con cordón para colgar. Contenido: 1 pieza.', 'Todos los modelos Porsche'
  FROM categorias c
 WHERE c.nombre_categoria = 'Refacciones'
   AND NOT EXISTS (SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-04');

INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'accesorios', 1, 0, 'nuevo', 'Interior', 'assets/Catalogo/accesorios/aromatizante-porsche.webp',
       'Aromatizante de ambiente en placa colgante, aroma fresa, para el interior de tu Porsche.',
       'Compatible con todos los modelos Porsche\nAroma fresa\nPlaca con cordón para colgar\nContenido: 1 pieza', 85
  FROM productos p
 WHERE p.codigo_barras = 'KRM-CAT-ACC-POR-04'
   AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);

INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
SELECT s.id_sucursal, p.id_producto, IF(s.nombre = 'Manzanillo', 3, 0), 2
  FROM sucursales s
  JOIN productos p ON p.codigo_barras = 'KRM-CAT-ACC-POR-04'
 WHERE NOT EXISTS (SELECT 1 FROM inventarios i WHERE i.id_producto = p.id_producto AND i.id_sucursal = s.id_sucursal);
