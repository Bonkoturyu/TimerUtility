import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/permission_manager.dart';
import '../infrastructure/permission/permission_handler_adapter.dart';

part 'permission_notifier.freezed.dart';
part 'permission_notifier.g.dart';

@freezed
class PermissionState with _$PermissionState {
  const factory PermissionState({
    required DomainPermissionStatus postNotifications,
    required DomainPermissionStatus scheduleExactAlarm,
  }) = _PermissionState;

  factory PermissionState.unknown() => const PermissionState(
    postNotifications: DomainPermissionStatus.unknown,
    scheduleExactAlarm: DomainPermissionStatus.unknown,
  );
}

/// Default-bound permission manager. Override in tests via
/// `permissionManagerProvider.overrideWithValue(fakePermissionManager)`.
@Riverpod(keepAlive: true)
PermissionManager permissionManager(Ref ref) =>
    const PermissionHandlerAdapter();

/// Holds the latest known permission state and exposes request actions.
@Riverpod(keepAlive: true)
class PermissionNotifier extends _$PermissionNotifier {
  @override
  PermissionState build() => PermissionState.unknown();

  Future<void> refresh() async {
    final manager = ref.read(permissionManagerProvider);
    final post = await manager.checkNotification();
    final exact = await manager.checkScheduleExactAlarm();
    state = PermissionState(postNotifications: post, scheduleExactAlarm: exact);
  }

  Future<void> requestNotification() async {
    final manager = ref.read(permissionManagerProvider);
    final next = await manager.requestNotification();
    state = state.copyWith(postNotifications: next);
  }

  Future<void> requestScheduleExactAlarm() async {
    final manager = ref.read(permissionManagerProvider);
    final next = await manager.requestScheduleExactAlarm();
    state = state.copyWith(scheduleExactAlarm: next);
  }

  Future<bool> openSettings() async {
    final manager = ref.read(permissionManagerProvider);
    return manager.openAppSettings();
  }
}
