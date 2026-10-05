# Redesign Plan, Fun Learning With Palak

**Scope: open work only.** Completed items are removed as they land. The audit that
produced this list is history and no longer tracked here; its findings are folded into
the tasks below.

**Last verified:** `flutter analyze lib` → **91 issues, 0 errors**. `flutter test` →
**21 tests, all passing**. Format checks pass. `check_axes`, `check_pillars` and
`reach_mechanics` all exit 0.
**Branch:** `copilot_post`. Untracked: `content_ideas.md`, `content_formats.md`,
`master_prompt.md`, `lib/models/quick_idea.dart`, `lib/format_handbook.dart`,
`lib/content_axes.dart`, `test/content_library_test.dart`,
`test/prompt_quality_test.dart`, `tool/*.dart`, `tool/*.csv`.

---

## Read this first

One decision is open and it blocks the largest remaining task.

| Open | Blocks |
|---|---|
| **Pixar-derived or storybook/watercolor** | Nothing. One constant, one line (T-12) |
| **T-7b: 57 ideas need pillar + series + production + goal** | T-7d, T-19, and T-9's inputs |

Everything else can proceed around T-7b.

---

## Stage A, live defects — 0 tasks left

`T-1` is done: **all 8 tests pass** and `flutter test` runs for the first time in this
repo's history. It had three separate defects, not one — see the DONE entry below.

Still open from this stage, folded into later tasks:

- **CI only triggers on `main` and `video-slideshow`** (`build.yml:12`). You are on
  `copilot_post`, so **CI has not been running on your branch.** Add it.
- **No mocking library in `dev_dependencies`**, so `http`, FFmpeg and the Gemini parse
  path are still untestable. One component now has a test seam
  (`PromoCommentVaultScreen.seed`). That is T-29.

---

## Stage B, data loss — 0 tasks left

`T-2` is done. See the DONE entry below for what it uncovered.

### T-2 Wire the posting pack to the content library — **DONE, with two defects found**

`PostingPackScreen._saveToLibrary` now builds a `ContentLibraryItem` from the package
and writes it, reporting the real outcome with an Undo action.

**The library turned out to be entirely dead code.** `ContentLibraryStore` had **zero
call sites in the whole app** — not `add`, not `getAll`, nothing. All 19 references to
it are inside `content_library.dart`. So the task was not "wire one button"; there was
no writer *and* no reader.

**`_saveAll` swallowed every exception** with `catch (_) {}`. A failed write was
indistinguishable from a successful one, so the UI could report "saved" over data that
was never stored — worse than refusing, because you would keep generating content
believing you had kept it. It now throws, and `tryAdd` returns a bool for the UI path.

**A latent crash in `FormatAdapter._expandToShots`, found by the new tests.** With an
empty `slides` and a target above zero it computed `lastIdx = -1` and read `shots[-1]`,
throwing `RangeError`. Any package generated without a scene breakdown crashed
`createFromPackage`, which is exactly the call the save depends on. Fixed to return
empty — a package with no scenes has no shots, and fabricating intermediate beats would
put content in front of a parent that nobody wrote.

**Tests: `test/content_library_test.dart`, 7 cases, all passing.** 15 total across the
suite. Covers save, all four adapted formats persisted, metadata round trip, failed
write reporting failure, repeated-save behaviour, the placeholder being gone from the
code, and retrieval through the store filters.

`ContentLibraryStore.useDirectory` is a test seam, since `getApplicationDocumentsDirectory`
is unavailable in tests. Same pattern as `PromoCommentVaultScreen.seed`.

**Still missing, and it matters:** there is **no screen that lists library items** and
no navigation to one. A save now persists correctly, but there is still no way to see
or reopen it. That is a viewer, not a save, and it is the natural next task.

### T-2b Build the library viewer — **not started**

The save is real; the library is still unreachable. Needs a list of saved items,
filtering by the seven statuses, and a detail view exposing the four format outputs.
Scope and design decisions, so not started unilaterally.

### T-3 `migrateBucketId` is not applied to `QuickIdea.bucket`

The migration maps `puzzle → challenge`, `talk → conversation`, `skill →
age_practice`, `wrap → community`, but only inside `PostRecord.fromJson`.

- `plan_data.dart:23-35` vs `QuickIdea.fromJson` in `quick_content.dart`

Saved ideas carrying a legacy id render as uncoloured text, because `bucketById`
returns null. 24 seeded posts were written against the old ids. Map on read; do not
rewrite the file, so old backups still restore.

---

## Stage C, one source of truth — 4 tasks left

The style half is done: `BrandDefaults.visualStyle` is the only definition, the 30
stale occurrences across 6 files are replaced, and `characterLockBlock` iterates the
library. What remains is the rest of the injected brand block.

### T-7 Freeze the axes — **DONE at the vocabulary level, 57 ideas still unmigrated**

**Shipped:** `lib/content_axes.dart`

| Enum | Values |
|---|---|
| `ContentPillar` | `PLAY` `THINK` `DISCOVER` `TALK` `DO` (`doIt`, since `do` is a Dart keyword) |
| `ContentSeries` | the seven, with documented legacy id mappings |
| `ContentType` | the six, with `unimplemented` naming the two T-14 owes |
| `ProductionMethod` | the six |
| `ContentGoal` | the eight, sharing ids with `kGoalIds` |
| `IdeaStatus` | the eight-state ladder, with positional `fromLegacy` |

