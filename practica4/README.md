# TokTik — Práctica 04

## 1. Información general

TokTik es una aplicación Flutter de reproducción de videos en formato vertical,
con feeds de descubrimiento y preferencias de usuario. La práctica integra
reproducción multimedia, carga de metadatos desde varias fuentes, persistencia
local y personalización estacional de la pantalla de inicio y del icono Android.

- **Nombre:** TokTik — Práctica 04.
- **Objetivo:** explorar videos en feeds verticales, organizar contenido en
  Discover, For You y Favorites, y conectar reproductores con diferentes
  proveedores.
- **Tecnologías:** Flutter y Dart; Provider; `video_player`;
  `youtube_player_iframe`; `webview_flutter`; `http`; `shared_preferences`;
  `audioplayers`; `flutter_dotenv`.
- **Versión declarada en `pubspec.yaml`:** `1.0.0+1`.
- **Funcionamiento resumido:** al iniciar, la aplicación carga configuración y
  preferencias locales, construye el repositorio de videos, obtiene contenido
  de las fuentes conectadas y presenta la pantalla Discover después del splash.

La versión de Flutter instalada en otro equipo debe incluir una versión de Dart
compatible con la restricción `sdk: ^3.13.2` de `pubspec.yaml`.

## 2. Funcionalidades implementadas

- **Discover, For You y Favorites:** tres secciones dentro de la pantalla
  Discover. For You ordena por vistas y likes; Favorites muestra publicaciones
  marcadas como favoritas.
- **Navegación:** desplazamiento horizontal entre secciones y desplazamiento
  vertical de videos mediante `PageView`.
- **Reproducción:** `video_player` para videos directos/Local y Pixabay,
  `youtube_player_iframe` para YouTube y `webview_flutter` para Vimeo.
- **Controles:** play/pausa, reintento y control de sonido. El helper de
  reproducción inicia YouTube y videos directos sin mute, mientras que Vimeo
  comienza muteado por compatibilidad con reproducción embebida. La salida de
  audio real depende también de las políticas de cada reproductor y dispositivo.
- **Likes y favoritos:** cambios persistidos localmente con
  `SharedPreferences`, indexados por identificador estable del video.
- **Texto expandible:** el caption se muestra en una vista previa de dos líneas
  y puede abrirse completo en una hoja inferior desplazable.
- **Temas:** Normal, Halloween, Christmas (Navidad) y Valentine's Day
  (San Valentín), con logos y audio estacional.
- **Temporadas:** modo automático basado en la fecha del dispositivo y selección
  manual persistida; volver a Automático elimina la selección manual.
- **Fuentes activas:** Local (registros con URLs remotas de Google Drive),
  YouTube, Pixabay y Vimeo opcional. Instagram permanece como integración
  preparada/no activa, no como fuente conectada.
- **Fallos parciales:** el repositorio intenta las fuentes concurrentemente,
  intercala resultados y conserva las fuentes que sí cargaron si otra falla.
  Cuando ninguna devuelve videos, la pantalla ofrece reintento.

Los tests widget/unitarios comprueban distintos flujos de estas funciones; no
sustituyen la verificación de reproducción real en un dispositivo Android.

## 3. Arquitectura del proyecto

La composición principal está en `lib/main.dart`. Allí se inicializa
`AppConfig`, `SharedPreferencesStorageService`, los Providers y el cliente HTTP;
se construye `VideoPostRepositoryImpl` con Local, YouTube, Pixabay y Vimeo.

- **Presentación:** `lib/presentation/screens/` organiza splash y Discover;
  `lib/presentation/widgets/` contiene el feed, controles, captions y player.
- **Estado (Provider):** `DiscoverProvider` coordina carga, orden de For You,
  favoritos, likes y exclusión temporal de videos incompatibles.  
  `SeasonalThemeProvider` mantiene la selección estacional manual o automática.
- **Dominio:** `VideoPost`, `VideoPostDataSource`,
  `VideoPostRepository` y `LocalStorageService` definen entidades y contratos.
- **Infraestructura:** los DataSources implementan la obtención de contenido;
  `VideoPostRepositoryImpl` carga fuentes en paralelo, intercala resultados,
  elimina IDs duplicados y conserva diagnósticos de fallos parciales.
