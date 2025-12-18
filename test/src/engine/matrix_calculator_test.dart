import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/engine/matrix_calculator.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';

void main() {
  group('MatrixCalculator', () {
    group('calculateMatrix', () {
      test('calculates identity matrix for zero rotation and center position',
          () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        expect(matrix.a, 100); // width * cos(0) = 100
        expect(matrix.b, 0); // width * sin(0) = 0
        expect(matrix.c, 0); // -height * sin(0) = 0
        expect(matrix.d, 50); // height * cos(0) = 50
        expect(
            matrix.e, 0); // centerX - 0.5 * (a + c) = 0 - 0.5 * (100 + 0) = -50
        expect(
            matrix.f, 0); // centerY - 0.5 * (b + d) = 0 - 0.5 * (0 + 50) = -25
      });

      test('calculates correct matrix for 90 degree rotation', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 90, // 90 degrees
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        // For 90° rotation: cos(90°) = 0, sin(90°) = 1
        expect(matrix.a, closeTo(0, 0.001)); // width * cos(90°) = 0
        expect(matrix.b, closeTo(100, 0.001)); // width * sin(90°) = 100
        expect(matrix.c, closeTo(-50, 0.001)); // -height * sin(90°) = -50
        expect(matrix.d, closeTo(0, 0.001)); // height * cos(90°) = 0
      });

      test('calculates correct matrix for 180 degree rotation', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 180, // 180 degrees
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        // For 180° rotation: cos(180°) = -1, sin(180°) = 0
        expect(matrix.a, closeTo(-100, 0.001)); // width * cos(180°) = -100
        expect(matrix.b, closeTo(0, 0.001)); // width * sin(180°) = 0
        expect(matrix.c, closeTo(0, 0.001)); // -height * sin(180°) = 0
        expect(matrix.d, closeTo(-50, 0.001)); // height * cos(180°) = -50
      });

      test('calculates correct matrix for 270 degree rotation', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 270, // 270 degrees
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        // For 270° rotation: cos(270°) = 0, sin(270°) = -1
        expect(matrix.a, closeTo(0, 0.001));
        expect(matrix.b, closeTo(-100, 0.001));
        expect(matrix.c, closeTo(50, 0.001));
        expect(matrix.d, closeTo(0, 0.001));
      });

      test('calculates correct translation for positioned stamp', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 125, // center x
          centerYPt: 237.5, // center y
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 50,
          heightPt: 75,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        // For rotation 0: e = centerX - 0.5 * (a + c) = 125 - 0.5 * (50 + 0) = 100
        // For rotation 0: f = centerY - 0.5 * (b + d) = 237.5 - 0.5 * (0 + 75) = 200
        expect(matrix.e, 100);
        expect(matrix.f, 200);
      });

      test('handles zero width and height', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 10,
          centerYPt: 20,
          rotationDeg: 45,
          pngBytes: Uint8List(0),
          widthPt: 0,
          heightPt: 0,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        expect(matrix.a, 0);
        expect(matrix.b, 0);
        expect(matrix.c, 0);
        expect(matrix.d, 0);
        expect(matrix.e, 10); // centerX
        expect(matrix.f, 20); // centerY
      });

      test('handles negative coordinates', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: -40,
          centerYPt: -85,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 20,
          heightPt: 30,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        expect(matrix.a, 20);
        expect(matrix.b, 0);
        expect(matrix.c, 0);
        expect(matrix.d, 30);
        // For rotation 0: e = centerX - 0.5 * (a + c) = -40 - 0.5 * (20 + 0) = -50
        expect(matrix.e, -50);
        // For rotation 0: f = centerY - 0.5 * (b + d) = -85 - 0.5 * (0 + 30) = -100
        expect(matrix.f, -100);
      });

      test('works with text stamps', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 50,
          centerYPt: 100,
          rotationDeg: 30, // 30 degrees
          text: 'Test',
          fontSizePt: 12,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        final cos30 = cos(pi / 6);
        final sin30 = sin(pi / 6);

        // Text stamps use simpler rotation matrix
        expect(matrix.a, closeTo(cos30, 0.001));
        expect(matrix.b, closeTo(sin30, 0.001));
        expect(matrix.c, closeTo(-sin30, 0.001));
        expect(matrix.d, closeTo(cos30, 0.001));
        expect(matrix.e, 50); // centerX
        expect(matrix.f, 100); // centerY
      });

      test('handles small rotation angles', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0.001, // Very small angle in degrees
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        expect(matrix.a, closeTo(100, 0.01)); // Should be close to 100
        expect(matrix.b,
            closeTo(0.001745, 0.01)); // Should be small (100 * sin(0.001°))
        expect(matrix.c,
            closeTo(-0.000873, 0.01)); // Should be small (-50 * sin(0.001°))
        expect(matrix.d, closeTo(50, 0.01)); // Should be close to 50
      });

      test('handles large rotation angles', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 360, // Full rotation
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        // 360° rotation should be equivalent to 0 rotation
        expect(matrix.a, closeTo(100, 0.001));
        expect(matrix.b, closeTo(0, 0.001));
        expect(matrix.c, closeTo(0, 0.001));
        expect(matrix.d, closeTo(50, 0.001));
      });

      test('calculates correct position for zero rotation', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 60,
          centerYPt: 45,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 100,
          heightPt: 50,
        );

        final matrix = MatrixCalculator.calculateMatrix(stamp);

        // For rotation 0: e = centerX - 0.5 * (a + c) = 60 - 0.5 * (100 + 0) = 10
        // For rotation 0: f = centerY - 0.5 * (b + d) = 45 - 0.5 * (0 + 50) = 20
        expect(matrix.e, 10);
        expect(matrix.f, 20);
      });
    });

    group('TransformationMatrix', () {
      test('equality comparison works correctly', () {
        const matrix1 = TransformationMatrix(
          a: 1,
          b: 2,
          c: 3,
          d: 4,
          e: 5,
          f: 6,
        );
        const matrix2 = TransformationMatrix(
          a: 1,
          b: 2,
          c: 3,
          d: 4,
          e: 5,
          f: 6,
        );
        const matrix3 = TransformationMatrix(
          a: 1,
          b: 2,
          c: 3,
          d: 4,
          e: 5,
          f: 7, // Different f
        );

        expect(matrix1, equals(matrix2));
        expect(matrix1, isNot(equals(matrix3)));
      });

      test('toString provides readable output', () {
        const matrix = TransformationMatrix(
          a: 1.5,
          b: 2.5,
          c: 3.5,
          d: 4.5,
          e: 5.5,
          f: 6.5,
        );

        final str = matrix.toString();
        expect(str, contains('a=1.5'));
        expect(str, contains('b=2.5'));
        expect(str, contains('c=3.5'));
        expect(str, contains('d=4.5'));
        expect(str, contains('e=5.5'));
        expect(str, contains('f=6.5'));
      });
    });
  });
}