Plus `GenerationRecipe`, whose `blockers` refuses a combination the app cannot produce
or that the narrative format does not claim — checked before generation, so an
impossible combination is a message rather than a half-rendered post. And
`creativeSpec` / `renderSpec`, which split the axes into what the model is told and
what the app renders.

**No `enum NarrativeFormat` was created, deliberately.** Narrative formats live in
`format_handbook.dart` as `FormatSpec`, synced from editable markdown, with 38 more
planned. A parallel enum would need hand-editing in lockstep with the handbook and
would drift — recreating the duplication this refactor exists to remove. Use
`validateNarrativeFormat`.

**The `Format` overload is now measured, not suspected.** Of 57 ideas, one field held:

- **33 content types** — Reel 18, Carousel 7, Trial Reel 5, Image Reel 2, Story Reel 1
- **24 narrative formats** — Save This List 6, Problem → Fix 5, Quick Tip 4, …
- **0 pillars at all**, and `Best content type` on only 24 of 57

### T-7b Classify the 57 ideas — **narrative formats: 19 approved, 14 held**

**Decisions live in `tool/format_decisions.csv`**, not in chat and not in
`content_ideas.md`.

| State | Count | Writable? |
|---|---|---|
| `approved` | **19** | yes |
| `suggested` | 12 | no |
| `needsReview` | 1 — `st-ria-wont-brush` | no |
| `invalid` | 1 — `lp-kitchen-counting` | no |

**Migration state is not `IdeaStatus`.** This is enforced in code, not just documented:
`MigrationState` is a separate enum, and `approved` there means *Palak approved the
classification*, which has nothing to do with an idea being approved for production.
Collapsing them would let a machine guess write the word "approved" onto an idea.

**The write rule is machine-enforced.** `MigrationState.isWritable` is true for
`approved` only, so `--apply` cannot write a suggested or held value even if asked.
An unknown state is a **hard error**, not a silent skip — a typo would otherwise turn
an approved decision into a missing one and the migration would quietly omit it.
Verified by injecting `approvved`: it refuses, names the line, and lists the four
valid states.

**`jm-dont-buy-use-this` promoted to `approved`** — correctly, it was marked HIGH in
your LOW table and had been mis-filed as `suggested`. That is why the count is 19 and
not 18.

**Your two holds stand, and one is independently confirmed.** `lp-kitchen-counting` is
the only idea the matcher also cannot resolve, tying Save This List against
Unpopular Opinion. `st-ria-wont-brush` stays open by your test: *"Resistance → Cuty
helps → done"* carries an obstacle and an intervention but no problem-and-fix
structure, so settle it by generating both packages and comparing.

**The handbook gap the LOWs exposed is closed.** Six of thirteen suggestions were the
same shape — water pouring, dal chawal, tape pull, spoon transfer, pouring, simple
sorting — and the handbook had no format for "show the activity". Rather than add a
seventeenth, **Quick Tip's stated scope now explicitly owns activity demonstrations.**
Unresolved fell 14 → 10 on that one edit, which is the evidence it was a scope gap and
not a matcher bug.

**Approved decisions outrank inference.** `propose_formats.dart` reads the decisions
file first and never re-litigates a settled idea. Without this, widening Quick Tip moved
`lp-shape-hunt` from a clean Quick Tip match to a tie with Three Examples, silently
regressing an approved idea.

### T-7b Phase 2 — pillar, 12 missing

One axis at a time, in the order the data allows. Each phase ends with the validator
showing zero missing for that axis before the next begins.

```
Phase 1  narrative format   19 approved, 14 held   ← you are here
Phase 2  pillar             12 missing
Phase 3  series              7 missing
Phase 4  content type        7 missing
Phase 5  goal                6 missing
Phase 6  production method  57/57 resolved         ← done
Phase 7  status              1 missing
```

Target before `sync_ideas.dart` becomes authoritative:

```
57 ideas · 57 valid · 0 missing on every axis
```

Keep the dry-run architecture exactly as it is. It has already caught several cases
where a dataset that looked complete was wrong, which is worth more than reaching
57/57 quickly.

### T-7b Phase 2 — pillar, 12 decided, 0 written

**Decisions in `tool/pillar_decisions.csv`**, all `suggested` or `archive_candidate`.
`content_ideas.md` untouched. `flutter analyze` 91 issues / 0 errors.

I did not widen the keyword vocabulary. **That was the right call and the five
false positives prove it** — patching the vocabulary would have produced the right
answers at HIGH confidence without making the matcher any more semantically capable.
A confident wrong pillar silently misfiles the performance data of a good post; an
honest miss is strictly better.

| State | Count |
|---|---|
| `suggested` | 11 |
| `archive_candidate` | 1 — `day14-favorite-format` |

**Three leans applied as you directed:** `day15-household-swaps` → PLAY,
`jm-5-kitchen-items` → PLAY, with DISCOVER and DO recorded as the alternatives.
`day14-favorite-format` is now `archive_candidate`, **not** forced into an axis value.
It surveys the audience about the account rather than giving a parent something to save
or send, so it has no pillar and inventing one would contaminate the dataset.

`MigrationState.archiveCandidate` is a real enum member with a rule attached: it must
carry **no** value. That is enforced, not documented.

**Evidence flags recorded.** `st-ria-same-toy` and `lp-kitchen-counting` are marked
`beat_only`. Both ideas have no `Topic`, `Lesson` or `Problem` field at all, so their
decisions rest on a beat description alone — materially weaker, and now visible rather
than indistinguishable from the other ten.

