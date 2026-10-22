# 04 — AI & Media Generation

## Overview
The app uses three external services for media generation:
1. **Google Gemini** — text generation (stories, captions, prompts) and TTS audio synthesis
2. **ElevenLabs** — premium TTS voice synthesis
3. **FFmpeg** — video composition and processing

**All HTTP requests go through a single path**: `geminiPost()` in `lib/gemini_call.dart`.

---

## 1. Gemini (Text Generation)

### Primary: `geminiPost()` in `lib/gemini_call.dart` (210 lines)

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

### Model Selection (from content files)

| File | Model Constant | Usage |
|------|---------------|-------|
| `caption_generator.dart:29` | `gemini-3.5-flash` | Small jobs (caption generation) — lighter model to preserve budget |
| `caption_generator.dart:30` | `gemini-3.8-flash` | Full jobs — higher quality outputs |
| `voice.dart:48` | `gemini-2.5-flash-preview-tts` | Gemini TTS audio synthesis |
| `gemini_call.dart:155` | Dynamic via `geminiPost(model: ..., fallbackModel: ...)` | Any text generation |

> **Note**: `google_generative_ai: ^0.4.0` is listed in pubspec.yaml but is **not used** — `gemini_call.dart` uses the `http` package directly. The SDK import is unused.

### `geminiBusyMessage()` — UX Strings

```dart
String geminiBusyMessage(int statusCode, [String body = ''])
```

Returns user-friendly messages:
- **503**: "Gemini is overloaded right now. This is at their end and usually passes in a minute or two. Your story is saved — try again shortly."
- **Daily limit**: "Today's free Gemini requests are used up. They reset tomorrow. Your story is saved, so nothing is lost."
- **Generic 429**: "Gemini has run out of free requests for the moment. Your story is saved, so nothing is lost — wait a minute and tap it again."

### Call Sites for `geminiPost()`

| File | Function | Model Used |
|------|----------|------------|
| `caption_generator.dart` | `generateCaption()` | `gemini-3.5-flash` (small) / `gemini-3.8-flash` (full) |
| `gemini_video_master_prompt.dart` | `generateVideoPlan()` | Dynamic (passed as parameter) |

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
6. **400 = switch models** (Path A only): "Model rejected request — switching to next model..."
7. **Path B has no fallback**: 400/429/503 → immediate hard failure (no retry, no switch)

---

## 5. Two Parallel Gemini Code Paths (CORRECTION)

### Path A: Raw HTTP via `geminiPost()` — `lib/gemini_call.dart` (210 lines)

All text generation calls from `content_studio_service.dart` go through `geminiPost()` with:
- Primary model: `gemini-3.8-flash` (content_studio_service.dart:18)
- Fallback chain: `gemini-3.7-flash` → `gemini-3.6-flash` → `gemini-3.5-flash` → `gemini-2.5-flash` (content_studio_service.dart:27-32)
- Full retry, backoff, 429 detection, model fallback (404 cache, 400 model switch)
- **Call sites using this path**: `content_studio_service.dart` (6 calls), `caption_generator.dart` (409:), `story_ideas.dart` (4 calls), `prompt_builder.dart` (2 calls), `main.dart` (1 call)

### Path B: SDK via `google_generative_ai` — `lib/gemini_client.dart` (381 lines)

**This is NOT an empty stub.** It's 381 lines that implements `AIProvider` using the `google_generative_ai` package directly:
- Model: `gemini-3.5-flash-lite` (gemini_client.dart:17) — **NOT** the same as Path A
- **No retry, no fallback, no backoff** — the comment at line 12-14 explicitly says it "gets none of that helper's model fallback and 404 handling"
- Used by `AiContentServiceImpl` (created at main.dart:96)
- `AiContentServiceImpl` is created but only appears in main.dart — **verify if actually used in any screen flow**

**400 Error Risk**: Path B (`gemini_client.dart`) uses `gemini-3.5-flash-lite` with no fallback. If this model returns 400, the call fails immediately with no retry. This is likely the source of the user's intermittent failures ("works 2 out of 10 times").

### Path B Call Sites
- `main.dart:96` — creates `AiContentServiceImpl(GeminiClient(...))`
- `AiContentServiceImpl` implements `AiContentService` (ai_content_service_impl.dart)

> **Finding**: Two Gemini code paths exist with different models, different error handling, and different callers. Path B has zero retry/fallback — any 400/429/503 is a hard failure.

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
