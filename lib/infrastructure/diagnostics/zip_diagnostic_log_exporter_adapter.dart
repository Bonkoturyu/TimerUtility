import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/ports/diagnostic_log_exporter.dart';

/// Pluggable share delegate so the unit test can record what would be
/// sent to the OS without actually firing the Share Sheet (which is a
/// Platform Channel call that doesn't work under `flutter test`).
typedef ShareDelegate = Future<void> Function(List<XFile> files);

/// Default production share delegate: hands the files to `share_plus`
/// with a fixed subject. Returning `void` is intentional — `share_plus`
/// reports cancellation as a regular result, not an exception, and the
/// Settings UI doesn't surface that distinction in Phase D-3.
Future<void> _defaultShareDelegate(List<XFile> files) async {
  await Share.shareXFiles(files, subject: 'Timer Utility diagnostic logs');
}

/// Phase D-3 [DiagnosticLogExporter] implementation.
///
/// `createArchive()`:
///   1. resolves `logDirProvider()` (the same directory the file sink
///      writes into) and `outputDirProvider()` (typically temp dir);
///   2. walks every regular file under the log dir (one level — we
///      don't ship subdirectories);
///   3. writes them into `timer_utility_diagnostic_<YYYYMMDD_HHmmss>.zip`
///      under the output dir using the `archive` package's
///      streaming `ZipFileEncoder`;
///   4. returns the absolute path.
///
/// `share(path)`: wraps [path] in an `XFile` and dispatches via the
/// injected [shareDelegate].
///
/// Both directory provider functions are async-returning closures so
/// production code uses `path_provider` and tests use `Directory.systemTemp`
/// without any conditional plumbing.
class ZipDiagnosticLogExporterAdapter implements DiagnosticLogExporter {
  ZipDiagnosticLogExporterAdapter({
    required this.logDirProvider,
    required this.outputDirProvider,
    required this.clock,
    ShareDelegate? shareDelegate,
  }) : shareDelegate = shareDelegate ?? _defaultShareDelegate;

  final Future<Directory> Function() logDirProvider;
  final Future<Directory> Function() outputDirProvider;
  final Clock clock;
  final ShareDelegate shareDelegate;

  @override
  Future<String> createArchive() async {
    final Directory logDir = await logDirProvider();
    final Directory outDir = await outputDirProvider();
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    final String stamp = _timestamp(clock.now());
    final String outPath = '${outDir.path}/timer_utility_diagnostic_$stamp.zip';

    final ZipFileEncoder encoder = ZipFileEncoder();
    encoder.create(outPath);
    try {
      if (await logDir.exists()) {
        final List<FileSystemEntity> entries = await logDir.list().toList();
        // Sort so the archive layout is deterministic — repeat exports
        // of the same on-disk state produce byte-identical zips, which
        // makes integration tests easier and helps testers spot diffs.
        entries.sort(
          (FileSystemEntity a, FileSystemEntity b) => a.path.compareTo(b.path),
        );
        for (final FileSystemEntity e in entries) {
          if (e is! File) continue;
          await encoder.addFile(e);
        }
      }
    } finally {
      await encoder.close();
    }
    return outPath;
  }

  @override
  Future<void> share(String path) async {
    await shareDelegate(<XFile>[XFile(path)]);
  }

  /// `YYYYMMDD_HHmmss` in UTC. UTC keeps filenames stable across
  /// daylight-saving boundaries; testers in a different timezone see the
  /// same name as we'd see on the device.
  String _timestamp(DateTime now) {
    final DateTime u = now.toUtc();
    final String y = u.year.toString().padLeft(4, '0');
    final String m = u.month.toString().padLeft(2, '0');
    final String d = u.day.toString().padLeft(2, '0');
    final String hh = u.hour.toString().padLeft(2, '0');
    final String mm = u.minute.toString().padLeft(2, '0');
    final String ss = u.second.toString().padLeft(2, '0');
    return '$y$m${d}_$hh$mm$ss';
  }
}
