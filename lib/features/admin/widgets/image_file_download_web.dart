import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadImageBytes(Uint8List bytes, String filename) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.rel = 'noopener';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();

  final ua = web.window.navigator.userAgent.toLowerCase();
  final isAppleMobile = ua.contains('iphone') ||
      ua.contains('ipad') ||
      (ua.contains('macintosh') && ua.contains('mobile'));

  if (isAppleMobile) {
    // Safari often ignores the download attribute — open the image so the
    // user can tap Share → Save Image.
    web.window.open(url, '_blank');
    // Revoke later so the new tab can load the blob.
    Future<void>.delayed(const Duration(seconds: 60), () {
      web.URL.revokeObjectURL(url);
    });
  } else {
    Future<void>.delayed(const Duration(seconds: 2), () {
      web.URL.revokeObjectURL(url);
    });
  }
}
