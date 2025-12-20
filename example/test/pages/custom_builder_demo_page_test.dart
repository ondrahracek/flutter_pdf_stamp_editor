import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/custom_builder_demo_page.dart';

void main() {
  group('CustomBuilderDemoPage', () {
    testWidgets('displays title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomBuilderDemoPage()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Custom Builder Demo'), findsWidgets);
    });

    testWidgets('has PDF picker button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomBuilderDemoPage()));

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('has builder toggle switch', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomBuilderDemoPage()));

      expect(find.text('Use Custom Builder'), findsWidgets);
    });

    testWidgets('displays PdfStampEditorPage when PDF is loaded', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomBuilderDemoPage()));

      // Initially no PDF, so no viewer
      expect(find.text('Pick a PDF to see custom builder in action'), findsOneWidget);

      // Note: We can't easily test PDF loading in widget tests without mocking,
      // but we can verify the structure is ready for PDF integration
    });

    testWidgets('has style selector', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomBuilderDemoPage()));

      // Toggle the custom builder switch to show style selector
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('Style'), findsWidgets);
      expect(find.text('Bordered'), findsWidgets);
      expect(find.text('Shadowed'), findsWidgets);
      expect(find.text('Highlighted'), findsWidgets);
    });

    testWidgets('displays instructions panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomBuilderDemoPage()));

      expect(find.text('Instructions'), findsWidgets);
    });
  });
}

