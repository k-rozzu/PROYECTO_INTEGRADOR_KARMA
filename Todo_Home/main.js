// main.js

// Función para cargar un archivo HTML en un contenedor
async function loadComponent(file, elementId) {
    try {
        const response = await fetch(file, { cache: "no-store" });
        if (response.ok) {
            const content = await response.text();
            document.getElementById(elementId).innerHTML = content;
        } else {
            console.error(`No se pudo cargar ${file}`);
        }
    } catch (error) {
        console.error(`Error al cargar ${file}:`, error);
    }
}

// Inicializar la aplicación cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', async () => {
    // 1. Cargar Navbar y Footer y esperar a que terminen
    await loadComponent('navbar.html', 'navbar-placeholder');
    await loadComponent('footer.html', 'footer-placeholder');

    // 2. Inicializar lógica del Menú de Perfil
    const profileContainer = document.getElementById('profileDropdown');
    const profileTrigger = document.getElementById('profileTrigger');

    if (profileTrigger && profileContainer) {
        profileTrigger.addEventListener('click', function(event) {
            event.stopPropagation();
            const isOpen = profileContainer.classList.toggle('open');
            profileTrigger.setAttribute('aria-expanded', String(isOpen));
        });
    }

    function closeProfileMenu() {
        if (profileContainer) profileContainer.classList.remove('open');
        if (profileTrigger) profileTrigger.setAttribute('aria-expanded', 'false');
    }

    // Cerrar si se hace clic fuera del menú
    document.addEventListener('click', function (event) {
        if (!event.target.closest('.profile-dropdown-container')) {
            closeProfileMenu();
        }
    });

    // Cerrar con la tecla Escape
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') closeProfileMenu();
    });

    // 3. Inicializar lógica del Reloj del Footer (solo si existe el elemento)
    const timeElement = document.getElementById('current-time');
    if (timeElement) {
        function updateClock() {
            const now = new Date();
            let hours = now.getHours();
            let minutes = String(now.getMinutes()).padStart(2, '0');
            const ampm = hours >= 12 ? 'pm' : 'am';
            
            hours = String(hours).padStart(2, '0');
            timeElement.textContent = `${hours}:${minutes} ${ampm}`;
        }
        
        updateClock(); // Llamada inicial
        setInterval(updateClock, 1000); // Actualización cada segundo
    }
});