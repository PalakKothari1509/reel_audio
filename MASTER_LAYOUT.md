# MASTER CONTENT LAYOUT

> Fun Learning With Palak Content Studio — Complete Project File Index

## Project Counts
- **Flutter lib files**: 37
- **Dart test files**: 7
- **Dart tool scripts**: 16
- **Markdown documentation**: 9
- **Decision CSVs**: 5
- **Total project files**: ~260 (excluding build artifacts, node_modules, platform dirs)

---

## I. SOURCE OF TRUTH — Content Definitions

### A. Idea Library & Formats
| File | Purpose | Owner |
|------|---------|-------|
| `content_ideas.md` | **Primary source**: 57 content ideas with full metadata (series, pillar, format, hook, beats, share trigger, production notes) | Editorial |
| `content_formats.md` | 16 registered narrative formats with structure and generation rules | Editorial |
| `quick_ideas.json` | Seeded quick idea cards for the app's "Quick Add" feature | Editorial |

### B. Decision Files (Human-Approved Axis States)
| File | Purpose | Owner |
|------|---------|-------|
| `tool/idea_decisions.csv` | Phase D verdicts: 40 KEEP, 8 REWORK, 3 ARCHIVE, 6 DELETE | Editorial |
| `tool/pillar_decisions.csv` | **NOT YET APPROVED** — 14 proposed pillar assignments (6 little-stories, 4 learning-through-play, 2 jugaadu-mummy, 2 little-stories-big-lessons) | Editorial (pending approval) |
| `tool/format_decisions.csv` | **NOT YET APPROVED** — 38 proposed narrative format assignments | Editorial (pending approval) |
| `tool/series_decisions.csv` | Series-level decisions | Editorial |
| `tool/goal_decisions.csv` | Goal assignments per idea | Editorial |
| `tool/production_method_decisions.csv` | Production method assignments | Editorial |

### C. Staged / Deferred Content
| File | Purpose | Owner |
|------|---------|-------|
| `tool/approved_12_reconstruction.md` | 12 new ideas approved in Phase D, status **DEFERRED** (original source unavailable, fresh authoring pass required) | Editorial |

---

## II. FLUTTER APP — `lib/`

### A. Core Framework & Entry Points
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/main.dart` | App entry point, routing, theme setup | Routes, main(), MaterialApp |
| `lib/creator_home.dart` | Dashboard with 8 cards: Ideas, Create Content, Calendar, Analytics, Experiments, Brand, Content Library, Shot Planner | CreatorHomeScreen |
| `lib/quality_check.dart` | **OLD system** — 10 heuristic QualityRule/QualityReport checks (superseded by quality gate) | QualityReport, QualityRule |

### B. Content Model & Taxonomy
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/content_axes.dart` | **THE TAXONOMY** — ContentPillar (4), ContentSeries (7 with fromLegacy/byLabel), ContentType (10), ProductionMethod (4), ContentGoal (8), IdeaStatus (6) | All enums, validateNarrativeFormat() |
| `lib/format_handbook.dart` | **THE FORMAT LIBRARY** — 16 FormatSpec entries with 4-dim scoring, 5-test minimum rule | FormatLibrary (pov, doThisNotThat, mistakesList, problemFix, quickTip, miniStory, questionAnswer, etc.), FormatSpec, FormatLibrary.minimumTests=5 |
| `lib/content_quality_gate.dart` | **NEW** — Phase 2 quality gate engine: VoiceMode (3), SaveValue (3), ShareTrigger (4-field structured), AxisResolution (5), ClassificationSnapshot (frozen state), QualityDimension (4), GateCheckResult, GateReport, QualityGate.evaluateIdea()/evaluatePackage() | QualityGate, GateReport, ShareTrigger, ClassificationSnapshot |
| `lib/content_generator.dart` | ContentPackage, SlideContent, generation pipeline | ContentPackage, SlideContent, GeneratedContent |
| `lib/content_library.dart` | Local content storage and retrieval | ContentLibrary, ContentRecord |
| `lib/content_library_screen.dart` | UI for browsing/saving generated content | ContentLibraryScreen |
| `lib/content_package_v2.dart` | Content package v2 format | ContentPackageV2 |

