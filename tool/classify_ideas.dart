// Classifies every idea in content_ideas.md against the frozen axes.
//
//   dart run tool/classify_ideas.dart              dry run, writes nothing
//   dart run tool/classify_ideas.dart --report     writes the review report
//   dart run tool/classify_ideas.dart --apply      writes content_ideas.md
//
// ── The rule this enforces ───────────────────────────────────────────────────
//
// Nothing is silently invented. Every proposal carries a confidence and a reason,
// and anything short of HIGH is listed for a human. Getting 57/57 "complete" by
// guessing would be worse than 20/57: a wrong pillar is invisible later, it just
// quietly misfiles the performance data of a post that was actually good.
//
// Confidence is deliberately coarse. An idea either has one defensible answer from
// its own text, or it does not, and pretending otherwise is what produced the
// original `Format` overload.
//
// ── Why the classifier reads the idea's own words ────────────────────────────
//
// The axis values are inferred from `Topic`, `Lesson`, `Audience Problem`,
// `Content Format` and `Notes` — never invented from the title alone. Two ideas with
// near-identical titles can sit in different pillars, and a title-derived guess is
// exactly the silent-invention case above.
//
// ── Recoverability ───────────────────────────────────────────────────────────
//
// `--apply` refuses to run without a backup alongside, and writes the backup
// unconditionally first. `content_ideas.md` is the only hand-authored copy of 57
// ideas; losing it loses the library.

import 'dart:io';

import '../lib/content_axes.dart';
import '../lib/format_handbook.dart';

// ============================================================================
// PARSING
// ============================================================================

/// A metadata field in either bold convention. `content_ideas.md` writes
/// `- **id:** value` with the colon inside the bold; `content_formats.md` writes
/// `- **ID**: value`. Only matching one yields zero fields from a file that plainly
/// contains them, which looks exactly like a data bug.
final _field = RegExp(
  r'^\s*(?:-\s*)?(?:\*\*(.+?):\*\*|\*\*(.+?)\*\*\s*:)\s*(.*)$',
);

class Idea {
  final String heading;
  final int lineStart;
  final Map<String, String> fields = {};
  Idea(this.heading, this.lineStart);

  String get id {
    final raw = fields['id'] ?? '';
    return raw.replaceAll('`', '').trim();
  }

  String g(String k) => (fields[k] ?? '').replaceAll('`', '').trim();

  /// All searchable prose for one idea, lowercased.
  String get body => [
        g('Topic'),
        g('Lesson'),
        g('Problem'),
        g('Audience Problem'),
        g('Content Format'),
        g('Notes'),
        heading,
      ].join(' ').toLowerCase();
}

class ParsedFile {
  final List<Idea> ideas;
  final List<String> lines;
  final List<String> proseHeadings;

  ParsedFile(this.ideas, this.lines, this.proseHeadings);
}

ParsedFile parseFile(String markdown) {
  final lines = markdown.split('\n');
  final ideas = <Idea>[];
  final prose = <String>[];
  Idea? current;
  var inFence = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].replaceAll('\r', '').trimRight();

    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    if (line.startsWith('### ')) {
      if (current != null) ideas.add(current);
      current = Idea(line.substring(4).trim(), i);
      continue;
    }
    if (current == null) continue;

    // Handles both field shapes: one per line, and the packed
    // "- **Series:** x | **Format:** y | **Goal:** z" used by newer entries. Only the
    // first fragment carries the leading dash, so it has to be optional.
    for (final part in line.split(RegExp(r'\s*\|\s*'))) {
      final m = _field.firstMatch(part);
      if (m == null) continue;
      final key = (m.group(1) ?? m.group(2) ?? '').trim();
      if (key.isEmpty) continue;
      current!.fields[key] = m.group(3)!.trim();
    }
  }
  if (current != null) ideas.add(current);

  // The document's own prose also uses `###` headings. A real idea carries an id.
  final real = ideas.where((i) => i.id.isNotEmpty).toList();
  prose.addAll(ideas.where((i) => i.id.isEmpty).map((i) => i.heading));
  return ParsedFile(real, lines, prose);
}

// ============================================================================
// CONFIDENCE
// ============================================================================

