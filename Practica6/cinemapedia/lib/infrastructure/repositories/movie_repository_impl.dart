import 'package:cinemapedia/domain/datasources/movies_datasource.dart';
import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:cinemapedia/domain/repositories/movies_repository.dart';

class MovieRepositoryImpl extends MoviesRepository {
  final MoviesDatasource datasource;
  MovieRepositoryImpl(this.datasource);

  @override
  Future<List<Movie>> getNowPlaying({int page = 1, MovieCountry? country}) {
    return datasource.getNowPlaying(page: page, country: country);
  }

  @override
  Future<List<Movie>> getPopular({int page = 1, MovieCountry? country}) {
    return datasource.getPopular(page: page, country: country);
  }

  @override
  Future<List<Movie>> getUpcoming({int page = 1, MovieCountry? country}) {
    return datasource.getUpcoming(page: page, country: country);
  }

  @override
  Future<List<Movie>> getTopRated({int page = 1, MovieCountry? country}) {
    return datasource.getTopRated(page: page, country: country);
  }

  @override
  Future<Movie> getMovieById(String movieId) {
    return datasource.getMovieById(movieId);
  }

  @override
  Future<List<Movie>> searchMovies(String query, {MovieCountry? country}) {
    return datasource.searchMovies(query, country: country);
  }
}