**`tool/check_pillars.dart` pins the five false positives** as regressions:

```
day5-ask-tonight       TALK   not DO
day18-mission2-concert PLAY   not THINK
day22-mission6-treasure THINK not TALK
jm-tape-pull           PLAY   not DO
lp-kitchen-counting    THINK  unresolved, blocked on two axes
```

The asserted invariant is deliberately **weaker than "the matcher is right"**:

> A human decision always wins, and the matcher must never be *confidently wrong*
> about an idea a human has already decided.

A tie or a miss is acceptable. A confident contradiction is not. That is the property
worth protecting, and it is checkable without pretending the matcher understands the
ideas.

**The guard was verified to have teeth.** All five currently return `?` at LOW, so the
check initially passed without reproducing anything. I temporarily widened the
vocabulary naively — exactly the fix that was rejected — and `day22-mission6-treasure`
came back as `DO` at high confidence, `3 signals for DO, 1 for TALK`. The check failed
and exited 1. Reverted. So it will catch the regression it exists for, rather than
sitting green for the wrong reason.

**The PLAY-heavy distribution is recorded but not acted on.** PLAY 6, THINK 3, TALK 2,
DO 1, DISCOVER 0 across these twelve. It is equally consistent with the library being
activity-heavy and with PLAY acting as a fallback when evidence is weak, and the
classifier has already demonstrated the second failure mode. Revisit only once all 57
have pillars.

**Shared vocabulary extracted to `tool/migration_state.dart`.** `MigrationState` and
`Decision` were duplicated in `propose_formats.dart` and were about to be duplicated a
third time in the pillar tool — which is how the two files drift into accepting
different spellings of the same state.

### T-7b Phase 3+ — remaining axes, consolidated

`check_ideas.dart` was not reading the decisions files, so it still reported 57 missing
pillars after twelve had been decided. Two validators disagreeing about one dataset is
worse than one incomplete validator, so:

- **`tool/check_axes.dart`** is now the authoritative coverage view. Reads
  `content_ideas.md` plus every decisions file. A value counts as resolved only if it
  came from the source or from a human decision — **inference is never counted**, and is
  reported separately as `inferable`.
- **`tool/propose_axes.dart`** emits proposals for every open axis value into one
  reviewable file, replacing five separate artefacts.

**The real remaining volume, which the piecemeal rounds understated:**

| Axis | in source | decided | open |
|---|---|---|---|
| Pillar | 0 | 11 suggested + 1 archive | **45** |
| Series | 34 | 0 | 23 |
| Narrative Format | 24 | 19 approved | 2 blocked |
| Content Type | 50 | 0 | 7 |
| Production Method | 50 | 0 | 7 |
| Goal | 51 | 0 | 6 |
| Status | 57 | 0 | **0** |

**Pillar was never 12 open, it was 45.** The twelve were only the ideas the keyword
matcher *missed*. The other 45 had inferred values that were never human decisions, so
under the established principle they still need approval. This was not visible until a
validator read the decision files.

### T-1 `test/widget_test.dart` — **DONE. All 8 tests pass.**

`flutter test` now runs for the first time in this repo's history. Three separate
defects, not one:

1. **`onCaptionGenerator` was never passed.** `CreatorHomeScreen` takes ten required
   callbacks and the test passed nine, so the file failed to compile and all seven
   tests were dead. The dashboard gained a Caption Generator entry, the constructor was
   widened, and nothing updated the test.
2. **`MaterialApp` and `Scrollable` were not imported.** The file imported
   `flutter_test` but not `material.dart`, and neither `creator_home.dart` nor
   `main.dart` re-exports it. Reported as "Method not found", which reads like a broken
   test rather than a missing import.
3. **Two tests called `pumpAndSettle` on screens that never settle.** The vault and the
   Idea Vault show a progress indicator while reading a local file; that future never
   completes under `path_provider`, so `pumpAndSettle` waited forever and timed out.
   Replaced with bounded pumps.

**One production change was needed to fix a test.** `PromoCommentVaultScreen` had no
injection point, so its "renders comments as wrapping rows" test asserted against data
the widget could never obtain in a test. Added an optional `seed` parameter; production
callers pass nothing and get the unchanged store-backed path.

That closes a recorded limitation too: with no mocking library in `dev_dependencies`,
anything touching `path_provider` was untestable. One component now has a seam.

Still no `mocktail`, so `http`, FFmpeg and the Gemini parse path remain untestable.
That is T-29.

### T-7b Phase 8 — distribution mechanics (`tool/reach_mechanics.dart`)

The reach spec arrived with a 7-dimension × 85-idea score sheet. **Not built, on
purpose:** 595 numbers with no evidential basis, produced by guessing, which is the
"fake viral score" the project explicitly rejected and the same reason the ten reach
dimensions in `quality_check.dart` are labelled heuristics in the UI.

Instead each mechanic is `pass` / `fail` / `unknown`, where `unknown` means the text
does not state it. That separates a measurement from a guess.

**The finding that matters: the library describes what a post IS, not why a stranger
would watch it to the end or send it.**

| Mechanic | unknown |
|---|---|
| `share_trigger` | **56 of 57** |
| `open_loop` | 42 of 57 |
| `visual_first` | 35 of 57 |
| `one_second_recognition` | 32 of 57 |
| `production_simple` | 32 of 57 |

Essentially **no idea in the library has a share trigger**, which independently
validates the spec's proposal to add `Share/Follow trigger` to the idea shape.

