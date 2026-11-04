<?php
declare(strict_types=1);

/* Productos para las tarjetas del Home (equivalente a GET /api/productos de backend/server.js, para correr en XAMPP) */
header('Content-Type: application/json; charset=utf-8');
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';

try {
    $productos = db()->query(
        // La foto viene del catálogo (productos_web); vendidos y destacado sirven para elegir los "más vendidos"
        "SELECT p.id_producto, p.tipo, p.marca, p.modelo, p.motor, p.cilindraje, p.detalle,
                COALESCE(NULLIF(p.imagen_path, ''), CONCAT('/', NULLIF(pw.imagen, ''))) AS imagen_path,
                COALESCE(pw.destacado, 0) AS destacado, COALESCE(dv.vendidos, 0) AS vendidos
           FROM productos p
           LEFT JOIN productos_web pw ON pw.id_producto = p.id_producto AND pw.publicado = 1
           LEFT JOIN (SELECT id_producto, SUM(cantidad) AS vendidos FROM detalle_ventas GROUP BY id_producto) dv
                  ON dv.id_producto = p.id_producto
          ORDER BY p.id_producto"
    )->fetchAll();
    echo json_encode($productos, JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['mensaje' => 'Error al consultar los productos'], JSON_UNESCAPED_UNICODE);
}
