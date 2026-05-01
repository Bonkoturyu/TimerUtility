import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/exceptions.dart';
import 'package:timer_utility/domain/timer/timer_collection.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

TimerEntity _entity({String id = 't1', TimerStatus status = TimerStatus.idle}) {
  return TimerEntity(
    id: id,
    notificationId: id.hashCode & 0x7FFFFFFF,
    label: '',
    duration: const Duration(minutes: 1),
    endAt: null,
    pausedRemaining: null,
    status: status,
    createdAt: DateTime.utc(2026, 5, 1),
  );
}

void main() {
  group('TimerCollection.empty', () {
    test('starts empty, not full', () {
      final TimerCollection c = TimerCollection.empty();
      expect(c.isEmpty, isTrue);
      expect(c.size, 0);
      expect(c.isFull, isFalse);
      expect(c.all, isEmpty);
      expect(c.runningCount, 0);
    });
  });

  group('TimerCollection.add', () {
    test('adds a new timer', () {
      final TimerCollection c = TimerCollection.empty().add(_entity());
      expect(c.size, 1);
      expect(c.findById('t1'), isNotNull);
    });

    test('adding an existing id updates instead of duplicating', () {
      final TimerCollection c = TimerCollection.empty()
          .add(_entity(id: 't1', status: TimerStatus.idle))
          .add(_entity(id: 't1', status: TimerStatus.running));
      expect(c.size, 1);
      expect(c.findById('t1')!.status, TimerStatus.running);
    });

    test('throws MaxTimerCountExceededException when adding the 11th', () {
      TimerCollection c = TimerCollection.empty();
      for (int i = 0; i < TimerCollection.maxSize; i++) {
        c = c.add(_entity(id: 't$i'));
      }
      expect(c.isFull, isTrue);
      expect(
        () => c.add(_entity(id: 'overflow')),
        throwsA(isA<MaxTimerCountExceededException>()),
      );
    });
  });

  group('TimerCollection.update', () {
    test('replaces the entity stored under the same id', () {
      final TimerCollection c = TimerCollection.empty().add(
        _entity(status: TimerStatus.idle),
      );
      final TimerCollection next = c.update(
        _entity(status: TimerStatus.running),
      );
      expect(next.findById('t1')!.status, TimerStatus.running);
    });

    test('throws TimerNotFoundException for unknown id', () {
      expect(
        () => TimerCollection.empty().update(_entity(id: 'missing')),
        throwsA(isA<TimerNotFoundException>()),
      );
    });
  });

  group('TimerCollection.remove', () {
    test('removes the entity by id', () {
      final TimerCollection c = TimerCollection.empty()
          .add(_entity(id: 'a'))
          .add(_entity(id: 'b'));
      final TimerCollection next = c.remove('a');
      expect(next.size, 1);
      expect(next.findById('a'), isNull);
      expect(next.findById('b'), isNotNull);
    });

    test('throws TimerNotFoundException for unknown id', () {
      expect(
        () => TimerCollection.empty().remove('missing'),
        throwsA(isA<TimerNotFoundException>()),
      );
    });
  });

  group('TimerCollection.fromList', () {
    test('builds from a list of entities', () {
      final TimerCollection c = TimerCollection.fromList(<TimerEntity>[
        _entity(id: 'a'),
        _entity(id: 'b', status: TimerStatus.running),
      ]);
      expect(c.size, 2);
      expect(c.runningCount, 1);
    });

    test('throws when the source list exceeds maxSize', () {
      final List<TimerEntity> tooMany = <TimerEntity>[
        for (int i = 0; i < TimerCollection.maxSize + 1; i++)
          _entity(id: 't$i'),
      ];
      expect(
        () => TimerCollection.fromList(tooMany),
        throwsA(isA<MaxTimerCountExceededException>()),
      );
    });
  });

  group('TimerCollection immutability', () {
    test('add returns a new collection without mutating the original', () {
      final TimerCollection original = TimerCollection.empty();
      final TimerCollection added = original.add(_entity());
      expect(original.size, 0);
      expect(added.size, 1);
    });

    test('all returns an unmodifiable view', () {
      final TimerCollection c = TimerCollection.empty().add(_entity());
      expect(() => c.all.add(_entity(id: 'x')), throwsUnsupportedError);
    });
  });

  group('TimerCollection.runningCount', () {
    test('counts only running entities', () {
      final TimerCollection c = TimerCollection.empty()
          .add(_entity(id: 'a', status: TimerStatus.idle))
          .add(_entity(id: 'b', status: TimerStatus.running))
          .add(_entity(id: 'c', status: TimerStatus.running))
          .add(_entity(id: 'd', status: TimerStatus.paused));
      expect(c.runningCount, 2);
    });
  });
}
