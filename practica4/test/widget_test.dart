import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/services/local_storage_service.dart';
import 'package:practica4/infrastructure/datasources/local_video_post_data_source.dart';
import 'package:practica4/infrastructure/models/local_video_model.dart';
import 'package:practica4/infrastructure/repositories/video_post_repository_impl.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/shared/data/local_video_post.dart';
import 'package:shared_preferences/shared_preferences.dart';

DiscoverProvider createDiscoverProvider(LocalStorageService storage) {
  final repository = VideoPostRepositoryImpl(LocalVideoPostDataSource());
  return DiscoverProvider(repository, storage);
}

void main() {
  late SharedPreferencesStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = SharedPreferencesStorageService();
    await storage.initialize();
  });

  test('loads the initial video posts', () async {
    final provider = createDiscoverProvider(storage);

    await provider.loadNextPage();

    expect(provider.initialLoading, isFalse);
    expect(provider.videos, isNotEmpty);
  });

  test('preserves stable unique video IDs through the model mapper', () {
    final models = videoPosts.map(LocalVideoModel.fromJson).toList();
    final entities = models.map((model) => model.toVideoPostEntity()).toList();
    final ids = entities.map((video) => video.id).toList();

    expect(ids, hasLength(videoPosts.length));
    expect(ids.toSet(), hasLength(ids.length));
    expect(entities.map((video) => video.id), models.map((model) => model.id));
    expect(
      ids,
      videoPosts.map(
        (video) =>
            'drive:${Uri.parse(video['videoUrl']).queryParameters['id']}',
      ),
    );
    expect(
      entities.map((video) => video.videoUrl),
      videoPosts.map((video) => video['videoUrl']),
    );
  });

  test('derives the same stable ID for legacy video records', () {
    final video = videoPosts.first;
    final legacyRecord = Map<String, dynamic>.from(video)..remove('id');

    expect(LocalVideoModel.fromJson(legacyRecord).id, video['id']);
  });

  test('toggles a like and updates its count exactly once', () async {
    final provider = createDiscoverProvider(storage);
    await provider.loadNextPage();

    final video = provider.videos.first;
    final initialLikes = video.likes;

    final firstToggle = provider.toggleLike(video.id);
    final secondToggle = provider.toggleLike(video.id);
    await Future.wait([firstToggle, secondToggle]);

    final likedVideo = provider.videos.first;
    expect(likedVideo.isLiked, isTrue);
    expect(likedVideo.likes, initialLikes + 1);

    await provider.toggleLike(video.id);

    final unlikedVideo = provider.videos.first;
    expect(unlikedVideo.isLiked, isFalse);
    expect(unlikedVideo.likes, initialLikes);
  });

  test(
    'restores the liked state and count after provider recreation',
    () async {
      final provider = createDiscoverProvider(storage);
      await provider.loadNextPage();
      final video = provider.videos.first;
      await provider.toggleLike(video.id);

      final restartedProvider = createDiscoverProvider(storage);
      await restartedProvider.loadNextPage();

      final restoredVideo = restartedProvider.videos.first;
      expect(restoredVideo.id, video.id);
      expect(restoredVideo.isLiked, isTrue);
      expect(restoredVideo.likes, video.likes + 1);
    },
  );

  test('toggles favorites independently from likes', () async {
    final provider = createDiscoverProvider(storage);
    await provider.loadNextPage();

    final video = provider.videos.first;
    final initialLikes = video.likes;

    await provider.toggleFavorite(video.id);

    var updatedVideo = provider.videos.first;
    expect(updatedVideo.isFavorite, isTrue);
    expect(updatedVideo.isLiked, isFalse);
    expect(updatedVideo.likes, initialLikes);

    await provider.toggleLike(video.id);

    updatedVideo = provider.videos.first;
    expect(updatedVideo.isFavorite, isTrue);
    expect(updatedVideo.isLiked, isTrue);
    expect(updatedVideo.likes, initialLikes + 1);

    await provider.toggleFavorite(video.id);

    updatedVideo = provider.videos.first;
    expect(updatedVideo.isFavorite, isFalse);
    expect(updatedVideo.isLiked, isTrue);
    expect(updatedVideo.likes, initialLikes + 1);
  });

  test('restores favorite state after provider recreation', () async {
    final provider = createDiscoverProvider(storage);
    await provider.loadNextPage();
    final video = provider.videos.first;
    await provider.toggleFavorite(video.id);

    final restartedProvider = createDiscoverProvider(storage);
    await restartedProvider.loadNextPage();

    final restoredVideo = restartedProvider.videos.first;
    expect(restoredVideo.id, video.id);
    expect(restoredVideo.isFavorite, isTrue);
    expect(restoredVideo.isLiked, isFalse);
    expect(restoredVideo.likes, video.likes);
  });

  test(
    'ignores duplicate favorite toggles while persistence is pending',
    () async {
      final provider = createDiscoverProvider(storage);
      await provider.loadNextPage();
      final video = provider.videos.first;

      final firstToggle = provider.toggleFavorite(video.id);
      final secondToggle = provider.toggleFavorite(video.id);
      await Future.wait([firstToggle, secondToggle]);

      expect(provider.videos.first.isFavorite, isTrue);
      expect(await storage.getBool('video_favorite_${video.id}'), isTrue);
    },
  );
}
