# Content Model — What The App Means

**Status: draft for agreement. Nothing here is coded.**

This document exists to settle *what the words mean* before any code depends on them.
It is the "Model Freeze" step. Agreeing it is cheaper than discovering halfway through
a refactor that `ContentPackage` and "the Reel" were never the same thing.

**Nothing in this document is implemented.** If code and this document disagree, this
document is the error.

---

## 1. Why this had to be written down

The app currently has four different representations of "a finished post", and ideas
that get overwritten every time you generate a new version of them. Both are symptoms
of one missing idea: **an idea is not a piece of content.**

Once that is explicit, the rest follows.

---

## 2. The four things

```
Idea
  └── ContentPackage        one execution of that idea
        └── Test            one posting of that package
              └── Result    what Instagram actually did
```

| | What it is | How many per idea |
| --- | --- | --- |
| **Idea** | The content opportunity. "Ria refuses to brush her teeth." | one |
| **ContentPackage** | One decision about how to execute it | many |
| **Test** | One posting of that package, at one point in time | one per package |
| **Result** | What actually happened | one per test |

### Why an idea needs many packages

"Ria refuses to brush" can be run as a Mini Story, as Do This Not That, as an Exact
Script, as Problem → Fix. Those are four different hypotheses about the same situation.

If generating overwrites the idea, that history is gone and you can never learn which
hypothesis was right. **This is the foundation the 5-test rule stands on** — without it
there is nothing to count tests across.

---

## 3. Idea

The durable thing. Survives every execution.

```
Idea
├── id                     stable, never reused
├── title
├── topic                  what it is about
├── problem                the parent's situation
├── lesson                 what the child takes away
├── classification        see below
├── quality                see below
├── packages[]            ContentPackages
└── lifecycle             see below
```

**An Idea holds no script, caption or images.** Those belong to a package. An idea with
a caption baked in is a package that was never given the chance to be a different one.

---

## 3b. Delete and Archive are different things

**Delete** means "I don't want this idea in my app anymore."
**Archive** means "this idea is not active, but I want to keep
the history." They are not the same operation and must not
share a button.

Deletion is permanent only after confirmation:

```text
Delete this idea?
This will permanently remove the idea from the application.
                Cancel | Delete
```

### What deletion does to history

Deleting an idea must not automatically destroy unrelated
historical data.

```text
Idea
 └── ContentPackage
      └── Test
           └── Result
```

- An idea with **nothing generated from it** is removed
  completely.
- An idea that **already has packages, tests or results** is
  removed from the active ideas while its historical records
  are retained internally. "I don't want to see this idea
  anymore" and "destroy every result this idea ever produced"
  are different requests, and only the second one destroys
  data.

No idea has packages yet — `ContentPackage` is not
implemented — so every delete in the current app is a
complete removal. The rule above is the contract deletion
must honour the moment packages exist.

Both actions exist in the Ideas screens today, each behind
a confirmation dialog. Archive is a lifecycle status
(`archived`, §9); delete is a removal. A per-row Archive
action does not exist yet and is recorded here as the
design, not as work done.

---

## 4. Classification — what it is

Seven independent values. They answer seven different questions and must never be
merged back together.

| Axis | Question | Notes |
| --- | --- | --- |
| Pillar | What value does this give? | 5 values |
| Series | Which recurring world? | 7 values, may be none |
| Content Type | What is published? | 6 values |
| Narrative Format | How is it shaped? | 16 registered |
| Production Method | How is it made? | 6 values |
| Goal | What outcome? | one primary goal only |
| Status | Where is it? | see lifecycle |

**A goal is singular.** "Reach + Shares" is not a goal, it is a failure to choose. If
everything is the goal, nothing is, and later you cannot tell which objective worked.

### Classification is not evaluation

Saying an idea is `DO` / `Mini Story` / `Character images` describes it. It does **not**
mean it is a good idea. Those are separate questions and the app must never let the
answer to one stand in for the other.

---

## 5. Quality — is it worth making

Separate from classification, and deliberately able to disagree with it.

