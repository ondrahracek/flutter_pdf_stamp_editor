import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';

void main() {
  group('PdfStamp', () {
    group('ImageStamp', () {
      test('creates image stamp with all properties', () {
        final pngBytes = Uint8List.fromList([1, 2, 3, 4]);
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 100.0,
          centerYPt: 200.0,
          rotationDeg: 45.0,
          pngBytes: pngBytes,
          widthPt: 50.0,
          heightPt: 75.0,
        );

        expect(stamp.pageIndex, 0);
        expect(stamp.centerXPt, 100.0);
        expect(stamp.centerYPt, 200.0);
        expect(stamp.rotationDeg, 45.0);
        expect(stamp.pngBytes, pngBytes);
        expect(stamp.widthPt, 50.0);
        expect(stamp.heightPt, 75.0);
        expect(stamp, isA<PdfStamp>());
      });

      test('allows zero dimensions', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 0,
          heightPt: 0,
        );

        expect(stamp.widthPt, 0);
        expect(stamp.heightPt, 0);
      });

      test('allows negative coordinates', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: -10,
          centerYPt: -20,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 10,
          heightPt: 10,
        );

        expect(stamp.centerXPt, -10);
        expect(stamp.centerYPt, -20);
      });

      test('supports multiple pages', () {
        final stamp = ImageStamp(
          pageIndex: 4,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 10,
          heightPt: 10,
        );

        expect(stamp.pageIndex, 4);
      });

      test('supports rotation in degrees', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 90.0,
          pngBytes: Uint8List(0),
          widthPt: 10,
          heightPt: 10,
        );

        expect(stamp.rotationDeg, 90.0);
      });
    });

    group('TextStamp', () {
      test('creates text stamp with all properties', () {
        final stamp = TextStamp(
          pageIndex: 1,
          centerXPt: 150.0,
          centerYPt: 250.0,
          rotationDeg: 30.0,
          text: 'Hello World',
          fontSizePt: 12.0,
          color: Colors.red,
        );

        expect(stamp.pageIndex, 1);
        expect(stamp.centerXPt, 150.0);
        expect(stamp.centerYPt, 250.0);
        expect(stamp.rotationDeg, 30.0);
        expect(stamp.text, 'Hello World');
        expect(stamp.fontSizePt, 12.0);
        expect(stamp, isA<PdfStamp>());
      });

      test('allows empty text', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          text: '',
          fontSizePt: 12,
          color: Colors.red,
        );

        expect(stamp.text, '');
      });

      test('allows zero fontSize', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          text: 'Test',
          fontSizePt: 0,
          color: Colors.red,
        );

        expect(stamp.fontSizePt, 0);
      });

      test('supports rotation in degrees', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: -45.0,
          text: 'Test',
          fontSizePt: 12,
          color: Colors.red,
        );

        expect(stamp.rotationDeg, -45.0);
      });

      test('creates text stamp with color property', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          text: 'Test',
          fontSizePt: 12,
          color: Colors.blue,
        );

        expect(stamp.color, Colors.blue);
      });
    });

    group('sealed class hierarchy', () {
      test('ImageStamp is a PdfStamp', () {
        final stamp = ImageStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          pngBytes: Uint8List(0),
          widthPt: 10,
          heightPt: 10,
        );

        expect(stamp, isA<PdfStamp>());
      });

      test('TextStamp is a PdfStamp', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 0,
          centerYPt: 0,
          rotationDeg: 0,
          text: 'Test',
          fontSizePt: 12,
          color: Colors.red,
        );

        expect(stamp, isA<PdfStamp>());
      });
    });
  });
}
