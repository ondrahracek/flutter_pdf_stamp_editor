import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor_example/pages/edge_cases_performance_demo_page.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

void main() {
  group('EdgeCasesPerformanceDemoPage', () {
    testWidgets('displays title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Edge Cases & Performance'), findsOneWidget);
    });

    testWidgets('has Generate Many Stamps button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.text('Generate Many Stamps'), findsOneWidget);
    });

    testWidgets('generates 50 stamps when button is clicked', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      
      final stateFinder = find.byType(EdgeCasesPerformanceDemoPage);
      expect(stateFinder, findsOneWidget);
      final state = tester.state<EdgeCasesPerformanceDemoPageState>(stateFinder);
      
      expect(state.controller.stamps, isEmpty);
      
      await tester.tap(find.text('Generate Many Stamps'));
      await tester.pumpAndSettle();
      
      expect(state.controller.stamps.length, 50);
    });

    testWidgets('has multi-page test button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.text('Multi-page Test'), findsOneWidget);
    });

    testWidgets('creates stamps on different pages when multi-page test is clicked', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      
      final stateFinder = find.byType(EdgeCasesPerformanceDemoPage);
      final state = tester.state<EdgeCasesPerformanceDemoPageState>(stateFinder);
      
      expect(state.controller.stamps, isEmpty);
      
      await tester.tap(find.text('Multi-page Test'));
      await tester.pumpAndSettle();
      
      expect(state.controller.stamps.length, greaterThan(0));
      final pageIndices = state.controller.stamps.map((s) => s.pageIndex).toSet();
      expect(pageIndices.length, greaterThan(1));
    });

    testWidgets('has edge cases test button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.text('Edge Cases Test'), findsOneWidget);
    });

    testWidgets('displays performance metrics panel', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.text('Performance Metrics'), findsOneWidget);
    });

    testWidgets('has stress test button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.text('Stress Test'), findsOneWidget);
    });

    testWidgets('has rotated page test button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EdgeCasesPerformanceDemoPage()));
      expect(find.text('Rotated Page Test'), findsOneWidget);
    });
  });
}

