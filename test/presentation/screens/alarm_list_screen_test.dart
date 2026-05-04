import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_collection_notifier.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/alarm_list_screen.dart';

import '../../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _InMemoryAlarmRepo implements AlarmRepository {
  _InMemoryAlarmRepo([Iterable<AlarmEntity>? seed]) {
    if (seed != null) {
      for (final AlarmEntity a in seed) {
        store[a.id] = a;
      }
    }
  }
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

AlarmEntity _seed({
  String id = 'a-1',
  bool enabled = true,
  AlarmRepeat? repeat,
  TimeOfDayValue? targetTime,
  String label = '',
  int snoozeMinutes = 5,
  String? soundId,
  DateTime? createdAt,
}) {
  return AlarmEntity(
    id: id,
    notificationId: id.hashCode & 0x7FFFFFFF,
    label: label,
    targetTime: targetTime ?? const TimeOfDayValue.unsafe(hour: 7, minute: 0),
    repeat: repeat ?? const AlarmRepeatOnce(),
    snoozeMinutes: snoozeMinutes,
    enabled: enabled,
    soundId: soundId,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 1),
  );
}

/// AlarmListScreen + 編集画面導線 (push 検証用 stub) を組んだハーネス。
/// 編集画面遷移はテスト対象外なので、`/alarms/edit` 系は単純な
/// Scaffold スタブにマップして「push が走ったか」だけ確認する。
Widget _harness({Iterable<AlarmEntity>? alarms, _InMemoryAlarmRepo? repo}) {
  final _InMemoryAlarmRepo r = repo ?? _InMemoryAlarmRepo(alarms);
  // alarms が指定されているのに repo が指定されている場合は repo が
  // 空でも seed を入れる (両方指定するケースは現状テストにない)。
  if (alarms != null && repo != null) {
    for (final AlarmEntity a in alarms) {
      r.store[a.id] = a;
    }
  }

  final router = GoRouter(
    initialLocation: AlarmListScreen.routeLocation,
    routes: <RouteBase>[
      GoRoute(
        path: AlarmListScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmListScreen(),
      ),
      GoRoute(
        path: '/alarms/edit',
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          key: Key('edit_stub_new'),
          body: Center(child: Text('edit-new-stub')),
        ),
      ),
      GoRoute(
        path: '/alarms/edit/:id',
        builder: (BuildContext context, GoRouterState state) => Scaffold(
          key: const Key('edit_stub_existing'),
          body: Center(child: Text('edit-${state.pathParameters['id']}-stub')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 4, 6))),
      alarmRepositoryProvider.overrideWithValue(r),
      notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
      testNotificationStringsOverride(),
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

/// build → microtask load → settle まで一気に消化するヘルパ。
Future<void> _settleRestore(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  testWidgets('空状態でヒントを表示する', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await _settleRestore(tester);

    expect(find.byKey(const Key('alarm_list_empty_hint')), findsOneWidget);
  });

  testWidgets('FAB タップで新規作成画面 (/alarms/edit) に遷移する', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await _settleRestore(tester);

    await tester.tap(find.byKey(const Key('alarm_list_add_fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_stub_new')), findsOneWidget);
    expect(find.text('edit-new-stub'), findsOneWidget);
  });

  testWidgets('永続化済アラームをカード表示する (時刻昇順)', (WidgetTester tester) async {
    final repo = _InMemoryAlarmRepo(<AlarmEntity>[
      _seed(
        id: 'a-1',
        targetTime: const TimeOfDayValue.unsafe(hour: 9, minute: 30),
      ),
      _seed(
        id: 'a-2',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
      ),
    ]);
    await tester.pumpWidget(_harness(repo: repo));
    await _settleRestore(tester);

    expect(find.byKey(const Key('alarm_card_a-1')), findsOneWidget);
    expect(find.byKey(const Key('alarm_card_a-2')), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
  });

  testWidgets(
    'カードの Switch をタップすると AlarmCollectionNotifier.toggle で enabled が反転する',
    (WidgetTester tester) async {
      final repo = _InMemoryAlarmRepo(<AlarmEntity>[
        _seed(id: 'a-1', enabled: true),
      ]);
      await tester.pumpWidget(_harness(repo: repo));
      await _settleRestore(tester);

      final BuildContext context = tester.element(find.byType(AlarmListScreen));
      final container = ProviderScope.containerOf(context);

      // 初期: enabled = true
      expect(
        container.read(alarmCollectionNotifierProvider).first.enabled,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('alarm_card_switch_a-1')));
      await tester.pumpAndSettle();

      expect(
        container.read(alarmCollectionNotifierProvider).first.enabled,
        isFalse,
      );
    },
  );

  testWidgets('カードタップで編集画面 (/alarms/edit/:id) に遷移する', (
    WidgetTester tester,
  ) async {
    final repo = _InMemoryAlarmRepo(<AlarmEntity>[_seed(id: 'a-1')]);
    await tester.pumpWidget(_harness(repo: repo));
    await _settleRestore(tester);

    await tester.tap(find.byKey(const Key('alarm_card_a-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_stub_existing')), findsOneWidget);
    expect(find.text('edit-a-1-stub'), findsOneWidget);
  });

  testWidgets('weekly (全曜日) は subtitle に「毎日」と表示される', (
    WidgetTester tester,
  ) async {
    final repo = _InMemoryAlarmRepo(<AlarmEntity>[
      _seed(
        id: 'a-1',
        repeat: AlarmRepeatWeekly.create(DayOfWeek.values.toSet()),
      ),
    ]);
    await tester.pumpWidget(_harness(repo: repo));
    await _settleRestore(tester);

    expect(find.text('毎日'), findsOneWidget);
  });

  testWidgets('weekly (部分集合) は曜日略称を空白区切りで表示する', (WidgetTester tester) async {
    final repo = _InMemoryAlarmRepo(<AlarmEntity>[
      _seed(
        id: 'a-1',
        repeat: AlarmRepeatWeekly.create(<DayOfWeek>{
          DayOfWeek.monday,
          DayOfWeek.wednesday,
          DayOfWeek.friday,
        }),
      ),
    ]);
    await tester.pumpWidget(_harness(repo: repo));
    await _settleRestore(tester);

    expect(find.text('月 水 金'), findsOneWidget);
  });
}
