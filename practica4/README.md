# practica4

## Local API configuration

Copy `.env.example` to `.env` in the `practica4` project root, then fill in
the values locally:

- `YOUTUBE_API_KEY`
- `YOUTUBE_PLAYLIST_ID`
- `PIXABAY_API_KEY`
- `VIMEO_VIDEO_URLS` (optional, comma-separated Vimeo video page URLs)

The app loads `.env` as a Flutter asset at startup. Missing values are detected
when an external source requires them; values are not printed to logs. YouTube
playlist metadata and Pixabay video metadata are fetched by the data sources
when their credentials are configured. The Discover repository continues
loading successful sources if another source fails.

Do not commit `.env`. The example file contains empty values only. Values
embedded in a compiled Flutter application can be extracted from its APK, so
these keys are not secret in a distributed app. A production application
should keep provider credentials on a trusted backend; this project does not
include a backend.

## Video data sources

The Discover repository requests configured sources concurrently and interleaves
their results (Local, YouTube, Pixabay, and Vimeo) so that a large YouTube
playlist does not push all Pixabay videos to the end of Discover. If a source
fails, successful sources remain available and the UI identifies the failed
source; if every source fails, loading ends with a retry action. Instagram's
placeholder is not registered as an active source.

Seasonal selection currently affects the splash screen and Android launcher
icon only. It does not filter, reorder, or reconfigure any video source.

The app combines these video sources:

- `LocalVideoPostDataSource` maps the existing `videoPosts` records. Despite
  the source name, these are remote Google Drive videos, not bundled assets.
  All nine configured URLs currently use the direct-download form
  `drive.google.com/uc?export=download&id=...`. A diagnostic HTTP range request
  to each returned `206 Partial Content` with `video/mp4`; this confirms the
  current URLs serve video data from this environment, but does not guarantee
  future availability or successful decoding on every Android device. The
  first Drive clip initialized and played in the Pixel 10 emulator after a
  user tap; physical-device playback is still unverified. Chrome
  Flutter Web has also blocked Drive playback with `net::ERR_BLOCKED_BY_ORB`;
  use a media host that supports CORS and byte-range requests for the web build.
  Actual playback on an Android device still needs verification.
- `YouTubeVideoDataSource` requests `playlistItems.list`, follows up to five
  pages, ignores entries without usable video IDs, and maps title, description,
  channel, thumbnail and stable `youtube:<id>` identity. YouTube's API key and
  playlist ID are required. Playback uses the YouTube IFrame player; videos
  whose owners disable embedding may still fail. Playback starts unmuted; the
  platform may still require a user gesture before allowing audible autoplay.
  See the [YouTube Data API
  playlistItems.list reference](https://developers.google.com/youtube/v3/docs/playlistItems/list).
- `PixabayVideoDataSource` searches the configured default terms (`nature
  vertical`), maps the API's `hits` collection (and accepts `videos` for
  compatibility), excludes entries without a direct MP4 variant, prefers
  portrait clips, and maps dimensions, duration, tags, thumbnail and
  contributor/page attribution. Results are cached in memory for 30 minutes to
  avoid repeat requests during rebuilds.
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
