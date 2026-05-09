import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_collection.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/domain/clock/exceptions.dart';

ClockLocation _loc(
  String id, {
  String displayName = 'City',
  String timezoneId = 'Asia/Tokyo',
  bool isCurrentLocation = false,
  int displayOrder = 0,
}) => ClockLocation(
  id: id,
  displayName: displayName,
  timezoneId: timezoneId,
  isCurrentLocation: isCurrentLocation,
  displayOrder: displayOrder,
  createdAt: DateTime(2026, 5, 9),
);

void main() {
  group('ClockCollection.empty', () {
    test('starts empty, not full', () {
      final c = ClockCollection.empty();
      expect(c.size, 0);
      expect(c.isEmpty, isTrue);
      expect(c.isFull, isFalse);
      expect(c.all, isEmpty);
      expect(c.currentLocation(), isNull);
    });
  });

  group('ClockCollection.add', () {
    test('adds a new location', () {
      final c0 = ClockCollection.empty();
      final c1 = c0.add(_loc('a'));
      expect(c1.size, 1);
      expect(c1.findById('a')?.id, 'a');
      expect(c1.isEmpty, isFalse);
    });

    test('adding an existing id updates instead of duplicating', () {
      final c0 = ClockCollection.empty().add(_loc('a', displayName: 'old'));
      final c1 = c0.add(_loc('a', displayName: 'new'));
      expect(c1.size, 1);
      expect(c1.findById('a')?.displayName, 'new');
    });

    test(
      'throws MaxClockLocationCountExceededException when adding the 7th',
      () {
        ClockCollection c = ClockCollection.empty();
        for (int i = 0; i < 6; i++) {
          c = c.add(_loc('p$i'));
        }
        expect(c.isFull, isTrue);
        expect(
          () => c.add(_loc('p6')),
          throwsA(isA<MaxClockLocationCountExceededException>()),
        );
      },
    );

    test('adding a current-location entry demotes the existing one', () {
      final c0 = ClockCollection.empty().add(
        _loc('a', isCurrentLocation: true),
      );
      final c1 = c0.add(_loc('b', isCurrentLocation: true));
      expect(c1.findById('a')?.isCurrentLocation, isFalse);
      expect(c1.findById('b')?.isCurrentLocation, isTrue);
      expect(c1.currentLocation()?.id, 'b');
    });

    test('non-current addition leaves existing current-location intact', () {
      final c0 = ClockCollection.empty().add(
        _loc('a', isCurrentLocation: true),
      );
      final c1 = c0.add(_loc('b', isCurrentLocation: false));
      expect(c1.findById('a')?.isCurrentLocation, isTrue);
      expect(c1.findById('b')?.isCurrentLocation, isFalse);
      expect(c1.currentLocation()?.id, 'a');
    });
  });

  group('ClockCollection.update', () {
    test('replaces the entity stored under the same id', () {
      final c0 = ClockCollection.empty().add(_loc('a', displayName: 'before'));
      final c1 = c0.update(_loc('a', displayName: 'after'));
      expect(c1.findById('a')?.displayName, 'after');
      expect(c1.size, 1);
    });

    test('throws ClockLocationNotFoundException for unknown id', () {
      final c = ClockCollection.empty();
      expect(
        () => c.update(_loc('missing')),
        throwsA(isA<ClockLocationNotFoundException>()),
      );
    });

    test('promoting an entry to current-location demotes the previous one', () {
      final c0 = ClockCollection.empty()
          .add(_loc('a', isCurrentLocation: true))
          .add(_loc('b'));
      final c1 = c0.update(_loc('b', isCurrentLocation: true));
      expect(c1.findById('a')?.isCurrentLocation, isFalse);
      expect(c1.findById('b')?.isCurrentLocation, isTrue);
      expect(c1.currentLocation()?.id, 'b');
    });
  });

  group('ClockCollection.remove', () {
    test('removes the entity by id', () {
      final c0 = ClockCollection.empty().add(_loc('a')).add(_loc('b'));
      final c1 = c0.remove('a');
      expect(c1.findById('a'), isNull);
      expect(c1.findById('b')?.id, 'b');
      expect(c1.size, 1);
    });

    test('throws ClockLocationNotFoundException for unknown id', () {
      final c = ClockCollection.empty();
      expect(
        () => c.remove('ghost'),
        throwsA(isA<ClockLocationNotFoundException>()),
      );
    });
  });

  group('ClockCollection.reorder', () {
    test('moves an entry forward and recalculates displayOrder', () {
      ClockCollection c = ClockCollection.empty();
      for (int i = 0; i < 4; i++) {
        c = c.add(_loc('l$i', displayOrder: i));
      }
      final moved = c.reorder(0, 2);
      final ids = moved.all.map((l) => l.id).toList();
      expect(ids, <String>['l1', 'l2', 'l0', 'l3']);
      for (int i = 0; i < moved.all.length; i++) {
        expect(moved.all[i].displayOrder, i);
      }
    });

    test('moves an entry backward', () {
      ClockCollection c = ClockCollection.empty();
      for (int i = 0; i < 4; i++) {
        c = c.add(_loc('l$i', displayOrder: i));
      }
      final moved = c.reorder(3, 0);
      final ids = moved.all.map((l) => l.id).toList();
      expect(ids, <String>['l3', 'l0', 'l1', 'l2']);
    });

    test('oldIndex == newIndex returns the same instance', () {
      final c0 = ClockCollection.empty().add(_loc('a')).add(_loc('b'));
      final c1 = c0.reorder(0, 0);
      expect(identical(c0, c1), isTrue);
    });

    test('throws RangeError when newIndex is out of bounds', () {
      final c = ClockCollection.empty().add(_loc('a'));
      expect(() => c.reorder(0, 5), throwsA(isA<RangeError>()));
    });

    test('throws RangeError when oldIndex is out of bounds', () {
      final c = ClockCollection.empty().add(_loc('a'));
      expect(() => c.reorder(5, 0), throwsA(isA<RangeError>()));
    });
  });

  group('ClockCollection.fromList', () {
    test('builds from a list of entities', () {
      final c = ClockCollection.fromList(<ClockLocation>[_loc('a'), _loc('b')]);
      expect(c.size, 2);
      expect(c.findById('a')?.id, 'a');
      expect(c.findById('b')?.id, 'b');
    });

    test('throws when the source list exceeds maxSize', () {
      final tooMany = <ClockLocation>[for (int i = 0; i < 7; i++) _loc('p$i')];
      expect(
        () => ClockCollection.fromList(tooMany),
        throwsA(isA<MaxClockLocationCountExceededException>()),
      );
    });

    test(
      'demotes duplicate current-location entries so only the first survives',
      () {
        final c = ClockCollection.fromList(<ClockLocation>[
          _loc('a', isCurrentLocation: true),
          _loc('b', isCurrentLocation: true),
        ]);
        expect(c.findById('a')?.isCurrentLocation, isTrue);
        expect(c.findById('b')?.isCurrentLocation, isFalse);
        expect(c.currentLocation()?.id, 'a');
      },
    );
  });

  group('ClockCollection.currentLocation', () {
    test('returns null when no entry is flagged', () {
      final c = ClockCollection.empty().add(_loc('a'));
      expect(c.currentLocation(), isNull);
    });

    test('returns the single flagged entry', () {
      final c = ClockCollection.empty()
          .add(_loc('a'))
          .add(_loc('b', isCurrentLocation: true));
      expect(c.currentLocation()?.id, 'b');
    });
  });

  group('ClockCollection immutability', () {
    test('add returns a new collection without mutating the original', () {
      final c0 = ClockCollection.empty();
      final c1 = c0.add(_loc('a'));
      expect(c0.size, 0);
      expect(c1.size, 1);
      expect(identical(c0, c1), isFalse);
    });

    test('all returns an unmodifiable view', () {
      final c = ClockCollection.empty().add(_loc('a'));
      expect(() => c.all.add(_loc('b')), throwsA(isA<UnsupportedError>()));
    });
  });
}
