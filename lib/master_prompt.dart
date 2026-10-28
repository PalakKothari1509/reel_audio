// Master prompt constants for consistent content generation.
//
// These strings are the single source of truth for brand rules, visual style,
// and negative instructions across all generation paths (online Gemini and
// offline deterministic generation). Both paths must reference these
// constants so that prompts never drift between formats.

/// The shared brand and style context injected at the top of every prompt.
/// Character descriptions are NOT included here — each generation path injects
/// the selected cast dynamically via its own character block, so stories starring
/// a different cast (e.g. Priya, Daadi, Ria) are not constrained by the default
/// Ria/Rio/Cuty descriptions.
const String kMasterPrompt = '''
Soft 3D Disney-Pixar animation style, vertical 9:16 aspect ratio.
Indian family setting. Target audience: parents of children aged 1-4.
Bilingual Hindi-English environment: adults speak natural Hindi, children speak age-appropriate Hinglish.
Warm natural lighting. Cream backgrounds preferred.
Characters are toddlers with realistic proportions — no chibi or kawaii exaggeration.
Every character looks the same in every scene: same clothes, same hair, same colors.
Cute but not cartoonish. Semi-realistic rendering.

Use the character descriptions from the CHARACTER LOCK section below — only
the listed characters may appear, with the exact wording provided.

LANGUAGE RULES:
  Adults speak natural, conversational Hindi or Hinglish — no stilted translations.
  Children speak simple, age-appropriate Hinglish — short sentences, limited vocabulary.
  Avoid formal, AI-sounding dialogue, repetitive catchphrases, and forced translations.

STORY QUALITY:
  Every story starts from a recognizable real-life preschool problem (e.g. sharing toys,
  bedtime resistance, picky eating, fear of loud noise).
  Child reactions are believable — frustration, tears, joy — not perfectly compliant.
  Parenting is imperfect but caring: mistakes happen, patience is shown.
  Clear cause-and-effect progression: Problem → Child acts → Consequence → Parent step → Resolution.
  Endings are satisfying but not artificially perfect — show a small, real-world improvement.
  Lessons are demonstrated through actions and consequences, not forced dialogue or moralizing.''';

/// The visual style suffix appended to generation prompts.
const String kVisualStyle =
    'Soft 3D Pixar-Disney animation style, vertical 9:16, '
    'warm natural lighting, semi-realistic quality, cream background';

/// Character appearance rules that must never change between parts.
///
/// Uses generics ("child characters") rather than hardcoded names so that
/// stories starring different casts (e.g. Priya, Daadi, Ria) receive the
/// correct continuity rules without irrelevant constraints from the default cast.
const String kCharacterRules = '''
Only characters from the CHARACTER LOCK block above may appear — never invent new characters.
Use the exact full character descriptions from the CHARACTER LOCK block above in every part.
No duplicate characters, no identity changes, no outfit changes between parts.
Preserve character positions, object locations, and scene continuity across all parts.''';

/// Constraints that apply to every generated frame.
const String kNegativeInstructions = '''
$kCharacterRules
No distorted hands or anatomy, no floating objects, no blurry faces.
NO on-screen text of any kind: no captions, titles, subtitles, speech bubbles,
readable signs, logos or watermarks. Text is added later in the editor.
No closing card, moral, quote or summary at the end.''';

/// Story structure rules repeated in every prompt for consistency.
const String kStoryStructureRules = '''
$kCharacterRules

VISUAL STORYTELLING:
  Every scene communicates through visible actions, facial expressions, and body language.
  No unnecessary props, characters, or scene changes — each element must serve the story.
  Preserve character positions, object locations, and previous-scene continuity.
  Show cause-and-effect visually: the audience must see why something happens, not just what happens.

LANGUAGE:
  Adults speak natural Hindi or Hinglish — never stilted or translated-sounding.
  Children speak short, age-appropriate Hinglish — simple words, limited grammar.
  Dialogue serves the action; it does not replace visual storytelling.

STORY PROGRESSION:
  Part 1 (10s): Establish the real-life problem and the character's first action.
  Part 2 (10s): Escalate tension through consequence, then resolve with a small, believable improvement.
  Each part ends on a clear beat that makes the viewer want to see what happens next.

ON-SCREEN TEXT:
  During image/video generation: render NONE. No on-screen text, no captions, no signs, no logos.
  Text overlays are added later in the editor using the ON-SCREEN TEXT OVERLAYS section of the plan.
  The overlay section specifies timing and content for post-generation addition only.''';

