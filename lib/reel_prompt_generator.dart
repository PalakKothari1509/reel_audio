import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'characters.dart';
import 'content_ideas.dart';
import 'content_studio_service.dart';
import 'gemini_video_master_prompt.dart';

/// Canonical 30-second, 3-clip Reel prompt generator.
///
/// Single authoritative entry point for the three-connected-clip workflow.
/// Reuses existing brand rules, character library, and master prompt template.
class ReelPromptGenerator {
  ReelPromptGenerator();

  /// Generates the complete master prompt for a 30-second, 3-clip Reel.
  ///
  /// [idea] is the selected HookIdea from the content library.
  /// [selectedCharacters] overrides the idea's defaultCast if provided.
  /// [additionalInstructions] are user-provided additions.
  /// [hasReferenceImages] indicates whether Gemini reference images are attached.
  ///
  /// Returns the fully rendered prompt string ready for Gemini.
  String generateMasterPrompt({
    required HookIdea idea,
    List<String>? selectedCharacters,
    String additionalInstructions = '',
    bool hasReferenceImages = false,
  }) {
    final cast = (selectedCharacters ?? idea.defaultCast)
        .where(kCharacterNames.contains)
        .toList();

    final vars = VideoPromptVariables(
      storyTitle: idea.title.isNotEmpty ? idea.title : idea.cover,
      storyIdea: idea.storyDetail.isNotEmpty
          ? idea.storyDetail
          : idea.asStoryText(),
      realLifeProblem: idea.problem,
      learningOutcome: idea.lesson,
      selectedCharacters: cast,
      visualStyle: BrandDefaults.visualStyle,
      overallTone: 'Warm, relatable, emotionally engaging',
      videoGenerator: 'Runway Gen-3 / Kling / Luma',
      language: 'Hinglish',
      hasReferenceImages: hasReferenceImages,
      storyHook: _buildStoryHookSource(idea),
    );

    return renderVideoMasterPrompt(vars);
  }

  /// Builds the authoritative story hook source from a HookIdea.
  StoryHookSource _buildStoryHookSource(HookIdea idea) {
    return StoryHookSource(
      problem: idea.problem,
      twist: _extractTwist(idea),
      resolution: _extractResolution(idea),
      lesson: idea.lesson,
      setting: idea.setting,
      sceneDetail: idea.sceneDetail,
      dialogue: idea.dialogue,
      mess: idea.mess,
      endingBeat: idea.endingBeat,
    );
  }

  String _extractTwist(HookIdea idea) {
    if (idea.storyDetail.isEmpty) return '';
    final lines = idea.storyDetail.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('twist:')) {
        return trimmed.substring(6).trim();
      }
    }
    return '';
  }

  String _extractResolution(HookIdea idea) {
    if (idea.storyDetail.isEmpty) return '';
    final lines = idea.storyDetail.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('resolution:')) {
        return trimmed.substring(11).trim();
      }
    }
    return '';
  }

  /// Parses Gemini's JSON response into a structured result.
  ///
  /// Maintains compatibility with existing [GeminiVideoResult] consumers.
  GeminiVideoResult parseResponse(String jsonText, String fallbackTitle) {
    return GeminiVideoResult.parseReadyPrompt(jsonText, fallbackTitle);
  }

  /// Validates a parsed JSON response against the Phase 10 schema.
  ///
  /// Returns null if valid, otherwise a list of validation errors.
  List<String>? validateResponse(Map<String, dynamic> json) {
    final validation = validateVideoMasterPromptJson(json);
    if (validation.isValid) return null;
    return validation.errors;
  }
}

/// Input bundle for the canonical generator.
///
/// Wraps the data needed to produce a 30-second, 3-clip Reel prompt.
@immutable
class ReelGenerationInput {
  final HookIdea idea;
  final List<String>? selectedCharacters;
  final String additionalInstructions;
  final bool hasReferenceImages;

  const ReelGenerationInput({
    required this.idea,
    this.selectedCharacters,
    this.additionalInstructions = '',
    this.hasReferenceImages = false,
  });

  ReelGenerationInput copyWith({
    HookIdea? idea,
    List<String>? selectedCharacters,
    String? additionalInstructions,
    bool? hasReferenceImages,
  }) {
    return ReelGenerationInput(
      idea: idea ?? this.idea,
      selectedCharacters: selectedCharacters ?? this.selectedCharacters,
      additionalInstructions: additionalInstructions ?? this.additionalInstructions,
      hasReferenceImages: hasReferenceImages ?? this.hasReferenceImages,
    );
  }
}

