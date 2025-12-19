import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfCoordinateConverter {
  static int rotationToDegrees(Object rotation) {
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
    return 0;
  }

  static PdfPoint viewerOffsetToPdfPoint({
    required PdfPage page,
    required Offset localOffsetTopLeft,
    required Size scaledPageSizePx,
  }) {
    final rot = rotationToDegrees(page.rotation);
    return localOffsetTopLeft.toPdfPoint(
      page: page,
      scaledPageSize: scaledPageSizePx,
      rotation: rot,
    );
  }

  static Offset pdfPointToViewerOffset({
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

  static ({double sx, double sy}) pageScaleFactors(
    PdfPage page,
    Size scaledPageSizePx,
  ) {
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
}

