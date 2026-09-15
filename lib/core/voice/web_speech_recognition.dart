import 'web_speech_recognition_stub.dart'
    if (dart.library.js_interop) 'web_speech_recognition_web.dart';

/// Cross-platform façade for browser speech recognition (Arabic).
abstract final class WebSpeechRecognition {
  static bool get isSupported => webSpeechIsSupported;

  /// Listens once and returns the best transcript, or null on cancel/error.
  static Future<String?> listenOnce({
    String lang = 'ar-IQ',
    Duration timeout = const Duration(seconds: 12),
  }) =>
      webSpeechListenOnce(lang: lang, timeout: timeout);

  static void cancel() => webSpeechCancel();
}
