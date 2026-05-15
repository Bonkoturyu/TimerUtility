import 'package:clock/clock.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../../domain/diagnostics/diagnostic_event.dart';
import '../../domain/ports/diagnostic_sink.dart';
import '../../domain/ports/location_detector.dart';
import 'country_to_timezone.dart';

/// `LocationDetector` 実装 (Phase 10.5)。
///
/// 検出チェーン (前段が失敗 / null を返したら次段へ降りる):
///
///   1. 位置情報パーミッション要求 (`Geolocator.checkPermission` →
///      必要なら `requestPermission`)。拒否されたらスキップ。
///   2. `Geolocator.getCurrentPosition` で coarse 精度 + 5 秒 timeout。
///   3. `placemarkFromCoordinates` で逆ジオコーディング (5 秒 timeout)。
///      先頭の `Placemark.isoCountryCode` を採用。
///   4. `CountryToTimezone.lookup(code)` で IANA TZ に解決。
///   5. ↑ ここまでで失敗したら `FlutterTimezone.getLocalTimezone()`
///      (端末のシステム TZ)。
///   6. `FlutterTimezone` も投げたら最後の保険として `'Asia/Tokyo'`。
///
/// `LocationDetector.detectTimezoneId()` の port 仕様は「必ず非空の
/// IANA id を返す」。各段は try/catch で握りつぶし、Adapter 内で
/// 完結させる (上位層は失敗を意識しない)。
///
/// テスト方針: `geolocator` / `geocoding` / `flutter_timezone` は
/// MethodChannel ベースで mock が困難。Adapter 自体は薄いラッパで
/// 分岐ロジックは「失敗したら次段」の単純チェーンしかないため、
/// Unit Test は書かず実機検証で担保 (BACKLOG にコメント済)。
class LocationDetectorAdapter implements LocationDetector {
  /// [sink] is optional so existing tests that construct the adapter
  /// directly don't have to plumb a fake. Production wiring passes the
  /// file-backed adapter; when null, exceptions only land in the
  /// `logger` package console output (Phase 10.5 baseline behaviour).
  /// [clock] is used to timestamp the diagnostic event; defaults to a
  /// real wall clock so the optional injection path stays terse.
  LocationDetectorAdapter({this.sink, Clock? clock})
    : _clock = clock ?? const Clock();

  static const String _ultimateFallback = 'Asia/Tokyo';
  static const Duration _gpsTimeout = Duration(seconds: 5);
  static const Duration _geocodingTimeout = Duration(seconds: 5);

  final DiagnosticSink? sink;
  final Clock _clock;

  // Single Logger reused across detection attempts: it's stateful
  // (output formatter / level filter) and constructing a fresh one per
  // call is wasted work since the Adapter itself is a singleton in
  // `ProviderScope.overrides`.
  final Logger _logger = Logger();

  @override
  Future<String> detectTimezoneId() async {
    final String? viaGps = await _detectViaGps();
    if (viaGps != null) return viaGps;

    final String? viaSystem = await _detectViaSystemTimezone();
    if (viaSystem != null) return viaSystem;

    return _ultimateFallback;
  }

  Future<String?> _detectViaGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: _gpsTimeout,
        ),
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(_geocodingTimeout);
      if (placemarks.isEmpty) return null;

      final String? isoCountryCode = placemarks.first.isoCountryCode;
      if (isoCountryCode == null || isoCountryCode.isEmpty) return null;

      final String? tz = CountryToTimezone.lookup(isoCountryCode);
      if (tz == null) return null;
      return tz;
    } catch (e, st) {
      _logger.w(
        'LocationDetectorAdapter: GPS path failed',
        error: e,
        stackTrace: st,
      );
      _recordDiagnostic(e, st);
      return null;
    }
  }

  Future<String?> _detectViaSystemTimezone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      final String id = info.identifier;
      if (id.isEmpty) return null;
      return id;
    } catch (e, st) {
      _logger.w(
        'LocationDetectorAdapter: FlutterTimezone fallback failed',
        error: e,
        stackTrace: st,
      );
      _recordDiagnostic(e, st);
      return null;
    }
  }

  /// Forward the GPS / TZ-resolution failure to the diagnostic sink as
  /// an [DiagnosticEvent.uncaughtException]. No-op when [sink] is null
  /// (Phase 10.5-era construction sites that haven't been migrated).
  /// Stack-trace digest is intentionally short — the domain layer's
  /// PII contract bars us from logging the position / placemark.
  void _recordDiagnostic(Object error, StackTrace st) {
    final DiagnosticSink? s = sink;
    if (s == null) return;
    final List<String> top = st
        .toString()
        .split('\n')
        .where((String l) => l.trim().isNotEmpty)
        .take(3)
        .toList();
    s.write(
      DiagnosticEvent.uncaughtException(
        occurredAt: _clock.now(),
        exceptionType: error.runtimeType.toString(),
        stackTraceDigest: top.join('\n'),
      ),
    );
  }
}
