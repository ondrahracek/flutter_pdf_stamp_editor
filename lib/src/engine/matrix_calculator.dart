import 'dart:math' as math;

import '../model/pdf_stamp.dart';

/// Represents a PDF transformation matrix.
///
/// PDF transformation matrices use the form:
/// [a  b  0]
/// [c  d  0]
/// [e  f  1]
///
/// Where:
/// - a, b, c, d: rotation and scaling
/// - e, f: translation (position)
class TransformationMatrix {
  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  const TransformationMatrix({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
    required this.f,
  });

  @override
  String toString() => 'Matrix(a=$a, b=$b, c=$c, d=$d, e=$e, f=$f)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformationMatrix &&
          runtimeType == other.runtimeType &&
          a == other.a &&
          b == other.b &&
          c == other.c &&
          d == other.d &&
          e == other.e &&
          f == other.f;

  @override
  int get hashCode => Object.hash(a, b, c, d, e, f);
}

/// Calculates PDF transformation matrices for stamps.
///
/// This class provides pure mathematical functions for calculating
/// transformation matrices based on stamp position, size, and rotation.
class MatrixCalculator {
  /// Calculates a transformation matrix for a PDF stamp.
  ///
  /// The matrix transforms the stamp from its local coordinate system
  /// to the PDF page coordinate system, including rotation around the center.
  ///
  /// [stamp] The stamp to calculate the matrix for.
  ///
  /// Returns a [TransformationMatrix] representing the transformation.
  static TransformationMatrix calculateMatrix(PdfStamp stamp) {
    if (stamp case ImageStamp s) {
      return _calculateImageMatrix(s);
    } else if (stamp case TextStamp s) {
      return _calculateTextMatrix(s);
    }
    throw ArgumentError('Unknown stamp type');
  }

  static TransformationMatrix _calculateImageMatrix(ImageStamp stamp) {
    // Convert degrees to radians
    final theta = stamp.rotationDeg * math.pi / 180.0;
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);

    // Rotation and scaling components
    final a = stamp.widthPt * cosT;
    final b = stamp.widthPt * sinT;
    final c = -stamp.heightPt * sinT;
    final d = stamp.heightPt * cosT;

    // Translation: adjust center to account for rotation
    final e = stamp.centerXPt - 0.5 * (a + c);
    final f = stamp.centerYPt - 0.5 * (b + d);

    return TransformationMatrix(
      a: a,
      b: b,
      c: c,
      d: d,
      e: e,
      f: f,
    );
  }

  static TransformationMatrix _calculateTextMatrix(TextStamp stamp) {
    // Convert degrees to radians
    final theta = stamp.rotationDeg * math.pi / 180.0;
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);

    // For text, we use a simpler rotation matrix
    // The center point is used directly as translation
    return TransformationMatrix(
      a: cosT,
      b: sinT,
      c: -sinT,
      d: cosT,
      e: stamp.centerXPt,
      f: stamp.centerYPt,
    );
  }
}