### C. Content Generation
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/quick_content.dart` | Single-format generation flow (QuickContentScreen) | QuickContentScreen |
| `lib/posting_kit.dart` | Post assembly and scheduling | PostingKit, BrandBlock, CtaBlock |
| `lib/posting_pack.dart` | Post packaging for social sharing | PostingPack |
| `lib/prompt_builder.dart` | Prompt construction for AI generation | PromptBuilder |
| `lib/slide_prompts.dart` | Slide-specific prompt templates | SlidePromptSet |
| `lib/caption_generator.dart` | Caption generation logic | CaptionGenerator |
| `lib/caption_renderer.dart` | Caption rendering pipeline | CaptionRenderer |

### D. Media & Voice
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/voice.dart` | Voice narration, TTS pipeline | VoiceActor, VoiceLine, VoiceNarrationProvider |
| `lib/video_builder.dart` | Video composition and export | VideoBuilder |
| `lib/characters.dart` | Character data (Ria, Rio, Cuty, Mumma, Papa, Daadi, Teacher) | Character, CharacterSet |
| `lib/music.dart` | Music library for sound design | MusicTrack, MusicLibrary |

### E. AI Integration
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/gemini_client.dart` | Gemini API client (configurable thinking budget caps) | GeminiClient |
| `lib/gemini_call.dart` | Single Gemini API call wrapper | geminiCall() |
| `lib/ai_provider.dart` | Abstract AI provider interface | AiProvider |

### F. UI Screens
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/plan_screen.dart` | Content plan/schedule UI | PlanScreen, PlanData |
| `lib/plan_data.dart` | Plan state management | PlanData |
| `lib/prompt_screen.dart` | Prompt review/edit UI | PromptScreen |
| `lib/settings_screen.dart` | App settings | SettingsScreen |
| `lib/reply_assistant.dart` | Quick reply assistant UI | ReplyAssistant |

