import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/widgets/video/youtube_playback_helpers.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  group('youtubeVideoIdForPlayback', () {
    test('uses the stable provider ID', () {
      final video = _video(
        id: 'youtube:AbCdEf12345',
        providerId: 'AbCdEf12345',
      );

      expect(youtubeVideoIdForPlayback(video), 'AbCdEf12345');
    });

    test('extracts the ID from a YouTube watch URL', () {
      final video = _video(
        videoUrl: 'https://www.youtube.com/watch?v=AbCdEf12345',
      );

      expect(youtubeVideoIdForPlayback(video), 'AbCdEf12345');
    });

    test('rejects malformed IDs', () {
      final video = _video(id: 'youtube:short', providerId: 'short');

      expect(youtubeVideoIdForPlayback(video), isNull);
    });
  });

  group('youtubeErrorMessageForCode', () {
    test('explains common IFrame API failures', () {
      expect(youtubeErrorMessageForCode(2), contains('identificador'));
      expect(youtubeErrorMessageForCode(5), contains('reproductor integrado'));
      expect(youtubeErrorMessageForCode(100), contains('privado'));
      expect(youtubeErrorMessageForCode(101), contains('propietario'));
      expect(youtubeErrorMessageForCode(150), contains('propietario'));
    });
  });

  group('youtubeWebResourceErrorIsFatal', () {
    test('treats a main-frame failure as fatal', () {
      expect(
        youtubeWebResourceErrorIsFatal(
          const WebResourceError(
            errorCode: -2,
            description: 'Connection failed',
            isForMainFrame: true,
          ),
        ),
        isTrue,
      );
    });

    test('ignores subresource and unclassified failures', () {
      expect(
        youtubeWebResourceErrorIsFatal(
          const WebResourceError(
            errorCode: -2,
            description: 'Connection failed',
            isForMainFrame: false,
          ),
        ),
        isFalse,
      );
      expect(
        youtubeWebResourceErrorIsFatal(
          const WebResourceError(
            errorCode: -2,
            description: 'Connection failed',
          ),
        ),
        isFalse,
      );
    });
  });
}

VideoPost _video({
  String id = 'youtube:AbCdEf12345',
  String? providerId,
  String videoUrl = 'https://example.com/video',
}) => VideoPost(
  id: id,
  caption: 'Test video',
  videoUrl: videoUrl,
  source: VideoSourceType.youtube,
  providerId: providerId,
);
