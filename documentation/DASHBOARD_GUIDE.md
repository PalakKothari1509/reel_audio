# Dashboard & Navigation Guide

**Purpose**: Documents the Content Studio Dashboard and main navigation screens.

**Date**: October 13, 2026
**Status**: Current implementation

---

## 1. Overview

The app's primary navigation hub is `ContentStudioHome` in `lib/home_screen.dart`.
From here, users access all content-planning and generation features. The Dashboard
screen (`lib/dashboard_screen.dart`) provides an analytics-style overview of
content by pillar, format, and status.

### Navigation structure

| Destination | File | Purpose |
|---|---|---|
| **Home** | `lib/home_screen.dart` (`ContentStudioHome`) | Pipeline overview, quick actions, reminders, continue where you left off |
| **Idea Vault** | `lib/content_library_screen.dart` | Browse, filter, and manage ideas from the canonical library |
| **Create** | `lib/main.dart` (`StoryScreen`) | Generate a Story Reel from a story brief, with character selection |
| **My Content** | `lib/my_content_screen.dart` | Track production, published content, and performance |
| **Insights** | `lib/insights_screen.dart` | All-time metrics, bucket breakdown, per-item grid |
| **Settings** | `lib/settings_screen.dart` | Brand, API keys, preferences |
| **Dashboard** | `lib/dashboard_screen.dart` | Analytics: ideas by pillar, ready-to-produce, published by format |
| **Plan** | `lib/plan_screen.dart` | Shot planning for cinematic reels |

---

## 2. Home Screen (`ContentStudioHome`)

The Home screen is the single entry point, launched from `main.dart`. It shows:

- **Welcome section** with quick action buttons
- **Pipeline overview**: counts by status (New ideas, In Progress, Ready to create,
  Packages created, Published awaiting metrics)
- **Continue where you left off**: the most recent in-progress story
- **Content reminders**: pending ideas, items awaiting metrics, formats with
  fewer than 5 tests

Navigation cards on Home open: Idea Vault, Create (Reel), My Content, Insights,
Idea Inbox (Promotion Comments), and Settings.

---

## 3. Dashboard Screen

### File: `lib/dashboard_screen.dart`

The Dashboard screen provides a read-only analytics overview. It is accessible from
the Home screen navigation. Shows four sections:

1. **Ideas by pillar** — count of ideas in each of the 5 pillars
2. **Ready to produce** — ideas approved but not yet produced
3. **Published by format** — published packages grouped by content type
4. **Formats tested <5 times** — narrative formats that haven't earned a judgment yet

84 tests in `test/dashboard_screen_test.dart` cover: section headers on loading
completion, refresh behavior, empty states, pillar chips with counts,
ready-to-produce items, and published-by-format display.

---

## 4. Idea Vault / Content Library

### File: `lib/content_library_screen.dart`

Browse all saved content library items. Filter by status, pillar, or search by
title. Each item can be opened to view full details, copy to clipboard, or
remove. The canonical store is `ContentLibraryStore` (extends `JsonFileStore`).

---

## 5. Reel Maker (Create / StoryScreen)

### File: `lib/main.dart` (`StoryScreen`)

The StoryScreen is where new Story Reels are generated. The workflow:

1. **Enter a story description** in the text field
2. **Choose characters** — chip selector defaults to Ria, Rio, Cuty; user can
   add Mumma and Papa. Character IDs are passed as `characterIds` to
   `generateEverything()`
3. **Pick tone, language, and duration** — dropdowns for style (Heartwarming,
   Funny, Educational, Adventure, Problem-Solving), language (Hinglish, English,
   Hindi), and length (20, 30, 45, 60 seconds)
4. **Tap 💡 Idea** to open the hook picker, which includes 10 Navratri hooks
   (N1–N10) under the `'Navratri'` category in `kDefaultHooks`
5. **Generate** — calls `generateEverything()` for scripts ≤10 lines
   (`kCombinedLineLimit`), or falls back to `generateScriptWithGemini()` for
   longer scripts

### Character selection

The chip selector at `lib/main.dart:StoryScreen` allows users to:
- Toggle individual characters in/out of the story
- Default selection: Ria (`ria`), Rio (`rio`), Cuty (`cuty`)
- Additional: Mumma (`mumma`), Papa (`papa`)

Selected IDs are passed to:
- `generateEverything(characterIds: ...)` in `lib/prompt_builder.dart`
- `generateScriptWithGemini(characterIds: ...)` in `lib/main.dart` (fallback)

The prompt builder resolves IDs via `CharacterLibrary.byId()` and includes
only the selected characters in both the `Characters appearing:` line and
the `CharacterLibrary.characterLockFor()` lock block.

### Story Input Screen

### File: `lib/main.dart` (`StoryInputScreen`)

An alternate entry point for Story Reel generation, accessible from some
navigation paths. Uses `FilterChip` widgets for character selection, synced
with `_selectedCharacterIds` state. Same character IDs and defaults as
`StoryScreen`.

---

## 6. Post-Generation

After the script is generated, the flow continues to:

- **TimedScriptScreen** — review and edit the timed script
- **PlanScreen** — plan cinematic shots per scene
- **Image/Voice generation** — scene prompts and narration via Gemini + ElevenLabs
- **FFmpeg rendering** — video assembled and saved to gallery

Scripts autosave as they are typed and edited.

---

## 7. Data stores

| Store | Backing file | Used by |
|---|---|---|
| `ContentLibraryStore` | `content_library.json` | Content Library, Dashboard |
| `PackageStore` | `package_store.json` | Performance tracking, Dashboard |
| `ApiKeyStore` | SharedPreferences | All generation paths |
| `IdeaInboxStore` | `idea_inbox.json` | Idea Vault |
| `QuickHistoryStore` | `quick_history.json` | Quick content history |
| `HookStore` | `hooks.json` | Hook picker in StoryScreen |

All stores extend `JsonFileStore<T>` (`lib/json_file_store.dart`), which
provides consistent load/save, error handling, and a single test seam.

---

## 8. Testing

The dashboard and related screens have comprehensive test coverage:

| Test file | Tests | Coverage |
|---|---|---|
| `test/dashboard_screen_test.dart` | 84 | Section headers, refresh, empty states, pillar chips, ready-to-produce, published by format |
| `test/home_screen_test.dart` | 7 | Welcome, pipeline overview, quick actions, nav cards, reminders |
| `test/insights_screen_test.dart` | 3 | App bar, loading, refresh |
| `test/my_content_screen_test.dart` | 1 | Content list rendering |
| `test/content_library_screen_test.dart` | — | (part of content_service_test) |

Run all tests:
```bash
flutter test
```