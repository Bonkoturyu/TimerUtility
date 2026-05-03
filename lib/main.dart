import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart'
    show LicenseEntry, LicenseParagraph, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/notification_scheduler_provider.dart';
import 'application/notification_strings_provider.dart';
import 'application/preset_repository_provider.dart';
import 'application/timer_collection_notifier.dart';
import 'application/timer_repository_provider.dart';
import 'application/user_preferences_provider.dart';
import 'infrastructure/database/app_database.dart';
import 'infrastructure/database/drift_preset_repository.dart';
import 'infrastructure/database/drift_timer_repository.dart';
import 'infrastructure/notification/flutter_local_notification_adapter.dart';
import 'infrastructure/preferences/shared_preferences_user_preferences.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/alarm_ringing_screen.dart';
import 'presentation/screens/licenses_screen.dart';
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

/// Resolve the localized strings used for OS notifications against the
/// device's preferred locale, fall back to the first supported locale
/// when no match exists. Notifier code can't call
/// `AppLocalizations.of(context)` (no `BuildContext`), so we resolve
/// against `AppLocalizations.delegate.load` and stash the result in
/// `notificationStringsNotifierProvider`.
///
/// Called both at startup (initial value) and from
/// `_TimerUtilityAppState.didChangeLocales` whenever the OS reports a
/// locale change — so a JA→EN switch updates pending banners after a
/// `rescheduleAllRunning()` follow-up.
Future<NotificationStrings> _resolveNotificationStrings() async {
  final List<Locale> systemLocales =
      WidgetsBinding.instance.platformDispatcher.locales;
  final Locale resolved = basicLocaleListResolution(
    systemLocales,
    supportedLocales,
  );
  final AppLocalizations l = await AppLocalizations.delegate.load(resolved);
  return NotificationStrings(
    timerEndedTitle: l.notificationTimerEndedTitle,
    timerEndedBody: l.notificationTimerEndedBody,
    timerCompletedBackgroundBody: l.notificationTimerCompletedBackgroundBody,
  );
}

/// Notifier subclass used as the override target — `build()` returns the
/// pre-resolved value supplied at app startup instead of throwing the
/// "must be overridden" assertion the base class uses to catch missing
/// test wiring.
class _BootstrappedNotificationStringsNotifier
    extends NotificationStringsNotifier {
  _BootstrappedNotificationStringsNotifier(this._initial);
  final NotificationStrings _initial;

  @override
  NotificationStrings build() => _initial;
}

/// Register the bundled-sound license file (`assets/sounds/LICENSES.md`)
/// so Flutter's `showLicensePage` lists it alongside pub-package licenses.
///
/// We split the markdown by `## <file>.mp3` headers and yield one entry
/// per audio file. Naming each entry `<file>.mp3 (bundled)` makes it
/// obvious in the license list that these are app-owned resources, not
/// pub dependencies. The body is split into one paragraph per line so
/// `showLicensePage` renders the bullet list legibly — by default
/// `LicenseEntryWithLineBreaks` joins single newlines and you'd see
/// every bullet collapsed into a single wall of text.
///
/// `LicenseRegistry.addLicense` takes a callback that returns a stream
/// of entries — the asset is read lazily the first time the license page
/// is opened, so this adds no startup cost.
void _registerBundledSoundsLicense() {
  LicenseRegistry.addLicense(() async* {
    final String content = await rootBundle.loadString(
      'assets/sounds/LICENSES.md',
    );
    final List<String> lines = content.split('\n');
    String? currentName;
    final List<String> currentLines = <String>[];

    Iterable<_BundledSoundLicenseEntry> flush() sync* {
      if (currentName != null) {
        yield _BundledSoundLicenseEntry(
          packageName: '$currentName (bundled)',
          lines: List<String>.unmodifiable(currentLines),
        );
      }
    }

    for (final String raw in lines) {
      final String line = raw.trimRight();
      if (line.startsWith('## ')) {
        for (final _BundledSoundLicenseEntry entry in flush()) {
          yield entry;
        }
        currentName = line.substring(3).trim();
        currentLines.clear();
      } else if (currentName != null) {
        currentLines.add(line);
      }
    }
    for (final _BundledSoundLicenseEntry entry in flush()) {
      yield entry;
    }
  });
}

