# Quick Content Studio - Application Overview

## 1. Project summary
This app is a Flutter application for creating AI-assisted short-form content for parenting and kids-focused social media posts. The current build is centered around generating reels from stories, writing scripts, adding voiceover, designing scenes, and preparing posting copy.

The app is useful for creators who want to:
- write a story idea
- generate a timed script with AI
- choose a voice style and language
- generate image prompts for each scene
- build a final reel with captions and music
- save the project and prepare Instagram-ready post content

---

## 2. Current app direction
The existing app already includes:
- story input screen
- script generation using Gemini
- voice engine switching
- AI prompt generation for scenes
- project saving
- hook and content planning
- posting kit for captions and comments
- saved project drafts

This means the app already works as a reel-making assistant.

---

## 3. What is missing for your workflow
Your real need is not only reel creation. You also want to:
- save many content ideas in one place
- create posts without going through the full reel pipeline
- generate prompts for static image posts and carousel posts
- create captions quickly
- create multiple different comments for one post
- build copy-and-paste content for AI tools outside this app

This means the app needs a second workflow: a fast content drafting module.

---

## 4. Best product structure
### A. Reel Maker
For full video reels with:
- story writing
- script generation
- narration
- prompt generation
- captions and reel output

### B. Quick Content Studio
For faster posts, such as:
- static image posts
- carousel posts
- text-based posts
- prompt-only generation
- caption-only generation
- comment pack generation

### C. Saved Ideas Library
A place where all ideas are stored and can be reopened later.

---

## 5. Recommended app name
Recommended name:
- Quick Content Studio

Alternative options:
- PostPilot
- StoryPack
- ContentFlow

The best fit for your business is: Quick Content Studio

---

## 6. Core feature to build next
### Quick Post Studio
This should be one single page that lets a creator generate everything for a post without entering the full reel flow.

Required fields:
- Post type: Reel / Carousel / Static Image / Story
- Post title or idea name
- Target audience
- Content goal
- Hook / cover text
- Main idea
- Problem
- Solution / lesson
- Visual style
- AI image prompt
- Caption
- CTA
- Hashtags
- Pin comment
- 5 reply comments
- Reel script or carousel slide text

This page should also include buttons such as:
- Copy all
- Copy caption
- Copy image prompt
- Copy script
- Copy comments
- Save idea

---

## 7. Best one-page content form
This is the recommended single-page structure:

Post Type
[ Reel / Carousel / Static Image / Story ]

Post Title
[ Example: School Morning Battle ]

Target Audience
[ Parents of 3-6 year olds / non-mom audience / general parents ]

Hook / Cover Text
[ 2 to 5 words ]

Main Idea
[ What is happening in this post? ]

Problem
[ What is the child struggling with? ]

Lesson / Solution
[ What should the parent learn? ]

Mood / Emotion
[ Relatable / Funny / Warm / Educational / Surprising ]

Visual Style
[ Bright / Clean / Real-life / Cartoon / Minimal ]

Image Prompt
[ Full prompt for image generation ]

Caption
[ Final caption text ]

CTA
[ Save / Share / Comment / Follow ]

