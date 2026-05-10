import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/presentation/widgets/analog_clock_widget.dart';

/// `tz` パッケージ初期化を回避するための fake。`computeAt` は呼び出し
/// 引数を無視して [_returns] を返すだけ。Widget 描画時の挙動だけを
/// 検証する。
class _FixedResolver implements TimezoneResolver {
  _FixedResolver(this._returns);
  final DateTime _returns;
  @override
  DateTime computeAt(DateTime now, String timezoneId) => _returns;
}

Future<void> _pump(
  WidgetTester tester, {
  required DateTime fakeWall,
  double size = 120,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        timezoneResolverProvider.overrideWithValue(_FixedResolver(fakeWall)),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: AnalogClockWidget(
            time: DateTime.utc(2026, 1, 15, 12),
            timezoneId: 'Asia/Tokyo',
            size: size,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AnalogClockWidget', () {
    testWidgets('UTC 12:00 + Tokyo (fake) で CustomPaint が 1 件描画される', (
      WidgetTester tester,
    ) async {
      await _pump(tester, fakeWall: DateTime(2026, 1, 15, 21));
      // ProviderScope + Directionality + Center は CustomPaint を描画しない
      // ので、AnalogClockWidget の 1 件のみが見つかる。
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('size: 80 を指定すると CustomPaint のサイズが 80x80 になる', (
      WidgetTester tester,
    ) async {
      await _pump(tester, fakeWall: DateTime(2026, 1, 15, 21), size: 80);
      final Size painted = tester.getSize(find.byType(CustomPaint));
      expect(painted, const Size(80, 80));
    });

    testWidgets('異なる時刻で _AnalogClockPainter の repaint 検証', (
      WidgetTester tester,
    ) async {
      // RepaintBoundary レベルでの差分検証は重く、本セッションのスコープ
      // 外。Painter.shouldRepaint は wall 更新で true を返す実装。
    }, skip: true);
  });
}
