import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/diagnostics/diagnostic_event.dart';
import '../domain/ports/permission_manager.dart';
import '../infrastructure/permission/permission_handler_adapter.dart';
import 'clock_provider.dart';
import 'diagnostic_logger_provider.dart';

part 'permission_notifier.freezed.dart';
part 'permission_notifier.g.dart';

@freezed
class PermissionState with _$PermissionState {
  const factory PermissionState({
    required DomainPermissionStatus postNotifications,
    required DomainPermissionStatus scheduleExactAlarm,
    required DomainPermissionStatus fullScreenIntent,
  }) = _PermissionState;

  factory PermissionState.unknown() => const PermissionState(
    postNotifications: DomainPermissionStatus.unknown,
    scheduleExactAlarm: DomainPermissionStatus.unknown,
    fullScreenIntent: DomainPermissionStatus.unknown,
  );
}

/// Default-bound permission manager. Override in tests via
/// `permissionManagerProvider.overrideWithValue(fakePermissionManager)`.
@Riverpod(keepAlive: true)
PermissionManager permissionManager(Ref ref) => PermissionHandlerAdapter();

/// Holds the latest known permission state and exposes request actions.
@Riverpod(keepAlive: true)
class PermissionNotifier extends _$PermissionNotifier {
  @override
  PermissionState build() => PermissionState.unknown();

  Future<void> refresh() async {
    final manager = ref.read(permissionManagerProvider);
    final PermissionState before = state;
    final post = await manager.checkNotification();
    final exact = await manager.checkScheduleExactAlarm();
    final fsi = await manager.checkFullScreenIntent();
    final PermissionState next = PermissionState(
      postNotifications: post,
      scheduleExactAlarm: exact,
      fullScreenIntent: fsi,
    );
    state = next;
    _logTransition(
      PermissionKind.postNotifications,
      before.postNotifications,
      next.postNotifications,
    );
    _logTransition(
      PermissionKind.scheduleExactAlarm,
      before.scheduleExactAlarm,
      next.scheduleExactAlarm,
    );
    _logTransition(
      PermissionKind.fullScreenIntent,
      before.fullScreenIntent,
      next.fullScreenIntent,
    );
  }

  Future<void> requestNotification() async {
    final manager = ref.read(permissionManagerProvider);
    final DomainPermissionStatus before = state.postNotifications;
    final next = await manager.requestNotification();
    state = state.copyWith(postNotifications: next);
    _logTransition(PermissionKind.postNotifications, before, next);
  }

  /// Make sure the notification permission prompt has had a chance to appear
  /// before the user creates timer/alarm work that depends on OS notifications.
  ///
  /// Denial is not treated as an error: timers and alarms still work while the
  /// app is foregrounded, and [PermissionBanners] keeps surfacing the degraded
  /// background behavior.
  Future<void> ensureNotificationPermissionForScheduling() async {
    if (state.postNotifications == DomainPermissionStatus.unknown) {
      await refresh();
    }
    final status = state.postNotifications;
    if (status == DomainPermissionStatus.unknown ||
        status == DomainPermissionStatus.denied) {
      await requestNotification();
    }
  }

  Future<void> requestScheduleExactAlarm() async {
    final manager = ref.read(permissionManagerProvider);
    final DomainPermissionStatus before = state.scheduleExactAlarm;
    final next = await manager.requestScheduleExactAlarm();
    state = state.copyWith(scheduleExactAlarm: next);
    _logTransition(PermissionKind.scheduleExactAlarm, before, next);
  }

  /// Opens the OS settings page for USE_FULL_SCREEN_INTENT. The status is
  /// not returned synchronously; callers should call [refresh] when the app
  /// regains focus to pick up the user's choice.
  Future<void> openFullScreenIntentSettings() async {
    final manager = ref.read(permissionManagerProvider);
    await manager.openFullScreenIntentSettings();
  }

  Future<bool> openSettings() async {
    final manager = ref.read(permissionManagerProvider);
    return manager.openAppSettings();
  }

  /// Emit a permission-transition diagnostic only when `before != after`
  /// so repeated `refresh()` calls (lifecycle resume etc.) don't spam
  /// no-op transitions into the log file.
  void _logTransition(
    PermissionKind kind,
    DomainPermissionStatus before,
    DomainPermissionStatus after,
  ) {
    if (before == after) return;
    ref
        .read(diagnosticLoggerProvider)
        .log(
          DiagnosticEvent.permissionTransition(
            occurredAt: ref.read(clockProvider).now(),
            permissionKind: kind,
            before: before,
            after: after,
          ),
        );
  }
}
