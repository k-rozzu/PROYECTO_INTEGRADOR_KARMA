-- KARMA / POS multisede
-- Agrega el estado (activo / inactivo) al inventario de cada sucursal.
-- Lo usa el panel de gerente para desactivar productos sin borrarlos.
-- Compatible con MySQL y MariaDB. Se puede ejecutar más de una vez.
USE pos_multisede;

SET @existe = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'inventarios'
      AND COLUMN_NAME = 'estado'
);
SET @sql = IF(@existe > 0,
    "SELECT 'La columna estado ya existe en inventarios'",
    "ALTER TABLE inventarios ADD COLUMN estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo'"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;