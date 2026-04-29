// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimerEntity {
  String get id => throw _privateConstructorUsedError;
  int get notificationId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  Duration get duration => throw _privateConstructorUsedError;
  DateTime? get endAt => throw _privateConstructorUsedError;
  Duration? get pausedRemaining => throw _privateConstructorUsedError;
  TimerStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of TimerEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimerEntityCopyWith<TimerEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimerEntityCopyWith<$Res> {
  factory $TimerEntityCopyWith(
    TimerEntity value,
    $Res Function(TimerEntity) then,
  ) = _$TimerEntityCopyWithImpl<$Res, TimerEntity>;
  @useResult
  $Res call({
    String id,
    int notificationId,
    String label,
    Duration duration,
    DateTime? endAt,
    Duration? pausedRemaining,
    TimerStatus status,
    DateTime createdAt,
  });
}

/// @nodoc
class _$TimerEntityCopyWithImpl<$Res, $Val extends TimerEntity>
    implements $TimerEntityCopyWith<$Res> {
  _$TimerEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimerEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notificationId = null,
    Object? label = null,
    Object? duration = null,
    Object? endAt = freezed,
    Object? pausedRemaining = freezed,
    Object? status = null,
    Object? createdAt = null,
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
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as Duration,
            endAt: freezed == endAt
                ? _value.endAt
                : endAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pausedRemaining: freezed == pausedRemaining
                ? _value.pausedRemaining
                : pausedRemaining // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TimerStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimerEntityImplCopyWith<$Res>
    implements $TimerEntityCopyWith<$Res> {
  factory _$$TimerEntityImplCopyWith(
    _$TimerEntityImpl value,
    $Res Function(_$TimerEntityImpl) then,
  ) = __$$TimerEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int notificationId,
    String label,
    Duration duration,
    DateTime? endAt,
    Duration? pausedRemaining,
    TimerStatus status,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$TimerEntityImplCopyWithImpl<$Res>
    extends _$TimerEntityCopyWithImpl<$Res, _$TimerEntityImpl>
    implements _$$TimerEntityImplCopyWith<$Res> {
  __$$TimerEntityImplCopyWithImpl(
    _$TimerEntityImpl _value,
    $Res Function(_$TimerEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notificationId = null,
    Object? label = null,
    Object? duration = null,
    Object? endAt = freezed,
    Object? pausedRemaining = freezed,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$TimerEntityImpl(
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
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        endAt: freezed == endAt
            ? _value.endAt
            : endAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pausedRemaining: freezed == pausedRemaining
            ? _value.pausedRemaining
            : pausedRemaining // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TimerStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$TimerEntityImpl implements _TimerEntity {
  const _$TimerEntityImpl({
    required this.id,
    required this.notificationId,
    required this.label,
    required this.duration,
    required this.endAt,
    required this.pausedRemaining,
    required this.status,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final int notificationId;
  @override
  final String label;
  @override
  final Duration duration;
  @override
  final DateTime? endAt;
  @override
  final Duration? pausedRemaining;
  @override
  final TimerStatus status;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'TimerEntity(id: $id, notificationId: $notificationId, label: $label, duration: $duration, endAt: $endAt, pausedRemaining: $pausedRemaining, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimerEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.endAt, endAt) || other.endAt == endAt) &&
            (identical(other.pausedRemaining, pausedRemaining) ||
                other.pausedRemaining == pausedRemaining) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    notificationId,
    label,
    duration,
    endAt,
    pausedRemaining,
    status,
    createdAt,
  );

  /// Create a copy of TimerEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimerEntityImplCopyWith<_$TimerEntityImpl> get copyWith =>
      __$$TimerEntityImplCopyWithImpl<_$TimerEntityImpl>(this, _$identity);
}

abstract class _TimerEntity implements TimerEntity {
  const factory _TimerEntity({
    required final String id,
    required final int notificationId,
    required final String label,
    required final Duration duration,
    required final DateTime? endAt,
    required final Duration? pausedRemaining,
    required final TimerStatus status,
    required final DateTime createdAt,
  }) = _$TimerEntityImpl;

  @override
  String get id;
  @override
  int get notificationId;
  @override
  String get label;
  @override
  Duration get duration;
  @override
  DateTime? get endAt;
  @override
  Duration? get pausedRemaining;
  @override
  TimerStatus get status;
  @override
  DateTime get createdAt;

  /// Create a copy of TimerEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimerEntityImplCopyWith<_$TimerEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
