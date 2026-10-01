# Redesign Plan v5, Fun Learning With Palak

**Status:** full code audit complete. Nothing below has been applied.
**Last verified:** `flutter analyze lib` → **95 issues, 0 errors** (8.3s).
**Branch:** `copilot_post`. `REDESIGN_PLAN.md` modified, `content_ideas.md` and
`master_prompt.md` untracked. `lib/secrets.dart` correctly gitignored.
**Supersedes:** v4 sequencing and several claims in v2/v3 that this audit disproved.

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

| # | Issue | Evidence | Fix |
|---|---|---|---|
| 1.1 | **`INTERNET` permission is missing from the release manifest.** It exists only in the debug and profile manifests. A release APK has no network, so every Gemini and ElevenLabs call fails at the socket. | `AndroidManifest.xml:45-49` lacks it; `debug/AndroidManifest.xml:6` and `profile/AndroidManifest.xml:6` have it; merger report `build/app/outputs/logs/manifest-merger-debug-report.txt:155` proves the provenance | Add to main manifest. CI only builds `--debug` (`.github/workflows/build.yml:56`) so nothing catches this |
| 1.2 | **`test/widget_test.dart` does not compile.** `CreatorHomeScreen` requires 10 callbacks; the test passes 9, omitting `onCaptionGenerator`. All 7 tests are dead. | `test/widget_test.dart:15-25` vs `creator_home.dart:15,28` | Add the argument. CI does not run on branch `copilot_post` (`build.yml:12` triggers on `main` and `video-slideshow` only) |
| 1.3 | **The Gemini TTS 429 retry drops the API key.** The retry rebuilds the request with `Content-Type` only, so the one path that recovers from per-minute throttling fails with 401. | `voice.dart:317-321` vs the correct first attempt at `:290-296` | Reuse the same headers map. One line |
| 1.4 | **`content_library.dart` cannot reload any item that has a quality report.** `fromJson` reads `qualityReport['package']` and `['formats']`; `toJson` never writes either key. `getAll` wraps the list in `try/catch → return []`, so **one bad item silently empties the entire library.** | `content_library.dart:147-148` vs `:105-120`, and `:215-217` | Write both keys, and make `getAll` skip the bad item rather than the whole list |
| 1.5 | **Two `IdeaInboxStore` classes write `idea_inbox.json` with mutually unreadable schemas.** One writes `rawIdea`, the other reads `rawNote`. Cross-reading throws, and one store has no error handling at all. | `quick_content.dart:3025` + `:3012` vs `idea_inbox.dart:178` + `:133` | `idea_inbox.dart` has **zero importers**. Delete it. It is a landmine |
| 1.6 | **`gemini-3.6-flash-lite` is not a real model ID.** Google's Lite tier is `gemini-3.5-flash-lite`. The 404-fallback hides it, so all four "cheap" call sites silently run on `gemini-3.6-flash`, **nullifying the per-model quota separation the code was written to achieve** (`story_ideas.dart:44-55`). | `story_ideas.dart:56`, `caption_generator.dart:27` | Rename to `gemini-3.5-flash-lite` |
| 1.7 | **Release is signed with the debug keystore** and `applicationId` is still `com.example.reel_audio`. Not installable from Play. | `build.gradle.kts:32-38` (the TODO is unresolved), `:19` | Add a real signing config |
| 1.8 | **Live credentials on disk.** `lib/secrets.dart:1-2` holds a Gemini key (`AQ.` prefix) and an ElevenLabs key. `backend/.env:2` holds a live OpenAI key for a `backend/` that contains **no source code**, only `node_modules` and `.env`. | files as cited; `lib/secrets.dart` is gitignored (`.gitignore:57`) but keys are still extractable from the APK | Rotate all three. Delete `backend/`. `APP_OVERVIEW.md:100` claims no OpenAI anything exists, which the directory contradicts |
| 1.9 | **`content_ideas.dart:1145` throws `RangeError`.** `toQuickIdea` pads the comments list with `replyComments[comments.length - 1]`, indexing the reply array by the comments length. With 1 comment and 1 reply it indexes `[1]` on a 1-element list. | `content_ideas.dart:1144-1146` | Unreached today only because the function has no caller |

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
| 3.13 | **A real import cycle containing `const` initialisers.** `content_ideas.dart:18` imports `quick_content.dart`, which imports `content_ideas.dart`. A cycle forcing lazy init of a `const` throws at runtime, and both `kDefaultHooks` and `kContentBuckets` are `const`. It also means `plan_data.dart`, which only needs `HookIdea`, transitively pulls in all 4,360 lines of `quick_content.dart`. | `content_ideas.dart:18` ↔ `quick_content.dart:11` |

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

**Completely unreferenced files:** `lib/idea_inbox.dart` (308 lines),
`lib/content_library.dart` (292 lines), `lib/slide_prompt_list.dart` (151 lines).

---

## 7. Severity 6, build, config, dependencies

