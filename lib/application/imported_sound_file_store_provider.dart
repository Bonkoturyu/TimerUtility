import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/imported_sound_file_store.dart';

part 'imported_sound_file_store_provider.g.dart';

@Riverpod(keepAlive: true)
ImportedSoundFileStore importedSoundFileStore(Ref ref) {
  throw UnimplementedError(
    'importedSoundFileStoreProvider must be overridden in main() or tests.',
  );
}
