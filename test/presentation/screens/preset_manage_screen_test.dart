import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/preset_collection_notifier.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/preset_manage_screen.dart';

class _InMemoryPresetRepo implements PresetRepository {
  _InMemoryPresetRepo([Iterable<Preset>? seed]) {
    if (seed != null) {
      for (final Preset p in seed) {
        store[p.id] = p;
      }
    }
  }
  final Map<String, Preset> store = <String, Preset>{};
  int replaceAllCalls = 0;

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<Preset>> findAll() async => store.values.toList();

  @override
  Future<Preset?> findById(String id) async => store[id];

  @override
  Future<void> upsert(Preset entity) async => store[entity.id] = entity;

  @override
  Future<void> replaceAll(List<Preset> entities) async {
    replaceAllCalls++;
    store.clear();
    for (final Preset e in entities) {
      store[e.id] = e;
    }
  }
}

class _MemoryUserPrefs implements UserPreferences {
  final Map<String, bool> _bools = <String, bool>{};

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async {
    _bools[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _bools.remove(key);
  }
}

Widget _harness({Iterable<Preset>? presets, _MemoryUserPrefs? userPrefs}) {
  final repo = _InMemoryPresetRepo(presets);
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 2, 12))),
      presetRepositoryProvider.overrideWithValue(repo),
      userPreferencesProvider.overrideWithValue(
        userPrefs ?? _MemoryUserPrefs(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
      home: const PresetManageScreen(),
    ),
  );
}

Future<void> _settleRestore(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state shows the placeholder hint', (tester) async {
    await tester.pumpWidget(_harness());
    await _settleRestore(tester);
    expect(find.byKey(const Key('preset_manage_empty_hint')), findsOneWidget);
  });

  testWidgets('renders one card per preset with sound chip', (tester) async {
    final Preset p = Preset(
      id: 'p-1',
      label: 'コーヒー',
      duration: const Duration(minutes: 4),
      soundId: 'gentle',
      createdAt: DateTime(2026, 5, 1),
    );
    await tester.pumpWidget(_harness(presets: <Preset>[p]));
    await _settleRestore(tester);

    expect(find.byKey(const Key('preset_card_p-1')), findsOneWidget);
    expect(find.text('コーヒー'), findsOneWidget);
    expect(find.text('やさしい'), findsOneWidget);
  });

  testWidgets('delete with skip-confirm preference removes the card directly', (
    tester,
  ) async {
    final Preset p = Preset(
      id: 'p-1',
      label: '',
      duration: const Duration(minutes: 1),
      soundId: 'default',
      createdAt: DateTime(2026, 5, 1),
    );
    final prefs = _MemoryUserPrefs();
    await prefs.setBool(UserPreferenceKeys.skipPresetDeleteConfirm, true);
    await tester.pumpWidget(_harness(presets: <Preset>[p], userPrefs: prefs));
    await _settleRestore(tester);

    await tester.tap(find.byKey(const Key('preset_card_p-1_delete')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('preset_card_p-1')), findsNothing);
    expect(find.byKey(const Key('preset_manage_empty_hint')), findsOneWidget);
  });

  testWidgets(
    'delete without skip pref shows confirm dialog and deletes on confirm',
    (tester) async {
      final Preset p = Preset(
        id: 'p-1',
        label: '',
        duration: const Duration(minutes: 1),
        soundId: 'default',
        createdAt: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(_harness(presets: <Preset>[p]));
      await _settleRestore(tester);

      await tester.tap(find.byKey(const Key('preset_card_p-1_delete')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preset_delete_confirm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('preset_delete_confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preset_card_p-1')), findsNothing);
    },
  );

  testWidgets(
    'overflow → Replace from template → general profile (empty path)',
    (tester) async {
      // Empty collection: the screen should skip the 3-way mode dialog
      // and proceed straight to append.
      await tester.pumpWidget(_harness());
      await _settleRestore(tester);

      await tester.tap(find.byKey(const Key('preset_manage_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('preset_manage_menu_replace')));
      await tester.pumpAndSettle();

      // Profile picker is shown.
      expect(
        find.byKey(const Key('preset_template_profile_general')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('preset_template_profile_general')),
      );
      await tester.pumpAndSettle();

      // Now the collection has 6 cards (general profile size).
      final BuildContext context = tester.element(
        find.byType(PresetManageScreen),
      );
      final container = ProviderScope.containerOf(context);
      expect(container.read(presetCollectionNotifierProvider).size, 6);
    },
  );
}
