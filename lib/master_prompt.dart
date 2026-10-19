// Master prompt constants for consistent content generation.
//
// These strings are the single source of truth for brand rules, visual style,
// and negative instructions across all generation paths (online Gemini and
// offline deterministic generation). Both paths must reference these
// constants so that prompts never drift between formats.

/// The shared brand and style context injected at the top of every prompt.
const String kMasterPrompt = '''
Soft 3D Disney-Pixar animation style, vertical 9:16 aspect ratio.
Indian family setting. Target audience: 3.5-5 year old children.
Bilingual Hindi-English environment (parents speak Hindi, children respond in simple English).
Warm, natural lighting. Cream backgrounds preferred.
Characters are toddlers with realistic proportions — no chibi or kawaii exaggeration.
Every character looks the same in every scene: same clothes, same hair, same colors.
Cute but not cartoonish. Semi-realistic rendering.''';

/// The visual style suffix appended to generation prompts.
const String kVisualStyle =
    'Soft 3D Pixar-Disney animation style, vertical 9:16, '
    'warm natural lighting, semi-realistic quality, cream background';

/// Constraints that apply to every generated frame.
const String kNegativeInstructions = '''
No duplicate characters, no identity changes, no outfit changes throughout.
Ria and Rio NEVER wear glasses.
Cuty is ALWAYS a small white bunny with a coral-pink neck bow.
Must maintain exact character appearance descriptions across all parts.
No distorted anatomy, no floating objects, no off-screen text, no blurry faces.
On-screen text is REQUIRED for sound-off viewing: short, readable, max 2 lines.''';

/// Story structure rules repeated in every prompt for consistency.
const String kStoryStructureRules = '''
Ria and Rio NEVER wear glasses.
Cuty is ALWAYS a small white bunny with a pink bow.
Use the exact character descriptions from Character Lock in every part.
No duplicate characters, no identity changes, no outfit changes.''';

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
