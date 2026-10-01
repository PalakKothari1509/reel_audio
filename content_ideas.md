# Fun Learning With Palak, Content Idea Library

**This file is the source of truth for content ideas.** The app does not invent ideas,
it reads them from here. You edit this file as we go, and I sync it into the app.

Last synced from the app: 24 post packages and 30 hooks.

---

## How to use this file

Each idea is one `##` section. Edit anything, add new ideas at the bottom, and tell
me to sync. Nothing here is hardcoded into Flutter, so changing an idea never means
recompiling.

An idea only needs **Series**, **Topic**, and **Problem** to be usable. Everything
else you can leave blank and I will propose a value before we generate.

### Every idea has these fields

This is the canonical schema. The app parser reads these names.

| Field | Required | Purpose |
|---|---|---|
| `ID` | yes | Unique, stable, never reused |
| `Series` | yes | Which pillar it belongs to |
| `Title` | yes | Internal name, not the caption |
| `Topic` | yes | What it is actually about |
| `Format` | yes | Reel, Trial Reel, Image Reel, Carousel, Static, Story |
| `Production` | yes | How it gets made: Character, Image, Video, Text |
| `Goal` | yes | Reach, Followers, Saves, Shares, Engagement, Community |
| `Audience Problem` | yes | The specific problem it solves |
| `Characters` | yes | Ria, Rio, Cuty, Mumma, Papa, Daadi, Teacher |
| `Age` | yes | 1-2, 2-3, 3-4, or 1-4 |
| `Content Format` | yes | Narrative shape: Problem → Jugaad → Result → Moral |
| `Hook Angle` | yes | Curiosity, Relatable, Problem, Surprising |
| `Status` | yes | Idea, Draft, Ready, Posted, Tracked |
| `Priority` | yes | High, Medium, Low |
| `Test Number` | when testing | 1/5, 2/5, 3/5, 4/5, 5/5 |
| `Notes` | optional | Your changes, what to try differently |
| `Performance` | after posting | The numbers, kept in Versions |

**`Format` and `Production` overlap and I want to flag it.** `Image Reel` appears
in your list as both a Format and a Production value, and `Character Reel`
appears as a Production that implies a Reel Format. As long as you always write
Format first and Production second, the parser can use Format to decide the shape
of the package and Production to decide the visual direction. It works, it is just
worth knowing they are not fully independent axes.

**Same idea, two executions:**

```
jugaadu-mummy + toddler wants phone at lunch
  Format: Reel        Production: Character  Goal: Reach     Content Format: Problem → Jugaad → Result → Moral
  Format: Carousel    Production: Static     Goal: Saves    Content Format: Do This Not That
```

**Test Number matters more than it looks.** A format is not judged after one post.
The app shows `2/5 tests` so a single weak result does not kill a format that
deserves five tries.

---

## Series

Your four pillars, which replace the seven working series I had guessed at.

| id | Pillar | What is inside it | Who appears |
|---|---|---|---|
| jugaadu-mummy | Jugaadu Mummy | Low-cost and zero-cost play, kitchen and household items, screen-free alternatives, everyday Indian parenting situations, simple fixes | Ria, Mumma |
| little-stories | Little Stories, Big Lessons | Short Ria/Rio/Cuty stories, an everyday preschool problem, a warm ending, one small lesson | Ria, Rio, Cuty |
| learning-through-play | Learning Through Play | Preschool learning, Montessori-inspired activities, numbers, colours, shapes, matching, sorting | Ria, Rio, Cuty |
| parenting-relatability | Parenting Relatability | Real mummy moments, toddler behaviour, expectation vs reality, POVs, everyday chaos | Mumma, Ria, Rio |

**Two gaps worth naming.** The 24 existing posts contain two kinds that none of
these four pillars describes: the age-based milestone checklists (`day6`, `day11`)
and the audience-engagement posts (`day13`, `day14`, `day15`, `day16`, `day25`).
I have left them in their own series rather than forcing them under a pillar that
does not fit. Tell me if you would rather they join one.

| id | Series | What is inside it |
|---|---|---|
| milestone-check | Milestone Check | Age-based skill checklists, gentle and non-competitive |
| the-casts | The Cast | Votes, favourites, week wrap ups, behind the scenes |


---

## Formats

| id | Name | Shape | Best for |
|---|---|---|---|
| problem-fix | Problem → Fix | Setup, problem, practical solution | Relatable parenting wins |
| expectation-reality | Expectation vs Reality | What you expect, what actually happens | Humor and relatability |
| pov | POV | You are in the moment | Relatable, shareable |
| do-this-not-that | Do This, Not That | Wrong way, right way | Saves and parenting tips |
| mistakes | Mistakes Parents Make | Mistake, why, instead | Authority and saves |
| mini-story | Mini Story | Character, moment, warm ending | Story Reels, emotional |
| quick-tip | Quick Tip | One idea, one line | Static and Stories |
| question-answer | Question → Answer | Parent question, real answer | Conversation posts |
| save-list | Save This List | Numbered list worth saving | Carousels |
| three-examples | Three Examples | Three clear instances | Carousels and Reels |
| this-or-that | This or That | Two options, pick one | Engagement and comments |