| # | Issue | Evidence |
|---|---|---|
| 7.1 | **`RECORD_AUDIO` is requested but the app never records audio.** It shows on the user's permission list for a capability that does not exist. | `AndroidManifest.xml:49` |
| 7.2 | **iOS will crash on first image pick.** `Info.plist` has no `NSPhotoLibraryUsageDescription`. Bundle ID is still `com.example.reelAudio`. | `ios/Runner/Info.plist`, `project.pbxproj:386` |
| 7.3 | **`hive`, `hive_flutter`, `cupertino_icons` are entirely unused.** `uuid` is used only in `idea_inbox.dart`, which is dead. | `pubspec.yaml:33,41-42,44`; zero imports |
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
| 8.1 | **7 tests, 1 file, and it does not compile.** See 1.2. No mocking library in `dev_dependencies`, so nothing touching `http` or `path_provider` is testable at all. | `test/widget_test.dart` |
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

1. ~~**`watercolor` or `pixar`.**~~ **ANSWERED: `pixar`.** Confirmed against all
   seven renders. Applied everywhere — see §2.1-2.5 and the note below.
2. **Appearance for all seven characters, and both appearance and personality for
   Mumma, Papa, Daadi, Teacher.** You have given personality for Ria, Rio and
   Cuty, now reconciled into `CharacterLibrary`. Personality keeps behaviour
   consistent; appearance keeps the face from drifting. I cannot read your
   artwork, so I need one line each.
3. **Which age range is the audience.** `1.5-5`, `2-6` or `1-4` (§2.8).
4. **Is `bucket` retired or kept?** Ten files still hardcode the bucket ids (§3.11).
5. **Which status ladder wins** across the three enums (§3.5).
5b. **Is Trial Reel a content type or a flag?** Recommend a real type that changes
   generation.
6. **Should `content_ideas.md` actually become the source of truth?** Today it is a
   mirror. Making it real needs an asset-bundled loader or a build step that
   generates `content_ideas.dart` from it.

---

## 11. Revised order of work

The audit changed the order. Items 1.3, 1.4 and 1.6 are one-line or few-line
fixes to live defects and go first, before any architecture work, because every
later change is built on the same call and parse paths.

**Stage A, live defects. Small, independent, verifiable.**
1.1 INTERNET permission · 1.3 TTS retry key · 1.6 lite model id ·
1.4 quality-report round trip · 1.9 `toQuickIdea` RangeError ·
1.2 test compile · 5.2 thinkingConfig on the four big calls ·
1.7 signing config and applicationId

**Stage B, stop the data loss.** 1.5 delete `idea_inbox.dart` ·
delete `slide_prompt_list.dart` · 1.8 rotate keys, delete `backend/` ·
5.4 make the posting pack persistable · 4 fix `migrateBucketId` scope

**Stage C, one source of truth.** **Style half is done (Phase 1).** What remains
is smaller than first scoped, because the personality sets, the lock block and
`visualPromptSpec` are already consolidated. Still open:
`buildBrandContext` double-injecting the lock block (2.6) · the static
`hashtagPool.take(5)` injection (2.9) · the CTA menu injection that fights the
CTA rule (2.11) · the audience age conflict (2.8).

**Stage D, one generator.** Point 6 and Point 3. Migrate `PostDetails`,
`ContentPackage`, `QuickIdea` and `ParsedPostPackage` to one package type · pick
one caption spec · pick one quality checker · delete `caption_generator.dart` and
the standalone generators · wire the fallback that already exists (3.8) ·
fix the discarded `script` (5.1) · add `imageReel` and `story` to `ContentFormat`
· unblock the series axis (2.13).

**Stage E, the library and the six tabs.** Point 7, 8, 9. Real `.md` loader ·
Series / Format / Production / Goal on every idea · format recommendation with
reasoning · the four missing tabs.

**Stage F, cleanup.** Generic JSON store to absorb the ~496 duplicated lines ·
remove unused dependencies · resolve the import cycle by moving `QuickIdea` out
of `quick_content.dart` · README · CI on this branch · tests.

---

## Log

| Date | Point | Result |
|---|---|---|
| today | **Phase 1** | 3D Pixar unified. `BrandDefaults.visualStyle` is now the only definition and `prompts.dart:_style` reads it. Duplicate `defaultVisualStyle` deleted. `visualPromptSpec` characters derived from the library. `kScriptShapeRules` personality block removed and made `final`. The same wording turned out to be hardcoded in **5 more files**, so 30 occurrences were replaced. 95 → 93 issues, 0 errors, APK builds |
| today | audit | 9 critical, 13 brand contradictions, 13 duplications, 9 generation bugs, 10 config, 11 hygiene. 4 of 6 target tabs do not exist |
| today | v5 | Wrote the full audit here. Corrected four of my own earlier wrong claims in §0 |
| today | v4 | Four pillars, 16-field schema, 33 new ideas, master prompt, six-tab structure |
| today | v3 | Idea Library created. Generators merged into one Create Content |
| today | v2b | Found all 7 character images. `brand_system` is missing 4 of them |
| today | **1** | Done, plus the thinking-budget bug found while testing |
| today | **2** | Done. Single ideas file, one bucket list, `community` created |
