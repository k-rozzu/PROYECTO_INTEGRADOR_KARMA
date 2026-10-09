-- =====================================================================================
-- KARMA / pos_multisede — catalogo_estructura.sql
-- Estructura que necesita el módulo CATÁLOGO (sitio web de clientes) para integrarse con el POS.
--
-- ORDEN DE IMPORTACIÓN (base nueva):
--   1. pos_multisede.sql  2. cajero_extensiones.sql  3. adicionales_tickets.sql
--   4. datos_prueba_cajero.sql  5. ajustes.sql
--   6. catalogo_estructura.sql   <-- este archivo
--   7. catalogo_productos.sql    (75 productos + accesorios + Colima + inventarios)
--   8. catalogo_datos_demo.sql   (promociones, opciones del configurador, cajeros de prueba)
--
-- SEGURO DE REIMPORTAR: no hay DROP TABLE / DROP DATABASE / DELETE. Todo se crea solo si no existe
-- (CREATE TABLE IF NOT EXISTS + procedimientos temporales que revisan information_schema),
-- así funciona igual en MariaDB (XAMPP) y en MySQL 8.
--
-- Qué agrega:
--   * productos_web        → ficha web 1:1 de cada producto (imagen, galería, sección, specs, publicación).
--   * sucursales  (+cols)  → ciudad, correo, horarios, servicios e imagen de cada sucursal.
--   * clientes    (+cols)  → cuenta en línea del cliente (contraseña con hash, dirección, preferencias).
--   * web_orders  (+cols)  → folio, cliente, sucursal, entrega, pago, totales y reserva de stock.
--   * web_order_detalle    → líneas del pedido (un carrito puede tener varias refacciones).
--   * citas                → visitas, apartados, pruebas de manejo y citas de servicio.
--   * solicitudes          → contacto, información, cotizaciones, garantía, seguros, financiamiento…
--   * notificaciones       → avisos que ve el cliente en su perfil.
--   * clientes_favoritos   → vehículos de interés del cliente.
--   * promociones          → promociones de demostración que muestra el sitio.
--   * catalogo_opciones    → colores, versiones y equipamiento del configurador.
-- =====================================================================================

SET NAMES utf8mb4;
USE pos_multisede;

-- ===== 0. PROCEDIMIENTOS TEMPORALES (se borran al final) =====

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS karma_tmp_ejecutar_si_falta;

DELIMITER $$

-- Agrega una columna solo si todavía no existe en la tabla
CREATE PROCEDURE karma_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND COLUMN_NAME = p_columna
    ) THEN
        SET @karma_sql = CONCAT('ALTER TABLE `', p_tabla, '` ADD COLUMN `', p_columna, '` ', p_definicion);
        PREPARE karma_st FROM @karma_sql;
        EXECUTE karma_st;
        DEALLOCATE PREPARE karma_st;
    END IF;
END$$

-- Ejecuta una sentencia (índice o llave foránea) solo si el objeto con ese nombre no existe
-- p_tipo: 'indice' revisa information_schema.STATISTICS, 'fk' revisa TABLE_CONSTRAINTS
CREATE PROCEDURE karma_tmp_ejecutar_si_falta(IN p_tipo VARCHAR(10), IN p_tabla VARCHAR(64), IN p_nombre VARCHAR(64), IN p_sql TEXT)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    IF p_tipo = 'indice' THEN
        SELECT COUNT(*) INTO v_existe FROM information_schema.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND INDEX_NAME = p_nombre;
    ELSE
        SELECT COUNT(*) INTO v_existe FROM information_schema.TABLE_CONSTRAINTS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND CONSTRAINT_NAME = p_nombre
           AND CONSTRAINT_TYPE = 'FOREIGN KEY';
    END IF;
    IF v_existe = 0 THEN
        SET @karma_sql = p_sql;
        PREPARE karma_st FROM @karma_sql;
        EXECUTE karma_st;
        DEALLOCATE PREPARE karma_st;
    END IF;
END$$

DELIMITER ;

-- ===== 1. PRODUCTOS_WEB: ficha web de cada producto (1 a 1 con productos) =====
-- El POS sigue usando `productos` tal cual; aquí vive solo lo que necesita el sitio web.
-- Un producto SIN fila en productos_web (o con publicado = 0) no aparece en el Catálogo.
-- IMÁGENES: `imagen` y `galeria` guardan rutas relativas a la raíz del proyecto,
--           por ejemplo assets/Catalogo/vehiculos/audi/a3.webp (ver docs/CATALOGO.md).

