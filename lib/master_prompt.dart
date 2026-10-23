// Master prompt constants for consistent content generation.
//
// These strings are the single source of truth for brand rules, visual style,
// and negative instructions across all generation paths (online Gemini and
// offline deterministic generation). Both paths must reference these
// constants so that prompts never drift between formats.

/// The shared brand and style context injected at the top of every prompt.
const String kMasterPrompt = '''
Soft 3D Disney-Pixar animation style, vertical 9:16 aspect ratio.
Indian family setting. Target audience: parents of children aged 1-4.
Bilingual Hindi-English environment: adults speak natural Hindi, children speak age-appropriate Hinglish.
Warm natural lighting. Cream backgrounds preferred.
Characters are toddlers with realistic proportions — no chibi or kawaii exaggeration.
Every character looks the same in every scene: same clothes, same hair, same colors.
Cute but not cartoonish. Semi-realistic rendering.

CHARACTER LOCK (do not deviate):
  Ria: 3-year-old girl, two high ponytails with pink bows, big brown eyes, dimple on left cheek,
       wearing a pink star-print dress (no glasses), small feet in pink sandals.
  Rio: 4-year-old boy, short brown hair, slight cowlick, brown eyes,
       wearing a blue kurta with white border and brown juttis (no glasses).
  Cuty: small white bunny, soft grey nose, pink neck bow, always upright on hind legs.
  Robot: friendly white-silver body, teal LED chest panel, child-height, round eyes glow teal.
  Mumma: warm Indian mother, yellow kurta, blue jeans, hair in a bun.
  Papa: light blue kurta, brown juttis.
  Daadi: silver bun, glasses, cream saree with gold border.
  Teacher: blue kurta, holding a book, kind smile.

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
const String kCharacterRules = '''
Ria and Rio NEVER wear glasses.
Cuty is ALWAYS a small white bunny with a pink neck bow.
Robot is friendly, white-silver with teal LED accents, child-height.
Mumma: warm Indian mother, yellow kurta, blue jeans.
Papa: light blue kurta, brown juttis.
Daadi: cream saree with gold border.
Teacher: blue kurta, holding a book.
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
