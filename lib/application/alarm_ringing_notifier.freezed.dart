// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_ringing_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AlarmRingingState {
  bool get isPlaying => throw _privateConstructorUsedError;
  bool get snoozeRequested => throw _privateConstructorUsedError;
  String? get currentTimerId => throw _privateConstructorUsedError;
  String? get currentSoundId => throw _privateConstructorUsedError;

  /// Create a copy of AlarmRingingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlarmRingingStateCopyWith<AlarmRingingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlarmRingingStateCopyWith<$Res> {
  factory $AlarmRingingStateCopyWith(
    AlarmRingingState value,
    $Res Function(AlarmRingingState) then,
  ) = _$AlarmRingingStateCopyWithImpl<$Res, AlarmRingingState>;
  @useResult
  $Res call({
    bool isPlaying,
    bool snoozeRequested,
    String? currentTimerId,
    String? currentSoundId,
  });
}

/// @nodoc
class _$AlarmRingingStateCopyWithImpl<$Res, $Val extends AlarmRingingState>
    implements $AlarmRingingStateCopyWith<$Res> {
  _$AlarmRingingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlarmRingingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPlaying = null,
    Object? snoozeRequested = null,
    Object? currentTimerId = freezed,
    Object? currentSoundId = freezed,
  }) {
    return _then(
      _value.copyWith(
            isPlaying: null == isPlaying
                ? _value.isPlaying
                : isPlaying // ignore: cast_nullable_to_non_nullable
                      as bool,
            snoozeRequested: null == snoozeRequested
                ? _value.snoozeRequested
                : snoozeRequested // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentTimerId: freezed == currentTimerId
                ? _value.currentTimerId
                : currentTimerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentSoundId: freezed == currentSoundId
                ? _value.currentSoundId
                : currentSoundId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlarmRingingStateImplCopyWith<$Res>
    implements $AlarmRingingStateCopyWith<$Res> {
  factory _$$AlarmRingingStateImplCopyWith(
    _$AlarmRingingStateImpl value,
    $Res Function(_$AlarmRingingStateImpl) then,
  ) = __$$AlarmRingingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isPlaying,
    bool snoozeRequested,
    String? currentTimerId,
    String? currentSoundId,
  });
}

/// @nodoc
class __$$AlarmRingingStateImplCopyWithImpl<$Res>
    extends _$AlarmRingingStateCopyWithImpl<$Res, _$AlarmRingingStateImpl>
    implements _$$AlarmRingingStateImplCopyWith<$Res> {
  __$$AlarmRingingStateImplCopyWithImpl(
    _$AlarmRingingStateImpl _value,
    $Res Function(_$AlarmRingingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlarmRingingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPlaying = null,
    Object? snoozeRequested = null,
    Object? currentTimerId = freezed,
    Object? currentSoundId = freezed,
  }) {
    return _then(
      _$AlarmRingingStateImpl(
        isPlaying: null == isPlaying
            ? _value.isPlaying
            : isPlaying // ignore: cast_nullable_to_non_nullable
                  as bool,
        snoozeRequested: null == snoozeRequested
            ? _value.snoozeRequested
            : snoozeRequested // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentTimerId: freezed == currentTimerId
            ? _value.currentTimerId
            : currentTimerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentSoundId: freezed == currentSoundId
            ? _value.currentSoundId
            : currentSoundId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AlarmRingingStateImpl implements _AlarmRingingState {
  const _$AlarmRingingStateImpl({
    required this.isPlaying,
    required this.snoozeRequested,
    this.currentTimerId,
    this.currentSoundId,
  });

  @override
  final bool isPlaying;
  @override
  final bool snoozeRequested;
  @override
  final String? currentTimerId;
  @override
  final String? currentSoundId;

  @override
  String toString() {
    return 'AlarmRingingState(isPlaying: $isPlaying, snoozeRequested: $snoozeRequested, currentTimerId: $currentTimerId, currentSoundId: $currentSoundId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlarmRingingStateImpl &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.snoozeRequested, snoozeRequested) ||
                other.snoozeRequested == snoozeRequested) &&
            (identical(other.currentTimerId, currentTimerId) ||
                other.currentTimerId == currentTimerId) &&
            (identical(other.currentSoundId, currentSoundId) ||
                other.currentSoundId == currentSoundId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isPlaying,
    snoozeRequested,
    currentTimerId,
    currentSoundId,
  );

  /// Create a copy of AlarmRingingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlarmRingingStateImplCopyWith<_$AlarmRingingStateImpl> get copyWith =>
      __$$AlarmRingingStateImplCopyWithImpl<_$AlarmRingingStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AlarmRingingState implements AlarmRingingState {
  const factory _AlarmRingingState({
    required final bool isPlaying,
    required final bool snoozeRequested,
    final String? currentTimerId,
    final String? currentSoundId,
  }) = _$AlarmRingingStateImpl;

  @override
  bool get isPlaying;
  @override
  bool get snoozeRequested;
  @override
  String? get currentTimerId;
  @override
  String? get currentSoundId;

  /// Create a copy of AlarmRingingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlarmRingingStateImplCopyWith<_$AlarmRingingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
