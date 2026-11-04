import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get theMovieDbKey {
    final apiKey = dotenv.env['THE_MOVIEDB_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('THE_MOVIEDB_KEY is missing from the .env file.');
    }

    return apiKey;
  }
}