---

## Which content type should an idea become

The short version, so we stop re-deciding it every time.

**Reach, and you have not tested the idea.** Make it a **Trial Reel**. Instagram
shows it to non-followers first, so it costs you nothing to find out whether the
hook works. Do this first for anything new.

**Reach, and the format already worked before.** Make it a **Reel**. Same idea, now
aimed at people who already follow you, so you can keep the character story going.

**You have stills or illustrations but no video.** Make it an **Image Reel**. This
is what the seven Missions posts already are, and it is the cheapest way to keep a
series going weekly without shooting anything.

**Saves.** Carousel. A list someone wants to come back to is a list they will save,
and saves are the signal that tells Instagram the post is worth showing to more
people.

**Engagement or comments.** Carousel or Static with a question on it. Polls, "which
one does your toddler do", "comment YES or NO".

**Parent wants to feel seen.** Reel. Relatable chaos in the first second does that
better than any slide.

One rule I would keep: **do not judge a format after one test.** An idea that failed
as a Trial Reel may be a great Carousel. That is what the Versions history at the
bottom of each idea is for.

---

### How the app picks the format for you

You should not have to remember which format fits which idea. The app proposes one,
shows you why, and lets you override.

| The idea is | Recommend | Why the app says it |
|---|---|---|
| A list of things | Carousel | List-based and worth returning to. Parents screenshot and save the solutions. |
| A POV or an emotion | Trial Reel | Highly relatable and testable without a complex story. Cheap to produce, cheap to lose. |
| A problem that can be dramatised | Character Reel | The problem needs a face and a reaction to land in three seconds. |
| Something a parent will look up again | Carousel | Reference content ages well and keeps earning saves. |
| A story with a character arc | Reel | Needs enough time to set up and pay off. |
| A still that makes one point | Static | Anything longer is effort for one message. |
| Something new and unproven | Trial Reel | Costs nothing to test. Instagram shows it to non-followers first. |

The app always shows the reason next to the recommendation, in one line, so you
learn the pattern instead of trusting it blindly.

**The app also recommends the goal.** Reach when the idea is emotional and broad,
Saves when it is a list or a reference, Shares when it is a fix for a specific
moment, Followers when it leans on character recognition, Engagement when it ends
in a question, Community when it is an inside joke or a vote.

---

## Goal

| id | Name | The generator optimises for |
|---|---|---|
| reach | Reach | Curiosity hook, fast understanding, non-follower appeal |
| followers | Followers | Character recognition, "follow for the next one" |
| saves | Saves | Something worth returning to, checklist or reference |
| shares | Shares | "Send this to a parent who needs this" |
| engagement | Engagement | A question the parent will answer |
| community | Community | Inside joke, vote, belonging |

---

## Ideas

Status ladder: Idea → Ready → Generated → Trial → Posted → Testing → Winner → Reuse

### 1. Which One Doesn't Belong?

- **id:** `day2-which-doesnt-belong`
- **Series:** play-at-home
- **Topic:** Spot the odd one out from four objects
- **Problem:** Four illustrated objects side by side: apple, banana, orange, car
- **Lesson:** The car. It is the only one that is not food
- **Format:** Quick Tip
- **Best content type:** Carousel
- **Alternative:** Trial Reel
- **Goal:** Saves
- **Why this type:** It is already a reveal. A carousel lets the answer sit on the
  last slide instead of being given away in second one
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** Medium
- **Notes:** Strong first carousel. Keep the answer off slide 1.

### 2. Mumma Says This 100x a Day

- **id:** `day3-mumma-says`
- **Series:** jugaadu-mummy
- **Topic:** The five things a mother says all day
- **Problem:** Shoes on, where is your water, do not run, stop fighting, come here
- **Lesson:** These are not nagging, they are the running commentary of parenting
- **Format:** POV
- **Best content type:** Reel
- **Alternative:** Trial Reel
- **Goal:** Reach
- **Why this type:** Pure relatability with no information to read. It has to be
  felt in three seconds, which a Reel does and a carousel does not
- **Duration:** 15 to 20 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** High
- **Notes:** Good first Trial Reel candidate. Nobody needs to follow you to enjoy it.

### 3. 5-Minute Kitchen Challenge

- **id:** `day4-kitchen-challenge`
- **Series:** play-at-home
- **Topic:** Five spoons of different sizes, one sorting game
- **Problem:** What you need is 5 spoons from the kitchen drawer
- **Lesson:** Sizing and sorting are real maths, and it took five minutes
- **Format:** Save This List
- **Best content type:** Carousel
- **Alternative:** Image Reel
- **Goal:** Saves
- **Why this type:** Steps. A parent comes back to this one, which is exactly what a
  save means
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** High

