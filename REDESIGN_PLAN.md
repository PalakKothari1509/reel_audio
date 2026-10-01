# Redesign Plan v5, Fun Learning With Palak

**Status:** Stage A and B applied and verified on device. Stage C partly done.
**Last verified:** `flutter analyze lib` → **91 issues, 0 errors** (6.1s). Debug APK
built and running on vivo V2318, Android 16, launched with no exceptions in logcat.
**Branch:** `copilot_post`. `REDESIGN_PLAN.md` modified; `content_ideas.md`,
`master_prompt.md`, `lib/models/quick_idea.dart`, `tool/*.ps1` untracked.
`lib/secrets.dart` correctly gitignored.
**Supersedes:** v4 sequencing and several claims in v2/v3 that this audit disproved.

---

## Status at a glance

| Stage | What it is | State |
|---|---|---|
| **A** | Live crashes and manifest | **9 of 10 done.** Only the release signing config remains |
| **B** | Data loss and dead files | **7 of 8 done.** Only `widget_test.dart` still does not compile |
| **C** | One source of truth | **Half done.** Style, characters and Mumma are in. Buckets, hashtags, CTAs, age duplicates remain |
| **D** | One generator | **Not started** |
| **E** | Library and six tabs | **Not started** |
| **F** | Cleanup | **Partly done** — dead files removed, import cycle broken |

Numbers moved from 95 issues to 91, and 0 errors throughout. The reduction is real
work, not silence: two dead files removed with the analyzer warnings they carried,
plus `defaultVisualStyle` and the two unnecessary string interpolations.



---

## 0. Corrections to my own earlier claims

Recording these first because the rest of this document was built on them.

| Earlier claim | Reality | Evidence |
|---|---|---|
| "audience is 3-6 years" | Wrong. It is **`Parents of preschoolers (1.5-5 years)`** | `brand_system.dart:17` |
| "`plan_data.dart` holds a `BucketLibrary` alias" | Wrong. `plan_data.dart` never mentions `BucketLibrary`. The alias lives in **`content_ideas.dart:17-31`** | grep: zero hits in `plan_data.dart` |
| "the import cycle is `plan_data ↔ brand_system`" | Wrong. The real cycle is **`content_ideas ↔ quick_content`** | `content_ideas.dart:18` → `quick_content.dart`; `quick_content.dart:11` → `content_ideas.dart` |
| "the app has ~14 files I never examined" | Actually **20 files** were unexamined, including `reply_assistant.dart`, `quality_check.dart`, `regenerator.dart`, `format_adapter.dart`, `posting_pack.dart`, `idea_inbox.dart`, `shot_planner.dart`, `caption_renderer.dart`, `creator_home.dart`, `slide_prompt_list.dart` | full `lib/` listing |
| "`content_ideas.md` is the source of truth, nothing is hardcoded into Flutter" | **False as written.** Ideas are compiled into `lib/content_ideas.dart` as `kDay14Posts` (`:384`). The `.md` is a manually-synced mirror. | `content_ideas.dart:384` |

The last one matters most. Until a real asset-bundled loader exists, editing
`content_ideas.md` changes nothing until a Dart file is regenerated from it.

---

## 1. Severity 1, breaks in production

**Status: 8 of 9 fixed. 1.7 (release signing) is still open.**

| # | Issue | State | Evidence |
|---|---|---|---|
| 1.1 | **`INTERNET` was missing from the release manifest.** Only in debug/profile, so a release APK had no network and every AI call failed at the socket. | **FIXED** | Added to `AndroidManifest.xml`. Verified in the merged manifest and on device: granted. `RECORD_AUDIO` removed at the same time and confirmed absent from the installed package |
| 1.2 | **`test/widget_test.dart` did not compile.** 9 of 10 required callbacks passed, so all 7 tests were dead. | **OPEN** | `test/widget_test.dart:15-25` vs `creator_home.dart:15,28`. Add `onCaptionGenerator`. Also note CI does not run on this branch |
| 1.3 | **The Gemini TTS 429 retry dropped the API key**, so the one path that survives throttling answered 401. | **FIXED** | `voice.dart` now builds the headers map once and reuses it in the retry |
| 1.4 | **`content_library.dart` silently emptied itself.** `fromJson` read `qualityReport` keys `toJson` never wrote, and `getAll` caught it and returned `[]`. | **FIXED** | The report is rebuilt from the item's own package and formats rather than serialising them twice; a damaged report now returns null instead of throwing; `getAll` decodes each row individually and logs skips |
| 1.5 | **Two `IdeaInboxStore` classes wrote `idea_inbox.json` with unreadable schemas.** | **FIXED** | `lib/idea_inbox.dart` deleted. Verified 0 importers before deleting. Only `quick_content.dart` writes that file now |
| 1.6 | **`gemini-3.6-flash-lite` is not a real model ID**, so four "cheap" call sites silently ran on the expensive model. | **FIXED** | Corrected to `gemini-3.5-flash-lite` in `story_ideas.dart` and `caption_generator.dart` |
| 1.7 | **Release is signed with the debug keystore**, `applicationId` is `com.example.reel_audio`. | **OPEN** | `build.gradle.kts:32-38` and `:19`. Both TODOs unresolved |
| 1.8 | **Live credentials on disk.** `lib/secrets.dart` (gitignored) and `backend/.env` (an OpenAI key for a directory with no source code). | **OPEN, needs you** | Rotate both keys and delete `backend/`. I cannot rotate them |
| 1.9 | **`content_ideas.dart:1145` throws `RangeError`** in `toQuickIdea`. | **FIXED** | Rewritten to pad from the reply list correctly. The function still has no caller |

---

