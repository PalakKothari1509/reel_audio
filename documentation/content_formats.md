# Fun Learning With Palak, Content Format Library

**This file is the source of truth for content FORMATS.** A format is the **HOW** a
piece of content is shaped. What the content is *about* lives in the idea library and
never here.

```
content_formats.md   ->  HOW to create content   ->  lib/format_handbook.dart
assets/ideas/*.md    ->  WHAT the content is about
```

**Separation is the whole point.** `Problem -> Fix` is a format. "Ria refuses to brush
her teeth" is an idea. An idea can be executed as `Problem -> Fix` or as `Do This,
Not That` on different days, and both executions are the same idea.

**Status: 16 of 50 formats specified.** These sixteen were chosen because they fit the
audience and because real ideas needed them, not because they are the most common
formats on Instagram. Formats 13–16 exist only because existing ideas referenced
narrative shapes no registered format covered. They get built and tested against real
content first. The remaining 34 are data entry into this same schema, not new design
work.

**Do not add formats just because the handbook has fifty.** A format earns its place
when a real idea needs it. That is exactly how 13–16 came to exist, and it is the only
reason to expect the other 34.

---

## How to use this file

Each format is one `##` section. The field names below are canonical; the parser in
`tool/sync_formats.dart` reads these names and nothing else.

| Field | Purpose |
|---|---|
| `ID` | Stable key used by ideas and by the Dart enum. Never renumbered. |
| `Name` | Display label |
| `Definition` | One sentence, what this shape is |
| `Structure` | The beat order, written so a prompt can follow it literally |
| `Best for` | When to reach for this format, in plain language |
| `Best content types` | Which of the six content types suit it |
| `Best goals` | Which goals it actually serves |
| `Default for` | Optional. The content type this format is the *right* answer for when several tie. The tie-break, not a shortcut |
| `Example` | A real Fun Learning With Palak idea executed in this format |
| `Generation rules` | The constraints the generator must follow |

**Valid values for `Best content types`:**

`Reel` · `Trial Reel` · `Carousel` · `Static Image` · `Image Slideshow Reel` · `Story`

**Valid values for `Best goals`:**

`Reach` · `Non-follower Reach` · `Saves` · `Shares` · `Comments` ·
`Relatability` · `Authority` · `Follows`

**Rules for every entry:**

- The `Name` is display text and goes into prompts, so it uses the real arrow `→`
  rather than ASCII `->`. The `ID` is the machine key and stays camelCase. Getting
  these two backwards is silent: `content_ideas.md` wrote `Problem → Fix` for five
  ideas, the handbook had ASCII, and `byName` matched nothing — the format read as
  unregistered when it had been registered all along.

- `Structure` is a beat list, not prose. The generator follows beats, so write beats.
- `Generation rules` must be checkable. "Make it good" is not a rule; "no more than
  9 words on screen" is.
- `Default for` exists because the scoring ties. `problemFix`, `mistakesList`,
  `saveThisList` and `doThisNotThat` all support `imageSlideshowReel` and all serve
  `nonFollowerReach`, so on content type and goal alone the recommendation came back
  as "Mistakes List" for an idea that is plainly a problem-to-fix. Ties broke by
  declaration order, which is arbitrary and would have shipped as "wrong format
  recommended, no obvious reason". Set `Default for` on the format genuinely
  responsible when nothing else separates them, and leave it off the rest.
- **One content type gets at most one default.** Two formats claiming the same type
  made the tie-break a coin flip again, which is the failure `Default for` exists to
  remove. It happened twice here: `pov` and `quickTip` both claimed `reel`, and
  `problemFix` and `saveThisList` both claimed `carousel`. In the carousel case the
  loser was invisible — `problemFix` sat earlier in the file, so `saveThisList` could
  never be recommended for a carousel, which is the format it exists to serve.
  `tool/check_formats.dart` now rejects a contested default.
- Every format needs a hook rule, a pacing rule, a visual structure and an audio
  type, even if the honest answer is "no on-screen text".
- A format must be executable by a 1-4 audience. If it needs reading speed a parent
  does not have, it does not belong here.

---

## POV

