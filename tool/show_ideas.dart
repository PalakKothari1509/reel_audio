import 'dart:io';

/// Prints the full text of the named ideas, so decisions are made from what an idea
/// actually says rather than from a keyword tally.
///
///   dart run tool/show_ideas.dart day12-dinner-types jm-phone-meals
///
/// The set of ids is a command-line argument rather than a hardcoded constant. It
/// started hardcoded, which meant inspecting a different set of ideas meant editing
/// the tool, and the constant was stale within a single session.

Set<String> _wanted(List<String> argv) => argv.toSet();

void main(List<String> argv) {
  final ids = _wanted(argv);
  if (ids.isEmpty) {
    stderr.writeln('Pass one or more idea ids to inspect.');
    exitCode = 1;
    return;
  }

  final field = RegExp(
      r'^\s*(?:-\s*)?(?:\*\*(.+?):\*\*|\*\*(.+?)\*\*\s*:)\s*(.*)$');

  final out = StringBuffer();
  String? heading;
  var id = '';
  var inFence = false;
  final pending = <String>[];

  void emit() {
    if (heading == null || !ids.contains(id)) {
      heading = null;
      id = '';
      pending.clear();
      return;
    }
    out.writeln('=== $id ===');
    out.writeln('  heading: $heading');
    for (final raw in pending) {
      final m = field.firstMatch(raw.split(RegExp(r'\s*\|\s*')).first);
      if (m == null) continue;
      final k = (m.group(1) ?? m.group(2) ?? '').trim();
      final v = (m.group(3) ?? '').trim();
      if (k == 'id' || k == 'Status' || k == 'Priority') continue;
      out.writeln('  $k: $v');
    }
    out.writeln('');
    heading = null;
    id = '';
    pending.clear();
  }

  for (final raw in File('content_ideas.md').readAsStringSync().split('\n')) {
    final line = raw.replaceAll('\r', '').trimRight();

    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    if (line.startsWith('### ')) {
      emit();
      heading = line.substring(4).trim();
      continue;
    }
    if (heading == null) continue;

    for (final part in line.split(RegExp(r'\s*\|\s*'))) {
      final m = field.firstMatch(part);
      if (m != null && (m.group(1) ?? m.group(2)) == 'id') {
        id = (m.group(3) ?? '').replaceAll('`', '').trim();
      }
    }

    if (line.trim() == '---') {
      emit();
      continue;
    }
    pending.add(line);
  }
  emit();

  print(out.toString());
}