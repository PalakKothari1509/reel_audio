// Reads content_ideas.md and reports every axis value, so the migration can be
// written against real data instead of assumptions. Read-only.
//
//   dart run tool/dump_ideas.dart
//
// Written in Dart rather than PowerShell because the parser already has to exist in
// Dart for task T-19, and the PowerShell version kept matching zero field lines
// against a file that plainly contains them.

import 'dart:io';

class Idea {
  final String heading;
  final Map<String, String> fields = {};
  Idea(this.heading);
}

List<Idea> parseIdeas(String markdown) {
  final ideas = <Idea>[];
  Idea? current;
  var inFence = false;

  for (final raw in markdown.split('\n')) {
    final line = raw.replaceAll('\r', '').trimRight();

    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    if (line.startsWith('### ')) {
      if (current != null) ideas.add(current);
      current = Idea(line.substring(4).trim());
      continue;
    }
    if (current == null) continue;

    // Both shapes exist in the file: one field per line, and the packed
    // "- **Series:** x | **Format:** y | **Goal:** z" used by newer entries.
    //
    // Two bold conventions are in play, and matching only one silently yields zero
    // fields from a file that plainly contains them. `content_ideas.md` writes
    // `- **id:** value` with the colon INSIDE the bold. `content_formats.md` writes
    // `- **ID**: value` with the colon outside. Both are accepted here.
    for (final part in line.split(RegExp(r'\s*\|\s*'))) {
      final m = _field.firstMatch(part);
      if (m != null) {
        final key = (m.group(1) ?? m.group(2) ?? '').trim();
        if (key.isNotEmpty) {
          current!.fields[key] = m.group(3)!.trim();
        }
      }
    }
  }
  if (current != null) ideas.add(current);
  return ideas;
}

/// A metadata field, in either bold convention.
final _field = RegExp(
  r'^\s*(?:-\s*)?(?:\*\*(.+?):\*\*|\*\*(.+?)\*\*\s*:)\s*(.*)$',
);

void main() {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseIdeas(file.readAsStringSync());
  stdout.writeln('IDEA BLOCKS: ${ideas.length}');
  stdout.writeln('');

  // Distinct values per axis, so nothing is missed by eyeballing.
  final axes = <String, Map<String, int>>{
    'Series': {},
    'Format': {},
    'Best content type': {},
    'Content Format': {},
    'Production': {},
    'Goal': {},
    'Status': {},
    'Pillar': {},
    'Priority': {},
  };

  for (final idea in ideas) {
    for (final axis in axes.keys) {
      final v = idea.fields[axis];
      if (v != null && v.isNotEmpty) {
        axes[axis]!.update(v, (n) => n + 1, ifAbsent: () => 1);
      }
    }
  }

  for (final entry in axes.entries) {
    if (entry.value.isEmpty) {
      stdout.writeln('${entry.key}:  (none present)');
      continue;
    }
    final sorted = entry.value.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    stdout.writeln('${entry.key}:');
    for (final e in sorted) {
      stdout.writeln('   ${e.value}x  ${e.key}');
    }
    stdout.writeln('');
  }

  stdout.writeln('--- per idea ---');
  for (var i = 0; i < ideas.length; i++) {
    final f = ideas[i].fields;
    String g(String k) => f[k] ?? '';
    stdout.writeln('${(i + 1).toString().padLeft(3)} | '
        '${g('id').padRight(24)} | '
        '${g('Series').padRight(22)} | '
        '${g('Format').padRight(22)} | '
        '${g('Best content type').padRight(11)} | '
        '${g('Production').padRight(10)} | '
        '${g('Goal')}');
  }
}