| Check | Answers | States |
| --- | --- | --- |
| Share trigger | Would a specific parent send this to another? | PASS / FAIL / UNKNOWN |
| Open loop | Is there something withheld? | PASS / FAIL / UNKNOWN |
| Voice mode | Does it work without narration? | none / optional / required |
| Reach candidacy | Can this reach non-followers? | yes / no / UNKNOWN |
| Production compatibility | Can our pipeline build it? | yes / no + reason |

### Two rules that are not negotiable

**UNKNOWN is a real answer.** Never force it into PASS or FAIL. "Insufficient data"
and "we haven't looked yet" are different from "it failed".

**A production problem is not a bad idea.** An idea needing real-life video when the
workflow generates character images is a *filming job*, not a rejection. The app must
never report "bad idea" for something it merely cannot conveniently make.

### Share trigger is structured

```
ShareTrigger
├── sender      a specific parent
├── recipient   a specific parent
├── situation   what is happening to them
└── reason      why they send instead of liking
```

"P-parents will share because it's relatable" fails. It names no one and gives no
reason. If a specific sender, recipient, situation and reason cannot be named, the
answer is FAIL — not "share trigger recommended".

---

## 6. ContentPackage — one execution

```
ContentPackage
├── id
├── ideaId                 which idea this executes
├── classificationSnapshot the values used AT GENERATION TIME
├── creative               what was written
├── production             what it needs to be made
└── lifecycle
```

### The snapshot is not optional

It records the classification **as it was when generated**.

Six months from now a format definition may change, or a series may be renamed. A
package generated earlier must not silently acquire the new meaning, or the performance
history becomes ambiguous. The snapshot is what makes old results still readable.

### Creative holds what is currently thrown away

```
creative
├── hook
├── title
├── script                 the full script
├── narration              voiceover text
├── dialogue[]             per-character lines, kept separate
├── scenes[]               one per scene
│     ├── number
│     ├── visualDescription
│     ├── dialogue
│     ├── narration
│     ├── onScreenText
│     └── imagePrompt
├── caption
├── cta
└── hashtags[]
```

**Narration and dialogue are separate fields.** The prompt already asks for both and
the app discards them. That is the clearest functional gap in the codebase: you are
paying for generation and throwing away one of its most useful outputs.

Keeping them separate also matters later — one feeds the voiceover, the other feeds
captions and on-screen text, and merging them loses both.

### Production is driven by production method

| Production method | The package must contain |
| --- | --- |
| Character images | image prompts + character consistency requirements |
| Real-life video | shot list, camera/action, props, timing |
| Image slideshow | slide plan, visual, text, duration |
| Text-based | text cards, timing, layout copy |
| Carousel | slide-by-slide copy and visual direction |
| Mixed | a combination, declared |

Production method is the bridge between strategy and the actual shoot. It is not
metadata — it decides what gets generated.

---

## 7. Test and Result

```
Test
├── packageId
├── testNumber             1..5
├── postedAt
└── result
    ├── views
    ├── reach
    ├── nonFollowerPercent   the only number that shows discovery
    ├── watchTime
    ├── completion
    ├── likes
    ├── comments
    ├── shares              more valuable than likes for this page
    ├── saves
    ├── profileVisits
    └── follows
```

### The experiment unit is the format, not the idea

**A format needs five meaningful tests before it can be judged. An idea does not need
five versions.**

```
Mini Story
  Test 1 → Idea A
  Test 2 → Idea B
  Test 3 → Idea C
  Test 4 → Idea D
  Test 5 → Idea E     → now a conclusion is possible
```

is a valid format experiment. Forcing every idea into five versions is not, and would
produce padding.

The unit needs a firm decision before the Experiments screen exists.

---

## 7b. One idea, one execution per generation

**Agreed decision. The app generates one content type at a time, never all four.**

```
Wrong:   Generate → carousel + reel + trialReel + staticImage
Right:   Generate ContentPackage → contentType = carousel → carousel adapter
```

An idea has many packages, but each package is **one concrete execution**. Generating
all four at once creates four candidates the user did not ask for, and none of them is a
decision.

