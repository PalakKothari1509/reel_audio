# App Overview: Fun Learning With Palak

## What the app does
A Flutter mobile app that generates Instagram reels and carousel posts for Indian preschool parents.
Stories feature toddlers Ria, Rio, white bunny Cuty, an AI Robot, and adult characters (Mumma, Papa, Daadi, Teacher).
The app manages the full content lifecycle: idea → script → prompt → video → quality check → posting.

## Core concepts

### 1. Characters (single source: `lib/characters.dart`)
| Name | Emoji | Description |
|---|---|---|
| Ria | 🌸 | Toddler girl, pigtails with pink bows, pink star dress, NO glasses |
| Rio | 💙 | Toddler boy, brown hair, blue-grey outfit, NO glasses |
| Cuty | 🐰 | White bunny, coral-pink bow, always upright |
| Robot | 🤖 | Friendly AI helper, white/silver body, teal LED accents, child-height |
| Mumma | 👩 | Indian mother, yellow kurta, blue jeans |
| Papa | 👨 | Indian father, light blue kurta |
| Daadi | 👵 | Grandmother, silver bun, glasses, cream saree |
| Teacher | 👩‍🏫 | School teacher, blue kurta, holds book |

Key APIs:
- `kCharacterOptions` — list of `CharOption(id, name, emoji)` for UI (8 characters including Robot)
- `kCharacterNames` — `['Ria', 'Rio', 'Cuty', 'Robot', 'Mumma', 'Papa', 'Daadi', 'Teacher']` for string-based logic
- `kCharacterDescriptions` — detailed appearance text used in image/video prompts
- `characterDescription(String name)` → returns description for prompts
- `CharacterLibrary` (in `lib/brand_system.dart`) — full character model with personality, appearance, and speech patterns for AI prompts

### 2. Ideas (source: `lib/content_ideas.dart`)
- `HookIdea` class: `id`, `category`, `cover`, `opening`, `problem`, `lesson`, `caption`, `pinnedComment`, `forApp`, `storyDetail`, `setting`, `sceneDetail`, `dialogue`, `mess`, `innerThought`, `endingBeat`, `defaultCast`, `keepMoralOffScreen`, `quote`, `detail`, `punchline`, `readyPrompt`
- `kDefaultHooks` — 116 built-in ideas using the `idea_N` scheme (`idea_1` through `idea_116`)
- 6 safety hooks (`idea_1`–`idea_6`) are spread in via `...kSafetyHooks`
- `kDefaultHooksWithRewrite` — alias to `kDefaultHooks` (rewrites now embedded inline in `storyDetail`)
- `kSafetyHooks` — 6 Kids Safety ideas (idea_1 through idea_6)
- Categories in `kHookCategories`: `Relatable`, `Struggle first`, `Surprising`, `Warm lesson`, `Page & milestone`, `Navratri`, `Series`
- `readyPrompt` field contains pre-built viral prompts for all 97 hooks that have them (all 94 in `kDefaultHooks` + safety hooks combined)
- `kRewrittenStories` and `kMomentUpgrades` were merged into inline `storyDetail` fields (no longer separate maps)

### 3. Content Collections (source: `lib/content_collections.dart`)
- 14 thematic collections for browsing: Ria & Robot, Festivals & Events, Morning & Bedtime Routines, Food & Mealtime, Tantrums & Big Feelings, Siblings & Sharing, Parent Moments, Warm Lessons, Play & Learning, Parent Guides, 7 Missions Week, Milestones & Community, Kids Safety, My Ideas
- `collectionOf(id, custom)` → maps idea IDs to collection IDs
- `kCollections` — list of `IdeaCollection(id, label, emoji)`
- `kSafetyHooks` IDs are registered in the `'safety'` `_members` map

### 4. Content Library (source: `lib/content_library.dart`)
- `ContentLibraryItem` — saved content with `sourceIdeaId` for traceability
- `kDefaultHooksWithRewrite` used as the source for new library items

### 5. Prompt System (source: `lib/master_prompt.dart`)
```dart
kMasterPrompt             // Brand rules, audience, visual style, character lock, language & story quality
kVisualStyle              // "Soft 3D Pixar-Disney animation style, vertical 9:16..."
kNegativeInstructions     // "No duplicate characters, no identity changes, no on-screen text..."
kStoryStructureRules      // Visual storytelling, structure, and text overlay guidance
kRequiredPromptSections   // Sections every video prompt must include
```

