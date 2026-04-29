import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/notification_id_generator.dart';

void main() {
  const gen = NotificationIdGenerator();

  group('NotificationIdGenerator', () {
    test('same timerId produces the same notification id (deterministic)', () {
      expect(gen.idFor('abc'), gen.idFor('abc'));
      expect(
        gen.idFor('550e8400-e29b-41d4-a716-446655440000'),
        gen.idFor('550e8400-e29b-41d4-a716-446655440000'),
      );
    });

    test('1000 distinct timerIds map to 1000 distinct notification ids', () {
      final ids = <int>{for (var i = 0; i < 1000; i++) gen.idFor('timer-$i')};
      expect(ids.length, 1000);
    });

    test('every output is in the 31-bit non-negative range', () {
      for (var i = 0; i < 1000; i++) {
        final id = gen.idFor('id-$i');
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('empty string is accepted and yields a valid id', () {
      final id = gen.idFor('');
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });
  });
}
