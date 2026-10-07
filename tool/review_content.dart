import 'dart:io';

import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/format_handbook.dart';

import 'check_axes.dart';
import 'classify_ideas.dart';
import 'idea_decisions.dart';
import 'migration_state.dart';
import 'reach_mechanics.dart';

/// The pre-install gate.
///
///   dart run tool/review_content.dart
///
/// Answers one question: is the library clean enough to sync into
/// the app? The phone app should never be the place where a messy
/// library is discovered — the sheet is where we curate, the app
/// is where we produce, Instagram is where we test.
///
/// ── What blocks ─────────────────────────────────────────────────
///
/// 1. An idea with no Decision. The human has not said what the
///    idea is, so it can be neither in the sync set nor excluded
///    from it.
/// 2. A `keep` idea with an unresolved axis. Resolved means stated
///    in `content_ideas.md` or approved in a decisions file. A
///    suggested value is a proposal, not a decision, and does not
///    resolve.
/// 3. A `keep` idea whose share trigger is UNKNOWN. "Would a
///    specific parent send this to another" is the question the
///    library exists to answer; an unanswered one is a curation
///    gap, not a failure.
/// 4. Two `keep` ideas with the same title — a possible series
///    collision for a human to look at.
///
/// ── What is reported but never blocks ───────────────────────────
///
/// * `open_loop` UNKNOWN — worth filling, not a gate.
/// * Production-incompatible ideas — a filming job or reference
///   content, not a bad idea (CONTENT_MODEL.md §5).
///
/// ── Nothing is written ──────────────────────────────────────────
///
/// Read-only. `content_ideas.md` and every decisions file are
/// untouched. Exits non-zero when the library is not ready, so
/// the gate can guard a build.

/// Maps a [MigrationState] to the equivalent [AxisResolution].
AxisResolution _migrationToResolution(MigrationState ms) {
  return AxisResolution.values
      .firstWhere((r) => r.name == ms.name, orElse: () => AxisResolution.approved);
}

