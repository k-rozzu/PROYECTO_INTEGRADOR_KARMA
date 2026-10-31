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
                u.id_sucursal,
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
                rol: usuario.nombre_rol,
                id_sucursal: usuario.id_sucursal
            }
        });

    } catch (error) {

        console.error(error);

        res.status(500).json({
            mensaje: "Error interno del servidor"
        });
    }
});

app.get("/api/productos", async (req, res) => {
    try {
        // Hacemos la consulta a la base de datos pidiendo los datos necesarios
        // Nota: Asegúrate de incluir 'imagen_path' que recién añadiste
        const [productos] = await pool.query(
            "SELECT id_producto, marca, modelo, motor, cilindraje, detalle, imagen_path FROM productos"
        );

        res.json(productos);

    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: "Error al consultar los productos"
        });
    }
});

//Esta sección consulta los productos a la base de datos para la interfaz de gerente
app.get("/api/gerente/productos", async (req, res) => {
    try {
        const sucursal = req.query.sucursal;

        //Aqui se especifican los datos a consultar, en este caso la informacion de los productos de la sucursal del gerente que accede a la pagina
        const [productos] = await pool.query(
            `SELECT p.id_producto AS id,
                    p.nombre,
                    p.marca,
                    p.descripcion,
                    CASE p.tipo WHEN 'auto' THEN 'vehiculo' ELSE p.tipo END AS tipo,
                    c.nombre_categoria AS categoria,
                    p.precio_base AS precio,
                    i.stock_actual AS stockActual,
                    i.stock_minimo AS stockMinimo
             FROM inventarios i
             JOIN productos p ON p.id_producto = i.id_producto
             JOIN categorias c ON c.id_categoria = p.id_categoria
             WHERE i.id_sucursal = ?`,
            [sucursal]
        );

        // Devuelve el resultado en formato JSON
        res.json(productos);
    //Avisa si hay un error en la consulta y no muestra detalles del error por seguridad
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al consultar los productos" });
    }
});

//Actualiza el stock de un producto en la sucursal del gerente
app.patch("/api/gerente/inventario/:id/stock", async (req, res) => {
    try {
        const idProducto = Number(req.params.id);
        const stockActual = Number(req.body.stockActual);
        const sucursal = Number(req.body.sucursal);

        // El servidor valida los datos, no confía en lo que manda el navegador
        if (!Number.isInteger(idProducto) || !Number.isInteger(stockActual) || !Number.isInteger(sucursal)) {
            return res.status(400).json({ mensaje: "Datos inválidos" });
        }
        if (stockActual < 0) {
            return res.status(400).json({ mensaje: "El stock no puede ser negativo" });
        }

        const [resultado] = await pool.query(
            `UPDATE inventarios
             SET stock_actual = ?
             WHERE id_producto = ? AND id_sucursal = ?`,
            [stockActual, idProducto, sucursal]
        );

        if (resultado.affectedRows === 0) {
            return res.status(404).json({ mensaje: "Producto no encontrado en esta sucursal" });
        }

        res.json({ mensaje: "Stock actualizado" });

    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al actualizar el stock" });
    }
});

//Devuelve las categorías reales para llenar el selector del formulario
app.get("/api/gerente/categorias", async (req, res) => {
    try {
        const [categorias] = await pool.query(
            "SELECT id_categoria AS id, nombre_categoria AS nombre FROM categorias ORDER BY nombre_categoria"
        );
        res.json(categorias);
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al consultar las categorías" });
    }
}); 

