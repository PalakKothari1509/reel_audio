import 'dart:io';

/// The idea-level verdict, separate from the axis decisions.
///
/// `delete` means "remove from the library". An idea that already
/// has packages, tests or results is not destroyed by it — see
/// CONTENT_MODEL.md §3b. No idea has packages yet, so every
/// delete is currently a complete removal.
enum IdeaVerdict { keep, rework, archive, delete }

/// One idea-level decision from `tool/idea_decisions.csv`.
class IdeaDecision {
  final String ideaId;
  final IdeaVerdict verdict;
  final String note;

  IdeaDecision(this.ideaId, this.verdict, this.note);
}

/// Reads `tool/idea_decisions.csv`, failing loudly on anything
/// malformed. A skipped row would turn a human decision into an
/// undecided idea, and the gate would then report the wrong
/// verdict — the same failure mode [readDecisions] exists to
/// prevent.
Map<String, IdeaDecision> readIdeaDecisions(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final out = <String, IdeaDecision>{};
  final lines = file.readAsLinesSync();

  for (var i = 1; i < lines.length; i++) {
    final l = lines[i];
    if (l.trim().isEmpty || l.trimLeft().startsWith('#')) continue;

    final m = RegExp(r'^([^,]+),([^,]+),(.*)$').firstMatch(l);
    if (m == null) {
      stderr.writeln('$path line ${i + 1}: cannot parse.');
      exitCode = 1;
      return {};
    }

    final raw = m.group(2)!.trim().toLowerCase();
    IdeaVerdict? verdict;
    for (final v in IdeaVerdict.values) {
      if (v.name == raw) {
        verdict = v;
        break;
      }
    }
    if (verdict == null) {
      stderr.writeln('$path line ${i + 1}: unknown decision "$raw". '
          'Expected one of ${IdeaVerdict.values.map((v) => v.name).join(', ')}.');
      exitCode = 1;
      return {};
    }

    var note = m.group(3)!.trim();
    if (note.startsWith('"') && note.endsWith('"') && note.length > 1) {
      note = note.substring(1, note.length - 1);
    }
    out[m.group(1)!.trim()] = IdeaDecision(m.group(1)!.trim(), verdict, note);
  }
  return {};
}
