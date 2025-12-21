import 'dart:typed_data';
import '../model/pdf_stamp.dart';

class PdfStampEditorExporter {
  static Future<Uint8List> applyStamps({
    required Uint8List inputPdfBytes,
    required List<PdfStamp> stamps,
  }) async {
    throw UnsupportedError('PDF export is not supported on Web (requires dart:ffi).');
  }
}
