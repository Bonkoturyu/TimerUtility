import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/notification_scheduler_provider.dart';
import 'infrastructure/notification/flutter_local_notification_adapter.dart';
import 'presentation/screens/alarm_ringing_screen.dart';
import 'presentation/screens/stopwatch_screen.dart';
import 'presentation/screens/timer_screen.dart';

final GoRouter _router = GoRouter(
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
    GoRoute(
      path: '/alarm-ringing',
      builder: (BuildContext context, GoRouterState state) =>
          const AlarmRingingScreen(),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adapter = FlutterLocalNotificationAdapter();
  await adapter.initialize(
    onNotificationTap: (String? payload) {
      // Phase 5 deep-link: tapping the timer-end notification jumps
      // straight to the alarm ringing screen. The payload (timer id) is
      // not used yet — Phase 8 will need it once multiple timers can
      // ring concurrently.
      if (payload != null) {
        _router.go('/alarm-ringing');
      }
    },
  );
  runApp(
    ProviderScope(
      overrides: <Override>[
        notificationSchedulerProvider.overrideWithValue(adapter),
      ],
      child: const TimerUtilityApp(),
    ),
  );
}

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
