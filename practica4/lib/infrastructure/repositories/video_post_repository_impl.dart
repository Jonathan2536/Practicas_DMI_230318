import 'dart:developer' as developer;

import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';
import 'package:practica4/infrastructure/datasources/video_source_api_exception.dart';

class VideoPostRepositoryImpl
    implements VideoPostRepository, VideoPostRepositoryDiagnostics {
  VideoPostRepositoryImpl(this._dataSources);

  final List<VideoPostDataSource> _dataSources;
  List<VideoPostSourceFailure> _lastSourceFailures = const [];

  @override
  List<VideoPostSourceFailure> get lastSourceFailures => _lastSourceFailures;

  @override
  Future<List<VideoPost>> getVideoPosts() async {
    final results = await Future.wait(_dataSources.map(_loadSource));
    final failures = results
        .where((result) => result.failure != null)
        .map((result) => result.failure!)
        .toList(growable: false);
    _lastSourceFailures = List.unmodifiable(
      results
          .where((result) => result.diagnostic != null)
          .map((result) => result.diagnostic!),
    );

    final videos = _interleave(results.map((result) => result.videos));

    if (_dataSources.isNotEmpty &&
        videos.isEmpty &&
        failures.length == _dataSources.length) {
      throw VideoDataSourcesException(failures);
    }

    final uniqueVideos = <String, VideoPost>{};
    for (final video in videos) {
      uniqueVideos.putIfAbsent(video.id, () => video);
    }
    return uniqueVideos.values.toList(growable: false);
  }

  Future<_DataSourceResult> _loadSource(
    VideoPostDataSource dataSource,
  ) async {
    try {
      return _DataSourceResult(videos: await dataSource.getVideoPosts());
    } catch (error, stackTrace) {
      final source = switch (error) {
        VideoSourceApiException() => error.source,
        UnconfiguredVideoDataSourceException() => error.source,
        _ => dataSource.runtimeType.toString(),
      };
      final message = switch (error) {
        VideoSourceApiException() => error.message,
        UnconfiguredVideoDataSourceException() => error.reason,
        _ => 'Unexpected source error (${error.runtimeType}).',
      };
      developer.log(
        '$source datasource failed: $message',
        name: 'VideoPostRepository',
        stackTrace: stackTrace,
        level: 900,
      );
      return _DataSourceResult(
        videos: const [],
        failure: error,
        diagnostic: VideoPostSourceFailure(source: source, message: message),
      );
    }
  }

  List<VideoPost> _interleave(Iterable<List<VideoPost>> sourceVideos) {
    final sources = sourceVideos.toList(growable: false);
    final interleaved = <VideoPost>[];
    final longestSource = sources.fold<int>(
      0,
      (longest, source) => source.length > longest ? source.length : longest,
    );

    for (var index = 0; index < longestSource; index++) {
      for (final source in sources) {
        if (index < source.length) interleaved.add(source[index]);
      }
    }
    return interleaved;
  }
}

class VideoDataSourcesException implements Exception {
  const VideoDataSourcesException(this.failures);

  final List<Object> failures;

  @override
  String toString() =>
      'All ${failures.length} video data sources failed: '
      '${failures.join('; ')}';
}

class _DataSourceResult {
  const _DataSourceResult({
    required this.videos,
    this.failure,
    this.diagnostic,
  });

  final List<VideoPost> videos;
  final Object? failure;
  final VideoPostSourceFailure? diagnostic;
}
