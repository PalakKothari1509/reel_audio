// Sanity check for the format handbook, run with: dart run tool/check_formats.dart
//
// Not a substitute for T-1. It exists because the handbook's scoring is the thing
// the milestone test depends on, and a scoring function that has never been executed
// is a scoring function with an unknown value.

import 'dart:io';

import '../lib/format_handbook.dart';

int failures = 0;

void check(String label, bool passed, [String detail = '']) {
  if (passed) {
    stdout.writeln('  ok   $label');
  } else {
    failures++;
    stdout.writeln('  FAIL $label${detail.isEmpty ? '' : '  ($detail)'}');
  }
}

void main() {
  stdout.writeln('Registry');
  check('12 formats registered', FormatLibrary.all.length == 12,
      'got ${FormatLibrary.all.length}');
  check('ids are unique',
      FormatLibrary.all.map((f) => f.id).toSet().length == 12);

  for (final f in FormatLibrary.all) {
    check('${f.id} has beats', f.structure.isNotEmpty);
    check('${f.id} has rules', f.generationRules.isNotEmpty);
    check('${f.id} has an example', f.example.length > 40);
    check('${f.id} declares a content type', f.bestContentTypes.isNotEmpty);
    check('${f.id} declares a goal', f.bestGoals.isNotEmpty);
  }

  stdout.writeln('');
  stdout.writeln('Axes');
  final problems = validateAxes();
  check('every axis reference resolves', problems.isEmpty, problems.join('; '));

  stdout.writeln('');
  stdout.writeln('Lookup');
  check('byId round-trips', FormatLibrary.byId('problemFix')?.name == 'Problem → Fix');
  check('byName round-trips',
      FormatLibrary.byName('Save This List')?.id == 'saveThisList');
  // The arrow must match what the idea library writes. It did not once: the
  // handbook had ASCII "Problem -> Fix" and content_ideas.md had the real arrow, so
  // five ideas looked unregistered for a format that had been registered all along.
  check('byName resolves the display arrow used by the idea library',
      FormatLibrary.byName('Problem → Fix')?.id == 'problemFix');
  check('unknown id returns null', FormatLibrary.byId('nope') == null);

  stdout.writeln('');
  stdout.writeln('The milestone idea: Ria refuses to brush her teeth');
  final rec = FormatLibrary.recommend(
    contentType: 'imageSlideshowReel',
    goal: 'nonFollowerReach',
  );
  check('recommends a format', rec != null, 'returned null');
  if (rec != null) {
    stdout.writeln('  -> ${rec.name} (${rec.id})');
    stdout.writeln('     ${rec.reason(contentType: 'imageSlideshowReel', goal: 'nonFollowerReach')}');
    check('imageSlideshowReel is supported by it',
        rec.supportsContentType('imageSlideshowReel'));
    check('Problem -> Fix is recommended, not a tie-break artefact',
        rec.id == 'problemFix', 'got ${rec.id}');
  }

  stdout.writeln('');
  stdout.writeln('No silent fallback');
  check('unmatched axes return null, not problemFix',
      FormatLibrary.recommend(contentType: 'unknownType', goal: 'unknownGoal') == null);

  stdout.writeln('');
  stdout.writeln('A default cannot outrank a better match');
  // POV defaults for reel but does not serve authority, so it scores 2 here.
  // numberedFramework supports reel and does serve authority, so it scores 3. If a
  // default could outrank a better match, POV would wrongly take this.
  final reelPick = FormatLibrary.recommend(contentType: 'reel', goal: 'authority');
  check('a non-default wins when it matches better',
      reelPick != null && !reelPick.isDefaultFor('reel') && reelPick.id == 'numberedFramework',
      reelPick == null ? 'null' : 'got ${reelPick.id}');
  // And with goals that do not separate anything, the declared default takes it.
  final reelDefault =
      FormatLibrary.recommend(contentType: 'trialReel', goal: 'relatability');
  check('the declared default wins a genuine tie',
      reelDefault != null && reelDefault.id == 'pov',
      reelDefault == null ? 'null' : 'got ${reelDefault.id}');

  stdout.writeln('');
  stdout.writeln('Prompt block shape');
  final block = FormatLibrary.problemFix.toPromptBlock();
  check('block names the format', block.contains('Problem → Fix (problemFix)'));
  check('block carries beats', block.contains('Structure, in order:'));
  check('block carries rules', block.contains('Generation rules:'));
  check('block omits the example',
      !block.contains(FormatLibrary.problemFix.example.substring(0, 30)));

  stdout.writeln('');
  if (failures == 0) {
    stdout.writeln('All checks passed.');
  } else {
    stdout.writeln('$failures check(s) failed.');
    exitCode = 1;
  }
}