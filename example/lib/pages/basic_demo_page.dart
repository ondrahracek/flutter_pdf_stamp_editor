import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

/// Basic demo page demonstrating simple stamp placement and export.
/// 
/// This is the original demo page showing basic functionality:
/// - Load PDF
/// - Load PNG stamp image
/// - Place stamps by tapping
/// - Adjust stamp width and rotation
/// - Export stamped PDF
class BasicDemoPage extends StatefulWidget {
  const BasicDemoPage({super.key});

  @override
  State<BasicDemoPage> createState() => _BasicDemoPageState();
}

class _BasicDemoPageState extends State<BasicDemoPage> {
  // PDF document bytes loaded from file picker
  Uint8List? _pdfBytes;
  
  // PNG image bytes for stamp placement (loaded from image picker)
  Uint8List? _pngBytes;
  
  // List of stamps placed on the PDF (updated via onStampsChanged callback)
  List<PdfStamp> _stamps = [];
  
  // Controls viewer visibility to prevent concurrent PDFium calls during export
  // When false, shows export progress indicator instead of PDF viewer
  bool _showViewer = true;

  // Current stamp dimensions and rotation settings
  // These are applied to new stamps when placed via tap
  double _stampWidthPt = 140; // Width in points (1/72 inch), default 140pt
  double _stampRotationDeg = 0; // Rotation in degrees, default 0° (no rotation)

