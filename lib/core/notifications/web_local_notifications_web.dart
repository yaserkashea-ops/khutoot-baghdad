import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web Notifications via the active service worker (phone notification tray).
abstract final class WebLocalNotifications {
  static bool get isSupported {
    try {
      return web.window.isSecureContext;
    } catch (_) {
      return false;
    }
  }

  static String get permission {
    try {
      return web.Notification.permission;
    } catch (_) {
      return 'denied';
    }
  }

  static Future<String> requestPermission() async {
    try {
      final result = await web.Notification.requestPermission().toDart;
      return result.toDart;
    } catch (_) {
      return 'denied';
    }
  }

  static Future<bool> show({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (!isSupported) return false;
    if (permission != 'granted') return false;
    final safeTag = tag ?? 'khutoot-notify';
    final origin = web.window.location.origin;
    final icon = '$origin/icons/app-icon-192-v19.png';
    final badge = '$origin/favicon-v19.png';
    var shown = false;

    try {
      final payload = <String, Object?>{
        'type': 'SHOW_NOTIFICATION',
        'title': title,
        'body': body,
        'tag': safeTag,
        'icon': icon,
        'badge': badge,
      };
      final sw = web.window.navigator.serviceWorker;
      final reg = await sw.ready.toDart;
      final active = reg.active;
      if (active != null) {
        active.postMessage(payload.jsify());
        shown = true;
      }
      // Also call showNotification on the registration (system tray).
      try {
        await reg
            .showNotification(
              title,
              web.NotificationOptions(
                body: body,
                tag: safeTag,
                icon: icon,
                badge: badge,
                dir: 'rtl',
                lang: 'ar',
              ),
            )
            .toDart;
        shown = true;
      } catch (_) {}
    } catch (_) {}

    try {
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          tag: safeTag,
          icon: icon,
          badge: badge,
          dir: 'rtl',
          lang: 'ar',
        ),
      );
      shown = true;
    } catch (_) {}

    return shown;
  }
}
