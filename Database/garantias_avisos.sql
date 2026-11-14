-- KARMA · Aviso al cajero cuando el gerente ACEPTA su solicitud de garantía.
-- Importar DESPUÉS de garantias.sql (o de pos_multisede.sql, que ya trae solicitudes_garantia). Se puede ejecutar varias veces.
--
--   * solicitudes_garantia.fecha_aviso_cajero: NULL = el cajero que envió la solicitud todavía no ve el aviso de que fue
--     aceptada; al dar «Enterado» en el Punto de Venta se guarda la fecha y hora y el aviso deja de mostrarse.
--   * Quién acepta o deniega (panel de gerente → PHP/Dashboard/garantias_gerente.php) lo siguen validando los triggers de garantias.sql.

SET NAMES utf8mb4;

ALTER TABLE solicitudes_garantia
    ADD COLUMN IF NOT EXISTS `fecha_aviso_cajero` datetime NULL DEFAULT NULL
        COMMENT 'Cuándo vio el cajero el aviso de garantía aceptada (NULL = aviso pendiente)' AFTER `fecha_resolucion`;
