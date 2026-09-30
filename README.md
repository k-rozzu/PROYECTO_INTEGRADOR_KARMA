# Karma

**Sistema web de punto de venta e inventario multi-sede para una concesionaria de vehículos.**

## 📋 Descripción

**Karma** es una aplicación web de punto de venta e inventario **multi-sede**, desarrollada para la gestión centralizada de una concesionaria de vehículos.

El sistema busca integrar en una misma plataforma la administración de **sucursales, vehículos, inventario, clientes, ventas, pagos y usuarios**, facilitando la organización y gestión de la información de las diferentes sucursales.

La aplicación contempla diferentes roles de usuario y mecanismos de control de acceso, de acuerdo con las responsabilidades establecidas para cada integrante dentro de la organización.

Entre las funcionalidades desarrolladas se encuentran el **inicio de sesión, control de acceso, dashboard administrativo, interfaz de punto de venta para cajeros, consulta de inventario, gestión de clientes y créditos, procesamiento de ventas y pagos, gestión de garantías y seguimiento de órdenes realizadas mediante la plataforma web**.

---
## 🎯 Objetivo general

Desarrollar una aplicación web de punto de venta e inventario multi-sede para una concesionaria de vehículos, que permita:

* Administrar de manera centralizada las diferentes sucursales de la empresa.
* Controlar el inventario de vehículos y refacciones disponible en cada sucursal.
* Registrar y gestionar las ventas realizadas.
* Gestionar información de clientes y operaciones a crédito.
* Facilitar el registro y seguimiento de pagos.
* Gestionar garantías relacionadas con vehículos y refacciones.
* Establecer diferentes niveles de acceso de acuerdo con el rol de cada usuario.
* Centralizar la información necesaria para la operación de las sucursales.

---
## ⚙️ Funcionalidades principales

### 🔐 Inicio de sesión

El sistema cuenta con una funcionalidad de inicio de sesión que permite al usuario ingresar mediante su correo electrónico y contraseña.

La autenticación se realiza mediante una solicitud al servidor utilizando una API desarrollada con **Node.js**, donde se procesan las credenciales proporcionadas y se determina si el usuario puede acceder al sistema.

<img width="1300" height="400" alt="Karma_login" src="https://github.com/user-attachments/assets/f8d615cd-8146-4c2c-8ee5-19444c7f058f" />

### 📊 Administración

El sistema cuenta con un **dashboard para el administrador general**, integrado con la estructura general del punto de venta.

El acceso a esta sección se encuentra restringido de acuerdo con el rol del usuario, permitiendo que únicamente los usuarios con los permisos correspondientes puedan acceder a las funcionalidades administrativas.

<img width="1300" height="400" alt="Karma_dashboard" src="https://github.com/user-attachments/assets/c3373974-b042-4ba6-8075-65e601d52178" />


### 🛒 Punto de venta

La interfaz del punto de venta está orientada principalmente a los cajeros y permite:

* Consultar el inventario disponible.
* Consultar información de clientes.
* Consultar clientes con crédito activo.
* Consultar garantías vigentes.
* Registrar información relacionada con garantías.
* Dar seguimiento a órdenes realizadas mediante la plataforma web.
* Procesar el cobro de vehículos y refacciones.
* Combinar diferentes métodos de pago en una misma operación.
* Registrar ventas a crédito.

La interfaz también incorpora elementos de apoyo para la operación, como la identificación del cajero y sucursal, estado de caja, hora local, barra de búsqueda y modo oscuro.

<img width="1300" height="400" alt="Karma_modulo_cajero" src="https://github.com/user-attachments/assets/f0fd3323-7cf1-4ecb-9cd8-fc79b39fda04" />


### 💳 Pagos

El proyecto contempla la integración de pagos mediante **PayPal**, utilizando módulos desarrollados en **PHP** para establecer la comunicación correspondiente con el servicio.

Esta integración permite incorporar el procesamiento de pagos electrónicos dentro del flujo del punto de venta.

## 🗄️ Base de datos

Karma utiliza **MySQL** como sistema gestor de bases de datos para almacenar, organizar y consultar la información necesaria para el funcionamiento del sistema.

La estructura de la base de datos contempla información relacionada con:

* Usuarios y roles.
* Sucursales.
* Vehículos.
* Inventario.
* Clientes.
* Ventas.
* Pagos.
* Créditos.
* Garantías.
* Órdenes.

Las tablas y relaciones se establecen de acuerdo con los requerimientos y funcionalidades contempladas para el sistema.

---
## 🛠️ Tecnologías y herramientas utilizadas

### Node.js

**Node.js** se utiliza para desarrollar la lógica del servidor relacionada con el inicio de sesión. La aplicación recibe las solicitudes de autenticación mediante una API y procesa las credenciales proporcionadas por el usuario.

### PHP

**PHP** se utiliza actualmente para implementar los módulos relacionados con la integración de pagos mediante **PayPal**, permitiendo establecer la comunicación necesaria con el servicio de pagos.

### MySQL

**MySQL** se utiliza como sistema gestor de bases de datos para almacenar, organizar y consultar la información del sistema.

### HTML, CSS y JavaScript

Estas tecnologías se utilizan para desarrollar la interfaz y las funcionalidades del lado del cliente:

* **HTML:** estructura el contenido de las páginas.
* **CSS:** define el diseño y la presentación visual.
* **JavaScript:** implementa funcionalidades de interacción y comunicación con los servicios del sistema, incluyendo las solicitudes realizadas a la API de autenticación.

### XAMPP

**XAMPP** se utiliza como entorno de desarrollo local para ejecutar y probar diferentes componentes del proyecto, principalmente aquellos relacionados con PHP y MySQL.

### GitHub

**GitHub** se utiliza para almacenar y administrar el código fuente del proyecto, además de facilitar el trabajo colaborativo y el control de versiones entre los integrantes del equipo.

### Figma

**Figma** se utiliza para el diseño y prototipado de la interfaz de usuario. Permite elaborar mockups, diseñar las diferentes vistas del sistema y visualizar los flujos de interacción antes de implementar las interfaces.

---
## 📊 Gestión del proyecto

### Jira

Para la gestión y organización del proyecto se utiliza **Jira**, siguiendo la metodología **Scrum**.

Jira permite organizar las actividades del equipo mediante:

* Creación y asignación de tareas.
* Establecimiento de fechas límite.
* Organización del trabajo mediante **Sprints**.
* Seguimiento del progreso.
* Visualización de las tareas mediante tableros y vistas de Sprint.

El uso de Scrum y Jira permite distribuir las actividades entre los integrantes del equipo y realizar un seguimiento del desarrollo durante las diferentes etapas del proyecto.

---
## 📚 Documentación

La documentación del proyecto incluye información relacionada con:

* Anteproyecto.
* Requerimientos del sistema.
* Diseño y estructura de la base de datos.
* Diseño de interfaces.
* Avances del desarrollo.
* Implementación de funcionalidades.
* Gestión y seguimiento del proyecto.

---
## 👥 Integrantes del equipo

* **Ibarra Heredia Alan Alejandro**
* **Vazquez Atanacio Diego Alejandro**
* **Martinez Zuñiga Carolina**
* **Nava Montiel Miranda Lizet**
* **Nava Montiel Dana Paola**
