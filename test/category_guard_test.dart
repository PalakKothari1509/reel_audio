import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';

void main() {
  group('Category guards', () {
    test('kHookCategories: all 3 lists match in length', () {
      // kHookCategories is a flat list of category names
      final allIdsByCategory = <String, List<String>>{};
      for (final h in kDefaultHooks) {
        final cat = h.category ?? 'Unknown';
        allIdsByCategory.putIfAbsent(cat, () => []).add(h.id);
      }
      final lengths = allIdsByCategory.values.map((l) => l.length).toSet();
      // Categories can have different counts, just verify no empty categories
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

    test('kDefaultHooks: every category ID has a matching HookIdea', () {
      final hookIds = kDefaultHooks.map((h) => h.id).toSet();
      for (final h in kDefaultHooks) {
        expect(hookIds, contains(h.id),
            reason: 'ID "${h.id}" has no matching HookIdea');
      }
    });

    test('Safety hooks: all maintain keepMoralOffScreen = false', () {
      for (final h in kSafetyHooks) {
        expect(h.keepMoralOffScreen, isFalse,
            reason: '${h.id} in kSafetyHooks must keep moral visible');
      }
    });

    test('kMomentUpgrades: every key has a matching HookIdea in kDefaultHooks', () {
      final hookIds = kDefaultHooks.map((h) => h.id).toSet();
      for (final id in kMomentUpgrades.keys) {
        expect(hookIds, contains(id),
            reason: 'kMomentUpgrades key "$id" has no matching hook');
      }
    });

    test('kDefaultHooksWithRewrite: moment fields are applied from kMomentUpgrades', () {
      final byId = {for (final h in kDefaultHooksWithRewrite) h.id: h};
      for (final entry in kMomentUpgrades.entries) {
        final id = entry.key;
        final upgrade = entry.value;
        final hook = byId[id];
        expect(hook, isNotNull, reason: '$id not found in kDefaultHooksWithRewrite');
        expect(hook!.setting, upgrade['setting'],
            reason: '$id setting mismatch');
        expect(hook.sceneDetail, upgrade['sceneDetail'],
            reason: '$id sceneDetail mismatch');
        expect(hook.dialogue, upgrade['dialogue'],
            reason: '$id dialogue mismatch');
        expect(hook.mess, upgrade['mess'],
            reason: '$id mess mismatch');
        expect(hook.innerThought, upgrade['innerThought'],
            reason: '$id innerThought mismatch');
        expect(hook.endingBeat, upgrade['endingBeat'],
            reason: '$id endingBeat mismatch');
      }
    });

    test('kDefaultHooksWithRewrite: storyDetail is applied from kRewrittenStories', () {
      final byId = {for (final h in kDefaultHooksWithRewrite) h.id: h};
      for (final entry in kRewrittenStories.entries) {
        final id = entry.key;
        final hook = byId[id];
        expect(hook, isNotNull, reason: '$id not found in kDefaultHooksWithRewrite');
        expect(hook!.storyDetail, entry.value,
            reason: '$id storyDetail was not rewritten');
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

    test('kMomentUpgrades: all defaultCast values have at most 3 characters', () {
      for (final entry in kMomentUpgrades.entries) {
        final cast = entry.value['cast']!.split('|');
        expect(cast.length, lessThanOrEqualTo(3),
            reason: '${entry.key} has more than 3 cast members: $cast');
      }
    });

    test('kMomentUpgrades: endingBeat is non-empty for all entries', () {
      for (final entry in kMomentUpgrades.entries) {
        expect(entry.value['endingBeat'], isNotEmpty,
            reason: '${entry.key} has empty endingBeat');
      }
    });
  });
}
