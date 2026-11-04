import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';

abstract class MoviesRepository {
  Future<List<Movie>> getNowPlaying({int page = 1, MovieCountry? country});
  Future<List<Movie>> getPopular({int page = 1, MovieCountry? country});
  Future<List<Movie>> getUpcoming({int page = 1, MovieCountry? country});
  Future<List<Movie>> getTopRated({int page = 1, MovieCountry? country});
  Future<Movie> getMovieById(String movieId);
  Future<List<Movie>> searchMovies(String query, {MovieCountry? country});
}
