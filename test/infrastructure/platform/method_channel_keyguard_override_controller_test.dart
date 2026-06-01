import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/platform/method_channel_keyguard_override_controller.dart';
import 'package:timer_utility/infrastructure/platform/permission_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelKeyguardOverrideController', () {
    const MethodChannel channel = MethodChannel(PermissionChannel.channelName);

    late List<MethodCall> calls;
    Future<Object?> Function(MethodCall) handler = (_) async => null;

    setUp(() {
      calls = <MethodCall>[];
      handler = (_) async => null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return handler(call);
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'clearShowWhenLocked invokes the native clearShowWhenLocked method',
      () async {
        await MethodChannelKeyguardOverrideController().clearShowWhenLocked();

        expect(calls.single.method, 'clearShowWhenLocked');
      },
    );

    test(
      'clearShowWhenLocked swallows PlatformException (best-effort)',
      () async {
        // Clearing the override only affects the recents (■) button
        // visibility, never the alarm — a native failure must not surface
        // on the leave-alarm-screen path.
        handler = (_) async => throw PlatformException(code: 'ERR');

        await expectLater(
          MethodChannelKeyguardOverrideController().clearShowWhenLocked(),
          completes,
        );
      },
    );

    test(
      'clearShowWhenLocked swallows MissingPluginException (test env)',
      () async {
        // No handler registered (Native absent in test env) → the channel
        // throws MissingPluginException. The adapter must absorb it so the
        // caller's fire-and-forget `unawaited(...)` never becomes an
        // unhandled rejection.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);

        await expectLater(
          MethodChannelKeyguardOverrideController().clearShowWhenLocked(),
          completes,
        );
      },
    );
  });
}
