import 'dart:convert';

import 'brand_system.dart';
import 'characters.dart';
import 'gemini_call.dart';
import 'master_prompt.dart';
import 'secrets.dart';
import 'prompts.dart';
import 'story_ideas.dart';

// ── Shared brand-aware prompt generation service ──────────────────────────────
//
// All four content features (Reel from Images, Image Prompt, Carousel Prompts,
// Gemini Video) share the same brand identity, character library and visual style.
// This service is the single place that knows all of that and produces the correct
// output for each requested deliverable.

const _model = 'gemini-3.8-flash';
// Gemini 3.8 Flash supports thinkingConfig.thinkingBudget (lite models do not),
// and its 20/day quota gives the app headroom before hitting free-tier limits.
// See the quota table in documentation/app_overview.md.
//
// Fallback chain for 429: each model has its own 20/day quota, so trying the
// next one on a rate limit gives the app roughly an hour of headroom before
// every flash-class model is also exhausted. Never retry on 429 — switch
// models instead, because each retry still counts against the same quota.
const _fallbackModels = [
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
  'gemini-2.5-flash',
];
const _timeout = Duration(seconds: 180);

/// Calls Gemini via the shared HTTP path and returns the text response.
///
/// Uses the same retry, fallback, and daily-limit logic as every other Gemini
/// call in the app (see [geminiPost]). This avoids the parallel SDK code path
/// that was sending requests the key could not authenticate.
///
/// [temperature] and [maxTokens] are forwarded to generationConfig.
Future<String> _geminiText(
  String prompt, {
  String? apiKey,
  double temperature = 0.7,
  int maxTokens = 8192,
  void Function(String message)? onWait,
}) async {
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;
  final body = jsonEncode({
    'contents': [{'parts': [{'text': prompt}]}],
    'generationConfig': {
      'temperature': temperature,
      'maxOutputTokens': maxTokens,
      // The model spends thinking tokens out of the same budget, and a reply
      // cut off mid-JSON will not parse. Measured on this key: with thinking
      // on, a 1024 budget went 981 tokens to thinking and returned
      // MAX_TOKENS with a truncated body.
      'thinkingConfig': {'thinkingBudget': 0},
      'responseMimeType': 'application/json',
    },
  });

  // Try the primary model first, then each fallback on 429. Each model has
  // its own daily quota, so switching models extends the usable window.
  final models = [_model, ..._fallbackModels.where((m) => m != _model)];
  for (final model in models) {
    final response = await geminiPost(
      model: model,
      apiKey: key,
      timeout: _timeout,
      onWait: onWait,
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final text = jsonBody['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
      if (text.trim().isNotEmpty) return text;
      throw Exception('Gemini returned nothing.');
    }

    // On a daily limit (429 with daily marker), stop — switching models
    // will not help if the key itself is exhausted.
    if (response.statusCode == 429) {
      if (isDailyLimit(response.body)) {
        throw Exception(geminiBusyMessage(429, response.body));
      }
      // Per-minute 429: try the next model in the chain immediately.
      onWait?.call('Rate limited — switching to next model...');
      continue;
    }

    // 400 = model rejected the request (e.g. thinkingConfig unsupported).
    // Try the next model — a different one may accept it.
    if (response.statusCode == 400) {
      onWait?.call('Model rejected request — switching...');
      continue;
    }

    // 404 = model does not exist for this key. Try the next model.
    if (response.statusCode == 404) {
      onWait?.call('Switching to next model...');
      continue;
    }

    // 503 = model overload — geminiPost already retried internally.
    // Try the next model in the chain — a different model may have capacity.
    if (response.statusCode == 503) {
      onWait?.call('Model overloaded — switching...');
      continue;
    }

    // Any other error (400, 401, etc.) is a real problem — surface it.
    throw Exception('Gemini error ${response.statusCode}: ${response.body}');
  }

  throw StateError('All models in the fallback chain were exhausted.');
}

// ── Character block builder ───────────────────────────────────────────────────

/// Builds the character lock section from canonical descriptions.
String _characterBlock(List<String> characterNames) {
  if (characterNames.isEmpty) {
    return kCharacterNames
        .map((name) => '- $name: ${characterDescription(name)}')
        .join('\n');
  }
  return characterNames
      .map((name) => '- $name: ${characterDescription(name)}')
      .join('\n');
}

String _brandStyleBlock() =>
    '$kMasterPrompt\n\nNEGATIVE INSTRUCTIONS: $kNegativeInstructions\n'
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
- Use the exact descriptions above for every part. Do not paraphrase.

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

  final text = await _geminiText(prompt, apiKey: apiKey, maxTokens: 4096, onWait: onWait);

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

  final text = await _geminiText(prompt, apiKey: apiKey, onWait: onWait);

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
  final String textOverlay;
  final String purpose;
  final String fullPrompt;
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

class GeminiVideoResult {
  final String storyTitle;
  final String storyFoundation;
  final List<VideoPartPrompt> parts;
  const GeminiVideoResult({
    required this.storyTitle,
    required this.storyFoundation,
    required this.parts,
  });

  /// Parses a [HookIdea.readyPrompt] string into a [GeminiVideoResult].
  /// The readyPrompt format is expected to have "Part 1" and "Part 2" sections.
  static GeminiVideoResult parseReadyPrompt(String readyPrompt, String title) {
    final lines = readyPrompt.split('\n');
    String foundation = '';
    final parts = <VideoPartPrompt>[];
    String currentPart = '';
    int partNumber = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('PROMPT:')) {
        foundation = trimmed.substring(7).trim();
      } else if (_isPartHeader(trimmed, 1)) {
        if (partNumber == 1 && currentPart.isNotEmpty) {
          parts.add(VideoPartPrompt(
            partNumber: 1,
            totalParts: 2,
            promptText: currentPart.trim(),
            purpose: 'Setup / Hook',
            fullPrompt: currentPart.trim(),
          ));
        }
        partNumber = 1;
        currentPart = '';
      } else if (_isPartHeader(trimmed, 2)) {
        if (partNumber == 1 && currentPart.isNotEmpty) {
          parts.add(VideoPartPrompt(
            partNumber: 1,
            totalParts: 2,
            promptText: currentPart.trim(),
            purpose: 'Setup / Hook',
            fullPrompt: currentPart.trim(),
          ));
        }
        partNumber = 2;
        currentPart = '';
      } else if (trimmed.startsWith('On-Screen Text:') ||
          trimmed.startsWith('Audio/Dialogue')) {
        // Skip these sections
      } else {
        if (partNumber > 0 && trimmed.isNotEmpty) {
          currentPart += '$trimmed\n';
        }
      }
    }

    // Add the last part
    if (partNumber == 2 && currentPart.trim().isNotEmpty) {
      parts.add(VideoPartPrompt(
        partNumber: 2,
        totalParts: 2,
        promptText: currentPart.trim(),
        purpose: 'Payoff / Twist',
        fullPrompt: currentPart.trim(),
      ));
    }

    // If we didn't find structured parts, wrap the whole prompt
    if (parts.isEmpty && foundation.isNotEmpty) {
      parts.add(VideoPartPrompt(
        partNumber: 1,
        totalParts: 1,
        promptText: foundation,
        purpose: 'Full Prompt',
        fullPrompt: foundation,
      ));
    }

    return GeminiVideoResult(
      storyTitle: title,
      storyFoundation: foundation.isNotEmpty ? foundation : title,
      parts: parts,
    );
  }

  static bool _isPartHeader(String line, int part) {
    final p = part.toString();
    return line.contains('Part $p') ||
        line.contains('### Part $p') ||
        line.contains('Part $p (');
  }
}

