import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../model/pdf_stamp.dart';
import '../engine/stamper_platform.dart'
    if (dart.library.html) '../engine/stamper_stub.dart';

/// Converts PdfPageRotation enum or int to degrees (0-359).
int rotationToDegrees(Object rotation) {
  if (rotation is PdfPageRotation) {
    switch (rotation) {
      case PdfPageRotation.none:
        return 0;
      case PdfPageRotation.clockwise90:
        return 90;
      case PdfPageRotation.clockwise180:
        return 180;
      case PdfPageRotation.clockwise270:
        return 270;
    }
  }
  if (rotation is int) {
    final r = rotation % 360;
    return (r + 360) % 360;
  }
  // Fallback (should not happen in pdfrx)
  return 0;
}

/// PDF stamp editor page with interactive stamp placement and export.
///
/// Supports:
/// - Loading PDF from bytes
/// - Loading PNG stamp image
/// - Preview image/text overlay while zooming/rotating
/// - Export modified PDF with stamps embedded as real PDF objects
class PdfStampEditorPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final Uint8List? pngBytes;
  final double stampWidthPt;
  final double stampRotationDeg;
  final ValueChanged<List<PdfStamp>>? onStampsChanged;
  final VoidCallback? onTapDown;
  final VoidCallback? onLongPressDown;

  const PdfStampEditorPage({
    super.key,
    required this.pdfBytes,
    this.pngBytes,
    this.stampWidthPt = 140,
    this.stampRotationDeg = 0,
    this.onStampsChanged,
    this.onTapDown,
    this.onLongPressDown,
  });

  @override
  State<PdfStampEditorPage> createState() => _PdfStampEditorPageState();
}

class _PdfStampEditorPageState extends State<PdfStampEditorPage> {
  final List<PdfStamp> _stamps = [];
  bool _showViewer =
      true; // Controls viewer visibility to prevent concurrent PDFium calls
  File? _tempPdfFile; // Materialized PDF for viewer on non-web platforms

  List<PdfStamp> get stamps => List.unmodifiable(_stamps);

  void clearStamps() {
    setState(() {
      _stamps.clear();
      widget.onStampsChanged?.call(stamps);
    });
  }

