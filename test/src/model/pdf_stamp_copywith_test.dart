import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';

void main() {
  group('ImageStamp.copyWith', () {
    test('creates new instance with updated values', () {
      final original = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );

      final updated = original.copyWith(
        centerXPt: 150.0,
        centerYPt: 250.0,
      );

      expect(updated, isNot(same(original)));
      expect(updated.centerXPt, 150.0);
      expect(updated.centerYPt, 250.0);
      expect(updated.rotationDeg, 0.0);
      expect(updated.widthPt, 50.0);
      expect(updated.heightPt, 30.0);
    });

    test('preserves original values when not specified', () {
      final original = ImageStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 45.0,
        pngBytes: Uint8List.fromList([1, 2, 3]),
        widthPt: 50.0,
        heightPt: 30.0,
      );

      final updated = original.copyWith(centerXPt: 150.0);

      expect(updated.centerXPt, 150.0);
      expect(updated.centerYPt, 200.0);
      expect(updated.rotationDeg, 45.0);
      expect(updated.widthPt, 50.0);
      expect(updated.heightPt, 30.0);
    });
  });

  group('TextStamp.copyWith', () {
    test('creates new instance with updated values', () {
      final original = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 0.0,
        text: 'Original',
        fontSizePt: 12.0,
        color: Colors.red,
      );

      final updated = original.copyWith(
        centerXPt: 150.0,
        text: 'Updated',
        fontSizePt: 16.0,
      );

      expect(updated, isNot(same(original)));
      expect(updated.centerXPt, 150.0);
      expect(updated.text, 'Updated');
      expect(updated.fontSizePt, 16.0);
      expect(updated.centerYPt, 200.0);
      expect(updated.rotationDeg, 0.0);
    });

    test('preserves original values when not specified', () {
      final original = TextStamp(
        pageIndex: 0,
        centerXPt: 100.0,
        centerYPt: 200.0,
        rotationDeg: 90.0,
        text: 'Original',
        fontSizePt: 12.0,
        color: Colors.red,
      );

      final updated = original.copyWith(text: 'Updated');

      expect(updated.text, 'Updated');
      expect(updated.centerXPt, 100.0);
      expect(updated.centerYPt, 200.0);
      expect(updated.rotationDeg, 90.0);
      expect(updated.fontSizePt, 12.0);
    });
  });
}

