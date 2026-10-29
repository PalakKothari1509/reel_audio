# Generate Prompt Only Button

## Feature Overview

The **"Show Prompt Only"** button is an optional secondary control in `IdeaInputScreen` that constructs and displays the full Gemini API prompt for review **without** calling the Gemini API. It allows content creators to inspect, copy, and manually send the prompt to any AI video-generation model (e.g., Veo 2, Runway Gen-3, Sora) outside the app.

---

## UI Placement

**File:** `lib/idea_input_screen.dart:271-277`

```dart
if (widget.onGeneratePromptOnly != null) ...[
  const SizedBox(height: 8),
  SecondaryButton(
    label: 'Show Prompt Only',
    icon: Icons.description,
    onPressed: _showPromptOnly,
  ),
],
```

- **Button label:** `Show Prompt Only`
- **Icon:** `Icons.description`
- **Type:** `SecondaryButton` (secondary styling, below the primary `Generate` button)
- **Visibility:** Conditionally rendered only when `onGeneratePromptOnly` callback is provided by the parent screen.

### Feature-Specific Registration

| Feature | Screen | Callback |
|---|---|---|
| Idea Evaluation | `IdeaEvaluationScreen` | `_showEvaluationPromptOnly` |
| Carousel Generation | `CarouselPromptsScreen` | `_showEvaluationPromptOnly` |
| Gemini Story Video | `GeminiVideoScreen` | `_totalSeconds == 30` → `_showMasterReelPromptOnly`, else `_showEvaluationPromptOnly` |

**File:** `content_studio_screens.dart:928-930`

```dart
onGeneratePromptOnly: _totalSeconds == 30
    ? _showMasterReelPromptOnly
    : _showEvaluationPromptOnly,
```

---

## Data Flow

### 1. Button Tap → `_showPromptOnly()`

**File:** `lib/idea_input_screen.dart:127-144`

```dart
void _showPromptOnly() {
  if (widget.onGeneratePromptOnly == null) return;
  final idea = _ideaCtrl.text.trim();
  if (idea.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter or select an idea first.')),
    );
    return;
  }
  final chars = _selectedChars.isEmpty
      ? ['ria', 'rio', 'cuty']
      : List<String>.from(_selectedChars);
  widget.onGeneratePromptOnly!(
    idea: idea,
    characters: chars,
    additionalInstructions: _instrCtrl.text.trim(),
  );
}
```

- Validates that an idea is entered (non-empty `_ideaCtrl.text`).
- Uses default characters `['Ria', 'Rio', 'Cuty']` if none selected.
- Passes `idea`, `characters`, and `additionalInstructions` to the callback.

### 2. Prompt Construction

#### For 30-second videos (Master Reel):

**File:** `lib/content_studio_service.dart:806-829`

```dart
Future<void> _showMasterReelPromptOnly({
  required String idea,
  required List<String> characters,
  required String additionalInstructions,
}) async {
  final prompt = buildMasterReelPrompt(
    idea: idea,
    characters: characters,
    additionalInstructions: additionalInstructions,
  );
  if (!mounted) return;
  await prompt.showPromptOnly(
    context: context,
    title: 'Master 30-Second Reel Prompt (3 Clips)',
    modelName: 'gemini-3.8-flash',
    generationConfig: {
      'temperature': 0.7,
      'maxOutputTokens': 8192,
      'thinkingConfig': {'thinkingBudget': 0},
      'responseMimeType': 'application/json',
    },
    useSheet: true,
  );
}
```

- Calls `buildMasterReelPrompt()` to construct the full prompt string.
- **No `hasReferenceImages` parameter** — defaults to `false`, so character descriptions are included inline.
- Uses `showPromptOnly()` (from `prompt_preview.dart`) to display the prompt.
- Does **not** require or use an API key (no `_geminiText()` call).

#### For non-30s videos (Evaluation Prompt):

**File:** `lib/content_studio_screens.dart:180-404` (image and carousel screens)

```dart
void _showEvaluationPromptOnly({
  required String idea,
  required List<String> characters,
  required String additionalInstructions,
}) async {
  final prompt = buildCheckStoryPrompt(idea); // or buildAnalyzeShareabilityPrompt
  ...
  await prompt.showPromptOnly(
    context: context,
    title: '...',
    modelName: 'gemini-3.5-flash',
    generationConfig: {...},
    useSheet: true,
  );
}
```

