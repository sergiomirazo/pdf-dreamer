import 'dart:typed_data';
import 'dart:ui';

enum DocumentEditType { brushStroke, imageStamp }

class BrushStroke {
  const BrushStroke({
    required this.points,
    required this.color,
    required this.width,
    this.fixed = false,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final bool fixed;

  BrushStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    bool? fixed,
  }) {
    return BrushStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      fixed: fixed ?? this.fixed,
    );
  }
}

class ImageStamp {
  const ImageStamp({
    required this.id,
    required this.bytes,
    required this.rect,
    this.fixed = false,
    this.opacity = 1,
  });

  final String id;
  final Uint8List bytes;
  final Rect rect;
  final bool fixed;
  final double opacity;

  ImageStamp copyWith({
    Uint8List? bytes,
    Rect? rect,
    bool? fixed,
    double? opacity,
  }) {
    return ImageStamp(
      id: id,
      bytes: bytes ?? this.bytes,
      rect: rect ?? this.rect,
      fixed: fixed ?? this.fixed,
      opacity: opacity ?? this.opacity,
    );
  }
}

class DocumentEdit {
  const DocumentEdit.brush(this.stroke)
    : stamp = null,
      type = DocumentEditType.brushStroke;

  const DocumentEdit.image(this.stamp)
    : stroke = null,
      type = DocumentEditType.imageStamp;

  final DocumentEditType type;
  final BrushStroke? stroke;
  final ImageStamp? stamp;
}
