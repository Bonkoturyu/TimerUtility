import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/platform/permission_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionChannel', () {
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

    test('canUseFullScreenIntent returns true when native says true', () async {
      handler = (_) async => true;

      final result = await PermissionChannel().canUseFullScreenIntent();

      expect(result, isTrue);
      expect(calls.single.method, 'canUseFullScreenIntent');
    });

    test(
      'canUseFullScreenIntent returns false when native says false',
      () async {
        handler = (_) async => false;

        final result = await PermissionChannel().canUseFullScreenIntent();

        expect(result, isFalse);
      },
    );

    test(
      'canUseFullScreenIntent returns false when native returns null',
      () async {
        handler = (_) async => null;

        final result = await PermissionChannel().canUseFullScreenIntent();

        expect(result, isFalse);
      },
    );

    test('openFullScreenIntentSettings invokes the channel', () async {
      handler = (_) async => null;

      await PermissionChannel().openFullScreenIntentSettings();

      expect(calls.single.method, 'openFullScreenIntentSettings');
    });
  });
}
