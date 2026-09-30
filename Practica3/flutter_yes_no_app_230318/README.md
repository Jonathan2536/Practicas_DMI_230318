# Práctica 03 · Yes No App 👽

## Descripción

**Yes No App** es una aplicación de chat desarrollada en Flutter. Cuando el usuario envía una pregunta que termina en `?`, el sistema responde *Sí*, *No* o *Tal vez*. La elección se realiza de manera local con una distribución probabilística de **40 % Sí**, **40 % No** y **20 % Tal vez**. Además, la aplicación consulta la API externa de [yesno.wtf](https://yesno.wtf/) para obtener y mostrar un GIF animado correspondiente a la respuesta obtenida.

---

## Objetivos de la práctica

- Crear e integrar un **ícono personalizado** que se muestre en la pantalla de inicio del dispositivo al abrir la aplicación.
- Implementar la lógica de respuestas probabilísticas (**40 % Sí**, **40 % No**, **20 % Tal vez**) acompañadas de sus respectivos GIFs.
- Diseñar burbujas de chat con estilo tipo WhatsApp que incluyan la **hora exacta de envío** de cada mensaje.

---

## Funcionalidades

- **Mensajes en tiempo real:** Permite redactar y visualizar mensajes con formato claro y la hora de envío registrada.
- **Respuestas automáticas:** Al detectar un signo de interrogación (`?`) al final del mensaje, la aplicación genera automáticamente una respuesta basada en la distribución 40/40/20.
- **Integración con API:** Consulta `yesno.wtf` para descargar y renderizar un GIF acorde a la respuesta. Si la imagen no logra cargarse, se mantiene la respuesta en formato de texto.
- **Indicadores de estado (Simulación):** Muestra palomitas de *enviado*, *entregado* y *visto* simuladas dentro de la lógica interna de la aplicación.

---

## Evidencias

*A continuación se presentan las capturas de pantalla de la aplicación en funcionamiento:*

### Ícono personalizado al iniciar
![Ícono personalizado](/Practica3/flutter_yes_no_app_230318/src/Icono.png)

### Chat y hora de envío
![Chat y hora](/Practica3/flutter_yes_no_app_230318/src/Hora.png)

### Respuesta "Sí" con GIF
![Respuesta Sí](/Practica3/flutter_yes_no_app_230318/src/Hora.png)

### Respuesta "No" con GIF
![Respuesta No](/Practica3/flutter_yes_no_app_230318/src/No.png)

### Respuesta "Tal vez" con GIF
![Respuesta Tal vez](ruta/a/tu/imagen_respuesta_tal_vez.png)

---

## Tecnologías utilizadas

| Tecnología | Función en la práctica |
| :--- | :--- |
| **Flutter** | Construcción de la aplicación multiplataforma. |
| **Dart** | Lenguaje de programación principal de la app. |
| **Provider / State Management** | Gestión del estado y manejo de la lista de mensajes. |
| **HTTP (Package)** | Peticiones HTTP para consumir la API externa. |
| **YesNo API (`yesno.wtf`)** | Servicio que proporciona los GIFs animados según la respuesta. |
| **Mermaid / HTML / CSS** | Generación de la arquitectura interactiva. |
| **GitHub Pages** | Publicación y hosting del diagrama de arquitectura HTML. |

---

## Arquitectura interactiva

Puedes explorar la arquitectura y el flujo de componentes de la **Práctica 03** a través del siguiente enlace:

👉 [Ver la arquitectura interactiva en GitHub Pages](https://tu-usuario.github.io/tu-repositorio)

El diagrama explica detalladamente el flujo del chat, la jerarquía de widgets/componentes y el soporte multi-plataforma (Android, iOS, Web, Windows, Linux y macOS). Al hacer clic en un bloque, podrás consultar su descripción y acceder directamente al archivo fuente correspondiente en este repositorio.

> **Nota:** También puedes abrir directamente el archivo HTML de la arquitectura que se encuentra en la carpeta del proyecto haciendo doble clic en él desde tu navegador preferido, sin necesidad de ejecutar el entorno de Flutter.