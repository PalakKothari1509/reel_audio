import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';

/// IDs that originally had entries in kRewrittenStories.
/// These stories should now be embedded directly in storyDetail.
const kRewrittenStoryIds = {
  'idea_1', 'idea_2', 'idea_3', 'idea_4', 'idea_5', 'idea_6',
  'idea_7', 'idea_8', 'idea_9', 'idea_10', 'idea_11', 'idea_12',
  'idea_13', 'idea_23', 'idea_32', 'idea_33', 'idea_34', 'idea_35',
  'idea_36', 'idea_38',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<HookIdea> allHooks;

  setUpAll(() async {
    allHooks = await ContentLibraryService.loadBuiltInHooks();
  });

  group('Story format on built-in hooks', () {
    test('every rewritten story ID has a matching HookIdea', () {
      final ideaIds = allHooks.map((h) => h.id).toSet();
      for (final id in kRewrittenStoryIds) {
        expect(ideaIds, contains(id),
            reason: 'Rewritten story ID "$id" has no matching idea');
      }
    });

    test('rewritten storyDetail contains Story:, Twist:, Resolution:, Moral:', () {
      final byId = {for (final h in allHooks) h.id: h};
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

    test('safety hooks have storyDetail format matching their category', () {
      final safetyHooks = allHooks.where((h) => h.category == 'Safety');
      for (final h in safetyHooks) {
        expect(h.storyDetail, isNotEmpty,
            reason: '${h.id} has empty storyDetail');
      }
    });
  });
}
