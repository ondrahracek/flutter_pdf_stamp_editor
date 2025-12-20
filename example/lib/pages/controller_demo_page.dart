import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';
import '../widgets/stamp_info_panel.dart';
import '../widgets/controller_controls.dart';

/// Demo page for PdfStampEditorController API.
/// 
/// Demonstrates all controller methods including:
/// - Programmatic stamp addition, update, and removal
/// - Selection management
/// - Controller listener functionality
/// - Real-time state display
class ControllerDemoPage extends StatefulWidget {
  const ControllerDemoPage({super.key});

  @override
  State<ControllerDemoPage> createState() => ControllerDemoPageState();
}

class ControllerDemoPageState extends State<ControllerDemoPage> {
  late final PdfStampEditorController controller;
  final List<String> _changeLog = [];
  Uint8List? _pdfBytes;
  bool _showViewer = true;

  @override
  void initState() {
    super.initState();
    controller = PdfStampEditorController();
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {
      _changeLog.add('Controller changed at ${DateTime.now().toString().substring(11, 19)}');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _addImageStamp() {
    final stamp = ImageStamp(
      pageIndex: 0,
      centerXPt: 200.0,
      centerYPt: 300.0,
      rotationDeg: 0.0,
      pngBytes: Uint8List.fromList([1, 2, 3]),
      widthPt: 100.0,
      heightPt: 50.0,
    );
    setState(() {
      _changeLog.add('addStamp: ImageStamp');
    });
    controller.addStamp(stamp);
  }

  void _addTextStamp() {
    final stamp = TextStamp(
      pageIndex: 0,
      centerXPt: 200.0,
      centerYPt: 300.0,
      rotationDeg: 0.0,
      text: 'APPROVED',
      fontSizePt: 18.0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller Demo'),
        actions: [
          IconButton(
            tooltip: 'Pick PDF',
            onPressed: _pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: _pdfBytes == null
          ? ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Pick a PDF to see PdfStampEditorPage integration'),
                      ),
                      StampInfoPanel(
                        stamps: controller.stamps,
                        selectedIndices: controller.selectedIndices,
                        showStampsList: true,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Change Log',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  itemCount: _changeLog.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Text(
                                        _changeLog[index],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addImageStamp,
                        icon: const Icon(Icons.add),
                        label: const Text('Add ImageStamp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addTextStamp,
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Add TextStamp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          foregroundColor: Colors.blue,
                        ),
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
                  ),
                );
              },
            )
          : _showViewer
              ? Column(
                  children: [
                    Expanded(
                      child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) {
                          return PdfStampEditorPage(
                            pdfBytes: _pdfBytes!,
                            controller: controller,
                            enableDrag: true,
                            enableResize: true,
                            enableRotate: true,
                            enableSelection: true,
                          );
                        },
                      ),
                    ),
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              StampInfoPanel(
                                stamps: controller.stamps,
                                selectedIndices: controller.selectedIndices,
                                showStampsList: true,
                              ),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Change Log',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 150,
                                        child: ListView.builder(
                                          itemCount: _changeLog.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                                              child: Text(
                                                _changeLog[index],
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addImageStamp,
                                icon: const Icon(Icons.add),
                                label: const Text('Add ImageStamp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  foregroundColor: Colors.green,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addTextStamp,
                                icon: const Icon(Icons.text_fields),
                                label: const Text('Add TextStamp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  foregroundColor: Colors.blue,
                                ),
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
                          ),
                        );
                      },
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

