import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';

class _StubPermissionManager implements PermissionManager {
  _StubPermissionManager({
    this.notificationStatus = DomainPermissionStatus.unknown,
    this.exactAlarmStatus = DomainPermissionStatus.unknown,
    DomainPermissionStatus? notificationAfterRequest,
    DomainPermissionStatus? exactAlarmAfterRequest,
  }) : notificationAfterRequest =
           notificationAfterRequest ?? notificationStatus,
       exactAlarmAfterRequest = exactAlarmAfterRequest ?? exactAlarmStatus;

  DomainPermissionStatus notificationStatus;
  DomainPermissionStatus exactAlarmStatus;
  DomainPermissionStatus notificationAfterRequest;
  DomainPermissionStatus exactAlarmAfterRequest;

  int requestNotificationCalls = 0;
  int requestExactAlarmCalls = 0;
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
    test('initial state is unknown for both permissions', () {
      final c = _container(_StubPermissionManager());

      final state = c.read(permissionNotifierProvider);
      expect(state.postNotifications, DomainPermissionStatus.unknown);
      expect(state.scheduleExactAlarm, DomainPermissionStatus.unknown);
    });

    test('refresh reads both statuses from the manager', () async {
      final pm = _StubPermissionManager(
        notificationStatus: DomainPermissionStatus.granted,
        exactAlarmStatus: DomainPermissionStatus.denied,
      );
      final c = _container(pm);

      await c.read(permissionNotifierProvider.notifier).refresh();

      final state = c.read(permissionNotifierProvider);
      expect(state.postNotifications, DomainPermissionStatus.granted);
      expect(state.scheduleExactAlarm, DomainPermissionStatus.denied);
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
        expect(pm.requestExactAlarmCalls, 1);
      },
    );

    test('openSettings delegates to the manager', () async {
      final pm = _StubPermissionManager();
      final c = _container(pm);

      final opened = await c
          .read(permissionNotifierProvider.notifier)
          .openSettings();

      expect(opened, isTrue);
      expect(pm.openAppSettingsCalls, 1);
    });
  });
}
