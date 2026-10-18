import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/widgets/video/video_playback_helpers.dart';

void main() {
  test('YouTube and direct video sources do not start muted', () {
    expect(videoStartsMuted(VideoSourceType.youtube), isFalse);
    expect(videoStartsMuted(VideoSourceType.local), isFalse);
    expect(videoStartsMuted(VideoSourceType.pixabay), isFalse);
  });

  test('Vimeo starts muted for embedded autoplay compatibility', () {
    expect(videoStartsMuted(VideoSourceType.vimeo), isTrue);
  });

  test(
    'identifies unsupported decoder formats without matching network errors',
    () {
      expect(
        isUnsupportedVideoFormatError(
          'DecoderInitializationException: '
          'format_supported=NO_EXCEEDS_CAPABILITIES',
        ),
        isTrue,
      );
      expect(
        isUnsupportedVideoFormatError(
          'ExoPlaybackException: ERROR_CODE_DECODING_FORMAT_UNSUPPORTED',
        ),
        isTrue,
      );
      expect(
        isUnsupportedVideoFormatError('HttpDataSourceException: 404 Not Found'),
        isFalse,
      );
      expect(isUnsupportedVideoFormatError(null), isFalse);
    },
  );
}
