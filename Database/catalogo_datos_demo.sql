-- =====================================================================================
-- KARMA / pos_multisede — catalogo_datos_demo.sql
-- Datos de DEMOSTRACIÓN para el módulo Catálogo y la sucursal Colima.
-- Importar después de catalogo_estructura.sql y catalogo_productos.sql. Seguro de reimportar.
--
--  1. Caja 01 de la sucursal Colima (el POS necesita una caja por sucursal).
--  2. Cajeros de PRUEBA (uno por sucursal) para probar el login del Punto de Venta.
--     No modifica ni reemplaza a los usuarios existentes (Miranda sigue igual).
--       cajero.manzanillo@karma.local  /  CajaMzo#2026   → sucursal Manzanillo
--       cajero.colima@karma.local      /  CajaCol#2026   → sucursal Colima
--     Las contraseñas se guardan con hash bcrypt ($2y$12$…), igual que las del resto de usuarios.
--  3. Promociones de demostración (NO son ofertas oficiales de Audi, Porsche ni Ducati).
--  4. Opciones del configurador (colores, versiones y equipamiento por marca; precios de referencia).
-- =====================================================================================

SET NAMES utf8mb4;
USE pos_multisede;

-- ===== 1. CAJA 01 DE COLIMA =====
INSERT INTO cajas (id_sucursal, numero_caja, estado)
SELECT s.id_sucursal, 1, 'abierta'
  FROM sucursales s
 WHERE s.nombre = 'Colima'
   AND NOT EXISTS (SELECT 1 FROM cajas c WHERE c.id_sucursal = s.id_sucursal AND c.numero_caja = 1);

-- ===== 2. CAJEROS DE PRUEBA =====
INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash, idioma_pref, estado)
SELECT r.id_rol, s.id_sucursal, 'Cajero Prueba Manzanillo', 'cajero.manzanillo@karma.local',
       '$2y$12$mVz.S6d98f4eCSYludtyM.UmH.Qy1mtbEV0CWH4i55.kkibFQJAZy', 'es', 'activo'
  FROM roles r JOIN sucursales s ON s.nombre = 'Manzanillo'
 WHERE r.nombre_rol = 'Cajero'
   AND NOT EXISTS (SELECT 1 FROM usuarios WHERE correo = 'cajero.manzanillo@karma.local');

INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash, idioma_pref, estado)
SELECT r.id_rol, s.id_sucursal, 'Cajero Prueba Colima', 'cajero.colima@karma.local',
       '$2y$12$27KZH4amsGmocKsAl07ZWudt9Poz9RBNv4Irq6PDVH4U2ct8Tbl3i', 'es', 'activo'
  FROM roles r JOIN sucursales s ON s.nombre = 'Colima'
 WHERE r.nombre_rol = 'Cajero'
   AND NOT EXISTS (SELECT 1 FROM usuarios WHERE correo = 'cajero.colima@karma.local');

