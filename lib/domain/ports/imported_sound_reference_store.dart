/// Atomically replaces persisted references to an imported sound.
///
/// The implementation also removes the imported metadata in the same
/// transaction. UserPreferences live outside SQLite and are coordinated by
/// the Application deletion saga.
abstract class ImportedSoundReferenceStore {
  Future<void> replaceReferencesAndDeleteMetadata({
    required String soundId,
    required String fallbackSoundId,
  });
}
