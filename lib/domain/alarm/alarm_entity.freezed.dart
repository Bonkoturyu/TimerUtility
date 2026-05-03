// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AlarmEntity {
  String get id => throw _privateConstructorUsedError;
  int get notificationId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  TimeOfDayValue get targetTime => throw _privateConstructorUsedError;
  AlarmRepeat get repeat => throw _privateConstructorUsedError;
  int get snoozeMinutes => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get soundId => throw _privateConstructorUsedError;

  /// Create a copy of AlarmEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlarmEntityCopyWith<AlarmEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlarmEntityCopyWith<$Res> {
  factory $AlarmEntityCopyWith(
    AlarmEntity value,
    $Res Function(AlarmEntity) then,
  ) = _$AlarmEntityCopyWithImpl<$Res, AlarmEntity>;
  @useResult
  $Res call({
    String id,
    int notificationId,
    String label,
    TimeOfDayValue targetTime,
    AlarmRepeat repeat,
    int snoozeMinutes,
    bool enabled,
    DateTime createdAt,
    String? soundId,
  });
}

/// @nodoc
class _$AlarmEntityCopyWithImpl<$Res, $Val extends AlarmEntity>
    implements $AlarmEntityCopyWith<$Res> {
  _$AlarmEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlarmEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notificationId = null,
    Object? label = null,
    Object? targetTime = null,
    Object? repeat = null,
    Object? snoozeMinutes = null,
    Object? enabled = null,
    Object? createdAt = null,
    Object? soundId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            notificationId: null == notificationId
                ? _value.notificationId
                : notificationId // ignore: cast_nullable_to_non_nullable
                      as int,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            targetTime: null == targetTime
                ? _value.targetTime
                : targetTime // ignore: cast_nullable_to_non_nullable
                      as TimeOfDayValue,
            repeat: null == repeat
                ? _value.repeat
                : repeat // ignore: cast_nullable_to_non_nullable
                      as AlarmRepeat,
            snoozeMinutes: null == snoozeMinutes
                ? _value.snoozeMinutes
                : snoozeMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            soundId: freezed == soundId
                ? _value.soundId
                : soundId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlarmEntityImplCopyWith<$Res>
    implements $AlarmEntityCopyWith<$Res> {
  factory _$$AlarmEntityImplCopyWith(
    _$AlarmEntityImpl value,
    $Res Function(_$AlarmEntityImpl) then,
  ) = __$$AlarmEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int notificationId,
    String label,
    TimeOfDayValue targetTime,
    AlarmRepeat repeat,
    int snoozeMinutes,
    bool enabled,
    DateTime createdAt,
    String? soundId,
  });
}

/// @nodoc
class __$$AlarmEntityImplCopyWithImpl<$Res>
    extends _$AlarmEntityCopyWithImpl<$Res, _$AlarmEntityImpl>
    implements _$$AlarmEntityImplCopyWith<$Res> {
  __$$AlarmEntityImplCopyWithImpl(
    _$AlarmEntityImpl _value,
    $Res Function(_$AlarmEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlarmEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notificationId = null,
    Object? label = null,
    Object? targetTime = null,
    Object? repeat = null,
    Object? snoozeMinutes = null,
    Object? enabled = null,
    Object? createdAt = null,
    Object? soundId = freezed,
  }) {
    return _then(
      _$AlarmEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        notificationId: null == notificationId
            ? _value.notificationId
            : notificationId // ignore: cast_nullable_to_non_nullable
                  as int,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        targetTime: null == targetTime
            ? _value.targetTime
            : targetTime // ignore: cast_nullable_to_non_nullable
                  as TimeOfDayValue,
        repeat: null == repeat
            ? _value.repeat
            : repeat // ignore: cast_nullable_to_non_nullable
                  as AlarmRepeat,
        snoozeMinutes: null == snoozeMinutes
            ? _value.snoozeMinutes
            : snoozeMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        soundId: freezed == soundId
            ? _value.soundId
            : soundId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AlarmEntityImpl implements _AlarmEntity {
  const _$AlarmEntityImpl({
    required this.id,
    required this.notificationId,
    required this.label,
    required this.targetTime,
    required this.repeat,
    required this.snoozeMinutes,
    required this.enabled,
    required this.createdAt,
    this.soundId,
  });

  @override
  final String id;
  @override
  final int notificationId;
  @override
  final String label;
  @override
  final TimeOfDayValue targetTime;
  @override
  final AlarmRepeat repeat;
  @override
  final int snoozeMinutes;
  @override
  final bool enabled;
  @override
  final DateTime createdAt;
  @override
  final String? soundId;

  @override
  String toString() {
    return 'AlarmEntity(id: $id, notificationId: $notificationId, label: $label, targetTime: $targetTime, repeat: $repeat, snoozeMinutes: $snoozeMinutes, enabled: $enabled, createdAt: $createdAt, soundId: $soundId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlarmEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.targetTime, targetTime) ||
                other.targetTime == targetTime) &&
            (identical(other.repeat, repeat) || other.repeat == repeat) &&
            (identical(other.snoozeMinutes, snoozeMinutes) ||
                other.snoozeMinutes == snoozeMinutes) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.soundId, soundId) || other.soundId == soundId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    notificationId,
    label,
    targetTime,
    repeat,
    snoozeMinutes,
    enabled,
    createdAt,
    soundId,
  );

  /// Create a copy of AlarmEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlarmEntityImplCopyWith<_$AlarmEntityImpl> get copyWith =>
      __$$AlarmEntityImplCopyWithImpl<_$AlarmEntityImpl>(this, _$identity);
}

abstract class _AlarmEntity implements AlarmEntity {
  const factory _AlarmEntity({
    required final String id,
    required final int notificationId,
    required final String label,
    required final TimeOfDayValue targetTime,
    required final AlarmRepeat repeat,
    required final int snoozeMinutes,
    required final bool enabled,
    required final DateTime createdAt,
    final String? soundId,
  }) = _$AlarmEntityImpl;

  @override
  String get id;
  @override
  int get notificationId;
  @override
  String get label;
  @override
  TimeOfDayValue get targetTime;
  @override
  AlarmRepeat get repeat;
  @override
  int get snoozeMinutes;
  @override
  bool get enabled;
  @override
  DateTime get createdAt;
  @override
  String? get soundId;

  /// Create a copy of AlarmEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlarmEntityImplCopyWith<_$AlarmEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
