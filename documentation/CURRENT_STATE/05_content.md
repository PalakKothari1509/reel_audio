# 05 â€” Content Ideas Storage & Grouping

## Overview

Content ideas live in three layers, merged at runtime by `ContentLibraryService` (`lib/content_library_service.dart`, 593 lines):

1. **Built-in constants** (`content_ideas.dart`): 98+ built-in `HookIdea` objects
2. **User edits** (`HookStore` â†’ `hooks.json`): overrides applied at runtime
3. **User additions** (`QuickIdeaStore` â†’ `quick_ideas.json`): custom QuickIdeas
4. **Idea inbox** (`IdeaInboxStore` â†’ `quick_ideas.json`-adjacent): "ideas to write" not yet full posts

The runtime canonical list is `kDefaultHooksWithRewrite` â€” built-ins with `kRewrittenStories` applied.

---

## 1. HookIdea Data Model (content_ideas.dart:35)

```dart
class HookIdea {
  final String id;          // Unique identifier
  final String category;    // 'Warm lesson', 'Relatable', 'Struggle first', 'Surprising',
                            //   'Page & milestone', 'Navratri', 'Series'
  final String cover;       // 2-4 word hook title (thumbnail text)
  final String opening;     // First line spoken (first 3 seconds)
  final String problem;     // The real preschool problem
  final String lesson;      // The teaching/learning outcome
  final String postFormat;  // 'Reel', 'Carousel', etc. (default 'Reel')
  final String strategy;    // Pedagogical strategy keywords
  final String caption;     // Instagram caption
  final String pinnedComment;// Top pinned comment
  final bool forApp;        // False = needs screen recordings (not auto-generated)
  final String usedOn;      // Last used date (avoid repeats within a month)
  final bool custom;        // True = user-added (built-ins can be edited, not deleted)
  final String storyDetail; // Full story: Story:/Where:/Twist:/Worse:/Resolution:/Ending:/Moral:
  final String setting;         // Specific location for the moment
  final String sceneDetail;     // Visual details to preserve throughout
  final String dialogue;        // The only spoken line (part 1 only)
  final String mess;            // How the situation gets worse
  final String innerThought;    // Parent voiceover (one line, not lip-synced)
  final String endingBeat;      // The final image to hold
  final bool keepMoralOffScreen;  // Moral not spoken or shown on screen
  final List<String> defaultCast;  // Character list for this story
  // Extra fields:
  final String quote;      // Optional quote text
  final String detail;     // Optional detail text
  final String punchline;  // Optional punchline text
}
```

### Moment Fields

The hook has 8 moment fields that define specific filmed moments instead of abstract narrative:

| Field | Purpose | Video prompt usage |
|-------|---------|-------------------|
| `opening` | First 3 seconds, mid-action | Overlay text (part 1 only) |
| `setting` | Where the moment takes place | SCENE AND SETTING |
| `sceneDetail` | Visual details to preserve | SCENE AND SETTING + keep visible |
| `dialogue` | Only spoken line | DIALOGUE AND AUDIO (part 1 only) |
| `mess` | Situation gets worse | ACTION TIMELINE (beat 2-3) |
| `innerThought` | Parent voiceover | DIALOGUE AND AUDIO (parent VO) |
| `endingBeat` | Final image to hold | ENDING ACTION + closing frame |
| `keepMoralOffScreen` | Moral not spoken/shown | Moral omitted from foundation |

### storyDetail Format

Uses label-based parsing:
```
Story: <problem narrative>
Where: <location>
Twist: <complication>
Worse: <escalation>
Resolution: <solution>
Ending: <final image>
Moral: <lesson>
```

Labels are parsed literally — `Worse:` is the escalation (not aliased to `Resolution:`), and `Ending:` is the final image (not aliased to `Moral:`).

---

## 2. Built-in Constants (content_ideas.dart)

### kDefaultHooks (93 entries)

The master list of all built-in ideas. Categories:

| Category | Count | Description | ID Pattern |
|----------|-------|-------------|------------|
| `Warm lesson` | 13 (incl. 6 safety) | Teaching moments + safety hooks | `h*`, `safety-*` |
| `Relatable` | 35 | Parent/child everyday moments | `h*`, `pal*` |
| `Struggle first` | 6 | Challenge-before-resolution | `h*` |
| `Surprising` | 7 | Unexpected twists | `h*` |
| `Page & milestone` | 8 | Platform milestones | `p01`–`p08` |
| `Navratri` | 10 | Festival posts | `navratri-*`, `night-before-annual-day` |
| `Series` | 20 | Robot series | `robot-01`..`robot-20` |

