import 'dart:typed_data';

import 'gallery_image_save_stub.dart'
    if (dart.library.io) 'gallery_image_save_io.dart'
    if (dart.library.html) 'gallery_image_save_web.dart' as impl;

enum GallerySaveOutcome {
  /// Written directly into the device photo library.
  savedToGallery,

  /// OS share sheet opened (user can pick Gallery / Save image).
  openedShareSheet,

  /// User dismissed the share sheet.
  dismissed,

  /// Browser download fallback.
  downloaded,

  /// Failed.
  failed,
}

/// Saves a PNG to the photo library when native APIs exist; on web opens the
/// system share sheet (files-only) so the user can save to Studio / Photos.
Future<GallerySaveOutcome> savePngToGallery({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) {
  return impl.savePngToGallery(
    bytes: bytes,
    filename: filename,
    title: title,
    text: text,
  );
}

Future<GallerySaveOutcome> sharePngImage({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) {
  return impl.sharePngImage(
    bytes: bytes,
    filename: filename,
    title: title,
    text: text,
  );
}
