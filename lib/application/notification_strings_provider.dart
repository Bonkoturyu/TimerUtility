import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_strings_provider.g.dart';

/// Pre-resolved localized strings used by code paths that emit OS
/// notifications (`TimerCollectionNotifier._scheduleNotification`,
/// `_showRestoredCompletionNotification`).
///
/// Why a separate value object: notifier code lives in the application
/// layer and has no `BuildContext`, so it can't call
/// `AppLocalizations.of(context)`. Resolving the strings against
/// `AppLocalizations` and stashing them in a Riverpod-managed notifier
/// gives the application layer a clean read-side without coupling it to
/// presentation-layer types.
class NotificationStrings {
  const NotificationStrings({
    required this.timerEndedTitle,
    required this.timerEndedBody,
    required this.timerCompletedBackgroundBody,
    required this.alarmRingingTitle,
    required this.alarmRingingBody,
  });

  /// Fallback title used when the timer has no user-provided label.
  /// E.g. "タイマー" / "Timer".
  final String timerEndedTitle;

  /// Body of the alarm-fire notification. E.g. "時間になりました。" /
  /// "Time is up.".
  final String timerEndedBody;

  /// Body of the silent "missed timer while in the background"
  /// notification fired by the restoration path on app start.
  final String timerCompletedBackgroundBody;

  /// Phase 9.5 のスケジュール時刻アラーム発火通知のタイトル
  /// (アラームに `label` が設定されていないときのフォールバック)。
  /// 例: "アラーム" / "Alarm"。
  final String alarmRingingTitle;

  /// Phase 9.5 のスケジュール時刻アラーム発火通知の本文。
  /// 例: "アラームの時刻になりました。" / "Time to wake up."。
  final String alarmRingingBody;
}

/// Holds the locale-resolved strings used by the OS-notification code
/// paths. `TimerUtilityApp`'s `WidgetsBindingObserver.didChangeLocales`
/// pushes a freshly resolved value via [set] whenever the device locale
/// changes, so notifications scheduled after a language switch use the
/// new translation instead of the one captured at startup.
///
/// Throw-on-default pattern: callers must override this provider in
/// `main.dart` with a value resolved against `AppLocalizations`.
/// Hitting this default in a test means the test harness forgot to
/// supply an override, and the assertion message tells the next
/// reader where to plug it in.
@Riverpod(keepAlive: true)
class NotificationStringsNotifier extends _$NotificationStringsNotifier {
  @override
  NotificationStrings build() => throw UnimplementedError(
    'notificationStringsNotifierProvider must be overridden in main.dart '
    '(and in tests via ProviderScope.overrides) with locale-resolved strings.',
  );

  /// Replace the held strings — typically called by the app-level
  /// locale observer after `AppLocalizations.delegate.load(newLocale)`.
  void set(NotificationStrings strings) => state = strings;
}
