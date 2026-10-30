import 'characters.dart';
import 'brand_system.dart';

/// A concise hook idea source-of-truth for the master prompt.
///
/// Pass the fields from the selected HookIdea so the model treats them as
/// authoritative — it must not invent contradictory events or characters.
class StoryHookSource {
  final String problem;
  final String twist;
  final String resolution;
  final String lesson;
  final String setting;
  final String sceneDetail;
  final String dialogue;
  final String mess;
  final String endingBeat;

  const StoryHookSource({
    required this.problem,
    required this.twist,
    required this.resolution,
    required this.lesson,
    required this.setting,
    required this.sceneDetail,
    required this.dialogue,
    required this.mess,
    required this.endingBeat,
  });
}

/// Input variables for the master video prompt.
///
/// All story and character data flows through here so the template stays
/// data-driven and testable.
class VideoPromptVariables {
  final String storyTitle;
  final String storyIdea;
  final String realLifeProblem;
  final String learningOutcome;
  final List<String> selectedCharacters;
  final String visualStyle;
  final String overallTone;
  final String videoGenerator;
  final String language;
  final bool hasReferenceImages;
  final StoryHookSource? storyHook;

  const VideoPromptVariables({
    required this.storyTitle,
    required this.storyIdea,
    required this.realLifeProblem,
    required this.learningOutcome,
    required this.selectedCharacters,
    required this.visualStyle,
    required this.overallTone,
    this.videoGenerator = 'Runway Gen-2 / Kling / Luma',
    this.language = 'Hinglish',
    this.hasReferenceImages = false,
    this.storyHook,
  });

  /// Only the selected characters that exist in the character library.
  /// Unknown names are dropped rather than silently rendered as
  /// 'standard character appearance'.
  List<String> get validCharacters =>
      selectedCharacters.where(kCharacterNames.contains).toList();

  /// Character descriptions for the valid characters only, joined by newline.
  String get characterDescriptions =>
      validCharacters.map(characterDescription).join('\n');

  /// Build the CHARACTER LOCK block dynamically from [validCharacters].
  /// Uses [CharacterLibrary.characterLockFor] when reference images are
  /// available, otherwise falls back to the description-based lock.
  String get characterLockBlock {
    final cast = validCharacters
        .map((name) => CharacterLibrary.all.firstWhere(
              (c) => c.name == name,
              orElse: () => CharacterLibrary.ria,
            ))
        .toList();
    return CharacterLibrary.characterLockFor(cast);
  }
}

