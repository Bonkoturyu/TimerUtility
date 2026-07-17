import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/timer/alarm_sound_catalog.dart';

/// Serializes every persistence mutation that can create or remove an
/// imported-sound reference.
///
/// A FIFO gate is shared by Timer, Alarm, Preset, Settings, and imported
/// sound deletion. This makes the deletion transaction an ordering fence:
/// writes queued before it complete first, while writes queued during it run
/// afterwards and observe the resulting tombstone.
class ImportedSoundMutationCoordinator {
  final Queue<Future<void> Function()> _pending =
      Queue<Future<void> Function()>();
  bool _isRunning = false;

  Future<T> run<T>(Future<T> Function() operation) {
    final Completer<T> completer = Completer<T>();
    _pending.add(() async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _runNext();
    return completer.future;
  }

  void _runNext() {
    if (_isRunning || _pending.isEmpty) return;
    _isRunning = true;
    final Future<void> Function() next = _pending.removeFirst();
    next().whenComplete(() {
      _isRunning = false;
      _runNext();
    });
  }
}

/// Process-local deletion tombstones used at both state and persistence
/// boundaries.
///
/// [deleting] is intentionally distinct from [deleted]: a write queued while
/// deletion is in progress is normalized only when it eventually executes,
/// so a failed deletion does not discard the user's sound choice.
class ImportedSoundDeletionRegistry {
  final Set<String> _deleting = <String>{};
  final Set<String> _deleted = <String>{};

  bool isDeleting(String? soundId) =>
      soundId != null && _deleting.contains(soundId);

  bool isDeleted(String? soundId) =>
      soundId != null && _deleted.contains(soundId);

  bool isUnavailable(String? soundId) =>
      isDeleting(soundId) || isDeleted(soundId);

  void markDeleting(String soundId) {
    if (!_deleted.contains(soundId)) _deleting.add(soundId);
  }

  void markDeleted(String soundId) {
    _deleting.remove(soundId);
    _deleted.add(soundId);
  }

  void clearDeleting(String soundId) {
    _deleting.remove(soundId);
  }

  String? normalizeDeletedReference(String? soundId) {
    return isDeleted(soundId) ? AlarmSoundCatalog.defaultSound.id : soundId;
  }
}

final Provider<ImportedSoundMutationCoordinator>
importedSoundMutationCoordinatorProvider =
    Provider<ImportedSoundMutationCoordinator>(
      (Ref ref) => ImportedSoundMutationCoordinator(),
    );

final Provider<ImportedSoundDeletionRegistry>
importedSoundDeletionRegistryProvider = Provider<ImportedSoundDeletionRegistry>(
  (Ref ref) => ImportedSoundDeletionRegistry(),
);