/// Custom [LicenseEntry] that emits each source line as its own
/// `LicenseParagraph` — fixes the "wall of text" rendering of
/// `LicenseEntryWithLineBreaks` when the source uses single newlines
/// between bullets.
class _BundledSoundLicenseEntry extends LicenseEntry {
  _BundledSoundLicenseEntry({required this.packageName, required this.lines});
  final String packageName;
  final List<String> lines;

  @override
  Iterable<String> get packages => <String>[packageName];

  @override
  // indent 0 = no left padding, left-aligned. Each source line is its
  // own paragraph so bullet lists render with line breaks.
  Iterable<LicenseParagraph> get paragraphs =>
      lines.map((String line) => LicenseParagraph(line, 0));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerBundledSoundsLicense();
  final NotificationStrings notificationStrings =
      await _resolveNotificationStrings();
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
      // The matchedLocation check is best-effort and can race with the
      // ringing listener's push when both fire in the same frame
      // (notification tap + ticker tick on app resume). Defer to the
      // synchronous reservation flag so only one path actually pushes.
      if (!AlarmRingingScreen.tryReservePush()) return;
      // Use push (not go) so the previous screen stays on the stack.
      // Combined with `_leaveAlarmScreen`'s pop-when-possible behavior,
      // this lets the user back-navigate to home after dismissing the
      // alarm.
      router.push('/alarm-ringing');
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
      GoRoute(
        path: LicensesScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const LicensesScreen(),
      ),
    ],
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        notificationSchedulerProvider.overrideWithValue(adapter),
        notificationStringsNotifierProvider.overrideWith(
          () => _BootstrappedNotificationStringsNotifier(notificationStrings),
        ),
        timerRepositoryProvider.overrideWithValue(repository),
        presetRepositoryProvider.overrideWithValue(presetRepo),
        userPreferencesProvider.overrideWithValue(userPrefs),
      ],
      child: TimerUtilityApp(router: router),
    ),
  );
}

/// Top-level app widget. Stateful so we can attach a
/// [WidgetsBindingObserver] and react to OS-driven locale changes:
/// when the user switches device language, we re-resolve the
/// notification strings and replace any in-flight scheduled banner so
/// running timers fire in the new language. Without this, the strings
/// stay locked to the locale active at process start.
class TimerUtilityApp extends ConsumerStatefulWidget {
  const TimerUtilityApp({super.key, required this.router});

  final GoRouter router;

  @override
  ConsumerState<TimerUtilityApp> createState() => _TimerUtilityAppState();
}

class _TimerUtilityAppState extends ConsumerState<TimerUtilityApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    // Fire-and-forget: re-resolve against the new device locale, push
    // the fresh strings into the provider, and re-schedule running
    // timers so their pending OS banners switch language too.
    unawaited(_refreshNotificationLocale());
  }

  Future<void> _refreshNotificationLocale() async {
    final NotificationStrings strings = await _resolveNotificationStrings();
    if (!mounted) return;
    ref.read(notificationStringsNotifierProvider.notifier).set(strings);
    ref.read(timerCollectionNotifierProvider.notifier).rescheduleAllRunning();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TimerUtility',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: widget.router,
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
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('home_menu'),
            onSelected: (String value) {
              if (value == 'licenses') {
                context.push(LicensesScreen.routeLocation);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                key: const Key('home_menu_licenses'),
                value: 'licenses',
                child: Text(l.licenseMenuOverflow),
              ),
            ],
          ),
        ],
      ),
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