**Reach candidacy and production compatibility are now separate columns.** This
corrected a real error. The tool previously reported *"16 ideas cannot be reach
candidates as written"* — but nine of them are perfectly good reach ideas that happen
to need real-life video, and the current workflow generates character images. That is a
production constraint, not a prediction, and conflating them baked a workflow
limitation into what the library believes about reach.

```
                          reach              production
jm-tape-pull              yes                no: production_simple
day4-kitchen-challenge    no: support        no: visual_first
```

**Current split: 48 reach candidates, 2 unknown, 7 support content. 41 of 57 are
production-compatible.** An idea can be `reach yes` and `production no`, and that is a
filming job, not a bad idea.

**Two earlier errors in this tool, both caught by reading output:**

- The roll-up gated on "4 passes, 0 fails" and returned *"0 of 57 viable"*, which read
  as a verdict on the library when it was an artefact of the threshold — `unknown`
  counts as neither. Replaced with a distribution.
- `save_trigger` was treated as disqualifying, so its `fail` state — the normal case,
  since most ideas are not reference content — reported **50 of 57 ideas as blocked**.

**Seven ideas are correctly support content** rather than weak ideas:
`day4-kitchen-challenge`, `day5-ask-tonight`, `day6-3year-skills`, `day10-3-questions`,
`day11-4year-skills`, `day15-household-swaps`, `day25-week-wrap-up`.

**Most complete mechanically:** `day3-mumma-says` (5 of 7), then `st-rio-says-no`,
`jm-dal-chawal`, `lp-shape-hunt`, `st-rio-bored-2-min`, `jm-wont-brush`,
`jm-bath-resistance` at 4.

### T-7d One migration mapper

Old data → new axes, writing only `complete` and `auto-mapped` ideas and emitting
`needs review` / `invalid` for the rest. Dry-run first; `check_ideas.dart` already
proves the report shape.

### T-4 The static hashtag injection — **DONE**

`hashtagPool.take(hashtagCount)` injected the **first five tags into every request**,
while the generation prompt simultaneously asked for five tags relevant to the topic.
The fixed set always won, so no post could be topically tagged. Every post shipped with
the identical set: `#funlearningwithpalak #noscreenactivities #playbasedlearning
#montessoriathome #toddleractivities`.

Fixed at all three sites (`brand_system.dart:551`, `ai_provider.dart:72`,
`caption_generator.dart:294`). The brand block now offers the full pool as available
rather than prescribing five, and states not to pad to reach five. The offline caption
generator now leads with topic tags and dedupes, because a topic word like "toddler"
can produce a tag already in the brand pool and the same tag twice looks like a bug.

`#ahmedabadmoms` is still in the pool. It narrows a national audience, so removing it is
a one-line change once you decide.

### T-5 The CTA menu fought the CTA rule — **DONE**

`ctaOptions` injected all five options into every prompt, including *"Follow for daily
play ideas"*, while `prompts.dart:334` **explicitly bans** "follow for more" as
engagement bait. The app instructed the model to do the thing another file forbade.

Replaced with a single instruction to choose one CTA suited to the post, plus the
explicit prohibition naming the banned phrases. Removed from `brand_system.dart` and
`ai_provider.dart` together, since the same defect existed in both.

Still open from this task: `prompt_builder.dart:426` hardcodes
`ctaLine: kDefaultCtaLine`, so **every reel posts an identical CTA** while
`ContentPackage.cta` is per-bucket. Two CTAs, one screen.

### T-16 Six text call sites send no `thinkingConfig` — **3 of 4 fixed**

Fixed the three hand-built JSON call sites: `main.dart:158`,
`prompt_builder.dart:176` and `:336`.

**`gemini_client.dart:30` cannot be fixed in place.** The `google_generative_ai` SDK has
no `thinkingConfig` parameter at all, which is precisely why this was never applied to
the largest call in the app. Options are dropping the SDK for a hand-built request, or
moving off a deprecated package. Both are T-26, so the site is left documented rather
than pretending to be fixed.

This means one 8,192-token call can still spend budget thinking and return truncated,
unparseable JSON. It is the last known instance of the bug that produced silent
truncation.

### T-6 One audience age, verified everywhere

`BrandDefaults.audience` and `kScriptShapeRules` both say 1-4. Leftovers to grep for:
`1.5-5`, `2-6`, `3-6` in `ai_provider.dart` and `settings_screen.dart`.

Also confirm the intent: the earlier decision read "1.5 to 5 years, or shorthand 1-4".
Those are different ranges. The code says **1-4**.

### T-7e Migrate the six bucket ids — **not started**

Ten files hardcode the six bucket ids. Adding or renaming one needs ten edits, and the
audit named this the worst drift surface in the codebase.

- `format_adapter.dart:201,307,583` · `content_generator.dart:405,417,435,448`
- `quality_check.dart:531,550` · `regenerator.dart:255` · plus the other six sets

`content_axes.dart` now supplies the replacements. What remains is rewiring the ten
files onto `ContentPillar` / `ContentSeries` / `ProductionMethod`, and deleting
`ContentBucket` and `BucketLibrary` once nothing references them.

Note the two-stage shape: **the vocabulary shipped, the rewiring did not.** Nothing in
the app reads `ContentPillar` yet, so no behaviour has changed. This task cannot be
skipped, because until it is done the app still infers everything from buckets and the
new axes are documentation.

**Do not do this outside Stage D.** It touches the same ten files as the format work;
splitting them is how a third vocabulary appears.

### T-8 Wire the status enum onto stored rows

