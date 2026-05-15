// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic_settings_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DiagnosticSettingsState {
  bool get enabled => throw _privateConstructorUsedError;

  /// Create a copy of DiagnosticSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagnosticSettingsStateCopyWith<DiagnosticSettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosticSettingsStateCopyWith<$Res> {
  factory $DiagnosticSettingsStateCopyWith(
    DiagnosticSettingsState value,
    $Res Function(DiagnosticSettingsState) then,
  ) = _$DiagnosticSettingsStateCopyWithImpl<$Res, DiagnosticSettingsState>;
  @useResult
  $Res call({bool enabled});
}

/// @nodoc
class _$DiagnosticSettingsStateCopyWithImpl<
  $Res,
  $Val extends DiagnosticSettingsState
>
    implements $DiagnosticSettingsStateCopyWith<$Res> {
  _$DiagnosticSettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagnosticSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? enabled = null}) {
    return _then(
      _value.copyWith(
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiagnosticSettingsStateImplCopyWith<$Res>
    implements $DiagnosticSettingsStateCopyWith<$Res> {
  factory _$$DiagnosticSettingsStateImplCopyWith(
    _$DiagnosticSettingsStateImpl value,
    $Res Function(_$DiagnosticSettingsStateImpl) then,
  ) = __$$DiagnosticSettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool enabled});
}

/// @nodoc
class __$$DiagnosticSettingsStateImplCopyWithImpl<$Res>
    extends
        _$DiagnosticSettingsStateCopyWithImpl<
          $Res,
          _$DiagnosticSettingsStateImpl
        >
    implements _$$DiagnosticSettingsStateImplCopyWith<$Res> {
  __$$DiagnosticSettingsStateImplCopyWithImpl(
    _$DiagnosticSettingsStateImpl _value,
    $Res Function(_$DiagnosticSettingsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiagnosticSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? enabled = null}) {
    return _then(
      _$DiagnosticSettingsStateImpl(
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$DiagnosticSettingsStateImpl implements _DiagnosticSettingsState {
  const _$DiagnosticSettingsStateImpl({required this.enabled});

  @override
  final bool enabled;

  @override
  String toString() {
    return 'DiagnosticSettingsState(enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosticSettingsStateImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @override
  int get hashCode => Object.hash(runtimeType, enabled);

  /// Create a copy of DiagnosticSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosticSettingsStateImplCopyWith<_$DiagnosticSettingsStateImpl>
  get copyWith =>
      __$$DiagnosticSettingsStateImplCopyWithImpl<
        _$DiagnosticSettingsStateImpl
      >(this, _$identity);
}

abstract class _DiagnosticSettingsState implements DiagnosticSettingsState {
  const factory _DiagnosticSettingsState({required final bool enabled}) =
      _$DiagnosticSettingsStateImpl;

  @override
  bool get enabled;

  /// Create a copy of DiagnosticSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagnosticSettingsStateImplCopyWith<_$DiagnosticSettingsStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