- Constructs the evaluation prompt (`buildCheckStoryPrompt` or `buildAnalyzeShareabilityPrompt`).
- No API call — just displays and allows copying.

### 3. Prompt Display

**File:** `lib/prompt_preview.dart:335-378`

The `showPromptOnly()` extension method on `String` displays the prompt in a bottom sheet (`_PromptOnlySheet`) or dialog (`_PromptOnlyDialog`).

#### Display Components:

1. **Header** (`lib/prompt_preview.dart:520-543`):
   - Icon: `Icons.description` (blue/grey)
   - Title: Passed from caller (e.g., "Master 30-Second Reel Prompt (3 Clips)")
   - **Copy Prompt** button: Copies `config.prompt` to clipboard
   - Close button

2. **Model & Config Info** (`lib/prompt_preview.dart:546-568`):
   - `Model: gemini-3.8-flash`
   - `Lines: <N>  •  Characters: <N>`
   - `Config: temp: 0.7  •  maxTokens: 8192  •  ...`

3. **Prompt Content** (`lib/prompt_preview.dart:572-592`):
   - `SelectableText` widget displaying the full prompt
   - Monospace font, 12pt, line height 1.4

4. **Actions** (`lib/prompt_preview.dart:449-468`):
   - `Close` button (text)
   - `Copy Prompt` button (filled, with `Icons.copy_all` icon)

**Important:** The "Show Prompt Only" flow does **not** display a "Send" button. The `onConfirm` callback is a no-op (`() {}`). This ensures no Gemini API call is made.

---

## Prompt Construction Details

### `buildMasterReelPrompt()` for 30-second videos

**File:** `lib/content_studio_service.dart:1470-1637`

Constructs a 667-line JSON-structured prompt for 3 connected 10-second clips (0-10s, 10-20s, 20-30s).

#### Prompt Sections (in order):

1. **Role Definition:**
   ```
   You are a senior video director for "Fun Learning With Palak", creating viral 30-second Instagram Reels (9:16 vertical) for Indian parents of preschoolers.
   ```

2. **Master Specification:**
   - Ratio & Format: 9:16 Vertical Video (Reels / Shorts)
   - Visual Aesthetic: Soft 3D Disney/Pixar animation, warm pastel cream backdrop
   - Characters: Only characters from CHARACTER LOCK below may appear

3. **Story Input:**
   - `STORY IDEA: $idea`
   - `LANGUAGE: $language` (Hinglish by default)
   - `ADDITIONAL INSTRUCTIONS: $additionalInstructions` (if provided)

4. **Brand Style Block** (`_videoBrandStyleBlock()`):
   ```
   $kMasterPrompt
   
   NEGATIVE INSTRUCTIONS: $kNegativeInstructions
   Audience: ${BrandDefaults.audience}
   Brand: ${BrandDefaults.name}
   ```
   - Uses `_videoBrandStyleBlock()` which **excludes** the Instagram handle `(@funlearningwithpalak)`.
   - Contrast: `_brandStyleBlock()` (used for image/carousel prompts) **includes** the handle.

5. **Character Lock (do not deviate):**
   - Dynamically generated from `_characterBlock()` and `_characterVoiceBlock()`
   - Uses reference images if `hasReferenceImages: true`
   - Character descriptions from `characterDescription()`

6. **Language Rules:**
   - Adults: natural, conversational Hindi or Hinglish
   - Children: simple, age-appropriate Hinglish
   - No formal, AI-sounding dialogue

7. **Story Quality:**
   - Real-life preschool problem foundation
   - Believable child reactions
   - Imperfect but caring parenting
   - Cause-and-effect progression

8. **Safety:**
   - No unsafe behavior as entertainment
   - Safe, realistic parenting solutions
   - No fear-based scenarios for sensitive children

9. **Shareability:**
   - "Why would one parent send this to another parent?"
   - Must name a specific parent archetype

10. **Character Continuity Rules:**
    - Reference image or description preservation
    - No character duplication or identity changes
    - Face, age, hair, outfit, colours, proportions preserved

