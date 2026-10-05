// Proposes a narrative format for the ideas that have no handbook format name.
//
//   dart run tool/propose_formats.dart            dry run, writes nothing
//   dart run tool/propose_formats.dart --csv      writes tool/format_proposals.csv
//
// ── Why this exists ──────────────────────────────────────────────────────────
//
// 33 of the 57 ideas have no narrative format. The older 24 name one in `Format`.
// The newer 33 put the publishing type in `Format` and a beat description in
// `Content Format` — something like "Refusal -> one small win -> she tries it".
//
// That beat description is real evidence. It states the shape of the post, which is
// exactly what a narrative format is. Discarding it would waste the only signal
// present, and assigning all 33 to `Problem -> Fix` would recreate the original
// `Format` overload one level down: a plausible-looking wrong answer applied
// uniformly.
//
// ── How a proposal is reached ────────────────────────────────────────────────
//
// Each handbook format has a structural signature derived from its registered beats
// in `content_formats.md`. The idea's beat description is scored against every
// signature, and the winner is reported with the margin. A wide margin is HIGH; a
// narrow one is MEDIUM because two shapes genuinely fit; no clear winner is LOW and
// is left for a human rather than forced.
//
// Nothing here writes to `content_ideas.md`. This produces proposals for approval.

import 'dart:io';

import '../lib/content_axes.dart';
import '../lib/format_handbook.dart';
import 'migration_state.dart';

// ============================================================================
// STRUCTURAL SIGNATURES
// ============================================================================
//
// Derived from each format's registered `structure` beats, expressed as the
// vocabulary that actually appears in an author's beat description.
//
// Weights are deliberately coarse. A finer scale would look more rigorous and
// would only make the confidence numbers look authoritative; what matters is whether
// the winning shape is structurally the right one.

class Signature {
  final String formatId;

  /// Ordered stage markers. Each is a list of surface forms a beat might use.
  final List<List<String>> stages;

  /// Terms that, on their own, indicate this shape regardless of stage order.
  final List<String> decisive;

  const Signature(this.formatId, this.stages, {this.decisive = const []});

  /// How strongly the description matches this shape. Null when it does not.
  //
  // Requires coverage, not just a hit. A decisive keyword alone is not enough: the
  // word "moral" appears in one beat description, and the whole point of the shape
  // is the sequence. A shape with several stages has to match at least two of them,
  // so a format whose signature is essentially one term still matches on that term
  // but a multi-beat format cannot be claimed by a single phrase.
  int? score(String beats) {
    final b = beats.toLowerCase();
    var hits = 0;
    var matchedStages = 0;
    var lastIndex = -1;
    var inOrder = true;

    for (final stage in stages) {
      var found = false;
      for (final term in stage) {
        final idx = b.indexOf(term);
        if (idx >= 0) {
          found = true;
          if (idx < lastIndex) inOrder = false;
          lastIndex = idx;
          break;
        }
      }
      if (found) matchedStages++;
      if (stage.length > 1) hits += found ? 2 : -1;
    }

    var decisiveHits = 0;
    for (final d in decisive) {
      if (b.contains(d)) decisiveHits += 3;
    }

    if (matchedStages == 0 && decisiveHits == 0) return null;

    // A multi-stage shape claimed by one stage or one decisive term is not evidence.
    final minCoverage = stages.length > 1 ? 2 : 1;
    if (matchedStages < minCoverage && decisiveHits == 0) return null;

    var total = decisiveHits + hits;
    // Reward the stages appearing in the order the format declares them. A beat
    // sequence that runs backwards is a different shape, not a near miss.
    if (matchedStages >= 2 && inOrder) total += 2;
    if (matchedStages == stages.length) total += 2;
    return total;
  }
}

