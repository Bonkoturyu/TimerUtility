import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/notification_scheduler.dart';
import '../infrastructure/notification/flutter_local_notification_adapter.dart';

part 'notification_scheduler_provider.g.dart';

/// Default-bound notification scheduler. Override in tests via
/// `notificationSchedulerProvider.overrideWithValue(fakeScheduler)`.
///
/// `main()` is responsible for awaiting `initialize()` on the adapter
/// before reading this provider for actual scheduling.
@Riverpod(keepAlive: true)
NotificationScheduler notificationScheduler(Ref ref) =>
    FlutterLocalNotificationAdapter();
