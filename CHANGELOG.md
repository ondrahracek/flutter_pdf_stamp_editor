## 0.3.0

### Features

* **Cross-Page Dragging**: Stamps can now be dragged seamlessly across different PDF pages without interruption

### Improvements

* **Code Cleanup**: Removed unused export-related private functions from `PdfStampEditorPage`

### Backward Compatibility

All changes are backward compatible. Existing code will continue to work without modification.

## 0.2.0

### Features

* **Configuration System**: Added comprehensive configuration classes for customizing stamp behavior
  * `TextStampConfig` - Configure default text stamp text, font size, color, and weight
  * `ImageStampConfig` - Configure image stamp dimensions and aspect ratio behavior
  * `SelectionConfig` - Configure selection border styling (color and width)
  * `webSourceName` parameter - Configurable source name for web PDF viewer

* **Image Aspect Ratio Computation**: Automatic height computation from actual PNG image dimensions
  * When `ImageStampConfig.maintainAspectRatio` is true and `heightPt` is null, height is computed from image dimensions
  * Image dimensions are cached for performance
  * Falls back to default aspect ratio (0.35) if decoding fails

### Improvements

* **UI Cleanup**: Removed enforced AppBar for cleaner PDF viewer experience
* **Better UX**: Removed error message when tapping without PNG selected (silent no-op)
* **Layout Fixes**: Widget now properly expands to maximum height without breaking layout constraints
* **Code Quality**: Removed excessive debug logging that spammed console output

### API Changes

* New parameters added to `PdfStampEditorPage`:
  * `textStampConfig` (default: `TextStampConfig()`)
  * `imageStampConfig` (default: `ImageStampConfig()`)
  * `selectionConfig` (default: `SelectionConfig()`)
  * `webSourceName` (default: `'stamped.pdf'`)

* New configuration classes:
  * `TextStampConfig` - Configuration for text stamp creation and styling
  * `ImageStampConfig` - Configuration for image stamp creation
  * `SelectionConfig` - Configuration for selection visual styling

### Backward Compatibility

All changes are backward compatible. Existing code will continue to work with sensible defaults.

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
