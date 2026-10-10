import 'package:practica4/domain/entities/video_post.dart';

abstract interface class VideoPostRepository {
  Future<List<VideoPost>> getVideoPosts();
}
