import 'dart:convert';

import 'brand_system.dart';
import 'characters.dart';
import 'gemini_call.dart';
import 'secrets.dart';

// ── Shared brand-aware prompt generation service ──────────────────────────────
//
// All four content features (Reel from Images, Image Prompt, Carousel Prompts,
// Gemini Video) share the same brand identity, character library and visual style.
// This service is the single place that knows all of that and produces the correct
// output for each requested deliverable.

const _model = 'gemini-3.6-flash';
const _lightModel = 'gemini-3.5-flash-lite';
const _timeout = Duration(seconds: 90);

// ── Character block builder ───────────────────────────────────────────────────

/// Builds the character lock section from the live cast for a given set of names.
String _characterBlock(List<String> characterNames) {
  final cast = characterNames.isEmpty
      ? kDefaultCast
      : kDefaultCast.where((c) => characterNames
          .map((n) => n.toLowerCase())
          .contains(c.name.toLowerCase()))
          .toList();
  if (cast.isEmpty) return kDefaultCast.map(_charLine).join('\n');
  return cast.map(_charLine).join('\n');
}

String _charLine(CharacterRef c) => '${c.name.toUpperCase()}: ${c.description}';

String _brandStyleBlock() =>
    'Visual style: ${BrandDefaults.visualStyle}\n'
    'Audience: ${BrandDefaults.audience}\n'
    'Brand: ${BrandDefaults.name} (${BrandDefaults.handle})';

// ── Feature 2: Single image prompt ───────────────────────────────────────────

class ImagePromptResult {
  final String prompt;
  const ImagePromptResult(this.prompt);
}

Future<ImagePromptResult> generateImagePrompt({
  required String idea,
  required List<String> characters,
  String additionalInstructions = '',
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final key = _key(apiKey);
  final charBlock = _characterBlock(characters);

  final prompt = '''
You are a creative director for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Generate ONE complete, detailed, copy-paste-ready image generation prompt for this idea.

IDEA: $idea
${additionalInstructions.trim().isEmpty ? '' : 'ADDITIONAL INSTRUCTIONS: $additionalInstructions'}

${_brandStyleBlock()}

CHARACTERS IN THIS IMAGE:
$charBlock

CHARACTER CONSISTENCY RULES:
- Use the exact descriptions above for every character. Do not paraphrase.
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Only the listed characters may appear.

Return ONLY valid JSON in exactly this shape:

{
  "concept": "The main idea and intended message",
  "characters_present": "Exact characters in this image",
  "scene": "Location, background and environment",
  "action": "What each character is doing",
  "expressions": "Emotions through facial expressions and body language",
  "composition": "Character positions, framing and camera angle",
  "visual_style": "The established Instagram illustration style",
  "lighting": "Lighting, shadows and atmosphere",
  "text_overlay": "Exact wording to display if needed, or empty string",
  "negative_prompt": "Duplicates, distorted anatomy, unwanted characters, incorrect outfits, glasses on Ria/Rio, watermarks, text errors",
  "output_format": "Aspect ratio and resolution",
  "full_prompt": "The complete copy-paste-ready prompt combining all sections above into one coherent paragraph"
}

The "full_prompt" must be self-contained and ready to paste directly into an image generator.
It must include: style, characters with exact descriptions, scene, action, expressions, composition, lighting, aspect ratio, and negative prompt.
Do NOT generate captions, hashtags, or Reel scripts.
''';

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _model,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned nothing.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.');
  }

  final full = (json['full_prompt'] as String?)?.trim() ?? '';
  if (full.isEmpty) throw Exception('Gemini returned an empty prompt.');
  return ImagePromptResult(full);
}

// ── Feature 3: Carousel prompts ───────────────────────────────────────────────

class CarouselSlidePrompt {
  final int slideNumber;
  final String purpose;
  final String textOverlay;
  final String prompt;
  const CarouselSlidePrompt({
    required this.slideNumber,
    required this.purpose,
    required this.textOverlay,
    required this.prompt,
  });
}

