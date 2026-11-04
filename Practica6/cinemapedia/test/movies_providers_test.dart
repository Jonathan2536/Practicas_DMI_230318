import 'dart:async';

import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:cinemapedia/presentation/providers/movies/movies_providers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the TMDB key from the bundled environment asset', () async {
    await dotenv.load(fileName: '.env');

    expect(dotenv.env['THE_MOVIEDB_KEY']?.trim(), isNotEmpty);
  });

  test('a failed request stops loading and can be retried', () async {
    final requestedPages = <int>[];
    final notifier = MoviesNotifier(
      fetchMoreMovies: ({int page = 1, MovieCountry? country}) async {
        requestedPages.add(page);
        if (requestedPages.length == 1) {
          throw StateError('TMDB unavailable');
        }
        return [];
      },
    );

    await notifier.loadNextPage();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isA<StateError>());

    await notifier.loadNextPage();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNull);
    expect(requestedPages, [1, 1]);

    notifier.dispose();
  });

  test('a request timeout stops the loading state', () async {
    final notifier = MoviesNotifier(
      requestTimeout: const Duration(milliseconds: 1),
      fetchMoreMovies: ({int page = 1, MovieCountry? country}) =>
          Completer<List<Movie>>().future,
    );

    await notifier.loadNextPage();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isA<TimeoutException>());

    notifier.dispose();
  });
}
