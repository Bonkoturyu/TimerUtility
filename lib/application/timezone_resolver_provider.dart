import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/clock/clock_time.dart';

part 'timezone_resolver_provider.g.dart';

/// Provider for the [TimezoneResolver] used by the world-clock
/// presentation widgets to render a wall-clock [DateTime] for a given
/// IANA timezone id. Tests override this with a fake (fixed-offset
/// implementation); production binding is wired in `main()` with
/// [TzDatabaseTimezoneResolver].
@Riverpod(keepAlive: true)
TimezoneResolver timezoneResolver(Ref ref) {
  throw UnimplementedError(
    'timezoneResolverProvider must be overridden in main() with '
    'TzDatabaseTimezoneResolver (or in tests with a fake).',
  );
}
