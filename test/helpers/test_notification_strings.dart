import 'package:timer_utility/application/notification_strings_provider.dart';

/// Stub strings for tests that don't care about the localized content
/// of timer-end notifications, only that something gets passed through.
/// Keeps the harness explicit about override-required providers.
const NotificationStrings testNotificationStrings = NotificationStrings(
  timerEndedTitle: 'Timer',
  timerEndedBody: 'Time is up.',
  timerCompletedBackgroundBody:
      'Timer ended while the app was in the background.',
);
