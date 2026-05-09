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

/// Drift テーブル定義: 世界時計のピン留め拠点 (Phase 10.5)。
///
/// 永続化方針:
///   - `id`: UUID v4 文字列 (Application 層で採番)。PK。
///   - `displayName`: ユーザ可視ラベル (1..30 文字、長さ制約は
///     Application 層 enforce)。
///   - `timezoneId`: IANA Time Zone Database 識別子
///     (例: 'Asia/Tokyo')。妥当性は `TimezoneResolver` が render 時に
///     検証するため、DB 層では生文字列のまま保存。
///   - `isCurrentLocation`: 「現在地」フラグ。集約 (`ClockCollection`)
///     で「true は最大 1 件」を保証する。BoolColumn (SQLite では
///     INTEGER 0/1)。
///   - `displayOrder`: 0..5 の表示順。ASC で findAll される前提
///     (port doc に明記)。
///   - `createdAtUtcMs`: epoch-ms UTC (Timer/Preset/Alarm と同じ規約)。
///
/// seed なし — 起動時に Notifier が現在地を 1 件追加する設計。
@DataClassName('ClockLocationRow')
class ClockLocations extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get timezoneId => text()();
  BoolColumn get isCurrentLocation => boolean()();
  IntColumn get displayOrder => integer()();
  IntColumn get createdAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Drift テーブル定義: 指定時刻アラーム (Phase 9.5、ADR 0005)。
///
/// 永続化方針:
///   - `targetTimeMinutes`: 0..1439 (00:00 を 0、23:59 を 1439 として
///     格納)。`TimeOfDayValue.toMinutesFromMidnight` の出力をそのまま保存。
///   - `repeatKind`: 'once' / 'weekly' の文字列。enum 名と同じく
///     「将来追加されたら migration が必要」というのを契約として残す。
///   - `repeatDaysBitmask`: 曜日のビットマスク
///     (Mon=1<<0, Tue=1<<1, …, Sun=1<<6)。`once` のときは 0。
///     0..127 の範囲で必ず収まる。
///   - `enabled`: BoolColumn (Drift が SQLite INTEGER で 0/1 にマップ)。
///   - その他の列規約 (epoch-ms UTC、null は null) は Timers/Presets と同一。
@DataClassName('AlarmRow')
class Alarms extends Table {
  TextColumn get id => text()();
  IntColumn get notificationId => integer()();
  TextColumn get label => text()();
  IntColumn get targetTimeMinutes => integer()();
  TextColumn get repeatKind => text()();
  IntColumn get repeatDaysBitmask => integer()();
  IntColumn get snoozeMinutes => integer()();
  BoolColumn get enabled => boolean()();
  TextColumn get soundId => text().nullable()();
  IntColumn get createdAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Application database. Phase 8 shipped with the `timers` table only;
/// Phase 9 introduces `presets` (schemaVersion bump 1 → 2) along with
/// a default-profile seed in `onCreate` / `onUpgrade`. Phase 9.5 adds
/// the `alarms` table (schemaVersion bump 2 → 3). Phase 10.5 adds the
/// `clock_locations` table (schemaVersion bump 3 → 4) — seed なしで、
/// 起動時に Notifier が現在地を 1 件追加する設計。
///
/// Use [AppDatabase.forTesting] to spin up an in-memory SQLite instance
/// without touching disk. `clock` and `idGenerator` are injectable so
/// migration / seed paths stay deterministic in unit tests.
@DriftDatabase(tables: <Type>[Timers, Presets, Alarms, ClockLocations])
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
  int get schemaVersion => 4;

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
      if (from < 3) {
        // Phase 9 → Phase 9.5: alarms テーブルを追加。既存の
        // timers / presets はそのまま残す。アラームは 0 件で開始
        // (seed なし) — ユーザが UI から作成する設計。
        await m.createTable(alarms);
      }
      if (from < 4) {
        // Phase 9.5 → Phase 10.5: clock_locations テーブルを追加。
        // seed なし — 起動時に Notifier が現在地を 1 件追加する。
        await m.createTable(clockLocations);
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
