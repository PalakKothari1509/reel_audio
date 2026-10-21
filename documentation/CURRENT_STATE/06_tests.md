# 06 — Tests

Inventory of the 40 test files in `test/`. `flutter test` reports 499 tests passing
(verified by running `flutter test`).

## Coverage map

### App shell & screens (widget tests)
| File | Focus | Notes |
|------|-------|-------|
| `home_screen_test.dart` | ContentStudioHome shell | Imports `CreatorHomeScreen` as a fixture; tests callback wiring. |
| `dashboard_screen_test.dart` | DashboardScreen | Dashboard is not wired to the live home. |
| `my_content_screen_test.dart` | MyContentScreen | Reachable screen widget test. |
| `idea_review_screen_test.dart` | IdeaReviewScreen | Approval-gate / hook selection rendering. |
| `offline_story_maker_test.dart` | OfflineStoryMakerScreen | Offline story + engagement + video-result pipeline. |
| `widget_test.dart` | (smoke / misc) | Baseline Flutter driving test. |

No widget tests exist for: StoryScreen, StoryInputScreen, HomeScreen (main.dart), TimedScriptScreen,
PreviewMergedScreen, SavedStoriesScreen, PromptScreen/VideoPromptScreen, PlanScreen,
ContentLibraryScreen, ImagePromptScreen, CarouselPromptsScreen, GeminiVideoScreen,
QuickContentScreen/CarouselMaker/TrialReel/SingleImage/IdeaInbox/MultiFormat/QualityCheck,
PromoCommentVaultScreen.

### Pipeline / production (unit + integration)
| File | Focus |
|------|-------|
| `ai_content_service_test.dart` | `AiContentServiceImpl` (PASS/BLOCKED/UNKNOWN/needsFilming paths, failure wrapping, JSON round-trip). |
| `ai_parser_validator_test.dart` | `AiParserValidator` parse findings. |
| `production_adapter_test.dart` | `ReelProductionAdapter` key-store wiring. |
| `pipeline_integration_test.dart` | End-to-end package flow. |
| `story_reel_builder_test.dart` | Reel assembly from a package. |
| `rewritten_stories_test.dart` | Story rewrite / reel generation logic. |
| `video_library_test.dart` | Video asset lookup helpers. |
| `video_production_plan_test.dart` | Production plan derivation. |
| `video_prompt_builder_test.dart` | `buildVideoPrompts` / beat logic. |

### Content models & rules
| File | Focus |
|------|-------|
| `content_axes_test.dart` | Axis parsing, `IdeaStatus` emoji/label/legacy migration. |
| `content_collection_test.dart` | `collectionOf` coverage for HookIdea / QuickIdea. |
| `content_library_test.dart` | `ContentLibraryStore` save/reload, format outputs, status migration, failed-write reporting. |
| `content_library_grouping_test.dart` | Library grouping logic. |
| `content_audit_test.dart` | `ContentAudit` metrics / items. |
| `content_package_v2_test.dart` | `ContentPackageV2` factory/JSON. |
| `content_service_test.dart` | `ContentService` API surface. |
| `quality_gate_test.dart` | `QualityGate` / `ReadyCheck`. |
| `quality_check_center_test.dart` | `ContentQualityChecker.check` + summary. |
| `beat_sheet_test.dart` | `BeatSheet` JSON round-trip, `bestLength`, `copyWith`. |
| `gemini_video_master_prompt_test.dart` | Master video-prompt generation. |
| `parts_calculator_test.dart` | Part-count / timing math. |
| `prompt_quality_test.dart` | Prompt quality heuristics. |
| `five_test_rule_test.dart` | Five-rule validation (name suggests a content rule check). |

### Storage & config
| File | Focus |
|------|-------|
| `api_key_store_test.dart` | `ApiKeyStore` default/custom key persistence (28→30 assertions). |
| `json_file_store_test.dart` | `JsonFileStore` CRUD. |
| `package_store_test.dart` | `PackageStore` persistence. |
| `prompt_vault_test.dart` | `PromptVault` versioned save/load. |
| `hook_templates_test.dart` | Hook template data integrity. |
| `idea_evaluation_test.dart` | `IdeaEvaluation` construction. |
| `engagement_package_test.dart` | `EngagementPackage` shapes. |
| `brand_identity_test.dart` | `BrandDefaults`, `CharacterLibrary`, `StoryCheck.contentPurpose`. |

## Gaps vs. the wired app
- The **central reel-creation flow** (StoryScreen → TimedScriptScreen → PreviewMergedScreen)
  has **zero widget tests**.
- The **ContentStudioHome** actions (Create Content / Content Library / Image Prompt /
  Carousel Promts / Gemini Video / Offline Story) are only covered indirectly via
  `home_screen_test.dart`'s callback wiring, not via navigation to the real target screens.
- `content_library_test.dart` does exercise the "Save to library" path that `PostingPackScreen`
  and the library UI depend on, but not the screens themselves.

## Running
`flutter test` from the repo root. Current count: **499 tests** (verified by running `flutter test`).