## 2. Severity 2, brand and character contradictions

These block Point 5 outright. There is no single source, and worse, **two files
inject mutually opposite instructions into live prompts.**

| # | Issue | Evidence |
|---|---|---|
| 2.1 | ~~**Visual style is declared twice, opposite ways.**~~ **RESOLVED 3D Pixar.** Was: `brand_system.dart` said pastel watercolor, `prompts.dart` said 3D Pixar via a private const. Now `BrandDefaults.visualStyle` is the sole definition and `prompts.dart:_style` reads it. | `brand_system.dart:26`, `prompts.dart:32` |
| 2.2 | ~~**`visualStyle` duplicated as `visualStyle` / `defaultVisualStyle`.**~~ **DONE.** Duplicate deleted, it had zero external references. | `brand_system.dart` |
| 2.3 | ~~**A fourth character description set hardcoded in `visualPromptSpec`.**~~ **DONE.** Now derived from `CharacterLibrary.all`, so it cannot drift. | `brand_system.dart:476` |
| 2.4 | ~~**`kScriptShapeRules` defines a third personality set, contradicting the library.**~~ **DONE.** The hardcoded Rio/Rio/Cuty lines are gone; the rule now interpolates the library. Rio is "energetic, playful, naturally stubborn/determined", Cuty is "gentle, quiet observer, subtle comic relief". `kScriptShapeRules` had to become `final` rather than `const` to allow that. | `prompts.dart:219`, `brand_system.dart:99-127` |
| 2.5 | **DONE.** `characterLockBlock` now iterates `CharacterLibrary.all`, so a character added to the library reaches prompts automatically. | `brand_system.dart:139` |
| 2.6 | **OPEN.** `buildBrandContext` still takes a `characters` parameter and *then* appends the full lock block, so passing one character yields that character plus all of them. | `brand_system.dart:495,508,511` |
| 2.7 | **The four missing characters are not merely absent, they are actively filtered out.** `buildCharacterBlock` drops any character with a blank description, which is exactly the state Mumma, Papa, Daadi and Teacher are in. | `prompts.dart:19-23` |
| 2.8 | **Three different audience ages.** `1.5-5 years`, `2-6 year old`, `1-4 years`. Every activity's developmental framing depends on which one the caller reads. | `brand_system.dart:17`, `prompts.dart:214`, `master_prompt.md` |
| 2.9 | **Three conflicting hashtag policies**, and the code one is the broken one. `buildBrandContext` injects `hashtagPool.take(5)`, which is a **fixed five tags on every single post**: `#funlearningwithpalak #noscreenactivities #playbasedlearning #montessoriathome #toddleractivities`. `prompts.dart:320` asks for 2 fixed + 3 story-specific. The master prompt asks for exactly 5 relevant. | `brand_system.dart:496`, `prompts.dart:320-321` |
| 2.10 | **The static pool contains `#ahmedabadmoms`**, which narrows reach for a national audience. | `brand_system.dart:40` |
| 2.11 | **CTA injection fights the CTA rule.** `buildBrandContext` injects all five `ctaOptions`, including "Follow for daily play ideas", into every prompt. `prompts.dart:334` **explicitly bans** "follow for more" as engagement bait. The app tells the model to do the thing another file forbids. | `brand_system.dart:497` + `:25` vs `prompts.dart:334` |
| 2.12 | **Every reel posts an identical CTA.** `prompt_builder.dart:426` hardcodes `ctaLine: kDefaultCtaLine` rather than generating one, deliberately, so `ContentPackage.cta` and the reel path post two different CTAs. | `prompt_builder.dart:426`, `prompts.dart:120` |
| 2.13 | **`prompts.dart` forbids any series label**, which blocks the entire new series axis from reaching the script generator. | `prompts.dart:230-231`: "Never use the old 'Ria's Little Heart' series label, **or any series label**" |

---

## 3. Severity 3, duplication and conflicting models

