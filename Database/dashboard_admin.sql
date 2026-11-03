-- KARMA / pos_multisede — dashboard_admin.sql: tablas y columnas que usa el Panel de Administrador (dasboard/admin.html).
-- Importar en phpMyAdmin DESPUÉS de pos_multisede.sql y cajero_extensiones.sql.
-- Se puede importar varias veces sin duplicar nada (todo usa IF NOT EXISTS).

USE pos_multisede;

-- ===== 1. SUCURSALES: correo de contacto ===== 

ALTER TABLE sucursales
    ADD COLUMN IF NOT EXISTS email VARCHAR(100) NULL;

-- ===== 2. PEDIDOS A PROVEEDORES =====

-- Orden de compra que llega a una sucursal
CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(30) NOT NULL UNIQUE,
    proveedor VARCHAR(150) NOT NULL,
    id_sucursal INT NOT NULL,
    fecha_emision DATE NOT NULL,
    fecha_eta DATE NOT NULL,
    fecha_recepcion DATETIME NULL,
    estado ENUM('solicitado','transito','patio','recibido','cancelado') DEFAULT 'solicitado' NOT NULL,
    CONSTRAINT fk_pedidos_sucursales FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Cada unidad (vehículo) incluida en un pedido
CREATE TABLE IF NOT EXISTS pedido_vehiculos (
    id_pedido_vehiculo INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    marca VARCHAR(80) NULL,
    modelo VARCHAR(150) NOT NULL,
    anio INT NULL,
    version VARCHAR(100) NULL,
    vin VARCHAR(17) NOT NULL,
    color_exterior VARCHAR(80) NULL,
    color_interior VARCHAR(80) NULL,
    equipamiento TEXT NULL,
    costo_adquisicion DECIMAL(12,2) NOT NULL DEFAULT 0,
    precio_proyectado DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_pedido_vehiculos_pedidos FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ===== 3. SUCURSALES: datos fiscales y contacto operativo =====

ALTER TABLE sucursales
    ADD COLUMN IF NOT EXISTS razon_social VARCHAR(150) NULL,
    ADD COLUMN IF NOT EXISTS direccion_fiscal VARCHAR(255) NULL,
    ADD COLUMN IF NOT EXISTS contacto_operativo VARCHAR(120) NULL;

-- ===== 4. INVENTARIO: costo (margen bruto) y fecha de ingreso al patio (antigüedad) =====

ALTER TABLE productos
    ADD COLUMN IF NOT EXISTS costo_adquisicion DECIMAL(12,2) NULL;

ALTER TABLE inventarios
    ADD COLUMN IF NOT EXISTS fecha_ingreso DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- ===== 5. MÉTODOS DE LIQUIDACIÓN propios de la venta automotriz =====

INSERT IGNORE INTO metodos_pago (nombre_metodo) VALUES ('Cheque certificado'), ('Crédito bancario');

-- ===== 6. CATÁLOGO MAESTRO DE MODELOS Y VERSIONES =====

CREATE TABLE IF NOT EXISTS catalogo_modelos (
    id_modelo INT AUTO_INCREMENT PRIMARY KEY,
    marca VARCHAR(80) NOT NULL,
    modelo VARCHAR(150) NOT NULL,
    version VARCHAR(100) NULL,
    carroceria VARCHAR(60) NOT NULL,
    anio INT NULL,
    equipamiento TEXT NULL,
    precio_lista DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado ENUM('activo','inactivo') DEFAULT 'activo' NOT NULL
) ENGINE=InnoDB;

-- Modelos de ejemplo (sólo si el catálogo está vacío)
INSERT INTO catalogo_modelos (marca, modelo, version, carroceria, anio, equipamiento, precio_lista)
SELECT * FROM (
    SELECT 'Porsche' AS marca, '911 Carrera' AS modelo, 'GTS' AS version, 'Supercar' AS carroceria, 2025 AS anio,
           'Sport Chrono, escape deportivo, rines de 20"' AS equipamiento, 2850000 AS precio_lista
    UNION ALL SELECT 'Porsche', 'Cayenne', 'Turbo', 'SUV', 2025, 'Suspensión neumática, techo panorámico', 2190000
    UNION ALL SELECT 'Audi', 'R8', 'V10 Performance', 'Supercar', 2025, 'Frenos cerámicos, quattro', 3980000
    UNION ALL SELECT 'Audi', 'A6', 'S line', 'Sedán', 2025, 'Asistente de manejo, Matrix LED', 1150000
    UNION ALL SELECT 'Ducati', 'Panigale V2', 'S', 'Motocicleta', 2025, 'Öhlins, quickshifter', 495000
) AS ejemplos
WHERE NOT EXISTS (SELECT 1 FROM catalogo_modelos);

-- ===== 7. AUDITORÍA DE ACTIVIDAD (audit trail) =====

CREATE TABLE IF NOT EXISTS auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL,
    accion VARCHAR(60) NOT NULL,
    detalle VARCHAR(255) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_auditoria_usuarios FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;
