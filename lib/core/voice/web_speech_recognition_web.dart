import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool get webSpeechIsSupported =>
    globalContext.has('SpeechRecognition') ||
    globalContext.has('webkitSpeechRecognition');

web.SpeechRecognition? _active;

Future<String?> webSpeechListenOnce({
  String lang = 'ar-IQ',
  Duration timeout = const Duration(seconds: 12),
}) async {
  if (!webSpeechIsSupported) return null;

  webSpeechCancel();

  final recognition = _createRecognition();
  if (recognition == null) return null;
  _active = recognition;

  recognition.lang = lang;
  recognition.interimResults = false;
  recognition.continuous = false;
  recognition.maxAlternatives = 3;

  final completer = Completer<String?>();

  void finish(String? value) {
    if (completer.isCompleted) return;
    completer.complete(value);
    _active = null;
  }

  recognition.onresult = (web.SpeechRecognitionEvent event) {
    final results = event.results;
    if (results.length == 0) {
      finish(null);
      return;
    }
    final last = results.item(results.length - 1);
    if (last.length == 0) {
      finish(null);
      return;
    }
    final alt = last.item(0);
    finish(alt.transcript.trim());
  }.toJS;

  recognition.onerror = (web.SpeechRecognitionErrorEvent event) {
    finish(null);
  }.toJS;

  recognition.onend = (web.Event _) {
    if (!completer.isCompleted) finish(null);
  }.toJS;

  try {
    recognition.start();
  } catch (_) {
    finish(null);
    return null;
  }

  return completer.future.timeout(
    timeout,
    onTimeout: () {
      webSpeechCancel();
      return null;
    },
  );
}

void webSpeechCancel() {
  final r = _active;
  _active = null;
  if (r == null) return;
  try {
    r.stop();
  } catch (_) {}
  try {
    r.abort();
  } catch (_) {}
}

web.SpeechRecognition? _createRecognition() {
  final ctor = globalContext.getProperty('SpeechRecognition'.toJS) ??
      globalContext.getProperty('webkitSpeechRecognition'.toJS);
  if (ctor == null) return null;
  try {
    return (ctor as JSFunction).callAsConstructor<web.SpeechRecognition>();
  } catch (_) {
    return null;
  }
}
