import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdfrx/pdfrx.dart';

import '../controller/pdf_stamp_editor_controller.dart';
import '../model/pdf_stamp.dart';
import '../utils/coordinate_converter.dart';

class DraggableStampWidget extends StatefulWidget {
  const DraggableStampWidget({
    super.key,
    required this.stamp,
    required this.stampIndex,
    required this.page,
    required this.scaledPageSizePx,
    required this.controller,
    this.onStampSelected,
    this.onStampUpdated,
    this.enableResize = true,
    this.enableRotate = true,
    this.enableSelection = true,
    this.minWidthPt,
    this.minHeightPt,
    this.maxWidthPt,
    this.maxHeightPt,
    this.rotationSnapDegrees,
  });

  final PdfStamp stamp;
  final int stampIndex;
  final PdfPage page;
  final Size scaledPageSizePx;
  final PdfStampEditorController controller;
  final void Function(int index, PdfStamp stamp)? onStampSelected;
  final void Function(int index, PdfStamp stamp)? onStampUpdated;
  final bool enableResize;
  final bool enableRotate;
  final bool enableSelection;
  final double? minWidthPt;
  final double? minHeightPt;
  final double? maxWidthPt;
  final double? maxHeightPt;
  final double? rotationSnapDegrees;

  @override
  State<DraggableStampWidget> createState() => _DraggableStampWidgetState();
}

class _DraggableStampWidgetState extends State<DraggableStampWidget> {
  Offset? _initialLocalPos;
  Offset? _initialPageCenterPos;
  PdfStamp? _originalStamp;
  double? _initialWidthPt;
  double? _initialHeightPt;
  double? _initialRotationDeg;
  bool _hasMoved = false;

  void _cancelDrag() {
    final originalStamp = _originalStamp;
    _initialLocalPos = null;
    _initialPageCenterPos = null;
    _originalStamp = null;
    _initialWidthPt = null;
    _initialHeightPt = null;
    _initialRotationDeg = null;
    _hasMoved = false;
    if (originalStamp != null) {
      widget.controller.updateStamp(widget.stampIndex, originalStamp);
    }
  }

