
enum VideoSourceType { local, youtube, pixabay, vimeo }

class VideoPost {
  final String id;
  final String caption;
  final String videoUrl;
  final VideoSourceType source;
  final String? providerId;
  final String? thumbnailUrl;
  final String? attribution;
  final String? description;
  final String? tags;
  final int? durationSeconds;
  final int? width;
  final int? height;
  final int likes;
  final bool isLiked;
  final bool isFavorite;
  final int views;

  VideoPost({
    required this.id,
    required this.caption,
    required this.videoUrl,
    this.source = VideoSourceType.local,
    this.providerId,
    this.thumbnailUrl,
    this.attribution,
    this.description,
    this.tags,
    this.durationSeconds,
    this.width,
    this.height,
    this.likes = 0,
    this.isLiked = false,
    this.isFavorite = false,
    this.views = 0,
  });

  String get playbackUrl => videoUrl;

  VideoPost copyWith({
    int? likes,
    bool? isLiked,
    bool? isFavorite,
    VideoSourceType? source,
    String? providerId,
    String? thumbnailUrl,
    String? attribution,
    String? description,
    String? tags,
    int? durationSeconds,
    int? width,
    int? height,
  }) {
    return VideoPost(
      id: id,
      caption: caption,
      videoUrl: videoUrl,
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      attribution: attribution ?? this.attribution,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      width: width ?? this.width,
      height: height ?? this.height,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      isFavorite: isFavorite ?? this.isFavorite,
      views: views,
    );
  }
}
