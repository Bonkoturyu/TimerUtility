import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/clock_tick/current_time_stream_provider.dart';

void main() {
  group('currentTimeStreamProvider', () {
    test('emits the initial tick synchronously and then once per second', () {
      // Inject a clock that follows the FakeAsync virtual clock so we
      // can assert on the absolute emitted DateTime values, not just
      // their count.
      final DateTime base = DateTime.utc(2026, 5, 9, 12);
      fakeAsync((FakeAsync async) {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            clockProvider.overrideWithValue(
              Clock(() => base.add(async.elapsed)),
            ),
          ],
        );
        addTearDown(container.dispose);
        final List<DateTime> emitted = <DateTime>[];
        final ProviderSubscription<AsyncValue<DateTime>> sub = container.listen(
          currentTimeProvider,
          (AsyncValue<DateTime>? _, AsyncValue<DateTime> next) {
            final DateTime? value = next.valueOrNull;
            if (value != null) emitted.add(value);
          },
          fireImmediately: true,
        );
        addTearDown(sub.close);

        async.flushMicrotasks();
        // Initial tick from Stream.multi
        expect(emitted, hasLength(1));
        expect(emitted[0], base);

        async.elapse(const Duration(seconds: 5));
        // 1 initial + 5 periodic ticks at exactly +1s each.
        expect(emitted, hasLength(6));
        for (int i = 0; i < emitted.length; i++) {
          expect(
            emitted[i],
            base.add(Duration(seconds: i)),
            reason: 'tick $i must be base + ${i}s',
          );
        }
      });
    });

    test('autoDisposes when the last listener detaches (no further ticks)', () {
      fakeAsync((FakeAsync async) {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[clockProvider.overrideWithValue(const Clock())],
        );
        addTearDown(container.dispose);
        final List<DateTime> emitted = <DateTime>[];
        final ProviderSubscription<AsyncValue<DateTime>> sub = container.listen(
          currentTimeProvider,
          (AsyncValue<DateTime>? _, AsyncValue<DateTime> next) {
            final DateTime? value = next.valueOrNull;
            if (value != null) emitted.add(value);
          },
          fireImmediately: true,
        );
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        expect(emitted, hasLength(3));
        // Periodic timer is registered while the provider is alive.
        expect(
          async.periodicTimerCount,
          greaterThanOrEqualTo(1),
          reason: 'Stream.multi should have a Timer.periodic running',
        );

        sub.close();
        // Riverpod's auto-dispose runs in a Future (not a microtask), so
        // we need to advance the virtual clock a hair to let it complete
        // before observing the Stream.onCancel side-effect. 1 ms is well
        // under the 1 s period, so this can't itself fire the timer.
        async.elapse(const Duration(milliseconds: 1));
        // Riverpod auto-dispose triggers the Stream onCancel which
        // cancels the periodic timer. Without this assertion, "no
        // further ticks" would just mean "no listener observed them" —
        // we want to prove the timer itself stopped.
        expect(
          async.periodicTimerCount,
          0,
          reason: 'Timer.periodic must be cancelled on auto-dispose',
        );

        async.elapse(const Duration(seconds: 5));
        expect(emitted, hasLength(3));
      });
    });
  });
}
