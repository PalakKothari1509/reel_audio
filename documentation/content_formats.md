# Content Format Handbook

Source of truth for narrative format definitions. This file is parsed by
`tool/sync_formats.dart` into `lib/format_handbook.dart`. Every `##` section
becomes one `FormatSpec` constant, and the `all` list is regenerated from the
sections in order.

Fields per format:

- **ID**: stable machine key (never renumbered)
- **Name**: display name
- **Definition**: one sentence, what this shape is
- **Structure**: the beat order, one item per line
- **Best for**: when to reach for this format, in plain language
- **Best content types**: comma-separated content type labels
- **Best goals**: comma-separated goal labels
- **Default for**: optional — the content type where this format is the tie-break answer
- **Example**: a real Fun Learning With Palak idea executed in this format
- **Generation rules**: checkable constraints, one per line

## POV

- **ID**: `pov`
- **Name**: POV
- **Definition**: First-person camera, as if the viewer is the parent living the moment.
- **Structure**:
  - On-screen text declares the POV: `POV: you finally drank hot chai`
  - The mess, or the small victory, immediately visible
  - One beat of the child's point of view, usually Cuty or Rio
  - The parent's quiet reaction
  - One line of relatability text, no explanation
- **Best for**: A feeling the viewer recognises in under two seconds. Works because the viewer supplies the story, so no exposition is needed.
- **Best content types**: `Trial Reel`, `Reel`
- **Best goals**: Non-follower Reach, Relatability, Shares, Comments
- **Default for**: `Reel`, `Trial Reel`
- **Example**: "POV: you finally drank hot chai while your child plays independently." Mumma sits down with a cup, Ria and Rio are absorbed transferring dal from bowl to bowl with two spoons. Cuty naps. No dialogue. On-screen text only at the top and the last frame.
- **Generation rules**:
  - Camera is the viewer's eyes. Never show the parent's face from outside.
  - `POV:` text appears in the first 6 words on screen and stays for at least 2 seconds.
  - No voiceover narration in third person. Sound design and text only.
  - Never explain the feeling. The viewer already has it.
  - Max 3 text overlays for the whole piece.

## Do This, Not That

- **ID**: `doThisNotThat`
- **Name**: Do This, Not That
- **Definition**: A correct behaviour paired with the wrong one it replaces.
- **Structure**:
  - Frame A, the one that works, shown first
  - Frame B, the familiar one that does not
  - Why B fails, one clause only
  - A or B restated as a rule the parent can remember
- **Best for**: Replacing advice the parent is already ignoring. The pairing does the persuading, so the caption does not have to argue.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Static Image`
- **Best goals**: Saves, Shares, Authority
- **Example**: "3 things to say instead of NO." Slide 1 `Say: "Aap ek kaam karo, phir main chai piyungi"` vs `Say: "NO"`. Slide 2 offering a turn instead of a refusal. Slide 3 narrating the child's version of being offered a turn.
- **Generation rules**:
  - Always two columns or two panels. Never one.
  - The correct option appears first in every pair. Order matters.
  - Exactly 3 pairs per post. Not 2, not 5.
  - Both options must be under 8 words on screen.
  - No shame language toward the parent. The wrong option was reasonable.
  - The closing line must be a rule, not a summary of the slides.

## Mistakes List

- **ID**: `mistakesList`
- **Name**: Mistake List
- **Definition**: The errors the target parent is making, named honestly, then fixed.
- **Structure**:
  - Call out the mistake the viewer is currently making
  - Enumerate the mistakes, one per beat
  - Each mistake gets its correction in the same beat
  - Close on the one that matters most
- **Best for**: Turning vague guilt into a specific checklist. The viewer recognises themselves, which is what earns the save.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Reel`
- **Best goals**: Saves, Shares, Non-follower Reach
- **Example**: "Mistakes I made teaching Ria to be independent." Stopping her mid-task. Asking "what colour?" instead of "which one". Praising every attempt equally. Sitting her down to help.
- **Generation rules**:
  - 3 to 5 mistakes. Three is the default.
  - Each mistake must be something a loving parent does by accident. Never stupidity.
  - The correction is mandatory in the same beat. A list without fixes is guilt.
  - First-person, as though the author made them. Not second-person accusation.
  - No mistake may repeat a pillar's other lessons. Each stands alone.

## Problem → Fix

- **ID**: `problemFix`
- **Name**: Problem → Fix
- **Definition**: One specific problem, the reason it persists, the jugaad fix, the result.
- **Structure**:
  - The problem, shown not described
  - The parent's first attempt, which fails
  - The reason the usual approach fails, one line
  - The fix, using something already in the house
  - The result, the child participating
  - A parent takeaway, one line
- **Best for**: The flagship shape for this brand. It carries the whole problem-then-solution premise and it is the format the first six ideas in the library were written for.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Carousel`
- **Best goals**: Non-follower Reach, Saves, Relatability
- **Default for**: `Image Slideshow Reel`
- **Example**: "Ria refuses to brush her teeth." Mumma counts to three. Ria clamps down. The count does not work on a 3-year-old. Mumma puts the brush in Ria's hand and turns it into a song she has to finish. Ria brushes. Takeaway: *"Give her the job, not the order."*
- **Generation rules**:
  - The fix must cost nothing and use something already in the home. No buying.
  - The first attempt must be a genuine attempt, not a strawman. It has to be one a parent would really try.
  - The reason the usual approach fails is mandatory. Without it this becomes a lecture.
  - The child ends the piece participating, not being managed.
  - The takeaway is spoken to the parent, never to the child.
  - Exactly 5 to 6 beats. Do not extend the middle.

## Exact Script

- **ID**: `exactScript`
- **Name**: Exact Script
- **Definition**: The literal words to say, delivered so the parent can copy them.
- **Structure**:
  - The situation, one line
  - What most parents say, and why it lands badly
  - The exact words to say instead, quoted verbatim
  - The child's likely response
  - One variation for a harder day
- **Best for**: Language-building and TALK pillar content. Removes the cost of composing, so the parent acts today rather than later.
- **Best content types**: `Carousel`, `Static Image`, `Image Slideshow Reel`
- **Best goals**: Saves, Shares, Authority, Follows
- **Example**: "What to say when Ria hits Rio." Instead of "don't hit", Mumma says *"Aap usko hurt kar rahe ho, rokao mujhe batana."* Rio responds by showing his hand. Variation for repeat: name the rule, then the consequence, in two short sentences.
- **Generation rules**:
  - The script must be quotable word for word. No paraphrasing in the on-screen text.
  - 8 to 12 words per quoted line. Longer is not memorised.
  - Hinglish, the way the parent actually talks. Not formal English.
  - Never shame the child in the quoted line.
  - One variation only, not a list of alternatives.

## Expectation vs Reality

- **ID**: `expectationReality`
- **Name**: Expectation vs Reality
- **Definition**: What the parent expects, set against what actually happens.
- **Structure**:
  - The expectation, stated as the parent imagines it
  - The expectation shown on screen
  - The reality, unstyled and immediate
  - The child doing the opposite
  - The moment it becomes funny instead of frustrating
- **Best for**: Humour that requires recognition to land. The gap is the joke, and the viewer closes it themselves.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Trial Reel`
- **Best goals**: Relatability, Shares, Non-follower Reach, Comments
- **Example**: "Expectation vs reality: teaching a 3-year-old to put on shoes." Expectation, a neat demonstration with Rio cooperating. Reality, Rio putting both shoes on, then a mitten on his foot, walking confidently. Mumma's face in the final beat.
- **Generation rules**:
  - The reality beat must be genuinely unexpected, not a cute exaggeration.
  - The child must be acting normally. Never a cartoon mishap.
  - No punchline music or emoji overlays. The situation is the joke.
  - The parent's reaction is the last beat and stays under 2 seconds.
  - Never make the child's behaviour something to correct. It is the punchline, not a lesson.

