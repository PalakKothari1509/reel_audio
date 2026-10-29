import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_collections.dart';

void main() {
  group('collectionOf coverage', () {
    test('every HookIdea id maps to a non-fallback collection', () {
      for (final idea in kDefaultHooks) {
        final coll = collectionOf(idea.id, custom: idea.custom);
        expect(
          coll,
          isNot('mine'),
          reason: '${idea.id} fell into "My Ideas" â it needs a mapping',
        );
      }
    });

    test('every migrated 14-day idea maps to a non-fallback collection', () {
      for (final idea in kDay14PostIdeas) {
        final coll = collectionOf(idea.id);
        expect(
          coll,
          isNot('mine'),
          reason: '${idea.id} fell into "My Ideas" â it needs a mapping',
        );
      }
    });

    test('every built-in idea maps to a real collection', () {
      final ids = kDefaultHooks.map((h) => h.id).toList();

      // No duplicate idea ids anywhere.
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Duplicate IDs in source lists',
      );

      // Nothing silently falls back to "My Ideas".
      final unmapped = ids.where((id) => collectionOf(id) == 'mine').toList();
      expect(unmapped, isEmpty, reason: 'Unmapped ideas: $unmapped');

      // Every collection id used must exist in kCollections.
      final valid = kCollections.map((c) => c.id).toSet();
      for (final id in ids) {
        expect(valid.contains(collectionOf(id)), isTrue, reason: id);
      }
    });

    test('custom ideas map to "mine"', () {
      expect(collectionOf('whatever', custom: true), 'mine');
      expect(collectionOf('', custom: true), 'mine');
    });

    test('unknown non-custom ids map to "mine" as fallback', () {
      expect(collectionOf('totally-unknown-id'), 'mine');
    });

    test('all expected collections have at least one member', () {
      final allIds = kDefaultHooks.map((h) => h.id).toList();

      final covered = <String>{};
      for (final id in allIds) {
        covered.add(collectionOf(id));
      }

      // These should all have members. "safety" and "mine" may be empty now.
      for (final coll in [
        'robot',
        'festivals',
        'routines',
        'food',
        'tantrums',
        'siblings',
        'parent',
        'warm',
        'play',
        'guides',
        'missions',
        'milestones',
      ]) {
        expect(
          covered,
          contains(coll),
          reason: 'Collection "$coll" has no members',
        );
      }
    });

    test('counts per collection are non-empty', () {
      final allIds = kDefaultHooks.map((h) => h.id).toList();

      final counts = <String, int>{};
      for (final id in allIds) {
        final coll = collectionOf(id);
        counts[coll] = (counts[coll] ?? 0) + 1;
      }

      expect(counts['robot'], 13);
      expect(counts['festivals'], greaterThanOrEqualTo(10));
      expect(counts['routines'], greaterThanOrEqualTo(5));
      expect(counts['food'], greaterThanOrEqualTo(3));
      expect(counts['tantrums'], greaterThanOrEqualTo(5));
      expect(counts['siblings'], greaterThanOrEqualTo(3));
    });
  });
}
