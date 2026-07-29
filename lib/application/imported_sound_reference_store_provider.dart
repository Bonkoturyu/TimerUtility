import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/imported_sound_reference_store.dart';

part 'imported_sound_reference_store_provider.g.dart';

@Riverpod(keepAlive: true)
ImportedSoundReferenceStore importedSoundReferenceStore(Ref ref) {
  throw UnimplementedError(
    'importedSoundReferenceStoreProvider must be overridden in main() or tests.',
  );
}
