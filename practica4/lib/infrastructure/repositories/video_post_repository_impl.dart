import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';

class VideoPostRepositoryImpl implements VideoPostRepository {
  VideoPostRepositoryImpl(this._dataSource);

  final VideoPostDataSource _dataSource;

  @override
  Future<List<VideoPost>> getVideoPosts() => _dataSource.getVideoPosts();
}
