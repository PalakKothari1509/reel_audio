# App Overview: Fun Learning With Palak

## What the app does
A Flutter mobile app that generates Instagram reels and carousel posts for Indian preschool parents.
Stories feature toddlers Ria, Rio, white bunny Cuty, and optional adult characters (Mumma, Papa, Daadi, Teacher).

## Core concepts

### 1. Characters (single source: `lib/characters.dart`)
| Name | Emoji | Description |
|---|---|---|
| Ria | 🌸 | Toddler girl, pigtails with pink bows, pink star dress, NO glasses |
| Rio | 💙 | Toddler boy, brown hair, blue-grey outfit, NO glasses |
| Cuty | 🐰 | White bunny, coral-pink bow, always upright |
| Mumma | 👩 | Indian mother, yellow kurta, blue jeans |
| Papa | 👨 | Indian father, light blue kurta |
| Daadi | 👵 | Grandmother, silver bun, glasses, cream saree |
| Teacher | 👩‍🏫 | School teacher, blue kurta, holds book |

Key APIs:
- `kCharacterOptions` — list of `CharOption(id, name, emoji)` for UI
- `kCharacterNames` — `['Ria', 'Rio', ...]` for string-based logic
- `characterDescription(String name)` → returns detailed appearance text for prompts

### 2. Ideas (source: `lib/content_ideas.dart`)
- `HookIdea` class: `id`, `category`, `cover`, `opening`, `problem`, `lesson`, `caption`, `pinnedComment`, `forApp`
- `kDefaultHooks` — ~140 built-in ideas across categories (Navratri, Daily Life, Skill Building, etc.)
- Categories in `kContentBuckets` (challenge, conversation, activity, humor, etc.)

### 3. Prompt System (source: `lib/master_prompt.dart`)
```dart
kMasterPrompt             // Brand rules, audience, visual style
kVisualStyle              // "Soft 3D Pixar-Disney animation style, vertical 9:16..."
kNegativeInstructions     // "No duplicate characters, no identity changes..."
kStoryStructureRules      // Character lock rules
kRequiredPromptSections   // Sections every video prompt must include
```

### 4. Hook/Text System (source: `lib/hook_system.dart`)
- `generateHookText(story, partNumber, totalParts)` — context-aware text overlay per part
- `generateOnScreenText(story, partNumber, totalParts, position)` — top/middle/bottom text

### 5. Story Generation (sources: `lib/story_generator_offline.dart`)
- `StoryGenerator().generate()` — deterministic offline story from 11 templates
- `GeneratedStory` model: `title`, `hook`, `who`, `where`, `problem`, `twist`, `worse`, `solution`, `endingLine`, `moral`, `hookOptions`

### 6. Video Prompt Generation (source: `lib/video_prompt_generator_offline.dart`)
```dart
OfflineVideoPromptGenerator().generateFromStory(
  GeneratedStory story,
  {required int totalSeconds, required List<String> characters},
) → GeminiVideoResult
```
- Returns `GeminiVideoResult` with `storyTitle`, `storyFoundation`, `List<VideoPartPrompt>`
- Each `VideoPartPrompt` = one 10-second part with full prompt text

### 7. Engagement Generation (source: `lib/offline_engagement.dart`)
```dart
OfflineEngagementGenerator().generate(storyMoral: String) → OfflineEngagementPackage
```
- Returns caption, hashtags (5), pinnedComment, suggestedReplies (6), followReason
- `buildOfflineImagePrompt()` and `buildOfflineCarouselSlides()` for other formats

## Architecture flow

```
User selects idea from Content Library (kDefaultHooks)
    ↓
If online: content_studio_service.dart → generateImagePrompt/generateCarouselPrompts/generateGeminiVideoPrompts
    ↓
If offline or Gemini fails (429/400/503): content_studio_screens.dart
    ↓
OfflineStoryMakerScreen:
  1. _storyFromHook(hook) → GeneratedStory (uses hook.problem, hook.lesson)
  2. OfflineVideoPromptGenerator.generateFromStory(story, duration, characters)
     → Uses: generateHookText() for overlays, characterDescription() for blocks
     → Uses: kVisualStyle, kNegativeInstructions from master_prompt.dart
  3. OfflineEngagementGenerator.generate(story.moral)
```

## Key design decisions

1. **Single source of truth** — Characters defined in `characters.dart`, prompts in `master_prompt.dart`, ideas in `content_ideas.dart`
2. **No duplication** — All generators import and reference the shared sources
3. **Automatic offline fallback** — `content_studio_screens.dart` detects Gemini errors and switches to offline mode
4. **Deterministic offline** — Uses `dart:math` seeded random for reproducible output
5. **Shared UI** — `IdeaInputScreen` used by all online features, with character selection from `kCharacterOptions`

## Key files to modify
- `lib/content_ideas.dart` — Add/edit ideas (HookIdea entries)
- `lib/story_generator_offline.dart` — Add/edit story templates
- `lib/master_prompt.dart` — Update brand rules
- `lib/characters.dart` — Update character descriptions
- `lib/hook_system.dart` — Update hook/text generation logic
