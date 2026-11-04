import 'package:cinemapedia/domain/entities/actor.dart';
import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:cinemapedia/presentation/providers/actors/actors_by_movie_provider.dart';
import 'package:cinemapedia/presentation/providers/filters/movie_country_provider.dart';
import 'package:cinemapedia/presentation/providers/movies/movie_info_provider.dart';
import 'package:cinemapedia/presentation/widgets/shared/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MovieScreen extends ConsumerStatefulWidget {
  static const name = 'movie-screen';

  final String movieId;

  const MovieScreen({super.key, required this.movieId});

  @override
  ConsumerState<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends ConsumerState<MovieScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(movieInfoProvider.notifier).loadMovie(widget.movieId);
      ref.read(actorsByMovieProvider.notifier).loadActors(widget.movieId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final movie = ref.watch(movieInfoProvider)[widget.movieId];
    final actors = ref.watch(actorsByMovieProvider)[widget.movieId] ?? [];
    final selectedCountry = ref.watch(selectedMovieCountryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(movie?.title ?? 'Película')),
      body: movie == null
          ? const Center(child: CircularProgressIndicator())
          : _MovieDetails(
              movie: movie,
              actors: actors,
              selectedCountryCode: selectedCountry?.code,
            ),
    );
  }
}

class _MovieDetails extends StatelessWidget {
  final Movie movie;
  final List<Actor> actors;
  final String? selectedCountryCode;

  const _MovieDetails({
    required this.movie,
    required this.actors,
    required this.selectedCountryCode,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            movie.backdropPath,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 240,
              child: Center(child: Icon(Icons.movie_outlined, size: 64)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.title, style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                RatingStars(rating: movie.voteAverage),
                const SizedBox(height: 16),
                if (movie.productionCountries.isNotEmpty) ...[
                  Text('País y clasificación', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final country in movie.productionCountries)
                        Chip(
                          avatar: Text(MovieCountry.flagForCode(country.code)),
                          label: Text(
                            '${country.name}: '
                            '${movie.countryCertifications[country.code]?.isNotEmpty == true ? movie.countryCertifications[country.code] : 'Sin clasificación'}',
                          ),
                        ),
                    ],
                  ),
                  if (selectedCountryCode != null &&
                      !movie.productionCountries.any(
                        (country) => country.code == selectedCountryCode,
                      ))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No hay clasificación disponible para '
                        '${_countryName(selectedCountryCode!)}.',
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                Text(
                  movie.overview.isEmpty
                      ? 'Sinopsis no disponible.'
                      : movie.overview,
                ),
                if (actors.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Reparto', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: actors.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final actor = actors[index];
                        return SizedBox(
                          width: 90,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(45),
                                child: Image.network(
                                  actor.profilePath,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: Icon(Icons.person, size: 48),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                actor.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _countryName(String code) {
    for (final country in MovieCountry.supported) {
      if (country.code == code) return country.name;
    }
    return code;
  }
}