Future<GeminiVideoResult> generateGeminiVideoPrompts({
  required String idea,
  required int totalSeconds,
  required List<String> characters,
  String language = 'Hinglish',
  String additionalInstructions = '',
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final parts = (totalSeconds / 10).round().clamp(2, 6);
  final charBlock = _characterBlock(characters);

  final prompt = '''
You are a video content creator for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Convert this story idea into $parts connected 10-second video prompts for Gemini video generation.

IDEA: $idea
TOTAL DURATION: ${totalSeconds}s ($parts parts × 10 seconds each)
LANGUAGE: $language
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
- All dialogue and text_overlay must be in $language (Hinglish = Hindi words in English script).

STORY STRUCTURE:
- Part 1: Establish the problem/situation
- Middle parts: Develop the conflict or action
- Last part: Resolution and payoff
- Each part must have ONE clear purpose. Do not compress the whole story into one part.

CONTINUITY RULE: Part 2 must continue Part 1. Part 3 must continue Part 2. Every transition must be intentional.
The ending state of each part becomes the starting state of the next.

LANGUAGE RULES:
- All dialogue must be in $language (Hinglish = Hindi words in English script, e.g. "Mumma ne kaha — beta, jaldi karo!").
- All on-screen text overlays must be in $language — short, readable, max 2 lines.
- Do not write in pure English or pure Hindi. Mix naturally, the way Indian parents actually speak.

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
       "text_overlay": "On-screen text for sound-off viewers, max 2 short lines",
       "ending_state": "Exact character positions, expressions, props at the END of this clip",
       "continuity_from": "For Part 1: opening scene. For later parts: describe previous clip ending state",
       "continuity_into": "Exact ending positions and environment the next part must continue from",
       "negative_instructions": "No duplicate characters, no identity changes, no outfit changes, no distorted anatomy, no off-screen text, no blurry faces",
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
- ON-SCREEN TEXT OVERLAYS (max 2 short lines, readable, for sound-off viewing)
- CONTINUITY FROM PREVIOUS PART
- CONTINUITY INTO NEXT PART
- VISUAL STYLE
- NEGATIVE INSTRUCTIONS

Return exactly $parts parts.
''';

   final text = await _geminiText(prompt, apiKey: apiKey, onWait: onWait);

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
      textOverlay: (p['text_overlay'] as String?)?.trim() ?? '',
    );
  }).where((p) => p.promptText.isNotEmpty).toList();

  if (videoparts.isEmpty) throw Exception('Gemini returned no video prompts.');
  return GeminiVideoResult(
    storyTitle: title,
    storyFoundation: foundation,
    parts: videoparts,
  );
}

