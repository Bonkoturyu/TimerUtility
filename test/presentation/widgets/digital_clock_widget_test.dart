import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/presentation/widgets/digital_clock_widget.dart';

/// Fake resolver that ignores its inputs and returns a pre-baked wall
/// clock. Keeps this widget test hermetic — TZ database / IANA
/// resolution semantics are exercised separately in
/// `tz_database_timezone_resolver_test.dart`.
class _FixedResolver implements TimezoneResolver {
  _FixedResolver(this._returns);
  final DateTime _returns;
  @override
  DateTime computeAt(DateTime now, String timezoneId) => _returns;
}

Future<void> _pump(
  WidgetTester tester, {
  required DateTime fakeWall,
  bool showSeconds = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        timezoneResolverProvider.overrideWithValue(_FixedResolver(fakeWall)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DigitalClockWidget(
            time: DateTime.utc(2026, 1, 15, 12),
            timezoneId: 'Asia/Tokyo',
            showSeconds: showSeconds,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DigitalClockWidget', () {
    testWidgets('Fake が 21:00:00 を返したとき HH:mm:ss が表示される', (
      WidgetTester tester,
    ) async {
      await _pump(tester, fakeWall: DateTime(2026, 1, 15, 21));
      expect(find.text('21:00:00'), findsOneWidget);
    });

    testWidgets('showSeconds: false で秒表記が省略される (21:00)', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        fakeWall: DateTime(2026, 1, 15, 21),
        showSeconds: false,
      );
      expect(find.text('21:00'), findsOneWidget);
      expect(find.text('21:00:00'), findsNothing);
    });

    testWidgets('00:00:00 (深夜) でも 2 桁ゼロ埋めが維持される', (WidgetTester tester) async {
      // padLeft 実装の境界ケース。1 桁になりがちな時刻でも HH:mm:ss を維持。
      await _pump(tester, fakeWall: DateTime(2026, 1, 15));
      expect(find.text('00:00:00'), findsOneWidget);
    });
  });
}
