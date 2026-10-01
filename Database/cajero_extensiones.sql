-- KARMA / POS multisede
-- Extensiones necesarias para el módulo de Cajero conectado a MySQL.
USE pos_multisede;

-- Datos descriptivos del catálogo de productos.
ALTER TABLE productos
    ADD COLUMN IF NOT EXISTS marca VARCHAR(80) NULL,
    ADD COLUMN IF NOT EXISTS modelo VARCHAR(120) NULL,
    ADD COLUMN IF NOT EXISTS anio INT NULL,
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(30) NOT NULL DEFAULT 'refaccion',
    ADD COLUMN IF NOT EXISTS color VARCHAR(80) NULL,
    ADD COLUMN IF NOT EXISTS color_hex VARCHAR(20) NULL,
    ADD COLUMN IF NOT EXISTS motor VARCHAR(120) NULL,
    ADD COLUMN IF NOT EXISTS cilindraje VARCHAR(80) NULL,
    ADD COLUMN IF NOT EXISTS detalle TEXT NULL,
    ADD COLUMN IF NOT EXISTS compatibilidad VARCHAR(255) NULL;

-- Clientes usados por Crédito, Garantías y datos de la venta.
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    rfc_ine VARCHAR(80) NULL,
    celular VARCHAR(30) NULL,
    email VARCHAR(120) NULL,
    articulo VARCHAR(180) NULL,
    total_adeudo DECIMAL(12,2) NULL,
    monto_abono DECIMAL(12,2) NULL,
    enganche DECIMAL(12,2) NULL,
    abonos_pagados INT NOT NULL DEFAULT 0,
    abonos_totales INT NOT NULL DEFAULT 0,
    estado ENUM('activo','inactivo') DEFAULT 'activo' NOT NULL,
    UNIQUE KEY uq_cliente_email (email)
) ENGINE=InnoDB;

-- Garantías de unidades entregadas.
CREATE TABLE IF NOT EXISTS garantias (
    id_garantia INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_producto INT NOT NULL,
    fecha_expiracion DATE NOT NULL,
    estado ENUM('vigente','vencida','cancelada') DEFAULT 'vigente' NOT NULL,
    CONSTRAINT fk_garantias_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_garantias_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Órdenes recibidas desde el sitio web.
CREATE TABLE IF NOT EXISTS web_orders (
    id_orden INT AUTO_INCREMENT PRIMARY KEY,
    tipo ENUM('vehiculo','refaccion') NOT NULL,
    id_producto INT NULL,
    nombre VARCHAR(150) NOT NULL,
    celular VARCHAR(30) NULL,
    email VARCHAR(120) NULL,
    enganche DECIMAL(12,2) NULL,
    fecha_visita DATETIME NULL,
    color VARCHAR(80) NULL,
    pieza VARCHAR(150) NULL,
    modelo_compatibilidad VARCHAR(150) NULL,
    marca_vehiculo VARCHAR(80) NULL,
    motor VARCHAR(120) NULL,
    cilindraje VARCHAR(80) NULL,
    traccion VARCHAR(80) NULL,
    transmision VARCHAR(100) NULL,
    lado VARCHAR(50) NULL,
    estado ENUM('pendiente','atendida','cancelada') DEFAULT 'pendiente' NOT NULL,
    CONSTRAINT fk_weborders_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Datos de cliente y efectivo asociados a una venta.
ALTER TABLE ventas
    ADD COLUMN IF NOT EXISTS id_cliente INT NULL,
    ADD COLUMN IF NOT EXISTS efectivo_recibido DECIMAL(12,2) NULL,
    ADD COLUMN IF NOT EXISTS cambio DECIMAL(12,2) NULL,
    ADD COLUMN IF NOT EXISTS ticket_numero INT NULL,
    ADD CONSTRAINT fk_ventas_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_productos_tipo ON productos(tipo);
CREATE INDEX IF NOT EXISTS idx_clientes_nombre ON clientes(nombre);
CREATE INDEX IF NOT EXISTS idx_garantias_estado ON garantias(estado);
CREATE INDEX IF NOT EXISTS idx_weborders_estado ON web_orders(estado);
