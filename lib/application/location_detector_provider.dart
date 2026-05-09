import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/location_detector.dart';

part 'location_detector_provider.g.dart';

/// Provider for the [LocationDetector] used by
/// [ClockCollectionNotifier]'s first-launch detection path. Tests
/// override this with a `mocktail` mock; production binding is wired
/// in `main()` with [LocationDetectorAdapter].
@Riverpod(keepAlive: true)
LocationDetector locationDetector(Ref ref) {
  throw UnimplementedError(
    'locationDetectorProvider must be overridden in main() with '
    'LocationDetectorAdapter (or in tests with a mock).',
  );
}