const _signatures = <Signature>[
  // Deliberately narrow, and deliberately only two stages.
  //
  // An earlier version matched on `play`, which is half the vocabulary of any toddler
  // post, so "Setup -> play -> satisfied ending" and "Materials -> play -> cleanup"
  // both scored as Problem -> Fix: 20 of 22 proposals came out identical, which is a
  // uniform wrong answer in a fancier costume.
  //
  // It then over-corrected. Problem -> Fix can be told in three beats
  // ("Resistance -> distraction -> win") or five, and requiring the full
  // obstacle/attempt/fix triple rejected the short tellings, including
  // `jm-wont-brush`, which is the single clearest problem-to-fix idea in the library.
  //
  // So the shape is reduced to the two things every telling shares: a stated
  // obstacle, and an intervention that resolves it. The failed first attempt is one
  // optional way to stage it, folded into the obstacle stage.
  Signature('problemFix', [
    ['refus', 'resist', 'struggl', 'reject', 'won\'t', 'wont', 'clamp',
     'fights', 'says no', 'tantrum', 'problem', 'distraction', 'first', 'usual',
     'count to'],
    ['fix', 'jugaad', 'instead', 'alternative', 'offer', 'choice', 'redirect',
     'gives her', 'puts the', 'distraction', 'a small win', 'one yes',
     'sharing', 'racing', 'help'],
  ], decisive: ['problem → jugaad', 'problem -> jugaad', 'jugaad', 'moral', 'takeaway']),

  Signature('saveThisList', [
    ['list', 'five', '5 ', 'seven', '7 ', 'things in', 'items', 'substitutes'],
  ], decisive: [
    'numbered list',
    'five-item',
    'five textures',
    'numbered list of',
  ]),

  Signature('numberedFramework', [
    ['step', 'steps', 'framework', 'routine', 'sequence', 'method'],
  ], decisive: ['numbered steps', 'framework']),

  Signature('expectationReality', [
    ['expect', 'imagine', 'suppose', 'plan'],
    ['real', 'actual', 'instead', 'but'],
    ['wrong', 'opposite', 'mistake', 'confus', 'laugh', 'tries'],
  ]),

  Signature('doThisNotThat', [
    ['pair', 'pairs', 'versus', ' vs ', 'not that', 'do this'],
  ], decisive: [
    'do this not that',
    'this or that',
    'numbered pairs',
    'phrase by phrase',
    'instead of',
  ]),

  Signature('exactScript', [
    ['say', 'words', 'phrase', 'script', 'quote', 'ask her', 'ask him', 'tell'],
  ], decisive: ['exact script', 'words to say']),

  Signature('questionAnswer', [
    ['ask', 'question'],
    ['answer', 'instead', 'respond', 'reply', 'say'],
  ], decisive: ['question -> answer', 'question → answer']),

  Signature('miniStory', [
    ['setup', 'once', 'one day', 'story', 'begin'],
    ['stuck', 'lost', 'obstacle', 'problem', 'rescue', 'treasure', 'hunt'],
    ['help', 'tries', 'idea', 'then', 'suddenly', 'finds'],
    ['done', 'rescued', 'happy', 'laugh', 'together'],
  ], decisive: ['rescue', 'treasure hunt']),

  // Owns activity demonstrations. The handbook was widened to say so explicitly after
  // six real ideas (water pouring, dal chawal, tape pull, spoon transfer, pouring,
  // simple sorting) matched nothing and were reported unresolvable. The alternative
  // was a new Activity Demonstration format, which would be format proliferation to
  // paper over a scope that Quick Tip already covers.
  //
  // The setup/play/result vocabulary is matched on purpose. It is the shape of a
  // demonstration, and it is not the shape of a problem-to-fix, which is why these
  // ideas must not fall through to Problem -> Fix by default.
  Signature('quickTip', [
    ['setup', 'materials', 'tray', 'bowl', 'spoon', 'pour', 'water', 'tape',
     'chawal', 'dal', 'sort', 'transfer', 'pull', 'texture', 'two bowls',
     'finger', 'spoonful'],
    ['play', 'transfer', 'result', 'repeat', 'cleanup', 'satisfied', 'proud',
     'done', 'find', 'match', 'next'],
  ], decisive: [
    'hidden',
    'odd one',
    'spot the',
    'find something',
    'two bowls',
    'materials',
  ]),

  Signature('threeExamples', [
    ['three', '3 ', 'first', 'second', 'third', 'ways', 'example', 'versions'],
  ], decisive: ['three ways', 'three examples']),

  Signature('mistakesList', [
    ['mistake', 'mistakes', 'wrong', 'should not', 'stop', 'tried', 'learned'],
    ['instead', 'now', 'fixed', 'changed', 'lesson'],
  ], decisive: ['mistakes']),

  // "small win" and "quiet" were listed here and both are generic outcome vocabulary,
  // not POV markers. "Refusal -> one small win -> she tries it" is plainly
  // Problem -> Fix and was being scored as POV on the strength of one shared phrase.
  // POV has to be named in the beats, because POV is a camera position and leaves no
  // other trace in a beat list.
  Signature('pov', [
    ['pov', 'point of view', 'your eyes', 'first person'],
  ], decisive: ['pov', 'point of view']),

  Signature('personalMistake', [
    ['i ', 'my ', 'told myself', 'learned', 'own', 'mistake'],
  ], decisive: ['personal mistake']),

  Signature('beforeYou', [
    ['before', 'first time', 'when they', 'moment'],
    ['mistake', 'wrong', 'goes wrong'],
    ['instead', 'do this', 'lay out', 'prepare'],
  ], decisive: ['before you']),

  Signature('unpopularOpinion', [
    ['opinion', 'nobody', 'unpopular', 'actually', 'truth', 'wrong'],
  ], decisive: ['unpopular opinion']),
];

