import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/keyguard_override_controller.dart';
import '../infrastructure/platform/method_channel_keyguard_override_controller.dart';

part 'keyguard_override_controller_provider.g.dart';

/// Default-bound [KeyguardOverrideController]. Override in tests via
/// `keyguardOverrideControllerProvider.overrideWithValue(...)`.
///
/// Used by [AlarmRingingScreen] to release the keyguard-override state
/// (set by Android when the screen was launched via FullScreenIntent) when
/// the user leaves the alarm screen — keeps the Presentation layer off the
/// raw MethodChannel (Issue #73). Sibling of [screenLockQueryProvider].
@Riverpod(keepAlive: true)
KeyguardOverrideController keyguardOverrideController(Ref ref) =>
    MethodChannelKeyguardOverrideController();
