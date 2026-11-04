import 'package:dio/dio.dart';

import 'package:cinemapedia/config/constants/environment.dart';
import 'package:cinemapedia/domain/datasources/movies_datasource.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';

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
  Future<List<Movie>> getNowPlaying({int page = 1, MovieCountry? country}) =>
      _getMovies(
        '/movie/now_playing',
        page: page,
        country: country,
        countrySortBy: 'primary_release_date.desc',
        releaseWindowDays: 45,
        releaseType: '2|3',
      );

  @override
  Future<List<Movie>> getPopular({int page = 1, MovieCountry? country}) =>
      _getMovies(
        '/movie/popular',
        page: page,
        country: country,
        countrySortBy: 'popularity.desc',
      );

  @override
  Future<List<Movie>> getUpcoming({int page = 1, MovieCountry? country}) =>
      _getMovies(
        '/movie/upcoming',
        page: page,
        country: country,
        countrySortBy: 'primary_release_date.asc',
        releaseWindowDays: 365,
        upcoming: true,
        releaseType: '2|3',
      );

  @override
  Future<List<Movie>> getTopRated({int page = 1, MovieCountry? country}) =>
      _getMovies(
        '/movie/top_rated',
        page: page,
        country: country,
        countrySortBy: 'vote_average.desc',
        minimumVoteCount: 200,
      );

  @override
  Future<Movie> getMovieById(String movieId) async {
    final response = await dio.get(
      '/movie/$movieId',
      queryParameters: const {'append_to_response': 'release_dates'},
    );
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final details = MovieDetails.fromJson(responseData);
    return MovieMapper.movieDetailsToEntity(
      details,
      countryCertifications: _parseCountryCertifications(
        responseData['release_dates'],
      ),
    );
  }

  @override
  Future<List<Movie>> searchMovies(String query, {MovieCountry? country}) =>
      _getMovies('/search/movie', query: query, country: country);

  Future<List<Movie>> _getMovies(
    String endpoint, {
    int page = 1,
    String? query,
    MovieCountry? country,
    String? countrySortBy,
    int? releaseWindowDays,
    bool upcoming = false,
    String? releaseType,
    int? minimumVoteCount,
  }) async {
    final useCountryDiscover = country != null && query == null;
    final resolvedEndpoint = useCountryDiscover ? '/discover/movie' : endpoint;
    final queryParameters = <String, dynamic>{
      'page': page,
      if (country != null) 'region': country.code,
    };
    if (query != null) {
      queryParameters['query'] = query;
    }
    if (useCountryDiscover) {
      final today = DateTime.now();
      queryParameters.addAll({
        'with_origin_country': country.code,
        'sort_by': countrySortBy,
      });
      if (releaseType != null) {
        queryParameters['with_release_type'] = releaseType;
      }
      if (minimumVoteCount != null) {
        queryParameters['vote_count.gte'] = minimumVoteCount;
      }
      if (releaseWindowDays != null) {
        queryParameters['primary_release_date.gte'] = _formatDate(
          upcoming
              ? today.add(const Duration(days: 1))
              : today.subtract(Duration(days: releaseWindowDays)),
        );
        queryParameters['primary_release_date.lte'] = _formatDate(
          upcoming ? today.add(Duration(days: releaseWindowDays)) : today,
        );
      }
    }

    final response = await dio.get(
      resolvedEndpoint,
      queryParameters: queryParameters,
    );
    final movieDBResponse = MovieDbResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    return movieDBResponse.results
        .where((movie) => movie.posterPath != 'no-poster')
        .map(MovieMapper.movieDBToEntity)
        .toList();
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Map<String, String> _parseCountryCertifications(dynamic data) {
    if (data is! Map) return const {};
    final results = data['results'];
    if (results is! List) return const {};

    final certifications = <String, String>{};
    for (final result in results) {
      if (result is! Map) continue;
      final country = Map<String, dynamic>.from(result);
      final code = country['iso_3166_1'];
      final releaseDates = country['release_dates'];
      if (code is! String || releaseDates is! List) continue;

      for (final releaseDate in releaseDates) {
        if (releaseDate is! Map) continue;
        final certification = releaseDate['certification'];
        if (certification is String && certification.trim().isNotEmpty) {
          certifications[code] = certification.trim();
          break;
        }
      }
    }

    return certifications;
  }
}
