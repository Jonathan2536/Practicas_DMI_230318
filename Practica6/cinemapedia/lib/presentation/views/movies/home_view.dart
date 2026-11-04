import 'dart:async';

import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cinemapedia/presentation/providers/providers.dart';
import 'package:cinemapedia/presentation/widgets/widgets.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends ConsumerState<HomeView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollToTopVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadInitialMovies());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollToTopVisibility)
      ..dispose();
    super.dispose();
  }

  void _updateScrollToTopVisibility() {
    final shouldShow = _scrollController.offset > 350;
    if (shouldShow != _showScrollToTop && mounted) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _loadInitialMovies({MovieCountry? country}) async {
    final requests = <Future<void>>[];

    if (ref.read(nowPlayingMoviesProvider(country)).movies.isEmpty) {
      requests.add(
        ref.read(nowPlayingMoviesProvider(country).notifier).loadNextPage(),
      );
    }
    if (ref.read(popularMoviesProvider(country)).movies.isEmpty) {
      requests.add(
        ref.read(popularMoviesProvider(country).notifier).loadNextPage(),
      );
    }
    if (ref.read(topRatedMoviesProvider(country)).movies.isEmpty) {
      requests.add(
        ref.read(topRatedMoviesProvider(country).notifier).loadNextPage(),
      );
    }
    if (ref.read(upcomingMoviesProvider(country)).movies.isEmpty) {
      requests.add(
        ref.read(upcomingMoviesProvider(country).notifier).loadNextPage(),
      );
    }

    await Future.wait(requests);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(selectedMovieCountryProvider);
    ref.listen(selectedMovieCountryProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadInitialMovies(country: next));
      });
    });

    final initialMoviesError = ref.watch(
      initialMoviesErrorProvider(selectedCountry),
    );
    final initialLoading = ref.watch(initialLoadingProvider(selectedCountry));
    if (initialLoading) return const FullScreenLoader();
    if (initialMoviesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No se pudieron cargar las películas. Verifica tu conexión y que THE_MOVIEDB_KEY sea una API key v3 válida de TMDB.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadInitialMovies(country: selectedCountry),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final slideShowMovies = ref.watch(moviesSlideshowProvider(selectedCountry));
    final nowPlayingMovies = ref
        .watch(nowPlayingMoviesProvider(selectedCountry))
        .movies;
    final popularMovies = ref
        .watch(popularMoviesProvider(selectedCountry))
        .movies;
    final topRatedMovies = ref
        .watch(topRatedMoviesProvider(selectedCountry))
        .movies;
    final upcomingMovies = ref
        .watch(upcomingMoviesProvider(selectedCountry))
        .movies;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverAppBar(
              floating: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(title: CustomAppbar()),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Column(
                  children: [
                    MoviesSlideshow(movies: slideShowMovies),
                    MovieHorizontalListview(
                      movies: nowPlayingMovies,
                      title: 'En cines',
                      subTitle: 'Lunes 20',
                      loadNextPage: () => ref
                          .read(
                            nowPlayingMoviesProvider(selectedCountry).notifier,
                          )
                          .loadNextPage(),
                    ),
                    MovieHorizontalListview(
                      movies: upcomingMovies,
                      title: 'Próximamente',
                      subTitle: 'En este mes',
                      loadNextPage: () => ref
                          .read(
                            upcomingMoviesProvider(selectedCountry).notifier,
                          )
                          .loadNextPage(),
                    ),
                    MovieHorizontalListview(
                      movies: popularMovies,
                      title: 'Populares',
                      loadNextPage: () => ref
                          .read(popularMoviesProvider(selectedCountry).notifier)
                          .loadNextPage(),
                    ),
                    MovieHorizontalListview(
                      movies: topRatedMovies,
                      title: 'Mejor calificadas',
                      subTitle: 'Desde siempre',
                      loadNextPage: () => ref
                          .read(
                            topRatedMoviesProvider(selectedCountry).notifier,
                          )
                          .loadNextPage(),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }, childCount: 1),
            ),
          ],
        ),
        if (_showScrollToTop)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              tooltip: 'Volver al principio',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }
}
