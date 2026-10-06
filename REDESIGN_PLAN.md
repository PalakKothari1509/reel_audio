# What Still Needs Building

Everything left to do on Fun Learning With Palak, in plain language.

**How to read this:** tasks are grouped by what they unblock. Anything marked **YOURS**
cannot be finished by me — it needs your decision or your keys.

**Last checked:** `flutter analyze` → 0 errors. `flutter test` → 36
tests, all passing. `check_pillars` passes. `check_axes`, `check_ideas` and
`review_content` report the open axes below — OPEN is the correct result for
unresolved taxonomy, not a failure.

---

## The one thing blocking everything

The 57 ideas in `content_ideas.md` are not fully classified yet.

Each idea needs seven values: **pillar, series, content type, narrative format,
production method, goal, status**. Right now most of them don't have them.

I can propose a value for almost every idea, with a reason. What I cannot do is decide
them for you — **a wrong pillar is invisible later**. It just quietly files the results
of a good post under the wrong heading, and six months of testing becomes unreadable.

**Two inputs unblock the next work, and neither is mine to produce:**

- **(A) Source details for 12 approved new ideas.** They are staged in
  `tool/approved_12_reconstruction.md` (temporary, non-authoritative) with only
  the recovered fields. I will not invent the missing fields.
- **(B) Explicit Phase D decisions for the existing 57.** These are human
  classification decisions. I will not manufacture them, and `OPEN` is not
  approval.

| Axis | Decided | Still open |
| --- | --- | --- |
| Pillar | 12 suggested | **43** |
| Series | — | **23** |
| Narrative Format | 19 approved, 12 suggested | 2 (1 needs review, 1 invalid) |
| Content Type | 57 in source | 0 |
| Production Method | — | **7** |
| Goal | — | **6** |
| Status | done | 0 |

### How to clear it quickly

I generated a review table so you can approve in one pass rather than 45 separate
decisions:

```bash
dart run tool/review_sheet.dart pillar
dart run tool/review_sheet.dart series
```

It writes `tool/review_sheet.md` — one row per idea with the proposed value, how
confident I am, and why. Fill in the **Decision** column.

**Two rows I would not trust without looking:**

- `day11-4year-skills` was proposed as **PLAY**. Its twin, `day6-3year-skills`, is
  already **DO**. They are the same kind of idea — an age skills checklist — so they
  should almost certainly match.
- `day16-voted-mission-won` was proposed as **THINK**. It is an audience vote
  announcement, which is not a thinking exercise at all.

### The 23 series with no obvious home

Four old series names never mapped, and I did not guess:

| Old name | Ideas | Why it has no answer |
| --- | --- | --- |
| `learning-through-play` | 10 | It was a pillar, not a series |
| `little-stories` | 9 | The retired "Little Stories, Big Lessons" name |
| `cuty-lessons` | 2 | Cuty is a character, not a series |
| `the-casts` | 2 | Audience voting — neither of its posts is relatable content |

This is the largest single editorial decision left, and it is **deliberately
not automated**: `little-stories` and `learning-through-play` stay OPEN until
the Phase D pass decides what those 19 legacy ideas actually become. The
checker reporting them OPEN is the correct signal, not a bug to fix.

### Two ideas that should not be forced

- `day14-favorite-format` — asks the audience which format worked best. It gives a
  parent nothing to save or send. Already marked `archive_candidate` rather than
  forced into a pillar.
- `st-ria-same-toy` and `lp-kitchen-counting` — both rest on a beat description
  because they have no Topic or Lesson text. Marked `beat_only` so you know the
  evidence is weaker.

---

## Next: one generator instead of five

The standalone Caption Generator and the "Generate All Formats" multi-select are
**already removed**. Create Content now generates one package for the selected
content type, and caption is part of that package. What remains: the app still has
multiple representations of a finished post, and they need to collapse into
one `ContentPackage`.

**The unified `ContentPackage` cannot be designed yet.** A finished package has to
know what it is generating — which pillar, which series, which format — and right
now most ideas don't.

Once the axes are settled:

- **Build one `ContentPackage`** that every path produces
- **Keep the script.** The prompt already asks for narration and per-scene dialogue,
  and the app throws it away. This is why narration isn't showing up in the output you
  asked for.
- **Delete the remaining standalone generators** once nothing needs them
- **Delete dead screens** — a quality check screen nobody opens, a shot planner that
  redirects, an old home screen

---

## What the ideas are missing

Every idea is checked against what actually gets content distributed. The result is
clear:

| Check | Ideas that don't state it |
| --- | --- |
| Share trigger | **56 of 57** |
| Open loop | 42 of 57 |
| Works with no voice | 35 of 57 |

**The library explains what a post is, not why anyone would watch it or send it.**

56 of 57 ideas currently do not have an evaluated share trigger. That is a
content gap, not a bug, and it is the highest-value thing to fix.

Once the axes are done, these become real fields on each idea rather than something I
check from outside.

---

## Missing screens

Four of the six tabs you planned do not exist:

| Tab | State |
| --- | --- |
| Ideas | Split across three places |
| Create | One workflow (one content type per generation); the multi-format path is gone |
| **Calendar** | Does not exist |
| **Analytics** | Does not exist |
| **Experiments** | Does not exist — no place for the 1/5 through 5/5 rule |
| Brand | Scattered across Settings |

