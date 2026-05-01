import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/timer_service.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

TimerService _service(_MutableNow holder, {String fixedId = 'test-id'}) {
  return TimerService(
    clock: Clock(() => holder.now),
    idGenerator: () => fixedId,
  );
}

void main() {
  group('TimerService.createIdle', () {
    test('creates an idle timer with provided values', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);

      final t = svc.createIdle(
        label: 'work',
        duration: const Duration(seconds: 30),
      );

      expect(t.id, 'test-id');
      expect(t.label, 'work');
      expect(t.duration, const Duration(seconds: 30));
      expect(t.endAt, isNull);
      expect(t.pausedRemaining, isNull);
      expect(t.status, TimerStatus.idle);
      expect(t.createdAt, DateTime(2026, 1, 1, 12));
    });

    test('assigns notificationId derived from the timer id', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now, fixedId: 'fixed-id-abc');

      final t = svc.createIdle(label: '', duration: const Duration(seconds: 5));

      // Same id → same notificationId, in 31-bit non-negative range.
      expect(t.notificationId, 'fixed-id-abc'.hashCode & 0x7FFFFFFF);
      expect(t.notificationId, greaterThanOrEqualTo(0));
      expect(t.notificationId, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('honors caller-supplied id and createdAt', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);

      final t = svc.createIdle(
        label: 'x',
        duration: const Duration(seconds: 5),
        id: 'custom',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(t.id, 'custom');
      expect(t.createdAt, DateTime(2025, 1, 1));
    });

    test('rejects zero duration', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final svc = _service(now);

      expect(
        () => svc.createIdle(label: 'x', duration: Duration.zero),
        throwsArgumentError,
      );
    });

    test('rejects negative duration', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final svc = _service(now);

      expect(
        () => svc.createIdle(label: 'x', duration: const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });

    test('rejects duration over 99 hours', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final svc = _service(now);

      expect(
        () => svc.createIdle(
          label: 'x',
          duration: const Duration(hours: 99, seconds: 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects label longer than 50 chars', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final svc = _service(now);

      expect(
        () => svc.createIdle(
          label: 'x' * 51,
          duration: const Duration(seconds: 1),
        ),
        throwsArgumentError,
      );
    });

    test('accepts empty label', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final svc = _service(now);

      expect(
        svc.createIdle(label: '', duration: const Duration(seconds: 1)).label,
        '',
      );
    });
  });

  group('TimerService.start', () {
    test('idle → running with endAt = now + duration', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final t = svc.createIdle(label: '', duration: const Duration(seconds: 5));

      final started = svc.start(t);

      expect(started.status, TimerStatus.running);
      expect(started.endAt, DateTime(2026, 1, 1, 12, 0, 5));
      expect(started.pausedRemaining, isNull);
    });

    test('paused → running uses pausedRemaining', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final paused = svc
          .createIdle(label: '', duration: const Duration(seconds: 10))
          .copyWith(
            status: TimerStatus.paused,
            pausedRemaining: const Duration(seconds: 3),
          );

      final restarted = svc.start(paused);

      expect(restarted.status, TimerStatus.running);
      expect(restarted.endAt, DateTime(2026, 1, 1, 12, 0, 3));
      expect(restarted.pausedRemaining, isNull);
    });

    test('ringing → running restarts with full duration', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final ringing = svc
          .createIdle(label: '', duration: const Duration(seconds: 5))
          .copyWith(status: TimerStatus.ringing);

      final restarted = svc.start(ringing);

      expect(restarted.status, TimerStatus.running);
      expect(restarted.endAt, DateTime(2026, 1, 1, 12, 0, 5));
    });

    test('completed → running restarts with full duration', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final completed = svc
          .createIdle(label: '', duration: const Duration(seconds: 5))
          .copyWith(status: TimerStatus.completed);

      final restarted = svc.start(completed);

      expect(restarted.status, TimerStatus.running);
      expect(restarted.endAt, DateTime(2026, 1, 1, 12, 0, 5));
    });

    test('running.start throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      expect(() => svc.start(running), throwsStateError);
    });

    test('cancelled.start throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final cancelled = svc.cancel(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      expect(() => svc.start(cancelled), throwsStateError);
    });
  });

  group('TimerService.pause', () {
    test('running → paused with computed remaining', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 10)),
      );

      now.now = DateTime(2026, 1, 1, 12, 0, 3);
      final paused = svc.pause(running);

      expect(paused.status, TimerStatus.paused);
      expect(paused.endAt, isNull);
      expect(paused.pausedRemaining, const Duration(seconds: 7));
    });

    test('clamps remaining to zero when called past endAt', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      now.now = DateTime(2026, 1, 1, 12, 0, 30);
      final paused = svc.pause(running);

      expect(paused.pausedRemaining, Duration.zero);
    });

    test('idle.pause throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );

      expect(() => svc.pause(idle), throwsStateError);
    });
  });

  group('TimerService.resume', () {
    test('paused → running using pausedRemaining', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 10)),
      );
      now.now = DateTime(2026, 1, 1, 12, 0, 4);
      final paused = svc.pause(running);

      now.now = DateTime(2026, 1, 1, 12, 0, 30);
      final resumed = svc.resume(paused);

      expect(resumed.status, TimerStatus.running);
      expect(resumed.endAt, DateTime(2026, 1, 1, 12, 0, 36));
      expect(resumed.pausedRemaining, isNull);
    });

    test('running.resume throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      expect(() => svc.resume(running), throwsStateError);
    });
  });

  group('TimerService.cancel', () {
    test('any non-cancelled state → cancelled', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );
      final running = svc.start(idle);

      expect(svc.cancel(idle).status, TimerStatus.cancelled);
      expect(svc.cancel(running).status, TimerStatus.cancelled);
    });

    test('cancelled.cancel is idempotent (returns same instance)', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final cancelled = svc.cancel(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      expect(svc.cancel(cancelled), same(cancelled));
    });
  });

  group('TimerService.tick', () {
    test('running with endAt past → ringing', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      now.now = DateTime(2026, 1, 1, 12, 0, 5);
      final ticked = svc.tick(running);

      expect(ticked.status, TimerStatus.ringing);
      expect(ticked.endAt, isNull);
    });

    test('running with endAt future → unchanged', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      now.now = DateTime(2026, 1, 1, 12, 0, 3);

      expect(svc.tick(running), same(running));
    });

    test('non-running tick returns same instance', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );

      expect(svc.tick(idle), same(idle));
    });
  });

  group('TimerService.reset', () {
    test('completed → idle preserves duration and id', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final completed = svc
          .createIdle(label: 'x', duration: const Duration(seconds: 5))
          .copyWith(status: TimerStatus.completed);

      final reset = svc.reset(completed);

      expect(reset.status, TimerStatus.idle);
      expect(reset.duration, const Duration(seconds: 5));
      expect(reset.endAt, isNull);
      expect(reset.pausedRemaining, isNull);
      expect(reset.id, completed.id);
    });

    test('cancelled → idle preserves duration', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final cancelled = svc.cancel(
        svc.createIdle(label: 'x', duration: const Duration(seconds: 5)),
      );

      expect(svc.reset(cancelled).status, TimerStatus.idle);
    });

    test('idle.reset throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );

      expect(() => svc.reset(idle), throwsStateError);
    });

    test('running.reset throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      expect(() => svc.reset(running), throwsStateError);
    });
  });

  group('TimerService.remaining', () {
    test('running returns endAt - now', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 10)),
      );

      now.now = DateTime(2026, 1, 1, 12, 0, 3);

      expect(svc.remaining(running), const Duration(seconds: 7));
    });

    test('running with endAt past returns zero', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      now.now = DateTime(2026, 1, 1, 12, 0, 30);

      expect(svc.remaining(running), Duration.zero);
    });

    test('paused returns pausedRemaining', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 10)),
      );
      now.now = DateTime(2026, 1, 1, 12, 0, 4);
      final paused = svc.pause(running);

      expect(svc.remaining(paused), const Duration(seconds: 6));
    });

    test('idle / ringing / completed / cancelled return zero', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );

      expect(svc.remaining(idle), Duration.zero);
      expect(
        svc.remaining(idle.copyWith(status: TimerStatus.ringing)),
        Duration.zero,
      );
      expect(
        svc.remaining(idle.copyWith(status: TimerStatus.completed)),
        Duration.zero,
      );
      expect(
        svc.remaining(idle.copyWith(status: TimerStatus.cancelled)),
        Duration.zero,
      );
    });
  });

  group('TimerService.snooze', () {
    test('ringing から 5 分スヌーズで running 化し endAt が now + 5 分になる', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final ringing = svc
          .createIdle(label: '', duration: const Duration(seconds: 5))
          .copyWith(status: TimerStatus.ringing);

      final snoozed = svc.snooze(ringing, 5);

      expect(snoozed.status, TimerStatus.running);
      expect(snoozed.endAt, DateTime(2026, 5, 1, 7, 35));
      expect(snoozed.pausedRemaining, isNull);
    });

    test('スヌーズ後も元の duration は変わらない（reset で元に戻せる）', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final ringing = svc
          .createIdle(label: '', duration: const Duration(seconds: 30))
          .copyWith(status: TimerStatus.ringing);

      final snoozed = svc.snooze(ringing, 3);

      expect(snoozed.duration, const Duration(seconds: 30));
    });

    test('スヌーズ後の remaining が指定分後の残り時間と一致する', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final ringing = svc
          .createIdle(label: '', duration: const Duration(seconds: 5))
          .copyWith(status: TimerStatus.ringing);

      final snoozed = svc.snooze(ringing, 10);

      expect(svc.remaining(snoozed), const Duration(minutes: 10));
    });

    test('idle からのスヌーズは StateError', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );

      expect(() => svc.snooze(idle, 5), throwsStateError);
    });

    test('running からのスヌーズは StateError', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );

      expect(() => svc.snooze(running, 5), throwsStateError);
    });

    test('paused からのスヌーズは StateError', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final running = svc.start(
        svc.createIdle(label: '', duration: const Duration(seconds: 5)),
      );
      final paused = svc.pause(running);

      expect(() => svc.snooze(paused, 5), throwsStateError);
    });

    test('completed からのスヌーズは StateError', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );
      final completed = idle.copyWith(status: TimerStatus.completed);

      expect(() => svc.snooze(completed, 5), throwsStateError);
    });

    test('cancelled からのスヌーズは StateError', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final idle = svc.createIdle(
        label: '',
        duration: const Duration(seconds: 5),
      );
      final cancelled = svc.cancel(idle);

      expect(() => svc.snooze(cancelled, 5), throwsStateError);
    });

    test('プリセット外の分数（4 分）は ArgumentError', () {
      final now = _MutableNow(DateTime(2026, 5, 1, 7, 30));
      final svc = _service(now);
      final ringing = svc
          .createIdle(label: '', duration: const Duration(seconds: 5))
          .copyWith(status: TimerStatus.ringing);

      expect(() => svc.snooze(ringing, 4), throwsArgumentError);
    });
  });
}
