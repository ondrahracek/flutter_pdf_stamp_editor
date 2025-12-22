import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdfrx/pdfrx.dart';

import '../controller/pdf_stamp_editor_controller.dart';
import '../model/pdf_stamp.dart';
import '../utils/coordinate_converter.dart';
import 'pdf_stamp_editor_page.dart';

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
    this.selectionConfig,
    this.pageRects,
    this.pages,
    this.isVisible = true,
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
  final SelectionConfig? selectionConfig;
  final Map<int, Rect>? pageRects;
  final Map<int, PdfPage>? pages;
  final bool isVisible;

  @override
  State<DraggableStampWidget> createState() => _DraggableStampWidgetState();
}

class _DraggableStampWidgetState extends State<DraggableStampWidget> {
  Offset? _initialLocalPos;
  Offset? _initialGlobalPos;
  PdfStamp? _originalStamp;
  double? _initialWidthPt;
  double? _initialHeightPt;
  double? _initialFontSizePt;
  double? _initialRotationDeg;
  int? _currentPageIndex;
  bool _hasMoved = false;

  /// Determines which page index a global coordinate belongs to by checking
  /// which page rect contains the coordinate.
  int? _getPageIndexFromGlobalCoordinate(Offset globalCoordinate) {
    if (widget.pageRects == null) return null;
    for (final entry in widget.pageRects!.entries) {
      if (entry.value.contains(globalCoordinate)) {
        return entry.key;
      }
    }
    return null;
  }