Why it matters beyond tidiness: one generation is one publishing candidate. It uses
less of the AI budget, returns a smaller JSON payload, has fewer fields to validate,
and is fast. Most importantly, four formats generated from one idea is four
opportunities to get it half-right and no way to say which was the actual bet.

### Where this currently lives in the code

Recording these so they are not lost, **not** as work done. Line numbers
drift, so the table names symbols, not lines.

| Decision | Where it lives today | State |
| --- | --- | --- |
| Remove "Generate All Formats" | the `Generate All Formats (AI)` button calling `_generateAllFormats()` in Quick Content Studio, and the `Generate All Formats` button in `MultiFormatScreen` calling `_generateAll()` | recorded, not built |
| Remove the multi-format screen | `MultiFormatScreen` | recorded, not built |
| Remove the all-formats generation path | `_generateAllFormats()` and `_generateAll()` | recorded, not built |
| Generate one selected content type | Replaces all three above | recorded, not built |
| Drop the standalone Caption Generator | Dashboard entry (`CreatorHomeScreen.onCaptionGenerator`), its route in `main.dart`, `CaptionGeneratorScreen` in `caption_generator.dart` | recorded, not built |
| Caption is generated, and stays editable | Inside every package; editing survives generation | recorded, not built |
| Add delete to Promotion Comments | `PromoCommentStore.delete()`; each vault row has a delete button behind a "Delete this comment?" confirmation with **Cancel \| Delete** | **done** — covered by the widget test "deleting a promotion comment asks for confirmation first" |

Removal of the all-formats path and the standalone Caption Generator is
sequenced with the unified generation flow, not done before it: until one
content type can be generated, deleting the existing paths would leave the
app with no generation at all.

### One consequence that has to be handled with it

`ContentLibraryItem.createFromPackage` calls `FormatAdapter.adaptAll`, so **every saved
item today carries four format outputs** — that is how the library viewer and the
posting pack are built.

Once generation is one-at-a-time, a saved package will carry **one** format output, not
four. The viewer's "N formats" label, the posting pack's four tabs, and the test that
asserts all four formats must change together.

Doing the generation change without that would leave the library showing four
placeholders for content that was only ever generated once.

### Caption belongs to generation, not to a feature

Caption, hashtags and CTA are part of every package. **Editing them after generation
survives** — a generated caption the user does not like should be fixable in place,
without regenerating.

---

## 8. Failure is not one thing

Four different failures, and collapsing them destroys the learning.

| Failure | Meaning | Example |
| --- | --- | --- |
| **Strategy** | The idea was not strong enough | No specific parent would send it |
| **Creative** | Good idea, weak execution | Hook didn't land in the first second |
| **Production** | Good strategy and creative, could not be delivered | Character consistency broke across scenes |
| **Performance** | Made correctly, did not achieve the goal | Good share trigger, low actual shares after 5 tests |

Only the fourth says anything about the format. The first three say the execution or
the pipeline failed, and blaming the format for those is how a good format gets
retired.

---

## 9. Lifecycle

```
idea → approved → scripted → imagesReady → generated → posted → tested → archived
```

Plus two states that are not the same as archived:

| State | Means |
| --- | --- |
| **blocked** | Could be good, cannot currently be produced |
| **rejected** | A decision was made not to make it |

**Archived** means no longer active. **Blocked** means waiting on a capability.
**Rejected** means deliberately declined. Merging them loses the reason, and the reason
is the useful part.

---

## 10. Legacy and non-content

Not everything historical fits today's taxonomy, and forcing it in corrupts the
taxonomy.

```
currentSeries   may be null
legacySeries    "little-stories"   preserved
currentPillar   may be null
classificationStatus  archive | nonContent | legacy
```

Old names are **kept, not mapped**. `little-stories` was a retired concept;
`cuty-lessons` confuses a character with a series; `the-casts` was audience voting.
Each is preserved as history and carries no current value.

**This means the migration will not reach 100%, and that is correct.** A migration that
reaches 100% by inventing mappings has contaminated the data it was meant to clean.

---

## 11. Human approval is permanent

Not a migration phase that ends. It never does.

The app proposes:

```
Pillar: DO
Confidence: high
Reason: the child is practising independence
```

