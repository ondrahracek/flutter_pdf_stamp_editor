# pdf_stamp_editor

A Flutter package for viewing PDFs with stamp overlays and exporting stamped PDFs on mobile platforms.

## Features

- 📄 **PDF Viewing**: Display PDFs using the powerful `pdfrx` viewer
- 🖼️ **Stamp Placement**: Place and position image or text stamps on PDF pages
- 💾 **PDF Export**: Export stamped PDFs with vector-based stamping (mobile only)
- 🌐 **Web Support**: View and place stamps on web (export disabled)
- 🎨 **Customizable**: Support for both PNG image stamps and text stamps with configurable size and rotation

## Platform Support

- ✅ **Mobile** (iOS/Android): Full support including export
- ⚠️ **Web**: View and place stamps only (export not supported)
- ❌ **Desktop** (Windows/macOS/Linux): Not currently supported

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pdf_stamp_editor: ^0.1.0
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Required if you may touch pdfrx engine / PdfDocument APIs early.
  pdfrxFlutterInitialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfStampEditorPage(
        pdfBytes: yourPdfBytes, // Uint8List from file/network
        pngBytes: yourStampImageBytes, // Optional: Uint8List PNG image
        stampWidthPt: 140, // Optional: stamp width in points (default: 140)
        stampRotationDeg: 0, // Optional: rotation in degrees (default: 0)
      ),
    );
  }
}
```

### Exporting Stamped PDFs (Mobile Only)

For exporting on mobile platforms (Android/iOS), use the `PdfiumStamper` class:

```dart
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

// In your export handler:
final outBytes = await PdfiumStamper.applyStamps(
  inputPdfBytes: pdfBytes,
  stamps: stamps, // List<PdfStamp> from PdfStampEditorPage
);
// Save or share outBytes
```

The export functionality uses native implementations:
- **Android**: PdfBox-Android library
- **iOS**: PDFKit framework

## Example

See the `example/` directory for a complete working example.

## Architecture

The package is organized into three main components:

- **Model** (`PdfStamp`): Data model representing stamps with position, size, rotation, and content
- **Engine** (`PdfiumStamper`): Native platform-based engine for applying stamps to PDFs (Android: PdfBox, iOS: PDFKit)
- **UI** (`PdfStampEditorPage`): Flutter widget providing the stamp placement interface
- **Utilities** (`PdfCoordinateConverter`): Coordinate conversion utilities for custom UI implementations

### Coordinate Conversion Utilities

The `PdfCoordinateConverter` class provides utilities for converting between PDF coordinate space (points, bottom-left origin) and screen/viewer coordinate space (pixels, top-left origin). This is useful when building custom UI implementations that need to interact with PDF coordinates.

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

// Convert screen coordinates to PDF coordinates
PdfPoint pdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
  page: pdfPage, // PdfPage from pdfrx
  localOffsetTopLeft: Offset(100, 100), // Screen position (top-left origin)
  scaledPageSizePx: Size(612, 792), // Displayed page size in pixels
);

// Convert PDF coordinates to screen coordinates
Offset screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
  page: pdfPage,
  xPt: 100.0, // PDF X coordinate (bottom-left origin)
  yPt: 692.0, // PDF Y coordinate (bottom-left origin)
  scaledPageSizePx: Size(612, 792),
);

// Calculate scale factors for a page
final scaleFactors = PdfCoordinateConverter.pageScaleFactors(
  pdfPage,
  Size(306, 396), // Scaled page size
);
print('X scale: ${scaleFactors.sx}, Y scale: ${scaleFactors.sy}');

// Convert rotation enum/int to degrees
int degrees = PdfCoordinateConverter.rotationToDegrees(
  PdfPageRotation.clockwise90, // or int value like 90
);
```

All methods handle PDF page rotations (0°, 90°, 180°, 270°) correctly. The converter respects PDF's bottom-left origin coordinate system while working with Flutter's top-left origin screen coordinates.

## Dependencies

- `pdfrx`: PDF viewing and rendering
- `image`: PNG image processing
- `file_picker`: File selection (optional)
- `path_provider`: File system access (optional)
- `path`: Path manipulation utilities

## Limitations

- Web export is not supported. For web export, consider:
  - Using a backend service
  - Implementing a JavaScript/WASM-based PDF writer
  - Using a different PDF manipulation library for web
- Desktop platforms (Windows/macOS/Linux) are not currently supported
- Stamps are placed with preset size and rotation; interactive editing (drag, resize, rotate) of placed stamps is not available

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Additional Information

For more information, issues, or feature requests, please visit the [GitHub repository](https://github.com/ondrahracek/flutter_pdf_stamp_editor).
