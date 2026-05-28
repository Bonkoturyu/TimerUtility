import 'package:flutter/services.dart';

import '../../domain/ports/screen_lock_query.dart';
import 'permission_channel.dart';

/// Calls `MainActivity.isScreenLockedInternal()` via the existing
/// `io.github.bonkoturyu.timer_utility/permission` MethodChannel. Spec:
/// docs/platform-channels.md.
///
/// Channel errors and unexpected return types fall back to `false`
/// (= treat as unlocked → applies the short 500 ms delay, matching
/// the foreground path). Issue #74.
class MethodChannelScreenLockQuery implements ScreenLockQuery {
  MethodChannelScreenLockQuery({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(PermissionChannel.channelName);

  final MethodChannel _channel;

  @override
  Future<bool> isScreenLocked() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isScreenLocked');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