### 4. Ask Your Child This Tonight

- **id:** `day5-ask-tonight`
- **Series:** ria-adventures
- **Topic:** One question to ask at bedtime instead of how was your day
- **Problem:** How was your day gets a one word answer every single time
- **Lesson:** Better questions get better stories
- **Format:** Question → Answer
- **Best content type:** Carousel
- **Alternative:** Static Image
- **Goal:** Saves
- **Why this type:** It is a reference a parent keeps. Carousel
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** High

### 5. Can Your 3-Year-Old Do These?

- **id:** `day6-3year-skills`
- **Series:** milestone-check
- **Topic:** Age 3 skill checklist
- **Problem:** Parents worry they are behind. They are not
- **Lesson:** Every child at their own pace
- **Format:** Save This List
- **Best content type:** Carousel
- **Alternative:** Static Image
- **Goal:** Saves
- **Why this type:** Pure reference content. Saveable, and it ages well
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** High
- **Notes:** Pair this with the 4-year-old one. Same design, posted a month apart.

### 6. Toddler Mathematics

- **id:** `day7-toddler-math`
- **Series:** cuty-lessons
- **Topic:** Toddler maths, said out loud
- **Problem:** Two plus one is three, unless it is two cups and one banana
- **Lesson:** Maths is counting real things, not numbers on paper
- **Format:** Expectation vs Reality
- **Best content type:** Reel
- **Alternative:** Trial Reel
- **Goal:** Reach
- **Why this type:** The joke only lands with timing
- **Duration:** 15 to 20 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** High

### 7. Find the Hidden Cuty!

- **id:** `day8-find-cuty`
- **Series:** cuty-lessons
- **Topic:** Hidden bunny in a busy picture
- **Problem:** Cuty is hiding somewhere in the scene
- **Lesson:** Careful looking beats fast looking
- **Format:** Quick Tip
- **Best content type:** Trial Reel
- **Alternative:** Carousel
- **Goal:** Reach
- **Why this type:** Built for retention. A hidden object is a reason to watch twice,
  and watch twice is what Trial Reels are looking for
- **Duration:** 10 to 15 sec
- **Language:** English
- **Status:** Idea
- **Priority:** High

### 8. The Sock Hunt

- **id:** `day9-sock-hunt`
- **Series:** play-at-home
- **Topic:** Matching laundry becomes a game
- **Problem:** Clean laundry, one toddler, twenty minutes of free time
- **Lesson:** Chores are easier when they are a hunt
- **Format:** Problem → Fix
- **Best content type:** Reel
- **Alternative:** Trial Reel
- **Goal:** Reach
- **Why this type:** Before and after. You need to see the pile and then the basket
- **Duration:** 20 to 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** High
- **Notes:** Zero cost to make. Uses your own laundry.

### 9. 3 Questions Every Parent Should Ask This Week

- **id:** `day10-3-questions`
- **Series:** ria-adventures
- **Topic:** Three questions that make a toddler talk
- **Problem:** Toddlers answer in one word, so conversation dies
- **Lesson:** Ask what and how, not what happened
- **Format:** Save This List
- **Best content type:** Carousel
- **Alternative:** Static Image
- **Goal:** Saves
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** Medium

### 10. Can Your 4-Year-Old Do These?

- **id:** `day11-4year-skills`
- **Series:** milestone-check
- **Topic:** Age 4 skill checklist
- **Problem:** Same as the 3-year-old list
- **Lesson:** Age 4 is about joining two ideas together
- **Format:** Save This List
- **Best content type:** Carousel
- **Alternative:** Static Image
- **Goal:** Saves
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** Medium

### 11. Three Types of Kids at Dinner

- **id:** `day12-dinner-types`
- **Series:** jugaadu-mummy
- **Topic:** Three kinds of toddler at dinner time
- **Problem:** The finicky one, the hoarder, the one who only wants what you are eating
- **Lesson:** Pick your battles, not every one
- **Format:** Three Examples
- **Best content type:** Reel
- **Alternative:** Trial Reel
- **Goal:** Engagement
- **Why this type:** Three beats, three characters reacting. Then ask which one is
  yours, which is where the comments come from
- **Duration:** 20 to 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** High

### 12. What Comes Next?

- **id:** `day13-pattern-game`
- **Series:** play-at-home
- **Topic:** Pattern completion game with household objects
- **Problem:** Red, blue, red, blue, what comes next
- **Lesson:** Patterns are the first step into reading
- **Format:** Quick Tip
- **Best content type:** Trial Reel
- **Alternative:** Carousel
- **Goal:** Saves
- **Why this type:** The pause before the answer is the whole hook, and only video
  makes a parent wait for it
- **Duration:** 10 to 15 sec
- **Language:** English
- **Status:** Idea
- **Priority:** High

### 13. Which New Format Was Your Favorite?

