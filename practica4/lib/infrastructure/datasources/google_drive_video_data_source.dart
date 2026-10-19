import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/models/google_drive_video_model.dart';
import 'package:practica4/shared/data/local_video_post.dart';

class GoogleDriveVideoDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() async => videoPosts
      .map((video) => GoogleDriveVideoModel.fromJson(video).toVideoPostEntity())
      .toList();
}
