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

class $PresetsTable extends Presets with TableInfo<$PresetsTable, PresetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    label,
    durationMs,
    soundId,
    createdAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PresetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
  PresetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
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
  $PresetsTable createAlias(String alias) {
    return $PresetsTable(attachedDatabase, alias);
  }
}

class PresetRow extends DataClass implements Insertable<PresetRow> {
  final String id;
  final String label;
  final int durationMs;
  final String? soundId;
  final int createdAtUtcMs;
  const PresetRow({
    required this.id,
    required this.label,
    required this.durationMs,
    this.soundId,
    required this.createdAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || soundId != null) {
      map['sound_id'] = Variable<String>(soundId);
    }
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    return map;
  }

  PresetsCompanion toCompanion(bool nullToAbsent) {
    return PresetsCompanion(
      id: Value(id),
      label: Value(label),
      durationMs: Value(durationMs),
      soundId: soundId == null && nullToAbsent
          ? const Value.absent()
          : Value(soundId),
      createdAtUtcMs: Value(createdAtUtcMs),
    );
  }

  factory PresetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      soundId: serializer.fromJson<String?>(json['soundId']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'durationMs': serializer.toJson<int>(durationMs),
      'soundId': serializer.toJson<String?>(soundId),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
    };
  }

  PresetRow copyWith({
    String? id,
    String? label,
    int? durationMs,
    Value<String?> soundId = const Value.absent(),
    int? createdAtUtcMs,
  }) => PresetRow(
    id: id ?? this.id,
    label: label ?? this.label,
    durationMs: durationMs ?? this.durationMs,
    soundId: soundId.present ? soundId.value : this.soundId,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
  );
  PresetRow copyWithCompanion(PresetsCompanion data) {
    return PresetRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      soundId: data.soundId.present ? data.soundId.value : this.soundId,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('durationMs: $durationMs, ')
          ..write('soundId: $soundId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, durationMs, soundId, createdAtUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.durationMs == this.durationMs &&
          other.soundId == this.soundId &&
          other.createdAtUtcMs == this.createdAtUtcMs);
}