## Personal Mistake

- **ID**: `personalMistake`
- **Name**: Personal Mistake
- **Definition**: Something the author did, owned without excuse, then repaired.
- **Structure**:
  - What I did, plainly
  - What I told myself about it
  - What actually happened as a result
  - What I do instead now
  - What I would tell a friend in the same spot
- **Best for**: Authority and relatability together. First-person accountability is the most trusted format on this platform and the least used.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: Saves, Shares, Follows, Relatability
- **Example**: "I let Ria watch TV to finish my work." Told myself it was ten minutes. It was forty, and by dinner she could not sit through dinner. Now the substitute is set up before the phone is, so the choice is never hers to make.
- **Generation rules**:
  - First person throughout. Never "you".
  - No excuse in beat 2. The self-justification is named so it can be discarded.
  - No self-punishment, no performative confession. The tone is matter-of-fact.
  - The repair must be specific and free. No product, no course, no book.
  - Beat 5 addresses the viewer as an equal, never as a learner.

## Save This List

- **ID**: `saveThisList`
- **Name**: Save This List
- **Definition**: A reference set of items, designed to be saved and returned to.
- **Structure**:
  - The promise, stated as what the list contains and who it is for
  - Item 1, each one usable today with nothing bought
  - Item 2
  - Item 3
  - Item 4
  - Item 5
  - Where to find them, i.e. a named drawer or shelf
- **Best for**: Age-Based Skills and Try This At Home content. Saves are the only metric this format optimises for, so everything about it serves that.
- **Best content types**: `Carousel`, `Static Image`
- **Best goals**: Saves, Shares
- **Default for**: `Carousel`, `Static Image`
- **Example**: "5 things in the kitchen drawer that keep a 3-year-old busy." Two spoons and a bowl for dal transfer. A plastic cup for water pouring. A muffin tin for sorting. A sieve for sifting. An empty container to fill and empty. The takeaway is the drawer, not the activities.
- **Generation rules**:
  - Exactly 5 items. This is a hard number, not a target.
  - Every item uses something already in the house. Zero purchases.
  - One item per beat, one line of on-screen text each, max 9 words.
  - The closing beat names a location, not a summary.
  - No item may require adult supervision to be safe. This audience plays unsupervised.
  - Never open with "save this post". The list has to earn the save.

## Numbered Framework

- **ID**: `numberedFramework`
- **Name**: Numbered Framework
- **Definition**: A teachable model in numbered steps, memorable as a sequence.
- **Structure**:
  - Name the framework, so it can be referred to later by name
  - Step 1, the entry point, the easiest
  - Step 2
  - Step 3
  - Step 4
  - The result, and when to move to the next step
- **Best for**: TALK and DO content that needs to be recalled and repeated. A named framework is what parents describe to each other, which is distribution you do not pay for.
- **Best content types**: `Carousel`, `Reel`, `Image Slideshow Reel`
- **Best goals**: Authority, Saves, Follows
- **Example**: "The 4-step brush routine that stopped the fight." Step 1 she chooses the song. Step 2 she holds the brush. Step 3 Mumma only taps the rhythm. Step 4 Ria finishes the last side. Move to step 3 only after two easy mornings.
- **Generation rules**:
  - 3 to 5 steps. Four is the default.
  - Steps increase in difficulty. The first must be trivially easy.
  - Each step is one instruction, max 10 words.
  - The framework needs a name the parent can repeat. A generic list is not a framework.
  - Include when to advance. A framework with no exit condition is a trap.

## Unpopular Opinion

- **ID**: `unpopularOpinion`
- **Name**: Unpopular Opinion
- **Definition**: A held position that contradicts common parenting advice, defended plainly.
- **Structure**:
  - The opinion, stated in one line, no hedging
  - The advice it contradicts, named fairly
  - Why that advice is common
  - The counter-case, argued not asserted
  - The condition under which the common advice is right
  - The honest close
- **Best for**: Comments and profile visits. Disagreement is the cheapest engagement available, provided the position is argued rather than baited.
- **Best content types**: `Reel`, `Trial Reel`, `Carousel`
- **Best goals**: Comments, Non-follower Reach, Follows
- **Example**: "Your child does not need praise." The common advice is to praise every attempt. It is common because it works on adults by analogy. For a 3-year-old, unearned praise teaches that the task was not interesting enough without an audience. Praise the effort once, then stay quiet. The common advice is right when the child is unsure whether they tried correctly.
- **Generation rules**:
  - The opposing view must be stated at its strongest, not a straw version.
  - Beat 5 is mandatory. An opinion with no boundary is a stunt.
  - Never disagree for the sake of disagreement. If the position is mainstream, it is not this format.
  - No contempt for parents who hold the other view. Argue the idea, not the person.
  - The opinion must be defensible by the author in comments.

## Before You

- **ID**: `beforeYou`
- **Name**: Before You
- **Definition**: Advice delivered as a pre-emptive warning about a specific moment.
- **Structure**:
  - The moment named, so the parent recognises it before it happens
  - What usually goes wrong there
  - The mistake most parents make in that moment
  - What to do instead, in time order
  - What it looks like when it goes well
