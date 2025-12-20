import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/features_demo_page.dart';

void main() {
  testWidgets('FeaturesDemoPage displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Features Demo'), findsWidgets);
  });

  testWidgets('FeaturesDemoPage displays feature toggle panel', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.text('Feature Flags'), findsWidgets);
    expect(find.text('Enable Drag'), findsWidgets);
    expect(find.text('Enable Resize'), findsWidgets);
    expect(find.text('Enable Rotate'), findsWidgets);
    expect(find.text('Enable Selection'), findsWidgets);
  });

  testWidgets('FeaturesDemoPage displays instructions panel', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.text('Instructions'), findsWidgets);
  });

  testWidgets('FeaturesDemoPage shows feature status indicators', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.text('Status'), findsWidgets);
    expect(find.byIcon(Icons.drag_handle), findsWidgets);
    expect(find.byIcon(Icons.aspect_ratio), findsWidgets);
    expect(find.byIcon(Icons.rotate_right), findsWidgets);
    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
  });

  testWidgets('FeaturesDemoPage has preset scenario buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.text('Drag Only'), findsWidgets);
    expect(find.text('Resize Only'), findsWidgets);
    expect(find.text('Rotate Only'), findsWidgets);
    expect(find.text('All Features'), findsWidgets);
    expect(find.text('None'), findsWidgets);
  });

  testWidgets('FeaturesDemoPage has PDF picker button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
  });

  testWidgets('FeaturesDemoPage displays dynamic instructions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesDemoPage(),
      ),
    );

    expect(find.text('Instructions'), findsWidgets);
    expect(find.textContaining('Tap and hold'), findsWidgets);
  });
}