- **id:** `day14-favorite-format`
- **Series:** the-casts
- **Topic:** Ask the audience which format worked best
- **Problem:** Seven formats posted, no idea which to keep making
- **Lesson:** Your audience will tell you if you let them
- **Format:** This or That
- **Best content type:** Static Image
- **Alternative:** Story
- **Goal:** Community
- **Why this type:** It is one question on one slide. Anything more is effort for a
  yes or no answer
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** Medium

### 14. How to Play Each Mission With Household Items

- **id:** `day15-household-swaps`
- **Series:** play-at-home
- **Topic:** Seven missions, remade with things already in the house
- **Problem:** Seven activities that sounded great but needed specific toys
- **Lesson:** The toy does not matter, the child does
- **Format:** Save This List
- **Best content type:** Carousel
- **Alternative:** Static Image
- **Goal:** Saves
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** High
- **Notes:** This is the one that removes the last excuse. Very high save potential.

### 15. You Voted! Here's Which Mission Won

- **id:** `day16-voted-mission-won`
- **Series:** the-casts
- **Topic:** Announce the audience's winning mission
- **Problem:** Votes came in for the sock hunt
- **Lesson:** The next one is because you asked
- **Format:** This or That
- **Best content type:** Static Image
- **Alternative:** Reel
- **Goal:** Community
- **Why this type:** It closes a loop the audience started. That is worth a single
  slide, and it makes the next post feel like their idea too
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** Medium
- **Notes:** Always follow this with a Reel of the winning mission. The pair works.

### 16. Mission 2: On Your Mark!

- **id:** `day17-mission1-race-track`
- **Series:** play-at-home
- **Topic:** Race track from cushions and masking tape
- **Problem:** Toddler and one biscuit, and a lot of energy
- **Lesson:** Running off that energy indoors is possible
- **Format:** Problem → Fix
- **Best content type:** Image Reel
- **Alternative:** Reel
- **Goal:** Reach
- **Why this type:** No video exists and you do not need one. Stills with narration
  carry this perfectly and take an evening, not a day
- **Duration:** 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** Medium
- **Notes:** Part of the 7 Missions run. Keep them all the same length so they can be
  reposted as one reel later, see idea 22.

### 17. Mission 3: Living Room Concert!

- **id:** `day18-mission2-concert`
- **Series:** play-at-home
- **Topic:** Living room concert with pots and spoons
- **Problem:** Loud, energetic, and needs a reason to be allowed
- **Lesson:** Noise is fine when it is music
- **Format:** Problem → Fix
- **Best content type:** Image Reel
- **Alternative:** Reel
- **Goal:** Reach
- **Duration:** 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** Medium

### 18. Mission 4: Art Corner Time!

- **id:** `day19-mission3-art-studio`
- **Series:** play-at-home
- **Topic:** Draw with crayons and household bits
- **Problem:** Crayons get used, paper runs out, and the floor gets covered
- **Lesson:** The art matters less than the sitting still
- **Format:** Problem → Fix
- **Best content type:** Image Reel
- **Alternative:** Carousel
- **Goal:** Saves
- **Duration:** 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** Medium

### 19. Mission 5: Case Open!

- **id:** `day20-mission4-detective`
- **Series:** play-at-home
- **Topic:** Which object does not belong, detective edition
- **Problem:** Five objects, one is hiding
- **Lesson:** Comparing things carefully is a skill you can practise
- **Format:** Quick Tip
- **Best content type:** Image Reel
- **Alternative:** Trial Reel
- **Goal:** Reach
- **Duration:** 30 sec
- **Language:** English
- **Status:** Idea
- **Priority:** Medium

### 20. Mission 6: Rescue Time!

- **id:** `day21-mission5-rescue`
- **Series:** play-at-home
- **Topic:** Cuty is stuck somewhere, rescue the bunny
- **Problem:** The bunny is under the sofa and nobody is moving it
- **Lesson:** A problem with a clear solution is a good story
- **Format:** Mini Story
- **Best content type:** Image Reel
- **Alternative:** Reel
- **Goal:** Reach
- **Duration:** 30 sec
- **Language:** English
- **Status:** Idea
- **Priority:** Medium

### 21. Mission 7: Treasure Hunt!

- **id:** `day22-mission6-treasure`
- **Series:** play-at-home
- **Topic:** Treasure hunt around one room
- **Problem:** One small thing, three clues, one very excited toddler
- **Lesson:** Clues are language in play
- **Format:** Mini Story
- **Best content type:** Image Reel
- **Alternative:** Reel
- **Goal:** Reach
- **Duration:** 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** Medium

### 22. Mission 8: Self-Care Squad!

- **id:** `day23-mission7-daily-care`
- **Series:** play-at-home
- **Topic:** Toddler brushing their own teeth, properly
- **Problem:** You used to do it, now they want to, now it is a battle
- **Lesson:** Letting them take over badly first is how they learn to do it well
- **Format:** Problem → Fix
- **Best content type:** Image Reel
- **Alternative:** Carousel
- **Goal:** Saves
- **Duration:** 30 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** High
- **Notes:** Strongest of the eight for saves. Consider splitting into two posts.

