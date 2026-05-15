import 'dart:convert' show jsonDecode;

import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_event.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/infrastructure/diagnostics/diagnostic_log_formatter.dart';

void main() {
  const DiagnosticLogFormatter formatter = DiagnosticLogFormatter();
  final DateTime utcMoment = DateTime.utc(2026, 5, 15, 10, 30, 0);

  Map<String, Object?> parse(String line) {
    expect(
      line.endsWith('\n'),
      isTrue,
      reason: 'JSON Lines must terminate with \\n',
    );
    return jsonDecode(line.trimRight()) as Map<String, Object?>;
  }

  group('DiagnosticLogFormatter envelope', () {
    test('全 4 種 variant に t / sev / kind が必ず出る', () {
      final List<DiagnosticEvent> events = <DiagnosticEvent>[
        DiagnosticEvent.uncaughtException(
          occurredAt: utcMoment,
          exceptionType: 'X',
          stackTraceDigest: 'a',
        ),
        DiagnosticEvent.permissionTransition(
          occurredAt: utcMoment,
          permissionKind: PermissionKind.postNotifications,
          before: DomainPermissionStatus.unknown,
          after: DomainPermissionStatus.granted,
        ),
        DiagnosticEvent.notificationFired(
          occurredAt: utcMoment,
          payloadId: 'pid',
          fireKind: NotificationFireKind.alarmFired,
        ),
        DiagnosticEvent.timerAction(
          occurredAt: utcMoment,
          timerId: 'tid',
          action: TimerActionKind.start,
        ),
      ];
      for (final DiagnosticEvent e in events) {
        final Map<String, Object?> r = parse(formatter.format(e));
        expect(r['t'], '2026-05-15T10:30:00.000Z');
        expect(r['sev'], e.severity.name);
        expect(r['kind'], e.kind);
      }
    });

    test('ローカルタイム入力は UTC に正規化される', () {
      final DateTime local = DateTime(2026, 5, 15, 10, 30);
      final DiagnosticEvent e = DiagnosticEvent.timerAction(
        occurredAt: local,
        timerId: 'x',
        action: TimerActionKind.start,
      );
      final Map<String, Object?> r = parse(formatter.format(e));
      final String t = r['t']! as String;
      expect(t.endsWith('Z'), isTrue);
      expect(DateTime.parse(t), local.toUtc());
    });
  });

  group('DiagnosticLogFormatter payload merge', () {
    test('uncaughtException: exceptionType / stackTraceDigest が出る', () {
      final Map<String, Object?> r = parse(
        formatter.format(
          DiagnosticEvent.uncaughtException(
            occurredAt: utcMoment,
            exceptionType: 'FormatException',
            stackTraceDigest: 'at A\nat B',
          ),
        ),
      );
      expect(r['exceptionType'], 'FormatException');
      // JSON エンコードで改行は \n に保存される。デコードすると復元される。
      expect(r['stackTraceDigest'], 'at A\nat B');
    });

    test('permissionTransition: enum.name で出力される', () {
      final Map<String, Object?> r = parse(
        formatter.format(
          DiagnosticEvent.permissionTransition(
            occurredAt: utcMoment,
            permissionKind: PermissionKind.scheduleExactAlarm,
            before: DomainPermissionStatus.denied,
            after: DomainPermissionStatus.granted,
          ),
        ),
      );
      expect(r['permissionKind'], 'scheduleExactAlarm');
      expect(r['before'], 'denied');
      expect(r['after'], 'granted');
    });
  });

  group('DiagnosticLogFormatter encoding', () {
    test('日本語 / マルチバイトが破損しない', () {
      // ※ 通常は PII 制約で日本語ラベルは載らないが、stackTraceDigest に
      // 例外メッセージ由来の文字が混ざることはあり得るので保険的に検証。
      final Map<String, Object?> r = parse(
        formatter.format(
          DiagnosticEvent.uncaughtException(
            occurredAt: utcMoment,
            exceptionType: 'CustomException',
            stackTraceDigest: '日本語スタック',
          ),
        ),
      );
      expect(r['stackTraceDigest'], '日本語スタック');
    });

    test('format() は単一行で終端が \\n', () {
      final String out = formatter.format(
        DiagnosticEvent.timerAction(
          occurredAt: utcMoment,
          timerId: 'x',
          action: TimerActionKind.start,
        ),
      );
      // 改行は末尾の 1 つだけ
      expect(out.endsWith('\n'), isTrue);
      expect(out.substring(0, out.length - 1).contains('\n'), isFalse);
    });
  });
}