- **Modelos/mappers:** `LocalVideoModel.fromJson` transforma registros Local en
  entidades `VideoPost`. Los DataSources remotos validan y mapean sus respuestas
  dentro de su implementación.
- **Persistencia:** `SharedPreferencesStorageService` guarda likes, favoritos y
  el override estacional.

### Diagramas de arquitectura

Los diagramas SVG ya existen en estas rutas relativas:

- Provider local y persistencia:
  ![Arquitectura del Provider local](<Diagrama de arquitectura local/arquitectura-provider-local.svg>)
- Provider, repositorio y DataSources:
  ![Arquitectura del Provider con repositorio y DataSources](<Diagrama con Repository y DataSources/arquitectura-provider-repository-datasources.svg>)

Las rutas sugeridas `docs/diagrams/*.png` no existen actualmente; se enlazan los
SVG existentes y no se crean imágenes duplicadas.

## 4. Requisitos y dependencias

- Flutter instalado y Dart compatible con `^3.13.2`.
- Android Studio/SDK o un dispositivo Android con depuración habilitada para
  ejecución local Android.
- Conexión a Internet para YouTube, Pixabay, Vimeo y las URLs de Google Drive.
- Variables de configuración para las APIs externas, descritas abajo.
- Dependencias principales, según `pubspec.yaml`:
  `provider`, `video_player`, `youtube_player_iframe`, `webview_flutter`,
  `http`, `shared_preferences`, `audioplayers`, `flutter_dotenv` e `intl`.
- Recursos incluidos: cuatro imágenes de logo en `assets/images/` y cuatro
  audios estacionales en `assets/audio/`.

## 5. Configuración local

### Configuración de servicios externos

Desde PowerShell, en la raíz de este proyecto, crea el archivo de configuración
local a partir de la plantilla:

```powershell
Copy-Item .env.example .env
```

Completa los valores requeridos únicamente en el `.env` local:

- `YOUTUBE_API_KEY`
- `YOUTUBE_PLAYLIST_ID`
- `PIXABAY_API_KEY`
- `VIMEO_VIDEO_URLS` (opcional; URLs públicas de páginas de Vimeo separadas
  por comas)

La aplicación carga `.env` como asset de Flutter al iniciar. YouTube y Pixabay
requieren sus variables correspondientes cuando se consultan; Vimeo no requiere
una clave API, pero necesita URLs configuradas para cargar contenido. Los valores
no deben copiarse al README ni compartirse. El repositorio conserva las fuentes
que cargaron correctamente si otra fuente falla.

No publiques ni compartas `.env`. `.env.example` contiene nombres de variables
con valores vacíos. Aunque `.env` esté ignorado por Git, `pubspec.yaml` lo incluye
como asset: las claves empaquetadas en Flutter pueden extraerse del APK y no son
secretas en una aplicación distribuida. Para producción, conserva credenciales
en un backend confiable; este proyecto no incluye backend.

### DataSources conectados y limitaciones conocidas

The Discover repository requests configured sources concurrently and interleaves
their results (Local, YouTube, Pixabay, and Vimeo) so that a large YouTube
playlist does not push all Pixabay videos to the end of Discover. If a source
fails, successful sources remain available and the UI identifies the failed
source; if every source fails, loading ends with a retry action. Instagram's
placeholder is not registered as an active source.

Seasonal selection affects the splash screen and Android launcher icon only. It
does not filter, reorder, or reconfigure any video source. Select a season from
the palette menu in Discover; the choice is saved and can be returned to
`Automático (fecha del dispositivo)`. Keep Android's automatic date and time
enabled: changing the device clock can make HTTPS certificate validation fail
for YouTube and Pixabay even though their configuration is correct.

The app combines these video sources:

- `LocalVideoPostDataSource` maps the existing `videoPosts` records. Despite
  the source name, these are remote Google Drive videos, not bundled assets.
  The eight configured URLs use the direct-download form
  `drive.google.com/uc?export=download&id=...`. The original first clip was
  removed because the Xiaomi 23129RA5FL rejected its 2160x3840 H.264 High
  Profile stream (`NO_EXCEEDS_CAPABILITIES`). A diagnostic HTTP range request
  to the remaining URLs returned `206 Partial Content` with `video/mp4`; this
  confirms that they serve video data from this environment, but does not
  guarantee future availability or successful decoding on every Android device.
  If
  Android reports a decoder initialization/format-capability failure, that
  video is omitted from all feed sections for the current app session and the
  feed advances to the next entry; transient network and other playback errors
  remain retryable and do not remove the video. The
  first Drive clip initialized and played in the Pixel 10 emulator after a
  user tap; physical-device playback is still unverified. Chrome
  Flutter Web has also blocked Drive playback with `net::ERR_BLOCKED_BY_ORB`;
  use a media host that supports CORS and byte-range requests for the web build.
  Actual playback on an Android device still needs verification.
