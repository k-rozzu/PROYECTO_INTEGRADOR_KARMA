-- KARMA / pos_multisede — ajustes.sql: código de barras y VIN autogenerados, VIN faltantes, acabados de refacciones y ruta de modelo 3D.
-- Importar en phpMyAdmin DESPUÉS de pos_multisede.sql, cajero_extensiones.sql, adicionales_tickets.sql, datos_prueba_cajero.sql y catalogo_productos.sql.
-- Se puede importar varias veces sin duplicar nada (todo usa IF NOT EXISTS / DROP IF EXISTS / WHERE ... IS NULL).

USE pos_multisede;

-- ===== 1. COLUMNAS NECESARIAS =====

-- Asegura las columnas vin y color_interior (ya existen en tu base, pero no venían en los .sql del proyecto)
ALTER TABLE productos
    ADD COLUMN IF NOT EXISTS color_interior VARCHAR(80) NULL,
    ADD COLUMN IF NOT EXISTS vin VARCHAR(17) NULL;

-- Garantiza que no se repita ningún VIN
CREATE UNIQUE INDEX IF NOT EXISTS uq_productos_vin ON productos(vin);

-- Nueva columna opcional con la ruta de un modelo 3D (.glb) propio para el producto
ALTER TABLE productos
    ADD COLUMN IF NOT EXISTS modelo_3d VARCHAR(255) NULL;

-- Permite insertar productos SIN escribir el código de barras (el trigger lo genera)
ALTER TABLE productos
    MODIFY codigo_barras VARCHAR(50) NOT NULL DEFAULT '';

-- ===== 2. FUNCIONES QUE ARMAN LOS CÓDIGOS =====

DROP FUNCTION IF EXISTS karma_abrev_marca;
DROP FUNCTION IF EXISTS karma_generar_codigo_barras;
DROP FUNCTION IF EXISTS karma_wmi_marca;
DROP FUNCTION IF EXISTS karma_letra_anio_vin;
DROP FUNCTION IF EXISTS karma_armar_vin;
DROP FUNCTION IF EXISTS karma_generar_vin;

DELIMITER $$

-- Abreviatura de marca usada en el código de barras (AUDI, POR, DUC; otras = primeras 4 letras)
CREATE FUNCTION karma_abrev_marca(p_marca VARCHAR(80))
RETURNS VARCHAR(10)
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
END$$

-- Siguiente código de barras con el formato del catálogo: KRM-CAT-AUDI-16 o KRM-CAT-REF-POR-11
CREATE FUNCTION karma_generar_codigo_barras(p_marca VARCHAR(80), p_tipo VARCHAR(30))
RETURNS VARCHAR(50)
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
END$$

-- Primeros 3 caracteres del VIN (fabricante): WAU = Audi, WP0 = Porsche, ZDM = Ducati
CREATE FUNCTION karma_wmi_marca(p_marca VARCHAR(80))
RETURNS CHAR(3)
DETERMINISTIC
BEGIN
    -- Normaliza la marca para compararla
    DECLARE v_marca VARCHAR(80) DEFAULT UPPER(TRIM(COALESCE(p_marca, '')));
    IF v_marca = 'AUDI' THEN RETURN 'WAU'; END IF;
    IF v_marca = 'PORSCHE' THEN RETURN 'WP0'; END IF;
    IF v_marca = 'DUCATI' THEN RETURN 'ZDM'; END IF;
    -- Marca nueva: se usa el prefijo de la agencia
    RETURN 'KRM';
END$$

-- Letra del año del VIN (posición 10): 2023 = P, 2024 = R, 2025 = S, 2026 = T …
CREATE FUNCTION karma_letra_anio_vin(p_anio INT)
RETURNS CHAR(1)
DETERMINISTIC
BEGIN
    -- Ciclo oficial de 30 años sin I, O, Q, U, Z ni 0 (empieza en 2010 = A)
    DECLARE v_anio INT DEFAULT COALESCE(p_anio, YEAR(CURDATE()));
    RETURN SUBSTRING('ABCDEFGHJKLMNPRSTVWXY123456789', MOD(MOD(v_anio - 2010, 30) + 30, 30) + 1, 1);
END$$

-- Arma un VIN de 17 caracteres igual a los existentes: WMI + ZZZ + ZZ + 0 + año + S + serie de 6 dígitos
CREATE FUNCTION karma_armar_vin(p_marca VARCHAR(80), p_anio INT, p_serie INT)
RETURNS VARCHAR(17)
DETERMINISTIC
BEGIN
    RETURN CONCAT(karma_wmi_marca(p_marca), 'ZZZ', 'ZZ', '0', karma_letra_anio_vin(p_anio), 'S', LPAD(p_serie, 6, '0'));
END$$

-- Siguiente VIN libre: toma la serie más alta registrada y le suma 37 (mismo salto que los VIN actuales)
CREATE FUNCTION karma_generar_vin(p_marca VARCHAR(80), p_anio INT)
RETURNS VARCHAR(17)
READS SQL DATA
BEGIN
    DECLARE v_serie INT;
    -- Última serie usada (los 6 dígitos finales del VIN); si no hay ninguna empieza en 100000
    SELECT COALESCE(MAX(CAST(RIGHT(vin, 6) AS UNSIGNED)), 100000)
      INTO v_serie
      FROM productos
     WHERE vin IS NOT NULL AND vin <> '';
    RETURN karma_armar_vin(p_marca, p_anio, v_serie + 37);
END$$

DELIMITER ;

-- ===== 3. TRIGGER: AUTOGENERA AL INSERTAR =====

DROP TRIGGER IF EXISTS trg_productos_autogenerar;

DELIMITER $$

