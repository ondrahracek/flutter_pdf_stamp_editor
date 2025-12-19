import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../controller/pdf_stamp_editor_controller.dart';
import '../model/pdf_stamp.dart';
import '../utils/coordinate_converter.dart';
import 'draggable_stamp_widget.dart';
import '../engine/stamper_platform.dart'
    if (dart.library.html) '../engine/stamper_stub.dart';

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
  final PdfStampEditorController? controller;
  final bool enableDrag;
  final bool enableResize;
  final bool enableRotate;
  final bool enableSelection;
  final ValueChanged<List<PdfStamp>>? onStampsChanged;
  final void Function(int index, PdfStamp stamp)? onStampSelected;
  final void Function(int index, PdfStamp stamp)? onStampUpdated;
  final void Function(List<int> indices)? onStampDeleted;
  final Widget Function(BuildContext context, PdfStamp stamp, PdfPage page, Size scaledPageSizePx, Offset position)? stampBuilder;
  final VoidCallback? onTapDown;
  final VoidCallback? onLongPressDown;

  const PdfStampEditorPage({
    super.key,
    required this.pdfBytes,
    this.pngBytes,
    this.stampWidthPt = 140,
    this.stampRotationDeg = 0,
    this.controller,
    this.enableDrag = false,
    this.enableResize = true,
    this.enableRotate = true,
    this.enableSelection = true,
    this.onStampsChanged,
    this.onStampSelected,
    this.onStampUpdated,
    this.onStampDeleted,
    this.stampBuilder,
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
  List<int>? _pendingDeletedIndices;
  int _previousStampCount = 0;
  List<int> _previousSelectedIndices = [];

  List<PdfStamp> get stamps => widget.controller?.stamps ?? List.unmodifiable(_stamps);

  void clearStamps() {
    if (widget.controller != null) {
      widget.controller!.clearStamps();
    } else {
      setState(() {
        _stamps.clear();
        widget.onStampsChanged?.call(stamps);
      });
    }
  }

  void _addStamp(PdfStamp stamp) {
    if (widget.controller != null) {
      widget.controller!.addStamp(stamp);
    } else {
      setState(() {
        _stamps.add(stamp);
        widget.onStampsChanged?.call(stamps);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    _previousStampCount = stamps.length;
    if (widget.controller != null) {
      _previousSelectedIndices = List<int>.from(widget.controller!.selectedIndices);
    }
    _materializePdfToTempFileIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PdfStampEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (!listEquals(oldWidget.pdfBytes, widget.pdfBytes)) {
      _materializePdfToTempFileIfNeeded();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final currentCount = stamps.length;
    if (widget.controller != null && _previousStampCount > currentCount) {
      final deletedIndices = _pendingDeletedIndices ?? _previousSelectedIndices;
      if (deletedIndices.isNotEmpty) {
        widget.onStampDeleted?.call(List<int>.from(deletedIndices));
      }
      _pendingDeletedIndices = null;
    }
    _previousStampCount = currentCount;
    if (widget.controller != null) {
      _previousSelectedIndices = List<int>.from(widget.controller!.selectedIndices);
    }
    setState(() {
      widget.onStampsChanged?.call(stamps);
    });
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
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.delete) &&
              widget.controller != null &&
              widget.controller!.selectedIndices.isNotEmpty) {
            _pendingDeletedIndices = List<int>.from(widget.controller!.selectedIndices);
            widget.controller!.deleteSelectedStamps();
          }
        },
        child: Builder(
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
                      stamps: stamps,
                      controller: widget.controller,
                      enableDrag: widget.enableDrag,
                      enableResize: widget.enableResize,
                      enableRotate: widget.enableRotate,
                      enableSelection: widget.enableSelection,
                      onStampSelected: widget.onStampSelected,
                      onStampUpdated: widget.onStampUpdated,
                      stampBuilder: widget.stampBuilder,
                      onTapDown: (offset) {
                        final png = widget.pngBytes;
                        if (png == null) {
                          _snack('Pick a PNG first.');
                          return;
                        }
                        final pdfPt = PdfCoordinateConverter.viewerOffsetToPdfPoint(
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
                        _addStamp(stamp);
                        widget.onTapDown?.call();
                      },
                      onLongPressDown: (offset) {
                        final pdfPt = PdfCoordinateConverter.viewerOffsetToPdfPoint(
                          page: page,
                          localOffsetTopLeft: offset,
                          scaledPageSizePx: pageRect.size,
                        );
                        _addStamp(
                          TextStamp(
                            pageIndex: page.pageNumber - 1,
                            centerXPt: pdfPt.x,
                            centerYPt: pdfPt.y,
                            rotationDeg: widget.stampRotationDeg,
                            text: 'APPROVED',
                            fontSizePt: 18,
                          ),
                        );
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
                    stamps: stamps,
                    controller: widget.controller,
                    enableDrag: widget.enableDrag,
                    enableResize: widget.enableResize,
                    enableRotate: widget.enableRotate,
                    enableSelection: widget.enableSelection,
                    onTapDown: (offset) {
                      final png = widget.pngBytes;
                      if (png == null) {
                        _snack('Pick a PNG first.');
                        return;
                      }
                      final pdfPt = PdfCoordinateConverter.viewerOffsetToPdfPoint(
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
                      _addStamp(stamp);
                      widget.onTapDown?.call();
                    },
                    onLongPressDown: (offset) {
                      final pdfPt = PdfCoordinateConverter.viewerOffsetToPdfPoint(
                        page: page,
                        localOffsetTopLeft: offset,
                        scaledPageSizePx: pageRect.size,
                      );
                      _addStamp(
                        TextStamp(
                          pageIndex: page.pageNumber - 1,
                          centerXPt: pdfPt.x,
                          centerYPt: pdfPt.y,
                          rotationDeg: widget.stampRotationDeg,
                          text: 'APPROVED',
                          fontSizePt: 18,
                        ),
                      );
                      widget.onLongPressDown?.call();
                    },
                  ),
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }
}

/// A widget that draws stamps on top of one page AND captures taps inside that page.
class _PageOverlay extends StatelessWidget {
  const _PageOverlay({
    required this.page,
    required this.stamps,
    required this.controller,
    required this.enableDrag,
    required this.enableResize,
    required this.enableRotate,
    required this.enableSelection,
    this.onStampSelected,
    this.onStampUpdated,
    this.stampBuilder,
    required this.onTapDown,
    required this.onLongPressDown,
  });

  final PdfPage page;
  final List<PdfStamp> stamps;
  final PdfStampEditorController? controller;
  final bool enableDrag;
  final bool enableResize;
  final bool enableRotate;
  final bool enableSelection;
  final void Function(int index, PdfStamp stamp)? onStampSelected;
  final void Function(int index, PdfStamp stamp)? onStampUpdated;
  final Widget Function(BuildContext context, PdfStamp stamp, PdfPage page, Size scaledPageSizePx, Offset position)? stampBuilder;
  final void Function(Offset localOffsetTopLeft) onTapDown;
  final void Function(Offset localOffsetTopLeft) onLongPressDown;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledPageSizePx =
            Size(constraints.maxWidth, constraints.maxHeight);

        final pageStamps = <PdfStamp>[];
        final pageStampIndices = <int>[];
        for (var i = 0; i < stamps.length; i++) {
          if (stamps[i].pageIndex == page.pageNumber - 1) {
            pageStamps.add(stamps[i]);
            pageStampIndices.add(i);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) {
            if (controller != null) {
              final tappedPoint = d.localPosition;
              bool hitAnyStamp = false;
              for (var i = 0; i < pageStamps.length; i++) {
                final stamp = pageStamps[i];
                final stampPosPx = PdfCoordinateConverter.pdfPointToViewerOffset(
                  page: page,
                  xPt: stamp.centerXPt,
                  yPt: stamp.centerYPt,
                  scaledPageSizePx: scaledPageSizePx,
                );
                if (stamp case ImageStamp s) {
                  final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
                  final wPx = s.widthPt * scale.sx;
                  final hPx = s.heightPt * scale.sy;
                  final stampRect = Rect.fromLTWH(
                    stampPosPx.dx - wPx / 2,
                    stampPosPx.dy - hPx / 2,
                    wPx,
                    hPx,
                  );
                  if (stampRect.contains(tappedPoint)) {
                    hitAnyStamp = true;
                    break;
                  }
                } else if (stamp case TextStamp s) {
                  final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
                  final fontPx = s.fontSizePt * scale.sy;
                  final stampRect = Rect.fromLTWH(
                    stampPosPx.dx,
                    stampPosPx.dy,
                    fontPx * 2,
                    fontPx,
                  );
                  if (stampRect.contains(tappedPoint)) {
                    hitAnyStamp = true;
                    break;
                  }
                }
              }
              if (!hitAnyStamp) {
                controller!.clearSelection();
              }
            }
            onTapDown(d.localPosition);
          },
          onLongPressStart: (d) => onLongPressDown(d.localPosition),
          child: Stack(
            children: [
              for (var i = 0; i < pageStamps.length; i++)
                enableDrag && controller != null
                    ? DraggableStampWidget(
                        stamp: pageStamps[i],
                        stampIndex: pageStampIndices[i],
                        page: page,
                        scaledPageSizePx: scaledPageSizePx,
                        controller: controller!,
                        onStampSelected: onStampSelected,
                        onStampUpdated: onStampUpdated,
                        enableResize: enableResize,
                        enableRotate: enableRotate,
                        enableSelection: enableSelection,
                      )
                    : _buildStampWidget(
                        context: context,
                        stamp: pageStamps[i],
                        page: page,
                        scaledPageSizePx: scaledPageSizePx,
                        stampBuilder: stampBuilder,
                      ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStampWidget({
    required BuildContext context,
    required PdfStamp stamp,
    required PdfPage page,
    required Size scaledPageSizePx,
    Widget Function(BuildContext context, PdfStamp stamp, PdfPage page, Size scaledPageSizePx, Offset position)? stampBuilder,
  }) {
    // Convert PDF point -> viewer local offset (top-left origin)
    final posPx = PdfCoordinateConverter.pdfPointToViewerOffset(
      page: page,
      xPt: stamp.centerXPt,
      yPt: stamp.centerYPt,
      scaledPageSizePx: scaledPageSizePx,
    );

    if (stampBuilder != null) {
      return Positioned(
        left: posPx.dx,
        top: posPx.dy,
        child: stampBuilder(context, stamp, page, scaledPageSizePx, posPx),
      );
    }

    if (stamp case ImageStamp s) {
      final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
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
      final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
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

