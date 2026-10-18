const formulario = document.querySelector(".login-form");

// Si se llega desde el botón "Punto de Venta" del Catálogo (index.html?destino=pos) se muestra el aviso de acceso
if (new URLSearchParams(window.location.search).get("destino") === "pos") {
    const aviso = document.getElementById("avisoDestino");
    if (aviso) aviso.hidden = false;
}

// Autenticación: en XAMPP usa PHP/Login/login.php (misma lógica que /api/login y además abre la sesión PHP del POS);
// si el proyecto corre con el servidor Node.js (puerto 3000), PHP no se ejecuta y se usa /api/login como antes.

async function autenticar(correo, password) {
    // Ruta relativa a index.html: funciona sin importar el nombre de la carpeta en htdocs
    const respuesta = await fetch("PHP/Login/login.php", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            correo: correo,
            password: password
        })
    });

    const tipo = respuesta.headers.get("content-type") || "";

    if (!tipo.includes("application/json")) {
        throw new Error(
            "PHP no devolvió JSON. Revisa login.php y la ruta solicitada."
        );
    }

    const datos = await respuesta.json();

    return {
        respuesta: respuesta,
        datos: datos
    };
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
