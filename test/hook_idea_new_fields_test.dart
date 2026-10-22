import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_ideas.dart';

void main() {
  group('HookIdea new fields (quote, detail, punchline)', () {
    test('HookIdea constructor accepts new fields', () {
      final hook = HookIdea(
        id: 'test-1',
        category: 'Test',
        cover: 'Test Cover',
        opening: 'Test opening',
        problem: 'Test problem',
        lesson: 'Test lesson',
        quote: 'Test quote',
        detail: 'Test detail',
        punchline: 'Test punchline',
      );

      expect(hook.quote, 'Test quote');
      expect(hook.detail, 'Test detail');
      expect(hook.punchline, 'Test punchline');
    });

    test('HookIdea copyWith works with new fields', () {
      final hook = HookIdea(
        id: 'test-1',
        category: 'Test',
        cover: 'Test Cover',
        opening: 'Test opening',
        problem: 'Test problem',
        lesson: 'Test lesson',
      );

      final updated = hook.copyWith(
        quote: 'New quote',
        detail: 'New detail',
        punchline: 'New punchline',
      );

      expect(updated.quote, 'New quote');
      expect(updated.detail, 'New detail');
      expect(updated.punchline, 'New punchline');
      // Original unchanged
      expect(hook.quote, '');
      expect(hook.detail, '');
      expect(hook.punchline, '');
    });

    test('HookIdea toJson includes new fields', () {
      final hook = HookIdea(
        id: 'test-1',
        category: 'Test',
        cover: 'Test Cover',
        opening: 'Test opening',
        problem: 'Test problem',
        lesson: 'Test lesson',
        quote: 'Test quote',
        detail: 'Test detail',
        punchline: 'Test punchline',
      );

      final json = hook.toJson();
      expect(json['quote'], 'Test quote');
      expect(json['detail'], 'Test detail');
      expect(json['punchline'], 'Test punchline');
    });

    test('HookIdea fromJson reads new fields', () {
      final json = {
        'id': 'test-1',
        'category': 'Test',
        'cover': 'Test Cover',
        'opening': 'Test opening',
        'problem': 'Test problem',
        'lesson': 'Test lesson',
        'quote': 'Test quote',
        'detail': 'Test detail',
        'punchline': 'Test punchline',
      };

      final hook = HookIdea.fromJson(json);
      expect(hook.quote, 'Test quote');
      expect(hook.detail, 'Test detail');
      expect(hook.punchline, 'Test punchline');
    });

    test('HookIdea fromJson defaults new fields to empty string', () {
      final json = {
        'id': 'test-1',
        'category': 'Test',
        'cover': 'Test Cover',
        'opening': 'Test opening',
        'problem': 'Test problem',
        'lesson': 'Test lesson',
      };

      final hook = HookIdea.fromJson(json);
      expect(hook.quote, '');
      expect(hook.detail, '');
      expect(hook.punchline, '');
    });
  });
}