import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_library.dart';
import 'package:reel_audio/home_screen.dart';

void main() {
  group('ContentStudioHome', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('home_screen_test');
      ContentLibraryStore.useDirectory(tempDir);
    });

    tearDown(() {
      ContentLibraryStore.resetDirectory();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets('renders welcome section and navigation, responds to taps', (tester) async {
      var addIdeaTapped = false;
      var createReelTapped = false;
      var settingsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onAddIdea: (_) => addIdeaTapped = true,
            onCreateReel: (_) => createReelTapped = true,
            onMyContent: () {},
            onInsights: () {},
            onSettings: () => settingsTapped = true,
            onIdeaVault: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Good morning, Palak!'), findsOneWidget);
      expect(find.text('+ Add Idea'), findsOneWidget);
      expect(find.text('Create a Reel'), findsOneWidget);
      expect(find.text('View Content'), findsOneWidget);
      expect(find.text('Idea Vault'), findsWidgets);
      expect(find.text('My Content'), findsWidgets);
      expect(find.text('Insights'), findsWidgets);

      await tester.tap(find.text('+ Add Idea').first);
      expect(addIdeaTapped, isTrue);

      await tester.tap(find.text('Create a Reel').first);
      expect(createReelTapped, isTrue);

      await tester.tap(find.byTooltip('Settings'));
      expect(settingsTapped, isTrue);
    });

    testWidgets('pipeline overview shows status headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onAddIdea: (_) {},
            onCreateReel: (_) {},
            onMyContent: () {},
            onInsights: () {},
            onSettings: () {},
            onIdeaVault: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Your content pipeline'), findsOneWidget);
      expect(find.text('Ideas'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
    });

    testWidgets('Idea Vault nav card navigates on tap', (tester) async {
      var vaultTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onAddIdea: (_) {},
            onCreateReel: (_) {},
            onMyContent: () {},
            onInsights: () {},
            onSettings: () {},
            onIdeaVault: () => vaultTapped = true,
          ),
        ),
      );
      await tester.pump();

      final card = find.ancestor(
        of: find.text('Capture, browse, organise, and develop ideas'),
        matching: find.byType(InkWell),
      );
      await tester.tap(card);
      expect(vaultTapped, isTrue);
    });

    testWidgets('reminders section is hidden when no pending items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onAddIdea: (_) {},
            onCreateReel: (_) {},
            onMyContent: () {},
            onInsights: () {},
            onSettings: () {},
            onIdeaVault: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reminders'), findsNothing);
    });

    testWidgets('settings icon in AppBar navigates', (tester) async {
      var settingsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onAddIdea: (_) {},
            onCreateReel: (_) {},
            onMyContent: () {},
            onInsights: () {},
            onSettings: () => settingsTapped = true,
            onIdeaVault: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Settings'));
      expect(settingsTapped, isTrue);
    });
  });
}
