const express = require("express");
const bcrypt = require("bcrypt");
const path = require("path");
const pool = require("./db");

const app = express();

app.use(express.json());

// El panel de gerente se abre desde Apache (otro origen): solo se admiten páginas del mismo equipo que atiende este servidor
app.use((req, res, next) => {
    const origen = req.headers.origin;
    let mismoEquipo = false;
    try {
        mismoEquipo = Boolean(origen) && new URL(origen).hostname === req.hostname;
    } catch (error) {
        mismoEquipo = false;
    }

    if (mismoEquipo) {
        res.setHeader("Access-Control-Allow-Origin", origen);
        res.setHeader("Vary", "Origin");
        res.setHeader("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    }

    if (req.method === "OPTIONS") {
        return res.sendStatus(204);
    }
    next();
});

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

        // Igual que PHP/Login/login.php: un usuario insertado a mano con SQL puede tener la contraseña en texto plano
        const guardado = String(usuario.password_hash || "");
        const esHash = /^\$(2[abxy]\$\d\d\$|argon2id?\$)/.test(guardado);
        const passwordCorrecta = esHash
            ? await bcrypt.compare(password, guardado)
            : guardado !== "" && guardado === String(password);

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
             WHERE i.id_sucursal = ? AND i.estado = 'activo'`,
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
             WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'`,
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
            "SELECT 1 FROM inventarios WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'",
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

//Marca un producto como inactivo en la sucursal (no se borra nada)
app.delete("/api/gerente/productos/:id", async (req, res) => {
    try {
        const idProducto = Number(req.params.id);
        const idSucursal = Number(req.query.sucursal);

        if (!Number.isInteger(idProducto) || !Number.isInteger(idSucursal)) {
            return res.status(400).json({ mensaje: "Datos inválidos" });
        }

        const [resultado] = await pool.query(
            `UPDATE inventarios
             SET estado = 'inactivo'
             WHERE id_producto = ? AND id_sucursal = ? AND estado = 'activo'`,
            [idProducto, idSucursal]
        );

        if (resultado.affectedRows === 0) {
            return res.status(404).json({ mensaje: "Producto no encontrado en esta sucursal" });
        }

        res.json({ mensaje: "Producto desactivado" });

    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al desactivar el producto" });
    }
});

//Devuelve las ventas de la sucursal del gerente (una fila por producto vendido)
app.get("/api/gerente/ventas", async (req, res) => {
    try {
        const sucursal = Number(req.query.sucursal);

        if (!Number.isInteger(sucursal)) {
            return res.status(400).json({ mensaje: "Sucursal inválida" });
        }

        const [ventas] = await pool.query(
            `SELECT CONCAT('V', v.id_venta, '-', d.id_detalle) AS id,
                    v.fecha_hora AS fecha,
                    u.id_usuario AS cajeroId,
                    u.nombre AS cajeroNombre,
                    p.id_producto AS productoId,
                    p.nombre AS productoNombre,
                    p.marca,
                    d.subtotal_linea AS total,
                    d.cantidad,
                    CASE
                        WHEN m.nombre_metodo = 'Efectivo' THEN 'efectivo'
                        WHEN m.nombre_metodo LIKE 'Tarjeta%' THEN 'tarjeta'
                        WHEN m.nombre_metodo = 'Transferencia' THEN 'transferencia'
                        ELSE LOWER(m.nombre_metodo)
                    END AS metodoPago
             FROM ventas v
             JOIN detalle_ventas d ON d.id_venta = v.id_venta
             JOIN productos p ON p.id_producto = d.id_producto
             JOIN usuarios u ON u.id_usuario = v.id_usuario
             JOIN metodos_pago m ON m.id_metodo_pago = v.id_metodo_pago
             WHERE v.id_sucursal = ?
               AND v.fecha_hora >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 5 MONTH)
             ORDER BY v.fecha_hora DESC`,
            [sucursal]
        );

        res.json(ventas);

    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al consultar las ventas" });
    }
});

//Datos de la sucursal del gerente
app.get("/api/gerente/sucursal", async (req, res) => {
    try {
        const sucursal = Number(req.query.sucursal);
        if (!Number.isInteger(sucursal)) {
            return res.status(400).json({ mensaje: "Sucursal inválida" });
        }

        const [filas] = await pool.query(
            "SELECT id_sucursal AS id, nombre, direccion, telefono, estado FROM sucursales WHERE id_sucursal = ?",
            [sucursal]
        );
        if (filas.length === 0) {
            return res.status(404).json({ mensaje: "Sucursal no encontrada" });
        }

        res.json(filas[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al consultar la sucursal" });
    }
});

//Cajeros de la sucursal del gerente
app.get("/api/gerente/cajeros", async (req, res) => {
    try {
        const sucursal = Number(req.query.sucursal);
        if (!Number.isInteger(sucursal)) {
            return res.status(400).json({ mensaje: "Sucursal inválida" });
        }

        const [cajeros] = await pool.query(
            `SELECT u.id_usuario AS id, u.nombre, u.correo, u.estado
             FROM usuarios u
             JOIN roles r ON r.id_rol = u.id_rol
             WHERE r.nombre_rol = 'Cajero' AND u.id_sucursal = ?`,
            [sucursal]
        );

        res.json(cajeros);
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al consultar los cajeros" });
    }
});

//Revisa que el cajero sea válido para la sucursal y no tenga ya otra caja. Devuelve el mensaje de error, o null si todo está bien
async function validarCajero(idCajero, idSucursal, idCajaActual) {
    const [cajero] = await pool.query(
        `SELECT 1
         FROM usuarios u
         JOIN roles r ON r.id_rol = u.id_rol
         WHERE u.id_usuario = ? AND u.id_sucursal = ? AND r.nombre_rol = 'Cajero' AND u.estado = 'activo'`,
        [idCajero, idSucursal]
    );
    if (cajero.length === 0) {
        return "El cajero no pertenece a esta sucursal o está inactivo";
    }

    const [otra] = await pool.query(
        "SELECT numero_caja FROM cajas WHERE id_usuario_asignado = ? AND id_caja <> ?",
        [idCajero, idCajaActual]
    );
    if (otra.length > 0) {
        return `Ese cajero ya está asignado a la Caja ${otra[0].numero_caja}`;
    }

    return null;
}

//Cajas de la sucursal, con su cajero asignado
app.get("/api/gerente/cajas", async (req, res) => {
    try {
        const sucursal = Number(req.query.sucursal);
        if (!Number.isInteger(sucursal)) {
            return res.status(400).json({ mensaje: "Sucursal inválida" });
        }

        const [cajas] = await pool.query(
            `SELECT c.id_caja AS id,
                    CONCAT('Caja ', c.numero_caja) AS nombre,
                    CASE WHEN c.estado = 'mantenimiento' THEN 'inactivo' ELSE 'activo' END AS estado,
                    c.id_usuario_asignado AS cajeroId
             FROM cajas c
             WHERE c.id_sucursal = ?
             ORDER BY c.numero_caja`,
            [sucursal]
        );

        res.json(cajas);
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al consultar las cajas" });
    }
});

//Crea una caja nueva en la sucursal (queda cerrada), con cajero opcional
app.post("/api/gerente/cajas", async (req, res) => {
    try {
        const numero = Number(req.body.numero);
        const sucursal = Number(req.body.sucursal);
        const cajeroId = (req.body.cajeroId === null || req.body.cajeroId === undefined || req.body.cajeroId === "")
            ? null
            : Number(req.body.cajeroId);

        if (!Number.isInteger(numero) || numero < 1 || !Number.isInteger(sucursal)) {
            return res.status(400).json({ mensaje: "El número de caja debe ser un entero mayor a 0" });
        }
        if (cajeroId !== null && !Number.isInteger(cajeroId)) {
            return res.status(400).json({ mensaje: "Cajero inválido" });
        }

        const [existe] = await pool.query(
            "SELECT 1 FROM cajas WHERE id_sucursal = ? AND numero_caja = ?",
            [sucursal, numero]
        );
        if (existe.length > 0) {
            return res.status(409).json({ mensaje: `Ya existe la Caja ${numero} en esta sucursal` });
        }

        if (cajeroId !== null) {
            const error = await validarCajero(cajeroId, sucursal, 0);
            if (error) return res.status(409).json({ mensaje: error });
        }

        const [resultado] = await pool.query(
            "INSERT INTO cajas (id_sucursal, numero_caja, id_usuario_asignado) VALUES (?, ?, ?)",
            [sucursal, numero, cajeroId]
        );

        res.status(201).json({ id: resultado.insertId });
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al crear la caja" });
    }
});

//Activa o desactiva una caja (desactivar = mantenimiento)
app.patch("/api/gerente/cajas/:id/estado", async (req, res) => {
    try {
        const idCaja = Number(req.params.id);
        const sucursal = Number(req.body.sucursal);
        const estado = req.body.estado;

        if (!Number.isInteger(idCaja) || !Number.isInteger(sucursal) || !["activo", "inactivo"].includes(estado)) {
            return res.status(400).json({ mensaje: "Datos inválidos" });
        }

        const [filas] = await pool.query(
            "SELECT estado FROM cajas WHERE id_caja = ? AND id_sucursal = ?",
            [idCaja, sucursal]
        );
        if (filas.length === 0) {
            return res.status(404).json({ mensaje: "Caja no encontrada en esta sucursal" });
        }

        const actual = filas[0].estado;

        if (estado === "inactivo") {
            if (actual === "abierta") {
                return res.status(409).json({ mensaje: "La caja está abierta. Pide que la cierren antes de desactivarla." });
            }
            await pool.query(
                "UPDATE cajas SET estado = 'mantenimiento' WHERE id_caja = ? AND id_sucursal = ?",
                [idCaja, sucursal]
            );
        } else if (actual === "mantenimiento") {
            await pool.query(
                "UPDATE cajas SET estado = 'cerrada' WHERE id_caja = ? AND id_sucursal = ?",
                [idCaja, sucursal]
            );
        }

        res.json({ mensaje: "Estado actualizado" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al actualizar la caja" });
    }
});

//Asigna (o quita) el cajero de una caja
app.patch("/api/gerente/cajas/:id/cajero", async (req, res) => {
    try {
        const idCaja = Number(req.params.id);
        const sucursal = Number(req.body.sucursal);
        const cajeroId = (req.body.cajeroId === null || req.body.cajeroId === undefined || req.body.cajeroId === "")
            ? null
            : Number(req.body.cajeroId);

        if (!Number.isInteger(idCaja) || !Number.isInteger(sucursal) || (cajeroId !== null && !Number.isInteger(cajeroId))) {
            return res.status(400).json({ mensaje: "Datos inválidos" });
        }

        const [caja] = await pool.query(
            "SELECT 1 FROM cajas WHERE id_caja = ? AND id_sucursal = ?",
            [idCaja, sucursal]
        );
        if (caja.length === 0) {
            return res.status(404).json({ mensaje: "Caja no encontrada en esta sucursal" });
        }

        if (cajeroId !== null) {
            const error = await validarCajero(cajeroId, sucursal, idCaja);
            if (error) return res.status(409).json({ mensaje: error });
        }

        await pool.query(
            "UPDATE cajas SET id_usuario_asignado = ? WHERE id_caja = ? AND id_sucursal = ?",
            [cajeroId, idCaja, sucursal]
        );

        res.json({ mensaje: "Cajero asignado" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: "Error al asignar el cajero" });
    }
});

//El puerto en el que se va a ejecturar el servidor:
const PORT = 3000;

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});