import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';

import 'movies_providers.dart';

final moviesSlideshowProvider = Provider.family<List<Movie>, MovieCountry?>((
  ref,
  country,
) {
  final nowPlayingMovies = ref.watch(nowPlayingMoviesProvider(country)).movies;

  if (nowPlayingMovies.isEmpty) return [];

  return nowPlayingMovies.take(6).toList();
});
