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
    controller.add(clock.now());
    final Timer timer = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      controller.add(clock.now());
    });
    controller.onCancel = () {
      timer.cancel();
    };
  });
}
