// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stopwatch_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StopwatchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )
    running,
    required TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )
    paused,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult? Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StopwatchIdle value) idle,
    required TResult Function(StopwatchRunning value) running,
    required TResult Function(StopwatchPaused value) paused,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StopwatchIdle value)? idle,
    TResult? Function(StopwatchRunning value)? running,
    TResult? Function(StopwatchPaused value)? paused,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StopwatchIdle value)? idle,
    TResult Function(StopwatchRunning value)? running,
    TResult Function(StopwatchPaused value)? paused,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StopwatchStateCopyWith<$Res> {
  factory $StopwatchStateCopyWith(
    StopwatchState value,
    $Res Function(StopwatchState) then,
  ) = _$StopwatchStateCopyWithImpl<$Res, StopwatchState>;
}

/// @nodoc
class _$StopwatchStateCopyWithImpl<$Res, $Val extends StopwatchState>
    implements $StopwatchStateCopyWith<$Res> {
  _$StopwatchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$StopwatchIdleImplCopyWith<$Res> {
  factory _$$StopwatchIdleImplCopyWith(
    _$StopwatchIdleImpl value,
    $Res Function(_$StopwatchIdleImpl) then,
  ) = __$$StopwatchIdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$StopwatchIdleImplCopyWithImpl<$Res>
    extends _$StopwatchStateCopyWithImpl<$Res, _$StopwatchIdleImpl>
    implements _$$StopwatchIdleImplCopyWith<$Res> {
  __$$StopwatchIdleImplCopyWithImpl(
    _$StopwatchIdleImpl _value,
    $Res Function(_$StopwatchIdleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$StopwatchIdleImpl implements StopwatchIdle {
  const _$StopwatchIdleImpl();

  @override
  String toString() {
    return 'StopwatchState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$StopwatchIdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )
    running,
    required TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )
    paused,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult? Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StopwatchIdle value) idle,
    required TResult Function(StopwatchRunning value) running,
    required TResult Function(StopwatchPaused value) paused,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StopwatchIdle value)? idle,
    TResult? Function(StopwatchRunning value)? running,
    TResult? Function(StopwatchPaused value)? paused,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StopwatchIdle value)? idle,
    TResult Function(StopwatchRunning value)? running,
    TResult Function(StopwatchPaused value)? paused,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class StopwatchIdle implements StopwatchState {
  const factory StopwatchIdle() = _$StopwatchIdleImpl;
}

/// @nodoc
abstract class _$$StopwatchRunningImplCopyWith<$Res> {
  factory _$$StopwatchRunningImplCopyWith(
    _$StopwatchRunningImpl value,
    $Res Function(_$StopwatchRunningImpl) then,
  ) = __$$StopwatchRunningImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    DateTime startedAt,
    Duration accumulatedBefore,
    List<LapRecord> laps,
  });
}

/// @nodoc
class __$$StopwatchRunningImplCopyWithImpl<$Res>
    extends _$StopwatchStateCopyWithImpl<$Res, _$StopwatchRunningImpl>
    implements _$$StopwatchRunningImplCopyWith<$Res> {
  __$$StopwatchRunningImplCopyWithImpl(
    _$StopwatchRunningImpl _value,
    $Res Function(_$StopwatchRunningImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startedAt = null,
    Object? accumulatedBefore = null,
    Object? laps = null,
  }) {
    return _then(
      _$StopwatchRunningImpl(
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        accumulatedBefore: null == accumulatedBefore
            ? _value.accumulatedBefore
            : accumulatedBefore // ignore: cast_nullable_to_non_nullable
                  as Duration,
        laps: null == laps
            ? _value._laps
            : laps // ignore: cast_nullable_to_non_nullable
                  as List<LapRecord>,
      ),
    );
  }
}

/// @nodoc

class _$StopwatchRunningImpl implements StopwatchRunning {
  const _$StopwatchRunningImpl({
    required this.startedAt,
    required this.accumulatedBefore,
    required final List<LapRecord> laps,
  }) : _laps = laps;

  @override
  final DateTime startedAt;
  @override
  final Duration accumulatedBefore;
  final List<LapRecord> _laps;
  @override
  List<LapRecord> get laps {
    if (_laps is EqualUnmodifiableListView) return _laps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_laps);
  }

  @override
  String toString() {
    return 'StopwatchState.running(startedAt: $startedAt, accumulatedBefore: $accumulatedBefore, laps: $laps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StopwatchRunningImpl &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.accumulatedBefore, accumulatedBefore) ||
                other.accumulatedBefore == accumulatedBefore) &&
            const DeepCollectionEquality().equals(other._laps, _laps));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    startedAt,
    accumulatedBefore,
    const DeepCollectionEquality().hash(_laps),
  );

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StopwatchRunningImplCopyWith<_$StopwatchRunningImpl> get copyWith =>
      __$$StopwatchRunningImplCopyWithImpl<_$StopwatchRunningImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )
    running,
    required TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )
    paused,
  }) {
    return running(startedAt, accumulatedBefore, laps);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult? Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
  }) {
    return running?.call(startedAt, accumulatedBefore, laps);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
    required TResult orElse(),
  }) {
    if (running != null) {
      return running(startedAt, accumulatedBefore, laps);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StopwatchIdle value) idle,
    required TResult Function(StopwatchRunning value) running,
    required TResult Function(StopwatchPaused value) paused,
  }) {
    return running(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StopwatchIdle value)? idle,
    TResult? Function(StopwatchRunning value)? running,
    TResult? Function(StopwatchPaused value)? paused,
  }) {
    return running?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StopwatchIdle value)? idle,
    TResult Function(StopwatchRunning value)? running,
    TResult Function(StopwatchPaused value)? paused,
    required TResult orElse(),
  }) {
    if (running != null) {
      return running(this);
    }
    return orElse();
  }
}

