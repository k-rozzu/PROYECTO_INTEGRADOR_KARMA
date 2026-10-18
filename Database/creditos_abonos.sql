-- KARMA · Créditos activos y abonos mensuales del Punto de Venta.
-- Se puede ejecutar varias veces sin riesgo.
--
--   * contratos_credito: cada crédito firmado lleva su propio estado de pago (abonos pagados, saldo pendiente y si está
--     activo, liquidado o cancelado). La sección «Clientes» del POS muestra SOLO los créditos activos con saldo.
--   * abonos_credito: un renglón por mensualidad cobrada en caja. No es una venta: no toca ventas, inventario ni los
--     datos originales del contrato. La llave única (contrato, número de abono) y la clave de idempotencia impiden
--     que una misma mensualidad se registre dos veces.
--   * Limpieza: los créditos antiguos sin contrato firmado (datos de prueba) dejan de figurar como crédito en clientes,
--     y se borran solo los clientes de prueba que no tienen ninguna operación, cuenta web ni relación en otra tabla.

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

-- ===== 1. Estado de pago de cada crédito =====
CALL karma_tmp_agregar_columna('contratos_credito', 'estado_credito',
    "enum('activo','liquidado','cancelado') NULL DEFAULT NULL COMMENT 'activo = con saldo; liquidado = pagado completo; cancelado = anulado' AFTER `estado`");
CALL karma_tmp_agregar_columna('contratos_credito', 'abonos_pagados',
    "int(11) NOT NULL DEFAULT 0 COMMENT 'Mensualidades cobradas' AFTER `monto_total`");
CALL karma_tmp_agregar_columna('contratos_credito', 'saldo_pendiente',
    "decimal(12,2) NULL DEFAULT NULL COMMENT 'Suma de las mensualidades que faltan por pagar' AFTER `abonos_pagados`");
CALL karma_tmp_agregar_columna('contratos_credito', 'fecha_liquidacion',
    "datetime NULL DEFAULT NULL AFTER `fecha_firma`");

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;

-- Créditos firmados que todavía no tienen estado de pago: activos, sin abonos y con todas sus mensualidades pendientes
UPDATE contratos_credito
   SET estado_credito = 'activo', abonos_pagados = 0, saldo_pendiente = ROUND(mensualidad, 2) * plazo_meses
 WHERE estado = 'firmado' AND estado_credito IS NULL;

-- ===== 2. Abonos mensuales =====
CREATE TABLE IF NOT EXISTS `abonos_credito` (
  `id_abono` int(11) NOT NULL AUTO_INCREMENT,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-AB-{sucursal}-{id}',
  `id_contrato` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `numero_abono` int(11) NOT NULL COMMENT 'Número de mensualidad según la tabla de amortización (1..plazo)',
  `importe` decimal(12,2) NOT NULL,
  `saldo_anterior` decimal(12,2) NOT NULL,
  `saldo_restante` decimal(12,2) NOT NULL,
  `fecha_vencimiento` date DEFAULT NULL COMMENT 'Vencimiento de esa mensualidad en la tabla de amortización',
  `id_sucursal` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL COMMENT 'Cajero que cobró (autenticado con su gafete)',
  `id_caja` int(11) NOT NULL,
  `ticket_numero` int(11) DEFAULT NULL,
  `metodo_pago` varchar(50) NOT NULL,
  `efectivo_recibido` decimal(12,2) DEFAULT NULL,
  `cambio` decimal(12,2) DEFAULT NULL,
  `clave_idempotencia` char(36) NOT NULL COMMENT 'Identificador del cobro generado en caja: un reenvío no cobra dos veces',
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_abono`),
  UNIQUE KEY `uq_abonos_folio` (`folio`),
  UNIQUE KEY `uq_abonos_contrato_numero` (`id_contrato`, `numero_abono`),
  UNIQUE KEY `uq_abonos_clave` (`clave_idempotencia`),
  KEY `idx_abonos_caja_fecha` (`id_caja`, `fecha_hora`),
  KEY `fk_abonos_cliente` (`id_cliente`),
  KEY `fk_abonos_sucursal` (`id_sucursal`),
  KEY `fk_abonos_usuario` (`id_usuario`),
  CONSTRAINT `fk_abonos_contrato` FOREIGN KEY (`id_contrato`) REFERENCES `contratos_credito` (`id_contrato`) ON UPDATE CASCADE,
  CONSTRAINT `fk_abonos_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_abonos_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_abonos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_abonos_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Mensualidades de los créditos automotrices cobradas en caja';

-- ===== 3. Limpieza de créditos de prueba =====
-- Créditos guardados en clientes sin un contrato firmado que los respalde: dejan de figurar como crédito
UPDATE clientes c
   SET c.articulo = NULL, c.total_adeudo = NULL, c.monto_abono = NULL, c.enganche = NULL, c.abonos_pagados = 0, c.abonos_totales = 0
 WHERE c.abonos_totales > 0
   AND NOT EXISTS (SELECT 1 FROM contratos_credito k WHERE k.id_cliente = c.id_cliente AND k.estado = 'firmado');

-- Clientes de prueba sin ninguna operación, cuenta web ni relación en otra tabla (no se toca a nadie con historial)
DELETE c FROM clientes c
 WHERE c.password_hash IS NULL AND c.abonos_totales = 0
   AND NOT EXISTS (SELECT 1 FROM ventas x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM contratos_credito x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM garantias x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM web_orders x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM citas x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM notificaciones x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM favoritos_catalogo x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM solicitudes x WHERE x.id_cliente = c.id_cliente)
   AND NOT EXISTS (SELECT 1 FROM abonos_credito x WHERE x.id_cliente = c.id_cliente);

-- La ficha del cliente refleja el saldo de su crédito más reciente (la cuenta del Catálogo muestra estos datos)
UPDATE clientes c
  JOIN contratos_credito k ON k.id_contrato = (
        SELECT MAX(k2.id_contrato) FROM contratos_credito k2 WHERE k2.id_cliente = c.id_cliente AND k2.estado = 'firmado')
   SET c.abonos_pagados = k.abonos_pagados, c.total_adeudo = k.saldo_pendiente
 WHERE k.estado_credito = 'activo';
