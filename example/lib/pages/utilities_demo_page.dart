import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart'
    show
        PdfStampEditorPage,
        PdfStampEditorController,
        PdfCoordinateConverter;
import 'package:pdf_stamp_editor/src/engine/matrix_calculator.dart';

/// Demo page for coordinate converter and matrix calculator utilities.
class UtilitiesDemoPage extends StatefulWidget {
  const UtilitiesDemoPage({super.key});

  @override
  State<UtilitiesDemoPage> createState() => UtilitiesDemoPageState();
}

class UtilitiesDemoPageState extends State<UtilitiesDemoPage> {
  Uint8List? _pdfBytes;
  File? _tempPdfFile;
  Offset? _lastTapPosition;
  String? _lastPdfCoordinates;
  final TextEditingController _pdfXController = TextEditingController();
  final TextEditingController _pdfYController = TextEditingController();
  Offset? _convertedScreenPosition;
  PdfPage? _currentPage;
  Size? _currentPageSize;
  String? _scaleFactorsDisplay;
  String? _rotationDisplay;
  PdfStampEditorController? _controller;
  String? _matrixDisplay;

  @override
  void initState() {
    super.initState();
    _controller = PdfStampEditorController();
    _controller!.addListener(_onStampsChanged);
    if (!kIsWeb) {
      _createTempFile();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onStampsChanged);
    _controller?.dispose();
    _pdfXController.dispose();
    _pdfYController.dispose();
    super.dispose();
  }

  void _onStampsChanged() {
    final stamps = _controller!.stamps;
    if (stamps.isEmpty) {
      setState(() {
        _matrixDisplay = null;
      });
      return;
    }
    final lastStamp = stamps.last;
    final matrix = MatrixCalculator.calculateMatrix(lastStamp);
    setState(() {
      _matrixDisplay = 'a=${matrix.a.toStringAsFixed(2)}, b=${matrix.b.toStringAsFixed(2)}, c=${matrix.c.toStringAsFixed(2)}, d=${matrix.d.toStringAsFixed(2)}, e=${matrix.e.toStringAsFixed(2)}, f=${matrix.f.toStringAsFixed(2)}';
    });
  }

