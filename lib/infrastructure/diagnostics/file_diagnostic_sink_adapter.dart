import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:clock/clock.dart';

import '../../domain/diagnostics/diagnostic_event.dart';
import '../../domain/ports/diagnostic_sink.dart';
import 'diagnostic_log_formatter.dart';
import 'diagnostic_log_rotator.dart';

/// File-backed [DiagnosticSink] for Phase D-2.
///
/// Writes one JSON line per event into `diagnostic_<YYYY-MM-DD>.log`
/// under [rootDirProvider]. Files roll over when:
///   - the calendar day changes (close current, open new);
///   - the current file grows past [DiagnosticLogRotator.maxFileBytes]
///     (rename current to `.N` suffix, open fresh).
///
/// Construction is cheap: actual directory resolution and file open
/// happen lazily on the first [write] so unit tests that never log
/// don't pay for any I/O. [write] queues events through a `Future`
/// chain so concurrent callers can't interleave bytes mid-line.
///
/// The rotator's [DiagnosticLogRotator.pruneOldFiles] is invoked
/// opportunistically once per process lifetime (first write) so a
/// long-running session that never rotates still bounds the disk
/// footprint over time.
class FileDiagnosticSinkAdapter implements DiagnosticSink {
  FileDiagnosticSinkAdapter({
    required this.rootDirProvider,
    required this.formatter,
    required this.rotator,
    required this.clock,
  });

  /// Resolves the directory that holds the daily log files.
  /// Production wiring passes a closure over
  /// `getApplicationSupportDirectory()`; tests pass a temp dir.
  final Future<Directory> Function() rootDirProvider;
  final DiagnosticLogFormatter formatter;
  final DiagnosticLogRotator rotator;
  final Clock clock;

  // The IOSink is closed by [_closeCurrent] (called from date-rollover,
  // size-rollover, dispose, and on every reassignment). The lint can't
  // see across these helpers, so it flags this field as unclosed.
  IOSink? _sink; // ignore: close_sinks
  File? _currentFile;
  String? _currentDateKey;
  bool _prunedOnce = false;

  /// Serializes writes so concurrent callers' lines don't interleave.
  /// Each `write` waits for the previous to finish before appending.
  Future<void> _writeChain = Future<void>.value();

  @override
  void write(DiagnosticEvent event) {
    final String line = formatter.format(event);
    _writeChain = _writeChain.then((_) => _writeLine(line)).catchError((
      Object _,
    ) {
      // Logging must never crash the host. Swallow filesystem errors
      // (disk full / permission revoked / dir removed) and continue
      // — the next write may succeed once conditions clear.
    });
  }

  Future<void> _writeLine(String line) async {
    final String dateKey = _dateKey(clock.now());
    if (_sink == null || _currentDateKey != dateKey) {
      await _openOrRollDate(dateKey);
    } else if (_currentFile != null &&
        await rotator.shouldRotateCurrentFile(_currentFile!)) {
      await _closeCurrent();
      await rotator.rotateCurrentFile(_currentFile!);
      await _openCurrent(dateKey);
    }
    _sink!.add(utf8.encode(line));
    if (!_prunedOnce) {
      _prunedOnce = true;
      // Fire-and-forget prune so the first write isn't blocked on disk
      // traversal. Errors inside pruneOldFiles are swallowed there.
      unawaited(_runFirstWritePrune());
    }
  }

  Future<void> _openOrRollDate(String dateKey) async {
    await _closeCurrent();
    await _openCurrent(dateKey);
  }

  Future<void> _openCurrent(String dateKey) async {
    final Directory dir = await rootDirProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final File file = File('${dir.path}/diagnostic_$dateKey.log');
    _currentFile = file;
    _currentDateKey = dateKey;
    _sink = file.openWrite(mode: FileMode.append);
  }

  Future<void> _closeCurrent() async {
    final IOSink? sink = _sink;
    _sink = null;
    if (sink != null) {
      try {
        await sink.flush();
      } catch (_) {
        /* see write swallow rationale */
      }
      try {
        await sink.close();
      } catch (_) {
        /* idem */
      }
    }
  }

  Future<void> _runFirstWritePrune() async {
    try {
      final Directory dir = await rootDirProvider();
      await rotator.pruneOldFiles(dir);
    } catch (_) {
      // Prune is best-effort.
    }
  }

  @override
  Future<void> flush() async {
    // Drain pending writes first, then flush the underlying IOSink.
    await _writeChain;
    final IOSink? sink = _sink;
    if (sink == null) return;
    try {
      await sink.flush();
    } catch (_) {}
  }

  /// Closes the underlying file. Call from the host app's `dispose` or
  /// the equivalent lifecycle teardown so the IOSink is not abandoned
  /// — Dart's IO library does not auto-flush on process exit.
  Future<void> dispose() async {
    await _writeChain;
    await _closeCurrent();
  }

  /// YYYY-MM-DD in UTC. Picking UTC (rather than local time) means
  /// timezone hops or DST transitions don't create midnight surprises;
  /// the log consumer can localize after parsing.
  String _dateKey(DateTime now) {
    final DateTime u = now.toUtc();
    final String y = u.year.toString().padLeft(4, '0');
    final String m = u.month.toString().padLeft(2, '0');
    final String d = u.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
