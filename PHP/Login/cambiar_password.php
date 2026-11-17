<?php
declare(strict_types=1);

/* KARMA · Pantalla para que cualquier usuario del sistema (Cajero, Gerente o Administrador) cambie su contraseña.
   Con ?forzado=1 (o si la cuenta todavía tiene la contraseña temporal del administrador) no se puede saltar. */
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';
require_once __DIR__ . '/sesion_pos.php';

header('Cache-Control: no-store');
$usuario = posUsuarioValidado(db());
if (!$usuario) {
    header('Location: ../../index.html');
    exit;
}
$forzado = posDebeCambiarPassword($usuario);
$csrf = posTokenCsrf();
$destino = $usuario['nombre_rol'] === 'Cajero' ? '../PuntoDeVenta/index.php' : '../../Home/home.html';
$e = fn($v) => htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex">
<meta name="karma-csrf" content="<?= $e($csrf) ?>">
<meta name="titulo-es" content="Cambiar contraseña — KARMA">
<meta name="titulo-en" content="Change password — KARMA">
<title>Cambiar contraseña — KARMA</title>
<link rel="icon" type="image/png" href="../../assets/favicon-karma.png?v=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,500&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../../CSS/Cuenta/cuenta.css?v=1">
</head>
<body data-destino="<?= $e($destino) ?>" data-forzado="<?= $forzado ? '1' : '0' ?>">
<script>try { if (localStorage.getItem("karma_tema") === "dark") document.body.classList.add("dark"); } catch (_) {}</script>

<header class="cuenta-topbar">
  <a class="cuenta-brand" href="<?= $e($destino) ?>" <?= $forzado ? 'aria-disabled="true" tabindex="-1" onclick="return false"' : '' ?>><img src="../../assets/logo-karma.png" alt=""><span>KARMA</span></a>
  <div class="cuenta-acciones">
    <button class="cuenta-chip" id="idiomaToggle" type="button" aria-label="Cambiar idioma / Change language">
      <span class="lang-op is-active" data-lang="es">ES</span><span>/</span><span class="lang-op" data-lang="en">EN</span>
    </button>
    <button class="cuenta-chip" id="temaToggle" type="button" aria-label="Modo claro u oscuro / Light or dark mode"><span data-icono-tema>☀</span></button>
    <button class="cuenta-chip" id="salirBtn" type="button" data-es="Cerrar sesión" data-en="Log out">Cerrar sesión</button>
  </div>
</header>

<main class="cuenta-main">
  <p class="cuenta-eyebrow" data-es="Tu cuenta" data-en="Your account">Tu cuenta</p>
  <h1 class="cuenta-titulo" data-es="Cambiar contraseña" data-en="Change password">Cambiar contraseña</h1>
  <?php if ($forzado): ?>
    <p class="cuenta-desc" data-es="Entraste con la contraseña temporal que te dio el administrador. Por seguridad, elige una contraseña propia para continuar."
       data-en="You signed in with the temporary password the administrator gave you. For security, choose your own password to continue.">Entraste con la contraseña temporal que te dio el administrador. Por seguridad, elige una contraseña propia para continuar.</p>
  <?php else: ?>
    <p class="cuenta-desc" data-es="Elige una contraseña que solo tú conozcas. Se aplica al Punto de Venta y a los paneles."
       data-en="Choose a password only you know. It applies to the Point of Sale and the panels.">Elige una contraseña que solo tú conozcas. Se aplica al Punto de Venta y a los paneles.</p>
  <?php endif; ?>

  <div class="cuenta-card">
    <p class="cuenta-alerta" id="alerta" role="alert" hidden></p>
    <form id="formPassword" novalidate>
      <div class="cuenta-campo">
        <label for="actual" data-es="<?= $forzado ? 'Contraseña temporal' : 'Contraseña actual' ?>" data-en="<?= $forzado ? 'Temporary password' : 'Current password' ?>"><?= $forzado ? 'Contraseña temporal' : 'Contraseña actual' ?></label>
        <input type="password" id="actual" autocomplete="current-password" required>
      </div>
      <div class="cuenta-campo">
        <label for="nueva" data-es="Contraseña nueva" data-en="New password">Contraseña nueva</label>
        <input type="password" id="nueva" autocomplete="new-password" minlength="8" maxlength="72" required>
      </div>
      <ul class="cuenta-reglas" id="reglas">
        <li data-regla="largo" data-es="Al menos 8 caracteres" data-en="At least 8 characters">Al menos 8 caracteres</li>
        <li data-regla="mezcla" data-es="Letras y números" data-en="Letters and numbers">Letras y números</li>
        <li data-regla="distinta" data-es="Distinta de la actual" data-en="Different from the current one">Distinta de la actual</li>
      </ul>
      <div class="cuenta-campo">
        <label for="confirmacion" data-es="Confirma la contraseña nueva" data-en="Confirm the new password">Confirma la contraseña nueva</label>
        <input type="password" id="confirmacion" autocomplete="new-password" maxlength="72" required>
      </div>
      <div class="cuenta-botones">
        <?php if (!$forzado): ?>
          <a class="cuenta-btn cuenta-btn--ghost" href="<?= $e($destino) ?>" id="volverBtn" data-es="Volver" data-en="Back">Volver</a>
        <?php endif; ?>
        <button class="cuenta-btn" type="submit" id="guardarBtn" data-es="Guardar contraseña" data-en="Save password">Guardar contraseña</button>
      </div>
    </form>
  </div>
  <p class="cuenta-pie"><a href="../Privacidad/aviso.php" data-es="Aviso de privacidad" data-en="Privacy notice">Aviso de privacidad</a></p>
</main>

<script src="../../JavaScript/Cuenta/preferencias.js?v=1"></script>
<script src="../../JavaScript/Cuenta/cambiar_password.js?v=1"></script>
</body>
</html>
