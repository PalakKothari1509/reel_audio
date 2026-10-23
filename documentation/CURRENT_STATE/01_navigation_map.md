# 01 — Navigation Map

Generated from source inspection of `lib/` (verified) and `lib/main.dart` route table
(lines 466–534). Only what is wired in `main.dart`'s `MaterialApp` is "live". Where a
callback or branch is inferred rather than seen, it is marked `UNVERIFIED`.

## App shell

- `MaterialApp.home` = **`ContentStudioHome`** (`lib/home_screen.dart`) — the live home.
- Named routes: exactly one — `'/review-idea'` → `ReviewIdeaScreen` (`lib/review_idea_screen.dart`), argument = idea ID string.
- Everything else is imperative `Navigator.push` with `MaterialPageRoute`.
- There is a separate `CreatorHomeScreen` in `lib/creator_home.dart`, but it is **not**
  the app home and is only referenced by `test/widget_test.dart` (dead/legacy seam).

## Legend

`→` screen opens / pushes · `⇢` bottom sheet / dialog / named route · `★` primary action

## Navigation graph

### ContentStudioHome (lib/home_screen.dart) — app home
AppBar `Settings` → SettingsScreen
- Create → **"Create Content"** → StoryScreen
- "Add New Idea" → AddIdeaScreen (form → ContentLibraryService.addIdea → inbox store)
- Go to → **"Content Library"** → ContentLibraryScreen
- (conditional) "Review All Ideas" → ContentLibraryScreen
- (conditional, null in live wiring) "Video Library" → onManageVideos (UNVERIFIED; not wired)
- (conditional) "Image Generation Prompt" → ImagePromptScreen
- (conditional) "Carousel Generation" → CarouselPromptsScreen
- (conditional) "Gemini Story Video" → GeminiVideoScreen
- (conditional) "Offline Story Generator" → OfflineStoryMakerScreen

### StoryScreen (lib/main.dart) — main reel writer, app entry point for creating
AppBar: `New story` (reset), `Plan` → PlanScreen, `Saved stories` → SavedStoriesScreen, `Add voice to a video I already have` → HomeScreen
Body:
- Idea → _askForIdea (pre-fills description; UNVERIFIED target)
- Check → _checkStory (UNVERIFIED; no push observed)
- Form → _useFormat (UNVERIFIED)
- "Plan cinematic shots" → ShotPlannerScreen
- Write the script / Continue → _generate → _openScript → TimedScriptScreen
- Or write the script myself → _openScript([]) → TimedScriptScreen

### TimedScriptScreen (lib/main.dart) — 4-step wizard: Script → Pictures → Voice → Reel
AppBar: back (pops / steps back) · Paste script icon · Add line icon
- StepBar (backwards only; step 0 = back/pop, step 3 = _checkSavedReel)
- Bottom bar: `Next: <step>` until last step
- Last step:
  - matching reel exists → "Open your reel" → _openReel; "Build it again anyway" → _makeReel
  - no reel → "Make the reel" / "Merging..." → _makeReel
  - Caption & comments button → showPostingKit (PostingKit bottom sheet)
- After build, result opens → PreviewMergedScreen

### PreviewMergedScreen (lib/main.dart) — reel preview
AppBar: play/pause
- Caption & comments → showPostingKit
- Save to gallery / Adjust (pop back)

### SavedStoriesScreen (lib/main.dart)
AppBar: Restore from backup
- "Back up now" in banner
- Tap a story → _openStory bottom sheet:
  - Rename → _rename (in sheet)
  - Open the reel (if file exists) → PreviewMergedScreen
  - Caption & comments (if promptsJson) → showPostingKit
  - Continue working on it → TimedScriptScreen (initialLines, projectId)
  - Picture prompts → PromptScreen
  - Edit the story text → pop(context, project) (returns to caller)
- Delete (per row) → confirmation → delete

### ContentLibraryScreen (lib/content_library_screen.dart)
AppBar: Refresh; FAB "Add New Idea" → AddIdeaScreen (onAddNewIdea wired from main.dart)
- Tap idea row → _IdeaCard actions:
  - Create Content → onCreateContent(idea.id) (null in live wiring)
  - Edit → `Navigator.pushNamed('/review-idea', arguments: idea.id)` → ReviewIdeaScreen
  - Delete → confirm → delete

### ReviewIdeaScreen (lib/review_idea_screen.dart) — the `'/review-idea'` route
- Create Content → widget.onCreateContent?.call() (returns up the stack; UNVERIFIED further nav)
- Back

