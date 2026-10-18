import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:practica4/config/environment/app_config.dart';
import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/datasources/pixabay_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/video_source_api_exception.dart';
import 'package:practica4/infrastructure/datasources/vimeo_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/youtube_video_data_source.dart';

void main() {
  group('YouTubeVideoDataSource', () {
    test('maps playlist metadata and follows the next page token', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.queryParameters['pageToken'] == 'page-2') {
          return http.Response(
            jsonEncode({
              'items': [
                _youtubeItem(
                  videoId: 'video-2',
                  title: 'Second video',
                  thumbnail: 'https://example.com/second.jpg',
                ),
                {
                  'snippet': {'title': 'Deleted video'},
                  'contentDetails': {},
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'nextPageToken': 'page-2',
            'items': [
              _youtubeItem(
                videoId: 'video-1',
                title: 'First video',
                description: 'A description',
                channel: 'A channel',
                thumbnail: 'https://example.com/first.jpg',
              ),
              {
                'snippet': {'title': 'Missing ID'},
                'contentDetails': {},
              },
            ],
          }),
          200,
        );
      });
      final source = YouTubeVideoDataSource(
        config: _configuredApp(),
        client: client,
      );

      final videos = await source.getVideoPosts();

      expect(requests, hasLength(2));
      expect(
        requests.first.url.queryParameters['part'],
        'snippet,contentDetails',
      );
      expect(requests.first.url.queryParameters['playlistId'], 'playlist-id');
      expect(requests[1].url.queryParameters['pageToken'], 'page-2');
      expect(videos.map((video) => video.id), [
        'youtube:video-1',
        'youtube:video-2',
      ]);
      expect(videos.first.source, VideoSourceType.youtube);
      expect(videos.first.providerId, 'video-1');
      expect(videos.first.description, 'A description');
      expect(videos.first.thumbnailUrl, 'https://example.com/first.jpg');
      expect(videos.first.attribution, 'A channel');
    });

    test('returns an empty list for a valid empty playlist', () async {
      final source = YouTubeVideoDataSource(
        config: _configuredApp(),
        client: MockClient((_) async => http.Response('{"items":[]}', 200)),
      );

      expect(await source.getVideoPosts(), isEmpty);
    });

    test('reports malformed JSON as an invalid response', () async {
      final source = YouTubeVideoDataSource(
        config: _configuredApp(),
        client: MockClient((_) async => http.Response('<html>', 200)),
      );

      await expectLater(
        source.getVideoPosts(),
        throwsA(
          isA<VideoSourceApiException>().having(
            (error) => error.kind,
            'kind',
            VideoSourceFailureKind.invalidResponse,
          ),
        ),
      );
    });

    test('classifies a quota response without exposing the API key', () async {
      final source = YouTubeVideoDataSource(
        config: _configuredApp(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'errors': [
                  {'reason': 'quotaExceeded'},
                ],
              },
            }),
            403,
          ),
        ),
      );

      await expectLater(
        source.getVideoPosts(),
        throwsA(
          isA<VideoSourceApiException>()
              .having(
                (error) => error.kind,
                'kind',
                VideoSourceFailureKind.quotaExceeded,
              )
              .having(
                (error) => error.toString(),
                'message',
                isNot(contains('test-key')),
              ),
        ),
      );
    });

    test('does not make a request when configuration is missing', () async {
      var requested = false;
      final source = YouTubeVideoDataSource(
        config: AppConfig.fromMap(const {}),
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        source.getVideoPosts(),
        throwsA(
          isA<UnconfiguredVideoDataSourceException>().having(
            (error) => error.reason,
            'reason',
            contains('YOUTUBE_API_KEY'),
          ),
        ),
      );
      expect(requested, isFalse);
    });

    test('caps pagination at the configured page limit', () async {
      var requests = 0;
      final source = YouTubeVideoDataSource(
        config: _configuredApp(),
        maxPages: 2,
        client: MockClient((_) async {
          requests++;
          return http.Response(
            jsonEncode({
              'nextPageToken': 'next-$requests',
              'items': [_youtubeItem(videoId: 'video-$requests')],
            }),
            200,
          );
        }),
      );

      final videos = await source.getVideoPosts();

      expect(requests, 2);
      expect(videos, hasLength(2));
    });

    test(
      'follows playlist pagination until the final page by default',
      () async {
        var requests = 0;
        final source = YouTubeVideoDataSource(
          config: _configuredApp(),
          client: MockClient((_) async {
            requests++;
            return http.Response(
              jsonEncode({
                if (requests < 7) 'nextPageToken': 'next-$requests',
                'items': [_youtubeItem(videoId: 'video-$requests')],
              }),
              200,
            );
          }),
        );

        final videos = await source.getVideoPosts();

        expect(requests, 7);
        expect(videos, hasLength(7));
      },
    );

    test('rejects a repeated playlist page token', () async {
      final source = YouTubeVideoDataSource(
        config: _configuredApp(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'nextPageToken': 'same-token',
              'items': [_youtubeItem(videoId: 'video-1')],
            }),
            200,
          ),
        ),
      );

      await expectLater(
        source.getVideoPosts(),
        throwsA(
          isA<VideoSourceApiException>().having(
            (error) => error.kind,
            'kind',
            VideoSourceFailureKind.invalidResponse,
          ),
        ),
      );
    });
  });

  group('PixabayVideoDataSource', () {
    test('maps the API hits response shape', () async {
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'total': 1,
              'totalHits': 1,
              'hits': [
                _pixabayItem(
                  id: 13,
                  tags: 'winter forest',
                  width: 360,
                  height: 640,
                  url: 'https://cdn.example.com/winter.mp4',
                ),
              ],
            }),
            200,
          ),
        ),
      );

      final videos = await source.getVideoPosts();

      expect(videos, hasLength(1));
      expect(videos.single.id, 'pixabay:13');
      expect(videos.single.source, VideoSourceType.pixabay);
      expect(videos.single.videoUrl, 'https://cdn.example.com/winter.mp4');
    });

    test('maps direct MP4 metadata and puts portrait videos first', () async {
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'videos': [
                _pixabayItem(
                  id: 11,
                  tags: 'forest, river',
                  user: 'contributor',
                  width: 640,
                  height: 360,
                  url: 'https://cdn.example.com/landscape.mp4',
                ),
                _pixabayItem(
                  id: 12,
                  tags: 'flowers, garden',
                  width: 360,
                  height: 640,
                  url: 'https://cdn.example.com/portrait.mp4',
                ),
              ],
            }),
            200,
          ),
        ),
      );

      final videos = await source.getVideoPosts();

      expect(videos.map((video) => video.id), ['pixabay:12', 'pixabay:11']);
      expect(videos.first.source, VideoSourceType.pixabay);
      expect(videos.first.providerId, '12');
      expect(videos.first.videoUrl, 'https://cdn.example.com/portrait.mp4');
      expect(videos.first.thumbnailUrl, 'https://cdn.example.com/12.jpg');
      expect(videos.first.durationSeconds, 8);
      expect(videos.first.width, 360);
      expect(videos.first.height, 640);
      expect(videos.first.tags, 'flowers, garden');
      expect(videos[1].attribution, contains('Pixabay'));
    });

    test('excludes entries without a direct MP4 variant', () async {
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'videos': [
                {
                  'id': 1,
                  'videos': {
                    'medium': {
                      'url': 'https://cdn.example.com/video.webm',
                      'width': 640,
                      'height': 360,
                    },
                  },
                },
                {'id': 2, 'videos': {}},
              ],
            }),
            200,
          ),
        ),
      );

      expect(await source.getVideoPosts(), isEmpty);
    });

    test('returns an empty list for a valid empty response', () async {
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        client: MockClient((_) async => http.Response('{"videos":[]}', 200)),
      );

      expect(await source.getVideoPosts(), isEmpty);
    });

    test('classifies rate-limit responses', () async {
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        client: MockClient((_) async => http.Response('{}', 429)),
      );

      await expectLater(
        source.getVideoPosts(),
        throwsA(
          isA<VideoSourceApiException>().having(
            (error) => error.kind,
            'kind',
            VideoSourceFailureKind.rateLimited,
          ),
        ),
      );
    });

    test('does not make a request when configuration is missing', () async {
      var requested = false;
      final source = PixabayVideoDataSource(
        config: AppConfig.fromMap(const {}),
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        source.getVideoPosts(),
        throwsA(
          isA<UnconfiguredVideoDataSourceException>().having(
            (error) => error.reason,
            'reason',
            contains('PIXABAY_API_KEY'),
          ),
        ),
      );
      expect(requested, isFalse);
    });

    test('caches successful responses and avoids repeat requests', () async {
      var requests = 0;
      var now = DateTime(2026, 1, 1);
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        clock: () => now,
        cacheDuration: const Duration(minutes: 30),
        client: MockClient((_) async {
          requests++;
          return http.Response(
            jsonEncode({
              'videos': [
                _pixabayItem(
                  id: 1,
                  width: 640,
                  height: 360,
                  url: 'https://cdn.example.com/video.mp4',
                ),
              ],
            }),
            200,
          );
        }),
      );

      await source.getVideoPosts();
      await source.getVideoPosts();
      expect(requests, 1);

      now = now.add(const Duration(minutes: 31));
      await source.getVideoPosts();
      expect(requests, 2);
    });

    test('uses the configured search terms and per-page limit', () async {
      late Uri requestedUri;
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        searchTerms: 'calm mountains',
        perPage: 7,
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('{"videos":[]}', 200);
        }),
      );

      await source.getVideoPosts();

      expect(requestedUri.queryParameters['q'], 'calm mountains');
      expect(requestedUri.queryParameters['per_page'], '7');
      expect(requestedUri.queryParameters['page'], '1');
      expect(requestedUri.queryParameters['safesearch'], 'true');
    });

    test('fetches every available page up to Pixabay API limit', () async {
      final requestedPages = <String?>[];
      final source = PixabayVideoDataSource(
        config: _configuredApp(),
        perPage: 2,
        client: MockClient((request) async {
          final page = request.url.queryParameters['page'];
          requestedPages.add(page);
          final pageNumber = int.parse(page!);
          return http.Response(
            jsonEncode({
              'totalHits': 5,
              'hits': [
                _pixabayItem(
                  id: pageNumber * 2 - 1,
                  width: 360,
                  height: 640,
                  url: 'https://cdn.example.com/$pageNumber-a.mp4',
                ),
                if (pageNumber < 3)
                  _pixabayItem(
                    id: pageNumber * 2,
                    width: 360,
                    height: 640,
                    url: 'https://cdn.example.com/$pageNumber-b.mp4',
                  ),
              ],
            }),
            200,
          );
        }),
      );

      final videos = await source.getVideoPosts();

      expect(requestedPages, ['1', '2', '3']);
      expect(videos, hasLength(5));
      expect(videos.map((video) => video.id), [
        'pixabay:1',
        'pixabay:2',
        'pixabay:3',
        'pixabay:4',
        'pixabay:5',
      ]);
    });

    test(
      'clamps excessive Pixabay results to its 500 result API limit',
      () async {
        final requestedPages = <String?>[];
        final source = PixabayVideoDataSource(
          config: _configuredApp(),
          perPage: 200,
          client: MockClient((request) async {
            requestedPages.add(request.url.queryParameters['page']);
            return http.Response(
              jsonEncode({
                'totalHits': 1000,
                'hits': [
                  _pixabayItem(
                    id: requestedPages.length,
                    width: 360,
                    height: 640,
                    url: 'https://cdn.example.com/${requestedPages.length}.mp4',
                  ),
                ],
              }),
              200,
            );
          }),
        );

        await source.getVideoPosts();

        expect(requestedPages, ['1', '2', '3']);
      },
    );
  });

  group('VimeoVideoDataSource', () {
    test('maps oEmbed metadata for configured Vimeo URLs', () async {
      late Uri requestedUri;
      final source = VimeoVideoDataSource(
        config: AppConfig.fromMap({
          'VIMEO_VIDEO_URLS': 'https://vimeo.com/123456789',
        }),
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'title': 'A public Vimeo video',
              'description': 'Video description',
              'author_name': 'Creator',
              'thumbnail_url': 'https://i.vimeocdn.com/video/123.jpg',
              'duration': 42,
              'width': 1280,
              'height': 720,
            }),
            200,
          );
        }),
      );

      final videos = await source.getVideoPosts();

      expect(requestedUri.host, 'vimeo.com');
      expect(requestedUri.path, '/api/oembed.json');
      expect(
        requestedUri.queryParameters['url'],
        'https://vimeo.com/123456789',
      );
      expect(videos, hasLength(1));
      expect(videos.single.id, 'vimeo:123456789');
      expect(videos.single.source, VideoSourceType.vimeo);
      expect(videos.single.providerId, '123456789');
      expect(videos.single.caption, 'A public Vimeo video');
      expect(
        videos.single.thumbnailUrl,
        'https://i.vimeocdn.com/video/123.jpg',
      );
      expect(videos.single.durationSeconds, 42);
    });

    test('returns an empty list when Vimeo is not configured', () async {
      var requested = false;
      final source = VimeoVideoDataSource(
        config: AppConfig.fromMap(const {}),
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      expect(await source.getVideoPosts(), isEmpty);
      expect(requested, isFalse);
    });

    test('keeps successful videos when another Vimeo URL fails', () async {
      final source = VimeoVideoDataSource(
        config: AppConfig.fromMap({
          'VIMEO_VIDEO_URLS':
              'https://vimeo.com/123456789,https://vimeo.com/987654321',
        }),
        client: MockClient((request) async {
          if (request.url.queryParameters['url']!.endsWith('987654321')) {
            return http.Response('{}', 404);
          }
          return http.Response(
            '{"title":"Available video","thumbnail_url":"https://example.com/video.jpg"}',
            200,
          );
        }),
      );

      final videos = await source.getVideoPosts();

      expect(videos, hasLength(1));
      expect(videos.single.caption, 'Available video');
    });
  });
}

AppConfig _configuredApp() => AppConfig.fromMap({
  'YOUTUBE_API_KEY': 'test-key',
  'YOUTUBE_PLAYLIST_ID': 'playlist-id',
  'PIXABAY_API_KEY': 'test-key',
});

Map<String, Object?> _youtubeItem({
  required String videoId,
  String title = 'Video title',
  String? description,
  String? channel,
  String? thumbnail,
}) => {
  'snippet': {
    'title': title,
    'description': ?description,
    'channelTitle': ?channel,
    if (thumbnail != null)
      'thumbnails': {
        'high': {'url': thumbnail},
      },
    'resourceId': {'videoId': videoId},
  },
  'contentDetails': {'videoId': videoId},
};

Map<String, Object?> _pixabayItem({
  required int id,
  required int width,
  required int height,
  required String url,
  String tags = 'sample video',
  String? user,
}) => {
  'id': id,
  'tags': tags,
  'duration': 8,
  'user': user ?? 'creator',
  'pageURL': 'https://pixabay.com/videos/sample-$id/',
  'picture': 'https://cdn.example.com/$id.jpg',
  'videos': {
    'medium': {'url': url, 'width': width, 'height': height},
  },
};
