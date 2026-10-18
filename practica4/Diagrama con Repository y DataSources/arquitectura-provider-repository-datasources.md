# TokTik — Arquitectura de Provider, Repository y múltiples DataSources de video

Diagrama basado en el código actual de `practica4`. Discover, For You y Favorites son vistas sobre las mismas listas del `DiscoverProvider`; no son fuentes de datos independientes.

```mermaid
flowchart LR
  subgraph P[Presentación]
    UI[DiscoverScreen<br/>Discover · For You · Favorites]
    SECT[_VideoSection<br/>selecciona lista de videos]
    SCROLL[VideoScrollableView<br/>PageView vertical]
    PLAYER[FullScreenPlayer<br/>controlador según fuente]
    UI -->|elige sección / solicita reintento| SECT
    SECT -->|VideoPost[]| SCROLL
    SCROLL -->|VideoPost activo| PLAYER
  end

  subgraph S[Estado de presentación]
    PR[DiscoverProvider<br/>ChangeNotifier]
  end

  subgraph D[Dominio]
    RI[VideoPostRepository<br/>getVideoPosts()]
    DSIF[VideoPostDataSource<br/>getVideoPosts()]
    VP[VideoPost<br/>entidad común del feed]
  end

  subgraph I[Infraestructura — instancias registradas en main.dart]
    REPO[VideoPostRepositoryImpl]
    LOCAL[LocalVideoPostDataSource<br/>LocalVideoModel.fromJson → toVideoPostEntity]
    YT[YouTubeVideoDataSource<br/>playlistItems.list · mapea a VideoPost]
    PIX[PixabayVideoDataSource<br/>API de búsqueda · mapea a VideoPost]
    VIM[VimeoVideoDataSource<br/>oEmbed de URLs configuradas · mapea a VideoPost]
  end

  subgraph X[Orígenes / reproductores externos]
    DATA[(videoPosts<br/>registros Dart)]
    DRIVE[(Google Drive<br/>URL remota de descarga)]
    YAPI[(YouTube Data API v3)]
    YPLAY[(YouTube IFrame player)]
    PAPI[(Pixabay Videos API)]
    MP4[(URLs MP4 de Pixabay)]
    OEMBED[(Vimeo oEmbed)]
    VWEB[(Vimeo embed en WebView)]
    NETWORK[VideoPlayerController.networkUrl<br/>para URLs directas]
  end

  UI -->|context.read/watch · loadNextPage()| PR
  PR -->|solicita lista| RI
  RI -.->|VideoPostRepositoryImpl implementa| REPO
  REPO -->|invoca concurrentemente<br/>cada getVideoPosts()| DSIF
  DSIF -.->|contrato implementado por| LOCAL
  DSIF -.-> YT
  DSIF -.-> PIX
  DSIF -.-> VIM
  LOCAL -->|lee registros| DATA
  DATA -->|videoUrl| DRIVE
  YT -->|HTTPS GET · playlist + pageToken| YAPI
  PIX -->|HTTPS GET · término + páginas| PAPI
  PAPI -->|URLs MP4 en respuesta| MP4
  VIM -->|HTTPS GET · URL de video| OEMBED
  REPO -->|combina: intercala, quita IDs duplicados| VP
  LOCAL -->|List<VideoPost>| VP
  YT -->|List<VideoPost>| VP
  PIX -->|List<VideoPost>| VP
  VIM -->|List<VideoPost>| VP
  VP -->|resultados| REPO
  REPO -->|List<VideoPost> o error total| PR
  PR -->|videos · initialLoading · loadError<br/>sourceFailures · notifyListeners| UI
  PLAYER -->|source=youtube| YPLAY
  PLAYER -->|source=vimeo| VWEB
  PLAYER -->|source=local o pixabay · URL| NETWORK

  classDef presentation fill:#edf4fa,stroke:#56738f,color:#182b3e
  classDef state fill:#f3effa,stroke:#775ca5,color:#2e2342
  classDef domain fill:#f5f7f9,stroke:#697b8c,color:#263747
  classDef infrastructure fill:#eef6f1,stroke:#568069,color:#1f392b
  classDef external fill:#fff8e9,stroke:#ad8643,color:#493919
  class UI,SECT,SCROLL,PLAYER presentation
  class PR state
  class RI,DSIF,VP domain
  class REPO,LOCAL,YT,PIX,VIM infrastructure
  class DATA,DRIVE,YAPI,YPLAY,PAPI,MP4,OEMBED,VWEB,NETWORK external
```

## Explicación por capas

