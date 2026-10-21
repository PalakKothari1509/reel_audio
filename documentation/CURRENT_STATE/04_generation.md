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

---

## 5. Prompt Sources

| Generator | Prompt Source File |
|-----------|-------------------|
| Captions | `caption_generator.dart` (kCaptionSpec rules) |
| Video plan | `gemini_video_master_prompt.dart` |
| Story expansion | `master_prompt.dart` |
| Slide prompts | `slide_prompts.dart` |
| AI content | `ai_content_service_impl.dart` |
