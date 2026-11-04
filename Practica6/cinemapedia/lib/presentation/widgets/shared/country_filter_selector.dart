import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:cinemapedia/presentation/providers/filters/movie_country_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountryFilterSelector extends ConsumerWidget {
  const CountryFilterSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCountry = ref.watch(selectedMovieCountryProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          avatar: const Text('🌍'),
          label: const Text('Todos'),
          selected: selectedCountry == null,
          onSelected: (_) {
            ref.read(selectedMovieCountryProvider.notifier).state = null;
          },
        ),
        for (final country in MovieCountry.supported)
          FilterChip(
            avatar: Text(country.flag),
            label: Text(country.shortName),
            tooltip: country.name,
            selected: selectedCountry == country,
            onSelected: (_) {
              ref.read(selectedMovieCountryProvider.notifier).state = country;
            },
          ),
      ],
    );
  }
}