/// Structured story beats extracted from a HookIdea.
///
/// Used for the global overlay timeline and clip mapping.
@immutable
class StoryBeats {
  final String title;
  final String problem;
  final String childReaction;
  final String parentResponse;
  final String turningPoint;
  final String resolution;
  final String endingAction;
  final List<String> dialogueLines;
  final Map<String, String> overlayTexts; // timestamp -> text
  final List<String> requiredProps;
  final String setting;

  const StoryBeats({
    required this.title,
    required this.problem,
    required this.childReaction,
    required this.parentResponse,
    required this.turningPoint,
    required this.resolution,
    required this.endingAction,
    required this.dialogueLines,
    required this.overlayTexts,
    required this.requiredProps,
    required this.setting,
  });

  /// Extracts beats from a HookIdea using its structured fields.
  static StoryBeats fromHookIdea(HookIdea idea) {
    final dialogueLines = idea.dialogue
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    final overlayTexts = <String, String>{};
    if (idea.storyDetail.isNotEmpty) {
      final lines = idea.storyDetail.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        final overlayMatch = RegExp(r'\[(\d+-\d+s?)\]\s*[:\-]?\s*(.+)').firstMatch(trimmed);
        if (overlayMatch != null) {
          overlayTexts[overlayMatch.group(1)!] = overlayMatch.group(2)!.trim();
        }
      }
    }

    return StoryBeats(
      title: idea.title.isNotEmpty ? idea.title : idea.cover,
      problem: idea.problem,
      childReaction: idea.mess,
      parentResponse: idea.innerThought,
      turningPoint: _extractTwistStatic(idea),
      resolution: _extractResolutionStatic(idea),
      endingAction: idea.endingBeat,
      dialogueLines: dialogueLines,
      overlayTexts: overlayTexts,
      requiredProps: _extractProps(idea),
      setting: idea.setting.isNotEmpty ? idea.setting : 'Indian home, warm daylight',
    );
  }

  static String _extractTwistStatic(HookIdea idea) {
    if (idea.storyDetail.isEmpty) return '';
    final lines = idea.storyDetail.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('twist:')) {
        return trimmed.substring(6).trim();
      }
    }
    return '';
  }

  static String _extractResolutionStatic(HookIdea idea) {
    if (idea.storyDetail.isEmpty) return '';
    final lines = idea.storyDetail.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('resolution:')) {
        return trimmed.substring(11).trim();
      }
    }
    return '';
  }

  static List<String> _extractProps(HookIdea idea) {
    final props = <String>[];
    final text = '${idea.sceneDetail} ${idea.storyDetail}'.toLowerCase();
    final propKeywords = [
      'ball', 'toy', 'phone', 'book', 'shoe', 'cup', 'plate', 'spoon',
      'blanket', 'pillow', 'teddy', 'car', 'blocks', 'crayon', 'paper',
      'chocolate', 'cookie', 'milk', 'water', 'bath', 'towel', 'brush',
      'slide', 'swing', 'sand', 'bucket', 'shovel', 'bubble', 'kite',
    ];
    for (final keyword in propKeywords) {
      if (text.contains(keyword)) props.add(keyword);
    }
    return props;
  }
}

/// Global overlay timeline preserving exact user-supplied text and timing.
///
/// Each entry maps to editor metadata only — never rendered in video frames.
@immutable
class OverlayTimelineEntry {
  final String text;
  final double startSeconds;
  final double endSeconds;
  final int clipIndex; // 0, 1, 2 for clips 1, 2, 3
  final bool editorOnly;
  final String? animationHint;

