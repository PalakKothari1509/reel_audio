# Redesign Plan, Fun Learning With Palak

**Scope: open work only.** Completed items are removed as they land. The audit that
produced this list is history and no longer tracked here; its findings are folded into
the tasks below.

**Last verified:** `flutter analyze lib` → **91 issues, 0 errors**.
`tool/check_formats.dart` → all checks pass, 12 formats.
`tool/check_ideas.dart` → 57 ideas, 0 complete, 25 need review, 32 invalid.
**Branch:** `copilot_post`. Untracked: `content_ideas.md`, `content_formats.md`,
`master_prompt.md`, `lib/models/quick_idea.dart`, `lib/format_handbook.dart`,
`lib/content_axes.dart`, `tool/*.dart`, `tool/*.ps1`.

---

## Read this first

Three decisions are still open. Two block work below; one does not.

| Open | Blocks |
|---|---|
| **Pixar-derived or storybook/watercolor** | Nothing. The `STYLE` constant makes it a one-line change (T-12) |
| **The 50-format handbook** | **Closed.** 12 formats are written, generated and checked (T-13 done). The other 38 are data entry (T-22) |
| **Naming of the content axes** | T-7. Decided, needs recording in code |

---

## Stage A, live defects — 1 task left

### T-1 `test/widget_test.dart` does not compile

`CreatorHomeScreen` takes ten required callbacks. The test passes nine, omitting
`onCaptionGenerator`, so the file fails to compile and all seven tests are dead.

- `test/widget_test.dart:15-25` · `creator_home.dart:15,28`

Add the missing argument. **This is one line and it gates everything else** — while
it is broken `flutter test` fails, so CI is red and no future change can be verified
by test.

Two related things in the same pass:

- CI only triggers on `main` and `video-slideshow` (`build.yml:12`). You are on
  `copilot_post`, so **CI has not been running on your branch.** Add it.
- No mocking library in `dev_dependencies`, so nothing touching `http` or
  `path_provider` is testable. That is why the untestable areas below are untestable.
  Add `mocktail` or `http`'s `MockClient`.

---

## Stage B, data loss — 2 tasks left

### T-2 `posting_pack.dart` cannot save anything

`_saveToLibrary` shows "Content Library integration coming soon".

- `posting_pack.dart:581-586`, called from `:499`

This is the single widest gap in the app. `GeminiClient` produces a complete package
in one call, `FormatAdapter.adaptAll` converts it to four formats, and the result
**cannot be persisted**. The flow stops at "generated" and never reaches "in my
library".

The plumbing behind it already exists — `ContentLibraryStore`,
`ContentLibraryItem.createFromPackage` — and its silent-wipe bug is fixed. This is
wiring, not construction.

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

### T-7b Resolve the 57 ideas — **not started, needs your decisions**

`tool/check_ideas.dart` classifies rather than guesses. Current state:

```
57 ideas, 57 unique ids, 0 duplicates
  0 complete
 25 need review
 32 invalid
```

| Blocker | Count | Why it cannot be automatic |
|---|---|---|
| `pillar` missing | **57** | Every single one. Never inferred from topic text — that is how 57 ideas quietly acquire 57 wrong pillars |
| `productionMethod` missing | 24 | Usually derivable from content type, but "Mixed" vs "Image slideshow" is a judgement |
| `narrativeFormat` unregistered | **9** | Quick Tip 4, Mini Story 2, This or That 2, Question → Answer 1 — see T-7c |
| `series` unmappable | 23 | learning-through-play 10, little-stories 9, cuty-lessons 2, the-casts 2 — see below |
| `goal` unmappable | 6 | Community 3, Engagement 2, "Reach + Shares" 1 |
| `status` legacy | 1 | `Trial` → `idea` |

**Series: 23 ideas have no correct target**, and this is the one genuinely large
decision left:

- `learning-through-play` (10) was a **pillar**, not a series. Its content is fine; the
  bucket it lived in was never a series identity. These need a series chosen from the
  seven.
- `little-stories` (9) is the retired "Little Stories, Big Lessons" name, which the
  current direction moved away from.