enum Confidence {
  /// Exactly one defensible answer, from the idea's own words.
  high,

  /// A default applied because nothing in the data contradicted it. Legitimate but
  /// worth a glance.
  medium,

  /// Genuinely ambiguous. A human decides.
  low,
}

/// One proposed axis value.
class Proposal {
  final String axis;
  final String value;
  final Confidence confidence;
  final String reason;

  Proposal(this.axis, this.value, this.confidence, this.reason);

  @override
  String toString() => '$axis: $value  [${confidence.name}]  $reason';
}

// ============================================================================
// CLASSIFICATION
// ============================================================================

/// Pillar signals, keyed to the axis label.
///
/// Matched against the idea's prose, not its title. Every keyword is a phrase a
/// parent would actually use, chosen so the signal points at the outcome rather than
/// the container: "sorting" is THINK whether it is delivered as a Reel or a Carousel.
const _pillarSignals = <String, List<String>>{
  'DO': [
    // Independence and practical life skills.
    'brush', 'shoes', 'wear', 'dress', 'eat', 'food', 'khana', 'clean', 'bath',
    'tidy', 'put away', 'independen', 'refus', 'no ', 'kart', 'time', 'thoda',
    '20 min', 'minute', 'khilaye', 'bartan', 'routine',
  ],
  'TALK': [
    // Language and parent-child conversation.
    'say', 'words', 'talk', 'question', 'conversation', 'talk with', 'batao',
    'instead of no', 'script', 'phrases', 'language', 'bolna', 'bhasha',
  ],
  'THINK': [
    // Problem solving and reasoning.
    'which', 'odd one', 'pattern', 'match', 'sort', 'sorting', 'puzzle', 'solve',
    'figure', 'clue', 'detective', 'find the', 'hidden', 'count', 'math', 'logic',
    'reason', 'try', 'attempt', 'think',
  ],
  'DISCOVER': [
    // Exploration of the everyday world.
    'colour', 'color', 'texture', 'sound', 'nature', 'observe', 'explor', 'discover',
    'experiment', 'what happens', 'watch', 'look',
  ],
  'PLAY': [
    // Undirected play and keeping a child busy.
    'play', 'busy', 'bore', 'bored', 'entertain', 'fun', 'enjoy', 'together',
    'chawal', 'dal', 'water', 'pour', 'spoon', 'sorting tray', 'texture tray',
  ],
};

/// Series signals for the three legacy ids with no mechanical mapping.
const _seriesSignals = <String, List<String>>{
  'canYourChildFigureItOut': [
    'odd one', 'detective', 'figure', 'clue', 'hidden', 'pattern', 'puzzle',
    'which one', 'mission', 'treasure', 'rescue', 'challenge', 'match',
  ],
  'lifeWithRiaRio': [
    'rio', 'ria ', 'sibling', 'fight', 'share', 'both', 'together',
  ],
  'talkWithYourChild': [
    'ask', 'question', 'talk', 'conversation', 'words to say',
  ],
};

/// Production methods implied by an existing production token.
const _productionFromLegacy = {
  'character': 'Character images',
  'image': 'Character images',
  'image reel': 'Character images',
  'static': 'Carousel',
  'carousel': 'Carousel',
  'video': 'Real-life video',
  'real-life video': 'Real-life video',
  'image slideshow': 'Image slideshow',
  'text': 'Text-based',
  'text-based': 'Text-based',
  'mixed': 'Mixed',
};

class Classifier {
  final Idea idea;

  Classifier(this.idea);

  String _body() => idea.body;

  bool _has(List<String> needles) => needles.any(_body().contains);

