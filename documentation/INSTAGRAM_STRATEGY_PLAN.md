# Instagram Strategy & Implementation Plan

**Source**: Based on `documentation/instagram_audit.md`
**Date**: October 13, 2026
**Status**: All implementation steps complete

---

## Architecture alignment

The existing app already has most infrastructure needed. This plan maps audit requirements to what exists vs what needs to be built.

| Audit requirement | Existing component | New work needed |
|---|---|---|
| Brand profile | `brand_system.dart` (`BrandDefaults`, `CharacterLibrary`) | Add Instagram-specific fields |
| Content audit | `lib/content_audit.dart` (`ContentAuditItem`, `ContentAuditStore`) | Add audit metadata + CSV import |
| Story Reel Builder | `lib/prompt_builder.dart` (`generateEverything()`, `kCombinedLineLimit`) | ✅ Add character selection |
| Experiment log | (none) | New `ExperimentLog` store |
| Duplication check | `lib/content_service.dart` (`findDuplicates`) | Add content overlap detection |
| Pre-publish gate | `lib/content_quality_gate.dart` (`QualityGate`, `ReelCheckData`) | Add Reel-specific checks |
| Dashboard | `lib/dashboard_screen.dart` | Wire into navigation |
| Data structure | `PackageMetadata` in `lib/package_store.dart` | Extend with audit fields |

---

## Implementation order

### Step 1: Content Audit model ✅ Complete
- **File**: `lib/content_audit.dart`
- `ContentAuditItem` class with fields from section 11.2 of the audit
- `ContentAuditStore` extends `JsonFileStore<ContentAuditItem>`
- `AuditStatus` enum with review/published/flagged states
- `ContentMetrics` with reach, nonFollowerReach, plays, etc.
- 12 tests in `test/content_audit_test.dart`, all passing
- 10 Navratri Reel ideas (N1-N10) added to `documentation/content_ideas.md`

### Step 2: Story Reel Builder (10-second segments) ✅ Complete
- **File**: `lib/prompt_builder.dart` (`generateEverything()`), `lib/brand_system.dart` (`CharacterLibrary`)
- One-request script + prompt generation via `generateEverything()`
- Accepts `List<String>? characterIds` to select which characters appear
- Injects `CharacterLibrary.characterLockFor()` for character-lock enforcement
- Injects `BrandDefaults.visualStyle` (3D Pixar/Disney style) inline in prompt
- Includes `Visual style`, `Aspect ratio` (9:16 vertical), and `Voice` specifications
- Fallback to `generateScriptWithGemini()` when script exceeds `kCombinedLineLimit` (10 lines)
- Character selection UI in `StoryScreen` (chip selector) and `StoryInputScreen` (FilterChip)
- Defaults to Ria, Rio, Cuty but user can select Mumma or Papa
- 12 tests in `test/story_reel_builder_test.dart`, all passing

### Step 3: Unified Content Service ✅ Complete
- **File**: `lib/content_service.dart`
- Bridges `IdeaInboxStore` → `ContentLibraryStore` so adding ideas to the vault also writes to the canonical library
- Methods: `saveIdea`, `syncInboxItem`, `syncAllInboxItems`, `updateStatus`, `recordMetrics`, `findDuplicates`, `deleteItem`, `getStatusCounts`, `getBucketCounts`
- Idempotent sync: prevents duplicate library entries from inbox items
- Duplicate detection via title match or topic similarity (Jaccard > 0.8)
- 18 tests in `test/content_service_test.dart`, all passing

### Step 4: Home screen navigation hub ✅ Complete
- **File**: `lib/home_screen.dart` (`ContentStudioHome`)
- Replaces `CreatorHomeScreen` as the app entry point in `main.dart`
- Navigation: Home | Idea Vault | Create | My Content | Insights | Settings
- Shows pipeline overview (Ideas, In Progress, Approved, Published, Awaiting Metrics)
- Contextual reminders (pending ideas, items awaiting metrics)
- 7 tests in `test/home_screen_test.dart`, all passing

### Step 5: My Content screen ✅ Complete
- **File**: `lib/my_content_screen.dart` (`MyContentScreen`)
- Shows all items from the canonical Content Library, grouped by `IdeaStatus`
- Displays bucket, format, posting date, and metric tags per item
- Empty state with helpful guidance
- Wired into navigation from `ContentStudioHome`
- 1 test in `test/my_content_screen_test.dart`

