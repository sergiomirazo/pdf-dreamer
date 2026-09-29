import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageBytesUtils {
  const ImageBytesUtils._();

  static Future<ui.Image> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  static Future<Uint8List> encodePng(Uint8List bytes) async {
    final image = await decode(bytes);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const FormatException('No se pudo codificar la imagen.');
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<Uint8List> imageToPng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const FormatException('No se pudo codificar la imagen.');
    }
    return data.buffer.asUint8List();
  }
}
