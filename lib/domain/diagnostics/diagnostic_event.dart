import '../ports/permission_manager.dart';

/// Severity level for diagnostic events.
///
/// Ordering matters: callers compare `event.severity.index` against a
/// `threshold` to filter out events below the configured level.
enum DiagnosticSeverity { debug, info, warning, error }

/// Which OS permission a permission-transition event refers to. Mirrors
/// the three permissions tracked in [PermissionState]; we keep a
/// dedicated enum here (rather than reusing a string) so an unknown
/// kind is a compile error at every call site.
enum PermissionKind { postNotifications, scheduleExactAlarm, fullScreenIntent }

/// The path that triggered an OS notification we surfaced. The four
/// values match the four code paths in the Application layer that hit
/// [NotificationScheduler]: foreground timer fire, alarm fire, post-kill
/// restored-completion banner (timer), and missed-alarm reconcile.
enum NotificationFireKind {
  timerFired,
  alarmFired,
  restoredCompletion,
  missedAlarmReconcile,
}

/// Discrete user/system actions on timers, stopwatches and alarms.
///
/// Kept as a single enum (rather than split per Notifier) because the
/// log consumer doesn't care which Notifier produced the event — they
/// only care what happened to which id.
enum TimerActionKind {
  // Timer / Stopwatch shared
  start,
  pause,
  resume,
  reset,
  // Timer only
  create,
  cancel,
  snooze,
  delete,
  changeSound,
  // Stopwatch only
  lap,
  // Alarm
  alarmCreate,
  alarmUpdate,
  alarmToggle,
  alarmDelete,
  alarmFiredStop,
  alarmFiredSnooze,
  // Diagnostics-only breadcrumb (Issue #86): records the instant audioplayers
  // playback is *requested* — the clock reading taken immediately before the
  // `player.play()` call in `AlarmRingingNotifier.start`, after the
  // cancel→delay sequence and the pre-play guard. This is the play-request
  // time, NOT the audible onset: the actual sound lags by the audioplayers /
  // OS playout latency. Lets the double-tone investigation correlate the play
  // request against the OS alarm-stream tone release observed via `dumpsys`,
  // since the existing `notificationFired` breadcrumb only marks the start of
  // the sequence (≈ cancel time), not the play request.
  alarmPlaybackStart,
}

/// Top of the diagnostic event hierarchy. Pure Dart sealed class so
/// `switch (event) { case DiagnosticUncaughtException(): ... }` is
/// exhaustive — adding a fifth variant is a compile error at every
/// consumer.
///
/// Design constraint (PII):
///   Factories never accept timer labels or location coordinates. Only
///   UUIDs / enum values / [Duration]s / [DomainPermissionStatus]
///   values are recorded. This is enforced at the type-level: there is
///   no constructor parameter that would let a label leak in.
sealed class DiagnosticEvent {
  const DiagnosticEvent({required this.occurredAt});

  // Factory redirects so call sites read like a tagged union
  // (`DiagnosticEvent.uncaughtException(...)`). The plan uses this
  // surface; the concrete subclasses can still be constructed directly
  // for tests / pattern-matching.
  const factory DiagnosticEvent.uncaughtException({
    required DateTime occurredAt,
    required String exceptionType,
    required String stackTraceDigest,
  }) = DiagnosticUncaughtException;

  const factory DiagnosticEvent.permissionTransition({
    required DateTime occurredAt,
    required PermissionKind permissionKind,
    required DomainPermissionStatus before,
    required DomainPermissionStatus after,
  }) = DiagnosticPermissionTransition;

  const factory DiagnosticEvent.notificationFired({
    required DateTime occurredAt,
    required String payloadId,
    required NotificationFireKind fireKind,
  }) = DiagnosticNotificationFired;

  const factory DiagnosticEvent.timerAction({
    required DateTime occurredAt,
    required String timerId,
    required TimerActionKind action,
  }) = DiagnosticTimerAction;

  /// When the event was observed. Callers must pass `clock.now()` from
  /// the Application layer — domain code never reads `DateTime.now()`
  /// directly.
  final DateTime occurredAt;

  /// Severity is fixed per variant, not stored — makes copy-paste
  /// mistakes impossible.
  DiagnosticSeverity get severity;

  /// Stable kind string used in the JSON-Lines serializer
  /// (`{"kind":"uncaughtException", ...}`). Hand-rolled so renaming a
  /// Dart class does not silently rewrite the on-disk format.
  String get kind;

  /// Variant-specific payload fields. The formatter merges these into
  /// the envelope (`t` / `sev` / `kind`) on serialization. Returning a
  /// `Map<String, Object?>` avoids `toJson` callbacks per variant.
  Map<String, Object?> toJsonPayload();

  /// PII-safe stack-trace digest: the first 3 non-empty frames joined
  /// with `\n`. Keeps the on-disk payload small and avoids leaking
  /// long internal frame strings that occasionally embed file paths.
  ///
  /// Centralised in the domain layer (PR #50 review #3246519127) so
  /// the Application-side `FlutterError.onError` / `PlatformDispatcher`
  /// handlers and the Infrastructure-side [LocationDetectorAdapter]
  /// share a single contract; if the cap or PII rules need to tighten,
  /// they tighten in one place.
  static String digestStackTrace(StackTrace? trace) {
    if (trace == null) return '';
    final List<String> lines = trace.toString().split('\n');
    final List<String> top = lines
        .where((String l) => l.trim().isNotEmpty)
        .take(3)
        .toList();
    return top.join('\n');
  }
}

