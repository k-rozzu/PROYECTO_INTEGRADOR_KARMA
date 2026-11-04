-- KARMA / POS multisede
-- Agrega a cada caja el cajero asignado (opcional).
-- Lo usa el panel de gerente para asignar un cajero por caja.
-- Compatible con MySQL y MariaDB. Se puede ejecutar más de una vez.
USE pos_multisede;

-- 1. Columna id_usuario_asignado (NULL = caja sin cajero asignado)
SET @existe = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'cajas'
      AND COLUMN_NAME = 'id_usuario_asignado'
);
SET @sql = IF(@existe > 0,
    "SELECT 'La columna id_usuario_asignado ya existe en cajas'",
    "ALTER TABLE cajas ADD COLUMN id_usuario_asignado INT NULL"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Llave foránea hacia usuarios (si se borra el usuario, la caja queda sin asignar)
SET @existe = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'cajas'
      AND CONSTRAINT_NAME = 'fk_cajas_usuario_asignado'
);
SET @sql = IF(@existe > 0,
    "SELECT 'La llave foranea fk_cajas_usuario_asignado ya existe'",
    "ALTER TABLE cajas ADD CONSTRAINT fk_cajas_usuario_asignado FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;