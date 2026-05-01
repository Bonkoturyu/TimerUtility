// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TimersTable extends Timers with TableInfo<$TimersTable, TimerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMsMeta = const VerificationMeta(
    'endAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> endAtUtcMs = GeneratedColumn<int>(
    'end_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedRemainingMsMeta = const VerificationMeta(
    'pausedRemainingMs',
  );
  @override
  late final GeneratedColumn<int> pausedRemainingMs = GeneratedColumn<int>(
    'paused_remaining_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soundIdMeta = const VerificationMeta(
    'soundId',
  );
  @override
  late final GeneratedColumn<String> soundId = GeneratedColumn<String>(
    'sound_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notificationId,
    label,
    durationMs,
    endAtUtcMs,
    pausedRemainingMs,
    status,
    soundId,
    createdAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timers';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('end_at_utc_ms')) {
      context.handle(
        _endAtUtcMsMeta,
        endAtUtcMs.isAcceptableOrUnknown(
          data['end_at_utc_ms']!,
          _endAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('paused_remaining_ms')) {
      context.handle(
        _pausedRemainingMsMeta,
        pausedRemainingMs.isAcceptableOrUnknown(
          data['paused_remaining_ms']!,
          _pausedRemainingMsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sound_id')) {
      context.handle(
        _soundIdMeta,
        soundId.isAcceptableOrUnknown(data['sound_id']!, _soundIdMeta),
      );
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      endAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at_utc_ms'],
      ),
      pausedRemainingMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_remaining_ms'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      soundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_id'],
      ),
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
    );
  }

  @override
  $TimersTable createAlias(String alias) {
    return $TimersTable(attachedDatabase, alias);
  }
}

class TimerRow extends DataClass implements Insertable<TimerRow> {
  final String id;
  final int notificationId;
  final String label;
  final int durationMs;
  final int? endAtUtcMs;
  final int? pausedRemainingMs;
  final String status;
  final String? soundId;
  final int createdAtUtcMs;
  const TimerRow({
    required this.id,
    required this.notificationId,
    required this.label,
    required this.durationMs,
    this.endAtUtcMs,
    this.pausedRemainingMs,
    required this.status,
    this.soundId,
    required this.createdAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notification_id'] = Variable<int>(notificationId);
    map['label'] = Variable<String>(label);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || endAtUtcMs != null) {
      map['end_at_utc_ms'] = Variable<int>(endAtUtcMs);
    }
    if (!nullToAbsent || pausedRemainingMs != null) {
      map['paused_remaining_ms'] = Variable<int>(pausedRemainingMs);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || soundId != null) {
      map['sound_id'] = Variable<String>(soundId);
    }
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    return map;
  }

