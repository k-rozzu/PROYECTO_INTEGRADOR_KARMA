-- KARMA · Autorización de empleado (gafete QR o código manual) para acciones sensibles del Punto de Venta.
-- Crea SOLO la tabla de auditoría. No modifica ninguna tabla existente y se puede ejecutar varias veces sin riesgo.
-- Documentación: docs/AUTORIZACION_EMPLEADO.md
--
-- Cada renglón es un evento:
--   etapa = 'autorizacion' -> alguien escaneó/escribió un código (resultado autorizado o denegado).
--                             Si se autorizó y después se usó, fecha_uso y operacion dicen en qué endpoint y cuándo.
--   etapa = 'operacion'    -> alguien intentó ejecutar una acción protegida SIN una autorización válida (siempre denegado).
-- Solo se guarda el texto del código (ej. EMP-0001): nunca imágenes, video ni cuadros de la cámara.
-- Sin llaves foráneas a propósito: la bitácora debe conservarse aunque después se edite o elimine un usuario.

CREATE TABLE IF NOT EXISTS `autorizaciones_empleado` (
  `id_autorizacion` int(11) NOT NULL AUTO_INCREMENT,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'Momento del intento',
  `etapa` enum('autorizacion','operacion') NOT NULL DEFAULT 'autorizacion' COMMENT 'autorizacion = código recibido; operacion = intento de ejecutar sin autorización válida',
  `accion` varchar(20) NOT NULL COMMENT 'VENTA, CREDITO, GARANTIA u ORDEN_WEB',
  `referencia` int(11) DEFAULT NULL COMMENT 'Ticket (venta/crédito), id_garantia o id_orden al que quedó ligada',
  `codigo_empleado` varchar(20) DEFAULT NULL COMMENT 'Texto leído del QR o escrito a mano',
  `metodo` enum('qr','manual') DEFAULT NULL COMMENT 'Cómo se obtuvo el código (informativo: ambos pasan por la misma validación)',
  `id_usuario_sesion` int(11) DEFAULT NULL COMMENT 'Usuario con la sesión del POS abierta',
  `id_usuario_empleado` int(11) DEFAULT NULL COMMENT 'Usuario al que pertenece el código (si existe)',
  `id_sucursal` int(11) DEFAULT NULL,
  `resultado` enum('autorizado','denegado') NOT NULL,
  `motivo` varchar(120) DEFAULT NULL COMMENT 'Motivo interno del rechazo (no se muestra al usuario)',
  `operacion` varchar(40) DEFAULT NULL COMMENT 'Endpoint de api.php que usó (o intentó usar) la autorización',
  `fecha_uso` datetime DEFAULT NULL COMMENT 'Cuándo se consumió la autorización (es de un solo uso)',
  PRIMARY KEY (`id_autorizacion`),
  KEY `idx_autorizaciones_fecha` (`fecha_hora`),
  KEY `idx_autorizaciones_sesion` (`id_usuario_sesion`),
  KEY `idx_autorizaciones_empleado` (`id_usuario_empleado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Auditoría de autorizaciones de empleado (gafete QR / código) del Punto de Venta';
