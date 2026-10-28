import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_studio_service.dart';
import 'package:reel_audio/prompts.dart';
import 'package:reel_audio/story_ideas.dart';

void main() {
  group('ShareabilityAnalysis', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'sender': '  Mumma of a 3-year-old who refuses vegetables  ',
        'recipient': '  a parent whose child also pushes food away  ',
        'reason': '  It shows a simple lunchbox trick that works  ',
        'confidence': 'High',
        'note': '  Add a photo of the final meal  ',
      };

      final result = ShareabilityAnalysis.fromJson(json);

      expect(result.sender, 'Mumma of a 3-year-old who refuses vegetables');
      expect(result.recipient, 'a parent whose child also pushes food away');
      expect(result.reason, 'It shows a simple lunchbox trick that works');
      expect(result.confidence, 'High');
      expect(result.note, 'Add a photo of the final meal');
    });

    test('fromJson provides empty defaults for missing fields', () {
      final result = ShareabilityAnalysis.fromJson({});

      expect(result.sender, isEmpty);
      expect(result.recipient, isEmpty);
      expect(result.reason, isEmpty);
      expect(result.confidence, isEmpty);
      expect(result.note, isEmpty);
    });

    test('fromJson handles null values gracefully', () {
      final json = <String, dynamic>{
        'sender': null,
        'recipient': null,
        'reason': null,
        'confidence': null,
        'note': null,
      };

      final result = ShareabilityAnalysis.fromJson(json);

      expect(result.sender, isEmpty);
      expect(result.recipient, isEmpty);
      expect(result.reason, isEmpty);
      expect(result.confidence, isEmpty);
      expect(result.note, isEmpty);
    });

    test('toJson round-trips correctly', () {
      const original = ShareabilityAnalysis(
        sender: 'Busy dad of two',
        recipient: 'another tired parent',
        reason: 'Because it reminds him of last night',
        confidence: 'medium',
        note: 'Keep it short next time',
      );

      final json = original.toJson();
      final roundTrip = ShareabilityAnalysis.fromJson(json);

      expect(roundTrip.sender, original.sender);
      expect(roundTrip.recipient, original.recipient);
      expect(roundTrip.reason, original.reason);
      expect(roundTrip.confidence, original.confidence);
      expect(roundTrip.note, original.note);
    });

    test('note defaults to empty string when omitted', () {
      const result = ShareabilityAnalysis(
        sender: 'A',
        recipient: 'B',
        reason: 'C',
        confidence: 'high',
      );

      expect(result.note, isEmpty);
    });

    test('isHighConfidence returns true for "high"', () {
      const result = ShareabilityAnalysis(
        sender: 'A',
        recipient: 'B',
        reason: 'C',
        confidence: 'high',
      );

      expect(result.isHighConfidence, isTrue);
    });

    test('isHighConfidence returns true for "HIGH" (case-insensitive)', () {
      const result = ShareabilityAnalysis(
        sender: 'A',
        recipient: 'B',
        reason: 'C',
        confidence: 'HIGH',
      );

      expect(result.isHighConfidence, isTrue);
    });

    test('isHighConfidence returns false for "medium"', () {
      const result = ShareabilityAnalysis(
        sender: 'A',
        recipient: 'B',
        reason: 'C',
        confidence: 'medium',
      );

      expect(result.isHighConfidence, isFalse);
    });

    test('isHighConfidence returns false for "low"', () {
      const result = ShareabilityAnalysis(
        sender: 'A',
        recipient: 'B',
        reason: 'C',
        confidence: 'low',
      );

      expect(result.isHighConfidence, isFalse);
    });
  });

  group('IdeaEvaluation.copyWith', () {
    final check = StoryCheck(
      good: ['Good point one'],
      missing: ['Needs more emotion'],
      verdict: 'Improvement possible',
      rows: [CheckRow('Hook', true, '')],
      hooks: [HookChoice('emotional', 'A crying toddler')],
    );
    final shareability = ShareabilityAnalysis(
      sender: 'Mumma of a 3-year-old',
      recipient: 'parents whose kids also fuss at bedtime',
      reason: 'It shows a bedtime hack she tried',
      confidence: 'high',
    );

    test('returns a new instance with no changes when no args', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
        selectedHook: HookChoice('question', 'Why do children...?'),
        isApproved: true,
      );

      final copy = original.copyWith();

      expect(copy.check, same(check));
      expect(copy.shareability, same(shareability));
      expect(copy.selectedHook, same(original.selectedHook));
      expect(copy.isApproved, original.isApproved);
    });

    test('replaces check when provided', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
      );
      final newCheck = StoryCheck(
        good: ['Better now'],
        missing: [],
        verdict: 'Strong story',
      );

      final copy = original.copyWith(check: newCheck);

      expect(copy.check, same(newCheck));
      expect(copy.shareability, same(shareability));
    });

    test('replaces shareability when provided', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
      );
      final newShare = ShareabilityAnalysis(
        sender: 'New sender',
        recipient: 'New recipient',
        reason: 'New reason',
        confidence: 'medium',
      );

      final copy = original.copyWith(shareability: newShare);

      expect(copy.check, same(check));
      expect(copy.shareability, same(newShare));
    });

    test('replaces selectedHook when provided', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
        selectedHook: HookChoice('old', 'Old hook'),
      );
      final newHook = HookChoice('new', 'New hook text');

      final copy = original.copyWith(selectedHook: newHook);

      expect(copy.selectedHook, same(newHook));
      expect(copy.check, same(check));
    });

    test('calling copyWith with null selectedHook keeps the original value', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
        selectedHook: HookChoice('old', 'Old hook'),
      );

      // Standard Dart copyWith uses ?? so passing null is indistinguishable
      // from not providing the parameter.
      final copy = original.copyWith(selectedHook: null);

      expect(copy.selectedHook, same(original.selectedHook));
    });

    test('replaces isApproved when provided', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
        isApproved: false,
      );

      final copy = original.copyWith(isApproved: true);

      expect(copy.isApproved, isTrue);
      expect(original.isApproved, isFalse);
    });

    test('does not modify the original instance', () {
      final original = IdeaEvaluation(
        check: check,
        shareability: shareability,
        isApproved: false,
      );

      original.copyWith(isApproved: true);

      expect(original.isApproved, isFalse);
    });
  });

  group('evaluateIdea input validation', () {
    test('throws when idea is too short', () async {
      expect(
        () => evaluateIdea(idea: 'hi'),
        throwsA(
          predicate((e) => e.toString().contains('Write a bit more of the story first.')),
        ),
      );
    });

    test('throws when idea is only whitespace', () async {
      expect(
        () => evaluateIdea(idea: '     '),
        throwsA(
          predicate((e) => e.toString().contains('Write a bit more of the story first.')),
        ),
      );
    });
  });

  group('StoryCheck scoring (Phase 2.2)', () {
    test('score equals pass count, min 1', () {
      final allPass = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: kStoryChecks.map((name) => CheckRow(name, true, '')).toList(),
      );
      expect(allPass.effectiveScore, equals(10));

      final allFail = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: kStoryChecks.map((name) => CheckRow(name, false, '')).toList(),
      );
      expect(allFail.effectiveScore, equals(1));
    });

    test('band is Ready when score >= 9 and no blockers', () {
      final check = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: kStoryChecks.map((name) => CheckRow(name, true, '')).toList(),
      );
      expect(check.band, equals('Ready'));
    });

    test('band is Improve when score >= 7 and < 9', () {
      final rows = kStoryChecks.map((name) => CheckRow(name, true, '')).toList();
      rows[0] = CheckRow('Real-life problem', false, '');
      final check = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: rows,
      );
      expect(check.band, equals('Improve'));
    });

    test('band is Rewrite when score < 7', () {
      final rows = kStoryChecks.map((name) => CheckRow(name, false, '')).toList();
      final check = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: rows,
      );
      expect(check.band, equals('Rewrite'));
    });

    test('blocker (failed Hook) caps band at Improve even with high score', () {
      final rows = kStoryChecks.map((name) => CheckRow(name, true, '')).toList();
      rows[1] = CheckRow('Hook', false, '');
      final check = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: rows,
      );
      expect(check.band, equals('Improve'));
    });

    test('blocker (failed Real-life problem) caps band at Improve even with high score', () {
      final rows = kStoryChecks.map((name) => CheckRow(name, true, '')).toList();
      rows[0] = CheckRow('Real-life problem', false, '');
      final check = StoryCheck(
        good: [],
        missing: [],
        verdict: '',
        rows: rows,
      );
      expect(check.band, equals('Improve'));
    });
  });
}
