/// Locale-resolved strings used by code paths that emit OS notifications.
///
/// Lives in `domain/notifications/` so both the application layer (which
/// holds a Riverpod notifier of this value) and the infrastructure layer
/// (which feeds the channel name/description into
/// `flutter_local_notifications`) can import it without violating the
/// `application → domain ← infrastructure` rule.
///
/// Application layer reasons it was extracted as a value object:
/// notifier code lives in the application layer and has no
/// `BuildContext`, so it can't call `AppLocalizations.of(context)`.
/// Resolving the strings against `AppLocalizations` and stashing them
/// in a Riverpod-managed notifier gives the application layer a clean
/// read-side without coupling it to presentation-layer types.
///
/// Infrastructure layer reasons it lives in domain: the notification
/// channel name/description shown in OS Settings is locale-aware
/// (Phase 11 A-2), so the adapter needs to be re-pushed when the user
/// switches language. Passing this value object through
/// [NotificationScheduler.updateChannelNames] keeps the adapter
/// signature stable as we add or rename channel-meta fields.
class NotificationStrings {
  const NotificationStrings({
    required this.timerEndedTitle,
    required this.timerEndedBody,
    required this.timerCompletedBackgroundBody,
    required this.alarmRingingTitle,
    required this.alarmRingingBody,
    required this.timerAlarmChannelName,
    required this.timerAlarmChannelDescription,
    required this.timerCompletedChannelName,
    required this.timerCompletedChannelDescription,
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

  /// OS-visible name of the alarm notification channel
  /// (`timer_alarm_v6`). Shown in Settings → Apps → TimerUtility →
  /// Notifications. Re-pushed to the OS when the locale changes so the
  /// system UI stays in sync with the app language.
  final String timerAlarmChannelName;

  /// Description shown under [timerAlarmChannelName] in the OS channel
  /// list.
  final String timerAlarmChannelDescription;

  /// OS-visible name of the silent background-completion channel
  /// (`timer_completed_v1`). Surfaces the "you missed a timer while
  /// away" notification.
  final String timerCompletedChannelName;

  /// Description shown under [timerCompletedChannelName].
  final String timerCompletedChannelDescription;
}
