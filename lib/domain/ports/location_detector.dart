/// Port for detecting the device's current IANA timezone id
/// (Phase 10.5).
///
/// Implementations live under `lib/infrastructure/location/` and
/// typically chain GPS → reverse geocoding → country code → canonical
/// timezone, with `FlutterTimezone.getLocalTimezone()` as the final
/// fallback when permission is denied or geocoding fails. A successful
/// call always returns a non-empty IANA id; transient failures are
/// hidden by the adapter so the Domain abstraction never needs to
/// model error states.
abstract class LocationDetector {
  Future<String> detectTimezoneId();
}
