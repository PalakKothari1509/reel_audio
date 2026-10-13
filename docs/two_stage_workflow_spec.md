# Two-Stage Content Workflow — Implementation Spec

## Overview

Split content creation into two stages:

- **Stage 1** — Base idea with story beats (no timing). Stored in `content_ideas.md`
  and loaded into the app as a `StoryIdea`-like model. No length decision yet.
- **Stage 2** — When you pick an idea + length, generate N 10-second clip prompts.
  Each prompt is self-contained (style, size, characters, continuity line).

---

## Stage 1: Beats Model

### New data class: `BeatSheet`

File: `lib/story_ideas.dart` (add below `StoryIdea`)

No timing. Just the story shape. This is the leanest possible representation.

```dart
class BeatSheet {
  final String id;          // e.g. 'life-jugaad-fail-box-win'
  final String title;       // e.g. 'Jugaad Fail, Box Win! 📦'
  final List<String> characters;  // e.g. ['ria', 'mumma', 'rio', 'cuty']
  final String where;       // e.g. 'Living room'
  final String hook;        // one-liner
  final String beat1;       // Setup: what's normal at the start
  final String beat2;       // Problem: what goes wrong
  final String beat3;       // Escalation: how it gets worse
  final String beat4;       // Turn: the moment things change
  final String beat5;       // Payoff: the funny or warm ending
  final String? stretchBeat; // optional extra moment between 2 and 4
  final String endingLine;
  final String closingCta;
  final String? caption;
  final List<String> hashtags;  // exactly 5
  final int? bestLength;    // 20 or 30 (null = flexible)

  const BeatSheet({
    required this.id,
    required this.title,
    required this.characters,
    required this.where,
    required this.hook,
    required this.beat1,
    required this.beat2,
    required this.beat3,
    required this.beat4,
    required this.beat5,
    this.stretchBeat,
    required this.endingLine,
    required this.closingCta,
    this.caption,
    this.hashtags = const [],
    this.bestLength,
  });
}
```

### Length → Parts Calculator

File: `lib/story_reel_builder.dart` (add static method)

```dart
/// Returns the number of 10-second parts for a given total length.
/// 20 → 2, 30 → 3, 40 → 4, 60 → 6
static int partsForLength(int seconds) => (seconds / 10).round();
```

### Beat-to-Part Mapping

```dart
class PartBeatMap {
  /// Maps beat indices to parts for a given length.
  ///
  /// 20s (2 parts): [0,1,2] → Part 1, [3,4] → Part 2
  /// 30s (3 parts): [0,1] → Part 1, [2,stretch] → Part 2, [3,4] → Part 3
  /// 40s (4 parts): same as 30s + [reaction] → Part 3-4
  /// 60s (6 parts): extended spread
  static List<List<int>> beatIndicesForParts(int lengthSeconds) {
    final parts = partsForLength(lengthSeconds);
    switch (parts) {
      case 2:
        return [
          [0, 1, 2],   // setup, problem, escalation
          [3, 4],      // turn, payoff
        ];
      case 3:
        return [
          [0, 1],      // setup, problem
          [2, -1],     // escalation + stretch beat (-1 = stretch if present)
          [3, 4],      // turn, payoff
        ];
      case 4:
        return [
          [0, 1],      // setup, problem
          [2, -1],     // escalation + stretch
          [-2, 3],     // second escalation or reaction
          [4, -3],     // payoff + extra
        ];
      default:
        return beatIndicesForParts(30); // fallback
    }
  }
}
```

---

## Stage 2: Video-Prompt Generator

### New method: `buildVideoPrompts`

File: `lib/prompt_builder.dart` (add below existing `buildVideoPrompt`)

Creates N self-contained prompts, one per 10-second part. Uses `StoryBeats`
(existing) + `BeatSheet` (new) + `LengthCalculator`.

```dart
/// Generates N 10-second video prompts from a beat sheet + length.
///
/// Each prompt is standalone: style, size, characters, camera, timed action,
/// and a continuity line for Parts 2+.
List<VideoClipPrompt> buildVideoPrompts({
  required BeatSheet beats,
  required int seconds,
}) {
  final parts = PartBeatMap.beatIndicesForParts(seconds);
  final prompts = <VideoClipPrompt>[];

  for (int i = 0; i < parts.length; i++) {
    final isFirst = i == 0;
    final indices = parts[i];

    final prompt = _buildPartPrompt(
      beats: beats,
      partNumber: i + 1,
      totalParts: parts.length,
      beatIndices: indices,
      isFirstPart: isFirst,
    );

    prompts.add(VideoClipPrompt(
      partNumber: i + 1,
      totalParts: parts.length,
      promptText: prompt,
    ));
  }

  return prompts;
}

String _buildPartPrompt({
  required BeatSheet beats,
  required int partNumber,
  required int totalParts,
  required List<int> beatIndices,
  required bool isFirstPart,
}) {
  final chars = beats.characters.map((id) => CharacterLibrary.byId(id)?.name ?? id).join(', ');

  return '''
Create a 10-second vertical 9:16 animated video clip.

STYLE: ${BrandDefaults.visualStyle}
CHARACTERS: Use the attached reference images for $chars. Match faces, hair and outfits exactly.
No glasses on anyone.
${isFirstPart ? '' : 'CONTINUITY: The first frame must match the attached image (same room, lighting, positions and outfits).'}
SETTING: ${beats.where}
CAMERA: Fixed medium shot at child eye level. Keep characters centred, bottom 20% clear.
ACTION:
0-4s: ${beats.beat2}  // escalation
4-8s: ${beats.beat3}
8-10s: ${isFirstPart ? 'transition to next part' : beats.beat4}  // turn begins
AUDIO: Natural room sound only. No music, no speech, no on-screen text.
AVOID: Distorted hands, changing outfits, text, logos.
''';
}
```

