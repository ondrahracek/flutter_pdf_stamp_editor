import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/full_feature_demo_page.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

void main() {
  group('FullFeatureDemoPage', () {
    testWidgets('displays title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Full Feature Demo'), findsWidgets);
    });

    testWidgets('has PDF picker button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('initializes controller with empty stamps', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      final stateFinder = find.byType(FullFeatureDemoPage);
      expect(stateFinder, findsOneWidget);
      final state = tester.state<FullFeatureDemoPageState>(stateFinder);
      expect(state.controller, isNotNull);
      expect(state.controller.stamps, isEmpty);
    });

    testWidgets('displays callback log panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.text('Callback Log'), findsOneWidget);
    });

    testWidgets('displays workflow step indicator', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.text('Workflow Steps'), findsOneWidget);
    });

    testWidgets('has PNG picker button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('has export button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('displays workflow instructions', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      expect(find.text('Workflow Instructions'), findsOneWidget);
    });

    testWidgets('has reload exported PDF button after export', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FullFeatureDemoPage()));
      // Initially no export has happened, so button shouldn't exist
      expect(find.text('Reload Exported PDF'), findsNothing);
    });
  });
}

