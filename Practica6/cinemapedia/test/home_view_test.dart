import 'package:cinemapedia/presentation/providers/movies/movies_providers.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:cinemapedia/presentation/views/movies/home_view.dart';
import 'package:cinemapedia/presentation/widgets/shared/full_screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads movies after the first frame without provider errors', (
    tester,
  ) async {
    MoviesNotifier createNotifier() => MoviesNotifier(
      fetchMoreMovies: ({int page = 1, MovieCountry? country}) async => [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowPlayingMoviesProvider.overrideWith(
            (ref, country) => createNotifier(),
          ),
          popularMoviesProvider.overrideWith(
            (ref, country) => createNotifier(),
          ),
          topRatedMoviesProvider.overrideWith(
            (ref, country) => createNotifier(),
          ),
          upcomingMoviesProvider.overrideWith(
            (ref, country) => createNotifier(),
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FullScreenLoader), findsNothing);
  });
}