  const OverlayTimelineEntry({
    required this.text,
    required this.startSeconds,
    required this.endSeconds,
    required this.clipIndex,
    this.editorOnly = true,
    this.animationHint,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'start_seconds': startSeconds,
    'end_seconds': endSeconds,
    'clip': clipIndex + 1,
    'editor_only': editorOnly,
    if (animationHint != null) 'animation': animationHint,
  };

  static OverlayTimelineEntry fromJson(Map<String, dynamic> json) {
    return OverlayTimelineEntry(
      text: json['text'] as String? ?? '',
      startSeconds: (json['start_seconds'] as num?)?.toDouble() ?? 0,
      endSeconds: (json['end_seconds'] as num?)?.toDouble() ?? 0,
      clipIndex: (json['clip'] as int? ?? 1) - 1,
      editorOnly: json['editor_only'] as bool? ?? true,
      animationHint: json['animation'] as String?,
    );
  }
}

/// Complete Reel generation output matching the Phase 10 JSON schema.
///
/// This is the canonical output format. Existing [GeminiVideoResult] consumers
/// continue to work via [toGeminiVideoResult()].
@immutable
class ReelGenerationOutput {
  final String storyTitle;
  final String storyFoundation;
  final String shareabilityReason;
  final String caption;
  final List<String> hashtags;
  final String pinComment;
  final String cta;
  final int totalDurationSeconds;
  final String aspectRatio;
  final List<Map<String, dynamic>> storyBeats;
  final List<Map<String, dynamic>> overlayTimeline;
  final List<ReelClipOutput> clips;
  final List<String> finalEditorInstructions;
  final List<String> qualityControl;

  const ReelGenerationOutput({
    required this.storyTitle,
    required this.storyFoundation,
    required this.shareabilityReason,
    required this.caption,
    required this.hashtags,
    required this.pinComment,
    required this.cta,
    required this.totalDurationSeconds,
    required this.aspectRatio,
    required this.storyBeats,
    required this.overlayTimeline,
    required this.clips,
    required this.finalEditorInstructions,
    required this.qualityControl,
  });

