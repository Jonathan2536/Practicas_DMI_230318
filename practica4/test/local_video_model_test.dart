import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/models/local_video_model.dart';

void main() {
  test('maps Drive records without changing their persisted IDs', () {
    final model = LocalVideoModel.fromJson({
      'id': 'drive:drive-id',
      'name': 'Drive video',
      'videoUrl': 'https://drive.google.com/uc?export=download&id=drive-id',
    });

    final video = model.toVideoPostEntity();

    expect(video.id, 'drive:drive-id');
    expect(video.source, VideoSourceType.local);
    expect(video.providerId, 'drive-id');
    expect(
      video.playbackUrl,
      'https://drive.google.com/uc?export=download&id=drive-id',
    );
  });

  test('derives the provider ID even when a legacy ID is not prefixed', () {
    final video = LocalVideoModel.fromJson({
      'id': 'legacy-id',
      'name': 'Legacy Drive video',
      'videoUrl': 'https://drive.google.com/uc?export=download&id=drive-id',
    }).toVideoPostEntity();

    expect(video.id, 'legacy-id');
    expect(video.providerId, 'drive-id');
  });
}
