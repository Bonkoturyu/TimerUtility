// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clock_time.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ClockTime {
  DateTime get now => throw _privateConstructorUsedError;
  String get timezoneId => throw _privateConstructorUsedError;

  /// Create a copy of ClockTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClockTimeCopyWith<ClockTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClockTimeCopyWith<$Res> {
  factory $ClockTimeCopyWith(ClockTime value, $Res Function(ClockTime) then) =
      _$ClockTimeCopyWithImpl<$Res, ClockTime>;
  @useResult
  $Res call({DateTime now, String timezoneId});
}

/// @nodoc
class _$ClockTimeCopyWithImpl<$Res, $Val extends ClockTime>
    implements $ClockTimeCopyWith<$Res> {
  _$ClockTimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClockTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? now = null, Object? timezoneId = null}) {
    return _then(
      _value.copyWith(
            now: null == now
                ? _value.now
                : now // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            timezoneId: null == timezoneId
                ? _value.timezoneId
                : timezoneId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClockTimeImplCopyWith<$Res>
    implements $ClockTimeCopyWith<$Res> {
  factory _$$ClockTimeImplCopyWith(
    _$ClockTimeImpl value,
    $Res Function(_$ClockTimeImpl) then,
  ) = __$$ClockTimeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime now, String timezoneId});
}

/// @nodoc
class __$$ClockTimeImplCopyWithImpl<$Res>
    extends _$ClockTimeCopyWithImpl<$Res, _$ClockTimeImpl>
    implements _$$ClockTimeImplCopyWith<$Res> {
  __$$ClockTimeImplCopyWithImpl(
    _$ClockTimeImpl _value,
    $Res Function(_$ClockTimeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClockTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? now = null, Object? timezoneId = null}) {
    return _then(
      _$ClockTimeImpl(
        now: null == now
            ? _value.now
            : now // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        timezoneId: null == timezoneId
            ? _value.timezoneId
            : timezoneId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ClockTimeImpl implements _ClockTime {
  const _$ClockTimeImpl({required this.now, required this.timezoneId});

  @override
  final DateTime now;
  @override
  final String timezoneId;

  @override
  String toString() {
    return 'ClockTime(now: $now, timezoneId: $timezoneId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClockTimeImpl &&
            (identical(other.now, now) || other.now == now) &&
            (identical(other.timezoneId, timezoneId) ||
                other.timezoneId == timezoneId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, now, timezoneId);

  /// Create a copy of ClockTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClockTimeImplCopyWith<_$ClockTimeImpl> get copyWith =>
      __$$ClockTimeImplCopyWithImpl<_$ClockTimeImpl>(this, _$identity);
}

abstract class _ClockTime implements ClockTime {
  const factory _ClockTime({
    required final DateTime now,
    required final String timezoneId,
  }) = _$ClockTimeImpl;

  @override
  DateTime get now;
  @override
  String get timezoneId;

  /// Create a copy of ClockTime
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClockTimeImplCopyWith<_$ClockTimeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
