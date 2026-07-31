import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/on_device_speech_recognizer.dart';
import '../infrastructure/platform/method_channel_on_device_speech_recognizer.dart';

part 'on_device_speech_recognizer_provider.g.dart';

@Riverpod(keepAlive: true)
OnDeviceSpeechRecognizer onDeviceSpeechRecognizer(Ref ref) {
  final recognizer = MethodChannelOnDeviceSpeechRecognizer();
  ref.onDispose(() => unawaited(recognizer.dispose()));
  return recognizer;
}

@riverpod
Future<bool> onDeviceSpeechRecognitionAvailable(Ref ref) =>
    ref.watch(onDeviceSpeechRecognizerProvider).isAvailable();