| # | Issue | Evidence |
|---|---|---|
| 3.1 | **Four models of "a complete post", with incompatible field types.** `ContentPackage`, `PostDetails`, `QuickIdea`, `ParsedPostPackage`. Hashtags are `List<String>` in two and `String` in two. Reply suggestions are `List<String>` of exactly 5 in one and a single `String` in another. | `content_generator.dart:10`, `prompts.dart:133`, `quick_content.dart:19`, `content_ideas.dart:1093` |
| 3.2 | **The 5-reply rule is enforced in one model and structurally impossible in another.** `quality_check.dart:272` fails a package whose `replyComments.length != 5`; `PostDetails` has no list, only `replyQuestion`. | as cited |
| 3.3 | **Three competing caption specifications.** `kCaptionSpec` is the declared standard but is imported only by its own file. | `caption_generator.dart:37`, `gemini_client.dart:116`, `prompt_builder.dart:141` |
| 3.4 | **Two quality checkers that disagree on the same rule.** Both implement `hook_length`, one as ≤125 characters, the other as ≤8 words. | `quality_check.dart:90` vs `quick_content.dart:2323` |
| 3.5 | **Three `IdeaStatus` enums, two of them same-named with different values**, and `reuse` vs `reused` makes `values.byName` throw. | `idea_inbox.dart:10`, `quick_content.dart:2946`, `content_library.dart:11` |
| 3.6 | **Four format vocabularies.** `ContentFormat` has 4 values and lacks `imageReel` and `story`. `QuickIdea.postType` is a bare string with a 4-item dropdown that has `Story` but not `Trial Reel`, and both `Single Image` and `Static Image`. The markdown parser reads only `Post Type` and never `Format` or `Content Type`. | `brand_system.dart:404`, `quick_content.dart:1477-1488`, `content_ideas.dart:1237` and `:1259` |
| 3.7 | **The parser silently collapses Trial Reel into Reel.** `_normalizePostType` checks `contains('reel')` before any trial-specific branch. | `content_ideas.dart:1259` |
| 3.8 | **`AIProviderWithFallback` and `NoOpAIProvider` are never instantiated.** The intended degradation for every AI failure is dead code; `main.dart:411-413` wires a bare client or null. | `ai_provider.dart:95`, `:269` |
| 3.9 | **`caption_generator.dart` documents a fallback it does not have.** The comment claims it falls back "on any failure"; the code only falls back when the key is empty. Every API failure surfaces as an empty caption. | `caption_generator.dart:154-155` vs `:166-168` |
| 3.10 | **Two copies of `_applyRegeneration`**, and `Regenerator` stores a `Future` in a `dynamic` field that callers blind-cast, which throws. | `ai_provider.dart:155-266` vs `quick_content.dart:3804+`; `regenerator.dart:148` |
| 3.11 | **The bucket key set is declared ten separate times** across five files. Adding or renaming a bucket requires ten edits. | `format_adapter.dart:201,307,583`; `content_generator.dart:405,417,435,448`; `quality_check.dart:531,550`; `regenerator.dart:255` |
| 3.12 | **~496 lines of duplicated JSON-store code**, with `_path()` copied nine times, two of them byte-identical. Error handling is inconsistent across the six near-identical implementations: four swallow to `[]`, one crashes. | §4 table of the persistence audit |
| 3.13 | **Import cycle `content_ideas ↔ quick_content`, containing `const` initialisers.** | **FIXED.** `QuickIdea` and both its stores moved to `lib/models/quick_idea.dart`. `content_ideas.dart` now imports only `brand_system.dart` and that model — no path back to `quick_content.dart`, so the cycle is structurally impossible. `plan_data.dart` no longer transitively pulls 4,400 lines of UI. Verified by import trace |

---

## 4. Persistence, verified

| Store | File | Model | Status |
|---|---|---|---|
| `ProjectStore` | `stories/<id>.json` | `Project`, 26 fields | Live. One file per story |
| `QuickIdeaStore` | `quick_ideas.json` | `QuickIdea` | Live |
| `QuickHistoryStore` | `quick_post_history.json` | `QuickIdea`, capped 50 | Live. A second copy of the same model |
| `PromoCommentStore` | `promo_comments.json` | `PromoComment` | Live |
| `IdeaInboxStore` | `idea_inbox.json` | `IdeaInboxItem` | Live, **the Idea Vault** |
| `IdeaInboxStore` | `idea_inbox.json` | `IdeaRecord` | **Dead, 0 importers, same filename** |
| `ContentLibraryStore` | `content_library.json` | `ContentLibraryItem` | **Dead, 0 importers, and see 1.4** |
| `HookStore` | `hooks.json` | `HookIdea` | Live |
| `ScheduleStore` | `schedule.json` | `PostSlot` | Live |
| `PostLogStore` | `posts.json` | `PostRecord` | Live |
| `CharacterStore` | `characters.json` | `CharacterRef` | Live. `assetPath` deliberately not persisted, re-derived by name |

**Migration:** exactly one real migration function, `migrateBucketId`
(`plan_data.dart:23-35`), applied on read only, and only inside
`PostRecord.fromJson`. It is **not** applied to `QuickIdea.bucket`, so any saved
idea carrying a legacy id renders as uncoloured text. The backup envelope writes
`version: 2` and never reads it.

---

## 5. Severity 4, generation bugs

| # | Issue | Evidence |
|---|---|---|
| 5.1 | **`gemini_client` requests a `script` it throws away.** The response schema demands it, the prompt insists on it, five few-shot examples include it, and `_parseResponse` never reads it. `ContentPackage` has no field for it. `quality_check.dart:292` papers over this by scoring the caption as the script, and `script_timing` then measures the caption's word count as if it were a voiceover. | `gemini_client.dart:233`, `:120`, `:329-369`; `quality_check.dart:292-317` |
| 5.2 | **Four text call sites send no `thinkingConfig`.** The thinking-budget bug that produced truncated unparseable JSON was found and fixed in the caption call, then never applied to the script, prompts, combined, or `GeminiClient` calls. Those are the 8,192-token ones, i.e. the most exposed. | `main.dart:158-165`, `prompt_builder.dart:176-180` and `:336-344`, `gemini_client.dart:30-37` vs the fix at `caption_generator.dart:196-202` |
| 5.3 | **`GeminiClient` has no resilience layer.** It bypasses `geminiPost`, so it gets no 404 model fallback, no backoff, no retry, only a 45-second timeout. Its own comment concedes this. | `gemini_client.dart:12-14`, `:20` |
| 5.4 | **`PostingPackScreen._saveToLibrary` is a stub** showing "coming soon", so the one fully-generated single-call output **cannot be persisted at all.** | `posting_pack.dart:581-586` |
| 5.5 | **Hard-cast nested parsers defeat their graceful parents.** `ContentPackage.fromJson` carefully defaults every field, then calls `SlideContent.fromJson`, which hard-casts all five. `FormatOutput.fromJson` hard-casts throughout. | `content_generator.dart:135-141`, `format_adapter.dart:30-37` |
| 5.6 | **`gemini_client._parseResponse` throws on the one path that matters most**, and embeds the entire raw model reply in the exception. Two residual hard casts on `hashtags` and `replyComments`. | `gemini_client.dart:361-368` |
| 5.7 | **Regeneration silently no-ops** for `slides`, `singleSlide`, `visualPrompts`, returning the original package. | `ai_provider.dart:259-264`, `quick_content.dart:3808+`, `regenerator.dart:148` |
| 5.8 | **Six call sites ignore the Settings API key** and read `secrets.dart` directly, so a user who configures Settings sees "AI generation enabled" and gets it honoured in one feature out of ten. | `main.dart:48,172`, `prompt_builder.dart:171,331`, `story_ideas.dart:220,339,499`, `main.dart:2278,2325` |
| 5.9 | **The API key is stored unencrypted in SharedPreferences**, and the `AIza` prefix validator would reject the app's own `AQ.`-prefixed key. | `settings_screen.dart:82`, `:201` |

