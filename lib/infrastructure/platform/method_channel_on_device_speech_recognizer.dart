import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/ports/on_device_speech_recognizer.dart';

/// Android-only adapter for `SpeechRecognizer.createOnDeviceSpeechRecognizer`.
class MethodChannelOnDeviceSpeechRecognizer
    implements OnDeviceSpeechRecognizer {
  MethodChannelOnDeviceSpeechRecognizer({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const String channelName =
      'io.github.bonkoturyu.timer_utility/on_device_speech';

  final MethodChannel _channel;
  final StreamController<OnDeviceSpeechEvent> _events =
      StreamController<OnDeviceSpeechEvent>.broadcast(sync: true);
  bool _disposed = false;

  @override
  Stream<OnDeviceSpeechEvent> get events => _events.stream;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OnDeviceSpeechSupportStatus> checkSupport({
    required String localeTag,
    required List<String> biasingPhrases,
  }) async {
    try {
      final String? status = await _channel.invokeMethod<String>(
        'checkSupport',
        _speechArguments(localeTag, biasingPhrases),
      );
      return _mapSupportStatus(status);
    } catch (_) {
      return OnDeviceSpeechSupportStatus.unavailable;
    }
  }

  @override
  Future<OnDeviceSpeechSupportStatus> requestModelDownload({
    required String localeTag,
    required List<String> biasingPhrases,
  }) async {
    try {
      final String? status = await _channel.invokeMethod<String>(
        'requestModelDownload',
        _speechArguments(localeTag, biasingPhrases),
      );
      return _mapSupportStatus(status);
    } catch (_) {
      return OnDeviceSpeechSupportStatus.unavailable;
    }
  }

  @override
  Future<void> startListening({
    required String localeTag,
    required List<String> biasingPhrases,
  }) async {
    try {
      await _channel.invokeMethod<void>(
        'startListening',
        _speechArguments(localeTag, biasingPhrases),
      );
    } on PlatformException catch (error) {
      final OnDeviceSpeechErrorKind kind = switch (error.code) {
        'MICROPHONE_PERMISSION_DENIED' =>
          OnDeviceSpeechErrorKind.microphonePermissionDenied,
        'ON_DEVICE_UNAVAILABLE' => OnDeviceSpeechErrorKind.unavailable,
        'RECOGNIZER_BUSY' => OnDeviceSpeechErrorKind.recognizerBusy,
        _ => OnDeviceSpeechErrorKind.other,
      };
      if (!_disposed) {
        _events.add(OnDeviceSpeechError(kind));
      }
    } on MissingPluginException {
      if (!_disposed) {
        _events.add(
          const OnDeviceSpeechError(OnDeviceSpeechErrorKind.unavailable),
        );
      }
    }
  }

  Map<String, Object> _speechArguments(
    String localeTag,
    List<String> biasingPhrases,
  ) => <String, Object>{
    'localeTag': localeTag,
    'biasingPhrases': biasingPhrases,
  };

  OnDeviceSpeechSupportStatus _mapSupportStatus(String? status) =>
      switch (status) {
        'ready' => OnDeviceSpeechSupportStatus.ready,
        'download_required' => OnDeviceSpeechSupportStatus.downloadRequired,
        'download_pending' => OnDeviceSpeechSupportStatus.downloadPending,
        'unsupported' => OnDeviceSpeechSupportStatus.unsupported,
        _ => OnDeviceSpeechSupportStatus.unavailable,
      };

  @override
  Future<void> cancelListening() async {
    if (_disposed) return;
    try {
      await _channel.invokeMethod<void>('cancelListening');
    } on MissingPluginException {
      // Test/unsupported platform: already effectively idle.
    } on PlatformException {
      // Cancellation is best-effort during screen disposal.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (_disposed) return;
    switch (call.method) {
      case 'onReady':
        _events.add(const OnDeviceSpeechReady());
      case 'onFinalResult':
        final Object? arguments = call.arguments;
        if (arguments is! Map<Object?, Object?>) return;
        final List<String> hypotheses =
            (arguments['hypotheses'] as List<Object?>? ?? const <Object?>[])
                .whereType<String>()
                .toList(growable: false);
        final List<double> scores =
            (arguments['confidenceScores'] as List<Object?>? ??
                    const <Object?>[])
                .whereType<num>()
                .map((num value) => value.toDouble())
                .toList(growable: false);
        _events.add(
          OnDeviceSpeechResult(
            hypotheses: hypotheses,
            confidenceScores: scores,
          ),
        );
      case 'onError':
        final String? code =
            (call.arguments as Map<Object?, Object?>?)?['code'] as String?;
        _events.add(OnDeviceSpeechError(_mapError(code)));
    }
  }

  OnDeviceSpeechErrorKind _mapError(String? code) => switch (code) {
    'no_match' => OnDeviceSpeechErrorKind.noMatch,
    'speech_timeout' => OnDeviceSpeechErrorKind.speechTimeout,
    'recognizer_busy' => OnDeviceSpeechErrorKind.recognizerBusy,
    'microphone_permission_denied' =>
      OnDeviceSpeechErrorKind.microphonePermissionDenied,
    'language_unavailable' => OnDeviceSpeechErrorKind.languageUnavailable,
    'language_unsupported' => OnDeviceSpeechErrorKind.languageUnsupported,
    'unavailable' => OnDeviceSpeechErrorKind.unavailable,
    _ => OnDeviceSpeechErrorKind.other,
  };

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    try {
      await _channel.invokeMethod<void>('destroy');
    } catch (_) {
      // Native side may already be gone during app/test teardown.
    }
    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}
