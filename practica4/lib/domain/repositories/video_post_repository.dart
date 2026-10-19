import 'package:practica4/domain/entities/video_post.dart';

abstract interface class VideoPostRepository {
  Future<List<VideoPost>> getVideoPosts();
}

abstract interface class VideoPostRepositoryDiagnostics {
  List<VideoPostSourceFailure> get lastSourceFailures;
}

final class VideoPostSourceFailure {
  const VideoPostSourceFailure({
    required this.source,
    required this.message,
  });

  final String source;
  final String message;
}
