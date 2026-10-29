# Content Ideas System

## Adding a new idea

Add to `lib/content_ideas.dart` in the `kDefaultHooks` list:

```dart
HookIdea(
  id: 'idea_N',  // e.g. 'idea_1', 'idea_2', etc. — use the idea_N scheme
  category: 'Category',
  cover: 'Short cover text',
  opening: 'First line spoken',
  problem: 'The relatable preschool problem',
  lesson: 'What children learn from this',
  postFormat: 'Reel',
  strategy: 'Parent relatable hook',
  caption: 'Instagram caption',
  pinnedComment: 'Pinned comment text',
  forApp: true,
  usedOn: '',
),
```

## HookIdea.copyWith()

Every property of `HookIdea` can be safely copied and mutated:

```dart
final updated = hook.copyWith(usedOn: '2026-10-16');
```

## Supported fields: `id`, `category`, `cover`, `opening`, `problem`, `lesson`,
`postFormat`, `strategy`, `caption`, `pinnedComment`, `forApp`, `usedOn`.

## The flow from idea to output

```
User selects idea from Content Library
    → HookIdea loaded
    → OfflineStoryMakerScreen._pickFromLibrary()
    → _storyFromHook(hook) builds GeneratedStory:
        title: hook.cover
        problem: hook.problem
        solution: hook.lesson
        moral: hook.lesson
    → OfflineVideoPromptGenerator.generateFromStory(story)
    → For each 10-second part:
        - generateHookText(story, part, total) → text overlay
        - characterDescription(name) → character block
        - master_prompt.dart constants → style/negative instructions
        - Story beats → action timeline (0-4s/4-8s/8-10s)
    → VideoPartPrompt[] produced
    → OfflineEngagementGenerator.generate() → caption/hashtags/comments
```

## For online generation
Same HookIdea flows through `IdeaInputScreen` → `IdeaReviewScreen` → `content_studio_service.dart`:
- `evaluateIdea()` checks story quality
- `analyzeShareability()` generates shareability analysis
- `generateImagePrompt()` / `generateCarouselPrompts()` / `generateGeminiVideoPrompts()` uses same `_characterBlock()` from `characters.dart`
- Auto-falls back to offline mode if Gemini returns 429/400/503

## Story templates

Offline generation uses deterministic templates from `StoryGenerator._templates` (11 templates):
- 6 original Indian-home stories
- 5 new templates matching shared prompt formats (Toy Car Share, Block Tower,
  Snack Reach, Night Before Annual Day, ASMR Cleaning Reel)

Each `StoryTemplate` has: title, problem, twist, worse, solution, endingLine, moral, where.

## Idea ID scheme

All ideas use the `idea_N` scheme (e.g. `idea_1` through `idea_116`). The first six
(`idea_1`–`idea_6`) are Kids Safety concepts and are also exposed as `kSafetyHooks`.

## Characters in idea selection

When a user selects an idea, they can choose any combination of:
- Ria, Rio, Cuty (default)
- Mumma, Papa, Daadi, Teacher (add as needed)

All 7 characters are available in both `IdeaInputScreen` (online) and `OfflineStoryMakerScreen`.
