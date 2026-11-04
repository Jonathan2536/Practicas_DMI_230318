import 'package:cinemapedia/presentation/providers/movies/movies_providers.dart';
import 'package:cinemapedia/presentation/views/movies/home_view.dart';
import 'package:cinemapedia/presentation/widgets/shared/full_screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads movies after the first frame without provider errors', (
    tester,
  ) async {
    MoviesNotifier createNotifier() =>
        MoviesNotifier(fetchMoreMovies: ({int page = 1}) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowPlayingMoviesProvider.overrideWith((ref) => createNotifier()),
          popularMoviesProvider.overrideWith((ref) => createNotifier()),
          topRatedMoviesProvider.overrideWith((ref) => createNotifier()),
          upcomingMoviesProvider.overrideWith((ref) => createNotifier()),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FullScreenLoader), findsNothing);
  });
}
