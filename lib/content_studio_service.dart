import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'characters.dart';
import 'gemini_call.dart';
import 'master_prompt.dart';
import 'secrets.dart';
import 'prompts.dart';
import 'story_ideas.dart';
import 'prompt_preview.dart';

// ── Shared brand-aware prompt generation service ──────────────────────────────
//
// All four content features (Reel from Images, Image Prompt, Carousel Prompts,
// Gemini Video) share the same brand identity, character library and visual style.
// This service is the single place that knows all of that and produces the correct
// output for each requested deliverable.

const _model = 'gemini-3.8-flash';
// Light model for quick calls (checkStory, analyzeShareability, generateStoryIdea)
// Separate quota from the main model
const _lightModel = 'gemini-3.5-flash';
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
String _characterBlock(List<String> characterNames, {bool hasReferenceImages = false}) {
  if (hasReferenceImages) {
    if (characterNames.isEmpty) return kCharacterNames.join(', ');
    return characterNames.join(', ');
  }
  if (characterNames.isEmpty) {
    return kCharacterNames
        .map((name) => '- $name: ${characterDescription(name)}')
        .join('\n');
  }
  return characterNames
      .map((name) => '- $name: ${characterDescription(name)}')
      .join('\n');
}

/// Builds a voice/pattern guide for each character in the cast.
///
/// Injects each character's speech pattern so dialogue sounds authentic per-character
/// rather than from a single generic narrator voice. References the canonical
/// [kSpeechPatterns] from characters.dart.
String _characterVoiceBlock(List<String> characterNames) {
  final lines = <String>[];
  for (final name in characterNames) {
    final pattern = speechPattern(name);
    if (pattern.isNotEmpty) {
      lines.add('- $name: $pattern');
    }
  }
  if (lines.isEmpty) return '';
  return '\n\nCHARACTER VOICE PATTERNS:\n${lines.join('\n')}';
}

String _brandStyleBlock() =>
    '$kMasterPrompt\n\nNEGATIVE INSTRUCTIONS: $kNegativeInstructions\n'
    'Audience: ${BrandDefaults.audience}\n'
    'Brand: ${BrandDefaults.name} (${BrandDefaults.handle})';

String _videoBrandStyleBlock() =>
    '$kMasterPrompt\n\nNEGATIVE INSTRUCTIONS: $kNegativeInstructions\n'
    'Audience: ${BrandDefaults.audience}\n'
    'Brand: ${BrandDefaults.name}';

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
  "negative_prompt": "Duplicates, distorted anatomy, unwanted characters, incorrect outfits, watermarks, text errors",
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
- Only the listed characters may appear.
- Keep faces, hair, outfits and proportions IDENTICAL across all slides.
- NO on-screen text rendered in images — text_overlay is editor metadata only.

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
  final String startingState;
  final String endingState;
  final String setting;
  final String dialogue;
  final String continuityFrom;
  final String continuityInto;
  final String negativeInstructions;
  final String visualPrompt;
  final Map<String, dynamic>? onScreenText;

  const VideoPartPrompt({
    required this.partNumber,
    required this.totalParts,
    required this.promptText,
    this.textOverlay = '',
    this.purpose = '',
    this.fullPrompt = '',
    this.startingState = '',
    this.endingState = '',
    this.setting = '',
    this.dialogue = '',
    this.continuityFrom = '',
    this.continuityInto = '',
    this.negativeInstructions = '',
    this.visualPrompt = '',
    this.onScreenText,
  });

  String get title => 'Part $partNumber of $totalParts';
}

class GeminiVideoResult {
  final String storyTitle;
  final String storyFoundation;
  final List<VideoPartPrompt> parts;
  final String? caption;
  final List<String>? hashtags;
  final String? pinComment;
  final bool fromReadyPrompt;
  final List<String> validationErrors;

  const GeminiVideoResult({
    required this.storyTitle,
    required this.storyFoundation,
    required this.parts,
    this.caption,
    this.hashtags,
    this.pinComment,
    this.fromReadyPrompt = false,
    this.validationErrors = const [],
  });

  bool get isValid => validationErrors.isEmpty;

  bool get hasEngagementData =>
      (caption != null && caption!.isNotEmpty) ||
      (hashtags != null && hashtags!.isNotEmpty) ||
      (pinComment != null && pinComment!.isNotEmpty);

  /// Parses a [HookIdea.readyPrompt] string into a [GeminiVideoResult].
  /// Supports both legacy text format and new JSON format.
  /// Returns a result with validationErrors populated if parsing issues found.
  static GeminiVideoResult parseReadyPrompt(String readyPrompt, String title) {
    if (readyPrompt.trim().isEmpty) {
      // Backward compatibility: empty input falls back to single part
      return GeminiVideoResult(
        storyTitle: title,
        storyFoundation: title,
        parts: [
          VideoPartPrompt(
            partNumber: 1,
            totalParts: 1,
            promptText: title,
            purpose: 'Full Prompt',
            fullPrompt: title,
          ),
        ],
        fromReadyPrompt: true,
        validationErrors: ['Ready prompt is empty'],
      );
    }

    final trimmed = readyPrompt.trim();

    // Try JSON format first (newer structured format)
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return _parseJsonReadyPrompt(trimmed, title);
    }

