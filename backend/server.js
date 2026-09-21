const express = require("express");
const bcrypt = require("bcrypt");
const path = require("path");
const pool = require("./db");

const app = express();

app.use(express.json());
app.use(express.static(path.join(__dirname, "..")));

app.get("/api/prueba", (req, res) => {
    res.json({
        mensaje: "El backend está funcionando"
    });
});

app.get("/api/usuarios", async (req, res) => {
    try {
        const [usuarios] = await pool.query(
            "SELECT id_usuario, nombre, correo, estado FROM usuarios"
        );

        res.json(usuarios);

    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: "Error al consultar los usuarios"
        });
    }
});

app.post("/api/login", async (req, res) => {

    const { correo, password } = req.body;

    if (!correo || !password) {
        return res.status(400).json({
            mensaje: "Correo y contraseña son obligatorios"
        });
    }

    try {

        const [usuarios] = await pool.query(
            `SELECT 
                u.id_usuario,
                u.nombre,
                u.correo,
                u.password_hash,
                u.estado,
                r.nombre_rol
            FROM usuarios u
            INNER JOIN roles r ON u.id_rol = r.id_rol
            WHERE u.correo = ?`,
            [correo]
        );

        if (usuarios.length === 0) {
            return res.status(401).json({
                mensaje: "Credenciales incorrectas"
            });
        }

        const usuario = usuarios[0];

        if (usuario.estado !== "activo") {
            return res.status(403).json({
                mensaje: "El usuario está inactivo"
            });
        }

        const passwordCorrecta = await bcrypt.compare(
            password,
            usuario.password_hash
        );

        if (!passwordCorrecta) {
            return res.status(401).json({
                mensaje: "Credenciales incorrectas"
            });
        }

        res.json({
            mensaje: "Inicio de sesión correcto",
            usuario: {
                id: usuario.id_usuario,
                nombre: usuario.nombre,
                correo: usuario.correo,
                rol: usuario.nombre_rol
            }
        });

    } catch (error) {

        console.error(error);

        res.status(500).json({
            mensaje: "Error interno del servidor"
        });
    }
});

const PORT = 3000;

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});