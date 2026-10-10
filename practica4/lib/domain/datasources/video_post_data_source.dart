import 'package:practica4/domain/entities/video_post.dart';

abstract interface class VideoPostDataSource {
  Future<List<VideoPost>> getVideoPosts();
}

class UnconfiguredVideoDataSourceException implements Exception {
  const UnconfiguredVideoDataSourceException(this.source, this.reason);

  final String source;
  final String reason;

  @override
  String toString() => '$source datasource is not configured: $reason';
}
