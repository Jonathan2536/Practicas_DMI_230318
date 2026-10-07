

class VideoPost {

  final String id;
  final String caption;
  final String videoUrl;
  final int likes;
  final bool isLiked;
  final int views;

  VideoPost({
    required this.id,
    required this.caption,
    required this.videoUrl,
    this.likes = 0,
    this.isLiked = false,
    this.views = 0
  });

  VideoPost copyWith({
    int? likes,
    bool? isLiked,
  }) {
    return VideoPost(
      id: id,
      caption: caption,
      videoUrl: videoUrl,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      views: views,
    );
  }
}