  Proposal classifyPillar() {
    if (idea.g('Pillar').isNotEmpty) {
      return Proposal('Pillar', idea.g('Pillar'), Confidence.high,
          'already stated in the idea');
    }

    // Counts matches per pillar. A clear winner is a real signal; a tie is not,
    // because it means the prose genuinely does not prioritise one outcome.
    final scores = <String, int>{};
    for (final entry in _pillarSignals.entries) {
      var n = 0;
      for (final k in entry.value) {
        if (_body().contains(k)) n++;
      }
      if (n > 0) scores[entry.key] = n;
    }
    if (scores.isEmpty) {
      return Proposal('Pillar', '', Confidence.low,
          'no pillar signal in the topic, lesson or problem text');
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final topKey = top.key;
    final topCount = top.value;

    if (sorted.length > 1 && sorted[1].value == topCount) {
      return Proposal(
          'Pillar', '', Confidence.low,
          '${sorted.take(2).map((e) => e.key).join(' and ')} tie at '
              '$topCount signals each');
    }
    // One clear signal, or a clear winner by margin.
    if (sorted.length == 1) {
      return Proposal('Pillar', topKey, Confidence.high,
          '$topCount signal${topCount == 1 ? '' : 's'} for $topKey, '
          'no other pillar matched');
    }
    final margin = topCount - sorted[1].value;
    return Proposal(
      'Pillar',
      topKey,
      margin >= 2 ? Confidence.high : Confidence.medium,
      margin >= 2
          ? '$topCount signals for $topKey, ${sorted[1].value} for '
              '${sorted[1].key}'
          : 'narrow win: $topCount for $topKey vs ${sorted[1].value} for '
              '${sorted[1].key}');
  }

  Proposal classifySeries() {
    final raw = idea.g('Series');
    final mapped = ContentSeries.fromLegacy(raw);
    if (mapped != null) {
      return Proposal('Series', mapped.label, Confidence.high,
          'legacy id "$raw" maps directly');
    }

    for (final entry in _seriesSignals.entries) {
      if (_has(entry.value)) {
        // `entry.key` is the target series; `entry.value` is the signal list.
        return Proposal('Series', entry.key, Confidence.medium,
            'legacy id "$raw" has no mapping; content signals ${entry.key}');
      }
    }
    return Proposal('Series', '', Confidence.low,
        'legacy id "$raw" has no mapping and the content gives no series signal');
  }

  Proposal classifyContentType() {
    final rawType = idea.g('Best content type');
    if (rawType.isNotEmpty) {
      final t = ContentType.byLabel(rawType);
      if (t != null) {
        return Proposal('Content Type', t.label, Confidence.high,
            'stated as "Best content type"');
      }
    }
    // Otherwise it was hiding inside `Format`.
    final raw = idea.g('Format');
    switch (raw.trim().toLowerCase()) {
      case 'reel':
        return Proposal('Content Type', 'Reel', Confidence.high,
            'recovered from the overloaded Format field');
      case 'carousel':
        return Proposal('Content Type', 'Carousel', Confidence.high,
            'recovered from the overloaded Format field');
      case 'trial reel':
        return Proposal('Content Type', 'Trial Reel', Confidence.high,
            'recovered from the overloaded Format field');
      case 'image reel':
      case 'image slideshow reel':
      case 'story reel':
        return Proposal('Content Type', 'Image Slideshow Reel',
            Confidence.high, 'recovered from the overloaded Format field');
      case 'static image':
        return Proposal('Content Type', 'Static Image', Confidence.high,
            'recovered from the overloaded Format field');
    }
    if (idea.g('Content Format').isNotEmpty &&
        _contentTypeNames.containsKey(raw.trim().toLowerCase())) {
      return Proposal('Content Type', _contentTypeNames[raw.trim().toLowerCase()]!,
          Confidence.high, 'recovered from the overloaded Format field');
    }
    return Proposal('Content Type', '', Confidence.low,
        'no content type stated and none recoverable from Format');
  }

  Proposal classifyNarrativeFormat() {
    // Schema A ideas kept the narrative shape in `Format` and the publishing type in
    // `Best content type`. Schema B ideas packed the publishing type into `Format` and
    // kept the shape in `Content Format`. Both are handled by trying each field and
    // accepting only a name the handbook actually knows.
    for (final field in ['Format', 'Content Format']) {
      final raw = idea.g(field);
      if (raw.isEmpty) continue;
      if (_contentTypeNames.containsKey(raw.trim().toLowerCase())) continue;
      final spec = validateNarrativeFormat(raw);
      if (spec != null) {
        return Proposal('Narrative Format', spec.name, Confidence.high,
            'resolved from $field');
      }
    }
    return Proposal('Narrative Format', '', Confidence.low,
        'no narrative format name in Format or Content Format');
  }

  Proposal classifyProduction() {
    final raw = idea.g('Production');
    if (raw.isNotEmpty) {
      final m = _productionFromLegacy[raw.trim().toLowerCase()];
      if (m != null) {
        return Proposal('Production Method', m, Confidence.high,
            'legacy production "$raw" maps to $m');
      }
    }

    // Nothing stated. Derive from the content type only when the derivation is
    // unambiguous, because "Mixed" and "Image slideshow" are both plausible for a
    // Reel and they produce different generation recipes.
    final type = idea.g('Best content type').trim().toLowerCase();
    switch (type) {
      case 'carousel':
        return Proposal('Production Method', 'Carousel', Confidence.high,
            'a carousel is produced as slides');
      case 'trial reel':
        return Proposal('Production Method', 'Image slideshow', Confidence.medium,
            'a Trial Reel is usually stills over audio, but Character images is '
            'also valid');
      case 'static image':
        return Proposal('Production Method', 'Text-based', Confidence.low,
            'Text-based or Character images; the idea does not say');
      case 'image reel':
      case 'image slideshow reel':
      case 'story reel':
        return Proposal('Production Method', 'Character images',
            Confidence.high, 'a story Reel is generated character images');
      case 'reel':
        return Proposal('Production Method', 'Character images', Confidence.low,
            'Reel could be Character images, Real-life video or Mixed');
    }
    return Proposal('Production Method', '', Confidence.low,
        'no production stated and the content type does not determine it');
  }

  Proposal classifyGoal() {
    final raw = idea.g('Goal');
    if (raw.contains('+') || raw.contains('/')) {
      return Proposal('Goal', '', Confidence.low,
          '"$raw" is two goals; one idea optimises for one, so this needs a '
          'human choice');
    }
    final mapped = ContentGoal.fromLegacy(raw) ?? ContentGoal.byLabel(raw);
    if (mapped != null) {
      if (mapped.name != raw.trim().toLowerCase()) {
        return Proposal('Goal', mapped.label, Confidence.high,
            'legacy goal "$raw" maps to ${mapped.label}');
      }
      return Proposal('Goal', mapped.label, Confidence.high, 'already stated');
    }
    // `Engagement` and `Community` are retired with no mechanical target, and both
    // sat on audience-participation posts. Guessing `comments` would change what
    // those posts optimise for.
    return Proposal('Goal', '', Confidence.low,
        '"$raw" is a retired goal with no single correct replacement');
  }

  Proposal classifyStatus() {
    final raw = idea.g('Status');
    if (raw.isEmpty) {
      return Proposal('Status', 'idea', Confidence.high,
          'no status stated, so it is untouched');
    }
    final s = IdeaStatus.fromLegacy(raw);
    if (s.id == raw.trim().toLowerCase()) {
      return Proposal('Status', s.id, Confidence.high, 'already on the ladder');
    }
    return Proposal('Status', s.id, Confidence.high,
        'legacy value "$raw" maps onto the ladder');
  }

  Classification classify() {
    final c = Classification(idea);
    c.pillar = classifyPillar();
    c.series = classifySeries();
    c.contentType = classifyContentType();
    c.narrativeFormat = classifyNarrativeFormat();
    c.goal = classifyGoal();
    c.status = classifyStatus();
    c.production = classifyProduction();
    return c;
  }
}

/// A full classification of one idea.
class Classification {
  final Idea idea;
  late Proposal pillar;
  late Proposal series;
  late Proposal contentType;
  late Proposal narrativeFormat;
  late Proposal goal;
  late Proposal status;
  late Proposal production;

