import 'package:practica4/domain/entities/video_post.dart';

class LocalVideoModel {
  final String id;
  final String name;
  final String videoUrl;
  final int likes;
  final int views;

  LocalVideoModel({
    required this.id,
    required this.name, 
    required this.videoUrl, 
    this.likes = 0, 
    this.views = 0,
  });


  factory LocalVideoModel.fromJson(Map<String, dynamic> json) => LocalVideoModel(
    id: json['id'] ?? json['videoUrl'] ?? '',
    name: json['name'] ?? '',
    videoUrl: json['videoUrl'] ?? '',
    likes: json['likes'] ?? 0,
    views: json['views'] ?? 0,
  );


  VideoPost toVideoPostEntity() => VideoPost(
    id: id,
    caption: name, 
    videoUrl: videoUrl,
    likes: likes,
    views: views,
  );
}