### 6. Hook/Text System (source: `lib/hook_system.dart`)
- `generateHookText(story, partNumber, totalParts)` — context-aware text overlay per part
- `generateOnScreenText(story, partNumber, totalParts, position)` — top/middle/bottom text

### 7. Story Generation (source: `lib/story_generator_offline.dart`)
- `StoryGenerator().generate()` — deterministic offline story from hook + storyDetail
- `GeneratedStory` model: `title`, `hook`, `who`, `where`, `problem`, `twist`, `worse`, `solution`, `endingLine`, `moral`, `hookOptions`
- Parses `Story:`, `Twist:`, `Resolution:`, `Moral:` labels from `storyDetail`

### 8. Video Prompt Generation (source: `lib/video_prompt_generator_offline.dart`)
```dart
OfflineVideoPromptGenerator().generateFromStory(
  GeneratedStory story,
  {required int totalSeconds, required List<String> characters},
) → GeminiVideoResult
```
- Returns `GeminiVideoResult` with `storyTitle`, `storyFoundation`, `List<VideoPartPrompt>`
- Each `VideoPartPrompt` = one 10-second part with full prompt text

### 9. Engagement Generation (source: `lib/offline_engagement.dart`)
```dart
OfflineEngagementGenerator().generate(storyMoral: String) → OfflineEngagementPackage
```
- Returns caption, hashtags (5), pinnedComment, suggestedReplies (6), followReason
- `buildOfflineImagePrompt()` and `buildOfflineCarouselSlides()` for other formats

## Data Layer

All persistent data is stored as JSON files in the app's documents directory, backed by a shared `JsonFileStore<T>` base class. The full store catalog, model fields, ID schemes, cross-store relationships, and error-resilience patterns are documented in [DATA.md](./DATA.md).

**Quick reference of stores:**

| Store | JSON file | Model | Purpose |
|---|---|---|---|
| `ContentLibraryStore` | `content_library.json` | `ContentLibraryItem` | All content packages with status flow |
| `PromptVault` | `saved_prompts.json` | `SavedPrompt` | Versioned AI prompts |
| `VideoLibrary` | `video_assets.json` | `VideoAsset` | Video metadata + file references |
| `HookStore` | `hooks.json` | `HookIdea` | User edits + custom hooks |
| `ScheduleStore` | `schedule.json` | `PostSlot` | Posting schedule (7 slots) |
| `PostLogStore` | `posts.json` | `PostRecord` | Posted content + performance |
| `PromoCommentStore` | `promo_comments.json` | `PromoComment` | Engagement comment vault |
| `QuickIdeaStore` | `quick_ideas.json` | `QuickIdea` | Saved quick content ideas |
| `QuickHistoryStore` | `quick_post_history.json` | `QuickIdea` | Last 50 generated ideas |
| `QualityCheckCenter` | `quality_reports.json` | `QualityReport2` | Quality check reports |

See DATA.md for full model field tables, methods, ID schemes, versioning, error resilience, and test seams.

## Architecture flow

```
User selects idea from Content Library (kDefaultHooksWithRewrite)
    ↓
If hook has a readyPrompt → GeminiVideoResult.parseReadyPrompt() splits into VideoPartPrompt parts (fast path, no API call)
    ↓
If online (no readyPrompt): content_studio_service.dart → generateImagePrompt/generateCarouselPrompts/generateGeminiVideoPrompts
    → Auto-saves prompt to PromptVault
    → Auto-saves production plan to VideoProductionPlan store
    ↓
If offline or Gemini fails (429/400/503): content_studio_screens.dart
    ↓
OfflineStoryMakerScreen:
  1. _storyFromHook(hook) → GeneratedStory (uses hook.problem, hook.lesson, hook.storyDetail)
  2. OfflineVideoPromptGenerator.generateFromStory(story, duration, characters)
     → Uses: generateHookText() for overlays, characterDescription() for blocks
     → Uses: kVisualStyle, kNegativeInstructions from master_prompt.dart
  3. OfflineEngagementGenerator.generate(story.moral)
    ↓
All generated prompts auto-saved to PromptVault
All finished videos saved to VideoLibrary
Quality reports saved to QualityCheckCenter
```

