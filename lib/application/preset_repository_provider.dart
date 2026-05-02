import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/preset_repository.dart';

part 'preset_repository_provider.g.dart';

/// Provider for the [PresetRepository] used by
/// [PresetCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
@Riverpod(keepAlive: true)
PresetRepository presetRepository(Ref ref) {
  throw UnimplementedError(
    'presetRepositoryProvider must be overridden in main() with the '
    'Drift-backed adapter (or in tests with an in-memory fake).',
  );
}