The ladder itself is **done** — `IdeaStatus` in `content_axes.dart` has all eight
values, and `fromLegacy` maps positionally rather than by name, so neither the old
`reuse` nor the old `reused` can fail, and an unrecognised value falls back to `idea`
instead of throwing. A status is not worth crashing a restore over.

What remains is the storage migration on read:

- `quick_content.dart:2946` — `idea, developing, ready, posted, reuse`
- `content_library.dart:11` — `idea, draft, ready, posted, reused, archived`

Both `fromJson` implementations must route through `IdeaStatus.fromLegacy` so existing
rows land on the new ladder rather than being reinterpreted by position against a
different enum.

---

## Stage D, one generator — the main event

Nothing here is started. This is where the app becomes the thing you described:
**one Content Studio, not a collection of generators.**

### T-9 Four models of "a complete post"

| Model | Fields | Problem |
|---|---|---|
| `ContentPackage` | hashtags `List<String>`, `replyComments` of exactly 5 | missing SEO fields |
| `PostDetails` | `replyQuestion` — one `String`, not a list | 5 replies structurally impossible |
| `QuickIdea` | hashtags `String`, `comments` folded together | pinned comment and a reply are indistinguishable |
| `ParsedPostPackage` | 18 fields, 17 overlapping `QuickIdea` | bridged by a conversion with a `RangeError` in it |

- `content_generator.dart:10` · `prompts.dart:133` · `lib/models/quick_idea.dart`
  · `content_ideas.dart:1093`

Migrate all four to one package type. This is the keystone — most of Stage D's other
tasks are downstream of it.

Add the two SEO fields the spec requires and nothing currently models:

```
primaryKeyword   // e.g. "screen free activities for toddlers"
secondaryKeywords // 3-5, used naturally, never stuffed
```

They drive the caption, the on-screen text where appropriate, and the topic line.

### T-10 Pick one caption spec, one quality checker

Three caption specifications, and the declared standard is imported only by its own
file:

- `caption_generator.dart:37` (the declared standard)
- `gemini_client.dart:116`
- `prompt_builder.dart:141`

Two quality checkers disagree on the same rule — `hook_length` is ≤125 chars in one
and ≤8 words in the other:

- `quality_check.dart:90` vs `quick_content.dart:2323`

The ten reach dimensions already went into `quality_check.dart` as `warn` severity so
they cannot block posting. Keep the other checker out rather than reconciling three
ways.

### T-11 The fallback exists and is never instantiated

`AIProviderWithFallback` and `NoOpAIProvider` have zero call sites. `main.dart:411`
wires a bare client or null.

- `ai_provider.dart:95`, `:269`

So every AI failure surfaces as an error with no fallback — the exact scenario the
class was written for. `caption_generator.dart:154` also *documents* a fallback it
does not implement: the code only falls back when the key is empty.

### T-12 The `script` is generated and thrown away

`gemini_client.dart:233` requires `script` in the response schema, the prompt demands
it, five few-shot examples include it, and `_parseResponse` **never reads it**.
`ContentPackage` has no field to hold it.

- `gemini_client.dart:233` vs `:329-369`
- `quality_check.dart:292` papers over this: *"Script stored in caption for now"*,
  and `script_timing` then measures the caption's word count as a voiceover

This matters directly to you: **narration and per-scene dialogue are in your required
output and currently do not exist as fields.** Fixing this is what makes the
"visual plan, narration, on-screen text" part of the package real.

Split into the shape the spec asks for, so one field is not doing four jobs:

```
script   // scene-by-scene: visual action + narration + on-screen text
```

### T-13 `content_formats.md` + `format_handbook.dart` — **DONE**

**Shipped:**

- `content_formats.md`, 12 formats to begin with, nine canonical fields each
- `lib/format_handbook.dart` — `FormatSpec` registry, `kContentTypeIds`, `kGoalIds`,
  `validateAxes()`, `recommend()` with one-line reasoning
- `tool/sync_formats.dart` — `content_formats.md` → Dart, const preserved
- `tool/check_formats.dart` — 78 checks, all passing

**Decisions that landed with it:**

- Own file, not `brand_system.dart`. Formats are the most volatile data in the app,
  and `brand_system.dart` has ten-plus importers.
- **The handbook never references buckets or pillars**, so T-7 stays possible.
- `Name` uses the real arrow `→`, not ASCII `->`. Getting this backwards was silent
  and cost five ideas: `content_ideas.md` wrote `Problem → Fix`, the handbook had
  ASCII, and `byName` matched nothing — so a format that had been registered all
  along read as unregistered. There is now a check for it.
- `Default for` — a new optional field, and the reason it exists is a defect the
  milestone test caught. `problemFix`, `mistakesList`, `saveThisList` and
  `doThisNotThat` all support `imageSlideshowReel` and all serve `nonFollowerReach`,
  so all four scored 3 and the tie broke by declaration order. The recommendation for
  "Ria refuses to brush her teeth" came back as **Mistakes List**. A default that
  breaks only ties, and never outranks a real score difference, fixes it: the
  milestone idea now returns **Problem → Fix**. Set on `pov` (reel, trialReel),
  `problemFix` (imageSlideshowReel, carousel), `saveThisList` (carousel, staticImage).
- `recommend()` returns **null** when nothing matches. No silent fallback to
  `problemFix` — that is how a format gets tested five times as the wrong shape and
  the results become unreadable.

