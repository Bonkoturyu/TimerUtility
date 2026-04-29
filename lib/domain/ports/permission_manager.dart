/// Domain-level representation of an OS permission state. Adapters map
/// platform-specific status enums to this set so the domain layer never
/// imports `permission_handler` etc.
enum DomainPermissionStatus {
  /// Permission is granted.
  granted,

  /// Permission has been denied but can be requested again.
  denied,

  /// Permission has been permanently denied; the user must open settings.
  permanentlyDenied,

  /// The permission is not required on this OS version (treat as granted).
  notRequired,

  /// State has not been queried yet.
  unknown,
}

/// Port for OS permission management.
///
/// Implementations live under `infrastructure/permission/` and wrap
/// `permission_handler` (and any other native permission APIs).
abstract class PermissionManager {
  Future<DomainPermissionStatus> checkNotification();
  Future<DomainPermissionStatus> requestNotification();

  Future<DomainPermissionStatus> checkScheduleExactAlarm();
  Future<DomainPermissionStatus> requestScheduleExactAlarm();

  /// Open the OS app-settings screen so the user can grant permanently
  /// denied permissions manually. Returns whether the screen was opened.
  Future<bool> openAppSettings();
}
