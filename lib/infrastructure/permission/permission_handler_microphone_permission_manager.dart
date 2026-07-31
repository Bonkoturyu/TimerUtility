import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/ports/microphone_permission_manager.dart';
import '../../domain/ports/permission_manager.dart';

class PermissionHandlerMicrophonePermissionManager
    implements MicrophonePermissionManager {
  @override
  Future<DomainPermissionStatus> check() async =>
      _toDomain(await ph.Permission.microphone.status);

  @override
  Future<DomainPermissionStatus> request() async =>
      _toDomain(await ph.Permission.microphone.request());

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();

  DomainPermissionStatus _toDomain(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return DomainPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return DomainPermissionStatus.permanentlyDenied;
    }
    if (status.isDenied) {
      return DomainPermissionStatus.denied;
    }
    return DomainPermissionStatus.unknown;
  }
}
