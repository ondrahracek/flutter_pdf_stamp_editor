import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

/// Demo page for all callback APIs.
class CallbacksDemoPage extends StatefulWidget {
  const CallbacksDemoPage({super.key});

  @override
  State<CallbacksDemoPage> createState() => CallbacksDemoPageState();
}

class CallbacksDemoPageState extends State<CallbacksDemoPage> {
  final List<String> _callbackLog = [];
  int _stampsChangedCount = 0;
  int _selectedCount = 0;
  int _updatedCount = 0;
  int _deletedCount = 0;
  int _tapDownCount = 0;
  int _longPressDownCount = 0;
  PdfStamp? _lastStamp;
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
        title: const Text('Callbacks Demo'),
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
                    child: Text('Pick a PDF to see callbacks in action'),
                  ),
                  _buildControls(),
                ],
              ),
            )
          : _showViewer
              ? Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildControls(),
                      ),
                    ),
                    if (_pdfBytes != null)
                      Expanded(
                        child: PdfStampEditorPage(
                          pdfBytes: _pdfBytes!,
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
                        ),
                      ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Card(
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
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow('Stamps Changed', _stampsChangedCount),
                _buildStatRow('Selected', _selectedCount),
                _buildStatRow('Updated', _updatedCount),
                _buildStatRow('Deleted', _deletedCount),
                _buildStatRow('Tap Down', _tapDownCount),
                _buildStatRow('Long Press Down', _longPressDownCount),
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
                  'Stamp Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_lastStamp == null)
                  const Text('No stamp selected or updated yet')
                else
                  _buildStampDetails(_lastStamp!),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _callbackLog.clear();
                _stampsChangedCount = 0;
                _selectedCount = 0;
                _updatedCount = 0;
                _deletedCount = 0;
                _tapDownCount = 0;
                _longPressDownCount = 0;
                _lastStamp = null;
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Log'),
          ),
        ),
      ],
    );
  }

  void _onStampsChanged(List<PdfStamp> stamps) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _stampsChangedCount++;
      _callbackLog.add('[$timestamp] onStampsChanged: ${stamps.length} stamps');
    });
  }

  void _onStampSelected(int index, PdfStamp stamp) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _selectedCount++;
      _lastStamp = stamp;
      _callbackLog.add('[$timestamp] onStampSelected: index=$index, type=${stamp is ImageStamp ? "Image" : "Text"}');
    });
  }

  void _onStampUpdated(int index, PdfStamp stamp) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _updatedCount++;
      _lastStamp = stamp;
      _callbackLog.add('[$timestamp] onStampUpdated: index=$index');
    });
  }

  void _onStampDeleted(List<int> indices) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _deletedCount++;
      _callbackLog.add('[$timestamp] onStampDeleted: indices=$indices');
    });
  }

  void _onTapDown() {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _tapDownCount++;
      _callbackLog.add('[$timestamp] onTapDown');
    });
  }

  void _onLongPressDown() {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _longPressDownCount++;
      _callbackLog.add('[$timestamp] onLongPressDown');
    });
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStampDetails(PdfStamp stamp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type: ${stamp is ImageStamp ? "Image" : "Text"}'),
        Text('Page: ${stamp.pageIndex + 1}'),
        Text('Position: (${stamp.centerXPt.toStringAsFixed(1)}, ${stamp.centerYPt.toStringAsFixed(1)})'),
        Text('Rotation: ${stamp.rotationDeg.toStringAsFixed(1)}°'),
        if (stamp is ImageStamp) ...[
          Text('Width: ${stamp.widthPt.toStringAsFixed(1)} pt'),
          Text('Height: ${stamp.heightPt.toStringAsFixed(1)} pt'),
        ],
        if (stamp is TextStamp) ...[
          Text('Text: ${stamp.text}'),
          Text('Font Size: ${stamp.fontSizePt.toStringAsFixed(1)} pt'),
        ],
      ],
    );
  }
}

