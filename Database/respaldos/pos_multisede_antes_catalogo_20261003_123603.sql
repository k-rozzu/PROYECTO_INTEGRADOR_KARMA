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
-- Current Database: `pos_multisede`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `pos_multisede` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `pos_multisede`;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cajas`
--

LOCK TABLES `cajas` WRITE;
/*!40000 ALTER TABLE `cajas` DISABLE KEYS */;
INSERT INTO `cajas` VALUES (1,1,1,'abierta');
/*!40000 ALTER TABLE `cajas` ENABLE KEYS */;
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
  PRIMARY KEY (`id_cliente`),
  UNIQUE KEY `uq_cliente_email` (`email`),
  KEY `idx_clientes_nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES (1,'Roberto Fernández Aguilar','FERA900101XXX','314 123 4567','roberto.fernandez@email.com','Porsche 911 Carrera',1880000.00,450000.00,470000.00,5,24,'activo',NULL,NULL),(2,'Marina López Castillo','LOCM920202XXX','314 987 6543','marina.lopez@email.com','Audi RS7 Sportback',1315000.00,200000.00,NULL,2,12,'activo',NULL,NULL),(3,'Héctor Iván Solórzano','SOIH930303XXX','312 456 7890','hector.solorzano@email.com','Ducati Panigale V4 S',496000.00,62000.00,124000.00,0,24,'activo',NULL,NULL),(4,'Carolina zuñiga','123456789','3141390132','cmartinez72@ucol.mx',NULL,NULL,NULL,NULL,0,0,'activo','Manzanillo Centro Sector 5','INE'),(5,'Alan Ibarra Heredia','26102007','3141576255','aibarra9@ucol.mx',NULL,NULL,NULL,NULL,0,0,'activo',NULL,NULL),(6,'Diego Alejandro Vazquez','098765423','3141987686','dvazquez89@gmail.com',NULL,NULL,NULL,NULL,0,0,'activo','Floresta 56','INE');
