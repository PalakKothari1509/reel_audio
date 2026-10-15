# Brand Sheet

The single source of truth for how this brand looks, sounds, and stays consistent
across every generated image, video, and caption. The code in `lib/brand_system.dart`
and `lib/characters.dart` is the authority; this document explains it in plain English.

---

## 1. Brand Identity

| Field | Value | Source |
|---|---|---|
| **Name** | Fun Learning With Palak | `BrandDefaults.name` |
| **Handle** | @funlearningwithpalak | `BrandDefaults.handle` |
| **Banner line** | Little Stories • Big Lessons | `kBrandTagline` in `lib/prompts.dart` |
| **Audience** | Indian moms and parents of children aged 1–4 | `BrandDefaults.audience` |
| **Tone** | Warm, playful, parent-relatable, simple | `BrandDefaults.tone` |

### CTA rules (hard constraints)

- The app rotates through `ctaOptions` in `BrandDefaults` (`Save this for later`,
  `Share with another parent`, etc.).
- **"Follow for more"** and **"follow for daily play ideas" are banned.** `buildBrandContext()`
  in `brand_system.dart` injects an explicit instruction against them into every prompt.
- CTAs must be one call to action chosen for what **this** post asks for — never generic.

### Hashtag rules

`BrandDefaults.hashtagPool` provides 12 candidate tags, but:

- Every post takes **exactly 5** (`hashtagCount`), never fewer, never more.
- Brand tags (`#FunLearningWithPalak`, `#LittleStoriesBigLessons`) are available if
  they fit, but the rest must be topic-specific to THIS post — never the same set
  twice in a row.
- Never pad to reach five; trim when nothing else fits.

---

## 2. Visual Style

> **Soft 3D Pixar/Disney-style render, warm natural lighting, semi-realistic quality.
> NOT flat 2D, NOT watercolor, NOT kawaii-chibi.**

This is `BrandDefaults.visualStyle` in `brand_system.dart`. It is the single
definition of the look. Every image and video prompt reads this one constant.

**Why "NOT watercolor" is spelled out:** An earlier version of this file said
"Soft pastel watercolor storybook" while `prompts.dart` carried a private
"3D Pixar" const. Both instructions reached the model on the same generation cycle,
so every render came out confused. The character reference images in
`assets/characters/` are all 3D Pixar, so the style now matches them, and the
negative prompt is explicit.

### Canvas sizes

| Format | Dimensions | Safe zone | Bottom margin | Use |
|---|---|---|---|---|
| **Reel** | 1080×1920 (9:16) | Top 250, Bottom 450 | 20% clear | Stories, reels |
| **Trial Reel** | 1080×1920 (9:16) | Top 250, Bottom 450 | 20% clear | Fast-cut testing |
| **Carousel** | 1080×1440 (3:4) | Top 180, Bottom 180 | N/A | Multi-slide |
| **Single Image** | 1080×1080 (1:1) | Top 100, Bottom 100 | N/A | Static posts |

Key text and characters must stay inside the safe zone. The bottom 20% of reels
must stay clear for Instagram's overlay buttons.

Source: `ContentFormat` enum in `brand_system.dart`, `FormatExt.safeZoneSpec`.

---

## 3. Characters

Five core characters are defined in `CharacterLibrary` (`brand_system.dart`). Three
appear in `kDefaultCast` (`lib/characters.dart`) with bundled reference images.
Two more (Daadi, Teacher) have descriptions but no approved visual profiles yet.

### Ria

| | |
|---|---|
| **ID** | `ria` |
| **Emoji** | 🌸 |
| **Description** | Indian preschool girl, curious and playful |
| **Appearance** | Dark brown hair in two ponytails with pink bows, brown eyes, pink dress, **no glasses**, preschool age (3-4). Toofani: round chubby cheeks and a soft plump build, not thin |
| **Personality** | Curious and expressive, energetic and playful, asks questions and leads activities, sometimes stubborn, a little harmless chaos |
| **Role** | Protagonist / explorer |
| **Asset** | `assets/characters/Ria.jpg` |

### Rio

| | |
|---|---|
| **ID** | `rio` |
| **Emoji** | 💙 |
| **Description** | Indian preschool boy, playful and determined |
| **Appearance** | Dark brown hair, blue outfit, brown eyes, **no glasses**, preschool age (3-4) |
| **Personality** | Energetic and playful, naturally stubborn and determined, says "no" before thinking, follows then leads, deep focus when interested |
| **Role** | Co-protagonist / problem solver |
| **Asset** | `assets/characters/Rio.jpg` |

