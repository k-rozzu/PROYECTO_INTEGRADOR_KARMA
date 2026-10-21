-- =====================================================================================
-- KARMA / pos_multisede — catalogo_registro_aceptacion.sql
-- Registro de clientes del Catálogo con aceptación expresa del Aviso de Privacidad y de los
-- Términos y Condiciones desde el correo de confirmación.
--
-- Se aplica sobre la base elegida (va después de catalogo_estructura.sql):
--     mysql -uroot --default-character-set=utf8mb4 pos_multisede < catalogo_registro_aceptacion.sql
--
-- SEGURO DE REIMPORTAR: no hay DROP TABLE / DROP DATABASE / DELETE ni cambios a columnas existentes.
-- Las tablas se crean solo si no existen; los triggers y el evento se reemplazan por su versión vigente.
--
-- Qué agrega:
--   * documentos_legales       → cada versión publicada del aviso y de los términos (texto exacto + huella SHA-256).
--   * registros_pendientes     → solicitudes de registro que esperan la aceptación desde el correo
--                                (el token de confirmación se guarda SOLO como hash SHA-256).
--   * aceptaciones_documentos  → constancia de aceptación: cliente + versión exacta + fecha, IP y navegador.
--   * triggers                 → impiden activar una cuenta en línea sin aceptación, reutilizar tokens,
--                                aceptar fuera de vigencia y modificar versiones o constancias.
--   * ev_registros_pendientes_vencidos → cada 15 min vence las solicitudes no confirmadas y borra sus datos.
-- =====================================================================================

SET NAMES utf8mb4;

-- ===== 1. VERSIONES DE LOS DOCUMENTOS LEGALES =====
-- El texto vive en PHP/Catalogo/includes/legal.php; la primera vez que se envía una versión se guarda aquí
-- tal cual. Una versión publicada no se modifica: si cambia el texto, se publica una versión nueva.

