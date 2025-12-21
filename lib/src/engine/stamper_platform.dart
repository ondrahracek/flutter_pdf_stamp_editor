import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../model/pdf_stamp.dart';

/// Platform exporter that delegates to native code via MethodChannel.
///
/// Android: PdfBox-Android library for stamping implemented in native code.
/// iOS: PDFKit framework for stamping implemented in native code.
class PdfStampEditorExporter {
  static const MethodChannel _channel = MethodChannel('pdf_stamp_editor');

  static Future<Uint8List> applyStamps({
    required Uint8List inputPdfBytes,
    required List<PdfStamp> stamps,
  }) async {
    final payload = _encodePayloadV1(stamps);
    final out = await _channel.invokeMethod<Uint8List>(
      'stampPdf',
      {
        'pdf': inputPdfBytes,
        'payload': payload,
      },
    );
    if (out == null) {
      throw StateError('stampPdf returned null');
    }
    return out;
  }

  /// Binary payload (versioned) that native code can parse efficiently.
  static Uint8List _encodePayloadV1(List<PdfStamp> stamps) {
    final b = BytesBuilder(copy: false);
    void u8(int v) => b.add([v & 0xFF]);
    void u32(int v) {
      final d = ByteData(4)..setUint32(0, v, Endian.little);
      b.add(d.buffer.asUint8List());
    }
    void f64(double v) {
      final d = ByteData(8)..setFloat64(0, v, Endian.little);
      b.add(d.buffer.asUint8List());
    }

    // magic "PSTM"
    u32(0x4D545350);
    // version
    u32(1);
    // count
    u32(stamps.length);

    for (final s in stamps) {
      if (s is ImageStamp) {
        u8(1); // type
        u32(s.pageIndex);
        f64(s.centerXPt);
        f64(s.centerYPt);
        f64(s.widthPt);
        f64(s.heightPt);
        f64(s.rotationDeg);
        u32(s.pngBytes.length);
        b.add(s.pngBytes);
      } else if (s is TextStamp) {
        u8(2); // type
        u32(s.pageIndex);
        f64(s.centerXPt);
        f64(s.centerYPt);
        f64(0); // width placeholder
        f64(0); // height placeholder
        f64(s.rotationDeg);
        f64(s.fontSizePt);
        // ARGB red
        u32(0xFFFF0000);
        final utf8Bytes = utf8.encode(s.text);
        u32(utf8Bytes.length);
        b.add(utf8Bytes);
      } else {
        throw UnsupportedError('Unknown stamp type: $s');
      }
    }

    return b.takeBytes();
  }
}


