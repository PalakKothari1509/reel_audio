# Dashboard — User Guide & Feature Documentation

**Source**: Based on `documentation/instagram_audit.md` §11.7 and `documentation/INSTAGRAM_STRATEGY_PLAN.md`

**Purpose**: Documents the Content Studio Dashboard — a single-screen hub that gives one-tap access to every content-planning feature.

---

## 1. Overview

The Dashboard is the primary navigation surface for the Content Studio. It presents seven top-level options. Each option opens a dedicated screen with its own sub-menu. Every sub-option performs a concrete, irreversible operation that writes to or reads from the file-backed stores described in §3.

---

## 2. Dashboard Options

| # | Option | Screen opened | Core purpose |
|---|---|---|---|
| 1 | **Content Library** | `lib/dashboard_screens.dart > ContentLibraryScreen` | Browse, filter, and edit all ideas and audit records |
| 2 | **Generate Reel** | `lib/dashboard_screens.dart > GenerateReelScreen` | Build a new Story Reel package from an idea |
| 3 | **Experiment Log** | `lib/dashboard_screens.dart > ExperimentLogScreen` | View, add, and edit performance entries for published content |
| 4 | **Quality Gate** | `lib/dashboard_screens.dart > QualityGateScreen` | Run an idea through the pre-publish gate |
| 5 | **Duplication Check** | `lib/dashboard_screens.dart > DuplicationCheckScreen` | Compare a new idea against the existing library |
| 6 | **Performance Dashboard** | `lib/dashboard_screens.dart > PerformanceDashboardScreen` | Charts and metrics for published content |
| 7 | **Settings** | `lib/dashboard_screens.dart > SettingsScreen` | Brand profile, API keys, preferences |

---

## 3. Option 1 — Content Library

### Screen: `ContentLibraryScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 1.1 | **View All Ideas** | Loads all `ContentIdea` records from `lib/content_library.dart` and renders them as a filterable, sortable list with status badges. |
| 1.2 | **Filter by Pillar** | Filters the list to ideas whose `ClassificationSnapshot.pillar` matches one of the seven canonical values (`PLAY`, `THINK`, `DISCOVER`, `TALK`, `DO`, `RELATE`, `CONVERSATION`). |
| 1.3 | **Filter by Status** | Filters to ideas whose `IdeaStatus` is `idea`, `inProgress`, `ready`, or `archived` (canonical values from `content_axes.dart`). |
| 1.4 | **Filter by Goal** | Filters to ideas whose `ContentGoal` is `reach`, `saves`, `shares`, `comments`, `follows`, etc. |
| 1.5 | **Search** | Full-text search across `title`, `hook`, and `parentProblem` fields. |
| 1.6 | **Add New Idea** | Opens `lib/add_idea_screen.dart`. Creates a new `ContentIdea` in memory and saves it via `ContentLibrary.add()`. |
| 1.7 | **Edit Idea** | Opens `lib/edit_idea_screen.dart`. Loads the idea, allows changing any field, and writes back to `ContentLibrary` via `ContentLibrary.update()`. |
| 1.8 | **Delete Idea** | Shows a confirmation dialog. On confirm, calls `ContentLibrary.delete(id)`. |
| 1.9 | **Export to Audit** | Converts the idea into a `ContentAuditItem` and saves it via `ContentAuditStore.add()`. |
| 1.10 | **Generate from Idea** | Opens `GenerateReelScreen` pre-filled with the selected idea's data. |

---

## 4. Option 2 — Generate Reel

### Screen: `GenerateReelScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 2.1 | **Pick Idea** | Loads `ContentLibrary` records into a dropdown. Defaults to the most-recently-added idea with `IdeaStatus.idea` or `IdeaStatus.inProgress`. |
| 2.2 | **Set Duration** | Dropdown with preset segment durations: `[5s x 4]`, `[10s x 2]`, `[15s x 2]`. Defaults to `[10s x 2]` (20s total). |
| 2.3 | **Choose Characters** | Checkbox list populated from `CharacterLibrary.all`. Defaults to all five: Ria, Rio, Cuty, Mumma, Papa. |
| 2.4 | **Pick Language** | Dropdown: `Hinglish`, `Pure Hindi`, `English`, `Bilingual`. Defaults to `Hinglish`. |
| 2.5 | **Pick Tone** | Dropdown: `relatable`, `warm`, `practical`, `playful`. Defaults to `relatable, warm, practical`. |
| 2.6 | **Generate** | Builds a `StoryReelRequest` and calls `StoryReelBuilder.buildReel(request)`. Displays the resulting `ContentPackageV2` in a read-only preview. |
| 2.7 | **Save Package** | Saves the `ContentPackageV2` via `PackageStore.save(pkg)`. |
| 2.8 | **Export Narration** | Sends the `script` field to voice-generation queue (or clipboard if offline). |
| 2.9 | **Export Visual Prompts** | Copies `imagePrompts` list to clipboard for image-generation tooling. |
| 2.10 | **Regenerate** | Re-runs `StoryReelBuilder.buildReel()` with the same parameters. Does not overwrite the saved package unless "Save" is pressed again. |

