import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/entities/video_post.dart';

void main() {
  test('copyWith preserves source and provider metadata', () {
    final video = VideoPost(
      id: 'youtube:video-id',
      caption: 'A video',
      videoUrl: 'https://youtube.com/watch?v=video-id',
      source: VideoSourceType.youtube,
      providerId: 'video-id',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      attribution: 'Example channel',
      likes: 10,
    );

    final updated = video.copyWith(isFavorite: true);

    expect(updated.source, VideoSourceType.youtube);
    expect(updated.providerId, 'video-id');
    expect(updated.thumbnailUrl, 'https://example.com/thumbnail.jpg');
    expect(updated.attribution, 'Example channel');
    expect(updated.playbackUrl, video.videoUrl);
    expect(updated.isFavorite, isTrue);
  });

  test('defaults existing constructor calls to the local source', () {
    final video = VideoPost(
      id: 'drive:drive-id',
      caption: 'A local-feed video',
      videoUrl: 'https://example.com/video.mp4',
    );

    expect(video.source, VideoSourceType.local);
  });
}
