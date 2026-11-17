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
  /// [storyOverride] if provided, replaces the story content from the HookIdea.
  ///   This allows using an edited story from the StoryScreen while preserving
  ///   all other HookIdea metadata (characters, problem, lesson, hooks, etc.).
  ///
  /// Returns the fully rendered prompt string ready for Gemini.
  String generateMasterPrompt({
    required HookIdea idea,
    List<String>? selectedCharacters,
    String additionalInstructions = '',
    bool hasReferenceImages = false,
    String? storyOverride,
  }) {
    final cast = (selectedCharacters ?? idea.defaultCast)
        .where(kCharacterNames.contains)
        .toList();

    final effectiveStory = (storyOverride != null && storyOverride.isNotEmpty)
        ? storyOverride
        : (idea.storyDetail.isNotEmpty ? idea.storyDetail : idea.asStoryText());

    final vars = VideoPromptVariables(
      storyTitle: idea.title.isNotEmpty ? idea.title : idea.cover,
      storyIdea: effectiveStory,
      realLifeProblem: idea.problem,
      learningOutcome: idea.lesson,
      selectedCharacters: cast,
      visualStyle: BrandDefaults.visualStyle,
      overallTone: 'Warm, relatable, emotionally engaging',
      videoGenerator: 'Runway Gen-3 / Kling / Luma',
      language: 'Hinglish',
      hasReferenceImages: hasReferenceImages,
      storyHook: _buildStoryHookSource(idea),
      additionalInstructions: additionalInstructions,
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

  /// Generates the master prompt for manual (non-HookIdea) reel generation.
  ///
  /// Uses the same authoritative master template as HookIdea-based generation.
  /// [idea] is the user-provided story idea text.
  /// [selectedCharacters] is the list of selected character names.
  /// [additionalInstructions] are user-provided additions.
  /// [hasReferenceImages] indicates whether Gemini reference images are attached.
  /// [language] is the target language (default: Hinglish).
  String generateMasterPromptFromManual({
    required String idea,
    required List<String> selectedCharacters,
    String additionalInstructions = '',
    bool hasReferenceImages = false,
    String language = 'Hinglish',
  }) {
    final cast = selectedCharacters.where(kCharacterNames.contains).toList();

    // Build a StoryHookSource from manual inputs
    final storyHook = StoryHookSource(
      problem: idea,
      twist: '',
      resolution: '',
      lesson: '',
      setting: 'Indian home, warm daylight',
      sceneDetail: '',
      dialogue: '',
      mess: '',
      endingBeat: '',
    );

    final vars = VideoPromptVariables(
      storyTitle: idea.split('\n').first.trim(),
      storyIdea: idea,
      realLifeProblem: idea,
      learningOutcome: 'A small, believable improvement through caring parenting.',
      selectedCharacters: cast,
      visualStyle: BrandDefaults.visualStyle,
      overallTone: 'Warm, relatable, emotionally engaging',
      videoGenerator: 'Runway Gen-3 / Kling / Luma',
      language: language,
      hasReferenceImages: hasReferenceImages,
      storyHook: storyHook,
      additionalInstructions: additionalInstructions,
    );

    return renderVideoMasterPrompt(vars);
  }
}