---

## 6. Severity 5, navigation and dead UI

23 screen classes. 10 reachable from `CreatorHomeScreen`. **4 of your 6 target tabs
do not exist at all.**

| Current | Target tab | Verdict |
|---|---|---|
| Idea Vault, Saved Stories, Plan→Hooks | **Ideas** | Partial, split across three places |
| 5 separate cards: Reel, Trial Reel, Carousel, Image, Multi-Format | **Create** | Fragmented. Carousel, Trial Reel and Single Image each have **3 entry points** |
| Plan→"When to post", a static list | **Calendar** | **Does not exist.** No calendar, no scheduling |
| Plan→"Results", manual text entry | **Analytics** | **Does not exist.** No metrics capture |
| none | **Experiments** | **Does not exist.** Zero infrastructure for 1/5 through 5/5 |
| Settings, Promo Comments, `BrandDefaults` | **Brand** | Scattered across four surfaces, no unified brand kit |

**Unreachable screens:**

| Screen | Evidence |
|---|---|
| `QualityCheckScreen` (`quick_content.dart:2564`) | Fully implemented, never pushed. `CarouselMakerScreen` skips straight to `PostingPackScreen` |
| `ShotPlannerScreen` (`shot_planner.dart:10`) | `main.dart:1278` shows a SnackBar redirecting elsewhere instead of navigating |
| `HomeScreen` (`main.dart:503`) | Legacy, only reachable from a `StoryScreen` appBar icon |
| `StoryInputScreen` (`main.dart:1699`) | Only pushed from that legacy `HomeScreen` |

**Completely unreferenced files:** ~~`lib/idea_inbox.dart`~~ **deleted** ·
~~`lib/slide_prompt_list.dart`~~ **deleted** · `lib/content_library.dart` **kept
deliberately** — it is not imported, but it is the only persistence model for a
generated package and the rebuild target in §11 Stage E, and its silent-wipe bug is
now fixed.

---

## 7. Severity 6, build, config, dependencies

| # | Issue | Evidence |
|---|---|---|
| 7.1 | ~~**`RECORD_AUDIO` requested but never used.**~~ **DONE.** Removed. The app has no audio recording; the `recorder` hits are Flutter canvas rasterisation in `caption_renderer.dart`. Confirmed absent from the installed package. | `AndroidManifest.xml` |
| 7.2 | **iOS will crash on first image pick.** `Info.plist` has no `NSPhotoLibraryUsageDescription`. Bundle ID is still `com.example.reelAudio`. | `ios/Runner/Info.plist`, `project.pbxproj:386` |
| 7.3 | **Unused dependencies.** `hive` and `hive_flutter` are still declared and still unused. `cupertino_icons` likewise. **`uuid` is now removed** — its only use was in `idea_inbox.dart`, which is deleted. | `pubspec.yaml` |
| 7.4 | **`google_generative_ai ^0.4.0` is Google-deprecated** and has no `thinkingConfig` support at all, which is precisely why `GeminiClient` cannot turn thinking off. | `pubspec.yaml:40` |
| 7.5 | **Release minification is off.** No `isMinifyEnabled`, no `shrinkResources`, no `proguardFiles`, for an APK carrying FFmpeg native libraries. | `build.gradle.kts:33-37` |
| 7.6 | **`assets/ideas/*.md` are neither bundled nor read.** Four files of real content ideas, zero references in Dart, not in `pubspec.yaml`. `APP_OVERVIEW.md:78` claims they are usable. | grep returns 0 |
| 7.7 | **`gemini-2.5-flash-preview-tts` is superseded** by `gemini-3.1-flash-tts-preview`. | `voice.dart:48` |
| 7.8 | **Launcher label is `reel_audio`**, not "Fun Learning With Palak". | `AndroidManifest.xml:3` |
| 7.9 | **`temperature`, `topP`, `topK` are set on every text call.** Google now recommends removing all three on Gemini 3.x. | `gemini_client.dart:19,31`; `main.dart:159`; `prompt_builder.dart:177,337` |
| 7.10 | **Carousel canvas is 1080×1440, which is 3:4.** Instagram feed ratios are 1:1, 4:5 and 1.91:1. 3:4 is outside all of them and will crop. | `brand_system.dart:406` |

---

## 8. Severity 7, tests, docs, hygiene

