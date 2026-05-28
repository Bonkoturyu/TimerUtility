import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/ports/permission_manager.dart';
import '../platform/permission_channel.dart';

/// Concrete [PermissionManager] backed by `permission_handler` and, for
/// permissions outside its scope (USE_FULL_SCREEN_INTENT), the
/// `io.github.bonkoturyu.timer_utility/permission` MethodChannel.
class PermissionHandlerAdapter implements PermissionManager {
  PermissionHandlerAdapter({PermissionChannel? channel})
    : _channel = channel ?? PermissionChannel();

  final PermissionChannel _channel;

  @override
  Future<DomainPermissionStatus> checkNotification() async {
    return _toDomain(await ph.Permission.notification.status);
  }

  @override
  Future<DomainPermissionStatus> requestNotification() async {
    return _toDomain(await ph.Permission.notification.request());
  }

  @override
  Future<DomainPermissionStatus> checkScheduleExactAlarm() async {
    return _toDomain(await ph.Permission.scheduleExactAlarm.status);
  }

  @override
  Future<DomainPermissionStatus> requestScheduleExactAlarm() async {
    return _toDomain(await ph.Permission.scheduleExactAlarm.request());
  }

  @override
  Future<DomainPermissionStatus> checkFullScreenIntent() async {
    try {
      final bool canUse = await _channel.canUseFullScreenIntent();
      return canUse
          ? DomainPermissionStatus.granted
          : DomainPermissionStatus.denied;
    } on PlatformException {
      return DomainPermissionStatus.unknown;
    }
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    try {
      await _channel.openFullScreenIntentSettings();
    } on PlatformException {
      // Best-effort; if the settings activity can't be resolved we silently
      // give up. The caller will see the same state on the next refresh.
    }
  }

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();

  DomainPermissionStatus _toDomain(ph.PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return DomainPermissionStatus.granted;
    }
    if (s.isPermanentlyDenied) {
      return DomainPermissionStatus.permanentlyDenied;
    }
    if (s.isRestricted) {
      return DomainPermissionStatus.permanentlyDenied;
    }
    if (s.isDenied) {
      return DomainPermissionStatus.denied;
    }
    return DomainPermissionStatus.unknown;
  }
}
