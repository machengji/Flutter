import 'dart:typed_data';

Future<void> saveImageToDevice({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Saving images is not supported on this platform.');
}
