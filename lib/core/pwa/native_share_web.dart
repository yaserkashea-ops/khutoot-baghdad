import 'dart:js_interop';
import 'dart:typed_data';

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
      if (error.toString().contains('AbortError')) {
        return NativeShareOutcome.dismissed;
      }
      return NativeShareOutcome.unavailable;
    }
  }

  /// Shares a PNG via the OS sheet (Save image / Gallery / WhatsApp…).
  ///
  /// [filename] must be ASCII — Arabic names break file share on Android.
  static Future<NativeShareOutcome> shareImage({
    required List<int> bytes,
    required String filename,
    required String title,
    String? text,
  }) async {
    try {
      final data = Uint8List.fromList(bytes);
      final blob = web.Blob(
        [data.toJS].toJS,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final safeName = filename.endsWith('.png') ? filename : '$filename.png';
      final file = web.File(
        [blob].toJS,
        safeName,
        web.FilePropertyBag(type: 'image/png'),
      );
      final files = [file].toJS;

      // Files-only → mobile OS shows «Save image» / Studio prominently.
      final filesOnly = web.ShareData(files: files);
      if (_canShare(filesOnly)) {
        await web.window.navigator.share(filesOnly).toDart;
        return NativeShareOutcome.shared;
      }

      final withMeta = web.ShareData(
        files: files,
        title: title,
        text: text ?? title,
      );
      if (_canShare(withMeta)) {
        await web.window.navigator.share(withMeta).toDart;
        return NativeShareOutcome.shared;
      }

      return NativeShareOutcome.unavailable;
    } catch (error) {
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
