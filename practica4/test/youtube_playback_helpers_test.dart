import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/widgets/video/youtube_playback_helpers.dart';

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