- **ID**: `pov`
- **Name**: POV
- **Definition**: First-person camera, as if the viewer is the parent living the moment.
- **Structure**:
  1. On-screen text declares the POV: `POV: you finally drank hot chai`
  2. The mess, or the small victory, immediately visible
  3. One beat of the child's point of view, usually Cuty or Rio
  4. The parent's quiet reaction
  5. One line of relatability text, no explanation
- **Best for**: A feeling the viewer recognises in under two seconds. Works because the
  viewer supplies the story, so no exposition is needed.
- **Best content types**: `Reel`, `Trial Reel`
- **Best goals**: `Non-follower Reach`, `Relatability`, `Shares`, `Comments`
- **Default for**: `Reel`, `Trial Reel`
- **Example**: **Idea**: "POV: you finally drank hot chai while your child plays
  independently." Mumma sits down with a cup, Ria and Rio are absorbed transferring
  dal from bowl to bowl with two spoons. Cuty naps. No dialogue. On-screen text only at
  the top and the last frame.
- **Generation rules**:
  - Camera is the viewer's eyes. Never show the parent's face from outside.
  - `POV:` text appears in the first 6 words on screen and stays for at least 2 seconds.
  - No voiceover narration in third person. Sound design and text only.
  - Never explain the feeling. The viewer already has it.
  - Max 3 text overlays for the whole piece.

---

## Do This, Not That

- **ID**: `doThisNotThat`
- **Name**: Do This, Not That
- **Definition**: A correct behaviour paired with the wrong one it replaces.
- **Structure**:
  1. Frame A, the one that works, shown first
  2. Frame B, the familiar one that does not
  3. Why B fails, one clause only
  4. A or B restated as a rule the parent can remember
- **Best for**: Replacing advice the parent is already ignoring. The pairing does the
  persuading, so the caption does not have to argue.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Static Image`
- **Best goals**: `Saves`, `Shares`, `Authority`
- **Example**: **Idea**: "3 things to say instead of NO." Slide 1 `Say: "Aap ek kaam
  karo, phir main chai piyungi"` vs `Say: "NO"`. Slide 2 offering a turn instead of a
  refusal. Slide 3 narrating the child's version of being offered a turn.
- **Generation rules**:
  - Always two columns or two panels. Never one.
  - The correct option appears first in every pair. Order matters.
  - Exactly 3 pairs per post. Not 2, not 5.
  - Both options must be under 8 words on screen.
  - No shame language toward the parent. The wrong option was reasonable.
  - The closing line must be a rule, not a summary of the slides.

---

## Mistakes List

- **ID**: `mistakesList`
- **Name**: Mistakes List
- **Definition**: The errors the target parent is making, named honestly, then fixed.
- **Structure**:
  1. Call out the mistake the viewer is currently making
  2. Enumerate the mistakes, one per beat
  3. Each mistake gets its correction in the same beat
  4. Close on the one that matters most
- **Best for**: Turning vague guilt into a specific checklist. The viewer recognises
  themselves, which is what earns the save.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Reel`
- **Best goals**: `Saves`, `Shares`, `Non-follower Reach`
- **Example**: **Idea**: "Mistakes I made teaching Ria to be independent." Stopping her
  mid-task. Asking "what colour?" instead of "which one". Praising every attempt
  equally. Sitting her down to help.
- **Generation rules**:
  - 3 to 5 mistakes. Three is the default.
  - Each mistake must be something a loving parent does by accident. Never stupidity.
  - The correction is mandatory in the same beat. A list without fixes is guilt.
  - First-person, as though the author made them. Not second-person accusation.
  - No mistake may repeat a pillar's other lessons. Each stands alone.

---

## Problem -> Fix

- **ID**: `problemFix`
- **Name**: Problem → Fix
- **Definition**: One specific problem, the reason it persists, the jugaad fix, the
  result.
- **Structure**:
  1. The problem, shown not described
  2. The parent's first attempt, which fails
  3. The reason the usual approach fails, one line
  4. The fix, using something already in the house
  5. The result, the child participating
  6. A parent takeaway, one line
- **Best for**: The flagship shape for this brand. It carries the whole
  problem-then-solution premise and it is the format the first six ideas in the library
  were written for.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Carousel`
