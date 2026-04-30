import 'package:flutter/services.dart';

/// Wraps the `com.bonkotu.timer/permission` MethodChannel.
///
/// Used for permissions that `permission_handler` does not cover, currently
/// `USE_FULL_SCREEN_INTENT`. Channel spec: docs/platform-channels.md
class PermissionChannel {
  PermissionChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'com.bonkotu.timer/permission';

  final MethodChannel _channel;

  /// Returns whether the app may fire a full-screen intent. Backed by
  /// `NotificationManager.canUseFullScreenIntent()` (API 34+); on older
  /// versions the Native side returns `true` since the OS auto-grants the
  /// permission.
  Future<bool> canUseFullScreenIntent() async {
    final bool? result = await _channel.invokeMethod<bool>(
      'canUseFullScreenIntent',
    );
    return result ?? false;
  }

  /// Opens the OS settings screen so the user can grant
  /// `USE_FULL_SCREEN_INTENT`.
  Future<void> openFullScreenIntentSettings() async {
    await _channel.invokeMethod<void>('openFullScreenIntentSettings');
  }
}
