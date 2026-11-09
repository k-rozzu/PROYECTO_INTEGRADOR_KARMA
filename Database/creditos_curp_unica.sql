-- KARMA · Punto de Venta: una CURP / RFC solo puede pertenecer a un cliente en los créditos.
-- Guarda en cada contrato la CURP / RFC del acreditado para poder buscarla (y bloquearla al firmar) sin leer el JSON.
-- Se puede ejecutar varias veces sin riesgo. No borra ni cambia los contratos existentes: solo copia el dato que ya traen.

SET NAMES utf8mb4;

ALTER TABLE contratos_credito ADD COLUMN IF NOT EXISTS rfc_curp VARCHAR(20) NULL AFTER cliente_nombre;
ALTER TABLE contratos_credito ADD INDEX IF NOT EXISTS idx_contratos_rfc_curp (rfc_curp);

UPDATE contratos_credito
   SET rfc_curp = UPPER(REPLACE(JSON_UNQUOTE(JSON_EXTRACT(datos_json, '$.acreditado.rfc_curp')), ' ', ''))
 WHERE rfc_curp IS NULL
   AND JSON_VALID(datos_json)
   AND JSON_EXTRACT(datos_json, '$.acreditado.rfc_curp') IS NOT NULL;