Hashtags
[ #ParentingTips #KidsLife #ToddlerMom ]

Pinned Comment
[ Single main comment ]

Reply Comments
[ 5 varied comments ]

Script / Carousel Text
[ For reel or carousel ]

---

## 8. Comment strategy
This is very important for Instagram safety and engagement.

Do not reuse the same reply on multiple comments. That can look spammy and may trigger restrictions.

A better approach is to generate a comment pack with 5 different styles for every post.

### Recommended comment types
1. Relatable mom comment
2. Relatable non-mom comment
3. Emoji reaction comment
4. Validation / truth comment
5. CTA or conversation comment

### Example comment pack
- Mom-focused: “This is my life right now 😭 and honestly, the struggle is so real.”
- Non-mom comment: “This is honestly so relatable even for non-moms. It feels like family life in one moment.”
- Emoji reaction: “😅😅😅 this is us every single day.”
- Validation: “This is so true. We all need this reminder sometimes.”
- CTA: “Which part of this feels most like your home? Tell me below 👇”

This creates organic conversation without repeating the same wording.

---

## 9. CTA strategy for last slide or final image
This is a strong idea and should be built into the content generator.

Suggested CTAs for end slide:
- “Save this for the next time your child says no.”
- “Share this with another parent who needs it.”
- “Comment ‘save’ if this feels like your home too.”
- “Tell me which part feels most relatable.”
- “Tag someone who needs this reminder today.”

This gives the final slide a clear engagement purpose.

---

## 10. Output model for different post types
### Static image post output
- image prompt
- caption
- pin comment
- 5 reply comments
- hashtags
- CTA

### Carousel post output
- slide-by-slide text
- prompt per slide
- caption
- pin comment
- 5 reply comments
- CTA block

### Reel post output
- hook
- script
- caption
- pin comment
- 5 reply comments
- CTA

---

## 11. Saving ideas
The app should support a draft idea system where each saved idea includes:
- title
- post type
- audience
- hook
- story
- lesson
- visual direction
- caption
- prompt
- script
- comments
- status: draft / approved / posted

This makes it easy to revisit older content and reuse ideas later.

---

## 12. Best first implementation phase
### Phase 1: Quick Content Studio
- new screen for idea saving
- post type selector
- prompt generation
- caption generation
- comment pack generation
- copy buttons
- save drafts

### Phase 2: Saved Ideas Library
- list all ideas
- filter by post type
- mark as posted or approved
- reopen and edit

### Phase 3: Full Post Planner
- scheduling
- content calendar
- posting bundle for different platforms

---

## 13. Key product principle
The app should never force every idea into the full reel workflow.

Instead, it should support two modes:
1. Fast post mode for quick content generation
2. Full reel mode for story-based video content

This is the cleanest and most useful direction for your creator workflow.

---

## 14. Recommended next step
The next step is to build the Quick Content Studio and the Saved Ideas page first.

After that, we can connect it to AI prompt generation and caption/comment generation.

At that point, the app will be much more aligned with your actual posting workflow.

---

## 15. Final recommendation
The correct product direction for this app is:

Quick Content Studio + Reel Maker + Saved Idea Vault

This gives you:
- faster content generation
- ready-to-copy prompt packs
- ready-to-copy captions
- ready-to-copy scripts
- ready-to-copy comments
- better content reuse
- less friction in daily posting

This is the best fit for your use case.

---

## 16. Current implementation status
The planned Quick Content Studio and saved idea workflow are now implemented.

### Where to find the built-in marketing ideas
The ideas from `Ideas from chat gpt for marketing posts.md` were added as built-in hooks in `lib/plan_data.dart`.

In the app:
1. Open the main Story Reel Maker screen.
2. Tap the calendar icon in the top bar.
3. Open the `Hooks` tab.
4. Browse the Palak ideas, including `Which Kid Is Yours?`, `7 Things Every Toddler Does`, `When Mumma Says No`, and `Mumma's Little Detective`.
5. Tap a hook to edit or reuse it in the story workflow.

The markdown file remains the full source/reference document. It is not displayed as a document page inside the app; its selected ideas are represented in the app as editable hook entries.

### Quick Content Studio
The article icon on the main screen opens Quick Content Studio. It supports:
- Reel, carousel, static image, and story briefs
- content goal, mood, audience, hook, idea, problem, lesson, visual style, and CTA
- generated image prompts, captions, hashtags, scripts, and comment packs
- saved post ideas with reopen and copy actions

### Gallery importing
The Android app now declares image-library access for importing images from the device gallery. The story image picker uses the device gallery multi-image picker, while video selection remains separate.

### Current creator dashboard
The app now opens on a creator dashboard with **7 clear entry points** plus a persistent bottom bar:
- ✨ **Create Content**: One idea → Carousel, Reel, Trial Reel, Image (all at once)
- 🎬 **Make a reel**: the existing story, script, image, voice, and render workflow
- 🧪 **Trial Reel**: 60-sec fast-cut compilation for non-follower reach
- 📚 **Carousel**: Enter idea → get slide prompts for all carousel pages
- 🖼️ **Image**: Enter idea → get 7 different image prompts for Meta AI
- 💡 **Idea Vault**: Capture, organize & develop ideas (💡📝✅📤♻️)
- ⚙️ **Settings**: AI provider, API keys, defaults, export/import data
- 💬 **Promotion Comments** (bottom bar): opens full reusable comment vault with bucket filter chips

Saved story history remains available through the existing folder/file-manager icon in the dashboard app bar.

Selecting an idea from `Browse ideas` now returns it directly to the story editor with its complete story scaffold filled in. The generated structure includes the setting, starting problem, escalation, solution, ending line, and moral, so there are no blank story sections to complete before writing the script.

### Quick-post history
Generated quick-post packs are also stored automatically in a separate history list. Carousel and static-image posts can be reopened or copied from the history icon in Quick Content Studio, even when they were not saved as a reusable idea.

### Profile-promotion comment vault
The dashboard owns the persistent library of reusable comments for engaging with other creators' posts. The library contains the Ria, Rio, Cuty, combined-character, curiosity, and community comment groups. Each comment can be copied, and new comments can be saved directly from the dashboard button.

### Real AI video generation
Gemini's current Veo video models can create short 4, 6, or 8-second clips with native audio and optional reference images. This is different from the app's current image-to-reel renderer. Veo access is asynchronous and depends on the API key, billing, region, and model entitlement, so it should be integrated as a separate video-shot workflow and then combined with the existing script, voice, caption, and posting tools. The current app still uses its reliable local image-to-video assembly path until Veo access is configured and tested with the project's key.

The recommended implementation for a longer Hinglish reel is three independent portrait shots, each generated from the same character references, followed by local FFmpeg concatenation. Because Veo's supported duration is 4, 6, or 8 seconds rather than 10 seconds, each requested 10-second segment must be implemented as an 8-second generation plus a 2-second extension or local hold/transition. Hinglish dialogue can be included in the prompt, but English is the only fully evaluated Veo language, so the existing Flutter TTS/Hinglish voice pipeline remains the reliable voice layer until Veo audio quality is tested for the account.

### Shot Planner implementation
The first Veo-ready layer is now implemented in `lib/shot_planner.dart` and is opened from the Story screen with `Plan cinematic shots`.

It:
- calculates a valid combination of 4, 6, and 8-second shots for the selected reel length
- tells the user when an exact total is impossible, such as 45 seconds becoming 44 seconds
- asks Gemini for structured cinematic beats: purpose, characters, location, action, emotion, camera, movement, Hinglish dialogue, and ending
- loads the saved cast descriptions and embeds a non-editable character-consistency contract in each Veo prompt
- shows each shot as a review card with its generated Veo prompt
- supports regenerating an individual shot plan without changing the rest of the app

This is intentionally P0. Veo generation, remote video download, FFmpeg joining, and shot thumbnails should be added only after the planner output is tested on real stories and the API key is confirmed to have Veo access.

### AI Idea Lab backend
The secure provider boundary is scaffolded in the `backend/` folder:
- `backend/server.js` exposes `POST /v1/ideas`
- the active provider is `openai` only; Claude is intentionally deferred
- the backend sends the Fun Learning With Palak brand context automatically
- responses are normalized into ideas with hooks, concepts, characters, reasons, and quality scores
- the OpenAI credential is read only from the backend environment variables
- `lib/idea_lab_api.dart` is the Flutter client and receives only the public backend URL

The backend must be deployed to an HTTPS host and protected with authentication and rate limiting before the Flutter app calls it. Node.js is not available on the current development machine, so the backend still needs to be installed and smoke-tested in the deployment environment. Any credentials previously present in `lib/secrets.dart` should be revoked and rotated before production use.

### 100th Instagram post ideas
The 100th milestone concepts are now available in the built-in `Page & milestone` Ideas category:
- `100 Posts. One World.`: the primary combined milestone, brand introduction, character introduction, and Trial Reel concept
- `100 Posts Ago...`: the emotional page-journey version
- `Who Made Post 100?`: the funny Ria/Rio/Cuty version
- `Meet Our Little World`: the pinned character and brand introduction

Each idea now carries its recommended format, strategy, ready caption, and pinned comment. Selecting one from Browse ideas sends the full kit into the story editor, so it is usable rather than only a title or hook.

### 14-Day Post Package Library
The app now includes a structured 14-day content plan in `lib/day14_posts.dart`. This library provides ready-to-use post packages that creators can load individually or import in bulk:

- **Content Buckets**: Six strategy buckets — `puzzle`, `humor`, `activity`, `talk`, `skill`, and `wrap` — each with its own color. Posts are categorized by the engagement type they target.
- **13 Post Packages (Days 2–14)**: Every `QuickIdea` includes a title, hook, main idea, problem, lesson, mood, visual style, character-consistent image prompt, caption, CTA, hashtags, comment pack, and script. Day 1 ("100 Posts. One World.") remains a built-in hook in `plan_data.dart`.
- **Character Bible**: Image prompts consistently feature Ria (brown eyes, warm skin tone, no glasses, pastel watercolor style) and Rio (same), plus Cuty the white bunny with a pink bow. All prompts specify cream background and soft pastel watercolor storybook aesthetics.

#### Bulk-Paste Import
A new `_bulkPaste()` method in `QuickContentScreen` (`lib/quick_content.dart`) lets creators import multiple post packages at once:
- Paste multi-line text structured with key-value pairs (e.g., `Title: ...`, `Hook: ...`, `Bucket: puzzle`)
- The `parseBulkPaste()` parser in `day14_posts.dart` converts pasted text into `QuickIdea` objects
- Parsed ideas can be saved or edited immediately

#### Bucket-Based Performance Tracking
`lib/plan_data.dart` now supports per-bucket analytics:
- `PostRecord.bucket` field tracks which content bucket each posted idea belongs to
- `resultsByBucket()` aggregates posts, engagement metrics, and completion rate per bucket
- `ContentBucketResult` class represents per-bucket performance summary
- The Results tab shows a "Best content bucket" section with color-coded avatars sorted by engagement rate

#### Calendar View with Buckets
- `QuickContentScreen` includes a bucket dropdown for assigning content buckets when drafting ideas
- `PlanScreen` (`lib/plan_screen.dart`) has a bucket dropdown when recording post results
- Posted list items show bucket badges with bucket-specific colors
- Selecting a 14-day post loads it directly into the Quick Content Studio form

#### Carousel Slide Prompts
When you generate a carousel post in the Quick Content Studio, the app shows and lets you copy **all slide image prompts at once**:
- Tap **Generate post pack** with post type set to **Carousel**
- A "Slide image prompts (7)" section appears with each slide's full image prompt
- Each prompt has its own **copy button**, plus a **Copy all slide prompts** button at the top
- The **Copy all** button also bundles all slide prompts into the combined clipboard
- Prompts are generated per slide by `planCarousel()` and `buildSlidePrompts()` in `lib/slide_prompts.dart`, displayed via `_buildSlidePromptsSection()` in `lib/quick_content.dart`

You can choose the number of slides: a **Slide count** dropdown (5, 6, 7, 8, or 10) appears when post type is set to **Carousel**. When loading a saved idea, the dropdown auto-adjusts to match the post's script beat count.

#### Comment Vault Filter by Bucket
`lib/creator_home.dart` now supports bucket-tagged comments:
- `PromoComment` model includes an optional `bucket` field
- Bucket filter chips let creators view comments for specific content types (e.g., only "humor" comments)
- Comment rows display bucket badges; tapping a badge filters the vault to that bucket
- Saved comments are backward-compatible: old comments load without a bucket, new comments can opt-in to bucket tagging

---

## 17. Brand System & Content Generation Engine (P0 Complete)

The app now includes a **complete brand-aware content generation engine** that eliminates manual entry of character descriptions, hashtags, CTAs, and visual style. Everything is defined once in `lib/brand_system.dart` and automatically injected into every generated prompt.

### Brand Defaults (`lib/brand_system.dart`)
- **Brand**: Fun Learning With Palak (`@funlearningwithpalak`)
- **Audience**: Parents of preschoolers (1.5-5 years)
- **Tone**: Warm, playful, parent-relatable, simple
- **Visual Style**: Soft pastel watercolor storybook, cream background
- **Default CTAs**: 5 rotating options (Save, Share, Comment, Follow, Try)
- **Hashtag Pool**: 11 curated tags, exactly 5 used per post
- **Character Bible** (immutable, auto-injected):
  - **Ria** 🌸 — Indian preschool girl, dark brown hair in two ponytails with pink bows, brown eyes, pink dress, **no glasses**
  - **Rio** 💙 — Indian preschool boy, dark brown hair, blue outfit, brown eyes, **no glasses**
  - **Cuty** 🐰 — Small white bunny, pink bow, unchanged always

### Content Buckets (5 Strategies)
Every post belongs to exactly one bucket, which drives the generation structure, visual approach, and success metric:

| Bucket | Emoji | Description | Example Hooks | Slide Template |
|--------|-------|-------------|---------------|----------------|
| **Challenge** | 🔎 | Observation games, pattern challenges, spot-the-hidden | "WHICH ONE DOESN'T BELONG? 👀" | Cover → Challenge → Options → Think → Reveal → Why → CTA |
| **Conversation** | 🗣️ | Bedtime questions, dinner talks, imagination starters | "ASK YOUR CHILD THIS TONIGHT 🗣️" | Cover → Q1 → Q2 → Q3 → Why → Variation → CTA |
| **Activity** | 🏠 | Try This at Home — practical play using household items | "5-MINUTE KITCHEN CHALLENGE 🥄" | Cover → What You Need → Step 1 → Step 2 → Step 3 → Learn → CTA |
| **Humor** | 😂 | Parent-relatable moments, toddler logic, daily chaos | "MUMMA SAYS THIS 100× A DAY 😂" | Cover → Scene 1 → Scene 2 → Scene 3 → Punchline → Tagline → CTA |
| **Age Practice** | 📚 | Gentle milestone checklists for specific ages | "CAN YOUR 3-YEAR-OLD DO THESE? ✅" | Cover → Skill 1 → Skill 2 → Skill 3 → Skill 4 → Skill 5 → CTA |

Each bucket defines: generation prompt, color, slide template, example hooks.

### Content Formats (4 Output Types)
Separate from buckets — defines **how** the content is published:

| Format | Emoji | Description | Default Slides/Shots |
|--------|-------|-------------|---------------------|
| **Carousel** | 📚 | Swipeable multi-slide post | 7 (5-10) |
| **Reel** | 🎬 | 15-20 sec vertical video | 5 (4-8) |
| **Trial Reel** | 🧪 | 60-sec fast-cut for non-follower reach | 8 (7-10) |
| **Single Image** | 🖼️ | One image + full caption pack | 1 |

### Complete Content Package Generator (`lib/content_generator.dart`)
**One call generates everything:**

```dart
final package = await ContentGenerator.generate(
  idea: 'Find the hidden Cuty',
  bucket: BucketLibrary.challenge,
  format: ContentFormat.carousel,
);
```

**Output includes:**
- ✅ Hook (bucket-specific)
- ✅ Slides/Shots (per bucket template × format slide count)
- ✅ Visual Prompts (per slide, with Character Lock + Brand Context)
- ✅ Caption (hook + idea + CTA + 5 hashtags)
- ✅ CTA (bucket-specific)
- ✅ Hashtags (exactly 5 from brand pool + bucket tags)
- ✅ Pinned Comment (bucket-specific question)
- ✅ 5 Reply Comments (5 distinct styles: Relatable Parent, Non-Parent, Emoji, Validation, CTA)

### Regeneration System (`lib/regenerator.dart`)
Regenerate **individual sections** with style variations — no need to re-generate the whole package:

| Target | Style Variations (8) |
|--------|---------------------|
| Hook | More Playful, More Curiosity, Simpler, Funnier, More Parent-Relatable, More Educational, More Visual |
| All Slides | Same 8 styles |
| Single Slide | Same 8 styles |
| Visual Prompts | Same 8 styles |
| Caption | Same 8 styles |
| CTA | Rotating options |
| Hashtags | Fresh shuffle |
| Pinned Comment | Same 8 styles |
| Reply Comments | Same 8 styles |

```dart
final result = await Regenerator.regenerate(RegenerationRequest(
  originalPackage: package,
  target: RegenerateTarget.caption,
  style: RegenerateStyle.funnier,
));
```

### Brand Context Auto-Injection
Every AI prompt automatically receives:

```
BRAND CONTEXT (auto-injected):
Brand: Fun Learning With Palak
Audience: Parents of preschoolers
Tone: Warm, playful, parent-relatable, simple
Visual Style: Soft pastel watercolor storybook, cream background

CHARACTER LOCK:
Ria: dark brown hair, two ponytails, pink bows, brown eyes, pink dress, NO GLASSES
Rio: dark brown hair, blue outfit, brown eyes, NO GLASSES
Cuty: small white bunny, pink bow, unchanged always

FORMAT: Carousel (7 slides)
BUCKET: Challenge 🔎
SLIDE TEMPLATE: Cover → Challenge → Options → Think → Reveal → Why → CTA
```

---

## 18. Redesigned Dashboard (7 Options + Bottom Bar)

The main dashboard now shows exactly **7 focused options** — no clutter:

| # | Option | Navigates To | Purpose |
|---|--------|--------------|---------|
| 1 | ✨ **Create Content** | `QuickContentScreen` | One idea → Carousel + Reel + Trial Reel + Image (all at once) |
| 2 | 🎬 **Reel** | `StoryScreen` | Full workflow: story → script → images → voice → video |
| 3 | 🧪 **Trial Reel** | `TrialReelScreen` | 60-sec compilation generator (hook, 7 fast cuts, celebration, follow CTA) |
| 4 | 📚 **Carousel** | `CarouselMakerScreen` | Enter idea → get slide prompts for all carousel pages |
| 5 | 🖼️ **Image** | `SingleImageScreen` | Enter idea → get 7 different image prompts for Meta AI |
| 6 | 💡 **Idea Vault** | `IdeaInboxScreen` | Capture, organize & develop ideas (💡📝✅📤♻️) |
| 7 | ⚙️ **Settings** | `SettingsScreen` | AI provider, API keys, defaults, export/import data |

**Bottom Bar**: 💬 **Promotion Comments** — persistent bottom button opens modal sheet with bucket filter chips, saved comments, and "Add comment" form.

**Design**: Clean cards with color-coded icons, descriptive subtitles, chevron indicators. Comments vault accessible only via bottom bar (not cluttering main scroll area).

---

## 19. 14-Day + Extended Post Library (24 Posts)

`lib/day14_posts.dart` now contains **24 ready-to-use posts** (Days 2-25):

### Days 2-14 (Original Plan)
| Day | ID | Type | Bucket | Hook |
|-----|-----|------|--------|------|
| 2 | which-doesnt-belong | Static Image | puzzle | Which One Doesn't Belong? 🧩 |
| 3 | mumma-says | Reel | humor | MUMMA SAYS THIS 100× A DAY 😂 |
| 4 | kitchen-challenge | Carousel | activity | 5-MINUTE KITCHEN CHALLENGE 🥄 |
| 5 | ask-tonight | Static Image | talk | ASK YOUR CHILD THIS TONIGHT 🗣️ |
| 6 | 3year-skills | Carousel | skill | CAN YOUR 3-YEAR-OLD DO THESE? ✅ |
| 7 | toddler-math | Reel | humor | TODDLER MATHEMATICS 😂 |
| 8 | find-cuty | Static Image | puzzle | FIND THE HIDDEN CUTY! 👀 |
| 9 | sock-hunt | Reel | activity | THE SOCK HUNT 🧦 |
| 10 | 3-questions | Carousel | talk | 3 QUESTIONS TO ASK YOUR CHILD THIS WEEK ❤️ |
| 11 | 4year-skills | Carousel | skill | CAN YOUR 4-YEAR-OLD DO THESE? ✅ |
| 12 | dinner-types | Static Image | humor | THREE TYPES OF KIDS AT DINNER 🍽️ |
| 13 | pattern-game | Reel | puzzle | WHAT COMES NEXT? 🟡🔵🟡🔵❓ |
| 14 | favorite-format | Carousel | wrap | WHICH NEW FORMAT WAS YOUR FAVORITE? 🗳️ |

### Days 15-25 (Mission Series — Post-100 Strategy)
| Day | ID | Type | Bucket | Hook |
|-----|-----|------|--------|------|
| **15** | household-swaps | Carousel | activity | **NO SPECIAL TOYS NEEDED — HERE'S WHAT TO USE! 🏠** ⭐ |
| 16 | voted-mission-won | Single Image | wrap | THE VOTES ARE IN! 🏆 |
| 17 | mission1-race-track | Reel | activity | MISSION 2: ON YOUR MARK! 🏁 |
| 18 | mission2-concert | Reel | activity | MISSION 3: LIVING ROOM CONCERT! 🎤 |
| 19 | mission3-art-studio | Reel | activity | MISSION 4: ART CORNER TIME! 🎨 |
| 20 | mission4-detective | Reel | puzzle | MISSION 5: CASE OPEN! 🕵️ |
| 21 | mission5-rescue | Reel | activity | MISSION 6: RESCUE TIME! 🧸 |
| 22 | mission6-treasure | Reel | skill | MISSION 7: TREASURE HUNT! 🎁 |
| 23 | mission7-daily-care | Reel | skill | MISSION 8: SELF-CARE SQUAD! 🍎 |
| 24 | trial-reel-7-missions | Reel | activity | 7 SCREEN-FREE MISSIONS IN 60 SECONDS 🏠✨ |
| 25 | week-wrap-up | Carousel | wrap | WE DID IT — ALL 7 MISSIONS COMPLETE! 🎉 |

**All posts include:** Complete fields (title, hook, main idea, problem, lesson, visual style, image prompt, caption, CTA, hashtags, 5 varied comments, script, bucket, character-consistent prompts).

---

## 20. Asset Idea Files (32 Additional Ideas)

`assets/ideas/` contains 4 markdown files with 32 ready-to-import ideas:

| File | Ideas | Formats |
|------|-------|---------|
| `Carousel_Post_Ideas.md` | 8 | Carousel (5-9 slides each) |
| `Reel_Post_Ideas.md` | 8 | Reel (10-20 sec each) |
| `Static_Image_Post_Ideas.md` | 8 | Static Image |
| `Trial_Reel_Post_Ideas.md` | 8 | Trial Reel (10-60 sec) |

---

## 21. Data Storage (Local JSON Files)

All data persists locally in app documents directory:

| Data | File | Structure |
|------|------|-----------|
| Reel Projects | `stories/{id}.json` | Individual project files |
| Saved Ideas | `quick_ideas.json` | Array of QuickIdea |
| Post History | `quick_post_history.json` | Last 50 generated (auto-saved) |
| Promotion Comments | `promo_comments.json` | Array with bucket tags |
| Plan Results | `plan_data.json` | PostRecord with bucket field |

Access via `adb shell run-as com.example.reel_audio` on debug builds.

---

## 22. Next Development Phase — Updated Roadmap

### 🔴 P0 — **DONE**
1. ✅ Content Bucket system (5 buckets)
2. ✅ Brand + Character Lock (Ria/Rio/Cuty)
3. ✅ Complete Content Package Generator
4. ✅ Regeneration System (9 targets × 8 styles)
5. ✅ 5-Option Dashboard

### 🔴 P1 — **Immediate Priority (Next Sprint)**

| Priority | Feature | Why |
|----------|---------|-----|
| 🔴 P1 | **One Idea → Multiple Formats** | Biggest workflow improvement: generate Carousel + Reel + Trial Reel + Image from single idea |
| 🔴 P1 | **Idea Inbox** | Capture raw ideas quickly without filling full form (Title, Raw idea, Bucket, Notes, Status) |
| 🔴 P1 | **Posting Pack Screen** | Single screen to copy Hook, Caption, Hashtags, Pinned Comment, Reply Comments, Image Prompts, Script, plus "Copy Everything" |
| 🟠 P1 | **Content Quality Check** | Actionable pre-export checks: Hook length, slide text density, character visibility, CTA presence, hashtag count, character lock |
| 🟠 P1 | **Trial Reel → Shot Planner Integration** | Replace `makeImagePrompt` with proper Veo-style shot prompts; keep local pipeline as fallback |

### 🟠 P1 — **Workflow Redesign (After Above)**

1. **Proper "Create" Flow** — Idea → Bucket → Format → Generate → Review/Edit → Export
2. **Content Quality Check UI** — Actionable flags (⚠ Hook too long, ⚠ Slide 4 too dense, ✅ Ria visible, ✅ 5 hashtags) + "Fix Issues" button
3. **Trial Reel Consolidation** — Hook → Shot Planner → Video Shot Prompts → Optional Veo → Local FFmpeg assembly (Veo optional)

### 🟡 P2 — **Content Management (After P1)**

| Feature | Purpose |
|---------|---------|
| **Content Library** | Searchable, filterable by bucket/format/status; Favorite, Duplicate, "Create Another Format" |
| **Idea/Draft/Ready/Posted/Reuse Statuses** | Separate raw Ideas from generated Posts; clear lifecycle |
| **Settings Screen** | API keys, defaults, brand settings (convenience) |

### 🟢 P3 — **Not Needed Yet**

| Feature | Reason |
|---------|--------|
| Scheduling / Publishing automation | Content creation is the value, not publishing |
| Onboarding | Personal app — not needed |
| Multi-platform publishing | Single-platform focus |
| Complicated analytics | Overkill for current stage |
| Another AI provider | OpenAI backend already scaffolded |

---

## 23. Explicit Content Hierarchy (New Architecture)

The app now follows this explicit hierarchy — every piece of content flows through these layers:

```
IDEA
  ↓
BUCKET (Challenge 🔎 / Conversation 🗣️ / Activity 🏠 / Humor 😂 / Age Practice 📚)
  ↓
FORMAT (Carousel 📚 / Reel 🎬 / Trial Reel 🧪 / Single Image 🖼️)
  ↓
CONTENT PACKAGE
  ├── Hook
  ├── Slides/Shots (per bucket template × format count)
  ├── Visual Prompts (per slide, with Character Lock + Brand Context)
  ├── Caption (hook + idea + CTA + 5 hashtags)
  ├── CTA (bucket-specific)
  ├── Hashtags (exactly 5 from brand pool + bucket tags)
  ├── Pinned Comment (bucket-specific question)
  └── 5 Reply Comments (Relatable Parent, Non-Parent, Emoji, Validation, CTA)
  ↓
QUALITY CHECK (actionable flags, not arbitrary scores)
  ↓
POSTING PACK (single screen: Copy Hook, Caption, Hashtags, Pinned, Replies, Prompts, Script, "Copy Everything")
  ↓
STATUS (Idea 💡 → Developing 📝 → Ready ✅ → Posted 📤 → Reuse ♻️)
```

**Example: "Find the Hidden Cuty"**

```
Find Hidden Cuty
        ↓
Challenge 🔎
        ↓
┌─────────────────────────────────────────┐
│  Carousel 📚    Reel 🎬    Trial Reel 🧪  Single Image 🖼️
│  7 slides       5 shots      8 shots         1 image
│  ↓              ↓             ↓              ↓
│  Package        Package       Package        Package
│  (each with     (each with    (each with     (each with
│   full output)  full output)  full output)   full output)
└─────────────────────────────────────────┘
        ↓
   Quality Check
        ↓
   Posting Pack (per format)
        ↓
   Status: Ready → Posted → Reuse
```

This architecture means **one idea becomes four related packages** — not four unrelated ideas. Bucket, characters, brand style, and core idea stay identical; only the format-specific structure changes.

---

## 24. Ideal Dashboard (Current State)

```
🌸 FUN LEARNING WITH PALAK

What are we creating today?

┌─────────────────────────────────────┐
│ ✨ CREATE CONTENT                   │
│ Turn an idea into a post            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🎬 REEL MAKER                       │
│ Full story → video                  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🧪 TRIAL REEL                       │
│ Fast experimental reel              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📚 CAROUSEL                         │
│ Quick visual content                │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🖼️ IMAGE                            │
│ 7 prompts for Meta AI               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 💡 IDEA VAULT                       │
│ Ideas, drafts & posts               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ⚙️ SETTINGS                         │
│ AI, API keys, defaults              │
└─────────────────────────────────────┘

💬 Promotion Comments  (persistent bottom button)
```

**Current implementation matches target** — all 7 options + bottom bar are live. No clutter, no comments in main scroll area.

---

## 25. What We Will NOT Build (Explicit)

| Feature | Reason |
|---------|--------|
| ❌ Scheduling / Auto-publishing | Content creation is the core value; publishing is manual |
| ❌ Onboarding flow | Personal use app — you know how it works |
| ❌ Multi-platform publishing (TikTok, YouTube, etc.) | Instagram-first; cross-posting is manual |
| ❌ Complex analytics dashboard | Content quality > post analytics |
| ❌ Additional AI providers (Claude, etc.) | OpenAI backend already scaffolded; stick to one |
| ❌ Elaborate Settings UI | Hardcoded defaults work; settings = convenience only |
| ❌ Team collaboration / Multi-user | Solo creator workflow |

---

## 26. Development Priority Summary

| Priority | Feature | Effort | Impact |
|----------|---------|--------|--------|
| 🔴 P1 | One Idea → Multiple Formats | Medium | **Highest** — eliminates duplicate work |
| 🔴 P1 | Idea Inbox | Low | **High** — captures fleeting ideas |
| 🔴 P1 | Posting Pack Screen | Low | **High** — daily time saver |
| 🟠 P1 | Content Quality Check | Medium | **High** — prevents bad posts |
| 🟠 P1 | Trial Reel → Shot Planner | Medium | **High** — fixes architectural gap |
| 🟠 P1 | Proper Create Flow | Medium | **Medium** — polish |
| 🟡 P2 | Content Library + Statuses | Medium | **Medium** — scales with volume |
| 🟡 P2 | Settings | Low | **Low** — convenience |
| 🟢 P3 | Scheduling | High | **Low** — not core value |
| 🟢 P3 | Onboarding | Low | **None** — personal app |

---

The app has evolved from "Quick Content Studio" → **"Fun Learning Content Studio"** — a **brand-aware, bucket-driven, format-flexible content production pipeline** with:

- **Capture**: Idea Inbox
- **Generate**: One Idea → Multiple Formats (Carousel/Reel/Trial Reel/Image)
- **Check**: Content Quality Check (actionable, not scores)
- **Export**: Posting Pack (single screen, "Copy Everything")
- **Manage**: Content Library with Idea/Draft/Ready/Posted/Reuse statuses
- **Reuse**: Duplicate → Create Another Format

All powered by immutable Brand + Character Lock, 5 Content Buckets, 4 Formats, and per-section Regeneration with 8 style variations.