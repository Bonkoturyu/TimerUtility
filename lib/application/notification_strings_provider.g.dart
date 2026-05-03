// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_strings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationStringsNotifierHash() =>
    r'95c245522834383d1491c474d0ead794195b5822';

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
///
/// Copied from [NotificationStringsNotifier].
@ProviderFor(NotificationStringsNotifier)
final notificationStringsNotifierProvider =
    NotifierProvider<NotificationStringsNotifier, NotificationStrings>.internal(
      NotificationStringsNotifier.new,
      name: r'notificationStringsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationStringsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationStringsNotifier = Notifier<NotificationStrings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
