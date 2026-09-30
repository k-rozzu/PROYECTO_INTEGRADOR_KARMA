const formulario = document.querySelector(".login-form");

formulario.addEventListener("submit", async (event) => {
    event.preventDefault();

    const correo = document.getElementById("correo").value;
    const password = document.getElementById("password").value;

    try {
        const respuesta = await fetch("/api/login", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                correo: correo,
                password: password
            })
        });

        const datos = await respuesta.json();

        if (respuesta.ok) {
            alert(`Bienvenido, ${datos.usuario.nombre}`);

            console.log("Usuario autenticado:", datos.usuario);
        } else {
            alert(datos.mensaje);
        }

    } catch (error) {
        console.error("Error:", error);
        alert("No se pudo conectar con el servidor.");
    }
});