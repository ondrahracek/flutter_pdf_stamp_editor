import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/controller/pdf_stamp_editor_controller.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';

void main() {
  group('PdfStampEditorController', () {
    test('initializes with empty stamp list', () {
      final controller = PdfStampEditorController();

      expect(controller.stamps, isEmpty);
    });

    test('initializes with pre-populated stamp list', () {
      final initialStamps = [
        TextStamp(
          pageIndex: 0,
          centerXPt: 100.0,
          centerYPt: 200.0,
          rotationDeg: 0.0,
          text: 'Test',
          fontSizePt: 12.0,
        ),
      ];
      final controller = PdfStampEditorController(initialStamps: initialStamps);

      expect(controller.stamps, hasLength(1));
      expect(controller.stamps[0], isA<TextStamp>());
    });
  });

  group('addStamp', () {
    test('adds ImageStamp to controller', () {
      final controller = PdfStampEditorController();
      final imageStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );

      controller.addStamp(imageStamp);

      expect(controller.stamps, hasLength(1));
      expect(controller.stamps[0], isA<ImageStamp>());
    });

    test('adds TextStamp to controller', () {
      final controller = PdfStampEditorController();
      final textStamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );

      controller.addStamp(textStamp);

      expect(controller.stamps, hasLength(1));
      expect(controller.stamps[0], isA<TextStamp>());
    });
  });

  group('updateStamp', () {
    test('updates stamp position', () {
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );
      final controller =
          PdfStampEditorController(initialStamps: [initialStamp]);

      final updatedStamp = initialStamp.copyWith(
        centerXPt: 150.0,
        centerYPt: 250.0,
      );
      controller.updateStamp(0, updatedStamp);

      expect(controller.stamps, hasLength(1));
      final stamp = controller.stamps[0] as ImageStamp;
      expect(stamp.centerXPt, 150.0);
      expect(stamp.centerYPt, 250.0);
    });

    test('updates stamp size', () {
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );
      final controller =
          PdfStampEditorController(initialStamps: [initialStamp]);

      final updatedStamp = initialStamp.copyWith(
        widthPt: 100.0,
        heightPt: 60.0,
      );
      controller.updateStamp(0, updatedStamp);

      final stamp = controller.stamps[0] as ImageStamp;
      expect(stamp.widthPt, 100.0);
      expect(stamp.heightPt, 60.0);
    });

    test('updates stamp rotation', () {
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );
      final controller =
          PdfStampEditorController(initialStamps: [initialStamp]);

      final updatedStamp = initialStamp.copyWith(rotationDeg: 90.0);
      controller.updateStamp(0, updatedStamp);

      final stamp = controller.stamps[0] as ImageStamp;
      expect(stamp.rotationDeg, 90.0);
    });
  });

  group('removeStamp', () {
    test('removes stamp at index', () {
      final stamp1 = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Test1',
        fontSizePt: 12.0,
      );
      final stamp2 = TextStamp(
        pageIndex: 0,
        centerXPt: 200.0,
        centerYPt: 300.0,
        rotationDeg: 0.0,
        text: 'Test2',
        fontSizePt: 12.0,
      );
      final controller =
          PdfStampEditorController(initialStamps: [stamp1, stamp2]);

      controller.removeStamp(0);

      expect(controller.stamps, hasLength(1));
      expect(controller.stamps[0].centerXPt, 200.0);
    });
  });

  group('clearStamps', () {
    test('removes all stamps', () {
      final stamp1 = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Test1',
        fontSizePt: 12.0,
      );
      final stamp2 = ImageStamp(
        pageIndex: 0,
        centerXPt: 200.0,
        centerYPt: 300.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );
      final controller =
          PdfStampEditorController(initialStamps: [stamp1, stamp2]);

      controller.clearStamps();

      expect(controller.stamps, isEmpty);
    });
  });

  group('listeners', () {
    test('notifies listeners when stamp is added', () {
      final controller = PdfStampEditorController();
      var listenerCalled = false;
      controller.addListener(() {
        listenerCalled = true;
      });

      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      controller.addStamp(stamp);

      expect(listenerCalled, isTrue);
      controller.dispose();
    });

    test('notifies listeners when stamp is updated', () {
      final initialStamp = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );
      final controller =
          PdfStampEditorController(initialStamps: [initialStamp]);
      var listenerCalled = false;
      controller.addListener(() {
        listenerCalled = true;
      });

      final updatedStamp = initialStamp.copyWith(centerXPt: 150.0);
      controller.updateStamp(0, updatedStamp);

      expect(listenerCalled, isTrue);
      controller.dispose();
    });

    test('notifies listeners when stamp is removed', () {
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      final controller = PdfStampEditorController(initialStamps: [stamp]);
      var listenerCalled = false;
      controller.addListener(() {
        listenerCalled = true;
      });

      controller.removeStamp(0);

      expect(listenerCalled, isTrue);
      controller.dispose();
    });

    test('notifies listeners when stamps are cleared', () {
      final stamp = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Test',
        fontSizePt: 12.0,
      );
      final controller = PdfStampEditorController(initialStamps: [stamp]);
      var listenerCalled = false;
      controller.addListener(() {
        listenerCalled = true;
      });

      controller.clearStamps();

      expect(listenerCalled, isTrue);
      controller.dispose();
    });
  });
}