  Future<void> _createTempFile() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'utilities_demo.pdf'));
    _tempPdfFile = file;
  }

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
    });
    if (!kIsWeb && _tempPdfFile != null) {
      await _tempPdfFile!.writeAsBytes(bytes);
    }
  }

  void _handleTapDown(Offset offset, PdfPage page, Size pageSize) {
    final pdfPt = PdfCoordinateConverter.viewerOffsetToPdfPoint(
      page: page,
      localOffsetTopLeft: offset,
      scaledPageSizePx: pageSize,
    );
    final scaleFactors = PdfCoordinateConverter.pageScaleFactors(page, pageSize);
    final rotationDeg = PdfCoordinateConverter.rotationToDegrees(page.rotation);
    setState(() {
      _lastTapPosition = offset;
      _lastPdfCoordinates = '(${pdfPt.x.toStringAsFixed(2)}, ${pdfPt.y.toStringAsFixed(2)})';
      _currentPage = page;
      _currentPageSize = pageSize;
      _scaleFactorsDisplay = 'sx: ${scaleFactors.sx.toStringAsFixed(4)}, sy: ${scaleFactors.sy.toStringAsFixed(4)}';
      _rotationDisplay = '${page.rotation} → $rotationDeg°';
    });
  }

  void _convertPdfToScreen() {
    if (_currentPage == null || _currentPageSize == null) return;
    final xStr = _pdfXController.text.trim();
    final yStr = _pdfYController.text.trim();
    if (xStr.isEmpty || yStr.isEmpty) return;
    final x = double.tryParse(xStr);
    final y = double.tryParse(yStr);
    if (x == null || y == null) return;
    final screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
      page: _currentPage!,
      xPt: x,
      yPt: y,
      scaledPageSizePx: _currentPageSize!,
    );
    setState(() {
      _convertedScreenPosition = screenOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilities Demo'),
        actions: [
          IconButton(
            tooltip: 'Pick PDF',
            onPressed: _pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tap Position → PDF Coordinates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_lastTapPosition != null && _lastPdfCoordinates != null) ...[
                      Text('Screen: (${_lastTapPosition!.dx.toStringAsFixed(1)}, ${_lastTapPosition!.dy.toStringAsFixed(1)})'),
                      Text('PDF: $_lastPdfCoordinates'),
                    ] else
                      const Text('Tap on PDF to see coordinates'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PDF Coordinates → Screen Position',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('X (points):'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pdfXController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Y (points):'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pdfYController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _convertPdfToScreen,
                      child: const Text('Convert to Screen Position'),
                    ),
                    if (_convertedScreenPosition != null) ...[
                      const SizedBox(height: 8),
                      Text('Screen: (${_convertedScreenPosition!.dx.toStringAsFixed(1)}, ${_convertedScreenPosition!.dy.toStringAsFixed(1)})'),
                    ],
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Page Scale Factors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_scaleFactorsDisplay != null)
                      Text(_scaleFactorsDisplay!)
                    else
                      const Text('Tap on PDF to see scale factors'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Page Rotation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_rotationDisplay != null)
                      Text(_rotationDisplay!)
                    else
                      const Text('Tap on PDF to see rotation'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Transformation Matrix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_matrixDisplay != null)
                      Text(_matrixDisplay!)
                    else
                      const Text('Create stamps to see transformation matrix'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Test Scenarios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _testEdgeCoordinates,
                          child: const Text('Test Edge Coordinates'),
                        ),
                        ElevatedButton(
                          onPressed: _testRoundTrip,
                          child: const Text('Test Round-Trip'),
                        ),
                        ElevatedButton(
                          onPressed: _clearAll,
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_pdfBytes != null) ...[
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPdfViewer(),
                    ),
                    Expanded(
                      flex: 1,
                      child: PdfStampEditorPage(
                        pdfBytes: _pdfBytes!,
                        controller: _controller,
                      ),
                    ),
                  ],
                ),
              )
            ]
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Pick a PDF to see coordinate conversion'),
              ),
          ],
        ),
      ),
    );
  }

  void _testEdgeCoordinates() {
    if (_currentPage == null || _currentPageSize == null) return;
    final w = _currentPage!.width;
    final h = _currentPage!.height;
    _pdfXController.text = '0';
    _pdfYController.text = '0';
    _convertPdfToScreen();
    Future.delayed(const Duration(milliseconds: 100), () {
      _pdfXController.text = w.toStringAsFixed(0);
      _pdfYController.text = h.toStringAsFixed(0);
      _convertPdfToScreen();
    });
  }

  void _testRoundTrip() {
    if (_lastTapPosition == null || _currentPage == null || _currentPageSize == null) return;
    final pdfPt = PdfCoordinateConverter.viewerOffsetToPdfPoint(
      page: _currentPage!,
      localOffsetTopLeft: _lastTapPosition!,
      scaledPageSizePx: _currentPageSize!,
    );
    final backToScreen = PdfCoordinateConverter.pdfPointToViewerOffset(
      page: _currentPage!,
      xPt: pdfPt.x,
      yPt: pdfPt.y,
      scaledPageSizePx: _currentPageSize!,
    );
    final diff = (_lastTapPosition! - backToScreen).distance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Round-trip error: ${diff.toStringAsFixed(2)} pixels'),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _lastTapPosition = null;
      _lastPdfCoordinates = null;
      _convertedScreenPosition = null;
      _scaleFactorsDisplay = null;
      _rotationDisplay = null;
      _matrixDisplay = null;
      _pdfXController.clear();
      _pdfYController.clear();
      _controller?.clearStamps();
    });
  }

  Widget _buildPdfViewer() {
    if (_pdfBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb) {
      return PdfViewer.data(
        _pdfBytes!,
        sourceName: 'utilities_demo.pdf',
        params: PdfViewerParams(
          pageOverlaysBuilder: (context, pageRect, page) => [
            Positioned.fromRect(
              rect: pageRect,
              child: GestureDetector(
                onTapDown: (details) {
                  _handleTapDown(details.localPosition, page, pageRect.size);
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      );
    }

    if (_tempPdfFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PdfViewer.file(
      _tempPdfFile!.path,
      params: PdfViewerParams(
        pageOverlaysBuilder: (context, pageRect, page) => [
          Positioned.fromRect(
            rect: pageRect,
            child: GestureDetector(
              onTapDown: (details) {
                _handleTapDown(details.localPosition, page, pageRect.size);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