11. **Continuity:**
    - Clip 2 starts from Clip 1 ending state
    - Clip 3 starts from Clip 2 ending state
    - **No on-screen text of any kind: no captions, titles, subtitles, speech bubbles, readable signs, logos or watermarks. Text is added later in the editor.**

12. **Brand Metadata (handle removed):**
    ```
    - Audience: Indian moms and parents of children aged 1-4
    - Brand: Fun Learning With Palak
    ```

13. **Clip Structure (MANDATORY):**
    - **CLIP 1 (0–10s): THE HOOK & PROBLEM**
    - **CLIP 2 (10–20s): THE TWIST & ESCALATION**
    - **CLIP 3 (20–30s): THE RESOLUTION & MORAL**
    - Each clip has: Visual Action, Camera Work, Editor Metadata (on_screen_text — do NOT render in video), AI Video Generator Prompt

14. **Continuity Requirements (CRITICAL):**
    - Each clip's prompt is copy-paste ready for Veo/Runway/Sora
    - Self-contained but references previous clip's end frame

15. **JSON Output Schema:**
    ```json
    {
      "story_title": "Short Hinglish title with emoji",
      "story_foundation": "2-3 sentences...",
      "caption": "1-2 lines...",
      "hashtags": [5 exactly],
      "pin_comment": "One true thing...",
      "parts": [
        {
          "part_number": 1,
          "purpose": "Hook & Problem",
          "setting": "...",
          "starting_state": "...",
          "action_0_4s": "...",
          "action_4_8s": "...",
          "action_8_10s": "...",
          "dialogue": "...",
          "text_overlay": "Two lines max...",
          "ending_state": "...",
          "continuity_from": "...",
          "continuity_into": "...",
          "negative_instructions": "...",
          "visual_prompt": "Complete copy-paste-ready prompt",
          "on_screen_text": {
            "line_1_0_3s": "Hook headline (max 3 words)",
            "line_2_4_7s": "Context text (max 5 words)"
          }
        }
      ]
    }
    ```

16. **Final Rules:**
    - Return exactly 3 parts
    - Each visual_prompt must be self-contained
    - All on_screen_text must be in the target language
    - Story must be specific to an Indian household
    - **NO on-screen text rendered in video frames — all text is editor metadata in the on_screen_text field only.**

### Character Block Construction

**File:** `lib/content_studio_service.dart` (multiple methods)

#### `_characterBlock()` (`lib/content_studio_service.dart`)

```dart
String _characterBlock(List<String> characters, {required bool hasReferenceImages}) {
  if (hasReferenceImages) return '';
  return characters.map((c) => characterDescription(c)).join('\n');
}
```

- When `hasReferenceImages: false` (the default for "Show Prompt Only"), each character's full description from `characterDescription()` is included.
- When `hasReferenceImages: true`, image references are used instead (no text descriptions).

#### `_characterVoiceBlock()` (`lib/content_studio_service.dart`)

```dart
String _characterVoiceBlock(List<String> characters) {
  // Returns voice patterns for each character
  // e.g., "Ria: Curious, asks questions. Rio: Determined, says 'no' first."
}
```

### `_videoBrandStyleBlock()` vs `_brandStyleBlock()`

**File:** `lib/content_studio_service.dart:162-170`

```dart
String _brandStyleBlock() =>
    '$kMasterPrompt\n\nNEGATIVE INSTRUCTIONS: $kNegativeInstructions\n'
    'Audience: ${BrandDefaults.audience}\n'
    'Brand: ${BrandDefaults.name} (${BrandDefaults.handle})';

String _videoBrandStyleBlock() =>
    '$kMasterPrompt\n\nNEGATIVE INSTRUCTIONS: $kNegativeInstructions\n'
    'Audience: ${BrandDefaults.audience}\n'
    'Brand: ${BrandDefaults.name}';
```

| Aspect | `_brandStyleBlock()` (image/carousel) | `_videoBrandStyleBlock()` (video) |
|---|---|---|
| Instagram handle | Included: `(@funlearningwithpalak)` | **Excluded** |
| Brand name | Included | Included |
| Audience | Included | Included |
| Visual style | Included (via `kMasterPrompt`) | Included (via `kMasterPrompt`) |
| Negative instructions | Included | Included |

### Text Overlay Extraction (`parseReadyPrompt`)

**File:** `lib/content_studio_service.dart:477-520`