final class DiagnosticUncaughtException extends DiagnosticEvent {
  const DiagnosticUncaughtException({
    required super.occurredAt,
    required this.exceptionType,
    required this.stackTraceDigest,
  });

  /// Runtime type name only (e.g. `FormatException`). Free-form
  /// exception messages are intentionally NOT captured — they routinely
  /// embed user-supplied strings (file paths, labels).
  final String exceptionType;

  /// A short digest of the stack trace. Typically the first 2-3 frames
  /// joined with `\n`. The Application-side handler is responsible for
  /// trimming; the domain layer just stores what it is given.
  final String stackTraceDigest;

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.error;

  @override
  String get kind => 'uncaughtException';

  @override
  Map<String, Object?> toJsonPayload() => <String, Object?>{
    'exceptionType': exceptionType,
    'stackTraceDigest': stackTraceDigest,
  };

  @override
  bool operator ==(Object other) =>
      other is DiagnosticUncaughtException &&
      other.occurredAt == occurredAt &&
      other.exceptionType == exceptionType &&
      other.stackTraceDigest == stackTraceDigest;

  @override
  int get hashCode => Object.hash(occurredAt, exceptionType, stackTraceDigest);

  @override
  String toString() =>
      'DiagnosticUncaughtException($occurredAt, $exceptionType, '
      '$stackTraceDigest)';
}

final class DiagnosticPermissionTransition extends DiagnosticEvent {
  const DiagnosticPermissionTransition({
    required super.occurredAt,
    required this.permissionKind,
    required this.before,
    required this.after,
  });

  /// Renamed from `kind` so it doesn't collide with the inherited
  /// [DiagnosticEvent.kind] (the JSON kind discriminator).
  /// `permissionKind` is used consistently for both the field name and
  /// the factory parameter (`DiagnosticEvent.permissionTransition` /
  /// `DiagnosticPermissionTransition`) — Dart's factory-redirect rule
  /// requires the name to match between the sealed parent's factory
  /// and the concrete subclass constructor.
  final PermissionKind permissionKind;
  final DomainPermissionStatus before;
  final DomainPermissionStatus after;

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.info;

  @override
  String get kind => 'permissionTransition';

  @override
  Map<String, Object?> toJsonPayload() => <String, Object?>{
    'permissionKind': permissionKind.name,
    'before': before.name,
    'after': after.name,
  };

  @override
  bool operator ==(Object other) =>
      other is DiagnosticPermissionTransition &&
      other.occurredAt == occurredAt &&
      other.permissionKind == permissionKind &&
      other.before == before &&
      other.after == after;

  @override
  int get hashCode => Object.hash(occurredAt, permissionKind, before, after);

  @override
  String toString() =>
      'DiagnosticPermissionTransition($occurredAt, ${permissionKind.name}, '
      '${before.name}→${after.name})';
}

final class DiagnosticNotificationFired extends DiagnosticEvent {
  const DiagnosticNotificationFired({
    required super.occurredAt,
    required this.payloadId,
    required this.fireKind,
  });

  /// Opaque id from the notification payload (timer id or alarm id —
  /// UUID v4). Never includes a label.
  final String payloadId;
  final NotificationFireKind fireKind;

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.info;

  @override
  String get kind => 'notificationFired';

  @override
  Map<String, Object?> toJsonPayload() => <String, Object?>{
    'payloadId': payloadId,
    'fireKind': fireKind.name,
  };

  @override
  bool operator ==(Object other) =>
      other is DiagnosticNotificationFired &&
      other.occurredAt == occurredAt &&
      other.payloadId == payloadId &&
      other.fireKind == fireKind;

  @override
  int get hashCode => Object.hash(occurredAt, payloadId, fireKind);

  @override
  String toString() =>
      'DiagnosticNotificationFired($occurredAt, $payloadId, ${fireKind.name})';
}

final class DiagnosticTimerAction extends DiagnosticEvent {
  const DiagnosticTimerAction({
    required super.occurredAt,
    required this.timerId,
    required this.action,
  });

  /// Domain id (UUID v4 for timers/alarms; the literal string
  /// `'stopwatch'` for the singleton stopwatch). Never a user-facing
  /// label.
  final String timerId;
  final TimerActionKind action;

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.debug;

  @override
  String get kind => 'timerAction';

  @override
  Map<String, Object?> toJsonPayload() => <String, Object?>{
    'timerId': timerId,
    'action': action.name,
  };

  @override
  bool operator ==(Object other) =>
      other is DiagnosticTimerAction &&
      other.occurredAt == occurredAt &&
      other.timerId == timerId &&
      other.action == action;

  @override
  int get hashCode => Object.hash(occurredAt, timerId, action);

  @override
  String toString() =>
      'DiagnosticTimerAction($occurredAt, $timerId, ${action.name})';
}
