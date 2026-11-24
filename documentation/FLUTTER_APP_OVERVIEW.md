# Flutter Application Overview — Fun Learning With Palak Content Studio

## What the app does

**Fun Learning With Palak Content Studio** is a Flutter mobile app for parents of children aged 1–4. It is a content decision system and production pipeline for short-form educational Instagram Reels and carousel posts. The full content lifecycle runs inside the app: idea → script → prompt → video → quality check → post → track.

The app is **offline-first**: all data stays on-device in JSON files. Gemini is used when available (online mode), with automatic offline fallback if Gemini returns errors (429/400/503) or no API key is configured.

**Pipeline:** IDEA → FORMAT → CONTENT PACKAGE → CREATIVE → POST → TRACK

---

## Core concepts

### 1. Characters (`lib/characters.dart`)

Single source of truth for all characters used in prompts and images.

| Name | Emoji | Description |
|------|-------|-------------|
| Ria | 🌸 | Toddler girl, pigtails with pink bows, pink star dress, NO glasses |
| Rio | 💙 | Toddler boy, brown hair, blue-grey outfit, NO glasses |
| Cuty | 🐰 | White bunny, coral-pink bow, always upright |
| Robot | 🤖 | Friendly AI helper, white/silver body, teal LED accents, child-height |
| Mumma | 👩 | Indian mother, yellow kurta, blue jeans |
| Papa | 👨 | Indian father, light blue kurta |
| Daadi | 👵 | Grandmother, silver bun, glasses, cream saree |
| Teacher | 👩‍🏫 | School teacher, blue kurta, holds book |

Key APIs:
- `kCharacterOptions` — list of `CharOption(id, name, emoji)` for UI chip selection
- `kCharacterNames` — string names for logic (`['Ria', 'Rio', 'Cuty', 'Robot', 'Mumma', 'Papa', 'Daadi', 'Teacher']`)
- `kCharacterDescriptions` — detailed appearance text used in image/video prompts
- `characterDescription(String name)` → description for prompts
- `CharacterLibrary` (in `lib/brand_system.dart`) — full character model with personality, appearance, and speech patterns

### 2. Ideas (`lib/content_ideas.dart` + `assets/data/content_ideas.json`)

- `HookIdea` class: id, category, cover, opening, problem, lesson, caption, pinnedComment, forApp, storyDetail, setting, sceneDetail, dialogue, readyPrompt, and more
- 117 built-in ideas (`idea_1` through `idea_117`) bundled as `assets/data/content_ideas.json`, loaded at runtime via `rootBundle`, parsed with `HookIdea.fromJson()`, validated (117 unique records, correct ordering, archived set `{idea_41, idea_42, idea_43, idea_44, idea_46}`)
- `kDefaultHooks` in Dart source is the fallback if JSON loading fails
- 6 safety hooks (`idea_1` through `idea_6`) — category `Safety`, exposed as `kSafetyHooks`
- Categories: Relatable, Struggle first, Surprising, Warm lesson, Page & milestone, Navratri, Series, Safety
- `readyPrompt` field contains pre-built viral prompts for hooks that have them

### 3. Prompt system (`lib/master_prompt.dart`)

```dart
kMasterPrompt             // Brand rules, audience, visual style, character lock, language, story quality
kVisualStyle              // "3D Pixar animation style, vertical 9:16..."
kNegativeInstructions     // "No duplicate characters, no identity changes, no on-screen text..."
kStoryStructureRules      // Visual storytelling and structure guidance
kRequiredPromptSections   // Sections every video prompt must include
```

All prompts use Hinglish dialogue and text overlays for sound-off viewing. The exact phrase `3D Pixar animation style` is used in `readyPrompt` and prompts.

### 4. Story generation (`lib/story_generator_offline.dart`)

`StoryGenerator().generate()` produces a deterministic offline story from a hook + storyDetail. Parses `Story:`, `Twist:`, `Resolution:`, `Moral:` labels from `storyDetail`.

### 5. Video prompt generation (`lib/video_prompt_generator_offline.dart`)

`OfflineVideoPromptGenerator().generateFromStory(story, totalSeconds, characters)` → `GeminiVideoResult` with `storyTitle`, `storyFoundation`, and `List<VideoPartPrompt>` (one 10-second part each with full prompt text).

### 6. Engagement generation (`lib/offline_engagement.dart`)

`OfflineEngagementGenerator().generate(storyMoral)` → `OfflineEngagementPackage` with caption, 5 hashtags, pinnedComment, 6 suggestedReplies, followReason. Also builds image prompts and carousel slides.

---

## Data layer

All persistent data is stored as JSON files in the app's documents directory, backed by `JsonFileStore<T>`.

| Store | JSON file | Model | Purpose |
|-------|-----------|-------|---------|
| ContentLibraryStore | content_library.json | ContentLibraryItem | All content packages with status flow |
| PromptVault | saved_prompts.json | SavedPrompt | Versioned AI prompts |
| VideoLibrary | video_assets.json | VideoAsset | Video metadata + file references |
| HookStore | hooks.json | HookIdea | User edits + custom hooks |
| ScheduleStore | schedule.json | PostSlot | Posting schedule (7 slots) |
| PostLogStore | posts.json | PostRecord | Posted content + performance |
| QualityCheckCenter | quality_reports.json | QualityReport2 | Quality check reports |
| QuickIdeaStore | quick_ideas.json | QuickIdea | Saved quick content ideas |
| QuickHistoryStore | quick_post_history.json | QuickIdea | Last 50 generated ideas |

Status flow: idea → scripted → tested → ready → posted → archived.

---

## Architecture flow

