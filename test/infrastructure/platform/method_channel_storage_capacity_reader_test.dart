import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/sound/imported_sound_exceptions.dart';
import 'package:timer_utility/infrastructure/platform/method_channel_storage_capacity_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelStorageCapacityReader', () {
    const MethodChannel channel = MethodChannel(
      MethodChannelStorageCapacityReader.channelName,
    );

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Nativeが返した利用可能byte数を返す', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            expect(call.method, 'getAvailableBytes');
            return 12_000_000_000;
          });

      expect(
        await MethodChannelStorageCapacityReader().getAvailableBytes(),
        12_000_000_000,
      );
    });

    test('nullを取得失敗として扱う', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);

      expect(
        MethodChannelStorageCapacityReader().getAvailableBytes,
        throwsA(isA<ImportedSoundStorageUnavailableException>()),
      );
    });

    test('PlatformExceptionをDomain例外へ変換する', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => throw PlatformException(code: 'FAILED'),
          );

      expect(
        MethodChannelStorageCapacityReader().getAvailableBytes,
        throwsA(isA<ImportedSoundStorageUnavailableException>()),
      );
    });
  });
}
