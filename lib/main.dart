import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/stopwatch_screen.dart';
import 'presentation/screens/timer_screen.dart';

void main() {
  runApp(const ProviderScope(child: TimerUtilityApp()));
}

final _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/stopwatch',
      builder: (BuildContext context, GoRouterState state) =>
          const StopwatchScreen(),
    ),
    GoRoute(
      path: '/timer',
      builder: (BuildContext context, GoRouterState state) =>
          const TimerScreen(),
    ),
  ],
);

class TimerUtilityApp extends StatelessWidget {
  const TimerUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TimerUtility',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TimerUtility')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('TimerUtility'),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('home_open_stopwatch_button'),
              onPressed: () => context.go('/stopwatch'),
              child: const Text('Open Stopwatch'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('home_open_timer_button'),
              onPressed: () => context.go('/timer'),
              child: const Text('Open Timer'),
            ),
          ],
        ),
      ),
    );
  }
}
