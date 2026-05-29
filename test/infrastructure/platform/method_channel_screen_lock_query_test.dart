import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/platform/method_channel_screen_lock_query.dart';
import 'package:timer_utility/infrastructure/platform/permission_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelScreenLockQuery', () {
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

    test('isScreenLocked returns true when native says true', () async {
      handler = (_) async => true;

      final bool result = await MethodChannelScreenLockQuery().isScreenLocked();

      expect(result, isTrue);
      expect(calls.single.method, 'isScreenLocked');
    });

    test('isScreenLocked returns false when native says false', () async {
      handler = (_) async => false;

      final bool result = await MethodChannelScreenLockQuery().isScreenLocked();

      expect(result, isFalse);
    });

    test('isScreenLocked returns false when native returns null', () async {
      handler = (_) async => null;

      final bool result = await MethodChannelScreenLockQuery().isScreenLocked();

      expect(result, isFalse);
    });

    test(
      'isScreenLocked falls back to false on PlatformException (safe default)',
      () async {
        // 例外時に true を返すと unlock 経路で 1.3 秒の不要な遅延が
        // 入るので、false (= 500 ms 既定 delay) にフォールバックする。
        handler = (_) async => throw PlatformException(code: 'ERR');

        final bool result = await MethodChannelScreenLockQuery()
            .isScreenLocked();

        expect(result, isFalse);
      },
    );

    test(
      'isScreenLocked falls back to false on MissingPluginException (test env)',
      () async {
        // ハンドラ未登録 (テスト環境で Native 不在) のときの fallback。
        // MissingPluginException を catch しないと AlarmRingingNotifier が
        // 例外で止まり、play() に到達しなくなる。
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);

        final bool result = await MethodChannelScreenLockQuery()
            .isScreenLocked();

        expect(result, isFalse);
      },
    );

    test('isScreenLocked falls back to false when native returns a non-bool '
        '(catch-all defends alarm-ring critical path, PR #75)', () async {
      // Native handler が誤って bool 以外 (例: int / String) を返した
      // ときの fallback。`invokeMethod<bool>` の内部 cast で TypeError
      // になるが、PlatformException / MissingPluginException だけ catch
      // していると伝播してアラーム無音化につながる
      // (Gemini + Copilot 指摘、catch (_) で全例外吸収済)。
      handler = (_) async => 42;

      final bool result = await MethodChannelScreenLockQuery().isScreenLocked();

      expect(result, isFalse);
    });
  });
}