### Cuty

| | |
|---|---|
| **ID** | `cuty` |
| **Emoji** | 🐰 |
| **Description** | Small white bunny, the peace-bringer |
| **Appearance** | Small white bunny, pink bow, soft friendly expression, unchanged always |
| **Personality** | Gentle, quiet observer, calm and sleepy, unbothered, subtle comic relief and warmth, the emotional anchor, never the one who lectures |
| **Role** | Mascot / observer |
| **Asset** | `assets/characters/Cuty.jpg` |

### Mumma

| | |
|---|---|
| **ID** | `mumma` |
| **Emoji** | 👩 |
| **Description** | Young Indian mother in her early 30s, warm and patient |
| **Appearance** | Young Indian mother, early 30s, warm brown eyes, gentle radiant smile, hair in a soft high bun with loose face-framing strands, small red bindi, gold jhumka earrings, mustard yellow kurti with white chikankari embroidery, blue jeans, brown flat slide sandals |
| **Personality** | Warm, patient and observant. Playfully redirects tantrums rather than scolding, never lectures. Master of low-cost screen-free household hacks. Solutions come from noticing what's already in the kitchen, not from buying anything. |
| **Speech** | Calm Hinglish, encouraging, warm. Soft terms of endearment such as "arre mera bachha" and "dekho toh". Never scolding, never impatient. |
| **Role** | Warm problem-solver, the parent the viewer identifies with |
| **Asset** | `assets/characters/Mumma.jpg` |

### Papa

| | |
|---|---|
| **ID** | `papa` |
| **Emoji** | 👨 |
| **Description** | Young Indian father in his early 30s, warm and playful |
| **Appearance** | Young Indian father, early 30s, warm brown eyes, soft smile, dark hair neatly styled with light stubble. Light blue full-sleeve linen shirt, slim-fit jeans, brown embroidered juttis |
| **Personality** | Warm, patient and playful. Joins in the children's games rather than directing, adds silly voices and sound effects, defuses tension with a joke. The calm in the chaos. |
| **Role** | The calm problem-solver, the parent who joins the fun |
| **Asset** | `assets/characters/Papa.jpg` |

### Not yet approved

| **Daadi** | Referenced in ideas but no approved profile. Asset exists at `assets/characters/Daadi.jpg` |
|---|---|
| **Teacher** | Referenced in ideas but no approved profile. Asset exists at `assets/characters/Teacher.jpg` |

### Hard character rules

From `characterLockFor()` in `brand_system.dart`:

1. **Ria and Rio NEVER wear glasses.** This is enforced in every prompt.
2. **Cuty is ALWAYS a small white bunny with a pink bow.** Never human, never changes.
3. **Only the characters in the current cast may appear.** No background characters, bystanders, extras, or mascots.
4. **Outfits may change per scene but hair/eyes/face stay consistent.**
5. Use **attached reference images** for exact face/hair/outfit matching. Facial details are locked by images uploaded to Gemini — the prompt only enforces style, size, and the no-glasses rule.

---

## 4. Content Buckets

Six buckets define what each post IS about. Each has its own generation prompt,
slide templates, and example hooks. Source: `BucketLibrary` in `brand_system.dart`.

| ID | Name | Emoji | Description | Key hooks |
|---|---|---|---|---|
| `challenge` | Challenge | 🔎 | Observation games, pattern challenges, puzzles | `WHICH ONE DOESN'T BELONG?`, `FIND THE HIDDEN CUTY!` |
| `conversation` | Conversation | 🗣️ | Bedtime questions, dinner talks, imagination starters | `ASK YOUR CHILD THIS TONIGHT`, `3 QUESTIONS FOR THIS WEEK` |
| `activity` | Activity | 🏠 | Try this at home — household items only | `5-MINUTE KITCHEN CHALLENGE`, `THE SOCK HUNT` |
| `humor` | Humor | 😂 | Parent-relatable moments, toddler logic | `MUMMA SAYS THIS 100x A DAY`, `TODDLER MATHEMATICS` |
| `age_practice` | Age Practice | 📚 | Gentle milestone checklists | `CAN YOUR 3-YEAR-OLD DO THESE?` |
| `community` | Community | 💬 | Polls, votes, favourites, week wrap ups | `WHICH ONE SHOULD WE DO NEXT?`, `TELL US YOUR FAVOURITE` |

