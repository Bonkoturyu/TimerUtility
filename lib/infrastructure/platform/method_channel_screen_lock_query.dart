import 'package:flutter/services.dart';

import '../../domain/ports/screen_lock_query.dart';
import 'permission_channel.dart';

/// Calls `MainActivity.isScreenLockedInternal()` via the existing
/// `io.github.bonkoturyu.timer_utility/permission` MethodChannel. Spec:
/// docs/platform-channels.md.
///
/// Any error — `PlatformException`, `MissingPluginException`, a `TypeError`
/// from `invokeMethod<bool>` returning a non-bool, or anything else —
/// falls back to `false` (= treat as unlocked → applies the short 500 ms
/// delay, matching the foreground path). This catch-all is intentional
/// because [AlarmRingingNotifier.start] is on the alarm-ring critical
/// path: an uncaught exception here would silence the alarm entirely
/// (PR #75 / Gemini + Copilot review). Issue #74.
class MethodChannelScreenLockQuery implements ScreenLockQuery {
  MethodChannelScreenLockQuery({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(PermissionChannel.channelName);

  final MethodChannel _channel;

  @override
  Future<bool> isScreenLocked() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isScreenLocked');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
