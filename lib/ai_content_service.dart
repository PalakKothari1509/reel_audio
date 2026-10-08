// Phase 4: Unified AI Content Service
//
// The single boundary through which screens send generation requests to AI.
// Screens never call Gemini directly — they send a ready idea to this service,
// which returns a ContentPackageV2.
//
// ── Design ────────────────────────────────────────────────────────────
//
// AiContentService
//   = "Generate creative content for this approved idea."
//
// QualityGate
//   = "Is this allowed/ready?"
//
// ContentPackageV2
//   = "Persist the generated result."
//
// The service accepts a [GenerationRequest] containing only:
// - The idea's strategic identity (title, ideaId)
// - The gate verdict (frozen classification + readiness)
// - Optional overrides (shareTrigger, openLoop, experiment metadata)
//
// The AI layer never constructs or owns the gate verdict, classification
// snapshot, or lifecycle state. It only generates creative content.

import 'dart:async';

import 'content_axes.dart';
import 'content_package_v2.dart';
import 'content_quality_gate.dart';

/// A pure-Dart intermediate result from the AI provider.
///
/// This represents what AI generates: creative content fields.
/// It is intentionally separate from [ContentPackageV2] so that the
/// AI layer never owns gate/classification state.
class GeneratedContent {
  final String title;
  final String hook;
  final String script;
  final String narration;
  final String dialogue;
  final String caption;
  final String cta;
  final List<String> hashtags;
  final List<Scene> scenes;
  final List<String> imagePrompts;
  final List<ShotListItem> shotList;

  const GeneratedContent({
    required this.title,
    required this.hook,
    required this.script,
    required this.narration,
    required this.dialogue,
    required this.caption,
    required this.cta,
    required this.hashtags,
    required this.scenes,
    required this.imagePrompts,
    required this.shotList,
  });

  bool get hasVoiceContent => narration.isNotEmpty || dialogue.isNotEmpty;
}

/// Input for generating content from an approved idea.
///
/// Only fully-ready ideas should reach [AiContentService.generate].
/// The [gateReport] ensures the resulting package carries the exact
/// verdict it was generated under.
class GenerationRequest {
  final String ideaId;
  final String title;

  /// The frozen axis state from the quality gate.
  final GateReport gateReport;

  /// Optional: idea metadata for the strategy fields.
  final String audience;
  final String problem;
  final String lesson;
  final String hook;

  /// Optional: a parent-provided share trigger / open loop.
  /// Falls back to the gate report's values when not provided.
  final ShareTrigger? shareTrigger;
  final String? openLoop;

  /// Optional experiment metadata.
  final String? experimentGroup;
  final int? testNumber;
  final int? testCount;

  const GenerationRequest({
    required this.ideaId,
    required this.title,
    required this.gateReport,
    this.audience = '',
    this.problem = '',
    this.lesson = '',
    this.hook = '',
    this.shareTrigger,
    this.openLoop,
    this.experimentGroup,
    this.testNumber,
    this.testCount,
  });

  /// Convenience: the classification snapshot that passed the gate.
  ClassificationSnapshot get classification => gateReport.classification;
}

/// Explicit failure type for AI generation errors.
class AiContentFailure implements Exception {
  final String message;
  final Object? cause;

  const AiContentFailure(this.message, [this.cause]);

  @override
  String toString() => 'AiContentFailure: $message';
}

/// The unified AI content service boundary.
///
/// Screens call [generate] with a [GenerationRequest]. The service:
///
/// 1. Verifies the idea passed the Ready-to-Generate gate.
/// 2. Calls the underlying AI provider to produce [GeneratedContent].
/// 3. Assembles a [ContentPackageV2] via [ContentPackageV2Factory].
///
/// This class is abstract so it can be mocked in tests without calling
/// real AI. The concrete implementation wraps [AIProvider].
abstract class AiContentService {
  /// Generates a [ContentPackageV2] for an approved idea.
  ///
  /// Throws [StateError] if the idea is blocked or UNKNOWN per the gate.
  /// Throws [AiContentFailure] if the AI provider fails.
  Future<ContentPackageV2> generate(GenerationRequest request);

