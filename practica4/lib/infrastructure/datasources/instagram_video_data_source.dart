import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';

class InstagramVideoDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() async {
    throw const UnconfiguredVideoDataSourceException(
      'Instagram',
      'A secure Instagram professional-account API integration is required.',
    );
  }
}
