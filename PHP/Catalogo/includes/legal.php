<?php
declare(strict_types=1);

/* =====================================================================================
   KARMA · Catálogo — FUENTE ÚNICA del Aviso de Privacidad Integral y de los Términos y Condiciones.
   - privacidad.php y terminos.php muestran este contenido; documentos_legales.php y el correo de registro
     generan el PDF con este mismo contenido (nunca hay dos textos distintos).
   - Cada documento tiene versión y fecha de vigencia. Su huella SHA-256 se calcula sobre el contenido exacto:
     si cambias UNA coma, sube la versión (y la fecha). La base de datos guarda cada versión publicada
     (tabla documentos_legales) y rechaza el envío si una versión ya publicada cambió de texto.
   - Marcas usadas en el texto: <span class="pendiente">[...]</span> = dato que KARMA debe confirmar;
     <sup>*</sup> = dato ficticio creado solo para el proyecto académico.
   Fundamento verificado en los textos vigentes publicados por la Cámara de Diputados:
     LFPDPPP (DOF 20-03-2025, última reforma 14-11-2025): arts. 2, 7, 8, 9, 10, 15, 16, 18-20, 24, 25, 28, 29, 31, 33-36, 40.
     LFPC (última reforma DOF 12-12-2025): arts. 18, 18 bis, 56, 76 bis, 77, 78, 92.
     Código de Comercio art. 38 (10 años) y Código Fiscal de la Federación art. 30 (5 años).
   ===================================================================================== */

// Datos del responsable que se repiten en ambos documentos
const CAT_LEGAL_RAZON_SOCIAL = 'Karma Autos, S.A. de C.V.';
const CAT_LEGAL_RFC = 'KAU251020KR4';
const CAT_LEGAL_DOMICILIO = 'Av. Miguel de la Madrid Hurtado No. 100, Col. Salahua, C.P. 28869, Manzanillo, Colima, México';
const CAT_LEGAL_CORREO_DATOS = 'privacidad@karma-automotriz.mx';
// Texto EXACTO del botón de aceptación (correo, página de confirmación, aviso y PDF usan este mismo texto)
const CAT_BOTON_ACEPTAR = 'He leído y acepto el Aviso de Privacidad y los Términos y Condiciones';

// Texto de un dato pendiente de confirmar, resaltado en la página y en el PDF
function catLegalPendiente(string $texto): string {
    return '<span class="pendiente">' . e($texto) . '</span>';
}

// Correo del Departamento de Datos Personales (dato ficticio del proyecto) como enlace para escribir
function catLegalCorreoDatos(): string {
    return '<a href="mailto:' . e(CAT_LEGAL_CORREO_DATOS) . '">' . e(CAT_LEGAL_CORREO_DATOS) . '</a><sup>*</sup>';
}

// Fecha legal en español (2026-10-20 → 20 de octubre de 2026)
function catLegalFecha(string $ymd): string {
    $meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    $t = strtotime($ymd);
    return $t ? date('j', $t) . ' de ' . $meses[(int)date('n', $t) - 1] . ' de ' . date('Y', $t) : $ymd;
}

// Bloque de identificación del responsable (igual en el aviso y en los términos)
function catLegalIdentidad(): string {
    return '<ul>'
        . '<li><strong>Responsable:</strong> ' . CAT_LEGAL_RAZON_SOCIAL . '<sup>*</sup>, que opera con el nombre comercial <strong>KARMA</strong> (Agencia de Autos Karma).</li>'
        . '<li><strong>RFC:</strong> ' . CAT_LEGAL_RFC . '<sup>*</sup></li>'
        . '<li><strong>Domicilio:</strong> ' . e(CAT_LEGAL_DOMICILIO) . '<sup>*</sup></li>'
        . '<li><strong>Sucursales:</strong> Manzanillo y Colima, en el estado de Colima. Sus direcciones, teléfonos y horarios están en la sección <a href="sucursales.php">Sucursales</a> de este sitio.</li>'
        . '<li><strong>Departamento de Datos Personales:</strong> es el área designada para atender tus solicitudes sobre datos personales. Correo: ' . catLegalCorreoDatos() . '. También puedes escribirnos desde el formulario de <a href="contacto.php">Contacto</a> o acudir a cualquier sucursal.</li>'
        . '</ul>';
}

// Notas que aclaran qué datos son ficticios por tratarse de un proyecto escolar
function catLegalNotaProyecto(): string {
    return '<p class="nota-ficticia"><sup>*</sup> Dato ficticio: KARMA es un proyecto integrador académico. La razón social, el RFC, el domicilio y el correo del Departamento de Datos Personales se crearon solo para el proyecto y no corresponden a una empresa real; no deben usarse para trámites fiscales ni legales. Los datos marcados como «pendiente de confirmar» deben sustituirse por los oficiales antes de usar este documento con clientes reales.</p>'
        . '<p class="nota-ficticia">Audi, Porsche y Ducati son marcas de sus respectivos titulares. Este sitio es una demostración educativa y no está afiliado a dichas marcas; los pagos con tarjeta del sitio son simulados.</p>';
}

