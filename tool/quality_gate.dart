import 'dart:convert';
import 'dart:io';

import '../lib/content_quality_gate.dart';

import 'check_axes.dart';
import 'classify_ideas.dart';
import 'idea_decisions.dart';
import 'migration_state.dart';

/// A runnable quality gate checker.
///
///   dart run tool/quality_gate.dart [idea-id]
///
/// When given an idea ID, evaluates just that idea through the gate and prints
/// a structured report. When run with no arguments, evaluates all `keep`
/// ideas and prints a summary.
///
/// This is a thin wrapper around [QualityGate.evaluateIdea] that wires up
/// the tool's classification data. It is read-only — no files are modified.

void main(List<String> args) {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseFile(file.readAsStringSync()).ideas;
  final decisions = readIdeaDecisions('tool/idea_decisions.csv');

  final axisDecisions = <String, Map<String, Decision>>{};
  for (final axis in axes) {
    final path = axis.decisionsFile;
    axisDecisions[axis.name] =
        path == null ? {} : readDecisions(path, requireEvidence: axis.hasEvidence);
  }

  if (args.isNotEmpty) {
    final id = args.first;
    final idea = ideas.cast<Idea?>().firstWhere((i) => i?.id == id, orElse: () {
      stderr.writeln('Idea "$id" not found.');
      exitCode = 1;
      return null;
    });
    if (idea == null) return;
    final report = _evaluateIdea(idea, decisions, axisDecisions);
    _printReport(report);
    return;
  }

  // Evaluate all keep ideas.
  final reports = <GateReport>[];
  final failures = <GateReport>[];
  final needsReview = <GateReport>[];

  for (final idea in ideas) {
    final verdict = decisions[idea.id]?.verdict;
    if (verdict != IdeaVerdict.keep) continue;

    final report = _evaluateIdea(idea, decisions, axisDecisions);
    reports.add(report);

    if (report.isBlockedFromGeneration) {
      failures.add(report);
    } else if (!report.classification.isFullyApproved) {
      needsReview.add(report);
    }
  }

  stdout.writeln('QUALITY GATE REPORT');
  stdout.writeln('===================');
  stdout.writeln('');
  stdout.writeln('Total keep ideas evaluated: ${reports.length}');
  stdout.writeln('PASS  ${reports.where((r) => r.overall == GateVerdict.pass).length}');
  stdout.writeln('UNKNOWN ${reports.where((r) => r.overall == GateVerdict.unknown).length}');
  stdout.writeln('FAIL  ${reports.where((r) => r.overall == GateVerdict.fail).length}');
  stdout.writeln('');

  if (failures.isNotEmpty) {
    stdout.writeln('BLOCKED:');
    for (final r in failures) {
      stdout.writeln('  ${r.ideaId}: ${r.blockingReasons.join("; ")}');
    }
    stdout.writeln('');
  }

  if (needsReview.isNotEmpty) {
    stdout.writeln('NEEDS REVIEW (not blocked, but not fully approved):');
    for (final r in needsReview) {
      final unknownAxes = reports
          .where((rep) => rep.ideaId == r.ideaId)
          .expand((rep) => rep.checks.where((c) => c.isUnknown))
          .map((c) => '${c.name}: ${c.reason}');
      stdout.writeln('  ${r.ideaId}: ${unknownAxes.join("; ")}');
    }
    stdout.writeln('');
  }

  stdout.writeln('Nothing was written.');
}

GateReport _evaluateIdea(
  Idea idea,
  Map<String, IdeaDecision> decisions,
  Map<String, Map<String, Decision>> axisDecisions,
) {
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
    final report = QualityGate.evaluateIdea(
      ideaId: idea.id,
      title: idea.heading,
      classification: snapshot,
    );
    return report;
}

AxisResolution _migrationToResolution(MigrationState ms) {
  return AxisResolution.values
      .firstWhere((r) => r.name == ms.name, orElse: () => AxisResolution.approved);
}

void _printReport(GateReport report) {
  final encoder = JsonEncoder.withIndent('  ');
  stdout.writeln('ID: ${report.ideaId}');
  stdout.writeln('Title: ${report.title}');
  stdout.writeln('Archived: ${report.isArchived}');
  stdout.writeln('Blocked: ${report.isBlockedFromGeneration}');
  stdout.writeln('Needs filming: ${report.needsFilming}');
  stdout.writeln('');

  for (final dim in QualityDimension.values) {
    final checks = report.checksFor(dim);
    if (checks.isEmpty) continue;

    stdout.writeln('${dim.label}:');
    for (final c in checks) {
      stdout.writeln('  [${c.verdict.name.toUpperCase()}] ${c.name}');
      stdout.writeln('    ${c.reason}');
    }
    stdout.writeln('');
  }

  stdout.writeln('JSON:');
  stdout.writeln(encoder.convert(report.toJson()));
}
