import 'package:shared_preferences/shared_preferences.dart';
import 'package:practica4/domain/services/local_storage_service.dart';

class SharedPreferencesStorageService implements LocalStorageService {
  SharedPreferences? _preferences;

  @override
  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _initializedPreferences {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError(
        'SharedPreferencesStorageService must be initialized before use.',
      );
    }
    return preferences;
  }

  @override
  Future<String?> getString(String key) async {
    return _initializedPreferences.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    if (!await _initializedPreferences.setString(key, value)) {
      throw StateError('Failed to persist string value for key "$key".');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    return _initializedPreferences.getBool(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    if (!await _initializedPreferences.setBool(key, value)) {
      throw StateError('Failed to persist boolean value for key "$key".');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    return _initializedPreferences.getInt(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    if (!await _initializedPreferences.setInt(key, value)) {
      throw StateError('Failed to persist integer value for key "$key".');
    }
  }

  @override
  Future<void> remove(String key) async {
    if (!await _initializedPreferences.remove(key)) {
      throw StateError('Failed to remove value for key "$key".');
    }
  }
}
