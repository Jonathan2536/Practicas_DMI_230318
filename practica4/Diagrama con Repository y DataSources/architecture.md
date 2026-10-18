# TokTik: arquitectura de videos

## Alcance y evidencia

Diagrama basado en el codigo Flutter inspeccionado en `../lib`. La carpeta de entrega esta un nivel debajo del proyecto y contiene solo esta documentacion.

## Mermaid

```mermaid
flowchart LR
  subgraph UI[Presentacion]
    DS[DiscoverScreen - Discover / For You / Favorites]
    F[VideoScrollableView - PageView vertical]
    P[DiscoverProvider - ChangeNotifier]
    Player[FullScreenPlayer]
    DS -->|listas derivadas| F
    DS -->|context.watch / retry| P
    F -->|VideoPost activo| Player
  end

  R[VideoPostRepository - contrato + VideoPostRepositoryImpl]
  E[VideoPost - modelo comun del feed]
  subgraph Sources[DataSources registrados en main.dart]
    Local[LocalVideoPostDataSource - URLs Google Drive]
    YT[YouTubeVideoDataSource]
    PX[PixabayVideoDataSource]
    VM[VimeoVideoDataSource]
  end
  Drive[(Google Drive - URLs HTTPS)]
  YApi[(YouTube Data API - playlistItems.list)]
  PApi[(Pixabay API - /api/videos/)]
  OEmbed[(Vimeo oEmbed - vimeo.com/api/oembed.json)]
  YPlayer[(YouTube embedded player)]
  VPlayer[(player.vimeo.com)]
  PixabayCDN[(Pixabay video URL)]

  P -->|getVideoPosts()| R
  R -->|solicita concurrentemente| Local
  R -->|solicita concurrentemente| YT
  R -->|solicita concurrentemente| PX
  R -->|solicita concurrentemente| VM
  Local -->|Future<List<VideoPost>>| R
  YT -->|Future<List<VideoPost>>| R
  PX -->|Future<List<VideoPost>>| R
  VM -->|Future<List<VideoPost>>| R
  Local -.->|videoUrl remoto| Drive
  YT -.->|HTTP JSON| YApi
  PX -.->|HTTP JSON| PApi
  VM -.->|HTTP JSON de metadatos| OEmbed
  R -.->|usa tipo comun| E
  R -->|List<VideoPost> y fallos parciales| P
  P -->|notifyListeners: carga, videos, error| DS
  Player -.->|networkUrl / VideoPlayerController| Drive
  Player -.->|networkUrl / VideoPlayerController| PixabayCDN
  Player -.->|YouTube IFrame player| YPlayer
  Player -.->|Vimeo embed WebView| VPlayer
```

## Flujo y capas

- **Presentacion:** `DiscoverScreen` navega horizontalmente por Discover, For You y Favorites. `VideoScrollableView` pagina verticalmente y entrega cada `VideoPost` visible a `FullScreenPlayer`.
- **Provider:** `DiscoverProvider` recibe `loadNextPage()` (arranque/reintento), `toggleLike`, `toggleFavorite` y exclusiones de formato no compatible. Expone `initialLoading`, `videos`, `loadError` y `sourceFailures`. For You ordena por vistas, likes y `id` como desempate; Favorites filtra por `isFavorite`.
- **Repository:** `VideoPostRepository` es el contrato; `VideoPostRepositoryImpl`, creado en `main.dart`, recibe cuatro fuentes. `Future.wait` lanza las cargas concurrentemente; luego intercala listas y conserva el primer video por `id`. Registra fallos parciales y solo lanza `VideoDataSourcesException` cuando todas fallan y no hay resultados. Vimeo tambien conserva los videos válidos si alguna URL oEmbed falla y registra ese error. No implementa reintentos internos; la pantalla ofrece reintentar invocando de nuevo al Provider.
- **DataSources y metadatos:** la fuente llamada `LocalVideoPostDataSource` lee registros Dart de `videoPosts`, cuyo `videoUrl` es una URL HTTPS de Google Drive. No lee archivos locales. YouTube consulta `playlistItems.list`; Pixabay consulta `/api/videos/` y cachea 24 h; Vimeo solicita oEmbed para cada URL configurada. Todas devuelven `Future<List<VideoPost>>`.
- **Modelos y mapeo:** `LocalVideoPostDataSource` convierte mapas con `LocalVideoModel.fromJson(...).toVideoPostEntity()`. Las fuentes YouTube, Pixabay y Vimeo mapean cada JSON directamente a `VideoPost`; no hay modelos de respuesta separados para esas API en los archivos inspeccionados.
- **Reproduccion:** los metadatos terminan en `VideoPost`; reproducir es un flujo distinto. `FullScreenPlayer` usa `VideoPlayerController.networkUrl` para fuentes distintas de YouTube/Vimeo (incluye URLs Drive/Pixabay), el reproductor YouTube IFrame y un WebView para Vimeo. URLs externas, privacidad y restricciones de embedding pueden impedir playback.

