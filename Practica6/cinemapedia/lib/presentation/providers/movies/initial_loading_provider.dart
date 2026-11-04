import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/movie_country.dart';
import 'movies_providers.dart';

final initialLoadingProvider = Provider.family<bool, MovieCountry?>((
  ref,
  country,
) {
  final states = [
    ref.watch(nowPlayingMoviesProvider(country)),
    ref.watch(popularMoviesProvider(country)),
    ref.watch(topRatedMoviesProvider(country)),
    ref.watch(upcomingMoviesProvider(country)),
  ];

  return states.any((state) => state.isLoading);
});

final initialMoviesErrorProvider = Provider.family<Object?, MovieCountry?>((
  ref,
  country,
) {
  final states = [
    ref.watch(nowPlayingMoviesProvider(country)),
    ref.watch(popularMoviesProvider(country)),
    ref.watch(topRatedMoviesProvider(country)),
    ref.watch(upcomingMoviesProvider(country)),
  ];

  for (final state in states) {
    if (state.error != null && state.movies.isEmpty) return state.error;
  }

  return null;
});