CREATE TABLE IF NOT EXISTS productos_web (
    id_producto INT NOT NULL PRIMARY KEY,
    seccion ENUM('vehiculos','refacciones','accesorios') NOT NULL,
    publicado TINYINT(1) NOT NULL DEFAULT 1,
    destacado TINYINT(1) NOT NULL DEFAULT 0,
    condicion ENUM('nuevo','seminuevo') NOT NULL DEFAULT 'nuevo',
    subcategoria VARCHAR(60) NULL,
    imagen VARCHAR(255) NULL,
    galeria TEXT NULL,
    transmision VARCHAR(100) NULL,
    potencia VARCHAR(40) NULL,
    aceleracion VARCHAR(40) NULL,
    descripcion_larga TEXT NULL,
    caracteristicas TEXT NULL,
    orden INT NOT NULL DEFAULT 0,
    fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_productosweb_seccion (seccion, publicado),
    CONSTRAINT fk_productosweb_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 2. SUCURSALES: datos de contacto que muestra el sitio =====

CALL karma_tmp_agregar_columna('sucursales', 'ciudad', 'VARCHAR(80) NULL');
CALL karma_tmp_agregar_columna('sucursales', 'email', 'VARCHAR(120) NULL');
CALL karma_tmp_agregar_columna('sucursales', 'horario_ventas', 'VARCHAR(150) NULL');
CALL karma_tmp_agregar_columna('sucursales', 'horario_servicio', 'VARCHAR(150) NULL');
CALL karma_tmp_agregar_columna('sucursales', 'servicios', 'VARCHAR(500) NULL');
CALL karma_tmp_agregar_columna('sucursales', 'imagen', 'VARCHAR(255) NULL');

-- ===== 3. CLIENTES: cuenta en línea (se reutiliza la tabla del POS, no se duplica) =====
-- `nombre` sigue siendo el nombre completo que usa el POS; `nombres` y `apellidos` los usa el perfil web.
-- `password_hash` queda NULL para los clientes que solo existen en el POS (crédito / ventas en sucursal).

CALL karma_tmp_agregar_columna('clientes', 'nombres', 'VARCHAR(80) NULL');
CALL karma_tmp_agregar_columna('clientes', 'apellidos', 'VARCHAR(100) NULL');
CALL karma_tmp_agregar_columna('clientes', 'password_hash', 'VARCHAR(255) NULL');
CALL karma_tmp_agregar_columna('clientes', 'ciudad', 'VARCHAR(100) NULL');
CALL karma_tmp_agregar_columna('clientes', 'entidad_federativa', 'VARCHAR(80) NULL');
CALL karma_tmp_agregar_columna('clientes', 'codigo_postal', 'VARCHAR(10) NULL');
CALL karma_tmp_agregar_columna('clientes', 'id_sucursal_preferida', 'INT NULL');
CALL karma_tmp_agregar_columna('clientes', 'marca_interes', 'VARCHAR(80) NULL');
CALL karma_tmp_agregar_columna('clientes', 'notif_email', 'TINYINT(1) NOT NULL DEFAULT 1');
CALL karma_tmp_agregar_columna('clientes', 'notif_sms', 'TINYINT(1) NOT NULL DEFAULT 0');
CALL karma_tmp_agregar_columna('clientes', 'notif_promociones', 'TINYINT(1) NOT NULL DEFAULT 1');
CALL karma_tmp_agregar_columna('clientes', 'fecha_registro', 'DATETIME NULL');
CALL karma_tmp_agregar_columna('clientes', 'ultimo_acceso', 'DATETIME NULL');

CALL karma_tmp_ejecutar_si_falta('fk', 'clientes', 'fk_clientes_sucursal_preferida',
    'ALTER TABLE clientes ADD CONSTRAINT fk_clientes_sucursal_preferida FOREIGN KEY (id_sucursal_preferida) REFERENCES sucursales(id_sucursal) ON UPDATE CASCADE ON DELETE SET NULL');

-- ===== 4. WEB_ORDERS: encabezado del pedido web (las columnas originales no cambian) =====
-- Las órdenes antiguas (sin folio) siguen funcionando igual en el POS.
-- estado        → lo que ve el cajero: pendiente (por atender/cobrar) · atendida · cancelada
-- estado_pago   → pendiente (pagará en sucursal) · pagado · reembolsado
-- stock_reservado = 1 → el inventario de ESA sucursal ya se descontó al crear el pedido;
--                       el cobro en caja NO vuelve a descontar y una cancelación lo regresa.

CALL karma_tmp_agregar_columna('web_orders', 'folio', 'VARCHAR(20) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'id_cliente', 'INT NULL');
CALL karma_tmp_agregar_columna('web_orders', 'id_sucursal', 'INT NULL');
CALL karma_tmp_agregar_columna('web_orders', 'metodo_entrega', "ENUM('recoger','envio') NULL");
CALL karma_tmp_agregar_columna('web_orders', 'id_metodo_pago', 'INT NULL');
CALL karma_tmp_agregar_columna('web_orders', 'estado_pago', "ENUM('pendiente','pagado','reembolsado') NOT NULL DEFAULT 'pendiente'");
CALL karma_tmp_agregar_columna('web_orders', 'subtotal', 'DECIMAL(12,2) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'costo_envio', 'DECIMAL(12,2) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'total', 'DECIMAL(12,2) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'direccion_envio', 'VARCHAR(400) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'tarjeta_marca', 'VARCHAR(20) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'tarjeta_ultimos4', 'CHAR(4) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'referencia_pago', 'VARCHAR(40) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'stock_reservado', 'TINYINT(1) NOT NULL DEFAULT 0');
CALL karma_tmp_agregar_columna('web_orders', 'comentarios', 'VARCHAR(500) NULL');
CALL karma_tmp_agregar_columna('web_orders', 'fecha_creacion', 'DATETIME NULL');
CALL karma_tmp_agregar_columna('web_orders', 'fecha_pago', 'DATETIME NULL');
CALL karma_tmp_agregar_columna('web_orders', 'id_venta', 'INT NULL');

CALL karma_tmp_ejecutar_si_falta('indice', 'web_orders', 'uq_weborders_folio',
    'ALTER TABLE web_orders ADD UNIQUE KEY uq_weborders_folio (folio)');
CALL karma_tmp_ejecutar_si_falta('indice', 'web_orders', 'idx_weborders_sucursal_estado',
    'ALTER TABLE web_orders ADD KEY idx_weborders_sucursal_estado (id_sucursal, estado)');
CALL karma_tmp_ejecutar_si_falta('fk', 'web_orders', 'fk_weborders_clientes',
    'ALTER TABLE web_orders ADD CONSTRAINT fk_weborders_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON UPDATE CASCADE ON DELETE SET NULL');
CALL karma_tmp_ejecutar_si_falta('fk', 'web_orders', 'fk_weborders_sucursales',
    'ALTER TABLE web_orders ADD CONSTRAINT fk_weborders_sucursales FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) ON UPDATE CASCADE ON DELETE SET NULL');
CALL karma_tmp_ejecutar_si_falta('fk', 'web_orders', 'fk_weborders_metodos_pago',
    'ALTER TABLE web_orders ADD CONSTRAINT fk_weborders_metodos_pago FOREIGN KEY (id_metodo_pago) REFERENCES metodos_pago(id_metodo_pago) ON UPDATE CASCADE ON DELETE SET NULL');
CALL karma_tmp_ejecutar_si_falta('fk', 'web_orders', 'fk_weborders_ventas',
    'ALTER TABLE web_orders ADD CONSTRAINT fk_weborders_ventas FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON UPDATE CASCADE ON DELETE SET NULL');

-- ===== 5. WEB_ORDER_DETALLE: líneas del pedido (mismo patrón que ventas → detalle_ventas) =====

CREATE TABLE IF NOT EXISTS web_order_detalle (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal_linea DECIMAL(12,2) NOT NULL,
    descripcion VARCHAR(200) NULL,
    CONSTRAINT chk_wod_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_wod_orden FOREIGN KEY (id_orden) REFERENCES web_orders(id_orden)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_wod_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 6. CITAS: visitas, apartados, pruebas de manejo y servicio postventa =====
-- Las visitas y apartados de vehículo además generan una fila en web_orders (id_orden) para que lleguen al cajero.

CREATE TABLE IF NOT EXISTS citas (
    id_cita INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) NULL,
    tipo ENUM('visita','apartado','prueba_manejo','servicio') NOT NULL,
    id_cliente INT NULL,
    id_sucursal INT NOT NULL,
    id_producto INT NULL,
    id_orden INT NULL,
    fecha_hora DATETIME NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(120) NULL,
    telefono VARCHAR(30) NULL,
    vehiculo_cliente VARCHAR(150) NULL,
    vin VARCHAR(17) NULL,
    kilometraje INT NULL,
    tipo_servicio VARCHAR(80) NULL,
    comentarios VARCHAR(1000) NULL,
    estado ENUM('programada','confirmada','completada','cancelada') NOT NULL DEFAULT 'programada',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_citas_folio (folio),
    KEY idx_citas_agenda (id_sucursal, fecha_hora),
    KEY idx_citas_cliente (id_cliente),
    CONSTRAINT fk_citas_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_citas_sucursales FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_citas_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_citas_weborders FOREIGN KEY (id_orden) REFERENCES web_orders(id_orden)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 7. SOLICITUDES: contacto, información, cotización, garantía, seguros, financiamiento… =====

CREATE TABLE IF NOT EXISTS solicitudes (
    id_solicitud INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) NULL,
    tipo ENUM('informacion','cotizacion','contacto','queja','sugerencia','garantia','seguro','financiamiento','seminuevo','postventa','otro') NOT NULL,
    id_cliente INT NULL,
    id_sucursal INT NULL,
    id_producto INT NULL,
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(120) NOT NULL,
    telefono VARCHAR(30) NULL,
    asunto VARCHAR(150) NULL,
    mensaje TEXT NULL,
    datos TEXT NULL,
    estado ENUM('nueva','en_proceso','atendida','cerrada') NOT NULL DEFAULT 'nueva',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_solicitudes_folio (folio),
    KEY idx_solicitudes_cliente (id_cliente),
    CONSTRAINT fk_solicitudes_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_solicitudes_sucursales FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_solicitudes_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 8. NOTIFICACIONES del cliente (pedido creado, pedido cobrado en caja, citas…) =====

CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    tipo ENUM('pedido','cita','solicitud','promocion','cuenta') NOT NULL DEFAULT 'cuenta',
    titulo VARCHAR(150) NOT NULL,
    mensaje VARCHAR(500) NULL,
    enlace VARCHAR(255) NULL,
    leida TINYINT(1) NOT NULL DEFAULT 0,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_notificaciones_cliente (id_cliente, leida),
    CONSTRAINT fk_notificaciones_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 9. VEHÍCULOS DE INTERÉS (favoritos) =====

CREATE TABLE IF NOT EXISTS clientes_favoritos (
    id_cliente INT NOT NULL,
    id_producto INT NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente, id_producto),
    CONSTRAINT fk_favoritos_clientes FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_favoritos_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 10. PROMOCIONES (datos de demostración; no son ofertas oficiales de las marcas) =====

CREATE TABLE IF NOT EXISTS promociones (
    id_promocion INT AUTO_INCREMENT PRIMARY KEY,
    clave VARCHAR(40) NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    subtitulo VARCHAR(200) NULL,
    descripcion TEXT NULL,
    tipo ENUM('vehiculos','refacciones','servicio','financiamiento','accesorios') NOT NULL,
    marca VARCHAR(80) NULL,
    etiqueta VARCHAR(40) NULL,
    imagen VARCHAR(255) NULL,
    condiciones TEXT NULL,
    fecha_inicio DATE NULL,
    fecha_fin DATE NULL,
    cta_texto VARCHAR(60) NULL,
    cta_url VARCHAR(255) NULL,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    orden INT NOT NULL DEFAULT 0,
    UNIQUE KEY uq_promociones_clave (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 11. OPCIONES DEL CONFIGURADOR (color, versión y equipamiento por marca) =====

CREATE TABLE IF NOT EXISTS catalogo_opciones (
    id_opcion INT AUTO_INCREMENT PRIMARY KEY,
    clave VARCHAR(60) NOT NULL,
    marca VARCHAR(80) NULL,
    tipo_vehiculo ENUM('auto','moto') NULL,
    grupo ENUM('color','version','equipamiento') NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(255) NULL,
    precio DECIMAL(12,2) NOT NULL DEFAULT 0,
    color_hex VARCHAR(20) NULL,
    orden INT NOT NULL DEFAULT 0,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY uq_catalogo_opciones_clave (clave),
    KEY idx_catalogo_opciones_marca (marca, grupo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 12. LIMPIEZA: se borran los procedimientos temporales =====

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS karma_tmp_ejecutar_si_falta;

-- Verificación rápida (solo muestra resultados)
SELECT TABLE_NAME AS tabla_catalogo
  FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME IN ('productos_web','web_order_detalle','citas','solicitudes','notificaciones','clientes_favoritos','promociones','catalogo_opciones');
