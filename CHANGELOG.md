## 0.1.0

Initial release of the `pdf_stamp_editor` package - a Flutter package for viewing PDFs with stamp overlays and exporting stamped PDFs on mobile platforms.

### Features

* **PDF Viewing**: Display PDFs using the powerful `pdfrx` viewer
* **Stamp Placement**: Place and position image or text stamps on PDF pages
  * Tap to place image stamps (requires PNG bytes)
  * Long-press to place text stamps
* **Interactive Editing**: Drag, resize, rotate, and select stamps with gestures
  * Enable/disable drag, resize, rotate, and selection via feature flags
  * Keyboard shortcuts (Backspace/Delete) for deleting selected stamps
* **Programmatic Control**: Full API via `PdfStampEditorController`
  * Add, update, remove stamps programmatically
  * Selection management
  * Change notifications via listeners
* **PDF Export**: Export stamped PDFs with vector-based stamping (mobile only)
  * Native implementations: PdfBox-Android (Android), PDFKit (iOS)
  * Stamps embedded as real PDF objects
* **Web Support**: View and place stamps on web (export disabled)
* **Custom Stamp Rendering**: Customize stamp appearance with `stampBuilder`
* **Coordinate Conversion**: Utilities for converting between PDF and screen coordinates
* **Matrix Calculator**: Calculate PDF transformation matrices for stamps

### API

* `PdfStampEditorPage` - Main widget for PDF stamp editing
* `PdfStampEditorController` - Controller for programmatic stamp management
* `PdfStamp`, `ImageStamp`, `TextStamp` - Stamp model classes
* `PdfStampEditorExporter` - Export engine for applying stamps to PDFs
* `PdfCoordinateConverter` - Utilities for coordinate conversion
* `MatrixCalculator` - Calculate PDF transformation matrices

### Platform Support

* ✅ **Mobile** (iOS/Android): Full support including export
* ⚠️ **Web**: View and place stamps only (export not supported)
* ❌ **Desktop** (Windows/macOS/Linux): Not currently supported

### Example

See the `example/` directory for a complete working example demonstrating all features and APIs.
