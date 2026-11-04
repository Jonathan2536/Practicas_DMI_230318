import 'dart:async';

import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/presentation/providers/movies/movies_repository_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nowPlayingMoviesProvider =
    StateNotifierProvider<MoviesNotifier, MoviesState>((ref) {
      final fetchMoreMovies = ref.watch(movieRepositoryProvider).getNowPlaying;
      return MoviesNotifier(fetchMoreMovies: fetchMoreMovies);
    });

final popularMoviesProvider =
    StateNotifierProvider<MoviesNotifier, MoviesState>((ref) {
      final fetchMoreMovies = ref.watch(movieRepositoryProvider).getPopular;
      return MoviesNotifier(fetchMoreMovies: fetchMoreMovies);
    });

final upcomingMoviesProvider =
    StateNotifierProvider<MoviesNotifier, MoviesState>((ref) {
      final fetchMoreMovies = ref.watch(movieRepositoryProvider).getUpcoming;
      return MoviesNotifier(fetchMoreMovies: fetchMoreMovies);
    });

final topRatedMoviesProvider =
    StateNotifierProvider<MoviesNotifier, MoviesState>((ref) {
      final fetchMoreMovies = ref.watch(movieRepositoryProvider).getTopRated;
      return MoviesNotifier(fetchMoreMovies: fetchMoreMovies);
    });

typedef MovieCallback = Future<List<Movie>> Function({int page});

class MoviesState {
  final List<Movie> movies;
  final bool isLoading;
  final Object? error;

  const MoviesState({
    this.movies = const [],
    this.isLoading = false,
    this.error,
  });
}

class MoviesNotifier extends StateNotifier<MoviesState> {
  int currentPage = 0;
  MovieCallback fetchMoreMovies;
  final Duration requestTimeout;

  MoviesNotifier({
    required this.fetchMoreMovies,
    this.requestTimeout = const Duration(seconds: 20),
  }) : super(const MoviesState());

  Future<void> loadNextPage() async {
    if (state.isLoading) return;

    state = MoviesState(movies: state.movies, isLoading: true);
    final nextPage = currentPage + 1;

    try {
      final movies = await fetchMoreMovies(page: nextPage)
          .timeout(requestTimeout);
      currentPage = nextPage;
      state = MoviesState(movies: [...state.movies, ...movies]);
    } catch (error, stackTrace) {
      debugPrint('Failed to load movie page $nextPage (${error.runtimeType}).');
      debugPrintStack(stackTrace: stackTrace);
      state = MoviesState(movies: state.movies, error: error);
    }
  }
}