## Configuracion y advertencias

`main.dart` registra Local, YouTube, Pixabay y Vimeo. `.env.example` declara vacias `YOUTUBE_API_KEY`, `YOUTUBE_PLAYLIST_ID`, `PIXABAY_API_KEY` y `VIMEO_VIDEO_URLS`: YouTube/Pixabay lanzan error de fuente no configurada si se consultan sin claves; Vimeo devuelve lista vacia sin URLs. Los valores reales y la disponibilidad en vivo no se validan en este diagrama.

`GoogleDriveVideoDataSource` y `InstagramVideoDataSource` existen pero no se registran en `main.dart`. Instagram es un placeholder que lanza `UnconfiguredVideoDataSourceException`. No son fuentes activas. `GoogleDriveVideoModel` no se usa por la fuente activa; esta usa `LocalVideoModel`.

Las secciones Discover, For You y Favorites son vistas de los mismos `VideoPost`, no DataSources. Estado de likes/favoritos se persiste por `LocalStorageService`, fuera del flujo de metadatos.

## Archivos y clases que sustentan el diagrama

| Archivo | Clases / evidencia |
|---|---|
| `lib/main.dart` | Registro de las cuatro fuentes, `VideoPostRepositoryImpl`, Provider inicial |
| `lib/presentation/screens/discover/discover_screen.dart` | `DiscoverScreen`, secciones, estado y reintento |
| `lib/presentation/widgets/shared/video_scrollable_view.dart` | `VideoScrollableView`, paginacion vertical |
| `lib/presentation/providers/discover_provider.dart` | `DiscoverProvider`, estado y operaciones |
| `lib/domain/repositories/video_post_repository.dart` | `VideoPostRepository`, diagnosticos y fallos |
| `lib/infrastructure/repositories/video_post_repository_impl.dart` | concurrencia, intercalado, deduplicacion, fallos parciales |
| `lib/domain/datasources/video_post_data_source.dart` | `VideoPostDataSource`, contrato de fuente |
| `lib/domain/entities/video_post.dart` | `VideoPost`, `VideoSourceType` |
| `lib/infrastructure/datasources/local_video_post_data_source.dart` | `LocalVideoPostDataSource` |
| `lib/infrastructure/models/local_video_model.dart` | `LocalVideoModel` y mapper a `VideoPost` |
| `lib/shared/data/local_video_post.dart` | `videoPosts` y URLs Drive |
| `lib/infrastructure/datasources/youtube_video_data_source.dart` | `YouTubeVideoDataSource` y mapeo API |
| `lib/infrastructure/datasources/pixabay_video_data_source.dart` | `PixabayVideoDataSource`, mapeo y cache |
| `lib/infrastructure/datasources/vimeo_video_data_source.dart` | `VimeoVideoDataSource`, mapeo oEmbed |
| `lib/config/environment/app_config.dart`, `.env.example` | Variables de configuracion |
| `lib/presentation/widgets/video/fullscreen_player.dart` | Controladores y ramas reales de playback |
| `lib/presentation/widgets/video/youtube_playback_helpers.dart`, `vimeo_playback_helpers.dart` | Resolucion de ID/URL de reproductores embebidos |
| `lib/infrastructure/datasources/google_drive_video_data_source.dart`, `instagram_video_data_source.dart` | Clases presentes pero no registradas |

> No se modifico codigo fuente, dependencias ni Git. Archify genero el HTML con validacion showcase 9/9, sin errores ni advertencias. La captura PNG incluida muestra el visor completo, no un recorte aislado. Las etiquetas y tarjetas del diagrama estan en espanol; los controles fijos del visor quedan en ingles.
