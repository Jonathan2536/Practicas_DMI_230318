import 'dart:developer' as developer;

import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';

class VideoPostRepositoryImpl implements VideoPostRepository {
  VideoPostRepositoryImpl(this._dataSources);

  final List<VideoPostDataSource> _dataSources;

  @override
  Future<List<VideoPost>> getVideoPosts() async {
    final videos = <VideoPost>[];
    final failures = <Object>[];

    for (final dataSource in _dataSources) {
      try {
        videos.addAll(await dataSource.getVideoPosts());
      } catch (error, stackTrace) {
        failures.add(error);
        developer.log(
          'Video datasource failed; trying the remaining sources.',
          name: 'VideoPostRepository',
          error: error,
          stackTrace: stackTrace,
          level: 900,
        );
      }
    }

    if (videos.isEmpty && failures.length == _dataSources.length) {
      throw VideoDataSourcesException(failures);
    }

    return videos;
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
