import 'package:dio/dio.dart';

import 'package:cinemapedia/config/constants/environment.dart';
import 'package:cinemapedia/domain/datasources/movies_datasource.dart';

import 'package:cinemapedia/infrastructure/mappers/movie_mapper.dart';
import 'package:cinemapedia/infrastructure/models/moviedb/moviedb_response.dart';
import 'package:cinemapedia/infrastructure/models/moviedb/movie_details.dart';
import 'package:cinemapedia/domain/entities/movie.dart';

class MoviedbDatasource extends MoviesDatasource {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      queryParameters: {
        'api_key': Environment.theMovieDbKey,
        'language': 'es-MX',
      },
    ),
  );

  @override
  Future<List<Movie>> getNowPlaying({int page = 1}) =>
      _getMovies('/movie/now_playing', page: page);

  @override
  Future<List<Movie>> getPopular({int page = 1}) =>
      _getMovies('/movie/popular', page: page);

  @override
  Future<List<Movie>> getUpcoming({int page = 1}) =>
      _getMovies('/movie/upcoming', page: page);

  @override
  Future<List<Movie>> getTopRated({int page = 1}) =>
      _getMovies('/movie/top_rated', page: page);

  @override
  Future<Movie> getMovieById(String movieId) async {
    final response = await dio.get('/movie/$movieId');
    final details = MovieDetails.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    return MovieMapper.movieDetailsToEntity(details);
  }

  @override
  Future<List<Movie>> searchMovies(String query) =>
      _getMovies('/search/movie', query: query);

  Future<List<Movie>> _getMovies(
    String endpoint, {
    int page = 1,
    String? query,
  }) async {
    final queryParameters = <String, dynamic>{'page': page};
    if (query != null) {
      queryParameters['query'] = query;
    }

    final response = await dio.get(endpoint, queryParameters: queryParameters);
    final movieDBResponse = MovieDbResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    return movieDBResponse.results
        .where((movie) => movie.posterPath != 'no-poster')
        .map(MovieMapper.movieDBToEntity)
        .toList();
  }
}
