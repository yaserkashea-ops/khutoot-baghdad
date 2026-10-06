import 'dart:typed_data';

import 'gallery_image_save.dart';

Future<GallerySaveOutcome> savePngToGallery({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) async {
  return GallerySaveOutcome.failed;
}

Future<GallerySaveOutcome> sharePngImage({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) async {
  return GallerySaveOutcome.failed;
}