- **Best goals**: `Non-follower Reach`, `Saves`, `Relatability`
- **Default for**: `Image Slideshow Reel`
- **Example**: **Idea**: "Ria refuses to brush her teeth." Mumma counts to three. Ria
  clamps down. The count does not work on a 3-year-old. Mumma puts the brush in Ria's
  hand and turns it into a song she has to finish. Ria brushes. Takeaway: *"Give her
  the job, not the order."*
- **Generation rules**:
  - The fix must cost nothing and use something already in the home. No buying.
  - The first attempt must be a genuine attempt, not a strawman. It has to be one a
    parent would really try.
  - The reason the usual approach fails is mandatory. Without it this becomes a
    lecture.
  - The child ends the piece participating, not being managed.
  - The takeaway is spoken to the parent, never to the child.
  - Exactly 5 to 6 beats. Do not extend the middle.

---

## Exact Script

- **ID**: `exactScript`
- **Name**: Exact Script
- **Definition**: The literal words to say, delivered so the parent can copy them.
- **Structure**:
  1. The situation, one line
  2. What most parents say, and why it lands badly
  3. The exact words to say instead, quoted verbatim
  4. The child's likely response
  5. One variation for a harder day
- **Best for**: Language-building and TALK pillar content. Removes the cost of
  composing, so the parent acts today rather than later.
- **Best content types**: `Carousel`, `Static Image`, `Image Slideshow Reel`
- **Best goals**: `Saves`, `Shares`, `Authority`, `Follows`
- **Example**: **Idea**: "What to say when Ria hits Rio." Instead of "don't hit",
  Mumma says *"Aap usko hurt kar rahe ho, rokao mujhe batana."* Rio responds by
  showing his hand. Variation for a repeat: name the rule, then the consequence, in
  two short sentences.
- **Generation rules**:
  - The script must be quotable word for word. No paraphrasing in the on-screen text.
  - 8 to 12 words per quoted line. Longer is not memorised.
  - Hinglish, the way the parent actually talks. Not formal English.
  - Never shame the child in the quoted line.
  - One variation only, not a list of alternatives.

---

## Expectation vs Reality

- **ID**: `expectationReality`
- **Name**: Expectation vs Reality
- **Definition**: What the parent expects, set against what actually happens.
- **Structure**:
  1. The expectation, stated as the parent imagines it
  2. The expectation shown on screen
  3. The reality, unstyled and immediate
  4. The child doing the opposite
  5. The moment it becomes funny instead of frustrating
