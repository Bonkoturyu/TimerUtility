import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/timer_repository.dart';

part 'timer_repository_provider.g.dart';

/// Provider for the [TimerRepository] used by
/// [TimerCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
@Riverpod(keepAlive: true)
TimerRepository timerRepository(Ref ref) {
  throw UnimplementedError(
    'timerRepositoryProvider must be overridden in main() with the '
    'Drift-backed adapter (or in tests with an in-memory fake).',
  );
}
