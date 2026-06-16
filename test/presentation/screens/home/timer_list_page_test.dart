import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/home/timer_list_page.dart';

import '../../../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _InMemoryRepo implements TimerRepository {
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

/// Wraps [TimerListPage] in a Scaffold so SnackBar / FAB hosting works
/// the same way HomeScreen / TimerListScreen will host it in production.
Widget _harness(
  _InMemoryRepo repo, {
  PermissionNotifier Function()? permissionNotifier,
  bool includeFab = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 10, 12))),
      timerRepositoryProvider.overrideWithValue(repo),
      presetRepositoryProvider.overrideWithValue(_InMemoryPresetRepo()),
      notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
      testNotificationStringsOverride(),
      permissionNotifierProvider.overrideWith(
        permissionNotifier ?? () => _GrantedPermissionNotifier(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
      home: Scaffold(
        body: const TimerListPage(),
        floatingActionButton: includeFab
            ? Consumer(
                builder: (BuildContext context, WidgetRef ref, _) =>
                    TimerListPage.buildFab(context, ref),
              )
            : null,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  group('TimerListPage (Phase 11 body widget)', () {
    testWidgets('renders the empty hint when no timers exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(_InMemoryRepo()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timer_list_empty_hint')), findsOneWidget);
      // FAB is supplied by the host (Scaffold), so the page itself
      // should not render one.
      expect(find.byKey(const Key('timer_list_add_fab')), findsNothing);
    });

    testWidgets('FAB タップでプリセット sheet 前に通知権限要求フローを通す', (
      WidgetTester tester,
    ) async {
      final permissions = _GrantedPermissionNotifier();
      await tester.pumpWidget(
        _harness(
          _InMemoryRepo(),
          permissionNotifier: () => permissions,
          includeFab: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_list_add_fab')));
      await tester.pumpAndSettle();

      expect(permissions.ensureCalls, 1);
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
