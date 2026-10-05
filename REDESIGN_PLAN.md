# What Still Needs Building

Everything left to do on Fun Learning With Palak, in plain language.

**How to read this:** tasks are grouped by what they unblock. Anything marked **YOURS**
cannot be finished by me — it needs your decision or your keys.

**Last checked:** `flutter analyze lib` → 91 issues, 0 errors. `flutter test` → 21
tests, all passing. All checker scripts pass.

---

## The one thing blocking everything

The 57 ideas in `content_ideas.md` are not fully classified yet.

Each idea needs seven values: **pillar, series, content type, narrative format,
production method, goal, status**. Right now most of them don't have them.

I can propose a value for almost every idea, with a reason. What I cannot do is decide
them for you — **a wrong pillar is invisible later**. It just quietly files the results
of a good post under the wrong heading, and six months of testing becomes unreadable.

| Axis | Decided | Still open |
| --- | --- | --- |
| Pillar | 11 suggested, 1 archived | **45** |
| Series | — | **23** |
| Narrative Format | 19 approved | 2 blocked |
| Content Type | — | 7 |
| Production Method | — | 7 |
| Goal | — | 6 |
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

This is the largest single editorial decision left.

### Two ideas that should not be forced

- `day14-favorite-format` — asks the audience which format worked best. It gives a
  parent nothing to save or send. Already marked `archive_candidate` rather than
  forced into a pillar.
- `st-ria-same-toy` and `lp-kitchen-counting` — both rest on a beat description
  because they have no Topic or Lesson text. Marked `beat_only` so you know the
  evidence is weaker.

---

## Next: one generator instead of five

Right now the app has separate caption, hashtag and hook tools, plus four different
ideas of what a "finished post" looks like. That is the fragmentation problem.

**This cannot be designed yet.** A finished package has to know what it is generating —
which pillar, which series, which format — and right now most ideas don't.

Once the axes are settled:

- **Build one `ContentPackage`** that every path produces
- **Keep the script.** The prompt already asks for narration and per-scene dialogue,
  and the app throws it away. This is why narration isn't showing up in the output you
  asked for.
- **Delete the standalone generators** once nothing needs them
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

No idea in the library has a share trigger. That is a content gap, not a bug, and it
is the highest-value thing to fix — a share is worth more than a view for this page.

Once the axes are done, these become real fields on each idea rather than something I
check from outside.

---

## Missing screens

Four of the six tabs you planned do not exist:

| Tab | State |
| --- | --- |
| Ideas | Split across three places |
| Create | Five buttons where there should be one workflow |
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
| README is template boilerplate | Says "A new Flutter project" |
| CI does not run on this branch | Only tests `main` and `video-slideshow` |

---

## Testing gaps

21 tests cover the quiet failures. Still untested: the Gemini JSON parser, network
calls, video assembly, and what happens when AI fails.

**Worth knowing:** most file-reading code cannot be tested at all, because the storage
layer has no test seam. Two components now have one. The rest need the same.

---

## Deliberately not being built

Recording these so they don't get re-proposed:

**A 150K potential score.** Seven scores across 85 ideas would be 595 numbers with no
evidence behind them, produced by guessing — and it would look like data. You already
decided this: *"learn from your real Instagram results rather than manufacture a viral
score."* The mechanics are checked honestly instead, as pass / fail / unknown.

**Regenerating all the ideas right now.** New ideas would discard the 19 narrative
formats and 11 pillars already decided, then restart the same review on a bigger set.

**More formats before these 16 are proven.** A format should earn its place because a
real idea needs it — which is exactly how the last four got added.

**Rebuilding the video pipeline.** The existing Reel Maker works end to end. Leave it.

**AI agents or autonomous posting.** Not until the classification work is solid.

---

## Suggested order

```
CLEAR THE BLOCKER
  review sheet  ->  you decide  ->  migration writes approved values

THEN
  one ContentPackage
  keep the script (this is where narration comes from)
  production method decides the output
  delete the standalone generators

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