-- ===== 3. PROMOCIONES (demostración) =====
-- Las promociones son informativas: se aplican en sucursal (no cambian el precio del carrito en línea),
-- salvo el envío gratis, que el checkout sí calcula automáticamente.
-- IMAGEN DE LA PROMOCIÓN: cambia la columna `imagen` (ruta relativa a la raíz del proyecto).

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'audi-q5-bono', 'Bono de $40,000 en Audi Q5', 'SUV mediana con tracción quattro',
       'Estrena tu Audi Q5 2025 con un bono aplicable al cerrar tu compra en cualquiera de nuestras sucursales.',
       'vehiculos', 'Audi', 'Bono $40,000', 'assets/Catalogo/vehiculos/audi/q5.webp',
       'Promoción de demostración del proyecto académico KARMA. Aplica sobre precio de lista, sujeta a disponibilidad de inventario en la sucursal.',
       '2026-10-01', '2026-12-31', 'Ver Audi Q5', 'vehiculo.php?codigo=KRM-CAT-AUDI-08', 1, 1
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'audi-q5-bono');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'porsche-macan-tasa', 'Tasa preferencial desde 11.9% en Porsche Macan', 'Plan de crédito KARMA Financial',
       'Financia tu Porsche Macan con una tasa preferencial y plazos de hasta 60 meses. Simula tu mensualidad en línea.',
       'financiamiento', 'Porsche', '11.9% anual', 'assets/Catalogo/vehiculos/porsche/macan.webp',
       'Promoción de demostración. Tasa fija anual de referencia con enganche mínimo del 20%; sujeta a aprobación de crédito.',
       '2026-10-01', '2026-12-31', 'Simular financiamiento', 'financiamiento.php?codigo=KRM-CAT-POR-13&tasa=11.9', 1, 2
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'porsche-macan-tasa');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'ducati-multistrada-maletas', 'Maletas laterales con 15% al estrenar tu Multistrada V4', 'Listo para viajar desde el primer día',
       'Al comprar tu Ducati Multistrada V4 obtén 15% de descuento en el juego de maletas laterales rígidas.',
       'accesorios', 'Ducati', '-15% accesorios', 'assets/Catalogo/accesorios/maletas-laterales-ducati.webp',
       'Promoción de demostración. Aplica en sucursal al momento de la compra de la motocicleta.',
       '2026-10-01', '2026-12-31', 'Ver Multistrada V4', 'vehiculo.php?codigo=KRM-CAT-DUC-07', 1, 3
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'ducati-multistrada-maletas');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'servicio-aceite', 'Cambio de aceite y filtro desde $2,490', 'Servicio express en menos de 90 minutos',
       'Incluye aceite sintético de especificación de fábrica, filtro nuevo y revisión de 25 puntos.',
       'servicio', NULL, 'Desde $2,490', 'assets/Catalogo/servicios/cambio-aceite.webp',
       'Promoción de demostración. Precio de referencia para autos de hasta 6 litros de aceite; motocicletas desde $1,690.',
       '2026-10-01', '2026-12-31', 'Agendar servicio', 'agendar.php?tipo=servicio&servicio=Cambio%20de%20aceite%20y%20filtro', 1, 4
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'servicio-aceite');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'servicio-frenos', 'Revisión de frenos sin costo', 'Tu seguridad primero',
       'Medimos el espesor de pastillas y discos, revisamos el líquido de frenos y te entregamos un diagnóstico por escrito.',
       'servicio', NULL, 'Sin costo', 'assets/Catalogo/servicios/frenos.webp',
       'Promoción de demostración. Una revisión por vehículo durante la vigencia; requiere cita previa.',
       '2026-10-01', '2026-11-30', 'Agendar revisión', 'agendar.php?tipo=servicio&servicio=Servicio%20de%20frenos', 1, 5
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'servicio-frenos');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'refacciones-instalacion', 'Instalación sin costo en pastillas y discos', 'Compra en línea, instala en nuestro taller',
       'Compra tus pastillas o discos de freno en línea, recoge en sucursal y nuestro taller los instala sin costo de mano de obra.',
       'refacciones', NULL, 'Instalación gratis', 'assets/Catalogo/refacciones/porsche/disco-delantero.webp',
       'Promoción de demostración. Requiere cita de servicio en la misma sucursal donde se recoge el pedido.',
       '2026-10-01', '2026-12-31', 'Ver refacciones de frenos', 'refacciones.php?categoria=Frenos', 1, 6
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'refacciones-instalacion');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'envio-gratis', 'Envío gratis en compras desde $3,000', 'Refacciones y accesorios a domicilio',
       'Tus refacciones y accesorios llegan a domicilio sin costo de envío cuando tu pedido es de $3,000 o más.',
       'accesorios', NULL, 'Envío gratis', 'assets/Catalogo/accesorios/tapetes-audi.webp',
       'Promoción de demostración. Aplica automáticamente en el checkout para pedidos con envío y pago con tarjeta.',
       '2026-10-01', '2026-12-31', 'Ver accesorios', 'accesorios.php', 1, 7
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'envio-gratis');

INSERT INTO promociones (clave, titulo, subtitulo, descripcion, tipo, marca, etiqueta, imagen, condiciones, fecha_inicio, fecha_fin, cta_texto, cta_url, activa, orden)
SELECT 'prueba-manejo-kit', 'Agenda tu prueba de manejo y recibe un kit de bienvenida', 'Vive la experiencia antes de decidir',
       'Agenda en línea tu prueba de manejo en Manzanillo o Colima y llévate un kit de bienvenida KARMA.',
       'vehiculos', NULL, 'Regalo', 'assets/Catalogo/banners/prueba-manejo.webp',
       'Promoción de demostración. Un kit por cliente; sujeto a existencias en la sucursal.',
       '2026-10-01', '2026-12-31', 'Agendar prueba de manejo', 'agendar.php?tipo=prueba_manejo', 1, 8
 WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE clave = 'prueba-manejo-kit');

