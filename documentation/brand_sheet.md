# Fun Learning With Palak — Brand Sheet

**Status:** Finalized. Single source of truth for brand identity.
**Date:** October 13, 2026

---

## 1. Brand Identity

| Field | Value |
|---|---|
| **Brand Name** | Fun Learning With Palak |
| **Handle** | @funlearningwithpalak |
| **Tagline** | Little Stories, Big Lessons |
| **Primary Audience** | Indian parents of children aged 1–4 |
| **Tone** | Warm, playful, parent-relatable, simple |
| **Language** | Hinglish (primary), English (secondary), Hindi (support) |

---

## 2. Content Pillars (5 confirmed)

| Pillar | What it is | Example |
|---|---|---|
| **PLAY** | Activities that keep a toddler busy | Spoon transfer, water pouring |
| **THINK** | Simple problem-solving | "Which one doesn't belong?" |
| **DISCOVER** | Learning through everyday objects | Colours, textures, sounds |
| **TALK** | Language and parent-child conversation | What to say instead of "NO" |
| **DO** | Practical independence | Brushing, shoes, eating |

---

## 3. Series (7 canonical)

| Series | Description |
|---|---|
| **Jugaadu Mummy** | Low-cost Indian parenting hacks |
| **Life With Ria & Rio** | Everyday preschool situations |
| **Can Your Child Figure It Out?** | Interactive problem-solving content |
| **Talk With Your Child** | Conversation starters |
| **Try This At Home** | Practical parent activities |
| **Parent-Relatable** | Funny preschool-parent moments |
| **Age-Based Skills** | Useful reference content |

---

## 4. Characters (5 approved)

| ID | Character | Emoji | Age | Description | Key Rules |
|---|---|---|---|---|---|
| `ria` | Ria | 🌸 | 3-4 | Indian preschool girl, curious and playful | Never wears glasses. Round chubby cheeks, soft plump build |
| `rio` | Rio | 💙 | 3-4 | Indian preschool boy, playful and determined | Never wears glasses. Naturally stubborn, says "no" first |
| `cuty` | Cuty | 🐰 | — | Small white bunny, the peace-bringer | Always small white bunny with pink bow. Never changes |
| `mumma` | Mumma | 👩 | ~30 | Young Indian mother, warm and patient | Warm, patient, never scolds. Uses "arre mera bachha" |
| `papa` | Papa | 👨 | ~30 | Young Indian father, warm and playful | Joins the fun, adds silly voices. The calm in the chaos |

**Characters NOT yet in the library:** Daadi, Teacher. Any story using them will generate without a locked appearance until profiles are written.

**Glasses:** Ria and Rio NEVER wear glasses. This is locked in `CharacterLibrary.characterLockFor()`.

---

## 5. Visual Style (1 confirmed)

**Soft 3D Pixar/Disney-style render, warm natural lighting, semi-realistic quality.**

- NOT flat 2D
- NOT watercolor
- NOT kawaii-chibi

This is defined in `BrandDefaults.visualStyle` in `lib/brand_system.dart` and injected into every prompt via:
- `generateEverything()` in `lib/prompt_builder.dart`
- `CharacterLibrary.characterLockFor()` in `lib/brand_system.dart`
- `AiContentService` via `{{VISUAL_STYLE}}` placeholder

All character renders in `assets/characters/` use this style. Watercolour/ pastel posts from the old grid are **legacy** and should be archived or redone.

**Aspect ratio:** Vertical 9:16 for Instagram Reels.

---

## 6. Lean Prompt Block (for every Gemini image/video prompt)

Reference images uploaded to Gemini handle facial locking. The prompt only needs
to enforce **style** and **size**.

```
STYLE (compulsory): Soft 3D Pixar/Disney-style render, warm natural
lighting, bright cozy colours. NOT flat 2D, NOT chibi, NOT watercolour.
Use the attached reference images for all characters. Match their faces,
hair and outfits exactly.

SIZE (compulsory):
- Reel / video / story frame: vertical 9:16 (1080x1920)
- Carousel / static post: 4:5 portrait (1080x1350)
Keep key characters and text inside the centre safe area. Leave the
bottom 20% and right edge clear for Instagram buttons.

NO GLASSES on any character.

SCENE: [describe the scene]
EXPRESSION: [emotion]
TEXT OVERLAY (if any): bold rounded font in a white banner with a
black border at the top.
```

> **Note:** Reference images lock faces and outfits well. They do not lock
> pose, scene or style on their own. If a result looks flat or 2D, repeat the
> style line in every scene prompt (the block above already does this).

