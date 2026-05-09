import 'package:freezed_annotation/freezed_annotation.dart';

import 'exceptions.dart';

part 'clock_time.freezed.dart';

/// Pure value: an absolute moment in time tagged with the IANA
/// timezone id we want to render it in.
///
/// Conversion to a wall-clock [DateTime] in the target zone is
/// delegated to [TimezoneResolver]. Domain stays Pure Dart (CLAUDE.md
/// constraint) and never imports the `timezone` package directly —
/// the Infrastructure adapter (`infrastructure/clock/...`) supplies
/// the real implementation at composition time.
@freezed
class ClockTime with _$ClockTime {
  const factory ClockTime({required DateTime now, required String timezoneId}) =
      _ClockTime;
}

/// Port for converting an absolute [DateTime] into the wall-clock
/// [DateTime] of a target IANA timezone.
///
/// Implementations live under `lib/infrastructure/clock/` and depend
/// on the `timezone` package. The signature is intentionally narrow —
/// no `Clock` injection (the caller passes `now` explicitly) — so the
/// Domain abstraction stays free of time-source concerns.
///
/// Implementations MUST throw [InvalidTimezoneIdException] when
/// `timezoneId` is not in the IANA Time Zone Database.
abstract class TimezoneResolver {
  DateTime computeAt(DateTime now, String timezoneId);
}
