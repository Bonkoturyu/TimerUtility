import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/timer/timer_service.dart';
import 'clock_provider.dart';

part 'timer_service_provider.g.dart';

/// Default-bound [TimerService] wired with the application [Clock].
///
/// Extracted from the Phase 3 `timer_notifier.dart` so the service can
/// outlive the deprecated single-timer notifier and be shared by the
/// Phase 8 [TimerCollectionNotifier] and any future preset / alarm
/// flows that need to drive [TimerEntity] state transitions.
@Riverpod(keepAlive: true)
TimerService timerService(Ref ref) =>
    TimerService(clock: ref.watch(clockProvider));
