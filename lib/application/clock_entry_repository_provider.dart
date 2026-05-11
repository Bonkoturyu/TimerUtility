import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/clock_entry_repository.dart';

part 'clock_entry_repository_provider.g.dart';

/// Provider for the [ClockEntryRepository] used by
/// [ClockEntryCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
@Riverpod(keepAlive: true)
ClockEntryRepository clockEntryRepository(Ref ref) {
  throw UnimplementedError(
    'clockEntryRepositoryProvider must be overridden in main() with the '
    'Drift-backed adapter (or in tests with an in-memory fake).',
  );
}
