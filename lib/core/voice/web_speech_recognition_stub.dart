/// Non-web stub.
bool get webSpeechIsSupported => false;

Future<String?> webSpeechListenOnce({
  String lang = 'ar-IQ',
  Duration timeout = const Duration(seconds: 12),
}) async =>
    null;

void webSpeechCancel() {}