// ===== AVISO DE PRIVACIDAD INTEGRAL =====
function catLegalAviso(): array {
    $s = [];
    $s[] = ['id' => 'responsable', 'titulo' => 'Identidad y domicilio del responsable', 'html' =>
        '<p>El responsable del tratamiento de tus datos personales es:</p>' . catLegalIdentidad()
        . '<p>Este aviso se emite conforme a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (publicada en el Diario Oficial de la Federación el 20 de marzo de 2025, en adelante «la Ley»), su Reglamento y las demás disposiciones aplicables.</p>'];

    $s[] = ['id' => 'alcance', 'titulo' => 'A quién aplica este aviso', 'html' =>
        '<p>Aplica a las personas que visitan el catálogo en línea de KARMA, crean una cuenta de cliente, compran refacciones o accesorios, agendan citas, solicitan el apartado de un vehículo o nos escriben desde el sitio. También aplica a los datos que el personal de KARMA registra en el sistema interno de la agencia (Punto de Venta) cuando atiende en sucursal esos pedidos, citas, compras, garantías y créditos, porque el catálogo y el Punto de Venta comparten la misma base de datos.</p>'
        . '<p>El sitio no está dirigido a menores de edad y no recabamos intencionalmente sus datos.</p>'];

    $s[] = ['id' => 'datos', 'titulo' => 'Datos personales que tratamos', 'html' =>
        '<p>Según los servicios que uses, podemos tratar las siguientes categorías de datos:</p>'
        . '<ul>'
        . '<li><strong>Identificación y contacto:</strong> nombre(s), apellidos, correo electrónico y teléfono celular; de forma opcional, calle y número, colonia, ciudad, estado y código postal.</li>'
        . '<li><strong>Cuenta de cliente:</strong> contraseña (solo se guarda transformada con un algoritmo de cifrado irreversible, bcrypt; nadie puede consultarla), sucursal preferida, marca de interés, preferencias de notificación, vehículos de interés que guardes, avisos de tu cuenta, fecha de registro y de último acceso.</li>'
        . '<li><strong>Pedidos y compras:</strong> productos, cantidades, importes, sucursal, modalidad de entrega, dirección de envío y nombre, teléfono y correo de quien recibe, comentarios del pedido; del pago con tarjeta solo la marca, los últimos 4 dígitos y la referencia de la operación (el número completo, la fecha de vencimiento y el código de seguridad no se guardan). También las compras que hagas en sucursal y que el personal asocie a tu cuenta (folio, fecha, artículos, importe y forma de pago).</li>'
        . '<li><strong>Citas y servicios:</strong> tipo de cita, sucursal, fecha y hora; vehículo de interés, color y enganche que indiques para un apartado; para servicio de taller, la marca, modelo y año de tu vehículo, número de serie (VIN) y kilometraje, el servicio solicitado y tus comentarios.</li>'
        . '<li><strong>Atención a clientes:</strong> motivo, asunto, mensaje y teléfono de las solicitudes, quejas y sugerencias que envíes desde Contacto.</li>'
        . '<li><strong>Datos financieros y patrimoniales:</strong> los descritos en el apartado 5 de este aviso.</li>'
        . '<li><strong>Datos técnicos y constancia de consentimiento:</strong> dirección IP desde la que solicitas el registro; fecha, hora, dirección IP y navegador (user agent) con los que aceptas este aviso y los Términos y Condiciones, así como la versión aceptada; y la información de las cookies descritas en el apartado 11.</li>'
        . '</ul>'
        . '<p><strong>Datos sensibles:</strong> KARMA no solicita datos personales sensibles (por ejemplo, origen étnico, estado de salud, creencias o preferencia sexual). Te pedimos no incluirlos en los mensajes o comentarios que nos envíes.</p>'
        . '<p><strong>Datos de otras personas:</strong> si nos das datos de un tercero (por ejemplo, de quien recibirá tu pedido), declaras contar con su autorización y haberle informado de este aviso.</p>'];

    $s[] = ['id' => 'finalidades', 'titulo' => 'Finalidades del tratamiento', 'html' =>
        '<h3>Finalidades primarias (necesarias para la relación contigo)</h3>'
        . '<ol>'
        . '<li>Crear, verificar y administrar tu cuenta, incluido el envío del correo de confirmación y la constancia de aceptación de este aviso y de los Términos y Condiciones.</li>'
        . '<li>Procesar tus pedidos de refacciones y accesorios: apartar las piezas en el inventario de la sucursal, cobrarlas en caja o registrar el pago, enviarlas o entregarlas, y atender cancelaciones, devoluciones y garantías.</li>'
        . '<li>Agendar, confirmar, consultar y cancelar tus citas de visita, apartado de vehículo y servicio de taller, junto con los servicios adicionales que elijas.</li>'
        . '<li>Dar seguimiento a tus pedidos, citas y operaciones en los sistemas internos de KARMA (apartado 6).</li>'
        . '<li>Mostrarte en tu perfil tus pedidos, citas, compras en sucursal, garantías y, en su caso, el estado de tu crédito.</li>'
        . '<li>Atender tus solicitudes, quejas y sugerencias, y enviarte avisos sobre tu cuenta, tus pedidos y tus citas (en tu perfil y por correo electrónico).</li>'
        . '<li>Proteger la seguridad del sitio y de tu cuenta: limitar intentos de acceso y de registro, y prevenir fraudes o usos indebidos.</li>'
        . '<li>Cumplir obligaciones legales (por ejemplo, fiscales, mercantiles y de protección al consumidor) y atender requerimientos de autoridades competentes.</li>'
        . '</ol>'
        . '<h3>Finalidades secundarias (requieren tu consentimiento y no son necesarias)</h3>'
        . '<ul><li>Enviarte promociones, novedades y publicidad de KARMA.</li></ul>'
        . '<p>Solo usamos tus datos para esta finalidad si lo autorizas marcando la casilla opcional «Deseo recibir promociones y novedades de KARMA» al registrarte (aparece desmarcada) o activando «Promociones y novedades» en las preferencias de tu perfil. Puedes negarte o retirar tu autorización en cualquier momento desde tu perfil o con el Departamento de Datos Personales; tu negativa no afecta los servicios que nos solicitas.</p>'];

    $s[] = ['id' => 'financieros', 'titulo' => 'Datos financieros y patrimoniales', 'html' =>
        '<p>Tratamos datos financieros o patrimoniales únicamente cuando corresponde:</p>'
        . '<ul>'
        . '<li><strong>Pagos:</strong> importe, forma de pago, referencia y, en pagos con tarjeta, solo la marca y los últimos 4 dígitos. En este proyecto académico el pago con tarjeta del sitio es una <strong>simulación</strong>: no se realiza ningún cargo.</li>'
        . '<li><strong>Crédito automotriz:</strong> los créditos se contratan en sucursal. Cuando contratas uno, el personal registra en el sistema interno el vehículo financiado, el enganche, el monto adeudado, la mensualidad y el número de abonos pagados y totales, así como el tipo y número de tu identificación oficial, tu RFC y tu domicilio. Si tu cuenta en línea usa el mismo correo, tu perfil te muestra el estado de tu crédito.</li>'
        . '<li><strong>Simulador de crédito:</strong> los montos que capturas en el simulador se calculan en tu navegador y no se guardan.</li>'
        . '</ul>'
        . '<p>Conforme al artículo 7 de la Ley, estos datos requieren tu <strong>consentimiento expreso</strong>, que otorgas al pulsar el botón de aceptación en la página de confirmación a la que te lleva el correo de registro, salvo las excepciones de los artículos 9 y 36 de la Ley (por ejemplo, cuando los datos se requieren para cumplir obligaciones de la relación jurídica que tienes con KARMA).</p>'];

    $s[] = ['id' => 'sistemas', 'titulo' => 'Uso de tus datos en los sistemas internos de KARMA', 'html' =>
        '<p>El catálogo en línea y el Punto de Venta (sistema exclusivo para empleados de KARMA) comparten la misma base de datos. Esto permite que:</p>'
        . '<ul>'
        . '<li>Los pedidos con recogida en sucursal, las visitas y las solicitudes de apartado lleguen al Punto de Venta, donde el personal de caja consulta tu nombre, teléfono, correo y el detalle del pedido para cobrarlo, entregarlo o cancelarlo.</li>'
        . '<li>Las compras, garantías y créditos que el personal registra en sucursal se asocien a tu cuenta y puedas consultarlos en tu perfil.</li>'
        . '<li>Los tickets de compra se te envíen por correo electrónico cuando los solicites en caja.</li>'
        . '</ul>'
        . '<p>Solo accede el personal autorizado, con usuario y contraseña propios y según su rol. Las operaciones sensibles del Punto de Venta (ventas, créditos, garantías y cobro o cancelación de órdenes web) exigen además la credencial del mismo empleado que tiene la sesión abierta. El personal está obligado a guardar confidencialidad aun después de terminar su relación con KARMA (artículo 20 de la Ley).</p>'];

    $s[] = ['id' => 'transferencias', 'titulo' => 'Proveedores que nos apoyan y transferencias', 'html' =>
        '<h3>Personas encargadas (tratan datos por cuenta de KARMA)</h3>'
        . '<ul>'
        . '<li><strong>Brevo</strong> (servicio de correo electrónico transaccional): recibe tu nombre, tu correo y el contenido de cada mensaje (por ejemplo, el PDF de este aviso y de los Términos y Condiciones, o tu ticket de compra) para enviarte el correo de confirmación de registro y los tickets que solicites.</li>'
        . '<li><strong>DeepL</strong> (traducción automática): solo si usas el botón ES / EN, el texto visible de la página se envía a este servicio para traducirlo.</li>'
        . '<li>Proveedor de hospedaje del sitio: ' . catLegalPendiente('[PROVEEDOR DE HOSPEDAJE PENDIENTE DE CONFIRMAR]') . '.</li>'
        . '<li>Empresa de mensajería para los pedidos con envío a domicilio: ' . catLegalPendiente('[EMPRESA DE PAQUETERÍA PENDIENTE DE CONFIRMAR]') . '.</li>'
        . '</ul>'
        . '<p>Además, para mostrar el sitio tu navegador descarga tipografías de Google Fonts y la biblioteca del visor 3D desde jsDelivr; estos servicios reciben tu dirección IP y los datos técnicos de tu navegador conforme a sus propias políticas.</p>'
        . '<h3>Transferencias</h3>'
        . '<p>KARMA no vende tus datos ni los comparte con terceros para fines publicitarios. Solo podrán transferirse, sin requerir tu consentimiento, en los supuestos del artículo 36 de la Ley:</p>'
        . '<ul>'
        . '<li>A autoridades competentes, cuando una ley lo exija o exista una orden o mandato fundado y motivado (fracciones I, V y VI).</li>'
        . '<li>A las aseguradoras y a las autoridades de control vehicular que intervengan en los seguros, trámites de placas, tenencia o refrendo y verificación que contrates con KARMA en sucursal, únicamente con los datos necesarios para ese servicio (fracciones IV y VII).</li>'
        . '</ul>'
        . '<p><strong>Cláusula de transferencias (artículo 35 de la Ley):</strong> KARMA no realiza transferencias que requieran tu consentimiento. Si en el futuro pretendiera realizar alguna, te lo informará mediante una nueva versión de este aviso y solo la hará si la aceptas expresamente.</p>'];

    $s[] = ['id' => 'seguridad', 'titulo' => 'Medidas de protección de tu información', 'html' =>
        '<p>Mantenemos medidas de seguridad administrativas, técnicas y físicas (artículo 18 de la Ley), entre ellas:</p>'
        . '<ul>'
        . '<li>Contraseñas guardadas solo como hash bcrypt y enlaces de confirmación aleatorios, personales, de un solo uso y con vencimiento, que se guardan únicamente como huella SHA-256.</li>'
        . '<li>Sesiones con cookies protegidas (HttpOnly y SameSite), protección contra solicitudes falsificadas (CSRF) y límites de intentos de acceso, registro y reenvío de correos.</li>'
        . '<li>En el sitio publicado, el registro y la confirmación de cuentas solo funcionan con conexión cifrada (HTTPS).</li>'
        . '<li>Acceso a los sistemas internos por usuario, rol y credencial del empleado; operaciones registradas en transacciones para evitar datos inconsistentes.</li>'
        . '<li>No se guardan el número completo de tarjeta, su vencimiento ni su código de seguridad.</li>'
        . '</ul>'
        . '<p>Si ocurriera una vulneración de seguridad que afecte de forma significativa tus derechos patrimoniales o morales, te lo informaremos de inmediato para que puedas tomar medidas (artículo 19 de la Ley).</p>'];

    $s[] = ['id' => 'arco', 'titulo' => 'Derechos ARCO y cómo ejercerlos', 'html' =>
        '<p>Tú o tu representante legal pueden ejercer en cualquier momento los derechos de <strong>Acceso</strong> (conocer qué datos tenemos y cómo los tratamos), <strong>Rectificación</strong> (corregirlos si son inexactos o están incompletos), <strong>Cancelación</strong> (pedir que se eliminen) y <strong>Oposición</strong> (oponerte a su tratamiento por causa legítima).</p>'
        . '<h3>Medios</h3>'
        . '<p>Envía tu solicitud al Departamento de Datos Personales: por correo a ' . catLegalCorreoDatos() . ', desde el formulario de <a href="contacto.php">Contacto</a> (motivo «Otro motivo», asunto «Derechos ARCO») o por escrito en cualquier sucursal. Muchos datos de tu cuenta también puedes consultarlos y corregirlos tú mismo en <a href="perfil.php">Mi perfil</a>.</p>'
        . '<h3>Requisitos de la solicitud (artículo 28 de la Ley)</h3>'
        . '<ol>'
        . '<li>Tu nombre y un domicilio, correo u otro medio para recibir la respuesta.</li>'
        . '<li>Documentos que acrediten tu identidad (identificación oficial vigente) o, en su caso, la identidad y personalidad de tu representante.</li>'
        . '<li>La descripción clara y precisa de los datos sobre los que ejerces el derecho (salvo en el derecho de acceso).</li>'
        . '<li>El derecho que deseas ejercer o lo que solicitas.</li>'
        . '<li>Cualquier elemento que facilite localizar tus datos (por ejemplo, el correo de tu cuenta o el folio de un pedido).</li>'
        . '</ol>'
        . '<p>Para rectificar, indica además las modificaciones y acompaña la documentación que las sustente (artículo 30 de la Ley).</p>'
        . '<h3>Plazos y respuesta</h3>'
        . '<p>Te comunicaremos la determinación en un máximo de <strong>20 días hábiles</strong> desde que recibamos tu solicitud y, si procede, la haremos efectiva dentro de los <strong>15 días hábiles</strong> siguientes; ambos plazos pueden ampliarse una sola vez por un periodo igual cuando el caso lo justifique (artículo 31 de la Ley). Responderemos por el mismo medio por el que presentaste la solicitud. El acceso se entregará en copia simple o documento electrónico, previa acreditación de identidad.</p>'
        . '<p>El ejercicio de los derechos ARCO es gratuito; solo podrán cobrarse los costos de reproducción, copias o envío (artículo 34 de la Ley). Podremos negar la solicitud en los casos del artículo 33 de la Ley (por ejemplo, si no se acredita la identidad), y no estaremos obligados a cancelar datos en los supuestos del artículo 25 (por ejemplo, si son necesarios para cumplir un contrato vigente o una obligación legal). En todos los casos te informaremos el motivo.</p>'
        . '<p>Si no estás conforme con la respuesta, o no la recibes, puedes presentar una solicitud de protección de datos ante la <strong>Secretaría Anticorrupción y Buen Gobierno</strong>, autoridad competente en la materia, dentro de los 15 días hábiles siguientes a que te comuniquemos la respuesta (artículo 40 de la Ley).</p>'];

    $s[] = ['id' => 'revocacion', 'titulo' => 'Revocación del consentimiento y limitación del uso o divulgación', 'html' =>
        '<h3>Revocación</h3>'
        . '<p>Puedes revocar en cualquier momento el consentimiento que nos diste, sin efectos retroactivos (artículo 7 de la Ley), con una solicitud por los mismos medios y con los mismos requisitos que los derechos ARCO; la atenderemos en los mismos plazos. Ten en cuenta que, si la revocación afecta finalidades primarias, ya no podremos mantener tu cuenta ni prestarte los servicios que dependen de ella, y que algunos datos deberán conservarse bloqueados mientras exista una obligación legal (apartado 12).</p>'
        . '<h3>Limitar el uso o la divulgación de tus datos</h3>'
        . '<ul>'
        . '<li>En <a href="perfil.php">Mi perfil</a> puedes desactivar en cualquier momento las notificaciones por correo, por SMS y las promociones y novedades.</li>'
        . '<li>Puedes pedir al Departamento de Datos Personales que dejemos de usar tus datos para fines publicitarios; registraremos tu decisión y la respetaremos (artículos 18 y 18 bis de la Ley Federal de Protección al Consumidor).</li>'
        . '<li>También puedes inscribirte en el Registro Público para Evitar Publicidad de la Procuraduría Federal del Consumidor (PROFECO).</li>'
        . '</ul>'];

    $s[] = ['id' => 'cookies', 'titulo' => 'Cookies y tecnologías similares', 'html' =>
        '<p>El sitio usa únicamente cookies y almacenamiento local necesarios para funcionar y para recordar tus preferencias:</p>'
        . '<ul>'
        . '<li><strong>KARMACLIENTE</strong> (cookie de sesión): mantiene tu sesión, tu carrito y la protección contra solicitudes falsificadas; se borra al cerrar el navegador.</li>'
        . '<li><strong>karma_sucursal</strong> (cookie, 1 año): recuerda la sucursal con la que navegas.</li>'
        . '<li><strong>Almacenamiento local del navegador:</strong> el modo claro u oscuro, el idioma elegido y las traducciones ya realizadas, y mensajes temporales de la página.</li>'
        . '</ul>'
        . '<p>En el sitio no usamos cookies publicitarias ni de analítica, ni elaboramos perfiles de navegación. Los servicios de Google Fonts y jsDelivr descritos en el apartado 7 pueden recibir datos técnicos de tu navegador. Puedes borrar o bloquear las cookies desde la configuración de tu navegador; si bloqueas la cookie de sesión no podrás iniciar sesión ni comprar.</p>'
        . '<p><strong>Correos electrónicos:</strong> Brevo, el servicio con el que enviamos los correos de registro y los tickets, registra la entrega de cada mensaje y hace pasar los enlaces por su propio servidor antes de llevarte a KARMA; según la configuración de la cuenta también puede medir la apertura del correo. Por ello Brevo puede registrar la fecha, tu dirección IP y tu tipo de dispositivo cuando abres el correo o pulsas un enlace. KARMA no usa esa información para publicidad ni para elaborar perfiles.</p>'];

    $s[] = ['id' => 'conservacion', 'titulo' => 'Conservación, bloqueo y eliminación', 'html' =>
        '<p>Conservamos tus datos solo el tiempo necesario para las finalidades de este aviso y para cumplir obligaciones legales (artículo 10 de la Ley):</p>'
        . '<ul>'
        . '<li><strong>Solicitudes de registro no confirmadas:</strong> el enlace del correo vence a las 24 horas. Al vencer, o si cancelas la solicitud, se eliminan tu nombre, correo, teléfono, dirección y contraseña cifrada; un día después se eliminan también la dirección IP y la huella del correo usadas para los límites de envío.</li>'
        . '<li><strong>Cuenta de cliente:</strong> mientras esté activa. Si pides su cancelación, los datos se bloquean durante el plazo de prescripción de las acciones derivadas de la relación contigo y después se suprimen (artículo 24 de la Ley); durante el bloqueo no se usan para ninguna finalidad.</li>'
        . '<li><strong>Operaciones comerciales</strong> (pedidos, compras y pagos): sus comprobantes se conservan al menos 10 años (artículo 38 del Código de Comercio); la contabilidad y la documentación fiscal, 5 años (artículo 30 del Código Fiscal de la Federación).</li>'
        . '<li><strong>Constancia de aceptación</strong> de este aviso y de los Términos y Condiciones: mientras exista tu cuenta y durante el periodo de bloqueo, para acreditar que diste tu consentimiento.</li>'
        . '<li><strong>Datos sobre incumplimiento de obligaciones contractuales</strong> (por ejemplo, de un crédito): se eliminan al transcurrir 72 meses desde el incumplimiento (artículo 10 de la Ley).</li>'
        . '</ul>'];

    $s[] = ['id' => 'cambios', 'titulo' => 'Cambios a este aviso', 'html' =>
        '<p>Este aviso puede cambiar por nuevas disposiciones legales, cambios en nuestros servicios o en nuestras prácticas de privacidad. Cada versión se publica en la página <a href="privacidad.php">Aviso de privacidad</a> con su número de versión y fecha de vigencia, y KARMA conserva el texto íntegro de las versiones anteriores.</p>'
        . '<p>Si el cambio es sustancial (por ejemplo, nuevas finalidades o transferencias que requieran tu consentimiento), te lo informaremos al correo de tu cuenta y en el apartado de avisos de tu perfil antes de aplicarlo, y te pediremos nuevamente tu consentimiento cuando la Ley lo exija (artículo 11 de la Ley).</p>'];

    $s[] = ['id' => 'consentimiento', 'titulo' => 'Tu consentimiento', 'html' =>
        '<p>Al crear tu cuenta te enviamos este aviso y los Términos y Condiciones en PDF. Tu cuenta solo se crea cuando pulsas el botón «' . CAT_BOTON_ACEPTAR . '» en la página de confirmación a la que te lleva el correo. Con ello otorgas tu consentimiento expreso, incluido el relativo a datos financieros y patrimoniales; abrir el correo, descargar el PDF o visitar la página no equivale a aceptar. Registramos la versión aceptada, la fecha, la hora, la dirección IP y el navegador como constancia.</p>'
        . '<p>En los formularios de pedido y de contacto mostramos una referencia a este aviso; el texto íntegro está siempre disponible en esta página y al pie de todas las páginas del sitio.</p>'];

    return ['tipo' => 'aviso_privacidad', 'titulo' => 'Aviso de Privacidad Integral', 'corto' => 'Aviso de Privacidad',
        'version' => '2.2', 'vigencia' => '2026-10-20', 'pagina' => 'privacidad.php',
        'resumen' => 'Cómo KARMA trata los datos personales de sus clientes en el catálogo en línea y en sus sucursales.',
        'secciones' => $s, 'notas' => catLegalNotaProyecto()];
}

