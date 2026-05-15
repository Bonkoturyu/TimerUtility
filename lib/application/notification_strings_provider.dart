import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/notifications/notification_strings.dart';

export '../domain/notifications/notification_strings.dart'
    show NotificationStrings;

part 'notification_strings_provider.g.dart';

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
