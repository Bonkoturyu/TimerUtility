import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

import '../domain/ports/imported_sound_file_store.dart';
import '../domain/ports/imported_sound_picker.dart';
import '../domain/ports/imported_sound_probe.dart';
import '../domain/ports/imported_sound_repository.dart';
import '../domain/ports/storage_capacity_reader.dart';
import '../domain/sound/imported_sound.dart';
import '../domain/sound/imported_sound_exceptions.dart';
import '../domain/sound/imported_sound_policy.dart';
import '../domain/sound/imported_sound_validator.dart';

typedef ImportedSoundIdGenerator = String Function();

String _newImportedSoundId() => const Uuid().v4();

sealed class PrepareImportedSoundResult {
  const PrepareImportedSoundResult();
}

/// A validated app-private staging copy awaiting explicit confirmation.
class PreparedImportedSound extends PrepareImportedSoundResult {
  PreparedImportedSound._({
    required this.candidate,
    required String stagingToken,
  }) : _stagingToken = stagingToken;

  final ImportedSound candidate;
  final String _stagingToken;
  bool _closed = false;
}

/// The selected bytes already exist and should resolve to this sound.
class DuplicateImportedSound extends PrepareImportedSoundResult {
  const DuplicateImportedSound(this.existingSound);

  final ImportedSound existingSound;
}

/// Coordinates the all-or-nothing import of one user-selected sound.
class ImportedSoundImportService {
  ImportedSoundImportService({
    required ImportedSoundPicker picker,
    required ImportedSoundFileStore fileStore,
    required ImportedSoundProbe probe,
    required StorageCapacityReader storageCapacityReader,
    required ImportedSoundRepository repository,
    required Clock clock,
    ImportedSoundValidator validator = const ImportedSoundValidator(),
    ImportedSoundIdGenerator? idGenerator,
  }) : _picker = picker,
       _fileStore = fileStore,
       _probe = probe,
       _storageCapacityReader = storageCapacityReader,
       _repository = repository,
       _clock = clock,
       _validator = validator,
       _idGenerator = idGenerator ?? _newImportedSoundId;

  final ImportedSoundPicker _picker;
  final ImportedSoundFileStore _fileStore;
  final ImportedSoundProbe _probe;
  final StorageCapacityReader _storageCapacityReader;
  final ImportedSoundRepository _repository;
  final Clock _clock;
  final ImportedSoundValidator _validator;
  final ImportedSoundIdGenerator _idGenerator;

  Future<PrepareImportedSoundResult?> prepare(
    ImportedSoundPolicy policy,
  ) async {
    final SelectedImportedSoundFile? selected = await _picker.pickOne();
    if (selected == null) return null;

    final int availableBytes = await _storageCapacityReader.getAvailableBytes();
    if (availableBytes < ImportedSoundValidator.minimumRemainingStorageBytes ||
        availableBytes - selected.byteLength <
            ImportedSoundValidator.minimumRemainingStorageBytes) {
      throw const InsufficientImportedSoundStorageException();
    }

    final StagedImportedSoundFile staged = await _fileStore.stage(
      source: selected.openRead(),
      expectedByteLength: selected.byteLength,
    );
    bool committed = false;
    try {
      final ImportedSoundProbeResult probed = await _probe.probe(staged.token);
      final ImportedSound candidate = ImportedSound.create(
        id: _idGenerator(),
        displayName: _displayNameOf(selected.name),
        format: probed.format,
        byteLength: staged.byteLength,
        duration: probed.duration,
        contentHash: staged.contentHash,
        createdAt: _clock.now(),
      );
      final List<ImportedSound> existing = await _repository.findAll();
      try {
        _validator.validateAddition(
          candidate: candidate,
          existingSounds: existing,
          policy: policy,
          availableStorageBytes: availableBytes,
        );
      } on DuplicateImportedSoundContentException catch (error) {
        ImportedSound? duplicate;
        for (final ImportedSound sound in existing) {
          if (sound.id == error.existingSoundId) {
            duplicate = sound;
            break;
          }
        }
        if (duplicate == null) rethrow;
        await _fileStore.discard(staged.token);
        committed = true;
        return DuplicateImportedSound(duplicate);
      }

      committed = true;
      return PreparedImportedSound._(
        candidate: candidate,
        stagingToken: staged.token,
      );
    } finally {
      if (!committed) await _fileStore.discard(staged.token);
    }
  }

  Future<ImportedSound> confirm(PreparedImportedSound prepared) async {
    _ensureOpen(prepared);
    bool committed = false;
    try {
      await _fileStore.commit(
        token: prepared._stagingToken,
        soundId: prepared.candidate.id,
        format: prepared.candidate.format,
      );
      committed = true;
      try {
        await _repository.upsert(prepared.candidate);
      } catch (_) {
        await _fileStore.delete(
          prepared.candidate.id,
          prepared.candidate.format,
        );
        rethrow;
      }
      return prepared.candidate;
    } finally {
      prepared._closed = true;
      if (!committed) await _fileStore.discard(prepared._stagingToken);
    }
  }

  Future<void> cancel(PreparedImportedSound prepared) async {
    if (prepared._closed) return;
    await _fileStore.discard(prepared._stagingToken);
    prepared._closed = true;
  }

  String stagingTokenOf(PreparedImportedSound prepared) {
    _ensureOpen(prepared);
    return prepared._stagingToken;
  }

  /// Compatibility entry point for callers that do not offer confirmation.
  Future<ImportedSound?> importOne(ImportedSoundPolicy policy) async {
    final PrepareImportedSoundResult? result = await prepare(policy);
    return switch (result) {
      null => null,
      DuplicateImportedSound(:final existingSound) =>
        throw DuplicateImportedSoundContentException(existingSound.id),
      final PreparedImportedSound prepared => confirm(prepared),
    };
  }

  void _ensureOpen(PreparedImportedSound prepared) {
    if (prepared._closed) {
      throw StateError('The imported sound session is already closed.');
    }
  }

  String _displayNameOf(String sourceName) {
    final String trimmed = sourceName.trim();
    final int dot = trimmed.lastIndexOf('.');
    final String withoutExtension = dot > 0
        ? trimmed.substring(0, dot)
        : trimmed;
    if (withoutExtension.trim().isEmpty) {
      throw const ImportedSoundReadException();
    }
    return withoutExtension;
  }
}
