<?php
declare(strict_types=1);

/* API DE TRADUCCIÓN: recibe textos en JSON, los traduce con DeepL (o Google) y guarda cada traducción en caché */
header('Content-Type: application/json; charset=utf-8');
require_once dirname(__DIR__) . '/entorno.php';

// Idiomas que acepta el traductor (se pueden agregar más, ej. 'fr', 'de')
const TRAD_IDIOMAS = ['es', 'en'];
// Máximo de textos por petición (DeepL acepta hasta 50)
const TRAD_MAX_TEXTOS = 50;
// Máximo de caracteres por texto y por petición completa
const TRAD_MAX_CARACTERES = 5000;
const TRAD_MAX_TOTAL = 60000;
// Carpeta donde se guardan las traducciones ya hechas (ahorra cuota y responde al instante)
const TRAD_CARPETA_CACHE = __DIR__ . '/cache';

// Responde en JSON con su código HTTP y termina
function tradResponder(array $datos, int $estado = 200): never {
    http_response_code($estado);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit;
}

// Solo acepta peticiones hechas desde este mismo sitio (evita que otras páginas gasten tu cuota)
function tradValidarOrigen(): void {
    $origen = $_SERVER['HTTP_ORIGIN'] ?? $_SERVER['HTTP_REFERER'] ?? '';
    $partes = parse_url($origen);
    $hostOrigen = ($partes['host'] ?? '') . (isset($partes['port']) ? ':' . $partes['port'] : '');
    $hostServidor = $_SERVER['HTTP_HOST'] ?? '';
    if ($hostOrigen === '' || strcasecmp($hostOrigen, $hostServidor) !== 0) {
        tradResponder(['ok' => false, 'error' => 'Origen no permitido.'], 403);
    }
}

// Ruta del archivo de caché para un par de idiomas (ej. cache/es_en.json)
function tradRutaCache(string $origen, string $destino): string {
    return TRAD_CARPETA_CACHE . "/{$origen}_{$destino}.json";
}

// Lee la caché de traducciones { "texto original": "traducción" }
function tradLeerCache(string $origen, string $destino): array {
    $ruta = tradRutaCache($origen, $destino);
    if (!is_file($ruta)) return [];
    $datos = json_decode((string)file_get_contents($ruta), true);
    return is_array($datos) ? $datos : [];
}

// Agrega traducciones nuevas a la caché con bloqueo de archivo (seguro si hay varias cajas a la vez)
function tradGuardarCache(string $origen, string $destino, array $nuevas): void {
    if (!is_dir(TRAD_CARPETA_CACHE)) {
        mkdir(TRAD_CARPETA_CACHE, 0775, true);
        file_put_contents(TRAD_CARPETA_CACHE . '/.htaccess', "Require all denied\n");
    }
    $archivo = fopen(tradRutaCache($origen, $destino), 'c+');
    if (!$archivo) return;
    flock($archivo, LOCK_EX);
    $actual = json_decode((string)stream_get_contents($archivo), true);
    $actual = $nuevas + (is_array($actual) ? $actual : []);
    ftruncate($archivo, 0);
    rewind($archivo);
    fwrite($archivo, json_encode($actual, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT | JSON_FORCE_OBJECT));
    fflush($archivo);
    flock($archivo, LOCK_UN);
    fclose($archivo);
}

// Hace un POST HTTPS con cuerpo JSON y regresa la respuesta decodificada (lanza error si falla)
function tradPost(string $url, array $encabezados, array $cuerpo): array {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_HTTPHEADER => $encabezados,
        CURLOPT_POSTFIELDS => json_encode($cuerpo, JSON_UNESCAPED_UNICODE)
    ]);
    $respuesta = curl_exec($ch);
    $http = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $errorRed = curl_error($ch);
    curl_close($ch);

    if ($respuesta === false) throw new RuntimeException('Sin conexión con el servicio de traducción: ' . $errorRed);
    $datos = json_decode((string)$respuesta, true) ?: [];
    if ($http === 401 || $http === 403) throw new RuntimeException('La clave de la API de traducción no es válida; revisa el archivo .env.');
    if ($http === 456) throw new RuntimeException('Se agotó la cuota mensual de traducción.');
    if ($http < 200 || $http >= 300) {
        $detalle = $datos['message'] ?? ($datos['error']['message'] ?? ('código HTTP ' . $http));
        throw new RuntimeException('El servicio de traducción respondió: ' . $detalle);
    }
    return $datos;
}

