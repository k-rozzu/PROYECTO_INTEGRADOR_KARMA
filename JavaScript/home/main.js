// main.js

// === PREFERENCIAS COMPARTIDAS CON LOS DEMÁS MÓDULOS (POS, paneles de administrador y gerente) ===
// Tema: 'light' | 'dark'   ·   Idioma: 'es' | 'en' (la misma llave que usa JavaScript/Traduccion/traductor.js)
const CLAVE_TEMA = 'karma_tema';
const CLAVE_IDIOMA = 'karma_idioma';

// Pasa las llaves antiguas del Home a las compartidas, para no perder lo que ya se había elegido
try {
    if (!localStorage.getItem(CLAVE_TEMA) && localStorage.getItem('karma_theme')) localStorage.setItem(CLAVE_TEMA, localStorage.getItem('karma_theme'));
    if (!localStorage.getItem(CLAVE_IDIOMA) && localStorage.getItem('karma_lang')) localStorage.setItem(CLAVE_IDIOMA, localStorage.getItem('karma_lang'));
    localStorage.removeItem('karma_theme');
    localStorage.removeItem('karma_lang');
} catch (_) { /* navegador sin almacenamiento */ }

// === PROTECCIÓN CONTRA BOTÓN "ATRÁS" (BFCache) ===
// Revisa la sesión de inmediato cuando la página se muestra, incluso si viene de la caché del navegador
window.addEventListener('pageshow', function (event) {
    if (!localStorage.getItem("karma_user")) {
        window.location.replace("../index.html");
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
        window.location.replace("../index.html"); 
        return;
    }
    const usuario = JSON.parse(userDataString);

    // Aplica el tema guardado de inmediato, antes de cargar la navbar, para que no se vea un destello claro
    document.body.classList.toggle('dark-mode', localStorage.getItem(CLAVE_TEMA) === 'dark');

    // === DICCIONARIO EN MEMORIA ===
    const translations = {
        es: {
            "top_sellers": "Los más vendidos",
            "catalog": "Catálogo completo",
            "start_sale": "Iniciar Venta",
            "manage_branch": "Gestionar Sucursal",
            "manager_panel": "Panel de Gerente",
            "flip_info": "Ver especificaciones",
            "engine": "Motor",
            "displacement": "Cilindraje",
            "detail": "Detalle",
            "logout": "Cerrar Sesión",
            "load_error": "No se pudieron cargar los vehículos. Revisa la conexión con el servidor e inténtalo de nuevo."
        },
        en: {
            "top_sellers": "Best sellers",
            "catalog": "Full catalog",
            "start_sale": "Start Sale",
            "manage_branch": "Manage Branch",
            "manager_panel": "Manager Panel",
            "flip_info": "View specifications",
            "engine": "Engine",
            "displacement": "Displacement",
            "detail": "Detail",
            "logout": "Log Out",
            "load_error": "The vehicles could not be loaded. Check the server connection and try again."
        }
    };

    let currentLang = localStorage.getItem(CLAVE_IDIOMA) === 'en' ? 'en' : 'es';

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

    // === 5. LÓGICA DE MODO OSCURO ===
    const themeSwitch = document.querySelector('.theme-switch__checkbox');
    
    if (themeSwitch) {
        const savedTheme = localStorage.getItem(CLAVE_TEMA);
        if (savedTheme === 'dark') {
            document.body.classList.add('dark-mode');
            themeSwitch.checked = true;
        }

        themeSwitch.addEventListener('change', function() {
            const oscuro = this.checked;
            const aplicarTema = () => {
                document.body.classList.toggle('dark-mode', oscuro);
                localStorage.setItem(CLAVE_TEMA, oscuro ? 'dark' : 'light');
            };

            // Navegadores sin View Transitions o con animaciones reducidas: cambio directo
            const sinAnimacion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            if (!document.startViewTransition || sinAnimacion) {
                aplicarTema();
                return;
            }

            // El tema nuevo aparece en un círculo que crece desde el switch hasta cubrir la pantalla
            const rect = this.closest('.theme-switch').getBoundingClientRect();
            const x = rect.left + rect.width / 2;
            const y = rect.top + rect.height / 2;
            const radio = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));

            document.startViewTransition(aplicarTema).ready.then(() => {
                document.documentElement.animate(
                    { clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${radio}px at ${x}px ${y}px)`] },
                    { duration: 650, easing: 'cubic-bezier(.4, 0, .2, 1)', pseudoElement: '::view-transition-new(root)' }
                );
            });
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
            // También cierra la sesión PHP del Punto de Venta; si falla, igual se regresa al login
            fetch('../PHP/PuntoDeVenta/api.php?action=logout').finally(() => {
                // Replace elimina la página actual del historial
                window.location.replace("../index.html");
            });
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
            localStorage.setItem(CLAVE_IDIOMA, currentLang);
            updateLanguage(currentLang);
        });
    }

    // Al volver con "Atrás" desde otro módulo el navegador restaura la página de su caché:
    // se vuelven a aplicar el tema y el idioma por si se cambiaron en esa otra página
    window.addEventListener('pageshow', (event) => {
        if (!event.persisted) return;
        const oscuro = localStorage.getItem(CLAVE_TEMA) === 'dark';
        document.body.classList.toggle('dark-mode', oscuro);
        if (themeSwitch) themeSwitch.checked = oscuro;
        const idioma = localStorage.getItem(CLAVE_IDIOMA) === 'en' ? 'en' : 'es';
        if (idioma !== currentLang) {
            currentLang = idioma;
            if (langSwitch) langSwitch.checked = (idioma === 'en');
            updateLanguage(idioma);
        }
    });

    // === 4. CARGAR PRODUCTOS DESDE LA BASE DE DATOS NODE.JS ===
    async function loadProducts() {
        try {
            const response = await fetch('../PHP/Home/productos.php');
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
                    // En la BD las rutas empiezan con "/assets/...": se vuelven relativas a Home/ para que funcionen en cualquier carpeta
                    const imgSrc = prod.imagen_path ? '..' + prod.imagen_path : '../assets/inventario/porsche-911.png';
                    
                    const cardHTML = `
                    <div class="card" tabindex="0">
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
                mostrarErrorProductos();
            }
        } catch (error) {
            console.error('Error de red al cargar productos:', error);
            mostrarErrorProductos();
        }
    }

    // Muestra un aviso en lugar de dejar la página vacía si no llegaron los productos
    function mostrarErrorProductos() {
        const catalogContainer = document.getElementById('catalog-container');
        if (catalogContainer) {
            catalogContainer.innerHTML = `<p class="products-error">${translations[currentLang].load_error}</p>`;
        }
    }

    // Llamar a la función para cargar los productos
    loadProducts();
});