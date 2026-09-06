CREATE DATABASE IF NOT EXISTS pos_multisede
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE pos_multisede;

-- Tablas base sin referencias foraneas

INSERT INTO roles(nombre_rol) VALUES ("Admin_General");
INSERT INTO roles(nombre_rol) VALUES ("Gerente");
INSERT INTO roles(nombre_rol) VALUES ("Cajero");

CREATE TABLE IF NOT EXISTS roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE sucursales(
id_sucursal INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
nombre varchar(100) NOT NULL,
direccion varchar(255) NOT NULL,
telefono varchar(20) NOT NULL,
estado ENUM('activo','inactivo') DEFAULT 'activo' NOT NULL,
UNIQUE(id_sucursal, nombre)
)ENGINE=InnoDB;

CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT NULL
) ENGINE=InnoDB;

CREATE TABLE metodos_pago (
    id_metodo_pago INT AUTO_INCREMENT PRIMARY KEY,
    nombre_metodo VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO metodos_pago(nombre_metodo) VALUES ("Efectivo");
INSERT INTO metodos_pago(nombre_metodo) VALUES ("Tarjeta");
INSERT INTO metodos_pago(nombre_metodo) VALUES ("Transferencia");

-- Tablas con dependencias de primer nivel

CREATE TABLE usuarios(
id_usuario INT NOT NULL AUTO_INCREMENT PRIMARY KEY UNIQUE,
id_rol INT NOT NULL,
id_sucursal INT NOT NULL,
nombre VARCHAR(100) NOT NULL,
correo VARCHAR(100) NOT NULL UNIQUE,
password_hash VARCHAR(255) NOT NULL,
idioma_pref ENUM('es', 'en') DEFAULT 'es' NOT NULL,
estado ENUM('activo', 'inactivo') DEFAULT 'activo' NOT NULL,
CONSTRAINT fk_usuarios_roles 
        FOREIGN KEY (id_rol) REFERENCES roles(id_rol) 
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_usuarios_sucursales 
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) 
        ON UPDATE CASCADE ON DELETE SET NULL
)ENGINE=InnoDB;

CREATE TABLE cajas (
    id_caja INT AUTO_INCREMENT PRIMARY KEY,
    id_sucursal INT NOT NULL,
    numero_caja INT NOT NULL,
    estado ENUM('abierta', 'cerrada', 'mantenimiento') DEFAULT 'cerrada' NOT NULL,
    CONSTRAINT uq_caja_sucursal UNIQUE (id_sucursal, numero_caja),
    CONSTRAINT fk_cajas_sucursales 
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) 
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    codigo_barras VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    precio_base DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_productos_categorias 
        FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria) 
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Inventarios y Transacciones

CREATE TABLE inventarios (
    id_inventario INT AUTO_INCREMENT PRIMARY KEY,
    id_sucursal INT NOT NULL,
    id_producto INT NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    CONSTRAINT uq_sucursal_producto UNIQUE (id_sucursal, id_producto),
    CONSTRAINT fk_inventarios_sucursales 
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_inventarios_productos 
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto) 
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_sucursal INT NOT NULL,
    id_usuario INT NOT NULL,
    id_caja INT NOT NULL,
    id_metodo_pago INT NOT NULL,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_ventas_sucursales 
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) 
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_usuarios 
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) 
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_cajas 
        FOREIGN KEY (id_caja) REFERENCES cajas(id_caja) 
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_metodos_pago 
        FOREIGN KEY (id_metodo_pago) REFERENCES metodos_pago(id_metodo_pago) 
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;