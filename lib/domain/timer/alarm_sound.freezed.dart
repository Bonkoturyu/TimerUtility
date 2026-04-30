// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_sound.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AlarmSound {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get assetPath => throw _privateConstructorUsedError;

  /// Create a copy of AlarmSound
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlarmSoundCopyWith<AlarmSound> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlarmSoundCopyWith<$Res> {
  factory $AlarmSoundCopyWith(
    AlarmSound value,
    $Res Function(AlarmSound) then,
  ) = _$AlarmSoundCopyWithImpl<$Res, AlarmSound>;
  @useResult
  $Res call({String id, String displayName, String assetPath});
}

/// @nodoc
class _$AlarmSoundCopyWithImpl<$Res, $Val extends AlarmSound>
    implements $AlarmSoundCopyWith<$Res> {
  _$AlarmSoundCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlarmSound
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? assetPath = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            assetPath: null == assetPath
                ? _value.assetPath
                : assetPath // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlarmSoundImplCopyWith<$Res>
    implements $AlarmSoundCopyWith<$Res> {
  factory _$$AlarmSoundImplCopyWith(
    _$AlarmSoundImpl value,
    $Res Function(_$AlarmSoundImpl) then,
  ) = __$$AlarmSoundImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String displayName, String assetPath});
}

/// @nodoc
class __$$AlarmSoundImplCopyWithImpl<$Res>
    extends _$AlarmSoundCopyWithImpl<$Res, _$AlarmSoundImpl>
    implements _$$AlarmSoundImplCopyWith<$Res> {
  __$$AlarmSoundImplCopyWithImpl(
    _$AlarmSoundImpl _value,
    $Res Function(_$AlarmSoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlarmSound
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? assetPath = null,
  }) {
    return _then(
      _$AlarmSoundImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        assetPath: null == assetPath
            ? _value.assetPath
            : assetPath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AlarmSoundImpl implements _AlarmSound {
  const _$AlarmSoundImpl({
    required this.id,
    required this.displayName,
    required this.assetPath,
  });

  @override
  final String id;
  @override
  final String displayName;
  @override
  final String assetPath;

  @override
  String toString() {
    return 'AlarmSound(id: $id, displayName: $displayName, assetPath: $assetPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlarmSoundImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.assetPath, assetPath) ||
                other.assetPath == assetPath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, displayName, assetPath);

  /// Create a copy of AlarmSound
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlarmSoundImplCopyWith<_$AlarmSoundImpl> get copyWith =>
      __$$AlarmSoundImplCopyWithImpl<_$AlarmSoundImpl>(this, _$identity);
}

abstract class _AlarmSound implements AlarmSound {
  const factory _AlarmSound({
    required final String id,
    required final String displayName,
    required final String assetPath,
  }) = _$AlarmSoundImpl;

  @override
  String get id;
  @override
  String get displayName;
  @override
  String get assetPath;

  /// Create a copy of AlarmSound
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlarmSoundImplCopyWith<_$AlarmSoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