abstract class StopwatchRunning implements StopwatchState {
  const factory StopwatchRunning({
    required final DateTime startedAt,
    required final Duration accumulatedBefore,
    required final List<LapRecord> laps,
  }) = _$StopwatchRunningImpl;

  DateTime get startedAt;
  Duration get accumulatedBefore;
  List<LapRecord> get laps;

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StopwatchRunningImplCopyWith<_$StopwatchRunningImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StopwatchPausedImplCopyWith<$Res> {
  factory _$$StopwatchPausedImplCopyWith(
    _$StopwatchPausedImpl value,
    $Res Function(_$StopwatchPausedImpl) then,
  ) = __$$StopwatchPausedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DateTime pausedAt, Duration accumulated, List<LapRecord> laps});
}

/// @nodoc
class __$$StopwatchPausedImplCopyWithImpl<$Res>
    extends _$StopwatchStateCopyWithImpl<$Res, _$StopwatchPausedImpl>
    implements _$$StopwatchPausedImplCopyWith<$Res> {
  __$$StopwatchPausedImplCopyWithImpl(
    _$StopwatchPausedImpl _value,
    $Res Function(_$StopwatchPausedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pausedAt = null,
    Object? accumulated = null,
    Object? laps = null,
  }) {
    return _then(
      _$StopwatchPausedImpl(
        pausedAt: null == pausedAt
            ? _value.pausedAt
            : pausedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        accumulated: null == accumulated
            ? _value.accumulated
            : accumulated // ignore: cast_nullable_to_non_nullable
                  as Duration,
        laps: null == laps
            ? _value._laps
            : laps // ignore: cast_nullable_to_non_nullable
                  as List<LapRecord>,
      ),
    );
  }
}

/// @nodoc

class _$StopwatchPausedImpl implements StopwatchPaused {
  const _$StopwatchPausedImpl({
    required this.pausedAt,
    required this.accumulated,
    required final List<LapRecord> laps,
  }) : _laps = laps;

  @override
  final DateTime pausedAt;
  @override
  final Duration accumulated;
  final List<LapRecord> _laps;
  @override
  List<LapRecord> get laps {
    if (_laps is EqualUnmodifiableListView) return _laps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_laps);
  }

  @override
  String toString() {
    return 'StopwatchState.paused(pausedAt: $pausedAt, accumulated: $accumulated, laps: $laps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StopwatchPausedImpl &&
            (identical(other.pausedAt, pausedAt) ||
                other.pausedAt == pausedAt) &&
            (identical(other.accumulated, accumulated) ||
                other.accumulated == accumulated) &&
            const DeepCollectionEquality().equals(other._laps, _laps));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pausedAt,
    accumulated,
    const DeepCollectionEquality().hash(_laps),
  );

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StopwatchPausedImplCopyWith<_$StopwatchPausedImpl> get copyWith =>
      __$$StopwatchPausedImplCopyWithImpl<_$StopwatchPausedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )
    running,
    required TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )
    paused,
  }) {
    return paused(pausedAt, accumulated, laps);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult? Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
  }) {
    return paused?.call(pausedAt, accumulated, laps);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      DateTime startedAt,
      Duration accumulatedBefore,
      List<LapRecord> laps,
    )?
    running,
    TResult Function(
      DateTime pausedAt,
      Duration accumulated,
      List<LapRecord> laps,
    )?
    paused,
    required TResult orElse(),
  }) {
    if (paused != null) {
      return paused(pausedAt, accumulated, laps);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StopwatchIdle value) idle,
    required TResult Function(StopwatchRunning value) running,
    required TResult Function(StopwatchPaused value) paused,
  }) {
    return paused(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StopwatchIdle value)? idle,
    TResult? Function(StopwatchRunning value)? running,
    TResult? Function(StopwatchPaused value)? paused,
  }) {
    return paused?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StopwatchIdle value)? idle,
    TResult Function(StopwatchRunning value)? running,
    TResult Function(StopwatchPaused value)? paused,
    required TResult orElse(),
  }) {
    if (paused != null) {
      return paused(this);
    }
    return orElse();
  }
}

