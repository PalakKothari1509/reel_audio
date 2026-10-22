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
Bilingual Hindi-English environment: adults speak Hindi, children speak Hinglish.
Warm natural lighting. Cream backgrounds preferred.
Characters are toddlers with realistic proportions — no chibi or kawaii exaggeration.
Every character looks the same in every scene: same clothes, same hair, same colors.
Cute but not cartoonish. Semi-realistic rendering.''';

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
Use the exact character descriptions from CHARACTER LOCK in every part.
No duplicate characters, no identity changes, no outfit changes between parts.''';

/// Constraints that apply to every generated frame.
const String kNegativeInstructions = '''
$kCharacterRules
No distorted hands or anatomy, no floating objects, no blurry faces.
NO on-screen text of any kind: no captions, titles, subtitles, speech bubbles,
readable signs, logos or watermarks. Text is added later in the editor.
No closing card, moral, quote or summary at the end.''';

/// Story structure rules repeated in every prompt for consistency.
const String kStoryStructureRules = kCharacterRules;

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
  'mission accomplished',
  'perfect ending',
  'something unexpected happened',
  'the big resolution',
  'what happens next',
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
