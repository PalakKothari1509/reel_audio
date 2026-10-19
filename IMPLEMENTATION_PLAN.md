# Fun Learning With Palak — Content Production System Implementation Plan

## Current State Summary

- **443 tests passing**, `dart analyze` clean on all modified files
- **Existing persistence**: `JsonFileStore<T>` generic base class in `lib/json_file_store.dart`
- **Existing models**:
  - `HookIdea` (in `content_ideas.dart`) — 117 ideas (93 hooks + 24 posts + 6 safety hooks)
  - `ContentLibraryItem` (in `content_library.dart`) — saved content with `sourceIdeaId`, `qualityReport`, `formatOutputs`, `status`
  - `ContentPackage`, `FormatOutput`, `QualityReport` — supporting models
- **Existing stores**: `HookStore` (plan_data.dart), `ContentLibraryStore` (content_library.dart)
- **8 characters**: Ria, Rio, Cuty, Robot, Mumma, Papa, Daadi, Teacher

---

## Phase 1: Persistent Prompt Vault (Week 1)

**Goal**: Automatically save every generated prompt, with versioning.

### Tasks:
1. **Create `lib/prompt_vault.dart`**
   - `SavedPrompt` class: `id`, `contentId`, `title`, `type` (enum: story, script, character, scene_image, video, voice, caption, quality_check), `promptText`, `version`, `status`, `createdAt`, `updatedAt`, `metadata`
   - `_PromptVaultStore extends JsonFileStore<SavedPrompt>`
   - `PromptVault` static class with: `save()`, `getAll()`, `getByContentId()`, `getByType()`, `getLatestForContent()`

2. **Create `lib/prompt_template.dart`**
   - `PromptTemplate` class: `id`, `name`, `type`, `version`, `templateText`, `isActive`
   - Store the Gemini Video Master Prompt as a template
   - `PromptTemplateRepository` for CRUD

