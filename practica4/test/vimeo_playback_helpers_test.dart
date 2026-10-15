import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/config/helpers/vimeo_video_id.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/widgets/video/vimeo_playback_helpers.dart';

void main() {
  group('vimeoVideoIdFromUrl', () {
    test('extracts IDs from standard and player URLs', () {
      expect(vimeoVideoIdFromUrl('https://vimeo.com/123456789'), '123456789');
      expect(
        vimeoVideoIdFromUrl('https://player.vimeo.com/video/987654321'),
        '987654321',
      );
    });

    test('rejects non-Vimeo hosts and malformed IDs', () {
      expect(vimeoVideoIdFromUrl('https://example.com/123456789'), isNull);
      expect(vimeoVideoIdFromUrl('https://vimeo.com/not-a-number'), isNull);
    });
  });

  group('vimeoEmbedUriForPlayback', () {
    test('keeps the privacy hash for unlisted videos', () {
      final uri = vimeoEmbedUriForPlayback(
        VideoPost(
          id: 'vimeo:123456789',
          caption: 'Unlisted video',
          videoUrl: 'https://vimeo.com/123456789?share=copy&h=secretHash',
          source: VideoSourceType.vimeo,
          providerId: '123456789',
        ),
      );

      expect(uri?.host, 'player.vimeo.com');
      expect(uri?.path, '/video/123456789');
      expect(uri?.queryParameters['h'], 'secretHash');
      expect(uri?.queryParameters['muted'], '1');
      expect(uri?.queryParameters['api'], '1');
    });

    test('returns null for posts without a valid Vimeo ID', () {
      final uri = vimeoEmbedUriForPlayback(
        VideoPost(
          id: 'bad-vimeo',
          caption: 'Invalid',
          videoUrl: 'https://example.com/video',
          source: VideoSourceType.vimeo,
        ),
      );

      expect(uri, isNull);
    });
  });
}
