# Fun Learning With Palak — App Overview

What this app is, how it works today, and what is still missing. Written from the
code as it actually stands.

---

## 1. What the app is for

A content production app for the **Fun Learning With Palak** Instagram page. It takes
an idea and turns it into a finished, publishable Instagram package: hook, script,
scene-by-scene visual plan, captions, hashtags, and a call to action.

The brand is **screen-free learning and play for Indian parents of children aged 1–4**,
built around the characters **Ria, Rio and Cuty**.

The app **does not publish to Instagram**. You export the copy and post it yourself.
It also never promises views or reach, and nothing in it tries to.

---

## 2. The five content pillars

The model requires every piece of content to belong to one pillar — the value
it gives a child. The 57-item migration has not finished assigning them yet
(see §9 for the current counts):

| Pillar | What it is | Example |
| --- | --- | --- |
| **PLAY** | Activities that keep a toddler busy | Spoon transfer, water pouring |
| **THINK** | Simple problem-solving | "Which one doesn't belong?" |
| **DISCOVER** | Learning through everyday objects | Colours, textures, sounds |
| **TALK** | Language and parent-child conversation | What to say instead of "NO" |
| **DO** | Practical independence | Brushing, shoes, eating |

---

## 3. The seven series

A series is a recurring content world. It is **not** the same as a pillar:

| Series | What it covers |
| --- | --- |
| **Jugaadu Mummy** | Low-cost Indian parenting hacks |
| **Life With Ria & Rio** | Everyday preschool situations |
| **Can Your Child Figure It Out?** | Interactive problem-solving |
| **Talk With Your Child** | Conversation starters |
| **Try This At Home** | Practical activities |
| **Parent-Relatable** | Funny parent-and-toddler moments |
| **Age-Based Skills** | Reference by age |

The distinction matters: one idea can be a `Jugaadu Mummy` episode that is `PLAY` or
`DO`, depending on what the child is actually doing. Series and pillar never collapse
into each other.

---

## 4. The seven axes

An idea is fully described by seven separate values. This separation is the most
important design decision in the app.

| Axis | Question it answers |
| --- | --- |
| **Pillar** | What value does this give? |
| **Series** | Which recurring world does it belong to? |
| **Content Type** | What are we publishing? |
| **Narrative Format** | How is the story shaped? |
| **Production Method** | How do we actually make it? |
| **Goal** | What outcome are we optimising for? |
| **Status** | Where is it in production? |

### Why this matters

The app used to have **one** field called `Format` doing three different jobs. Of 57
ideas, 33 held a content type (Reel, Carousel), 24 held a narrative shape (Problem →
Fix, Save This List), and none had a pillar at all. That made it impossible to answer
basic questions like "which format works best?".

Splitting the axes fixed it.

### Content types

`Reel` · `Carousel` · `Trial Reel` · `Image Slideshow Reel` · `Static Image` · `Story`

**Trial Reel** is a publishing and testing type, not a production method. It is for
testing an idea with non-followers.

### Production methods

`Character images` · `Real-life video` · `Image slideshow` · `Text-based` · `Carousel`
· `Mixed`

This decides what Gemini is asked to produce: image prompts, a shot list, slides, or
text cards.

### Goals

`Reach` · `Non-follower Reach` · `Saves` · `Shares` · `Comments` · `Relatability` ·
`Authority` · `Follows`

### Status ladder

```
idea → approved → scripted → imagesReady → generated → posted → tested → archived
```

`imagesReady` exists because generating images is where a Ria/Rio/Cuty story Reel
spends most of its time. An idea that is written and one whose images exist are
different states.

---

## 5. Content format library

Narrative formats are **shapes of a story**, not publishing types.

The 12 currently registered: POV · Do This, Not That · Mistakes List · Problem → Fix ·
Exact Script · Expectation vs Reality · Personal Mistake · Save This List · Numbered
Framework · Unpopular Opinion · Before You · Three Examples — plus four added later:
Quick Tip, Mini Story, This or That, Question → Answer. **16 of 50.**

The format file is the source of truth (`content_formats.md`). Dart is generated from
it, so the app can never disagree with the document.

Each format records which content types it suits and which goals it serves, which is
what lets the app **recommend a format for an idea and explain why**.

---

