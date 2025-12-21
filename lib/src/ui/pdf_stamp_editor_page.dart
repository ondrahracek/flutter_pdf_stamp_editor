import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

/// Configuration for default text stamp creation and styling
class TextStampConfig {
  /// Text to add on long press. If null, long press is disabled.
  final String? text;

  /// Font size in points for the default text stamp
  final double fontSizePt;

  /// Text color when using default rendering (ignored if custom stampBuilder is provided)
  final Color color;

  /// Font weight when using default rendering (ignored if custom stampBuilder is provided)
  final FontWeight fontWeight;

  const TextStampConfig({
    this.text = 'APPROVED',
    this.fontSizePt = 18,
    this.color = Colors.red,
    this.fontWeight = FontWeight.bold,
  });

  /// Disables text stamp creation on long press
  const TextStampConfig.disabled()
      : text = null,
        fontSizePt = 18,
        color = Colors.red,
        fontWeight = FontWeight.bold;
}

/// Configuration for default image stamp creation
class ImageStampConfig {
  /// Width in points for image stamps
  final double widthPt;

  /// Height in points for image stamps. If null, height is computed from image aspect ratio.
  final double? heightPt;

  /// If true and heightPt is null, compute height from actual image dimensions.
  /// If false, uses default aspect ratio (0.35).
  final bool maintainAspectRatio;

  const ImageStampConfig({
    this.widthPt = 140,
    this.heightPt,
    this.maintainAspectRatio = true,
  });

  /// Use explicit width and height (ignores aspect ratio)
  const ImageStampConfig.explicit({
    required this.widthPt,
    required this.heightPt,
  }) : maintainAspectRatio = false;
}

/// Configuration for selection visual styling
class SelectionConfig {
  final Color borderColor;
  final double borderWidth;

  const SelectionConfig({
    this.borderColor = Colors.blue,
    this.borderWidth = 2.0,
  });
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
  final PdfStampEditorController? controller;
  final bool enableDrag;
  final bool enableResize;
  final bool enableRotate;
  final bool enableSelection;
  final ValueChanged<List<PdfStamp>>? onStampsChanged;
  final void Function(int index, PdfStamp stamp)? onStampSelected;
  final void Function(int index, PdfStamp stamp)? onStampUpdated;
  final void Function(List<int> indices)? onStampDeleted;
  final Widget Function(BuildContext context, PdfStamp stamp, PdfPage page,
      Size scaledPageSizePx, Offset position)? stampBuilder;
  final VoidCallback? onTapDown;
  final VoidCallback? onLongPressDown;
  final VoidCallback? onImageStampPlaced;

  final TextStampConfig textStampConfig;
  final ImageStampConfig imageStampConfig;
  final SelectionConfig selectionConfig;
  final String webSourceName;

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
    this.onImageStampPlaced,
    this.textStampConfig = const TextStampConfig(),
    this.imageStampConfig = const ImageStampConfig(),
    this.selectionConfig = const SelectionConfig(),
    this.webSourceName = 'stamped.pdf',
  });

  @override
  State<PdfStampEditorPage> createState() => _PdfStampEditorPageState();
}

class _PdfStampEditorPageState extends State<PdfStampEditorPage> {
  final List<PdfStamp> _stamps = [];
  File? _tempPdfFile; // Materialized PDF for viewer on non-web platforms
  List<int>? _pendingDeletedIndices;
  int _previousStampCount = 0;
  List<int> _previousSelectedIndices = [];
  final Map<int, Size> _imageDimensionCache = {};

  List<PdfStamp> get stamps =>
      widget.controller?.stamps ?? List.unmodifiable(_stamps);

