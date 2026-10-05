import 'dart:io';

import '../lib/content_axes.dart';
import 'classify_ideas.dart';
import 'migration_state.dart';

/// Emits proposals for every axis value that is not yet settled, in one reviewable file.
///
///   dart run tool/propose_axes.dart              dry run
///   dart run tool/propose_axes.dart --csv        writes tool/axis_proposals.csv
///
/// ── Why one file ─────────────────────────────────────────────────────────────
///
/// Settling the remaining axes piecemeal produced five separate review artefacts and
/// two validators that disagreed about the same dataset. One file means approval is a
/// single read, and it makes the remaining volume honest: after the format and pillar
/// rounds, 45 pillars are still unapproved because an inferred value is not a decision.
///
/// ── Nothing here writes ──────────────────────────────────────────────────────
//
// Inference is never counted as resolved. `check_axes.dart` reports a value as settled
/// only when it came from the source file or from a human decision.

class Open {
  final Idea idea;
  final String axis;
  final String proposed;
  final String confidence;
  final String reason;

  Open(this.idea, this.axis, this.proposed, this.confidence, this.reason);
}

const _contentTypeNames = {
  'reel': 'Reel',
  'carousel': 'Carousel',
  'trial reel': 'Trial Reel',
  'image reel': 'Image Slideshow Reel',
  'image slideshow reel': 'Image Slideshow Reel',
  'story reel': 'Image Slideshow Reel',
  'static image': 'Static Image',
};

void main(List<String> argv) {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseFile(file.readAsStringSync()).ideas;
  final pillars = readDecisions('tool/pillar_decisions.csv', requireEvidence: true);
  final formats = readDecisions('tool/format_decisions.csv', requireEvidence: false);

  final open = <Open>[];

  for (final idea in ideas) {
    final c = Classifier(idea);

    // -- Pillar
    if (!pillars.containsKey(idea.id)) {
      final p = c.classifyPillar();
      if (p.value.isNotEmpty) {
        open.add(Open(idea, 'pillar', p.value, p.confidence.name, p.reason));
      }
    }

    // -- Series
    final series = ContentSeries.fromLegacy(idea.g('Series'));
    if (series == null) {
      final p = c.classifySeries();
      if (p.value.isNotEmpty) {
        open.add(Open(idea, 'series', p.value, p.confidence.name, p.reason));
      }
    }

    // -- Content Type
    final rawType = idea.g('Best content type');
    final hasType = (rawType.isNotEmpty && ContentType.byLabel(rawType) != null) ||
        _contentTypeNames.containsKey(idea.g('Format').toLowerCase());
    if (!hasType) {
      final p = c.classifyContentType();
      if (p.value.isNotEmpty) {
        open.add(Open(idea, 'contentType', p.value, p.confidence.name, p.reason));
      }
    }

    // -- Narrative Format. Already handled by format_decisions.csv, so skipped here
    // to avoid producing a second competing proposal for the same field.

    // -- Production Method
    final p2 = c.classifyProduction();
    if (p2.value.isEmpty) {
      // The classifier only proposes a production when the content type pins it.
      // Report the content type so a human can decide without cross-referencing.
      open.add(Open(idea, 'productionMethod', '', 'low',
          '${p2.reason}; content type is ${c.classifyContentType().value}'));
    }

    // -- Goal
    final p3 = c.classifyGoal();
    if (p3.value.isEmpty) {
      open.add(Open(idea, 'goal', '', 'low', p3.reason));
    }
  }

  // -- Report
  var high = 0, medium = 0, low = 0;
  final byAxis = <String, int>{};
  for (final o in open) {
    byAxis[o.axis] = (byAxis[o.axis] ?? 0) + 1;
    if (o.proposed.isEmpty) {
      low++;
    } else {
      switch (o.confidence) {
        case 'high':
          high++;
        case 'medium':
          medium++;
        default:
          low++;
      }
    }
  }

  stdout.writeln('Open axis values needing a decision');
  stdout.writeln('===================================');
  stdout.writeln('');
  for (final e in byAxis.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
    stdout.writeln('  ${e.key.padRight(18)} ${e.value}');
  }
  stdout.writeln('');
  stdout.writeln('Proposals with a value : '
      '${open.where((o) => o.proposed.isNotEmpty).length}');
  stdout.writeln('  high                  : $high');
  stdout.writeln('  medium                : $medium');
  stdout.writeln('Blocked, no value      : $low');
  stdout.writeln('');
  stdout.writeln('Nothing was written. content_ideas.md is untouched.');
  stdout.writeln('');

  if (argv.contains('--csv')) {
    final csv = StringBuffer()
      ..writeln('idea_id,axis,proposed,confidence,reason');
    for (final o in open) {
      csv.writeln([
        o.idea.id,
        o.axis,
        '"${o.proposed.replaceAll('"', "'")}"',
        o.confidence,
        '"${o.reason.replaceAll('"', "'")}"',
      ].join(','));
    }
    File('tool/axis_proposals.csv').writeAsStringSync(csv.toString());
    stdout.writeln('Wrote tool/axis_proposals.csv');
  }
}