    // Legacy text format (PROMPT:, Part 1:, Part 2:, Part 3:, etc.)
    return _parseLegacyReadyPrompt(trimmed, title);
  }

  /// Parse JSON-structured ready prompt (newer generation workflow)
  static GeminiVideoResult _parseJsonReadyPrompt(String jsonText, String title) {
    final errors = <String>[];
    Map<String, dynamic> json;

    try {
      json = jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      return GeminiVideoResult(
        storyTitle: title,
        storyFoundation: title,
        parts: [],
        fromReadyPrompt: true,
        validationErrors: ['Invalid JSON in readyPrompt: $e'],
      );
    }

    // Extract top-level fields
    final storyTitle = (json['story_title'] as String?)?.trim() ?? title;
    final storyFoundation =
        (json['story_foundation'] as String?)?.trim() ?? '';
    final caption = (json['caption'] as String?)?.trim();
    final hashtags = (json['hashtags'] as List?)?.cast<String>() ?? [];
    final pinComment = (json['pin_comment'] as String?)?.trim();

    // Parse parts
    final rawParts = (json['parts'] as List?) ?? [];
    final parts = <VideoPartPrompt>[];

    for (int i = 0; i < rawParts.length; i++) {
      final p = rawParts[i];
      if (p is! Map<String, dynamic>) {
        errors.add('Part ${i + 1}: not a valid object');
        continue;
      }

      final partNumber = (p['part_number'] as num?)?.toInt() ?? i + 1;
      final totalParts = rawParts.length;
      final purpose = (p['purpose'] as String?)?.trim() ?? '';
      final setting = (p['setting'] as String?)?.trim() ?? '';
      final startingState = (p['starting_state'] as String?)?.trim() ?? '';
      final action04s = (p['action_0_4s'] as String?)?.trim() ?? '';
      final action48s = (p['action_4_8s'] as String?)?.trim() ?? '';
      final action810s = (p['action_8_10s'] as String?)?.trim() ?? '';
      final dialogue = (p['dialogue'] as String?)?.trim() ?? '';
      final textOverlay = (p['text_overlay'] as String?)?.trim() ?? '';
      final endingState = (p['ending_state'] as String?)?.trim() ?? '';
      final continuityFrom = (p['continuity_from'] as String?)?.trim() ?? '';
      final continuityInto = (p['continuity_into'] as String?)?.trim() ?? '';
      final negativeInstructions =
          (p['negative_instructions'] as String?)?.trim() ?? '';
      final visualPrompt = (p['visual_prompt'] as String?)?.trim() ?? '';
      final fullPrompt = (p['full_prompt'] as String?)?.trim() ?? visualPrompt;
      final onScreenText = p['on_screen_text'];

      // Validate required fields
      if (visualPrompt.isEmpty && fullPrompt.isEmpty) {
        errors.add('Part $partNumber: missing visual_prompt/full_prompt');
      }
      if (textOverlay.isEmpty) {
        errors.add('Part $partNumber: missing text_overlay');
      }
      if (setting.isEmpty) {
        errors.add('Part $partNumber: missing setting');
      }
      if (startingState.isEmpty) {
        errors.add('Part $partNumber: missing starting_state');
      }
      if (endingState.isEmpty) {
        errors.add('Part $partNumber: missing ending_state');
      }

      // Build comprehensive prompt text for the part
      final promptText = _buildPartPromptText(
        partNumber: partNumber,
        totalParts: totalParts,
        purpose: purpose,
        setting: setting,
        startingState: startingState,
        action04s: action04s,
        action48s: action48s,
        action810s: action810s,
        dialogue: dialogue,
        textOverlay: textOverlay,
        endingState: endingState,
        continuityFrom: continuityFrom,
        continuityInto: continuityInto,
        negativeInstructions: negativeInstructions,
        visualPrompt: visualPrompt,
        fullPrompt: fullPrompt,
        onScreenText: onScreenText,
      );

      parts.add(VideoPartPrompt(
        partNumber: partNumber,
        totalParts: totalParts,
        promptText: promptText,
        textOverlay: textOverlay,
        purpose: purpose,
        fullPrompt: fullPrompt,
      ));
    }

    // Validate part count
    if (parts.length != 2 && parts.length != 3) {
      errors.add('Expected 2 or 3 parts, got ${parts.length}');
    }

    // Validate engagement data
    if (caption == null || caption.isEmpty) {
      errors.add('Missing caption');
    }
    if (hashtags.length != 5) {
      errors.add('Expected exactly 5 hashtags, got ${hashtags.length}');
    }
    if (pinComment == null || pinComment.isEmpty) {
      errors.add('Missing pinned comment');
    }

    return GeminiVideoResult(
      storyTitle: storyTitle,
      storyFoundation: storyFoundation.isNotEmpty ? storyFoundation : title,
      parts: parts,
      caption: caption,
      hashtags: hashtags.isNotEmpty ? hashtags : null,
      pinComment: pinComment,
      fromReadyPrompt: true,
      validationErrors: errors,
    );
  }

  /// Parse legacy text format ready prompt (PROMPT:, Part 1:, Part 2:, Part 3:, etc.)
  static GeminiVideoResult _parseLegacyReadyPrompt(String text, String title) {
    final errors = <String>[];
    final lines = text.split('\n');
    String foundation = '';
    final parts = <VideoPartPrompt>[];
    final Map<int, String> partContent = {};
    final Map<int, String> partPurpose = {};
    int maxPartNumber = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('PROMPT:')) {
        foundation = trimmed.substring(7).trim();
      } else if (_isPartHeader(trimmed, 1)) {
        partContent[1] = _partHeaderContent(trimmed, 1);
        partPurpose[1] = 'Hook & Problem';
        maxPartNumber = max(maxPartNumber, 1);
      } else if (_isPartHeader(trimmed, 2)) {
        partContent[2] = _partHeaderContent(trimmed, 2);
        partPurpose[2] = 'Twist & Escalation';
        maxPartNumber = max(maxPartNumber, 2);
      } else if (_isPartHeader(trimmed, 3)) {
        partContent[3] = _partHeaderContent(trimmed, 3);
        partPurpose[3] = 'Resolution & Moral';
        maxPartNumber = max(maxPartNumber, 3);
      } else if (trimmed.startsWith('On-Screen Text:') ||
          trimmed.startsWith('Audio/Dialogue') ||
          trimmed.startsWith('Outro:')) {
        // Skip these sections - they're metadata
      } else {
        // Append to the most recent part if any
        if (maxPartNumber > 0 && trimmed.isNotEmpty) {
          // Find the highest part number we've seen so far
          for (int p = maxPartNumber; p >= 1; p--) {
            if (partContent.containsKey(p)) {
              partContent[p] = '${partContent[p]}$trimmed\n';
              break;
            }
          }
        }
      }
    }

    // Build parts from collected content
    for (int i = 1; i <= maxPartNumber; i++) {
      if (partContent.containsKey(i)) {
        parts.add(VideoPartPrompt(
          partNumber: i,
          totalParts: maxPartNumber,
          promptText: partContent[i]!.trim(),
          purpose: partPurpose[i] ?? '',
          fullPrompt: partContent[i]!.trim(),
        ));
      }
    }

    // If we didn't find structured parts, wrap the whole prompt
    if (parts.isEmpty) {
      if (foundation.isNotEmpty) {
        parts.add(VideoPartPrompt(
          partNumber: 1,
          totalParts: 1,
          promptText: foundation,
          purpose: 'Full Prompt',
          fullPrompt: foundation,
        ));
      } else if (text.trim().isNotEmpty) {
        parts.add(VideoPartPrompt(
          partNumber: 1,
          totalParts: 1,
          promptText: text.trim(),
          purpose: 'Full Prompt',
          fullPrompt: text.trim(),
        ));
      } else {
        errors.add('No parsable content found in readyPrompt');
      }
    }

    // Extract "Final text overlay:" value into textOverlay field and strip
    // the overlay instruction from promptText/fullPrompt so it is never
    // accidentally passed as a rendering instruction to the video model.
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      final (cleanPrompt, overlay) = _extractTextOverlay(p.promptText);
      parts[i] = VideoPartPrompt(
        partNumber: p.partNumber,
        totalParts: p.totalParts,
        promptText: cleanPrompt,
        textOverlay: overlay,
        purpose: p.purpose,
        fullPrompt: cleanPrompt,
      );
    }

    // Validate legacy format
    if (parts.isEmpty) {
      errors.add('No parts could be parsed from legacy format');
    }
    if (parts.length != 1 && parts.length != 2 && parts.length != 3) {
      errors.add('Legacy format should have 1, 2, or 3 parts, got ${parts.length}');
    }

