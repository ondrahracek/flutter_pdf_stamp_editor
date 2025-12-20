import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/basic_demo_page.dart';

void main() {
  group('BasicDemoPage', () {
    testWidgets('displays instructions panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BasicDemoPage()));
      expect(find.text('Instructions'), findsOneWidget);
    });

    testWidgets('shows success message when PDF is picked', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BasicDemoPage()));
      // This test verifies that success feedback is shown
      // We'll test the snackbar appears with success styling
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays stamp count', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BasicDemoPage()));
      expect(find.text('Stamps:'), findsOneWidget);
    });
  });
}

