import 'package:flutter/services.dart';

import '../../domain/ports/keyguard_override_controller.dart';
import 'permission_channel.dart';

/// Calls `MainActivity.clearShowWhenLockedInternal()` via the existing
/// `io.github.bonkoturyu.timer_utility/permission` MethodChannel. Spec:
/// docs/platform-channels.md.
///
/// All platform errors are swallowed: clearing the override is best-effort
/// (it only governs the recents (■) button visibility after the alarm is
/// dismissed, not the alarm itself), and this runs on the leave-alarm-screen
/// path where a thrown `PlatformException` / `MissingPluginException` would
/// be noise. Mirrors [MethodChannelScreenLockQuery]'s catch-all rationale
/// (Issue #73 / Issue #74).
class MethodChannelKeyguardOverrideController
    implements KeyguardOverrideController {
  MethodChannelKeyguardOverrideController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(PermissionChannel.channelName);

  final MethodChannel _channel;

  @override
  Future<void> clearShowWhenLocked() async {
    try {
      await _channel.invokeMethod<void>('clearShowWhenLocked');
    } catch (_) {
      // Best-effort — see class doc. Swallow every error so the
      // leave-alarm-screen path never surfaces a platform exception.
    }
  }
}
