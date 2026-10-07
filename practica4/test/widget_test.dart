import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/infrastructure/models/local_video_model.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/shared/data/local_video_post.dart';

void main() {
  test('loads the initial video posts', () async {
    final provider = DiscoverProvider();

    await provider.loadNextPage();

    expect(provider.initialLoading, isFalse);
    expect(provider.videos, isNotEmpty);
  });

  test('preserves stable unique video IDs through the model mapper', () {
    final models = videoPosts.map(LocalVideoModel.fromJson).toList();
    final entities = models.map((model) => model.toVideoPostEntity()).toList();
    final ids = entities.map((video) => video.id).toList();

    expect(ids, hasLength(8));
    expect(ids.toSet(), hasLength(ids.length));
    expect(entities.map((video) => video.id), models.map((model) => model.id));
    expect(
      entities.map((video) => video.videoUrl),
      videoPosts.map((video) => video['videoUrl']),
    );
  });
}