---

## 7. Character Lock (lean version)

`CharacterLibrary.characterLockFor()` now outputs only names + the no-glasses rule
plus a pointer to reference images:

```
CHARACTER LOCK — Use the attached reference images for exact face/hair/outfit matching.

Ria, Rio, Cuty, Mumma, Papa

RULES:
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Only the characters listed above may appear in this post.
- Outfits may change per scene but hair/eyes/face stay consistent.

VISUAL STYLE:
Soft 3D Pixar/Disney-style render, warm natural lighting, semi-realistic quality.

SIZE:
- Vertical 9:16 (1080x1920) for Reels and Stories.
- Portrait 4:5 (1080x1350) for Carousels and Static posts.
- Keep key characters and text inside the centre safe area.
- Leave bottom 20% clear for Instagram buttons.
```

## 8. Two-Stage Content Workflow

**Stage 1 — Base Idea** (stored in `content_ideas.md`): Beats only, no timing.
Defines Setup, Problem, Escalation, Turn, Payoff, Stretch Beat, Ending line,
CLOSING CTA, and best length. No timestamps or camera notes at this stage.

**Stage 2 — Clip Prompts** (generated on demand, see `clip_prompts.md`):
You pick an idea + length. I produce N self-contained 10-second prompts.
Each Part includes style, size, characters, camera, timed action, and a
continuity line for Parts 2+. For Part 2+, attach the previous Part's last frame.

| Length | Parts | Beats |
|---|---|---|
| 20s | 2 | Setup+Problem+Escalation / Turn+Payoff |
| 30s | 3 | Setup+Problem / Escalation+Stretch / Turn+Payoff |
| 40s | 4 | Same as 30s + extra escalation or reaction |
| 60s | 6 | Rarely recommended — drift risk |

## 9. Content Generation Defaults

| Parameter | Default | Presets |
|---|---|---|
| Duration | 30 sec | 20, 30, 45, 60 sec |
| Language | Hinglish | Hinglish, English, Hindi |
| Tone | Warm, playful, relatable | Heartwarming, Funny, Educational, Adventure, Problem-Solving |
| Characters | Ria, Rio, Cuty | All 5 selectable via chip UI |
| Hashtags | Exactly 5 | Auto-generated per post |
| Voice | Optional | ElevenLabs (Settings override pending) |

---

## 10. Reach Mechanics

No viral scores. Every idea is checked mechanically with pass/fail/unknown:

- **Share trigger** — who sends this to whom, and why (sender, recipient, situation, reason)
- **Open loop** — does the post invite a response?
- **Voice mode** — `none` (visuals/text only), `optional` (voice enhances), `required`
- **Production compatibility** — can this be made with available tools?
- **Five-test rule** — a format needs 5 tests before judgment. Never conclude from one post.

---

## 11. Post Structure (per reel)

Each reel output includes:
1. Hook text overlay (first 3 seconds)
2. Script with 4-second-timed lines (Hinglish on screen + Devanagari spoken)
3. Scene descriptions (visual + expression + beat + shot + key objects)
4. Caption (2-3 lines, warm, ends with engagement prompt)
5. 5 niche-relevant hashtags
6. Pinned comment (conversation starter)
7. Cover title (3-5 words, big and curious)
8. Moral line (second-to-last screen)
9. End question (last screen, answer in 4 words)

---

## 12. Security

- All API keys (Gemini, ElevenLabs) centralized in `ApiKeyStore` (`lib/api_key_store.dart`)
- Settings-first fallback: user key checked before default
- Keys stored in `lib/secrets.dart` (git-ignored)
- `backend/` directory deleted (OpenAI key was never in git)
- **Action required:** Rotate both keys before release (compiled into APK)
- **Action required:** Add ElevenLabs Settings override

---

## 13. Test Status

**310 tests, all passing.** Coverage includes:
- Gemini script parser (timestamps, bullets, Hinglish/Devanagari)
- Content quality gate (ShareTrigger, VoiceMode, SaveValue, ClassificationSnapshot)
- AI content service (generation, validation, failure handling)
- AI parser validator (JSON schema validation, malformed/truncated, markdown extraction)
- Content library (save path, metadata round trip, all four formats)
- Content service (save/sync/duplicates)
- Story reel builder (12 tests, Navratri structure)
- Dashboard (84 tests)
- API key store (9 tests)
- JsonFileStore (11 tests)
- Content audit (12 tests)

Run: `flutter test`