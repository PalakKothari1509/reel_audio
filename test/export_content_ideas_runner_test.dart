import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/export_content_ideas.dart' as exporter;

void main() {
  test('export content ideas', () async {
    Directory('assets/data').createSync(recursive: true);
    exporter.main();
    final file = File('assets/data/content_ideas.json');
    expect(file.existsSync(), isTrue);

    final raw = file.readAsStringSync();
    final d = jsonDecode(raw) as Map<String, dynamic>;
    expect(d['version'], '1.0.0');
    final ideas = (d['ideas'] as List).cast<Map<String, dynamic>>();
    expect(ideas.length, greaterThanOrEqualTo(117));

    // Every built-in id idea_1..idea_117 must be present exactly once.
    final ids = ideas.map((i) => i['id'] as String).toSet();
    for (var i = 1; i <= 117; i++) {
      expect(ids.contains('idea_$i'), isTrue,
          reason: 'missing built-in idea_$i');
    }

    // idea_117 sits at index 78 (after the 77 that precede it).
    expect(ideas[78]['id'], 'idea_117');

    // Archived set is exactly {idea_43, idea_44, idea_46}.
    final archived =
        ideas.where((i) => i['archived'] == true).map((i) => i['id']).toSet();
    expect(archived, {'idea_43', 'idea_44', 'idea_46'});

    // idea_41 / idea_42 must NOT be archived.
    expect(
      ideas.firstWhere((i) => i['id'] == 'idea_41')['archived'],
      isNot(true),
    );
    expect(
      ideas.firstWhere((i) => i['id'] == 'idea_42')['archived'],
      isNot(true),
    );
  });
}