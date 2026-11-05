import 'dart:convert';
import 'dart:io';

/// Re-exports `assets/data/content_ideas.json` in canonical form.
///
/// Reads the current JSON, validates the built-in set (idea_1..idea_117,
/// idea_117 at index 78, archived = {idea_43, idea_44, idea_46}), and writes
/// it back with a fresh `generatedAt` timestamp. The total record count is
/// allowed to grow when users add custom ideas (idea_118+), so the count is
/// reported but not asserted.

void main() {
  final rawContent = File('assets/data/content_ideas.json').readAsStringSync();
  final jsonData = jsonDecode(rawContent) as Map<String, dynamic>;
  final ideas = (jsonData['ideas'] as List).cast<Map<String, dynamic>>();

  final seen = <String>{};
  for (final h in ideas) {
    final id = h['id'] as String?;
    if (id == null) {
      stderr.writeln('MISSING_ID: an idea has no id');
      exit(1);
    }
    if (!seen.add(id)) {
      stderr.writeln('DUPLICATE ID: $id');
      exit(1);
    }
  }

  // Every built-in idea_1..idea_117 must be present exactly once.
  final idSet = seen;
  for (var i = 1; i <= 117; i++) {
    if (!idSet.contains('idea_$i')) {
      stderr.writeln('MISSING_BUILTIN: idea_$i');
      exit(1);
    }
  }

  // idea_117 sits at index 78.
  if (ideas[78]['id'] != 'idea_117') {
    stderr.writeln(
      'ORDER_MISMATCH: expected idea_117 at index 78, got ${ideas[78]['id']}',
    );
    exit(1);
  }

  // Archived set is exactly {idea_43, idea_44, idea_46}.
  final archivedIds = ideas
      .where((h) => h['archived'] == true)
      .map((h) => h['id'] as String)
      .toSet();
  if (archivedIds.length != 3) {
    stderr.writeln(
      'ARCHIVED_COUNT_MISMATCH: expected 3, got ${archivedIds.length}',
    );
    exit(1);
  }
  for (final a in const {'idea_43', 'idea_44', 'idea_46'}) {
    if (!archivedIds.contains(a)) {
      stderr.writeln('MISSING_ARCHIVED_ID: $a');
      exit(1);
    }
  }

  // idea_41 / idea_42 must NOT be archived.
  final idea41 = ideas.firstWhere((h) => h['id'] == 'idea_41');
  final idea42 = ideas.firstWhere((h) => h['id'] == 'idea_42');
  if (idea41['archived'] == true) {
    stderr.writeln('idea_41 should not be archived');
    exit(1);
  }
  if (idea42['archived'] == true) {
    stderr.writeln('idea_42 should not be archived');
    exit(1);
  }

  final out = {
    'version': '1.0.0',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'ideas': ideas,
  };

  Directory('assets/data').createSync(recursive: true);
  File('assets/data/content_ideas.json').writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(out),
  );

  print('Records: ${ideas.length}');
  print('Unique IDs: ${seen.length}');
  print('Written to assets/data/content_ideas.json');
}