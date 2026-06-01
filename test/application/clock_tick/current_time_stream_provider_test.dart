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

    test('a throwing clock tick is skipped — stream keeps ticking, never '
        'enters a sticky error state (Review #3)', () {
      final DateTime base = DateTime.utc(2026, 5, 9, 12);
      int calls = 0;
      fakeAsync((FakeAsync async) {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            clockProvider.overrideWithValue(
              Clock(() {
                calls++;
                // call 1 = initial add, call 2 = +1s tick, call 3 = +2s tick.
                // Throw on the +2s tick to simulate a transient clock failure.
                // An Exception (not an Error) is the runtime-condition kind
                // the production guard is meant to absorb.
                if (calls == 3) throw Exception('transient clock failure');
                return base.add(async.elapsed);
              }),
            ),
          ],
        );
        addTearDown(container.dispose);

        final List<DateTime> emitted = <DateTime>[];
        bool sawError = false;
        final ProviderSubscription<AsyncValue<DateTime>> sub = container.listen(
          currentTimeProvider,
          (AsyncValue<DateTime>? _, AsyncValue<DateTime> next) {
            // Track every emission, not just the final state, so a brief
            // AsyncError that recovers on the next tick is still caught.
            if (next.hasError) sawError = true;
            final DateTime? value = next.valueOrNull;
            if (value != null) emitted.add(value);
          },
          fireImmediately: true,
        );
        addTearDown(sub.close);

        async.flushMicrotasks();
        expect(emitted, hasLength(1)); // initial tick

        async.elapse(const Duration(seconds: 3));
        // +1s ok, +2s throws (skipped — no emission, no error), +3s ok.
        expect(emitted, <DateTime>[
          base,
          base.add(const Duration(seconds: 1)),
          base.add(const Duration(seconds: 3)),
        ]);
        // The provider must never surface an error — not even transiently —
        // because that is what would freeze the world-clock display.
        expect(
          sawError,
          isFalse,
          reason: 'no emission may carry an AsyncError, even briefly',
        );
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
