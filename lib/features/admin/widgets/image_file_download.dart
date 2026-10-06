import 'dart:typed_data';

import 'image_file_download_stub.dart'
    if (dart.library.js_interop) 'image_file_download_web.dart' as download;

/// Saves [bytes] as a downloadable file in the browser; no-op on other platforms.
void downloadImageBytes(Uint8List bytes, String filename) {
  download.downloadImageBytes(bytes, filename);
}
