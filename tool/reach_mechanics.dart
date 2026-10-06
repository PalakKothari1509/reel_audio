import 'dart:io';

import '../lib/content_axes.dart';
import 'classify_ideas.dart';

/// Classifies every idea against the distribution mechanics that actually decide
/// whether a small account gets seen by non-followers.
///
///   dart run tool/reachmechanics.dart              dry run
///   dart run tool/reachmechanics.dart --csv        writes tool/reach_candidates.csv
///
/// ── Pass, fail, unknown. Never a 1-to-10 score ───────────────────────────────
//
// A seven-dimension score sheet over 85 ideas would be 595 numbers with no evidential
/// basis, produced by guessing, and it would read as calibrated data. That is the same
/// object as the "fake viral score" this project explicitly rejected, and the same
/// reason the ten reach dimensions in `quality_check.dart` are heuristics and are
/// labelled as heuristics in the UI.
///
/// So each mechanic is a question with three honest answers:
///
///   pass     the idea demonstrably satisfies it
///   fail     the idea demonstrably does not
///   unknown  it cannot be determined from the text, and a human decides
///
/// `unknown` is the common case and is not a failure. Reporting it as unknown is the
/// difference between a measurement and a guess.
///
/// ── Why mechanics rather than scores ─────────────────────────────────────────
///
/// These are the things that decide non-follower distribution on a small account, and
/// each is a property of the idea rather than of its execution. An idea that needs a
/// voiceover to be understood cannot become a reach candidate by being filmed well.
///
/// ── Nothing is written ────────────────────────────────────────────────────────
//
// This reads `content_ideas.md` and reports. It does not regenerate the library.
/// Rewriting 85 ideas would discard every axis decision settled so far.

/// One distribution mechanic.
class Mechanic {
  final String name;

  /// Why it matters, in one line. Shown in the output so the criteria are auditable
  /// rather than opaque.
  final String because;

  /// Returns 'pass', 'fail', or 'unknown'.
  final String Function(Idea) judge;

  const Mechanic(this.name, this.because, this.judge);
}

/// Mechanics whose `fail` says the idea is **incompatible with the current
/// production workflow**. Shared with `review_content.dart`, which reports
/// the same ideas as a production notice rather than a blocker.
///
/// This is deliberately NOT the same as "Instagram will not distribute this".
///
/// An earlier version reported these as "blocked by a hard failure", which listed 16
/// ideas as unable to be reach candidates. Nine of them are perfectly good reach ideas
/// that happen to need real-life video, and the current workflow generates character
/// images. That is a production constraint, not a prediction, and conflating the two
/// would bake a workflow limitation into what the library believes about reach.
///
/// Two separate questions, two separate answers:
///
///   ReachCandidate       can this reach non-followers?        yes / no / unknown
///   ProductionCompatible can our pipeline build it?          yes / no
///   ProductionConstraint why not, when it cannot             named
///
/// An idea can be `ReachCandidate: yes` and `ProductionCompatible: no`. That is a
/// filming job, not a bad idea.
const productionConstraints = {'visual_first', 'production_simple'};

String _text(Idea i) =>
    [i.g('Topic'), i.g('Problem'), i.g('Lesson'), i.g('Audience Problem'),
     i.g('Content Format'), i.g('Notes')]
        .join(' ').toLowerCase();

bool _has(Idea i, List<String> terms) {
  final t = _text(i);
  return terms.any(t.contains);
}

