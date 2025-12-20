import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/controller_demo_page.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

void main() {
  testWidgets('ControllerDemoPage displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Controller Demo'), findsWidgets);
  });

  testWidgets('ControllerDemoPage initializes controller with empty stamps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    expect(stateFinder, findsOneWidget);
    
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    expect(state.controller, isNotNull);
    expect(state.controller.stamps, isEmpty);
  });

  testWidgets('ControllerDemoPage displays stamp count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    expect(find.text('Total Stamps'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('ControllerDemoPage has Add ImageStamp button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    expect(find.text('Add ImageStamp'), findsOneWidget);
  });

  testWidgets('Clicking Add ImageStamp button adds stamp to controller', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    expect(state.controller.stamps, isEmpty);

    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();

    expect(state.controller.stamps, hasLength(1));
    expect(state.controller.stamps[0], isA<ImageStamp>());
  });

  testWidgets('ControllerDemoPage has Add TextStamp button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    expect(find.text('Add TextStamp'), findsOneWidget);
  });

  testWidgets('Update stamp button updates first stamp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    
    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(1));
    final originalStamp = state.controller.stamps[0] as ImageStamp;
    expect(originalStamp.centerXPt, 200.0);
    
    await tester.ensureVisible(find.text('Update Stamp'));
    await tester.tap(find.text('Update Stamp'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(1));
    final updatedStamp = state.controller.stamps[0] as ImageStamp;
    expect(updatedStamp.centerXPt, isNot(equals(200.0)));
  });

  testWidgets('Remove stamp button removes last stamp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    
    await tester.tap(find.text('Add ImageStamp'));
    await tester.tap(find.text('Add TextStamp'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(2));
    
    await tester.ensureVisible(find.text('Remove Stamp'));
    await tester.tap(find.text('Remove Stamp'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(1));
  });

  testWidgets('Clear All button removes all stamps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    
    await tester.tap(find.text('Add ImageStamp'));
    await tester.tap(find.text('Add TextStamp'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(2));
    
    await tester.ensureVisible(find.text('Clear All'));
    await tester.tap(find.text('Clear All'));
    await tester.pump();
    
    expect(state.controller.stamps, isEmpty);
  });

  testWidgets('Select Stamp button selects first stamp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    
    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();
    
    expect(state.controller.selectedIndices, isEmpty);
    
    await tester.ensureVisible(find.text('Select Stamp'));
    await tester.tap(find.text('Select Stamp'));
    await tester.pump();
    
    expect(state.controller.selectedIndices, contains(0));
    expect(state.controller.isSelected(0), isTrue);
  });

  testWidgets('Clear Selection button clears selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    
    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();
    await tester.ensureVisible(find.text('Select Stamp'));
    await tester.tap(find.text('Select Stamp'));
    await tester.pump();
    
    expect(state.controller.selectedIndices, isNotEmpty);
    
    await tester.ensureVisible(find.text('Clear Selection'));
    await tester.tap(find.text('Clear Selection'));
    await tester.pump();
    
    expect(state.controller.selectedIndices, isEmpty);
  });

  testWidgets('Delete Selected button removes selected stamps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    final stateFinder = find.byType(ControllerDemoPage);
    final state = tester.state<ControllerDemoPageState>(stateFinder);
    
    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();
    await tester.ensureVisible(find.text('Add TextStamp'));
    await tester.tap(find.text('Add TextStamp'));
    await tester.pump();
    await tester.ensureVisible(find.text('Select Stamp'));
    await tester.tap(find.text('Select Stamp'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(2));
    expect(state.controller.selectedIndices, contains(0));
    
    await tester.ensureVisible(find.text('Delete Selected'));
    await tester.tap(find.text('Delete Selected'));
    await tester.pump();
    
    expect(state.controller.stamps, hasLength(1));
    expect(state.controller.selectedIndices, isEmpty);
  });

  testWidgets('ControllerDemoPage displays change log', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    expect(find.text('Change Log'), findsOneWidget);
  });

  testWidgets('Adding stamp logs change in change log', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();
    
    expect(find.textContaining('addStamp'), findsWidgets);
  });

  testWidgets('ControllerDemoPage displays stamps list when stamps exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerDemoPage(),
      ),
    );

    await tester.tap(find.text('Add ImageStamp'));
    await tester.pump();
    
    expect(find.text('[0] Image - Page 1'), findsOneWidget);
  });
}