---

## 5. Option 3 — Experiment Log

### Screen: `ExperimentLogScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 3.1 | **View Log** | Loads all `ExperimentEntry` records from `ExperimentLogStore` and renders as a table. |
| 3.2 | **Filter by Date** | Filters entries by week, month, or custom range. |
| 3.3 | **Filter by Format** | Filters to entries whose `format` is `carousel`, `reel`, `trialReel`, or `storyReel`. |
| 3.4 | **Filter by Status** | Filters to entries whose `status` is `published`, `scheduled`, `draft`, or `archived`. |
| 3.5 | **Add Entry** | Opens a form. Creates a new `ExperimentEntry` with `experimentCount: 1`, `testNumber: 1`, `testCount: 1`. Saves via `ExperimentLogStore.add()`. |
| 3.6 | **Edit Entry** | Opens the form pre-filled. Updates the record via `ExperimentLogStore.update()`. |
| 3.7 | **Link to Package** | Links the entry to a `ContentPackageV2` by selecting from `PackageStore.loadAll()`. |
| 3.8 | **Record Metrics** | Opens a metrics form. Calls `PackageStore.recordMetrics(packageId, metrics)` with reach, nonFollowerReach, plays, watchTimeSeconds, shares, saves, profileVisits, followsAttributed. |
| 3.9 | **Delete Entry** | Confirmation dialog, then `ExperimentLogStore.delete(id)`. |
| 3.10 | **Export CSV** | Writes all entries to `exports/experiment_log_<timestamp>.csv`. |

---

## 6. Option 4 — Quality Gate

### Screen: `QualityGateScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 4.1 | **Pick Idea** | Loads `ContentLibrary` records. Shows only ideas with `IdeaStatus.idea` or `IdeaStatus.inProgress`. |
| 4.2 | **Run Gate** | Calls `QualityGate.evaluateIdea()` with the idea's `ClassificationSnapshot`. Displays the `GateReport` with pass/fail/unknown verdicts per check. |
| 4.3 | **View Blocking Reasons** | If `GateVerdict.fail`, shows the specific `blockingReasons` list from the report. |
| 4.4 | **Approve Blocked Axes** | Opens a dialog to set axis states from `AxisResolution.suggested`/`needsReview`/`invalid` to `AxisResolution.approved`. Updates the idea's stored classification. |
| 4.5 | **Suggest Next Format** | Calls `FormatLibrary.suggestFormat(idea.classification)` and shows the recommendation. |
| 4.6 | **Mark as Ready** | If all checks pass, sets `IdeaStatus` to `ready` and saves via `ContentLibrary.update()`. |
| 4.7 | **Override and Proceed** | Shows a warning dialog; if confirmed, sets `IdeaStatus` to `ready` regardless of gate verdict. |

---

## 7. Option 5 — Duplication Check

### Screen: `DuplicationCheckScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 5.1 | **Enter New Idea** | Text field for hook + text area for parent problem. Creates a transient `StoryReelRequest`. |
| 5.2 | **Compare Against Library** | Loads all `ContentAuditItem` records from `ContentAuditStore`. Runs `DuplicationChecker.checkOverlap(newRecord, existingRecords)`. |
| 5.3 | **View Results** | Renders a list of potential duplicates with confidence scores (0.0 = unique, 1.0 = near-identical). |
| 5.4 | **Accept — New Angle** | Confidence < 0.3. Saves the new idea to `ContentLibrary`. |
| 5.5 | **Accept — Variation** | 0.3 ≤ confidence < 0.7. Prompts for the angle that differs, then saves. |
| 5.6 | **Reject — Too Similar** | Confidence ≥ 0.7. Discards the new idea and shows the closest match. |
| 5.7 | **Manual Review** | Confidence between 0.5 and 0.8. Flags the idea for human review via `ContentIdea.status = IdeaStatus.needsReview`. |

---

## 8. Option 6 — Performance Dashboard

### Screen: `PerformanceDashboardScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 6.1 | **Select Date Range** | Dropdown: last 7 days, last 30 days, last 90 days, custom range. Loads packages from `PackageStore.query(dateRange: ...)`. |
| 6.2 | **Performance by Format** | Groups packages by `classification.contentType` and renders bar charts of reach, saves, shares, and watch time. |
| 6.3 | **Performance by Idea** | Groups by `ideaId` and lists per-package metrics sorted descending by nonFollowerReach. |
| 6.4 | **Five-Test Rule Tracker** | For each format, shows how many tests have been run vs the minimum of 5. Calls `FiveTestRule.check(format)` and renders the verdict. |
| 6.5 | **Top-Performing Packages** | Loads from `PackageStore` with `PackageQuery.sortBy = 'nonFollowerReach'`, `limit = 10`. |
| 6.6 | **Underperforming Packages** | Same query sorted ascending. Highlights packages with `reach == 0`. |
| 6.7 | **Export Metrics** | Writes a CSV of all queried packages to `exports/performance_<timestamp>.csv`. |
| 6.8 | **Refresh** | Re-reads from disk; clears in-memory cache on all stores. |

