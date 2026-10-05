import 'dart:io';

import '../lib/content_axes.dart';
import 'classify_ideas.dart';
import 'migration_state.dart';

/// Pins the classifier's known false positives so they cannot come back.
///
///   dart run tool/check_pillars.dart
///
/// ── Why this asserts what it asserts ─────────────────────────────────────────
//
// The keyword pillar matcher produced five wrong answers, all of the same kind: one
// stray term creating a tie that then read as a decision. `ask` matched both TALK and
/// DO for day5-ask-tonight; `match` matched THINK for a concert made of pots and
/// spoons; `clue` matched TALK for a treasure hunt; `hands` matched DO for an activity;
///
/// The instruction was not to widen the vocabulary. Widening it would make the
/// classifier report HIGH confidence for the right answers without making it any more
// semantically capable, which is worse than an honest miss: a confident wrong pillar
// silently misfiles the performance data of a post that was actually good.
//
// So the invariant here is deliberately weaker than "the matcher is right". It is:
//
//   a human decision always wins, and the matcher must never be CONFIDENTLY WRONG
//   about an idea a human has already decided.
//
// A tie or a miss is acceptable. A confident contradiction is not. That is the
// property worth protecting, and it is checkable without pretending the matcher
// understands the ideas.

/// The five documented false positives, with the human decision each must not
/// contradict.
const _regressions = <String, String>{
  'day5-ask-tonight': 'TALK',
  'day18-mission2-concert': 'PLAY',
  'day22-mission6-treasure': 'THINK',
  'jm-tape-pull': 'PLAY',
  'lp-kitchen-counting': 'THINK',
};

/// Decisions the matcher is allowed to tie with or miss entirely.
const _toleratedMisses = {'lp-kitchen-counting'};

void main() {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseFile(file.readAsStringSync()).ideas;
  final decisions =
      readDecisions('tool/pillar_decisions.csv', requireEvidence: true);

  var failures = 0;
  void check(String label, bool ok, [String detail = '']) {
    if (ok) {
      stdout.writeln('  ok    $label');
    } else {
      failures++;
      stdout.writeln('  FAIL  $label${detail.isEmpty ? '' : '  ($detail)'}');
    }
  }

  stdout.writeln('Pillar decision regression checks');
  stdout.writeln('================================');
  stdout.writeln('');
  stdout.writeln('Ideas parsed          : ${ideas.length}');
  stdout.writeln('Pillar decisions read : ${decisions.length}');
  stdout.writeln('');

  // -- Every decision resolves to a real pillar, or is deliberately valueless.
  stdout.writeln('Decision validity');
  for (final d in decisions.values) {
    if (d.state == MigrationState.archiveCandidate) {
      check('${d.ideaId} archiveCandidate carries no pillar', d.value.isEmpty);
      continue;
    }
    if (d.state != MigrationState.suggested &&
        d.state != MigrationState.approved) {
      check('${d.ideaId} ${d.state.name} carries no value', d.value.isEmpty);
      continue;
    }
    check('${d.ideaId} pillar is a real value',
        ContentPillar.byLabel(d.value) != null, d.value);
  }

  // -- The human decision outranks the matcher.
  stdout.writeln('');
  stdout.writeln('The matcher must never be confidently wrong about a decided idea');
  for (final entry in _regressions.entries) {
    final idea = ideas.where((i) => i.id == entry.key).toList();
    if (idea.isEmpty) {
      check('${entry.key} exists', false, 'not found in content_ideas.md');
      continue;
    }
    final decided = decisions[entry.key];
    if (decided == null) {
      check('${entry.key} has a pillar decision', false);
      continue;
    }

    final guess = Classifier(idea.first).classifyPillar();
    final contradicts =
        guess.value.isNotEmpty && guess.value != entry.value &&
            guess.confidence == Confidence.high;

    if (contradicts) {
      check('${entry.key}: matcher does not confidently contradict '
          '${entry.value}',
          false,
          'matcher says ${guess.value} at high confidence — ${guess.reason}');
      continue;
    }

    final agrees = guess.value == entry.value && guess.value.isNotEmpty;
    check('${entry.key}: not confidently wrong',
        true,
        agrees
            ? 'matcher agrees'
            : _toleratedMisses.contains(entry.key)
                ? 'tolerated miss'
                : 'matcher is unsure: ${guess.reason}');
  }

  // -- Beat-only evidence stays flagged.
  stdout.writeln('');
  stdout.writeln('Evidence flags');
  final beatOnly = decisions.values.where((d) => d.evidence == 'beat_only');
  check('beat_only evidence is recorded where it applies', beatOnly.isNotEmpty);
  for (final d in beatOnly) {
    stdout.writeln('  note  ${d.ideaId}: rests on the beat description alone');
  }

  stdout.writeln('');
  stdout.writeln('------------------------------------------------------------');
  if (failures == 0) {
    stdout.writeln('All checks passed. A human decision always wins.');
  } else {
    stdout.writeln('$failures check(s) failed.');
    exitCode = 1;
  }
}