-- Antes de guardar un producto nuevo: si no trae código de barras o VIN, se generan solos
CREATE TRIGGER trg_productos_autogenerar
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
END$$

DELIMITER ;

-- ===== 4. VIN PARA LOS VEHÍCULOS QUE AÚN NO TIENEN =====

-- Última serie de VIN usada hasta ahora
SET @karma_serie := (SELECT COALESCE(MAX(CAST(RIGHT(vin, 6) AS UNSIGNED)), 100000) FROM productos WHERE vin IS NOT NULL AND vin <> '');

-- Asigna un VIN nuevo (serie +37 cada uno) a cada auto/moto sin VIN, en orden de id
UPDATE productos
   SET vin = karma_armar_vin(marca, anio, (@karma_serie := @karma_serie + 37))
 WHERE tipo IN ('auto', 'moto') AND (vin IS NULL OR vin = '')
 ORDER BY id_producto;

-- ===== 5. ACABADO (COLOR) DE LAS REFACCIONES PARA LA VISTA 3D =====

-- Color real de cada tipo de pieza; solo se llena donde todavía no hay color
UPDATE productos
   SET color = CASE
           WHEN nombre LIKE '%Disco%'        THEN 'Acero gris'
           WHEN nombre LIKE '%pastillas%'    THEN 'Negro grafito'
           WHEN nombre LIKE '%Balata%'       THEN 'Negro grafito'
           WHEN nombre LIKE '%aceite%'       THEN 'Blanco'
           WHEN nombre LIKE '%aire%'         THEN 'Blanco hueso'
           WHEN nombre LIKE '%Bater%'        THEN 'Negro'
           WHEN nombre LIKE '%buj%'          THEN 'Plata'
           WHEN nombre LIKE '%distribuci%'   THEN 'Negro'
           WHEN nombre LIKE '%Bomba%'        THEN 'Aluminio'
           WHEN nombre LIKE '%Cadena%'       THEN 'Dorado'
           WHEN nombre LIKE '%Maneta%'       THEN 'Negro anodizado'
           WHEN nombre LIKE '%Espejo%'       THEN 'Negro mate'
           ELSE 'Acero'
       END,
       color_hex = CASE
           WHEN nombre LIKE '%Disco%'        THEN '#8C9096'
           WHEN nombre LIKE '%pastillas%'    THEN '#2E2F33'
           WHEN nombre LIKE '%Balata%'       THEN '#2E2F33'
           WHEN nombre LIKE '%aceite%'       THEN '#E6E6E2'
           WHEN nombre LIKE '%aire%'         THEN '#E8E4D8'
           WHEN nombre LIKE '%Bater%'        THEN '#1C1C1E'
           WHEN nombre LIKE '%buj%'          THEN '#BFC3C7'
           WHEN nombre LIKE '%distribuci%'   THEN '#202124'
           WHEN nombre LIKE '%Bomba%'        THEN '#A9ADB2'
           WHEN nombre LIKE '%Cadena%'       THEN '#B8923A'
           WHEN nombre LIKE '%Maneta%'       THEN '#2A2B2F'
           WHEN nombre LIKE '%Espejo%'       THEN '#1A1A1A'
           ELSE '#9A9DA1'
       END
 WHERE tipo = 'refaccion' AND (color_hex IS NULL OR color_hex = '');

-- ===== 6. MODELOS 3D REALES (.glb en assets/Modelos_3D) =====

-- Porsche 911 Carrera 2025 (id 2) — "2022 Porsche 911 GT3 Touring (992)" por Ddiaz Design, CC BY-NC-SA 4.0
UPDATE productos SET modelo_3d = 'assets/Modelos_3D/id2_KRM-P911-25_porsche911Carrera_2025_Negro Jeweled.glb' WHERE codigo_barras = 'KRM-P911-25';
-- Audi R8 2025 (id 25) — "2019 Audi R8 V10 Performance Quattro" por Ddiaz Design, CC BY-NC-SA 4.0
UPDATE productos SET modelo_3d = 'assets/Modelos_3D/id25_KRM-CAT-AUDI-15_audiR8_2025_AzulUltra.glb' WHERE codigo_barras = 'KRM-CAT-AUDI-15';
-- Ducati Panigale V2 2025 (id 41) — "2021 Ducati Panigale V4 SP" por Carlito, CC BY 4.0
UPDATE productos SET modelo_3d = 'assets/Modelos_3D/id41_KRM-CAT-DUC-01_DucatiPanigaleV2_2025_Gris Antracita.glb' WHERE codigo_barras = 'KRM-CAT-DUC-01';
-- Balata delantera Audi RS7 (id 10) — "Balata_3af92511c849988dda3f" por anaelsa2007mx, CC BY 4.0
UPDATE productos SET modelo_3d = 'assets/Modelos_3D/idproducto10_idcategoria4_KRM-REF-BALATA-AUDI_balataDelanteraParaAudiRS7_2024_Negro grafito_refaccion.glb' WHERE codigo_barras = 'KRM-REF-BALATA-AUDI';

-- ===== 7. VERIFICACIÓN (opcional, solo muestra resultados) =====

-- Vehículos que siguen sin VIN (debe salir 0)
SELECT COUNT(*) AS vehiculos_sin_vin FROM productos WHERE tipo IN ('auto', 'moto') AND (vin IS NULL OR vin = '');

-- Ejemplo de alta SIN código de barras ni VIN (quítale los guiones "-- " para probarlo):
-- INSERT INTO productos (id_categoria, nombre, precio_base, marca, modelo, anio, tipo, color, color_hex)
-- SELECT id_categoria, 'Q4 e-tron 2026', 1250000, 'Audi', 'Q4 e-tron', 2026, 'auto', 'Gris Nardo', '#7A7D80' FROM categorias WHERE nombre_categoria = 'Audi';
