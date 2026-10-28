# Fun Learning With Palak — Content Studio

A Flutter app for making short-form educational content for Indian parents of
children aged **1–4**. It is a content decision system that happens to generate
content: the hard part is knowing what to make, why it exists, how to produce it,
and what to learn from the result.

**Pipeline:** IDEA → FORMAT → CONTENT PACKAGE → CREATIVE → POST → TRACK

---

## What exists

- **Idea Vault** — 57 ideas in `content_ideas.md`, each classified on seven
  axes: pillar, series, content type, narrative format, production method,
  goal, status. 10 Navratri Reel ideas (N1–N10) recently added.
- **Create** — one `Create Content` action. A finished post is one package:
  hook, script, narration, per-scene dialogue, caption, CTA, hashtags.
- **Reel Maker** — the existing end-to-end video pipeline (FFmpeg). Works;
  left as is. `StoryScreen` includes character selection (chip selector,
  defaults to Ria/Rio/Cuty) passed to `generateEverything()`.
- **Promotion Comments** — a vault of saved comment lines.
- **Brand** — character lock for eight characters: Ria (pigtails, pink star dress), Rio (blue kurta), Cuty (white bunny, pink bow), Robot (friendly AI), Mumma (yellow kurta, blue jeans), Papa (light blue kurta), Daadi (cream saree), and Teacher (blue kurta with book), with the 3D Pixar/Disney visual style injected into every prompt so characters look identical in every scene.

Not built yet, deliberately: Calendar, Analytics, Experiments. They answer
questions the data cannot yet support — see `REDESIGN_PLAN2.md`.

## Content system

- `content_formats.md` — source of truth for the 50 narrative formats (16 verified, 34 app-authored).
  `lib/format_handbook.dart` is generated from it:
  `dart run tool/sync_formats.dart`
- `content_ideas.md` — the hand-authored idea library. Never edited by a tool
  without a backup (`content_ideas.md.bak`).
- `tool/` — domain validation: `check_formats`, `check_axes`, `check_pillars`,
  `check_ideas`, `reach_mechanics`, `review_sheet`, `classify_ideas`,
  `propose_formats`, `propose_axes`, `show_ideas`.

Classification follows one rule: **automation proposes; a human approves.**
Only `approved` decisions in `tool/*_decisions.csv` are ever written to the
library. A wrong pillar is invisible later — it quietly misfiles six months of
performance data.

## Reach mechanics

No viral scores. Every idea is checked mechanically, with honest answers:
share trigger (who sends this to whom, and why), open loop, no-voice
compatibility, visual-first, one-second recognition, production simplicity.
Each is `pass` / `fail` / `unknown` — never a number. A format earns its place
after 5 real tests (`1/5 … 5/5`), and one post never condemns a format.

## Security

- All API keys (Gemini, ElevenLabs) are centralized in `ApiKeyStore`
  (`lib/api_key_store.dart`), which honors the user key configured in
  Settings before falling back to defaults.
- Keys are stored in `lib/secrets.dart` (git-ignored). Keys inside an APK can
  be extracted — rotate before release.
- The `backend/` directory has been removed entirely. It held an OpenAI key
  that was **never committed** to git (it was in a git-ignored `.env` file);
  no rotation is needed. See `SECURITY_AUDIT.md` for the full audit.

## Setup

```bash
flutter pub get
cp lib/secrets.example.dart lib/secrets.dart   # then fill in real keys
```

`lib/secrets.dart` is git-ignored.

## Development

```bash
flutter test                 # ~550 tests (505 unit + 44 widget)
flutter analyze              # lib/ is clean; tool/ has known warnings
dart run tool/check_formats.dart
dart run tool/check_axes.dart
dart run tool/check_pillars.dart
dart run tool/check_ideas.dart
dart run tool/reach_mechanics.dart
dart run tool/review_sheet.dart   # regenerates tool/review_sheet.md
```

On-device debugging uses wireless ADB: `.\run_phone.ps1` from PowerShell (the
phone must be on the `JayJinendra_5G` network).

## Build

```bash
flutter build apk --release
```

Release signing and the application id (`com.example.reel_audio`) are not yet
configured — the app is not distributable until they are.
