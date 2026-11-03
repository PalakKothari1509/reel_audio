# 05 â€” Content Ideas Storage & Grouping

## Overview

Content ideas live in three layers, merged at runtime by `ContentLibraryService` (`lib/content_library_service.dart`):

1. **Built-in ideas from JSON asset** (`assets/data/content_ideas.json`): 117 `HookIdea` records loaded via `rootBundle.loadString()`, parsed with `HookIdea.fromJson()`, validated by `ContentLibraryService._validateJsonHooks()`. JSON is the primary runtime source.
2. **Dart fallback** (`content_ideas.dart`): `kDefaultHooksWithRewrite` (alias to `kDefaultHooks` from `buildDefaultHooks()`) used when JSON loading or validation fails.
3. **User edits** (`HookStore` â†’ `hooks.json`): overrides applied at runtime by ID.
4. **User additions** (`QuickIdeaStore` â†’ `quick_ideas.json`): custom QuickIdeas.
5. **Idea inbox** (`IdeaInboxStore` â†’ `quick_ideas.json`-adjacent): "ideas to write" not yet full posts

The runtime canonical list is `kDefaultHooksWithRewrite` â€” built-ins with rewrites applied inline into `storyDetail` fields.

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

### kDefaultHooks (Dart source)

The master list of all built-in ideas in Dart source code. This serves as the **fallback** when JSON loading fails.

### kDefaultHooksWithRewrite (ALIAS)

`kDefaultHooksWithRewrite` is now a simple alias to `kDefaultHooks` — rewrites and upgrades are embedded inline. User edits are preserved via `HookStore.load()`.

```dart
final kDefaultHooksWithRewrite = kDefaultHooks;
```

This is the **runtime canonical fallback list**. All built-in ideas pass through this alias before being used.

### Built-in Ideas JSON Asset (`assets/data/content_ideas.json`)

**117 built-in HookIdea records** bundled as a runtime asset. Categories:

| Category | Count | ID Pattern |
|----------|-------|------------|
| `Warm lesson` | 16 (incl. 6 safety) | `h01`, `h02`, `h03`, `h04`, `h05`, `h07`, `h08`, `h12`, `h13`, `h16`, `h17`, `h19` + `safety-*` (6) |
| `Relatable` | 46 | `pal*`, descriptive IDs |
| `Struggle first` | 5 | `h09`-`h11`, `h14`-`h15`, `h18` |
| `Surprising` | 5 | `h20`-`h21`, `night-before-annual-day` |
| `Page & milestone` | 8 | `p01`-`p08` |
| `Navratri` | 10 | `navratri-*`, `night-before-annual-day` |
| `Series` | 20 | `robot-01`..`robot-20` |
| `idea_N` series | 117 unique | `idea_1`–`idea_117` |

**Archived built-in ideas:** `idea_41`, `idea_42`, `idea_43`, `idea_44`, `idea_46` (archived flag set to `true`)
**Ordering quirk:** `idea_117` appears at index 78 (zero-based) in the JSON, matching its position in `buildDefaultHooks()`.

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

---

## 4. Content Library Service (content_library_service.dart)

### Unified Read Source

`ContentLibraryService` merges and dedupes by id across:

1. **Built-in ideas from JSON asset** (`assets/data/content_ideas.json`): loaded via `rootBundle.loadString()`, parsed with `HookIdea.fromJson()`, validated by `_validateJsonHooks()` — requires exactly 117 records, unique IDs `idea_1`–`idea_117`, correct ordering (including `idea_117` at index 78), archived set `{idea_41, idea_42, idea_43, idea_44, idea_46}`
2. **Dart fallback** (`kDefaultHooksWithRewrite`): used when JSON loading or validation fails
3. `HookStore` (user-edited hooks): overrides built-ins by ID
4. `kSafetyHooks` (explicit safety category, already in kDefaultHooksWithRewrite via spread)
5. `QuickIdeaStore` (user-added QuickIdeas)
6. `IdeaInboxStore` (user "ideas to write")

### Validation

`_validateJsonHooks()` checks:
- Exactly 117 records
- All IDs unique and present (`idea_1`–`idea_117`)
- Correct ordering (special handling for `idea_117` at index 78)
- Archived set exactly `{idea_41, idea_42, idea_43, idea_44, idea_46}`

### Fallback

If JSON asset is missing, invalid JSON, empty, fails validation, or any exception occurs, `ContentLibraryService` falls back to `kDefaultHooksWithRewrite` from `lib/content_ideas.dart`. The Dart source is **not deleted** and remains available.

### Caching

- JSON hooks cached statically (`_cachedJsonHooks`); first load sets `_jsonLoadAttempted = true`
- Full merged cache with 1-minute TTL (`_cacheTtl`)
- `invalidateCache()` clears the cache; called after any write (add/update/delete)

### Normalized View

Exposes a unified `ContentIdea` view:
```dart
class ContentIdea {
  final String id;
  final String title;        // From cover or opening
  final String category;
  final String collectionId; // From collectionOf()
  final String format;       // From postFormat
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
- Invalidated on writes via `invalidateCache()`
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

`ContentLibraryService._loadAll()` calls `HookStore.load()` to get user-edited built-ins plus custom hooks, then overlays them on the JSON-loaded built-ins by ID:

- Built-ins from JSON are loaded first via `_loadHooksFromJson()`
- `HookStore.load()` returns saved hooks from `hooks.json` merged with `kDefaultHooksWithRewrite`
- For each built-in hook ID, if a saved version exists AND its `storyDetail` differs from the original built-in, the saved (user-edited) version wins
- User-added hooks (`custom: true`) from `hooks.json` are appended
- Built-ins can be **edited** but not deleted via this path
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

---

## 10. Instagram Workflows

The home screen's **Instagram Workflows** entry opens six optional drafts in
`instagram_workflow_screen.dart`: account/per-approved-idea growth planning,
Reels scripts, carousel drafts, caption rewrites, hashtag/keyword maps, and
Stories sequences.

- Approved ideas come from `ContentLibraryService`; category and canonical
  characters are selected in the workflow form.
- Reels call the existing `generateScriptWithGemini` path. Carousel prompts use
  `generateCarouselPrompts`; captions reuse `caption_generator.dart`; growth
  planning and Stories use `instagram_workflow_service.dart`.
- Offline generation is explicit. Stories are text/frame plans only; no
  publishing, rendering, trend lookup, or Instagram analytics API is provided.
- Growth planning uses saved or manually entered metrics as user-recorded
  evidence. Without metrics, the plan identifies recommendations as estimates
  or hypotheses.
- Generated post drafts use the existing quality checker and require exactly
  five unique hashtags before saving. Drafts are editable and stored as
  `ContentLibraryItem` entries with optional `workflowType` and `workflowData`.
  Missing workflow keys in older library JSON remain valid.
