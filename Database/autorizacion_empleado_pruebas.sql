-- KARMA · Datos de PRUEBA de la autorización de empleado (gafete QR / código). Opcional: solo para repetir las pruebas.
-- Agrega 3 usuarios nuevos (no toca a los existentes) y se puede ejecutar varias veces sin duplicar nada.
-- Su codigo_empleado lo asigna el trigger auto_codigo_empleado (EMP-000X). Detalle y contraseña: docs/AUTORIZACION_EMPLEADO.md
--   * Cajero Prueba QR           -> Cajero, Manzanillo, activo (inicia sesión en el POS para las pruebas)
--   * Gerente Prueba QR          -> Gerente, activo: su gafete debe ser RECHAZADO en la sesión de un cajero
--   * Cajero Prueba QR Inactivo  -> Cajero, inactivo: su gafete debe ser RECHAZADO
-- El gerente y el inactivo tienen contraseñas aleatorias que nadie conoce: solo existen como dueños de un código.

INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash, idioma_pref, estado)
SELECT r.id_rol, s.id_sucursal, 'Cajero Prueba QR', 'cajero.qr@karma.local',
       '$2y$12$wsPtHl8g5LMv6plaMo7owe3pcYxkqxwjis7/tDVS3QnDdgnJOkipm', 'es', 'activo'
FROM roles r JOIN sucursales s ON s.nombre = 'Manzanillo'
WHERE r.nombre_rol = 'Cajero' AND NOT EXISTS (SELECT 1 FROM usuarios WHERE correo = 'cajero.qr@karma.local');

INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash, idioma_pref, estado)
SELECT r.id_rol, s.id_sucursal, 'Gerente Prueba QR', 'gerente.qr@karma.local',
       '$2y$12$19YSbu6g5IcuzYETfw0a4uY1svHQlzLAjKCRuLa55Ro0VCIZN2Fne', 'es', 'activo'
FROM roles r JOIN sucursales s ON s.nombre = 'Manzanillo'
WHERE r.nombre_rol = 'Gerente' AND NOT EXISTS (SELECT 1 FROM usuarios WHERE correo = 'gerente.qr@karma.local');

INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash, idioma_pref, estado)
SELECT r.id_rol, s.id_sucursal, 'Cajero Prueba QR Inactivo', 'inactivo.qr@karma.local',
       '$2y$12$wLW/QZeiMYhQQIh1kky.Ve9/88PYimfEwl/3aBMFqKKI.d2csrUQG', 'es', 'inactivo'
FROM roles r JOIN sucursales s ON s.nombre = 'Manzanillo'
WHERE r.nombre_rol = 'Cajero' AND NOT EXISTS (SELECT 1 FROM usuarios WHERE correo = 'inactivo.qr@karma.local');
