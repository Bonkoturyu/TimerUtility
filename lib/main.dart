import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/notification_scheduler_provider.dart';
import 'application/timer_repository_provider.dart';
import 'infrastructure/database/app_database.dart';
import 'infrastructure/database/drift_timer_repository.dart';
import 'infrastructure/notification/flutter_local_notification_adapter.dart';
import 'presentation/screens/alarm_ringing_screen.dart';
import 'presentation/screens/stopwatch_screen.dart';
import 'presentation/screens/timer_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adapter = FlutterLocalNotificationAdapter();
  final AppDatabase database = AppDatabase();
  final DriftTimerRepository repository = DriftTimerRepository(database);

  // `late final` lets the warm-launch tap callback reference the router
  // that's only constructed after we know the cold-launch payload below.
  late final GoRouter router;
  await adapter.initialize(
    onNotificationTap: (String? payload) {
      // Warm-launch path (app already running): navigate to the alarm
      // screen. The payload (timer id) is not used yet — Phase 8 will
      // need it once multiple timers can ring concurrently.
      if (payload == null) return;
      // Skip if we're already on the alarm screen. TimerScreen's ringing
      // listener also pushes when the timer flips to `ringing`, so without
      // this guard the screen can end up stacked twice (warm-launch tap
      // race) and Stop only pops one layer at a time.
      final RouteMatch last = router.routerDelegate.currentConfiguration.last;
      if (last.matchedLocation == '/alarm-ringing') return;
      router.go('/alarm-ringing');
    },
  );

  // Cold-launch path: if the user tapped the notification while the
  // process was dead, the `onNotificationTap` callback above does not
  // fire. We probe the plugin for that case and adjust the initial
  // location so the user lands on the alarm screen instead of the home.
  final String? coldLaunchPayload = await adapter.coldLaunchPayload();
  final String initialLocation = coldLaunchPayload != null
      ? '/alarm-ringing'
      : '/';

  router = GoRouter(
    initialLocation: initialLocation,
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
            const TimerListScreen(),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmRingingScreen(),
      ),
    ],
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        notificationSchedulerProvider.overrideWithValue(adapter),
        timerRepositoryProvider.overrideWithValue(repository),
      ],
      child: TimerUtilityApp(router: router),
    ),
  );
}

class TimerUtilityApp extends StatelessWidget {
  const TimerUtilityApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TimerUtility',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
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
