// Validates every idea in content_ideas.md against the frozen axes in
// lib/content_axes.dart, and classifies what still needs a human decision.
//
//   dart run tool/check_ideas.dart
//
// Reports rather than throws. The point of migrating 59 ideas by hand is seeing the
// complete list of decisions a person still has to make, so a validator that stops at
// the first failure is worse than no validator here.
//
// Two conventions in the source file this parser has to handle, both discovered the
// hard way:
//
//   1. Two bold spellings. `content_ideas.md` writes `- **id:** value` with the colon
//      INSIDE the bold. `content_formats.md` writes `- **ID**: value` with it outside.
//      Matching only one yields zero fields from a file that plainly contains them.
//   2. Two field shapes. Older ideas put one field per line; newer ones pack them as
//      `- **Series:** x | **Format:** y | **Goal:** z`. Only the first fragment of a
//      packed line carries the leading `-`, so the dash has to be optional.

import 'dart:io';

import '../lib/content_axes.dart';
import '../lib/format_handbook.dart';

// ============================================================================
// PARSING
// ============================================================================

/// A metadata field in either bold convention.
final _field = RegExp(
  r'^\s*(?:-\s*)?(?:\*\*(.+?):\*\*|\*\*(.+?)\*\*\s*:)\s*(.*)$',
);

class Idea {
  final String heading;
  final Map<String, String> fields = {};
  Idea(this.heading);

  String get id {
    final raw = fields['id'] ?? '';
    return raw.replaceAll('`', '').trim();
  }

  String? get key {
    for (final k in ['id', 'ID', 'Id']) {
      if (fields.containsKey(k)) return k;
    }
    return null;
  }

  String get name => (key == null) ? heading : name_;

  /// `name` is a reserved word on Object.
  String get name_ => fields[key!] ?? heading;
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

    for (final part in line.split(RegExp(r'\s*\|\s*'))) {
      final m = _field.firstMatch(part);
      if (m == null) continue;
      final key = (m.group(1) ?? m.group(2) ?? '').trim();
      if (key.isEmpty) continue;
      current!.fields[key] = m.group(3)!.trim();
    }
  }
  if (current != null) ideas.add(current);
  return ideas;
}

// ============================================================================
// CLASSIFICATION
//;

/// What still needs a human decision.
enum Verdict {
  /// Every axis resolved with a confident mapping.
  complete,

  /// Resolvable by a documented mapping rule, worth a glance.
  autoMapped,

  /// No correct automatic answer. A person decides.
  needsReview,

  /// Cannot be repaired by choosing a different value.
  invalid,
}

class Result {
  final Idea idea;
  final Verdict verdict;
  final Map<String, String> proposed;
  final List<String> reasons;

  Result(this.idea, this.verdict, this.proposed, this.reasons);

  String get id => idea.id.isEmpty ? '(no id) ${idea.heading}' : idea.id;
}

// Content types the old `Format` field was really holding, in the app's own spelling.
const _contentTypeNames = {
  'reel': 'Reel',
  'carousel': 'Carousel',
  'trial reel': 'Trial Reel',
  'image reel': 'Image Slideshow Reel',
  'image slideshow reel': 'Image Slideshow Reel',
  'static image': 'Static Image',
  'story': 'Story',
  'story reel': 'Image Slideshow Reel',
};

/// Old series ids with no correct target in the new seven. Reported, never guessed.
const _unmappableSeries = {
  'learning-through-play': 'was a pillar, not a series',
  'little-stories': 'the retired "Little Stories, Big Lessons" name',
  'cuty-lessons': 'Cuty is a character, not a series',
  'the-casts': 'an audience-voting series; both its ideas optimise for comments',
};

/// Old goals with no correct target. `Engagement` and `Community` sat on audience
/// participation posts; guessing `comments` would change what they optimise for.
const _unmappableGoals = {
  'engagement': 'could be comments, follows or relatability',
  'community': 'could be comments or authority',
};