//Crea un producto nuevo y su inventario en la sucursal del gerente
app.post("/api/gerente/productos", async (req, res) => {
    const { tipo, marca, nombre, idCategoria, precio, stockActual, stockMinimo, descripcion, sucursal } = req.body;

    // El formulario manda "vehiculo", pero la base guarda "auto"
    const tipoBD = { vehiculo: "auto", moto: "moto", refaccion: "refaccion" }[tipo];

    const idCat = Number(idCategoria);
    const precioNum = Number(precio);
    const stock = Number(stockActual);
    const minimo = Number(stockMinimo);
    const idSucursal = Number(sucursal);

    // Validaciones: el servidor no confía en lo que manda el navegador
    if (!tipoBD || !marca?.trim() || !nombre?.trim()) {
        return res.status(400).json({ mensaje: "Faltan datos del producto" });
    }
    if (!Number.isInteger(idCat) || !Number.isInteger(idSucursal)) {
        return res.status(400).json({ mensaje: "Categoría o sucursal inválida" });
    }
    if (!(precioNum > 0)) {
        return res.status(400).json({ mensaje: "El precio debe ser mayor a 0" });
    }
    if (!Number.isInteger(stock) || stock < 0 || !Number.isInteger(minimo) || minimo < 0) {
        return res.status(400).json({ mensaje: "El stock debe ser un entero de 0 o más" });
    }

    const conexion = await pool.getConnection();
    try {
        await conexion.beginTransaction();

        // codigo_barras es obligatorio y único, así que lo generamos
        const codigoBarras = `KRM-${tipoBD.toUpperCase()}-${Date.now()}`;

        const [producto] = await conexion.query(
            `INSERT INTO productos
                (id_categoria, codigo_barras, nombre, descripcion, precio_base, marca, modelo, tipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [idCat, codigoBarras, nombre.trim(), descripcion || null, precioNum, marca.trim(), nombre.trim(), tipoBD]
        );

        await conexion.query(
            `INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_minimo)
             VALUES (?, ?, ?, ?)`,
            [idSucursal, producto.insertId, stock, minimo]
        );

        await conexion.commit();
        res.status(201).json({ id: producto.insertId });

    } catch (error) {
        await conexion.rollback();
        console.error(error);
        res.status(500).json({ mensaje: "Error al crear el producto" });
    } finally {
        conexion.release();
    }
});

//Edita un producto y su inventario en la sucursal del gerente
app.patch("/api/gerente/productos/:id", async (req, res) => {
    const idProducto = Number(req.params.id);
    const { tipo, marca, nombre, idCategoria, precio, stockActual, stockMinimo, descripcion, sucursal } = req.body;

    const tipoBD = { vehiculo: "auto", moto: "moto", refaccion: "refaccion" }[tipo];

    const idCat = Number(idCategoria);
    const precioNum = Number(precio);
    const stock = Number(stockActual);
    const minimo = Number(stockMinimo);
    const idSucursal = Number(sucursal);

    // Validaciones
    if (!Number.isInteger(idProducto) || !Number.isInteger(idCat) || !Number.isInteger(idSucursal)) {
        return res.status(400).json({ mensaje: "Datos inválidos" });
    }
    if (!tipoBD || !marca?.trim() || !nombre?.trim()) {
        return res.status(400).json({ mensaje: "Faltan datos del producto" });
    }
    if (!(precioNum > 0)) {
        return res.status(400).json({ mensaje: "El precio debe ser mayor a 0" });
    }
    if (!Number.isInteger(stock) || stock < 0 || !Number.isInteger(minimo) || minimo < 0) {
        return res.status(400).json({ mensaje: "El stock debe ser un entero de 0 o más" });
    }

    const conexion = await pool.getConnection();
    try {
        await conexion.beginTransaction();

        // El producto debe existir en el inventario de esta sucursal
        const [existe] = await conexion.query(
            "SELECT 1 FROM inventarios WHERE id_producto = ? AND id_sucursal = ?",
            [idProducto, idSucursal]
        );
        if (existe.length === 0) {
            await conexion.rollback();
            return res.status(404).json({ mensaje: "Producto no encontrado en esta sucursal" });
        }

        await conexion.query(
            `UPDATE productos
             SET modelo = IF(modelo = nombre, ?, modelo),
                 nombre = ?,
                 marca = ?,
                 id_categoria = ?,
                 precio_base = ?,
                 tipo = ?,
                 descripcion = ?
             WHERE id_producto = ?`,
            [nombre.trim(), nombre.trim(), marca.trim(), idCat, precioNum, tipoBD, descripcion || null, idProducto]
        );

        await conexion.query(
            `UPDATE inventarios
             SET stock_actual = ?, stock_minimo = ?
             WHERE id_producto = ? AND id_sucursal = ?`,
            [stock, minimo, idProducto, idSucursal]
        );

        await conexion.commit();
        res.json({ mensaje: "Producto actualizado" });

    } catch (error) {
        await conexion.rollback();
        console.error(error);
        res.status(500).json({ mensaje: "Error al actualizar el producto" });
    } finally {
        conexion.release();
    }
});

//El puerto en el que se va a ejecturar el servidor:
const PORT = 3000;

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});