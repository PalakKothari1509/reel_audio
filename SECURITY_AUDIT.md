# Security Audit

**Date:** 2026-10-09  
**Scope:** API keys, secrets, and credentials in the reel_audio Flutter project.

---

## Executive Summary

The project stores API keys in Dart source code compiled into the APK. This is **not safe for release keys** — an APK is fully reversible. However, the keys themselves are not committed to git (`.gitignore` excludes `secrets.dart`). The OpenAI key that was in `backend/` was never committed and the directory has been deleted.

**Status:**
- `backend/` OpenAI key — **safe**: never in git, directory deleted
- `geminiApiKey` — **exposed in APK**: hardcoded in `lib/secrets.dart`
- `elevenLabsApiKey` — **exposed in APK**: hardcoded in `lib/secrets.dart`
- `elevenVoiceId` — **not a secret**: public voice identifier

---

## Key Inventory

### 1. Gemini API Key (`geminiApiKey`)

| Property | Value |
|---|---|
| **Stored in** | `lib/secrets.dart` (line 1) |
| **Hardcoded** | Yes (40-char `AQ.`-prefixed key) |
| **Format** | Google API key |
| **Purpose** | Text-to-speech via Gemini, image generation, content generation |
| **Used in** | `main.dart`, `gemini_client.dart`, `production_adapter_impl.dart`, `caption_generator.dart`, `prompt_builder.dart`, `story_ideas.dart`, `voice.dart` (~20 call sites) |
| **Settings override** | `settings_screen.dart` stores `gemini_api_key` in SharedPreferences, but this override is **only honored in Settings screen and `ai_content_service_impl.dart`** — most of the app ignores it |
| **In git** | No (`secrets.dart` is gitignored) |
| **In APK** | Yes — compiled into native code, easily extracted |
| **Safe to keep** | No — rotate before Play Store release |

**Finding:** A new `ApiKeyStore` class centralizes all key resolution. Every
code path through `ApiKeyStore` honors the Settings-screen override,
including: `main.dart` (story checker, story generator, combined call),
`prompt_screen.dart` (prompt generator), `posting_kit.dart` (reply assistant),
`caption_generator.dart`, `production_adapter_impl.dart` (via factory).
The `geminiApiKey`/`elevenLabsApiKey` constants in `secrets.dart` are now
only read from within `ApiKeyStore` itself.

**Remaining gap:** `elevenLabsApiKey` still has no Settings-screen override
— it always uses the default key.

### 2. ElevenLabs API Key (`elevenLabsApiKey`)

| Property | Value |
|---|---|
| **Stored in** | `lib/secrets.dart` (line 2) |
| **Hardcoded** | Yes (32-char `sk_`-prefixed key) |
| **Format** | Standard ElevenLabs key |
| **Purpose** | Text-to-speech voice generation |
| **Used in** | `production_adapter_impl.dart`, `voice.dart` |
| **Settings override** | None — always uses hardcoded key |
| **In git** | No (`secrets.dart` is gitignored) |
| **In APK** | Yes — compiled into native code |
| **Safe to keep** | No — rotate before Play Store release |

### 3. ElevenLabs Voice ID (`elevenVoiceId`)

| Property | Value |
|---|---|
| **Stored in** | `lib/secrets.dart` (line 3) |
| **Value** | `EXAVITQu4vr4xnSDxMaL` ("Aria" multilingual) |
| **Secret?** | No — voice IDs are public identifiers |
| **In git** | No (`secrets.dart` is gitignored), but exists in `secrets.example.dart` |

### 4. OpenAI API Key (was in `backend/`

| Property | Value |
|---|---|
| **Location** | `backend/.env` (deleted) |
| **In git** | No — `.gitignore` ignored `.env` files |
| **Git history** | Never committed. The `backend/.gitignore` with `.env` pattern was tracked, but the `.env` file itself was never added to git. |
| **Status** | Directory deleted in commit `8047e4a`. Key was only ever on disk. |
| **Safe** | Yes — no rotation needed since it was never in git or source code |

---

## Git History Safety

Checked all commits containing `backend/`:
- `3647620` — contained only `backend/.gitignore`
- No `.env` or `backend/` directory with keys was ever committed

The OpenAI key is **confirmed safe** — it never existed in the repository's git history.

---

## Threats

1. **APK key extraction:** Both the Gemini and ElevenLabs keys are compiled into the app binary. Anyone with the APK can extract them using tools like `apktool` + `grep` for strings, or by instrumenting the native calls.
2. **Settings override broken:** Users who change the Gemini key in Settings will find that most features still use the old hardcoded key. This creates a false sense of security.
3. **Debug build APK:** Currently signed with the debug key (`com.example.reel_audio`), so even the signing isn't release-grade.

---

## Remediation Plan

### Immediate (before any public release)

1. **Rotate both keys** (`geminiApiKey`, `elevenLabsApiKey`) — they have been exposed in this repository's code (in `secrets.dart`), even though that file is gitignored. The keys should be considered potentially compromised.
2. **Move keys to runtime configuration:** Store keys in Android's native secrets manager or a secure backend endpoint. The Flutter app should fetch the key at runtime, not embed it.
3. **Fix Settings override:** Make all ~20 call sites use a centralized `ApiKeyStore` that prioritizes:
   1. User-configured key from Settings (SharedPreferences)
   2. Fallback to a minimal default if needed

### Short term

4. **Verify the `backend/` deletion is permanent** in git by running `git gc` and checking `git log --all --full-history -- backend/` returns nothing — done, it only ever contained `.gitignore`.
5. **Add `secrets.dart` to `.gitkeep`-style instructions** — already documented in `secrets.example.dart`.

### Long term

6. **Backend proxy:** Route all AI API calls through `backend/` (or a new serverless function). This is explicitly deferred — "Do not build a new backend yet; first understand what exists."
