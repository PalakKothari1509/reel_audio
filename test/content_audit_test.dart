import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_audit.dart';

void main() {
  group('ContentAuditItem', () {
    test('round-trips through JSON with all fields', () {
      final item = ContentAuditItem(
        id: 'navratri-garba-ghar',
        title: 'Garba se Ghar Kaise Laayein?',
        pillar: ContentPillar.play,
        format: 'story_reel',
        audienceAge: '2-4',
        language: 'hinglish',
        characters: const ['Ria', 'Mumma', 'Papa'],
        parentProblem: 'Toddler refuses to leave after Garba',
        learningGoal: 'Predictable endings reduce resistance',
        hook: 'Navratri mein bachche ko Garba se ghar kaise laayein?',
        storyBeats: const ['setup', 'problem', 'solution', 'takeaway'],
        narration: 'Ria dances happily. Mumma gives a clear ending.',
        onScreenText: const ['Garba time!', 'Last two songs!', 'Goodbye!'],
        caption: 'Suddenly stop nahi—pehle se batao',
        hashtags: const ['#navratri', '#toddler', '#parenting'],
        cta: 'Follow for more',
        status: AuditStatus.idea,
        experimentCount: 0,
        reviewNotes: const [],
      );

      final roundTrip = ContentAuditItem.fromJson(item.toJson());
      expect(roundTrip.id, 'navratri-garba-ghar');
      expect(roundTrip.title, 'Garba se Ghar Kaise Laayein?');
      expect(roundTrip.pillar, ContentPillar.play);
      expect(roundTrip.characters, ['Ria', 'Mumma', 'Papa']);
      expect(roundTrip.storyBeats, ['setup', 'problem', 'solution', 'takeaway']);
      expect(roundTrip.narration, isNotNull);
      expect(roundTrip.onScreenText, hasLength(3));
      expect(roundTrip.hashtags, hasLength(3));
      expect(roundTrip.status, AuditStatus.idea);
      expect(roundTrip.metrics, isNotNull);
      expect(roundTrip.experimentCount, 0);
    });
  });

  group('ContentMetrics', () {
    test('empty metrics when no data', () {
      const metrics = ContentMetrics();
      final json = metrics.toJson();
      final roundTrip = ContentMetrics.fromJson(json);
      expect(roundTrip.reach, isNull);
      expect(roundTrip.shares, isNull);
      expect(roundTrip.saves, isNull);
    });

    test('preserves all fields through JSON', () {
      const metrics = ContentMetrics(
        reach: 1000,
        nonFollowerReach: 300,
        plays: 1500,
        averageWatchTimeSeconds: 12,
        shares: 50,
        saves: 100,
        profileVisits: 30,
        followsAttributed: 5,
      );
      final roundTrip = ContentMetrics.fromJson(metrics.toJson());
      expect(roundTrip.reach, 1000);
      expect(roundTrip.nonFollowerReach, 300);
      expect(roundTrip.plays, 1500);
      expect(roundTrip.averageWatchTimeSeconds, 12);
      expect(roundTrip.shares, 50);
      expect(roundTrip.saves, 100);
      expect(roundTrip.profileVisits, 30);
      expect(roundTrip.followsAttributed, 5);
    });

    test('handles null JSON map', () {
      final metrics = ContentMetrics.fromJson(null);
      expect(metrics.reach, isNull);
      expect(metrics.shares, isNull);
    });
  });

  group('AuditStatus', () {
    test('all statuses have labels', () {
      expect(AuditStatus.values.every((s) => s.label.isNotEmpty), isTrue);
      expect(AuditStatus.idea.label, 'Idea');
      expect(AuditStatus.posted.label, 'Posted');
    });
  });

  group('Pillar mapping', () {
    test('_pillarFromString maps descriptive names to ContentPillar', () {
      final store = ContentAuditStore();
      // Test via fromJson since _pillarFromString is private
      final test = (String input, ContentPillar expected) {
        final item = ContentAuditItem.fromJson({
          'id': 'test',
          'title': 'Test',
          'pillar': input,
          'parentProblem': '',
          'learningGoal': '',
          'hook': '',
        });
        expect(item.pillar, expected, reason: 'input was "$input"');
      };

      test('relatable', ContentPillar.play);
      test('relatable_toddler_moments', ContentPillar.play);
      test('story', ContentPillar.play);
      test('play', ContentPillar.play);
      test('think', ContentPillar.think);
      test('guess', ContentPillar.think);
      test('discover', ContentPillar.discover);
      test('explore', ContentPillar.discover);
      test('talk', ContentPillar.talk);
      test('conversation', ContentPillar.talk);
      test('activity', ContentPillar.doIt);
      test('home', ContentPillar.doIt);
      test('try', ContentPillar.doIt);
      test('skill', ContentPillar.doIt);
      test('reference', ContentPillar.doIt);
      test('try_this_at_home', ContentPillar.doIt);
      test('parent_child_conversation', ContentPillar.talk);
      test('tiny_story_big_lesson', ContentPillar.play);
    });
  });
}
