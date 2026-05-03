import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/alarm_edit_screen.dart';

import '../../helpers/test_notification_strings.dart';

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

Widget _harness({
  String? alarmId,
  AlarmEntity? seed,
  _MemoryUserPrefs? userPrefs,
  _InMemoryAlarmRepo? repo,
}) {
  final _InMemoryAlarmRepo r = repo ?? _InMemoryAlarmRepo();
  if (seed != null) r.store[seed.id] = seed;

  final router = GoRouter(
    initialLocation: '/list',
    routes: <RouteBase>[
      // list-stub: AlarmEditScreen.context.pop() の戻り先を確保するため、
      // initial location は list 相当のスタブにし、test の最初に push で
      // /edit に遷移する形にする。本番ルートでも List → Edit という
      // 遷移パスを再現できる。
      GoRoute(
        path: '/list',
        builder: (BuildContext context, GoRouterState state) => Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open_edit'),
                onPressed: () {
                  if (alarmId == null) {
                    context.push('/alarms/edit');
                  } else {
                    context.push('/alarms/edit/$alarmId');
                  }
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/alarms/edit',
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmEditScreen(),
      ),
      GoRoute(
        path: '/alarms/edit/:id',
        builder: (BuildContext context, GoRouterState state) =>
            AlarmEditScreen(alarmId: state.pathParameters['id']),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 4, 6))),
      alarmRepositoryProvider.overrideWithValue(r),
      notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
      testNotificationStringsOverride(),
      userPreferencesProvider.overrideWithValue(
        userPrefs ?? _MemoryUserPrefs(),
      ),
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

/// edit 画面に遷移するヘルパ。各テストの先頭で呼び出す。
Future<void> _openEdit(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open_edit')));
  await tester.pumpAndSettle();
}

AlarmEntity _seed({
  String id = 'a-1',
  bool enabled = true,
  AlarmRepeat? repeat,
  TimeOfDayValue? targetTime,
  String label = '',
  int snoozeMinutes = 5,
  String? soundId,
}) {
  return AlarmEntity(
    id: id,
    notificationId: 99,
    label: label,
    targetTime: targetTime ?? const TimeOfDayValue.unsafe(hour: 7, minute: 0),
    repeat: repeat ?? const AlarmRepeatOnce(),
    snoozeMinutes: snoozeMinutes,
    enabled: enabled,
    soundId: soundId,
    createdAt: DateTime.utc(2026, 5, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  group('AlarmEditScreen 新規モード', () {
    testWidgets('AppBar タイトルが「アラームを追加」になる', (WidgetTester tester) async {
      await tester.pumpWidget(_harness());
      await _openEdit(tester);
      expect(find.text('アラームを追加'), findsOneWidget);
    });

    testWidgets('削除ボタンは新規モードでは出ない', (WidgetTester tester) async {
      await tester.pumpWidget(_harness());
      await _openEdit(tester);
      expect(find.byKey(const Key('alarm_edit_delete_button')), findsNothing);
    });

    testWidgets('保存ボタンを押すと AlarmCollectionNotifier に追加され、戻る', (
      WidgetTester tester,
    ) async {
      final repo = _InMemoryAlarmRepo();
      await tester.pumpWidget(_harness(repo: repo));
      await _openEdit(tester);

      await tester.tap(find.byKey(const Key('alarm_edit_save_button')));
      await tester.pumpAndSettle();

      expect(repo.store.length, 1);
    });

    testWidgets('繰り返し SegmentedButton で曜日指定に切り替えると WeekdaySelector が出る', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await _openEdit(tester);

      // 単発モード: 曜日チップは出ていない
      expect(find.byKey(const Key('weekday_chip_monday')), findsNothing);

      // 「曜日指定」をタップ
      await tester.tap(find.text('曜日指定'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weekday_chip_monday')), findsOneWidget);
      expect(find.byKey(const Key('weekday_chip_sunday')), findsOneWidget);
    });

    testWidgets('曜日指定モードのデフォルトは全曜日選択済み', (WidgetTester tester) async {
      await tester.pumpWidget(_harness());
      await _openEdit(tester);
      await tester.tap(find.text('曜日指定'));
      await tester.pumpAndSettle();

      for (final DayOfWeek d in DayOfWeek.values) {
        final chip = tester.widget<FilterChip>(
          find.byKey(Key('weekday_chip_${d.name}')),
        );
        expect(chip.selected, isTrue);
      }
    });

    testWidgets('曜日指定モードで全曜日を外して保存しようとすると SnackBar で警告', (
      WidgetTester tester,
    ) async {
      final repo = _InMemoryAlarmRepo();
      await tester.pumpWidget(_harness(repo: repo));
      await _openEdit(tester);
      await tester.tap(find.text('曜日指定'));
      await tester.pumpAndSettle();

      // 全曜日を外す
      for (final DayOfWeek d in DayOfWeek.values) {
        await tester.tap(find.byKey(Key('weekday_chip_${d.name}')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('alarm_edit_save_button')));
      await tester.pump();

      expect(find.text('曜日を1つ以上選択してください'), findsOneWidget);
      expect(repo.store, isEmpty);
    });

    testWidgets('enabled Switch で初期 ON、OFF 切替で false で保存される', (
      WidgetTester tester,
    ) async {
      final repo = _InMemoryAlarmRepo();
      await tester.pumpWidget(_harness(repo: repo));
      await _openEdit(tester);

      // 初期 enabled は true (Switch は ON)
      final initialSwitch = tester.widget<Switch>(
        find.byKey(const Key('alarm_edit_enabled_switch')),
      );
      expect(initialSwitch.value, isTrue);

      await tester.tap(find.byKey(const Key('alarm_edit_enabled_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alarm_edit_save_button')));
      await tester.pumpAndSettle();

      expect(repo.store.values.first.enabled, isFalse);
    });
  });

  group('AlarmEditScreen 既存編集モード', () {
    testWidgets('AppBar タイトルが「アラームを編集」になる', (WidgetTester tester) async {
      final AlarmEntity existing = _seed();
      final repo = _InMemoryAlarmRepo()..store[existing.id] = existing;
      await tester.pumpWidget(_harness(alarmId: existing.id, repo: repo));
      await _openEdit(tester);
      expect(find.text('アラームを編集'), findsOneWidget);
    });

    testWidgets('既存値がフォームに反映される (時刻 / ラベル)', (WidgetTester tester) async {
      final AlarmEntity existing = _seed(
        targetTime: const TimeOfDayValue.unsafe(hour: 8, minute: 30),
        label: 'Wake up',
      );
      final repo = _InMemoryAlarmRepo()..store[existing.id] = existing;
      await tester.pumpWidget(_harness(alarmId: existing.id, repo: repo));
      await _openEdit(tester);
      // notifier の load microtask を消化
      await tester.pumpAndSettle();

      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('Wake up'), findsOneWidget);
    });

    testWidgets('削除ボタンが出る + 削除確認ダイアログで Delete → 削除される', (
      WidgetTester tester,
    ) async {
      final AlarmEntity existing = _seed(id: 'to-delete');
      final repo = _InMemoryAlarmRepo()..store[existing.id] = existing;
      await tester.pumpWidget(_harness(alarmId: existing.id, repo: repo));
      await _openEdit(tester);

      await tester.tap(find.byKey(const Key('alarm_edit_delete_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alarm_delete_confirm')), findsOneWidget);

      await tester.tap(find.byKey(const Key('alarm_delete_confirm')));
      await tester.pumpAndSettle();

      expect(repo.store.containsKey('to-delete'), isFalse);
    });

    testWidgets('skipAlarmDeleteConfirm が true ならダイアログをスキップして即削除', (
      WidgetTester tester,
    ) async {
      final prefs = _MemoryUserPrefs();
      await prefs.setBool('skipAlarmDeleteConfirm', true);
      final AlarmEntity existing = _seed(id: 'skip-confirm');
      final repo = _InMemoryAlarmRepo()..store[existing.id] = existing;
      await tester.pumpWidget(
        _harness(alarmId: existing.id, repo: repo, userPrefs: prefs),
      );
      await _openEdit(tester);

      await tester.tap(find.byKey(const Key('alarm_edit_delete_button')));
      await tester.pumpAndSettle();

      // ダイアログは出ない
      expect(find.byKey(const Key('alarm_delete_confirm')), findsNothing);
      expect(repo.store.containsKey('skip-confirm'), isFalse);
    });
  });
}
