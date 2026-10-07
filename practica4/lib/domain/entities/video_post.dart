

class VideoPost {

  final String id;
  final String caption;
  final String videoUrl;
  final int likes;
  final bool isLiked;
  final bool isFavorite;
  final int views;

  VideoPost({
    required this.id,
    required this.caption,
    required this.videoUrl,
    this.likes = 0,
    this.isLiked = false,
    this.isFavorite = false,
    this.views = 0
  });

  VideoPost copyWith({
    int? likes,
    bool? isLiked,
    bool? isFavorite,
  }) {
    return VideoPost(
      id: id,
      caption: caption,
      videoUrl: videoUrl,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      isFavorite: isFavorite ?? this.isFavorite,
      views: views,
    );
  }
}
