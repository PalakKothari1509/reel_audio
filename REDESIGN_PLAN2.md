# What Still Needs Building

Fun Learning With Palak â€” revised product plan.

**Principle:** the app is a **content decision system first, and a content
generator second.** Stabilize the content system, then make generation consume
it, and only later build learning/analytics.

**North star:**

```
IDEA â†’ CLASSIFY â†’ EVALUATE â†’ READY TO CREATE? â†’ CONTENT PACKAGE â†’
GENERATE â†’ VALIDATE â†’ PRODUCE â†’ PUBLISH â†’ REAL RESULT â†’ LEARN â†’
BETTER DECISIONS
```

The app answers: **"What should I make next, why should I make it, and how
can I realistically produce it?"** â€” not merely "What can AI generate?"

**How to read this:** tasks are grouped by phase. Anything marked **YOURS**
cannot be finished by me â€” it needs your decision or your keys.

**Last checked:** `flutter analyze` â†’ 0 errors. `flutter test` â†’ 36
tests, all passing. `check_pillars` passes. `check_axes`, `check_ideas` and
`review_content` report the open axes below â€” OPEN is the correct result for
unresolved taxonomy, not a failure.

---

## The immediate milestone

**Finish the content decision layer before rebuilding the generation layer.**
Immediate repo work is **Phase 1 + Phase 2** only â€” not Analytics, Calendar,
Experiments, storage refactoring, or a large UI rewrite.

**Phase D is complete.** All 57 ideas now have explicit verdicts in
`tool/idea_decisions.csv`: **41 KEEP**, 7 REWORK, 3 ARCHIVE, 6 DELETE. Only `keep`
ideas are sync candidates (41 active). The 7 REWORK ideas need their noted issues
fixed before they can sync. **Phase 1 taxonomy is complete** â€” all seven axes are
resolved for KEEP ideas. The 2 Narrative Format and 6 Goal items still OPEN are
ARCHIVE/DELETE/ambiguous source and do not block the sync set. Only `approved`
rows get written. `OPEN` is not approval; `suggested` / `needsReview` /
`invalid` / `archiveCandidate` are not `approved`.

The 12 approved new ideas remain **deferred** â€” they wait in
`tool/approved_12_reconstruction.md` (temporary, non-authoritative) until
original source details arrive.

#### The 57-idea classification state

| Axis | Decided | Still open |
| --- | --- | --- |
| Pillar | **55 approved, 2 archiveCandidate** | **0** |
| Series | **51 approved, 2 archiveCandidate** | **4 (DELETE)** |
| Narrative Format | 19 approved, 12 suggested | 2 (1 needsReview, 1 invalid) |
| Content Type | 57 in source | 0 |
| Production Method | **51 approved, 2 archiveCandidate** | **0** |
| Goal | **47 approved, 4 from source** | **6 (2 ARCHIVE, 2 DELETE, 2 ambiguous)** |
| Status | done | 0 |

### How to clear it

```bash
dart run tool/review_sheet.dart productionMethod
dart run tool/review_sheet.dart goal
```

The 57-idea taxonomy is **complete for the sync set** (41 KEEP ideas). Only the 2 Narrative Format and 6 Goal items remain OPEN, and those are ARCHIVE/DELETE or have ambiguous source goals â€” they do not block the active library.

### The 23 series with no obvious home â€” RESOLVED

All four legacy series have been mapped:

| Old name | Ideas | Resolution |
| --- | --- | --- |
| `learning-through-play` | 10 | Was a pillar, not a series â†’ mapped to **Can Your Child Figure It Out?** (6), **Life With Ria & Rio** (1), deleted (3) |
| `little-stories` | 9 | Retired "Little Stories, Big Lessons" name â†’ mapped to **Life With Ria & Rio** (8), deleted (1) |
| `cuty-lessons` | 2 | Cuty is a character, not a series â†’ mapped to **Can Your Child Figure It Out?** (1), deleted (1) |
| `the-casts` | 2 | Audience voting â€” neither post is relatable â†’ **ARCHIVE** (no series) |

The legacy/non-content escape hatch (Phase 1.3) is no longer needed for these â€” they have explicit current-series decisions in `tool/series_decisions.csv`.

### Two ideas that should not be forced

- `day14-favorite-format` â€” asks the audience which format worked best. It
  gives a parent nothing to save or send. Already marked `archive_candidate`
  rather than forced into a pillar.
- `st-ria-same-toy` and `lp-kitchen-counting` â€” both rest on a beat
  description because they have no Topic or Lesson text. Marked `beat_only`
  so you know the evidence is weaker.

### Two review items to decide by hand

- `day11-4year-skills` â€” don't decide from the title. Compare the actual
  child outcome with `day6-3year-skills` (its twin, already DO).
