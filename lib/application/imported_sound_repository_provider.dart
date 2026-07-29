import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/imported_sound_repository.dart';

part 'imported_sound_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ImportedSoundRepository importedSoundRepository(Ref ref) {
  throw UnimplementedError(
    'importedSoundRepositoryProvider must be overridden in main() or tests.',
  );
}
