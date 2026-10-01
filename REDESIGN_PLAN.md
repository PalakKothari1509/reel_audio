# Redesign Plan v2, Fun Learning With Palak

**Status:** awaiting approval. Nothing below has been applied.
**Supersedes:** the sequencing in the first version of this document. The audit
findings it contained still stand; the order does not.
**Last verified:** `flutter analyze lib` 0 errors, 95 pre-existing issues.

---

## 1. Done and verified

| Point | What | Verification |
|---|---|---|
| 1 | API key moved to `x-goog-api-key` header in `gemini_call.dart` **and** `voice.dart`; model off the 404-ing `gemini-1.5-flash`; both throwing JSON parsers guarded | Live API call. Hinglish + Devanagari returned correctly, HTTP 200 |
| 2 | All content ideas in one file (`content_ideas.dart`, 1,306 lines); one bucket list; `community` bucket created; old ids migrated on read | APK built, installed, running on V2318 |

One extra finding from Point 1 that was not on any list: the model spends thinking
tokens out of the same `maxOutputTokens` budget. At 1024 it used 981 tokens
thinking and returned truncated, unparseable JSON. Fixed with
`thinkingBudget: 0` on the four small structured calls.

---

## 2. Three things to settle before I build anything

### Blocker A, the visual style contradicts itself

This plan cannot be written past this one.

- **Your last message:** "Pastel soft watercolor + children's storybook look."
- **Your message before that:** "go with 3D Pixar, not watercolor. That's what all
  my actual character prompts and reference images have been built around, fix
  `brand_system.dart` to match `prompts.dart`, not the reverse, so we don't break
  the character consistency work already done."

Both instructions say keep the existing direction and change the other file. That
is the exact opposite action, and it changes every image prompt in the app.

The second one is the better argument, because it is based on what already
exists: `prompts.dart:26` and the video work are already 3D, so choosing watercolor
means migrating the character references you have built. But the first one reads
like a considered decision rather than a slip, and I am not going to silently pick
one and rewrite every prompt in the app on a coin toss.

**I need one word from you: `watercolor` or `pixar`.**

### Blocker B, Mummy does not exist yet

`CharacterLibrary` has exactly three characters: `ria`, `rio`, `cuty`. There is no
Mummy anywhere in the codebase. "Jugaadu Mummy" is a new series built on a
character that has no profile yet, and the Character Consistency work is the whole
point, so this has to be built properly rather than improvised per prompt.

To add her I need: face, hair, skin tone, outfit (does she wear the same things
every episode, or does that change per jugaad?), height relative to Ria and Rio,
and whether she ever appears as the on-camera narrator or only within a scene.

### Blocker C, the 50-format handbook is not in the repo

`Ideas from chat gpt for marketing posts.md` is 1,015 lines and it is a **strategy**
document: the four content jobs, Trial Reels versus Reels, why to stop making
educational carousels. It is genuinely good and worth reading before we build.

It does not contain a list of 50 formats. The only format-shaped line in the whole
file is `Problem → Think → Try → Fix` at line 332. Your formats (POV, Do This Not
That, Mistakes, Expectation vs Reality, Mini Story) are not in it.

So the format library has to be written from scratch, or you paste the real one.
Worth doing properly: it is the asset that makes this app months of work rather
than a generator for the current 24 posts.

---

## 3. What I think about the reordering

Agreed, and I want to be specific about why rather than just nodding.

Buckets should stop being the organising idea. You are right, and the code agrees:
`ContentFormat` currently has 5 values that are *output shapes* (carousel, reel,
trial reel, single image, multi format), while your real formats are *narrative
structures* (Problem → Fix, POV, Expectation vs Reality). Those are different
axes and the app currently only has the first one. Adding a series axis on top of
a format axis that means the wrong thing is how you end up with a library that
cannot answer "what else can I do with this idea".

On **content_library.dart: do not delete it.** You were right to stop me, and I
checked rather than assumed. It already holds the spine of what you are asking
for: a six-state lifecycle (`idea → draft → ready → posted → reused → archived`),
`formatOutputs` as a map of one content into many formats, `reuseCount`,
`sourceIdeaId`, `qualityReport`, `performanceMetrics`, `postedAt`,
`instagramPostUrl`. That is a content pipeline. It was just built for posts
instead of series, and never wired to anything.

So Point 8 changes from "delete dead code" to "**rebuild `content_library.dart`
around series**". It stops being cleanup and becomes part of Phase 1.

---

## 4. Revised roadmap

Effort is honest, including device testing.

### PHASE 0, reliability, 2 of 4 done

| # | Point | Status | Effort |
|---|---|---|---|
| 1 | Key, model, parsers | **Done** | — |
| 2 | Bucket unification | **Done** | — |
| 3 | `GeminiService`, built around the Reel pipeline not `prompt → JSON` | Next | large |
| 4 | Wire up the fallback that already exists | After 3 | small |

