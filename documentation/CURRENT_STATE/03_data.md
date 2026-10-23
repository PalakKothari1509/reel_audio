# Data Architecture & Stores

## Overview

All persistent data in **Fun Learning With Palak** is stored locally on the device as JSON files in the app's documents directory (`getApplicationDocumentsDirectory()`). Video files themselves are stored as separate binary files, keeping metadata and media in separate layers.

A single generic base class, `JsonFileStore<T>`, underpins every store. It provides file-path resolution, test seams, per-row JSON decoding, and consistent error handling. Each domain store extends or delegates to it.

---

## Storage Infrastructure

### JsonFileStore<T> — `lib/json_file_store.dart` (153 lines)

The generic persistence abstraction. Every store in the app builds on this.

**Test seam:**
```dart
@visibleForTesting
static void setTestDirectory(Directory dir)
@visibleForTesting
static void clearTestDirectory()
```
Tests call `setTestDirectory` to redirect all JSON I/O to a temp directory. Production code never sets this.

**Core methods:**

| Method | Description |
|---|---|
| `_file()` | Resolves the file path as `<docs_dir>/<fileName>`; creates the directory if missing |
| `loadAll({shouldKeep})` | Reads the JSON file, decodes each row independently, skips corrupted entries, applies optional `shouldKeep` filter |
| `saveAll(items)` | Encodes all items and writes atomically (`flush: true`); throws `StoreFailure` on error |
| `add(item)` | Loads, inserts at front, saves; swallows exceptions with `debugPrint` |
| `loadById(id)` | Loads all and finds by `idOf(item)` |
| `deleteById(id)` | Loads, removes by `idOf`, saves |

**Key design:** per-row decoding means one corrupted entry never breaks the whole file — it is skipped, not fatal.

**StoreFailure** (`class StoreFailure implements Exception`): thrown on write errors; carries a message and optional cause.

---

## Store Catalog

### 1. Content Library — `lib/content_library.dart` (360 lines)

**JSON file:** `content_library.json`
**Store class:** `ContentLibraryStore` (wraps `_ContentLibraryFileStore extends JsonFileStore<ContentLibraryItem>`)
**Model:** `ContentLibraryItem`

**Model fields:**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Timestamp-based ID (milliseconds since epoch) |
| `title` | `String` | Post title / hook text |
| `topic` | `String` | The idea topic |
| `bucket` | `ContentBucket` | Content bucket/category |
| `format` | `ContentFormat` | carousel, reel, singleImage, trialReel |
| `status` | `IdeaStatus` | idea → scripted → tested → ready → posted → archived |
| `contentPackage` | `ContentPackage?` | The full generated content package |
| `formatOutputs` | `Map<ContentFormat, FormatOutput>` | Per-format adapted outputs |
| `qualityReport` | `QualityReport?` | Cached quality check results (legacy format, rebuilt on load) |
| `tags` | `List<String>` | Tags for searching/filtering |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |
| `postedAt` | `DateTime?` | When posted to Instagram |
| `instagramPostUrl` | `String?` | URL of the Instagram post |
| `performanceMetrics` | `Map<String, dynamic>` | Views, likes, saves, shares (filled manually) |
| `reuseCount` | `int` | How many times this item has been reused |
| `sourceIdeaId` | `String?` | Links back to a `HookIdea.id` in `kDefaultHooks` |

**Methods:**
- `getAll()` — loads all, sorts by `updatedAt` descending
- `getByStatus(IdeaStatus)` — filter by status
- `getByBucket(ContentBucket)` — filter by bucket
- `getByFormat(ContentFormat)` — filter by format
- `getById(String id)` — single item lookup
- `add(item)` — insert at front
- `update(item)` — replace by id, bumps `updatedAt`
- `delete(String id)` — remove by id
- `tryAdd(item)` — safe add returning `bool`
- `updateStatus(id, status)` — status transition with auto `postedAt`
- `markReused(id)` — increments `reuseCount`, sets status to `tested`
- `updateQualityReport(id, report)` — attaches a quality report
- `getStatusCounts()` / `getBucketCounts()` — aggregate stats for dashboard

