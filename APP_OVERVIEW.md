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
- reusable profile-promotion comments with save, copy, and delete actions

### Gallery importing
The Android app now declares image-library access for importing images from the device gallery. The story image picker uses the device gallery multi-image picker, while video selection remains separate.
