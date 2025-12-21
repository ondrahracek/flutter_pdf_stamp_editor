import 'dart:typed_data';

import 'package:flutter/material.dart';

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

  ImageStamp copyWith({
    int? pageIndex,
    double? centerXPt,
    double? centerYPt,
    double? rotationDeg,
    Uint8List? pngBytes,
    double? widthPt,
    double? heightPt,
  }) {
    return ImageStamp(
      pageIndex: pageIndex ?? this.pageIndex,
      centerXPt: centerXPt ?? this.centerXPt,
      centerYPt: centerYPt ?? this.centerYPt,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      pngBytes: pngBytes ?? this.pngBytes,
      widthPt: widthPt ?? this.widthPt,
      heightPt: heightPt ?? this.heightPt,
    );
  }
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
    required this.color,
  });

  final String text;
  final double fontSizePt;
  final Color color;

  TextStamp copyWith({
    int? pageIndex,
    double? centerXPt,
    double? centerYPt,
    double? rotationDeg,
    String? text,
    double? fontSizePt,
    Color? color,
  }) {
    return TextStamp(
      pageIndex: pageIndex ?? this.pageIndex,
      centerXPt: centerXPt ?? this.centerXPt,
      centerYPt: centerYPt ?? this.centerYPt,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      text: text ?? this.text,
      fontSizePt: fontSizePt ?? this.fontSizePt,
      color: color ?? this.color,
    );
  }
}
