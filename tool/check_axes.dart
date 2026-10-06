import 'dart:io';

import '../lib/content_axes.dart';
import '../lib/format_handbook.dart';
import 'classify_ideas.dart';
import 'migration_state.dart';

/// The authoritative view of axis coverage across all 57 ideas.
///
///   dart run tool/checkaxes.dart
///
/// Reads `content_ideas.md` plus every decisions file, and reports what is genuinely
/// resolved versus what still needs a human. This exists because `check_ideas.dart`
/// does not read the decisions files, so it kept reporting 57 missing pillars after
/// twelve had been decided. Two validators disagreeing about the same dataset is worse
/// than one incomplete validator.
///
/// ── What counts as resolved ──────────────────────────────────────────────────
//
// Three sources, in descending authority:
///
///   1. A human decision in a decisions file. Highest, and only `approved` is writable.
///   2. A legacy value already in `content_ideas.md` that maps mechanically.
///   3. Classifier inference. Never counted as resolved. It is shown separately as
///      `inferable`, because "the tool can guess this" and "this is decided" are
///      different facts.

class AxisSpec {
  final String name;
  final String axisLabel;
  final String? decisionsFile;

  /// Whether this axis carries an evidence column.
  final bool hasEvidence;

  /// Resolves a value already present in the idea, or null.
  final String? Function(Idea) fromSource;

  /// Whether a value is a legal member of this axis.
  final bool Function(String) isValid;

