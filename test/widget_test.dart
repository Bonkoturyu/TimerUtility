import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/main.dart';

void main() {
  testWidgets('App boots and renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TimerUtilityApp()));
    await tester.pumpAndSettle();

    expect(find.text('TimerUtility'), findsOneWidget);
    expect(find.text('Phase 1: Skeleton'), findsOneWidget);
  });
}
