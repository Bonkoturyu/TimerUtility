import 'package:flutter/services.dart';

import '../../domain/ports/storage_capacity_reader.dart';
import '../../domain/sound/imported_sound_exceptions.dart';

class MethodChannelStorageCapacityReader implements StorageCapacityReader {
  MethodChannelStorageCapacityReader({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName =
      'io.github.bonkoturyu.timer_utility/storage';

  final MethodChannel _channel;

  @override
  Future<int> getAvailableBytes() async {
    try {
      final int? bytes = await _channel.invokeMethod<int>('getAvailableBytes');
      if (bytes == null || bytes < 0) {
        throw const ImportedSoundStorageUnavailableException();
      }
      return bytes;
    } on PlatformException {
      throw const ImportedSoundStorageUnavailableException();
    } on MissingPluginException {
      throw const ImportedSoundStorageUnavailableException();
    }
  }
}
