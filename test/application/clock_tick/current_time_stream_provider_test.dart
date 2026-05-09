import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/clock_tick/current_time_stream_provider.dart';

void main() {
  group('currentTimeStreamProvider', () {
    test('emits the initial tick synchronously and then once per second', () {
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
        addTearDown(sub.close);

        async.flushMicrotasks();
        // Initial tick from Stream.multi
        expect(emitted, hasLength(1));

        async.elapse(const Duration(seconds: 5));
        // 1 initial + 5 periodic ticks
        expect(emitted, hasLength(6));
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
        sub.close();
        async.elapse(const Duration(seconds: 5));
        expect(emitted, hasLength(3));
      });
    });
  });
}
