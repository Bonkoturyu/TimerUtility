import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/notification_scheduler_provider.dart';
import 'application/preset_repository_provider.dart';
import 'application/timer_repository_provider.dart';
import 'application/user_preferences_provider.dart';
import 'infrastructure/database/app_database.dart';
import 'infrastructure/database/drift_preset_repository.dart';
import 'infrastructure/database/drift_timer_repository.dart';
import 'infrastructure/notification/flutter_local_notification_adapter.dart';
import 'infrastructure/preferences/shared_preferences_user_preferences.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/alarm_ringing_screen.dart';
import 'presentation/screens/preset_manage_screen.dart';
import 'presentation/screens/stopwatch_screen.dart';
import 'presentation/screens/timer_list_screen.dart';

/// Compile-time feature flag for experimental locales (zh-Hans / zh-Hant /
/// ko). The public release ships with Japanese + English only; the other
/// locales' ARB files exist for internal development and are reachable
/// from a debug build with `--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true`.
///
/// Phase 11 (settings screen) will likely flip this to a runtime
/// preference; for now the compile-time gate keeps test surface small.
const bool kEnableExperimentalLocales = bool.fromEnvironment(
  'ENABLE_EXPERIMENTAL_LOCALES',
  defaultValue: false,
);

const List<Locale> _publicSupportedLocales = <Locale>[
  Locale('ja'),
  Locale('en'),
];

const List<Locale> _experimentalSupportedLocales = <Locale>[
  Locale('zh'),
  Locale('zh', 'Hant'),
  Locale('ko'),
];

List<Locale> get supportedLocales => <Locale>[
  ..._publicSupportedLocales,
  if (kEnableExperimentalLocales) ..._experimentalSupportedLocales,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adapter = FlutterLocalNotificationAdapter();
  final AppDatabase database = AppDatabase();
  final DriftTimerRepository repository = DriftTimerRepository(database);
  final DriftPresetRepository presetRepo = DriftPresetRepository(database);
  final SharedPreferencesUserPreferences userPrefs =
      await SharedPreferencesUserPreferences.create();

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
      GoRoute(
        path: '/presets',
        builder: (BuildContext context, GoRouterState state) =>
            const PresetManageScreen(),
      ),
    ],
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        notificationSchedulerProvider.overrideWithValue(adapter),
        timerRepositoryProvider.overrideWithValue(repository),
        presetRepositoryProvider.overrideWithValue(presetRepo),
        userPreferencesProvider.overrideWithValue(userPrefs),
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(l.appTitle),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('home_open_stopwatch_button'),
              // push (not go) so back from the inner screen returns to
              // home rather than exiting the app.
              onPressed: () => context.push('/stopwatch'),
              child: Text(l.homeOpenStopwatch),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('home_open_timer_button'),
              onPressed: () => context.push('/timer'),
              child: Text(l.homeOpenTimer),
            ),
          ],
        ),
      ),
    );
  }
}