**Total in kDefaultHooks**: 93 entries.

### kSafetyHooks (6 entries, content_ideas.dart:184-262)

All category: `Warm lesson`. All have `keepMoralOffScreen: false`. Spread into `kDefaultHooks` via `...kSafetyHooks`:

| ID | Opening (Hindi) | Cover (English + Hindi) | Topic |
|----|-----------------|-------------------------|-------|
| `safety-good-touch` | "Uncle bole 'Ek pappi do'... aur Ria ne bola nahi." | "Meri Marzi!" | Good touch / bad touch |
| `safety-stranger` | "Park mein aunty ne chocolate di... Ria ne kya kiya?" | "Chocolate Nahi!" | Stranger danger |
| `safety-road` | "Zebra crossing par Rio ruk gaya... koi nahi bola." | "Ruko, Dekho, Chalo!" | Road safety |
| `safety-emergency-number` | "Ria ko Mumma ka number yaad nahi tha... phir gaana bana." | "Mera Number Gaana" | Emergency numbers |
| `safety-lost-crowd` | "Bheed mein Mumma ka haath chhoot gaya... ab kya?" | "Mela Mein Kho Gayi" | Lost in crowd |
| `safety-kitchen-line` | "Rasoi mein Ria ko aage jaana tha... par ek line thi." | "Laal Line Ke Peeche" | Kitchen safety |

> **Note**: These are inside `kDefaultHooks` via the `...kSafetyHooks` spread — NOT a separate loss bug. Rewrites are now embedded inline in `storyDetail` and moment fields directly.

### kRewrittenStories / kMomentUpgrades (MERGED & DELETED)

**Merged** into inline `storyDetail` and moment fields in `kDefaultHooks` and **deleted**. Previously separate maps that are no longer used.

### kDefaultHooksWithRewrite (ALIAS)

`kDefaultHooksWithRewrite` is now a simple alias to `kDefaultHooks` — rewrites and upgrades are embedded inline. User edits are preserved via `HookStore.load()`.

```dart
final kDefaultHooksWithRewrite = kDefaultHooks;
```

This is the **runtime canonical list**. All built-in ideas pass through this alias before being used.

---

## 4. Content Library Service (content_library_service.dart)

### Unified Read Source

`ContentLibraryService` merges and dedupes by id across:
1. `kDefaultHooksWithRewrite` (built-ins with rewrites)
2. `HookStore` (user-edited hooks)
3. `kSafetyHooks` (explicit safety category)
4. `kDay14Posts` (carousel posts)
5. `QuickIdeaStore` (user-added QuickIdeas)
6. `IdeaInboxStore` (user "ideas to write")

### Normalized View

Exposes a unified `ContentIdea` view:
```dart
class ContentIdea {
  final String id;
  final String title;        // From cover or opening
  final String category;
  final String collectionId; // From collectionOf()
  final ContentFormat format; // From postFormat
  final String problem;
  final String lesson;
  final String storyDetail;
  final String caption;
  final String pinnedComment;
  final String opening;
  final List<String> characterIds; // Extracted from storyDetail
  final IdeaStatus status;
  final SourceType sourceType;     // 'builtin' | 'user_edited' | 'user_added'
  final String sourceIdeaId;
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getAllIdeas()` | Returns all merged ideas |
| `getIdeasByCategory(category)` | Filter by category string |
| `getIdeasByCollection(collectionId)` | Filter by collection |
| `searchIdeas(query)` | Full-text search across all fields |
| `getIdeaById(id)` | Single lookup with caching |
| `addIdea(ContentIdea)` | Add custom idea (only custom ideas can be added) |
| `updateIdea(ContentIdea)` | Update existing idea |
| `deleteIdea(id)` | Delete (only custom ideas) |

### Caching
- 1-minute TTL cache
- Invalidated on writes via `onPlanSaved` callback
   - `HookStore.load()` is async, loads from `hooks.json` + built-ins

---

## 5. HookStore (plan_data.dart)

```dart
class HookStore {
  static Future<List<HookIdea>> load() async {
     // 1. Start with kDefaultHooksWithRewrite (= kDefaultHooks alias)
    // 2. Merge user edits from hooks.json via JsonFileStore
    // 3. User edits take precedence when storyDetail differs
  }
}
```

