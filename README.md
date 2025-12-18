# pdf_stamp_editor

A Flutter package for viewing PDFs with draggable stamp overlays and exporting stamped PDFs on mobile and desktop platforms.

## Features

- 📄 **PDF Viewing**: Display PDFs using the powerful `pdfrx` viewer
- 🖼️ **Draggable Stamps**: Place and position image or text stamps on PDF pages
- 🔄 **Interactive Editing**: Drag, resize, and rotate stamps with intuitive gestures
- 💾 **PDF Export**: Export stamped PDFs with vector-based stamping (mobile/desktop only)
- 🌐 **Web Support**: View and edit stamps on web (export requires backend or native implementation)
- 🎨 **Customizable**: Support for both PNG image stamps and text stamps

## Platform Support

- ✅ **Mobile** (iOS/Android): Full support including export
- ✅ **Desktop** (Windows/macOS/Linux): Full support including export
- ⚠️ **Web**: View and edit only (export disabled due to PDFium FFI limitations)

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
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
      ),
    );
  }
}
```

### Exporting Stamped PDFs (Mobile/Desktop)

For exporting on mobile/desktop platforms, you'll need to initialize PDFium:

```dart
import 'dart:ffi';
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

// Initialize PDFium (do this once, typically in your app initialization)
final pdfium = PDFium(DynamicLibrary.open('pdfium'));

// In your export handler:
final stamper = PdfStampStamper(pdfium);
final outputBytes = await stamper.applyStamps(pdfBytes, stamps);
// Save or share outputBytes
```

## Example

See the `example/` directory for a complete working example.

## Architecture

The package is organized into three main components:

- **Model** (`PdfStamp`): Data model representing stamps with position, size, rotation, and content
- **Engine** (`PdfStampStamper`): PDFium-based engine for applying stamps to PDFs (native platforms)
- **UI** (`PdfStampEditorPage`): Flutter widget providing the interactive editor interface

## Dependencies

- `pdfrx`: PDF viewing and rendering
- `pdfium_dart`: PDF manipulation and export (native platforms)
- `image`: PNG image processing
- `file_picker`: File selection (optional)
- `path_provider`: File system access (optional)

## Limitations

- Web export is not supported due to PDFium FFI requirements. For web export, consider:
  - Using a backend service
  - Implementing a JavaScript/WASM-based PDF writer
  - Using a different PDF manipulation library for web

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Additional Information

For more information, issues, or feature requests, please visit the [GitHub repository](https://github.com/ondrahracek/flutter_pdf_stamp_editor).
