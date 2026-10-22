// main.js

// === PROTECCIÓN CONTRA BOTÓN "ATRÁS" (BFCache) ===
// Revisa la sesión de inmediato cuando la página se muestra, incluso si viene de la caché del navegador
window.addEventListener('pageshow', function (event) {
    if (!localStorage.getItem("karma_user")) {
        window.location.replace("/index.html");
    }
});

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
    // === 0. VERIFICAR SESIÓN Y OBTENER DATOS ===
    const userDataString = localStorage.getItem("karma_user");
    if (!userDataString) {
        // Redirección sin guardar el intento en el historial
        window.location.replace("/index.html"); 
        return;
    }
    const usuario = JSON.parse(userDataString);

    // === DICCIONARIO EN MEMORIA ===
    const translations = {
        es: {
            "top_sellers": "Los más vendidos:",
            "catalog": "Catálogo Completo",
            "start_sale": "Iniciar Venta",
            "manage_branch": "Gestionar Sucursal",
            "flip_info": "Gira para más info ↺",
            "engine": "Motor",
            "displacement": "Cilindraje",
            "detail": "Detalle",
            "logout": "Cerrar Sesión"
        },
        en: {
            "top_sellers": "Best Sellers:",
            "catalog": "Full Catalog",
            "start_sale": "Start Sale",
            "manage_branch": "Manage Branch",
            "flip_info": "Flip for more info ↺",
            "engine": "Engine",
            "displacement": "Displacement",
            "detail": "Detail",
            "logout": "Log Out"
        }
    };

    let currentLang = localStorage.getItem('karma_lang') || 'es';

    function updateLanguage(lang) {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (translations[lang] && translations[lang][key]) {
                // Preservar iconos si existen (como en el botón de cerrar sesión)
                if (el.querySelector('svg')) {
                    const svg = el.querySelector('svg').outerHTML;
                    el.innerHTML = svg + ' ' + translations[lang][key];
                } else {
                    el.textContent = translations[lang][key];
                }
            }
        });
        
        // Volver a renderizar productos si ya están cargados para traducir sus etiquetas dinámicas
        if (document.getElementById('top-sellers-container') && document.getElementById('top-sellers-container').innerHTML !== '') {
            loadProducts();
        }
    }

    // === 1. Cargar Navbar y Footer y esperar a que terminen ===
    await loadComponent('navbar.html', 'navbar-placeholder');
    await loadComponent('footer.html', 'footer-placeholder');

    const enlaceGestion = document.querySelector('a[href*="admin.html"]');
    if (enlaceGestion && usuario.rol === "Gerente") {
        enlaceGestion.href = "/Home/gerente.html";
    }

    // === 5. LÓGICA DE MODO OSCURO ===
    const themeSwitch = document.querySelector('.theme-switch__checkbox');
    
    if (themeSwitch) {
        const savedTheme = localStorage.getItem('karma_theme');
        if (savedTheme === 'dark') {
            document.body.classList.add('dark-mode');
            themeSwitch.checked = true;
        }

        themeSwitch.addEventListener('change', function() {
            if (this.checked) {
                document.body.classList.add('dark-mode');
                localStorage.setItem('karma_theme', 'dark');
            } else {
                document.body.classList.remove('dark-mode');
                localStorage.setItem('karma_theme', 'light');
            }
        });
    }

    // === MOSTRAR NOMBRE Y ROL DINÁMICO ===
    const footerUserInfo = document.getElementById('footer-user-info');
    if (footerUserInfo) {
        footerUserInfo.textContent = `${usuario.rol}: ${usuario.nombre}`;
    }
    
    const navUserName = document.getElementById('nav-user-name');
    if (navUserName) {
        navUserName.textContent = usuario.nombre;
    }

    // === LÓGICA DE CERRAR SESIÓN SEGURA ===
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.removeItem("karma_user"); 
            // Replace elimina la página actual del historial
            window.location.replace("/index.html");  
        });
    }

    // === 2. Inicializar lógica del Menú de Perfil ===
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

    document.addEventListener('click', function (event) {
        if (!event.target.closest('.profile-dropdown-container')) {
            closeProfileMenu();
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') closeProfileMenu();
    });

    // === 3. Inicializar lógica del Reloj del Footer ===
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
        
        updateClock(); 
        setInterval(updateClock, 1000); 
    }

    // === 6. LÓGICA DE IDIOMA ===
    const langSwitch = document.querySelector('.lang-switch__checkbox');
    if (langSwitch) {
        langSwitch.checked = (currentLang === 'en');
        // Usar setTimeout para asegurar que los elementos del navbar estén en el DOM
        setTimeout(() => updateLanguage(currentLang), 100);

        langSwitch.addEventListener('change', function() {
            currentLang = this.checked ? 'en' : 'es';
            localStorage.setItem('karma_lang', currentLang);
            updateLanguage(currentLang);
        });
    }

    // === 4. CARGAR PRODUCTOS DESDE LA BASE DE DATOS NODE.JS ===
    async function loadProducts() {
        try {
            const response = await fetch('/api/productos'); 
            if (response.ok) {
                const productos = await response.json();
                
                const topSellersContainer = document.getElementById('top-sellers-container');
                const catalogContainer = document.getElementById('catalog-container');

                if (!topSellersContainer || !catalogContainer) return;

                topSellersContainer.innerHTML = '';
                catalogContainer.innerHTML = '';

                // Tomamos los primeros 3 para top sellers y el resto para el catálogo
                const topSellers = productos.slice(0, 3);
                const catalog = productos.slice(3);

                // Generar tarjetas para Top Sellers (Giratorias)
                topSellers.forEach(prod => {
                    const imgSrc = prod.imagen_path || '/assets/home/porsche-911.png'; 
                    
                    const cardHTML = `
                    <div class="card">
                        <div class="content">
                            <div class="face face-front">
                                <h2 class="car-title">${prod.marca || ''} ${prod.modelo || ''}</h2>
                                <div class="image-wrapper"><img src="${imgSrc}" alt="${prod.modelo}" class="car-image"></div>
                                <span class="hover-indicator">${translations[currentLang].flip_info}</span>
                            </div>
                            <div class="face face-back">
                                <h2 class="car-title-back">${prod.marca || ''} ${prod.modelo || ''}</h2>
                                <div class="car-info">
                                    <div class="info-row"><span>${translations[currentLang].engine}</span><strong>${prod.motor || 'N/A'}</strong></div>
                                    <div class="info-row"><span>${translations[currentLang].displacement}</span><strong>${prod.cilindraje || 'N/A'}</strong></div>
                                    <div class="info-row"><span>${translations[currentLang].detail}</span><strong>${prod.detalle || 'Estándar'}</strong></div>
                                </div>
                            </div>
                        </div>
                    </div>`;
                    topSellersContainer.innerHTML += cardHTML;
                });

                // Generar tarjetas para Catálogo Completo (Liquid Glass)
                catalog.forEach(prod => {
                    const glassHTML = `
                    <div class="card-glass">
                        <div class="glass-bg-shapes">
                            <div class="shape shape-1"></div>
                            <div class="shape shape-2"></div>
                        </div>
                        <div class="glass-front">
                            <h2 class="glass-title">${prod.marca || ''} <br> ${prod.modelo || ''}</h2>
                            <div class="glass-specs">
                                <div class="spec-item"><span>${translations[currentLang].engine}</span><strong>${prod.motor || 'N/A'}</strong></div>
                                <div class="spec-item"><span>${translations[currentLang].displacement}</span><strong>${prod.cilindraje || 'N/A'}</strong></div>
                                <div class="spec-item"><span>${translations[currentLang].detail}</span><strong>${prod.detalle || 'Estándar'}</strong></div>
                            </div>
                        </div>
                    </div>`;
                    catalogContainer.innerHTML += glassHTML;
                });

            } else {
                console.error('Error al obtener los productos del servidor');
            }
        } catch (error) {
            console.error('Error de red al cargar productos:', error);
        }
    }

    // Llamar a la función para cargar los productos
    loadProducts();
});