### G. Brand System (Phase 0 Complete — Brand Tab Ready)
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/brand_system.dart` | Color palette, typography, hashtag sets, CTA options | BrandSystem, BrandColor, CtaOption |
| `lib/theme.dart` | App theme definition | AppTheme |
| `lib/format_adapter.dart` | Format-to-content-type adaptation | FormatAdapter |

### H. Utility
| File | Purpose | Key Exports |
|------|---------|-------------|
| `lib/prompts.dart` | Static prompt templates | Prompts |
| `lib/regenerator.dart` | Regeneration logic for content variations | Regenerator |
| `lib/models/quick_idea.dart` | QuickIdea data model | QuickIdea |

---

## III. TESTS — `test/`

| File | Tests | Purpose |
|------|-------|---------|
| `test/widget_test.dart` | 9 | Widget tests: home screen, delete confirmations, promotion comments, Gemini parser, Hinglish splitting |
| `test/quality_gate_test.dart` | 53 | Quality gate engine: ShareTrigger verdicts, VoiceMode inference, SaveValue, ClassificationSnapshot, evaluateIdea/evaluatePackage, 5-test rule, design invariants |
| `test/five_test_rule_test.dart` | 8 | Format verdict: minimumTests=5, 1/5 insufficient, 5/5 sufficient, all registered formats |
| `test/content_axes_test.dart` | 2 | Content axis parsing: canonical labels, slugged variants, punctuation normalization |
| `test/content_library_test.dart` | 6 | Content library: save/retrieve, JSON round-trip, failure handling |
| `test/content_package_v2_test.dart` | 13 | Content package v2 serialization + gate integration |
| `test/prompt_quality_test.dart` | 6 | Prompt quality: no fixed hashtags, no truncation, Gemini thinking budget caps |
| **TOTAL** | **102** | **All passing** |

---

## IV. TOOL SCRIPTS — `tool/`

### A. Classification & Decision Tools
| File | Purpose |
|------|---------|
| `tool/classify_ideas.dart` | Idea parser (Idea, Section, Comment) and classifier producing Confidence/Proposal |
| `tool/check_axes.dart` | **Axis coverage report** — reads all 5 decision files, reports per-axis coverage (in-source, approved, suggested, OPEN) |
| `tool/check_pillars.dart` | **Pillar regression guard** — verifies no decided idea has a wrong pillar; "a human decision always wins" |
| `tool/check_ideas.dart` | **Idea validation** — validates all 57 ideas against axes, produces needsReview/invalid status per idea |
| `tool/check_formats.dart` | Format validation against registered formats |
| `tool/propose_axes.dart` | Generates axis proposals from idea text |
| `tool/propose_formats.dart` | Generates format proposals from idea text |
| `tool/sync_formats.dart` | Syncs format definitions |

### B. Quality Gate Tools
| File | Purpose |
|------|---------|
| `tool/quality_gate.dart` | **NEW** — Runnable quality gate checker. Evaluates ideas through QualityGate.evaluateIdea(), reports PASS/UNKNOWN/FAIL summary |
| `tool/review_content.dart` | **Pre-install gate** — read-only gate answering "is the library clean enough to sync?" Blocks on: no decision, unresolved axes, UNKNOWN share trigger, duplicate titles |
| `tool/review_sheet.dart` | Generates `tool/review_sheet.md` — human-readable markdown for axis approval |

### C. Analysis & Reporting Tools
| File | Purpose |
|------|---------|
| `tool/reach_mechanics.dart` | Distribution analysis: Pass/Fail/Unknown per mechanic (visual_first, share_trigger, open_loop, etc.) |
| `tool/show_ideas.dart` | Displays ideas in various filtered views |
| `tool/dump_ideas.dart` | Dumps ideas to text for inspection |

### D. Migration State
| File | Purpose |
|------|---------|
| `tool/migration_state.dart` | MigrationState enum (approved/suggested/needsReview/invalid/archiveCandidate) — mirrors AxisResolution in lib/ |

---

## V. ASSETS

| Path | Purpose |
|------|---------|
| `assets/characters/*` | Character images: Cuty, Daadi, Mumma, Papa, Rio, Teacher (+ README) |
| `assets/ideas/Carousel_Post_Ideas.md` | Carousel-specific idea prompts |
| `assets/ideas/Reel_Post_Ideas.md` | Reel-specific idea prompts |
| `assets/ideas/Static_Image_Post_Ideas.md` | Static image idea prompts |
| `assets/ideas/Trial_Reel_Post_Ideas.md` | Trial reel idea prompts |
| `assets/music/README.md` | Music library documentation |
| `captions/shoe_rack_time_chaos.txt` | Sample caption output |

---

## VI. DOCUMENTATION

| File | Purpose | Status |
|------|---------|--------|
| `APP_OVERVIEW.md` | **Master app documentation**: architecture, taxonomy, lifecycle, quality gate, 4-dimension model, share trigger structure | **Updated Phase D** |
| `REDESIGN_PLAN.md` | Revised product plan: pipeline phases, Phase D complete, Phase 1+2 immediate | **Updated Phase D** |
| `REDESIGN_PLAN2.md` | Alternative redesign approach | — |
| `CONTENT_MODEL.md` | Deep-dive into content model, production constraints, reference content | — |
| `POSTS_REVIEW.md` | Post-level review notes | — |
| `MASTER_CONTENT.md` | Content strategy master document | — |
| `master_prompt.md` | Master prompt for AI generation | — |
| `README.md` | Project readme | — |
| `tool/review_sheet.md` | Generated review sheet for axis approval | — |

---

## VII. CONFIGURATION

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Flutter dependencies and asset declarations |
| `pubspec.lock` | Locked dependency versions |
| `analysis_options.yaml` | Dart analyzer configuration |
| `analysis_options.yaml` | Dart analyzer configuration |
| `kilo.json` | Kilo CLI configuration |
| `AGENTS.md` | Agent instructions |
| `.kilo/command/*.md` | Kilo command definitions |
| `.kilo/agent/*.md` | Kilo agent definitions |

---

## VIII. PLATFORM DIRECTORIES

| Directory | Purpose |
|-----------|---------|
| `android/` | Android platform project (Gradle, Manifest, Kotlin MainActivity) |
| `ios/` | iOS platform project (Xcode project, Swift AppDelegate) |
| `web/` | Web platform (index.html, manifest.json, icons) |
| `linux/` | Linux desktop platform (CMake, C++ runner) |
| `windows/` | Windows desktop platform (CMake, C++ runner) |
| `macos/` | macOS desktop platform (Xcode project, Swift) |

---

## IX. PIPELINE — How Data Flows

```
content_ideas.md (57 ideas)
  │
  ▼
Phase D Classification (DONE: 40 KEEP, 8 REWORK, 3 ARCHIVE, 6 DELETE)
  │ → tool/idea_decisions.csv
  │
  ▼
Axis Decisions (PENDING: pillar_decisions.csv, format_decisions.csv)
  │
  ▼
QualityGate.evaluateIdea()  ← lib/content_quality_gate.dart
  ├── Strategy: pillar, series, format, content type (4 checks)
  ├── Creative: share trigger, voice mode (2 checks)
  ├── Production: content type & method implementation (2 checks)
  └── Performance: five-test rule (1 check)
  │
  ▼
If PASS → QuickContentScreen (single-format generation)
  │ → ContentPackage → PostingKit → BrandBlock → VideoBuilder
  │
  ▼
5 tests min → FormatSpec.verdict()
  │
  ▼
Production-incompatible → needsFilming (route to filming plan)
```

---

## X. KEY RULES ENFORCED BY SYSTEMS

| Rule | Enforced Where |
|------|---------------|
| Audience ages 1-4 only (never 2-6 or 3-6) | Manual / BrandBlock |
| One "Create Content" action (no standalone Caption Generator) | main.dart, creator_home.dart |
| Five-test rule: minimum 5 tests to judge a format | FormatLibrary.minimumTests, FormatSpec.verdict(), QualityGate _performanceChecks |
| Share trigger: structured with specific sender/recipient/situation/reason | ShareTrigger class, reach_mechanics.dart |
| Automation proposes; human approves | MigrationState enum, AxisResolution.suggested vs approved |
| 16 registered narrative formats (not 100+) | FormatLibrary.all |
| Content ideas must be decided (keep/rework/archive/delete) | tool/review_content.dart gate |
| little-stories and learning-through-play are OPEN in validator (not a bug) | check_pillars.dart allows, check_axes reports OPEN |
| Production problems ≠ bad ideas | QualityGate: production FAIL → needsFilming, not blocked |
| Classification snapshots preserved at generation time | ClassificationSnapshot class |

---

## XI. FILE INTERACTION MAP

```
lib/content_axes.dart ◄────────── lib/content_quality_gate.dart
   └── 4 enums used by             ├── evaluates ideas/packages
       │                          ├── consumes ContentPillar, ContentSeries, etc.
       ├── lib/quick_content.dart  ├── produces GateReport
       ├── lib/main.dart           └── used by test/quality_gate_test.dart
       ├── lib/creator_home.dart   tool/quality_gate.dart
       ├── lib/content_generator.dart
       └── tool/check_* files
       
lib/format_handbook.dart ◄─────── lib/content_quality_gate.dart
   └── FormatLibrary                  ├── FormatSpec.verdict() (5-test rule)
   └── FormatSpec                      └── validateNarrativeFormat()
       
tool/classify_ideas.dart ◄────────── tool/check_* tools
   ├── parseFile()                     ├── check_pillars.dart (pillar regression)
   ├── Idea/Comment                    ├── check_axes.dart (axis coverage)
   ├── Section                         ├── check_ideas.dart (idea validation)
   └── proposal logic                  └── review_content.dart (pre-install gate)

tool/migration_state.dart ◄────────── lib/content_quality_gate.dart
   └── MigrationState                     └── AxisResolution (mirrors enum)
       
tool/idea_decisions.dart ◄────────── tool/review_content.dart, tool/quality_gate.dart
   ├── IdeaVerdict (keep/rework/archive/delete)
   ├── IdeaDecision
   └── readIdeaDecisions()
       
test/quality_gate_test.dart ◄────── lib/content_quality_gate.dart
   ├── 53 tests covering everything
   └── 102 total tests, all passing
   ├── ShareTrigger, VoiceMode, SaveValue
   ├── ClassificationSnapshot, QualityGate
   └── GateReport JSON serialization

tool/review_sheet.dart ◄──────────── tool/review_sheet.md
   └── generates human-approval markdown
       
assets/ideas/*.md ◄────────────────── lib/content_ideas.dart
   └── idea seed data for QuickAdd
```

---

## XII. STATUS SUMMARY

| Phase | Status | Files |
|-------|--------|-------|
| Phase 0: Brand System | ✅ Complete | brand_system.dart, theme.dart, content_axes.dart |
| Phase D: Idea Classification (57 ideas) | ✅ Complete | content_ideas.md, idea_decisions.csv, check_pillars.dart |
| Phase 1: Single-format generation | ✅ Complete | quick_content.dart, content_generator.dart, content_library.dart |
| Phase 1: Remove Caption Generator | ✅ Complete | main.dart (route removed), creator_home.dart (card removed) |
| Phase 1: Delete confirmations | ✅ Complete | widget_test.dart |
| Phase 2: Quality Gate System | ✅ Complete | content_quality_gate.dart, quality_gate_test.dart (53 tests), quality_gate.dart (tool) |
| Phase 2: review_content.dart integration | ⚠️ Partial | Uses QualityGate but has import issues with `dart run` |
| Phase 2: ContentPackage handoff | ✅ Complete | content_package_v2.dart with GateReport field + fromGateReport() factory, content_package_v2_test.dart (13 tests) |
| 12 Approved New Ideas (Reconstruction) | ⏸️ Deferred | approved_12_reconstruction.md |
