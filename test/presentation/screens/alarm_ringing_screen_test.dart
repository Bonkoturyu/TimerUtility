import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_push_reservation.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/keyguard_override_controller_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/screen_lock_query_provider.dart';
import 'package:timer_utility/application/timer_collection_notifier.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/keyguard_override_controller.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/screen_lock_query.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/alarm_ringing_screen.dart';

import '../../helpers/test_notification_strings.dart';

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  int playCalls = 0;
  int prepareCalls = 0;
  int stopCalls = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> prepare(AlarmSound sound) async {
    prepareCalls++;
  }

  @override
  Future<void> play(AlarmSound sound) async {
    playCalls++;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {}
}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

/// Issue #74 fix: AlarmRingingNotifier consults ScreenLockQuery to pick
/// the cancel→play delay (500 ms unlocked / 1800 ms locked).
class _StubScreenLockQuery implements ScreenLockQuery {
  _StubScreenLockQuery({this.locked = false});

  final bool locked;

  @override
  Future<bool> isScreenLocked() async => locked;
}

/// Issue #73: AlarmRingingScreen releases the keyguard-override via this
/// controller on leave. Records the call so tests can assert it fired
/// without touching a real MethodChannel.
class _StubKeyguardOverrideController implements KeyguardOverrideController {
  int clearCalls = 0;

  @override
  Future<void> clearShowWhenLocked() async {
    clearCalls++;
  }
}

/// In-memory [TimerRepository] used by every harness so the
/// [TimerCollectionNotifier] under test never touches a real DB.
class _InMemoryTimerRepository implements TimerRepository {
  final Map<String, TimerEntity> _store = <String, TimerEntity>{};

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<TimerEntity>> findAll() async => _store.values.toList();

  @override
  Future<TimerEntity?> findById(String id) async => _store[id];

  @override
  Future<void> upsert(TimerEntity entity) async {
    _store[entity.id] = entity;
  }
}

class _DelayedColdTimerRepository implements TimerRepository {
  _DelayedColdTimerRepository(this.entity, this.lookupDelay);

  final TimerEntity entity;
  final Duration lookupDelay;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<TimerEntity>> findAll() async => <TimerEntity>[];

  @override
  Future<TimerEntity?> findById(String id) async {
    await Future<void>.delayed(lookupDelay);
    return id == entity.id ? entity : null;
  }

  @override
  Future<void> upsert(TimerEntity entity) async {}
}

