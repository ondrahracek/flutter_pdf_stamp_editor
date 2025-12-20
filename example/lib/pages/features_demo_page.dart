import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';
import '../widgets/feature_toggle_panel.dart';

/// Demo page for feature flags (enableDrag, enableResize, enableRotate, enableSelection).
class FeaturesDemoPage extends StatefulWidget {
  const FeaturesDemoPage({super.key});

  @override
  State<FeaturesDemoPage> createState() => FeaturesDemoPageState();
}

class FeaturesDemoPageState extends State<FeaturesDemoPage> {
  bool _enableDrag = true;
  bool _enableResize = true;
  bool _enableRotate = true;
  bool _enableSelection = true;
  Uint8List? _pdfBytes;
  bool _showViewer = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features Demo'),
        actions: [
          IconButton(
            tooltip: 'Pick PDF',
            onPressed: _pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: _pdfBytes == null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Pick a PDF to see feature flags in action'),
                  ),
                  FeatureTogglePanel(
                    enableDrag: _enableDrag,
                    enableResize: _enableResize,
                    enableRotate: _enableRotate,
                    enableSelection: _enableSelection,
                    onDragChanged: (value) => setState(() => _enableDrag = value),
                    onResizeChanged: (value) => setState(() => _enableResize = value),
                    onRotateChanged: (value) => setState(() => _enableRotate = value),
                    onSelectionChanged: (value) => setState(() => _enableSelection = value),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatusIndicator('Drag', _enableDrag, Icons.drag_handle),
                          _buildStatusIndicator('Resize', _enableResize, Icons.aspect_ratio),
                          _buildStatusIndicator('Rotate', _enableRotate, Icons.rotate_right),
                          _buildStatusIndicator('Selection', _enableSelection, Icons.check_circle_outline),
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
                            'Preset Scenarios',
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
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _enableDrag = true;
                                  _enableResize = false;
                                  _enableRotate = false;
                                  _enableSelection = false;
                                }),
                                child: const Text('Drag Only'),
                              ),
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _enableDrag = false;
                                  _enableResize = true;
                                  _enableRotate = false;
                                  _enableSelection = false;
                                }),
                                child: const Text('Resize Only'),
                              ),
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _enableDrag = false;
                                  _enableResize = false;
                                  _enableRotate = true;
                                  _enableSelection = false;
                                }),
                                child: const Text('Rotate Only'),
                              ),
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _enableDrag = true;
                                  _enableResize = true;
                                  _enableRotate = true;
                                  _enableSelection = true;
                                }),
                                child: const Text('All Features'),
                              ),
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _enableDrag = false;
                                  _enableResize = false;
                                  _enableRotate = false;
                                  _enableSelection = false;
                                }),
                                child: const Text('None'),
                              ),
                            ],
                          ),
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
                          ..._buildInstructions(),
                        ],
                      ),
                    ),
                  ),
            FeatureTogglePanel(
              enableDrag: _enableDrag,
              enableResize: _enableResize,
              enableRotate: _enableRotate,
              enableSelection: _enableSelection,
              onDragChanged: (value) => setState(() => _enableDrag = value),
              onResizeChanged: (value) => setState(() => _enableResize = value),
              onRotateChanged: (value) => setState(() => _enableRotate = value),
              onSelectionChanged: (value) => setState(() => _enableSelection = value),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusIndicator('Drag', _enableDrag, Icons.drag_handle),
                    _buildStatusIndicator('Resize', _enableResize, Icons.aspect_ratio),
                    _buildStatusIndicator('Rotate', _enableRotate, Icons.rotate_right),
                    _buildStatusIndicator('Selection', _enableSelection, Icons.check_circle_outline),
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
                      'Preset Scenarios',
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
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _enableDrag = true;
                            _enableResize = false;
                            _enableRotate = false;
                            _enableSelection = false;
                          }),
                          child: const Text('Drag Only'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _enableDrag = false;
                            _enableResize = true;
                            _enableRotate = false;
                            _enableSelection = false;
                          }),
                          child: const Text('Resize Only'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _enableDrag = false;
                            _enableResize = false;
                            _enableRotate = true;
                            _enableSelection = false;
                          }),
                          child: const Text('Rotate Only'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _enableDrag = true;
                            _enableResize = true;
                            _enableRotate = true;
                            _enableSelection = true;
                          }),
                          child: const Text('All Features'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _enableDrag = false;
                            _enableResize = false;
                            _enableRotate = false;
                            _enableSelection = false;
                          }),
                          child: const Text('None'),
                        ),
                      ],
                    ),
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
                  ],
                ),
              ),
            ),
                ],
              ),
            )
          : _showViewer
              ? Column(
                  children: [
                    Expanded(
                      child: PdfStampEditorPage(
                        pdfBytes: _pdfBytes!,
                        enableDrag: _enableDrag,
                        enableResize: _enableResize,
                        enableRotate: _enableRotate,
                        enableSelection: _enableSelection,
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          FeatureTogglePanel(
                            enableDrag: _enableDrag,
                            enableResize: _enableResize,
                            enableRotate: _enableRotate,
                            enableSelection: _enableSelection,
                            onDragChanged: (value) => setState(() => _enableDrag = value),
                            onResizeChanged: (value) => setState(() => _enableResize = value),
                            onRotateChanged: (value) => setState(() => _enableRotate = value),
                            onSelectionChanged: (value) => setState(() => _enableSelection = value),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatusIndicator('Drag', _enableDrag, Icons.drag_handle),
                                  _buildStatusIndicator('Resize', _enableResize, Icons.aspect_ratio),
                                  _buildStatusIndicator('Rotate', _enableRotate, Icons.rotate_right),
                                  _buildStatusIndicator('Selection', _enableSelection, Icons.check_circle_outline),
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
                                    'Preset Scenarios',
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
                                      ElevatedButton(
                                        onPressed: () => setState(() {
                                          _enableDrag = true;
                                          _enableResize = false;
                                          _enableRotate = false;
                                          _enableSelection = false;
                                        }),
                                        child: const Text('Drag Only'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => setState(() {
                                          _enableDrag = false;
                                          _enableResize = true;
                                          _enableRotate = false;
                                          _enableSelection = false;
                                        }),
                                        child: const Text('Resize Only'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => setState(() {
                                          _enableDrag = false;
                                          _enableResize = false;
                                          _enableRotate = true;
                                          _enableSelection = false;
                                        }),
                                        child: const Text('Rotate Only'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => setState(() {
                                          _enableDrag = true;
                                          _enableResize = true;
                                          _enableRotate = true;
                                          _enableSelection = true;
                                        }),
                                        child: const Text('All Features'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => setState(() {
                                          _enableDrag = false;
                                          _enableResize = false;
                                          _enableRotate = false;
                                          _enableSelection = false;
                                        }),
                                        child: const Text('None'),
                                      ),
                                    ],
                                  ),
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
                                  ..._buildInstructions(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
    );
  }

  Widget _buildStatusIndicator(String label, bool enabled, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: enabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInstructions() {
    final instructions = <Widget>[];
    
    if (_enableDrag) {
      instructions.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text('• Drag: Tap and hold a stamp, then drag to move it'),
        ),
      );
    }
    
    if (_enableResize) {
      instructions.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text('• Resize: Pinch to zoom on a stamp to resize it'),
        ),
      );
    }
    
    if (_enableRotate) {
      instructions.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text('• Rotate: Use rotation gesture on a stamp to rotate it'),
        ),
      );
    }
    
    if (_enableSelection) {
      instructions.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text('• Selection: Tap a stamp to select it'),
        ),
      );
    }
    
    if (instructions.isEmpty) {
      instructions.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text('No features enabled. Enable features above to see instructions.'),
        ),
      );
    }
    
    return instructions;
  }
}

