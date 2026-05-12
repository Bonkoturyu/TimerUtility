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

  group('getInt', () {
    test('returns null for an absent key', () async {
      final adapter = await makeAdapter();
      expect(await adapter.getInt('lastHomePageIndex'), isNull);
    });

    test('returns the stored int verbatim (including 0)', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.lastHomePageIndex': 0,
      });
      // 0 is the Stopwatch tab in Phase 11; we assert on it explicitly
      // because a naive implementation that uses falsy checks (`?? null`
      // logic on the bare `getInt` result) would lose the distinction
      // between "explicitly 0" and "absent".
      expect(await adapter.getInt('lastHomePageIndex'), 0);
    });

    test('returns positive values verbatim', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.lastHomePageIndex': 3,
      });
      expect(await adapter.getInt('lastHomePageIndex'), 3);
    });
  });

  group('setInt', () {
    test('persists a value that getInt reads back', () async {
      final adapter = await makeAdapter();
      await adapter.setInt('lastHomePageIndex', 2);
      expect(await adapter.getInt('lastHomePageIndex'), 2);
    });

    test('overwrites an existing value', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.lastHomePageIndex': 1,
      });
      await adapter.setInt('lastHomePageIndex', 3);
      expect(await adapter.getInt('lastHomePageIndex'), 3);
    });
  });

  group('getString', () {
    test('returns null for an absent key', () async {
      final adapter = await makeAdapter();
      expect(await adapter.getString('defaultAlarmSoundId'), isNull);
    });

    test('returns the stored string verbatim (including empty)', () async {
      // 空文字列を「未設定」と混同しないことを明示するためのテスト。
      final adapter = await makeAdapter(<String, Object>{
        'flutter.defaultAlarmSoundId': '',
      });
      expect(await adapter.getString('defaultAlarmSoundId'), '');
    });

    test('returns positive values verbatim', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.defaultAlarmSoundId': 'gentle',
      });
      expect(await adapter.getString('defaultAlarmSoundId'), 'gentle');
    });
  });

  group('setString', () {
    test('persists a value that getString reads back', () async {
      final adapter = await makeAdapter();
      await adapter.setString('defaultAlarmSoundId', 'gentle');
      expect(await adapter.getString('defaultAlarmSoundId'), 'gentle');
    });

    test('overwrites an existing value', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.defaultAlarmSoundId': 'default',
      });
      await adapter.setString('defaultAlarmSoundId', 'warning');
      expect(await adapter.getString('defaultAlarmSoundId'), 'warning');
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

    test('removes an int key so subsequent getInt returns null', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.lastHomePageIndex': 2,
      });
      await adapter.remove('lastHomePageIndex');
      expect(await adapter.getInt('lastHomePageIndex'), isNull);
    });

    test('removes a string key so subsequent getString returns null', () async {
      final adapter = await makeAdapter(<String, Object>{
        'flutter.defaultAlarmSoundId': 'gentle',
      });
      await adapter.remove('defaultAlarmSoundId');
      expect(await adapter.getString('defaultAlarmSoundId'), isNull);
    });

    test('is a no-op for an absent key', () async {
      final adapter = await makeAdapter();
      await adapter.remove('nope');
      expect(await adapter.getBool('nope'), isNull);
    });
  });
}
