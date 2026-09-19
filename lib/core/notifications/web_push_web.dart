import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web Push via JS helpers in index.html (reliable on Chrome Android).
abstract final class WebPush {
  static bool get isSupported {
    try {
      return _hasSubscribeFn();
    } catch (_) {
      return false;
    }
  }

  /// Returns endpoint/p256dh/auth or null.
  static Future<Map<String, String>?> subscribe({
    required String vapidPublicKey,
  }) async {
    try {
      final result = await _subscribeJs(vapidPublicKey).toDart;
      if (result == null) return null;
      final endpoint = result.getProperty('endpoint'.toJS);
      final p256dh = result.getProperty('p256dh'.toJS);
      final auth = result.getProperty('auth'.toJS);
      if (endpoint == null || p256dh == null || auth == null) return null;
      return {
        'endpoint': (endpoint as JSString).toDart,
        'p256dh': (p256dh as JSString).toDart,
        'auth': (auth as JSString).toDart,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> unsubscribe() async {
    try {
      await _unsubscribeJs().toDart;
    } catch (_) {}
  }
}

@JS('__khutootPushSubscribe')
external JSPromise<JSObject?> _subscribeJs(String vapidPublicKey);

@JS('__khutootPushUnsubscribe')
external JSPromise<JSAny?> _unsubscribeJs();

@JS('__khutootPushSubscribe')
external JSFunction? get _subscribeFn;

bool _hasSubscribeFn() => _subscribeFn != null;
