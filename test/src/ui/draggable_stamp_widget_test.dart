import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/controller/pdf_stamp_editor_controller.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';
import 'package:pdf_stamp_editor/src/ui/draggable_stamp_widget.dart';
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
    this.width = 612.0,
    this.height = 792.0,
    this.rotation = PdfPageRotation.none,
    this.pageNumber = 1,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
    PdfAnnotationRenderingMode annotationRenderingMode =
        PdfAnnotationRenderingMode.none,
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
  group('DraggableStampWidget', () {
    testWidgets('responds to pan gestures', (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: Stack(
                children: [
                  DraggableStampWidget(
                    stamp: stamp,
                    stampIndex: 0,
                    page: page,
                    scaledPageSizePx: const Size(612, 792),
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(find.byType(DraggableStampWidget), findsOneWidget);
    });

    testWidgets('drag updates stamp position in controller',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[0].centerYPt, 692.0);

      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();
      await gesture.moveBy(const Offset(50, -50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as TextStamp;
      expect(updatedStamp.centerXPt, isNot(100.0));
      expect(updatedStamp.centerYPt, isNot(692.0));
    });

    testWidgets('coordinate conversion during drag is accurate',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[0].centerYPt, 692.0);

      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();
      await gesture.moveBy(const Offset(50, -50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as TextStamp;
      expect(updatedStamp.centerXPt, closeTo(150.0, 1.0));
      expect(updatedStamp.centerYPt, closeTo(742.0, 1.0));
    });

    testWidgets('drag works correctly on 90° rotated page',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 100.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage(
        rotation: PdfPageRotation.clockwise90,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 792,
              height: 612,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(792, 612),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[0].centerYPt, 100.0);

      final initialScreenPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page,
        xPt: 100.0,
        yPt: 100.0,
        scaledPageSizePx: const Size(792, 612),
      );

      final gesture = await tester.startGesture(initialScreenPos);
      await tester.pump();
      await gesture.moveBy(const Offset(50, -50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as TextStamp;
      expect(updatedStamp.centerXPt, isNot(100.0));
      expect(updatedStamp.centerYPt, isNot(100.0));
    });

    testWidgets('prevents dragging stamp outside page boundaries',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = TextStamp(
        pageIndex: 0,
        centerXPt: 50.0,
        centerYPt: 50.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 50.0);
      expect(controller.stamps[0].centerYPt, 50.0);

      final initialScreenPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page,
        xPt: 50.0,
        yPt: 50.0,
        scaledPageSizePx: const Size(612, 792),
      );

      final gesture = await tester.startGesture(initialScreenPos);
      await tester.pump();
      await gesture.moveBy(const Offset(-1000, -1000));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as TextStamp;
      expect(updatedStamp.centerXPt, greaterThanOrEqualTo(0.0));
      expect(updatedStamp.centerYPt, greaterThanOrEqualTo(0.0));
      expect(updatedStamp.centerXPt, lessThanOrEqualTo(612.0));
      expect(updatedStamp.centerYPt, lessThanOrEqualTo(792.0));
    });

    testWidgets('drag only affects stamps on current page',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stampPage0 = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Page0',
        fontSizePt: 12.0,
      );
      final stampPage1 = TextStamp(
        pageIndex: 1,
        centerXPt: 200.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Page1',
        fontSizePt: 12.0,
      );
      controller.addStamp(stampPage0);
      controller.addStamp(stampPage1);
      final page = MockPdfPage(pageNumber: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final pageStamps = controller.stamps
                      .where((s) => s.pageIndex == page.pageNumber - 1)
                      .toList();
                  if (pageStamps.isEmpty) {
                    return const SizedBox();
                  }
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: pageStamps[0],
                        stampIndex: controller.stamps.indexOf(pageStamps[0]),
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[1].centerXPt, 200.0);

      final initialScreenPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page,
        xPt: 200.0,
        yPt: 692.0,
        scaledPageSizePx: const Size(612, 792),
      );

      final gesture = await tester.startGesture(initialScreenPos);
      await tester.pump();
      await gesture.moveBy(const Offset(50, -50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[0].centerYPt, 692.0);
      final updatedStampPage1 = controller.stamps[1] as TextStamp;
      expect(updatedStampPage1.centerXPt, isNot(200.0));
    });

    testWidgets('dragging one stamp does not affect other stamps',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp1 = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Stamp1',
        fontSizePt: 12.0,
      );
      final stamp2 = TextStamp(
        pageIndex: 0,
        centerXPt: 300.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Stamp2',
        fontSizePt: 12.0,
      );
      controller.addStamp(stamp1);
      controller.addStamp(stamp2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: controller.stamps[0],
                        stampIndex: 0,
                        page: MockPdfPage(),
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                      DraggableStampWidget(
                        stamp: controller.stamps[1],
                        stampIndex: 1,
                        page: MockPdfPage(),
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[1].centerXPt, 300.0);

      final initialScreenPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: MockPdfPage(),
        xPt: 100.0,
        yPt: 692.0,
        scaledPageSizePx: const Size(612, 792),
      );

      final gesture = await tester.startGesture(initialScreenPos);
      await tester.pump();
      await gesture.moveBy(const Offset(50, -50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final updatedStamp1 = controller.stamps[0] as TextStamp;
      expect(updatedStamp1.centerXPt, isNot(100.0));
      final unchangedStamp2 = controller.stamps[1] as TextStamp;
      expect(unchangedStamp2.centerXPt, 300.0);
      expect(unchangedStamp2.centerYPt, 692.0);
    });

    testWidgets('cancelled drag restores original position',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      bool showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (!showWidget || controller.stamps.isEmpty) {
                    return const SizedBox();
                  }
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps[0].centerXPt, 100.0);
      expect(controller.stamps[0].centerYPt, 692.0);

      final initialScreenPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page,
        xPt: 100.0,
        yPt: 692.0,
        scaledPageSizePx: const Size(612, 792),
      );

      final gesture = await tester.startGesture(initialScreenPos);
      await tester.pump();
      await gesture.moveBy(const Offset(50, -50));
      await tester.pump();

      final updatedDuringDrag = controller.stamps[0] as TextStamp;
      expect(updatedDuringDrag.centerXPt, isNot(100.0));

      showWidget = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (!showWidget || controller.stamps.isEmpty) {
                    return const SizedBox();
                  }
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await gesture.up();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final restoredStamp = controller.stamps[0] as TextStamp;
      expect(restoredStamp.centerXPt, 100.0);
      expect(restoredStamp.centerYPt, 692.0);
    });

    testWidgets('responds to scale gestures', (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      expect(finder, findsOneWidget);

      final center = tester.getCenter(finder);
      final gesture1 = await tester.startGesture(center - const Offset(20, 0));
      final gesture2 = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-10, 0));
      await gesture2.moveBy(const Offset(10, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.widthPt, isNot(100.0));
    });

    testWidgets('resize updates stamp dimensions in PDF points',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final gesture1 = await tester.startGesture(center - const Offset(25, 0));
      final gesture2 = await tester.startGesture(center + const Offset(25, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-20, 0));
      await gesture2.moveBy(const Offset(20, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.widthPt, greaterThan(100.0));
      expect(updatedStamp.heightPt, greaterThan(50.0));
      expect(updatedStamp.centerXPt, 306.0);
      expect(updatedStamp.centerYPt, 396.0);
    });

    testWidgets('resize preserves aspect ratio when enabled',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      const initialAspectRatio = 100.0 / 50.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final gesture1 = await tester.startGesture(center - const Offset(25, 0));
      final gesture2 = await tester.startGesture(center + const Offset(25, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-15, -10));
      await gesture2.moveBy(const Offset(15, 10));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      final newAspectRatio = updatedStamp.widthPt / updatedStamp.heightPt;
      expect(newAspectRatio, closeTo(initialAspectRatio, 0.01));
    });

    testWidgets('resize enforces minimum size constraints',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      const minWidthPt = 20.0;
      const minHeightPt = 10.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        minWidthPt: minWidthPt,
                        minHeightPt: minHeightPt,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final gesture1 = await tester.startGesture(center - const Offset(25, 0));
      final gesture2 = await tester.startGesture(center + const Offset(25, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(50, 0));
      await gesture2.moveBy(const Offset(-50, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.widthPt, greaterThanOrEqualTo(minWidthPt));
      expect(updatedStamp.heightPt, greaterThanOrEqualTo(minHeightPt));
    });

    testWidgets('resize works correctly with rotated stamps',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 45.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final gesture1 = await tester.startGesture(center - const Offset(25, 0));
      final gesture2 = await tester.startGesture(center + const Offset(25, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-20, 0));
      await gesture2.moveBy(const Offset(20, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.rotationDeg, 45.0);
      expect(updatedStamp.widthPt, greaterThan(100.0));
      expect(updatedStamp.heightPt, greaterThan(50.0));
      expect(updatedStamp.centerXPt, 306.0);
      expect(updatedStamp.centerYPt, 396.0);
    });

    testWidgets('resize coordinate conversion is accurate',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(initialStamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final initialWidth = (controller.stamps[0] as ImageStamp).widthPt;
      final initialHeight = (controller.stamps[0] as ImageStamp).heightPt;

      final gesture1 = await tester.startGesture(center - const Offset(25, 0));
      final gesture2 = await tester.startGesture(center + const Offset(25, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-20, 0));
      await gesture2.moveBy(const Offset(20, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;

      final widthScaleFactor = updatedStamp.widthPt / initialWidth;
      final heightScaleFactor = updatedStamp.heightPt / initialHeight;

      expect(widthScaleFactor, closeTo(heightScaleFactor, 0.01));
      expect(updatedStamp.widthPt, greaterThan(initialWidth));
      expect(updatedStamp.heightPt, greaterThan(initialHeight));
    });

    testWidgets('responds to rotation gestures', (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final initialRotation = (controller.stamps[0] as ImageStamp).rotationDeg;

      final gesture1 = await tester.startGesture(center + const Offset(30, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-30, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.rotationDeg, isNot(initialRotation));
    });

    testWidgets('rotation updates stamp angle correctly',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final initialRotation = (controller.stamps[0] as ImageStamp).rotationDeg;

      final gesture1 = await tester.startGesture(center + const Offset(30, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-30, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.rotationDeg, isNot(initialRotation));
      expect(updatedStamp.rotationDeg, isA<double>());
      expect(updatedStamp.rotationDeg, greaterThanOrEqualTo(0.0));
      expect(updatedStamp.rotationDeg, lessThan(360.0));
    });

    testWidgets('rotation occurs around center point',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final initialCenterX = (controller.stamps[0] as ImageStamp).centerXPt;
      final initialCenterY = (controller.stamps[0] as ImageStamp).centerYPt;

      final gesture1 = await tester.startGesture(center + const Offset(30, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-30, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.centerXPt, initialCenterX);
      expect(updatedStamp.centerYPt, initialCenterY);
      expect(updatedStamp.rotationDeg, isNot(0.0));
    });

    testWidgets('rotation angle is normalized to 0-360 range',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 350.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final gesture1 = await tester.startGesture(center + const Offset(30, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-30, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.rotationDeg, greaterThanOrEqualTo(0.0));
      expect(updatedStamp.rotationDeg, lessThan(360.0));
    });

    testWidgets('rotation works with resized stamps',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 150.0,
        heightPt: 50.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final initialCenterX = (controller.stamps[0] as ImageStamp).centerXPt;
      final initialCenterY = (controller.stamps[0] as ImageStamp).centerYPt;
      final initialWidth = (controller.stamps[0] as ImageStamp).widthPt;
      final initialHeight = (controller.stamps[0] as ImageStamp).heightPt;

      final gesture1 = await tester.startGesture(center + const Offset(40, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-40, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.rotationDeg, isNot(0.0));
      expect(updatedStamp.centerXPt, initialCenterX);
      expect(updatedStamp.centerYPt, initialCenterY);
      expect(updatedStamp.widthPt, initialWidth);
      expect(updatedStamp.heightPt, initialHeight);
    });

    testWidgets('rotation snaps to increments when enabled',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        rotationSnapDegrees: 45.0,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);

      final gesture1 = await tester.startGesture(center + const Offset(30, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-30, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedStamp = controller.stamps[0] as ImageStamp;
      expect(updatedStamp.rotationDeg % 45.0, closeTo(0.0, 0.1));
    });

    testWidgets('tap selects stamp', (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(stamp);

      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.isSelected(0), isFalse);

      final finder = find.byType(DraggableStampWidget);
      final center = tester.getCenter(finder);
      await tester.tapAt(center);
      await tester.pump();

      expect(controller.isSelected(0), isTrue);
    });

    testWidgets('selected stamp shows visual indicator',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.isSelected(0), isFalse);
      expect(find.byType(Container), findsNothing);

      controller.selectStamp(0);
      await tester.pump();

      expect(controller.isSelected(0), isTrue);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('multiple stamps can be selected', (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp1 = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      final stamp2 = ImageStamp(
        pageIndex: 0,
        centerXPt: 300.0,
        centerYPt: 400.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 50.0,
      );
      controller.addStamp(stamp1);
      controller.addStamp(stamp2);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return Stack(
                    children: [
                      for (var i = 0; i < controller.stamps.length; i++)
                        DraggableStampWidget(
                          stamp: controller.stamps[i],
                          stampIndex: i,
                          page: page,
                          scaledPageSizePx: const Size(612, 792),
                          controller: controller,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.selectedIndices, isEmpty);

      final finders = find.byType(DraggableStampWidget);
      expect(finders, findsNWidgets(2));

      await tester.tapAt(tester.getCenter(finders.at(0)));
      await tester.pump();

      expect(controller.isSelected(0), isTrue);
      expect(controller.selectedIndices.length, 1);

      await tester.tapAt(tester.getCenter(finders.at(1)));
      await tester.pump();

      expect(controller.isSelected(0), isTrue);
      expect(controller.isSelected(1), isTrue);
      expect(controller.selectedIndices.length, 2);
    });

    testWidgets('enableResize=false prevents resize gestures',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final initialWidth = (controller.stamps[0] as ImageStamp).widthPt;
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        enableResize: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      expect(finder, findsOneWidget);

      final center = tester.getCenter(finder);
      final gesture1 = await tester.startGesture(center - const Offset(20, 0));
      final gesture2 = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-10, 0));
      await gesture2.moveBy(const Offset(10, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedWidth = (controller.stamps[0] as ImageStamp).widthPt;
      expect(updatedWidth, equals(initialWidth));
    });

    testWidgets('enableRotate=false prevents rotation gestures',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final initialRotation = (controller.stamps[0] as ImageStamp).rotationDeg;
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        enableRotate: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      expect(finder, findsOneWidget);

      final center = tester.getCenter(finder);
      final gesture1 = await tester.startGesture(center + const Offset(30, 0));
      final gesture2 = await tester.startGesture(center + const Offset(-30, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(0, -20));
      await gesture2.moveBy(const Offset(0, 20));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      final updatedRotation = (controller.stamps[0] as ImageStamp).rotationDeg;
      expect(updatedRotation, equals(initialRotation));
    });

    testWidgets('enableSelection=false prevents tap selection',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        enableSelection: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.isSelected(0), isFalse);

      final finder = find.byType(DraggableStampWidget);
      expect(finder, findsOneWidget);

      final center = tester.getCenter(finder);
      await tester.tapAt(center);
      await tester.pump();

      expect(controller.isSelected(0), isFalse);
      expect(controller.selectedIndices, isEmpty);
    });

    testWidgets('onStampSelected callback is called when stamp is tapped',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      int? selectedIndex;
      PdfStamp? selectedStamp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        onStampSelected: (index, stamp) {
                          selectedIndex = index;
                          selectedStamp = stamp;
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      expect(finder, findsOneWidget);

      final center = tester.getCenter(finder);
      await tester.tapAt(center);
      await tester.pump();

      expect(selectedIndex, equals(0));
      expect(selectedStamp, equals(stamp));
    });

    testWidgets('onStampUpdated callback is called when stamp is updated',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        widthPt: 100.0,
        heightPt: 100.0,
      );
      controller.addStamp(stamp);
      final page = MockPdfPage();

      int? updatedIndex;
      PdfStamp? updatedStamp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final currentStamp = controller.stamps[0];
                  return Stack(
                    children: [
                      DraggableStampWidget(
                        stamp: currentStamp,
                        stampIndex: 0,
                        page: page,
                        scaledPageSizePx: const Size(612, 792),
                        controller: controller,
                        enableResize: true,
                        onStampUpdated: (index, stamp) {
                          updatedIndex = index;
                          updatedStamp = stamp;
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final finder = find.byType(DraggableStampWidget);
      expect(finder, findsOneWidget);

      final center = tester.getCenter(finder);
      final gesture1 = await tester.startGesture(center - const Offset(20, 0));
      final gesture2 = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();

      await gesture1.moveBy(const Offset(-10, 0));
      await gesture2.moveBy(const Offset(10, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();
      await tester.pump();

      expect(updatedIndex, equals(0));
      expect(updatedStamp, isNotNull);
      expect((updatedStamp! as ImageStamp).widthPt, isNot(100.0));

      await gesture1.up();
      await gesture2.up();
      await tester.pump();
    });
  });
}
