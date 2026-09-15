const pool = require("./db");

async function probarConexion() {
    try {
        const [resultado] = await pool.query(
            "SELECT DATABASE() AS base_datos"
        );

        console.log("Conexión exitosa a MySQL");
        console.log("Base de datos:", resultado[0].base_datos);

    } catch (error) {
        console.error("Error al conectar con MySQL:");
        console.error(error.message);

    } finally {
        await pool.end();
    }
}

probarConexion();