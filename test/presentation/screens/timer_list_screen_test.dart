import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/application/timer_collection_notifier.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/timer_collection.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/timer_list_screen.dart';

import '../../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _InMemoryRepo implements TimerRepository {
  _InMemoryRepo([Iterable<TimerEntity>? seed]) {
    if (seed != null) {
      for (final TimerEntity t in seed) {
        store[t.id] = t;
      }
    }
  }
  final Map<String, TimerEntity> store = <String, TimerEntity>{};

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<TimerEntity>> findAll() async => store.values.toList();

  @override
  Future<TimerEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(TimerEntity entity) async => store[entity.id] = entity;
}

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

NotificationScheduler _stubScheduler() {
  final s = _MockScheduler();
  when(
    () => s.schedule(
      notificationId: any(named: 'notificationId'),
      fireAt: any(named: 'fireAt'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      exact: any(named: 'exact'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => s.show(
      notificationId: any(named: 'notificationId'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(() => s.cancel(any())).thenAnswer((_) async {});
  when(() => s.cancelAll()).thenAnswer((_) async {});
  return s;
}

class _GrantedPermissionNotifier extends PermissionNotifier {
  @override
  PermissionState build() => const PermissionState(
    postNotifications: DomainPermissionStatus.granted,
    scheduleExactAlarm: DomainPermissionStatus.granted,
    fullScreenIntent: DomainPermissionStatus.granted,
  );
}

Widget _harness(_InMemoryRepo repo, {Iterable<Preset>? presetSeed}) {
  final router = GoRouter(
    initialLocation: '/timer',
    routes: <RouteBase>[
      GoRoute(path: '/timer', builder: (_, _) => const TimerListScreen()),
      GoRoute(
        path: '/alarm-ringing',
        builder: (_, _) => const Scaffold(body: Text('alarm-stub')),
      ),
      GoRoute(
        path: '/presets',
        builder: (_, _) => const Scaffold(body: Text('presets-stub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 1, 12))),
      timerRepositoryProvider.overrideWithValue(repo),
      presetRepositoryProvider.overrideWithValue(
        _InMemoryPresetRepo(presetSeed),
      ),
      notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
      testNotificationStringsOverride(),
      permissionNotifierProvider.overrideWith(
        () => _GrantedPermissionNotifier(),
      ),
    ],
    // Force Japanese so the existing "上限 N 件に達しています" SnackBar
    // assertion stays stable (the SnackBar's text is now resolved via
    // AppLocalizations).
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  testWidgets('shows empty hint when no timers exist', (tester) async {
    await tester.pumpWidget(_harness(_InMemoryRepo()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timer_list_empty_hint')), findsOneWidget);
    expect(find.byKey(const Key('timer_list_add_fab')), findsOneWidget);
  });

  testWidgets(
    'add FAB → preset sheet → custom button → DurationPicker confirm creates a timer',
    (tester) async {
      await tester.pumpWidget(_harness(_InMemoryRepo()));
      await tester.pumpAndSettle();

      // Phase 9: FAB now opens the preset sheet first. With no presets
      // seeded the only action is the "custom time" button.
      await tester.tap(find.byKey(const Key('timer_list_add_fab')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('preset_sheet_custom_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('preset_sheet_custom_button')));
      await tester.pumpAndSettle();

      // DurationPicker is now open. Default initial = 1 minute, so
      // confirm is enabled and a timer card is added on tap.
      await tester.tap(find.byKey(const Key('duration_picker_confirm')));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(TimerListScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(timerCollectionNotifierProvider).size, 1);
    },
  );

  testWidgets(
    'add FAB → preset sheet → tapping a preset chip creates a timer',
    (tester) async {
      final Preset preset = Preset(
        id: 'preset-30s',
        label: '',
        duration: const Duration(seconds: 30),
        soundId: 'default',
        createdAt: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(
        _harness(_InMemoryRepo(), presetSeed: <Preset>[preset]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_list_add_fab')));
      await tester.pumpAndSettle();
      // Preset chip is rendered.
      expect(find.byKey(const Key('preset_chip_preset-30s')), findsOneWidget);

      await tester.tap(find.byKey(const Key('preset_chip_preset-30s')));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(TimerListScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(timerCollectionNotifierProvider).size, 1);
      // Created timer carries the preset's soundId.
      final t = container.read(timerCollectionNotifierProvider).all.first;
      expect(t.soundId, 'default');
      expect(t.duration, const Duration(seconds: 30));
    },
  );

  testWidgets('AppBar overflow menu navigates to /presets', (tester) async {
    await tester.pumpWidget(_harness(_InMemoryRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('timer_list_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timer_list_menu_manage_presets')));
    await tester.pumpAndSettle();

    expect(find.text('presets-stub'), findsOneWidget);
  });

  testWidgets('Start button on a card transitions to running', (tester) async {
    final TimerEntity idle = TimerEntity(
      id: 't-1',
      notificationId: 1,
      label: 'Tea',
      duration: const Duration(seconds: 30),
      endAt: null,
      pausedRemaining: null,
      status: TimerStatus.idle,
      createdAt: DateTime(2026, 5, 1),
    );
    final repo = _InMemoryRepo(<TimerEntity>[idle]);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('timer_card_t-1_start')));
    await tester.pump();

    final BuildContext context = tester.element(find.byType(TimerListScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(timerCollectionNotifierProvider).findById('t-1')!.status,
      TimerStatus.running,
    );
    // Stop the ticker so the test ends cleanly.
    container.read(timerCollectionNotifierProvider.notifier).cancel('t-1');
  });

  testWidgets('Delete button removes the card', (tester) async {
    final TimerEntity idle = TimerEntity(
      id: 't-1',
      notificationId: 1,
      label: '',
      duration: const Duration(seconds: 30),
      endAt: null,
      pausedRemaining: null,
      status: TimerStatus.idle,
      createdAt: DateTime(2026, 5, 1),
    );
    final repo = _InMemoryRepo(<TimerEntity>[idle]);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timer_card_t-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('timer_card_t-1_delete')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timer_card_t-1')), findsNothing);
    expect(find.byKey(const Key('timer_list_empty_hint')), findsOneWidget);
  });

  testWidgets(
    'FAB tap at max capacity surfaces a SnackBar instead of opening picker',
    (tester) async {
      final List<TimerEntity> seed = <TimerEntity>[
        for (int i = 0; i < TimerCollection.maxSize; i++)
          TimerEntity(
            id: 't-$i',
            notificationId: 100 + i,
            label: '',
            duration: const Duration(seconds: 5),
            endAt: null,
            pausedRemaining: null,
            status: TimerStatus.idle,
            createdAt: DateTime(2026, 5, 1),
          ),
      ];
      final repo = _InMemoryRepo(seed);
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();

      // FAB stays tappable on purpose (a disabled FAB's state is too
      // subtle to read as "limit reached"); tap should produce a
      // SnackBar and not open the duration picker.
      await tester.tap(find.byKey(const Key('timer_list_add_fab')));
      await tester.pump();

      expect(
        find.text('上限 ${TimerCollection.maxSize} 件に達しています'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('duration_picker_confirm')), findsNothing);
    },
  );
}
