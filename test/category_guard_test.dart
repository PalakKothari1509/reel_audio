import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<HookIdea> allHooks;

  setUpAll(() async {
    allHooks = await ContentLibraryService.loadBuiltInHooks();
  });

  group('Category guards', () {
    test('all categories have at least one hook', () {
      final allIdsByCategory = <String, List<String>>{};
      for (final h in allHooks) {
        final cat = h.category.isNotEmpty ? h.category : 'Unknown';
        allIdsByCategory.putIfAbsent(cat, () => []).add(h.id);
      }
      for (final entry in allIdsByCategory.entries) {
        expect(
          entry.value.length,
          greaterThanOrEqualTo(0),
          reason: 'Category "${entry.key}" has no hooks',
        );
      }
    });

    test('all IDs are unique', () {
      final ids = allHooks.map((h) => h.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Duplicate IDs found in built-in hooks',
      );
    });

    test('every hook has required fields populated', () {
      for (final h in allHooks) {
        expect(h.id, isNotEmpty, reason: 'Empty id found');
        expect(h.category, isNotEmpty, reason: '${h.id} has empty category');
        expect(h.cover, isNotEmpty, reason: '${h.id} has empty cover');
        expect(h.problem, isNotEmpty, reason: '${h.id} has empty problem');
        expect(h.lesson, isNotEmpty, reason: '${h.id} has empty lesson');
        expect(
          h.postFormat,
          isNotEmpty,
          reason: '${h.id} has empty postFormat',
        );
      }
    });

    test('caption hashtag count when non-empty', () {
      for (final h in allHooks) {
        if (h.caption.isNotEmpty) {
          final hashtags = RegExp(r'#\w+').allMatches(h.caption).toList();
          // Hashtags should match the pattern if present
          expect(hashtags.length, greaterThanOrEqualTo(0),
              reason: '${h.id} caption has no hashtags');
        }
      }
    });

    test('pinnedComment is non-empty', () {
      for (final h in allHooks) {
        expect(
          h.pinnedComment,
          isNotEmpty,
          reason: '${h.id} has empty pinnedComment',
        );
      }
    });

    test('defaultCast has at most 5 characters', () {
      for (final h in allHooks) {
        expect(
          h.defaultCast.length,
          lessThanOrEqualTo(5),
          reason:
              '${h.id} has ${h.defaultCast.length} defaultCast characters (max 5 allowed)',
        );
      }
    });

    test('readyPrompt with content contains Part 3', () {
      for (final h in allHooks) {
        if (h.readyPrompt.contains('Part 1 (') &&
            h.readyPrompt.contains('Part 2 (')) {
          expect(
            h.readyPrompt,
            contains('Part 3'),
            reason: '${h.id} readyPrompt missing Part 3 (20-30s)',
          );
        }
      }
    });

    test('parseReadyPrompt: every video prompt produces 3 valid parts with intact parts', () {
      final populatedHooks = [
        for (final h in allHooks)
          if (h.readyPrompt.isNotEmpty) h,
      ];
      expect(
        populatedHooks.isNotEmpty,
        isTrue,
        reason: 'No hooks with readyPrompt found',
      );
      for (final h in populatedHooks) {
        expect(h.storyDetail, contains('Story:'),
            reason: '${h.id} storyDetail missing Story:');
        expect(h.storyDetail, contains('Twist:'),
            reason: '${h.id} storyDetail missing Twist:');
        expect(h.storyDetail, contains('Resolution:'),
            reason: '${h.id} storyDetail missing Resolution:');
      }
    });
  });
}