  /// Converts to the existing [GeminiVideoResult] for backward compatibility.
  GeminiVideoResult toGeminiVideoResult() {
    return GeminiVideoResult(
      storyTitle: storyTitle,
      storyFoundation: storyFoundation,
      parts: clips.map((c) => c.toVideoPartPrompt()).toList(),
      caption: caption,
      hashtags: hashtags,
      pinComment: pinComment,
      validationErrors: const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'story_title': storyTitle,
    'story_foundation': storyFoundation,
    'shareability_reason': shareabilityReason,
    'caption': caption,
    'hashtags': hashtags,
    'pin_comment': pinComment,
    'cta': cta,
    'total_duration_seconds': totalDurationSeconds,
    'aspect_ratio': aspectRatio,
    'story_beats': storyBeats,
    'overlay_timeline': overlayTimeline,
    'parts': clips.map((c) => c.toJson()).toList(),
    'final_editor_instructions': finalEditorInstructions,
    'quality_control': qualityControl,
  };

  factory ReelGenerationOutput.fromJson(Map<String, dynamic> json) {
    return ReelGenerationOutput(
      storyTitle: json['story_title'] as String? ?? '',
      storyFoundation: json['story_foundation'] as String? ?? '',
      shareabilityReason: json['shareability_reason'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      hashtags: (json['hashtags'] as List?)?.cast<String>() ?? [],
      pinComment: json['pin_comment'] as String? ?? '',
      cta: json['cta'] as String? ?? '',
      totalDurationSeconds: json['total_duration_seconds'] as int? ?? 30,
      aspectRatio: json['aspect_ratio'] as String? ?? '9:16',
      storyBeats: (json['story_beats'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      overlayTimeline: (json['overlay_timeline'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      clips: (json['parts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((m) => ReelClipOutput.fromJson(m))
              .toList() ??
          [],
      finalEditorInstructions: (json['final_editor_instructions'] as List?)?.cast<String>() ?? [],
      qualityControl: (json['quality_control'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Single 10-second clip output with all required fields.
@immutable
class ReelClipOutput {
  final int partNumber;
  final String timeRange;
  final String purpose;
  final String setting;
  final String startingState;
  final String action0to4s;
  final String action4to8s;
  final String action8to10s;
  final List<Map<String, String>> dialogue;
  final String audioDirection;
  final String endingState;
  final String continuityFrom;
  final String continuityInto;
  final List<String> characterLock;
  final String negativeInstructions;
  final String visualPrompt;
  final List<Map<String, dynamic>> onScreenText;

  const ReelClipOutput({
    required this.partNumber,
    required this.timeRange,
    required this.purpose,
    required this.setting,
    required this.startingState,
    required this.action0to4s,
    required this.action4to8s,
    required this.action8to10s,
    required this.dialogue,
    required this.audioDirection,
    required this.endingState,
    required this.continuityFrom,
    required this.continuityInto,
    required this.characterLock,
    required this.negativeInstructions,
    required this.visualPrompt,
    required this.onScreenText,
  });

  VideoPartPrompt toVideoPartPrompt() {
    final promptText = _buildPromptText();
    return VideoPartPrompt(
      partNumber: partNumber,
      totalParts: 3,
      promptText: promptText,
      textOverlay: onScreenText
          .map((o) => o['text'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .join(' | '),
      purpose: purpose,
      fullPrompt: visualPrompt,
      startingState: startingState,
      endingState: endingState,
      setting: setting,
      dialogue: dialogue.map((d) => '${d['character']}: ${d['text']}').join('\n'),
      continuityFrom: continuityFrom,
      continuityInto: continuityInto,
      negativeInstructions: negativeInstructions,
      visualPrompt: visualPrompt,
      onScreenText: onScreenText.isNotEmpty ? onScreenText.first : {},
    );
  }

  String _buildPromptText() {
    final buffer = StringBuffer();
    buffer.writeln('PART $partNumber of 3 — $purpose');
    buffer.writeln('');
    buffer.writeln('SETTING: $setting');
    buffer.writeln('');
    buffer.writeln('STARTING STATE: $startingState');
    buffer.writeln('');
    buffer.writeln('ACTION 0-4s: $action0to4s');
    buffer.writeln('ACTION 4-8s: $action4to8s');
    buffer.writeln('ACTION 8-10s: $action8to10s');
    buffer.writeln('');
    if (dialogue.isNotEmpty) {
      buffer.writeln('DIALOGUE:');
      for (final d in dialogue) {
        buffer.writeln('  ${d['character']}: ${d['text']}');
      }
      buffer.writeln('');
    }
    buffer.writeln('AUDIO DIRECTION: $audioDirection');
    buffer.writeln('');
    buffer.writeln('ENDING STATE: $endingState');
    buffer.writeln('');
    buffer.writeln('CONTINUITY FROM: $continuityFrom');
    buffer.writeln('CONTINUITY INTO: $continuityInto');
    buffer.writeln('');
    buffer.writeln('CHARACTER LOCK:');
    for (final c in characterLock) {
      buffer.writeln('  $c');
    }
    buffer.writeln('');
    buffer.writeln('NEGATIVE INSTRUCTIONS: $negativeInstructions');
    buffer.writeln('');
    buffer.writeln('VISUAL PROMPT: $visualPrompt');
    return buffer.toString().trim();
  }

  Map<String, dynamic> toJson() => {
    'part_number': partNumber,
    'time_range': timeRange,
    'purpose': purpose,
    'setting': setting,
    'starting_state': startingState,
    'action_0_4s': action0to4s,
    'action_4_8s': action4to8s,
    'action_8_10s': action8to10s,
    'dialogue': dialogue,
    'audio_direction': audioDirection,
    'ending_state': endingState,
    'continuity_from': continuityFrom,
    'continuity_into': continuityInto,
    'character_lock': characterLock,
    'negative_instructions': negativeInstructions,
    'visual_prompt': visualPrompt,
    'on_screen_text': onScreenText,
  };

  factory ReelClipOutput.fromJson(Map<String, dynamic> json) {
    return ReelClipOutput(
      partNumber: json['part_number'] as int? ?? 0,
      timeRange: json['time_range'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      setting: json['setting'] as String? ?? '',
      startingState: json['starting_state'] as String? ?? '',
      action0to4s: json['action_0_4s'] as String? ?? '',
      action4to8s: json['action_4_8s'] as String? ?? '',
      action8to10s: json['action_8_10s'] as String? ?? '',
      dialogue: (json['dialogue'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((m) => m.cast<String, String>())
              .toList() ??
          [],
      audioDirection: json['audio_direction'] as String? ?? '',
      endingState: json['ending_state'] as String? ?? '',
      continuityFrom: json['continuity_from'] as String? ?? '',
      continuityInto: json['continuity_into'] as String? ?? '',
      characterLock: (json['character_lock'] as List?)?.cast<String>() ?? [],
      negativeInstructions: json['negative_instructions'] as String? ?? '',
      visualPrompt: json['visual_prompt'] as String? ?? '',
      onScreenText: (json['on_screen_text'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [],
    );
  }
}