3. **Add tests: `test/prompt_vault_test.dart`**
   - Save and reload prompts
   - Versioning (new version doesn't overwrite old)
   - Filtering by content_id and type

4. **Update `APP_OVERVIEW.md`** — Document Prompt Vault section

### Acceptance:
- [ ] `SavedPrompt` model exists and serializes/deserializes
- [ ] Prompts can be saved and reloaded after app restart
- [ ] Version history is preserved
- [ ] Tests pass

---

## Phase 2: Gemini Video Master Prompt Integration (Week 1-2)

**Goal**: Add the master prompt as a reusable template and wire it into the generation flow.

### Tasks:
1. **Create `lib/gemini_video_master_prompt.dart`**
   - `kGeminiVideoMasterPrompt` — the full template from the spec
   - `VideoPromptVariables` class: `storyTitle`, `storyIdea`, `realLifeProblem`, `learningOutcome`, `selectedCharacters`, `characterDescriptions`, `visualStyle`, `overallTone`, `videoGenerator`
   - `renderVideoMasterPrompt()` function — fills template variables

2. **Create `lib/video_production_plan.dart`**
   - `VideoProductionPlan` class: `contentId`, `templateId`, `cliptPlans` (3x `ClipPlan`), `fullNarration`, `textOverlaySummary`
   - `ClipPlan` class: `contentId`, `partNumber`, `startSecond`, `endSecond`, `purpose`, `visualBeat`, `onScreenText`, `voiceover`, `videoPrompt`
   - Persistence via `JsonFileStore`

3. **Update `content_studio_service.dart`**
   - Add `generateProductionPlan()` that uses the master template
   - Auto-save the plan to Prompt Vault after generation

4. **Update `APP_OVERVIEW.md`** — Document Video Production module

### Acceptance:
- [ ] Master prompt template exists and is versioned
- [ ] `renderVideoMasterPrompt()` produces correct output
- [ ] Production plans are saved automatically
- [ ] Tests pass

---

## Phase 3: Video Library (Week 2-3)

**Goal**: Allow uploading, storing, previewing, and downloading finished videos.

### Tasks:
1. **Create `lib/video_library.dart`**
   - `VideoAsset` class: `id`, `contentId`, `title`, `fileName`, `storagePath`, `fileSizeBytes`, `durationSeconds`, `resolution`, `aspectRatio`, `version`, `status`, `createdAt`, `approvedVersion`
   - `VideoStatus` enum: draft, uploaded, approved, posted, archived
   - `_VideoLibraryStore extends JsonFileStore<VideoAsset>`
   - `VideoLibrary` static class: `uploadVideo()`, `getByContentId()`, `getAll()`, `approveVersion()`, `delete()`

2. **Create `lib/file_storage.dart`**
   - `FileStorageManager` class — manages app documents directory for videos
   - `saveUploadedVideo()`, `getVideoPath()`, `deleteVideo()`

3. **Update `APP_OVERVIEW.md`** — Document Video Library module

### Acceptance:
- [ ] Videos can be uploaded independently of generation
- [ ] Metadata persists after restart
- [ ] Multiple versions per content item are preserved
- [ ] Missing files are handled gracefully
- [ ] Tests pass

---

## Phase 4: Quality Check Center (Week 3-4)

**Goal**: Structured review process for scripts, prompts, and videos with persistent reports.

### Tasks:
1. **Create `lib/quality_check_center.dart`**
   - Extend existing `QualityReport` with `assetVersion`, `assetType`
   - `QualityReportStore extends JsonFileStore<QualityReport>`
   - Three check functions:
     - `checkScript(ContentLibraryItem)` → script quality report
     - `checkPrompt(SavedPrompt)` → prompt quality report  
     - `checkVideo(VideoAsset)` → technical + creative video check

2. **Add quality check criteria** (as defined in the analysis doc)
   - Script: real-life relevance, age suitability, dialogue naturalness, resolution, visual clarity, duration, language
   - Prompt: scene clarity, character presence, consistency, action explicitness, style, format, contradictions, language
   - Video: file readable, duration, orientation, audio, playback, resolution

3. **Update `APP_OVERVIEW.md`** — Document Quality Check Center

### Acceptance:
- [ ] All three checkers are implemented
- [ ] Reports identify exact asset and version
- [ ] Critical/major/minor/suggestion severity levels
- [ ] Old reports remain associated with old versions
- [ ] Tests pass

---

## Phase 5: Complete Content Library UI & Workflow (Week 4-5)

**Goal**: Connect all modules into a unified content management experience.

### Tasks:
1. **Update `lib/content_library_screen.dart`**
   - Add asset completeness indicators (script icon, prompt icon, video icon, quality status)
   - Add filters for: prompt availability, video availability, quality status, posting status
   - Add status badges to each card

2. **Create `lib/video_preview_player.dart`**
   - Video preview widget using existing video player package
   - Download button
   - Quality check action

3. **Update `APP_OVERVIEW.md`** — Document Content Library and workflow

### Acceptance:
- [ ] Each content card shows complete asset status
- [ ] Filtering by asset availability works
- [ ] Video preview works within the app
- [ ] Full workflow test passes

---

## Phase 6: Integration & Testing (Week 5)

**Goal**: Ensure all modules connect correctly and data persists.

### Tasks:
1. Add end-to-end tests for: Create content → generate script → save prompt → upload video → check quality → approve → mark ready to post
2. Test restart persistence
3. Test incomplete workflow (upload fails, earlier assets preserved)
4. Final `APP_OVERVIEW.md` update

### Acceptance:
- [ ] End-to-end workflow test passes
- [ ] All 500+ tests pass
- [ ] `dart analyze` clean
- [ ] `APP_OVERVIEW.md` fully updated

---

## Key Design Principles

1. **No replacement** — Extend existing models and stores
2. **Files separate from metadata** — Videos stored as files, references in JSON
3. **Versions never silently overwrite** — New version = new record
4. **Save before navigating** — Prompts and reports saved immediately after generation
5. **User edits never overwritten** — `HookStore.load()` already preserves user edits
6. **443 existing tests preserved** — No breaking changes to existing functionality