**Quality report storage (legacy):** The `qualityReport` field stores serialized `QualityResult` entries (rule id/name, passed flag, severity index, message, details). On load, `_reportFromJson` rebuilds a `QualityReport` from the saved data, reusing the item's own `ContentPackage` and `formatOutputs` rather than storing them twice. If the report is corrupted, it is dropped rather than crashing the whole library. Severity enum indices are bounds-checked with `clamp()` to prevent `RangeError` on malformed stored data.

**Note:** This uses the old `QualityReport`/`QualityResult` model from `lib/quality_check.dart`, not the newer `QualityReport2` from `quality_check_center.dart`.

### 2. Prompt Vault — `lib/prompt_vault.dart` (267 lines)

**JSON file:** `saved_prompts.json`
**Store class:** `PromptVault` (wraps `_PromptVaultStore extends JsonFileStore<SavedPrompt>`)
**Model:** `SavedPrompt`

**Model fields:**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Formatted as `{contentId}_{type.name}_v{version}` |
| `contentId` | `String` | Links to `ContentLibraryItem.id` |
| `title` | `String` | Human-readable title |
| `type` | `PromptType` | story, script, character, sceneImage, video, voice, caption, qualityCheck, custom |
| `promptText` | `String` | The full prompt text |
| `version` | `int` | Incrementing version number |
| `status` | `PromptStatus` | draft, saved, approved, archived |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |
| `sourceScriptVersion` | `String?` | Links to a specific script version |
| `metadata` | `Map<String, dynamic>` | Arbitrary key-value metadata |

**Enums:**
- `PromptType` (9 values) with `PromptTypeExtension` for serialization
- `PromptStatus` (4 values) with `PromptStatusExtension`

**Methods:**
- `getAll()` — all prompts, sorted by `updatedAt` descending
- `getByContentId(contentId)` — all prompts for a content item
- `getByType(type)` — all prompts of a type
- `getById(id)` — single prompt by id
- `getLatest(contentId, type)` — highest-version prompt for a content item + type
- `save(prompt)` — replaces all (writes entire list)
- `saveWithVersion(...)` — creates a new version entry (never overwrites old)
- `updateStatus(id, status)` — update a prompt's status
- `delete(id)` — remove by id
- `deleteByContentId(contentId)` — remove all prompts for a content item
- `trySave(prompt)` — safe save returning `bool`

**Versioning:** `saveWithVersion` computes the next version by finding the max existing version for the same `contentId + type` combination, ensuring new versions never overwrite old ones.

### 3. Video Library — `lib/video_library_store.dart` (206 lines) + `lib/video_library.dart` (158 lines)

**JSON file:** `video_assets.json`
**Store class:** `VideoLibrary` (wraps `_VideoAssetStore extends JsonFileStore<VideoAsset>`)
**Model:** `VideoAsset` (defined in `video_library.dart`)

**Model fields:**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Formatted as `{contentId}_v{version}` |
| `contentId` | `String` | Links to `ContentLibraryItem.id` |
| `title` | `String` | Video title |
| `fileName` | `String` | Relative file name in video storage (`{assetId}.mp4`) |
| `fileSizeBytes` | `int?` | File size in bytes |
| `durationSeconds` | `int?` | Duration in seconds |
| `resolution` | `String?` | Resolution string (e.g. "1080x1920") |
| `aspectRatio` | `String` | Default `'9:16'` |
| `version` | `int` | Version number |
| `status` | `VideoStatus` | draft → uploaded → qualityChecked → approved → posted → archived |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |
| `approvedVersionId` | `String?` | Which version is approved (null = self-approved) |
| `qualityReportId` | `String?` | Links to `QualityReport2.id` |
| `uploadedAt` | `DateTime?` | Upload timestamp |
| `postedAt` | `DateTime?` | Posting timestamp |
| `notes` | `String?` | Manual notes from quality review |
| `metadata` | `Map<String, dynamic>` | Arbitrary key-value metadata |

**Enum:** `VideoStatus` (6 values) with `VideoStatusExtension`

**Methods:**
- `getAll()` — all assets, sorted by `updatedAt` descending
- `getByContentId(contentId)` — all versions of a video, sorted by version descending
- `getByStatus(status)` — filter by status
- `getById(id)` — single asset by id
- `getApprovedForContent(contentId)` — highest-version approved asset
- `upload(...)` — creates a new versioned entry with status `uploaded`
- `pickAndUpload(...)` — picks video from gallery, saves file via `FileStorageManager`, creates entry
- `update(asset)` — replace by id
- `updateStatus(id, status)` — status transition
- `approveVersion(id)` — marks one version approved, sets `approvedVersionId` on others
- `markPosted(id)` — sets status to `posted`, sets `postedAt`
- `delete(id)` — deletes file from `FileStorageManager` + removes metadata
- `deleteByContentId(contentId)` — deletes all versions' files + metadata

