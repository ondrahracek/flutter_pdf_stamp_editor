import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Required if you may touch pdfrx engine / PdfDocument APIs early.
  pdfrxFlutterInitialize();

  runApp(const StampDemoApp());
}

class StampDemoApp extends StatelessWidget {
  const StampDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Stamp Demo',
      theme: ThemeData(useMaterial3: true),
      home: const StampDemoPage(),
    );
  }
}

class StampDemoPage extends StatefulWidget {
  const StampDemoPage({super.key});

  @override
  State<StampDemoPage> createState() => _StampDemoPageState();
}

class _StampDemoPageState extends State<StampDemoPage> {
  Uint8List? _pdfBytes;
  Uint8List? _pngBytes;
  List<PdfStamp> _stamps = [];
  bool _showViewer =
      true; // Controls viewer visibility to prevent concurrent PDFium calls

  // Simple "current stamp size"
  double _stampWidthPt = 140; // points (1/72 inch)
  double _stampRotationDeg = 0;

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final bytes = res.files.single.bytes;
    if (bytes == null) return;
    setState(() {
      _pdfBytes = bytes;
      _stamps.clear();
    });
  }

  Future<void> _pickPng() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;
    
    final bytes = await image.readAsBytes();
    setState(() => _pngBytes = bytes);
  }

  Future<void> _exportStampedPdf() async {
    final pdfBytes = _pdfBytes;
    if (pdfBytes == null) return;

    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isWindows &&
        !Platform.isMacOS &&
        !Platform.isLinux) {
      _snack('Export not supported on this platform (FFI/PDFium required).');
      return;
    }

    // 1) Pause viewer to prevent concurrent PDFium calls
    setState(() => _showViewer = false);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final outBytes = await PdfiumStamper.applyStamps(
        inputPdfBytes: pdfBytes,
        stamps: _stamps,
      );

      final dir = await getApplicationDocumentsDirectory();
      final outFile = File(
        '${dir.path}/stamped_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await outFile.writeAsBytes(outBytes);

      setState(() => _pdfBytes = outBytes); // reload viewer with stamped PDF
      _snack('Exported: ${outFile.path}');
    } catch (e) {
      _snack('Export failed: $e');
      rethrow;
    } finally {
      // 2) Resume viewer after stamping completes
      if (mounted) {
        setState(() => _showViewer = true);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Stamping (vector)'),
        actions: [
          IconButton(
            tooltip: 'Pick PDF',
            onPressed: _pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Pick PNG',
            onPressed: _pickPng,
            icon: const Icon(Icons.image),
          ),
          IconButton(
            tooltip: 'Export stamped PDF',
            onPressed: _pdfBytes == null ? null : _exportStampedPdf,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _pdfBytes == null
          ? const Center(
              child: Text('Pick a PDF (top bar) to begin.'),
            )
          : _showViewer
              ? Column(
                  children: [
                    _controls(),
                    const Divider(height: 1),
                    Expanded(
                      child: PdfStampEditorPage(
                        pdfBytes: _pdfBytes!,
                        pngBytes: _pngBytes,
                        stampWidthPt: _stampWidthPt,
                        stampRotationDeg: _stampRotationDeg,
                        onStampsChanged: (stamps) {
                          setState(() => _stamps = stamps);
                        },
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Exporting...'),
                    ],
                  ),
                ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Stamp width (pt)'),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: Slider(
                  min: 40,
                  max: 320,
                  value: _stampWidthPt,
                  onChanged: (v) => setState(() => _stampWidthPt = v),
                ),
              ),
              Text(_stampWidthPt.toStringAsFixed(0)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rotation (°)'),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: Slider(
                  min: -180,
                  max: 180,
                  value: _stampRotationDeg,
                  onChanged: (v) => setState(() => _stampRotationDeg = v),
                ),
              ),
              Text(_stampRotationDeg.toStringAsFixed(0)),
            ],
          ),
          TextButton.icon(
            onPressed: _stamps.isEmpty
                ? null
                : () {
                    setState(() => _stamps.clear());
                  },
            icon: const Icon(Icons.clear),
            label: const Text('Clear stamps'),
          ),
        ],
      ),
    );
  }
}
