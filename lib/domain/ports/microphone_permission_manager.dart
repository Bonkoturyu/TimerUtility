import 'permission_manager.dart';

/// Permission boundary dedicated to optional on-device voice commands.
abstract interface class MicrophonePermissionManager {
  Future<DomainPermissionStatus> check();
  Future<DomainPermissionStatus> request();
  Future<bool> openAppSettings();
}