- `day16-voted-mission-won` â€” is it educational content, or
  community/announcement/meta? If it's not educational content, don't force
  it into a pillar.

---

## Phase 0 â€” Security & safety (parallel, before release)

**YOURS.** Audit and rotate exposed keys (`lib/secrets.dart` Gemini +
ElevenLabs, the OpenAI key in `backend/`, any `.env`/config/committed
credentials). Determine for each: used? where? production? obsolete? safe?
Long-term, the Flutter APK should not contain production provider secrets â€”
route through a backend/secure API. **Do not build a new backend yet** â€”
first understand what exists. Deliverable: `SECURITY_AUDIT.md`.

---

## Phase 1 â€” Stabilize the content taxonomy (NOW)

Lock the current taxonomy and finish the 57-idea migration. **Do not add
pillars, series, content types, narrative formats, production methods, goals,
or lifecycle states** unless a real workflow requires it.

**Classification answers "what is this?"** (pillar, series, content type,
narrative format, production method, goal, status). **Evaluation answers "is
this worth producing?"** (share trigger, open loop, voice compatibility,
reach candidacy, production compatibility, ready state). Never mix the two:
`Pillar = DO` does not mean "good idea = YES."

Migration workflow: `content_ideas.md` â†’ `review_sheet` â†’
`idea_decisions.csv`. **Automation proposes; a human approves.** For each
idea: classification + evaluation + editorial decision (KEEP / REWORK /
ARCHIVE), separate from lifecycle `status`.

---

## Phase 2 â€” Build the quality-gate system (NEXT)

Once classification is trustworthy, build the evaluation layer. This is where
the app becomes a decision system.

- **Share Trigger** â€” structured: sender, recipient, situation, reason.
  Validated as PASS / FAIL / UNKNOWN. PASS needs all four; FAIL is generic
  ("parents will share because it's relatable"); UNKNOWN is insufficient
  information. Never convert UNKNOWN â†’ PASS or UNKNOWN â†’ FAIL.
- **Open Loop** â€” same PASS / FAIL / UNKNOWN model. Only require it where
  the selected narrative/content strategy benefits from one. Don't force fake
  open loops onto every idea.
- **Voice Mode** â€” replace `worksWithNoVoice` with `voiceMode`: `none` (must
  work through visuals/text/actions/expressions), `optional` (voice
  enhances), `required` (genuinely depends on audio).
- **Production Compatibility** â€” keep separate from idea quality. A good idea
  that needs real-life child footage is "needs filming," not "bad idea."
- **Ready-to-Generate Gate** â€” before Gemini is called: classification
  complete? share trigger valid? open loop valid where required? voice mode
  defined? production method, goal, content type, narrative format selected?
  enough source information? READY â†’ generate; NOT READY â†’ fix first.

---

## Phase 3 â€” Separate Idea from ContentPackage (THEN)

