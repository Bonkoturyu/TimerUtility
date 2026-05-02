import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/preset_select_sheet.dart';

class _InMemoryPresetRepo implements PresetRepository {
  _InMemoryPresetRepo([Iterable<Preset>? seed]) {
    if (seed != null) {
      for (final Preset p in seed) {
        store[p.id] = p;
      }
    }
  }
  final Map<String, Preset> store = <String, Preset>{};

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
    store.clear();
    for (final Preset e in entities) {
      store[e.id] = e;
    }
  }
}

Widget _harness(
  Iterable<Preset>? seed, {
  void Function(PresetSelectResult?)? capture,
}) {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 1))),
      presetRepositoryProvider.overrideWithValue(_InMemoryPresetRepo(seed)),
    ],
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: ElevatedButton(
              key: const Key('open'),
              onPressed: () async {
                final r = await showModalBottomSheet<PresetSelectResult>(
                  context: context,
                  builder: (_) => const PresetSelectSheet(),
                );
                capture?.call(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _settleRestore(WidgetTester tester) async {
  // Microtask kicked off by PresetCollectionNotifier.build().
  await tester.pump();
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('renders preset chips and the custom button when presets exist', (
    tester,
  ) async {
    final Preset p = Preset(
      id: 'p-30s',
      label: '',
      duration: const Duration(seconds: 30),
      soundId: 'default',
      createdAt: DateTime(2026, 5, 1),
    );
    await tester.pumpWidget(_harness(<Preset>[p]));
    await _settleRestore(tester);
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();

    expect(find.text('プリセットから選択'), findsOneWidget);
    expect(find.byKey(const Key('preset_chip_p-30s')), findsOneWidget);
    expect(find.byKey(const Key('preset_sheet_custom_button')), findsOneWidget);
  });

  testWidgets('empty collection shows only the custom button', (tester) async {
    await tester.pumpWidget(_harness(null));
    await _settleRestore(tester);
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('preset_sheet_custom_button')), findsOneWidget);
    // No preset chips rendered.
    expect(find.byType(FilledButton), findsOneWidget); // only custom button
  });

  testWidgets('tapping a preset chip pops PresetSelectResult.preset', (
    tester,
  ) async {
    PresetSelectResult? captured;
    final Preset p = Preset(
      id: 'p-1m',
      label: '',
      duration: const Duration(minutes: 1),
      soundId: 'gentle',
      createdAt: DateTime(2026, 5, 1),
    );
    await tester.pumpWidget(
      _harness(<Preset>[p], capture: (r) => captured = r),
    );
    await _settleRestore(tester);
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preset_chip_p-1m')));
    await tester.pumpAndSettle();

    expect(captured?.preset?.id, 'p-1m');
    expect(captured?.customRequested, isFalse);
  });

  testWidgets(
    'tapping the custom button pops PresetSelectResult.customRequested',
    (tester) async {
      PresetSelectResult? captured;
      await tester.pumpWidget(_harness(null, capture: (r) => captured = r));
      await _settleRestore(tester);
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('preset_sheet_custom_button')));
      await tester.pumpAndSettle();

      expect(captured?.preset, isNull);
      expect(captured?.customRequested, isTrue);
    },
  );
}
