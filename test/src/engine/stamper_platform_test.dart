import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/engine/stamper_platform.dart';
import 'package:pdf_stamp_editor/src/model/pdf_stamp.dart';

/// Extracts the ARGB color value from a serialized TextStamp payload.
///
/// Payload format: magic (4 bytes), version (4 bytes), count (4 bytes),
/// then for TextStamp: type (1 byte), pageIndex (4 bytes), cx (8 bytes), cy (8 bytes),
/// w (8 bytes), h (8 bytes), rot (8 bytes), fontSize (8 bytes), argb (4 bytes), textLen (4 bytes), text (variable)
int _extractColorFromPayload(Uint8List payload) {
  final reader = ByteData.sublistView(payload);
  var offset = 0;

  // Skip magic (4 bytes)
  offset += 4;
  // Skip version (4 bytes)
  offset += 4;
  // Skip count (4 bytes)
  offset += 4;

  // Read type (1 byte)
  final type = reader.getUint8(offset);
  expect(type, 2); // TextStamp type
  offset += 1;

  // Skip pageIndex (4 bytes)
  offset += 4;
  // Skip cx, cy, w, h, rot (each 8 bytes = 40 bytes)
  offset += 40;
  // Skip fontSize (8 bytes)
  offset += 8;

  // Read ARGB color (4 bytes, little-endian)
  return reader.getUint32(offset, Endian.little);
}

void main() {
  group('PdfStampEditorExporter', () {
    group('encodePayloadV1', () {
      test('serializes TextStamp color correctly for black', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 100.0,
          centerYPt: 200.0,
          rotationDeg: 0.0,
          text: 'Test',
          fontSizePt: 12.0,
          color: Colors.black,
        );

        final payload = PdfStampEditorExporter.encodePayloadV1([stamp]);
        final argb = _extractColorFromPayload(payload);
        expect(argb, Colors.black.value);
      });

      test('serializes TextStamp color correctly for blue', () {
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 100.0,
          centerYPt: 200.0,
          rotationDeg: 0.0,
          text: 'Test',
          fontSizePt: 12.0,
          color: Colors.blue,
        );

        final payload = PdfStampEditorExporter.encodePayloadV1([stamp]);
        final argb = _extractColorFromPayload(payload);
        expect(argb, Colors.blue.value);
      });

      test('serializes TextStamp color correctly for custom color', () {
        final customColor = const Color(0xFF123456);
        final stamp = TextStamp(
          pageIndex: 0,
          centerXPt: 100.0,
          centerYPt: 200.0,
          rotationDeg: 0.0,
          text: 'Test',
          fontSizePt: 12.0,
          color: customColor,
        );

        final payload = PdfStampEditorExporter.encodePayloadV1([stamp]);
        final argb = _extractColorFromPayload(payload);
        expect(argb, customColor.value);
      });
    });
  });
}
