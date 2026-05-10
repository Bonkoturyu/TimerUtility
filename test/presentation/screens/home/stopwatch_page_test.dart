import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/home/stopwatch_page.dart';

/// Phase 11 smoke test for [StopwatchPage]. The Page widget no longer
/// owns a Scaffold, so we wrap it in one for the test harness — the
/// production caller (HomeScreen / StopwatchScreen) does the same.
Widget _harness() {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 10, 12))),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: <Locale>[Locale('en'), Locale('ja')],
      home: Scaffold(body: StopwatchPage()),
    ),
  );
}

void main() {
  group('StopwatchPage (Phase 11 body widget)', () {
    testWidgets('renders 00:00.00 and a Start button on first paint', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());

      expect(find.byKey(const Key('stopwatch_display')), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const Key('stopwatch_display')))).data,
        '00:00.00',
      );
      expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);
    });
  });
}
