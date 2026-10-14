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
      var createReelTapped = false;
      var settingsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onCreateReel: (_) => createReelTapped = true,
            onMyContent: () {},
            onSettings: () => settingsTapped = true,
            onIdeaVault: () {},
            onImagePrompt: () {},
            onCarouselPrompts: () {},
            onGeminiVideo: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Good morning, Palak!'), findsOneWidget);
      expect(find.text('Reel from Images'), findsOneWidget);
      expect(find.text('Gemini Story Video'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Idea Vault'), 100);
      expect(find.text('Idea Vault'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('My Content'), 100);
      expect(find.text('My Content'), findsOneWidget);

      // Scroll back to top to tap Reel from Images
      await tester.scrollUntilVisible(find.text('Reel from Images'), -100);
      await tester.tap(find.text('Reel from Images').first);
      expect(createReelTapped, isTrue);

      await tester.tap(find.byTooltip('Settings'));
      expect(settingsTapped, isTrue);
    });

    testWidgets('has no duplicate Create button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onCreateReel: (_) => {},
            onMyContent: () {},
            onSettings: () {},
            onIdeaVault: () {},
            onImagePrompt: () {},
            onCarouselPrompts: () {},
            onGeminiVideo: () {},
          ),
        ),
      );
      await tester.pump();

      // Exactly one Reel from Images card, not duplicated.
      expect(find.text('Reel from Images'), findsOneWidget);
    });
  });
}