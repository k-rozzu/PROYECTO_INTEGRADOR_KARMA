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
-- Table structure for table `autorizaciones_empleado`
--

DROP TABLE IF EXISTS `autorizaciones_empleado`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `autorizaciones_empleado` (
  `id_autorizacion` int(11) NOT NULL AUTO_INCREMENT,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'Momento del intento',
  `etapa` enum('autorizacion','operacion') NOT NULL DEFAULT 'autorizacion' COMMENT 'autorizacion = c√≥digo recibido; operacion = intento de ejecutar sin autorizaci√≥n v√°lida',
  `accion` varchar(20) NOT NULL COMMENT 'VENTA, CREDITO, GARANTIA u ORDEN_WEB',
  `referencia` int(11) DEFAULT NULL COMMENT 'Ticket (venta/cr√©dito), id_garantia o id_orden al que qued√≥ ligada',
  `codigo_empleado` varchar(20) DEFAULT NULL COMMENT 'Texto le√≠do del QR o escrito a mano',
  `metodo` enum('qr','manual') DEFAULT NULL COMMENT 'C√≥mo se obtuvo el c√≥digo (informativo: ambos pasan por la misma validaci√≥n)',
  `id_usuario_sesion` int(11) DEFAULT NULL COMMENT 'Usuario con la sesi√≥n del POS abierta',
  `id_usuario_empleado` int(11) DEFAULT NULL COMMENT 'Usuario al que pertenece el c√≥digo (si existe)',
  `id_sucursal` int(11) DEFAULT NULL,
  `resultado` enum('autorizado','denegado') NOT NULL,
  `motivo` varchar(120) DEFAULT NULL COMMENT 'Motivo interno del rechazo (no se muestra al usuario)',
  `operacion` varchar(40) DEFAULT NULL COMMENT 'Endpoint de api.php que us√≥ (o intent√≥ usar) la autorizaci√≥n',
  `fecha_uso` datetime DEFAULT NULL COMMENT 'Cu√°ndo se consumi√≥ la autorizaci√≥n (es de un solo uso)',
  PRIMARY KEY (`id_autorizacion`),
  KEY `idx_autorizaciones_fecha` (`fecha_hora`),
  KEY `idx_autorizaciones_sesion` (`id_usuario_sesion`),
  KEY `idx_autorizaciones_empleado` (`id_usuario_empleado`)
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Auditor√≠a de autorizaciones de empleado (gafete QR / c√≥digo) del Punto de Venta';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `autorizaciones_empleado`
--

LOCK TABLES `autorizaciones_empleado` WRITE;
/*!40000 ALTER TABLE `autorizaciones_empleado` DISABLE KEYS */;
INSERT INTO `autorizaciones_empleado` VALUES (1,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(2,'2026-10-05 08:55:35','operacion','CREDITO',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(3,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(4,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(5,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','CSRF','crear_venta',NULL),(6,'2026-10-05 08:55:35','operacion','ORDEN_WEB',12,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cobrar_orden_web',NULL),(7,'2026-10-05 08:55:35','operacion','ORDEN_WEB',13,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cancelar_orden_web',NULL),(8,'2026-10-05 08:55:35','operacion','GARANTIA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','aplicar_garantia',NULL),(9,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,NULL,1,'denegado','CSRF',NULL,NULL),(10,'2026-10-05 08:55:35','autorizacion','DESCONOCIDA',NULL,NULL,'manual',5,NULL,1,'denegado','METODO_HTTP',NULL,NULL),(11,'2026-10-05 08:55:35','autorizacion','BORRAR_TODO',1,'EMP-0005','manual',5,NULL,1,'denegado','ACCION_NO_PROTEGIDA',NULL,NULL),(12,'2026-10-05 08:55:35','autorizacion','VENTA',NULL,'EMP-0005','manual',5,NULL,1,'denegado','REFERENCIA_INVALIDA',NULL,NULL),(13,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-9999','qr',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(14,'2026-10-05 08:55:35','autorizacion','VENTA',1,'HOLA','manual',5,NULL,1,'denegado','FORMATO_INVALIDO',NULL,NULL),(15,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005\'OR\'1\'=\'1','manual',5,NULL,1,'denegado','FORMATO_INVALIDO',NULL,NULL),(16,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0006','qr',5,6,1,'denegado','ROL_DISTINTO,USUARIO_DISTINTO',NULL,NULL),(17,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(18,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0007','qr',5,7,1,'denegado','USUARIO_DISTINTO,INACTIVO',NULL,NULL),(19,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0001','qr',5,1,1,'denegado','USUARIO_DISTINTO',NULL,NULL),(20,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(21,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(22,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(23,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(24,'2026-10-05 08:55:35','operacion','CREDITO',1,'EMP-0005',NULL,5,NULL,1,'denegado','ACCION_DISTINTA','crear_venta',NULL),(25,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(26,'2026-10-05 08:55:35','autorizacion','VENTA',51,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(27,'2026-10-05 08:55:35','operacion','VENTA',1,'EMP-0005',NULL,5,NULL,1,'denegado','REFERENCIA_DISTINTA','crear_venta',NULL),(28,'2026-10-05 08:55:35','autorizacion','ORDEN_WEB',12,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(29,'2026-10-05 08:55:35','operacion','ORDEN_WEB',13,'EMP-0005',NULL,5,NULL,1,'denegado','REFERENCIA_DISTINTA','cancelar_orden_web',NULL),(30,'2026-10-05 08:55:35','autorizacion','GARANTIA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(31,'2026-10-05 08:55:35','autorizacion','GARANTIA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(32,'2026-10-05 08:55:35','operacion','GARANTIA',1,'EMP-0005',NULL,5,NULL,1,'denegado','PERMISO_INVALIDO','aplicar_garantia',NULL),(33,'2026-10-05 08:55:35','autorizacion','GARANTIA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(34,'2026-10-05 08:56:37','operacion','GARANTIA',1,'EMP-0005',NULL,5,NULL,1,'denegado','PERMISO_VENCIDO','aplicar_garantia',NULL),(35,'2026-10-05 08:56:37','autorizacion','VENTA',1,'EMP-0005','qr',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 08:56:37'),(36,'2026-10-05 08:56:37','operacion','VENTA',2,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(37,'2026-10-05 08:56:37','autorizacion','CREDITO',2,'EMP-0005','manual',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 08:56:37'),(38,'2026-10-05 08:56:37','autorizacion','GARANTIA',1,'EMP-0005','qr',5,5,1,'autorizado',NULL,'aplicar_garantia','2026-10-05 08:56:37'),(39,'2026-10-05 08:56:37','autorizacion','GARANTIA',999,'EMP-0005','manual',5,5,1,'autorizado',NULL,'aplicar_garantia','2026-10-05 08:56:37'),(40,'2026-10-05 08:56:37','autorizacion','ORDEN_WEB',12,'EMP-0005','qr',5,5,1,'autorizado',NULL,'cobrar_orden_web','2026-10-05 08:56:38'),(41,'2026-10-05 08:56:38','autorizacion','ORDEN_WEB',13,'EMP-0005','manual',5,5,1,'autorizado',NULL,'cancelar_orden_web','2026-10-05 08:56:38'),(42,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(43,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(44,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(45,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(46,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(47,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-0005','manual',5,NULL,1,'denegado','DEMASIADOS_INTENTOS',NULL,NULL),(48,'2026-10-05 08:56:39','autorizacion','VENTA',4,'EMP-0005','qr',5,5,1,'autorizado',NULL,NULL,NULL),(49,'2026-10-05 09:02:08','autorizacion','VENTA',4,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(50,'2026-10-05 09:02:26','autorizacion','VENTA',4,'EMP-0006','qr',5,6,1,'denegado','ROL_DISTINTO,USUARIO_DISTINTO',NULL,NULL),(51,'2026-10-05 09:02:50','autorizacion','VENTA',4,'EMP-0005','qr',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 09:02:51'),(52,'2026-10-05 09:04:43','autorizacion','CREDITO',5,'EMP-0005','manual',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 09:04:44'),(53,'2026-10-05 09:05:03','autorizacion','GARANTIA',1,'EMP-0005','qr',5,5,1,'autorizado',NULL,'aplicar_garantia','2026-10-05 09:05:03'),(54,'2026-10-05 09:06:18','autorizacion','ORDEN_WEB',14,'EMP-0005','qr',5,5,1,'autorizado',NULL,'cobrar_orden_web','2026-10-05 09:06:19'),(55,'2026-10-05 09:06:35','autorizacion','ORDEN_WEB',15,'EMP-0005','manual',5,5,1,'autorizado',NULL,'cancelar_orden_web','2026-10-05 09:06:36'),(56,'2026-10-05 09:07:14','operacion','VENTA',7,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(57,'2026-10-05 09:07:14','operacion','VENTA',7,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(58,'2026-10-05 09:07:14','operacion','CREDITO',7,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(59,'2026-10-05 09:07:14','operacion','ORDEN_WEB',11,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cobrar_orden_web',NULL),(60,'2026-10-05 09:07:14','operacion','ORDEN_WEB',10,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cancelar_orden_web',NULL),(61,'2026-10-05 09:07:14','operacion','GARANTIA',3,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','aplicar_garantia',NULL),(62,'2026-10-05 09:07:14','autorizacion','VENTA',7,NULL,'manual',5,NULL,1,'denegado','FORMATO_INVALIDO',NULL,NULL),(63,'2026-10-05 22:32:10','autorizacion','ORDEN_WEB',11,'EMP-0004','manual',4,4,1,'autorizado',NULL,'cobrar_orden_web','2026-10-05 22:32:10'),(64,'2026-10-06 09:48:43','autorizacion','VENTA',1,'EMP-0004','qr',4,4,1,'autorizado',NULL,'crear_venta','2026-10-06 09:48:43'),(65,'2026-10-06 10:00:30','autorizacion','VENTA',2,'EMP-0004','qr',4,4,1,'autorizado',NULL,'crear_venta','2026-10-06 10:00:30'),(66,'2026-10-06 10:04:33','autorizacion','VENTA',3,'EMP-0004','qr',4,4,1,'autorizado',NULL,'crear_venta','2026-10-06 10:04:34'),(67,'2026-10-10 16:23:42','autorizacion','CREDITO',1,'EMP-0004','manual',4,4,1,'autorizado',NULL,'preparar_credito','2026-10-10 16:23:42'),(68,'2026-10-10 16:29:20','autorizacion','CREDITO',2,'EMP-0004','qr',4,4,1,'autorizado',NULL,'preparar_credito','2026-10-10 16:29:20');
/*!40000 ALTER TABLE `autorizaciones_empleado` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cajas`
--

DROP TABLE IF EXISTS `cajas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cajas` (
  `id_caja` int(11) NOT NULL AUTO_INCREMENT,
  `id_sucursal` int(11) NOT NULL,
  `numero_caja` int(11) NOT NULL,
  `estado` enum('abierta','cerrada','mantenimiento') NOT NULL DEFAULT 'cerrada',
  PRIMARY KEY (`id_caja`),
  UNIQUE KEY `uq_caja_sucursal` (`id_sucursal`,`numero_caja`),
  CONSTRAINT `fk_cajas_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cajas`
--

LOCK TABLES `cajas` WRITE;
/*!40000 ALTER TABLE `cajas` DISABLE KEYS */;
INSERT INTO `cajas` VALUES (1,1,1,'abierta'),(2,2,1,'abierta');
/*!40000 ALTER TABLE `cajas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_opciones`
--

DROP TABLE IF EXISTS `catalogo_opciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `catalogo_opciones` (
  `id_opcion` int(11) NOT NULL AUTO_INCREMENT,
  `clave` varchar(60) NOT NULL,
  `marca` varchar(80) DEFAULT NULL,
  `tipo_vehiculo` enum('auto','moto') DEFAULT NULL,
  `grupo` enum('color','version','equipamiento') NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `precio` decimal(12,2) NOT NULL DEFAULT 0.00,
  `color_hex` varchar(20) DEFAULT NULL,
  `orden` int(11) NOT NULL DEFAULT 0,
  `activa` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_opcion`),
  UNIQUE KEY `uq_catalogo_opciones_clave` (`clave`),
  KEY `idx_catalogo_opciones_marca` (`marca`,`grupo`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_opciones`
--

LOCK TABLES `catalogo_opciones` WRITE;
/*!40000 ALTER TABLE `catalogo_opciones` DISABLE KEYS */;
INSERT INTO `catalogo_opciones` VALUES (1,'audi-color-blanco','Audi','auto','color','Blanco Glaciar','Met√°lico',0.00,'#F2F2EF',1,1),(2,'audi-color-negro','Audi','auto','color','Negro Mythos','Met√°lico',0.00,'#101012',2,1),(3,'audi-color-nardo','Audi','auto','color','Gris Nardo','S√≥lido',0.00,'#7A7D80',3,1),(4,'audi-color-azul','Audi','auto','color','Azul Ultra','Met√°lico',0.00,'#1F3B66',4,1),(5,'audi-color-rojo','Audi','auto','color','Rojo Tango','Met√°lico',0.00,'#8C1D2B',5,1),(6,'audi-color-verde','Audi','auto','color','Verde Distrito','Met√°lico',12000.00,'#3F4A3C',6,1),(7,'audi-version-base','Audi','auto','version','Base','Equipamiento de serie',0.00,NULL,1,1),(8,'audi-version-sline','Audi','auto','version','S line','Paquete exterior e interior S line con suspensi√≥n deportiva',65000.00,NULL,2,1),(9,'audi-version-black','Audi','auto','version','Black Edition','Detalles en negro brillante, rines de 20\" y techo panor√°mico',95000.00,NULL,3,1),(10,'audi-eq-techo','Audi','auto','equipamiento','Techo panor√°mico','Techo de cristal corredizo con cortinilla el√©ctrica',32000.00,NULL,1,1),(11,'audi-eq-audio','Audi','auto','equipamiento','Sistema de audio premium','16 bocinas con sonido envolvente 3D',28000.00,NULL,2,1),(12,'audi-eq-hud','Audi','auto','equipamiento','Head-up display','Informaci√≥n de manejo proyectada en el parabrisas',22000.00,NULL,3,1),(13,'audi-eq-tour','Audi','auto','equipamiento','Asistentes de conducci√≥n Tour','Crucero adaptativo, carril activo y asistente de tr√°fico',35000.00,NULL,4,1),(14,'audi-eq-rines','Audi','auto','equipamiento','Rines de 21\"','Rines de aleaci√≥n de dise√±o exclusivo',41000.00,NULL,5,1),(15,'porsche-color-blanco','Porsche','auto','color','Blanco Carrara','Met√°lico',0.00,'#EDEDEA',1,1),(16,'porsche-color-negro','Porsche','auto','color','Negro Jeweled','Met√°lico',0.00,'#141414',2,1),(17,'porsche-color-gt','Porsche','auto','color','Gris GT Plata','Met√°lico',0.00,'#9EA0A1',3,1),(18,'porsche-color-azul','Porsche','auto','color','Azul Gentian','Met√°lico',0.00,'#1B3A6B',4,1),(19,'porsche-color-rojo','Porsche','auto','color','Rojo Carm√≠n','S√≥lido',0.00,'#9E1B2E',5,1),(20,'porsche-color-verde','Porsche','auto','color','Verde Python','Color especial',48000.00,'#5C7D3A',6,1),(21,'porsche-color-amarillo','Porsche','auto','color','Amarillo Racing','Color especial',48000.00,'#F2C230',7,1),(22,'porsche-version-base','Porsche','auto','version','Base','Equipamiento de serie',0.00,NULL,1,1),(23,'porsche-version-chrono','Porsche','auto','version','Paquete Sport Chrono','Cron√≥metro, modo Sport Plus y Launch Control',78000.00,NULL,2,1),(24,'porsche-version-design','Porsche','auto','version','Paquete Sport Design','Fascias y faldones deportivos con detalles en negro',115000.00,NULL,3,1),(25,'porsche-eq-audio','Porsche','auto','equipamiento','Sistema de audio de alta fidelidad','Amplificaci√≥n dedicada y bocinas de alto desempe√±o',54000.00,NULL,1,1),(26,'porsche-eq-asientos','Porsche','auto','equipamiento','Asientos deportivos adaptativos','18 posiciones el√©ctricas con memoria',68000.00,NULL,2,1),(27,'porsche-eq-direccion','Porsche','auto','equipamiento','Direcci√≥n en el eje trasero','Mayor agilidad en curvas y estabilidad a alta velocidad',72000.00,NULL,3,1),(28,'porsche-eq-matrix','Porsche','auto','equipamiento','Faros LED Matrix con PDLS Plus','Iluminaci√≥n adaptativa con luz de curva',45000.00,NULL,4,1),(29,'porsche-eq-pccb','Porsche','auto','equipamiento','Frenos cer√°micos PCCB','Discos de carbono-cer√°mica con calipers amarillos',260000.00,NULL,5,1),(30,'ducati-color-rojo','Ducati','moto','color','Rojo Ducati','Color de la marca',0.00,'#9E1B2E',1,1),(31,'ducati-color-gris','Ducati','moto','color','Gris Antracita','Mate',0.00,'#4A4A4A',2,1),(32,'ducati-color-blanco','Ducati','moto','color','Blanco Dark','Brillante',0.00,'#E7E7E4',3,1),(33,'ducati-color-negro','Ducati','moto','color','Negro Mate','Mate',0.00,'#1A1A1A',4,1),(34,'ducati-color-verde','Ducati','moto','color','Verde Storm','Edici√≥n especial',9500.00,'#4D5845',5,1),(35,'ducati-version-std','Ducati','moto','version','Est√°ndar','Equipamiento de serie',0.00,NULL,1,1),(36,'ducati-version-perf','Ducati','moto','version','Paquete Performance','Escape deportivo, asiento racing y piezas de aluminio maquinado',38000.00,NULL,2,1),(37,'ducati-eq-punos','Ducati','moto','equipamiento','Pu√±os con calefacci√≥n','Tres niveles de temperatura',6500.00,NULL,1,1),(38,'ducati-eq-crucero','Ducati','moto','equipamiento','Control de crucero','Mandos integrados en el manubrio',9800.00,NULL,2,1),(39,'ducati-eq-asiento','Ducati','moto','equipamiento','Asiento confort','Espuma de doble densidad para viajes largos',5200.00,NULL,3,1),(40,'ducati-eq-nav','Ducati','moto','equipamiento','Navegaci√≥n en pantalla TFT','Mapas paso a paso conectados al celular',7900.00,NULL,4,1),(41,'ducati-eq-alarma','Ducati','moto','equipamiento','Alarma antirrobo','Inmovilizador con sensor de movimiento',6200.00,NULL,5,1);
/*!40000 ALTER TABLE `catalogo_opciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categorias`
--

DROP TABLE IF EXISTS `categorias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_categoria` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  PRIMARY KEY (`id_categoria`),
  UNIQUE KEY `nombre_categoria` (`nombre_categoria`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categorias`
--

LOCK TABLES `categorias` WRITE;
/*!40000 ALTER TABLE `categorias` DISABLE KEYS */;
INSERT INTO `categorias` VALUES (1,'Porsche','Veh√≠culos Porsche'),(2,'Audi','Veh√≠culos Audi'),(3,'Ducati','Motocicletas Ducati'),(4,'Refacciones','Refacciones y piezas');
/*!40000 ALTER TABLE `categorias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `citas`
--

DROP TABLE IF EXISTS `citas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `citas` (
  `id_cita` int(11) NOT NULL AUTO_INCREMENT,
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
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_cita`),
  UNIQUE KEY `uq_citas_folio` (`folio`),
  KEY `idx_citas_agenda` (`id_sucursal`,`fecha_hora`),
  KEY `idx_citas_cliente` (`id_cliente`),
  KEY `fk_citas_productos` (`id_producto`),
  KEY `fk_citas_weborders` (`id_orden`),
  CONSTRAINT `fk_citas_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_citas_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_citas_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_citas_weborders` FOREIGN KEY (`id_orden`) REFERENCES `web_orders` (`id_orden`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `citas`
--

LOCK TABLES `citas` WRITE;
/*!40000 ALTER TABLE `citas` DISABLE KEYS */;
INSERT INTO `citas` VALUES (1,'CITA-02-000001','prueba_manejo',NULL,2,25,NULL,'2026-10-06 11:00:00','Ana Prueba','cliente.prueba@karma.local','3145550101',NULL,NULL,NULL,NULL,NULL,'cancelada','2026-10-03 18:02:32'),(2,'CITA-01-000002','apartado',NULL,1,18,NULL,'2026-10-06 12:00:00','Ana Prueba','cliente.prueba@karma.local','3145550101',NULL,NULL,NULL,NULL,NULL,'completada','2026-10-03 18:02:32'),(3,'CITA-02-000003','servicio',NULL,2,NULL,NULL,'2026-10-06 09:00:00','Ana Prueba','cliente.prueba@karma.local','3145550101','Audi Q5 2022','WAUZZZFY0N2000001',45000,'Servicio de frenos','Rechinan los frenos','programada','2026-10-03 18:02:33'),(4,'CITA-01-000004','apartado',9,1,31,10,'2026-10-05 10:00:00','Gojo Satoru','gojosatorureal@gmail.com','3140242412',NULL,NULL,NULL,NULL,NULL,'programada','2026-10-04 16:14:34');
/*!40000 ALTER TABLE `citas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clientes`
--

DROP TABLE IF EXISTS `clientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL AUTO_INCREMENT,
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
  `identificacion_numero` varchar(40) DEFAULT NULL COMMENT 'Folio o n√∫mero de la identificaci√≥n oficial',
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
  `ultimo_acceso` datetime DEFAULT NULL,
  PRIMARY KEY (`id_cliente`),
  UNIQUE KEY `uq_cliente_email` (`email`),
  KEY `idx_clientes_nombre` (`nombre`),
  KEY `fk_clientes_sucursal_preferida` (`id_sucursal_preferida`),
  CONSTRAINT `fk_clientes_sucursal_preferida` FOREIGN KEY (`id_sucursal_preferida`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES (1,'Roberto Fern√°ndez Aguilar','FERA900101XXX','314 123 4567','roberto.fernandez@email.com','Porsche 911 Carrera',1880000.00,450000.00,470000.00,5,24,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(2,'Marina L√≥pez Castillo','LOCM920202XXX','314 987 6543','marina.lopez@email.com','Audi RS7 Sportback',1315000.00,200000.00,NULL,2,12,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(3,'H√©ctor Iv√°n Sol√≥rzano','SOIH930303XXX','312 456 7890','hector.solorzano@email.com','Ducati Panigale V4 S',496000.00,62000.00,124000.00,0,24,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(4,'Carolina zu√±iga','123456789','3141390132','cmartinez72@ucol.mx',NULL,NULL,NULL,NULL,0,0,'activo','Manzanillo Centro Sector 5','INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(5,'Alan Ibarra Heredia','26102007','3141576255','aibarra9@ucol.mx',NULL,NULL,NULL,NULL,0,0,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(6,'Diego Alejandro Vazquez','098765423','3141987686','dvazquez89@gmail.com',NULL,NULL,NULL,NULL,0,0,'activo','Floresta 56','INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(9,'Gojo Satoru',NULL,'3140242412','gojosatorureal@gmail.com',NULL,NULL,NULL,NULL,0,0,'activo',NULL,NULL,NULL,'Gojo','Satoru','$2y$10$xeX87ork9xKTpOhN7PbtqOi//t3Yw/2ee.ZdhHJLIE1Z6U3ye110q',NULL,NULL,NULL,1,'Porsche',1,0,0,'2026-10-04 16:13:31','2026-10-06 09:24:28'),(10,'Cliente Prueba QR Credito','XAXX010101000','3140000002','cliente.credito.qr@karma.local','Ducati Scrambler Nightshift (2023)',276000.00,11500.00,50000.00,0,24,'activo','Calle de Prueba 1, Manzanillo','INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(11,'Cliente Prueba QR UI Credito',NULL,NULL,'cliente.credito.ui.qr@karma.local','Ducati Multistrada V2 (2024)',356388.08,14849.50,80000.00,0,24,'activo',NULL,'INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(12,'Cliente Prueba Contrato','PECC900101AB1','3140000009','cliente.prueba.contrato@karma.local','Audi Q5 (2025)',984426.23,41017.76,201373.13,0,24,'activo','Calle Prueba 123, Col. Centro, Manzanillo, Colima','INE','IDMEX1234567890',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(13,'Mar√≠a De Todos Los Angeles','MAZC060605MCMRXRA7','3145439851','mariadelosangeles@gmail.com','Ducati SuperSport 950 (2023)',377644.95,15735.21,50000.00,0,24,'activo','Avenida Cerro de La Cruz #54','INE','298463710372',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL);
/*!40000 ALTER TABLE `clientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clientes_favoritos`
--

DROP TABLE IF EXISTS `clientes_favoritos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clientes_favoritos` (
  `id_cliente` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_cliente`,`id_producto`),
  KEY `fk_favoritos_productos` (`id_producto`),
  CONSTRAINT `fk_favoritos_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_favoritos_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes_favoritos`
--

LOCK TABLES `clientes_favoritos` WRITE;
/*!40000 ALTER TABLE `clientes_favoritos` DISABLE KEYS */;
/*!40000 ALTER TABLE `clientes_favoritos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contratos_credito`
--

DROP TABLE IF EXISTS `contratos_credito`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contratos_credito` (
  `id_contrato` int(11) NOT NULL AUTO_INCREMENT,
  `folio` varchar(30) DEFAULT NULL COMMENT 'KRM-CC-{sucursal}-{id}',
  `estado` enum('pendiente_firma','firmado','cancelado') NOT NULL DEFAULT 'pendiente_firma' COMMENT 'pendiente_firma = enganche cobrado y contrato en pantalla; firmado = cr√©dito concretado; cancelado = el cliente no firm√≥',
  `id_sucursal` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL COMMENT 'Cajero que atendi√≥ (representante de KARMA)',
  `id_caja` int(11) NOT NULL,
  `ticket_numero` int(11) DEFAULT NULL,
  `id_producto` int(11) NOT NULL,
  `vin` varchar(17) DEFAULT NULL,
  `id_venta` int(11) DEFAULT NULL COMMENT 'Venta registrada al firmar (NULL mientras no se firma)',
  `id_cliente` int(11) DEFAULT NULL COMMENT 'Cliente de la secci√≥n Clientes ligado al firmar',
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
  `importe_cobrado` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Enganche + art√≠culos de contado del mismo ticket',
  `metodo_pago` varchar(50) DEFAULT NULL,
  `efectivo_recibido` decimal(12,2) DEFAULT NULL,
  `cambio` decimal(12,2) DEFAULT NULL,
  `datos_json` longtext NOT NULL COMMENT 'Copia de la operaci√≥n: partes, veh√≠culo, condiciones y tabla de amortizaci√≥n',
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
  CONSTRAINT `fk_contratos_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_sucursal` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_contratos_venta` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contratos de cr√©dito automotriz generados y firmados en el Punto de Venta';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contratos_credito`
--

LOCK TABLES `contratos_credito` WRITE;
/*!40000 ALTER TABLE `contratos_credito` DISABLE KEYS */;
INSERT INTO `contratos_credito` VALUES (1,'KRM-CC-01-000001','firmado',1,4,1,1,18,'WAUZZZZZ0SS100555',21,12,'Cliente Prueba Contrato',1006865.63,201373.13,805492.50,16109.85,821602.35,18.000,22.00,24,41017.76,162823.88,984426.23,201373.13,'Efectivo',202000.00,626.87,'{\"folio\":\"KRM-CC-01-000001\",\"operacion\":{\"fecha\":\"10\\/10\\/2026\",\"fecha_larga\":\"10 de octubre de 2026\",\"hora\":\"16:23:42\",\"fecha_iso\":\"2026-10-10 16:23:42\",\"sucursal\":\"Manzanillo\",\"sucursal_ciudad\":\"Manzanillo\",\"caja\":\"01\",\"ticket\":1,\"folio_venta\":\"KRM-01-000021\",\"id_venta\":21,\"cajero\":\"Carolina Martinez\",\"codigo_empleado\":\"EMP-0004\",\"metodo_pago\":\"Efectivo\",\"importe_cobrado\":201373.13,\"recibido\":202000,\"cambio\":626.87},\"vendedor\":{\"razon_social\":\"KARMA S.A. de C.V.\",\"rfc\":\"KAR000000DEM\",\"domicilio\":\"Av. Miguel de la Madrid 100, Manzanillo, Colima\",\"telefono\":\"3140000000\",\"email\":\"manzanillo@karma.local\",\"sucursal\":\"Manzanillo\"},\"representante\":{\"nombre\":\"Carolina Martinez\",\"rol\":\"Cajero\",\"codigo\":\"EMP-0004\"},\"acreditado\":{\"nombre\":\"Cliente Prueba Contrato\",\"rfc_curp\":\"PECC900101AB1\",\"email\":\"cliente.prueba.contrato@karma.local\",\"celular\":\"3140000009\",\"direccion\":\"Calle Prueba 123, Col. Centro, Manzanillo, Colima\",\"identificacion_tipo\":\"INE\",\"identificacion_numero\":\"IDMEX1234567890\"},\"vehiculo\":{\"id_producto\":18,\"tipo\":\"auto\",\"marca\":\"Audi\",\"modelo\":\"Q5\",\"anio\":2025,\"version\":\"2.0L TFSI Turbo ¬∑ S tronic de 7 velocidades ¬∑ 261 hp\",\"cilindraje\":\"1984 cc\",\"vin\":\"WAUZZZZZ0SS100555\",\"numero_motor\":null,\"color\":\"Rojo Tango\",\"color_interior\":\"Negro\",\"condicion\":\"nuevo\",\"nuevo\":true,\"codigo\":\"KRM-CAT-AUDI-08\"},\"credito\":{\"precio_contado\":1006865.63,\"enganche\":201373.13,\"enganche_tipo\":\"pct\",\"enganche_pct\":20,\"saldo_financiar\":805492.5,\"comision_apertura_pct\":2,\"comision_apertura\":16109.85,\"monto_financiado\":821602.35,\"tasa_anual\":18,\"tasa_mensual\":1.5,\"tasa_moratoria\":null,\"cat\":22,\"plazo_meses\":24,\"mensualidad\":41017.76,\"monto_interes\":162823.88,\"monto_total\":984426.23,\"dia_pago\":10,\"primer_vencimiento\":\"10\\/11\\/2026\",\"ultimo_vencimiento\":\"10\\/10\\/2028\"},\"amortizacion\":[{\"pago\":1,\"fecha\":\"10\\/11\\/2026\",\"cuota\":41017.76,\"capital\":28693.72,\"interes\":12324.04,\"saldo\":792908.63},{\"pago\":2,\"fecha\":\"10\\/12\\/2026\",\"cuota\":41017.76,\"capital\":29124.13,\"interes\":11893.63,\"saldo\":763784.5},{\"pago\":3,\"fecha\":\"10\\/01\\/2027\",\"cuota\":41017.76,\"capital\":29560.99,\"interes\":11456.77,\"saldo\":734223.5},{\"pago\":4,\"fecha\":\"10\\/02\\/2027\",\"cuota\":41017.76,\"capital\":30004.41,\"interes\":11013.35,\"saldo\":704219.1},{\"pago\":5,\"fecha\":\"10\\/03\\/2027\",\"cuota\":41017.76,\"capital\":30454.47,\"interes\":10563.29,\"saldo\":673764.62},{\"pago\":6,\"fecha\":\"10\\/04\\/2027\",\"cuota\":41017.76,\"capital\":30911.29,\"interes\":10106.47,\"saldo\":642853.33},{\"pago\":7,\"fecha\":\"10\\/05\\/2027\",\"cuota\":41017.76,\"capital\":31374.96,\"interes\":9642.8,\"saldo\":611478.37},{\"pago\":8,\"fecha\":\"10\\/06\\/2027\",\"cuota\":41017.76,\"capital\":31845.58,\"interes\":9172.18,\"saldo\":579632.79},{\"pago\":9,\"fecha\":\"10\\/07\\/2027\",\"cuota\":41017.76,\"capital\":32323.27,\"interes\":8694.49,\"saldo\":547309.52},{\"pago\":10,\"fecha\":\"10\\/08\\/2027\",\"cuota\":41017.76,\"capital\":32808.12,\"interes\":8209.64,\"saldo\":514501.41},{\"pago\":11,\"fecha\":\"10\\/09\\/2027\",\"cuota\":41017.76,\"capital\":33300.24,\"interes\":7717.52,\"saldo\":481201.17},{\"pago\":12,\"fecha\":\"10\\/10\\/2027\",\"cuota\":41017.76,\"capital\":33799.74,\"interes\":7218.02,\"saldo\":447401.43},{\"pago\":13,\"fecha\":\"10\\/11\\/2027\",\"cuota\":41017.76,\"capital\":34306.74,\"interes\":6711.02,\"saldo\":413094.69},{\"pago\":14,\"fecha\":\"10\\/12\\/2027\",\"cuota\":41017.76,\"capital\":34821.34,\"interes\":6196.42,\"saldo\":378273.35},{\"pago\":15,\"fecha\":\"10\\/01\\/2028\",\"cuota\":41017.76,\"capital\":35343.66,\"interes\":5674.1,\"saldo\":342929.69},{\"pago\":16,\"fecha\":\"10\\/02\\/2028\",\"cuota\":41017.76,\"capital\":35873.81,\"interes\":5143.95,\"saldo\":307055.87},{\"pago\":17,\"fecha\":\"10\\/03\\/2028\",\"cuota\":41017.76,\"capital\":36411.92,\"interes\":4605.84,\"saldo\":270643.95},{\"pago\":18,\"fecha\":\"10\\/04\\/2028\",\"cuota\":41017.76,\"capital\":36958.1,\"interes\":4059.66,\"saldo\":233685.85},{\"pago\":19,\"fecha\":\"10\\/05\\/2028\",\"cuota\":41017.76,\"capital\":37512.47,\"interes\":3505.29,\"saldo\":196173.38},{\"pago\":20,\"fecha\":\"10\\/06\\/2028\",\"cuota\":41017.76,\"capital\":38075.16,\"interes\":2942.6,\"saldo\":158098.22},{\"pago\":21,\"fecha\":\"10\\/07\\/2028\",\"cuota\":41017.76,\"capital\":38646.29,\"interes\":2371.47,\"saldo\":119451.94},{\"pago\":22,\"fecha\":\"10\\/08\\/2028\",\"cuota\":41017.76,\"capital\":39225.98,\"interes\":1791.78,\"saldo\":80225.96},{\"pago\":23,\"fecha\":\"10\\/09\\/2028\",\"cuota\":41017.76,\"capital\":39814.37,\"interes\":1203.39,\"saldo\":40411.59},{\"pago\":24,\"fecha\":\"10\\/10\\/2028\",\"cuota\":41017.76,\"capital\":40411.59,\"interes\":606.17,\"saldo\":0}],\"otros_articulos\":[],\"solicitud\":{\"items\":[{\"producto_id\":18,\"cantidad\":1,\"vin\":\"WAUZZZZZ0SS100555\",\"motor_serie\":\"2.0L TFSI Turbo\",\"color_interior\":\"Negro\",\"es_credito\":true}],\"ordenes_web\":[],\"cliente\":{\"nombre\":\"Cliente Prueba Contrato\",\"rfc_curp\":\"PECC900101AB1\",\"email\":\"cliente.prueba.contrato@karma.local\",\"celular\":\"3140000009\",\"direccion\":\"Calle Prueba 123, Col. Centro, Manzanillo, Colima\",\"identificacion_tipo\":\"INE\",\"identificacion_numero\":\"IDMEX1234567890\"},\"precios\":[1006865.63],\"articulo\":\"Audi Q5 (2025)\"},\"id_cliente\":12,\"integridad\":\"59d810325e2bfc9d8247559dcac952723a4ad45181a5b85f71e0d87016fd041b\"}','<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 600 200\" width=\"600\" height=\"200\"><path fill=\"none\" stroke=\"#0D1B3E\" stroke-width=\"3.4\" stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"M24.0 153.0 Q49.8 153.0 51.5 149.7 Q53.3 146.4 54.6 143.1 Q56.0 139.8 57.0 136.5 Q58.0 133.2 58.7 129.8 Q59.4 126.5 59.8 123.2 Q60.2 119.9 60.4 116.7 Q60.5 113.4 60.5 110.1 Q60.4 106.8 60.2 103.6 Q60.0 100.4 59.8 97.2 Q59.5 94.1 59.2 91.0 Q59.0 87.9 58.8 84.9 Q58.5 81.9 58.4 79.0 Q58.3 76.1 58.4 73.4 Q58.5 70.7 58.8 68.2 Q59.1 65.7 59.7 63.4 Q60.3 61.1 61.2 59.0 Q62.1 57.0 63.3 55.2 Q64.6 53.5 66.2 52.1 Q67.8 50.7 69.8 49.7 Q71.8 48.7 74.2 48.0 Q76.6 47.4 79.3 47.2 Q82.1 47.0 85.2 47.2 Q88.2 47.5 91.6 48.2 Q95.0 48.9 98.6 50.1 Q102.2 51.3 106.1 53.0 Q110.0 54.7 114.0 56.9 Q118.0 59.0 122.1 61.6 Q126.2 64.3 130.3 67.4 Q134.5 70.6 138.6 74.2 Q142.7 77.7 146.7 81.7 Q150.7 85.7 154.6 90.1 Q158.4 94.4 162.1 99.1 Q165.7 103.8 169.1 108.8 Q172.4 113.7 175.5 119.0 Q178.6 124.2 181.3 129.6 Q184.0 134.9 186.3 140.4 Q188.7 145.8 190.7 148.2 Q192.7 150.7 194.3 147.4 Q195.9 144.1 197.2 140.8 Q198.4 137.5 199.3 134.2 Q200.2 130.9 200.8 127.6 Q201.4 124.2 201.7 121.0 Q202.0 117.7 202.1 114.4 Q202.1 111.1 202.0 107.8 Q201.9 104.6 201.7 101.4 Q201.5 98.2 201.2 95.1 Q201.0 91.9 200.7 88.8 Q200.4 85.8 200.2 82.8 Q200.1 79.9 200.1 77.1 Q200.0 74.2 200.2 71.6 Q200.3 68.9 200.7 66.5 Q201.1 64.0 201.8 61.8 Q202.5 59.6 203.5 57.7 Q204.5 55.7 205.9 54.1 Q207.3 52.5 209.1 51.2 Q210.8 49.9 212.9 49.0 Q215.1 48.1 217.6 47.6 Q220.1 47.1 222.9 47.0 Q225.8 47.0 228.9 47.4 Q232.1 47.8 235.6 48.7 Q239.1 49.6 242.8 51.0 Q246.5 52.3 250.4 54.2 Q254.4 56.1 258.4 58.5 Q262.5 60.8 266.6 63.6 Q270.7 66.4 274.9 69.7 Q279.0 73.0 283.1 76.7 Q287.1 80.4 291.1 84.6 Q295.1 88.7 298.9 93.2 Q302.6 97.6 306.1 102.4 Q309.7 107.2 313.0 112.2 Q316.3 117.3 319.2 122.6 Q322.2 127.9 324.8 133.3 Q327.4 138.7 329.6 144.2 Q331.9 149.7 333.8 149.1 Q335.6 148.4 337.1 145.1 Q338.5 141.8 339.6 138.5 Q340.8 135.2 341.6 131.9 Q342.4 128.6 342.9 125.2 Q343.3 121.9 343.5 118.7 Q343.7 115.4 343.8 112.1 Q343.8 108.8 343.6 105.5 Q343.5 102.3 343.2 99.2 Q343.0 96.0 342.7 92.8 Q342.4 89.7 342.1 86.7 Q341.9 83.7 341.8 80.8 Q341.7 77.9 341.7 75.1 Q341.7 72.3 341.9 69.8 Q342.2 67.2 342.7 64.8 Q343.2 62.4 344.0 60.3 Q344.8 58.2 346.0 56.4 Q347.1 54.5 348.6 53.0 Q350.1 51.5 352.0 50.4 Q353.8 49.2 356.1 48.5 Q358.4 47.7 361.0 47.4 Q363.6 47.0 366.6 47.1 Q369.6 47.2 372.9 47.8 Q376.2 48.3 379.8 49.3 Q383.3 50.4 387.1 52.0 Q390.9 53.5 394.9 55.5 Q398.8 57.6 402.9 60.1 Q407.0 62.6 411.1 65.6 Q415.3 68.6 419.4 72.0 Q423.5 75.5 427.6 79.3 Q431.6 83.2 435.5 87.5 Q439.4 91.7 443.1 96.3 Q446.8 100.9 450.2 105.8 Q453.7 110.7 456.9 115.8 Q460.1 120.9 462.9 126.2 Q465.7 131.6 468.2 137.1 Q470.7 142.5 472.8 147.6 Q474.9 152.7 476.6 149.4 Q478.3 146.1 479.7 142.8 Q481.1 139.5 482.1 136.2 Q483.1 132.9 483.8 129.6 Q484.4 126.3 484.8 123.0 Q485.2 119.7 485.3 116.4 Q485.4 113.1 485.4 109.8 Q485.3 106.6 485.1 103.3 Q485.0 100.1 484.7 96.9 Q484.4 93.8 484.1 90.7 Q483.9 87.6 483.7 84.6 Q483.5 81.6 483.4 78.8 Q483.3 75.9 483.4 73.2 Q483.5 70.5 483.8 68.0 Q484.1 65.5 484.7 63.2 Q485.3 60.9 486.2 58.8 Q487.1 56.8 488.4 55.1 Q489.7 53.4 491.4 52.0 Q493.0 50.6 495.0 49.6 Q497.0 48.6 499.4 48.0 Q501.8 47.3 504.6 47.1 Q507.3 47.0 510.4 47.2 Q513.4 47.5 516.8 48.2 Q520.2 49.0 523.9 50.2 Q527.5 51.4 531.4 53.1 Q535.3 54.8 539.3 57.0 Q543.3 59.2 547.4 61.9 Q551.5 64.6 555.6 67.8 Q559.8 70.9 563.9 74.5 Q568.0 78.1 572.0 82.1 L576.0 86.1\"/></svg>','%PDF-1.7\n1 0 obj\n<< /Type /Catalog\n/Outlines 2 0 R\n/Pages 3 0 R >>\nendobj\n2 0 obj\n<< /Type /Outlines /Count 0 >>\nendobj\n3 0 obj\n<< /Type /Pages\n/Kids [6 0 R\n14 0 R\n16 0 R\n18 0 R\n]\n/Count 4\n/Resources <<\n/ProcSet 4 0 R\n/Font << \n/F1 8 0 R\n/F2 9 0 R\n/F3 10 0 R\n/F4 11 0 R\n/F5 20 0 R\n>>\n/ExtGState << \n/GS1 12 0 R\n/GS2 13 0 R\n/GS3 21 0 R\n/GS4 22 0 R\n>>\n>>\n/MediaBox [0.000 0.000 612.000 792.000]\n >>\nendobj\n4 0 obj\n[/PDF /Text ]\nendobj\n5 0 obj\n<<\n/Producer (˛ˇ\0d\0o\0m\0p\0d\0f\0 \03\0.\01\0.\06\0 \0+\0 \0C\0P\0D\0F)\n/CreationDate (D:20261011002342+02\'00\')\n/ModDate (D:20261011002342+02\'00\')\n/Title (˛ˇ\0C\0o\0n\0t\0r\0a\0t\0o\0 \0K\0R\0M\0-\0C\0C\0-\00\01\0-\00\00\00\00\00\01)\n>>\nendobj\n6 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 7 0 R\n>>\nendobj\n7 0 obj\n<< /Filter /FlateDecode\n/Length 6240 >>\nstream\nxúù\\Kw[«ëﬁÎWÙ9„úcœ°·~?º\ZÑl8|§5ìDY@ $¡\Z 5˝ë¸ØgÈ≈¨fóùóYd1«`™˙Q› pIPqL—Ö{ª´ÎÒ’Wu/Ù‚«å˜∏≤¯ìÛ˙Si¶UO:Œl0Ω`õﬁº`b˚\"¯˘e+íõ¯\\Àw.]ø{!ÿ2ŒæÉxÒ#^b|(dÄüR;ºƒr›\Z÷‚=ªﬂÄ¿√QÄ´,^X¡ã@˘(ê6	\\œÆDœ¿ØR»∏\näºä)≠{VGëê≤«·S≠BπJhﬂsp£·¢à$á·+ëÓ…Ä\"SE†ZKëH(’spï≥uyX6¿!ºr§¨ëNÁ¥*…@Ì$¶ß‚°=ÏE∏ÑÒÿNG]Ö∞6ØF¶A˜L<•Ò:ã‡Õ£ãΩ./P$ç ;*ﬂì—™¬áû.äee¡:T¢2¿5ãÁÂàõ8∞r9`tõïE`¡v\n-l™kz\Z∂‘úú•dO©‰´,ÔéUE[£∆r…ü\"g¡ﬁÉ»≈ã îùƒ`2*	úáèW…<b¡FÎHûOöh{*Î®‚Ka‰H_\rÅé2tÌzLkEÒ\rúÖ˚÷`…xJœÈL∏ëâ+·!ER/Ä3∏Dâ\n.{ AêDOóù\'t».∂º∏ÿB€Ìÿ@§L2%®@[É Ö,‚R9ﬁxâF∞O±¡9\'ΩœAõ9pgATYw«€4¥›‰	ÔÃnIdB4\rxÑD∏Ü⁄ 9â•,äxªñÉÂç™kÅ™c¿÷úÉ_\\•<9îgîëxc»\"õE*&-Gó,±9U≠HÊBÁ d¯≠à√ 4éåwIW M•>.›Ê≤ˆíqe\'sﬁjôØq:{º¨£gúÀ◊Ä…}º∆ãº∏çôÌUÜO8´â+{Î(s“ ﬁÁêGC∆ªBñhéò]wÌ%°Ymä;J∏4Sí¨œ!Ä\r¬nı$áS+ºœUp%GT®W¡ô§FCVëqymÎçê)òwÄ5¬BÑ>#´ø°Ñy∏—ÿä9¡«£⁄\nn¥(2¶Ω1`Ñπf-ï∞?4¯W¡ØÆQÙ	\nq∞.üÅœÖ\nç&e¯.&ä¿›X’–md/£Õ;’⁄S\r<h‚}J\0&L†R∞í9L«‚ã S$à\ZõäJ(ï (A¶*ïû±ƒc,õòˇÂ|ûÇ]rº: \rëk⁄#C§Gå\"GX PÂ Z\0\r!Aï¢´R`SU$‚Ú∆ÿ\"≤ô\ZI\"ôw4\\%\nÊkWJ.îä†M!hHë™d·>q-MÃéù Aïƒ∆î≠™lQ†*ƒï.zA9HˆR%ø9O,D™ËD_\"Dzô]∆3¶JÄlÑÂ†ëêÚQB)aE,âﬁSà¢Ö0™,qò^ßRã≈GÂ`Ñk~É„-≥´u/ù»QPwãuŒ) I8òD\n \Zæî–º¬-ò!—j◊HLÃGﬁ‹ÖÁ2∆7{°ÎMeuPŒ±∫iO–ŸG¥ß¢\nÈåwiEy¯ÅG˜¿\Z\nÛ]$ãATä§$/L•Kä!\\\"Ä*YˆíVñÑc¿í§(}.+PçH~7#%-%r¢q*C≤—Ï™djê¢)<]∫√:Ws∞Å4[±ñ◊2%Hñ\0t$>mJ¥ÀIe≈îª∞`≈Í¯∞®≈Bó£´∑OtKÁÏ\0o‰-\0\0©óäè.E2…Ü§uñÄ•t ≈\\fëxÎdWx§ù€≤ê*EU)ï--£W@í9\nzE$∂Ú:ê+Èd“ÊXÄËêâÁS(‰?…á*ı9 êÁe¢wä £åDj§ÂJ.≥\ZÙJÿ\'¿Æ®ΩÆÖ	ºäzhGMÉÂ1MçVÿ*%dE}ˆ≥¡\nô\n	ÍåU∞ÓÆì]¨†<@∫ày©kÆàv+{êcπ⁄Ü§jW%.ª™6º≠uÿ9ƒ$bÃ€∏N≈$ô˝Ââº@OπõßSHõN\Z \"úO˘î)2¯Dÿ‰Â¥ìía¶–UóÎú*±ä,/5<ZD∆æ0âla√ög‹÷•ü‚ê%!eï0@|£©x$|ƒ\nV™é-µ…rQE	ﬂ≠U$‚ç»G≤à«>§°ã‹∏hV¨¨e-S (Q»ZÆú°\n&rπ¬ˆîË}	 é∞B»4í®Bbo»2A*S«Á•ˆâk˙¬9D∂L‡’9	nÇJ\n*!°∏äÇ3âﬂËH*ïáêà¡í7d≠=≠Ÿ\'ˆi5Í‡î*∂:ŒSÇÒ‹÷:]EAXƒ\Z	À¢€\\≠PHÈêW⁄ÜWb/é\"Q◊ÇO1)çkD*Óhl√wS2ö:@@%ê˝4ıéÉä8ÿ–\r˚ƒé=V< GéAd∑–∂ÆŸœÛ»B˘ +ì›tÒ©ùA^â ®®xì<©é0ÒPà{»#pK[ÃÓaû°8K∞Éu$O≠8èÜ4≥=ìz†\\⁄¿ÉπserÅçeä^^z û¨-år •!D!w`ucSzn/,h\n‚/ûU©‹π)ù-Ñ}öIôH¢ì$ÛRî§Bd Kçk≠à§ H´D‰F)Û€¨£¬~D%†Ÿ?2Bg-ﬁ\n¨)S9\riöÇ2pª]A˜Pî\ZÏâ¿Xg0\Z>√_%x¬\Z⁄Òö≠9òŒ„yìœû}àsÈ )|,D%Çä\r\rR£Ïç‰1c\n®‘\0·:ç˝2ë“hπåÅ˘\Z†Öiv·D»a_ˆrπE–@%2rB∂†/UêtMàhØ®´,w)ƒ1ë$ä,ÔÚ^Ÿ_mπ*ﬁÅàH£$[2Ú OrD£ﬂs	@™»€qJåiÁaQ‚%)(à™∆jmÂbdÍ$1$I˘‰sÛÖë©të \Z+Mô\níHvΩ©ëi”:∫XC‰Û%zAÌ„¡Ôÿ9+\"ÎH‚!îì:®.x.M≠ãÂ%6T¶¬8b¡H¬h…◊ÄÂ]lheï¨Q˚oXÑ˜;BN≈˜íŒÖ\Z∆¶®ÿπúIJ\"∞ÿ0•∫#3âÛ‡Kdû⁄$oS¥x–0°Ñ˜…Ú#u˙>gä«ÏL3ó<Çäd\'°Ø(wï*è¸,–Ã∞\\ÉÑ(≈O»ÕyÄ≤ëõz+´$Y,Slî§Xµ9#±JºÀ\"NÍp$©’îçsœìÀ:®≥»ËkË§â0YóÌóömÎScÈ}…S[ÏÉSÅ,QâR≈HåÎ*¡]Ω≠◊®Höº•‹…ŒC%À\rèJå¡R[k2u¬§Hÿ+ìùÒ|)ó#äÊkRÓ äZ—é-#B∆Afã´ò{ûòb&FâßX’!a@6ï%6íèz\nÉ4$§8,íT´kö‹Ó¯L=kM¡…O&Ø9s—;)∆êîêuµ…Rû*ºihx¬ﬁRøjå©¸d#∆X&Êæ^ì⁄8aÎ:2I“T≤ÓÖL£ËìX•R∂ÊNZπL“B‚48Ö…^o\'§--£wçU…J¿‘z\"äª”–AAcÜxjíP‚EK*QÇ®ßâÀ†ƒƒ∫#Ií∞R}TπIR°ﬁïHyed\n∞-•(¬ï&Æf	≤ODQä\rï≥[¡)ÚLJeTßÜµX5÷Cñè»ÔË\ZgE√Hîÿ≠∫Ûê#!oz˚Ø/~ˇ|ıÕ•`Ô6¯ßƒ?˜>Ô˚Ìâ`≠6∞´k¯iˇ’î}ıR‚c=¯˝-c˙¸w˝Òiˇã?≥´ÔÚ3E∏dxı+åaò√öaã,âaÇ¡Öøz)¯∫]é]ˆ˙=v=cÉﬁ´˚âıﬂÕñ”˘ÑMÓÔV7´ªı¸#/Ôß˜ÎÕd¡N\'ÀèìÂ|±X%5`˜∫¢èK\'ÿﬁ®ˇ°«NÁÔÓg‹h1ÅeÆ◊ÛkÏ¶éö%èÿ`µòﬂL`√´Ÿ¢¢%˛è6€µ·¯õhÆ¸dıOå˝~πé˘,7Ã‚\Zeô–i|Ö-*¸±û±K‘‹‡î¬˘ÿÕ#¿D„+ûç/ò•3ŒœÆ∆˝´svvﬁ€ÁÇ˝æ’.-Á“$ïL£‚√‹‚ÑÒÈóÉ¡ó\\|O*ö£Ó˜™∆èí,≤+≠Q˘¥ˆ«˛ŸË‰‰,{~2gˇ[ˇó\\Zˆ”Ó9–$…A%ojÒ»˙¬~-’◊Zh`F¶q √a5>X«áA.z‰Ìãƒ2⁄üÈÃÒY¨ÖF[À§í.)Êªn:¬ôO/∆˝W√≥´>Î≥¡¯Á„|\0W∞Òr8~’«ãéœOGg£Û}gpﬁ3‰~BÕœ∫ƒ—ù∞± aeŒ—Ó…£ØfÔˇ9Ω_¨J\n≠÷ly?˚∞„øú/\'ò]7ÛŸÚn≈ÆÁÎŸˇú±›\\l!ƒ⁄ƒü°1¶¡vG ÷òòÅ—ò<.∂S¯z∂‡ê+Hk> ÄÒ>)‚}\\Ñî`⁄_ZÔWÂ¿)À°ÆioK(@Ásüæ?cG€Oœ/¡É—ˇû±ø±ãÒ˘Ü¯®?Ëˇ|:\Zúß˜Zëx–~k—Ï¿Ü6~9®ˆömÿ˝í]Oí\rØg7´Õ›z2ùˇ∫dØ?_Æÿá_ÛkpƒÚn∆\0|.˚WØø`⁄¥˚ñÉ	l‰√Ó∂”≈/˜õ{∏âmVK6_‹„&wÛìÕ◊6y?Y≤\rn≥û}òo&◊p›-¯ª]ØﬁŒ6Û’rÇ¿áˇÇøﬂØ@∏Ì›d\rzÕ˚ÿá	®9˚»~∏_ˇÛz>ùÙÿ…j√Ê7∞Ã›lsƒÓ&õ	¸qªò|˘_„Å7JÔóÛÎ…ıæ„‡˚\0NÌ¥˙\0Ò7[ÊV∑≥l≥ıÏ›œv=a)(ºÅˇú›L™ó~§¿É:¨úe7å2\nÃ\0˘‘~øDÌH†Ò2$¥L¸;[v¡}ÿá˜§êDP´›%‡˝g‘dZ\"RòåÅ∞kú@…>Ëèˇ˚Í˚ìΩU9(ïU∂1ms_‹â\0Æ¸Ïä∫§≠ã∏Ô¶ü/g∂]\'∆∑\0$:ü‚`ÎR$xbL˜|ëïŸ[Q\0Ù[ÉãòÔÖ∆GˆçÃ÷^\"•©u¿ê\rÆ ›êÔêﬂgﬂ˜Oÿ’˘Uˇ‰ıœ®ìy/|ZÔjô4dgúIˇÜmë|A√lﬂÇa^ÓÿÃólÙ™O∑ƒá\\¢5ò‚â€∂√´¥h-FíLÜqÇ=ƒfW˝ÀX~FgW√ÒœóÏ||<:ÎèG{©]W#£}l›hˇ√ÌN„„[!˜ËY8X˛Ì¸á	ôüÿ9ﬁöGNÿéµ¶DÛrﬁöí$òRâÙ€”¶<=«öC,zR\n˝·F†≠bè#ˆ·3/≈éWî!#‡ëehç@ê”& \\e¬VIc¸T¯ˆ*íí®:Ω¢˜<SıŸEˇõ˛¯9Z∂È6ï#dﬁRU3eò¬â(ú£Å©,ia*√\"¡T|ØÂ@ò¬Wåy‰\'˝?û≥ØÿŸﬂOá„HR¿\0Áóœ)ài‹ûÛK(<≥\rêíüò‘[%9›©=ûo_ñ›Ãñõ{dìÎŸf≤»xYçÒ*@Î…!Ê#x“~¿Ì.\\F«˝cˆrÙ›ﬁí˜ tZÓ3-éxÏëvAÜO ”æBJ9|ërx ¸ßÉg<Ç®a`?π\Zùû3Ë*£”“›O\0öN;`w&Rwˆ∑⁄™˘]–!£Ë¥ÈDC˘î%≠Q*ƒî´ä‰†¥+h§Èñ∫”sl–ˆñ∫\'°ß”pg+v;ôﬁÌP◊á8§ΩÄîjq®H2≈ãq7‰isQñ4`Ö˜È-∞Ç&*‰kû\0+ç8oÏ£Ò6år˝ÎÒ3¢¨ÏÅO\'åﬂólêk‹y®∞©*`”ZàÆ\"—Uçâ*\0ë‰\0#∏x⁄J√≥o˙gÉoáÚp<¸ÊYf¢]∫Ì$π8¬Å#ú`´O âÔ≠;[Í˘˙s|yãˇ¶0‡Õ™uöµ÷•´»∫tUc›äp≈∫$9¿∫Ñû∂Ó‡¸ttâ˝˚≈˘òı/Ü„´Ô«œHZ⁄Ëë@¥GØò-˚‚$w\'Çÿ∑µm≈j€ä[π]Æ\"€“UmrPRvIc€\nîÂ*íÕûˆ¿˘’∏…íŒœÜœ·*e|“Æ1Îî™}3_ŒÀ∏$2&∑ã˘t≤≈[ *\Zt“bwïã…ª8^ôOÁ∑ìÎ’æe:≠ê±VÇºŸu2vïπá;l_O†Y∑ö/ﬂÆ÷78I≥êõÆns<«õN”˚Ë‚T&¯è∑yÚvΩ:¬ô‹2ﬂ‡»\'5ì€Ÿ˙Ó6àì!Y\\C«pãŸÊÆîÏôáË¯“©©ÛÕE‘Y«>â‹ë§˜\nuô\"¯§yﬁ.‘VJd…\'ÕC4w‡,˝»<d‘c«P›/±rùÙŸ9†Fú˛‘ø9Çf<¸ÈdØÍº√À’bæJn_‚n’DZu\nùèPêﬁß\';Ìí™YÚŸ3x f¯!J~ò-Ô&Oj®uz\"ÿπjò’ì≠z>Nj}¿Au>ÖÉÓä|ı@rùÀ±¥UÚ(\\eá‡˚Ö{µ∫ïáC[L¢]º÷ßÌÌûV◊~{ûA=\\?°∂”áêºŸµ„`Ú√\ZG@πøÃÓ∂ NªEÕ±CéI.tS.aX‹ó˝Kò≈°@·§˜≠C≥‰á\Z\Zà=¡;õæüÏzìˆ\"koÌıÑ7ª6Ni≤öﬁ›øY„üaÛ≥ÎX⁄ú¨~¿A…±]õªZOv˝I{ë?8(˘≥Û†˘i{˝˘{ÿ6>ò:¨\'∂ãn^IãûtfO¸„øÊ”UKÄr4(€Ñn£!KââÉ˜∞7gk|∏±π]-7ì7ãŸnh–∆‰Ø≠çüçÓù◊\0£K|\\ºæÉ⁄ˇq7,hcrﬁ\'¶∞Ë‹¯◊Î˘ªﬂ≥õ€≈H√nê–Œ$ô\\€µÛÙA^Cê|ò≠ÁoÅH]ÔÛ4æ◊DÎÈ,i∫X¸ãÎEErH8@•◊ZÌ±ÕÍMåÿÙŸÔÄRΩﬂ§˘©—Ó°2ı™mıûö.˝ÜogS‰Üª±BZë≠ÍPØ:ƒhQ]Zç“≥<‡,o÷{√âî£pj˙@ïz’!&£†ÎRÆÌsÇDüŒﬂÃØW˚ I””ŒÔ]B·’`ÑüÄÉﬂº˙Ûôç_Ñ‹%ÀT©P…2~ÈïÔìò	~YMW≤\\üDñqø5…/íO\"À¯ù\'ïå’EñÅ-èéágW£ó£AzTiÛ%ªËèØˆ∑{>TÒ˝+¸\n~”W\Zﬂ`√/0ìüÛÁ7∫$Ùv§4È´ZB≈VÔ—˜1ÚàI‚´‹>xEﬂ	(qÒjxv<<>«¡i0∆__ßèˆ?Ï\0•Ù2úå_åojk1‰xÚzπÕ\n\Zº≈”Ì\0˛Õ÷nØ÷6µèæãÒ∏Çªm≥G¡óÉ√ıÍZÙJØCO∑RKè‹æS7wæ˛|ﬂ;M]yÍ\\¯\rvU:Ü>z:«^ÁıÁõ‹l-˚ƒQª÷=Ùç±÷\neQ¸F†hqé&\nÒÌ≤Cœ,ÇÆ€]Êj∂¯«€’r¡tµ^œh@ãf]K÷7›\0=oËxˇˆó…˙f“[¨¶[a˝∏⁄¯˙ΩŸó#≥[‡pÿé.Ôfá´‹.◊&I79kÔ∆oÀò=°úIeÚÌf˜Ì¬Ún⁄ÉÂ4èµ≥\\°MµËãÙ˝jºﬂ8!\0ƒ◊>¥ÛãN{Ôƒ/x}\n,*¸≤à9”´ièG]3˛.¬aìñ]àx∂∫¡~\nGcãŸ3ÕCÕNP,ùµªXﬂœﬁLÿ`w¯ÚÑ¶è@#d“‡˚Ò≈·Jv≠u1ÁÇã˛oô‚d’∫Pht\rGé$<æµÇﬂ)0§fÁ∫gC»Û≥Vˇ”·©¥±Œ~∞ Òª¥˚0ÆÚ-Ê%éB◊+‹πÍ`≤XêÎA›¯¶nè\rb˚⁄	»¥lÏ»tË.h{>\"ìj]K\"ám(¢ªêmöÚ§wç’+C ΩPNÑX‡_„u%ƒÇÎ(®dwüƒÏHÄoõP	q|!∆€ïkï…\'b![ÍQBºèü∞W√oˇg˝…3\02∑±–)±gEk˙ÙX∂4õ]´ÙÔØÁœä;UYA3}@ƒÊ¨kôﬂõfâÁçÖΩâ}aùdA3K¿oè…vŒòLùœ`˜ÔˇVÏf˚ÏˆØìÅF°\n‘k∂4z‹ü]*A[≠¯`Ô:hîy∞wΩÊ\0Ûî∏ËRÊj~ª;\' eJB∂Æ⁄ﬁª^sÄeJtu:_eˇı√º≈.ˇçÙ\"~:\ne{ú§(h=iTPüiÓ˝÷I°Ï·£¯Ïx5ΩøIÔÀo˜/§@Qá:ô‚W=¯£z]¸ÚÈ¨¿]t≥Ùˇ\neRe\nendstream\nendobj\n8 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F1\n/BaseFont /Helvetica\n/Encoding /WinAnsiEncoding\n>>\nendobj\n9 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F2\n/BaseFont /Times-Bold\n/Encoding /WinAnsiEncoding\n>>\nendobj\n10 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F3\n/BaseFont /Helvetica-Bold\n/Encoding /WinAnsiEncoding\n>>\nendobj\n11 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F4\n/BaseFont /Helvetica-Oblique\n/Encoding /WinAnsiEncoding\n>>\nendobj\n12 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/CA 1\n>>\nendobj\n13 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/ca 1\n>>\nendobj\n14 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 15 0 R\n>>\nendobj\n15 0 obj\n<< /Filter /FlateDecode\n/Length 4532 >>\nstream\nxúù\\Àí‹∏ï›Î+∞ê#Ï\n¬ã 8ªtIrT∑•n´™Â?Ï¨ÏÍÏ©L÷dfilˇà?•ø¡Î˘Ç^Œ¢WﬁyÂãL‚ÚÚeG∏™Ö\"ŒΩ8\0ô˘Bp),Éü“¯ü™fá˚ÇªZ0ˇ”¡œZ:ˆÒ7–hJˆøL∞/ÿ˚3¸«¥i[¬%⁄˘ªç>ﬂ˝Î[f*.î`ïñºvé›ﬁ±◊Ô$s‹∞€Ô˚„/?m«Ì?˜ø˙3ª˝ÇΩΩ}1ÀpdÂxe@äãﬂ≤€w7◊ÏˆÈmÀ~d7Ïth˜€5ª€∞ä}ﬁ<¥ÎÌ]s∑9¬ﬂîïÏ˚G¯Y·ı\Z˚7äóûØ™†s¡v–±· ˆ-Ïf1XYrQÈô`Ø?∞◊Ï√øvõCÎY7áÌª˜¥cZX.ƒ∏ÔÖ—Œ5È¸˜´o˛‡ˇ\'nn§eYb«„nvÃËäW&/h-/E\"Í>ﬁ]{j}™GùÏXikn\\^ºFJôT∑-;lÓ∑«”°πkŸfœ6Ïˇ‹Ïö…hCJ:⁄]K∆h€⁄qYVSWÌC{`õøú`îIÿ„.»0:Ms¥◊èÌ-ªmˆ˜Ìt|±GL}Fòa|‚‹ÓGqé˚ √õgﬁhØ6˜áv<ê∂÷\\πödh…H\'°K9ÌÍÀÌCª€Äé~ÿ@˘Æ€˝›vMÁ¨q_˝à“ﬁ«m˝(–´∆m}÷Üë,®# 7{?≤˝”Ês√˛3˜Ô\n®çTJ„+ÙÒ°Ÿü\Zˆß_bî}5√\"˙Ø3J˚ß_M°≤\\CEíAËZŒvïå+π®k…)k∏VÂåˇy∑Ω?O5€˝g´ENá	˘·ê~c:‰*Bp|\'LÇ5æì\\E∞∆wí!ßy›IÆ\Z$nA±Ã}˘Ò˝´´’Ì´’7oÆ_	áI˚0m∏tÁBÉ>7<ÙDfZÃ§•‰“*hAò–{∂˛¬Íé9L¶∫¨7Íj≤‡ ¥lEgó–‚”ÒªØs#Ÿ˝—ˇV˛˜¥ÉNYÆÊJYüPÙzª>€hÕEó®ÎOú]}ı·Õı’ıWﬁﬁ∞w◊VÆÆﬂ~\\›\\í&ŒC˜ùW3iK«-å‘d4æ>l÷€≥é°OﬁøÓ†>oæˇy˝Ù–..ñî∂ºÇ(¢¯/e!Ñ-ú-π’.s±í%5H“BÓïVÁ¥Öñú\Zí√‰>ÂˆvﬂÏ◊ﬂo¬¥t◊«;ÓÜ˙†„Ö¨ƒz~©Ñ,†ﬁ∏‘0*?êø8\'˛Ò<[7èßßÛr‚˛øˆsÃõÈX÷ñ;-HjBKFjJgxÂ‘î‡MÛ\0}Ô7\' ∞Å˘zﬂxë|∑›C ∂ÕŒ∑L”’ì	È\ZíIßk¿Ü.(_:Q¶ÜÄ≈$¸™˝\Z~◊íæ≠∏≥vn°±€˙Õ¬9˚Õ„Ê‡c\Z-ˆç—˙^à6÷˘Ki)jÓJØçã.é~<\nöı√”˝q8\Z3⁄∞ä◊†?íúÆ%\'9%Tf9„ÏÔa¢hŸ©=5=Éô“È;«Ï:_»N¨˜óN…¬\n≈u9	◊Ä	:M√ÌZr¬Ö…\\Ëø∫méÕ≈ÁaŸ˘ˇG÷Ó Ë√vFÿ?F<Ë!‚òZ˝Ù–Ïü ·ÔÆøXÅ,§_(C„n≥?˙Êc˚ÌasQ…ò€áßS{úQÑ™¡+ö¢Æ%\'E6K≤^N—Æ=4∞ˇöKˆè)\ZÙøê¢ÿÅ=6Î”dÂô˙º9∞ı√OO«ßáÜ›¸„Î€Î˜´ôºH‡r#yÈZrÚ\"¸.cfcÀ`p’°^VÁ·ªıUC∫˜FÚ2Ë!/1Jq…qªg◊üV‰Ë–¯í›xç|◊vÕi˚Û◊ãˇÔ¸ﬂ˚ç.;¶.πiˆŸ	-Ÿ1ŒÔ&fˆU_?4k°Ô}økø®˘rv2…Qœ\"‰h»\"ù£(\r¯Êx9´1C\nê´ö„$∞¬5≤¶ŸËZr≤a˝B{∆qØw‡5ì]{\"”L ÃƒÄ¡B&(ÖÅÕ\ZX¨AâUv≤ıuŸ–í≤ÒªÜ£{∑Yﬂ}ƒ∞ÉZo#käæov–˜B∞±Œﬂ¸‹0)H∫Ω\0[–\"l8•x-Âk%\0·GˆØá”v◊5\nﬂË&˘1Üóé\Zmh……‹R¬~k*	?ùû•<jıÏªs’Å0M\niäqÄ≈à*ú“‹MÉVl\r∫k…	Z¬Ü@ÕlËÍ¢ÅÎæ9¯9}aj@*¸Ä B1./kg\n£,Wzºº*Èé$¥ê£Ì$wù7CKFÜt\ri1≥y∏,N[?ãüóßwªÌ˛|nr>D˘Îe«–êS9ÇÈ b3cÕ˛¥]oÁ÷q}§ò[È8∞˛™a®Èà∆\n∆ﬁ<>l◊Õ~zN†KÀÌÂê14îÁÜ˛`Æ≈NZ*Îˆ˛ú†o¯èŒ	¸Ì¢¶Z-ˇ—9ÅÜ…Œ^Ü,rNpª˙ıoWÏÕ[∂zˇ’«€Î?¨ÆÆˇÔ√ÙÑ ‡˘”Ä1‚ºº8üi√p¿÷ÓÖ<_M^òîÜ+ò*5 Ë∞a—ÃÚ:9€l8NAü˚ˆˇÑ%_NﬂRh_∆;ˇ4c≥§-y©í®aÇy$ zna;%qıÛUò£“4îÖ]ø)ëÜÑµ[\r[Ñ\ZvÖUôâ’∑Ì*∆lOKL¥5–P\rô‘eìÛ†´¥&»ñ Õƒ¿–H•€ª:Oú“&∆ÊrîÅßãGZ∆⁄¶¡@jÖéXq∂ct^Më∏\ZÙ6• ı“∆oõYä˘ÒWêÿ@«oSÆß˜ï\ZL˛‡`¢÷â€§*4PÜﬁV¬m∆§z´jU‘¬\rOˆÍ≤Úgzgk´›yò¬‘„ü∆¿<L=öó‡\"Á—çÍ¯,ÎÈjøa\nsK◊ê≤õ0¥–3y≤€§“aÑû∫0¬,F¬qŸ1út2ÿ°ñbÙºñ‘PK≥<±”éhòÈ—1/X°Ñy)É) 7∆tFæ≥L±”é)NÜÑÍòÿé·ƒïAK&JU’ÖÙÒ,h;•T˝lI®éâ¡ $ÃlT±L£T•,T˜bπÖNëj7ù™cbdµíAßÜ(’ Í¢rfÊƒ÷≥Ç‰ë Ì\Z|á§H!ø¢€C˜¡èÓ\'’6Dƒ¬äABaâÛ$]ıèFP§@Ü‡X1ôZCI¡QΩQpPoiΩ˚g#(\"¬!8Í-\nzÉΩ3$π√ëÕØ¥)l,âBRÊ°`¥\rl“fÃ#\\Q√0[◊+4dXÇÇçëTvJ”dYB ∑Ñû\\PVª†‹(=Ø\\5Tn“—Ñ%ÙLÉLsòÜ2à2}Æ%¶)KË©—ÁP\rEß™E!`Œ42œT#ñ–S\r%îC5îhú™ÙY’ÙaH“z™qKË©Ü⁄Œ°\Z\n>NµP≤Ü˚«ñ‡Y)]ë Ì\ZÜñ†*≈em¶–Âÿz@*|ÇàÖÉÙÖ•Á-°ßZ%‡X1Ñ%Ù‡T]’ı\Zÿ≤õjb	=8’GΩE¡•\0ø—\\’KË¡Q6CpTH‹V∞h\0Æva!dQñV•,¡:ÆEIÑ’5‰XBÈ8å îÊ¬zÍ»%,…°≤2ÿ°rcÙºrÕs,°#ö≤dä2Õ`äec˙lKËò&-©¢Ë3®bQE©BQ’RR›ß-ÅRçYR≈ †ä%\Z•\n%ÍEb∆;E™	K@™X€T±‡£T≠QÖ+¡æ&ÁÎûï>ømEÍIw/[ë\"5–™Â∫öXR·D,¨§/¨2b	NµJ¿±b‡)K@p™.éÍçÇkˇ∂ëÅÒüZÇS=p£a_ßò◊#wbÍàç™b£@¢ÿ÷oA*ê⁄íò;’\0†≠Îî#¿üå—DW]Cé#@*åò9syé–ëK8íCae∞C·∆Ëy·⁄Á8BG4Â»Uö¡´ ∆ÙŸé–1M:REÕgP≈öäRÖör≤±0¯ÿ)•\Zs§ä%îA+4Jµ.§_s-0≈>ëi¬ê)ñvS¨˜(”≤ÇŸDC5‘CÄ{KI|C√»$taÎ)t=1§∫\'àXW1H_WUƒúJïÄc)ƒ¿SÜÄ‡T\\≈◊˛¿ñÒ3{ßz ‡(∑(∏˚èô-b£jÜÿ(ê(vi™¬?+Û∂≤v‹iõ2	ø9é\rI!;ƒ#‡R={†òÂÅ]¬ê*+É*7ŒÔµpœpÑ@4Â»eö¡À ∆Ùπéò&©¢Ë3®bQE©BQ9·‡ñ<GPç9R≈\Z †ä%\Z•Í\nEdN7Cü=”Ñ# S¨ÌúB\neZJSîB“√8R€÷êÛﬁ–&ìKëJø≈‹Ÿ©[BèHÖO Ca≈1°∞ÍyKË¡©V	x®Ö(x¬zp™.‘◊∫áı L,°ßÇ ‡Aoq™®Ä8ô¥«HΩl∆£ÿ)$ë\'AÕíÀº=Ç¨¸€;:a	“Aí„»–êa	˛C]˛3ASe‰=\\Ï‚ñ–≥Cee–CÂF˘Öós-°#ö∞Ñû) 4É)ñAåÈ≥-°cö≤Ñû*ä>É*Uî*UU◊ºZòh±SJ5b	=U¨°™X¢Q™U°¸\'\rñ÷U°Od\Z∑Ñû)÷vN!ÖÇèè?¨ç∑Ñ…©ëgU9K*∑kYl»kê§&ó{D*|âÖ≈o\0ÕXÇS≠p¨Öx ú™ãÄ£z£‡⁄˛É•’å% 8GΩE¡-XÇ§z#ŸåF1($ë]ÿÉÿÖ„⁄ )ì\"e	•ÂÆ$«ë°!«\\*’å2Ú.v	K@v®¨z®‹(øæQÆ%tDSñÄLQ¶L±bLüm	”§% U}U,™(U(*ß$◊πñ@©∆,©b\reP≈çRµÖ¨°‘r-ô&,ôbmÁR(¯xR+ÿ—TzÊCÅ~◊ä¯ÜÜë%h≈ùõ;<ù<\\Ó{· ±∞¢ò·}#7µÔµ:\0«ZàÅß,¡{u\r¿QΩQp]\Z∆ŸNü$Ù‡Ω ‡®∑(xYÄ·ﬁ!ŸåF1($N‹®¢Vu∂%»∂B.e	 AAí…–êc	∞“™Õ‹ëbﬁ√Â¿.a	»ïïAïÂﬁ7Z8K∆N;¢)K@¶(”¶X1¶œ∂Ñéi“ê*ä>É*Uî*ïÉ…Àeæo4†\Z≥§ä5îAK4Jµ,¸4_gæn‘3MX2≈⁄Œ)§PÒ§ä™e…]5±ˇπKé|C√»¥ π””…√Âë\nü@baE1√˚F3ñÄ‡T´k!û≤ßÍ\"‡®ﬁ(∏∂ÖÅï|≠¶ñÄ‡Tıg^X¯õ3SK@lîÕhÉB¢ÿ™ÖÕQÛE6Æ‚⁄ï)GáP™&∫Í\Z2°Ü≠êõ;PÃ{∂‹qK¯rCYeê≤ç≤Ô\Ze⁄AG3Â»ö¡3T@åÁsÕ†„ôÙ$äjœ \Z™)Jä©I,=@\n}R¢1\'@¢X:DCe∆3\nìkM◊ÅI#@û	@ûX–9Â”Uyîß“∫∞¶ê…Œ\08…öúÚvˇö@çe9£¸…ÛdÑ#b\'x°î¢Ä·Ì¢© 2ë\'A‚è!\'fD&z\"»A≠Qd]˛{*f^5Ed¢\0Ç‰G.Jò∑g^3E‡†í—∞uzà√é∂ê~ß∏Ù6D¯z%¯ïz≈†î%\'é›ø…ß¿Bkrt‘˝;√¸ã∂jÊ|KÂ=^Ó∏«Mπ•ÚC≤˝%ÏÉ‘cÙÒ}§L◊Ë‚H∏ÑMÔØ…à$îV,íÁ˙JI W0îPI$îÛ˛öåPB-GC—ÆïˇÜº<Á°°DúC	µKB1ÔØ…%L—P`ßµgó>X‘˜xâ$ÓM	~±(©Ú!q˙’gÀuﬁÕV—Hd	£R;¯+˘˛¡çÚñ5•ˇY^>\næN‡ÚÕ˛Û—jŸ<ÀÀÙÀ’«˜+v√W‹@˚ä‚ÏGv’ÓO˛Kõÿ˘ÎØ^	˘J¯ˇI¯€õv˝¥Û∞˜◊ﬂmvm¯≤	‰Ù‚w¥¸∑•x}˝”˝vﬂ0Â{1˙ﬂÓ71\nendstream\nendobj\n16 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 17 0 R\n>>\nendobj\n17 0 obj\n<< /Filter /FlateDecode\n/Length 4304 >>\nstream\nxúù[Ms€F∂›˚WÙ¬SeW10\Zﬂ»¨8„aFíÚÃÀh-\0¢ë ïQ˛ÿ¨ﬂ2Î∑õùó^x1•]VÔ‹Óí Lç+ñhËæÁﬁ{Óm‰ïip”c¯…˙iÖ¨\\æ2ç 4˝3‰õΩ«E€wŸ/Ãdﬂ≥ø3ˆ|àq—Ùl˝†iXéOè;ñ·Z&Û≠¿mã9¯¬ÂåªÜÈc˘Ñ=º‚Üiö¨˝è˝i¡\\«∞8û¥m√∂l∂àŸªÔlÊ![<0ˆ˜77bYº˝[|œ∆ãÓΩÀ}ﬁÏMˇÙ¸≥ˆÊ¶mx?Ω˘á$è“Uö‰õØ»¿=◊pÌ†\"Ù\rœ<OhoxÅ{Zà—∂ÿ∂JÚj+≤~1,œ6∏„6bpæÏ≥‰∞Õ–›OÔãº`ÇEbùnæ&âÌ9∏‡ÔK∫gI‚¿\"æÌ˜cÇ≈	KÛMR~Æ˙%q‡\ZnY-I√v√Û¿…aœ>ﬂÃElù‰1Å$iI“c¥`\0¿AÅÔ´ıÄ?√“ÎYºYB‚”É;Õ”∑sÛùÈø≥L+h?fY∞=˜N?ˆ⁄·ì˚àìˆc∂ã ¸O?fœÒ+l?Êÿ0{ÿ∑õ5∞}n8~˚)◊Ú«È€åÛp‡∏‹ùñUC◊ßÙ‰πÙ30€©«‰∏”§€p]Oy∑æÉ;x&`+Vg}!cÛØ:†	X«≥˙•´∑““’…©%›Å0+÷‰í3ƒkrJ>BH∞èêN9õMµ†uk	z(◊ä5ÈÊIPûí¥îùí6õjIõ◊ıP∞kÚ—¢6ÅpRT;X∏)¸äQõM€¢Rlâz(ÿä5	ÎQõ‡;)*¯!7¸ØH⁄ÏŸH™ìd;å‰Z1◊\r\'0œ$HÍ∏=ëÙ:0ïQw˛oÖ∂	ôwÅ´/–~ªı†ßâ]èc‘nV<X†l˚K÷qurMä´p?Æój≈«˛‚u(ú\\º#ój!zÒ\Zºßx8ÃﬁÂ„√•Z‹_ºÜ€È≈˘¿©≤w‚p•jº®“cs‡pn∏·Y¡Û!G¿{\nÇ¯Õ›·™æ@µV·°”∫G_8£hxæoòÅ›»Øî¥÷V§¡È¢±”†_[Öâ[7ù°Cßî@‡øÛ+K≠MOeŸ©S√Ω≠Œ°Ù≠ªŒ–ß	∫S˙º¥˛‘˙Ù’üùBuàµ:øu◊\n5Å~Z°Û‚•Ωi£–â*µS®éÎ∂Bá‚∑Ó:C!«‚Lﬁ£êGòÙœ´d;mNW≤ù6uN⁄À\0≤∑Ó:\'8Å·x}xC*5[∫ÿR;†eª1äNC≈r∏[≈‘´,ƒ}&ÿ2…ìRƒÇ≠ãí%[=«€L∂HQ˘9N7Ù1c7€\\~bhk—QﬁΩY•’J∞áÁrµ≈\"¯B‰h1”Xƒ,*r∂æMÏÁm¬™Ñ≠äjS>3ë±(ì˝}Î,çÑ‹Vov˜÷hÙ˙πI§∂ãˆ+$L‘y!€ôµ„ä{t≈3@7p•Y¶æWñwtÄråè1Zè[Vª,’W»π?ºz˜~ŒŸ≤¢ﬂ˝Ól1[~BµÒ˝Ä¸§Ü\'ãHvåa„∞ãÒËr8é&”ÎÒ\\ô…î\'Ó‘\rï^ ≤á˚ıR(àø»•\0+Ω‘ƒ`IîâR∞øgW√Åt?<o#ÂËj¿ØÀ§\"á√_ﬂÓm¯K_ßjπ°åün1xK\0I‹ΩïI*∂Õ´ä(ME´§å∞oöAòºX•9aT  Ê∆– G∆c ·\0ÕæKÿ2	\'ä¿ï,ÆiÀÇ„D¬TDÈsŒR4Êë@ãû»ı≈Zî˙ÁdÚGà}Ø≈â≤» ª¬◊iû¸ ƒ¯éI!J±NÙrXÅRm£mY˙W\"ˇU‰iÜP{¢¯H°Â&}H£gµ_ü.n©WÎ‚Òc]™¥⁄$àO≤\r=«©\Z{$´uñê„´õo∞∂C∫D;¨Àbù&Q¶B∆˝cÚÒK§ÚAïî\ré¨1»¯EÙìIm°	pï•˜%ô¥Wì¿3\\ﬁ‰¶ùÀR<~Z!5UÿÁÓM¨E$€Jl∆ÄDîfi-Pï¸Gdùﬁ2˙g<-a|”L…-√£åy5≠∞_≤·h6æò,Ü”G°s¿∫w;\0RU\0g_*¿Rz6ÇñëLπY≤Ñ˘◊$Wqü•KQ¬OuÓm∞•õ\\èY˛;‚´Ëu\ròh`ÀtƒQ`:‰õ\\\\çˇ∆-€q=?ÕvTdE≈b±)\Z±3h@_æä2Jã¸°û_%‰á(’ˇ)œ¨\r¿\',äå•˜(Ñ\0*\"•ËU¡Òå¿∑î\nA–\'÷ÍAD°˚@É°ä(°êEÅ˙¥Aëì0\r∫∏ëµì ﬁ™@‹ˇ™b¸IFB¡Ú4VÒÜ8îWJXÉvê—q‡æ^PÿB\0È(B,Òº\"üJ∑G[DvZfEG˝tM|¬ﬂ’Odà.Ïjc◊ˇËJ ëõÌñ©/¸Wıìv›6Ö™Ø¸Wı”Â¯m˙=ıst˘ø∑Û€ÀaoÌtBG2kπågÚ„,p3õ\\çg(A”?}?^LçƒæeéyjèΩÿWïÓQVíÉdC0˙¨pµZó\nóMòàÌ¶XÛ|õ<ˆÊm†}∏çSˆÉ€@≠ WÙëånÀä>Œ∞ìkˆ◊·ÌèÙ«úœ—	∏Æ:«ÜUJdËW:ëpKq®äC8Ò\0™TMH+9\'ßb¥¶«:TJëZ6üKdâ¢ÍïY÷‚ˆq¯<I≤ìR&Bj:å‘≥kÜ„\"õáæJ1}8DÀ|¸˛ˆ˙hπôç¡‹ÿˇ∞Òı˚·ıËœ„ó\0áz˙ÓÌˆÄ3ÆÌ$)<Ù⁄z\rDîæØ—≤öﬁ @ßÔﬁ‹^≥´…ÂÂÙöÕ«ì9}f”—üß£…¯z1ù˜⁄ò~€:Õ⁄‹=j>ûcï!tMÆGSv3ûOÁ`ÀÔÄve\\woNﬂ¬	plöGŸ	¥20BƒïNbô‹%\"J™öπF…Z1◊$_ä<˙òP¢Óï€&ˆ‰)π]nÀ-	(’W≤óeÚÅM›YÎb:◊ña pl17óÊ„Ö÷óÆju˘æ∫…œ€ÙuQ∑B…¯rTØ»<@æ0u‚;G#Qq/ª:E;#ÅNy&NNë–UßDÛYÚêDõÙQ€ﬂP5ƒ_¨ÖU¡ò\'õ÷…≠˙\0\núG©Pû_a}ä\r\Z∂„†|òÓ¿	)è√∆-¯i‹êùG∑√≈¨π~=˝†-\rèhCªfÀ–gG≤™≥kU>BÛ8í„ŸHÊ˝´)ˆf¿Êhˆ†IA=ö^MÊìˇªf7”ﬁågã[‹z~Ñ€&‚Â∂[åΩüD¨õÃ∏Û®^$∂ïêçäCZ)!7\n–∞Õ∂Túﬁ˙Cüsl?@\r∂k:ö6Z5˜‹ç\0ô_≥Ã\ZÏ\'9+–môîq@Y±\r\n∫eSl\0¬˙π∏…LÅ≈ûiË‡uÕ»h≠ÂÏ^<œˇ`“1™F⁄¥yÒn¯¿ÚTZkMgƒ˙Q∫ÜXÁC»ÂÜÂÎ”¥¨cº≥4πòêÁl:ªò\\gìÈ¸EÂÄ¶ƒß6<, ÿ-3Kêîü‘8\Z¸äeåØÀ…W(z}7˘~®∆:‰dJPwoê+M˙§ﬂ*@.ÎuÖ\Z¿∂¶nGâe	rUËŸ2T™\"€R=x\"è®.°Æà“õÇí¥ú<Â*©uË¢ËÒ	˙`∞K≠mﬁ€\rŸño@ïcD=R´[∆à.äAl˘ò.-hlT†∂±°4ÁBˇÓ\r∫âª∑ﬂ2À2`œ*EkˆÅ&1ƒÁ·ÆÑl@\n	 «dÜXq>°†{>.9»ÇÂ(8^.∏\"â£\\§lˆ›î¢ÓbÃnÜÔ_DpAlÈ¯¢{«}`ÓUvr0¨ÿäE.,–Ú/ÃAE≤]%—f*c4Ûwâä>GZahxnPáLë<’PÈq˜	$Å|†êW¡ÉÚõﬂ≥M∫*‰\rπ†4õI◊”—V‰\0ö§ÎHb‚&¥Û£ºùx@E”¢Çp≥.S4ÂÇV§N$^Ø.`Ö^®âÔj#ûh])^≥¨:wQ’]Â`≤a8«ÚÙ(Ïí:wd¡ä{ô¿ø¬=ràEÉPó§T§OjZØ˘B%©D°⁄}Ë›Ô\rﬂ5|´£ª˝(Ó”,›$y%UMƒJ0ß§¨æÛò ŒZâ°)\"∞$ª£‚^hÜ\"ùF:ù6ñá∏&[aÊò€ˇç¢fxs9\rGT˝2óDD6/JË@•bŸΩÂ^‹Ï\\#á!i¨ú§GÈ Gp52:>TÈr+π¡∑≠dètàß¨}î®°®–xı“6ÀA	ÿø∑úµΩ∞é>KÄ;:Kã(í˜i ÀQ∂\"—ı[aÁ;∆7∞tK yW”ı€ÕbrµWhØ¶≥·b˙“Bã|r~b«=ø‹P÷>ú˘ÇˇËIl\'î‰sçÓEƒä¨…\n¥{+≠që@îKﬂÙ:∆¢# [ÁÅÆ\ZKUÑß™«\0k˝‹.ò˜\ni&cÂ&ë–\"•X¢Ó‚¥Zî»ê\\≤dôVôRWa>”QK∑*ù◊‘>Ùj`‡öÑM≤>J5ÂR√5\'ö∏˘ú´»ó˝b›æ∏{Áh5º@Û\'˘*Ÿ!ê¶£≈F4^/&£…\rÍ’K .j“abÁ^}%±àë≈da‹ëQ°C*Kf†ÛwAÓÂ»ªæ†ÊO{7…˚‹¿”πÓà-T”c≤÷\0m‚G°çDV	pË¶ıŸRVS‘8‰‚Dè≤7üÂ1`Qñ™më	H\'µvÈŸ1É◊%ÓÚ]T™f«4Bß BTìH√√)[ôƒ€(ï)5”sŸ«ÏQí¶˚B¶£˚“ `´‚@ˇ?ï¶˛πw=√:⁄„nFã4≤ïÊè≈˘¿w8nÍ|÷Q⁄dc\r‡SÚú}ê\\-Óı‰Eÿ˜A∂,˜ƒvÛN…6™§|ä—aî*˚≠˘’GAYñ∞¥0≈Õ¡©m$°í±°iCÔXCM§,∑£Á’Ò3êH›∑\'X‘DSÉ]•Ú‰´bt`ä{˜≈˜ã•ÔŸx∂9/ÿV˚ÛπùôîÁTê3‡◊{5\0˚Âv=¸∂:,L\'jÇña¢D≠éÈ3+Œ´U∫IK¢çhDÊÚ4_˛ä¯eCfßHá4`.kÏ…,®A£Y≠û4◊•NˆVO:ñ*”%ï|5J*?ı*c∫Ø€Z«Í‡µHp¿r+ x∑ü:H›EŸ·Ñõg)íWº˜∆IŸT;iq:˙%UÓ”RÙ\ZítBL\'—ı°cü°mXfW*©^n‡ﬂıÔ˜»gÖ>lÇK®¶∆ÙjÖ¥ÂOtR[»t>´˘wN@ä˜ÇöÕ/ê˚™ ûL=hu˜Vuér≥EÉ´FyHû•ö2ÇeD]ÙŸy¬˜\r\'ıd◊Èxè‡‚∑ë‰Y4Âû°Bﬁ.¶W”≈lÚ„ã¶∏À∫7€K∫…ﬁ±8’iÜ °éD°ˇäûEUb!öh&Àm˘µâ%Ω>fiÇ%O„éÚCqØ\'lÇŒ·ÑeÏÖµ¶\'rÉˆíxüêª„Jπ¨X4K”É5îôtôìˇé_†Z€¡\r~EÅCˇSé„öÚÖ˘ÇS}í¶£€—Ï—€∑\Z¶û·j}:v˙i~≈˛2ª˙f4˙∆‰Ù\nÅâ∆Û_Ï¢à∂+=˚›{è¢Å⁄´ŒWzÂ∫˘DYÑŸ¥ã”Z˙ˇ)q«\nendstream\nendobj\n18 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 19 0 R\n>>\nendobj\n19 0 obj\n<< /Filter /FlateDecode\n/Length 15116 >>\nstream\nxú•}Àñ[«ïÂú_qár/\Zé˜√±R¥úU%ìîªΩJ5@\"A\n^»\rdfïÙ#ı)˛Ü\ZÙ®æ@C4ËÂYè˙Ï}N‹D>ò≤‹ÂZJ\"7‚ƒyø‚‚ô[xW&˘ØO¯oË”˛˝≥z;•∞»¡M5¶Eàmz{.ﬂ∆ÿß∑ˇ>˝Í∑~jã4Ω}7Mˇ˙…Ÿ˙r˝n≥⁄,˜õ›Ùaø~∑ﬁØ/Ø÷”z⁄Ï˜Îõ›jy∂]Oﬂ.WÀÈ√n?≠∑”aπ=ﬂMõÀ√n{}µõŒehµˇÎ˘Êj˜|˙nZNÚ¸~˝~πó˛Àã◊_ºòVªõ•Ãõ∂≤∆ﬂ∂õÔó2O>ÆìÏ∂ªYÆ6ªÀıaÒãõﬁ˛≥@Íú§/ﬂ%ÑE®Qèb}xîóó”jyÿqÂÕÂf}∏⁄D≤ÁÊÚ|}q)€Æ6ªúÎi˘aªY-˜?®rÊÕ≈z?mØ	Òv˙∞|Øg∫wÃÔpÙ˝˙by	¸<ó-¶Ìn˙ˆ˙l#{éU«πêÉø¸¸…≥x°Ü´8À›#º8y˝Ú””∑/>˝“p!è…%\ZqÂ‰©ﬁ%qÈiëª7ßxâGã~˙_\'ßBÖØ^ü~ÒÚıã≈ÙÂ?}~˙Ÿãì”/_Ω|3}˙R`ùÏ{˜«x,‘ºhŒÇ„cM/Ñ\0?àV‚˜√ıÂ’ır˚¸Óﬁ@‚Ólªyøúñøûæ˘d˘Õ/¶Î√íLw≥˛ˆ«’ıv˜ZKã2\0	“C@VªÀwª˝ÖpÄ0ﬂtπº∫ﬁ/∑kÚ£ˆJda/DÆ8ªñˇ-œÖÖ‰)°ıA¿€ﬂà®ÏpõøπÿŸw”üØ◊`≥\r˛\n¥Ôñg{·0ôÒ9«ôúcu-#{,Û‰	™[î‹ïµ?¬‰õã◊◊Ó\\ÄÿØWﬂ‚_\0¸Rd¯0ÌÑEﬂâLùc¯fΩﬂàlõt·å◊€+ô W;Ô√á›Â˘Úl?xWÔÂN@ddª3™˝xÄTMKëÖΩâ“ì\'…m!å°\'iÈZ¨´˝ÊäzÅj;üÀŒÀõ\rhNe√)ª°Hpdë1J8Ë!‚&§¯QNÙÌgõÌ\ZæøA÷r˙ï0ÿüÂ”^¥¬≈ŸÜOùÔ.ÑÄ€çuy¯Qêp!‘ﬁ>yéT5¥á¢∫ﬂùÌû+öı≈Ÿr/ºΩ;⁄˘[à¯^æ[ØD≠a\Z ÚõO÷r‚Î˝≈Êj≥|#ê™∫˘\0≠\"(?NÔ~<lVJñ±÷ﬂØ-¢_8î,©‰èjã7/?˚˙’ß¢-N_ù|˝≈Wüü~q˙Ú’€/üOx˘Íƒ>L/^Ω==9˝\n¢˚«ÈıÀ7\'ßoNˇ˚’œP!±÷Ö˚Ù8XwTàöíªs—ØÁ∆7‡z¡àöêı√Ú|y°∆Îií˙æp©ËfÆóáõ}ÿ.øøcÿ†˝ˇcÛ~CUD\r∂πºXüoñWèŸäÁ¬b.Özá¥8˘\n2\'‹ªƒ˜¬!\"¢wµﬂ–xÁÎ?≠¡´¶1ŒBc∏∫pÕŸa¸#áŸMPΩÇòÉ∞ÂÊ|y.r\"ê÷´Î´Õçœ7ü\\Ïˆ≤ÛPU\"˙©ÿµKhîÀÎıÕ\ZåΩº\\≠∑‘páı˚kïƒ’ÓlΩá\"ùñbWóCÉqŒóœß˜˚%üïı.¬ÊÀßNì{°˜ﬂ„√”¿Öÿ÷≥L	x†úÜ:Q·ZN¶ôoÁØó&≤ê)·!ûˇg≠ñbx¥Ì<†ÉË†ønc˚ÌÚªßè—‚¬ß>8Ï5˛aøìm†òódX%uOßª’5¯X?ø[nKp‘7üºì≠7óÚ•ÁëíŸ	já;•Ê”‹©È»#\"+k˜lÓì«®BÑÍæsq∑b]~∏É—·Ó}\'äÎ R≤øÇFÊ÷Wõ´ÎÕ˛áK˝√(Å,2«¸®K’ò4π√PÀY∑Î˜õ√VÒ°æõê‰Ô÷y9g—)U©ëáÁ¯àŒ{˚Úı	=$QnØ_~ˆBú£œEﬂ˝Óü|˝˘œråb\\îZ>≤Ò#ZÕ<«I}9ÙÍjwµk`Nº∫ﬁã™ôæX^~øº‹laD˛t\rˇ.ä< Nâ∞≈ì4MqëùW	´⁄Ó√Ds/ÏπY_!(x~‰µâ+⁄ˆ«%ÖÔ÷ÕQ˜XÏ©<y∆u˜w\"~§€‚û´wæ^me)aé’Êl≥\'˚àKıΩZ∂ƒT‰X2Âayµ9º[ÆVdÚµÚö‡Â|c¨vn«Åxﬁ\n\'	ãB¸NOOˇ~fÚ‚Ù74T¯(3ù|˝‚ı[·•O_º˝ÚÕÙ’À◊oæ|ı‚Ûóo~y·£ò?≤Á>˙N©òñÙ›A¥ ñ~‡_C°ŸÂÿ*:e¿ˇ{)dT€˘TŸ>M-õoW⁄#÷zy~!éë¯E*≥à\Z¿Ÿö*wÏ◊&‘¬8k—ÜàÓ∫ËÙÑ0[¬4ÑâbæcﬁS\nB–1W{\r3ÖØ÷+€˘©É§Ó≠=‚‹=@%≈[≥CÔ‹≥È\\ÓÁ»ıßŸ\'’≤’ùò”GŸÁ˜_üæ\"˚|˘Ö∏Xüü\n˝qzıÂ€”ﬂûûXÏˆs8)ÉPı#€ﬂÂ§c›˝ñ€Â•∫…≥Î|PŸ˝∏Jò¯äõpuj\0?p|V‰≥ıìëB*iúi…¯ò±º+´ãÈ‰°gc4ÄÿãAπ>@¡JÚ`øô¥ÌÂ†àrê›xø|NuqÔ0F≥∫ò‰ar¢˚áù(⁄t/L-lC1‹70⁄kƒªü¡D±»ﬂl±U˛∏A{ÛÚÅáNæ|ıFL⁄⁄ˇ8˝ˆTÑ˛Á∞OËÿáèl|á}Ó*±GÇOò{˙Áp‘U/Ω€àø≥g⁄D¸…s°•∞%Ñ∑B6F˛π‹ˇp%“ı¸\'º˘“\"èê9ÑG`:yÒñFéı√R¸›´ë2√≈`^¯ÎG˘«{ulÔ˘Ïﬂ—WCEÿ’Û•™¢Rb4\0˝)JK\'à3˙7q~ﬂ…TâÆñ∞†ÁOÍ’‰Âo).ˇà^]-?¿”>_\ZOD«Æ/ncË≈ÙYL˝πiwÖán≠ò√Î’ïÊ»ÆEz·ã¡’dJK ^#íÇú¡°ê´ø	ä\rÒ:◊Há<y\'zÊ±h˘=áıYE ﬂÕÙ±•E!bˆODÆˇıï∞∫†‚Ûóüùæ˘\\îÂøûˇÁØ_üæ˘ÙÙ‰‰ÁE®]˙G∂ø√˙_©Â≈\'¢.àΩ\ZFè}dä2÷]o˘ ¶P»@•ıd‰kXÙ∆z˜à\'∑]\'kæ[üØ˜4b≥Î|6ÏÂA=ÅØ¡˚áÈ	r≈ùì˝\']Ra1\0\'åv2Û¡âöj$<Ê·ìÕÕf;˝V7¢ˇ?}æ˛nx⁄«‚}D∞)>¡~ukœeµâ]ØEËv˚ˇÆ¿üÆ˜õÉXõ’ëyæ⁄oŒÆ’x√-NM˜{œ\';!åËƒ∏»†!*ø[â¿_ãzÇÙ?yå‘%˛Nö|π=Û]Cœ-èRoÎ=¿É`Óóﬂ+Ë\"≥°ôL:>øª¡◊Ñ¸í?]√´•ni¿áﬁ4›Í\ZŸáürËb¨ßÒÍÃØ†oÆ˜‚ÒﬂíÛò∑¸Ág`ƒlìÒ_å¯–DhúDF‚¿Ê<≠.ûâ+{<ˇ˝ÂÒPq˙W¶∫3E6˝ÙÔìõ‰D”üdÁGß¸Í≥7qz¿ﬂÑøû•<tL+b-^ˆ`ö?^:∑∆Â¢Ås1›’,˛Jì0Ø,zÒb˚Qc	tèã®ØÒwıl˛∆fŒOﬁ[||^=b’äÛàÓ*ÂvØ^ƒ}ã«[ƒÖã}ÜA,…1à„„¿È3€ÿ”c[›˛»l∑i„©{´⁄«’≥{ªòÏÈÛº˙8”|F;Û}‹BˇÊŸÔˇ^b∆cZ÷Äñc®zqB8ëà“ îíßRJ=Ïq˛+à∂o∆Ã˘…{ãèœ†ec§=F|ñÛÑ€º´rÓz¥GÆã(™dl⁄√}tÑÅØ±ü€åÂ«_!Á\0@\'éÁÓ≠⁄LŒ;˚Œ0 \rÍ€ÂÁsÕ€Ñ{›Á∆êûIXË=Á°Ï:°[MãVÖûN†î3§ÿËbçøBœÒçÕúüº∑¯¯,ËNMÉ)Ò]N.Á\Z+¯‚Iö€=|»‚R§\nÔ“(Áœ∑Úi#cØ±¬ÿkÏ1˛ „õ9?yoÌÒYËzo˜∫≠¡ª«|¬qb√¿}å¸Cîıã|L€ˆê∂cªı,Åc^tâa%f\\∏é∞Hña˛+\'ﬂåô„…{ãèœB[‡ƒ›ŒÇìÓoWEåcmG{¯òXM{ây ˘Û-mmdÏ5V{ç=∆_Åj|3fé\'Ô≠=>À…ÔÔ>†≥¸∑{åŒ\'∏áëü¶Ì#ñ˜ÿ¢\"!u®}—ƒ*\\<´Q˛·8êÑ©∂œÑÀ¢ÿ‘ókÔ2 ƒwÃ@@ñX\nq+0£ãŒëÅJV∆@	èxÜAfv±![Ë‘V\n3!Mòö	 5«ENÿV˛!8‚Ò˜òuç‹“\"\\œ•Ã*Ö»Ä®Bâƒ›ì≈˘Hì»%p FßàB¿\Z‡Ñq÷CFÂ´Ë@‡\Z}Q\0ìÌrä¡¬@\Zenõ+f»)ìxòAçª\0ßÚè 3k≈#U»ötÔÖ”∑œöhqÃå zÅ9]˛·ÌÅ	EÑgBÛà¢≤Rà(òEYQ\rüä‚Ã%«ÿv>“∫†(TB˙¬7U˛>{Cë/tkM2 Ä5â∑Ç®ó±hBwlõ$\0ŒZ^∏*ã∆Ã›x\Z·5\'s∏≤…id1E2ê¯kT|/Ü∏y&ÒõÀQŸª∏©Å€?÷ñ‰˚.k74`â.‚\n˙.†múÇr\0è£ı$pBnÖ˙‰SŸ£5(\"ıhI0ÍXñ©°®¯± “7¿xÖCÂ!ceíè^ƒqj%‡{aâ‡^à\ZQ…®bÉC˛Æ¶q ¢òc ˚ÃdöÃ(ÙÒë√	Ω(î‡MP$Ò¡E´ìD¬Fép dk·ÛI≤FJ’‘1–h¸eÜLÕCáq\0ÓÄ( ¡ö h™5C	VìæEÍëJÚÇƒÇñòj∂TË)¿5ÕûØä:~Ïlê∏jKPzza¥{¸p#,\"Bë@QAûk/üù°?ôî‘F˙ÊC…ïkÑûë\Z$ƒ%:∞¢óBK‰)`RæéÅ0ÑÇF¶ÈÒΩ´¯^p–·8!_.¯˘mÕs˝DûÑ ıù˚£Ÿ|-ÁKYèç%/ûu\0-f\\¯≥ìûò!*∆weûO{05¿ˆ2Cd¿[¯Rÿœg≈DNÙ∫<‚I∆≠¯¢Î¿Ì25Un„ò)ˆPì.´<dl#™6PL;‹UÙG¶‚ÒDoñ\n»º∞iH DR®@<8ëFQ›*#A`uÎãú\'GŒ¸~Qs9TéxÍ@\':nÃø†D…3\n%Ø,™G*≤)™Ú7sD¥°0	–	±`Á!gôãpwXV9~¶,x!nÉÂlÇ_làπozT˘ :\ZÏ,&¢xË#ú´¿ä@NO!sBSîäïNlVYN·Ù§∞◊b\0/r∑Ñ≥∆$Fœ•q-˚ã:ÃûO%Å(&ŒÒi|W¿%†ÌüèëäÕãv/ﬁ€úÜ@Å%Ab5t*(Ó©{Ö ßŒåÕbu…H	„Eh!tΩ¿!Åæ¨úm1=2Ç‘~1¡€Tà\\ıƒP•BıI‚√¶¯;ÅXNd\nA,∫¯òÚúpJág+º$1û£Añ9÷ág:dYS∞aŒ≠˛Ø_˘LåVØò#Üø\r\\7òì˚0pBΩé)<æ) V\"éï1‡…^–SM∑Üf√\"Ç:eV8…\"¢´Kàùì3u®˝ƒE‘Ån¿21Q2Â±¡®vD∏ﬁ¢ÕS%dJÑCõÍCBÈ<NUÒ	i{èº2ME\n±†0^P‘â≤ËQÁãÂ∞p-0Bá>åã®À#SGsV∆å(àx¢á*¶s•á∆Ñ#“ë¢Ñ∂¢ﬁ$x,¬T¡B´m%ùxŸ°g3gïÎ#˘äÔ3}9m¶N´—¨x∂Á!7Ç@1îpP‰4®ú «$.æ˜‰H®ƒ\n¯*\rsãT]ÄOf\nwæÉäΩ®Y\'∫iﬂPhóäx+Ú@∞Ã∞[`g¯\"Ô–∆]ûá+Êﬂ£T+&=S◊S[¿}i\Z<õ&˚$.\\Â˜†|Åâ@A\0	[â>(µ´[#zSàﬁ[3Ñ˙å˛4±Eçß`*8øÁÅ0|/6âN$f$¡em#I&[ãSˇì;\ZömYπCbã–?S»NÙ_3O\0_ó;‘§Q0÷A≤ È˜E0ƒ#WYÜÜ\\8DTxnûﬂ\rd·Z‘—œÚ¯XC‰˛éRÉ1x•¿ÄêÆr∆\r·Ôrdt°¬)$A™*Tõîe∏>≤ @â8òÇrò˘ûËÃdëi1\"è¯û\Z*É©†pÒ=T\\Æ@Ñ¯ Ã?ä∆QyÃ	K\n!Ìy€Ì°\Z<^Wha∏uß\Zòf2L˜§3$b}E»\n\\p@Ù	’Ä[“k. ∏tçÉ®cò%±2=íŒr\nhud’iR0 »ùâ@	ÑTòåÕ:qÀÑöå†Åã¬F§›©*C≤TúË–Œ]\"ÿπ:9+ç0‰ñàÄ„BÇ,\'£nÎï„Â1,äˆ\"PøÄ5Ÿ•B94õ¿B¢éõ¬!&T‘+g€∂¶lﬁxâ\":$[ÿêzÒ´∏(†zÔ<\\ÜÚæQâDÏVB≥<c7$ÂºNç*±®¬G°y/Dgp…¡]ÙÃ{!{Y·ÄÍ\0zy–\\31Ç<ß%?‡#ãmmåÎÇ^GB‚,€@KH)õıE»ÁŸÇ!<8ÅØ^°p9C4RB»ibÊ\ZÙv<5\r\rT\07EJ≤\Z9°†àHÜ‡@˘º›Œ+ﬂ4ûBY÷”Á¬˜®w`Äñ‡˚§\ZmÀG≤H>ìCyT$n$ä¢£Éà&$\Z`Ë#-uxÊ\00@«_Q¸¢W!ıºÍ¿¯Œ™„ÒíHl‚®ËÌ\"ê®@~!´…ã‡£JrñÇ‡8JÃã≤r≠ƒCÊÖµÖ{ú†ˇ#òWL[ıî™ò†t–ˆL¬˜eH¥¶w1ıË£vç¬…B(Jô)ŸÁfIå¸¢∏@puAËäÔ£ÚéÿvœÁEAë∞PFE!\n≥âÁ◊à⁄9äVƒ¯€˙= óÇ∂íüt≤¡Æ¢qÓùˇ∆P•#R¿ú,Ÿ∏ñ†§a…\0ß>ê∫nÈU85F´IÇ’ŒÔ≈∆¢ÍÀ\'(≈r›M¬6û ÅÑ»£äd!YáK“År,P&˙∑R`Ú\"S<H£ã√`D,,í.í	W\"f∏‰&5”á/RÙ\08gêDñ<2Z∞~†fíPR‹ØÈﬁ˘âQª•”MÉ[+(MM∑«Ò‰¬ZpëD˜@¶å]]kS¥ _§Såä®˘æS˜58j¿A{;jëÏä÷”ª#∑˜∆Á°+»ö:÷NÜ(◊¡≤°„?<Äñáëæmï…\Z™!–◊A!@√Ê ˆròH+Écyÿz·6∆ãnúÉ`ô!b¸Ó}oôjM*\0ù≤ù‡\nÉ	7 ≠ò‹l˛=Æ‰Ù@/\n.à÷ÑÛ‡—u˝3ÈBÇ¸±7˙Cr>¯˛z“imqΩ@)Q1ΩârµsÅé8ı≈3¡ú∏ò\0â	^‚¶}†`í∞m)‰ÇJÌò‡ÉAıSI•†1áA≠|KéFbÖö>≈@7Œ:˝˚$“Ëg‰¿âT:ÉÑÃ™âÆ*.<Î(ÍÚ\'ÒW:‚E¡3—dòª.+…ôêjdÃ“Öâ∑®QWFVJ0ô’UD`@ù#7ú„7¨O\"ZÇG{ÑMòô∫b¢GEA‚\rŒõx¢m∏G‚ñ$RéH∆übKÒÀ!Sò!r\n?–C/ku!b\rƒu9pF◊BïP¿â£–‰êıE\\%Å5CD“¿‡™àçY◊ÃçN\"AË;¡¢hÊä”˙dπ—ƒò∏áùÒjµeœÏìX~\n◊æ5[\'DçÃD3z/>B©{Œg	ï±à\\óû\'GRB¥0ì9Lﬂ…\Z¬IPìNmB°—Æ+4ﬂ‡§∆\"û∞ci\\Ç‰¿˜û¥B>3¿Õy`\0>E¸ æ$íóΩ\Z7ÚB8L¿ôUJ*ıl*ûé;®ãzbºù»ô=&Æ!&\'eÉ™3Œû}£ŒDÚY81Ç{œÖ\nÖÒΩ”º=¿‰äJá6!ÄhùÙl¥\"∑å#–>ÄK-¿…q5\n›·F]\'¿O·Sr¬#|ï Ey˘) %2SãlR¥<¸QpŒSP±\0D£·96Öê4fE4∑òÑ\0∞¸»n Çå®x÷`4ØùjÄÑ¶—e;ÏÉß¸Dé‡»ˆ8À™eƒ“»ep}ÂàgXçÃR£wñz\'[™1î›ÃçŒtBxE<¿rpÜÛ ;WTO5√ô`JSáI#¶¢zOâd‰—F™5âµ!f·¿ˆ`ßGŸÿì‚,¯JgƒóπFúJ<}s=k–ºöÿÕŒ8ñÕ«ëàY+õF®9jy(1è]Â^®L¢®É,^Vµ.ßè51”Á|≥ΩêéÒà˘K·©äQUÌÜ«<“&±*¶ëpOLø∆y⁄»|sUâ°ﬁÈ¥`%ëv¡œQ,KÎ®–Dû÷œaú÷1|Âsôe!d\\ZPZ,Ê≠)\r˘7±x±ï˜%Ç’LcW.@Â∆QÀ\"3Q™÷ø@E\r\\3Ωô√ñ4]íîfv\'û^k»jö›{-õi‚@Œ\"ÿÁ:–˘»!àÆÔ¥≤Ÿk¢5áuD·@ÂæNˇÓ´0\nF˙qp\rÉûkKÃÕAô∫π&BÌöiãê”m¨¬ÿkd	\rKù-7,ÊQ<9	ª•4ø]fjmM¬!¥»®E;^h≥LµHNÇf“Ti_Ú#éº\'t{M˙îÿíÑ9…¢TÊ…ã=	3mS§Ù]3±E5∂Ë≥™ßë≤ùòEßhY˜ i‰≥VÜ35ué®∫SÛWÀyG⁄6kf¯{¿)JÇñ(˜ÃΩ‰¬§ “õ±©•§ËëEò“úm™6t8äJ\nﬁv™‰¬BÍ ¥=“óH%pN’ú8m‡(ñ`°s\'7zå»wkVö(ÊëOº†=ù:\'WÎ≈IöG{\"Íﬂ¢e,K…ìuê(J?-LB[∫Æs*•3!·JéE%B\"ÃŒÍÅyB≠z„Ëÿó‘˜â`_¢øÕ§wx µ¨Ç:wã¶À`c‡ãÄ¶¨1ìı$}Œ¿#9Sb5ıT‰sÌHÎ¡4$¥ºbtl¶Æ÷˙õ∏¢Œ@8\'ë) µÏ∂÷Æpme$Ø3sÑ™ÒâÁ¨û8t^≤ƒz£TdÑ<¥≈,Â@∫ﬁçJzÎƒaV#Â†ÔÈW‰J_∂’vÃÅì˚ıP…@.õñÖˆQ¯FFêQ\'ˆƒFL	Õ™uWV_≤‚.ZÖ•3rNH˜©¨•@wsä÷\\>OÍ°“2 HdÄRZ|ı‚°ø\'Í:®iÅ*‡&?“ˆ’!/îYÅÙåY=9π±zç\nñc∞ŒIZ;ø–ÅW1#≤5ÇVüe1ÒjbÂgú˙ÜtCÆ‘á7zü_S±ÿ%V¯ÇT™÷)ßÈî;†#@zÃ%1“£Gd;i¿âBãîALºè„Z}CNò	Kß˝F\nr¥Xaæp8\n˚∞l=ªñkÅq+$–°®\rgìd£#rpﬁ	U©—ÁA¡…’<°í¯‰¢j’FèñÑàﬂ§áòπÍôï´&§A£⁄j [‰+{ÓÖ∫2]‡4K§Ü¬&HF”4a»Ã “ÆRV\"$@ËQbbN$Sƒ≥n¥Ô⁄ s–≈≈∏\Z67ãÆÏ™˘!˜êft—sÇW%ò‡-ªB_Ç’n‡\'F´“qÒú\0°ßOà‚¥√H®Ïc¿à⁄íÕùçdìoÌbÒÊIÇZ∏ˆ(ﬂT$≈“®H∂¿lV∞≥‰û5r\\eÑá°¯hz≤™ŸXƒ`¬Ì9y˙kö:∆eLh%µiH{£ #VÃö	é¥Ñﬂh¬Y§”åtvœ`$3z»¨˚iR⁄Q◊„)ÔuƒÎ )õgçLv¬S»}¶ndPCÙà\ZP‰ˆõhò,ó_Ÿ=ÑéJØUúË˘ú›Q⁄B‘f›À0ªÜNZXÅ\nª1oå<5å®2≤rU-2√A¸ÊåV®€ã˙∞zçö_Æl)‚©èd≈Ä£à˛Ù§Ü|gıe¡∏.í„•!€«Q#àƒäm◊œ.3O˜k4∆µ|(˙*„*õ¯Z¸å3Î¨øpªéq(¢5k\"7ô=Cu?“D.∞f\rõÕ 6¿7-;]Ö•J ∑Hñwì´ƒ&‡»âınV•F¬gú∫⁄Ë\r»jIX:|ﬁ©Õò\ZßŒ	LzC∏√œ5Ü‡#eV‰OÁÄ√¨‰á‰πÓ_äùzÓ?3öb(zÎb¬]®àëD©îà≠Eô\r[äEttA3©	,¢¢≤≠∞ˆı4¥∫é^≤ƒàëúÆ°˙ÁãGå V‚g>—	€JÉg¥∫v,´ë@Xï2N?:+†fDâë9BDÜ–\'»nì{#Ùl¿y—oîà#—p*ÖùâwÙjÅÛíßw∆œA˘Ω≥à“7£N<£hõ»ªÙïëI≈pÙ\02v>£∞D√<!é†ç	Ùg?<IÂôJ0£Ö∏Ëûl2\r;“öB‚;sÙﬁzÀ;=!$·ÒäÒ√D~ìe··]@Jê©F\Zy\nJ\rkÂî¶÷±⁄\0|Ÿ§kx-0ùô({¢&|Ê˝T≤»Òëô≠H˘ÖıA≤uåÊJßk†#¿Ò|¢øeFfõ≠¡B!U=íÊÇÇ^´WØA+%6xp%Öª¯–2º˝ 9µ0ˇç(´GŒ\nZáB©!+¸EãH–n	>,ı¨DaM\\π÷3fåLm7µC¥_ËîG≠óÙaë|œN-Å/∫Ne⁄ò6ÜæFuNfßVvåú0Ë7FzâU˘î—*Jå∞ószäHo+˜¶#»f’ëyåÅÉZ¥kÊgÖı«⁄Åù°®§Äo)%åØ\"ªæ:%ÿ◊lÖÖŒòö∞“óähEÉ˝åïR´∂	B˛P-ä5}y-ìÏ€∞y»{ëÍMc2å8—kºxk/ü+Â©~tù`\r‰4#+û˙Wµ8FXÆ8–°Ö\'\Zµ\\gVM◊Aµ:öƒ\"3ÛôRˇ˛Ü%èçK g§–ª¯ﬂÌÜÁoU◊àº	r¨A\0_CK®C˛&QK\n¥hA…ö˘◊¶ƒ	—0π81∆B”—\rKRåUF˘ò¬â≤Çúû≈\ZÖyå¨⁄eïVlFñÿ≠*û´oÃ◊ nÛå¶PÅ@Óé÷—d<»@fK`Gær¡-\núÆŸü-\r∫rç¶ôâ©Èu≈02‹¥ Ãã¯È>Üà5x)êY∂Ò@fë[èå)≈Ç≥c1!Ø\nN∆:Ùf—”∫ l•D øﬁË\'÷(m≤πëuˆBtæÀU≠ƒB∑\0ì!´?é,æV¶–ŸÕeˆ‘@\rv∑(ûºfû§&±›I„ﬂ‰I/‰“·˜£5KVO»q§DÍÕQı·u©ƒJ\n÷d‰Bõç¢çòs\Z	x·húaì¯Ü^F∞sHôk$÷D±F≈˝,5wä™\nv∞Pö·Ùû}±àŒ4òX≥IåG©i,ˇœ®Ÿï∆ TB·¨2BêÂACDbìœçá|GãÏ⁄Eﬁ\n}bV¥ä⁄ò∞\Z⁄ôÎB‹J˘öÖtƒÅ]ÔÌ$Ìƒâ\n˝3å†hŒ\0ZhX¥\"4-ÿ_∞nÇå¢VÌöMÙÁ5Üvl‰CùL#‰¶T£∑⁄1•	¢ÉÍ4ÉÇ™qÃ	4z‚ò!≤√54H†Ω∞o°ßáëdwŒ¿«¨– ˆ•œD˛*®ê‚Zª\\P∑®ºµ4rCÅÒagá™:Ã$í§ê%Âß†í	oº*«5‹qA„z–˛\\…µ†OTÕ‘X|rú°ŸÌ>™S†q◊éTf4ë©Ë∞hZ˛H ;hÖ!ëå€ã“º™ñ´ZÉKà†EøÊ†ıJıUXã@Ñ}èö7Ãú√¬iùÆ˚b˜ö≠ºÙ®`}dÌn8#r$Sœ·\\à¶Aìdö≤Êﬁòı\0∑ﬂÖìV¢†◊ëÁ√3Ã˝ÄA∂Ü ﬂèh∏}Ñb>∏ü˜±xæ](îTÕ1±<€π*ˆçZ≥Æàâ®Õ˝7¨”¿˜MÊ/3O¬[òé9≥≠S‡ˆk≠	µYO™ï®#âyÃ©‰8ØyMÎ–$®j5é ÀÇWå¿í≥F¨¸åÃx≤;Ó‰wI3°òk\\xS¥ì<[Ü@áƒN{»;⁄\n)-Nﬂ‹Ç8öîgT¬LtR—Ó1Ê4ÉJ†ßm¢ÁÂ§Q5*†QÈﬂï`Ñ~F˚∫Ü√›\'¯∆Qodˆl7‚(T≠‰tÍE“ÇñΩ≥	¥®§¥:ÔÀ¡ßaSO7°â–cU‘HA¥1¿.¿*”^)l¢ˇ)AwÉE\rAÈ)·∞rÖÙÙÏ∫áµq»ø«¿àıÊô⁄üJ»2≠):©´˝%Ÿk<Ç”afÊÕìcRêÒ>XlÙÔ„CeØ3è(´Ï!œ+Î¬ˇ+A´]é:˛û∂ˇ!“C\Z}⁄°éh6(h}V\"v‡T≠£÷ﬂ\n+Ñ∞[°jÂ5±…61?≈u`!Â4hR…ZÎBT[\n€J\nô·Ü|∏q\'Çqs“{ëµj\rUº‹EΩS/ë°+8é®“jÖåÒ3^œG≠M¶VÙ25Ûèqwd#g°/Ô\'2ÁK]Ñú⁄îöc?üFµ¿icÖÍÜk¿ì¬K5™/l	C;Ofn>ìFë◊¿QçÖˇ[yˇº∞yYf¿ﬂ≠é#∏}¡Lr\'µ±æy√€º≠)-ª”xuW¯√®yÈ\Z\rPí˝]éπL|÷‹\r=‚¢æ|ÒÍó„„ÊØımè>±˘ÇwjíFè∑a‡QEfyiØ3aÑñ8m™d’ƒ±·Ã3Wà~ Db¬˝!úéÖ°\Z∫\Z◊Ä˜¿m{vÒ·-¬kÓB6@Í–Ò2`Ô\0ñ°Æo	‘z£ÅJ∏πóıaRg∑Ω◊ª»ƒÎe¡›9<U´›ÑË∞ìŒñÆÃ‘!ÊDﬁ∏¬ú¿ƒ<öJùÆIº·‹ˇO6F˙´vlDM6b9YtmD±Ï\"8”ÒNä5ß°öÇÓ%¡N‘|zIÄ◊S\0ŸU\ZÆLmÑãâ9XÕPm:2–»ÆüÆ(\Z#öAéOÛE®õí–»=hè,!F 9∂ª\'“!ÒÆ(ÑöìD7†÷Üê\0ÈÒMÂS⁄^ËËC)OEDU®¡on:¥æÖVEÕ#óÆÎ¿∂Ùπ¿8≈ŸïSt st<Õπ˜Nxﬂ®q$f⁄c…∆®ñ Bû√kï5ioµúÕòµ*≈a##lÌv∆—ø≈H#¶êÒ∂C∏ÄÖƒ8ZÎ-´v\Z¯¨tøÀ-öçÃ~‡Üçe±!&‡Ù!ZE≈Î’`⁄`];Î]XØB¨˚˚dıπ¬Ê›—E^o+ìˇt$+óEFw£vW9“\r˜®N‡D7t≥¬£‚FÌXÙVÇvå ¬k ı∏õ‰ÏÕUñïlZ•èmpΩØs›^9:zΩöxGâ#∏-¿J~∂û¿Aœ—∂Æ$Âõ©\npsvPYG*1∆◊vËîñ◊˜®\\≤üÍ,Â¡n7¨å{#∫rR~]sê[F^‡)ÊøÎ°¬„›D]\'*øÄ¶:}#‡≤î«Ó®îÛ\rÉ[#ÎÛé>…F<©„ôØÚ9BspY$6»QatÀÛòÚù *˚pTsı®≥†Çu7ƒQGúé∞À\\ü“µëçlÏxJÏÓÿjﬁî#Ÿ˙3†E#2e6RÏﬁ¡lÊ ÊF~“ã”´Êä•®&eGÖjú™ùê]˚Æ∂Ãä5ˆU”âƒ\"Ø£µm‘∆∆/hÎ\0\r√¨%Qg‡H5Æáß•Ø˜©ÜÊ&ö“–µ°ı™xßN”ºW•˙ôÔ≤^oÆ˙&†-≥1§<{zÜÆá.„u„óN˙ÚÕiå†ÍàZÜJ*û\nÊ\'¯yeæ˚]∂qp}…j‘cBéêCN∂ó„w»µ¶€ìBr4Àœluk†§cQ5)¯G©√>nGﬂÕÊS\0’Ñ3Gô‘ä®§B´DJs\Zô‚öÌ˝}–\Z–\nË3˛Q\nüŸlè…%tAR˛âùÙF∑ìi vm™≈*u3‡`IürùVñî‘ïùrdÿ©ÃÅNEÁ(¬z@ÆŸiùÜˆØNWVª™ﬁe¶iæ˘‚¢vhE≥ÖQÁÄ≥teDv…Ùüj_‰¯y“°∑¿ë‘æ^≥x®†vÍhË¢Îà€ëËÀ´ï≠¯°≈ΩvåÅnè≈}ê3ıÙ\nù“TÒÃkÖM˝mÎeÍ\n+xcT Ωr:Ö ∞iê4TTvhyíjhg∂»Q∑0õoVÆ±ﬂ¥5{≈»¿Ÿmí·–>ÃÓ2;$∞2oLé˙7nx*–q¡©‡“Xáö§9ì\\ˆL¬¢÷qÕ\0v8µ∫}Üê≤\\ÇŸ+h=⁄aæzBG\"µ_`mIG\n;ÿ¥¢?˚7–-»Jû´È®b‹ú÷‰√ÏÕˆﬁ;}ÕA∂ö˛ç›ÀﬁÚﬁ)˝HóMK:Ø˜9Z_ÌœÄˆ√û—¯G}¿•r¡wj`˙Få3=OËô˜“ëF◊∂¿z\rp{«©ΩËe»¯òt3õv◊Z—Ç¡ö]€©ÁTá≈î«6ˆÕ¥j∂(.íB]t∑§/óáW£tÜı¨›∏åo˙(ä°ÏuDΩ3æC˜Ç5ÒÊ±€à^¢ÈÓºé™v∆Óˆ9{˝Uåû¿ñëb±ÕtŒ\Z•ôa´·a‡\ZëyÑ 9ÅØ„ƒ¢cÊ≤:{≠M_j3Ô¡[¸Z3{Â-«Ü>ÇíÊë¢’˘±ój0ËJÎ˝B\n˝àq∞Ó1≥ûY<å8C±®0”¶°À@œéÆ$ß∂»¸j»Å∑wö.QÔ,\"ÉÈVy#\r/ËËÛ–£∞%ÍYˆ9ÕﬂòîŸk4\rç˚*Qµù⁄Ì\\ÇFfãx)¥™˜i‹ötXD’–Ÿô#’<BËıËUC´.◊3∆ÅÔ™ö‘0¥ëNﬂ#∆·›¨ì◊òR˝Ïmé⁄X\\¥ßÃœöO√^YmZ®fy‚∞®1RO$√”ñUf˙‚ﬁ\r_ıŸ¨V≈<Dª∞À¨÷)fÀ\"ª8˚qÅdœ´Íÿ¸K& <^ÅÓ˜ZÁÏ∫N”◊™∞äi# «¨…∆·qÑ™Ôï3èæ\"y£/ﬂi¥∏Try´\ntÏÍÔ ≤	\Z9jƒù¸É\nÛíåÒCÊvÍ‡€º$Ù^{ı—Fd≠+FªÏÆ#Ù˚‡<EΩ—ÜÜ¶?@À3¯Yo[adËlˆpM≥®˛I|Må„´õ≤Ah	ìúÃ:%ﬁºPØ÷“>Nı0z¿ÃFñO≈q\nPéö$Ãæ,|V]gﬁÍœ]mëb4edÌΩYB»gJÍø{]π(Ø√)~$ØÔ—Q\n¬g¥E√b¿˚+|£I7l†#Ç∑xaMyæ”nzˆ6ÈH¢&bGûéxıﬂ°Ûå«êg\r:b6≠{ã”úI”}€D{ÂUßæµƒYG=‰9Ú–…çIÈHS-éäm#≈^mÊ›ò\rà#[Ï>gàah‹·-∫ó˘à≈ﬁ\rÜ˛ùØ⁄,O¥(>ëO@˘ÏÜﬁbûŸ¨4F@\rdÚÏ≥íßR≥#¥üŸœÁ“8—KÙc˘tkô_¬Ó]çæÉù=2F¡≥±UµbUÛèõf¥Ÿ}§:ùyU#tı,£eipæjt÷]a?’ûCfôQ…#‚Çˇ®rêÊÏÑvÌ\0?≥£Û°+V[#Ù‚ºW–7rÄ:ñCî`Øé\ZZcut>é‹à∆∫¡\"A’ÎÃ0Â=W3ﬁ0…¿ùèd‹R«O™Ò4ﬂØÊÿõc:¢^\0lÎàôÕ™ >∑ÀE‡ä’Êƒ1¢Za‰€8Bxºy{Ï\n∫ó≥ëHﬂ∫dÿônÒy=n…¥BÉË≤¯‹,aP\rœ€8Î`Ÿõ6F2π%ò&\'qŒò·ç0èh˘°-ﬂ<ËL˜òÈÑoz¯)ÙJF\\MFü(ó±˙ªiUFÏçâµä‹û´ÊÔÄπhÒp◊¸\"\nãôÉŸ¥9FEg]∞ë>F∫EÏ!|<>5ÁËöz™∞çŸèßò/¿´y¸––ù˘¿f˙è˝w¥∫sƒÃû◊ô£ÇZå§[˘≤|AIcƒô≠.ÛS√z˚YöXr®∑RiôΩ“g-nXÂÌ\Z•†¡S »7ôÆM4¡ØÃó4,œ<g◊âFãywÊŒq¬‚|çÔa9ÃC¥x1Úﬁ–·›‚O”êxÕö”ß|#—÷â≥g§ÕWÁ\r{¡ﬁØ|k¥ﬁé,iâc/vZ5_≠Éû¥é9M˘ò¸hóv%œ\"Áúî^ÊﬂwÌÀ–¥’Îà≈ü]≥ek•ƒÇÃu}”	≥y6ßÃ# ´à…HAÅbƒüIã`m∞ËçTõcYè®ﬁVõ≠U‘˚±˘ˇEÀ£°iŸçŸÈßªC€X—NëöfèÎêÊ¸åüç »À$≈jôG(x„Q#Ãï?ˆb7âf≠^Ñ≥€[<’a ´m≤HÖw”’Ê\Z„∞Meâ\Z’ßÛ—¥q\Zπ}XóV’æ\"ª’∆M·∑tÒs‰DÒÜè4F¥Z’˜˙b˙πå|\"Àh7Ê˚H,Õ˝ègøÁˇ~ıŸoÖ∏†o:œ~~Î#˙å/¶1Äkƒ∏ÇEZ°#ˆ–ÒH„{E∂Û2Û¿ˇú.˘ÒÑ◊ü=É´mı¿ù¶ìúCüˆ‚ŒñÙrß7èÁc?Œ‡ŸÉèW5ˆπÚ˝ı¯Ià2~˙cπﬂm7óÀÈ¸XœÂ˙˚˘eıx\Zû:ﬁ{ç˚è-<|˚˝Î„ü«òccz≥x±‡/!,˛p¸Î¬∏¯õñ¯3Ddp€\nî€∆®3ÑX_ûØœw¯-ùÂjøÊ?ˇ2Ω9˛â˘Ï›Ø‰ˇÉ√õ¬ ØC¸u\nw_ªZΩ˜⁄}Ù—±~”›œyÌ~¯πØ›œ~ök√)Ç\"/2…À$è:p≤óûG{çÚxGY›:\\À´÷÷@∑“;ß≠0®CnPzÁÇQ◊…ˆ‚–®N∆\r\nÔ:†9 ¨äØ$l˙ΩVZpWñùŸN–È7Ë(`ŒÕnª\r1ﬂ`Øoåõ?:Éo<‡\nÀ9≠‚Û{}°Œ≥˝qeÄáı∫÷)≤&\0ªíàﬂ‚M≠B÷í¢’Öxt<ã™∫~ã\r∆˚kÿëÄœEW∂oıÛ≥U3Ò∂ri∑P·°¢u´¨¥*„Y4a·≥◊Iöñ»cﬂ¢E#TQÚÊ<–≠ÙÖ_ãoU›Â0ê©&;+TEq5≥J’d|RWMê§f˚¬¿Á:–ıìÓ€tã§P5Áˆ€6>gE—ïı€ûÌµ·ƒ≥]ÔÀÉº”ÿ5ÎÖNΩHŒ*\\`ßúMŒ¥WtÁbTƒª0‹-q›ÿ–™Œ≈˙(Ωì—\r˚’®ÅªøFJJNT¯=7ºßJ|i‚ÇVïk´ﬁ∞›¨†iÿÁÛÎtMùx£oÔ„{„∞<E´Ë7ﬁ*‡7¨($ì!≠ôf¢¡3|#+ØP≥\ZjblXh¶X¢røÁ€ãÙ}ÜÛ¡ÿ«‡,œœÉéæ;¢}”\r•i∆e◊⁄:ﬁ¬3òúb;KWlxÎ=·{).›*5°∞_¸«≥T;kGßÂÀ˘y»=ﬁˆ†ox∑z®S§Ûù(ÛQ)úüp’ e>ù#J–y€]gdÂËµO6 b¿©<åÉêQ⁄ºÉ‚æ)¬«¡ë1öø˜*ã„yØåËÁÔ›-´éÁ´üÒd¨ﬁÓÏ_ÜÍ|^%√¸M%gÏÜŒW®“…’8û\0≤!Yâü”üÊˇ≤.ÉáWA7J{7·Û˙R–4∏\Z^ïNS˘:4îù/∏°î¯}∞ÁÎx>(b”±W6k∏÷-Ìy‚?Ê°∑Ï|QNv˛§Ñ…3ó%≥âV¿…nò`;_VnÀ™—Ç)3Ú}QƒEífÿß”ÍL0¶Ú,.Cüè‹\\çˆ$jÛÎ0Ωº{\nÜR∏ê™‡«4÷7N5¡›Ù0Ì® Pï)¬£ifæ©◊&t	sñ(Ta,·MÕxe4ôP∏-°r√ê?òx3P√;ßI¥’TÜâ¶‘†dlóh¢j¶áfüΩÕ»ˆå•%ÏµPPvcF3œJŸe‡aî\\—î_6‰4e£3ºô¢h≠zx¡1ñî#Ò¬É4ôªÙôò¢©Ú¡t,Oq$+§…Œ‚áëüGÃ@DÎxƒkHÚ<#•¢Õ†fÍG`P3çüQ≈ﬁáÊiÜœ§{∑2©‡∑hﬂ+Œöõü˜√fv˚ûgdèÅüú}ª?m∂Òï¡W“¸Ω®√ëj0s¨ÙuìMEMü/√g0∆5ïë”új3ØJ%;öwbﬁ6o|~ÿJ‰Msq}ì4≥äâzRUâê‹π#ÕM∆M3≈2˚^Üü“«\0◊Ø≥f≥Û◊2ú7‚ØŒûûùøô€®\0GSvåˆπu7ªë,π8*rÉø∑-ÜsØ°≤„ˇ¸ﬁåh…&‘Ï(qNﬂ~¨M(I…≠˚£ﬂ%+ChküÓS¸ÏÙW˛‚1≠˘≥UÉè∑%-+a,⁄Èe<üäâàû7%Çâàb∑wTÃ¨ó∆¸IàùÕ∞”Úç6òQÜ0ì¢4<7É6ôˇÔ„†c™√áRMè7’®b\Z6,ôR«[Uáπ·P]…f¥9¬Sk’Á5\r“¶ËGå«]ÃY˜qÜ‘LÉè∆HÕT»Ï‚Ê àÛË¯∑4zF3s˙·u“ñMµ©‚≠3ß~™∑\Z€ı“<;˘≈f®I ##ﬁÛGU“ˆ;Ävì¿¶ﬁÜ9´z‘ÆºRÏ§t∫“|–8¢æÒ=Y≥Õ *(5œò≤¿/‹yæZW™a≤¥Mi»B>Çø‹>o¢a\\’ àª«˛&´≈ŒgN√Pù…trV∏xÀX¥˘B}ûo_3°-Öd*w∂í;\n≥yÅ…|7Û~g’îÕ©3’ïGøÓê[†o± ÓÃX–iﬂEÛÚ≤ıØòÄﬁ’k˙†û+éøcˇ®¯À¶·£Íå<úæl÷RŸtn6:õNÅtVùUÜjÕña®¶!ã¬W”»ó•k≥0]ﬂÜuŒUmM+÷ª¯Ê#)G‘	è”á”<2ß3≤#Ì—ë9Èx;2rå∑+ˇCY«c¿4ÌxºÈœO;∆¶◊>ûv‹n¯≥ù_ÌØ◊gK¸X&Íı8˘HW“«ìèwÀÛõO#¶˚Â˘nˇÕ/~2È®Øfvœ:˛ˆâ_(û˛2ÒÎÛ~·ı(Û»_§},ˇhø\"äΩï(Ëù@Rk≈~dƒ?2¢Ø?<ZWîÍïg∆ÔîËœqëÍÈ’èû∆+í/ÓlÄëè˝qúéÂx{àø—¨wîÌg^E)‚µßy˝≈/ON~È¸/˛œO´ıv}∂\'b/˝Z‚©Â›ÍÍ˙lœú3Pøò~wçü‚≈Á\r†öø9˝Õ\'o~˜‚ó!óo~1~ıV∏ûø¿À_}˛ıS?˚äWw·«~‰,ë?ß¡≥‰£≥‰~ﬁƒîÖºgÔVÚ!§*˙‰|µ\\u—k!.”Ú<e¡Ë2üµ¸Æ˙µ;o’˘ÚÓ‹%ˆËÓë?\0˙±ÌèQπò>›≠Æ/¯ª…Ô◊ók‚éøÏ~˚”◊öì«œUø€‡7€ó´Â˘_/6+¢·È_ft’›è€}œ◊ªÉø\'¸Î€-øæ⁄@DÛÚB¿›áı~¸P¸~Ω‘_U>[Oáı^>ﬂlÿÎÀiy∂{èèﬂ=«ì¯]ÌÂaá_~ø¡>¯—aË°⁄œ¸≈]≠ÀiÔë⁄oΩñEV÷ì™ÊœÜÃÕv–á\rë˛è3_éËqÓºE”ì›{\Z¨<~cÙ#p}ı√{TmvIGKˇ?Ám7…\nendstream\nendobj\n20 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F5\n/BaseFont /Courier\n/Encoding /WinAnsiEncoding\n>>\nendobj\n21 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/CA 0.93\n>>\nendobj\n22 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/ca 0.93\n>>\nendobj\nxref\n0 23\n0000000000 65535 f \n0000000009 00000 n \n0000000074 00000 n \n0000000120 00000 n \n0000000404 00000 n \n0000000433 00000 n \n0000000644 00000 n \n0000000747 00000 n \n0000007060 00000 n \n0000007167 00000 n \n0000007275 00000 n \n0000007388 00000 n \n0000007504 00000 n \n0000007561 00000 n \n0000007618 00000 n \n0000007723 00000 n \n0000012329 00000 n \n0000012434 00000 n \n0000016812 00000 n \n0000016917 00000 n \n0000032108 00000 n \n0000032214 00000 n \n0000032274 00000 n \ntrailer\n<<\n/Size 23\n/Root 1 0 R\n/Info 5 0 R\n/ID[<1596933cbcd8a12091c18b8c2c2ca9f4><1596933cbcd8a12091c18b8c2c2ca9f4>]\n>>\nstartxref\n32334\n%%EOF\n','91fcc83581a71ea65d15c053552d75f3a8144ddc9f3b76a8a44dd38486aac1f4','2026-10-10 16:23:42','2026-10-10 16:23:42',NULL),(2,'KRM-CC-01-000002','firmado',1,4,1,2,55,'ZDMZZZZZ0PS101924',22,13,'Mar√≠a De Todos Los Angeles',359002.51,50000.00,309002.51,6180.05,315182.56,18.000,22.00,24,15735.21,62462.39,377644.95,50000.00,'Efectivo',50000.00,0.00,'{\"folio\":\"KRM-CC-01-000002\",\"operacion\":{\"fecha\":\"10\\/10\\/2026\",\"fecha_larga\":\"10 de octubre de 2026\",\"hora\":\"16:30:26\",\"fecha_iso\":\"2026-10-10 16:30:26\",\"sucursal\":\"Manzanillo\",\"sucursal_ciudad\":\"Manzanillo\",\"caja\":\"01\",\"ticket\":2,\"folio_venta\":\"KRM-01-000022\",\"id_venta\":22,\"cajero\":\"Carolina Martinez\",\"codigo_empleado\":\"EMP-0004\",\"metodo_pago\":\"Efectivo\",\"importe_cobrado\":50000,\"recibido\":50000,\"cambio\":0},\"vendedor\":{\"razon_social\":\"KARMA S.A. de C.V.\",\"rfc\":\"KAR000000DEM\",\"domicilio\":\"Av. Miguel de la Madrid 100, Manzanillo, Colima\",\"telefono\":\"3140000000\",\"email\":\"manzanillo@karma.local\",\"sucursal\":\"Manzanillo\"},\"representante\":{\"nombre\":\"Carolina Martinez\",\"rol\":\"Cajero\",\"codigo\":\"EMP-0004\"},\"acreditado\":{\"nombre\":\"Mar√≠a De Todos Los Angeles\",\"rfc_curp\":\"MAZC060605MCMRXRA7\",\"email\":\"mariadelosangeles@gmail.com\",\"celular\":\"3145439851\",\"direccion\":\"Avenida Cerro de La Cruz #54\",\"identificacion_tipo\":\"INE\",\"identificacion_numero\":\"298463710372\"},\"vehiculo\":{\"id_producto\":55,\"tipo\":\"moto\",\"marca\":\"Ducati\",\"modelo\":\"SuperSport 950\",\"anio\":2023,\"version\":\"V2 Testastretta ¬∑ 6 velocidades con Ducati Quick Shift ¬∑ 110 hp\",\"cilindraje\":\"937 cc\",\"vin\":\"ZDMZZZZZ0PS101924\",\"numero_motor\":null,\"color\":\"Blanco Dark\",\"color_interior\":null,\"condicion\":\"nuevo\",\"nuevo\":true,\"codigo\":\"KRM-CAT-DUC-15\"},\"credito\":{\"precio_contado\":359002.51,\"enganche\":50000,\"enganche_tipo\":\"monto\",\"enganche_pct\":13.93,\"saldo_financiar\":309002.51,\"comision_apertura_pct\":2,\"comision_apertura\":6180.05,\"monto_financiado\":315182.56,\"tasa_anual\":18,\"tasa_mensual\":1.5,\"tasa_moratoria\":null,\"cat\":22,\"plazo_meses\":24,\"mensualidad\":15735.21,\"monto_interes\":62462.39,\"monto_total\":377644.95,\"dia_pago\":10,\"primer_vencimiento\":\"10\\/11\\/2026\",\"ultimo_vencimiento\":\"10\\/10\\/2028\"},\"amortizacion\":[{\"pago\":1,\"fecha\":\"10\\/11\\/2026\",\"cuota\":15735.21,\"capital\":11007.47,\"interes\":4727.74,\"saldo\":304175.09},{\"pago\":2,\"fecha\":\"10\\/12\\/2026\",\"cuota\":15735.21,\"capital\":11172.58,\"interes\":4562.63,\"saldo\":293002.51},{\"pago\":3,\"fecha\":\"10\\/01\\/2027\",\"cuota\":15735.21,\"capital\":11340.17,\"interes\":4395.04,\"saldo\":281662.34},{\"pago\":4,\"fecha\":\"10\\/02\\/2027\",\"cuota\":15735.21,\"capital\":11510.27,\"interes\":4224.94,\"saldo\":270152.07},{\"pago\":5,\"fecha\":\"10\\/03\\/2027\",\"cuota\":15735.21,\"capital\":11682.93,\"interes\":4052.28,\"saldo\":258469.15},{\"pago\":6,\"fecha\":\"10\\/04\\/2027\",\"cuota\":15735.21,\"capital\":11858.17,\"interes\":3877.04,\"saldo\":246610.98},{\"pago\":7,\"fecha\":\"10\\/05\\/2027\",\"cuota\":15735.21,\"capital\":12036.04,\"interes\":3699.16,\"saldo\":234574.94},{\"pago\":8,\"fecha\":\"10\\/06\\/2027\",\"cuota\":15735.21,\"capital\":12216.58,\"interes\":3518.62,\"saldo\":222358.35},{\"pago\":9,\"fecha\":\"10\\/07\\/2027\",\"cuota\":15735.21,\"capital\":12399.83,\"interes\":3335.38,\"saldo\":209958.52},{\"pago\":10,\"fecha\":\"10\\/08\\/2027\",\"cuota\":15735.21,\"capital\":12585.83,\"interes\":3149.38,\"saldo\":197372.7},{\"pago\":11,\"fecha\":\"10\\/09\\/2027\",\"cuota\":15735.21,\"capital\":12774.62,\"interes\":2960.59,\"saldo\":184598.08},{\"pago\":12,\"fecha\":\"10\\/10\\/2027\",\"cuota\":15735.21,\"capital\":12966.24,\"interes\":2768.97,\"saldo\":171631.84},{\"pago\":13,\"fecha\":\"10\\/11\\/2027\",\"cuota\":15735.21,\"capital\":13160.73,\"interes\":2574.48,\"saldo\":158471.12},{\"pago\":14,\"fecha\":\"10\\/12\\/2027\",\"cuota\":15735.21,\"capital\":13358.14,\"interes\":2377.07,\"saldo\":145112.98},{\"pago\":15,\"fecha\":\"10\\/01\\/2028\",\"cuota\":15735.21,\"capital\":13558.51,\"interes\":2176.69,\"saldo\":131554.46},{\"pago\":16,\"fecha\":\"10\\/02\\/2028\",\"cuota\":15735.21,\"capital\":13761.89,\"interes\":1973.32,\"saldo\":117792.58},{\"pago\":17,\"fecha\":\"10\\/03\\/2028\",\"cuota\":15735.21,\"capital\":13968.32,\"interes\":1766.89,\"saldo\":103824.26},{\"pago\":18,\"fecha\":\"10\\/04\\/2028\",\"cuota\":15735.21,\"capital\":14177.84,\"interes\":1557.36,\"saldo\":89646.42},{\"pago\":19,\"fecha\":\"10\\/05\\/2028\",\"cuota\":15735.21,\"capital\":14390.51,\"interes\":1344.7,\"saldo\":75255.91},{\"pago\":20,\"fecha\":\"10\\/06\\/2028\",\"cuota\":15735.21,\"capital\":14606.37,\"interes\":1128.84,\"saldo\":60649.54},{\"pago\":21,\"fecha\":\"10\\/07\\/2028\",\"cuota\":15735.21,\"capital\":14825.46,\"interes\":909.74,\"saldo\":45824.07},{\"pago\":22,\"fecha\":\"10\\/08\\/2028\",\"cuota\":15735.21,\"capital\":15047.85,\"interes\":687.36,\"saldo\":30776.23},{\"pago\":23,\"fecha\":\"10\\/09\\/2028\",\"cuota\":15735.21,\"capital\":15273.56,\"interes\":461.64,\"saldo\":15502.67},{\"pago\":24,\"fecha\":\"10\\/10\\/2028\",\"cuota\":15735.21,\"capital\":15502.67,\"interes\":232.54,\"saldo\":0}],\"otros_articulos\":[],\"solicitud\":{\"items\":[{\"producto_id\":55,\"cantidad\":1,\"vin\":\"ZDMZZZZZ0PS101924\",\"motor_serie\":\"V2 Testastretta\",\"color_interior\":\"\",\"es_credito\":true}],\"ordenes_web\":[],\"cliente\":{\"nombre\":\"Mar√≠a De Todos Los Angeles\",\"rfc_curp\":\"MAZC060605MCMRXRA7\",\"email\":\"mariadelosangeles@gmail.com\",\"celular\":\"3145439851\",\"direccion\":\"Avenida Cerro de La Cruz #54\",\"identificacion_tipo\":\"INE\",\"identificacion_numero\":\"298463710372\"},\"precios\":[359002.51],\"articulo\":\"Ducati SuperSport 950 (2023)\"},\"id_cliente\":13,\"integridad\":\"2b6ece393739661d0eafae1c1bfd2708452239bad7b11a0c381096527620feb4\"}','<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 600 200\" width=\"600\" height=\"200\"><path fill=\"none\" stroke=\"#0D1B3E\" stroke-width=\"3.4\" stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"M211.7 122.2 Q217.1 118.6 221.6 115.4 Q226.2 112.2 228.9 110.0 Q231.6 107.7 234.3 105.9 Q237.0 104.1 239.3 102.3 Q241.6 100.5 242.5 100.0 Q243.4 99.5 244.3 98.6 Q245.2 97.7 246.1 97.2 Q247.0 96.8 247.9 95.9 Q248.8 95.0 249.2 94.5 Q249.7 94.1 250.1 95.4 Q250.6 96.8 249.2 98.7 Q247.9 100.5 245.2 104.1 Q242.5 107.7 239.8 113.6 Q237.0 119.5 233.8 125.0 Q230.7 130.4 227.5 136.2 Q224.3 142.1 221.6 147.6 Q218.9 153.0 217.1 155.7 Q215.3 158.4 214.4 159.8 Q213.5 161.2 213.1 162.1 Q212.6 163.0 212.1 163.9 Q211.7 164.8 211.2 165.2 Q210.8 165.7 211.2 165.2 Q211.7 164.8 213.1 163.4 Q214.4 162.1 217.6 158.9 Q220.7 155.7 224.8 151.2 Q228.9 146.7 233.4 141.2 Q237.9 135.8 242.4 131.2 Q247.0 126.7 250.6 123.1 Q254.2 119.5 258.3 116.3 Q262.4 113.1 264.6 110.8 Q266.9 108.6 268.8 106.8 Q270.6 105.0 271.5 104.1 Q272.4 103.2 273.3 102.8 Q274.2 102.3 275.1 101.8 Q276.0 101.4 276.0 102.3 Q276.0 103.2 274.6 104.6 Q273.3 105.9 270.6 110.0 Q267.8 114.0 263.8 119.5 Q259.7 124.9 255.6 130.4 Q251.5 135.8 247.9 141.7 Q244.3 147.6 241.1 151.6 Q237.9 155.7 236.1 158.4 Q234.3 161.2 233.9 162.6 Q233.4 163.9 232.5 164.8 Q231.6 165.7 231.1 166.1 Q230.7 166.6 231.6 166.1 Q232.5 165.7 233.8 164.3 Q235.2 163.0 240.6 157.6 Q246.1 152.1 257.9 142.1 Q269.6 132.2 288.6 115.4 Q307.7 98.6 325.4 80.9 Q343.0 63.3 353.9 53.3 Q364.8 43.4 372.5 36.6 Q380.2 29.8 383.8 26.6 Q387.4 23.4 388.8 22.0 Q390.2 20.7 391.1 20.2 Q392.0 19.8 392.4 19.4 Q392.9 18.9 392.4 19.4 Q392.0 19.8 390.6 21.1 Q389.2 22.5 386.0 25.7 Q382.9 28.9 379.3 33.4 Q375.7 37.9 370.7 43.8 Q365.7 49.7 360.2 57.0 Q354.8 64.2 348.9 71.5 Q343.0 78.7 338.9 83.7 Q334.9 88.7 331.7 93.2 Q328.5 97.7 327.1 100.5 Q325.8 103.2 324.5 105.0 Q323.1 106.8 322.6 107.7 Q322.2 108.6 322.2 109.5 Q322.2 110.4 323.5 110.4 Q324.9 110.4 327.6 108.6 Q330.4 106.8 334.9 104.5 Q339.4 102.3 347.1 97.3 Q354.8 92.3 366.6 85.0 Q378.4 77.8 387.9 71.9 Q397.4 66.0 403.3 62.0 Q409.2 57.9 412.8 55.6 Q416.4 53.3 418.7 52.4 Q421.0 51.5 422.4 51.0 Q423.7 50.6 423.2 52.0 Q422.8 53.3 420.1 55.6 Q417.3 57.9 414.6 60.6 Q411.9 63.3 406.9 68.3 Q401.9 73.3 396.9 77.8 Q392.0 82.3 386.6 88.2 Q381.1 94.1 377.5 98.7 Q373.8 103.2 370.2 107.2 Q366.6 111.3 364.8 114.0 Q363.0 116.8 360.7 119.0 Q358.4 121.3 357.0 123.5 Q355.7 125.8 354.8 127.2 Q353.9 128.5 353.4 129.4 Q353.0 130.4 352.1 130.4 Q351.2 130.4 350.8 131.3 Q350.3 132.2 349.9 132.6 Q349.4 133.1 349.4 134.0 Q349.4 134.9 350.8 134.9 Q352.1 134.9 352.6 134.4 Q353.0 134.0 354.4 133.6 Q355.7 133.1 357.0 133.1 Q358.4 133.1 359.4 132.6 Q360.3 132.2 360.8 131.8 Q361.2 131.3 362.1 131.3 Q363.0 131.3 361.1 132.2 Q359.3 133.1 356.6 134.9 Q353.9 136.7 350.3 138.9 Q346.7 141.2 341.2 144.4 Q335.8 147.6 330.8 151.2 Q325.8 154.8 320.4 158.0 Q315.0 161.2 309.6 163.4 Q304.1 165.7 300.0 167.9 Q295.9 170.2 292.3 172.0 Q288.7 173.8 285.0 174.8 Q281.4 175.7 278.7 177.1 Q276.0 178.4 273.3 178.9 Q270.6 179.3 268.8 180.2 Q266.9 181.1 265.1 181.1 Q263.3 181.1 262.4 181.6 Q261.5 182.0 260.6 182.0 Q259.7 182.0 258.8 182.0 Q257.9 182.0 257.0 182.0 Q256.1 182.0 255.2 182.0 Q254.2 182.0 253.3 181.6 Q252.4 181.1 251.5 180.6 Q250.6 180.2 248.8 178.8 Q247.0 177.5 245.7 177.5 Q244.3 177.5 242.0 176.2 Q239.7 174.8 238.3 173.9 Q237.0 172.9 235.7 172.0 Q234.3 171.1 232.9 170.6 Q231.6 170.2 230.2 169.8 Q228.9 169.3 227.6 168.9 Q226.2 168.4 224.3 167.5 Q222.5 166.6 221.2 166.1 Q219.8 165.7 218.0 164.8 Q216.2 163.9 213.9 163.0 Q211.7 162.1 208.1 160.2 Q204.4 158.4 201.7 157.1 Q199.0 155.7 196.2 154.8 Q193.5 153.9 190.8 153.0 Q188.1 152.1 186.3 150.8 Q184.5 149.4 183.2 148.9 Q181.8 148.5 180.9 148.1 Q179.9 147.6 179.0 147.1 Q178.1 146.7 177.2 146.7 Q176.3 146.7 175.9 146.2 Q175.4 145.8 176.3 144.9 Q177.2 143.9 178.6 143.4 Q179.9 143.0 182.7 142.6 Q185.4 142.1 191.3 139.4 Q197.2 136.7 208.9 133.6 Q220.7 130.4 239.3 124.5 Q257.9 118.6 280.5 114.0 Q303.2 109.5 319.5 105.9 Q335.8 102.3 348.5 100.4 Q361.2 98.6 370.7 97.2 Q380.2 95.9 386.5 95.0 Q392.9 94.1 397.9 93.7 Q402.8 93.2 405.6 92.8 Q408.3 92.3 410.1 91.8 Q411.9 91.4 412.8 91.0 Q413.7 90.5 414.6 90.5 Q415.5 90.5 415.9 90.0 Q416.4 89.6 416.9 89.2 L417.3 88.7\"/></svg>','%PDF-1.7\n1 0 obj\n<< /Type /Catalog\n/Outlines 2 0 R\n/Pages 3 0 R >>\nendobj\n2 0 obj\n<< /Type /Outlines /Count 0 >>\nendobj\n3 0 obj\n<< /Type /Pages\n/Kids [6 0 R\n14 0 R\n16 0 R\n18 0 R\n]\n/Count 4\n/Resources <<\n/ProcSet 4 0 R\n/Font << \n/F1 8 0 R\n/F2 9 0 R\n/F3 10 0 R\n/F4 11 0 R\n/F5 20 0 R\n>>\n/ExtGState << \n/GS1 12 0 R\n/GS2 13 0 R\n/GS3 21 0 R\n/GS4 22 0 R\n>>\n>>\n/MediaBox [0.000 0.000 612.000 792.000]\n >>\nendobj\n4 0 obj\n[/PDF /Text ]\nendobj\n5 0 obj\n<<\n/Producer (˛ˇ\0d\0o\0m\0p\0d\0f\0 \03\0.\01\0.\06\0 \0+\0 \0C\0P\0D\0F)\n/CreationDate (D:20261011003026+02\'00\')\n/ModDate (D:20261011003026+02\'00\')\n/Title (˛ˇ\0C\0o\0n\0t\0r\0a\0t\0o\0 \0K\0R\0M\0-\0C\0C\0-\00\01\0-\00\00\00\00\00\02)\n>>\nendobj\n6 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 7 0 R\n>>\nendobj\n7 0 obj\n<< /Filter /FlateDecode\n/Length 6251 >>\nstream\nxú≠\\Ks[«ïﬁÎWtUú*yJÜ˚˝*≤·!	\ri&é≤∏Æ(8x–\0©ôËè‰ßx=K/f5ªÏºÃ\"ã©¸Å9ßﬂ \0ÚR5qLQ}ªOü«wæ”}·g?=#¥GÖ∆üîñüB)z‹P¢ùÍ9Õ»lıå∞˝AÛ´Zƒ8U˛KÜnØü1ÚÑíÔ·ﬂü˝ÑC¥ÄwìKÉC4ï=\'a.⁄≥∞˙\nFxŒ≤|¶MaΩÄÎ 0=´P¿®`=ør∆˝,(≤¬Rˆ¥Ù\"∆yè¬ßR∏4äI€3†¢,â8Ö·Õ+ëÏqá\"UD†ZKd¢g`î—ezò÷¡&¨0Y/ò#Ïˆ©EêÅ⁄A∆TO¯M[X›ãp\nÎ¸∂çÙ∫2¶uú-õÜ9ŸS~ó  (Ç_®7èLˆb8=CW\"Æ(lè{´2Îz2)ïÎ0P—±¥Ic‡K”5l1`Â¥AÔ6Õì@ÉÌZX◊Ù$,)ivñ‡=!ÇØ¢ºß(:T$	,ç\Zc»ﬁãú%˘\0\"„A(é¡§D!Ó7.Çy8ƒÇˆ÷·4NûTﬁˆTñ^ùlà/Åë√m1:JÂ=H”£`ZÕío`/‘÷Ü\0K˙]Zö˜Ñiêòúı8Érîg¢ßâ˜î2—yL∫ËbMìã5d±ﬁè\rÙ@»$ïÇ\n¥e>®åã\"j!ï˝Éé¶hã–î“¨ó°1hC ;Óå\"à*ç·nhùÜ⁄‚¶´<°=áyBu)ÁM…\"úCÏÂÉƒ\ZE¥ûÀ¿ÙJîπ@Uá1†KŒ¡ØF	õJ# p|–Eëé\"·ìå#SñËò™ös°sy0¸^ƒa*[∆ß∏Iê&Bà13Qkq?≥·1o%ècååû/KÔc‚0πıc,ãÛ@ÄküŸVD¯ÑΩ*?≥’&gNòŸ⁄ÚhHˇîã¡‚Õ·≥À·Í†=œhÊ,ƒDõ†&\'åÕœ÷ß¿\na∑xí¬Æ>g\n8Éíà#¬ïQ∞\'.—êEdòü^ÍÚ d\nÊ‡Gâ0Á°OÒ‚o(aT∫`é≥~´∫ÄÌäî™ta¶öKÏw~¡(¯’T™Ç>N ñÈ#W†QÖÃﬂ˘§@∏´\Z∫-€ã˙h≥F‘v∆T*ˇúÉÄ	„r)sX…¶cÚÖ„!DçE≈•J\n S5óÁ±ƒb,+üˇiñ&ÇUbºöú,÷,¥GÑ*HE&c	(BïIs4∏\0U\"è\nAÄeLÛ”+•ìHGj†xÒ∏¢¢2)ë0_öTr!†Ñœ\0©…@C≤P%ì◊Òs…Ã<`€DJ\\`L—™B\'U™úP»§îÉ`/ëÚõ“¿B@Ñ†äN¥)B∏Â—e4b*»FXv2±)Ô%>9Ãà%—⁄¢h!å*ù9LÑ+C©≈‚#b0¬òÄﬂ‡xç¿lJ›;29®Äª˘:gDŒIÿG\n¿*æ–º¿-ò!QKSIîœGZ=Ö˚R Vk°ÎUauPŒ±∫Iõ%†≥ıhüã*§3>%EŒ;¿,8íô{÷òÔ,X¢í’ ≈Åxa\ZôR·T¥á∏P03œ8∆l± Ò\\πçeä£b¡Ô c$œEKpì9–8°Ÿh\0vë2’Ò—9<Mãa´9ÿÄ´ΩÿÀK$J\0:üV)ZÅÂÑ≤¢“SX∞|uº_‘|°ã—ä’€∫%cvÄ7bÜ&\0Ä‘≈G¶\"ô§]–:J¿R2‰b,≥Hºe∞áIº\r“ŒÏYH§¢*ÑàñÊﬁ+ âΩ¬€sq»ï∞3Æc,@t@é„.Úü‡C˙°≤Áy†w\"óGâ‘H∏ú+±ÃJ–+`ª¢ˆ≤&*Í!Mn\Z4ıë®J¥¬™P)!3r‘G?+¨ê°ê†ŒXÀÍ2ÿE≥úH1/e…ÍQÔer,S\Z\"¿êPÌäƒÑbWÙ¡¶É÷µ˚#Éòî3∆6ŒS0âGŸL^†\'Ù‹ÕÊ]pvÍ \"å\r˘)2¯ÑÈ‡Â0ìîa*—UÎúH±ä,/4<í%D∆æ0àtb√íF‹ñ©ü¢ê%.dG.`Ä\0¯JÊ‚+X™::’&MY|◊‹Û\"â\"Í˚êä.ReºY±≤¶πT*£ôBñreTÆ`,ñ+lO3Ω a\\ZfpëFf™ÿÚÇ»BêJ˘‘±q*áΩC‡ö6q-„hqNÄ\'Ç¬.óó‹E¡®¿o§\'.óà¡◊E≠mûŸ≥OÏ”J‘¡.ÖouåÕ	Fc[kd!a´H$Lãn3•B!•C^©+^âΩ8äXô>≈§T¶	ø¢“ﬂ\r…® *ÅÏß™wTƒÉ\rY±OÏÿ}≈À˘H1àÙﬁ¡Ù@Ü-Kˆ”xd!l·ï¡Ó∫¯–Œ ØDπx:<)2a‚°‹eÓ	 è¿Õu2ªÖ5hÑ‚(¡vÊ·ô»ÿ‹äSoH3K—S°ä•\r<;0ìN.∞±—KSD#É’âëANôpë»X]Èêû˚≈öÄ¯Û{\"vnBFaü¶B¶ª,ëAy)JB!Rê• ‘VD	R$ÜE¬b£˘m‘Q`?\"–∞ËÓ°≥o÷‰°ú∫pöÇ2<‡YêÔvYñpøÜ»9 ¡ûåÂF¬gX‡K¿†wXB€èŸ;ìÒ¯@CﬁƒΩG‚π7i÷¢A…Ü\n©QÙFòR	‘\nJÄpé˝\"ëíhπàÅq–¬pvaòãaü÷2±Eê@%\"rB∂†/Ö„yåÛh/rWôûàc,HD∂ºâkEA¥≈(y\"\"%ÈîaêÒ!F4˙=ñ\0§ä¥>nBâRıyòóÿ@Ií\n¢(±ZZ9ô2HTñÑ|≤±˘¬»2IçÖÃô\nOv2<ZU\"Sáyd≤ãfSÙÇ¬€«Çﬂ±sô¨#=\'.Ì‘@u¡}…‹∫höbCD*åG,I-qXﬁ¯Ê!œ,Ç5Jˇm\0ãyìë”∏@Ò-œ˚B\r}SîÏúvÅ$%XlòB›·ëƒY%2õ€$´C¥X–0†Ñµ¡Ú#t˙6fä≈Ïg.Ò ìùÄæ,=ï™<J3óœ”$D!~\\lŒîçÿ‘k^$¡bëb£$ƒ™é9ËâU‡XÒ°ÓÇ$¥öºí`ÓŸÏ¡4ÍÃ\"˙™º”@ò¥âˆÅåÕ∂∂°±¥6Â©Nˆ¡SÅ(ÅÊ:äg0X 1ÆãWµ∫åû4Yùs\'28ï,6<\"0ù€Z©@≤ÄΩ<ÿ˜rŸ£hrQT≥˙ÿ“#§?»¨qsœffÅòâQbs¨Jâ0 õàÌ…GŸÖB\Z‚B&I®’%Ulwl§û•¶‡…O$Ø1s—;!∆êîdÍ™É•lÆ™¢·{S˝*1&‚ÕÜè±HÃm⁄8¶À<<H¬©dYôF“\'∞J!t…ù0s:IsÅ”‡)LÙ2x; mj≠Ih,RVÜá÷πê_=:»aÃõõ$îXVìJî Í…ÃeP¢|›·Y∞Rf˙(bì$\\y*êÚ¬»`/ZJ‰òî∏\Z%»>Eslàò›vœ§DDı‹∞&´˙∫£≤Â=Úõ<F˘∆Y‰√HîËΩ∫sü#!ozˇOœ˛˛˘˙€+FÆw¯\'«?èﬁ˜˝Ûî∏¿∞V;Ì»tü\"ÌüŒ»◊/9^Î¡ÔÔ	˘√ÛÈO.˙_˛ëLøèwä0d8}ÜFÃaI∞Er˜&ÜƒPN·ƒ_ød|]OGÆz˝ô∑d–{”#?ì˛uªû-\Z“‹›nVõ€Ì‚ØÓfw€]≥$Õ˙S≥^,óõ†¨^BÙ1a˚ı?ˆ»≈‚˙Æ]‚BÀ¶ôosÏ¶^TSæ ÉÕr±j`¡iªÏ«ÜhÒˇÀã⁄pÚÌ34WºY˝!Ñ_Ê˛íOSE4ﬁ–Mò«Wÿ¢¬€ñ\\°Ê\nO)åı›<å7æ†—¯åËºá¡¯r:ÈO«‰r‹;ÊÇ„æï&Lg“$L#¸enr¬‰‚´¡‡+ æÚ;Â’Vè{U‚è‡ƒ≥+)P˘¢˘Cˇrt~>ÀéœG‡ÏüaÈØ·ˇúrM~>‹ö#Ÿâ‡M…òüÈo˝ÜÎéÊ\0Ê†x8n§ xXçÎxdºGﬁ?,£˛ˆÏÔb54öêÿíïdJ0\';t”Ÿˆ|Òj“3ºúˆIü&øúç‡A&√´·‰Mùç/Fó£Ò±=k	Ú\r?°ÊG]XéÓ´VÊÌ6{Ùbsªô-fÀˆ∂!Îªˆ#∆ÛÀ≈∫¡¥Z-⁄ıÌÜÃ€vÜ∂‰0	´pﬁ˜N*ˇ”UVTÿÁp^[Sœ[ëz§≈>\nﬂk¿ﬁí˘,Ä\0>Ãœ?«ôé2ÚlÍ¸€\nñ„s‡£q.§74iuäa@Ê∏·≥Ò‡ıXŸ˝lx1æFˇsI˛B^M∆ø‡£˛†ˆÀ≈h0;Ó’¯¡q3†˝ﬁ\n¨ZÅódÚrPÏ’Ó»›öÃõ`√yª⁄Ïn∑ÕlÒè5y˚|Ω!].Ê“¨o[®s’üæ˝í¸†gWØõ6∆∞ÉwáÀŒñøﬁÌÓ‡!≤€¨…byáã‹.>6ªo,Ú°Yì.≥m?.vÕ∆›l∂®ÿÕvÛæ›-6ÎˇÿÄÿu≥Ω\0z‰cj∂ü»èw€øœ≥¶GŒ7;≤X¡4∑ÌÓπmv\r¸q≥l>Å¸œ~√ªà°wÎ≈ºô€æ`ƒ·v@´èÌ:Œ∞πi£Õ∂Ìı˜6o|\n\nÔ‡ØÌ™)^˙)`a4Yë,‡^∞$\nXß¥«%‚@ób …”$¡øëı)úw«Ä>´Ï‘™◊D	xˇ	≈8O…T?X5\"çÀY>ËO˛k˙˙¸h9vBƒÑEïµO€ÿ–i¢+^˙CU¢L¶¥5ç√Ù≥iœ˙‘éÒ˙ü£#˙{ñ$¡c∫«AöGoyn	\n,}æü®0÷”n§¥6ŒU)\0*€`\nÈ6Ä|á¸æ|›?\'”Ò¥˛ˆÀ\'»∏^”õRU∂3FˇñÏ±\r|3CÌ?Çaûûÿ-÷dÙ¶üÒ∑[¨6ò†Å‘÷√Qí’Àí&√€ßªÿl⁄øÚugt9N~π\"„…ŸË≤?	§z^âTˆ°yΩ˝ª€=Oå˜∂å!&–¨P∞¸˚≈èM6%^’Zõœö∞´MâÊ•¥6eñt0•`·Âµ«My1∆ö„C,zû*|w#‰•|s√é·`¸/òÖå”Ÿ∏eÓj#d»©F)∑óÅIR?e∂ï%]UÜwÛûf™>y’ˇ∂?yBé¶e0ì1/¥Ñ∫£äô\"L·Q(Ï£Ç©(©a*¬bÜ)ˇBKGò¬w\nîz`ÛØŒ˚?å…◊‰ÚØ√â\')`ÄÒ’”AäBﬂÆÃë˝s(<ÌH…œÑÀΩíûî˜w,ÀVÌzwá,†ô∑ªC» ∆ÀêUØ\0T≤^ít1_FÄGÌ‹Ó\n¿et÷?#/Gﬂ-yè†ÃIÀ}˘eÖÇLﬁ|ôjÛR“Êì§ÀÊsÊ?<ìD\r˘=˘Î˘tt1&–NF#§ªü4\'ÌÄmmŸ_JèfA\'%ÉNùNbr>EImî1iTítJªÑèöÓ~©ªcgv¥‘=\n=\'\rwπ!7ÕÏˆÄ∫ﬁ«!i§TçCIq»¬{n»”jPîT`Öœ…=∞Ç& ≈1èÄïDúW˙¡xF±}Ö∆ıÏ	Qñ÷¿k	eè¬¥r/Ö+≈†¶ÿ\'AMmü<*(è™T‡\'Y(K:ò(Å≈„6\Z^~€ø|7$êÖì·∑O2R^Â¥ï}Åó√0’^ì*∏ÂbÔ¡öwæ}ŒPˇﬂ&˙[AY1nÇ≤⁄∏yT6nU∑¿[2nñt0nB†«ç;_åÆ∞y5ûê˛´·d˙zÚÑåÕù∂ØFÖØ?ÓôkÒX˘ÛÚ⁄¥	ãi ÓÂu\ZïMõG’âùA2gvíT¶- ôFeI\0àHˆ∏∆”Iˇä7å/áO·)i\rº^-À—TæZ¨È®ƒb47À≈¨Ÿ„,i	:Iv8À´Ê⁄≠,fãõfæ96ÕI+DúÂ`´ùåeÏﬂ^\0ÆoË?÷¿´Î˜õÌ\nœ^¬9HKfõ~é˚xAfÕrv∑]@ä@≥ÑøºèßnÛÕ<ÔÄG;<Ó¿SöÊ¶›ﬁﬁ¡˛TàxWQ1\\¢››Vá$GŒB§”Tï≥Iôîséc~ 	/.À4IYg!¯8{)%üu\"©g…ŒBF=rï˝\n´÷yüå4¸˘_˜´\n¸∫ﬁ∆X¯”r¶*„\n/7À≈&∏}çgpõ*“‚1\'ìq	Ám∏Œ©ß’îO>xÄaävQÚcªæm’P p\rxr>‘0™«kı¨?•µOß≥!‰©h¿˜\r8ï±s]$¬UtæDëxW≠[∫⁄„ı‰•<Ì/˜à∑N≠w‰‚È˛¸µçÏ∂¡ÏÕS+öh\ZÂ˛‘ﬁÓïùzâíc]∂ô]˛‡¢î·\rò_ó¸¶\nÃ‰P\rÌíµµC£§ãCï\0\rÿë‡mgöCoÊµ≤µ˜÷zƒõßÉ:i≤ô›ﬁΩ€‚Ò=¡∆Á–±yÒlıÕé=µ¯wõmsËœºVˆgáçfû‹hº\"#oüÄe˝e¿–aã8±_t„Líı∏QG‡oˇπòmj£AË t\rQ“%\Z8∫ª£qÿnÒbcw≥YÔöwÀˆ04Ú¬Ÿ_{?\ZßWﬁåÆÒéx{µˇ”aX‰Ö≥Û:Ï8á≈…Öˇ1_\\{¯nW7ÀH√aê‰ïsêtÿrvÌ©ïáØ‰%…«vªxDj~Ã”¯2ücµß£§Í`Ò´xP\\%IópÄJ/•8bõÕ;±KË±ØÅR}8YªÏßJª˚ îQ˚Í=4ßÙæog»\rc%kï}Xiu_á2™ã—rDù“jÓÒÄ≥º€\rß¨\\ß⁄°˜T)£∫ò,›)Â™.˜g»ÛŸ‚›bæ9ÜH‹©û4ˆëfÕÍêü/ØáDôñ\n·\nQ∆oô††ê‡cu ¡oß…Bîã‡≥à2Æ`˜Nì‰≥à2~…IKù\" ¿îGg√ÀÈËÂhÆ»=eæ\"Ø˙ìÈÒVØ„•†/\\·wñ´Ω∫i|e\rø±§TºﬂèØpqËÎ4êGÆ¬w≥òmﬁÉ/`ƒ£%éÔ˙Q}Ôù| ≈õ·ÂŸlå¶˝¡dË}ﬁ4:~-xê¬€o‹æ™´…êìÊÙqª\r4wÀ«[¸O9hΩ?[›–>¯∆√\n2Ï¥’_∫Îuj–+ºˇt6ºÿ?ã¢Xv¯˛ì≤zÚÌÛcÔFT5Â±}·WÑ;TÈzËŸ˚ú∑œw±ÿõˆë≠ûö∑Î+bµ“§¯@Vc\\>MØìu›33∏Êpöiª¸€˚Õz›¿l≥›∂öœ§Ÿ©)À´mÄù´ºΩﬂ˝©ŸÆöﬁr3€Îá’∆˜Ì’±ioÄøa+∫æmª´\\OW\'…ibV?ç_èQGB9 ‡€›·ÎÑÈe¥{”IÍ·Î`∫DôJ¡g·’L…ûÅf: û≠jì^p:Çﬂ¯$~£Îs`Q‡∑CT\\Ô¢`<ù:€?E6t–Ú\"^nVÿK·±ÿ≤Ìp>\"©Û°y¡Õo»YK¶õ˘fÁ_LÍØØ€euM˘®≤†#$”‡ı‰Uw=OÕu—ˇa@5¸£.ìüÙMw˝N°—hi„â∏=jøu)4Y◊ìÛ^!ﬂ/7=|ÂMja¶À…S–◊Éˆ–Tæ¡‰ƒ≥–mgmOŒ⁄ˇÿ‚;fd–nCÍû√Ô€ªO‰7Jv◊/“˛P5+|jJHG\ZXÄØ=8…ûÇ U≥]4–ﬁlvMÒﬂ]Øö≈≤ŸtHfR¨ïÖÃ2*Ω†’cu —ÄÆêŸ\"¯,2ãèC0Ud6I>ãÃ2Ü_ëíŸclˆúº~˜ﬂÉ◊ÁO\0∑ÿ~B[#ÿëC@¢Ÿ„«©©I<5ÀŸ›¨π]t>Â=©Ã„§Û·Ó©iÆÓn⁄Ìˆáƒ©˙˝ˆßÓZÂªª“ÌGAu\"Ä_¸‚ıiat8¿∑6ù>Tæˇø≤⁄∑√ΩıK_)tOÅ2fO£áΩ{J%Nπ8Ë˛≥2©óÆîπ∑v”¡<)FN)3]‹v˚Yôîûµ´ˆ◊.c:X&E⁄)e™◊—+,£˛?ﬁ¢õ…ŸÔOD¥ëπÁ/wìGø22àw2‰˛ï\n|v∂ô›≠¬;Ô˚ΩH÷†ÈÑ:	©¸˜4ËÉzΩ˙ı\Z©)√Ud5ıˇ»‚@¨\nendstream\nendobj\n8 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F1\n/BaseFont /Helvetica\n/Encoding /WinAnsiEncoding\n>>\nendobj\n9 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F2\n/BaseFont /Times-Bold\n/Encoding /WinAnsiEncoding\n>>\nendobj\n10 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F3\n/BaseFont /Helvetica-Bold\n/Encoding /WinAnsiEncoding\n>>\nendobj\n11 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F4\n/BaseFont /Helvetica-Oblique\n/Encoding /WinAnsiEncoding\n>>\nendobj\n12 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/CA 1\n>>\nendobj\n13 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/ca 1\n>>\nendobj\n14 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 15 0 R\n>>\nendobj\n15 0 obj\n<< /Filter /FlateDecode\n/Length 4493 >>\nstream\nxúù\\Àr‹6›˚+∞p™í*ö∆ã 9;E≤SJ∆éc)û™<L´-w“•ªÂôÃè‰S¸\r≥û/»rYeó’\\∞âãÀ@(^»Lú{q.\0≤˚œ7~\nm öÌoÒº™9≥?+¯YãäΩ˛\Zu¡˛…8˚ú}Àÿ˜èhS¶ÄKTeÔ÷™Ω˚”k¶ÀúKŒJ%Ú∫™ÿı\r{˙\\∞*◊Ï˙-cﬂ~¸fπ?¨˛ÿ~Ú=ª˛ú=ª~4…pDYÂ•âIvΩ<õ√qø<ˆÅˆ~πﬁ-V7ÕÕÚ¿ª-ª∏_4«˚Í~µ¯â]Ω[Ω=¬eBpˆÓ˛Q´í-»DÀº∞Ãe	48€\0ùK„[÷Ïj6lQ‰ºTl/_≤ßÏÂüõÂ~«nñÏ∞‹Øñÿı∞ß\rS‹‰ú˚ûIÌ\\ëŒøπxÒç˝√_]	.j©±„a7¶Uôó:-h%x^H‘>ﬁÕÓ∏€˚T:Ÿ∞¬‘πÆ“‚’0RR«∫›±˝Úv hnvlπeÀ5;¿ØÀM3\ZmArMGªkImSWπ( 1ÅÛ›z∑gÀaîIÿ√.»0˜:çs∞◊O◊Õv±cÕ˛ßÒ\0cóò˚Ñ8›\0œ∫⁄ˆA∆7!P7æ¡^é¢©U.´öå¢kI≈J@wb‹Õ´ın≥˝∏Ñ⁄Ö˘‰fµ†S◊∞/?ú¥˜aõz’∞Õg¨…å4B°|Ωµ≥\"€ﬁ/ﬂ7ÏWò¿⁄dP0uﬁ6∂<Ô@:0á~˜1FÈ+®ÈW–ﬂZî›wüå°4πÇr$É–µ¥vå)π®kI)£s%ã	˛q≥∫mÁô’ˆ=Ñ’Ä\Z«√Ñ¸pHø!r!8ºì&¡\ZﬁIÆ\"X√;…ê”º\rÓ$Wı7#åPÊæx˝‚…˘ŸıìãØœüàsˆ3éó“π®⁄\\Éj÷û«Dãµπ0Z∆5¸ÉmÅ>7™#ÛÉ.O´é∫-;-S“â≈µÿl|ıËÈgWÇ›Ïﬂ“˛=Ó†ñÉ´s)çMàzΩ^¥ZÁºÀ”Âõúù˘Ú‚Ú¸ÚÀóœÆÿÛÀóg/œ/üΩ>ª:%ç∑#˜µkö∏åEï®—`º⁄/´V∆PÜGÎ]7PwÔóÔ~_‹Øw≥K&©L^BA¸«™®3Œ!fA¿|.UBÅ\rd^*Ÿ&Õµ§09ÃÍcfœ∂∑‡]ÔñnN∫Ò—ª!CﬁÎx&\'°ûRbGf?\0¨’Gm÷Ô⁄±»ÿ¢π;ﬁ∑Îà;p∫\råÀƒ‘W‘&Ø\'Iq-	I)*ùóïSªj÷–ÌvyÑæó0-CnñVoW[H÷™Ÿÿñq¢<ó®>ôx¢zlTO<|$~YÉr4\røkI	ﬂîyeÃ‘⁄b≥≤[Ö6ÒÕ›ro«a-ˆç—ˆ˙ûâ6‘˘cìâ\nTQÄ*‰I;8Ãb}øBWÏ∆Ñ4åÃk…M◊ííõJ≤òÛVáÏ∏;6û¡DÕ¯Œ19ΩŒgíÍ˝±§4£p5X_•h∏]KJ∏0ás5·R◊Õ°9π;,4ˇw`ª˝\rΩ_M»˚«à{˝œD\"\03*Á±f{	~˘˘ôù,Ï“\Z7ÀÌ¡6v?Ïó\'ïÄÈa∑æ?Óäê5X_IS‘µ§§H¿˛H‘Û)⁄Ïˆ\rlπ¶RÑ˝cäz˝œ§(D\06]wÕ‚8Z/B¶ﬁ/˜l±˛Ì˛pønÿ’^]_æ8õ»ã\0~ 7íóÆ%%/‹Ó+&ˆÇ∞∏Áª‘ÀY;|◊∂jH˜√ﬁH^z˝œ‰%D@ DrXmŸÂõ≥r¥ol….≠FﬁÓˆõÊ∏zÇ˘Âd˚˚ˇΩ]Fó]πi˙Ï∏ñÑÏË Ó!&vRØ÷Õøw–˜÷o‘Oj>¢år‰Y∏ıYƒs§!a˛^ %X˚OBrıcse÷µZ‘4]KJ6å]^OÓÂ¨Ê‰±´cBdú	dÄôË1ò…•–sYòYKXÀë…jc\'j≤Æ%%dm˜\n>˜|πx◊lƒ∞oZ¨K\nﬂ7€Î{&ÿPÁø7Lpín+Äª˝\n¥€L¡ü\nÒTr@¯¿˛\\WõÆë€∆jî≠Û¢¢FÎZRÚ∑∞À\ZK¬Nß≠4ùÁ@≠∂æ;UH”‘£0ì¶á«Ff\Z|[’£òe	õIcÓZRbEn‰ƒ6Å..\Zò∞nõΩù“gf§Ç±˜®Ãƒ‚ÚXïef ãu1\n^º,ËNƒµêÛUâº*È¥ÈZ2§jÿ=ÛâM√ii∫≥ìxª8ΩŸ¨∂ÌaI{rÚK€yÛÖD0+àXO¯D≥=Æ´ª©eúèsK\"ÊØÍá\ZÅ`¨‡ÎÕ›zµh∂„”Uò‹úN]C—6¯ùˇTãµî9¨⁄˝ÈÄo¯Kßˆv^S-∫ñøt:†`Æ3ß!ú\\ü}˙˜3vÒåùΩ¯ÚııÂ7gÁóˇ}9>pxˆH`4oWÌ)6lÏâˆj˙Ûƒ§–‡p\' (∑]QÃ‰µÛq*∂…p`µ^ñ˚∂ø¬ä/•o¡Ñ/¬ùøôpéI¬y°*$Q√¡”H@Ùπ©ä0âÛ{òØ‹ß!ç Ö.êÜÄ•[\r;Ñ∞	Ü¬ãåƒŸª-Tå=7XÁò(£°°Ï3©ã$&Ì† ∏&»é ŒD√–)	ù´¢Nß∞Äë±9d‡∆ÏAñÅ±÷ö)0êZ¢!ñπtª1:Øå&è\\çÎzõîêza¬∑M¨ƒÏ¯KHÏü#∑âåÛ2◊eoÚWêı:÷õŒÏ£ØR”ª\nir≠cù)Æ3QZJ$©uQ⁄£º÷ŸÍ™%7Ûÿß/∞\0w3è 0ëvpÁÄ*<…JªW∂€%7µt\r1∑q#k⁄¸C]êåá·zÍ¬pì	c¿e√pŒI`áR\n—≥Rí})MÚƒN;¢n¢#Dáº`Å‚¶•¶®ﬁ”	ıN2≈N;¶8™CbÜÛVU¨ò0U\ZQUq™ÿ)•j\'KBuH&nbK†äU\Z§™3{Äf‘Lµπ>ëi7ô¶C^d≠í¿gÜ SY´¿i≠eπ#Ö€5ÿIç⁄CqˇÙ’C˚‡˜ìbÎ#b]Ö °Æx;E˚IsEÍ£é•ü(Ö!Qt≈ôÇÈTxÊC(¢¡>8 -Æ3Uo\nC$¢ö>6\n$à-+ëª´‘I÷!a∞5Ï–&¨√]Q√(õ Î 5$ÇÑ]ëêfLsÜúÎ©#6OŒ	+ÖùnêûÆÏ7jéhƒ<Sß“¶Æ\nÇLjéiÃ<Uß˘™Æ¶\"TEVÿ©s&©ÿ)•\Z0O’ïP\nUW°a™:≥ôØÁj»ıâL√Ü‡ô∫“NaÍÍ=ÃTñ<ÖÑÂ¸–,+©JR∏]Cﬂ$x¥®ı∫\ZÇ§∫\'àXW!H[Wj⁄<8ï*«RÅG¡ÉSqpo¶U∏ßV#C‡TÂ◊á!§áü$¢ö>6\n$à-ã*”p3y\r$jÖŒa13SÂäDW]Cä!UÉ2¶9≥Úv=u‰\"ÜÄ‰PX	ÏP∏!zV∏˙!Ü–ç2Eï&0≈*1}∞!tL£ÜÄTQÛ	T±¶¬TEV¡äTC†TCÜÄT±Ñ®bÖ©™¨*K∫dã2ç2≈“N`äıd*µ…å∞îFÜ\0¨T˚v)\'’Ω\\EjTC´cËrdHuO±ÆBê∂ÆäÄ! 8ï*«RÅ«¡©∏8ä7.3Æïƒäh∞érÇ´Ã‘ˆ·˝ÿU”«FÅ±•ÇÌnô∞∫ÈTÄ@&f_Z+¢´Æ!≈ öOúÅÕú\Z∏û:rC@r(¨v(‹=+\\ÛCËà∆ô¢JòbÑò>ÿ:¶QC@™®˘™XSa™2ì¬$ı®Ü©b	%P≈\n\rRU∞ó©r3s≤â}\"”à! S,Ì¶XÔA¶R LÅ]®—£VÀ™‰¨◊5ÜVêcËzdHuO±ÆBê∂Æ Ä! 8ï*«RÅ«¡©∏8ä7iÜIªöÿ! 8’Gπ¡U¶Ä∏öÿ! 6™¶èç	bK^g5§òÛI5¢Æ H3aè}…Q§kà\n™IC<ˆpSM&&9Çcqdá J†á \rÛ{ ´8Ç#\Zsdä2M`äeb˙PGpL£éÄTQÙ	T±®¬TeVT-™®#Ù®Ü©b\r%P≈\rRUô–5-—®#x¶G@¶X€)Ö‰\n>ú‘∫ÃT	’¿áé`YM{]ÉõLNE**¯õOúä°%xD*|È\n+å	ÖUO[ÇßZ%‡ÆÇ‡K‡T]‹©7.≥V⁄dï0ÑÚ\"Ä;ΩÖ¡eVÉAı»<∂ìÕp;ÖDàW∞GÄõ¯úö;ŸîˆΩ±a? »a§kH∞˚.˚†±2“û+;vaKÏPY	ÙPπA~Ó≠∆TKËàF,¡3Eô&0≈21}∞%tLcñ‡©¢Ë®bQÖ©Z·õ\\Œl_±SJ5`	û*÷PU,— U(SAÔâñÄL√ñ‡ôbmßí+¯pRKë%ÚJè,Xïï!ï€5,Ê\"Ú$)Ç—ÉeèHÖO ±∞ÇòÓ›ü	K@p™UéµèYÇSupToñ	ˆ?«ªNA¿QoApŸÏËÒ.¡c£l£Ë…JïÈR‰sìÆìçÜî	≥Ñ¬‰UAé#]Cä%h∏T»	e§=YvÏ\"ñÄÏPY	ÙPπA~ÓU£TKËà∆,ô¢LòbÑò>ÿ:¶QK@™(˙™XTa™™=·ò|ÏîR\rYR≈\ZJ†ä%\Z§*aÂ]“ßµqK@¶K@¶X€)Ö‰\n>úT]dˆ„	˛Æ%9u\rKP2Ø™©√”—£eèËÖﬂÉƒ¬\nb∫wç™±% ∏◊jk!≥˜ÍÍÅ£z√‡*+ÏÒã[Ç{AÙ¿QoApôâ“û=é-±Q6ÉQt\nâ¿gÊÈ≠ìçÄ`ƒ$¨ñjr È\ZR,A¿•zÍH1ÌŸ≤c±dá J†á \rÚs/ÕÏµ∞”éhÃê) 4Å)ñAàÈÉ-°c\Zµ§ä¢O†äE¶™`Ì\rÎŸô7®±SJ5d	Hk(Å*ñhòj´˛\\%>JL#ñÄL±∂S\n…|ò©(≥≤ÓΩ”Kjõr‰Î\Zñ¿°ULùûé.{D*|âÖƒtoMXÇS≠p¨ÖxÃú™ãÄ£z√‡\nˆ∏’ƒäà∞ézÉCeZC$\"õ¡(:ÖÑ±π *iøs\'…™2WUs.ZÖz]u\r	éPãúWSäiœñ;n?@n(´rN∂AvÓU£D;Ëh∆‹\0y¢Bx∫\nÒ|®t<£^ÄDQÌ	D]5Öâ⁄”îÙh#jîh»	ê(ñNQWôa¢∞öÇŒÁJßÎyF|\0ybAßîè}î\\ÑÎÁqUg∂\rZ]\0(âöÚvø˜=\0ÜB≈ÑGèìéhù‡πJ\n∫óã∆Û?\"udß˝rdÚGd\"\'ÇÏƒ\ZF∂‡SõD& »N]a‰Li›{Ê”«Ò\"[\'á pYd≤(Úzf\"¿/UÇøbÔó¬ZH\Zrﬁÿ˝N>˝\rJëÉ£Ó˜KÄAír‚tK¶=\\Ó∏á-π;°Ú}≤˛íˆNÈ!˙¯6R¢gtqD<q∫&Åà˚k\"qïä‰°Æ“Es≈	e¿‹_ìä+Âp(:3‹~!HöÔ–PæÉ°∏“%°ò˚kBqsG8îÃn ÊîÙxä$ÏL	~É(©Ú>q˙ÖgÛuﬁMV¡HÔ~>îüLK˚!Y]ÿü≈È–Ó[N_`?-{ 3y—a~qˆ˙≈ª œr˚πÏÛ¸MŒ>∞Û›ˆhø™âµ_≈x˛Ñã\'‹˛ëª≈˝∆~Æﬁ^≥‹Ï‹wL ßG_%–≤ﬂM„ıÍ∑€’∂a“ˆ¢	Ùˇm&5∑\nendstream\nendobj\n16 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 17 0 R\n>>\nendobj\n17 0 obj\n<< /Filter /FlateDecode\n/Length 4245 >>\nstream\nxúùZ=s„F∂ÕÁWt0ÆÚT—|x#ö¢Á—+â2Ii˜Ÿ≥AÄ8pÅ\0\rÄÚìˇÿ∆/tºŸfN0¡+eéﬁπ›çí ÜZóM— –}nﬂsÔ=∑ØtÕ–]ÜO√¶O3`≈˙ïÆ˘ÅŒË”«g`¯lÒ-œaø1ù˝¿~fÏ¯·¢ÓZÍA]3mè∑MÕ1uÊôæÊY&≥ÒÉc0√—t√«Ï·ï°È∫Œ∫üxÏªslÕ4§eiñi±Uƒﬁ~o1WÿÍÅ±üøæ·Î¸Õ?ÿÍ6]ıœÌõöÁÕ‹ÙøÆw÷‹ÜniÆmúû¸.Œ¬dìƒYıÜÎhéÂ7 OsıÛ@¿zÕıù” &ªº‚lgÂéß√0L◊“€i`:|È[g·∞Ù@ÛúOåÔÛ,gúÖ|õT_Bbπ6.x˚HÁ,$6Vƒ≥ºaN∞(fIV≈≈ßrâ\r◊¶ŸAbkñúGNÎ9‰õ%O£úm„,\"íƒ$=1F˙ ∞æÊ{û¸”L5ûi4C~∫pß~˙vC´{oM›Ùªèô&÷ﬁpO?ˆ⁄pFûÂh˚≥Y&V·?ò=ÚqìÌv≥-Ä‘çÅ«bñ›}∆±tÕv÷·µÌ`*Í,i‡xîõ\\á>}ΩõwtÓ∂õºcié„J◊÷w6ûÒŸÜ’ÈB]HŸÚãﬁcD’±∑ÃatıT\n]ùô:Ë¿lXìHŒÄ◊–„>¢áøOè^úÕ§\nhùΩ:@qmXìkŒ@⁄0Ú“Fˆ\"m&UHõ◊Åzl√ödt‘&\nÜ†Í∂ß˘Œ0‘f“.T Ä®á¿6¨…Vg@m\"Ô$T◊˜4À˝B’368U~Ï—™\rs‹@≥}˝º0™£˝$NKyû´ôVµÿ:0∑a´.–|mÑ∫Æb÷„mG<†j˚C÷QurLä™`?™áÍD«˛‡u úº\'áÍyö∫ÉÉõ¸⁄R‚p®˜Ø…vzp€5‡å÷É„t8s‡CEèAÿénjÓy≈¿ÖÖño\n√tZV’Qg#∞;˜®g◊Û4›∑zËhüU0jNå÷Çöz]wn:√ÜÜˇßå\0ˇÒÔ˘U•∂f†™¥Ê‘dÔösàæs◊ˆ4!w ûó÷û⁄û°⁄”\ZTX◊†C¯ùªŒ0®	Û!ÉŒâóÓ§çA\'*TkP◊]É·wÓ:√†&µú4»¥î_àùÓå“ö”u¨µ¶ŒI{‡\0{ÁÆsrÄÌC!Ò\rmäﬁ±≈VX>\rc[Õ¢®4‰R,Ì(∫\Ze≈ÔSŒ÷q<‚lõ,NŸÊ9⁄•¢7\nãOQR—◊î›Ï2Òç°üE+˘˛ÎMRn8{x.6;ÇxÜﬁ2âxƒ¬<c/ÒkÚgøÓbV∆lìóUÒÃx ¬T4:Ùïo”$‰bZ5Ÿ˚7Zc◊ØM\"Ehy0k”òdŸ‚B⁄.kœÁËä´Al‡J3L}·o,Îi˝ƒ˛Epº—y‹4ªe©æBŒ˝Ò’€wKÉ≠K˙k“ﬂﬁﬁ≤„\'TœÛ…Or◊däV1hv1ù\\é„…l~=] e“E´â;U\'•Ü2MÕ6ºz(ƒﬂƒP†ï\Zj¶±ã8Ly¡Ÿ_«ã´ÒH∏ûãv°ttπ·∑E\\í√·Øo˜&¸m®E5ù@ƒO?£D‚Ôﬂéƒ%€eúïyòƒƒ¢M\\Ñò7I&À7IFXŸRkq¢›i#A7hÒ˝‰agIíÜƒ‚Ë÷1≈Ç¶<Lû3ñ†#9zÛXåœ∑º®Ëg≥ø\0ˆΩÇ=·Eûª¬œIˇŒx~Gd%ﬂ∆j8åÇ@)w·Æ(A˝+û˝Œ≥$E®=Q|$∞≤JíYŒ7dã\0µÔ([\\„ÿñ2)´ÒIkGÜœQ\"˜;‚Õ6ç…äÈ’Õ7€&[¬÷€\"ﬂ&q≈ãÑã∏å?|e>(√Ç≤¡—jÃF\"~˝dGúÖ;X^•…}AK:hâÔjé—‰¶÷Äu¡?nêö ÷Á˝◊ëÇHk+∏Åaí&5†2˛?ûˆzKﬁ‹ÈÄÒtÕ◊Öz§ ÙDM\'l¶ól<YL/f´Ò≈¸¡a†–ŸPx˝≥ù©Ã¡≥áœ%h)<¬ P§‹4^c˘∑Ñ+øOì5/‡äß:˜6‹íèÕÆß,˚Òï∫J‘∑|â’Ûü¯∂kyÜnyf7$“ºdØÚs\n¯Ùë+/¬$œûÁ»U\0<pî{,¸éhf]ˆ=aP§£0πG› ˜S)¯ ~€’|œ$¸ÜÊ˚}AÇH-xH·πœ2¨R∆Ø®N+T8¡Ò…x5¢ãï(úTÛ69Ç˛w‡O\"r\0ÀíHÇP\\)∞\Z4Éçﬂ\r⁄Ä™ÄEG·càÁ\r9T¯<‹!¨ì\"Õ{äß£{^[<®s∫–∆æ+ﬁ—_–6má©/¸G≈ìfúÆ~™Ø¸G≈”1W˜äÁ‰Úoó∑ó„¡¬i∂ê’bòÄ∂S¿Õbv5]†˛Ãø˚a∫ök/|”B}wOÃ±¯≤Ã=ä2rêiàFü$Ø6€BÚ≤	æ´ÚM^°ígª¯q0iÉÌª0ƒ?m†!•#÷‹Ùè°.wàÒ%¢∫bÅ£3¥t÷à›ÕÆŸOW?—?˙Õ¬<0m(;6.“çài!A]ÛC°\ZÌâP∞jmZäΩr™K[J˘h<¨iX=¡ìâU}*êgÂIËûÑÚ’a‹û]>lâ=d¬—≠ûÚ±úæªΩæ\0wnSà8ˆﬂlz˝n|=˘ØÈKh‰£µΩ”Ì—hZØìPÛ∞á´’k#Ì}ç&g§£›É>zˇıj1]Nf”Î’|…&≥Î…-æéÅı˙vz7eW≥À¡Eßøñ)´Üÿä9DuÅao¶K|:∆[ÙãÏJª÷ﬁø1xzáïáCí,Lw»°•v@®tÇŒ‰#R^U 5å∑Rπ∆Ÿög·áx$8Jï»a!b[§§\\πö&:ÿ#‹ØkDOcç⁄u¡z(st}œú¯◊]Úà“ßZÙêÅıUóª¿|/\Z/©Céf	-lü–âÉ\r_sÈ:™ÌÙÍ&éíÒ,~à√*yTÎP¡√\0Ç∏ìñ≈UÁHä =@‚fa¬ÂI¶$ç~Ç4\rQX„ÎAÏ®>hﬂé„tègá°»√gY	˝8W”≈D§´9≤pl≤¯£àúÃØfÀŸøÆŸÕ|¡∆7”≈Í∑ûûñÓh.*g?åΩ\\Ê$êõ¥÷Æ7$[»w%\rÚ|Ríæ wqd€jWHmn~5¥¨ñÁ£úZÄK\"‚\0\r¯⁄>pFµX¨=Õ~-øÍÆƒ˘}ìGí3¥Wê”-U^Å®ısQõUÉç´©|üÂíÙ ( ∑É&∏Æ¯ﬁ13ƒRD»ﬁI”≠EÌÀ±X[:„•ì-`ùœ )¿S≠¢nö«ö‹é+hv\r.Mó”%õ/.f◊„≈læ|Q*ßÕﬁS¶rπÿùe)> 3lÙÈ%Àã?	r(óB$˙~ˆ√XÓŒêWê(t˝+D¨ΩDﬂ‘[HYÉÆ∞–“ÎJ¥†ø?ÜÚ%∏Jh{\"∂†%Û2Owï®≥à‘˚rÖîJ‘¢°»ãM\\€–\'∂£=9sß±Kem6ò\'-””,´ßﬂ|§ék!∏(1Âc≤éE t®•±Ié≈∆b9WÇ¯®„’˚7ﬂ2Ô+(tXw¥°B Óäi\r» Nióñ!íÍçKÍûœK√–\\”VIﬁÌ·Âè∑`$ÈãÀÒOîÃæüS‘]LŸÕ¯›ã§*$*ùBÙœ∏OÃΩM∆*vb≈\rt¸ãÂ†}A%ª 8‹aY∏ÃÕ6∫`≈ê#Õ –\\«ØC¶áè»ùroË±}áÄEü93t·…ºø¸ôV…&7dú≤l*\\OwÑ;ûÅhBx#âU$1$„q;ï˚í6}r‚Õ∂H–[s\ZëŒ9:ÁpmÒ=Õ\rTßJªÿG∂<—∏^3¨<>ëEu[Ê`ëu=o‰⁄Ëı‡»Ç%%ˆ\"Ü~á{ƒ^Ì◊@°ƒÖxRIr%JFä!óç;ÏˆÜÁhûŸ”ß~‡˜IöTÒHÑEáq©ƒ‡`‰¢v4—c\"zd	C)=pIÙ9˘=WBD8çl:;lL7J˘µ6⁄◊Âß®ﬂ\\Œ&„	ÑÃ%iÑÕã:XÈ†ÂËür/nZ◊àmç$íNR;‚“Gp52:æî…z\'§¡∑ùdètàˆ§®}Àù>^¢i\Zî∫¶ç–û°wúµª0é:Ä;zKã(¬˚4Â(›¥Q˝V◊˘é±LÕ2Uwi=ÕˆÚèõ’ÏjØ–^Õ„’¸•Ö˘,0å3Ó˘ÂÜ≤ˆ·÷-Ùè⁄Pm‚Ñ≤Äÿã‹¢	·ë‘j¢µoï5.‚hd2·õA«òtíc©<–Wc©\nBîuCøUo±µ¡ºWHSN+™XPãå\"bÒZÙGIπÕ)ë!π§Ò:)SiÆ‰‡}™¢ñnï6o©K¥@˜°u{õP}îjäµ¢kF2±˙î…»m_›’Ω∏Û6Ss}•ü¸æ]õ˘d5æ£¬àÄf„Î’l2ªAΩz	Ö†Eu:Ïùk®$Ê≤ò(å≠Â*d`≤P*Á‰.Hét‘∂µ~⁄S∏q6‰RÙûQ7≥^èÙo	ÉnóéF\"*Ñ 4t”yt-™)jrq¨v§´O‚4//\nŸµà§íZ∑Ù¥\n¸ √\rR…p}Ò.©UΩß!WÈÜ≤U≈8T¬pø¨à£]òàîö™}o—«ÏIí¶˘B¶£˚í\rÌiµˆˇÂ®4•√†ÔÒ¸ûæ∂_—\"çÏƒÚG¸|‚€nÎ|÷S⁄ÆÁw”küíÁ‚Nh¡t∏◊≥qﬂÉÿ2ù”ıÏ\\\nµQ∆≈#óÇàŒîdŸÔÏ=}‡îeâK˚ÛÅ?—é6’¢J*J6ûã1,PB tz6üT¸åS€‚ˆÑ’á4≈TcWâ8¿*ù{‚ﬁ}x–~ë=\"œ6;ˇªromDß9Â9ôƒnnëÔY¢&iÜUoc˜m∏“¡ßa/P´#˙N¡\n¿YπI™§ –@#1ó%Ÿ˙OHƒœ-;E:¿”VqQsO‰`N\r\ZÌ≥™=„∫‘âﬁÍÅËIßKE≤¶í/wåäèÉ∆Ëéf‘m≠mˆËZ§8`Ω„E‘Œ\'œC€(;‹∆‰iÇ‰ÌΩ8@(õj\'VúNp…î˚§êΩ¶$Ù“År}v8dC`i¶ﬁ£ï\n™ó¸ª˝Û˘,W«Fp	’‘àﬁêk˘∏Ê\"ù/ÍG˛ù—@ÒéS≥˘∏Ør“…‘ÉñÔﬂ»ŒQl«Ï–‡ ;$œáBn&ÇÇEH]ÙŸy¬Û4€d\\XvœÎ\0LÑŒ¢Í*‰Ìj~5_-f?Ωh7wy~ˇd{I‚B5ŸUÒSùˆaÿÅÚdˆoËiHT˘ ¢çÀxΩâ}%\0î¿\n˙∂ƒ†S‘ß5Æ∂2ˆ¬Z…±Éˆít≥„J—VƒGJ•©ç5îôdùëˇéﬂb†Z€£\r}EÅ£ã=]]º∑ ﬁS™œƒ§atªiâWhM]ÕQˆÙÃÙO6Q˙ä˝uqıÕdÚçn–õ\0:Á?ŸEÓ6ıo˜uàÜjØ~<ñ£ÎÉ∏n>RaÕbwÜ˛£\Z∑v\nendstream\nendobj\n18 0 obj\n<< /Type /Page\n/MediaBox [0.000 0.000 612.000 792.000]\n/Parent 3 0 R\n/Contents 19 0 R\n>>\nendobj\n19 0 obj\n<< /Filter /FlateDecode\n/Length 15329 >>\nstream\nxú•}Àñ[«ïÂú_qár/\Zé˜√±(ZfE…$ÂnØR\rêHêÇ2AôY%ˇH}äø°=™/––\rzy÷£>{ü»”ñªJ\"7\'ŒcüG\\<qÔ $ˇı	ˇ\r}⁄xÚOÔ¶9∏©∆¥±MÔŒÂ€˚ÙÓﬂß_¸⁄Omë¶wÔßÈ_?;[_ÆﬂoVõÂ~≥õ>Ó◊Ô◊˚ıÂ’zZOõ˝~}≥[-œ∂ÎÈªÂ·j9}‹Ìßıv:,∑ÁªisyÿmØØv”π4≠ˆ9ﬂ\\ÌûNﬂOÀIûﬂØ?,˜ÚœyˆÊÀg”j˜q≥î~”V∆¯ÎvÛß•ÙìèáÎ√$≥Ìnñ´ÕÓr}X¸Ïﬂ¶wˇ,+uŒa•/ﬁùn%ÑE®Q∑bΩøïó”jyÿq‰ÕÂf}∏⁄ÀädŒÕÂ˘˙‚R¶]m˛z9÷”Ú„v≥ZÓê• û7Î˝¥ΩÊä∑”«Â›”ùm~è≠Ô◊ÀK–Á©L1mw”w◊g°ÿSå:ˆ˝Él¸≈´G˜‚Â4\\≈^no·ŸÛ7/>˘ÓŸÁ_-‰1¢D;\\Ÿy™∑è∏Ù¥»›€ßtâ\'É~˛_œ_ )|˝ÊÂó/ﬁ<[L_˝”´ó_<{˛Ú´◊/ﬁNüøêµN˜Ê=]˜ßx,‘ºhŒbß€öû…¸p YIﬂè◊óW◊ÀÌ”€sÉàª≥ÌÊ√rZ˛r˙ˆ≥Â∑?õÆK2›Õ˙ªW◊€›cd--,J»XHX∏êÓ/dµª|ø€_ÛMóÀ´Î˝rª&? ¡^â,ÏÂPÖ+ŒÆÂ?¬AÀsa!yJŒ˙ À€ﬂà®Ï∞Îøπÿ»±Ô¶?^Ø¡f¸ï’æ_ûÌÖ√§«Ødg≤è’µ¥Ï1Ã£;®nQrWR÷˛\0ìo.>^À∫váß≤à˝zı˛ÖÖ_ä¶ù∞Ë{ë©s4ﬂ¨˜ëmì.ÏÒz{%ù∞»’Nƒ˚qwyæº€˙bΩ+YÔÂN@ddª≥S˚Ò\0©öñ\"{•Gwí€BCw““g±>¨ˆõ+Í™	Ã|.3/o68s*vŸ\rEÇ-ãåQ¬q\"nr? éæ˚·l≥]cÖÆq kŸ˝JÏèÚi/Z·‚l√ßŒwrÄ€çÍÚ£·BN{˚Ë>RY‘–ÓãÍ~w∂{z™h÷gÀΩˆÓdÊÔp@§˜Ú˝z%jıÑ“Pñﬂ~∂ñ\\Ô/6Wõ˝S(‡Y)H†™ü–Z8Â«È˝èáÕJèeåı˜kãËŒ=ñTÚ\'µ≈€_|Û˙s—/_?ˇÊÀØ_Ω¸ÚÂã◊Ôæz:˝Ó≈ÎÁˆazˆ˙›ÀÁ/øÜË˛~zÛ‚ÌÛóo_˛˜Îü†Bb≠/ˆÈ·e›R!jJ>ÓŒEøû‹ÄÎÖ\"\"hr¨óÁÀ5^è©ÔóäNÊzπ?Ÿ«ÌÚO∑¥ˇl>l®ä®¡6óÎÛÕÚÍ![ÒTx@Ã¬•úﬁa≠\0NæÇÃ	˜.ÒΩpààËmÌ74ﬁ˘˙k™iåÛø°1\\]∏Êl3˛ÅÕÏ&®^!ÃAÿrsæ<9ëï÷´Î´Õçœ∑ü]Ïˆ2ÛPU\"˙∂R±kó–(ó◊Îõ5{yπZo©·Î◊*â´›ŸzE:-/ƒÆ.áë√9_>ù>Ïó|V∆ª<õ/€MÓYxÑ\Z‹/|è˜w±;¨gôpO9\ru¢¬µúL3˚Øó&≤ê)·!Óˇg≠ñbx¥Ì–At–_∂ø2Å˝n˘˝„€hq·SˆÄ\Zˇ∏ﬂ…4PÃK2¨í¬°Ènu\r>÷œÔó€√ıÌgÔeÍÕ•|)¸y¢dvB⁄ß‘|\ZúöNYTªcs›FïChÒæÓ;`∏ÎÚ√-ä∏˜Ω(ÆÉH…˛\n\ZôS_mÆÆ7˚.ı4£Ñcë>Ü£.Uc“‰C-{›Æ?l[•áb79íø[ÁÂúEßT=ç<ê„:Ô›ã7œâêDπΩyÒ≈3GØDﬂ˝Ê?ˇÊ’OF1.J-üò¯≠f»qRÃ!õ^]Ìnëv\r …ØÆ˜¢j¶/óóZ^n∂0\"∏˛\0Dëî[<z¶).≤Û*a®ÌÓöhÓÖ=7Î+8OOPªë‡[—∂?.)|Gò£XÏ©<y∆Ö˚;?û€‚‘;_Ø∂2î0«js∂Ÿì}íA}Ôó-19ñ˚LyX^mÔó´ô|≠º&t9ﬂ´ù‚8êŒ[·$aQàﬂÀó/ˇ~fÚzÉ\Z*|íôûÛÏÕ;·•œüΩ˚ÍÌÙıã7oøz˝Ï’ã∑?ÖèºQÃüòÛΩ(”rÄæ;àVŸr√˜5dö]∂}†¢S¸øóråj;?‚T∂èÅããñ\r€ïˆÄµ^û_0\\§2+Q8[SÂé˝⁄ÑZg-⁄¡màN$Ñﬁ‚¶¡MÛEÛéRêΩsµW7SxjΩ≤ô€HÍ~—⁄‡Ó)·(Õ—\'∏g#“π‹œûÎﬂfüTÀ¬W:1ßO≤œoøy˘öÏÛ’ó±^Ω˙˝Ù˙´w/˝Úπ˘n?Öì2™~b˙€út™ªˇœrªºTò<CÁÉ≤»Ó«ΩúÑâØ¿Ñ´SWÙYëœ÷èz\n©§Ep¶%„C∆Ú∂¨.¶Á˜ë˝å—Xƒ^ m˜öVí˚’Dßm/ÖóÉË∆áÂS™ã;€Ä1ö’≈LÄG7ìÉ∫øœQ–â¢M˜¬‘¬6√h£ΩÜo∞˚	Lã¸ÕÊ[ÂO¥∑/˛xË˘WØﬂäI®˝˜”Ø_ä–ˇˆ	]˚ââo±œmÖ#ˆHË	sCˇ@]ı“˚ç‡ù=√&Ç\'œÂ,≈Ä-!¸ª¢1ÚœÂ˛á+ëÆßÕßêy∏Ã!<∞¶Áœﬁ—à»Q?,Ô^çpê.:Û¬_? ?>(∞ΩÉŸø\'VC≈µ+Ú•™¢R¢7\0˝)JK;˝´Äﬂ˜“U<á´%,Ë˘£z5y˘€GàÀ?†WWÀè@⁄ÁK„…ÉËÿı≈—á^L_ì≈î—üöv◊ı÷ä9º^]iåÏZ§XPì!-YÒ\Zû‰ÄBz¨˛*ãWjÍ\\#ÚËúËôáºÂSÚ÷[Dî(7”«ñ}∏àŸ?‚π˛◊◊¬ÍBäW/æx˘ˆï(Àˇ~-<ˇœﬂºy˘ˆÛóœüˇ45@†KˇƒÙ∑Xˇkµú¢¯D‘Ö∞WÉ¡àÿG§Ë>c›FÀ1ÖrTZèz~±ÜEn¨w πÌ˙{Û˝˙|Ωßõ°Ûaÿ∞EﬂÄ˜”ó‚‰\núì˝\'!©∞\'åˆ|ÊÉÁj™òõüon6€È◊:ÒˇÙj˝˝‹∏é≈-˙`S|¿É˝˙hœe¥Á‚ª^ã–Ìˆˇ9†¿Æ˜õÉXõ’âyæ⁄oŒÆ’xñÇ¶¶{N—ÛÛùåË¯∏à†¡+ø„[â¿_ãzÇÙ?∫ç‘≈ˇN\Z|π=‡Û]Cœ-OBoÎ=ñ¡‹/ˇ§K˘ò\rÕd“	˜˘˝µæúÄK˛p\rTKna¿˚hönuçË√ﬂt1÷ÖSıÂW–7◊{A¸«„<=Ñ£\0ˇÒ	1õd¸->4\Z\'ûë\0ÿúß’≈Å≤ßΩﬂüü6ß•´ª◊Sd”Oˇ>πIv4˝Af~∞À/æxß¸M¯˚«Y CG∑\"÷‚Õ˜∫˘”°sk.⁄r.¶cSÕÇWö∏ye—ã€èK <.¢æ∆ﬂ’ì˘Î9?ygÒyı$àU+.Ã-^∏´î„\\Ω|ãßSƒÖã}^ÉXí”%éèÉ¶O¨aLcOèYlt˚#Ω≠›∫çßÓåjWOÓÃ:÷dOè5œ£è=Õ{¥=ﬂ•¡qıoü¸ˆÔ=Ãxzñ5‹;À—TΩÄPYúHDieJ…S)•dÌq˛+Ñ∂oFœ˘…;Éèœ8ÀFO{¥¯,˚	«º´≤Ôz2GÆã(™dL⁄≠5Üª‰É^c>=¶√èørúc⁄q<wg‹–Ê„º5ÔL\0[§≠˙8¸ºØyöpg}wπÒ<œ$,tÁ<Á¶Ïeurn5-ZïÛt≤JŸCäçk¸ïÛﬂXœ˘…;ÉèœBÓ‘‘ô≤ﬂeÁ≤Ø1Ç/~ëƒ°9Œ·CHëÊUxón≠r˛|îOksç∆\\céÒWûﬂXœ˘…;cèœrÆwfüW7VkÎ?Œ1ÔpÏÿ(pó\"ˇ–…˙E>=€vˇlGfÎY«ºË‚√äœ∏pnë¬¸Wv8æ=«ìwüÂlAwÏÑ&›GEåcm\'s¯òòMs	Äºµ ˘ÛÒl≠eÃ5Fsç9∆_Y’¯fÙOﬁ{|ñùﬂù}¨ŒFÎ?Œ1v8ÔxP‡E˛ˆŸ>`yO-*B®CÌã&V·‚IçÚ«Ü$Lµ}\"\\≈ ø\\{ó1 æ£J\0≤4¿R¨@è.:G\Z*Y\r%<‚ÈNÈŸ≈Ül°S[)åÑ4aj6$(◊9aZ˘GÑ‡‚Ô1Îπ…Jãp={§2´4ÆG\ZDä/ pOÁ#M<ó¿Üù6¿!\nY÷∞!x∞22_E«Ëã⁄∞0ô.ß»,4D9£ÃisEŸeÑ‰—0h*ˇ“≥V<RÂX≥.›{!·Ù›ì&Z}Ñ\"àü^†Oó@x{‡Cr\"¬3!â˘$QYYRàHòëDYI\rüä“Ã%«ÿv>“∫ê(TnB\Z˙¬7U˛>{#ë/ÑÇµ&iêÖ5Ò∑Ç®ó1hrÓò6â?\0öµºpUçô≥q7¬kN˙8peì›»(bä§!Ò/∆®¯^(\"qÛD¸7ó£≤wqS∑7~¨-…˜]∆nhê’t,KtY(Ëªl ‡lª–\'ÿZO≤N»≠ú>˘TÊh\r\rJH›Zäz8ñejHÍ~¨2Ù\r(^®<d¨LÚ—ÀfÇ\0ßVæfë≈\"‹I#*ô\rUl0÷–Ñø+\ZÑiQÃ±«…˚Ã`öÙ(ƒ¯à·Ñ^tï‡MúH‚#Bã*x´ÛàÑç◊)_ê≠Öœ$¡À¡Î©¶éÜF„/=§k:å\rÄ¢ÄÑjB†©ä◊}$TMÙ©G(…Jb™ŸR9OYI”Ã‡˘™§„«Œâê∂=O/åvánÑED(NTàÁZ√ãƒgg‰O&%µÒ\0}ÛXC…ïcÑûë\Z$ƒ%X—K°%Ú()ﬂ«¿5ÑÇBÜÈÒΩ´¯^h–ú/zä¸∂Ê9~\"OBÂ˙Œ˘QÏæñ˝•¨€∆êO:-f\\¯≥Û<—CTåÔ $‹ûˆ`&j6,€Kël·Ka?ö9—ÎÚàÁ1noàÆ∑K◊T9çc§ÿCM∫¨Úê1ç®⁄@1ÌÄ≤T—ôZà=?àﬁ,+Û¬¶!Aà§PÅxp<ç¢∫UZÇ¨E‘≠/≤üŸGËãıãöÀ°≤≈Sg`u¢„FRî‹£Qr@Ω`Q›RëIÒPïøô-¢\rÖI@áŒÖ prñπbÓÀ*€œî/á€`9õ¬bÓPè™#DGÉù≈D}Ñ}XqYê”]Hü–î§ÅbÂÖ[ÅUñ]8›)Ïµ,1Ä9[¬ﬁÖb‚£Á“ÿÜñ˘Efœßí¨(&ˆÒi|W¿%8-⁄?#õÌ^º∑>\réSÇ§jËTPúSÁ\nAvùÈõ≈Íÿí)ê‚∆ã–pÖ–ı≤qÙe‰l„àÈëÑˆãQhSW‰™\'Ö*™O‚6•áÿ±z¿¿™@Äw\"Cb—c s¬)»VxI|<GÉ,}<¨˜&ÁêeL°Ü!Ï[ÒØæÚô≠^—G¥m–\')ıa‡‰Ù:∫p˚≤•(Sâ8+£¡ìΩ†ßöN\rÕÜAÑt ¨≤‡$ÉàÆ.!⁄ÍúÏ©CÌ\'¢\0∫Å §D…î«,PmãÄﬁ¢ÕSÂ ÄJÑCõÍ#BÈ‹NUÒºÑ∞ΩG\\ô&å\"_P/(ÈDYÙ®}Ñ≈IrX∏Ë°Cü	≈E‘Âë©£8#£GBÀz\"B”9âRãCcàtÑ(°ÌÉxá»7	ã0U∞åUÇ∂áíŒ≤xô°g3gï„#¯äÔ3±èÏ6Sßã’Ë\rV<€Ûê!†J\0Ÿ\r2ßÚ1	Ñ¬˜û	ïX±æJ√‹\"U÷\'=Ö;ÑﬁA≈^‘¨›è∞o(¥KE–ä<–,3Ïÿ8C‰⁄∏ÀÛ¿∞b˛=Rµb“3u=µµ,Æ/MÉg—dü¬U~èì/0H®bA¬V¢«ÑJÌ\nkDo °˜÷å†>£>MlQ#AL˚˜‹∞,ﬂãM\"àDè$¥¨8€»#ì©T\0rÜBCS†-+gH,bë‚S0ÖÃD¸öπ`]ŒPìz¡¡Ç§ﬂ°∑\\e\Zr·Q·πy~/g ◊¢∂à8À„c\rëÛ;J\rJƒÄJA9∫Z»7\\ó-£\n†ê<©™PPmRñ·¯à*É$0Ö‰0Û=Ãdëi1\"è¯û\Z*É©†pÒ=T W A|e‰I„®<ÊÑ%Â Ìy€Ì°\ZØ+4É0‹:øS\rL3¶;Rƒ¬âX_r∏l}B5‡¿ñDÕEó–8à:ÜY+”#œYv≠é®:M\n\ZÑ∏=(Åê\nÉ±Y;n–\0†…p\Z8(lÑ¨ÿù™2$≈âÌú%ÇΩ´ìΩr–s@nâp8û¿%»\"q¬¿1Í¥^9^v@√†(/í≈˝XXìY*îC≥,$Í∏È:ƒÑä\Z!∞r6mk Êç{/¢C≤Ö\r©\'·ø\nD¡©˜ŒÕe(_·ïH¡n%À”wCCRŒÎƒkTâE¶\0ÖÊaº‡ùíÉªàÃ·{!zY@µµº\rdÆôAúS6äåí\r¿»b[˝∫ ÍHúekh	!e≥æp˘<K0Ñ«#¿Í\nó=D#%9ŸMÃÉh«S”–@pS§$´ëì…(Ó∑€~Âõ∆˝¢AŒ@ÜıƒA¯˘4–í†|üT£m˘H…gp(èÜä¿çxë tt—ÑÜDÃ}§•Œœ\0\Zl–\0˜…/¢™©ÁU˙w÷P∑ó¥A|GEóh—Ä@‚YM^Ug)pé£¯ºH+◊J:Da^X[¿„˝¡ºb⁄™ßT≈•É≤gÚæ/CÍ†ù–Ωã©GEµkN.BQ\"àL…tÿè0K¢ÁÍ‚†+æè ;b€=üEPÑD¬BÖ(Ã&»	–à⁄9\n+bâ\n∂~èÙ•ê≠‰ƒÁA6ÿU4Œù˝ﬂI†tD\nÄì!«í4\0Í†Îî^ÖS}T9b5ir`µÛ{±±»z¿Ú	I1\\Euì∞çÁípÑà£äd!XáK“Åt,H&˙∑R`Ú\"C<£ã√`D,í.í	(3 yÑIÕƒÇ\"e@èÁå#ë·∑åRå®ôƒï¯5›Ÿ?I\"j∑t¬4¿Z!âhj¬«ùk\"â:ÓÅLªBk8S¥ _§Såä®˘æS˜5\05– ÅΩµHvEÛÈ›ë€{„Û–«ö:∆NÜ(◊¡2°„\0èEÀ√ﬂ∂ ‡â,\Z™!Î¿˘êE√Ê Ù≤ôH+Émyÿz·6˙ã0‡ Xdàî\0ø;zﬂ[ÜZì\n@ßl\'@@a0·ÑìõÕø#‚JN∑\0Ú\"·oM8àÆÎ˜ËIâ„èΩ…˛Ä˝uß)“⁄‚zÅûDE˜& ßï‚0‘O∏∆ƒ≈–IL@EoˆÅÇI¬∂•ê*µcÉÍßíJA}<0ùZ˘ñç¿\n5}äÅ0`ù¯>â4˙¬9∞A<ïN\'!3k¢£\nÑgE!º“·/\n•\0pòâ&√‡∫å${B®ë>K£&nQ£éå®îP2+TÑc@ù=7Ï„7ÃO¬[¢É=Çã&LÑH°òËQQ–Åtx$J◊Üs$ˆaI\"Â‘a\\Ò9¿∑\\ôBëS‡@Ω¨ŸÖà1‡◊Â¿]UrN‰â&á®7NƒUÆ#0gO\Z¥¬∫*|cx÷5≥G#®É\'}\'TÕ\\±[ü,6öËw“∞”_M¢ñ°Ïù`„\0g!qÌ[≥qBTœ<A4S zÒ°pï∫~œñêãàuÈ~r‰Iàf0á·;Cÿ\"#hÅ”$®MHî√€uÖÊú‘òƒv,çc@ê¯ﬁÛ¨œ@°9\n\0‡CP·∞Å%ºÏ’∏!êœ‡¬°ˆ¨RR©gSÒÓ8]ƒ–˝ÌDŒÏ1q1Èÿ)Tùq¶<Œ7Í¬¿ô>\'Fpè“πP°–øw\Z∑«2π¢–&8≠Û=€Ì¡ñ±⁄+DƒR\09\"Æ8çBÿ#‹®„‡>%˚‡zÑØ¢ûrQû@¸ƒEärâå‘\"ZÄ-w<\n.√~\n2X›h «¶kƒJ\Z£\"\Z[Lr\0∞¸àn¿É√\Zë%Ã¡h\\;¡’\0?»ôFómg∞ûÚŸÇ} ⁄„,™ñ·K#Fî¡ıï-ûn5\"KçË,ıN∂‡z®∆êvkn”	<–˛\0”†ˆÉË\\Q=’åfB)\r&Qå\0&7DEOâdƒ—F®5âµ!e`{∞›#mÏy‚L¯J0‚Àú£	N%ûÿ\\˜\Z4Æ&v≥”èeÒ1[ƒc÷0bS5GM%‡°´úôI$u≈À™÷e˜±&F˙úo6¬1>?})<U!™™›–‚\'@ÿ$V•4Óâ·◊8˜AôoéÆ*)‘;AFi\nq≈¢¥^ÈÅM‰Óa=z‰0è·+üÀL!‚“Ç“®–b1nMi»àøâ≈Éã≠º/¨F\Zªr27éZëâR5ˇÖST«5Õd∂§·í§gaw◊”´R\r1C\r≥{Øi3\r»^Ñ˙:1—ıùV6{\rî Áê¢∂Ë:ê9ˆ¿ÓﬂˇcF°®C=Æaπ∂ƒÿî©õs\"‘Æô∂1›∆l åΩzñ–¿–Q∞‘Ÿb√bë»NX-•ÒÌ*k¶÷÷ \\ãå\\¥„Ö6ãTã‰$h&\rÂÒ,◊ó¸àÅ#Ó	›^ì>%∂$°O2/ïqÚbOEÆô∂)“\n˙Æëÿ¢\Z[ÙY’]ÑHŸNå\"è]¥¨sÂ4‚Ÿ#ÃE\rù√´Ó‘¸’bﬁëˆá≈⁄\\3häî† =coXraP·Õÿ‘RRÙ»$LiŒ÷Yé¢í∫wáô*πÇ+Ü@Ü∫2lè%B	ÏS5&z€rî p∞Pπì#‚›\Z’Ü&äyƒƒÔhMßˆ…’jqíF¿Qûà¸∑hãíCÚdƒäûü&&°-]◊>ï“ôp%«„D≈C‚öùÂ9=ÚÑZı∆=–3∞/©\rÓ)‚9¿æDå§w `m:´‡ÑŒŸ¢È2ÿ`ú)≥Då§G›Iü#ŒT∏XMëä|n¢i=ÜÑñGlÇéÕ‘’öücW‘pÁƒ3≈J-∫≠π+\\[¡ÎÃ°j|“9+áŒKXoîäóá∂ò©Hó¨7B„„$ΩU‚0™å∏r–˜ƒπK¬ˆ\"€éB#prXôƒ≤iYh?`Öo§uRO0|JhVÕª2˚íïv—2,ùûsB∏Oe-¬}Ù)ösëıyû2-#}Ä@NJìØ^0“±¿=Q«ANßnÚ#l_‚BôHOü’ìì≥◊»`9:À‡ú§π3¡≠Xx=\"K#hıôT+?c◊7<7ƒäq˙@£w˘>”ÅΩQb`Ö/xJ’*Â4ºÇttNÖàπ$zzDD6ì:úh·j2àâ˜qú≠VﬂêÄfÆ•”~£\n1Zå7_8â}X6Y=´ñÑjÅ~3$–°»\rgìD£#bp@Ô\\U<ã‘àyê0Dp5œUIpπ®Z∂—£$°“7©ƒ¡gÆ∫\'GÂ∆¨	œ†—m5‰-Úçë=ÁBﬁë.pöRCaë	$£iò0dFiW)+VËëbbL	SY7⁄w≠ê>®‚¢ﬂ\n\rõõEWv’¸ê{H3™ÇàúÄ™ÑºeWà%òÌ}b¥,«‰ÑzbB$ßZBeZ‘ñdh∆Ë¨%õ|kã7$â≥–ƒµG˙¶\"(ñFF≤∆`3®Çπ%˜Ãë„*#˛Ö“£ÈŒ™Fc·É	∑Á‰â◊4tåÀò–Jj”ˆF=@ÜØò5i	3æ—Ä≥HßhÈ¨ûAK¶˜êô˜”†¥£Æ«Sﬁkã◊ëS6dçHv¬Sà}¶nÎ…8\r—#j@€o¬K8√d±¸ Í!TTzÕ‚Dœ˜∏`Ôé“¢ìË\\F!ÿ5T“¬\nT  Ã∆∏1n‘dk¢ à Uµ,à¡Õ•P∂-HÙaÙ\Z5æ\\YRƒû>Zç\"ÍPìbÚùŸ?§{‡∏é§ÜlGç +∂][<´Ã<·∆hÙk#¯PÙU∆U6¡Z¸å=ÇÍÃø∞≥çq(¢4c\"6=Cv?c•â.0gçöÕV\njÄoZ,∂ª\nKïîo,Ô&WâE<†ëÎ	⁄åJçÑœÿuµ–ê‰í0&t>¯ºSõ14NùÙÖpÜük2\n#ef‰wÁ@√,Âá‡πŒÈ_äùíÛú8=öR(z´b¿]N-âR)Kã2∂îä®ËÇfû&®à$à ∂Æµá®ª°’\r\0z…Z‡?¿Gr:ÜÍwÏW,)_âü˘Dß\'l=(\rûﬁnËZ±™FV\0aT 8qt÷u‡4#Råå¬3Ñ>Atõ‹°gˆãz£D\ZâÜS)Ïº£Vúó<—?Â˜Œ< Zxæy*–I€Dﬁ“WND$¿QÄï±ÚUÄ%\ZÖÄÑÿÇ2&ú?Î˚Å$ïg*1`F2\n~—Ÿd<\Zv§5]âÔå—{´-ÔDB¬„Ç√D~ìE·Å. %àT#åè8•ÜπÚàì¶÷±‹\0∞l“1º&ŒLî=—?>Û~2Y‰¯»»V§¸¬˙ ÿè<xFq•”1P‡∏?—ﬂ“#”ãÕV`°+U=íÊÑÇ^´W‘†áàúCJ·6=4ç¥_Ÿß∆ø·eı»^AÛPH5d]—$¥[ÜE†ûô(åâ+Ça=}∆»–vS;D˚ÖJy‰zYOã‡{vj	|—q*√∆¥1ƒh	‘9ôïFŸ—sBK nåDâU˘îﬁ2J@FòÀ9›E$ö«»ΩibÖYud-E÷A-⁄5ráΩ¬˙cÏ¿ PdR¿∑î˙WëU_ùÏk∂ƒBßOMXâ•\"J—`?c•T≈™eÇê?d‰ƒöæºãñIÊämÿ<ƒΩxÍM}2¥8—kºxk/ü+Â°~Tù`ƒ4#3û˙Wµ8ZòÆñu†BO4jπŒ®öé·ÉjuâEFÊ3•¯˛Ü)èçK {¬J°wÒÿÌÜ˚oU«àº	rõÃAÄ^hCI®C¸&QK jQÇí5ÚØE)?ºarq¢èÖ¢£¶ \"§™å‚1Ö=e1	<ã1\n„Yµ%“*≠Xè*±ZUê´oå◊¿oÛÙ¶êÅ@Ïé“—d	<»@fI÷é(∞r¡-\nÏÆYü-~çsÂM##‚Su≈0\"‹¥ åã¯È.ÖH5†»,Àx ≥à≠G˙îb¡Y±òW\'c¢Y‘¥áÆ2[)àØ7‚‰¬•µ@ˆ!◊!r}ùµùÔ2√˙™fb°[@…êè#äØô)TˆAsô˝√i ª[îN^#OxRìXÓ§˛oÚ</ƒ“Å˚Qö%£\'ƒ8R‚Èÿô#Î√ÎRâôåIœÖ6-⁄â6RŒ©\'Ñu\0Ö£pÜEB‡¢\n¥`∆ê2«HÃâbåä˚1HXjÏY$Ï`°4¬È=Îb·ùi01gìËèR”X¸ü^¢+çô©ÑƒY•áÜS@îâEZ‹#4‚-≤jq+ ˙ƒ2¨hî1a&¥3÷øJ˘öât¯Å]ÔÌ$≠ƒé\nÒZP4«\0∞ZhXî\"4Mÿ_0oÇàºV≠öMƒÛÍC;Ú!O¶r”S#ZÌÙòÉû	ºÉÍ4ÇÇ≤qå	4\"qÙŸ·\ZƒJ†Ω0o!“CK≤;g‡cfh‡˚3ëø\n2dÅ¥÷*‰-*o-çÿP†ˇ∆µ≥BYFí∏í§+K OA%hº*«5‹qA·jP˛\\…µ8ü®ö©1˘‰ÿC£€}dßp∆]+R—D§¢√¢iP¯#)Ô†¸	\'â§ﬂ^ÙÃ´jπ™9∏\0zQÙköØT¨¬\\<Ï;ßy√»9,úÊÈ∫/qØŸ“õAwÅ\\\0∆G‘ÓÜ=\"[2ıˆo\Z\'`ÚÇHS÷ÿ£‡v“ª0cr√LÙ:‚|xÜ±#NÑ•!à˜±„\Zn!ôÓÁ},ÓØ@G %YsÙÄ/œÚCéäy£ÊÏA+R\"jqˇ\rÛ4¿æ…2„$ºÖÈ3ª—<æa±Êöêõı<µµ%1ÆÄ>ïÁ5Æi∫X	≤Zç-à≤‡#∞‰Ã+?#Ú^ÄÏé;y†]“H(z¿\ZﬁÌ‰œí!úCb•=‰eÖîßonÅÕìßW¬HtR—Í1∆4ÉJ†ßm¢ÁÂ§^52†Qœø”+A#¸ÙˆuáªO¿∆Qod÷l7“(TÕ‰tÍEû-{gŒ¢Ú¥†’y_òÜE=›hÑ\"¨£\"Gä”AÏ¨2ÌïÆMÙ?• Ël∞®!ËyFJ8¨\\·yzV›√⁄8ƒﬂc†«zÛDÌOÂ 2≠)*OWÎK≤WªCœÃõ\'&«<	¨å˜¡b#ºKïΩŒxQVŸCúW∆˛+A≥]é:xOÀˇ‡È!ç∫\r≠Pá74?+;h™÷QÛoÖBÿ≠P5ÛöXdõü‚8∞ê≤©dÕu¡´-Öe%ÖÖÉåpC>‹∏Aø9ÈΩ»Z5á*hwDëÔ‘Kd»≈\nç#≤¥ö!£ˇåF\0˘®µ…‘äÅ(S#Ô@ƒª#9±,–OdÃó∫19î)5«z>ıjA”∆’\r«\0í¬K’´/,	C9Ofl>Ûå\"ØÅ#¸[yˇº∞xYz\0ÔV«‹æ`§	±ì⁄òﬂº·mﬁ÷Ù,ªSyW‡a‰ºtåÜàNíı]é±L|÷ÿ\rqQ,_º‚ÚSz‹¸„πæ¢„—\'#_N\r]“»√„m ™»(#/ÌuåPßEïÃö8úy∆\nQ¡¢‡êpE}{\0œ±°–UC^„@ÙQQ∂gˇ‡ﬁ¬ΩÊ,dÑ/ˆé≈“u¿ı-Yµﬁ(ÑcÜTnÓeΩAòL‚ˆ£˜⁄bôxΩå-∏;áßjµÅV“lÈ»¢O‰ç+Ù	Ã£®‘È»Qâƒé¡˝ˇ$aod°˛!0kw¡B‘d-ìE’F¥ã.Ç3Ô§Xq\Z≤)®^øqŸâöO/	: }\n; K√ë©çp11À™MAYı”ïD£Ec!àÒiºyS4bZ#KàHéÕÓItHº+∫BçI¢\ZPsCà‡ËÒMÂSZ^Ëà°îß\"º*dÇÄõõ∂Õo°TQ„»•Î8∞-}Œ–OqvÂïÚOsÏΩs=Jo‰8#Ì±dcdK‡	!Œ·5Àö¥∂ZˆfLé\\ï“∞ë∂v;„ào—“H)DºÌ∆.`°>éÊ˙pñU+\r|÷søÕ-\Zçå~‡ÜçE±!&‡‘!ZF≈Î’`⁄`;Î]XØB¨Û˚d+ÍsÜÕªìãºﬁF&ˇiKV.ãÙÓFÓÆ≤•Ìëù¿é\"nËf]èäµc—[	Z1Ø)◊„ní≥7WYT≤iñ>∂¡ıæŒy{ÂËËı.h‚%∂‡∂\03˘Ÿj∞\"x€:28ê\'ﬂLUÄ+≥Éb»⁄RI1æ∂C[†¥ºæü@ÂíıPgq(Vªad‹—ëìÚ[Ë\ZÉ‹“ÛO1˛]GÔ&Í8Q˘g™}P7.KyÃéL9ﬂ 1∏52?ÔX·ì¨≈Ût<„ıCû G»c.ã§9*åj˘SSæSYeéjÆµT∞Œ_\"jã”VôÎS:6¢ëçOâ’[çõ≤%[}¥◊àHôµ€á7z0\Zá>àÑπÑÙb˜™πb)™IYQ°\Zßj%d◊∫´-£bçµD’t\"©»Îƒ¡Œá⁄6Íc„îu‡√¨%ëg`K5Æ““◊˚T£cMœ–µ°ı™xßN”∏W•˙ôÔ≤^oÆ˙&†-£1<y÷Ù]]∆Î∆/ùÁÀ7§—Ç¨#r*©x*NÛ»|˜™l„‡˙í’®«>V9B9Ÿ\\éﬂ!÷öé;Ö‰hñü—Í÷@I≈¢jRèûÎ∏±õ3 +•Ä\0’Ñ3Fô‘ä®§B´DJs\Zë‚öÌ˝}ú;*4†P\'f¸£òŸlè…%tAR˛âùÁçj\'”@¨⁄TãUÍ‡g¨ÉQ$} uZYû§éÏîì √NeÁT¥èÚ!¨‰öï÷ihˇÍtdµª°ÍMPFöÊõ/.jÖV4[µ8KGÜgóLˇ©ˆEåü;zIÌÎ5äájß.ÅÜ.:é¿ ÿéD,ØV∂ö/‡á˜Z1Üs≥ıòﬂ9Sd†WËÙLïŒºVÿo[-S◊µÇ7F¶‹+G°R®õIC@eáñ\'©Üvfãu£˘fÂ\ZÎΩq∂fØË8ªM2p\0Ì√óY!Åëycr¥ﬂ∏ÅT†„ÇS‡“áö§9ì\\÷L¬¢÷qÕ\0v8µ∫}^!eπ≥W–z¥√|ıÑ∂Djø¿‹í∂V∞iF∆7–-àJù´È®b‹úÊ‰√åfkÔùæÊ†[M|c˜≤∑ºwJÈ≤i	^ß„ı>GÎ´ı–~ò3\Zˇ(v¿∫T.¯N\rÙA›àq¶Á=„^⁄“˝a¨÷\0∑wú⁄ã^Ü\\Äèynf”n[+Z0Xì†c;ENuXåqÚ∏¿∆∫ôVÕﬁE“Uù-ÈÀÂÅjÙúAa›k7.„õ>äR({mQt∆◊`Ë\\∞&ﬁªµËı\'JëŒŒÎ®jgÏnü≥◊_≈hÓ	lO,∂˘ú≥:GiÊ_ÿj \\#2D®ú¯:Ó¡AÙ  @3ó’µ6}QH®Õ–É7ˇ%¥fˆ [å\ru%Õ-E≥Ûc.’`–ï˛à~!Ö~¯8ò˜òôœ¨c=Ù8C1Øk¶MCïÅÓUINmë·j»Å∑wö.Qt¡ÙÉ™ºëÜtÙAyËQÿEñÅµGN„7&eFç¶°q_%™∂S;£ïK–à¡l/ÖVEü∆≠IÁÄET\0ùùŸR\rBØGØ\ZZu	∏û>∞´Æ–§Üæ†µtb¥áw≥N^}J≈Ÿ=Zµ±∏,hOŒ\ZO√\\YmZ®fy‚∞®1RO$£”ñYfbqÔ÷C~6´U1Ñh÷`ô’:≈lQdg(Ò\'ˆº™ÅÕæd¢\\ÒZtø◊<g◊qöæVÖYLkQ>fN6ƒ™æWŒ∞\"y£îÔ‘[∆∫Try´\nÁéµ+ﬁÅg‘sTèxù¸É\Z\nCI∆á¯°√Éù:Ù6îÑ⁄kØmx÷:b¥ÀÓ⁄BÃÿ∑‡)Íç644Ò\0-œ‡gΩmÖñ°≥Y√]4Ã¢˙\'Ò51éØn ∂Bò‰d÷)ÒÊÖ¢Z˚8’√®3,å(3ûäc89jí0c+X¯¨∫Œ–Úœ]mëRgJœ⁄{≥Ñêœîø{π(Ø√)}‡$ØÔ——f¥E√b\0˝æ—§5P¡€º∞¶<ﬂi7=kõ¥%Q±\"O[º‚wË<„1ƒYÉ∂òMÎﬁ¸4g“t◊6—^y’iÅo-qV—GÑÅ8G: πÒ\")mi™≈ë±Ì£•ÿ´ç¬<£qDkÇ›Á1ÕÅ;ºEÁ2åXÏ›`®–>@’fy¢yÒâ|ÇìœnË-∆9ÕJ£ßÅ»Cû1+y*5Ûë—B˚ô˝º/ıc‡ΩD?ZoAµñ·VÔ™˜lÔë>\n˙òç≠™]‡´\Z>n\Z—fıëÍlTÊUı–YFã“`’ŒYgÖ˝T{ôeD%è¯QÂ Õ—	≠⁄}ÃgGÂCW™∂0Zà‚<W–7r‡t,/¡^;4¥˙Í®|±ıuÉyÇ™◊a\n ∫ØfºaíÅ;…∏•éÓ\"T„hæ_+Ãæ7+∆¥EQ\0lÎôÕ™¿?∑ãE‡ä’˙ƒ—¢Zaƒ€ÿ¬ıxC{¨\n:ó≥ñHÏ\0]2ÏL7ˇºç\Z∑dZ!Üq®2ˇ‹,aP\r‰múâåu∞ËM-ô‹Ãììÿg f†∆->¥ÂõùÈ˛±Ê¬s¬7Ω˙¢í·AìÂ2∆A}7≠ Ω·!1Wë˚†s’¯(ÕÓ\ZÉGa>s0õ6˚®®¨÷“GK7è›Vå«ßÊ]S§\n€ò˝xäÒºö«\r›l¶ˇXG´;{Ï¡Ïyù9*®≈@K: ó≈J\Z-Œluôü\Z÷€œ“ƒîC=J•EˆJüµ∏Qï∑kÙm=•åxìÈJúâ˙!h·ï˘íÜÂô˚˛·8—Œbûù±s‹Ç0?_˝{XCàÊ/Fﬁ:ºõˇi\ZØYs˙îè£%⁄8q÷·Ù¥˘Íºa/X˚ïè∂@ÛÌàíñ8Êbe°eÛ’:ËNÎË”îè…èÊqiUËl>!bŒIœÀ∞¿Ê∏k_Ü¶≠^[ÃˇÏ\Z-CÀ@¨ïN0K‘ıM\'åÊYü2∑(Ø¬\'„	 *Üˇô4	÷Fãh§ZãzDE[m∂VQÔƒÊáˇ-éÜ§EO‘d•üŒmcD€Ej\Z=ÆCvÛ3~∂SF\\&)UÀ‹B)¿è⁄ha¨§¯1´I4bh˘\"Ï›ﬁ‚©Ñ1Ä¨∂…<ﬁMWõk4å√6ïπ%™Wüf G”∆iƒˆa]ZU˚n|àËBTgg\n‹“µ≈œûWà7|§—¢Ÿ™>∏◊”œeƒõ‡°XD#∏—Á#15˜?û¸ñˇ˚ã/ﬁzKƒ}”yˆÛ[Qg|1ç\\#∆,BhB˜ZÏ°”ñ∆˜älÁaÊÜˇ9]>„	oæx®m˘¿ù¶ìúüÆ\nòˆ‚÷îDπ”€∂Û©g¨¡«´ö\nÎ\\˘˛z¸$D?˝±‹Ô∂õÀÂÙ%~¨Ár˝ß˘eıx\ZHÔΩ∆˝«Óø˝˛ÕÈœcÃø±1Ω]<[óø;˝ı\na\\¸ÄMK¸É±DDp€\nî„c‘yÖø[_ûØœw¯-ùÂjøÊ?ˇ<Ω=˝â˘Ï›/‰ˇÇ√õ¬ /£˚e(∑_ªZΩÛ⁄}‘—1”›OyÌ~¯©Ø›œ~ös√)‚‡E^§ìóNy`Ø⁄€¢ø`4Qp‹˘\'	j”x˚—Èõ∏îÎqC2ÃÏÁ¯⁄:ß=¢=„,?\0˝∆œŸ™#à›ùæÔ⁄;ì6~÷Ë‘\ro¿Ëä#˘∆*˚l≥$}+ÄêSÂÄGÌ>◊\ru÷◊m(=‘è¡æ◊5‡_ŒBRéØn∞5&Õ	ˆlØ—÷pﬁÂ`ﬂw‹mŸçW?ù≤fMÁÒÌyµ=:øµC]Ô†…Õì„û;áÚV¡zBGoD¿{$yûy>çﬁ„\rÍ°iﬁõÓ∫·m,“>i˛c>qTÑjo\'ÃBäì…#9èΩ ¶ÔÙÌ˘ú≈´Áé˚áÕÕÔDK—∏o§;Õ€n\rw #®≥Î«ân≈›Agﬁ7?Á±ƒÜ≠•~¢«›1‚<ãù€Xª≠ª-∂7[G0ö⁄˛AAŒö˝LS£ÚÖv.Z]1˜àv˙∏˝b¸Õ—ﬂ·O‹Ø∆`\\GàÉb9ô$⁄ÈgıÒvì¢b£⁄.·7ìU;óRåMﬁãr=nz[èjÛ:ÑÍç+g>≠6ã≥ÃpïIÛ√VjÚ\rÔóT∑åÕçF≠Ö4û5¬‹2f±Ω∏4¯tûWex^˘Q3ïjdoy/&/F¡FﬁU#™¿wÉü»œ\rs˘÷…ŸI&?Kˆê®jÒooÚ‚O‰∂ürP,÷£çYÜŒÚU\n¿ïc„)ìÊ≈N8˚Dià∂éR∆…\rÌÄò¢ı(wzåQÛÃ…Õf±sâ¶∑Ü‹&£zûıG\Zª3â Éb≥ÏónTsÓÍ∂’â¶MΩ„B_	ÍL&gÁ/”(¿«9⁄*£Q≈å∆∏˙ã≠ëw_0≥*,Ü“… Û˜U˘“ûo*&!gçj\"S\r\"z˝Ï{˚}øõ»Ù±?{G©©⁄øøıº9x£ kuA‹◊¸∆ìÙ¥IYsP‘‡∆°ı¢U=ƒ·“X“7\Z/E;3z`∫\\«˛≥“∑®†3ú MWœßöÎı{dvÙ˚®Ú6\\≥®¬‘„†ﬂ‚1[s:œÓh<—!õ‚“G‚rGµeóÎ‹Qµç0À0Ø7®ö\Z\\6>˜yk±¬!ÜƒN>ﬂh ÌV3n\0ìh™d^ámäÃfâ›z®Ú”´b‹|ºEÌnﬂõ¯∂y´Uı»p™[ßa““ïõK±Q1)ÉõQç`«ãò2¿«l[`∆‡(^,ús|_¢Åïéo1’b*˝\"˚1~–s7ìÜèAüﬂ€Ñ6~Plu2øRb^üöÄ‚ÊÔuß¶\ríS#Wö—èu3éÔ•$˝Ãm7r•≠}õ—∑\rnl*wÜ˝\0p\'ÿéqÑSf¨Œi†œqdﬁ{;¬tÀ2›hΩòSkﬁL‰®´}üeNOôoÔFè<Cådˆ≈õpæ¡Pl¶(Ω…_Ã»œ≥Ê1‘7,`4-~¥à—pœ±á°∞Ëg~ujÕLø3.jüM(í±|¥;ÊÛÁô\'-˝÷,ipıº≤—√<¶{{øÒìÊYÀmäçuö∆Å∫f™œ=∆∫ÊΩî;ª-Gzm:(6N¨|¶ÿ8˝πáŸnÛÜëÌxkeﬁmw∑Œ6*Ç<ûBõ≠¶~3pi¥øxÁöQÃPŒ¿2P^∑±Ó¨xç∑1uäeÏ‰ºΩ››vçl˚@˙√∫\'C&fÖ∆oÊÿªÑq\'[1ùØ√N´h˙:t∆àÍyìΩ`⁄’ÜáFç≥Ÿ∫P«uF≤Ü1MŒàrÆÎü1•–/∑aÈgDm:Çu±\'üo4œt´á˚6„√b≥ŸØsôfüOpÍËë«:é=eÕ=åìOz.õ{í;ÈënµÑ|\\π≠4◊Æÿn¨‹Õ=∆⁄Ì‰ÃØMÌ\\Üßcjûp=˘|Ç®ÁÜÜÍÏ≈F£áùˆ»ÚmuÓñØ\\\r	≈1Àº€Åπ´Ì%ÜôÁÊ6|<∏0ö^/≥ü;<øb¸1Ã9zè?)∆c√ˇ.Ûn√¿‹eé¡wï<˙πˆKÑGÏÔ«,Ê¯·?ƒ±€Ÿ6TéJ~û9Ÿ•YíπRgO‰!/¨4bã—≤€¨y¨ÉÔ¥cãÕﬂá˛Î`ù,[L∂b±Ñ·£˙fPnXÄfø/íM¡}ÕZ˜u˚l+≠fqLèyÀ4˚4Ô•⁄:ÜN¨’f)f’˘^¡[=ÚÏÂÎëÕœ7ù8?1tÚqT£G5O\'\r]x\\iúÂUuÙ∞/¨8¥Æ∏{”Î√f{ãr\rÕœ◊ÒªS;7«0F\\hD‡¬ﬂ\Z˙cDõ3®;[dC7GÛ¢èqæŸzÃ@∂ÕQ<”¸fÜ_g~«•~ô© ±ÏÊ†‹—o\ZHÃR2}¯…bÊH†ºáAπô@}Lt3ífâ>K=êdW”1êpüë¨◊ô∫]0$⁄á[2jóÊÔu›Õœ+ínjY£É;E∫f‹∂¸a∑ár\n√»ì\nsÀúC»(@i∂ÃYÖcÀH\"G˛á“\nß”º¬È§?=Ø¿;v˘ëº¬óK¸ ÓÁÎÈƒ˝ï¸ˇ≥ÀÎÌ˙pö`‡\"J˙tÇ·ˆÔı~˚~®xø<ﬂÌø˝ŸﬂL,ËÎ◊›ß3ø~‰W»ß?O¸˙|á_q>….Wß 1ÿ/Sñ(ûp™v›‚Åˇ@ãæ‚Ùd\\m–ÉØ‹3~ãHrèüÓ¸…”x\r˙≈≠	–Ú©sò¶c8ﬁ‰Ô∞Î{Ïßú≈I\Zy%˚ÒÓÈ_ﬁ|˘ÛÁœÓ¸œ˛\'L+aÇ≥=	{˘‡/MìﬁHÌVW◊g{Êï@˙≈Ùõk¸‹6>o¯#Ù¸]˘o?{˚õg?ıÌœ∆/[üÀƒ˝ïm˛≤˚/˚igÑ«ÒÉ^≤ó»üÃ·^Ú…^¬YYØ÷±ãCŸKÒÁn-‹≤ˆ+ˆ˛\\†hK9àÊ>[û◊3Ôón%é©Î%é\rÓ˝˙,=8{‰è¸~j˙SR.¶œw´Î˛6˙áıÂö¥√Obü¸ºΩÊ›ìÙÔ7ó¯!Û’Ú¸/õ…¯Øã√†£»√ƒ„8Ô˘˙bwêCƒoÜˇrZéøæ⁄@Dˆá5p˜qç;L∫_/ıó”œ÷”aΩóœ7õ√XÏıÂ¥<€}¿«Ôü‚…√ı¥Zv¯eÒÃÉG\ZQNÌ\'˛™∂ÊﬁµæPUº^Ω$+ÎNUÛßÅÊçf€Ë˝§•Hˇß¯œ\'ÁqÓ<íi^ì›}|Yy¸é\'÷ııêôMò%ù˝ˇ\0`{Ù™\nendstream\nendobj\n20 0 obj\n<< /Type /Font\n/Subtype /Type1\n/Name /F5\n/BaseFont /Courier\n/Encoding /WinAnsiEncoding\n>>\nendobj\n21 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/CA 0.93\n>>\nendobj\n22 0 obj\n<< /Type /ExtGState\n/BM /Normal\n/ca 0.93\n>>\nendobj\nxref\n0 23\n0000000000 65535 f \n0000000009 00000 n \n0000000074 00000 n \n0000000120 00000 n \n0000000404 00000 n \n0000000433 00000 n \n0000000644 00000 n \n0000000747 00000 n \n0000007071 00000 n \n0000007178 00000 n \n0000007286 00000 n \n0000007399 00000 n \n0000007515 00000 n \n0000007572 00000 n \n0000007629 00000 n \n0000007734 00000 n \n0000012301 00000 n \n0000012406 00000 n \n0000016725 00000 n \n0000016830 00000 n \n0000032234 00000 n \n0000032340 00000 n \n0000032400 00000 n \ntrailer\n<<\n/Size 23\n/Root 1 0 R\n/Info 5 0 R\n/ID[<7b02807247ba3b3922db1eed53685f3a><7b02807247ba3b3922db1eed53685f3a>]\n>>\nstartxref\n32460\n%%EOF\n','cfbe9d0e9d74dc1e70224247fa3c05b492b45474bdcd5b3f8ae8928d9237a861','2026-10-10 16:29:20','2026-10-10 16:30:26',NULL);
/*!40000 ALTER TABLE `contratos_credito` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_ventas`
--

DROP TABLE IF EXISTS `detalle_ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `detalle_ventas` (
  `id_detalle` int(11) NOT NULL AUTO_INCREMENT,
  `id_venta` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal_linea` decimal(10,2) NOT NULL,
  `vin` varchar(50) DEFAULT NULL,
  `motor_serie` varchar(80) DEFAULT NULL,
  `color_interior` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `fk_detalle_ventas_ventas` (`id_venta`),
  KEY `fk_detalle_ventas_productos` (`id_producto`),
  CONSTRAINT `fk_detalle_ventas_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_detalle_ventas_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
INSERT INTO `detalle_ventas` VALUES (1,1,5,1,1850000.00,1850000.00,NULL,NULL,NULL),(2,1,9,1,12400.00,12400.00,NULL,NULL,NULL),(3,2,6,1,620000.00,620000.00,NULL,NULL,NULL),(4,3,6,1,620000.00,620000.00,'2026','12345','Negro piel'),(5,4,1,1,2280000.00,2280000.00,'2024911','3.0','Negro grisaceo'),(6,5,54,1,444801.61,444801.61,'2345671','V2 Testastretta',NULL),(7,6,25,1,3469997.91,3469997.91,'WAUZZZZZ0SS100814','5.2L V10 FSI',NULL),(8,7,20,1,1743576.89,1743576.89,'WAUZZZZZ0PS100629','3.0L V6 TFSI','Negro'),(9,8,63,2,4918.41,9836.82,NULL,NULL,NULL),(10,9,18,1,1006865.63,1006865.63,'WAUZZZZZ0SS100555',NULL,NULL),(11,10,78,2,2440.93,4881.86,NULL,NULL,NULL),(12,11,84,1,1203.37,1203.37,NULL,NULL,NULL),(13,12,52,1,288140.62,288140.62,'ZDMZZZZZ0PS101813',NULL,NULL),(14,13,84,1,1203.37,1203.37,NULL,NULL,NULL),(15,14,84,1,1203.37,1203.37,NULL,NULL,NULL),(16,15,46,1,371609.38,371609.38,'ZDMZZZZZ0RS101591','V2 Testastretta',NULL),(17,16,84,1,1203.37,1203.37,NULL,NULL,NULL),(18,17,61,1,5907.23,5907.23,NULL,NULL,NULL),(19,18,33,1,2413985.87,2413985.87,'WP0ZZZZZ0RS101110','3.0L Boxer Biturbo','Negro'),(20,19,33,1,2413985.87,2413985.87,'WP0ZZZZZ0RS101110','3.0L Boxer Biturbo','Negro'),(21,20,54,1,444801.61,444801.61,'ZDMZZZZZ0RS101887','V2 Testastretta',NULL),(22,21,18,1,1006865.63,1006865.63,'WAUZZZZZ0SS100555','2.0L TFSI Turbo','Negro'),(23,22,55,1,359002.51,359002.51,'ZDMZZZZZ0PS101924','V2 Testastretta',NULL);
/*!40000 ALTER TABLE `detalle_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `garantias`
--

DROP TABLE IF EXISTS `garantias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `garantias` (
  `id_garantia` int(11) NOT NULL AUTO_INCREMENT,
  `id_cliente` int(11) DEFAULT NULL COMMENT 'Cliente de la secci√≥n Clientes (cr√©ditos o compradores con cuenta); NULL en contado',
  `id_producto` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL COMMENT 'Venta con la que se compr√≥ el veh√≠culo',
  `id_sucursal` int(11) DEFAULT NULL COMMENT 'Sucursal donde se vendi√≥',
  `vin` varchar(17) DEFAULT NULL COMMENT 'VIN de la unidad vendida',
  `cliente_nombre` varchar(150) DEFAULT NULL COMMENT 'Comprador tal como se captur√≥ en caja',
  `cliente_celular` varchar(30) DEFAULT NULL,
  `cliente_email` varchar(120) DEFAULT NULL,
  `fecha_compra` datetime DEFAULT NULL COMMENT 'Momento real de la venta (ventas.fecha_hora)',
  `fecha_expiracion` datetime NOT NULL COMMENT 'Fecha y hora exactas de vencimiento (compra + 4 a√±os)',
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `garantias`
--

LOCK TABLES `garantias` WRITE;
/*!40000 ALTER TABLE `garantias` DISABLE KEYS */;
INSERT INTO `garantias` VALUES (4,13,55,22,1,'ZDMZZZZZ0PS101924','Mar√≠a De Todos Los Angeles','3145439851','mariadelosangeles@gmail.com','2026-10-10 16:30:26','2030-10-10 16:30:26','vigente');
/*!40000 ALTER TABLE `garantias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventarios`
--

DROP TABLE IF EXISTS `inventarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inventarios` (
  `id_inventario` int(11) NOT NULL AUTO_INCREMENT,
  `id_sucursal` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `stock_actual` int(11) NOT NULL DEFAULT 0,
  `stock_minimo` int(11) NOT NULL DEFAULT 5,
  PRIMARY KEY (`id_inventario`),
  UNIQUE KEY `uq_sucursal_producto` (`id_sucursal`,`id_producto`),
  KEY `fk_inventarios_productos` (`id_producto`),
  CONSTRAINT `fk_inventarios_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_inventarios_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=195 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventarios`
--

LOCK TABLES `inventarios` WRITE;
/*!40000 ALTER TABLE `inventarios` DISABLE KEYS */;
INSERT INTO `inventarios` VALUES (1,1,5,4,1),(2,1,4,4,1),(3,1,6,4,1),(4,1,7,3,1),(5,1,1,1,1),(6,1,2,1,1),(7,1,3,2,1),(8,1,8,8,1),(9,1,9,9,1),(10,1,10,1,1),(11,1,11,0,2),(12,1,12,0,2),(13,1,13,1,2),(14,1,14,1,2),(15,1,15,2,2),(16,1,16,3,2),(17,1,17,0,2),(18,1,18,3,2),(19,1,19,2,2),(20,1,20,0,2),(21,1,21,0,2),(22,1,22,4,2),(23,1,23,3,2),(24,1,24,7,2),(25,1,25,0,2),(26,1,41,0,2),(27,1,42,0,2),(28,1,43,1,2),(29,1,44,1,2),(30,1,45,2,2),(31,1,46,2,2),(32,1,47,0,2),(33,1,48,5,2),(34,1,49,2,2),(35,1,50,1,2),(36,1,51,0,2),(37,1,52,3,2),(38,1,53,3,2),(39,1,54,5,2),(40,1,55,0,2),(41,1,26,0,2),(42,1,27,0,2),(43,1,28,1,2),(44,1,29,1,2),(45,1,30,2,2),(46,1,31,3,2),(47,1,32,0,2),(48,1,33,3,2),(49,1,34,2,2),(50,1,35,1,2),(51,1,36,0,2),(52,1,37,4,2),(53,1,38,3,2),(54,1,39,7,2),(55,1,40,1,2),(56,1,56,0,2),(57,1,57,0,2),(58,1,58,1,2),(59,1,59,1,2),(60,1,60,2,2),(61,1,61,2,2),(62,1,62,0,2),(63,1,63,3,2),(64,1,64,2,2),(65,1,65,1,2),(66,1,76,3,2),(67,1,77,0,2),(68,1,78,3,2),(69,1,79,2,2),(70,1,80,1,2),(71,1,81,0,2),(72,1,82,4,2),(73,1,83,3,2),(74,1,84,3,2),(75,1,85,1,2),(76,1,66,0,2),(77,1,67,4,2),(78,1,68,3,2),(79,1,69,6,2),(80,1,70,1,2),(81,1,71,0,2),(82,1,72,0,2),(83,1,73,1,2),(84,1,74,1,2),(85,1,75,2,2),(86,1,86,6,2),(87,1,87,2,2),(88,1,88,8,2),(89,1,89,1,2),(90,1,90,4,2),(91,1,91,0,2),(92,1,92,2,2),(93,1,93,5,2),(94,1,94,3,2),(101,2,1,1,1),(102,2,2,0,1),(103,2,3,5,1),(104,2,4,3,1),(105,2,5,2,1),(106,2,6,1,1),(107,2,7,0,1),(108,2,8,1,2),(109,2,9,3,2),(110,2,10,0,2),(111,2,11,5,1),(112,2,12,0,1),(113,2,13,5,1),(114,2,14,3,1),(115,2,15,2,1),(116,2,16,1,1),(117,2,17,0,1),(118,2,18,5,1),(119,2,19,3,1),(120,2,20,2,1),(121,2,21,1,1),(122,2,22,0,1),(123,2,23,5,1),(124,2,24,3,1),(125,2,25,1,1),(126,2,26,1,1),(127,2,27,0,1),(128,2,28,3,1),(129,2,29,3,1),(130,2,30,2,1),(131,2,31,1,1),(132,2,32,0,1),(133,2,33,5,1),(134,2,34,3,1),(135,2,35,2,1),(136,2,36,1,1),(137,2,37,0,1),(138,2,38,5,1),(139,2,39,3,1),(140,2,40,2,1),(141,2,41,1,1),(142,2,42,2,1),(143,2,43,5,1),(144,2,44,3,1),(145,2,45,2,1),(146,2,46,1,1),(147,2,47,0,1),(148,2,48,5,1),(149,2,49,3,1),(150,2,50,2,1),(151,2,51,1,1),(152,2,52,0,1),(153,2,53,5,1),(154,2,54,3,1),(155,2,55,2,1),(156,2,56,5,2),(157,2,57,3,2),(158,2,58,0,2),(159,2,59,10,2),(160,2,60,5,2),(161,2,61,2,2),(162,2,62,1,2),(163,2,63,1,2),(164,2,64,0,2),(165,2,65,10,2),(166,2,66,5,2),(167,2,67,0,2),(168,2,68,1,2),(169,2,69,3,2),(170,2,70,0,2),(171,2,71,10,2),(172,2,72,5,2),(173,2,73,2,2),(174,2,74,1,2),(175,2,75,3,2),(176,2,76,0,2),(177,2,77,10,2),(178,2,78,10,2),(179,2,79,2,2),(180,2,80,1,2),(181,2,81,3,2),(182,2,82,0,2),(183,2,83,10,2),(184,2,84,5,2),(185,2,85,2,2),(186,2,86,5,2),(187,2,87,2,2),(188,2,88,1,2),(189,2,89,3,2),(190,2,90,0,2),(191,2,91,10,2),(192,2,92,5,2),(193,2,93,2,2),(194,2,94,1,2);
/*!40000 ALTER TABLE `inventarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `metodos_pago`
--

DROP TABLE IF EXISTS `metodos_pago`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metodos_pago` (
  `id_metodo_pago` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_metodo` varchar(50) NOT NULL,
  PRIMARY KEY (`id_metodo_pago`),
  UNIQUE KEY `nombre_metodo` (`nombre_metodo`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metodos_pago`
--

LOCK TABLES `metodos_pago` WRITE;
/*!40000 ALTER TABLE `metodos_pago` DISABLE KEYS */;
INSERT INTO `metodos_pago` VALUES (1,'Efectivo'),(5,'Sin cobro (enganche $0)'),(3,'Tarjeta de Cr√©dito'),(2,'Tarjeta de D√©bito'),(4,'Transferencia');
/*!40000 ALTER TABLE `metodos_pago` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notificaciones`
--

DROP TABLE IF EXISTS `notificaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notificaciones` (
  `id_notificacion` int(11) NOT NULL AUTO_INCREMENT,
  `id_cliente` int(11) NOT NULL,
  `tipo` enum('pedido','cita','solicitud','promocion','cuenta') NOT NULL DEFAULT 'cuenta',
  `titulo` varchar(150) NOT NULL,
  `mensaje` varchar(500) DEFAULT NULL,
  `enlace` varchar(255) DEFAULT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT 0,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_notificacion`),
  KEY `idx_notificaciones_cliente` (`id_cliente`,`leida`),
  CONSTRAINT `fk_notificaciones_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones`
--

LOCK TABLES `notificaciones` WRITE;
/*!40000 ALTER TABLE `notificaciones` DISABLE KEYS */;
INSERT INTO `notificaciones` VALUES (17,9,'cuenta','¬°Bienvenido a KARMA!','Tu cuenta qued√≥ lista. Desde tu perfil puedes revisar pedidos, citas y veh√≠culos de inter√©s.','perfil.php',0,'2026-10-04 16:13:31'),(18,9,'cita','Apartado de veh√≠culo agendada (CITA-01-000004)','Porsche 911 GT3 ¬∑ Manzanillo ¬∑ 5 oct 2026, 10:00. Te esperamos.','perfil.php#citas',0,'2026-10-04 16:14:34'),(19,9,'pedido','Pedido WEB-01-000011 recibido','Tus piezas quedaron apartadas en Manzanillo. Paga en efectivo al recogerlas en caja.','pedido.php?id=11',0,'2026-10-04 17:09:53'),(20,9,'pedido','Pedido WEB-01-000011 pagado en caja','Recibimos tu pago en efectivo. ¬°Gracias por tu compra en KARMA!','pedido.php?id=11',0,'2026-10-05 22:32:10');
/*!40000 ALTER TABLE `notificaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL AUTO_INCREMENT,
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
  `traccion` varchar(80) DEFAULT NULL,
  `lado` varchar(50) DEFAULT NULL,
  `color_interior` varchar(80) DEFAULT NULL,
  `vin` varchar(17) DEFAULT NULL,
  `numero_motor` varchar(40) DEFAULT NULL COMMENT 'N√∫mero de serie del motor de la unidad',
  `modelo_3d` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `codigo_barras` (`codigo_barras`),
  UNIQUE KEY `uq_productos_vin` (`vin`),
  KEY `fk_productos_categorias` (`id_categoria`),
  KEY `idx_productos_tipo` (`tipo`),
  CONSTRAINT `fk_productos_categorias` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id_categoria`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=95 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (1,1,'KRM-P911-24','911 Carrera 2024','Porsche 911 Carrera 2024',2280000.00,'Porsche','911 Carrera',2024,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Sport Chrono de f√°brica y llantas forjadas de 21\".',NULL,NULL,NULL,'Negro','WP0ZZZ990RS100037',NULL,NULL),(2,1,'KRM-P911-25','911 Carrera 2025','Porsche 911 Carrera 2025',2350000.00,'Porsche','911 Carrera',2025,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Sport Chrono de f√°brica y llantas forjadas de 21\".',NULL,NULL,NULL,'Negro','WP0ZZZ990SS100074',NULL,'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb'),(3,1,'KRM-PTAY-25','Taycan Turbo S 2025','Porsche Taycan Turbo S 2025',3180000.00,'Porsche','Taycan Turbo S',2025,'auto','Blanco Carrara','#EDEDEA','El√©ctrico de doble motor','‚Äî','Doble motor el√©ctrico con carga ultrarr√°pida de 270 kW.',NULL,NULL,NULL,'Beige','WP0ZZZY10SS100111',NULL,NULL),(4,2,'KRM-ARS7-24','RS7 Sportback 2024','Audi RS7 Sportback 2024',2190000.00,'Audi','RS7 Sportback',2024,'auto','Gris Nardo','#7A7D80','4.0L V8 Biturbo','3993 cc','V8 biturbo con interior en piel Nappa extendida.',NULL,NULL,NULL,'Negro','WUAZZZF20RS100148',NULL,NULL),(5,2,'KRM-AQ8E-25','Q8 e-tron 2025','Audi Q8 e-tron 2025',1850000.00,'Audi','Q8 e-tron',2025,'auto','Azul Ultra','#1F3B66','El√©ctrico de doble motor','‚Äî','Doble motor el√©ctrico y techo panor√°mico solar.',NULL,NULL,NULL,'Caf√©','WA1ZZZFE0SS100185',NULL,NULL),(6,3,'KRM-DPAN-24','Panigale V4 S 2024','Ducati Panigale V4 S 2024',620000.00,'Ducati','Panigale V4 S',2024,'moto','Rojo Ducati','#9E1B2E','V4 Desmosedici Stradale','1103 cc','Motor V4 con electr√≥nica √ñhlins de serie.',NULL,NULL,NULL,NULL,'ZDMZZZPV0RS100222',NULL,NULL),(7,3,'KRM-DSTR-25','Streetfighter V4 2025','Ducati Streetfighter V4 2025',590000.00,'Ducati','Streetfighter V4',2025,'moto','Negro Mate','#1A1A1A','V4 Desmosedici Stradale','1103 cc','Motor V4 con winglets aerodin√°micos de MotoGP.',NULL,NULL,NULL,NULL,'ZDMZZZSF0SS100259',NULL,NULL),(8,4,'KRM-REF-DISCO-911','Disco de freno delantero','Disco de freno delantero para Porsche 911',18500.00,'Porsche','911 Carrera',2024,'refaccion','Acero gris','#8C9096','3.0L Boxer Biturbo',NULL,'Disco delantero izquierdo.','Porsche 911','Trasera','Izquierdo',NULL,NULL,NULL,NULL),(9,4,'KRM-REF-PAST-AUDI','Juego de pastillas de freno','Pastillas de freno para Audi RS7',12400.00,'Audi','RS7 Sportback',2024,'refaccion','Negro grafito','#2E2F33','4.0L V8 Biturbo',NULL,'Juego completo para eje delantero.','Audi RS7 Sportback','AWD','Ambos',NULL,NULL,NULL,NULL),(10,4,'KRM-REF-BALATA-AUDI','Balata delantera','Balata delantera para Audi RS7',9800.00,'Audi','RS7 Sportback',2024,'refaccion','Negro grafito','#2E2F33','4.0L V8 Biturbo',NULL,NULL,'Audi RS7 Sportback','AWD','Ambos',NULL,NULL,NULL,'assets/Modelos_3D/idproducto10_idcategoria4_KRM-REF-BALATA-AUDI_balataDelanteraParaAudiRS7_2024_Negro grafito_refaccion.glb'),(11,2,'KRM-CAT-AUDI-01','A3 2025','Audi A3 2025, motor 1.4L TFSI Turbo.',665281.24,'Audi','A3',2025,'auto','Gris Nardo','#7A7D80','1.4L TFSI Turbo','1395 cc','Audi A3 equipado de f√°brica, listo para entrega en agencia.',NULL,'Delantera',NULL,'Negro','WAUZZZZZ0SS100296',NULL,NULL),(12,2,'KRM-CAT-AUDI-02','A4 2024','Audi A4 2024, motor 2.0L TFSI Turbo.',812356.66,'Audi','A4',2024,'auto','Blanco Glaciar','#F2F2EF','2.0L TFSI Turbo','1984 cc','Audi A4 equipado de f√°brica, listo para entrega en agencia.',NULL,'Delantera',NULL,'Negro','WAUZZZZZ0RS100333',NULL,NULL),(13,2,'KRM-CAT-AUDI-03','A5 2025','Audi A5 2025, motor 2.0L TFSI Turbo.',946010.16,'Audi','A5',2025,'auto','Gris Nardo','#7A7D80','2.0L TFSI Turbo','1984 cc','Audi A5 equipado de f√°brica, listo para entrega en agencia.',NULL,'Delantera',NULL,'Negro','WAUZZZZZ0SS100370',NULL,NULL),(14,2,'KRM-CAT-AUDI-04','A6 2025','Audi A6 2025, motor 3.0L V6 TFSI.',1166650.62,'Audi','A6',2025,'auto','Gris Nardo','#7A7D80','3.0L V6 TFSI','2995 cc','Audi A6 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100407',NULL,NULL),(15,2,'KRM-CAT-AUDI-05','A7 2023','Audi A7 2023, motor 3.0L V6 TFSI.',1206138.70,'Audi','A7',2023,'auto','Gris Nardo','#7A7D80','3.0L V6 TFSI','2995 cc','Audi A7 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100444',NULL,NULL),(16,2,'KRM-CAT-AUDI-06','A8 2023','Audi A8 2023, motor 3.0L V6 TFSI.',1809054.93,'Audi','A8',2023,'auto','Rojo Tango','#8C1D2B','3.0L V6 TFSI','2995 cc','Audi A8 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Beige','WAUZZZZZ0PS100481',NULL,NULL),(17,2,'KRM-CAT-AUDI-07','Q3 2025','Audi Q3 2025, motor 2.0L TFSI Turbo.',858687.40,'Audi','Q3',2025,'auto','Blanco Glaciar','#F2F2EF','2.0L TFSI Turbo','1984 cc','Audi Q3 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100518',NULL,NULL),(18,2,'KRM-CAT-AUDI-08','Q5 2025','Audi Q5 2025, motor 2.0L TFSI Turbo.',1006865.63,'Audi','Q5',2025,'auto','Rojo Tango','#8C1D2B','2.0L TFSI Turbo','1984 cc','Audi Q5 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100555',NULL,NULL),(19,2,'KRM-CAT-AUDI-09','Q7 2024','Audi Q7 2024, motor 3.0L V6 TFSI.',1398540.24,'Audi','Q7',2024,'auto','Rojo Tango','#8C1D2B','3.0L V6 TFSI','2995 cc','Audi Q7 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100592',NULL,NULL),(20,2,'KRM-CAT-AUDI-10','Q8 2023','Audi Q8 2023, motor 3.0L V6 TFSI.',1743576.89,'Audi','Q8',2023,'auto','Blanco Glaciar','#F2F2EF','3.0L V6 TFSI','2995 cc','Audi Q8 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100629',NULL,NULL),(21,2,'KRM-CAT-AUDI-11','RS3 2024','Audi RS3 2024, motor 2.5L TFSI Turbo 5-cil..',1303929.87,'Audi','RS3',2024,'auto','Negro Mythos','#101012','2.5L TFSI Turbo 5-cil.','2480 cc','Audi RS3 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100666',NULL,NULL),(22,2,'KRM-CAT-AUDI-12','RS5 2024','Audi RS5 2024, motor 2.9L V6 Biturbo.',1579878.48,'Audi','RS5',2024,'auto','Gris Nardo','#7A7D80','2.9L V6 Biturbo','2894 cc','Audi RS5 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100703',NULL,NULL),(23,2,'KRM-CAT-AUDI-13','RS6 2023','Audi RS6 2023, motor 4.0L V8 Biturbo.',2480657.88,'Audi','RS6',2023,'auto','Negro Mythos','#101012','4.0L V8 Biturbo','3993 cc','Audi RS6 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100740',NULL,NULL),(24,2,'KRM-CAT-AUDI-14','RS7 2025','Audi RS7 2025, motor 4.0L V8 Biturbo.',2297617.75,'Audi','RS7',2025,'auto','Negro Mythos','#101012','4.0L V8 Biturbo','3993 cc','Audi RS7 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100777',NULL,NULL),(25,2,'KRM-CAT-AUDI-15','R8 2025','Audi R8 2025, motor 5.2L V10 FSI.',3469997.91,'Audi','R8',2025,'auto','Azul Ultra','#1F3B66','5.2L V10 FSI','5204 cc','Audi R8 equipado de f√°brica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100814',NULL,'assets/Modelos_3D/id25_KRM-CAT-AUDI-15_audiR8_2025_AzulUltra.glb'),(26,1,'KRM-CAT-POR-01','718 Cayman 2024','Porsche 718 Cayman 2024, motor 2.0L Turbo Flat-4.',1361240.78,'Porsche','718 Cayman',2024,'auto','Blanco Carrara','#EDEDEA','2.0L Turbo Flat-4','1988 cc','Porsche 718 Cayman equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0RS100851',NULL,NULL),(27,1,'KRM-CAT-POR-02','718 Boxster 2025','Porsche 718 Boxster 2025, motor 2.0L Turbo Flat-4.',1465107.75,'Porsche','718 Boxster',2025,'auto','Azul Gentian','#1B3A6B','2.0L Turbo Flat-4','1988 cc','Porsche 718 Boxster equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0SS100888',NULL,NULL),(28,1,'KRM-CAT-POR-03','911 Carrera 2024','Porsche 911 Carrera 2024, motor 3.0L Boxer Biturbo.',1996608.97,'Porsche','911 Carrera',2024,'auto','Azul Gentian','#1B3A6B','3.0L Boxer Biturbo','2981 cc','Porsche 911 Carrera equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0RS100925',NULL,NULL),(29,1,'KRM-CAT-POR-04','911 Carrera S 2023','Porsche 911 Carrera S 2023, motor 3.0L Boxer Biturbo.',2338828.86,'Porsche','911 Carrera S',2023,'auto','Blanco Carrara','#EDEDEA','3.0L Boxer Biturbo','2981 cc','Porsche 911 Carrera S equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0PS100962',NULL,NULL),(30,1,'KRM-CAT-POR-05','911 Turbo 2024','Porsche 911 Turbo 2024, motor 3.7L Boxer Biturbo.',3646135.38,'Porsche','911 Turbo',2024,'auto','Blanco Carrara','#EDEDEA','3.7L Boxer Biturbo','3745 cc','Porsche 911 Turbo equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS100999',NULL,NULL),(31,1,'KRM-CAT-POR-06','911 GT3 2023','Porsche 911 GT3 2023, motor 4.0L Boxer Atmosf√©rico.',3520336.58,'Porsche','911 GT3',2023,'auto','Rojo Carm√≠n','#9E1B2E','4.0L Boxer Atmosf√©rico','3996 cc','Porsche 911 GT3 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0PS101036',NULL,NULL),(32,1,'KRM-CAT-POR-07','911 GT3 RS 2025','Porsche 911 GT3 RS 2025, motor 4.0L Boxer Atmosf√©rico.',4209809.72,'Porsche','911 GT3 RS',2025,'auto','Gris GT Plata','#9EA0A1','4.0L Boxer Atmosf√©rico','3996 cc','Porsche 911 GT3 RS equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101073',NULL,NULL),(33,1,'KRM-CAT-POR-08','911 Targa 2024','Porsche 911 Targa 2024, motor 3.0L Boxer Biturbo.',2413985.87,'Porsche','911 Targa',2024,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Porsche 911 Targa equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS101110',NULL,NULL),(34,1,'KRM-CAT-POR-09','Taycan 2025','Porsche Taycan 2025, motor El√©ctrico de doble motor.',2492779.35,'Porsche','Taycan',2025,'auto','Blanco Carrara','#EDEDEA','El√©ctrico de doble motor','‚Äî','Porsche Taycan equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101147',NULL,NULL),(35,1,'KRM-CAT-POR-10','Taycan Turbo 2023','Porsche Taycan Turbo 2023, motor El√©ctrico de doble motor.',3296579.71,'Porsche','Taycan Turbo',2023,'auto','Azul Gentian','#1B3A6B','El√©ctrico de doble motor','‚Äî','Porsche Taycan Turbo equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101184',NULL,NULL),(36,1,'KRM-CAT-POR-11','Panamera 2023','Porsche Panamera 2023, motor 2.9L V6 Biturbo.',2010461.38,'Porsche','Panamera',2023,'auto','Rojo Carm√≠n','#9E1B2E','2.9L V6 Biturbo','2894 cc','Porsche Panamera equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0PS101221',NULL,NULL),(37,1,'KRM-CAT-POR-12','Panamera Turbo 2025','Porsche Panamera Turbo 2025, motor 4.0L V8 Biturbo.',2846312.51,'Porsche','Panamera Turbo',2025,'auto','Azul Gentian','#1B3A6B','4.0L V8 Biturbo','3996 cc','Porsche Panamera Turbo equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101258',NULL,NULL),(38,1,'KRM-CAT-POR-13','Macan 2024','Porsche Macan 2024, motor 2.0L Turbo.',1387139.15,'Porsche','Macan',2024,'auto','Blanco Carrara','#EDEDEA','2.0L Turbo','1984 cc','Porsche Macan equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS101295',NULL,NULL),(39,1,'KRM-CAT-POR-14','Cayenne 2023','Porsche Cayenne 2023, motor 3.0L V6 Turbo.',1751851.73,'Porsche','Cayenne',2023,'auto','Gris GT Plata','#9EA0A1','3.0L V6 Turbo','2995 cc','Porsche Cayenne equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101332',NULL,NULL),(40,1,'KRM-CAT-POR-15','Cayenne Turbo 2023','Porsche Cayenne Turbo 2023, motor 4.0L V8 Biturbo.',2825169.72,'Porsche','Cayenne Turbo',2023,'auto','Negro Jeweled','#141414','4.0L V8 Biturbo','3996 cc','Porsche Cayenne Turbo equipado de f√°brica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101369',NULL,NULL),(41,3,'KRM-CAT-DUC-01','Panigale V2 2025','Ducati Panigale V2 2025, motor V2 90¬∞.',400688.50,'Ducati','Panigale V2',2025,'moto','Gris Antracita','#4A4A4A','V2 90¬∞','955 cc','Ducati Panigale V2 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101406',NULL,'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb'),(42,3,'KRM-CAT-DUC-02','Panigale V4 2024','Ducati Panigale V4 2024, motor V4 Desmosedici Stradale.',615698.60,'Ducati','Panigale V4',2024,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Panigale V4 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101443',NULL,NULL),(43,3,'KRM-CAT-DUC-03','Panigale V4 S 2025','Ducati Panigale V4 S 2025, motor V4 Desmosedici Stradale.',584572.86,'Ducati','Panigale V4 S',2025,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Panigale V4 S equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101480',NULL,NULL),(44,3,'KRM-CAT-DUC-04','Monster 2023','Ducati Monster 2023, motor V2 Testastretta.',332543.44,'Ducati','Monster',2023,'moto','Negro Mate','#1A1A1A','V2 Testastretta','937 cc','Ducati Monster equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101517',NULL,NULL),(45,3,'KRM-CAT-DUC-05','Monster SP 2025','Ducati Monster SP 2025, motor V2 Testastretta.',374228.00,'Ducati','Monster SP',2025,'moto','Gris Antracita','#4A4A4A','V2 Testastretta','937 cc','Ducati Monster SP equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101554',NULL,NULL),(46,3,'KRM-CAT-DUC-06','Multistrada V2 2024','Ducati Multistrada V2 2024, motor V2 Testastretta.',371609.38,'Ducati','Multistrada V2',2024,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','937 cc','Ducati Multistrada V2 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101591',NULL,NULL),(47,3,'KRM-CAT-DUC-07','Multistrada V4 2023','Ducati Multistrada V4 2023, motor V4 Granturismo.',485963.66,'Ducati','Multistrada V4',2023,'moto','Blanco Dark','#E7E7E4','V4 Granturismo','1158 cc','Ducati Multistrada V4 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101628',NULL,NULL),(48,3,'KRM-CAT-DUC-08','Diavel V4 2023','Ducati Diavel V4 2023, motor V4 Granturismo.',510005.49,'Ducati','Diavel V4',2023,'moto','Rojo Ducati','#9E1B2E','V4 Granturismo','1158 cc','Ducati Diavel V4 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101665',NULL,NULL),(49,3,'KRM-CAT-DUC-09','Streetfighter V2 2023','Ducati Streetfighter V2 2023, motor V2 Testastretta.',416324.43,'Ducati','Streetfighter V2',2023,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','955 cc','Ducati Streetfighter V2 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101702',NULL,NULL),(50,3,'KRM-CAT-DUC-10','Streetfighter V4 2024','Ducati Streetfighter V4 2024, motor V4 Desmosedici Stradale.',599051.87,'Ducati','Streetfighter V4',2024,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Streetfighter V4 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101739',NULL,NULL),(51,3,'KRM-CAT-DUC-11','Scrambler Icon 2024','Ducati Scrambler Icon 2024, motor L-Twin Desmodue.',279596.86,'Ducati','Scrambler Icon',2024,'moto','Gris Antracita','#4A4A4A','L-Twin Desmodue','803 cc','Ducati Scrambler Icon equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101776',NULL,NULL),(52,3,'KRM-CAT-DUC-12','Scrambler Nightshift 2023','Ducati Scrambler Nightshift 2023, motor L-Twin Desmodue.',288140.62,'Ducati','Scrambler Nightshift',2023,'moto','Rojo Ducati','#9E1B2E','L-Twin Desmodue','803 cc','Ducati Scrambler Nightshift equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101813',NULL,NULL),(53,3,'KRM-CAT-DUC-13','DesertX 2025','Ducati DesertX 2025, motor L-Twin Testastretta.',438049.83,'Ducati','DesertX',2025,'moto','Gris Antracita','#4A4A4A','L-Twin Testastretta','937 cc','Ducati DesertX equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101850',NULL,NULL),(54,3,'KRM-CAT-DUC-14','Hypermotard 2024','Ducati Hypermotard 2024, motor V2 Testastretta.',444801.61,'Ducati','Hypermotard',2024,'moto','Rojo Ducati','#9E1B2E','V2 Testastretta','937 cc','Ducati Hypermotard equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101887',NULL,NULL),(55,3,'KRM-CAT-DUC-15','SuperSport 950 2023','Ducati SuperSport 950 2023, motor V2 Testastretta.',359002.51,'Ducati','SuperSport 950',2023,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','937 cc','Ducati SuperSport 950 equipado de f√°brica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101924',NULL,NULL),(56,4,'KRM-CAT-REF-AUDI-01','Filtro de aceite Audi','Filtro de aceite original/compatible para Audi RS5.',508.87,'Audi','RS5',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi RS5',NULL,NULL,NULL,NULL,NULL,NULL),(57,4,'KRM-CAT-REF-AUDI-02','Filtro de aire Audi','Filtro de aire original/compatible para Audi A7.',666.81,'Audi','A7',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi A7',NULL,NULL,NULL,NULL,NULL,NULL),(58,4,'KRM-CAT-REF-AUDI-03','Juego de pastillas de freno delanteras Audi','Juego de pastillas de freno delanteras original/compatible para Audi RS6.',3984.05,'Audi','RS6',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi RS6','Delantera',NULL,NULL,NULL,NULL,NULL),(59,4,'KRM-CAT-REF-AUDI-04','Juego de pastillas de freno traseras Audi','Juego de pastillas de freno traseras original/compatible para Audi R8.',3560.70,'Audi','R8',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi R8','Trasera',NULL,NULL,NULL,NULL,NULL),(60,4,'KRM-CAT-REF-AUDI-05','Disco de freno delantero Audi','Disco de freno delantero original/compatible para Audi RS3.',6580.71,'Audi','RS3',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi RS3','Delantera','Izquierdo',NULL,NULL,NULL,NULL),(61,4,'KRM-CAT-REF-AUDI-06','Disco de freno trasero Audi','Disco de freno trasero original/compatible para Audi RS3.',5907.23,'Audi','RS3',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi RS3','Trasera','Derecho',NULL,NULL,NULL,NULL),(62,4,'KRM-CAT-REF-AUDI-07','Juego de buj√≠as Audi','Juego de buj√≠as original/compatible para Audi A6.',1369.46,'Audi','A6',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi A6',NULL,NULL,NULL,NULL,NULL,NULL),(63,4,'KRM-CAT-REF-AUDI-08','Bater√≠a Audi','Bater√≠a original/compatible para Audi RS6.',4918.41,'Audi','RS6',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi RS6',NULL,NULL,NULL,NULL,NULL,NULL),(64,4,'KRM-CAT-REF-AUDI-09','Kit de distribuci√≥n Audi','Kit de distribuci√≥n original/compatible para Audi RS6.',10462.38,'Audi','RS6',NULL,'refaccion','Negro','#202124',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi RS6',NULL,NULL,NULL,NULL,NULL,NULL),(65,4,'KRM-CAT-REF-AUDI-10','Bomba de agua Audi','Bomba de agua original/compatible para Audi R8.',3312.33,'Audi','R8',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Refacci√≥n de repuesto para Audi, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Audi R8',NULL,NULL,NULL,NULL,NULL,NULL),(66,4,'KRM-CAT-REF-POR-01','Filtro de aceite Porsche','Filtro de aceite original/compatible para Porsche 911 GT3.',479.12,'Porsche','911 GT3',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche 911 GT3',NULL,NULL,NULL,NULL,NULL,NULL),(67,4,'KRM-CAT-REF-POR-02','Filtro de aire Porsche','Filtro de aire original/compatible para Porsche 718 Boxster.',662.57,'Porsche','718 Boxster',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche 718 Boxster',NULL,NULL,NULL,NULL,NULL,NULL),(68,4,'KRM-CAT-REF-POR-03','Juego de pastillas de freno delanteras Porsche','Juego de pastillas de freno delanteras original/compatible para Porsche Cayenne Turbo.',4526.14,'Porsche','Cayenne Turbo',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche Cayenne Turbo','Delantera',NULL,NULL,NULL,NULL,NULL),(69,4,'KRM-CAT-REF-POR-04','Juego de pastillas de freno traseras Porsche','Juego de pastillas de freno traseras original/compatible para Porsche Macan.',3682.97,'Porsche','Macan',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche Macan','Trasera',NULL,NULL,NULL,NULL,NULL),(70,4,'KRM-CAT-REF-POR-05','Disco de freno delantero Porsche','Disco de freno delantero original/compatible para Porsche 718 Cayman.',6518.07,'Porsche','718 Cayman',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche 718 Cayman','Delantera','Izquierdo',NULL,NULL,NULL,NULL),(71,4,'KRM-CAT-REF-POR-06','Disco de freno trasero Porsche','Disco de freno trasero original/compatible para Porsche Taycan Turbo.',6321.92,'Porsche','Taycan Turbo',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche Taycan Turbo','Trasera','Derecho',NULL,NULL,NULL,NULL),(72,4,'KRM-CAT-REF-POR-07','Juego de buj√≠as Porsche','Juego de buj√≠as original/compatible para Porsche 718 Boxster.',1503.80,'Porsche','718 Boxster',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche 718 Boxster',NULL,NULL,NULL,NULL,NULL,NULL),(73,4,'KRM-CAT-REF-POR-08','Bater√≠a Porsche','Bater√≠a original/compatible para Porsche Cayenne.',4841.58,'Porsche','Cayenne',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche Cayenne',NULL,NULL,NULL,NULL,NULL,NULL),(74,4,'KRM-CAT-REF-POR-09','Kit de distribuci√≥n Porsche','Kit de distribuci√≥n original/compatible para Porsche Macan.',9851.28,'Porsche','Macan',NULL,'refaccion','Negro','#202124',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche Macan',NULL,NULL,NULL,NULL,NULL,NULL),(75,4,'KRM-CAT-REF-POR-10','Bomba de agua Porsche','Bomba de agua original/compatible para Porsche 911 Carrera.',3385.95,'Porsche','911 Carrera',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Refacci√≥n de repuesto para Porsche, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Porsche 911 Carrera',NULL,NULL,NULL,NULL,NULL,NULL),(76,4,'KRM-CAT-REF-DUC-01','Filtro de aceite Ducati','Filtro de aceite original/compatible para Ducati Diavel V4.',407.17,'Ducati','Diavel V4',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Diavel V4',NULL,NULL,NULL,NULL,NULL,NULL),(77,4,'KRM-CAT-REF-DUC-02','Filtro de aire Ducati','Filtro de aire original/compatible para Ducati Panigale V4 S.',500.45,'Ducati','Panigale V4 S',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Panigale V4 S',NULL,NULL,NULL,NULL,NULL,NULL),(78,4,'KRM-CAT-REF-DUC-03','Juego de pastillas de freno delanteras Ducati','Juego de pastillas de freno delanteras original/compatible para Ducati Hypermotard.',2440.93,'Ducati','Hypermotard',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Hypermotard','Delantera',NULL,NULL,NULL,NULL,NULL),(79,4,'KRM-CAT-REF-DUC-04','Juego de pastillas de freno traseras Ducati','Juego de pastillas de freno traseras original/compatible para Ducati Monster.',2244.11,'Ducati','Monster',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Monster','Trasera',NULL,NULL,NULL,NULL,NULL),(80,4,'KRM-CAT-REF-DUC-05','Disco de freno delantero Ducati','Disco de freno delantero original/compatible para Ducati DesertX.',4354.51,'Ducati','DesertX',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati DesertX','Delantera','Izquierdo',NULL,NULL,NULL,NULL),(81,4,'KRM-CAT-REF-DUC-06','Cadena de transmisi√≥n Ducati','Cadena de transmisi√≥n original/compatible para Ducati Monster.',3205.62,'Ducati','Monster',NULL,'refaccion','Dorado','#B8923A',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Monster',NULL,NULL,NULL,NULL,NULL,NULL),(82,4,'KRM-CAT-REF-DUC-07','Kit de buj√≠as Ducati','Kit de buj√≠as original/compatible para Ducati Multistrada V4.',1025.26,'Ducati','Multistrada V4',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Multistrada V4',NULL,NULL,NULL,NULL,NULL,NULL),(83,4,'KRM-CAT-REF-DUC-08','Bater√≠a Ducati','Bater√≠a original/compatible para Ducati Scrambler Icon.',2547.34,'Ducati','Scrambler Icon',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Scrambler Icon',NULL,NULL,NULL,NULL,NULL,NULL),(84,4,'KRM-CAT-REF-DUC-09','Maneta de freno/embrague Ducati','Maneta de freno/embrague original/compatible para Ducati SuperSport 950.',1203.37,'Ducati','SuperSport 950',NULL,'refaccion','Negro anodizado','#2A2B2F',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati SuperSport 950',NULL,'Derecho',NULL,NULL,NULL,NULL),(85,4,'KRM-CAT-REF-DUC-10','Espejo retrovisor Ducati','Espejo retrovisor original/compatible para Ducati Panigale V4.',854.10,'Ducati','Panigale V4',NULL,'refaccion','Negro mate','#1A1A1A',NULL,NULL,'Refacci√≥n de repuesto para Ducati, verificar compatibilidad exacta por modelo/a√±o en sucursal.','Ducati Panigale V4',NULL,'Izquierdo',NULL,NULL,NULL,NULL),(86,4,'KRM-CAT-ACC-AUDI-01','Tapetes de hule para todo clima Audi Q5','Juego de tapetes de hule a la medida para Audi Q5.',3290.00,'Audi','Q5',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Juego de 4 piezas con bordes elevados.','Audi Q5',NULL,NULL,NULL,NULL,NULL,NULL),(87,4,'KRM-CAT-ACC-AUDI-02','Barras portaequipaje para techo Audi Q3','Barras transversales de aluminio para el techo del Audi Q3.',6890.00,'Audi','Q3',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Par de barras con cerradura antirrobo.','Audi Q3',NULL,NULL,NULL,NULL,NULL,NULL),(88,4,'KRM-CAT-ACC-AUDI-03','Organizador plegable de cajuela Audi','Organizador plegable con divisiones ajustables para cajuela.',1450.00,'Audi','A4',NULL,'refaccion','Negro','#202124',NULL,NULL,'Divisiones ajustables y base antiderrapante.','Audi A4 / A6 / Q5',NULL,NULL,NULL,NULL,NULL,NULL),(89,4,'KRM-CAT-ACC-POR-01','Funda de interior a la medida Porsche 911','Funda transpirable a la medida para el Porsche 911.',9850.00,'Porsche','911 Carrera',NULL,'refaccion','Gris','#6E7175',NULL,NULL,'Funda para uso en interior con bolsa de guardado.','Porsche 911 (992)',NULL,NULL,NULL,NULL,NULL,NULL),(90,4,'KRM-CAT-ACC-POR-02','Tapetes premium con ribete Porsche Macan','Tapetes de alfombra premium con ribete para Porsche Macan.',4590.00,'Porsche','Macan',NULL,'refaccion','Negro','#141414',NULL,NULL,'Juego de 4 piezas con respaldo antiderrapante.','Porsche Macan',NULL,NULL,NULL,NULL,NULL,NULL),(91,4,'KRM-CAT-ACC-POR-03','Cargador port√°til para veh√≠culo el√©ctrico Porsche Taycan','Cargador port√°til de hasta 11 kW con conector Tipo 2.',18900.00,'Porsche','Taycan',NULL,'refaccion','Negro','#1A1A1A',NULL,NULL,'Incluye estuche de transporte.','Porsche Taycan',NULL,NULL,NULL,NULL,NULL,NULL),(92,4,'KRM-CAT-ACC-DUC-01','Maletas laterales r√≠gidas Ducati Multistrada V4','Par de maletas laterales de aluminio para Multistrada V4.',21500.00,'Ducati','Multistrada V4',NULL,'refaccion','Aluminio','#BFC3C7',NULL,NULL,'Par de maletas con soportes de liberaci√≥n r√°pida.','Ducati Multistrada V4',NULL,NULL,NULL,NULL,NULL,NULL),(93,4,'KRM-CAT-ACC-DUC-02','Parabrisas touring Ducati Multistrada','Parabrisas touring de mayor altura para Multistrada.',4250.00,'Ducati','Multistrada V4',NULL,'refaccion','Transparente','#D8DDE3',NULL,NULL,'Policarbonato de 4 mm con tratamiento antirrayas.','Ducati Multistrada V2 / V4',NULL,NULL,NULL,NULL,NULL,NULL),(94,4,'KRM-CAT-ACC-DUC-03','Funda para motocicleta Ducati','Funda de exterior impermeable con protecci√≥n UV.',2890.00,'Ducati','Panigale V4',NULL,'refaccion','Negro','#1A1A1A',NULL,NULL,'Incluye orificios para candado y bolsa de transporte.','Ducati Panigale / Streetfighter',NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_productos_autogenerar
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    -- C√≥digo de barras vac√≠o = se genera con el formato KRM-CAT-‚Ä¶
    IF NEW.codigo_barras IS NULL OR TRIM(NEW.codigo_barras) = '' THEN
        SET NEW.codigo_barras = karma_generar_codigo_barras(NEW.marca, NEW.tipo);
    END IF;
    -- Solo autos y motos llevan VIN; las refacciones se quedan sin VIN
    IF NEW.tipo IN ('auto', 'moto') AND (NEW.vin IS NULL OR TRIM(NEW.vin) = '') THEN
        SET NEW.vin = karma_generar_vin(NEW.marca, NEW.anio);
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `productos_web`
--

DROP TABLE IF EXISTS `productos_web`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
  `fecha_publicacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_producto`),
  KEY `idx_productosweb_seccion` (`seccion`,`publicado`),
  CONSTRAINT `fk_productosweb_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_web`
--

LOCK TABLES `productos_web` WRITE;
/*!40000 ALTER TABLE `productos_web` DISABLE KEYS */;
INSERT INTO `productos_web` VALUES (11,'vehiculos',1,0,'nuevo','Hatchback','assets/Catalogo/vehiculos/audi/a3.webp',NULL,'S tronic de 7 velocidades','150 hp','8.4 s','El Audi A3 Sportback re√∫ne la esencia premium de Audi en un formato compacto y vers√°til. Su motor TFSI turbo responde al instante con consumos contenidos, y su interior digital con Audi virtual cockpit lo convierte en el compa√±ero ideal para la ciudad y los viajes de fin de semana.','Audi virtual cockpit de 10.25\"\nPantalla MMI t√°ctil con Apple CarPlay y Android Auto\nFaros LED con firma luminosa diurna\nControl de crucero adaptativo y asistente de carril\nModos de manejo Audi drive select\nRines de aleaci√≥n de 17\"',1,'2026-10-03 14:44:13'),(12,'vehiculos',1,0,'nuevo','Sed√°n','assets/Catalogo/vehiculos/audi/a4.webp',NULL,'S tronic de 7 velocidades','201 hp','7.3 s','El Audi A4 Sed√°n es un referente del segmento ejecutivo: aplomo en carretera, aislamiento ac√∫stico sobresaliente y una cabina que equilibra tecnolog√≠a y confort. Una elecci√≥n inteligente para quien recorre largas distancias sin renunciar a la deportividad.','Motor 2.0 TFSI con sistema mild hybrid de 12 V\nClimatizador autom√°tico de tres zonas\nAsientos delanteros con ajuste el√©ctrico\nFrenado de emergencia Audi pre sense city\nCalaveras LED con intermitentes din√°micos\nCajuela de 460 litros',2,'2026-10-03 14:44:13'),(13,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/a5.webp',NULL,'S tronic de 7 velocidades','201 hp','7.7 s','El Audi A5 Sportback combina la silueta de un coup√© con la practicidad de cinco puertas. L√≠neas fluidas, port√≥n trasero de gran apertura y un habit√°culo digital de √∫ltima generaci√≥n lo convierten en el gran turismo de la gama media.','Dise√±o Sportback de cinco puertas\nPantalla panor√°mica curva MMI\nHead-up display\nSuspensi√≥n deportiva\nSistema de audio premium de 16 bocinas\nPort√≥n trasero el√©ctrico',3,'2026-10-03 14:44:13'),(14,'vehiculos',1,1,'nuevo','Sed√°n','assets/Catalogo/vehiculos/audi/a6.webp',NULL,'S tronic de 7 velocidades','340 hp','5.1 s','El Audi A6 es la expresi√≥n del lujo progresivo: un sed√°n de gran formato con tracci√≥n quattro, motor V6 TFSI y una cabina con doble pantalla t√°ctil con respuesta h√°ptica. Confort de primera clase con la precisi√≥n din√°mica que distingue a Audi.','Motor 3.0 V6 TFSI con mild hybrid de 48 V\nTracci√≥n integral quattro\nDoble pantalla MMI touch response\nFaros HD Matrix LED\nSuspensi√≥n adaptativa\nC√°mara de 360¬∞ para estacionarse',4,'2026-10-03 14:44:13'),(15,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/a7.webp',NULL,'S tronic de 7 velocidades','340 hp','5.3 s','El Audi A7 Sportback es un gran turismo de cuatro puertas con alma de coup√©. Su dise√±o escultural, el aler√≥n trasero desplegable y la tracci√≥n quattro hacen de cada trayecto una experiencia elegante y emocionante.','Aler√≥n trasero activo\nTracci√≥n integral quattro\nFaros HD Matrix LED\nInterior en piel Valcona\nTecho panor√°mico\nPaquete de asistentes de conducci√≥n Tour',5,'2026-10-03 14:44:13'),(16,'vehiculos',1,0,'nuevo','Sed√°n de lujo','assets/Catalogo/vehiculos/audi/a8.webp',NULL,'Tiptronic de 8 velocidades','340 hp','5.6 s','El Audi A8 es el buque insignia de la marca: un sed√°n de representaci√≥n con un nivel de refinamiento, silencio y tecnolog√≠a pensado tanto para quien conduce como para quien viaja atr√°s. Cada detalle est√° dise√±ado para el m√°ximo confort.','Suspensi√≥n neum√°tica adaptativa\nAsientos con masaje y ventilaci√≥n\nIluminaci√≥n ambiental de 30 colores\nClimatizador de cuatro zonas\nPuertas con cierre asistido\nSistema de audio 3D premium',6,'2026-10-03 14:44:13'),(17,'vehiculos',1,0,'nuevo','SUV','assets/Catalogo/vehiculos/audi/q3.webp',NULL,'S tronic de 7 velocidades','190 hp','7.3 s','El Audi Q3 es la SUV compacta para la vida urbana con esp√≠ritu aventurero: posici√≥n de manejo elevada, cajuela flexible gracias a la banca trasera deslizable y tracci√≥n quattro para mayor seguridad en cualquier camino.','Tracci√≥n integral quattro\nBanca trasera deslizable y reclinable\nAudi virtual cockpit\nPort√≥n trasero el√©ctrico\nC√°mara de reversa\nSensores de estacionamiento delanteros y traseros',7,'2026-10-03 14:44:13'),(18,'vehiculos',1,1,'nuevo','SUV','assets/Catalogo/vehiculos/audi/q5.webp',NULL,'S tronic de 7 velocidades','261 hp','6.1 s','El Audi Q5 es la SUV mediana m√°s equilibrada de la gama: espacio para cinco ocupantes, tracci√≥n quattro y un motor TFSI que entrega potencia con suavidad. Ideal para la familia que busca versatilidad y prestigio.','Tracci√≥n quattro con tecnolog√≠a ultra\nFaros LED Matrix\nPantalla MMI de 10.1\"\nAlerta de tr√°fico cruzado trasero\nCajuela de 520 litros\nPreparaci√≥n para enganche de remolque',8,'2026-10-03 14:44:13'),(19,'vehiculos',1,0,'nuevo','SUV 7 plazas','assets/Catalogo/vehiculos/audi/q7.webp',NULL,'Tiptronic de 8 velocidades','335 hp','5.9 s','El Audi Q7 ofrece tres filas de asientos, tracci√≥n quattro y la serenidad de un veh√≠culo de lujo. Con su motor V6 TFSI y suspensi√≥n adaptativa, recorre ciudad y carretera con igual soltura.','Tres filas de asientos (7 plazas)\nSuspensi√≥n neum√°tica adaptativa\nTracci√≥n integral quattro\nClimatizador de cuatro zonas\nDirecci√≥n en las cuatro ruedas\nTecho panor√°mico corredizo',9,'2026-10-03 14:44:13'),(20,'vehiculos',1,0,'nuevo','SUV coup√©','assets/Catalogo/vehiculos/audi/q8.webp',NULL,'Tiptronic de 8 velocidades','335 hp','5.9 s','El Audi Q8 fusiona la elegancia de un coup√© con la presencia de una SUV de lujo. Su parrilla octagonal, las puertas sin marco y una cabina completamente digital lo posicionan como la cumbre de la familia Q.','Dise√±o SUV coup√© con puertas sin marco\nRines de 21\"\nDoble pantalla MMI touch response\nTracci√≥n integral quattro\nFaros HD Matrix LED\nAsistente de conducci√≥n en ciudad y autopista',10,'2026-10-03 14:44:13'),(21,'vehiculos',1,1,'nuevo','Deportivo compacto','assets/Catalogo/vehiculos/audi/rs3.webp',NULL,'S tronic de 7 velocidades','401 hp','3.8 s','El Audi RS 3 es un compacto de altas prestaciones impulsado por el legendario cinco cilindros turbo. Su sonido inconfundible, el diferencial RS Torque Splitter y la suspensi√≥n deportiva convierten cada curva en un momento memorable.','Motor 2.5 TFSI de cinco cilindros\nRS Torque Splitter con modo RS Torque Rear\nEscape deportivo RS\nAsientos deportivos RS con costura en panal\nFrenos de alto desempe√±o\nPantallas RS en el virtual cockpit',11,'2026-10-03 14:44:13'),(22,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/rs5.webp',NULL,'Tiptronic de 8 velocidades','444 hp','3.9 s','El Audi RS 5 Sportback combina cinco puertas con un V6 biturbo de 444 hp y tracci√≥n quattro deportiva. Es la definici√≥n de un auto de uso diario capaz de emocionar en pista.','Motor 2.9 V6 biturbo\nTracci√≥n quattro con diferencial deportivo\nSuspensi√≥n RS con Dynamic Ride Control\nPaquete de dise√±o RS en negro\nEscape deportivo RS\nVolante deportivo RS en Alcantara',12,'2026-10-03 14:44:13'),(23,'vehiculos',1,1,'nuevo','Avant','assets/Catalogo/vehiculos/audi/rs6.webp',NULL,'Tiptronic de 8 velocidades','591 hp','3.6 s','El Audi RS 6 Avant es una de las familiares m√°s deseadas del mundo: un V8 biturbo de 591 hp, carrocer√≠a ensanchada y la practicidad de una cajuela de gran capacidad. Desempe√±o de superdeportivo para el d√≠a a d√≠a.','Motor 4.0 V8 biturbo con mild hybrid\nCarrocer√≠a ensanchada exclusiva RS\nSuspensi√≥n neum√°tica adaptativa RS\nDirecci√≥n en las cuatro ruedas\nFrenos RS de alto desempe√±o\nCajuela de 565 litros',13,'2026-10-03 14:44:13'),(24,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/rs7.webp',NULL,'Tiptronic de 8 velocidades','591 hp','3.6 s','El Audi RS 7 Sportback lleva el dise√±o del A7 a su m√°xima expresi√≥n deportiva. Su V8 biturbo, la tracci√≥n quattro y la suspensi√≥n RS ofrecen un equilibrio √∫nico entre lujo, elegancia y desempe√±o.','Motor 4.0 V8 biturbo\nTracci√≥n quattro con diferencial deportivo\nFaros HD Matrix LED con luz l√°ser\nEscape deportivo RS\nAsientos RS con ventilaci√≥n y masaje\nRines de 22\"',14,'2026-10-03 14:44:13'),(25,'vehiculos',1,1,'nuevo','Superdeportivo','assets/Catalogo/vehiculos/audi/r8.webp',NULL,'S tronic de 7 velocidades','602 hp','3.1 s','El Audi R8 V10 performance es el superdeportivo nacido en las pistas de competencia. Motor central V10 atmosf√©rico, chasis de aluminio y fibra de carbono y tracci√≥n quattro para una conexi√≥n pura entre piloto y camino.','Motor central V10 5.2 FSI atmosf√©rico\nChasis Audi Space Frame de aluminio y CFRP\nTracci√≥n integral quattro\nFrenos cer√°micos disponibles\nAudi virtual cockpit con modo de pista\nEdici√≥n de producci√≥n limitada',15,'2026-10-03 14:44:13'),(26,'vehiculos',1,0,'nuevo','Coup√©','assets/Catalogo/vehiculos/porsche/718-cayman.webp',NULL,'PDK de 7 velocidades','300 hp','4.9 s','El Porsche 718 Cayman es el deportivo de motor central por excelencia: equilibrio perfecto, direcci√≥n precisa y un motor b√≥xer turbo que responde al instante. Diversi√≥n pura en cada curva.','Motor central b√≥xer turbo de cuatro cilindros\nTransmisi√≥n PDK de 7 velocidades\nPorsche Torque Vectoring\nPaquete Sport Chrono\nDos cajuelas: delantera y trasera\nFrenos de alto desempe√±o',16,'2026-10-03 14:44:13'),(27,'vehiculos',1,0,'nuevo','Roadster','assets/Catalogo/vehiculos/porsche/718-boxster.webp',NULL,'PDK de 7 velocidades','300 hp','4.9 s','El Porsche 718 Boxster es el roadster que convierte cualquier camino en un destino. Su capota el√©ctrica se abre en segundos y el motor central b√≥xer ofrece un equilibrio din√°mico excepcional.','Capota el√©ctrica de lona (apertura en 9 s)\nMotor central b√≥xer turbo\nTransmisi√≥n PDK de 7 velocidades\nPorsche Active Suspension Management (PASM)\nAsientos deportivos Plus\nPaquete Sport Chrono',17,'2026-10-03 14:44:13'),(28,'vehiculos',1,1,'nuevo','Coup√©','assets/Catalogo/vehiculos/porsche/911-carrera.webp',NULL,'PDK de 8 velocidades','379 hp','4.2 s','El Porsche 911 Carrera es el √≠cono atemporal de los autos deportivos. Su motor b√≥xer biturbo montado atr√°s, la tracci√≥n trasera y una ergonom√≠a impecable lo hacen tan disfrutable en el d√≠a a d√≠a como en un track day.','Motor b√≥xer biturbo 3.0 de seis cilindros\nTransmisi√≥n PDK de 8 velocidades\nPorsche Communication Management (PCM)\nModos de manejo con Sport Response\nRines de 19\" y 20\"\nFaros LED Matrix',18,'2026-10-03 14:44:13'),(29,'vehiculos',1,0,'nuevo','Coup√©','assets/Catalogo/vehiculos/porsche/911-carrera-s.webp',NULL,'PDK de 8 velocidades','443 hp','3.7 s','El 911 Carrera S eleva la experiencia con 443 hp, frenos de mayor di√°metro y un car√°cter a√∫n m√°s afilado. La combinaci√≥n perfecta de confort de gran turismo y desempe√±o de deportivo puro.','Motor b√≥xer biturbo de 443 hp\nCalipers rojos de seis pistones\nPASM de serie\nEscape deportivo disponible\nSport Chrono con selector de modos\nRines de 20\" y 21\"',19,'2026-10-03 14:44:13'),(30,'vehiculos',1,1,'nuevo','Coup√©','assets/Catalogo/vehiculos/porsche/911-turbo.webp',NULL,'PDK de 8 velocidades','572 hp','2.8 s','El Porsche 911 Turbo es el superdeportivo para todos los d√≠as. Tracci√≥n integral, aerodin√°mica activa y un motor biturbo de 572 hp que impulsa de 0 a 100 km/h en menos de tres segundos con una facilidad sorprendente.','Tracci√≥n integral Porsche Traction Management\nAerodin√°mica activa: spoiler y aler√≥n adaptativos\nMotor b√≥xer 3.7 biturbo\nSuspensi√≥n PASM deportiva\nInterior en piel con costuras en contraste\nSistema de audio envolvente premium',20,'2026-10-03 14:44:13'),(31,'vehiculos',1,0,'nuevo','Deportivo de pista','assets/Catalogo/vehiculos/porsche/911-gt3.webp',NULL,'PDK de 7 velocidades','502 hp','3.4 s','El 911 GT3 lleva el ADN del automovilismo a la calle: motor atmosf√©rico de 4.0 litros que gira hasta 9,000 rpm, suspensi√≥n delantera de doble horquilla derivada de competencia y aler√≥n trasero fijo para m√°xima carga aerodin√°mica.','Motor b√≥xer atmosf√©rico de 4.0 l y 9,000 rpm\nSuspensi√≥n delantera de doble horquilla\nAler√≥n trasero tipo cuello de cisne\nDirecci√≥n en el eje trasero\nFrenos cer√°micos PCCB disponibles\nModo Track Screen en el tablero',21,'2026-10-03 14:44:13'),(32,'vehiculos',1,1,'nuevo','Deportivo de pista','assets/Catalogo/vehiculos/porsche/911-gt3-rs.webp',NULL,'PDK de 7 velocidades','518 hp','3.2 s','El 911 GT3 RS es una de las versiones m√°s radicales homologadas para calle: aerodin√°mica activa con DRS, enorme carga aerodin√°mica y un motor atmosf√©rico de 518 hp. Concebido para dominar el circuito.','Sistema de reducci√≥n de arrastre (DRS)\nHasta 860 kg de carga aerodin√°mica a 285 km/h\nMotor atmosf√©rico de 518 hp\nAjustes de suspensi√≥n desde el volante\nPaquete Weissach disponible\nJaula antivuelco disponible',22,'2026-10-03 14:44:13'),(33,'vehiculos',1,0,'nuevo','Targa','assets/Catalogo/vehiculos/porsche/911-targa.webp',NULL,'PDK de 8 velocidades','379 hp','4.4 s','El 911 Targa combina la emoci√≥n de un convertible con la seguridad de un coup√© gracias a su ic√≥nico arco Targa y a un techo que se retrae autom√°ticamente. Tracci√≥n integral para disfrutarlo todo el a√±o.','Techo Targa de apertura autom√°tica\nArco Targa caracter√≠stico\nTracci√≥n integral\nTransmisi√≥n PDK de 8 velocidades\nAsientos con calefacci√≥n\nFaros LED Matrix',23,'2026-10-03 14:44:13'),(34,'vehiculos',1,0,'nuevo','Sed√°n el√©ctrico','assets/Catalogo/vehiculos/porsche/taycan.webp',NULL,'Autom√°tica de 2 velocidades (eje trasero)','402 hp','4.8 s','El Porsche Taycan es el deportivo el√©ctrico que redefine la movilidad sin emisiones: arquitectura de 800 voltios, carga ultrarr√°pida y la din√°mica de manejo que se espera de un Porsche.','Arquitectura el√©ctrica de 800 V\nCarga r√°pida en corriente directa\nAutonom√≠a estimada de hasta 500 km (WLTP)\nTransmisi√≥n de 2 velocidades en el eje trasero\nPantalla curva de 16.8\"\nPorsche Electric Sport Sound',24,'2026-10-03 14:44:13'),(35,'vehiculos',1,0,'nuevo','Sed√°n el√©ctrico','assets/Catalogo/vehiculos/porsche/taycan-turbo.webp',NULL,'Autom√°tica de 2 velocidades (eje trasero)','670 hp','3.2 s','El Taycan Turbo lleva la electrificaci√≥n al l√≠mite del desempe√±o: dos motores, tracci√≥n integral y una aceleraci√≥n contundente que se repite una y otra vez sin perder potencia.','Dos motores el√©ctricos y tracci√≥n integral\nLaunch Control con overboost\nSuspensi√≥n neum√°tica adaptativa\nPorsche Dynamic Chassis Control\nCargador a bordo de 22 kW disponible\nInterior sin piel animal disponible',25,'2026-10-03 14:44:13'),(36,'vehiculos',1,0,'nuevo','Gran turismo','assets/Catalogo/vehiculos/porsche/panamera.webp',NULL,'PDK de 8 velocidades','325 hp','5.6 s','El Porsche Panamera es el gran turismo de cuatro plazas que combina el confort de una limusina con el desempe√±o de un deportivo. Espacio, lujo y emoci√≥n para toda la familia.','Motor 2.9 V6 biturbo\nSuspensi√≥n neum√°tica adaptativa de tres c√°maras\nCuatro asientos individuales\nPorsche Advanced Cockpit\nPort√≥n trasero el√©ctrico\nAsistente de visi√≥n nocturna disponible',26,'2026-10-03 14:44:13'),(37,'vehiculos',1,0,'nuevo','Gran turismo','assets/Catalogo/vehiculos/porsche/panamera-turbo.webp',NULL,'PDK de 8 velocidades','670 hp','3.2 s','El Panamera Turbo representa la m√°xima expresi√≥n del gran turismo Porsche: potencia descomunal, tracci√≥n integral y una cabina de lujo artesanal. La forma m√°s r√°pida de viajar en primera clase.','Motor V8 biturbo de alto desempe√±o\nTracci√≥n integral Porsche Traction Management\nPorsche Active Ride disponible\nInterior en piel extendida\nPantalla para el acompa√±ante\nSistema de audio 3D de alta fidelidad',27,'2026-10-03 14:44:13'),(38,'vehiculos',1,1,'nuevo','SUV','assets/Catalogo/vehiculos/porsche/macan.webp',NULL,'PDK de 7 velocidades','261 hp','6.2 s','El Porsche Macan es el deportivo de su segmento: una SUV compacta con la agilidad y la precisi√≥n de manejo que caracterizan a la marca. Vers√°til para la ciudad y emocionante en carretera.','Tracci√≥n integral Porsche Traction Management\nMotor 2.0 turbo\nTransmisi√≥n PDK de 7 velocidades\nPantalla t√°ctil PCM de 10.9\"\nPort√≥n trasero el√©ctrico\nModo Offroad',28,'2026-10-03 14:44:13'),(39,'vehiculos',1,0,'nuevo','SUV','assets/Catalogo/vehiculos/porsche/cayenne.webp',NULL,'Tiptronic S de 8 velocidades','335 hp','5.9 s','El Porsche Cayenne es la SUV que demostr√≥ que lujo, espacio y deportividad pueden convivir: interior amplio, gran capacidad de remolque y el manejo inconfundible de un Porsche.','Motor 3.0 V6 turbo\nTracci√≥n integral\nSuspensi√≥n neum√°tica disponible\nCapacidad de remolque de hasta 3,500 kg\nCajuela de 772 litros\nPorsche InnoDrive con crucero adaptativo',29,'2026-10-03 14:44:13'),(40,'vehiculos',1,0,'nuevo','SUV coup√©','assets/Catalogo/vehiculos/porsche/cayenne-turbo.webp',NULL,'Tiptronic S de 8 velocidades','541 hp','3.9 s','El Cayenne Turbo combina la presencia de una SUV de lujo con la potencia de un V8 biturbo: aceleraci√≥n de deportivo, tracci√≥n integral y un interior premium para cinco ocupantes.','Motor 4.0 V8 biturbo\nTracci√≥n integral\nPorsche Dynamic Chassis Control\nFrenos Porsche Surface Coated Brake\nEscape deportivo\nAsientos deportivos adaptativos de 18 posiciones',30,'2026-10-03 14:44:13'),(41,'vehiculos',1,0,'nuevo','Superdeportiva','assets/Catalogo/vehiculos/ducati/panigale-v2.webp',NULL,'6 velocidades con Ducati Quick Shift','155 hp','3.2 s','La Ducati Panigale V2 es la superdeportiva bicil√≠ndrica que ofrece las sensaciones de la familia Panigale con un car√°cter m√°s ligero y accesible. Ideal para dar el salto a la pista.','Motor Superquadro bicil√≠ndrico de 955 cc\nDucati Quick Shift up & down\nControl de tracci√≥n y ABS en curva\nPantalla TFT a color\nBasculante monobrazo\nModos de manejo Race, Sport y Street',31,'2026-10-03 14:44:13'),(42,'vehiculos',1,1,'nuevo','Superdeportiva','assets/Catalogo/vehiculos/ducati/panigale-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','215 hp','2.9 s','La Panigale V4 traslada la tecnolog√≠a de MotoGP a la calle: motor Desmosedici Stradale V4 de 1,103 cc, aerodin√°mica con alerones y un paquete electr√≥nico de √∫ltima generaci√≥n.','Motor Desmosedici Stradale V4 de 1,103 cc\nAlerones aerodin√°micos de doble perfil\nDucati Traction Control y Slide Control\nLaunch Control\nPantalla TFT de 5\"\nChasis Front Frame de aluminio',32,'2026-10-03 14:44:13'),(43,'vehiculos',1,0,'nuevo','Superdeportiva','assets/Catalogo/vehiculos/ducati/panigale-v4-s.webp',NULL,'6 velocidades con Ducati Quick Shift','216 hp','2.8 s','La Panigale V4 S suma suspensiones electr√≥nicas √ñhlins, rines forjados y bater√≠a de litio a la f√≥rmula de la Panigale V4. Es la referencia para quienes buscan el m√°ximo desempe√±o en pista.','Suspensiones electr√≥nicas √ñhlins Smart EC 2.0\nRines forjados de aluminio\nBater√≠a de iones de litio\nFrenos Brembo Stylema\nABS Cornering EVO\nPeso reducido en orden de marcha',33,'2026-10-03 14:44:13'),(44,'vehiculos',1,1,'nuevo','Naked','assets/Catalogo/vehiculos/ducati/monster.webp',NULL,'6 velocidades con Ducati Quick Shift','111 hp','3.6 s','La Ducati Monster es la naked deportiva que invent√≥ un segmento: ligera, √°gil y con un motor Testastretta de car√°cter vibrante. Perfecta para el uso diario y la diversi√≥n del fin de semana.','Motor Testastretta 11¬∞ de 937 cc\n188 kg en orden de marcha\nDucati Quick Shift\nControl de tracci√≥n y ABS en curva\nTablero TFT de 4.3\"\nAsiento de altura ajustable',34,'2026-10-03 14:44:13'),(45,'vehiculos',1,0,'nuevo','Naked','assets/Catalogo/vehiculos/ducati/monster-sp.webp',NULL,'6 velocidades con Ducati Quick Shift','111 hp','3.5 s','La Monster SP es la versi√≥n m√°s deportiva de la Monster: suspensiones √ñhlins, escape deportivo homologado y frenos Brembo Stylema para un manejo a√∫n m√°s preciso.','Suspensiones √ñhlins totalmente ajustables\nFrenos Brembo Stylema\nEscape deportivo homologado\nBater√≠a de litio\nAmortiguador de direcci√≥n\nGr√°ficos SP exclusivos',35,'2026-10-03 14:44:13'),(46,'vehiculos',1,0,'nuevo','Adventure touring','assets/Catalogo/vehiculos/ducati/multistrada-v2.webp',NULL,'6 velocidades con Ducati Quick Shift','113 hp','3.9 s','La Multistrada V2 es la compa√±era ideal para viajar: posici√≥n de manejo c√≥moda, buena protecci√≥n aerodin√°mica y un motor Testastretta suave y el√°stico. Varias motos en una para cualquier tipo de camino.','Motor Testastretta de 937 cc\nParabrisas ajustable\nCuatro modos de manejo\nControl de crucero\nAsiento de altura ajustable\nPreparada para maletas laterales',36,'2026-10-03 14:44:13'),(47,'vehiculos',1,1,'nuevo','Adventure touring','assets/Catalogo/vehiculos/ducati/multistrada-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','170 hp','3.3 s','La Multistrada V4 combina un motor V4 Granturismo de 170 hp con radar delantero y trasero para una experiencia de viaje segura y tecnol√≥gica. Lista para cruzar continentes.','Motor V4 Granturismo de 1,158 cc\nRadar delantero y trasero con crucero adaptativo\nPantalla TFT de 6.5\" con navegaci√≥n\nSuspensi√≥n semiactiva Skyhook\nServicio de v√°lvulas cada 60,000 km\nFaros full LED con luz de curva',37,'2026-10-03 14:44:13'),(48,'vehiculos',1,0,'nuevo','Power cruiser','assets/Catalogo/vehiculos/ducati/diavel-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','168 hp','2.6 s','La Diavel V4 es la power cruiser m√°s deportiva: dise√±o musculoso, motor V4 Granturismo y la capacidad de acelerar como una superdeportiva con la comodidad de una cruiser.','Motor V4 Granturismo de 1,158 cc\nLlanta trasera de 240 mm\nDucati Power Launch\nEscape de cuatro salidas\nIluminaci√≥n full LED con firma distintiva\nPosici√≥n de manejo relajada',38,'2026-10-03 14:44:13'),(49,'vehiculos',1,0,'nuevo','Naked deportiva','assets/Catalogo/vehiculos/ducati/streetfighter-v2.webp',NULL,'6 velocidades con Ducati Quick Shift','153 hp','3.1 s','La Streetfighter V2 es una superdeportiva sin carenado: motor Superquadro de 955 cc, manubrio ancho y un dise√±o agresivo inspirado en la Panigale. Adrenalina pura para la calle.','Motor Superquadro de 955 cc\nManubrio ancho de aluminio\nBasculante monobrazo\nControl de wheelie\nFrenos Brembo de anclaje radial\nPantalla TFT a color',39,'2026-10-03 14:44:13'),(50,'vehiculos',1,1,'nuevo','Naked deportiva','assets/Catalogo/vehiculos/ducati/streetfighter-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','208 hp','2.9 s','La Streetfighter V4 es una Panigale sin carenado: motor Desmosedici Stradale de 208 hp, alerones biplano y un paquete electr√≥nico de competencia en una naked de dise√±o inconfundible.','Motor Desmosedici Stradale V4 de 1,103 cc\nAlerones biplano\nControl de tracci√≥n y wheelie EVO\nFaros full LED con firma frontal distintiva\nDucati Quick Shift EVO\nPantalla TFT de 5\"',40,'2026-10-03 14:44:13'),(51,'vehiculos',1,0,'nuevo','Scrambler','assets/Catalogo/vehiculos/ducati/scrambler-icon.webp',NULL,'6 velocidades','73 hp','4.6 s','La Scrambler Icon es sin√≥nimo de libertad: estilo atemporal, motor bicil√≠ndrico enfriado por aire f√°cil de manejar y una ergonom√≠a amigable para todos los niveles. Perfecta para la ciudad y las escapadas.','Motor L-Twin de 803 cc enfriado por aire\nPeso ligero y asiento bajo\nFaro con luz diurna en forma de X\nControl de tracci√≥n\nCubiertas de tanque intercambiables\nTablero digital',41,'2026-10-03 14:44:13'),(52,'vehiculos',1,0,'nuevo','Scrambler','assets/Catalogo/vehiculos/ducati/scrambler-nightshift.webp',NULL,'6 velocidades','73 hp','4.6 s','La Scrambler Nightshift interpreta el estilo caf√© racer con un toque urbano: rines de rayos, manubrio plano y acabados oscuros que destacan en cualquier calle.','Rines de rayos\nManubrio plano\nEspejos en los extremos del manubrio\nMotor L-Twin de 803 cc\nAsiento con tapizado especial\nAcabados en color oscuro',42,'2026-10-03 14:44:13'),(53,'vehiculos',1,0,'nuevo','Adventure off-road','assets/Catalogo/vehiculos/ducati/desertx.webp',NULL,'6 velocidades con Ducati Quick Shift','110 hp','3.9 s','La DesertX est√° inspirada en las legendarias motos de rally: rin delantero de 21\", suspensiones de largo recorrido y modos de manejo off-road para explorar m√°s all√° del asfalto.','Rin delantero de 21\" y trasero de 18\"\nSuspensiones de largo recorrido\nModos de manejo Rally y Enduro\nTanque de 21 litros\nPantalla TFT vertical\nProtector de motor de aluminio',43,'2026-10-03 14:44:13'),(54,'vehiculos',1,0,'nuevo','Motard','assets/Catalogo/vehiculos/ducati/hypermotard.webp',NULL,'6 velocidades con Ducati Quick Shift','114 hp','3.4 s','La Hypermotard es pura diversi√≥n: geometr√≠a de supermotard, posici√≥n elevada y un motor Testastretta que invita a jugar en cada curva. Ligera, divertida e irreverente.','Motor Testastretta de 937 cc\nEscape bajo el asiento\nSuspensiones de largo recorrido\nModo Slide by Brake\n178 kg en seco\nManubrio ancho de aluminio',44,'2026-10-03 14:44:13'),(55,'vehiculos',1,0,'nuevo','Sport touring','assets/Catalogo/vehiculos/ducati/supersport-950.webp',NULL,'6 velocidades con Ducati Quick Shift','110 hp','3.6 s','La SuperSport 950 es la deportiva de uso diario: posici√≥n de manejo c√≥moda, protecci√≥n aerodin√°mica y un motor Testastretta suave. Ideal para quien quiere estilo deportivo con confort para viajar.','Motor Testastretta 11¬∞ de 937 cc\nParabrisas ajustable\nDise√±o inspirado en la Panigale V4\nLuces de curva Ducati Cornering Lights\nPantalla TFT de 4.3\"\nAsiento confortable para dos personas',45,'2026-10-03 14:44:13'),(56,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/audi/filtro-aceite.webp',NULL,NULL,NULL,NULL,'Filtro de aceite de alta eficiencia para Audi RS5. Retiene part√≠culas met√°licas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.','Compatible con Audi RS5\nMedio filtrante de alta retenci√≥n\nIncluye empaque de sellado\nReemplazo recomendado en cada servicio\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',46,'2026-10-03 14:44:13'),(57,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/audi/filtro-aire.webp',NULL,NULL,NULL,NULL,'Filtro de aire con medio de celulosa reforzada que asegura el flujo √≥ptimo de aire limpio al motor de Audi A7, protegiendo sus componentes y manteniendo el desempe√±o.','Compatible con Audi A7\nCelulosa reforzada de alta captaci√≥n\nMarco de poliuretano flexible\nRevisi√≥n recomendada cada 15,000 km\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',47,'2026-10-03 14:44:13'),(58,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/pastillas-delanteras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricci√≥n, dise√±adas para Audi RS6. Frenado firme y silencioso desde la primera aplicaci√≥n.','Compatible con Audi RS6\nCompuesto cer√°mico de bajo polvo\nIncluye l√°minas antirruido\nJuego para eje delantero\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',48,'2026-10-03 14:44:13'),(59,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/pastillas-traseras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricci√≥n, dise√±adas para Audi R8. Frenado estable y silencioso.','Compatible con Audi R8\nCompuesto cer√°mico de bajo polvo\nIncluye l√°minas antirruido\nJuego para eje trasero\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',49,'2026-10-03 14:44:13'),(60,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/disco-delantero.webp',NULL,NULL,NULL,NULL,'Disco de freno delantero ventilado de hierro de alta resistencia para Audi RS3. Disipa el calor de forma eficiente y mantiene un frenado constante.','Compatible con Audi RS3\nDise√±o ventilado y perforado\nTratamiento anticorrosi√≥n\nSe recomienda cambiar en pares\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',50,'2026-10-03 14:44:13'),(61,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/disco-trasero.webp',NULL,NULL,NULL,NULL,'Disco de freno trasero de hierro de alta resistencia para Audi RS3, balanceado para una operaci√≥n sin vibraciones y con excelente disipaci√≥n de calor.','Compatible con Audi RS3\nBalanceado de f√°brica\nTratamiento anticorrosi√≥n\nSe recomienda cambiar en pares\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',51,'2026-10-03 14:44:13'),(62,'refacciones',1,0,'nuevo','Encendido y el√©ctrico','assets/Catalogo/refacciones/audi/bujias.webp',NULL,NULL,NULL,NULL,'Juego de buj√≠as con electrodo de iridio para Audi A6. Encendido preciso, arranque confiable y consumo optimizado.','Compatible con Audi A6\nElectrodo central de iridio\nCalibraci√≥n de f√°brica\nJuego completo para el motor\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',52,'2026-10-03 14:44:13'),(63,'refacciones',1,0,'nuevo','Encendido y el√©ctrico','assets/Catalogo/refacciones/audi/bateria.webp',NULL,NULL,NULL,NULL,'Bater√≠a de 12 V libre de mantenimiento para Audi RS6, con alta capacidad de arranque en fr√≠o y construcci√≥n resistente a vibraciones.','Compatible con Audi RS6\n12 V libre de mantenimiento\nAlta corriente de arranque en fr√≠o\nInstalaci√≥n incluida en sucursal\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',53,'2026-10-03 14:44:13'),(64,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/audi/kit-distribucion.webp',NULL,NULL,NULL,NULL,'Kit de distribuci√≥n completo para Audi RS6: incluye banda, tensor y poleas para garantizar la sincronizaci√≥n exacta del motor.','Compatible con Audi RS6\nIncluye banda, tensor y poleas\nInstalaci√≥n recomendada en taller\nReemplazo preventivo seg√∫n kilometraje\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',54,'2026-10-03 14:44:13'),(65,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/audi/bomba-agua.webp',NULL,NULL,NULL,NULL,'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Audi R8. Mantiene la temperatura √≥ptima de operaci√≥n del motor.','Compatible con Audi R8\nCarcasa de aluminio\nImpulsor de alto flujo\nIncluye empaque\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',55,'2026-10-03 14:44:13'),(66,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/porsche/filtro-aceite.webp',NULL,NULL,NULL,NULL,'Filtro de aceite de alta eficiencia para Porsche 911 GT3. Retiene part√≠culas met√°licas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.','Compatible con Porsche 911 GT3\nMedio filtrante de alta retenci√≥n\nIncluye empaque de sellado\nReemplazo recomendado en cada servicio\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',56,'2026-10-03 14:44:13'),(67,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/porsche/filtro-aire.webp',NULL,NULL,NULL,NULL,'Filtro de aire con medio de celulosa reforzada que asegura el flujo √≥ptimo de aire limpio al motor de Porsche 718 Boxster, protegiendo sus componentes y manteniendo el desempe√±o.','Compatible con Porsche 718 Boxster\nCelulosa reforzada de alta captaci√≥n\nMarco de poliuretano flexible\nRevisi√≥n recomendada cada 15,000 km\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',57,'2026-10-03 14:44:13'),(68,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/pastillas-delanteras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricci√≥n, dise√±adas para Porsche Cayenne Turbo. Frenado firme y silencioso desde la primera aplicaci√≥n.','Compatible con Porsche Cayenne Turbo\nCompuesto cer√°mico de bajo polvo\nIncluye l√°minas antirruido\nJuego para eje delantero\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',58,'2026-10-03 14:44:13'),(69,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/pastillas-traseras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricci√≥n, dise√±adas para Porsche Macan. Frenado estable y silencioso.','Compatible con Porsche Macan\nCompuesto cer√°mico de bajo polvo\nIncluye l√°minas antirruido\nJuego para eje trasero\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',59,'2026-10-03 14:44:13'),(70,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/disco-delantero.webp',NULL,NULL,NULL,NULL,'Disco de freno delantero ventilado de hierro de alta resistencia para Porsche 718 Cayman. Disipa el calor de forma eficiente y mantiene un frenado constante.','Compatible con Porsche 718 Cayman\nDise√±o ventilado y perforado\nTratamiento anticorrosi√≥n\nSe recomienda cambiar en pares\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',60,'2026-10-03 14:44:13'),(71,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/disco-trasero.webp',NULL,NULL,NULL,NULL,'Disco de freno trasero de hierro de alta resistencia para Porsche Taycan Turbo, balanceado para una operaci√≥n sin vibraciones y con excelente disipaci√≥n de calor.','Compatible con Porsche Taycan Turbo\nBalanceado de f√°brica\nTratamiento anticorrosi√≥n\nSe recomienda cambiar en pares\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',61,'2026-10-03 14:44:13'),(72,'refacciones',1,0,'nuevo','Encendido y el√©ctrico','assets/Catalogo/refacciones/porsche/bujias.webp',NULL,NULL,NULL,NULL,'Juego de buj√≠as con electrodo de iridio para Porsche 718 Boxster. Encendido preciso, arranque confiable y consumo optimizado.','Compatible con Porsche 718 Boxster\nElectrodo central de iridio\nCalibraci√≥n de f√°brica\nJuego completo para el motor\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',62,'2026-10-03 14:44:13'),(73,'refacciones',1,0,'nuevo','Encendido y el√©ctrico','assets/Catalogo/refacciones/porsche/bateria.webp',NULL,NULL,NULL,NULL,'Bater√≠a de 12 V libre de mantenimiento para Porsche Cayenne, con alta capacidad de arranque en fr√≠o y construcci√≥n resistente a vibraciones.','Compatible con Porsche Cayenne\n12 V libre de mantenimiento\nAlta corriente de arranque en fr√≠o\nInstalaci√≥n incluida en sucursal\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',63,'2026-10-03 14:44:13'),(74,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/porsche/kit-distribucion.webp',NULL,NULL,NULL,NULL,'Kit de distribuci√≥n completo para Porsche Macan: incluye banda, tensor y poleas para garantizar la sincronizaci√≥n exacta del motor.','Compatible con Porsche Macan\nIncluye banda, tensor y poleas\nInstalaci√≥n recomendada en taller\nReemplazo preventivo seg√∫n kilometraje\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',64,'2026-10-03 14:44:13'),(75,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/porsche/bomba-agua.webp',NULL,NULL,NULL,NULL,'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Porsche 911 Carrera. Mantiene la temperatura √≥ptima de operaci√≥n del motor.','Compatible con Porsche 911 Carrera\nCarcasa de aluminio\nImpulsor de alto flujo\nIncluye empaque\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',65,'2026-10-03 14:44:13'),(76,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/ducati/filtro-aceite.webp',NULL,NULL,NULL,NULL,'Filtro de aceite de alta eficiencia para Ducati Diavel V4. Retiene part√≠culas met√°licas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.','Compatible con Ducati Diavel V4\nMedio filtrante de alta retenci√≥n\nIncluye empaque de sellado\nReemplazo recomendado en cada servicio\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',66,'2026-10-03 14:44:13'),(77,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/ducati/filtro-aire.webp',NULL,NULL,NULL,NULL,'Filtro de aire con medio de celulosa reforzada que asegura el flujo √≥ptimo de aire limpio al motor de Ducati Panigale V4 S, protegiendo sus componentes y manteniendo el desempe√±o.','Compatible con Ducati Panigale V4 S\nCelulosa reforzada de alta captaci√≥n\nMarco de poliuretano flexible\nRevisi√≥n recomendada cada 15,000 km\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',67,'2026-10-03 14:44:13'),(78,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/ducati/pastillas-delanteras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricci√≥n, dise√±adas para Ducati Hypermotard. Frenado firme y silencioso desde la primera aplicaci√≥n.','Compatible con Ducati Hypermotard\nCompuesto cer√°mico de bajo polvo\nIncluye l√°minas antirruido\nJuego para eje delantero\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',68,'2026-10-03 14:44:13'),(79,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/ducati/pastillas-traseras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricci√≥n, dise√±adas para Ducati Monster. Frenado estable y silencioso.','Compatible con Ducati Monster\nCompuesto cer√°mico de bajo polvo\nIncluye l√°minas antirruido\nJuego para eje trasero\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',69,'2026-10-03 14:44:13'),(80,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/ducati/disco-delantero.webp',NULL,NULL,NULL,NULL,'Disco de freno delantero ventilado de hierro de alta resistencia para Ducati DesertX. Disipa el calor de forma eficiente y mantiene un frenado constante.','Compatible con Ducati DesertX\nDise√±o ventilado y perforado\nTratamiento anticorrosi√≥n\nSe recomienda cambiar en pares\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',70,'2026-10-03 14:44:13'),(81,'refacciones',1,0,'nuevo','Transmisi√≥n','assets/Catalogo/refacciones/ducati/cadena-transmision.webp',NULL,NULL,NULL,NULL,'Cadena de transmisi√≥n con retenes X-Ring para Ducati Monster. Mayor durabilidad y menor fricci√≥n al transmitir la potencia del motor a la rueda trasera.','Compatible con Ducati Monster\nRetenes X-Ring\nEslab√≥n de uni√≥n remachable\nLubricaci√≥n de larga duraci√≥n\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',71,'2026-10-03 14:44:13'),(82,'refacciones',1,0,'nuevo','Encendido y el√©ctrico','assets/Catalogo/refacciones/ducati/kit-bujias.webp',NULL,NULL,NULL,NULL,'Juego de buj√≠as con electrodo de iridio para Ducati Multistrada V4. Encendido preciso, arranque confiable y consumo optimizado.','Compatible con Ducati Multistrada V4\nElectrodo central de iridio\nCalibraci√≥n de f√°brica\nJuego completo para el motor\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',72,'2026-10-03 14:44:13'),(83,'refacciones',1,0,'nuevo','Encendido y el√©ctrico','assets/Catalogo/refacciones/ducati/bateria.webp',NULL,NULL,NULL,NULL,'Bater√≠a de 12 V libre de mantenimiento para Ducati Scrambler Icon, con alta capacidad de arranque en fr√≠o y construcci√≥n resistente a vibraciones.','Compatible con Ducati Scrambler Icon\n12 V libre de mantenimiento\nAlta corriente de arranque en fr√≠o\nInstalaci√≥n incluida en sucursal\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',73,'2026-10-03 14:44:13'),(84,'refacciones',1,0,'nuevo','Controles','assets/Catalogo/refacciones/ducati/maneta-freno-embrague.webp',NULL,NULL,NULL,NULL,'Maneta de freno/embrague de aluminio anodizado con ajuste de distancia para Ducati SuperSport 950. Tacto preciso y ergonom√≠a mejorada.','Compatible con Ducati SuperSport 950\nAluminio anodizado\nAjuste de distancia en 6 posiciones\nInstalaci√≥n directa\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',74,'2026-10-03 14:44:13'),(85,'refacciones',1,0,'nuevo','Carrocer√≠a','assets/Catalogo/refacciones/ducati/espejo-retrovisor.webp',NULL,NULL,NULL,NULL,'Espejo retrovisor con cristal antirreflejante y soporte reforzado para Ducati Panigale V4. Visibilidad amplia con dise√±o aerodin√°mico.','Compatible con Ducati Panigale V4\nCristal antirreflejante\nSoporte reforzado\nAjuste en varias posiciones\nGarant√≠a de 6 meses contra defectos de fabricaci√≥n',75,'2026-10-03 14:44:13'),(86,'accesorios',1,0,'nuevo','Interior','assets/Catalogo/accesorios/tapetes-audi.webp',NULL,NULL,NULL,NULL,'Juego de tapetes de hule moldeados a la medida del Audi Q5. Sus bordes elevados retienen agua, lodo y arena, protegiendo la alfombra original en cualquier temporada.','Compatible con Audi Q5\nJuego de 4 piezas a la medida\nBordes elevados que contienen l√≠quidos\nMaterial antiderrapante y f√°cil de lavar\nAnclajes de fijaci√≥n originales',76,'2026-10-03 14:44:13'),(87,'accesorios',1,0,'nuevo','Exterior','assets/Catalogo/accesorios/barras-techo-audi.webp',NULL,NULL,NULL,NULL,'Barras transversales de aluminio aerodin√°mico para el Audi Q3. Base ideal para portabicicletas, portaesqu√≠s o cajas de techo, con sistema de bloqueo antirrobo.','Compatible con Audi Q3\nPerfil aerodin√°mico de bajo ruido\nCapacidad de carga de 75 kg\nCerradura con llave antirrobo\nInstalaci√≥n sin herramientas especiales',77,'2026-10-03 14:44:13'),(88,'accesorios',1,0,'nuevo','Organizaci√≥n','assets/Catalogo/accesorios/organizador-cajuela-audi.webp',NULL,NULL,NULL,NULL,'Organizador plegable con divisiones ajustables que mantiene en orden las compras, herramientas y art√≠culos deportivos dentro de la cajuela.','Compatible con Audi A4 / A6 / Q5\nDivisiones ajustables con velcro\nBase antiderrapante\nSe pliega cuando no se usa\nCompatible con A4, A6 y Q5',78,'2026-10-03 14:44:13'),(89,'accesorios',1,0,'nuevo','Protecci√≥n','assets/Catalogo/accesorios/funda-interior-porsche.webp',NULL,NULL,NULL,NULL,'Funda transpirable a la medida del Porsche 911 para uso en interior. Protege la pintura del polvo y los rayones mientras permite la circulaci√≥n del aire.','Compatible con Porsche 911 (992)\nCorte a la medida del 911 (992)\nTejido suave y transpirable\nInterior afelpado que cuida la pintura\nIncluye bolsa de almacenamiento',79,'2026-10-03 14:44:13'),(90,'accesorios',1,0,'nuevo','Interior','assets/Catalogo/accesorios/tapetes-premium-porsche.webp',NULL,NULL,NULL,NULL,'Tapetes de alfombra premium con ribete y respaldo antiderrapante, dise√±ados a la medida del Porsche Macan.','Compatible con Porsche Macan\nAlfombra de alta densidad\nRibete en piel sint√©tica\nRespaldo antiderrapante\nJuego de 4 piezas',80,'2026-10-03 14:44:13'),(91,'accesorios',1,0,'nuevo','Carga el√©ctrica','assets/Catalogo/accesorios/cargador-portatil-porsche.webp',NULL,NULL,NULL,NULL,'Cargador port√°til de hasta 11 kW con conector Tipo 2 para el Porsche Taycan. Permite cargar en casa o en cualquier contacto industrial compatible.','Compatible con Porsche Taycan\nPotencia de carga de hasta 11 kW\nConector Tipo 2\nCable de 7.5 metros\nEstuche de transporte incluido',81,'2026-10-03 14:44:13'),(92,'accesorios',1,0,'nuevo','Equipaje','assets/Catalogo/accesorios/maletas-laterales-ducati.webp',NULL,NULL,NULL,NULL,'Par de maletas laterales r√≠gidas de aluminio con cierre herm√©tico para la Multistrada V4. Capacidad suficiente para viajes largos con total protecci√≥n contra la lluvia.','Compatible con Ducati Multistrada V4\nCapacidad de 30 y 37 litros\nAluminio anodizado resistente\nCierre herm√©tico con llave\nSoportes de liberaci√≥n r√°pida',82,'2026-10-03 14:44:13'),(93,'accesorios',1,0,'nuevo','Exterior','assets/Catalogo/accesorios/parabrisas-touring-ducati.webp',NULL,NULL,NULL,NULL,'Parabrisas touring de mayor altura que reduce la turbulencia y la fatiga en viajes largos. Policarbonato resistente a impactos con tratamiento antirrayas.','Compatible con Ducati Multistrada V2 / V4\nPolicarbonato de 4 mm\nTratamiento antirrayas\n60 mm m√°s alto que el original\nCompatible con Multistrada V2 y V4',83,'2026-10-03 14:44:13'),(94,'accesorios',1,0,'nuevo','Protecci√≥n','assets/Catalogo/accesorios/funda-moto-ducati.webp',NULL,NULL,NULL,NULL,'Funda de exterior impermeable con protecci√≥n UV y forro suave. Mantiene tu Ducati limpia y protegida del sol, la lluvia y el polvo.','Compatible con Ducati Panigale / Streetfighter\nTela impermeable con protecci√≥n UV\nForro interior suave\nOrificios para candado\nBolsa de transporte incluida',84,'2026-10-03 14:44:13');
/*!40000 ALTER TABLE `productos_web` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promociones`
--

DROP TABLE IF EXISTS `promociones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `promociones` (
  `id_promocion` int(11) NOT NULL AUTO_INCREMENT,
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
  `orden` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_promocion`),
  UNIQUE KEY `uq_promociones_clave` (`clave`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promociones`
--

LOCK TABLES `promociones` WRITE;
/*!40000 ALTER TABLE `promociones` DISABLE KEYS */;
INSERT INTO `promociones` VALUES (1,'audi-q5-bono','Bono de $40,000 en Audi Q5','SUV mediana con tracci√≥n quattro','Estrena tu Audi Q5 2025 con un bono aplicable al cerrar tu compra en cualquiera de nuestras sucursales.','vehiculos','Audi','Bono $40,000','assets/Catalogo/vehiculos/audi/q5.webp','Promoci√≥n de demostraci√≥n del proyecto acad√©mico KARMA. Aplica sobre precio de lista, sujeta a disponibilidad de inventario en la sucursal.','2026-10-01','2026-12-31','Ver Audi Q5','vehiculo.php?codigo=KRM-CAT-AUDI-08',1,1),(2,'porsche-macan-tasa','Tasa preferencial desde 11.9% en Porsche Macan','Plan de cr√©dito KARMA Financial','Financia tu Porsche Macan con una tasa preferencial y plazos de hasta 60 meses. Simula tu mensualidad en l√≠nea.','financiamiento','Porsche','11.9% anual','assets/Catalogo/vehiculos/porsche/macan.webp','Promoci√≥n de demostraci√≥n. Tasa fija anual de referencia con enganche m√≠nimo del 20%; sujeta a aprobaci√≥n de cr√©dito.','2026-10-01','2026-12-31','Simular financiamiento','financiamiento.php?codigo=KRM-CAT-POR-13&tasa=11.9',1,2),(3,'ducati-multistrada-maletas','Maletas laterales con 15% al estrenar tu Multistrada V4','Listo para viajar desde el primer d√≠a','Al comprar tu Ducati Multistrada V4 obt√©n 15% de descuento en el juego de maletas laterales r√≠gidas.','accesorios','Ducati','-15% accesorios','assets/Catalogo/accesorios/maletas-laterales-ducati.webp','Promoci√≥n de demostraci√≥n. Aplica en sucursal al momento de la compra de la motocicleta.','2026-10-01','2026-12-31','Ver Multistrada V4','vehiculo.php?codigo=KRM-CAT-DUC-07',1,3),(4,'servicio-aceite','Cambio de aceite y filtro desde $2,490','Servicio express en menos de 90 minutos','Incluye aceite sint√©tico de especificaci√≥n de f√°brica, filtro nuevo y revisi√≥n de 25 puntos.','servicio',NULL,'Desde $2,490','assets/Catalogo/servicios/cambio-aceite.webp','Promoci√≥n de demostraci√≥n. Precio de referencia para autos de hasta 6 litros de aceite; motocicletas desde $1,690.','2026-10-01','2026-12-31','Agendar servicio','agendar.php?tipo=servicio&servicio=Cambio%20de%20aceite%20y%20filtro',1,4),(5,'servicio-frenos','Revisi√≥n de frenos sin costo','Tu seguridad primero','Medimos el espesor de pastillas y discos, revisamos el l√≠quido de frenos y te entregamos un diagn√≥stico por escrito.','servicio',NULL,'Sin costo','assets/Catalogo/servicios/frenos.webp','Promoci√≥n de demostraci√≥n. Una revisi√≥n por veh√≠culo durante la vigencia; requiere cita previa.','2026-10-01','2026-11-30','Agendar revisi√≥n','agendar.php?tipo=servicio&servicio=Servicio%20de%20frenos',1,5),(6,'refacciones-instalacion','Instalaci√≥n sin costo en pastillas y discos','Compra en l√≠nea, instala en nuestro taller','Compra tus pastillas o discos de freno en l√≠nea, recoge en sucursal y nuestro taller los instala sin costo de mano de obra.','refacciones',NULL,'Instalaci√≥n gratis','assets/Catalogo/refacciones/porsche/disco-delantero.webp','Promoci√≥n de demostraci√≥n. Requiere cita de servicio en la misma sucursal donde se recoge el pedido.','2026-10-01','2026-12-31','Ver refacciones de frenos','refacciones.php?categoria=Frenos',1,6),(7,'envio-gratis','Env√≠o gratis en compras desde $3,000','Refacciones y accesorios a domicilio','Tus refacciones y accesorios llegan a domicilio sin costo de env√≠o cuando tu pedido es de $3,000 o m√°s.','accesorios',NULL,'Env√≠o gratis','assets/Catalogo/accesorios/tapetes-audi.webp','Promoci√≥n de demostraci√≥n. Aplica autom√°ticamente en el checkout para pedidos con env√≠o y pago con tarjeta.','2026-10-01','2026-12-31','Ver accesorios','accesorios.php',1,7),(8,'prueba-manejo-kit','Agenda tu prueba de manejo y recibe un kit de bienvenida','Vive la experiencia antes de decidir','Agenda en l√≠nea tu prueba de manejo en Manzanillo o Colima y ll√©vate un kit de bienvenida KARMA.','vehiculos',NULL,'Regalo','assets/Catalogo/banners/prueba-manejo.webp','Promoci√≥n de demostraci√≥n. Un kit por cliente; sujeto a existencias en la sucursal.','2026-10-01','2026-12-31','Agendar prueba de manejo','agendar.php?tipo=prueba_manejo',1,8);
/*!40000 ALTER TABLE `promociones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id_rol` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_rol` varchar(50) NOT NULL,
  PRIMARY KEY (`id_rol`),
  UNIQUE KEY `nombre_rol` (`nombre_rol`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Administrador General'),(3,'Cajero'),(2,'Gerente');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `solicitudes`
--

DROP TABLE IF EXISTS `solicitudes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solicitudes` (
  `id_solicitud` int(11) NOT NULL AUTO_INCREMENT,
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
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_solicitud`),
  UNIQUE KEY `uq_solicitudes_folio` (`folio`),
  KEY `idx_solicitudes_cliente` (`id_cliente`),
  KEY `fk_solicitudes_sucursales` (`id_sucursal`),
  KEY `fk_solicitudes_productos` (`id_producto`),
  CONSTRAINT `fk_solicitudes_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_solicitudes_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `solicitudes`
--

LOCK TABLES `solicitudes` WRITE;
/*!40000 ALTER TABLE `solicitudes` DISABLE KEYS */;
INSERT INTO `solicitudes` VALUES (1,'SOL-02-000001','cotizacion',NULL,2,25,'Ana Prueba','cliente.prueba@karma.local',NULL,'Cotizaci√≥n: Audi R8',NULL,'{\"color\":\"Azul Ultra\",\"version\":\"Black Edition\",\"precioEstimado\":3600000}','nueva','2026-10-03 18:02:34');
/*!40000 ALTER TABLE `solicitudes` ENABLE KEYS */;
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
  `id_sucursal` int(11) NOT NULL COMMENT 'Sucursal donde se levant√≥ la solicitud',
  `id_usuario_solicita` int(11) NOT NULL COMMENT 'Cajero que llen√≥ el formulario (autenticado con su gafete)',
  `estado` enum('pendiente','confirmada','denegada') NOT NULL DEFAULT 'pendiente',
  `motivo_rechazo` varchar(500) DEFAULT NULL COMMENT 'Obligatorio cuando el gerente la deniega',
  `id_usuario_resuelve` int(11) DEFAULT NULL COMMENT 'Gerente o administrador que la confirm√≥ o deneg√≥',
  `datos_json` longtext NOT NULL COMMENT 'Campos del formulario: VIN, kilometraje, s√≠ntoma, condiciones, evidencia, etc.',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Solicitudes de garant√≠a levantadas en caja; las confirma o deniega un gerente';
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
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La solicitud de garant√≠a ya fue resuelta.';
        END IF;
        IF NEW.id_usuario_resuelve IS NULL OR NOT EXISTS (
            SELECT 1 FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
             WHERE u.id_usuario = NEW.id_usuario_resuelve AND u.estado = 'activo'
               AND r.nombre_rol IN ('Gerente', 'Administrador General')
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un gerente o administrador activo puede confirmar o denegar una solicitud de garant√≠a.';
        END IF;
        IF NEW.id_usuario_resuelve = OLD.id_usuario_solicita THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quien env√≠a una solicitud de garant√≠a no puede resolverla.';
        END IF;
        IF NEW.estado = 'denegada' AND TRIM(COALESCE(NEW.motivo_rechazo, '')) = '' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Para denegar una solicitud de garant√≠a se debe indicar el motivo.';
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

--
-- Table structure for table `sucursales`
--

DROP TABLE IF EXISTS `sucursales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sucursales` (
  `id_sucursal` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `ciudad` varchar(80) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `horario_ventas` varchar(150) DEFAULT NULL,
  `horario_servicio` varchar(150) DEFAULT NULL,
  `servicios` varchar(500) DEFAULT NULL,
  `imagen` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_sucursal`),
  UNIQUE KEY `id_sucursal` (`id_sucursal`,`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sucursales`
--

LOCK TABLES `sucursales` WRITE;
/*!40000 ALTER TABLE `sucursales` DISABLE KEYS */;
INSERT INTO `sucursales` VALUES (1,'Manzanillo','Av. Miguel de la Madrid 100, Manzanillo, Colima','3140000000','activo','Manzanillo','manzanillo@karma.local','Lunes a viernes 9:00‚Äì19:00 ¬∑ S√°bado 9:00‚Äì14:00','Lunes a viernes 8:00‚Äì18:00 ¬∑ S√°bado 8:00‚Äì13:00','Venta de veh√≠culos nuevos,Simulaci√≥n de cr√©dito,Apartado de veh√≠culos,Seguros,Gestor√≠a de placas y tr√°mites,Garant√≠a extendida,Plan de mantenimiento prepagado,Accesorios originales e instalaci√≥n,Polarizado,Orden de servicio de taller,Refacciones originales','assets/Catalogo/sucursales/manzanillo.webp'),(2,'Colima','Av. Constituci√≥n 1500, Colima, Colima','3120000000','activo','Colima','colima@karma.local','Lunes a viernes 9:00‚Äì19:00 ¬∑ S√°bado 9:00‚Äì14:00','Lunes a viernes 8:00‚Äì18:00 ¬∑ S√°bado 8:00‚Äì13:00','Venta de veh√≠culos nuevos,Simulaci√≥n de cr√©dito,Apartado de veh√≠culos,Seguros,Gestor√≠a de placas y tr√°mites,Garant√≠a extendida,Plan de mantenimiento prepagado,Accesorios originales e instalaci√≥n,Polarizado,Orden de servicio de taller,Refacciones originales','assets/Catalogo/sucursales/colima.webp');
/*!40000 ALTER TABLE `sucursales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL AUTO_INCREMENT,
  `id_rol` int(11) NOT NULL,
  `id_sucursal` int(11) DEFAULT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellidos` varchar(100) DEFAULT NULL COMMENT 'Apellidos del empleado (nombre completo = nombre + apellidos)',
  `correo` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `idioma_pref` enum('es','en') NOT NULL DEFAULT 'es',
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `codigo_empleado` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `correo` (`correo`),
  UNIQUE KEY `codigo_empleado` (`codigo_empleado`),
  KEY `fk_usuarios_roles` (`id_rol`),
  KEY `fk_usuarios_sucursales` (`id_sucursal`),
  CONSTRAINT `fk_usuarios_roles` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON UPDATE CASCADE,
  CONSTRAINT `fk_usuarios_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,3,1,'Miranda',NULL,'miranda@karma.local','$2y$12$69yS9OJm0dBEBU1GlzIRkePfwIRRfNnSpeB1LAkOLSF0vHQRYh0yG','es','activo','EMP-0001'),(2,3,1,'Cajero Prueba Manzanillo',NULL,'cajero.manzanillo@karma.local','$2y$12$mVz.S6d98f4eCSYludtyM.UmH.Qy1mtbEV0CWH4i55.kkibFQJAZy','es','activo','EMP-0002'),(3,3,2,'Cajero Prueba Colima',NULL,'cajero.colima@karma.local','$2y$12$27KZH4amsGmocKsAl07ZWudt9Poz9RBNv4Irq6PDVH4U2ct8Tbl3i','es','activo','EMP-0003'),(4,3,1,'Carolina','Martinez','Carolina@karma.com','$2y$12$0PUAds1yElWFnkU8VH.QZ.R7iuDuXIYzrJJrNJLMHhazrXogQ.H/C','es','activo','EMP-0004'),(5,3,1,'Cajero Prueba QR',NULL,'cajero.qr@karma.local','$2y$12$wsPtHl8g5LMv6plaMo7owe3pcYxkqxwjis7/tDVS3QnDdgnJOkipm','es','activo','EMP-0005'),(6,2,1,'Gerente Prueba QR',NULL,'gerente.qr@karma.local','$2y$12$19YSbu6g5IcuzYETfw0a4uY1svHQlzLAjKCRuLa55Ro0VCIZN2Fne','es','activo','EMP-0006'),(7,3,1,'Cajero Prueba QR Inactivo',NULL,'inactivo.qr@karma.local','$2y$12$wLW/QZeiMYhQQIh1kky.Ve9/88PYimfEwl/3aBMFqKKI.d2csrUQG','es','inactivo','EMP-0007');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER auto_codigo_empleado
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    DECLARE siguiente_id INT;
    
    -- Obtiene el pr√≥ximo ID de autoincremento
    SELECT AUTO_INCREMENT INTO siguiente_id
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios';
    
    -- Asigna el c√≥digo en formato EMP-000X
    IF NEW.codigo_empleado IS NULL THEN
        SET NEW.codigo_empleado = CONCAT('EMP-', LPAD(siguiente_id, 4, '0'));
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `ventas`
--

DROP TABLE IF EXISTS `ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ventas` (
  `id_venta` int(11) NOT NULL AUTO_INCREMENT,
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
  PRIMARY KEY (`id_venta`),
  KEY `fk_ventas_sucursales` (`id_sucursal`),
  KEY `fk_ventas_usuarios` (`id_usuario`),
  KEY `fk_ventas_cajas` (`id_caja`),
  KEY `fk_ventas_metodos_pago` (`id_metodo_pago`),
  KEY `fk_ventas_clientes` (`id_cliente`),
  CONSTRAINT `fk_ventas_cajas` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_metodos_pago` FOREIGN KEY (`id_metodo_pago`) REFERENCES `metodos_pago` (`id_metodo_pago`) ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_usuarios` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (1,1,1,1,1,'2026-09-24 16:07:19',1862400.00,1862400.00,4,1862400.00,0.00,1),(2,1,1,1,1,'2026-09-24 17:18:09',620000.00,620000.00,5,650000.00,30000.00,1),(3,1,1,1,1,'2026-09-26 22:43:57',620000.00,620000.00,4,700000.00,80000.00,1),(4,1,1,1,1,'2026-09-26 22:47:26',2280000.00,2280000.00,4,3000000.00,720000.00,1),(5,1,1,1,1,'2026-09-27 21:47:44',444801.61,444801.61,6,500000.00,55198.39,1),(6,1,1,1,1,'2026-09-28 08:34:47',3469997.91,3469997.91,NULL,4000000.00,530002.09,1),(7,1,1,1,1,'2026-09-28 08:51:34',1743576.89,1743576.89,NULL,2000000.00,256423.11,2),(8,1,2,1,1,'2026-10-03 17:58:36',9836.82,9836.82,NULL,10336.82,500.00,1),(9,1,2,1,1,'2026-10-03 18:02:33',1006865.63,1006865.63,NULL,2000000.00,993134.37,99),(10,1,2,1,1,'2026-10-03 19:06:07',4881.86,4881.86,NULL,5000.00,118.14,3),(11,1,5,1,1,'2026-10-05 08:56:37',1203.37,1203.37,NULL,2000.00,796.63,1),(12,1,5,1,1,'2026-10-05 08:56:37',288140.62,288140.62,10,300000.00,11859.38,2),(13,1,5,1,1,'2026-10-05 08:56:38',1203.37,1203.37,NULL,1500.00,296.63,3),(14,1,5,1,1,'2026-10-05 09:02:51',1203.37,1203.37,NULL,1500.00,296.63,4),(15,1,5,1,1,'2026-10-05 09:04:44',371609.38,371609.38,11,436489.00,64879.62,5),(16,1,5,1,1,'2026-10-05 09:06:19',1203.37,1203.37,NULL,1300.00,96.63,6),(17,1,4,1,1,'2026-10-05 22:32:10',5907.23,5907.23,9,6000.00,92.77,7),(18,1,4,1,1,'2026-10-06 09:48:43',2413985.87,2413985.87,NULL,2500000.00,86014.13,1),(19,1,4,1,1,'2026-10-06 10:00:30',2413985.87,2413985.87,NULL,3000000.00,586014.13,2),(20,1,4,1,1,'2026-10-06 10:04:34',444801.61,444801.61,NULL,500000.00,55198.39,3),(21,1,4,1,1,'2026-10-10 16:23:42',201373.13,201373.13,12,202000.00,626.87,1),(22,1,4,1,1,'2026-10-10 16:30:26',50000.00,50000.00,13,50000.00,0.00,2);
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `web_order_detalle`
--

DROP TABLE IF EXISTS `web_order_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `web_order_detalle` (
  `id_detalle` int(11) NOT NULL AUTO_INCREMENT,
  `id_orden` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `subtotal_linea` decimal(12,2) NOT NULL,
  `descripcion` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `fk_wod_orden` (`id_orden`),
  KEY `fk_wod_producto` (`id_producto`),
  CONSTRAINT `fk_wod_orden` FOREIGN KEY (`id_orden`) REFERENCES `web_orders` (`id_orden`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wod_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE,
  CONSTRAINT `chk_wod_cantidad` CHECK (`cantidad` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `web_order_detalle`
--

LOCK TABLES `web_order_detalle` WRITE;
/*!40000 ALTER TABLE `web_order_detalle` DISABLE KEYS */;
INSERT INTO `web_order_detalle` VALUES (8,11,61,1,5907.23,5907.23,'Disco de freno trasero Audi'),(9,12,84,1,1203.37,1203.37,'Maneta de freno/embrague Ducati');
/*!40000 ALTER TABLE `web_order_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `web_orders`
--

DROP TABLE IF EXISTS `web_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `web_orders` (
  `id_orden` int(11) NOT NULL AUTO_INCREMENT,
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
  `id_venta` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_orden`),
  UNIQUE KEY `uq_weborders_folio` (`folio`),
  KEY `fk_weborders_productos` (`id_producto`),
  KEY `idx_weborders_estado` (`estado`),
  KEY `idx_weborders_sucursal_estado` (`id_sucursal`,`estado`),
  KEY `fk_weborders_clientes` (`id_cliente`),
  KEY `fk_weborders_metodos_pago` (`id_metodo_pago`),
  KEY `fk_weborders_ventas` (`id_venta`),
  CONSTRAINT `fk_weborders_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_weborders_metodos_pago` FOREIGN KEY (`id_metodo_pago`) REFERENCES `metodos_pago` (`id_metodo_pago`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_weborders_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_weborders_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_weborders_ventas` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `web_orders`
--

LOCK TABLES `web_orders` WRITE;
/*!40000 ALTER TABLE `web_orders` DISABLE KEYS */;
INSERT INTO `web_orders` VALUES (10,'vehiculo',31,'Gojo Satoru','3140242412','gojosatorureal@gmail.com',200000.00,'2026-10-05 10:00:00','Rojo Carm√≠n',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pendiente','WEB-01-000010',9,1,NULL,NULL,'pendiente',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'Solicitud de apartado. ','2026-10-04 16:14:34',NULL,NULL),(11,'refaccion',61,'Gojo Satoru','3140242412','gojosatorureal@gmail.com',NULL,NULL,NULL,'Disco de freno trasero Audi','Audi RS3','Audi','2.5L TFSI Turbo 5-cil.','2480 cc','Trasera',NULL,'Derecho','atendida','WEB-01-000011',9,1,'recoger',1,'pagado',5907.23,0.00,5907.23,NULL,NULL,NULL,NULL,1,NULL,'2026-10-04 17:09:53','2026-10-05 22:32:10',17),(12,'refaccion',NULL,'Cliente Prueba QR','3140000001',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'atendida','WEB-QR-PRUEBA-01',NULL,1,'recoger',1,'pagado',1203.37,0.00,1203.37,NULL,NULL,NULL,NULL,0,'Orden de prueba de la autorizaci?n por gafete (docs/AUTORIZACION_EMPLEADO.md)','2026-10-05 08:53:33','2026-10-05 08:56:38',13);
/*!40000 ALTER TABLE `web_orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'pos_multisede'
--
/*!50106 SET @save_time_zone= @@TIME_ZONE */ ;
/*!50106 DROP EVENT IF EXISTS `ev_garantias_vencidas` */;
DELIMITER ;;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;;
/*!50003 SET character_set_client  = utf8mb4 */ ;;
/*!50003 SET character_set_results = utf8mb4 */ ;;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;;
/*!50003 SET @saved_time_zone      = @@time_zone */ ;;
/*!50003 SET time_zone             = 'SYSTEM' */ ;;
/*!50106 CREATE*/ /*!50117 DEFINER=`root`@`localhost`*/ /*!50106 EVENT `ev_garantias_vencidas` ON SCHEDULE EVERY 1 MINUTE STARTS '2026-10-10 16:52:13' ON COMPLETION PRESERVE ENABLE COMMENT 'Garant√≠as cuya fecha y hora de vencimiento ya lleg√≥ dejan de est' DO UPDATE garantias SET estado = 'vencida' WHERE estado = 'vigente' AND fecha_expiracion <= NOW() */ ;;
/*!50003 SET time_zone             = @saved_time_zone */ ;;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;;
/*!50003 SET character_set_client  = @saved_cs_client */ ;;
/*!50003 SET character_set_results = @saved_cs_results */ ;;
/*!50003 SET collation_connection  = @saved_col_connection */ ;;
DELIMITER ;
/*!50106 SET TIME_ZONE= @save_time_zone */ ;

--
-- Dumping routines for database 'pos_multisede'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `karma_abrev_marca` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_abrev_marca`(p_marca VARCHAR(80)) RETURNS varchar(10) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    DETERMINISTIC
BEGIN
    -- Normaliza la marca a may√∫sculas y sin espacios
    DECLARE v_marca VARCHAR(80) DEFAULT UPPER(TRIM(COALESCE(p_marca, '')));
    -- Marcas conocidas del cat√°logo
    IF v_marca = 'AUDI' THEN RETURN 'AUDI'; END IF;
    IF v_marca = 'PORSCHE' THEN RETURN 'POR'; END IF;
    IF v_marca = 'DUCATI' THEN RETURN 'DUC'; END IF;
    -- Marca nueva: primeras 4 letras (o GEN si no trae marca)
    IF v_marca = '' THEN RETURN 'GEN'; END IF;
    RETURN LEFT(REGEXP_REPLACE(v_marca, '[^A-Z]', ''), 4);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `karma_armar_vin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_armar_vin`(p_marca VARCHAR(80), p_anio INT, p_serie INT) RETURNS varchar(17) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    DETERMINISTIC
BEGIN
    RETURN CONCAT(karma_wmi_marca(p_marca), 'ZZZ', 'ZZ', '0', karma_letra_anio_vin(p_anio), 'S', LPAD(p_serie, 6, '0'));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `karma_generar_codigo_barras` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_generar_codigo_barras`(p_marca VARCHAR(80), p_tipo VARCHAR(30)) RETURNS varchar(50) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    READS SQL DATA
BEGIN
    DECLARE v_prefijo VARCHAR(40);
    DECLARE v_siguiente INT;
    -- Veh√≠culos: KRM-CAT-{MARCA}- ; refacciones: KRM-CAT-REF-{MARCA}-
    SET v_prefijo = IF(p_tipo = 'refaccion',
                       CONCAT('KRM-CAT-REF-', karma_abrev_marca(p_marca), '-'),
                       CONCAT('KRM-CAT-', karma_abrev_marca(p_marca), '-'));
    -- Busca el n√∫mero m√°s alto que ya existe con ese prefijo y le suma 1
    SELECT COALESCE(MAX(CAST(SUBSTRING(codigo_barras, CHAR_LENGTH(v_prefijo) + 1) AS UNSIGNED)), 0) + 1
      INTO v_siguiente
      FROM productos
     WHERE codigo_barras REGEXP CONCAT('^', v_prefijo, '[0-9]+$');
    -- N√∫mero con al menos 2 d√≠gitos (01, 02 ‚Ä¶ 99, 100)
    RETURN CONCAT(v_prefijo, IF(v_siguiente < 10, CONCAT('0', v_siguiente), v_siguiente));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `karma_generar_vin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_generar_vin`(p_marca VARCHAR(80), p_anio INT) RETURNS varchar(17) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    READS SQL DATA
BEGIN
    DECLARE v_serie INT;
    -- √öltima serie usada (los 6 d√≠gitos finales del VIN); si no hay ninguna empieza en 100000
    SELECT COALESCE(MAX(CAST(RIGHT(vin, 6) AS UNSIGNED)), 100000)
      INTO v_serie
      FROM productos
     WHERE vin IS NOT NULL AND vin <> '';
    RETURN karma_armar_vin(p_marca, p_anio, v_serie + 37);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `karma_letra_anio_vin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_letra_anio_vin`(p_anio INT) RETURNS char(1) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    DETERMINISTIC
BEGIN
    -- Ciclo oficial de 30 a√±os sin I, O, Q, U, Z ni 0 (empieza en 2010 = A)
    DECLARE v_anio INT DEFAULT COALESCE(p_anio, YEAR(CURDATE()));
    RETURN SUBSTRING('ABCDEFGHJKLMNPRSTVWXY123456789', MOD(MOD(v_anio - 2010, 30) + 30, 30) + 1, 1);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `karma_wmi_marca` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `karma_wmi_marca`(p_marca VARCHAR(80)) RETURNS char(3) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    DETERMINISTIC
BEGIN
    -- Normaliza la marca para compararla
    DECLARE v_marca VARCHAR(80) DEFAULT UPPER(TRIM(COALESCE(p_marca, '')));
    IF v_marca = 'AUDI' THEN RETURN 'WAU'; END IF;
    IF v_marca = 'PORSCHE' THEN RETURN 'WP0'; END IF;
    IF v_marca = 'DUCATI' THEN RETURN 'ZDM'; END IF;
    -- Marca nueva: se usa el prefijo de la agencia
    RETURN 'KRM';
END ;;
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

-- Dump completed on 2026-10-10 17:05:15
