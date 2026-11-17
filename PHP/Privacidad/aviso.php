<?php
declare(strict_types=1);

/* KARMA · Aviso de privacidad integral para empleados (página pública).
   El correo de bienvenida enlaza aquí con ?t=<token>: al abrirla, el aviso de ese empleado queda «revisado» en el panel
   de administrador. Sin token se muestra igual (apartado «Aviso de privacidad» del sistema). */
require_once dirname(__DIR__) . '/PuntoDeVenta/conexion.php';
require_once dirname(__DIR__) . '/Login/sesion_pos.php';
require_once __DIR__ . '/avisos.php';

header('Cache-Control: no-store');
header('Referrer-Policy: no-referrer');

$empleado = null;
$token = (string)($_GET['t'] ?? '');
if ($token !== '') {
    try { $empleado = avisoMarcarRevisado(db(), $token); } catch (Throwable $e) { error_log('[Aviso] ' . $e->getMessage()); }
}
$nombre = $empleado ? trim($empleado['nombre'] . ' ' . ($empleado['apellidos'] ?? '')) : '';
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex">
<meta name="titulo-es" content="Aviso de privacidad para empleados — KARMA">
<meta name="titulo-en" content="Employee privacy notice — KARMA">
<title>Aviso de privacidad para empleados — KARMA</title>
<link rel="icon" type="image/png" href="../../assets/favicon-karma.png?v=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,500&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../../CSS/Cuenta/cuenta.css?v=1">
</head>
<body>
<script>try { if (localStorage.getItem("karma_tema") === "dark") document.body.classList.add("dark"); } catch (_) {}</script>

<header class="cuenta-topbar">
  <a class="cuenta-brand" href="../../index.html"><img src="../../assets/logo-karma.png" alt=""><span>KARMA</span></a>
  <div class="cuenta-acciones">
    <button class="cuenta-chip" id="idiomaToggle" type="button" aria-label="Cambiar idioma / Change language">
      <span class="lang-op is-active" data-lang="es">ES</span><span>/</span><span class="lang-op" data-lang="en">EN</span>
    </button>
    <button class="cuenta-chip" id="temaToggle" type="button" aria-label="Modo claro u oscuro / Light or dark mode"><span data-icono-tema>☀</span></button>
  </div>
</header>

<main class="cuenta-main cuenta-main--ancho aviso-doc">