NotificationScheduler _stubScheduler() {
  final scheduler = _MockNotificationScheduler();
  when(
    () => scheduler.schedule(
      notificationId: any(named: 'notificationId'),
      fireAt: any(named: 'fireAt'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      exact: any(named: 'exact'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => scheduler.show(
      notificationId: any(named: 'notificationId'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  when(() => scheduler.cancelAll()).thenAnswer((_) async {});
  return scheduler;
}

Widget _harness(
  _StubAlarmSoundPlayer player, {
  DateTime? now,
  TimerEntity? seedRinging,
  bool screenLocked = false,
  Duration handoffDelay = Duration.zero,
  Duration selectionTimeout = const Duration(seconds: 1),
  _StubKeyguardOverrideController? keyguard,
  TimerRepository? repository,
  NotificationScheduler? scheduler,
  String? payload,
}) {
  final NotificationScheduler notificationScheduler =
      scheduler ?? _stubScheduler();
  final _InMemoryTimerRepository inMemoryRepo = _InMemoryTimerRepository();
  if (seedRinging != null) {
    inMemoryRepo._store[seedRinging.id] = seedRinging;
  }
  final TimerRepository repo = repository ?? inMemoryRepo;

  final router = GoRouter(
    initialLocation: payload == null
        ? '/alarm-ringing'
        : '/alarm-ringing?payload=${Uri.encodeQueryComponent(payload)}',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('home-stub')),
      ),
      GoRoute(
        path: '/timer',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('timer-stub')),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (BuildContext context, GoRouterState state) =>
            AlarmRingingScreen(payload: state.uri.queryParameters['payload']),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      alarmSoundPlayerProvider.overrideWithValue(player),
      alarmSoundHandoffDelayProvider.overrideWithValue(handoffDelay),
      alarmSoundSelectionTimeoutProvider.overrideWithValue(selectionTimeout),
      clockProvider.overrideWithValue(Clock(() => now ?? DateTime(2026, 1, 1))),
      keyguardOverrideControllerProvider.overrideWithValue(
        keyguard ?? _StubKeyguardOverrideController(),
      ),
      notificationSchedulerProvider.overrideWithValue(notificationScheduler),
      screenLockQueryProvider.overrideWithValue(
        _StubScreenLockQuery(locked: screenLocked),
      ),
      testNotificationStringsOverride(),
      timerRepositoryProvider.overrideWithValue(repo),
    ],
    // Force Japanese so existing assertions for "スヌーズ時間を選択"
    // remain stable; the alarm screen text now resolves through
    // AppLocalizations.
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

void main() {
  group('AlarmRingingScreen', () {
    testWidgets(
      'shows title and Stop / Snooze buttons without unresolved label',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player));
        await tester.pumpAndSettle();
        // Drain the 500ms cancel→play delay AlarmRingingNotifier.start
        // schedules so no Timer is left pending at teardown.
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byKey(const Key('alarm_ringing_title')), findsOneWidget);
        expect(find.byKey(const Key('alarm_stop_button')), findsOneWidget);
        expect(find.byKey(const Key('alarm_snooze_button')), findsOneWidget);
        expect(find.byKey(const Key('alarm_ringing_label')), findsNothing);
      },
    );

    testWidgets('shows timer label between title and action buttons', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(
        _harness(player, seedRinging: _seedRinging(label: 'Tea timer')),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      final Finder title = find.byKey(const Key('alarm_ringing_title'));
      final Finder label = find.byKey(const Key('alarm_ringing_label'));
      final Finder stopButton = find.byKey(const Key('alarm_stop_button'));

      expect(label, findsOneWidget);
      expect(find.text('Tea timer'), findsOneWidget);
      expect(
        tester.getBottomLeft(title).dy,
        lessThan(tester.getTopLeft(label).dy),
      );
      expect(
        tester.getBottomLeft(label).dy,
        lessThan(tester.getTopLeft(stopButton).dy),
      );
    });

    testWidgets('hides an empty timer label', (WidgetTester tester) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player, seedRinging: _seedRinging()));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('alarm_ringing_label')), findsNothing);
    });

    testWidgets('limits a long timer label to two centered ellipsis lines', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      final String longLabel = List<String>.filled(50, 'A').join();
      await tester.pumpWidget(
        _harness(player, seedRinging: _seedRinging(label: longLabel)),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      final Text label = tester.widget<Text>(
        find.byKey(const Key('alarm_ringing_label')),
      );
      expect(label.data, longLabel);
      expect(label.maxLines, 2);
      expect(label.overflow, TextOverflow.ellipsis);
      expect(label.textAlign, TextAlign.center);
    });

    testWidgets(
      'AppBar has no back button while the alarm is ringing — Stop / Snooze are the only exits',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        // automaticallyImplyLeading: false drops the BackButton, and
        // PopScope(canPop: false) blocks both gesture-back and any
        // explicit Navigator.pop attempts.
        expect(find.byType(BackButton), findsNothing);
      },
    );

    testWidgets(
      'self-bootstraps audio on cold-start (no ringing timer in collection)',
      (WidgetTester tester) async {
        // Cold launch: collection is empty. The screen still arms audio
        // with the synthetic 'unknown' timer id so the user is not met
        // with silence after the OS notification was dismissed.
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);

        expect(player.playCalls, 1);
        final ringing = container.read(alarmRingingNotifierProvider);
        expect(ringing.isPlaying, isTrue);
        expect(ringing.currentTimerId, 'unknown');
        expect(ringing.currentSoundId, 'default');
      },
    );

    testWidgets('cold timerは1秒超のDB応答後も保存済みnotificationIdをcancelする', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      final scheduler = _stubScheduler();
      final persisted = TimerEntity(
        id: 'timer-slow-cold',
        notificationId: 24680,
        label: 'Slow cold timer',
        duration: const Duration(minutes: 1),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.ringing,
        createdAt: DateTime.utc(2026, 7, 16),
        soundId: 'late-imported-sound',
      );

      await tester.pumpWidget(
        _harness(
          player,
          payload: 'timer:${persisted.id}',
          repository: _DelayedColdTimerRepository(
            persisted,
            const Duration(milliseconds: 1100),
          ),
          scheduler: scheduler,
          selectionTimeout: const Duration(seconds: 1),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1000));
      expect(player.playCalls, 1, reason: '音源選択はdefaultへ期限内fallbackする');
      verifyNever(() => scheduler.cancel(persisted.notificationId));

      await tester.pump(const Duration(milliseconds: 100));
      verify(() => scheduler.cancel(persisted.notificationId)).called(1);

      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      expect(
        container.read(alarmRingingNotifierProvider).currentSoundId,
        AlarmSoundCatalog.defaultSound.id,
      );
    });

    testWidgets('start is idempotent — second start while playing is a no-op', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      expect(player.playCalls, 1);

      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      await container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 'late-tick',
            sound: AlarmSoundCatalog.defaultSound,
            notificationId: 99,
          );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      expect(player.playCalls, 1);
    });

    testWidgets('Stop button stops the player and cancels the ringing timer', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      final keyguard = _StubKeyguardOverrideController();
      final TimerEntity seeded = TimerEntity(
        id: 'ringing-1',
        notificationId: 1,
        label: '',
        duration: const Duration(seconds: 5),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.ringing,
        createdAt: DateTime(2026, 1, 1),
      );
      await tester.pumpWidget(
        _harness(player, seedRinging: seeded, keyguard: keyguard),
      );
      // Pump the microtask that loads the collection from the repo.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('alarm_stop_button')));
      await tester.pumpAndSettle();

      expect(player.stopCalls, greaterThanOrEqualTo(1));
      // Issue #73: leaving the screen releases the keyguard-override via
      // the Application-layer provider.
      expect(keyguard.clearCalls, 1);
      // Phase 11 follow-up: Stop の cold-launch fallback は `/` 単独に
      // 置換 (Phase 10.5 までの「`/timer` push で 2 段再構築」は廃止)。
      // tab 復元は HomeScreen の lastHomePageIndex に委譲するので、
      // ここでは home-stub への遷移のみを assert する。
      final BuildContext context = tester.element(find.text('home-stub'));
      final container = ProviderScope.containerOf(context);
      final ringing = container.read(alarmRingingNotifierProvider);
      expect(ringing.isPlaying, isFalse);
      expect(ringing.currentTimerId, isNull);
      final collection = container.read(timerCollectionNotifierProvider);
      expect(collection.findById('ringing-1')?.status, TimerStatus.cancelled);
      expect(find.text('home-stub'), findsOneWidget);
      expect(find.byType(AlarmRingingScreen), findsNothing);
    });

    testWidgets(
      'cold-start: Stop replaces the stack with Home so back-key exits the app',
      (WidgetTester tester) async {
        // Phase 11 follow-up: cold-start fallback は `/` 単独 push に
        // 戻った (旧 F-4 修正の「Home → list 2 段再構築」は Phase 11 で
        // HomeScreen が PageView 化したことで `/timer` が薄ラッパに縮退
        // し、戻ると見覚えのない左上 ← だけの画面になる退行を起こした)。
        // 1 段スタックで Home に直行し、戻るキー = アプリ終了が正解。
        final player = _StubAlarmSoundPlayer();
        final TimerEntity seeded = _seedRinging();
        await tester.pumpWidget(_harness(player, seedRinging: seeded));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.byKey(const Key('alarm_stop_button')));
        await tester.pumpAndSettle();

        // 1) Stop 直後は home-stub が最前面 (1 段スタック)。
        expect(find.text('home-stub'), findsOneWidget);
        expect(find.text('timer-stub'), findsNothing);

        // 2) `canPop` は false (= 戻るキーで pop すべき何もない)。
        //    Android 側はこの状態で system back を握ってアプリを終了
        //    させる。`pop()` 呼び出しは何も起こさず、home-stub のまま。
        final BuildContext ctx = tester.element(find.text('home-stub'));
        expect(GoRouter.of(ctx).canPop(), isFalse);
        expect(find.text('home-stub'), findsOneWidget);
      },
    );

    testWidgets('Snooze button opens 3/5/10-minute chooser sheet', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      final TimerEntity seeded = _seedRinging();
      await tester.pumpWidget(_harness(player, seedRinging: seeded));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('alarm_snooze_button')));
      await tester.pumpAndSettle();

      expect(find.text('スヌーズ時間を選択'), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_choice_3m')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_choice_5m')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_choice_10m')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_cancel')), findsOneWidget);
    });

    testWidgets(
      'selecting 5 minutes snoozes the timer and leaves the alarm screen',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        final keyguard = _StubKeyguardOverrideController();
        final TimerEntity seeded = _seedRinging();
        final DateTime fixedNow = DateTime(2026, 5, 1, 7, 30);
        await tester.pumpWidget(
          _harness(
            player,
            now: fixedNow,
            seedRinging: seeded,
            keyguard: keyguard,
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('alarm_snooze_choice_5m')));
        await tester.pumpAndSettle();

        // Issue #73: snooze also leaves the screen → keyguard-override
        // released via the provider.
        expect(keyguard.clearCalls, 1);

        // Phase 11 follow-up: snooze の cold-launch fallback も Stop と
        // 同じく `/` 単独 push に統一。home-stub への遷移を assert する。
        final BuildContext context = tester.element(find.text('home-stub'));
        final container = ProviderScope.containerOf(context);
        final TimerEntity entity = container
            .read(timerCollectionNotifierProvider)
            .findById('ringing-1')!;
        expect(entity.status, TimerStatus.running);
        expect(entity.endAt, isNotNull);
        expect(find.text('home-stub'), findsOneWidget);
        expect(find.byType(AlarmRingingScreen), findsNothing);
      },
    );

    testWidgets('screenLocked=true でも固定3200msのハンドオフ境界を使う', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(
        _harness(
          player,
          screenLocked: true,
          handoffDelay: const Duration(milliseconds: 3200),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 3199));
      expect(player.playCalls, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(player.playCalls, 1);
    });

    testWidgets('screenLocked=false でも固定3200msのハンドオフ境界を使う', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(
        _harness(player, handoffDelay: const Duration(milliseconds: 3200)),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 3199));
      expect(player.playCalls, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(player.playCalls, 1);
    });

    group('AlarmPushReservation dedup (Review #5)', () {
      test(
        'first caller acquires, subsequent callers blocked until released',
        () {
          // Per-container scope replaces the old static flag + debugReset
          // seam: a fresh container starts unreserved, no manual reset.
          final ProviderContainer container = ProviderContainer();
          addTearDown(container.dispose);
          final AlarmPushReservation reservation = container.read(
            alarmPushReservationProvider.notifier,
          );

          expect(reservation.tryReserve(), isTrue);
          expect(reservation.tryReserve(), isFalse);
          expect(reservation.tryReserve(), isFalse);
          reservation.release();
          expect(reservation.tryReserve(), isTrue);
        },
      );
    });

    testWidgets(
      'cancelling the snooze chooser keeps the alarm screen and timer ringing',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        final TimerEntity seeded = _seedRinging();
        await tester.pumpWidget(_harness(player, seedRinging: seeded));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('alarm_snooze_cancel')));
        await tester.pumpAndSettle();

        expect(find.text('スヌーズ時間を選択'), findsNothing);
        expect(find.byType(AlarmRingingScreen), findsOneWidget);
        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);
        expect(
          container
              .read(timerCollectionNotifierProvider)
              .findById('ringing-1')!
              .status,
          TimerStatus.ringing,
        );
      },
    );
  });
}

TimerEntity _seedRinging({String label = ''}) => TimerEntity(
  id: 'ringing-1',
  notificationId: 42,
  label: label,
  duration: const Duration(seconds: 5),
  endAt: null,
  pausedRemaining: null,
  status: TimerStatus.ringing,
  createdAt: DateTime(2026, 5, 1, 7, 30),
);
