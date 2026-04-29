// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationSchedulerHash() =>
    r'ebdf741a2855b2ec915d68f391f4bb978508ea0a';

/// Default-bound notification scheduler. Override in tests via
/// `notificationSchedulerProvider.overrideWithValue(fakeScheduler)`.
///
/// `main()` is responsible for awaiting `initialize()` on the adapter
/// before reading this provider for actual scheduling.
///
/// Copied from [notificationScheduler].
@ProviderFor(notificationScheduler)
final notificationSchedulerProvider = Provider<NotificationScheduler>.internal(
  notificationScheduler,
  name: r'notificationSchedulerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationSchedulerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationSchedulerRef = ProviderRef<NotificationScheduler>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
