# Instagram Strategy → Implementation Plan

**Source**: Based on `documentation/instagram_audit.md`
**Date**: October 12, 2026

---

## Architecture alignment

The existing app already has most infrastructure needed. This plan maps audit requirements to what exists vs what needs to be built.

| Audit requirement | Existing component | New work needed |
|---|---|---|
| Brand profile | `brand_system.dart` (partial) | Add Instagram-specific fields |
| Content audit | `package_store.dart` (PackageStore) | Add audit metadata + CSV import |
| Story Reel Builder | `content_package_v2.dart` (ContentPackageV2) | Add Reel-specific generator |
| Experiment log | (none) | New `ExperimentLog` store |
| Duplication check | `idea_decisions.csv` (partial) | Add content overlap detection |
| Pre-publish gate | `content_quality_gate.dart` (partial) | Add Reel-specific checks |
| Dashboard | (none) | New dashboard screen |
| Data structure | `PackageMetadata` in `package_store.dart` | Extend with audit fields |

---

## Implementation order

### Step 1: Content Audit model ✅ Complete
- **File**: `lib/content_audit.dart`
- `ContentAuditItem` class with fields from section 11.2 of the audit
- `ContentAuditStore` extends `JsonFileStore<ContentAuditItem>`
- `AuditStatus` enum with review/published/flagged states
- `ContentMetrics` with reach, nonFollowerReach, plays, etc.
- 6 tests in `test/content_audit_test.dart`, all passing
- 10 Navratri Reel ideas (N1-N10) added to `documentation/content_ideas.md`

### Step 2: Story Reel Builder (10-second segments) ✅ Complete
- **File**: `lib/story_reel_builder.dart`
- `StoryReelRequest` class: problem, characters, hook, pillar, 10s per segment, 2 segments
- `StoryReelBuilder` class: takes `AIProvider`, generates `ContentPackageV2` with 2 × 10s scenes
- Reel-specific prompt with hook → struggle → solution → takeaway structure
- Uses existing pipeline: `AIProvider.generate(IdeaInput)` → `ContentPackage` → `ContentPackageV2`
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
- 5 tests in `test/home_screen_test.dart`, all passing

### Step 5: My Content screen ✅ Complete
- **File**: `lib/my_content_screen.dart` (`MyContentScreen`)
- Shows all items from the canonical Content Library, grouped by `IdeaStatus`
- Displays bucket, format, posting date, and metric tags per item
- Empty state with helpful guidance
- Wired into navigation from `ContentStudioHome` (replaces the earlier `IdeaInboxScreen` placeholder)
- 1 test in `test/my_content_screen_test.dart`

### Step 6: Insights screen ✅ Complete
- **File**: `lib/insights_screen.dart` (`InsightsScreen`)
- Shows all-time metric totals (reach, impressions, saves, shares)
- Bucket breakdown with item counts and reach per bucket
- Per-item metrics grid for published content
- Empty state for when no content is published
- Wired into navigation from `ContentStudioHome` (replaces the earlier `SavedStoriesScreen` placeholder)
- 1 test in `test/insights_screen_test.dart`

### Step 7: Performance tracking in PackageStore
- **File**: `lib/package_store.dart` (extend `PackageMetadata`)
- Add `metrics` field: reach, nonFollowerReach, plays, watchTimeSeconds, shares, saves, profileVisits, followsAttributed
- Add `experimentCount`, `reviewNotes` fields
- Add methods: `recordMetrics(id, metrics)`, `incrementExperiment(id)`

### Step 4: Duplication detection
- **File**: `lib/duplication_checker.dart` (new)
- Compare new idea against `ContentAuditStore` records
- Check: same problem, same lesson, same hook, overlapping scenes
- Return confidence score: 0.0 (unique) to 1.0 (duplicate)

### Step 5: Pre-publish quality gate (Reel-specific)
- **File**: `lib/content_quality_gate.dart` (extend)
- Add `ReelReadinessCheck` with checks from audit §11.6
- Integrate with `ContentPackageV2.isReadyToGenerate`
- New checks: first-2s hook, sound-off readability, character consistency

### Step 6: Content audit CSV import tool
- **File**: `tool/content_audit.dart` (new)
- Parse `documentation/content_ideas.md` → `content_audit.json`
- Parse Instagram Insights CSV export → `performance_audit.json`
- Merge into unified audit store

### Step 7: Dashboard screen
- **File**: `lib/dashboard_screen.dart` (new)
- Shows: ideas by pillar, ready-to-produce, published by format, formats tested <5 times
- Uses `ContentAuditStore` and `PackageStore`

---

## Implementation constraints

1. **All storage through `JsonFileStore<T>`** — no new file I/O patterns
2. **All enum values canonical** — use `IdeaStatus` from `content_axes.dart`, not local enums
3. **All generation through existing pipeline** — `QualityGate` → `AiContentService` → `AiParserValidator` → `ContentPackageV2`
4. **No new dependencies** — only use packages already in `pubspec.yaml`
5. **Tests with `flutter test`** — match existing test patterns

---

## Navratri reel specifics

The 10 Navratri ideas (N1-N10) in `content_ideas.md` will be the first batch tested through the Story Reel Builder:
- Duration: 20 sec total (two 10-sec segments per Reel)
- Characters: Ria, Rio, Cuty, Mumma, Papa (as specified per idea)
- Format: Reel, Production: Character
- Content Format: Problem → Jugaad → Result → Moral
- Tone: Relatable, Warm, Practical
- Language: Hinglish
