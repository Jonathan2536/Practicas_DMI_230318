import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/config/environment/app_config.dart';

void main() {
  group('AppConfig', () {
    test('returns configured values without surrounding whitespace', () {
      final config = AppConfig.fromMap({
        'YOUTUBE_API_KEY': '  test-key  ',
        'YOUTUBE_PLAYLIST_ID': ' playlist-id ',
        'PIXABAY_API_KEY': ' pixabay-key ',
        'VIMEO_VIDEO_URLS': ' https://vimeo.com/12345, ,https://vimeo.com/67890 ',
      });

      expect(config.youtubeApiKey, 'test-key');
      expect(config.youtubePlaylistId, 'playlist-id');
      expect(config.pixabayApiKey, 'pixabay-key');
      expect(config.vimeoVideoUrls, [
        'https://vimeo.com/12345',
        'https://vimeo.com/67890',
      ]);
    });

    test('reports the name of a missing variable', () {
      final config = AppConfig.fromMap(const {});

      expect(
        () => config.youtubeApiKey,
        throwsA(
          isA<MissingAppConfigurationException>().having(
            (error) => error.message,
            'message',
            contains('YOUTUBE_API_KEY'),
          ),
        ),
      );
    });

    test('treats an empty value as missing', () {
      final config = AppConfig.fromMap({'PIXABAY_API_KEY': '  '});

      expect(
        () => config.pixabayApiKey,
        throwsA(isA<MissingAppConfigurationException>()),
      );
    });

    test('treats Vimeo URLs as optional', () {
      expect(AppConfig.fromMap(const {}).vimeoVideoUrls, isEmpty);
    });
  });
}
