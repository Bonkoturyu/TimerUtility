import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

import 'preset.dart';

/// Default UUID v4 generator (separate from the service so tests can
/// inject a deterministic alternative).
String _defaultIdGenerator() => const Uuid().v4();

/// Domain service that constructs and validates [Preset] instances.
///
/// Mirrors the role of `TimerService.createIdle` / `TimerService` for
/// the Preset aggregate: id / createdAt allocation + bounds checking
/// in one place so the Notifier doesn't have to repeat invariants.
///
/// Invalid input throws [ArgumentError]; the type system rules out
/// nonsensical state transitions (Preset has no status / endAt fields).
class PresetService {
  PresetService({required Clock clock, String Function()? idGenerator})
    : _clock = clock,
      _idGenerator = idGenerator ?? _defaultIdGenerator;

  final Clock _clock;
  final String Function() _idGenerator;

  /// Mirrors `TimerService.maxDuration` / `maxLabelLength` so a Preset
  /// can never describe a Timer that the Timer aggregate would later
  /// reject.
  static const Duration maxDuration = Duration(hours: 99);
  static const int maxLabelLength = 50;

  /// Build a brand-new [Preset]. Throws [ArgumentError] when:
  ///   - `duration` is non-positive
  ///   - `duration` exceeds [maxDuration]
  ///   - `label.length` exceeds [maxLabelLength]
  Preset create({
    required String label,
    required Duration duration,
    String? soundId,
    String? id,
    DateTime? createdAt,
  }) {
    _validate(label: label, duration: duration);
    return Preset(
      id: id ?? _idGenerator(),
      label: label,
      duration: duration,
      soundId: soundId,
      createdAt: createdAt ?? _clock.now(),
    );
  }

  /// Returns a copy of [existing] with the given fields replaced.
  /// `id` and `createdAt` are preserved across edits — only the
  /// user-mutable fields are updated. Validation rules match [create].
  ///
  /// Pass explicit `null` for `soundId` to reset to "use catalog
  /// default"; omitting the parameter keeps the existing soundId.
  Preset update(
    Preset existing, {
    String? label,
    Duration? duration,
    Object? soundId = _sentinel,
  }) {
    final String nextLabel = label ?? existing.label;
    final Duration nextDuration = duration ?? existing.duration;
    _validate(label: nextLabel, duration: nextDuration);
    return Preset(
      id: existing.id,
      label: nextLabel,
      duration: nextDuration,
      soundId: identical(soundId, _sentinel)
          ? existing.soundId
          : soundId as String?,
      createdAt: existing.createdAt,
    );
  }

  void _validate({required String label, required Duration duration}) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'must be > 0');
    }
    if (duration > maxDuration) {
      throw ArgumentError.value(duration, 'duration', 'must be <= 99 hours');
    }
    if (label.length > maxLabelLength) {
      throw ArgumentError.value(
        label,
        'label',
        'must be <= $maxLabelLength characters',
      );
    }
  }

  /// Private sentinel that lets `update`'s `soundId` parameter
  /// distinguish "omitted" from "explicitly null" (used to clear
  /// the soundId override).
  static const Object _sentinel = Object();
}
