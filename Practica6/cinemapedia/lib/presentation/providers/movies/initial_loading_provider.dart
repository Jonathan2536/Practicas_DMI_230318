import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'movies_providers.dart';

final initialLoadingProvider = Provider<bool>((ref) {
  final states = [
    ref.watch(nowPlayingMoviesProvider),
    ref.watch(popularMoviesProvider),
    ref.watch(topRatedMoviesProvider),
    ref.watch(upcomingMoviesProvider),
  ];

  return states.any((state) => state.isLoading);
});

final initialMoviesErrorProvider = Provider<Object?>((ref) {
  final states = [
    ref.watch(nowPlayingMoviesProvider),
    ref.watch(popularMoviesProvider),
    ref.watch(topRatedMoviesProvider),
    ref.watch(upcomingMoviesProvider),
  ];

  for (final state in states) {
    if (state.error != null && state.movies.isEmpty) return state.error;
  }

  return null;
});
