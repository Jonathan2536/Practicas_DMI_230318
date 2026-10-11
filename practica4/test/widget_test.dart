import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';
import 'package:practica4/domain/services/local_storage_service.dart';
import 'package:practica4/infrastructure/datasources/instagram_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/local_video_post_data_source.dart';
import 'package:practica4/infrastructure/datasources/youtube_video_data_source.dart';
import 'package:practica4/infrastructure/models/local_video_model.dart';
import 'package:practica4/infrastructure/repositories/video_post_repository_impl.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/screens/discover/discover_screen.dart';
import 'package:practica4/presentation/widgets/video/video_caption.dart';
import 'package:practica4/shared/data/local_video_post.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

DiscoverProvider createDiscoverProvider(LocalStorageService storage) {
  final repository = VideoPostRepositoryImpl([
    LocalVideoPostDataSource(),
    YouTubeVideoDataSource(),
    InstagramVideoDataSource(),
  ]);
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

  test(
    'For You sorts posts by views without changing Discover order',
    () async {
      final provider = createDiscoverProvider(storage);
      await provider.loadNextPage();

      expect(
        provider.forYouVideos.first.views,
        provider.videos
            .map((video) => video.views)
            .reduce((a, b) => a > b ? a : b),
      );
      expect(provider.videos.first.id, videoPosts.first['id']);
    },
  );

  test('local datasource loads posts and preserves their stable IDs', () async {
    final videos = await LocalVideoPostDataSource().getVideoPosts();

    expect(videos, hasLength(videoPosts.length));
    expect(videos.map((video) => video.id).toSet(), hasLength(videos.length));
    expect(videos.first.id, videoPosts.first['id']);
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
    expect(provider.favoriteVideos, [updatedVideo]);
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
    expect(provider.favoriteVideos, isEmpty);
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

  testWidgets('horizontal page swipes navigate between video sections', (
    tester,
  ) async {
    final provider = DiscoverProvider(_EmptyVideoRepository(), storage);
    await provider.loadNextPage();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<DiscoverProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('section-semantic-Discover')),
          )
          .properties
          .selected,
      isTrue,
    );

    await tester.drag(
      find.byKey(const ValueKey('video-sections-page-view')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('section-semantic-For You')),
          )
          .properties
          .selected,
      isTrue,
    );

    await tester.drag(
      find.byKey(const ValueKey('video-sections-page-view')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('No tienes videos favoritos'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('section-semantic-Favorites')),
          )
          .properties
          .selected,
      isTrue,
    );
  });

  testWidgets('short captions do not show the expand action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: VideoCaption(caption: 'Descripción breve'),
          ),
        ),
      ),
    );

    expect(find.text('Descripción breve'), findsOneWidget);
    expect(find.text('... más'), findsNothing);
  });

  testWidgets('long captions open a scrollable full description', (
    tester,
  ) async {
    final longCaption = List.filled(
      20,
      'Una descripción extensa que permite recorrer el contenido completo '
      'verticalmente y regresar al feed cuando se cierra.',
    ).join('\n\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 240, child: VideoCaption(caption: longCaption)),
        ),
      ),
    );

    expect(find.text('... más'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-full-caption')));
    await tester.pumpAndSettle();

    final scrollable = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('full-caption-scroll')),
    );
    expect(scrollable.controller, isNull);
    final fullCaption = find.descendant(
      of: find.byKey(const ValueKey('full-caption-scroll')),
      matching: find.text(longCaption),
    );
    expect(fullCaption, findsOneWidget);
    final scrollPosition = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('full-caption-scroll')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(scrollPosition.pixels, 0);

    await tester.drag(
      find.byKey(const ValueKey('full-caption-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(scrollPosition.pixels, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('close-full-caption')));
    await tester.pumpAndSettle();
    expect(find.text('... más'), findsOneWidget);
  });
}

class _EmptyVideoRepository implements VideoPostRepository {
  @override
  Future<List<VideoPost>> getVideoPosts() async => [];
}