  @override
  void deactivate() {
    if (_originalStamp != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_originalStamp != null) {
          _cancelDrag();
        }
      });
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final posPx = PdfCoordinateConverter.pdfPointToViewerOffset(
      page: widget.page,
      xPt: widget.stamp.centerXPt,
      yPt: widget.stamp.centerYPt,
      scaledPageSizePx: widget.scaledPageSizePx,
    );

    Widget positionedChild;
    if (widget.stamp case ImageStamp s) {
      final scale = PdfCoordinateConverter.pageScaleFactors(
        widget.page,
        widget.scaledPageSizePx,
      );
      final wPx = s.widthPt * scale.sx;
      final hPx = s.heightPt * scale.sy;

      positionedChild = Positioned(
        left: posPx.dx - wPx / 2,
        top: posPx.dy - hPx / 2,
        width: wPx,
        height: hPx,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_hasMoved && widget.enableSelection) {
              widget.controller.selectStamp(widget.stampIndex);
              widget.onStampSelected?.call(widget.stampIndex, widget.stamp);
            }
            _hasMoved = false;
          },
          onScaleStart: (details) {
            _hasMoved = false;
            if (details.pointerCount > 1) {
              _initialWidthPt = s.widthPt;
              _initialHeightPt = s.heightPt;
              _initialRotationDeg = s.rotationDeg;
            } else {
              _initialLocalPos = details.localFocalPoint;
              _initialPageCenterPos = posPx;
              _originalStamp = s.copyWith();
            }
          },
          onScaleUpdate: (details) {
            _hasMoved = true;
            if (details.pointerCount > 1) {
              if (widget.enableRotate && _initialRotationDeg != null && details.rotation.abs() > 0.01) {
                var newRotationDeg = _initialRotationDeg! + details.rotation * 180 / math.pi;
                newRotationDeg = newRotationDeg % 360;
                if (newRotationDeg < 0) newRotationDeg += 360;

                if (widget.rotationSnapDegrees != null) {
                  newRotationDeg = (newRotationDeg / widget.rotationSnapDegrees!).round() * widget.rotationSnapDegrees!;
                }

                final updatedStamp = s.copyWith(
                  rotationDeg: newRotationDeg,
                );

                widget.controller.updateStamp(widget.stampIndex, updatedStamp);
                widget.onStampUpdated?.call(widget.stampIndex, updatedStamp);
              } else if (widget.enableResize && _initialWidthPt != null && _initialHeightPt != null) {
                var newWidthPt = _initialWidthPt! * details.scale;
                var newHeightPt = _initialHeightPt! * details.scale;

                if (widget.minWidthPt != null) {
                  newWidthPt = math.max(newWidthPt, widget.minWidthPt!);
                }
                if (widget.minHeightPt != null) {
                  newHeightPt = math.max(newHeightPt, widget.minHeightPt!);
                }
                if (widget.maxWidthPt != null) {
                  newWidthPt = math.min(newWidthPt, widget.maxWidthPt!);
                }
                if (widget.maxHeightPt != null) {
                  newHeightPt = math.min(newHeightPt, widget.maxHeightPt!);
                }

                final updatedStamp = s.copyWith(
                  widthPt: newWidthPt,
                  heightPt: newHeightPt,
                );

                widget.controller.updateStamp(widget.stampIndex, updatedStamp);
                widget.onStampUpdated?.call(widget.stampIndex, updatedStamp);
              }
            } else {
              if (_initialLocalPos == null || _initialPageCenterPos == null) return;

              final currentLocalPos = details.localFocalPoint;
              final deltaLocal = currentLocalPos - _initialLocalPos!;

              final newPagePos = _initialPageCenterPos! + deltaLocal;
              final newPdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
                page: widget.page,
                localOffsetTopLeft: newPagePos,
                scaledPageSizePx: widget.scaledPageSizePx,
              );

              final updatedStamp = s.copyWith(
                centerXPt: newPdfPoint.x,
                centerYPt: newPdfPoint.y,
              );

              widget.controller.updateStamp(widget.stampIndex, updatedStamp);
              widget.onStampUpdated?.call(widget.stampIndex, updatedStamp);
            }
          },
          onScaleEnd: (_) {
            _initialWidthPt = null;
            _initialHeightPt = null;
            _initialRotationDeg = null;
            _initialLocalPos = null;
            _initialPageCenterPos = null;
            _originalStamp = null;
            _hasMoved = false;
          },
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final isSelected = widget.controller.isSelected(widget.stampIndex);
              final content = Transform.rotate(
                angle: s.rotationDeg * math.pi / 180,
                child: Image.memory(s.pngBytes, fit: BoxFit.fill),
              );

              if (isSelected) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  child: content,
                );
              }

              return content;
            },
          ),
        ),
      );
    } else if (widget.stamp case TextStamp s) {
      final scale = PdfCoordinateConverter.pageScaleFactors(
        widget.page,
        widget.scaledPageSizePx,
      );
      final fontPx = s.fontSizePt * scale.sy;

      positionedChild = Positioned(
        left: posPx.dx,
        top: posPx.dy,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _hasMoved = false;
            _initialLocalPos = details.localPosition;
            _initialPageCenterPos = posPx;
            _originalStamp = s.copyWith();
          },
          onPanUpdate: (details) {
            _hasMoved = true;
            if (_initialLocalPos == null || _initialPageCenterPos == null) return;

            final currentLocalPos = details.localPosition;
            final deltaLocal = currentLocalPos - _initialLocalPos!;

            final newPagePos = _initialPageCenterPos! + deltaLocal;
            final newPdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
              page: widget.page,
              localOffsetTopLeft: newPagePos,
              scaledPageSizePx: widget.scaledPageSizePx,
            );

            final updatedStamp = s.copyWith(
              centerXPt: newPdfPoint.x,
              centerYPt: newPdfPoint.y,
            );

            widget.controller.updateStamp(widget.stampIndex, updatedStamp);
            widget.onStampUpdated?.call(widget.stampIndex, updatedStamp);
          },
          onPanEnd: (_) {
            if (!_hasMoved && widget.enableSelection) {
              widget.controller.selectStamp(widget.stampIndex);
              widget.onStampSelected?.call(widget.stampIndex, widget.stamp);
            }
            _initialLocalPos = null;
            _initialPageCenterPos = null;
            _originalStamp = null;
            _hasMoved = false;
          },
          onPanCancel: _cancelDrag,
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final isSelected = widget.controller.isSelected(widget.stampIndex);
              final content = Transform.rotate(
                angle: s.rotationDeg * math.pi / 180,
                child: Text(
                  s.text,
                  style: TextStyle(
                    fontSize: fontPx,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              );

              if (isSelected) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  child: content,
                );
              }

              return content;
            },
          ),
        ),
      );
    } else {
      positionedChild = const SizedBox.shrink();
    }

    return positionedChild;
  }
}