**Still open inside this task:** the remaining 34 formats, which is T-22 data entry.
Formats 13–16 landed under T-7c, because nine existing ideas referenced narrative
shapes no registered format covered.

### T-14 Add `imageSlideshowReel` and `story` to `ContentFormat`

Four of your six content types exist. Two are missing entirely, and they are not
equivalent:

- `imageSlideshowReel` — Ria + Rio + Mumma telling a story through generated images.
  Distinct from `reel` because pacing and slide count behave differently.
- `story` — ephemeral, 9:16 full-bleed, no caption surface.

Carousel must not be a Reel script split into slides — it needs its own generation.

Also: **the carousel canvas is 1080×1440, which is 3:4.** Instagram feed ratios are
1:1, 4:5 and 1.91:1. 3:4 is outside all of them and will crop.

`format_handbook.dart` already references both new ids in
`kContentTypeIds`, and `kUnimplementedContentTypes` names them explicitly, so the gap
is visible rather than discovered at generation time. Moving the `ContentFormat` enum
into the handbook is part of this task, as decided in T-13.

### T-15 Unblock the series axis

`prompts.dart:230-231` forbids any series label outright:

> *"Never use the old 'Ria's Little Heart' series label, **or any series label**."*

So seven new series cannot reach the script generator at all. Rewrite that rule to
permit the seven, while still banning the retired name.

### T-16 Six text call sites send no `thinkingConfig`

The thinking-budget bug that produced truncated, unparseable JSON was found and
fixed in the caption call, then never applied to the four 8,192-token calls, which
are the most exposed:

- `main.dart:158-165` · `prompt_builder.dart:176-180` and `:336-344`
  · `gemini_client.dart:30-37`
- versus the fix at `caption_generator.dart:196-202`

### T-17 Delete the standalone generators

Once T-9 lands: `caption_generator.dart`, `reply_assistant.dart`, the separate
story-check and reply-suggestion entry points. Hook, caption, CTA, hashtags, pinned
comment and five replies all come from one call.

### T-18 Delete the unreferenced UI

| Screen | Evidence |
|---|---|
| `QualityCheckScreen` (`quick_content.dart:2564`) | fully implemented, never pushed |
| `ShotPlannerScreen` (`shot_planner.dart:10`) | `main.dart:1278` shows a SnackBar redirecting elsewhere |
| `HomeScreen` (`main.dart:503`) | legacy, one appBar icon away |
| `StoryInputScreen` (`main.dart:1699`) | only from legacy `HomeScreen` |

Carousel, Trial Reel and Single Image each have **three entry points**. Consolidate.

---

## Stage E, the library and the six tabs

### T-19 The idea codegen script

`dart run tool/sync_ideas.dart` compiles `content_ideas.md` into Dart. Prompt
construction stays synchronous, `const` survives, a malformed line becomes a compile
error instead of a startup crash.

**The parser already exists and is proven.** `tool/check_ideas.dart` parses the file
correctly and `tool/dump_ideas.dart` reports every axis value. Two conventions it
handles, both discovered the hard way:

- **Two bold spellings.** `content_ideas.md` writes `- **id:** value` with the colon
  *inside* the bold; `content_formats.md` writes `- **ID**: value` with it outside.
  Matching only one yields zero fields from a file that plainly contains them, and it
  looks exactly like a data bug.
- **Two field shapes.** Older ideas put one field per line; newer ones pack them as
  `- **Series:** x | **Format:** y | **Goal:** z`. Only the first fragment carries the
  leading `-`, so the dash has to be optional — otherwise every field after the first
  on a packed line is silently dropped.

Remaining requirements:

- **Do not gitignore the generated file.** The usual `*.g.dart` convention would mean
  a fresh clone fails to compile.
- The parser must read `Series`, `Pillar`, `Content Type`, `Narrative Format`,
  `Production Method`, `Goal`, `Age`, `Characters` and `Test Number`. It normalises
  Trial Reel into Reel today.
- Adopt the **`JUGAADU-MUMMY-001` ID scheme**, not a bare sequence number. The
  dashboard filters on series, so a flat integer cannot answer "how manythm is this".
- The document's own prose also uses `###` headings, so count sections by carrying an
  `id`, not by heading count. Otherwise the file reports 59 ideas when it holds 57.
- Prose sections must be skipped, not validated as broken ideas.

`QuickIdea` has already moved to `lib/models/`, which was the prerequisite.

### T-20 Four tabs do not exist

| Target tab | State |
|---|---|
| Ideas | Partial — split across Idea Vault, Saved Stories and Plan→Hooks |
| Create | Fragmented — five cards where there should be one |
| **Calendar** | **Does not exist** |
| **Analytics** | **Does not exist** — Plan→Results is manual text entry |
| **Experiments** | **Does not exist** — no infrastructure for 1/5 through 5/5 |
| Brand | Scattered across Settings, Promo Comments and `BrandDefaults` |

The AI Content Brief screen — Series, Pillar, Format, Content Type, Production
method, Goal, Characters, Duration — **is** the Create screen. Build that, not ten
buttons.

Analytics must capture the fields the spec lists, including **non-follower %** and
**watch time**, not just views and likes. Non-follower % is the only number that
distinguishes discovery from distribution, and it is the one your whole Trial Reel
strategy rests on.

### T-21 Format recommendation with visible reasoning

The scoring and the one-line reasoning ship in `FormatLibrary.recommend()` and
`FormatSpec.reason()` (T-13). What is left is the UI: show the recommendation and the
reason next to the AI Content Brief.

Rules it must keep:

