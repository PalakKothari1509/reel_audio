import 'package:flutter_test/flutter_test.dart';

import '../lib/hook_templates.dart';

void main() {
  group('HookTemplate', () {
    test('12 templates defined', () {
      expect(kHookTemplates.length, 12);
    });

    test('all templates have non-empty fields', () {
      for (final t in kHookTemplates) {
        expect(t.id, isNotEmpty);
        expect(t.name, isNotEmpty);
        expect(t.pattern, isNotEmpty);
        expect(t.trigger, isNotEmpty);
        expect(t.replacement, isNotEmpty);
      }
    });

    test('triggers cover all psychological categories', () {
      final triggers = kHookTemplates.map((t) => t.trigger).toSet();
      expect(triggers, contains('Recognition'));
      expect(triggers, contains('Curiosity gap'));
      expect(triggers, contains('Social proof'));
      expect(triggers, contains('Loss aversion'));
    });

    test('apply fills child and detail', () {
      final t = kHookTemplates.firstWhere((t) => t.id == 'refusal');
      final result = t.apply('Ria', 'naya frock');
      expect(result, contains('Ria'));
      expect(result, contains('naya frock'));
    });
  });

  group('HookGenerator', () {
    test('generateAll produces 12 hooks from templates', () {
      final gen = HookGenerator();
      final hooks = gen.generateAll(
        'Ria', 'naya frock', 'help karna', 'mummy',
        'blocks jodna', 3, 'Subah 8', 'morning chaos',
        'calm mil Gayi', '1',
      );
      expect(hooks.length, 12);
    });

    test('generateAll hooks are non-empty', () {
      final gen = HookGenerator();
      final hooks = gen.generateAll(
        'Ria', 'naya frock', 'help karna', 'mummy',
        'blocks jodna', 3, 'Subah 8', 'morning chaos',
        'calm mil Gayi', '1',
      );
      for (final h in hooks) {
        expect(h, isNotEmpty);
      }
    });

    test('generateRandom returns a non-empty hook', () {
      final gen = HookGenerator();
      final hook = gen.generateRandom('Rio', 'tower gir gaya');
      expect(hook, isNotEmpty);
    });

    test('getTemplateNames returns 12 names', () {
      final gen = HookGenerator();
      expect(gen.getTemplateNames().length, 12);
    });

    test('getTriggers returns unique triggers', () {
      final gen = HookGenerator();
      final triggers = gen.getTriggers();
      expect(triggers.length, greaterThan(1));
      expect(triggers, isNotEmpty);
    });
  });

  group('Power words', () {
    test('power words use list has 15 entries', () {
      expect(kPowerWordsUse.length, 15);
    });

    test('power words avoid list has 6 entries', () {
      expect(kPowerWordsAvoid.length, 6);
    });
  });
}
