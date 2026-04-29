import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Application-wide [Clock] instance.
///
/// Override in tests via `clockProvider.overrideWithValue(Clock.fixed(...))`.
/// Domain code receives this through constructor injection (e.g. via
/// `stopwatchServiceProvider`); it must never call `DateTime.now()` directly.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const Clock();
