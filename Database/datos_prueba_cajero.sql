INSERT INTO sucursales (nombre, direccion, telefono, estado)
SELECT 'Manzanillo', 'Av. Miguel de la Madrid 100, Manzanillo, Colima', '3140000000', 'activo'
WHERE NOT EXISTS (SELECT 1 FROM sucursales WHERE nombre = 'Manzanillo');
INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash, idioma_pref, estado)
SELECT r.id_rol, s.id_sucursal, 'Miranda', 'miranda@karma.local',
       '$2y$12$69yS9OJm0dBEBU1GlzIRkePfwIRRfNnSpeB1LAkOLSF0vHQRYh0yG',
       'es', 'activo'
FROM roles r
JOIN sucursales s ON s.nombre = 'Manzanillo'
WHERE r.nombre_rol = 'Cajero'
  AND NOT EXISTS (SELECT 1 FROM usuarios WHERE correo = 'miranda@karma.local');
INSERT INTO cajas (id_sucursal, numero_caja, estado)
SELECT s.id_sucursal, 1, 'abierta'
FROM sucursales s
WHERE s.nombre = 'Manzanillo'
  AND NOT EXISTS (
      SELECT 1 FROM cajas c
      WHERE c.id_sucursal = s.id_sucursal AND c.numero_caja = 1
  );
INSERT INTO categorias (nombre_categoria, descripcion)
SELECT 'Porsche', 'Vehículos Porsche'
WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Porsche');
INSERT INTO categorias (nombre_categoria, descripcion)
SELECT 'Audi', 'Vehículos Audi'
WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Audi');
INSERT INTO categorias (nombre_categoria, descripcion)
SELECT 'Ducati', 'Motocicletas Ducati'
WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Ducati');
INSERT INTO categorias (nombre_categoria, descripcion)
SELECT 'Refacciones', 'Refacciones y piezas'
WHERE NOT EXISTS (SELECT 1 FROM categorias WHERE nombre_categoria = 'Refacciones');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-P911-24', '911 Carrera 2024',
       'Porsche 911 Carrera 2024', 2280000,
       'Porsche', '911 Carrera', 2024, 'auto', 'Negro Jeweled', '#141414',
       '3.0L Boxer Biturbo', '2981 cc',
       'Sport Chrono de fábrica y llantas forjadas de 21".'
FROM categorias c
WHERE c.nombre_categoria='Porsche'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-P911-24');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-P911-25', '911 Carrera 2025',
       'Porsche 911 Carrera 2025', 2350000,
       'Porsche', '911 Carrera', 2025, 'auto', 'Negro Jeweled', '#141414',
       '3.0L Boxer Biturbo', '2981 cc',
       'Sport Chrono de fábrica y llantas forjadas de 21".'
FROM categorias c
WHERE c.nombre_categoria='Porsche'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-P911-25');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-PTAY-25', 'Taycan Turbo S 2025',
       'Porsche Taycan Turbo S 2025', 3180000,
       'Porsche', 'Taycan Turbo S', 2025, 'auto', 'Blanco Carrara', '#EDEDEA',
       'Eléctrico de doble motor', '—',
       'Doble motor eléctrico con carga ultrarrápida de 270 kW.'
FROM categorias c
WHERE c.nombre_categoria='Porsche'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-PTAY-25');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-ARS7-24', 'RS7 Sportback 2024',
       'Audi RS7 Sportback 2024', 2190000,
       'Audi', 'RS7 Sportback', 2024, 'auto', 'Gris Nardo', '#7A7D80',
       '4.0L V8 Biturbo', '3993 cc',
       'V8 biturbo con interior en piel Nappa extendida.'
FROM categorias c
WHERE c.nombre_categoria='Audi'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-ARS7-24');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-AQ8E-25', 'Q8 e-tron 2025',
       'Audi Q8 e-tron 2025', 1850000,
       'Audi', 'Q8 e-tron', 2025, 'auto', 'Azul Ultra', '#1F3B66',
       'Eléctrico de doble motor', '—',
       'Doble motor eléctrico y techo panorámico solar.'
FROM categorias c
WHERE c.nombre_categoria='Audi'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-AQ8E-25');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-DPAN-24', 'Panigale V4 S 2024',
       'Ducati Panigale V4 S 2024', 620000,
       'Ducati', 'Panigale V4 S', 2024, 'moto', 'Rojo Ducati', '#9E1B2E',
       'V4 Desmosedici Stradale', '1103 cc',
       'Motor V4 con electrónica Öhlins de serie.'
