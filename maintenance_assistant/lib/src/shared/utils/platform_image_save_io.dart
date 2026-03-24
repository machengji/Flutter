import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

Future<void> saveImageToDevice({
  required Uint8List bytes,
  required String fileName,
}) async {
  final result = await ImageGallerySaverPlus.saveImage(
    bytes,
    quality: 100,
    name: fileName,
  );

  if (result['isSuccess'] != true) {
    throw Exception('Failed to save image to gallery.');
  }
}