// ============================================================================
// READING
// ============================================================================

final _field = RegExp(
  r'^\s*(?:-\s*)?(?:\*\*(.+?):\*\*|\*\*(.+?)\*\*\s*:)\s*(.*)$',
);

class Idea {
  final String heading;
  String id = '';
  final Map<String, String> fields = {};
  Idea(this.heading);

  String g(String k) => (fields[k] ?? '').replaceAll('`', '').trim();
}

List<Idea> readIdeas() {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return [];
  }

  final ideas = <Idea>[];
  Idea? current;
  var inFence = false;

  for (final raw in file.readAsLinesSync()) {
    final line = raw.replaceAll('\r', '').trimRight();
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    if (line.startsWith('### ')) {
      if (current != null && current.id.isNotEmpty) ideas.add(current);
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
      if (key == 'id') current!.id = m.group(3)!.replaceAll('`', '').trim();
    }
  }
  if (current != null && current.id.isNotEmpty) ideas.add(current);
  return ideas;
}

/// Content types, which `Format` sometimes holds instead of a narrative shape.
const _contentTypes = {
  'reel', 'carousel', 'trial reel', 'image reel', 'image slideshow reel',
  'story reel', 'static image', 'story',
};

/// An already-resolved format name, if any.
String? resolvedFormat(Idea idea) {
  for (final field in ['Format', 'Content Format']) {
    final raw = idea.g(field);
    if (raw.isEmpty) continue;
    if (_contentTypes.contains(raw.toLowerCase())) continue;
    if (validateNarrativeFormat(raw) != null) return validateNarrativeFormat(raw)!.name;
  }
  return null;
}

// ============================================================================
// APPROVED DECISIONS
// ============================================================================
//
// A decision a human has made outranks anything this tool infers.
//
// Without this, widening the Quick Tip signature to own activity demonstrations moved
// `lp-shape-hunt` from a clean Quick Tip match to a tie with Three Examples, and the
// proposal silently regressed an approved idea. The classifier is allowed to be
// wrong about undecided ideas; it is not allowed to contradict a settled one.
//
// ── These are NOT IdeaStatus values ──────────────────────────────────────────
//
// Migration state describes a decision in progress. IdeaStatus describes where an
// idea is in production. Collapsing them would mean a machine guess could write the
// word "approved" onto an idea, which is precisely the confusion this file exists to
// prevent. `approved` here means Palak approved the classification. It does not mean
// the idea has been approved for production.
//
// Only [MigrationState.approved] is writable. The rest are held.

// The vocabulary lives in tool/migration_state.dart, shared with the pillar
// decision file. It was duplicated here once, which is how the two files
// drifted into accepting different state spellings.
Map<String, Decision> readFormatDecisions() =>
    readDecisions('tool/format_decisions.csv', requireEvidence: false);
// ============================================================================

class Proposal {
  final Idea idea;
  final String beats;
  final String? format;
  final Confidence confidence;
  final String reason;
  final String? runnerUp;

  /// Set when the value came from a human decision rather than from inference.
  /// The distinction is the whole point, so it is reported separately.
  final MigrationState? machineOrigin;

  Proposal(this.idea, this.beats, this.format, this.confidence, this.reason,
      this.runnerUp, {this.machineOrigin});

  bool get writable => format != null && format!.isNotEmpty;
}

enum Confidence { high, medium, low }

