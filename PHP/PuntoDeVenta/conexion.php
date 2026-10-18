<?php
declare(strict_types=1);

// Zona horaria del proyecto (sucursales de Manzanillo y Colima). El php.ini de XAMPP trae Europe/Berlin (8 horas adelante),
// por eso se fija aquí: este archivo lo cargan el Punto de Venta, el login y el Catálogo
const KARMA_ZONA_HORARIA = 'America/Mexico_City';
date_default_timezone_set(KARMA_ZONA_HORARIA);

/* Conexión PDO a MySQL */
function db(): PDO {
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $host = getenv('KARMA_DB_HOST') ?: '127.0.0.1';
    $name = getenv('KARMA_DB_NAME') ?: 'pos_multisede';
    $user = getenv('KARMA_DB_USER') ?: 'root';
    $pass = getenv('KARMA_DB_PASS') ?: '';

    $dsn = "mysql:host={$host};dbname={$name};charset=utf8mb4";

    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);

    // MySQL trabaja con la misma zona que PHP: NOW() y ventas.fecha_hora dan la hora de la sucursal aunque el servidor tenga otra
    $pdo->exec("SET time_zone = '" . (new DateTimeImmutable('now'))->format('P') . "'");

    return $pdo;
}
?>
