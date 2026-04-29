import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/stopwatch/stopwatch_service.dart';
import '../domain/stopwatch/stopwatch_state.dart';
import 'clock_provider.dart';

part 'stopwatch_notifier.g.dart';

/// Stopwatch domain service wired with the application [Clock].
@Riverpod(keepAlive: true)
StopwatchService stopwatchService(Ref ref) =>
    StopwatchService(clock: ref.watch(clockProvider));

/// Stopwatch state holder.
///
/// The displayed elapsed value should be derived from the *current* clock
/// each frame; this notifier only tracks discrete transitions (start, pause,
/// resume, lap, reset). The absolute-time design (`startedAt` + `clock.now()`)
/// makes the value naturally correct after the app returns from background,
/// so no `AppLifecycleListener` plumbing is required at this layer.
@Riverpod(keepAlive: true)
class StopwatchNotifier extends _$StopwatchNotifier {
  @override
  StopwatchState build() => const StopwatchState.idle();

  void start() {
    state = ref.read(stopwatchServiceProvider).start();
  }

  void pause() {
    state = ref.read(stopwatchServiceProvider).pause(state);
  }

  void resume() {
    state = ref.read(stopwatchServiceProvider).resume(state);
  }

  void lap() {
    state = ref.read(stopwatchServiceProvider).lap(state);
  }

  void reset() {
    state = ref.read(stopwatchServiceProvider).reset();
  }

  /// Convenience: current elapsed time using the latest clock.
  Duration get elapsed => ref.read(stopwatchServiceProvider).elapsed(state);
}

// NOTE: Display ticks are driven by a Timer inside StopwatchScreen
// (ConsumerStatefulWidget) so that the timer is cancelled on dispose.
// A StreamProvider-based ticker had trouble deterministically tearing
// down its internal periodic timer in tests.
