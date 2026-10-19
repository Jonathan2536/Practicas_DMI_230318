import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._(this._values);

  static AppConfig _instance = const AppConfig._({});

  final Map<String, String> _values;

  static AppConfig get instance => _instance;

  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
    _instance = AppConfig._(Map<String, String>.unmodifiable(dotenv.env));
  }

  factory AppConfig.fromMap(Map<String, String> values) =>
      AppConfig._(Map<String, String>.unmodifiable(values));

  String get youtubeApiKey => _required('YOUTUBE_API_KEY');

  String get youtubePlaylistId => _required('YOUTUBE_PLAYLIST_ID');

  String get pixabayApiKey => _required('PIXABAY_API_KEY');

  List<String> get vimeoVideoUrls => List.unmodifiable(
    (_values['VIMEO_VIDEO_URLS'] ?? '')
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty),
  );

  String _required(String variableName) {
    final value = _values[variableName]?.trim();
    if (value == null || value.isEmpty) {
      throw MissingAppConfigurationException(variableName);
    }
    return value;
  }
}

class MissingAppConfigurationException implements Exception {
  const MissingAppConfigurationException(this.variableName);

  final String variableName;

  String get message => 'Missing required configuration: $variableName.';

  @override
  String toString() => message;
}