/// The full Gemini Video Master Prompt template.
///
/// This template produces a 30-second vertical Reel in 3 connected 10-second
/// clips. It encodes all brand, safety, continuity, and story-accuracy rules.
/// The JSON schema is fixed and must NOT be changed.
const String kGeminiVideoMasterPrompt = '''
ROLE AND OBJECTIVE

You are an expert short-form video director, preschool storytelling scriptwriter,
social media content strategist, and AI video prompt engineer.

Your task is to transform the provided story idea into a complete, emotionally
engaging, ready-to-produce 30-second vertical video Reel for the brand
"Fun Learning With Palak".

The final Reel must tell a clear, relatable story with a meaningful takeaway.
It should feel like a professionally directed short film, not a collection of
unrelated AI-generated scenes.

The video consists of three consecutive 10-second clips:
- Part 1: 0-10 seconds — Hook and story setup.
- Part 2: 10-20 seconds — Core action and conflict.
- Part 3: 20-30 seconds — Resolution and call to action.

The clips will be generated sequentially using AI video generation and video
extension tools. Therefore, continuity between clips is essential.

STORY INPUT:
Story title: {{STORY_TITLE}}
Story idea: {{STORY_IDEA}}
Real-life problem: {{REAL_LIFE_PROBLEM}}
Learning outcome: {{LEARNING_OUTCOME}}
{{STORY_HOOK_BLOCK}}
Target audience: Indian parents and caregivers of children aged 1-4.
Primary objective: Create a relatable, engaging, visually understandable
story that parents will want to watch, share, or save.

BRAND AND CHARACTER SETTINGS:
Brand name: Fun Learning With Palak
Brand tagline: Little stories, big lessons.
Characters available: {{SELECTED_CHARACTERS}}

{{CHARACTER_DESC_SECTION}}
{{REF_IMAGE_INSTRUCTION}}

Character consistency rules:
1. Use the supplied references as the authoritative source for character identity.
2. Preserve each character's appearance, clothing, colors, hairstyle,
   proportions, and distinguishing features across all three clips.
3. Do not invent new character appearances or change established designs.
4. Only include characters needed for the story.
5. Do not introduce unexplained characters or props between clips.
6. Keep facial expressions and body movements natural, expressive, and
   suitable for preschool storytelling.
7. If a character appears in multiple clips, maintain the same identity
   and appearance.
8. Apply any character-specific physical details (e.g. glasses, distinctive marks)
   only when they are part of that character's supplied description — do not invent
   or remove them based on the default cast.

PRODUCTION SETTINGS:
Video format: 9:16 vertical.
Total duration: 30 seconds.
Clip duration: 10 seconds per clip.
Visual style: {{VISUAL_STYLE}}
Overall tone: {{OVERALL_TONE}}
Language: {{LANGUAGE}}
Narration style: Warm, conversational, emotionally expressive, and easy
to understand.
Visual approach: Story-driven animation with clear actions, readable
expressions, natural movement, and visually meaningful details.
Video generator: {{VIDEO_GENERATOR}}
Target duration of spoken narration: Three short narration sections
that fit their respective 10-second clips.
Text overlays: Short, readable, high-contrast text suitable for a mobile
screen. Each part MUST include an "on_screen_text" field specifying what text
the editor will overlay for sound-off viewing. The video model itself must NOT
render text — use the on_screen_text field only to inform the editor's
post-generation overlay.

ON-SCREEN TEXT — THREE SEPARATE THINGS, NEVER MIXED:
1. GENERATED VIDEO FRAMES: render NONE. The video model must NOT render
   text — no captions, titles, subtitles, speech bubbles, readable signs,
   logos or watermarks. Text is added later in the editor.
2. SPOKEN DIALOGUE: what the characters say out loud, in {{LANGUAGE}}.
   This is audio, not graphics — it is never rendered as on-screen text.
3. EDITOR-ONLY OVERLAYS (editor metadata): actual story-specific text the
   editor adds post-generation for sound-off viewing, stored in the
   on_screen_text field only. This is editor metadata — the video model must
   NOT draw it. The editor's caption renderer adds it later.

{{STORY_ACCURACY_RULES}}

{{REALISTIC_OUTCOME_RULES}}

{{CONTINUITY_RULES}}

{{DIALOGUE_ACTION_RULES}}

{{SAFETY_RULES}}

STORYTELLING RULES:
A. Start with a strong visual hook — the first three seconds must
   communicate an interesting situation immediately. Avoid generic
   introductions. The opening must make sense even when viewed without
   sound.
B. Use a real-life preschool situation built around the supplied problem.
C. Give the story a clear progression: something happens, the character
   reacts, tries something, faces a complication, discovers a resolution.
D. Keep the lesson natural — do not turn the ending into a long lecture.
   Prefer showing the character learning through action or dialogue.
E. Keep the story age-appropriate for children aged 1-4 and their
   caregivers.

VIDEO CONTINUITY RULES:
The three clips must look like consecutive sections of the same video.
For every clip, explicitly define starting character positions, character
appearances and clothing, setting and important props, current action,
camera position and movement, lighting and visual style, emotional
state of each important character, and the exact visual state at the
end of the clip.
For Part 2, begin with: "Continuing seamlessly from the final frame
of Clip 1..."
For Part 3, begin with: "Continuing directly from the final frame
of Clip 2..."
Do not restart the story at the beginning of Parts 2 or 3.
Do not teleport characters, change clothing, or move objects without
explanation.

REQUIRED OUTPUT FORMAT

Return ONLY valid JSON:

{
  "story_title": "short title",
  "story_foundation": "2-3 sentences describing the complete story arc",
  "parts": [
    {
      "part_number": 1,
      "purpose": "What story beat this part communicates",
      "setting": "Location, background, lighting, props",
      "starting_state": "Character positions and expressions at START",
      "action_0_4s": "Specific action in first 4 seconds",
      "action_4_8s": "Continuation in seconds 4-8",
      "action_8_10s": "Complete this beat, establish transition",
      "dialogue": "Exact Hinglish dialogue if required, or empty",
      "text_overlay": "On-screen text for sound-off viewers, max 2 short lines",
      "ending_state": "Character positions at END of this clip",
      "continuity_from": "Opening state for Part 1",
      "continuity_into": "Ending state for next part",
      "negative_instructions": "No duplicate characters, no identity changes, no outfit changes, no distorted anatomy, no blurry faces",
      "full_prompt": "Complete copy-paste-ready video generation prompt"
    }
  ]
}

RULES FOR full_prompt:
Each full_prompt must include:
- TITLE, PART number, DURATION (exactly 10 seconds), FORMAT (vertical 9:16)
- STORY CONTEXT
- THIS PART'S PURPOSE
- CHARACTER LOCK with exact descriptions
- SCENE AND SETTING
- STARTING STATE
- CAMERA (opening framing, movement, ending framing)
- ACTION TIMELINE (0-4s, 4-8s, 8-10s)
- DIALOGUE AND AUDIO in {{LANGUAGE}}
- ON-SCREEN TEXT OVERLAYS are editor metadata only (on_screen_text field) — NOT rendered in video
- CONTINUITY FROM PREVIOUS PART
- CONTINUITY INTO NEXT PART
- VISUAL STYLE
- NEGATIVE INSTRUCTIONS

Every part must have a non-empty dialogue or text_overlay so the video
is engaging with or without sound.

Return exactly 3 parts.
''';

