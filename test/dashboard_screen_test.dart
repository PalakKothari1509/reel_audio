import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_library.dart';
import 'package:reel_audio/dashboard_screen.dart';

void main() {
  group('DashboardScreen', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dashboard_test');
      ContentLibraryStore.useDirectory(tempDir);
    });

    tearDown(() {
      ContentLibraryStore.resetDirectory();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    void _writeItems(List<ContentLibraryItem> items) {
      final path = '${tempDir.path}/content_library.json';
      final json = jsonEncode(items.map((i) => i.toJson()).toList());
      File(path).writeAsStringSync(json);
    }

    ContentLibraryItem _makeItem({
      required String id,
      required String title,
      required IdeaStatus status,
      ContentFormat format = ContentFormat.reel,
      List<String> tags = const ['challenge'],
    }) {
      return ContentLibraryItem(
        id: id,
        title: title,
        topic: 'Test topic',
        bucket: BucketLibrary.challenge,
        format: format,
        status: status,
        formatOutputs: {},
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        performanceMetrics: {},
        reuseCount: 0,
      );
    }

    testWidgets('renders section headers when loading completes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ideas by Pillar'), findsOneWidget);
      expect(find.text('Ready to Produce'), findsOneWidget);
      expect(find.text('Published by Format'), findsOneWidget);
      expect(find.text('Formats Tested < 5 Times'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh'), findsOneWidget);
    });

    testWidgets('shows empty states when no content exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ideas in the library yet.'), findsOneWidget);
      expect(find.text('Nothing ready to produce yet.'), findsOneWidget);
      expect(find.text('No published content yet.'), findsOneWidget);
    });

    testWidgets('shows ready-to-produce items when they exist', (tester) async {
      _writeItems([_makeItem(id: '1', title: 'Test Idea', status: IdeaStatus.approved, tags: ['challenge', 'play'])]);

      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 item ready'), findsOneWidget);
      expect(find.text('Test Idea'), findsOneWidget);
    });

    testWidgets('shows pillar chips with counts', (tester) async {
      _writeItems([_makeItem(id: '1', title: 'Play Idea', status: IdeaStatus.idea, tags: ['play'])]);

      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAY · 1'), findsOneWidget);
    });

    testWidgets('shows published by format when items are posted', (tester) async {
      _writeItems([_makeItem(id: '1', title: 'Posted Reel', status: IdeaStatus.posted, tags: ['challenge'])]);

      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ContentFormat.reel'), findsWidgets);
    });

    testWidgets('refresh reloads dashboard data', (tester) async {
      _writeItems([_makeItem(id: '1', title: 'Refresh Test', status: IdeaStatus.approved, tags: ['challenge'])]);

      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 item ready'), findsOneWidget);

      // Write more items and refresh
      _writeItems([
        _makeItem(id: '1', title: 'Refresh Test', status: IdeaStatus.approved, tags: ['challenge']),
        _makeItem(id: '2', title: 'Another Idea', status: IdeaStatus.approved, tags: ['challenge']),
      ]);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(find.text('2 items ready'), findsOneWidget);
    });
  });
}
