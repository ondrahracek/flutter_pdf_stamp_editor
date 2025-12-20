import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

/// Demo page for custom stamp builder functionality.
class CustomBuilderDemoPage extends StatefulWidget {
  const CustomBuilderDemoPage({super.key});

  @override
  State<CustomBuilderDemoPage> createState() => CustomBuilderDemoPageState();
}

enum CustomStyle { bordered, shadowed, highlighted }

class CustomBuilderDemoPageState extends State<CustomBuilderDemoPage> {
  Uint8List? _pdfBytes;
  Uint8List? _pngBytes;
  bool _showViewer = true;
  bool _useCustomBuilder = false;
  CustomStyle _selectedStyle = CustomStyle.bordered;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Builder Demo'),
        actions: [
          IconButton(
            tooltip: 'Pick PNG',
            onPressed: _pickPng,
            icon: const Icon(Icons.image),
          ),
          IconButton(
            tooltip: 'Pick PDF',
            onPressed: _pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Use Custom Builder'),
                              const Spacer(),
                              Switch(
                                value: _useCustomBuilder,
                                onChanged: (value) {
                                  setState(() {
                                    _useCustomBuilder = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_useCustomBuilder) ...[
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Text('Style'),
                                Spacer(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<CustomStyle>(
                              segments: const [
                                ButtonSegment(
                                  value: CustomStyle.bordered,
                                  label: Text('Bordered'),
                                ),
                                ButtonSegment(
                                  value: CustomStyle.shadowed,
                                  label: Text('Shadowed'),
                                ),
                                ButtonSegment(
                                  value: CustomStyle.highlighted,
                                  label: Text('Highlighted'),
                                ),
                              ],
                              selected: {_selectedStyle},
                              onSelectionChanged: (Set<CustomStyle> newSelection) {
                                setState(() {
                                  _selectedStyle = newSelection.first;
                                });
                              },
                            ),
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
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Pick a PDF file to load it in the viewer.\n'
                            '2. Pick a PNG image for image stamps (optional).\n'
                            '3. Toggle "Use Custom Builder" to enable custom styling.\n'
                            '4. Select a style: Bordered, Shadowed, or Highlighted.\n'
                            '5. Tap on the PDF to place image stamps (if PNG is loaded).\n'
                            '6. Long press on the PDF to place text stamps.\n'
                            '7. Toggle between default and custom builder to see the difference.\n\n'
                            'Custom builder allows you to customize how stamps are rendered, '
                            'including borders, shadows, colors, and other styling effects.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_pdfBytes != null && _showViewer)
            Expanded(
              child: PdfStampEditorPage(
                pdfBytes: _pdfBytes!,
                pngBytes: _pngBytes,
                stampBuilder: _useCustomBuilder ? (context, stamp, page, size, pos) => _buildCustomStamp(context, stamp, page, size, pos, _selectedStyle) : null,
                onImageStampPlaced: () {
                  setState(() => _pngBytes = null);
                },
              ),
            )
          else if (_pdfBytes == null)
            Expanded(
              child: const Center(
                child: Text('Pick a PDF to see custom builder in action'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomStamp(
    BuildContext context,
    PdfStamp stamp,
    PdfPage page,
    Size scaledPageSizePx,
    Offset position,
    CustomStyle style,
  ) {
    if (stamp case ImageStamp s) {
      final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
      final wPx = s.widthPt * scale.sx;
      final hPx = s.heightPt * scale.sy;

      Widget imageWidget = Image.memory(s.pngBytes, fit: BoxFit.fill);

      BoxDecoration decoration;
      switch (style) {
        case CustomStyle.bordered:
          decoration = BoxDecoration(
            border: Border.all(color: Colors.blue, width: 3),
            borderRadius: BorderRadius.circular(8),
          );
          break;
        case CustomStyle.shadowed:
          decoration = BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(5, 5),
              ),
            ],
          );
          break;
        case CustomStyle.highlighted:
          decoration = BoxDecoration(
            border: Border.all(color: Colors.green, width: 4),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          );
          break;
      }

      return Positioned(
        left: position.dx - wPx / 2,
        top: position.dy - hPx / 2,
        width: wPx,
        height: hPx,
        child: Transform.rotate(
          angle: s.rotationDeg * 3.141592653589793 / 180,
          child: Container(
            decoration: decoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: imageWidget,
            ),
          ),
        ),
      );
    }

    if (stamp case TextStamp s) {
      final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
      final fontPx = s.fontSizePt * scale.sy;

      BoxDecoration decoration;
      TextStyle textStyle;
      switch (style) {
        case CustomStyle.bordered:
          decoration = BoxDecoration(
            color: Colors.yellow.withOpacity(0.8),
            border: Border.all(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(4),
          );
          textStyle = TextStyle(
            fontSize: fontPx,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          );
          break;
        case CustomStyle.shadowed:
          decoration = BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(3, 3),
              ),
            ],
          );
          textStyle = TextStyle(
            fontSize: fontPx,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: [
              Shadow(
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          );
          break;
        case CustomStyle.highlighted:
          decoration = BoxDecoration(
            color: Colors.amber.withOpacity(0.9),
            border: Border.all(color: Colors.red, width: 3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          );
          textStyle = TextStyle(
            fontSize: fontPx,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          );
          break;
      }

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: Transform.rotate(
          angle: s.rotationDeg * 3.141592653589793 / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: decoration,
            child: Text(
              s.text,
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

