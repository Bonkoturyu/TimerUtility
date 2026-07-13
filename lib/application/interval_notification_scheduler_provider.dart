import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/interval_notification_scheduler.dart';

part 'interval_notification_scheduler_provider.g.dart';

@Riverpod(keepAlive: true)
IntervalNotificationScheduler intervalNotificationScheduler(Ref ref) =>
    const _NoopIntervalNotificationScheduler();

class _NoopIntervalNotificationScheduler
    implements IntervalNotificationScheduler {
  const _NoopIntervalNotificationScheduler();

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> schedule({
    required int notificationId,
    required DateTime firstFireAt,
    required Duration interval,
    required String title,
    required String body,
    required bool exact,
  }) async {}
}
