import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_utility/infrastructure/preferences/shared_preferences_user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferencesUserPreferences> makeAdapter([
    Map<String, Object> initial = const <String, Object>{},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return SharedPreferencesUserPreferences.forTesting(prefs);
  }

  group('getBool', () {
    test('returns null for an absent key', () async {
      final adapter = await makeAdapter();
      expect(await adapter.getBool('skipPresetDeleteConfirm'), isNull);
    });

    test('returns true when the key is stored as true', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.skipPresetDeleteConfirm': true,
      });
      expect(await adapter.getBool('skipPresetDeleteConfirm'), isTrue);
    });

    test('returns false when the key is stored as false', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.skipPresetDeleteConfirm': false,
      });
      expect(await adapter.getBool('skipPresetDeleteConfirm'), isFalse);
    });
  });

  group('setBool', () {
    test('persists a value that getBool reads back', () async {
      final adapter = await makeAdapter();
      await adapter.setBool('skipPresetDeleteConfirm', true);
      expect(await adapter.getBool('skipPresetDeleteConfirm'), isTrue);
    });

    test('overwrites an existing value', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.skipPresetDeleteConfirm': true,
      });
      await adapter.setBool('skipPresetDeleteConfirm', false);
      expect(await adapter.getBool('skipPresetDeleteConfirm'), isFalse);
    });
  });

  group('remove', () {
    test('removes the key so subsequent getBool returns null', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.skipPresetDeleteConfirm': true,
      });
      await adapter.remove('skipPresetDeleteConfirm');
      expect(await adapter.getBool('skipPresetDeleteConfirm'), isNull);
    });

    test('is a no-op for an absent key', () async {
      final adapter = await makeAdapter();
      await adapter.remove('nope');
      expect(await adapter.getBool('nope'), isNull);
    });
  });
}