- **Best for**: Preparing a parent for a predictable hard moment. The value is in the timing, so it has to be watchable *before* the moment arrives.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Carousel`
- **Best goals**: Saves, Non-follower Reach, Authority
- **Example**: "Before you let Ria choose her own clothes." The usual moment is a 20-minute stall over two options. The mistake is offering choices too early. Do it instead: lay out two complete outfits, let her choose between those, and keep the rejected one for tomorrow.
- **Generation rules**:
  - The moment must be specific and recognisable in under 3 seconds.
  - Advice must be actionable before the moment, not during it.
  - The fix must be repeatable, not a one-off.
  - No preview of the moment happening. The piece prepares, it does not tease.
  - The closing beat must show the version that worked, not just the warning.

## Three Examples

- **ID**: `threeExamples`
- **Name**: Three Examples
- **Definition**: One idea demonstrated three different ways, so the parent picks the version that fits their child.
- **Structure**:
  - The goal, one line, so the three are comparable
  - Example 1, the easiest, the one that always works
  - Example 2, the middle
  - Example 3, the hardest, for a child who resists
  - Which one to try first, given the child's temperament
- **Best for**: Anyone whose advice has to survive contact with a real child. Three versions converts a rule into a choice, which is what makes it usable.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Reel`
- **Best goals**: Saves, Shares, Authority
- **Example**: "Three ways to end a tantrum." One, distract and leave. Two, stay close and stay silent. Three, name the feeling and wait. Start with one unless the child escalates to the floor.
- **Generation rules**:
  - Exactly 3 examples, in ascending difficulty.
  - All three must serve the same goal. Three different problems is not this format.
  - Each example gets one beat and max 10 words on screen.
  - The closing beat must tell the parent how to choose between them.
  - None of the three may require anything bought or any professional.

## Quick Tip

- **ID**: `quickTip`
- **Name**: Quick Tip
- **Definition**: One simple activity or technique a parent can try immediately, demonstrated in a single beat.
- **Structure**:
  - The situation, one line
  - The quick technique, shown not described
  - Why it works, one sentence
  - The result, immediate
- **Best for**: A single free activity or technique a parent can try today. This format owns **activity demonstrations**: water pouring, dal-chawal sensory play, tape pulling, spoon transfer, two-bowl sorting, and the rest of that family.
- **Best content types**: `Reel`, `Trial Reel`, `Image Slideshow Reel`
- **Best goals**: Non-follower Reach, Saves, Shares
- **Example**: "Toddler maths — 1 biscuit = hungry, 2 = still hungry, 3 = MORE." Rio holds biscuits, expression escalates. Cuty unimpressed in background. No setup, just the reveal.
- **Generation rules**:
  - Exactly one technique. Not a list.
  - The technique uses something already in the house. Zero purchases.
  - **Activity demonstrations belong here.** A setup then play then result beat sequence is not a failure to match another shape; it is this shape. The handbook previously had no format for "show the activity", so six real ideas — water pouring, dal chawal, tape pull, spoon transfer, pouring, simple sorting — matched nothing at all and were reported as unresolvable. Widening this format's stated scope is cheaper and more honest than inventing an Activity Demonstration format to absorb them.
  - No explanation of why the child behaves this way. The technique speaks.
  - On-screen text max 8 words. The visual is the hook.
  - Duration 10-15 seconds if Reel/Trial Reel.

## Mini Story

- **ID**: `miniStory`
- **Name**: Mini Story
- **Definition**: A short narrative with a clear beginning, middle and end, told through Ria/Rio/Cuty.
- **Structure**:
  - The setup — character wants something
  - The obstacle — it does not go smoothly
  - The turning point — a small intervention or discovery
  - The resolution — character succeeds or learns
  - The parent takeaway, one line
- **Best for**: Emotional connection through character moments. The viewer watches for Ria/Rio/Cuty, not just the activity.
- **Best content types**: `Image Slideshow Reel`, `Reel`, `Carousel`
- **Best goals**: Relatability, Shares, Follows
- **Example**: "Cuty is stuck under the sofa." Ria panics. Rio thinks. Mumma suggests the broom handle. Cuty rescued. Takeaway: "Sometimes the solution is already in your hand."
- **Generation rules**:
  - Exactly 5 beats. Not 3, not 7.
  - Ria, Rio or Cuty must be the protagonist. Never a generic child.
  - The obstacle must be solvable with a household object, not magic.
  - The takeaway addresses the parent, not the child.
  - No moralising. The story teaches; the takeaway names the lesson.

## This or That

- **ID**: `thisOrThat`
- **Name**: This or That
- **Definition**: A direct choice between two options, presented so the audience picks one.
- **Structure**:
  - The question, visual and immediate
  - Option A, shown
  - Option B, shown
  - The parent context — why this choice matters
  - A gentle nudge toward the better option, without shame
- **Best for**: Engagement and comments. The format is literally a question the viewer answers.
- **Best content types**: `Carousel`, `Static Image`, `Story`
- **Best goals**: Comments, Relatability, Shares
- **Example**: "Toddler wants phone at dinner. Phone OR spoon-transfer activity?" Show both. Spoon-transfer wins. Caption: "Which one buys you 15 minutes of hot chai?"
- **Generation rules**:
  - Always two options. Never three.
  - Both options visually distinct. Not "red spoon" vs "blue spoon".
  - The better option is not morally superior. It is practically superior.
  - The nudge is optional. The audience's vote is the point.
  - Max 6 words per option on screen.

## Question → Answer

- **ID**: `questionAnswer`
- **Name**: Question → Answer
- **Definition**: One parent question, the exact words to say, and why those words work.
- **Structure**:
  - The exact question a parent asks
  - The common answer that lands badly
  - The exact words to say instead, quoted verbatim
  - Why this phrasing works, one sentence
  - One variation for a harder moment
- **Best for**: Language-building and TALK pillar content. Removes the cost of composing, so the parent acts today rather than later.
- **Best content types**: `Carousel`, `Static Image`, `Image Slideshow Reel`
- **Best goals**: Saves, Shares, Authority, Follows
- **Example**: "What to say when toddler asks for phone at lunch." Common: "No phone." Instead: "Phone baad mein. Abhi chhuri-chammach se khelo." Variation for escalation: "Phone baad mein. Pehle ek kaam karo, phir phone."
- **Generation rules**:
  - The quoted line must be quotable word for word. No paraphrasing.
  - 8 to 12 words per quoted line. Longer is not memorised.
  - Hinglish, the way the parent actually talks. Not formal English.
  - Never shame the child in the quoted line.
  - One variation only, not a list of alternatives.
  - The "why it works" sentence is mandatory — otherwise it is a script, not a lesson.

