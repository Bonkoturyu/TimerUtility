import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timer_utility/main.dart';

void main() {
  testWidgets('App boots and renders home screen with stopwatch entry', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: TimerUtilityApp(router: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('TimerUtility'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('home_open_stopwatch_button')), findsOneWidget);
  });
}
