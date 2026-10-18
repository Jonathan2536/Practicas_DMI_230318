import 'package:flutter/foundation.dart';
import 'package:practica4/domain/services/local_storage_service.dart';
import 'package:practica4/presentation/screens/splash/seasonal_theme.dart';

class SeasonalThemeProvider extends ChangeNotifier {
  SeasonalThemeProvider(
    this._storage, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _storageKey = 'seasonal_theme_override';

  final LocalStorageService _storage;
  final DateTime Function() _clock;
  SeasonalTheme? _override;

  SeasonalTheme get currentTheme =>
      _override ?? SeasonalTheme.forDate(_clock());

  SeasonalTheme? get selectedOverride => _override;

  Future<void> initialize() async {
    final savedId = await _storage.getString(_storageKey);
    if (savedId == null) return;

    final savedTheme = SeasonalTheme.fromId(savedId);
    if (savedTheme == null) {
      throw FormatException('Unknown saved seasonal theme "$savedId".');
    }
    _override = savedTheme;
  }

  Future<void> selectTheme(SeasonalTheme? theme) async {
    if (_override == theme) return;

    if (theme == null) {
      await _storage.remove(_storageKey);
    } else {
      await _storage.setString(_storageKey, theme.launcherIconTheme);
    }

    _override = theme;
    notifyListeners();
  }
}
