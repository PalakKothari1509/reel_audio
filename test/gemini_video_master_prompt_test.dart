import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/characters.dart';
import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/gemini_video_master_prompt.dart';
import 'package:reel_audio/video_production_plan.dart';

void main() {
  group('renderVideoMasterPrompt', () {
    test('replaces all placeholders with variable values', () {
      final vars = VideoPromptVariables(
        storyTitle: 'Main Khud Karungi',
        storyIdea: 'Ria wants to put her shoes on herself.',
        realLifeProblem: 'Rushing morning routine.',
        learningOutcome: 'Independence and patience.',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: 'Vibrant 3D animation',
        overallTone: 'Heartwarming and relatable',
        videoGenerator: 'Runway Gen-2',
        language: 'Hinglish',
      );

      final rendered = renderVideoMasterPrompt(vars);

      expect(rendered, contains('Main Khud Karungi'));
      expect(rendered, contains('Ria wants to put her shoes on herself.'));
      expect(rendered, contains('Rushing morning routine.'));
      expect(rendered, contains('Independence and patience.'));
      expect(rendered, contains('Ria, Mumma'));
      expect(rendered, contains('Vibrant 3D animation'));
      expect(rendered, contains('Heartwarming and relatable'));
      expect(rendered, contains('Runway Gen-2'));
      expect(rendered, contains('Hinglish'));
      expect(rendered, isNot(contains('{{')));
    });

    test('includes character descriptions in rendered output', () {
      final vars = VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test idea',
        realLifeProblem: 'Test problem',
        learningOutcome: 'Test outcome',
        selectedCharacters: ['Ria', 'Robot'],
        visualStyle: '3D',
        overallTone: 'Playful',
      );

      final rendered = renderVideoMasterPrompt(vars);

      // Should contain descriptions for both characters
      expect(rendered, contains(characterDescription('Ria')));
      expect(rendered, contains(characterDescription('Robot')));
    });

    test('requires text_overlay for sound-off viewing', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: [],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('text_overlay'));
      expect(rendered, contains('ON-SCREEN TEXT OVERLAYS'));
      expect(rendered, contains('sound-off'));
    });

    test('does not hardcode "Never add glasses to Ria or Rio"', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Mumma', 'Papa'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, isNot(contains('Never add glasses to Ria or Rio')));
    });

    test('uses generic character consistency rules', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('Character consistency rules'));
      expect(rendered, isNot(contains('Ria or Rio')));
      expect(rendered, isNot(contains('Robot, when selected')));
    });

    test('uses reference image instruction when hasReferenceImages is true', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
        hasReferenceImages: true,
      ));

      expect(rendered, contains('Use the attached reference images as the definitive character references'));
      expect(rendered, isNot(contains('Character descriptions:')));
      expect(rendered, isNot(contains(characterDescription('Mumma'))));
    });

    test('includes character descriptions when hasReferenceImages is false', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
        hasReferenceImages: false,
      ));

      expect(rendered, contains('Character descriptions:'));
      expect(rendered, contains(characterDescription('Mumma')));
      expect(rendered, contains('Use the supplied character descriptions as the authoritative references'));
    });

    test('prohibits rendered text overlays in video frames', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      // The prompt must tell Gemini that text overlays are editor metadata
      // and must NOT be rendered in the video
      expect(rendered, contains('must NOT'));
      expect(rendered, contains('render text'));
      expect(rendered, contains('on_screen_text field only'));
      expect(rendered, contains('editor\'s'));
      expect(rendered, contains('editor metadata'));
    });

    test('does not contain Instagram handle', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, isNot(contains('@funlearningwithpalak')));
    });
  });
}
