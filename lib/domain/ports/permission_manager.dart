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

  /// USE_FULL_SCREEN_INTENT の許可状態。`permission_handler` ではカバーされず、
  /// Native MethodChannel 経由で `NotificationManager.canUseFullScreenIntent()`
  /// を読む。Android 14 (API 34) 未満では OS が自動付与するため granted を返す。
  Future<DomainPermissionStatus> checkFullScreenIntent();

  /// USE_FULL_SCREEN_INTENT の設定画面を開く。Android 14+ では
  /// `Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`、それ未満ではアプリ
  /// 詳細画面にフォールバック。granted/denied は戻らないので、呼び出し側は
  /// アプリ復帰時に [checkFullScreenIntent] を再実行して状態を取り直す。
  Future<void> openFullScreenIntentSettings();

  /// Open the OS app-settings screen so the user can grant permanently
  /// denied permissions manually. Returns whether the screen was opened.
  Future<bool> openAppSettings();
}
