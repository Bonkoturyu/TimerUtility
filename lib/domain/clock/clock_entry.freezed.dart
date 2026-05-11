// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clock_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ClockEntry {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get timezoneId => throw _privateConstructorUsedError;
  bool get isCurrentLocation => throw _privateConstructorUsedError;
  int get displayOrder => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of ClockEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClockEntryCopyWith<ClockEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClockEntryCopyWith<$Res> {
  factory $ClockEntryCopyWith(
    ClockEntry value,
    $Res Function(ClockEntry) then,
  ) = _$ClockEntryCopyWithImpl<$Res, ClockEntry>;
  @useResult
  $Res call({
    String id,
    String displayName,
    String timezoneId,
    bool isCurrentLocation,
    int displayOrder,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ClockEntryCopyWithImpl<$Res, $Val extends ClockEntry>
    implements $ClockEntryCopyWith<$Res> {
  _$ClockEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClockEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? timezoneId = null,
    Object? isCurrentLocation = null,
    Object? displayOrder = null,
    Object? createdAt = null,
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
            timezoneId: null == timezoneId
                ? _value.timezoneId
                : timezoneId // ignore: cast_nullable_to_non_nullable
                      as String,
            isCurrentLocation: null == isCurrentLocation
                ? _value.isCurrentLocation
                : isCurrentLocation // ignore: cast_nullable_to_non_nullable
                      as bool,
            displayOrder: null == displayOrder
                ? _value.displayOrder
                : displayOrder // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$ClockEntryImplCopyWith<$Res>
    implements $ClockEntryCopyWith<$Res> {
  factory _$$ClockEntryImplCopyWith(
    _$ClockEntryImpl value,
    $Res Function(_$ClockEntryImpl) then,
  ) = __$$ClockEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String displayName,
    String timezoneId,
    bool isCurrentLocation,
    int displayOrder,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ClockEntryImplCopyWithImpl<$Res>
    extends _$ClockEntryCopyWithImpl<$Res, _$ClockEntryImpl>
    implements _$$ClockEntryImplCopyWith<$Res> {
  __$$ClockEntryImplCopyWithImpl(
    _$ClockEntryImpl _value,
    $Res Function(_$ClockEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClockEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? timezoneId = null,
    Object? isCurrentLocation = null,
    Object? displayOrder = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ClockEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        timezoneId: null == timezoneId
            ? _value.timezoneId
            : timezoneId // ignore: cast_nullable_to_non_nullable
                  as String,
        isCurrentLocation: null == isCurrentLocation
            ? _value.isCurrentLocation
            : isCurrentLocation // ignore: cast_nullable_to_non_nullable
                  as bool,
        displayOrder: null == displayOrder
            ? _value.displayOrder
            : displayOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$ClockEntryImpl implements _ClockEntry {
  const _$ClockEntryImpl({
    required this.id,
    required this.displayName,
    required this.timezoneId,
    required this.isCurrentLocation,
    required this.displayOrder,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String displayName;
  @override
  final String timezoneId;
  @override
  final bool isCurrentLocation;
  @override
  final int displayOrder;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ClockEntry(id: $id, displayName: $displayName, timezoneId: $timezoneId, isCurrentLocation: $isCurrentLocation, displayOrder: $displayOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClockEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.timezoneId, timezoneId) ||
                other.timezoneId == timezoneId) &&
            (identical(other.isCurrentLocation, isCurrentLocation) ||
                other.isCurrentLocation == isCurrentLocation) &&
            (identical(other.displayOrder, displayOrder) ||
                other.displayOrder == displayOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    displayName,
    timezoneId,
    isCurrentLocation,
    displayOrder,
    createdAt,
  );

  /// Create a copy of ClockEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClockEntryImplCopyWith<_$ClockEntryImpl> get copyWith =>
      __$$ClockEntryImplCopyWithImpl<_$ClockEntryImpl>(this, _$identity);
}

abstract class _ClockEntry implements ClockEntry {
  const factory _ClockEntry({
    required final String id,
    required final String displayName,
    required final String timezoneId,
    required final bool isCurrentLocation,
    required final int displayOrder,
    required final DateTime createdAt,
  }) = _$ClockEntryImpl;

  @override
  String get id;
  @override
  String get displayName;
  @override
  String get timezoneId;
  @override
  bool get isCurrentLocation;
  @override
  int get displayOrder;
  @override
  DateTime get createdAt;

  /// Create a copy of ClockEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClockEntryImplCopyWith<_$ClockEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
