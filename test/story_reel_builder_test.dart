import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/ai_provider.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_generator.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/gemini_client.dart';
import 'package:reel_audio/story_reel_builder.dart';

/// A mock AIProvider that returns pre-canned JSON.
class MockAIProvider implements AIProvider {
  final String? cannedJson;
  final Exception? error;
  bool generateCalled = false;
  IdeaInput? capturedInput;

  MockAIProvider({this.cannedJson, this.error});

  @override
  Future<ContentPackage> generate(IdeaInput input) async {
    generateCalled = true;
    capturedInput = input;
    if (error != null) throw error!;
    if (cannedJson == null) {
      throw Exception('No canned response set');
    }
    return GeminiClient.parseResponse(cannedJson!, input);
  }

  @override
  Future<ContentPackage> regenerate(
      ContentPackage pkg, dynamic target, dynamic style) {
    throw UnimplementedError();
  }

  @override
  Future<void> testConnection() async {}

  @override
  String get providerName => 'Mock';

  @override
  bool get isAvailable => error == null;
}

const String _navratriReelJson = r'''
{
  "topic": "Morning Aarti at Home",
  "bucket": "challenge",
  "hook": "Diya lit, baby distracted — 30 seconds of chaos 🪔",
  "slides": [
    {
      "slideNumber": 1,
      "headline": "The Distraction",
      "body": "Baby crawls toward the diya while Mumma tries to finish the aarti. Cuty sneaks a snack.",
      "imagePrompt": "Ria trying to light diya, baby crawling toward it, Cuty sneaking ladoos, soft 3D Pixar style, cream background",
      "cta": "We have ALL been here"
    },
    {
      "slideNumber": 2,
      "headline": "The Hack",
      "body": "Mumma involves baby with a tiny diya of her own — 30 seconds of focus, peaceful aarti.",
      "imagePrompt": "Baby holding tiny toy diya next to real one, Mumma smiling, Ria helping, Cuty behaving, 3D Pixar style, cream background",
      "cta": "Save this diwali hack!"
    }
  ],
  "caption": "Diya lit, baby distracted. 30 seconds of chaos. Then I gave her a tiny diya of her own. Suddenly everyone was focused. Try it tonight. #DiwaliWithKids #ParentingHack #Navratri2025",
  "hashtags": ["#DiwaliWithKids", "#ParentingHack", "#Navratri2025", "#ScreenFree", "#FunLearning"],
  "pinnedComment": "Did you try this? Tell us below!",
  "replyComments": ["Same here every evening!", "Genius hack", "Saving this", "Toddler logic 😂", "Tried and worked!"],
  "script": "Diya lit, baby distracted — 30 seconds of chaos. Then I gave her a tiny diya of her own. Suddenly everyone was focused."
}
''';

