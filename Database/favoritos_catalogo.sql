-- KARMA · Renombra la tabla clientes_favoritos a favoritos_catalogo.
-- Guarda los vehículos de interés que cada cliente marca con el corazón en el Catálogo web; el nombre anterior
-- se leía como "los clientes favoritos de KARMA".
-- RENAME TABLE conserva las filas, la llave primaria y las llaves foráneas (fk_favoritos_clientes, fk_favoritos_productos).
-- Para bases creadas antes del cambio. Se puede ejecutar varias veces: solo renombra si la tabla vieja existe
-- y la nueva todavía no.

USE pos_multisede;

SET @renombrar = (SELECT IF(
    EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'clientes_favoritos')
    AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favoritos_catalogo'),
    "RENAME TABLE clientes_favoritos TO favoritos_catalogo;",
    "SELECT 'Nada que renombrar: la base no tiene clientes_favoritos o ya tiene favoritos_catalogo';"
));
PREPARE stmt FROM @renombrar;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
