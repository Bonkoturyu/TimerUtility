import 'dart:async';

/// Events emitted by the platform on-device speech recognizer.
///
/// Transcripts are intentionally transient. Callers must not persist or log
/// them; they exist only long enough to match a small command allow-list.
sealed class OnDeviceSpeechEvent {
  const OnDeviceSpeechEvent();
}

final class OnDeviceSpeechReady extends OnDeviceSpeechEvent {
  const OnDeviceSpeechReady();
}

final class OnDeviceSpeechResult extends OnDeviceSpeechEvent {
  const OnDeviceSpeechResult({
    required this.hypotheses,
    this.confidenceScores = const <double>[],
  });

  final List<String> hypotheses;
  final List<double> confidenceScores;
}

enum OnDeviceSpeechErrorKind {
  noMatch,
  speechTimeout,
  recognizerBusy,
  microphonePermissionDenied,
  languageUnavailable,
  languageUnsupported,
  unavailable,
  other,
}

final class OnDeviceSpeechError extends OnDeviceSpeechEvent {
  const OnDeviceSpeechError(this.kind);

  final OnDeviceSpeechErrorKind kind;
}

enum OnDeviceSpeechSupportStatus {
  ready,
  downloadRequired,
  downloadPending,
  unsupported,
  unavailable,
}

/// Pure Dart boundary for Android's API 31+ on-device SpeechRecognizer.
abstract interface class OnDeviceSpeechRecognizer {
  Stream<OnDeviceSpeechEvent> get events;

  /// Returns true only when Android exposes a dedicated on-device engine.
  Future<bool> isAvailable();

  /// Checks whether the requested language model can be used immediately.
  ///
  /// API 31-32 implementations may report [OnDeviceSpeechSupportStatus.ready]
  /// when an on-device engine exists because Android cannot preflight model
  /// availability before API 33.
  Future<OnDeviceSpeechSupportStatus> checkSupport({
    required String localeTag,
    required List<String> biasingPhrases,
  });

  /// Requests Android to download the requested on-device language model.
  Future<OnDeviceSpeechSupportStatus> requestModelDownload({
    required String localeTag,
    required List<String> biasingPhrases,
  });

  /// Starts one short recognition session.
  ///
  /// Implementations must use the on-device recognizer factory and must never
  /// fall back to the default/cloud recognizer.
  Future<void> startListening({
    required String localeTag,
    required List<String> biasingPhrases,
  });

  /// Cancels the current session. Safe to call when already idle.
  Future<void> cancelListening();

  /// Releases the native recognizer and event channel.
  Future<void> dispose();
}