### 23. 7 Missions in 60 Seconds

- **id:** `day24-trial-reel-7-missions`
- **Series:** play-at-home
- **Topic:** All seven missions compressed into one minute
- **Problem:** Seven good ideas buried in seven posts, none of them seen
- **Lesson:** Sometimes the summary is the better post
- **Format:** Three Examples
- **Best content type:** Trial Reel
- **Alternative:** Reel
- **Goal:** Reach
- **Why this type:** Fast cuts and no explanation. This is the shape Trial Reels want
  and it also works as a recap for people who followed the whole run
- **Duration:** 60 sec
- **Language:** Hinglish
- **Status:** Idea
- **Priority:** High
- **Notes:** Make this one first if you want to test whether the Missions run has legs.

### 24. We Completed All 7 Missions! Here's What Happened

- **id:** `day25-week-wrap-up`
- **Series:** play-at-home
- **Topic:** Results and what the audience said
- **Problem:** Seven posts, no idea which to repeat
- **Lesson:** Look at the numbers before planning the next week
- **Format:** Save This List
- **Best content type:** Carousel
- **Alternative:** Static Image
- **Goal:** Community
- **Duration:** n/a
- **Language:** English
- **Status:** Idea
- **Priority:** Medium

---

### 25. Phone During Meals

- **id:** `jm-phone-meals`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Character | **Goal:** Reach + Shares
- **Topic:** Toddler demanding the phone instead of eating
- **Audience Problem:** Mealtime is a battle because the only thing that works is a screen
- **Characters:** Ria + Mumma | **Age:** 1-4
- **Content Format:** Problem → Jugaad → Result → Moral
- **Hook Angle:** Relatable
- **Hook:** "Phone ke bina khana nahi khata? 😭"
- **Status:** Idea | **Priority:** High
- **Notes:** One YES alternative beats one more NO. Full worked example exists, see master prompt.

### 26. Hot Chai

- **id:** `jm-hot-chai`
- **Series:** jugaadu-mummy | **Format:** Trial Reel | **Production:** Image Reel | **Goal:** Reach
- **Topic:** POV Mumma finally gets to drink her hot chai
- **Audience Problem:** Mumma never finishes anything warm while the toddler is awake
- **Characters:** Mumma + Ria | **Age:** 1-4
- **Content Format:** POV → small win → quiet laugh
- **Hook Angle:** Relatable
- **Status:** Trial | **Priority:** High
- **Notes:** Cheapest high-relatable post to make. Strong first trial candidate.

### 27. Kitchen Busy Basket

- **id:** `jm-kitchen-busy-basket`
- **Series:** jugaadu-mummy | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Topic:** Five safe household items that buy 20 minutes of independent play
- **Audience Problem:** Mumma needs a few minutes of peace without buying a new toy
- **Characters:** Ria | **Age:** 1-4
- **Content Format:** Five-item list
- **Hook Angle:** Curiosity
- **Hook:** "Toy box band karo. Kitchen kholo! 👀"
- **Status:** Idea | **Priority:** High

### 28. Water Pouring

- **id:** `jm-water-pouring`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Video | **Goal:** Reach
- **Topic:** Pouring water between two containers
- **Audience Problem:** No activity that survives more than two minutes
- **Characters:** Ria | **Age:** 1-2
- **Content Format:** Setup → play → satisfied ending
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High

### 29. Dal Chawal Sensory Play

- **id:** `jm-dal-chawal`
- **Series:** jugaadu-mummy | **Format:** Image Reel | **Production:** Image | **Goal:** Reach
- **Topic:** Texture play with cooked dal and rice
- **Audience Problem:** Kitchen ingredients get wasted and the child is bored
- **Characters:** Ria + Rio | **Age:** 2-4
- **Content Format:** Materials → play → cleanup
- **Hook Angle:** Surprising
- **Status:** Idea | **Priority:** Medium

### 30. Tape Pull Activity

- **id:** `jm-tape-pull`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Video | **Goal:** Shares
- **Topic:** Painter's tape stuck to the floor for small hands to pull
- **Audience Problem:** Need an activity that is free and survives a long attention span
- **Characters:** Rio | **Age:** 1-3
- **Content Format:** Setup → play → repeat
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High

### 31. Mumma I am Bored

- **id:** `jm-mumma-i-am-bored`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Character | **Goal:** Reach
- **Topic:** The exact sentence that starts the meltdown
- **Audience Problem:** "Bored" is the word right before crying
- **Characters:** Ria + Mumma | **Age:** 2-4
- **Content Format:** Statement → Mumma's fix → play
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** High

### 32. Won't Brush