-- ===== 4. OPCIONES DEL CONFIGURADOR =====
-- grupo: color (muestra con color_hex) · version (precio adicional) · equipamiento (precio adicional)
-- Precios de referencia para la demostración; se suman al precio base en la página del vehículo.
INSERT INTO catalogo_opciones (clave, marca, tipo_vehiculo, grupo, nombre, descripcion, precio, color_hex, orden)
SELECT t.clave, t.marca, t.tipo_vehiculo, t.grupo, t.nombre, t.descripcion, t.precio, t.color_hex, t.orden
  FROM (
        SELECT 'audi-color-blanco' AS clave, 'Audi' AS marca, 'auto' AS tipo_vehiculo, 'color' AS grupo, 'Blanco Glaciar' AS nombre, 'Metálico' AS descripcion, 0 AS precio, '#F2F2EF' AS color_hex, 1 AS orden
        UNION ALL SELECT 'audi-color-negro', 'Audi', 'auto', 'color', 'Negro Mythos', 'Metálico', 0, '#101012', 2
        UNION ALL SELECT 'audi-color-nardo', 'Audi', 'auto', 'color', 'Gris Nardo', 'Sólido', 0, '#7A7D80', 3
        UNION ALL SELECT 'audi-color-azul', 'Audi', 'auto', 'color', 'Azul Ultra', 'Metálico', 0, '#1F3B66', 4
        UNION ALL SELECT 'audi-color-rojo', 'Audi', 'auto', 'color', 'Rojo Tango', 'Metálico', 0, '#8C1D2B', 5
        UNION ALL SELECT 'audi-color-verde', 'Audi', 'auto', 'color', 'Verde Distrito', 'Metálico', 12000, '#3F4A3C', 6
        UNION ALL SELECT 'audi-version-base', 'Audi', 'auto', 'version', 'Base', 'Equipamiento de serie', 0, NULL, 1
        UNION ALL SELECT 'audi-version-sline', 'Audi', 'auto', 'version', 'S line', 'Paquete exterior e interior S line con suspensión deportiva', 65000, NULL, 2
        UNION ALL SELECT 'audi-version-black', 'Audi', 'auto', 'version', 'Black Edition', 'Detalles en negro brillante, rines de 20" y techo panorámico', 95000, NULL, 3
        UNION ALL SELECT 'audi-eq-techo', 'Audi', 'auto', 'equipamiento', 'Techo panorámico', 'Techo de cristal corredizo con cortinilla eléctrica', 32000, NULL, 1
        UNION ALL SELECT 'audi-eq-audio', 'Audi', 'auto', 'equipamiento', 'Sistema de audio premium', '16 bocinas con sonido envolvente 3D', 28000, NULL, 2
        UNION ALL SELECT 'audi-eq-hud', 'Audi', 'auto', 'equipamiento', 'Head-up display', 'Información de manejo proyectada en el parabrisas', 22000, NULL, 3
        UNION ALL SELECT 'audi-eq-tour', 'Audi', 'auto', 'equipamiento', 'Asistentes de conducción Tour', 'Crucero adaptativo, carril activo y asistente de tráfico', 35000, NULL, 4
        UNION ALL SELECT 'audi-eq-rines', 'Audi', 'auto', 'equipamiento', 'Rines de 21"', 'Rines de aleación de diseño exclusivo', 41000, NULL, 5
        UNION ALL SELECT 'porsche-color-blanco', 'Porsche', 'auto', 'color', 'Blanco Carrara', 'Metálico', 0, '#EDEDEA', 1
        UNION ALL SELECT 'porsche-color-negro', 'Porsche', 'auto', 'color', 'Negro Jeweled', 'Metálico', 0, '#141414', 2
        UNION ALL SELECT 'porsche-color-gt', 'Porsche', 'auto', 'color', 'Gris GT Plata', 'Metálico', 0, '#9EA0A1', 3
        UNION ALL SELECT 'porsche-color-azul', 'Porsche', 'auto', 'color', 'Azul Gentian', 'Metálico', 0, '#1B3A6B', 4
        UNION ALL SELECT 'porsche-color-rojo', 'Porsche', 'auto', 'color', 'Rojo Carmín', 'Sólido', 0, '#9E1B2E', 5
        UNION ALL SELECT 'porsche-color-verde', 'Porsche', 'auto', 'color', 'Verde Python', 'Color especial', 48000, '#5C7D3A', 6
        UNION ALL SELECT 'porsche-color-amarillo', 'Porsche', 'auto', 'color', 'Amarillo Racing', 'Color especial', 48000, '#F2C230', 7
        UNION ALL SELECT 'porsche-version-base', 'Porsche', 'auto', 'version', 'Base', 'Equipamiento de serie', 0, NULL, 1
        UNION ALL SELECT 'porsche-version-chrono', 'Porsche', 'auto', 'version', 'Paquete Sport Chrono', 'Cronómetro, modo Sport Plus y Launch Control', 78000, NULL, 2
        UNION ALL SELECT 'porsche-version-design', 'Porsche', 'auto', 'version', 'Paquete Sport Design', 'Fascias y faldones deportivos con detalles en negro', 115000, NULL, 3
        UNION ALL SELECT 'porsche-eq-audio', 'Porsche', 'auto', 'equipamiento', 'Sistema de audio de alta fidelidad', 'Amplificación dedicada y bocinas de alto desempeño', 54000, NULL, 1
        UNION ALL SELECT 'porsche-eq-asientos', 'Porsche', 'auto', 'equipamiento', 'Asientos deportivos adaptativos', '18 posiciones eléctricas con memoria', 68000, NULL, 2
        UNION ALL SELECT 'porsche-eq-direccion', 'Porsche', 'auto', 'equipamiento', 'Dirección en el eje trasero', 'Mayor agilidad en curvas y estabilidad a alta velocidad', 72000, NULL, 3
        UNION ALL SELECT 'porsche-eq-matrix', 'Porsche', 'auto', 'equipamiento', 'Faros LED Matrix con PDLS Plus', 'Iluminación adaptativa con luz de curva', 45000, NULL, 4
        UNION ALL SELECT 'porsche-eq-pccb', 'Porsche', 'auto', 'equipamiento', 'Frenos cerámicos PCCB', 'Discos de carbono-cerámica con calipers amarillos', 260000, NULL, 5
        UNION ALL SELECT 'ducati-color-rojo', 'Ducati', 'moto', 'color', 'Rojo Ducati', 'Color de la marca', 0, '#9E1B2E', 1
        UNION ALL SELECT 'ducati-color-gris', 'Ducati', 'moto', 'color', 'Gris Antracita', 'Mate', 0, '#4A4A4A', 2
        UNION ALL SELECT 'ducati-color-blanco', 'Ducati', 'moto', 'color', 'Blanco Dark', 'Brillante', 0, '#E7E7E4', 3
        UNION ALL SELECT 'ducati-color-negro', 'Ducati', 'moto', 'color', 'Negro Mate', 'Mate', 0, '#1A1A1A', 4
        UNION ALL SELECT 'ducati-color-verde', 'Ducati', 'moto', 'color', 'Verde Storm', 'Edición especial', 9500, '#4D5845', 5
        UNION ALL SELECT 'ducati-version-std', 'Ducati', 'moto', 'version', 'Estándar', 'Equipamiento de serie', 0, NULL, 1
        UNION ALL SELECT 'ducati-version-perf', 'Ducati', 'moto', 'version', 'Paquete Performance', 'Escape deportivo, asiento racing y piezas de aluminio maquinado', 38000, NULL, 2
        UNION ALL SELECT 'ducati-eq-punos', 'Ducati', 'moto', 'equipamiento', 'Puños con calefacción', 'Tres niveles de temperatura', 6500, NULL, 1
        UNION ALL SELECT 'ducati-eq-crucero', 'Ducati', 'moto', 'equipamiento', 'Control de crucero', 'Mandos integrados en el manubrio', 9800, NULL, 2
        UNION ALL SELECT 'ducati-eq-asiento', 'Ducati', 'moto', 'equipamiento', 'Asiento confort', 'Espuma de doble densidad para viajes largos', 5200, NULL, 3
        UNION ALL SELECT 'ducati-eq-nav', 'Ducati', 'moto', 'equipamiento', 'Navegación en pantalla TFT', 'Mapas paso a paso conectados al celular', 7900, NULL, 4
        UNION ALL SELECT 'ducati-eq-alarma', 'Ducati', 'moto', 'equipamiento', 'Alarma antirrobo', 'Inmovilizador con sensor de movimiento', 6200, NULL, 5
  ) t
 WHERE NOT EXISTS (SELECT 1 FROM catalogo_opciones o WHERE o.clave = t.clave);

-- ===== VERIFICACIÓN =====
SELECT u.nombre, u.correo, r.nombre_rol, s.nombre AS sucursal
  FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol LEFT JOIN sucursales s ON s.id_sucursal = u.id_sucursal
 ORDER BY u.id_usuario;
SELECT c.id_caja, s.nombre AS sucursal, c.numero_caja, c.estado FROM cajas c JOIN sucursales s ON s.id_sucursal = c.id_sucursal;
SELECT COUNT(*) AS promociones FROM promociones;
SELECT marca, grupo, COUNT(*) AS opciones FROM catalogo_opciones GROUP BY marca, grupo;
