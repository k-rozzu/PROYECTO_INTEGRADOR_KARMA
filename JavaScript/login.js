const formulario = document.querySelector(".login-form");

// Si se llega desde el botón "Punto de Venta" del Catálogo (index.html?destino=pos) se muestra el aviso de acceso
if (new URLSearchParams(window.location.search).get("destino") === "pos") {
    const aviso = document.getElementById("avisoDestino");
    if (aviso) aviso.hidden = false;
}

// Autenticación: en XAMPP usa PHP/Login/login.php (misma lógica que /api/login y además abre la sesión PHP del POS);
// si el proyecto corre con el servidor Node.js (puerto 3000), PHP no se ejecuta y se usa /api/login como antes.
// La ruta es relativa a index.html para que funcione sin importar cómo se llame la carpeta del proyecto en htdocs.
async function autenticar(correo, password) {
    const opciones = {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo: correo, password: password })
    };
    try {
        const respuestaPhp = await fetch("PHP/Login/login.php", opciones);
        const tipo = respuestaPhp.headers.get("content-type") || "";
        if (tipo.includes("application/json")) {
            return { respuesta: respuestaPhp, datos: await respuestaPhp.json() };
        }
    } catch (_) { /* sin PHP disponible: se intenta con Node */ }
    const respuestaNode = await fetch("/api/login", opciones);
    return { respuesta: respuestaNode, datos: await respuestaNode.json() };
}


formulario.addEventListener("submit", async (event) => {
    event.preventDefault();

    const correo = document.getElementById("correo").value;
    const password = document.getElementById("password").value;

    try {
        const { respuesta, datos } = await autenticar(correo, password);

        if (respuesta.ok) {
            alert(`Bienvenido, ${datos.usuario.nombre}`);
            console.log("Usuario autenticado:", datos.usuario);

            // 1. Guardamos el usuario en localStorage
            localStorage.setItem("karma_user", JSON.stringify(datos.usuario));

            // 2. Evaluamos el rol para la redirección (rutas relativas: funcionan en XAMPP y en Node)
            const rol = datos.usuario.rol;

            if (rol === "Cajero") {
                window.location.href = "PHP/PuntoDeVenta/index.php";
            } else if (rol === "Administrador General" || rol === "Gerente") {
                // Redirige al Home
                window.location.href = "Home/home.html";
            } else {
                alert("Tu rol no tiene una pantalla asignada aún.");
            }
        } else {
            alert(datos.mensaje);
        }

    } catch (error) {
        console.error("Error:", error);
        alert("No se pudo conectar con el servidor.");
    }
});