<!-- ===================== ESPAÑOL ===================== -->
<section data-idioma-bloque="es">
  <p class="cuenta-eyebrow">KARMA POS</p>
  <h1 class="cuenta-titulo">Aviso de privacidad integral para empleados</h1>
  <?php if ($empleado): ?>
    <p class="cuenta-alerta cuenta-alerta--ok">Hola, <?= h($nombre) ?>. Gracias por revisar el aviso de privacidad: quedó registrado que lo recibiste. No necesitas hacer nada más.</p>
  <?php endif; ?>
  <p>Este aviso explica qué datos personales tratamos de nuestro personal, para qué los usamos y cómo puedes ejercer tus derechos. Cumple con la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP), publicada en el Diario Oficial de la Federación el 20 de marzo de 2025, y con su normativa aplicable.</p>

  <h2>I. Identidad y domicilio del responsable</h2>
  <p><strong>Grupo Automotriz Karma, S.A. de C.V.</strong> («KARMA»), RFC GAK190312KM4, es una agencia de automóviles y motocicletas de lujo con sucursales en Manzanillo y Colima. Es la responsable del tratamiento de tus datos personales.</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Dato</th><th>Información</th></tr>
    <tr><td>Domicilio</td><td>Av. Miguel de la Madrid Hurtado No. 100, Col. Salahua, C.P. 28869, Manzanillo, Colima, México</td></tr>
    <tr><td>Área responsable</td><td>Departamento de Protección de Datos Personales</td></tr>
    <tr><td>Correo electrónico</td><td>privacidad@karma-automotriz.mx</td></tr>
    <tr><td>Teléfono</td><td>314 000 0000, ext. 105</td></tr>
    <tr><td>Horario de atención</td><td>Lunes a viernes, 9:00 a 17:00 h</td></tr>
  </table></div>

  <h2>II. Encargado del sistema</h2>
  <p><strong>DevCorp Soluciones Tecnológicas, S.A. de C.V.</strong> («DevCorp»), con domicilio en Av. Constitución No. 2050, Col. Lomas de Circunvalación, C.P. 28010, Colima, Colima, desarrolló el sistema KARMA POS y se encarga de alojarlo y mantenerlo. DevCorp <strong>no es dueña de la agencia ni tu empleador</strong>: trata tus datos solo por cuenta de KARMA, siguiendo sus instrucciones y con las obligaciones de confidencialidad y seguridad de un contrato. No puede usarlos para fines propios.</p>

  <h2>III. Datos personales que tratamos</h2>
  <p>Recabamos tus datos directamente de ti al contratarte, de los documentos que entregas y del uso que haces del sistema KARMA POS.</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Categoría</th><th>Datos</th></tr>
    <tr><td>Identificación</td><td>Nombre, apellidos, fecha de nacimiento, sexo, nacionalidad, CURP, RFC, número de seguridad social (NSS), copia de identificación oficial, fotografía y firma</td></tr>
    <tr><td>Contacto</td><td>Domicilio, teléfono, correo electrónico (también es tu usuario de acceso al sistema) y comprobante de domicilio</td></tr>
    <tr><td>Laborales y académicos</td><td>Currículum, escolaridad, experiencia y referencias laborales, puesto o rol, sucursal asignada, fecha de ingreso, código de empleado (EMP-0000) y gafete con código QR</td></tr>
    <tr><td>Patrimoniales y financieros</td><td>Salario y prestaciones, banco, cuenta y CLABE para el pago de nómina, y número de crédito INFONAVIT o FONACOT, si lo tienes</td></tr>
    <tr><td>Acceso al sistema</td><td>Contraseña (guardada solo como huella cifrada con bcrypt; nadie, ni KARMA ni DevCorp, puede verla), idioma preferido y estado de tu cuenta (activa o inactiva)</td></tr>
    <tr><td>Uso del sistema</td><td>Inicios de sesión e intentos fallidos; cada uso de tu gafete (fecha, hora, acción, sucursal, si se escaneó o se escribió, y resultado), y las ventas, créditos, abonos, garantías y pedidos web que registres</td></tr>
    <tr><td>Terceros</td><td>Nombre, parentesco y teléfono de tu contacto de emergencia</td></tr>
  </table></div>
  <p><strong>Datos sensibles.</strong> No recabamos datos sensibles: ni de salud, ni biométricos, ni antecedentes penales, ni de religión, afiliación sindical u opiniones políticas.</p>
  <p><strong>Datos de terceros.</strong> Si nos das los datos de tu contacto de emergencia, te comprometes a informarle de este aviso. Solo los usaremos para localizarlo en caso de emergencia.</p>

  <h2>IV. Finalidades del tratamiento</h2>
  <p>Tus datos se usarán para estas <strong>finalidades primarias</strong>, necesarias para la relación laboral:</p>
  <ol>
    <li>Integrar y actualizar tu expediente laboral.</li>
    <li>Crear tu cuenta en KARMA POS, asignarte un rol y una sucursal, y darte acceso al sistema.</li>
    <li>Emitir tu gafete y tu código de empleado, y verificar tu identidad cuando autorices ventas, créditos, abonos, garantías y pedidos web.</li>
    <li>Registrar y auditar las operaciones que realices, para controlar la caja, el inventario y aclarar diferencias.</li>
    <li>Proteger el sistema: bloquear el acceso tras varios intentos fallidos, detectar usos indebidos y responder a incidentes.</li>
    <li>Enviarte avisos relacionados con tu cuenta y tu trabajo, como este aviso y los cambios de contraseña.</li>
    <li>Pagar tu nómina y tus prestaciones.</li>
    <li>Cumplir las obligaciones laborales, fiscales y de seguridad social, como las altas en el IMSS, las retenciones y la emisión de los CFDI de nómina.</li>
    <li>Atender los requerimientos de autoridades y defender los derechos de KARMA en procedimientos legales.</li>
  </ol>
  <p><strong>Finalidades secundarias.</strong> No tratamos tus datos para finalidades secundarias como publicidad, mercadotecnia o prospección comercial. Si en el futuro queremos hacerlo, primero actualizaremos este aviso y te pediremos tu consentimiento.</p>

  <h2>V. Remisiones a encargados</h2>
  <p>Estos proveedores tratan tus datos solo por cuenta de KARMA y no pueden usarlos para fines propios:</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Encargado</th><th>Servicio</th><th>Ubicación</th></tr>
    <tr><td>DevCorp Soluciones Tecnológicas, S.A. de C.V.</td><td>Desarrollo, alojamiento y mantenimiento de KARMA POS</td><td>México</td></tr>
    <tr><td>Brevo (Sendinblue SAS)</td><td>Envío de correos del sistema (avisos y tickets)</td><td>Francia, Unión Europea</td></tr>
    <tr><td>Proveedor de alojamiento contratado por DevCorp</td><td>Servidores y base de datos</td><td>México</td></tr>
    <tr><td>Despacho contable externo</td><td>Cálculo de nómina y timbrado de CFDI</td><td>México</td></tr>
  </table></div>
  <p>El envío a Brevo es una remisión internacional. Brevo está sujeta al Reglamento General de Protección de Datos de la Unión Europea y solo recibe tu nombre y tu correo electrónico.</p>

  <h2>VI. Transferencias de datos</h2>
  <p>Tus datos pueden transferirse a estos destinatarios. Como todas estas transferencias son obligaciones legales o necesarias para la relación laboral, <strong>no requieren tu consentimiento</strong>:</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Destinatario</th><th>Finalidad</th></tr>
    <tr><td>IMSS, INFONAVIT y FONACOT</td><td>Alta, bajas, cuotas y descuentos de seguridad social y créditos</td></tr>
    <tr><td>Servicio de Administración Tributaria (SAT)</td><td>Retenciones y CFDI de nómina</td></tr>
    <tr><td>Secretaría del Trabajo y Previsión Social y tribunales laborales</td><td>Inspecciones, conflictos y procedimientos laborales</td></tr>
    <tr><td>Autoridades judiciales y ministeriales</td><td>Cumplir órdenes o requerimientos fundados y motivados</td></tr>
    <tr><td>Institución bancaria que paga la nómina</td><td>Depositar tu salario y prestaciones</td></tr>
  </table></div>
  <p>KARMA no vende, renta ni comparte tus datos con las marcas que distribuye ni con otras empresas.</p>

  <h2>VII. Consentimiento</h2>
  <p>La mayor parte del tratamiento es necesaria para cumplir la relación laboral y obligaciones legales, por lo que la ley no exige tu consentimiento para ello. Para lo demás, si después de recibir este aviso no te opones, se entenderá que <strong>consientes tácitamente</strong> el tratamiento de tus datos en estos términos.</p>

  <h2>VIII. Medios para ejercer los derechos ARCO</h2>
  <p>Tienes derecho a:</p>
  <ul>
    <li><strong>Acceso:</strong> saber qué datos tenemos de ti y cómo los usamos.</li>
    <li><strong>Rectificación:</strong> corregirlos si son inexactos o están incompletos.</li>
    <li><strong>Cancelación:</strong> pedir que los eliminemos de nuestros registros.</li>
    <li><strong>Oposición:</strong> oponerte a su uso para fines específicos.</li>
  </ul>
  <p><strong>Cómo presentar tu solicitud.</strong> Envíala a privacidad@karma-automotriz.mx o entrégala en el domicilio del Departamento de Protección de Datos Personales. Puedes usar el formato del Anexo A. La solicitud debe incluir:</p>
  <ol>
    <li>Tu nombre completo y un correo o domicilio para recibir la respuesta.</li>
    <li>Copia de tu identificación oficial vigente (INE, pasaporte o cédula profesional). Si actúas por medio de un representante, este debe presentar su identificación y una carta poder firmada ante dos testigos o un poder notarial.</li>
    <li>El derecho que ejerces y una descripción clara de los datos involucrados.</li>
    <li>Cualquier documento que ayude a localizar tus datos. Para una rectificación, adjunta el documento que respalde el cambio.</li>
  </ol>
  <h3>Plazos</h3>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Etapa</th><th>Plazo</th></tr>
    <tr><td>Si falta información, te la pediremos</td><td>5 días hábiles desde que recibamos tu solicitud</td></tr>
    <tr><td>Para entregar lo que falta</td><td>10 días hábiles; si no respondes, la solicitud se tendrá por no presentada</td></tr>
    <tr><td>Respuesta a tu solicitud</td><td>20 días hábiles desde que la recibamos completa</td></tr>
    <tr><td>Hacer efectiva la respuesta, si procede</td><td>15 días hábiles desde que te demos la respuesta</td></tr>
  </table></div>
  <p>Los plazos de respuesta y de ejecución pueden ampliarse una sola vez por un periodo igual, cuando el caso lo justifique y te avisemos. El trámite es <strong>gratuito</strong>; solo podrían cobrarse los costos justificados de envío o copias certificadas.</p>
  <p><strong>Límites.</strong> Podemos negar la cancelación o la oposición cuando debamos conservar los datos por una obligación legal, por un juicio en curso o para cumplir la relación laboral. Si la negamos, te explicaremos el motivo y su fundamento.</p>

  <h2>IX. Revocación del consentimiento</h2>
  <p>Puedes revocar tu consentimiento en cualquier momento con el mismo procedimiento de los derechos ARCO. La revocación no procede respecto de los datos necesarios para la relación laboral o para cumplir obligaciones legales mientras estas sigan vigentes.</p>

  <h2>X. Opciones para limitar el uso o la divulgación</h2>
  <p>Como no tratamos tus datos para finalidades secundarias, no necesitas inscribirte en ninguna lista de exclusión. Si quieres limitar algún uso o divulgación en particular, preséntalo como solicitud de oposición.</p>

  <h2>XI. Cookies y tecnologías similares</h2>
  <p>KARMA POS usa una cookie de sesión (<code>KARMAPOS</code>) que mantiene tu sesión abierta y se borra al cerrarla. También guarda en tu navegador tu tema (claro u oscuro), tu idioma y los datos básicos de tu sesión para mostrarte la pantalla correcta. El correo con este aviso incluye una imagen mínima que solo registra que lo abriste. No usamos cookies de publicidad ni de rastreo de terceros. Puedes borrar estos datos desde la configuración de tu navegador, aunque tendrás que volver a iniciar sesión.</p>

  <h2>XII. Conservación y medidas de seguridad</h2>
  <p><strong>Conservación.</strong> Conservamos tus datos durante la relación laboral y hasta <strong>5 años</strong> después de que termine, para cumplir los plazos de las obligaciones laborales, fiscales y de seguridad social. Al darte de baja, tu cuenta queda <strong>inactiva</strong> y ya no da acceso al sistema. Después de los 5 años, tus datos se bloquean y se eliminan de forma segura.</p>
  <p><strong>Seguridad.</strong> Protegemos tus datos con medidas administrativas, técnicas y físicas:</p>
  <ul>
    <li>Las contraseñas se guardan cifradas con bcrypt.</li>
    <li>El acceso al sistema se controla por rol y sucursal.</li>
    <li>Tras 5 intentos fallidos de inicio de sesión o de gafete, el acceso se bloquea durante 60 segundos.</li>
    <li>Las autorizaciones con gafete son de un solo uso, vencen a los 60 segundos y quedan registradas.</li>
    <li>Solo el personal autorizado tiene acceso al expediente laboral.</li>
  </ul>
  <p>Si ocurre una vulneración de seguridad que afecte de forma significativa tus derechos, te avisaremos sin demora para que puedas protegerte.</p>

  <h2>XIII. Cambios al aviso de privacidad</h2>
  <p>Este aviso puede cambiar por reformas legales, cambios en nuestros procesos o nuevas funciones del sistema. Te avisaremos de cualquier cambio por correo electrónico y en el sistema KARMA POS, indicando la nueva fecha de actualización.</p>

  <h2>XIV. Autoridad</h2>
  <p>Si crees que se vulneró tu derecho a la protección de datos personales, o no estás conforme con nuestra respuesta, puedes acudir a la <strong>Secretaría Anticorrupción y Buen Gobierno</strong>, que es la autoridad competente según la LFPDPPP, e iniciar un procedimiento de protección de derechos.</p>

  <h2>Anexo A — Formato de solicitud de derechos ARCO</h2>
  <p>Envía a privacidad@karma-automotriz.mx, o entrega en el Departamento de Protección de Datos Personales, una solicitud con estos datos:</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Sección</th><th>Contenido</th></tr>
    <tr><td>Fecha de la solicitud</td><td>Día, mes y año</td></tr>
    <tr><td>Datos del titular</td><td>Nombre completo, código de empleado (EMP-0000), sucursal, correo o domicilio para recibir la respuesta y teléfono</td></tr>
    <tr><td>Representante (solo si aplica)</td><td>Nombre completo del representante y documento que acredita la representación</td></tr>
    <tr><td>Derecho que deseas ejercer</td><td>Acceso, rectificación, cancelación, oposición o revocación del consentimiento</td></tr>
    <tr><td>Descripción de la solicitud</td><td>Los datos involucrados y lo que pides (en una rectificación, el dato correcto; en una oposición, la finalidad a la que te opones)</td></tr>
    <tr><td>Documentos que adjuntas</td><td>Copia de identificación oficial vigente, identificación y poder del representante, documento que respalda la rectificación u otros</td></tr>
    <tr><td>Firma</td><td>Del titular o de su representante</td></tr>
  </table></div>
  <p><strong>Fecha de última actualización:</strong> 20 de octubre de 2026.</p>