## 6. The main screens

### Dashboard

Eight entries: Create Content, Reel, Trial Reel, Carousel, Image, Idea Vault,
Settings, and Promotion Comments. The standalone Caption Generator is gone —
caption is part of the generated package, not a separate workflow.

Create Content is the single generation path: one idea, one content type, one
package. The old "Generate All Formats" multi-select is removed.

### Create Content

Takes an idea and produces one package for the selected content type. Saves to
the library.

### Content Library

Lists everything you have saved. Filter by status, open any item, copy any block.

**This is new.** The library previously had a working save path and **no way to see
anything** — a save was real but unreachable.

### Reel Maker

Story brief → timed script and scene prompts → review and edit → images and voice →
render locally with FFmpeg → save to gallery. Autosaves as you go.

### Idea Vault

Raw idea capture with title, notes, bucket and status. Stored in `idea_inbox.json`.

### Promotion Comments

A vault of reusable comment replies, filterable by bucket.

---

## 7. How content is generated

Gemini is the text-generation provider; ElevenLabs is used for voice. One call
produces a complete package, then `FormatAdapter` converts it into four
format-specific outputs (carousel, reel, trial reel, single image).

Two things learned the hard way and now fixed:

**Hashtags.** A fixed set of five tags used to be injected into every single request,
which made topical tags impossible. Now the model is asked for tags relevant to the
actual post.

**Reasoning budget.** Gemini spends reasoning tokens out of the same budget as the
answer. Left uncapped on large requests, it returned truncated, unparseable JSON with
no error. Capped on all hand-built requests.

---

## 8. Brand and characters

`lib/brand_system.dart` holds the brand defaults and the character library.

**Visual style is one constant.** Changing how the app describes its art is a one-line
edit, not a change to character generation, scene generation, reel generation, prompt
templates, or individual ideas.

**Characters carry a lock block** that is appended to every image-generation request,
built from the full character library so a new character updates every prompt
automatically.

Approved characters: Ria, Rio, Cuty, Mumma, Papa, Daadi, Teacher.

---

## 9. Content idea library

`content_ideas.md` holds **57 ideas**, each with a topic, problem, lesson, goal and
metadata.

**Phase D is complete.** Every idea now has an explicit verdict in
`tool/idea_decisions.csv`: **41 KEEP**, 7 REWORK, 3 ARCHIVE, 6 DELETE. Only `keep`
ideas are sync candidates (41 active). The 6 deleted ideas are removed from the active
library; the 3 archived stay in `content_ideas.md` but are not sync candidates. The 7
REWORK ideas remain in the library but are not ready to sync until their noted issue is
resolved.

Current axis state (all decisions in CSVs; only `approved` rows are written):

| Axis | Decided | Open |
| --- | --- | --- |
| Pillar | **55 approved, 2 archiveCandidate** | **0** |
| Series | **51 approved, 2 archiveCandidate** | **4 (DELETE)** |
| Narrative Format | 19 approved, 12 suggested, 1 needsReview, 1 invalid | 2 (blocked) |
| Content Type | 57 in source | 0 |
| Production Method | **51 approved, 2 archiveCandidate** | **0** |
| Goal | **47 approved, 4 from source** | **6 (2 ARCHIVE, 2 DELETE, 2 ambiguous)** |
| Status | done | 0 |

**Automation proposes; a human approves.** **Phase 1 taxonomy is complete for the sync set** (41 KEEP ideas). The remaining OPEN items are ARCHIVE/DELETE or have ambiguous source goals — they do not block the active library.

**12 further ideas are approved but deferred.** They are staged in
`tool/approved_12_reconstruction.md` (temporary, non-authoritative) with
only the fields recovered so far. They are **skipped for now** — the original
source is not available, so they would be a fresh authoring pass, not a
reconstruction. They are not written here until that work is resumed.

### How well are these ideas built for reach?

Every idea is checked against what actually gets content distributed to strangers:

| Check | Ideas that don't state it |
| --- | --- |
| Share trigger | **56 of 57** |
| Open loop | 42 of 57 |
| Works with no voice | 35 of 57 |

The clearest finding: **the library describes what a post is, not why anyone would
watch it to the end or send it to a friend.** That is a content-quality gap, not a bug.