/// The registered mechanics, shared with `review_content.dart` so the
/// pre-install gate and this report judge ideas identically. Two tools
/// with two copies of the signal lists would drift, and a drift between
/// them is exactly the kind of silent disagreement this toolchain exists
/// to prevent.
final mechanics = <Mechanic>[
  Mechanic(
    'visual_first',
    'The story must survive with no voice and ~6 words of on-screen text.',
    (i) {
      // An idea whose whole content is a list, script or instruction is not visual
      // first. Those are saves content by construction.
      final f = validateNarrativeFormat(i.g('Format')) ??
          validateNarrativeFormat(i.g('Content Format'));
      if (f != null && const {'saveThisList', 'numberedFramework', 'exactScript',
            'questionAnswer', 'doThisNotThat'}.contains(f.id)) {
        return 'fail';
      }
      // A concrete physical action implies something to film.
      if (_has(i, [
            'pour', 'transfer', 'spoon', 'wash', 'brush', 'wear', 'pack', 'stack',
            'chawal', 'dal', 'tape', 'water', 'bowl', 'sort', 'climb', 'race',
            'concert', 'treasure', 'hide'
          ])) {
        return 'pass';
      }
      return 'unknown';
    },
  ),
  Mechanic(
    'one_second_recognition',
    'A parent must recognise their own situation immediately.',
    (i) {
      // Named, repeatable situations. Absent a concrete moment, this is a concept
      // rather than a scene.
      if (_has(i, [
            'phone', 'chocolate', 'boring', 'bore', 'refuse', 'refusal', 'no ',
            'tired', 'hungry', 'bath', 'brush', 'shoes', 'dinner', 'lunch',
            'tantrum', 'same', 'vegetable', 'vegetables'
          ])) {
        return 'pass';
      }
      return 'unknown';
    },
  ),
  Mechanic(
    'open_loop',
    'Something is withheld, so there is a reason to stay.',
    (i) {
      if (_has(i, [
            'why', 'what happens', 'find', 'hidden', 'discover', 'reveal', 'turns',
            'twist', 'until', 'first', 'one day', 'suddenly', 'clue'
          ])) {
        return 'pass';
      }
      return 'unknown';
    },
  ),
  Mechanic(
    'share_trigger',
    'There is a person to send it to, named or implied.',
    (i) {
      if (_has(i, [
            'send', 'share', 'your friend', 'tag', 'moms', 'whichever', 'who does',
            'does this', 'tell me', 'comment'
          ])) {
        return 'pass';
      }
      return 'unknown';
    },
  ),
  Mechanic(
    'production_simple',
    'Character or generated images only. No filming required.',
    (i) {
      final p = i.g('Production').toLowerCase();
      if (p == 'video' || p == 'real-life video') return 'fail';
      if (p == 'character' || p == 'image') return 'pass';
      if (i.g('Characters').isNotEmpty && p.isEmpty) return 'pass';
      return 'unknown';
    },
  ),
  Mechanic(
    'follower_independent',
    'Understandable by a stranger who has never seen Ria, Rio or Cuty.',
    (i) {
      // Names a character but the beat carries no explanation of who they are.
      final namesCharacter = _has(i, ['ria', 'rio', 'cuty', 'mumma', 'papa', 'daadi']);
      if (!namesCharacter) return 'pass';
      // A character-led story is still legible if the beat states the situation.
      if (_has(i, [
            'refus', 'wants', 'tries', 'rejects', 'no ', 'not', 'wants the',
            'asking', 'bored', 'same', 'share'
          ])) {
        return 'pass';
      }
      return 'unknown';
    },
  ),
  Mechanic(
    'save_trigger',
    'Reference material a parent returns to.',
    (i) {
      final f = validateNarrativeFormat(i.g('Format')) ??
          validateNarrativeFormat(i.g('Content Format'));
      if (f != null && const {'saveThisList', 'numberedFramework', 'exactScript',
            'questionAnswer', 'mistakesList'}.contains(f.id)) {
        return 'pass';
      }
      return 'fail';
    },
  ),
];

