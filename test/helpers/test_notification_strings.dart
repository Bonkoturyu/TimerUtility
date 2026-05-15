import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_utility/application/notification_strings_provider.dart';

/// Stub strings for tests that don't care about the localized content
/// of timer-end notifications, only that something gets passed through.
/// Keeps the harness explicit about override-required providers.
const NotificationStrings testNotificationStrings = NotificationStrings(
  timerEndedTitle: 'Timer',
  timerEndedBody: 'Time is up.',
  timerCompletedBackgroundBody:
      'Timer ended while the app was in the background.',
  alarmRingingTitle: 'Alarm',
  alarmRingingBody: 'Alarm ringing.',
  timerAlarmChannelName: 'Timer Alarm',
  timerAlarmChannelDescription: 'Alarm notification when a timer ends',
  timerCompletedChannelName: 'Timer Completed (Background)',
  timerCompletedChannelDescription:
      'Silent notification when a timer ended while the app was in the background',
);

/// Notifier override target — `notificationStringsNotifierProvider` was
/// converted from a value provider to a class notifier (so the app can
/// react to locale changes); tests must therefore supply the initial
/// state via `overrideWith` instead of `overrideWithValue`.
class _TestNotificationStringsNotifier extends NotificationStringsNotifier {
  _TestNotificationStringsNotifier(this._value);
  final NotificationStrings _value;

  @override
  NotificationStrings build() => _value;
}

/// Convenience factory for the override every test harness needs.
Override testNotificationStringsOverride([
  NotificationStrings value = testNotificationStrings,
]) => notificationStringsNotifierProvider.overrideWith(
  () => _TestNotificationStringsNotifier(value),
);
