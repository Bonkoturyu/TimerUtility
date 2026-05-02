/// Thrown when adding a new preset would push [PresetCollection.size]
/// past [PresetCollection.maxSize].
///
/// Caller (`PresetCollectionNotifier.create` / `replaceFromTemplate` in
/// append mode) is expected to surface this to the UI as a SnackBar.
class MaxPresetCountExceededException implements Exception {
  const MaxPresetCountExceededException(this.maxSize);

  final int maxSize;

  @override
  String toString() =>
      'MaxPresetCountExceededException: cannot exceed $maxSize presets';
}

/// Thrown when an operation references a preset id that is not in the
/// collection. Indicates either a stale UI reference or a bug.
class PresetNotFoundException implements Exception {
  const PresetNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'PresetNotFoundException: $id';
}