// ===== TÉRMINOS Y CONDICIONES DEL CATÁLOGO EN LÍNEA =====
function catLegalTerminos(): array {
    $s = [];
    $s[] = ['id' => 'aceptacion', 'titulo' => 'Aceptación y datos del proveedor', 'html' =>
        '<p>Estos términos regulan el uso del catálogo en línea de KARMA y las operaciones que realizas desde él. Los aceptas al confirmar tu registro desde el correo que te enviamos; para navegar sin cuenta aplican en lo conducente. Las operaciones de consumo se rigen además por la Ley Federal de Protección al Consumidor.</p>'
        . '<p>Datos del proveedor (artículo 76 bis, fracción III, de la Ley Federal de Protección al Consumidor):</p>' . catLegalIdentidad()
        . '<p>El tratamiento de tus datos personales se explica en el <a href="privacidad.php">Aviso de Privacidad Integral</a>, que forma parte de estos términos.</p>'];

    $s[] = ['id' => 'cuenta', 'titulo' => 'Tu cuenta de cliente', 'html' =>
        '<ul>'
        . '<li>Para comprar en línea, agendar citas, apartar vehículos y guardar vehículos de interés necesitas una cuenta. Para contratar debes tener capacidad legal para obligarte (ser mayor de edad).</li>'
        . '<li>Tu cuenta se crea solo después de que confirmes desde el correo electrónico que proporcionaste y aceptes expresamente el Aviso de Privacidad y estos términos. Mientras no confirmes, no puedes iniciar sesión. El enlace de confirmación es personal, de un solo uso y vence a las 24 horas; puedes pedir un nuevo correo desde la página de registro.</li>'
        . '<li>Proporciona datos verdaderos y mantenlos actualizados. Cada correo electrónico solo puede tener una cuenta.</li>'
        . '<li>Tu contraseña es personal: debe tener al menos 8 caracteres con letras y números. Eres responsable de las operaciones hechas con tu cuenta; si sospechas un uso indebido, cámbiala desde tu perfil y avísanos.</li>'
        . '<li>Si ya eras cliente de una sucursal con el mismo correo, al confirmar tu registro tu cuenta en línea se vincula con tu historial de compras, garantías y crédito.</li>'
        . '<li>KARMA puede suspender una cuenta que se use para fraudes, para dañar el sitio o en contra de estos términos, informándote el motivo.</li>'
        . '</ul>'];

    $s[] = ['id' => 'productos', 'titulo' => 'Información, precios y disponibilidad', 'html' =>
        '<ul>'
        . '<li>Los precios se muestran en pesos mexicanos con IVA incluido; antes de confirmar un pedido verás el monto total a pagar, incluido el envío (artículo 7 bis de la Ley Federal de Protección al Consumidor).</li>'
        . '<li>La disponibilidad corresponde al inventario de la sucursal elegida (Manzanillo o Colima); cada sucursal tiene sus propias existencias y la disponibilidad se confirma al comprar o agendar.</li>'
        . '<li>Las imágenes y los modelos 3D son ilustrativos: un mismo modelo 3D puede representar vehículos con la misma carrocería y el color se aplica digitalmente. Las especificaciones definitivas de cada unidad las confirma tu asesor.</li>'
        . '</ul>'];

    $s[] = ['id' => 'compras', 'titulo' => 'Compras en línea de refacciones y accesorios', 'html' =>
        '<p>Las refacciones y los accesorios del catálogo pueden comprarse en dos modalidades:</p>'
        . '<ol>'
        . '<li><strong>Recoger en sucursal con pago en efectivo:</strong> al confirmar, las piezas se apartan en el inventario de la sucursal y el pedido aparece en la caja del Punto de Venta, donde lo pagas y recibes al presentarte con tu folio.</li>'
        . '<li><strong>Envío a domicilio con pago con tarjeta:</strong> el costo de envío es de ' . catPrecio(CAT_ENVIO_COSTO, true) . ' y es gratis en compras desde ' . catPrecio(CAT_ENVIO_GRATIS_DESDE, true) . '. El tiempo de entrega es ' . catLegalPendiente('[TIEMPO DE ENTREGA DE LOS ENVÍOS PENDIENTE DE CONFIRMAR]') . '. En este proyecto académico el pago con tarjeta es una simulación y no se realiza ningún cargo.</li>'
        . '</ol>'
        . '<ul>'
        . '<li>Puedes pedir hasta ' . CAT_MAX_POR_PRODUCTO . ' piezas iguales por pedido.</li>'
        . '<li>Antes de confirmar puedes revisar y corregir tu carrito, la modalidad, los datos de entrega y el total. Al confirmar recibes un folio y un aviso en tu perfil, donde puedes consultar el estado del pedido.</li>'
        . '</ul>'];

    $s[] = ['id' => 'cancelaciones', 'titulo' => 'Cancelaciones, devoluciones y garantías', 'html' =>
        '<ul>'
        . '<li><strong>Pedidos para recoger en sucursal:</strong> puedes cancelarlos desde tu perfil mientras estén pendientes de pago; las piezas regresan al inventario.</li>'
        . '<li><strong>Derecho de revocación en compras con envío:</strong> tienes 5 días hábiles contados a partir de la entrega para revocar tu compra sin responsabilidad, avisándonos o devolviendo el producto por un medio fehaciente; te reintegraremos el precio pagado y los costos de flete y seguro de la devolución corren por tu cuenta (artículo 56 de la Ley Federal de Protección al Consumidor).</li>'
        . '<li><strong>Garantía:</strong> los productos que se ofrecen con garantía la tienen por al menos 90 días desde la entrega (artículo 77 de la misma Ley), salvo que la póliza indique un plazo mayor. Si un producto no corresponde a lo ofrecido o el bien reparado no queda en estado adecuado dentro de la garantía, puedes elegir su reposición o la devolución de lo pagado (artículo 92). Las devoluciones de dinero se hacen por la misma forma de pago, salvo que aceptes otra.</li>'
        . '<li>Las garantías de los vehículos se documentan en tu ticket de compra y en la póliza correspondiente; las registradas en sucursal aparecen en tu perfil.</li>'
        . '</ul>'];

    $s[] = ['id' => 'vehiculos', 'titulo' => 'Vehículos: citas de visita y apartados', 'html' =>
        '<ul>'
        . '<li>Los vehículos no se venden en línea. Desde el catálogo puedes agendar una visita para conocer un vehículo o solicitar su apartado; ambas solicitudes llegan a la sucursal y un asesor te atiende.</li>'
        . '<li>El enganche que indiques al solicitar un apartado es una referencia para tu asesor y no se cobra en línea. La solicitud no retira la unidad del inventario: el apartado y la venta, de contado o a crédito, se formalizan en sucursal con la documentación correspondiente.</li>'
        . '<li>Solo puedes solicitar el apartado de un vehículo con unidades disponibles en la sucursal elegida.</li>'
        . '</ul>'];

    $s[] = ['id' => 'servicios', 'titulo' => 'Citas de servicio y servicios de la agencia', 'html' =>
        '<ul>'
        . '<li>Las citas se agendan desde el día siguiente y hasta con 60 días de anticipación, con horarios de inicio de 9:00 a 18:00 h de lunes a viernes y de 9:00 a 13:00 h los sábados; los domingos no hay citas. Cada horario tiene un cupo limitado por sucursal.</li>'
        . '<li>Puedes cancelar desde tu perfil una cita futura que aún no haya sido atendida.</li>'
        . '<li>Los servicios de la agencia (seguros de cobertura amplia, de vida y desempleo y de llantas y rines; gestoría de placas y alta vehicular; ISAN; tenencia o refrendo; verificación con holograma 00; plan de mantenimiento prepagado; garantía extendida; accesorios originales e instalación; película de seguridad o polarizado, y orden de servicio de taller) se contratan en sucursal con tu asesor, quien te informa su precio, cobertura y condiciones antes de contratarlos.</li>'
        . '<li>En el servicio de taller, tu asesor confirma contigo el presupuesto antes de iniciar cualquier trabajo.</li>'
        . '</ul>'];

    $s[] = ['id' => 'financiamiento', 'titulo' => 'Simulador y crédito automotriz', 'html' =>
        '<ul>'
        . '<li>El simulador de crédito es informativo: usa una tasa anual de referencia de ' . rtrim(rtrim(number_format(CAT_TASA_ANUAL, 2), '0'), '.') . ' %, una comisión por apertura de ' . rtrim(rtrim(number_format(CAT_COMISION_APERTURA * 100, 2), '0'), '.') . ' % sobre el monto financiado y plazos de ' . implode(', ', CAT_PLAZOS) . ' meses. Su resultado no es una oferta ni una aprobación de crédito.</li>'
        . '<li>El crédito está sujeto a evaluación y se formaliza en sucursal mediante un contrato firmado, en el que constan el monto, la tasa, la comisión, el plazo, las mensualidades y los seguros requeridos.</li>'
        . '</ul>'];

    $s[] = ['id' => 'pagos', 'titulo' => 'Pagos', 'html' =>
        '<ul>'
        . '<li>Formas de pago disponibles en el sitio: efectivo en la caja de la sucursal (pedidos para recoger) y tarjeta de crédito o débito (pedidos con envío).</li>'
        . '<li>En este proyecto académico el pago con tarjeta es una simulación: no se conecta con ningún banco y no se realiza ningún cargo. Solo se guardan la marca, los últimos 4 dígitos y la referencia de la operación.</li>'
        . '<li>Las operaciones de vehículos, abonos de crédito y servicios se pagan en sucursal.</li>'
        . '</ul>'];

    $s[] = ['id' => 'uso', 'titulo' => 'Uso adecuado del sitio y propiedad intelectual', 'html' =>
        '<ul>'
        . '<li>No está permitido usar el sitio para fines ilícitos, intentar acceder a cuentas o sistemas ajenos (incluido el Punto de Venta), alterar precios o solicitudes, automatizar registros o enviar información falsa.</li>'
        . '<li>Los textos, diseños y desarrollos del sitio pertenecen a sus autores. Audi, Porsche y Ducati son marcas de sus respectivos titulares; las fuentes de las imágenes se indican en <a href="creditos.php">Créditos de imágenes</a>.</li>'
        . '</ul>'];

    $s[] = ['id' => 'comunicaciones', 'titulo' => 'Comunicaciones y promociones', 'html' =>
        '<p>Te enviaremos avisos necesarios sobre tu cuenta, tus pedidos y tus citas. Solo te enviaremos promociones si lo autorizas, y respetaremos tu decisión de no recibirlas (artículo 76 bis, fracción VI, de la Ley Federal de Protección al Consumidor); puedes cambiarla en cualquier momento desde tu perfil.</p>'];

    $s[] = ['id' => 'responsabilidad', 'titulo' => 'Disponibilidad del sitio y responsabilidad', 'html' =>
        '<p>Procuramos que el sitio funcione de forma continua y que su información sea exacta, pero puede haber interrupciones por mantenimiento o fallas técnicas. KARMA respeta los precios, condiciones y disponibilidad que confirmó al aceptar tu pedido o tu cita (artículo 7 de la Ley Federal de Protección al Consumidor). Nada de lo establecido en estos términos limita los derechos que te otorga dicha Ley.</p>'];

    $s[] = ['id' => 'quejas', 'titulo' => 'Aclaraciones, quejas y PROFECO', 'html' =>
        '<p>Para aclaraciones, quejas o reclamaciones escríbenos desde <a href="contacto.php">Contacto</a> (motivo «Queja») o acude a cualquier sucursal. Si no quedas satisfecho, puedes acudir a la Procuraduría Federal del Consumidor (PROFECO).</p>'];

    $s[] = ['id' => 'modificaciones', 'titulo' => 'Modificaciones a estos términos', 'html' =>
        '<p>Cada versión se publica en la página <a href="terminos.php">Términos y condiciones</a> con su número y fecha de vigencia. Las compras y citas se rigen por la versión vigente cuando las realizaste. Si un cambio es sustancial, te avisaremos al correo de tu cuenta y en tu perfil antes de aplicarlo.</p>'];

    $s[] = ['id' => 'ley', 'titulo' => 'Legislación aplicable y jurisdicción', 'html' =>
        '<p>Estos términos se rigen por las leyes federales de los Estados Unidos Mexicanos. Sin perjuicio de tu derecho a acudir a la PROFECO, para la interpretación y cumplimiento de estos términos las partes se someten a los tribunales competentes de ' . catLegalPendiente('[CIUDAD DE LOS TRIBUNALES COMPETENTES PENDIENTE DE CONFIRMAR]') . '.</p>'];

    return ['tipo' => 'terminos_condiciones', 'titulo' => 'Términos y Condiciones del Catálogo en Línea', 'corto' => 'Términos y Condiciones',
        'version' => '2.2', 'vigencia' => '2026-10-20', 'pagina' => 'terminos.php',
        'resumen' => 'Reglas para usar el catálogo en línea de KARMA: cuenta, compras, citas, apartados, pagos y garantías.',
        'secciones' => $s, 'notas' => catLegalNotaProyecto()];
}

