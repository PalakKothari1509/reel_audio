import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_audit.dart';
import 'package:reel_audio/content_studio_service.dart';

void main() {
  group('EngagementPackage', () {
    test('fromJson parses all fields', () {
      final json = {
        'caption': 'Test caption\n\nUseful line.',
        'hashtags': ['#a', '#b', '#c', '#d', '#e'],
        'pinnedComment': 'Great post! What worked for you?',
        'suggestedReplies': [
          {'situation': 'similar experience', 'text': 'Same here! How did you handle it?'},
          {'situation': 'tip shared', 'text': 'Thanks for the tip! What works best for you?'},
          {'situation': 'question asked', 'text': 'Good question. I found that works too — what did you try?'},
          {'situation': 'disagreement', 'text': 'I see it differently, but I respect that. What approach works for your family?'},
          {'situation': 'emotional share', 'text': 'Those moments stay with us. What reminded you most?'},
          {'situation': 'compliment', 'text': 'Thank you! Which character did you enjoy most?'},
        ],
        'followReason': 'We share practical, relatable parenting hacks.',
      };

      final result = EngagementPackage.fromJson(json);

      expect(result.caption, 'Test caption\n\nUseful line.');
      expect(result.hashtags.length, 5);
      expect(result.hashtags, contains('#a'));
      expect(result.pinnedComment, 'Great post! What worked for you?');
      expect(result.suggestedReplies.length, 6);
      expect(result.suggestedReplies[0].situation, 'similar experience');
      expect(result.followReason, 'We share practical, relatable parenting hacks.');
    });

    test('fromJson handles missing suggestedReplies', () {
      final json = {
        'caption': 'Hello',
        'hashtags': ['#a', '#b', '#c', '#d', '#e'],
        'pinnedComment': 'Nice! What do you think?',
        'followReason': 'Follow for more.',
      };

      final result = EngagementPackage.fromJson(json);

      expect(result.suggestedReplies, isEmpty);
    });

    test('fromJson filters empty hashtags', () {
      final json = {
        'caption': 'Hello',
        'hashtags': ['#a', '', '#c', '  ', '#d', '#e'],
        'pinnedComment': 'Nice! What do you think?',
        'followReason': 'Follow for more.',
      };

      final result = EngagementPackage.fromJson(json);

      expect(result.hashtags.length, 4);
    });

    test('toJson round-trips correctly', () {
      final original = EngagementPackage(
        caption: 'My caption',
        hashtags: ['#one', '#two', '#three', '#four', '#five'],
        pinnedComment: 'What worked for you?',
        suggestedReplies: [
          SuggestedReply('similar experience', 'Same! How about you?'),
          SuggestedReply('tip shared', 'Thanks! What works best for you?'),
        ],
        followReason: 'We share daily tips.',
      );

      final json = original.toJson();
      final roundTrip = EngagementPackage.fromJson(json);

      expect(roundTrip.caption, original.caption);
      expect(roundTrip.hashtags, original.hashtags);
      expect(roundTrip.pinnedComment, original.pinnedComment);
      expect(roundTrip.suggestedReplies.length, 2);
      expect(roundTrip.suggestedReplies[0].situation, 'similar experience');
      expect(roundTrip.followReason, original.followReason);
    });

    test('forInstagram combines caption and hashtags', () {
      final pkg = EngagementPackage(
        caption: 'Great post!',
        hashtags: ['#a', '#b', '#c', '#d', '#e'],
        pinnedComment: 'Nice! What do you think?',
        suggestedReplies: [],
        followReason: 'Follow for more.',
      );

      final combined = pkg.forInstagram;

      expect(combined, contains('Great post!'));
      expect(combined, contains('#a'));
      expect(combined, contains('#e'));
    });

    test('forInstagram returns only caption when no hashtags', () {
      final pkg = EngagementPackage(
        caption: 'Just a caption',
        hashtags: [],
        pinnedComment: 'Comment?',
        suggestedReplies: [],
        followReason: 'Reason.',
      );

      expect(pkg.forInstagram, 'Just a caption');
    });
  });

  group('SuggestedReply', () {
    test('stores situation and text', () {
      const reply = SuggestedReply('compliment', 'Thank you! Which character?');
      expect(reply.situation, 'compliment');
      expect(reply.text, 'Thank you! Which character?');
    });
  });

  group('PerformanceLearn', () {
    test('averageStrengthByHook respects minSamples', () {
      final decisions = [
        CreativeDecision(hookType: 'Curiosity', contentPurpose: 'RELATE', format: 'Reel', score: 9, strength: 20, meetsFiveTestRule: true),
        CreativeDecision(hookType: 'Curiosity', contentPurpose: 'RELATE', format: 'Reel', score: 8, strength: 30, meetsFiveTestRule: true),
        CreativeDecision(hookType: 'Hook', contentPurpose: 'LEARN', format: 'Image', score: 7, strength: 10, meetsFiveTestRule: false),
      ];

      final learn = PerformanceLearn(decisions);
      final byHook = learn.averageStrengthByHook(minSamples: 2);

      expect(byHook['Curiosity'], 25.0);
      expect(byHook.containsKey('Hook'), isFalse);
    });

    test('averageStrengthByPurpose groups correctly', () {
      final decisions = [
        CreativeDecision(hookType: 'Curiosity', contentPurpose: 'RELATE', format: 'Reel', score: 9, strength: 20, meetsFiveTestRule: true),
        CreativeDecision(hookType: 'Hook', contentPurpose: 'RELATE', format: 'Reel', score: 8, strength: 30, meetsFiveTestRule: true),
        CreativeDecision(hookType: 'Emotional', contentPurpose: 'LEARN', format: 'Image', score: 7, strength: 10, meetsFiveTestRule: true),
      ];

      final learn = PerformanceLearn(decisions);
      final byPurpose = learn.averageStrengthByPurpose(minSamples: 2);

      expect(byPurpose['RELATE'], 25.0);
      expect(byPurpose['LEARN'], isNull);
    });

    test('recentlyUsedHooks returns sorted by frequency', () {
      final decisions = List.generate(10, (i) => CreativeDecision(
        hookType: i < 6 ? 'Curiosity' : 'Hook',
        contentPurpose: 'RELATE',
        format: 'Reel',
        score: 8,
        strength: 10,
        meetsFiveTestRule: true,
      ));

      final learn = PerformanceLearn(decisions);
      final recent = learn.recentlyUsedHooks(recentWindow: 10);

      expect(recent.first, 'Curiosity');
    });

    test('recommendedTests suggests under-tested hooks', () {
      // Curiosity: 6 samples (meets threshold), Hook: 3 samples (under-tested)
      final decisions = List.generate(9, (i) => CreativeDecision(
        hookType: i < 6 ? 'Curiosity' : 'Hook',
        contentPurpose: 'RELATE',
        format: 'Reel',
        score: 8,
        strength: i < 3 ? 10 : 20,
        meetsFiveTestRule: true,
      ));

      final learn = PerformanceLearn(decisions);
      final recs = learn.recommendedTests(minSamples: 5);

      // Curiosity has 6 samples (>= 5) so it's not recommended
      // Hook has 3 samples (< 5) so it should be recommended
      expect(recs.any((r) => r.contains('Hook')), isTrue);
      expect(recs.any((r) => r.contains('Curiosity')), isFalse);
    });

    test('handles empty decisions gracefully', () {
      final learn = PerformanceLearn([]);

      expect(learn.averageStrengthByHook(), isEmpty);
      expect(learn.averageStrengthByPurpose(), isEmpty);
      expect(learn.recentlyUsedHooks(), isEmpty);
      expect(learn.recommendedTests(), isEmpty);
    });
  });
}
