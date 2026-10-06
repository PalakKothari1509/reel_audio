# Fun Learning With Palak — Content Studio

A Flutter app for making short-form educational content for parents of
children aged **1–4**. It is a content decision system that happens to
generate content: the hard part is knowing what to make, why it exists,
how to produce it, and what to learn from the result.

Pipeline: **IDEA → FORMAT → CONTENT PACKAGE → CREATIVE → POST → TRACK**

## What exists

- **Idea Vault** — 57 ideas in `content_ideas.md`, each classified on
  seven axes: pillar, series, content type, narrative format, production
  method, goal, status.
- **Create** — one `Create Content` action. A finished post is one
  package: hook, script, narration, per-scene dialogue, caption, CTA,
  hashtags.
- **Reel Maker** — the existing end-to-end video pipeline (FFmpeg).
  Works; left as is.
- **Promotion Comments** — a vault of saved comment lines.
- **Brand** — character lock (Ria, Rio, Cuty, Mumma, Papa, Daadi,
  Teacher) and the 3D Pixar/Disney visual style, injected into every
  prompt so a character looks the same in every scene.

Not built yet, deliberately: Calendar, Analytics, Experiments. They
answer questions the data cannot yet support — see
`REDESIGN_PLAN.md`.

## Content system

- `content_formats.md` — source of truth for the 16 narrative formats.
  `lib/format_handbook.dart` is generated from it:
  `dart run tool/sync_formats.dart`
- `content_ideas.md` — the hand-authored idea library. Never edited by
  a tool without a backup (`content_ideas.md.bak`).
- `tool/` — domain validation: `check_formats`, `check_axes`,
  `check_pillars`, `check_ideas`, `reach_mechanics`, `review_sheet`,
  `classify_ideas`, `propose_formats`, `propose_axes`, `show_ideas`.

Classification follows one rule: **automation proposes; a human
approves.** Only `approved` decisions in `tool/*_decisions.csv` are
ever written to the library. A wrong pillar is invisible later — it
quietly misfiles six months of performance data.

## Reach mechanics

No viral scores. Every idea is checked mechanically, with honest
answers: share trigger (who sends this to whom, and why), open loop,
no-voice compatibility, visual-first, one-second recognition,
production simplicity. Each is `pass` / `fail` / `unknown` — never a
number. A format earns its place after 5 real tests (`1/5 … 5/5`),
and one post never condemns a format.

## Setup

```bash
flutter pub get
cp lib/secrets.example.dart lib/secrets.dart   # then fill in real keys
```

`lib/secrets.dart` is git-ignored. Provider keys (Gemini, ElevenLabs)
must be rotated before any release — keys inside an APK can be
extracted. `backend/` holds an unreferenced OpenAI key and no source
code; it is pending removal.

## Development

```bash
flutter test                 # 33 tests
flutter analyze              # lib/ is clean; tool/ has known warnings
dart run tool/check_formats.dart
dart run tool/check_axes.dart
dart run tool/check_pillars.dart
dart run tool/check_ideas.dart
dart run tool/reach_mechanics.dart
dart run tool/review_sheet.dart   # regenerates tool/review_sheet.md
```

On-device debugging uses wireless ADB: `.\run_phone.ps1` from
PowerShell (the phone must be on the `JayJinendra_5G` network).

## Build

```bash
flutter build apk --release
```

Release signing and the application id (`com.example.reel_audio`) are
not yet configured — the app is not distributable until they are.
