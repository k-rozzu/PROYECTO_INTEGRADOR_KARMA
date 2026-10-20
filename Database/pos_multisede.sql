-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 11-10-2026 a las 22:25:42
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `pos_multisede`
--

DELIMITER $$
--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_abrev_marca` (`p_marca` VARCHAR(80)) RETURNS VARCHAR(10) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci DETERMINISTIC BEGIN
    -- Normaliza la marca a mayúsculas y sin espacios
    DECLARE v_marca VARCHAR(80) DEFAULT UPPER(TRIM(COALESCE(p_marca, '')));
    -- Marcas conocidas del catálogo
    IF v_marca = 'AUDI' THEN RETURN 'AUDI'; END IF;
    IF v_marca = 'PORSCHE' THEN RETURN 'POR'; END IF;
    IF v_marca = 'DUCATI' THEN RETURN 'DUC'; END IF;
    -- Marca nueva: primeras 4 letras (o GEN si no trae marca)
    IF v_marca = '' THEN RETURN 'GEN'; END IF;
    RETURN LEFT(REGEXP_REPLACE(v_marca, '[^A-Z]', ''), 4);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `karma_armar_vin` (`p_marca` VARCHAR(80), `p_anio` INT, `p_serie` INT) RETURNS VARCHAR(17) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci DETERMINISTIC BEGIN
    RETURN CONCAT(karma_wmi_marca(p_marca), 'ZZZ', 'ZZ', '0', karma_letra_anio_vin(p_anio), 'S', LPAD(p_serie, 6, '0'));
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `karma_generar_codigo_barras` (`p_marca` VARCHAR(80), `p_tipo` VARCHAR(30)) RETURNS VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci READS SQL DATA BEGIN
    DECLARE v_prefijo VARCHAR(40);
    DECLARE v_siguiente INT;
    -- Vehículos: KRM-CAT-{MARCA}- ; refacciones: KRM-CAT-REF-{MARCA}-
    SET v_prefijo = IF(p_tipo = 'refaccion',
                       CONCAT('KRM-CAT-REF-', karma_abrev_marca(p_marca), '-'),
                       CONCAT('KRM-CAT-', karma_abrev_marca(p_marca), '-'));
    -- Busca el número más alto que ya existe con ese prefijo y le suma 1
    SELECT COALESCE(MAX(CAST(SUBSTRING(codigo_barras, CHAR_LENGTH(v_prefijo) + 1) AS UNSIGNED)), 0) + 1
      INTO v_siguiente
      FROM productos
     WHERE codigo_barras REGEXP CONCAT('^', v_prefijo, '[0-9]+$');
    -- Número con al menos 2 dígitos (01, 02 … 99, 100)
    RETURN CONCAT(v_prefijo, IF(v_siguiente < 10, CONCAT('0', v_siguiente), v_siguiente));
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `karma_generar_vin` (`p_marca` VARCHAR(80), `p_anio` INT) RETURNS VARCHAR(17) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci READS SQL DATA BEGIN
    DECLARE v_serie INT;
    -- Última serie usada (los 6 dígitos finales del VIN); si no hay ninguna empieza en 100000
    SELECT COALESCE(MAX(CAST(RIGHT(vin, 6) AS UNSIGNED)), 100000)
      INTO v_serie
      FROM productos
     WHERE vin IS NOT NULL AND vin <> '';
    RETURN karma_armar_vin(p_marca, p_anio, v_serie + 37);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `karma_letra_anio_vin` (`p_anio` INT) RETURNS CHAR(1) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci DETERMINISTIC BEGIN
    -- Ciclo oficial de 30 años sin I, O, Q, U, Z ni 0 (empieza en 2010 = A)
    DECLARE v_anio INT DEFAULT COALESCE(p_anio, YEAR(CURDATE()));
    RETURN SUBSTRING('ABCDEFGHJKLMNPRSTVWXY123456789', MOD(MOD(v_anio - 2010, 30) + 30, 30) + 1, 1);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `karma_wmi_marca` (`p_marca` VARCHAR(80)) RETURNS CHAR(3) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci DETERMINISTIC BEGIN
    -- Normaliza la marca para compararla
    DECLARE v_marca VARCHAR(80) DEFAULT UPPER(TRIM(COALESCE(p_marca, '')));
    IF v_marca = 'AUDI' THEN RETURN 'WAU'; END IF;
    IF v_marca = 'PORSCHE' THEN RETURN 'WP0'; END IF;
    IF v_marca = 'DUCATI' THEN RETURN 'ZDM'; END IF;
    -- Marca nueva: se usa el prefijo de la agencia
    RETURN 'KRM';
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `abonos_credito`
--

CREATE TABLE `abonos_credito` (
  `id_abono` int(11) NOT NULL,
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
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Mensualidades de los créditos automotrices cobradas en caja';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `autorizaciones_empleado`
--

CREATE TABLE `autorizaciones_empleado` (
  `id_autorizacion` int(11) NOT NULL,
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
  `fecha_uso` datetime DEFAULT NULL COMMENT 'Cuándo se consumió la autorización (es de un solo uso)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Auditoría de autorizaciones de empleado (gafete QR / código) del Punto de Venta';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajas`
--