### 4. File Storage — `lib/file_storage.dart` (75 lines)

**Directory:** `<docs_dir>/video_storage/`
**Class:** `FileStorageManager` (static methods, not a `JsonFileStore`)

**Methods:**

| Method | Description |
|---|---|
| `saveVideo(sourceFile, assetId)` | Copies a file to `<storage_dir>/<assetId>.mp4`, returns the file name |
| `getVideoFile(fileName)` | Returns `File?` for the stored video, or null if missing |
| `deleteVideo(fileName)` | Silently deletes if exists |
| `videoExists(fileName)` | Checks file presence |

**Design:** Files are stored separately from JSON metadata. The `VideoAsset.fileName` field stores the relative path. `FileStorageManager` has its own test seam via `setTestDirectory`/`clearTestDirectory` that also calls `JsonFileStore.setTestDirectory` to keep all stores in sync.

### 5. Hook Store — `lib/plan_data.dart` (383 lines)

**JSON file:** `hooks.json`
**Store class:** `HookStore` (wraps `_HookFileStore extends JsonFileStore<HookIdea>`)
**Model:** `HookIdea` (defined in `lib/content_ideas.dart`)

**Model fields (HookIdea):**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | String slug (e.g. `h01`, `safety-good-touch`) |
| `category` | `String` | Content bucket category |
| `cover` | `String` | Hook cover text |
| `opening` | `String` | Opening line |
| `problem` | `String` | The problem in the story |
| `lesson` | `String` | The lesson/moral |
| `caption` | `String` | Instagram caption |
| `pinnedComment` | `String` | Pinned comment text |
| `forApp` | `bool` | Whether this hook is for the app |
| `storyDetail` | `String` | Full story detail with labels |
| `custom` | `bool` | User-created vs built-in |
| `usedOn` | `String?` | ISO timestamp of last use |

**Methods:**
- `load()` — **The key method.** Merges two layers: (1) built-in hooks from `kDefaultHooks` (which includes `...kSafetyHooks` inline), (2) user edits saved in `hooks.json`. Custom hooks appear at the end.
- `save(hooks)` — writes all hooks to file
- `markUsed(id)` — updates `usedOn` timestamp

**Rewrite logic:** Rewrites are now embedded inline in `storyDetail` fields directly — `kRewrittenStories` and `kMomentUpgrades` have been merged into the `storyDetail` and moment fields of `kDefaultHooks` and deleted. If a built-in hook's `storyDetail` in the saved file differs from the original built-in value, user edits are preserved.

**Backup integration:** `onPlanSaved` callback fires after any save — triggers Downloads backup.

### 6. Schedule Store — `lib/plan_data.dart`

**JSON file:** `schedule.json`
**Store class:** `ScheduleStore` (wraps `_ScheduleFileStore extends JsonFileStore<PostSlot>`)
**Model:** `PostSlot` (weekday: 1-7, first: "13:30", backup: "20:45", focus: topic)

**Methods:**
- `load()` — returns `kDefaultSchedule` (7 slots) if file doesn't have exactly 7 entries
- `save(slots)` — writes all slots

**Utilities:** `nextPostingTime()` returns human-readable next posting time ("Today 8:45 PM"). `formatClock()` converts "20:45" to "8:45 PM".

### 7. Post Log Store — `lib/plan_data.dart`

**JSON file:** `posts.json`
**Store class:** `PostLogStore` (wraps `_PostLogFileStore extends JsonFileStore<PostRecord>`)
**Model:** `PostRecord` (id, title, projectId, hookId, bucket, postedAt, views, likes, comments, saves, shares)

**Methods:**
- `load()` — all posts, sorted by `postedAt` descending
- `save(posts)` — writes all
- `add(post)` — prepend to list

**Migration:** `PostRecord.fromJson` applies `migrateBucketId()` on read, converting old bucket ids (`puzzle` → `challenge`, `talk` → `conversation`, `skill` → `age_practice`, `wrap` → `community`).