return GeminiVideoResult(
      storyTitle: title,
      storyFoundation: foundation.isNotEmpty ? foundation : title,
      parts: parts,
      fromReadyPrompt: true,
      validationErrors: errors,
    );
  }

  /// Build comprehensive prompt text for a part from JSON fields
  static String _buildPartPromptText({
    required int partNumber,
    required int totalParts,
    required String purpose,
    required String setting,
    required String startingState,
    required String action04s,
    required String action48s,
    required String action810s,
    required String dialogue,
    required String textOverlay,
    required String endingState,
    required String continuityFrom,
    required String continuityInto,
    required String negativeInstructions,
    required String visualPrompt,
    required String fullPrompt,
    dynamic onScreenText,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('PART $partNumber of $totalParts — $purpose');
    buffer.writeln('');

    if (setting.isNotEmpty) {
      buffer.writeln('SETTING: $setting');
      buffer.writeln('');
    }

    if (startingState.isNotEmpty) {
      buffer.writeln('STARTING STATE: $startingState');
      buffer.writeln('');
    }

    if (action04s.isNotEmpty) {
      buffer.writeln('ACTION 0-4s: $action04s');
    }
    if (action48s.isNotEmpty) {
      buffer.writeln('ACTION 4-8s: $action48s');
    }
    if (action810s.isNotEmpty) {
      buffer.writeln('ACTION 8-10s: $action810s');
    }
    buffer.writeln('');

    if (dialogue.isNotEmpty) {
      buffer.writeln('DIALOGUE: $dialogue');
      buffer.writeln('');
    }

    // On-screen text overlay (editor metadata)
    if (textOverlay.isNotEmpty) {
      buffer.writeln('ON-SCREEN TEXT OVERLAY (editor metadata): $textOverlay');
      buffer.writeln('');
    } else if (onScreenText != null) {
      // Handle structured on_screen_text object
      if (onScreenText is Map) {
        final lines = onScreenText.values
            .where((v) => v is String && (v as String).isNotEmpty)
            .cast<String>()
            .toList();
        if (lines.isNotEmpty) {
          buffer.writeln('ON-SCREEN TEXT OVERLAY (editor metadata): ${lines.join(' | ')}');
          buffer.writeln('');
        }
      }
    }

    if (endingState.isNotEmpty) {
      buffer.writeln('ENDING STATE: $endingState');
      buffer.writeln('');
    }

    if (continuityFrom.isNotEmpty) {
      buffer.writeln('CONTINUITY FROM: $continuityFrom');
      buffer.writeln('');
    }

    if (continuityInto.isNotEmpty) {
      buffer.writeln('CONTINUITY INTO: $continuityInto');
      buffer.writeln('');
    }

    if (negativeInstructions.isNotEmpty) {
      buffer.writeln('NEGATIVE INSTRUCTIONS: $negativeInstructions');
      buffer.writeln('');
    }

    // Visual prompt (the actual video generation prompt)
    if (visualPrompt.isNotEmpty) {
      buffer.writeln('VISUAL PROMPT: $visualPrompt');
      buffer.writeln('');
    } else if (fullPrompt.isNotEmpty) {
      buffer.writeln('VISUAL PROMPT: $fullPrompt');
      buffer.writeln('');
    }

    // Explicitly note: NO on-screen text in video frames
    buffer.writeln('NOTE: No on-screen text rendered in video frames. All overlay text is editor metadata only.');

    return buffer.toString().trim();
  }

  static (String, String) _extractTextOverlay(String promptText) {
    final lower = promptText.toLowerCase();
    final marker = 'final text overlay:';
    final idx = lower.indexOf(marker);
    if (idx == -1) return (promptText.trim(), '');

    final before = promptText.substring(0, idx).trim();
    final after = promptText.substring(idx + marker.length).trim();

    final moralIdx = after.toLowerCase().indexOf('moral:');
    String overlay;
    String suffix = '';

    if (moralIdx != -1) {
      overlay = after.substring(0, moralIdx).trim();
      suffix = after.substring(moralIdx).trim();
    } else {
      overlay = after.trim();
    }

    if (overlay.endsWith('.')) {
      overlay = overlay.substring(0, overlay.length - 1).trim();
    }

    final cleaned = suffix.isNotEmpty ? '$before $suffix' : before;
    return (cleaned, overlay);
  }

  static bool _isPartHeader(String line, int part) {
    final p = part.toString();
    final regex = RegExp(
        r'^(?:###\s*)?Part\s+' + p + r'(?:\s*\([^)]*\))?\s*:',
        caseSensitive: false);
    return regex.hasMatch(line);
  }

  static String _partHeaderContent(String line, int part) {
    final regex = RegExp(
        r'^(?:###\s*)?Part\s+' + part.toString() + r'(?:\s*\([^)]*\))?\s*:?\s*(.*)',
        caseSensitive: false);
    final match = regex.firstMatch(line);
    return match?.group(1)?.trim() ?? '';
  }
}

