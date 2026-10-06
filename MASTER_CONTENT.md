# Master Content File

This is the single consolidated record of the content model and current content structure in the app.

It is meant to be the one-file source for the app's current content logic, without needing to open multiple documents.

---

## 1. App purpose

Fun Learning With Palak is a content production app for an Instagram page focused on screen-free learning and play for Indian parents of children aged 1–4.

It turns an idea into a finished, publishable Instagram package that includes:
- hook
- script
- scene-by-scene plan
- caption
- hashtags
- CTA
- comments / reusable copy

The app does not publish directly to Instagram. It prepares content for export and manual posting.

---

## 2. Brand and characters

### Brand tone
- warm
- playful
- relatable
- family-first
- screen-free learning

### Characters
- Ria
- Rio
- Cuty
- Mumma
- Papa
- Daadi
- Teacher

### Core visual style
The app has a single visual style constant and a shared character lock block used across prompts.

---

## 3. Current content pillars

Every content item belongs to one pillar, which describes the value it gives the child.

| Pillar | Meaning | Example |
| --- | --- | --- |
| PLAY | Activities that keep a toddler busy | spoon transfer, pouring, sorting |
| THINK | Simple problem-solving | which one doesn't belong |
| DISCOVER | Learning through everyday objects | colours, textures, sounds |
| TALK | Language and parent-child conversation | what to say instead of no |
| DO | Practical independence | brushing, shoes, eating |

---

## 4. Current series model

A series is the recurring content world; it is different from a pillar.

| Series | What it covers |
| --- | --- |
| Jugaadu Mummy | low-cost Indian parenting hacks |
| Life With Ria & Rio | everyday preschool situations |
| Can Your Child Figure It Out? | interactive problem-solving |
| Talk With Your Child | conversation starters |
| Try This At Home | practical activities |
| Parent-Relatable | relatable parent/toddler moments |
| Age-Based Skills | age-based developmental practice |

There are also legacy/archived ideas that do not fit neatly into the active taxonomy, such as milestone-check content and cast engagement posts.

---

## 5. Seven classification axes

The app's model separates content by seven independent axes.

| Axis | Question it answers |
| --- | --- |
| Pillar | What value does this give? |
| Series | What recurring world does it belong to? |
| Content Type | What is being published? |
| Narrative Format | How is the idea shaped? |
| Production Method | How is it made? |
| Goal | What outcome are we optimising for? |
| Status | Where is it in the workflow? |

### Why this matters
The app previously merged those ideas into one loose concept of “format.” The current model separates them so the app can answer different questions without mixing them together.

---

## 6. Content types

Current content types in the app:
- Reel
- Carousel
- Trial Reel
- Image Slideshow Reel
- Static Image
- Story

### Content type meaning
- Trial Reel = low-risk test for non-follower reach
- Reel = stronger format for followers or established ideas
- Carousel = saveable, list-based, reference-heavy content
- Static Image = single, punchy message
- Story = short narrative / moment-based publishing

---

## 7. Production methods

Production methods decide what the app is actually producing:
- Character images
- Real-life video
- Image slideshow
- Text-based
- Carousel
- Mixed

This decides whether the app should generate image prompts, scripts, scene plans, slide layouts, or text cards.

---

## 8. Narrative formats

Narrative formats are story shapes, not publishing types.

Current registered formats include:
- POV
- Do This, Not That
- Mistakes List
- Problem → Fix
- Exact Script
- Expectation vs Reality
- Personal Mistake
- Save This List
- Numbered Framework
- Unpopular Opinion
- Before You
- Three Examples
- Quick Tip
- Mini Story
- This or That
- Question → Answer

These are tracked as format definitions and used to recommend what type of story should fit a given idea.

---

## 9. Goal model

Each content item is optimized around a goal, but the model treats it as a single strategic outcome rather than a bundle of everything.

Possible goals:
- Reach
- Non-follower Reach
- Saves
- Shares
- Comments
- Relatability
- Authority
- Follows

The design is to choose one primary goal instead of saying “reach + shares + saves” all at once.

---

## 10. Status ladder

Current production status progression:

idea → approved → scripted → imagesReady → generated → posted → tested → archived

This makes a difference between:
- an idea that exists
- a script that is written
- a visual asset that is ready
- a package that has been generated
- a post that has been tested live

---

## 11. Current app screens

### Dashboard
The dashboard currently includes:
- Create Content
- Reel
- Trial Reel
- Carousel
- Image
- Idea Vault
- Settings
- Promotion Comments

The standalone Caption Generator is not treated as a dashboard app flow; captions are generated as part of a package instead of as a separate standalone feature.

### Create Content
This is the single generation path:
- one idea
- one selected content type
- one generated package

This is the current replacement for the removed “Generate All Formats” flow.

### Content Library
Saved items are visible in a library where they can be filtered, opened, copied, or managed.

### Reel Maker
Story brief → timed script + scene prompts → review/edit → images and voice → render locally with FFmpeg → save locally.

### Idea Vault
Raw idea capture with title, notes, bucket and status.

### Promotion Comments
Reusable comments / profile replies stored in a vault and filtered by category.

---

## 12. Generation flow

The app generates one package at a time.

Primary flow:
1. idea
2. selected content type
3. generate one package
4. review/copy/edit
5. save or post

The system no longer assumes that selecting one idea means generating multiple versions at once.

---

## 13. Current content library snapshot

The app currently keeps a mix of:
- active ideas
- saved content packages
- draft/ready content
- legacy idea records
- historical post data

The internal source-of-truth files include:
- APP_OVERVIEW.md
- CONTENT_MODEL.md
- content_ideas.md
- content_formats.md
- quick_ideas.json
- REDESIGN_PLAN.md
- POSTS_REVIEW.md
- master_prompt.md

---

## 14. Current idea inventory status

The files describe the idea library as being in migration.

Current reported state:
- 57 ideas in content_ideas.md
- some axes are approved
- some fields are still open
- content classification is still being resolved
- the legacy library is being reviewed and reclassified rather than blindly forced into the new taxonomy

This means the content library is active, but still in transition.

---

## 15. Summary of the current app model

The app is currently structured around this logic:

Idea → selected content type → one package → one execution

Not:

Idea → generate multiple format outputs all at once

The new approach is more aligned with:
- lower AI usage
- less token complexity
- clearer ownership
- easier validation
- one package = one concrete execution

---

## 16. Source-of-truth files

This repository currently contains the main content references:
- APP_OVERVIEW.md — current app behavior and missing gaps
- CONTENT_MODEL.md — architecture and definitions for the content model
- content_ideas.md — idea library / source content data
- content_formats.md — format definitions
- quick_ideas.json — quick idea store / cached package data
- REDESIGN_PLAN.md — open work and future decisions

This file consolidates the active content structure into one master view.

---

## 17. Final current-state statement

The app currently contains:
- a content-first idea model
- series and pillar-based organization
- focus on one selected content format at a time
- a generation pipeline that is intended to produce a single execution per idea
- a legacy library that is being triaged, reclassified, and cleaned up rather than migrated blindly

This is the current working content landscape of the application.
