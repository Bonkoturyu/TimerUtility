import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_collection_notifier.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/alarm_ringing_screen.dart';

import '../../helpers/test_notification_strings.dart';

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  int playCalls = 0;
  int stopCalls = 0;

  @override
  bool get isPlaying => _isPlaying;

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

class _InMemoryAlarmRepo implements AlarmRepository {
  final Map<String, AlarmEntity> store = <String, AlarmEntity>{};

  @override
  Future<void> delete(String id) async {
    store.remove(id);
  }

  @override
  Future<List<AlarmEntity>> findAll() async => store.values.toList();

  @override
  Future<AlarmEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(AlarmEntity entity) async {
    store[entity.id] = entity;
  }
}

class _InMemoryTimerRepo implements TimerRepository {
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<TimerEntity>> findAll() async => <TimerEntity>[];
  @override
  Future<TimerEntity?> findById(String id) async => null;
  @override
  Future<void> upsert(TimerEntity entity) async {}
}

class _GrantedPermissionNotifier extends PermissionNotifier {
  @override
  PermissionState build() => const PermissionState(
    postNotifications: DomainPermissionStatus.granted,
    scheduleExactAlarm: DomainPermissionStatus.granted,
    fullScreenIntent: DomainPermissionStatus.granted,
  );
}

NotificationScheduler _stubScheduler() {
  final s = _MockNotificationScheduler();
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
  when(() => s.cancel(any())).thenAnswer((_) async {});
  when(() => s.cancelAll()).thenAnswer((_) async {});
  when(
    () => s.show(
      notificationId: any(named: 'notificationId'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  return s;
}

Widget _harness(
  _StubAlarmSoundPlayer player, {
  required AlarmEntity seedAlarm,
  DateTime? now,
  NotificationScheduler? scheduler,
}) {
  final NotificationScheduler s = scheduler ?? _stubScheduler();
  final _InMemoryAlarmRepo repo = _InMemoryAlarmRepo();
  repo.store[seedAlarm.id] = seedAlarm;

  final router = GoRouter(
    initialLocation:
        '/alarm-ringing?payload=${Uri.encodeQueryComponent('alarm:${seedAlarm.id}')}',
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
      // Phase 9.5 follow-up: alarm 由来の Stop 後 fallback は `/alarms`
      // に飛ぶようになったため、stub を追加。
      GoRoute(
        path: '/alarms',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('alarms-stub')),
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
      clockProvider.overrideWithValue(
        Clock(() => now ?? DateTime(2026, 5, 4, 7)),
      ),
      notificationSchedulerProvider.overrideWithValue(s),
      testNotificationStringsOverride(),
      alarmRepositoryProvider.overrideWithValue(repo),
      timerRepositoryProvider.overrideWithValue(_InMemoryTimerRepo()),
      permissionNotifierProvider.overrideWith(
        () => _GrantedPermissionNotifier(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

AlarmEntity _seedOnceAlarm() => AlarmEntity(
  id: 'alarm-1',
  notificationId: 42,
  label: 'Wake up',
  targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
  repeat: const AlarmRepeatOnce(),
  snoozeMinutes: 10,
  enabled: true,
  createdAt: DateTime.utc(2026, 5, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
    AlarmRingingScreen.debugResetPushReservation();
  });

  tearDown(AlarmRingingScreen.debugResetPushReservation);

  group('AlarmRingingScreen (alarm payload path)', () {
    testWidgets('payload="alarm:<id>" で起動すると alarm 由来として再生される', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player, seedAlarm: _seedOnceAlarm()));
      await tester.pumpAndSettle();
      // start() の cancel→500ms→play 順序を消化させる。
      await tester.pump(const Duration(milliseconds: 600));

      expect(player.playCalls, 1);
      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      final ringing = container.read(alarmRingingNotifierProvider);
      expect(ringing.currentSource, AlarmSource.alarm);
      expect(ringing.currentTimerId, 'alarm-1');
    });

    testWidgets(
      'Stop 押下で AlarmCollectionNotifier.onFiredStop が走り once は disabled',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player, seedAlarm: _seedOnceAlarm()));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.byKey(const Key('alarm_stop_button')));
        await tester.pumpAndSettle();

        expect(player.stopCalls, greaterThanOrEqualTo(1));
        // onFiredStop が走っているなら state の alarm は enabled=false に
        // 落ちている。alarm 由来の cold-start fallback は `/alarms` に
        // 飛ぶようになったので、alarms-stub を起点にして provider を読む。
        final BuildContext context = tester.element(find.text('alarms-stub'));
        final container = ProviderScope.containerOf(context);
        final List<AlarmEntity> alarms = container.read(
          alarmCollectionNotifierProvider,
        );
        expect(alarms.first.enabled, isFalse);
      },
    );

    testWidgets('Snooze 押下で alarm.snoozeMinutes ぶんだけ即時再 schedule (シート無し)', (
      WidgetTester tester,
    ) async {
      final scheduler = _stubScheduler();
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(
        _harness(
          player,
          seedAlarm: _seedOnceAlarm(),
          now: DateTime(2026, 5, 4, 7, 0),
          scheduler: scheduler,
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('alarm_snooze_button')));
      await tester.pumpAndSettle();

      // 既存 Timer 経路のシート (alarm_snooze_choice_*) は出ない。
      expect(find.byKey(const Key('alarm_snooze_choice_5m')), findsNothing);
      // alarm.snoozeMinutes = 10 → 07:10 に同 notificationId で再 schedule。
      verify(
        () => scheduler.schedule(
          notificationId: 42,
          fireAt: DateTime(2026, 5, 4, 7, 10),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:alarm-1',
        ),
      ).called(1);
      // 鳴動 UI を抜けている。
      expect(find.byType(AlarmRingingScreen), findsNothing);
    });
  });
}
