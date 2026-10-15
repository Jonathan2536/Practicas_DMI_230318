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
}