**Analytics helpers:** `resultsByTime()` and `resultsByBucket()` compute average views/saves/comments/shares per time-of-day or per content bucket from posts with non-zero results.

### 8. Promo Comment Store — `lib/quick_content.dart`

**JSON file:** `promo_comments.json`
**Store class:** `PromoCommentStore` (wraps `_PromoCommentFileStore extends JsonFileStore<PromoComment>`)
**Model:** `PromoComment` (text, bucket)

**Behavior:** Falls back to 55 built-in `starterComments` if the file is absent or unreadable. Comments are keyed by text (not a unique ID), since starter comments have no stable identifier.

**Methods:**
- `loadWithBuckets()` — loads as `PromoComment` objects with bucket tags, falls back to starters
- `load()` — backward-compatible plain string list
- `add(comment)` — prepend and save
- `delete(text)` — remove by text and save
- `save(comments)` — write all

### 9. Quick Idea Store — `lib/models/quick_idea.dart` (218 lines)

**JSON file:** `quick_ideas.json`
**Store class:** `QuickIdeaStore` (wraps `_QuickIdeaFileStore extends JsonFileStore<QuickIdea>`)
**Model:** `QuickIdea`

**Model fields:**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Timestamp-based ID |
| `title` | `String` | Post title |
| `postType` | `String` | Carousel, Reel, Static Image, Story |
| `audience` | `String` | Target audience |
| `contentGoal` | `String` | Content goal |
| `mood` | `String` | Mood/emotion |
| `hook` | `String` | Hook text |
| `mainIdea` | `String` | Main idea text |
| `problem` | `String` | Problem text |
| `lesson` | `String` | Lesson text |
| `visualStyle` | `String` | Visual style description |
| `imagePrompt` | `String` | Image generation prompt |
| `caption` | `String` | Instagram caption |
| `cta` | `String` | Call-to-action |
| `hashtags` | `String` | Hashtags |
| `comments` | `List<String>` | Reply comments |
| `script` | `String` | Script text |
| `slidePrompts` | `List<String>` | Per-slide prompts |
| `createdAt` | `DateTime` | Creation timestamp |
| `bucket` | `String` | Content bucket |

**Methods:** `load()`, `getById(id)`, `saveAll(ideas)`, `add(idea)`, `delete(id)`

**Error handling:** `decodeIdeas()` decodes each row independently; `QuickIdea.fromJson` never throws — all fields default.

### 10. Quick History Store — `lib/models/quick_idea.dart`

**JSON file:** `quick_post_history.json`
**Store class:** `QuickHistoryStore` (wraps `_QuickHistoryFileStore extends JsonFileStore<QuickIdea>`)
**Capacity:** Capped at 50 items (`maxItems = 50`)

**Methods:** `load()`, `add(idea)` — prepends and trims to `maxItems`

### 11. Quality Check Center — `lib/quality_check_center.dart` (538 lines)

**JSON file:** `quality_reports.json`
**Store class:** `QualityCheckCenter` (wraps `_QualityReportStore extends JsonFileStore<QualityReport2>`)
**Model:** `QualityReport2`

**Model fields (QualityReport2):**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Report ID |
| `contentId` | `String` | Links to `ContentLibraryItem.id` |
| `assetId` | `String` | Links to `VideoAsset.id` (for video) or content ID (for script) |
| `assetType` | `QualityCheckType` | script, prompt, video |
| `assetVersion` | `int` | Version of the asset at check time |
| `checkedAt` | `DateTime` | When the check ran |
| `findings` | `List<QualityFinding>` | All individual findings |
| `manualNotes` | `String?` | Manual review notes |
| `requiresHumanReview` | `bool` | Whether any finding failed |

**Model fields (QualityFinding):**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Finding ID |
| `checkId` | `String` | Rule identifier |
| `checkName` | `String` | Human-readable rule name |
| `severity` | `FindingSeverity` | critical, major, minor, suggestion |
| `passed` | `bool` | Whether the check passed |
| `message` | `String` | Result message |
| `suggestion` | `String?` | Fix suggestion if failed |

**Enums:**
- `FindingSeverity` (critical, major, minor, suggestion) with `FindingSeverityExtension`
- `QualityCheckType` (script, prompt, video) with `QualityCheckTypeExtension`

