import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';

void main() {
  group('kRewrittenStories', () {
    test('every key exists in kDefaultHooks', () {
      final ideaIds = kDefaultHooks.map((h) => h.id).toSet();
      for (final id in kRewrittenStories.keys) {
        expect(ideaIds, contains(id),
            reason: 'kRewrittenStories has no matching idea for "$id"');
      }
    });

    test('every value contains Story:, Twist:, Resolution:, Moral:', () {
      for (final entry in kRewrittenStories.entries) {
        final story = entry.value;
        expect(story, contains('Story:'),
            reason: '${entry.key} is missing Story:');
        expect(story, contains('Twist:'),
            reason: '${entry.key} is missing Twist:');
        expect(story, contains('Resolution:'),
            reason: '${entry.key} is missing Resolution:');
        expect(story, contains('Moral:'),
            reason: '${entry.key} is missing Moral:');
      }
    });

    test('kDefaultHooksWithRewrite applies storyDetail where mapped', () {
      final byId = {for (final h in kDefaultHooksWithRewrite) h.id: h};
      for (final id in kRewrittenStories.keys) {
        expect(byId[id]!.storyDetail, kRewrittenStories[id],
            reason: '$id did not receive its rewritten story');
      }
    });

    test('unmapped hooks keep their original storyDetail', () {
      final mappedIds = kRewrittenStories.keys.toSet();
      for (final h in kDefaultHooksWithRewrite) {
        if (!mappedIds.contains(h.id)) {
          final original = kDefaultHooks
              .firstWhere((d) => d.id == h.id, orElse: () => h);
          expect(h.storyDetail, original.storyDetail,
              reason: '${h.id} should keep its original storyDetail');
        }
      }
    });
  });
}
