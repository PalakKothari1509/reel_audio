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

  group('Regression: Conflicting overlay instructions resolved', () {
    test('video frames must contain no rendered text', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      // Video frames: NO rendered text
      expect(rendered, contains('GENERATED VIDEO FRAMES'));
      expect(rendered, contains('render NONE'));
      expect(rendered, contains('The video model must NOT render'));
    });

    test('spoken dialogue is separate from overlay text', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      // Spoken dialogue layer
      expect(rendered, contains('SPOKEN DIALOGUE'));
      expect(rendered, contains('what the characters say out loud'));
      expect(rendered, contains('This is audio, not graphics'));

      // Editor overlays layer
      expect(rendered, contains('EDITOR-ONLY OVERLAYS'));
      expect(rendered, contains('actual story-specific text'));
      expect(rendered, contains('sound-off viewing'));
      expect(rendered, contains('editor adds post-generation'));
      expect(rendered, contains('editor metadata'));
    });

    test('three layers are clearly separated', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      // The three distinct layers should be clearly documented
      expect(rendered, contains('THREE SEPARATE THINGS'));
      expect(rendered, contains('NEVER MIXED'));
    });
  });

  group('Regression: Dynamic character locks from valid cast', () {
    test('character lock built from validCharacters only', () {
      // Pass an invalid character name along with valid ones
      final vars = VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'InvalidCharacter', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
      );

      expect(vars.validCharacters, equals(['Ria', 'Mumma']));
      expect(vars.validCharacters, isNot(contains('InvalidCharacter')));
    });

    test('characterDescriptions only includes valid characters', () {
      final vars = VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'NotACharacter', 'Robot'],
        visualStyle: '3D',
        overallTone: 'Playful',
      );

      final desc = vars.characterDescriptions;
      expect(desc, contains(characterDescription('Ria')));
      expect(desc, contains(characterDescription('Robot')));
      expect(desc, isNot(contains('standard character appearance')));
    });

    test('rendered output only mentions valid characters', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'FakeCharacter', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('Ria'));
      expect(rendered, contains('Mumma'));
      expect(rendered, isNot(contains('FakeCharacter')));
      // Should contain descriptions for valid chars
      expect(rendered, contains(characterDescription('Ria')));
      expect(rendered, contains(characterDescription('Mumma')));
    });

    test('character lock block is built dynamically from valid cast', () {
      final vars = VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Mumma', 'Papa'],
        visualStyle: '3D',
        overallTone: 'Playful',
      );

      final lock = vars.characterLockBlock;
      expect(lock, contains('Mumma'));
      expect(lock, contains('Papa'));
      expect(lock, isNot(contains('Ria')));
      expect(lock, isNot(contains('Rio')));
      expect(lock, isNot(contains('Cuty')));
    });
  });

  group('Regression: Story-specific dialogue and actions', () {
    test('prompt demands idea-specific dialogue, not generic placeholders', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Shoe Independence',
        storyIdea: 'Ria wants to put her shoes on herself.',
        realLifeProblem: 'Rushing morning routine.',
        learningOutcome: 'Independence and patience.',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      // Should contain DIALOGUE AND ACTIONS section with specificity requirement
      expect(rendered, contains('DIALOGUE AND ACTIONS'));
      expect(rendered, contains('idea-specific'));
      expect(rendered, contains('concrete'));
      expect(rendered, contains('Replace generic placeholders'));
    });

    test('not every character forced to speak', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'Mumma', 'Papa'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('Not every character needs to speak'));
      expect(rendered, contains('silent character who acts is fine'));
    });

    test('Hinglish dialogue required for adults and children', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('Hinglish'));
      expect(rendered, contains('Adults speak natural Hindi or Hinglish'));
      expect(rendered, contains('children speak short, age-appropriate Hinglish'));
    });
  });

  group('Regression: Clip continuity with exact start/end states', () {
    test('CONTINUITY rules demand exact start/end states', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('CONTINUITY'));
      expect(rendered, contains('exact starting state'));
      expect(rendered, contains('exact ending state'));
      expect(rendered, contains('character positions, expressions, props, and background'));
      expect(rendered, contains('no teleporting'));
      expect(rendered, contains('unexplained outfit or prop changes'));
    });

    test('Part 2 and Part 3 continuation phrases enforced', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('Continuing seamlessly from the final frame of Clip 1'));
      expect(rendered, contains('Continuing directly from the final frame of Clip 2'));
      expect(rendered, contains('Do not restart the story'));
    });

