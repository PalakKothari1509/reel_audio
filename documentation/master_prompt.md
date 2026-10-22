# Master Prompt & Character System

## Single source of truth for prompts

All content generation (online and offline) uses these constants from `lib/master_prompt.dart`:

```
kMasterPrompt            // Brand rules + visual style + audience context
kVisualStyle            // "Soft 3D Pixar-Disney animation style, vertical 9:16..."
kNegativeInstructions   // NO on-screen text of any kind, character rules, no distortions
kCharacterRules         // Ria/Rio no glasses, Cuty always bunny, etc.
kStoryStructureRules    // Alias for kCharacterRules
kRequiredPromptSections // Sections every video prompt must include
kBannedStoryPhrases     // 12 phrases that make stories read as AI-written
kBannedOverlayPhrases   // 12 phrases banned from overlays/dialogue
kKnownBadTokens         // 8 typos/non-words to avoid
```

### kNegativeInstructions (key rule)

**NO on-screen text of any kind**: no captions, titles, subtitles, speech bubbles,
readable signs, logos or watermarks. Text is added later in the editor.
No closing card, moral, quote or summary at the end.

This is the single most important constraint — the video model must never draw text.

## Single source of truth for characters

All character definitions live in `lib/characters.dart`:

```
kDefaultCast           // 8 CharacterRef objects with assetPath + descriptions
kCharacterOptions      // Id/name/emoji tuples for UI selection
kCharacterNames        // Simple string list: ['Ria', 'Rio', ...]
kCharacterDescriptions // Detailed appearance descriptions for prompt generation
kSpeechPatterns        // Speech pattern strings for all 8 characters
characterDescription(name)   // Lookup function: String -> String
characterVoice(name)      // Returns voice pattern (dialogue + example)
speechPattern(name)       // Returns speech pattern string for a character
```

### The 8 characters
| Name | Emoji | Key traits |
|---|---|---|
| Ria | 🌸 | Toddler girl, pigtails with pink bows, star dress, no glasses |
| Rio | 💙 | Toddler boy, brown hair, blue-grey outfit, no glasses |
| Cuty | 🐰 | White bunny, coral-pink bow, always upright |
| Mumma | 👩 | Indian mother, yellow kurta, blue jeans |
| Papa | 👨 | Indian father, light blue kurta, friendly |
| Daadi | 👵 | Grandmother, grey hair, glasses, cream saree |
| Teacher | 👩‍🏫 | School teacher, blue kurta, holds book |
| Robot | 🤖 | Friendly white-silver robot, teal LED accents, child-height |

## Hook & text system (`lib/hook_system.dart`)

```dart
generateHookText(story, partNumber, totalParts)
    // Part 1 only: returns story.title (short cover, 5-word cap)
    // Parts 2+: returns '' (empty — no overlay)

generateOnScreenText(story, partNumber, totalParts, position)
    // Returns overlay text for OverlayPosition.top/middle/bottom
    // Only top is populated (part 1 cover); middle and bottom are always empty

overlayInstruction(overlay)
    // Formats the ON-SCREEN TEXT OVERLAYS section for the video prompt

overlayProblems(overlay, story)
    // Returns list of issues (too long, contains moral, banned phrases)

OverlayPosition { top, middle, bottom }
    // Replaces TextPosition enum

kMaxOverlayWords = 5
    // Maximum words in any overlay text
kBannedOverlayPhrases
    // 12 phrases that must never appear in overlays
```

### Deterministic overlays

- Overlays are **part 1 only** — the title/cover appears as text on the first part
- The overlay is **never drawn by the video model** — `overlayInstruction()` tells it "Do NOT draw this"
- The editor adds text later via caption_renderer.dart
- No moral, lesson, or summary appears on screen at any point

## How generators use these

### Online generation (`content_studio_service.dart`)
- `_brandStyleBlock()` returns `kMasterPrompt + kNegativeInstructions + BrandDefaults info`
- `_characterBlock(characters)` uses `characterDescription(name)` from `characters.dart`

### Offline generation (`offline_story_maker_screen.dart`)
1. User selects a hook from Content Library
2. `_storyFromHook(hook)` creates `GeneratedStory` using hook's moment fields
   (`opening`, `setting`, `sceneDetail`, `dialogue`, `mess`, `innerThought`,
   `endingBeat`, `defaultCast`) with storyDetail label parsing as fallback
3. `OfflineVideoPromptGenerator.generateFromStory(story)` produces video prompts using:
   - `generateOnScreenText()` / `overlayInstruction()` for text overlays (part 1 only)
   - `characterDescription()` / `characterVoice()` for character blocks
   - `kVisualStyle` / `kNegativeInstructions` for style consistency
   - Beat remapping: `problem` → `twist` → `worse` → `solution`

### Engagement (`offline_engagement.dart`)
- `buildOfflineImagePrompt()` uses `kVisualStyle` and `kStoryStructureRules`
- Moral is omitted when `story.moralHidden` is true

### Story structure (offline, `story_generator_offline.dart`)
- `_loadAvailable()` returns all hooks (moment fields filter removed — all hooks are usable)
- `_buildHook()` uses `hook.opening` deterministically (no random templates)
- `_buildHookOptions()` draws from real moment fields (`dialogue`, `mess`, `endingBeat`, `innerThought`, `sceneDetail`)