## Mistake → Recovery

- **ID**: `mistakeToRecovery`
- **Name**: Mistake → Recovery
- **Definition**: A single mistake the author made, the immediate consequence, and the recovery that worked.
- **Structure**:
  - The mistake, stated plainly
  - The consequence, shown
  - The recovery, step by step
  - What I do now to prevent it
  - The takeaway, one line to the viewer
- **Best for**: Building trust through vulnerability. A recovery that worked is more valuable than a perfect example.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: Authority, Relatability, Saves
- **Example**: "I raised my voice and Ria flinched." Rio started crying. I knelt down: "Mumma is cross, not gone." I counted to five, apologized, hugged. Now I keep my voice low and warn: "I am getting frustrated — I need a moment." Takeaway: "The repair is the relationship."
- **Generation rules**:
  - The mistake must be something a loving parent does. Never negligence.
  - The recovery must be specific and repeatable. No generic "I'm sorry."
  - No product or service as the fix. Free only.
  - The prevention step must be doable in under 30 seconds.
  - Beat 5 addresses the viewer as a peer.

## Two Truths And A Lie Parenting

- **ID**: `twoTruthsAndALieParenting`
- **Name**: Two Truths and a Lie: Parenting
- **Definition**: Three statements about parenting, one false — the viewer guesses which.
- **Structure**:
  - Statement 1, plausible
  - Statement 2, equally plausible
  - Statement 3, the lie
  - The reveal
  - Why the lie sounded true
- **Best for**: Comments and shares. Interaction without argument.
- **Best content types**: `Reel`, `Carousel`, `Story`
- **Best goals**: Comments, Shares, Relatability
- **Example**: "1: Ria hides under the table when she's shy. 2: Rio counts every spoon before eating. 3: Cuty asks for help with homework." The lie? Cuty is three. She does not do homework. But isn't it convincing?
- **Generation rules**:
  - All three statements must be specific to this brand's children.
  - The lie must be believable to another parent.
  - No lie may be harmful or shameful.
  - The reveal is text-only, no dramatic music.
  - The "why it sounded true" is mandatory.

## My Mistake Monday

- **ID**: `myMistakeMonday`
- **Name**: My Mistake Monday
- **Definition**: A weekly series where the author names one mistake and the lesson, posted consistently.
- **Structure**:
  - The day, stated as "Monday, week 3"
  - The mistake, one line
  - What I thought was happening
  - What was actually happening
  - The fix I will try this week
- **Best for**: Series consistency and follow building. The weekly cadence turns accountability into habit.
- **Best content types**: `Reel`, `Carousel`, `Story`
- **Best goals**: Follows, Relatability, Comments
- **Example**: "Monday, week 3: I stopped Cuty from climbing." I thought she was being reckless. She was practicing spatial reasoning on the sofa. The fix: give her a safe climbing spot and redirect.
- **Generation rules**:
  - Must be first person. Always.
  - The mistake must not involve child safety directly.
  - The fix must be free and doable by any parent.
  - Posted every Monday without fail.
  - The week number is always stated.

## Child Quote

- **ID**: `childQuote`
- **Name**: Child Quote
- **Definition**: A real thing a child said, set on screen with the context that makes it land.
- **Structure**:
  - The quote, exact words
  - The situation, one line
  - The parent's internal reaction
  - Why it is memorable
  - The takeaway, one line
- **Best for**: Relatability and saves. Parents save these because they are universal.
- **Best content types**: `Reel`, `Carousel`, `Static Image`, `Story`
- **Best goals**: Relatability, Saves, Shares
- **Example**: "Ria: 'Mama, your saree is dancing!'" Mumma walked fast. Ria giggled. That is what it looks like through her eyes. Takeaway: "They see everything — and they see the magic."
- **Generation rules**:
  - Quotes must be verbatim. No paraphrasing.
  - The child must be named.
  - No quote may be embarrassing or shameful.
  - The context is shown, not described.
  - On-screen text max 6 words per card.

## Show Don't Tell

- **ID**: `showDontTell`
- **Name**: Show Don't Tell
- **Definition**: A parenting principle demonstrated visually rather than explained.
- **Structure**:
  - The principle, named
  - What telling looks like
  - What showing looks like instead
  - The result, visual
  - The takeaway, one line
