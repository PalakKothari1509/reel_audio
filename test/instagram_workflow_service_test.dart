import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/caption_generator.dart';
import 'package:reel_audio/instagram_workflow_service.dart';

void main() {
  group('offline Instagram workflows', () {
    test('growth plan labels the no-metrics plan as an estimate', () async {
      final result = await InstagramWorkflowService.generateGrowthPlan(
        scope: 'Account',
        idea: '',
        category: 'Activity',
        evidence: '',
        hasRecordedMetrics: false,
        apiKey: '',
      );

      expect(result.usedOfflineFallback, isTrue);
      expect(result.content, contains('planning estimate'));
      expect(
        result.content,
        contains('No trend, audience, reach, or growth claim'),
      );
      expect(result.metadata['evidenceType'], 'estimate');
    });

    test('Stories fallback is a five-frame planning draft', () async {
      final result = await InstagramWorkflowService.generateStoriesSequence(
        idea: 'Ria sorts the laundry by colour',
        category: 'Activity',
        characters: const ['Ria'],
        apiKey: '',
      );

      expect(result.usedOfflineFallback, isTrue);
      expect(result.metadata['frameCount'], 5);
      expect(
        RegExp(
          r'^FRAME \d+',
          multiLine: true,
        ).allMatches(result.content).length,
        5,
      );
      expect(result.content, contains('INTERACTION:'));
    });

    test('keywords are derived from supplied text, not trends', () {
      final keywords = InstagramWorkflowService.topicKeywords(
        'the toddler sorts colourful blocks during screen-free play',
        category: 'Activity',
      );

      expect(
        keywords,
        containsAll(['Activity', 'toddler', 'colourful', 'blocks']),
      );
      expect(keywords, isNot(contains('the')));
    });
  });

  test(
    'caption prompt includes the source caption and preserves its meaning',
    () {
      final prompt = buildCaptionPrompt(
        topic: 'bedtime routine',
        language: CaptionLanguage.hinglish,
        sourceCaption: 'My child asks for one more story at bedtime.',
      );

      expect(prompt, contains('EXISTING CAPTION TO REWRITE'));
      expect(prompt, contains('My child asks for one more story at bedtime.'));
      expect(prompt, contains('Preserve the original meaning'));
    },
  );

  test('offline caption template provides exactly five unique hashtags', () {
    final caption = captionFromTemplate(
      topic: 'preschool brushing routine',
      language: CaptionLanguage.hinglish,
    );

    expect(caption.hashtags, hasLength(5));
    expect(caption.hashtags.toSet(), hasLength(5));
    expect(caption.hashtags.every((tag) => tag.startsWith('#')), isTrue);
  });
}
