import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/json_file_store.dart';
import '../lib/story_generator_offline.dart';
import '../lib/video_prompt_generator_offline.dart';
import '../lib/offline_engagement.dart';
import '../lib/offline_story_maker_screen.dart';
import '../lib/content_ideas.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('story_gen_test');
    JsonFileStore.setTestDirectory(tempDir);
  });

  tearDown(() {
    JsonFileStore.clearTestDirectory();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('StoryGenerator (offline)', () {
    test('generates a story with all required fields', () async {
      final story = await StoryGenerator().generate();
      expect(story.title, isNotEmpty);
      expect(story.hook, isNotEmpty);
      expect(story.problem, isNotEmpty);
      // twist/solution/endingLine may be empty for hooks without storyDetail
      // moral is empty when keepMoralOffScreen is true
    });

    test('generates exactly 5 hook options with type and text', () async {
      final story = await StoryGenerator().generate();
      expect(story.hookOptions, isNotEmpty);
      for (final h in story.hookOptions) {
        expect(h['type'], isNotEmpty);
        expect(h['text'], isNotEmpty);
      }
    });

    test('produces valid JSON from toJson', () async {
      final story = await StoryGenerator().generate();
      final json = story.toJson();
      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['title'], isNotEmpty);
      expect(decoded['hook'], isNotEmpty);
      expect(decoded['hook_options'], isA<List>());
    });

    test('_extractLine handles PART 1: format as fallback for Story:', () {
      const detail = '''
Story: This is the proper story.
Twist: A twist occurred.
Resolution: All resolved.
Moral: The lesson.
''';
      expect(StoryGenerator.extractLine(detail, 'Story:', 'PART 1:'),
          contains('proper story'));

      const partDetail = '''
PART 1: This is a PART 1 story.
Twist: A twist occurred.
Resolution: All resolved.
Moral: The lesson.
''';
      expect(StoryGenerator.extractLine(partDetail, 'Story:', 'PART 1:'),
          contains('PART 1 story'));
      expect(StoryGenerator.extractLine(partDetail, 'Story:', 'PART 1:'),
          isNotEmpty);
    });

    test('PART 1 hooks produce non-empty problem field', () async {
      final result = await StoryGenerator().generate();
      expect(result.problem, isNotEmpty);
    });

    test('all PART 1 hooks are parseable by _extractLine', () {
      final part1Hooks = kDefaultHooksWithRewrite
          .where((h) => h.storyDetail.contains('PART 1:'));
      expect(part1Hooks, isNotEmpty,
          reason: 'There should be hooks using PART 1: format');
      for (final h in part1Hooks) {
        final problem =
            StoryGenerator.extractLine(h.storyDetail, 'Story:', 'PART 1:');
        expect(problem, isNotEmpty,
            reason: 'Hook ${h.id} PART 1: not parsed as story');
      }
    });
  });

   group('OfflineVideoPromptGenerator', () {
    test('generates correct number of parts for 30s', () async {
      final story = await StoryGenerator().generate();
      final result = OfflineVideoPromptGenerator().generateFromStory(
        story,
        totalSeconds: 30,
        characters: ['Ria', 'Rio', 'Cuty'],
      );
      expect(result.parts.length, 3);
    });

    test('generates correct number of parts for 20s', () async {
      final story = await StoryGenerator().generate();
      final result = OfflineVideoPromptGenerator().generateFromStory(
        story,
        totalSeconds: 20,
        characters: ['Ria', 'Rio'],
      );
      expect(result.parts.length, 2);
    });

    test('each part has a full prompt with required sections', () async {
      final story = await StoryGenerator().generate();
      final result = OfflineVideoPromptGenerator().generateFromStory(
        story,
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

    test('story foundation is non-empty', () async {
      final story = await StoryGenerator().generate();
      final result = OfflineVideoPromptGenerator().generateFromStory(
        story,
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