void main() {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseFile(file.readAsStringSync()).ideas;
  final decisions = readIdeaDecisions('tool/idea_decisions.csv');
  if (exitCode != 0) return;

  // Axis decisions, for the approved-state lookup. A suggested
  // value is a proposal and does not resolve an axis here.
  final axisDecisions = <String, Map<String, Decision>>{};
  for (final axis in axes) {
    final path = axis.decisionsFile;
    axisDecisions[axis.name] =
        path == null ? {} : readDecisions(path, requireEvidence: axis.hasEvidence);
  }
  if (exitCode != 0) return;

  final shareTrigger = mechanics.firstWhere((m) => m.name == 'share_trigger');
  final openLoop = mechanics.firstWhere((m) => m.name == 'open_loop');
  final saveTrigger = mechanics.firstWhere((m) => m.name == 'save_trigger');

  var keep = 0, rework = 0, archive = 0, delete = 0, undecided = 0;
  final undecidedIds = <String>[];
  final unresolved = <String, List<String>>{};
  final noShareTrigger = <String>[];
  final openLoopUnknown = <String>[];
  final needsFilming = <String>[];
  final referenceContent = <String>[];
  final keepTitles = <String, List<String>>{};

  for (final idea in ideas) {
    final verdict = decisions[idea.id]?.verdict;
    switch (verdict) {
      case IdeaVerdict.keep:
        keep++;
      case IdeaVerdict.rework:
        rework++;
      case IdeaVerdict.archive:
        archive++;
      case IdeaVerdict.delete:
        delete++;
      case null:
        undecided++;
        undecidedIds.add(idea.id);
    }

    // Only `keep` ideas must be fully curated: they are the sync
    // set. Everything else is excluded by its own decision.
    if (verdict != IdeaVerdict.keep) continue;

    final title = idea.heading.trim().toLowerCase();
    keepTitles.putIfAbsent(title, () => []).add(idea.id);

    // Check each axis for resolution.
    for (final axis in axes) {
      final d = axisDecisions[axis.name]![idea.id];
      final resolved =
          axis.fromSource(idea) != null || d?.state == MigrationState.approved;
      if (!resolved) {
        unresolved.putIfAbsent(axis.axisLabel, () => []).add(idea.id);
      }
    }

    // Build a classification snapshot for the quality gate.
    final axisStates = <String, AxisResolution?>{};
    for (final axis in axes) {
      final d = axisDecisions[axis.name]?[idea.id];
      final fromSource = axis.fromSource(idea);
      if (d == null && fromSource == null) {
        axisStates[axis.axisLabel] = null;
      } else if (d != null) {
        axisStates[axis.axisLabel] = _migrationToResolution(d.state);
      } else {
        axisStates[axis.axisLabel] = AxisResolution.approved;
      }
    }

    final snapshot = ClassificationSnapshot(axisStates: axisStates);

    // Run through the quality gate for a structured verdict.
    final gateReport = QualityGate.evaluateIdea(
      ideaId: idea.id,
      title: idea.heading,
      classification: snapshot,
    );

    if (shareTrigger.judge(idea) == 'unknown') noShareTrigger.add(idea.id);
    if (openLoop.judge(idea) == 'unknown') openLoopUnknown.add(idea.id);
    if (saveTrigger.judge(idea) == 'pass') referenceContent.add(idea.id);

    final blockedBy = mechanics
        .where((m) =>
            m.judge(idea) == 'fail' && productionConstraints.contains(m.name))
        .map((m) => m.name)
        .toList();
    if (blockedBy.isNotEmpty) {
      needsFilming.add('${idea.id} (${blockedBy.join(', ')})');
    }
  }

  final collisions = keepTitles.entries
      .where((e) => e.value.length > 1)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  stdout.writeln('CONTENT LIBRARY REVIEW');
  stdout.writeln('======================');
  stdout.writeln('');
  stdout.writeln('Total ideas: ${ideas.length}');
  stdout.writeln('');
  stdout.writeln('KEEP      ${keep.toString().padLeft(3)}');
  stdout.writeln('REWORK    ${rework.toString().padLeft(3)}');
  stdout.writeln('ARCHIVE   ${archive.toString().padLeft(3)}');
  stdout.writeln('DELETE    ${delete.toString().padLeft(3)}');
  stdout.writeln('UNDECIDED ${undecided.toString().padLeft(3)}');
  stdout.writeln('');

  final blockers = <String>[
    if (undecided > 0)
      '$undecided idea${undecided == 1 ? ' has' : 's have'} no Decision',
    for (final e in unresolved.entries)
      '${e.value.length} keep idea${e.value.length == 1 ? '' : 's'} missing ${e.key}',
    if (noShareTrigger.isNotEmpty)
      '${noShareTrigger.length} keep idea${noShareTrigger.length == 1 ? '' : 's'} '
      'with UNKNOWN share trigger',
    if (collisions.isNotEmpty)
      '${collisions.length} possible series collision${collisions.length == 1 ? '' : 's'} '
      '(duplicate titles)',
  ];

  stdout.writeln('BLOCKING:');
  if (blockers.isEmpty) {
    stdout.writeln('  none');
  } else {
    for (final b in blockers) {
      stdout.writeln('  - $b');
    }
  }
  stdout.writeln('');

  stdout.writeln('Reported, not blocking:');
  stdout.writeln('  open_loop UNKNOWN      : ${openLoopUnknown.length}');
  stdout.writeln('  reference content      : ${referenceContent.length} '
      '(Saves and Authority, not reach candidates)');
  stdout.writeln('  production-incompatible: ${needsFilming.length} '
      '(filming jobs, not bad ideas)');
  stdout.writeln('');

  if (undecidedIds.isNotEmpty && undecidedIds.length <= 12) {
    stdout.writeln('Undecided: ${undecidedIds.join(', ')}');
    stdout.writeln('');
  }
  if (collisions.isNotEmpty) {
    stdout.writeln('Duplicate titles:');
    for (final c in collisions) {
      stdout.writeln('  "${c.key}"  ${c.value.join(', ')}');
    }
    stdout.writeln('');
  }

  final ready = blockers.isEmpty;
  stdout.writeln('Ready to sync: ${ready ? 'YES' : 'NO'}');
  if (!ready) {
    stdout.writeln('');
    stdout.writeln('Fill tool/idea_decisions.csv and resolve the blockers '
        'above.');
    stdout.writeln('Full axis coverage: dart run tool/check_axes.dart');
    exitCode = 1;
  }
  stdout.writeln('');
  stdout.writeln('Nothing was written. content_ideas.md is untouched.');
}
