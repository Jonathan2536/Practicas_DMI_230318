# practica4

## Video data sources

The Discover repository receives three implementations of
`VideoPostDataSource`:

- `LocalVideoPostDataSource` is active. It reads the existing `videoPosts`
  records and maps them with `LocalVideoModel`.
- `YouTubeVideoDataSource` is a prepared integration, not an active API client.
  A real integration requires a YouTube Data API project and credentials. The
  current `video_player` widget cannot play YouTube watch-page URLs; playback
  needs a YouTube-compatible player before those records can be shown safely.
  See the [YouTube Data API playlistItems.list
  reference](https://developers.google.com/youtube/v3/docs/playlistItems/list).
- `InstagramVideoDataSource` is a prepared integration, not an active API
  client. Instagram's API is for authorized professional accounts and requires
  app setup, permissions, and an access token. Keep that token on a trusted
  backend; do not put it in the Flutter app or source control. See the
  [Instagram API getting started
  guide](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-instagram-login/get-started).

Both external implementations currently throw
`UnconfiguredVideoDataSourceException`; they do not make network requests or
pretend to return remote videos. Their API-specific DTO mappers should be added
alongside the real authenticated clients when those integrations are
configured. The repository logs a failed source, continues to the remaining
sources, and returns results from sources that succeeded. It throws
`VideoDataSourcesException` only if every configured source fails.
