import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/timer/timer_entity.dart';
import '../domain/timer/timer_service.dart';
import '../domain/timer/timer_status.dart';
import 'clock_provider.dart';

part 'timer_notifier.g.dart';

/// Timer domain service wired with the application [Clock].
@Riverpod(keepAlive: true)
TimerService timerService(Ref ref) =>
    TimerService(clock: ref.watch(clockProvider));

/// Single-timer state holder for Phase 3.
///
/// State `null` means "no timer configured yet" (initial app state).
/// While a timer is `running`, an internal 200ms ticker calls
/// `TimerService.tick` to detect when `endAt` is reached and transition
/// to `ringing`. The ticker also covers the "returned from background"
/// case naturally: a single tick after resume re-checks `endAt` against
/// the current clock and flips to `ringing` immediately if the deadline
/// has already passed.
@Riverpod(keepAlive: true)
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;

  @override
  TimerEntity? build() {
    ref.onDispose(_stopTicker);
    return null;
  }

  /// Configure a brand new timer (state goes from null/anything to idle).
  void create({required String label, required Duration duration}) {
    _stopTicker();
    state = ref
        .read(timerServiceProvider)
        .createIdle(label: label, duration: duration);
  }

  void start() {
    final current = _requireState('start');
    state = ref.read(timerServiceProvider).start(current);
    _startTicker();
  }

  void pause() {
    final current = _requireState('pause');
    state = ref.read(timerServiceProvider).pause(current);
    _stopTicker();
  }

  void resume() {
    final current = _requireState('resume');
    state = ref.read(timerServiceProvider).resume(current);
    _startTicker();
  }

  void cancel() {
    final current = state;
    if (current == null) {
      return;
    }
    state = ref.read(timerServiceProvider).cancel(current);
    _stopTicker();
  }

  void reset() {
    final current = _requireState('reset');
    state = ref.read(timerServiceProvider).reset(current);
    _stopTicker();
  }

  /// Drop the currently configured timer (returns to the "no timer" state).
  void clear() {
    _stopTicker();
    state = null;
  }

  TimerEntity _requireState(String op) {
    final current = state;
    if (current == null) {
      throw StateError('No timer to $op');
    }
    return current;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onTick(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    final current = state;
    if (current == null || current.status != TimerStatus.running) {
      _stopTicker();
      return;
    }
    final next = ref.read(timerServiceProvider).tick(current);
    if (!identical(next, current)) {
      state = next;
      if (next.status != TimerStatus.running) {
        _stopTicker();
      }
    }
  }
}
