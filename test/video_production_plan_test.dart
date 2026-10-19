import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/video_production_plan.dart';

void main() {
  group('ClipPlan', () {
    test('fromJson round-trips all fields', () {
      final json = {
        'partNumber': 1,
        'purpose': 'Hook',
        'setting': 'Kitchen',
        'startingState': 'Ria standing',
        'action_0_4s': 'Ria runs',
        'action_4_8s': 'Ria stops',
        'action_8_10s': 'Ria looks',
        'dialogue': 'Mumma!',
        'text_overlay': 'Main Khud!',
        'endingState': 'Ria smiling',
        'continuity_from': 'Opening',
        'continuity_into': 'Next scene',
        'negative_instructions': 'No glasses',
        'full_prompt': 'Complete prompt here',
      };

      final clip = ClipPlan.fromJson(json);
      expect(clip.partNumber, 1);
      expect(clip.purpose, 'Hook');
      expect(clip.dialogue, 'Mumma!');
      expect(clip.textOverlay, 'Main Khud!');
      expect(clip.fullPrompt, 'Complete prompt here');
      expect(clip.hasOverlayText, isTrue);
      expect(clip.hasDialogue, isTrue);
    });

    test('hasOverlayText is false when text_overlay is empty', () {
      final clip = ClipPlan(
        partNumber: 1,
        purpose: '',
        setting: '',
        startingState: '',
        action0to4s: '',
        action4to8s: '',
        action8to10s: '',
        dialogue: '',
        textOverlay: '',
        endingState: '',
        continuityFrom: '',
        continuityInto: '',
        negativeInstructions: '',
        fullPrompt: '',
      );
      expect(clip.hasOverlayText, isFalse);
      expect(clip.hasDialogue, isFalse);
    });
  });

  group('VideoProductionPlan', () {
    test('fromJson round-trips with clips', () {
      final clip = ClipPlan(
        partNumber: 1,
        purpose: 'Hook',
        setting: 'Kitchen',
        startingState: 'Ria standing',
        action0to4s: 'Ria runs',
        action4to8s: '',
        action8to10s: '',
        dialogue: 'Mumma!',
        textOverlay: 'Text here',
        endingState: 'Ria smiling',
        continuityFrom: '',
        continuityInto: '',
        negativeInstructions: '',
        fullPrompt: 'Prompt',
      );

      final json = {
        'id': 'plan-1',
        'contentId': 'FLWP-0001',
        'storyTitle': 'Test Story',
        'storyFoundation': 'A foundation',
        'templateId': 'gemini-video-v1',
        'templateVersion': 1,
        'clipPlans': [clip.toJson()],
        'fullNarration': 'Narration here',
        'createdAt': '2025-01-15T10:00:00.000',
        'updatedAt': '2025-01-15T10:30:00.000',
      };

      final plan = VideoProductionPlan.fromJson(json);
      expect(plan.id, 'plan-1');
      expect(plan.contentId, 'FLWP-0001');
      expect(plan.storyTitle, 'Test Story');
      expect(plan.clipPlans.length, 1);
      expect(plan.clipPlans.first.partNumber, 1);
      expect(plan.hasSoundOffCoverage, isTrue);
    });

    test('hasSoundOffCoverage is false when clips lack text and dialogue', () {
      final clip1 = ClipPlan(
        partNumber: 1,
        purpose: '',
        setting: '',
        startingState: '',
        action0to4s: '',
        action4to8s: '',
        action8to10s: '',
        dialogue: '',
        textOverlay: '',
        endingState: '',
        continuityFrom: '',
        continuityInto: '',
        negativeInstructions: '',
        fullPrompt: '',
      );

      final plan = VideoProductionPlan(
        id: 'plan-2',
        contentId: 'FLWP-0002',
        storyTitle: '',
        storyFoundation: '',
        templateId: '',
        templateVersion: 1,
        clipPlans: [clip1],
        fullNarration: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(plan.hasSoundOffCoverage, isFalse);
    });
  });
}
