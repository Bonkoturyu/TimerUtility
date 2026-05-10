import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/main.dart';
import 'package:timer_utility/presentation/screens/alarm_list_screen.dart';
import 'package:timer_utility/presentation/screens/clock_location_picker_screen.dart';
import 'package:timer_utility/presentation/screens/clock_screen.dart';

/// HomeScreen の 4 ボタン → 各画面への遷移を検証する smoke test。
///
/// 各 route の builder は軽量 placeholder Scaffold を返す。実画面を
/// マウントすると provider override が肥大するため、ここでは route が
/// 到達したかだけを確認する (ClockScreen 自体の挙動は別 test に任せる)。
Widget _harness() {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: '/stopwatch',
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          body: Center(child: Text('stopwatch route reached')),
        ),
      ),
      GoRoute(
        path: '/timer',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Center(child: Text('timer route reached'))),
      ),
      GoRoute(
        path: AlarmListScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Center(child: Text('alarm route reached'))),
      ),
      GoRoute(
        path: ClockScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Center(child: Text('clock route reached'))),
      ),
      GoRoute(
        path: ClockLocationPickerScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          body: Center(child: Text('clock-locations route reached')),
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

void main() {
  testWidgets('Stopwatch ボタンタップで /stopwatch に遷移する', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_open_stopwatch_button')));
    await tester.pumpAndSettle();

    expect(find.text('stopwatch route reached'), findsOneWidget);
  });

  testWidgets('Timer ボタンタップで /timer に遷移する', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_open_timer_button')));
    await tester.pumpAndSettle();

    expect(find.text('timer route reached'), findsOneWidget);
  });

  testWidgets('Alarm ボタンタップで /alarms に遷移する', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_open_alarm_button')));
    await tester.pumpAndSettle();

    expect(find.text('alarm route reached'), findsOneWidget);
  });

  testWidgets('Clock ボタンタップで /clock に遷移する', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_open_clock_button')));
    await tester.pumpAndSettle();

    expect(find.text('clock route reached'), findsOneWidget);
  });
}
