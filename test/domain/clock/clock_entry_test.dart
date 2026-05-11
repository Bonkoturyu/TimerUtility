import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';

ClockEntry _entry({
  String id = 'l1',
  String displayName = 'Tokyo',
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
  group('ClockEntry', () {
    test('value equality (same fields → equal)', () {
      expect(_entry(), equals(_entry()));
    });

    test('differing field breaks equality', () {
      expect(
        _entry(displayName: 'Tokyo'),
        isNot(equals(_entry(displayName: 'Kyoto'))),
      );
    });

    test('copyWith preserves untouched fields', () {
      final original = _entry(displayName: 'Tokyo');
      final copy = original.copyWith(displayName: 'Kyoto');
      expect(copy.displayName, 'Kyoto');
      expect(copy.timezoneId, 'Asia/Tokyo');
      expect(copy.id, original.id);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith on isCurrentLocation flips flag only', () {
      final original = _entry(isCurrentLocation: false);
      final copy = original.copyWith(isCurrentLocation: true);
      expect(copy.isCurrentLocation, isTrue);
      expect(copy.id, original.id);
    });
  });
}
