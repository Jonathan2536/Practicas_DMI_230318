import 'dart:async';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadInitialMovies());
    });
  }

  Future<void> _loadInitialMovies() async {
    final requests = <Future<void>>[];

    if (ref.read(nowPlayingMoviesProvider).movies.isEmpty) {
      requests.add(ref.read(nowPlayingMoviesProvider.notifier).loadNextPage());
    }
    if (ref.read(popularMoviesProvider).movies.isEmpty) {
      requests.add(ref.read(popularMoviesProvider.notifier).loadNextPage());
    }
    if (ref.read(topRatedMoviesProvider).movies.isEmpty) {
      requests.add(ref.read(topRatedMoviesProvider.notifier).loadNextPage());
    }
    if (ref.read(upcomingMoviesProvider).movies.isEmpty) {
      requests.add(ref.read(upcomingMoviesProvider.notifier).loadNextPage());
    }

    await Future.wait(requests);
  }

  @override
  Widget build(BuildContext context) {
    final initialMoviesError = ref.watch(initialMoviesErrorProvider);
    final initialLoading = ref.watch(initialLoadingProvider);
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
                onPressed: _loadInitialMovies,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final slideShowMovies = ref.watch(moviesSlideshowProvider);
    final nowPlayingMovies = ref.watch(nowPlayingMoviesProvider).movies;
    final popularMovies = ref.watch(popularMoviesProvider).movies;
    final topRatedMovies = ref.watch(topRatedMoviesProvider).movies;
    final upcomingMovies = ref.watch(upcomingMoviesProvider).movies;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          flexibleSpace: FlexibleSpaceBar(title: CustomAppbar()),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Column(
              children: [
                // const CustomAppbar(),

                MoviesSlideshow(movies: slideShowMovies),

                MovieHorizontalListview(
                  movies: nowPlayingMovies,
                  title: 'En cines',
                  subTitle: 'Lunes 20',
                  loadNextPage: () => ref
                      .read(nowPlayingMoviesProvider.notifier)
                      .loadNextPage(),
                ),

                MovieHorizontalListview(
                  movies: upcomingMovies,
                  title: 'Próximamente',
                  subTitle: 'En este mes',
                  loadNextPage: () =>
                      ref.read(upcomingMoviesProvider.notifier).loadNextPage(),
                ),

                MovieHorizontalListview(
                  movies: popularMovies,
                  title: 'Populares',
                  // subTitle: '',
                  loadNextPage: () =>
                      ref.read(popularMoviesProvider.notifier).loadNextPage(),
                ),

                MovieHorizontalListview(
                  movies: topRatedMovies,
                  title: 'Mejor calificadas',
                  subTitle: 'Desde siempre',
                  loadNextPage: () =>
                      ref.read(topRatedMoviesProvider.notifier).loadNextPage(),
                ),

                const SizedBox(height: 10),
              ],
            );
          }, childCount: 1),
        ),
      ],
    );
  }
}
