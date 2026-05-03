import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timer_utility/main.dart';
import 'package:timer_utility/presentation/screens/licenses_screen.dart';

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

    // The "TimerUtility" string is the localized appTitle. It appears
    // in both ja and en ARB as the same literal so any host locale works.
    expect(find.text('TimerUtility'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('home_open_stopwatch_button')), findsOneWidget);
  });

  testWidgets('Home AppBar overflow opens the licenses screen', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/licenses', builder: (_, _) => const LicensesScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: TimerUtilityApp(router: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_menu_licenses')));
    await tester.pumpAndSettle();

    // Both ExpansionTile section headers should be present.
    expect(find.byKey(const Key('licenses_group_bundled')), findsOneWidget);
    expect(find.byKey(const Key('licenses_group_software')), findsOneWidget);
  });
}