- **Best for**: Humour that requires recognition to land. The gap is the joke, and the
  viewer closes it themselves.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Trial Reel`
- **Best goals**: `Relatability`, `Shares`, `Non-follower Reach`, `Comments`
- **Example**: **Idea**: "Expectation vs reality: teaching a 3-year-old to put on
  shoes." Expectation, a neat demonstration with Rio cooperating. Reality, Rio putting
  both shoes on, then a mitten on his foot, walking confidently. Mumma's face in the
  final beat.
- **Generation rules**:
  - The reality beat must be genuinely unexpected, not a cute exaggeration.
  - The child must be acting normally. Never a cartoon mishap.
  - No punchline music or emoji overlays. The situation is the joke.
  - The parent's reaction is the last beat and stays under 2 seconds.
  - Never make the child's behaviour something to correct. It is the punchline, not a
    lesson.

---

## Personal Mistake

- **ID**: `personalMistake`
- **Name**: Personal Mistake
- **Definition**: Something the author did, owned without excuse, then repaired.
- **Structure**:
  1. What I did, plainly
  2. What I told myself about it
  3. What actually happened as a result
  4. What I do instead now
  5. What I would tell a friend in the same spot
- **Best for**: Authority and relatability together. First-person accountability is
  the most trusted format on this platform and the least used.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: `Saves`, `Shares`, `Follows`, `Relatability`
- **Example**: **Idea**: "I let Ria watch TV to finish my work." Told myself it was
  ten minutes. It was forty, and by dinner she could not sit through dinner. Now the
  substitute is set up before the phone is, so the choice is never hers to make.
- **Generation rules**:
  - First person throughout. Never "you".
  - No excuse in beat 2. The self-justification is named so it can be discarded.
  - No self-punishment, no performative confession. The tone is matter-of-fact.
  - The repair must be specific and free. No product, no course, no book.
  - Beat 5 addresses the viewer as an equal, never as a learner.

---

## Save This List

- **ID**: `saveThisList`
- **Name**: Save This List
- **Definition**: A reference set of items, designed to be saved and returned to.
- **Structure**:
  1. The promise, stated as what the list contains and who it is for
  2. Item 1, each one usable today with nothing bought
  3. Item 2
  4. Item 3
  5. Item 4
  6. Item 5
  7. Where to find them, i.e. a named drawer or shelf
- **Best for**: Age-Based Skills and Try This At Home content. Saves are the only
  metric this format optimises for, so everything about it serves that.
- **Best content types**: `Carousel`, `Static Image`
- **Best goals**: `Saves`, `Shares`
- **Default for**: `Carousel`, `Static Image`
- **Example**: **Idea**: "5 things in the kitchen drawer that keep a 3-year-old
  busy." Two spoons and a bowl for dal transfer. A plastic cup for water pouring. A
  muffin tin for sorting. A sieve for sifting. An empty container to fill and empty.
  The takeaway is the drawer, not the activities.
- **Generation rules**:
  - Exactly 5 items. This is a hard number, not a target.
  - Every item uses something already in the house. Zero purchases.
  - One item per beat, one line of on-screen text each, max 9 words.
  - The closing beat names a location, not a summary.
  - No item may require adult supervision to be safe. This audience plays unsupervised.
  - Never open with "save this post". The list has to earn the save.

---

## Numbered Framework

- **ID**: `numberedFramework`
- **Name**: Numbered Framework
- **Definition**: A teachable model in numbered steps, memorable as a sequence.
- **Best content types**: `Carousel`, `Reel`, `Image Slideshow Reel`
- **Best goals**: `Authority`, `Saves`, `Follows`
- **Structure**:
  1. Name the framework, so it can be referred to later by name
  2. Step 1, the entry point, the easiest
  3. Step 2
  4. Step 3
  5. Step 4
  6. The result, and when to move to the next step
- **Best for**: TALK and DO content that needs to be recalled and repeated. A named
  framework is what parents describe to each other, which is distribution you do not
  pay for.
- **Example**: **Idea**: "The 4-step brush routine that stopped the fight." Step 1 she
  chooses the song. Step 2 she holds the brush. Step 3 Mumma only taps the rhythm.
  Step 4 Ria finishes the last side. Move to step 3 only after two easy mornings.
- **Generation rules**:
  - 3 to 5 steps. Four is the default.
  - Steps increase in difficulty. The first must be trivially easy.
  - Each step is one instruction, max 10 words.
  - The framework needs a name the parent can repeat. A generic list is not a
    framework.
  - Include when to advance. A framework with no exit condition is a trap.

---

## Unpopular Opinion

- **ID**: `unpopularOpinion`
- **Name**: Unpopular Opinion
- **Definition**: A held position that contradicts common parenting advice, defended
  plainly.
- **Structure**:
  1. The opinion, stated in one line, no hedging
  2. The advice it contradicts, named fairly
  3. Why that advice is common
  4. The counter-case, argued not asserted
  5. The condition under which the common advice is right
  6. The honest close
- **Best for**: Comments and profile visits. Disagreement is the cheapest engagement
  available, provided the position is argued rather than baited.
- **Best content types**: `Reel`, `Trial Reel`, `Carousel`
- **Best goals**: `Comments`, `Non-follower Reach`, `Follows`
- **Example**: **Idea**: "Your child does not need praise." The common advice is to
  praise every attempt. It is common because it works on adults by analogy. For a
  3-year-old, unearned praise teaches that the task was not interesting enough without
  an audience. Praise the effort once, then stay quiet. The common advice is right when
  the child is unsure whether they tried correctly.
- **Generation rules**:
  - The opposing view must be stated at its strongest, not a straw version.
  - Beat 5 is mandatory. An opinion with no boundary is a stunt.
  - Never disagree for the sake of disagreement. If the position is mainstream, it is
    not this format.
  - No contempt for parents who hold the other view. Argue the idea, not the person.
  - The opinion must be defensible by the author in comments.

---

## Before You

- **ID**: `beforeYou`
- **Name**: Before You
- **Definition**: Advice delivered as a pre-emptive warning about a specific moment.
- **Structure**:
  1. The moment named, so the parent recognises it before it happens
  2. What usually goes wrong there
  3. The mistake most parents make in that moment
  4. What to do instead, in time order
  5. What it looks like when it goes well
- **Best for**: Preparing a parent for a predictable hard moment. The value is in the
  timing, so it has to be watchable *before* the moment arrives.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Carousel`
