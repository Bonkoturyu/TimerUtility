import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_push_reservation.g.dart';

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
@Riverpod(keepAlive: true)
class AlarmPushReservation extends _$AlarmPushReservation {
  @override
  bool build() => false;

  /// Atomic check-and-set: returns `false` if a push is already reserved
  /// (pending or currently mounted), `true` if this caller now owns the
  /// slot. The owner must follow up with a `push('/alarm-ringing')` and
  /// [release] the slot when the screen is dismissed.
  bool tryReserve() {
    if (state) return false;
    state = true;
    return true;
  }

  /// Releases the reservation so a future ring can push again. Called from
  /// `AlarmRingingScreen.dispose`.
  void release() => state = false;
}
