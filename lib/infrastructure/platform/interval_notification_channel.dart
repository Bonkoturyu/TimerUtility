import 'package:flutter/services.dart';

import '../../domain/ports/interval_notification_scheduler.dart';

/// MethodChannel adapter for Android's self-rescheduling interval alarm.
class IntervalNotificationChannel implements IntervalNotificationScheduler {
  IntervalNotificationChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName =
      'io.github.bonkoturyu.timer_utility/interval_notification';

  final MethodChannel _channel;

  @override
  Future<void> schedule({
    required int notificationId,
    required DateTime firstFireAt,
    required Duration interval,
    required String title,
    required String body,
    required bool exact,
    required String payload,
  }) async {
    await _channel.invokeMethod<void>('schedule', <String, Object>{
      'notificationId': notificationId,
      'firstFireAtUtcMs': firstFireAt.toUtc().millisecondsSinceEpoch,
      'intervalMs': interval.inMilliseconds,
      'title': title,
      'body': body,
      'exact': exact,
      'payload': payload,
    });
  }

  @override
  Future<void> cancel(int notificationId) async {
    await _channel.invokeMethod<void>('cancel', <String, Object>{
      'notificationId': notificationId,
    });
  }
}
