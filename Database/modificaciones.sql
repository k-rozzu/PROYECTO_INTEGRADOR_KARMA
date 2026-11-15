-- KARMA · Sección «Servicios» del Punto de Venta (conceptos de caja: seguros, financiamiento, trámites, impuestos y posventa).
-- Se puede ejecutar varias veces sin riesgo: no borra, no duplica y no cambia lo que ya exista.
--
-- Es para las bases que NO se crearon importando Database/pos_multisede.sql, o que se importaron antes de que ese archivo
-- trajera los conceptos. Sin estas tablas, posCatalogoConceptosCaja() responde disponible = false y la pestaña no aparece.
-- Deja los mismos datos e ids que pos_multisede.sql (categoría 5 y productos 95 a 107), para que todas las bases del equipo coincidan.

SET NAMES utf8mb4;

-- ===== 1. Categoría y productos de servicio (sin inventario: la caja los registra en detalle_ventas) =====
INSERT INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`)
SELECT 5, 'Servicios y Trámites', 'Seguros, trámites vehiculares, impuestos, comisiones y servicios de posventa cobrados en caja'
 WHERE NOT EXISTS (SELECT 1 FROM `categorias` WHERE `nombre_categoria` = 'Servicios y Trámites');

-- Si otro producto ocupa los ids 95 a 107, se mueve después del último id del equipo (109).
-- Sus ventas, inventario y demás relaciones lo siguen solas (ON UPDATE CASCADE).
SET @karma_libre := (SELECT GREATEST(COALESCE(MAX(`id_producto`), 0), 109) FROM `productos`);
UPDATE `productos` SET `id_producto` = (@karma_libre := @karma_libre + 1)
 WHERE `id_producto` BETWEEN 95 AND 107 AND `codigo_barras` NOT LIKE 'KRM-SRV-%'
 ORDER BY `id_producto`;

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 95, c.`id_categoria`, 'KRM-SRV-SEG-AMPLIA', 'Seguro automotriz de cobertura amplia', 'Prima de seguro de cobertura amplia cobrada en caja', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-SEG-AMPLIA');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 96, c.`id_categoria`, 'KRM-SRV-COSEG-VIDA-DES', 'Co seguro de vida y desempleo', 'Prima del seguro de vida y desempleo ligado a un crédito', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-COSEG-VIDA-DES');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 97, c.`id_categoria`, 'KRM-SRV-SEG-LLANTAS', 'Seguro de llantas y rines', 'Plan de protección de llantas y rines', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-SEG-LLANTAS');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 98, c.`id_categoria`, 'KRM-SRV-COMISION-APERTURA', 'Comisión por apertura de crédito', 'Comisión por apertura de un crédito con financiera externa', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-COMISION-APERTURA');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 99, c.`id_categoria`, 'KRM-SRV-GESTORIA-PLACAS', 'Gestoría de placas y alta vehicular', 'Honorarios de gestoría y derechos de alta vehicular', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-GESTORIA-PLACAS');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 100, c.`id_categoria`, 'KRM-SRV-ISAN', 'Impuesto sobre automóviles nuevos (ISAN)', 'ISAN calculado con la tarifa vigente', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-ISAN');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 101, c.`id_categoria`, 'KRM-SRV-TENENCIA-REFRENDO', 'Tenencia / refrendo vehicular', 'Tenencia estatal o refrendo anual de control vehicular', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-TENENCIA-REFRENDO');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 102, c.`id_categoria`, 'KRM-SRV-VERIF-HOLOGRAMA-00', 'Verificación vehicular (holograma 00)', 'Gestión y derechos del holograma 00', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-VERIF-HOLOGRAMA-00');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 103, c.`id_categoria`, 'KRM-SRV-MANT-PREPAGADO', 'Plan de mantenimiento prepagado', 'Paquete de servicios de mantenimiento pagados por adelantado', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-MANT-PREPAGADO');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 104, c.`id_categoria`, 'KRM-SRV-GARANTIA-EXT', 'Garantía extendida', 'Extensión de la garantía KARMA del vehículo', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-GARANTIA-EXT');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 105, c.`id_categoria`, 'KRM-SRV-ACCESORIOS-INST', 'Instalación de accesorios originales', 'Mano de obra de instalación de accesorios originales', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-ACCESORIOS-INST');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 106, c.`id_categoria`, 'KRM-SRV-POLARIZADO', 'Película de seguridad y/o polarizado', 'Instalación de película de seguridad o polarizado', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-POLARIZADO');

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `tipo`)
SELECT 107, c.`id_categoria`, 'KRM-SRV-ORDEN-TALLER', 'Orden de servicio de taller', 'Cobro de una orden de servicio del taller', 0.00, 'servicio'
  FROM `categorias` c
 WHERE c.`nombre_categoria` = 'Servicios y Trámites'
   AND NOT EXISTS (SELECT 1 FROM `productos` p WHERE p.`codigo_barras` = 'KRM-SRV-ORDEN-TALLER');

-- ===== 2. Columnas que usa la venta para ligar el cobro con su concepto =====
ALTER TABLE `ventas` ADD COLUMN IF NOT EXISTS `total_conceptos` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Parte del total que corresponde a conceptos de caja (ventas_conceptos)';
ALTER TABLE `detalle_ventas` ADD COLUMN IF NOT EXISTS `id_venta_concepto` int(11) DEFAULT NULL COMMENT 'Concepto de caja al que pertenece la línea (ventas_conceptos)';
ALTER TABLE `detalle_ventas` ADD KEY IF NOT EXISTS `idx_detalle_venta_concepto` (`id_venta_concepto`);

-- ===== 3. Tablas de los conceptos de caja =====
CREATE TABLE IF NOT EXISTS `conceptos_caja` (
  `id_concepto` int(11) NOT NULL AUTO_INCREMENT,
  `clave` varchar(40) NOT NULL COMMENT 'Identificador estable que usa el código (SEG_AMPLIA, ISAN…)',
  `nombre` varchar(120) NOT NULL COMMENT 'Nombre que se muestra en caja, ticket y PDF',
  `grupo` varchar(60) NOT NULL COMMENT 'Agrupador del selector: Seguros, Financiamiento, Trámites e impuestos, Posventa y taller',
  `descripcion` varchar(500) DEFAULT NULL COMMENT 'Explicación breve para el cajero',
  `modo_calculo` enum('PORCENTAJE','FIJO','PORCENTAJE_MENSUAL','TARIFA','MANO_OBRA') NOT NULL COMMENT 'PORCENTAJE = base × % ; FIJO = cuotas fijas ; PORCENTAJE_MENSUAL = base × % × plazo del crédito ; TARIFA = tramos de conceptos_caja_tarifas ; MANO_OBRA = horas × tarifa + materiales',
  `base_calculo` enum('ninguna','vehiculo','vehiculo_sin_iva','credito','accesorio') NOT NULL DEFAULT 'ninguna' COMMENT 'Sobre qué se aplica el porcentaje o la tarifa (precio con IVA, precio sin IVA, monto del crédito o precio del accesorio)',
  `porcentaje` decimal(9,4) DEFAULT NULL COMMENT 'Porcentaje general (las opciones lo pueden sustituir)',
  `monto_fijo` decimal(12,2) DEFAULT NULL COMMENT 'Cuota fija que causa IVA (en MANO_OBRA es la tarifa por hora)',
  `monto_exento` decimal(12,2) DEFAULT NULL COMMENT 'Cuota fija sin IVA (derechos, impuestos)',
  `monto_minimo` decimal(12,2) DEFAULT NULL COMMENT 'Mínimo de la parte porcentual (solo si el porcentaje es mayor que cero)',
  `monto_maximo` decimal(12,2) DEFAULT NULL COMMENT 'Tope de la parte porcentual (NULL = sin tope)',
  `causa_iva` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 = la parte porcentual y la cuota fija incluyen IVA; 0 = exento',
  `tasa_iva` decimal(5,2) NOT NULL DEFAULT 16.00 COMMENT 'Tasa de IVA incluida en los importes gravados',
  `origenes_vehiculo` varchar(40) NOT NULL DEFAULT '' COMMENT 'Lista separada por comas: ticket, vendido, externo. Vacío = no usa vehículo',
  `vehiculo_obligatorio` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 = no se puede cobrar sin vehículo de referencia',
  `aplica_tipos` varchar(20) NOT NULL DEFAULT 'auto,moto' COMMENT 'Tipos de vehículo permitidos (auto, moto)',
  `origenes_credito` varchar(20) NOT NULL DEFAULT '' COMMENT 'karma = contrato firmado en KARMA; externo = financiera externa. Vacío = no usa crédito',
  `unico_por_vin` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 = solo se cobra una vez por VIN (ISAN, alta de placas, holograma 00)',
  `campo_referencia` varchar(40) DEFAULT NULL COMMENT 'Campo capturado que se guarda como referencia (póliza, folio de OS, placas…)',
  `referencia_unica` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 = la referencia no se puede repetir (folio de OS, número de crédito)',
  `vigencia_meses` int(11) DEFAULT NULL COMMENT 'Vigencia por omisión en meses (las opciones la pueden sustituir)',
  `campos_json` longtext DEFAULT NULL COMMENT 'Campos extra que captura la caja: [{clave, etiqueta, tipo(texto|numero|select|area), opciones, requerido, ayuda}]',
  `id_producto` int(11) DEFAULT NULL COMMENT 'Producto tipo servicio que representa el concepto en detalle_ventas',
  `orden` int(11) NOT NULL DEFAULT 0 COMMENT 'Orden en el selector de la caja',
  `activo` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Interruptor general del concepto',
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Último cambio de parametrización',
  PRIMARY KEY (`id_concepto`),
  UNIQUE KEY `uq_conceptos_clave` (`clave`),
  KEY `idx_conceptos_activo` (`activo`,`orden`),
  KEY `fk_conceptos_productos` (`id_producto`),
  CONSTRAINT `fk_conceptos_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo y parametrización de los conceptos que se cobran en la pantalla de Cajero';

