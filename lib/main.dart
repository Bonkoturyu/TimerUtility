import 'dart:async' show unawaited;
import 'dart:io' show Directory;

import 'package:clock/clock.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'
    show
        LicenseEntry,
        LicenseParagraph,
        LicenseRegistry,
        PlatformDispatcher,
        kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/alarm_repository_provider.dart';
import 'application/clock_entry_repository_provider.dart';
import 'application/diagnostic_log_exporter_provider.dart';
import 'application/diagnostic_logger_provider.dart';
import 'application/diagnostic_settings_notifier.dart';
import 'application/diagnostic_sink_provider.dart';
import 'application/location_detector_provider.dart';
import 'application/notification_scheduler_provider.dart';
import 'application/notification_strings_provider.dart';
import 'application/preset_repository_provider.dart';
import 'application/settings_notifier.dart';
import 'application/timer_collection_notifier.dart';
import 'application/timer_repository_provider.dart';
import 'application/timezone_resolver_provider.dart';
import 'application/user_preferences_provider.dart';
import 'domain/diagnostics/diagnostic_event.dart';
import 'domain/ports/diagnostic_sink.dart';
import 'domain/ports/user_preferences.dart';
import 'infrastructure/database/app_database.dart';
import 'infrastructure/database/drift_alarm_repository.dart';
import 'infrastructure/clock/tz_database_timezone_resolver.dart';
import 'infrastructure/database/drift_clock_entry_repository.dart';
import 'infrastructure/database/drift_preset_repository.dart';
import 'infrastructure/database/drift_timer_repository.dart';
import 'infrastructure/diagnostics/diagnostic_log_formatter.dart';
import 'infrastructure/diagnostics/diagnostic_log_rotator.dart';
import 'infrastructure/diagnostics/file_diagnostic_sink_adapter.dart';
import 'infrastructure/diagnostics/zip_diagnostic_log_exporter_adapter.dart';
import 'infrastructure/location/location_detector_adapter.dart';
import 'infrastructure/notification/flutter_local_notification_adapter.dart';
import 'infrastructure/preferences/shared_preferences_user_preferences.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/alarm_edit_screen.dart';
import 'presentation/screens/alarm_list_screen.dart';
import 'presentation/screens/alarm_ringing_screen.dart';
import 'presentation/screens/clock_entry_edit_screen.dart';
import 'presentation/screens/clock_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/licenses_screen.dart';
import 'presentation/screens/preset_manage_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/stopwatch_screen.dart';
import 'presentation/screens/timer_list_screen.dart';

const List<Locale> _publicSupportedLocales = <Locale>[
  Locale('ja'),
  Locale('en'),
];

