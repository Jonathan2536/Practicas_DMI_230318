import 'package:practica4/domain/entities/video_post.dart';

class GoogleDriveVideoModel {
  final String id;
  final String name;
  final String videoUrl;
  final int likes;
  final int views;

  GoogleDriveVideoModel({
    required this.id,
    required this.name,
    required this.videoUrl,
    this.likes = 0,
    this.views = 0,
  });

  factory GoogleDriveVideoModel.fromJson(Map<String, dynamic> json) {
    final videoUrl = json['videoUrl'] ?? '';
    final uri = Uri.tryParse(videoUrl);
    final driveId = uri?.queryParameters['id'];
    final fallbackId = uri?.host == 'drive.google.com' && driveId != null
        ? 'drive:$driveId'
        : videoUrl;

    return GoogleDriveVideoModel(
      id: json['id'] ?? fallbackId,
      name: json['name'] ?? '',
      videoUrl: videoUrl,
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  VideoPost toVideoPostEntity() => VideoPost(
    id: id,
    caption: name,
    videoUrl: videoUrl,
    likes: likes,
    views: views,
  );
}