- Never silently substitute. A null recommendation is surfaced as a **missing
  format**, naming what was missing.
- The recommendation must be **overridable**. You know your page better than the
  heuristic does.
- The reason must be the real one. Content type scores 2 and goal scores 1, and the
  `Default for` tie-break is declared in the data, not hidden in code — otherwise the
  explanation and the answer drift apart.

### T-22 The remaining 34 formats

Data entry into `content_formats.md`, same nine fields, then
`dart run tool/sync_formats.dart`. **No new design work** — the schema, the id
convention, the parser and the checks all exist.

Two rules from the shipped code:

- **Never renumber an existing id.** Ideas and posted performance reference these, so
  a renumber silently rewrites history.
- **One content type gets at most one `Default for`.** Claiming the same type twice is
  invisible from inside a single format and silently makes the loser unreachable.
  `tool/check_formats.dart` now rejects it.

---

## Stage F, cleanup

### T-23 Release signing and applicationId

Release is signed with the debug keystore and `applicationId` is still
`com.example.reel_audio`. Not installable from Play.

- `build.gradle.kts:32-38` and `:19`, both TODOs unresolved
- ProGuard and resource shrinking are off, for an APK carrying FFmpeg natives

### T-24 Rotate the keys, delete `backend/`

`lib/secrets.dart` holds a live Gemini and ElevenLabs key. Correctly gitignored, but
keys compiled into an APK are extractable. `backend/.env` holds a live OpenAI key for
a directory with **no source code**, which also contradicts `APP_OVERVIEW.md:100`.
Only you can do this.

### T-25 Remaining duplicated store code

~450 lines across six near-identical implementations, with `_path()` copied nine
times and inconsistent error handling — four swallow to `[]`, one crashes. A generic
`JsonStore<T>` absorbs this.

### T-26 Unused dependencies

`hive`, `hive_flutter` and `cupertino_icons` are declared and never imported.
`google_generative_ai` is Google-deprecated **and has no `thinkingConfig` support**,
which is why T-16 cannot be fixed inside `GeminiClient`.

### T-27 The settings key is honoured by 2 of 10 paths

Six call sites read `secrets.dart` directly, so a user who configures Settings sees
"AI generation enabled" and gets it honoured in one feature out of ten. The key is
also stored unencrypted in SharedPreferences, and the `AIza` validator would reject
the app's own `AQ.`-prefixed key.

### T-28 Documentation

`README.md` is untouched Flutter template boilerplate — "A new Flutter project", the
same string as `pubspec.yaml:2` and `web/index.html:21`. `APP_OVERVIEW.md` is the real
doc and is good, but its dashboard table omits Caption Generator. Eight of the last
ten commits are titled `commit`. `debug_report.txt` references two deleted files. The
launcher label is `reel_audio`, not "Fun Learning With Palak".

### T-29 Tests

Beyond the seven that do not compile: **zero coverage** on the Gemini JSON parse path
and `_stripFence`, `geminiBusyMessage`, the model-404 memory cache,
`AIProviderWithFallback` degradation, `FormatAdapter`, `caption_renderer.dart` canvas
drawing, `video_builder.dart` FFmpeg assembly, and backup write/restore. Highest
value first: caption rendering goldens, Gemini parsing, fallback degradation.

---

## Confirmed and already satisfied

Recorded so these are not re-litigated. No action.

| Point | Where it already lives |
|---|---|
| One generator, no standalone caption/hashtag/hook tools | T-17 |
| Every generate returns the complete package | T-9 |
| **Do not claim a specific view count.** No code promises 150K; `main.dart:477` explicitly steers away from "chasing viral". Keep it that way | verified |
| Stage A idea vs Stage B content are separate | T-19 keeps ideas metadata-only, no scripts in the library |
| One idea decides the format, not the other way round | T-21 |
| Trial Reel needs its own generation, not a flag | T-13, T-14 |
| Character descriptions injected verbatim, library not hardcoded subsets | done |
| Character consistency rules appended to every image prompt | done, `characterLockBlock` |
| Master strategy prompt inside the app, not sent blindly per type | T-9 |
| Keep Story Reel Maker as-is; do not rebuild the pipeline | confirmed, out of scope |

---

## Suggested additions

### S-1 The visual style question, settled properly

You have now asked for a studio-free style description twice, and I have pushed back
twice, so here is the resolution rather than another round.

**Your underlying request is right and I agree with it.** Building the app around the
word "Pixar" is bad practice: `NOT kawaii-chibi` and `NOT flat 2D` are negative
constraints against looks some generators will not recognise, and a studio name is not
yours to depend on.

**Where I think the conclusion goes wrong** is the replacement wording. Both proposed
descriptions — *"soft watercolor children's illustration"* and *"soft pastel
children's storybook illustration, warm cream background, gentle hand-painted
texture"* — describe a **2D hand-painted look**. Your seven character renders in
`assets/characters/` are 3D. Adopting either would send every generation toward an
appearance your reference art does not have.

You do not have to choose between them, because the style is already a single constant
(`BrandDefaults.visualStyle:29`) read by `prompts.dart` and injected by
`buildBrandContext`. **Changing it is one line.** So the decision is reversible, which
means it does not need to block anything — including T-12.

The version that satisfies your actual requirement (own vocabulary, no studio name)
without contradicting your assets:

```
Soft 3D storybook children's illustration, warm Indian home settings, pastel palette,
rounded friendly shapes, expressive faces, clean backgrounds, preschool-friendly.
NOT flat 2D, NOT watercolor, NOT kawaii-chibi.
```

