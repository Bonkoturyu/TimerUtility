import 'package:flutter/services.dart';

/// MethodChannel bridge for Android exact-alarm scheduling and playback.
class NativeAlarmChannel {
  NativeAlarmChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName =
      'io.github.bonkoturyu.timer_utility/native_alarm';

  final MethodChannel _channel;

  void initialize({required void Function(String? payload) onAlarmTap}) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'alarmTapped') {
        onAlarmTap(call.arguments as String?);
      }
    });
  }

  Future<void> schedule({
    required int notificationId,
    required DateTime fireAt,
    required String title,
    required String body,
    required String payload,
    required String soundId,
    String? soundPath,
  }) => _channel.invokeMethod<void>('schedule', <String, Object?>{
    'notificationId': notificationId,
    'fireAtUtcMs': fireAt.toUtc().millisecondsSinceEpoch,
    'title': title,
    'body': body,
    'payload': payload,
    'soundId': soundId,
    'soundPath': soundPath,
  });

  Future<void> cancel(int notificationId) => _channel.invokeMethod<void>(
    'cancel',
    <String, Object>{'notificationId': notificationId},
  );

  Future<void> cancelAll() => _channel.invokeMethod<void>('cancelAll');

  Future<void> setAlarmVolumePercent(int percent) =>
      _channel.invokeMethod<void>('setAlarmVolumePercent', <String, Object>{
        'percent': percent,
      });

  Future<bool> ensurePlayback(int notificationId) async =>
      await _channel.invokeMethod<bool>('ensurePlayback', <String, Object>{
        'notificationId': notificationId,
      }) ??
      false;

  Future<void> stopPlayback() => _channel.invokeMethod<void>('stopPlayback');

  Future<String?> takeLaunchPayload() =>
      _channel.invokeMethod<String>('takeLaunchPayload');

  Future<String?> activePayload() =>
      _channel.invokeMethod<String>('activePayload');
}
