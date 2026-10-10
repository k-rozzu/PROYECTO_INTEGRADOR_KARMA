-- KARMA · Garantías del Punto de Venta: registro automático al vender un vehículo, caducidad exacta a 4 años
-- y solicitudes de garantía que el cajero envía al gerente (el cajero NO aprueba).
-- Se puede ejecutar varias veces sin riesgo.
--
--   * garantias: la caducidad pasa a fecha y HORA (DATETIME); se guarda la venta, el VIN, la fecha de compra y los datos
--     del comprador (las ventas de contado no se registran en clientes, por eso id_cliente ahora es opcional).
--     Estado 'aplicada' = el gerente confirmó una solicitud y la garantía ya fue atendida.
--   * Limpieza de datos de prueba: se borran SOLO las garantías sin venta asociada (id_venta IS NULL). Las garantías reales
--     siempre nacen ligadas a su venta, así que este borrado nunca toca una garantía real aunque se vuelva a ejecutar.
--   * solicitudes_garantia: una fila por formulario enviado desde caja ('pendiente'). Los triggers impiden que una solicitud
--     nazca aprobada y exigen que la resuelva un Gerente o Administrador activo distinto de quien la envió; al confirmarla,
--     la garantía queda 'aplicada' y al denegarla se exige el motivo.
--   * ev_garantias_vencidas: evento de MySQL que cada minuto pasa a 'vencida' toda garantía cuya fecha y hora de
--     vencimiento ya llegó, aunque nadie tenga abierto el POS (requiere event_scheduler = ON).

SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS karma_tmp_ejecutar_si_falta;

DELIMITER $$

-- Agrega una columna solo si todavía no existe en la tabla
CREATE PROCEDURE karma_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND COLUMN_NAME = p_columna
    ) THEN
        SET @karma_sql = CONCAT('ALTER TABLE `', p_tabla, '` ADD COLUMN `', p_columna, '` ', p_definicion);
        PREPARE karma_st FROM @karma_sql;
        EXECUTE karma_st;
        DEALLOCATE PREPARE karma_st;
    END IF;
END$$

-- Ejecuta una sentencia (índice o llave foránea) solo si el objeto con ese nombre no existe
CREATE PROCEDURE karma_tmp_ejecutar_si_falta(IN p_tipo VARCHAR(10), IN p_tabla VARCHAR(64), IN p_nombre VARCHAR(64), IN p_sql TEXT)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    IF p_tipo = 'indice' THEN
        SELECT COUNT(*) INTO v_existe FROM information_schema.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND INDEX_NAME = p_nombre;
    ELSE
        SELECT COUNT(*) INTO v_existe FROM information_schema.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND CONSTRAINT_NAME = p_nombre
           AND CONSTRAINT_TYPE = 'FOREIGN KEY';
    END IF;
    IF v_existe = 0 THEN
        SET @karma_sql = p_sql;
        PREPARE karma_st FROM @karma_sql;
        EXECUTE karma_st;
        DEALLOCATE PREPARE karma_st;
    END IF;
END$$

DELIMITER ;

-- ===== 1. Tabla garantias =====
-- Caducidad con fecha y hora exactas, comprador opcional en clientes y nuevo estado 'aplicada'
ALTER TABLE garantias
    MODIFY `id_cliente` int(11) NULL DEFAULT NULL COMMENT 'Cliente de la sección Clientes (créditos o compradores con cuenta); NULL en contado',
    MODIFY `fecha_expiracion` datetime NOT NULL COMMENT 'Fecha y hora exactas de vencimiento (compra + 4 años)',
    MODIFY `estado` enum('vigente','vencida','cancelada','aplicada') NOT NULL DEFAULT 'vigente';

CALL karma_tmp_agregar_columna('garantias', 'id_venta',
    "int(11) NULL DEFAULT NULL COMMENT 'Venta con la que se compró el vehículo' AFTER `id_producto`");
CALL karma_tmp_agregar_columna('garantias', 'id_sucursal',
    "int(11) NULL DEFAULT NULL COMMENT 'Sucursal donde se vendió' AFTER `id_venta`");
CALL karma_tmp_agregar_columna('garantias', 'vin',
    "varchar(17) NULL DEFAULT NULL COMMENT 'VIN de la unidad vendida' AFTER `id_sucursal`");
CALL karma_tmp_agregar_columna('garantias', 'cliente_nombre',
    "varchar(150) NULL DEFAULT NULL COMMENT 'Comprador tal como se capturó en caja' AFTER `vin`");
CALL karma_tmp_agregar_columna('garantias', 'cliente_celular',
    "varchar(30) NULL DEFAULT NULL AFTER `cliente_nombre`");
CALL karma_tmp_agregar_columna('garantias', 'cliente_email',
    "varchar(120) NULL DEFAULT NULL AFTER `cliente_celular`");
CALL karma_tmp_agregar_columna('garantias', 'fecha_compra',
    "datetime NULL DEFAULT NULL COMMENT 'Momento real de la venta (ventas.fecha_hora)' AFTER `cliente_email`");

-- ===== 2. Datos de prueba: garantías sin venta asociada (las de Database/datos_prueba_cajero.sql) =====
DELETE FROM garantias WHERE id_venta IS NULL;

CALL karma_tmp_ejecutar_si_falta('indice', 'garantias', 'idx_garantias_vencimiento',
    'CREATE INDEX idx_garantias_vencimiento ON garantias (estado, fecha_expiracion)');
CALL karma_tmp_ejecutar_si_falta('indice', 'garantias', 'uq_garantias_venta_vin',
    'CREATE UNIQUE INDEX uq_garantias_venta_vin ON garantias (id_venta, vin)');