Future<GeminiVideoResult> generateGeminiVideoPrompts({
  required String idea,
  required int totalSeconds,
  required List<String> characters,
  String language = 'Hinglish',
  String additionalInstructions = '',
  bool hasReferenceImages = false,
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final parts = (totalSeconds / 10).round().clamp(2, 6);
  final charBlock = _characterBlock(characters, hasReferenceImages: hasReferenceImages);
  final voiceBlock = _characterVoiceBlock(characters);

  final characterInstructions = hasReferenceImages
      ? '''Use the attached reference images as the definitive character references.
Preserve each character's exact face, identity, hairstyle, clothing, colours, and proportions. Do not redesign or replace characters.'''
      : '''Use the exact descriptions above for every part. Do not paraphrase.
Preserve each character's face, age, hair, outfit, colours and proportions across ALL parts.''';

  final prompt = '''
You are a video content creator for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Convert this story idea into $parts connected 10-second video prompts for Gemini video generation.

IDEA: $idea
TOTAL DURATION: ${totalSeconds}s ($parts parts × 10 seconds each)
LANGUAGE: $language
${additionalInstructions.trim().isEmpty ? '' : 'ADDITIONAL INSTRUCTIONS: $additionalInstructions'}

${_videoBrandStyleBlock()}

CHARACTERS:
$charBlock$voiceBlock

CHARACTER CONSISTENCY RULES:
- $characterInstructions
- Only the listed characters may appear. Never duplicate any character.
- All dialogue and text_overlay must be in $language (Hinglish = Hindi words in English script).
- NO on-screen text rendered in video frames — text_overlay/on_screen_text are editor metadata only.

STORY STRUCTURE:
- Part 1: Establish the problem/situation — the relatable hook
- Middle parts: Develop the conflict or action
- Last part: Resolution and payoff
- Each part must have ONE clear purpose. Do not compress the whole story into one part.

SAFETY:
- Never depict unsafe behavior as entertainment — no choking hazards, no climbing on unstable furniture, no small objects near babies under 3.
- Solutions must show safe, realistic parenting.
- No fear-based scenarios that could frighten a sensitive child.

SHAREABILITY:
- Before writing, ask: "Why would one parent send this to another parent?"
  The story must name a specific parent who would send it.

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
  "caption": "1-2 lines for Instagram caption, warm, speaking to parents, ending with a question a parent will answer",
  "hashtags": ["5 exactly", "story-relevant", "not generic", "tags", "here"],
  "pin_comment": "One true thing about this situation in a parent's own house, then ask them about theirs.",
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
- CHARACTER LOCK (reference images or descriptions from above)
- SCENE AND SETTING
- STARTING STATE
 - CAMERA (opening framing, movement, ending framing)
 - ACTION TIMELINE (0-4s, 4-8s, 8-10s)
 - DIALOGUE AND AUDIO
 - ON-SCREEN TEXT OVERLAYS (editor metadata only, NOT rendered in video — max 2 short lines)
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
  bool hasReferenceImages = false,
  String? apiKey,
  void Function(String)? onWait,
}) async {
  final charBlock = _characterBlock(characters, hasReferenceImages: hasReferenceImages);

  final characterInstructions = hasReferenceImages
      ? '''Use the attached reference images as the definitive character references.
Preserve each character's exact face, identity, hairstyle, clothing, colours, and proportions. Do not redesign or replace characters.'''
      : '''Use the exact descriptions above. Do not paraphrase.
Preserve each character's face, age, hair, outfit, colours and proportions.''';

   final prompt = '''
You are a video content creator for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Regenerate ONLY Part $partNumber of $totalParts for this story. Keep the same story, same characters, same continuity — just produce a fresh version of this one part.

ORIGINAL IDEA: $idea
STORY FOUNDATION: $storyFoundation
PART TO REGENERATE: Part $partNumber of $totalParts
LANGUAGE: $language
${previousEndingState.trim().isEmpty ? '' : 'PREVIOUS PART ENDED WITH: $previousEndingState'}

${_videoBrandStyleBlock()}

CHARACTERS:
$charBlock

CHARACTER CONSISTENCY RULES:
- $characterInstructions
- Only the listed characters may appear.
- All dialogue and text_overlay must be in $language (Hinglish = Hindi words in English script).
- NO on-screen text rendered in video frames — text_overlay/on_screen_text are editor metadata only.

SAFETY:
- Never depict unsafe behavior as entertainment — no choking hazards, no climbing on unstable furniture, no small objects near babies under 3.
- Solutions must show safe, realistic parenting.

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

/// ============================================================================
/// PROMPT PREVIEW WRAPPERS
/// ============================================================================
///
/// These functions show the exact prompt before sending to Gemini.
/// Import 'prompt_preview.dart' and call these from UI code with a BuildContext.

/// Builds the analyzeShareability prompt without sending.
String buildAnalyzeShareabilityPrompt(String idea) {
  return '''You are analyzing content for "${BrandDefaults.name}", an Indian kids' education
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
}

const Map<String, dynamic> kShareabilityGenConfig = {
  'temperature': 0.3,
  'maxOutputTokens': 2048,
  'thinkingConfig': {'thinkingBudget': 0},
  'responseMimeType': 'application/json',
};

/// Calls analyzeShareability with a prompt preview dialog first.
Future<ShareabilityAnalysis> analyzeShareabilityWithPreview({
  required BuildContext context,
  required String idea,
  String? apiKey,
  void Function(String)? onWait,
  bool useSheet = false,
}) async {
  final prompt = buildAnalyzeShareabilityPrompt(idea);
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  return prompt.withPromptPreview<ShareabilityAnalysis>(
    context: context,
    title: 'Shareability Analysis',
    modelName: _model,
    generationConfig: kShareabilityGenConfig,
    useSheet: useSheet,
    onSend: () async {
      final text = await _geminiText(
        prompt, apiKey: key, maxTokens: 2048, temperature: 0.3, onWait: onWait);
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
    },
  );
}

/// Builds the generateCarouselPrompts prompt without sending.
String buildCarouselPromptsPrompt({
  required String idea,
  required int slideCount,
  required List<String> characters,
  String contentTheme = '',
  String language = 'Hinglish',
  String additionalInstructions = '',
}) {
  final charBlock = _characterBlock(characters);
  final count = slideCount.clamp(3, 12);

  return '''You are a creative director for "${BrandDefaults.name}", an Indian kids' education Instagram page.

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
- Only the listed characters may appear.
- Keep faces, hair, outfits and proportions IDENTICAL across all slides.
- NO on-screen text rendered in images — text_overlay is editor metadata only.

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
}

const Map<String, dynamic> kCarouselGenConfig = {
  'temperature': 0.7,
  'maxOutputTokens': 8192,
  'thinkingConfig': {'thinkingBudget': 0},
  'responseMimeType': 'application/json',
};

/// Calls generateCarouselPrompts with a prompt preview dialog first.
Future<CarouselPromptsResult> generateCarouselPromptsWithPreview({
  required BuildContext context,
  required String idea,
  required int slideCount,
  required List<String> characters,
  String contentTheme = '',
  String language = 'Hinglish',
  String additionalInstructions = '',
  String? apiKey,
  void Function(String)? onWait,
  bool useSheet = false,
}) async {
  final prompt = buildCarouselPromptsPrompt(
    idea: idea,
    slideCount: slideCount,
    characters: characters,
    contentTheme: contentTheme,
    language: language,
    additionalInstructions: additionalInstructions,
  );
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  return prompt.withPromptPreview<CarouselPromptsResult>(
    context: context,
    title: 'Carousel Prompts Generation',
    modelName: _model,
    generationConfig: kCarouselGenConfig,
    useSheet: useSheet,
    onSend: () async {
      final text = await _geminiText(prompt, apiKey: key, onWait: onWait);

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
    },
  );
}

/// Builds the generateGeminiVideoPrompts prompt without sending.
String buildGeminiVideoPrompt({
  required String idea,
  required int totalSeconds,
  required List<String> characters,
  String language = 'Hinglish',
  String additionalInstructions = '',
  bool hasReferenceImages = false,
}) {
  final parts = (totalSeconds / 10).round().clamp(2, 6);
  final charBlock = _characterBlock(characters, hasReferenceImages: hasReferenceImages);
  final voiceBlock = _characterVoiceBlock(characters);

  final characterInstructions = hasReferenceImages
      ? '''Use the attached reference images as the definitive character references.
Preserve each character's exact face, identity, hairstyle, clothing, colours, and proportions. Do not redesign or replace characters.'''
      : '''Use the exact descriptions above for every part. Do not paraphrase.
Preserve each character's face, age, hair, outfit, colours and proportions across ALL parts.''';

  return '''You are a video content creator for "${BrandDefaults.name}", an Indian kids' education Instagram page.

Convert this story idea into $parts connected 10-second video prompts for Gemini video generation.

IDEA: $idea
TOTAL DURATION: ${totalSeconds}s ($parts parts × 10 seconds each)
LANGUAGE: $language
${additionalInstructions.trim().isEmpty ? '' : 'ADDITIONAL INSTRUCTIONS: $additionalInstructions'}

${_videoBrandStyleBlock()}

CHARACTERS:
$charBlock$voiceBlock

CHARACTER CONSISTENCY RULES:
- $characterInstructions
- Only the listed characters may appear. Never duplicate any character.
- All dialogue and text_overlay must be in $language (Hinglish = Hindi words in English script).
- NO on-screen text rendered in video frames — text_overlay/on_screen_text are editor metadata only.

STORY STRUCTURE:
- Part 1: Establish the problem/situation — the relatable hook
- Middle parts: Develop the conflict or action
- Last part: Resolution and payoff
- Each part must have ONE clear purpose. Do not compress the whole story into one part.

SAFETY:
- Never depict unsafe behavior as entertainment — no choking hazards, no climbing on unstable furniture, no small objects near babies under 3.
- Solutions must show safe, realistic parenting.
- No fear-based scenarios that could frighten a sensitive child.

SHAREABILITY:
- Before writing, ask: "Why would one parent send this to another parent?"
  The story must name a specific parent who would send it.

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
  "caption": "1-2 lines for Instagram caption, warm, speaking to parents, ending with a question a parent will answer",
  "hashtags": ["5 exactly", "story-relevant", "not generic", "tags", "here"],
  "pin_comment": "One true thing about this situation in a parent's own house, then ask them about theirs.",
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
- CHARACTER LOCK (reference images or descriptions from above)
- SCENE AND SETTING
- STARTING STATE
 - CAMERA (opening framing, movement, ending framing)
 - ACTION TIMELINE (0-4s, 4-8s, 8-10s)
 - DIALOGUE AND AUDIO
 - ON-SCREEN TEXT OVERLAYS (editor metadata only, NOT rendered in video — max 2 short lines)
 - CONTINUITY FROM PREVIOUS PART
- CONTINUITY INTO NEXT PART
- VISUAL STYLE
- NEGATIVE INSTRUCTIONS

Return exactly $parts parts.
''';
}

/// Builds the MASTER 30-SECOND REEL prompt following the specification.
/// Generates 3 connected clips (0-10s, 10-20s, 20-30s) with full continuity.
String buildMasterReelPrompt({
  required String idea,
  required List<String> characters,
  String language = 'Hinglish',
  String additionalInstructions = '',
  bool hasReferenceImages = false,
}) {
  final charBlock = _characterBlock(characters, hasReferenceImages: hasReferenceImages);
  final parts = 3; // Fixed 30-second = 3 × 10s clips
  final characterInstructions = hasReferenceImages
      ? '''Use the attached reference images as the definitive character references.
Preserve each character's exact face, identity, hairstyle, clothing, colours, and proportions. Do not redesign or replace characters.'''
      : '''Use the exact descriptions above. Do not paraphrase.
Preserve each character's face, age, hair, outfit, colours and proportions across ALL parts.''';

  final voiceBlock = _characterVoiceBlock(characters);

  return '''You are a senior video director for "${BrandDefaults.name}", creating viral 30-second Instagram Reels (9:16 vertical) for Indian parents of preschoolers.

PRODUCE A COMPLETE 30-SECOND REEL IN 3 CONNECTED 10-SECOND CLIPS.

STORY IDEA: $idea
LANGUAGE: $language (Hinglish = Hindi words in English script, e.g. "Mumma ne kaha — beta, jaldi karo!")
${additionalInstructions.trim().isEmpty ? '' : 'ADDITIONAL INSTRUCTIONS: $additionalInstructions'}

${_videoBrandStyleBlock()}

CHARACTER LOCK (do not deviate):
$charBlock$voiceBlock
$characterInstructions

STORY STRUCTURE GUIDANCE:
- Clip 1 (0-10s): Hook & Problem — Show the real-life preschool problem from the STORY IDEA.
  Open with the child's immediate physical action. End on a freeze-frame that sets up Clip 2's twist.
- Clip 2 (10-20s): Twist & Escalation — A complication arises. The parent or another character
  responds. Tension peaks around second 18-20s. End on the moment the resolution begins.
- Clip 3 (20-30s): Resolution & Payoff — The small, believable solution. Warm family moment.
  Holds for smooth loop. No explicit "moral of the story" spoken — show it through action.

For each clip, extract specific actions, dialogue, and on-screen text from the STORY IDEA.
Do NOT use generic template placeholders — every field must contain STORY-SPECIFIC content.

SAFETY: (overrides any conflicting idea field)
- If the story involves fireworks, sparklers, flames, matches, candles, or similar items:
  Children must NEVER light, touch, hold, or approach them. Adults always handle them.
  Children watch from a genuinely safe distance. Show the safety rule first, then the payoff.
- Never depict unsafe behavior as entertainment — no choking hazards shown as play, no
  climbing on furniture that could collapse, no small objects near babies under 3.
- Solutions must show safe, realistic parenting — no magic fixes, no dismissing
  genuine feelings.
- No fear-based scenarios that could frighten a sensitive child.

CHARACTER CONTINUITY RULES:
  $characterInstructions

SHAREABILITY:
- Before writing, answer: "Why would one parent send this to another parent?"
  Include that specific, relatable hook. If the story cannot name a parent who would
  send it, the concept is too generic — make it specific.

CONTINUITY:
- Clip 1 ends at the exact frame Clip 2 starts from. Clip 2 ends at the exact frame Clip 3 starts from.
- No distorted hands or anatomy, no floating objects, no blurry faces.
- NO on-screen text of any kind: no captions, titles, subtitles, speech bubbles,
  readable signs, logos or watermarks. Text is added later in the editor.
- No closing card, moral, quote or summary at the end.
- Audience: Indian moms and parents of children aged 1-4
- Brand: Fun Learning With Palak

Return ONLY valid JSON:

{
  "story_title": "Short Hinglish title with emoji",
  "story_foundation": "2-3 sentences describing the complete 30s story arc, characters, setting and moral",
  "caption": "1-2 lines for Instagram caption, warm, speaking to parents, ending with a question a parent will answer",
  "hashtags": ["5 exactly", "story-relevant", "not generic", "tags", "here"],
  "pin_comment": "One true thing about this situation in a parent's own house, then ask them about theirs.",
  "parts": [
    {
      "part_number": 1,
      "purpose": "Hook & Problem - Establish the relatable struggle",
      "setting": "Exact location from the story idea (e.g. living room rug, kitchen counter, bedtime scene, Diwali courtyard at dusk)",
      "starting_state": "Exact character positions, expressions, prop positions at 0s — use character names from CHARACTER LOCK",
      "action_0_4s": "Specific visually clear action in first 4 seconds — name characters by their actual names from the story",
      "action_4_8s": "Continuation of action in seconds 4-8",
      "action_8_10s": "Complete this beat and establish transition to Clip 2 — describe the exact end pose",
      "dialogue": "Exact dialogue in Hinglish if required, assigned to the correct character, or empty string",
      "text_overlay": "Two lines max: Line 1 (0-3s hook), Line 2 (4-7s context)",
      "ending_state": "EXACT character positions, expressions, props at 10s - Clip 2 continues from HERE",
      "continuity_from": "Opening scene - establish the world",
      "continuity_into": "Describe the exact 10s frame that Clip 2 must continue from",
      "negative_instructions": "No duplicate characters, no identity changes, no outfit changes, no distorted anatomy, no off-screen text, no blurry faces. All text is editor metadata only — do NOT render in video.",
      "visual_prompt": "Self-contained copy-paste-ready AI video prompt for Clip 1 (0-10s): describe the exact scene from the story — who does what, where, with what props, in what lighting. Reference characters by their CHARACTER LOCK names. No on-screen text rendered.",
      "on_screen_text": {
        "line_1_0_3s": "Hook headline (max 3 words, Hinglish) — Editor Metadata, do NOT render in video",
        "line_2_4_7s": "Context text (max 5 words, Hinglish) — Editor Metadata, do NOT render in video"
      }
    },
    {
      "part_number": 2,
      "purpose": "Twist & Escalation - Complicate the situation",
      "setting": "Same location from Clip 1 unless the story moves. Background lighting and props must match.",
      "starting_state": "MUST match Clip 1 ending_state exactly — same positions, same expressions, same props",
      "action_0_4s": "Specific visually clear action in seconds 10-14 — a parent enters, a sibling joins, or the situation changes",
      "action_4_8s": "Continuation in seconds 14-18 — tension builds as the parent addresses the child's action",
      "action_8_10s": "Peak tension around second 18-20, then begin the resolution — describe exact end pose",
      "dialogue": "Exact dialogue in Hinglish if required, assigned to the correct character, or empty string",
      "text_overlay": "Two lines max: Line 1 (11-15s insight), Line 2 (16-20s tension)",
      "ending_state": "EXACT character positions, expressions, props at 20s - Clip 3 continues from HERE",
      "continuity_from": "Clip 1 ended with [describe exact 10s frame]",
      "continuity_into": "Describe the exact 20s frame that Clip 3 must continue from",
      "negative_instructions": "No duplicate characters, no identity changes, no outfit changes, no distorted anatomy, no off-screen text, no blurry faces. All text is editor metadata only — do NOT render in video.",
      "visual_prompt": "Self-contained copy-paste-ready AI video prompt for Clip 2 (10-20s): MUST start with 'Continuing seamlessly from the final frame of Clip 1'. Describe the exact scene — which character enters, what they do, how the child reacts. Reference characters by their CHARACTER LOCK names. No on-screen text rendered.",
      "on_screen_text": {
        "line_1_11_15s": "Parent insight (max 5 words, Hinglish) — Editor Metadata, do NOT render in video",
        "line_2_16_20s": "Tension text (max 5 words, Hinglish) — Editor Metadata, do NOT render in video"
      }
    },
    {
      "part_number": 3,
      "purpose": "Resolution & Moral - Heartwarming payoff",
      "setting": "Same location from Clip 2. Lighting stays consistent.",
      "starting_state": "MUST match Clip 2 ending_state exactly",
      "action_0_4s": "Specific visually clear action in seconds 20-24 — the parent's solution is applied",
      "action_4_8s": "Continuation in seconds 24-28 — characters react to the resolution, small improvement shown",
      "action_8_10s": "Final warm family moment at second 28-30 — hold for smooth loop",
      "dialogue": "Exact dialogue in Hinglish if required, assigned to the correct character, or empty string",
      "text_overlay": "Two lines max: Line 1 (21-26s moral takeaway), Line 2 (27-30s CTA)",
      "ending_state": "Final warm family tableau at 30s, ready for smooth loop",
      "continuity_from": "Clip 2 ended with [describe exact 20s frame]",
      "continuity_into": "Final frame - loops back to beginning vibe",
      "negative_instructions": "No duplicate characters, no identity changes, no outfit changes, no distorted anatomy, no off-screen text, no blurry faces. All text is editor metadata only — do NOT render in video.",
      "visual_prompt": "Self-contained copy-paste-ready AI video prompt for Clip 3 (20-30s): MUST start with 'Continuing directly from the final frame of Clip 2'. Describe the resolution — how the parent helps, how the child responds, the warm ending. Reference characters by their CHARACTER LOCK names. No on-screen text rendered.",
      "on_screen_text": {
        "line_1_21_26s": "Moral takeaway (max 5 words, Hinglish) — Editor Metadata, do NOT render in video",
        "line_2_27_30s": "Save this for later ❤️ — Editor Metadata, do NOT render in video"
      }
    }
  ]
}

RULES:
- Return exactly $parts parts.
- Every "visual_prompt" must be completely self-contained and describe specific, story-driven actions.
- All on_screen_text must be in $language.
- The story must be specific to an Indian household with relatable preschool moments.
- Character actions must be physically clear and animation-friendly.
- Only the listed characters (from CHARACTER LOCK above) may appear. Do NOT add characters not in that list.
- NO text rendered in video frames — all overlay text goes in the on_screen_text field only.
- If the story involves hazardous items (fireworks, flames, sparklers, etc.), safety rules above take priority and children must never handle them.
''';
}

const Map<String, dynamic> kVideoGenConfig = {
  'temperature': 0.7,
  'maxOutputTokens': 8192,
  'thinkingConfig': {'thinkingBudget': 0},
  'responseMimeType': 'application/json',
};

/// Calls generateGeminiVideoPrompts with a prompt preview dialog first.
Future<GeminiVideoResult> generateGeminiVideoPromptsWithPreview({
  required BuildContext context,
  required String idea,
  required int totalSeconds,
  required List<String> characters,
  String language = 'Hinglish',
  String additionalInstructions = '',
  bool hasReferenceImages = false,
  String? apiKey,
  void Function(String)? onWait,
  bool useSheet = false,
}) async {
  final parts = (totalSeconds / 10).round().clamp(2, 6);
  final prompt = buildGeminiVideoPrompt(
    idea: idea,
    totalSeconds: totalSeconds,
    characters: characters,
    language: language,
    additionalInstructions: additionalInstructions,
    hasReferenceImages: hasReferenceImages,
  );
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  return prompt.withPromptPreview<GeminiVideoResult>(
    context: context,
    title: 'Gemini Video Prompts Generation',
    modelName: _model,
    generationConfig: kVideoGenConfig,
    useSheet: useSheet,
    onSend: () async {
      final text = await _geminiText(prompt, apiKey: key, onWait: onWait);

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
    },
  );
}

/// Calls the MASTER 30-SECOND REEL prompt with preview dialog.
/// Uses the new specification format with 3 connected clips (0-10s, 10-20s, 20-30s).
Future<GeminiVideoResult> generateMasterReelPromptsWithPreview({
  required BuildContext context,
  required String idea,
  required List<String> characters,
  String language = 'Hinglish',
  String additionalInstructions = '',
  bool hasReferenceImages = false,
  String? apiKey,
  void Function(String)? onWait,
  bool useSheet = true,
}) async {
  final prompt = buildMasterReelPrompt(
    idea: idea,
    characters: characters,
    language: language,
    additionalInstructions: additionalInstructions,
    hasReferenceImages: hasReferenceImages,
  );
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  return prompt.withPromptPreview<GeminiVideoResult>(
    context: context,
    title: 'Master 30-Second Reel (3 Clips)',
    modelName: _model,
    generationConfig: kVideoGenConfig,
    useSheet: useSheet,
    onSend: () async {
      final text = await _geminiText(prompt, apiKey: key, onWait: onWait);

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
        // Use visual_prompt from new format, fallback to full_prompt
        final visualPrompt = (p['visual_prompt'] as String?)?.trim() ?? '';
        final fullPrompt = (p['full_prompt'] as String?)?.trim() ?? '';
        final promptText = visualPrompt.isNotEmpty ? visualPrompt : fullPrompt;
        
        // Use on_screen_text from new format
        final onScreenText = (p['on_screen_text'] as Map?) ?? {};
        final textOverlay = [
          onScreenText['line_1_0_3s'] ?? onScreenText['line_1_11_15s'] ?? onScreenText['line_1_21_26s'] ?? '',
          onScreenText['line_2_4_7s'] ?? onScreenText['line_2_16_20s'] ?? onScreenText['line_2_27_30s'] ?? '',
        ].where((s) => s.isNotEmpty).join(' | ');

        return VideoPartPrompt(
          partNumber: (p['part_number'] as num?)?.toInt() ?? 0,
          totalParts: 3,
          promptText: promptText,
          textOverlay: textOverlay,
        );
      }).where((p) => p.promptText.isNotEmpty).toList();

      if (videoparts.isEmpty) throw Exception('Gemini returned no video prompts.');
      return GeminiVideoResult(
        storyTitle: title,
        storyFoundation: foundation,
        parts: videoparts,
      );
    },
  );
}

