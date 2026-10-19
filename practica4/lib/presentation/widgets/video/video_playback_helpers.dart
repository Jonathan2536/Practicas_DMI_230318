import 'package:practica4/domain/entities/video_post.dart';

bool videoStartsMuted(VideoSourceType source) =>
    source == VideoSourceType.vimeo;

bool isUnsupportedVideoFormatError(String? errorDescription) {
  if (errorDescription == null) return false;
  final error = errorDescription.toLowerCase();
  return error.contains('decoderinitializationexception') ||
      error.contains('decoder init failed') ||
      error.contains('decoding_format_unsupported') ||
      error.contains('decoding_format_exceeds_capabilities') ||
      error.contains('no_exceeds_capabilities');
}
