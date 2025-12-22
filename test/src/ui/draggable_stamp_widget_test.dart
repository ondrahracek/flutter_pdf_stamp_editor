import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/controller/pdf_stamp_editor_controller.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';
import 'package:pdf_stamp_editor/src/ui/draggable_stamp_widget.dart';
import 'package:pdf_stamp_editor/src/ui/pdf_stamp_editor_page.dart';
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
        color: Colors.red,
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
        color: Colors.red,
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
        color: Colors.red,
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
      color: Colors.red,);
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
      color: Colors.red,);
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
        color: Colors.red,
      );
      final stampPage1 = TextStamp(
        pageIndex: 1,
        centerXPt: 200.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Page1',
        fontSizePt: 12.0,
        color: Colors.red,
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
        color: Colors.red,
      );
      final stamp2 = TextStamp(
        pageIndex: 0,
        centerXPt: 300.0,
        centerYPt: 692.0,
        rotationDeg: 0.0,
        text: 'Stamp2',
        fontSizePt: 12.0,
        color: Colors.red,
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
        color: Colors.red,
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

    testWidgets('selected stamp shows delete button when deleteButtonConfig is provided',
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
      const deleteButtonConfig = DeleteButtonConfig();

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
                        selectionConfig: const SelectionConfig(
                          deleteButtonConfig: deleteButtonConfig,
                        ),
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
      expect(find.byIcon(Icons.close), findsNothing);

      controller.selectStamp(0);
      await tester.pump();

      expect(controller.isSelected(0), isTrue);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping delete button removes the stamp',
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
      const deleteButtonConfig = DeleteButtonConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.stamps.isEmpty) {
                    return const SizedBox.shrink();
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
                        selectionConfig: const SelectionConfig(
                          deleteButtonConfig: deleteButtonConfig,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(controller.stamps.length, 1);
      controller.selectStamp(0);
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(controller.stamps.length, 0);
    });

    testWidgets('delete button is not shown when deleteButtonConfig is disabled',
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
                        selectionConfig: const SelectionConfig(
                          deleteButtonConfig: DeleteButtonConfig.disabled(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      controller.selectStamp(0);
      await tester.pump();

      expect(controller.isSelected(0), isTrue);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('delete button is positioned at top-right corner of stamp bounding box',
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
      const deleteButtonConfig = DeleteButtonConfig(
        offsetX: -8.0,
        offsetY: -8.0,
        hitAreaSize: 44.0,
      );

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
                        selectionConfig: const SelectionConfig(
                          deleteButtonConfig: deleteButtonConfig,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      controller.selectStamp(0);
      await tester.pump();

      // Calculate expected stamp bounding box
      final posPx = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page,
        xPt: 306.0,
        yPt: 396.0,
        scaledPageSizePx: const Size(612, 792),
      );
      final scale = PdfCoordinateConverter.pageScaleFactors(
        page,
        const Size(612, 792),
      );
      final wPx = 100.0 * scale.sx;
      final hPx = 50.0 * scale.sy;
      
      // Visual stamp content position (not expanded bounding box)
      final visualStampTop = posPx.dy - hPx / 2;
      final visualStampRight = posPx.dx + wPx / 2;

      // Find the delete button Positioned widget
      final buttonFinder = find.byIcon(Icons.close);
      expect(buttonFinder, findsOneWidget);
      
      final buttonWidget = tester.widget<Positioned>(
        find.ancestor(
          of: buttonFinder,
          matching: find.byType(Positioned),
        ).first,
      );

      // Expected button position: top-right corner of visual stamp content with offset
      final expectedButtonLeft = visualStampRight - deleteButtonConfig.hitAreaSize + deleteButtonConfig.offsetX;
      final expectedButtonTop = visualStampTop + deleteButtonConfig.offsetY;

      expect(buttonWidget.left, closeTo(expectedButtonLeft, 0.1));
      expect(buttonWidget.top, closeTo(expectedButtonTop, 0.1));
    });

    testWidgets('delete button is positioned relative to visual stamp content, not expanded bounding box',
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
      const deleteButtonConfig = DeleteButtonConfig(
        offsetX: -8.0,
        offsetY: -8.0, // Negative offset should move button up from visual content top
        hitAreaSize: 44.0,
      );

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
                        selectionConfig: const SelectionConfig(
                          deleteButtonConfig: deleteButtonConfig,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      controller.selectStamp(0);
      await tester.pump();

      // Calculate visual stamp content position (not expanded bounding box)
      final posPx = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page,
        xPt: 306.0,
        yPt: 396.0,
        scaledPageSizePx: const Size(612, 792),
      );
      final scale = PdfCoordinateConverter.pageScaleFactors(
        page,
        const Size(612, 792),
      );
      final wPx = 100.0 * scale.sx;
      final hPx = 50.0 * scale.sy;
      const hitAreaExpansion = 40.0;
      
      // Visual stamp content top (not expanded bounding box)
      final visualStampTop = posPx.dy - hPx / 2;
      final visualStampRight = posPx.dx + wPx / 2;

      // Find the delete button Positioned widget
      final buttonFinder = find.byIcon(Icons.close);
      expect(buttonFinder, findsOneWidget);
      
      final buttonWidget = tester.widget<Positioned>(
        find.ancestor(
          of: buttonFinder,
          matching: find.byType(Positioned),
        ).first,
      );

      // Expected button position: top-right corner of VISUAL stamp content with offset
      // Button's top-right should align with visual stamp's top-right, then offset applied
      final expectedButtonLeft = visualStampRight - deleteButtonConfig.hitAreaSize + deleteButtonConfig.offsetX;
      final expectedButtonTop = visualStampTop + deleteButtonConfig.offsetY;

      expect(buttonWidget.left, closeTo(expectedButtonLeft, 0.1));
      expect(buttonWidget.top, closeTo(expectedButtonTop, 0.1));
    });

    testWidgets('multiple stamps can be selected', (WidgetTester tester) async {
      final controller = PdfStampEditorController(enableMultiSelection: true);
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

    testWidgets('updates pageIndex when stamp is dragged to another page',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
        color: Colors.red,
      );
      controller.addStamp(stamp);
      final page0 = MockPdfPage(pageNumber: 1);
      final page1 = MockPdfPage(pageNumber: 2);

      // Simulate two pages stacked vertically
      // Page 0: y = 0 to 792
      // Page 1: y = 792 to 1584
      final page0Rect = Rect.fromLTWH(0, 0, 612, 792);
      final page1Rect = Rect.fromLTWH(0, 792, 612, 792);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 1584,
              child: Stack(
                children: [
                  DraggableStampWidget(
                    stamp: controller.stamps[0],
                    stampIndex: 0,
                    page: page0,
                    scaledPageSizePx: const Size(612, 792),
                    controller: controller,
                    pageRects: {
                      0: page0Rect,
                      1: page1Rect,
                    },
                    pages: {
                      0: page0,
                      1: page1,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Get initial position on page 0
      final initialPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page0,
        xPt: 306.0,
        yPt: 396.0,
        scaledPageSizePx: const Size(612, 792),
      );

      // Drag to position on page 1 (below page 0)
      final gesture = await tester.startGesture(initialPos);
      await tester.pump();
      // Move to page 1 - y position should be in page 1's rect
      await gesture.moveBy(const Offset(0, 850));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Verify pageIndex was updated to page 1
      final updatedStamp = controller.stamps[0];
      expect(updatedStamp.pageIndex, 1);
    });

    testWidgets('correctly calculates global coordinates when page rect is offset',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
        color: Colors.red,
      );
      controller.addStamp(stamp);
      final page0 = MockPdfPage(pageNumber: 1);
      final page1 = MockPdfPage(pageNumber: 2);

      // Simulate pages with non-zero offsets (like in a scrolled viewer)
      // Page 0: y = 100 to 892 (offset by 100)
      // Page 1: y = 892 to 1684
      final page0Rect = Rect.fromLTWH(0, 100, 612, 792);
      final page1Rect = Rect.fromLTWH(0, 892, 612, 792);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 1684,
              child: Stack(
                children: [
                  DraggableStampWidget(
                    stamp: controller.stamps[0],
                    stampIndex: 0,
                    page: page0,
                    scaledPageSizePx: const Size(612, 792),
                    controller: controller,
                    pageRects: {
                      0: page0Rect,
                      1: page1Rect,
                    },
                    pages: {
                      0: page0,
                      1: page1,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Get initial position relative to page overlay, then add page rect offset for global position
      // In the real implementation, the widget is inside a page overlay at pageRect.topLeft
      // So posPx is relative to the overlay, and we add pageRect.topLeft to get global
      final posPx = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page0,
        xPt: 306.0,
        yPt: 396.0,
        scaledPageSizePx: const Size(612, 792),
      );
      // In test, widget is directly in Stack, so we need to account for page rect offset
      final initialPos = page0Rect.topLeft + posPx;

      // Drag down to move to page 1
      // initialPos is relative to page overlay, so it's at (306, 396) relative to page0Rect.topLeft
      // Global position would be (306, 396 + 100) = (306, 496)
      // To get to page 1, we need to drag to y > 892
      // So we need to drag by at least 892 - 496 = 396 pixels
      final gesture = await tester.startGesture(initialPos);
      await tester.pump();
      await gesture.moveBy(const Offset(0, 500));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Verify pageIndex was updated to page 1
      final updatedStamp = controller.stamps[0];
      expect(updatedStamp.pageIndex, 1, reason: 'Stamp should move to page 1 when dragged past page boundary');
    });

    testWidgets('stamp remains visible and draggable when pageIndex changes during drag',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
        color: Colors.red,
      );
      controller.addStamp(stamp);
      final page0 = MockPdfPage(pageNumber: 1);
      final page1 = MockPdfPage(pageNumber: 2);

      final page0Rect = Rect.fromLTWH(0, 0, 612, 792);
      final page1Rect = Rect.fromLTWH(0, 792, 612, 792);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 1584,
              child: Stack(
                children: [
                  DraggableStampWidget(
                    stamp: controller.stamps[0],
                    stampIndex: 0,
                    page: page0,
                    scaledPageSizePx: const Size(612, 792),
                    controller: controller,
                    pageRects: {
                      0: page0Rect,
                      1: page1Rect,
                    },
                    pages: {
                      0: page0,
                      1: page1,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final initialPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page0,
        xPt: 306.0,
        yPt: 396.0,
        scaledPageSizePx: const Size(612, 792),
      );

      // Start drag
      final gesture = await tester.startGesture(initialPos);
      await tester.pump();
      
      // Move to page 1 boundary - this should trigger pageIndex change
      await gesture.moveBy(const Offset(0, 400));
      await tester.pump();
      
      // Verify dragging state is set
      expect(controller.draggingStampIndex, 0, reason: 'Controller should track dragging stamp');
      
      // Continue dragging on page 1
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      
      // Verify stamp position continues to update even after pageIndex changed
      final updatedStamp = controller.stamps[0];
      expect(updatedStamp.pageIndex, 1, reason: 'Stamp should be on page 1');
      expect(updatedStamp.centerYPt, greaterThan(396.0), reason: 'Stamp position should continue updating during drag');
      
      await gesture.up();
      await tester.pump();
      
      // Verify dragging state is cleared
      expect(controller.draggingStampIndex, isNull, reason: 'Dragging state should be cleared after drag ends');
    });

    testWidgets('uses correct page for coordinate conversion after page change during drag',
        (WidgetTester tester) async {
      final controller = PdfStampEditorController();
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 306.0,
        centerYPt: 396.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
        color: Colors.red,
      );
      controller.addStamp(stamp);
      final page0 = MockPdfPage(pageNumber: 1);
      final page1 = MockPdfPage(pageNumber: 2);

      final page0Rect = Rect.fromLTWH(0, 0, 612, 792);
      final page1Rect = Rect.fromLTWH(0, 792, 612, 792);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 1584,
              child: Stack(
                children: [
                  DraggableStampWidget(
                    stamp: controller.stamps[0],
                    stampIndex: 0,
                    page: page0,
                    scaledPageSizePx: const Size(612, 792),
                    controller: controller,
                    pageRects: {
                      0: page0Rect,
                      1: page1Rect,
                    },
                    pages: {
                      0: page0,
                      1: page1,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final initialPos = PdfCoordinateConverter.pdfPointToViewerOffset(
        page: page0,
        xPt: 306.0,
        yPt: 396.0,
        scaledPageSizePx: const Size(612, 792),
      );

      // Start drag
      final gesture = await tester.startGesture(initialPos);
      await tester.pump();
      
      // Move to page 1 - this should trigger pageIndex change
      await gesture.moveBy(const Offset(0, 400));
      await tester.pump();
      
      // Verify pageIndex was updated
      expect(controller.stamps[0].pageIndex, 1, reason: 'Stamp should be on page 1');
      
      // Continue dragging on page 1 - coordinates should be positive (not negative)
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      
      // Verify coordinates are valid (positive Y on page 1)
      final updatedStamp = controller.stamps[0];
      expect(updatedStamp.pageIndex, 1, reason: 'Stamp should still be on page 1');
      expect(updatedStamp.centerYPt, greaterThan(0), reason: 'Y coordinate should be positive after moving on page 1');
      expect(updatedStamp.centerYPt, lessThan(792), reason: 'Y coordinate should be within page 1 bounds');
      
      await gesture.up();
      await tester.pump();
    });
  });
}