When a `HookIdea` has a pre-built `readyPrompt` (e.g., for viral reels), `parseReadyPrompt()` parses the structured text into `VideoPartPrompt` objects.

#### The overlay extraction process:

1. **Parse** the readyPrompt text into Part 1, Part 2, Part 3 sections using header detection (`Part 1 (0-10s):`, `Part 2 (10-20s):`, `Part 3 (20-30s):`).

2. **For each part**, call `_extractTextOverlay(promptText)`:
   - Searches for `Final text overlay:` marker
   - Extracts the overlay value (e.g., `LEARNING IS A HABIT, SMALL WINS BIG HEARTS`)
   - Strips the overlay instruction from `promptText` and `fullPrompt`
   - Preserves `Moral:` and all scene/dialogue content

3. **Result:** `VideoPartPrompt.textOverlay` contains the extracted overlay text; `promptText` contains only scene/dialogue/moral content.

#### Example readyPrompt Part 3:

**Before extraction:**
```
3D Pixar style, 9:16. Ria puts on both shoes correctly, stands up proud. Mumma gives a quick hug. "Chalo, chalte hain." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Give children age-appropriate opportunities to practise independence, allow reasonable time, and offer gentle help when needed.
```

**After extraction:**
- `textOverlay`: `LEARNING IS A HABIT, SMALL WINS BIG HEARTS`
- `promptText`: `3D Pixar style, 9:16. Ria puts on both shoes correctly, stands up proud. Mumma gives a quick hug. "Chalo, chalte hain." Moral: Give children age-appropriate opportunities to practise independence, allow reasonable time, and offer gentle help when needed.`

### `kGeminiVideoMasterPrompt` (Alternative Prompt Template)

**File:** `lib/gemini_video_master_prompt.dart`

A separate master prompt template used by some code paths. Key properties:

- **Brand name reference:** `"Fun Learning With Palak"` (no handle)
- **Text overlay rule:** `"The video model itself must NOT render text — use the on_screen_text field only to inform the editor's post-generation overlay."`
- **Full prompt rule:** `"ON-SCREEN TEXT OVERLAYS are editor metadata only (on_screen_text field) — NOT rendered in video"`

### Prompt Preview Dialog

**File:** `lib/prompt_preview.dart:298-378` (`showPromptOnly`)

The `showPromptOnly()` extension method on `String`:

```dart
Future<void> showPromptOnly({
  required BuildContext context,
  required String title,
  required String modelName,
  required Map<String, dynamic> generationConfig,
  bool useSheet = true,
}) async {
  // Shows the prompt in a bottom sheet (default) or dialog
  // Actions: Close (text) + Copy Prompt (filled button)
  // No "Send" button — no API call is made
}
```

#### Bottom Sheet Layout (`_PromptOnlySheet` at `lib/prompt_preview.dart:486-607`):

1. **Handle bar** (gray, 40×4, top margin 12)
2. **Header row:**
   - `Icons.description` icon (grey)
   - Title text (e.g., "Master 30-Second Reel Prompt (3 Clips)")
   - Copy button (`Icons.copy_all`) — copies `config.prompt` to clipboard
   - Close button (`Icons.close`)
3. **Model info card:**
   - `Model: gemini-3.8-flash`
   - `Lines: <N>  •  Characters: <N>`
   - `Config: temp: 0.7  •  maxTokens: 8192  •  ...`
4. **Prompt content:**
   - `SelectableText` widget with monospace font, 12pt, line height 1.4
   - Scrollable within `SingleChildScrollView`

#### Dialog Layout (`_PromptOnlyDialog` at `lib/prompt_preview.dart:380-484`):

Similar to bottom sheet but in an `AlertDialog`:
1. **Title row:** Icon + title
2. **Model info card:** Same as bottom sheet
3. **Prompt content:** `SelectableText` in scrollable container
4. **Actions:** `Close` (text button) + `Copy Prompt` (filled button with icon)

---

## Security and Data Integrity

### Handle Exclusion

- `_videoBrandStyleBlock()` (line 167) omits `BrandDefaults.handle` (`@funlearningwithpalak`)
- Hardcoded brand line in `buildMasterReelPrompt` (line 1542) was changed from:
  ```
  - Brand: Fun Learning With Palak (@funlearningwithpalak)
  ```
  to:
  ```
  - Brand: Fun Learning With Palak
  ```
