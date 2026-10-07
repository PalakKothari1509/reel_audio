// Phase 3: Canonical ContentPackage Model
//
// Separates Idea (strategic concept) from ContentPackage (specific execution/test).
// One idea can create many packages, enabling experimentation without destroying
// the original idea. Preserves classification snapshot at generation time.
// Makes narration and dialogue first-class for future voice generation.

import 'content_axes.dart';
import 'content_quality_gate.dart';

/// Classification snapshot captured at package generation time.
/// Ensures redefining a format later doesn’t retroactively change old content.
///
/// This is the frozen state the quality gate evaluated. Axes that were OPEN
/// (no decision yet) are stored as null — they must NOT be silently replaced
/// with an inferred value.
class ClassificationSnapshotV2 {
  final ContentPillar? pillar;
  final ContentSeries? series;
  final String? narrativeFormatName;
  final ContentType? contentType;
  final ProductionMethod? productionMethod;
  final ContentGoal? goal;
  final IdeaStatus status;
  final Map<String, AxisResolution?> axisStates;
  final DateTime capturedAt;

  const ClassificationSnapshotV2({
    this.pillar,
    this.series,
    this.narrativeFormatName,
    this.contentType,
    this.productionMethod,
    this.goal,
    required this.status,
    required this.axisStates,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
          'pillar': pillar?.label,
          'series': series?.label,
          'narrativeFormatName': narrativeFormatName,
          'contentType': contentType?.label,
          'productionMethod': productionMethod?.label,
          'goal': goal?.label,
          'status': status.name,
          'axisStates':
              axisStates.map((k, v) => MapEntry(k, v?.name ?? 'open')),
          'capturedAt': capturedAt.toIso8601String(),
        };

  factory ClassificationSnapshotV2.fromJson(Map<String, dynamic> json) {
    AxisResolution? parseAxis(String? s) =>
        s == null || s == 'open'
            ? null
            : AxisResolution.values.byName(s);
    return ClassificationSnapshotV2(
      pillar: json['pillar'] != null
          ? ContentPillar.byLabel(json['pillar'] as String)
          : null,
      series: json['series'] != null
          ? ContentSeries.byLabel(json['series'] as String)
          : null,
      narrativeFormatName: json['narrativeFormatName'] as String?,
      contentType: json['contentType'] != null
          ? ContentType.byLabel(json['contentType'] as String)
          : null,
      productionMethod: json['productionMethod'] != null
          ? ProductionMethod.byLabel(json['productionMethod'] as String)
          : null,
      goal: json['goal'] != null
          ? ContentGoal.byLabel(json['goal'] as String)
          : null,
      status: json['status'] != null
          ? IdeaStatus.values.byName(json['status'] as String)
          : IdeaStatus.idea,
      axisStates: (json['axisStates'] as Map?)?.map(
            (k, v) => MapEntry(k as String, parseAxis(v as String?)),
          ) ??
          {},
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Whether the snapshot carries a human-approved value on every axis
  /// required for generation. Returns false if any axis is OPEN (null)
  /// or in a non-resolved state.
  bool get isFullyApproved {
    for (final axis in [
      'pillar',
      'series',
      'narrativeFormat',
      'contentType',
      'productionMethod',
      'goal',
    ]) {
      final state = axisStates[axis];
      if (state == null || !state.isResolved) {
        return false;
      }
    }
    return true;
  }

  /// Whether any axis is still OPEN (no value, not even a suggestion).
  bool get hasOpenAxes => axisStates.values.any((s) => s == null);

  /// Whether any axis is blocked on a human decision (needsReview, invalid).
  bool get hasBlockedAxes => axisStates.values.any(
      (s) => s == AxisResolution.needsReview || s == AxisResolution.invalid);

  /// Whether any axis is flagged as an archive candidate.
  bool get hasArchiveCandidateAxes =>
      axisStates.values.any((s) => s == AxisResolution.archiveCandidate);
}

/// Reach candidacy assessment for a package.
enum ReachCandidacy {
  yes,
  no,
  unknown,
}

/// Production compatibility assessment.
enum ProductionCompatibility {
  yes,
  needsFilming,
  unknown,
}

/// A single scene/shot in a content package.
class Scene {
  final int index;
  final String title;
  final String description;
  final String visualPrompt;
  final String? narration; // First-class narration for voice generation
  final String? dialogue; // First-class dialogue for character voices
  final String? overlayText;
  final int? durationSeconds;
  final String? cameraMove;
  final String? lighting;
  final String? audioCue;
  final String? transition;

  const Scene({
    required this.index,
    required this.title,
    required this.description,
    required this.visualPrompt,
    this.narration,
    this.dialogue,
    this.overlayText,
    this.durationSeconds,
    this.cameraMove,
    this.lighting,
    this.audioCue,
    this.transition,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'description': description,
        'visualPrompt': visualPrompt,
        'narration': narration,
        'dialogue': dialogue,
        'overlayText': overlayText,
        'durationSeconds': durationSeconds,
        'cameraMove': cameraMove,
        'lighting': lighting,
        'audioCue': audioCue,
        'transition': transition,
      };

  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
        index: json['index'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        visualPrompt: json['visualPrompt'] as String,
        narration: json['narration'] as String?,
        dialogue: json['dialogue'] as String?,
        overlayText: json['overlayText'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        cameraMove: json['cameraMove'] as String?,
        lighting: json['lighting'] as String?,
        audioCue: json['audioCue'] as String?,
        transition: json['transition'] as String?,
      );
}

/// Shot list item for production planning.
class ShotListItem {
  final int shotNumber;
  final String title;
  final String visualDescription;
  final String cameraMove;
  final String lighting;
  final int durationSeconds;
  final String? audioCue;
  final String? transition;
  final List<String> characters;

  const ShotListItem({
    required this.shotNumber,
    required this.title,
    required this.visualDescription,
    required this.cameraMove,
    required this.lighting,
    required this.durationSeconds,
    this.audioCue,
    this.transition,
    required this.characters,
  });

  Map<String, dynamic> toJson() => {
        'shotNumber': shotNumber,
        'title': title,
        'visualDescription': visualDescription,
        'cameraMove': cameraMove,
        'lighting': lighting,
        'durationSeconds': durationSeconds,
        'audioCue': audioCue,
        'transition': transition,
        'characters': characters,
      };

  factory ShotListItem.fromJson(Map<String, dynamic> json) => ShotListItem(
        shotNumber: json['shotNumber'] as int,
        title: json['title'] as String,
        visualDescription: json['visualDescription'] as String,
        cameraMove: json['cameraMove'] as String,
        lighting: json['lighting'] as String,
        durationSeconds: json['durationSeconds'] as int,
        audioCue: json['audioCue'] as String?,
        transition: json['transition'] as String?,
        characters: (json['characters'] as List?)?.cast<String>() ?? [],
      );
}

/// Canonical ContentPackage model for Phase 3.
///
/// Identity: id, ideaId, createdAt, updatedAt
/// Classification: the 7 axes (snapshot at generation)
/// Strategy: audience, problem, lesson, hook, shareTrigger, openLoop, voiceMode,
///           cta, reachCandidacy, productionCompatibility
/// Creative: title, script, narration, dialogue, caption, hashtags, scenes[]
/// Production: productionMethod, shotList, imagePrompts, productionNotes
/// Publishing: publishedAt, platform, postUrl
/// Experiment: experimentGroup, testNumber, testCount
class ContentPackageV2 {
  // Identity
  final String id;
  final String ideaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Classification (snapshot at generation time)
  final ClassificationSnapshotV2 classification;

  // Strategy
  final String audience;
  final String problem;
  final String lesson;
  final String hook;
  final ShareTrigger? shareTrigger;
  final String? openLoop;
  final VoiceMode voiceMode;
  final String cta;
  final ReachCandidacy reachCandidacy;
  final ProductionCompatibility productionCompatibility;

  // Creative
  final String title;
  final String script; // Full script with timestamps
  final String narration; // Full narration for voice generation
  final String dialogue; // Character dialogue lines
  final String caption;
  final List<String> hashtags;
  final List<Scene> scenes;

  // Production
  final ProductionMethod productionMethod;
  final List<ShotListItem> shotList;
  final List<String> imagePrompts;
  final String? productionNotes;

  // Publishing
  final DateTime? publishedAt;
  final String? platform;
  final String? postUrl;

  // Experiment
  final String? experimentGroup;
  final int? testNumber;
  final int? testCount;

  // Gate result — the verdict from QualityGate.evaluateIdea() at generation time.
  // This is the authoritative readiness check. The package must NOT be generated
  // if the gate did not PASS.
  final GateReport? gateReport;

  const ContentPackageV2({
    required this.id,
    required this.ideaId,
    required this.createdAt,
    required this.updatedAt,
    required this.classification,
    required this.audience,
    required this.problem,
    required this.lesson,
    required this.hook,
    this.shareTrigger,
    this.openLoop,
    required this.voiceMode,
    required this.cta,
    required this.reachCandidacy,
    required this.productionCompatibility,
    required this.title,
    required this.script,
    required this.narration,
    required this.dialogue,
    required this.caption,
    required this.hashtags,
    required this.scenes,
    required this.productionMethod,
    required this.shotList,
    required this.imagePrompts,
    this.productionNotes,
    this.publishedAt,
    this.platform,
    this.postUrl,
    this.experimentGroup,
    this.testNumber,
    this.testCount,
    this.gateReport,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ideaId': ideaId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'classification': classification.toJson(),
        'audience': audience,
        'problem': problem,
        'lesson': lesson,
        'hook': hook,
        'shareTrigger': shareTrigger?.toJson(),
        'openLoop': openLoop,
        'voiceMode': voiceMode.name,
        'cta': cta,
        'reachCandidacy': reachCandidacy.name,
        'productionCompatibility': productionCompatibility.name,
        'title': title,
        'script': script,
        'narration': narration,
        'dialogue': dialogue,
        'caption': caption,
        'hashtags': hashtags,
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'productionMethod': productionMethod.label,
        'shotList': shotList.map((s) => s.toJson()).toList(),
        'imagePrompts': imagePrompts,
        'productionNotes': productionNotes,
        'publishedAt': publishedAt?.toIso8601String(),
        'platform': platform,
        'postUrl': postUrl,
        'experimentGroup': experimentGroup,
        'testNumber': testNumber,
        'testCount': testCount,
        'gateReport': gateReport?.toJson(),
      };

  factory ContentPackageV2.fromJson(Map<String, dynamic> json) {
    return ContentPackageV2(
      id: json['id'] as String,
      ideaId: json['ideaId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      classification:
          ClassificationSnapshotV2.fromJson(Map<String, dynamic>.from(json['classification'] as Map)),
      audience: json['audience'] as String,
      problem: json['problem'] as String,
      lesson: json['lesson'] as String,
      hook: json['hook'] as String,
      shareTrigger: json['shareTrigger'] != null
          ? ShareTrigger.fromJson(Map<String, dynamic>.from(json['shareTrigger'] as Map))
          : null,
      openLoop: json['openLoop'] as String?,
      voiceMode: VoiceMode.values.byName(json['voiceMode'] as String),
      cta: json['cta'] as String,
      reachCandidacy:
          ReachCandidacy.values.byName(json['reachCandidacy'] as String),
      productionCompatibility: ProductionCompatibility.values.byName(
          json['productionCompatibility'] as String),
      title: json['title'] as String,
      script: json['script'] as String,
      narration: json['narration'] as String,
      dialogue: json['dialogue'] as String,
      caption: json['caption'] as String,
      hashtags: (json['hashtags'] as List).cast<String>(),
      scenes: (json['scenes'] as List)
          .map((s) => Scene.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      productionMethod:
          ProductionMethod.byLabel(json['productionMethod'] as String)!,
      shotList: (json['shotList'] as List)
          .map((s) => ShotListItem.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      imagePrompts: (json['imagePrompts'] as List).cast<String>(),
      productionNotes: json['productionNotes'] as String?,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      platform: json['platform'] as String?,
      postUrl: json['postUrl'] as String?,
      experimentGroup: json['experimentGroup'] as String?,
      testNumber: json['testNumber'] as int?,
      testCount: json['testCount'] as int?,
      gateReport: json['gateReport'] != null
          ? GateReport.fromJson(
              Map<String, dynamic>.from(json['gateReport'] as Map))
          : null,
    );
  }

  /// Creates a copy with updated fields.
  ContentPackageV2 copyWith({
    String? id,
    String? ideaId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ClassificationSnapshotV2? classification,
    String? audience,
    String? problem,
    String? lesson,
    String? hook,
    ShareTrigger? shareTrigger,
    String? openLoop,
    VoiceMode? voiceMode,
    String? cta,
    ReachCandidacy? reachCandidacy,
    ProductionCompatibility? productionCompatibility,
    String? title,
    String? script,
    String? narration,
    String? dialogue,
    String? caption,
    List<String>? hashtags,
    List<Scene>? scenes,
    ProductionMethod? productionMethod,
    List<ShotListItem>? shotList,
    List<String>? imagePrompts,
    String? productionNotes,
    DateTime? publishedAt,
    String? platform,
    String? postUrl,
     String? experimentGroup,
    int? testNumber,
    int? testCount,
    GateReport? gateReport,
  }) {
    return ContentPackageV2(
      id: id ?? this.id,
      ideaId: ideaId ?? this.ideaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      classification: classification ?? this.classification,
      audience: audience ?? this.audience,
      problem: problem ?? this.problem,
      lesson: lesson ?? this.lesson,
      hook: hook ?? this.hook,
      shareTrigger: shareTrigger ?? this.shareTrigger,
      openLoop: openLoop ?? this.openLoop,
      voiceMode: voiceMode ?? this.voiceMode,
      cta: cta ?? this.cta,
      reachCandidacy: reachCandidacy ?? this.reachCandidacy,
      productionCompatibility:
          productionCompatibility ?? this.productionCompatibility,
      title: title ?? this.title,
      script: script ?? this.script,
      narration: narration ?? this.narration,
      dialogue: dialogue ?? this.dialogue,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      scenes: scenes ?? this.scenes,
      productionMethod: productionMethod ?? this.productionMethod,
      shotList: shotList ?? this.shotList,
      imagePrompts: imagePrompts ?? this.imagePrompts,
      productionNotes: productionNotes ?? this.productionNotes,
      publishedAt: publishedAt ?? this.publishedAt,
      platform: platform ?? this.platform,
      postUrl: postUrl ?? this.postUrl,
      experimentGroup: experimentGroup ?? this.experimentGroup,
      testNumber: testNumber ?? this.testNumber,
      testCount: testCount ?? this.testCount,
      gateReport: gateReport ?? this.gateReport,
    );
  }

  /// Returns the total estimated duration in seconds.
  int get totalDurationSeconds =>
      shotList.fold(0, (sum, s) => sum + s.durationSeconds);

  /// Returns true if this package has narration/dialogue for voice generation.
  bool get hasVoiceContent => narration.isNotEmpty || dialogue.isNotEmpty;

  /// Returns true if this package is part of an experiment.
  bool get isExperiment =>
      experimentGroup != null && testNumber != null && testCount != null;

  // ── Ready-to-Generate Gate Integration ────────────────────────────

  /// The gate verdict from [QualityGate.evaluateIdea()], captured at
  /// generation time. Null when no gate was run.
  ///
  /// The package must NOT proceed to generation if [canGenerate] is false.

  /// Whether this package passed the Ready-to-Generate Gate.
  ///
  /// Returns true only when [gateReport] is present and
  /// [GateReport.isBlockedFromGeneration] is false. When the report is null,
  /// returns false — generation must never bypass the gate.
  bool get canGenerate =>
      gateReport != null && !gateReport!.isBlockedFromGeneration;

  /// Whether this package is blocked from generation by the gate.
  ///
  /// Strategy or creative failures set this true. The package must not be
  /// generated even if someone manually bypasses [canGenerate].
  bool get isBlockedByGate => gateReport?.isBlockedFromGeneration ?? false;

  /// Whether the gate verdict is PASS — all checks satisfied, safe to generate.
  bool get isReadyToGenerate =>
      gateReport != null && gateReport!.overall == GateVerdict.pass;

  /// Whether the gate verdict is UNKNOWN — needs more data, not blocked.
  bool get isNotReady =>
      gateReport != null && gateReport!.overall == GateVerdict.unknown;

  /// Whether the package is ready but production-incompatible (needs filming).
  ///
  /// Production failures do NOT block generation — they route to a filming plan.
  bool get needsFilming => gateReport?.needsFilming ?? false;

  /// Whether the package is fully ready and production-compatible.
  bool get isReadyAndProducible => isReadyToGenerate && !needsFilming;

  /// Human-readable list of what is blocking generation, if anything.
  List<String> get blockingReasons => gateReport?.blockingReasons ?? [];
}

/// Factory for creating ContentPackageV2 from an Idea and generation parameters.
class ContentPackageV2Factory {
  /// Creates a new package from an idea and classification.
  static ContentPackageV2 create({
    required String id,
    required String ideaId,
    required ClassificationSnapshotV2 classification,
    required String audience,
    required String problem,
    required String lesson,
    required String hook,
    ShareTrigger? shareTrigger,
    String? openLoop,
    required VoiceMode voiceMode,
    required String cta,
    required ReachCandidacy reachCandidacy,
    required ProductionCompatibility productionCompatibility,
    required String title,
    required String script,
    required String narration,
    required String dialogue,
    required String caption,
    required List<String> hashtags,
    required List<Scene> scenes,
    required ProductionMethod productionMethod,
    required List<ShotListItem> shotList,
    required List<String> imagePrompts,
    String? productionNotes,
     String? experimentGroup,
    int? testNumber,
    int? testCount,
    GateReport? gateReport,
  }) {
    final now = DateTime.now();
    return ContentPackageV2(
      id: id,
      ideaId: ideaId,
      createdAt: now,
      updatedAt: now,
      classification: classification,
      audience: audience,
      problem: problem,
      lesson: lesson,
      hook: hook,
      shareTrigger: shareTrigger,
      openLoop: openLoop,
      voiceMode: voiceMode,
      cta: cta,
      reachCandidacy: reachCandidacy,
      productionCompatibility: productionCompatibility,
      title: title,
      script: script,
      narration: narration,
      dialogue: dialogue,
      caption: caption,
      hashtags: hashtags,
      scenes: scenes,
      productionMethod: productionMethod,
      shotList: shotList,
      imagePrompts: imagePrompts,
      productionNotes: productionNotes,
      experimentGroup: experimentGroup,
      testNumber: testNumber,
      testCount: testCount,
      gateReport: gateReport,
    );
  }

  /// Creates a new experiment package (test 1 of N).
  static ContentPackageV2 createExperiment({
    required String id,
    required String ideaId,
    required ClassificationSnapshotV2 classification,
    required String experimentGroup,
    required int testCount,
    // ... other required fields
  }) {
    return create(
      id: id,
      ideaId: ideaId,
      classification: classification,
      experimentGroup: experimentGroup,
      testNumber: 1,
      testCount: testCount,
      // ... other fields
      audience: '',
      problem: '',
      lesson: '',
      hook: '',
      voiceMode: VoiceMode.optional,
      cta: '',
      reachCandidacy: ReachCandidacy.unknown,
      productionCompatibility: ProductionCompatibility.unknown,
      title: '',
      script: '',
      narration: '',
      dialogue: '',
      caption: '',
      hashtags: [],
      scenes: [],
      productionMethod: ProductionMethod.characterImages,
      shotList: [],
      imagePrompts: [],
    );
  }

  /// Creates a ContentPackageV2 from a [GateReport] result.
  ///
  /// This is the canonical handoff point: the quality gate evaluates an idea,
  /// and the resulting GateReport is embedded in the package so generation
  /// can check [canGenerate] before proceeding.
  ///
  /// The classification is converted from [ClassificationSnapshot] (in
  /// content_quality_gate.dart) to [ClassificationSnapshotV2].
  static ContentPackageV2 fromGateReport({
    required String id,
    required String ideaId,
    required GateReport report,
    String? hook,
    String? title,
    String? script,
    String? narration,
    String? dialogue,
    String? caption,
    List<String>? hashtags,
    List<Scene>? scenes,
    List<ShotListItem>? shotList,
    List<String>? imagePrompts,
    String? productionNotes,
    DateTime? publishedAt,
    String? platform,
    String? postUrl,
    String? experimentGroup,
    int? testNumber,
    int? testCount,
  }) {
    final now = DateTime.now();
    final cls = ClassificationSnapshotV2(
      pillar: report.classification.pillar,
      series: report.classification.series,
      narrativeFormatName: report.classification.narrativeFormatName,
      contentType: report.classification.contentType,
      productionMethod: report.classification.productionMethod,
      goal: report.classification.goal,
      status: report.classification.status,
      axisStates: report.classification.axisStates,
      capturedAt: now,
    );

    return ContentPackageV2(
      id: id,
      ideaId: ideaId,
      createdAt: now,
      updatedAt: now,
      classification: cls,
      audience: '',
      problem: '',
      lesson: '',
      hook: hook ?? report.title,
      shareTrigger: report.shareTrigger ?? const ShareTrigger(),
      openLoop: null,
      voiceMode: report.voiceMode,
      cta: '',
      reachCandidacy: report.classification.goal != null
          ? ReachCandidacy.yes
          : ReachCandidacy.unknown,
      productionCompatibility: ProductionCompatibility.unknown,
      title: title ?? report.title,
      script: script ?? '',
      narration: narration ?? '',
      dialogue: dialogue ?? '',
      caption: caption ?? '',
      hashtags: hashtags ?? [],
      scenes: scenes ?? [],
      productionMethod:
          report.classification.productionMethod ?? ProductionMethod.characterImages,
      shotList: shotList ?? [],
      imagePrompts: imagePrompts ?? [],
      productionNotes: productionNotes,
      publishedAt: publishedAt,
      platform: platform,
      postUrl: postUrl,
      experimentGroup: experimentGroup,
      testNumber: testNumber,
      testCount: testCount,
      gateReport: report,
    );
  }
}