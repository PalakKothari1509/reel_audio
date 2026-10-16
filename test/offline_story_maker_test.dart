import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/story_generator_offline.dart';
import '../lib/video_prompt_generator_offline.dart';
import '../lib/offline_engagement.dart';
import '../lib/offline_story_maker_screen.dart';

void main() {
  group('StoryGenerator (offline)', () {
    test('generates a story with all required fields', () {
      final story = StoryGenerator().generate();
      expect(story.title, isNotEmpty);
      expect(story.hook, isNotEmpty);
      expect(story.problem, isNotEmpty);
      expect(story.twist, isNotEmpty);
      expect(story.solution, isNotEmpty);
      expect(story.endingLine, isNotEmpty);
      expect(story.moral, isNotEmpty);
    });

    test('generates exactly 5 hook options with type and text', () {
      final story = StoryGenerator().generate();
      expect(story.hookOptions, isNotEmpty);
      for (final h in story.hookOptions) {
        expect(h['type'], isNotEmpty);
        expect(h['text'], isNotEmpty);
      }
    });

    test('produces valid JSON from toJson', () {
      final story = StoryGenerator().generate();
      final json = story.toJson();
      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['title'], isNotEmpty);
      expect(decoded['hook'], isNotEmpty);
      expect(decoded['hook_options'], isA<List>());
    });
  });

  group('OfflineVideoPromptGenerator', () {
    test('generates correct number of parts for 30s', () {
      final result = OfflineVideoPromptGenerator().generateFromIdea(
        idea: 'Tooth brushing fight',
        totalSeconds: 30,
        characters: ['Ria', 'Rio', 'Cuty'],
      );
      expect(result.parts.length, 3);
    });

    test('generates correct number of parts for 20s', () {
      final result = OfflineVideoPromptGenerator().generateFromIdea(
        idea: 'Putting on shoes',
        totalSeconds: 20,
        characters: ['Ria', 'Rio'],
      );
      expect(result.parts.length, 2);
    });

    test('each part has a full prompt with required sections', () {
      final result = OfflineVideoPromptGenerator().generateFromIdea(
        idea: 'Sharing toys',
        totalSeconds: 30,
        characters: ['Ria', 'Rio', 'Cuty'],
      );
      for (final part in result.parts) {
        expect(part.promptText, contains('TITLE:'));
        expect(part.promptText, contains('PART'));
        expect(part.promptText, contains('DURATION:'));
        expect(part.promptText, contains('FORMAT:'));
        expect(part.promptText, contains('CHARACTER LOCK'));
        expect(part.promptText, contains('ACTION TIMELINE'));
        expect(part.promptText, contains('VISUAL STYLE'));
        expect(part.promptText, contains('NEGATIVE INSTRUCTIONS'));
      }
    });

    test('story foundation is non-empty', () {
      final result = OfflineVideoPromptGenerator().generateFromIdea(
        idea: 'Bath time struggle',
        totalSeconds: 30,
        characters: ['Ria', 'Cuty'],
      );
      expect(result.storyFoundation, isNotEmpty);
      expect(result.storyTitle, isNotEmpty);
    });
  });

  group('OfflineEngagementGenerator', () {
    test('generates engagement with all fields', () {
      final pkg = OfflineEngagementGenerator().generate(storyMoral: 'Sharing is caring');
      expect(pkg.caption, isNotEmpty);
      expect(pkg.hashtags.length, 5);
      expect(pkg.pinnedComment, isNotEmpty);
      expect(pkg.suggestedReplies.length, 6);
      expect(pkg.followReason, isNotEmpty);
    });

    test('caption includes the moral', () {
      final pkg = OfflineEngagementGenerator().generate(
        storyMoral: 'Teamwork makes dreams work',
      );
      expect(pkg.caption, contains('Teamwork makes dreams work'));
    });

    test('hashtags always has exactly 5', () {
      final pkg = OfflineEngagementGenerator().generate(storyMoral: 'Good habits');
      expect(pkg.hashtags.length, equals(5));
    });

    test('forInstagram joins caption and hashtags', () {
      final pkg = OfflineEngagementGenerator().generate(storyMoral: 'Test');
      expect(pkg.forInstagram, contains(pkg.caption));
      expect(pkg.forInstagram, contains('#'));
    });

    test('produces valid JSON', () {
      final pkg = OfflineEngagementGenerator().generate(storyMoral: 'Test');
      final json = pkg.toJson();
      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['caption'], isNotEmpty);
      expect(decoded['hashtags'], isA<List>());
      expect(decoded['pinnedComment'], isNotEmpty);
    });
  });

  group('OfflineStoryMakerScreen', () {
    testWidgets('renders generate button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OfflineStoryMakerScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Generate Story (No Internet Required)'), findsOneWidget);
    });

    testWidgets('tapping generate produces story result without API',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OfflineStoryMakerScreen()),
      );
      expect(find.text('Generate Story (No Internet Required)'),
          findsOneWidget);

      await tester.tap(find.text('Generate Story (No Internet Required)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Generated Story'), findsOneWidget);
      expect(find.textContaining('Video Prompts'), findsOneWidget);
      expect(find.textContaining('Engagement Package'), findsOneWidget);
    });
  });
}