  /// Picks a PDF file using the file picker.
  /// 
  /// Demonstrates:
  /// - FilePicker API for selecting PDF files
  /// - Loading PDF bytes into memory
  /// - Clearing existing stamps when loading a new PDF
  /// - Success feedback via snackbar
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
      _stamps.clear(); // Clear stamps when loading new PDF
    });
    _snackSuccess('PDF loaded successfully');
  }

  /// Picks a PNG image from the device gallery.
  /// 
  /// Demonstrates:
  /// - ImagePicker API for selecting images
  /// - Loading image bytes for use as stamp image
  /// - Success feedback via snackbar
  /// 
  /// Note: The PNG bytes are passed to PdfStampEditorPage via pngBytes parameter.
  /// When a PNG is loaded, tapping on the PDF will place image stamps.
  Future<void> _pickPng() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;
    
    final bytes = await image.readAsBytes();
    setState(() => _pngBytes = bytes);
    _snackSuccess('PNG image loaded successfully');
  }

  /// Exports the PDF with stamps embedded using PdfiumStamper.
  /// 
  /// Demonstrates:
  /// - Platform detection for FFI support
  /// - PdfiumStamper.applyStamps() API for embedding stamps
  /// - File system operations (writing exported PDF)
  /// - Progress indication by hiding viewer during export
  /// - Comprehensive success feedback with file path, size, and stamp count
  /// - Error handling with user-friendly error messages
  /// 
  /// Important: The viewer must be hidden during export to prevent concurrent
  /// PDFium calls, which would cause crashes. The viewer is resumed in the
  /// finally block after export completes.
  Future<void> _exportStampedPdf() async {
    final pdfBytes = _pdfBytes;
    if (pdfBytes == null) return;

    // Check platform support - FFI/PDFium is required for export
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isWindows &&
        !Platform.isMacOS &&
        !Platform.isLinux) {
      _snackError('Export not supported on this platform (FFI/PDFium required).');
      return;
    }

    // Step 1: Hide viewer to prevent concurrent PDFium calls
    // This is critical - PDFium cannot handle concurrent operations
    setState(() => _showViewer = false);
    await WidgetsBinding.instance.endOfFrame;

    try {
      // Apply stamps to PDF using PdfiumStamper
      // This embeds the stamps as real PDF objects in the document
      final outBytes = await PdfiumStamper.applyStamps(
        inputPdfBytes: pdfBytes,
        stamps: _stamps,
      );

      // Save exported PDF to application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outFile = File(
        '${dir.path}/stamped_$timestamp.pdf',
      );
      await outFile.writeAsBytes(outBytes);
      final fileSizeKB = (outBytes.length / 1024).toStringAsFixed(1);

      // Reload viewer with the exported PDF (which now has embedded stamps)
      setState(() => _pdfBytes = outBytes);
      
      // Show comprehensive success message with export details
      _snackSuccess(
        'Exported successfully!\n'
        'File: ${outFile.path}\n'
        'Size: ${fileSizeKB} KB\n'
        'Stamps: ${_stamps.length}',
      );
    } catch (e) {
      // Show error message if export fails
      _snackError('Export failed: $e');
      rethrow;
    } finally {
      // Step 2: Resume viewer after stamping completes (or fails)
      // This ensures the viewer is always restored, even if export fails
      if (mounted) {
        setState(() => _showViewer = true);
      }
    }
  }

  /// Shows a success snackbar with green background.
  /// 
  /// Demonstrates visual feedback for successful operations.
  /// Used when PDF/PNG is loaded, stamps are cleared, or export succeeds.
  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error snackbar with red background.
  /// 
  /// Demonstrates visual feedback for errors.
  /// Used when export fails or platform is not supported.
  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Demo - PDF Stamping'),
        // Action buttons for PDF picking, PNG picking, and export
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
          // Initial state: Show instructions panel when no PDF is loaded
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Pick a PDF (top bar) to begin.'),
                  ),
                  _buildInstructionsPanel(),
                ],
              ),
            )
          : _showViewer
              // PDF loaded: Show controls and PDF viewer with stamp editor
              ? Column(
                  children: [
                    _controls(), // Stamp count, width/rotation sliders, clear button
                    const Divider(height: 1),
                    Expanded(
                      // PdfStampEditorPage demonstrates:
                      // - PDF viewing with pdfrx
                      // - Interactive stamp placement via tap
                      // - Stamp width and rotation configuration
                      // - onStampsChanged callback for tracking stamp list
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
              // Export in progress: Show progress indicator
              // Viewer is hidden to prevent concurrent PDFium calls
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

  /// Builds the instructions panel shown when no PDF is loaded.
  /// 
  /// Demonstrates:
  /// - User guidance and instructions
  /// - Stamp count display (always visible)
  /// - Clear step-by-step workflow instructions
  Widget _buildInstructionsPanel() {
    return Card(
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
            // Stamp count display - shows current number of stamps placed
            Row(
              children: [
                const Text('Stamps:'),
                const SizedBox(width: 8),
                Text(
                  '${_stamps.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Step-by-step instructions for using the basic demo
            const Text('1. Load PDF: Tap the PDF icon to pick a PDF file'),
            const SizedBox(height: 8),
            const Text('2. Load PNG: Tap the image icon to pick a stamp image'),
            const SizedBox(height: 8),
            const Text('3. Place stamps: Tap on the PDF to place image stamps'),
            const SizedBox(height: 8),
            const Text('4. Adjust settings: Use sliders to change stamp width and rotation'),
            const SizedBox(height: 8),
            const Text('5. Export: Tap the save icon to export the stamped PDF'),
          ],
        ),
      ),
    );
  }

  /// Builds the controls panel shown above the PDF viewer.
  /// 
  /// Demonstrates:
  /// - Stamp count display (real-time count of placed stamps)
  /// - Interactive sliders for configuring stamp width and rotation
  /// - Clear stamps button with disabled state when no stamps exist
  /// - Visual feedback when stamps are cleared
  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stamp count - shows current number of stamps
          Row(
            children: [
              const Text('Stamps:'),
              const SizedBox(width: 8),
              Text(
                '${_stamps.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Control widgets wrapped for responsive layout
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              // Stamp width slider - controls size of new stamps (40-320 points)
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
              // Rotation slider - controls rotation of new stamps (-180° to 180°)
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
              // Clear stamps button - removes all stamps from the PDF
              // Disabled when no stamps exist
              TextButton.icon(
                onPressed: _stamps.isEmpty
                    ? null
                    : () {
                        setState(() => _stamps.clear());
                        _snackSuccess('All stamps cleared');
                      },
                icon: const Icon(Icons.clear),
                label: const Text('Clear stamps'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