CREATE TABLE IF NOT EXISTS documentos_legales (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    tipo ENUM('aviso_privacidad','terminos_condiciones') NOT NULL,
    version VARCHAR(20) NOT NULL,
    fecha_vigencia DATE NOT NULL,
    hash_contenido CHAR(64) NOT NULL COMMENT 'SHA-256 del contenido exacto de la versión',
    contenido MEDIUMTEXT NOT NULL COMMENT 'Texto íntegro de la versión (JSON de secciones) como evidencia',
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_documentos_legales_version (tipo, version),
    UNIQUE KEY uq_documentos_legales_hash (tipo, hash_contenido),
    CONSTRAINT chk_documentos_legales_hash CHECK (hash_contenido REGEXP '^[0-9a-f]{64}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 2. SOLICITUDES DE REGISTRO PENDIENTES DE ACEPTACIÓN =====
-- estado: pendiente    → correo enviado, esperando que la persona confirme (no existe cuenta todavía)
--         completado   → aceptó desde el correo; la cuenta quedó creada o activada (id_cliente)
--         expirado     → venció sin confirmarse; sus datos personales se borraron
--         cancelado    → la persona la canceló, falló el envío o hubo un conflicto; datos borrados
--         aviso_cuenta → el correo ya tenía una cuenta: solo se le avisó (no guarda datos ni token)
-- email_hash permite aplicar límites de envío sin conservar el correo; también se borra al día siguiente.

CREATE TABLE IF NOT EXISTS registros_pendientes (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM('pendiente','completado','expirado','cancelado','aviso_cuenta') NOT NULL DEFAULT 'pendiente',
    email VARCHAR(120) NULL,
    email_hash CHAR(64) NULL COMMENT 'SHA-256 del correo en minúsculas (límites de envío)',
    nombres VARCHAR(80) NULL,
    apellidos VARCHAR(100) NULL,
    celular VARCHAR(30) NULL,
    direccion VARCHAR(255) NULL,
    ciudad VARCHAR(100) NULL,
    entidad_federativa VARCHAR(80) NULL,
    codigo_postal VARCHAR(10) NULL,
    id_sucursal_preferida INT NULL,
    marca_interes VARCHAR(80) NULL,
    notif_promociones TINYINT(1) NOT NULL DEFAULT 0,
    password_hash VARCHAR(255) NULL COMMENT 'Hash bcrypt; nunca la contraseña en texto plano',
    token_hash CHAR(64) NULL COMMENT 'SHA-256 del token del enlace; el token completo nunca se guarda',
    id_aviso INT NULL COMMENT 'Versión del aviso enviada en el PDF',
    id_terminos INT NULL COMMENT 'Versión de los términos enviada en el PDF',
    envios INT NOT NULL DEFAULT 0,
    fecha_ultimo_envio DATETIME NULL,
    fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion DATETIME NULL,
    fecha_aceptacion DATETIME NULL,
    fecha_cierre DATETIME NULL,
    id_cliente INT NULL,
    ip_solicitud VARCHAR(45) NULL,
    -- Solo puede haber UNA solicitud pendiente por correo (la columna vale NULL en los demás estados)
    email_pendiente VARCHAR(120) AS (IF(estado = 'pendiente', email, NULL)) PERSISTENT,
    UNIQUE KEY uq_registros_token (token_hash),
    UNIQUE KEY uq_registros_email_pendiente (email_pendiente),
    KEY idx_registros_email_hash (email_hash, fecha_solicitud),
    KEY idx_registros_ip (ip_solicitud, fecha_solicitud),
    KEY idx_registros_vencimiento (estado, fecha_expiracion),
    KEY fk_registros_aviso (id_aviso),
    KEY fk_registros_terminos (id_terminos),
    KEY fk_registros_cliente (id_cliente),
    KEY fk_registros_sucursal (id_sucursal_preferida),
    CONSTRAINT fk_registros_aviso FOREIGN KEY (id_aviso) REFERENCES documentos_legales(id_documento),
    CONSTRAINT fk_registros_terminos FOREIGN KEY (id_terminos) REFERENCES documentos_legales(id_documento),
    CONSTRAINT fk_registros_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON UPDATE CASCADE,
    CONSTRAINT fk_registros_sucursal FOREIGN KEY (id_sucursal_preferida) REFERENCES sucursales(id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL,
    -- Una solicitud pendiente siempre tiene token, datos completos, versiones enviadas y vencimiento
    CONSTRAINT chk_registros_pendiente CHECK (estado <> 'pendiente' OR (token_hash IS NOT NULL AND email IS NOT NULL
        AND password_hash IS NOT NULL AND id_aviso IS NOT NULL AND id_terminos IS NOT NULL AND fecha_expiracion IS NOT NULL)),
    -- Una solicitud completada siempre quedó ligada a su cuenta y a la fecha de aceptación
    CONSTRAINT chk_registros_completado CHECK (estado <> 'completado' OR (id_cliente IS NOT NULL AND fecha_aceptacion IS NOT NULL)),
    CONSTRAINT chk_registros_token CHECK (token_hash IS NULL OR token_hash REGEXP '^[0-9a-f]{64}$'),
    CONSTRAINT chk_registros_vigencia CHECK (fecha_expiracion IS NULL OR fecha_expiracion > fecha_solicitud),
    CONSTRAINT chk_registros_envios CHECK (envios >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 3. CONSTANCIAS DE ACEPTACIÓN =====
-- Una fila por documento aceptado (aviso y términos) en cada registro confirmado. Son evidencia del
-- consentimiento: no se modifican y no se pueden duplicar para la misma solicitud.

CREATE TABLE IF NOT EXISTS aceptaciones_documentos (
    id_aceptacion INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_documento INT NOT NULL,
    id_registro INT NOT NULL,
    fecha_aceptacion DATETIME NOT NULL,
    ip VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    medio VARCHAR(60) NOT NULL DEFAULT 'Botón de la página de confirmación del correo',
    UNIQUE KEY uq_aceptaciones_registro_documento (id_registro, id_documento),
    KEY idx_aceptaciones_cliente (id_cliente, fecha_aceptacion),
    KEY fk_aceptaciones_documento (id_documento),
    CONSTRAINT fk_aceptaciones_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON UPDATE CASCADE,
    CONSTRAINT fk_aceptaciones_documento FOREIGN KEY (id_documento) REFERENCES documentos_legales(id_documento),
    CONSTRAINT fk_aceptaciones_registro FOREIGN KEY (id_registro) REFERENCES registros_pendientes(id_registro)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== 4. TRIGGERS (las reglas se cumplen aunque alguien intente saltarse el PHP) =====

DROP TRIGGER IF EXISTS trg_documentos_legales_inmutables;
DROP TRIGGER IF EXISTS trg_registros_pendientes_nuevo;
DROP TRIGGER IF EXISTS trg_registros_pendientes_cambio;
DROP TRIGGER IF EXISTS trg_aceptaciones_documentos_nueva;
DROP TRIGGER IF EXISTS trg_aceptaciones_documentos_inmutables;
DROP TRIGGER IF EXISTS trg_clientes_activacion_alta;
DROP TRIGGER IF EXISTS trg_clientes_activacion_cambio;

DELIMITER $$

-- Una versión publicada del aviso o de los términos no puede cambiar su texto ni su número de versión
CREATE TRIGGER trg_documentos_legales_inmutables BEFORE UPDATE ON documentos_legales FOR EACH ROW
BEGIN
    IF NEW.tipo <> OLD.tipo OR NEW.version <> OLD.version OR NEW.hash_contenido <> OLD.hash_contenido
       OR NEW.contenido <> OLD.contenido OR NEW.fecha_vigencia <> OLD.fecha_vigencia THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una versión publicada no se modifica: publica una versión nueva.';
    END IF;
END$$

-- Toda solicitud nace pendiente (o como aviso a una cuenta existente), sin aceptación y con vencimiento futuro
CREATE TRIGGER trg_registros_pendientes_nuevo BEFORE INSERT ON registros_pendientes FOR EACH ROW
BEGIN
    IF NEW.estado NOT IN ('pendiente', 'aviso_cuenta') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una solicitud de registro solo puede crearse como pendiente.';
    END IF;
    IF NEW.fecha_aceptacion IS NOT NULL OR NEW.id_cliente IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La aceptación solo se registra al confirmar desde el correo.';
    END IF;
    IF NEW.fecha_expiracion IS NULL OR NEW.fecha_expiracion <= NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La solicitud necesita una fecha de vencimiento futura.';
    END IF;
    IF NEW.estado = 'aviso_cuenta' AND (NEW.token_hash IS NOT NULL OR NEW.email IS NOT NULL OR NEW.password_hash IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un aviso a una cuenta existente no guarda token, correo ni contraseña.';
    END IF;
END$$

-- Reglas de cambio de estado: los estados finales no se reabren, el token no se reutiliza ni se reemplaza
-- después de aceptar, la aceptación debe ocurrir antes del vencimiento y completar exige las dos constancias
CREATE TRIGGER trg_registros_pendientes_cambio BEFORE UPDATE ON registros_pendientes FOR EACH ROW
BEGIN
    DECLARE v_constancias INT DEFAULT 0;

    IF OLD.estado <> 'pendiente' THEN
        IF NEW.estado <> OLD.estado OR NOT (NEW.token_hash <=> OLD.token_hash)
           OR NOT (NEW.fecha_aceptacion <=> OLD.fecha_aceptacion) OR NOT (NEW.id_cliente <=> OLD.id_cliente) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La solicitud ya se cerró: su token no puede volver a usarse.';
        END IF;
    ELSE
        IF OLD.fecha_aceptacion IS NOT NULL AND NOT (NEW.token_hash <=> OLD.token_hash) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La solicitud ya fue aceptada: su token no puede reemplazarse.';
        END IF;
        IF OLD.fecha_aceptacion IS NULL AND NEW.fecha_aceptacion IS NOT NULL
           AND (NEW.estado <> 'pendiente' OR OLD.fecha_expiracion <= NOW() OR NOT (NEW.token_hash <=> OLD.token_hash)) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La aceptación debe registrarse con el token vigente y antes del vencimiento.';
        END IF;
        IF NEW.estado = 'expirado' AND OLD.fecha_expiracion > NOW() THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una solicitud vigente no puede marcarse como vencida.';
        END IF;
        IF NEW.estado = 'completado' THEN
            SELECT COUNT(*) INTO v_constancias FROM aceptaciones_documentos
             WHERE id_registro = OLD.id_registro AND id_cliente = NEW.id_cliente
               AND id_documento IN (OLD.id_aviso, OLD.id_terminos);
            IF OLD.fecha_aceptacion IS NULL OR v_constancias <> 2 OR NOT (NEW.token_hash <=> OLD.token_hash) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede completar el registro sin la aceptación de ambos documentos.';
            END IF;
        END IF;
        IF NEW.estado = 'aviso_cuenta' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una solicitud pendiente no puede convertirse en aviso.';
        END IF;
    END IF;
END$$

-- La constancia debe pertenecer a una solicitud aceptada, a una de las versiones enviadas en su PDF y a la
-- cuenta de ese mismo correo; la fecha de aceptación se toma de la solicitud
CREATE TRIGGER trg_aceptaciones_documentos_nueva BEFORE INSERT ON aceptaciones_documentos FOR EACH ROW
BEGIN
    DECLARE v_fecha DATETIME DEFAULT NULL;
    SELECT r.fecha_aceptacion INTO v_fecha
      FROM registros_pendientes r
      JOIN clientes c ON c.id_cliente = NEW.id_cliente AND c.email = r.email
     WHERE r.id_registro = NEW.id_registro AND r.estado = 'pendiente' AND r.fecha_aceptacion IS NOT NULL
       AND NEW.id_documento IN (r.id_aviso, r.id_terminos)
     LIMIT 1;
    IF v_fecha IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La constancia debe corresponder a la solicitud confirmada y a las versiones enviadas.';
    END IF;
    SET NEW.fecha_aceptacion = v_fecha;
END$$

CREATE TRIGGER trg_aceptaciones_documentos_inmutables BEFORE UPDATE ON aceptaciones_documentos FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las constancias de aceptación son evidencia y no se modifican.';
END$$

-- Una cuenta en línea (contraseña) solo se crea con una solicitud aceptada del mismo correo y la misma contraseña.
-- Los clientes del POS sin contraseña y los cambios de contraseña de cuentas ya activas no se ven afectados.
CREATE TRIGGER trg_clientes_activacion_alta BEFORE INSERT ON clientes FOR EACH ROW
BEGIN
    IF NULLIF(NEW.password_hash, '') IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM registros_pendientes r
         WHERE r.estado = 'pendiente' AND r.email = NEW.email AND r.password_hash = NEW.password_hash
           AND r.fecha_aceptacion IS NOT NULL AND r.fecha_aceptacion <= r.fecha_expiracion) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cuenta en línea solo se activa al aceptar el aviso y los términos desde el correo.';
    END IF;
END$$

CREATE TRIGGER trg_clientes_activacion_cambio BEFORE UPDATE ON clientes FOR EACH ROW
BEGIN
    IF NULLIF(NEW.password_hash, '') IS NOT NULL AND NULLIF(OLD.password_hash, '') IS NULL AND NOT EXISTS (
        SELECT 1 FROM registros_pendientes r
         WHERE r.estado = 'pendiente' AND r.email = NEW.email AND r.password_hash = NEW.password_hash
           AND r.fecha_aceptacion IS NOT NULL AND r.fecha_aceptacion <= r.fecha_expiracion) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cuenta en línea solo se activa al aceptar el aviso y los términos desde el correo.';
    END IF;
END$$

DELIMITER ;

-- ===== 5. SOLICITUDES VENCIDAS: se cierran y se borran sus datos (el PHP también lo hace en cada registro) =====
-- Requiere event_scheduler=ON (ya activo en my.ini para ev_garantias_vencidas).

DROP EVENT IF EXISTS ev_registros_pendientes_vencidos;

DELIMITER $$
CREATE EVENT ev_registros_pendientes_vencidos
    ON SCHEDULE EVERY 15 MINUTE
    DO BEGIN
        UPDATE registros_pendientes
           SET estado = 'expirado', fecha_cierre = NOW(), email = NULL, nombres = NULL, apellidos = NULL, celular = NULL,
               direccion = NULL, ciudad = NULL, entidad_federativa = NULL, codigo_postal = NULL,
               id_sucursal_preferida = NULL, marca_interes = NULL, password_hash = NULL
         WHERE estado = 'pendiente' AND fecha_expiracion <= NOW();
        -- Un día después del cierre ya no se necesitan la IP ni la huella del correo (solo servían para los límites)
        UPDATE registros_pendientes SET ip_solicitud = NULL, email_hash = NULL
         WHERE estado <> 'pendiente' AND (ip_solicitud IS NOT NULL OR email_hash IS NOT NULL)
           AND COALESCE(fecha_cierre, fecha_expiracion) <= NOW() - INTERVAL 1 DAY;
    END$$
DELIMITER ;

-- Verificación rápida (solo muestra resultados)
SELECT TABLE_NAME AS tabla_registro
  FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME IN ('documentos_legales', 'registros_pendientes', 'aceptaciones_documentos');