test('VIDEO CONTINUITY RULES section present and detailed', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('VIDEO CONTINUITY RULES'));
      expect(rendered, contains('starting character positions'));
      expect(rendered, contains('appearances and clothing'));
      expect(rendered, contains('setting and important props'));
      expect(rendered, contains('camera position and movement'));
      expect(rendered, contains('lighting and visual style'));
      expect(rendered, contains('emotional')); // "emotional\nstate" split across lines
      expect(rendered, contains('exact visual state')); // "exact visual state at the\nend of the clip" split across lines
    });
  });

  group('Regression: Realistic preschool outcomes', () {
    test('prompt forbids implausible claims like cleaning whole house in minutes', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('REALISTIC PRESCHOOL OUTCOMES'));
      expect(rendered, contains('entire house is cleaned in minutes'));
      expect(rendered, contains('tantrum is cured instantly'));
      expect(rendered, contains('child masters an adult skill in one take'));
      expect(rendered, contains('imperfect but caring parenting'));
      expect(rendered, contains('not magic'));
    });

    test('small believable improvement emphasized', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('small, believable improvement'));
      expect(rendered, contains('one manageable step better'));
    });

    test('STORY ACCURACY preserves hook problem/twist/resolution/lesson', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains('STORY ACCURACY'));
      expect(rendered, contains('source of truth'));
      expect(rendered, contains('Preserve the hook'));
      expect(rendered, contains('central problem, twist, resolution, and lesson'));
      expect(rendered, contains('Do not introduce contradictory events'));
      expect(rendered, contains('unrelated characters'));
      expect(rendered, contains('different moral'));
    });

    test('HOOK SOURCE block injected when storyHook provided', () {
      final hook = StoryHookSource(
        problem: 'Ria refuses shoes',
        twist: 'Mumma offers choice',
        resolution: 'Ria picks red shoes',
        lesson: 'Choice builds cooperation',
        setting: 'Entryway',
        sceneDetail: 'Shoes by door',
        dialogue: 'Mumma: "Red or blue?"',
        mess: 'Ria throws tantrum',
        endingBeat: 'Ria puts on red shoes proudly',
      );

      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
        storyHook: hook,
      ));

      expect(rendered, contains('HOOK SOURCE (authoritative'));
      expect(rendered, contains('Ria refuses shoes'));
      expect(rendered, contains('Mumma offers choice'));
      expect(rendered, contains('Ria picks red shoes'));
      expect(rendered, contains('Choice builds cooperation'));
    });
  });

  group('Regression: Valid JSON structure and output validation', () {
    test('validateVideoMasterPromptJson validates exactly 3 parts', () {
      const validJson = {
        'story_title': 'Test Story',
        'story_foundation': 'Ria learns to put on her shoes with Mumma\'s help.',
        'parts': [
          {
            'part_number': 1,
            'purpose': 'Hook',
            'setting': 'Entryway',
            'starting_state': 'Ria standing by shoes',
            'action_0_4s': 'Ria picks up red shoe',
            'action_4_8s': 'Ria tries to put it on',
            'action_8_10s': 'Ria struggles, Mumma enters',
            'dialogue': 'Mumma: "Need help, beta?"',
            'text_overlay': 'Morning shoe struggle',
            'ending_state': 'Ria holding shoe, Mumma nearby',
            'continuity_from': 'Opening scene',
            'continuity_into': 'Mumma helps Ria',
            'negative_instructions': 'No extra characters',
            'full_prompt': 'Complete copy-paste-ready video generation prompt for Clip 1 with Ria and Mumma in entryway',
          },
          {
            'part_number': 2,
            'purpose': 'Twist',
            'setting': 'Entryway',
            'starting_state': 'Ria holding shoe, Mumma nearby',
            'action_0_4s': 'Mumma offers choice',
            'action_4_8s': 'Ria picks red shoe',
            'action_8_10s': 'Ria puts it on',
            'dialogue': 'Mumma: "Red or blue?"',
            'text_overlay': 'Choice builds cooperation',
            'ending_state': 'Ria wearing one shoe',
            'continuity_from': 'Clip 1 end',
            'continuity_into': 'Resolution',
            'negative_instructions': 'No extra characters',
            'full_prompt': 'Complete copy-paste-ready video generation prompt for Clip 2 with Ria and Mumma',
          },
          {
            'part_number': 3,
            'purpose': 'Resolution',
            'setting': 'Entryway',
            'starting_state': 'Ria wearing one shoe',
            'action_0_4s': 'Ria puts on second shoe',
            'action_4_8s': 'Ria stands up proudly',
            'action_8_10s': 'Mumma high-fives Ria',
            'dialogue': 'Ria: "Main khud karungi!"',
            'text_overlay': 'Independence! Save this tip.',
            'ending_state': 'Ria ready, Mumma smiling',
            'continuity_from': 'Clip 2 end',
            'continuity_into': 'Loop to start',
            'negative_instructions': 'No extra characters',
            'full_prompt': 'Complete copy-paste-ready video generation prompt for Clip 3 with Ria and Mumma',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(validJson);
      expect(result.isValid, isTrue);
    });

    test('validateVideoMasterPromptJson rejects wrong part count', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here'},
          {'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here'},
        ],
      };

      final result = validateVideoMasterPromptJson(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('Expected exactly 3 parts')));
    });

    test('validateVideoMasterPromptJson rejects missing required fields', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {
            'part_number': 1,
            'purpose': 'a',
            'setting': 'b',
            // missing starting_state, action_0_4s, etc.
            'dialogue': '',
            'text_overlay': 'g',
            'ending_state': 'h',
            'continuity_from': 'i',
            'continuity_into': 'j',
            'negative_instructions': 'k',
            'full_prompt': 'long enough prompt text here',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('missing or empty')));
    });

    test('validateVideoMasterPromptJson validates 5 hashtags', () {
      const jsonWithHashtags = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'hashtags': ['#fun', '#learning', '#kids', '#parenting', '#tips'],
        'parts': [
          {
            'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
          {
            'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
          {
            'part_number': 3, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(jsonWithHashtags);
      expect(result.isValid, isTrue);
    });

    test('validateVideoMasterPromptJson rejects invalid hashtag count', () {
      const jsonWithHashtags = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'hashtags': ['#one', '#two'],
        'parts': [
          {
            'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
          {
            'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
          {
            'part_number': 3, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(jsonWithHashtags);
      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('Expected exactly 5 hashtags')));
    });

    test('validateVideoMasterPromptJson validates story-specific visual prompts', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {
            'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'short',
          },
          {
            'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'short',
          },
          {
            'part_number': 3, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'short',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('full_prompt too short')));
    });

    test('validateVideoMasterPromptJson validates character names in full_prompt', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {
            'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'A random prompt with no character names at all',
          },
          {
            'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'A random prompt with no character names at all',
          },
          {
            'part_number': 3, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'A random prompt with no character names at all',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(invalidJson, validCharacterNames: ['Ria', 'Rio', 'Cuty', 'Robot', 'Mumma', 'Papa', 'Daadi', 'Teacher']);
      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('does not mention any valid character')));
    });

    test('validateVideoMasterPromptJson requires non-empty story-specific text_overlay', () {
      const invalidJson = {
        'story_title': 'Test',
        'story_foundation': 'Test',
        'parts': [
          {
            'part_number': 1, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': '', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
          {
            'part_number': 2, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
          {
            'part_number': 3, 'purpose': 'a', 'setting': 'b', 'starting_state': 'c', 'action_0_4s': 'd', 'action_4_8s': 'e', 'action_8_10s': 'f', 'dialogue': '', 'text_overlay': 'g', 'ending_state': 'h', 'continuity_from': 'i', 'continuity_into': 'j', 'negative_instructions': 'k', 'full_prompt': 'long enough prompt text here with Ria',
          },
        ],
      };

      final result = validateVideoMasterPromptJson(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('text_overlay must be non-empty')));
    });
  });

  group('Regression: Preservation of existing idea content', () {
    test('all story input fields preserved in rendered prompt', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Main Khud Karungi',
        storyIdea: 'Ria wants to put her shoes on herself.',
        realLifeProblem: 'Rushing morning routine.',
        learningOutcome: 'Independence and patience.',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: 'Vibrant 3D animation',
        overallTone: 'Heartwarming and relatable',
        videoGenerator: 'Runway Gen-2',
        language: 'Hinglish',
      ));

      expect(rendered, contains('Main Khud Karungi'));
      expect(rendered, contains('Ria wants to put her shoes on herself.'));
      expect(rendered, contains('Rushing morning routine.'));
      expect(rendered, contains('Independence and patience.'));
      expect(rendered, contains('Ria, Mumma'));
      expect(rendered, contains('Vibrant 3D animation'));
      expect(rendered, contains('Heartwarming and relatable'));
      expect(rendered, contains('Runway Gen-2'));
      expect(rendered, contains('Hinglish'));
    });

    test('character descriptions match library exactly', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'Mumma', 'Daadi'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, contains(characterDescription('Ria')));
      expect(rendered, contains(characterDescription('Mumma')));
      expect(rendered, contains(characterDescription('Daadi')));
    });

    test('STORY HOOK block preserves all hook fields when provided', () {
      final hook = StoryHookSource(
        problem: 'Shoe refusal',
        twist: 'Choice offered',
        resolution: 'Shoe chosen',
        lesson: 'Choice empowers',
        setting: 'Entryway',
        sceneDetail: 'Shoes by door',
        dialogue: 'Mumma: "Pick one"',
        mess: 'Tantrum',
        endingBeat: 'Happy feet',
      );

      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria', 'Mumma'],
        visualStyle: '3D',
        overallTone: 'Playful',
        storyHook: hook,
      ));

      // All hook fields preserved
      expect(rendered, contains('Shoe refusal'));
      expect(rendered, contains('Choice offered'));
      expect(rendered, contains('Shoe chosen'));
      expect(rendered, contains('Choice empowers'));
      expect(rendered, contains('Entryway'));
      expect(rendered, contains('Shoes by door'));
      expect(rendered, contains('Mumma: "Pick one"'));
      expect(rendered, contains('Tantrum'));
      expect(rendered, contains('Happy feet'));
    });

    test('no placeholders remain after rendering', () {
      final rendered = renderVideoMasterPrompt(VideoPromptVariables(
        storyTitle: 'Test',
        storyIdea: 'Test',
        realLifeProblem: 'Test',
        learningOutcome: 'Test',
        selectedCharacters: ['Ria'],
        visualStyle: '3D',
        overallTone: 'Playful',
      ));

      expect(rendered, isNot(contains('{{')));
    });
  });
}
