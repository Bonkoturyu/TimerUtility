import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/ports/app_version_reader.dart';

/// Reads the running build's `versionName` / `versionCode` through
/// `package_info_plus`.
///
/// Preferred over compiling pubspec's `version:` into a Dart constant
/// because the value then cannot drift from what the OS (and Play
/// Console) actually reports for the installed artifact.
///
/// Platform errors fall back to an empty [AppVersion] rather than
/// throwing: the version row is informational, and a failed read must
/// not break the settings screen. The empty display renders as a dash
/// on the presentation side.
class PackageInfoAppVersionReader implements AppVersionReader {
  const PackageInfoAppVersionReader({
    Future<PackageInfo> Function() loadPackageInfo = PackageInfo.fromPlatform,
  }) : _loadPackageInfo = loadPackageInfo;

  final Future<PackageInfo> Function() _loadPackageInfo;

  @override
  Future<AppVersion> read() async {
    try {
      final PackageInfo info = await _loadPackageInfo();
      return AppVersion(version: info.version, buildNumber: info.buildNumber);
    } catch (_) {
      return const AppVersion(version: '', buildNumber: '');
    }
  }
}
