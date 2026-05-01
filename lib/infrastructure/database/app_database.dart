import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

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

/// Application database. Phase 8 ships with the `timers` table only;
/// Preset / Alarm / ClockLocation tables land in Phase 9 / 9.5 / 10.5
/// respectively and will require a schema bump + migration step.
///
/// Use [AppDatabase.memory] in tests to spin up an in-memory SQLite
/// instance without touching disk.
@DriftDatabase(tables: <Type>[Timers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'timer_utility'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
