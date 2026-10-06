import 'dart:typed_data';

import '../../../core/pwa/native_share.dart';
import 'gallery_image_save.dart';
import 'image_file_download.dart';

Future<GallerySaveOutcome> savePngToGallery({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) async {
  // Save ≠ Share: download the image file to the device.
  downloadImageBytes(bytes, filename);
  return GallerySaveOutcome.downloaded;
}

Future<GallerySaveOutcome> sharePngImage({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) async {
  final shared = await NativeShare.shareImage(
    bytes: bytes,
    filename: filename,
    title: title,
    text: text,
  );
  switch (shared) {
    case NativeShareOutcome.shared:
      return GallerySaveOutcome.openedShareSheet;
    case NativeShareOutcome.dismissed:
      return GallerySaveOutcome.dismissed;
    case NativeShareOutcome.unavailable:
      // Desktop browsers without file-share: still give the user the file.
      downloadImageBytes(bytes, filename);
      return GallerySaveOutcome.downloaded;
  }
}