---

## 9. Option 7 — Settings

### Screen: `SettingsScreen`

### Sub-options

| # | Sub-option | What it does |
|---|---|---|
| 7.1 | **Brand Name** | Text field, reads/writes `BrandContext.brandName` in `brand_system.dart`'s defaults file. |
| 7.2 | **Handle** | Text field for `@handle`. |
| 7.3 | **Audience** | Dropdown: `preschoolers (1-4)`, `preschoolers (0-5)`, `toddlers (2-4)`. |
| 7.4 | **Tone** | Multi-select tags: `warm`, `playful`, `relatable`, `practical`, `encouraging`, `never preachy`. |
| 7.5 | **Default Characters** | Checkbox list seeded from `CharacterLibrary.all`. Changes update `BrandContext.characters`. |
| 7.6 | **Caption Length Target** | Slider: 500–2200 chars. Stored and enforced by `caption_quality.dart`. |
| 7.7 | **Hashtag Count** | Slider: 3–10. Defaults to 5. Enforced by the quality gate's `hashtagCountCheck`. |
| 7.8 | **API Key** | Shows current key provider. Opens `ApiKeyStore` edit dialog. Calls `hasCustomGeminiKey()` to toggle between custom and default. |
| 7.9 | **Save** | Writes all changes to the brand defaults JSON in `documentation/brand_defaults.json`. |
| 7.10 | **Reset to Defaults** | Confirmation dialog. Restores the original `BrandContext.defaultContext()` values. |

---

## 10. Navigation Flow

```
Dashboard
  │
  ├── 1. Content Library
  │     ├── 1.1 View All  1.6 Add New  1.7 Edit  1.8 Delete
  │     ├── 1.3 Filter by Status  1.4 Filter by Goal
  │     ├── 1.9 Export to Audit  1.10 Generate from Idea
  │     └── 1.5 Search
  │
  ├── 2. Generate Reel
  │     ├── 2.1 Pick Idea  2.2 Set Duration  2.3 Choose Characters
  │     ├── 2.4 Pick Language  2.5 Pick Tone
  │     ├── 2.6 Generate  2.7 Save  2.8 Export Narration
  │     ├── 2.9 Export Visual Prompts  2.10 Regenerate
  │
  ├── 3. Experiment Log
  │     ├── 3.1 View Log  3.2-3.3 Filter (date/format)
  │     ├── 3.5 Add Entry  3.6 Edit Entry  3.7 Link to Package
  │     ├── 3.8 Record Metrics  3.9 Delete Entry  3.10 Export CSV
  │
  ├── 4. Quality Gate
  │     ├── 4.1 Pick Idea  4.2 Run Gate  4.3 View Blocking Reasons
  │     ├── 4.4 Approve Axes  4.5 Suggest Format
  │     ├── 4.6 Mark as Ready  4.7 Override and Proceed
  │
  ├── 5. Duplication Check
  │     ├── 5.1 Enter New Idea  5.2 Compare Against Library
  │     ├── 5.3 View Results
  │     ├── 5.4 Accept (New)  5.5 Accept (Variation)  5.6 Reject
  │     └── 5.7 Manual Review
  │
  ├── 6. Performance Dashboard
  │     ├── 6.1 Date Range  6.2 Chart by Format  6.3 Chart by Idea
  │     ├── 6.4 Five-Test Rule  6.5 Top Packages  6.6 Underperforming
  │     ├── 6.7 Export  6.8 Refresh
  │
  └── 7. Settings
        ├── 7.1 Brand Name  7.2 Handle  7.3 Audience  7.4 Tone
        ├── 7.5 Characters  7.6 Caption Length  7.7 Hashtag Count
        ├── 7.8 API Key  7.9 Save  7.10 Reset to Defaults
```

---

## 11. Data Stores

All dashboard screens read from and write to file-backed stores:

| Store | Backing file | Used by dashboard options |
|---|---|---|
| `ContentLibrary` | `data/content_library.json` | Content Library, Generate Reel, Quality Gate |
| `ContentAuditStore` | `data/content_audit.json` | Content Library, Duplication Check, Performance Dashboard |
| `PackageStore` | `data/package_store.json` | Experiment Log, Performance Dashboard |
| `ExperimentLogStore` | `data/experiment_log.json` | Experiment Log, Performance Dashboard |
| `ApiKeyStore` | SharedPreferences | Settings |

All stores extend `JsonFileStore<T>` and follow the same `loadAll` / `add` / `update` / `delete` contract.

---

## 12. Error Handling

Every dashboard sub-option that writes data returns a `StoreResult<T>`:

- `StoreResult.success(data)` — the record was saved, and `data` contains the stored object (or its ID).
- `StoreResult.failure(failure)` — the write failed, and `failure` is a `StoreFailure` with a human-readable message.
- `StoreResult.info(message)` — non-critical: the operation succeeded but needs the user's attention (e.g., validation warning).

Dashboard screens display `failure.message` in a banner at the top of the screen rather than as a native alert.