### IdeaReviewScreen (lib/idea_review_screen.dart) — separate review flow
- Approve (with hook) → onApprove(hook)
- Regenerate Review → onRegenerate()
- Back → onBack()
- Fix buttons (on quality issues) → onRegenerate variants
Not pushed via a route by main.dart itself; it is reached inline by `ImagePromptScreen`,
`CarouselPromptsScreen`, and `GeminiVideoScreen` (all wired from ContentStudioHome), so it IS
reachable in production through the Gemini/idea flow.

### PlanScreen (lib/plan_screen.dart) — tabbed
Tabs: Hooks / When to post (schedule) / Results
- No push navigation observed; in-sheet/tab interactions only.

### ShotPlannerScreen (lib/shot_planner.dart) — from StoryScreen "Plan cinematic shots"
- Build/exports a shot plan to the script; no push observed.

### PromptScreen (lib/prompt_screen.dart) — from TimedScriptScreen & SavedStoriesScreen
- Script → image prompts; Generate → shows prompts (copy). No push observed.

### OfflineStoryMakerScreen (lib/offline_story_maker_screen.dart)
- "Generate Story (No Internet Required)" → runs offline pipeline, results on same screen
  (story, video prompts, engagement package)
- Export/share actions (UNVERIFIED)

### StoryGeneratorScreen (lib/story_generator_offline.dart)
UNVERIFIED whether reachable separately from OfflineStoryMakerScreen. Builds a Scaffold
with Generate → offline story/prompts display.

### SettingsScreen (lib/settings_screen.dart)
- Save Settings (persists to SharedPreferences)
- Export Data / Import Data → "coming soon" snackbar (UNVERIFIED)
- Clear All Local Data → confirm → prefs.clear
- Open Source Licenses

### DashboardScreen (lib/dashboard_screen.dart)
- Refresh button
- Nav cards (UNVERIFIED wiring — not on the live home): Review All Ideas, Create Content, Manage Videos
- Pillar chips → filter; ready-to-produce list; published-by-format; undertested formats
- Not wired into the live home from ContentStudioHome; tested directly but unreachable in production.

---

### quick_content.dart screens
**QuickContentScreen**
- "Generate post pack" → builds a QuickIdea (local, no nav)
- "Generate {Post Type}" → ContentGenerator.generate → PostingPackScreen
  (quality gate dialog on AI-provider path)
- Saved/Post history / 14-Day Test / Bulk paste → modal sheets that load into fields
- Pin/reply comments → copy; "Save idea" → persists

**CarouselMakerScreen** — Generate → local carousel prompts (copy). No nav.
**MultiFormatScreen** — Generate → ContentGenerator.generate → shows results; "Posting Pack" → PostingPackScreen.
**QualityCheckScreen** — auto-fix snackbar; per-check "Fix" buttons → onRegenerate(target, style).
**TrialReelScreen** — Generate → local reel script + 8 shot prompts (copy). No nav.
**SingleImageScreen** — Generate → 7 image prompts (copy). No nav.
**PromoCommentVaultScreen** — Add/Copy/Delete; add/delete use confirm dialogs. No nav.
**IdeaInboxScreen** — +Add idea / Edit / Delete (confirm dialogs); per-idea "Generate" → onCreateReel (callback) or pop.

### posting_pack.dart / posting_kit.dart
**PostingPackScreen** — TabBar over 4 `ContentFormat` tabs (carousel/reel/trialReel/singleImage),
  each a `_FormatTabView` of copy blocks + script + slide prompts + detail cards + Copy/Share/Save.
  AppBar: "Export all as JSON" + "Share all"; Save → `ContentLibraryStore.tryAdd`.
**PostingKit** (`showPostingKit`) — bottom sheet over a saved project's 8 posting fields, with
  copy/alternative-pick/edit; opens `ReplyAssistant` as a nested sheet. Not a pushed route.

### reply_assistant.dart
**ReplyAssistant** (showReplyAssistant) — bottom sheet with reply suggestions. Not a pushed route.

---

