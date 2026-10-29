# 07 — Gaps & Notes

## Verified vs. inferred
Per-screen files document **verified** layout/handlers from reading the source. Where a build
delegates to private `_stepBody*` / `_buildStep` helpers that were not fully read, the screen
file marks the step contents as **UNVERIFIED** and notes the handler-level behaviour that was
confirmed (navigation targets, save/merge flow, key state). The TimedScriptScreen file in
particular records the 5-step structure (`kSteps = ['Story','Script','Pictures','Voice','Reel']`)
and the step dispatch (`_stepScript`/`_stepPictures`/`_stepVoice`/`_stepReel`) from the build
skeleton, with step body UI marked UNVERIFIED.

## Two "home" screens
- `ContentStudioHome` (`lib/home_screen.dart`) — the **live** `MaterialApp.home`. All
  ContentStudioHome callbacks were read and documented.
- `HomeScreen` (`lib/main.dart`) — a **legacy** "add voice to an existing video" entry reached
  only from StoryScreen's app-bar "Add voice to a video I already have". It is NOT the app home
  and is not reachable from ContentStudioHome. Both are documented separately.

## Dead / unreachable screens
- `CaptionGeneratorScreen` (`lib/caption_generator.dart`) — **not imported anywhere** in `lib/`.
- `CreatorHomeScreen` (`lib/creator_home.dart`) — replaced by ContentStudioHome; imported only by
  `test/home_screen_test.dart` as a fixture.
Both are documented with reachability = unreachable.

## Reachability of the Quick Content Studio cluster
`QuickContentScreen`, `CarouselMakerScreen`, `SingleImageScreen`, `TrialReelScreen`,
`MultiFormatScreen`, `IdeaInboxScreen`, `QualityCheckScreen`, `PostingPackScreen`, and
`ShotPlannerScreen` live in `quick_content.dart` / standalone files and are **not wired to ContentStudioHome**
(none appear in main.dart or home_screen.dart). They form a parallel "quick content" surface;
`PostingPackScreen` and `ShotPlannerScreen` are referenced only by comments / same-cluster code.
Document each as reachable only within its own cluster (effectively unreachable from the live app shell today).
`PromoCommentVaultScreen` IS now wired via `onPromoComments` in ContentStudioHome.

## ContentStudioScreens cluster — reachable
`ImagePromptScreen`, `CarouselPromptsScreen`, `GeminiVideoScreen` ARE wired (main.dart
onImagePrompt/onCarouselPrompts/onGeminiVideo). `StoryGeneratorScreen` (story_generator_offline.dart)
is standalone and not imported by main.dart (which uses `OfflineStoryMakerScreen` instead).

## Bottom sheets (not separate routes)
`PostingKit` and `ReplyAssistant` are modal bottom sheets (not routes), opened by
`showPostingKit` / `showReplyAssistant`. Documented as their own per-sheet entries rather than
screen routes.

## Navigation conventions (verified)
- Only **one** named route exists: `'/review-idea'` → `ReviewIdeaScreen(ideaId)` (main.dart:471).
- All other navigation is imperative `Navigator.push` + `MaterialPageRoute`.
- `IdeaInboxScreen._generateFromIdea` deliberately does **not** push StoryScreen; it calls the
  caller-provided `onCreateReel` callback because main.dart owns that screen.

## Data / persistence notes (from source comments)
- `PreviewMergedScreen._saveToGallery` uses a `MethodChannel` to write to MediaStore (a prior
  file-copy approach made reels invisible to Instagram).
- `StoryScreen` auto-saves (debounced 1.2s) and reuses a saved script under the same description
  to avoid re-spending a Gemini request.
- `PostingKit` derives the next posting time from `ScheduleStore` rather than Gemini.

## Test-file count
40 test files in `test/` (glob result). README states 412 tests; a function-level grep returns
100+ `test(`/`testWidgets(`/`group(` hits across these files.