</section>

<!-- ===================== ENGLISH ===================== -->
<section data-idioma-bloque="en" hidden>
  <p class="cuenta-eyebrow">KARMA POS</p>
  <h1 class="cuenta-titulo">Comprehensive employee privacy notice</h1>
  <?php if ($empleado): ?>
    <p class="cuenta-alerta cuenta-alerta--ok">Hello, <?= h($nombre) ?>. Thank you for reviewing the privacy notice: we recorded that you received it. You don't need to do anything else.</p>
  <?php endif; ?>
  <p class="aviso-nota">English translation for reference. The Spanish version prevails in case of discrepancy.</p>
  <p>This notice explains what personal data we process about our staff, what we use it for and how you can exercise your rights. It complies with Mexico's Federal Law on the Protection of Personal Data Held by Private Parties (LFPDPPP), published in the Official Gazette of the Federation on March 20, 2025, and its applicable regulations.</p>

  <h2>I. Identity and address of the data controller</h2>
  <p><strong>Grupo Automotriz Karma, S.A. de C.V.</strong> ("KARMA"), RFC GAK190312KM4, is a luxury car and motorcycle dealership with branches in Manzanillo and Colima. It is responsible for processing your personal data.</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Item</th><th>Details</th></tr>
    <tr><td>Address</td><td>Av. Miguel de la Madrid Hurtado No. 100, Col. Salahua, C.P. 28869, Manzanillo, Colima, Mexico</td></tr>
    <tr><td>Responsible department</td><td>Personal Data Protection Department</td></tr>
    <tr><td>Email</td><td>privacidad@karma-automotriz.mx</td></tr>
    <tr><td>Phone</td><td>+52 314 000 0000, ext. 105</td></tr>
    <tr><td>Office hours</td><td>Monday to Friday, 9:00 a.m. to 5:00 p.m.</td></tr>
  </table></div>

  <h2>II. System processor</h2>
  <p><strong>DevCorp Soluciones Tecnológicas, S.A. de C.V.</strong> ("DevCorp"), located at Av. Constitución No. 2050, Col. Lomas de Circunvalación, C.P. 28010, Colima, Colima, developed the KARMA POS system and hosts and maintains it. DevCorp <strong>does not own the dealership and is not your employer</strong>: it processes your data only on KARMA's behalf, following its instructions and bound by contractual confidentiality and security obligations. It may not use your data for its own purposes.</p>

  <h2>III. Personal data we process</h2>
  <p>We collect your data directly from you when you are hired, from the documents you provide and from your use of the KARMA POS system.</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Category</th><th>Data</th></tr>
    <tr><td>Identification</td><td>First name, last names, date of birth, sex, nationality, CURP, RFC, social security number (NSS), copy of official ID, photograph and signature</td></tr>
    <tr><td>Contact</td><td>Address, phone number, email address (also your system username) and proof of address</td></tr>
    <tr><td>Employment and education</td><td>Résumé, education, work experience and references, position or role, assigned branch, start date, employee code (EMP-0000) and QR-code badge</td></tr>
    <tr><td>Financial</td><td>Salary and benefits, bank, account number and CLABE for payroll, and INFONAVIT or FONACOT loan number, if any</td></tr>
    <tr><td>System access</td><td>Password (stored only as a bcrypt hash; no one, neither KARMA nor DevCorp, can see it), preferred language and account status (active or inactive)</td></tr>
    <tr><td>System use</td><td>Logins and failed attempts; every use of your badge (date, time, action, branch, whether it was scanned or typed, and result), and the sales, credits, payments, warranties and web orders you process</td></tr>
    <tr><td>Third parties</td><td>Name, relationship and phone number of your emergency contact</td></tr>
  </table></div>
  <p><strong>Sensitive data.</strong> We do not collect sensitive data: no health, biometric or criminal record data, and no data on religion, union membership or political opinions.</p>
  <p><strong>Third-party data.</strong> If you give us your emergency contact's details, you agree to inform that person of this notice. We will only use them to reach that person in an emergency.</p>

  <h2>IV. Purposes of processing</h2>
  <p>Your data will be used for these <strong>primary purposes</strong>, which are necessary for the employment relationship:</p>
  <ol>
    <li>Building and updating your employee file.</li>
    <li>Creating your KARMA POS account, assigning you a role and a branch, and giving you access to the system.</li>
    <li>Issuing your badge and employee code, and verifying your identity when you authorize sales, credits, payments, warranties and web orders.</li>
    <li>Recording and auditing the transactions you process, to control cash, inventory and resolve discrepancies.</li>
    <li>Protecting the system: blocking access after several failed attempts, detecting misuse and responding to incidents.</li>
    <li>Sending you notices about your account and your work, such as this notice and password changes.</li>
    <li>Paying your wages and benefits.</li>
    <li>Meeting labor, tax and social security obligations, such as IMSS registration, withholdings and payroll CFDI invoices.</li>
    <li>Responding to requests from authorities and defending KARMA's rights in legal proceedings.</li>
  </ol>
  <p><strong>Secondary purposes.</strong> We do not process your data for secondary purposes such as advertising, marketing or commercial prospecting. If we wish to do so in the future, we will first update this notice and ask for your consent.</p>

  <h2>V. Disclosures to processors</h2>
  <p>These providers process your data only on KARMA's behalf and may not use it for their own purposes:</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Processor</th><th>Service</th><th>Location</th></tr>
    <tr><td>DevCorp Soluciones Tecnológicas, S.A. de C.V.</td><td>Development, hosting and maintenance of KARMA POS</td><td>Mexico</td></tr>
    <tr><td>Brevo (Sendinblue SAS)</td><td>System emails (notices and receipts)</td><td>France, European Union</td></tr>
    <tr><td>Hosting provider hired by DevCorp</td><td>Servers and database</td><td>Mexico</td></tr>
    <tr><td>External accounting firm</td><td>Payroll calculation and CFDI stamping</td><td>Mexico</td></tr>
  </table></div>
  <p>The disclosure to Brevo is an international one. Brevo is subject to the EU General Data Protection Regulation and only receives your name and email address.</p>

  <h2>VI. Data transfers</h2>
  <p>Your data may be transferred to these recipients. Because all of these transfers are legal obligations or necessary for the employment relationship, <strong>they do not require your consent</strong>:</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Recipient</th><th>Purpose</th></tr>
    <tr><td>IMSS, INFONAVIT and FONACOT</td><td>Registration, termination, contributions and loan deductions</td></tr>
    <tr><td>Tax Administration Service (SAT)</td><td>Withholdings and payroll CFDI invoices</td></tr>
    <tr><td>Ministry of Labor and Social Welfare and labor courts</td><td>Inspections, disputes and labor proceedings</td></tr>
    <tr><td>Judicial and prosecutorial authorities</td><td>Complying with substantiated orders or requests</td></tr>
    <tr><td>Bank that pays the payroll</td><td>Depositing your wages and benefits</td></tr>
  </table></div>
  <p>KARMA does not sell, rent or share your data with the brands it sells or with other companies.</p>

  <h2>VII. Consent</h2>
  <p>Most processing is necessary to fulfill the employment relationship and legal obligations, so the law does not require your consent for it. For anything else, if you do not object after receiving this notice, you will be deemed to have given <strong>tacit consent</strong> to the processing of your data on these terms.</p>

  <h2>VIII. How to exercise your ARCO rights</h2>
  <p>You have the right to:</p>
  <ul>
    <li><strong>Access:</strong> know what data we hold about you and how we use it.</li>
    <li><strong>Rectification:</strong> correct it if it is inaccurate or incomplete.</li>
    <li><strong>Cancellation:</strong> ask us to delete it from our records.</li>
    <li><strong>Objection:</strong> object to its use for specific purposes.</li>
  </ul>
  <p><strong>How to submit your request.</strong> Send it to privacidad@karma-automotriz.mx or deliver it to the Personal Data Protection Department. You can use the form in Annex A. The request must include:</p>
  <ol>
    <li>Your full name and an email or address to receive the response.</li>
    <li>A copy of your valid official ID (INE voter card, passport or professional license). If you act through a representative, that person must present their ID and a power of attorney signed before two witnesses, or a notarized power of attorney.</li>
    <li>The right you are exercising and a clear description of the data involved.</li>
    <li>Any document that helps locate your data. For a rectification, attach the document that supports the change.</li>
  </ol>
  <h3>Deadlines</h3>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Stage</th><th>Deadline</th></tr>
    <tr><td>If information is missing, we will ask for it</td><td>5 business days after we receive your request</td></tr>
    <tr><td>To provide what is missing</td><td>10 business days; otherwise, the request is considered not submitted</td></tr>
    <tr><td>Response to your request</td><td>20 business days after we receive it complete</td></tr>
    <tr><td>Carrying out the response, if granted</td><td>15 business days after we respond</td></tr>
  </table></div>
  <p>The response and execution deadlines may be extended once, for an equal period, when justified and notified to you. The process is <strong>free of charge</strong>; only justified shipping or certified copy costs may apply.</p>
  <p><strong>Limits.</strong> We may deny cancellation or objection when we must keep the data due to a legal obligation, an ongoing legal proceeding or to fulfill the employment relationship. If we deny it, we will explain the reason and its legal basis.</p>

  <h2>IX. Withdrawal of consent</h2>
  <p>You may withdraw your consent at any time using the same procedure as for ARCO rights. Withdrawal does not apply to data needed for the employment relationship or to meet legal obligations while those remain in force.</p>

  <h2>X. Options to limit use or disclosure</h2>
  <p>Since we do not process your data for secondary purposes, you do not need to join any opt-out list. If you want to limit a specific use or disclosure, submit it as an objection request.</p>

  <h2>XI. Cookies and similar technologies</h2>
  <p>KARMA POS uses a session cookie (<code>KARMAPOS</code>) that keeps you logged in and is deleted when you log out. It also stores your theme (light or dark), your language and basic session data in your browser to show you the right screen. The email with this notice includes a tiny image that only records that you opened it. We do not use advertising or third-party tracking cookies. You can delete this data in your browser settings, but you will need to log in again.</p>

  <h2>XII. Retention and security measures</h2>
  <p><strong>Retention.</strong> We keep your data during the employment relationship and for up to <strong>5 years</strong> after it ends, to meet the deadlines of labor, tax and social security obligations. When you leave, your account becomes <strong>inactive</strong> and no longer grants access to the system. After 5 years, your data is blocked and securely deleted.</p>
  <p><strong>Security.</strong> We protect your data with administrative, technical and physical measures:</p>
  <ul>
    <li>Passwords are stored as bcrypt hashes.</li>
    <li>System access is controlled by role and branch.</li>
    <li>After 5 failed login or badge attempts, access is blocked for 60 seconds.</li>
    <li>Badge authorizations are single-use, expire after 60 seconds and are logged.</li>
    <li>Only authorized staff can access employee files.</li>
  </ul>
  <p>If a security breach significantly affects your rights, we will notify you without delay so you can protect yourself.</p>

  <h2>XIII. Changes to this privacy notice</h2>
  <p>This notice may change due to legal reforms, changes in our processes or new system features. We will inform you of any change by email and in KARMA POS, stating the new update date.</p>

  <h2>XIV. Authority</h2>
  <p>If you believe your right to personal data protection has been violated, or you disagree with our response, you may turn to the <strong>Secretaría Anticorrupción y Buen Gobierno</strong> (Anti-Corruption and Good Governance Ministry), the competent authority under the LFPDPPP, and start a rights protection procedure.</p>

  <h2>Annex A — ARCO rights request form</h2>
  <p>Send to privacidad@karma-automotriz.mx, or deliver to the Personal Data Protection Department, a request with this information:</p>
  <div class="aviso-tabla-wrap"><table class="aviso-tabla">
    <tr><th>Section</th><th>Content</th></tr>
    <tr><td>Request date</td><td>Day, month and year</td></tr>
    <tr><td>Data subject</td><td>Full name, employee code (EMP-0000), branch, email or address to receive the response, and phone</td></tr>
    <tr><td>Representative (only if applicable)</td><td>Representative's full name and document proving representation</td></tr>
    <tr><td>Right you wish to exercise</td><td>Access, rectification, cancellation, objection or withdrawal of consent</td></tr>
    <tr><td>Description of the request</td><td>The data involved and what you are asking for (for a rectification, the correct data; for an objection, the purpose you object to)</td></tr>
    <tr><td>Attached documents</td><td>Copy of valid official ID, representative's ID and power of attorney, document supporting the rectification, or others</td></tr>
    <tr><td>Signature</td><td>Of the data subject or representative</td></tr>
  </table></div>
  <p><strong>Last updated:</strong> October 20, 2026.</p>
</section>

  <p class="cuenta-pie">Grupo Automotriz Karma, S.A. de C.V. · KARMA POS</p>
</main>

<script src="../../JavaScript/Cuenta/preferencias.js?v=1"></script>
</body>
</html>