If you would rather go 2D, that is a legitimate creative decision and I will do it —
but the seven character images then need regenerating, or the library will look wrong
from the first post.

### S-2 One-line identity locks for the remaining three characters

You supplied the wording for Mumma, Papa, Daadi and Teacher. Mumma is implemented with
a full profile. **Papa, Daadi and Teacher are one `const` each** in
`CharacterLibrary` (`brand_system.dart:107-162`) and then added to `all`. Not blocked,
just not written.

Your consistency rules are already enforced in `characterLockFor` (`brand_system.dart:180-189`)
except two: *"keep proportions consistent"* and *"keep facial identity consistent"*
are not stated. Add both — they are the rules that matter most when a batch of 20
images is generated across multiple calls.

### S-3 `content_ideas.md` is not the source of truth yet

It claims ideas are not hardcoded into Flutter. They are — `kDay14Posts` at
`content_ideas.dart:384`. T-19 fixes this, but until then **editing the `.md` changes
nothing**, which is worth knowing before you rely on it.

### S-4 Three unrelated copies of a content idea

The same ideas exist in three places with different shapes: `content_ideas.md` (57),
`kDay14Posts` (24 seeded), and four unbundled `assets/ideas/*.md` files. Nothing
reconciles them. Decide which is authoritative and delete or generate the rest.

Note that those four files are **not your format handbook** — they are Reel, Carousel,
Static and Trial Reel *idea* lists, 9-15 KB each. The handbook still has to be
written. But they are worth reading before T-22, because they show which formats you
have actually been thinking about.

### S-5 The parser has a second, unreached bug

`content_ideas.dart` `_parseComments` has a guard that can never be reached, because
the regex already matches every numbered line. Harmless today, wrong regardless.

### S-6 The reach score needs a label and eventually calibration

The ten dimensions are heuristics the model applies to its own output. **Label them
in the UI as internal heuristics, never predictions.** And do not surface a number
until there is real posted data behind it — a self-score has no calibration without it.

This is the same instinct behind your point 10: ambition is not a promise. Keep the
scoring honest in the same way.

### S-7 The format-test discipline needs a home

"Test a format five times before judging it" is a rule the app should enforce, not one
you remember. `Test Number` belongs on the idea, and the Experiments tab should refuse
to conclude on fewer than three.

### S-8 `/content/` as a directory is fine; `brand_rules.md` and `characters.md` as
*files* is not

Splitting into `formats.md`, `series.md` and `ideas.md` is right — those are data that
changes. Putting brand and characters back into markdown recreates the drift just
removed: 30 stale watercolor strings, four character description sets, three age
ranges.

Keep those two in Dart `const`, so prompt builders stay synchronous. The other four
files in the proposed layout belong in `/content/`.

### S-9 Delete `tool/fix_style.ps1` and `tool/extract_quick_idea.ps1` when you are happy

Both were one-shot migrations. `fix_style.ps1` is safe to re-run.
`extract_quick_idea.ps1` is **not** — it will cut the wrong lines a second time.

---

## Order

```
```
DONE  T-1   all 8 tests pass         tests run for the first time
DONE  T-2   posting pack saves       found a dead library and a RangeError
DONE  T-4   hashtags no longer fixed every post carried the same 5
DONE  T-5   CTA menu no longer contradicts the brand rule
DONE  T-16  thinking config on 3 of 4 sites; SDK blocks the fourth
  |
T-2b  library viewer               the save persists; nothing can see it
T-3   migrate QuickIdea            last legacy-id rendering bug
T-24  rotate keys            only you
T-23  signing + appId        before any real install
T-6   age audit              grep and confirm
  |
DONE  T-13  content_formats.md + format_handbook + codegen + checks
DONE  T-7   content_axes.dart  (vocabulary only; rewiring is T-7e)
DONE  T-8   IdeaStatus enum + fromLegacy (storage migration to do)
DONE  T-7c  formats 13-16: Quick Tip, Mini Story, This or That, Question -> Answer
  |
T-7b  resolve 57 ideas        NEEDS YOUR DECISIONS, largest remaining
T-7d  migration mapper        after T-7b, dry-run first
  |
T-9   one package type       keystone; needs the axes vocabulary
  +-- T-10 one caption spec, one checker
  +-- T-11 wire the fallback
  +-- T-12 keep the script   unblocks narration + dialogue
  +-- T-14 imageSlideshowReel + story, fix the 3:4 canvas
  +-- T-15 unblock series
  +-- T-7e buckets -> axes    with the format work
  +-- T-8  storage migration for status
  +-- T-17 delete standalone generators
  +-- T-18 delete unreferenced UI
  |
T-19  sync_ideas.dart        parser already proven by check_ideas
T-20  four missing tabs
T-21  recommendation UI      engine already shipped in T-13
T-22  remaining 34 formats   data entry only
  |
S-2   three character locks  15 min, unblocks a listed blocker
T-25  generic JsonStore
T-26  unused deps
T-27  settings key
T-28  docs
T-29  tests
```

**T-7b is the gate.** Everything downstream needs an idea that knows its own pillar,
series, production method and narrative format, and 57 ideas currently know none of
them. Doing T-9 first would mean designing a `ContentPackage` against a schema whose
inputs are undefined.

Do not start Stage E until Stage D passes, and do not start T-7e or T-8's storage
migration outside Stage D. They touch the same ten files as the format work, and
splitting them is how a third vocabulary appears.