abstract class StopwatchPaused implements StopwatchState {
  const factory StopwatchPaused({
    required final DateTime pausedAt,
    required final Duration accumulated,
    required final List<LapRecord> laps,
  }) = _$StopwatchPausedImpl;

  DateTime get pausedAt;
  Duration get accumulated;
  List<LapRecord> get laps;

  /// Create a copy of StopwatchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StopwatchPausedImplCopyWith<_$StopwatchPausedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$LapRecord {
  int get index => throw _privateConstructorUsedError;
  Duration get splitTime => throw _privateConstructorUsedError;
  Duration get totalTime => throw _privateConstructorUsedError;
  DateTime get recordedAt => throw _privateConstructorUsedError;

  /// Create a copy of LapRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LapRecordCopyWith<LapRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LapRecordCopyWith<$Res> {
  factory $LapRecordCopyWith(LapRecord value, $Res Function(LapRecord) then) =
      _$LapRecordCopyWithImpl<$Res, LapRecord>;
  @useResult
  $Res call({
    int index,
    Duration splitTime,
    Duration totalTime,
    DateTime recordedAt,
  });
}

/// @nodoc
class _$LapRecordCopyWithImpl<$Res, $Val extends LapRecord>
    implements $LapRecordCopyWith<$Res> {
  _$LapRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LapRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? splitTime = null,
    Object? totalTime = null,
    Object? recordedAt = null,
  }) {
    return _then(
      _value.copyWith(
            index: null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as int,
            splitTime: null == splitTime
                ? _value.splitTime
                : splitTime // ignore: cast_nullable_to_non_nullable
                      as Duration,
            totalTime: null == totalTime
                ? _value.totalTime
                : totalTime // ignore: cast_nullable_to_non_nullable
                      as Duration,
            recordedAt: null == recordedAt
                ? _value.recordedAt
                : recordedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LapRecordImplCopyWith<$Res>
    implements $LapRecordCopyWith<$Res> {
  factory _$$LapRecordImplCopyWith(
    _$LapRecordImpl value,
    $Res Function(_$LapRecordImpl) then,
  ) = __$$LapRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int index,
    Duration splitTime,
    Duration totalTime,
    DateTime recordedAt,
  });
}

/// @nodoc
class __$$LapRecordImplCopyWithImpl<$Res>
    extends _$LapRecordCopyWithImpl<$Res, _$LapRecordImpl>
    implements _$$LapRecordImplCopyWith<$Res> {
  __$$LapRecordImplCopyWithImpl(
    _$LapRecordImpl _value,
    $Res Function(_$LapRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LapRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? splitTime = null,
    Object? totalTime = null,
    Object? recordedAt = null,
  }) {
    return _then(
      _$LapRecordImpl(
        index: null == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
        splitTime: null == splitTime
            ? _value.splitTime
            : splitTime // ignore: cast_nullable_to_non_nullable
                  as Duration,
        totalTime: null == totalTime
            ? _value.totalTime
            : totalTime // ignore: cast_nullable_to_non_nullable
                  as Duration,
        recordedAt: null == recordedAt
            ? _value.recordedAt
            : recordedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$LapRecordImpl implements _LapRecord {
  const _$LapRecordImpl({
    required this.index,
    required this.splitTime,
    required this.totalTime,
    required this.recordedAt,
  });

  @override
  final int index;
  @override
  final Duration splitTime;
  @override
  final Duration totalTime;
  @override
  final DateTime recordedAt;

  @override
  String toString() {
    return 'LapRecord(index: $index, splitTime: $splitTime, totalTime: $totalTime, recordedAt: $recordedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LapRecordImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.splitTime, splitTime) ||
                other.splitTime == splitTime) &&
            (identical(other.totalTime, totalTime) ||
                other.totalTime == totalTime) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, index, splitTime, totalTime, recordedAt);

  /// Create a copy of LapRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LapRecordImplCopyWith<_$LapRecordImpl> get copyWith =>
      __$$LapRecordImplCopyWithImpl<_$LapRecordImpl>(this, _$identity);
}

abstract class _LapRecord implements LapRecord {
  const factory _LapRecord({
    required final int index,
    required final Duration splitTime,
    required final Duration totalTime,
    required final DateTime recordedAt,
  }) = _$LapRecordImpl;

  @override
  int get index;
  @override
  Duration get splitTime;
  @override
  Duration get totalTime;
  @override
  DateTime get recordedAt;

  /// Create a copy of LapRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LapRecordImplCopyWith<_$LapRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