CREATE TABLE IF NOT EXISTS `conceptos_caja_opciones` (
  `id_opcion` int(11) NOT NULL AUTO_INCREMENT,
  `id_concepto` int(11) NOT NULL COMMENT 'Concepto al que pertenece el plan',
  `clave` varchar(40) NOT NULL COMMENT 'Identificador del plan dentro del concepto',
  `descripcion` varchar(150) NOT NULL COMMENT 'Texto del plan en el selector y en el ticket',
  `tipo_vehiculo` enum('todos','auto','moto') NOT NULL DEFAULT 'todos' COMMENT 'Tipo de vehículo para el que se ofrece el plan',
  `porcentaje` decimal(9,4) DEFAULT NULL COMMENT 'Sustituye el porcentaje del concepto (NULL = hereda)',
  `monto_fijo` decimal(12,2) DEFAULT NULL COMMENT 'Sustituye la cuota fija gravada del concepto (NULL = hereda)',
  `monto_exento` decimal(12,2) DEFAULT NULL COMMENT 'Sustituye la cuota exenta del concepto (NULL = hereda)',
  `meses` int(11) DEFAULT NULL COMMENT 'Vigencia del plan en meses (NULL = la del concepto)',
  `orden` int(11) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_opcion`),
  UNIQUE KEY `uq_opcion_concepto` (`id_concepto`,`clave`),
  CONSTRAINT `fk_opciones_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planes, coberturas y paquetes de cada concepto';

CREATE TABLE IF NOT EXISTS `conceptos_caja_sucursal` (
  `id_concepto` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0 = el concepto no se ofrece en esta sucursal',
  PRIMARY KEY (`id_concepto`,`id_sucursal`),
  KEY `fk_concsuc_sucursales` (`id_sucursal`),
  CONSTRAINT `fk_concsuc_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_concsuc_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Disponibilidad de cada concepto por sucursal (sin renglón = disponible)';

CREATE TABLE IF NOT EXISTS `conceptos_caja_tarifas` (
  `id_tarifa` int(11) NOT NULL AUTO_INCREMENT,
  `id_concepto` int(11) NOT NULL COMMENT 'Concepto con modo TARIFA',
  `limite_inferior` decimal(14,2) NOT NULL COMMENT 'Límite inferior del tramo (base sin IVA)',
  `limite_superior` decimal(14,2) DEFAULT NULL COMMENT 'Límite superior del tramo (NULL = en adelante)',
  `cuota_fija` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT 'Cuota fija del tramo',
  `porcentaje_excedente` decimal(7,4) NOT NULL COMMENT '% que se aplica sobre el excedente del límite inferior',
  `ejercicio` int(11) NOT NULL COMMENT 'Año fiscal de la tarifa; la caja usa el ejercicio más reciente que no sea futuro',
  PRIMARY KEY (`id_tarifa`),
  UNIQUE KEY `uq_tarifa_tramo` (`id_concepto`,`ejercicio`,`limite_inferior`),
  CONSTRAINT `fk_tarifas_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tarifas por tramos (ISAN y cualquier impuesto progresivo)';

CREATE TABLE IF NOT EXISTS `ventas_conceptos` (
  `id_venta_concepto` int(11) NOT NULL AUTO_INCREMENT,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-SC-{sucursal}-{id}: folio del concepto cobrado',
  `id_venta` int(11) NOT NULL COMMENT 'Venta (ticket) en la que se cobró',
  `id_concepto` int(11) NOT NULL,
  `id_opcion` int(11) DEFAULT NULL COMMENT 'Plan elegido',
  `id_sucursal` int(11) NOT NULL,
  `id_caja` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL COMMENT 'Cajero que cobró',
  `id_producto_vehiculo` int(11) DEFAULT NULL COMMENT 'Vehículo KARMA de referencia (NULL si es externo o no aplica)',
  `vin` varchar(17) DEFAULT NULL COMMENT 'VIN del vehículo de referencia',
  `vehiculo_origen` enum('ticket','vendido','externo') DEFAULT NULL COMMENT 'De dónde salió el vehículo de referencia',
  `vehiculo_descripcion` varchar(150) DEFAULT NULL COMMENT 'Marca, modelo y año del vehículo de referencia',
  `id_contrato` int(11) DEFAULT NULL COMMENT 'Contrato de crédito KARMA de referencia',
  `credito_origen` enum('karma','externo') DEFAULT NULL,
  `id_producto_accesorio` int(11) DEFAULT NULL COMMENT 'Accesorio instalado (descuenta inventario)',
  `referencia` varchar(80) DEFAULT NULL COMMENT 'Póliza, folio de OS, placas o número de crédito capturado',
  `base_calculo` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT 'Base sobre la que se calculó (precio, precio sin IVA, monto del crédito…)',
  `porcentaje` decimal(9,4) DEFAULT NULL COMMENT 'Porcentaje aplicado',
  `importe_gravado` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Parte que incluye IVA',
  `importe_exento` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Parte sin IVA (derechos e impuestos)',
  `importe_accesorio` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Precio del accesorio incluido en el total',
  `subtotal` decimal(12,2) NOT NULL COMMENT 'Total sin IVA',
  `iva` decimal(12,2) NOT NULL COMMENT 'IVA trasladado',
  `total` decimal(12,2) NOT NULL COMMENT 'Importe cobrado (redondeado al peso)',
  `vigencia_inicio` date DEFAULT NULL,
  `vigencia_fin` date DEFAULT NULL,
  `datos_json` longtext DEFAULT NULL COMMENT 'Campos capturados, plan, tramo de tarifa y desglose completo del cálculo',
  `estado` enum('cobrado','cancelado') NOT NULL DEFAULT 'cobrado',
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_venta_concepto`),
  UNIQUE KEY `uq_ventas_conceptos_folio` (`folio`),
  KEY `idx_vc_venta` (`id_venta`),
  KEY `idx_vc_concepto_vin` (`id_concepto`,`vin`,`estado`),
  KEY `idx_vc_concepto_ref` (`id_concepto`,`referencia`,`estado`),
  KEY `idx_vc_fecha` (`fecha_hora`),
  KEY `fk_vc_opciones` (`id_opcion`),
  KEY `fk_vc_sucursales` (`id_sucursal`),
  KEY `fk_vc_cajas` (`id_caja`),
  KEY `fk_vc_usuarios` (`id_usuario`),
  KEY `fk_vc_vehiculo` (`id_producto_vehiculo`),
  KEY `fk_vc_accesorio` (`id_producto_accesorio`),
  KEY `fk_vc_contratos` (`id_contrato`),
  CONSTRAINT `fk_vc_accesorio` FOREIGN KEY (`id_producto_accesorio`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_cajas` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_contratos` FOREIGN KEY (`id_contrato`) REFERENCES `contratos_credito` (`id_contrato`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_opciones` FOREIGN KEY (`id_opcion`) REFERENCES `conceptos_caja_opciones` (`id_opcion`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_usuarios` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_vehiculo` FOREIGN KEY (`id_producto_vehiculo`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_vc_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de cobro y desglose de los conceptos de caja';

-- ===== 4. Catálogo, planes y tarifas =====
INSERT INTO `conceptos_caja` (`id_concepto`, `clave`, `nombre`, `grupo`, `descripcion`, `modo_calculo`, `base_calculo`, `porcentaje`, `monto_fijo`, `monto_exento`, `monto_minimo`, `monto_maximo`, `causa_iva`, `tasa_iva`, `origenes_vehiculo`, `vehiculo_obligatorio`, `aplica_tipos`, `origenes_credito`, `unico_por_vin`, `campo_referencia`, `referencia_unica`, `vigencia_meses`, `campos_json`, `id_producto`, `orden`, `activo`, `fecha_actualizacion`) VALUES
(1, 'SEG_AMPLIA', 'Seguro automotriz de cobertura amplia', 'Seguros', 'Prima de contado sobre el valor del vehículo (misma tasa del 3 % del módulo de crédito). Elige la vigencia.', 'PORCENTAJE', 'vehiculo', 3.0000, NULL, NULL, 4500.00, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, 'poliza', 0, 12, '[{\"clave\":\"aseguradora\",\"etiqueta\":\"Aseguradora\",\"tipo\":\"select\",\"opciones\":[\"Qualitas\",\"GNP Seguros\",\"AXA Seguros\",\"HDI Seguros\",\"Chubb\"],\"requerido\":true},{\"clave\":\"uso\",\"etiqueta\":\"Uso del vehículo\",\"tipo\":\"select\",\"opciones\":[\"Particular\",\"Comercial\"],\"requerido\":true},{\"clave\":\"poliza\",\"etiqueta\":\"Número de póliza\",\"tipo\":\"texto\",\"requerido\":false,\"ayuda\":\"Si la aseguradora aún no emite la póliza, déjalo vacío.\"}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-SEG-AMPLIA'), 10, 1, '2026-10-11 13:09:17'),
(2, 'COSEG_VIDA_DES', 'Co seguro de vida y desempleo', 'Seguros', 'Protege el saldo del crédito por fallecimiento o desempleo. Prima = monto del crédito × tasa mensual × plazo.', 'PORCENTAJE_MENSUAL', 'credito', 0.0900, NULL, NULL, NULL, NULL, 0, 16.00, '', 0, 'auto,moto', 'karma,externo', 0, NULL, 0, NULL, '[{\"clave\":\"beneficiario\",\"etiqueta\":\"Beneficiario\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"parentesco\",\"etiqueta\":\"Parentesco\",\"tipo\":\"select\",\"opciones\":[\"Cónyuge\",\"Hijo(a)\",\"Padre / Madre\",\"Hermano(a)\",\"Otro\"],\"requerido\":true},{\"clave\":\"ocupacion\",\"etiqueta\":\"Ocupación del asegurado\",\"tipo\":\"select\",\"opciones\":[\"Asalariado\",\"Independiente\",\"Empresario\"],\"requerido\":true,\"ayuda\":\"La cobertura de desempleo aplica solo a asalariados.\"}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-COSEG-VIDA-DES'), 20, 1, '2026-10-11 13:09:17'),
(3, 'SEG_LLANTAS', 'Seguro de llantas y rines', 'Seguros', 'Reposición de llantas y rines por daño en camino. Cuota fija según tipo de vehículo y vigencia.', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, 'certificado', 0, 12, '[{\"clave\":\"medida\",\"etiqueta\":\"Medida de llanta\",\"tipo\":\"texto\",\"requerido\":false,\"ayuda\":\"Ej. 255/40 R20\"},{\"clave\":\"certificado\",\"etiqueta\":\"Número de certificado\",\"tipo\":\"texto\",\"requerido\":false}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-SEG-LLANTAS'), 30, 1, '2026-10-11 13:09:17'),
(4, 'COMISION_APERTURA', 'Comisión por apertura de crédito', 'Financiamiento', 'Solo créditos con financiera externa: en los créditos KARMA la comisión ya va incluida en el contrato.', 'PORCENTAJE', 'credito', 2.0000, NULL, NULL, NULL, NULL, 1, 16.00, '', 0, 'auto,moto', 'externo', 0, 'numero_credito', 1, NULL, '[{\"clave\":\"numero_credito\",\"etiqueta\":\"Número de crédito / solicitud\",\"tipo\":\"texto\",\"requerido\":true}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-COMISION-APERTURA'), 40, 1, '2026-10-11 13:09:17'),
(5, 'GESTORIA_PLACAS', 'Gestoría de placas y alta vehicular', 'Trámites e impuestos', 'Honorarios de gestoría (con IVA) más derechos de alta, placas y tarjeta de circulación (sin IVA). Una vez por VIN.', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 1, 'titular', 0, NULL, '[{\"clave\":\"entidad\",\"etiqueta\":\"Entidad de emplacamiento\",\"tipo\":\"select\",\"opciones\":[\"Colima\",\"Jalisco\",\"Michoacán\",\"Otra\"],\"requerido\":true},{\"clave\":\"titular\",\"etiqueta\":\"Titular de la factura\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"comprobante_domicilio\",\"etiqueta\":\"Comprobante de domicilio entregado\",\"tipo\":\"select\",\"opciones\":[\"Sí\",\"No\"],\"requerido\":true}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-GESTORIA-PLACAS'), 50, 1, '2026-10-11 13:09:17'),
(6, 'ISAN', 'Impuesto sobre automóviles nuevos (ISAN)', 'Trámites e impuestos', 'Tarifa por tramos sobre el precio sin IVA de una unidad nueva vendida por KARMA. Una vez por VIN.', 'TARIFA', 'vehiculo_sin_iva', NULL, NULL, NULL, NULL, NULL, 0, 16.00, 'ticket,vendido', 1, 'auto', '', 1, 'factura', 0, NULL, '[{\"clave\":\"factura\",\"etiqueta\":\"Folio de la factura del vehículo\",\"tipo\":\"texto\",\"requerido\":false}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-ISAN'), 60, 1, '2026-10-11 13:09:17'),
(7, 'TENENCIA_REFRENDO', 'Tenencia / refrendo vehicular', 'Trámites e impuestos', 'Refrendo anual de control vehicular (cuota fija) o tenencia estatal (% del valor sin IVA). Sin IVA.', 'PORCENTAJE', 'vehiculo_sin_iva', NULL, NULL, NULL, NULL, NULL, 0, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, 'placas', 0, 12, '[{\"clave\":\"ejercicio\",\"etiqueta\":\"Ejercicio fiscal\",\"tipo\":\"numero\",\"requerido\":true,\"predeterminado\":\"anio_actual\"},{\"clave\":\"placas\",\"etiqueta\":\"Placas\",\"tipo\":\"texto\",\"requerido\":false,\"ayuda\":\"Vacío si el vehículo aún no se emplaca.\"}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-TENENCIA-REFRENDO'), 70, 1, '2026-10-11 13:09:17'),
(8, 'VERIF_HOLOGRAMA_00', 'Verificación vehicular (holograma 00)', 'Trámites e impuestos', 'Gestión (con IVA) y derechos del holograma 00 (sin IVA) para unidades nuevas. Una vez por VIN.', 'FIJO', 'ninguna', NULL, 450.00, 780.00, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto', '', 1, 'placas', 0, 24, '[{\"clave\":\"placas\",\"etiqueta\":\"Placas\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"centro\",\"etiqueta\":\"Centro de verificación\",\"tipo\":\"texto\",\"requerido\":false}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-VERIF-HOLOGRAMA-00'), 80, 1, '2026-10-11 13:09:17'),
(9, 'MANT_PREPAGADO', 'Plan de mantenimiento prepagado', 'Posventa y taller', 'Paquete de servicios de mantenimiento en agencia pagados por adelantado.', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, NULL, 0, 36, '[{\"clave\":\"kilometraje\",\"etiqueta\":\"Kilometraje actual\",\"tipo\":\"numero\",\"requerido\":true}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-MANT-PREPAGADO'), 90, 1, '2026-10-11 13:09:17'),
(10, 'GARANTIA_EXT', 'Garantía extendida', 'Posventa y taller', 'Extiende la garantía KARMA de 4 años de una unidad vendida por la agencia; empieza al vencer la garantía vigente.', 'PORCENTAJE', 'vehiculo', NULL, NULL, NULL, 9500.00, NULL, 1, 16.00, 'ticket,vendido', 1, 'auto,moto', '', 0, NULL, 0, NULL, '[{\"clave\":\"kilometraje\",\"etiqueta\":\"Kilometraje actual\",\"tipo\":\"numero\",\"requerido\":true}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-GARANTIA-EXT'), 100, 1, '2026-10-11 13:09:17'),
(11, 'ACCESORIOS_INST', 'Accesorios originales e instalación', 'Posventa y taller', 'Cobra el accesorio original (descuenta inventario) más la mano de obra de instalación como % de su precio.', 'PORCENTAJE', 'accesorio', NULL, NULL, NULL, 600.00, NULL, 1, 16.00, 'ticket,vendido,externo', 0, 'auto,moto', '', 0, NULL, 0, NULL, '[{\"clave\":\"notas\",\"etiqueta\":\"Notas de instalación\",\"tipo\":\"area\",\"requerido\":false}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-ACCESORIOS-INST'), 110, 1, '2026-10-11 13:09:17'),
(12, 'POLARIZADO', 'Película de seguridad y/o polarizado', 'Posventa y taller', 'Instalación de polarizado, película de seguridad o paquete combinado (solo autos).', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto', '', 0, NULL, 0, NULL, '[{\"clave\":\"tono\",\"etiqueta\":\"Tono / paso de luz\",\"tipo\":\"select\",\"opciones\":[\"5%\",\"20%\",\"35%\",\"50%\",\"70% (parabrisas)\"],\"requerido\":true},{\"clave\":\"marca_pelicula\",\"etiqueta\":\"Marca de la película\",\"tipo\":\"select\",\"opciones\":[\"3M\",\"LLumar\",\"SunTek\"],\"requerido\":true}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-POLARIZADO'), 120, 1, '2026-10-11 13:09:17'),
(13, 'ORDEN_TALLER', 'Orden de servicio de taller', 'Posventa y taller', 'Mano de obra (horas × tarifa por hora) más refacciones y materiales de la orden. El folio de OS no se repite.', 'MANO_OBRA', 'ninguna', NULL, 1150.00, NULL, NULL, NULL, 1, 16.00, 'vendido,externo', 1, 'auto,moto', '', 0, 'folio_os', 1, NULL, '[{\"clave\":\"folio_os\",\"etiqueta\":\"Folio de la orden de servicio\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"kilometraje\",\"etiqueta\":\"Kilometraje de recepción\",\"tipo\":\"numero\",\"requerido\":true},{\"clave\":\"tecnico\",\"etiqueta\":\"Técnico responsable\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"horas\",\"etiqueta\":\"Horas de mano de obra\",\"tipo\":\"numero\",\"requerido\":true},{\"clave\":\"materiales\",\"etiqueta\":\"Refacciones y materiales ($, IVA incluido)\",\"tipo\":\"numero\",\"requerido\":false},{\"clave\":\"trabajo\",\"etiqueta\":\"Trabajos realizados\",\"tipo\":\"area\",\"requerido\":true}]', (SELECT `id_producto` FROM `productos` WHERE `codigo_barras` = 'KRM-SRV-ORDEN-TALLER'), 130, 1, '2026-10-11 13:09:17')
ON DUPLICATE KEY UPDATE `id_concepto` = `conceptos_caja`.`id_concepto`;

INSERT INTO `conceptos_caja_opciones` (`id_opcion`, `id_concepto`, `clave`, `descripcion`, `tipo_vehiculo`, `porcentaje`, `monto_fijo`, `monto_exento`, `meses`, `orden`, `activo`) VALUES
(1, 1, 'ANUAL', 'Anual (12 meses)', 'todos', 3.0000, NULL, NULL, 12, 1, 1),
(2, 1, 'BIANUAL', 'Multianual 24 meses', 'todos', 5.7500, NULL, NULL, 24, 2, 1),
(3, 1, 'TRIANUAL', 'Multianual 36 meses', 'todos', 8.2500, NULL, NULL, 36, 3, 1),
(4, 3, 'AUTO_12', 'Auto · 12 meses', 'auto', NULL, 6900.00, NULL, 12, 1, 1),
(5, 3, 'AUTO_24', 'Auto · 24 meses', 'auto', NULL, 11900.00, NULL, 24, 2, 1),
(6, 3, 'AUTO_36', 'Auto · 36 meses', 'auto', NULL, 15900.00, NULL, 36, 3, 1),
(7, 3, 'MOTO_12', 'Moto · 12 meses', 'moto', NULL, 3200.00, NULL, 12, 4, 1),
(8, 3, 'MOTO_24', 'Moto · 24 meses', 'moto', NULL, 5600.00, NULL, 24, 5, 1),
(9, 5, 'ALTA_AUTO', 'Alta de auto: placas, tarjeta y engomado', 'auto', NULL, 3500.00, 2850.00, NULL, 1, 1),
(10, 5, 'ALTA_MOTO', 'Alta de moto: placa y tarjeta de circulación', 'moto', NULL, 1900.00, 1250.00, NULL, 2, 1),
(11, 7, 'REFRENDO_AUTO', 'Refrendo anual · auto', 'auto', 0.0000, NULL, 1050.00, 12, 1, 1),
(12, 7, 'REFRENDO_MOTO', 'Refrendo anual · moto', 'moto', 0.0000, NULL, 650.00, 12, 2, 1),
(13, 7, 'TENENCIA', 'Tenencia estatal (3 % del valor sin IVA)', 'todos', 3.0000, NULL, NULL, 12, 3, 1),
(14, 9, 'AUTO_3', 'Auto · 3 servicios (36 meses)', 'auto', NULL, 24900.00, NULL, 36, 1, 1),
(15, 9, 'AUTO_5', 'Auto · 5 servicios (60 meses)', 'auto', NULL, 39900.00, NULL, 60, 2, 1),
(16, 9, 'MOTO_3', 'Moto · 3 servicios (36 meses)', 'moto', NULL, 11900.00, NULL, 36, 3, 1),
(17, 9, 'MOTO_5', 'Moto · 5 servicios (60 meses)', 'moto', NULL, 18900.00, NULL, 60, 4, 1),
(18, 10, 'EXT_12', '+12 meses (2.5 %)', 'todos', 2.5000, NULL, NULL, 12, 1, 1),
(19, 10, 'EXT_24', '+24 meses (4.5 %)', 'todos', 4.5000, NULL, NULL, 24, 2, 1),
(20, 10, 'EXT_36', '+36 meses (6 %)', 'todos', 6.0000, NULL, NULL, 36, 3, 1),
(21, 11, 'ESTANDAR', 'Instalación estándar (12 %)', 'todos', 12.0000, NULL, NULL, NULL, 1, 1),
(22, 11, 'ESPECIALIZADA', 'Instalación especializada: eléctrica o estructural (20 %)', 'todos', 20.0000, NULL, NULL, NULL, 2, 1),
(23, 11, 'SIN_INSTALACION', 'Solo accesorio, sin instalación', 'todos', 0.0000, NULL, NULL, NULL, 3, 1),
(24, 12, 'POLARIZADO', 'Polarizado completo', 'auto', NULL, 4900.00, NULL, NULL, 1, 1),
(25, 12, 'SEGURIDAD', 'Película de seguridad completa', 'auto', NULL, 12900.00, NULL, NULL, 2, 1),
(26, 12, 'PAQUETE', 'Paquete: película de seguridad + polarizado', 'auto', NULL, 15900.00, NULL, NULL, 3, 1),
(27, 12, 'PARABRISAS', 'Parabrisas antirreflejante', 'auto', NULL, 3200.00, NULL, NULL, 4, 1)
ON DUPLICATE KEY UPDATE `id_opcion` = `conceptos_caja_opciones`.`id_opcion`;

INSERT INTO `conceptos_caja_tarifas` (`id_tarifa`, `id_concepto`, `limite_inferior`, `limite_superior`, `cuota_fija`, `porcentaje_excedente`, `ejercicio`) VALUES
(1, 6, 0.01, 323893.68, 0.00, 2.0000, 2026),
(2, 6, 323893.69, 388672.38, 6477.85, 5.0000, 2026),
(3, 6, 388672.39, 453451.18, 9716.79, 10.0000, 2026),
(4, 6, 453451.19, 582999.86, 16194.67, 15.0000, 2026),
(5, 6, 582999.87, NULL, 35626.97, 17.0000, 2026)
ON DUPLICATE KEY UPDATE `id_tarifa` = `conceptos_caja_tarifas`.`id_tarifa`;

-- ===== 5. Vista de consulta de lo cobrado =====
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_conceptos_cobrados` AS SELECT `vc`.`id_venta_concepto` AS `id_venta_concepto`, `vc`.`folio` AS `folio`, `vc`.`fecha_hora` AS `fecha_hora`, `s`.`nombre` AS `sucursal`, `vc`.`id_caja` AS `id_caja`, `u`.`nombre` AS `cajero`, `c`.`clave` AS `clave`, `c`.`nombre` AS `concepto`, `c`.`grupo` AS `grupo`, `o`.`descripcion` AS `plan`, `vc`.`id_venta` AS `id_venta`, concat('KRM-',lpad(`vc`.`id_sucursal`,2,'0'),'-',lpad(`vc`.`id_venta`,6,'0')) AS `folio_venta`, `vc`.`vin` AS `vin`, `vc`.`vehiculo_descripcion` AS `vehiculo_descripcion`, `vc`.`referencia` AS `referencia`, `vc`.`base_calculo` AS `base_calculo`, `vc`.`porcentaje` AS `porcentaje`, `vc`.`importe_gravado` AS `importe_gravado`, `vc`.`importe_exento` AS `importe_exento`, `vc`.`importe_accesorio` AS `importe_accesorio`, `vc`.`subtotal` AS `subtotal`, `vc`.`iva` AS `iva`, `vc`.`total` AS `total`, `vc`.`vigencia_inicio` AS `vigencia_inicio`, `vc`.`vigencia_fin` AS `vigencia_fin`, `vc`.`estado` AS `estado` FROM ((((`ventas_conceptos` `vc` join `conceptos_caja` `c` on(`c`.`id_concepto` = `vc`.`id_concepto`)) join `sucursales` `s` on(`s`.`id_sucursal` = `vc`.`id_sucursal`)) join `usuarios` `u` on(`u`.`id_usuario` = `vc`.`id_usuario`)) left join `conceptos_caja_opciones` `o` on(`o`.`id_opcion` = `vc`.`id_opcion`)) ;
