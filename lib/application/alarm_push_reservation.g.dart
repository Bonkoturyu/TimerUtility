// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_push_reservation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alarmPushReservationHash() =>
    r'f8864ee5b65f168def0812ba7b2b506e05bfc6d7';

/// App-global single-slot reservation that dedupes concurrent attempts to
/// push the `/alarm-ringing` screen.
///
/// Two paths can fire in the same frame when a timer rings while the app is
/// backgrounded:
///   1. The OS notification tap (`main.dart#onNotificationTap`).
///   2. The `TimerCollection` ringing listener in `HomeScreen` flipping to
///      `ringing` on app resume.
/// Each path's "is the alarm screen already on top?" check can race past the
/// other before the route stack settles, leaving two `/alarm-ringing` frames
/// stacked. Both callers commit synchronously via [tryReserve]; the loser
/// bails before adding a second frame. The owner releases the slot in
/// `AlarmRingingScreen.dispose` so a future ring can push again.
///
/// Review #5: previously a static mutable field on `AlarmRingingScreen`.
/// Moving it to a `keepAlive` provider keeps the same app-global semantics in
/// production (a single instance in the shared `ProviderContainer`, which
/// `main.dart` and the widget tree both read via `UncontrolledProviderScope`)
/// while letting tests isolate it per `ProviderContainer` — no static reset
/// seam to remember in `tearDown`.
///
/// Copied from [AlarmPushReservation].
@ProviderFor(AlarmPushReservation)
final alarmPushReservationProvider =
    NotifierProvider<AlarmPushReservation, bool>.internal(
      AlarmPushReservation.new,
      name: r'alarmPushReservationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alarmPushReservationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AlarmPushReservation = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
