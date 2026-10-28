import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/story_reel_builder.dart';
import 'package:reel_audio/story_ideas.dart';

void main() {
  const beats = BeatSheet(
    id: 'box-beat',
    title: "Rio's Box",
    characters: ['ria', 'rio', 'cuty'],
    where: 'Living room, afternoon light',
    hook: 'Rio ne box chupa diya?!',
    beat1Setup: 'The family is packing a big cardboard box together.',
    beat2Problem: 'Rio climbs inside the box and pulls the lid shut.',
    beat3Escalation: 'Nobody can find him and the box starts to roll across the floor.',
    beat4Turn: 'Ria hears a muffled giggle from inside the box.',
    beat5Payoff: 'They open it and Rio pops out laughing.',
    stretchBeat: 'Mumma tries to carry the box and it tips over.',
    endingLine: 'Khelne mein kuch bhi ho, sab milke theek karte hain',
    closingCta: 'Save this for your own box day',
  );

  group('buildVideoPrompts duration mapping', () {
    test('20s produces exactly 2 prompts', () {
      expect(buildVideoPrompts(beats: beats, seconds: 20).length, 2);
    });

    test('30s produces exactly 3 prompts', () {
      expect(buildVideoPrompts(beats: beats, seconds: 30).length, 3);
    });

    test('40s produces exactly 4 prompts', () {
      expect(buildVideoPrompts(beats: beats, seconds: 40).length, 4);
    });

    test('60s produces exactly 6 prompts', () {
      expect(buildVideoPrompts(beats: beats, seconds: 60).length, 6);
    });

    test('unsupported durations throw', () {
      expect(() => buildVideoPrompts(beats: beats, seconds: 50),
          throwsArgumentError);
    });
  });

  group('part numbering', () {
    test('each prompt knows its part number and total', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 30);
      expect(prompts[0].partNumber, 1);
      expect(prompts[0].totalParts, 3);
      expect(prompts[1].partNumber, 2);
      expect(prompts[2].partNumber, 3);
    });

    test('the title reads "Part N of M"', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 40);
      expect(prompts[0].title, 'Part 1 of 4');
      expect(prompts[3].title, 'Part 4 of 4');
    });
  });

  group('prompt completeness', () {
    const requiredSections = [
      'STYLE:',
      'SIZE:',
      'CHARACTER LOCK',
      'SETTING:',
      'CAMERA:',
      'ACTION:',
      '0-4s:',
      '4-8s:',
      '8-10s:',
      'AUDIO:',
      'AVOID:',
    ];

    for (final seconds in [20, 30, 40, 60]) {
      test('every part at $seconds includes all required sections', () {
        final prompts = buildVideoPrompts(beats: beats, seconds: seconds);
        for (final p in prompts) {
          for (final section in requiredSections) {
            expect(p.promptText, contains(section),
                reason: 'Part ${p.partNumber} of ${p.totalParts} is '
                    'missing the "$section" section');
          }
        }
      });
    }

    test('every part includes all three action intervals', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 40);
      for (final p in prompts) {
        expect(p.promptText, contains('0-4s:'));
        expect(p.promptText, contains('4-8s:'));
        expect(p.promptText, contains('8-10s:'));
      }
    });

    test('no part repeats the same beat in all three intervals', () {
      // A part with only one beat must still develop it across 4-10s rather
      // than printing the same sentence three times.
      for (final seconds in [20, 30, 40, 60]) {
        final prompts = buildVideoPrompts(beats: beats, seconds: seconds);
        for (final p in prompts) {
          final actions = RegExp(r'(?:0-4s:|4-8s:|8-10s:)\s*(.+?)$')
              .allMatches(p.promptText)
              .map((m) => m.group(1)!.trim())
              .toList();
          if (actions.length >= 3) {
            final distinct = actions.toSet();
            expect(distinct.length, greaterThan(1),
                reason: 'Part ${p.partNumber} of ${seconds}s repeats the '
                    'same action in every interval');
          }
        }
      }
    });

    test('the setting comes from the beat sheet', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 20);
      for (final p in prompts) {
        expect(p.promptText, contains('Living room, afternoon light'));
      }
    });
  });

  group('character selection', () {
    test('only the selected characters are listed in the character lock', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 30);
      for (final p in prompts) {
        // The character lock block lists the cast on its own line.
        expect(p.promptText, contains('Ria, Rio, Cuty'));
        // Mumma and Papa are not in this beat sheet and must not appear as
        // cast members in the character lock block.
        final lockStart = p.promptText.indexOf('CHARACTER LOCK');
        final lockEnd = p.promptText.indexOf('RULES:');
        final lockBlock = p.promptText.substring(lockStart, lockEnd);
        expect(lockBlock, isNot(contains('Mumma')));
        expect(lockBlock, isNot(contains('Papa')));
      }
    });

    test('a beat sheet with only Mumma does not force Ria, Rio and Cuty', () {
      const mummaOnly = BeatSheet(
        id: 'mumma-only',
        title: 'Mumma alone',
        characters: ['mumma'],
        where: 'Kitchen',
        hook: 'hook',
        beat1Setup: 'setup',
        beat2Problem: 'problem',
        beat3Escalation: 'escalation',
        beat4Turn: 'turn',
        beat5Payoff: 'payoff',
        endingLine: 'ending',
        closingCta: 'cta',
      );
      final prompts = buildVideoPrompts(beats: mummaOnly, seconds: 20);
      for (final p in prompts) {
        expect(p.promptText, contains('Mumma'));
        // The cast line in the lock block must list only Mumma.
        final lockStart = p.promptText.indexOf('CHARACTER LOCK');
        final lockEnd = p.promptText.indexOf('RULES:');
        final lockBlock = p.promptText.substring(lockStart, lockEnd);
        expect(lockBlock, contains('Mumma'));
        expect(lockBlock, isNot(contains('Ria, Rio, Cuty')));
        expect(lockBlock, isNot(contains('Cuty')));
      }
    });
  });

  group('character-specific rules', () {
    test('no hardcoded character rules when different cast is selected', () {
      const mummaOnly = BeatSheet(
        id: 'mumma-only',
        title: 'Mumma alone',
        characters: ['mumma'],
        where: 'Kitchen',
        hook: 'hook',
        beat1Setup: 'setup',
        beat2Problem: 'problem',
        beat3Escalation: 'escalation',
        beat4Turn: 'turn',
        beat5Payoff: 'payoff',
        endingLine: 'ending',
        closingCta: 'cta',
      );
      final prompts = buildVideoPrompts(beats: mummaOnly, seconds: 20);
      for (final p in prompts) {
        // Must not contain hardcoded rules for Ria/Rio/Cuty
        expect(p.promptText, isNot(contains('Ria and Rio must never wear glasses')));
        expect(p.promptText, isNot(contains('Cuty is ALWAYS')));
      }
    });
  });

  group('continuity', () {
    test('Part 1 has no continuity line', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 30);
      expect(prompts[0].promptText, isNot(contains('CONTINUITY')));
    });

    test('Parts 2+ include a continuity instruction', () {
      for (final seconds in [20, 30, 40, 60]) {
        final prompts = buildVideoPrompts(beats: beats, seconds: seconds);
        for (var i = 1; i < prompts.length; i++) {
          expect(prompts[i].promptText, contains('CONTINUITY'),
              reason: 'Part ${i + 1} of ${seconds}s must continue from '
                  'the previous clip');
          expect(prompts[i].promptText, contains('previous clip'));
        }
      }
    });

    test('continuity forbids restarting the story', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 40);
      for (var i = 1; i < prompts.length; i++) {
        expect(prompts[i].promptText, contains('Do not restart the story'));
      }
    });
  });

  group('self-contained prompts', () {
    test('each prompt can be pasted into a video generator on its own', () {
      final prompts = buildVideoPrompts(beats: beats, seconds: 30);
      for (final p in prompts) {
        // A standalone prompt must not depend on surrounding context.
        expect(p.promptText, contains('Create a 10-second vertical 9:16'));
        expect(p.promptText, contains(BrandDefaults.visualStyle));
        expect(p.promptText, contains('9:16 (1080x1920)'));
        expect(p.promptText, contains('AVOID:'));
      }
    });
  });
}