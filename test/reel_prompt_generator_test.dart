import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/characters.dart';
import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/reel_prompt_generator.dart';

void main() {
  late HookIdea testIdea;

  setUpAll(() {
    testIdea = HookIdea(
      id: 'test_idea_1',
      category: 'Relatable',
      title: 'Ria Refuses Shoes',
      cover: 'Shoe Struggle 👟',
      opening: 'Ria sits on the floor, arms crossed: "Main nahi pehnungi!"',
      problem: 'Ria refuses to put on her shoes when it is time to leave for the park.',
      lesson: 'Offering a choice gives the child agency and avoids a power struggle.',
      forApp: true,
      usedOn: '',
      custom: false,
      archived: false,
      postFormat: 'Reel',
      strategy: 'Show the real struggle, then the parent offers a choice.',
      caption: 'When your toddler refuses shoes, offer a choice: red or blue? 👟',
      pinnedComment: 'Which shoe does your little one always pick?',
      storyDetail: 'Story: It is park time. Mumma holds out Ria shoes: "Chalo, pehno." Ria crosses her arms and scowls: "Main nahi pehnungi!" Mumma waits, then smiles: "Theek hai. Red wale ya blue wale?" Ria looks, points: "Red!" She puts them on herself, beaming.\nTwist: Mumma offers a choice instead of forcing.\nResolution: Ria chooses red shoes and puts them on proudly.\nMoral: Choice builds cooperation.',
      setting: 'Entryway, morning light, shoes by the door',
      sceneDetail: 'Two pairs of shoes — red and blue — lined up neatly',
      dialogue: 'Mumma: "Chalo, pehno." Ria: "Main nahi pehnungi!" Mumma: "Red wale ya blue wale?" Ria: "Red!"',
      mess: 'Ria throws a mini-tantrum, kicks the floor, refuses to budge.',
      innerThought: 'Forcing her will make it worse. A choice might work.',
      endingBeat: 'Ria puts on red shoes herself, high-fives Mumma, runs to the door.',
      defaultCast: ['Ria', 'Mumma'],
      keepMoralOffScreen: false,
    );
  });

  group('ReelPromptGenerator architecture', () {
    late ReelPromptGenerator generator;

    setUp(() {
      generator = ReelPromptGenerator();
    });

    test('can receive a selected HookIdea and generate a master prompt', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, isNotEmpty);
      expect(prompt, contains('Ria Refuses Shoes'));
      expect(prompt, contains('Ria refuses to put on her shoes'));
      expect(prompt, contains('Choice builds cooperation'));
    });

    test('injects character rules from authoritative CharacterLibrary', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      // Character descriptions from CharacterLibrary must appear verbatim
      expect(prompt, contains(characterDescription('Ria')));
      expect(prompt, contains(characterDescription('Mumma')));
      // Only selected characters appear
      expect(prompt, isNot(contains(characterDescription('Rio'))));
      expect(prompt, isNot(contains(characterDescription('Cuty'))));
    });

    test('injects brand rules from BrandDefaults', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains(BrandDefaults.name));
      expect(prompt, contains(BrandDefaults.visualStyle));
      expect(prompt, contains('9:16'));
    });

    test('generates prompt requesting exactly three clips', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      // The master prompt template requests 3 parts
      expect(prompt, contains('three consecutive 10-second clips'));
      expect(prompt, contains('Part 1: 0-10 seconds'));
      expect(prompt, contains('Part 2: 10-20 seconds'));
      expect(prompt, contains('Part 3: 20-30 seconds'));
      expect(prompt, contains('Return exactly 3 parts'));
    });

    test('includes story-specific hook source block', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('HOOK SOURCE (authoritative'));
      expect(prompt, contains('Ria refuses to put on her shoes'));
      expect(prompt, contains('Mumma offers a choice'));
      expect(prompt, contains('Ria chooses red shoes'));
      expect(prompt, contains('Choice builds cooperation'));
      expect(prompt, contains('Entryway, morning light'));
      expect(prompt, contains('Two pairs of shoes'));
      expect(prompt, contains('Mumma: "Chalo, pehno."'));
      expect(prompt, contains('Ria throws a mini-tantrum'));
      expect(prompt, contains('Ria puts on red shoes herself'));
    });

    test('includes continuity rules for connected clips', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('Continuing seamlessly from the final frame of Clip 1'));
      expect(prompt, contains('Continuing directly from the final frame of Clip 2'));
      expect(prompt, contains('exact starting state'));
      expect(prompt, contains('exact ending state'));
      expect(prompt, contains('no teleporting'));
    });

    test('includes safety rules that override story fields', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('SAFETY (overrides any conflicting idea field)'));
      expect(prompt, contains('choking hazards'));
      expect(prompt, contains('climbing on unstable furniture'));
    });

    test('includes story accuracy rules preserving hook fields', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('STORY ACCURACY'));
      expect(prompt, contains('source of truth'));
      expect(prompt, contains('Preserve the hook'));
      expect(prompt, contains('central problem, twist, resolution, and lesson'));
      expect(prompt, contains('Do not introduce contradictory events'));
    });

    test('includes realistic outcome rules', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('REALISTIC PRESCHOOL OUTCOMES'));
      expect(prompt, contains('entire house is cleaned in minutes'));
      expect(prompt, contains('tantrum is cured instantly'));
      expect(prompt, contains('imperfect but caring parenting'));
    });

    test('prohibits rendered text in video frames', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('GENERATED VIDEO FRAMES'));
      expect(prompt, contains('render NONE'));
      expect(prompt, contains('must NOT render'));
      expect(prompt, contains('editor metadata'));
    });

    test('separates three text layers: frames, dialogue, editor overlays', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('THREE SEPARATE THINGS'));
      expect(prompt, contains('NEVER MIXED'));
      expect(prompt, contains('SPOKEN DIALOGUE'));
      expect(prompt, contains('EDITOR-ONLY OVERLAYS'));
      expect(prompt, contains('sound-off viewing'));
    });

    test('includes Hinglish language rules for adults and children', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('Hinglish'));
      expect(prompt, contains('Adults speak natural Hindi or Hinglish'));
      expect(prompt, contains('children speak short, age-appropriate Hinglish'));
    });

    test('validates response against Phase 10 schema', () {
      const validJson = {
        'story_title': 'Test Story',
        'story_foundation': 'Ria learns to put on her shoes.',
        'shareability_reason': 'Parents relate to shoe struggles.',
        'caption': 'Shoe time! 👟',
        'hashtags': ['#funlearningwithpalak', '#toddlerlife', '#parenting', '#shoes', '#choices'],
        'pin_comment': 'Red or blue in your house?',
        'cta': 'Save this for morning struggles!',
        'total_duration_seconds': 30,
        'aspect_ratio': '9:16',
        'story_beats': [],
        'overlay_timeline': [],
        'parts': [
          {
            'part_number': 1,
            'time_range': '00:00-00:10',
            'purpose': 'Hook & Problem',
            'setting': 'Entryway',
            'starting_state': 'Ria by shoes',
            'action_0_4s': 'Ria refuses',
            'action_4_8s': 'Mumma offers choice',
            'action_8_10s': 'Ria considers',
            'dialogue': [],
            'text_overlay': 'Shoe struggle',
            'ending_state': 'Ria looking at shoes',
            'continuity_from': 'Opening',
            'continuity_into': 'Mumma helping',
            'negative_instructions': 'No extra chars',
            'full_prompt': 'Full prompt for clip 1 with Ria and Mumma in entryway',
            'on_screen_text': {},
          },
          {
            'part_number': 2,
            'time_range': '00:10-00:20',
            'purpose': 'Twist & Escalation',
            'setting': 'Entryway',
            'starting_state': 'Ria looking at shoes',
            'action_0_4s': 'Mumma helps',
            'action_4_8s': 'Ria puts on red',
            'action_8_10s': 'Ria smiles',
            'dialogue': [],
            'text_overlay': 'Choice made',
            'ending_state': 'Ria wearing red shoe',
            'continuity_from': 'Clip 1 end',
            'continuity_into': 'Resolution',
            'negative_instructions': 'No extra chars',
            'full_prompt': 'Full prompt for clip 2 with Ria and Mumma',
            'on_screen_text': {},
          },
          {
            'part_number': 3,
            'time_range': '00:20-00:30',
            'purpose': 'Resolution',
            'setting': 'Entryway',
            'starting_state': 'Ria wearing red shoe',
            'action_0_4s': 'Second shoe on',
            'action_4_8s': 'High five',
            'action_8_10s': 'Run to door',
            'dialogue': [],
            'text_overlay': 'Success!',
            'ending_state': 'Ready to go',
            'continuity_from': 'Clip 2 end',
            'continuity_into': 'Loop',
            'negative_instructions': 'No extra chars',
            'full_prompt': 'Full prompt for clip 3 with Ria and Mumma',
            'on_screen_text': {},
          },
        ],
        'final_editor_instructions': [],
        'quality_control': [],
      };

      final errors = generator.validateResponse(validJson);
      expect(errors, isNull);
    });

    test('rejects response with wrong clip count', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'shareability_reason': 'Test',
        'caption': 'Test',
        'hashtags': ['#1', '#2', '#3', '#4', '#5'],
        'pin_comment': 'Test',
        'cta': 'Test',
        'total_duration_seconds': 30,
        'aspect_ratio': '9:16',
        'story_beats': [],
        'overlay_timeline': [],
        'parts': [
          {'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c',
           'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f',
           'dialogue': [], 'text_overlay': 'g', 'ending_state': 'h',
           'continuity_from': 'i', 'continuity_into': 'j',
           'negative_instructions': 'k',
           'full_prompt': 'long enough prompt text here with Ria',
           'on_screen_text': {}},
          {'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c',
           'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f',
           'dialogue': [], 'text_overlay': 'g', 'ending_state': 'h',
           'continuity_from': 'i', 'continuity_into': 'j',
           'negative_instructions': 'k',
           'full_prompt': 'long enough prompt text here with Ria',
           'on_screen_text': {}},
        ],
        'final_editor_instructions': [],
        'quality_control': [],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.any((e) => e.contains('Expected exactly 3 parts')), isTrue);
    });

    test('rejects response with missing required fields', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'shareability_reason': 'Test',
        'caption': 'Test',
        'hashtags': ['#1', '#2', '#3', '#4', '#5'],
        'pin_comment': 'Test',
        'cta': 'Test',
        'total_duration_seconds': 30,
        'aspect_ratio': '9:16',
        'story_beats': [],
        'overlay_timeline': [],
        'parts': [
          {'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c',
           'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f',
           'dialogue': [], 'text_overlay': 'g', 'ending_state': 'h',
           'continuity_from': 'i', 'continuity_into': 'j',
           'negative_instructions': 'k',
           'full_prompt': 'long enough prompt text here with Ria',
           'on_screen_text': {}},
        ],
        'final_editor_instructions': [],
        'quality_control': [],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.any((e) => e.contains('Expected exactly 3 parts')), isTrue);
    });

    test('rejects response with invalid hashtag count', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'shareability_reason': 'Test',
        'caption': 'Test',
        'hashtags': ['#1', '#2'],
        'pin_comment': 'Test',
        'cta': 'Test',
        'total_duration_seconds': 30,
        'aspect_ratio': '9:16',
        'story_beats': [],
        'overlay_timeline': [],
        'parts': [
          {'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c',
           'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f',
           'dialogue': [], 'text_overlay': 'g', 'ending_state': 'h',
           'continuity_from': 'i', 'continuity_into': 'j',
           'negative_instructions': 'k',
           'full_prompt': 'long enough prompt text here with Ria',
           'on_screen_text': {}},
          {'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c',
           'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f',
           'dialogue': [], 'text_overlay': 'g', 'ending_state': 'h',
           'continuity_from': 'i', 'continuity_into': 'j',
           'negative_instructions': 'k',
           'full_prompt': 'long enough prompt text here with Ria',
           'on_screen_text': {}},
          {'part_number': 3, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c',
           'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f',
           'dialogue': [], 'text_overlay': 'g', 'ending_state': 'h',
           'continuity_from': 'i', 'continuity_into': 'j',
           'negative_instructions': 'k',
           'full_prompt': 'long enough prompt text here with Ria',
           'on_screen_text': {}},
        ],
        'final_editor_instructions': [],
        'quality_control': [],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.any((e) => e.contains('Expected exactly 5 hashtags')), isTrue);
    });
  });

  group('additionalInstructions integration', () {
    late ReelPromptGenerator generator;

    setUp(() {
      generator = ReelPromptGenerator();
    });

    test('non-empty additionalInstructions appear in generated prompt', () {
      const characters = ['Ria', 'Mumma'];
      const additionalInstructions = 'Make the tone more humorous and add a joke about shoes.';

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: additionalInstructions,
        hasReferenceImages: false,
      );

      expect(prompt, contains('Make the tone more humorous'));
      expect(prompt, contains('joke about shoes'));
      expect(prompt, contains('ADDITIONAL USER INSTRUCTIONS'));
    });

    test('empty additionalInstructions do not create unnecessary content', () {
      const characters = ['Ria', 'Mumma'];
      const additionalInstructions = '';

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: additionalInstructions,
        hasReferenceImages: false,
      );

      expect(prompt, isNot(contains('ADDITIONAL USER INSTRUCTIONS')));
    });

    test('whitespace-only additionalInstructions are handled correctly', () {
      const characters = ['Ria', 'Mumma'];
      const additionalInstructions = '   \n\t  ';

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: additionalInstructions,
        hasReferenceImages: false,
      );

      expect(prompt, isNot(contains('ADDITIONAL USER INSTRUCTIONS')));
    });

    test('special characters in additionalInstructions are preserved safely', () {
      const characters = ['Ria', 'Mumma'];
      const additionalInstructions = 'Use {{PLACEHOLDER}} and "quotes" & <tags>.';

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: additionalInstructions,
        hasReferenceImages: false,
      );

      expect(prompt, contains('{{PLACEHOLDER}}'));
      expect(prompt, contains('"quotes"'));
      expect(prompt, contains('<tags>'));
    });

    test('multiline additionalInstructions are preserved', () {
      const characters = ['Ria', 'Mumma'];
      const additionalInstructions = 'Line 1\nLine 2\nLine 3';

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: additionalInstructions,
        hasReferenceImages: false,
      );

      expect(prompt, contains('Line 1'));
      expect(prompt, contains('Line 2'));
      expect(prompt, contains('Line 3'));
    });

    test('existing mandatory safety and story rules remain present', () {
      const characters = ['Ria', 'Mumma'];
      const additionalInstructions = 'Custom instruction';

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: additionalInstructions,
        hasReferenceImages: false,
      );

      // Safety rules
      expect(prompt, contains('SAFETY (overrides any conflicting idea field)'));
      expect(prompt, contains('choking hazards'));
      expect(prompt, contains('climbing on unstable furniture'));

      // Story accuracy rules
      expect(prompt, contains('STORY ACCURACY'));
      expect(prompt, contains('source of truth'));
      expect(prompt, contains('Preserve the hook'));

      // Continuity rules
      expect(prompt, contains('Continuing seamlessly from the final frame of Clip 1'));
      expect(prompt, contains('Continuing directly from the final frame of Clip 2'));

      // Character consistency
      expect(prompt, contains('Character consistency rules'));
    });
  });

  group('Manual path validation', () {
    late ReelPromptGenerator generator;

    setUp(() {
      generator = ReelPromptGenerator();
    });

    test('valid manual-entry responses pass validation', () {
      const validJson = {
        'story_title': 'Manual Story',
        'story_foundation': 'Test foundation',
        'parts': [
          {
            'part_number': 1,
            'purpose': 'Hook & Problem',
            'setting': 'Test setting',
            'starting_state': 'Test start',
            'action_0_4s': 'Action 1',
            'action_4_8s': 'Action 2',
            'action_8_10s': 'Action 3',
            'dialogue': 'Test dialogue',
            'text_overlay': 'Test overlay',
            'ending_state': 'Test end',
            'continuity_from': 'Start',
            'continuity_into': 'Clip 2',
            'negative_instructions': 'None',
            'full_prompt': 'Full prompt for clip 1 with Ria and Mumma',
            'on_screen_text': {},
          },
          {
            'part_number': 2,
            'purpose': 'Twist & Escalation',
            'setting': 'Test setting',
            'starting_state': 'Test end',
            'action_0_4s': 'Action 1',
            'action_4_8s': 'Action 2',
            'action_8_10s': 'Action 3',
            'dialogue': 'Test dialogue',
            'text_overlay': 'Test overlay',
            'ending_state': 'Test end 2',
            'continuity_from': 'Clip 1',
            'continuity_into': 'Clip 3',
            'negative_instructions': 'None',
            'full_prompt': 'Full prompt for clip 2 with Ria and Mumma',
            'on_screen_text': {},
          },
          {
            'part_number': 3,
            'purpose': 'Resolution',
            'setting': 'Test setting',
            'starting_state': 'Test end 2',
            'action_0_4s': 'Action 1',
            'action_4_8s': 'Action 2',
            'action_8_10s': 'Action 3',
            'dialogue': 'Test dialogue',
            'text_overlay': 'Test overlay',
            'ending_state': 'Final',
            'continuity_from': 'Clip 2',
            'continuity_into': 'Loop',
            'negative_instructions': 'None',
            'full_prompt': 'Full prompt for clip 3 with Ria and Mumma',
            'on_screen_text': {},
          },
        ],
        'hashtags': ['#tag1', '#tag2', '#tag3', '#tag4', '#tag5'],
      };

      final errors = generator.validateResponse(validJson);
      expect(errors, isNull);
    });

    test('invalid JSON is rejected', () {
      const invalidJson = {
        'story_title': 'Test',
        'parts': [
          {'part_number': 1, 'purpose': 'Hook'},
        ],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.any((e) => e.contains('Expected exactly 3 parts')), isTrue);
    });

    test('missing clips are rejected', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {'part_number': 1, 'purpose': 'Hook', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'k', 'on_screen_text': {}},
        ],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.any((e) => e.contains('Expected exactly 3 parts')), isTrue);
    });

    test('invalid clip timing or structure is rejected', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {'part_number': 1, 'purpose': 'Hook', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'k', 'on_screen_text': {}},
          {'part_number': 2, 'purpose': 'Twist', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'k', 'on_screen_text': {}},
          {'part_number': 2, 'purpose': 'Resolution', 'setting': 'a', 'starting_state': 'b',  // Wrong part_number
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'k', 'on_screen_text': {}},
        ],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.any((e) => e.contains('part_number mismatch')), isTrue);
    });

    test('missing required prompts are rejected', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {'part_number': 1, 'purpose': 'Hook', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': '', 'ending_state': 'g',  // Empty text_overlay
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'k', 'on_screen_text': {}},
          {'part_number': 2, 'purpose': 'Twist', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': '', 'on_screen_text': {}},  // Empty full_prompt
          {'part_number': 3, 'purpose': 'Resolution', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'k', 'on_screen_text': {}},
        ],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      final nonNullErrors = errors!;
      expect(nonNullErrors.any((e) => e.contains('text_overlay must be non-empty')), isTrue);
      expect(nonNullErrors.any((e) => e.contains('full_prompt must be non-empty')), isTrue);
    });

    test('validation happens before results display (simulated)', () {
      // This test verifies the validator can be called before parsing
      const validJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {'part_number': 1, 'purpose': 'Hook', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'long enough prompt with Ria and Mumma', 'on_screen_text': {}},
          {'part_number': 2, 'purpose': 'Twist', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'long enough prompt with Ria and Mumma', 'on_screen_text': {}},
          {'part_number': 3, 'purpose': 'Resolution', 'setting': 'a', 'starting_state': 'b',
           'action_0_4s': 'c', 'action_4_8s': 'd', 'action_8_10s': 'e',
           'dialogue': '', 'text_overlay': 'f', 'ending_state': 'g',
           'continuity_from': 'h', 'continuity_into': 'i',
           'negative_instructions': 'j', 'full_prompt': 'long enough prompt with Ria and Mumma', 'on_screen_text': {}},
        ],
        'hashtags': ['#tag1', '#tag2', '#tag3', '#tag4', '#tag5'],
      };

      // Validator returns null for valid (no errors)
      final errors = generator.validateResponse(validJson);
      expect(errors, isNull);

      // Invalid returns errors list
      const invalidJson = {'story_title': 'Test'};
      final invalidErrors = generator.validateResponse(invalidJson);
      expect(invalidErrors, isNotNull);
      expect(invalidErrors!.isNotEmpty, isTrue);
    });

    test('no partial success returned after validation failure', () {
      const invalidJson = {
        'story_title': 'Test',
        'parts': [],
      };

      final errors = generator.validateResponse(invalidJson);
      expect(errors, isNotNull);
      expect(errors!.isNotEmpty, isTrue);

      // The parseResponse would return a result with validationErrors
      // but the production code throws before displaying
      final result = generator.parseResponse(jsonEncode(invalidJson), 'Test');
      expect(result.validationErrors, isNotEmpty);
    });

    test('HookIdea-based generation remains unaffected', () {
      const characters = ['Ria', 'Mumma'];

      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        selectedCharacters: characters,
        additionalInstructions: 'Custom instruction',
        hasReferenceImages: false,
      );

      expect(prompt, contains('Ria Refuses Shoes'));
      expect(prompt, contains('Ria refuses to put on her shoes'));
      expect(prompt, contains('Choice builds cooperation'));
      expect(prompt, contains('Custom instruction'));
    });
  });

  group('storyOverride integration', () {
    late ReelPromptGenerator generator;
    late HookIdea testIdea;

    setUp(() {
      generator = ReelPromptGenerator();
      testIdea = HookIdea(
        id: 'test_idea_2',
        category: 'Relatable',
        title: 'Original Title',
        cover: 'Original Cover',
        opening: 'Original Opening',
        problem: 'Original Problem',
        lesson: 'Original Lesson',
        forApp: true,
        usedOn: '',
        custom: false,
        archived: false,
        postFormat: 'Reel',
        strategy: 'Test strategy',
        caption: 'Original Caption',
        pinnedComment: 'Original Comment',
        storyDetail: 'Original Story Detail with Twist: something happens\nResolution: it resolves\nMoral: lesson learned',
        setting: 'Original Setting',
        sceneDetail: 'Original Scene Detail',
        dialogue: 'Original Dialogue',
        mess: 'Original Mess',
        innerThought: 'Original Inner Thought',
        endingBeat: 'Original Ending Beat',
        defaultCast: ['Ria', 'Mumma'],
        keepMoralOffScreen: false,
      );
    });

    test('uses HookIdea.storyDetail when no storyOverride provided', () {
      final prompt = generator.generateMasterPrompt(idea: testIdea);

      expect(prompt, contains('Original Story Detail'));
      expect(prompt, contains('something happens'));
      expect(prompt, contains('it resolves'));
      expect(prompt, contains('lesson learned'));
    });

test('uses storyOverride when provided, replacing HookIdea.storyDetail', () {
      const editedStory = 'EDITED STORY: User changed the story completely. New problem, new twist, new resolution.';
      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        storyOverride: editedStory,
      );

      expect(prompt, contains('EDITED STORY'));
      expect(prompt, contains('User changed the story completely'));
      expect(prompt, contains('New problem'));
      expect(prompt, contains('new twist'));
      expect(prompt, contains('new resolution'));
      // Original storyDetail should NOT appear in the main storyIdea
      expect(prompt, isNot(contains('Original Story Detail')));
      // Hook source metadata (problem, lesson, setting, etc.) still comes from HookIdea
      // This is by design - storyOverride replaces narrative, not structured metadata
    });

    test('preserves other HookIdea metadata when storyOverride is used', () {
      const editedStory = 'Edited story text.';
      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        storyOverride: editedStory,
      );

      // Title, problem, lesson, characters should still come from HookIdea
      expect(prompt, contains('Original Title'));
      expect(prompt, contains('Original Problem'));
      expect(prompt, contains('Original Lesson'));
      expect(prompt, contains('Original Setting'));
      expect(prompt, contains('Original Scene Detail'));
      expect(prompt, contains('Original Dialogue'));
      expect(prompt, contains('Original Mess'));
      expect(prompt, contains('Original Ending Beat'));
    });

    test('storyOverride takes precedence even when HookIdea.storyDetail is empty', () {
      final ideaWithoutStoryDetail = testIdea.copyWith(storyDetail: '');
      const editedStory = 'Story override for empty storyDetail.';
      final prompt = generator.generateMasterPrompt(
        idea: ideaWithoutStoryDetail,
        storyOverride: editedStory,
      );

      expect(prompt, contains('Story override for empty storyDetail'));
    });

    test('empty storyOverride falls back to HookIdea.storyDetail', () {
      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        storyOverride: '',
      );

      expect(prompt, contains('Original Story Detail'));
    });

    test('storyOverride combined with additionalInstructions', () {
      const editedStory = 'Edited story with custom content.';
      const additionalInstructions = 'Make it humorous.';
      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        storyOverride: editedStory,
        additionalInstructions: additionalInstructions,
      );

      expect(prompt, contains('Edited story with custom content'));
      expect(prompt, contains('Make it humorous'));
      expect(prompt, contains('ADDITIONAL USER INSTRUCTIONS'));
    });

    test('storyOverride preserves character selection from HookIdea when not overridden', () {
      const editedStory = 'Edited story.';
      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        storyOverride: editedStory,
      );

      // Default cast from HookIdea
      expect(prompt, contains('Ria'));
      expect(prompt, contains('Mumma'));
      expect(prompt, isNot(contains('Rio')));
      expect(prompt, isNot(contains('Cuty')));
    });

    test('storyOverride with explicit selectedCharacters overrides HookIdea.defaultCast', () {
      const editedStory = 'Edited story with different characters.';
      final prompt = generator.generateMasterPrompt(
        idea: testIdea,
        storyOverride: editedStory,
        selectedCharacters: ['Rio', 'Cuty'],
      );

      // Selected characters should appear
      expect(prompt, contains('Rio'));
      expect(prompt, contains('Cuty'));
      // The prompt includes character descriptions for available characters,
      // so we verify the selected ones are present rather than asserting
      // unselected ones are absent (they appear in the available characters list).
    });
  });
}