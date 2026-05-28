import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/screen_lock_query.dart';
import '../infrastructure/platform/method_channel_screen_lock_query.dart';

part 'screen_lock_query_provider.g.dart';

/// Default-bound [ScreenLockQuery]. Override in tests via
/// `screenLockQueryProvider.overrideWithValue(StubScreenLockQuery(...))`.
///
/// Used by [AlarmRingingNotifier.start] (Issue #74 fix) to pick the
/// cancel→play delay based on whether the keyguard is currently up.
@Riverpod(keepAlive: true)
ScreenLockQuery screenLockQuery(Ref ref) => MethodChannelScreenLockQuery();
