import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/timer/preset_templates.dart';

part 'app_database.g.dart';

/// Default UUID v4 generator (separate from the database so tests can
/// inject a deterministic alternative for migration assertions).
String _defaultIdGenerator() => const Uuid().v4();

/// Drift table definition for [Timer] persistence.
///
/// Mirrors `TimerEntity` 1:1; `TimerStatus` is stored as its `name`
/// (lowercase enum identifier) so future enum additions remain
/// backward-readable. Optional fields use Dart `null` rather than
/// sentinel values so DB-level integrity (NOT NULL where applicable)
/// stays meaningful.
@DataClassName('TimerRow')
class Timers extends Table {
  TextColumn get id => text()();
  IntColumn get notificationId => integer()();
  TextColumn get label => text()();
  IntColumn get durationMs => integer()();
  IntColumn get endAtUtcMs => integer().nullable()();
  IntColumn get pausedRemainingMs => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get soundId => text().nullable()();
  IntColumn get createdAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Drift table definition for [Preset] persistence (Phase 9).
///
/// `Preset` mirrors `Timer`'s storage conventions: epoch-ms in UTC for
/// `DateTime`, ms for `Duration`, optional fields stored as `null`.
/// There is no `status` analogue — a Preset is a pure config template,
/// not a live timer.
@DataClassName('PresetRow')
class Presets extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get durationMs => integer()();
  TextColumn get soundId => text().nullable()();
  IntColumn get createdAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Application database. Phase 8 shipped with the `timers` table only;
/// Phase 9 introduces `presets` (schemaVersion bump 1 → 2) along with
/// a default-profile seed in `onCreate` / `onUpgrade`. Alarm /
/// ClockLocation tables land in Phase 9.5 / 10.5 respectively and will
/// require further schema bumps.
///
/// Use [AppDatabase.forTesting] to spin up an in-memory SQLite instance
/// without touching disk. `clock` and `idGenerator` are injectable so
/// migration / seed paths stay deterministic in unit tests.
@DriftDatabase(tables: <Type>[Timers, Presets])
class AppDatabase extends _$AppDatabase {
  AppDatabase({Clock? clock, String Function()? idGenerator})
    : _clock = clock ?? const Clock(),
      _idGenerator = idGenerator ?? _defaultIdGenerator,
      super(driftDatabase(name: 'timer_utility'));

  AppDatabase.forTesting(
    super.executor, {
    Clock? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? const Clock(),
       _idGenerator = idGenerator ?? _defaultIdGenerator;

  final Clock _clock;
  final String Function() _idGenerator;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // Fresh install: build the entire schema and drop the default
      // profile in. The seed runs only on first launch; subsequent
      // launches read whatever the user has edited.
      await m.createAll();
      await _seedDefaultPresets();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Phase 8 → Phase 9: only `presets` is new; `timers` is left
        // untouched so existing user data survives.
        await m.createTable(presets);
        await _seedDefaultPresets();
      }
    },
  );

  /// Inserts `PresetTemplates.defaultProfile` (6 entries) into the
  /// `presets` table as a single batch. Called from `onCreate` on a
  /// fresh install and from `onUpgrade` when a Phase 8 user moves to
  /// schemaVersion 2. Both paths run inside Drift's migration
  /// transaction, so a partial failure rolls back atomically.
  Future<void> _seedDefaultPresets() async {
    final DateTime now = _clock.now();
    await batch((Batch b) {
      for (final PresetTemplate t in PresetTemplates.defaultProfile.templates) {
        b.insert(
          presets,
          PresetsCompanion(
            id: Value<String>(_idGenerator()),
            label: Value<String>(t.label),
            durationMs: Value<int>(t.duration.inMilliseconds),
            soundId: Value<String?>(t.soundId),
            createdAtUtcMs: Value<int>(now.toUtc().millisecondsSinceEpoch),
          ),
        );
      }
    });
  }
}