const List<Locale> _experimentalSupportedLocales = <Locale>[
  Locale('zh'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  Locale('ko'),
];

/// Exposed for tests so the locale-form invariant for `zh_Hant`
/// (scriptCode form, not countryCode form — see PR #61 / Copilot review)
/// can be verified independently of the `kEnableExperimentalLocales`
/// compile-time flag, which would otherwise hide the list from the
/// default `flutter test` run.
@visibleForTesting
const List<Locale> debugExperimentalSupportedLocales =
    _experimentalSupportedLocales;

List<Locale> get supportedLocales => <Locale>[
  ..._publicSupportedLocales,
  if (kEnableExperimentalLocales) ..._experimentalSupportedLocales,
];

/// Resolve a device locale to one of [supported], falling back to
/// [Locale('en')] when no language code matches.
///
/// This intentionally differs from Flutter's default
/// `basicLocaleListResolution`, which falls back to `supported[0]` —
/// here we fall back to English to give users of unsupported languages
/// a more globally readable text than Japanese.
///
/// We evaluate a **single** device locale (not the full preferred-locale
/// chain) because Flutter's `localeResolutionCallback` only hands us
/// one locale, and we want the notification resolver to behave the same
/// way. If the language code matches any entry in [supported], we
/// delegate to `basicLocaleListResolution` (with a singleton list) so
/// the SDK can still pick the best script/country variant.
@visibleForTesting
Locale resolveSupportedLocale(Locale? deviceLocale, List<Locale> supported) {
  if (deviceLocale != null) {
    for (final Locale s in supported) {
      if (s.languageCode == deviceLocale.languageCode) {
        return basicLocaleListResolution(<Locale>[deviceLocale], supported);
      }
    }
  }
  return const Locale('en');
}

/// Resolve the localized strings used for OS notifications against the
/// device's preferred locale. Delegates to [resolveSupportedLocale], so
/// any locale whose language code isn't in [supportedLocales] falls
/// back to `Locale('en')` — matching the UI side's
/// `localeResolutionCallback` behavior. Notifier code can't call
/// `AppLocalizations.of(context)` (no `BuildContext`), so we resolve
/// against `AppLocalizations.delegate.load` and stash the result in
/// `notificationStringsNotifierProvider`.
///
/// We evaluate only `platformDispatcher.locales.first` (not the full
/// chain) to keep UI and notification semantics identical — Flutter's
/// `localeResolutionCallback` only hands us a single locale.
///
/// Called both at startup (initial value) and from
/// `_TimerUtilityAppState.didChangeLocales` whenever the OS reports a
/// locale change — so a JA→EN switch updates pending banners after a
/// `rescheduleAllRunning()` follow-up.
///
/// Phase 11 language-toggle: when the user has chosen a manual override
/// in settings, the caller passes it as [overrideLocale] so notification
/// strings track the UI language instead of the OS language. A null
/// override means "follow system" — same path as before.
Future<NotificationStrings> _resolveNotificationStrings({
  Locale? overrideLocale,
}) async {
  final Locale? sourceLocale =
      overrideLocale ??
      WidgetsBinding.instance.platformDispatcher.locales.firstOrNull;
  final Locale resolved = resolveSupportedLocale(
    sourceLocale,
    supportedLocales,
  );
  final AppLocalizations l = await AppLocalizations.delegate.load(resolved);
  return NotificationStrings(
    timerEndedTitle: l.notificationTimerEndedTitle,
    timerEndedBody: l.notificationTimerEndedBody,
    timerCompletedBackgroundBody: l.notificationTimerCompletedBackgroundBody,
    alarmRingingTitle: l.notificationAlarmRingingTitle,
    alarmRingingBody: l.notificationAlarmRingingBody,
    timerAlarmChannelName: l.notificationTimerAlarmChannelName,
    timerAlarmChannelDescription: l.notificationTimerAlarmChannelDescription,
    timerCompletedChannelName: l.notificationTimerCompletedChannelName,
    timerCompletedChannelDescription:
        l.notificationTimerCompletedChannelDescription,
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

  // ──────────────────────────────────────────────────────────────
  // Phase D-1: diagnostic logging bootstrap
  //
  // Build the file-backed sink *before* doing anything else so the
  // FlutterError / PlatformDispatcher uncaught-exception handlers we
  // register below have a sink to forward into. The Phase D-1
  // in-memory adapter is no longer reachable from main(); tests still
  // default to the in-memory one via diagnosticSinkProvider's default.
  //
  // Note (PR #49 review #3246516898 / #3246537710): the error handlers
  // are installed *after* the ProviderContainer is built so they can
  // route through `diagnosticLoggerProvider` and respect the
  // `diagnosticSettingsNotifier.enabled` toggle (which defaults to
  // `!kReleaseMode`). Errors during the sub-100ms boot window between
  // `WidgetsFlutterBinding.ensureInitialized()` and the container
  // construction below are still surfaced by Flutter's default
  // red-screen / stderr presentation — they just don't reach the
  // diagnostic sink, which is the intended behaviour when the user
  // has logging disabled.
  // ──────────────────────────────────────────────────────────────
  // Shared closure: Phase D-2 sink + Phase D-3 zip exporter both need
  // to point at the same on-disk directory, so resolution is hoisted
  // to a single Future-returning helper.
  Future<Directory> resolveLogDir() async {
    // p.join keeps the path separator platform-correct (PR #50 review
    // #3246519123). Phase D-2 currently targets Android only, where
    // '/' is fine — but the indirection prepares the same path-build
    // for the Phase 12 iOS port.
    final Directory base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'diagnostic_logs'));
  }

  final FileDiagnosticSinkAdapter diagnosticSink = FileDiagnosticSinkAdapter(
    rootDirProvider: resolveLogDir,
    formatter: const DiagnosticLogFormatter(),
    rotator: const DiagnosticLogRotator(clock: Clock()),
    clock: const Clock(),
  );
  // Phase D-3: zip exporter that the Settings "Share logs" action drives.
  // outputDirProvider goes to the OS temp dir — share_plus reads from
  // there and the file is opaque to the user after the share completes.
  final ZipDiagnosticLogExporterAdapter diagnosticExporter =
      ZipDiagnosticLogExporterAdapter(
        logDirProvider: resolveLogDir,
        outputDirProvider: getTemporaryDirectory,
        clock: const Clock(),
      );
  // Default-enabled in debug builds, off in release builds. The
  // notifier reads `defaultEnabled` from the field below at build()
  // time. A persisted user toggle (if any) overrides this.
  const bool diagnosticDefaultEnabled = !kReleaseMode;

  _registerBundledSoundsLicense();
  final NotificationStrings notificationStrings =
      await _resolveNotificationStrings();
  final adapter = FlutterLocalNotificationAdapter();
  final AppDatabase database = AppDatabase();
  final DriftTimerRepository repository = DriftTimerRepository(database);
  final DriftPresetRepository presetRepo = DriftPresetRepository(database);
  final DriftAlarmRepository alarmRepo = DriftAlarmRepository(database);
  final DriftClockEntryRepository clockRepo = DriftClockEntryRepository(
    database,
  );
  // Phase D-2 / PR #50 review #3246543096: forward GPS /
  // TZ-resolution failures through the diagnostic logger, so the
  // user's `enabled` toggle gates these writes. `loggerLookup` is a
  // thunk so the adapter can be constructed *before* the
  // `ProviderContainer` below — the closure only runs on a real
  // failure, by which time `container` is assigned.
  late final ProviderContainer container;
  final LocationDetectorAdapter detector = LocationDetectorAdapter(
    loggerLookup: () => container.read(diagnosticLoggerProvider),
  );
  final TzDatabaseTimezoneResolver timezoneResolver =
      TzDatabaseTimezoneResolver();
  final SharedPreferencesUserPreferences userPrefs =
      await SharedPreferencesUserPreferences.create();

  // PR #29 G3: read the last-visited tab synchronously here (we're
  // still pre-runApp and shared_preferences has resolved) so HomeScreen
  // can paint its first frame at the right tab. Reading via a
  // post-frame microtask would briefly flash the default Timer tab
  // before the jumpToPage kicked in.
  final int? storedHomePageIndex = await userPrefs.getInt(
    UserPreferenceKeys.lastHomePageIndex,
  );
  final int initialHomePageIndex =
      (storedHomePageIndex ?? HomeScreen.defaultPageIndex).clamp(
        0,
        HomeScreen.pageCount - 1,
      );

  // `late final` lets the warm-launch tap callback reference the router
  // that's only constructed after we know the cold-launch payload below.
  late final GoRouter router;
  await adapter.initialize(
    strings: notificationStrings,
    onNotificationTap: (String? payload) {
      // Warm-launch path (app already running): navigate to the alarm
      // screen. payload は ADR 0005 で定めた `timer:<id>` / `alarm:<id>`
      // の形式で渡される。AlarmRingingScreen は queryParameters['payload']
      // を読んで起動元を判別する。
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
      // payload を queryParameter に載せて screen に渡す。
      // push (not go) で前の画面はスタックに残し、`_leaveAlarmScreen` の
      // pop で home に戻れるようにする。
      router.push(
        Uri(
          path: '/alarm-ringing',
          queryParameters: <String, String>{'payload': payload},
        ).toString(),
      );
    },
  );

  // Cold-launch path: プロセスが死んでいた状態で通知をタップされた場合は
  // `onNotificationTap` が発火しないので、プラグインに直接問い合わせて
  // 初期ロケーションを `/alarm-ringing?payload=...` に切り替える。
  //
  // Issue #74 fix (2026-05-28、案 A 補正): cold/warm-launch 判定では
  // 不十分 (warm-launch FSI snooze 再鳴動も Lock 画面状態なら二重音発生)
  // → `AlarmRingingNotifier.start` 内部で
  // `KeyguardManager.isKeyguardLocked()` を Native から読んで delay 分岐
  // する設計に変更。main.dart は経路情報を伝達しない (cold=1 クエリ廃止)。
  final String? coldLaunchPayload = await adapter.coldLaunchPayload();
  final String initialLocation = coldLaunchPayload != null
      ? Uri(
          path: '/alarm-ringing',
          queryParameters: <String, String>{'payload': coldLaunchPayload},
        ).toString()
      : '/';

  router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            HomeScreen(initialPageIndex: initialHomePageIndex),
      ),
      GoRoute(
        path: StopwatchScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const StopwatchScreen(),
      ),
      GoRoute(
        path: TimerListScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const TimerListScreen(),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (BuildContext context, GoRouterState state) =>
            AlarmRingingScreen(payload: state.uri.queryParameters['payload']),
      ),
      GoRoute(
        path: '/presets',
        builder: (BuildContext context, GoRouterState state) =>
            const PresetManageScreen(),
      ),
      // Phase 9.5: 指定時刻アラーム機能。`/alarms` 一覧、
      // `/alarms/edit` 新規作成、`/alarms/edit/:id` 編集。
      // `:id` は optional なため別ルートとして登録 (go_router の path
      // パラメータは optional 不可)。
      GoRoute(
        path: AlarmListScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmListScreen(),
      ),
      GoRoute(
        path: '/alarms/edit',
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmEditScreen(),
      ),
      GoRoute(
        path: '/alarms/edit/:id',
        builder: (BuildContext context, GoRouterState state) =>
            AlarmEditScreen(alarmId: state.pathParameters['id']),
      ),
      GoRoute(
        path: ClockScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const ClockScreen(),
      ),
      GoRoute(
        path: ClockEntryEditScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const ClockEntryEditScreen(),
      ),
      GoRoute(
        path: LicensesScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const LicensesScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
    ],
  );

  // Build the container ourselves rather than relying on ProviderScope
  // so the FlutterError / PlatformDispatcher handlers below can route
  // through `diagnosticLoggerProvider` and pick up the user's
  // `diagnosticSettingsNotifier.enabled` toggle (PR #49 review
  // #3246516898 / #3246537710). UncontrolledProviderScope wraps this
  // same container for the widget tree so reads from both sides see
  // identical state.
  container = ProviderContainer(
    overrides: <Override>[
      notificationSchedulerProvider.overrideWithValue(adapter),
      notificationStringsNotifierProvider.overrideWith(
        () => _BootstrappedNotificationStringsNotifier(notificationStrings),
      ),
      timerRepositoryProvider.overrideWithValue(repository),
      presetRepositoryProvider.overrideWithValue(presetRepo),
      alarmRepositoryProvider.overrideWithValue(alarmRepo),
      clockEntryRepositoryProvider.overrideWithValue(clockRepo),
      locationDetectorProvider.overrideWithValue(detector),
      timezoneResolverProvider.overrideWithValue(timezoneResolver),
      userPreferencesProvider.overrideWithValue(userPrefs),
      diagnosticSinkProvider.overrideWithValue(diagnosticSink),
      diagnosticLogExporterProvider.overrideWithValue(diagnosticExporter),
      diagnosticSettingsNotifierProvider.overrideWith(
        () =>
            DiagnosticSettingsNotifier()
              ..defaultEnabled = diagnosticDefaultEnabled,
      ),
    ],
  );

  // Funnel both the Flutter framework's caught errors (build / layout /
  // render) and asynchronous PlatformDispatcher errors through the
  // diagnostic logger. Going via `diagnosticLoggerProvider` (rather
  // than writing to the sink directly) means the
  // `diagnosticSettingsNotifier.enabled` toggle gates these too, so
  // the release default (`!kReleaseMode == false`) no longer leaks
  // uncaught-exception records onto disk against the user's choice.
  // We keep Flutter's default presentation (red screen / console dump)
  // by delegating to `FlutterError.presentError` after recording.
  final void Function(FlutterErrorDetails)? previousOnError =
      FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    container
        .read(diagnosticLoggerProvider)
        .log(
          DiagnosticEvent.uncaughtException(
            occurredAt: clock.now(),
            exceptionType: details.exception.runtimeType.toString(),
            stackTraceDigest: DiagnosticEvent.digestStackTrace(details.stack),
          ),
        );
    if (previousOnError != null) {
      previousOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    container
        .read(diagnosticLoggerProvider)
        .log(
          DiagnosticEvent.uncaughtException(
            occurredAt: clock.now(),
            exceptionType: error.runtimeType.toString(),
            stackTraceDigest: DiagnosticEvent.digestStackTrace(stack),
          ),
        );
    // Returning `false` lets the engine continue its default handling
    // (logging to stderr in debug, crashing in release). We only want
    // to *observe*, not swallow.
    return false;
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TimerUtilityApp(router: router, diagnosticSink: diagnosticSink),
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
  const TimerUtilityApp({
    super.key,
    required this.router,
    required this.diagnosticSink,
  });

  final GoRouter router;

  /// Reference to the same sink we override the Provider with in
  /// `main()`. Held here (rather than read back from the Provider) so
  /// the lifecycle hook can call `flush()` even while the Provider
  /// container is being torn down on `detached`.
  final DiagnosticSink diagnosticSink;

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      // Phase D-2 will swap the in-memory sink for the file adapter
      // whose flush() drains the IOSink to disk. The Phase D-1
      // in-memory adapter no-ops, so this is harmless until then.
      //
      // PR #49 review #3246537686: flush() can throw under the file
      // sink (disk full / permissions). Catch here so a lifecycle
      // transition cannot crash the app — losing the unflushed bytes
      // is acceptable, taking the app down is not.
      unawaited(
        widget.diagnosticSink.flush().catchError((Object _) {
          // Best-effort flush. The Phase D-2 file adapter swallows
          // I/O failures internally too; this is belt-and-braces for
          // future sinks that may not.
        }),
      );
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    // Fire-and-forget: re-resolve against the new device locale, push
    // the fresh strings into the provider, and re-schedule running
    // timers so their pending OS banners switch language too. When the
    // user has a manual override active, OS changes don't matter — the
    // override wins and we keep notification strings on that locale.
    unawaited(_refreshNotificationLocale());
  }

  Future<void> _refreshNotificationLocale() async {
    final Locale? override = ref.read(settingsNotifierProvider).localeOverride;
    final NotificationStrings strings = await _resolveNotificationStrings(
      overrideLocale: override,
    );
    if (!mounted) return;
    ref.read(notificationStringsNotifierProvider.notifier).set(strings);
    // Re-push the OS notification channel labels so Settings → Apps →
    // TimerUtility → Notifications follows the new language. The
    // channel id is unchanged so this only updates name/description;
    // importance / sound / vibration stay locked at their original
    // values (the OS protects user-overridable settings).
    unawaited(
      ref.read(notificationSchedulerProvider).updateChannelNames(strings),
    );
    ref.read(timerCollectionNotifierProvider.notifier).rescheduleAllRunning();
  }

  @override
  Widget build(BuildContext context) {
    // Watch both theme and locale override. Pass `locale` through to
    // MaterialApp — when null, `localeResolutionCallback` continues to
    // run against the device locale (F-9 behaviour preserved); when set,
    // MaterialApp uses the override but still routes it through the
    // callback so unsupported tags fall back to en the same way.
    final ThemeMode themeMode = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.themeMode),
    );
    final Locale? localeOverride = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.localeOverride),
    );
    // Refresh pending notification banners whenever the user flips the
    // manual override. The OS-locale path is handled by didChangeLocales;
    // this listener covers the in-app toggle that doesn't trigger an OS
    // event.
    ref.listen<SettingsState>(settingsNotifierProvider, (prev, next) {
      if (prev?.localeOverride != next.localeOverride) {
        unawaited(_refreshNotificationLocale());
      }
    });
    return MaterialApp.router(
      title: 'TimerUtility',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      locale: localeOverride,
      routerConfig: widget.router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      localeResolutionCallback:
          (Locale? deviceLocale, Iterable<Locale> supported) =>
              resolveSupportedLocale(deviceLocale, supported.toList()),
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
    );
  }
}
