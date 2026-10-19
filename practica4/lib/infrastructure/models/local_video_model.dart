import 'package:practica4/domain/entities/video_post.dart';

class LocalVideoModel {
  final String id;
  final String? providerId;
  final String name;
  final String videoUrl;
  final int likes;
  final int views;

  LocalVideoModel({
    required this.id,
    this.providerId,
    required this.name,
    required this.videoUrl,
    this.likes = 0,
    this.views = 0,
  });

  factory LocalVideoModel.fromJson(Map<String, dynamic> json) {
    final videoUrl = json['videoUrl'] ?? '';
    final uri = Uri.tryParse(videoUrl);
    final isGoogleDrive = uri?.host == 'drive.google.com';
    final driveId = isGoogleDrive ? uri?.queryParameters['id'] : null;
    final fallbackId = driveId != null
        ? 'drive:$driveId'
        : videoUrl;

    return LocalVideoModel(
      id: json['id'] ?? fallbackId,
      providerId: driveId,
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
    source: VideoSourceType.local,
    providerId: providerId,
    likes: likes,
    views: views,
  );
}