- `cuty-lessons` (2) — Cuty is a character, not a series.
- `the-casts` (2) was audience voting. `parentRelatable` would be plausible and wrong:
  both its ideas optimise for comments.

I did **not** map these. `little-stories` → `parentRelatable` is a one-line change that
would look right and misfile nine ideas.

### T-7c Fix the 9 ideas with unregistered formats

Do not silently substitute. Either add the format to `content_formats.md` or map it
explicitly:

| Format | Ideas | Candidate mapping |
|---|---|---|
| Quick Tip | 4 | genuinely new — one activity, one beat. Spans `Try This At Home` and `Can Your Child Figure It Out?` |
| Mini Story | 2 | genuinely new — Cuty rescue, treasure hunt. Short-narrative shape, and the 12 have none |
| This or That | 2 | genuinely new — audience vote. Goal `comments` |
| Question → Answer | 1 | closest is `Exact Script`; the bedtime question is literally a quotable line |

Three of the four look like real gaps rather than naming drift. Adding formats 13–16
is data entry against a schema that now exists.

### T-7d One migration mapper

Old data → new axes, writing only `complete` and `auto-mapped` ideas and emitting
`needs review` / `invalid` for the rest. Dry-run first; `check_ideas.dart` already
proves the report shape.

### T-4 The static hashtag injection defeats the hashtag rule

`hashtagPool.take(5)` injects a **fixed five tags into every post**:
`#funlearningwithpalak #noscreenactivities #playbasedlearning #montessoriathome
#toddleractivities`. Meanwhile the generation prompt asks for five tags relevant to
the actual topic.

- `brand_system.dart:551` · `ai_provider.dart:72` · `caption_generator.dart:294`

Every post currently gets the same five. This is the most visible quality bug left,
and the one most likely to be costing reach.

Also: `#ahmedabadmoms` sits in the pool, which narrows a national audience.

Fix by removing the static injection, not by extending the pool. The pool can stay as
brand-tier tags the model *may* use, never as the answer.

### T-5 The CTA menu fights the CTA rule

`ctaOptions` injects all five options into every prompt, including "Follow for daily
play ideas". `prompts.dart:334` **explicitly bans** "follow for more" as engagement
bait. The app instructs the model to do the thing another file forbids.

- `brand_system.dart:552` and `:37` vs `prompts.dart:334`

Separately, `prompt_builder.dart:426` hardcodes `ctaLine: kDefaultCtaLine` rather
than generating one, so **every reel posts an identical CTA** while
`ContentPackage.cta` is per-bucket. Two CTAs, one screen. Decide which wins.

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

- `content_formats.md`, 12 formats, nine canonical fields each
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

**Still open inside this task:** the remaining 38 formats, which is T-22 data entry.

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

### T-22 The remaining 38 formats

Data entry into `content_formats.md`, same nine fields, then
`dart run tool/sync_formats.dart`. **No new design work** — the schema, the id
convention, the parser and the checks all exist.

Two rules from the shipped code:

- **Never renumber an existing id.** Ideas and posted performance reference these, so
  a renumber silently rewrites history.
- Run `tool/check_formats.dart` after each batch. It validates that every
  `bestContentTypes` and `bestGoal` resolves, which is what caught the twelve bad axis
  references on the first parse.

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
T-1   tests compile          gates all verification
T-2   posting pack saves     widest gap: generate -> library
T-3   migrate QuickIdea      last legacy-id rendering bug
T-24  rotate keys            only you
T-23  signing + appId        before any real install
  |
T-4   hashtags               most visible remaining quality bug
T-5   CTA                    resolves a live contradiction
T-6   age audit              grep and confirm
  |
DONE  T-13  content_formats.md + format_handbook + codegen + checks
DONE  T-7   content_axes.dart  (vocabulary only; rewiring is T-7e)
DONE  T-8   IdeaStatus enum + fromLegacy (storage migration to do)
  |
T-7b  resolve 57 ideas        NEEDS YOUR DECISIONS, largest remaining
T-7c  9 unregistered formats add or map, do not substitute
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
T-22  remaining 38 formats   data entry only
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