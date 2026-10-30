# 04 — AI & Media Generation

## Overview
The app uses three external services for media generation:
1. **Google Gemini** — text generation (stories, captions, prompts) and TTS audio synthesis
2. **ElevenLabs** — premium TTS voice synthesis
3. **FFmpeg** — video composition and processing

Gemini text generation currently has two transports:

- The raw HTTP path through `geminiPost()` is used by live generation flows.
- The `google_generative_ai` SDK path remains available through a lazily created
  `GeminiClient`, but `getAiContentService()` currently has no call sites.

Both paths remain in the codebase. Their model selection and some fallback
behavior differ; this document records the current behavior rather than implying
that they are interchangeable.

---

## 1. Gemini Text Generation

### Live path: raw HTTP via `geminiPost()` in `lib/gemini_call.dart`

```dart
Future<http.Response> geminiPost({
  required String model,
  required String apiKey,
  required String body,
  required Duration timeout,
  String? fallbackModel,
  void Function(String message)? onWait,
})
```

**URL pattern**: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`

**Key design decisions**:
- API key sent in `x-goog-api-key` **header**, never in query string (avoids leaking into proxy logs/crash reports)
- Retryable status codes: `{429, 500, 503}`
- Non-retryable: any other 4xx (except 404 with fallback) treated as real errors

### Retry Behavior

Retry backoff sequence: `[4s, 10s, 20s, 30s]` (4 attempts total in the `_backoff` loop)

Between retries, the app:
1. Checks if Google specified a delay: `googlesRetryDelay()` parses two formats:
   - JSON `"retryDelay": "19s"` — clamps to 1–60 seconds + 1 second buffer
   - SDK `"Please retry in 7h27.19s"` — parses hours/minutes, or seconds
2. If Google provides no delay, uses the fallback from `_backoff`
3. Calls `onWait?.call('Gemini is busy — trying again in ${left}s...')` with countdown (1s per second)

### Special Cases

| Status | Condition | Action |
|--------|-----------|--------|
| 404 | First attempt only | One-time fallback to `fallbackModel`, caches model name in `_missingModels` (persisted to `missing_models.json` for 7 days) |
| 429 | `isDailyLimit(body)` true | Stops retrying immediately — "out for the day" |
| 429 + PerDay | Body contains `PerDay` | Daily limit exhausted |
| 429 + free_tier | Delay > 5 minutes | Daily limit exhausted |
| 503 | — | Retries with backoff |
| Timeout | — | Not retried — returned as-is (caller handles) |

### Model Selection (per call site)

| File | Model Constant | Usage |
|------|---------------|-------|
| `main.dart` | `gemini-3.5-flash` | Story script generation |
| `caption_generator.dart` | `gemini-3.5-flash` / `gemini-3.8-flash` | Small / full caption jobs |
| `content_studio_service.dart` | `gemini-3.8-flash` / `gemini-3.5-flash` | Main / light jobs; its caller adds a model fallback chain |
| `story_ideas.dart` | `gemini-3.5-flash` / `gemini-3.8-flash` | Light / full jobs |
| `prompt_builder.dart` | `gemini-3.5-flash` | Prompt construction |
| `voice.dart:48` | `gemini-2.5-flash-preview-tts` | Gemini TTS audio synthesis |
| `gemini_call.dart:155` | Dynamic via `geminiPost(model: ..., fallbackModel: ...)` | Any text generation |

There is not yet a shared model-selection configuration. Most call sites choose
their own primary model. `geminiPost()` can switch to a supplied fallback after a
404; `content_studio_service.dart` additionally tries other models after selected
model errors (including per-minute 429, 400, 404, and 503).

### SDK path: `GeminiClient` in `lib/gemini_client.dart`

`GeminiClient` implements `AIProvider` using `google_generative_ai`. It is only
constructed by `getAiContentService()` in `main.dart`; repository search found
no caller of that getter, so this is currently an available but dormant path.
`AiContentServiceImpl` adapts its legacy `ContentPackage` output to the newer
generation model.

- Primary model: `gemini-3.5-flash-lite`; one 404 fallback: `gemini-3.5-flash`.
- Retryable status codes share `retryableStatusCodes`, `backoffDurations`,
  `googlesRetryDelay()`, and `isDailyLimit()` with the HTTP helper.
- Retries 429/500/503 with the shared backoff and stops immediately for a
  detected daily limit. A timeout is surfaced without retrying.
- Unlike `geminiPost()`, the SDK wrapper does not persist/cache 404'd model names.
- Other recognized errors are surfaced; there is no SDK-side template fallback.
  `AIProviderWithFallback` can provide a local template fallback, but it has no
  construction sites in the current `lib/` tree.

The SDK primary (`gemini-3.5-flash-lite`) differs from the main HTTP flow's
`gemini-3.5-flash`; `GeminiClient.providerName` also currently reports
“Gemini 3.6 Flash.” Do not treat these labels as a single source of truth.

### `geminiBusyMessage()` — UX Strings

```dart
String geminiBusyMessage(int statusCode, [String body = ''])
```

Returns user-friendly messages:
- **503**: "Gemini is overloaded right now. This is at their end and usually passes in a minute or two. Your story is saved — try again shortly."
- **Daily limit**: "Today's free Gemini requests are used up. They reset tomorrow. Your story is saved, so nothing is lost."
- **Generic 429**: "Gemini has run out of free requests for the moment. Your story is saved, so nothing is lost — wait a minute and tap it again."

### Live call sites for `geminiPost()`

| File | Function | Model Used |
|------|----------|------------|
| `caption_generator.dart` | `generateCaption()` | `gemini-3.5-flash` (small) / `gemini-3.8-flash` (full) |
| `content_studio_service.dart` | generation methods | `gemini-3.8-flash`, then call-site model chain |
| `main.dart` | story script generation | `gemini-3.5-flash` |
| `prompt_builder.dart` | prompt generation | `gemini-3.5-flash` |
| `story_ideas.dart` | idea/check generation | `gemini-3.5-flash` / `gemini-3.8-flash` |

### Model Caching (`_missingModels`)

- In-memory map + persisted to `{appDocsDir}/missing_models.json`
- Persists for 7 days, then forgotten
- Prevents retrying 404'd model names on every app open

---

## 2. ElevenLabs (Premium TTS)

### Engine: `VoiceEngine.elevenLabs` in `lib/voice.dart` (455 lines)

```dart
enum VoiceEngine { phone, gemini, elevenLabs }
```

- **Label in UI**: `🎧 ElevenLabs`
- **Hint**: "Best quality, about 25 reels a month free."
- Used via `VoiceEngine` enum — three engines behind one call path
- `phone` is the default/fallback (Flutter's `flutter_tts`), `gemini` is mid-tier, `elevenLabs` is premium

> **UNVERIFIED**: ElevenLabs HTTP endpoint details — voice.dart defines the enum and model constants but the actual HTTP call implementation was not fully verified in this audit. See `voice.dart` for full implementation.

### Gemini TTS

- **Model**: `gemini-2.5-flash-preview-tts` (defined at `voice.dart:48`)
- Comment confirms: "Google resolves this to gemini-2.5-flash-tts"
- Free tier, reads whole story in one take

---

## 3. FFmpeg (Video Processing)

### Primary file: `lib/video_builder.dart` (743 lines)

```dart
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
```

### Key Constants (video_builder.dart:11-26)

| Constant | Value | Purpose |
|----------|-------|---------|
| `kVideoWidth` | 1080 | Portrait 1080x1920 (Reels/Shorts/TikTok) |
| `kVideoHeight` | 1920 | Portrait |
| `kFps` | 30 | Frames per second |
| `kMinClipSeconds` | 1.0 | Min seconds per image clip |
| `kTailSeconds` | 1.5 | Silence after last spoken word |
| `kEndcardSeconds` | 3.5 | Brand card duration |

### FFmpeg Usage Pattern

The app uses `ffmpeg_kit_flutter_new` (v4.6.2):
- `FFmpegKit` — for video composition commands
- `FFprobeKit` — for probing media metadata (duration, dimensions)
- `ReturnCode` — for checking command success/failure

### Video Build Pipeline

```
Text script → TTS audio (voice.dart) → Audio track
Image slides → FFmpeg composition → Video
Audio + Video → FFmpeg merge → Final video
```

### Instagram Compliance

From `video_builder.dart` comments: Instagram overlays its own UI (header, profile, CTAs) at fixed screen positions. The composition accounts for this by:
- Keeping visual content centered
- Respecting safe margins for text/important elements
- Positioning elements to avoid Instagram's UI overlay zones

---

## 4. Quota & Error Handling Summary

| Provider | Daily Free Limit | Quota Exhausted Signal | App Behavior |
|----------|-----------------|----------------------|--------------|
| Gemini | Per-model, varies | `PerDay` in error body, `retryDelay` > 5 min | Stops retrying, shows "resets tomorrow" message, saves story |
| ElevenLabs | ~25 reels/month | UNVERIFIED | UNVERIFIED fallback behavior |
| FFmpeg | None (local) | Process return code | Retry via FFmpeg return code check |

### Error Handling Principles (from code comments)

1. **503 is not a bug**: It means the model is temporarily overloaded — retrying is the correct response
2. **Google's delay wins**: When Google says "retry in 19s", the app waits 19 seconds, not a guess
3. **429 has two meanings**: Per-minute (retry) vs per-day (stop) — the app distinguishes them
4. **Timeout is not retried**: A request that timed out will usually time out again
5. **Missing models cached**: 404'd model names are remembered for 7 days
6. **400 is call-site-specific**: `geminiPost()` returns it without retry; the
   Content Studio caller may then try another model. The SDK path surfaces it.
7. **Fallback layers differ**: HTTP call sites may provide a model chain; the SDK
   wrapper has one 404 fallback and does not fall back to local templates.

---

## 5. Transport and Error Policy Summary

| Concern | Raw HTTP (`geminiPost`) | SDK (`GeminiClient`) |
|---------|-------------------------|----------------------|
| Current use | Live call sites listed above | Dormant; getter has no caller |
| Model source | Selected by each caller | SDK primary and fallback constants |
| Retry | 429/500/503, shared four-delay backoff; daily 429 stops | Same retryable codes and backoff helpers; daily 429 stops |
| 404 | Optional caller-supplied fallback; failed primary is cached for 7 days | One fallback model; no persistent missing-model cache |
| Other 4xx | Returned to caller without retry | Converted from SDK exception and surfaced |
| Timeout | Not retried; caller handles timeout | Not retried; converted to a user-facing busy message |
| Local content fallback | Not in the transport; some callers have their own fallback behavior | No local template fallback in `GeminiClient`; `AIProviderWithFallback` is currently uninstantiated |

Model choice, request configuration, and fallback chains are not yet centralized.
The two transports share retry/quota helpers, but they are not behaviorally
identical. Keep both until their callers and compatibility requirements are
reviewed; this stabilization task does not remove either transport or make API
requests.

---

## 5. Prompt Sources

| Generator | Prompt Source File |
|-----------|-------------------|
| Captions | `caption_generator.dart` (kCaptionSpec rules) |
| Video plan | `gemini_video_master_prompt.dart` |
| Story expansion | `master_prompt.dart` |
| Slide prompts | `slide_prompts.dart` |
| AI content | `ai_content_service_impl.dart` |

---

## 6. Offline Generation (No API Required)

When the app is offline or the user doesn't have API access, the app can generate content locally:

### OfflineStoryGenerator (`lib/story_generator_offline.dart`)

```dart
GeneratedStory generate()
```

1. Loads all hooks from `kDefaultHooksWithRewrite` (via `HookStore.load()`)
2. Picks a random hook
3. Extracts story fields from the hook's moment fields (`setting`, `sceneDetail`,
   `dialogue`, `mess`, `innerThought`, `endingBeat`) with `storyDetail` label
   parsing as fallback
4. Uses `hook.defaultCast` for characters, or falls back to a random selection
5. Returns a `GeneratedStory` with all moment fields populated

**Key rules:**
- `_buildHook()` uses `hook.opening` deterministically — no random templates
- `_buildHookOptions()` draws from real moment fields, not fabricated text
- Labels are parsed literally: `Worse:` != `Resolution:`, `Ending:` != `Moral:`

### OfflineVideoPromptGenerator (`lib/video_prompt_generator_offline.dart`)

```dart
GeminiVideoResult generateFromStory(GeneratedStory story, {
  required int totalSeconds,
  required List<String> characters,
})
```

Produces 2-6 video part prompts (10s each) using beat remapping:
`problem` -> `twist` -> `worse` -> `solution`

- Part 1 purpose: "The moment itself, mid-action. No setup, no context."
- Middle parts: "Escalation -- the situation gets worse and stays worse."
- Last part: "Closing image only. Hold the frame. No lesson, no summary, no card text."

Uses `generateOnScreenText()` from `hook_system.dart` for deterministic overlays
(part 1 title only, 5-word cap, never drawn by the video model).
