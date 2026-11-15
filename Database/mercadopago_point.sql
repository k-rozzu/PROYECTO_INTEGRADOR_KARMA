-- KARMA · Cobro con tarjeta en el Punto de Venta mediante Mercado Pago Point (API de Orders).
-- Se puede ejecutar varias veces sin riesgo. No modifica ninguna tabla existente.
--
--   * terminales_point: qué terminal Point cobra en cada caja, por entorno (prueba = terminal virtual de Mercado Pago,
--     produccion = terminal física). Para habilitar otra sucursal basta con agregar su fila.
--   * pagos_mercadopago: un renglón por cada cobro enviado a la terminal. Guarda el importe exacto, los datos ya validados
--     del ticket y el estado del cobro. La venta (o el abono, o la orden web) se registra UNA sola vez, cuando Mercado Pago
--     confirma el pago: las llaves únicas (clave, referencia y orden de Mercado Pago) impiden cobros o registros duplicados.
--   * pagos_mercadopago_eventos: bitácora de cada consulta a la API y de cada Webhook recibido (firma válida o no).
--
-- Las credenciales (Access Token y clave secreta del Webhook) NO van aquí: viven en el archivo .env.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `terminales_point` (
  `id_terminal` int(11) NOT NULL AUTO_INCREMENT,
  `entorno` enum('prueba','produccion') NOT NULL,
  `id_caja` int(11) NOT NULL,
  `terminal_id` varchar(80) NOT NULL COMMENT 'TIPO__SERIE, tal como lo devuelve /terminals/v1/list',
  `descripcion` varchar(80) DEFAULT NULL,
  `activa` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_terminal`),
  UNIQUE KEY `uq_terminales_point_caja` (`entorno`, `id_caja`),
  KEY `fk_terminales_point_caja` (`id_caja`),
  CONSTRAINT `fk_terminales_point_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Terminal Mercado Pago Point de cada caja';

CREATE TABLE IF NOT EXISTS `pagos_mercadopago` (
  `id_pago_mp` int(11) NOT NULL AUTO_INCREMENT,
  `clave` char(36) NOT NULL COMMENT 'UUID del cobro generado en caja; también es la X-Idempotency-Key de la orden',
  `referencia_externa` varchar(64) NOT NULL COMMENT 'external_reference enviada a Mercado Pago (sin datos personales)',
  `tipo` enum('venta','enganche','abono','orden_web') NOT NULL,
  `entorno` enum('prueba','produccion') NOT NULL,
  `estado` enum('creando','en_terminal','aprobado','registrado','rechazado','cancelado','expirado','error') NOT NULL DEFAULT 'creando'
    COMMENT 'aprobado = Mercado Pago cobró y falta registrar (o el enganche espera su contrato); registrado = operación guardada',
  `id_sucursal` int(11) NOT NULL,
  `id_caja` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL COMMENT 'Cajero que inició el cobro',
  `ticket_numero` int(11) DEFAULT NULL,
  `terminal_id` varchar(80) NOT NULL,
  `importe` decimal(12,2) NOT NULL COMMENT 'Importe exacto calculado por el servidor con los precios de la BD',
  `moneda` char(3) NOT NULL DEFAULT 'MXN',
  `descripcion` varchar(150) DEFAULT NULL,
  `solicitud_json` longtext NOT NULL COMMENT 'Datos del ticket ya validados para registrar la operación al aprobarse',
  `mp_order_id` varchar(64) DEFAULT NULL,
  `mp_payment_id` varchar(64) DEFAULT NULL,
  `mp_referencia` varchar(40) DEFAULT NULL COMMENT 'reference_id del pago (número de operación)',
  `mp_estado` varchar(30) DEFAULT NULL,
  `mp_estado_detalle` varchar(40) DEFAULT NULL,
  `tarjeta_tipo` varchar(20) DEFAULT NULL COMMENT 'credit_card, debit_card o prepaid_card',
  `tarjeta_marca` varchar(30) DEFAULT NULL,
  `cuotas` int(11) DEFAULT NULL,
  `importe_pagado` decimal(12,2) DEFAULT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `id_abono` int(11) DEFAULT NULL,
  `id_contrato` int(11) DEFAULT NULL COMMENT 'Enganche: contrato que usa este pago',
  `id_orden_web` int(11) DEFAULT NULL,
  `resultado_json` text DEFAULT NULL COMMENT 'Datos del ticket que se devolvieron al registrar',
  `mensaje` varchar(255) DEFAULT NULL,
  `ultima_consulta` datetime DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_aprobacion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_pago_mp`),
  UNIQUE KEY `uq_pagos_mp_clave` (`clave`),
  UNIQUE KEY `uq_pagos_mp_referencia` (`referencia_externa`),
  UNIQUE KEY `uq_pagos_mp_orden` (`mp_order_id`),
  UNIQUE KEY `uq_pagos_mp_venta` (`id_venta`),
  UNIQUE KEY `uq_pagos_mp_abono` (`id_abono`),
  KEY `idx_pagos_mp_caja_estado` (`id_caja`, `estado`),
  KEY `fk_pagos_mp_sucursal` (`id_sucursal`),
  KEY `fk_pagos_mp_usuario` (`id_usuario`),
  KEY `fk_pagos_mp_contrato` (`id_contrato`),
  KEY `fk_pagos_mp_orden_web` (`id_orden_web`),
  CONSTRAINT `fk_pagos_mp_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_mp_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_mp_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_mp_venta` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_mp_abono` FOREIGN KEY (`id_abono`) REFERENCES `abonos_credito` (`id_abono`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_mp_contrato` FOREIGN KEY (`id_contrato`) REFERENCES `contratos_credito` (`id_contrato`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_mp_orden_web` FOREIGN KEY (`id_orden_web`) REFERENCES `web_orders` (`id_orden`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cobros con tarjeta enviados a Mercado Pago Point';

CREATE TABLE IF NOT EXISTS `pagos_mercadopago_eventos` (
  `id_evento` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_pago_mp` int(11) DEFAULT NULL,
  `origen` enum('creacion','consulta','webhook','cancelacion') NOT NULL,
  `mp_order_id` varchar(64) DEFAULT NULL,
  `accion` varchar(40) DEFAULT NULL COMMENT 'action del Webhook (order.processed, order.failed…)',
  `request_id` varchar(80) DEFAULT NULL COMMENT 'Encabezado x-request-id del Webhook',
  `firma_valida` tinyint(1) DEFAULT NULL,
  `http_codigo` int(11) DEFAULT NULL,
  `mp_estado` varchar(30) DEFAULT NULL,
  `mp_estado_detalle` varchar(40) DEFAULT NULL,
  `detalle` varchar(500) DEFAULT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_evento`),
  KEY `idx_eventos_mp_pago` (`id_pago_mp`),
  KEY `idx_eventos_mp_orden` (`mp_order_id`),
  CONSTRAINT `fk_eventos_mp_pago` FOREIGN KEY (`id_pago_mp`) REFERENCES `pagos_mercadopago` (`id_pago_mp`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bitácora de consultas y Webhooks de Mercado Pago';

-- Terminales verificadas con la API el 2026-11-04. Por ahora solo cobra la caja 01 de Manzanillo.
INSERT INTO terminales_point (entorno, id_caja, terminal_id, descripcion)
SELECT 'produccion', c.id_caja, 'NEWLAND_N950__N950NCD500171132', 'Point Smart 2'
  FROM cajas c JOIN sucursales s ON s.id_sucursal = c.id_sucursal
 WHERE s.nombre = 'Manzanillo' AND c.numero_caja = 1
   AND NOT EXISTS (SELECT 1 FROM terminales_point t WHERE t.entorno = 'produccion' AND t.id_caja = c.id_caja);

INSERT INTO terminales_point (entorno, id_caja, terminal_id, descripcion)
SELECT 'prueba', c.id_caja, 'NEWLAND_N950__SBX0000001', 'Terminal virtual de pruebas'
  FROM cajas c JOIN sucursales s ON s.id_sucursal = c.id_sucursal
 WHERE s.nombre = 'Manzanillo' AND c.numero_caja = 1
   AND NOT EXISTS (SELECT 1 FROM terminales_point t WHERE t.entorno = 'prueba' AND t.id_caja = c.id_caja);