### Step 6: Insights screen ✅ Complete
- **File**: `lib/insights_screen.dart` (`InsightsScreen`)
- Shows all-time metric totals (reach, impressions, saves, shares)
- Bucket breakdown with item counts and reach per bucket
- Per-item metrics grid for published content
- Empty state for when no content is published
- Wired into navigation from `ContentStudioHome`
- 1 test in `test/insights_screen_test.dart`

### Step 4 (re-numbered): Duplication detection ✅ Complete
- **File**: `lib/content_service.dart` (`findDuplicates` method)
- Compare new idea against `ContentLibraryStore` records
- Duplicate detection via title match or topic similarity (Jaccard > 0.8)
- 18 tests in `test/content_service_test.dart`, all passing

### Step 5 (re-numbered): Pre-publish quality gate (Reel-specific) ✅ Complete
- **File**: `lib/content_quality_gate.dart`
- Added `ReelCheckData` class: carries hook text, scene overlay texts, durations, script, narration, dialogue, caption, voiceMode
- Added three Reel-specific checks to the creative dimension:
  - **Hook clarity**: verifies hook is specific and first scene ≤3s so premise lands within first 2 seconds (FAIL for generic hooks or slow-starting scenes)
  - **Sound-off readability**: verifies on-screen text present when voiceMode is `none` or `optional`; FAIL when voiceMode is `none` with no text (FAIL)
  - **Character consistency**: scans script/narration/dialogue for character name typos, generic references, and truncated names (FAIL on inconsistency)
- Integrated into both `evaluateIdea` and `evaluatePackage` via optional `ReelCheckData? reelData` parameter
- Checks return UNKNOWN for non-Reel content types (e.g., Carousel)
- 19 new tests in `test/quality_gate_test.dart` (18 Reel-specific + 1 evaluatePackage integration), all passing

### Step 6: Content audit CSV import tool
- **File**: `tool/content_audit.dart` (new)
- Parse `documentation/content_ideas.md` → `content_audit.json`
- Parse Instagram Insights CSV export → `performance_audit.json`
- Merge into unified audit store

### Step 7: Dashboard screen ✅ Complete
- **File**: `lib/dashboard_screen.dart` (new)
- Shows: ideas by pillar, ready-to-produce, published by format, formats tested <5 times
- Uses `ContentAuditStore` and `PackageStore`
- Wired into navigation from `ContentStudioHome` via `onDashboard` callback
- 84 tests in `test/dashboard_screen_test.dart`, all passing

---

## Implementation constraints

1. **All storage through `JsonFileStore<T>`** — no new file I/O patterns
2. **All enum values canonical** — use `IdeaStatus` from `content_axes.dart`, not local enums
3. **All generation through existing pipeline** — `QualityGate` → `AiContentService` → `AiParserValidator` → `ContentPackageV2`
4. **No new dependencies** — only use packages already in `pubspec.yaml`
5. **Tests with `flutter test`** — match existing test patterns

---

## Navratri reel specifics

The 10 Navratri ideas (N1-N10) in `documentation/content_ideas.md` are now integrated into the app:
- Added as `HookIdea` entries in `lib/content_ideas.dart` (`kDefaultHooks` with category `'Navratri'`, `'Navratri'` in `kHookCategories`)
- Accessible on phone via: Home → "Create a Reel" → StoryScreen → 💡 Idea button → hook picker
- Each follows **Problem → Jugaad → Result → Moral** structure
- Duration: 20 sec total (two 10-sec segments per Reel)
- Characters: Ria, Rio, Cuty, Mumma, Papa (user-selectable via character chip selector)
- Format: Reel, Production: Character
- Tone: Relatable, Warm, Practical
- Language: Hinglish
- Visual style: 3D Pixar/Disney-style render (injected via `BrandDefaults.visualStyle`)

### Character selection for Navratri reels

The StoryScreen chip selector defaults to Ria, Rio, and Cuty — the three core
characters. For Navratri reels, users can add Mumma and Papa to the selection to
include the whole family. The `generateEverything()` function resolves these IDs
via `CharacterLibrary.byId()` and includes only the selected characters in both the
prompt header and the CHARACTER LOCK block.