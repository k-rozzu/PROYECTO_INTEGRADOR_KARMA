-- KARMA · Contratos de crédito automotriz del Punto de Venta (enganche + contrato firmado por el cliente).
-- Se puede ejecutar varias veces sin riesgo: solo agrega lo que falta y no borra ni modifica datos existentes,
-- salvo el apellido de la cajera Carolina (pedido explícito) y solo si todavía no tiene uno.
--
--   * usuarios.apellidos              -> nombre completo del representante de KARMA en el contrato
--   * clientes.identificacion_numero  -> folio de la identificación oficial del acreditado
--   * productos.numero_motor          -> número de serie del motor de la unidad (se imprime en el contrato si está capturado)
--   * metodos_pago 'Sin cobro (enganche $0)' -> método de las ventas a crédito sin enganche (no hay dinero que cobrar)
--   * contratos_credito               -> un renglón por crédito: datos de la operación, condiciones, tabla de amortización,
--                                        firma del cliente (SVG) y el PDF definitivo para consultarlo después

SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;

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

DELIMITER ;

CALL karma_tmp_agregar_columna('usuarios', 'apellidos',
    "VARCHAR(100) NULL DEFAULT NULL COMMENT 'Apellidos del empleado (nombre completo = nombre + apellidos)' AFTER `nombre`");
CALL karma_tmp_agregar_columna('clientes', 'identificacion_numero',
    "VARCHAR(40) NULL DEFAULT NULL COMMENT 'Folio o número de la identificación oficial' AFTER `identificacion_tipo`");
CALL karma_tmp_agregar_columna('productos', 'numero_motor',
    "VARCHAR(40) NULL DEFAULT NULL COMMENT 'Número de serie del motor de la unidad' AFTER `vin`");

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;

-- Apellido de la cajera Carolina para que el contrato muestre su nombre completo (Carolina Martinez)
UPDATE usuarios SET apellidos = 'Martinez'
 WHERE correo = 'Carolina@karma.com' AND (apellidos IS NULL OR apellidos = '');

-- Método de pago para los créditos con enganche de $0 (ventas.id_metodo_pago es obligatorio)
INSERT INTO metodos_pago (nombre_metodo)
SELECT 'Sin cobro (enganche $0)' FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM metodos_pago WHERE nombre_metodo = 'Sin cobro (enganche $0)');

CREATE TABLE IF NOT EXISTS `contratos_credito` (
  `id_contrato` int(11) NOT NULL AUTO_INCREMENT,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-CC-{sucursal}-{id}',
  `estado` enum('pendiente_firma','firmado','cancelado') NOT NULL DEFAULT 'pendiente_firma'
      COMMENT 'pendiente_firma = enganche cobrado y contrato en pantalla; firmado = crédito concretado; cancelado = el cliente no firmó',
  `id_sucursal` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL COMMENT 'Cajero que atendió (representante de KARMA)',
  `id_caja` int(11) NOT NULL,
  `ticket_numero` int(11) DEFAULT NULL,
  `id_producto` int(11) NOT NULL,
  `vin` varchar(17) DEFAULT NULL,
  `id_venta` int(11) DEFAULT NULL COMMENT 'Venta registrada al firmar (NULL mientras no se firma)',
  `id_cliente` int(11) DEFAULT NULL COMMENT 'Cliente de la sección Clientes ligado al firmar',
  `cliente_nombre` varchar(150) NOT NULL,
  `precio_contado` decimal(12,2) NOT NULL,
  `enganche` decimal(12,2) NOT NULL,
  `saldo_financiar` decimal(12,2) NOT NULL,
  `comision_apertura` decimal(12,2) NOT NULL,
  `monto_financiado` decimal(12,2) NOT NULL,
  `tasa_anual` decimal(7,3) NOT NULL COMMENT 'Tasa ordinaria anual fija (%)',
  `cat` decimal(8,2) DEFAULT NULL COMMENT 'Costo anual total (%) sin IVA',
  `plazo_meses` int(11) NOT NULL,
  `mensualidad` decimal(12,2) NOT NULL,
  `monto_interes` decimal(12,2) NOT NULL,
  `monto_total` decimal(12,2) NOT NULL COMMENT 'Suma de todas las mensualidades',
  `importe_cobrado` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Enganche + artículos de contado del mismo ticket',
  `metodo_pago` varchar(50) DEFAULT NULL,
  `efectivo_recibido` decimal(12,2) DEFAULT NULL,
  `cambio` decimal(12,2) DEFAULT NULL,
  `datos_json` longtext NOT NULL COMMENT 'Copia de la operación: partes, vehículo, condiciones y tabla de amortización',
  `firma_cliente` mediumtext DEFAULT NULL COMMENT 'Firma del acreditado en SVG (generado por el servidor a partir de los trazos)',
  `pdf` mediumblob DEFAULT NULL COMMENT 'PDF definitivo del contrato firmado',
  `pdf_sha256` char(64) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_firma` datetime DEFAULT NULL,
  `fecha_cancelacion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_contrato`),
  UNIQUE KEY `uq_contratos_folio` (`folio`),
  UNIQUE KEY `uq_contratos_venta` (`id_venta`),
  KEY `idx_contratos_cliente` (`id_cliente`),
  KEY `idx_contratos_estado` (`estado`),
  KEY `idx_contratos_usuario` (`id_usuario`),
  KEY `fk_contratos_sucursal` (`id_sucursal`),
  KEY `fk_contratos_caja` (`id_caja`),
  KEY `fk_contratos_producto` (`id_producto`),
  CONSTRAINT `fk_contratos_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_venta` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Contratos de crédito automotriz generados y firmados en el Punto de Venta';