// ── Feature 4b: Regenerate a single video part ───────────────────────────────

Future<VideoPartPrompt> regenerateSingleVideoPart({
  required String idea,
  required String storyFoundation,
  required int partNumber,
  required int totalParts,
  required List<String> characters,
  String language = 'Hinglish',
  String previousEndingState = '',
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final charBlock = _characterBlock(characters);

  final prompt = '''
You are a video content creator for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Regenerate ONLY Part $partNumber of $totalParts for this story. Keep the same story, same characters, same continuity — just produce a fresh version of this one part.

ORIGINAL IDEA: $idea
STORY FOUNDATION: $storyFoundation
PART TO REGENERATE: Part $partNumber of $totalParts
LANGUAGE: $language
${previousEndingState.trim().isEmpty ? '' : 'PREVIOUS PART ENDED WITH: $previousEndingState'}

${_brandStyleBlock()}

CHARACTERS:
$charBlock

CHARACTER CONSISTENCY RULES:
- Use the exact descriptions above. Do not paraphrase.
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Only the listed characters may appear.
- All dialogue and text_overlay must be in $language (Hinglish = Hindi words in English script).

Return ONLY valid JSON for this single part:

{
  "part_number": $partNumber,
  "purpose": "What story beat this part communicates",
  "text_overlay": "On-screen text for sound-off viewers, max 2 short lines",
  "full_prompt": "Complete copy-paste-ready video generation prompt for this part, self-contained with TITLE, PART $partNumber of $totalParts, DURATION 10 seconds, FORMAT vertical 9:16, STORY CONTEXT, CHARACTER LOCK, SCENE, STARTING STATE, CAMERA, ACTION TIMELINE 0-4s/4-8s/8-10s, DIALOGUE IN $language, ON-SCREEN TEXT OVERLAYS IN $language, CONTINUITY FROM/INTO, VISUAL STYLE, NEGATIVE INSTRUCTIONS"
}
''';

   final text = await _geminiText(
    prompt, apiKey: apiKey, maxTokens: 4096, onWait: onWait);

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.');
  }

  final promptText = (json['full_prompt'] as String?)?.trim() ?? '';
  if (promptText.isEmpty) throw Exception('Gemini returned an empty prompt.');

  return VideoPartPrompt(
    partNumber: partNumber,
    totalParts: totalParts,
    promptText: promptText,
    textOverlay: (json['text_overlay'] as String?)?.trim() ?? '',
  );
}

