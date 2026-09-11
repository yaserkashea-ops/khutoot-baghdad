import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Result of attempting the OS / browser share sheet.
enum NativeShareOutcome {
  /// User completed a share action (or the sheet opened successfully).
  shared,

  /// User dismissed the system sheet without sharing.
  dismissed,

  /// System share is not available on this device/browser.
  unavailable,
}

/// Opens the browser Web Share API (same sheet used by professional PWAs).
abstract final class NativeShare {
  static Future<NativeShareOutcome> share({
    required String title,
    required String text,
    required String url,
  }) async {
    try {
      final withUrl = web.ShareData(title: title, text: text, url: url);
      if (_canShare(withUrl)) {
        await web.window.navigator.share(withUrl).toDart;
        return NativeShareOutcome.shared;
      }

      // Some agents accept text only (URL embedded).
      final textOnly = web.ShareData(
        title: title,
        text: '$text\n$url',
      );
      if (_canShare(textOnly)) {
        await web.window.navigator.share(textOnly).toDart;
        return NativeShareOutcome.shared;
      }

      return NativeShareOutcome.unavailable;
    } catch (error) {
      // User closed the system sheet without sharing.
      if (error.toString().contains('AbortError')) {
        return NativeShareOutcome.dismissed;
      }
      return NativeShareOutcome.unavailable;
    }
  }

  static bool _canShare(web.ShareData data) {
    try {
      return web.window.navigator.canShare(data);
    } catch (_) {
      return false;
    }
  }
}