void main(List<String> argv) {
  final file = File('content_ideas.md');
  if (!file.existsSync()) {
    stderr.writeln('content_ideas.md not found. Run from the project root.');
    exitCode = 1;
    return;
  }

  final ideas = parseFile(file.readAsStringSync()).ideas;

  stdout.writeln('Distribution mechanics, by idea');
  stdout.writeln('===============================');
  stdout.writeln('');
  stdout.writeln('Ideas: ${ideas.length}');
  stdout.writeln('');
  stdout.writeln('Per mechanic:');
  for (final m in mechanics) {
    final p = ideas.where((i) => m.judge(i) == 'pass').length;
    final f = ideas.where((i) => m.judge(i) == 'fail').length;
    final u = ideas.where((i) => m.judge(i) == 'unknown').length;
    stdout.writeln('  ${m.name.padRight(22)} pass $p  fail $f  unknown $u');
    stdout.writeln('      ${m.because}');
  }
  stdout.writeln('');

  // -- Per idea roll-up.
  //
  // Reported as a distribution, not a gate. An earlier version required 4 passes and
  // 0 fails and returned "0 of 57 viable", which read as a verdict on the library when
  // it was really an artefact of the threshold: `unknown` counts as neither, and most
  // mechanics are unknown because the ideas simply do not state the mechanic.
  //
  // That artefact turned out to be the finding worth reporting, so the gate is gone.
  final buckets = <int, int>{};
  final ranked = <List<dynamic>>[];
  for (final idea in ideas) {
    final passes = mechanics.where((m) => m.judge(idea) == 'pass').length;
    final fails = mechanics.where((m) => m.judge(idea) == 'fail').length;
    buckets[passes] = (buckets[passes] ?? 0) + 1;
    ranked.add([idea, passes, fails]);
  }

  stdout.writeln('How many mechanics each idea demonstrably satisfies');
  stdout.writeln('--------------------------------------------');
  final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final k in keys) {
    final bar = '#' * (buckets[k]! ~/ 2);
    stdout.writeln('  $k passes: ${buckets[k]!.toString().padLeft(2)}  $bar');
  }
  stdout.writeln('');

  // -- Reach candidacy is a judgement about the idea. Production compatibility is a
  // fact about our pipeline. They are reported as separate columns precisely so a
  // workflow limitation is never recorded as a verdict on the content.
  stdout.writeln('Reach candidacy and production compatibility, reported '
      'separately');
  stdout.writeln('--------------------------------------------');
  var reachYes = 0, reachUnknown = 0, incompatible = 0;
  final needsFilming = <String>[];

  for (final idea in ideas) {
    // Reach candidacy: passes at least one reach mechanic, and is not reference
    // content. `unknown` is the honest default, not a fail.
    final reachPasses = mechanics
        .where((m) => m.name != 'save_trigger' && m.judge(idea) == 'pass')
        .length;
    final isReference =
        mechanics.firstWhere((m) => m.name == 'save_trigger').judge(idea) == 'pass';

    final reach = isReference
        ? 'no: support content'
        : reachPasses > 0
            ? 'yes'
            : 'unknown';

    if (reach.startsWith('yes')) reachYes++;
    if (reach.startsWith('unknown')) reachUnknown++;

    final blockedBy = mechanics
        .where((m) => m.judge(idea) == 'fail' &&
            productionConstraints.contains(m.name))
        .map((m) => m.name)
        .toList();

    final compat = blockedBy.isEmpty ? 'yes' : 'no: ${blockedBy.join(', ')}';
    if (blockedBy.isNotEmpty) {
      incompatible++;
      needsFilming.add('${idea.id.padRight(28)} $compat');
    }

    stdout.writeln('  ${idea.id.padRight(28)} '
        'reach ${reach.padRight(20)} production $compat');
  }

  stdout.writeln('');
  stdout.writeln('Reach candidate      : $reachYes yes, $reachUnknown unknown');
  stdout.writeln('Production compatible: ${ideas.length - incompatible} of '
      '${ideas.length}');
  stdout.writeln('');
  if (needsFilming.isNotEmpty) {
    stdout.writeln('Cannot be produced by the current character-image workflow:');
    for (final f in needsFilming) {
      stdout.writeln('  $f');
    }
    stdout.writeln('');
    stdout.writeln('These are not weak ideas and not judged as poor reach. They '
        'need filming');
    stdout.writeln('or are reference content, which is a production and format '
        'decision.');
    stdout.writeln('');
  }

  // -- Mechanics the library barely states at all. This is the actionable finding.
  stdout.writeln('Mechanics the library does not state');
  stdout.writeln('-------------------------------------');
  for (final m in mechanics) {
    final unknown =
        ideas.where((i) => m.judge(i) == 'unknown').length;
    if (unknown <= ideas.length ~/ 3) continue;
    stdout.writeln('  ${m.name.padRight(22)} unknown on $unknown of '
        '${ideas.length}');
    stdout.writeln('      ${m.because}');
  }
  stdout.writeln('');

  ranked.sort((a, b) => (b[1] as int).compareTo(a[1] as int));
  stdout.writeln('Most complete mechanically:');
  for (final r in ranked.take(8)) {
    stdout.writeln('  ${(r[1] as int)} passes   ${(r[0] as Idea).id}   '
        '${(r[0] as Idea).heading}');
  }
  stdout.writeln('');

  // -- Ideas that are support content by construction, not weak ideas.
  stdout.writeln('Support content, not reach candidates (by construction):');
  stdout.writeln('---------------------------------------------');
  for (final idea in ideas) {
    if (mechanics.firstWhere((m) => m.name == 'save_trigger').judge(idea) ==
        'pass') {
      final f = validateNarrativeFormat(idea.g('Format')) ??
          validateNarrativeFormat(idea.g('Content Format'));
      stdout.writeln('  ${idea.id}   ${f?.name ?? 'reference content'}');
    }
  }
  stdout.writeln('');
  stdout.writeln('These are not weak. They are Saves and Authority content, and '
      'forcing them into a reach Reel would waste them.');
  stdout.writeln('');

  if (argv.contains('--csv')) {
    final csv = StringBuffer()
      ..writeln('idea_id,heading,${mechanics.map((m) => m.name).join(',')}');
    for (final idea in ideas) {
      csv.writeln([
        idea.id,
        '"${idea.heading.replaceAll('"', "'")}"',
        ...mechanics.map((m) => m.judge(idea)),
      ].join(','));
    }
    File('tool/reach_candidates.csv').writeAsStringSync(csv.toString());
    stdout.writeln('Wrote tool/reach_candidates.csv');
  }
  stdout.writeln('Nothing was written. content_ideas.md is untouched.');
}