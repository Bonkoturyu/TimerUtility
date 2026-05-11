import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/mappers/clock_entry_mapper.dart';

void main() {
  const ClockEntryMapper mapper = ClockEntryMapper();

  ClockEntry makeEntity({
    String id = 'c-1',
    String displayName = 'Tokyo',
    String timezoneId = 'Asia/Tokyo',
    bool isCurrentLocation = false,
    int displayOrder = 0,
    DateTime? createdAt,
  }) {
    return ClockEntry(
      id: id,
      displayName: displayName,
      timezoneId: timezoneId,
      isCurrentLocation: isCurrentLocation,
      displayOrder: displayOrder,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 9, 12),
    );
  }

  group('ClockEntryMapper roundtrip', () {
    test('all fields survive roundtrip', () {
      final ClockEntry original = makeEntity(isCurrentLocation: true);
      final ClockEntryRow row = mapper.toRow(original);
      final ClockEntry back = mapper.toEntity(row);
      expect(back, original);
    });

    test('isCurrentLocation=false roundtrips correctly', () {
      final ClockEntry original = makeEntity();
      final ClockEntry back = mapper.toEntity(mapper.toRow(original));
      expect(back.isCurrentLocation, isFalse);
      expect(back, original);
    });

    test('displayOrder=5 (max) roundtrips correctly', () {
      final ClockEntry original = makeEntity(displayOrder: 5);
      final ClockEntry back = mapper.toEntity(mapper.toRow(original));
      expect(back.displayOrder, 5);
    });

    test('local-time createdAt is normalised to UTC after roundtrip', () {
      final DateTime local = DateTime(2026, 5, 9, 12);
      final ClockEntry original = makeEntity(createdAt: local);
      final ClockEntry back = mapper.toEntity(mapper.toRow(original));
      expect(back.createdAt.isUtc, isTrue);
      expect(back.createdAt, local.toUtc());
    });

    test('epoch boundary (1970-01-01 UTC) roundtrips correctly', () {
      final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      );
      final ClockEntry original = makeEntity(createdAt: epoch);
      final ClockEntry back = mapper.toEntity(mapper.toRow(original));
      expect(back.createdAt, epoch);
      expect(back.createdAt.millisecondsSinceEpoch, 0);
    });

    test('IANA timezoneId is preserved verbatim (no normalization)', () {
      final ClockEntry original = makeEntity(timezoneId: 'America/Los_Angeles');
      final ClockEntry back = mapper.toEntity(mapper.toRow(original));
      expect(back.timezoneId, 'America/Los_Angeles');
    });
  });

  group('ClockEntryMapper.toCompanion', () {
    test('all fields produce Value(...) (no absent slots)', () {
      final ClockEntry entity = makeEntity(
        isCurrentLocation: true,
        displayOrder: 3,
      );
      final ClockEntriesCompanion companion = mapper.toCompanion(entity);
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
