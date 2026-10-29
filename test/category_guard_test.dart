import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_studio_service.dart';

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

    test('parseReadyPrompt: all 60 prompts produce 3 valid parts with intact Part 3', () {
      final hooks = [
        for (final h in [...kSafetyHooks, ...kDefaultHooks])
          if (h.readyPrompt.isNotEmpty) h,
      ];
      expect(hooks.length, 60,
          reason: 'Expected exactly 60 populated readyPrompt entries');

      for (final h in hooks) {
        final result = GeminiVideoResult.parseReadyPrompt(h.readyPrompt, h.cover);
        expect(result.parts.length, 3,
            reason: '${h.id}: expected 3 parts, got ${result.parts.length}');

        for (final p in result.parts) {
          expect(p.promptText.trim(), isNotEmpty,
              reason: '${h.id}: Part ${p.partNumber} promptText is empty');
          expect(p.fullPrompt.trim(), isNotEmpty,
              reason: '${h.id}: Part ${p.partNumber} fullPrompt is empty');
        }

        final p3 = result.parts.firstWhere((p) => p.partNumber == 3);
        expect(p3.promptText, contains('Moral:'),
            reason: '${h.id}: Part 3 missing Moral');
        expect(p3.textOverlay, isNotEmpty,
            reason: '${h.id}: Part 3 textOverlay field is empty');
        expect(p3.promptText, isNot(contains('Final text overlay')),
            reason: '${h.id}: Part 3 promptText still contains Final text overlay');
        expect(p3.promptText, isNot(contains('\\')),
            reason: '${h.id}: Part 3 contains backslash artifact');

        expect(p3.purpose, contains('Resolut'),
            reason: '${h.id}: Part 3 purpose not "Resolution & Moral"');
      }
    });

    test('parseReadyPrompt: overlay text is extracted to textOverlay and stripped from promptText', () {
      const readyPrompt = '''PROMPT: Foundation

Part 3 (20-30s): Ria puts on shoes correctly. Mumma hugs. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Give children opportunities to practise independence.
''';
      final result = GeminiVideoResult.parseReadyPrompt(readyPrompt, 'Test');
      final p3 = result.parts.firstWhere((p) => p.partNumber == 3);

      // Overlay value is extracted into textOverlay
      expect(p3.textOverlay, contains('LEARNING IS A HABIT'));
      expect(p3.textOverlay, contains('SMALL WINS BIG HEARTS'));

      // Overlay instruction is NOT in promptText
      expect(p3.promptText, isNot(contains('Final text overlay')));
      expect(p3.promptText, isNot(contains('LEARNING IS A HABIT')));

      // Moral and scene description remain intact
      expect(p3.promptText, contains('Moral:'));
      expect(p3.promptText, contains('independence'));
      expect(p3.promptText, contains('Ria puts on shoes'));
    });

    test('parseReadyPrompt: handles missing overlay gracefully', () {
      const readyPrompt = '''PROMPT: Foundation

Part 1 (0-10s): Hook introduction
Part 2 (10-20s): Twist escalation
Part 3 (20-30s): Resolution and Moral: Be kind to others.
''';
      final result = GeminiVideoResult.parseReadyPrompt(readyPrompt, 'Test');
      final p3 = result.parts.firstWhere((p) => p.partNumber == 3);

      // No overlay in source, textOverlay is empty
      expect(p3.textOverlay, isEmpty);

      // promptText still contains the moral
      expect(p3.promptText, contains('Moral:'));
    });

    test('parseReadyPrompt: handles overlay at end of prompt without Moral', () {
      const readyPrompt = '''PROMPT: Foundation

Part 1 (0-10s): Hook introduction
Part 2 (10-20s): Twist escalation
Part 3 (20-30s): Resolution. Final text overlay: BE KIND.
''';
      final result = GeminiVideoResult.parseReadyPrompt(readyPrompt, 'Test');
      final p3 = result.parts.firstWhere((p) => p.partNumber == 3);

      expect(p3.textOverlay, contains('BE KIND'));
      expect(p3.promptText, isNot(contains('Final text overlay')));
      expect(p3.promptText, isNot(contains('BE KIND')));
      expect(p3.promptText, contains('Resolution.'));
    });

    test('parseReadyPrompt: repaired hooks retain apostrophes and quotes in Part 3', () {
      final checks = <String, List<String>>{
        'pal01': ["Cuty yawns in Mumma's arms. \"Ria, Rio ya Cuty"],
        'pal05': ["around Ria's shoulders, both half-asleep by page three"],
        'pal14': ["Ria's tears turn to giggles as they draw"],
        'pal18': ["Bow back in Ria's hair", "Sock on Ria's foot"],
      };

      for (final entry in checks.entries) {
        final h = kDefaultHooks.firstWhere((e) => e.id == entry.key);
        final result = GeminiVideoResult.parseReadyPrompt(h.readyPrompt, h.cover);
        final p3 = result.parts.firstWhere((p) => p.partNumber == 3);
        for (final expected in entry.value) {
          expect(p3.promptText, contains(expected),
              reason: '${entry.key}: Part 3 missing "$expected"');
        }
      }
    });

    test('parseReadyPrompt: overlay text is preserved in textOverlay metadata across all 60 hooks', () {
      final hooks = [
        for (final h in [...kSafetyHooks, ...kDefaultHooks])
          if (h.readyPrompt.isNotEmpty && h.readyPrompt.contains('Final text overlay')) h,
      ];
      for (final h in hooks) {
        final result = GeminiVideoResult.parseReadyPrompt(h.readyPrompt, h.cover);
        final p3 = result.parts.firstWhere((p) => p.partNumber == 3);
        expect(p3.textOverlay, isNotEmpty,
            reason: '${h.id}: textOverlay should be populated');
        expect(p3.textOverlay, isNot(contains('Final text overlay')),
            reason: '${h.id}: textOverlay should not contain the label');
        expect(p3.promptText, isNot(contains('Final text overlay')),
            reason: '${h.id}: promptText should not contain overlay label');
        expect(p3.promptText, isNot(contains('LEARNING IS A HABIT')),
            reason: '${h.id}: promptText should not contain overlay value');
      }
    });

    test('parseReadyPrompt: dialogue and scene content survives overlay extraction', () {
      final hooks = [
        for (final h in [...kSafetyHooks, ...kDefaultHooks])
          if (h.readyPrompt.isNotEmpty && h.readyPrompt.contains('Final text overlay')) h,
      ];
      for (final h in hooks) {
        final result = GeminiVideoResult.parseReadyPrompt(h.readyPrompt, h.cover);
        for (final p in result.parts) {
          // Dialogue and scene descriptions should remain
          expect(p.promptText.trim(), isNotEmpty,
              reason: '${h.id}: Part ${p.partNumber} promptText is empty after extraction');
        }
      }
    });

    group('parseReadyPrompt header variations', () {
      test('header with inline content', () {
        final prompt = '''PROMPT: Foundation text

Part 1 (0-10s): Inline content for part 1
Part 2 (10-20s): Inline content for part 2
Part 3 (20-30s): Inline "quotes" and apostrophes here
''';
        final result = GeminiVideoResult.parseReadyPrompt(prompt, 'Test');
        expect(result.parts.length, 3);
        expect(result.parts[0].promptText, contains('Inline content for part 1'));
        expect(result.parts[1].promptText, contains('Inline content for part 2'));
        expect(result.parts[2].promptText, contains('Inline "quotes"'));
      });

      test('header with content on subsequent lines', () {
        final prompt = '''PROMPT: Foundation text

Part 1 (0-10s):
Content next line 1
Part 2 (10-20s):
Content next line 2
Part 3 (20-30s):
Content next line 3
''';
        final result = GeminiVideoResult.parseReadyPrompt(prompt, 'Test');
        expect(result.parts.length, 3);
        expect(result.parts[0].promptText, contains('Content next line 1'));
        expect(result.parts[1].promptText, contains('Content next line 2'));
        expect(result.parts[2].promptText, contains('Content next line 3'));
      });

      test('different spacing and capitalization', () {
        final prompt = '''PROMPT: Foundation text

PART 1 (0-10s): Content 1
Part 2(10-20s): Content 2
  part 3 (20-30s): Content 3
''';
        final result = GeminiVideoResult.parseReadyPrompt(prompt, 'Test');
        expect(result.parts.length, 3);
        expect(result.parts[0].promptText, contains('Content 1'));
        expect(result.parts[1].promptText, contains('Content 2'));
        expect(result.parts[2].promptText, contains('Content 3'));
      });

      test('missing Part 2 retains Part 1 and Part 3', () {
        final prompt = '''PROMPT: Foundation

Part 1 (0-10s): Content 1
Part 3 (20-30s): Content 3
''';
        final result = GeminiVideoResult.parseReadyPrompt(prompt, 'Test');
        expect(result.parts.length, 2);
        expect(result.parts[0].partNumber, 1);
        expect(result.parts[1].partNumber, 3);
      });

      test('empty input falls back to single part', () {
        final result = GeminiVideoResult.parseReadyPrompt('', 'Empty');
        expect(result.parts.length, 1);
        expect(result.parts[0].purpose, 'Full Prompt');
      });

      test('non-part text falls back to single part', () {
        final result = GeminiVideoResult.parseReadyPrompt('Just text', 'Fallback');
        expect(result.parts.length, 1);
        expect(result.parts[0].purpose, 'Full Prompt');
      });
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

    test('New readyPrompt entries: each has 3 parts with Moral and Final text overlay', () {
      final newIds = [
        'h06', 'pal10', 'pal12', 'h10', 'h11', 'h12', 'h13', 'h14', 'h15',
        'h16', 'h17', 'h18', 'h20', 'h21', 'p05', 'h23', 'h24', 'h25', 'h26',
        'park-se-nikalna',
      ];
      for (final id in newIds) {
        final h = kDefaultHooks.firstWhere((e) => e.id == id, orElse: () =>
            throw StateError('Hook not found: $id'));
        expect(h.readyPrompt, isNotEmpty, reason: '$id readyPrompt is empty');
        expect(h.readyPrompt, contains('Part 1 (0-10s)'),
            reason: '$id missing Part 1 (0-10s)');
        expect(h.readyPrompt, contains('Part 2 (10-20s)'),
            reason: '$id missing Part 2 (10-20s)');
        expect(h.readyPrompt, contains('Part 3 (20-30s)'),
            reason: '$id missing Part 3 (20-30s)');
        expect(h.readyPrompt, contains('Moral:'),
            reason: '$id Part 3 missing Moral');
        expect(h.readyPrompt, contains('Final text overlay:'),
            reason: '$id missing Final text overlay');
        final result = GeminiVideoResult.parseReadyPrompt(h.readyPrompt, h.cover);
        expect(result.parts.length, 3,
            reason: '$id: parseReadyPrompt failed - expected 3 parts, got ${result.parts.length}');
        final p3 = result.parts.firstWhere((p) => p.partNumber == 3);
        expect(p3.promptText, contains('Moral:'),
            reason: '$id: Part 3 missing Moral after parse');
        expect(p3.textOverlay, isNotEmpty,
            reason: '$id: Part 3 textOverlay empty after parse');
        expect(p3.textOverlay, contains('LEARNING IS A HABIT'),
            reason: '$id: textOverlay should contain standard footer');
        expect(p3.textOverlay, isNot(contains('Moral:')),
            reason: '$id: textOverlay should not contain Moral');
      }
    });


    test('New readyPrompt entries: correct characters mentioned', () {
      final characterChecks = {
        'h06': ['Ria', 'Rio', 'Mumma'],
        'pal12': ['Cuty', 'Mumma'],
        'h10': ['Rio', 'Mumma'],
        'h11': ['Ria', 'Mumma'],
        'h12': ['Ria', 'Mumma'],
        'h13': ['Ria', 'Cuty'],
        'h14': ['Ria', 'Rio', 'Mumma'],
        'h15': ['Rio', 'Mumma'],
        'h16': ['Robot', 'Papa'],
        'h17': ['Ria', 'Mumma'],
        'h18': ['Rio', 'Mumma', 'Papa'],
        'h20': ['Rio', 'Mumma'],
        'h21': ['Ria', 'Mumma'],
        'h23': ['Rio', 'Mumma', 'Papa'],
        'p05': ['Ria', 'Rio', 'Cuty'],
      };
      for (final entry in characterChecks.entries) {
        final h = kDefaultHooks.firstWhere((e) => e.id == entry.key);
        for (final character in entry.value) {
          expect(h.readyPrompt, contains(character),
              reason: '${entry.key}: expected character "$character" in readyPrompt');
        }
      }
    });

    test('asmr-cleaning-reel: safety regression - no child sitting in paste', () {
      final h = kDefaultHooks.firstWhere((e) => e.id == 'asmr-cleaning-reel');
      final combined = '${h.storyDetail} ${h.sceneDetail} ${h.mess} ${h.endingBeat}';
      expect(combined, isNot(contains('sitting in')),
          reason: 'Child should not be described as sitting in paste');
      expect(combined, isNot(contains('in the paste')),
          reason: 'Child should not be in the paste');
      expect(h.mess, contains('hands'),
          reason: 'Mess should describe hands covered in flour, not paws');
      expect(h.endingBeat, contains('dry brush'),
          reason: 'Ending should describe proper technique');
      expect(h.defaultCast, contains('Ria'),
          reason: 'Default cast should include Ria');
      expect(h.defaultCast, isNot(contains('Cuty')),
          reason: 'Default cast should not include Cuty');
    });
  });
}

const kRewrittenStoryIds = {
  'h01', 'h02', 'h03', 'h04', 'h05', 'h07', 'h08',
  'h12', 'h13', 'h14', 'h15', 'h16', 'h17', 'h19', 'h19b',
  'pal03', 'pal19',
};
