# App Overview: Fun Learning With Palak

## What the app does
A Flutter mobile app that generates Instagram reels and carousel posts for Indian preschool parents.
Stories feature toddlers Ria, Rio, white bunny Cuty, an AI Robot, and adult characters (Mumma, Papa, Daadi, Teacher).

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
- `HookIdea` class: `id`, `category`, `cover`, `opening`, `problem`, `lesson`, `caption`, `pinnedComment`, `forApp`, `storyDetail`
- `kDefaultHooks` — ~140 built-in ideas across categories (Ria & Robot series, Navratri, Daily Life, Skill Building, Safety, etc.)
- `kDefaultHooksWithRewrite` — built-in hooks with rewritten `storyDetail` applied
- `kSafetyHooks` — 6 Kids Safety ideas (safety-good-touch, safety-stranger, safety-road, safety-emergency-number, safety-lost-crowd, safety-kitchen-line)
- Categories in `kContentBuckets` (challenge, conversation, activity, humor, etc.)
- `kRewrittenStories` — map of idea `id` → improved `storyDetail` text in Story/Twist/Resolution/Moral format

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
kMasterPrompt             // Brand rules, audience, visual style
kVisualStyle              // "Soft 3D Pixar-Disney animation style, vertical 9:16..."
kNegativeInstructions     // "No duplicate characters, no identity changes..."
kStoryStructureRules      // Character lock rules
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

## Architecture flow

```
User selects idea from Content Library (kDefaultHooksWithRewrite)
    ↓
If online: content_studio_service.dart → generateImagePrompt/generateCarouselPrompts/generateGeminiVideoPrompts
    ↓
If offline or Gemini fails (429/400/503): content_studio_screens.dart
    ↓
OfflineStoryMakerScreen:
  1. _storyFromHook(hook) → GeneratedStory (uses hook.problem, hook.lesson, hook.storyDetail)
  2. OfflineVideoPromptGenerator.generateFromStory(story, duration, characters)
     → Uses: generateHookText() for overlays, characterDescription() for blocks
     → Uses: kVisualStyle, kNegativeInstructions from master_prompt.dart
  3. OfflineEngagementGenerator.generate(story.moral)
```

## Key design decisions

1. **Single source of truth** — Characters defined in `characters.dart`, prompts in `master_prompt.dart`, ideas in `content_ideas.dart`, collections in `content_collections.dart`
2. **No duplication** — All generators import and reference the shared sources
3. **Rewrite layer** — `kRewrittenStories` and `kSafetyHooks` allow improving scripts without changing the const `kDefaultHooks` list; `HookStore.load()` applies rewrites while preserving user edits
4. **Collection grouping** — Ideas are grouped into 14 thematic collections via `collectionOf()`; the vault groups by `sourceIdeaId`
5. **Automatic offline fallback** — `content_studio_screens.dart` detects Gemini errors (429/400/503) and switches to offline mode
6. **Deterministic offline** — Uses `dart:math` seeded random for reproducible output
7. **Shared UI** — `IdeaInputScreen` used by all online features, with character selection from `kCharacterOptions`

## Key files to modify
- `lib/content_ideas.dart` — Add/edit ideas (HookIdea entries, kRewrittenStories, kSafetyHooks)
- `lib/content_collections.dart` — Add/edit collection mappings
- `lib/characters.dart` — Update character descriptions (kCharacterOptions, kCharacterNames, kCharacterDescriptions)
- `lib/story_generator_offline.dart` — Add/edit story templates
- `lib/master_prompt.dart` — Update brand rules
- `lib/plan_data.dart` — HookStore.load() applies kRewrittenStories