**File**: `hooks.json`
**Location**: `{appDocsDir}/content_library/hooks.json`

### Merge Logic
- Built-ins can be **edited** but not deleted
- User edits override `storyDetail` only if different from built-in
- User-added hooks are preserved across updates
- Updates that add new built-ins never fight with existing user changes

---

## 6. Collections (content_collections.dart, 117 lines)

### 13 Browse Collections + 'mine'

```dart
const kCollections = <IdeaCollection>[
  IdeaCollection('robot', 'Ria & Robot', 'ðŸ¤–'),
  IdeaCollection('festivals', 'Festivals & Events', 'ðŸª”'),
  IdeaCollection('routines', 'Morning & Bedtime Routines', 'ðŸŒ™'),
  IdeaCollection('food', 'Food & Mealtime', 'ðŸ½ï¸'),
  IdeaCollection('tantrums', 'Tantrums & Big Feelings', 'ðŸ˜¤'),
  IdeaCollection('siblings', 'Siblings & Sharing', 'ðŸ‘«'),
  IdeaCollection('parent', 'Parent Moments', 'ðŸ˜‚'),
  IdeaCollection('warm', 'Warm Lessons', 'â¤ï¸'),
  IdeaCollection('play', 'Play & Learning', 'ðŸ§©'),
  IdeaCollection('guides', 'Parent Guides', 'ðŸ—£ï¸'),
  IdeaCollection('missions', '7 Missions Week', 'ðŸ'),
  IdeaCollection('milestones', 'Milestones & Community', 'ðŸŽ‰'),
  IdeaCollection('safety', 'Kids Safety', 'ðŸ›¡ï¸'),
  IdeaCollection('mine', 'My Ideas', 'âœï¸'),
];
```

### collectionOf() Assignment Rules

```dart
String collectionOf(String id, {bool custom = false}) {
  if (custom) return 'mine';                          // Rule 1: custom â†’ mine
  if (id.startsWith('robot-')) return 'robot';        // Rule 2: robot series
  if (id.startsWith('navratri-') ||                   // Rule 3: festivals
      id == 'night-before-annual-day') return 'festivals';
  if (RegExp(r'^day(1[5-9]|2[0-5])-').hasMatch(id))    // Rule 4: day15-25 â†’ missions
    return 'missions';
  return _collectionById[id] ?? 'mine';               // Rule 5/6: lookup or mine
}
```

### Collection Member Counts (verified from _members map in content_collections.dart)

| Collection | Member Count | Sample Members |
|------------|-------------|----------------|
| **routines** | 12 | h01, h04, h05, h07, h09, h12, pal06, pal07, pal09, pal12, shoe-bandhani, missing-shoe-mystery |
| **food** | 7 | h08, vegetable-drama, plate-patana, broken-biscuit-meltdown, the-snack-reach, day12-dinner-types |
| **tantrums** | 12 | h02, h03, h10, h11, h13, h15, h17, pal03, pal04, pal13, pal14, park-se-nikalna |
| **siblings** | 6 | h06, h14, pal18, toy-sharing, the-toy-car-share, the-block-tower |
| **parent** | 14 | h16, h19, pal01, pal02, pal05, pal08, pal11, pal15, pal16, pal19, dangerous-silence, asmr-cleaning-reel, day3-mumma-says, day7-toddler-math |
| **warm** | 6 | h18, h20, h21, pal10, pal17, pal20 |
| **play** | 5 | day2-which-doesnt-belong, day4-kitchen-challenge, day8-find-cuty, day9-sock-hunt, day13-pattern-game |
| **guides** | 4 | day5-ask-tonight, day6-3year-skills, day10-3-questions, day11-4year-skills |
| **milestones** | 9 | p01â€“p08, day14-favorite-format |
| **safety** | 6 | safety-good-touch, safety-stranger, safety-road, safety-emergency-number, safety-lost-crowd, safety-kitchen-line |
| **robot** | 20 | robot-01..robot-20 (via `id.startsWith('robot-')` rule, not in _members) |
| **festivals** | 11 | navratri-01..navratri-09, navratri-10, night-before-annual-day (via startsWith rule) |
| **missions** | 11 | day15..day25 (via `RegExp(r'^day(1[5-9]2|0-5)-)` rule) |
| **mine** | 0 built-in | Only custom/user-added ideas

---

## 7. QuickIdea Store (models/quick_idea.dart, 218 lines)