// Ambos documentos con su huella SHA-256 (la huella cubre título, versión, vigencia, secciones y notas)
function catLegalDocumentos(): array {
    static $docs = null;
    if ($docs !== null) return $docs;
    $docs = [];
    foreach ([catLegalAviso(), catLegalTerminos()] as $doc) {
        $doc['contenido'] = catLegalContenidoCanonico($doc);
        $doc['hash'] = hash('sha256', $doc['contenido']);
        $docs[$doc['tipo']] = $doc;
    }
    return $docs;
}

function catLegalDocumento(string $tipo): array {
    $docs = catLegalDocumentos();
    if (!isset($docs[$tipo])) throw new InvalidArgumentException('Documento legal desconocido.');
    return $docs[$tipo];
}

// Texto exacto de la versión (JSON estable): es lo que se guarda en documentos_legales.contenido
function catLegalContenidoCanonico(array $doc): string {
    $datos = array_intersect_key($doc, array_flip(['tipo', 'titulo', 'version', 'vigencia', 'secciones', 'notas']));
    return json_encode($datos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

// Registra la versión vigente en documentos_legales (una sola vez) y regresa su id.
// Si la misma versión ya existe con otro texto, se detiene: el texto cambió sin publicar una versión nueva.
function catLegalRegistrarVersion(PDO $pdo, array $doc): int {
    $buscar = $pdo->prepare('SELECT id_documento, hash_contenido FROM documentos_legales WHERE tipo = ? AND version = ?');
    $buscar->execute([$doc['tipo'], $doc['version']]);
    $fila = $buscar->fetch(PDO::FETCH_ASSOC);
    if (!$fila) {
        try {
            $pdo->prepare('INSERT INTO documentos_legales (tipo, version, fecha_vigencia, hash_contenido, contenido) VALUES (?, ?, ?, ?, ?)')
                ->execute([$doc['tipo'], $doc['version'], $doc['vigencia'], $doc['hash'], $doc['contenido']]);
            return (int)$pdo->lastInsertId();
        } catch (PDOException $e) {
            if (($e->errorInfo[1] ?? 0) !== 1062) throw $e;
            $buscar->execute([$doc['tipo'], $doc['version']]); // otra petición la registró al mismo tiempo
            $fila = $buscar->fetch(PDO::FETCH_ASSOC);
        }
    }
    if (!$fila || !hash_equals((string)$fila['hash_contenido'], $doc['hash'])) {
        throw new RuntimeException("El texto de {$doc['tipo']} versión {$doc['version']} cambió sin publicar una versión nueva: sube la versión en includes/legal.php.");
    }
    return (int)$fila['id_documento'];
}

// Id de la versión vigente ya registrada (null si todavía no se ha enviado nunca); no escribe en la BD
function catLegalIdVigente(PDO $pdo, string $tipo): ?int {
    $doc = catLegalDocumento($tipo);
    $stmt = $pdo->prepare('SELECT id_documento FROM documentos_legales WHERE tipo = ? AND version = ? AND hash_contenido = ?');
    $stmt->execute([$tipo, $doc['version'], $doc['hash']]);
    $id = $stmt->fetchColumn();
    return $id === false ? null : (int)$id;
}

// Huella corta para mostrar (los primeros 16 caracteres del SHA-256)
function catLegalHuella(array $doc): string {
    return strtoupper(substr($doc['hash'], 0, 16));
}

// ===== PÁGINA WEB (privacidad.php y terminos.php) =====
function catLegalPagina(string $tipo): void {
    $doc = catLegalDocumento($tipo);
    $otro = catLegalDocumento($tipo === 'aviso_privacidad' ? 'terminos_condiciones' : 'aviso_privacidad');
    catCabecera(['titulo' => $doc['corto'], 'activo' => '', 'descripcion' => $doc['resumen']]);
    ?>
<section class="cabecera-pagina"><div class="contenedor">
  <ol class="migas"><li><a href="index.php">Inicio</a></li><li><?= e($doc['corto']) ?></li></ol>
  <h1><?= e($doc['titulo']) ?></h1>
  <p><?= e($doc['resumen']) ?></p>
  <div class="legal-meta">
    <span><?= icono('documento', 'icono icono--chico') ?> Versión <strong><?= e($doc['version']) ?></strong></span>
    <span><?= icono('calendario', 'icono icono--chico') ?> Vigente desde el <?= e(catLegalFecha($doc['vigencia'])) ?></span>
    <span translate="no" title="Huella SHA-256 del texto de esta versión"><?= icono('candado', 'icono icono--chico') ?> Huella <?= e(catLegalHuella($doc)) ?></span>
  </div>
  <div class="fila fila--envolver" style="margin-top:18px;">
    <a class="btn btn--secundario btn--chico" href="documentos_legales.php" target="_blank" rel="noopener"><?= icono('documento') ?> Descargar ambos documentos en PDF</a>
    <a class="btn btn--fantasma btn--chico" href="<?= e($otro['pagina']) ?>">Ver <?= e($otro['corto']) ?></a>
  </div>
</div></section>
<section class="seccion--compacta"><div class="contenedor documento-legal-rejilla">
  <nav class="indice-legal" aria-label="Contenido del documento">
    <details open>
      <summary>Contenido</summary>
      <ol><?php foreach ($doc['secciones'] as $i => $sec): ?><li><a href="#<?= e($sec['id']) ?>"><?= e($sec['titulo']) ?></a></li><?php endforeach; ?></ol>
    </details>
  </nav>
  <article class="documento-legal">
    <p class="aviso-demo"><?= icono('info') ?><span>KARMA es un proyecto integrador académico. Los datos marcados con <sup>*</sup> son ficticios y los resaltados como «pendiente de confirmar» deben sustituirse por los oficiales antes de un uso real.</span></p>
    <?php foreach ($doc['secciones'] as $i => $sec): ?>
      <section id="<?= e($sec['id']) ?>" class="seccion-legal">
        <h2><span class="num"><?= $i + 1 ?>.</span> <?= e($sec['titulo']) ?></h2>
        <?= $sec['html'] ?>
      </section>
    <?php endforeach; ?>
    <footer class="notas-legales"><?= $doc['notas'] ?></footer>
  </article>
</div></section>
<?php
    catPie();
}

// ===== PDF (Dompdf, el mismo que genera el ticket del POS) =====

// Logo vectorial (Dompdf lo dibuja sin la extensión GD de PHP)
function catLegalLogoPdf(): string {
    $ruta = dirname(__DIR__, 3) . '/assets/logo-karma-vector.svg';
    return is_file($ruta) ? 'data:image/svg+xml;base64,' . base64_encode((string)file_get_contents($ruta)) : '';
}

// Convierte los enlaces internos (contacto.php…) en direcciones completas para el PDF; sin URL pública se quitan
function catLegalEnlacesPdf(string $html, ?string $urlCatalogo): string {
    return (string)preg_replace_callback('#<a href="([a-z_]+\.php[^"]*)">(.*?)</a>#u', function ($m) use ($urlCatalogo) {
        return $urlCatalogo ? '<a href="' . e($urlCatalogo . $m[1]) . '">' . $m[2] . '</a>' : $m[2];
    }, $html);
}

// HTML completo del PDF con ambos documentos. $solicitud (opcional) = ['folio', 'email', 'fecha'] para identificar a quién se envió
function catLegalHtmlPdf(?array $solicitud = null, ?string $urlCatalogo = null): string {
    $docs = catLegalDocumentos();
    $logo = catLegalLogoPdf();
    $generado = catFecha(date('Y-m-d H:i:s'));
    $filas = '';
    foreach ($docs as $doc) {
        $filas .= '<tr><td><strong>' . e($doc['titulo']) . '</strong></td><td>' . e($doc['version']) . '</td><td>' . e(catLegalFecha($doc['vigencia']))
            . '</td><td class="huella">' . e(catLegalHuella($doc)) . '</td></tr>';
    }
    $cuerpo = '';
    $parte = 0;
    foreach ($docs as $doc) {
        $parte++;
        $indice = '';
        foreach ($doc['secciones'] as $i => $sec) $indice .= '<li>' . ($i + 1) . '. ' . e($sec['titulo']) . '</li>';
        $cuerpo .= '<div class="documento' . ($parte > 1 ? ' salto' : '') . '">'
            . '<div class="parte">Parte ' . ($parte === 1 ? 'I' : 'II') . '</div>'
            . '<h1>' . e($doc['titulo']) . '</h1>'
            . '<div class="meta">Versión ' . e($doc['version']) . ' · Vigente desde el ' . e(catLegalFecha($doc['vigencia'])) . ' · Huella SHA-256 ' . e(catLegalHuella($doc)) . '</div>'
            . '<div class="indice"><strong>Contenido</strong><ol>' . $indice . '</ol></div>';
        foreach ($doc['secciones'] as $i => $sec) {
            $cuerpo .= '<h2><span class="num">' . ($i + 1) . '.</span> ' . e($sec['titulo']) . '</h2>' . catLegalEnlacesPdf($sec['html'], $urlCatalogo);
        }
        $cuerpo .= '<div class="notas">' . $doc['notas'] . '</div></div>';
    }
    $destinatario = $solicitud
        ? '<p class="para">Documento enviado para la solicitud de registro <strong>' . e($solicitud['folio']) . '</strong> a <strong>' . e($solicitud['email']) . '</strong> el ' . e($solicitud['fecha']) . '.</p>'
        : '';

    return '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>
      @page { margin: 26mm 18mm 20mm 18mm; }
      body { font-family: Helvetica, Arial, sans-serif; font-size: 10.2px; color: #0d1320; line-height: 1.5; }
      #encabezado { position: fixed; top: -18mm; left: 0; right: 0; height: 12mm; border-bottom: 1.5px solid #10213f; }
      #encabezado img { height: 9mm; vertical-align: middle; }
      #encabezado .marca { font-size: 13px; font-weight: bold; color: #10213f; letter-spacing: 2px; margin-left: 6px; vertical-align: middle; }
      #encabezado .derecha { float: right; font-size: 8.5px; color: #4a5568; margin-top: 4mm; }
      #pie { position: fixed; bottom: -13mm; left: 0; right: 0; height: 8mm; border-top: 1px solid #e2e6ec; font-size: 8px; color: #636d7e; padding-top: 2mm; }
      .portada { border: 1px solid #e2e6ec; border-top: 4px solid #10213f; padding: 16px 18px; margin-bottom: 14px; background: #f6f7f9; }
      .portada .sobre { font-size: 8.5px; letter-spacing: 2px; text-transform: uppercase; color: #1f5bd8; font-weight: bold; }
      .portada h1 { font-size: 19px; margin: 4px 0 8px; color: #10213f; }
      .portada p { margin: 4px 0; color: #4a5568; }
      .portada .para { color: #0d1320; }
      table.versiones { width: 100%; border-collapse: collapse; margin: 10px 0 6px; font-size: 9.4px; }
      table.versiones th { text-align: left; background: #10213f; color: #ffffff; padding: 5px 7px; font-weight: bold; }
      table.versiones td { padding: 5px 7px; border-bottom: 1px solid #e2e6ec; background: #ffffff; }
      .huella { font-family: Courier, monospace; font-size: 8.6px; }
      .aviso-aceptacion { margin-top: 10px; padding: 8px 10px; border-left: 3px solid #1f5bd8; background: #ffffff; font-size: 9.4px; }
      .salto { page-break-before: always; }
      .parte { font-size: 8.5px; letter-spacing: 2px; text-transform: uppercase; color: #1f5bd8; font-weight: bold; }
      .documento h1 { font-size: 17px; color: #10213f; margin: 2px 0 2px; }
      .meta { font-size: 8.8px; color: #636d7e; margin-bottom: 8px; }
      .indice { border: 1px solid #e2e6ec; padding: 7px 12px; margin: 6px 0 10px; font-size: 9px; color: #4a5568; }
      .indice ol { margin: 4px 0 0; padding-left: 0; list-style: none; }
      h2 { font-size: 12px; color: #10213f; margin: 14px 0 5px; padding-bottom: 3px; border-bottom: 1px solid #e2e6ec; page-break-after: avoid; }
      h2 .num { color: #1f5bd8; }
      h3 { font-size: 10.6px; margin: 9px 0 3px; color: #0d1320; page-break-after: avoid; }
      p { margin: 4px 0 6px; }
      ul, ol { margin: 3px 0 7px; padding-left: 16px; }
      li { margin-bottom: 3px; }
      a { color: #1f5bd8; text-decoration: none; }
      .pendiente { background: #fff2dd; color: #9a5800; font-weight: bold; padding: 0 2px; }
      sup { font-size: 7px; }
      .notas { margin-top: 14px; padding-top: 8px; border-top: 1px dashed #c9d0da; }
      .nota-ficticia { font-size: 8.4px; color: #636d7e; margin: 3px 0; }
    </style></head><body>
      <div id="encabezado">' . ($logo ? '<img src="' . $logo . '" alt="KARMA">' : '') . '<span class="marca">KARMA</span>
        <span class="derecha">Aviso de Privacidad Integral y Términos y Condiciones</span></div>
      <div id="pie">KARMA · Catálogo en línea · Generado el ' . e($generado) . '</div>
      <div class="portada">
        <div class="sobre">Documentos para tu registro</div>
        <h1>Aviso de Privacidad Integral y Términos y Condiciones</h1>
        <p>Catálogo en línea de KARMA · ' . e(CAT_LEGAL_RAZON_SOCIAL) . '<sup>*</sup></p>
        ' . $destinatario . '
        <table class="versiones"><tr><th>Documento</th><th>Versión</th><th>Vigente desde</th><th>Huella SHA-256</th></tr>' . $filas . '</table>
        <div class="aviso-aceptacion"><strong>Cómo se aceptan:</strong> este PDF es informativo. Tu cuenta solo se crea si pulsas el botón «' . CAT_BOTON_ACEPTAR . '» del correo de confirmación y lo confirmas en la página de KARMA. Abrir el correo o descargar este archivo no equivale a aceptar.</div>
      </div>
      ' . $cuerpo . '
    </body></html>';
}

// Genera el PDF en memoria (no se escribe ningún archivo) y regresa sus bytes
function catLegalPdf(?array $solicitud = null, ?string $urlCatalogo = null): string {
    $autoload = dirname(__DIR__, 2) . '/PuntoDeVenta/vendor/autoload.php';
    if (!is_file($autoload)) throw new RuntimeException('Falta Dompdf: ejecuta "composer install" en PHP/PuntoDeVenta.');
    require_once $autoload;
    $opciones = new Dompdf\Options();
    $opciones->set('isRemoteEnabled', false);
    $opciones->set('defaultFont', 'Helvetica');
    $dompdf = new Dompdf\Dompdf($opciones);
    $dompdf->loadHtml(catLegalHtmlPdf($solicitud, $urlCatalogo), 'UTF-8');
    $dompdf->setPaper('letter', 'portrait');
    $dompdf->addInfo('Title', 'KARMA — Aviso de Privacidad Integral y Términos y Condiciones');
    $dompdf->addInfo('Author', CAT_LEGAL_RAZON_SOCIAL);
    $dompdf->render();
    // «Página N de M» alineado a la derecha del pie (Dompdf no resuelve counter(pages) dentro del CSS)
    $dompdf->getCanvas()->page_script(function (int $pagina, int $total, $canvas, $metricas) {
        $texto = "Página {$pagina} de {$total}";
        $fuente = $metricas->getFont('Helvetica');
        $ancho = $metricas->getTextWidth($texto, $fuente, 8);
        $canvas->text($canvas->get_width() - 51 - $ancho, $canvas->get_height() - 43, $texto, $fuente, 8, [0.39, 0.43, 0.49]);
    });
    return (string)$dompdf->output();
}

// Nombre del archivo PDF según las versiones vigentes (ej. karma-aviso-privacidad-v2.0-terminos-v2.0.pdf)
function catLegalNombrePdf(): string {
    $docs = catLegalDocumentos();
    return 'karma-aviso-privacidad-v' . $docs['aviso_privacidad']['version'] . '-terminos-v' . $docs['terminos_condiciones']['version'] . '.pdf';
}