/// The individual rule blocks substituted into the template.
const String kStoryAccuracyRules = '''
STORY ACCURACY (the selected HookIdea is the source of truth):
- Preserve the hook's central problem, twist, resolution, and lesson exactly.
- Do not introduce contradictory events, unrelated characters, or a different moral.
- If the hook describes a specific object, action, or setting, use it — do not swap it for a generic stand-in.
''';

const String kRealisticOutcomeRules = '''
REALISTIC PRESCHOOL OUTCOMES:
- Show a small, believable improvement — a child trying, a parent nudging, one manageable step better.
- Never claim an entire house is cleaned in minutes, a tantrum is cured instantly, or a child masters an adult skill in one take.
- Outcomes must respect the child's age (1-4): imperfect but caring parenting, not magic.
''';

const String kContinuityRules = '''
CLIP CONTINUITY:
- Define the exact starting state and exact ending state for every clip: character positions, expressions, props, and background.
- Each next clip must continue from the previous clip's ending state — no teleporting, no unexplained outfit or prop changes.
- Part 2 begins with: "Continuing seamlessly from the final frame of Clip 1..."
- Part 3 begins with: "Continuing directly from the final frame of Clip 2..."
''';

const String kDialogueActionRules = '''
DIALOGUE AND ACTIONS:
- Replace generic placeholders with concrete, idea-specific actions and natural Hinglish dialogue.
- Not every character needs to speak. A silent character who acts is fine.
- Adults speak natural Hindi or Hinglish; children speak short, age-appropriate Hinglish.
''';

const String kSafetyRules = '''
SAFETY (overrides any conflicting idea field):
- Never depict unsafe behaviour as entertainment: no choking hazards, no climbing on unstable furniture, no small objects near babies under 3.
- If the story involves fireworks, sparklers, flames, matches, or candles: children must NEVER light, touch, hold, or approach them. Adults always handle them. Children watch from a genuinely safe distance.
- The visual resolution must never reward unsafe behaviour — show the safe choice being made, not the dangerous act succeeding.
- Solutions must show safe, realistic parenting — no magic fixes, no dismissing genuine feelings.
- No fear-based scenarios that could frighten a sensitive child.
''';

/// Renders the master prompt by replacing {{...}} placeholders.
String renderVideoMasterPrompt(VideoPromptVariables vars) {
  final charDescSection = vars.hasReferenceImages
      ? ''
      : 'Character descriptions:\n${vars.characterDescriptions}';

  final refImageInstruction = vars.hasReferenceImages
      ? 'Use the attached reference images as the definitive character references. Preserve each character\'s exact face, identity, hairstyle, clothing, colours, and proportions. Do not redesign or replace characters.'
      : 'Use the supplied character descriptions as the authoritative references.';

  // Build the STORY_HOOK_BLOCK if a hook is provided
  final storyHookBlock = vars.storyHook != null
      ? '''
HOOK SOURCE (authoritative — do not deviate):
Problem: ${vars.storyHook!.problem}
Twist: ${vars.storyHook!.twist}
Resolution: ${vars.storyHook!.resolution}
Lesson: ${vars.storyHook!.lesson}
Setting: ${vars.storyHook!.setting}
Scene detail: ${vars.storyHook!.sceneDetail}
Dialogue: ${vars.storyHook!.dialogue}
Mess: ${vars.storyHook!.mess}
Ending beat: ${vars.storyHook!.endingBeat}
'''
      : '';

  return kGeminiVideoMasterPrompt
      .replaceAll('{{STORY_TITLE}}', vars.storyTitle)
      .replaceAll('{{STORY_IDEA}}', vars.storyIdea)
      .replaceAll('{{REAL_LIFE_PROBLEM}}', vars.realLifeProblem)
      .replaceAll('{{LEARNING_OUTCOME}}', vars.learningOutcome)
      .replaceAll('{{STORY_HOOK_BLOCK}}', storyHookBlock)
      .replaceAll('{{SELECTED_CHARACTERS}}', vars.validCharacters.join(', '))
      .replaceAll('{{CHARACTER_DESC_SECTION}}', charDescSection)
      .replaceAll('{{REF_IMAGE_INSTRUCTION}}', refImageInstruction)
      .replaceAll('{{VISUAL_STYLE}}', vars.visualStyle)
      .replaceAll('{{OVERALL_TONE}}', vars.overallTone)
      .replaceAll('{{VIDEO_GENERATOR}}', vars.videoGenerator)
      .replaceAll('{{LANGUAGE}}', vars.language)
      .replaceAll('{{STORY_ACCURACY_RULES}}', kStoryAccuracyRules)
      .replaceAll('{{REALISTIC_OUTCOME_RULES}}', kRealisticOutcomeRules)
      .replaceAll('{{CONTINUITY_RULES}}', kContinuityRules)
      .replaceAll('{{DIALOGUE_ACTION_RULES}}', kDialogueActionRules)
      .replaceAll('{{SAFETY_RULES}}', kSafetyRules);
}

