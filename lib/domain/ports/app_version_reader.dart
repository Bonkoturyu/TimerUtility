/// The app's own version, as reported by the packaging layer.
///
/// Kept in the domain so the display format lives next to the data and
/// stays testable as Pure Dart. `version` maps to Android's
/// `versionName` (`1.0.0`), `buildNumber` to `versionCode` (`2`) — the
/// two halves of pubspec's `version: 1.0.0+2`.
class AppVersion {
  const AppVersion({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  /// `1.0.0 (2)`. Falls back to the bare version when the build number
  /// is unavailable — some platforms report an empty string rather than
  /// failing, and `1.0.0 ()` would look like a bug to the user.
  String get display =>
      buildNumber.isEmpty ? version : '$version ($buildNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersion &&
          other.version == version &&
          other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(version, buildNumber);

  @override
  String toString() => 'AppVersion($display)';
}

/// Port for reading [AppVersion]. Implementations live under
/// `infrastructure/platform/` and wrap the packaging plugin.
///
/// Exists so the settings screen can be widget-tested without the
/// plugin's platform channel: override `appVersionReaderProvider` with
/// a stub instead.
abstract class AppVersionReader {
  Future<AppVersion> read();
}
