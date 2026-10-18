-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: pos_multisede
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `garantias`
--

DROP TABLE IF EXISTS `garantias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garantias` (
  `id_garantia` int(11) NOT NULL AUTO_INCREMENT,
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
  `estado` enum('vigente','vencida','cancelada','aplicada') NOT NULL DEFAULT 'vigente',
  PRIMARY KEY (`id_garantia`),
  UNIQUE KEY `uq_garantias_venta_vin` (`id_venta`,`vin`),
  KEY `fk_garantias_clientes` (`id_cliente`),
  KEY `fk_garantias_productos` (`id_producto`),
  KEY `idx_garantias_estado` (`estado`),
  KEY `idx_garantias_vencimiento` (`estado`,`fecha_expiracion`),
  CONSTRAINT `fk_garantias_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON UPDATE CASCADE,
  CONSTRAINT `fk_garantias_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_garantias_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `garantias`
--

LOCK TABLES `garantias` WRITE;
/*!40000 ALTER TABLE `garantias` DISABLE KEYS */;
/*!40000 ALTER TABLE `garantias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `solicitudes_garantia`
--

DROP TABLE IF EXISTS `solicitudes_garantia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solicitudes_garantia` (
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
  KEY `idx_solicitudes_garantia_estado` (`id_garantia`,`estado`),
  KEY `fk_solicitudes_garantia_sucursal` (`id_sucursal`),
  KEY `fk_solicitudes_garantia_solicita` (`id_usuario_solicita`),
  KEY `fk_solicitudes_garantia_resuelve` (`id_usuario_resuelve`),
  CONSTRAINT `fk_solicitudes_garantia_garantia` FOREIGN KEY (`id_garantia`) REFERENCES `garantias` (`id_garantia`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_garantia_resuelve` FOREIGN KEY (`id_usuario_resuelve`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_garantia_solicita` FOREIGN KEY (`id_usuario_solicita`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_garantia_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Solicitudes de garantía levantadas en caja; las confirma o deniega un gerente';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `solicitudes_garantia`
--

LOCK TABLES `solicitudes_garantia` WRITE;
/*!40000 ALTER TABLE `solicitudes_garantia` DISABLE KEYS */;
/*!40000 ALTER TABLE `solicitudes_garantia` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_solicitudes_garantia_nueva BEFORE INSERT ON solicitudes_garantia FOR EACH ROW
BEGIN
    SET NEW.estado = 'pendiente', NEW.id_usuario_resuelve = NULL, NEW.fecha_resolucion = NULL, NEW.motivo_rechazo = NULL;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_solicitudes_garantia_resolver BEFORE UPDATE ON solicitudes_garantia FOR EACH ROW
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_solicitudes_garantia_aplicada AFTER UPDATE ON solicitudes_garantia FOR EACH ROW
BEGIN
    IF NEW.estado = 'confirmada' AND OLD.estado = 'pendiente' THEN
        UPDATE garantias SET estado = 'aplicada' WHERE id_garantia = NEW.id_garantia;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-10 16:59:36