### New data class: `VideoClipPrompt`

```dart
class VideoClipPrompt {
  final int partNumber;
  final int totalParts;
  final String promptText;

  const VideoClipPrompt({
    required this.partNumber,
    required this.totalParts,
    required this.promptText,
  });

  String get title => 'Part $partNumber of $totalParts';
}
```

---

## UI: Parts Screen (Stage 2 output)

File: `lib/prompt_screen.dart` (new tab or new screen)

A new screen that shows N cards, one per Part, each with:
- Title: "Part 1 of 3"
- The full prompt text
- Copy button
- Text area for notes (e.g., "checked last frame — face OK")

Reuses the existing copy-button pattern from `prompt_screen.dart`.

### Integration with StoryReelBuilder

The existing `StoryReelBuilder` already accepts `segmentCount` and
`segmentDurationSeconds`. It forces 10-second scenes. The new approach:

1. User picks a base idea from `content_ideas.md`
2. User picks a length (20/30/45/60)
3. App generates the `BeatSheet` from the idea
4. App calls `buildVideoPrompts(beats, seconds)` to produce N prompts
5. App shows the Parts Screen with copy buttons
6. User pastes each prompt into Gemini (video API), saves results

No new dependencies needed. Uses existing `CharacterLibrary`,
`BrandDefaults`, and prompt infrastructure.

---

## Stage 1: Gemini Prompt for Beat Generation

When you type an idea in the app, the first Gemini call asks for beats, not
timed scenes:

```prompt
Act as a preschool content writer for "Fun Learning With Palak".

THE IDEA: {storyDescription}

Do NOT decide the length. Write in this exact JSON shape:

{
  "title": "short title with emoji",
  "characters": ["ria", "mumma"],
  "where": "the setting in 2-3 words",
  "hook": "one-line hook",
  "beat1_setup": "what's normal at the start",
  "beat2_problem": "what goes wrong",
  "beat3_escalation": "how it gets worse",
  "beat4_turn": "the moment things change",
  "beat5_payoff": "the funny or warm ending",
  "stretch_beat": "an extra moment between problem and turn, or null",
  "ending_line": "one short warm line in Hinglish",
  "closing_cta": "a short follow line",
  "caption": "2-3 lines for Instagram",
  "hashtags": ["exactly", "five", "relevant", "tags", "here"],
  "best_length": 20 or 30 or null
}
```

This replaces the current `generateEverything()` script-generation call when
the idea is a Stage 1 beat idea. The existing `generateEverything()` path stays
for ideas that need the full timed script.

---

## Tests to Add

### 1. `beat_sheet_test.dart`
- `BeatSheet` serializes to JSON and back
- `hasStretchBeat` returns true/false correctly
- `bestLength` is validated (20, 30, or null)

### 2. `parts_calculator_test.dart`
- `partsForLength(20) == 2`
- `partsForLength(30) == 3`
- `partsForLength(40) == 4`
- `partsForLength(60) == 6`
- `beatIndicesForParts(20)` maps beats to the right parts

### 3. `video_prompt_builder_test.dart`
- `buildVideoPrompts(beats, 20s)` returns 2 prompts
- `buildVideoPrompts(beats, 30s)` returns 3 prompts
- Part 1 has no continuity line
- Part 2+ has "CONTINUITY: The first frame must match..."
- Style and size lines are present in every part
- No glasses rule is in every part

---

## Build Order (from user's plan)

1. **Add beats model + Stage 1 generator** — no length
2. **Add length picker + parts calculator** — simple math
3. **Add video-prompt template + parts screen** — reuses existing UI patterns
4. **End-to-end test** on "Jugaad Fail, Box Win" at 30s — compare generated
   prompts to hand-written versions in `clip_prompts.md`
5. **Only then** consider clip import and last-frame extraction (FFmpeg)

---

## What Does NOT Work Automatically

- **Video generation from prompts.** User pastes prompts into Gemini manually.
  App writes the prompts and stores raw replies.
- **Chaining last frames.** User saves Gemini's last frame, attaches to next
  Part prompt. Later: FFmpeg auto-extracts if clips return to the app.
- **Face/style verification.** Still needs human eyes per clip.

---

## Files Modified

| File | Change |
|---|---|
| `lib/story_ideas.dart` | Add `BeatSheet` class |
| `lib/prompts.dart` | Add `buildVideoPrompts()` + `VideoClipPrompt` class |
| `lib/story_reel_builder.dart` | Add `partsForLength()` + `beatIndicesForParts()` |
| `lib/prompt_builder.dart` | Add `generateBeats()` (Stage 1 Gemini call) |
| `lib/prompt_screen.dart` | New tab: Parts Screen with copy buttons |
| `test/beat_sheet_test.dart` | New test file |
| `test/parts_calculator_test.dart` | New test file |
| `test/video_prompt_builder_test.dart` | New test file |
