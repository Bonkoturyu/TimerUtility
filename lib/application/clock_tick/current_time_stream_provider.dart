import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../clock_provider.dart';

part 'current_time_stream_provider.g.dart';

/// 1-second cadence stream of "now" used by the world-clock screen
/// (Phase 10.5). Implemented as a function-form `@riverpod` so it
/// auto-disposes when no listeners are attached: a clock screen that
/// is no longer in the foreground stops emitting.
///
/// Initial value is emitted synchronously on subscribe (via
/// `Stream.multi`) so the UI never has to render a frame with the
/// "no value yet" placeholder. Subsequent emissions come from a
/// `Timer.periodic` that runs through `clockProvider` so unit tests
/// can advance time deterministically with `fake_async`.
@riverpod
Stream<DateTime> currentTime(Ref ref) {
  final Clock clock = ref.watch(clockProvider);
  return Stream<DateTime>.multi((MultiStreamController<DateTime> controller) {
    // Skip a transient `clock.now()` failure instead of letting it surface
    // as a stream error: an `AsyncError` here is sticky, so `ClockPage`
    // would stop rebuilding and the world clock would freeze on the last
    // value until a new emission. Dropping the bad tick keeps the stream
    // alive so the next tick recovers. Both the synchronous initial emit
    // and the periodic ticks go through this guard (Review #3).
    //
    // Only `Exception` is swallowed — an `Error` (e.g. a `TypeError` from a
    // programming bug) still propagates so it is not silently hidden. In
    // practice `clock.now()` (pure Dart, no platform boundary) throws
    // neither, so this is purely defensive.
    void emitNow() {
      try {
        controller.add(clock.now());
      } on Exception catch (_) {
        // Next periodic tick re-reads the clock.
      }
    }

    emitNow();
    final Timer timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer _) => emitNow(),
    );
    controller.onCancel = () {
      timer.cancel();
    };
  });
}