| # | Issue | Evidence |
|---|---|---|
| 8.1 | **7 tests, 1 file, and it does not compile.** See 1.2. No mocking library in `dev_dependencies`, so nothing touching `http` or `path_provider` is testable at all. | **STILL OPEN.** This is the last mechanical Stage B item and it is one line |
| 8.2 | **Zero tests on the highest-consequence code:** Gemini JSON parsing and `_stripFence`, `geminiBusyMessage`, the model-404 memory cache, `AIProviderWithFallback` degradation, `FormatAdapter`, `caption_renderer.dart` canvas drawing, `video_builder.dart` FFmpeg assembly, and backup write/restore. | full audit |
| 8.3 | **`README.md` is unmodified Flutter template boilerplate.** "A new Flutter project." Same string in `pubspec.yaml:2` and `web/index.html:21`. `APP_OVERVIEW.md` is the real doc and is good, but it omits Caption Generator from its dashboard table. | `README.md:1-17`; `APP_OVERVIEW.md:15-24` |
| 8.4 | **`content_ideas.md:3-14` falsely claims ideas are not hardcoded into Flutter.** See §0. | `content_ideas.dart:384` |
| 8.5 | **8 of the last 10 commits are titled `commit` or `Commit`.** The last three are a remove-then-re-add churn cycle on Promotion Comments, and the bug cited in `d12b78b4` has no regression test. | `git log --oneline -5` |
| 8.6 | **`quick_ideas.json` at the repo root contains a `cat:` error message**, not data. Not gitignored. | file at repo root |
| 8.7 | **`debug_report.txt` is a stale committed artefact** referencing two deleted files, and its own tooling reports "No screens found". | `debug_report.txt:21,26,52` |
| 8.8 | **Four near-duplicate debug `.ps1` scripts**, of which only `run_phone.ps1` is documented. | repo root |
| 8.9 | **`.gitignore` lacks root `node_modules/` and `.env`.** `.vscode/` is tracked, including a possible `mcp.json`. | `.gitignore:24` |
| 8.10 | **20 `withOpacity` deprecations and 2 `Share.share` deprecations** account for much of the 95. Mechanical. | analyzer output |
| 8.11 | **CI never runs on this branch.** `build.yml:12` triggers on `main` and `video-slideshow`; you are on `copilot_post`. | `.git/HEAD` |

---

## 9. The pipeline and the app structure you specified

Unchanged from v4 and still correct. Restated here because the audit shows how far
the code is from it.

```
IDEA → FORMAT → CONTENT PACKAGE → CREATIVE → POST → TRACK
```

One **Create** action. Hook, visual hook, verbal hook, on-screen text, script,
narration, visual directions, CTA, SEO caption, exactly 5 hashtags, pinned
comment, 5 reply suggestions, cover text, recommended goal, why non-followers will
see it, and the format test number. All from one call.

The format must change generation, not be a post-processing flag:

| Format | The generator must do |
|---|---|
| Trial Reel | Strongest possible first 1-3s, one clear idea, simplest production, built to be tested |
| Reel | Hook → problem → story/value → payoff → CTA |
| Image Reel | Every image carries part of the story with sound off, minimal text |
| Carousel | Slide 1 stops the scroll, each slide advances, final slide is the CTA |
| Static | One strong visual, one message, short caption. No forced carousel shape |
| Story | Short sequential frames built for interaction |

**"Why this format" is part of Create**, not a separate screen. One line of
reasoning next to every recommendation, so the pattern is learnable rather than
trusted blindly.

---

## 10. Open decisions

**All six are now decided.** Recorded with what still has to be built, because a
verdict in a document is not an implementation.

### 10.1 ~~`watercolor` or `pixar`~~ → **`pixar`** (applied)

`BrandDefaults.visualStyle` is the sole definition; `prompts.dart:_style` reads it.
The same wording was found hardcoded in 5 further files and 30 occurrences were
replaced, including the main `GeminiClient` system prompt and 21 seeded
`imagePrompt` strings in `content_ideas.dart`. §2.1-2.5 now marked done.

### 10.2 ~~Appearance and personality for all seven~~ → **Partly closed**

| Character | State |
|---|---|
| Ria | Done. Including *toofani*, written as "round chubby cheeks and a soft plump build, not thin" because image generators do not know the Hindi word |
| Rio | Done. "Energetic and playful, naturally stubborn and determined" |
| Cuty | Done. "Gentle, quiet observer, calm and sleepy, subtle comic relief" |
| Mumma | **Done.** Added to `CharacterLibrary`, so she now reaches every prompt through `characterLockBlock`. Includes her speech pattern |
| Papa, Daadi, Teacher | **Still open.** Not on the critical path for the current direction, but they are referenced by name in ideas and would still generate undescribed |

A `speechPattern` field was added to `Character` because personality decides what
Mumma *does* while speech decides what comes out of her mouth. "Patient" alone
produces a scolding-adjacent line; "arre mera bachha" produces the right tone.

### 10.3 Target audience → **1-4 years** (applied)

`BrandDefaults.audience` is now "Indian moms and parents of children aged 1-4",
and the "2-6 year old" line in `kScriptShapeRules` is now 1-4. That closes the
three-way conflict in §2.8.

One thing to settle later: the decision says "1.5 to 5 years, or shorthand 1-4".
Those are different ranges. The code now says **1-4**, so if 1.5-5 was the intent,
say so and it is a one-line change.

### 10.4 Bucket → **retire, replaced by `ContentPillar`** (not started)

Agreed in principle and I think it is right, because the ten hardcoded bucket-id
sets in §3.11 are the worst drift surface in the codebase. Named pillars
`diyHacks`, `storyMoral`, `routineHabits`, `parentRelatability` live in
`brand_system.dart`; legacy ids map through the existing `migrateBucketId` on read,
then the bucket concept is deleted.

**This is not a rename and it is not cheap.** Order matters: the pillar enum must
land with the migration mapping and the ten call sites collapsed onto it, or you
get a third vocabulary. Do it in Stage D with the format work, not before.

### 10.5 Status ladder → **one enum** (not started)

`IdeaStatus { draft, proposed, approved, inProgress, posted, archived }`, dropping
`reuse` vs `reused`. That resolves §3.5, where the same enum name carries different
values in two files and `values.byName` throws on the mismatch.

`proposed` and `inProgress` map onto the distinction that matters: an idea the
model suggested versus one you have decided to make. That is the approved/proposed
split from §12.2.

