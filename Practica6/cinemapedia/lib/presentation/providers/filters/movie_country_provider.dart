import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedMovieCountryProvider = StateProvider<MovieCountry?>(
  (ref) => null,
);
