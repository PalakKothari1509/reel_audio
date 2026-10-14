import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/story_reel_builder.dart';

void main() {
  group('partsForLength', () {
    test('20 seconds -> 2 parts', () {
      expect(partsForLength(20), 2);
    });

    test('30 seconds -> 3 parts', () {
      expect(partsForLength(30), 3);
    });

    test('40 seconds -> 4 parts', () {
      expect(partsForLength(40), 4);
    });

    test('60 seconds -> 6 parts', () {
      expect(partsForLength(60), 6);
    });
  });

  group('beatIndicesForParts', () {
    test('20s maps setup+problem+escalation then turn+payoff', () {
      final mapping = beatIndicesForParts(20);
      expect(mapping.partToBeatIndices.length, 2);
      expect(mapping.partToBeatIndices[0], [0, 1, 2]);
      expect(mapping.partToBeatIndices[1], [3, 4]);
    });

    test('30s spreads the beats across three parts', () {
      final mapping = beatIndicesForParts(30);
      expect(mapping.partToBeatIndices.length, 3);
      expect(mapping.partToBeatIndices[0], [0, 1]);
      expect(mapping.partToBeatIndices[1], [2, -1]);
      expect(mapping.partToBeatIndices[2], [3, 4]);
    });

    test('40s spreads the beats across four parts', () {
      final mapping = beatIndicesForParts(40);
      expect(mapping.partToBeatIndices.length, 4);
      expect(mapping.partToBeatIndices[0], [0, 1]);
      expect(mapping.partToBeatIndices[1], [2, -1]);
      expect(mapping.partToBeatIndices[2], [-2, 3]);
      expect(mapping.partToBeatIndices[3], [4, -3]);
    });

    test('60s spreads the beats across six parts', () {
      final mapping = beatIndicesForParts(60);
      expect(mapping.partToBeatIndices.length, 6);
      // Every core beat must appear somewhere in the 60s mapping.
      final flat = mapping.partToBeatIndices.expand((p) => p).toList();
      expect(flat, contains(0));
      expect(flat, contains(1));
      expect(flat, contains(2));
      expect(flat, contains(3));
      expect(flat, contains(4));
      // The turn and the payoff each span two adjacent parts instead of being
      // squeezed into a single part, so a 60s reel has room to breathe.
      expect(mapping.partToBeatIndices[2], [-2, 3]);
      expect(mapping.partToBeatIndices[3], [3, 4]);
    });

    test('every part has at least one beat index', () {
      for (final seconds in [20, 30, 40, 60]) {
        final mapping = beatIndicesForParts(seconds);
        for (final part in mapping.partToBeatIndices) {
          expect(part, isNotEmpty,
              reason: 'A part with no beats would produce an empty prompt');
        }
      }
    });

    test('unsupported durations throw', () {
      expect(() => beatIndicesForParts(10), throwsArgumentError);
      expect(() => beatIndicesForParts(50), throwsArgumentError);
      expect(() => beatIndicesForParts(45), throwsArgumentError);
    });
  });
}