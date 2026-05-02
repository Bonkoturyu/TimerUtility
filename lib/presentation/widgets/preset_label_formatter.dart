import '../../domain/shared/duration_formatter.dart';
import '../../l10n/app_localizations.dart';

/// Localized label for a preset. Plain Dart function rather than a
/// widget — callers (chips, list rows, dialog titles) all want the
/// resolved string up-front.
///
/// Strategy:
///   - If the user supplied a non-empty `label`, that wins. The
///     duration becomes a sub-label (caller can render it separately
///     if needed; this function intentionally only returns the primary
///     label).
///   - Otherwise the duration is rendered through ARB plural keys:
///     - 0 < d <  1 minute  → presetLabelSeconds(d.inSeconds)
///     - 1 minute <= d < 1 hour, multiple of 60s → presetLabelMinutes
///     - 1 hour <= d, multiple of 3600s → presetLabelHours
///     - mixed durations (e.g. 1h 30m) fall back to
///       `DurationFormatter.formatTimer` which produces a
///       language-neutral HH:MM:SS string.
///
/// The locale-specific singular / plural handling comes from the
/// gen-l10n plural blocks in `app_*.arb`.
String formatPresetLabel({
  required Duration duration,
  required AppLocalizations l,
  String userLabel = '',
}) {
  if (userLabel.isNotEmpty) return userLabel;
  return formatPresetDurationOnly(duration: duration, l: l);
}

/// Renders only the duration portion (used as the secondary label or
/// when there is no user-provided label). Same fallback rules as
/// [formatPresetLabel].
String formatPresetDurationOnly({
  required Duration duration,
  required AppLocalizations l,
}) {
  final int totalSeconds = duration.inSeconds;
  if (totalSeconds <= 0) {
    // Defensive: PresetService rejects this, but render something
    // rather than crashing if a stale entity slips through.
    return l.presetLabelSeconds(0);
  }

  if (duration.inMinutes == 0) {
    return l.presetLabelSeconds(totalSeconds);
  }
  if (duration.inHours == 0 && totalSeconds % 60 == 0) {
    return l.presetLabelMinutes(duration.inMinutes);
  }
  if (totalSeconds % 3600 == 0) {
    return l.presetLabelHours(duration.inHours);
  }
  // Mixed (e.g. 1h 30m, 5m 20s): fall back to the language-neutral
  // formatter so we don't have to invent presetLabelHoursMinutes etc.
  // for every locale.
  const DurationFormatter formatter = DurationFormatter();
  return formatter.formatTimer(duration);
}
