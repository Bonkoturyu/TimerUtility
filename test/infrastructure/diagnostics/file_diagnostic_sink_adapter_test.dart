import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_event.dart';
import 'package:timer_utility/infrastructure/diagnostics/diagnostic_log_formatter.dart';
import 'package:timer_utility/infrastructure/diagnostics/diagnostic_log_rotator.dart';
import 'package:timer_utility/infrastructure/diagnostics/file_diagnostic_sink_adapter.dart';

void main() {
  late Directory rootDir;

  setUp(() async {
    rootDir = await Directory.systemTemp.createTemp('diag_sink_test_');
  });

  tearDown(() async {
    if (await rootDir.exists()) await rootDir.delete(recursive: true);
  });

  /// Build a sink that writes into [rootDir] using the supplied [clock].
  /// [maxFileBytes] is generous by default so rotation only fires when
  /// a test deliberately writes a large payload.
  FileDiagnosticSinkAdapter makeSink({
    required Clock clock,
    int maxFileBytes = 1024 * 1024,
  }) {
    return FileDiagnosticSinkAdapter(
      rootDirProvider: () async => rootDir,
      formatter: const DiagnosticLogFormatter(),
      rotator: DiagnosticLogRotator(
        clock: clock,
        maxFileBytes: maxFileBytes,
        retention: const Duration(days: 100),
        maxBytes: 1024 * 1024 * 1024,
      ),
      clock: clock,
    );
  }

  group('FileDiagnosticSinkAdapter basic write', () {
    test('event 1 本 → diagnostic_<YYYY-MM-DD>.log にシリアライズされる', () async {
      final Clock clock = Clock.fixed(DateTime.utc(2026, 5, 15, 12));
      final FileDiagnosticSinkAdapter sink = makeSink(clock: clock);

      sink.write(
        DiagnosticEvent.timerAction(
          occurredAt: clock.now(),
          timerId: 'uuid-1',
          action: TimerActionKind.start,
        ),
      );
      await sink.flush();
      await sink.dispose();

      final File f = File('${rootDir.path}/diagnostic_2026-05-15.log');
      expect(await f.exists(), isTrue);
      final String content = await f.readAsString();
      expect(
        content.split('\n').where((String s) => s.isNotEmpty),
        hasLength(1),
      );
      expect(content, contains('"kind":"timerAction"'));
      expect(content, contains('"timerId":"uuid-1"'));
    });

    test('複数 event は順序を維持して append される', () async {
      final Clock clock = Clock.fixed(DateTime.utc(2026, 5, 15, 12));
      final FileDiagnosticSinkAdapter sink = makeSink(clock: clock);

      for (int i = 0; i < 5; i++) {
        sink.write(
          DiagnosticEvent.timerAction(
            occurredAt: clock.now(),
            timerId: 'id-$i',
            action: TimerActionKind.start,
          ),
        );
      }
      await sink.flush();
      await sink.dispose();

      final File f = File('${rootDir.path}/diagnostic_2026-05-15.log');
      final List<String> lines = (await f.readAsString())
          .split('\n')
          .where((String s) => s.isNotEmpty)
          .toList();
      expect(lines, hasLength(5));
      for (int i = 0; i < 5; i++) {
        expect(lines[i], contains('"id-$i"'));
      }
    });
  });

  group('FileDiagnosticSinkAdapter rollover', () {
    test('日付跨ぎで新しいファイルに切り替わる', () async {
      // 可変 clock: 最初は 5/15、後半は 5/16 を返す。
      DateTime currentTime = DateTime.utc(2026, 5, 15, 23, 59);
      final Clock clock = Clock(() => currentTime);
      final FileDiagnosticSinkAdapter sink = makeSink(clock: clock);

      sink.write(
        DiagnosticEvent.timerAction(
          occurredAt: currentTime,
          timerId: 'before-midnight',
          action: TimerActionKind.start,
        ),
      );
      await sink.flush();

      currentTime = DateTime.utc(2026, 5, 16, 0, 1);
      sink.write(
        DiagnosticEvent.timerAction(
          occurredAt: currentTime,
          timerId: 'after-midnight',
          action: TimerActionKind.start,
        ),
      );
      await sink.flush();
      await sink.dispose();

      final File f1 = File('${rootDir.path}/diagnostic_2026-05-15.log');
      final File f2 = File('${rootDir.path}/diagnostic_2026-05-16.log');
      expect(await f1.exists(), isTrue);
      expect(await f2.exists(), isTrue);
      expect(await f1.readAsString(), contains('before-midnight'));
      expect(await f2.readAsString(), contains('after-midnight'));
    });

    test('maxFileBytes 超過で .1 サフィックスに切り替わる', () async {
      final Clock clock = Clock.fixed(DateTime.utc(2026, 5, 15, 12));
      // 1 イベント ≒ 100 byte 程度なので、maxFileBytes=200 にして
      // 数イベント書いたら必ず rotation する設定。
      final FileDiagnosticSinkAdapter sink = makeSink(
        clock: clock,
        maxFileBytes: 200,
      );

      // 何回か書いて rotation を確実に起こす。各 write は flush 待ちで
      // 順序保証されるため間に sleep は不要。
      for (int i = 0; i < 10; i++) {
        sink.write(
          DiagnosticEvent.timerAction(
            occurredAt: clock.now(),
            timerId: 'id-$i',
            action: TimerActionKind.start,
          ),
        );
        await sink.flush();
      }
      await sink.dispose();

      final File main = File('${rootDir.path}/diagnostic_2026-05-15.log');
      final File rotated = File('${rootDir.path}/diagnostic_2026-05-15.log.1');
      expect(await main.exists(), isTrue);
      expect(
        await rotated.exists(),
        isTrue,
        reason: '10 イベント書けば maxFileBytes=200 を超えて .1 が生成されるはず',
      );
    });
  });

  group('FileDiagnosticSinkAdapter error resilience', () {
    test('rootDirProvider が投げても write は throw しない', () async {
      final Clock clock = Clock.fixed(DateTime.utc(2026, 5, 15, 12));
      final FileDiagnosticSinkAdapter sink = FileDiagnosticSinkAdapter(
        rootDirProvider: () async {
          throw const FileSystemException('disk gone');
        },
        formatter: const DiagnosticLogFormatter(),
        rotator: DiagnosticLogRotator(clock: clock),
        clock: clock,
      );

      // 例外が伝播しないこと。
      sink.write(
        DiagnosticEvent.timerAction(
          occurredAt: clock.now(),
          timerId: 'x',
          action: TimerActionKind.start,
        ),
      );
      // flush も throw しない。
      await sink.flush();
      await sink.dispose();
    });
  });

  group('FileDiagnosticSinkAdapter dispose', () {
    test('write after dispose is dropped (does not reopen the file)', () async {
      final Clock clock = Clock.fixed(DateTime.utc(2026, 5, 15, 12));
      final FileDiagnosticSinkAdapter sink = makeSink(clock: clock);

      sink.write(
        DiagnosticEvent.timerAction(
          occurredAt: clock.now(),
          timerId: 'before-dispose',
          action: TimerActionKind.start,
        ),
      );
      await sink.flush();
      await sink.dispose();

      final File f = File('${rootDir.path}/diagnostic_2026-05-15.log');
      final String before = await f.readAsString();

      // A late write must be dropped: no reopen, no extra bytes, no leaked
      // IOSink. The directory still holds exactly one file and its content
      // is byte-identical.
      sink.write(
        DiagnosticEvent.timerAction(
          occurredAt: clock.now(),
          timerId: 'after-dispose',
          action: TimerActionKind.start,
        ),
      );
      await sink.flush();

      final List<File> files = rootDir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      final String after = await f.readAsString();
      expect(after, before);
      expect(after, isNot(contains('after-dispose')));
    });
  });
}
