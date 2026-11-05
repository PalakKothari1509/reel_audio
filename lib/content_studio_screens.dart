/// Gemini evaluation result wrapper for Flutter UI.
class GeminiVideoResult {
  final String ideaId;
  final String title;
  final String cover;
  final String opening;
  final String problem;
  final String lesson;
  final String storyDetail;
  final String endingBeat;
  final String caption;
  final String pinnedComment;
  final String dialogue;
  final List<String> defaultCast;
  final String setting;
  final String sceneDetail;
  final String postFormat;
  final String strategy;
  final String mess;
  final String innerThought;
  final bool keepMoralOffScreen;
  final String quote;
  final String detail;
  final String punchline;
  final String readyPrompt;
  final bool forApp;
  final bool custom;
  final bool archived;
  final String usedOn;
  final int score;
  final String band;
  final String reviewedOn;

  GeminiVideoResult({
    required this.ideaId,
    required this.title,
    required this.cover,
    required this.opening,
    required this.problem,
    required this.lesson,
    required this.storyDetail,
    required this.endingBeat,
    required this.caption,
    required this.pinnedComment,
    required this.dialogue,
    required this.defaultCast,
    required this.setting,
    required this.sceneDetail,
    required this.postFormat,
    required this.strategy,
    required this.mess,
    required this.innerThought,
    required this.keepMoralOffScreen,
    required this.quote,
    required this.detail,
    required this.punchline,
    required this.readyPrompt,
    required this.forApp,
    required this.custom,
    required this.archived,
    required this.usedOn,
    required this.score,
    required this.band,
    required this.reviewedOn,
  });
}

/// Evaluation result wrapper for Flutter UI.
class IdeaEvaluation {
  final StoryCheck check;
  final ShareabilityAnalysis shareability;
  final HookChoice? selectedHook;
  final bool isApproved;

  IdeaEvaluation({
    required this.check,
    required this.shareability,
    this.selectedHook,
    this.isApproved = false,
  });
}

/// Shareability analysis result.
class ShareabilityAnalysis {
  final HookChoice? sender;
  final HookChoice? recipient;
  final String reason;
  final String caption;
  final String improvedCaption;
  final List<EvaluationSuggestion> suggestions;
  final double confidence;

  ShareabilityAnalysis({
    this.sender,
    this.recipient,
    required this.reason,
    required this.caption,
    required this.improvedCaption,
    required this.suggestions,
    required this.confidence,
  });
}

/// Hook strength dimension score.
class HookStrength {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  HookStrength({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Relatability dimension score.
class Relatability {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  Relatability({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Story structure dimension score.
class StoryStructure {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  StoryStructure({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Age appropriateness dimension score.
class AgeAppropriateness {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  AgeAppropriateness({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Hinglish naturalness dimension score.
class HinglishNaturalness {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  HinglishNaturalness({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Character consistency dimension score.
class CharacterConsistency {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  CharacterConsistency({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Visual feasibility dimension score.
class VisualFeasibility {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  VisualFeasibility({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Sound-off readability dimension score.
class SoundOffReadability {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  SoundOffReadability({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Engagement potential dimension score.
class EngagementPotential {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  EngagementPotential({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Brand and safety dimension score.
class BrandAndSafety {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  BrandAndSafety({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

class StoryCheck {
  final HookStrength hookStrength;
  final Relatability relatability;
  final StoryStructure storyStructure;
  final AgeAppropriateness ageAppropriateness;
  final HinglishNaturalness hinglishNaturalness;
  final CharacterConsistency characterConsistency;
  final VisualFeasibility visualFeasibility;
  final SoundOffReadability soundOffReadability;
  final EngagementPotential engagementPotential;
  final BrandAndSafety brandAndSafety;

  StoryCheck({
    required this.hookStrength,
    required this.relatability,
    required this.storyStructure,
    required this.ageAppropriateness,
    required this.hinglishNaturalness,
    required this.characterConsistency,
    required this.visualFeasibility,
    required this.soundOffReadability,
    required this.engagementPotential,
    required this.brandAndSafety,
  });
}

/// Dimension score for quality checker.
class DimensionScore {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;
  final String whatWorks;
  final String needsImprovement;

  DimensionScore({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
    required this.whatWorks,
    required this.needsImprovement,
  });
}

/// Reach dimension score.
class ReachDimension {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;

  ReachDimension({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
  });
}

/// Critical finding from evaluation.
class CriticalFinding {
  final String title;
  final String explanation;
  final String evidence;
  final String suggestedFix;

  CriticalFinding({
    required this.title,
    required this.explanation,
    required this.evidence,
    required this.suggestedFix,
  });
}

/// Major finding from evaluation.
class MajorFinding {
  final String title;
  final String explanation;
  final String evidence;
  final String suggestedFix;

  MajorFinding({
    required this.title,
    required this.explanation,
    required this.evidence,
    required this.suggestedFix,
  });
}

/// Minor finding from evaluation.
class MinorFinding {
  final String title;
  final String explanation;
  final String evidence;
  final String suggestedFix;

  MinorFinding({
    required this.title,
    required this.explanation,
    required this.evidence,
    required this.suggestedFix,
  });
}

/// Evaluation suggestion from browser evaluator.
class EvaluationSuggestion {
  final String title;
  final String explanation;
  final String original;
  final String suggested;

  EvaluationSuggestion({
    required this.title,
    required this.explanation,
    required this.original,
    required this.suggested,
  });
}

/// Current approval source for an idea.
class EvaluationSource {
  final String approvalStatus;
  final String approvedAt;

  EvaluationSource({required this.approvalStatus, required this.approvedAt});
}

/// Carousel promotion result.
class CarouselPromptsResult {
  final String ideaId;
  final List<CarouselSlidePrompt> slides;
  final String overallTheme;

  CarouselPromptsResult({
    required this.ideaId,
    required this.slides,
    required this.overallTheme,
  });
}

/// Carousel slide prompt.
class CarouselSlidePrompt {
  final int slideNumber;
  final String title;
  final String cover;
  final String opening;
  final String problem;
  final String lesson;
  final String storyDetail;
  final String endingBeat;
  final String caption;
  final String pinnedComment;
  final String dialogue;
  final List<String> defaultCast;
  final String setting;
  final String sceneDetail;
  final String postFormat;
  final String strategy;
  final String mess;
  final String innerThought;
  final bool keepMoralOffScreen;
  final String quote;
  final String detail;
  final String punchline;
  final String readyPrompt;
  final bool forApp;
  final bool custom;
  final bool archived;
  final String usedOn;
  final int score;
  final String band;
  final String reviewedOn;

  CarouselSlidePrompt({
    required this.slideNumber,
    required this.title,
    required this.cover,
    required this.opening,
    required this.problem,
    required this.lesson,
    required this.storyDetail,
    required this.endingBeat,
    required this.caption,
    required this.pinnedComment,
    required this.dialogue,
    required this.defaultCast,
    required this.setting,
    required this.sceneDetail,
    required this.postFormat,
    required this.strategy,
    required this.mess,
    required this.innerThought,
    required this.keepMoralOffScreen,
    required this.quote,
    required this.detail,
    required this.punchline,
    required this.readyPrompt,
    required this.forApp,
    required this.custom,
    required this.archived,
    required this.usedOn,
    required this.score,
    required this.band,
    required this.reviewedOn,
  });
}

/// Character choice for evaluation.
class HookChoice {
  final String id;
  final String title;

  HookChoice({required this.id, required this.title});
}
