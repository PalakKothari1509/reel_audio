import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/story_ideas.dart';

void main() {
  group('BeatSheet', () {
    const beats = BeatSheet(
      id: 'test-beat',
      title: 'Test Beat 📦',
      characters: ['ria', 'rio', 'cuty'],
      where: 'Living room',
      hook: 'Rio ne box chupa diya?!',
      beat1Setup: 'The family is packing a box together.',
      beat2Problem: 'Rio hides inside the box and closes the lid.',
      beat3Escalation: 'Nobody can find him and the box starts to roll.',
      beat4Turn: 'Ria hears a muffled giggle from inside.',
      beat5Payoff: 'They open it and Rio pops out laughing.',
      stretchBeat: 'Mumma tries to carry the box and it tips over.',
      endingLine: 'Khelne mein kuch bhi ho, sab milke theek karte hain',
      closingCta: 'Save this for your own box day',
      hashtags: ['#funlearningwithpalak', '#toddlerfun', '#storytime'],
      bestLength: 30,
    );

    test('round-trips through JSON', () {
      final restored = BeatSheet.fromJson(beats.toJson());
      expect(restored.id, beats.id);
      expect(restored.title, beats.title);
      expect(restored.characters, beats.characters);
      expect(restored.where, beats.where);
      expect(restored.hook, beats.hook);
      expect(restored.beat1Setup, beats.beat1Setup);
      expect(restored.beat2Problem, beats.beat2Problem);
      expect(restored.beat3Escalation, beats.beat3Escalation);
      expect(restored.beat4Turn, beats.beat4Turn);
      expect(restored.beat5Payoff, beats.beat5Payoff);
      expect(restored.stretchBeat, beats.stretchBeat);
      expect(restored.endingLine, beats.endingLine);
      expect(restored.closingCta, beats.closingCta);
      expect(restored.hashtags, beats.hashtags);
      expect(restored.bestLength, beats.bestLength);
    });

    test('hasStretchBeat is true when a stretch beat is set', () {
      expect(beats.hasStretchBeat, isTrue);
    });

    test('hasStretchBeat is false when stretchBeat is null', () {
      const noStretch = BeatSheet(
        id: 'no-stretch',
        title: 'No Stretch',
        characters: ['ria'],
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
      expect(noStretch.hasStretchBeat, isFalse);
    });

    test('hasStretchBeat is false when stretchBeat is empty', () {
      const emptyStretch = BeatSheet(
        id: 'empty-stretch',
        title: 'Empty Stretch',
        characters: ['ria'],
        where: 'Kitchen',
        hook: 'hook',
        beat1Setup: 'setup',
        beat2Problem: 'problem',
        beat3Escalation: 'escalation',
        beat4Turn: 'turn',
        beat5Payoff: 'payoff',
        stretchBeat: '   ',
        endingLine: 'ending',
        closingCta: 'cta',
      );
      expect(emptyStretch.hasStretchBeat, isFalse);
    });

    test('beats exposes the five core beats at the right indices', () {
      expect(beats.beats[0], beats.beat1Setup);
      expect(beats.beats[1], beats.beat2Problem);
      expect(beats.beats[2], beats.beat3Escalation);
      expect(beats.beats[3], beats.beat4Turn);
      expect(beats.beats[4], beats.beat5Payoff);
      expect(beats.beats.length, 5);
    });

    test('bestLength accepts 20, 30 and null', () {
      const with20 = BeatSheet(
        id: 'a', title: 'a', characters: ['ria'], where: 'w', hook: 'h',
        beat1Setup: 's', beat2Problem: 'p', beat3Escalation: 'e',
        beat4Turn: 't', beat5Payoff: 'pa', endingLine: 'en',
        closingCta: 'c', bestLength: 20,
      );
      const with30 = BeatSheet(
        id: 'b', title: 'b', characters: ['ria'], where: 'w', hook: 'h',
        beat1Setup: 's', beat2Problem: 'p', beat3Escalation: 'e',
        beat4Turn: 't', beat5Payoff: 'pa', endingLine: 'en',
        closingCta: 'c', bestLength: 30,
      );
      const withNull = BeatSheet(
        id: 'c', title: 'c', characters: ['ria'], where: 'w', hook: 'h',
        beat1Setup: 's', beat2Problem: 'p', beat3Escalation: 'e',
        beat4Turn: 't', beat5Payoff: 'pa', endingLine: 'en', closingCta: 'c',
      );
      expect(with20.bestLength, 20);
      expect(with30.bestLength, 30);
      expect(withNull.bestLength, isNull);
    });

    test('copyWith preserves every field when nothing is passed', () {
      final copy = beats.copyWith();
      expect(copy.id, beats.id);
      expect(copy.characters, beats.characters);
      expect(copy.stretchBeat, beats.stretchBeat);
      expect(copy.bestLength, beats.bestLength);
    });

    test('copyWith overrides only the fields that are passed', () {
      final copy = beats.copyWith(id: 'new-id', where: 'Kitchen');
      expect(copy.id, 'new-id');
      expect(copy.where, 'Kitchen');
      expect(copy.title, beats.title);
      expect(copy.characters, beats.characters);
    });
  });
}