// API DEEPL: traduce una lista de textos (plan Free o Pro según la clave) y respeta el orden
function tradDeepL(array $textos, string $origen, string $destino): array {
    $clave = karmaEnv('DEEPL_API_KEY');
    if ($clave === '') throw new RuntimeException('Falta DEEPL_API_KEY en el archivo .env (ver explicacion_api.txt).');
    // Las claves gratuitas terminan en ":fx" y usan otro servidor
    $url = str_ends_with($clave, ':fx') ? 'https://api-free.deepl.com/v2/translate' : 'https://api.deepl.com/v2/translate';
    // DeepL pide variante de inglés: EN-US
    $destinoDeepL = $destino === 'en' ? 'EN-US' : strtoupper($destino);
    $datos = tradPost($url, ['Authorization: DeepL-Auth-Key ' . $clave, 'Content-Type: application/json'], [
        'text' => $textos,
        'source_lang' => strtoupper($origen),
        'target_lang' => $destinoDeepL,
        'preserve_formatting' => true
    ]);
    return array_map(fn($t) => (string)($t['text'] ?? ''), $datos['translations'] ?? []);
}

// API GOOGLE CLOUD TRANSLATION (v2): alternativa si se configura TRADUCTOR_PROVEEDOR=google
function tradGoogle(array $textos, string $origen, string $destino): array {
    $clave = karmaEnv('GOOGLE_TRANSLATE_API_KEY');
    if ($clave === '') throw new RuntimeException('Falta GOOGLE_TRANSLATE_API_KEY en el archivo .env.');
    $url = 'https://translation.googleapis.com/language/translate/v2?key=' . urlencode($clave);
    $datos = tradPost($url, ['Content-Type: application/json'], [
        'q' => $textos,
        'source' => $origen,
        'target' => $destino,
        'format' => 'text'
    ]);
    return array_map(fn($t) => html_entity_decode((string)($t['translatedText'] ?? ''), ENT_QUOTES | ENT_HTML5, 'UTF-8'), $datos['data']['translations'] ?? []);
}

// Elige el proveedor configurado en .env y traduce
function tradTraducirConProveedor(array $textos, string $origen, string $destino): array {
    $proveedor = strtolower(karmaEnv('TRADUCTOR_PROVEEDOR', 'deepl'));
    $traducidos = $proveedor === 'google'
        ? tradGoogle($textos, $origen, $destino)
        : tradDeepL($textos, $origen, $destino);
    if (count($traducidos) !== count($textos)) throw new RuntimeException('El servicio regresó un número distinto de traducciones.');
    return $traducidos;
}

// Flujo principal: valida la petición, usa la caché y solo manda a la API lo que falta
try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') tradResponder(['ok' => false, 'error' => 'Usa POST.'], 405);
    tradValidarOrigen();

    // Lee y valida el cuerpo { textos: [...], origen: "es", destino: "en" }
    $entrada = json_decode((string)file_get_contents('php://input'), true);
    if (!is_array($entrada) || !is_array($entrada['textos'] ?? null)) tradResponder(['ok' => false, 'error' => 'Formato inválido.'], 400);
    $origen = strtolower((string)($entrada['origen'] ?? 'es'));
    $destino = strtolower((string)($entrada['destino'] ?? 'en'));
    if (!in_array($origen, TRAD_IDIOMAS, true) || !in_array($destino, TRAD_IDIOMAS, true) || $origen === $destino) {
        tradResponder(['ok' => false, 'error' => 'Par de idiomas no permitido.'], 400);
    }
    $textos = array_map(fn($t) => (string)$t, array_values($entrada['textos']));
    if (count($textos) > TRAD_MAX_TEXTOS) tradResponder(['ok' => false, 'error' => 'Demasiados textos en una sola petición.'], 413);
    $total = 0;
    foreach ($textos as $t) {
        if (mb_strlen($t) > TRAD_MAX_CARACTERES) tradResponder(['ok' => false, 'error' => 'Uno de los textos es demasiado largo.'], 413);
        $total += mb_strlen($t);
    }
    if ($total > TRAD_MAX_TOTAL) tradResponder(['ok' => false, 'error' => 'La petición es demasiado grande.'], 413);

    // Busca en caché y junta solo los textos que nunca se han traducido
    $cache = tradLeerCache($origen, $destino);
    $faltantes = array_values(array_unique(array_filter($textos, fn($t) => trim($t) !== '' && !array_key_exists($t, $cache))));

    // Traduce lo que falta y lo guarda para la próxima vez
    if ($faltantes) {
        $traducidos = tradTraducirConProveedor($faltantes, $origen, $destino);
        $nuevas = array_combine($faltantes, $traducidos);
        tradGuardarCache($origen, $destino, $nuevas);
        $cache = $nuevas + $cache;
    }

    // Respuesta en el mismo orden en que llegaron los textos
    tradResponder(['ok' => true, 'traducciones' => array_map(fn($t) => $cache[$t] ?? $t, $textos)]);
} catch (Throwable $e) {
    tradResponder(['ok' => false, 'error' => $e->getMessage()], 502);
}
