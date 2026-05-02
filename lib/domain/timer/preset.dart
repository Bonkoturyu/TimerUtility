import 'package:freezed_annotation/freezed_annotation.dart';

part 'preset.freezed.dart';

/// A user-managed timer template that can be turned into a real timer
/// in one tap from the bottom sheet on `TimerListScreen`.
///
/// Field invariants (enforced in `PresetService`, not by this VO):
///   - `duration` is in (Duration.zero, Duration(hours: 99)]
///   - `label.length <= 50`
///   - `soundId == null` means "use catalog default"; non-null values
///     should match an entry in `AlarmSoundCatalog`, but unknown ids
///     must fall back to default rather than throw (so removing a
///     bundled sound across releases stays backward compatible).
///
/// Notes:
///   - There is no status / endAt / pausedRemaining; a Preset is a
///     pure configuration template, not a live timer.
///   - `createdAt` is preserved across edits; only label / duration /
///     soundId are mutable.
@freezed
class Preset with _$Preset {
  const factory Preset({
    required String id,
    required String label,
    required Duration duration,
    required String? soundId,
    required DateTime createdAt,
  }) = _Preset;
}