void main() {
  group('StoryReelBuilder', () {
    late MockAIProvider provider;
    late StoryReelBuilder builder;

    setUp(() {
      provider = MockAIProvider(cannedJson: _navratriReelJson);
      builder = StoryReelBuilder(provider);
    });

    test('buildReel produces ContentPackageV2 with 2 ten-second scenes', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(pkg.ideaId, 'N1');
      expect(pkg.scenes.length, 2);
      expect(pkg.shotList.length, 2);
    });

    test('each scene has durationSeconds of 10', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      for (final scene in pkg.scenes) {
        expect(scene.durationSeconds, 10);
      }
      for (final shot in pkg.shotList) {
        expect(shot.durationSeconds, 10);
      }
    });

    test('total duration equals segmentCount * segmentDurationSeconds', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(request.totalDurationSeconds, 20);
      expect(pkg.scenes.length * 10, 20);
    });

    test('promptString is included in extraContext', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      await builder.buildReel(request);

      expect(provider.capturedInput, isNotNull);
      final extra = provider.capturedInput!.extraContext;
      expect(extra, isNotNull);
      expect(extra!['storyReelPrompt'], isNotNull);
    });

    test('scene titles and descriptions match provider output', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(pkg.scenes[0].title, 'The Distraction');
      expect(pkg.scenes[1].title, 'The Hack');
      expect(pkg.scenes[0].description, contains('Baby crawls'));
      expect(pkg.scenes[1].description, contains('tiny diya'));
    });

    test('classification has correct contentType and productionMethod', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(pkg.classification.contentType, ContentType.reel);
      expect(pkg.classification.productionMethod, ProductionMethod.characterImages);
      expect(pkg.classification.pillar, ContentPillar.play);
    });

    test('share trigger is populated', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(pkg.shareTrigger, isNotNull);
      expect(pkg.shareTrigger!.sender, 'Mumma');
      expect(pkg.shareTrigger!.senderKnown, isTrue);
    });

    test('voiceMode is required for story-based reels', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(pkg.voiceMode, VoiceMode.required);
    });

    test('experiment group is set to navratri-reels', () async {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted — 30 seconds of chaos 🪔',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
      );

      final pkg = await builder.buildReel(request);

      expect(pkg.experimentGroup, 'navratri-reels');
      expect(pkg.testNumber, 1);
      expect(pkg.testCount, 2);
    });

    test('can configure 4 segments at 5 seconds each', () {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted',
        characters: ['mumma', 'ria', 'rio', 'cuty'],
        pillar: ContentPillar.play,
        segmentDurationSeconds: 5,
        segmentCount: 4,
      );

      expect(request.segmentDurationSeconds, 5);
      expect(request.segmentCount, 4);
      expect(request.totalDurationSeconds, 20);
    });

    test('throwIf provider throws propagates AiContentFailure', () async {
      final errorProvider = MockAIProvider(error: Exception('API down'));
      final errorBuilder = StoryReelBuilder(errorProvider);
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti',
        parentProblem: 'Distracted baby',
        learningGoal: 'Focus',
        hook: 'Diya lit, baby distracted',
        characters: ['mumma'],
        pillar: ContentPillar.play,
      );

      expect(() => errorBuilder.buildReel(request), throwsException);
    });

    test('promptString contains Reel structure instructions', () {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Morning Aarti at Home',
        parentProblem: 'Baby keeps distracting during prayer time',
        learningGoal: 'Involving baby in rituals builds focus and connection',
        hook: 'Diya lit, baby distracted',
        characters: ['mumma', 'ria'],
        pillar: ContentPillar.play,
      );

      final prompt = request.toPromptString();

      expect(prompt, contains('STORY REEL REQUEST'));
      expect(prompt, contains('STRUCTURE'));
      expect(prompt, contains('Scene 1'));
      expect(prompt, contains('Scene 2'));
      expect(prompt, contains('OUTPUT JSON SCHEMA'));
    });

    test('promptString with segmentCount=1 only has Scene 1', () {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Simple Story',
        parentProblem: 'Small problem',
        learningGoal: 'Small lesson',
        hook: 'Hook here',
        characters: ['mumma', 'ria'],
        pillar: ContentPillar.play,
        segmentCount: 1,
      );
      final prompt = request.toPromptString();
      expect(prompt, contains('Scene 1'));
      expect(prompt.contains('Scene 2'), isFalse);
    });

    test('promptString with segmentCount=3 has Scenes 1-3', () {
      final request = StoryReelRequest(
        ideaId: 'N1',
        title: 'Three Scene Story',
        parentProblem: 'Medium problem',
        learningGoal: 'Medium lesson',
        hook: 'Hook here',
        characters: ['mumma', 'ria'],
        pillar: ContentPillar.play,
        segmentCount: 3,
      );
      final prompt = request.toPromptString();
      expect(prompt, contains('Scene 1'));
      expect(prompt, contains('Scene 2'));
      expect(prompt, contains('Scene 3'));
      expect(prompt.contains('Scene 4'), isFalse);
    });
  });
}