Each check answers **pass, fail, or unknown** — never a score out of ten, because a
self-assigned number would look like data without being evidence.

Two things are tracked separately on purpose:

- **Reach candidacy** — can this reach non-followers?
- **Production compatibility** — can our pipeline actually build it?

An idea can be a good reach candidate that needs real-life video. That is a filming
job, not a bad idea.

---

## 10. Tests

**36 + 37 = 73 tests, all passing.** They currently cover several quiet failure modes:

- the Gemini script parser (timestamps, bullets, Hinglish/Devanagari)
- legacy store decoding
- the content library save path (all four formats, metadata round trip, failed writes)
- three prompt bugs that shipped silently (fixed hashtags, contradictory CTAs,
  truncated JSON)
- the five-test rule (the minimum can be raised for a specific format)
- delete confirmations (a promotion comment and an idea both ask first)
- **quality gate system** (ShareTrigger, VoiceMode, SaveValue, ClassificationSnapshot,
  QualityGate.evaluateIdea, QualityGate.evaluatePackage, design invariants)

Not yet covered: the Gemini JSON parse path, network calls, FFmpeg assembly, and
the AI fallback path.

---

## 11. Development commands

Content is authored in markdown and compiled to Dart, so prompts stay fast and a typo
becomes a build error instead of a crash.

```bash
flutter analyze lib          # 0 errors
flutter test                 # 73 tests

dart run tool/sync_formats.dart      # content_formats.md -> Dart
dart run tool/check_formats.dart     # validate the handbook
dart run tool/check_axes.dart        # which axis values are decided
dart run tool/review_sheet.dart      # markdown table to review and approve
dart run tool/check_pillars.dart     # guard the known classifier mistakes
dart run tool/review_content.dart    # pre-install gate: decisions + blockers
dart run tool/reach_mechanics.dart   # distribution analysis
dart run tool/show_ideas.dart <id>   # print one idea in full
```

### Testing on your phone

```powershell
.\run_phone.ps1
```

The `.\` matters — a bare `run_phone.ps1` fails. Pairing is only needed the first time
(`.\run_phone.ps1 -Pair`). Keep the terminal open while editing: `r` reloads, `R`
restarts, `q` stops.

---

## 12. What is not done yet

In rough order of how much it matters:

1. **Phase D decisions are complete.** All 57 ideas now have verdicts in
   `tool/idea_decisions.csv`: 41 KEEP, 7 REWORK, 3 ARCHIVE, 6 DELETE. Only `keep`
   ideas are sync candidates (41 active). The 7 REWORK ideas need their noted issues
   fixed before they can sync. The 12 approved new ideas remain **deferred** — they
   wait in `tool/approved_12_reconstruction.md` until original source details arrive.

2. **Phase 1 taxonomy is complete** — all seven axes resolved for the 41 KEEP ideas.
   The 2 Narrative Format and 6 Goal items still OPEN are ARCHIVE/DELETE/ambiguous
   source and do not block the sync set.

3. **Phase 2 quality-gate system is complete** — implemented in
   `lib/content_quality_gate.dart` with 37 tests covering Share Trigger,
   Voice Mode, Save Value, four evaluation dimensions, classification snapshots,
   and the five-test rule.

4. **There is no unified Content Package.** The app still has multiple
   representations of a finished post. The standalone Caption Generator and
   the "Generate All Formats" multi-select are removed; the remaining
   representations need to collapse into one `ContentPackage`.

5. **The generated script is thrown away.** The prompt asks for narration and
   per-scene dialogue, and it is never read back — so the app cannot yet show the
   narration the plan promises.

6. **Four tabs do not exist:** Calendar, Analytics, Experiments, and a proper Ideas tab.

7. **Release builds are not distributable.** Signed with the debug keystore, and the
   application id is still `com.example.reel_audio`.

8. **Settings does not actually export or import** your data.

9. **Most file-reading code cannot be tested.** Three components have a test seam
   (the promotion vault, the idea inbox, and the content library); the rest do not.

---

## 13. Keeping this document honest

`REDESIGN_PLAN.md` tracks the remaining work. Completed items are removed from it as
they land, so it always shows only what is left.

If you change behaviour in the code, change this file in the same pass — a document
that describes an earlier version of the app is worse than none, because it is trusted.