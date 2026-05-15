import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_event.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';

void main() {
  final DateTime t = DateTime.utc(2026, 5, 15, 10, 30);

  group('DiagnosticEvent.uncaughtException', () {
    test('severity / kind / payload を返す', () {
      final DiagnosticEvent e = DiagnosticEvent.uncaughtException(
        occurredAt: t,
        exceptionType: 'FormatException',
        stackTraceDigest: 'at A\nat B',
      );
      expect(e.severity, DiagnosticSeverity.error);
      expect(e.kind, 'uncaughtException');
      expect(e.toJsonPayload(), <String, Object?>{
        'exceptionType': 'FormatException',
        'stackTraceDigest': 'at A\nat B',
      });
    });

    test('equality は全フィールド一致で成立', () {
      final DiagnosticEvent a = DiagnosticEvent.uncaughtException(
        occurredAt: t,
        exceptionType: 'X',
        stackTraceDigest: 'd',
      );
      final DiagnosticEvent b = DiagnosticEvent.uncaughtException(
        occurredAt: t,
        exceptionType: 'X',
        stackTraceDigest: 'd',
      );
      final DiagnosticEvent c = DiagnosticEvent.uncaughtException(
        occurredAt: t,
        exceptionType: 'Y',
        stackTraceDigest: 'd',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('DiagnosticEvent.permissionTransition', () {
    test('severity = info / payload に enum.name が入る', () {
      final DiagnosticEvent e = DiagnosticEvent.permissionTransition(
        occurredAt: t,
        permissionKind: PermissionKind.postNotifications,
        before: DomainPermissionStatus.unknown,
        after: DomainPermissionStatus.granted,
      );
      expect(e.severity, DiagnosticSeverity.info);
      expect(e.kind, 'permissionTransition');
      expect(e.toJsonPayload(), <String, Object?>{
        'permissionKind': 'postNotifications',
        'before': 'unknown',
        'after': 'granted',
      });
    });
  });

  group('DiagnosticEvent.notificationFired', () {
    test('payloadId と fireKind が JSON に出る', () {
      final DiagnosticEvent e = DiagnosticEvent.notificationFired(
        occurredAt: t,
        payloadId: 'abc-123',
        fireKind: NotificationFireKind.alarmFired,
      );
      expect(e.severity, DiagnosticSeverity.info);
      expect(e.kind, 'notificationFired');
      expect(e.toJsonPayload(), <String, Object?>{
        'payloadId': 'abc-123',
        'fireKind': 'alarmFired',
      });
    });
  });

  group('DiagnosticEvent.timerAction', () {
    test('severity = debug / action.name が JSON に出る', () {
      final DiagnosticEvent e = DiagnosticEvent.timerAction(
        occurredAt: t,
        timerId: 'uuid-1',
        action: TimerActionKind.start,
      );
      expect(e.severity, DiagnosticSeverity.debug);
      expect(e.kind, 'timerAction');
      expect(e.toJsonPayload(), <String, Object?>{
        'timerId': 'uuid-1',
        'action': 'start',
      });
    });

    test('factory 経由でも具象クラスに redirect される (pattern match)', () {
      final DiagnosticEvent e = DiagnosticEvent.timerAction(
        occurredAt: t,
        timerId: 'uuid-2',
        action: TimerActionKind.pause,
      );
      expect(e, isA<DiagnosticTimerAction>());
      // exhaustive switch (sealed) でも全 4 分岐が解決できることを確認。
      final String kind = switch (e) {
        DiagnosticUncaughtException() => 'ue',
        DiagnosticPermissionTransition() => 'pt',
        DiagnosticNotificationFired() => 'nf',
        DiagnosticTimerAction() => 'ta',
      };
      expect(kind, 'ta');
    });
  });

  group('PII invariants', () {
    test('どの factory もラベル / 緯度経度の引数を受け取らない (構造的検証)', () {
      // 構造的検証: factory のパラメータ名に label / lat / lon / location が
      // 含まれないことを runtime で確認するのは困難なので、ここでは
      // toJsonPayload() の中身に「label」「latitude」「longitude」キーが
      // 混入していないことを 4 種すべて確認する。
      final List<DiagnosticEvent> events = <DiagnosticEvent>[
        DiagnosticEvent.uncaughtException(
          occurredAt: t,
          exceptionType: 'E',
          stackTraceDigest: 's',
        ),
        DiagnosticEvent.permissionTransition(
          occurredAt: t,
          permissionKind: PermissionKind.fullScreenIntent,
          before: DomainPermissionStatus.denied,
          after: DomainPermissionStatus.granted,
        ),
        DiagnosticEvent.notificationFired(
          occurredAt: t,
          payloadId: 'p',
          fireKind: NotificationFireKind.timerFired,
        ),
        DiagnosticEvent.timerAction(
          occurredAt: t,
          timerId: 'id',
          action: TimerActionKind.create,
        ),
      ];
      for (final DiagnosticEvent e in events) {
        final Map<String, Object?> payload = e.toJsonPayload();
        for (final String forbidden in <String>[
          'label',
          'latitude',
          'longitude',
          'location',
        ]) {
          expect(
            payload.containsKey(forbidden),
            isFalse,
            reason: '${e.kind} は $forbidden を含むべきでない',
          );
        }
      }
    });
  });
}
