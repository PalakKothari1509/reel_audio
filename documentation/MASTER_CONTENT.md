# Master Content File

This is the single-file source of truth for the current app content library.

Source basis: `content_ideas.md`
Current scope: all current ideas represented in the app, with duplicate/legacy items clearly marked.

---

## 1. Current app model

Idea → selected content type → one generated package → one execution

This replaces the old "generate all formats" flow.

The app currently treats:
- caption as part of the package
- content type as a chosen execution target
- one idea = one selected package output

---

## 2. Active series / pillars

Current working taxonomy from the library:

- `jugaadu-mummy` — low-cost parenting hacks, practical house solutions, everyday toddler problems
- `little-stories` — short Ria / Rio / Cuty character stories
- `learning-through-play` — household learning activities and play ideas
- `play-at-home` — mission-style activities and quick challenge content
- `milestone-check` — age-based skill-check content
- `the-casts` — audience/community posts, votes, wrap-ups

---

## 3. Current content inventory (57 ideas)

### Day / mission ideas
- `day2-which-doesnt-belong`
- `day3-mumma-says`
- `day4-kitchen-challenge`
- `day5-ask-tonight`
- `day6-3year-skills`
- `day7-toddler-math`
- `day8-find-cuty`
- `day9-sock-hunt`
- `day10-3-questions`
- `day11-4year-skills`
- `day12-dinner-types`
- `day13-pattern-game`
- `day14-favorite-format`
- `day15-household-swaps`
- `day16-voted-mission-won`
- `day17-mission1-race-track`
- `day18-mission2-concert`
- `day19-mission3-art-studio`
- `day20-mission4-detective`
- `day21-mission5-rescue`
- `day22-mission6-treasure`
- `day23-mission7-daily-care`
- `day24-trial-reel-7-missions`
- `day25-week-wrap-up`

### Jugaadu Mummy ideas
- `jm-phone-meals`
- `jm-hot-chai`
- `jm-kitchen-busy-basket`
- `jm-water-pouring`
- `jm-dal-chawal`
- `jm-tape-pull`
- `jm-mumma-i-am-bored`
- `jm-wont-brush`
- `jm-wont-wear-shoes`
- `jm-bath-resistance`
- `jm-phone-chahiye-script`
- `jm-5-kitchen-items`
- `jm-dont-buy-use-this`
- `jm-7-instead-of-phone`

### Little stories / Ria, Rio & Cuty ideas
- `st-ria-vegetables`
- `st-rio-says-no`
- `st-ria-wont-brush`
- `st-rio-sharing`
- `st-cuty-wants-sleep`
- `st-ria-wants-phone`
- `st-rio-clean-toys`
- `st-ria-same-toy`
- `st-rio-bored-2-min`

### Learning-through-play ideas
- `lp-sort-colour`
- `lp-spoon-transfer`
- `lp-big-small`
- `lp-kitchen-counting`
- `lp-shape-hunt`
- `lp-sound-matching`
- `lp-pouring`
- `lp-texture`
- `lp-colour-hunt`
- `lp-simple-sorting`

---

## 4. Known issues in the current library

These are not hidden; they are explicitly noted in the library and should be handled before final cleanup:

- Duplicate cluster: `lp-sort-colour` + `lp-simple-sorting` → merge
- Duplicate cluster: `lp-pouring` + `jm-water-pouring` → merge
- Overlap cluster: `lp-spoon-transfer`, `day4-kitchen-challenge`, `jm-water-pouring` → keep strongest version
- Overlap cluster: `jm-wont-brush` + `st-ria-wont-brush` → choose strongest version
- Phone overlap cluster: `jm-phone-meals`, `jm-phone-chahiye-script`, `jm-7-instead-of-phone`, `st-ria-wants-phone` → prune/keep strongest
- Legacy/community content: `day14-favorite-format`, `day16-voted-mission-won`, `day25-week-wrap-up` → treat as archive/community, not core educational posts

---

## 5. Current final state

This file is the current content truth for the app based on the actual idea library in `content_ideas.md`.

It includes:
- the active app content model
- the currently represented 57 ideas
- the known duplicate/legacy issues
- the current active taxonomy without forcing everything into a single false category

This is the working one-file content inventory for the app until a later reclassification pass removes duplicates and finalizes the canonical library.
