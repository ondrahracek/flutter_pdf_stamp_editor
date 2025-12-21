# pdf_stamp_editor

A Flutter package for viewing PDFs with stamp overlays and exporting stamped PDFs on mobile platforms.

## Features

- 📄 **PDF Viewing**: Display PDFs using the powerful `pdfrx` viewer
- 🖼️ **Stamp Placement**: Place and position image or text stamps on PDF pages
- ✏️ **Interactive Editing**: Drag, resize, rotate, and select stamps with gestures
- 💾 **PDF Export**: Export stamped PDFs with vector-based stamping (mobile only)
- 🎮 **Programmatic Control**: Full API for adding, updating, and managing stamps
- 🌐 **Web Support**: View and place stamps on web (export disabled)
- 🎨 **Customizable**: Support for both PNG image stamps and text stamps with custom rendering

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

### Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';
// For loading files, you might also need:
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';

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
    // Load PDF bytes from file, network, or assets
    // Example: final pdfBytes = await FilePicker.platform.pickFiles(...);
    // Example: final pdfBytes = await http.get(...).then((r) => r.bodyBytes);

    return MaterialApp(
      home: PdfStampEditorPage(
        pdfBytes: pdfBytes, // Uint8List from file/network/assets
        pngBytes: pngBytes, // Optional: Uint8List PNG image for stamp placement
      ),
    );
  }
}
```

## Usage

### Basic Stamp Placement

Place stamps by tapping or long-pressing on the PDF:

- **Tap**: Places an image stamp (requires `pngBytes` to be set)
- **Long Press**: Places a text stamp with "APPROVED" text

```dart
PdfStampEditorPage(
  pdfBytes: pdfBytes,
  pngBytes: pngBytes, // Required for tap-to-place image stamps
  stampWidthPt: 140, // Optional: stamp width in points (default: 140)
  stampRotationDeg: 0, // Optional: rotation in degrees (default: 0)
  onStampsChanged: (stamps) {
    print('Stamps count: ${stamps.length}');
  },
)
```

### Interactive Editing

Enable drag, resize, rotate, and selection gestures:

```dart
PdfStampEditorPage(
  pdfBytes: pdfBytes,
  enableDrag: true,      // Enable drag gestures (default: false)
  enableResize: true,    // Enable pinch-to-resize (default: true)
  enableRotate: true,    // Enable rotation gestures (default: true)
  enableSelection: true, // Enable tap-to-select (default: true)
)
```

**Gestures:**

- **Drag**: Tap and hold a stamp, then drag to move it (requires `enableDrag: true` and a `controller`)
- **Resize**: Pinch to zoom on a stamp to resize it
- **Rotate**: Use rotation gesture (two fingers) on a stamp to rotate it
- **Select**: Tap a stamp to select it (shows blue border)
- **Delete**: Select stamps and press Backspace/Delete key (requires a `controller`)

### Programmatic Control

Use `PdfStampEditorController` for programmatic stamp management:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

class MyEditorPage extends StatefulWidget {
  @override
  State<MyEditorPage> createState() => _MyEditorPageState();
}

class _MyEditorPageState extends State<MyEditorPage> {
  late final PdfStampEditorController controller;
  Uint8List? pngBytes; // Load from file picker, network, or assets

  @override
  void initState() {
    super.initState();
    controller = PdfStampEditorController();
    controller.addListener(() {
      print('Stamps changed: ${controller.stamps.length}');
    });
    // Load PNG bytes (e.g., from file picker or assets)
    // _loadPngBytes();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _addStamp() {
    if (pngBytes == null) return; // Ensure PNG is loaded

    final stamp = ImageStamp(
      pageIndex: 0,
      centerXPt: 200.0,
      centerYPt: 300.0,
      rotationDeg: 0.0,
      pngBytes: pngBytes!,
      widthPt: 100.0,
      heightPt: 50.0,
    );
    controller.addStamp(stamp);
  }

  @override
  Widget build(BuildContext context) {
    return PdfStampEditorPage(
      pdfBytes: pdfBytes,
      controller: controller,
      enableDrag: true,
      enableResize: true,
      enableRotate: true,
      enableSelection: true,
    );
  }
}
```

**Controller Methods:**

- `addStamp(stamp)` - Add a stamp programmatically
- `updateStamp(index, stamp)` - Update stamp at index
- `removeStamp(index)` - Remove stamp at index
- `clearStamps()` - Remove all stamps
- `selectStamp(index, {toggle})` - Select/deselect stamp
- `clearSelection()` - Clear all selections
- `deleteSelectedStamps()` - Delete all selected stamps
- `isSelected(index)` - Check if stamp is selected

### Exporting PDFs

Export stamped PDFs on mobile platforms (Android/iOS):

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