**Store methods:**
- `getAll()` — all reports, sorted by `checkedAt` descending
- `getByAsset(assetId)` — reports for a specific asset
- `getByContentId(contentId)` — reports for a content item
- `getById(id)` — single report
- `save(report)` — insert or replace by id
- `delete(id)` — remove by id

**Checkers:**
- `checkScript({contentId, version, title, scriptText})` — checks real-life relevance, age appropriateness, Hinglish dialogue, clear resolution
- `checkPrompt({contentId, assetId, version, promptText, expectedCharacters})` — checks characters present, duration specified, format specified, negative instructions
- `checkVideo({asset, filePath})` — async checks: file readable, file size (>100KB), duration (25-35s), aspect ratio (9:16)

**Summary getters:** `passCount`, `criticalCount`, `majorCount`, `minorCount`, `suggestionCount`, `hasCriticalIssues`, `hasMajorIssues`, `canApprove`, `overallStatus` (FAIL / NEEDS REVISION / PASS WITH NOTES / PASS)

---

## Two Quality Systems

The app has two quality-checking systems:

| Aspect | Old (`quality_check.dart`) | New (`quality_check_center.dart`) |
|---|---|---|
| Model | `QualityReport` + `QualityResult` | `QualityReport2` + `QualityFinding` |
| Severity enum | `QualitySeverity` (pass, warn, fail) | `FindingSeverity` (critical, major, minor, suggestion) |
| Check type | Single `check(pkg, formats)` → inline results | `checkScript()` / `checkPrompt()` / `checkVideo()` → `QualityReport2` |
| Persistence | Embedded in `ContentLibraryItem.qualityReport` (rebuilt on load) | Stored in `quality_reports.json` via `QualityCheckCenter` |
| Rules | 35 rules covering hook/slides/caption/hashtags/comments/script/brand/reach | 4 checks per checker (script: 4, prompt: 4, video: 4) |
| Status flow | `failCount == 0` → ready | `canApprove` = no critical + no major issues |

`ContentLibraryItem` still uses the old `QualityReport` as a cached field, while `QualityCheckCenter` produces and persists the new `QualityReport2` reports independently.

---

## Cross-Store Relationships

```
HookIdea (hooks.json)
  id: slug (e.g. "h01", "safety-good-touch")
    │ referenced by
    ▼
ContentLibraryItem (content_library.json)
  id: timestamp string
  sourceIdeaId → HookIdea.id
  qualityReport: QualityReport (legacy, cached inline)
    │
    ├── referenced by → SavedPrompt (saved_prompts.json)
    │     contentId → ContentLibraryItem.id
    │
    ├── referenced by → VideoAsset (video_assets.json)
    │     contentId → ContentLibraryItem.id
    │     qualityReportId → QualityReport2.id
    │
    └── referenced by → QualityReport2 (quality_reports.json)
          contentId → ContentLibraryItem.id
          assetId → VideoAsset.id (for video checks)

PostRecord (posts.json)
  id: timestamp string
  hookId → HookIdea.id
  bucket → ContentBucket.id
```

### ID Schemes

| Model | ID format | File |
|---|---|---|
| `ContentLibraryItem` | Timestamp (milliseconds since epoch as string) | `content_library.json` |
| `SavedPrompt` | `{contentId}_{type.name}_v{version}` | `saved_prompts.json` |
| `VideoAsset` | `{contentId}_v{version}` | `video_assets.json` |
| `HookIdea` | String slug (e.g. `h01`, `safety-road`) | `hooks.json` |
| `QuickIdea` | Timestamp (milliseconds since epoch as string) | `quick_ideas.json` |
| `PostRecord` | Timestamp (milliseconds since epoch as string) | `posts.json` |
| `QualityReport2` | `{contentId}_script_report_{timestamp}` or `{assetId}_*_report_{timestamp}` | `quality_reports.json` |

**Audit finding (Q8):** The ID schemes are intentionally different per domain. `contentId` fields in `SavedPrompt`, `VideoAsset`, and `QualityReport2` all reference the `ContentLibraryItem.id` (timestamp). `QualityReport2.assetId` references `VideoAsset.id` for video checks, or `ContentLibraryItem.id` for script/prompt checks.

### Versioning

