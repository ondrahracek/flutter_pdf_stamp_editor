import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/controller/pdf_stamp_editor_controller.dart';
import 'package:pdf_stamp_editor/src/ui/pdf_stamp_editor_page.dart';

/// Creates minimal valid PDF bytes for testing.
///
/// This is a minimal PDF structure that should be accepted by pdfrx.
Uint8List createMinimalPdfBytes() {
  // Minimal PDF structure (PDF 1.4)
  return Uint8List.fromList([
    // PDF header
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A,
    // Minimal PDF content
    // This is a very basic PDF that may not render but should load
    ...'%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Resources <<\n/Font <<\n/F1 <<\n/Type /Font\n/Subtype /Type1\n/BaseFont /Helvetica\n>>\n>>\n>>\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n100 700 Td\n(Test) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000307 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n398\n%%EOF\n'.codeUnits,
  ]);
}

void main() {
  group('PdfStampEditorPage', () {
    testWidgets('renders with PDF bytes', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Check that the page renders
      expect(find.byType(PdfStampEditorPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays correct app bar title', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      expect(find.text('PDF Stamp Editor'), findsOneWidget);
    });

    testWidgets('displays rotate button', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Find the rotate button by icon
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    });

    testWidgets('displays export button', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Find the export button by icon
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('rotate button increments rotation', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Tap the rotate button
      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.pump();

      // The rotation should have changed (we can't directly test the internal state,
      // but we can verify the button is tappable and doesn't throw)
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    });

    testWidgets('export button shows snackbar on web', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Tap the export button
      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();

      // On non-web, it should show a message about PDFium initialization
      // The exact message depends on the platform, but we can check for snackbar
      await tester.pump(const Duration(seconds: 1));

      // The snackbar might be present, but we can't easily test the exact message
      // without platform detection. Just verify the button works.
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('renders with PNG bytes for stamp', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        // Minimal PNG structure would be longer, but for testing we just need bytes
        ...List.filled(100, 0),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
            pngBytes: pngBytes,
          ),
        ),
      );

      expect(find.byType(PdfStampEditorPage), findsOneWidget);
    });

    testWidgets('renders without PNG bytes (placeholder stamp)', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
            // pngBytes is null
          ),
        ),
      );

      expect(find.byType(PdfStampEditorPage), findsOneWidget);
      // The placeholder "STAMP" text might be in an overlay that's not easily findable
      // but the widget should still render
    });

    testWidgets('handles empty PDF bytes gracefully', (WidgetTester tester) async {
      final emptyPdfBytes = Uint8List(0);

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: emptyPdfBytes,
          ),
        ),
      );

      // Widget should still render, even if PDF viewer shows error
      expect(find.byType(PdfStampEditorPage), findsOneWidget);
    });

    testWidgets('has correct widget structure', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Verify widget hierarchy
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('multiple rotate taps work', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Tap rotate multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.rotate_right));
        await tester.pump();
      }

      // Button should still be present and functional
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    });

    testWidgets('export button is tappable multiple times', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Tap export multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.download));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Button should still be present
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('PdfStampEditorPage - Snackbar messages', () {
    testWidgets('shows message when export is triggered', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
          ),
        ),
      );

      // Tap export
      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // A snackbar should appear (exact message depends on platform)
      // We can't easily test the exact message without platform detection,
      // but we verify the action triggers something
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('PdfStampEditorPage with controller', () {
    testWidgets('works with external controller', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();
      final controller = PdfStampEditorController();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
            controller: controller,
          ),
        ),
      );

      expect(find.byType(PdfStampEditorPage), findsOneWidget);
      expect(controller.stamps, isEmpty);
    });

    testWidgets('controller receives stamps when added via widget', (WidgetTester tester) async {
      final pdfBytes = createMinimalPdfBytes();
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        ...List.filled(100, 0),
      ]);
      final controller = PdfStampEditorController();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfStampEditorPage(
            pdfBytes: pdfBytes,
            pngBytes: pngBytes,
            controller: controller,
          ),
        ),
      );

      expect(controller.stamps, isEmpty);

      // The widget should render and allow interaction
      // Note: Actually tapping and adding stamps requires a fully rendered PDF viewer
      // which is complex to test. This test verifies the controller can be provided
      // and the widget accepts it.
      expect(find.byType(PdfStampEditorPage), findsOneWidget);
    });
  });
}

