import 'characters.dart';

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

  VideoPromptVariables({
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
  });

  String get characterDescriptions {
    return selectedCharacters
        .map((name) => characterDescription(name))
        .join('\n');
  }
}

/// The full Gemini Video Master Prompt.
/// Placeholders in {{...}} are replaced by values from [VideoPromptVariables].
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

/// Renders the master prompt by replacing {{...}} placeholders.
String renderVideoMasterPrompt(VideoPromptVariables vars) {
  final charDescSection = vars.hasReferenceImages
      ? ''
      : 'Character descriptions:\n${vars.characterDescriptions}';

  final refImageInstruction = vars.hasReferenceImages
      ? 'Use the attached reference images as the definitive character references. Preserve each character\'s exact face, identity, hairstyle, clothing, colours, and proportions. Do not redesign or replace characters.'
      : 'Use the supplied character descriptions as the authoritative references.';

  return kGeminiVideoMasterPrompt
      .replaceAll('{{STORY_TITLE}}', vars.storyTitle)
      .replaceAll('{{STORY_IDEA}}', vars.storyIdea)
      .replaceAll('{{REAL_LIFE_PROBLEM}}', vars.realLifeProblem)
      .replaceAll('{{LEARNING_OUTCOME}}', vars.learningOutcome)
      .replaceAll('{{SELECTED_CHARACTERS}}', vars.selectedCharacters.join(', '))
      .replaceAll('{{CHARACTER_DESC_SECTION}}', charDescSection)
      .replaceAll('{{REF_IMAGE_INSTRUCTION}}', refImageInstruction)
      .replaceAll('{{VISUAL_STYLE}}', vars.visualStyle)
      .replaceAll('{{OVERALL_TONE}}', vars.overallTone)
      .replaceAll('{{VIDEO_GENERATOR}}', vars.videoGenerator)
      .replaceAll('{{LANGUAGE}}', vars.language);
}