- Verified: `renderVideoMasterPrompt()` output does not contain `@funlearningwithpalak`
- Verified: `buildGeminiVideoPrompt()` output does not contain `@funlearningwithpalak`
- Verified: `buildMasterReelPrompt()` output does not contain `@funlearningwithpalak`
- Instagram handle (`@funlearningwithpalak`) is preserved in image/carousel prompts via `_brandStyleBlock()` (lines 196, 284, 1227)

### Text Overlay Integrity

- `_extractTextOverlay()` (line 506) strips `Final text overlay: <VALUE>.` from `promptText`
- `textOverlay` field stores the extracted value separately
- `kGeminiVideoMasterPrompt` explicitly tells Gemini:
  - Line 108-109: "The video model itself must NOT render text — use the on_screen_text field only"
  - Line 177: "ON-SCREEN TEXT OVERLAYS are editor metadata only (on_screen_text field) — NOT rendered in video"
- `buildMasterReelPrompt` negative instructions (line 1540-1541):
  ```
  - NO on-screen text of any kind: no captions, titles, subtitles, speech bubbles,
    readable signs, logos or watermarks. Text is added later in the editor.
  - No closing card, moral, quote or summary at the end.
  ```
- `buildGeminiVideoPrompt` negative instructions (line 562):
  ```
  - NO on-screen text rendered in video frames — text_overlay/on_screen_text are editor metadata only.
  ```

### API Key Handling

- The "Show Prompt Only" path does **not** access or use API keys
- `keyStore.getGeminiApiKey()` is not called in `_showMasterReelPromptOnly()` or `_showEvaluationPromptOnly()`
- The `showPromptOnly()` method's `generationConfig` parameter is only used for display purposes (shows model name and config to user)

---

## Prompt Field Routing

### For `generateGeminiVideoPrompts()` (live Gemini API):

**File:** `lib/content_studio_service.dart:576-631`

| JSON Field (from Gemini) | VideoPartPrompt Field | Used For |
|---|---|---|
| `full_prompt` | `promptText` | Main video generation prompt |
| `text_overlay` | `textOverlay` | Editor metadata (separate field) |
| `part_number` | `partNumber` | Part sequencing |
| `purpose` | `purpose` | Part description |

### For `generateMasterReelPromptsWithPreview()`:

**File:** `lib/content_studio_service.dart:770-798`

| JSON Field (from Gemini) | VideoPartPrompt Field | Used For |
|---|---|---|
| `visual_prompt` (fallback: `full_prompt`) | `promptText` | Main video generation prompt |
| `on_screen_text.line_1_*` / `line_2_*` | `textOverlay` | Editor metadata (joined with ` \| `) |
| `part_number` | `partNumber` | Part sequencing |
| `purpose` | `purpose` | Part description (not parsed) |

### For `parseReadyPrompt()` (pre-built hooks):

**File:** `lib/content_studio_service.dart:390-520`

| Source | VideoPartPrompt Field | Used For |
|---|---|---|
| Part header + body text | `promptText` | Video generation prompt (overlay stripped) |
| `Final text overlay: <VALUE>` | `textOverlay` | Editor metadata (extracted and removed from promptText) |
| Part header | `purpose` | Part description (parsed from header) |

---

## Persistence

### Save to PromptVault

**File:** `lib/content_studio_screens.dart:30-50` (`_saveVideoPromptsToVault`)

```dart
for (final part in result.parts) {
  await PromptVault.saveWithVersion(
    contentId: contentId,
    title: '${result.storyTitle} ${part.title}',
    type: PromptType.video,
    promptText: part.promptText,  // Overlay already stripped
    metadata: {
      'partNumber': part.partNumber,
      'textOverlay': part.textOverlay,  // Stored in metadata
      'storyFoundation': result.storyFoundation,
      ...
    },
  );
}
```

- `promptText` is saved as-is (overlay already stripped by `parseReadyPrompt` or extracted from Gemini response)
- `textOverlay` is stored in `metadata` as a separate key
- On reload via `SavedPrompt.fromJson()`, `promptText` and `metadata` are restored independently — overlay text does not re-enter the generation prompt

### Copy to Clipboard

**File:** `lib/content_studio_screens.dart:1009-1014` (Copy all parts)

