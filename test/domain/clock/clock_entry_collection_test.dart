import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/domain/clock/clock_entry_collection.dart';
import 'package:timer_utility/domain/clock/exceptions.dart';

ClockEntry _entry(
  String id, {
  String displayName = 'City',
  String timezoneId = 'Asia/Tokyo',
  bool isCurrentLocation = false,
  int displayOrder = 0,
}) => ClockEntry(
  id: id,
  displayName: displayName,
  timezoneId: timezoneId,
  isCurrentLocation: isCurrentLocation,
  displayOrder: displayOrder,
  createdAt: DateTime(2026, 5, 9),
);

void main() {
  group('ClockEntryCollection.empty', () {
    test('starts empty, not full', () {
      final c = ClockEntryCollection.empty();
      expect(c.size, 0);
      expect(c.isEmpty, isTrue);
      expect(c.isFull, isFalse);
      expect(c.all, isEmpty);
      expect(c.currentEntry(), isNull);
    });
  });

  group('ClockEntryCollection.add', () {
    test('adds a new entry', () {
      final c0 = ClockEntryCollection.empty();
      final c1 = c0.add(_entry('a'));
      expect(c1.size, 1);
      expect(c1.findById('a')?.id, 'a');
      expect(c1.isEmpty, isFalse);
    });

    test('adding an existing id updates instead of duplicating', () {
      final c0 = ClockEntryCollection.empty().add(
        _entry('a', displayName: 'old'),
      );
      final c1 = c0.add(_entry('a', displayName: 'new'));
      expect(c1.size, 1);
      expect(c1.findById('a')?.displayName, 'new');
    });

    test('throws MaxClockEntryCountExceededException when adding the 7th', () {
      ClockEntryCollection c = ClockEntryCollection.empty();
      for (int i = 0; i < 6; i++) {
        c = c.add(_entry('p$i'));
      }
      expect(c.isFull, isTrue);
      expect(
        () => c.add(_entry('p6')),
        throwsA(isA<MaxClockEntryCountExceededException>()),
      );
    });

    test('adding a current-location entry demotes the existing one', () {
      final c0 = ClockEntryCollection.empty().add(
        _entry('a', isCurrentLocation: true),
      );
      final c1 = c0.add(_entry('b', isCurrentLocation: true));
      expect(c1.findById('a')?.isCurrentLocation, isFalse);
      expect(c1.findById('b')?.isCurrentLocation, isTrue);
      expect(c1.currentEntry()?.id, 'b');
    });

    test('non-current addition leaves existing current-location intact', () {
      final c0 = ClockEntryCollection.empty().add(
        _entry('a', isCurrentLocation: true),
      );
      final c1 = c0.add(_entry('b', isCurrentLocation: false));
      expect(c1.findById('a')?.isCurrentLocation, isTrue);
      expect(c1.findById('b')?.isCurrentLocation, isFalse);
      expect(c1.currentEntry()?.id, 'a');
    });
  });

  group('ClockEntryCollection.update', () {
    test('replaces the entity stored under the same id', () {
      final c0 = ClockEntryCollection.empty().add(
        _entry('a', displayName: 'before'),
      );
      final c1 = c0.update(_entry('a', displayName: 'after'));
      expect(c1.findById('a')?.displayName, 'after');
      expect(c1.size, 1);
    });

    test('throws ClockEntryNotFoundException for unknown id', () {
      final c = ClockEntryCollection.empty();
      expect(
        () => c.update(_entry('missing')),
        throwsA(isA<ClockEntryNotFoundException>()),
      );
    });

    test('promoting an entry to current-location demotes the previous one', () {
      final c0 = ClockEntryCollection.empty()
          .add(_entry('a', isCurrentLocation: true))
          .add(_entry('b'));
      final c1 = c0.update(_entry('b', isCurrentLocation: true));
      expect(c1.findById('a')?.isCurrentLocation, isFalse);
      expect(c1.findById('b')?.isCurrentLocation, isTrue);
      expect(c1.currentEntry()?.id, 'b');
    });
  });

  group('ClockEntryCollection.remove', () {
    test('removes the entity by id', () {
      final c0 = ClockEntryCollection.empty().add(_entry('a')).add(_entry('b'));
      final c1 = c0.remove('a');
      expect(c1.findById('a'), isNull);
      expect(c1.findById('b')?.id, 'b');
      expect(c1.size, 1);
    });

    test('throws ClockEntryNotFoundException for unknown id', () {
      final c = ClockEntryCollection.empty();
      expect(
        () => c.remove('ghost'),
        throwsA(isA<ClockEntryNotFoundException>()),
      );
    });
  });

  group('ClockEntryCollection.reorder', () {
    test('moves an entry forward and recalculates displayOrder', () {
      ClockEntryCollection c = ClockEntryCollection.empty();
      for (int i = 0; i < 4; i++) {
        c = c.add(_entry('l$i', displayOrder: i));
      }
      final moved = c.reorder(0, 2);
      final ids = moved.all.map((l) => l.id).toList();
      expect(ids, <String>['l1', 'l2', 'l0', 'l3']);
      for (int i = 0; i < moved.all.length; i++) {
        expect(moved.all[i].displayOrder, i);
      }
    });

    test('moves an entry backward', () {
      ClockEntryCollection c = ClockEntryCollection.empty();
      for (int i = 0; i < 4; i++) {
        c = c.add(_entry('l$i', displayOrder: i));
      }
      final moved = c.reorder(3, 0);
      final ids = moved.all.map((l) => l.id).toList();
      expect(ids, <String>['l3', 'l0', 'l1', 'l2']);
    });

    test('oldIndex == newIndex returns the same instance', () {
      final c0 = ClockEntryCollection.empty().add(_entry('a')).add(_entry('b'));
      final c1 = c0.reorder(0, 0);
      expect(identical(c0, c1), isTrue);
    });

    test('throws RangeError when newIndex is out of bounds', () {
      final c = ClockEntryCollection.empty().add(_entry('a'));
      expect(() => c.reorder(0, 5), throwsA(isA<RangeError>()));
    });

    test('throws RangeError when oldIndex is out of bounds', () {
      final c = ClockEntryCollection.empty().add(_entry('a'));
      expect(() => c.reorder(5, 0), throwsA(isA<RangeError>()));
    });
  });

  group('ClockEntryCollection.fromList', () {
    test('builds from a list of entities', () {
      final c = ClockEntryCollection.fromList(<ClockEntry>[
        _entry('a'),
        _entry('b'),
      ]);
      expect(c.size, 2);
      expect(c.findById('a')?.id, 'a');
      expect(c.findById('b')?.id, 'b');
    });

    test('throws when the source list exceeds maxSize', () {
      final tooMany = <ClockEntry>[for (int i = 0; i < 7; i++) _entry('p$i')];
      expect(
        () => ClockEntryCollection.fromList(tooMany),
        throwsA(isA<MaxClockEntryCountExceededException>()),
      );
    });

    test(
      'demotes duplicate current-location entries so only the first survives',
      () {
        final c = ClockEntryCollection.fromList(<ClockEntry>[
          _entry('a', isCurrentLocation: true),
          _entry('b', isCurrentLocation: true),
        ]);
        expect(c.findById('a')?.isCurrentLocation, isTrue);
        expect(c.findById('b')?.isCurrentLocation, isFalse);
        expect(c.currentEntry()?.id, 'a');
      },
    );
  });

  group('ClockEntryCollection.currentEntry', () {
    test('returns null when no entry is flagged', () {
      final c = ClockEntryCollection.empty().add(_entry('a'));
      expect(c.currentEntry(), isNull);
    });

    test('returns the single flagged entry', () {
      final c = ClockEntryCollection.empty()
          .add(_entry('a'))
          .add(_entry('b', isCurrentLocation: true));
      expect(c.currentEntry()?.id, 'b');
    });
  });

  group('ClockEntryCollection immutability', () {
    test('add returns a new collection without mutating the original', () {
      final c0 = ClockEntryCollection.empty();
      final c1 = c0.add(_entry('a'));
      expect(c0.size, 0);
      expect(c1.size, 1);
      expect(identical(c0, c1), isFalse);
    });

    test('all returns an unmodifiable view', () {
      final c = ClockEntryCollection.empty().add(_entry('a'));
      expect(() => c.all.add(_entry('b')), throwsA(isA<UnsupportedError>()));
    });
  });
}