## Content Management Architecture

The app is organized into six connected modules for managing content from idea to posted Reel:

### Module 1: Content Library
- **File**: `lib/content_library.dart`
- **Stores**: `ContentLibraryStore` (persists to `content_library.json`)
- **Model**: `ContentLibraryItem` with `sourceIdeaId`, `status`, `qualityReport`, `formatOutputs`
- **Bridges**: Connects predefined ideas (`kDefaultHooks`) to production workflow

### Module 2: Prompt Vault
- **File**: `lib/prompt_vault.dart`
- **Stores**: `PromptVault` (persists to `saved_prompts.json`)
- **Models**: `SavedPrompt` (with `PromptType` enum: story, script, character, sceneImage, video, voice, caption, qualityCheck, custom)
- **Features**: Automatic saving after generation, version history, type filtering, getLatest by content+type
- **Integration**: All Gemini-generated prompts are saved automatically

### Module 3: Gemini Video Master Prompt
- **File**: `lib/gemini_video_master_prompt.dart`
- **Template**: `kGeminiVideoMasterPrompt` — 30-second vertical Reel plan in Story/Twist/Resolution/Moral format
- **Renderer**: `renderVideoMasterPrompt(VideoPromptVariables)` — fills template variables
- **Rules**: Text overlays required, Hinglish dialogue, continuity between parts
- **Model**: `lib/video_production_plan.dart` — `VideoProductionPlan` and `ClipPlan` classes

### Module 4: Video Library
- **Files**: `lib/video_library.dart`, `lib/video_library_store.dart`, `lib/file_storage.dart`
- **Stores**: `VideoLibrary` (persists to `video_assets.json`)
- **Model**: `VideoAsset` (with `VideoStatus` enum: draft, uploaded, qualityChecked, approved, posted, archived)
- **Features**: Upload, preview, download, multiple versions, file existence checks
- **Storage**: Files kept separate from metadata; `FileStorageManager` handles file I/O

### Module 5: Quality Check Center
- **File**: `lib/quality_check_center.dart`
- **Models**: `QualityReport2`, `QualityFinding`, `QualityCheckType` enum (script, prompt, video)
- **Findings**: Four severity levels — Critical, Major, Minor, Suggestion
- **Checkers**:
  - `checkScript()` — real-life relevance, age appropriateness, natural Hinglish, clear resolution
  - `checkPrompt()` — characters present, duration specified, format, negative instructions
  - `checkVideo()` — file readable, file size, duration, aspect ratio
- **Store**: `QualityCheckCenter` (persists to `quality_reports.json`)

### Module 6: Posting Tracker
- **Model**: `ContentLibraryItem` fields (`status`, `postedAt`, `instagramPostUrl`, `performanceMetrics`)
- **Status flow**: idea → scripted → tested → ready → posted → archived

### Module 7: Asset Completeness Service
- **File**: `lib/asset_completeness_service.dart`
- **Model**: `AssetCompleteness` — tracks whether content has script, video prompt, video asset, and quality report
- **Service**: `AssetCompletenessService` — `checkContentId()`, `checkAll()`, `getMissing()`
- **Features**: Identifies which content items are missing assets; drives the Ready-to-Post checklist on the Dashboard

### 8. Dashboard & UI Screens
- **File**: `lib/dashboard_screen.dart` — Ready-to-Post checklist showing ready items and items needing attention
- **File**: `lib/home_screen.dart` — `ContentStudioHome`, the live app home with nav cards for Create Content, Add New Idea, Content Library, Image Prompt, Carousel Prompts, Gemini Video, Offline Story, Promotion Comments, Review All Ideas, and Settings
- **File**: `lib/prompt_vault_screen.dart` — UI for browsing, searching, filtering, copying, and deleting saved prompts
- **File**: `lib/video_library_screen.dart` — UI for listing, uploading, previewing videos; status management (quality check, approve, mark posted)
- **File**: `lib/quick_content.dart` — `PromoCommentVaultScreen` for promotion comment management

## Key design decisions