A person accepts or edits. **Confidence is not truth.** It is what the classifier
believes, and it is wrong often enough that treating it as authority would poison the
performance data — which is the entire reason this model exists.

Classification quality *is* data quality. Thirty good DO pieces with eight wrongly
labelled PLAY produces a conclusion that PLAY outperformed, and you would change
strategy on the strength of a labelling error. That is worse than having no analytics
at all.

---

## 12. The Create flow

The screen must name what it is selecting. A dropdown called "Format" is ambiguous
because format means two things in this app — the content type being published and the
narrative shape.

```
Create Content

  Idea
  ┌────────────────────────────────┐
  │ Ria refuses to brush her teeth │
  └────────────────────────────────┘

  Content Type      [ Carousel      ▼ ]
  Narrative Format  [ Problem → Fix ▼ ]
  Goal              [ Saves         ▼ ]

              [ Generate Carousel ]
```

Switching Content Type to Reel changes the button to **Generate Reel** and changes what
is generated. Only the fields that matter for that content type are shown.

**Rules:**

- The label states what will be produced. "Generate Carousel", not "Generate".
- Content Type is never called "Format".
- Narrative Format is a separate, separately-labelled choice.
- Classification is shown for confirmation, not re-entered.

---

## 13. What is deliberately not decided here

- Which screen shows what
- How production effort is estimated
- Whether voice mode can be inferred or only declared
- The exact storage shape

Each can wait until something depends on it.

---

## 14. The Master Content Sheet

One structured view of every idea intended for the
application. The sheet is deliberately **not a new file**:
it is the existing source files read together, because a
second copy of the library would fork the source of truth
and the two would drift.

| Sheet field | Where it lives |
| --- | --- |
| ID, Series, Idea Title, Idea, Pillar, Content Type, Narrative Format, Production Method, Goal, Status, Notes | `content_ideas.md` |
| Decision (KEEP / REWORK / DELETE / ARCHIVE) | `tool/idea_decisions.csv` |
| Share Sender, Share Recipient, Share Situation, Share Reason, Share Status | not yet per-idea fields — checked mechanically by `tool/reach_mechanics.dart` until the axes settle, then written onto each idea |
| Open Loop, Voice Mode | same |
| Series Collision | `tool/review_content.dart` reports duplicate titles as possible collisions |

The Decision vocabulary:

- **KEEP** — curated and fully classified; the only sync candidates
- **REWORK** — worth keeping, but not as written
- **ARCHIVE** — not active, history retained (§3b)
- **DELETE** — remove (§3b for what happens to history)

### The pre-install gate

```bash
dart run tool/review_content.dart
```

prints the decision counts, every blocking issue, and
`Ready to sync: YES / NO`, and exits non-zero when the
library is not ready so it can guard a build. Only KEEP
ideas that resolve every axis and state a share trigger
can sync. A suggested axis value is a proposal and does
not resolve; an UNKNOWN share trigger blocks, because an
unanswered "would a specific parent send this" is a
curation gap.

## 15. Work order

```text
Phase A  Master Content Sheet structure       the files above
Phase B  Existing ideas in the sheet          57 ideas, done
Phase C  Pressure test against the checks     reach_mechanics, review_content
Phase D  Clean                                KEEP / REWORK / ARCHIVE / DELETE
Phase E  Classification freeze                the seven axes settled
Phase F  App sync                             only KEEP ideas enter Flutter
Phase G  ContentPackage                       the generation architecture
```

Phases A–C exist. Phase D is the current blocker: it
needs human decisions, one pass over
`tool/review_sheet.md` and `tool/idea_decisions.csv`.
Phase E cannot start until D is done, and G cannot
start until E.

---

## Open questions

These need an answer before code depends on the model:

1. **Experiment unit** — the format, or a format within a goal, or a format within a
   pillar? The 5-test count means something different in each case.
2. **Can a package be re-posted?** If yes, does it get a new test number, or is it the
   same test observed longer?
3. **What happens to an idea when its classification changes after posting?** The
   snapshot protects history, but does the idea itself re-classify?
4. **Does a series end?** A retired series needs a state that is not "archived", or the
   filter starts lying.