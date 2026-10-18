<?php
declare(strict_types=1);

/* Productos para las tarjetas del Home (equivalente a GET /api/productos de backend/server.js, para correr en XAMPP) */
header('Content-Type: application/json; charset=utf-8');
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';

try {
    $productos = db()->query(
        "SELECT id_producto, marca, modelo, motor, cilindraje, detalle, imagen_path FROM productos"
    )->fetchAll();
    echo json_encode($productos, JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['mensaje' => 'Error al consultar los productos'], JSON_UNESCAPED_UNICODE);
}