  void _cancelDrag() {
    widget.controller.setDraggingStamp(null);
    final originalStamp = _originalStamp;
    _initialLocalPos = null;
    _originalStamp = null;
    _initialWidthPt = null;
    _initialHeightPt = null;
    _initialFontSizePt = null;
    _initialRotationDeg = null;
    _currentPageIndex = null;
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

  Widget _buildDeleteButton(
    DeleteButtonConfig deleteConfig,
    double stampLeft,
    double stampTop,
    double stampWidth,
    double stampHeight,
    bool isSelected,
  ) {
    // Position button relative to visual stamp content, not expanded bounding box
    // When selected, stamp coordinates include hitAreaExpansion, so we need to adjust
    const hitAreaExpansion = 40.0;
    final visualStampTop = isSelected ? stampTop + hitAreaExpansion : stampTop;
    final visualStampRight = isSelected
        ? (stampLeft + stampWidth) - hitAreaExpansion
        : stampLeft + stampWidth;

    // Position button so its top-right corner aligns with visual stamp's top-right corner
    // Then apply offset to move it slightly outside
    // Positioned widget uses left/top for top-left corner, so we subtract width
    final buttonLeft =
        visualStampRight - deleteConfig.hitAreaSize + deleteConfig.offsetX;
    final buttonTop = visualStampTop + deleteConfig.offsetY;

    return Positioned(
      left: buttonLeft,
      top: buttonTop,
      width: deleteConfig.hitAreaSize,
      height: deleteConfig.hitAreaSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.controller.removeStamp(widget.stampIndex);
        },
        child: Center(
          child: Container(
            width: deleteConfig.size,
            height: deleteConfig.size,
            decoration: BoxDecoration(
              color: deleteConfig.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: deleteConfig.elevation,
                  offset: Offset(0, deleteConfig.elevation / 2),
                ),
              ],
            ),
            child: Icon(
              deleteConfig.icon,
              color: deleteConfig.iconColor,
              size: deleteConfig.size * 0.6,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isSelected = widget.controller.isSelected(widget.stampIndex);
        // Define a hit area expansion for selected stamps to make them easier to gesture on.
        const hitAreaExpansion = 40.0;

        final posPx = PdfCoordinateConverter.pdfPointToViewerOffset(
          page: widget.page,
          xPt: widget.stamp.centerXPt,
          yPt: widget.stamp.centerYPt,
          scaledPageSizePx: widget.scaledPageSizePx,
        );

        Widget positionedChild;
        double? stampLeft;
        double? stampTop;
        double? stampWidth;
        double? stampHeight;

        if (widget.stamp case ImageStamp s) {
          final scale = PdfCoordinateConverter.pageScaleFactors(
            widget.page,
            widget.scaledPageSizePx,
          );
          final wPx = s.widthPt * scale.sx;
          final hPx = s.heightPt * scale.sy;

          stampLeft = posPx.dx - wPx / 2 - (isSelected ? hitAreaExpansion : 0);
          stampTop = posPx.dy - hPx / 2 - (isSelected ? hitAreaExpansion : 0);
          stampWidth = wPx + (isSelected ? hitAreaExpansion * 2 : 0);
          stampHeight = hPx + (isSelected ? hitAreaExpansion * 2 : 0);

          positionedChild = Positioned(
            left: stampLeft,
            top: stampTop,
            width: stampWidth,
            height: stampHeight,
            child: Opacity(
              opacity: widget.isVisible ? 1.0 : 0.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (isSelected) {
                    // If already selected, only count as a "hit" if it's within the actual visual bounds.
                    // This allows tapping in the expanded hit area to deselect (fall through to background).
                    final localPos = details.localPosition;
                    final contentRect = Rect.fromLTWH(
                      isSelected ? hitAreaExpansion : 0,
                      isSelected ? hitAreaExpansion : 0,
                      wPx,
                      hPx,
                    );
                    if (!contentRect.contains(localPos)) {
                      return;
                    }
                  }

                  if (!_hasMoved && widget.enableSelection) {
                    widget.controller.selectStamp(widget.stampIndex);
                    widget.onStampSelected
                        ?.call(widget.stampIndex, widget.stamp);
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
                    widget.controller.setDraggingStamp(widget.stampIndex,
                        dragStartPageIndex: widget.stamp.pageIndex);
                    _initialLocalPos = details.localFocalPoint;
                    _originalStamp = s.copyWith();
                    _currentPageIndex = widget.stamp.pageIndex;
                    if (widget.pageRects != null) {
                      final currentPageRect =
                          widget.pageRects![widget.stamp.pageIndex];
                      if (currentPageRect != null) {
                        _initialGlobalPos = currentPageRect.topLeft + posPx;
                      }
                    }
                  }
                },
                onScaleUpdate: (details) {
                  _hasMoved = true;
                  if (details.pointerCount > 1) {
                    // Initialize initial values if they haven't been set yet
                    _initialWidthPt ??= s.widthPt;
                    _initialHeightPt ??= s.heightPt;
                    _initialRotationDeg ??= s.rotationDeg;

                    if (widget.enableRotate &&
                        _initialRotationDeg != null &&
                        details.rotation.abs() > 0.01) {
                      var newRotationDeg = _initialRotationDeg! +
                          details.rotation * 180 / math.pi;
                      newRotationDeg = newRotationDeg % 360;
                      if (newRotationDeg < 0) newRotationDeg += 360;

                      if (widget.rotationSnapDegrees != null) {
                        newRotationDeg =
                            (newRotationDeg / widget.rotationSnapDegrees!)
                                    .round() *
                                widget.rotationSnapDegrees!;
                      }

                      final updatedStamp = s.copyWith(
                        rotationDeg: newRotationDeg,
                      );

                      widget.controller
                          .updateStamp(widget.stampIndex, updatedStamp);
                      widget.onStampUpdated
                          ?.call(widget.stampIndex, updatedStamp);
                    } else if (widget.enableResize &&
                        _initialWidthPt != null &&
                        _initialHeightPt != null) {
                      var newWidthPt = _initialWidthPt! * details.scale;
                      var newHeightPt = _initialHeightPt! * details.scale;

                      if (widget.minWidthPt != null) {
                        newWidthPt = math.max(newWidthPt, widget.minWidthPt!);
                      }
                      if (widget.minHeightPt != null) {
                        newHeightPt =
                            math.max(newHeightPt, widget.minHeightPt!);
                      }
                      if (widget.maxWidthPt != null) {
                        newWidthPt = math.min(newWidthPt, widget.maxWidthPt!);
                      }
                      if (widget.maxHeightPt != null) {
                        newHeightPt =
                            math.min(newHeightPt, widget.maxHeightPt!);
                      }

                      final updatedStamp = s.copyWith(
                        widthPt: newWidthPt,
                        heightPt: newHeightPt,
                      );

                      widget.controller
                          .updateStamp(widget.stampIndex, updatedStamp);
                      widget.onStampUpdated
                          ?.call(widget.stampIndex, updatedStamp);
                    }
                  } else {
                    if (_initialLocalPos == null || _initialGlobalPos == null) {
                      return;
                    }

                    final currentLocalPos = details.localFocalPoint;
                    final deltaLocal = currentLocalPos - _initialLocalPos!;

                    // Calculate global position using the initial global position as anchor
                    final currentGlobalPos = _initialGlobalPos! + deltaLocal;

                    // Detect which page we're on
                    final detectedPageIndex = widget.pageRects != null
                        ? _getPageIndexFromGlobalCoordinate(currentGlobalPos)
                        : null;

                    if (detectedPageIndex != null && widget.pages != null) {
                      // Update current page index if it changed
                      if (detectedPageIndex != _currentPageIndex) {
                        _currentPageIndex = detectedPageIndex;
                      }

                      final targetPage = widget.pages![_currentPageIndex]!;
                      final targetPageRect =
                          widget.pageRects![_currentPageIndex]!;

                      // Convert global position to local position on the target page
                      final localPosOnPage =
                          currentGlobalPos - targetPageRect.topLeft;

                      // Convert local pixels to PDF points
                      final newPdfPoint =
                          PdfCoordinateConverter.viewerOffsetToPdfPoint(
                        page: targetPage,
                        localOffsetTopLeft: localPosOnPage,
                        scaledPageSizePx: targetPageRect.size,
                      );

                      final updatedStamp = s.copyWith(
                        pageIndex: _currentPageIndex,
                        centerXPt: newPdfPoint.x,
                        centerYPt: newPdfPoint.y,
                      );

                      widget.controller
                          .updateStamp(widget.stampIndex, updatedStamp);
                      widget.onStampUpdated
                          ?.call(widget.stampIndex, updatedStamp);
                    }
                  }
                },
                onScaleEnd: (_) {
                  widget.controller.setDraggingStamp(null);
                  if (!_hasMoved && widget.enableSelection) {
                    widget.controller.selectStamp(widget.stampIndex);
                    widget.onStampSelected
                        ?.call(widget.stampIndex, widget.stamp);
                  }
                  _initialWidthPt = null;
                  _initialHeightPt = null;
                  _initialRotationDeg = null;
                  _initialLocalPos = null;
                  _originalStamp = null;
                  _currentPageIndex = null;
                  _hasMoved = false;
                },
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.all(isSelected ? hitAreaExpansion : 0),
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border.all(
                              color: widget.selectionConfig?.borderColor ??
                                  Colors.blue,
                              width: widget.selectionConfig?.borderWidth ?? 2.0,
                            ),
                          )
                        : null,
                    child: Transform.rotate(
                      angle: s.rotationDeg * math.pi / 180,
                      child: Image.memory(s.pngBytes, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (widget.stamp case TextStamp s) {
          final scale = PdfCoordinateConverter.pageScaleFactors(
            widget.page,
            widget.scaledPageSizePx,
          );
          final fontPx = s.fontSizePt * scale.sy;

          final textPainter = TextPainter(
            text: TextSpan(
              text: s.text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          // Re-layout with correct font size for accurate measurement
          textPainter.text = TextSpan(
            text: s.text,
            style: TextStyle(
              fontSize: fontPx,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          final wPx = textPainter.width;
          final hPx = textPainter.height;

          stampLeft = posPx.dx - wPx / 2 - (isSelected ? hitAreaExpansion : 0);
          stampTop = posPx.dy - hPx / 2 - (isSelected ? hitAreaExpansion : 0);
          stampWidth = wPx + (isSelected ? hitAreaExpansion * 2 : 0);
          stampHeight = hPx + (isSelected ? hitAreaExpansion * 2 : 0);

          positionedChild = Positioned(
            left: stampLeft,
            top: stampTop,
            width: stampWidth,
            height: stampHeight,
            child: Opacity(
              opacity: widget.isVisible ? 1.0 : 0.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (isSelected) {
                    // If already selected, only count as a "hit" if it's within the actual visual bounds.
                    // This allows tapping in the expanded hit area to deselect (fall through to background).
                    final localPos = details.localPosition;
                    final contentRect = Rect.fromLTWH(
                      isSelected ? hitAreaExpansion : 0,
                      isSelected ? hitAreaExpansion : 0,
                      wPx,
                      hPx,
                    );
                    if (!contentRect.contains(localPos)) {
                      return;
                    }
                  }

                  if (!_hasMoved && widget.enableSelection) {
                    widget.controller.selectStamp(widget.stampIndex);
                    widget.onStampSelected
                        ?.call(widget.stampIndex, widget.stamp);
                  }
                  _hasMoved = false;
                },
                onScaleStart: (details) {
                  _hasMoved = false;
                  if (details.pointerCount > 1) {
                    _initialFontSizePt = s.fontSizePt;
                    _initialRotationDeg = s.rotationDeg;
                  } else {
                    widget.controller.setDraggingStamp(widget.stampIndex,
                        dragStartPageIndex: widget.stamp.pageIndex);
                    _initialLocalPos = details.localFocalPoint;
                    _originalStamp = s.copyWith();
                    _currentPageIndex = widget.stamp.pageIndex;
                    if (widget.pageRects != null) {
                      final currentPageRect =
                          widget.pageRects![widget.stamp.pageIndex];
                      if (currentPageRect != null) {
                        _initialGlobalPos = currentPageRect.topLeft + posPx;
                      }
                    }
                  }
                },
                onScaleUpdate: (details) {
                  _hasMoved = true;
                  if (details.pointerCount > 1) {
                    // Initialize initial values if they haven't been set yet
                    _initialFontSizePt ??= s.fontSizePt;
                    _initialRotationDeg ??= s.rotationDeg;

                    if (widget.enableRotate &&
                        _initialRotationDeg != null &&
                        details.rotation.abs() > 0.01) {
                      var newRotationDeg = _initialRotationDeg! +
                          details.rotation * 180 / math.pi;
                      newRotationDeg = newRotationDeg % 360;
                      if (newRotationDeg < 0) newRotationDeg += 360;

                      if (widget.rotationSnapDegrees != null) {
                        newRotationDeg =
                            (newRotationDeg / widget.rotationSnapDegrees!)
                                    .round() *
                                widget.rotationSnapDegrees!;
                      }

                      final updatedStamp = s.copyWith(
                        rotationDeg: newRotationDeg,
                      );

                      widget.controller
                          .updateStamp(widget.stampIndex, updatedStamp);
                      widget.onStampUpdated
                          ?.call(widget.stampIndex, updatedStamp);
                    } else if (widget.enableResize &&
                        _initialFontSizePt != null) {
                      var newFontSize = _initialFontSizePt! * details.scale;

                      if (widget.minHeightPt != null) {
                        newFontSize =
                            math.max(newFontSize, widget.minHeightPt!);
                      }
                      if (widget.maxHeightPt != null) {
                        newFontSize =
                            math.min(newFontSize, widget.maxHeightPt!);
                      }

                      final updatedStamp = s.copyWith(
                        fontSizePt: newFontSize,
                      );

                      widget.controller
                          .updateStamp(widget.stampIndex, updatedStamp);
                      widget.onStampUpdated
                          ?.call(widget.stampIndex, updatedStamp);
                    }
                  } else {
                    if (_initialLocalPos == null || _initialGlobalPos == null) {
                      return;
                    }

                    final currentLocalPos = details.localFocalPoint;
                    final deltaLocal = currentLocalPos - _initialLocalPos!;

                    // Calculate global position using the initial global position as anchor
                    final currentGlobalPos = _initialGlobalPos! + deltaLocal;

                    // Detect which page we're on
                    final detectedPageIndex = widget.pageRects != null
                        ? _getPageIndexFromGlobalCoordinate(currentGlobalPos)
                        : null;

                    if (detectedPageIndex != null && widget.pages != null) {
                      // Update current page index if it changed
                      if (detectedPageIndex != _currentPageIndex) {
                        _currentPageIndex = detectedPageIndex;
                      }

                      final targetPage = widget.pages![_currentPageIndex]!;
                      final targetPageRect =
                          widget.pageRects![_currentPageIndex]!;

                      // Convert global position to local position on the target page
                      final localPosOnPage =
                          currentGlobalPos - targetPageRect.topLeft;

                      // Convert local pixels to PDF points
                      final newPdfPoint =
                          PdfCoordinateConverter.viewerOffsetToPdfPoint(
                        page: targetPage,
                        localOffsetTopLeft: localPosOnPage,
                        scaledPageSizePx: targetPageRect.size,
                      );

                      final updatedStamp = s.copyWith(
                        pageIndex: _currentPageIndex,
                        centerXPt: newPdfPoint.x,
                        centerYPt: newPdfPoint.y,
                      );

                      widget.controller
                          .updateStamp(widget.stampIndex, updatedStamp);
                      widget.onStampUpdated
                          ?.call(widget.stampIndex, updatedStamp);
                    }
                  }
                },
                onScaleEnd: (_) {
                  widget.controller.setDraggingStamp(null);
                  if (!_hasMoved && widget.enableSelection) {
                    widget.controller.selectStamp(widget.stampIndex);
                    widget.onStampSelected
                        ?.call(widget.stampIndex, widget.stamp);
                  }
                  _initialFontSizePt = null;
                  _initialRotationDeg = null;
                  _initialLocalPos = null;
                  _originalStamp = null;
                  _currentPageIndex = null;
                  _hasMoved = false;
                },
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.all(isSelected ? hitAreaExpansion : 0),
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border.all(
                              color: widget.selectionConfig?.borderColor ??
                                  Colors.blue,
                              width: widget.selectionConfig?.borderWidth ?? 2.0,
                            ),
                          )
                        : null,
                    child: Transform.rotate(
                      angle: s.rotationDeg * math.pi / 180,
                      child: Text(
                        s.text,
                        style: TextStyle(
                          fontSize: fontPx,
                          fontWeight: FontWeight.bold,
                          color: s.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          positionedChild = const SizedBox.shrink();
        }

        // Wrap in Stack to add delete button overlay when selected
        final deleteConfig =
            isSelected ? widget.selectionConfig?.deleteButtonConfig : null;
        if (deleteConfig != null &&
            deleteConfig.enabled &&
            stampLeft != null &&
            stampTop != null &&
            stampWidth != null &&
            stampHeight != null) {
          // Extract non-null values (flow analysis ensures they're non-null here)
          final left = stampLeft;
          final top = stampTop;
          final width = stampWidth;
          final height = stampHeight;
          return Stack(
            children: [
              positionedChild,
              _buildDeleteButton(
                deleteConfig,
                left,
                top,
                width,
                height,
                isSelected,
              ),
            ],
          );
        }

        return positionedChild;
      },
    );
  }
}
