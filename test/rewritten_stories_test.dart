import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';

/// IDs that originally had entries in kRewrittenStories.
/// These stories should now be embedded directly in storyDetail.
const kRewrittenStoryIds = {
  'h01', 'h02', 'h03', 'h04', 'h05', 'h07', 'h08',
  'h12', 'h13', 'h14', 'h15', 'h16', 'h17', 'h19',
  'pal03', 'pal19',
};

void main() {
  group('Story format on kDefaultHooks', () {
    test('every rewritten story ID has a matching HookIdea', () {
      final ideaIds = kDefaultHooks.map((h) => h.id).toSet();
      for (final id in kRewrittenStoryIds) {
        expect(ideaIds, contains(id),
            reason: 'Rewritten story ID "$id" has no matching idea');
      }
    });

    test('rewritten storyDetail contains Story:, Twist:, Resolution:, Moral:', () {
      final byId = {for (final h in kDefaultHooks) h.id: h};
      for (final id in kRewrittenStoryIds) {
        final story = byId[id]!.storyDetail;
        expect(story, contains('Story:'),
            reason: '$id is missing Story:');
        expect(story, contains('Twist:'),
            reason: '$id is missing Twist:');
        expect(story, contains('Resolution:'),
            reason: '$id is missing Resolution:');
        expect(story, contains('Moral:'),
            reason: '$id is missing Moral:');
      }
    });

    test('kDefaultHooksWithRewrite equals kDefaultHooks', () {
      expect(kDefaultHooksWithRewrite, same(kDefaultHooks));
    });

    test('safety hooks have storyDetail format matching their category', () {
      for (final h in kSafetyHooks) {
        expect(h.storyDetail, isNotEmpty,
            reason: '${h.id} has empty storyDetail');
      }
    });
  });
}
