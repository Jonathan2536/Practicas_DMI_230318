import 'package:practica4/domain/entities/video_post.dart';

class InstagramVideoModel {
  const InstagramVideoModel({
    required this.id,
    required this.caption,
    required this.videoUrl,
  });

  final String id;
  final String caption;
  final String videoUrl;

  factory InstagramVideoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final mediaType = json['media_type'];
    final caption = json['caption'];
    final mediaUrl = json['media_url'];
    if (id is! String || id.isEmpty || mediaType is! String) {
      throw const FormatException('Instagram item has invalid media metadata.');
    }
    if (mediaType != 'VIDEO' && mediaType != 'REELS') {
      throw const FormatException('Instagram item is not a video or Reel.');
    }
    if (mediaUrl is! String || mediaUrl.isEmpty) {
      throw const FormatException('Instagram video has no playable media URL.');
    }

    final uri = Uri.tryParse(mediaUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException(
        'Instagram media URL must be a valid HTTPS video URL.',
      );
    }

    return InstagramVideoModel(
      id: id,
      caption: caption is String ? caption : '',
      videoUrl: mediaUrl,
    );
  }

  VideoPost toVideoPostEntity() => VideoPost(
    id: 'instagram:$id',
    caption: caption,
    videoUrl: videoUrl,
  );
}