  /// The name of the underlying AI provider, for display.
  String get providerName;

  /// Whether the provider is configured and reachable.
  bool get isAvailable;
}

/// Abstract base for implementations that delegate to an AI provider.
///
/// Concrete implementations wrap an [AIProvider] and handle the
/// Conversion from AI output → [GeneratedContent] → [ContentPackageV2].
abstract class AiContentServiceImplBase implements AiContentService {
  /// Generates [GeneratedContent] from a request.
  ///
  /// Subclasses implement this by calling their AI provider.
  Future<GeneratedContent> generateContent(GenerationRequest request);

  @override
  Future<ContentPackageV2> generate(GenerationRequest request) async {
    final report = request.gateReport;

    // ── Gate check: only READY ideas can be generated ──────────────────
    if (report.isBlockedFromGeneration) {
      throw StateError(
          'Idea ${request.ideaId} is blocked by the quality gate and cannot be generated.');
    }
    if (report.overall == GateVerdict.unknown) {
      throw StateError(
          'Idea ${request.ideaId} is not ready: gate verdict is UNKNOWN.');
    }

    // ── Generate creative content ───────────────────────────────────────
    final generated = await generateContent(request);

    // ── Convert classification snapshot to V2 ─────────────────────────
    final classificationV2 = ClassificationSnapshotV2(
      pillar: report.classification.pillar,
      series: report.classification.series,
      narrativeFormatName: report.classification.narrativeFormatName,
      contentType: report.classification.contentType,
      productionMethod: report.classification.productionMethod,
      goal: report.classification.goal,
      status: report.classification.status,
      axisStates: report.classification.axisStates,
      capturedAt: report.checkedAt,
    );

    // ── Assemble the final package ─────────────────────────────────────
    return ContentPackageV2Factory.create(
      id: _packageId(request),
      ideaId: request.ideaId,
      classification: classificationV2,
      audience: request.audience,
      problem: request.problem,
      lesson: request.lesson,
      hook: generated.hook,
      shareTrigger: request.shareTrigger ?? report.shareTrigger,
      openLoop: request.openLoop,
      voiceMode: report.voiceMode,
      cta: generated.cta,
      reachCandidacy: _reachCandidacy(report),
      productionCompatibility: _productionCompatibility(report, generated),
      title: generated.title,
      script: generated.script,
      narration: generated.narration,
      dialogue: generated.dialogue,
      caption: generated.caption,
      hashtags: generated.hashtags,
      scenes: generated.scenes,
      productionMethod: report.classification.productionMethod ??
          _inferProductionMethod(generated),
      imagePrompts: generated.imagePrompts,
      shotList: generated.shotList,
      experimentGroup: request.experimentGroup,
      testNumber: request.testNumber,
      testCount: request.testCount,
      gateReport: report,
    );
  }

  String _packageId(GenerationRequest request) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = request.experimentGroup != null
        ? '${request.experimentGroup}-t${request.testNumber ?? 1}'
        : 'gen';
    return '${request.ideaId}-$suffix-$ts';
  }

  ProductionMethod _inferProductionMethod(GeneratedContent generated) {
    // Infer from scene count and content type. Default to character images.
    if (generated.scenes.isEmpty) {
      return ProductionMethod.characterImages;
    }
    return ProductionMethod.characterImages;
  }

  ReachCandidacy _reachCandidacy(GateReport report) {
    final goal = report.classification.goal;
    if (goal == ContentGoal.reach || goal == ContentGoal.shares) {
      return ReachCandidacy.yes;
    }
    if (goal == ContentGoal.saves || goal == ContentGoal.authority) {
      return ReachCandidacy.no;
    }
    return ReachCandidacy.unknown;
  }

  ProductionCompatibility _productionCompatibility(
    GateReport report,
    GeneratedContent generated,
  ) {
    if (report.needsFilming) {
      return ProductionCompatibility.needsFilming;
    }
    return ProductionCompatibility.yes;
  }
}