class PresetsCompanion extends UpdateCompanion<PresetRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> durationMs;
  final Value<String?> soundId;
  final Value<int> createdAtUtcMs;
  final Value<int> rowid;
  const PresetsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.soundId = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresetsCompanion.insert({
    required String id,
    required String label,
    required int durationMs,
    this.soundId = const Value.absent(),
    required int createdAtUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       durationMs = Value(durationMs),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<PresetRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? durationMs,
    Expression<String>? soundId,
    Expression<int>? createdAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (durationMs != null) 'duration_ms': durationMs,
      if (soundId != null) 'sound_id': soundId,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresetsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? durationMs,
    Value<String?>? soundId,
    Value<int>? createdAtUtcMs,
    Value<int>? rowid,
  }) {
    return PresetsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      durationMs: durationMs ?? this.durationMs,
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
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
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
    return (StringBuffer('PresetsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('durationMs: $durationMs, ')
          ..write('soundId: $soundId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, AlarmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _targetTimeMinutesMeta = const VerificationMeta(
    'targetTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> targetTimeMinutes = GeneratedColumn<int>(
    'target_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatKindMeta = const VerificationMeta(
    'repeatKind',
  );
  @override
  late final GeneratedColumn<String> repeatKind = GeneratedColumn<String>(
    'repeat_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatDaysBitmaskMeta = const VerificationMeta(
    'repeatDaysBitmask',
  );
  @override
  late final GeneratedColumn<int> repeatDaysBitmask = GeneratedColumn<int>(
    'repeat_days_bitmask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozeMinutesMeta = const VerificationMeta(
    'snoozeMinutes',
  );
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
    'snooze_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
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
    targetTimeMinutes,
    repeatKind,
    repeatDaysBitmask,
    snoozeMinutes,
    enabled,
    soundId,
    createdAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmRow> instance, {
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
    if (data.containsKey('target_time_minutes')) {
      context.handle(
        _targetTimeMinutesMeta,
        targetTimeMinutes.isAcceptableOrUnknown(
          data['target_time_minutes']!,
          _targetTimeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTimeMinutesMeta);
    }
    if (data.containsKey('repeat_kind')) {
      context.handle(
        _repeatKindMeta,
        repeatKind.isAcceptableOrUnknown(data['repeat_kind']!, _repeatKindMeta),
      );
    } else if (isInserting) {
      context.missing(_repeatKindMeta);
    }
    if (data.containsKey('repeat_days_bitmask')) {
      context.handle(
        _repeatDaysBitmaskMeta,
        repeatDaysBitmask.isAcceptableOrUnknown(
          data['repeat_days_bitmask']!,
          _repeatDaysBitmaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repeatDaysBitmaskMeta);
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
        _snoozeMinutesMeta,
        snoozeMinutes.isAcceptableOrUnknown(
          data['snooze_minutes']!,
          _snoozeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snoozeMinutesMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
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
  AlarmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmRow(
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
      targetTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_time_minutes'],
      )!,
      repeatKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_kind'],
      )!,
      repeatDaysBitmask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_days_bitmask'],
      )!,
      snoozeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_minutes'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
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
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }
}

class AlarmRow extends DataClass implements Insertable<AlarmRow> {
  final String id;
  final int notificationId;
  final String label;
  final int targetTimeMinutes;
  final String repeatKind;
  final int repeatDaysBitmask;
  final int snoozeMinutes;
  final bool enabled;
  final String? soundId;
  final int createdAtUtcMs;
  const AlarmRow({
    required this.id,
    required this.notificationId,
    required this.label,
    required this.targetTimeMinutes,
    required this.repeatKind,
    required this.repeatDaysBitmask,
    required this.snoozeMinutes,
    required this.enabled,
    this.soundId,
    required this.createdAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notification_id'] = Variable<int>(notificationId);
    map['label'] = Variable<String>(label);
    map['target_time_minutes'] = Variable<int>(targetTimeMinutes);
    map['repeat_kind'] = Variable<String>(repeatKind);
    map['repeat_days_bitmask'] = Variable<int>(repeatDaysBitmask);
    map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || soundId != null) {
      map['sound_id'] = Variable<String>(soundId);
    }
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      notificationId: Value(notificationId),
      label: Value(label),
      targetTimeMinutes: Value(targetTimeMinutes),
      repeatKind: Value(repeatKind),
      repeatDaysBitmask: Value(repeatDaysBitmask),
      snoozeMinutes: Value(snoozeMinutes),
      enabled: Value(enabled),
      soundId: soundId == null && nullToAbsent
          ? const Value.absent()
          : Value(soundId),
      createdAtUtcMs: Value(createdAtUtcMs),
    );
  }

  factory AlarmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmRow(
      id: serializer.fromJson<String>(json['id']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      label: serializer.fromJson<String>(json['label']),
      targetTimeMinutes: serializer.fromJson<int>(json['targetTimeMinutes']),
      repeatKind: serializer.fromJson<String>(json['repeatKind']),
      repeatDaysBitmask: serializer.fromJson<int>(json['repeatDaysBitmask']),
      snoozeMinutes: serializer.fromJson<int>(json['snoozeMinutes']),
      enabled: serializer.fromJson<bool>(json['enabled']),
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
      'targetTimeMinutes': serializer.toJson<int>(targetTimeMinutes),
      'repeatKind': serializer.toJson<String>(repeatKind),
      'repeatDaysBitmask': serializer.toJson<int>(repeatDaysBitmask),
      'snoozeMinutes': serializer.toJson<int>(snoozeMinutes),
      'enabled': serializer.toJson<bool>(enabled),
      'soundId': serializer.toJson<String?>(soundId),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
    };
  }

  AlarmRow copyWith({
    String? id,
    int? notificationId,
    String? label,
    int? targetTimeMinutes,
    String? repeatKind,
    int? repeatDaysBitmask,
    int? snoozeMinutes,
    bool? enabled,
    Value<String?> soundId = const Value.absent(),
    int? createdAtUtcMs,
  }) => AlarmRow(
    id: id ?? this.id,
    notificationId: notificationId ?? this.notificationId,
    label: label ?? this.label,
    targetTimeMinutes: targetTimeMinutes ?? this.targetTimeMinutes,
    repeatKind: repeatKind ?? this.repeatKind,
    repeatDaysBitmask: repeatDaysBitmask ?? this.repeatDaysBitmask,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    enabled: enabled ?? this.enabled,
    soundId: soundId.present ? soundId.value : this.soundId,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
  );
  AlarmRow copyWithCompanion(AlarmsCompanion data) {
    return AlarmRow(
      id: data.id.present ? data.id.value : this.id,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      label: data.label.present ? data.label.value : this.label,
      targetTimeMinutes: data.targetTimeMinutes.present
          ? data.targetTimeMinutes.value
          : this.targetTimeMinutes,
      repeatKind: data.repeatKind.present
          ? data.repeatKind.value
          : this.repeatKind,
      repeatDaysBitmask: data.repeatDaysBitmask.present
          ? data.repeatDaysBitmask.value
          : this.repeatDaysBitmask,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      soundId: data.soundId.present ? data.soundId.value : this.soundId,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmRow(')
          ..write('id: $id, ')
          ..write('notificationId: $notificationId, ')
          ..write('label: $label, ')
          ..write('targetTimeMinutes: $targetTimeMinutes, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('repeatDaysBitmask: $repeatDaysBitmask, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('enabled: $enabled, ')
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
    targetTimeMinutes,
    repeatKind,
    repeatDaysBitmask,
    snoozeMinutes,
    enabled,
    soundId,
    createdAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmRow &&
          other.id == this.id &&
          other.notificationId == this.notificationId &&
          other.label == this.label &&
          other.targetTimeMinutes == this.targetTimeMinutes &&
          other.repeatKind == this.repeatKind &&
          other.repeatDaysBitmask == this.repeatDaysBitmask &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.enabled == this.enabled &&
          other.soundId == this.soundId &&
          other.createdAtUtcMs == this.createdAtUtcMs);
}

class AlarmsCompanion extends UpdateCompanion<AlarmRow> {
  final Value<String> id;
  final Value<int> notificationId;
  final Value<String> label;
  final Value<int> targetTimeMinutes;
  final Value<String> repeatKind;
  final Value<int> repeatDaysBitmask;
  final Value<int> snoozeMinutes;
  final Value<bool> enabled;
  final Value<String?> soundId;
  final Value<int> createdAtUtcMs;
  final Value<int> rowid;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.label = const Value.absent(),
    this.targetTimeMinutes = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.repeatDaysBitmask = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.enabled = const Value.absent(),
    this.soundId = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsCompanion.insert({
    required String id,
    required int notificationId,
    required String label,
    required int targetTimeMinutes,
    required String repeatKind,
    required int repeatDaysBitmask,
    required int snoozeMinutes,
    required bool enabled,
    this.soundId = const Value.absent(),
    required int createdAtUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       notificationId = Value(notificationId),
       label = Value(label),
       targetTimeMinutes = Value(targetTimeMinutes),
       repeatKind = Value(repeatKind),
       repeatDaysBitmask = Value(repeatDaysBitmask),
       snoozeMinutes = Value(snoozeMinutes),
       enabled = Value(enabled),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<AlarmRow> custom({
    Expression<String>? id,
    Expression<int>? notificationId,
    Expression<String>? label,
    Expression<int>? targetTimeMinutes,
    Expression<String>? repeatKind,
    Expression<int>? repeatDaysBitmask,
    Expression<int>? snoozeMinutes,
    Expression<bool>? enabled,
    Expression<String>? soundId,
    Expression<int>? createdAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notificationId != null) 'notification_id': notificationId,
      if (label != null) 'label': label,
      if (targetTimeMinutes != null) 'target_time_minutes': targetTimeMinutes,
      if (repeatKind != null) 'repeat_kind': repeatKind,
      if (repeatDaysBitmask != null) 'repeat_days_bitmask': repeatDaysBitmask,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (enabled != null) 'enabled': enabled,
      if (soundId != null) 'sound_id': soundId,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsCompanion copyWith({
    Value<String>? id,
    Value<int>? notificationId,
    Value<String>? label,
    Value<int>? targetTimeMinutes,
    Value<String>? repeatKind,
    Value<int>? repeatDaysBitmask,
    Value<int>? snoozeMinutes,
    Value<bool>? enabled,
    Value<String?>? soundId,
    Value<int>? createdAtUtcMs,
    Value<int>? rowid,
  }) {
    return AlarmsCompanion(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      label: label ?? this.label,
      targetTimeMinutes: targetTimeMinutes ?? this.targetTimeMinutes,
      repeatKind: repeatKind ?? this.repeatKind,
      repeatDaysBitmask: repeatDaysBitmask ?? this.repeatDaysBitmask,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      enabled: enabled ?? this.enabled,
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
    if (targetTimeMinutes.present) {
      map['target_time_minutes'] = Variable<int>(targetTimeMinutes.value);
    }
    if (repeatKind.present) {
      map['repeat_kind'] = Variable<String>(repeatKind.value);
    }
    if (repeatDaysBitmask.present) {
      map['repeat_days_bitmask'] = Variable<int>(repeatDaysBitmask.value);
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
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
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('notificationId: $notificationId, ')
          ..write('label: $label, ')
          ..write('targetTimeMinutes: $targetTimeMinutes, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('repeatDaysBitmask: $repeatDaysBitmask, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('enabled: $enabled, ')
          ..write('soundId: $soundId, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClockEntriesTable extends ClockEntries
    with TableInfo<$ClockEntriesTable, ClockEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClockEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneIdMeta = const VerificationMeta(
    'timezoneId',
  );
  @override
  late final GeneratedColumn<String> timezoneId = GeneratedColumn<String>(
    'timezone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentLocationMeta = const VerificationMeta(
    'isCurrentLocation',
  );
  @override
  late final GeneratedColumn<bool> isCurrentLocation = GeneratedColumn<bool>(
    'is_current_location',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current_location" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    displayName,
    timezoneId,
    isCurrentLocation,
    displayOrder,
    createdAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clock_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClockEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('timezone_id')) {
      context.handle(
        _timezoneIdMeta,
        timezoneId.isAcceptableOrUnknown(data['timezone_id']!, _timezoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneIdMeta);
    }
    if (data.containsKey('is_current_location')) {
      context.handle(
        _isCurrentLocationMeta,
        isCurrentLocation.isAcceptableOrUnknown(
          data['is_current_location']!,
          _isCurrentLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCurrentLocationMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
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
  ClockEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClockEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      timezoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone_id'],
      )!,
      isCurrentLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current_location'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
    );
  }

  @override
  $ClockEntriesTable createAlias(String alias) {
    return $ClockEntriesTable(attachedDatabase, alias);
  }
}

class ClockEntryRow extends DataClass implements Insertable<ClockEntryRow> {
  final String id;
  final String displayName;
  final String timezoneId;
  final bool isCurrentLocation;
  final int displayOrder;
  final int createdAtUtcMs;
  const ClockEntryRow({
    required this.id,
    required this.displayName,
    required this.timezoneId,
    required this.isCurrentLocation,
    required this.displayOrder,
    required this.createdAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['timezone_id'] = Variable<String>(timezoneId);
    map['is_current_location'] = Variable<bool>(isCurrentLocation);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    return map;
  }

  ClockEntriesCompanion toCompanion(bool nullToAbsent) {
    return ClockEntriesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      timezoneId: Value(timezoneId),
      isCurrentLocation: Value(isCurrentLocation),
      displayOrder: Value(displayOrder),
      createdAtUtcMs: Value(createdAtUtcMs),
    );
  }

  factory ClockEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClockEntryRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      timezoneId: serializer.fromJson<String>(json['timezoneId']),
      isCurrentLocation: serializer.fromJson<bool>(json['isCurrentLocation']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'timezoneId': serializer.toJson<String>(timezoneId),
      'isCurrentLocation': serializer.toJson<bool>(isCurrentLocation),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
    };
  }

  ClockEntryRow copyWith({
    String? id,
    String? displayName,
    String? timezoneId,
    bool? isCurrentLocation,
    int? displayOrder,
    int? createdAtUtcMs,
  }) => ClockEntryRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    timezoneId: timezoneId ?? this.timezoneId,
    isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
  );
  ClockEntryRow copyWithCompanion(ClockEntriesCompanion data) {
    return ClockEntryRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      timezoneId: data.timezoneId.present
          ? data.timezoneId.value
          : this.timezoneId,
      isCurrentLocation: data.isCurrentLocation.present
          ? data.isCurrentLocation.value
          : this.isCurrentLocation,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClockEntryRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('timezoneId: $timezoneId, ')
          ..write('isCurrentLocation: $isCurrentLocation, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAtUtcMs: $createdAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    timezoneId,
    isCurrentLocation,
    displayOrder,
    createdAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClockEntryRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.timezoneId == this.timezoneId &&
          other.isCurrentLocation == this.isCurrentLocation &&
          other.displayOrder == this.displayOrder &&
          other.createdAtUtcMs == this.createdAtUtcMs);
}

class ClockEntriesCompanion extends UpdateCompanion<ClockEntryRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> timezoneId;
  final Value<bool> isCurrentLocation;
  final Value<int> displayOrder;
  final Value<int> createdAtUtcMs;
  final Value<int> rowid;
  const ClockEntriesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.timezoneId = const Value.absent(),
    this.isCurrentLocation = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClockEntriesCompanion.insert({
    required String id,
    required String displayName,
    required String timezoneId,
    required bool isCurrentLocation,
    required int displayOrder,
    required int createdAtUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       timezoneId = Value(timezoneId),
       isCurrentLocation = Value(isCurrentLocation),
       displayOrder = Value(displayOrder),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<ClockEntryRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? timezoneId,
    Expression<bool>? isCurrentLocation,
    Expression<int>? displayOrder,
    Expression<int>? createdAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (timezoneId != null) 'timezone_id': timezoneId,
      if (isCurrentLocation != null) 'is_current_location': isCurrentLocation,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClockEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? timezoneId,
    Value<bool>? isCurrentLocation,
    Value<int>? displayOrder,
    Value<int>? createdAtUtcMs,
    Value<int>? rowid,
  }) {
    return ClockEntriesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      timezoneId: timezoneId ?? this.timezoneId,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      displayOrder: displayOrder ?? this.displayOrder,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (timezoneId.present) {
      map['timezone_id'] = Variable<String>(timezoneId.value);
    }
    if (isCurrentLocation.present) {
      map['is_current_location'] = Variable<bool>(isCurrentLocation.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
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
    return (StringBuffer('ClockEntriesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('timezoneId: $timezoneId, ')
          ..write('isCurrentLocation: $isCurrentLocation, ')
          ..write('displayOrder: $displayOrder, ')
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
  late final $PresetsTable presets = $PresetsTable(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  late final $ClockEntriesTable clockEntries = $ClockEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    timers,
    presets,
    alarms,
    clockEntries,
  ];
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
typedef $$PresetsTableCreateCompanionBuilder =
    PresetsCompanion Function({
      required String id,
      required String label,
      required int durationMs,
      Value<String?> soundId,
      required int createdAtUtcMs,
      Value<int> rowid,
    });
typedef $$PresetsTableUpdateCompanionBuilder =
    PresetsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<int> durationMs,
      Value<String?> soundId,
      Value<int> createdAtUtcMs,
      Value<int> rowid,
    });

class $$PresetsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
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

class $$PresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
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

class $$PresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundId =>
      $composableBuilder(column: $table.soundId, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );
}

class $$PresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresetsTable,
          PresetRow,
          $$PresetsTableFilterComposer,
          $$PresetsTableOrderingComposer,
          $$PresetsTableAnnotationComposer,
          $$PresetsTableCreateCompanionBuilder,
          $$PresetsTableUpdateCompanionBuilder,
          (PresetRow, BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>),
          PresetRow,
          PrefetchHooks Function()
        > {
  $$PresetsTableTableManager(_$AppDatabase db, $PresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> soundId = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresetsCompanion(
                id: id,
                label: label,
                durationMs: durationMs,
                soundId: soundId,
                createdAtUtcMs: createdAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required int durationMs,
                Value<String?> soundId = const Value.absent(),
                required int createdAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => PresetsCompanion.insert(
                id: id,
                label: label,
                durationMs: durationMs,
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

typedef $$PresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresetsTable,
      PresetRow,
      $$PresetsTableFilterComposer,
      $$PresetsTableOrderingComposer,
      $$PresetsTableAnnotationComposer,
      $$PresetsTableCreateCompanionBuilder,
      $$PresetsTableUpdateCompanionBuilder,
      (PresetRow, BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>),
      PresetRow,
      PrefetchHooks Function()
    >;
typedef $$AlarmsTableCreateCompanionBuilder =
    AlarmsCompanion Function({
      required String id,
      required int notificationId,
      required String label,
      required int targetTimeMinutes,
      required String repeatKind,
      required int repeatDaysBitmask,
      required int snoozeMinutes,
      required bool enabled,
      Value<String?> soundId,
      required int createdAtUtcMs,
      Value<int> rowid,
    });
typedef $$AlarmsTableUpdateCompanionBuilder =
    AlarmsCompanion Function({
      Value<String> id,
      Value<int> notificationId,
      Value<String> label,
      Value<int> targetTimeMinutes,
      Value<String> repeatKind,
      Value<int> repeatDaysBitmask,
      Value<int> snoozeMinutes,
      Value<bool> enabled,
      Value<String?> soundId,
      Value<int> createdAtUtcMs,
      Value<int> rowid,
    });

class $$AlarmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableFilterComposer({
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

  ColumnFilters<int> get targetTimeMinutes => $composableBuilder(
    column: $table.targetTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatDaysBitmask => $composableBuilder(
    column: $table.repeatDaysBitmask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
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

class $$AlarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableOrderingComposer({
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

  ColumnOrderings<int> get targetTimeMinutes => $composableBuilder(
    column: $table.targetTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatDaysBitmask => $composableBuilder(
    column: $table.repeatDaysBitmask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
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

class $$AlarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableAnnotationComposer({
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

  GeneratedColumn<int> get targetTimeMinutes => $composableBuilder(
    column: $table.targetTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatDaysBitmask => $composableBuilder(
    column: $table.repeatDaysBitmask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get soundId =>
      $composableBuilder(column: $table.soundId, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );
}

class $$AlarmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmsTable,
          AlarmRow,
          $$AlarmsTableFilterComposer,
          $$AlarmsTableOrderingComposer,
          $$AlarmsTableAnnotationComposer,
          $$AlarmsTableCreateCompanionBuilder,
          $$AlarmsTableUpdateCompanionBuilder,
          (AlarmRow, BaseReferences<_$AppDatabase, $AlarmsTable, AlarmRow>),
          AlarmRow,
          PrefetchHooks Function()
        > {
  $$AlarmsTableTableManager(_$AppDatabase db, $AlarmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> targetTimeMinutes = const Value.absent(),
                Value<String> repeatKind = const Value.absent(),
                Value<int> repeatDaysBitmask = const Value.absent(),
                Value<int> snoozeMinutes = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> soundId = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmsCompanion(
                id: id,
                notificationId: notificationId,
                label: label,
                targetTimeMinutes: targetTimeMinutes,
                repeatKind: repeatKind,
                repeatDaysBitmask: repeatDaysBitmask,
                snoozeMinutes: snoozeMinutes,
                enabled: enabled,
                soundId: soundId,
                createdAtUtcMs: createdAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int notificationId,
                required String label,
                required int targetTimeMinutes,
                required String repeatKind,
                required int repeatDaysBitmask,
                required int snoozeMinutes,
                required bool enabled,
                Value<String?> soundId = const Value.absent(),
                required int createdAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => AlarmsCompanion.insert(
                id: id,
                notificationId: notificationId,
                label: label,
                targetTimeMinutes: targetTimeMinutes,
                repeatKind: repeatKind,
                repeatDaysBitmask: repeatDaysBitmask,
                snoozeMinutes: snoozeMinutes,
                enabled: enabled,
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

typedef $$AlarmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmsTable,
      AlarmRow,
      $$AlarmsTableFilterComposer,
      $$AlarmsTableOrderingComposer,
      $$AlarmsTableAnnotationComposer,
      $$AlarmsTableCreateCompanionBuilder,
      $$AlarmsTableUpdateCompanionBuilder,
      (AlarmRow, BaseReferences<_$AppDatabase, $AlarmsTable, AlarmRow>),
      AlarmRow,
      PrefetchHooks Function()
    >;
typedef $$ClockEntriesTableCreateCompanionBuilder =
    ClockEntriesCompanion Function({
      required String id,
      required String displayName,
      required String timezoneId,
      required bool isCurrentLocation,
      required int displayOrder,
      required int createdAtUtcMs,
      Value<int> rowid,
    });
typedef $$ClockEntriesTableUpdateCompanionBuilder =
    ClockEntriesCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> timezoneId,
      Value<bool> isCurrentLocation,
      Value<int> displayOrder,
      Value<int> createdAtUtcMs,
      Value<int> rowid,
    });

class $$ClockEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ClockEntriesTable> {
  $$ClockEntriesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezoneId => $composableBuilder(
    column: $table.timezoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrentLocation => $composableBuilder(
    column: $table.isCurrentLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClockEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClockEntriesTable> {
  $$ClockEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezoneId => $composableBuilder(
    column: $table.timezoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrentLocation => $composableBuilder(
    column: $table.isCurrentLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClockEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClockEntriesTable> {
  $$ClockEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezoneId => $composableBuilder(
    column: $table.timezoneId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrentLocation => $composableBuilder(
    column: $table.isCurrentLocation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );
}

class $$ClockEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClockEntriesTable,
          ClockEntryRow,
          $$ClockEntriesTableFilterComposer,
          $$ClockEntriesTableOrderingComposer,
          $$ClockEntriesTableAnnotationComposer,
          $$ClockEntriesTableCreateCompanionBuilder,
          $$ClockEntriesTableUpdateCompanionBuilder,
          (
            ClockEntryRow,
            BaseReferences<_$AppDatabase, $ClockEntriesTable, ClockEntryRow>,
          ),
          ClockEntryRow,
          PrefetchHooks Function()
        > {
  $$ClockEntriesTableTableManager(_$AppDatabase db, $ClockEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClockEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClockEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClockEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> timezoneId = const Value.absent(),
                Value<bool> isCurrentLocation = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClockEntriesCompanion(
                id: id,
                displayName: displayName,
                timezoneId: timezoneId,
                isCurrentLocation: isCurrentLocation,
                displayOrder: displayOrder,
                createdAtUtcMs: createdAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String timezoneId,
                required bool isCurrentLocation,
                required int displayOrder,
                required int createdAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => ClockEntriesCompanion.insert(
                id: id,
                displayName: displayName,
                timezoneId: timezoneId,
                isCurrentLocation: isCurrentLocation,
                displayOrder: displayOrder,
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

typedef $$ClockEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClockEntriesTable,
      ClockEntryRow,
      $$ClockEntriesTableFilterComposer,
      $$ClockEntriesTableOrderingComposer,
      $$ClockEntriesTableAnnotationComposer,
      $$ClockEntriesTableCreateCompanionBuilder,
      $$ClockEntriesTableUpdateCompanionBuilder,
      (
        ClockEntryRow,
        BaseReferences<_$AppDatabase, $ClockEntriesTable, ClockEntryRow>,
      ),
      ClockEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimersTableTableManager get timers =>
      $$TimersTableTableManager(_db, _db.timers);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db, _db.presets);
  $$AlarmsTableTableManager get alarms =>
      $$AlarmsTableTableManager(_db, _db.alarms);
  $$ClockEntriesTableTableManager get clockEntries =>
      $$ClockEntriesTableTableManager(_db, _db.clockEntries);
}