/// Header fields every video prompt part must include.
const List<String> kRequiredPromptSections = [
  'TITLE',
  'PART',
  'DURATION',
  'FORMAT',
  'STORY CONTEXT',
  'CHARACTER LOCK',
  'SCENE AND SETTING',
  'STARTING STATE',
  'CAMERA',
  'ACTION TIMELINE',
  'DIALOGUE AND AUDIO',
  'ON-SCREEN TEXT OVERLAYS',
  'CONTINUITY',
  'VISUAL STYLE',
  'NEGATIVE INSTRUCTIONS',
];

/// Phrases that make a story read as AI-written. For the quality gate and
/// tests only; never send these to a model.
const List<String> kBannedStoryPhrases = [
  'funny family chaos',
  'reacts in their own way',
  'listen, help one another',
  'big family memory',
  'teamwork makes the dream work',
  'little moments',
  'every child celebrates differently',
  'sharing is caring',
  'the magic of',
  'mission accomplished',
  'mission complete',
  'perfect ending',
  'something unexpected happened',
  'the big resolution',
  'what happens next',
  'and they all learned a lesson',
  'and the moral of the story is',
  'in the end,',
  'happily ever after',
  'they realized that',
  'without telling anyone',
  'the lesson here is',
  'as we all know',
  'it goes without saying',
  'needless to say',
  'in conclusion',
  'to sum up',
  'the end',
  'suddenly,',
  'magically,',
  'out of nowhere',
  'as if by magic',
  'with a sudden realization',
  'they happily',
  'everyone was happy',
  'and so they',
  'from that day on',
  'ever since then',
  'as a rule',
  'always remember',
  'never forget',
  'the moral is',
  'remember,',
];

/// Phrases that must never appear in an overlay or dialogue.
const List<String> kBannedOverlayPhrases = [
  'part ',
  'scene:',
  'middle mein',
  'starting soon',
  'mission accomplished',
  'mission complete',
  'sharing is caring',
  'the magic of',
  'perfect ending',
  'the big resolution',
  'finally!',
  'what happens next',
  'toh phir kya hua',
  'dekhte hi',
];

/// Typos and non-words already found in the library.
const List<String> kKnownBadTokens = [
  'wieder',
  'sirhara',
  'buthadh',
  'pitte',
  'couver',
  'haante',
  'khushboo mein latke',
  'chaddi',
];

/// Checks if [text] contains any banned phrase from [bannedList] using
/// word-boundary-aware matching (case-insensitive). Returns the first
/// matching phrase, or null if none found.
///
/// Uses `\b` regex word boundaries to avoid false positives like
/// "mission accomplished" matching "unaccomplished" or "sharing" matching
/// "sharing is caring" partially.
String? containsBannedPhrase(String text, List<String> bannedList) {
  final lower = text.toLowerCase();
  for (final phrase in bannedList) {
    final pattern = RegExp(r'\b' + RegExp.escape(phrase.toLowerCase()) + r'\b');
    if (pattern.hasMatch(lower)) {
      return phrase;
    }
  }
  return null;
}

/// Returns all banned phrases from [bannedList] found in [text] using
/// word-boundary-aware matching (case-insensitive).
List<String> findBannedPhrases(String text, List<String> bannedList) {
  final lower = text.toLowerCase();
  final found = <String>[];
  for (final phrase in bannedList) {
    final pattern = RegExp(r'\b' + RegExp.escape(phrase.toLowerCase()) + r'\b');
    if (pattern.hasMatch(lower)) {
      found.add(phrase);
    }
  }
  return found;
}