  TimersCompanion toCompanion(bool nullToAbsent) {
    return TimersCompanion(
      id: Value(id),
      notificationId: Value(notificationId),
      label: Value(label),
      durationMs: Value(durationMs),
      endAtUtcMs: endAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endAtUtcMs),
      pausedRemainingMs: pausedRemainingMs == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedRemainingMs),
      status: Value(status),
      soundId: soundId == null && nullToAbsent
          ? const Value.absent()
          : Value(soundId),
      createdAtUtcMs: Value(createdAtUtcMs),
    );
  }

  factory TimerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerRow(
      id: serializer.fromJson<String>(json['id']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      label: serializer.fromJson<String>(json['label']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      endAtUtcMs: serializer.fromJson<int?>(json['endAtUtcMs']),
      pausedRemainingMs: serializer.fromJson<int?>(json['pausedRemainingMs']),
      status: serializer.fromJson<String>(json['status']),
      soundId: serializer.fromJson<String?>(json['soundId']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'notificationId': serializer.toJson<int>(notificationId),
      'label': serializer.toJson<String>(label),
      'durationMs': serializer.toJson<int>(durationMs),
      'endAtUtcMs': serializer.toJson<int?>(endAtUtcMs),
      'pausedRemainingMs': serializer.toJson<int?>(pausedRemainingMs),
      'status': serializer.toJson<String>(status),
      'soundId': serializer.toJson<String?>(soundId),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
    };
  }

  TimerRow copyWith({
    String? id,
    int? notificationId,
    String? label,
    int? durationMs,
    Value<int?> endAtUtcMs = const Value.absent(),
    Value<int?> pausedRemainingMs = const Value.absent(),
    String? status,
    Value<String?> soundId = const Value.absent(),
    int? createdAtUtcMs,
  }) => TimerRow(
    id: id ?? this.id,
    notificationId: notificationId ?? this.notificationId,
    label: label ?? this.label,
    durationMs: durationMs ?? this.durationMs,
    endAtUtcMs: endAtUtcMs.present ? endAtUtcMs.value : this.endAtUtcMs,
    pausedRemainingMs: pausedRemainingMs.present
        ? pausedRemainingMs.value
        : this.pausedRemainingMs,
    status: status ?? this.status,
    soundId: soundId.present ? soundId.value : this.soundId,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
  );
  TimerRow copyWithCompanion(TimersCompanion data) {
    return TimerRow(
      id: data.id.present ? data.id.value : this.id,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      label: data.label.present ? data.label.value : this.label,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      endAtUtcMs: data.endAtUtcMs.present
          ? data.endAtUtcMs.value
          : this.endAtUtcMs,
      pausedRemainingMs: data.pausedRemainingMs.present
          ? data.pausedRemainingMs.value
          : this.pausedRemainingMs,
      status: data.status.present ? data.status.value : this.status,
      soundId: data.soundId.present ? data.soundId.value : this.soundId,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerRow(')
          ..write('id: $id, ')
          ..write('notificationId: $notificationId, ')
          ..write('label: $label, ')
          ..write('durationMs: $durationMs, ')
          ..write('endAtUtcMs: $endAtUtcMs, ')
          ..write('pausedRemainingMs: $pausedRemainingMs, ')
          ..write('status: $status, ')
          ..write('soundId: $soundId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    notificationId,
    label,
    durationMs,
    endAtUtcMs,
    pausedRemainingMs,
    status,
    soundId,
    createdAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerRow &&
          other.id == this.id &&
          other.notificationId == this.notificationId &&
          other.label == this.label &&
          other.durationMs == this.durationMs &&
          other.endAtUtcMs == this.endAtUtcMs &&
          other.pausedRemainingMs == this.pausedRemainingMs &&
          other.status == this.status &&
          other.soundId == this.soundId &&
          other.createdAtUtcMs == this.createdAtUtcMs);
}

class TimersCompanion extends UpdateCompanion<TimerRow> {
  final Value<String> id;
  final Value<int> notificationId;
  final Value<String> label;
  final Value<int> durationMs;
  final Value<int?> endAtUtcMs;
  final Value<int?> pausedRemainingMs;
  final Value<String> status;
  final Value<String?> soundId;
  final Value<int> createdAtUtcMs;
  final Value<int> rowid;
  const TimersCompanion({
    this.id = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.label = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.endAtUtcMs = const Value.absent(),
    this.pausedRemainingMs = const Value.absent(),
    this.status = const Value.absent(),
    this.soundId = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimersCompanion.insert({
    required String id,
    required int notificationId,
    required String label,
    required int durationMs,
    this.endAtUtcMs = const Value.absent(),
    this.pausedRemainingMs = const Value.absent(),
    required String status,
    this.soundId = const Value.absent(),
    required int createdAtUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       notificationId = Value(notificationId),
       label = Value(label),
       durationMs = Value(durationMs),
       status = Value(status),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<TimerRow> custom({
    Expression<String>? id,
    Expression<int>? notificationId,
    Expression<String>? label,
    Expression<int>? durationMs,
    Expression<int>? endAtUtcMs,
    Expression<int>? pausedRemainingMs,
    Expression<String>? status,
    Expression<String>? soundId,
    Expression<int>? createdAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notificationId != null) 'notification_id': notificationId,
      if (label != null) 'label': label,
      if (durationMs != null) 'duration_ms': durationMs,
      if (endAtUtcMs != null) 'end_at_utc_ms': endAtUtcMs,
      if (pausedRemainingMs != null) 'paused_remaining_ms': pausedRemainingMs,
      if (status != null) 'status': status,
      if (soundId != null) 'sound_id': soundId,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimersCompanion copyWith({
    Value<String>? id,
    Value<int>? notificationId,
    Value<String>? label,
    Value<int>? durationMs,
    Value<int?>? endAtUtcMs,
    Value<int?>? pausedRemainingMs,
    Value<String>? status,
    Value<String?>? soundId,
    Value<int>? createdAtUtcMs,
    Value<int>? rowid,
  }) {
    return TimersCompanion(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      label: label ?? this.label,
      durationMs: durationMs ?? this.durationMs,
      endAtUtcMs: endAtUtcMs ?? this.endAtUtcMs,
      pausedRemainingMs: pausedRemainingMs ?? this.pausedRemainingMs,
      status: status ?? this.status,
      soundId: soundId ?? this.soundId,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (endAtUtcMs.present) {
      map['end_at_utc_ms'] = Variable<int>(endAtUtcMs.value);
    }
    if (pausedRemainingMs.present) {
      map['paused_remaining_ms'] = Variable<int>(pausedRemainingMs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (soundId.present) {
      map['sound_id'] = Variable<String>(soundId.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimersCompanion(')
          ..write('id: $id, ')
          ..write('notificationId: $notificationId, ')
          ..write('label: $label, ')
          ..write('durationMs: $durationMs, ')
          ..write('endAtUtcMs: $endAtUtcMs, ')
          ..write('pausedRemainingMs: $pausedRemainingMs, ')
          ..write('status: $status, ')
          ..write('soundId: $soundId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TimersTable timers = $TimersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [timers];
}

typedef $$TimersTableCreateCompanionBuilder =
    TimersCompanion Function({
      required String id,
      required int notificationId,
      required String label,
      required int durationMs,
      Value<int?> endAtUtcMs,
      Value<int?> pausedRemainingMs,
      required String status,
      Value<String?> soundId,
      required int createdAtUtcMs,
      Value<int> rowid,
    });
typedef $$TimersTableUpdateCompanionBuilder =
    TimersCompanion Function({
      Value<String> id,
      Value<int> notificationId,
      Value<String> label,
      Value<int> durationMs,
      Value<int?> endAtUtcMs,
      Value<int?> pausedRemainingMs,
      Value<String> status,
      Value<String?> soundId,
      Value<int> createdAtUtcMs,
      Value<int> rowid,
    });

class $$TimersTableFilterComposer
    extends Composer<_$AppDatabase, $TimersTable> {
  $$TimersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAtUtcMs => $composableBuilder(
    column: $table.endAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedRemainingMs => $composableBuilder(
    column: $table.pausedRemainingMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundId => $composableBuilder(
    column: $table.soundId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimersTableOrderingComposer
    extends Composer<_$AppDatabase, $TimersTable> {
  $$TimersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAtUtcMs => $composableBuilder(
    column: $table.endAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedRemainingMs => $composableBuilder(
    column: $table.pausedRemainingMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundId => $composableBuilder(
    column: $table.soundId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimersTable> {
  $$TimersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endAtUtcMs => $composableBuilder(
    column: $table.endAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedRemainingMs => $composableBuilder(
    column: $table.pausedRemainingMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get soundId =>
      $composableBuilder(column: $table.soundId, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );
}

class $$TimersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimersTable,
          TimerRow,
          $$TimersTableFilterComposer,
          $$TimersTableOrderingComposer,
          $$TimersTableAnnotationComposer,
          $$TimersTableCreateCompanionBuilder,
          $$TimersTableUpdateCompanionBuilder,
          (TimerRow, BaseReferences<_$AppDatabase, $TimersTable, TimerRow>),
          TimerRow,
          PrefetchHooks Function()
        > {
  $$TimersTableTableManager(_$AppDatabase db, $TimersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> endAtUtcMs = const Value.absent(),
                Value<int?> pausedRemainingMs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> soundId = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimersCompanion(
                id: id,
                notificationId: notificationId,
                label: label,
                durationMs: durationMs,
                endAtUtcMs: endAtUtcMs,
                pausedRemainingMs: pausedRemainingMs,
                status: status,
                soundId: soundId,
                createdAtUtcMs: createdAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int notificationId,
                required String label,
                required int durationMs,
                Value<int?> endAtUtcMs = const Value.absent(),
                Value<int?> pausedRemainingMs = const Value.absent(),
                required String status,
                Value<String?> soundId = const Value.absent(),
                required int createdAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => TimersCompanion.insert(
                id: id,
                notificationId: notificationId,
                label: label,
                durationMs: durationMs,
                endAtUtcMs: endAtUtcMs,
                pausedRemainingMs: pausedRemainingMs,
                status: status,
                soundId: soundId,
                createdAtUtcMs: createdAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimersTable,
      TimerRow,
      $$TimersTableFilterComposer,
      $$TimersTableOrderingComposer,
      $$TimersTableAnnotationComposer,
      $$TimersTableCreateCompanionBuilder,
      $$TimersTableUpdateCompanionBuilder,
      (TimerRow, BaseReferences<_$AppDatabase, $TimersTable, TimerRow>),
      TimerRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimersTableTableManager get timers =>
      $$TimersTableTableManager(_db, _db.timers);
}
