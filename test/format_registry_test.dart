import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/format_handbook.dart';

void main() {
  group('format registry', () {
    test('registers exactly 50 formats', () {
      expect(FormatLibrary.all.length, 50);
    });

    test('all ids are unique', () {
      final ids = FormatLibrary.all.map((f) => f.id).toSet();
      expect(ids.length, FormatLibrary.all.length);
    });

    test('all names are unique', () {
      final names = FormatLibrary.all.map((f) => f.name).toSet();
      expect(names.length, FormatLibrary.all.length);
    });

    test('every format has a non-empty definition', () {
      for (final f in FormatLibrary.all) {
        expect(f.definition.trim(), isNotEmpty, reason: '${f.id} has empty definition');
      }
    });

    test('every format has at least one structure beat', () {
      for (final f in FormatLibrary.all) {
        expect(f.structure, isNotEmpty, reason: '${f.id} has no structure beats');
      }
    });

    test('every format has at least one generation rule', () {
      for (final f in FormatLibrary.all) {
        expect(f.generationRules, isNotEmpty, reason: '${f.id} has no generation rules');
      }
    });

    test('every format has an example over 40 characters', () {
      for (final f in FormatLibrary.all) {
        expect(f.example.length, greaterThan(40), reason: '${f.id} example too short');
      }
    });

    test('every format declares at least one content type', () {
      for (final f in FormatLibrary.all) {
        expect(f.bestContentTypes, isNotEmpty, reason: '${f.id} has no content type');
      }
    });

    test('every format declares at least one goal', () {
      for (final f in FormatLibrary.all) {
        expect(f.bestGoals, isNotEmpty, reason: '${f.id} has no goal');
      }
    });
  });

  group('axis validation', () {
    test('all content type references resolve to known ids', () {
      final problems = validateAxes();
      expect(problems, isEmpty, reason: 'Axis validation failed: ${problems.join('; ')}');
    });

    test('all goal references resolve to known ids', () {
      final knownGoals = kGoalIds.toSet();
      for (final f in FormatLibrary.all) {
        for (final g in f.bestGoals) {
          expect(knownGoals, contains(g), reason: '${f.id} references unknown goal "$g"');
        }
      }
    });

    test('all content type references resolve to known ids', () {
      final knownTypes = kContentTypeIds.toSet();
      for (final f in FormatLibrary.all) {
        for (final t in f.bestContentTypes) {
          expect(knownTypes, contains(t), reason: '${f.id} references unknown content type "$t"');
        }
      }
    });

    test('defaultFor values are valid content types', () {
      for (final f in FormatLibrary.all) {
        for (final d in f.defaultFor) {
          expect(kContentTypeIds, contains(d), reason: '${f.id} defaults to unknown type "$d"');
        }
      }
    });
  });

  group('lookup', () {
    test('byId resolves every registered id', () {
      for (final f in FormatLibrary.all) {
        expect(FormatLibrary.byId(f.id), same(f), reason: 'byId failed for ${f.id}');
      }
    });

    test('byName resolves every registered name', () {
      for (final f in FormatLibrary.all) {
        expect(FormatLibrary.byName(f.name), same(f), reason: 'byName failed for ${f.name}');
      }
    });

    test('unknown id returns null', () {
      expect(FormatLibrary.byId('nonexistent'), isNull);
    });

    test('unknown name returns null', () {
      expect(FormatLibrary.byName('Nonexistent'), isNull);
    });
  });

  group('recommend', () {
    test('returns null for unmatched axes', () {
      expect(FormatLibrary.recommend(contentType: 'unknown', goal: 'unknown'), isNull);
    });

    test('returns a format for valid axes', () {
      final rec = FormatLibrary.recommend(contentType: 'reel', goal: 'reach');
      expect(rec, isNotNull);
    });

    test('a format that does not support the content type is not recommended', () {
      final rec = FormatLibrary.recommend(contentType: 'reel', goal: 'reach');
      if (rec != null) {
        expect(rec.supportsContentType('reel'), isTrue);
      }
    });
  });

  group('prompt block', () {
    test('toPromptBlock names the format', () {
      for (final f in FormatLibrary.all) {
        final block = f.toPromptBlock();
        expect(block, contains('${f.name} (${f.id})'), reason: '${f.id} block does not name the format');
      }
    });

    test('toPromptBlock carries beats', () {
      for (final f in FormatLibrary.all) {
        final block = f.toPromptBlock();
        expect(block, contains('Structure, in order:'), reason: '${f.id} block has no structure');
      }
    });

    test('toPromptBlock carries rules', () {
      for (final f in FormatLibrary.all) {
        final block = f.toPromptBlock();
        expect(block, contains('Generation rules:'), reason: '${f.id} block has no rules');
      }
    });

    test('toPromptBlock omits the example', () {
      for (final f in FormatLibrary.all) {
        final block = f.toPromptBlock();
        expect(block, isNot(contains(f.example.substring(0, 20))), reason: '${f.id} block includes the example');
      }
    });
  });

  group('five-test rule integration', () {
    test('every format enforces the five-test minimum at 4 tests', () {
      for (final f in FormatLibrary.all) {
        final v = f.verdict(4);
        expect(v.allowed, isFalse, reason: '${f.id} allowed 4 tests');
      }
    });

    test('every format allows at 5 tests', () {
      for (final f in FormatLibrary.all) {
        final v = f.verdict(5);
        expect(v.allowed, isTrue, reason: '${f.id} blocked 5 tests');
      }
    });
  });
}