CREATE TABLE `cajas` (
  `id_caja` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL,
  `numero_caja` int(11) NOT NULL,
  `estado` enum('abierta','cerrada','mantenimiento') NOT NULL DEFAULT 'cerrada'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cajas`
--

INSERT INTO `cajas` (`id_caja`, `id_sucursal`, `numero_caja`, `estado`) VALUES
(1, 1, 1, 'abierta');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `catalogo_opciones`
--

CREATE TABLE `catalogo_opciones` (
  `id_opcion` int(11) NOT NULL,
  `clave` varchar(60) NOT NULL,
  `marca` varchar(80) DEFAULT NULL,
  `tipo_vehiculo` enum('auto','moto') DEFAULT NULL,
  `grupo` enum('color','version','equipamiento') NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `precio` decimal(12,2) NOT NULL DEFAULT 0.00,
  `color_hex` varchar(20) DEFAULT NULL,
  `orden` int(11) NOT NULL DEFAULT 0,
  `activa` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `catalogo_opciones`
--

INSERT INTO `catalogo_opciones` (`id_opcion`, `clave`, `marca`, `tipo_vehiculo`, `grupo`, `nombre`, `descripcion`, `precio`, `color_hex`, `orden`, `activa`) VALUES
(1, 'audi-color-blanco', 'Audi', 'auto', 'color', 'Blanco Glaciar', 'Metálico', 0.00, '#F2F2EF', 1, 1),
(2, 'audi-color-negro', 'Audi', 'auto', 'color', 'Negro Mythos', 'Metálico', 0.00, '#101012', 2, 1),
(3, 'audi-color-nardo', 'Audi', 'auto', 'color', 'Gris Nardo', 'Sólido', 0.00, '#7A7D80', 3, 1),
(4, 'audi-color-azul', 'Audi', 'auto', 'color', 'Azul Ultra', 'Metálico', 0.00, '#1F3B66', 4, 1),
(5, 'audi-color-rojo', 'Audi', 'auto', 'color', 'Rojo Tango', 'Metálico', 0.00, '#8C1D2B', 5, 1),
(6, 'audi-color-verde', 'Audi', 'auto', 'color', 'Verde Distrito', 'Metálico', 12000.00, '#3F4A3C', 6, 1),
(7, 'audi-version-base', 'Audi', 'auto', 'version', 'Base', 'Equipamiento de serie', 0.00, NULL, 1, 1),
(8, 'audi-version-sline', 'Audi', 'auto', 'version', 'S line', 'Paquete exterior e interior S line con suspensión deportiva', 65000.00, NULL, 2, 1),
(9, 'audi-version-black', 'Audi', 'auto', 'version', 'Black Edition', 'Detalles en negro brillante, rines de 20\" y techo panorámico', 95000.00, NULL, 3, 1),
(10, 'audi-eq-techo', 'Audi', 'auto', 'equipamiento', 'Techo panorámico', 'Techo de cristal corredizo con cortinilla eléctrica', 32000.00, NULL, 1, 1),
(11, 'audi-eq-audio', 'Audi', 'auto', 'equipamiento', 'Sistema de audio premium', '16 bocinas con sonido envolvente 3D', 28000.00, NULL, 2, 1),
(12, 'audi-eq-hud', 'Audi', 'auto', 'equipamiento', 'Head-up display', 'Información de manejo proyectada en el parabrisas', 22000.00, NULL, 3, 1),
(13, 'audi-eq-tour', 'Audi', 'auto', 'equipamiento', 'Asistentes de conducción Tour', 'Crucero adaptativo, carril activo y asistente de tráfico', 35000.00, NULL, 4, 1),
(14, 'audi-eq-rines', 'Audi', 'auto', 'equipamiento', 'Rines de 21\"', 'Rines de aleación de diseño exclusivo', 41000.00, NULL, 5, 1),
(15, 'porsche-color-blanco', 'Porsche', 'auto', 'color', 'Blanco Carrara', 'Metálico', 0.00, '#EDEDEA', 1, 1),
(16, 'porsche-color-negro', 'Porsche', 'auto', 'color', 'Negro Jeweled', 'Metálico', 0.00, '#141414', 2, 1),
(17, 'porsche-color-gt', 'Porsche', 'auto', 'color', 'Gris GT Plata', 'Metálico', 0.00, '#9EA0A1', 3, 1),
(18, 'porsche-color-azul', 'Porsche', 'auto', 'color', 'Azul Gentian', 'Metálico', 0.00, '#1B3A6B', 4, 1),
(19, 'porsche-color-rojo', 'Porsche', 'auto', 'color', 'Rojo Carmín', 'Sólido', 0.00, '#9E1B2E', 5, 1),
(20, 'porsche-color-verde', 'Porsche', 'auto', 'color', 'Verde Python', 'Color especial', 48000.00, '#5C7D3A', 6, 1),
(21, 'porsche-color-amarillo', 'Porsche', 'auto', 'color', 'Amarillo Racing', 'Color especial', 48000.00, '#F2C230', 7, 1),
(22, 'porsche-version-base', 'Porsche', 'auto', 'version', 'Base', 'Equipamiento de serie', 0.00, NULL, 1, 1),
(23, 'porsche-version-chrono', 'Porsche', 'auto', 'version', 'Paquete Sport Chrono', 'Cronómetro, modo Sport Plus y Launch Control', 78000.00, NULL, 2, 1),
(24, 'porsche-version-design', 'Porsche', 'auto', 'version', 'Paquete Sport Design', 'Fascias y faldones deportivos con detalles en negro', 115000.00, NULL, 3, 1),
(25, 'porsche-eq-audio', 'Porsche', 'auto', 'equipamiento', 'Sistema de audio de alta fidelidad', 'Amplificación dedicada y bocinas de alto desempeño', 54000.00, NULL, 1, 1),
(26, 'porsche-eq-asientos', 'Porsche', 'auto', 'equipamiento', 'Asientos deportivos adaptativos', '18 posiciones eléctricas con memoria', 68000.00, NULL, 2, 1),
(27, 'porsche-eq-direccion', 'Porsche', 'auto', 'equipamiento', 'Dirección en el eje trasero', 'Mayor agilidad en curvas y estabilidad a alta velocidad', 72000.00, NULL, 3, 1),
(28, 'porsche-eq-matrix', 'Porsche', 'auto', 'equipamiento', 'Faros LED Matrix con PDLS Plus', 'Iluminación adaptativa con luz de curva', 45000.00, NULL, 4, 1),
(29, 'porsche-eq-pccb', 'Porsche', 'auto', 'equipamiento', 'Frenos cerámicos PCCB', 'Discos de carbono-cerámica con calipers amarillos', 260000.00, NULL, 5, 1),
(30, 'ducati-color-rojo', 'Ducati', 'moto', 'color', 'Rojo Ducati', 'Color de la marca', 0.00, '#9E1B2E', 1, 1),
(31, 'ducati-color-gris', 'Ducati', 'moto', 'color', 'Gris Antracita', 'Mate', 0.00, '#4A4A4A', 2, 1),
(32, 'ducati-color-blanco', 'Ducati', 'moto', 'color', 'Blanco Dark', 'Brillante', 0.00, '#E7E7E4', 3, 1),
(33, 'ducati-color-negro', 'Ducati', 'moto', 'color', 'Negro Mate', 'Mate', 0.00, '#1A1A1A', 4, 1),
(34, 'ducati-color-verde', 'Ducati', 'moto', 'color', 'Verde Storm', 'Edición especial', 9500.00, '#4D5845', 5, 1),
(35, 'ducati-version-std', 'Ducati', 'moto', 'version', 'Estándar', 'Equipamiento de serie', 0.00, NULL, 1, 1),
(36, 'ducati-version-perf', 'Ducati', 'moto', 'version', 'Paquete Performance', 'Escape deportivo, asiento racing y piezas de aluminio maquinado', 38000.00, NULL, 2, 1),
(37, 'ducati-eq-punos', 'Ducati', 'moto', 'equipamiento', 'Puños con calefacción', 'Tres niveles de temperatura', 6500.00, NULL, 1, 1),
(38, 'ducati-eq-crucero', 'Ducati', 'moto', 'equipamiento', 'Control de crucero', 'Mandos integrados en el manubrio', 9800.00, NULL, 2, 1),
(39, 'ducati-eq-asiento', 'Ducati', 'moto', 'equipamiento', 'Asiento confort', 'Espuma de doble densidad para viajes largos', 5200.00, NULL, 3, 1),
(40, 'ducati-eq-nav', 'Ducati', 'moto', 'equipamiento', 'Navegación en pantalla TFT', 'Mapas paso a paso conectados al celular', 7900.00, NULL, 4, 1),
(41, 'ducati-eq-alarma', 'Ducati', 'moto', 'equipamiento', 'Alarma antirrobo', 'Inmovilizador con sensor de movimiento', 6200.00, NULL, 5, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES
(1, 'Porsche', 'Vehículos Porsche'),
(2, 'Audi', 'Vehículos Audi'),
(3, 'Ducati', 'Motocicletas Ducati'),
(4, 'Refacciones', 'Refacciones y piezas'),
(5, 'Servicios y Trámites', 'Seguros, trámites vehiculares, impuestos, comisiones y servicios de posventa cobrados en caja');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `citas`
--

CREATE TABLE `citas` (
  `id_cita` int(11) NOT NULL,
  `folio` varchar(20) DEFAULT NULL,
  `tipo` enum('visita','apartado','prueba_manejo','servicio') NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `id_sucursal` int(11) NOT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `id_orden` int(11) DEFAULT NULL,
  `fecha_hora` datetime NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `email` varchar(120) DEFAULT NULL,
  `telefono` varchar(30) DEFAULT NULL,
  `vehiculo_cliente` varchar(150) DEFAULT NULL,
  `vin` varchar(17) DEFAULT NULL,
  `kilometraje` int(11) DEFAULT NULL,
  `tipo_servicio` varchar(80) DEFAULT NULL,
  `comentarios` varchar(1000) DEFAULT NULL,
  `estado` enum('programada','confirmada','completada','cancelada') NOT NULL DEFAULT 'programada',
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `rfc_ine` varchar(80) DEFAULT NULL,
  `celular` varchar(30) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `articulo` varchar(180) DEFAULT NULL,
  `total_adeudo` decimal(12,2) DEFAULT NULL,
  `monto_abono` decimal(12,2) DEFAULT NULL,
  `enganche` decimal(12,2) DEFAULT NULL,
  `abonos_pagados` int(11) NOT NULL DEFAULT 0,
  `abonos_totales` int(11) NOT NULL DEFAULT 0,
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `direccion` varchar(255) DEFAULT NULL,
  `identificacion_tipo` varchar(30) DEFAULT NULL,
  `identificacion_numero` varchar(40) DEFAULT NULL COMMENT 'Folio o número de la identificación oficial',
  `nombres` varchar(80) DEFAULT NULL,
  `apellidos` varchar(100) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `ciudad` varchar(100) DEFAULT NULL,
  `entidad_federativa` varchar(80) DEFAULT NULL,
  `codigo_postal` varchar(10) DEFAULT NULL,
  `id_sucursal_preferida` int(11) DEFAULT NULL,
  `marca_interes` varchar(80) DEFAULT NULL,
  `notif_email` tinyint(1) NOT NULL DEFAULT 1,
  `notif_sms` tinyint(1) NOT NULL DEFAULT 0,
  `notif_promociones` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_registro` datetime DEFAULT NULL,
  `ultimo_acceso` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `favoritos_catalogo`
--

CREATE TABLE `favoritos_catalogo` (
  `id_cliente` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `conceptos_caja`
--

CREATE TABLE `conceptos_caja` (
  `id_concepto` int(11) NOT NULL,
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
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Último cambio de parametrización'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo y parametrización de los conceptos que se cobran en la pantalla de Cajero';

--
-- Volcado de datos para la tabla `conceptos_caja`
--

INSERT INTO `conceptos_caja` (`id_concepto`, `clave`, `nombre`, `grupo`, `descripcion`, `modo_calculo`, `base_calculo`, `porcentaje`, `monto_fijo`, `monto_exento`, `monto_minimo`, `monto_maximo`, `causa_iva`, `tasa_iva`, `origenes_vehiculo`, `vehiculo_obligatorio`, `aplica_tipos`, `origenes_credito`, `unico_por_vin`, `campo_referencia`, `referencia_unica`, `vigencia_meses`, `campos_json`, `id_producto`, `orden`, `activo`, `fecha_actualizacion`) VALUES
(1, 'SEG_AMPLIA', 'Seguro automotriz de cobertura amplia', 'Seguros', 'Prima de contado sobre el valor del vehículo (misma tasa del 3 % del módulo de crédito). Elige la vigencia.', 'PORCENTAJE', 'vehiculo', 3.0000, NULL, NULL, 4500.00, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, 'poliza', 0, 12, '[{\"clave\":\"aseguradora\",\"etiqueta\":\"Aseguradora\",\"tipo\":\"select\",\"opciones\":[\"Qualitas\",\"GNP Seguros\",\"AXA Seguros\",\"HDI Seguros\",\"Chubb\"],\"requerido\":true},{\"clave\":\"uso\",\"etiqueta\":\"Uso del vehículo\",\"tipo\":\"select\",\"opciones\":[\"Particular\",\"Comercial\"],\"requerido\":true},{\"clave\":\"poliza\",\"etiqueta\":\"Número de póliza\",\"tipo\":\"texto\",\"requerido\":false,\"ayuda\":\"Si la aseguradora aún no emite la póliza, déjalo vacío.\"}]', 95, 10, 1, '2026-10-11 13:09:17'),
(2, 'COSEG_VIDA_DES', 'Co seguro de vida y desempleo', 'Seguros', 'Protege el saldo del crédito por fallecimiento o desempleo. Prima = monto del crédito × tasa mensual × plazo.', 'PORCENTAJE_MENSUAL', 'credito', 0.0900, NULL, NULL, NULL, NULL, 0, 16.00, '', 0, 'auto,moto', 'karma,externo', 0, NULL, 0, NULL, '[{\"clave\":\"beneficiario\",\"etiqueta\":\"Beneficiario\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"parentesco\",\"etiqueta\":\"Parentesco\",\"tipo\":\"select\",\"opciones\":[\"Cónyuge\",\"Hijo(a)\",\"Padre / Madre\",\"Hermano(a)\",\"Otro\"],\"requerido\":true},{\"clave\":\"ocupacion\",\"etiqueta\":\"Ocupación del asegurado\",\"tipo\":\"select\",\"opciones\":[\"Asalariado\",\"Independiente\",\"Empresario\"],\"requerido\":true,\"ayuda\":\"La cobertura de desempleo aplica solo a asalariados.\"}]', 96, 20, 1, '2026-10-11 13:09:17'),
(3, 'SEG_LLANTAS', 'Seguro de llantas y rines', 'Seguros', 'Reposición de llantas y rines por daño en camino. Cuota fija según tipo de vehículo y vigencia.', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, 'certificado', 0, 12, '[{\"clave\":\"medida\",\"etiqueta\":\"Medida de llanta\",\"tipo\":\"texto\",\"requerido\":false,\"ayuda\":\"Ej. 255/40 R20\"},{\"clave\":\"certificado\",\"etiqueta\":\"Número de certificado\",\"tipo\":\"texto\",\"requerido\":false}]', 97, 30, 1, '2026-10-11 13:09:17'),
(4, 'COMISION_APERTURA', 'Comisión por apertura de crédito', 'Financiamiento', 'Solo créditos con financiera externa: en los créditos KARMA la comisión ya va incluida en el contrato.', 'PORCENTAJE', 'credito', 2.0000, NULL, NULL, NULL, NULL, 1, 16.00, '', 0, 'auto,moto', 'externo', 0, 'numero_credito', 1, NULL, '[{\"clave\":\"numero_credito\",\"etiqueta\":\"Número de crédito / solicitud\",\"tipo\":\"texto\",\"requerido\":true}]', 98, 40, 1, '2026-10-11 13:09:17'),
(5, 'GESTORIA_PLACAS', 'Gestoría de placas y alta vehicular', 'Trámites e impuestos', 'Honorarios de gestoría (con IVA) más derechos de alta, placas y tarjeta de circulación (sin IVA). Una vez por VIN.', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 1, 'titular', 0, NULL, '[{\"clave\":\"entidad\",\"etiqueta\":\"Entidad de emplacamiento\",\"tipo\":\"select\",\"opciones\":[\"Colima\",\"Jalisco\",\"Michoacán\",\"Otra\"],\"requerido\":true},{\"clave\":\"titular\",\"etiqueta\":\"Titular de la factura\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"comprobante_domicilio\",\"etiqueta\":\"Comprobante de domicilio entregado\",\"tipo\":\"select\",\"opciones\":[\"Sí\",\"No\"],\"requerido\":true}]', 99, 50, 1, '2026-10-11 13:09:17'),
(6, 'ISAN', 'Impuesto sobre automóviles nuevos (ISAN)', 'Trámites e impuestos', 'Tarifa por tramos sobre el precio sin IVA de una unidad nueva vendida por KARMA. Una vez por VIN.', 'TARIFA', 'vehiculo_sin_iva', NULL, NULL, NULL, NULL, NULL, 0, 16.00, 'ticket,vendido', 1, 'auto', '', 1, 'factura', 0, NULL, '[{\"clave\":\"factura\",\"etiqueta\":\"Folio de la factura del vehículo\",\"tipo\":\"texto\",\"requerido\":false}]', 100, 60, 1, '2026-10-11 13:09:17'),
(7, 'TENENCIA_REFRENDO', 'Tenencia / refrendo vehicular', 'Trámites e impuestos', 'Refrendo anual de control vehicular (cuota fija) o tenencia estatal (% del valor sin IVA). Sin IVA.', 'PORCENTAJE', 'vehiculo_sin_iva', NULL, NULL, NULL, NULL, NULL, 0, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, 'placas', 0, 12, '[{\"clave\":\"ejercicio\",\"etiqueta\":\"Ejercicio fiscal\",\"tipo\":\"numero\",\"requerido\":true,\"predeterminado\":\"anio_actual\"},{\"clave\":\"placas\",\"etiqueta\":\"Placas\",\"tipo\":\"texto\",\"requerido\":false,\"ayuda\":\"Vacío si el vehículo aún no se emplaca.\"}]', 101, 70, 1, '2026-10-11 13:09:17'),
(8, 'VERIF_HOLOGRAMA_00', 'Verificación vehicular (holograma 00)', 'Trámites e impuestos', 'Gestión (con IVA) y derechos del holograma 00 (sin IVA) para unidades nuevas. Una vez por VIN.', 'FIJO', 'ninguna', NULL, 450.00, 780.00, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto', '', 1, 'placas', 0, 24, '[{\"clave\":\"placas\",\"etiqueta\":\"Placas\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"centro\",\"etiqueta\":\"Centro de verificación\",\"tipo\":\"texto\",\"requerido\":false}]', 102, 80, 1, '2026-10-11 13:09:17'),
(9, 'MANT_PREPAGADO', 'Plan de mantenimiento prepagado', 'Posventa y taller', 'Paquete de servicios de mantenimiento en agencia pagados por adelantado.', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto,moto', '', 0, NULL, 0, 36, '[{\"clave\":\"kilometraje\",\"etiqueta\":\"Kilometraje actual\",\"tipo\":\"numero\",\"requerido\":true}]', 103, 90, 1, '2026-10-11 13:09:17'),
(10, 'GARANTIA_EXT', 'Garantía extendida', 'Posventa y taller', 'Extiende la garantía KARMA de 4 años de una unidad vendida por la agencia; empieza al vencer la garantía vigente.', 'PORCENTAJE', 'vehiculo', NULL, NULL, NULL, 9500.00, NULL, 1, 16.00, 'ticket,vendido', 1, 'auto,moto', '', 0, NULL, 0, NULL, '[{\"clave\":\"kilometraje\",\"etiqueta\":\"Kilometraje actual\",\"tipo\":\"numero\",\"requerido\":true}]', 104, 100, 1, '2026-10-11 13:09:17'),
(11, 'ACCESORIOS_INST', 'Accesorios originales e instalación', 'Posventa y taller', 'Cobra el accesorio original (descuenta inventario) más la mano de obra de instalación como % de su precio.', 'PORCENTAJE', 'accesorio', NULL, NULL, NULL, 600.00, NULL, 1, 16.00, 'ticket,vendido,externo', 0, 'auto,moto', '', 0, NULL, 0, NULL, '[{\"clave\":\"notas\",\"etiqueta\":\"Notas de instalación\",\"tipo\":\"area\",\"requerido\":false}]', 105, 110, 1, '2026-10-11 13:09:17'),
(12, 'POLARIZADO', 'Película de seguridad y/o polarizado', 'Posventa y taller', 'Instalación de polarizado, película de seguridad o paquete combinado (solo autos).', 'FIJO', 'ninguna', NULL, NULL, NULL, NULL, NULL, 1, 16.00, 'ticket,vendido,externo', 1, 'auto', '', 0, NULL, 0, NULL, '[{\"clave\":\"tono\",\"etiqueta\":\"Tono / paso de luz\",\"tipo\":\"select\",\"opciones\":[\"5%\",\"20%\",\"35%\",\"50%\",\"70% (parabrisas)\"],\"requerido\":true},{\"clave\":\"marca_pelicula\",\"etiqueta\":\"Marca de la película\",\"tipo\":\"select\",\"opciones\":[\"3M\",\"LLumar\",\"SunTek\"],\"requerido\":true}]', 106, 120, 1, '2026-10-11 13:09:17'),
(13, 'ORDEN_TALLER', 'Orden de servicio de taller', 'Posventa y taller', 'Mano de obra (horas × tarifa por hora) más refacciones y materiales de la orden. El folio de OS no se repite.', 'MANO_OBRA', 'ninguna', NULL, 1150.00, NULL, NULL, NULL, 1, 16.00, 'vendido,externo', 1, 'auto,moto', '', 0, 'folio_os', 1, NULL, '[{\"clave\":\"folio_os\",\"etiqueta\":\"Folio de la orden de servicio\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"kilometraje\",\"etiqueta\":\"Kilometraje de recepción\",\"tipo\":\"numero\",\"requerido\":true},{\"clave\":\"tecnico\",\"etiqueta\":\"Técnico responsable\",\"tipo\":\"texto\",\"requerido\":true},{\"clave\":\"horas\",\"etiqueta\":\"Horas de mano de obra\",\"tipo\":\"numero\",\"requerido\":true},{\"clave\":\"materiales\",\"etiqueta\":\"Refacciones y materiales ($, IVA incluido)\",\"tipo\":\"numero\",\"requerido\":false},{\"clave\":\"trabajo\",\"etiqueta\":\"Trabajos realizados\",\"tipo\":\"area\",\"requerido\":true}]', 107, 130, 1, '2026-10-11 13:09:17');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `conceptos_caja_opciones`
--

CREATE TABLE `conceptos_caja_opciones` (
  `id_opcion` int(11) NOT NULL,
  `id_concepto` int(11) NOT NULL COMMENT 'Concepto al que pertenece el plan',
  `clave` varchar(40) NOT NULL COMMENT 'Identificador del plan dentro del concepto',
  `descripcion` varchar(150) NOT NULL COMMENT 'Texto del plan en el selector y en el ticket',
  `tipo_vehiculo` enum('todos','auto','moto') NOT NULL DEFAULT 'todos' COMMENT 'Tipo de vehículo para el que se ofrece el plan',
  `porcentaje` decimal(9,4) DEFAULT NULL COMMENT 'Sustituye el porcentaje del concepto (NULL = hereda)',
  `monto_fijo` decimal(12,2) DEFAULT NULL COMMENT 'Sustituye la cuota fija gravada del concepto (NULL = hereda)',
  `monto_exento` decimal(12,2) DEFAULT NULL COMMENT 'Sustituye la cuota exenta del concepto (NULL = hereda)',
  `meses` int(11) DEFAULT NULL COMMENT 'Vigencia del plan en meses (NULL = la del concepto)',
  `orden` int(11) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planes, coberturas y paquetes de cada concepto';

--
-- Volcado de datos para la tabla `conceptos_caja_opciones`
--

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
(27, 12, 'PARABRISAS', 'Parabrisas antirreflejante', 'auto', NULL, 3200.00, NULL, NULL, 4, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `conceptos_caja_sucursal`
--

CREATE TABLE `conceptos_caja_sucursal` (
  `id_concepto` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0 = el concepto no se ofrece en esta sucursal'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Disponibilidad de cada concepto por sucursal (sin renglón = disponible)';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `conceptos_caja_tarifas`
--

CREATE TABLE `conceptos_caja_tarifas` (
  `id_tarifa` int(11) NOT NULL,
  `id_concepto` int(11) NOT NULL COMMENT 'Concepto con modo TARIFA',
  `limite_inferior` decimal(14,2) NOT NULL COMMENT 'Límite inferior del tramo (base sin IVA)',
  `limite_superior` decimal(14,2) DEFAULT NULL COMMENT 'Límite superior del tramo (NULL = en adelante)',
  `cuota_fija` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT 'Cuota fija del tramo',
  `porcentaje_excedente` decimal(7,4) NOT NULL COMMENT '% que se aplica sobre el excedente del límite inferior',
  `ejercicio` int(11) NOT NULL COMMENT 'Año fiscal de la tarifa; la caja usa el ejercicio más reciente que no sea futuro'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tarifas por tramos (ISAN y cualquier impuesto progresivo)';

--
-- Volcado de datos para la tabla `conceptos_caja_tarifas`
--

INSERT INTO `conceptos_caja_tarifas` (`id_tarifa`, `id_concepto`, `limite_inferior`, `limite_superior`, `cuota_fija`, `porcentaje_excedente`, `ejercicio`) VALUES
(1, 6, 0.01, 323893.68, 0.00, 2.0000, 2026),
(2, 6, 323893.69, 388672.38, 6477.85, 5.0000, 2026),
(3, 6, 388672.39, 453451.18, 9716.79, 10.0000, 2026),
(4, 6, 453451.19, 582999.86, 16194.67, 15.0000, 2026),
(5, 6, 582999.87, NULL, 35626.97, 17.0000, 2026);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contratos_credito`
--

CREATE TABLE `contratos_credito` (
  `id_contrato` int(11) NOT NULL,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-CC-{sucursal}-{id}',
  `estado` enum('pendiente_firma','firmado','cancelado') NOT NULL DEFAULT 'pendiente_firma' COMMENT 'pendiente_firma = enganche cobrado y contrato en pantalla; firmado = crédito concretado; cancelado = el cliente no firmó',
  `estado_credito` enum('activo','liquidado','cancelado') DEFAULT NULL COMMENT 'activo = con saldo; liquidado = pagado completo; cancelado = anulado',
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
  `abonos_pagados` int(11) NOT NULL DEFAULT 0 COMMENT 'Mensualidades cobradas',
  `saldo_pendiente` decimal(12,2) DEFAULT NULL COMMENT 'Suma de las mensualidades que faltan por pagar',
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
  `fecha_liquidacion` datetime DEFAULT NULL,
  `fecha_cancelacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contratos de crédito automotriz generados y firmados en el Punto de Venta';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_ventas`
--

CREATE TABLE `detalle_ventas` (
  `id_detalle` int(11) NOT NULL,
  `id_venta` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal_linea` decimal(10,2) NOT NULL,
  `vin` varchar(50) DEFAULT NULL,
  `motor_serie` varchar(80) DEFAULT NULL,
  `color_interior` varchar(80) DEFAULT NULL,
  `id_venta_concepto` int(11) DEFAULT NULL COMMENT 'Concepto de caja al que pertenece la línea (ventas_conceptos)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `garantias`
--

CREATE TABLE `garantias` (
  `id_garantia` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL COMMENT 'Cliente de la sección Clientes (créditos o compradores con cuenta); NULL en contado',
  `id_producto` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL COMMENT 'Venta con la que se compró el vehículo',
  `id_sucursal` int(11) DEFAULT NULL COMMENT 'Sucursal donde se vendió',
  `vin` varchar(17) DEFAULT NULL COMMENT 'VIN de la unidad vendida',
  `cliente_nombre` varchar(150) DEFAULT NULL COMMENT 'Comprador tal como se capturó en caja',
  `cliente_celular` varchar(30) DEFAULT NULL,
  `cliente_email` varchar(120) DEFAULT NULL,
  `fecha_compra` datetime DEFAULT NULL COMMENT 'Momento real de la venta (ventas.fecha_hora)',
  `fecha_expiracion` datetime NOT NULL COMMENT 'Fecha y hora exactas de vencimiento (compra + 4 años)',
  `estado` enum('vigente','vencida','cancelada','aplicada') NOT NULL DEFAULT 'vigente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventarios`
--

CREATE TABLE `inventarios` (
  `id_inventario` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `stock_actual` int(11) NOT NULL DEFAULT 0,
  `stock_minimo` int(11) NOT NULL DEFAULT 5
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `inventarios`
--

INSERT INTO `inventarios` (`id_inventario`, `id_sucursal`, `id_producto`, `stock_actual`, `stock_minimo`) VALUES
(1, 1, 1, 1, 1),
(2, 1, 6, 5, 1),
(3, 1, 5, 4, 1),
(4, 1, 7, 6, 1),
(5, 1, 8, 3, 1),
(6, 1, 2, 2, 1),
(7, 1, 3, 1, 1),
(8, 1, 4, 2, 1),
(9, 1, 9, 8, 1),
(10, 1, 10, 10, 1),
(11, 1, 86, 6, 2),
(12, 1, 87, 2, 2),
(13, 1, 88, 10, 2),
(14, 1, 89, 1, 2),
(15, 1, 90, 4, 2),
(16, 1, 91, 0, 2),
(17, 1, 92, 2, 2),
(18, 1, 93, 5, 2),
(19, 1, 94, 3, 2),
(26, 1, 11, 0, 2),
(27, 1, 12, 0, 2),
(28, 1, 13, 1, 2),
(29, 1, 14, 1, 2),
(30, 1, 15, 2, 2),
(31, 1, 16, 3, 2),
(32, 1, 17, 0, 2),
(33, 1, 18, 5, 2),
(34, 1, 19, 2, 2),
(35, 1, 20, 0, 2),
(36, 1, 21, 0, 2),
(37, 1, 22, 4, 2),
(38, 1, 23, 3, 2),
(39, 1, 24, 7, 2),
(40, 1, 25, 0, 2),
(41, 1, 26, 0, 2),
(42, 1, 27, 0, 2),
(43, 1, 28, 1, 2),
(44, 1, 29, 1, 2),
(45, 1, 30, 2, 2),
(46, 1, 31, 3, 2),
(47, 1, 32, 0, 2),
(48, 1, 33, 5, 2),
(49, 1, 34, 2, 2),
(50, 1, 35, 1, 2),
(51, 1, 36, 0, 2),
(52, 1, 37, 4, 2),
(53, 1, 38, 3, 2),
(54, 1, 39, 7, 2),
(55, 1, 40, 1, 2),
(56, 1, 41, 0, 2),
(57, 1, 42, 0, 2),
(58, 1, 43, 1, 2),
(59, 1, 44, 1, 2),
(60, 1, 45, 2, 2),
(61, 1, 46, 3, 2),
(62, 1, 47, 0, 2),
(63, 1, 48, 5, 2),
(64, 1, 49, 2, 2),
(65, 1, 50, 1, 2),
(66, 1, 51, 0, 2),
(67, 1, 52, 4, 2),
(68, 1, 53, 3, 2),
(69, 1, 54, 6, 2),
(70, 1, 55, 1, 2),
(71, 1, 56, 0, 2),
(72, 1, 57, 0, 2),
(73, 1, 58, 1, 2),
(74, 1, 59, 1, 2),
(75, 1, 60, 2, 2),
(76, 1, 61, 3, 2),
(77, 1, 62, 0, 2),
(78, 1, 63, 5, 2),
(79, 1, 64, 2, 2),
(80, 1, 65, 1, 2),
(81, 1, 66, 0, 2),
(82, 1, 67, 4, 2),
(83, 1, 68, 3, 2),
(84, 1, 69, 7, 2),
(85, 1, 70, 1, 2),
(86, 1, 71, 0, 2),
(87, 1, 72, 0, 2),
(88, 1, 73, 1, 2),
(89, 1, 74, 1, 2),
(90, 1, 75, 2, 2),
(91, 1, 76, 3, 2),
(92, 1, 77, 0, 2),
(93, 1, 78, 5, 2),
(94, 1, 79, 2, 2),
(95, 1, 80, 1, 2),
(96, 1, 81, 0, 2),
(97, 1, 82, 4, 2),
(98, 1, 83, 3, 2),
(99, 1, 84, 7, 2),
(100, 1, 85, 1, 2),
(153, 2, 2, 1, 1),
(154, 2, 3, 0, 1),
(155, 2, 4, 5, 1),
(156, 2, 5, 3, 1),
(157, 2, 6, 2, 1),
(158, 2, 7, 1, 1),
(159, 2, 8, 0, 1),
(160, 2, 9, 1, 2),
(161, 2, 10, 3, 2),
(162, 2, 1, 0, 2),
(163, 2, 11, 5, 1),
(164, 2, 12, 0, 1),
(165, 2, 13, 5, 1),
(166, 2, 14, 3, 1),
(167, 2, 15, 2, 1),
(168, 2, 16, 1, 1),
(169, 2, 17, 0, 1),
(170, 2, 18, 5, 1),
(171, 2, 19, 3, 1),
(172, 2, 20, 2, 1),
(173, 2, 21, 1, 1),
(174, 2, 22, 0, 1),
(175, 2, 23, 5, 1),
(176, 2, 24, 3, 1),
(177, 2, 25, 1, 1),
(178, 2, 26, 1, 1),
(179, 2, 27, 0, 1),
(180, 2, 28, 3, 1),
(181, 2, 29, 3, 1),
(182, 2, 30, 2, 1),
(183, 2, 31, 1, 1),
(184, 2, 32, 0, 1),
(185, 2, 33, 5, 1),
(186, 2, 34, 3, 1),
(187, 2, 35, 2, 1),
(188, 2, 36, 1, 1),
(189, 2, 37, 0, 1),
(190, 2, 38, 5, 1),
(191, 2, 39, 3, 1),
(192, 2, 40, 2, 1),
(193, 2, 41, 1, 1),
(194, 2, 42, 2, 1),
(195, 2, 43, 5, 1),
(196, 2, 44, 3, 1),
(197, 2, 45, 2, 1),
(198, 2, 46, 1, 1),
(199, 2, 47, 0, 1),
(200, 2, 48, 5, 1),
(201, 2, 49, 3, 1),
(202, 2, 50, 2, 1),
(203, 2, 51, 1, 1),
(204, 2, 52, 0, 1),
(205, 2, 53, 5, 1),
(206, 2, 54, 3, 1),
(207, 2, 55, 2, 1),
(208, 2, 56, 5, 2),
(209, 2, 57, 3, 2),
(210, 2, 58, 0, 2),
(211, 2, 59, 10, 2),
(212, 2, 60, 5, 2),
(213, 2, 61, 2, 2),
(214, 2, 62, 1, 2),
(215, 2, 63, 2, 2),
(216, 2, 64, 0, 2),
(217, 2, 65, 10, 2),
(218, 2, 66, 5, 2),
(219, 2, 67, 0, 2),
(220, 2, 68, 1, 2),
(221, 2, 69, 3, 2),
(222, 2, 70, 0, 2),
(223, 2, 71, 10, 2),
(224, 2, 72, 5, 2),
(225, 2, 73, 2, 2),
(226, 2, 74, 1, 2),
(227, 2, 75, 3, 2),
(228, 2, 76, 0, 2),
(229, 2, 77, 10, 2),
(230, 2, 78, 10, 2),
(231, 2, 79, 2, 2),
(232, 2, 80, 1, 2),
(233, 2, 81, 3, 2),
(234, 2, 82, 0, 2),
(235, 2, 83, 10, 2),
(236, 2, 84, 5, 2),
(237, 2, 85, 2, 2),
(238, 2, 86, 5, 2),
(239, 2, 87, 2, 2),
(240, 2, 88, 1, 2),
(241, 2, 89, 3, 2),
(242, 2, 90, 0, 2),
(243, 2, 91, 10, 2),
(244, 2, 92, 5, 2),
(245, 2, 93, 2, 2),
(246, 2, 94, 1, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metodos_pago`
--

CREATE TABLE `metodos_pago` (
  `id_metodo_pago` int(11) NOT NULL,
  `nombre_metodo` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `metodos_pago`
--

INSERT INTO `metodos_pago` (`id_metodo_pago`, `nombre_metodo`) VALUES
(1, 'Efectivo'),
(5, 'Sin cobro (enganche $0)'),
(3, 'Tarjeta de Crédito'),
(2, 'Tarjeta de Débito'),
(4, 'Transferencia');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notificaciones`
--

CREATE TABLE `notificaciones` (
  `id_notificacion` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `tipo` enum('pedido','cita','solicitud','promocion','cuenta') NOT NULL DEFAULT 'cuenta',
  `titulo` varchar(150) NOT NULL,
  `mensaje` varchar(500) DEFAULT NULL,
  `enlace` varchar(255) DEFAULT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT 0,
  `fecha` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `id_categoria` int(11) NOT NULL,
  `codigo_barras` varchar(50) NOT NULL DEFAULT '',
  `nombre` varchar(150) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `precio_base` decimal(10,2) NOT NULL,
  `marca` varchar(80) DEFAULT NULL,
  `modelo` varchar(120) DEFAULT NULL,
  `anio` int(11) DEFAULT NULL,
  `tipo` varchar(30) NOT NULL DEFAULT 'refaccion',
  `color` varchar(80) DEFAULT NULL,
  `color_hex` varchar(20) DEFAULT NULL,
  `motor` varchar(120) DEFAULT NULL,
  `cilindraje` varchar(80) DEFAULT NULL,
  `detalle` text DEFAULT NULL,
  `compatibilidad` varchar(255) DEFAULT NULL,
  `color_interior` varchar(80) DEFAULT NULL,
  `vin` varchar(17) DEFAULT NULL,
  `numero_motor` varchar(40) DEFAULT NULL COMMENT 'Número de serie del motor de la unidad',
  `modelo_3d` varchar(255) DEFAULT NULL,
  `traccion` varchar(80) DEFAULT NULL,
  `lado` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `id_categoria`, `codigo_barras`, `nombre`, `descripcion`, `precio_base`, `marca`, `modelo`, `anio`, `tipo`, `color`, `color_hex`, `motor`, `cilindraje`, `detalle`, `compatibilidad`, `color_interior`, `vin`, `numero_motor`, `modelo_3d`, `traccion`, `lado`) VALUES
(1, 4, 'KRM-REF-BALATA-AUDI', 'Balata delantera', 'Balata delantera para Audi RS7', 9800.00, 'Audi', 'RS7 Sportback (2024)', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, NULL, 'Audi RS7 Sportback', NULL, NULL, NULL, 'assets/Modelos_3D/idproducto10_idcategoria4_KRM-REF-BALATA-AUDI_balataDelanteraParaAudiRS7_2024_Negro grafito_refaccion.glb', 'Delantera', 'Izquierdo'),
(2, 1, 'KRM-P911-24', '911 Carrera 2024', 'Porsche 911 Carrera 2024', 2280000.00, 'Porsche', '911 Carrera', 2024, 'auto', 'Negro Jeweled', '#141414', '3.0L Boxer Biturbo', '2981 cc', 'Sport Chrono de fábrica y llantas forjadas de 21\".', NULL, NULL, 'WP0ZZZZZ0RS100037', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', NULL, NULL),
(3, 1, 'KRM-P911-25', '911 Carrera 2025', 'Porsche 911 Carrera 2025', 2350000.00, 'Porsche', '911 Carrera', 2025, 'auto', 'Negro Jeweled', '#141414', '3.0L Boxer Biturbo', '2981 cc', 'Sport Chrono de fábrica y llantas forjadas de 21\".', NULL, NULL, 'WP0ZZZZZ0SS100074', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', NULL, NULL),
(4, 1, 'KRM-PTAY-25', 'Taycan Turbo S 2025', 'Porsche Taycan Turbo S 2025', 3180000.00, 'Porsche', 'Taycan Turbo S', 2025, 'auto', 'Blanco Carrara', '#EDEDEA', 'Eléctrico de doble motor', '—', 'Doble motor eléctrico con carga ultrarrápida de 270 kW.', NULL, NULL, 'WP0ZZZZZ0SS100111', NULL, 'assets/Modelos_3D/porsche_taycan.glb', NULL, NULL),
(5, 2, 'KRM-ARS7-24', 'RS7 Sportback 2024', 'Audi RS7 Sportback 2024', 2190000.00, 'Audi', 'RS7 Sportback', 2024, 'auto', 'Gris Nardo', '#7A7D80', '4.0L V8 Biturbo', '3993 cc', 'V8 biturbo con interior en piel Nappa extendida.', NULL, NULL, 'WAUZZZZZ0RS100148', NULL, 'assets/Modelos_3D/audi_rs7.glb', NULL, NULL),
(6, 2, 'KRM-AQ8E-25', 'Q8 e-tron 2025', 'Audi Q8 e-tron 2025', 1850000.00, 'Audi', 'Q8 e-tron', 2025, 'auto', 'Azul Ultra', '#1F3B66', 'Eléctrico de doble motor', '—', 'Doble motor eléctrico y techo panorámico solar.', NULL, NULL, 'WAUZZZZZ0SS100185', NULL, 'assets/Modelos_3D/audi_q5.glb', NULL, NULL),
(7, 3, 'KRM-DPAN-24', 'Panigale V4 S 2024', 'Ducati Panigale V4 S 2024', 620000.00, 'Ducati', 'Panigale V4 S', 2024, 'moto', 'Rojo Ducati', '#9E1B2E', 'V4 Desmosedici Stradale', '1103 cc', 'Motor V4 con electrónica Öhlins de serie.', NULL, NULL, 'ZDMZZZZZ0RS100222', NULL, 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb', NULL, NULL),
(8, 3, 'KRM-DSTR-25', 'Streetfighter V4 2025', 'Ducati Streetfighter V4 2025', 590000.00, 'Ducati', 'Streetfighter V4', 2025, 'moto', 'Negro Mate', '#1A1A1A', 'V4 Desmosedici Stradale', '1103 cc', 'Motor V4 con winglets aerodinámicos de MotoGP.', NULL, NULL, 'ZDMZZZZZ0SS100259', NULL, 'assets/Modelos_3D/ducati_monster.glb', NULL, NULL),
(9, 4, 'KRM-REF-DISCO-911', 'Disco de freno delantero', 'Disco de freno delantero para Porsche 911', 18500.00, 'Porsche', '911 (2019)', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Disco delantero izquierdo.', 'Porsche 911', NULL, NULL, NULL, NULL, NULL, NULL),
(10, 4, 'KRM-REF-PAST-AUDI', 'Juego de pastillas de freno', 'Pastillas de freno para Audi RS7', 12400.00, 'Audi', 'RS7 Sportback', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Juego completo para eje delantero.', 'Audi RS7 Sportback', NULL, NULL, NULL, NULL, NULL, NULL),
(11, 2, 'KRM-CAT-AUDI-01', 'A3 2025', 'Audi A3 2025, motor 1.4L TFSI Turbo.', 665281.24, 'Audi', 'A3', 2025, 'auto', 'Gris Nardo', '#7A7D80', '1.4L TFSI Turbo', '1395 cc', 'Audi A3 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100296', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'Delantera', NULL),
(12, 2, 'KRM-CAT-AUDI-02', 'A4 2024', 'Audi A4 2024, motor 2.0L TFSI Turbo.', 812356.66, 'Audi', 'A4', 2024, 'auto', 'Blanco Glaciar', '#F2F2EF', '2.0L TFSI Turbo', '1984 cc', 'Audi A4 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0RS100333', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'Delantera', NULL),
(13, 2, 'KRM-CAT-AUDI-03', 'A5 2025', 'Audi A5 2025, motor 2.0L TFSI Turbo.', 946010.16, 'Audi', 'A5', 2025, 'auto', 'Gris Nardo', '#7A7D80', '2.0L TFSI Turbo', '1984 cc', 'Audi A5 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100370', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'Delantera', NULL),
(14, 2, 'KRM-CAT-AUDI-04', 'A6 2025', 'Audi A6 2025, motor 3.0L V6 TFSI.', 1166650.62, 'Audi', 'A6', 2025, 'auto', 'Gris Nardo', '#7A7D80', '3.0L V6 TFSI', '2995 cc', 'Audi A6 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100407', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(15, 2, 'KRM-CAT-AUDI-05', 'A7 2023', 'Audi A7 2023, motor 3.0L V6 TFSI.', 1206138.70, 'Audi', 'A7', 2023, 'auto', 'Gris Nardo', '#7A7D80', '3.0L V6 TFSI', '2995 cc', 'Audi A7 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0PS100444', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(16, 2, 'KRM-CAT-AUDI-06', 'A8 2023', 'Audi A8 2023, motor 3.0L V6 TFSI.', 1809054.93, 'Audi', 'A8', 2023, 'auto', 'Rojo Tango', '#8C1D2B', '3.0L V6 TFSI', '2995 cc', 'Audi A8 equipado de fábrica, listo para entrega en agencia.', NULL, 'Beige', 'WAUZZZZZ0PS100481', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(17, 2, 'KRM-CAT-AUDI-07', 'Q3 2025', 'Audi Q3 2025, motor 2.0L TFSI Turbo.', 858687.40, 'Audi', 'Q3', 2025, 'auto', 'Blanco Glaciar', '#F2F2EF', '2.0L TFSI Turbo', '1984 cc', 'Audi Q3 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100518', NULL, 'assets/Modelos_3D/audi_q5.glb', 'quattro (AWD)', NULL),
(18, 2, 'KRM-CAT-AUDI-08', 'Q5 2025', 'Audi Q5 2025, motor 2.0L TFSI Turbo.', 1006865.63, 'Audi', 'Q5', 2025, 'auto', 'Rojo Tango', '#8C1D2B', '2.0L TFSI Turbo', '1984 cc', 'Audi Q5 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100555', NULL, 'assets/Modelos_3D/audi_q5.glb', 'quattro (AWD)', NULL),
(19, 2, 'KRM-CAT-AUDI-09', 'Q7 2024', 'Audi Q7 2024, motor 3.0L V6 TFSI.', 1398540.24, 'Audi', 'Q7', 2024, 'auto', 'Rojo Tango', '#8C1D2B', '3.0L V6 TFSI', '2995 cc', 'Audi Q7 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0RS100592', NULL, 'assets/Modelos_3D/audi_q5.glb', 'quattro (AWD)', NULL),
(20, 2, 'KRM-CAT-AUDI-10', 'Q8 2023', 'Audi Q8 2023, motor 3.0L V6 TFSI.', 1743576.89, 'Audi', 'Q8', 2023, 'auto', 'Blanco Glaciar', '#F2F2EF', '3.0L V6 TFSI', '2995 cc', 'Audi Q8 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0PS100629', NULL, 'assets/Modelos_3D/audi_q5.glb', 'quattro (AWD)', NULL),
(21, 2, 'KRM-CAT-AUDI-11', 'RS3 2024', 'Audi RS3 2024, motor 2.5L TFSI Turbo 5-cil..', 1303929.87, 'Audi', 'RS3', 2024, 'auto', 'Negro Mythos', '#101012', '2.5L TFSI Turbo 5-cil.', '2480 cc', 'Audi RS3 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0RS100666', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(22, 2, 'KRM-CAT-AUDI-12', 'RS5 2024', 'Audi RS5 2024, motor 2.9L V6 Biturbo.', 1579878.48, 'Audi', 'RS5', 2024, 'auto', 'Gris Nardo', '#7A7D80', '2.9L V6 Biturbo', '2894 cc', 'Audi RS5 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0RS100703', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(23, 2, 'KRM-CAT-AUDI-13', 'RS6 2023', 'Audi RS6 2023, motor 4.0L V8 Biturbo.', 2480657.88, 'Audi', 'RS6', 2023, 'auto', 'Negro Mythos', '#101012', '4.0L V8 Biturbo', '3993 cc', 'Audi RS6 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0PS100740', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(24, 2, 'KRM-CAT-AUDI-14', 'RS7 2025', 'Audi RS7 2025, motor 4.0L V8 Biturbo.', 2297617.75, 'Audi', 'RS7', 2025, 'auto', 'Negro Mythos', '#101012', '4.0L V8 Biturbo', '3993 cc', 'Audi RS7 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100777', NULL, 'assets/Modelos_3D/audi_rs7.glb', 'quattro (AWD)', NULL),
(25, 2, 'KRM-CAT-AUDI-15', 'R8 2025', 'Audi R8 2025, motor 5.2L V10 FSI.', 3469997.91, 'Audi', 'R8', 2025, 'auto', 'Azul Ultra', '#1F3B66', '5.2L V10 FSI', '5204 cc', 'Audi R8 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WAUZZZZZ0SS100814', NULL, 'assets/Modelos_3D/id25_KRM-CAT-AUDI-15_audiR8_2025_AzulUltra.glb', 'quattro (AWD)', NULL),
(26, 1, 'KRM-CAT-POR-01', '718 Cayman 2024', 'Porsche 718 Cayman 2024, motor 2.0L Turbo Flat-4.', 1361240.78, 'Porsche', '718 Cayman', 2024, 'auto', 'Blanco Carrara', '#EDEDEA', '2.0L Turbo Flat-4', '1988 cc', 'Porsche 718 Cayman equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0RS100851', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'Trasera', NULL),
(27, 1, 'KRM-CAT-POR-02', '718 Boxster 2025', 'Porsche 718 Boxster 2025, motor 2.0L Turbo Flat-4.', 1465107.75, 'Porsche', '718 Boxster', 2025, 'auto', 'Azul Gentian', '#1B3A6B', '2.0L Turbo Flat-4', '1988 cc', 'Porsche 718 Boxster equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0SS100888', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'Trasera', NULL),
(28, 1, 'KRM-CAT-POR-03', '911 Carrera 2024', 'Porsche 911 Carrera 2024, motor 3.0L Boxer Biturbo.', 1996608.97, 'Porsche', '911 Carrera', 2024, 'auto', 'Azul Gentian', '#1B3A6B', '3.0L Boxer Biturbo', '2981 cc', 'Porsche 911 Carrera equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0RS100925', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'Trasera', NULL),
(29, 1, 'KRM-CAT-POR-04', '911 Carrera S 2023', 'Porsche 911 Carrera S 2023, motor 3.0L Boxer Biturbo.', 2338828.86, 'Porsche', '911 Carrera S', 2023, 'auto', 'Blanco Carrara', '#EDEDEA', '3.0L Boxer Biturbo', '2981 cc', 'Porsche 911 Carrera S equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0PS100962', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'Trasera', NULL),
(30, 1, 'KRM-CAT-POR-05', '911 Turbo 2024', 'Porsche 911 Turbo 2024, motor 3.7L Boxer Biturbo.', 3646135.38, 'Porsche', '911 Turbo', 2024, 'auto', 'Blanco Carrara', '#EDEDEA', '3.7L Boxer Biturbo', '3745 cc', 'Porsche 911 Turbo equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0RS100999', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'AWD', NULL),
(31, 1, 'KRM-CAT-POR-06', '911 GT3 2023', 'Porsche 911 GT3 2023, motor 4.0L Boxer Atmosférico.', 3520336.58, 'Porsche', '911 GT3', 2023, 'auto', 'Rojo Carmín', '#9E1B2E', '4.0L Boxer Atmosférico', '3996 cc', 'Porsche 911 GT3 equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0PS101036', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'Trasera', NULL),
(32, 1, 'KRM-CAT-POR-07', '911 GT3 RS 2025', 'Porsche 911 GT3 RS 2025, motor 4.0L Boxer Atmosférico.', 4209809.72, 'Porsche', '911 GT3 RS', 2025, 'auto', 'Gris GT Plata', '#9EA0A1', '4.0L Boxer Atmosférico', '3996 cc', 'Porsche 911 GT3 RS equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0SS101073', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'AWD', NULL),
(33, 1, 'KRM-CAT-POR-08', '911 Targa 2024', 'Porsche 911 Targa 2024, motor 3.0L Boxer Biturbo.', 2413985.87, 'Porsche', '911 Targa', 2024, 'auto', 'Negro Jeweled', '#141414', '3.0L Boxer Biturbo', '2981 cc', 'Porsche 911 Targa equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0RS101110', NULL, 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb', 'AWD', NULL),
(34, 1, 'KRM-CAT-POR-09', 'Taycan 2025', 'Porsche Taycan 2025, motor Eléctrico de doble motor.', 2492779.35, 'Porsche', 'Taycan', 2025, 'auto', 'Blanco Carrara', '#EDEDEA', 'Eléctrico de doble motor', '—', 'Porsche Taycan equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0SS101147', NULL, 'assets/Modelos_3D/porsche_taycan.glb', 'AWD', NULL),
(35, 1, 'KRM-CAT-POR-10', 'Taycan Turbo 2023', 'Porsche Taycan Turbo 2023, motor Eléctrico de doble motor.', 3296579.71, 'Porsche', 'Taycan Turbo', 2023, 'auto', 'Azul Gentian', '#1B3A6B', 'Eléctrico de doble motor', '—', 'Porsche Taycan Turbo equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0PS101184', NULL, 'assets/Modelos_3D/porsche_taycan.glb', 'AWD', NULL),
(36, 1, 'KRM-CAT-POR-11', 'Panamera 2023', 'Porsche Panamera 2023, motor 2.9L V6 Biturbo.', 2010461.38, 'Porsche', 'Panamera', 2023, 'auto', 'Rojo Carmín', '#9E1B2E', '2.9L V6 Biturbo', '2894 cc', 'Porsche Panamera equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0PS101221', NULL, 'assets/Modelos_3D/porsche_taycan.glb', 'Trasera', NULL),
(37, 1, 'KRM-CAT-POR-12', 'Panamera Turbo 2025', 'Porsche Panamera Turbo 2025, motor 4.0L V8 Biturbo.', 2846312.51, 'Porsche', 'Panamera Turbo', 2025, 'auto', 'Azul Gentian', '#1B3A6B', '4.0L V8 Biturbo', '3996 cc', 'Porsche Panamera Turbo equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0SS101258', NULL, 'assets/Modelos_3D/porsche_taycan.glb', 'AWD', NULL),
(38, 1, 'KRM-CAT-POR-13', 'Macan 2024', 'Porsche Macan 2024, motor 2.0L Turbo.', 1387139.15, 'Porsche', 'Macan', 2024, 'auto', 'Blanco Carrara', '#EDEDEA', '2.0L Turbo', '1984 cc', 'Porsche Macan equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0RS101295', NULL, 'assets/Modelos_3D/porsche_cayenne.glb', 'AWD', NULL),
(39, 1, 'KRM-CAT-POR-14', 'Cayenne 2023', 'Porsche Cayenne 2023, motor 3.0L V6 Turbo.', 1751851.73, 'Porsche', 'Cayenne', 2023, 'auto', 'Gris GT Plata', '#9EA0A1', '3.0L V6 Turbo', '2995 cc', 'Porsche Cayenne equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0PS101332', NULL, 'assets/Modelos_3D/porsche_cayenne.glb', 'AWD', NULL),
(40, 1, 'KRM-CAT-POR-15', 'Cayenne Turbo 2023', 'Porsche Cayenne Turbo 2023, motor 4.0L V8 Biturbo.', 2825169.72, 'Porsche', 'Cayenne Turbo', 2023, 'auto', 'Negro Jeweled', '#141414', '4.0L V8 Biturbo', '3996 cc', 'Porsche Cayenne Turbo equipado de fábrica, listo para entrega en agencia.', NULL, 'Negro', 'WP0ZZZZZ0PS101369', NULL, 'assets/Modelos_3D/porsche_cayenne.glb', 'AWD', NULL),
(41, 3, 'KRM-CAT-DUC-01', 'Panigale V2 2025', 'Ducati Panigale V2 2025, motor V2 90°.', 400688.50, 'Ducati', 'Panigale V2', 2025, 'moto', 'Gris Antracita', '#4A4A4A', 'V2 90°', '955 cc', 'Ducati Panigale V2 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0SS101406', NULL, 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb', 'Trasera (cadena)', NULL),
(42, 3, 'KRM-CAT-DUC-02', 'Panigale V4 2024', 'Ducati Panigale V4 2024, motor V4 Desmosedici Stradale.', 615698.60, 'Ducati', 'Panigale V4', 2024, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Desmosedici Stradale', '1103 cc', 'Ducati Panigale V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0RS101443', NULL, 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb', 'Trasera (cadena)', NULL),
(43, 3, 'KRM-CAT-DUC-03', 'Panigale V4 S 2025', 'Ducati Panigale V4 S 2025, motor V4 Desmosedici Stradale.', 584572.86, 'Ducati', 'Panigale V4 S', 2025, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Desmosedici Stradale', '1103 cc', 'Ducati Panigale V4 S equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0SS101480', NULL, 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb', 'Trasera (cadena)', NULL),
(44, 3, 'KRM-CAT-DUC-04', 'Monster 2023', 'Ducati Monster 2023, motor V2 Testastretta.', 332543.44, 'Ducati', 'Monster', 2023, 'moto', 'Negro Mate', '#1A1A1A', 'V2 Testastretta', '937 cc', 'Ducati Monster equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0PS101517', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(45, 3, 'KRM-CAT-DUC-05', 'Monster SP 2025', 'Ducati Monster SP 2025, motor V2 Testastretta.', 374228.00, 'Ducati', 'Monster SP', 2025, 'moto', 'Gris Antracita', '#4A4A4A', 'V2 Testastretta', '937 cc', 'Ducati Monster SP equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0SS101554', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(46, 3, 'KRM-CAT-DUC-06', 'Multistrada V2 2024', 'Ducati Multistrada V2 2024, motor V2 Testastretta.', 371609.38, 'Ducati', 'Multistrada V2', 2024, 'moto', 'Blanco Dark', '#E7E7E4', 'V2 Testastretta', '937 cc', 'Ducati Multistrada V2 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0RS101591', NULL, 'assets/Modelos_3D/ducati_desertx.glb', 'Trasera (cadena)', NULL),
(47, 3, 'KRM-CAT-DUC-07', 'Multistrada V4 2023', 'Ducati Multistrada V4 2023, motor V4 Granturismo.', 485963.66, 'Ducati', 'Multistrada V4', 2023, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Granturismo', '1158 cc', 'Ducati Multistrada V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0PS101628', NULL, 'assets/Modelos_3D/ducati_desertx.glb', 'Trasera (cadena)', NULL),
(48, 3, 'KRM-CAT-DUC-08', 'Diavel V4 2023', 'Ducati Diavel V4 2023, motor V4 Granturismo.', 510005.49, 'Ducati', 'Diavel V4', 2023, 'moto', 'Rojo Ducati', '#9E1B2E', 'V4 Granturismo', '1158 cc', 'Ducati Diavel V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0PS101665', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(49, 3, 'KRM-CAT-DUC-09', 'Streetfighter V2 2023', 'Ducati Streetfighter V2 2023, motor V2 Testastretta.', 416324.43, 'Ducati', 'Streetfighter V2', 2023, 'moto', 'Blanco Dark', '#E7E7E4', 'V2 Testastretta', '955 cc', 'Ducati Streetfighter V2 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0PS101702', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(50, 3, 'KRM-CAT-DUC-10', 'Streetfighter V4 2024', 'Ducati Streetfighter V4 2024, motor V4 Desmosedici Stradale.', 599051.87, 'Ducati', 'Streetfighter V4', 2024, 'moto', 'Blanco Dark', '#E7E7E4', 'V4 Desmosedici Stradale', '1103 cc', 'Ducati Streetfighter V4 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0RS101739', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(51, 3, 'KRM-CAT-DUC-11', 'Scrambler Icon 2024', 'Ducati Scrambler Icon 2024, motor L-Twin Desmodue.', 279596.86, 'Ducati', 'Scrambler Icon', 2024, 'moto', 'Gris Antracita', '#4A4A4A', 'L-Twin Desmodue', '803 cc', 'Ducati Scrambler Icon equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0RS101776', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(52, 3, 'KRM-CAT-DUC-12', 'Scrambler Nightshift 2023', 'Ducati Scrambler Nightshift 2023, motor L-Twin Desmodue.', 288140.62, 'Ducati', 'Scrambler Nightshift', 2023, 'moto', 'Rojo Ducati', '#9E1B2E', 'L-Twin Desmodue', '803 cc', 'Ducati Scrambler Nightshift equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0PS101813', NULL, 'assets/Modelos_3D/ducati_monster.glb', 'Trasera (cadena)', NULL),
(53, 3, 'KRM-CAT-DUC-13', 'DesertX 2025', 'Ducati DesertX 2025, motor L-Twin Testastretta.', 438049.83, 'Ducati', 'DesertX', 2025, 'moto', 'Gris Antracita', '#4A4A4A', 'L-Twin Testastretta', '937 cc', 'Ducati DesertX equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0SS101850', NULL, 'assets/Modelos_3D/ducati_desertx.glb', 'Trasera (cadena)', NULL),
(54, 3, 'KRM-CAT-DUC-14', 'Hypermotard 2024', 'Ducati Hypermotard 2024, motor V2 Testastretta.', 444801.61, 'Ducati', 'Hypermotard', 2024, 'moto', 'Rojo Ducati', '#9E1B2E', 'V2 Testastretta', '937 cc', 'Ducati Hypermotard equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0RS101887', NULL, 'assets/Modelos_3D/ducati_desertx.glb', 'Trasera (cadena)', NULL),
(55, 3, 'KRM-CAT-DUC-15', 'SuperSport 950 2023', 'Ducati SuperSport 950 2023, motor V2 Testastretta.', 359002.51, 'Ducati', 'SuperSport 950', 2023, 'moto', 'Blanco Dark', '#E7E7E4', 'V2 Testastretta', '937 cc', 'Ducati SuperSport 950 equipado de fábrica, listo para entrega en agencia.', NULL, NULL, 'ZDMZZZZZ0PS101924', NULL, 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb', 'Trasera (cadena)', NULL),
(56, 4, 'KRM-CAT-REF-AUDI-01', 'Filtro de aceite Audi', 'Filtro de aceite original/compatible para Audi RS5.', 508.87, 'Audi', 'RS5', NULL, 'refaccion', 'Blanco', '#E6E6E2', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS5', NULL, NULL, NULL, NULL, NULL, NULL),
(57, 4, 'KRM-CAT-REF-AUDI-02', 'Filtro de aire Audi', 'Filtro de aire original/compatible para Audi A7.', 666.81, 'Audi', 'A7', NULL, 'refaccion', 'Blanco hueso', '#E8E4D8', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi A7', NULL, NULL, NULL, NULL, NULL, NULL),
(58, 4, 'KRM-CAT-REF-AUDI-03', 'Juego de pastillas de freno delanteras Audi', 'Juego de pastillas de freno delanteras original/compatible para Audi RS6.', 3984.05, 'Audi', 'RS6', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS6', NULL, NULL, NULL, NULL, 'Delantera', NULL),
(59, 4, 'KRM-CAT-REF-AUDI-04', 'Juego de pastillas de freno traseras Audi', 'Juego de pastillas de freno traseras original/compatible para Audi R8.', 3560.70, 'Audi', 'R8', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi R8', NULL, NULL, NULL, NULL, 'Trasera', NULL),
(60, 4, 'KRM-CAT-REF-AUDI-05', 'Disco de freno delantero Audi', 'Disco de freno delantero original/compatible para Audi RS3.', 6580.71, 'Audi', 'RS3', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS3', NULL, NULL, NULL, NULL, 'Delantera', 'Izquierdo'),
(61, 4, 'KRM-CAT-REF-AUDI-06', 'Disco de freno trasero Audi', 'Disco de freno trasero original/compatible para Audi RS3.', 5907.23, 'Audi', 'RS3', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS3', NULL, NULL, NULL, NULL, 'Trasera', 'Derecho'),
(62, 4, 'KRM-CAT-REF-AUDI-07', 'Juego de bujías Audi', 'Juego de bujías original/compatible para Audi A6.', 1369.46, 'Audi', 'A6', NULL, 'refaccion', 'Plata', '#BFC3C7', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi A6', NULL, NULL, NULL, NULL, NULL, NULL),
(63, 4, 'KRM-CAT-REF-AUDI-08', 'Batería Audi', 'Batería original/compatible para Audi RS6.', 4918.41, 'Audi', 'RS6', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS6', NULL, NULL, NULL, NULL, NULL, NULL),
(64, 4, 'KRM-CAT-REF-AUDI-09', 'Kit de distribución Audi', 'Kit de distribución original/compatible para Audi RS6.', 10462.38, 'Audi', 'RS6', NULL, 'refaccion', 'Negro', '#202124', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi RS6', NULL, NULL, NULL, NULL, NULL, NULL),
(65, 4, 'KRM-CAT-REF-AUDI-10', 'Bomba de agua Audi', 'Bomba de agua original/compatible para Audi R8.', 3312.33, 'Audi', 'R8', NULL, 'refaccion', 'Aluminio', '#A9ADB2', NULL, NULL, 'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.', 'Audi R8', NULL, NULL, NULL, NULL, NULL, NULL),
(66, 4, 'KRM-CAT-REF-POR-01', 'Filtro de aceite Porsche', 'Filtro de aceite original/compatible para Porsche 911 GT3.', 479.12, 'Porsche', '911 GT3', NULL, 'refaccion', 'Blanco', '#E6E6E2', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 911 GT3', NULL, NULL, NULL, NULL, NULL, NULL),
(67, 4, 'KRM-CAT-REF-POR-02', 'Filtro de aire Porsche', 'Filtro de aire original/compatible para Porsche 718 Boxster.', 662.57, 'Porsche', '718 Boxster', NULL, 'refaccion', 'Blanco hueso', '#E8E4D8', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 718 Boxster', NULL, NULL, NULL, NULL, NULL, NULL),
(68, 4, 'KRM-CAT-REF-POR-03', 'Juego de pastillas de freno delanteras Porsche', 'Juego de pastillas de freno delanteras original/compatible para Porsche Cayenne Turbo.', 4526.14, 'Porsche', 'Cayenne Turbo', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Cayenne Turbo', NULL, NULL, NULL, NULL, 'Delantera', NULL),
(69, 4, 'KRM-CAT-REF-POR-04', 'Juego de pastillas de freno traseras Porsche', 'Juego de pastillas de freno traseras original/compatible para Porsche Macan.', 3682.97, 'Porsche', 'Macan', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Macan', NULL, NULL, NULL, NULL, 'Trasera', NULL),
(70, 4, 'KRM-CAT-REF-POR-05', 'Disco de freno delantero Porsche', 'Disco de freno delantero original/compatible para Porsche 718 Cayman.', 6518.07, 'Porsche', '718 Cayman', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 718 Cayman', NULL, NULL, NULL, NULL, 'Delantera', 'Izquierdo'),
(71, 4, 'KRM-CAT-REF-POR-06', 'Disco de freno trasero Porsche', 'Disco de freno trasero original/compatible para Porsche Taycan Turbo.', 6321.92, 'Porsche', 'Taycan Turbo', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Taycan Turbo', NULL, NULL, NULL, NULL, 'Trasera', 'Derecho'),
(72, 4, 'KRM-CAT-REF-POR-07', 'Juego de bujías Porsche', 'Juego de bujías original/compatible para Porsche 718 Boxster.', 1503.80, 'Porsche', '718 Boxster', NULL, 'refaccion', 'Plata', '#BFC3C7', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 718 Boxster', NULL, NULL, NULL, NULL, NULL, NULL),
(73, 4, 'KRM-CAT-REF-POR-08', 'Batería Porsche', 'Batería original/compatible para Porsche Cayenne.', 4841.58, 'Porsche', 'Cayenne', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Cayenne', NULL, NULL, NULL, NULL, NULL, NULL),
(74, 4, 'KRM-CAT-REF-POR-09', 'Kit de distribución Porsche', 'Kit de distribución original/compatible para Porsche Macan.', 9851.28, 'Porsche', 'Macan', NULL, 'refaccion', 'Negro', '#202124', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche Macan', NULL, NULL, NULL, NULL, NULL, NULL),
(75, 4, 'KRM-CAT-REF-POR-10', 'Bomba de agua Porsche', 'Bomba de agua original/compatible para Porsche 911 Carrera.', 3385.95, 'Porsche', '911 Carrera', NULL, 'refaccion', 'Aluminio', '#A9ADB2', NULL, NULL, 'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.', 'Porsche 911 Carrera', NULL, NULL, NULL, NULL, NULL, NULL),
(76, 4, 'KRM-CAT-REF-DUC-01', 'Filtro de aceite Ducati', 'Filtro de aceite original/compatible para Ducati Diavel V4.', 407.17, 'Ducati', 'Diavel V4', NULL, 'refaccion', 'Blanco', '#E6E6E2', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Diavel V4', NULL, NULL, NULL, NULL, NULL, NULL),
(77, 4, 'KRM-CAT-REF-DUC-02', 'Filtro de aire Ducati', 'Filtro de aire original/compatible para Ducati Panigale V4 S.', 500.45, 'Ducati', 'Panigale V4 S', NULL, 'refaccion', 'Blanco hueso', '#E8E4D8', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Panigale V4 S', NULL, NULL, NULL, NULL, NULL, NULL),
(78, 4, 'KRM-CAT-REF-DUC-03', 'Juego de pastillas de freno delanteras Ducati', 'Juego de pastillas de freno delanteras original/compatible para Ducati Hypermotard.', 2440.93, 'Ducati', 'Hypermotard', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Hypermotard', NULL, NULL, NULL, NULL, 'Delantera', NULL),
(79, 4, 'KRM-CAT-REF-DUC-04', 'Juego de pastillas de freno traseras Ducati', 'Juego de pastillas de freno traseras original/compatible para Ducati Monster.', 2244.11, 'Ducati', 'Monster', NULL, 'refaccion', 'Negro grafito', '#2E2F33', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Monster', NULL, NULL, NULL, NULL, 'Trasera', NULL),
(80, 4, 'KRM-CAT-REF-DUC-05', 'Disco de freno delantero Ducati', 'Disco de freno delantero original/compatible para Ducati DesertX.', 4354.51, 'Ducati', 'DesertX', NULL, 'refaccion', 'Acero gris', '#8C9096', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati DesertX', NULL, NULL, NULL, NULL, 'Delantera', 'Izquierdo'),
(81, 4, 'KRM-CAT-REF-DUC-06', 'Cadena de transmisión Ducati', 'Cadena de transmisión original/compatible para Ducati Monster.', 3205.62, 'Ducati', 'Monster', NULL, 'refaccion', 'Dorado', '#B8923A', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Monster', NULL, NULL, NULL, NULL, NULL, NULL),
(82, 4, 'KRM-CAT-REF-DUC-07', 'Kit de bujías Ducati', 'Kit de bujías original/compatible para Ducati Multistrada V4.', 1025.26, 'Ducati', 'Multistrada V4', NULL, 'refaccion', 'Plata', '#BFC3C7', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Multistrada V4', NULL, NULL, NULL, NULL, NULL, NULL),
(83, 4, 'KRM-CAT-REF-DUC-08', 'Batería Ducati', 'Batería original/compatible para Ducati Scrambler Icon.', 2547.34, 'Ducati', 'Scrambler Icon', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Scrambler Icon', NULL, NULL, NULL, NULL, NULL, NULL),
(84, 4, 'KRM-CAT-REF-DUC-09', 'Maneta de freno/embrague Ducati', 'Maneta de freno/embrague original/compatible para Ducati SuperSport 950.', 1203.37, 'Ducati', 'SuperSport 950', NULL, 'refaccion', 'Negro anodizado', '#2A2B2F', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati SuperSport 950', NULL, NULL, NULL, NULL, NULL, 'Derecho'),
(85, 4, 'KRM-CAT-REF-DUC-10', 'Espejo retrovisor Ducati', 'Espejo retrovisor original/compatible para Ducati Panigale V4.', 854.10, 'Ducati', 'Panigale V4', NULL, 'refaccion', 'Negro mate', '#1A1A1A', NULL, NULL, 'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.', 'Ducati Panigale V4', NULL, NULL, NULL, NULL, NULL, 'Izquierdo'),
(86, 4, 'KRM-CAT-ACC-AUDI-01', 'Tapetes de hule para todo clima Audi Q5', 'Juego de tapetes de hule a la medida para Audi Q5.', 3290.00, 'Audi', 'Q5', NULL, 'refaccion', 'Negro', '#1C1C1E', NULL, NULL, 'Juego de 4 piezas con bordes elevados.', 'Audi Q5', NULL, NULL, NULL, NULL, NULL, NULL),
(87, 4, 'KRM-CAT-ACC-AUDI-02', 'Barras portaequipaje para techo Audi Q3', 'Barras transversales de aluminio para el techo del Audi Q3.', 6890.00, 'Audi', 'Q3', NULL, 'refaccion', 'Aluminio', '#A9ADB2', NULL, NULL, 'Par de barras con cerradura antirrobo.', 'Audi Q3', NULL, NULL, NULL, NULL, NULL, NULL),
(88, 4, 'KRM-CAT-ACC-AUDI-03', 'Organizador plegable de cajuela Audi', 'Organizador plegable con divisiones ajustables para cajuela.', 1450.00, 'Audi', 'A4', NULL, 'refaccion', 'Negro', '#202124', NULL, NULL, 'Divisiones ajustables y base antiderrapante.', 'Audi A4 / A6 / Q5', NULL, NULL, NULL, NULL, NULL, NULL),
(89, 4, 'KRM-CAT-ACC-POR-01', 'Funda de interior a la medida Porsche 911', 'Funda transpirable a la medida para el Porsche 911.', 9850.00, 'Porsche', '911 Carrera', NULL, 'refaccion', 'Gris', '#6E7175', NULL, NULL, 'Funda para uso en interior con bolsa de guardado.', 'Porsche 911 (992)', NULL, NULL, NULL, NULL, NULL, NULL),
(90, 4, 'KRM-CAT-ACC-POR-02', 'Tapetes premium con ribete Porsche Macan', 'Tapetes de alfombra premium con ribete para Porsche Macan.', 4590.00, 'Porsche', 'Macan', NULL, 'refaccion', 'Negro', '#141414', NULL, NULL, 'Juego de 4 piezas con respaldo antiderrapante.', 'Porsche Macan', NULL, NULL, NULL, NULL, NULL, NULL),
(91, 4, 'KRM-CAT-ACC-POR-03', 'Cargador portátil para vehículo eléctrico Porsche Taycan', 'Cargador portátil de hasta 11 kW con conector Tipo 2.', 18900.00, 'Porsche', 'Taycan', NULL, 'refaccion', 'Negro', '#1A1A1A', NULL, NULL, 'Incluye estuche de transporte.', 'Porsche Taycan', NULL, NULL, NULL, NULL, NULL, NULL),
(92, 4, 'KRM-CAT-ACC-DUC-01', 'Maletas laterales rígidas Ducati Multistrada V4', 'Par de maletas laterales de aluminio para Multistrada V4.', 21500.00, 'Ducati', 'Multistrada V4', NULL, 'refaccion', 'Aluminio', '#BFC3C7', NULL, NULL, 'Par de maletas con soportes de liberación rápida.', 'Ducati Multistrada V4', NULL, NULL, NULL, NULL, NULL, NULL),
(93, 4, 'KRM-CAT-ACC-DUC-02', 'Parabrisas touring Ducati Multistrada', 'Parabrisas touring de mayor altura para Multistrada.', 4250.00, 'Ducati', 'Multistrada V4', NULL, 'refaccion', 'Transparente', '#D8DDE3', NULL, NULL, 'Policarbonato de 4 mm con tratamiento antirrayas.', 'Ducati Multistrada V2 / V4', NULL, NULL, NULL, NULL, NULL, NULL),
(94, 4, 'KRM-CAT-ACC-DUC-03', 'Funda para motocicleta Ducati', 'Funda de exterior impermeable con protección UV.', 2890.00, 'Ducati', 'Panigale V4', NULL, 'refaccion', 'Negro', '#1A1A1A', NULL, NULL, 'Incluye orificios para candado y bolsa de transporte.', 'Ducati Panigale / Streetfighter', NULL, NULL, NULL, NULL, NULL, NULL),
(95, 5, 'KRM-SRV-SEG-AMPLIA', 'Seguro automotriz de cobertura amplia', 'Prima de seguro de cobertura amplia cobrada en caja', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(96, 5, 'KRM-SRV-COSEG-VIDA-DES', 'Co seguro de vida y desempleo', 'Prima del seguro de vida y desempleo ligado a un crédito', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(97, 5, 'KRM-SRV-SEG-LLANTAS', 'Seguro de llantas y rines', 'Plan de protección de llantas y rines', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(98, 5, 'KRM-SRV-COMISION-APERTURA', 'Comisión por apertura de crédito', 'Comisión por apertura de un crédito con financiera externa', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(99, 5, 'KRM-SRV-GESTORIA-PLACAS', 'Gestoría de placas y alta vehicular', 'Honorarios de gestoría y derechos de alta vehicular', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(100, 5, 'KRM-SRV-ISAN', 'Impuesto sobre automóviles nuevos (ISAN)', 'ISAN calculado con la tarifa vigente', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(101, 5, 'KRM-SRV-TENENCIA-REFRENDO', 'Tenencia / refrendo vehicular', 'Tenencia estatal o refrendo anual de control vehicular', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(102, 5, 'KRM-SRV-VERIF-HOLOGRAMA-00', 'Verificación vehicular (holograma 00)', 'Gestión y derechos del holograma 00', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(103, 5, 'KRM-SRV-MANT-PREPAGADO', 'Plan de mantenimiento prepagado', 'Paquete de servicios de mantenimiento pagados por adelantado', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(104, 5, 'KRM-SRV-GARANTIA-EXT', 'Garantía extendida', 'Extensión de la garantía KARMA del vehículo', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(105, 5, 'KRM-SRV-ACCESORIOS-INST', 'Instalación de accesorios originales', 'Mano de obra de instalación de accesorios originales', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(106, 5, 'KRM-SRV-POLARIZADO', 'Película de seguridad y/o polarizado', 'Instalación de película de seguridad o polarizado', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(107, 5, 'KRM-SRV-ORDEN-TALLER', 'Orden de servicio de taller', 'Cobro de una orden de servicio del taller', 0.00, NULL, NULL, NULL, 'servicio', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--
-- Disparadores `productos`
--
DELIMITER $$
CREATE TRIGGER `trg_productos_autogenerar` BEFORE INSERT ON `productos` FOR EACH ROW BEGIN
    -- Código de barras vacío = se genera con el formato KRM-CAT-…
    IF NEW.codigo_barras IS NULL OR TRIM(NEW.codigo_barras) = '' THEN
        SET NEW.codigo_barras = karma_generar_codigo_barras(NEW.marca, NEW.tipo);
    END IF;
    -- Solo autos y motos llevan VIN; las refacciones se quedan sin VIN
    IF NEW.tipo IN ('auto', 'moto') AND (NEW.vin IS NULL OR TRIM(NEW.vin) = '') THEN
        SET NEW.vin = karma_generar_vin(NEW.marca, NEW.anio);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos_web`
--

CREATE TABLE `productos_web` (
  `id_producto` int(11) NOT NULL,
  `seccion` enum('vehiculos','refacciones','accesorios') NOT NULL,
  `publicado` tinyint(1) NOT NULL DEFAULT 1,
  `destacado` tinyint(1) NOT NULL DEFAULT 0,
  `condicion` enum('nuevo','seminuevo') NOT NULL DEFAULT 'nuevo',
  `subcategoria` varchar(60) DEFAULT NULL,
  `imagen` varchar(255) DEFAULT NULL,
  `galeria` text DEFAULT NULL,
  `transmision` varchar(100) DEFAULT NULL,
  `potencia` varchar(40) DEFAULT NULL,
  `aceleracion` varchar(40) DEFAULT NULL,
  `descripcion_larga` text DEFAULT NULL,
  `caracteristicas` text DEFAULT NULL,
  `orden` int(11) NOT NULL DEFAULT 0,
  `fecha_publicacion` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `productos_web`
--

INSERT INTO `productos_web` (`id_producto`, `seccion`, `publicado`, `destacado`, `condicion`, `subcategoria`, `imagen`, `galeria`, `transmision`, `potencia`, `aceleracion`, `descripcion_larga`, `caracteristicas`, `orden`, `fecha_publicacion`) VALUES
(11, 'vehiculos', 1, 0, 'nuevo', 'Hatchback', 'assets/Catalogo/vehiculos/audi/a3.webp', NULL, 'S tronic de 7 velocidades', '150 hp', '8.4 s', 'El Audi A3 Sportback reúne la esencia premium de Audi en un formato compacto y versátil. Su motor TFSI turbo responde al instante con consumos contenidos, y su interior digital con Audi virtual cockpit lo convierte en el compañero ideal para la ciudad y los viajes de fin de semana.', 'Audi virtual cockpit de 10.25\"\r\nPantalla MMI táctil con Apple CarPlay y Android Auto\r\nFaros LED con firma luminosa diurna\r\nControl de crucero adaptativo y asistente de carril\r\nModos de manejo Audi drive select\r\nRines de aleación de 17\"', 1, '2026-10-10 17:59:21'),
(12, 'vehiculos', 1, 0, 'nuevo', 'Sedán', 'assets/Catalogo/vehiculos/audi/a4.webp', NULL, 'S tronic de 7 velocidades', '201 hp', '7.3 s', 'El Audi A4 Sedán es un referente del segmento ejecutivo: aplomo en carretera, aislamiento acústico sobresaliente y una cabina que equilibra tecnología y confort. Una elección inteligente para quien recorre largas distancias sin renunciar a la deportividad.', 'Motor 2.0 TFSI con sistema mild hybrid de 12 V\r\nClimatizador automático de tres zonas\r\nAsientos delanteros con ajuste eléctrico\r\nFrenado de emergencia Audi pre sense city\r\nCalaveras LED con intermitentes dinámicos\r\nCajuela de 460 litros', 2, '2026-10-10 17:59:21'),
(13, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/a5.webp', NULL, 'S tronic de 7 velocidades', '201 hp', '7.7 s', 'El Audi A5 Sportback combina la silueta de un coupé con la practicidad de cinco puertas. Líneas fluidas, portón trasero de gran apertura y un habitáculo digital de última generación lo convierten en el gran turismo de la gama media.', 'Diseño Sportback de cinco puertas\r\nPantalla panorámica curva MMI\r\nHead-up display\r\nSuspensión deportiva\r\nSistema de audio premium de 16 bocinas\r\nPortón trasero eléctrico', 3, '2026-10-10 17:59:21'),
(14, 'vehiculos', 1, 1, 'nuevo', 'Sedán', 'assets/Catalogo/vehiculos/audi/a6.webp', NULL, 'S tronic de 7 velocidades', '340 hp', '5.1 s', 'El Audi A6 es la expresión del lujo progresivo: un sedán de gran formato con tracción quattro, motor V6 TFSI y una cabina con doble pantalla táctil con respuesta háptica. Confort de primera clase con la precisión dinámica que distingue a Audi.', 'Motor 3.0 V6 TFSI con mild hybrid de 48 V\r\nTracción integral quattro\r\nDoble pantalla MMI touch response\r\nFaros HD Matrix LED\r\nSuspensión adaptativa\r\nCámara de 360° para estacionarse', 4, '2026-10-10 17:59:21'),
(15, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/a7.webp', NULL, 'S tronic de 7 velocidades', '340 hp', '5.3 s', 'El Audi A7 Sportback es un gran turismo de cuatro puertas con alma de coupé. Su diseño escultural, el alerón trasero desplegable y la tracción quattro hacen de cada trayecto una experiencia elegante y emocionante.', 'Alerón trasero activo\r\nTracción integral quattro\r\nFaros HD Matrix LED\r\nInterior en piel Valcona\r\nTecho panorámico\r\nPaquete de asistentes de conducción Tour', 5, '2026-10-10 17:59:21'),
(16, 'vehiculos', 1, 0, 'nuevo', 'Sedán de lujo', 'assets/Catalogo/vehiculos/audi/a8.webp', NULL, 'Tiptronic de 8 velocidades', '340 hp', '5.6 s', 'El Audi A8 es el buque insignia de la marca: un sedán de representación con un nivel de refinamiento, silencio y tecnología pensado tanto para quien conduce como para quien viaja atrás. Cada detalle está diseñado para el máximo confort.', 'Suspensión neumática adaptativa\r\nAsientos con masaje y ventilación\r\nIluminación ambiental de 30 colores\r\nClimatizador de cuatro zonas\r\nPuertas con cierre asistido\r\nSistema de audio 3D premium', 6, '2026-10-10 17:59:21'),
(17, 'vehiculos', 1, 0, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/audi/q3.webp', NULL, 'S tronic de 7 velocidades', '190 hp', '7.3 s', 'El Audi Q3 es la SUV compacta para la vida urbana con espíritu aventurero: posición de manejo elevada, cajuela flexible gracias a la banca trasera deslizable y tracción quattro para mayor seguridad en cualquier camino.', 'Tracción integral quattro\r\nBanca trasera deslizable y reclinable\r\nAudi virtual cockpit\r\nPortón trasero eléctrico\r\nCámara de reversa\r\nSensores de estacionamiento delanteros y traseros', 7, '2026-10-10 17:59:21'),
(18, 'vehiculos', 1, 1, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/audi/q5.webp', NULL, 'S tronic de 7 velocidades', '261 hp', '6.1 s', 'El Audi Q5 es la SUV mediana más equilibrada de la gama: espacio para cinco ocupantes, tracción quattro y un motor TFSI que entrega potencia con suavidad. Ideal para la familia que busca versatilidad y prestigio.', 'Tracción quattro con tecnología ultra\r\nFaros LED Matrix\r\nPantalla MMI de 10.1\"\r\nAlerta de tráfico cruzado trasero\r\nCajuela de 520 litros\r\nPreparación para enganche de remolque', 8, '2026-10-10 17:59:21'),
(19, 'vehiculos', 1, 0, 'nuevo', 'SUV 7 plazas', 'assets/Catalogo/vehiculos/audi/q7.webp', NULL, 'Tiptronic de 8 velocidades', '335 hp', '5.9 s', 'El Audi Q7 ofrece tres filas de asientos, tracción quattro y la serenidad de un vehículo de lujo. Con su motor V6 TFSI y suspensión adaptativa, recorre ciudad y carretera con igual soltura.', 'Tres filas de asientos (7 plazas)\r\nSuspensión neumática adaptativa\r\nTracción integral quattro\r\nClimatizador de cuatro zonas\r\nDirección en las cuatro ruedas\r\nTecho panorámico corredizo', 9, '2026-10-10 17:59:21'),
(20, 'vehiculos', 1, 0, 'nuevo', 'SUV coupé', 'assets/Catalogo/vehiculos/audi/q8.webp', NULL, 'Tiptronic de 8 velocidades', '335 hp', '5.9 s', 'El Audi Q8 fusiona la elegancia de un coupé con la presencia de una SUV de lujo. Su parrilla octagonal, las puertas sin marco y una cabina completamente digital lo posicionan como la cumbre de la familia Q.', 'Diseño SUV coupé con puertas sin marco\r\nRines de 21\"\r\nDoble pantalla MMI touch response\r\nTracción integral quattro\r\nFaros HD Matrix LED\r\nAsistente de conducción en ciudad y autopista', 10, '2026-10-10 17:59:21'),
(21, 'vehiculos', 1, 1, 'nuevo', 'Deportivo compacto', 'assets/Catalogo/vehiculos/audi/rs3.webp', NULL, 'S tronic de 7 velocidades', '401 hp', '3.8 s', 'El Audi RS 3 es un compacto de altas prestaciones impulsado por el legendario cinco cilindros turbo. Su sonido inconfundible, el diferencial RS Torque Splitter y la suspensión deportiva convierten cada curva en un momento memorable.', 'Motor 2.5 TFSI de cinco cilindros\r\nRS Torque Splitter con modo RS Torque Rear\r\nEscape deportivo RS\r\nAsientos deportivos RS con costura en panal\r\nFrenos de alto desempeño\r\nPantallas RS en el virtual cockpit', 11, '2026-10-10 17:59:21'),
(22, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/rs5.webp', NULL, 'Tiptronic de 8 velocidades', '444 hp', '3.9 s', 'El Audi RS 5 Sportback combina cinco puertas con un V6 biturbo de 444 hp y tracción quattro deportiva. Es la definición de un auto de uso diario capaz de emocionar en pista.', 'Motor 2.9 V6 biturbo\r\nTracción quattro con diferencial deportivo\r\nSuspensión RS con Dynamic Ride Control\r\nPaquete de diseño RS en negro\r\nEscape deportivo RS\r\nVolante deportivo RS en Alcantara', 12, '2026-10-10 17:59:21'),
(23, 'vehiculos', 1, 1, 'nuevo', 'Avant', 'assets/Catalogo/vehiculos/audi/rs6.webp', NULL, 'Tiptronic de 8 velocidades', '591 hp', '3.6 s', 'El Audi RS 6 Avant es una de las familiares más deseadas del mundo: un V8 biturbo de 591 hp, carrocería ensanchada y la practicidad de una cajuela de gran capacidad. Desempeño de superdeportivo para el día a día.', 'Motor 4.0 V8 biturbo con mild hybrid\r\nCarrocería ensanchada exclusiva RS\r\nSuspensión neumática adaptativa RS\r\nDirección en las cuatro ruedas\r\nFrenos RS de alto desempeño\r\nCajuela de 565 litros', 13, '2026-10-10 17:59:21'),
(24, 'vehiculos', 1, 0, 'nuevo', 'Sportback', 'assets/Catalogo/vehiculos/audi/rs7.webp', NULL, 'Tiptronic de 8 velocidades', '591 hp', '3.6 s', 'El Audi RS 7 Sportback lleva el diseño del A7 a su máxima expresión deportiva. Su V8 biturbo, la tracción quattro y la suspensión RS ofrecen un equilibrio único entre lujo, elegancia y desempeño.', 'Motor 4.0 V8 biturbo\r\nTracción quattro con diferencial deportivo\r\nFaros HD Matrix LED con luz láser\r\nEscape deportivo RS\r\nAsientos RS con ventilación y masaje\r\nRines de 22\"', 14, '2026-10-10 17:59:21'),
(25, 'vehiculos', 1, 1, 'nuevo', 'Superdeportivo', 'assets/Catalogo/vehiculos/audi/r8.webp', NULL, 'S tronic de 7 velocidades', '602 hp', '3.1 s', 'El Audi R8 V10 performance es el superdeportivo nacido en las pistas de competencia. Motor central V10 atmosférico, chasis de aluminio y fibra de carbono y tracción quattro para una conexión pura entre piloto y camino.', 'Motor central V10 5.2 FSI atmosférico\r\nChasis Audi Space Frame de aluminio y CFRP\r\nTracción integral quattro\r\nFrenos cerámicos disponibles\r\nAudi virtual cockpit con modo de pista\r\nEdición de producción limitada', 15, '2026-10-10 17:59:21'),
(26, 'vehiculos', 1, 0, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/718-cayman.webp', NULL, 'PDK de 7 velocidades', '300 hp', '4.9 s', 'El Porsche 718 Cayman es el deportivo de motor central por excelencia: equilibrio perfecto, dirección precisa y un motor bóxer turbo que responde al instante. Diversión pura en cada curva.', 'Motor central bóxer turbo de cuatro cilindros\r\nTransmisión PDK de 7 velocidades\r\nPorsche Torque Vectoring\r\nPaquete Sport Chrono\r\nDos cajuelas: delantera y trasera\r\nFrenos de alto desempeño', 16, '2026-10-10 17:59:21'),
(27, 'vehiculos', 1, 0, 'nuevo', 'Roadster', 'assets/Catalogo/vehiculos/porsche/718-boxster.webp', NULL, 'PDK de 7 velocidades', '300 hp', '4.9 s', 'El Porsche 718 Boxster es el roadster que convierte cualquier camino en un destino. Su capota eléctrica se abre en segundos y el motor central bóxer ofrece un equilibrio dinámico excepcional.', 'Capota eléctrica de lona (apertura en 9 s)\r\nMotor central bóxer turbo\r\nTransmisión PDK de 7 velocidades\r\nPorsche Active Suspension Management (PASM)\r\nAsientos deportivos Plus\r\nPaquete Sport Chrono', 17, '2026-10-10 17:59:21'),
(28, 'vehiculos', 1, 1, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/911-carrera.webp', NULL, 'PDK de 8 velocidades', '379 hp', '4.2 s', 'El Porsche 911 Carrera es el ícono atemporal de los autos deportivos. Su motor bóxer biturbo montado atrás, la tracción trasera y una ergonomía impecable lo hacen tan disfrutable en el día a día como en un track day.', 'Motor bóxer biturbo 3.0 de seis cilindros\r\nTransmisión PDK de 8 velocidades\r\nPorsche Communication Management (PCM)\r\nModos de manejo con Sport Response\r\nRines de 19\" y 20\"\r\nFaros LED Matrix', 18, '2026-10-10 17:59:21'),
(29, 'vehiculos', 1, 0, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/911-carrera-s.webp', NULL, 'PDK de 8 velocidades', '443 hp', '3.7 s', 'El 911 Carrera S eleva la experiencia con 443 hp, frenos de mayor diámetro y un carácter aún más afilado. La combinación perfecta de confort de gran turismo y desempeño de deportivo puro.', 'Motor bóxer biturbo de 443 hp\r\nCalipers rojos de seis pistones\r\nPASM de serie\r\nEscape deportivo disponible\r\nSport Chrono con selector de modos\r\nRines de 20\" y 21\"', 19, '2026-10-10 17:59:21'),
(30, 'vehiculos', 1, 1, 'nuevo', 'Coupé', 'assets/Catalogo/vehiculos/porsche/911-turbo.webp', NULL, 'PDK de 8 velocidades', '572 hp', '2.8 s', 'El Porsche 911 Turbo es el superdeportivo para todos los días. Tracción integral, aerodinámica activa y un motor biturbo de 572 hp que impulsa de 0 a 100 km/h en menos de tres segundos con una facilidad sorprendente.', 'Tracción integral Porsche Traction Management\r\nAerodinámica activa: spoiler y alerón adaptativos\r\nMotor bóxer 3.7 biturbo\r\nSuspensión PASM deportiva\r\nInterior en piel con costuras en contraste\r\nSistema de audio envolvente premium', 20, '2026-10-10 17:59:21'),
(31, 'vehiculos', 1, 0, 'nuevo', 'Deportivo de pista', 'assets/Catalogo/vehiculos/porsche/911-gt3.webp', NULL, 'PDK de 7 velocidades', '502 hp', '3.4 s', 'El 911 GT3 lleva el ADN del automovilismo a la calle: motor atmosférico de 4.0 litros que gira hasta 9,000 rpm, suspensión delantera de doble horquilla derivada de competencia y alerón trasero fijo para máxima carga aerodinámica.', 'Motor bóxer atmosférico de 4.0 l y 9,000 rpm\r\nSuspensión delantera de doble horquilla\r\nAlerón trasero tipo cuello de cisne\r\nDirección en el eje trasero\r\nFrenos cerámicos PCCB disponibles\r\nModo Track Screen en el tablero', 21, '2026-10-10 17:59:21'),
(32, 'vehiculos', 1, 1, 'nuevo', 'Deportivo de pista', 'assets/Catalogo/vehiculos/porsche/911-gt3-rs.webp', NULL, 'PDK de 7 velocidades', '518 hp', '3.2 s', 'El 911 GT3 RS es una de las versiones más radicales homologadas para calle: aerodinámica activa con DRS, enorme carga aerodinámica y un motor atmosférico de 518 hp. Concebido para dominar el circuito.', 'Sistema de reducción de arrastre (DRS)\r\nHasta 860 kg de carga aerodinámica a 285 km/h\r\nMotor atmosférico de 518 hp\r\nAjustes de suspensión desde el volante\r\nPaquete Weissach disponible\r\nJaula antivuelco disponible', 22, '2026-10-10 17:59:21'),
(33, 'vehiculos', 1, 0, 'nuevo', 'Targa', 'assets/Catalogo/vehiculos/porsche/911-targa.webp', NULL, 'PDK de 8 velocidades', '379 hp', '4.4 s', 'El 911 Targa combina la emoción de un convertible con la seguridad de un coupé gracias a su icónico arco Targa y a un techo que se retrae automáticamente. Tracción integral para disfrutarlo todo el año.', 'Techo Targa de apertura automática\r\nArco Targa característico\r\nTracción integral\r\nTransmisión PDK de 8 velocidades\r\nAsientos con calefacción\r\nFaros LED Matrix', 23, '2026-10-10 17:59:21'),
(34, 'vehiculos', 1, 0, 'nuevo', 'Sedán eléctrico', 'assets/Catalogo/vehiculos/porsche/taycan.webp', NULL, 'Automática de 2 velocidades (eje trasero)', '402 hp', '4.8 s', 'El Porsche Taycan es el deportivo eléctrico que redefine la movilidad sin emisiones: arquitectura de 800 voltios, carga ultrarrápida y la dinámica de manejo que se espera de un Porsche.', 'Arquitectura eléctrica de 800 V\r\nCarga rápida en corriente directa\r\nAutonomía estimada de hasta 500 km (WLTP)\r\nTransmisión de 2 velocidades en el eje trasero\r\nPantalla curva de 16.8\"\r\nPorsche Electric Sport Sound', 24, '2026-10-10 17:59:21'),
(35, 'vehiculos', 1, 0, 'nuevo', 'Sedán eléctrico', 'assets/Catalogo/vehiculos/porsche/taycan-turbo.webp', NULL, 'Automática de 2 velocidades (eje trasero)', '670 hp', '3.2 s', 'El Taycan Turbo lleva la electrificación al límite del desempeño: dos motores, tracción integral y una aceleración contundente que se repite una y otra vez sin perder potencia.', 'Dos motores eléctricos y tracción integral\r\nLaunch Control con overboost\r\nSuspensión neumática adaptativa\r\nPorsche Dynamic Chassis Control\r\nCargador a bordo de 22 kW disponible\r\nInterior sin piel animal disponible', 25, '2026-10-10 17:59:21'),
(36, 'vehiculos', 1, 0, 'nuevo', 'Gran turismo', 'assets/Catalogo/vehiculos/porsche/panamera.webp', NULL, 'PDK de 8 velocidades', '325 hp', '5.6 s', 'El Porsche Panamera es el gran turismo de cuatro plazas que combina el confort de una limusina con el desempeño de un deportivo. Espacio, lujo y emoción para toda la familia.', 'Motor 2.9 V6 biturbo\r\nSuspensión neumática adaptativa de tres cámaras\r\nCuatro asientos individuales\r\nPorsche Advanced Cockpit\r\nPortón trasero eléctrico\r\nAsistente de visión nocturna disponible', 26, '2026-10-10 17:59:21'),
(37, 'vehiculos', 1, 0, 'nuevo', 'Gran turismo', 'assets/Catalogo/vehiculos/porsche/panamera-turbo.webp', NULL, 'PDK de 8 velocidades', '670 hp', '3.2 s', 'El Panamera Turbo representa la máxima expresión del gran turismo Porsche: potencia descomunal, tracción integral y una cabina de lujo artesanal. La forma más rápida de viajar en primera clase.', 'Motor V8 biturbo de alto desempeño\r\nTracción integral Porsche Traction Management\r\nPorsche Active Ride disponible\r\nInterior en piel extendida\r\nPantalla para el acompañante\r\nSistema de audio 3D de alta fidelidad', 27, '2026-10-10 17:59:21'),
(38, 'vehiculos', 1, 1, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/porsche/macan.webp', NULL, 'PDK de 7 velocidades', '261 hp', '6.2 s', 'El Porsche Macan es el deportivo de su segmento: una SUV compacta con la agilidad y la precisión de manejo que caracterizan a la marca. Versátil para la ciudad y emocionante en carretera.', 'Tracción integral Porsche Traction Management\r\nMotor 2.0 turbo\r\nTransmisión PDK de 7 velocidades\r\nPantalla táctil PCM de 10.9\"\r\nPortón trasero eléctrico\r\nModo Offroad', 28, '2026-10-10 17:59:21'),
(39, 'vehiculos', 1, 0, 'nuevo', 'SUV', 'assets/Catalogo/vehiculos/porsche/cayenne.webp', NULL, 'Tiptronic S de 8 velocidades', '335 hp', '5.9 s', 'El Porsche Cayenne es la SUV que demostró que lujo, espacio y deportividad pueden convivir: interior amplio, gran capacidad de remolque y el manejo inconfundible de un Porsche.', 'Motor 3.0 V6 turbo\r\nTracción integral\r\nSuspensión neumática disponible\r\nCapacidad de remolque de hasta 3,500 kg\r\nCajuela de 772 litros\r\nPorsche InnoDrive con crucero adaptativo', 29, '2026-10-10 17:59:21'),
(40, 'vehiculos', 1, 0, 'nuevo', 'SUV coupé', 'assets/Catalogo/vehiculos/porsche/cayenne-turbo.webp', NULL, 'Tiptronic S de 8 velocidades', '541 hp', '3.9 s', 'El Cayenne Turbo combina la presencia de una SUV de lujo con la potencia de un V8 biturbo: aceleración de deportivo, tracción integral y un interior premium para cinco ocupantes.', 'Motor 4.0 V8 biturbo\r\nTracción integral\r\nPorsche Dynamic Chassis Control\r\nFrenos Porsche Surface Coated Brake\r\nEscape deportivo\r\nAsientos deportivos adaptativos de 18 posiciones', 30, '2026-10-10 17:59:21'),
(41, 'vehiculos', 1, 0, 'nuevo', 'Superdeportiva', 'assets/Catalogo/vehiculos/ducati/panigale-v2.webp', NULL, '6 velocidades con Ducati Quick Shift', '155 hp', '3.2 s', 'La Ducati Panigale V2 es la superdeportiva bicilíndrica que ofrece las sensaciones de la familia Panigale con un carácter más ligero y accesible. Ideal para dar el salto a la pista.', 'Motor Superquadro bicilíndrico de 955 cc\r\nDucati Quick Shift up & down\r\nControl de tracción y ABS en curva\r\nPantalla TFT a color\r\nBasculante monobrazo\r\nModos de manejo Race, Sport y Street', 31, '2026-10-10 17:59:21'),
(42, 'vehiculos', 1, 1, 'nuevo', 'Superdeportiva', 'assets/Catalogo/vehiculos/ducati/panigale-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '215 hp', '2.9 s', 'La Panigale V4 traslada la tecnología de MotoGP a la calle: motor Desmosedici Stradale V4 de 1,103 cc, aerodinámica con alerones y un paquete electrónico de última generación.', 'Motor Desmosedici Stradale V4 de 1,103 cc\r\nAlerones aerodinámicos de doble perfil\r\nDucati Traction Control y Slide Control\r\nLaunch Control\r\nPantalla TFT de 5\"\r\nChasis Front Frame de aluminio', 32, '2026-10-10 17:59:21'),
(43, 'vehiculos', 1, 0, 'nuevo', 'Superdeportiva', 'assets/Catalogo/vehiculos/ducati/panigale-v4-s.webp', NULL, '6 velocidades con Ducati Quick Shift', '216 hp', '2.8 s', 'La Panigale V4 S suma suspensiones electrónicas Öhlins, rines forjados y batería de litio a la fórmula de la Panigale V4. Es la referencia para quienes buscan el máximo desempeño en pista.', 'Suspensiones electrónicas Öhlins Smart EC 2.0\r\nRines forjados de aluminio\r\nBatería de iones de litio\r\nFrenos Brembo Stylema\r\nABS Cornering EVO\r\nPeso reducido en orden de marcha', 33, '2026-10-10 17:59:21'),
(44, 'vehiculos', 1, 1, 'nuevo', 'Naked', 'assets/Catalogo/vehiculos/ducati/monster.webp', NULL, '6 velocidades con Ducati Quick Shift', '111 hp', '3.6 s', 'La Ducati Monster es la naked deportiva que inventó un segmento: ligera, ágil y con un motor Testastretta de carácter vibrante. Perfecta para el uso diario y la diversión del fin de semana.', 'Motor Testastretta 11° de 937 cc\r\n188 kg en orden de marcha\r\nDucati Quick Shift\r\nControl de tracción y ABS en curva\r\nTablero TFT de 4.3\"\r\nAsiento de altura ajustable', 34, '2026-10-10 17:59:21'),
(45, 'vehiculos', 1, 0, 'nuevo', 'Naked', 'assets/Catalogo/vehiculos/ducati/monster-sp.webp', NULL, '6 velocidades con Ducati Quick Shift', '111 hp', '3.5 s', 'La Monster SP es la versión más deportiva de la Monster: suspensiones Öhlins, escape deportivo homologado y frenos Brembo Stylema para un manejo aún más preciso.', 'Suspensiones Öhlins totalmente ajustables\r\nFrenos Brembo Stylema\r\nEscape deportivo homologado\r\nBatería de litio\r\nAmortiguador de dirección\r\nGráficos SP exclusivos', 35, '2026-10-10 17:59:21'),
(46, 'vehiculos', 1, 0, 'nuevo', 'Adventure touring', 'assets/Catalogo/vehiculos/ducati/multistrada-v2.webp', NULL, '6 velocidades con Ducati Quick Shift', '113 hp', '3.9 s', 'La Multistrada V2 es la compañera ideal para viajar: posición de manejo cómoda, buena protección aerodinámica y un motor Testastretta suave y elástico. Varias motos en una para cualquier tipo de camino.', 'Motor Testastretta de 937 cc\r\nParabrisas ajustable\r\nCuatro modos de manejo\r\nControl de crucero\r\nAsiento de altura ajustable\r\nPreparada para maletas laterales', 36, '2026-10-10 17:59:21'),
(47, 'vehiculos', 1, 1, 'nuevo', 'Adventure touring', 'assets/Catalogo/vehiculos/ducati/multistrada-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '170 hp', '3.3 s', 'La Multistrada V4 combina un motor V4 Granturismo de 170 hp con radar delantero y trasero para una experiencia de viaje segura y tecnológica. Lista para cruzar continentes.', 'Motor V4 Granturismo de 1,158 cc\r\nRadar delantero y trasero con crucero adaptativo\r\nPantalla TFT de 6.5\" con navegación\r\nSuspensión semiactiva Skyhook\r\nServicio de válvulas cada 60,000 km\r\nFaros full LED con luz de curva', 37, '2026-10-10 17:59:21'),
(48, 'vehiculos', 1, 0, 'nuevo', 'Power cruiser', 'assets/Catalogo/vehiculos/ducati/diavel-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '168 hp', '2.6 s', 'La Diavel V4 es la power cruiser más deportiva: diseño musculoso, motor V4 Granturismo y la capacidad de acelerar como una superdeportiva con la comodidad de una cruiser.', 'Motor V4 Granturismo de 1,158 cc\r\nLlanta trasera de 240 mm\r\nDucati Power Launch\r\nEscape de cuatro salidas\r\nIluminación full LED con firma distintiva\r\nPosición de manejo relajada', 38, '2026-10-10 17:59:21'),
(49, 'vehiculos', 1, 0, 'nuevo', 'Naked deportiva', 'assets/Catalogo/vehiculos/ducati/streetfighter-v2.webp', NULL, '6 velocidades con Ducati Quick Shift', '153 hp', '3.1 s', 'La Streetfighter V2 es una superdeportiva sin carenado: motor Superquadro de 955 cc, manubrio ancho y un diseño agresivo inspirado en la Panigale. Adrenalina pura para la calle.', 'Motor Superquadro de 955 cc\r\nManubrio ancho de aluminio\r\nBasculante monobrazo\r\nControl de wheelie\r\nFrenos Brembo de anclaje radial\r\nPantalla TFT a color', 39, '2026-10-10 17:59:21'),
(50, 'vehiculos', 1, 1, 'nuevo', 'Naked deportiva', 'assets/Catalogo/vehiculos/ducati/streetfighter-v4.webp', NULL, '6 velocidades con Ducati Quick Shift', '208 hp', '2.9 s', 'La Streetfighter V4 es una Panigale sin carenado: motor Desmosedici Stradale de 208 hp, alerones biplano y un paquete electrónico de competencia en una naked de diseño inconfundible.', 'Motor Desmosedici Stradale V4 de 1,103 cc\r\nAlerones biplano\r\nControl de tracción y wheelie EVO\r\nFaros full LED con firma frontal distintiva\r\nDucati Quick Shift EVO\r\nPantalla TFT de 5\"', 40, '2026-10-10 17:59:21'),
(51, 'vehiculos', 1, 0, 'nuevo', 'Scrambler', 'assets/Catalogo/vehiculos/ducati/scrambler-icon.webp', NULL, '6 velocidades', '73 hp', '4.6 s', 'La Scrambler Icon es sinónimo de libertad: estilo atemporal, motor bicilíndrico enfriado por aire fácil de manejar y una ergonomía amigable para todos los niveles. Perfecta para la ciudad y las escapadas.', 'Motor L-Twin de 803 cc enfriado por aire\r\nPeso ligero y asiento bajo\r\nFaro con luz diurna en forma de X\r\nControl de tracción\r\nCubiertas de tanque intercambiables\r\nTablero digital', 41, '2026-10-10 17:59:21'),
(52, 'vehiculos', 1, 0, 'nuevo', 'Scrambler', 'assets/Catalogo/vehiculos/ducati/scrambler-nightshift.webp', NULL, '6 velocidades', '73 hp', '4.6 s', 'La Scrambler Nightshift interpreta el estilo café racer con un toque urbano: rines de rayos, manubrio plano y acabados oscuros que destacan en cualquier calle.', 'Rines de rayos\r\nManubrio plano\r\nEspejos en los extremos del manubrio\r\nMotor L-Twin de 803 cc\r\nAsiento con tapizado especial\r\nAcabados en color oscuro', 42, '2026-10-10 17:59:21'),
(53, 'vehiculos', 1, 0, 'nuevo', 'Adventure off-road', 'assets/Catalogo/vehiculos/ducati/desertx.webp', NULL, '6 velocidades con Ducati Quick Shift', '110 hp', '3.9 s', 'La DesertX está inspirada en las legendarias motos de rally: rin delantero de 21\", suspensiones de largo recorrido y modos de manejo off-road para explorar más allá del asfalto.', 'Rin delantero de 21\" y trasero de 18\"\r\nSuspensiones de largo recorrido\r\nModos de manejo Rally y Enduro\r\nTanque de 21 litros\r\nPantalla TFT vertical\r\nProtector de motor de aluminio', 43, '2026-10-10 17:59:21'),
(54, 'vehiculos', 1, 0, 'nuevo', 'Motard', 'assets/Catalogo/vehiculos/ducati/hypermotard.webp', NULL, '6 velocidades con Ducati Quick Shift', '114 hp', '3.4 s', 'La Hypermotard es pura diversión: geometría de supermotard, posición elevada y un motor Testastretta que invita a jugar en cada curva. Ligera, divertida e irreverente.', 'Motor Testastretta de 937 cc\r\nEscape bajo el asiento\r\nSuspensiones de largo recorrido\r\nModo Slide by Brake\r\n178 kg en seco\r\nManubrio ancho de aluminio', 44, '2026-10-10 17:59:21'),
(55, 'vehiculos', 1, 0, 'nuevo', 'Sport touring', 'assets/Catalogo/vehiculos/ducati/supersport-950.webp', NULL, '6 velocidades con Ducati Quick Shift', '110 hp', '3.6 s', 'La SuperSport 950 es la deportiva de uso diario: posición de manejo cómoda, protección aerodinámica y un motor Testastretta suave. Ideal para quien quiere estilo deportivo con confort para viajar.', 'Motor Testastretta 11° de 937 cc\r\nParabrisas ajustable\r\nDiseño inspirado en la Panigale V4\r\nLuces de curva Ducati Cornering Lights\r\nPantalla TFT de 4.3\"\r\nAsiento confortable para dos personas', 45, '2026-10-10 17:59:21'),
(56, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/audi/filtro-aceite.webp', NULL, NULL, NULL, NULL, 'Filtro de aceite de alta eficiencia para Audi RS5. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.', 'Compatible con Audi RS5\r\nMedio filtrante de alta retención\r\nIncluye empaque de sellado\r\nReemplazo recomendado en cada servicio\r\nGarantía de 6 meses contra defectos de fabricación', 46, '2026-10-10 17:59:21'),
(57, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/audi/filtro-aire.webp', NULL, NULL, NULL, NULL, 'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Audi A7, protegiendo sus componentes y manteniendo el desempeño.', 'Compatible con Audi A7\r\nCelulosa reforzada de alta captación\r\nMarco de poliuretano flexible\r\nRevisión recomendada cada 15,000 km\r\nGarantía de 6 meses contra defectos de fabricación', 47, '2026-10-10 17:59:21'),
(58, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/pastillas-delanteras.webp', NULL, NULL, NULL, NULL, 'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Audi RS6. Frenado firme y silencioso desde la primera aplicación.', 'Compatible con Audi RS6\r\nCompuesto cerámico de bajo polvo\r\nIncluye láminas antirruido\r\nJuego para eje delantero\r\nGarantía de 6 meses contra defectos de fabricación', 48, '2026-10-10 17:59:21'),
(59, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/pastillas-traseras.webp', NULL, NULL, NULL, NULL, 'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Audi R8. Frenado estable y silencioso.', 'Compatible con Audi R8\r\nCompuesto cerámico de bajo polvo\r\nIncluye láminas antirruido\r\nJuego para eje trasero\r\nGarantía de 6 meses contra defectos de fabricación', 49, '2026-10-10 17:59:21'),
(60, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/disco-delantero.webp', NULL, NULL, NULL, NULL, 'Disco de freno delantero ventilado de hierro de alta resistencia para Audi RS3. Disipa el calor de forma eficiente y mantiene un frenado constante.', 'Compatible con Audi RS3\r\nDiseño ventilado y perforado\r\nTratamiento anticorrosión\r\nSe recomienda cambiar en pares\r\nGarantía de 6 meses contra defectos de fabricación', 50, '2026-10-10 17:59:21'),
(61, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/audi/disco-trasero.webp', NULL, NULL, NULL, NULL, 'Disco de freno trasero de hierro de alta resistencia para Audi RS3, balanceado para una operación sin vibraciones y con excelente disipación de calor.', 'Compatible con Audi RS3\r\nBalanceado de fábrica\r\nTratamiento anticorrosión\r\nSe recomienda cambiar en pares\r\nGarantía de 6 meses contra defectos de fabricación', 51, '2026-10-10 17:59:21'),
(62, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/audi/bujias.webp', NULL, NULL, NULL, NULL, 'Juego de bujías con electrodo de iridio para Audi A6. Encendido preciso, arranque confiable y consumo optimizado.', 'Compatible con Audi A6\r\nElectrodo central de iridio\r\nCalibración de fábrica\r\nJuego completo para el motor\r\nGarantía de 6 meses contra defectos de fabricación', 52, '2026-10-10 17:59:21'),
(63, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/audi/bateria.webp', NULL, NULL, NULL, NULL, 'Batería de 12 V libre de mantenimiento para Audi RS6, con alta capacidad de arranque en frío y construcción resistente a vibraciones.', 'Compatible con Audi RS6\r\n12 V libre de mantenimiento\r\nAlta corriente de arranque en frío\r\nInstalación incluida en sucursal\r\nGarantía de 6 meses contra defectos de fabricación', 53, '2026-10-10 17:59:21'),
(64, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/audi/kit-distribucion.webp', NULL, NULL, NULL, NULL, 'Kit de distribución completo para Audi RS6: incluye banda, tensor y poleas para garantizar la sincronización exacta del motor.', 'Compatible con Audi RS6\r\nIncluye banda, tensor y poleas\r\nInstalación recomendada en taller\r\nReemplazo preventivo según kilometraje\r\nGarantía de 6 meses contra defectos de fabricación', 54, '2026-10-10 17:59:21'),
(65, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/audi/bomba-agua.webp', NULL, NULL, NULL, NULL, 'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Audi R8. Mantiene la temperatura óptima de operación del motor.', 'Compatible con Audi R8\r\nCarcasa de aluminio\r\nImpulsor de alto flujo\r\nIncluye empaque\r\nGarantía de 6 meses contra defectos de fabricación', 55, '2026-10-10 17:59:21'),
(66, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/porsche/filtro-aceite.webp', NULL, NULL, NULL, NULL, 'Filtro de aceite de alta eficiencia para Porsche 911 GT3. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.', 'Compatible con Porsche 911 GT3\r\nMedio filtrante de alta retención\r\nIncluye empaque de sellado\r\nReemplazo recomendado en cada servicio\r\nGarantía de 6 meses contra defectos de fabricación', 56, '2026-10-10 17:59:21'),
(67, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/porsche/filtro-aire.webp', NULL, NULL, NULL, NULL, 'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Porsche 718 Boxster, protegiendo sus componentes y manteniendo el desempeño.', 'Compatible con Porsche 718 Boxster\r\nCelulosa reforzada de alta captación\r\nMarco de poliuretano flexible\r\nRevisión recomendada cada 15,000 km\r\nGarantía de 6 meses contra defectos de fabricación', 57, '2026-10-10 17:59:21'),
(68, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/pastillas-delanteras.webp', NULL, NULL, NULL, NULL, 'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Porsche Cayenne Turbo. Frenado firme y silencioso desde la primera aplicación.', 'Compatible con Porsche Cayenne Turbo\r\nCompuesto cerámico de bajo polvo\r\nIncluye láminas antirruido\r\nJuego para eje delantero\r\nGarantía de 6 meses contra defectos de fabricación', 58, '2026-10-10 17:59:21'),
(69, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/pastillas-traseras.webp', NULL, NULL, NULL, NULL, 'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Porsche Macan. Frenado estable y silencioso.', 'Compatible con Porsche Macan\r\nCompuesto cerámico de bajo polvo\r\nIncluye láminas antirruido\r\nJuego para eje trasero\r\nGarantía de 6 meses contra defectos de fabricación', 59, '2026-10-10 17:59:21'),
(70, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/disco-delantero.webp', NULL, NULL, NULL, NULL, 'Disco de freno delantero ventilado de hierro de alta resistencia para Porsche 718 Cayman. Disipa el calor de forma eficiente y mantiene un frenado constante.', 'Compatible con Porsche 718 Cayman\r\nDiseño ventilado y perforado\r\nTratamiento anticorrosión\r\nSe recomienda cambiar en pares\r\nGarantía de 6 meses contra defectos de fabricación', 60, '2026-10-10 17:59:21'),
(71, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/porsche/disco-trasero.webp', NULL, NULL, NULL, NULL, 'Disco de freno trasero de hierro de alta resistencia para Porsche Taycan Turbo, balanceado para una operación sin vibraciones y con excelente disipación de calor.', 'Compatible con Porsche Taycan Turbo\r\nBalanceado de fábrica\r\nTratamiento anticorrosión\r\nSe recomienda cambiar en pares\r\nGarantía de 6 meses contra defectos de fabricación', 61, '2026-10-10 17:59:21'),
(72, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/porsche/bujias.webp', NULL, NULL, NULL, NULL, 'Juego de bujías con electrodo de iridio para Porsche 718 Boxster. Encendido preciso, arranque confiable y consumo optimizado.', 'Compatible con Porsche 718 Boxster\r\nElectrodo central de iridio\r\nCalibración de fábrica\r\nJuego completo para el motor\r\nGarantía de 6 meses contra defectos de fabricación', 62, '2026-10-10 17:59:21'),
(73, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/porsche/bateria.webp', NULL, NULL, NULL, NULL, 'Batería de 12 V libre de mantenimiento para Porsche Cayenne, con alta capacidad de arranque en frío y construcción resistente a vibraciones.', 'Compatible con Porsche Cayenne\r\n12 V libre de mantenimiento\r\nAlta corriente de arranque en frío\r\nInstalación incluida en sucursal\r\nGarantía de 6 meses contra defectos de fabricación', 63, '2026-10-10 17:59:21'),
(74, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/porsche/kit-distribucion.webp', NULL, NULL, NULL, NULL, 'Kit de distribución completo para Porsche Macan: incluye banda, tensor y poleas para garantizar la sincronización exacta del motor.', 'Compatible con Porsche Macan\r\nIncluye banda, tensor y poleas\r\nInstalación recomendada en taller\r\nReemplazo preventivo según kilometraje\r\nGarantía de 6 meses contra defectos de fabricación', 64, '2026-10-10 17:59:21'),
(75, 'refacciones', 1, 0, 'nuevo', 'Motor', 'assets/Catalogo/refacciones/porsche/bomba-agua.webp', NULL, NULL, NULL, NULL, 'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Porsche 911 Carrera. Mantiene la temperatura óptima de operación del motor.', 'Compatible con Porsche 911 Carrera\r\nCarcasa de aluminio\r\nImpulsor de alto flujo\r\nIncluye empaque\r\nGarantía de 6 meses contra defectos de fabricación', 65, '2026-10-10 17:59:21'),
(76, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/ducati/filtro-aceite.webp', NULL, NULL, NULL, NULL, 'Filtro de aceite de alta eficiencia para Ducati Diavel V4. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.', 'Compatible con Ducati Diavel V4\r\nMedio filtrante de alta retención\r\nIncluye empaque de sellado\r\nReemplazo recomendado en cada servicio\r\nGarantía de 6 meses contra defectos de fabricación', 66, '2026-10-10 17:59:21'),
(77, 'refacciones', 1, 0, 'nuevo', 'Filtros', 'assets/Catalogo/refacciones/ducati/filtro-aire.webp', NULL, NULL, NULL, NULL, 'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Ducati Panigale V4 S, protegiendo sus componentes y manteniendo el desempeño.', 'Compatible con Ducati Panigale V4 S\r\nCelulosa reforzada de alta captación\r\nMarco de poliuretano flexible\r\nRevisión recomendada cada 15,000 km\r\nGarantía de 6 meses contra defectos de fabricación', 67, '2026-10-10 17:59:21'),
(78, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/ducati/pastillas-delanteras.webp', NULL, NULL, NULL, NULL, 'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Ducati Hypermotard. Frenado firme y silencioso desde la primera aplicación.', 'Compatible con Ducati Hypermotard\r\nCompuesto cerámico de bajo polvo\r\nIncluye láminas antirruido\r\nJuego para eje delantero\r\nGarantía de 6 meses contra defectos de fabricación', 68, '2026-10-10 17:59:21'),
(79, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/ducati/pastillas-traseras.webp', NULL, NULL, NULL, NULL, 'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Ducati Monster. Frenado estable y silencioso.', 'Compatible con Ducati Monster\r\nCompuesto cerámico de bajo polvo\r\nIncluye láminas antirruido\r\nJuego para eje trasero\r\nGarantía de 6 meses contra defectos de fabricación', 69, '2026-10-10 17:59:21'),
(80, 'refacciones', 1, 0, 'nuevo', 'Frenos', 'assets/Catalogo/refacciones/ducati/disco-delantero.webp', NULL, NULL, NULL, NULL, 'Disco de freno delantero ventilado de hierro de alta resistencia para Ducati DesertX. Disipa el calor de forma eficiente y mantiene un frenado constante.', 'Compatible con Ducati DesertX\r\nDiseño ventilado y perforado\r\nTratamiento anticorrosión\r\nSe recomienda cambiar en pares\r\nGarantía de 6 meses contra defectos de fabricación', 70, '2026-10-10 17:59:21'),
(81, 'refacciones', 1, 0, 'nuevo', 'Transmisión', 'assets/Catalogo/refacciones/ducati/cadena-transmision.webp', NULL, NULL, NULL, NULL, 'Cadena de transmisión con retenes X-Ring para Ducati Monster. Mayor durabilidad y menor fricción al transmitir la potencia del motor a la rueda trasera.', 'Compatible con Ducati Monster\r\nRetenes X-Ring\r\nEslabón de unión remachable\r\nLubricación de larga duración\r\nGarantía de 6 meses contra defectos de fabricación', 71, '2026-10-10 17:59:21'),
(82, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/ducati/kit-bujias.webp', NULL, NULL, NULL, NULL, 'Juego de bujías con electrodo de iridio para Ducati Multistrada V4. Encendido preciso, arranque confiable y consumo optimizado.', 'Compatible con Ducati Multistrada V4\r\nElectrodo central de iridio\r\nCalibración de fábrica\r\nJuego completo para el motor\r\nGarantía de 6 meses contra defectos de fabricación', 72, '2026-10-10 17:59:21'),
(83, 'refacciones', 1, 0, 'nuevo', 'Encendido y eléctrico', 'assets/Catalogo/refacciones/ducati/bateria.webp', NULL, NULL, NULL, NULL, 'Batería de 12 V libre de mantenimiento para Ducati Scrambler Icon, con alta capacidad de arranque en frío y construcción resistente a vibraciones.', 'Compatible con Ducati Scrambler Icon\r\n12 V libre de mantenimiento\r\nAlta corriente de arranque en frío\r\nInstalación incluida en sucursal\r\nGarantía de 6 meses contra defectos de fabricación', 73, '2026-10-10 17:59:21'),
(84, 'refacciones', 1, 0, 'nuevo', 'Controles', 'assets/Catalogo/refacciones/ducati/maneta-freno-embrague.webp', NULL, NULL, NULL, NULL, 'Maneta de freno/embrague de aluminio anodizado con ajuste de distancia para Ducati SuperSport 950. Tacto preciso y ergonomía mejorada.', 'Compatible con Ducati SuperSport 950\r\nAluminio anodizado\r\nAjuste de distancia en 6 posiciones\r\nInstalación directa\r\nGarantía de 6 meses contra defectos de fabricación', 74, '2026-10-10 17:59:21'),
(85, 'refacciones', 1, 0, 'nuevo', 'Carrocería', 'assets/Catalogo/refacciones/ducati/espejo-retrovisor.webp', NULL, NULL, NULL, NULL, 'Espejo retrovisor con cristal antirreflejante y soporte reforzado para Ducati Panigale V4. Visibilidad amplia con diseño aerodinámico.', 'Compatible con Ducati Panigale V4\r\nCristal antirreflejante\r\nSoporte reforzado\r\nAjuste en varias posiciones\r\nGarantía de 6 meses contra defectos de fabricación', 75, '2026-10-10 17:59:21'),
(86, 'accesorios', 1, 0, 'nuevo', 'Interior', 'assets/Catalogo/accesorios/tapetes-audi.webp', NULL, NULL, NULL, NULL, 'Juego de tapetes de hule moldeados a la medida del Audi Q5. Sus bordes elevados retienen agua, lodo y arena, protegiendo la alfombra original en cualquier temporada.', 'Compatible con Audi Q5\r\nJuego de 4 piezas a la medida\r\nBordes elevados que contienen líquidos\r\nMaterial antiderrapante y fácil de lavar\r\nAnclajes de fijación originales', 76, '2026-10-10 17:59:21'),
(87, 'accesorios', 1, 0, 'nuevo', 'Exterior', 'assets/Catalogo/accesorios/barras-techo-audi.webp', NULL, NULL, NULL, NULL, 'Barras transversales de aluminio aerodinámico para el Audi Q3. Base ideal para portabicicletas, portaesquís o cajas de techo, con sistema de bloqueo antirrobo.', 'Compatible con Audi Q3\r\nPerfil aerodinámico de bajo ruido\r\nCapacidad de carga de 75 kg\r\nCerradura con llave antirrobo\r\nInstalación sin herramientas especiales', 77, '2026-10-10 17:59:21'),
(88, 'accesorios', 1, 0, 'nuevo', 'Organización', 'assets/Catalogo/accesorios/organizador-cajuela-audi.webp', NULL, NULL, NULL, NULL, 'Organizador plegable con divisiones ajustables que mantiene en orden las compras, herramientas y artículos deportivos dentro de la cajuela.', 'Compatible con Audi A4 / A6 / Q5\r\nDivisiones ajustables con velcro\r\nBase antiderrapante\r\nSe pliega cuando no se usa\r\nCompatible con A4, A6 y Q5', 78, '2026-10-10 17:59:21'),
(89, 'accesorios', 1, 0, 'nuevo', 'Protección', 'assets/Catalogo/accesorios/funda-interior-porsche.webp', NULL, NULL, NULL, NULL, 'Funda transpirable a la medida del Porsche 911 para uso en interior. Protege la pintura del polvo y los rayones mientras permite la circulación del aire.', 'Compatible con Porsche 911 (992)\r\nCorte a la medida del 911 (992)\r\nTejido suave y transpirable\r\nInterior afelpado que cuida la pintura\r\nIncluye bolsa de almacenamiento', 79, '2026-10-10 17:59:21'),
(90, 'accesorios', 1, 0, 'nuevo', 'Interior', 'assets/Catalogo/accesorios/tapetes-premium-porsche.webp', NULL, NULL, NULL, NULL, 'Tapetes de alfombra premium con ribete y respaldo antiderrapante, diseñados a la medida del Porsche Macan.', 'Compatible con Porsche Macan\r\nAlfombra de alta densidad\r\nRibete en piel sintética\r\nRespaldo antiderrapante\r\nJuego de 4 piezas', 80, '2026-10-10 17:59:21'),
(91, 'accesorios', 1, 0, 'nuevo', 'Carga eléctrica', 'assets/Catalogo/accesorios/cargador-portatil-porsche.webp', NULL, NULL, NULL, NULL, 'Cargador portátil de hasta 11 kW con conector Tipo 2 para el Porsche Taycan. Permite cargar en casa o en cualquier contacto industrial compatible.', 'Compatible con Porsche Taycan\r\nPotencia de carga de hasta 11 kW\r\nConector Tipo 2\r\nCable de 7.5 metros\r\nEstuche de transporte incluido', 81, '2026-10-10 17:59:21'),
(92, 'accesorios', 1, 0, 'nuevo', 'Equipaje', 'assets/Catalogo/accesorios/maletas-laterales-ducati.webp', NULL, NULL, NULL, NULL, 'Par de maletas laterales rígidas de aluminio con cierre hermético para la Multistrada V4. Capacidad suficiente para viajes largos con total protección contra la lluvia.', 'Compatible con Ducati Multistrada V4\r\nCapacidad de 30 y 37 litros\r\nAluminio anodizado resistente\r\nCierre hermético con llave\r\nSoportes de liberación rápida', 82, '2026-10-10 17:59:21'),
(93, 'accesorios', 1, 0, 'nuevo', 'Exterior', 'assets/Catalogo/accesorios/parabrisas-touring-ducati.webp', NULL, NULL, NULL, NULL, 'Parabrisas touring de mayor altura que reduce la turbulencia y la fatiga en viajes largos. Policarbonato resistente a impactos con tratamiento antirrayas.', 'Compatible con Ducati Multistrada V2 / V4\r\nPolicarbonato de 4 mm\r\nTratamiento antirrayas\r\n60 mm más alto que el original\r\nCompatible con Multistrada V2 y V4', 83, '2026-10-10 17:59:21'),
(94, 'accesorios', 1, 0, 'nuevo', 'Protección', 'assets/Catalogo/accesorios/funda-moto-ducati.webp', NULL, NULL, NULL, NULL, 'Funda de exterior impermeable con protección UV y forro suave. Mantiene tu Ducati limpia y protegida del sol, la lluvia y el polvo.', 'Compatible con Ducati Panigale / Streetfighter\r\nTela impermeable con protección UV\r\nForro interior suave\r\nOrificios para candado\r\nBolsa de transporte incluida', 84, '2026-10-10 17:59:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `promociones`
--

CREATE TABLE `promociones` (
  `id_promocion` int(11) NOT NULL,
  `clave` varchar(40) NOT NULL,
  `titulo` varchar(150) NOT NULL,
  `subtitulo` varchar(200) DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `tipo` enum('vehiculos','refacciones','servicio','financiamiento','accesorios') NOT NULL,
  `marca` varchar(80) DEFAULT NULL,
  `etiqueta` varchar(40) DEFAULT NULL,
  `imagen` varchar(255) DEFAULT NULL,
  `condiciones` text DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `cta_texto` varchar(60) DEFAULT NULL,
  `cta_url` varchar(255) DEFAULT NULL,
  `activa` tinyint(1) NOT NULL DEFAULT 1,
  `orden` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `promociones`
--

INSERT INTO `promociones` (`id_promocion`, `clave`, `titulo`, `subtitulo`, `descripcion`, `tipo`, `marca`, `etiqueta`, `imagen`, `condiciones`, `fecha_inicio`, `fecha_fin`, `cta_texto`, `cta_url`, `activa`, `orden`) VALUES
(1, 'audi-q5-bono', 'Bono de $40,000 en Audi Q5', 'SUV mediana con tracción quattro', 'Estrena tu Audi Q5 2025 con un bono aplicable al cerrar tu compra en cualquiera de nuestras sucursales.', 'vehiculos', 'Audi', 'Bono $40,000', 'assets/Catalogo/vehiculos/audi/q5.webp', 'Promoción de demostración del proyecto académico KARMA. Aplica sobre precio de lista, sujeta a disponibilidad de inventario en la sucursal.', '2026-10-01', '2026-12-31', 'Ver Audi Q5', 'vehiculo.php?codigo=KRM-CAT-AUDI-08', 1, 1),
(2, 'porsche-macan-tasa', 'Tasa preferencial desde 11.9% en Porsche Macan', 'Plan de crédito KARMA Financial', 'Financia tu Porsche Macan con una tasa preferencial y plazos de hasta 60 meses. Simula tu mensualidad en línea.', 'financiamiento', 'Porsche', '11.9% anual', 'assets/Catalogo/vehiculos/porsche/macan.webp', 'Promoción de demostración. Tasa fija anual de referencia con enganche mínimo del 20%; sujeta a aprobación de crédito.', '2026-10-01', '2026-12-31', 'Simular financiamiento', 'financiamiento.php?codigo=KRM-CAT-POR-13&tasa=11.9', 1, 2),
(3, 'ducati-multistrada-maletas', 'Maletas laterales con 15% al estrenar tu Multistrada V4', 'Listo para viajar desde el primer día', 'Al comprar tu Ducati Multistrada V4 obtén 15% de descuento en el juego de maletas laterales rígidas.', 'accesorios', 'Ducati', '-15% accesorios', 'assets/Catalogo/accesorios/maletas-laterales-ducati.webp', 'Promoción de demostración. Aplica en sucursal al momento de la compra de la motocicleta.', '2026-10-01', '2026-12-31', 'Ver Multistrada V4', 'vehiculo.php?codigo=KRM-CAT-DUC-07', 1, 3),
(4, 'servicio-aceite', 'Cambio de aceite y filtro desde $2,490', 'Servicio express en menos de 90 minutos', 'Incluye aceite sintético de especificación de fábrica, filtro nuevo y revisión de 25 puntos.', 'servicio', NULL, 'Desde $2,490', 'assets/Catalogo/servicios/cambio-aceite.webp', 'Promoción de demostración. Precio de referencia para autos de hasta 6 litros de aceite; motocicletas desde $1,690.', '2026-10-01', '2026-12-31', 'Agendar servicio', 'agendar.php?tipo=servicio&servicio=Cambio%20de%20aceite%20y%20filtro', 1, 4),
(5, 'servicio-frenos', 'Revisión de frenos sin costo', 'Tu seguridad primero', 'Medimos el espesor de pastillas y discos, revisamos el líquido de frenos y te entregamos un diagnóstico por escrito.', 'servicio', NULL, 'Sin costo', 'assets/Catalogo/servicios/frenos.webp', 'Promoción de demostración. Una revisión por vehículo durante la vigencia; requiere cita previa.', '2026-10-01', '2026-11-30', 'Agendar revisión', 'agendar.php?tipo=servicio&servicio=Servicio%20de%20frenos', 1, 5),
(6, 'refacciones-instalacion', 'Instalación sin costo en pastillas y discos', 'Compra en línea, instala en nuestro taller', 'Compra tus pastillas o discos de freno en línea, recoge en sucursal y nuestro taller los instala sin costo de mano de obra.', 'refacciones', NULL, 'Instalación gratis', 'assets/Catalogo/refacciones/porsche/disco-delantero.webp', 'Promoción de demostración. Requiere cita de servicio en la misma sucursal donde se recoge el pedido.', '2026-10-01', '2026-12-31', 'Ver refacciones de frenos', 'refacciones.php?categoria=Frenos', 1, 6),
(7, 'envio-gratis', 'Envío gratis en compras desde $3,000', 'Refacciones y accesorios a domicilio', 'Tus refacciones y accesorios llegan a domicilio sin costo de envío cuando tu pedido es de $3,000 o más.', 'accesorios', NULL, 'Envío gratis', 'assets/Catalogo/accesorios/tapetes-audi.webp', 'Promoción de demostración. Aplica automáticamente en el checkout para pedidos con envío y pago con tarjeta.', '2026-10-01', '2026-12-31', 'Ver accesorios', 'accesorios.php', 1, 7),
(8, 'prueba-manejo-kit', 'Agenda tu prueba de manejo y recibe un kit de bienvenida', 'Vive la experiencia antes de decidir', 'Agenda en línea tu prueba de manejo en Manzanillo o Colima y llévate un kit de bienvenida KARMA.', 'vehiculos', NULL, 'Regalo', 'assets/Catalogo/banners/prueba-manejo.webp', 'Promoción de demostración. Un kit por cliente; sujeto a existencias en la sucursal.', '2026-10-01', '2026-12-31', 'Agendar prueba de manejo', 'agendar.php?tipo=prueba_manejo', 1, 8);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id_rol` int(11) NOT NULL,
  `nombre_rol` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id_rol`, `nombre_rol`) VALUES
(1, 'Administrador General'),
(3, 'Cajero'),
(2, 'Gerente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `solicitudes`
--

CREATE TABLE `solicitudes` (
  `id_solicitud` int(11) NOT NULL,
  `folio` varchar(20) DEFAULT NULL,
  `tipo` enum('informacion','cotizacion','contacto','queja','sugerencia','garantia','seguro','financiamiento','seminuevo','postventa','otro') NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `id_sucursal` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `nombre` varchar(150) NOT NULL,
  `email` varchar(120) NOT NULL,
  `telefono` varchar(30) DEFAULT NULL,
  `asunto` varchar(150) DEFAULT NULL,
  `mensaje` text DEFAULT NULL,
  `datos` text DEFAULT NULL,
  `estado` enum('nueva','en_proceso','atendida','cerrada') NOT NULL DEFAULT 'nueva',
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `solicitudes_garantia`
--

CREATE TABLE `solicitudes_garantia` (
  `id_solicitud` int(11) NOT NULL,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-SG-{sucursal}-{id}',
  `id_garantia` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL COMMENT 'Sucursal donde se levantó la solicitud',
  `id_usuario_solicita` int(11) NOT NULL COMMENT 'Cajero que llenó el formulario (autenticado con su gafete)',
  `estado` enum('pendiente','confirmada','denegada') NOT NULL DEFAULT 'pendiente',
  `motivo_rechazo` varchar(500) DEFAULT NULL COMMENT 'Obligatorio cuando el gerente la deniega',
  `id_usuario_resuelve` int(11) DEFAULT NULL COMMENT 'Gerente o administrador que la confirmó o denegó',
  `datos_json` longtext NOT NULL COMMENT 'Campos del formulario: VIN, kilometraje, síntoma, condiciones, evidencia, etc.',
  `fecha_solicitud` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_resolucion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Solicitudes de garantía levantadas en caja; las confirma o deniega un gerente';

--
-- Disparadores `solicitudes_garantia`
--
DELIMITER $$
CREATE TRIGGER `trg_solicitudes_garantia_aplicada` AFTER UPDATE ON `solicitudes_garantia` FOR EACH ROW BEGIN
    IF NEW.estado = 'confirmada' AND OLD.estado = 'pendiente' THEN
        UPDATE garantias SET estado = 'aplicada' WHERE id_garantia = NEW.id_garantia;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_solicitudes_garantia_nueva` BEFORE INSERT ON `solicitudes_garantia` FOR EACH ROW BEGIN
    SET NEW.estado = 'pendiente', NEW.id_usuario_resuelve = NULL, NEW.fecha_resolucion = NULL, NEW.motivo_rechazo = NULL;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_solicitudes_garantia_resolver` BEFORE UPDATE ON `solicitudes_garantia` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursales`
--

CREATE TABLE `sucursales` (
  `id_sucursal` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `ciudad` varchar(80) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `horario_ventas` varchar(150) DEFAULT NULL,
  `horario_servicio` varchar(150) DEFAULT NULL,
  `servicios` varchar(500) DEFAULT NULL,
  `imagen` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sucursales`
--

INSERT INTO `sucursales` (`id_sucursal`, `nombre`, `direccion`, `telefono`, `estado`, `ciudad`, `email`, `horario_ventas`, `horario_servicio`, `servicios`, `imagen`) VALUES
(1, 'Manzanillo', 'Av. Miguel de la Madrid 100, Manzanillo, Colima', '3140000000', 'activo', 'Manzanillo', 'manzanillo@karma.local', 'Lunes a viernes 9:00–19:00 · Sábado 9:00–14:00', 'Lunes a viernes 8:00–18:00 · Sábado 8:00–13:00', 'Venta de vehículos nuevos,Simulación de crédito,Apartado de vehículos,Seguros,Gestoría de placas y trámites,Garantía extendida,Plan de mantenimiento prepagado,Accesorios originales e instalación,Polarizado,Orden de servicio de taller,Refacciones originales', 'assets/Catalogo/sucursales/manzanillo.webp'),
(2, 'Colima', 'Av. Constitución 1500, Colima, Colima', '3120000000', 'activo', 'Colima', 'colima@karma.local', 'Lunes a viernes 9:00–19:00 · Sábado 9:00–14:00', 'Lunes a viernes 8:00–18:00 · Sábado 8:00–13:00', 'Venta de vehículos nuevos,Prueba de manejo,Financiamiento,Servicio y mantenimiento,Refacciones originales,Accesorios,Garantía,Seminuevos', 'assets/Catalogo/sucursales/colima.webp');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `id_sucursal` int(11) DEFAULT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellidos` varchar(100) DEFAULT NULL COMMENT 'Apellidos del empleado (nombre completo = nombre + apellidos)',
  `correo` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `idioma_pref` enum('es','en') NOT NULL DEFAULT 'es',
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `id_rol`, `id_sucursal`, `nombre`, `apellidos`, `correo`, `password_hash`, `idioma_pref`, `estado`) VALUES
(1, 3, 1, 'Miranda', NULL, 'miranda@karma.local', '$2y$12$69yS9OJm0dBEBU1GlzIRkePfwIRRfNnSpeB1LAkOLSF0vHQRYh0yG', 'es', 'activo'),
(2, 1, 1, 'Admin', NULL, 'admin@karma.com', '$2y$12$lrzROyFQlVjXN7Ngei1rFuSfrP.VHr/7mBMWWHlWTzev57F2jVGEm', 'es', 'activo'),
(3, 3, 1, 'Cajero Prueba Manzanillo', NULL, 'cajero.manzanillo@karma.local', '$2y$12$mVz.S6d98f4eCSYludtyM.UmH.Qy1mtbEV0CWH4i55.kkibFQJAZy', 'es', 'activo'),
(4, 3, 1, 'Cajero Prueba QR', NULL, 'cajero.qr@karma.local', '$2y$12$wsPtHl8g5LMv6plaMo7owe3pcYxkqxwjis7/tDVS3QnDdgnJOkipm', 'es', 'activo'),
(5, 2, 1, 'Gerente Prueba QR', NULL, 'gerente.qr@karma.local', '$2y$12$19YSbu6g5IcuzYETfw0a4uY1svHQlzLAjKCRuLa55Ro0VCIZN2Fne', 'es', 'activo'),
(6, 3, 1, 'Cajero Prueba QR Inactivo', NULL, 'inactivo.qr@karma.local', '$2y$12$wLW/QZeiMYhQQIh1kky.Ve9/88PYimfEwl/3aBMFqKKI.d2csrUQG', 'es', 'inactivo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id_venta` int(11) NOT NULL,
  `id_sucursal` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_caja` int(11) NOT NULL,
  `id_metodo_pago` int(11) NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `subtotal` decimal(10,2) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `efectivo_recibido` decimal(12,2) DEFAULT NULL,
  `cambio` decimal(12,2) DEFAULT NULL,
  `ticket_numero` int(11) DEFAULT NULL,
  `total_conceptos` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Parte del total que corresponde a conceptos de caja (ventas_conceptos)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas_conceptos`
--

CREATE TABLE `ventas_conceptos` (
  `id_venta_concepto` int(11) NOT NULL,
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
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de cobro y desglose de los conceptos de caja';

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `v_conceptos_cobrados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `v_conceptos_cobrados` (
`id_venta_concepto` int(11)
,`folio` varchar(30)
,`fecha_hora` datetime
,`sucursal` varchar(100)
,`id_caja` int(11)
,`cajero` varchar(100)
,`clave` varchar(40)
,`concepto` varchar(120)
,`grupo` varchar(60)
,`plan` varchar(150)
,`id_venta` int(11)
,`folio_venta` varchar(13)
,`vin` varchar(17)
,`vehiculo_descripcion` varchar(150)
,`referencia` varchar(80)
,`base_calculo` decimal(14,2)
,`porcentaje` decimal(9,4)
,`importe_gravado` decimal(12,2)
,`importe_exento` decimal(12,2)
,`importe_accesorio` decimal(12,2)
,`subtotal` decimal(12,2)
,`iva` decimal(12,2)
,`total` decimal(12,2)
,`vigencia_inicio` date
,`vigencia_fin` date
,`estado` enum('cobrado','cancelado')
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `web_orders`
--

CREATE TABLE `web_orders` (
  `id_orden` int(11) NOT NULL,
  `tipo` enum('vehiculo','refaccion') NOT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `nombre` varchar(150) NOT NULL,
  `celular` varchar(30) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `enganche` decimal(12,2) DEFAULT NULL,
  `fecha_visita` datetime DEFAULT NULL,
  `color` varchar(80) DEFAULT NULL,
  `pieza` varchar(150) DEFAULT NULL,
  `modelo_compatibilidad` varchar(150) DEFAULT NULL,
  `marca_vehiculo` varchar(80) DEFAULT NULL,
  `motor` varchar(120) DEFAULT NULL,
  `cilindraje` varchar(80) DEFAULT NULL,
  `traccion` varchar(80) DEFAULT NULL,
  `transmision` varchar(100) DEFAULT NULL,
  `lado` varchar(50) DEFAULT NULL,
  `estado` enum('pendiente','atendida','cancelada') NOT NULL DEFAULT 'pendiente',
  `folio` varchar(20) DEFAULT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `id_sucursal` int(11) DEFAULT NULL,
  `metodo_entrega` enum('recoger','envio') DEFAULT NULL,
  `id_metodo_pago` int(11) DEFAULT NULL,
  `estado_pago` enum('pendiente','pagado','reembolsado') NOT NULL DEFAULT 'pendiente',
  `subtotal` decimal(12,2) DEFAULT NULL,
  `costo_envio` decimal(12,2) DEFAULT NULL,
  `total` decimal(12,2) DEFAULT NULL,
  `direccion_envio` varchar(400) DEFAULT NULL,
  `tarjeta_marca` varchar(20) DEFAULT NULL,
  `tarjeta_ultimos4` char(4) DEFAULT NULL,
  `referencia_pago` varchar(40) DEFAULT NULL,
  `stock_reservado` tinyint(1) NOT NULL DEFAULT 0,
  `comentarios` varchar(500) DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT NULL,
  `fecha_pago` datetime DEFAULT NULL,
  `id_venta` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `web_orders`
--

INSERT INTO `web_orders` (`id_orden`, `tipo`, `id_producto`, `nombre`, `celular`, `email`, `enganche`, `fecha_visita`, `color`, `pieza`, `modelo_compatibilidad`, `marca_vehiculo`, `motor`, `cilindraje`, `traccion`, `transmision`, `lado`, `estado`, `folio`, `id_cliente`, `id_sucursal`, `metodo_entrega`, `id_metodo_pago`, `estado_pago`, `subtotal`, `costo_envio`, `total`, `direccion_envio`, `tarjeta_marca`, `tarjeta_ultimos4`, `referencia_pago`, `stock_reservado`, `comentarios`, `fecha_creacion`, `fecha_pago`, `id_venta`) VALUES
(1, 'vehiculo', 4, 'Daniela Ruiz Ponce', '314 222 3344', 'daniela.ruiz@email.com', 500000.00, '2026-09-18 11:30:00', 'Blanco Carrara', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'pendiente', NULL, NULL, NULL, NULL, NULL, 'pendiente', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL),
(2, 'vehiculo', 8, 'Iñaki Torres Vega', '314 555 6677', 'inaki.torres@email.com', NULL, '2026-09-19 16:00:00', 'Negro Mate', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'pendiente', NULL, NULL, NULL, NULL, NULL, 'pendiente', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL),
(3, 'refaccion', 9, 'Carlos Beltrán Ibarra', '314 888 1122', NULL, NULL, NULL, NULL, 'Disco de freno delantero', '911 (2019)', 'Porsche', '3.0L Boxer Biturbo', '2981 cc', 'Trasera', 'PDK automática', 'Izquierdo', 'pendiente', NULL, NULL, NULL, NULL, NULL, 'pendiente', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `web_order_detalle`
--

CREATE TABLE `web_order_detalle` (
  `id_detalle` int(11) NOT NULL,
  `id_orden` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `subtotal_linea` decimal(12,2) NOT NULL,
  `descripcion` varchar(200) DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `v_conceptos_cobrados`
--
DROP TABLE IF EXISTS `v_conceptos_cobrados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_conceptos_cobrados`  AS SELECT `vc`.`id_venta_concepto` AS `id_venta_concepto`, `vc`.`folio` AS `folio`, `vc`.`fecha_hora` AS `fecha_hora`, `s`.`nombre` AS `sucursal`, `vc`.`id_caja` AS `id_caja`, `u`.`nombre` AS `cajero`, `c`.`clave` AS `clave`, `c`.`nombre` AS `concepto`, `c`.`grupo` AS `grupo`, `o`.`descripcion` AS `plan`, `vc`.`id_venta` AS `id_venta`, concat('KRM-',lpad(`vc`.`id_sucursal`,2,'0'),'-',lpad(`vc`.`id_venta`,6,'0')) AS `folio_venta`, `vc`.`vin` AS `vin`, `vc`.`vehiculo_descripcion` AS `vehiculo_descripcion`, `vc`.`referencia` AS `referencia`, `vc`.`base_calculo` AS `base_calculo`, `vc`.`porcentaje` AS `porcentaje`, `vc`.`importe_gravado` AS `importe_gravado`, `vc`.`importe_exento` AS `importe_exento`, `vc`.`importe_accesorio` AS `importe_accesorio`, `vc`.`subtotal` AS `subtotal`, `vc`.`iva` AS `iva`, `vc`.`total` AS `total`, `vc`.`vigencia_inicio` AS `vigencia_inicio`, `vc`.`vigencia_fin` AS `vigencia_fin`, `vc`.`estado` AS `estado` FROM ((((`ventas_conceptos` `vc` join `conceptos_caja` `c` on(`c`.`id_concepto` = `vc`.`id_concepto`)) join `sucursales` `s` on(`s`.`id_sucursal` = `vc`.`id_sucursal`)) join `usuarios` `u` on(`u`.`id_usuario` = `vc`.`id_usuario`)) left join `conceptos_caja_opciones` `o` on(`o`.`id_opcion` = `vc`.`id_opcion`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `abonos_credito`
--
ALTER TABLE `abonos_credito`
  ADD PRIMARY KEY (`id_abono`),
  ADD UNIQUE KEY `uq_abonos_contrato_numero` (`id_contrato`,`numero_abono`),
  ADD UNIQUE KEY `uq_abonos_clave` (`clave_idempotencia`),
  ADD UNIQUE KEY `uq_abonos_folio` (`folio`),
  ADD KEY `idx_abonos_caja_fecha` (`id_caja`,`fecha_hora`),
  ADD KEY `fk_abonos_cliente` (`id_cliente`),
  ADD KEY `fk_abonos_sucursal` (`id_sucursal`),
  ADD KEY `fk_abonos_usuario` (`id_usuario`);

--
-- Indices de la tabla `autorizaciones_empleado`
--
ALTER TABLE `autorizaciones_empleado`
  ADD PRIMARY KEY (`id_autorizacion`),
  ADD KEY `idx_autorizaciones_fecha` (`fecha_hora`),
  ADD KEY `idx_autorizaciones_sesion` (`id_usuario_sesion`),
  ADD KEY `idx_autorizaciones_empleado` (`id_usuario_empleado`);

--
-- Indices de la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD PRIMARY KEY (`id_caja`),
  ADD UNIQUE KEY `uq_caja_sucursal` (`id_sucursal`,`numero_caja`);

--
-- Indices de la tabla `catalogo_opciones`
--
ALTER TABLE `catalogo_opciones`
  ADD PRIMARY KEY (`id_opcion`),
  ADD UNIQUE KEY `uq_catalogo_opciones_clave` (`clave`),
  ADD KEY `idx_catalogo_opciones_marca` (`marca`,`grupo`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`),
  ADD UNIQUE KEY `nombre_categoria` (`nombre_categoria`);

--
-- Indices de la tabla `citas`
--
ALTER TABLE `citas`
  ADD PRIMARY KEY (`id_cita`),
  ADD UNIQUE KEY `uq_citas_folio` (`folio`),
  ADD KEY `idx_citas_agenda` (`id_sucursal`,`fecha_hora`),
  ADD KEY `idx_citas_cliente` (`id_cliente`),
  ADD KEY `fk_citas_productos` (`id_producto`),
  ADD KEY `fk_citas_weborders` (`id_orden`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `uq_cliente_email` (`email`),
  ADD KEY `idx_clientes_nombre` (`nombre`),
  ADD KEY `fk_clientes_sucursal_preferida` (`id_sucursal_preferida`);

--
-- Indices de la tabla `favoritos_catalogo`
--
ALTER TABLE `favoritos_catalogo`
  ADD PRIMARY KEY (`id_cliente`,`id_producto`),
  ADD KEY `fk_favoritos_productos` (`id_producto`);

--
-- Indices de la tabla `conceptos_caja`
--
ALTER TABLE `conceptos_caja`
  ADD PRIMARY KEY (`id_concepto`),
  ADD UNIQUE KEY `uq_conceptos_clave` (`clave`),
  ADD KEY `idx_conceptos_activo` (`activo`,`orden`),
  ADD KEY `fk_conceptos_productos` (`id_producto`);

--
-- Indices de la tabla `conceptos_caja_opciones`
--
ALTER TABLE `conceptos_caja_opciones`
  ADD PRIMARY KEY (`id_opcion`),
  ADD UNIQUE KEY `uq_opcion_concepto` (`id_concepto`,`clave`);

--
-- Indices de la tabla `conceptos_caja_sucursal`
--
ALTER TABLE `conceptos_caja_sucursal`
  ADD PRIMARY KEY (`id_concepto`,`id_sucursal`),
  ADD KEY `fk_concsuc_sucursales` (`id_sucursal`);

--
-- Indices de la tabla `conceptos_caja_tarifas`
--
ALTER TABLE `conceptos_caja_tarifas`
  ADD PRIMARY KEY (`id_tarifa`),
  ADD UNIQUE KEY `uq_tarifa_tramo` (`id_concepto`,`ejercicio`,`limite_inferior`);

--
-- Indices de la tabla `contratos_credito`
--
ALTER TABLE `contratos_credito`
  ADD PRIMARY KEY (`id_contrato`),
  ADD UNIQUE KEY `uq_contratos_folio` (`folio`),
  ADD UNIQUE KEY `uq_contratos_venta` (`id_venta`),
  ADD KEY `idx_contratos_cliente` (`id_cliente`),
  ADD KEY `idx_contratos_estado` (`estado`),
  ADD KEY `idx_contratos_usuario` (`id_usuario`),
  ADD KEY `fk_contratos_sucursal` (`id_sucursal`),
  ADD KEY `fk_contratos_caja` (`id_caja`),
  ADD KEY `fk_contratos_producto` (`id_producto`);

--
-- Indices de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `fk_detalle_ventas_ventas` (`id_venta`),
  ADD KEY `fk_detalle_ventas_productos` (`id_producto`),
  ADD KEY `idx_detalle_venta_concepto` (`id_venta_concepto`);

--
-- Indices de la tabla `garantias`
--
ALTER TABLE `garantias`
  ADD PRIMARY KEY (`id_garantia`),
  ADD UNIQUE KEY `uq_garantias_venta_vin` (`id_venta`,`vin`),
  ADD KEY `fk_garantias_clientes` (`id_cliente`),
  ADD KEY `fk_garantias_productos` (`id_producto`),
  ADD KEY `idx_garantias_estado` (`estado`),
  ADD KEY `idx_garantias_vencimiento` (`estado`,`fecha_expiracion`);

--
-- Indices de la tabla `inventarios`
--
ALTER TABLE `inventarios`
  ADD PRIMARY KEY (`id_inventario`),
  ADD UNIQUE KEY `uq_sucursal_producto` (`id_sucursal`,`id_producto`),
  ADD KEY `fk_inventarios_productos` (`id_producto`);

--
-- Indices de la tabla `metodos_pago`
--
ALTER TABLE `metodos_pago`
  ADD PRIMARY KEY (`id_metodo_pago`),
  ADD UNIQUE KEY `nombre_metodo` (`nombre_metodo`);

--
-- Indices de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD PRIMARY KEY (`id_notificacion`),
  ADD KEY `idx_notificaciones_cliente` (`id_cliente`,`leida`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`),
  ADD UNIQUE KEY `codigo_barras` (`codigo_barras`),
  ADD UNIQUE KEY `uq_productos_vin` (`vin`),
  ADD KEY `fk_productos_categorias` (`id_categoria`),
  ADD KEY `idx_productos_tipo` (`tipo`);

--
-- Indices de la tabla `productos_web`
--
ALTER TABLE `productos_web`
  ADD PRIMARY KEY (`id_producto`),
  ADD KEY `idx_productosweb_seccion` (`seccion`,`publicado`);

--
-- Indices de la tabla `promociones`
--
ALTER TABLE `promociones`
  ADD PRIMARY KEY (`id_promocion`),
  ADD UNIQUE KEY `uq_promociones_clave` (`clave`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id_rol`),
  ADD UNIQUE KEY `nombre_rol` (`nombre_rol`);

--
-- Indices de la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  ADD PRIMARY KEY (`id_solicitud`),
  ADD UNIQUE KEY `uq_solicitudes_folio` (`folio`),
  ADD KEY `idx_solicitudes_cliente` (`id_cliente`),
  ADD KEY `fk_solicitudes_sucursales` (`id_sucursal`),
  ADD KEY `fk_solicitudes_productos` (`id_producto`);

--
-- Indices de la tabla `solicitudes_garantia`
--
ALTER TABLE `solicitudes_garantia`
  ADD PRIMARY KEY (`id_solicitud`),
  ADD UNIQUE KEY `uq_solicitudes_garantia_folio` (`folio`),
  ADD KEY `idx_solicitudes_garantia_estado` (`id_garantia`,`estado`),
  ADD KEY `fk_solicitudes_garantia_sucursal` (`id_sucursal`),
  ADD KEY `fk_solicitudes_garantia_solicita` (`id_usuario_solicita`),
  ADD KEY `fk_solicitudes_garantia_resuelve` (`id_usuario_resuelve`);

--
-- Indices de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  ADD PRIMARY KEY (`id_sucursal`),
  ADD UNIQUE KEY `id_sucursal` (`id_sucursal`,`nombre`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `correo` (`correo`),
  ADD KEY `fk_usuarios_roles` (`id_rol`),
  ADD KEY `fk_usuarios_sucursales` (`id_sucursal`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `fk_ventas_sucursales` (`id_sucursal`),
  ADD KEY `fk_ventas_usuarios` (`id_usuario`),
  ADD KEY `fk_ventas_cajas` (`id_caja`),
  ADD KEY `fk_ventas_metodos_pago` (`id_metodo_pago`),
  ADD KEY `fk_ventas_clientes` (`id_cliente`);

--
-- Indices de la tabla `ventas_conceptos`
--
ALTER TABLE `ventas_conceptos`
  ADD PRIMARY KEY (`id_venta_concepto`),
  ADD UNIQUE KEY `uq_ventas_conceptos_folio` (`folio`),
  ADD KEY `idx_vc_venta` (`id_venta`),
  ADD KEY `idx_vc_concepto_vin` (`id_concepto`,`vin`,`estado`),
  ADD KEY `idx_vc_concepto_ref` (`id_concepto`,`referencia`,`estado`),
  ADD KEY `idx_vc_fecha` (`fecha_hora`),
  ADD KEY `fk_vc_opciones` (`id_opcion`),
  ADD KEY `fk_vc_sucursales` (`id_sucursal`),
  ADD KEY `fk_vc_cajas` (`id_caja`),
  ADD KEY `fk_vc_usuarios` (`id_usuario`),
  ADD KEY `fk_vc_vehiculo` (`id_producto_vehiculo`),
  ADD KEY `fk_vc_accesorio` (`id_producto_accesorio`),
  ADD KEY `fk_vc_contratos` (`id_contrato`);

--
-- Indices de la tabla `web_orders`
--
ALTER TABLE `web_orders`
  ADD PRIMARY KEY (`id_orden`),
  ADD UNIQUE KEY `uq_weborders_folio` (`folio`),
  ADD KEY `fk_weborders_productos` (`id_producto`),
  ADD KEY `idx_weborders_estado` (`estado`),
  ADD KEY `idx_weborders_sucursal_estado` (`id_sucursal`,`estado`),
  ADD KEY `fk_weborders_clientes` (`id_cliente`),
  ADD KEY `fk_weborders_metodos_pago` (`id_metodo_pago`),
  ADD KEY `fk_weborders_ventas` (`id_venta`);

--
-- Indices de la tabla `web_order_detalle`
--
ALTER TABLE `web_order_detalle`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `fk_wod_orden` (`id_orden`),
  ADD KEY `fk_wod_producto` (`id_producto`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `abonos_credito`
--
ALTER TABLE `abonos_credito`
  MODIFY `id_abono` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `autorizaciones_empleado`
--
ALTER TABLE `autorizaciones_empleado`
  MODIFY `id_autorizacion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cajas`
--
ALTER TABLE `cajas`
  MODIFY `id_caja` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `catalogo_opciones`
--
ALTER TABLE `catalogo_opciones`
  MODIFY `id_opcion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `citas`
--
ALTER TABLE `citas`
  MODIFY `id_cita` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `conceptos_caja`
--
ALTER TABLE `conceptos_caja`
  MODIFY `id_concepto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `conceptos_caja_opciones`
--
ALTER TABLE `conceptos_caja_opciones`
  MODIFY `id_opcion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT de la tabla `conceptos_caja_tarifas`
--
ALTER TABLE `conceptos_caja_tarifas`
  MODIFY `id_tarifa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `contratos_credito`
--
ALTER TABLE `contratos_credito`
  MODIFY `id_contrato` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `garantias`
--
ALTER TABLE `garantias`
  MODIFY `id_garantia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `inventarios`
--
ALTER TABLE `inventarios`
  MODIFY `id_inventario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=247;

--
-- AUTO_INCREMENT de la tabla `metodos_pago`
--
ALTER TABLE `metodos_pago`
  MODIFY `id_metodo_pago` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  MODIFY `id_notificacion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;

--
-- AUTO_INCREMENT de la tabla `promociones`
--
ALTER TABLE `promociones`
  MODIFY `id_promocion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  MODIFY `id_solicitud` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `solicitudes_garantia`
--
ALTER TABLE `solicitudes_garantia`
  MODIFY `id_solicitud` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  MODIFY `id_sucursal` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `ventas_conceptos`
--
ALTER TABLE `ventas_conceptos`
  MODIFY `id_venta_concepto` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `web_orders`
--
ALTER TABLE `web_orders`
  MODIFY `id_orden` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `web_order_detalle`
--
ALTER TABLE `web_order_detalle`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `abonos_credito`
--
ALTER TABLE `abonos_credito`
  ADD CONSTRAINT `fk_abonos_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_abonos_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_abonos_contrato` FOREIGN KEY (`id_contrato`) REFERENCES `contratos_credito` (`id_contrato`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_abonos_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_abonos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD CONSTRAINT `fk_cajas_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `citas`
--
ALTER TABLE `citas`
  ADD CONSTRAINT `fk_citas_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_citas_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_citas_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_citas_weborders` FOREIGN KEY (`id_orden`) REFERENCES `web_orders` (`id_orden`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD CONSTRAINT `fk_clientes_sucursal_preferida` FOREIGN KEY (`id_sucursal_preferida`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `favoritos_catalogo`
--
ALTER TABLE `favoritos_catalogo`
  ADD CONSTRAINT `fk_favoritos_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_favoritos_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `conceptos_caja`
--
ALTER TABLE `conceptos_caja`
  ADD CONSTRAINT `fk_conceptos_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `conceptos_caja_opciones`
--
ALTER TABLE `conceptos_caja_opciones`
  ADD CONSTRAINT `fk_opciones_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `conceptos_caja_sucursal`
--
ALTER TABLE `conceptos_caja_sucursal`
  ADD CONSTRAINT `fk_concsuc_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_concsuc_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `conceptos_caja_tarifas`
--
ALTER TABLE `conceptos_caja_tarifas`
  ADD CONSTRAINT `fk_tarifas_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `contratos_credito`
--
ALTER TABLE `contratos_credito`
  ADD CONSTRAINT `fk_contratos_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_contratos_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_contratos_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_contratos_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_contratos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_contratos_venta` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD CONSTRAINT `fk_detalle_ventas_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_detalle_ventas_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `garantias`
--
ALTER TABLE `garantias`
  ADD CONSTRAINT `fk_garantias_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_garantias_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_garantias_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `inventarios`
--
ALTER TABLE `inventarios`
  ADD CONSTRAINT `fk_inventarios_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_inventarios_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD CONSTRAINT `fk_notificaciones_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_productos_categorias` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id_categoria`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos_web`
--
ALTER TABLE `productos_web`
  ADD CONSTRAINT `fk_productosweb_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  ADD CONSTRAINT `fk_solicitudes_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_solicitudes_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_solicitudes_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `solicitudes_garantia`
--
ALTER TABLE `solicitudes_garantia`
  ADD CONSTRAINT `fk_solicitudes_garantia_garantia` FOREIGN KEY (`id_garantia`) REFERENCES `garantias` (`id_garantia`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_solicitudes_garantia_resuelve` FOREIGN KEY (`id_usuario_resuelve`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_solicitudes_garantia_solicita` FOREIGN KEY (`id_usuario_solicita`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_solicitudes_garantia_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_usuarios_roles` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_usuarios_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `fk_ventas_cajas` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_metodos_pago` FOREIGN KEY (`id_metodo_pago`) REFERENCES `metodos_pago` (`id_metodo_pago`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_usuarios` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `ventas_conceptos`
--
ALTER TABLE `ventas_conceptos`
  ADD CONSTRAINT `fk_vc_accesorio` FOREIGN KEY (`id_producto_accesorio`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_cajas` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_conceptos` FOREIGN KEY (`id_concepto`) REFERENCES `conceptos_caja` (`id_concepto`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_contratos` FOREIGN KEY (`id_contrato`) REFERENCES `contratos_credito` (`id_contrato`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_opciones` FOREIGN KEY (`id_opcion`) REFERENCES `conceptos_caja_opciones` (`id_opcion`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_usuarios` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_vehiculo` FOREIGN KEY (`id_producto_vehiculo`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vc_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `web_orders`
--
ALTER TABLE `web_orders`
  ADD CONSTRAINT `fk_weborders_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_weborders_metodos_pago` FOREIGN KEY (`id_metodo_pago`) REFERENCES `metodos_pago` (`id_metodo_pago`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_weborders_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_weborders_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_weborders_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `web_order_detalle`
--
ALTER TABLE `web_order_detalle`
  ADD CONSTRAINT `fk_wod_orden` FOREIGN KEY (`id_orden`) REFERENCES `web_orders` (`id_orden`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_wod_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE;

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `ev_garantias_vencidas` ON SCHEDULE EVERY 1 MINUTE STARTS '2026-10-10 18:35:30' ON COMPLETION PRESERVE ENABLE COMMENT 'Garantías cuya fecha y hora de vencimiento ya llegó dejan de est' DO UPDATE garantias SET estado = 'vencida' WHERE estado = 'vigente' AND fecha_expiracion <= NOW()$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