```dart
final all = result.parts
    .map((p) => '=== ${p.title.toUpperCase()} ===\n\n${p.promptText}')
    .join('\n\n');
Clipboard.setData(ClipboardData(text: all));
```

**File:** `lib/content_studio_screens.dart:1211-1212` (Copy single part)

```dart
Clipboard.setData(ClipboardData(text: part.promptText));
```

- Only `promptText` is copied — `textOverlay` is **not** included
- Since overlay text was stripped from `promptText`, the clipboard content contains only scene/dialogue/moral content

---

## Regeneration Path

**File:** `lib/content_studio_service.dart:689-757` (`regenerateSingleVideoPart`)

When a user clicks "Regenerate" on a specific part:

1. `regenerateSingleVideoPart()` is called with:
   - `idea`, `storyFoundation`, `partNumber`, `totalParts`
   - `characters`, `previousEndingState`, `hasReferenceImages`
   - `apiKey`, `onWait` callback

2. The prompt uses `_videoBrandStyleBlock()` (no handle)

3. Gemini returns JSON with:
   - `full_prompt` → `promptText`
   - `text_overlay` → `textOverlay`

4. The new `VideoPartPrompt` replaces the old one in the parts list
5. The new part is saved to PromptVault with both `promptText` and `textOverlay`

**Note:** The `previousEndingState` passed to `regenerateSingleVideoPart` (line 866) is `current.parts[partIndex - 1].promptText` — this is the cleaned prompt text (overlay already stripped), which is correct for continuity.

---

## Related Functions and Classes

### `VideoPartPrompt`

**File:** `lib/content_studio_service.dart:356-382`

```dart
class VideoPartPrompt {
  final int partNumber;
  final int totalParts;
  final String promptText;    // Video generation prompt (overlay stripped)
  final String textOverlay;   // Extracted overlay value (editor metadata)
  final String purpose;       // Part description
  final String fullPrompt;    // Same as promptText
  
  const VideoPartPrompt({
    required this.partNumber,
    required this.totalParts,
    required this.promptText,
    this.textOverlay = '',
    this.purpose = '',
    this.fullPrompt = '',
  });
  
  String get title => 'Part $partNumber of $totalParts';
}
```

### `GeminiVideoResult`

**File:** `lib/content_studio_service.dart:374-521`

```dart
class GeminiVideoResult {
  final String storyTitle;
  final String storyFoundation;
  final List<VideoPartPrompt> parts;
  
  static GeminiVideoResult parseReadyPrompt(String readyPrompt, String title) { ... }
  static (String, String) _extractTextOverlay(String promptText) { ... }
  static bool _isPartHeader(String line, int part) { ... }
  static String _partHeaderContent(String line, int part) { ... }
}
```

### `BrandDefaults`

**File:** `lib/brand_system.dart:10-25`

```dart
class BrandDefaults {
  static const String name = 'Fun Learning With Palak';
  static const String handle = '@funlearningwithpalak';
  static const String audience = 'Parents of preschoolers (1.5-5 years)';
  static const String tagline = 'Little stories, big lessons.';
  static const List<String> defaultHashtags = [...];
  static String get visualStyle => 'Soft 3D Pixar/Disney-style render, cream backgrounds, gentle textures';
}
```

### `kMasterPrompt` and `kNegativeInstructions`

**File:** `lib/master_prompt.dart:13-61`

```dart
const String kMasterPrompt = '''
Soft 3D Disney-Pixar animation style, vertical 9:16 aspect ratio.
Indian family setting. Target audience: parents of children aged 1-4.
Bilingual Hindi-English environment: adults speak natural Hindi, children speak age-appropriate Hinglish.
Warm natural lighting. Cream backgrounds preferred.
Characters are toddlers with realistic proportions — no chibi or kawaii exaggeration.
Every character looks the same in every scene: same clothes, same hair, same colors.
Cute but not cartoonish. Semi-realistic rendering.
Endings are satisfying but not artificially perfect — show a small, real-world improvement.
Lessons are demonstrated through actions and consequences, not forced dialogue or moralizing.''';

const String kNegativeInstructions = '''
$kCharacterRules
No distorted hands or anatomy, no floating objects, no blurry faces.
NO on-screen text of any kind: no captions, titles, subtitles, speech bubbles,
readable signs, logos or watermarks. Text is added later in the editor.
No closing card, moral, quote or summary at the end.''';
```

