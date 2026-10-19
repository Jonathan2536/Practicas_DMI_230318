final RegExp _vimeoIdPattern = RegExp(r'^\d+$');

String? vimeoVideoIdFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      (uri.host != 'vimeo.com' && !uri.host.endsWith('.vimeo.com'))) {
    return null;
  }

  for (final segment in uri.pathSegments) {
    if (_vimeoIdPattern.hasMatch(segment)) return segment;
  }
  return null;
}
