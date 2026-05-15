import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_event.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_logger.dart';
import 'package:timer_utility/domain/ports/diagnostic_sink.dart';

/// Minimal in-test sink (we deliberately avoid pulling the
/// infrastructure InMemoryDiagnosticSinkAdapter into a domain test so
/// the Pure-Dart import boundary is respected).
class _RecordingSink implements DiagnosticSink {
  final List<DiagnosticEvent> events = <DiagnosticEvent>[];
  int flushCount = 0;

  @override
  void write(DiagnosticEvent event) => events.add(event);

  @override
  Future<void> flush() async => flushCount++;
}

void main() {
  final DateTime t = DateTime.utc(2026, 5, 15, 10);
  final DiagnosticEvent debugEvent = DiagnosticEvent.timerAction(
    occurredAt: t,
    timerId: 'id',
    action: TimerActionKind.start,
  );
  final DiagnosticEvent infoEvent = DiagnosticEvent.notificationFired(
    occurredAt: t,
    payloadId: 'id',
    fireKind: NotificationFireKind.timerFired,
  );

  group('DiagnosticLogger.log', () {
    test('isEnabled=false なら sink に書き込まない', () {
      final _RecordingSink sink = _RecordingSink();
      final DiagnosticLogger logger = DiagnosticLogger(
        sink: sink,
        isEnabled: () => false,
        threshold: DiagnosticSeverity.debug,
      );
      logger.log(infoEvent);
      expect(sink.events, isEmpty);
    });

    test('isEnabled=true かつ severity が閾値以上なら書き込む', () {
      final _RecordingSink sink = _RecordingSink();
      final DiagnosticLogger logger = DiagnosticLogger(
        sink: sink,
        isEnabled: () => true,
        threshold: DiagnosticSeverity.debug,
      );
      logger.log(debugEvent);
      logger.log(infoEvent);
      expect(sink.events, hasLength(2));
    });

    test('severity が閾値未満なら drop される', () {
      final _RecordingSink sink = _RecordingSink();
      final DiagnosticLogger logger = DiagnosticLogger(
        sink: sink,
        isEnabled: () => true,
        // info 以上のみ通す。debug はドロップ。
        threshold: DiagnosticSeverity.info,
      );
      logger.log(debugEvent);
      logger.log(infoEvent);
      expect(sink.events, <DiagnosticEvent>[infoEvent]);
    });

    test('isEnabled は call ごとに評価される (動的に flip 可能)', () {
      final _RecordingSink sink = _RecordingSink();
      bool enabled = false;
      final DiagnosticLogger logger = DiagnosticLogger(
        sink: sink,
        isEnabled: () => enabled,
        threshold: DiagnosticSeverity.debug,
      );
      logger.log(debugEvent);
      expect(sink.events, isEmpty);
      enabled = true;
      logger.log(debugEvent);
      expect(sink.events, hasLength(1));
      enabled = false;
      logger.log(debugEvent);
      expect(sink.events, hasLength(1));
    });
  });
}
