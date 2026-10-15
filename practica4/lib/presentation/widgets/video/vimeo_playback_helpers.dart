import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/config/helpers/vimeo_video_id.dart';

final RegExp _vimeoHashPattern = RegExp(r'^[A-Za-z0-9_-]+$');

String? vimeoVideoIdForPlayback(VideoPost video) {
  final providerId = video.providerId;
  if (providerId != null && RegExp(r'^\d+$').hasMatch(providerId)) {
    return providerId;
  }
  return vimeoVideoIdFromUrl(video.playbackUrl);
}

Uri? vimeoEmbedUriForPlayback(VideoPost video) {
  final videoId = vimeoVideoIdForPlayback(video);
  if (videoId == null) return null;

  final sourceUri = Uri.tryParse(video.playbackUrl);
  final privacyHash = sourceUri?.queryParameters['h'] ??
      _privacyHashFromPath(sourceUri?.pathSegments ?? const []);
  return Uri.https(
    'player.vimeo.com',
    '/video/$videoId',
    {
      'autoplay': '1',
      'api': '1',
      'muted': '1',
      'playsinline': '1',
      'controls': '1',
      if (_vimeoHashPattern.hasMatch(privacyHash))
        'h': privacyHash,
    },
  );
}

String _privacyHashFromPath(List<String> segments) {
  if (segments.length > 1 &&
      segments.first != 'video' &&
      RegExp(r'^\d+$').hasMatch(segments.first)) {
    return segments[1];
  }
  return '';
}
