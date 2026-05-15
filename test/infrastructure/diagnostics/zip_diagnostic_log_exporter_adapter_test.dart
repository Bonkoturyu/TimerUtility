import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart' show XFile;
import 'package:timer_utility/infrastructure/diagnostics/zip_diagnostic_log_exporter_adapter.dart';

void main() {
  late Directory logDir;
  late Directory outDir;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('diag_zip_test_log_');
    outDir = await Directory.systemTemp.createTemp('diag_zip_test_out_');
  });

  tearDown(() async {
    if (await logDir.exists()) await logDir.delete(recursive: true);
    if (await outDir.exists()) await outDir.delete(recursive: true);
  });

  /// Test-recording share delegate.
  List<({List<XFile> files, String subject})> shareCalls =
      <({List<XFile> files, String subject})>[];
  Future<void> fakeShare(List<XFile> files, {required String subject}) async {
    shareCalls.add((files: files, subject: subject));
  }

  setUp(() {
    shareCalls = <({List<XFile> files, String subject})>[];
  });

  ZipDiagnosticLogExporterAdapter makeExporter({Clock? clock}) {
    return ZipDiagnosticLogExporterAdapter(
      logDirProvider: () async => logDir,
      outputDirProvider: () async => outDir,
      clock: clock ?? Clock.fixed(DateTime.utc(2026, 5, 15, 12, 34, 56)),
      shareDelegate: fakeShare,
    );
  }

  group('createArchive', () {
    test('ファイル名は timer_utility_diagnostic_YYYYMMDD_HHmmss.zip', () async {
      final ZipDiagnosticLogExporterAdapter exp = makeExporter();
      await File(
        '${logDir.path}/diagnostic_2026-05-15.log',
      ).writeAsString('{"k":1}\n');

      final String path = await exp.createArchive();
      expect(
        path,
        '${outDir.path}/timer_utility_diagnostic_20260515_123456.zip',
      );
      expect(await File(path).exists(), isTrue);
    });

    test('zip 内に log ファイルが含まれる (archive で decode)', () async {
      final ZipDiagnosticLogExporterAdapter exp = makeExporter();
      await File(
        '${logDir.path}/diagnostic_2026-05-15.log',
      ).writeAsString('{"kind":"timerAction"}\n{"kind":"timerAction"}\n');
      await File(
        '${logDir.path}/diagnostic_2026-05-16.log',
      ).writeAsString('{"kind":"notificationFired"}\n');

      final String path = await exp.createArchive();
      final Uint8List bytes = await File(path).readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      final Set<String> names = archive.files
          .map((ArchiveFile f) => f.name)
          .toSet();
      expect(
        names,
        containsAll(<String>[
          'diagnostic_2026-05-15.log',
          'diagnostic_2026-05-16.log',
        ]),
      );
    });

    test('zip 内ファイルの内容が source と一致する', () async {
      final ZipDiagnosticLogExporterAdapter exp = makeExporter();
      const String body = '{"kind":"timerAction","timerId":"x"}\n';
      await File(
        '${logDir.path}/diagnostic_2026-05-15.log',
      ).writeAsString(body);

      final String path = await exp.createArchive();
      final Archive archive = ZipDecoder().decodeBytes(
        await File(path).readAsBytes(),
      );
      final ArchiveFile entry = archive.files.singleWhere(
        (ArchiveFile f) => f.name == 'diagnostic_2026-05-15.log',
      );
      expect(String.fromCharCodes(entry.content as List<int>), body);
    });

    test('log dir が空でも zip は作られる', () async {
      final ZipDiagnosticLogExporterAdapter exp = makeExporter();
      final String path = await exp.createArchive();
      expect(await File(path).exists(), isTrue);
      final Archive archive = ZipDecoder().decodeBytes(
        await File(path).readAsBytes(),
      );
      expect(archive.files, isEmpty);
    });

    test('outputDir が存在しなくても作成して書き込む', () async {
      // 既存の outDir を消してから作る exporter。
      final Directory ghostOut = Directory('${outDir.path}/nested/missing');
      final ZipDiagnosticLogExporterAdapter exp =
          ZipDiagnosticLogExporterAdapter(
            logDirProvider: () async => logDir,
            outputDirProvider: () async => ghostOut,
            clock: Clock.fixed(DateTime.utc(2026, 5, 15, 12, 34, 56)),
            shareDelegate: fakeShare,
          );
      await File('${logDir.path}/diagnostic.log').writeAsString('hi\n');

      final String path = await exp.createArchive();
      expect(path.startsWith(ghostOut.path), isTrue);
      expect(await File(path).exists(), isTrue);
    });
  });

  group('share', () {
    test('share() は shareDelegate に XFile と subject を渡す', () async {
      final ZipDiagnosticLogExporterAdapter exp = makeExporter();
      await exp.share('${outDir.path}/zip.zip', subject: 'test-subject');
      expect(shareCalls, hasLength(1));
      expect(shareCalls.first.files, hasLength(1));
      expect(shareCalls.first.files.first.path, '${outDir.path}/zip.zip');
      expect(shareCalls.first.subject, 'test-subject');
    });
  });
}
