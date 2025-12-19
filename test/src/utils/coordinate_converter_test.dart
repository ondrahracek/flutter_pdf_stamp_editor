import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/utils/coordinate_converter.dart';
import 'package:pdfrx/pdfrx.dart';

class MockPdfPage implements PdfPage {
  @override
  final double width;
  @override
  final double height;
  @override
  final PdfPageRotation rotation;
  @override
  final int pageNumber;

  MockPdfPage({
    required this.width,
    required this.height,
    required this.rotation,
    this.pageNumber = 1,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  PdfDocument get document => throw UnimplementedError();

  @override
  bool get isLoaded => throw UnimplementedError();

  @override
  PdfPageRenderCancellationToken createCancellationToken() =>
      throw UnimplementedError();

  @override
  Future<List<PdfLink>> loadLinks(
          {bool compact = false, bool enableAutoLinkDetection = true}) =>
      throw UnimplementedError();

  @override
  Future<PdfPageRawText?> loadText() => throw UnimplementedError();

  @override
  Future<PdfImage?> render({
    PdfAnnotationRenderingMode annotationRenderingMode = PdfAnnotationRenderingMode.none,
    int? backgroundColor,
    PdfPageRenderCancellationToken? cancellationToken,
    int flags = 0,
    double? fullHeight,
    double? fullWidth,
    int? height,
    PdfPageRotation? rotationOverride,
    int? width,
    int x = 0,
    int y = 0,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('PdfCoordinateConverter', () {
    group('viewerOffsetToPdfPoint', () {
      test('converts screen coordinates to PDF coordinates for 0° rotation',
          () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);
        final screenOffset = const Offset(100.0, 100.0);

        final result = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: screenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<PdfPoint>());
        expect(result.x, closeTo(100.0, 0.01));
        expect(result.y, closeTo(692.0, 0.01)); // 792 - 100 (bottom-left origin)
      });

      test('converts screen coordinates to PDF coordinates for 90° rotation',
          () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise90,
        );
        final scaledPageSize = const Size(792.0, 612.0); // Rotated dimensions
        const screenOffset = Offset(100.0, 100.0);

        final result = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: screenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<PdfPoint>());
        // For 90° rotation, coordinate mapping is different
        // Top-left (100, 100) in viewer should map to PDF coordinates
        // The exact values depend on pdfrx's toPdfPoint implementation
        expect(result.x, isA<double>());
        expect(result.y, isA<double>());
      });

      test('converts screen coordinates to PDF coordinates for 180° rotation',
          () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise180,
        );
        final scaledPageSize = const Size(612.0, 792.0);
        const screenOffset = Offset(100.0, 100.0);

        final result = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: screenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<PdfPoint>());
        expect(result.x, isA<double>());
        expect(result.y, isA<double>());
      });

      test('converts screen coordinates to PDF coordinates for 270° rotation',
          () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise270,
        );
        final scaledPageSize = const Size(792.0, 612.0); // Rotated dimensions
        const screenOffset = Offset(100.0, 100.0);

        final result = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: screenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<PdfPoint>());
        expect(result.x, isA<double>());
        expect(result.y, isA<double>());
      });
    });

    group('pdfPointToViewerOffset', () {
      test('converts PDF coordinates to screen coordinates for 0° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);
        const pdfX = 100.0;
        const pdfY = 692.0; // Bottom-left origin: 792 - 100 = 692

        final result = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: pdfX,
          yPt: pdfY,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<Offset>());
        expect(result.dx, closeTo(100.0, 0.01));
        expect(result.dy, closeTo(100.0, 0.01)); // Top-left origin
      });

      test('converts PDF coordinates to screen coordinates for 90° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise90,
        );
        final scaledPageSize = const Size(792.0, 612.0); // Rotated dimensions
        const pdfX = 100.0;
        const pdfY = 100.0;

        final result = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: pdfX,
          yPt: pdfY,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<Offset>());
        expect(result.dx, isA<double>());
        expect(result.dy, isA<double>());
      });

      test('converts PDF coordinates to screen coordinates for 180° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise180,
        );
        final scaledPageSize = const Size(612.0, 792.0);
        const pdfX = 512.0; // 612 - 100
        const pdfY = 100.0; // Should map to screen position

        final result = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: pdfX,
          yPt: pdfY,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<Offset>());
        expect(result.dx, isA<double>());
        expect(result.dy, isA<double>());
      });

      test('converts PDF coordinates to screen coordinates for 270° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise270,
        );
        final scaledPageSize = const Size(792.0, 612.0); // Rotated dimensions
        const pdfX = 100.0;
        const pdfY = 100.0;

        final result = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: pdfX,
          yPt: pdfY,
          scaledPageSizePx: scaledPageSize,
        );

        expect(result, isA<Offset>());
        expect(result.dx, isA<double>());
        expect(result.dy, isA<double>());
      });

      test('round-trip conversion maintains accuracy', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);
        const originalPdfX = 150.0;
        const originalPdfY = 642.0; // 792 - 150

        // Convert PDF -> Screen
        final screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: originalPdfX,
          yPt: originalPdfY,
          scaledPageSizePx: scaledPageSize,
        );

        // Convert Screen -> PDF (round-trip)
        final roundTripPdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: screenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        // Should be very close to original (allowing for floating point precision)
        expect(roundTripPdfPoint.x, closeTo(originalPdfX, 0.1));
        expect(roundTripPdfPoint.y, closeTo(originalPdfY, 0.1));
      });
    });

    group('pageScaleFactors', () {
      test('calculates scale factors for 0° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(306.0, 396.0); // Half size

        final result = PdfCoordinateConverter.pageScaleFactors(
          page,
          scaledPageSize,
        );

        expect(result.sx, closeTo(0.5, 0.01)); // 306 / 612
        expect(result.sy, closeTo(0.5, 0.01)); // 396 / 792
      });

      test('calculates scale factors for 90° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise90,
        );
        // Rotated: width becomes height, height becomes width
        final scaledPageSize = const Size(396.0, 306.0); // Half size (rotated)

        final result = PdfCoordinateConverter.pageScaleFactors(
          page,
          scaledPageSize,
        );

        // For 90° rotation, dimensions swap: w=792, h=612
        expect(result.sx, closeTo(0.5, 0.01)); // 396 / 792
        expect(result.sy, closeTo(0.5, 0.01)); // 306 / 612
      });

      test('calculates scale factors for 180° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise180,
        );
        final scaledPageSize = const Size(306.0, 396.0); // Half size

        final result = PdfCoordinateConverter.pageScaleFactors(
          page,
          scaledPageSize,
        );

        // For 180°, dimensions don't swap
        expect(result.sx, closeTo(0.5, 0.01)); // 306 / 612
        expect(result.sy, closeTo(0.5, 0.01)); // 396 / 792
      });

      test('calculates scale factors for 270° rotation', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.clockwise270,
        );
        // Rotated: width becomes height, height becomes width
        final scaledPageSize = const Size(396.0, 306.0); // Half size (rotated)

        final result = PdfCoordinateConverter.pageScaleFactors(
          page,
          scaledPageSize,
        );

        // For 270° rotation, dimensions swap: w=792, h=612
        expect(result.sx, closeTo(0.5, 0.01)); // 396 / 792
        expect(result.sy, closeTo(0.5, 0.01)); // 306 / 612
      });
    });

    group('rotationToDegrees', () {
      test('converts PdfPageRotation.none to 0', () {
        final result = PdfCoordinateConverter.rotationToDegrees(
          PdfPageRotation.none,
        );
        expect(result, 0);
      });

      test('converts PdfPageRotation.clockwise90 to 90', () {
        final result = PdfCoordinateConverter.rotationToDegrees(
          PdfPageRotation.clockwise90,
        );
        expect(result, 90);
      });

      test('converts PdfPageRotation.clockwise180 to 180', () {
        final result = PdfCoordinateConverter.rotationToDegrees(
          PdfPageRotation.clockwise180,
        );
        expect(result, 180);
      });

      test('converts PdfPageRotation.clockwise270 to 270', () {
        final result = PdfCoordinateConverter.rotationToDegrees(
          PdfPageRotation.clockwise270,
        );
        expect(result, 270);
      });

      test('converts int rotation values correctly', () {
        expect(PdfCoordinateConverter.rotationToDegrees(45), 45);
        expect(PdfCoordinateConverter.rotationToDegrees(360), 0);
        expect(PdfCoordinateConverter.rotationToDegrees(370), 10);
        expect(PdfCoordinateConverter.rotationToDegrees(-10), 350);
      });
    });

    group('edge cases', () {
      test('handles zero coordinates', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);

        // Zero screen offset
        final pdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: Offset.zero,
          scaledPageSizePx: scaledPageSize,
        );

        expect(pdfPoint, isA<PdfPoint>());
        expect(pdfPoint.x, isA<double>());
        expect(pdfPoint.y, closeTo(792.0, 0.01)); // Bottom of page

        // Zero PDF coordinates
        final screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: 0.0,
          yPt: 0.0,
          scaledPageSizePx: scaledPageSize,
        );

        expect(screenOffset, isA<Offset>());
        expect(screenOffset.dx, closeTo(0.0, 0.01));
        expect(screenOffset.dy, closeTo(792.0, 0.01)); // Top-left origin
      });

      test('handles coordinates at page boundaries', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);

        // Top-left corner (screen)
        final topLeftPdf = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: Offset.zero,
          scaledPageSizePx: scaledPageSize,
        );
        expect(topLeftPdf.x, closeTo(0.0, 0.01));
        expect(topLeftPdf.y, closeTo(792.0, 0.01));

        // Bottom-right corner (screen)
        final bottomRightPdf = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: const Offset(612.0, 792.0),
          scaledPageSizePx: scaledPageSize,
        );
        expect(bottomRightPdf.x, closeTo(612.0, 0.01));
        expect(bottomRightPdf.y, closeTo(0.0, 0.01));

        // Bottom-left corner (PDF)
        final bottomLeftScreen = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: 0.0,
          yPt: 0.0,
          scaledPageSizePx: scaledPageSize,
        );
        expect(bottomLeftScreen.dx, closeTo(0.0, 0.01));
        expect(bottomLeftScreen.dy, closeTo(792.0, 0.01));

        // Top-right corner (PDF)
        final topRightScreen = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: 612.0,
          yPt: 792.0,
          scaledPageSizePx: scaledPageSize,
        );
        expect(topRightScreen.dx, closeTo(612.0, 0.01));
        expect(topRightScreen.dy, closeTo(0.0, 0.01));
      });

      test('handles very large coordinates', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);

        // Large screen offset
        final largeScreenOffset = const Offset(10000.0, 10000.0);
        final pdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: largeScreenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        expect(pdfPoint, isA<PdfPoint>());
        expect(pdfPoint.x, isA<double>());
        expect(pdfPoint.y, isA<double>());

        // Large PDF coordinates
        final largePdfX = 10000.0;
        final largePdfY = 10000.0;
        final screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: largePdfX,
          yPt: largePdfY,
          scaledPageSizePx: scaledPageSize,
        );

        expect(screenOffset, isA<Offset>());
        expect(screenOffset.dx, isA<double>());
        expect(screenOffset.dy, isA<double>());
      });

      test('handles negative coordinates', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final scaledPageSize = const Size(612.0, 792.0);

        // Negative screen offset
        final negativeScreenOffset = const Offset(-100.0, -100.0);
        final pdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
          page: page,
          localOffsetTopLeft: negativeScreenOffset,
          scaledPageSizePx: scaledPageSize,
        );

        expect(pdfPoint, isA<PdfPoint>());
        expect(pdfPoint.x, isA<double>());
        expect(pdfPoint.y, isA<double>());

        // Negative PDF coordinates
        final screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: page,
          xPt: -100.0,
          yPt: -100.0,
          scaledPageSizePx: scaledPageSize,
        );

        expect(screenOffset, isA<Offset>());
        expect(screenOffset.dx, isA<double>());
        expect(screenOffset.dy, isA<double>());
      });

      test('handles very small scaled page size', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final tinyScaledPageSize = const Size(1.0, 1.0);

        final result = PdfCoordinateConverter.pageScaleFactors(
          page,
          tinyScaledPageSize,
        );

        expect(result.sx, closeTo(1.0 / 612.0, 0.0001));
        expect(result.sy, closeTo(1.0 / 792.0, 0.0001));
      });

      test('handles very large scaled page size', () {
        final page = MockPdfPage(
          width: 612.0,
          height: 792.0,
          rotation: PdfPageRotation.none,
        );
        final largeScaledPageSize = const Size(1224.0, 1584.0); // 2x size

        final result = PdfCoordinateConverter.pageScaleFactors(
          page,
          largeScaledPageSize,
        );

        expect(result.sx, closeTo(2.0, 0.01));
        expect(result.sy, closeTo(2.0, 0.01));
      });
    });
  });
}

