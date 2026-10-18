import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';
import 'package:practica4/presentation/providers/seasonal_theme_provider.dart';
import 'package:practica4/presentation/screens/splash/seasonal_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = SharedPreferencesStorageService();
    await storage.initialize();
  });

  test(
    'uses the date-derived theme when no manual selection is saved',
    () async {
      final provider = SeasonalThemeProvider(
        storage,
        clock: () => DateTime(2026, 10, 31),
      );
      await provider.initialize();

      expect(provider.currentTheme, SeasonalTheme.halloween);
      expect(provider.selectedOverride, isNull);
    },
  );

  test('persists a manual theme and restores it on the next launch', () async {
    final provider = SeasonalThemeProvider(
      storage,
      clock: () => DateTime(2026, 10, 31),
    );
    await provider.initialize();
    await provider.selectTheme(SeasonalTheme.christmas);

    final restoredProvider = SeasonalThemeProvider(
      storage,
      clock: () => DateTime(2026, 10, 31),
    );
    await restoredProvider.initialize();

    expect(restoredProvider.currentTheme, SeasonalTheme.christmas);
    expect(
      await storage.getString('seasonal_theme_override'),
      SeasonalTheme.christmas.launcherIconTheme,
    );
  });

  test('clears the manual theme when automatic mode is selected', () async {
    final provider = SeasonalThemeProvider(
      storage,
      clock: () => DateTime(2026, 2, 14),
    );
    await provider.initialize();
    await provider.selectTheme(SeasonalTheme.normal);
    await provider.selectTheme(null);

    expect(provider.currentTheme, SeasonalTheme.valentine);
    expect(provider.selectedOverride, isNull);
    expect(await storage.getString('seasonal_theme_override'), isNull);
  });
}
