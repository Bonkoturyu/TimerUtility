import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';

ClockLocation _location({
  String id = 'l1',
  String displayName = 'Tokyo',
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
  group('ClockLocation', () {
    test('value equality (same fields → equal)', () {
      expect(_location(), equals(_location()));
    });

    test('differing field breaks equality', () {
      expect(
        _location(displayName: 'Tokyo'),
        isNot(equals(_location(displayName: 'Kyoto'))),
      );
    });

    test('copyWith preserves untouched fields', () {
      final original = _location(displayName: 'Tokyo');
      final copy = original.copyWith(displayName: 'Kyoto');
      expect(copy.displayName, 'Kyoto');
      expect(copy.timezoneId, 'Asia/Tokyo');
      expect(copy.id, original.id);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith on isCurrentLocation flips flag only', () {
      final original = _location(isCurrentLocation: false);
      final copy = original.copyWith(isCurrentLocation: true);
      expect(copy.isCurrentLocation, isTrue);
      expect(copy.id, original.id);
    });
  });
}