/*!40000 ALTER TABLE `clientes` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
INSERT INTO `detalle_ventas` VALUES (1,1,5,1,1850000.00,1850000.00,NULL,NULL,NULL),(2,1,9,1,12400.00,12400.00,NULL,NULL,NULL),(3,2,6,1,620000.00,620000.00,NULL,NULL,NULL),(4,3,6,1,620000.00,620000.00,'2026','12345','Negro piel'),(5,4,1,1,2280000.00,2280000.00,'2024911','3.0','Negro grisaceo'),(6,5,54,1,444801.61,444801.61,'2345671','V2 Testastretta',NULL),(7,6,25,1,3469997.91,3469997.91,'WAUZZZZZ0SS100814','5.2L V10 FSI',NULL),(8,7,20,1,1743576.89,1743576.89,'WAUZZZZZ0PS100629','3.0L V6 TFSI','Negro');
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
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventarios`
--

LOCK TABLES `inventarios` WRITE;
/*!40000 ALTER TABLE `inventarios` DISABLE KEYS */;
INSERT INTO `inventarios` VALUES (1,1,5,4,1),(2,1,4,4,1),(3,1,6,4,1),(4,1,7,3,1),(5,1,1,1,1),(6,1,2,1,1),(7,1,3,2,1),(8,1,8,8,1),(9,1,9,9,1),(10,1,10,1,1),(11,1,11,0,2),(12,1,12,0,2),(13,1,13,1,2),(14,1,14,1,2),(15,1,15,2,2),(16,1,16,3,2),(17,1,17,0,2),(18,1,18,5,2),(19,1,19,2,2),(20,1,20,0,2),(21,1,21,0,2),(22,1,22,4,2),(23,1,23,3,2),(24,1,24,7,2),(25,1,25,0,2),(26,1,41,0,2),(27,1,42,0,2),(28,1,43,1,2),(29,1,44,1,2),(30,1,45,2,2),(31,1,46,3,2),(32,1,47,0,2),(33,1,48,5,2),(34,1,49,2,2),(35,1,50,1,2),(36,1,51,0,2),(37,1,52,4,2),(38,1,53,3,2),(39,1,54,6,2),(40,1,55,1,2),(41,1,26,0,2),(42,1,27,0,2),(43,1,28,1,2),(44,1,29,1,2),(45,1,30,2,2),(46,1,31,3,2),(47,1,32,0,2),(48,1,33,5,2),(49,1,34,2,2),(50,1,35,1,2),(51,1,36,0,2),(52,1,37,4,2),(53,1,38,3,2),(54,1,39,7,2),(55,1,40,1,2),(56,1,56,0,2),(57,1,57,0,2),(58,1,58,1,2),(59,1,59,1,2),(60,1,60,2,2),(61,1,61,3,2),(62,1,62,0,2),(63,1,63,5,2),(64,1,64,2,2),(65,1,65,1,2),(66,1,76,3,2),(67,1,77,0,2),(68,1,78,5,2),(69,1,79,2,2),(70,1,80,1,2),(71,1,81,0,2),(72,1,82,4,2),(73,1,83,3,2),(74,1,84,7,2),(75,1,85,1,2),(76,1,66,0,2),(77,1,67,4,2),(78,1,68,3,2),(79,1,69,7,2),(80,1,70,1,2),(81,1,71,0,2),(82,1,72,0,2),(83,1,73,1,2),(84,1,74,1,2),(85,1,75,2,2);
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
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (1,1,'KRM-P911-24','911 Carrera 2024','Porsche 911 Carrera 2024',2280000.00,'Porsche','911 Carrera',2024,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Sport Chrono de fábrica y llantas forjadas de 21\".',NULL,NULL,NULL,'Negro','WP0ZZZ990RS100037',NULL),(2,1,'KRM-P911-25','911 Carrera 2025','Porsche 911 Carrera 2025',2350000.00,'Porsche','911 Carrera',2025,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Sport Chrono de fábrica y llantas forjadas de 21\".',NULL,NULL,NULL,'Negro','WP0ZZZ990SS100074','assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb'),(3,1,'KRM-PTAY-25','Taycan Turbo S 2025','Porsche Taycan Turbo S 2025',3180000.00,'Porsche','Taycan Turbo S',2025,'auto','Blanco Carrara','#EDEDEA','Eléctrico de doble motor','—','Doble motor eléctrico con carga ultrarrápida de 270 kW.',NULL,NULL,NULL,'Beige','WP0ZZZY10SS100111',NULL),(4,2,'KRM-ARS7-24','RS7 Sportback 2024','Audi RS7 Sportback 2024',2190000.00,'Audi','RS7 Sportback',2024,'auto','Gris Nardo','#7A7D80','4.0L V8 Biturbo','3993 cc','V8 biturbo con interior en piel Nappa extendida.',NULL,NULL,NULL,'Negro','WUAZZZF20RS100148',NULL),(5,2,'KRM-AQ8E-25','Q8 e-tron 2025','Audi Q8 e-tron 2025',1850000.00,'Audi','Q8 e-tron',2025,'auto','Azul Ultra','#1F3B66','Eléctrico de doble motor','—','Doble motor eléctrico y techo panorámico solar.',NULL,NULL,NULL,'Café','WA1ZZZFE0SS100185',NULL),(6,3,'KRM-DPAN-24','Panigale V4 S 2024','Ducati Panigale V4 S 2024',620000.00,'Ducati','Panigale V4 S',2024,'moto','Rojo Ducati','#9E1B2E','V4 Desmosedici Stradale','1103 cc','Motor V4 con electrónica Öhlins de serie.',NULL,NULL,NULL,NULL,'ZDMZZZPV0RS100222',NULL),(7,3,'KRM-DSTR-25','Streetfighter V4 2025','Ducati Streetfighter V4 2025',590000.00,'Ducati','Streetfighter V4',2025,'moto','Negro Mate','#1A1A1A','V4 Desmosedici Stradale','1103 cc','Motor V4 con winglets aerodinámicos de MotoGP.',NULL,NULL,NULL,NULL,'ZDMZZZSF0SS100259',NULL),(8,4,'KRM-REF-DISCO-911','Disco de freno delantero','Disco de freno delantero para Porsche 911',18500.00,'Porsche','911 Carrera',2024,'refaccion','Acero gris','#8C9096','3.0L Boxer Biturbo',NULL,'Disco delantero izquierdo.','Porsche 911','Trasera','Izquierdo',NULL,NULL,NULL),(9,4,'KRM-REF-PAST-AUDI','Juego de pastillas de freno','Pastillas de freno para Audi RS7',12400.00,'Audi','RS7 Sportback',2024,'refaccion','Negro grafito','#2E2F33','4.0L V8 Biturbo',NULL,'Juego completo para eje delantero.','Audi RS7 Sportback','AWD','Ambos',NULL,NULL,NULL),(10,4,'KRM-REF-BALATA-AUDI','Balata delantera','Balata delantera para Audi RS7',9800.00,'Audi','RS7 Sportback',2024,'refaccion','Negro grafito','#2E2F33','4.0L V8 Biturbo',NULL,NULL,'Audi RS7 Sportback','AWD','Ambos',NULL,NULL,'assets/Modelos_3D/idproducto10_idcategoria4_KRM-REF-BALATA-AUDI_balataDelanteraParaAudiRS7_2024_Negro grafito_refaccion.glb'),(11,2,'KRM-CAT-AUDI-01','A3 2025','Audi A3 2025, motor 1.4L TFSI Turbo.',665281.24,'Audi','A3',2025,'auto','Gris Nardo','#7A7D80','1.4L TFSI Turbo','1395 cc','Audi A3 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WAUZZZZZ0SS100296',NULL),(12,2,'KRM-CAT-AUDI-02','A4 2024','Audi A4 2024, motor 2.0L TFSI Turbo.',812356.66,'Audi','A4',2024,'auto','Blanco Glaciar','#F2F2EF','2.0L TFSI Turbo','1984 cc','Audi A4 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WAUZZZZZ0RS100333',NULL),(13,2,'KRM-CAT-AUDI-03','A5 2025','Audi A5 2025, motor 2.0L TFSI Turbo.',946010.16,'Audi','A5',2025,'auto','Gris Nardo','#7A7D80','2.0L TFSI Turbo','1984 cc','Audi A5 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WAUZZZZZ0SS100370',NULL),(14,2,'KRM-CAT-AUDI-04','A6 2025','Audi A6 2025, motor 3.0L V6 TFSI.',1166650.62,'Audi','A6',2025,'auto','Gris Nardo','#7A7D80','3.0L V6 TFSI','2995 cc','Audi A6 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100407',NULL),(15,2,'KRM-CAT-AUDI-05','A7 2023','Audi A7 2023, motor 3.0L V6 TFSI.',1206138.70,'Audi','A7',2023,'auto','Gris Nardo','#7A7D80','3.0L V6 TFSI','2995 cc','Audi A7 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100444',NULL),(16,2,'KRM-CAT-AUDI-06','A8 2023','Audi A8 2023, motor 3.0L V6 TFSI.',1809054.93,'Audi','A8',2023,'auto','Rojo Tango','#8C1D2B','3.0L V6 TFSI','2995 cc','Audi A8 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Beige','WAUZZZZZ0PS100481',NULL),(17,2,'KRM-CAT-AUDI-07','Q3 2025','Audi Q3 2025, motor 2.0L TFSI Turbo.',858687.40,'Audi','Q3',2025,'auto','Blanco Glaciar','#F2F2EF','2.0L TFSI Turbo','1984 cc','Audi Q3 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100518',NULL),(18,2,'KRM-CAT-AUDI-08','Q5 2025','Audi Q5 2025, motor 2.0L TFSI Turbo.',1006865.63,'Audi','Q5',2025,'auto','Rojo Tango','#8C1D2B','2.0L TFSI Turbo','1984 cc','Audi Q5 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100555',NULL),(19,2,'KRM-CAT-AUDI-09','Q7 2024','Audi Q7 2024, motor 3.0L V6 TFSI.',1398540.24,'Audi','Q7',2024,'auto','Rojo Tango','#8C1D2B','3.0L V6 TFSI','2995 cc','Audi Q7 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100592',NULL),(20,2,'KRM-CAT-AUDI-10','Q8 2023','Audi Q8 2023, motor 3.0L V6 TFSI.',1743576.89,'Audi','Q8',2023,'auto','Blanco Glaciar','#F2F2EF','3.0L V6 TFSI','2995 cc','Audi Q8 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100629',NULL),(21,2,'KRM-CAT-AUDI-11','RS3 2024','Audi RS3 2024, motor 2.5L TFSI Turbo 5-cil..',1303929.87,'Audi','RS3',2024,'auto','Negro Mythos','#101012','2.5L TFSI Turbo 5-cil.','2480 cc','Audi RS3 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100666',NULL),(22,2,'KRM-CAT-AUDI-12','RS5 2024','Audi RS5 2024, motor 2.9L V6 Biturbo.',1579878.48,'Audi','RS5',2024,'auto','Gris Nardo','#7A7D80','2.9L V6 Biturbo','2894 cc','Audi RS5 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0RS100703',NULL),(23,2,'KRM-CAT-AUDI-13','RS6 2023','Audi RS6 2023, motor 4.0L V8 Biturbo.',2480657.88,'Audi','RS6',2023,'auto','Negro Mythos','#101012','4.0L V8 Biturbo','3993 cc','Audi RS6 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0PS100740',NULL),(24,2,'KRM-CAT-AUDI-14','RS7 2025','Audi RS7 2025, motor 4.0L V8 Biturbo.',2297617.75,'Audi','RS7',2025,'auto','Negro Mythos','#101012','4.0L V8 Biturbo','3993 cc','Audi RS7 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'quattro (AWD)',NULL,'Negro','WAUZZZZZ0SS100777',NULL),(25,2,'KRM-CAT-AUDI-15','R8 2025','Audi R8 2025, motor 5.2L V10 FSI.',3469997.91,'Audi','R8',2025,'auto','Azul Ultra','#1F3B66','5.2L V10 FSI','5204 cc','Audi R8 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WAUZZZZZ0SS100814','assets/Modelos_3D/id25_KRM-CAT-AUDI-15_audiR8_2025_AzulUltra.glb'),(26,1,'KRM-CAT-POR-01','718 Cayman 2024','Porsche 718 Cayman 2024, motor 2.0L Turbo Flat-4.',1361240.78,'Porsche','718 Cayman',2024,'auto','Blanco Carrara','#EDEDEA','2.0L Turbo Flat-4','1988 cc','Porsche 718 Cayman equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0RS100851',NULL),(27,1,'KRM-CAT-POR-02','718 Boxster 2025','Porsche 718 Boxster 2025, motor 2.0L Turbo Flat-4.',1465107.75,'Porsche','718 Boxster',2025,'auto','Azul Gentian','#1B3A6B','2.0L Turbo Flat-4','1988 cc','Porsche 718 Boxster equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0SS100888',NULL),(28,1,'KRM-CAT-POR-03','911 Carrera 2024','Porsche 911 Carrera 2024, motor 3.0L Boxer Biturbo.',1996608.97,'Porsche','911 Carrera',2024,'auto','Azul Gentian','#1B3A6B','3.0L Boxer Biturbo','2981 cc','Porsche 911 Carrera equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0RS100925',NULL),(29,1,'KRM-CAT-POR-04','911 Carrera S 2023','Porsche 911 Carrera S 2023, motor 3.0L Boxer Biturbo.',2338828.86,'Porsche','911 Carrera S',2023,'auto','Blanco Carrara','#EDEDEA','3.0L Boxer Biturbo','2981 cc','Porsche 911 Carrera S equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0PS100962',NULL),(30,1,'KRM-CAT-POR-05','911 Turbo 2024','Porsche 911 Turbo 2024, motor 3.7L Boxer Biturbo.',3646135.38,'Porsche','911 Turbo',2024,'auto','Blanco Carrara','#EDEDEA','3.7L Boxer Biturbo','3745 cc','Porsche 911 Turbo equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS100999',NULL),(31,1,'KRM-CAT-POR-06','911 GT3 2023','Porsche 911 GT3 2023, motor 4.0L Boxer Atmosférico.',3520336.58,'Porsche','911 GT3',2023,'auto','Rojo Carmín','#9E1B2E','4.0L Boxer Atmosférico','3996 cc','Porsche 911 GT3 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0PS101036',NULL),(32,1,'KRM-CAT-POR-07','911 GT3 RS 2025','Porsche 911 GT3 RS 2025, motor 4.0L Boxer Atmosférico.',4209809.72,'Porsche','911 GT3 RS',2025,'auto','Gris GT Plata','#9EA0A1','4.0L Boxer Atmosférico','3996 cc','Porsche 911 GT3 RS equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0SS101073',NULL),(33,1,'KRM-CAT-POR-08','911 Targa 2024','Porsche 911 Targa 2024, motor 3.0L Boxer Biturbo.',2413985.87,'Porsche','911 Targa',2024,'auto','Negro Jeweled','#141414','3.0L Boxer Biturbo','2981 cc','Porsche 911 Targa equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0RS101110',NULL),(34,1,'KRM-CAT-POR-09','Taycan 2025','Porsche Taycan 2025, motor Eléctrico de doble motor.',2492779.35,'Porsche','Taycan',2025,'auto','Blanco Carrara','#EDEDEA','Eléctrico de doble motor','—','Porsche Taycan equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0SS101147',NULL),(35,1,'KRM-CAT-POR-10','Taycan Turbo 2023','Porsche Taycan Turbo 2023, motor Eléctrico de doble motor.',3296579.71,'Porsche','Taycan Turbo',2023,'auto','Azul Gentian','#1B3A6B','Eléctrico de doble motor','—','Porsche Taycan Turbo equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0PS101184',NULL),(36,1,'KRM-CAT-POR-11','Panamera 2023','Porsche Panamera 2023, motor 2.9L V6 Biturbo.',2010461.38,'Porsche','Panamera',2023,'auto','Rojo Carmín','#9E1B2E','2.9L V6 Biturbo','2894 cc','Porsche Panamera equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0PS101221',NULL),(37,1,'KRM-CAT-POR-12','Panamera Turbo 2025','Porsche Panamera Turbo 2025, motor 4.0L V8 Biturbo.',2846312.51,'Porsche','Panamera Turbo',2025,'auto','Azul Gentian','#1B3A6B','4.0L V8 Biturbo','3996 cc','Porsche Panamera Turbo equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,'Negro','WP0ZZZZZ0SS101258',NULL),(38,1,'KRM-CAT-POR-13','Macan 2024','Porsche Macan 2024, motor 2.0L Turbo.',1387139.15,'Porsche','Macan',2024,'auto','Blanco Carrara','#EDEDEA','2.0L Turbo','1984 cc','Porsche Macan equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0RS101295',NULL),(39,1,'KRM-CAT-POR-14','Cayenne 2023','Porsche Cayenne 2023, motor 3.0L V6 Turbo.',1751851.73,'Porsche','Cayenne',2023,'auto','Gris GT Plata','#9EA0A1','3.0L V6 Turbo','2995 cc','Porsche Cayenne equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101332',NULL),(40,1,'KRM-CAT-POR-15','Cayenne Turbo 2023','Porsche Cayenne Turbo 2023, motor 4.0L V8 Biturbo.',2825169.72,'Porsche','Cayenne Turbo',2023,'auto','Negro Jeweled','#141414','4.0L V8 Biturbo','3996 cc','Porsche Cayenne Turbo equipado de fábrica, listo para prueba de manejo en agencia.',NULL,'AWD',NULL,'Negro','WP0ZZZZZ0PS101369',NULL),(41,3,'KRM-CAT-DUC-01','Panigale V2 2025','Ducati Panigale V2 2025, motor V2 90°.',400688.50,'Ducati','Panigale V2',2025,'moto','Gris Antracita','#4A4A4A','V2 90°','955 cc','Ducati Panigale V2 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0SS101406','assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb'),(42,3,'KRM-CAT-DUC-02','Panigale V4 2024','Ducati Panigale V4 2024, motor V4 Desmosedici Stradale.',615698.60,'Ducati','Panigale V4',2024,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Panigale V4 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0RS101443',NULL),(43,3,'KRM-CAT-DUC-03','Panigale V4 S 2025','Ducati Panigale V4 S 2025, motor V4 Desmosedici Stradale.',584572.86,'Ducati','Panigale V4 S',2025,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Panigale V4 S equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0SS101480',NULL),(44,3,'KRM-CAT-DUC-04','Monster 2023','Ducati Monster 2023, motor V2 Testastretta.',332543.44,'Ducati','Monster',2023,'moto','Negro Mate','#1A1A1A','V2 Testastretta','937 cc','Ducati Monster equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0PS101517',NULL),(45,3,'KRM-CAT-DUC-05','Monster SP 2025','Ducati Monster SP 2025, motor V2 Testastretta.',374228.00,'Ducati','Monster SP',2025,'moto','Gris Antracita','#4A4A4A','V2 Testastretta','937 cc','Ducati Monster SP equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0SS101554',NULL),(46,3,'KRM-CAT-DUC-06','Multistrada V2 2024','Ducati Multistrada V2 2024, motor V2 Testastretta.',371609.38,'Ducati','Multistrada V2',2024,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','937 cc','Ducati Multistrada V2 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0RS101591',NULL),(47,3,'KRM-CAT-DUC-07','Multistrada V4 2023','Ducati Multistrada V4 2023, motor V4 Granturismo.',485963.66,'Ducati','Multistrada V4',2023,'moto','Blanco Dark','#E7E7E4','V4 Granturismo','1158 cc','Ducati Multistrada V4 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0PS101628',NULL),(48,3,'KRM-CAT-DUC-08','Diavel V4 2023','Ducati Diavel V4 2023, motor V4 Granturismo.',510005.49,'Ducati','Diavel V4',2023,'moto','Rojo Ducati','#9E1B2E','V4 Granturismo','1158 cc','Ducati Diavel V4 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0PS101665',NULL),(49,3,'KRM-CAT-DUC-09','Streetfighter V2 2023','Ducati Streetfighter V2 2023, motor V2 Testastretta.',416324.43,'Ducati','Streetfighter V2',2023,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','955 cc','Ducati Streetfighter V2 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0PS101702',NULL),(50,3,'KRM-CAT-DUC-10','Streetfighter V4 2024','Ducati Streetfighter V4 2024, motor V4 Desmosedici Stradale.',599051.87,'Ducati','Streetfighter V4',2024,'moto','Blanco Dark','#E7E7E4','V4 Desmosedici Stradale','1103 cc','Ducati Streetfighter V4 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0RS101739',NULL),(51,3,'KRM-CAT-DUC-11','Scrambler Icon 2024','Ducati Scrambler Icon 2024, motor L-Twin Desmodue.',279596.86,'Ducati','Scrambler Icon',2024,'moto','Gris Antracita','#4A4A4A','L-Twin Desmodue','803 cc','Ducati Scrambler Icon equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0RS101776',NULL),(52,3,'KRM-CAT-DUC-12','Scrambler Nightshift 2023','Ducati Scrambler Nightshift 2023, motor L-Twin Desmodue.',288140.62,'Ducati','Scrambler Nightshift',2023,'moto','Rojo Ducati','#9E1B2E','L-Twin Desmodue','803 cc','Ducati Scrambler Nightshift equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0PS101813',NULL),(53,3,'KRM-CAT-DUC-13','DesertX 2025','Ducati DesertX 2025, motor L-Twin Testastretta.',438049.83,'Ducati','DesertX',2025,'moto','Gris Antracita','#4A4A4A','L-Twin Testastretta','937 cc','Ducati DesertX equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0SS101850',NULL),(54,3,'KRM-CAT-DUC-14','Hypermotard 2024','Ducati Hypermotard 2024, motor V2 Testastretta.',444801.61,'Ducati','Hypermotard',2024,'moto','Rojo Ducati','#9E1B2E','V2 Testastretta','937 cc','Ducati Hypermotard equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0RS101887',NULL),(55,3,'KRM-CAT-DUC-15','SuperSport 950 2023','Ducati SuperSport 950 2023, motor V2 Testastretta.',359002.51,'Ducati','SuperSport 950',2023,'moto','Blanco Dark','#E7E7E4','V2 Testastretta','937 cc','Ducati SuperSport 950 equipado de fábrica, listo para prueba de manejo en agencia.',NULL,NULL,NULL,NULL,'ZDMZZZZZ0PS101924',NULL),(56,4,'KRM-CAT-REF-AUDI-01','Filtro de aceite Audi','Filtro de aceite original/compatible para Audi RS5.',508.87,'Audi','RS5',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS5',NULL,NULL,NULL,NULL,NULL),(57,4,'KRM-CAT-REF-AUDI-02','Filtro de aire Audi','Filtro de aire original/compatible para Audi A7.',666.81,'Audi','A7',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi A7',NULL,NULL,NULL,NULL,NULL),(58,4,'KRM-CAT-REF-AUDI-03','Juego de pastillas de freno delanteras Audi','Juego de pastillas de freno delanteras original/compatible para Audi RS6.',3984.05,'Audi','RS6',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS6','Delantera',NULL,NULL,NULL,NULL),(59,4,'KRM-CAT-REF-AUDI-04','Juego de pastillas de freno traseras Audi','Juego de pastillas de freno traseras original/compatible para Audi R8.',3560.70,'Audi','R8',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi R8','Trasera',NULL,NULL,NULL,NULL),(60,4,'KRM-CAT-REF-AUDI-05','Disco de freno delantero Audi','Disco de freno delantero original/compatible para Audi RS3.',6580.71,'Audi','RS3',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS3','Delantera','Izquierdo',NULL,NULL,NULL),(61,4,'KRM-CAT-REF-AUDI-06','Disco de freno trasero Audi','Disco de freno trasero original/compatible para Audi RS3.',5907.23,'Audi','RS3',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS3','Trasera','Derecho',NULL,NULL,NULL),(62,4,'KRM-CAT-REF-AUDI-07','Juego de bujías Audi','Juego de bujías original/compatible para Audi A6.',1369.46,'Audi','A6',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi A6',NULL,NULL,NULL,NULL,NULL),(63,4,'KRM-CAT-REF-AUDI-08','Batería Audi','Batería original/compatible para Audi RS6.',4918.41,'Audi','RS6',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS6',NULL,NULL,NULL,NULL,NULL),(64,4,'KRM-CAT-REF-AUDI-09','Kit de distribución Audi','Kit de distribución original/compatible para Audi RS6.',10462.38,'Audi','RS6',NULL,'refaccion','Negro','#202124',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi RS6',NULL,NULL,NULL,NULL,NULL),(65,4,'KRM-CAT-REF-AUDI-10','Bomba de agua Audi','Bomba de agua original/compatible para Audi R8.',3312.33,'Audi','R8',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Refacción de repuesto para Audi, verificar compatibilidad exacta por modelo/año en sucursal.','Audi R8',NULL,NULL,NULL,NULL,NULL),(66,4,'KRM-CAT-REF-POR-01','Filtro de aceite Porsche','Filtro de aceite original/compatible para Porsche 911 GT3.',479.12,'Porsche','911 GT3',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 911 GT3',NULL,NULL,NULL,NULL,NULL),(67,4,'KRM-CAT-REF-POR-02','Filtro de aire Porsche','Filtro de aire original/compatible para Porsche 718 Boxster.',662.57,'Porsche','718 Boxster',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 718 Boxster',NULL,NULL,NULL,NULL,NULL),(68,4,'KRM-CAT-REF-POR-03','Juego de pastillas de freno delanteras Porsche','Juego de pastillas de freno delanteras original/compatible para Porsche Cayenne Turbo.',4526.14,'Porsche','Cayenne Turbo',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Cayenne Turbo','Delantera',NULL,NULL,NULL,NULL),(69,4,'KRM-CAT-REF-POR-04','Juego de pastillas de freno traseras Porsche','Juego de pastillas de freno traseras original/compatible para Porsche Macan.',3682.97,'Porsche','Macan',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Macan','Trasera',NULL,NULL,NULL,NULL),(70,4,'KRM-CAT-REF-POR-05','Disco de freno delantero Porsche','Disco de freno delantero original/compatible para Porsche 718 Cayman.',6518.07,'Porsche','718 Cayman',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 718 Cayman','Delantera','Izquierdo',NULL,NULL,NULL),(71,4,'KRM-CAT-REF-POR-06','Disco de freno trasero Porsche','Disco de freno trasero original/compatible para Porsche Taycan Turbo.',6321.92,'Porsche','Taycan Turbo',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Taycan Turbo','Trasera','Derecho',NULL,NULL,NULL),(72,4,'KRM-CAT-REF-POR-07','Juego de bujías Porsche','Juego de bujías original/compatible para Porsche 718 Boxster.',1503.80,'Porsche','718 Boxster',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 718 Boxster',NULL,NULL,NULL,NULL,NULL),(73,4,'KRM-CAT-REF-POR-08','Batería Porsche','Batería original/compatible para Porsche Cayenne.',4841.58,'Porsche','Cayenne',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Cayenne',NULL,NULL,NULL,NULL,NULL),(74,4,'KRM-CAT-REF-POR-09','Kit de distribución Porsche','Kit de distribución original/compatible para Porsche Macan.',9851.28,'Porsche','Macan',NULL,'refaccion','Negro','#202124',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche Macan',NULL,NULL,NULL,NULL,NULL),(75,4,'KRM-CAT-REF-POR-10','Bomba de agua Porsche','Bomba de agua original/compatible para Porsche 911 Carrera.',3385.95,'Porsche','911 Carrera',NULL,'refaccion','Aluminio','#A9ADB2',NULL,NULL,'Refacción de repuesto para Porsche, verificar compatibilidad exacta por modelo/año en sucursal.','Porsche 911 Carrera',NULL,NULL,NULL,NULL,NULL),(76,4,'KRM-CAT-REF-DUC-01','Filtro de aceite Ducati','Filtro de aceite original/compatible para Ducati Diavel V4.',407.17,'Ducati','Diavel V4',NULL,'refaccion','Blanco','#E6E6E2',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Diavel V4',NULL,NULL,NULL,NULL,NULL),(77,4,'KRM-CAT-REF-DUC-02','Filtro de aire Ducati','Filtro de aire original/compatible para Ducati Panigale V4 S.',500.45,'Ducati','Panigale V4 S',NULL,'refaccion','Blanco hueso','#E8E4D8',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Panigale V4 S',NULL,NULL,NULL,NULL,NULL),(78,4,'KRM-CAT-REF-DUC-03','Juego de pastillas de freno delanteras Ducati','Juego de pastillas de freno delanteras original/compatible para Ducati Hypermotard.',2440.93,'Ducati','Hypermotard',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Hypermotard','Delantera',NULL,NULL,NULL,NULL),(79,4,'KRM-CAT-REF-DUC-04','Juego de pastillas de freno traseras Ducati','Juego de pastillas de freno traseras original/compatible para Ducati Monster.',2244.11,'Ducati','Monster',NULL,'refaccion','Negro grafito','#2E2F33',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Monster','Trasera',NULL,NULL,NULL,NULL),(80,4,'KRM-CAT-REF-DUC-05','Disco de freno delantero Ducati','Disco de freno delantero original/compatible para Ducati DesertX.',4354.51,'Ducati','DesertX',NULL,'refaccion','Acero gris','#8C9096',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati DesertX','Delantera','Izquierdo',NULL,NULL,NULL),(81,4,'KRM-CAT-REF-DUC-06','Cadena de transmisión Ducati','Cadena de transmisión original/compatible para Ducati Monster.',3205.62,'Ducati','Monster',NULL,'refaccion','Dorado','#B8923A',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Monster',NULL,NULL,NULL,NULL,NULL),(82,4,'KRM-CAT-REF-DUC-07','Kit de bujías Ducati','Kit de bujías original/compatible para Ducati Multistrada V4.',1025.26,'Ducati','Multistrada V4',NULL,'refaccion','Plata','#BFC3C7',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Multistrada V4',NULL,NULL,NULL,NULL,NULL),(83,4,'KRM-CAT-REF-DUC-08','Batería Ducati','Batería original/compatible para Ducati Scrambler Icon.',2547.34,'Ducati','Scrambler Icon',NULL,'refaccion','Negro','#1C1C1E',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Scrambler Icon',NULL,NULL,NULL,NULL,NULL),(84,4,'KRM-CAT-REF-DUC-09','Maneta de freno/embrague Ducati','Maneta de freno/embrague original/compatible para Ducati SuperSport 950.',1203.37,'Ducati','SuperSport 950',NULL,'refaccion','Negro anodizado','#2A2B2F',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati SuperSport 950',NULL,'Derecho',NULL,NULL,NULL),(85,4,'KRM-CAT-REF-DUC-10','Espejo retrovisor Ducati','Espejo retrovisor original/compatible para Ducati Panigale V4.',854.10,'Ducati','Panigale V4',NULL,'refaccion','Negro mate','#1A1A1A',NULL,NULL,'Refacción de repuesto para Ducati, verificar compatibilidad exacta por modelo/año en sucursal.','Ducati Panigale V4',NULL,'Izquierdo',NULL,NULL,NULL);
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
  PRIMARY KEY (`id_sucursal`),
  UNIQUE KEY `id_sucursal` (`id_sucursal`,`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sucursales`
--

LOCK TABLES `sucursales` WRITE;
/*!40000 ALTER TABLE `sucursales` DISABLE KEYS */;
INSERT INTO `sucursales` VALUES (1,'Manzanillo','Av. Miguel de la Madrid 100, Manzanillo, Colima','3140000000','activo');
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
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `correo` (`correo`),
  KEY `fk_usuarios_roles` (`id_rol`),
  KEY `fk_usuarios_sucursales` (`id_sucursal`),
  CONSTRAINT `fk_usuarios_roles` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON UPDATE CASCADE,
  CONSTRAINT `fk_usuarios_sucursales` FOREIGN KEY (`id_sucursal`) REFERENCES `sucursales` (`id_sucursal`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,3,1,'Miranda','miranda@karma.local','$2y$12$69yS9OJm0dBEBU1GlzIRkePfwIRRfNnSpeB1LAkOLSF0vHQRYh0yG','es','activo');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (1,1,1,1,1,'2026-09-24 16:07:19',1862400.00,1862400.00,4,1862400.00,0.00,1),(2,1,1,1,1,'2026-09-24 17:18:09',620000.00,620000.00,5,650000.00,30000.00,1),(3,1,1,1,1,'2026-09-26 22:43:57',620000.00,620000.00,4,700000.00,80000.00,1),(4,1,1,1,1,'2026-09-26 22:47:26',2280000.00,2280000.00,4,3000000.00,720000.00,1),(5,1,1,1,1,'2026-09-27 21:47:44',444801.61,444801.61,6,500000.00,55198.39,1),(6,1,1,1,1,'2026-09-28 08:34:47',3469997.91,3469997.91,NULL,4000000.00,530002.09,1),(7,1,1,1,1,'2026-09-28 08:51:34',1743576.89,1743576.89,NULL,2000000.00,256423.11,2);
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
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
  PRIMARY KEY (`id_orden`),
  KEY `fk_weborders_productos` (`id_producto`),
  KEY `idx_weborders_estado` (`estado`),
  CONSTRAINT `fk_weborders_productos` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `web_orders`
--

LOCK TABLES `web_orders` WRITE;
/*!40000 ALTER TABLE `web_orders` DISABLE KEYS */;
INSERT INTO `web_orders` VALUES (1,'vehiculo',3,'Daniela Ruiz Ponce','314 222 3344','daniela.ruiz@email.com',500000.00,'2026-09-18 11:30:00','Blanco Carrara',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pendiente'),(2,'vehiculo',7,'Iñaki Torres Vega','314 555 6677','inaki.torres@email.com',NULL,'2026-09-19 16:00:00','Negro Mate',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pendiente'),(3,'refaccion',8,'Carlos Beltrán Ibarra','314 888 1122',NULL,NULL,NULL,NULL,'Disco de freno delantero','911 (2019)','Porsche','3.0L Boxer Biturbo','2981 cc','Trasera','PDK automática','Izquierdo','pendiente');
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

-- Dump completed on 2026-10-03 12:36:04
