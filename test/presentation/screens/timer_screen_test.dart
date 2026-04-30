import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/timer_notifier.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/presentation/screens/timer_screen.dart';

class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  AlarmSound? lastPlayed;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(AlarmSound sound) async {
    lastPlayed = sound;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {}
}

class _StubPermissionManager implements PermissionManager {
  _StubPermissionManager({
    this.notificationStatus = DomainPermissionStatus.granted,
    this.exactAlarmStatus = DomainPermissionStatus.granted,
    this.fullScreenIntentStatus = DomainPermissionStatus.granted,
  });

  DomainPermissionStatus notificationStatus;
  DomainPermissionStatus exactAlarmStatus;
  DomainPermissionStatus fullScreenIntentStatus;

  int openFullScreenIntentSettingsCalls = 0;

  @override
  Future<DomainPermissionStatus> checkNotification() async =>
      notificationStatus;

  @override
  Future<DomainPermissionStatus> requestNotification() async {
    notificationStatus = DomainPermissionStatus.granted;
    return notificationStatus;
  }

  @override
  Future<DomainPermissionStatus> checkScheduleExactAlarm() async =>
      exactAlarmStatus;

  @override
  Future<DomainPermissionStatus> requestScheduleExactAlarm() async {
    exactAlarmStatus = DomainPermissionStatus.granted;
    return exactAlarmStatus;
  }

  @override
  Future<DomainPermissionStatus> checkFullScreenIntent() async =>
      fullScreenIntentStatus;

  @override
  Future<void> openFullScreenIntentSettings() async {
    openFullScreenIntentSettingsCalls++;
  }

  @override
  Future<bool> openAppSettings() async => true;
}

Widget _harness(_MutableNow holder, {PermissionManager? permissionManager}) {
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
  when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  when(() => scheduler.cancelAll()).thenAnswer((_) async {});

  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const TimerScreen(),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('alarm-ringing-stub')),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock(() => holder.now)),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      permissionManagerProvider.overrideWithValue(
        permissionManager ?? _StubPermissionManager(),
      ),
      alarmSoundPlayerProvider.overrideWithValue(_StubAlarmSoundPlayer()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('TimerScreen setup mode', () {
    testWidgets('shows preset duration chips when no timer is configured', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      expect(find.text('Choose a duration'), findsOneWidget);
      expect(find.byKey(const Key('timer_preset_5s')), findsOneWidget);
      expect(find.byKey(const Key('timer_preset_60s')), findsOneWidget);
    });

    testWidgets('tapping a preset transitions to active idle view', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_5s')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timer_display')), findsOneWidget);
      expect(find.byKey(const Key('timer_start_button')), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const Key('timer_display')))).data,
        '00:05',
      );
    });
  });

  group('TimerScreen active mode', () {
    testWidgets('5-second timer reaches Time\'s up after elapsing 5 s', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_5s')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timer_start_button')));
      await tester.pump();

      // Advance the clock and let internal Timer.periodic fire.
      now.now = DateTime(2026, 1, 1, 12, 0, 6);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text("Time's up!"), findsOneWidget);
      expect(find.byKey(const Key('timer_dismiss_button')), findsOneWidget);

      // Stop ticker so Flutter's leak detector is happy.
      await tester.tap(find.byKey(const Key('timer_dismiss_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Pause replaces Pause button with Resume', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_60s')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timer_start_button')));
      await tester.pump();

      now.now = DateTime(2026, 1, 1, 12, 0, 5);
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const Key('timer_pause_button')));
      await tester.pump();

      expect(find.byKey(const Key('timer_resume_button')), findsOneWidget);
      expect(find.byKey(const Key('timer_pause_button')), findsNothing);

      // Verify state via container
      final BuildContext context = tester.element(find.byType(TimerScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(timerNotifierProvider)!.status, TimerStatus.paused);
    });

    testWidgets('Back button returns to setup view', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_5s')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timer_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose a duration'), findsOneWidget);
      expect(find.byKey(const Key('timer_display')), findsNothing);
    });
  });

  group('TimerScreen permission banners', () {
    testWidgets('shows POST_NOTIFICATIONS banner when denied', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final pm = _StubPermissionManager(
        notificationStatus: DomainPermissionStatus.denied,
        exactAlarmStatus: DomainPermissionStatus.granted,
      );
      await tester.pumpWidget(_harness(now, permissionManager: pm));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('banner_post_notifications')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('banner_exact_alarm')), findsNothing);
    });

    testWidgets('shows SCHEDULE_EXACT_ALARM banner when denied', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final pm = _StubPermissionManager(
        notificationStatus: DomainPermissionStatus.granted,
        exactAlarmStatus: DomainPermissionStatus.denied,
      );
      await tester.pumpWidget(_harness(now, permissionManager: pm));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_exact_alarm')), findsOneWidget);
      expect(find.byKey(const Key('banner_post_notifications')), findsNothing);
    });

    testWidgets('shows full-screen-intent banner when denied', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final pm = _StubPermissionManager(
        fullScreenIntentStatus: DomainPermissionStatus.denied,
      );
      await tester.pumpWidget(_harness(now, permissionManager: pm));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('banner_full_screen_intent')),
        findsOneWidget,
      );

      await tester.tap(find.text('設定を開く'));
      await tester.pump();
      expect(pm.openFullScreenIntentSettingsCalls, 1);
    });

    testWidgets('hides all banners when permissions granted', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_post_notifications')), findsNothing);
      expect(find.byKey(const Key('banner_exact_alarm')), findsNothing);
      expect(find.byKey(const Key('banner_full_screen_intent')), findsNothing);
    });
  });
}
