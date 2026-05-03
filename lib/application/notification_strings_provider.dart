import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_strings_provider.g.dart';

/// Pre-resolved localized strings used by code paths that emit OS
/// notifications (`TimerCollectionNotifier._scheduleNotification`,
/// `_showRestoredCompletionNotification`).
///
/// Why a separate value object: notifier code lives in the application
/// layer and has no `BuildContext`, so it can't call
/// `AppLocalizations.of(context)`. Resolving the strings once at startup
/// (in `main.dart` against the device locale) and stashing them in this
/// provider gives the notifier a clean read-side without coupling it to
/// presentation-layer types.
///
/// Phase 11 (settings screen + runtime locale switch) will likely turn
/// this into a streaming provider that re-resolves whenever the user's
/// chosen locale changes. For now strings are locked to the locale
/// active at app startup.
class NotificationStrings {
  const NotificationStrings({
    required this.timerEndedTitle,
    required this.timerEndedBody,
    required this.timerCompletedBackgroundBody,
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
}

/// Throw-on-default pattern: callers must override this provider in
/// `main.dart` with a value resolved against `AppLocalizations`.
/// Hitting this default in a test means the test harness forgot to
/// supply an override, and the assertion message tells the next
/// reader where to plug it in.
@Riverpod(keepAlive: true)
NotificationStrings notificationStrings(Ref ref) => throw UnimplementedError(
  'notificationStringsProvider must be overridden in main.dart (and in '
  'tests via ProviderScope.overrides) with locale-resolved strings.',
);