- **Best goals**: `Saves`, `Non-follower Reach`, `Authority`
- **Example**: **Idea**: "Before you let Ria choose her own clothes." The usual moment
  is a 20-minute stall over two options. The mistake is offering choices too early. Do
  it instead: lay out two complete outfits, let her choose between those, and keep the
  rejected one for tomorrow.
- **Generation rules**:
  - The moment must be specific and recognisable in under 3 seconds.
  - Advice must be actionable before the moment, not during it.
  - The fix must be repeatable, not a one-off.
  - No preview of the moment happening. The piece prepares, it does not tease.
  - The closing beat must show the version that worked, not just the warning.

---

## Three Examples

- **ID**: `threeExamples`
- **Name**: Three Examples
- **Definition**: One idea demonstrated three different ways, so the parent picks the
  version that fits their child.
- **Structure**:
  1. The goal, one line, so the three are comparable
  2. Example 1, the easiest, the one that always works
  3. Example 2, the middle
  4. Example 3, the hardest, for a child who resists
  5. Which one to try first, given the child's temperament
- **Best for**: Anyone whose advice has to survive contact with a real child. Three
  versions converts a rule into a choice, which is what makes it usable.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Reel`
- **Best goals**: `Saves`, `Shares`, `Authority`
- **Example**: **Idea**: "Three ways to end a tantrum." One, distract and leave.
  Two, stay close and stay silent. Three, name the feeling and wait. Start with one
  unless the child escalates to the floor.
- **Generation rules**:
  - Exactly 3 examples, in ascending difficulty.
  - All three must serve the same goal. Three different problems is not this format.
  - Each example gets one beat and max 10 words on screen.
  - The closing beat must tell the parent how to choose between them.
  - None of the three may require anything bought or any professional.

---

## Format selection, for the generator

When the app proposes a format for an idea, it scores each registered format on two
factors already in this file, and shows the reasoning in one line:

- **`Best content types`** — does the format support the content type in play
- **`Best goals`** — does the format serve the goal that was chosen

The recommendation is overridable. You know your page better than the heuristic does.

An idea with no matching format must **fail loudly**, naming the format that was
missing. It must not silently fall back to `Problem -> Fix`, because that is how an
unsupported format becomes a Problem Fix with no trace and the test results become
unreadable.

---

## Quick Tip

- **ID**: `quickTip`
- **Name**: Quick Tip
- **Definition**: One simple activity or technique a parent can try immediately, demonstrated in a single beat.
- **Structure**:
  1. The situation, one line
  2. The quick technique, shown not described
  3. Why it works, one sentence
  4. The result, immediate
- **Best for**: A single ₹0 activity or technique a parent can try today. This format owns **activity demonstrations**: water pouring, dal-chawal sensory play, tape pulling, spoon transfer, two-bowl sorting, and the rest of that family.
- **Best content types**: `Reel`, `Trial Reel`, `Image Slideshow Reel`
- **Best goals**: `Non-follower Reach`, `Saves`, `Shares`
- **Example**: **Idea**: "Toddler maths — 1 biscuit = hungry, 2 = still hungry, 3 = MORE." Rio holds biscuits, expression escalates. Cuty unimpressed in background. No setup, just the reveal.
- **Generation rules**:
  - Exactly one technique. Not a list.
  - The technique uses something already in the house. Zero purchases.
  - **Activity demonstrations belong here.** A setup → play → result beat sequence is
    not a failure to match another shape; it is this shape. The handbook previously had
    no format for "show the activity", so six real ideas — water pouring, dal chawal,
    tape pull, spoon transfer, pouring, simple sorting — matched nothing at all and
    were reported as unresolvable. Widening this format's stated scope is cheaper and
    more honest than inventing an Activity Demonstration format to absorb them.
  - No explanation of why the child behaves this way. The technique speaks.
  - On-screen text max 8 words. The visual is the hook.
  - Duration 10-15 seconds if Reel/Trial Reel.

---

## Mini Story

- **ID**: `miniStory`
- **Name**: Mini Story
- **Definition**: A short narrative with a clear beginning, middle and end, told through Ria/Rio/Cuty.
- **Structure**:
  1. The setup — character wants something
  2. The obstacle — it doesn't go smoothly
  3. The turning point — a small intervention or discovery
  4. The resolution — character succeeds or learns
  5. The parent takeaway, one line
- **Best for**: Emotional connection through character moments. The viewer watches for Ria/Rio/Cuty, not just the activity.
- **Best content types**: `Image Slideshow Reel`, `Reel`, `Carousel`
- **Best goals**: `Relatability`, `Shares`, `Follows`
- **Example**: **Idea**: "Cuty is stuck under the sofa." Ria panics. Rio thinks. Mumma suggests the broom handle. Cuty rescued. Takeaway: "Sometimes the solution is already in your hand."
- **Generation rules**:
  - Exactly 5 beats. Not 3, not 7.
  - Ria, Rio or Cuty must be the protagonist. Never a generic child.
  - The obstacle must be solvable with a household object, not magic.
  - The takeaway addresses the parent, not the child.
  - No moralising. The story teaches; the takeaway names the lesson.

---

## This or That

- **ID**: `thisOrThat`
- **Name**: This or That
- **Definition**: A direct choice between two options, presented so the audience picks one.
- **Structure**:
  1. The question, visual and immediate
  2. Option A, shown
  3. Option B, shown
  4. The parent context — why this choice matters
  5. A gentle nudge toward the better option, without shame
- **Best for**: Engagement and comments. The format is literally a question the viewer answers.
- **Best content types**: `Carousel`, `Static Image`, `Story`
- **Best goals**: `Comments`, `Relatability`, `Shares`
- **Example**: **Idea**: "Toddler wants phone at dinner. Phone OR spoon-transfer activity?" Show both. Spoon-transfer wins. Caption: "Which one buys you 15 minutes of hot chai?"
- **Generation rules**:
  - Always two options. Never three.
  - Both options visually distinct. Not "red spoon" vs "blue spoon".
  - The better option is not morally superior. It is practically superior.
  - The nudge is optional. The audience's vote is the point.
  - Max 6 words per option on screen.

---

## Question → Answer

- **ID**: `questionAnswer`
- **Name**: Question → Answer
- **Definition**: One parent question, the exact words to say, and why those words work.
- **Structure**:
  1. The exact question a parent asks
  2. The common answer that lands badly
  3. The exact words to say instead, quoted verbatim
  4. Why this phrasing works, one sentence
  5. One variation for a harder moment
- **Best for**: Language-building and TALK pillar content. Removes the cost of composing, so the parent acts today rather than later.
- **Best content types**: `Carousel`, `Static Image`, `Image Slideshow Reel`
- **Best goals**: `Saves`, `Shares`, `Authority`, `Follows`
- **Example**: **Idea**: "What to say when toddler asks for phone at lunch." Common: "No phone." Instead: "Phone baad mein. Abhi chhuri-chammach se khelo." Variation for escalation: "Phone baad mein. Pehle ek kaam karo, phir phone."
- **Generation rules**:
  - The quoted line must be quotable word for word. No paraphrasing.
  - 8 to 12 words per quoted line. Longer is not memorised.
  - Hinglish, the way the parent actually talks. Not formal English.
  - Never shame the child in the quoted line.
  - One variation only, not a list of alternatives.
  - The "why it works" sentence is mandatory — otherwise it is a script, not a lesson.

---

## Adding format 13

1. Add the `##` section here using the nine canonical fields.
2. Validate the field names and the allowed values for `Best content types` and
   `Best goals`.
3. Run `dart run tool/sync_formats.dart` to regenerate `lib/format_handbook.dart`.
4. Register the content types and goals in the handbook, not in a prompt file.
5. Test against one real idea from `assets/ideas/` before marking it available.

Do not add an ID that is not in this file, and never renumber an existing one. Ideas
and posted performance reference these IDs, so a renumber silently rewrites history.