- **id:** `jm-wont-brush`
- **Series:** jugaadu-mummy | **Format:** Story Reel | **Production:** Image | **Goal:** Reach
- **Topic:** Toothbrush becomes the enemy at night
- **Audience Problem:** Bedtime brushing is a nightly fight
- **Characters:** Ria + Cuty | **Age:** 2-4
- **Content Format:** Resistance → distraction → win
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** Medium
- **Notes:** Overlaps with idea 22, the self-care mission. Merge or keep both and test.

### 33. Won't Wear Shoes

- **id:** `jm-wont-wear-shoes`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Video | **Goal:** Reach
- **Topic:** Putting shoes on is a fight that happens at the door
- **Audience Problem:** Getting out of the house is late every single day
- **Characters:** Rio | **Age:** 1-3
- **Content Format:** Refusal → choice offered → compliance
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** Medium

### 34. Bath Time Resistance

- **id:** `jm-bath-resistance`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Video | **Goal:** Reach
- **Topic:** Bath is fine until the hair washing part starts
- **Audience Problem:** The hair washing moment ruins the whole evening
- **Characters:** Ria + Mumma | **Age:** 1-4
- **Content Format:** Enjoyment → the problem → the fix
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** High

### 35. Phone Chahiye, Exact Script

- **id:** `jm-phone-chahiye-script`
- **Series:** jugaadu-mummy | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Topic:** The exact lines to say instead of handing over the phone
- **Audience Problem:** Nothing to say in the moment except "no"
- **Characters:** Mumma | **Age:** 1-4
- **Content Format:** Do This Not That, phrase by phrase
- **Hook Angle:** Problem
- **Status:** Idea | **Priority:** High

### 36. Five Kitchen Items

- **id:** `jm-5-kitchen-items`
- **Series:** jugaadu-mummy | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Topic:** Five safe kitchen items for independent play
- **Audience Problem:** Independent play sounds expensive before you realise it is not
- **Characters:** Ria | **Age:** 1-4
- **Content Format:** Five-item list
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High

### 37. Don't Buy This, Use This

- **id:** `jm-dont-buy-use-this`
- **Series:** jugaadu-mummy | **Format:** Reel | **Production:** Video | **Goal:** Shares
- **Topic:** Expensive toy shown next to its free household equivalent
- **Audience Problem:** Spending on toys that duplicate what the kitchen already has
- **Characters:** Rio | **Age:** 1-4
- **Content Format:** Expensive thing → free thing → play
- **Hook Angle:** Surprising
- **Status:** Idea | **Priority:** High

### 38. Seven Things Instead of the Phone

- **id:** `jm-7-instead-of-phone`
- **Series:** jugaadu-mummy | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Topic:** Seven things to hand over instead of a screen
- **Audience Problem:** Reaching for the phone out of habit, not boredom
- **Characters:** Mumma + Ria | **Age:** 1-4
- **Content Format:** Numbered list of substitutes
- **Hook Angle:** Problem
- **Status:** Idea | **Priority:** High

---

## Ria, Rio & Cuty stories

Nine short character stories. Each one is a small problem, one beat of resistance,
a warm ending, and one lesson. Series is `little-stories`.

### S1. Ria Doesn't Want Vegetables

- **id:** `st-ria-vegetables`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Reach
- **Characters:** Ria + Mumma | **Age:** 2-4
- **Content Format:** Refusal → one small win → she tries it
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** High
- **Notes:** Overlaps hook `h08`, the broccoli hook. Use `h08` as its hook.

### S2. Rio Says NO to Everything

- **id:** `st-rio-says-no`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Followers
- **Characters:** Rio | **Age:** 2-4
- **Content Format:** Series of refusals → one yes → why
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** High
- **Notes:** Signature character post. This is the one that earns follows.

### S3. Ria Won't Brush

- **id:** `st-ria-wont-brush`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Reach
- **Characters:** Ria + Cuty | **Age:** 2-4
- **Content Format:** Resistance → Cuty helps → done
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** Medium
- **Notes:** Third brush post across the library. Pick one before scheduling.

### S4. Rio Doesn't Want to Share

- **id:** `st-rio-sharing`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Engagement
- **Characters:** Rio + Ria | **Age:** 2-4
- **Content Format:** Refusal → sharing → friendship
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** Medium

### S5. Cuty Wants to Sleep

- **id:** `st-cuty-wants-sleep`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Reach
- **Characters:** Cuty + Ria + Rio | **Age:** 1-4
- **Content Format:** Everyone plays → Cuty sleeps → lesson about rest
- **Hook Angle:** Warm
- **Status:** Idea | **Priority:** Medium
- **Notes:** Uses hook `h18`, Cuty bhi soti hai.

### S6. Ria Wants Mumma's Phone

- **id:** `st-ria-wants-phone`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Reach
- **Characters:** Ria + Mumma | **Age:** 1-4
- **Content Format:** Asking → Mumma offers one → accepted
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** High
- **Notes:** Fourth phone idea in the library. Best version is Mumma offering her own phone briefly, which reverses the power.

