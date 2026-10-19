import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('requires initialization before storage access', () async {
    final storage = SharedPreferencesStorageService();

    await expectLater(storage.getString('key'), throwsA(isA<StateError>()));
  });

  test('reads, writes and removes supported primitive values', () async {
    final storage = SharedPreferencesStorageService();
    await storage.initialize();

    await storage.setString('string', 'value');
    await storage.setBool('bool', true);
    await storage.setInt('int', 42);

    expect(await storage.getString('string'), 'value');
    expect(await storage.getBool('bool'), isTrue);
    expect(await storage.getInt('int'), 42);

    await storage.remove('string');
    expect(await storage.getString('string'), isNull);
  });
}
