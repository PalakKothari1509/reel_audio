# Master Generation Prompt

**Fun Learning With Palak, Content Production System**

This is the app's main prompt. One call produces a complete content package. It
replaces the old caption generator, hashtag generator, hook generator and CTA
generator, none of which should exist as separate screens.

---

## The flow this prompt serves

```
IDEA → FORMAT → CONTENT PACKAGE → CREATIVE → POST → TRACK
```

The app never invents an idea. It reads one from `content_ideas.md`, applies the
fields you recorded, and runs this prompt.

---

## Where the character descriptions come from

The `CHARACTERS` block below is filled at runtime from `brand_system.dart`, not
hardcoded in this file. `brand_system.dart` is the single source. When you approve
profiles for Mumma, Papa, Daadi and Teacher, they are added there once and flow
into every prompt automatically.

The exact `Visual style` and `Negative prompt` blocks are also injected from
`brand_system.dart`.

---

## The prompt

```
Act as an expert Instagram growth strategist and content creator for Fun Learning With Palak.

BRAND:
Fun Learning With Palak

TAGLINE:
Little Stories, Big Lessons

AUDIENCE:
Indian parents, especially moms of children aged 1-4.

CONTENT STYLE:
Warm, relatable, playful, practical, simple Hinglish.

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
Create a high-retention Reel with:
Hook -> Problem -> Insight/Story -> Solution/Payoff -> CTA.

If FORMAT = IMAGE REEL:
Every image must communicate part of the story even without audio.
Use minimal on-screen text.

If FORMAT = CAROUSEL:
Slide 1 must stop scrolling.
Each following slide must move the story/information forward.
Final slide must contain CTA.

If FORMAT = STATIC:
Create one strong visual concept with a clear message.
Do not force a carousel or Reel structure.

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
Do not use generic hooks.
Create curiosity, recognition, surprise, tension or a strong relatable parenting moment.
The first 3 seconds must make the viewer want to continue.

CAPTION RULES:
Make it natural and searchable.
Use relevant keywords naturally.
Do not keyword-stuff.
Do not repeat the Reel word-for-word.
Keep it easy to read.

HASHTAG RULE:
Exactly 5 hashtags.
Use relevant niche/intent-based hashtags.
Do not use random generic hashtags.

CTA RULE:
CTA must match the content goal.
Do not always say "follow for more."

CONTENT RULE:
The content should feel like something an Indian parent would actually experience.
Avoid generic parenting advice.
Prefer specific situations, real-life problems and practical solutions.

CHARACTER RULE:
Maintain the exact established personality and appearance of Ria, Rio and Cuty.
Do not change their character traits.

OUTPUT:
Return a complete ready-to-create content package as valid JSON.
```

---

## JSON shape

The prompt returns prose plus JSON. The app parses the JSON block only.

```json
{
  "title": "",
  "angle": "",
  "visualHook": "",
  "verbalHook": "",
  "textHook": "",
  "script": [
    { "scene": 1, "durationSec": 3, "visual": "", "onScreenText": "", "narration": "", "characterAction": "" }
  ],
  "visualDirections": "",
  "cta": "",
  "caption": "",
  "hashtags": ["", "", "", "", ""],
  "pinnedComment": "",
  "replySuggestions": ["", "", "", "", ""],
  "coverText": "",
  "recommendedGoal": "",
  "whyNonFollowersWillSeeIt": "",
  "formatTestNumber": "1/5"
}
```

**Never remove the JSON wrapper.** The parser reads the first fenced ```json block.
If the model wraps it in commentary, extract the block and ignore the rest.

---

## Two constraints from the reliability work

Both of these are already proven against the live API, so they stay.

**`thinkingConfig` with `thinkingBudget: 0`.** Without it the model burns budget on
reasoning and the JSON gets truncated mid-array. Every caption and script call in
`gemini_client.dart` already sends it.

**Harden the parser.** `ContentPackage.fromJson` and `GeminiClient._parseResponse`
already tolerate missing fields. A new field added here should be added to the
fallback defaults, not assumed to be present.

---

## What is still a placeholder

`{{CHARACTER_PROFILES}}` currently resolves for Ria, Rio and Cuty only. Mumma,
Papa, Daadi and Teacher have no approved one-line profile, so any idea naming them
will generate without a locked appearance. That is the single biggest correctness
gap in this prompt.

The visual style is settled: **3D Pixar/Disney-style render**, confirmed against
all seven renders in `assets/characters/`. `BrandDefaults.visualStyle` in
`brand_system.dart` is the only definition and `prompts.dart` reads it, so the
image and text builders can no longer disagree. The old watercolor wording had
also been hardcoded in `gemini_client.dart`, `format_adapter.dart`,
`quick_content.dart`, `slide_prompts.dart` and 21 seeded `imagePrompt` strings in
`content_ideas.dart`; all were replaced.

Still worth settling: `BrandDefaults.audience` says `1.5-5 years` and
`kScriptShapeRules` says `2-6 year old`. Both are wrong relative to the intended
`1-4`.