### S7. Rio Won't Clean Toys

- **id:** `st-rio-clean-toys`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Shares
- **Characters:** Rio + Ria | **Age:** 2-4
- **Content Format:** Refusal → racing → cleaned together
- **Hook Angle:** Relatable
- **Status:** Idea | **Priority:** Medium

### S8. Ria Wants the Same Toy Again

- **id:** `st-ria-same-toy`
- **Series:** little-stories | **Format:** Reel | **Production:** Character | **Goal:** Reach
- **Characters:** Ria | **Age:** 1-3
- **Content Format:** Repetition → why → it is learning
- **Hook Angle:** Surprising
- **Status:** Idea | **Priority:** Medium
- **Notes:** Uses hook `h15`, baar baar wahi.

### S9. Rio Gets Bored After Two Minutes

- **id:** `st-rio-bored-2-min`
- **Series:** little-stories | **Format:** Trial Reel | **Production:** Character | **Goal:** Reach
- **Characters:** Rio | **Age:** 2-4
- **Content Format:** Bored → Mumma watches him too → both bored → laugh
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High
- **Notes:** Novel angle, the child mirrors the parent. Worth the first trial slot.

---

## Learning through play

Ten activities, all using household items. Series is `learning-through-play`.

### L1. Sort by Colour

- **id:** `lp-sort-colour`
- **Series:** learning-through-play | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Characters:** Ria | **Age:** 2-4
- **Content Format:** Numbered list of colour sets
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High
- **Notes:** Overlaps L10, simple sorting game. Merge them.

### L2. Spoon Transfer

- **id:** `lp-spoon-transfer`
- **Series:** learning-through-play | **Format:** Reel | **Production:** Video | **Goal:** Reach
- **Characters:** Ria | **Age:** 1-3
- **Content Format:** Setup → transfer → proud finish
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High
- **Notes:** Overlaps idea 3, the kitchen challenge, and idea 28, water pouring. Strongest of the three, keep it and retire the other two.

### L3. Match Big and Small

- **id:** `lp-big-small`
- **Series:** learning-through-play | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Characters:** Rio | **Age:** 2-4
- **Content Format:** Numbered pairs
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** Medium

### L4. Kitchen Counting Game

- **id:** `lp-kitchen-counting`
- **Series:** learning-through-play | **Format:** Reel | **Production:** Video | **Goal:** Reach
- **Characters:** Ria + Rio | **Age:** 2-4
- **Content Format:** Count items → get it wrong together → laugh
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High

### L5. Shape Hunt at Home

- **id:** `lp-shape-hunt`
- **Series:** learning-through-play | **Format:** Trial Reel | **Production:** Image | **Goal:** Reach
- **Characters:** Ria | **Age:** 2-4
- **Content Format:** Hidden shapes → find three → done
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High
- **Notes:** Good first trial. Same retention mechanics as the hidden Cuty idea.

### L6. Sound Matching

- **id:** `lp-sound-matching`
- **Series:** learning-through-play | **Format:** Reel | **Production:** Video | **Goal:** Reach
- **Characters:** Rio + Cuty | **Age:** 1-3
- **Content Format:** Make a sound → find the object → match
- **Hook Angle:** Surprise
- **Status:** Idea | **Priority:** Medium

### L7. Pouring Activity

- **id:** `lp-pouring`
- **Series:** learning-through-play | **Format:** Image Reel | **Production:** Image | **Goal:** Reach
- **Characters:** Ria | **Age:** 1-2
- **Content Format:** Materials → play → result
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** Medium
- **Notes:** Duplicate of idea 28, water pouring. Merge.

### L8. Texture Exploration

- **id:** `lp-texture`
- **Series:** learning-through-play | **Format:** Carousel | **Production:** Static | **Goal:** Saves
- **Characters:** Ria | **Age:** 1-3
- **Content Format:** Five textures to put in a tray
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** Medium

### L9. Colour Hunt

- **id:** `lp-colour-hunt`
- **Series:** learning-through-play | **Format:** Trial Reel | **Production:** Image | **Goal:** Reach
- **Characters:** Ria + Rio | **Age:** 2-4
- **Content Format:** "Find something red" → run → find it → next colour
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** High
- **Notes:** Best of the learning batch for trial. Simple to film, fast to understand.

### L10. Simple Sorting Game

- **id:** `lp-simple-sorting`
- **Series:** learning-through-play | **Format:** Trial Reel | **Production:** Video | **Goal:** Reach
- **Characters:** Rio | **Age:** 2-4
- **Content Format:** Two bowls → sort → done
- **Hook Angle:** Curiosity
- **Status:** Idea | **Priority:** Medium
- **Notes:** Duplicate of L1. Merge.

---