- **Best for**: Authority and saves. Parents remember what they see, not what they read.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Carousel`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Stay calm." Telling: "Ria, calm down!" Showing: Mumma's hand stays steady while she waits out the tantrum. Ria mirrors. Takeaway: "Your calm is contagious — yours, not theirs."
- **Generation rules**:
  - The principle must be named in beat 1.
  - The "telling" version must be a real parent phrase.
  - The "showing" version must be a physical action, not body language advice.
  - No voiceover. Visuals only.
  - Beat 5 is always the takeaway to the parent.

## One Thing Better

- **ID**: `oneThingBetter`
- **Name**: One Thing Better
- **Definition**: One thing the parent can improve, stated as a small upgrade not a fix.
- **Structure**:
  - The current thing, shown
  - The thing that already works about it
  - The one upgrade, small
  - The upgrade in action
  - The result, subtle but real
- **Best for**: Non-shaming improvement. Parents resist big fixes; small upgrades feel kind.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: Saves, Relatability, Authority
- **Example**: "Your evening rush." It works because you get dinner on the table. The upgrade: Ria sets the table while you stir. She feels involved, you feel less alone.
- **Generation rules**:
  - The upgrade must be doable in under 2 minutes.
  - Never shame the current version. Name what works first.
  - The upgrade uses something already in the house.
  - Show the result, do not describe it.
  - End on the parent feeling capable, not guilty.

## The Switch

- **ID**: `theSwitch`
- **Name**: The Switch
- **Definition**: The exact moment a parent realizes they need to change tactics, and the new one.
- **Structure**:
  - The old tactic, shown failing
  - The parent's realisation, one line
  - The internal choice: continue or switch
  - The new tactic, in action
  - The result, immediately visible
- **Best for**: Comments and shares. The "switch" moment is a hook every parent recognises.
- **Best content types**: `Reel`, `Trial Reel`, `Carousel`
- **Best goals**: Comments, Shares, Relatability
- **Example**: "Chasing Ria to get dressed." She runs every morning. I realise: I am playing chase, not dressing. I stop, sit on the bed, start singing the toothbrush song. She peeks, joins in. Takeaway: "Stop playing their game."
- **Generation rules**:
  - The old tactic must fail visually, not verbally.
  - The realisation is one line, no internal monologue.
  - The new tactic must cost nothing and use nothing bought.
  - The result shows within 3 seconds of the switch.
  - No voiceover — only text and sound.

## Parent Math

- **ID**: `parentMath`
- **Name**: Parent Math
- **Definition**: A calculation the parent is doing in their head, made visible.
- **Structure**:
  - The math, stated
  - The variables, shown
  - The calculation, visual
  - The result, unexpected
  - The takeaway, one line
- **Best for**: Humour and relatability. Every parent has done this exact arithmetic.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: Relatability, Shares, Comments
- **Example**: "6am wake = 2 snooze = 4 shower = 8 feed = 15 leave. But Ria needs 20 hugs each morning. 15 + 20 = running late. Solution: start hugging at 6."
- **Generation rules**:
  - The math must be something real parents actually do.
  - Numbers must be concrete, not abstract.
  - The visual must show the calculation, not just text.
  - No mockery of the parent's arithmetic.
  - Beat 5 is a tip, not a punchline.

## Yes And

- **ID**: `yesAnd`
- **Name**: Yes And
- **Definition**: Accepting the child's lead and building on it rather than redirecting.
- **Structure**:
  - The child's offer, stated
  - The parent's impulse to redirect
  - The choice to say "yes and"
  - What grows from it
  - The takeaway, one line
- **Best for**: Relationship building and creativity. Children who feel heard cooperate more.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Relatability, Saves, Authority
- **Example**: "Rio wants to wear a raincoat inside." Instead of 'no', I say 'yes and' — he can be a dinosaur with the coat as a tail. He plays for 10 minutes. I get dinner started. Takeaway: "Yes and" is a parent superpower.
- **Generation rules**:
  - The impulse to redirect must be shown, not just stated.
  - The "yes and" must add structure, not just approval.
  - What grows from it must be visible, not described.
  - No scenario where saying yes creates danger.
  - Beat 5 addresses the viewer directly.

## The Pause

- **ID**: `thePause`
- **Name**: The Pause
- **Definition**: The power of the pause before responding to a child's demand or outburst.
- **Structure**:
  - The moment that triggers a reaction
  - The parent's instinct to react immediately
  - The deliberate pause
  - The response chosen after the pause
  - The result, calmer
- **Best for**: Authority and saves. The pause is a skill every parent can learn.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`, `Static Image`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Ria throws her plate." My hand shoots up to speak. I stop. One count. "Ria, you are cross that lunch is over. Tell me." She sniffles: "I wanted more roti." I get another piece. Takeaway: "The pause is not delay. It is calibration."
- **Generation rules**:
  - The trigger must be shown, not described.
  - The instinct to react must be physical, visible.
  - The pause is at least one full second.
  - The response must be different from the instinctive one.
  - No voiceover. Text and sound only.

## What They See

- **ID**: `whatTheySee`
- **Name**: What They See
- **Definition**: How the parent appears through the child's eyes, not the parent's own lens.
- **Structure**:
  - The parent's view of the moment
  - The child's view, shown
  - The gap between them
  - The parent's adjustment
  - The result, in the child's behaviour
- **Best for**: Empathy and relatability. Parents forget children are small people with their own perspective.
- **Best content types**: `Reel`, `Image Slideshow Reel`, `Carousel`
- **Best goals**: Relatability, Shares, Comments
- **Example**: "I was busy." Mumma thought: I am cooking, this is normal. Ria saw: Mumma's back is turned, I do not exist. Mumma paused, knelt: "Ria, I see you." Ria leaned in. Takeaway: "They do not know you are busy. They only know you are gone."
- **Generation rules**:
  - The parent's view and the child's view must be visually distinct.
  - The child's view is shown at their eye level.
  - No judgment of the parent's view. It is normal, just unseen.
  - The adjustment must be small, not a full pivot.
  - End on the child's behaviour, not the parent's feeling.

## The Rule Of Three

- **ID**: `theRuleOfThree`
- **Name**: The Rule of Three
- **Definition**: Children learn in threes: show once, try once, do once.
- **Structure**:
  - The skill, named
  - First exposure — just watch
  - Second exposure — guided attempt
  - Third exposure — independent try
  - The result, the child succeeding