**Point 3, shaped for Reels.** Agreed, and this is the right instinct. The request
and the result become first-class types rather than four files each inventing their
own JSON:

```
ReelRequest          ReelPackage
  series     ──┐      hook
  format       │      story
  topic        ├──►   scene list (with per-scene characters)
  characters   │      narration (Hinglish + Devanagari speak)
  duration     │      on-screen text per scene
  language     │      ending
  audience     │      caption
  goal        ─┘      5 hashtags
```

Four existing callers migrate: `main.dart:169` (script), `prompt_builder.dart:169`
and `:329` (prompts), `story_ideas.dart` (3 calls), `caption_generator.dart:170`.
One at a time, a build between each. This is the highest-risk item in the plan and
I am not going to do it in a single sweep.

### PHASE 1, make it your app

**Depends on Blocker A.** Every one of these touches the character prompts.

| # | Point | Risk | Effort |
|---|---|---|---|
| 5 | Single brand source: `brand_system.dart` owns characters, style, colours, clothing, faces, proportions, lighting, ratio, negatives. Four descriptions collapse into one. Gemini never gets to rewrite a character | medium | medium |
| 6 | **Character Consistency Engine.** Every image and video prompt gets the exact profile injected, verbatim, never paraphrased | medium | medium |
| 7 | One hashtag generator. Exactly 5, with the mix you specified: 2 niche, 1 audience, 1 topic, 1 brand or series | low | small |
| 8 | **Series system.** `Jugaadu Mummy`, `Ria's little adventures`, `Rio says NO`, `Cuty's little lessons`, plus the format library, plus `content_library.dart` rebuilt around series | medium | large |
| 9 | **CTA library by goal and series**, not one generic string | low | medium |

**On Point 5, the part that matters most.** You said "do not let Gemini freely
rewrite Ria/Rio/Cuty descriptions, that will cause character drift." Agreed, and
the mechanism has to be structural rather than a line in a prompt, because a
prompt instruction is advice and advice gets followed inconsistently. The
description should be a constant that is concatenated into every prompt, so
there is no path where the model writes its own version. Note there are currently
four separate descriptions of these characters in four files; consolidating them
*is* the anti-drift work.

**On Point 7.** Your mix is the rule I will encode: exactly 5, never generic
stuffing, at least one specific to the post rather than to the page. Worth
deciding whether the brand tag is always `#FunLearningWithPalak` or rotates with
the series, because `#JugaaduMummy` only works if the series is public.

### PHASE 2, cleanup, after real use

| # | Point | Note |
|---|---|---|
| 10 | Remove genuinely dead code, minus `content_library.dart` which Point 8 absorbed | low |
| 11 | Generic `JsonStore<T>`, about 400 duplicated lines | medium, no content impact |

### PHASE 3, architecture, not approved

Points 12 to 14: splitting `main.dart` and `quick_content.dart`, navigation
cleanup, and Riverpod. **Not proposed for approval.** Agreed that splitting files
while the logic is still moving makes every diff harder to read, and that a state
migration has no business landing while the content workflow is still changing
shape. Revisit after Phase 1 with real usage data.

---

## 5. What I would do next, concretely

Blocker A is one word from you. Blocker B needs a Mummy description. Blocker C
needs the format list or permission to draft it.

With those answered, the order I would propose is **5, 6, 7, 3, 4, 8, 9**. I have
put 5 and 6 before 3 deliberately: the character work is the part that compounds.
Every scene you generate from now on carries whatever consistency foundation exists
at that moment, and retrofitting profiles later means re-checking content you have
already made.

If you would rather keep moving and settle Blocker A on the first image prompt
that looks wrong, say so and I will start on Point 5 with Pixar and you can flip it
in one constant.

---

## 6. Open questions

1. **Watercolor or Pixar.** Blocker A. Everything in Phase 1 waits on this.
2. **Mummy's profile.** Blocker B. Outfit fixed per episode or rotating?
3. **Format list.** Blocker C. Do you have the real 50, or should I draft 20 to start?
4. **Is `bucket` retired or kept?** With series and format carrying the meaning, buckets may be redundant. Keeping all three axes means every idea carries three tags, which is more than most posts need. My lean is to keep buckets as a light taxonomy for filtering, not as a generation axis.
5. **Brand tag fixed or per series?** Affects Point 7.
6. **Trial Reels.** The handbook argues for them heavily. Is the Trial Reel output a full separate package, or the same package with a different `format`?

---

## Log

| Date | Point | Result |
|---|---|---|
| today | audit | 10 findings verified by hand, 2 claims corrected |
| today | **2** | Done. Single ideas file, one bucket list, `community` created |
| today | **1** | Done, plus the thinking-budget bug found while testing |
| today | v2 | Reordered to Reel-first per your direction. Blocker A needs one word |