### 10.6 Trial Reel → **a real `ContentFormat` value, never a flag** (not started)

Confirmed. Its timing rules genuinely differ: pattern interrupt inside frame 1,
one problem, one immediate action, no preamble. That is a different generation,
which is the argument for it being a type rather than a boolean.

### 10.7 Idea loading → **build-time codegen, not a runtime asset** (decision accepted)

`dart run tool/sync_ideas.dart` compiles `content_ideas.md` into a generated Dart
file, so prompt construction stays synchronous, `const` survives, and a malformed
line becomes a compile error instead of a startup crash.

**This supersedes what I recommended in §12.3 and it is the better call.** I argued
for a `rootBundle` loader with a `kDay14Posts` fallback; you are right that async
startup plus bundling failure modes are worse than a build step you run
deliberately. Two requirements on the implementation:

- **Do not gitignore the generated file.** The usual convention is to ignore
  `*.g.dart`, and if you do, a fresh clone fails to compile. Either commit it or
  add the codegen to the build pipeline.
- **`QuickIdea` has to move first.** It currently lives in `quick_content.dart`,
  so generating a `const List<QuickIdea>` into a model file would import 4,360 lines
  of UI and preserve the import cycle in §3.13. Move it to `lib/models/` as part of
  Stage B.

### 10.8 Format handbook → **its own `format_handbook.dart`** (decided)

Answered directly: separate file, not inside `brand_system.dart`. Formats are the
most volatile data in the system, since testing one five times is the loop you
described, and `brand_system.dart` is imported by ten-plus modules. Editing a
format should not touch a file that `ai_provider`, `format_adapter`,
`content_generator` and `quality_check` all depend on.

`ContentFormat` moves with it, because that enum has `canvasWidth`, `topMargin`
and `defaultSlideCount` baked in, which is publishing layout rather than identity.
The handbook must not reference buckets, or §10.4 stays impossible.



---

## 11. Order of work

### 11.1 Done

**Stage A, live defects.** 1.1 INTERNET permission + `RECORD_AUDIO` removed ·
1.3 TTS retry key · 1.4 quality-report round trip and per-row library decode ·
1.6 lite model id · 5.2 thinkingConfig confirmed on the caption path · all verified
on device.

**Stage B, data loss.** 1.5 `idea_inbox.dart` deleted · `slide_prompt_list.dart`
deleted · `uuid` dependency removed · 1.9 `toQuickIdea` RangeError · 3.13 import
cycle broken by moving `QuickIdea` to `lib/models/quick_idea.dart` · 1.4 per-row
decode so one bad file no longer empties a store.

**Stage C, brand, partly.** 2.1-2.5 done: single `visualStyle`, 30 occurrences of
the old wording replaced across 6 files, `visualPromptSpec` characters derived from
the library, `characterLockBlock` iterating `all`, personality sets reconciled,
Mumma added with a `speechPattern` field. 2.6 done via `characterLockFor`.

**The ten reach dimensions** are in `quality_check.dart`, all `warn` severity so
they cannot block posting.

### 11.2 Next, in this order

1. **1.2, the test compile.** One argument. Until this is fixed `flutter test`
   fails, so CI is red and every future change is unverifiable by test.
2. **1.8, rotate the keys and delete `backend/`.** Only you can do this.
3. **1.7, release signing and `applicationId`.** Required before any real install.
4. **5.4, make the posting pack persistable.** `posting_pack.dart` still shows
   "coming soon", so a generated package cannot be saved at all. This is the single
   biggest gap between "generate" and "have a library".
5. **Stage C remainder.** Drop the static `hashtagPool.take(5)` injection (2.9),
   drop the CTA menu that fights the CTA rule (2.11), settle the last age duplicate
   (2.8).

### 11.3 Then

**Stage D, one generator.** Migrate `PostDetails`, `ContentPackage`, `QuickIdea`
and `ParsedPostPackage` to one package type · one caption spec · one quality
checker (there are still two) · delete `caption_generator.dart` and the standalone
generators · wire the fallback that already exists but is never instantiated (3.8) ·
fix the discarded `script` (5.1) · add `imageReel` and `story` to `ContentFormat` ·
unblock the series axis (2.13) · add the `FormatSpec` registry in its own
`format_handbook.dart` (§10.8) · retire buckets for `ContentPillar` (§10.4) · the
one status enum (§10.5) · `tool/sync_ideas.dart` codegen (§10.7).

**Stage E, library and tabs.** Real idea codegen · Series / Format / Production /
Goal on every idea · format recommendation with reasoning · the four missing tabs.

**Stage F, cleanup.** Generic JSON store to absorb the remaining duplicated lines ·
remove `hive`/`hive_flutter`/`cupertino_icons` · README · CI on this branch ·
tests for the Gemini parse path, the fallback and format adaptation.

---

## 12. Implementing the two-stage pipeline

You asked how to build this before generating any ideas. Written against the real
files, not a generic architecture.

### 12.1 What already exists, and what that means

