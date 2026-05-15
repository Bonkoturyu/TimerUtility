import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/clock_entry_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/clock_entry_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/infrastructure/diagnostics/in_memory_diagnostic_sink_adapter.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/main.dart';
import 'package:timer_utility/presentation/screens/home/home_screen.dart';

import 'helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _MockClockEntryRepository extends Mock implements ClockEntryRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockEntryFake extends Fake implements ClockEntry {}

class _IdentityResolver implements TimezoneResolver {
  @override
  DateTime computeAt(DateTime now, String timezoneId) => now;
}

class _FakePrefs implements UserPreferences {
  final Map<String, bool> _bools = <String, bool>{};
  final Map<String, int> _ints = <String, int>{};
  final Map<String, String> _strings = <String, String>{};

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async => _bools[key] = value;

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<void> setInt(String key, int value) async => _ints[key] = value;

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setString(String key, String value) async =>
      _strings[key] = value;

  @override
  Future<void> remove(String key) async {
    _bools.remove(key);
    _ints.remove(key);
    _strings.remove(key);
  }
}

class _InMemoryTimerRepo implements TimerRepository {
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

class _InMemoryAlarmRepo implements AlarmRepository {
  final Map<String, AlarmEntity> store = <String, AlarmEntity>{};

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<AlarmEntity>> findAll() async => store.values.toList();

  @override
  Future<AlarmEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(AlarmEntity entity) async => store[entity.id] = entity;
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

ClockEntryRepository _stubClockRepo() {
  final r = _MockClockEntryRepository();
  when(() => r.findAll()).thenAnswer((_) async => <ClockEntry>[]);
  when(() => r.upsert(any())).thenAnswer((_) async {});
  when(() => r.delete(any())).thenAnswer((_) async {});
  when(() => r.replaceAll(any())).thenAnswer((_) async {});
  return r;
}

LocationDetector _stubDetector() {
  final d = _MockLocationDetector();
  when(() => d.detectTimezoneId()).thenAnswer((_) async => 'Etc/UTC');
  return d;
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(_ClockEntryFake());
    registerFallbackValue(<ClockEntry>[]);
  });

  testWidgets('App boots and mounts the Phase 11 PageView HomeScreen', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 10))),
          userPreferencesProvider.overrideWithValue(_FakePrefs()),
          timerRepositoryProvider.overrideWithValue(_InMemoryTimerRepo()),
          presetRepositoryProvider.overrideWithValue(_InMemoryPresetRepo()),
          alarmRepositoryProvider.overrideWithValue(_InMemoryAlarmRepo()),
          notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
          clockEntryRepositoryProvider.overrideWithValue(_stubClockRepo()),
          locationDetectorProvider.overrideWithValue(_stubDetector()),
          timezoneResolverProvider.overrideWithValue(_IdentityResolver()),
          testNotificationStringsOverride(),
          permissionNotifierProvider.overrideWith(
            () => _GrantedPermissionNotifier(),
          ),
        ],
        child: TimerUtilityApp(
          router: router,
          diagnosticSink: InMemoryDiagnosticSinkAdapter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The new HomeScreen mounts a horizontal PageView keyed
    // `home_page_view`; everything else (Timer landing tab, AppBar
    // chrome, FAB visibility, overflow contents) is exercised by
    // `test/presentation/screens/home/home_screen_test.dart` (Phase 11).
    expect(find.byKey(const Key('home_page_view')), findsOneWidget);
  });
}
