import 'package:practica4/domain/entities/video_post.dart';

final RegExp _youtubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

String? youtubeVideoIdForPlayback(VideoPost video) {
  final providerId = video.providerId;
  if (providerId != null && _youtubeIdPattern.hasMatch(providerId)) {
    return providerId;
  }

  if (video.id.startsWith('youtube:')) {
    final id = video.id.substring('youtube:'.length);
    if (_youtubeIdPattern.hasMatch(id)) return id;
  }

  final uri = Uri.tryParse(video.playbackUrl);
  if (uri == null) return null;

  final id = switch (uri.host.toLowerCase()) {
    'youtu.be' => uri.pathSegments.isEmpty ? null : uri.pathSegments.first,
    'youtube.com' || 'www.youtube.com' =>
      uri.queryParameters['v'] ?? _embeddedId(uri.pathSegments),
    _ => null,
  };

  return id != null && _youtubeIdPattern.hasMatch(id) ? id : null;
}

String? _embeddedId(List<String> pathSegments) {
  if (pathSegments.length < 2) return null;
  if (pathSegments.first == 'embed' || pathSegments.first == 'shorts') {
    return pathSegments[1];
  }
  return null;
}

String youtubeErrorMessageForCode(int code) => switch (code) {
  2 => 'El identificador de YouTube no es válido.',
  5 => 'YouTube no pudo reproducir este video en el reproductor integrado.',
  100 => 'El video fue eliminado, es privado o ya no está disponible.',
  101 || 150 =>
    'El propietario no permite reproducir este video dentro de la aplicación.',
  _ => 'YouTube no pudo reproducir este video (error $code).',
};
