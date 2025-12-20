import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';
import '../utils/asset_loader.dart';

class EdgeCasesPerformanceDemoPage extends StatefulWidget {
  const EdgeCasesPerformanceDemoPage({super.key});

  @override
  State<EdgeCasesPerformanceDemoPage> createState() => EdgeCasesPerformanceDemoPageState();
}

class EdgeCasesPerformanceDemoPageState extends State<EdgeCasesPerformanceDemoPage> {
  late final PdfStampEditorController controller;
  Uint8List? _pngBytes;
  int _frameCount = 0;
  DateTime _lastUpdate = DateTime.now();
  double _currentFPS = 0.0;

  @override
  void initState() {
    super.initState();
    controller = PdfStampEditorController();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
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

  void _onFrameTimings(List<FrameTiming> timings) {
    _frameCount += timings.length;
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate).inMilliseconds;
    
    if (elapsed >= 1000) {
      setState(() {
        _currentFPS = (_frameCount * 1000.0) / elapsed;
        _frameCount = 0;
        _lastUpdate = now;
      });
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    controller.dispose();
    super.dispose();
  }

  void _generateManyStamps() {
    if (_pngBytes == null) return;
    
    final random = math.Random();
    final pageWidth = 612.0;
    final pageHeight = 792.0;
    
    for (int i = 0; i < 50; i++) {
      final stamp = ImageStamp(
        pageIndex: 0,
        centerXPt: random.nextDouble() * pageWidth,
        centerYPt: random.nextDouble() * pageHeight,
        rotationDeg: random.nextDouble() * 360,
        pngBytes: _pngBytes!,
        widthPt: 50 + random.nextDouble() * 100,
        heightPt: 50 + random.nextDouble() * 100,
      );
      controller.addStamp(stamp);
    }
  }

  void _multiPageTest() {
    if (_pngBytes == null) return;
    
    final random = math.Random();
    final pageWidth = 612.0;
    final pageHeight = 792.0;
    
    for (int pageIndex = 0; pageIndex < 3; pageIndex++) {
      for (int i = 0; i < 5; i++) {
        final stamp = ImageStamp(
          pageIndex: pageIndex,
          centerXPt: random.nextDouble() * pageWidth,
          centerYPt: random.nextDouble() * pageHeight,
          rotationDeg: random.nextDouble() * 360,
          pngBytes: _pngBytes!,
          widthPt: 50 + random.nextDouble() * 100,
          heightPt: 50 + random.nextDouble() * 100,
        );
        controller.addStamp(stamp);
      }
    }
  }

  void _edgeCasesTest() {
    if (_pngBytes == null) return;
    
    final pageWidth = 612.0;
    final pageHeight = 792.0;
    
    controller.clearStamps();
    
    final stampSize = 50.0;
    final halfSize = stampSize / 2;
    
    controller.addStamp(ImageStamp(
      pageIndex: 0,
      centerXPt: halfSize,
      centerYPt: pageHeight - halfSize,
      rotationDeg: 0,
      pngBytes: _pngBytes!,
      widthPt: stampSize,
      heightPt: stampSize,
    ));
    
    controller.addStamp(ImageStamp(
      pageIndex: 0,
      centerXPt: pageWidth - halfSize,
      centerYPt: halfSize,
      rotationDeg: 0,
      pngBytes: _pngBytes!,
      widthPt: stampSize,
      heightPt: stampSize,
    ));
    
    final centerX = pageWidth / 2;
    final centerY = pageHeight / 2;
    for (int i = 0; i < 10; i++) {
      controller.addStamp(ImageStamp(
        pageIndex: 0,
        centerXPt: centerX + i * 5,
        centerYPt: centerY + i * 5,
        rotationDeg: 0,
        pngBytes: _pngBytes!,
        widthPt: stampSize,
        heightPt: stampSize,
      ));
    }
    
    controller.addStamp(ImageStamp(
      pageIndex: 0,
      centerXPt: centerX,
      centerYPt: centerY,
      rotationDeg: 0,
      pngBytes: _pngBytes!,
      widthPt: 500,
      heightPt: 500,
    ));
    
    controller.addStamp(ImageStamp(
      pageIndex: 0,
      centerXPt: centerX,
      centerYPt: centerY,
      rotationDeg: 0,
      pngBytes: _pngBytes!,
      widthPt: 10,
      heightPt: 10,
    ));
  }

  Future<void> _stressTest() async {
    if (_pngBytes == null) return;
    
    controller.clearStamps();
    
    _generateManyStamps();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    for (int i = 0; i < 10 && i < controller.stamps.length; i++) {
      controller.selectStamp(i);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    controller.clearSelection();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _generateManyStamps();
  }

  void _rotatedPageTest() {
    if (_pngBytes == null) return;
    
    final pageWidth = 612.0;
    final pageHeight = 792.0;
    final centerX = pageWidth / 2;
    final centerY = pageHeight / 2;
    
    controller.clearStamps();
    
    for (int rotation = 0; rotation < 360; rotation += 90) {
      controller.addStamp(ImageStamp(
        pageIndex: 0,
        centerXPt: centerX,
        centerYPt: centerY,
        rotationDeg: rotation.toDouble(),
        pngBytes: _pngBytes!,
        widthPt: 100,
        heightPt: 100,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Cases & Performance'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPerformanceMetricsPanel(),
            ElevatedButton(
              onPressed: _generateManyStamps,
              child: const Text('Generate Many Stamps'),
            ),
            ElevatedButton(
              onPressed: _multiPageTest,
              child: const Text('Multi-page Test'),
            ),
            ElevatedButton(
              onPressed: _edgeCasesTest,
              child: const Text('Edge Cases Test'),
            ),
            ElevatedButton(
              onPressed: _stressTest,
              child: const Text('Stress Test'),
            ),
            ElevatedButton(
              onPressed: _rotatedPageTest,
              child: const Text('Rotated Page Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('FPS: ${_currentFPS.toStringAsFixed(1)}'),
            const SizedBox(height: 4),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return Text('Stamps: ${controller.stamps.length}');
              },
            ),
          ],
        ),
      ),
    );
  }
}

