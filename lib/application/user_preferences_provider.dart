import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/user_preferences.dart';

part 'user_preferences_provider.g.dart';

/// Provider for the [UserPreferences] adapter. Tests override with an
/// in-memory fake; production binding is wired in `main()` after
/// `SharedPreferencesUserPreferences.create()` has resolved.
///
/// Kept on a single global provider rather than splitting per key —
/// the surface area is small (one bool today; a handful expected
/// across Phase 11), so the additional indirection isn't worth it.
@Riverpod(keepAlive: true)
UserPreferences userPreferences(Ref ref) {
  throw UnimplementedError(
    'userPreferencesProvider must be overridden in main() with the '
    'shared_preferences adapter (or in tests with an in-memory fake).',
  );
}
