// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permission_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PermissionState {
  DomainPermissionStatus get postNotifications =>
      throw _privateConstructorUsedError;
  DomainPermissionStatus get scheduleExactAlarm =>
      throw _privateConstructorUsedError;
  DomainPermissionStatus get fullScreenIntent =>
      throw _privateConstructorUsedError;

  /// Create a copy of PermissionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PermissionStateCopyWith<PermissionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PermissionStateCopyWith<$Res> {
  factory $PermissionStateCopyWith(
    PermissionState value,
    $Res Function(PermissionState) then,
  ) = _$PermissionStateCopyWithImpl<$Res, PermissionState>;
  @useResult
  $Res call({
    DomainPermissionStatus postNotifications,
    DomainPermissionStatus scheduleExactAlarm,
    DomainPermissionStatus fullScreenIntent,
  });
}

/// @nodoc
class _$PermissionStateCopyWithImpl<$Res, $Val extends PermissionState>
    implements $PermissionStateCopyWith<$Res> {
  _$PermissionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PermissionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postNotifications = null,
    Object? scheduleExactAlarm = null,
    Object? fullScreenIntent = null,
  }) {
    return _then(
      _value.copyWith(
            postNotifications: null == postNotifications
                ? _value.postNotifications
                : postNotifications // ignore: cast_nullable_to_non_nullable
                      as DomainPermissionStatus,
            scheduleExactAlarm: null == scheduleExactAlarm
                ? _value.scheduleExactAlarm
                : scheduleExactAlarm // ignore: cast_nullable_to_non_nullable
                      as DomainPermissionStatus,
            fullScreenIntent: null == fullScreenIntent
                ? _value.fullScreenIntent
                : fullScreenIntent // ignore: cast_nullable_to_non_nullable
                      as DomainPermissionStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PermissionStateImplCopyWith<$Res>
    implements $PermissionStateCopyWith<$Res> {
  factory _$$PermissionStateImplCopyWith(
    _$PermissionStateImpl value,
    $Res Function(_$PermissionStateImpl) then,
  ) = __$$PermissionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DomainPermissionStatus postNotifications,
    DomainPermissionStatus scheduleExactAlarm,
    DomainPermissionStatus fullScreenIntent,
  });
}

/// @nodoc
class __$$PermissionStateImplCopyWithImpl<$Res>
    extends _$PermissionStateCopyWithImpl<$Res, _$PermissionStateImpl>
    implements _$$PermissionStateImplCopyWith<$Res> {
  __$$PermissionStateImplCopyWithImpl(
    _$PermissionStateImpl _value,
    $Res Function(_$PermissionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PermissionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postNotifications = null,
    Object? scheduleExactAlarm = null,
    Object? fullScreenIntent = null,
  }) {
    return _then(
      _$PermissionStateImpl(
        postNotifications: null == postNotifications
            ? _value.postNotifications
            : postNotifications // ignore: cast_nullable_to_non_nullable
                  as DomainPermissionStatus,
        scheduleExactAlarm: null == scheduleExactAlarm
            ? _value.scheduleExactAlarm
            : scheduleExactAlarm // ignore: cast_nullable_to_non_nullable
                  as DomainPermissionStatus,
        fullScreenIntent: null == fullScreenIntent
            ? _value.fullScreenIntent
            : fullScreenIntent // ignore: cast_nullable_to_non_nullable
                  as DomainPermissionStatus,
      ),
    );
  }
}

/// @nodoc

class _$PermissionStateImpl implements _PermissionState {
  const _$PermissionStateImpl({
    required this.postNotifications,
    required this.scheduleExactAlarm,
    required this.fullScreenIntent,
  });

  @override
  final DomainPermissionStatus postNotifications;
  @override
  final DomainPermissionStatus scheduleExactAlarm;
  @override
  final DomainPermissionStatus fullScreenIntent;

  @override
  String toString() {
    return 'PermissionState(postNotifications: $postNotifications, scheduleExactAlarm: $scheduleExactAlarm, fullScreenIntent: $fullScreenIntent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionStateImpl &&
            (identical(other.postNotifications, postNotifications) ||
                other.postNotifications == postNotifications) &&
            (identical(other.scheduleExactAlarm, scheduleExactAlarm) ||
                other.scheduleExactAlarm == scheduleExactAlarm) &&
            (identical(other.fullScreenIntent, fullScreenIntent) ||
                other.fullScreenIntent == fullScreenIntent));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    postNotifications,
    scheduleExactAlarm,
    fullScreenIntent,
  );

  /// Create a copy of PermissionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionStateImplCopyWith<_$PermissionStateImpl> get copyWith =>
      __$$PermissionStateImplCopyWithImpl<_$PermissionStateImpl>(
        this,
        _$identity,
      );
}

abstract class _PermissionState implements PermissionState {
  const factory _PermissionState({
    required final DomainPermissionStatus postNotifications,
    required final DomainPermissionStatus scheduleExactAlarm,
    required final DomainPermissionStatus fullScreenIntent,
  }) = _$PermissionStateImpl;

  @override
  DomainPermissionStatus get postNotifications;
  @override
  DomainPermissionStatus get scheduleExactAlarm;
  @override
  DomainPermissionStatus get fullScreenIntent;

  /// Create a copy of PermissionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PermissionStateImplCopyWith<_$PermissionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
