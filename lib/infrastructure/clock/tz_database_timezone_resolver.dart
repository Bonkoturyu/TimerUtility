import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/clock/clock_time.dart';
import '../../domain/clock/exceptions.dart';

/// Adapter that backs [TimezoneResolver] with the `timezone` package's
/// IANA Time Zone Database (full / "latest_all" dataset, ~25 KB
/// gzipped — matched against the catalog of major-city presets in
/// [TimezoneCatalog]).
///
/// `tz.initializeTimeZones()` builds the in-memory zone table from the
/// bundled binary blob; it is idempotent but not cheap, so we gate it
/// behind a static flag to keep cold-start cost bounded when the
/// resolver is constructed multiple times in tests.
///
/// Conversion failures (`tz.LocationNotFoundException`) are wrapped in
/// the Domain-level [InvalidTimezoneIdException] so callers can react
/// without leaking the `timezone` package across the boundary.
class TzDatabaseTimezoneResolver implements TimezoneResolver {
  TzDatabaseTimezoneResolver() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  static bool _initialized = false;

  @override
  DateTime computeAt(DateTime now, String timezoneId) {
    try {
      final tz.Location location = tz.getLocation(timezoneId);
      return tz.TZDateTime.from(now, location);
    } on tz.LocationNotFoundException catch (_, st) {
      // Preserve the original stack trace so logs / crash reports point
      // back at the failing `tz.getLocation` call site rather than
      // bottoming out at this rethrow.
      Error.throwWithStackTrace(InvalidTimezoneIdException(timezoneId), st);
    }
  }
}
