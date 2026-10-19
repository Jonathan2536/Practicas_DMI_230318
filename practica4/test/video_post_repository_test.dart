import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/datasources/instagram_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/local_video_post_data_source.dart';
import 'package:practica4/infrastructure/datasources/youtube_video_data_source.dart';
import 'package:practica4/infrastructure/repositories/video_post_repository_impl.dart';

void main() {
  test(
    'keeps local videos when external datasources are unconfigured',
    () async {
      final repository = VideoPostRepositoryImpl([
        LocalVideoPostDataSource(),
        YouTubeVideoDataSource(),
        InstagramVideoDataSource(),
      ]);

      final videos = await repository.getVideoPosts();

      expect(videos, isNotEmpty);
      expect(videos.first.id, startsWith('drive:'));
    },
  );

  test('throws an aggregate error when every datasource fails', () async {
    final repository = VideoPostRepositoryImpl([
      _FailingVideoDataSource(),
      _FailingVideoDataSource(),
    ]);

    await expectLater(
      repository.getVideoPosts(),
      throwsA(isA<VideoDataSourcesException>()),
    );
  });

  test('keeps the first occurrence of duplicate IDs in source order', () async {
    final first = _video('youtube:video-1', caption: 'first');
    final duplicate = _video('youtube:video-1', caption: 'duplicate');
    final second = _video('pixabay:video-1', caption: 'second');
    final repository = VideoPostRepositoryImpl([
      _VideoDataSource([first, second]),
      _VideoDataSource([duplicate]),
    ]);

    final videos = await repository.getVideoPosts();

    expect(videos.map((video) => video.id), [
      'youtube:video-1',
      'pixabay:video-1',
    ]);
    expect(videos.first.caption, 'first');
  });

  test('interleaves sources so later feeds are reachable near the top', () async {
    final repository = VideoPostRepositoryImpl([
      _VideoDataSource([
        _video('local:1'),
        _video('local:2'),
      ]),
      _VideoDataSource([_video('youtube:1')]),
      _VideoDataSource([_video('pixabay:1')]),
    ]);

    final videos = await repository.getVideoPosts();

    expect(videos.map((video) => video.id), [
      'local:1',
      'youtube:1',
      'pixabay:1',
      'local:2',
    ]);
  });

  test('starts source requests concurrently', () async {
    final localSource = _DeferredVideoDataSource();
    final youtubeSource = _DeferredVideoDataSource();
    final repository = VideoPostRepositoryImpl([localSource, youtubeSource]);

    final request = repository.getVideoPosts();
    await Future<void>.delayed(Duration.zero);

    expect(localSource.started, isTrue);
    expect(youtubeSource.started, isTrue);

    localSource.completer.complete([_video('local:1')]);
    youtubeSource.completer.complete([_video('youtube:1')]);
    await request;
  });

  test('exposes source failures without exposing the original error text', () async {
    final repository = VideoPostRepositoryImpl([
      _UnconfiguredPixabayDataSource(),
      _VideoDataSource([_video('local:one')]),
    ]);

    await repository.getVideoPosts();

    expect(repository.lastSourceFailures, hasLength(1));
    expect(repository.lastSourceFailures.single.source, 'Pixabay');
    expect(
      repository.lastSourceFailures.single.message,
      'Add the configured API key.',
    );
  });

  test('returns an empty list when there are no configured sources', () async {
    final repository = VideoPostRepositoryImpl([]);

    expect(await repository.getVideoPosts(), isEmpty);
  });

  test('continues returning successful source results after another fails', () async {
    final expected = _video('local:one');
    final repository = VideoPostRepositoryImpl([
      _FailingVideoDataSource(),
      _VideoDataSource([expected]),
    ]);

    expect(await repository.getVideoPosts(), [expected]);
  });
}

class _FailingVideoDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() =>
      Future.error(Exception('Datasource unavailable'));
}

class _VideoDataSource implements VideoPostDataSource {
  _VideoDataSource(this.videos);

  final List<VideoPost> videos;

  @override
  Future<List<VideoPost>> getVideoPosts() async => videos;
}

class _UnconfiguredPixabayDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() => Future.error(
    const UnconfiguredVideoDataSourceException(
      'Pixabay',
      'Add the configured API key.',
    ),
  );
}

class _DeferredVideoDataSource implements VideoPostDataSource {
  final Completer<List<VideoPost>> completer = Completer<List<VideoPost>>();
  bool started = false;

  @override
  Future<List<VideoPost>> getVideoPosts() {
    started = true;
    return completer.future;
  }
}

VideoPost _video(String id, {String caption = 'caption'}) => VideoPost(
  id: id,
  caption: caption,
  videoUrl: 'https://example.com/$id.mp4',
);
