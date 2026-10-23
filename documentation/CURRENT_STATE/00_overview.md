# 00 — App Overview & Architecture

## Purpose
**Fun Learning With Palak** is a content decision system and production pipeline for short-form educational Instagram Reels/Carousels targeting parents of children aged 1–4. The app is **offline-first**: all data stays on-device in JSON files (backed up to Downloads on Android). No cloud sync.

> **Note:** The repo is named `reel_audio` but contains **no audio player code**. The name is historical/legacy. It is a content *studio*, not a player.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (Screens)                      │
│  ContentStudioHome ── ContentStudioScreens ── QualityKit    │
├─────────────────────────────────────────────────────────────┤
│                    Content Services                          │
│  ContentLibraryService  │  ContentGenerator  │  PlanData     │
├─────────────────────────────────────────────────────────────┤
│                      Store Layer                            │
│  JsonFileStore<T> base → 11 concrete stores (JSON files)    │
├─────────────────────────────────────────────────────────────┤
│                   AI / Media Generation                      │
│  Gemini (gemini_call.dart) │ ElevenLabs │ FFmpeg │ flutter_tts│
└─────────────────────────────────────────────────────────────┘
```

### Key Patterns

1. **Callback-driven shell**: `ContentStudioHome` (main navigation) delegates to `ContentStudioScreens` via callbacks (`onCreateReel`, `onContentLibrary`, `onAddNewIdea`, etc.). Screens don't know about each other.
2. **Offline-first persistence**: All data via `JsonFileStore<T>` — generic JSON file store with per-row decoding and safe defaults. Files live in `getApplicationDocumentsDirectory()/content_library/`.
3. **Built-in data + user overrides**: `kDefaultHooks` in `content_ideas.dart` provides 94 built-in ideas (including 6 safety hooks via `...kSafetyHooks` spread, totaling 100 entries). `HookStore` merges user edits from `hooks.json`. Rewrites are embedded inline in `storyDetail` fields; `kRewrittenStories` and `kMomentUpgrades` have been merged into inline fields and deleted.
4. **Two Gemini paths**: Path A (`gemini_call.dart`) — raw HTTP with retry/fallback; Path B (`gemini_client.dart`) — SDK-based, no retry/fallback (see 04_generation.md §5)
5. **Story label parsing**: `StoryGenerator.extractLine()` parses `Story:`, `Twist:`, `Resolution:`, `Moral:` labels (with `PART 1:` fallback).

## Folder Map (lib/)

Full file listing with line counts:

| Lines | File | Purpose |
|-------|------|---------|
| 191 | api_key_store.dart | API key storage abstraction |
| 259 | ai_content_service.dart | AI content orchestration interface |
| 126 | ai_content_service_impl.dart | AI content service implementation |
| 421 | ai_parser_validator.dart | AI response parsing and validation |
| 292 | ai_provider.dart | AI provider configuration |
| 166 | asset_completeness_service.dart | Asset completeness auditing |
| 605 | brand_system.dart | CharacterLibrary, BrandSystem, BucketLibrary, voice/character assets |
| 43 | bucket_group.dart | DEAD CODE — group widget |
| 545 | caption_generator.dart | Instagram caption generator with house format |
| 519 | caption_renderer.dart | Caption rendering engine |
| 250 | characters.dart | Ria, Rio, Cuty, Mumma, Papa, Daadi, Teacher, Robot (8 chars) |
| 491 | content_audit.dart | Content audit helper |
| 548 | content_axes.dart | Enums: ContentBucket, ContentFormat, IdeaStatus, etc. |
| 118 | content_collections.dart | Thematic collection grouping (collectionOf) |
| 531 | content_generator.dart | ContentPackage model + generation engine |
| 2970 | content_ideas.dart | Built-in idea constants (HookIdea, kDefaultHooks, kDay14Posts) |
| 360 | content_library.dart | Persistence model for generated packages |
| 472 | content_library_screen.dart | Content Library browsing UI |
| 593 | content_library_service.dart | Unified read API over all idea sources |
| 744 | content_package_v2.dart | ContentPackage model v2 |
| 2207 | content_quality_gate.dart | Quality check rules and scoring |
| 225 | content_service.dart | Content service abstraction |
| 1427 | content_studio_screens.dart | Main ContentStudioScreens cluster |
| 914 | content_studio_service.dart | Content studio service layer |
| 190 | creator_home.dart | DEAD — unreachable home screen |
| 711 | dashboard_screen.dart | Dashboard with posting metrics (unreachable) |
| 76 | file_storage.dart | File storage for video assets |
| 629 | format_adapter.dart | Package → format-specific output adapter |
| 803 | format_handbook.dart | Format rules and definitions |
| 211 | gemini_call.dart | Primary Gemini HTTP client (Path A, with retry/fallback) |
| 381 | gemini_client.dart | SDK-based Gemini client (Path B, no retry/fallback) — implements AIProvider |
| 198 | gemini_video_master_prompt.dart | Gemini prompt for video planning |
| 346 | home_screen.dart | ContentStudioHome (main navigation shell) |
| 102 | hook_system.dart | Hook system logic |
| 163 | hook_templates.dart | 12 hook templates from Palak's swipe file |
| 430 | idea_input_screen.dart | Idea input screen |
| 614 | idea_review_screen.dart | Idea review screen |
| 154 | json_file_store.dart | Generic JSON persistence base class |
| 5100 | main.dart | App entry point, MaterialApp, routes |
| 57 | master_prompt.dart | Master prompt definitions |
| 70 | music.dart | Background music configuration |
| 207 | add_idea_screen.dart | Custom idea creation form screen |
| 169 | offline_engagement.dart | Offline engagement tracking |
| 763 | offline_story_maker_screen.dart | Offline story maker UI |
| 219 | models/quick_idea.dart | QuickIdea model + stores |
| 227 | package_store.dart | Package storage abstraction |
| 227 | package_store_impl.dart | Package store implementation |
| 384 | plan_data.dart | HookStore, ScheduleStore, PostLogStore, analytics |
| 489 | plan_screen.dart | Plan creation screen |
| 351 | posting_kit.dart | Posting kit bottom sheet |
| 628 | posting_pack.dart | Posting pack creation |
| 140 | production_adapter.dart | Adapter for production output |
| 316 | production_adapter_impl.dart | Production adapter implementation |
| 585 | projects.dart | Project management |
| 140 | project_bridge.dart | Project bridge utility |
| 484 | prompts.dart | Prompt definitions |
| 140 | quality_check.dart | QualityChecker with reach scoring |
| 498 | prompt_builder.dart | Prompt builder utility |
| 886 | prompt_screen.dart | Prompt management screen |
| 268 | prompt_vault.dart | Prompt vault (persistent prompt saving) |
| 810 | prompt_vault_screen.dart | Prompt vault UI |
| 138 | secrets.dart | API key (3 lines — should be in env) |
| 8 | secrets.example.dart | Example secrets file |
| 433 | settings_screen.dart | App settings |
| 714 | shot_planner.dart | Shot planning utility |
| 384 | slide_prompts.dart | Slide prompt generation |
| 286 | story_generator_offline.dart | Offline story generator + screen |
| 802 | story_ideas.dart | Story idea definitions |
| 507 | story_reel_builder.dart | Reel building from story |
| 387 | theme.dart | App theme (colors, text styles) |
| 744 | video_builder.dart | FFmpeg video composition |
| 159 | video_library.dart | Video library model + store |
| 207 | video_library_store.dart | Video library store |
| 138 | video_production_plan.dart | Video production plan model |
| 363 | video_prompt_generator_offline.dart | Offline video prompt generator |
| 456 | voice.dart | Voice/TTS engine selection (phone/gemini/elevenLabs) |

### Key Constants (content_ideas.dart)

- `kDefaultHooks`: 99 built-in HookIdeas (includes `...kSafetyHooks` spread)
- `kSafetyHooks`: 6 safety concepts
- `kDefaultHooksWithRewrite`: alias to `kDefaultHooks` (rewrites merged inline into storyDetail & moment fields, kRewrittenStories/kMomentUpgrades deleted)

## pubspec.yaml Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  image_picker: ^1.1.2      # Image selection
  video_player: ^2.9.2      # Video playback
  flutter_tts: ^4.2.0       # Offline TTS (phone voice engine)
  ffmpeg_kit_flutter_new: ^4.6.2  # FFmpeg video composition
  path_provider: ^2.1.4     # File system access
  http: ^1.2.2             # HTTP client (Gemini, ElevenLabs)
  google_generative_ai: ^0.4.0  # DEPRECATED — real client uses raw http
  shared_preferences: ^2.2.3  # Settings/preferences
  share_plus: ^10.0.0       # Share content

dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^6.0.0
  test: ^1.31.1

# NOTE: uuid was only used by the now-deleted idea_inbox.dart; all IDs are ms timestamps
# NOTE: Two Gemini paths exist: gemini_call.dart (raw http, see 04_generation.md)
#       and gemini_client.dart (google_generative_ai SDK, implements AIProvider)
```

## Data Flow (high level)

```
1. User selects idea from ContentLibraryService
     ↓
2. StoryGenerator.generate() ← HookStore.load()
     ↓ (async, picks random eligible HookIdea)
3. GeneratedStory (title, hook, story beats)
     ↓
4. ContentGenerator → ContentPackage (slides, prompts, captions)
     ↓
5. Media: Gemini TTS/Voice → FFmpeg video build → VideoLibrary
     ↓
6. QualityChecker → QualityReport (score, pass/warn/fail)
     ↓
7. ScheduleStore → PostLogStore (track views/likes/comments)
```

## Test State

- **499 tests pass** (verified via `flutter test`)
- `dart analyze`: no errors, only pre-existing warnings
- APK builds successfully

## Key Design Decisions (from code comments)

1. **API key in header, not query string**: `x-goog-api-key` header used instead of `?key=` to avoid leaking into logs/proxies
2. **Key-in-header + fallback model**: Cost management — small jobs → lighter model
3. **Free-tier per-model limits**: Different models have separate free quotas, so routing is strategic
4. **Missing models cached**: 404s cached for 7 days to avoid retrying
5. **All data on-device**: No cloud sync — app works fully offline after initial install
