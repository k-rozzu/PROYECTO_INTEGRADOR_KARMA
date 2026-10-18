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
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Auditoría de autorizaciones de empleado (gafete QR / código) del Punto de Venta';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `autorizaciones_empleado`
--

LOCK TABLES `autorizaciones_empleado` WRITE;
/*!40000 ALTER TABLE `autorizaciones_empleado` DISABLE KEYS */;
INSERT INTO `autorizaciones_empleado` VALUES (1,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(2,'2026-10-05 08:55:35','operacion','CREDITO',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(3,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(4,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(5,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','CSRF','crear_venta',NULL),(6,'2026-10-05 08:55:35','operacion','ORDEN_WEB',12,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cobrar_orden_web',NULL),(7,'2026-10-05 08:55:35','operacion','ORDEN_WEB',13,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cancelar_orden_web',NULL),(8,'2026-10-05 08:55:35','operacion','GARANTIA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','aplicar_garantia',NULL),(9,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,NULL,1,'denegado','CSRF',NULL,NULL),(10,'2026-10-05 08:55:35','autorizacion','DESCONOCIDA',NULL,NULL,'manual',5,NULL,1,'denegado','METODO_HTTP',NULL,NULL),(11,'2026-10-05 08:55:35','autorizacion','BORRAR_TODO',1,'EMP-0005','manual',5,NULL,1,'denegado','ACCION_NO_PROTEGIDA',NULL,NULL),(12,'2026-10-05 08:55:35','autorizacion','VENTA',NULL,'EMP-0005','manual',5,NULL,1,'denegado','REFERENCIA_INVALIDA',NULL,NULL),(13,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-9999','qr',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(14,'2026-10-05 08:55:35','autorizacion','VENTA',1,'HOLA','manual',5,NULL,1,'denegado','FORMATO_INVALIDO',NULL,NULL),(15,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005\'OR\'1\'=\'1','manual',5,NULL,1,'denegado','FORMATO_INVALIDO',NULL,NULL),(16,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0006','qr',5,6,1,'denegado','ROL_DISTINTO,USUARIO_DISTINTO',NULL,NULL),(17,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(18,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0007','qr',5,7,1,'denegado','USUARIO_DISTINTO,INACTIVO',NULL,NULL),(19,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0001','qr',5,1,1,'denegado','USUARIO_DISTINTO',NULL,NULL),(20,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(21,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(22,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(23,'2026-10-05 08:55:35','autorizacion','VENTA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(24,'2026-10-05 08:55:35','operacion','CREDITO',1,'EMP-0005',NULL,5,NULL,1,'denegado','ACCION_DISTINTA','crear_venta',NULL),(25,'2026-10-05 08:55:35','operacion','VENTA',1,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(26,'2026-10-05 08:55:35','autorizacion','VENTA',51,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(27,'2026-10-05 08:55:35','operacion','VENTA',1,'EMP-0005',NULL,5,NULL,1,'denegado','REFERENCIA_DISTINTA','crear_venta',NULL),(28,'2026-10-05 08:55:35','autorizacion','ORDEN_WEB',12,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(29,'2026-10-05 08:55:35','operacion','ORDEN_WEB',13,'EMP-0005',NULL,5,NULL,1,'denegado','REFERENCIA_DISTINTA','cancelar_orden_web',NULL),(30,'2026-10-05 08:55:35','autorizacion','GARANTIA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(31,'2026-10-05 08:55:35','autorizacion','GARANTIA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(32,'2026-10-05 08:55:35','operacion','GARANTIA',1,'EMP-0005',NULL,5,NULL,1,'denegado','PERMISO_INVALIDO','aplicar_garantia',NULL),(33,'2026-10-05 08:55:35','autorizacion','GARANTIA',1,'EMP-0005','manual',5,5,1,'autorizado',NULL,NULL,NULL),(34,'2026-10-05 08:56:37','operacion','GARANTIA',1,'EMP-0005',NULL,5,NULL,1,'denegado','PERMISO_VENCIDO','aplicar_garantia',NULL),(35,'2026-10-05 08:56:37','autorizacion','VENTA',1,'EMP-0005','qr',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 08:56:37'),(36,'2026-10-05 08:56:37','operacion','VENTA',2,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(37,'2026-10-05 08:56:37','autorizacion','CREDITO',2,'EMP-0005','manual',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 08:56:37'),(38,'2026-10-05 08:56:37','autorizacion','GARANTIA',1,'EMP-0005','qr',5,5,1,'autorizado',NULL,'aplicar_garantia','2026-10-05 08:56:37'),(39,'2026-10-05 08:56:37','autorizacion','GARANTIA',999,'EMP-0005','manual',5,5,1,'autorizado',NULL,'aplicar_garantia','2026-10-05 08:56:37'),(40,'2026-10-05 08:56:37','autorizacion','ORDEN_WEB',12,'EMP-0005','qr',5,5,1,'autorizado',NULL,'cobrar_orden_web','2026-10-05 08:56:38'),(41,'2026-10-05 08:56:38','autorizacion','ORDEN_WEB',13,'EMP-0005','manual',5,5,1,'autorizado',NULL,'cancelar_orden_web','2026-10-05 08:56:38'),(42,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(43,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(44,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(45,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(46,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(47,'2026-10-05 08:56:38','autorizacion','VENTA',1,'EMP-0005','manual',5,NULL,1,'denegado','DEMASIADOS_INTENTOS',NULL,NULL),(48,'2026-10-05 08:56:39','autorizacion','VENTA',4,'EMP-0005','qr',5,5,1,'autorizado',NULL,NULL,NULL),(49,'2026-10-05 09:02:08','autorizacion','VENTA',4,'EMP-9999','manual',5,NULL,1,'denegado','CODIGO_INEXISTENTE',NULL,NULL),(50,'2026-10-05 09:02:26','autorizacion','VENTA',4,'EMP-0006','qr',5,6,1,'denegado','ROL_DISTINTO,USUARIO_DISTINTO',NULL,NULL),(51,'2026-10-05 09:02:50','autorizacion','VENTA',4,'EMP-0005','qr',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 09:02:51'),(52,'2026-10-05 09:04:43','autorizacion','CREDITO',5,'EMP-0005','manual',5,5,1,'autorizado',NULL,'crear_venta','2026-10-05 09:04:44'),(53,'2026-10-05 09:05:03','autorizacion','GARANTIA',1,'EMP-0005','qr',5,5,1,'autorizado',NULL,'aplicar_garantia','2026-10-05 09:05:03'),(54,'2026-10-05 09:06:18','autorizacion','ORDEN_WEB',14,'EMP-0005','qr',5,5,1,'autorizado',NULL,'cobrar_orden_web','2026-10-05 09:06:19'),(55,'2026-10-05 09:06:35','autorizacion','ORDEN_WEB',15,'EMP-0005','manual',5,5,1,'autorizado',NULL,'cancelar_orden_web','2026-10-05 09:06:36'),(56,'2026-10-05 09:07:14','operacion','VENTA',7,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(57,'2026-10-05 09:07:14','operacion','VENTA',7,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(58,'2026-10-05 09:07:14','operacion','CREDITO',7,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','crear_venta',NULL),(59,'2026-10-05 09:07:14','operacion','ORDEN_WEB',11,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cobrar_orden_web',NULL),(60,'2026-10-05 09:07:14','operacion','ORDEN_WEB',10,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','cancelar_orden_web',NULL),(61,'2026-10-05 09:07:14','operacion','GARANTIA',3,NULL,NULL,5,NULL,1,'denegado','SIN_AUTORIZACION','aplicar_garantia',NULL),(62,'2026-10-05 09:07:14','autorizacion','VENTA',7,NULL,'manual',5,NULL,1,'denegado','FORMATO_INVALIDO',NULL,NULL),(63,'2026-10-05 22:32:10','autorizacion','ORDEN_WEB',11,'EMP-0004','manual',4,4,1,'autorizado',NULL,'cobrar_orden_web','2026-10-05 22:32:10'),(64,'2026-10-06 09:48:43','autorizacion','VENTA',1,'EMP-0004','qr',4,4,1,'autorizado',NULL,'crear_venta','2026-10-06 09:48:43'),(65,'2026-10-06 10:00:30','autorizacion','VENTA',2,'EMP-0004','qr',4,4,1,'autorizado',NULL,'crear_venta','2026-10-06 10:00:30'),(66,'2026-10-06 10:04:33','autorizacion','VENTA',3,'EMP-0004','qr',4,4,1,'autorizado',NULL,'crear_venta','2026-10-06 10:04:34');
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
INSERT INTO `catalogo_opciones` VALUES (1,'audi-color-blanco','Audi','auto','color','Blanco Glaciar','Metálico',0.00,'#F2F2EF',1,1),(2,'audi-color-negro','Audi','auto','color','Negro Mythos','Metálico',0.00,'#101012',2,1),(3,'audi-color-nardo','Audi','auto','color','Gris Nardo','Sólido',0.00,'#7A7D80',3,1),(4,'audi-color-azul','Audi','auto','color','Azul Ultra','Metálico',0.00,'#1F3B66',4,1),(5,'audi-color-rojo','Audi','auto','color','Rojo Tango','Metálico',0.00,'#8C1D2B',5,1),(6,'audi-color-verde','Audi','auto','color','Verde Distrito','Metálico',12000.00,'#3F4A3C',6,1),(7,'audi-version-base','Audi','auto','version','Base','Equipamiento de serie',0.00,NULL,1,1),(8,'audi-version-sline','Audi','auto','version','S line','Paquete exterior e interior S line con suspensión deportiva',65000.00,NULL,2,1),(9,'audi-version-black','Audi','auto','version','Black Edition','Detalles en negro brillante, rines de 20\" y techo panorámico',95000.00,NULL,3,1),(10,'audi-eq-techo','Audi','auto','equipamiento','Techo panorámico','Techo de cristal corredizo con cortinilla eléctrica',32000.00,NULL,1,1),(11,'audi-eq-audio','Audi','auto','equipamiento','Sistema de audio premium','16 bocinas con sonido envolvente 3D',28000.00,NULL,2,1),(12,'audi-eq-hud','Audi','auto','equipamiento','Head-up display','Información de manejo proyectada en el parabrisas',22000.00,NULL,3,1),(13,'audi-eq-tour','Audi','auto','equipamiento','Asistentes de conducción Tour','Crucero adaptativo, carril activo y asistente de tráfico',35000.00,NULL,4,1),(14,'audi-eq-rines','Audi','auto','equipamiento','Rines de 21\"','Rines de aleación de diseño exclusivo',41000.00,NULL,5,1),(15,'porsche-color-blanco','Porsche','auto','color','Blanco Carrara','Metálico',0.00,'#EDEDEA',1,1),(16,'porsche-color-negro','Porsche','auto','color','Negro Jeweled','Metálico',0.00,'#141414',2,1),(17,'porsche-color-gt','Porsche','auto','color','Gris GT Plata','Metálico',0.00,'#9EA0A1',3,1),(18,'porsche-color-azul','Porsche','auto','color','Azul Gentian','Metálico',0.00,'#1B3A6B',4,1),(19,'porsche-color-rojo','Porsche','auto','color','Rojo Carmín','Sólido',0.00,'#9E1B2E',5,1),(20,'porsche-color-verde','Porsche','auto','color','Verde Python','Color especial',48000.00,'#5C7D3A',6,1),(21,'porsche-color-amarillo','Porsche','auto','color','Amarillo Racing','Color especial',48000.00,'#F2C230',7,1),(22,'porsche-version-base','Porsche','auto','version','Base','Equipamiento de serie',0.00,NULL,1,1),(23,'porsche-version-chrono','Porsche','auto','version','Paquete Sport Chrono','Cronómetro, modo Sport Plus y Launch Control',78000.00,NULL,2,1),(24,'porsche-version-design','Porsche','auto','version','Paquete Sport Design','Fascias y faldones deportivos con detalles en negro',115000.00,NULL,3,1),(25,'porsche-eq-audio','Porsche','auto','equipamiento','Sistema de audio de alta fidelidad','Amplificación dedicada y bocinas de alto desempeño',54000.00,NULL,1,1),(26,'porsche-eq-asientos','Porsche','auto','equipamiento','Asientos deportivos adaptativos','18 posiciones eléctricas con memoria',68000.00,NULL,2,1),(27,'porsche-eq-direccion','Porsche','auto','equipamiento','Dirección en el eje trasero','Mayor agilidad en curvas y estabilidad a alta velocidad',72000.00,NULL,3,1),(28,'porsche-eq-matrix','Porsche','auto','equipamiento','Faros LED Matrix con PDLS Plus','Iluminación adaptativa con luz de curva',45000.00,NULL,4,1),(29,'porsche-eq-pccb','Porsche','auto','equipamiento','Frenos cerámicos PCCB','Discos de carbono-cerámica con calipers amarillos',260000.00,NULL,5,1),(30,'ducati-color-rojo','Ducati','moto','color','Rojo Ducati','Color de la marca',0.00,'#9E1B2E',1,1),(31,'ducati-color-gris','Ducati','moto','color','Gris Antracita','Mate',0.00,'#4A4A4A',2,1),(32,'ducati-color-blanco','Ducati','moto','color','Blanco Dark','Brillante',0.00,'#E7E7E4',3,1),(33,'ducati-color-negro','Ducati','moto','color','Negro Mate','Mate',0.00,'#1A1A1A',4,1),(34,'ducati-color-verde','Ducati','moto','color','Verde Storm','Edición especial',9500.00,'#4D5845',5,1),(35,'ducati-version-std','Ducati','moto','version','Estándar','Equipamiento de serie',0.00,NULL,1,1),(36,'ducati-version-perf','Ducati','moto','version','Paquete Performance','Escape deportivo, asiento racing y piezas de aluminio maquinado',38000.00,NULL,2,1),(37,'ducati-eq-punos','Ducati','moto','equipamiento','Puños con calefacción','Tres niveles de temperatura',6500.00,NULL,1,1),(38,'ducati-eq-crucero','Ducati','moto','equipamiento','Control de crucero','Mandos integrados en el manubrio',9800.00,NULL,2,1),(39,'ducati-eq-asiento','Ducati','moto','equipamiento','Asiento confort','Espuma de doble densidad para viajes largos',5200.00,NULL,3,1),(40,'ducati-eq-nav','Ducati','moto','equipamiento','Navegación en pantalla TFT','Mapas paso a paso conectados al celular',7900.00,NULL,4,1),(41,'ducati-eq-alarma','Ducati','moto','equipamiento','Alarma antirrobo','Inmovilizador con sensor de movimiento',6200.00,NULL,5,1);
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
INSERT INTO `categorias` VALUES (1,'Porsche','Vehículos Porsche'),(2,'Audi','Vehículos Audi'),(3,'Ducati','Motocicletas Ducati'),(4,'Refacciones','Refacciones y piezas');
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
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES (1,'Roberto Fernández Aguilar','FERA900101XXX','314 123 4567','roberto.fernandez@email.com','Porsche 911 Carrera',1880000.00,450000.00,470000.00,5,24,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(2,'Marina López Castillo','LOCM920202XXX','314 987 6543','marina.lopez@email.com','Audi RS7 Sportback',1315000.00,200000.00,NULL,2,12,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(3,'Héctor Iván Solórzano','SOIH930303XXX','312 456 7890','hector.solorzano@email.com','Ducati Panigale V4 S',496000.00,62000.00,124000.00,0,24,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(4,'Carolina zuñiga','123456789','3141390132','cmartinez72@ucol.mx',NULL,NULL,NULL,NULL,0,0,'activo','Manzanillo Centro Sector 5','INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(5,'Alan Ibarra Heredia','26102007','3141576255','aibarra9@ucol.mx',NULL,NULL,NULL,NULL,0,0,'activo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(6,'Diego Alejandro Vazquez','098765423','3141987686','dvazquez89@gmail.com',NULL,NULL,NULL,NULL,0,0,'activo','Floresta 56','INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(9,'Gojo Satoru',NULL,'3140242412','gojosatorureal@gmail.com',NULL,NULL,NULL,NULL,0,0,'activo',NULL,NULL,'Gojo','Satoru','$2y$10$xeX87ork9xKTpOhN7PbtqOi//t3Yw/2ee.ZdhHJLIE1Z6U3ye110q',NULL,NULL,NULL,1,'Porsche',1,0,0,'2026-10-04 16:13:31','2026-10-06 09:24:28'),(10,'Cliente Prueba QR Credito','XAXX010101000','3140000002','cliente.credito.qr@karma.local','Ducati Scrambler Nightshift (2023)',276000.00,11500.00,50000.00,0,24,'activo','Calle de Prueba 1, Manzanillo','INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL),(11,'Cliente Prueba QR UI Credito',NULL,NULL,'cliente.credito.ui.qr@karma.local','Ducati Multistrada V2 (2024)',356388.08,14849.50,80000.00,0,24,'activo',NULL,'INE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,0,1,NULL,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
INSERT INTO `detalle_ventas` VALUES (1,1,5,1,1850000.00,1850000.00,NULL,NULL,NULL),(2,1,9,1,12400.00,12400.00,NULL,NULL,NULL),(3,2,6,1,620000.00,620000.00,NULL,NULL,NULL),(4,3,6,1,620000.00,620000.00,'2026','12345','Negro piel'),(5,4,1,1,2280000.00,2280000.00,'2024911','3.0','Negro grisaceo'),(6,5,54,1,444801.61,444801.61,'2345671','V2 Testastretta',NULL),(7,6,25,1,3469997.91,3469997.91,'WAUZZZZZ0SS100814','5.2L V10 FSI',NULL),(8,7,20,1,1743576.89,1743576.89,'WAUZZZZZ0PS100629','3.0L V6 TFSI','Negro'),(9,8,63,2,4918.41,9836.82,NULL,NULL,NULL),(10,9,18,1,1006865.63,1006865.63,'WAUZZZZZ0SS100555',NULL,NULL),(11,10,78,2,2440.93,4881.86,NULL,NULL,NULL),(12,11,84,1,1203.37,1203.37,NULL,NULL,NULL),(13,12,52,1,288140.62,288140.62,'ZDMZZZZZ0PS101813',NULL,NULL),(14,13,84,1,1203.37,1203.37,NULL,NULL,NULL),(15,14,84,1,1203.37,1203.37,NULL,NULL,NULL),(16,15,46,1,371609.38,371609.38,'ZDMZZZZZ0RS101591','V2 Testastretta',NULL),(17,16,84,1,1203.37,1203.37,NULL,NULL,NULL),(18,17,61,1,5907.23,5907.23,NULL,NULL,NULL),(19,18,33,1,2413985.87,2413985.87,'WP0ZZZZZ0RS101110','3.0L Boxer Biturbo','Negro'),(20,19,33,1,2413985.87,2413985.87,'WP0ZZZZZ0RS101110','3.0L Boxer Biturbo','Negro'),(21,20,54,1,444801.61,444801.61,'ZDMZZZZZ0RS101887','V2 Testastretta',NULL);
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
  `id_cliente` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `fecha_expiracion` date NOT NULL,
  `estado` enum('vigente','vencida','cancelada') NOT NULL DEFAULT 'vigente',
  PRIMARY KEY (`id_garantia`),
  KEY `fk_garantias_clientes` (`id_cliente`),
  KEY `fk_garantias_productos` (`id_producto`),
  KEY `idx_garantias_estado` (`estado`),
  CONSTRAINT `fk_garantias_clientes` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`) ON UPDATE CASCADE,
  CONSTRAINT `fk_garantias_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `garantias`
--

LOCK TABLES `garantias` WRITE;
/*!40000 ALTER TABLE `garantias` DISABLE KEYS */;
INSERT INTO `garantias` VALUES (1,1,1,'2027-03-12','vigente'),(2,2,4,'2026-07-28','vencida'),(3,3,6,'2026-11-05','vigente');
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
INSERT INTO `inventarios` VALUES (1,1,5,4,1),(2,1,4,4,1),(3,1,6,4,1),(4,1,7,3,1),(5,1,1,1,1),(6,1,2,1,1),(7,1,3,2,1),(8,1,8,8,1),(9,1,9,9,1),(10,1,10,1,1),(11,1,11,0,2),(12,1,12,0,2),(13,1,13,1,2),(14,1,14,1,2),(15,1,15,2,2),(16,1,16,3,2),(17,1,17,0,2),(18,1,18,4,2),(19,1,19,2,2),(20,1,20,0,2),(21,1,21,0,2),(22,1,22,4,2),(23,1,23,3,2),(24,1,24,7,2),(25,1,25,0,2),(26,1,41,0,2),(27,1,42,0,2),(28,1,43,1,2),(29,1,44,1,2),(30,1,45,2,2),(31,1,46,2,2),(32,1,47,0,2),(33,1,48,5,2),(34,1,49,2,2),(35,1,50,1,2),(36,1,51,0,2),(37,1,52,3,2),(38,1,53,3,2),(39,1,54,5,2),(40,1,55,1,2),(41,1,26,0,2),(42,1,27,0,2),(43,1,28,1,2),(44,1,29,1,2),(45,1,30,2,2),(46,1,31,3,2),(47,1,32,0,2),(48,1,33,3,2),(49,1,34,2,2),(50,1,35,1,2),(51,1,36,0,2),(52,1,37,4,2),(53,1,38,3,2),(54,1,39,7,2),(55,1,40,1,2),(56,1,56,0,2),(57,1,57,0,2),(58,1,58,1,2),(59,1,59,1,2),(60,1,60,2,2),(61,1,61,2,2),(62,1,62,0,2),(63,1,63,3,2),(64,1,64,2,2),(65,1,65,1,2),(66,1,76,3,2),(67,1,77,0,2),(68,1,78,3,2),(69,1,79,2,2),(70,1,80,1,2),(71,1,81,0,2),(72,1,82,4,2),(73,1,83,3,2),(74,1,84,3,2),(75,1,85,1,2),(76,1,66,0,2),(77,1,67,4,2),(78,1,68,3,2),(79,1,69,6,2),(80,1,70,1,2),(81,1,71,0,2),(82,1,72,0,2),(83,1,73,1,2),(84,1,74,1,2),(85,1,75,2,2),(86,1,86,6,2),(87,1,87,2,2),(88,1,88,8,2),(89,1,89,1,2),(90,1,90,4,2),(91,1,91,0,2),(92,1,92,2,2),(93,1,93,5,2),(94,1,94,3,2),(101,2,1,1,1),(102,2,2,0,1),(103,2,3,5,1),(104,2,4,3,1),(105,2,5,2,1),(106,2,6,1,1),(107,2,7,0,1),(108,2,8,1,2),(109,2,9,3,2),(110,2,10,0,2),(111,2,11,5,1),(112,2,12,0,1),(113,2,13,5,1),(114,2,14,3,1),(115,2,15,2,1),(116,2,16,1,1),(117,2,17,0,1),(118,2,18,5,1),(119,2,19,3,1),(120,2,20,2,1),(121,2,21,1,1),(122,2,22,0,1),(123,2,23,5,1),(124,2,24,3,1),(125,2,25,1,1),(126,2,26,1,1),(127,2,27,0,1),(128,2,28,3,1),(129,2,29,3,1),(130,2,30,2,1),(131,2,31,1,1),(132,2,32,0,1),(133,2,33,5,1),(134,2,34,3,1),(135,2,35,2,1),(136,2,36,1,1),(137,2,37,0,1),(138,2,38,5,1),(139,2,39,3,1),(140,2,40,2,1),(141,2,41,1,1),(142,2,42,2,1),(143,2,43,5,1),(144,2,44,3,1),(145,2,45,2,1),(146,2,46,1,1),(147,2,47,0,1),(148,2,48,5,1),(149,2,49,3,1),(150,2,50,2,1),(151,2,51,1,1),(152,2,52,0,1),(153,2,53,5,1),(154,2,54,3,1),(155,2,55,2,1),(156,2,56,5,2),(157,2,57,3,2),(158,2,58,0,2),(159,2,59,10,2),(160,2,60,5,2),(161,2,61,2,2),(162,2,62,1,2),(163,2,63,1,2),(164,2,64,0,2),(165,2,65,10,2),(166,2,66,5,2),(167,2,67,0,2),(168,2,68,1,2),(169,2,69,3,2),(170,2,70,0,2),(171,2,71,10,2),(172,2,72,5,2),(173,2,73,2,2),(174,2,74,1,2),(175,2,75,3,2),(176,2,76,0,2),(177,2,77,10,2),(178,2,78,10,2),(179,2,79,2,2),(180,2,80,1,2),(181,2,81,3,2),(182,2,82,0,2),(183,2,83,10,2),(184,2,84,5,2),(185,2,85,2,2),(186,2,86,5,2),(187,2,87,2,2),(188,2,88,1,2),(189,2,89,3,2),(190,2,90,0,2),(191,2,91,10,2),(192,2,92,5,2),(193,2,93,2,2),(194,2,94,1,2);
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metodos_pago`
--

LOCK TABLES `metodos_pago` WRITE;
/*!40000 ALTER TABLE `metodos_pago` DISABLE KEYS */;
INSERT INTO `metodos_pago` VALUES (1,'Efectivo'),(3,'Tarjeta de Crédito'),(2,'Tarjeta de Débito'),(4,'Transferencia');
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
INSERT INTO `notificaciones` VALUES (17,9,'cuenta','¡Bienvenido a KARMA!','Tu cuenta quedó lista. Desde tu perfil puedes revisar pedidos, citas y vehículos de interés.','perfil.php',0,'2026-10-04 16:13:31'),(18,9,'cita','Apartado de vehículo agendada (CITA-01-000004)','Porsche 911 GT3 · Manzanillo · 5 oct 2026, 10:00. Te esperamos.','perfil.php#citas',0,'2026-10-04 16:14:34'),(19,9,'pedido','Pedido WEB-01-000011 recibido','Tus piezas quedaron apartadas en Manzanillo. Paga en efectivo al recogerlas en caja.','pedido.php?id=11',0,'2026-10-04 17:09:53'),(20,9,'pedido','Pedido WEB-01-000011 pagado en caja','Recibimos tu pago en efectivo. ¡Gracias por tu compra en KARMA!','pedido.php?id=11',0,'2026-10-05 22:32:10');
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
INSERT INTO `productos` VALUES (1,1,'KRM-P911-24','911 Carrera 2024','Porsche 911 Carrera 2024',2280000.00,'Porsche','911 Carrera',2024,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Sport Chrono de fábrica y llantas forjadas de 21\".',NULL,NULL,NULL,'Negro','WP0ZZZ990RS100037',NULL),(2,1,'KRM-P911-25','911 Carrera 2025','Porsche 911 Carrera 2025',2350000.00,'Porsche','911 Carrera',2025,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Sport Chrono de fábrica y llantas forjadas de 21\".',NULL,NULL,NULL,'Negro','WP0ZZZ990SS100074','assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb'),(3,1,'KRM-PTAY-25','Taycan Turbo S 2025','Porsche Taycan Turbo S 2025',3180000.00,'Porsche','Taycan Turbo S',2025,'auto','Blanco Carrara','#EDEDEA','Eléctrico de doble motor','—','Doble motor eléctrico con carga ultrarrápida de 270 kW.',NULL,NULL,NULL,'Beige','WP0ZZZY10SS100111',NULL),(4,2,'KRM-ARS7-24','RS7 Sportback 2024','Audi RS7 Sportback 2024',2190000.00,'Audi','RS7 Sportback',2024,'auto','Gris Nardo','#7A7D80','4.0L V8 Biturbo','3993 cc','V8 biturbo con interior en piel Nappa extendida.',NULL,NULL,NULL,'Negro','WUAZZZF20RS100148',NULL),(5,2,'KRM-AQ8E-25','Q8 e-tron 2025','Audi Q8 e-tron 2025',1850000.00,'Audi','Q8 e-tron',2025,'auto','Azul Ultra','#1F3B66','Eléctrico de doble motor','—','Doble motor eléctrico y techo panorámico solar.',NULL,NULL,NULL,'Café','WA1ZZZFE0SS100185',NULL),(6,3,'KRM-DPAN-24','Panigale V4 S 2024','Ducati Panigale V4 S 2024',620000.00,'Ducati','Panigale V4 S',2024,'moto','Rojo Ducati','#9E1B2E','V4 Desmosedici Stradale','1103 cc','Motor V4 con electrónica Öhlins de serie.',NULL,NULL,NULL,NULL,'ZDMZZZPV0RS100222',NULL),(7,3,'KRM-DSTR-25','Streetfighter V4 2025','Ducati Streetfighter V4 2025',590000.00,'Ducati','Streetfighter V4',2025,'moto','Negro Mate','#1A1A1A','V4 Desmosedici Stradale','1103 cc','Motor V4 con winglets aerodinámicos de MotoGP.',NULL,NULL,NULL,NULL,'ZDMZZZSF0SS100259',NULL),(8,4,'KRM-REF-DISCO-911','Disco de freno delantero','Disco de freno delantero para Porsche 911',18500.00,'Porsche','911 Carrera',2024,'refaccion','Acero gris','#8C9096','3.0L Boxer Biturbo',NULL,'Disco delantero izquierdo.','Porsche 911','Trasera','Izquierdo',NULL,NULL,NULL),(9,4,'KRM-REF-PAST-AUDI','Juego de pastillas de freno','Pastillas de freno para Audi RS7',12400.00,'Audi','RS7 Sportback',2024,'refaccion','Negro grafito','#2E2F33','4.0L V8 Biturbo',NULL,'Juego completo para eje delantero.','Audi RS7 Sportback','AWD','Ambos',NULL,NULL,NULL),(10,4,'KRM-REF-BALATA-AUDI','Balata delantera','Balata delantera para Audi RS7',9800.00,'Audi','RS7 Sportback',2024,'refaccion','Negro grafito','#2E2F33','4.0L V8 Biturbo',NULL,NULL,'Audi RS7 Sportback','AWD','Ambos',NULL,NULL,'assets/Modelos_3D/idproducto10_idcategoria4_KRM-REF-BALATA-AUDI_balataDelanteraParaAudiRS7_2024_Negro grafito_refaccion.glb'),(11,2,'KRM-CAT-AUDI-01','A3 2025','Audi A3 2025, motor 1.4L TFSI Turbo.',665281.24,'Audi','A3',2025,'auto','Gris Nardo','#7A7D80','1.4L TFSI Turbo','1395 cc','Audi A3 equipado de fábrica, listo para entrega en agencia.',NULL,'Delantera',NULL,'Negro','WAUZZZZZ0SS100296',NULL),(12,2,'KRM-CAT-AUDI-02','A4 2024','Audi A4 2024, motor 2.0L TFSI Turbo.',812356.66,'Audi','A4',2024,'auto','Blanco Glaciar','#F2F2EF','2.0L TFSI Turbo','1984 cc','Audi A4 equipado de fábrica, listo para entrega en agencia.',NULL,'Delantera',NULL,'Negro','WAUZZZZZ0RS100333',NULL),(13,2,'KRM-CAT-AUDI-03','A5 2025','Audi A5 2025, motor 2.0L TFSI Turbo.',946010.16,'Audi','A5',2025,'auto','Gris Nardo','#7A7D80','2.0L TFSI Turbo','1984 cc','Audi A5 equipado de fábrica, listo para entrega en agencia.',NULL,'Delantera',NULL,'Negro','WAUZZZZZ0SS100370',NULL),(14,2,'KRM-CAT-AUDI-04','A6 2025','Audi A6 2025, motor 3.0L V6 TFSI.',1166650.62,'Audi','A6',2025,'auto','Gris Nardo','#7A7D80','3.0L V6 TFSI','2995 cc','Audi A6 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100407',NULL),(15,2,'KRM-CAT-AUDI-05','A7 2023','Audi A7 2023, motor 3.0L V6 TFSI.',1206138.70,'Audi','A7',2023,'auto','Gris Nardo','#7A7D80','3.0L V6 TFSI','2995 cc','Audi A7 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100444',NULL),(16,2,'KRM-CAT-AUDI-06','A8 2023','Audi A8 2023, motor 3.0L V6 TFSI.',1809054.93,'Audi','A8',2023,'auto','Rojo Tango','#8C1D2B','3.0L V6 TFSI','2995 cc','Audi A8 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Beige','WAUZZZZZ0PS100481',NULL),(17,2,'KRM-CAT-AUDI-07','Q3 2025','Audi Q3 2025, motor 2.0L TFSI Turbo.',858687.40,'Audi','Q3',2025,'auto','Blanco Glaciar','#F2F2EF','2.0L TFSI Turbo','1984 cc','Audi Q3 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100518',NULL),(18,2,'KRM-CAT-AUDI-08','Q5 2025','Audi Q5 2025, motor 2.0L TFSI Turbo.',1006865.63,'Audi','Q5',2025,'auto','Rojo Tango','#8C1D2B','2.0L TFSI Turbo','1984 cc','Audi Q5 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100555',NULL),(19,2,'KRM-CAT-AUDI-09','Q7 2024','Audi Q7 2024, motor 3.0L V6 TFSI.',1398540.24,'Audi','Q7',2024,'auto','Rojo Tango','#8C1D2B','3.0L V6 TFSI','2995 cc','Audi Q7 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100592',NULL),(20,2,'KRM-CAT-AUDI-10','Q8 2023','Audi Q8 2023, motor 3.0L V6 TFSI.',1743576.89,'Audi','Q8',2023,'auto','Blanco Glaciar','#F2F2EF','3.0L V6 TFSI','2995 cc','Audi Q8 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100629',NULL),(21,2,'KRM-CAT-AUDI-11','RS3 2024','Audi RS3 2024, motor 2.5L TFSI Turbo 5-cil..',1303929.87,'Audi','RS3',2024,'auto','Negro Mythos','#101012','2.5L TFSI Turbo 5-cil.','2480 cc','Audi RS3 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100666',NULL),(22,2,'KRM-CAT-AUDI-12','RS5 2024','Audi RS5 2024, motor 2.9L V6 Biturbo.',1579878.48,'Audi','RS5',2024,'auto','Gris Nardo','#7A7D80','2.9L V6 Biturbo','2894 cc','Audi RS5 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100703',NULL),(23,2,'KRM-CAT-AUDI-13','RS6 2023','Audi RS6 2023, motor 4.0L V8 Biturbo.',2480657.88,'Audi','RS6',2023,'auto','Negro Mythos','#101012','4.0L V8 Biturbo','3993 cc','Audi RS6 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100740',NULL),(24,2,'KRM-CAT-AUDI-14','RS7 2025','Audi RS7 2025, motor 4.0L V8 Biturbo.',2297617.75,'Audi','RS7',2025,'auto','Negro Mythos','#101012','4.0L V8 Biturbo','3993 cc','Audi RS7 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100777',NULL),(25,2,'KRM-CAT-AUDI-15','R8 2025','Audi R8 2025, motor 5.2L V10 FSI.',3469997.91,'Audi','R8',2025,'auto','Azul Ultra','#1F3B66','5.2L V10 FSI','5204 cc','Audi R8 equipado de fábrica, listo para entrega en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100814','assets/Modelos_3D/id25_KRM-CAT-AUDI-15_audiR8_2025_AzulUltra.glb'),(26,1,'KRM-CAT-POR-01','718 Cayman 2024','Porsche 718 Cayman 2024, motor 2.0L Turbo Flat-4.',1361240.78,'Porsche','718 Cayman',2024,'auto','Blanco Carrara','#EDEDEA','2.0L Turbo Flat-4','1988 cc','Porsche 718 Cayman equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0RS100851',NULL),(27,1,'KRM-CAT-POR-02','718 Boxster 2025','Porsche 718 Boxster 2025, motor 2.0L Turbo Flat-4.',1465107.75,'Porsche','718 Boxster',2025,'auto','Azul Gentian','#1B3A6B','2.0L Turbo Flat-4','1988 cc','Porsche 718 Boxster equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0SS100888',NULL),(28,1,'KRM-CAT-POR-03','911 Carrera 2024','Porsche 911 Carrera 2024, motor 3.0L Boxer Biturbo.',1996608.97,'Porsche','911 Carrera',2024,'auto','Azul Gentian','#1B3A6B','3.0L Boxer Biturbo','2981 cc','Porsche 911 Carrera equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0RS100925',NULL),(29,1,'KRM-CAT-POR-04','911 Carrera S 2023','Porsche 911 Carrera S 2023, motor 3.0L Boxer Biturbo.',2338828.86,'Porsche','911 Carrera S',2023,'auto','Blanco Carrara','#EDEDEA','3.0L Boxer Biturbo','2981 cc','Porsche 911 Carrera S equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0PS100962',NULL),(30,1,'KRM-CAT-POR-05','911 Turbo 2024','Porsche 911 Turbo 2024, motor 3.7L Boxer Biturbo.',3646135.38,'Porsche','911 Turbo',2024,'auto','Blanco Carrara','#EDEDEA','3.7L Boxer Biturbo','3745 cc','Porsche 911 Turbo equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS100999',NULL),(31,1,'KRM-CAT-POR-06','911 GT3 2023','Porsche 911 GT3 2023, motor 4.0L Boxer Atmosférico.',3520336.58,'Porsche','911 GT3',2023,'auto','Rojo Carmín','#9E1B2E','4.0L Boxer Atmosférico','3996 cc','Porsche 911 GT3 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0PS101036',NULL),(32,1,'KRM-CAT-POR-07','911 GT3 RS 2025','Porsche 911 GT3 RS 2025, motor 4.0L Boxer Atmosférico.',4209809.72,'Porsche','911 GT3 RS',2025,'auto','Gris GT Plata','#9EA0A1','4.0L Boxer Atmosférico','3996 cc','Porsche 911 GT3 RS equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101073',NULL),(33,1,'KRM-CAT-POR-08','911 Targa 2024','Porsche 911 Targa 2024, motor 3.0L Boxer Biturbo.',2413985.87,'Porsche','911 Targa',2024,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Porsche 911 Targa equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS101110',NULL),(34,1,'KRM-CAT-POR-09','Taycan 2025','Porsche Taycan 2025, motor Eléctrico de doble motor.',2492779.35,'Porsche','Taycan',2025,'auto','Blanco Carrara','#EDEDEA','Eléctrico de doble motor','—','Porsche Taycan equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101147',NULL),(35,1,'KRM-CAT-POR-10','Taycan Turbo 2023','Porsche Taycan Turbo 2023, motor Eléctrico de doble motor.',3296579.71,'Porsche','Taycan Turbo',2023,'auto','Azul Gentian','#1B3A6B','Eléctrico de doble motor','—','Porsche Taycan Turbo equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101184',NULL),(36,1,'KRM-CAT-POR-11','Panamera 2023','Porsche Panamera 2023, motor 2.9L V6 Biturbo.',2010461.38,'Porsche','Panamera',2023,'auto','Rojo Carmín','#9E1B2E','2.9L V6 Biturbo','2894 cc','Porsche Panamera equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera',NULL,'Negro','WP0ZZZZZ0PS101221',NULL),(37,1,'KRM-CAT-POR-12','Panamera Turbo 2025','Porsche Panamera Turbo 2025, motor 4.0L V8 Biturbo.',2846312.51,'Porsche','Panamera Turbo',2025,'auto','Azul Gentian','#1B3A6B','4.0L V8 Biturbo','3996 cc','Porsche Panamera Turbo equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101258',NULL),(38,1,'KRM-CAT-POR-13','Macan 2024','Porsche Macan 2024, motor 2.0L Turbo.',1387139.15,'Porsche','Macan',2024,'auto','Blanco Carrara','#EDEDEA','2.0L Turbo','1984 cc','Porsche Macan equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS101295',NULL),(39,1,'KRM-CAT-POR-14','Cayenne 2023','Porsche Cayenne 2023, motor 3.0L V6 Turbo.',1751851.73,'Porsche','Cayenne',2023,'auto','Gris GT Plata','#9EA0A1','3.0L V6 Turbo','2995 cc','Porsche Cayenne equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101332',NULL),(40,1,'KRM-CAT-POR-15','Cayenne Turbo 2023','Porsche Cayenne Turbo 2023, motor 4.0L V8 Biturbo.',2825169.72,'Porsche','Cayenne Turbo',2023,'auto','Negro Jeweled','#141414','4.0L V8 Biturbo','3996 cc','Porsche Cayenne Turbo equipado de fábrica, listo para entrega en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101369',NULL),(41,3,'KRM-CAT-DUC-01','Panigale V2 2025','Ducati Panigale V2 2025, motor V2 90°.',400688.50,'Ducati','Panigale V2',2025,'moto','Gris Antracita','#4A4A4A','V2 90°','955 cc','Ducati Panigale V2 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101406','assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb'),(42,3,'KRM-CAT-DUC-02','Panigale V4 2024','Ducati Panigale V4 2024, motor V4 Desmosedici Stradale.',615698.60,'Ducati','Panigale V4',2024,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Panigale V4 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101443',NULL),(43,3,'KRM-CAT-DUC-03','Panigale V4 S 2025','Ducati Panigale V4 S 2025, motor V4 Desmosedici Stradale.',584572.86,'Ducati','Panigale V4 S',2025,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Panigale V4 S equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101480',NULL),(44,3,'KRM-CAT-DUC-04','Monster 2023','Ducati Monster 2023, motor V2 Testastretta.',332543.44,'Ducati','Monster',2023,'moto','Negro Mate','#1A1A1A','V2 Testastretta','937 cc','Ducati Monster equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101517',NULL),(45,3,'KRM-CAT-DUC-05','Monster SP 2025','Ducati Monster SP 2025, motor V2 Testastretta.',374228.00,'Ducati','Monster SP',2025,'moto','Gris Antracita','#4A4A4A','V2 Testastretta','937 cc','Ducati Monster SP equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101554',NULL),(46,3,'KRM-CAT-DUC-06','Multistrada V2 2024','Ducati Multistrada V2 2024, motor V2 Testastretta.',371609.38,'Ducati','Multistrada V2',2024,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','937 cc','Ducati Multistrada V2 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101591',NULL),(47,3,'KRM-CAT-DUC-07','Multistrada V4 2023','Ducati Multistrada V4 2023, motor V4 Granturismo.',485963.66,'Ducati','Multistrada V4',2023,'moto','Blanco Dark','#E7E7E4','V4 Granturismo','1158 cc','Ducati Multistrada V4 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101628',NULL),(48,3,'KRM-CAT-DUC-08','Diavel V4 2023','Ducati Diavel V4 2023, motor V4 Granturismo.',510005.49,'Ducati','Diavel V4',2023,'moto','Rojo Ducati','#9E1B2E','V4 Granturismo','1158 cc','Ducati Diavel V4 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101665',NULL),(49,3,'KRM-CAT-DUC-09','Streetfighter V2 2023','Ducati Streetfighter V2 2023, motor V2 Testastretta.',416324.43,'Ducati','Streetfighter V2',2023,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','955 cc','Ducati Streetfighter V2 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101702',NULL),(50,3,'KRM-CAT-DUC-10','Streetfighter V4 2024','Ducati Streetfighter V4 2024, motor V4 Desmosedici Stradale.',599051.87,'Ducati','Streetfighter V4',2024,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Streetfighter V4 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101739',NULL),(51,3,'KRM-CAT-DUC-11','Scrambler Icon 2024','Ducati Scrambler Icon 2024, motor L-Twin Desmodue.',279596.86,'Ducati','Scrambler Icon',2024,'moto','Gris Antracita','#4A4A4A','L-Twin Desmodue','803 cc','Ducati Scrambler Icon equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101776',NULL),(52,3,'KRM-CAT-DUC-12','Scrambler Nightshift 2023','Ducati Scrambler Nightshift 2023, motor L-Twin Desmodue.',288140.62,'Ducati','Scrambler Nightshift',2023,'moto','Rojo Ducati','#9E1B2E','L-Twin Desmodue','803 cc','Ducati Scrambler Nightshift equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101813',NULL),(53,3,'KRM-CAT-DUC-13','DesertX 2025','Ducati DesertX 2025, motor L-Twin Testastretta.',438049.83,'Ducati','DesertX',2025,'moto','Gris Antracita','#4A4A4A','L-Twin Testastretta','937 cc','Ducati DesertX equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0SS101850',NULL),(54,3,'KRM-CAT-DUC-14','Hypermotard 2024','Ducati Hypermotard 2024, motor V2 Testastretta.',444801.61,'Ducati','Hypermotard',2024,'moto','Rojo Ducati','#9E1B2E','V2 Testastretta','937 cc','Ducati Hypermotard equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0RS101887',NULL),(55,3,'KRM-CAT-DUC-15','SuperSport 950 2023','Ducati SuperSport 950 2023, motor V2 Testastretta.',359002.51,'Ducati','SuperSport 950',2023,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','937 cc','Ducati SuperSport 950 equipado de fábrica, listo para entrega en agencia.',NULL,'Trasera (cadena)',NULL,NULL,'ZDMZZZZZ0PS101924',NULL),(56,4,'KRM-CAT-REF-AUDI-01','Filtro de aceite Audi','Filtro de aceite original/compatible para Audi RS5.',508.87,'Audi','RS5',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS5',NULL,NULL,NULL,NULL,NULL),(57,4,'KRM-CAT-REF-AUDI-02','Filtro de aire Audi','Filtro de aire original/compatible para Audi A7.',666.81,'Audi','A7',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi A7',NULL,NULL,NULL,NULL,NULL),(58,4,'KRM-CAT-REF-AUDI-03','Juego de pastillas de freno delanteras Audi','Juego de pastillas de freno delanteras original/compatible para Audi RS6.',3984.05,'Audi','RS6',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS6','Delantera',NULL,NULL,NULL,NULL),(59,4,'KRM-CAT-REF-AUDI-04','Juego de pastillas de freno traseras Audi','Juego de pastillas de freno traseras original/compatible para Audi R8.',3560.70,'Audi','R8',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi R8','Trasera',NULL,NULL,NULL,NULL),(60,4,'KRM-CAT-REF-AUDI-05','Disco de freno delantero Audi','Disco de freno delantero original/compatible para Audi RS3.',6580.71,'Audi','RS3',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS3','Delantera','Izquierdo',NULL,NULL,NULL),(61,4,'KRM-CAT-REF-AUDI-06','Disco de freno trasero Audi','Disco de freno trasero original/compatible para Audi RS3.',5907.23,'Audi','RS3',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS3','Trasera','Derecho',NULL,NULL,NULL),(62,4,'KRM-CAT-REF-AUDI-07','Juego de bujías Audi','Juego de bujías original/compatible para Audi A6.',1369.46,'Audi','A6',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi A6',NULL,NULL,NULL,NULL,NULL),(63,4,'KRM-CAT-REF-AUDI-08','Batería Audi','Batería original/compatible para Audi RS6.',4918.41,'Audi','RS6',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS6',NULL,NULL,NULL,NULL,NULL),(64,4,'KRM-CAT-REF-AUDI-09','Kit de distribución Audi','Kit de distribución original/compatible para Audi RS6.',10462.38,'Audi','RS6',NULL,'refaccion','Negro','#202124',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS6',NULL,NULL,NULL,NULL,NULL),(65,4,'KRM-CAT-REF-AUDI-10','Bomba de agua Audi','Bomba de agua original/compatible para Audi R8.',3312.33,'Audi','R8',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi R8',NULL,NULL,NULL,NULL,NULL),(66,4,'KRM-CAT-REF-POR-01','Filtro de aceite Porsche','Filtro de aceite original/compatible para Porsche 911 GT3.',479.12,'Porsche','911 GT3',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 911 GT3',NULL,NULL,NULL,NULL,NULL),(67,4,'KRM-CAT-REF-POR-02','Filtro de aire Porsche','Filtro de aire original/compatible para Porsche 718 Boxster.',662.57,'Porsche','718 Boxster',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 718 Boxster',NULL,NULL,NULL,NULL,NULL),(68,4,'KRM-CAT-REF-POR-03','Juego de pastillas de freno delanteras Porsche','Juego de pastillas de freno delanteras original/compatible para Porsche Cayenne Turbo.',4526.14,'Porsche','Cayenne Turbo',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Cayenne Turbo','Delantera',NULL,NULL,NULL,NULL),(69,4,'KRM-CAT-REF-POR-04','Juego de pastillas de freno traseras Porsche','Juego de pastillas de freno traseras original/compatible para Porsche Macan.',3682.97,'Porsche','Macan',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Macan','Trasera',NULL,NULL,NULL,NULL),(70,4,'KRM-CAT-REF-POR-05','Disco de freno delantero Porsche','Disco de freno delantero original/compatible para Porsche 718 Cayman.',6518.07,'Porsche','718 Cayman',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 718 Cayman','Delantera','Izquierdo',NULL,NULL,NULL),(71,4,'KRM-CAT-REF-POR-06','Disco de freno trasero Porsche','Disco de freno trasero original/compatible para Porsche Taycan Turbo.',6321.92,'Porsche','Taycan Turbo',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Taycan Turbo','Trasera','Derecho',NULL,NULL,NULL),(72,4,'KRM-CAT-REF-POR-07','Juego de bujías Porsche','Juego de bujías original/compatible para Porsche 718 Boxster.',1503.80,'Porsche','718 Boxster',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 718 Boxster',NULL,NULL,NULL,NULL,NULL),(73,4,'KRM-CAT-REF-POR-08','Batería Porsche','Batería original/compatible para Porsche Cayenne.',4841.58,'Porsche','Cayenne',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Cayenne',NULL,NULL,NULL,NULL,NULL),(74,4,'KRM-CAT-REF-POR-09','Kit de distribución Porsche','Kit de distribución original/compatible para Porsche Macan.',9851.28,'Porsche','Macan',NULL,'refaccion','Negro','#202124',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Macan',NULL,NULL,NULL,NULL,NULL),(75,4,'KRM-CAT-REF-POR-10','Bomba de agua Porsche','Bomba de agua original/compatible para Porsche 911 Carrera.',3385.95,'Porsche','911 Carrera',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 911 Carrera',NULL,NULL,NULL,NULL,NULL),(76,4,'KRM-CAT-REF-DUC-01','Filtro de aceite Ducati','Filtro de aceite original/compatible para Ducati Diavel V4.',407.17,'Ducati','Diavel V4',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Diavel V4',NULL,NULL,NULL,NULL,NULL),(77,4,'KRM-CAT-REF-DUC-02','Filtro de aire Ducati','Filtro de aire original/compatible para Ducati Panigale V4 S.',500.45,'Ducati','Panigale V4 S',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Panigale V4 S',NULL,NULL,NULL,NULL,NULL),(78,4,'KRM-CAT-REF-DUC-03','Juego de pastillas de freno delanteras Ducati','Juego de pastillas de freno delanteras original/compatible para Ducati Hypermotard.',2440.93,'Ducati','Hypermotard',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Hypermotard','Delantera',NULL,NULL,NULL,NULL),(79,4,'KRM-CAT-REF-DUC-04','Juego de pastillas de freno traseras Ducati','Juego de pastillas de freno traseras original/compatible para Ducati Monster.',2244.11,'Ducati','Monster',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Monster','Trasera',NULL,NULL,NULL,NULL),(80,4,'KRM-CAT-REF-DUC-05','Disco de freno delantero Ducati','Disco de freno delantero original/compatible para Ducati DesertX.',4354.51,'Ducati','DesertX',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati DesertX','Delantera','Izquierdo',NULL,NULL,NULL),(81,4,'KRM-CAT-REF-DUC-06','Cadena de transmisión Ducati','Cadena de transmisión original/compatible para Ducati Monster.',3205.62,'Ducati','Monster',NULL,'refaccion','Dorado','#B8923A',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Monster',NULL,NULL,NULL,NULL,NULL),(82,4,'KRM-CAT-REF-DUC-07','Kit de bujías Ducati','Kit de bujías original/compatible para Ducati Multistrada V4.',1025.26,'Ducati','Multistrada V4',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Multistrada V4',NULL,NULL,NULL,NULL,NULL),(83,4,'KRM-CAT-REF-DUC-08','Batería Ducati','Batería original/compatible para Ducati Scrambler Icon.',2547.34,'Ducati','Scrambler Icon',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Scrambler Icon',NULL,NULL,NULL,NULL,NULL),(84,4,'KRM-CAT-REF-DUC-09','Maneta de freno/embrague Ducati','Maneta de freno/embrague original/compatible para Ducati SuperSport 950.',1203.37,'Ducati','SuperSport 950',NULL,'refaccion','Negro anodizado','#2A2B2F',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati SuperSport 950',NULL,'Derecho',NULL,NULL,NULL),(85,4,'KRM-CAT-REF-DUC-10','Espejo retrovisor Ducati','Espejo retrovisor original/compatible para Ducati Panigale V4.',854.10,'Ducati','Panigale V4',NULL,'refaccion','Negro mate','#1A1A1A',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Panigale V4',NULL,'Izquierdo',NULL,NULL,NULL),(86,4,'KRM-CAT-ACC-AUDI-01','Tapetes de hule para todo clima Audi Q5','Juego de tapetes de hule a la medida para Audi Q5.',3290.00,'Audi','Q5',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Juego de 4 piezas con bordes elevados.','Audi Q5',NULL,NULL,NULL,NULL,NULL),(87,4,'KRM-CAT-ACC-AUDI-02','Barras portaequipaje para techo Audi Q3','Barras transversales de aluminio para el techo del Audi Q3.',6890.00,'Audi','Q3',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Par de barras con cerradura antirrobo.','Audi Q3',NULL,NULL,NULL,NULL,NULL),(88,4,'KRM-CAT-ACC-AUDI-03','Organizador plegable de cajuela Audi','Organizador plegable con divisiones ajustables para cajuela.',1450.00,'Audi','A4',NULL,'refaccion','Negro','#202124',NULL,NULL,'Divisiones ajustables y base antiderrapante.','Audi A4 / A6 / Q5',NULL,NULL,NULL,NULL,NULL),(89,4,'KRM-CAT-ACC-POR-01','Funda de interior a la medida Porsche 911','Funda transpirable a la medida para el Porsche 911.',9850.00,'Porsche','911 Carrera',NULL,'refaccion','Gris','#6E7175',NULL,NULL,'Funda para uso en interior con bolsa de guardado.','Porsche 911 (992)',NULL,NULL,NULL,NULL,NULL),(90,4,'KRM-CAT-ACC-POR-02','Tapetes premium con ribete Porsche Macan','Tapetes de alfombra premium con ribete para Porsche Macan.',4590.00,'Porsche','Macan',NULL,'refaccion','Negro','#141414',NULL,NULL,'Juego de 4 piezas con respaldo antiderrapante.','Porsche Macan',NULL,NULL,NULL,NULL,NULL),(91,4,'KRM-CAT-ACC-POR-03','Cargador portátil para vehículo eléctrico Porsche Taycan','Cargador portátil de hasta 11 kW con conector Tipo 2.',18900.00,'Porsche','Taycan',NULL,'refaccion','Negro','#1A1A1A',NULL,NULL,'Incluye estuche de transporte.','Porsche Taycan',NULL,NULL,NULL,NULL,NULL),(92,4,'KRM-CAT-ACC-DUC-01','Maletas laterales rígidas Ducati Multistrada V4','Par de maletas laterales de aluminio para Multistrada V4.',21500.00,'Ducati','Multistrada V4',NULL,'refaccion','Aluminio','#BFC3C7',NULL,NULL,'Par de maletas con soportes de liberación rápida.','Ducati Multistrada V4',NULL,NULL,NULL,NULL,NULL),(93,4,'KRM-CAT-ACC-DUC-02','Parabrisas touring Ducati Multistrada','Parabrisas touring de mayor altura para Multistrada.',4250.00,'Ducati','Multistrada V4',NULL,'refaccion','Transparente','#D8DDE3',NULL,NULL,'Policarbonato de 4 mm con tratamiento antirrayas.','Ducati Multistrada V2 / V4',NULL,NULL,NULL,NULL,NULL),(94,4,'KRM-CAT-ACC-DUC-03','Funda para motocicleta Ducati','Funda de exterior impermeable con protección UV.',2890.00,'Ducati','Panigale V4',NULL,'refaccion','Negro','#1A1A1A',NULL,NULL,'Incluye orificios para candado y bolsa de transporte.','Ducati Panigale / Streetfighter',NULL,NULL,NULL,NULL,NULL);
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
    -- Código de barras vacío = se genera con el formato KRM-CAT-…
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
INSERT INTO `productos_web` VALUES (11,'vehiculos',1,0,'nuevo','Hatchback','assets/Catalogo/vehiculos/audi/a3.webp',NULL,'S tronic de 7 velocidades','150 hp','8.4 s','El Audi A3 Sportback reúne la esencia premium de Audi en un formato compacto y versátil. Su motor TFSI turbo responde al instante con consumos contenidos, y su interior digital con Audi virtual cockpit lo convierte en el compañero ideal para la ciudad y los viajes de fin de semana.','Audi virtual cockpit de 10.25\"\nPantalla MMI táctil con Apple CarPlay y Android Auto\nFaros LED con firma luminosa diurna\nControl de crucero adaptativo y asistente de carril\nModos de manejo Audi drive select\nRines de aleación de 17\"',1,'2026-10-03 14:44:13'),(12,'vehiculos',1,0,'nuevo','Sedán','assets/Catalogo/vehiculos/audi/a4.webp',NULL,'S tronic de 7 velocidades','201 hp','7.3 s','El Audi A4 Sedán es un referente del segmento ejecutivo: aplomo en carretera, aislamiento acústico sobresaliente y una cabina que equilibra tecnología y confort. Una elección inteligente para quien recorre largas distancias sin renunciar a la deportividad.','Motor 2.0 TFSI con sistema mild hybrid de 12 V\nClimatizador automático de tres zonas\nAsientos delanteros con ajuste eléctrico\nFrenado de emergencia Audi pre sense city\nCalaveras LED con intermitentes dinámicos\nCajuela de 460 litros',2,'2026-10-03 14:44:13'),(13,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/a5.webp',NULL,'S tronic de 7 velocidades','201 hp','7.7 s','El Audi A5 Sportback combina la silueta de un coupé con la practicidad de cinco puertas. Líneas fluidas, portón trasero de gran apertura y un habitáculo digital de última generación lo convierten en el gran turismo de la gama media.','Diseño Sportback de cinco puertas\nPantalla panorámica curva MMI\nHead-up display\nSuspensión deportiva\nSistema de audio premium de 16 bocinas\nPortón trasero eléctrico',3,'2026-10-03 14:44:13'),(14,'vehiculos',1,1,'nuevo','Sedán','assets/Catalogo/vehiculos/audi/a6.webp',NULL,'S tronic de 7 velocidades','340 hp','5.1 s','El Audi A6 es la expresión del lujo progresivo: un sedán de gran formato con tracción quattro, motor V6 TFSI y una cabina con doble pantalla táctil con respuesta háptica. Confort de primera clase con la precisión dinámica que distingue a Audi.','Motor 3.0 V6 TFSI con mild hybrid de 48 V\nTracción integral quattro\nDoble pantalla MMI touch response\nFaros HD Matrix LED\nSuspensión adaptativa\nCámara de 360° para estacionarse',4,'2026-10-03 14:44:13'),(15,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/a7.webp',NULL,'S tronic de 7 velocidades','340 hp','5.3 s','El Audi A7 Sportback es un gran turismo de cuatro puertas con alma de coupé. Su diseño escultural, el alerón trasero desplegable y la tracción quattro hacen de cada trayecto una experiencia elegante y emocionante.','Alerón trasero activo\nTracción integral quattro\nFaros HD Matrix LED\nInterior en piel Valcona\nTecho panorámico\nPaquete de asistentes de conducción Tour',5,'2026-10-03 14:44:13'),(16,'vehiculos',1,0,'nuevo','Sedán de lujo','assets/Catalogo/vehiculos/audi/a8.webp',NULL,'Tiptronic de 8 velocidades','340 hp','5.6 s','El Audi A8 es el buque insignia de la marca: un sedán de representación con un nivel de refinamiento, silencio y tecnología pensado tanto para quien conduce como para quien viaja atrás. Cada detalle está diseñado para el máximo confort.','Suspensión neumática adaptativa\nAsientos con masaje y ventilación\nIluminación ambiental de 30 colores\nClimatizador de cuatro zonas\nPuertas con cierre asistido\nSistema de audio 3D premium',6,'2026-10-03 14:44:13'),(17,'vehiculos',1,0,'nuevo','SUV','assets/Catalogo/vehiculos/audi/q3.webp',NULL,'S tronic de 7 velocidades','190 hp','7.3 s','El Audi Q3 es la SUV compacta para la vida urbana con espíritu aventurero: posición de manejo elevada, cajuela flexible gracias a la banca trasera deslizable y tracción quattro para mayor seguridad en cualquier camino.','Tracción integral quattro\nBanca trasera deslizable y reclinable\nAudi virtual cockpit\nPortón trasero eléctrico\nCámara de reversa\nSensores de estacionamiento delanteros y traseros',7,'2026-10-03 14:44:13'),(18,'vehiculos',1,1,'nuevo','SUV','assets/Catalogo/vehiculos/audi/q5.webp',NULL,'S tronic de 7 velocidades','261 hp','6.1 s','El Audi Q5 es la SUV mediana más equilibrada de la gama: espacio para cinco ocupantes, tracción quattro y un motor TFSI que entrega potencia con suavidad. Ideal para la familia que busca versatilidad y prestigio.','Tracción quattro con tecnología ultra\nFaros LED Matrix\nPantalla MMI de 10.1\"\nAlerta de tráfico cruzado trasero\nCajuela de 520 litros\nPreparación para enganche de remolque',8,'2026-10-03 14:44:13'),(19,'vehiculos',1,0,'nuevo','SUV 7 plazas','assets/Catalogo/vehiculos/audi/q7.webp',NULL,'Tiptronic de 8 velocidades','335 hp','5.9 s','El Audi Q7 ofrece tres filas de asientos, tracción quattro y la serenidad de un vehículo de lujo. Con su motor V6 TFSI y suspensión adaptativa, recorre ciudad y carretera con igual soltura.','Tres filas de asientos (7 plazas)\nSuspensión neumática adaptativa\nTracción integral quattro\nClimatizador de cuatro zonas\nDirección en las cuatro ruedas\nTecho panorámico corredizo',9,'2026-10-03 14:44:13'),(20,'vehiculos',1,0,'nuevo','SUV coupé','assets/Catalogo/vehiculos/audi/q8.webp',NULL,'Tiptronic de 8 velocidades','335 hp','5.9 s','El Audi Q8 fusiona la elegancia de un coupé con la presencia de una SUV de lujo. Su parrilla octagonal, las puertas sin marco y una cabina completamente digital lo posicionan como la cumbre de la familia Q.','Diseño SUV coupé con puertas sin marco\nRines de 21\"\nDoble pantalla MMI touch response\nTracción integral quattro\nFaros HD Matrix LED\nAsistente de conducción en ciudad y autopista',10,'2026-10-03 14:44:13'),(21,'vehiculos',1,1,'nuevo','Deportivo compacto','assets/Catalogo/vehiculos/audi/rs3.webp',NULL,'S tronic de 7 velocidades','401 hp','3.8 s','El Audi RS 3 es un compacto de altas prestaciones impulsado por el legendario cinco cilindros turbo. Su sonido inconfundible, el diferencial RS Torque Splitter y la suspensión deportiva convierten cada curva en un momento memorable.','Motor 2.5 TFSI de cinco cilindros\nRS Torque Splitter con modo RS Torque Rear\nEscape deportivo RS\nAsientos deportivos RS con costura en panal\nFrenos de alto desempeño\nPantallas RS en el virtual cockpit',11,'2026-10-03 14:44:13'),(22,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/rs5.webp',NULL,'Tiptronic de 8 velocidades','444 hp','3.9 s','El Audi RS 5 Sportback combina cinco puertas con un V6 biturbo de 444 hp y tracción quattro deportiva. Es la definición de un auto de uso diario capaz de emocionar en pista.','Motor 2.9 V6 biturbo\nTracción quattro con diferencial deportivo\nSuspensión RS con Dynamic Ride Control\nPaquete de diseño RS en negro\nEscape deportivo RS\nVolante deportivo RS en Alcantara',12,'2026-10-03 14:44:13'),(23,'vehiculos',1,1,'nuevo','Avant','assets/Catalogo/vehiculos/audi/rs6.webp',NULL,'Tiptronic de 8 velocidades','591 hp','3.6 s','El Audi RS 6 Avant es una de las familiares más deseadas del mundo: un V8 biturbo de 591 hp, carrocería ensanchada y la practicidad de una cajuela de gran capacidad. Desempeño de superdeportivo para el día a día.','Motor 4.0 V8 biturbo con mild hybrid\nCarrocería ensanchada exclusiva RS\nSuspensión neumática adaptativa RS\nDirección en las cuatro ruedas\nFrenos RS de alto desempeño\nCajuela de 565 litros',13,'2026-10-03 14:44:13'),(24,'vehiculos',1,0,'nuevo','Sportback','assets/Catalogo/vehiculos/audi/rs7.webp',NULL,'Tiptronic de 8 velocidades','591 hp','3.6 s','El Audi RS 7 Sportback lleva el diseño del A7 a su máxima expresión deportiva. Su V8 biturbo, la tracción quattro y la suspensión RS ofrecen un equilibrio único entre lujo, elegancia y desempeño.','Motor 4.0 V8 biturbo\nTracción quattro con diferencial deportivo\nFaros HD Matrix LED con luz láser\nEscape deportivo RS\nAsientos RS con ventilación y masaje\nRines de 22\"',14,'2026-10-03 14:44:13'),(25,'vehiculos',1,1,'nuevo','Superdeportivo','assets/Catalogo/vehiculos/audi/r8.webp',NULL,'S tronic de 7 velocidades','602 hp','3.1 s','El Audi R8 V10 performance es el superdeportivo nacido en las pistas de competencia. Motor central V10 atmosférico, chasis de aluminio y fibra de carbono y tracción quattro para una conexión pura entre piloto y camino.','Motor central V10 5.2 FSI atmosférico\nChasis Audi Space Frame de aluminio y CFRP\nTracción integral quattro\nFrenos cerámicos disponibles\nAudi virtual cockpit con modo de pista\nEdición de producción limitada',15,'2026-10-03 14:44:13'),(26,'vehiculos',1,0,'nuevo','Coupé','assets/Catalogo/vehiculos/porsche/718-cayman.webp',NULL,'PDK de 7 velocidades','300 hp','4.9 s','El Porsche 718 Cayman es el deportivo de motor central por excelencia: equilibrio perfecto, dirección precisa y un motor bóxer turbo que responde al instante. Diversión pura en cada curva.','Motor central bóxer turbo de cuatro cilindros\nTransmisión PDK de 7 velocidades\nPorsche Torque Vectoring\nPaquete Sport Chrono\nDos cajuelas: delantera y trasera\nFrenos de alto desempeño',16,'2026-10-03 14:44:13'),(27,'vehiculos',1,0,'nuevo','Roadster','assets/Catalogo/vehiculos/porsche/718-boxster.webp',NULL,'PDK de 7 velocidades','300 hp','4.9 s','El Porsche 718 Boxster es el roadster que convierte cualquier camino en un destino. Su capota eléctrica se abre en segundos y el motor central bóxer ofrece un equilibrio dinámico excepcional.','Capota eléctrica de lona (apertura en 9 s)\nMotor central bóxer turbo\nTransmisión PDK de 7 velocidades\nPorsche Active Suspension Management (PASM)\nAsientos deportivos Plus\nPaquete Sport Chrono',17,'2026-10-03 14:44:13'),(28,'vehiculos',1,1,'nuevo','Coupé','assets/Catalogo/vehiculos/porsche/911-carrera.webp',NULL,'PDK de 8 velocidades','379 hp','4.2 s','El Porsche 911 Carrera es el ícono atemporal de los autos deportivos. Su motor bóxer biturbo montado atrás, la tracción trasera y una ergonomía impecable lo hacen tan disfrutable en el día a día como en un track day.','Motor bóxer biturbo 3.0 de seis cilindros\nTransmisión PDK de 8 velocidades\nPorsche Communication Management (PCM)\nModos de manejo con Sport Response\nRines de 19\" y 20\"\nFaros LED Matrix',18,'2026-10-03 14:44:13'),(29,'vehiculos',1,0,'nuevo','Coupé','assets/Catalogo/vehiculos/porsche/911-carrera-s.webp',NULL,'PDK de 8 velocidades','443 hp','3.7 s','El 911 Carrera S eleva la experiencia con 443 hp, frenos de mayor diámetro y un carácter aún más afilado. La combinación perfecta de confort de gran turismo y desempeño de deportivo puro.','Motor bóxer biturbo de 443 hp\nCalipers rojos de seis pistones\nPASM de serie\nEscape deportivo disponible\nSport Chrono con selector de modos\nRines de 20\" y 21\"',19,'2026-10-03 14:44:13'),(30,'vehiculos',1,1,'nuevo','Coupé','assets/Catalogo/vehiculos/porsche/911-turbo.webp',NULL,'PDK de 8 velocidades','572 hp','2.8 s','El Porsche 911 Turbo es el superdeportivo para todos los días. Tracción integral, aerodinámica activa y un motor biturbo de 572 hp que impulsa de 0 a 100 km/h en menos de tres segundos con una facilidad sorprendente.','Tracción integral Porsche Traction Management\nAerodinámica activa: spoiler y alerón adaptativos\nMotor bóxer 3.7 biturbo\nSuspensión PASM deportiva\nInterior en piel con costuras en contraste\nSistema de audio envolvente premium',20,'2026-10-03 14:44:13'),(31,'vehiculos',1,0,'nuevo','Deportivo de pista','assets/Catalogo/vehiculos/porsche/911-gt3.webp',NULL,'PDK de 7 velocidades','502 hp','3.4 s','El 911 GT3 lleva el ADN del automovilismo a la calle: motor atmosférico de 4.0 litros que gira hasta 9,000 rpm, suspensión delantera de doble horquilla derivada de competencia y alerón trasero fijo para máxima carga aerodinámica.','Motor bóxer atmosférico de 4.0 l y 9,000 rpm\nSuspensión delantera de doble horquilla\nAlerón trasero tipo cuello de cisne\nDirección en el eje trasero\nFrenos cerámicos PCCB disponibles\nModo Track Screen en el tablero',21,'2026-10-03 14:44:13'),(32,'vehiculos',1,1,'nuevo','Deportivo de pista','assets/Catalogo/vehiculos/porsche/911-gt3-rs.webp',NULL,'PDK de 7 velocidades','518 hp','3.2 s','El 911 GT3 RS es una de las versiones más radicales homologadas para calle: aerodinámica activa con DRS, enorme carga aerodinámica y un motor atmosférico de 518 hp. Concebido para dominar el circuito.','Sistema de reducción de arrastre (DRS)\nHasta 860 kg de carga aerodinámica a 285 km/h\nMotor atmosférico de 518 hp\nAjustes de suspensión desde el volante\nPaquete Weissach disponible\nJaula antivuelco disponible',22,'2026-10-03 14:44:13'),(33,'vehiculos',1,0,'nuevo','Targa','assets/Catalogo/vehiculos/porsche/911-targa.webp',NULL,'PDK de 8 velocidades','379 hp','4.4 s','El 911 Targa combina la emoción de un convertible con la seguridad de un coupé gracias a su icónico arco Targa y a un techo que se retrae automáticamente. Tracción integral para disfrutarlo todo el año.','Techo Targa de apertura automática\nArco Targa característico\nTracción integral\nTransmisión PDK de 8 velocidades\nAsientos con calefacción\nFaros LED Matrix',23,'2026-10-03 14:44:13'),(34,'vehiculos',1,0,'nuevo','Sedán eléctrico','assets/Catalogo/vehiculos/porsche/taycan.webp',NULL,'Automática de 2 velocidades (eje trasero)','402 hp','4.8 s','El Porsche Taycan es el deportivo eléctrico que redefine la movilidad sin emisiones: arquitectura de 800 voltios, carga ultrarrápida y la dinámica de manejo que se espera de un Porsche.','Arquitectura eléctrica de 800 V\nCarga rápida en corriente directa\nAutonomía estimada de hasta 500 km (WLTP)\nTransmisión de 2 velocidades en el eje trasero\nPantalla curva de 16.8\"\nPorsche Electric Sport Sound',24,'2026-10-03 14:44:13'),(35,'vehiculos',1,0,'nuevo','Sedán eléctrico','assets/Catalogo/vehiculos/porsche/taycan-turbo.webp',NULL,'Automática de 2 velocidades (eje trasero)','670 hp','3.2 s','El Taycan Turbo lleva la electrificación al límite del desempeño: dos motores, tracción integral y una aceleración contundente que se repite una y otra vez sin perder potencia.','Dos motores eléctricos y tracción integral\nLaunch Control con overboost\nSuspensión neumática adaptativa\nPorsche Dynamic Chassis Control\nCargador a bordo de 22 kW disponible\nInterior sin piel animal disponible',25,'2026-10-03 14:44:13'),(36,'vehiculos',1,0,'nuevo','Gran turismo','assets/Catalogo/vehiculos/porsche/panamera.webp',NULL,'PDK de 8 velocidades','325 hp','5.6 s','El Porsche Panamera es el gran turismo de cuatro plazas que combina el confort de una limusina con el desempeño de un deportivo. Espacio, lujo y emoción para toda la familia.','Motor 2.9 V6 biturbo\nSuspensión neumática adaptativa de tres cámaras\nCuatro asientos individuales\nPorsche Advanced Cockpit\nPortón trasero eléctrico\nAsistente de visión nocturna disponible',26,'2026-10-03 14:44:13'),(37,'vehiculos',1,0,'nuevo','Gran turismo','assets/Catalogo/vehiculos/porsche/panamera-turbo.webp',NULL,'PDK de 8 velocidades','670 hp','3.2 s','El Panamera Turbo representa la máxima expresión del gran turismo Porsche: potencia descomunal, tracción integral y una cabina de lujo artesanal. La forma más rápida de viajar en primera clase.','Motor V8 biturbo de alto desempeño\nTracción integral Porsche Traction Management\nPorsche Active Ride disponible\nInterior en piel extendida\nPantalla para el acompañante\nSistema de audio 3D de alta fidelidad',27,'2026-10-03 14:44:13'),(38,'vehiculos',1,1,'nuevo','SUV','assets/Catalogo/vehiculos/porsche/macan.webp',NULL,'PDK de 7 velocidades','261 hp','6.2 s','El Porsche Macan es el deportivo de su segmento: una SUV compacta con la agilidad y la precisión de manejo que caracterizan a la marca. Versátil para la ciudad y emocionante en carretera.','Tracción integral Porsche Traction Management\nMotor 2.0 turbo\nTransmisión PDK de 7 velocidades\nPantalla táctil PCM de 10.9\"\nPortón trasero eléctrico\nModo Offroad',28,'2026-10-03 14:44:13'),(39,'vehiculos',1,0,'nuevo','SUV','assets/Catalogo/vehiculos/porsche/cayenne.webp',NULL,'Tiptronic S de 8 velocidades','335 hp','5.9 s','El Porsche Cayenne es la SUV que demostró que lujo, espacio y deportividad pueden convivir: interior amplio, gran capacidad de remolque y el manejo inconfundible de un Porsche.','Motor 3.0 V6 turbo\nTracción integral\nSuspensión neumática disponible\nCapacidad de remolque de hasta 3,500 kg\nCajuela de 772 litros\nPorsche InnoDrive con crucero adaptativo',29,'2026-10-03 14:44:13'),(40,'vehiculos',1,0,'nuevo','SUV coupé','assets/Catalogo/vehiculos/porsche/cayenne-turbo.webp',NULL,'Tiptronic S de 8 velocidades','541 hp','3.9 s','El Cayenne Turbo combina la presencia de una SUV de lujo con la potencia de un V8 biturbo: aceleración de deportivo, tracción integral y un interior premium para cinco ocupantes.','Motor 4.0 V8 biturbo\nTracción integral\nPorsche Dynamic Chassis Control\nFrenos Porsche Surface Coated Brake\nEscape deportivo\nAsientos deportivos adaptativos de 18 posiciones',30,'2026-10-03 14:44:13'),(41,'vehiculos',1,0,'nuevo','Superdeportiva','assets/Catalogo/vehiculos/ducati/panigale-v2.webp',NULL,'6 velocidades con Ducati Quick Shift','155 hp','3.2 s','La Ducati Panigale V2 es la superdeportiva bicilíndrica que ofrece las sensaciones de la familia Panigale con un carácter más ligero y accesible. Ideal para dar el salto a la pista.','Motor Superquadro bicilíndrico de 955 cc\nDucati Quick Shift up & down\nControl de tracción y ABS en curva\nPantalla TFT a color\nBasculante monobrazo\nModos de manejo Race, Sport y Street',31,'2026-10-03 14:44:13'),(42,'vehiculos',1,1,'nuevo','Superdeportiva','assets/Catalogo/vehiculos/ducati/panigale-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','215 hp','2.9 s','La Panigale V4 traslada la tecnología de MotoGP a la calle: motor Desmosedici Stradale V4 de 1,103 cc, aerodinámica con alerones y un paquete electrónico de última generación.','Motor Desmosedici Stradale V4 de 1,103 cc\nAlerones aerodinámicos de doble perfil\nDucati Traction Control y Slide Control\nLaunch Control\nPantalla TFT de 5\"\nChasis Front Frame de aluminio',32,'2026-10-03 14:44:13'),(43,'vehiculos',1,0,'nuevo','Superdeportiva','assets/Catalogo/vehiculos/ducati/panigale-v4-s.webp',NULL,'6 velocidades con Ducati Quick Shift','216 hp','2.8 s','La Panigale V4 S suma suspensiones electrónicas Öhlins, rines forjados y batería de litio a la fórmula de la Panigale V4. Es la referencia para quienes buscan el máximo desempeño en pista.','Suspensiones electrónicas Öhlins Smart EC 2.0\nRines forjados de aluminio\nBatería de iones de litio\nFrenos Brembo Stylema\nABS Cornering EVO\nPeso reducido en orden de marcha',33,'2026-10-03 14:44:13'),(44,'vehiculos',1,1,'nuevo','Naked','assets/Catalogo/vehiculos/ducati/monster.webp',NULL,'6 velocidades con Ducati Quick Shift','111 hp','3.6 s','La Ducati Monster es la naked deportiva que inventó un segmento: ligera, ágil y con un motor Testastretta de carácter vibrante. Perfecta para el uso diario y la diversión del fin de semana.','Motor Testastretta 11° de 937 cc\n188 kg en orden de marcha\nDucati Quick Shift\nControl de tracción y ABS en curva\nTablero TFT de 4.3\"\nAsiento de altura ajustable',34,'2026-10-03 14:44:13'),(45,'vehiculos',1,0,'nuevo','Naked','assets/Catalogo/vehiculos/ducati/monster-sp.webp',NULL,'6 velocidades con Ducati Quick Shift','111 hp','3.5 s','La Monster SP es la versión más deportiva de la Monster: suspensiones Öhlins, escape deportivo homologado y frenos Brembo Stylema para un manejo aún más preciso.','Suspensiones Öhlins totalmente ajustables\nFrenos Brembo Stylema\nEscape deportivo homologado\nBatería de litio\nAmortiguador de dirección\nGráficos SP exclusivos',35,'2026-10-03 14:44:13'),(46,'vehiculos',1,0,'nuevo','Adventure touring','assets/Catalogo/vehiculos/ducati/multistrada-v2.webp',NULL,'6 velocidades con Ducati Quick Shift','113 hp','3.9 s','La Multistrada V2 es la compañera ideal para viajar: posición de manejo cómoda, buena protección aerodinámica y un motor Testastretta suave y elástico. Varias motos en una para cualquier tipo de camino.','Motor Testastretta de 937 cc\nParabrisas ajustable\nCuatro modos de manejo\nControl de crucero\nAsiento de altura ajustable\nPreparada para maletas laterales',36,'2026-10-03 14:44:13'),(47,'vehiculos',1,1,'nuevo','Adventure touring','assets/Catalogo/vehiculos/ducati/multistrada-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','170 hp','3.3 s','La Multistrada V4 combina un motor V4 Granturismo de 170 hp con radar delantero y trasero para una experiencia de viaje segura y tecnológica. Lista para cruzar continentes.','Motor V4 Granturismo de 1,158 cc\nRadar delantero y trasero con crucero adaptativo\nPantalla TFT de 6.5\" con navegación\nSuspensión semiactiva Skyhook\nServicio de válvulas cada 60,000 km\nFaros full LED con luz de curva',37,'2026-10-03 14:44:13'),(48,'vehiculos',1,0,'nuevo','Power cruiser','assets/Catalogo/vehiculos/ducati/diavel-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','168 hp','2.6 s','La Diavel V4 es la power cruiser más deportiva: diseño musculoso, motor V4 Granturismo y la capacidad de acelerar como una superdeportiva con la comodidad de una cruiser.','Motor V4 Granturismo de 1,158 cc\nLlanta trasera de 240 mm\nDucati Power Launch\nEscape de cuatro salidas\nIluminación full LED con firma distintiva\nPosición de manejo relajada',38,'2026-10-03 14:44:13'),(49,'vehiculos',1,0,'nuevo','Naked deportiva','assets/Catalogo/vehiculos/ducati/streetfighter-v2.webp',NULL,'6 velocidades con Ducati Quick Shift','153 hp','3.1 s','La Streetfighter V2 es una superdeportiva sin carenado: motor Superquadro de 955 cc, manubrio ancho y un diseño agresivo inspirado en la Panigale. Adrenalina pura para la calle.','Motor Superquadro de 955 cc\nManubrio ancho de aluminio\nBasculante monobrazo\nControl de wheelie\nFrenos Brembo de anclaje radial\nPantalla TFT a color',39,'2026-10-03 14:44:13'),(50,'vehiculos',1,1,'nuevo','Naked deportiva','assets/Catalogo/vehiculos/ducati/streetfighter-v4.webp',NULL,'6 velocidades con Ducati Quick Shift','208 hp','2.9 s','La Streetfighter V4 es una Panigale sin carenado: motor Desmosedici Stradale de 208 hp, alerones biplano y un paquete electrónico de competencia en una naked de diseño inconfundible.','Motor Desmosedici Stradale V4 de 1,103 cc\nAlerones biplano\nControl de tracción y wheelie EVO\nFaros full LED con firma frontal distintiva\nDucati Quick Shift EVO\nPantalla TFT de 5\"',40,'2026-10-03 14:44:13'),(51,'vehiculos',1,0,'nuevo','Scrambler','assets/Catalogo/vehiculos/ducati/scrambler-icon.webp',NULL,'6 velocidades','73 hp','4.6 s','La Scrambler Icon es sinónimo de libertad: estilo atemporal, motor bicilíndrico enfriado por aire fácil de manejar y una ergonomía amigable para todos los niveles. Perfecta para la ciudad y las escapadas.','Motor L-Twin de 803 cc enfriado por aire\nPeso ligero y asiento bajo\nFaro con luz diurna en forma de X\nControl de tracción\nCubiertas de tanque intercambiables\nTablero digital',41,'2026-10-03 14:44:13'),(52,'vehiculos',1,0,'nuevo','Scrambler','assets/Catalogo/vehiculos/ducati/scrambler-nightshift.webp',NULL,'6 velocidades','73 hp','4.6 s','La Scrambler Nightshift interpreta el estilo café racer con un toque urbano: rines de rayos, manubrio plano y acabados oscuros que destacan en cualquier calle.','Rines de rayos\nManubrio plano\nEspejos en los extremos del manubrio\nMotor L-Twin de 803 cc\nAsiento con tapizado especial\nAcabados en color oscuro',42,'2026-10-03 14:44:13'),(53,'vehiculos',1,0,'nuevo','Adventure off-road','assets/Catalogo/vehiculos/ducati/desertx.webp',NULL,'6 velocidades con Ducati Quick Shift','110 hp','3.9 s','La DesertX está inspirada en las legendarias motos de rally: rin delantero de 21\", suspensiones de largo recorrido y modos de manejo off-road para explorar más allá del asfalto.','Rin delantero de 21\" y trasero de 18\"\nSuspensiones de largo recorrido\nModos de manejo Rally y Enduro\nTanque de 21 litros\nPantalla TFT vertical\nProtector de motor de aluminio',43,'2026-10-03 14:44:13'),(54,'vehiculos',1,0,'nuevo','Motard','assets/Catalogo/vehiculos/ducati/hypermotard.webp',NULL,'6 velocidades con Ducati Quick Shift','114 hp','3.4 s','La Hypermotard es pura diversión: geometría de supermotard, posición elevada y un motor Testastretta que invita a jugar en cada curva. Ligera, divertida e irreverente.','Motor Testastretta de 937 cc\nEscape bajo el asiento\nSuspensiones de largo recorrido\nModo Slide by Brake\n178 kg en seco\nManubrio ancho de aluminio',44,'2026-10-03 14:44:13'),(55,'vehiculos',1,0,'nuevo','Sport touring','assets/Catalogo/vehiculos/ducati/supersport-950.webp',NULL,'6 velocidades con Ducati Quick Shift','110 hp','3.6 s','La SuperSport 950 es la deportiva de uso diario: posición de manejo cómoda, protección aerodinámica y un motor Testastretta suave. Ideal para quien quiere estilo deportivo con confort para viajar.','Motor Testastretta 11° de 937 cc\nParabrisas ajustable\nDiseño inspirado en la Panigale V4\nLuces de curva Ducati Cornering Lights\nPantalla TFT de 4.3\"\nAsiento confortable para dos personas',45,'2026-10-03 14:44:13'),(56,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/audi/filtro-aceite.webp',NULL,NULL,NULL,NULL,'Filtro de aceite de alta eficiencia para Audi RS5. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.','Compatible con Audi RS5\nMedio filtrante de alta retención\nIncluye empaque de sellado\nReemplazo recomendado en cada servicio\nGarantía de 6 meses contra defectos de fabricación',46,'2026-10-03 14:44:13'),(57,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/audi/filtro-aire.webp',NULL,NULL,NULL,NULL,'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Audi A7, protegiendo sus componentes y manteniendo el desempeño.','Compatible con Audi A7\nCelulosa reforzada de alta captación\nMarco de poliuretano flexible\nRevisión recomendada cada 15,000 km\nGarantía de 6 meses contra defectos de fabricación',47,'2026-10-03 14:44:13'),(58,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/pastillas-delanteras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Audi RS6. Frenado firme y silencioso desde la primera aplicación.','Compatible con Audi RS6\nCompuesto cerámico de bajo polvo\nIncluye láminas antirruido\nJuego para eje delantero\nGarantía de 6 meses contra defectos de fabricación',48,'2026-10-03 14:44:13'),(59,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/pastillas-traseras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Audi R8. Frenado estable y silencioso.','Compatible con Audi R8\nCompuesto cerámico de bajo polvo\nIncluye láminas antirruido\nJuego para eje trasero\nGarantía de 6 meses contra defectos de fabricación',49,'2026-10-03 14:44:13'),(60,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/disco-delantero.webp',NULL,NULL,NULL,NULL,'Disco de freno delantero ventilado de hierro de alta resistencia para Audi RS3. Disipa el calor de forma eficiente y mantiene un frenado constante.','Compatible con Audi RS3\nDiseño ventilado y perforado\nTratamiento anticorrosión\nSe recomienda cambiar en pares\nGarantía de 6 meses contra defectos de fabricación',50,'2026-10-03 14:44:13'),(61,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/audi/disco-trasero.webp',NULL,NULL,NULL,NULL,'Disco de freno trasero de hierro de alta resistencia para Audi RS3, balanceado para una operación sin vibraciones y con excelente disipación de calor.','Compatible con Audi RS3\nBalanceado de fábrica\nTratamiento anticorrosión\nSe recomienda cambiar en pares\nGarantía de 6 meses contra defectos de fabricación',51,'2026-10-03 14:44:13'),(62,'refacciones',1,0,'nuevo','Encendido y eléctrico','assets/Catalogo/refacciones/audi/bujias.webp',NULL,NULL,NULL,NULL,'Juego de bujías con electrodo de iridio para Audi A6. Encendido preciso, arranque confiable y consumo optimizado.','Compatible con Audi A6\nElectrodo central de iridio\nCalibración de fábrica\nJuego completo para el motor\nGarantía de 6 meses contra defectos de fabricación',52,'2026-10-03 14:44:13'),(63,'refacciones',1,0,'nuevo','Encendido y eléctrico','assets/Catalogo/refacciones/audi/bateria.webp',NULL,NULL,NULL,NULL,'Batería de 12 V libre de mantenimiento para Audi RS6, con alta capacidad de arranque en frío y construcción resistente a vibraciones.','Compatible con Audi RS6\n12 V libre de mantenimiento\nAlta corriente de arranque en frío\nInstalación incluida en sucursal\nGarantía de 6 meses contra defectos de fabricación',53,'2026-10-03 14:44:13'),(64,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/audi/kit-distribucion.webp',NULL,NULL,NULL,NULL,'Kit de distribución completo para Audi RS6: incluye banda, tensor y poleas para garantizar la sincronización exacta del motor.','Compatible con Audi RS6\nIncluye banda, tensor y poleas\nInstalación recomendada en taller\nReemplazo preventivo según kilometraje\nGarantía de 6 meses contra defectos de fabricación',54,'2026-10-03 14:44:13'),(65,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/audi/bomba-agua.webp',NULL,NULL,NULL,NULL,'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Audi R8. Mantiene la temperatura óptima de operación del motor.','Compatible con Audi R8\nCarcasa de aluminio\nImpulsor de alto flujo\nIncluye empaque\nGarantía de 6 meses contra defectos de fabricación',55,'2026-10-03 14:44:13'),(66,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/porsche/filtro-aceite.webp',NULL,NULL,NULL,NULL,'Filtro de aceite de alta eficiencia para Porsche 911 GT3. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.','Compatible con Porsche 911 GT3\nMedio filtrante de alta retención\nIncluye empaque de sellado\nReemplazo recomendado en cada servicio\nGarantía de 6 meses contra defectos de fabricación',56,'2026-10-03 14:44:13'),(67,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/porsche/filtro-aire.webp',NULL,NULL,NULL,NULL,'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Porsche 718 Boxster, protegiendo sus componentes y manteniendo el desempeño.','Compatible con Porsche 718 Boxster\nCelulosa reforzada de alta captación\nMarco de poliuretano flexible\nRevisión recomendada cada 15,000 km\nGarantía de 6 meses contra defectos de fabricación',57,'2026-10-03 14:44:13'),(68,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/pastillas-delanteras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Porsche Cayenne Turbo. Frenado firme y silencioso desde la primera aplicación.','Compatible con Porsche Cayenne Turbo\nCompuesto cerámico de bajo polvo\nIncluye láminas antirruido\nJuego para eje delantero\nGarantía de 6 meses contra defectos de fabricación',58,'2026-10-03 14:44:13'),(69,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/pastillas-traseras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Porsche Macan. Frenado estable y silencioso.','Compatible con Porsche Macan\nCompuesto cerámico de bajo polvo\nIncluye láminas antirruido\nJuego para eje trasero\nGarantía de 6 meses contra defectos de fabricación',59,'2026-10-03 14:44:13'),(70,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/disco-delantero.webp',NULL,NULL,NULL,NULL,'Disco de freno delantero ventilado de hierro de alta resistencia para Porsche 718 Cayman. Disipa el calor de forma eficiente y mantiene un frenado constante.','Compatible con Porsche 718 Cayman\nDiseño ventilado y perforado\nTratamiento anticorrosión\nSe recomienda cambiar en pares\nGarantía de 6 meses contra defectos de fabricación',60,'2026-10-03 14:44:13'),(71,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/porsche/disco-trasero.webp',NULL,NULL,NULL,NULL,'Disco de freno trasero de hierro de alta resistencia para Porsche Taycan Turbo, balanceado para una operación sin vibraciones y con excelente disipación de calor.','Compatible con Porsche Taycan Turbo\nBalanceado de fábrica\nTratamiento anticorrosión\nSe recomienda cambiar en pares\nGarantía de 6 meses contra defectos de fabricación',61,'2026-10-03 14:44:13'),(72,'refacciones',1,0,'nuevo','Encendido y eléctrico','assets/Catalogo/refacciones/porsche/bujias.webp',NULL,NULL,NULL,NULL,'Juego de bujías con electrodo de iridio para Porsche 718 Boxster. Encendido preciso, arranque confiable y consumo optimizado.','Compatible con Porsche 718 Boxster\nElectrodo central de iridio\nCalibración de fábrica\nJuego completo para el motor\nGarantía de 6 meses contra defectos de fabricación',62,'2026-10-03 14:44:13'),(73,'refacciones',1,0,'nuevo','Encendido y eléctrico','assets/Catalogo/refacciones/porsche/bateria.webp',NULL,NULL,NULL,NULL,'Batería de 12 V libre de mantenimiento para Porsche Cayenne, con alta capacidad de arranque en frío y construcción resistente a vibraciones.','Compatible con Porsche Cayenne\n12 V libre de mantenimiento\nAlta corriente de arranque en frío\nInstalación incluida en sucursal\nGarantía de 6 meses contra defectos de fabricación',63,'2026-10-03 14:44:13'),(74,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/porsche/kit-distribucion.webp',NULL,NULL,NULL,NULL,'Kit de distribución completo para Porsche Macan: incluye banda, tensor y poleas para garantizar la sincronización exacta del motor.','Compatible con Porsche Macan\nIncluye banda, tensor y poleas\nInstalación recomendada en taller\nReemplazo preventivo según kilometraje\nGarantía de 6 meses contra defectos de fabricación',64,'2026-10-03 14:44:13'),(75,'refacciones',1,0,'nuevo','Motor','assets/Catalogo/refacciones/porsche/bomba-agua.webp',NULL,NULL,NULL,NULL,'Bomba de agua con carcasa de aluminio e impulsor de alto flujo para Porsche 911 Carrera. Mantiene la temperatura óptima de operación del motor.','Compatible con Porsche 911 Carrera\nCarcasa de aluminio\nImpulsor de alto flujo\nIncluye empaque\nGarantía de 6 meses contra defectos de fabricación',65,'2026-10-03 14:44:13'),(76,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/ducati/filtro-aceite.webp',NULL,NULL,NULL,NULL,'Filtro de aceite de alta eficiencia para Ducati Diavel V4. Retiene partículas metálicas y contaminantes para prolongar la vida del motor; se recomienda reemplazarlo en cada cambio de aceite.','Compatible con Ducati Diavel V4\nMedio filtrante de alta retención\nIncluye empaque de sellado\nReemplazo recomendado en cada servicio\nGarantía de 6 meses contra defectos de fabricación',66,'2026-10-03 14:44:13'),(77,'refacciones',1,0,'nuevo','Filtros','assets/Catalogo/refacciones/ducati/filtro-aire.webp',NULL,NULL,NULL,NULL,'Filtro de aire con medio de celulosa reforzada que asegura el flujo óptimo de aire limpio al motor de Ducati Panigale V4 S, protegiendo sus componentes y manteniendo el desempeño.','Compatible con Ducati Panigale V4 S\nCelulosa reforzada de alta captación\nMarco de poliuretano flexible\nRevisión recomendada cada 15,000 km\nGarantía de 6 meses contra defectos de fabricación',67,'2026-10-03 14:44:13'),(78,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/ducati/pastillas-delanteras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno delanteras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Ducati Hypermotard. Frenado firme y silencioso desde la primera aplicación.','Compatible con Ducati Hypermotard\nCompuesto cerámico de bajo polvo\nIncluye láminas antirruido\nJuego para eje delantero\nGarantía de 6 meses contra defectos de fabricación',68,'2026-10-03 14:44:13'),(79,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/ducati/pastillas-traseras.webp',NULL,NULL,NULL,NULL,'Juego de pastillas de freno traseras con compuesto de bajo polvo y alto coeficiente de fricción, diseñadas para Ducati Monster. Frenado estable y silencioso.','Compatible con Ducati Monster\nCompuesto cerámico de bajo polvo\nIncluye láminas antirruido\nJuego para eje trasero\nGarantía de 6 meses contra defectos de fabricación',69,'2026-10-03 14:44:13'),(80,'refacciones',1,0,'nuevo','Frenos','assets/Catalogo/refacciones/ducati/disco-delantero.webp',NULL,NULL,NULL,NULL,'Disco de freno delantero ventilado de hierro de alta resistencia para Ducati DesertX. Disipa el calor de forma eficiente y mantiene un frenado constante.','Compatible con Ducati DesertX\nDiseño ventilado y perforado\nTratamiento anticorrosión\nSe recomienda cambiar en pares\nGarantía de 6 meses contra defectos de fabricación',70,'2026-10-03 14:44:13'),(81,'refacciones',1,0,'nuevo','Transmisión','assets/Catalogo/refacciones/ducati/cadena-transmision.webp',NULL,NULL,NULL,NULL,'Cadena de transmisión con retenes X-Ring para Ducati Monster. Mayor durabilidad y menor fricción al transmitir la potencia del motor a la rueda trasera.','Compatible con Ducati Monster\nRetenes X-Ring\nEslabón de unión remachable\nLubricación de larga duración\nGarantía de 6 meses contra defectos de fabricación',71,'2026-10-03 14:44:13'),(82,'refacciones',1,0,'nuevo','Encendido y eléctrico','assets/Catalogo/refacciones/ducati/kit-bujias.webp',NULL,NULL,NULL,NULL,'Juego de bujías con electrodo de iridio para Ducati Multistrada V4. Encendido preciso, arranque confiable y consumo optimizado.','Compatible con Ducati Multistrada V4\nElectrodo central de iridio\nCalibración de fábrica\nJuego completo para el motor\nGarantía de 6 meses contra defectos de fabricación',72,'2026-10-03 14:44:13'),(83,'refacciones',1,0,'nuevo','Encendido y eléctrico','assets/Catalogo/refacciones/ducati/bateria.webp',NULL,NULL,NULL,NULL,'Batería de 12 V libre de mantenimiento para Ducati Scrambler Icon, con alta capacidad de arranque en frío y construcción resistente a vibraciones.','Compatible con Ducati Scrambler Icon\n12 V libre de mantenimiento\nAlta corriente de arranque en frío\nInstalación incluida en sucursal\nGarantía de 6 meses contra defectos de fabricación',73,'2026-10-03 14:44:13'),(84,'refacciones',1,0,'nuevo','Controles','assets/Catalogo/refacciones/ducati/maneta-freno-embrague.webp',NULL,NULL,NULL,NULL,'Maneta de freno/embrague de aluminio anodizado con ajuste de distancia para Ducati SuperSport 950. Tacto preciso y ergonomía mejorada.','Compatible con Ducati SuperSport 950\nAluminio anodizado\nAjuste de distancia en 6 posiciones\nInstalación directa\nGarantía de 6 meses contra defectos de fabricación',74,'2026-10-03 14:44:13'),(85,'refacciones',1,0,'nuevo','Carrocería','assets/Catalogo/refacciones/ducati/espejo-retrovisor.webp',NULL,NULL,NULL,NULL,'Espejo retrovisor con cristal antirreflejante y soporte reforzado para Ducati Panigale V4. Visibilidad amplia con diseño aerodinámico.','Compatible con Ducati Panigale V4\nCristal antirreflejante\nSoporte reforzado\nAjuste en varias posiciones\nGarantía de 6 meses contra defectos de fabricación',75,'2026-10-03 14:44:13'),(86,'accesorios',1,0,'nuevo','Interior','assets/Catalogo/accesorios/tapetes-audi.webp',NULL,NULL,NULL,NULL,'Juego de tapetes de hule moldeados a la medida del Audi Q5. Sus bordes elevados retienen agua, lodo y arena, protegiendo la alfombra original en cualquier temporada.','Compatible con Audi Q5\nJuego de 4 piezas a la medida\nBordes elevados que contienen líquidos\nMaterial antiderrapante y fácil de lavar\nAnclajes de fijación originales',76,'2026-10-03 14:44:13'),(87,'accesorios',1,0,'nuevo','Exterior','assets/Catalogo/accesorios/barras-techo-audi.webp',NULL,NULL,NULL,NULL,'Barras transversales de aluminio aerodinámico para el Audi Q3. Base ideal para portabicicletas, portaesquís o cajas de techo, con sistema de bloqueo antirrobo.','Compatible con Audi Q3\nPerfil aerodinámico de bajo ruido\nCapacidad de carga de 75 kg\nCerradura con llave antirrobo\nInstalación sin herramientas especiales',77,'2026-10-03 14:44:13'),(88,'accesorios',1,0,'nuevo','Organización','assets/Catalogo/accesorios/organizador-cajuela-audi.webp',NULL,NULL,NULL,NULL,'Organizador plegable con divisiones ajustables que mantiene en orden las compras, herramientas y artículos deportivos dentro de la cajuela.','Compatible con Audi A4 / A6 / Q5\nDivisiones ajustables con velcro\nBase antiderrapante\nSe pliega cuando no se usa\nCompatible con A4, A6 y Q5',78,'2026-10-03 14:44:13'),(89,'accesorios',1,0,'nuevo','Protección','assets/Catalogo/accesorios/funda-interior-porsche.webp',NULL,NULL,NULL,NULL,'Funda transpirable a la medida del Porsche 911 para uso en interior. Protege la pintura del polvo y los rayones mientras permite la circulación del aire.','Compatible con Porsche 911 (992)\nCorte a la medida del 911 (992)\nTejido suave y transpirable\nInterior afelpado que cuida la pintura\nIncluye bolsa de almacenamiento',79,'2026-10-03 14:44:13'),(90,'accesorios',1,0,'nuevo','Interior','assets/Catalogo/accesorios/tapetes-premium-porsche.webp',NULL,NULL,NULL,NULL,'Tapetes de alfombra premium con ribete y respaldo antiderrapante, diseñados a la medida del Porsche Macan.','Compatible con Porsche Macan\nAlfombra de alta densidad\nRibete en piel sintética\nRespaldo antiderrapante\nJuego de 4 piezas',80,'2026-10-03 14:44:13'),(91,'accesorios',1,0,'nuevo','Carga eléctrica','assets/Catalogo/accesorios/cargador-portatil-porsche.webp',NULL,NULL,NULL,NULL,'Cargador portátil de hasta 11 kW con conector Tipo 2 para el Porsche Taycan. Permite cargar en casa o en cualquier contacto industrial compatible.','Compatible con Porsche Taycan\nPotencia de carga de hasta 11 kW\nConector Tipo 2\nCable de 7.5 metros\nEstuche de transporte incluido',81,'2026-10-03 14:44:13'),(92,'accesorios',1,0,'nuevo','Equipaje','assets/Catalogo/accesorios/maletas-laterales-ducati.webp',NULL,NULL,NULL,NULL,'Par de maletas laterales rígidas de aluminio con cierre hermético para la Multistrada V4. Capacidad suficiente para viajes largos con total protección contra la lluvia.','Compatible con Ducati Multistrada V4\nCapacidad de 30 y 37 litros\nAluminio anodizado resistente\nCierre hermético con llave\nSoportes de liberación rápida',82,'2026-10-03 14:44:13'),(93,'accesorios',1,0,'nuevo','Exterior','assets/Catalogo/accesorios/parabrisas-touring-ducati.webp',NULL,NULL,NULL,NULL,'Parabrisas touring de mayor altura que reduce la turbulencia y la fatiga en viajes largos. Policarbonato resistente a impactos con tratamiento antirrayas.','Compatible con Ducati Multistrada V2 / V4\nPolicarbonato de 4 mm\nTratamiento antirrayas\n60 mm más alto que el original\nCompatible con Multistrada V2 y V4',83,'2026-10-03 14:44:13'),(94,'accesorios',1,0,'nuevo','Protección','assets/Catalogo/accesorios/funda-moto-ducati.webp',NULL,NULL,NULL,NULL,'Funda de exterior impermeable con protección UV y forro suave. Mantiene tu Ducati limpia y protegida del sol, la lluvia y el polvo.','Compatible con Ducati Panigale / Streetfighter\nTela impermeable con protección UV\nForro interior suave\nOrificios para candado\nBolsa de transporte incluida',84,'2026-10-03 14:44:13');
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
INSERT INTO `promociones` VALUES (1,'audi-q5-bono','Bono de $40,000 en Audi Q5','SUV mediana con tracción quattro','Estrena tu Audi Q5 2025 con un bono aplicable al cerrar tu compra en cualquiera de nuestras sucursales.','vehiculos','Audi','Bono $40,000','assets/Catalogo/vehiculos/audi/q5.webp','Promoción de demostración del proyecto académico KARMA. Aplica sobre precio de lista, sujeta a disponibilidad de inventario en la sucursal.','2026-10-01','2026-12-31','Ver Audi Q5','vehiculo.php?codigo=KRM-CAT-AUDI-08',1,1),(2,'porsche-macan-tasa','Tasa preferencial desde 11.9% en Porsche Macan','Plan de crédito KARMA Financial','Financia tu Porsche Macan con una tasa preferencial y plazos de hasta 60 meses. Simula tu mensualidad en línea.','financiamiento','Porsche','11.9% anual','assets/Catalogo/vehiculos/porsche/macan.webp','Promoción de demostración. Tasa fija anual de referencia con enganche mínimo del 20%; sujeta a aprobación de crédito.','2026-10-01','2026-12-31','Simular financiamiento','financiamiento.php?codigo=KRM-CAT-POR-13&tasa=11.9',1,2),(3,'ducati-multistrada-maletas','Maletas laterales con 15% al estrenar tu Multistrada V4','Listo para viajar desde el primer día','Al comprar tu Ducati Multistrada V4 obtén 15% de descuento en el juego de maletas laterales rígidas.','accesorios','Ducati','-15% accesorios','assets/Catalogo/accesorios/maletas-laterales-ducati.webp','Promoción de demostración. Aplica en sucursal al momento de la compra de la motocicleta.','2026-10-01','2026-12-31','Ver Multistrada V4','vehiculo.php?codigo=KRM-CAT-DUC-07',1,3),(4,'servicio-aceite','Cambio de aceite y filtro desde $2,490','Servicio express en menos de 90 minutos','Incluye aceite sintético de especificación de fábrica, filtro nuevo y revisión de 25 puntos.','servicio',NULL,'Desde $2,490','assets/Catalogo/servicios/cambio-aceite.webp','Promoción de demostración. Precio de referencia para autos de hasta 6 litros de aceite; motocicletas desde $1,690.','2026-10-01','2026-12-31','Agendar servicio','agendar.php?tipo=servicio&servicio=Cambio%20de%20aceite%20y%20filtro',1,4),(5,'servicio-frenos','Revisión de frenos sin costo','Tu seguridad primero','Medimos el espesor de pastillas y discos, revisamos el líquido de frenos y te entregamos un diagnóstico por escrito.','servicio',NULL,'Sin costo','assets/Catalogo/servicios/frenos.webp','Promoción de demostración. Una revisión por vehículo durante la vigencia; requiere cita previa.','2026-10-01','2026-11-30','Agendar revisión','agendar.php?tipo=servicio&servicio=Servicio%20de%20frenos',1,5),(6,'refacciones-instalacion','Instalación sin costo en pastillas y discos','Compra en línea, instala en nuestro taller','Compra tus pastillas o discos de freno en línea, recoge en sucursal y nuestro taller los instala sin costo de mano de obra.','refacciones',NULL,'Instalación gratis','assets/Catalogo/refacciones/porsche/disco-delantero.webp','Promoción de demostración. Requiere cita de servicio en la misma sucursal donde se recoge el pedido.','2026-10-01','2026-12-31','Ver refacciones de frenos','refacciones.php?categoria=Frenos',1,6),(7,'envio-gratis','Envío gratis en compras desde $3,000','Refacciones y accesorios a domicilio','Tus refacciones y accesorios llegan a domicilio sin costo de envío cuando tu pedido es de $3,000 o más.','accesorios',NULL,'Envío gratis','assets/Catalogo/accesorios/tapetes-audi.webp','Promoción de demostración. Aplica automáticamente en el checkout para pedidos con envío y pago con tarjeta.','2026-10-01','2026-12-31','Ver accesorios','accesorios.php',1,7),(8,'prueba-manejo-kit','Agenda tu prueba de manejo y recibe un kit de bienvenida','Vive la experiencia antes de decidir','Agenda en línea tu prueba de manejo en Manzanillo o Colima y llévate un kit de bienvenida KARMA.','vehiculos',NULL,'Regalo','assets/Catalogo/banners/prueba-manejo.webp','Promoción de demostración. Un kit por cliente; sujeto a existencias en la sucursal.','2026-10-01','2026-12-31','Agendar prueba de manejo','agendar.php?tipo=prueba_manejo',1,8);
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
INSERT INTO `solicitudes` VALUES (1,'SOL-02-000001','cotizacion',NULL,2,25,'Ana Prueba','cliente.prueba@karma.local',NULL,'Cotización: Audi R8',NULL,'{\"color\":\"Azul Ultra\",\"version\":\"Black Edition\",\"precioEstimado\":3600000}','nueva','2026-10-03 18:02:34');
/*!40000 ALTER TABLE `solicitudes` ENABLE KEYS */;
UNLOCK TABLES;

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
INSERT INTO `sucursales` VALUES (1,'Manzanillo','Av. Miguel de la Madrid 100, Manzanillo, Colima','3140000000','activo','Manzanillo','manzanillo@karma.local','Lunes a viernes 9:00–19:00 · Sábado 9:00–14:00','Lunes a viernes 8:00–18:00 · Sábado 8:00–13:00','Venta de vehículos nuevos,Simulación de crédito,Apartado de vehículos,Seguros,Gestoría de placas y trámites,Garantía extendida,Plan de mantenimiento prepagado,Accesorios originales e instalación,Polarizado,Orden de servicio de taller,Refacciones originales','assets/Catalogo/sucursales/manzanillo.webp'),(2,'Colima','Av. Constitución 1500, Colima, Colima','3120000000','activo','Colima','colima@karma.local','Lunes a viernes 9:00–19:00 · Sábado 9:00–14:00','Lunes a viernes 8:00–18:00 · Sábado 8:00–13:00','Venta de vehículos nuevos,Simulación de crédito,Apartado de vehículos,Seguros,Gestoría de placas y trámites,Garantía extendida,Plan de mantenimiento prepagado,Accesorios originales e instalación,Polarizado,Orden de servicio de taller,Refacciones originales','assets/Catalogo/sucursales/colima.webp');
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
INSERT INTO `usuarios` VALUES (1,3,1,'Miranda','miranda@karma.local','$2y$12$69yS9OJm0dBEBU1GlzIRkePfwIRRfNnSpeB1LAkOLSF0vHQRYh0yG','es','activo','EMP-0001'),(2,3,1,'Cajero Prueba Manzanillo','cajero.manzanillo@karma.local','$2y$12$mVz.S6d98f4eCSYludtyM.UmH.Qy1mtbEV0CWH4i55.kkibFQJAZy','es','activo','EMP-0002'),(3,3,2,'Cajero Prueba Colima','cajero.colima@karma.local','$2y$12$27KZH4amsGmocKsAl07ZWudt9Poz9RBNv4Irq6PDVH4U2ct8Tbl3i','es','activo','EMP-0003'),(4,3,1,'Carolina','Carolina@karma.com','$2y$12$0PUAds1yElWFnkU8VH.QZ.R7iuDuXIYzrJJrNJLMHhazrXogQ.H/C','es','activo','EMP-0004'),(5,3,1,'Cajero Prueba QR','cajero.qr@karma.local','$2y$12$wsPtHl8g5LMv6plaMo7owe3pcYxkqxwjis7/tDVS3QnDdgnJOkipm','es','activo','EMP-0005'),(6,2,1,'Gerente Prueba QR','gerente.qr@karma.local','$2y$12$19YSbu6g5IcuzYETfw0a4uY1svHQlzLAjKCRuLa55Ro0VCIZN2Fne','es','activo','EMP-0006'),(7,3,1,'Cajero Prueba QR Inactivo','inactivo.qr@karma.local','$2y$12$wLW/QZeiMYhQQIh1kky.Ve9/88PYimfEwl/3aBMFqKKI.d2csrUQG','es','inactivo','EMP-0007');
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
    
    -- Obtiene el próximo ID de autoincremento
    SELECT AUTO_INCREMENT INTO siguiente_id
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios';
    
    -- Asigna el código en formato EMP-000X
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
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (1,1,1,1,1,'2026-09-24 16:07:19',1862400.00,1862400.00,4,1862400.00,0.00,1),(2,1,1,1,1,'2026-09-24 17:18:09',620000.00,620000.00,5,650000.00,30000.00,1),(3,1,1,1,1,'2026-09-26 22:43:57',620000.00,620000.00,4,700000.00,80000.00,1),(4,1,1,1,1,'2026-09-26 22:47:26',2280000.00,2280000.00,4,3000000.00,720000.00,1),(5,1,1,1,1,'2026-09-27 21:47:44',444801.61,444801.61,6,500000.00,55198.39,1),(6,1,1,1,1,'2026-09-28 08:34:47',3469997.91,3469997.91,NULL,4000000.00,530002.09,1),(7,1,1,1,1,'2026-09-28 08:51:34',1743576.89,1743576.89,NULL,2000000.00,256423.11,2),(8,1,2,1,1,'2026-10-03 17:58:36',9836.82,9836.82,NULL,10336.82,500.00,1),(9,1,2,1,1,'2026-10-03 18:02:33',1006865.63,1006865.63,NULL,2000000.00,993134.37,99),(10,1,2,1,1,'2026-10-03 19:06:07',4881.86,4881.86,NULL,5000.00,118.14,3),(11,1,5,1,1,'2026-10-05 08:56:37',1203.37,1203.37,NULL,2000.00,796.63,1),(12,1,5,1,1,'2026-10-05 08:56:37',288140.62,288140.62,10,300000.00,11859.38,2),(13,1,5,1,1,'2026-10-05 08:56:38',1203.37,1203.37,NULL,1500.00,296.63,3),(14,1,5,1,1,'2026-10-05 09:02:51',1203.37,1203.37,NULL,1500.00,296.63,4),(15,1,5,1,1,'2026-10-05 09:04:44',371609.38,371609.38,11,436489.00,64879.62,5),(16,1,5,1,1,'2026-10-05 09:06:19',1203.37,1203.37,NULL,1300.00,96.63,6),(17,1,4,1,1,'2026-10-05 22:32:10',5907.23,5907.23,9,6000.00,92.77,7),(18,1,4,1,1,'2026-10-06 09:48:43',2413985.87,2413985.87,NULL,2500000.00,86014.13,1),(19,1,4,1,1,'2026-10-06 10:00:30',2413985.87,2413985.87,NULL,3000000.00,586014.13,2),(20,1,4,1,1,'2026-10-06 10:04:34',444801.61,444801.61,NULL,500000.00,55198.39,3);
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
INSERT INTO `web_orders` VALUES (10,'vehiculo',31,'Gojo Satoru','3140242412','gojosatorureal@gmail.com',200000.00,'2026-10-05 10:00:00','Rojo Carmín',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pendiente','WEB-01-000010',9,1,NULL,NULL,'pendiente',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'Solicitud de apartado. ','2026-10-04 16:14:34',NULL,NULL),(11,'refaccion',61,'Gojo Satoru','3140242412','gojosatorureal@gmail.com',NULL,NULL,NULL,'Disco de freno trasero Audi','Audi RS3','Audi','2.5L TFSI Turbo 5-cil.','2480 cc','Trasera',NULL,'Derecho','atendida','WEB-01-000011',9,1,'recoger',1,'pagado',5907.23,0.00,5907.23,NULL,NULL,NULL,NULL,1,NULL,'2026-10-04 17:09:53','2026-10-05 22:32:10',17),(12,'refaccion',NULL,'Cliente Prueba QR','3140000001',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'atendida','WEB-QR-PRUEBA-01',NULL,1,'recoger',1,'pagado',1203.37,0.00,1203.37,NULL,NULL,NULL,NULL,0,'Orden de prueba de la autorizaci?n por gafete (docs/AUTORIZACION_EMPLEADO.md)','2026-10-05 08:53:33','2026-10-05 08:56:38',13);
/*!40000 ALTER TABLE `web_orders` ENABLE KEYS */;
UNLOCK TABLES;

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
    -- Normaliza la marca a mayúsculas y sin espacios
    DECLARE v_marca VARCHAR(80) DEFAULT UPPER(TRIM(COALESCE(p_marca, '')));
    -- Marcas conocidas del catálogo
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
    -- Última serie usada (los 6 dígitos finales del VIN); si no hay ninguna empieza en 100000
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
    -- Ciclo oficial de 30 años sin I, O, Q, U, Z ni 0 (empieza en 2010 = A)
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

-- Dump completed on 2026-10-10 15:39:20
