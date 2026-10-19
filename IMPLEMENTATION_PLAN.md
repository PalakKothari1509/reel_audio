# Fun Learning With Palak — Content Production System Implementation Plan

## Current State Summary

- **483 tests passing**, `dart analyze` clean on all new/modified files (only pre-existing warnings)
- **Existing persistence**: `JsonFileStore<T>` generic base class in `lib/json_file_store.dart`
- **8 characters**: Ria, Rio, Cuty, Robot, Mumma, Papa, Daadi, Teacher

## ✅ Phase 1 Complete: Persistent Prompt Vault

### What was built:
- `lib/prompt_vault.dart` — `SavedPrompt` model, `PromptType`/`PromptStatus` enums, `PromptVault` store with versioning
- `lib/content_studio_screens.dart` — Integrated auto-save of video prompts after generation via `_saveVideoPromptsToVault()` and after part regeneration

### Files created:
- `lib/prompt_vault.dart`
- `test/prompt_vault_test.dart` (7 tests)

### Files modified:
- `lib/content_studio_screens.dart` — Added `_contentIdFromTitle()` and `_saveVideoPromptsToVault()`, imported `prompt_vault.dart`
- `test/home_screen_test.dart` — Added `onPromptVault` callback

## ✅ Phase 2 Complete: Gemini Video Master Prompt Integration

### What was built:
- `lib/gemini_video_master_prompt.dart` — Master prompt template and renderer
- `lib/video_production_plan.dart` — `VideoProductionPlan` and `ClipPlan` models
- `lib/content_studio_service.dart` — Modified `content_studio_service.dart` with text overlay fields and Hinglish language requirements

### Files created:
- `lib/gemini_video_master_prompt.dart`
- `lib/video_production_plan.dart`
- `test/gemini_video_master_prompt_test.dart` (3 tests)
- `test/video_production_plan_test.dart` (4 tests)

### Files modified:
- `lib/content_studio_service.dart` — Added `textOverlay` field to `VideoPartPrompt`, language parameter, Hinglish rules

## ✅ Phase 3 Complete: Video Library

### What was built:
- `lib/video_library.dart` — `VideoAsset` model, `VideoStatus` enum
- `lib/video_library_store.dart` — `VideoLibrary` store with upload, versioning, approval workflows
- `lib/file_storage.dart` — `FileStorageManager` for app-managed video file storage
- `lib/video_library_screen.dart` — UI screen for listing, previewing, uploading videos

### Files created:
- `lib/video_library.dart`
- `lib/video_library_store.dart`
- `lib/file_storage.dart`
- `lib/video_library_screen.dart`
- `test/video_library_test.dart` (6 tests)

### Files modified:
- `lib/file_storage.dart` — Fixed to use `path_provider` properly with test fallback

## ✅ Phase 4 Complete: Quality Check Center

### What was built:
- `lib/quality_check_center.dart` — `QualityReport2`, `QualityFinding`, three checkers (script/prompt/video), severity levels
- Added `contentId` field to `QualityReport2` for content-level lookups
- Added `getByContentId()` method to `QualityCheckCenter`

### Files created:
- `lib/quality_check_center.dart`
- `test/quality_check_center_test.dart` (11 tests)

### Files modified:
- `test/quality_check_center_test.dart` — Updated for new `contentId` field and `checkPrompt` signature

## ✅ Phase 5 Complete: Content Library UI & Workflow Integration

### What was built:
- `lib/prompt_vault_screen.dart` — UI screen for browsing, searching, filtering, copying, and deleting saved prompts
- `lib/asset_completeness_service.dart` — Service that checks which content items have scripts, video prompts, video assets, and quality reports
- Updated `lib/dashboard_screen.dart` — Added Ready-to-Post checklist with completeness status

### Files created:
- `lib/prompt_vault_screen.dart`
- `lib/asset_completeness_service.dart`
- `test/asset_completeness_test.dart` (9 tests)

### Files modified:
- `lib/home_screen.dart` — Added `onPromptVault` and `onVideoLibrary` callbacks and nav cards
- `lib/main.dart` — Wired up navigation for Prompt Vault and Video Library screens
- `lib/dashboard_screen.dart` — Added Ready-to-Post checklist section
- `test/home_screen_test.dart` — Added new callbacks

## ✅ Phase 6 Complete: Integration Testing

### All 483 tests pass (474 original + 9 new)
- `dart analyze` clean on all new files
- Pre-existing warnings only (no new errors)

---

## Key Design Principles

1. **No replacement** — Extended existing models and stores
2. **Files separate from metadata** — Videos stored as files, references in JSON
3. **Versions never silently overwrite** — New version = new record
4. **Save before navigating** — Prompts saved immediately after generation
5. **User edits never overwritten** — `HookStore.load()` preserves edits via `kRewrittenStories`
6. **All 483 tests preserved** — No breaking changes to existing functionality
