const bcrypt = require("bcrypt");
const pool = require("./db");

async function crearAdministrador() {
    const nombre = process.argv[2];
    const correo = process.argv[3];
    const password = process.argv[4];

    if (!nombre || !correo || !password) {
        console.log(
            'Uso: node backend/crear-admin.js "Nombre" "correo" "contraseña"'
        );
        process.exit(1);
    }

    try {
        // Buscar el rol de Administrador General
        const [roles] = await pool.query(
            "SELECT id_rol FROM roles WHERE nombre_rol = ?",
            ["Admin_General"]
        );

        if (roles.length === 0) {
            console.log("No existe el rol Admin_General en la base de datos.");
            return;
        }

        // Comprobar que el correo no esté registrado
        const [usuarios] = await pool.query(
            "SELECT id_usuario FROM usuarios WHERE correo = ?",
            [correo]
        );

        if (usuarios.length > 0) {
            console.log("Ya existe un usuario con ese correo.");
            return;
        }

        // Convertir la contraseña en un hash
        const passwordHash = await bcrypt.hash(password, 10);

        // Crear el administrador
        await pool.query(
            `INSERT INTO usuarios
                (id_rol, id_sucursal, nombre, correo, password_hash)
             VALUES (?, NULL, ?, ?, ?)`,
            [
                roles[0].id_rol,
                nombre,
                correo,
                passwordHash
            ]
        );

        console.log("Administrador creado correctamente.");

    } catch (error) {
        console.error("Error al crear el administrador:");
        console.error(error.message);

    } finally {
        await pool.end();
    }
}

crearAdministrador();