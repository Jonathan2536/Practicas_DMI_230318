import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';

class YouTubeVideoDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() async {
    throw const UnconfiguredVideoDataSourceException(
      'YouTube',
      'YouTube Data API credentials and a YouTube-capable player are required.',
    );
  }
}
