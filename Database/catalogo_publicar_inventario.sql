-- =====================================================================================
-- KARMA · Catálogo — publicar en el catálogo los productos del inventario que no aparecían
-- Fecha: 2026-11-10
--
-- Problema: el catálogo solo muestra productos con ficha en `productos_web`. Los 10 productos originales
-- del Punto de Venta (KRM-P911-24, KRM-ARS7-24, KRM-REF-BALATA-AUDI, etc.) tenían existencias en
-- `inventarios` y se vendían en el POS, pero no tenían ficha web: el inventario del POS tenía más productos
-- y más unidades que el catálogo.
--
-- Solución: se les crea su ficha web. Las existencias NO se copian ni se tocan: el catálogo y el POS leen la
-- misma fila inventarios(id_sucursal, id_producto), así que las cantidades coinciden siempre.
-- La foto es la de referencia del mismo modelo (o pieza equivalente) que ya usa el catálogo.
--
-- Los productos se buscan por código de barras (los id cambian entre bases). Es idempotente: se puede
-- ejecutar varias veces; solo inserta las fichas que falten y no modifica ni borra nada.
-- =====================================================================================

SET NAMES utf8mb4;

-- ===== 1. Vehículos del mismo modelo que uno ya publicado: se reutiliza la ficha de ese modelo =====
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria,
                           transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, h.seccion, 1, 0, 'nuevo', h.subcategoria, h.imagen, NULL,
       h.transmision, COALESCE(m.potencia, h.potencia), COALESCE(m.aceleracion, h.aceleracion),
       REPLACE(h.descripcion_larga, COALESCE(h.potencia, ''), COALESCE(m.potencia, h.potencia, '')),
       h.caracteristicas, h.orden
  FROM (          SELECT 'KRM-P911-24' AS codigo, 'KRM-CAT-POR-03' AS hermano, NULL AS potencia, NULL AS aceleracion
        UNION ALL SELECT 'KRM-P911-25', 'KRM-CAT-POR-03', '388 hp', '4.1 s'   -- 911 Carrera 2025 (992.2)
        UNION ALL SELECT 'KRM-ARS7-24', 'KRM-CAT-AUDI-14', NULL, NULL
        UNION ALL SELECT 'KRM-DPAN-24', 'KRM-CAT-DUC-03', NULL, NULL
        UNION ALL SELECT 'KRM-DSTR-25', 'KRM-CAT-DUC-10', '214 hp', NULL      -- Streetfighter V4 2025
       ) m
  JOIN productos p  ON p.codigo_barras = m.codigo
  JOIN productos ph ON ph.codigo_barras = m.hermano
  JOIN productos_web h ON h.id_producto = ph.id_producto
 WHERE NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);

-- ===== 2. Vehículos de una versión que el catálogo no tenía =====
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria,
                           transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'Sedán eléctrico', 'assets/Catalogo/vehiculos/porsche/taycan.webp', NULL,
       'Automática de 2 velocidades (eje trasero)', '938 hp', '2.4 s',
       'El Taycan Turbo S es la versión más potente de la gama Taycan: dos motores eléctricos, tracción integral y Launch Control con overboost para acelerar de 0 a 100 km/h en 2.4 segundos, con carga ultrarrápida de hasta 270 kW.',
       'Dos motores eléctricos y tracción integral\nLaunch Control con overboost\nArquitectura eléctrica de 800 V\nCarga rápida en corriente directa de hasta 270 kW\nSuspensión neumática adaptativa',
       COALESCE((SELECT w.orden FROM productos_web w JOIN productos x ON x.id_producto = w.id_producto WHERE x.codigo_barras = 'KRM-CAT-POR-10'), 25)
  FROM productos p
 WHERE p.codigo_barras = 'KRM-PTAY-25'
   AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);

INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria,
                           transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'vehiculos', 1, 0, 'nuevo', 'SUV eléctrica', 'assets/Catalogo/vehiculos/audi/q8.webp', NULL,
       'Automática de 1 velocidad', '402 hp', '5.6 s',
       'La Audi Q8 e-tron es la SUV eléctrica insignia de Audi: dos motores eléctricos con tracción quattro, techo panorámico solar y una cabina silenciosa para viajes largos sin emisiones.',
       'Dos motores eléctricos con tracción quattro\nTecho panorámico solar\nCarga rápida en corriente directa\nSuspensión neumática adaptativa\nAsistentes de conducción',
       COALESCE((SELECT w.orden FROM productos_web w JOIN productos x ON x.id_producto = w.id_producto WHERE x.codigo_barras = 'KRM-CAT-AUDI-10'), 10)
  FROM productos p
 WHERE p.codigo_barras = 'KRM-AQ8E-25'
   AND NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);

-- ===== 3. Refacciones =====
INSERT INTO productos_web (id_producto, seccion, publicado, destacado, condicion, subcategoria, imagen, galeria,
                           transmision, potencia, aceleracion, descripcion_larga, caracteristicas, orden)
SELECT p.id_producto, 'refacciones', 1, 0, 'nuevo', 'Frenos', m.imagen, NULL, NULL, NULL, NULL, m.descripcion, m.caracteristicas,
       COALESCE((SELECT w.orden FROM productos_web w JOIN productos x ON x.id_producto = w.id_producto WHERE x.codigo_barras = m.hermano), 50)
  FROM (          SELECT 'KRM-REF-BALATA-AUDI' AS codigo, 'KRM-CAT-REF-AUDI-03' AS hermano,
                         'assets/Catalogo/refacciones/audi/pastillas-delanteras.webp' AS imagen,
                         'Balata delantera para Audi RS7 Sportback con compuesto de bajo polvo y alto coeficiente de fricción. Frenado firme y silencioso desde la primera aplicación.' AS descripcion,
                         'Compatible con Audi RS7 Sportback\nCompuesto cerámico de bajo polvo\nPara eje delantero\nGarantía de 6 meses contra defectos de fabricación' AS caracteristicas
        UNION ALL SELECT 'KRM-REF-PAST-AUDI', 'KRM-CAT-REF-AUDI-03',
                         'assets/Catalogo/refacciones/audi/pastillas-delanteras.webp',
                         'Juego completo de pastillas de freno para el eje delantero del Audi RS7 Sportback. Compuesto de bajo polvo y láminas antirruido para un frenado firme y silencioso.',
                         'Compatible con Audi RS7 Sportback\nJuego completo para eje delantero\nIncluye láminas antirruido\nGarantía de 6 meses contra defectos de fabricación'
        UNION ALL SELECT 'KRM-REF-DISCO-911', 'KRM-CAT-REF-POR-05',
                         'assets/Catalogo/refacciones/porsche/disco-delantero.webp',
                         'Disco de freno delantero izquierdo ventilado para Porsche 911. Disipa el calor de forma eficiente y mantiene un frenado constante.',
                         'Compatible con Porsche 911\nLado delantero izquierdo\nDiseño ventilado\nSe recomienda cambiar en pares\nGarantía de 6 meses contra defectos de fabricación'
       ) m
  JOIN productos p ON p.codigo_barras = m.codigo
 WHERE NOT EXISTS (SELECT 1 FROM productos_web w WHERE w.id_producto = p.id_producto);

-- ===== 4. Verificación: productos con existencias en inventario que el catálogo no muestra (debe salir vacío) =====
SELECT p.id_producto, p.codigo_barras, p.nombre, i.id_sucursal, i.stock_actual
  FROM inventarios i
  JOIN productos p ON p.id_producto = i.id_producto
  LEFT JOIN productos_web pw ON pw.id_producto = p.id_producto AND pw.publicado = 1
 WHERE pw.id_producto IS NULL
 ORDER BY p.id_producto, i.id_sucursal;