FROM categorias c
WHERE c.nombre_categoria='Ducati'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-DPAN-24');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, color, color_hex, motor, cilindraje, detalle)
SELECT c.id_categoria, 'KRM-DSTR-25', 'Streetfighter V4 2025',
       'Ducati Streetfighter V4 2025', 590000,
       'Ducati', 'Streetfighter V4', 2025, 'moto', 'Negro Mate', '#1A1A1A',
       'V4 Desmosedici Stradale', '1103 cc',
       'Motor V4 con winglets aerodinámicos de MotoGP.'
FROM categorias c
WHERE c.nombre_categoria='Ducati'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-DSTR-25');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, compatibilidad, detalle)
SELECT c.id_categoria, 'KRM-REF-DISCO-911', 'Disco de freno delantero',
       'Disco de freno delantero para Porsche 911', 18500,
       'Porsche', '911 (2019)', NULL, 'refaccion', 'Porsche 911',
       'Disco delantero izquierdo.'
FROM categorias c
WHERE c.nombre_categoria='Refacciones'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-REF-DISCO-911');
INSERT INTO productos
(id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, anio, tipo, compatibilidad, detalle)
SELECT c.id_categoria, 'KRM-REF-PAST-AUDI', 'Juego de pastillas de freno',
       'Pastillas de freno para Audi RS7', 12400,
       'Audi', 'RS7 Sportback', NULL, 'refaccion', 'Audi RS7 Sportback',
       'Juego completo para eje delantero.'
FROM categorias c
WHERE c.nombre_categoria='Refacciones'
AND NOT EXISTS (SELECT 1 FROM productos WHERE codigo_barras='KRM-REF-PAST-AUDI');
INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
SELECT s.id_sucursal, p.id_producto,
       CASE p.codigo_barras
         WHEN 'KRM-P911-24' THEN 2
         WHEN 'KRM-P911-25' THEN 1
         WHEN 'KRM-PTAY-25' THEN 2
         WHEN 'KRM-ARS7-24' THEN 4
         WHEN 'KRM-AQ8E-25' THEN 5
         WHEN 'KRM-DPAN-24' THEN 6
         WHEN 'KRM-DSTR-25' THEN 3
         WHEN 'KRM-REF-DISCO-911' THEN 8
         WHEN 'KRM-REF-PAST-AUDI' THEN 10
       END,
       1
FROM sucursales s
JOIN productos p ON p.codigo_barras IN (
 'KRM-P911-24','KRM-P911-25','KRM-PTAY-25','KRM-ARS7-24',
 'KRM-AQ8E-25','KRM-DPAN-24','KRM-DSTR-25',
 'KRM-REF-DISCO-911','KRM-REF-PAST-AUDI'
)
WHERE s.nombre='Manzanillo'
AND NOT EXISTS (
  SELECT 1 FROM inventarios i
  WHERE i.id_sucursal=s.id_sucursal AND i.id_producto=p.id_producto
);
INSERT INTO clientes
(nombre, rfc_ine, celular, email, articulo, total_adeudo, monto_abono, enganche, abonos_pagados, abonos_totales, estado)
SELECT 'Roberto Fernández Aguilar', 'FERA900101XXX', '314 123 4567', 'roberto.fernandez@email.com',
       'Porsche 911 Carrera', 1880000, 450000, 470000, 5, 24, 'activo'
WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE email='roberto.fernandez@email.com');
INSERT INTO clientes
(nombre, rfc_ine, celular, email, articulo, total_adeudo, monto_abono, enganche, abonos_pagados, abonos_totales, estado)
SELECT 'Marina López Castillo', 'LOCM920202XXX', '314 987 6543', 'marina.lopez@email.com',
       'Audi RS7 Sportback', 1315000, 200000, NULL, 2, 12, 'activo'
WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE email='marina.lopez@email.com');
INSERT INTO clientes
(nombre, rfc_ine, celular, email, articulo, total_adeudo, monto_abono, enganche, abonos_pagados, abonos_totales, estado)
SELECT 'Héctor Iván Solórzano', 'SOIH930303XXX', '312 456 7890', 'hector.solorzano@email.com',
       'Ducati Panigale V4 S', 496000, 62000, 124000, 0, 24, 'activo'
WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE email='hector.solorzano@email.com');
INSERT INTO garantias (id_cliente, id_producto, fecha_expiracion, estado)
SELECT c.id_cliente, p.id_producto, '2027-03-12', 'vigente'
FROM clientes c
JOIN productos p ON p.codigo_barras='KRM-P911-24'
WHERE c.email='roberto.fernandez@email.com'
AND NOT EXISTS (
  SELECT 1 FROM garantias g
  WHERE g.id_cliente=c.id_cliente AND g.id_producto=p.id_producto
);
INSERT INTO garantias (id_cliente, id_producto, fecha_expiracion, estado)
SELECT c.id_cliente, p.id_producto, '2026-07-28', 'vencida'
FROM clientes c
JOIN productos p ON p.codigo_barras='KRM-ARS7-24'
WHERE c.email='marina.lopez@email.com'
AND NOT EXISTS (
  SELECT 1 FROM garantias g
  WHERE g.id_cliente=c.id_cliente AND g.id_producto=p.id_producto
);
INSERT INTO garantias (id_cliente, id_producto, fecha_expiracion, estado)
SELECT c.id_cliente, p.id_producto, '2026-11-05', 'vigente'
FROM clientes c
JOIN productos p ON p.codigo_barras='KRM-DPAN-24'
WHERE c.email='hector.ivan@solorzano.local'
AND NOT EXISTS (
  SELECT 1 FROM garantias g
  WHERE g.id_cliente=c.id_cliente AND g.id_producto=p.id_producto
);
INSERT INTO garantias (id_cliente, id_producto, fecha_expiracion, estado)
SELECT c.id_cliente, p.id_producto, '2026-11-05', 'vigente'
FROM clientes c
JOIN productos p ON p.codigo_barras='KRM-DPAN-24'
WHERE c.nombre='Héctor Iván Solórzano'
AND NOT EXISTS (
  SELECT 1 FROM garantias g
  WHERE g.id_cliente=c.id_cliente AND g.id_producto=p.id_producto
);
INSERT INTO web_orders
(tipo,id_producto,nombre,celular,email,enganche,fecha_visita,color,estado)
SELECT 'vehiculo', p.id_producto, 'Daniela Ruiz Ponce', '314 222 3344', 'daniela.ruiz@email.com',
       500000, '2026-09-18 11:30:00', 'Blanco Carrara', 'pendiente'
FROM productos p
WHERE p.codigo_barras='KRM-PTAY-25'
AND NOT EXISTS (SELECT 1 FROM web_orders WHERE email='daniela.ruiz@email.com');
INSERT INTO web_orders
(tipo,id_producto,nombre,celular,email,enganche,fecha_visita,color,estado)
SELECT 'vehiculo', p.id_producto, 'Iñaki Torres Vega', '314 555 6677', 'inaki.torres@email.com',
       NULL, '2026-09-19 16:00:00', 'Negro Mate', 'pendiente'
FROM productos p
WHERE p.codigo_barras='KRM-DSTR-25'
AND NOT EXISTS (SELECT 1 FROM web_orders WHERE email='inaki.torres@email.com');
INSERT INTO web_orders
(tipo,id_producto,nombre,celular,pieza,modelo_compatibilidad,marca_vehiculo,motor,cilindraje,traccion,transmision,lado,estado)
SELECT 'refaccion', p.id_producto, 'Carlos Beltrán Ibarra', '314 888 1122',
       'Disco de freno delantero', '911 (2019)', 'Porsche',
       '3.0L Boxer Biturbo', '2981 cc', 'Trasera', 'PDK automática', 'Izquierdo', 'pendiente'
FROM productos p
WHERE p.codigo_barras='KRM-REF-DISCO-911'
AND NOT EXISTS (SELECT 1 FROM web_orders WHERE nombre='Carlos Beltrán Ibarra');
SELECT 'Cajero' AS tipo, u.nombre, u.correo, s.nombre AS sucursal
FROM usuarios u
LEFT JOIN sucursales s ON s.id_sucursal=u.id_sucursal
WHERE u.correo='miranda@karma.local';
SELECT p.codigo_barras, p.nombre, i.stock_actual, p.precio_base
FROM productos p
JOIN inventarios i ON i.id_producto=p.id_producto
JOIN sucursales s ON s.id_sucursal=i.id_sucursal
WHERE s.nombre='Manzanillo'
ORDER BY p.id_producto;
SELECT nombre, email, total_adeudo, abonos_pagados, abonos_totales
FROM clientes
ORDER BY id_cliente;
