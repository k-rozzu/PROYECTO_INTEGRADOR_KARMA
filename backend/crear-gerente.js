const bcrypt = require("bcrypt");
const pool = require("./db");

async function crearGerente() {
    const nombre    = process.argv[2];
    const correo    = process.argv[3];
    const password  = process.argv[4];
    const sucursal  = process.argv[5]; // id_sucursal (número)

    if (!nombre || !correo || !password) {
        console.log(
            'Uso: node backend/crear-gerente.js "Nombre" "correo" "contraseña" [id_sucursal]'
        );
        process.exit(1);
    }

    try {
        // Buscar el rol Gerente
        const [roles] = await pool.query(
            "SELECT id_rol FROM roles WHERE nombre_rol = ?",
            ["Gerente"]
        );

        if (roles.length === 0) {
            console.log("No existe el rol 'Gerente' en la base de datos.");
            return;
        }

        // Verificar que el correo no esté registrado
        const [existente] = await pool.query(
            "SELECT id_usuario FROM usuarios WHERE correo = ?",
            [correo]
        );

        if (existente.length > 0) {
            console.log("Ya existe un usuario con ese correo.");
            return;
        }

        // Verificar sucursal si se proporcionó
        if (sucursal) {
            const [suc] = await pool.query(
                "SELECT id_sucursal FROM sucursales WHERE id_sucursal = ?",
                [parseInt(sucursal)]
            );
            if (suc.length === 0) {
                console.log(`No existe una sucursal con id ${sucursal}.`);
                return;
            }
        }

        const passwordHash = await bcrypt.hash(password, 10);

        await pool.query(
            `INSERT INTO usuarios (id_rol, id_sucursal, nombre, correo, password_hash)
             VALUES (?, ?, ?, ?, ?)`,
            [
                roles[0].id_rol,
                sucursal ? parseInt(sucursal) : null,
                nombre,
                correo,
                passwordHash
            ]
        );

        console.log(`Gerente "${nombre}" creado correctamente.`);
        if (sucursal) {
            console.log(`Asignado a la sucursal con id ${sucursal}.`);
        } else {
            console.log("Sin sucursal asignada (puedes asignarla después desde el panel de administrador).");
        }

    } catch (error) {
        console.error("Error al crear el gerente:");
        console.error(error.message);
    } finally {
        await pool.end();
    }
}

crearGerente();
