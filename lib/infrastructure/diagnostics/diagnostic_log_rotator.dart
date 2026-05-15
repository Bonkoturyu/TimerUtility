import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';

/// Manages the on-disk footprint of diagnostic logs.
///
/// Three independent limits (whichever hits first wins on prune):
///   - [maxFileBytes] (default 1 MB): when the current day's log
///     crosses this, [shouldRotateCurrentFile] returns true so the sink
///     can call [rotateCurrentFile] to mint a `.1` / `.2` suffix and
///     start writing a fresh segment.
///   - [retention] (default 14 days): files older than `now - retention`
///     are eligible for deletion.
///   - [maxBytes] (default 50 MB): the cumulative size cap; oldest
///     files are dropped until the directory shrinks below this.
///
/// All filesystem operations defer to async [File] / [Directory] APIs
/// so the calling thread (sink writer) never blocks on a stat.
class DiagnosticLogRotator {
  const DiagnosticLogRotator({
    required this.clock,
    this.retention = const Duration(days: 14),
    this.maxBytes = 50 * 1024 * 1024,
    this.maxFileBytes = 1 * 1024 * 1024,
  });

  final Clock clock;
  final Duration retention;
  final int maxBytes;
  final int maxFileBytes;

  /// Whether [current] has grown past [maxFileBytes] and should be
  /// rolled over to a `.N` suffix. Missing files return false (the
  /// sink will create them on the next write).
  Future<bool> shouldRotateCurrentFile(File current) async {
    if (!await current.exists()) return false;
    final int size = await current.length();
    return size >= maxFileBytes;
  }

  /// Rename [current] to the next available `.N` suffix (`.1`, `.2`, …).
  /// Returns the rotated file. If [current] does not exist, returns it
  /// unchanged so the sink can fall through to creating a fresh one.
  ///
  /// The numbering scans for the first gap rather than tracking a
  /// counter, so a manually-deleted `.3` is reused without confusion.
  Future<File> rotateCurrentFile(File current) async {
    if (!await current.exists()) return current;
    int n = 1;
    File rotated;
    do {
      rotated = File('${current.path}.$n');
      n++;
    } while (await rotated.exists());
    return current.rename(rotated.path);
  }

  /// Drop files (oldest first by mtime) until the directory satisfies
  /// both [retention] and [maxBytes]. Files newer than `now -
  /// retention` are also dropped if they push us over [maxBytes].
  ///
  /// Non-file entries and unreadable files are skipped silently — log
  /// pruning must not crash the app. PR #50 review #3246543152: the
  /// directory traversal itself can also throw (permission revoked
  /// mid-call, directory removed between `exists()` and `list()`),
  /// so we wrap the listing in a try/catch too.
  Future<void> pruneOldFiles(Directory dir) async {
    if (!await dir.exists()) return;
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list().toList();
    } catch (_) {
      // Directory disappeared / unreadable. Skip this prune attempt;
      // the next opportunistic invocation may succeed.
      return;
    }
    final List<_FileInfo> infos = <_FileInfo>[];
    for (final FileSystemEntity e in entries) {
      if (e is! File) continue;
      try {
        final FileStat stat = await e.stat();
        infos.add(_FileInfo(file: e, mtime: stat.modified, size: stat.size));
      } catch (_) {
        // Unreadable: skip rather than fail the whole prune.
      }
    }
    // Oldest first so the "delete until under budget" loop is monotone.
    infos.sort((_FileInfo a, _FileInfo b) => a.mtime.compareTo(b.mtime));

    final DateTime cutoff = clock.now().subtract(retention);
    int total = infos.fold<int>(0, (int s, _FileInfo f) => s + f.size);

    // Pass 1: drop everything older than retention regardless of size.
    final List<_FileInfo> survivors = <_FileInfo>[];
    for (final _FileInfo f in infos) {
      if (f.mtime.isBefore(cutoff)) {
        await _safeDelete(f.file);
        total -= f.size;
      } else {
        survivors.add(f);
      }
    }

    // Pass 2: keep dropping oldest until the cumulative cap is met.
    int i = 0;
    while (total > maxBytes && i < survivors.length) {
      final _FileInfo f = survivors[i];
      await _safeDelete(f.file);
      total -= f.size;
      i++;
    }
  }

  Future<void> _safeDelete(File f) async {
    try {
      await f.delete();
    } catch (_) {
      // Another process holds the file open, or it vanished between
      // listing and deletion. Either way, not fatal.
    }
  }
}

class _FileInfo {
  _FileInfo({required this.file, required this.mtime, required this.size});
  final File file;
  final DateTime mtime;
  final int size;
}
