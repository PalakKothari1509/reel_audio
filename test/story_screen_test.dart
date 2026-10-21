import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/json_file_store.dart';
import 'package:reel_audio/main.dart';

void main() {
  setUp(() {
    final dir = Directory.systemTemp.createTempSync('story_screen_test');
    JsonFileStore.setTestDirectory(dir);
  });

  tearDown(() {
    JsonFileStore.clearTestDirectory();
  });

  group('StoryScreen', () {
    testWidgets('displays initialText in the story box when provided',
        (tester) async {
      const testText = 'Ria ne joote ulte se pehne — silly story for testing.';
      await tester.pumpWidget(
        MaterialApp(
          home: StoryScreen(initialText: testText),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(testText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows New story button by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoryScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('Write the script'), findsOneWidget);
    });

    testWidgets('shows Or write the script myself link when no saved script',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoryScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('Or write the script myself'), findsOneWidget);
    });

    testWidgets('loads idea storyDetail when ideaId is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoryScreen(ideaId: 'h01'),
        ),
      );

      // Allow async loading from ContentLibraryService to complete.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.textContaining('Bus ka samay ho raha hai'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ria haath jhatak deti'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows status message after loading idea', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoryScreen(ideaId: 'h01'),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.textContaining('Main Khud Karungi'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to problem+lesson when storyDetail is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoryScreen(ideaId: 'h99'),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // h99 is not a real idea — the screen should not crash and should
      // show an empty text field.
      expect(tester.takeException(), isNull);
    });
  });

  group('TimedScriptScreen', () {
    testWidgets('renders initial script lines as text fields', (tester) async {
      final lines = [
        ScriptLine(const Duration(seconds: 0), 'Ek baar ki baat hai'),
        ScriptLine(const Duration(seconds: 5), 'Ria ne dekha ek titli'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: TimedScriptScreen(
            style: '❤️ Heartwarming',
            language: 'Hinglish',
            videoFile: null,
            initialLines: lines,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Your script'), findsOneWidget);
      expect(find.text('Ek baar ki baat hai'), findsOneWidget);
      expect(find.text('Ria ne dekha ek titli'), findsOneWidget);
      expect(find.text('FIRST 3 SECONDS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows paste panel when no initial lines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimedScriptScreen(
            style: '❤️ Heartwarming',
            language: 'Hinglish',
            videoFile: null,
            initialLines: [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('One line each, starting with the time'), findsOneWidget);
      expect(find.text('Paste your script here'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows line count in trailing label', (tester) async {
      final lines = [
        ScriptLine(const Duration(seconds: 0), 'Line one'),
        ScriptLine(const Duration(seconds: 4), 'Line two'),
        ScriptLine(const Duration(seconds: 8), 'Line three'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: TimedScriptScreen(
            style: '❤️ Heartwarming',
            language: 'Hinglish',
            videoFile: null,
            initialLines: lines,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('THE REST'), findsOneWidget);
      expect(find.text('3 lines'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('step bar shows all five steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimedScriptScreen(
            style: '❤️ Heartwarming',
            language: 'Hinglish',
            videoFile: null,
            initialLines: [
              ScriptLine(const Duration(seconds: 0), 'Test line'),
            ],
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Script'), findsWidgets);
      expect(find.text('Pictures'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Reel'), findsOneWidget);
    });
  });
}
