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
      var settingsTapped = false;
      var contentLibraryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home:           ContentStudioHome(
            onCreateReel: (_) {},
            onSettings: () => settingsTapped = true,
            onContentLibrary: () => contentLibraryTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning, Palak!'), findsOneWidget);
      expect(find.text('Create Content'), findsOneWidget);
      expect(find.text('Content Library'), findsOneWidget);
      expect(find.text('Content Library'), findsOneWidget);
      expect(find.text('Review All Ideas'), findsNothing);
      expect(find.text('My Videos'), findsNothing);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(settingsTapped, isTrue);

      await tester.tap(find.text('Content Library'));
      await tester.pumpAndSettle();
      expect(contentLibraryTapped, isTrue);
    });

    testWidgets('has no duplicate Create button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home:           ContentStudioHome(
            onCreateReel: (_) => {},
            onSettings: () {},
            onContentLibrary: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly one Create Content card, not duplicated.
      expect(find.text('Create Content'), findsOneWidget);
    });

    testWidgets('optionally shows Add New Idea and legacy create cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onCreateReel: (_) => {},
            onSettings: () {},
            onContentLibrary: () {},
            onAddNewIdea: () {},
            onImagePrompt: () {},
            onCarouselPrompts: () {},
            onGeminiVideo: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add New Idea'), findsOneWidget);
      expect(find.text('Image Generation Prompt'), findsOneWidget);
      expect(find.text('Carousel Generation'), findsOneWidget);
      expect(find.text('Gemini Story Video'), findsOneWidget);
    });

    testWidgets('conditionally hides optional cards when callbacks are null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentStudioHome(
            onCreateReel: (_) => {},
            onSettings: () {},
            onContentLibrary: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // With no optional callbacks, none of those cards should render.
      expect(find.text('Add New Idea'), findsNothing);
      expect(find.text('Image Generation Prompt'), findsNothing);
      expect(find.text('Carousel Generation'), findsNothing);
      expect(find.text('Gemini Story Video'), findsNothing);
      expect(find.text('Review All Ideas'), findsNothing);
    });
  });
}
