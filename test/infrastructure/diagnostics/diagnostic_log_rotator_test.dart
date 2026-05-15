import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/diagnostics/diagnostic_log_rotator.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('diag_rotator_test_');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<File> writeFile(
    String name,
    int sizeBytes, {
    Duration ageBeforeNow = Duration.zero,
    Clock? clock,
  }) async {
    final File f = File('${dir.path}/$name');
    await f.writeAsBytes(List<int>.filled(sizeBytes, 0x61));
    final DateTime now = (clock ?? const Clock()).now();
    final DateTime mtime = now.subtract(ageBeforeNow);
    await f.setLastModified(mtime);
    return f;
  }

  group('shouldRotateCurrentFile', () {
    test('maxFileBytes 未満なら false', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(
        clock: Clock(),
        maxFileBytes: 1000,
      );
      final File f = await writeFile('a.log', 500);
      expect(await rotator.shouldRotateCurrentFile(f), isFalse);
    });

    test('maxFileBytes と等しい / 超過なら true', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(
        clock: Clock(),
        maxFileBytes: 1000,
      );
      final File f = await writeFile('a.log', 1000);
      expect(await rotator.shouldRotateCurrentFile(f), isTrue);
      final File g = await writeFile('b.log', 1001);
      expect(await rotator.shouldRotateCurrentFile(g), isTrue);
    });

    test('存在しないファイルは false (sink 側で新規作成する経路)', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(clock: Clock());
      expect(
        await rotator.shouldRotateCurrentFile(File('${dir.path}/missing.log')),
        isFalse,
      );
    });
  });

  group('rotateCurrentFile', () {
    test('.1 がなければ .1 にリネーム', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(clock: Clock());
      final File f = await writeFile('diag.log', 10);
      final File rotated = await rotator.rotateCurrentFile(f);
      expect(rotated.path, '${f.path}.1');
      expect(await rotated.exists(), isTrue);
      expect(await f.exists(), isFalse);
    });

    test('.1 が既にあれば .2 にリネーム', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(clock: Clock());
      final File current = await writeFile('diag.log', 10);
      await writeFile('diag.log.1', 10);
      final File rotated = await rotator.rotateCurrentFile(current);
      expect(rotated.path, '${current.path}.2');
    });

    test('存在しない current は unchanged を返す (sink は新規作成へ進む)', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(clock: Clock());
      final File ghost = File('${dir.path}/never.log');
      final File r = await rotator.rotateCurrentFile(ghost);
      expect(r.path, ghost.path);
    });
  });

  group('pruneOldFiles: retention', () {
    test('retention 直後のファイルは削除される', () async {
      final DateTime now = DateTime.utc(2026, 5, 15, 12);
      final DiagnosticLogRotator rotator = DiagnosticLogRotator(
        clock: Clock.fixed(now),
        retention: const Duration(days: 14),
      );
      final File old = await writeFile(
        'old.log',
        100,
        ageBeforeNow: const Duration(days: 14, seconds: 1),
        clock: Clock.fixed(now),
      );
      final File recent = await writeFile(
        'new.log',
        100,
        ageBeforeNow: const Duration(days: 13),
        clock: Clock.fixed(now),
      );

      await rotator.pruneOldFiles(dir);
      expect(await old.exists(), isFalse);
      expect(await recent.exists(), isTrue);
    });

    test('retention 直前 (= ちょうど 14 日前) は残る', () async {
      final DateTime now = DateTime.utc(2026, 5, 15, 12);
      final DiagnosticLogRotator rotator = DiagnosticLogRotator(
        clock: Clock.fixed(now),
        retention: const Duration(days: 14),
      );
      final File f = await writeFile(
        'edge.log',
        100,
        ageBeforeNow: const Duration(days: 14),
        clock: Clock.fixed(now),
      );
      await rotator.pruneOldFiles(dir);
      // ちょうど cutoff (= now - 14d) の境界は < cutoff なので残る。
      expect(await f.exists(), isTrue);
    });
  });

  group('pruneOldFiles: maxBytes', () {
    test('合計が maxBytes を超えたら古い順に削除', () async {
      final DateTime now = DateTime.utc(2026, 5, 15, 12);
      final DiagnosticLogRotator rotator = DiagnosticLogRotator(
        clock: Clock.fixed(now),
        retention: const Duration(days: 100),
        maxBytes: 1500,
      );
      // 各 1000 byte × 3 ファイル = 3000 byte > maxBytes 1500
      final File f1 = await writeFile(
        'a.log',
        1000,
        ageBeforeNow: const Duration(days: 3),
        clock: Clock.fixed(now),
      );
      final File f2 = await writeFile(
        'b.log',
        1000,
        ageBeforeNow: const Duration(days: 2),
        clock: Clock.fixed(now),
      );
      final File f3 = await writeFile(
        'c.log',
        1000,
        ageBeforeNow: const Duration(days: 1),
        clock: Clock.fixed(now),
      );

      await rotator.pruneOldFiles(dir);

      // 最古から削除して 1500 byte 以下になるまで → a / b 削除、c 残存。
      expect(await f1.exists(), isFalse);
      expect(await f2.exists(), isFalse);
      expect(await f3.exists(), isTrue);
    });
  });

  group('pruneOldFiles: robustness', () {
    test('空 dir でもクラッシュしない', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(clock: Clock());
      await rotator.pruneOldFiles(dir);
    });

    test('存在しない dir でもクラッシュしない', () async {
      const DiagnosticLogRotator rotator = DiagnosticLogRotator(clock: Clock());
      await rotator.pruneOldFiles(Directory('${dir.path}/nope'));
    });
  });
}