  Future<void> _cacheImageDimensions(Uint8List? pngBytes) async {
    if (pngBytes == null) {
      _imageDimensionCache.clear();
      return;
    }

    final hash = pngBytes.hashCode;
    if (_imageDimensionCache.containsKey(hash)) {
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      _imageDimensionCache[hash] = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PdfStampEditor] Failed to decode image dimensions: $e');
      }
    }
  }

  double? _getImageAspectRatio(Uint8List? pngBytes) {
    if (pngBytes == null) return null;
    final hash = pngBytes.hashCode;
    final dimensions = _imageDimensionCache[hash];
    if (dimensions == null || dimensions.width == 0) return null;
    return dimensions.height / dimensions.width;
  }

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
      _previousSelectedIndices =
          List<int>.from(widget.controller!.selectedIndices);
    }
    _materializePdfToTempFileIfNeeded();
    _cacheImageDimensions(widget.pngBytes);
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
    if (oldWidget.pngBytes != widget.pngBytes) {
      _cacheImageDimensions(widget.pngBytes);
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
      _previousSelectedIndices =
          List<int>.from(widget.controller!.selectedIndices);
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

  @override
  Widget build(BuildContext context) {
    final pdfBytes = widget.pdfBytes;

    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.delete) &&
              widget.controller != null &&
              widget.controller!.selectedIndices.isNotEmpty) {
            _pendingDeletedIndices =
                List<int>.from(widget.controller!.selectedIndices);
            widget.controller!.deleteSelectedStamps();
          }
        },
        child: Builder(
          builder: (context) {
            if (pdfBytes.isEmpty) {
              return const Center(child: Text('No PDF loaded.'));
            }

            // Web: in‑memory bytes
            if (kIsWeb) {
              return SizedBox.expand(
                child: PdfViewer.data(
                  pdfBytes,
                  sourceName: widget.webSourceName,
                  params: PdfViewerParams(
                    pageOverlaysBuilder: (context, pageRect, page) {
                      return [
                        Positioned(
                          left: 0,
                          top: 0,
                          width: pageRect.size.width,
                          height: pageRect.size.height,
                          child: _PageOverlay(
                            page: page,
                            scaledPageSizePx: pageRect.size,
                            stamps: stamps,
                            controller: widget.controller,
                            enableDrag: widget.enableDrag,
                            enableResize: widget.enableResize,
                            enableRotate: widget.enableRotate,
                            enableSelection: widget.enableSelection,
                            onStampSelected: widget.onStampSelected,
                            onStampUpdated: widget.onStampUpdated,
                            stampBuilder: widget.stampBuilder,
                            textStampConfig: widget.textStampConfig,
                            selectionConfig: widget.selectionConfig,
                            onTapDown: (offset) {
                              final png = widget.pngBytes;
                              if (png == null) {
                                return;
                              }
                              final pdfPt =
                                  PdfCoordinateConverter.viewerOffsetToPdfPoint(
                                page: page,
                                localOffsetTopLeft: offset,
                                scaledPageSizePx: pageRect.size,
                              );
                              final config = widget.imageStampConfig;
                              double heightPt;
                              if (config.heightPt != null) {
                                heightPt = config.heightPt!;
                              } else if (config.maintainAspectRatio) {
                                final aspectRatio = _getImageAspectRatio(png);
                                heightPt = aspectRatio != null
                                    ? config.widthPt * aspectRatio
                                    : config.widthPt * 0.35;
                              } else {
                                heightPt = config.widthPt * 0.35;
                              }

                              final stamp = ImageStamp(
                                pageIndex: page.pageNumber - 1,
                                centerXPt: pdfPt.x,
                                centerYPt: pdfPt.y,
                                rotationDeg: widget.stampRotationDeg,
                                pngBytes: png,
                                widthPt: config.widthPt,
                                heightPt: heightPt,
                              );
                              _addStamp(stamp);
                              widget.onTapDown?.call();
                              widget.onImageStampPlaced?.call();
                            },
                            onLongPressDown: (offset) {
                              final config = widget.textStampConfig;

                              if (config.text == null) {
                                widget.onLongPressDown?.call();
                                return;
                              }

                              final pdfPt =
                                  PdfCoordinateConverter.viewerOffsetToPdfPoint(
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
                                  text: config.text!,
                                  fontSizePt: config.fontSizePt,
                                ),
                              );
                              widget.onLongPressDown?.call();
                            },
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              );
            }

            // Native: temp file
            if (_tempPdfFile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SizedBox.expand(
              child: PdfViewer.file(
                _tempPdfFile!.path,
                params: PdfViewerParams(
                  pageOverlaysBuilder: (context, pageRect, page) {
                    return [
                      Positioned(
                        left: 0,
                        top: 0,
                        width: pageRect.size.width,
                        height: pageRect.size.height,
                        child: _PageOverlay(
                          page: page,
                          scaledPageSizePx: pageRect.size,
                          stamps: stamps,
                          controller: widget.controller,
                          enableDrag: widget.enableDrag,
                          enableResize: widget.enableResize,
                          enableRotate: widget.enableRotate,
                          enableSelection: widget.enableSelection,
                          onStampSelected: widget.onStampSelected,
                          onStampUpdated: widget.onStampUpdated,
                          stampBuilder: widget.stampBuilder,
                          textStampConfig: widget.textStampConfig,
                          selectionConfig: widget.selectionConfig,
                          onTapDown: (offset) {
                            final png = widget.pngBytes;
                            if (png == null) {
                              return;
                            }
                            final pdfPt =
                                PdfCoordinateConverter.viewerOffsetToPdfPoint(
                              page: page,
                              localOffsetTopLeft: offset,
                              scaledPageSizePx: pageRect.size,
                            );
                            final config = widget.imageStampConfig;
                            double heightPt;
                            if (config.heightPt != null) {
                              heightPt = config.heightPt!;
                            } else if (config.maintainAspectRatio) {
                              final aspectRatio = _getImageAspectRatio(png);
                              heightPt = aspectRatio != null
                                  ? config.widthPt * aspectRatio
                                  : config.widthPt * 0.35;
                            } else {
                              heightPt = config.widthPt * 0.35;
                            }

                            final stamp = ImageStamp(
                              pageIndex: page.pageNumber - 1,
                              centerXPt: pdfPt.x,
                              centerYPt: pdfPt.y,
                              rotationDeg: widget.stampRotationDeg,
                              pngBytes: png,
                              widthPt: config.widthPt,
                              heightPt: heightPt,
                            );
                            _addStamp(stamp);
                            widget.onTapDown?.call();
                            widget.onImageStampPlaced?.call();
                          },
                          onLongPressDown: (offset) {
                            final config = widget.textStampConfig;

                            if (config.text == null) {
                              widget.onLongPressDown?.call();
                              return;
                            }

                            final pdfPt =
                                PdfCoordinateConverter.viewerOffsetToPdfPoint(
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
                                text: config.text!,
                                fontSizePt: config.fontSizePt,
                              ),
                            );
                            widget.onLongPressDown?.call();
                          },
                        ),
                      ),
                    ];
                  },
                ),
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
    required this.scaledPageSizePx,
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
    required this.textStampConfig,
    required this.selectionConfig,
  });

  final PdfPage page;
  final Size scaledPageSizePx;
  final List<PdfStamp> stamps;
  final PdfStampEditorController? controller;
  final bool enableDrag;
  final bool enableResize;
  final bool enableRotate;
  final bool enableSelection;
  final void Function(int index, PdfStamp stamp)? onStampSelected;
  final void Function(int index, PdfStamp stamp)? onStampUpdated;
  final Widget Function(BuildContext context, PdfStamp stamp, PdfPage page,
      Size scaledPageSizePx, Offset position)? stampBuilder;
  final void Function(Offset localOffsetTopLeft) onTapDown;
  final void Function(Offset localOffsetTopLeft) onLongPressDown;
  final TextStampConfig textStampConfig;
  final SelectionConfig selectionConfig;

  @override
  Widget build(BuildContext context) {
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
              final scale = PdfCoordinateConverter.pageScaleFactors(
                  page, scaledPageSizePx);
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
              final scale = PdfCoordinateConverter.pageScaleFactors(
                  page, scaledPageSizePx);
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
                    selectionConfig: selectionConfig,
                  )
                : _buildStampWidget(
                    context: context,
                    stamp: pageStamps[i],
                    page: page,
                    scaledPageSizePx: scaledPageSizePx,
                    stampBuilder: stampBuilder,
                    textStampConfig: textStampConfig,
                  ),
        ],
      ),
    );
  }

  Widget _buildStampWidget({
    required BuildContext context,
    required PdfStamp stamp,
    required PdfPage page,
    required Size scaledPageSizePx,
    Widget Function(BuildContext context, PdfStamp stamp, PdfPage page,
            Size scaledPageSizePx, Offset position)?
        stampBuilder,
    required TextStampConfig textStampConfig,
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
      final scale =
          PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
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
      final scale =
          PdfCoordinateConverter.pageScaleFactors(page, scaledPageSizePx);
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
              fontWeight: textStampConfig.fontWeight,
              color: textStampConfig.color,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
