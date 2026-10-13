# Master Generation Prompt

**Fun Learning With Palak, Content Production System**

This document covers two distinct generation paths in the app:

1. **Main content generation** — the master prompt for `Create Content` (Reels, Carousels, Static, Stories). Uses `AiContentService` with structured JSON output.
2. **Story Reel Maker** — `generateEverything()` in `lib/prompt_builder.dart` for the `StoryScreen`. Generates a timed script + scene prompts + post details in a single Gemini call.

---

## The flow this prompt serves

```
IDEA → FORMAT → CONTENT PACKAGE → CREATIVE → POST → TRACK
```

The app never invents an idea. It reads one from `documentation/content_ideas.md`, applies the fields you recorded, and runs this prompt.

---

## Two generation paths

### Path 1: Main content generation (`Create Content`)

The prompt below is for the `ContentPackageV2` generation path. `AiContentService` fills the `{{PLACEHOLDER}}` values and calls Gemini in JSON mode with `thinkingBudget: 0`. The parser is `AiParserValidator` → `ContentPackageV2.fromJson`.

```
Act as an expert Instagram growth strategist and content creator for Fun Learning With Palak.

BRAND:
Fun Learning With Palak
TAGLINE: Little Stories, Big Lessons
AUDIENCE: Indian moms and parents of children aged 1-4.
CONTENT STYLE: Warm, relatable, playful, practical, simple Hinglish.

CHARACTERS:
{{CHARACTER_PROFILES}}

IMPORTANT:
Never invent personal experiences, results, clients, statistics or claims.

CONTENT GOAL:
Create content designed for discovery among non-followers while also encouraging
saves, shares, comments and follows.

INPUT IDEA:
{{IDEA}}

SERIES:
{{SERIES}}

FORMAT:
{{FORMAT}}

PRODUCTION TYPE:
{{PRODUCTION}}

TARGET AGE:
{{AGE}}

CHARACTERS:
{{CHARACTERS}}

PRIMARY GOAL:
{{GOAL}}

FORMAT RULE:

If FORMAT = TRIAL REEL:
Create a simple, high-potential concept designed to test one content angle.
Prioritize a strong first 1-3 seconds and easy production.

If FORMAT = REEL:
Create a high-retention Reel with: Hook -> Problem -> Insight/Story -> Solution/Payoff -> CTA.

If FORMAT = IMAGE REEL:
Every image must communicate part of the story even without audio. Use minimal on-screen text.

If FORMAT = CAROUSEL:
Slide 1 must stop scrolling. Each following slide must move the story/information forward.
Final slide must contain CTA.

If FORMAT = STATIC:
Create one strong visual concept with a clear message. Do not force a carousel or Reel structure.

If FORMAT = STORY:
Create short sequential story frames designed for interaction.

FOR EVERY CONTENT PIECE PROVIDE:

1. Content title
2. Primary content angle
3. Visual hook
4. Verbal hook if applicable
5. On-screen/text hook
6. Complete content/script according to the selected format
7. Visual directions
8. Character actions/dialogue where applicable
9. CTA
10. SEO-friendly Instagram caption
11. Exactly 5 relevant SEO-friendly hashtags
12. Pinned comment
13. 5 natural comment replies
14. Suggested cover text
15. Recommended posting goal
16. Why this concept can attract non-followers
17. Format test number

HOOK RULES:
Do not use generic hooks. Create curiosity, recognition, surprise, tension or a
strong relatable parenting moment. The first 3 seconds must make the viewer want
to continue.

CAPTION RULES:
Make it natural and searchable. Use relevant keywords naturally.
Do not keyword-stuff. Do not repeat the Reel word-for-word. Keep it easy to read.

HASHTAG RULE:
Exactly 5 hashtags. Use relevant niche/intent-based hashtags. Do not use random generic hashtags.

CTA RULE:
CTA must match the content goal. Do not always say "follow for more."

CONTENT RULE:
The content should feel like something an Indian parent would actually experience.
Avoid generic parenting advice. Prefer specific situations, real-life problems and
practical solutions.

CHARACTER RULE:
Maintain the exact established personality and appearance of the characters in the library.
Do not change their character traits.

VISUAL STYLE:
{{VISUAL_STYLE}}
Every image prompt must include this style. The full character lock block from
`CharacterLibrary.characterLockFor()` is appended to image prompts.

OUTPUT:
Return a complete ready-to-create content package as valid JSON.
```

### Path 2: Story Reel Maker (`generateEverything()`)

The Story Reel Maker in `lib/prompt_builder.dart` uses a separate prompt built by `generateEverything()`. This path:

- Generates a **timed script** + **scene prompts** + **post details** in one Gemini call
- Falls back to `generateScriptWithGemini()` for scripts that exceed `kCombinedLineLimit` (10 lines)
- Accepts **character selection** via `List<String>? characterIds`
- Injects `Visual style`, `Aspect ratio`, and `Voice` specifications directly into the prompt
- Appends `CharacterLibrary.characterLockFor()` for character-lock enforcement

The prompt template:

```
Write a complete {SECONDS} second Instagram Reel for "Fun Learning With Palak".

THE STORY (this is the source of truth, follow it):
{STORY_DESCRIPTION}

Characters appearing: {CHARACTERS}.

Visual style: {BrandDefaults.visualStyle}.
Aspect ratio: vertical 9:16 for Instagram Reel.
Voice: {Hinglish narration with Devanagari spoken lines | English narration}.

{CharacterLibrary.characterLockFor(selectedCharacters)}

{kScriptShapeRules}

{kReelShapeRules}

Keep every line to 4-9 words: short on screen, still easy to say in about 4 seconds.
Write how a person talks, not how a book reads.

Return ONLY valid JSON in exactly this shape:
{ ... JSON schema ... }
```

**Character selection flow:**

1. User selects characters in the `StoryScreen` UI (chip selector) — defaults to Ria, Rio, Cuty
2. Selected IDs are passed as `characterIds` to `generateEverything()`
3. `CharacterLibrary.byId()` resolves each ID to a full `Character` profile
4. The character names/descriptions appear in the prompt header
5. `CharacterLibrary.characterLockFor()` generates the full CHARACTER LOCK block with only the selected characters

---

## Where the character descriptions come from

The `{{CHARACTER_PROFILES}}` and `{{CHARACTERS}}` placeholders are filled at runtime from
`lib/brand_system.dart` (`CharacterLibrary`), not hardcoded in this file. `brand_system.dart`
is the single source. The `characterLockFor()` method builds the lock block from whatever
cast is passed to it, so adding a character to `CharacterLibrary.all` updates every prompt
automatically.

The exact `Visual style` and `Negative prompt` blocks are also injected from
`brand_system.dart` (`BrandDefaults.visualStyle`).

### Current approved characters

| id    | Character | Emoji | Description                      |
|-------|-----------|-------|----------------------------------|
| `ria` | Ria       | 🌸    | Indian preschool girl, curious and playful |
| `rio` | Rio       | 💙    | Indian preschool boy, playful and determined |
| `cuty`| Cuty      | 🐰    | Small white bunny, the peace-bringer |
| `mumma`| Mumma   | 👩    | Young Indian mother, warm and patient |
| `papa`| Papa      | 👨    | Young Indian father, warm and playful |

The local `Character` class in `main.dart` (used for UI chip selection) maps each
selection to a `characterId` that resolves to `CharacterLibrary.byId()`.

**Characters in `master_prompt.md` but not yet in `CharacterLibrary`:** Daadi, Teacher. These are referenced in `documentation/content_ideas.md` field descriptions but have no approved profile yet, so any idea naming them generates without a locked appearance. This is the single biggest correctness gap in the prompt.

---

## Visual style

The visual style is settled: **3D Pixar/Disney-style render**, confirmed against
all five character renders in `assets/characters/`. `BrandDefaults.visualStyle` in
`lib/brand_system.dart` is the single definition used by:

- `generateEverything()` — inline in the prompt header
- `CharacterLibrary.characterLockFor()` — in the CHARACTER LOCK block
- `AiContentService` — via `{{VISUAL_STYLE}}` placeholder for the main generation path

The old watercolor wording that existed in `gemini_client.dart`, `format_adapter.dart`,
`quick_content.dart`, `slide_prompts.dart`, and 21 seeded `imagePrompt` strings in
`content_ideas.dart` were all replaced by this single constant.

---

## Two constraints from the reliability work

Both of these are already proven against the live API, so they stay.

**`thinkingConfig` with `thinkingBudget: 0`.** Without it the model burns budget on
reasoning and the JSON gets truncated mid-array. Every caption and script call in
`gemini_client.dart` and `generateEverything()` already sends it.

**Harden the parser.** `ContentPackage.fromJson` and `GeminiClient._parseResponse`
already tolerate missing fields. A new field added here should be added to the
fallback defaults, not assumed to be present.

---

## What is still a placeholder

`{{CHARACTER_PROFILES}}` currently resolves for Ria, Rio, Cuty, Mumma, and Papa only.
Daadi and Teacher have no approved one-line profile, so any idea naming them will
generate without a locked appearance.

The audience and age targeting still has a minor inconsistency: `BrandDefaults.audience`
says `Indian moms and parents of children aged 1-4` and `kScriptShapeRules` in
`lib/prompts.dart` references a 2-6 year range. Both should converge on the intended `1-4`
audience.