---

## Test Coverage

### Overlay Extraction Tests

**File:** `test/category_guard_test.dart`

| Test Name | Lines | What it verifies |
|---|---|---|
| `parseReadyPrompt: overlay text is extracted to textOverlay and stripped from promptText` | 104-124 | Overlay value extracted; `promptText` does NOT contain "Final text overlay" or overlay value; `Moral:` and scene text remain |
| `parseReadyPrompt: handles missing overlay gracefully` | 126-141 | No overlay marker → `textOverlay` empty; `promptText` intact |
| `parseReadyPrompt: handles overlay at end of prompt without Moral` | 143-157 | Overlay stripped even without trailing "Moral:"; scene text preserved |
| `parseReadyPrompt: all 26 prompts produce 3 valid parts with intact Part 3` | 69-101 | Updated: checks `textOverlay` non-empty and `promptText` does NOT contain "Final text overlay" |
| `parseReadyPrompt: overlay text is preserved in textOverlay metadata across all 26 hooks` | 175-202 | All 26 hooks with overlay marker: overlay in `textOverlay`, not in `promptText` |
| `parseReadyPrompt: dialogue and scene content survives overlay extraction` | 204-216 | All parts remain non-empty after extraction |
| `parseReadyPrompt: repaired hooks retain apostrophes and quotes in Part 3` | 159-174 | Apostrophes/quotes in scene description survive extraction |
| `parseReadyPrompt header variations` (4 tests) | 178-206 | Header parsing with inline content, multi-line, different spacing, missing Part 2, empty input, non-part text |

### Brand Handle Exclusion Tests

| Test Name | File | What it verifies |
|---|---|---|
| `excludes brand handle from video prompt` | `content_studio_prompt_test.dart:409` | `buildGeminiVideoPrompt` output has no `@funlearningwithpalak` |
| `excludes brand handle from master reel video prompt` | `content_studio_prompt_test.dart:455` | `buildMasterReelPrompt` output has no handle but keeps brand name |
| `does not contain Instagram handle` | `gemini_video_master_prompt_test.dart:152` | `kGeminiVideoMasterPrompt` has no `@funlearningwithpalak` |

### Text-As-Metadata Tests

| Test Name | File | What it verifies |
|---|---|---|
| `prohibits rendered text overlays on video frames` | `content_studio_prompt_test.dart` | `buildMasterReelPrompt` has "NO on-screen text" directive |
| `prohibits rendered text overlays` | `content_studio_prompt_test.dart:473` | Multiple directives: "NO on-screen text", "Text is added later", "editor metadata", "do NOT render in video" |
| `negative instructions say text is editor metadata` | `content_studio_prompt_test.dart:169` | `buildGeminiVideoPrompt` has "editor metadata" and "do NOT render" |
| `prohibits rendered text overlays in video frames` | `gemini_video_master_prompt_test.dart:134` | `kGeminiVideoMasterPrompt` says "must NOT render text" and "editor metadata" |

---

## Known Limitations

1. **No API validation:** The "Show Prompt Only" feature does not call the Gemini API, so it cannot verify that the prompt structure will produce valid JSON output. The prompt is displayed as-is.

2. **`hasReferenceImages` defaults to false:** `_showMasterReelPromptOnly()` calls `buildMasterReelPrompt()` without `hasReferenceImages: true`. This means character descriptions are included inline in the prompt. If the user uploaded reference images, they would need to be manually added as a note after copying the prompt.

3. **Offline generator is separate:** `video_prompt_generator_offline.dart` has its own `VideoPartPrompt` class (without `textOverlay` field) and its own overlay handling via `overlayInstruction()` in `hook_system.dart:53`. This is a different code path used for the offline story maker and does not go through `parseReadyPrompt()`.

4. **PromptVault stores `promptText` as opaque string:** There is no automatic re-extraction of overlay text from saved prompts. The overlay is stripped at generation time and stored in metadata, but if a user manually edits the saved `promptText` to re-add overlay text, it will not be automatically extracted.

5. **No undo for copy operation:** Once a prompt is copied to clipboard via the "Copy Prompt" button, there is no undo mechanism.
