import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';
import '../widgets/feature_toggle_panel.dart';
import '../widgets/controller_controls.dart';
import '../widgets/stamp_info_panel.dart';
import '../utils/asset_loader.dart';

class FullFeatureDemoPage extends StatefulWidget {
  const FullFeatureDemoPage({super.key});

  @override
  State<FullFeatureDemoPage> createState() => FullFeatureDemoPageState();
}

class FullFeatureDemoPageState extends State<FullFeatureDemoPage> {
  late final PdfStampEditorController controller;
  final List<String> _callbackLog = [];
  Uint8List? _pdfBytes;
  Uint8List? _pngBytes;
  File? _exportedPdfFile;
  bool _showViewer = true;

  @override
  void initState() {
    super.initState();
    controller = PdfStampEditorController();
    _loadDefaultStamp();
  }

  Future<void> _loadDefaultStamp() async {
    try {
      final bytes = await AssetLoader.loadAssetBytes('lib/assets/dog.png');
      setState(() => _pngBytes = bytes);
    } catch (e) {
      debugPrint('Failed to load default stamp: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
      controller.clearStamps();
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
        title: const Text('Full Feature Demo'),
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
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Pick a PDF to begin'),
                  ),
                  _buildWorkflowStepIndicator(),
                  _buildWorkflowInstructions(),
                  _buildCallbackLogPanel(),
                ],
              ),
            )
          : _showViewer
              ? Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildWorkflowStepIndicator(),
                            ListenableBuilder(
                              listenable: controller,
                              builder: (context, _) {
                                return Column(
                                  children: [
                                    FeatureTogglePanel(
                                      enableDrag: true,
                                      enableResize: true,
                                      enableRotate: true,
                                      enableSelection: true,
                                    ),
                                    StampInfoPanel(
                                      stamps: controller.stamps,
                                      selectedIndices: controller.selectedIndices,
                                      showStampsList: true,
                                    ),
                                    ControllerControls(
                                      controller: controller,
                                      onAddStamp: _addImageStamp,
                                      onUpdateStamp: _updateStamp,
                                      onRemoveStamp: _removeStamp,
                                      onClearStamps: _clearStamps,
                                      onSelectStamp: _selectStamp,
                                      onClearSelection: _clearSelection,
                                      onDeleteSelected: _deleteSelected,
                                    ),
                                  ],
                                );
                              },
                            ),
                            _buildWorkflowInstructions(),
                            if (_exportedPdfFile != null) _buildExportVerification(),
                            _buildCallbackLogPanel(),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: PdfStampEditorPage(
                        pdfBytes: _pdfBytes!,
                        pngBytes: _pngBytes,
                        controller: controller,
                        enableDrag: true,
                        enableResize: true,
                        enableRotate: true,
                        enableSelection: true,
                        onStampsChanged: _onStampsChanged,
                        onStampSelected: _onStampSelected,
                        onStampUpdated: _onStampUpdated,
                        onStampDeleted: _onStampDeleted,
                        onTapDown: _onTapDown,
                        onLongPressDown: _onLongPressDown,
                        onImageStampPlaced: () {
                          setState(() => _pngBytes = null);
                        },
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildWorkflowStepIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Workflow Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStepChip('Load PDF'),
                _buildStepChip('Load PNG'),
                _buildStepChip('Place'),
                _buildStepChip('Drag'),
                _buildStepChip('Resize'),
                _buildStepChip('Rotate'),
                _buildStepChip('Select'),
                _buildStepChip('Delete'),
                _buildStepChip('Export'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(String label) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.circle, size: 12),
    );
  }

  Widget _buildExportVerification() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Exported PDF: ${_exportedPdfFile?.path ?? 'N/A'}'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _reloadExportedPdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Exported PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reloadExportedPdf() async {
    if (_exportedPdfFile == null || !await _exportedPdfFile!.exists()) {
      _snack('Exported PDF file not found');
      return;
    }

    final bytes = await _exportedPdfFile!.readAsBytes();
    setState(() {
      _pdfBytes = bytes;
      controller.clearStamps();
      _snack('Reloaded exported PDF. Verify stamps are embedded.');
    });
  }

  Widget _buildWorkflowInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Workflow Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text('1. Load PDF: Tap the PDF icon to pick a PDF file'),
            const SizedBox(height: 8),
            const Text('2. Load PNG: Tap the image icon to pick a stamp image'),
            const SizedBox(height: 8),
            const Text('3. Place: Tap on PDF to place image stamp, long-press for text stamp'),
            const SizedBox(height: 8),
            const Text('4. Drag: Tap and hold a stamp, then drag to move it'),
            const SizedBox(height: 8),
            const Text('5. Resize: Pinch to zoom on a stamp to resize it'),
            const SizedBox(height: 8),
            const Text('6. Rotate: Use rotation gesture on a stamp to rotate it'),
            const SizedBox(height: 8),
            const Text('7. Select: Tap a stamp to select it'),
            const SizedBox(height: 8),
            const Text('8. Delete: Use controller buttons or delete selected stamps'),
            const SizedBox(height: 8),
            const Text('9. Export: Tap the save icon to export stamped PDF'),
          ],
        ),
      ),
    );
  }

  Widget _buildCallbackLogPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Callback Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _callbackLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _callbackLog[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStampsChanged(List<PdfStamp> stamps) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _callbackLog.add('[$timestamp] onStampsChanged: ${stamps.length} stamps');
    });
  }

  void _onStampSelected(int index, PdfStamp stamp) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _callbackLog.add('[$timestamp] onStampSelected: index=$index');
    });
  }

  void _onStampUpdated(int index, PdfStamp stamp) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _callbackLog.add('[$timestamp] onStampUpdated: index=$index');
    });
  }

  void _onStampDeleted(List<int> indices) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _callbackLog.add('[$timestamp] onStampDeleted: indices=$indices');
    });
  }

  void _onTapDown() {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _callbackLog.add('[$timestamp] onTapDown');
    });
  }

  void _onLongPressDown() {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _callbackLog.add('[$timestamp] onLongPressDown');
    });
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

    setState(() => _showViewer = false);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final outBytes = await PdfiumStamper.applyStamps(
        inputPdfBytes: pdfBytes,
        stamps: controller.stamps,
      );

      final dir = await getApplicationDocumentsDirectory();
      final outFile = File(
        p.join(dir.path, 'stamped_${DateTime.now().millisecondsSinceEpoch}.pdf'),
      );
      await outFile.writeAsBytes(outBytes);

      setState(() {
        _exportedPdfFile = outFile;
        _snack('Exported: ${outFile.path}. Use "Reload Exported PDF" to verify stamps.');
      });
    } catch (e) {
      _snack('Export failed: $e');
      if (kDebugMode) {
        rethrow;
      }
    } finally {
      if (mounted) {
        setState(() => _showViewer = true);
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addImageStamp() {
    if (_pngBytes == null) return;
    
    final stamp = ImageStamp(
      pageIndex: 0,
      centerXPt: 200.0,
      centerYPt: 300.0,
      rotationDeg: 0.0,
      pngBytes: _pngBytes!,
      widthPt: 100.0,
      heightPt: 50.0,
    );
    controller.addStamp(stamp);
  }

  void _updateStamp() {
    if (controller.stamps.isEmpty) return;
    final firstStamp = controller.stamps[0];
    if (firstStamp is ImageStamp) {
      final updated = firstStamp.copyWith(
        centerXPt: 300.0,
        centerYPt: 400.0,
        rotationDeg: 45.0,
      );
      controller.updateStamp(0, updated);
    } else if (firstStamp is TextStamp) {
      final updated = firstStamp.copyWith(
        centerXPt: 300.0,
        centerYPt: 400.0,
        rotationDeg: 45.0,
      );
      controller.updateStamp(0, updated);
    }
  }

  void _removeStamp() {
    if (controller.stamps.isEmpty) return;
    controller.removeStamp(controller.stamps.length - 1);
  }

  void _clearStamps() {
    controller.clearStamps();
  }

  void _selectStamp() {
    if (controller.stamps.isEmpty) return;
    controller.selectStamp(0);
  }

  void _clearSelection() {
    controller.clearSelection();
  }

  void _deleteSelected() {
    controller.deleteSelectedStamps();
  }
}