/// Validation result for a rendered video master prompt's JSON output.
class MasterPromptValidation {
  final bool isValid;
  final List<String> errors;

  const MasterPromptValidation({required this.isValid, required this.errors});

  static MasterPromptValidation valid() => const MasterPromptValidation(isValid: true, errors: []);
  static MasterPromptValidation invalid(List<String> errors) => MasterPromptValidation(isValid: false, errors: errors);

  @override
  String toString() => isValid ? 'VALID' : 'INVALID: ${errors.join("; ")}';
}

/// Validates a parsed JSON map from the master prompt output.
///
/// Pure Dart — no API calls. Checks the schema required by the prompt.
MasterPromptValidation validateVideoMasterPromptJson(
  Map<String, dynamic> json, {
  List<String> validCharacterNames = const ['Ria', 'Rio', 'Cuty', 'Robot', 'Mumma', 'Papa', 'Daadi', 'Teacher'],
  String? storyTitle,
  String? storyIdea,
}) {
  final errors = <String>[];

  // Top-level fields
  if (json['story_title'] == null || json['story_title'].toString().trim().isEmpty) {
    errors.add('Missing or empty story_title');
  }
  if (json['story_foundation'] == null || json['story_foundation'].toString().trim().isEmpty) {
    errors.add('Missing or empty story_foundation');
  }
  if (json['parts'] == null || json['parts'] is! List) {
    errors.add('Missing parts array');
    return MasterPromptValidation.invalid(errors);
  }

  final parts = json['parts'] as List;

  // Exactly 3 parts
  if (parts.length != 3) {
    errors.add('Expected exactly 3 parts, got ${parts.length}');
  }

  for (int i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part is! Map) {
      errors.add('Part $i is not a map');
      continue;
    }
    // Fields that MUST be non-empty
    const nonEmptyFields = [
      'part_number', 'purpose', 'setting', 'starting_state',
      'action_0_4s', 'action_4_8s', 'action_8_10s',
      'text_overlay', 'ending_state',
      'continuity_from', 'continuity_into',
      'negative_instructions', 'full_prompt',
    ];
    // dialogue can be empty
    for (final field in nonEmptyFields) {
      final value = part[field];
      if (value == null || value.toString().trim().isEmpty) {
        errors.add('Part ${i + 1}: missing or empty "$field"');
      }
    }
    // dialogue is optional - just check it exists
    if (!part.containsKey('dialogue')) {
      errors.add('Part ${i + 1}: missing "dialogue" field');
    }
    // Story-specific visual prompt check
    final fullPrompt = part['full_prompt']?.toString().trim() ?? '';
    if (fullPrompt.isEmpty) {
      errors.add('Part ${i + 1}: full_prompt must be non-empty and story-specific');
    } else if (fullPrompt.length < 30) {
      errors.add('Part ${i + 1}: full_prompt too short (likely a placeholder)');
    }
    // Character name validation in full_prompt
    if (fullPrompt.isNotEmpty && validCharacterNames.isNotEmpty) {
      final hasValidChar = validCharacterNames.any((c) => fullPrompt.contains(c));
      if (!hasValidChar) {
        errors.add('Part ${i + 1}: full_prompt does not mention any valid character');
      }
    }
    // text_overlay story-specific check
    final textOverlay = part['text_overlay']?.toString().trim() ?? '';
    if (textOverlay.isEmpty) {
      errors.add('Part ${i + 1}: text_overlay must be non-empty and story-specific');
    }
    // part_number should match
    if (part['part_number'] is int) {
      final pn = part['part_number'] as int;
      if (pn != i + 1) {
        errors.add('Part ${i + 1}: part_number mismatch (expected ${i + 1}, got $pn)');
      }
    }
  }

  // Hashtags validation (if present at top-level)
  if (json['hashtags'] != null) {
    final tags = json['hashtags'];
    if (tags is List) {
      final validTags = tags.whereType<String>().map((s) => s.trim()).where((s) => s.startsWith('#')).toList();
      if (validTags.length != 5) {
        errors.add('Expected exactly 5 hashtags starting with #, got ${validTags.length}');
      }
    }
  }

  return errors.isEmpty ? MasterPromptValidation.valid() : MasterPromptValidation.invalid(errors);
}