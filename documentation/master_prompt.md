# Master Prompt & Character System

## Single source of truth for prompts

All content generation (online and offline) uses these constants from `lib/master_prompt.dart`:

```dart
kMasterPrompt       // Brand rules + visual style + audience context
kVisualStyle       // "Soft 3D Pixar-Disney animation style, vertical 9:16..."
kNegativeInstructions  // "No duplicate characters, no identity changes..."
kStoryStructureRules   // Character lock rules (no glasses, Cuty always bunny)
kRequiredPromptSections  // Sections every video prompt must include
```

## Single source of truth for characters

All character definitions live in `lib/characters.dart`:

```dart
kDefaultCast           // 7 CharacterRef objects with assetPath + descriptions
kCharacterOptions      // Id/name/emoji tuples for UI selection
kCharacterNames        // Simple string list: ['Ria', 'Rio', ...]
kCharacterDescriptions // Detailed appearance descriptions for prompt generation
characterDescription(name)  // Lookup function: String -> String
```

### The 7 characters
| Name | Emoji | Key traits |
|---|---|---|
| Ria | 🌸 | Toddler girl, pigtails with pink bows, star dress, no glasses |
| Rio | 💙 | Toddler boy, brown hair, blue-grey outfit, no glasses |
| Cuty | 🐰 | White bunny, coral-pink bow, always upright |
| Mumma | 👩 | Indian mother, yellow kurta, blue jeans |
| Papa | 👨 | Indian father, light blue kurta, friendly |
| Daadi | 👵 | Grandmother, grey hair, glasses, cream saree |
| Teacher | 👩‍🏫 | School teacher, blue kurta, holds book |

## Hook & text system (`lib/hook_system.dart`)

```dart
generateHookText(story, partNumber, totalParts)  // Returns context-aware text overlay
generateOnScreenText(story, partNumber, totalParts, position)  // Returns top/middle/bottom text
```

These functions use the story's `hook`, `problem`, `endingLine`, and `moral` fields
to generate text that is specific to the actual story, not generic templates.

## How generators use these

### Online generation (`content_studio_service.dart`)
- `_brandStyleBlock()` returns `kMasterPrompt + kNegativeInstructions + BrandDefaults info`
- `_characterBlock(characters)` uses `characterDescription(name)` from `characters.dart`

### Offline generation (`offline_story_maker_screen.dart`)
1. User selects a hook from Content Library
2. `_storyFromHook(hook)` creates `GeneratedStory` using hook's `problem`, `lesson`
3. `OfflineVideoPromptGenerator.generateFromStory(story)` produces video prompts using:
   - `generateHookText()` for text overlays
   - `characterDescription()` for character blocks
   - `kVisualStyle`/`kNegativeInstructions` for style consistency

### Engagement (`offline_engagement.dart`)
- `buildOfflineImagePrompt()` uses `kVisualStyle` and `kStoryStructureRules`
