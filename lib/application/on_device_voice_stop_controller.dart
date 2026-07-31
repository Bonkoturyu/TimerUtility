import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/on_device_speech_recognizer.dart';
import '../domain/voice/on_device_speech_locale.dart';
import '../domain/voice/voice_stop_command_matcher.dart';
import 'on_device_speech_recognizer_provider.dart';

part 'on_device_voice_stop_controller.g.dart';

enum OnDeviceVoiceStopStatus {
  idle,
  starting,
  listening,
  commandDetected,
  modelDownloadRequired,
  modelDownloadPending,
  languageUnsupported,
  unavailable,
  microphonePermissionDenied,
  error,
}

class OnDeviceVoiceStopState {
  const OnDeviceVoiceStopState({
    required this.status,
    required this.commandSequence,
  });

  const OnDeviceVoiceStopState.idle()
    : status = OnDeviceVoiceStopStatus.idle,
      commandSequence = 0;

  final OnDeviceVoiceStopStatus status;
  final int commandSequence;

  OnDeviceVoiceStopState copyWith({
    OnDeviceVoiceStopStatus? status,
    int? commandSequence,
  }) => OnDeviceVoiceStopState(
    status: status ?? this.status,
    commandSequence: commandSequence ?? this.commandSequence,
  );
}

/// Repeats short, on-device-only recognition sessions while the alarm screen
/// is visible. The provider is auto-disposed with that screen.
@riverpod
class OnDeviceVoiceStopController extends _$OnDeviceVoiceStopController {
  static const Duration _retryDelay = Duration(milliseconds: 350);
  static const Duration _busyRetryDelay = Duration(milliseconds: 900);

  final VoiceStopCommandMatcher _matcher = const VoiceStopCommandMatcher();
  late OnDeviceSpeechRecognizer _recognizer;
  Timer? _retryTimer;
  bool _active = false;
  int _generation = 0;
  String _localeTag = 'ja-JP';

  @override
  OnDeviceVoiceStopState build() {
    _recognizer = ref.read(onDeviceSpeechRecognizerProvider);
    final StreamSubscription<OnDeviceSpeechEvent> subscription = _recognizer
        .events
        .listen(_handleEvent);
    ref.onDispose(() {
      unawaited(subscription.cancel());
      _dispose();
    });
    return const OnDeviceVoiceStopState.idle();
  }

  Future<void> start({required String localeTag}) async {
    if (_active) return;
    _active = true;
    final int generation = ++_generation;
    _localeTag = resolveOnDeviceSpeechLocaleTag(localeTag);
    state = state.copyWith(status: OnDeviceVoiceStopStatus.starting);

    final OnDeviceSpeechSupportStatus support = await _recognizer.checkSupport(
      localeTag: _localeTag,
      biasingPhrases: VoiceStopCommandMatcher.biasingPhrases,
    );
    if (!_isCurrent(generation)) return;
    switch (support) {
      case OnDeviceSpeechSupportStatus.ready:
        await _beginSession(generation);
      case OnDeviceSpeechSupportStatus.downloadRequired:
        await _requestModelDownload(generation);
      case OnDeviceSpeechSupportStatus.downloadPending:
        _active = false;
        state = state.copyWith(
          status: OnDeviceVoiceStopStatus.modelDownloadPending,
        );
      case OnDeviceSpeechSupportStatus.unsupported:
        _active = false;
        state = state.copyWith(
          status: OnDeviceVoiceStopStatus.languageUnsupported,
        );
      case OnDeviceSpeechSupportStatus.unavailable:
        _active = false;
        state = state.copyWith(status: OnDeviceVoiceStopStatus.unavailable);
    }
  }

  Future<void> stop() async {
    _active = false;
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    state = state.copyWith(status: OnDeviceVoiceStopStatus.idle);
    await _recognizer.cancelListening();
  }