**Duplicate check on the new batch.** Six ideas collide with something already in
the library: brushing (`jm-wont-brush`, `st-ria-wont-brush`, and idea 22), phone
(25, 35, 38, S6), spoon transfer (`lp-spoon-transfer`, idea 3, idea 28), sorting
(`lp-sort-colour`, `lp-simple-sorting`), and water pouring (`jm-water-pouring`,
`lp-pouring`). You now have more brushing and phone ideas than the rest combined.
Worth pruning before we build the library, otherwise the Create screen opens on
four near-identical options.

---

## Hook library

Thirty hooks already live in the app as reel story seeds. They are not ideas yet,
they are openings. A hook becomes an idea once it has a series and a topic.

| id | Category | Cover | Lesson |
|---|---|---|---|
| `h01` | Relatable | Main Khud Karungi! | Thoda intezaar, aur bachcha khud seekh jaata hai |
| `h02` | Relatable | Bas 5 Minute Aur?! | Achanak nahi, pehle se bataakar band karo |
| `h03` | Relatable | Mujhe Nahi Aata! | Galti se hi seekhte hain, phir se try karo |
| `h04` | Relatable | Cuty Kahan Gaya?! | Saaf kamra, sab kuch saamne |
| `h05` | Relatable | Ek Aur Paani! | Roz ek jaisa routine, neend jaldi aati hai |
| `h06` | Relatable | Meri Car Hai! | Baari baari khelne mein sabka mazaa |
| `h07` | Relatable | Brush Nahi Karungi! | Khel banao, zidd khud chali jaati hai |
| `h08` | Relatable | Broccoli? Bilkul Nahi! | Start small, one bite is a win |
| `h09` | Relatable | Mere Papa Ka Haath! | Let them try in front of you, not alone |
| `h10` | Relatable | Water Piya Hi Nahi! | Keep the glass where they can reach it |
| `h11` | Relatable | Ek Aur Kahaani! | One more story is a bedtime ritual, not a problem |
| `h12` | Relatable | Galti Ho Gayi! | They will get it wrong. Let them |
| `h13` | Struggle first | Naam Lene Mein Waqt | Say it patiently more than once, it lands |
| `h14` | Struggle first | Kapde Pehno Hi Nahi! | Choose the clothes the night before |
| `h15` | Struggle first | Baar Baar Wahi! | Repetition is not a loop, it is learning |
| `h16` | Struggle first | Wait Karo, Kar Lo! | Do not take over, wait it out |
| `h17` | Struggle first | Kuch Bhi Kha Lo! | Offer two options, not five |
| `h18` | Surprising | Cuty Bhi Soti Hai! | Even the toy needs rest |
| `h19` | Surprising | Woh So Gaya! | They fell asleep in the middle of it |
| `h20` | Surprising | 3 Ki Galti Se Barabar | Toddler maths is not a bug |
| `h21` | Warm lesson | Ek Saath, Phir Akele | Do it together first |
| `h22` | Warm lesson | Thoda Aur | Slow down, it lands better |
| `h23` | Warm lesson | Raat Bhar Yaad Aayegi | The day they did it themselves |
| `h24` | Warm lesson | Aadat Banti Hai | Tiny things repeated |
| `h25` | Warm lesson | Galti Ke Baad | The retry is the lesson |
| `h26` | Warm lesson | Khushi Ka Ped | What you praised once, they do again |
| `h27` | Page & milestone | 100 Posts. One World. | Every family has this, you are not alone |
| `h28` | Page & milestone | Ek Kahani Kaise Banti Hai | Behind the scenes |
| `h29` | Page & milestone | Ek Reel Kaise Banti Hai | Behind the scenes |
| `h30` | Page & milestone | Jab Humne Shuru Kiya | Honest start builds trust |

---

## Template for a new idea

Copy this block, paste it at the bottom of the Ideas section, fill in what you know.

```
### <Title>

- **id:** `<series-short>-<short-slug>`
- **Series:** 
- **Topic:** 
- **Problem:** 
- **Lesson:** 
- **Format:** 
- **Best content type:** 
- **Alternative:** 
- **Goal:** 
- **Why this type:** 
- **Duration:** 
- **Language:** Hinglish
- **Characters:** 
- **Status:** Idea
- **Priority:** 
- **Notes:** 
```

## Versions

When you try the same idea in a second format, do not overwrite it. Add it here.

```
### <Title>, version 2

- **Format:** 
- **Content Type:** 
- **Goal:** 
- **Posted on:** 
- **Result:** views / saves / comments
- **Verdict:** keep / drop / try again
- **Why:** 
```

---

## Sync log

| Date | What changed |
|---|---|
| today | Created. Seeded with 24 post packages and 30 hooks from the app |
| today | Series reduced to your four pillars. Milestone-check and the-casts kept separate |
| today | Field schema expanded to your 16 canonical fields. Added Age, Hook Angle, Production, Test Number |
| today | Added 33 new ideas: 14 Jugaadu Mummy, 9 character stories, 10 learning activities |
| today | Added the format recommendation table with one-line reasoning per rule |