Result classify(Idea idea) {
  final reasons = <String>[];
  final proposed = <String, String>{};
  var verdict = Verdict.complete;

  void review(String axis, String message) {
    reasons.add('$axis: $message');
    if (verdict == Verdict.complete || verdict == Verdict.autoMapped) {
      verdict = Verdict.needsReview;
    }
  }

  void invalid(String axis, String message) {
    reasons.add('$axis: $message');
    verdict = Verdict.invalid;
  }

  String g(String k) => idea.fields[k] ?? '';

  // -- Series
  final rawSeries = g('Series');
  final series = ContentSeries.fromLegacy(rawSeries);
  if (series != null) {
    proposed['series'] = series.label;
    if (series.label.toLowerCase() != rawSeries.trim().toLowerCase()) {
      verdict = Verdict.autoMapped;
      reasons.add('series: "$rawSeries" -> ${series.label}');
    }
  } else if (rawSeries.isEmpty) {
    review('series', 'missing');
  } else {
    invalid('series',
        '"$rawSeries" has no target (${_unmappableSeries[rawSeries.trim().toLowerCase()] ?? 'not a known legacy id'})');
  }

  // -- Pillar. Never guessed from the topic text: inferring a pillar from a sentence
  // is how 59 ideas quietly acquire 59 wrong pillars.
  if (g('Pillar').isEmpty) {
    review('pillar', 'missing, and not inferable from the topic');
  }

  // -- Content Type, which lived inside `Format` on 33 ideas and in
  // `Best content type` on 24.
  final rawFormat = g('Format');
  final rawType = g('Best content type');
  String? contentType;
  if (rawType.isNotEmpty) {
    contentType = ContentType.byLabel(rawType)?.label;
  } else if (_contentTypeNames.containsKey(rawFormat.trim().toLowerCase())) {
    contentType = _contentTypeNames[rawFormat.trim().toLowerCase()];
  }
  if (contentType != null) {
    proposed['contentType'] = contentType;
  } else if (rawFormat.isEmpty && rawType.isEmpty) {
    review('contentType', 'missing');
  }

  // -- Narrative Format. The remainder of `Format`, when it is not a content type.
  if (!(_contentTypeNames.containsKey(rawFormat.trim().toLowerCase()))) {
    final spec = validateNarrativeFormat(rawFormat);
    if (spec != null) {
      proposed['narrativeFormat'] = spec.name;
    } else if (rawFormat.trim().isEmpty) {
      review('narrativeFormat', 'missing');
    } else {
      invalid('narrativeFormat',
          '"$rawFormat" is not one of the ${FormatLibrary.all.length} registered formats');
    }
  }

  // -- Production Method
  if (g('Production').isEmpty) {
    review('productionMethod', 'missing');
  }

  // -- Goal
  final rawGoal = g('Goal');
  if (rawGoal.trim().isEmpty) {
    review('goal', 'missing');
  } else if (rawGoal.contains('+') || rawGoal.contains('/')) {
    // "Reach + Shares" was a compound goal on 4 ideas. One idea, one goal, so this
    // has to be split by a person: the format's best-goals list scores one goal.
    invalid('goal', '"$rawGoal" is two goals; one idea optimises for one');
  } else if (_unmappableGoals.containsKey(rawGoal.trim().toLowerCase())) {
    invalid('goal',
        '"$rawGoal" has no target (${_unmappableGoals[rawGoal.trim().toLowerCase()]})');
  } else if (ContentGoal.fromLegacy(rawGoal) == null &&
      ContentGoal.byLabel(rawGoal) == null) {
    invalid('goal', '"$rawGoal" is not a known goal');
  }

  // -- Status
  final rawStatus = g('Status');
  if (rawStatus.trim().isEmpty) {
    review('status', 'missing');
  } else if (IdeaStatus.byId(rawStatus) == null) {
    proposed['status'] = IdeaStatus.fromLegacy(rawStatus).id;
    verdict = verdict == Verdict.complete ? Verdict.autoMapped : verdict;
    reasons.add('status: "$rawStatus" -> ${IdeaStatus.fromLegacy(rawStatus).id}');
  }

  return Result(idea, verdict, proposed, reasons);
}

// ============================================================================

void main() {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final allSections = parseIdeas(file.readAsStringSync());

  // The document's own prose also uses `###` headings, so heading count overstates the
  // idea count. A real idea is a section carrying an id; the rest is documentation and
  // is reported separately rather than counted as 59 broken ideas.
  final ideas = allSections.where((i) => i.id.isNotEmpty).toList();
  final docSections =
      allSections.where((i) => i.id.isEmpty).map((i) => i.heading).toList();

  final results = ideas.map(classify).toList();

  // Unique ids, checked across the whole set rather than per idea.
  final seen = <String, int>{};
  for (var i = 0; i < results.length; i++) {
    final id = results[i].idea.id;
    if (id.isEmpty) continue;
    seen[id] = (seen[id] ?? 0) + 1;
  }
  final dupes = seen.entries.where((e) => e.value > 1);

  final counts = <Verdict, int>{};
  for (final r in results) {
    counts[r.verdict] = (counts[r.verdict] ?? 0) + 1;
  }

  stdout.writeln('Fun Learning With Palak, idea validation');
  stdout.writeln('============================================');
  stdout.writeln('');
  stdout.writeln('Sections in file    : ${allSections.length}');
  stdout.writeln('  of which prose    : ${docSections.length}  '
      '(### headings in the document, not ideas)');
  stdout.writeln('Ideas               : ${results.length}');
  stdout.writeln('Unique ids          : ${seen.length}');
  stdout.writeln('Duplicate ids       : ${dupes.length}');
  stdout.writeln('');
  stdout.writeln('complete            : ${counts[Verdict.complete] ?? 0}');
  stdout.writeln('auto-mapped         : ${counts[Verdict.autoMapped] ?? 0}');
  stdout.writeln('needs review        : ${counts[Verdict.needsReview] ?? 0}');
  stdout.writeln('invalid             : ${counts[Verdict.invalid] ?? 0}');
  stdout.writeln('');

  if (dupes.isNotEmpty) {
    stdout.writeln('DUPLICATE IDS');
    for (final d in dupes) {
      stdout.writeln('  ${d.key}  x${d.value}');
    }
    stdout.writeln('');
  }

  final needsWork =
      results.where((r) => r.verdict != Verdict.complete).toList();
  if (needsWork.isNotEmpty) {
    stdout.writeln('NEEDS A HUMAN DECISION (${needsWork.length})');
    stdout.writeln('');
    for (final r in needsWork) {
      stdout.writeln('[${r.verdict.name}] ${r.id}');
      for (final reason in r.reasons) {
        stdout.writeln('    $reason');
      }
      if (r.proposed.isNotEmpty) {
        stdout.writeln(
            '    proposed: ${r.proposed.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
      }
      stdout.writeln('');
    }
  }

  final clean = results.where((r) => r.verdict == Verdict.complete).length;
  stdout.writeln('------------------------------------------------------------');
  stdout.writeln('$clean of ${results.length} ideas are ready to migrate with no '
      'human input.');
  stdout.writeln('');
  stdout.writeln('Nothing was written. content_ideas.md is untouched.');

  if (docSections.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Prose sections skipped (not ideas):');
    for (final h in docSections) {
      stdout.writeln('  $h');
    }
  }
}