```
User selects idea from Content Library
    ↓
If hook has a readyPrompt → GeminiVideoResult.parseReadyPrompt() splits into VideoPartPrompt parts (fast path, no API call)
    ↓
If online (no readyPrompt): content_studio_service.dart → Gemini generation
    → Auto-saves prompt to PromptVault
    → Auto-saves production plan to VideoProductionPlan store
    ↓
If offline or Gemini fails: content_studio_screens.dart → OfflineStoryMakerScreen
    1. _storyFromHook(hook) → GeneratedStory
    2. OfflineVideoPromptGenerator.generateFromStory() → uses generateHookText(), characterDescription(), kVisualStyle, kNegativeInstructions
    3. OfflineEngagementGenerator.generate(story.moral)
    ↓
All prompts auto-saved to PromptVault
All finished videos saved to VideoLibrary
Quality reports saved to QualityCheckCenter
```

---

## Content management modules

### Module 1 — Content Library (`lib/content_library.dart`)
Stores `ContentLibraryItem` with `sourceIdeaId`, `status`, `qualityReport`, `formatOutputs`. Bridges predefined ideas to the production workflow.

### Module 2 — Prompt Vault (`lib/prompt_vault.dart`)
`SavedPrompt` model with `PromptType` enum (story, script, character, sceneImage, video, voice, caption, qualityCheck, custom). Auto-saves after generation, version history, type filtering.

### Module 3 — Gemini Video Master Prompt (`lib/gemini_video_master_prompt.dart`)
`kGeminiVideoMasterPrompt` template — 30-second vertical Reel plan in Story/Twist/Resolution/Moral format. `renderVideoMasterPrompt(VideoPromptVariables)` fills template variables.

### Module 4 — Video Library (`lib/video_library.dart`, `lib/video_library_store.dart`)
`VideoAsset` model with `VideoStatus` enum (draft, uploaded, qualityChecked, approved, posted, archived). Upload, preview, download, multiple versions.

### Module 5 — Quality Check Center (`lib/quality_check_center.dart`)
`QualityReport2`, `QualityFinding`, `QualityCheckType` enum (script, prompt, video). Four severity levels: Critical, Major, Minor, Suggestion. Checkers: `checkScript()`, `checkPrompt()`, `checkVideo()`.

### Module 6 — Posting Tracker
Tracked via `ContentLibraryItem` fields (`status`, `postedAt`, `instagramPostUrl`, `performanceMetrics`).

### Module 7 — Asset Completeness Service (`lib/asset_completeness_service.dart`)
`AssetCompletenessService.checkContentId()`, `checkAll()`, `getMissing()` — identifies missing assets, drives the Ready-to-Post checklist on the Dashboard.

---

## Key screens

- `lib/home_screen.dart` — `ContentStudioHome`, the live app home with nav cards for Create Content, Content Library, Add New Idea, Image Prompt, Carousel Prompts, Gemini Video, Offline Story Generator, Promotion Comments, Review All Ideas, Settings
- `lib/content_library_screen.dart` — Browse ideas, filter by collection
- `lib/dashboard_screen.dart` — Ready-to-Post checklist
- `lib/prompt_vault_screen.dart` — Browse, search, filter, copy, delete saved prompts
- `lib/video_library_screen.dart` — List, upload, preview videos; status management
- `lib/content_studio_screens.dart` — IdeaInputScreen, IdeaReviewScreen, GeminiVideoScreen, CarouselPromptsScreen, ImagePromptScreen
- `lib/offline_story_maker_screen.dart` — Offline generation screen
- `lib/settings_screen.dart` — API key configuration

---

## Key design decisions

1. **Single source of truth** — Characters in `characters.dart`, prompts in `master_prompt.dart` / `gemini_video_master_prompt.dart`, ideas in `content_ideas.dart`
2. **Offline-first** — All data on-device in JSON; Gemini optional with automatic fallback
3. **Deterministic offline output** — Seeded random for reproducible results
4. **Prompt auto-save** — Prompts auto-saved to PromptVault after generation and after part regeneration
5. **Hinglish language** — Video prompts require Hinglish dialogue and text overlays
6. **Files separate from metadata** — Videos stored as files, metadata in JSON; `FileStorageManager` handles file I/O
7. **Version history** — Prompts and videos retain version history; new versions don't overwrite old ones

---

## Setup

```bash
flutter pub get
flutter run
```

Tests:
```bash
flutter test
```

Build:
```bash
flutter build apk --release
```

---

## Key files to modify

- `lib/content_ideas.dart` — Add/edit ideas (HookIdea entries, categories, safety hooks)
- `assets/data/content_ideas.json` — Bundled runtime asset with 117 built-in ideas
- `lib/characters.dart` — Update character descriptions
- `lib/master_prompt.dart` — Update brand rules and visual style
- `lib/gemini_video_master_prompt.dart` — Update video master prompt template
- `lib/story_generator_offline.dart` — Add/edit story templates
- `lib/video_prompt_generator_offline.dart` — Add/edit video prompt templates
- `lib/offline_engagement.dart` — Add/edit engagement generation
- `lib/content_collections.dart` — Add/edit collection mappings
- `lib/content_library.dart` — ContentLibraryItem model and store
- `lib/prompt_vault.dart` — SavedPrompt model and PromptVault store
- `lib/quality_check_center.dart` — QualityReport2, QualityFinding, QualityCheckCenter
- `lib/asset_completeness_service.dart` — AssetCompleteness model and service
- `lib/dashboard_screen.dart` — Dashboard UI
- `lib/home_screen.dart` — App home navigation
- `lib/content_studio_screens.dart` — UI screens for online features