- **Presentación:** `DiscoverScreen` navega horizontalmente entre Discover, For You y Favorites. Cada sección recibe una lista derivada del mismo `DiscoverProvider`; los videos se desplazan verticalmente con `VideoScrollableView` y `PageView`. El `FullScreenPlayer` recibe el `VideoPost` activo.
- **Provider:** `DiscoverProvider.loadNextPage()` solicita los videos al repositorio. Publica `videos`, `initialLoading`, `loadError` y `sourceFailures`; la pantalla escucha cambios con `context.watch`. `forYouVideos` ordena por vistas y likes, y `favoriteVideos` filtra favoritos. La llamada inicial se activa al crear el provider en `main.dart`; la interfaz puede volver a invocarla para reintentar. Aunque el método se llama `loadNextPage`, no añade páginas locales de feed: vuelve a solicitar los resultados completos al repositorio.
- **Repository:** `VideoPostRepositoryImpl` inicia los DataSources concurrentemente (`Future.wait`), intercala los resultados por posición, conserva el primer video de cada ID y registra fallos por fuente. Mantiene los resultados disponibles si alguna fuente falla; lanza `VideoDataSourcesException` si todas fallan y no hay videos. No hay reintento automático en esta clase; el botón de la interfaz vuelve a llamar al Provider.
- **DataSources y entidad:** los cuatro DataSources registrados implementan `VideoPostDataSource` y devuelven `Future<List<VideoPost>>`. `VideoPost` es la entidad común que el repositorio entrega al Provider. Solo Local usa el modelo intermedio `LocalVideoModel`; las fuentes remotas mapean sus respuestas directamente a `VideoPost`.
- **Reproducción:** cargar metadatos y reproducir son flujos distintos. YouTube obtiene metadatos de la playlist con Data API y usa el reproductor IFrame. Vimeo obtiene título/miniatura mediante oEmbed y reproduce el URL con embed en WebView. Local y Pixabay entregan URLs directas al `VideoPlayerController.networkUrl`.

## Archivos y clases fuente

| Archivo | Clases / responsabilidad |
|---|---|
| `lib/main.dart` | `main`, `MyApp`: carga `AppConfig`, registra Local, YouTube, Pixabay y Vimeo en `VideoPostRepositoryImpl`; crea `DiscoverProvider` y llama `loadNextPage()`. |
| `lib/presentation/screens/discover/discover_screen.dart` | `DiscoverScreen`, `_VideoSection`: secciones, reintento, estado de carga/error y selección de listas. |
| `lib/presentation/widgets/shared/video_scrollable_view.dart` | `VideoScrollableView`: feed vertical y selección del video activo. |
| `lib/presentation/widgets/video/fullscreen_player.dart` | `FullScreenPlayer`: crea el controlador correspondiente a la fuente. |
| `lib/presentation/providers/discover_provider.dart` | `DiscoverProvider`: solicitud, listas, carga, errores y derivación For You/Favorites. |
| `lib/domain/repositories/video_post_repository.dart` | `VideoPostRepository`, `VideoPostRepositoryDiagnostics`, `VideoPostSourceFailure`. |
| `lib/infrastructure/repositories/video_post_repository_impl.dart` | `VideoPostRepositoryImpl`, `VideoDataSourcesException`: concurrencia, intercalado, deduplicación y errores parciales. |
| `lib/domain/datasources/video_post_data_source.dart` | `VideoPostDataSource`, `UnconfiguredVideoDataSourceException`. |
| `lib/domain/entities/video_post.dart` | `VideoPost`, `VideoSourceType`: entidad común del feed. |
| `lib/infrastructure/datasources/local_video_post_data_source.dart` | `LocalVideoPostDataSource`: mapea registros Dart al modelo común. |
| `lib/infrastructure/models/local_video_model.dart` | `LocalVideoModel.fromJson`, `toVideoPostEntity`: único mapper/modelo intermedio observado. |
| `lib/shared/data/local_video_post.dart` | `videoPosts`: metadatos estáticos Dart; sus `videoUrl` apuntan a Google Drive. |
| `lib/infrastructure/datasources/youtube_video_data_source.dart` | `YouTubeVideoDataSource`: YouTube Data API v3 `playlistItems.list`; paginación por `pageToken`; mapeo directo a `VideoPost`. |
| `lib/infrastructure/datasources/pixabay_video_data_source.dart` | `PixabayVideoDataSource`: API de videos, páginas, selección de URL MP4, caché en memoria y mapeo directo a `VideoPost`. |
| `lib/infrastructure/datasources/vimeo_video_data_source.dart` | `VimeoVideoDataSource`: URLs Vimeo configuradas y metadatos oEmbed; mapeo directo a `VideoPost`. |
| `lib/config/environment/app_config.dart` | `AppConfig`: `YOUTUBE_API_KEY`, `YOUTUBE_PLAYLIST_ID`, `PIXABAY_API_KEY` y `VIMEO_VIDEO_URLS`. |
| `lib/infrastructure/datasources/video_source_api_exception.dart` | `VideoSourceApiException`, `VideoSourceFailureKind` y validación/decodificación de JSON para APIs. |

## Advertencias de configuración y alcance

- `LocalVideoPostDataSource` es el nombre del origen de metadatos: sus registros viven en `videoPosts`, pero sus videos no están empaquetados en el dispositivo; se descargan desde URLs de Google Drive.
- En el `.env` presente se encontraron los nombres `YOUTUBE_API_KEY`, `YOUTUBE_PLAYLIST_ID` y `PIXABAY_API_KEY`; no se muestran sus valores ni se valida aquí que sean vigentes o aceptados por las APIs. `VIMEO_VIDEO_URLS` es opcional y no aparece entre esos nombres, por lo que Vimeo está registrado pero, con la configuración visible actual, devuelve una lista vacía.
- YouTube y Pixabay están registrados, pero requieren credenciales válidas para cargar datos. La ejecución exitosa contra las APIs reales no se deduce solo del registro en `main.dart`.
- `InstagramVideoDataSource` existe, pero `main.dart` no lo registra; su implementación lanza `UnconfiguredVideoDataSourceException` y no consume una API. No forma parte del flujo activo.
- La lista de prueba/fixture o el código no demuestran disponibilidad futura de Google Drive, compatibilidad de cada códec en cada dispositivo, restricciones de embed de YouTube/Vimeo ni éxito con credenciales en vivo.