CALL karma_tmp_ejecutar_si_falta('fk', 'garantias', 'fk_garantias_ventas',
    'ALTER TABLE garantias ADD CONSTRAINT fk_garantias_ventas FOREIGN KEY (id_venta) REFERENCES ventas (id_venta) ON DELETE SET NULL ON UPDATE CASCADE');

-- ===== 3. Solicitudes de garantía (formulario de caja → aprobación del gerente) =====
CREATE TABLE IF NOT EXISTS `solicitudes_garantia` (
  `id_solicitud` int(11) NOT NULL AUTO_INCREMENT,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-SG-{sucursal}-{id}',
  `id_garantia` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL COMMENT 'Sucursal donde se levantó la solicitud',
  `id_usuario_solicita` int(11) NOT NULL COMMENT 'Cajero que llenó el formulario (autenticado con su gafete)',
  `estado` enum('pendiente','confirmada','denegada') NOT NULL DEFAULT 'pendiente',
  `motivo_rechazo` varchar(500) DEFAULT NULL COMMENT 'Obligatorio cuando el gerente la deniega',
  `id_usuario_resuelve` int(11) DEFAULT NULL COMMENT 'Gerente o administrador que la confirmó o denegó',
  `datos_json` longtext NOT NULL COMMENT 'Campos del formulario: VIN, kilometraje, síntoma, condiciones, evidencia, etc.',
  `fecha_solicitud` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_resolucion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_solicitud`),
  UNIQUE KEY `uq_solicitudes_garantia_folio` (`folio`),
  KEY `idx_solicitudes_garantia_estado` (`id_garantia`, `estado`),
  KEY `fk_solicitudes_garantia_sucursal` (`id_sucursal`),
  KEY `fk_solicitudes_garantia_solicita` (`id_usuario_solicita`),
  KEY `fk_solicitudes_garantia_resuelve` (`id_usuario_resuelve`),
  CONSTRAINT `fk_solicitudes_garantia_garantia` FOREIGN KEY (`id_garantia`) REFERENCES `garantias` (`id_garantia`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_garantia_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_garantia_solicita` FOREIGN KEY (`id_usuario_solicita`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_garantia_resuelve` FOREIGN KEY (`id_usuario_resuelve`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Solicitudes de garantía levantadas en caja; las confirma o deniega un gerente';

DROP TRIGGER IF EXISTS trg_solicitudes_garantia_nueva;
DROP TRIGGER IF EXISTS trg_solicitudes_garantia_resolver;
DROP TRIGGER IF EXISTS trg_solicitudes_garantia_aplicada;

DELIMITER $$

-- Toda solicitud nace pendiente: nadie puede registrarla ya aprobada o denegada
CREATE TRIGGER trg_solicitudes_garantia_nueva BEFORE INSERT ON solicitudes_garantia FOR EACH ROW
BEGIN
    SET NEW.estado = 'pendiente', NEW.id_usuario_resuelve = NULL, NEW.fecha_resolucion = NULL, NEW.motivo_rechazo = NULL;
END$$

-- Reglas para resolver una solicitud (las usará el módulo del gerente)
CREATE TRIGGER trg_solicitudes_garantia_resolver BEFORE UPDATE ON solicitudes_garantia FOR EACH ROW
BEGIN
    IF NEW.estado <> OLD.estado THEN
        IF OLD.estado <> 'pendiente' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La solicitud de garantía ya fue resuelta.';
        END IF;
        IF NEW.id_usuario_resuelve IS NULL OR NOT EXISTS (
            SELECT 1 FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
             WHERE u.id_usuario = NEW.id_usuario_resuelve AND u.estado = 'activo'
               AND r.nombre_rol IN ('Gerente', 'Administrador General')
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un gerente o administrador activo puede confirmar o denegar una solicitud de garantía.';
        END IF;
        IF NEW.id_usuario_resuelve = OLD.id_usuario_solicita THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quien envía una solicitud de garantía no puede resolverla.';
        END IF;
        IF NEW.estado = 'denegada' AND TRIM(COALESCE(NEW.motivo_rechazo, '')) = '' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Para denegar una solicitud de garantía se debe indicar el motivo.';
        END IF;
        SET NEW.fecha_resolucion = COALESCE(NEW.fecha_resolucion, NOW());
    END IF;
END$$

-- Solicitud confirmada = garantía aplicada (sale de la lista de garantías pendientes de atención)
CREATE TRIGGER trg_solicitudes_garantia_aplicada AFTER UPDATE ON solicitudes_garantia FOR EACH ROW
BEGIN
    IF NEW.estado = 'confirmada' AND OLD.estado = 'pendiente' THEN
        UPDATE garantias SET estado = 'aplicada' WHERE id_garantia = NEW.id_garantia;
    END IF;
END$$

DELIMITER ;

-- ===== 4. Caducidad automática =====
DROP EVENT IF EXISTS ev_garantias_vencidas;
CREATE EVENT ev_garantias_vencidas
    ON SCHEDULE EVERY 1 MINUTE STARTS CURRENT_TIMESTAMP
    ON COMPLETION PRESERVE ENABLE
    COMMENT 'Garantías cuya fecha y hora de vencimiento ya llegó dejan de estar vigentes'
    DO UPDATE garantias SET estado = 'vencida' WHERE estado = 'vigente' AND fecha_expiracion <= NOW();

-- Enciende el programador de eventos de MySQL (en XAMPP también queda event_scheduler=ON en my.ini para cada arranque)
SET GLOBAL event_scheduler = ON;

UPDATE garantias SET estado = 'vencida' WHERE estado = 'vigente' AND fecha_expiracion <= NOW();

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS karma_tmp_ejecutar_si_falta;
