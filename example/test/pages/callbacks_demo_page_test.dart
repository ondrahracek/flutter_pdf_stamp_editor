import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/callbacks_demo_page.dart';

void main() {
  group('CallbacksDemoPage', () {
    testWidgets('displays title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CallbacksDemoPage()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Callbacks Demo'), findsWidgets);
    });

    testWidgets('displays callback log panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CallbacksDemoPage()));

      expect(find.text('Callback Log'), findsWidgets);
    });

    testWidgets('displays callback statistics panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CallbacksDemoPage()));

      expect(find.text('Statistics'), findsWidgets);
    });

    testWidgets('has clear log button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CallbacksDemoPage()));

      expect(find.text('Clear Log'), findsWidgets);
    });

    testWidgets('displays stamp details panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CallbacksDemoPage()));

      expect(find.text('Stamp Details'), findsWidgets);
    });

    testWidgets('has PDF picker button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CallbacksDemoPage()));

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });
  });
}

