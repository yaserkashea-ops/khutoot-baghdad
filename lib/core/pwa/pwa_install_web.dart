import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('__masaratPwa')
external _PwaApi? get _api;

extension type _PwaApi._(JSObject _) implements JSObject {
  external bool get canInstall;
  external bool isStandalone();
  external bool isIos();
  external bool isMobile();
  external void setMode(String mode);
  external bool ensureAdminHash();
  external bool isAdminEntry();
  external bool openAdminEntry();
  external JSPromise<JSAny?> promptInstall();
  external JSPromise<JSBoolean> waitForPrompt(JSNumber ms);
}

class PwaInstall {
  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static bool _listening = false;

  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    web.window.addEventListener(
      'masarat-install-state',
      (web.Event event) {
        if (!_controller.isClosed) _controller.add(null);
      }.toJS,
    );
  }

  static bool get isStandalone {
    try {
      return _api?.isStandalone() ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get canNativeInstall {
    try {
      return _api?.canInstall ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get isIos {
    try {
      return _api?.isIos() ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get isMobile {
    try {
      return _api?.isMobile() ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get isAdminEntry {
    try {
      return _api?.isAdminEntry() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Stream<void> get onStateChanged {
    _ensureListening();
    return _controller.stream;
  }

  static void setMode(String mode) {
    try {
      _api?.setMode(mode);
    } catch (_) {}
  }

  static bool ensureAdminHash() {
    try {
      return _api?.ensureAdminHash() ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool openAdminEntry() {
    try {
      return _api?.openAdminEntry() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> waitForPrompt({
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    final api = _api;
    if (api == null) return false;
    if (api.canInstall) return true;
    try {
      final ready = await api.waitForPrompt(timeout.inMilliseconds.toJS).toDart;
      return ready.toDart;
    } catch (_) {
      return api.canInstall;
    }
  }

  static Future<String> promptInstall() async {
    final api = _api;
    if (api == null) return 'unavailable';
    final any = await api.promptInstall().toDart;
    if (any == null) return 'unavailable';
    return (any as JSString).toDart;
  }
}