- `YouTubeVideoDataSource` requests `playlistItems.list`, follows page tokens
  until the playlist ends (or an optional page limit is configured), ignores
  entries without usable video IDs, and maps title, description,
  channel, thumbnail and stable `youtube:<id>` identity. YouTube's API key and
  playlist ID are required. Playback uses the YouTube IFrame player; videos
  whose owners disable embedding may still fail. Playback starts unmuted; the
  platform may still require a user gesture before allowing audible autoplay.
  See the [YouTube Data API
  playlistItems.list reference](https://developers.google.com/youtube/v3/docs/playlistItems/list).
- `PixabayVideoDataSource` searches the configured default terms (`nature
  vertical`), requests up to 200 results per page and follows pagination up to
  Pixabay's documented 500-result per-query API limit. It maps the API's
  `hits` collection (and accepts `videos` for compatibility), excludes entries
  without a direct MP4 variant, prefers portrait clips, and maps dimensions,
  duration, tags, thumbnail and contributor/page attribution. Results are
  cached in memory for 24 hours as required by the
  [Pixabay API usage policy](https://pixabay.com/api/docs/).
- `VimeoVideoDataSource` optionally accepts comma-separated public Vimeo page
  URLs in `VIMEO_VIDEO_URLS`, fetches title and thumbnail metadata from Vimeo's
  public oEmbed endpoint, and plays supported videos through the Vimeo embedded
  player in a WebView. No Vimeo API key is used. The video's Vimeo privacy and
  embedding settings must allow playback in an embedded player.
- `InstagramVideoDataSource` is a prepared integration, not an active API
  client. Instagram's API is for authorized professional accounts and requires
  app setup, permissions, and an access token. Keep that token on a trusted
  backend; do not put it in the Flutter app or source control. See the
  [Instagram API getting started
  guide](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-instagram-login/get-started).

The unconfigured Instagram stub remains in the repository for reference, but
it is not registered in the active repository and makes no network requests.
API responses are tested with simulated HTTP clients, not live credentials.
Player selection,
loading/error controls and the Vimeo URL/oEmbed mapping have unit/widget
coverage. YouTube and Pixabay metadata requests timed out in this emulator
session; successful live API loading, YouTube playback, and Vimeo playback on a
physical Android device remain unverified. The repository logs
a failed source, continues to the remaining sources, removes duplicate IDs
while preserving first-seen order, and throws `VideoDataSourcesException` only
if all configured sources fail without returning videos.

## 6. Ejecución y pruebas locales

Ejecuta los comandos desde el directorio del proyecto, donde está
`pubspec.yaml`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d "DEVICE_ID"
```

Reemplaza `DEVICE_ID` por el identificador que muestra `flutter devices`.
También se puede ejecutar `flutter run` para elegir el dispositivo disponible.
Las pruebas de APIs usan clientes HTTP simulados: no requieren claves válidas y
no deben interpretarse como solicitudes reales a los proveedores.

**Verificación ejecutada durante esta actualización documental (17-oct-2026):**

- `flutter analyze`: `No issues found!`.
- `flutter test`: `All tests passed!`, 80 pruebas.
- No se ejecutó `flutter build apk --release` durante esta tarea.
- Estos resultados describen análisis y tests automatizados, no una prueba de
  reproducción en un teléfono ni en Appetize.

## 7. Compilación APK

Para compilar el APK de producción:

```powershell
flutter build apk --release
```

La ruta esperada es `build/app/outputs/flutter-apk/app-release.apk`. La ruta
solo indica dónde Flutter normalmente genera el archivo; **no confirma que
exista**. Al terminar la compilación se puede verificar y medir en PowerShell:

```powershell
Test-Path .\build\app\outputs\flutter-apk\app-release.apk
Get-Item .\build\app\outputs\flutter-apk\app-release.apk |
  Select-Object FullName, Length, LastWriteTime
```

Actualmente el APK release no está verificado como generado. Su tamaño queda
**PENDIENTE: compilar y medir el APK release**. La versión declarada del
proyecto es `1.0.0+1`; comprueba los overrides usados en la compilación antes de
documentar una versión distinta.

## 8. Publicación en Appetize.io

Procedimiento para completar cuando se prepare el APK release:

1. Generar y verificar el APK release con el comando de la sección anterior.
2. Cargar ese APK en Appetize.io desde la cuenta del proyecto.
3. Seleccionar y ejecutar una primera configuración virtual; registrar el
   dispositivo/ajustes elegidos en la evidencia.
4. Repetir en una segunda configuración virtual distinta y guardar su evidencia.
5. Copiar el enlace permanente real proporcionado por Appetize y comprobarlo en
   una ventana de navegador antes de documentarlo.

> **PENDIENTE: agregar aquí el enlace real de Appetize**

<!-- PENDIENTE: agregar docs/evidencias/16-panel-publicacion-appetize.png -->
<!-- PENDIENTE: agregar docs/evidencias/14-appetize-configuracion-1.png -->
<!-- PENDIENTE: agregar docs/evidencias/15-appetize-configuracion-2.png -->

No se afirma que TokTik esté publicada: aún falta un enlace real de Appetize.
La disponibilidad de reproductores externos y servicios de video en Appetize
también queda pendiente de comprobar en la ejecución publicada.

## 9. Plan y resultados de pruebas

| Identificador | Prueba | Resultado esperado | Resultado obtenido | Estado | Ruta de la evidencia |
|---|---|---|---|---|---|
| T01 | Inicio y carga inicial | Mostrar splash y llegar a Discover | Hay cobertura automatizada de splash/carga; inicio del APK en dispositivo no comprobado en esta tarea | Prueba automatizada existente; ejecución Android pendiente | `test/seasonal_theme_test.dart`; `test/widget_test.dart`; captura: PENDIENTE |
| T02 | Navegación Discover / For You / Favorites | Cambiar horizontalmente entre las tres secciones | Test widget de swipe horizontal incluido en las 80 pruebas aprobadas | Automatizada aprobada; captura pendiente | `test/widget_test.dart`; captura: PENDIENTE |
| T03 | Desplazamiento vertical | Avanzar al siguiente video verticalmente | El feed usa `PageView` vertical; interacción manual en Android/Appetize pendiente | Parcial; ejecución manual pendiente | `lib/presentation/widgets/shared/video_scrollable_view.dart`; captura: PENDIENTE |
| T04 | Reproducción | Reproducir un video visible sin cierre inesperado | Hay cobertura de estado de error recuperable; reproducción de streams reales pendiente | Pendiente de verificación real | `test/widget_test.dart`; captura: PENDIENTE |
| T05 | Sonido activado/desactivado | Cambiar el estado de mute y reflejarlo en controles | Test widget verifica el control/estado; audio real de cada reproductor no verificado | Automatizada parcial; prueba de audio pendiente | `test/widget_test.dart`; captura: PENDIENTE |
| T06 | Like y persistencia | Cambiar like y recuperar el estado guardado | Tests de toggle, serialización y restauración incluidos en la suite aprobada | Automatizada aprobada; captura pendiente | `test/widget_test.dart`; captura: PENDIENTE |
| T07 | Favoritos y persistencia | Guardar/quitar favorito y restaurarlo | Tests de filtro, toggle y restauración incluidos en la suite aprobada | Automatizada aprobada; captura pendiente | `test/widget_test.dart`; captura: PENDIENTE |
| T08 | Caption/description expandible | Abrir y leer el texto completo | Tests widget de caption corto y descripción completa incluidos en la suite aprobada | Automatizada aprobada; captura pendiente | `test/widget_test.dart`; captura: PENDIENTE |
| T09 | Cuatro temas estacionales | Resolver Normal, Halloween, Christmas y Valentine's Day | Tests cubren las reglas de fecha de los cuatro temas; capturas de cada tema no aportadas | Reglas automatizadas aprobadas; evidencia visual pendiente | `test/seasonal_theme_test.dart`; capturas: PENDIENTE |
| T10 | Selector manual y retorno a automático | Persistir una elección y poder limpiarla | Tests de selección persistida y retorno a automático incluidos en la suite aprobada | Automatizada aprobada; captura pendiente | `test/seasonal_theme_provider_test.dart`; `test/widget_test.dart`; captura: PENDIENTE |
| T11 | Carga de cada DataSource | Obtener metadatos y mostrar videos Local, YouTube, Pixabay y Vimeo cuando estén configurados | Mapeo/API cubiertos principalmente con respuestas mock; APIs y playback reales no verificados durante esta tarea | Automatizada simulada; verificación en vivo pendiente | `test/video_data_sources_test.dart`; capturas: PENDIENTE |
| T12 | Error de conexión y reintento | Conservar fuentes disponibles y ofrecer reintento con error legible | Tests cubren errores simulados/repositorio y reintento; un fallo TLS real y su causa no han sido confirmados | Parcial; TLS/Android pendiente | `test/video_post_repository_test.dart`; `test/widget_test.dart`; captura/log: PENDIENTE |
| T13 | Appetize: primera configuración virtual | Abrir la app y completar pruebas básicas | No hay enlace ni ejecución/captura confirmados | Pendiente de ejecutar | `docs/evidencias/14-appetize-configuracion-1.png` — PENDIENTE |
| T14 | Appetize: segunda configuración virtual | Repetir pruebas en una configuración virtual distinta | No hay configuración, ejecución ni captura confirmadas | Pendiente de ejecutar | `docs/evidencias/15-appetize-configuracion-2.png` — PENDIENTE |
| T15 | Análisis y suite de tests | Análisis limpio y pruebas aprobadas | Ejecutado el 17-oct-2026: análisis sin issues y 80 tests aprobados | Verificado | Salida de terminal/captura: `docs/evidencias/17-resultados-pruebas.png` — PENDIENTE |

La suite aprobada confirma los casos automatizados con sus dependencias
simuladas; no confirma que las APIs externas estén disponibles ni que los
videos se reproduzcan en un Android real.

## 10. Evidencias visuales

No se encontraron capturas académicas en `docs/evidencias/`; esa carpeta no
existe todavía. Agrega manualmente las capturas indicadas en la tabla. Los
comentarios HTML siguientes marcan espacios pendientes sin enlazar imágenes
inexistentes:

| Archivo sugerido | Qué debe verse | Requisito que demuestra | Sección del README |
|---|---|---|---|
| `docs/evidencias/01-pantalla-inicial.png` | Splash y pantalla inicial de TokTik | Inicio y tema activo | 9, T01 |
| `docs/evidencias/02-discover-video.png` | Discover con un video reproduciéndose | Feed y reproducción | 2, 9, T04 |
| `docs/evidencias/03-for-you.png` | Sección For You seleccionada | Secciones de navegación | 2, 9, T02 |
| `docs/evidencias/04-favorites.png` | Sección Favorites con un favorito | Favoritos | 2, 9, T07 |
| `docs/evidencias/05-sonido-activado.png` | Control en estado sonido activado | Control de audio | 2, 9, T05 |
| `docs/evidencias/06-sonido-desactivado.png` | Control en estado mute | Control de audio | 2, 9, T05 |
| `docs/evidencias/07-like-activado.png` | Video con like activado | Like | 2, 9, T06 |
| `docs/evidencias/08-like-desactivado.png` | Video con like desactivado | Toggle de like | 2, 9, T06 |
| `docs/evidencias/09-descripcion-expandida.png` | Hoja inferior con texto completo | Caption/descripción expandible | 2, 9, T08 |
| `docs/evidencias/10-tema-normal.png` | Splash/logo en tema Normal | Tema estacional | 2, 9, T09 |
| `docs/evidencias/11-tema-halloween.png` | Splash/logo en Halloween | Tema estacional | 2, 9, T09 |
| `docs/evidencias/12-tema-christmas.png` | Splash/logo en Christmas/Navidad | Tema estacional | 2, 9, T09 |
| `docs/evidencias/13-tema-valentines-day.png` | Splash/logo en Valentine's Day/San Valentín | Tema estacional | 2, 9, T09 |
| `docs/evidencias/14-appetize-configuracion-1.png` | App ejecutándose en la primera configuración virtual; anotar dispositivo elegido | Compatibilidad de la primera configuración | 8, 9, T13 |
| `docs/evidencias/15-appetize-configuracion-2.png` | App ejecutándose en otra configuración virtual; anotar dispositivo elegido | Compatibilidad de la segunda configuración | 8, 9, T14 |
| `docs/evidencias/16-panel-publicacion-appetize.png` | Panel/link real de la aplicación publicada | Publicación y acceso web | 8 |
| `docs/evidencias/17-resultados-pruebas.png` | Terminal con `flutter analyze` y `flutter test` satisfactorios | Validación automatizada | 6, 9, T15 |
| `docs/evidencias/18-historial-git-integracion.png` | Historial/flujo de integración real, sin ocultar el contexto relevante | Rama e integración | 12 |

<!-- PENDIENTE: agregar manualmente las capturas enumeradas arriba bajo docs/evidencias/. -->

No se insertan marcadores `![...](...)` para estas capturas mientras no existan
los archivos. Los dos diagramas de la sección 3 sí apuntan a SVG que existen.

## 11. Incidencias y soluciones

| Problema detectado | Causa confirmada o hipótesis pendiente | Solución aplicada | Resultado posterior |
|---|---|---|---|
| Un clip local de Drive no era compatible con el Xiaomi 23129RA5FL | Confirmado en los logs documentados en el README: stream H.264 High Profile de 2160×3840 rechazado con `NO_EXCEEDS_CAPABILITIES` | El registro de ese clip se retiró; ante fallos de inicialización de decoder, el reproductor omite el video para la sesión y avanza | El README documenta que el primer clip restante inicializó/reprodujo en un emulador Pixel 10 después de un toque; reproducción física aún sin verificar |
| Chrome Flutter Web bloqueó reproducción de Drive con `net::ERR_BLOCKED_BY_ORB` | Incidencia observada; Drive no sirve necesariamente contenido compatible con CORS en ese flujo | No se documenta una solución aplicada | Requiere un host de medios con CORS y byte ranges para validar web; pendiente |
| YouTube y Pixabay reportaron `HandshakeException` al cambiar manualmente la fecha del teléfono a 14 de febrero | **Hipótesis pendiente:** el reloj podría hacer que la validación TLS considere un certificado fuera de vigencia. El tipo de excepción no confirma por sí solo fecha/certificado; también faltan logs internos para descartar CA o red | No se documenta aquí una solución verificada. No se debe desactivar la validación TLS ni cambiar a HTTP | Reproducción bajo fecha automática y detalle de causa TLS pendiente |
| Carga real de YouTube/Pixabay/Vimeo | Las pruebas disponibles de metadatos usan clientes HTTP simulados; las peticiones reales pueden fallar por conexión, configuración o proveedor | No se declara solución ni disponibilidad estable | Playback de YouTube/Vimeo y carga completa de proveedores externos en Android físico pendientes |

## 12. Publicación y control de versiones

La rama de trabajo observada es `Practica4`. Este documento no afirma que una
rama se haya integrado ni que exista un merge, commit o publicación de release
verificados. Completa el flujo real usado por el equipo únicamente cuando
cuentes con esa evidencia.

- **Rama:** `Practica4` (observada).
- **Flujo de integración:** PENDIENTE de documentar según el procedimiento real.
- **Hash/fecha de integración:** PENDIENTE; no se inventa.

<!-- PENDIENTE: agregar docs/evidencias/18-historial-git-integracion.png -->

## 13. Conclusiones y limitaciones

TokTik tiene implementados feeds por secciones, estado de preferencias local,
temas estacionales y un repositorio que combina varias fuentes. La suite local
ejecutada en esta actualización terminó con 80 pruebas aprobadas y
`flutter analyze` no encontró problemas. Los diagramas de arquitectura ya están
disponibles en SVG.

Estos resultados no acreditan publicación en Appetize ni reproducción de todos
los streams en teléfonos. Los videos llamados Local dependen de URLs remotas de
Google Drive; la integración de YouTube requiere API configurada y embedding
permitido; Pixabay y Vimeo dependen de servicios/red y sus restricciones. La
causa del handshake reportado y la ejecución en dos configuraciones virtuales
continúan pendientes.

Para cerrar la entrega falta compilar y verificar el APK release, probarlo en
dos configuraciones de Appetize, guardar las capturas reales y sustituir el
marcador del enlace únicamente cuando Appetize proporcione un URL comprobado.
