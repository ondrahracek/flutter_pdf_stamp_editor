import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/utilities_demo_page.dart';

void main() {
  group('UtilitiesDemoPage', () {
    testWidgets('displays title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Utilities Demo'), findsWidgets);
    });

    testWidgets('has PDF picker button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('displays viewerOffsetToPdfPoint section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('Tap Position → PDF Coordinates'), findsOneWidget);
    });

    testWidgets('displays tap position and PDF coordinates', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.textContaining('Screen:'), findsNothing);
      expect(find.textContaining('PDF:'), findsNothing);
    });

    testWidgets('displays pdfPointToViewerOffset section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('PDF Coordinates → Screen Position'), findsOneWidget);
    });

    testWidgets('has PDF coordinate input fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('X (points):'), findsOneWidget);
      expect(find.text('Y (points):'), findsOneWidget);
    });

    testWidgets('displays pageScaleFactors section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('Page Scale Factors'), findsOneWidget);
    });

    testWidgets('displays rotationToDegrees section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('Page Rotation'), findsOneWidget);
    });

    testWidgets('displays MatrixCalculator section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('Transformation Matrix'), findsOneWidget);
    });

    testWidgets('has test scenario buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesDemoPage()));
      expect(find.text('Test Scenarios'), findsOneWidget);
    });
  });
}