  @override
  void initState() {
    super.initState();
    _materializePdfToTempFileIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PdfStampEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.pdfBytes, widget.pdfBytes)) {
      _materializePdfToTempFileIfNeeded();
    }
  }

  Future<void> _materializePdfToTempFileIfNeeded() async {
    if (kIsWeb) return;
    final bytes = widget.pdfBytes;
    if (bytes.isEmpty) return;

    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'viewer_${DateTime.now().microsecondsSinceEpoch}.pdf',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    setState(() => _tempPdfFile = file);
  }

  Future<void> _exportStampedPdf() async {
    final pdfBytes = widget.pdfBytes;
    if (pdfBytes.isEmpty) return;

    if (kIsWeb) {
      _snack('Export not supported on this platform (FFI/PDFium required).');
      return;
    }

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
        stamps: stamps,
      );

      // In a real app, you'd save this or share it
      // For now, just show a message
      _snack('Export successful! ${outBytes.length} bytes');
    } catch (e) {
      _snack('Export failed: $e');
      if (kDebugMode) {
        rethrow;
      }
    } finally {
      // 2) Resume viewer after stamping completes
      if (mounted) {
        setState(() => _showViewer = true);
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pdfBytes = widget.pdfBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Stamping (vector)'),
        actions: [
          IconButton(
            tooltip: 'Export stamped PDF',
            onPressed: pdfBytes.isEmpty ? null : _exportStampedPdf,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (pdfBytes.isEmpty) {
            return const Center(child: Text('No PDF loaded.'));
          }

          if (!_showViewer) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting...'),
                ],
              ),
            );
          }

          // Web: in‑memory bytes
          if (kIsWeb) {
            return PdfViewer.data(
              pdfBytes,
              sourceName: 'stamped.pdf',
              params: PdfViewerParams(
                pageOverlaysBuilder: (context, pageRect, page) => [
                  Positioned.fromRect(
                    rect: pageRect,
                    child: _PageOverlay(
                      page: page,
                      stamps: _stamps,
                      onTapDown: (offset) {
                        final png = widget.pngBytes;
                        if (png == null) {
                          _snack('Pick a PNG first.');
                          return;
                        }
                        final pdfPt = _viewerOffsetToPdfPoint(
                          page: page,
                          localOffsetTopLeft: offset,
                          scaledPageSizePx: pageRect.size,
                        );
                        final stamp = ImageStamp(
                          pageIndex: page.pageNumber - 1,
                          centerXPt: pdfPt.x,
                          centerYPt: pdfPt.y,
                          rotationDeg: widget.stampRotationDeg,
                          pngBytes: png,
                          widthPt: widget.stampWidthPt,
                          heightPt: widget.stampWidthPt * 0.35,
                        );
                        setState(() {
                          _stamps.add(stamp);
                          widget.onStampsChanged?.call(stamps);
                        });
                        widget.onTapDown?.call();
                      },
                      onLongPressDown: (offset) {
                        final pdfPt = _viewerOffsetToPdfPoint(
                          page: page,
                          localOffsetTopLeft: offset,
                          scaledPageSizePx: pageRect.size,
                        );
                        setState(() {
                          _stamps.add(
                            TextStamp(
                              pageIndex: page.pageNumber - 1,
                              centerXPt: pdfPt.x,
                              centerYPt: pdfPt.y,
                              rotationDeg: widget.stampRotationDeg,
                              text: 'APPROVED',
                              fontSizePt: 18,
                            ),
                          );
                          widget.onStampsChanged?.call(stamps);
                        });
                        widget.onLongPressDown?.call();
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Native: temp file
          if (_tempPdfFile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return PdfViewer.file(
            _tempPdfFile!.path,
            params: PdfViewerParams(
              pageOverlaysBuilder: (context, pageRect, page) => [
                Positioned.fromRect(
                  rect: pageRect,
                  child: _PageOverlay(
                    page: page,
                    stamps: _stamps,
                    onTapDown: (offset) {
                      final png = widget.pngBytes;
                      if (png == null) {
                        _snack('Pick a PNG first.');
                        return;
                      }
                      final pdfPt = _viewerOffsetToPdfPoint(
                        page: page,
                        localOffsetTopLeft: offset,
                        scaledPageSizePx: pageRect.size,
                      );
                      final stamp = ImageStamp(
                        pageIndex: page.pageNumber - 1,
                        centerXPt: pdfPt.x,
                        centerYPt: pdfPt.y,
                        rotationDeg: widget.stampRotationDeg,
                        pngBytes: png,
                        widthPt: widget.stampWidthPt,
                        heightPt: widget.stampWidthPt * 0.35,
                      );
                      setState(() {
                        _stamps.add(stamp);
                        widget.onStampsChanged?.call(stamps);
                      });
                      widget.onTapDown?.call();
                    },
                    onLongPressDown: (offset) {
                      final pdfPt = _viewerOffsetToPdfPoint(
                        page: page,
                        localOffsetTopLeft: offset,
                        scaledPageSizePx: pageRect.size,
                      );
                      setState(() {
                        _stamps.add(
                          TextStamp(
                            pageIndex: page.pageNumber - 1,
                            centerXPt: pdfPt.x,
                            centerYPt: pdfPt.y,
                            rotationDeg: widget.stampRotationDeg,
                            text: 'APPROVED',
                            fontSizePt: 18,
                          ),
                        );
                        widget.onStampsChanged?.call(stamps);
                      });
                      widget.onLongPressDown?.call();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A widget that draws stamps on top of one page AND captures taps inside that page.
class _PageOverlay extends StatelessWidget {
  const _PageOverlay({
    required this.page,
    required this.stamps,
    required this.onTapDown,
    required this.onLongPressDown,
  });

  final PdfPage page;
  final List<PdfStamp> stamps;
  final void Function(Offset localOffsetTopLeft) onTapDown;
  final void Function(Offset localOffsetTopLeft) onLongPressDown;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledPageSizePx =
            Size(constraints.maxWidth, constraints.maxHeight);

        final pageStamps =
            stamps.where((s) => s.pageIndex == page.pageNumber - 1).toList();

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => onTapDown(d.localPosition),
          onLongPressStart: (d) => onLongPressDown(d.localPosition),
          child: Stack(
            children: [
              for (final s in pageStamps)
                _buildStampWidget(
                  stamp: s,
                  page: page,
                  scaledPageSizePx: scaledPageSizePx,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStampWidget({
    required PdfStamp stamp,
    required PdfPage page,
    required Size scaledPageSizePx,
  }) {
    // Convert PDF point -> viewer local offset (top-left origin)
    final posPx = _pdfPointToViewerOffset(
      page: page,
      xPt: stamp.centerXPt,
      yPt: stamp.centerYPt,
      scaledPageSizePx: scaledPageSizePx,
    );

    if (stamp case ImageStamp s) {
      final scale = _pageScaleFactors(page, scaledPageSizePx);
      final wPx = s.widthPt * scale.sx;
      final hPx = s.heightPt * scale.sy;

      return Positioned(
        left: posPx.dx - wPx / 2,
        top: posPx.dy - hPx / 2,
        width: wPx,
        height: hPx,
        child: Transform.rotate(
          angle: s.rotationDeg * math.pi / 180,
          child: Image.memory(s.pngBytes, fit: BoxFit.fill),
        ),
      );
    }

    if (stamp case TextStamp s) {
      final scale = _pageScaleFactors(page, scaledPageSizePx);
      final fontPx = s.fontSizePt * scale.sy;

      return Positioned(
        left: posPx.dx,
        top: posPx.dy,
        child: Transform.rotate(
          angle: s.rotationDeg * math.pi / 180,
          child: Text(
            s.text,
            style: TextStyle(
              fontSize: fontPx,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// ===== Coordinate conversion (no guessing; matches PDF rotation model) =====
/// PDF user space: points, origin bottom-left.
/// Viewer page local: pixels, origin top-left.

({double sx, double sy}) _pageScaleFactors(
    PdfPage page, Size scaledPageSizePx) {
  // PDF page size in points
  final w = page.width;
  final h = page.height;

  final rot = rotationToDegrees(page.rotation);
  final rotatedW = (rot == 90 || rot == 270) ? h : w;
  final rotatedH = (rot == 90 || rot == 270) ? w : h;

  return (
    sx: scaledPageSizePx.width / rotatedW,
    sy: scaledPageSizePx.height / rotatedH,
  );
}

PdfPoint _viewerOffsetToPdfPoint({
  required PdfPage page,
  required Offset localOffsetTopLeft,
  required Size scaledPageSizePx,
}) {
  // pdfrx provides this helper for exactly this conversion.
  final rot = rotationToDegrees(page.rotation);
  return localOffsetTopLeft.toPdfPoint(
    page: page,
    scaledPageSize: scaledPageSizePx,
    rotation: rot,
  );
}

Offset _pdfPointToViewerOffset({
  required PdfPage page,
  required double xPt,
  required double yPt,
  required Size scaledPageSizePx,
}) {
  final w = page.width;
  final h = page.height;
  final rot = rotationToDegrees(page.rotation);

  // Map original PDF point -> rotated-space point (origin bottom-left)
  double xr, yr;
  if (rot == 0) {
    xr = xPt;
    yr = yPt;
  } else if (rot == 90) {
    xr = yPt;
    yr = w - xPt;
  } else if (rot == 180) {
    xr = w - xPt;
    yr = h - yPt;
  } else if (rot == 270) {
    xr = h - yPt;
    yr = xPt;
  } else {
    // pdfrx rotation is typically multiples of 90.
    xr = xPt;
    yr = yPt;
  }

  final rotatedW = (rot == 90 || rot == 270) ? h : w;
  final rotatedH = (rot == 90 || rot == 270) ? w : h;

  final sx = scaledPageSizePx.width / rotatedW;
  final sy = scaledPageSizePx.height / rotatedH;

  // rotated-space bottom-left -> viewer top-left
  final xPx = xr * sx;
  final yPx = (rotatedH - yr) * sy;

  return Offset(xPx, yPx);
}