/// Builds the evaluateIdea prompt (combines checkStory + analyzeShareability)
String buildEvaluateIdeaPrompt(String idea) {
  return '''${buildCheckStoryPrompt(idea)}

---

${buildAnalyzeShareabilityPrompt(idea)}''';
}

/// Calls evaluateIdea with a prompt preview dialog first.
/// Note: This shows both prompts (checkStory + analyzeShareability) in one dialog.
Future<IdeaEvaluation> evaluateIdeaWithPreview({
  required BuildContext context,
  required String idea,
  String? apiKey,
  void Function(String)? onWait,
  bool useSheet = false,
}) async {
  // For evaluateIdea, we show a combined preview of both calls
  final checkPrompt = buildCheckStoryPrompt(idea);
  final sharePrompt = buildAnalyzeShareabilityPrompt(idea);
  final combinedPrompt = '$checkPrompt\n\n---\n\n$sharePrompt';

  return combinedPrompt.withPromptPreview<IdeaEvaluation>(
    context: context,
    title: 'Idea Evaluation (Quality + Shareability)',
    modelName: '$_lightModel + $_model',
    generationConfig: {'note': 'Two separate calls: checkStory (temp 0.3) + analyzeShareability (temp 0.3)'},
    useSheet: useSheet,
    onSend: () async {
      onWait?.call('Checking story quality...');
      final check = await checkStory(idea, apiKey: apiKey, onWait: onWait);

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
    },
  );
}

