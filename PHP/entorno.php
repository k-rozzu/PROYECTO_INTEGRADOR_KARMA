<?php
declare(strict_types=1);

/* Lector de configuración compartido: claves de las APIs guardadas en el archivo .env de la raíz del proyecto */

// Devuelve el valor de una clave: primero la busca en el sistema (getenv) y, si no está, en el archivo .env
function karmaEnv(string $clave, string $defecto = ''): string {
    // Guarda el contenido del .env para leer el archivo una sola vez por petición
    static $valores = null;
    $delSistema = getenv($clave);
    if ($delSistema !== false && $delSistema !== '') return $delSistema;
    if ($valores === null) $valores = karmaLeerArchivoEnv(dirname(__DIR__) . '/.env');
    return $valores[$clave] ?? $defecto;
}

// Convierte las líneas CLAVE=valor del .env en un arreglo (ignora líneas vacías y comentarios con #)
function karmaLeerArchivoEnv(string $ruta): array {
    $valores = [];
    if (!is_readable($ruta)) return $valores;
    foreach (file($ruta, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $linea) {
        $linea = trim($linea);
        if ($linea === '' || str_starts_with($linea, '#') || !str_contains($linea, '=')) continue;
        [$nombre, $valor] = explode('=', $linea, 2);
        $valores[trim($nombre)] = trim(trim($valor), "\"'");
    }
    return $valores;
}