// ── Idea Evaluation ─────────────────────────────────────────────────────────────
//
// Before any generation happens, the idea is checked for story quality and for
// shareability. This is the gate that decides whether the idea is worth spending
// an API request on, and which hook to use.

/// The result of analyzing why a parent would send this idea to another parent.
class ShareabilityAnalysis {
  /// The specific parent archetype who would send it.
  /// e.g. "Mumma of a 3-year-old who refuses vegetables at dinner"
  final String sender;

  /// Who they would send it to.
  /// e.g. "a parent whose child also pushes food away"
  final String recipient;

  /// Why they would send it — one specific, actionable sentence.
  final String reason;

  /// How confident the analysis is: "high", "medium", or "low".
  final String confidence;

  /// A practical tip to strengthen the shareability, or empty.
  final String note;

  const ShareabilityAnalysis({
    required this.sender,
    required this.recipient,
    required this.reason,
    required this.confidence,
    this.note = '',
  });

  bool get isHighConfidence =>
      confidence.toLowerCase().trim() == 'high';

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'recipient': recipient,
        'reason': reason,
        'confidence': confidence,
        'note': note,
      };

  factory ShareabilityAnalysis.fromJson(Map<String, dynamic> json) {
    return ShareabilityAnalysis(
      sender: (json['sender'] as String?)?.trim() ?? '',
      recipient: (json['recipient'] as String?)?.trim() ?? '',
      reason: (json['reason'] as String?)?.trim() ?? '',
      confidence: (json['confidence'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
    );
  }
}

/// The combined result of evaluating an idea before production.
///
/// Holds the story quality check (10 criteria + 5 hooks) and the shareability
/// analysis (who shares, to whom, why). The approval flow on
/// [IdeaReviewScreen] fills in [selectedHook] and [isApproved] as the user
/// works through it.
class IdeaEvaluation {
  final StoryCheck check;
  final ShareabilityAnalysis shareability;
  final HookChoice? selectedHook;
  final bool isApproved;

  const IdeaEvaluation({
    required this.check,
    required this.shareability,
    this.selectedHook,
    this.isApproved = false,
  });

  IdeaEvaluation copyWith({
    StoryCheck? check,
    ShareabilityAnalysis? shareability,
    HookChoice? selectedHook,
    bool? isApproved,
  }) {
    return IdeaEvaluation(
      check: check ?? this.check,
      shareability: shareability ?? this.shareability,
      selectedHook: selectedHook ?? this.selectedHook,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

/// Asks Gemini to identify who would share this idea, to whom, and why.
///
/// Done before production: if no specific sender and recipient can be named,
/// the idea is not share-worthy and should be reworked first.
Future<ShareabilityAnalysis> analyzeShareability({
  required String idea,
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final prompt = '''
You are analyzing content for "${BrandDefaults.name}", an Indian kids' education
Instagram page. The audience is Indian moms and parents of children aged 1-4.

Analyze the shareability of this story idea:

IDEA: $idea

Answer these exact questions in JSON:
1. SENDER — which specific parent archetype would send this?
   e.g. "Mumma of a 3-year-old who refuses vegetables"
2. RECIPIENT — who would they send it to?
   e.g. "a parent whose child also pushes food away"
3. REASON — why would they send it? One specific, actionable sentence.
4. CONFIDENCE — how confident are you this will be shared?
   (high, medium, or low)
5. NOTE — one practical tip to strengthen the shareability, or empty string.

Return ONLY valid JSON:
{
  "sender": "specific parent who would send this",
  "recipient": "who they would send it to",
  "reason": "why they would send it — specific and actionable",
  "confidence": "high",
  "note": "practical tip or empty string"
}

Be honest: a share is worth more than a view, and a post that cannot name a
specific sender and recipient is not ready.
''';

  final text = await _geminiText(
    prompt, apiKey: apiKey, maxTokens: 2048, temperature: 0.3, onWait: onWait);
  if (text.trim().isEmpty) {
    throw Exception('Gemini returned no shareability analysis.');
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON for shareability.');
  }

  if ((json['sender'] as String? ?? '').trim().isEmpty &&
      (json['recipient'] as String? ?? '').trim().isEmpty) {
    throw Exception(
        'Shareability analysis was empty — try rewording the idea.');
  }

  return ShareabilityAnalysis.fromJson(json);
}

/// Evaluates an idea before production: quality check + shareability analysis.
///
/// Reuses [checkStory] for the 10-criteria story quality score and hooks, then
/// runs [analyzeShareability] for the share trigger. Returns a combined
/// [IdeaEvaluation] that the review screen presents to the user.
Future<IdeaEvaluation> evaluateIdea({
  required String idea,
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final trimmed = idea.trim();
  if (trimmed.length < 15) {
    throw Exception('Write a bit more of the story first.');
  }

  onWait?.call('Checking story quality...');
  final check = await checkStory(
    idea,
    apiKey: apiKey,
    onWait: onWait,
  );

  onWait?.call('Analyzing shareability...');
  final shareability = await analyzeShareability(
    idea: idea,
    apiKey: apiKey,
    onWait: onWait,
  );

  return IdeaEvaluation(
    check: check,
    shareability: shareability,
  );
}

// ── Engagement Package ────────────────────────────────────────────────────────
//
// Every content package now includes the full engagement toolkit: caption,
// hashtags, pinned comment, and suggested comment replies. This is shared
// across all four content features so every post can publish-ready.

/// One suggested reply for a specific comment situation.
class SuggestedReply {
  /// The situation this reply is for, e.g. "similar experience",
  /// "tip shared", "question asked", "disagreement",
  /// "emotional share", "compliment".
  final String situation;

  /// The reply text — always ends with a question.
  final String text;

  const SuggestedReply(this.situation, this.text);
}

/// The complete engagement package: caption, hashtags, pinned comment,
/// suggested comment replies, and a follow reason.
///
/// Generated alongside the main content so every post is publish-ready.
class EngagementPackage {
  /// The caption text (without hashtags — those are separate).
  final String caption;

  /// Exactly five relevant hashtags.
  final List<String> hashtags;

  /// One recommended pinned comment ending with a question.
  final String pinnedComment;

  /// Six suggested replies for common comment situations, each ending
  /// with a relevant question.
  final List<SuggestedReply> suggestedReplies;

  /// One genuine reason a viewer would want to follow the brand.
  final String followReason;

  const EngagementPackage({
    required this.caption,
    required this.hashtags,
    required this.pinnedComment,
    required this.suggestedReplies,
    required this.followReason,
  });

  /// Caption plus hashtags as one block for pasting into Instagram.
  String get forInstagram =>
      hashtags.isEmpty ? caption : '$caption\n\n${hashtags.join(' ')}';

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'hashtags': hashtags,
        'pinnedComment': pinnedComment,
        'suggestedReplies':
            suggestedReplies.map((r) => {'situation': r.situation, 'text': r.text}).toList(),
        'followReason': followReason,
      };

  factory EngagementPackage.fromJson(Map<String, dynamic> json) {
    final rawReplies = (json['suggestedReplies'] as List?) ?? [];
    final replies = rawReplies.whereType<Map<String, dynamic>>().map((r) {
      return SuggestedReply(
        (r['situation'] as String?)?.trim() ?? '',
        (r['text'] as String?)?.trim() ?? '',
      );
    }).toList();

    return EngagementPackage(
      caption: (json['caption'] as String?)?.trim() ?? '',
      hashtags: ((json['hashtags'] as List?) ?? [])
          .whereType<String>()
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList(),
      pinnedComment: (json['pinnedComment'] as String?)?.trim() ?? '',
      suggestedReplies: replies,
      followReason: (json['followReason'] as String?)?.trim() ?? '',
    );
  }
}

/// The six situations for which we generate suggested replies.
const kReplySituations = [
  'similar experience',
  'tip shared',
  'question asked',
  'disagreement',
  'emotional share',
  'compliment',
];

/// Generates the complete engagement package for a content idea.
///
/// Includes caption, exactly 5 hashtags, pinned comment with a question,
/// six suggested comment replies (each ending with a question), and
/// a follow reason.
Future<EngagementPackage> generateEngagementPackage({
  required String idea,
  required HookChoice? selectedHook,
  required String contentPurpose,
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final hookText = selectedHook?.text ?? '';
  final trimmed = idea.trim();
  if (trimmed.length < 10) {
    throw Exception('Write a bit more of the story first.');
  }

  onWait?.call('Writing caption and hashtags...');

  final prompt = '''
You are the caption writer and engagement assistant for
"${BrandDefaults.name}", an Indian kids' education Instagram page.

IDEA: $idea

SELECTED HOOK: ${hookText.isEmpty ? 'none' : hookText}

CONTENT PURPOSE: $contentPurpose

Your audience is Indian parents and caregivers of children aged 1-4.

Write the complete engagement package in exactly this JSON shape:

{
  "caption": "A caption that complements the content, not a summary of it. Use the brand voice: warm, playful, parent-relatable. Include one natural CTA if appropriate. Keep it short enough for Instagram (2-3 short paragraphs max).",
  "hashtags": ["#funlearningwithpalak", "#noscreenactivities", "#playbasedlearning", "#toddleractivities", "#indianmoms"],
  "pinnedComment": "One natural conversation-starter ending with a question, not 'Comment below!' or a repeat of the caption.",
  "suggestedReplies": [
    {"situation": "similar experience", "text": "Acknowledges + ends with a question."},
    {"situation": "tip shared", "text": "Acknowledges + ends with a question."},
    {"situation": "question asked", "text": "Answers the question first, then asks a relevant follow-up."},
    {"situation": "disagreement", "text": "Acknowledges respectfully + ends with a question."},
    {"situation": "emotional share", "text": "Acknowledges the emotion + ends with a question."},
    {"situation": "compliment", "text": "Thanks + ends with a question."}
  ],
  "followReason": "One genuine sentence for why a viewer interested in this content would want to follow the brand."
}

RULES:
- Exactly 5 hashtags. No more, no less. Always include #funlearningwithpalak.
- Every suggested reply must end with a question mark.
- The pinned comment must end with a question mark.
- Do not repeat the caption verbatim in the pinned comment.
- Do not invent statistics or performance claims.
- Match the brand voice: warm, playful, parent-relatable, simple.
- Keep the caption specific to this actual content, not generic.
''';

  final text = await _geminiText(
    prompt, apiKey: apiKey, maxTokens: 4096, temperature: 0.7, onWait: onWait);
  if (text.trim().isEmpty) {
    throw Exception('Gemini returned no engagement package.');
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON for engagement package.');
  }

  final result = EngagementPackage.fromJson(json);

  if (result.hashtags.length != 5) {
    throw Exception(
        'Engagement package must include exactly 5 hashtags, got ${result.hashtags.length}.');
  }
  if (!result.pinnedComment.endsWith('?')) {
    throw Exception('Pinned comment must end with a question mark.');
  }
  for (final reply in result.suggestedReplies) {
    if (!reply.text.endsWith('?')) {
      throw Exception(
          'Suggested reply for "${reply.situation}" must end with a question mark.');
    }
  }

  return result;
}

