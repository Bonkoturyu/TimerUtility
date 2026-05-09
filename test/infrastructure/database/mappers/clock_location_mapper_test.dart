import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/mappers/clock_location_mapper.dart';

void main() {
  const ClockLocationMapper mapper = ClockLocationMapper();

  ClockLocation makeEntity({
    String id = 'c-1',
    String displayName = 'Tokyo',
    String timezoneId = 'Asia/Tokyo',
    bool isCurrentLocation = false,
    int displayOrder = 0,
    DateTime? createdAt,
  }) {
    return ClockLocation(
      id: id,
      displayName: displayName,
      timezoneId: timezoneId,
      isCurrentLocation: isCurrentLocation,
      displayOrder: displayOrder,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 9, 12),
    );
  }

  group('ClockLocationMapper roundtrip', () {
    test('all fields survive roundtrip', () {
      final ClockLocation original = makeEntity(isCurrentLocation: true);
      final ClockLocationRow row = mapper.toRow(original);
      final ClockLocation back = mapper.toEntity(row);
      expect(back, original);
    });

    test('isCurrentLocation=false roundtrips correctly', () {
      final ClockLocation original = makeEntity();
      final ClockLocation back = mapper.toEntity(mapper.toRow(original));
      expect(back.isCurrentLocation, isFalse);
      expect(back, original);
    });

    test('displayOrder=5 (max) roundtrips correctly', () {
      final ClockLocation original = makeEntity(displayOrder: 5);
      final ClockLocation back = mapper.toEntity(mapper.toRow(original));
      expect(back.displayOrder, 5);
    });

    test('local-time createdAt is normalised to UTC after roundtrip', () {
      final DateTime local = DateTime(2026, 5, 9, 12);
      final ClockLocation original = makeEntity(createdAt: local);
      final ClockLocation back = mapper.toEntity(mapper.toRow(original));
      expect(back.createdAt.isUtc, isTrue);
      expect(back.createdAt, local.toUtc());
    });

    test('epoch boundary (1970-01-01 UTC) roundtrips correctly', () {
      final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      );
      final ClockLocation original = makeEntity(createdAt: epoch);
      final ClockLocation back = mapper.toEntity(mapper.toRow(original));
      expect(back.createdAt, epoch);
      expect(back.createdAt.millisecondsSinceEpoch, 0);
    });

    test('IANA timezoneId is preserved verbatim (no normalization)', () {
      final ClockLocation original = makeEntity(
        timezoneId: 'America/Los_Angeles',
      );
      final ClockLocation back = mapper.toEntity(mapper.toRow(original));
      expect(back.timezoneId, 'America/Los_Angeles');
    });
  });

  group('ClockLocationMapper.toCompanion', () {
    test('all fields produce Value(...) (no absent slots)', () {
      final ClockLocation entity = makeEntity(
        isCurrentLocation: true,
        displayOrder: 3,
      );
      final ClockLocationsCompanion companion = mapper.toCompanion(entity);
      expect(companion.id.value, 'c-1');
      expect(companion.displayName.value, 'Tokyo');
      expect(companion.timezoneId.value, 'Asia/Tokyo');
      expect(companion.isCurrentLocation.value, isTrue);
      expect(companion.displayOrder.value, 3);
      expect(
        companion.createdAtUtcMs.value,
        DateTime.utc(2026, 5, 9, 12).millisecondsSinceEpoch,
      );
    });
  });
}
