USE pos_multisede;

-- 1. Modificar tabla productos (agrega las columnas solo si no existen)
SET @dropdown = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'traccion') > 0,
    "SELECT 'La columna traccion ya existe';",
    "ALTER TABLE productos ADD COLUMN traccion VARCHAR(80) NULL, ADD COLUMN lado VARCHAR(50) NULL;"
));
PREPARE stmt FROM @dropdown;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Modificar tabla clientes
SET @dropdown = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'clientes' AND COLUMN_NAME = 'direccion') > 0,
    "SELECT 'La columna direccion ya existe';",
    "ALTER TABLE clientes ADD COLUMN direccion VARCHAR(255) NULL, ADD COLUMN identificacion_tipo VARCHAR(30) NULL;"
));
PREPARE stmt FROM @dropdown;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. Modificar tabla detalle_ventas
SET @dropdown = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'detalle_ventas' AND COLUMN_NAME = 'vin') > 0,
    "SELECT 'La columna vin ya existe';",
    "ALTER TABLE detalle_ventas ADD COLUMN vin VARCHAR(50) NULL, ADD COLUMN motor_serie VARCHAR(80) NULL, ADD COLUMN color_interior VARCHAR(80) NULL;"
));
PREPARE stmt FROM @dropdown;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. Insertar nuevo producto (Evita duplicar el código de barras)
INSERT INTO productos (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, tipo, traccion, lado, compatibilidad)
SELECT c.id_categoria, 'KRM-REF-BALATA-AUDI', 'Balata delantera', 'Balata delantera para Audi RS7', 9800, 'Audi', 'RS7 Sportback (2024)', 'refaccion', 'Delantera', 'Izquierdo', 'Audi RS7 Sportback'
FROM categorias c
WHERE c.nombre_categoria = 'Refacciones'
  AND NOT EXISTS (
      SELECT 1 FROM productos p WHERE p.codigo_barras = 'KRM-REF-BALATA-AUDI'
  );

-- 5. Crear registro de inventario inicial (Evita duplicar la combinación sucursal + producto)
INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
SELECT s.id_sucursal, p.id_producto, 1, 1
FROM sucursales s 
JOIN productos p ON p.codigo_barras = 'KRM-REF-BALATA-AUDI'
WHERE s.nombre = 'Manzanillo'
  AND NOT EXISTS (
      SELECT 1 FROM inventarios i WHERE i.id_sucursal = s.id_sucursal AND i.id_producto = p.id_producto
  );