import 'package:cinemapedia/domain/entities/movie_country.dart';
import 'package:cinemapedia/presentation/providers/filters/movie_country_provider.dart';
import 'package:cinemapedia/presentation/widgets/shared/country_filter_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selecting a flag updates the global movie country', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: CountryFilterSelector())),
      ),
    );

    await tester.tap(find.text('MÉX'));
    await tester.pump();

    expect(container.read(selectedMovieCountryProvider), MovieCountry.mexico);
    expect(find.text('🇺🇸'), findsOneWidget);
    expect(find.text('🇩🇪'), findsOneWidget);
    expect(find.text('🇯🇵'), findsOneWidget);
  });
}