  const AxisSpec(this.name, this.axisLabel, this.decisionsFile,
      {this.hasEvidence = false,
      required this.fromSource,
      required this.isValid});
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

/// The registered axes, shared with `review_content.dart` so the
/// pre-install gate and this report resolve ideas identically.
final axes = <AxisSpec>[
  AxisSpec(
    'pillar', 'Pillar', 'tool/pillar_decisions.csv',
    hasEvidence: true,
    fromSource: (i) => ContentPillar.byLabel(i.g('Pillar'))?.label,
    isValid: (v) => ContentPillar.byLabel(v) != null,
  ),
  AxisSpec(
    'series', 'Series', null,
    fromSource: (i) => ContentSeries.fromLegacy(i.g('Series'))?.label,
    isValid: (v) => ContentSeries.byLabel(v) != null,
  ),
  AxisSpec(
    'contentType', 'Content Type', null,
    fromSource: (i) {
      final t = i.g('Best content type');
      if (t.isNotEmpty && ContentType.byLabel(t) != null) {
        return ContentType.byLabel(t)!.label;
      }
      final f = i.g('Format').toLowerCase();
      return _contentTypeNames[f];
    },
    isValid: (v) => ContentType.byLabel(v) != null,
  ),
  AxisSpec(
    'narrativeFormat', 'Narrative Format', 'tool/format_decisions.csv',
    fromSource: (i) {
      for (final field in ['Format', 'Content Format']) {
        final raw = i.g(field);
        if (raw.isEmpty) continue;
        if (_contentTypeNames.containsKey(raw.toLowerCase())) continue;
        final s = validateNarrativeFormat(raw);
        if (s != null) return s.name;
      }
      return null;
    },
    isValid: (v) => validateNarrativeFormat(v) != null,
  ),
  AxisSpec(
    'productionMethod', 'Production Method', null,
    fromSource: (i) {
      final raw = i.g('Production').toLowerCase();
      const map = {
        'character': 'Character images',
        'image': 'Character images',
        'static': 'Carousel',
        'carousel': 'Carousel',
        'video': 'Real-life video',
        'real-life video': 'Real-life video',
        'image slideshow': 'Image slideshow',
        'text': 'Text-based',
        'text-based': 'Text-based',
        'mixed': 'Mixed',
      };
      final m = map[raw];
      if (m != null) return m;
      final t = i.g('Best content type').toLowerCase();
      if (t == 'carousel') return 'Carousel';
      if (t == 'trial reel') return 'Image slideshow';
      if (t == 'image reel' ||
          t == 'image slideshow reel' ||
          t == 'story reel') {
        return 'Character images';
      }
      return null;
    },
    isValid: (v) => ProductionMethod.byLabel(v) != null,
  ),
  AxisSpec(
    'goal', 'Goal', null,
    fromSource: (i) {
      final raw = i.g('Goal');
      if (raw.contains('+') || raw.contains('/')) return null;
      return (ContentGoal.fromLegacy(raw) ?? ContentGoal.byLabel(raw))?.label;
    },
    isValid: (v) => ContentGoal.byLabel(v) != null,
  ),
  AxisSpec(
    'status', 'Status', null,
    fromSource: (i) {
      final raw = i.g('Status');
      if (raw.isEmpty) return 'idea';
      return IdeaStatus.fromLegacy(raw).id;
    },
    isValid: (v) => IdeaStatus.byId(v) != null,
  ),
];

void main() {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseFile(file.readAsStringSync()).ideas;

  // Decisions, keyed by axis name. Loaded once, not per idea.
  final decisions = <String, Map<String, Decision>>{};
  for (final a in axes) {
    if (a.decisionsFile == null) {
      decisions[a.name] = {};
      continue;
    }
    // Copied into a local so the nullable public field can be promoted.
    final path = a.decisionsFile!;
    decisions[a.name] = readDecisions(path, requireEvidence: a.hasEvidence);
  }

  stdout.writeln('Fun Learning With Palak, axis coverage');
  stdout.writeln('=======================================');
  stdout.writeln('');
  stdout.writeln('Ideas: ${ideas.length}   unique ids: '
      '${ideas.map((i) => i.id).toSet().length}');
  stdout.writeln('');

  var anyBlocked = false;
  var allResolved = true;

  for (final axis in axes) {
    final d = decisions[axis.name]!;
    var fromSource = 0, approved = 0, suggested = 0;
    var needsReview = 0, invalid = 0, archive = 0;
    final open = <String>[];

    for (final idea in ideas) {
      final decision = d[idea.id];
      if (decision != null) {
        switch (decision.state) {
          case MigrationState.approved:
            approved++;
          case MigrationState.suggested:
            suggested++;
          case MigrationState.needsReview:
            needsReview++;
            open.add('${idea.id}  needsReview  ${decision.note}');
          case MigrationState.invalid:
            invalid++;
            open.add('${idea.id}  invalid');
          case MigrationState.archiveCandidate:
            archive++;
        }
        continue;
      }
      if (axis.fromSource(idea) != null) {
        fromSource++;
        continue;
      }
      open.add(idea.id);
    }

    final settled = fromSource + approved + suggested + archive;
    final outstanding = open.length;
    if (outstanding > 0) allResolved = false;
    if (needsReview > 0 || invalid > 0) anyBlocked = true;

    stdout.writeln(axis.axisLabel);
    stdout.writeln('  in source            : $fromSource');
    stdout.writeln('  approved (writable)   : $approved');
    stdout.writeln('  suggested (not yet)  : $suggested');
    if (archive > 0) stdout.writeln('  archive_candidate    : $archive');
    if (needsReview > 0) stdout.writeln('  needsReview (blocked): $needsReview');
    if (invalid > 0) stdout.writeln('  invalid (blocked)    : $invalid');
    stdout.writeln('  OPEN                 : $outstanding');
    if (outstanding <= 12) {
      for (final o in open) {
        stdout.writeln('      $o');
      }
    } else {
      for (final o in open.take(12)) {
        stdout.writeln('      $o');
      }
      stdout.writeln('      ... and ${outstanding - 12} more');
    }
    stdout.writeln('');
  }

  stdout.writeln('------------------------------------------------------------');
  if (allResolved) {
    stdout.writeln('All 57 ideas carry a value on every axis.');
  } else {
    stdout.writeln('Not yet complete. sync_ideas.dart must not become '
        'authoritative.');
  }
  if (anyBlocked) {
    stdout.writeln('Some axes are explicitly blocked pending a human decision.');
  }
  stdout.writeln('');
  stdout.writeln('Nothing was written. content_ideas.md is untouched.');
}