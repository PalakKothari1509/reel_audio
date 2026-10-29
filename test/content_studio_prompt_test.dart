import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/characters.dart';
import 'package:reel_audio/content_studio_service.dart';
import 'package:reel_audio/master_prompt.dart';

void main() {
  group('buildMasterReelPrompt character handling', () {
    test('uses the characters parameter for CHARACTER LOCK, not hardcoded cast', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Priya learns to share with Daadi',
        characters: ['Priya', 'Daadi', 'Ria'],
        language: 'Hinglish',
      );

      expect(prompt, contains('CHARACTER LOCK'));
      expect(prompt, contains(characterDescription('Priya')));
      expect(prompt, contains(characterDescription('Daadi')));
      expect(prompt, contains(characterDescription('Ria')));
    });

    test('does not hardcode Ria, Rio, Cuty in the CHARACTER LOCK section', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Mumma teaches Baby to brush',
        characters: ['Mumma', 'Daadi'],
        language: 'Hinglish',
      );

      final lockStart = prompt.indexOf('CHARACTER LOCK');
      final lockEnd = prompt.indexOf('CHARACTER CONTINUITY RULES');
      final lockBlock = prompt.substring(lockStart, lockEnd);

      expect(lockBlock, contains('Mumma'));
      expect(lockBlock, contains('Daadi'));
      expect(lockBlock, isNot(contains('Ria')));
      expect(lockBlock, isNot(contains('Rio')));
      expect(lockBlock, isNot(contains('Cuty')));
    });

    test('Cuty appears in >=2 clips rule is removed', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Cuty loses her bow',
        characters: ['Cuty', 'Ria'],
        language: 'Hinglish',
      );

      expect(prompt, isNot(contains('at least 2 clips')));
      expect(prompt, isNot(contains('emotional anchor')));
    });

    test('glasses rule is dynamic based on selected characters', () {
      final withRia = buildMasterReelPrompt(
        idea: 'Ria plays',
        characters: ['Ria', 'Mumma'],
        language: 'Hinglish',
      );
      expect(withRia, contains('Ria'), reason: 'Should mention Ria when selected');

      final withoutRia = buildMasterReelPrompt(
        idea: 'Mumma cooks',
        characters: ['Mumma', 'Daadi'],
        language: 'Hinglish',
      );
      expect(withoutRia, isNot(contains('Ria and Rio NEVER wear glasses')));
      expect(withoutRia, isNot(contains('glasses on Ria/Rio')));
    });
  });

  group('buildMasterReelPrompt text-as-metadata', () {
    test('negative instructions say NO on-screen text in video', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Test story',
        characters: ['Ria', 'Rio'],
        language: 'Hinglish',
      );

      expect(prompt, contains('NO on-screen text of any kind'));
      expect(prompt, contains('Text is added later in the editor'));
    });

    test('on_screen_text is marked as editor metadata only', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Test story',
        characters: ['Ria'],
        language: 'Hinglish',
      );

      expect(prompt, contains('editor metadata'));
      expect(prompt, contains('do NOT render in video'));
    });

    test('CLIP STRUCTURE does not instruct on-screen text rendering', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Test story',
        characters: ['Ria'],
        language: 'Hinglish',
      );

      // The old format had "On-Screen Text:" with timing cues
      // The new format has "Editor Metadata" instead
      expect(prompt, isNot(contains('On-Screen Text:\n  - 0s')));
      expect(prompt, contains('Editor Metadata'));
    });

    test('prohibits rendered text overlays on video frames', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Test story',
        characters: ['Ria'],
        language: 'Hinglish',
      );

      // No text rendered in video frames — editor adds text post-generation
      expect(prompt, contains('NO on-screen text of any kind'));
      expect(prompt, contains('Text is added later in the editor'));
    });
  });

  group('buildMasterReelPrompt with reference images', () {
    test('omits character descriptions when reference images provided', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Mumma and Daadi bake cookies',
        characters: ['Mumma', 'Daadi'],
        language: 'Hinglish',
        hasReferenceImages: true,
      );

      expect(prompt, isNot(contains(characterDescription('Mumma'))));
      expect(prompt, isNot(contains(characterDescription('Daadi'))));
    });

    test('includes short reference image instruction when images provided', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria plays',
        characters: ['Ria'],
        language: 'Hinglish',
        hasReferenceImages: true,
      );

      expect(prompt, contains('Use the attached reference images as the definitive character references'));
      expect(prompt, contains('Preserve each character\'s face, age, hair, outfit, colours and proportions across ALL parts'));
    });

    test('includes character descriptions when no reference images (fallback)', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria plays',
        characters: ['Ria'],
        language: 'Hinglish',
        hasReferenceImages: false,
      );

      expect(prompt, contains(characterDescription('Ria')));
    });
  });

  group('buildGeminiVideoPrompt character handling', () {
    test('uses characters parameter for character block', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Daadi tells a story',
        totalSeconds: 30,
        characters: ['Daadi', 'Priya'],
      );

      expect(prompt, contains(characterDescription('Daadi')));
      expect(prompt, contains(characterDescription('Priya')));
    });

    test('no hardcoded Ria/Rio/Cuty rules when different cast selected', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Mumma and Papa cook',
        totalSeconds: 30,
        characters: ['Mumma', 'Papa'],
      );

      expect(prompt, isNot(contains('Ria and Rio NEVER wear glasses')));
      expect(prompt, isNot(contains('Cuty is ALWAYS')));
    });
  });

  group('buildGeminiVideoPrompt text-as-metadata', () {
    test('negative instructions say text is editor metadata', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Test story',
        totalSeconds: 30,
        characters: ['Ria', 'Rio'],
      );

      expect(prompt, contains('NO on-screen text rendered in video frames'));
      expect(prompt, contains('editor metadata'));
    });
  });

  group('buildGeminiVideoPrompt with reference images', () {
    test('omits character descriptions when reference images provided', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Mumma and Daadi bake cookies',
        totalSeconds: 30,
        characters: ['Mumma', 'Daadi'],
        hasReferenceImages: true,
      );

      expect(prompt, isNot(contains(characterDescription('Mumma'))));
      expect(prompt, isNot(contains(characterDescription('Daadi'))));
    });

    test('includes short reference image instruction when images provided', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria plays',
        totalSeconds: 30,
        characters: ['Ria'],
        hasReferenceImages: true,
      );

      expect(prompt, contains('Use the attached reference images as the definitive character references'));
      expect(prompt, isNot(contains('Use the exact descriptions above for every part')));
    });

    test('includes character descriptions when no reference images (fallback)', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria plays',
        totalSeconds: 30,
        characters: ['Ria'],
        hasReferenceImages: false,
      );

      expect(prompt, contains(characterDescription('Ria')));
      expect(prompt, contains('Use the exact descriptions above for every part'));
    });
  });

  group('master_prompt kCharacterRules', () {
    test('does not hardcode specific character names', () {
      expect(kCharacterRules, isNot(contains('Ria and Rio NEVER wear glasses')));
      expect(kCharacterRules, isNot(contains('Cuty is ALWAYS')));
      expect(kCharacterRules, isNot(contains('Robot is friendly')));
    });

    test('mentions characters generically', () {
      expect(kCharacterRules, contains('characters'));
      expect(kCharacterRules, contains('CHARACTER LOCK'));
    });
  });

  group('characterLockFor dynamic rules', () {
    test('includes glasses rule when Ria is in cast', () {
      final lock = CharacterLibrary.characterLockFor([
        CharacterLibrary.ria,
        CharacterLibrary.mumma,
      ]);
      expect(lock, contains('Ria and Rio NEVER wear glasses'));
    });

    test('omits glasses rule when Ria is not in cast', () {
      final lock = CharacterLibrary.characterLockFor([
        CharacterLibrary.mumma,
        CharacterLibrary.papa,
      ]);
      expect(lock, isNot(contains('Ria and Rio')));
      expect(lock, isNot(contains('glasses')));
    });

    test('includes Cuty rule when Cuty is in cast', () {
      final lock = CharacterLibrary.characterLockFor([
        CharacterLibrary.cuty,
        CharacterLibrary.rio,
      ]);
      expect(lock, contains('Cuty is ALWAYS a small white bunny'));
    });

    test('omits Cuty rule when Cuty is not in cast', () {
      final lock = CharacterLibrary.characterLockFor([
        CharacterLibrary.mumma,
      ]);
      expect(lock, isNot(contains('Cuty')));
    });
  });

  group('negative_instructions no hardcoded glasses', () {
    test('buildMasterReelPrompt JSON template omits glasses rule', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Test story',
        characters: ['Ria', 'Mumma'],
        language: 'Hinglish',
      );

      expect(prompt, isNot(contains('no glasses on child characters')));
    });

    test('buildGeminiVideoPrompt JSON template omits glasses rule', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Test story',
        totalSeconds: 30,
        characters: ['Ria', 'Mumma'],
      );

      expect(prompt, isNot(contains('no glasses on child characters')));
    });
  });

  group('buildMasterReelPrompt safety rules', () {
    test('includes SAFETY section with choking hazard rule', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria plays with small toys',
        characters: ['Ria', 'Cuty'],
        language: 'Hinglish',
      );

      expect(prompt, contains('SAFETY:'));
      expect(prompt, contains('choking hazards'));
      expect(prompt, contains('small objects near babies under 3'));
    });

    test('includes fear-based scenario rule', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria is scared of thunder',
        characters: ['Ria', 'Mumma'],
        language: 'Hinglish',
      );

      expect(prompt, contains('fear-based scenarios'));
      expect(prompt, contains('sensitive child'));
    });
  });

  group('buildMasterReelPrompt shareability', () {
    test('includes SHAREABILITY section asking why parent would send', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria refuses to wear shoes',
        characters: ['Ria', 'Mumma'],
        language: 'Hinglish',
      );

      expect(prompt, contains('SHAREABILITY:'));
      expect(prompt, contains('Why would one parent send this to another parent'));
    });
  });

  group('buildMasterReelPrompt character voice patterns', () {
    test('includes voice patterns for selected characters', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria shares toys with Cuty',
        characters: ['Ria', 'Cuty'],
        language: 'Hinglish',
      );

      expect(prompt, contains('CHARACTER VOICE PATTERNS'));
      expect(prompt, contains('Ria:'));
      expect(prompt, contains('Cuty:'));
    });

    test('omits voice patterns section when characters have no speech patterns', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Story with unnamed characters',
        characters: ['Unknown1', 'Unknown2'],
        language: 'Hinglish',
      );

      expect(prompt, isNot(contains('CHARACTER VOICE PATTERNS')));
    });
  });

  group('buildMasterReelPrompt caption and pin_comment fields', () {
    test('includes caption field in JSON schema', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria learns to share',
        characters: ['Ria', 'Cuty', 'Mumma'],
        language: 'Hinglish',
      );

      expect(prompt, contains('"caption"'));
      expect(prompt, contains('Instagram caption'));
    });

    test('includes hashtags field in JSON schema', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria learns to share',
        characters: ['Ria', 'Cuty'],
        language: 'Hinglish',
      );

      expect(prompt, contains('"hashtags"'));
      expect(prompt, contains('story-relevant'));
    });

    test('includes pin_comment field in JSON schema', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria learns to share',
        characters: ['Ria'],
        language: 'Hinglish',
      );

      expect(prompt, contains('"pin_comment"'));
      expect(prompt, contains('parent\'s own house'));
    });
  });

  group('buildGeminiVideoPrompt safety and shareability', () {
    test('includes SAFETY section', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria plays with toys',
        totalSeconds: 30,
        characters: ['Ria'],
      );

      expect(prompt, contains('SAFETY:'));
      expect(prompt, contains('choking hazards'));
    });

    test('excludes brand handle from video prompt', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria plays with toys',
        totalSeconds: 30,
        characters: ['Ria'],
      );

      // Instagram handle must NOT appear in video prompts
      expect(prompt, isNot(contains('(@funlearningwithpalak)')));
      expect(prompt, isNot(contains('@funlearningwithpalak')));
    });

    test('includes SHAREABILITY section', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria shares toys',
        totalSeconds: 30,
        characters: ['Ria'],
      );

      expect(prompt, contains('SHAREABILITY:'));
    });

    test('includes caption and pin_comment in JSON schema', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria shares toys',
        totalSeconds: 30,
        characters: ['Ria'],
      );

      expect(prompt, contains('"caption"'));
      expect(prompt, contains('"hashtags"'));
      expect(prompt, contains('"pin_comment"'));
    });

    test('includes voice patterns for selected characters', () {
      final prompt = buildGeminiVideoPrompt(
        idea: 'Ria shares toys with Cuty',
        totalSeconds: 30,
        characters: ['Ria', 'Cuty'],
      );

      expect(prompt, contains('CHARACTER VOICE PATTERNS'));
      expect(prompt, contains('Ria:'));
    });
  });

  group('buildMasterReelPrompt brand handle exclusion', () {
    test('excludes brand handle from master reel video prompt', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria refuses to wear shoes',
        characters: ['Ria', 'Mumma'],
        language: 'Hinglish',
      );

      // Instagram handle must NOT appear in video prompts
      expect(prompt, isNot(contains('(@funlearningwithpalak)')));
      expect(prompt, isNot(contains('@funlearningwithpalak')));

      // Brand name should still be present without handle
      expect(prompt, contains('Fun Learning With Palak'));
    });
  });

  group('buildMasterReelPrompt no-text overlay directive', () {
    test('prohibits rendered text overlays', () {
      final prompt = buildMasterReelPrompt(
        idea: 'Ria learns to share',
        characters: ['Ria', 'Cuty'],
        language: 'Hinglish',
      );

      expect(prompt, contains('NO on-screen text of any kind'));
      expect(prompt, contains('Text is added later in the editor'));
      expect(prompt, contains('editor metadata'));
      expect(prompt, contains('do NOT render in video'));
    });
  });
}
