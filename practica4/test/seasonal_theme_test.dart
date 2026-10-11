import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/presentation/screens/splash/seasonal_theme.dart';
import 'package:practica4/presentation/screens/splash/splash_screen.dart';

void main() {
  group('SeasonalTheme.forDate', () {
    test('uses Halloween from October 20 through November 3', () {
      expect(SeasonalTheme.forDate(DateTime(2026, 10, 20)), SeasonalTheme.halloween);
      expect(SeasonalTheme.forDate(DateTime(2026, 10, 31)), SeasonalTheme.halloween);
      expect(SeasonalTheme.forDate(DateTime(2026, 11, 3)), SeasonalTheme.halloween);
    });

    test('uses Christmas throughout December', () {
      expect(SeasonalTheme.forDate(DateTime(2026, 12, 1)), SeasonalTheme.christmas);
      expect(SeasonalTheme.forDate(DateTime(2026, 12, 31)), SeasonalTheme.christmas);
    });

    test('uses Valentine theme from February 10 through 18', () {
      expect(SeasonalTheme.forDate(DateTime(2026, 2, 10)), SeasonalTheme.valentine);
      expect(SeasonalTheme.forDate(DateTime(2026, 2, 14)), SeasonalTheme.valentine);
      expect(SeasonalTheme.forDate(DateTime(2026, 2, 18)), SeasonalTheme.valentine);
    });

    test('uses normal theme outside seasonal ranges', () {
      expect(SeasonalTheme.forDate(DateTime(2026, 10, 19)), SeasonalTheme.normal);
      expect(SeasonalTheme.forDate(DateTime(2026, 11, 4)), SeasonalTheme.normal);
      expect(SeasonalTheme.forDate(DateTime(2026, 1, 1)), SeasonalTheme.normal);
      expect(SeasonalTheme.forDate(DateTime(2026, 2, 19)), SeasonalTheme.normal);
    });
  });

  testWidgets('shows the seasonal logo and replaces itself after the timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          destination: const Scaffold(body: Text('TokTik Home')),
          now: () => DateTime(2026, 10, 31),
          duration: const Duration(seconds: 2),
        ),
      ),
    );

    expect(find.text('Halloween'), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      'assets/images/logo_halloween.png',
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('TokTik Home'), findsOneWidget);
    expect(find.text('Halloween'), findsNothing);
  });
}