The major architectural change. An **Idea** is the strategic concept ("child
refuses to brush teeth"). A **ContentPackage** is a specific execution/test
of that idea. One idea can create many packages, which makes experimentation
possible without destroying the original idea.

One canonical `ContentPackage` model: identity (id, ideaId, createdAt,
updatedAt), classification (the 7 axes), strategy (audience, problem,
lesson, hook, shareTrigger, openLoop, voiceMode, cta, reachCandidacy,
productionCompatibility), creative (title, script, narration, dialogue,
caption, hashtags, scenes[]), production (productionMethod, shotList,
imagePrompts, productionNotes), publishing (eventually publishedAt, platform,
postUrl), experiment (eventually experimentGroup, testNumber, testCount).

- **Preserve a classification snapshot** when a package is generated, so
  redefining a format later doesn't retroactively change old content.
- **Make narration and dialogue first-class** â€” never throw away Gemini
  output. Store them separately to support future voice generation and
  no-voice production.

---

## Phase 4 â€” Unified generation architecture (THEN)

```
Idea â†’ Strategy â†’ ContentPackage â†’ AI Content Service â†’ Validation â†’
Production Adapter
```

One AI boundary (`AiContentService`); screens should not talk to Gemini
directly. **The app is the strategy authority; AI is the creative execution.**
The app supplies the classification + strategy; Gemini creates hook, script,
narration, dialogue, scene plan, caption, CTA, hashtags, image prompts.
Hard-validate every fixed requirement (e.g. `hashtags.length == 5` â€” repair
or regenerate). Wrap existing working functionality through production
adapters (`ContentPackage â†’ ReelProductionAdapter â†’ existing Reel Maker`,
likewise Carousel/Image) rather than rebuilding Reel Maker.

---

## Phase 5 â€” AI reliability (THEN)

Prioritize parser tests: malformed JSON, markdown-wrapped JSON, missing
fields, wrong types, truncated response, unexpected fields,
Unicode/Hinglish/Devanagari, empty response, timeout, API error.
Architecture: Gemini â†’ parse â†’ schema validation â†’ repair/retry â†’
ContentPackage. Separate testing layers (AI parser, ContentPackage,
validation, production, repository), then one small E2E smoke test.

---

## Phase 6 â€” Storage refactor (LATER)

Only after ContentPackage is stable. The six near-identical storage classes
(~450 lines, inconsistent error handling) eventually become Repository â†’
Storage Adapter â†’ JSON/filesystem. Don't do this early â€” otherwise you
refactor storage around models that are still changing.

---

## Phase 7 â€” UI simplification (LATER)

Stop exposing implementation details (Caption Generator, Hook Generator,
Hashtag Generator, Trial Reel Generator â€” the first is already gone).
**Ideas** becomes the control center (filters: ready to generate, needs
review, needs share trigger, needs classification, untested, testing 1/5â€¦5/5,
archive candidates). **Create** has two entry points (choose existing idea /
create new idea) and shows the classification + evaluation before Generate.
**Library** stores ContentPackages, not disconnected script/caption/image/
reel. **Reel Maker** keeps its working workflow, connected through
ContentPackage â†’ ReelProductionAdapter. **Settings** eventually centralizes
AppConfig so no screen independently decides which API key/model/config to
use.

---

## Phase 8 â€” Domain validation tooling

Keep the existing tools. Eventually add `dart run tool/check_content_system.dart`
to run formats, pillars, series, content types, production methods, goals,
statuses, ideas, share mechanics, and ContentPackage schema in one pass,
reporting a clear RESULT: FAILED with the specific gaps.

---

## Phase 9 â€” CI & testing

CI should eventually run `flutter analyze`, `flutter test`, domain checks, and
generated-file consistency checks. Also fix the README so it actually
describes the application.

---

## Phase 10 â€” Release hardening (before release)

applicationId, release signing, keystore, version, icons, README, CI,
release build, installation test. Security items from Phase 0 must also be
resolved.

---

## Phase 11 â€” Real content testing (after real posts)

The 5-test rule belongs in the domain model now, but the UI can wait. For a
format: 1/5 â€¦ 5/5. Do not conclude "Mini Story is bad" from one failed Reel.
The unit of evaluation is the experiment/format across sufficient real tests,
not one post. Distinguish **failed content** from **failed experiment**.

---

## Phase 12 â€” Analytics (after sufficient data) â€” DO NOT BUILD NOW

Analytics becomes useful only after Idea â†’ Classification â†’ ContentPackage â†’
Published content â†’ Real Instagram results. Then it can answer which
pillar/series/narrative format/production method/goal/combination performs
best, which formats have 5 tests, which ideas are still 1/5. That is actual
learning â€” not "AI says this could get 150K views." **The 150K prediction
score remains permanently out.**

---

## Phase 13 â€” Experiments (after real data)

Experiment = format + test 1â€¦5. Only after 5 meaningful tests should the
system suggest continue testing / promising / needs refinement / archive.
Design the exact verdict rules once real data exists.

---

## Phase 14 â€” Calendar (last)

Build after Ideas â†’ Approved â†’ Generated â†’ Ready. Calendar is a scheduling
layer, not a place to compensate for unclear strategy.

---

## Phase 15 â€” Advanced learning (eventual destination)

The system can eventually identify combinations (e.g. DO + Life With Ria &
Rio + Mini Story + Character Images + Relatability) and compare them â€” but
learned from real results, not predicted by AI.

---

## Development order

| Order | Work | Priority |
| --- | --- | --- |
| 1 | Finish 57-idea editorial classification | âœ… **Done** |
| 2 | Re-author the 12 missing ideas | â¸ï¸ Deferred (skipped for now) |
| 3 | Resolve legacy/non-content handling | âœ… **Done** |
| 4 | Resolve `day11-4year-skills` + `day16-voted-mission-won` | âœ… **Done** |
| 5 | Implement structured share trigger | âœ… **Done (Phase 2)** |
| 6 | Implement PASS / FAIL / UNKNOWN validation | âœ… **Done (Phase 2)** |
| 7 | Add open-loop validation | ðŸŸ  Next |
| 8 | Add `voiceMode` | âœ… **Done (Phase 2)** |
| 9 | Add Ready-to-Generate gate | ðŸŸ  Next |
| 10 | Design/finalize `ContentPackage` | ðŸŸ  **Phase 3 starts here** |
| 11 | Preserve narration + dialogue | ðŸŸ  Then |
| 12 | Separate Idea â†’ ContentPackage | ðŸŸ  Then |
| 13 | Build unified AI service | ðŸŸ  Then |
| 14 | Connect production adapters | ðŸŸ  Then |
| 15 | Harden Gemini parser/tests | ðŸŸ  Then |
| 16 | Refactor storage | ðŸŸ¡ Later |
| 17 | Simplify UI around Ideas/Create/Library | ðŸŸ¡ Later |
| 18 | Security/release cleanup | ðŸŸ¡ Before release |
| 19 | Real 5-test experiment tracking | ðŸŸ¢ After real posts |
| 20 | Analytics | ðŸŸ¢ After sufficient data |
| 21 | Experiments UI | ðŸŸ¢ After sufficient data |
| 22 | Calendar | ðŸŸ¢ Last |

---

## Clean-up work

| Task | Why it matters |
| --- | --- |
| Rotate your API keys | `lib/secrets.dart` holds live Gemini and ElevenLabs keys. Keys in an APK can be extracted. **`backend/` also holds a live OpenAI key and has no source code â€” what is it for?** |
| Release signing and app id | Still signed with the debug key, still called `com.example.reel_audio`. Not installable from Play |
| Settings key honoured in 2 of 10 places | Configure Gemini in Settings and most of the app ignores it |
| Remove unused packages | `hive`, `hive_flutter`, `cupertino_icons` are installed and never used |
| Google AI SDK is deprecated | And it has no thinking-budget control, which is why one large Gemini call can still return truncated text |
| Six near-identical storage classes | About 450 lines of repeated code with inconsistent error handling |
| Two `IdeaStatus` enums | `content_axes.dart` has the lifecycle ladder (idea â†’ â€¦ â†’ archived); `quick_content.dart` has a separate UI enum (idea / developing / ready / posted / reuse) with emoji and label. Only `idea` and `posted` exist in both, so the two ladders can drift. Consolidate when the Idea Vault moves to the model's ladder |
| README is template boilerplate | Says "A new Flutter project" |
| CI does not run on this branch | Only tests `main` and `video-slideshow` |

### File-by-file policy

Recorded so cleanup is deliberate, not a file-count reduction. The final
project is clean because every remaining file has a known purpose.

**Keep:** `lib/`, `test/`, `tool/`, `android/`, `ios/`, `web/` if still
supported, `assets/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`,
`.gitignore`, and the documentation that is part of the system:
`CONTENT_MODEL.md`, `content_formats.md`, `content_ideas.md`,
`REDESIGN_PLAN.md`, `README.md`.

**Review before deleting:** old generators, old screens and routes, duplicate
storage classes, old content JSON, obsolete scripts, old planning documents
(`master_prompt.md`, `POSTS_REVIEW.md`, `APP_OVERVIEW.md`, `MASTER_CONTENT.md`,
the chat-export `.md` files), temporary test files, and regenerable exports
(`tool/idea_classification_report.txt`, `tool/reach_candidates.csv`,
`debug_report.txt`).

**Remove only when confirmed obsolete:**

- `backend/` â€” **after the OpenAI key inside it has been rotated**. It has no
  source code and nothing references it, but the key is live until rotated.
- The 57 ideas and all content history â€” **never** deleted to make the folder
  look clean. They are curated through the Master Content Sheet (KEEP /
  REWORK / ARCHIVE / DELETE), not deleted by hand.

---

## Testing gaps

36 tests currently cover several quiet failure modes. Still untested: the
Gemini JSON parser, network calls, video assembly, and what happens when AI
fails.

**Worth knowing:** most file-reading code cannot be tested at all, because
the storage layer has no test seam. Three components now have one â€” the
promotion vault, the idea inbox, and the content library. The rest need the
same.

---

## Deliberately not being built

Recording these so they don't get re-proposed:

**A 150K potential score.** Seven scores across 85 ideas would be 595 numbers
with no evidence behind them, produced by guessing â€” and it would look like
data. You already decided this: *"learn from your real Instagram results
rather than manufacture a viral score."* The mechanics are checked honestly
instead, as pass / fail / unknown.

**Regenerating all the ideas right now.** New ideas would discard the 19
narrative formats and 12 pillars already decided, then restart the same review
on a bigger set.

**More formats before these 16 are proven.** A format should earn its place
because a real idea needs it â€” which is exactly how the last four got added.

**Rebuilding the video pipeline.** The existing Reel Maker works end to end.
Leave it.

**AI agents or autonomous posting.** Not until the classification work is
solid.

**Analytics, Calendar, Experiments, storage refactor, and a large UI
rewrite** â€” not until the content decision layer (Phase 1 + Phase 2) is
stable.

---

**One honest observation.** The classification work looks like paperwork and
is actually the most valuable thing in this list. Every later question â€” which
format works, which hook gets shares, which series grows the account â€” can
only be answered if each post was recorded with the right labels. Do it once,
properly, and the rest of the app gets easier. Skip it and you end up with
analytics that cannot tell you anything.

