import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/main.dart';

void main() {
  testWidgets('App boots and renders home screen with stopwatch entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TimerUtilityApp()));
    await tester.pumpAndSettle();

    expect(find.text('TimerUtility'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('home_open_stopwatch_button')), findsOneWidget);
  });
}
