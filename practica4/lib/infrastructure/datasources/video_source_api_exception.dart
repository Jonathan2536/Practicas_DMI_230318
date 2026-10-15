import 'dart:convert';

enum VideoSourceFailureKind {
  authentication,
  accessDenied,
  quotaExceeded,
  rateLimited,
  http,
  invalidResponse,
  network,
}

class VideoSourceApiException implements Exception {
  const VideoSourceApiException(
    this.source,
    this.message, {
    required this.kind,
    this.statusCode,
  });

  final String source;
  final String message;
  final VideoSourceFailureKind kind;
  final int? statusCode;

  @override
  String toString() => '$source: $message';
}

Map<String, dynamic> decodeJsonObject(String body, String source) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw VideoSourceApiException(
      source,
      'The service returned malformed JSON.',
      kind: VideoSourceFailureKind.invalidResponse,
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw VideoSourceApiException(
      source,
      'The service returned an unexpected response.',
      kind: VideoSourceFailureKind.invalidResponse,
    );
  }
  return decoded;
}

Map<String, dynamic>? jsonObject(Object? value) =>
    value is Map<String, dynamic> ? value : null;

String? validHttpUrl(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty) {
    return null;
  }
  return value;
}
