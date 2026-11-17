-- KARMA / pos_multisede — avisos_privacidad.sql
-- 1. Código de empleado del gafete (usuarios.codigo_empleado + trigger auto_codigo_empleado). La autorización con gafete del
--    Punto de Venta lo necesita y ningún script anterior lo creaba: sin él, ninguna venta podía autorizarse.
-- 2. Cambio de contraseña obligatorio: el empleado entra con la contraseña temporal que le puso el administrador y el sistema
--    le pide cambiarla antes de seguir (usuarios.debe_cambiar_password).
-- 3. Avisos de privacidad: estado del aviso enviado por correo a cada empleado (pendiente → enviado → revisado).
--
-- Importar DESPUÉS de pos_multisede.sql y dashboard_admin.sql, o desde la terminal:
--   C:/xampp/mysql/bin/mysql -u root pos_multisede < avisos_privacidad.sql
-- Se puede ejecutar varias veces sin riesgo: solo agrega lo que falta. Compatible con MariaDB y MySQL 8.

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

-- Ejecuta una sentencia (índice) solo si el índice con ese nombre todavía no existe
CREATE PROCEDURE karma_tmp_ejecutar_si_falta(IN p_tabla VARCHAR(64), IN p_indice VARCHAR(64), IN p_sql TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tabla AND INDEX_NAME = p_indice
    ) THEN
        SET @karma_sql = p_sql;
        PREPARE karma_st FROM @karma_sql;
        EXECUTE karma_st;
        DEALLOCATE PREPARE karma_st;
    END IF;
END$$

DELIMITER ;

-- ===== 1. Código de empleado (gafete EMP-0001) =====
CALL karma_tmp_agregar_columna('usuarios', 'codigo_empleado',
    'VARCHAR(20) NULL DEFAULT NULL COMMENT ''Código impreso y en QR del gafete (EMP- + 4 dígitos); lo asigna el trigger auto_codigo_empleado''');

-- Usuarios que ya existían: su código sale de su id (EMP-0001, EMP-0002…)
UPDATE usuarios
   SET codigo_empleado = CONCAT('EMP-', LPAD(id_usuario, 4, '0'))
 WHERE codigo_empleado IS NULL OR codigo_empleado = '';

CALL karma_tmp_ejecutar_si_falta('usuarios', 'uq_usuarios_codigo_empleado',
    'CREATE UNIQUE INDEX uq_usuarios_codigo_empleado ON usuarios (codigo_empleado)');

-- Usuarios nuevos: el siguiente número libre (el panel de administrador lo vuelve a fijar con el id si hiciera falta)
DROP TRIGGER IF EXISTS auto_codigo_empleado;
DELIMITER $$
CREATE TRIGGER auto_codigo_empleado BEFORE INSERT ON usuarios FOR EACH ROW
BEGIN
    IF NEW.codigo_empleado IS NULL OR NEW.codigo_empleado = '' THEN
        SET NEW.codigo_empleado = CONCAT('EMP-', LPAD(
            GREATEST(
                COALESCE((SELECT MAX(CAST(SUBSTRING(u.codigo_empleado, 5) AS UNSIGNED)) FROM usuarios u WHERE u.codigo_empleado LIKE 'EMP-%'), 0),
                COALESCE((SELECT MAX(u.id_usuario) FROM usuarios u), 0)
            ) + 1, 4, '0'));
    END IF;
END$$
DELIMITER ;

-- ===== 2. Cambio de contraseña obligatorio =====
CALL karma_tmp_agregar_columna('usuarios', 'debe_cambiar_password',
    'TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = entra con la contraseña temporal del administrador y debe cambiarla al iniciar sesión''');
CALL karma_tmp_agregar_columna('usuarios', 'fecha_cambio_password',
    'DATETIME NULL DEFAULT NULL COMMENT ''Última vez que el propio usuario cambió su contraseña''');

-- ===== 3. Avisos de privacidad enviados a los empleados =====
-- Un registro por empleado. estado: pendiente = aún no se envía (o el envío falló); enviado = Brevo aceptó el correo;
-- revisado = el empleado abrió el correo o el enlace al aviso integral.
CREATE TABLE IF NOT EXISTS avisos_privacidad (
    id_aviso INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    estado ENUM('pendiente','enviado','revisado') NOT NULL DEFAULT 'pendiente',
    token CHAR(64) NOT NULL COMMENT 'Identifica el correo de este empleado en el enlace y en la imagen de apertura',
    version_aviso VARCHAR(20) NOT NULL DEFAULT '2026-10-20' COMMENT 'Fecha de la versión del aviso enviada',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_envio DATETIME NULL DEFAULT NULL,
    fecha_revision DATETIME NULL DEFAULT NULL,
    intentos INT NOT NULL DEFAULT 0 COMMENT 'Veces que se intentó enviar el correo',
    ultimo_error VARCHAR(255) NULL DEFAULT NULL COMMENT 'Motivo del último envío fallido',
    id_mensaje VARCHAR(150) NULL DEFAULT NULL COMMENT 'messageId que regresó Brevo',
    UNIQUE KEY uq_avisos_privacidad_usuario (id_usuario),
    UNIQUE KEY uq_avisos_privacidad_token (token),
    CONSTRAINT fk_avisos_privacidad_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS karma_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS karma_tmp_ejecutar_si_falta;

-- Revisión rápida
SELECT u.id_usuario, u.nombre, u.codigo_empleado, u.debe_cambiar_password, COALESCE(a.estado, 'pendiente') AS aviso
  FROM usuarios u LEFT JOIN avisos_privacidad a ON a.id_usuario = u.id_usuario
 ORDER BY u.id_usuario;