## Reachability summary
| Screen | Reachable from live app? | Source |
|---|---|---|
| ContentStudioHome | yes (home) | main.dart:477 |
| StoryScreen | yes | home Create + onCreateContent |
| TimedScriptScreen | yes | StoryScreen / StoryInputScreen / SavedStories |
| PreviewMergedScreen | yes | TimedScriptScreen (last step) / SavedStories "Open the reel" |
| SavedStoriesScreen | yes | StoryScreen Saved stories |
| ContentLibraryScreen | yes | home Content Library |
| ReviewIdeaScreen | yes (named route) | ContentLibraryScreen Edit |
| ImagePromptScreen | yes (conditional) | home Image Generation Prompt |
| CarouselPromptsScreen | yes (conditional) | home Carousel Generation |
| GeminiVideoScreen | yes (conditional) | home Gemini Story Video |
| OfflineStoryMakerScreen | yes (conditional) | home Offline Story Generator |
| AddIdeaScreen | yes | home Add New Idea / ContentLibraryScreen FAB |
| SettingsScreen | yes | home Settings |
| StoryInputScreen | yes (old path) | StoryScreen "add voice" / HomeScreen |
| PlanScreen, ShotPlannerScreen, PromptScreen, PostingPackScreen, PostingKit | yes | StoryScreen / TimedScriptScreen / SavedStories |
| IdeaReviewScreen, PostingPackScreen, PostingKit, ReplyAssistant | yes (via content_studio / TimedScript / SavedStories) | content_studio_screens, posting_pack, posting_kit, reply_assistant |
| DashboardScreen | NO — not wired on home | dashboard_screen.dart |
| CreatorHomeScreen | NO — only test import | creator_home.dart |

---

## Complete Screen Inventory (checklist)

Below is every screen/widget class found during source inspection that builds a `Scaffold`. Verify against your known screens:

### Live (reachable from app home)
1. `ContentStudioHome` (`home_screen.dart`) — app home
2. `StoryScreen` (`main.dart`) — main reel writer
3. `TimedScriptScreen` (`main.dart`) — 4-step wizard
4. `PreviewMergedScreen` (`main.dart`) — reel preview
5. `SavedStoriesScreen` (`main.dart`) — saved stories list
6. `PlanScreen` (`plan_screen.dart`) — tabbed plan screen
7. `ShotPlannerScreen` (`shot_planner.dart`) — shot planning
8. `PromptScreen` (`prompt_screen.dart`) — image prompt generation
9. `PostingPackScreen` (`posting_pack.dart`) — posting pack
10. `SettingsScreen` (`settings_screen.dart`) — app settings
11. `ContentLibraryScreen` (`content_library_screen.dart`) — idea browsing
12. `ReviewIdeaScreen` (`review_idea_screen.dart`) — single idea review (named route `/review-idea`)
13. `AddIdeaScreen` (`add_idea_screen.dart`) — custom idea form
14. `ImagePromptScreen` (`idea_input_screen.dart` or `main.dart`) — image prompt flow
15. `CarouselPromptsScreen` (`story_ideas.dart` or `main.dart`) — carousel generation
16. `GeminiVideoScreen` (`gemini_video_master_prompt.dart`) — Gemini video generation
17. `OfflineStoryMakerScreen` (`offline_story_maker_screen.dart`) — offline pipeline
18. `StoryGeneratorScreen` (`story_generator_offline.dart`) — offline story generator
19. `IdeaReviewScreen` (`idea_review_screen.dart`) — idea review flow
20. `PostingKit` (`posting_kit.dart`) — bottom sheet, not a route
21. `ReplyAssistant` (`reply_assistant.dart`) — bottom sheet, not a route

### Not live / Dead / Test-only
22. `DashboardScreen` (`dashboard_screen.dart`) — not wired into home
23. `CreatorHomeScreen` (`creator_home.dart`) — only test import
24. `CaptionGeneratorScreen` (`caption_generator.dart`) — not pushed by any screen in main.dart
25. `QuickContentScreen` (`quick_content.dart`) — not wired
26. `CarouselMakerScreen` (`quick_content.dart`) — not wired
27. `MultiFormatScreen` (`quick_content.dart`) — not wired
28. `QualityCheckScreen` (`quick_content.dart`) — not wired
29. `TrialReelScreen` (`quick_content.dart`) — not wired
30. `SingleImageScreen` (`quick_content.dart`) — not wired
31. `PromoCommentVaultScreen` (`quick_content.dart`) — not wired
32. `IdeaInboxScreen` (`quick_content.dart`) — not wired
33. `StoryInputScreen` (`main.dart`) — old/alternate path
34. `PromptVaultScreen` (`prompt_vault_screen.dart`) — not wired (if exists)
35. `VideoLibraryScreen` — DEAD (deleted, per audit notes)
36. `InsightsScreen` — DEAD (deleted, per audit notes)

**Total screens found: 36** (21 live/wired + 15 dead/test-only)

> Screens 22-36 may need manual verification — some may have been deleted since the codebase was last audited.