Both `SavedPrompt` and `VideoAsset` use a versioning scheme where new versions are appended, never overwriting:
- `SavedPrompt`: `saveWithVersion()` creates `{contentId}_{type.name}_v{nextVersion}`
- `VideoAsset`: `upload()` / `pickAndUpload()` creates `{contentId}_v{nextVersion}`

`VideoLibrary.approveVersion()` sets `approvedVersionId` on all sibling versions, pointing to the newly approved one. `getApprovedForContent()` returns the highest-version approved asset.

### Error Resilience

Every store has the same error resilience pattern:
1. **Per-row decoding** — `JsonFileStore.loadAll()` decodes each JSON array element independently; a corrupted row is skipped with `debugPrint`, not fatal
2. **Safe defaults** — Model `fromJson` methods use `as String? ?? ''` and `DateTime.tryParse(...) ?? DateTime.now()` to never throw on missing/bad data
3. **Graceful fallback** — `PromoCommentStore` falls back to starter comments; `ScheduleStore` falls back to `kDefaultSchedule` if the file doesn't have exactly 7 entries; `ContentLibraryItem._reportFromJson` returns null for a corrupted report
4. **Try-pattern methods** — `tryAdd()` and `trySave()` return `bool` instead of throwing for UI-safe error handling

---

## Test Seams

| Store | Test directory method |
|---|---|
| `JsonFileStore` (base) | `setTestDirectory(Directory)` / `clearTestDirectory()` |
| `ContentLibraryStore` | `useDirectory(Directory)` / `resetDirectory()` |
| `PromptVault` | `useDirectory(Directory)` / `resetDirectory()` |
| `VideoLibrary` | `useDirectory(Directory)` / `resetDirectory()` |
| `QualityCheckCenter` | `useDirectory(Directory)` / `resetDirectory()` |
| `FileStorageManager` | `setTestDirectory(Directory)` / `clearTestDirectory()` (also sets `JsonFileStore` test dir) |
| `QuickIdeaStore` & `QuickHistoryStore` | `JsonFileStore.setTestDirectory` (via `HookStore.useDirectory`) |
| `PromoCommentStore` | `JsonFileStore.setTestDirectory` |

All test seams set the same `JsonFileStore._testDirectory`, so a single call redirects all stores simultaneously.

---

## JSON File Inventory

| File name | Store | Model | Records kept |
|---|---|---|---|
| `content_library.json` | `ContentLibraryStore` | `ContentLibraryItem` | All content packages with status, metrics |
| `saved_prompts.json` | `PromptVault` | `SavedPrompt` | Versioned prompts, never overwrites |
| `video_assets.json` | `VideoLibrary` | `VideoAsset` | Versioned video metadata |
| `hooks.json` | `HookStore` | `HookIdea` | User-edited hooks + custom hooks |
| `schedule.json` | `ScheduleStore` | `PostSlot` | 7 posting time slots |
| `posts.json` | `PostLogStore` | `PostRecord` | Posted content with performance |
| `promo_comments.json` | `PromoCommentStore` | `PromoComment` | Custom promo comments |
| `quick_ideas.json` | `QuickIdeaStore` | `QuickIdea` | Saved quick content ideas |
| `quick_post_history.json` | `QuickHistoryStore` | `QuickIdea` | Last 50 generated ideas |
| `quality_reports.json` | `QualityCheckCenter` | `QualityReport2` | Quality check reports |

All files are stored in `getApplicationDocumentsDirectory()`. Video files are stored in `<docs_dir>/video_storage/` separately from their JSON metadata.

---

## Asset Completeness Service — `lib/asset_completeness_service.dart`

Cross-store aggregation service that checks whether content items have all required assets.

**JSON file:** (uses existing stores, no own file)

**Model:** `AssetCompleteness` — `contentId`, `hasScript`, `hasVideoPrompt`, `hasVideoAsset`, `hasQualityReport`, `missing` (list), `isReadyToPost` (bool)

**Methods:**
- `checkContentId(contentId)` — checks one item across all stores
- `checkAll()` — checks all items in `ContentLibraryStore`
- `getMissing()` — returns items missing assets (drives the Dashboard Ready-to-Post checklist)

**Integration:** The dashboard calls `getMissing()` to show items that need attention — e.g., content that has a script but no video asset or quality report.
