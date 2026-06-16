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
  final Map<String, int> _ints = <String, int>{};
  final Map<String, String> _strings = <String, String>{};

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async {
    _bools[key] = value;
  }

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<void> setInt(String key, int value) async {
    _ints[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _bools.remove(key);
    _ints.remove(key);
    _strings.remove(key);
  }
}

class _GrantedPermissionNotifier extends PermissionNotifier {
  int ensureCalls = 0;

  @override
  PermissionState build() => const PermissionState(
    postNotifications: DomainPermissionStatus.granted,
    scheduleExactAlarm: DomainPermissionStatus.granted,
    fullScreenIntent: DomainPermissionStatus.granted,
  );

  @override
  Future<void> ensureNotificationPermissionForScheduling() async {
    ensureCalls++;
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
  when(() => s.cancel(any())).thenAnswer((_) async {});
  when(() => s.cancelAll()).thenAnswer((_) async {});
  return s;
}

Widget _harness({
  String? alarmId,
  AlarmEntity? seed,
  _MemoryUserPrefs? userPrefs,
  _InMemoryAlarmRepo? repo,
  PermissionNotifier Function()? permissionNotifier,
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
        permissionNotifier ?? () => _GrantedPermissionNotifier(),
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

    testWidgets('enabled=true の新規保存前に通知権限要求フローを通す', (
      WidgetTester tester,
    ) async {
      final repo = _InMemoryAlarmRepo();
      final permissions = _GrantedPermissionNotifier();
      await tester.pumpWidget(
        _harness(repo: repo, permissionNotifier: () => permissions),
      );
      await _openEdit(tester);

      await tester.tap(find.byKey(const Key('alarm_edit_save_button')));
      await tester.pumpAndSettle();

      expect(permissions.ensureCalls, 1);
      expect(repo.store.length, 1);
    });

    testWidgets('enabled=false の新規保存では通知権限要求を省略する', (
      WidgetTester tester,
    ) async {
      final repo = _InMemoryAlarmRepo();
      final permissions = _GrantedPermissionNotifier();
      await tester.pumpWidget(
        _harness(repo: repo, permissionNotifier: () => permissions),
      );
      await _openEdit(tester);

      await tester.tap(find.byKey(const Key('alarm_edit_enabled_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alarm_edit_save_button')));
      await tester.pumpAndSettle();

      expect(permissions.ensureCalls, 0);
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

    testWidgets('上限到達状態で新規保存すると上限 SnackBar が出て画面に留まる', (
      WidgetTester tester,
    ) async {
      // F-1: MaxAlarmCountExceededException を AlarmEditScreen が
      // catch して SnackBar 通知 + 画面 pop しないことの回帰テスト。
      //
      // PR #12 review 反映:
      // - 上限件数は AlarmCollectionNotifier.maxSize を参照 (将来変更耐性)
      // - seed alarm は enabled: false (テスト目的と無関係な
      //   _loadFromRepository 内 schedule 副作用を回避)
      const int limit = AlarmCollectionNotifier.maxSize;
      final repo = _InMemoryAlarmRepo();
      for (int i = 0; i < limit; i++) {
        final AlarmEntity a = _seed(id: 'seed-$i', enabled: false);
        repo.store[a.id] = a;
      }
      await tester.pumpWidget(_harness(repo: repo));
      await _openEdit(tester);
      // notifier の load microtask を消化 (limit 件 state 反映)
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('alarm_edit_save_button')));
      await tester.pumpAndSettle();

      // ja ARB: "上限 {count} 件に達しています" → maxSize で展開
      expect(find.text('上限 $limit 件に達しています'), findsOneWidget);
      // 画面に留まっている (AppBar タイトルが新規モードのまま)
      expect(find.text('アラームを追加'), findsOneWidget);
      // repo は limit 件のまま (新規追加されていない)
      expect(repo.store.length, limit);
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

    testWidgets('stale id (load 完了後も対象なし) で SnackBar を出して画面を閉じる', (
      WidgetTester tester,
    ) async {
      // PR #11 review (Copilot) 反映: deep link 等で存在しない id を
      // 踏んだ際にローディング表示が永続する問題の回帰テスト。
      // repo は最初から空 → load microtask 完了で state は空のまま →
      // listen の prev != null で stale id 確定 → SnackBar + pop。
      //
      // 注: AlarmCollectionNotifier._loadFromRepository は state が
      // 空のまま return するため (persisted が空ならそもそも更新しない)、
      // 純粋な空 repo では listen 第二発火が起きない。テストでは
      // 「他の alarm を持つ repo + 異なる alarmId」を渡して、load 完了
      // → state populated → 対象外 id で listen 発火する経路を取る。
      final AlarmEntity other = _seed(id: 'a-other');
      final repo = _InMemoryAlarmRepo()..store[other.id] = other;
      await tester.pumpWidget(_harness(alarmId: 'missing', repo: repo));
      await _openEdit(tester);
      // load microtask + listen 発火 + postFrameCallback 消化を待つ
      await tester.pumpAndSettle();

      // SnackBar が出ている (alarmEditNotFound キー: 「対象のアラームが
      // 見つかりませんでした」)
      expect(find.text('対象のアラームが見つかりませんでした'), findsOneWidget);
      // 画面が閉じた = list-stub の open ボタンに戻っている
      expect(find.byKey(const Key('open_edit')), findsOneWidget);
    });
  });
}
