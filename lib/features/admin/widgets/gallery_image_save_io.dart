import 'dart:typed_data';

import 'package:gal/gal.dart';

import 'gallery_image_save.dart';

Future<GallerySaveOutcome> savePngToGallery({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) async {
  try {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) return GallerySaveOutcome.failed;
    }
    await Gal.putImageBytes(
      bytes,
      name: filename.replaceAll('.png', ''),
      album: 'دليل خطوط بغداد',
    );
    return GallerySaveOutcome.savedToGallery;
  } catch (_) {
    try {
      await Gal.putImageBytes(bytes, name: filename.replaceAll('.png', ''));
      return GallerySaveOutcome.savedToGallery;
    } catch (_) {
      return GallerySaveOutcome.failed;
    }
  }
}

Future<GallerySaveOutcome> sharePngImage({
  required Uint8List bytes,
  required String filename,
  String title = 'دليل خطوط بغداد',
  String? text,
}) async {
  return GallerySaveOutcome.failed;
}