### Slide templates (by bucket)

**Challenge** — Cover → Challenge → Options → Think → Reveal → Why it works → CTA

**Conversation** — Cover → Question 1 → Question 2 → Question 3 → Why → Variation → CTA

**Activity** — Cover → What You Need → Step 1 → Step 2 → Step 3 → What They Learn → CTA

**Humor** — Cover → Scene 1 → Scene 2 → Scene 3 → Punchline → Tagline → CTA

**Age Practice** — Cover → Skill 1 → Skill 2 → Skill 3 → Skill 4 → Skill 5 → CTA

**Community** — Cover → Options → Each option → Why → CTA

---

## 5. Content Formats

Source: `ContentFormat` enum in `brand_system.dart`. Format decides the **shape**
of the package; Production method decides the **visual direction**.

| Format | Emoji | Description | Slides | Canvas |
|---|---|---|---|---|
| Reel | 🎬 | 15-20 sec vertical video | 5 (4-8) | 1080×1920 |
| Trial Reel | 🧪 | 60-sec fast-cut for reach | 8 (7-10) | 1080×1920 |
| Carousel | 📚 | Swipeable multi-slide post | 7 (5-10) | 1080×1440 |
| Single Image | 🖼️ | One image + full caption pack | 1 | 1080×1080 |

---

## 6. Share Trigger (mandatory)

Before writing any caption, the prompt asks:

> **"Why would one parent send this to another parent?"**

The answer must name a **specific** parent and situation:

> *Send this to the mom whose toddler says "I don't like vegetables" before even tasting them.*

Not "share with your friends." A share is worth more than a view, so this is not
optional decoration. If no specific person can be named, the post is not ready —
prefer an open loop or a surprising payoff that creates the send.

Source: `buildBrandContext()` in `brand_system.dart`.

---

## 7. Story Reel Workflow (Two-Stage)

The Story Reel builder in `lib/story_reel_builder.dart` uses a two-stage workflow.
Full details are in `clip_prompts.md`, summarized here:

- **Stage 1 — BeatSheet:** A base idea with five beats (setup, problem, escalation,
  turn, payoff) plus an optional stretch beat. Stored in `content_ideas.md`. No timing.
  This is the `BeatSheet` class in `lib/story_ideas.dart`.

- **Stage 2 — VideoClipPrompt:** You pick an idea + length (20/30/40/60 sec). The app
  produces N self-contained 10-second prompts, one per Part. Each Part is a
  standalone `VideoClipPrompt` (defined in `lib/prompts.dart:207`) with style, size,
  characters, camera, timed action (0-4s / 4-8s / 8-10s), audio, avoid rules, and a
  continuity line for Parts 2+.

  - `partsForLength()` → 20→2, 30→3, 40→4, 60→6 parts.
  - `beatIndicesForParts()` → maps beats to parts for each length.
  - `buildVideoPrompts()` → assembles the final `List<VideoClipPrompt>`.
  - `_buildPartPrompt()` → builds each Part's prompt text via `characterLockFor()`.

---

## 8. End Card & Closing

Every reel ends with the same screen so the channel is recognisable:

| Element | Value | Source |
|---|---|---|
| **Header** | ❤️ Little Stories, Big Lessons | `kEndCardHeader` in `prompts.dart` |
| **CTA line** | 💾 Save this for later / ↗️ Share with a parent who needs it | `kDefaultCtaLine` in `prompts.dart` |

The last screen carries a **question** to keep comments alive:
> *Comments are what keep a reel alive after the first hour, and people answer a
> question far more readily than they volunteer an opinion.*

No engagement bait anywhere — no "comment YES", "tag 10 friends", "like this",
"follow for more". Invite genuine conversation between parents instead.

---

## 9. Security Notes

- All API keys (Gemini, ElevenLabs) are centralized in `ApiKeyStore`
  (`lib/api_key_store.dart`), which honors the user-configured key in Settings
  before falling back to defaults.
- Keys are stored in `lib/secrets.dart` (git-ignored). Keys inside an APK can be
  extracted — **rotate before release**.
- Reference images are attached per generation call; no keys are embedded in prompts.
- See `SECURITY_AUDIT.md` for the full audit.
