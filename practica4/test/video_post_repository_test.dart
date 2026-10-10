import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/datasources/instagram_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/local_video_post_data_source.dart';
import 'package:practica4/infrastructure/datasources/youtube_video_data_source.dart';
import 'package:practica4/infrastructure/repositories/video_post_repository_impl.dart';

void main() {
  test(
    'keeps local videos when external datasources are unconfigured',
    () async {
      final repository = VideoPostRepositoryImpl([
        LocalVideoPostDataSource(),
        YouTubeVideoDataSource(),
        InstagramVideoDataSource(),
      ]);

      final videos = await repository.getVideoPosts();

      expect(videos, isNotEmpty);
      expect(videos.first.id, startsWith('drive:'));
    },
  );

  test('throws an aggregate error when every datasource fails', () async {
    final repository = VideoPostRepositoryImpl([
      _FailingVideoDataSource(),
      _FailingVideoDataSource(),
    ]);

    await expectLater(
      repository.getVideoPosts(),
      throwsA(isA<VideoDataSourcesException>()),
    );
  });
}

class _FailingVideoDataSource implements VideoPostDataSource {
  @override
  Future<List<VideoPost>> getVideoPosts() =>
      Future.error(Exception('Datasource unavailable'));
}