void main(List<String> argv) {
  final ideas = readIdeas();
  if (ideas.isEmpty) return;

  final decisions = readFormatDecisions();
  final proposals = <Proposal>[];
  for (final idea in ideas) {
    // Already resolved by name in the source file. Not a proposal.
    final existing = resolvedFormat(idea);
    if (existing != null) continue;

    // A human decision already exists. Reported, never re-litigated.
    final decided = decisions[idea.id];
    if (decided != null) {
      if (decided.isWritable) {
        proposals.add(Proposal(
            idea,
            idea.g('Content Format'),
            decided.value,
            Confidence.high,
            'decided by Palak, ${decided.state.name}',
            null,
            machineOrigin: decided.state));
      } else {
        proposals.add(Proposal(
            idea,
            idea.g('Content Format'),
            null,
            Confidence.low,
            'held: ${decided.state.name}, not writable',
            null));
      }
      continue;
    }

    final beats = idea.g('Content Format');
    if (beats.isEmpty) continue;

    // Scores every signature against the beat description.
    final scored = <String, int>{};
    for (final sig in _signatures) {
      final s = sig.score(beats);
      if (s != null) scored[sig.formatId] = s;
    }
    if (scored.isEmpty) {
      proposals.add(Proposal(idea, beats, null, Confidence.low,
          'no registered shape matched the beat description', null));
      continue;
    }

    final ranked = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : null;
    final margin = second == null ? 99 : top.value - second.value;

    final spec = FormatLibrary.byId(top.key);
    if (spec == null) continue;

    final confidence = margin >= 4
        ? Confidence.high
        : margin >= 1
            ? Confidence.medium
            : Confidence.low;

    final reason = margin >= 4
        ? 'clear structural match, margin $margin over '
            '${second == null ? 'the only candidate' : second.key}'
        : margin >= 1
            ? 'matches ${spec.name}, but ${second?.key} is structurally close '
                '(margin $margin)'
            : 'tied with ${second?.key ?? 'nothing'}; the beats do '
                'not distinguish them';

    proposals.add(Proposal(
      idea,
      beats,
      spec.name,
      confidence,
      reason,
      second?.key,
    ));
  }

  // -- Console report
  var high = 0, medium = 0, low = 0;
  for (final p in proposals) {
    switch (p.confidence) {
      case Confidence.high:
        high++;
      case Confidence.medium:
        medium++;
      case Confidence.low:
        low++;
    }
  }

  stdout.writeln('Narrative format proposals');
  stdout.writeln('==========================');
  stdout.writeln('');
  stdout.writeln('Ideas with no handbook format name : ${proposals.length}');

  var writable = 0, held = 0;
  final byState = <String, int>{};
  for (final p in proposals) {
    if (p.writable) {
      writable++;
      final key = p.machineOrigin == null
          ? 'inferred'
          : 'machine: ${p.machineOrigin}';
      byState[key] = (byState[key] ?? 0) + 1;
    } else {
      held++;
    }
  }

  stdout.writeln('');
  stdout.writeln('WRITABLE (approved by Palak) : $writable');
  stdout.writeln('HELD (not writable)         : $held');
  stdout.writeln('');
  stdout.writeln('Proposed values for the held ideas come from the classifier and '
      'are');
  stdout.writeln('suggestions only. They are NOT written anywhere until they are '
      'approved');
  stdout.writeln('in tool/format_decisions.csv.');
  stdout.writeln('');
  stdout.writeln('Nothing was written. content_ideas.md is untouched.');
  stdout.writeln('');

  for (final p in proposals) {
    stdout.writeln('${p.idea.id}  [${p.confidence.name}]');
    stdout.writeln('  beats   : ${p.beats}');
    stdout.writeln('  propose : ${p.format ?? '(none)'}');
    stdout.writeln('  reason  : ${p.reason}');
    stdout.writeln('');
  }

  if (argv.contains('--csv')) {
    final csv = StringBuffer()
      ..writeln('idea_id,beats,proposed_format,confidence,runner_up,reason');
    for (final p in proposals) {
      csv.writeln([
        p.idea.id,
        '"${p.beats.replaceAll('"', "'")}"',
        p.format ?? '',
        p.confidence.name,
        p.runnerUp ?? '',
        '"${p.reason.replaceAll('"', "'")}"',
      ].join(','));
    }
    File('tool/format_proposals.csv').writeAsStringSync(csv.toString());
    stdout.writeln('Wrote tool/format_proposals.csv');
  }
}