  Future<void> _beginSession(int generation) async {
    if (!_isCurrent(generation)) return;
    state = state.copyWith(status: OnDeviceVoiceStopStatus.listening);
    try {
      await _recognizer.startListening(
        localeTag: _localeTag,
        biasingPhrases: VoiceStopCommandMatcher.biasingPhrases,
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _active = false;
      state = state.copyWith(status: OnDeviceVoiceStopStatus.error);
    }
  }

  Future<void> _requestModelDownload(int generation) async {
    final OnDeviceSpeechSupportStatus status = await _recognizer
        .requestModelDownload(
          localeTag: _localeTag,
          biasingPhrases: VoiceStopCommandMatcher.biasingPhrases,
        );
    if (!_isCurrent(generation)) return;
    switch (status) {
      case OnDeviceSpeechSupportStatus.ready:
        await _beginSession(generation);
      case OnDeviceSpeechSupportStatus.downloadRequired:
        _active = false;
        state = state.copyWith(
          status: OnDeviceVoiceStopStatus.modelDownloadRequired,
        );
      case OnDeviceSpeechSupportStatus.downloadPending:
        _active = false;
        state = state.copyWith(
          status: OnDeviceVoiceStopStatus.modelDownloadPending,
        );
      case OnDeviceSpeechSupportStatus.unsupported:
        _active = false;
        state = state.copyWith(
          status: OnDeviceVoiceStopStatus.languageUnsupported,
        );
      case OnDeviceSpeechSupportStatus.unavailable:
        _active = false;
        state = state.copyWith(status: OnDeviceVoiceStopStatus.unavailable);
    }
  }

  void _handleEvent(OnDeviceSpeechEvent event) {
    if (!_active) return;
    if (event is OnDeviceSpeechReady) {
      state = state.copyWith(status: OnDeviceVoiceStopStatus.listening);
      return;
    }
    if (event is OnDeviceSpeechResult) {
      if (_matcher.matchesAny(event.hypotheses)) {
        _active = false;
        _retryTimer?.cancel();
        unawaited(_recognizer.cancelListening());
        state = state.copyWith(
          status: OnDeviceVoiceStopStatus.commandDetected,
          commandSequence: state.commandSequence + 1,
        );
      } else {
        _scheduleRetry(_retryDelay);
      }
      return;
    }
    if (event is OnDeviceSpeechError) {
      switch (event.kind) {
        case OnDeviceSpeechErrorKind.noMatch:
        case OnDeviceSpeechErrorKind.speechTimeout:
          _scheduleRetry(_retryDelay);
        case OnDeviceSpeechErrorKind.recognizerBusy:
          _scheduleRetry(_busyRetryDelay);
        case OnDeviceSpeechErrorKind.microphonePermissionDenied:
          _active = false;
          state = state.copyWith(
            status: OnDeviceVoiceStopStatus.microphonePermissionDenied,
          );
        case OnDeviceSpeechErrorKind.languageUnavailable:
          _active = false;
          state = state.copyWith(
            status: OnDeviceVoiceStopStatus.modelDownloadRequired,
          );
        case OnDeviceSpeechErrorKind.languageUnsupported:
          _active = false;
          state = state.copyWith(
            status: OnDeviceVoiceStopStatus.languageUnsupported,
          );
        case OnDeviceSpeechErrorKind.unavailable:
          _active = false;
          state = state.copyWith(status: OnDeviceVoiceStopStatus.unavailable);
        case OnDeviceSpeechErrorKind.other:
          _active = false;
          state = state.copyWith(status: OnDeviceVoiceStopStatus.error);
      }
    }
  }

  void _scheduleRetry(Duration delay) {
    if (!_active) return;
    final int generation = _generation;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(_beginSession(generation)));
  }

  bool _isCurrent(int generation) => _active && generation == _generation;

  void _dispose() {
    _active = false;
    _generation++;
    _retryTimer?.cancel();
    unawaited(_recognizer.cancelListening());
  }
}
