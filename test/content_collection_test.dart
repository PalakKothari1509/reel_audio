import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_collections.dart';
import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<HookIdea> allHooks;

  setUpAll(() async {
    allHooks = await ContentLibraryService.loadBuiltInHooks();
  });

  group('collectionOf coverage', () {
    test('every HookIdea with a collection mapping maps to the correct collection', () {
      for (final idea in allHooks) {
        if (idea.custom) continue;
        final coll = collectionOf(idea.id, custom: idea.custom);
        if (coll == 'mine') continue; // Not in any collection
        expect(
          coll,
          isNot('mine'),
          reason: '${idea.id} fell into "My Ideas" â it needs a mapping',
        );
      }
    });

    test('every migrated 14-day idea maps to a non-fallback collection', () {
      final day14Hooks = allHooks.where((h) {
        final id = h.id;
        if (!id.startsWith('idea_')) return false;
        final number = int.tryParse(id.substring('idea_'.length));
        return number != null && number >= 93 && number <= 116;
      }).toList();
      for (final idea in day14Hooks) {
        final coll = collectionOf(idea.id);
        expect(
          coll,
          isNot('mine'),
          reason: '${idea.id} fell into "My Ideas" â it needs a mapping',
        );
      }
    });

    test('every built-in idea maps to a real collection', () {
      final ids = allHooks.where((h) => !h.custom).map((h) => h.id).toList();

      // No duplicate idea ids anywhere.
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Duplicate IDs in source lists',
      );

      // Nothing silently falls back to "My Ideas".
      final unmapped =
          ids.where((id) => collectionOf(id) == 'mine').toList();
      expect(unmapped, isEmpty, reason: 'Unmapped ideas: $unmapped');

      // Every collection id used must exist in kCollections.
      final valid = kCollections.map((c) => c.id).toSet();
      for (final id in ids) {
        if (collectionOf(id) == 'mine') continue; // Not in any collection
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
      final allIds = allHooks.map((h) => h.id).toList();

      final covered = <String>{};
      for (final id in allIds) {
        covered.add(collectionOf(id));
      }

      // Collections that have members in _members map. Collections not in
      // kCollections (e.g. birthday, mealtime, bath) are not expected to
      // have members.
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
        'safety',
      ]) {
        expect(
          covered.contains(coll),
          isTrue,
          reason: 'No ideas mapped to collection "$coll"',
        );
      }
    });
  });
}