### QuickIdea Model (models/quick_idea.dart, 218 lines)

**18 fields** â€” not a simple text/bool model:

```dart
class QuickIdea {
  final String id;             // Unique identifier
  final String title;          // Post title
  final String postType;       // Default 'Carousel'
  final String audience;       // Default 'Indian moms and parents of children aged 1-4'
  final String contentGoal;    // Default 'Build connection'
  final String mood;           // Default 'Relatable'
  final String hook;           // Hook text
  final String mainIdea;       // Core idea
  final String problem;        // Problem statement
  final String lesson;         // Lesson/learning
  final String visualStyle;    // Default 'Bright and playful'
  final String imagePrompt;    // Main image prompt
  final String caption;        // Instagram caption
  final String cta;            // Default 'Save this for later'
  final String hashtags;       // Hashtags
  final List<String> comments; // Promo/reply comments
  final String script;         // Written script
  final List<String> slidePrompts; // One per slide (default: [])
  final DateTime createdAt;    // Creation timestamp
  final String bucket;         // ContentBucket id (default: '')
}
```

All fields default rather than throw â€” a hand-edited or partially written file degrades to a blank idea, not a crash.

### Stores

| Store | File | Purpose | Cap |
|-------|------|---------|-----|
| `QuickIdeaStore` | `quick_ideas.json` | User-added quick ideas | None |
| `QuickHistoryStore` | `quick_post_history.json` | Recently posted ideas | 50 items |
| `IdeaInboxStore` | `quick_ideas.json` (shared/adjacent) | Ideas to write later | None |

### Persistence
All stores use `JsonFileStore<T>` as base, with:
- Per-row decoding (corrupt rows skipped, not fatal)
- `setTestDirectory()` / `clearTestDirectory()` test seams
- Files in `{appDocsDir}/content_library/`

---

## 8. Storage Summary

| Store | JSON File | Model | Read By | Written By |
|-------|-----------|-------|---------|------------|
| `HookStore` | `hooks.json` | `HookIdea` | `StoryGenerator`, `ContentLibraryService` | User edits in app |
| `ContentLibraryStore` | `content_library.json` | `ContentLibraryItem` | `ContentLibraryScreen` | `ContentGenerator` (saved packages) |
| `VideoLibrary` | `video_assets.json` | `VideoAsset` | `VideoLibraryScreen` | After FFmpeg render |
| `QuickIdeaStore` | `quick_ideas.json` | `QuickIdea` | Quick content UI | User additions |
| `QuickHistoryStore` | `quick_post_history.json` | `QuickIdea` | History UI | Posting actions |
| `ScheduleStore` | `schedule.json` | `PostSlot` | `PlanScreen` | User scheduling |
| `PostLogStore` | `posts.json` | `PostRecord` | `DashboardScreen` | Manual + after posting |
| `PromoCommentStore` | `promo_comments.json` | `PromoComment` | Promo tools | User additions |
| `PromptVault` | `saved_prompts.json` | `SavedPrompt` | `PromptVaultScreen` | User saves |
| `PackageStore` | (via JsonFileStore) | `ContentPackage` | ContentStudio | `ContentGenerator` |
| `QualityCheckCenter` | `quality_reports.json` | `QualityReport2` | Quality UI | `QualityChecker` |

---

## 9. Character Extraction

Characters can be inferred from `storyDetail` text by `ContentLibraryService`, or explicitly set via `hook.defaultCast`:

```dart
final characters = extractCharacters(storyDetail);
```

Inferred characters: `Ria`, `Rio`, `Cuty`, `Mumma`, `Papa`, `Daadi`, `Teacher`

`kDefaultCast` in `characters.dart` includes 8 characters (Ria, Rio, Cuty, Robot, Mumma, Papa, Daadi, Teacher).

**Note**: `StoryGenerator._characters` in `story_generator_offline.dart:80` only lists 7 (no Robot). The offline story generator doesn't use the Robot character for general hooks — Robot appears only in the `robot-01`..`robot-20` series where `defaultCast` is set explicitly.

Character descriptions, voice patterns, and speech patterns are available via:
```dart
characterDescription(name)  // Full appearance description
characterVoice(name)        // Voice pattern + example line
speechPattern(name)         // Speech pattern string
```

These match the 8 character image assets in `pubspec.yaml`:
`assets/characters/Ria.jpg` through `assets/characters/Robot.jpg`

