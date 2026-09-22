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
The app now opens on a creator dashboard with four clear entry points:
- Make a reel: the existing story, script, image, voice, and render workflow
- Create a quick post: carousel, static-image, story, or reel copy packs
- Browse ideas: complete built-in hooks with filled story beats, not blank placeholders
- Profile promotion comments: open the full reusable comment vault

The dashboard shows the first three ready comments with one-tap copy. The `Profile promotion comments` button opens every saved comment, supports copying, and lets you add another reusable comment. Saved story history remains available through the existing folder/file-manager icon in the dashboard app bar.

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