| Your proposal | Reality | Decision |
|---|---|---|
| `page_profile.json` with niche, audience, positioning, characters | `BrandDefaults` in `brand_system.dart` already holds brand, handle, audience, tone, visual style, and `CharacterLibrary` holds the three characters. `buildBrandContext` already injects them. | **Do not create a JSON file.** Keep it as const Dart. It has to be `const` to be injected into `const` prompt strings, and a runtime JSON read would force every prompt builder to become async. Extend `BrandDefaults`, do not parallel it |
| `content_formats.md` with a definition per format | No format library exists. `content_ideas.md` has 11 format names, no definitions. The 50-format handbook is not in the repo. | **Blocked on the handbook.** See §12.5 |
| `ideas.md` read at runtime | Ideas are compiled into `content_ideas.dart:384` as `kDay14Posts`. `assets/ideas/*.md` already exists on disk, is **not in `pubspec.yaml`, and is never loaded** — the exact trap this would walk into again | Needs a real loader plus a const fallback. See §12.3 |
| Stage A idea generation | Nothing. No `PageProfile`, no `FormatDefinition`, no `IdeaEngine`, no scorecard. | New, and the main risk. See §12.2 |
| Stage B content generation | `GeminiClient.generate()` at `gemini_client.dart:56` already returns a full `ContentPackage` under a response schema, including hook, slides, caption, CTA, exactly 5 hashtags, pinned comment and 5 replies | Mostly there. It is missing narration, per-scene dialogue, cover text, and the test number |
| Content type rules | `ContentFormat` has 4 of your 6 values. `imageReel` and `story` do not exist. | Add both |
| Reach scorecard | Nothing | **Do not build a new scorer.** See §12.4 |

### 12.2 The main risk, stated plainly

Stage A as proposed adds an idea engine, and Stage B is a second generation path.
The app already has **8 text call sites, 3 competing caption specs, 2 dead AI
providers, and 2 quality checkers that disagree with each other**. Adding a clean
two-stage pipeline on top of that does not make it cleaner, it makes it a third
generation stack.

So Stage A must be a *selector*, not a second generator. Two sources, clearly
separated:

- **Approved** — ideas already in `content_ideas.md`. These are the default.
- **Proposals** — new ideas the model suggests to fill gaps you have not covered.

A proposal is never silently promoted into the library. It shows as a proposal
with a reason it was suggested, and it enters the library only when you say so.
Otherwise you will lose the distinction between what you decided and what the
model guessed, which is the thing the `.md` was meant to protect.

Implementation: **one new method on the existing client**, not a new client. A
`responseSchema` of ideas, reusing `gemini_post` transport so it inherits the 404
fallback, the backoff and the per-model quota separation that `GeminiClient`
currently lacks (§5.3).

### 12.3 The loader decision

`content/ideas.md` on disk cannot reach the app without all three of:

1. Declared under `assets:` in `pubspec.yaml` — the file `assets/ideas/*.md`
   demonstrates what happens if you skip this.
2. Loaded with `rootBundle.loadString`.
3. Parsed at startup, with the existing `kDay14Posts` kept as the fallback when
   the asset is missing or the parse fails.

Without step 3 the app hard-crashes on a malformed line in a file you edit by
hand, which is the worst possible failure for a file you edit weekly.

Two sub-decisions follow from this. **`QuickIdea` must move out of
`quick_content.dart` first** — it is the type `kDay14Posts` is a list of, and
leaving it there means the loader keeps the §3.13 import cycle. And the parser
must read `Format`, `Production`, `Age`, `Hook Angle` and `Test Number`, none of
which it reads today; it only reads `Post Type`, and normalises Trial Reel into
Reel (§3.7).

### 12.4 The scorecard should not be a new system

You want `Reach Potential: 8.7/10`. That is a good idea and it should not be a
second AI call and should not be a second scorer.

`quality_check.dart` already scores packages against 30 rules and already reports
`isReadyToPost`. Add reach rules to it, keyed on the same outputs:

| Dimension | Scored from, all already in `ContentPackage` |
|---|---|
| Hook strength | `hook` length and whether it opens on a scene, not an introduction |
| Curiosity | does the hook pose a question the piece answers |
| Relatability | whether `characters` and the problem match a 1-4 household |
| Non-follower appeal | is the hook understandable with no prior context |
| Watch-time | slide count and whether the payoff is withheld |
| Save potential | is there a reference the parent returns to |
| Share potential | is there a specific moment worth sending on |
| Comment potential | does the piece end in a question |
| Brand fit | do the characters match `CharacterLibrary` |
| Originality | is this a known fable or a specific situation |

Two constraints. Label it in the UI as an internal heuristic, never as a
prediction, because it is the model grading its own output. And **do not** run
the number before you have posted anything, since a self-score has no
calibration until there is real data behind it.

### 12.5 Still blocked

1. **The 50-format handbook is not in the repo.** You reference it as the
   framework for both stages, and the app needs a *definition* per format, not
   just a name. `Ideas from chat gpt for marketing posts.md` is a strategy
   document. Without the real list, Stage A can propose a format name the
   generator has no rules for.
2. **Mumma has no profile and appears in most of your examples.** With Ria, Rio
   and Cuty now defined, Mumma is the single most damaging gap — *"Phone chahiye
   → simple home activity"* is a Mumma story. One line for Mumma unblocks the
   entire Jugaadu Mummy direction.
3. Papa, Daadi and Teacher remain undefined, but they are not on the critical path
   for the current content direction.

### 12.6 Order

I would still not build Stage A yet, and the reason is Stage B of the audit rather
than the architecture. `idea_inbox.json` has two writers with unreadable schemas,
`posting_pack.dart` cannot persist its output at all, and `content_library.dart`
silently empties itself. Adding a proposal store on top of that means a fourth
idea store, and you will not be able to tell which file your approved ideas are in.

Recommended order: §11 Stage A and B (the live defects and the data loss, all
one-liners to small edits) → add `imageReel` and `story` to `ContentFormat` →
add the reach rules to `quality_check.dart` → then Stage A idea proposals →
then the content library rebuild and the six tabs.
---

## 13. The Content Studio architecture, as specified

Your latest architecture is largely consistent with 10 and 12, and needs no changes to
those decisions. Recorded here with the three places it collides with applied work.

