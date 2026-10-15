import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/story_ideas.dart';

void main() {
  group('BrandDefaults', () {
    test('name is Fun Learning With Palak', () {
      expect(BrandDefaults.name, 'Fun Learning With Palak');
    });

    test('handle is the Instagram handle', () {
      expect(BrandDefaults.handle, '@funlearningwithpalak');
    });

    test('audience targets Indian parents of 1-4 year olds', () {
      expect(BrandDefaults.audience.contains('1-4'), isTrue);
      expect(BrandDefaults.audience.contains('Indian'), isTrue);
    });

    test('hashtagCount is 5', () {
      expect(BrandDefaults.hashtagCount, 5);
    });

    test('hashtagPool includes required brand hashtag', () {
      expect(BrandDefaults.hashtagPool, contains('#funlearningwithpalak'));
    });

    test('has at least 5 hashtags in the pool', () {
      expect(BrandDefaults.hashtagPool.length, greaterThanOrEqualTo(5));
    });

    test('ctaOptions includes share and save options', () {
      expect(BrandDefaults.ctaOptions.any((c) => c.contains('Share')), isTrue);
      expect(BrandDefaults.ctaOptions.any((c) => c.contains('Save')), isTrue);
    });
  });

  group('CharacterLibrary', () {
    test('has all five main characters', () {
      expect(CharacterLibrary.all.length, 5);
      expect(CharacterLibrary.all.map((c) => c.id),
          containsAll(['ria', 'rio', 'cuty', 'mumma', 'papa']));
    });

    test('Ria is playful and energetic', () {
      final ria = CharacterLibrary.ria;
      expect(ria.name, 'Ria');
      expect(ria.personality.toLowerCase(), contains('playful'));
      expect(ria.personality.toLowerCase(), contains('energetic'));
    });

    test('Rio is stubborn and expressive', () {
      final rio = CharacterLibrary.rio;
      expect(rio.name, 'Rio');
      expect(rio.personality.toLowerCase(), contains('stubborn'));
      expect(rio.personality.toLowerCase(), contains('playful'));
    });

    test('Cuty is a peaceful sleep-loving bunny', () {
      final cuty = CharacterLibrary.cuty;
      expect(cuty.name, 'Cuty');
      expect(cuty.personality.toLowerCase(), contains('sleep'));
    });

    test('Mumma is warm and patient', () {
      final mumma = CharacterLibrary.mumma;
      expect(mumma.name, 'Mumma');
      expect(mumma.personality.toLowerCase(), contains('warm'));
      expect(mumma.personality.toLowerCase(), contains('patient'));
    });

    test('Papa is playful and joins in games', () {
      final papa = CharacterLibrary.papa;
      expect(papa.name, 'Papa');
      expect(papa.personality.toLowerCase(), contains('playful'));
    });

    test('Mumma has a Hinglish speech pattern', () {
      expect(CharacterLibrary.mumma.speechPattern, isNotEmpty);
      expect(CharacterLibrary.mumma.speechPattern.toLowerCase(), contains('hinglish'));
    });

    test('byId returns the correct character', () {
      expect(CharacterLibrary.byId('ria'), same(CharacterLibrary.ria));
      expect(CharacterLibrary.byId('rio'), same(CharacterLibrary.rio));
      expect(CharacterLibrary.byId('nonexistent'), isNull);
    });

    test('characterLockBlock includes all characters', () {
      final lock = CharacterLibrary.characterLockBlock;
      expect(lock, contains('Ria'));
      expect(lock, contains('Rio'));
      expect(lock, contains('Cuty'));
      expect(lock, contains('Ria and Rio NEVER wear glasses'));
      expect(lock, contains('Cuty is ALWAYS a small white bunny with a pink bow'));
    });
  });

  group('StoryCheck.contentPurpose', () {
    test('returns RELATE when real-life problem passes', () {
      final check = StoryCheck(
        score: 9,
        good: [],
        missing: [],
        verdict: 'test',
        rows: [CheckRow('Real-life problem', true, '')],
      );
      expect(check.contentPurpose, 'RELATE');
    });

    test('returns LEARN when child learns naturally passes', () {
      final check = StoryCheck(
        score: 9,
        good: [],
        missing: [],
        verdict: 'test',
        rows: [CheckRow('Child learns naturally', true, '')],
      );
      expect(check.contentPurpose, 'LEARN');
    });

    test('returns FEEL when emotion passes', () {
      final check = StoryCheck(
        score: 9,
        good: [],
        missing: [],
        verdict: 'test',
        rows: [CheckRow('Emotion', true, '')],
      );
      expect(check.contentPurpose, 'FEEL');
    });

    test('returns LAUGH when hook and curiosity both pass', () {
      final check = StoryCheck(
        score: 9,
        good: [],
        missing: [],
        verdict: 'test',
        rows: [
          CheckRow('Hook', true, ''),
          CheckRow('Curiosity', true, ''),
        ],
      );
      expect(check.contentPurpose, 'LAUGH');
    });

    test('returns SHARE when share value passes but not others', () {
      final check = StoryCheck(
        score: 8,
        good: [],
        missing: [],
        verdict: 'test',
        rows: [CheckRow('Share value', true, '')],
      );
      expect(check.contentPurpose, 'SHARE');
    });

    test('defaults to RELATE when no purpose-related checks pass', () {
      final check = StoryCheck(
        score: 5,
        good: [],
        missing: [],
        verdict: 'test',
        rows: [CheckRow('Originality', true, '')],
      );
      expect(check.contentPurpose, 'RELATE');
    });
  });
}
