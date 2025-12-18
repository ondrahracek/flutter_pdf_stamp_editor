import 'dart:typed_data';

/// Base class for PDF stamps (sealed class hierarchy).
/// 
/// All stamps use PDF user-space coordinates (points, origin bottom-left).
sealed class PdfStamp {
  PdfStamp({
    required this.pageIndex,
    required this.centerXPt,
    required this.centerYPt,
    required this.rotationDeg,
  });

  /// 0-based page index
  final int pageIndex;

  /// Center X coordinate in PDF points (origin bottom-left)
  final double centerXPt;

  /// Center Y coordinate in PDF points (origin bottom-left)
  final double centerYPt;

  /// Rotation in degrees (clockwise)
  final double rotationDeg;
}

/// Image stamp using PNG bytes.
class ImageStamp extends PdfStamp {
  ImageStamp({
    required super.pageIndex,
    required super.centerXPt,
    required super.centerYPt,
    required super.rotationDeg,
    required this.pngBytes,
    required this.widthPt,
    required this.heightPt,
  });

  final Uint8List pngBytes;
  final double widthPt;
  final double heightPt;
}

/// Text stamp.
class TextStamp extends PdfStamp {
  TextStamp({
    required super.pageIndex,
    required super.centerXPt,
    required super.centerYPt,
    required super.rotationDeg,
    required this.text,
    required this.fontSizePt,
  });

  final String text;
  final double fontSizePt;
}