### 13.1 Agreed and already reflected

| Your point | Where it already lives |
|---|---|
| One generator, no separate caption/hashtag/hook tools | 12.2, 11.3 Stage D |
| Idea to Format to Content Type to Script to Hook to Visual to Caption to SEO to Hashtags | 9 |
| Format and Content Type stay separate axes | 10.8, where `format_handbook.dart` owns both |
| Carousel must not be a Reel script split into slides | 9, format rules table |
| Trial Reel is a distinct type with its own generation | 10.6 |
| AI Content Brief screen before generating | 12.2, with format recommendation plus reasoning |
| Performance tracking only after real posting | 11.3 Stage E |
| Modes rather than ten separate features | 12.2, approved vs proposed |

### 13.2 Three collisions to settle

**A. Point 23 reverses a decision you made two messages ago.** You wrote:

> "every single character model is unambiguously rendered in a stylized 3D
> Pixar/Disney-inspired aesthetic, not traditional watercolor"

and instructed me to change it. I did: 30 occurrences across 6 files, and
`BrandDefaults.visualStyle` now reads "Soft 3D Pixar/Disney-style render, NOT
watercolor".

Point 23 now says the opposite, and proposes defining the style as "Fun Learning
With Palak soft watercolor children's illustration style".

The underlying reasoning is sound and worth separating from the conclusion. Not
depending on a studio name is good practice, because "NOT kawaii-chibi" and "NOT
flat 2D" are negative constraints against a look some generators will not
recognise. But the replacement proposed is watercolor, and the seven reference
renders are not. Adopting it would send every generation toward a look the
character art does not show, which is the same class of bug as the one just fixed,
only in the other direction.

To get a brand-owned style name without contradicting the assets:

```
Soft 3D Pixar/Disney-style children's illustration, warm Indian home settings,
pastel-leaning palette, rounded friendly shapes, expressive faces, clean
backgrounds, preschool-friendly. NOT flat 2D, NOT watercolor, NOT kawaii-chibi.
```

Nothing has been changed for point 23. This needs one word: **Pixar-derived, or
watercolor**.

**B. Point 21 splits the brand across six markdown files.** `brand.md` and
`characters.md` would duplicate what `brand_system.dart` now holds in `const`.
Moving them back into markdown recreates the drift just removed: 30 stale
watercolor strings, four character description sets, three age ranges.

The split is right for `formats.md`, `series.md` and `ideas.md`, which are data
that changes. It is wrong for brand and characters, which are identity and must
stay `const` to keep prompt builders synchronous.

**C. Point 18 and point 4 conflict with decisions in section 10.** The status ladder
here has nine values; 10.5 settled on six. The content-type enum here has seventeen
values; 10.8 settled on six, each with a `FormatSpec` contract behind it. Both should
defer to section 10 unless deliberately reopened, and if reopened the seventeen need
seventeen generation contracts, not seventeen names.

### 13.3 Still blocked

**The 50-format handbook.** This is now the fourth time it has blocked, and point 20
depends on it entirely. The app needs a definition per format, not a name. Twenty-six
format names exist across `content_ideas.md` and the bundled `assets/ideas/*.md`
files, and none has a structure attached. Without it, Stage A can propose a format
the generator has no rules for.

Worth checking: `assets/ideas/*.md` is four more idea files that are neither bundled
nor read (7.6). If the handbook is hiding in there, it is already in the repo.

### 13.4 One factual correction

Point 24's dashboard says "37 ideas". The library currently holds **57** - 24 seeded
posts plus 33 added this session. The dashboard count should be computed, not typed.

---

## Log

| Date | Point | Result |
|---|---|---|
| today | **on device** | Installed and launched on vivo V2318 / Android 16. No crashes, no Flutter exceptions in logcat. Verified `INTERNET` granted and `RECORD_AUDIO` absent **in the installed package**, not just in source |
| today | **Stage A+B** | 9 of 10 Stage A items, 7 of 8 Stage B items. Fixed the TTS retry key drop and the `content_library` silent wipe. Deleted `idea_inbox.dart` + `slide_prompt_list.dart`, removed `uuid`, broke the `content_ideas ↔ quick_content` import cycle by moving `QuickIdea` to `lib/models/quick_idea.dart`. 95 → 91 issues, 0 errors |
| today | **pipeline design** | Wrote §12 mapping the two-stage pipeline onto real files. Audience locked to 1-4 in `BrandDefaults` and `kScriptShapeRules`. Ria gained her toofani appearance trait. Still blocked on the 50-format handbook and a Mumma profile |
| today | **Phase 1** | 3D Pixar unified. `BrandDefaults.visualStyle` is now the only definition and `prompts.dart:_style` reads it. Duplicate `defaultVisualStyle` deleted. `visualPromptSpec` characters derived from the library. `kScriptShapeRules` personality block removed and made `final`. The same wording turned out to be hardcoded in **5 more files**, so 30 occurrences were replaced. 95 → 93 issues, 0 errors, APK builds |
| today | audit | 9 critical, 13 brand contradictions, 13 duplications, 9 generation bugs, 10 config, 11 hygiene. 4 of 6 target tabs do not exist |
| today | v5 | Wrote the full audit here. Corrected four of my own earlier wrong claims in §0 |
| today | v4 | Four pillars, 16-field schema, 33 new ideas, master prompt, six-tab structure |
| today | v3 | Idea Library created. Generators merged into one Create Content |
| today | v2b | Found all 7 character images. `brand_system` is missing 4 of them |
| today | **1** | Done, plus the thinking-budget bug found while testing |
| today | **2** | Done. Single ideas file, one bucket list, `community` created |