1. **Single source of truth** — Characters defined in `characters.dart`, prompts in `master_prompt.dart` and `gemini_video_master_prompt.dart`, ideas in `content_ideas.dart`, collections in `content_collections.dart`
2. **No duplication** — All generators import and reference the shared sources
3. **Rewrite layer** — Rewrites are now embedded inline in `storyDetail` fields directly. `kDefaultHooksWithRewrite` is an alias to `kDefaultHooks`; user edits are preserved via `HookStore.load()` while custom hooks are appended at runtime
4. **Collection grouping** — Ideas are grouped into 14 thematic collections via `collectionOf()`; the vault groups by `sourceIdeaId`
5. **Automatic offline fallback** — `content_studio_screens.dart` detects Gemini errors (429/400/503) and switches to offline mode
6. **Deterministic offline** — Uses `dart:math` seeded random for reproducible output
7. **Shared UI** — `IdeaInputScreen` used by all online features, with character selection from `kCharacterOptions`
8. **Prompt auto-save** — `VideoPartPrompt` now includes `textOverlay` field; prompts auto-saved to PromptVault after generation and after part regeneration
9. **Hinglish language** — Video prompts require Hinglish dialogue and text overlays for sound-off viewing
10. **Files separate from metadata** — Videos stored as files, metadata in JSON; `FileStorageManager` handles file I/O
11. **Version history** — Prompts and videos retain version history; new versions don't overwrite old ones
12. **Quality checks with severity** — Critical/Major/Minor/Suggestion severity levels; reports tied to asset version
13. **Content-level tracking** — `QualityReport2` has both `contentId` and `assetId` for flexible querying; `AssetCompletenessService` aggregates across all stores
14. **Navigation hub** — `ContentStudioHome` (in `lib/home_screen.dart`) is the live app home with nav cards for Create Content, Content Library, Add New Idea, Image Prompt, Carousel Prompts, Gemini Video, Offline Story Generator, Promotion Comments, Review All Ideas, and Settings

## Key files to modify
- `lib/content_ideas.dart` — Add/edit ideas (HookIdea entries, kHookCategories, kSafetyHooks, kDefaultHooks, kDefaultHooksWithRewrite — alias to kDefaultHooks)
- `lib/hook_templates.dart` — 12 hook templates, HookGenerator class, power words lists
- `lib/add_idea_screen.dart` — Form for adding custom ideas to Content Library (title, bucket, format, characters, opening, problem, lesson, story details, notes); saves via ContentLibraryService.addIdea
- `lib/content_collections.dart` — Add/edit collection mappings
- `lib/characters.dart` — Update character descriptions (kCharacterOptions, kCharacterNames, kCharacterDescriptions)
- `lib/story_generator_offline.dart` — Add/edit story templates
- `lib/master_prompt.dart` — Update brand rules
- `lib/plan_data.dart` — HookStore, ScheduleStore, PostLogStore; HookStore.load() merges user edits with default hooks
- `lib/prompt_vault.dart` — SavedPrompt model and PromptVault store
- `lib/content_studio_service.dart` — GeminiVideoResult.parseReadyPrompt() for readyPrompt fast-path
- `lib/content_studio_service.dart` — Gemini API calls & readyPrompt parsing
- `lib/content_studio_screens.dart` — IdeaInputScreen, IdeaReviewScreen, GeminiVideoScreen, CarouselPromptsScreen, ImagePromptScreen
- `lib/video_production_plan.dart` — VideoProductionPlan and ClipPlan models, GeminiVideoResult, VideoPartPrompt
- `lib/video_library.dart` — VideoAsset model and VideoStatus enum
- `lib/video_library_store.dart` — VideoLibrary store
- `lib/json_file_store.dart` — Base class for all JSON stores (path resolution, test seam, per-row decoding)
- `lib/file_storage.dart` — FileStorageManager for app-managed video file storage
- `lib/quality_check_center.dart` — QualityReport2, QualityFinding, QualityCheckCenter
- `lib/asset_completeness_service.dart` — AssetCompleteness model and AssetCompletenessService
- `lib/quality_check.dart` — Legacy QualityReport, QualityChecker, and 35 quality rules
- `lib/content_library.dart` — ContentLibraryItem model and ContentLibraryStore
- `lib/models/quick_idea.dart` — QuickIdea model, QuickIdeaStore, QuickHistoryStore
- `lib/quick_content.dart` — PromoComment model and PromoCommentStore
- `documentation/DATA.md` — Full data architecture reference (stores, models, IDs, relationships, error resilience)
