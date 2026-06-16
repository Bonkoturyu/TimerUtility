import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';

class _StubPermissionManager implements PermissionManager {
  _StubPermissionManager({
    this.notificationStatus = DomainPermissionStatus.unknown,
    this.exactAlarmStatus = DomainPermissionStatus.unknown,
    this.fullScreenIntentStatus = DomainPermissionStatus.unknown,
    DomainPermissionStatus? notificationAfterRequest,
    DomainPermissionStatus? exactAlarmAfterRequest,
  }) : notificationAfterRequest =
           notificationAfterRequest ?? notificationStatus,
       exactAlarmAfterRequest = exactAlarmAfterRequest ?? exactAlarmStatus;

  DomainPermissionStatus notificationStatus;
  DomainPermissionStatus exactAlarmStatus;
  DomainPermissionStatus fullScreenIntentStatus;
  DomainPermissionStatus notificationAfterRequest;
  DomainPermissionStatus exactAlarmAfterRequest;

  int requestNotificationCalls = 0;
  int requestExactAlarmCalls = 0;
  int openFullScreenIntentSettingsCalls = 0;
  int openAppSettingsCalls = 0;

  @override
  Future<DomainPermissionStatus> checkNotification() async =>
      notificationStatus;

  @override
  Future<DomainPermissionStatus> requestNotification() async {
    requestNotificationCalls++;
    notificationStatus = notificationAfterRequest;
    return notificationStatus;
  }

  @override
  Future<DomainPermissionStatus> checkScheduleExactAlarm() async =>
      exactAlarmStatus;

  @override
  Future<DomainPermissionStatus> requestScheduleExactAlarm() async {
    requestExactAlarmCalls++;
    exactAlarmStatus = exactAlarmAfterRequest;
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
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return true;
  }
}

ProviderContainer _container(PermissionManager pm) {
  final c = ProviderContainer(
    overrides: <Override>[permissionManagerProvider.overrideWithValue(pm)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('PermissionNotifier', () {
    test('initial state is unknown for all permissions', () {
      final c = _container(_StubPermissionManager());

      final state = c.read(permissionNotifierProvider);
      expect(state.postNotifications, DomainPermissionStatus.unknown);
      expect(state.scheduleExactAlarm, DomainPermissionStatus.unknown);
      expect(state.fullScreenIntent, DomainPermissionStatus.unknown);
    });

    test('refresh reads all three statuses from the manager', () async {
      final pm = _StubPermissionManager(
        notificationStatus: DomainPermissionStatus.granted,
        exactAlarmStatus: DomainPermissionStatus.denied,
        fullScreenIntentStatus: DomainPermissionStatus.permanentlyDenied,
      );
      final c = _container(pm);

      await c.read(permissionNotifierProvider.notifier).refresh();

      final state = c.read(permissionNotifierProvider);
      expect(state.postNotifications, DomainPermissionStatus.granted);
      expect(state.scheduleExactAlarm, DomainPermissionStatus.denied);
      expect(state.fullScreenIntent, DomainPermissionStatus.permanentlyDenied);
    });

    test('requestNotification updates only the notification field', () async {
      final pm = _StubPermissionManager(
        notificationStatus: DomainPermissionStatus.denied,
        notificationAfterRequest: DomainPermissionStatus.granted,
        exactAlarmStatus: DomainPermissionStatus.denied,
      );
      final c = _container(pm);

      await c.read(permissionNotifierProvider.notifier).requestNotification();

      final state = c.read(permissionNotifierProvider);
      expect(state.postNotifications, DomainPermissionStatus.granted);
      expect(state.scheduleExactAlarm, DomainPermissionStatus.unknown);
      expect(state.fullScreenIntent, DomainPermissionStatus.unknown);
      expect(pm.requestNotificationCalls, 1);
    });

    test(
      'requestScheduleExactAlarm updates only the exact alarm field',
      () async {
        final pm = _StubPermissionManager(
          exactAlarmStatus: DomainPermissionStatus.denied,
          exactAlarmAfterRequest: DomainPermissionStatus.granted,
        );
        final c = _container(pm);

        await c
            .read(permissionNotifierProvider.notifier)
            .requestScheduleExactAlarm();

        final state = c.read(permissionNotifierProvider);
        expect(state.scheduleExactAlarm, DomainPermissionStatus.granted);
        expect(state.postNotifications, DomainPermissionStatus.unknown);
        expect(state.fullScreenIntent, DomainPermissionStatus.unknown);
        expect(pm.requestExactAlarmCalls, 1);
      },
    );

    test('openFullScreenIntentSettings delegates to the manager', () async {
      final pm = _StubPermissionManager();
      final c = _container(pm);

      await c
          .read(permissionNotifierProvider.notifier)
          .openFullScreenIntentSettings();

      expect(pm.openFullScreenIntentSettingsCalls, 1);
    });

    test('openSettings delegates to the manager', () async {
      final pm = _StubPermissionManager();
      final c = _container(pm);

      final opened = await c
          .read(permissionNotifierProvider.notifier)
          .openSettings();

      expect(opened, isTrue);
      expect(pm.openAppSettingsCalls, 1);
    });

    test(
      'ensureNotificationPermissionForScheduling refreshes unknown then requests',
      () async {
        final pm = _StubPermissionManager(
          notificationStatus: DomainPermissionStatus.unknown,
          notificationAfterRequest: DomainPermissionStatus.denied,
        );
        final c = _container(pm);

        await c
            .read(permissionNotifierProvider.notifier)
            .ensureNotificationPermissionForScheduling();

        expect(pm.requestNotificationCalls, 1);
        expect(
          c.read(permissionNotifierProvider).postNotifications,
          DomainPermissionStatus.denied,
        );
      },
    );

    test(
      'ensureNotificationPermissionForScheduling requests denied status',
      () async {
        final pm = _StubPermissionManager(
          notificationStatus: DomainPermissionStatus.denied,
          notificationAfterRequest: DomainPermissionStatus.granted,
        );
        final c = _container(pm);
        await c.read(permissionNotifierProvider.notifier).refresh();

        await c
            .read(permissionNotifierProvider.notifier)
            .ensureNotificationPermissionForScheduling();

        expect(pm.requestNotificationCalls, 1);
        expect(
          c.read(permissionNotifierProvider).postNotifications,
          DomainPermissionStatus.granted,
        );
      },
    );

    test(
      'ensureNotificationPermissionForScheduling does not request non-requestable statuses',
      () async {
        for (final status in <DomainPermissionStatus>[
          DomainPermissionStatus.granted,
          DomainPermissionStatus.permanentlyDenied,
          DomainPermissionStatus.notRequired,
        ]) {
          final pm = _StubPermissionManager(notificationStatus: status);
          final c = _container(pm);
          await c.read(permissionNotifierProvider.notifier).refresh();

          await c
              .read(permissionNotifierProvider.notifier)
              .ensureNotificationPermissionForScheduling();

          expect(pm.requestNotificationCalls, 0);
        }
      },
    );
  });
}