- **Best for**: Age-Based Skills and DO content. Gives parents a structure they can count on.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Static Image`
- **Best goals**: Saves, Authority, Follows
- **Example**: "Tying shoes." Watch me once. Try with my hand over yours. Try on your own. Ria's shoes are crooked but she did it. Takeaway: "Show three times, then get out of the way."
- **Generation rules**:
  - All three exposures must be shown, not described.
  - The skill must be doable with no special tools.
  - No skill may require verbal instruction on the third try.
  - The result must be a child attempt, not a parent win.
  - Beat 5 is a parent tip, not a child instruction.

## Feelings First

- **ID**: `feelingsFirst`
- **Name**: Feelings First
- **Definition**: Naming the emotion before solving the problem.
- **Structure**:
  - The behaviour, shown
  - The feeling behind it, named
  - The child's struggle to name it
  - The parent naming it for them
  - The problem solving that follows
- **Best for**: TALK pillar content. Language is the long game, but naming is the door.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Ria screams for the toy." She is not being greedy — she is disappointed. She does not have the word. Mumma: "You really wanted it. It hurts when you can't have it." Ria: "Yeah." Then: "Can we ask if they have extras?"
- **Generation rules**:
  - The feeling must be named, not guessed at.
  - The child must struggle to find the word. No perfect language.
  - The parent names it, not lectures about it.
  - Solving the problem comes after, not instead of.
  - No resolution where the child gets the toy.

## The Library Hack

- **ID**: `theLibraryHack`
- **Name**: The Library Hack
- **Definition**: A specific technique a parent can use, named and demonstrated.
- **Structure**:
  - The problem, one line
  - The hack, named
  - How it works, shown
  - The result, immediate
  - Save note: the name is the trigger to remember
- **Best for**: Saves and shares. Named hacks are what parents pass to each other.
- **Best content types**: `Carousel`, `Static Image`, `Reel`
- **Best goals**: Saves, Shares, Authority
- **Example**: "Screen time battles." The hack: 'First Next Last'. Before screen: 'First we eat, then next we watch, then last we turn off.' Ria knows the order before the battle starts.
- **Generation rules**:
  - The hack must have a name parents can repeat.
  - The name must be short — 3 words max.
  - Show the hack in action, do not describe it.
  - No product or service as the hack.
  - Beat 5 is a save reminder, not a moral.

## Mirror Moment

- **ID**: `mirrorMoment`
- **Name**: Mirror Moment
- **Definition**: A parent sees their own behaviour reflected in their child.
- **Structure**:
  - The child's behaviour, shown
  - The parent's recognition
  - The behaviour the parent shares
  - The parent's choice
  - The result, in both of them
- **Best for**: Comments and shares. Seeing yourself in your child is a quiet shock every parent feels.
- **Best content types**: `Reel`, `Carousel`, `Story`
- **Best goals**: Comments, Relatability, Follows
- **Example**: "Rio refuses to share." Mumma freezes — she was just doing the same thing on a work call. "I model this," she says aloud. Rio sees her sit. "Can I try?" He hands over the car. Takeaway: "They learn from watching. That is the job."
- **Generation rules**:
  - The recognition must be honest, not performative.
  - The parent's behaviour must be adult, not childish.
  - No shame. Name it, change it.
  - The result shows in both parent and child.
  - Beat 5 is a takeaway, not a lecture.

## The Anchor Word

- **ID**: `theAnchorWord`
- **Name**: The Anchor Word
- **Definition**: One word the parent uses consistently to signal safety or boundary.
- **Structure**:
  - The situation, named
  - The parent's usual response
  - The chosen anchor word
  - How the child responds to it
  - The result, calmer
- **Best for**: Authority and saves. One word repeated becomes a security blanket for the child.
- **Best content types**: `Reel`, `Carousel`, `Static Image`, `Story`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Tantrum at the grocery store." Instead of 'calm down,' Mumma says 'anchor.' She says it softly, makes eye contact. Ria looks up. "Anchor," she echoes. She takes Mumma's hand."
- **Generation rules**:
  - The anchor word must be neutral, not emotional.
  - It is introduced after a moment of calm, not during chaos.
  - The child must echo or respond to it.
  - No anchor word that sounds like a command.
  - Beat 5 is a parent note: "One word, repeated, becomes safety."

## The Two-Minute Rule

- **ID**: `theTwoMinuteRule`
- **Name**: The Two-Minute Rule
- **Definition**: If a task takes less than two minutes, do it now rather than planning it.
- **Structure**:
  - The task, named
  - The parent's tendency to defer
  - The two-minute threshold
  - Doing it now, shown
  - The result, less friction
- **Best for**: Practical DO content and saves. Parents hoard tasks that could be done in seconds.
- **Best content types**: `Carousel`, `Static Image`, `Reel`
- **Best goals**: Saves, Authority, Follows
- **Example**: "Shoes by the door." Mumma walks past them every morning and moves them mentally to 'later.' Today: two minutes. Shoes in the rack. Tomorrow: smooth exit. Takeaway: "Two minutes now saves twenty later."
- **Generation rules**:
  - The task must be genuinely under two minutes.
  - Show the deferral, then the action.
  - No product or tool needed.
  - The result is visible within the piece.
  - Beat 5 is a parent reminder, not a child instruction.

## Story Reel

- **ID**: `storyReel`
- **Name**: Story Reel
- **Definition**: A short narrative story with a twist and resolution, adapted from the viral reel format.
- **Structure**:
  - The setup — character wants something
  - The conflict — it does not go as planned
  - The twist — a small surprise or discovery
  - The resolution — problem solved or lesson learned
  - The takeaway, one line to the parent
- **Best for**: Emotional connection through character moments with Ria, Rio, and Cuty. The viewer watches for the characters, not just the message.
- **Best content types**: `Image Slideshow Reel`, `Reel`
- **Best goals**: Relatability, Shares, Follows
- **Example**: "Ria's surprise drawing." Ria draws Mumma's portrait. Mumma hangs it. Ria asks: "Where is yours?" Twist: Mumma has no portrait of herself. Resolution: they draw each other. Takeaway: "Children see us when we think we are invisible."
- **Generation rules**:
  - Exactly 5 beats. Not 3, not 7.
  - Ria, Rio or Cuty must be the protagonist.
  - The twist must come in beat 3, not beat 5.
  - The takeaway addresses the parent, not the child.
  - No moralising. Let the story teach.

## The Reframe

- **ID**: `theReframe`
- **Name**: The Reframe
- **Definition**: Shifting the parent's interpretation of a behaviour from negative to neutral or positive.
- **Structure**:
  - The behaviour, seen the old way
  - The parent's reaction, shown
  - The new interpretation, stated
  - The new reaction, shown
  - The result, calmer family atmosphere
- **Best for**: Relatability and saves. A reframe is a parent superpower they can steal.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Relatability, Saves, Authority
- **Example**: "Constant questions." Old view: Ria is demanding attention. New view: Ria is learning through language. New response: "That is your learning voice. Ask me five." She counts on her fingers. Takeaway: "Curiosity is not manipulation."
- **Generation rules**:
  - The old interpretation must be a real parent thought, not mockable.
  - The reframe must be specific, not "they are just kids."
  - Show the new reaction, do not describe it.
  - No reframe that ignores genuine needs.
  - Beat 5 is a takeaway the parent can steal.

## The Handoff

- **ID**: `theHandoff`
- **Name**: The Handoff
- **Definition**: How a parent gracefully transfers attention from one caregiver to another.
- **Structure**:
  - The current parent, engaged
  - The incoming parent, arriving
  - The child caught between
  - The handoff ritual, shown
  - The result, seamless transition
- **Best for**: Relatability and follows. Every household with two caregivers lives this.
- **Best content types**: `Reel`, `Carousel`, `Story`
- **Best goals**: Relatability, Follows, Comments
- **Example**: "Papa arrives home." Ria is mid-story to Mumma. Papa enters. I kneel: "Beta, Papa has the next chapter." She runs to him. Takeaway: "Transitions are rituals. Make them visible."
- **Generation rules**:
  - The handoff ritual must be specific, not "it's fine."
  - Show the child's resistance or hesitation.
  - Both parents must appear. Never hand off to silence.
  - The ritual takes under 10 seconds.
  - Beat 5 is a parent tip, not a child instruction.

## The 80/20 Rule

- **ID**: `the8020Rule`
- **Name**: The 80/20 Rule
- **Definition**: A parent gets 80 percent compliance naturally; the last 20 percent needs a different strategy entirely.
- **Structure**:
  - The goal, stated
  - The 80 percent, where it works naturally
  - The 20 percent, where it breaks down
  - The different strategy for 20 percent
  - The result, less frustration
- **Best for**: Authority and saves. Parents feel like failures at the 20 percent. Showing it is different work reframes everything.
- **Best content types**: `Carousel`, `Static Image`, `Reel`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Putting on shoes." 80 percent of the time, Ria does it herself. 20 percent: she sits and refuses. The strategy switches from "keep asking" to "give two choices, then carry." Takeaway: "The last 20 percent is not defiance. It is a different job."
- **Generation rules**:
  - The 80 percent must be effortless, not forced.
  - The 20 percent must be named as a different scenario.
  - The different strategy must be specific and free.
  - Show the strategy, do not describe it.
  - Beat 5 is a parent reframing statement.

## The Reset

- **ID**: `theReset`
- **Name**: The Reset
- **Definition**: A parent acknowledges a boundary breakdown and starts over with the child.
- **Structure**:
  - The breakdown, shown
  - The parent's recognition
  - The reset words
  - Starting over, shown
  - The result, repaired
- **Best for**: Trust and relatability. Children need to see parents repair, not just be perfect.
- **Best content types**: `Reel`, `Carousel`, `Story`
- **Best goals**: Relatability, Comments, Authority
- **Example**: "I yelled." Ria flinched. "Mumma sorry. My voice was loud. Let's start again." We both took a breath. "Can you try again?" "Yes." Takeaway: "A reset is not weakness. It is repair."
- **Generation rules**:
  - The breakdown must be shown, not described.
  - The reset words must be specific, not "sorry."
  - Both parent and child must participate in the reset.
  - The result shows within 3 seconds.
  - No voiceover. Text and sound only.

## The Substitute

- **ID**: `theSubstitute`
- **Name**: The Substitute
- **Definition**: Swapping an unavailable desired object for one that is already in the house.
- **Structure**:
  - The desired object, named
  - The parent's refusal impulse
  - The substitute, offered
  - The child's acceptance or negotiation
  - The result, redirected
- **Best for**: Saves and authority. The substitute is a parent hack worth saving.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: Saves, Authority, Relatability
- **Example**: "Phone." Rio reaches for it. "Not now. Here — the wooden block phone." He takes it, dials imaginary numbers. Takeaway: "The substitute is not a punishment. It is a bridge."
- **Generation rules**:
  - The substitute must use something already in the house.
  - Never shame the child for wanting the original.
  - The substitute must be presented positively, not as a consolation.
  - Show the child's negotiation, not just acceptance.
  - Beat 5 is a parent note.

## The Counting Boundary

- **ID**: `theCountingBoundary`
- **Name**: The Counting Boundary
- **Definition**: A parent states the boundary, counts, and follows through — without drama.
- **Structure**:
  - The boundary, stated once
  - The child's non-compliance
  - The count, calm
  - The follow-through, immediate
  - The result, the boundary holds
- **Best for**: Authority and follows. Parents need to see the calm count, not the theatrical one.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Authority, Follows, Comments
- **Example**: "Time to clean up." Ria keeps building. "You have to toys in the bin by the time I count to five." One... two... three... she is on the fourth. "Four." She runs. Takeaway: "The count is the boundary. Not the drama."
- **Generation rules**:
  - The count must be calm, not escalating.
  - The follow-through must be immediate, not delayed.
  - No count above five. Ever.
  - The result must show the boundary holding.
  - Beat 5 is a parent takeaway.

## The Invitation

- **ID**: `theInvitation`
- **Name**: The Invitation
- **Definition**: Offering a choice that leads to the desired outcome rather than a direct request.
- **Structure**:
  - The desired outcome, stated
  - The parent's direct request impulse
  - The invitation, offered
  - The child's choice
  - The result, cooperation
- **Best for**: Saves and authority. Invitations feel like choice, not control.
- **Best content types**: `Reel`, `Carousel`, `Static Image`, `Story`
- **Best goals**: Saves, Authority, Relatability
- **Example**: "Eat vegetables." Instead: "Would you like carrots or peas?" Ria points to peas. She eats them. Takeaway: "Choice is the oldest cooperation trick."
- **Generation rules**:
  - Both options must be genuinely acceptable to the parent.
  - The invitation must be phrased as a question.
  - Show the child's choice, not just compliance.
  - No fake choices where only one outcome is allowed.
  - Beat 5 is a parent note.

## The Observation

- **ID**: `theObservation`
- **Name**: The Observation
- **Definition**: Noticing and naming a child's competence or growth without praise.
- **Structure**:
  - The behaviour, observed
  - The parent's impulse to praise
  - The parent's statement, instead
  - The child's response
  - The result, the child tries again
- **Best for**: Authority and saves. Praise motivates the parent; observation motivates the child.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Ria stacks blocks." She wobbles. Instead of 'good job,' Mumma says: 'You noticed the base needed to be wider.' Ria looks at her tower, adjusts. Takeaway: "Observation names the skill. Praise names the parent."
- **Generation rules**:
  - The observation must be about the child's thinking, not appearance.
  - No comparison to other children.
  - Show the child's response, not just compliance.
  - The observation is one sentence, not a paragraph.
  - Beat 5 is a parent takeaway.

## The Script Handoff

- **ID**: `theScriptHandoff`
- **Name**: The Script Handoff
- **Definition**: Teaching a peer script for a social moment a child will face, practiced before the moment.
- **Structure**:
  - The upcoming moment, named
  - The child's usual response
  - The script, taught
  - The script practiced
  - The moment, script used
- **Best for**: TALK and Authority. Scripts reduce anxiety for both child and parent.
- **Best content types**: `Carousel`, `Static Image`, `Image Slideshow Reel`
- **Best goals**: Authority, Saves, Follows
- **Example**: "New friend says 'you can't play.'" Script: 'I can show you how to play next.' Practice: Rio says it to his dinosaur. The moment: Rio says it to the other child. Takeaway: "Scripts are training wheels for social moments."
- **Generation rules**:
  - The script must be under 5 words.
  - Practice must happen, not just be stated.
  - The script must be the child's, not the parent's.
  - No script that requires adult presence.
  - Beat 5 is a parent note.

## The 15-Minute Check

- **ID**: `the15MinuteCheck`
- **Name**: The 15-Minute Check
- **Definition**: A quick, regular check-in that prevents escalation.
- **Structure**:
  - The pattern, named
  - The parent's usual reaction
  - The 15-minute check, introduced
  - The check in action
  - The result, no escalation
- **Best for**: Authority and saves. Prevention is cheaper than intervention.
- **Best content types**: `Reel`, `Carousel`, `Static Image`
- **Best goals**: Authority, Saves, Relatability
- **Example**: "Afternoon energy crash." Every day at 3pm, Ria gets wild. Instead of waiting for meltdown: "15-minute check." At 2:45: "How is your body feeling?" She says: "Wiggly." We dance for 2 minutes. Takeaway: "Catch them before they crash."
- **Generation rules**:
  - The check must happen before escalation, not after.
  - It must be routine, not spontaneous.
  - Show the check, do not describe it.
  - No product needed.
  - Beat 5 is a parent takeaway.

## The Choice Menu

- **ID**: `theChoiceMenu`
- **Name**: The Choice Menu
- **Definition**: Presenting a small set of options within a boundary, so the child chooses without losing the limit.
- **Structure**:
  - The limit, stated
  - The child's reaction
  - The choices, offered
  - The child's choice
  - The result, limit held and child empowered
- **Best for**: Saves and authority. A limit with a menu of choices feels fair, not arbitrary.
- **Best content types**: `Carousel`, `Static Image`, `Reel`
- **Best goals**: Saves, Authority, Comments
- **Example**: "No park today — rain." Ria protests. "Choose: indoor obstacle course or blanket fort?" She picks fort. "We build together." Takeaway: "A menu of choices holds the limit and offers agency."
- **Generation rules**:
  - The limit is stated first, not bargained after.
  - Both choices must be acceptable to the parent.
  - The child must actually choose, not default.
  - No choice that undermines the limit.
  - Beat 5 is a parent note.

## The Echo

- **ID**: `theEcho`
- **Name**: The Echo
- **Definition**: Reflecting back what the child said, so they hear their own words as valid.
- **Structure**:
  - The child's words, stated
  - The parent's usual response
  - The parent's reflection, back
  - The child's reaction
  - The result, heard
- **Best for**: TALK and relatability. Children want to be heard; echoing proves they were.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Relatability, Authority, Comments
- **Example**: "I want to be first!" Mumma: 'You feel like being first really matters to you.' Ria: 'Yes.' 'Tell me about it.' Ria explains. Takeaway: "An echo is not agreement. It is acknowledgement."
- **Generation rules**:
  - The reflection must not add advice or correction.
  - Show the child's reaction, not just compliance.
  - The child must speak again after the echo.
  - No echo when the child is in genuine distress.
  - Beat 5 is a parent takeaway.

## The 3 AM Rule

- **ID**: `the3AmRule`
- **Name**: The 3 AM Rule
- **Definition**: If the parent would not do it at 3 AM, it is not needed.
- **Structure**:
  - The urge, named
  - The parent's question: 3 AM?
  - The answer, honest
  - The choice, made
  - The result, lighter
- **Best for**: Saves and relatability. Parents are exhausted and doing too much.
- **Best content types**: `Carousel`, `Static Image`, `Reel`, `Story`
- **Best goals**: Saves, Relatability, Authority
- **Example**: "Check Ria's homework again." 3 AM? No. She checked it this morning. The anxiety, not the task, is knocking. Takeaway: "If it survives the night, it is not urgent."
- **Generation rules**:
  - The 3 AM question must be genuinely asked.
  - The answer must be honest.
  - No 3 AM rule that dismisses genuine needs.
  - Show the choice, not just the result.
  - Beat 5 is a parent takeaway.

## The Micro Win

- **ID**: `theMicroWin`
- **Name**: The Micro Win
- **Definition**: Celebrating a tiny step forward without fanfare or praise.
- **Structure**:
  - The small step, shown
  - The parent's notice
  - The parent's acknowledgment
  - The child's response
  - The momentum, building
- **Best for**: Relatability and saves. Parents miss micro wins and wonder why motivation fades.
- **Best content types**: `Reel`, `Carousel`, `Image Slideshow Reel`
- **Best goals**: Relatability, Saves, Authority
- **Example**: "Rio puts one block in the bin." Not the whole tower. One. Mumma: 'I saw that.' He grins. Puts another. Takeaway: "Micro wins are not small. They are the foundation."
- **Generation rules**:
  - The step must be genuinely small, not a whole task.
  - No celebration. Just acknowledgment.
  - Show the momentum, not just the step.
  - No praise language ("good job," "amazing").
  - Beat 5 is a parent takeaway.

## The Exit Strategy

- **ID**: `theExitStrategy`
- **Name**: The Exit Strategy
- **Definition**: How to gracefully end an activity so the child transitions without resistance.
- **Structure**:
  - The activity, named
  - The parent's usual ending
  - The exit strategy, stated
  - The exit, in action
  - The result, smooth
- **Best for**: Authority and saves. Transitions are the daily battle every parent fights.
- **Best content types**: `Reel`, `Carousel`, `Static Image`, `Story`
- **Best goals**: Authority, Saves, Relatability, Follows
- **Example**: "Blocks." Instead of 'clean up now,' Mumma says: 'Five more minutes, then we sweep together.' Timer dings. Rio: 'Timer!' 'Ready?' 'Yes!' Takeaway: "The exit strategy is the promise. Keep it."
- **Generation rules**:
  - The strategy must be named, not described.
  - It must involve the child, not just announce to them.
  - Show the transition, not just the strategy.
  - No strategy that uses time pressure as punishment.
  - Beat 5 is a parent note.

## The Anchor Routine

- **ID**: `theAnchorRoutine`
- **Name**: The Anchor Routine
- **Definition**: A consistent sequence that marks the start or end of a transition, giving the child a predictable rhythm.
- **Structure**:
  - The transition, named
  - The parent's usual approach
  - The anchor routine, established
  - The anchor in action
  - The result, predictable
- **Best for**: Authority and follow building. Routines are the invisible scaffolding children lean on.
- **Best content types**: `Carousel`, `Image Slideshow Reel`, `Reel`
- **Best goals**: Authority, Follows, Saves
- **Example**: "Morning departure." Instead of chaos: 'Wash hands, shoes by door, wave to Cuty.' Same order every day. Rio knows what comes next. Takeaway: "An anchor routine is a sentence the child can predict."
- **Generation rules**:
  - The routine must be under 30 seconds.
  - It must use something already in the house.
  - Show the routine, do not describe it.
  - No routine that requires adult assistance at every step.
  - Beat 5 is a parent takeaway.

