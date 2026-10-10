import 'package:practica4/domain/entities/video_post.dart';

abstract interface class VideoPostDataSource {
  Future<List<VideoPost>> getVideoPosts();
}
