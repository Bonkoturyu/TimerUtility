import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/home/alarm_list_page.dart';

import '../../../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

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
  when(() => s.cancel(any())).thenAnswer((_) async {});
  when(() => s.cancelAll()).thenAnswer((_) async {});
  return s;
}

Widget _harness() {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 10, 6))),
      alarmRepositoryProvider.overrideWithValue(_InMemoryAlarmRepo()),
      notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
      testNotificationStringsOverride(),
      permissionNotifierProvider.overrideWith(
        () => _GrantedPermissionNotifier(),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: <Locale>[Locale('ja'), Locale('en')],
      home: Scaffold(body: AlarmListPage()),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  group('AlarmListPage (Phase 11 body widget)', () {
    testWidgets('renders the empty hint when no alarms exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await _settle(tester);

      expect(find.byKey(const Key('alarm_list_empty_hint')), findsOneWidget);
      // The Page does not own a FAB; that is the host's responsibility.
      expect(find.byKey(const Key('alarm_list_add_fab')), findsNothing);
    });
  });
}