class CarouselPromptsResult {
  final String title;
  final List<CarouselSlidePrompt> slides;
  const CarouselPromptsResult({required this.title, required this.slides});
}

Future<CarouselPromptsResult> generateCarouselPrompts({
  required String idea,
  required int slideCount,
  required List<String> characters,
  String contentTheme = '',
  String language = 'Hinglish',
  String additionalInstructions = '',
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final key = _key(apiKey);
  final charBlock = _characterBlock(characters);
  final count = slideCount.clamp(3, 12);

  final prompt = '''
You are a creative director for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Generate a complete $count-slide carousel with one detailed image-generation prompt per slide.

IDEA: $idea
${contentTheme.trim().isEmpty ? '' : 'CONTENT THEME: $contentTheme'}
LANGUAGE: $language
${additionalInstructions.trim().isEmpty ? '' : 'ADDITIONAL INSTRUCTIONS: $additionalInstructions'}

${_brandStyleBlock()}

CHARACTERS:
$charBlock

CHARACTER CONSISTENCY RULES:
- Use the exact descriptions above. Do not paraphrase.
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Only the listed characters may appear.
- Keep faces, hair, outfits and proportions IDENTICAL across all slides.

CAROUSEL STRUCTURE (adapt to the idea):
- Slide 1: Cover and hook — the most eye-catching image
- Middle slides: Story progression or educational content
- Last slide: Resolution, lesson or call to action

Return ONLY valid JSON:

{
  "title": "carousel title",
  "slides": [
    {
      "slide_number": 1,
      "purpose": "Cover and hook",
      "text_overlay": "Exact text to display on this slide",
      "characters_present": "Which characters appear",
      "scene": "Location and background",
      "action": "What each character is doing",
      "expressions": "Facial expressions and body language",
      "composition": "Framing and camera angle",
      "lighting": "Lighting and atmosphere",
      "continuity_note": "How this slide connects to the next",
      "negative_prompt": "What to avoid",
      "full_prompt": "Complete copy-paste-ready image generation prompt for this slide"
    }
  ]
}

RULES:
- Return exactly $count slides.
- Every "full_prompt" must be self-contained: include style, characters with exact descriptions, scene, action, expressions, composition, lighting, aspect ratio (square 1:1 for carousel), and negative prompt.
- All slides must look like parts of the same carousel: consistent characters, consistent visual style, consistent colour palette.
- Text overlays should be in $language.
- Never generate only an outline. Every slide must have a complete, copy-paste-ready prompt.
''';

  final response = await geminiPost(
    model: _model,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 8192,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned nothing.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.');
  }

  final title = (json['title'] as String?)?.trim() ?? idea;
  final rawSlides = (json['slides'] as List?) ?? [];
  final slides = rawSlides.whereType<Map<String, dynamic>>().map((s) {
    return CarouselSlidePrompt(
      slideNumber: (s['slide_number'] as num?)?.toInt() ?? 0,
      purpose: (s['purpose'] as String?)?.trim() ?? '',
      textOverlay: (s['text_overlay'] as String?)?.trim() ?? '',
      prompt: (s['full_prompt'] as String?)?.trim() ?? '',
    );
  }).where((s) => s.prompt.isNotEmpty).toList();

  if (slides.isEmpty) throw Exception('Gemini returned no slide prompts.');
  return CarouselPromptsResult(title: title, slides: slides);
}

// ── Feature 4: Gemini video prompts ──────────────────────────────────────────

class VideoPartPrompt {
  final int partNumber;
  final int totalParts;
  final String promptText;
  const VideoPartPrompt({
    required this.partNumber,
    required this.totalParts,
    required this.promptText,
  });
  String get title => 'Part $partNumber of $totalParts';
}

class GeminiVideoResult {
  final String storyTitle;
  final String storyFoundation;
  final List<VideoPartPrompt> parts;
  const GeminiVideoResult({
    required this.storyTitle,
    required this.storyFoundation,
    required this.parts,
  });
}

Future<GeminiVideoResult> generateGeminiVideoPrompts({
  required String idea,
  required int totalSeconds,
  required List<String> characters,
  String additionalInstructions = '',
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final key = _key(apiKey);
  final parts = (totalSeconds / 10).round().clamp(2, 6);
  final charBlock = _characterBlock(characters);

  final prompt = '''
You are a video content creator for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Convert this story idea into $parts connected 10-second video prompts for Gemini video generation.

IDEA: $idea
TOTAL DURATION: ${totalSeconds}s ($parts parts × 10 seconds each)
${additionalInstructions.trim().isEmpty ? '' : 'ADDITIONAL INSTRUCTIONS: $additionalInstructions'}

${_brandStyleBlock()}

CHARACTERS:
$charBlock

CHARACTER CONSISTENCY RULES:
- Use the exact descriptions above for every part. Do not paraphrase.
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Only the listed characters may appear. Never duplicate any character.
- Preserve each character's face, age, hair, outfit, colours and proportions across ALL parts.

STORY STRUCTURE:
- Part 1: Establish the problem/situation
- Middle parts: Develop the conflict or action
- Last part: Resolution and payoff
- Each part must have ONE clear purpose. Do not compress the whole story into one part.

CONTINUITY RULE: Part 2 must continue Part 1. Part 3 must continue Part 2. Every transition must be intentional.
The ending state of each part becomes the starting state of the next.

Return ONLY valid JSON:

{
  "story_title": "short title",
  "story_foundation": "2-3 sentences describing the complete story arc, characters, setting and lesson",
  "parts": [
    {
      "part_number": 1,
      "purpose": "What story beat this part communicates",
      "setting": "Exact location, background, lighting, props",
      "starting_state": "Exact character positions, expressions, prop positions at the START of this clip",
      "action_0_4s": "Specific visually clear action in first 4 seconds",
      "action_4_8s": "Continuation of action in seconds 4-8",
      "action_8_10s": "Complete this beat and establish transition to next part",
      "dialogue": "Exact dialogue if required, assigned to correct character, or empty string",
      "ending_state": "Exact character positions, expressions, props at the END of this clip",
      "continuity_from": "For Part 1: opening scene. For later parts: describe previous clip ending state",
      "continuity_into": "Exact ending positions and environment the next part must continue from",
      "negative_instructions": "No duplicate characters, no identity changes, no outfit changes, no distorted anatomy, no random text",
      "full_prompt": "Complete copy-paste-ready video generation prompt for this part"
    }
  ]
}

RULES FOR full_prompt:
Each "full_prompt" must be completely self-contained and include:
- TITLE, PART number, DURATION (exactly 10 seconds), FORMAT (vertical 9:16)
- STORY CONTEXT (brief explanation of the complete story)
- THIS PART'S PURPOSE
- CHARACTER LOCK with exact descriptions from above
- SCENE AND SETTING
- STARTING STATE
- CAMERA (opening framing, movement, ending framing)
- ACTION TIMELINE (0-4s, 4-8s, 8-10s)
- DIALOGUE AND AUDIO
- CONTINUITY FROM PREVIOUS PART
- CONTINUITY INTO NEXT PART
- VISUAL STYLE
- NEGATIVE INSTRUCTIONS

Return exactly $parts parts.
''';

  final response = await geminiPost(
    model: _model,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 8192,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned nothing.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.');
  }

  final title = (json['story_title'] as String?)?.trim() ?? idea;
  final foundation = (json['story_foundation'] as String?)?.trim() ?? '';
  final rawParts = (json['parts'] as List?) ?? [];

  final videoparts = rawParts.whereType<Map<String, dynamic>>().map((p) {
    return VideoPartPrompt(
      partNumber: (p['part_number'] as num?)?.toInt() ?? 0,
      totalParts: parts,
      promptText: (p['full_prompt'] as String?)?.trim() ?? '',
    );
  }).where((p) => p.promptText.isNotEmpty).toList();

  if (videoparts.isEmpty) throw Exception('Gemini returned no video prompts.');
  return GeminiVideoResult(
    storyTitle: title,
    storyFoundation: foundation,
    parts: videoparts,
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _key(String? apiKey) =>
    (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;
