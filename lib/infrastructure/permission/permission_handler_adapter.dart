import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/ports/permission_manager.dart';

/// Concrete [PermissionManager] backed by `permission_handler`.
class PermissionHandlerAdapter implements PermissionManager {
  const PermissionHandlerAdapter();

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
