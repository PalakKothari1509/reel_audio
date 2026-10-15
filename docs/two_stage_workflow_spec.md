# Two-Stage Content Workflow — Implementation Spec

**Status:** Implemented and tested. This document describes the shipped code.

## Overview

Content creation is split into two stages:

- **Stage 1** — Base idea with story beats, no timing. Stored in
  `content_ideas.md` and loaded into the app as a `BeatSheet`. No length
  decision yet.
- **Stage 2** — When you pick an idea + length, generate N self-contained
  10-second clip prompts. Each prompt includes style, size, characters,
  camera, timed action, audio, avoid rules, and a continuity line for
  Parts 2+.

---

## Stage 1: Beats Model

### `BeatSheet`

File: `lib/story_ideas.dart`

No timing. Just the story shape. This is the leanest possible representation.

```dart
class BeatSheet {
  final String id;
  final String title;
  final List<String> characters;
  final String where;
  final String hook;
  final String beat1Setup;
  final String beat2Problem;
  final String beat3Escalation;
  final String beat4Turn;
  final String beat5Payoff;
  final String? stretchBeat;
  final String endingLine;
  final String closingCta;
  final List<String> hashtags;
  final int? bestLength;

  const BeatSheet({...});
}
```

`hasStretchBeat` is `true` when `stretchBeat` is non-null and non-blank.
`beats` exposes the five core beats at indices 0–4.

---

## Stage 2: Duration → Parts

File: `lib/story_reel_builder.dart`

```dart
int partsForLength(int seconds) => (seconds / 10).round();
```

| Reel length | Number of prompts |
| ----------- | ----------------: |
| 20 seconds  |                 2 |
| 30 seconds  |                 3 |
| 40 seconds  |                 4 |
| 60 seconds  |                 6 |

### `PartBeatMapping`

```dart
PartBeatMapping beatIndicesForParts(int seconds);
```

Beat indices: 0=setup, 1=problem, 2=escalation, 3=turn, 4=payoff.
Sentinel values: `-1` = stretch beat if present, `-2` = extra escalation or
reaction beat, `-3` = payoff buffer / ending.

| Length | Part 1 | Part 2 | Part 3 | Part 4 | Part 5 | Part 6 |
| --- | --- | --- | --- | --- | --- | --- |
| 20s | [0,1,2] | [3,4] | — | — | — | — |
| 30s | [0,1] | [2,-1] | [3,4] | — | — | — |
| 40s | [0,1] | [2,-1] | [-2,3] | [4,-3] | — | — |
| 60s | [0,1] | [2,-1] | [-2,3] | [3,4] | [4,-3] | [-3,4] |

The 60s mapping spreads the 30s structure across six parts. Adjacent parts
share a beat at the cut point, so the turn and the payoff each span two
clips instead of being squeezed into one.

Unsupported durations throw `ArgumentError`.

---

## Stage 2: Video Prompt Builder

File: `lib/story_reel_builder.dart`

```dart
List<VideoClipPrompt> buildVideoPrompts({
  required BeatSheet beats,
  required int seconds,
});
```

Each prompt is self-contained, so it can be copied independently into
Gemini's video-generation workflow.

### Prompt structure

Every prompt includes these sections:

| Section | Required content |
| --- | --- |
| STYLE | Soft 3D Pixar/Disney-style render, warm natural lighting, semi-realistic quality |
| SIZE | Vertical 9:16 (1080x1920), bottom 20% clear for Instagram overlay |
| CHARACTERS | Only the selected characters, identified by reference images |
| SETTING | Specific location and relevant objects |
| CAMERA | Vertical 9:16 composition and suitable framing |
| ACTION | 0–4s, 4–8s, and 8–10s, all derived from the story beats |
| AUDIO | Hinglish narration describing the action, plus matching sound effects |
| AVOID | Glasses on Ria or Rio, unwanted characters, visual inconsistencies |
| CONTINUITY | Required for Parts 2 onward |

### Action timing

Every prompt describes meaningful action throughout all three intervals.
A part with fewer beats than intervals develops the beat along the story's
natural order rather than repeating the same sentence three times.

### Character lock

Only the selected characters may appear. No background characters, bystanders,
extras, or mascots. Ria and Rio must never wear glasses. Reference images
preserve the established faces, hair, outfits, and proportions.

### Continuity

Parts 2 onward include a continuity instruction: the first frame must match
the previous clip exactly (same room, lighting, character positions, and
outfits), and the story must not restart.

---

## Output model

File: `lib/prompts.dart`

```dart
class VideoClipPrompt {
  final int partNumber;
  final int totalParts;
  final String promptText;

  const VideoClipPrompt({...});

  String get title => 'Part $partNumber of $totalParts';
}
```

`buildVideoPrompts` returns this model. `prompt_screen.dart` consumes it
directly — there is one canonical output type for the whole workflow.

---

## Tests

| File | Covers |
| --- | --- |
| `test/beat_sheet_test.dart` | JSON round-trip, `hasStretchBeat`, `bestLength`, `copyWith` |
| `test/parts_calculator_test.dart` | Duration mapping, beat mapping per length, unsupported durations throw |
| `test/video_prompt_builder_test.dart` | Part count, numbering, completeness, character selection, glasses rule, continuity, self-contained prompts, no repeated action |

Run: `flutter test`