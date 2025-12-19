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
    this.minWidthPt,
    this.minHeightPt,
    this.maxWidthPt,
    this.maxHeightPt,
  });

  final PdfStamp stamp;
  final int stampIndex;
  final PdfPage page;
  final Size scaledPageSizePx;
  final PdfStampEditorController controller;
  final double? minWidthPt;
  final double? minHeightPt;
  final double? maxWidthPt;
  final double? maxHeightPt;

  @override
  State<DraggableStampWidget> createState() => _DraggableStampWidgetState();
}

class _DraggableStampWidgetState extends State<DraggableStampWidget> {
  Offset? _initialLocalPos;
  Offset? _initialPageCenterPos;
  PdfStamp? _originalStamp;
  double? _initialWidthPt;
  double? _initialHeightPt;

  void _cancelDrag() {
    final originalStamp = _originalStamp;
    _initialLocalPos = null;
    _initialPageCenterPos = null;
    _originalStamp = null;
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
          onScaleStart: (details) {
            if (details.pointerCount > 1) {
              _initialWidthPt = s.widthPt;
              _initialHeightPt = s.heightPt;
            } else {
              _initialLocalPos = details.localFocalPoint;
              _initialPageCenterPos = posPx;
              _originalStamp = s.copyWith();
            }
          },
          onScaleUpdate: (details) {
            if (details.pointerCount > 1) {
              if (_initialWidthPt == null || _initialHeightPt == null) return;

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
            }
          },
          onScaleEnd: (_) {
            _initialWidthPt = null;
            _initialHeightPt = null;
            _initialLocalPos = null;
            _initialPageCenterPos = null;
            _originalStamp = null;
          },
          child: Transform.rotate(
            angle: s.rotationDeg * math.pi / 180,
            child: Image.memory(s.pngBytes, fit: BoxFit.fill),
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
          onPanStart: (details) {
            _initialLocalPos = details.localPosition;
            _initialPageCenterPos = posPx;
            _originalStamp = s.copyWith();
          },
          onPanUpdate: (details) {
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
          },
          onPanEnd: (_) {
            _initialLocalPos = null;
            _initialPageCenterPos = null;
            _originalStamp = null;
          },
          onPanCancel: _cancelDrag,
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
        ),
      );
    } else {
      positionedChild = const SizedBox.shrink();
    }

    return positionedChild;
  }
}

