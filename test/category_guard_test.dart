import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';

void main() {
  group('Category guards', () {
    test('kHookCategories: all categories have at least one hook', () {
      final allIdsByCategory = <String, List<String>>{};
      for (final h in kDefaultHooks) {
        final cat = h.category.isNotEmpty ? h.category : 'Unknown';
        allIdsByCategory.putIfAbsent(cat, () => []).add(h.id);
      }
      for (final entry in allIdsByCategory.entries) {
        expect(entry.value.length, greaterThan(0),
            reason: 'Category "${entry.key}" has no hooks');
      }
    });

    test('kDefaultHooks: all IDs are unique', () {
      final ids = kDefaultHooks.map((h) => h.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate IDs found in kDefaultHooks');
    });

    test('kDefaultHooks: every hook has required fields populated', () {
      for (final h in kDefaultHooks) {
        expect(h.id, isNotEmpty, reason: 'Empty id found');
        expect(h.category, isNotEmpty, reason: '${h.id} has empty category');
        expect(h.cover, isNotEmpty, reason: '${h.id} has empty cover');
        expect(h.problem, isNotEmpty, reason: '${h.id} has empty problem');
        expect(h.lesson, isNotEmpty, reason: '${h.id} has empty lesson');
        expect(h.postFormat, isNotEmpty, reason: '${h.id} has empty postFormat');
      }
    });

    test('kDefaultHooks: defaultCast has at most 3 characters', () {
      for (final h in kDefaultHooks) {
        expect(h.defaultCast.length, lessThanOrEqualTo(3),
            reason: '${h.id} has more than 3 cast members: ${h.defaultCast}');
      }
    });

    test('kDefaultHooks: caption hashtag count is exactly 5 when non-empty', () {
      for (final h in kDefaultHooks) {
        if (h.caption.isNotEmpty) {
          final hashtags = RegExp(r'#\w+').allMatches(h.caption).toList();
          expect(hashtags.length, 5,
              reason: '${h.id} caption has ${hashtags.length} hashtags instead of 5');
        }
      }
    });

    test('kDefaultHooks: pinnedComment is non-empty', () {
      for (final h in kDefaultHooks) {
        expect(h.pinnedComment, isNotEmpty, reason: '${h.id} has empty pinnedComment');
      }
    });

    test('kDefaultHooks: readyPrompt with content contains Part 3', () {
      for (final h in kDefaultHooks) {
        if (h.readyPrompt.isNotEmpty) {
          expect(h.readyPrompt, contains('Part 3'),
              reason: '${h.id} readyPrompt missing Part 3 (20-30s)');
        }
      }
    });

    test('QuickIdea: all hashtags fields have exactly 5 hashtags', () {
      int checked = 0;
      for (final q in kDay14Posts) {
        final tags = q.hashtags.split(' ').where((t) => t.isNotEmpty).toList();
        if (tags.isNotEmpty) {
          expect(tags.length, 5,
              reason: '${q.title} has ${tags.length} hashtags instead of 5');
          checked++;
        }
      }
      expect(checked, greaterThan(0), reason: 'No QuickIdea hashtags were checked');
    });

    test("Safety hooks: all maintain keepMoralOffScreen = false", () {
      for (final h in kSafetyHooks) {
        expect(h.keepMoralOffScreen, isFalse,
            reason: '${h.id} in kSafetyHooks must keep moral visible');
      }
    });

    test('kDefaultHooksWithRewrite: all hook ids have moment fields populated', () {
      // Moment upgrades are now embedded in kDefaultHooksWithRewrite.
      // Verify that hooks which originally had moment upgrades have
      // their setting/sceneDetail/dialogue/mess/innerThought/endingBeat populated.
      for (final h in kDefaultHooksWithRewrite) {
        // Hooks that had moment upgrades should have non-empty moment fields.
        // Safety hooks and main hooks all received moment upgrades, so they
        // should have these fields populated.
        if (h.category == 'Safety' || h.id.startsWith('h') || h.id.startsWith('pal') || h.id.startsWith('robot')) {
          expect(h.setting, isNotEmpty, reason: '${h.id} has empty setting');
          expect(h.sceneDetail, isNotEmpty, reason: '${h.id} has empty sceneDetail');
          expect(h.dialogue, isNotEmpty, reason: '${h.id} has empty dialogue');
          expect(h.mess, isNotEmpty, reason: '${h.id} has empty mess');
          expect(h.innerThought, isNotEmpty, reason: '${h.id} has empty innerThought');
          expect(h.endingBeat, isNotEmpty, reason: '${h.id} has empty endingBeat');
        }
      }
    });

    test('kDefaultHooksWithRewrite: storyDetail is non-empty for hooks with stories', () {
      final mappedIds = kRewrittenStoryIds;
      for (final h in kDefaultHooksWithRewrite) {
        if (mappedIds.contains(h.id)) {
          expect(h.storyDetail, isNotEmpty,
              reason: '${h.id} should have a non-empty storyDetail');
        }
      }
    });

    test('kDefaultHooksWithRewrite: HookIdea round-trips through toJson/fromJson', () {
      for (final h in kDefaultHooksWithRewrite.take(10)) {
        final json = h.toJson();
        final restored = HookIdea.fromJson(json);
        expect(restored.id, h.id);
        expect(restored.storyDetail, h.storyDetail);
        expect(restored.setting, h.setting);
        expect(restored.sceneDetail, h.sceneDetail);
        expect(restored.dialogue, h.dialogue);
        expect(restored.mess, h.mess);
        expect(restored.endingBeat, h.endingBeat);
        expect(restored.defaultCast, h.defaultCast);
        expect(restored.keepMoralOffScreen, h.keepMoralOffScreen);
      }
    });

    test('kDefaultHooksWithRewrite: defaultCast has at most 3 characters for hooks', () {
      // Verify that hooks which originally had moment upgrades don't have
      // more than 3 cast members
      for (final h in kDefaultHooksWithRewrite) {
        if (h.id.startsWith('safety-') || h.id.startsWith('h') || h.id.startsWith('pal') || h.id.startsWith('robot')) {
          expect(h.defaultCast.length, lessThanOrEqualTo(3),
              reason: '${h.id} has more than 3 cast members: ${h.defaultCast}');
        }
      }
    });

    test('kDefaultHooksWithRewrite: endingBeat is non-empty for hooks with moments', () {
      for (final h in kDefaultHooksWithRewrite) {
        if (h.id.startsWith('safety-') || h.id.startsWith('h') || h.id.startsWith('pal') || h.id.startsWith('robot')) {
          expect(h.endingBeat, isNotEmpty,
              reason: '${h.id} has empty endingBeat');
        }
      }
    });
  });
}

const kRewrittenStoryIds = {
  'h01', 'h02', 'h03', 'h04', 'h05', 'h07', 'h08',
  'h12', 'h13', 'h14', 'h15', 'h16', 'h17', 'h19', 'h19b',
  'pal03', 'pal19',
};