Future<void> exportPdf(Uint8List pdfBytes, List<PdfStamp> stamps) async {
  try {
    final outBytes = await PdfStampEditorExporter.applyStamps(
      inputPdfBytes: pdfBytes,
      stamps: stamps, // List<PdfStamp> from PdfStampEditorPage
    );

    // Save or share outBytes
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/stamped.pdf');
    await file.writeAsBytes(outBytes);
    print('Exported to: ${file.path}');
  } catch (e) {
    print('Export failed: $e');
  }
}
```

**Note:** Export requires FFI/PDFium and is only available on mobile platforms. The export functionality uses native implementations:

- **Android**: PdfBox-Android library
- **iOS**: PDFKit framework

## Advanced Features

### Callbacks

Monitor stamp changes with callbacks:

```dart
PdfStampEditorPage(
  pdfBytes: pdfBytes,
  onStampsChanged: (stamps) {
    // Called when stamps list changes (add/remove)
  },
  onStampSelected: (index, stamp) {
    // Called when a stamp is selected
  },
  onStampUpdated: (index, stamp) {
    // Called when a stamp is updated (drag/resize/rotate)
  },
  onStampDeleted: (indices) {
    // Called when stamps are deleted
  },
  onTapDown: () {
    // Called when tapping to place image stamp
  },
  onLongPressDown: () {
    // Called when long-pressing to place text stamp
  },
  onImageStampPlaced: () {
    // Called after image stamp is placed
  },
)
```

### Custom Stamp Rendering

Customize stamp appearance with `stampBuilder`. The builder must return a `Widget` - if you want default rendering for some types, handle them explicitly or omit the `stampBuilder` parameter:

```dart
import 'dart:math' as math;
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';
import 'package:pdfrx/pdfrx.dart';

PdfStampEditorPage(
  pdfBytes: pdfBytes,
  stampBuilder: (context, stamp, page, scaledPageSize, position) {
    if (stamp is ImageStamp) {
      // Custom rendering for ImageStamp
      final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSize);
      final wPx = stamp.widthPt * scale.sx;
      final hPx = stamp.heightPt * scale.sy;

      return Container(
        width: wPx,
        height: hPx,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: stamp.rotationDeg * math.pi / 180,
          child: Image.memory(stamp.pngBytes, fit: BoxFit.fill),
        ),
      );
    } else if (stamp is TextStamp) {
      // Custom rendering for TextStamp
      final scale = PdfCoordinateConverter.pageScaleFactors(page, scaledPageSize);
      final fontPx = stamp.fontSizePt * scale.sy;

      return Transform.rotate(
        angle: stamp.rotationDeg * math.pi / 180,
        child: Text(
          stamp.text,
          style: TextStyle(
            fontSize: fontPx,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
    }
    // Handle all stamp types or omit stampBuilder to use defaults
    return const SizedBox.shrink();
  },
)
```

### Coordinate Conversion

Convert between PDF coordinates and screen coordinates for custom implementations. Note: `PdfPoint` and `PdfPage` are from the `pdfrx` package:

```dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

// Convert screen coordinates to PDF coordinates
PdfPoint pdfPoint = PdfCoordinateConverter.viewerOffsetToPdfPoint(
  page: pdfPage, // PdfPage from pdfrx
  localOffsetTopLeft: Offset(100, 100), // Screen position
  scaledPageSizePx: Size(612, 792), // Displayed page size
);

// Convert PDF coordinates to screen coordinates
Offset screenOffset = PdfCoordinateConverter.pdfPointToViewerOffset(
  page: pdfPage,
  xPt: 100.0, // PDF X coordinate (bottom-left origin)
  yPt: 692.0, // PDF Y coordinate (bottom-left origin)
  scaledPageSizePx: Size(612, 792),
);

// Get scale factors for a page
final scaleFactors = PdfCoordinateConverter.pageScaleFactors(
  pdfPage,
  Size(306, 396), // Scaled page size
);
```

All methods handle PDF page rotations (0°, 90°, 180°, 270°) correctly.

## Example App

See the `example/` directory for a complete working example demonstrating:

- Basic stamp placement
- Interactive editing with gestures
- Programmatic control with controller
- All callback APIs
- Custom stamp rendering
- Coordinate conversion utilities
- Complete workflow from placement to export

Run the example:

```bash
cd example
flutter run
```

## API Reference

| Class                      | Description                                  |
| -------------------------- | -------------------------------------------- |
| `PdfStampEditorPage`       | Main widget for PDF stamp editing            |
| `PdfStampEditorController` | Controller for programmatic stamp management |
| `PdfStamp`                 | Base class for stamps (sealed)               |
| `ImageStamp`               | Image stamp with PNG bytes                   |
| `TextStamp`                | Text stamp with customizable text            |
| `PdfStampEditorExporter`   | Export engine for applying stamps to PDFs    |
| `PdfCoordinateConverter`   | Utilities for coordinate conversion          |
| `MatrixCalculator`         | Calculate PDF transformation matrices        |

For detailed API documentation, see the [API reference](https://pub.dev/documentation/pdf_stamp_editor/latest/) (available after publishing to pub.dev).

## Limitations

- **Web export**: Not supported (requires FFI/PDFium). Consider using a backend service or JavaScript/WASM-based PDF writer for web export.
- **Desktop platforms**: Windows/macOS/Linux are not currently supported
- **Concurrent operations**: The PDF viewer must be hidden during export to prevent concurrent PDFium calls

## Dependencies

- `pdfrx`: PDF viewing and rendering
- `image`: PNG image processing
- `file_picker`: File selection (optional)
- `path_provider`: File system access (optional)
- `path`: Path manipulation utilities

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Additional Information

For more information, issues, or feature requests, please visit the [GitHub repository](https://github.com/ondrahracek/flutter_pdf_stamp_editor).