  Classification(this.idea);

  /// The overall verdict for this idea.
  ///
  /// Weighted, not a simple worst-case roll-up. An idea whose pillar, series, format
  /// and goal are all solid is still a good idea; letting an unstated production
  /// method drag it to LOW reported 50 of 57 as failures when most were one decision
  /// short. Production is held separately because it changes the generation recipe
  /// rather than the creative intent, so it is worth fixing on its own rather than
  /// holding the whole classification hostage.
  Confidence get overall {
    final creative =
        [pillar, series, contentType, narrativeFormat, goal].map((p) => p.confidence);
    if (creative.contains(Confidence.low)) return Confidence.low;
    if (creative.contains(Confidence.medium)) return Confidence.medium;
    return Confidence.high;
  }

  /// Every proposal, in the order a reader wants to check them.
  List<Proposal> get all => [
        pillar,
        series,
        contentType,
        narrativeFormat,
        goal,
        status,
        production,
      ];

  /// Everything that must have a value before the migration can be applied.
  ///
  /// Production and goal are excluded: production defaults per content type and is
  /// fixed in its own pass, and an unresolved goal blocks six ideas out of fifty-seven
  /// for reasons a human must settle.
  List<String> get missingRequired => [
        for (final p in [pillar, series, contentType, narrativeFormat])
          if (p.value.isEmpty) '${idea.id}: ${p.axis}',
      ];
}

/// Content types the old `Format` field was really holding.
///
/// Declared before [Classification] because a stray closing brace once swallowed it
/// into the class body, which surfaced as "final field 'idea' is not initialized by
/// this constructor" — a constructor error three hundred lines from the cause.
const _contentTypeNames = {
  'reel': 'Reel',
  'carousel': 'Carousel',
  'trial reel': 'Trial Reel',
  'image reel': 'Image Slideshow Reel',
  'image slideshow reel': 'Image Slideshow Reel',
  'story reel': 'Image Slideshow Reel',
  'static image': 'Static Image',
};

// ============================================================================
// APPLYING
// ============================================================================

/// Rewrites one idea's block with the proposed axes.
///
/// Returns null when nothing changed, so a no-op apply rewrites nothing at all.
String? rewriteBlock(List<String> lines, Idea idea, List<Proposal> proposals) {
  // Blocks are delimited by `---`, so find the next one rather than guessing a length.
  var end = idea.lineStart + 1;
  while (end < lines.length && lines[end].trim() != '---') {
    end++;
  }
  if (end >= lines.length) end = lines.length;

  final block = lines.sublist(idea.lineStart, end);
  final heading = block.first;

  final body = block.sublist(1);
  final kept = <String>[];

  // Drops the old axes. `Content Format` is kept: it is the schema-B narrative shape
  // and losing it would lose the author's own wording for the beat structure.
  final drop = {'Series', 'Format', 'Best content type', 'Production', 'Goal',
                'Status', 'Pillar', 'Content Type', 'Narrative Format',
                'Production Method'};

  for (final raw in body) {
    // A packed line holds several fields; drop it whole and re-emit below.
    final first = _field.firstMatch(raw.split(RegExp(r'\s*\|\s*')).first);
    if (first != null && drop.contains((first.group(1) ?? first.group(2) ?? '').trim())) {
      continue;
    }
    if (raw.trim().startsWith('- **Series:**') ||
        raw.trim().startsWith('- **Status:**')) {
      continue;
    }
    kept.add(raw);
  }

  final axisLines = <String>[];
  for (final p in proposals) {
    if (p.value.isEmpty) continue;
    axisLines.add('- **${p.axis}:** ${p.value}');
  }

  // Insert after the id line so the block reads id, then axes, then prose.
  final out = <String>[heading];
  var inserted = false;
  for (final raw in kept) {
    out.add(raw);
    final m = _field.firstMatch(raw);
    if (!inserted && m != null && (m.group(1) ?? m.group(2)) == 'id') {
      out.addAll(axisLines);
      inserted = true;
    }
  }
  if (!inserted) out.addAll(axisLines);

  if (_identical(block, out)) return null;
  return out.join('\n');
}

bool _identical(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ============================================================================

void main(List<String> argv) {
  final apply = argv.contains('--apply');
  final wantReport = argv.contains('--report') || apply;

  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final original = file.readAsStringSync();
  final parsed = parseFile(original);

  if (parsed.ideas.isEmpty) {
    stderr.writeln('No ideas parsed. Refusing to write.');
    exitCode = 1;
    return;
  }

  // Classify before any write, so a dry run and an apply classify identically.
  final classified = [for (final idea in parsed.ideas) Classifier(idea).classify()];

  // -- Report
  var high = 0, medium = 0, low = 0, productionOpen = 0;
  final report = StringBuffer();

  report.writeln('Fun Learning With Palak, idea classification');
  report.writeln('============================================');
  report.writeln('');
  report.writeln('Ideas            : ${parsed.ideas.length}');
  report.writeln('Formats known    : ${FormatLibrary.all.length}');
  report.writeln('');

  for (var i = 0; i < classified.length; i++) {
    final c = classified[i];
    final verdict = c.overall;
    switch (verdict) {
      case Confidence.high:
        high++;
      case Confidence.medium:
        medium++;
      case Confidence.low:
        low++;
    }
    if (c.production.value.isEmpty) productionOpen++;

    report.writeln('${c.idea.id}   [$verdict]');
    report.writeln('  ${c.idea.heading}');
    for (final p in c.all) {
      final shown = p.value.isEmpty ? '?' : p.value;
      report.writeln('    ${p.axis}: $shown  (${p.confidence.name})');
      if (p.confidence != Confidence.high) {
        report.writeln('        ${p.reason}');
      }
    }
    if (c.idea.g('Notes').isNotEmpty) {
      report.writeln('    note from library: ${c.idea.g('Notes')}');
    }
    report.writeln('');
  }

  report.writeln('------------------------------------------------------------');
  report.writeln('HIGH   $high    every creative axis has one defensible answer');
  report.writeln('MEDIUM $medium  a default was applied, worth a glance');
  report.writeln('LOW    $low    genuinely ambiguous, needs a human');
  report.writeln('');
  report.writeln('Production method still open: $productionOpen');
  report.writeln('  Held apart from the verdict above, because production changes '
      'the');
  report.writeln('  generation recipe rather than the creative intent.');
  report.writeln('');

  if (wantReport) {
    File('tool/idea_classification_report.txt')
        .writeAsStringSync(report.toString());
    stdout.writeln('Wrote tool/idea_classification_report.txt');
  }

  // -- Apply
  if (!apply) {
    stdout
      ..writeln('HIGH   $high')
      ..writeln('MEDIUM $medium')
      ..writeln('LOW    $low')
      ..writeln('production open   $productionOpen')
      ..writeln('')
      ..writeln('Dry run. Nothing written. Use --apply to rewrite, --report to '
          'save the full report.');
    return;
  }

  // Refuse to write unless every idea resolves a pillar, series, content type and
  // narrative format. Applying a partial migration would leave the library
  // half-migrated, which is harder to reason about than not started.
  final missing = <String>[];
  for (final c in classified) {
    missing.addAll(c.missingRequired);
  }
  if (missing.isNotEmpty) {
    stderr.writeln('Refusing to apply. ${missing.length} ideas are missing a '
        'required axis:');
    for (final m in missing.take(20)) {
      stderr.writeln('  $m');
    }
    if (missing.length > 20) {
      stderr.writeln('  ... and ${missing.length - 20} more');
    }
    stderr.writeln('');
    stderr.writeln('Resolve these in content_ideas.md, or accept the proposals '
        'deliberately. Nothing was written.');
    exitCode = 1;
    return;
  }

  final backup = File('content_ideas.md.bak');
  backup.writeAsStringSync(original);
  stdout.writeln('Backup written: ${backup.path}');

  final out = List<String>.from(parsed.lines);
  // Applied back to front so earlier line numbers stay valid.
  for (var i = parsed.ideas.length - 1; i >= 0; i--) {
    final rewritten = rewriteBlock(out, parsed.ideas[i], classified[i].all);
    if (rewritten == null) continue;
    final start = parsed.ideas[i].lineStart;
    var end = start + 1;
    while (end < out.length && out[end].trim() != '---') {
      end++;
    }
    if (end >= out.length) end = out.length;
    out.replaceRange(start, end, rewritten.split('\n'));
  }

  file.writeAsStringSync(out.join('\n'));
  stdout
    ..writeln('Applied to ${file.path}')
    ..writeln('')
    ..writeln('MEDIUM and LOW proposals were applied as proposed. Re-read the '
        'report and correct them by hand; the .bak holds the original.');
}