**The idea behind them:** these are only worth building once generated content carries
its axes. Analytics that cannot tell you *which format* worked are just numbers.

**A word on the 5-test rule.** It needs somewhere to live. An idea tested once should
not be able to conclude anything, and the app should refuse to mark a format as failed
until it has a real sample.

---

## Clean-up work

| Task | Why it matters |
| --- | --- |
| Rotate your API keys | `lib/secrets.dart` holds live Gemini and ElevenLabs keys. Keys in an APK can be extracted. **`backend/` also holds a live OpenAI key and has no source code — what is it for?** |
| Release signing and app id | Still signed with the debug key, still called `com.example.reel_audio`. Not installable from Play |
| Settings key honoured in 2 of 10 places | Configure Gemini in Settings and most of the app ignores it |
| Remove unused packages | `hive`, `hive_flutter`, `cupertino_icons` are installed and never used |
| Google AI SDK is deprecated | And it has no thinking-budget control, which is why one large Gemini call can still return truncated text |
| Six near-identical storage classes | About 450 lines of repeated code with inconsistent error handling |
| Two `IdeaStatus` enums | `content_axes.dart` has the lifecycle ladder (idea → … → archived); `quick_content.dart` has a separate UI enum (idea / developing / ready / posted / reuse) with emoji and label. Only `idea` and `posted` exist in both, so the two ladders can drift. Consolidate when the Idea Vault moves to the model's ladder |
| README is template boilerplate | Says "A new Flutter project" |
| CI does not run on this branch | Only tests `main` and `video-slideshow` |

### File-by-file policy

Recorded so cleanup is deliberate, not a file-count
reduction. The final project is clean because every
remaining file has a known purpose.

**Keep:** `lib/`, `test/`, `tool/`, `android/`, `ios/`,
`web/` if still supported, `assets/`, `pubspec.yaml`,
`pubspec.lock`, `analysis_options.yaml`, `.gitignore`,
and the documentation that is part of the system:
`CONTENT_MODEL.md`, `content_formats.md`, `content_ideas.md`,
`REDESIGN_PLAN.md`, `README.md`.

**Review before deleting:** old generators, old screens and
routes, duplicate storage classes, old content JSON, obsolete
scripts, old planning documents (`master_prompt.md`,
`POSTS_REVIEW.md`, `APP_OVERVIEW.md`, the chat-export
`.md` files), temporary test files, and regenerable
exports (`tool/idea_classification_report.txt`,
`tool/reach_candidates.csv`, `debug_report.txt`).

**Remove only when confirmed obsolete:**

- `backend/` — **after the OpenAI key inside it has been
  rotated**. It has no source code and nothing references
  it, but the key is live until rotated.
- Standalone Caption Generator and "Generate All Formats"
  code — **done.** The unified one-type generation flow now
  exists (`CONTENT_MODEL.md` §7b), so both were removed.
  Caption is part of the package; Create Content generates
  one content type at a time.
- The 57 ideas and all content history — **never** deleted
  to make the folder look clean. They are curated through
  the Master Content Sheet (KEEP / REWORK / ARCHIVE /
  DELETE), not deleted by hand.

---

## Testing gaps

36 tests currently cover several quiet failure modes. Still untested: the Gemini
JSON parser, network calls, video assembly, and what happens when AI fails.

**Worth knowing:** most file-reading code cannot be tested at all, because the storage
layer has no test seam. Three components now have one — the promotion vault, the
idea inbox, and the content library. The rest need the same.

---

## Deliberately not being built

Recording these so they don't get re-proposed:

**A 150K potential score.** Seven scores across 85 ideas would be 595 numbers with no
evidence behind them, produced by guessing — and it would look like data. You already
decided this: *"learn from your real Instagram results rather than manufacture a viral
score."* The mechanics are checked honestly instead, as pass / fail / unknown.

**Regenerating all the ideas right now.** New ideas would discard the 19 narrative
formats and 12 pillars already decided, then restart the same review on a bigger set.

**More formats before these 16 are proven.** A format should earn its place because a
real idea needs it — which is exactly how the last four got added.

**Rebuilding the video pipeline.** The existing Reel Maker works end to end. Leave it.

**AI agents or autonomous posting.** Not until the classification work is solid.

---

## Suggested order

```
CLEAR THE BLOCKER
  review sheet  ->  you decide  ->  migration writes approved values
  (Phase D: the existing 57 ideas' KEEP / REWORK / ARCHIVE / DELETE)

WAITING ON INPUT
  (A) source details for the approved 12 — staged in
      tool/approved_12_reconstruction.md, not written until the
      missing fields arrive: the app never invents an idea
  (B) explicit Phase D decisions for the existing 57

THEN
  one ContentPackage
  keep the script (this is where narration comes from)
  production method decides the output
  delete the remaining standalone generators

THEN
  experiments tab, with the 5-test rule enforced
  analytics that can answer "which format works?"
  ideas tab, calendar, create consolidation

ANY TIME
  rotate keys
  release signing
```

**One honest observation.** The classification work looks like paperwork and is
actually the most valuable thing in this list. Every later question — which format
works, which hook gets shares, which series grows the account — can only be answered if
each post was recorded with the right labels. Do it once, properly, and the rest of the
app gets easier. Skip it and you end up with analytics that cannot tell you anything.