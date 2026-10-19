import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/models/local_video_model.dart';
import 'package:practica4/shared/data/local_video_post.dart';

class LocalVideoPostDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() async => videoPosts
      .map((video) => LocalVideoModel.fromJson(video).toVideoPostEntity())
      .toList();
}
