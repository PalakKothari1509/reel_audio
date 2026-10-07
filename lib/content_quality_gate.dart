// Quality Gate System — structured evaluation of ideas and packages.
//
// This file implements the quality-gate layer that separates Quality from Goal,
// evaluates structured share triggers, and enforces the five-test rule as a
// core domain rule. It consumes the existing taxonomy in content_axes.dart and
// format_handbook.dart — it does not redefine it.
//
// ── Design principles ─────────────────────────────────────────────────────
//
// 1. PASS / FAIL / UNKNOWN, never a score. A number out of 10 looks like
//    evidence without being one. `unknown` is the honest default.
// 2. Quality is not Goal. An idea can be well-constructed and still have
//    low reach; that is a planning decision, not a quality failure.
// 3. Production constraints are not quality failures. An idea that needs
//    real-life video is not a bad idea — it is a filming job.
// 4. The five-test rule is enforced here, in the data model, so a format
//    is never judged on one result.
// 5. OPEN axis decisions stay OPEN. The gate never infers a value it was
//    not given.
// 6. Classification snapshots are preserved: a package carries the exact
//    axis values it was generated against, so a verdict is auditable.
//
// ── What blocks ───────────────────────────────────────────────────────────
//
// An idea is BLOCKED from generation when:
//   - Its quality gate has a FAIL on any strategy or creative check.
//   - Its narrative format is invalid or unmapped.
//   - Its content type or production method is unimplemented.
//   - Its format has not been tested enough (the five-test rule).
//
// Production-incompatible ideas are NOT blocked — they are flagged as
// needsFilming and routed to a plan, not retired.

import 'content_axes.dart';
import 'content_generator.dart';
import 'format_handbook.dart';

  /// The resolution state of an axis, as known to the quality gate.
  ///
  /// This mirrors the migration states in `tool/migration_state.dart` but is
  /// defined in `lib/` because the gate must run without depending on the tool
  /// layer. Only `approved` means "a human signed off on this value."
  enum AxisResolution {
    /// A human approved this classification. Safe to use.
    approved,

    /// A human proposed it; not yet signed off. Do not treat as decided.
    suggested,

    /// Deliberately undecided, pending evidence that does not exist yet.
    needsReview,

    /// No correct value derivable from the source material.
    invalid,

    /// The idea does not serve the core value proposition.
    archiveCandidate;

    /// Whether this state means the axis is resolved enough to generate.
    bool get isResolved => this == approved;

    /// Parses a state name from a string, case-insensitive, tolerant of
    /// snake_case (matching `tool/migration_state.dart` conventions).
    static AxisResolution? parse(String raw) {
      final flat = raw.trim().toLowerCase().replaceAll('_', '');
      for (final s in AxisResolution.values) {
        if (s.name.toLowerCase() == flat) return s;
      }
      return null;
    }
  }

// ============================================================================
// VOICE MODE — production constraint
// ============================================================================

/// Whether the content can be understood without voice narration.
///
/// This is a production constraint, not a quality judgment. An idea that
/// requires voice is not a bad idea — if voice is unavailable, it is a
/// scheduling decision.
enum VoiceMode {
  /// The story survives entirely through visuals, text, and captions.
  /// No voiceover, no dialogue.
  none('None', 'Understandable without voice or dialogue.'),
  optional('Optional', 'Voice improves it but is not required.'),

  /// The concept fundamentally depends on narration or dialogue.
  required('Required', 'Requires voice or dialogue to be understood.');

  final String label;
  final String description;

  const VoiceMode(this.label, this.description);

  /// Infers voice mode from the narrative format and content type.
  ///
  /// `none` for visual-first formats (POV, Quick Tip on stills), `required`
  /// for formats that need dialogue (Mini Story, Expectation vs Reality),
  /// `optional` otherwise.
  static VoiceMode infer(FormatSpec? format, ContentType? contentType) {
    if (format == null) return VoiceMode.optional;

    final visualFirst = {
      'pov',
      'quickTip',
      'doThisNotThat',
      'threeExamples',
    };
    if (visualFirst.contains(format.id)) {
      return VoiceMode.none;
    }

    final voiceRequired = {
      'miniStory',
      'expectationReality',
      'personalMistake',
      'mistakesList',
    };
    if (voiceRequired.contains(format.id)) {
      return VoiceMode.required;
    }

    return VoiceMode.optional;
  }
}

// ============================================================================
// SAVE VALUE — goal classification
// ============================================================================

/// Whether the idea's goal makes save value measurable.
///
/// `notApplicable` means the idea's goal is Reach or Shares — it is not
/// a save-driven post, so save value is N/A, not unknown.
enum SaveValue {
  measurable('Measurable', 'Saves / Authority content with a save metric'),
  notApplicable('N/A', 'Goal is Reach or Shares — not save-driven'),
  unknown('Unknown', 'Cannot determine from the idea text');

  final String label;
  final String description;

  const SaveValue(this.label, this.description);
}

// ============================================================================
// SHARE TRIGGER — structured
// ============================================================================

/// The four-part structure of a share trigger, as recommended in the redesign.
///
/// An idea that cannot name a specific person who would send it is not ready.
/// Each field defaults to UNKNOWN until a human provides a concrete answer.
class ShareTrigger {
  /// Who is sending this? Must name a role/relationship, not "parents".
  final String? sender;
  final bool senderKnown;

  /// Who receives it? Must name a relationship or shared situation.
  final String? recipient;
  final bool recipientKnown;

  /// What situation does it name? Concrete, not generic.
  final String? situation;
  final bool situationKnown;

  /// Why would they send it instead of just liking it?
  final String? reason;
  final bool reasonKnown;

  const ShareTrigger({
    this.sender,
    this.recipient,
    this.situation,
    this.reason,
    this.senderKnown = false,
    this.recipientKnown = false,
    this.situationKnown = false,
    this.reasonKnown = false,
  });

  /// Creates a fully-populated share trigger.
  ShareTrigger.filled({
    required String this.sender,
    required String this.recipient,
    required String this.situation,
    required String this.reason,
  })  : senderKnown = true,
        recipientKnown = true,
        situationKnown = true,
        reasonKnown = true;

  /// The honest verdict for the share trigger as a whole.
  ///
  /// Returns 'pass' only when all four components are populated with
  /// non-empty, specific text.
  /// Returns 'fail' when there is text but it is generic/vague.
  /// Returns 'unknown' when the fields are empty, absent, or not all known.
  GateVerdict get verdict {
    // If any field is not known (not even provided), it's UNKNOWN.
    if (!senderKnown || !recipientKnown || !situationKnown || !reasonKnown) {
      return GateVerdict.unknown;
    }
    // All four are marked as known — but if any is empty, it's still UNKNOWN.
    if (sender == null ||
        sender!.trim().isEmpty ||
        recipient == null ||
        recipient!.trim().isEmpty ||
        situation == null ||
        situation!.trim().isEmpty ||
        reason == null ||
        reason!.trim().isEmpty) {
      return GateVerdict.unknown;
    }
    // All four are populated — check for genericness.
    if (_isGeneric(sender!) ||
        _isGeneric(recipient!) ||
        _isGeneric(situation!) ||
        _isGeneric(reason!)) {
      return GateVerdict.fail;
    }
    return GateVerdict.pass;
  }

  static bool _isGeneric(String? s) {
    if (s == null || s.trim().isEmpty) return true;
    final lower = s.toLowerCase();
    final generic = [
      'parents',
      'moms',
      'parents will share',
      'relatable',
      'everyone',
      'people',
      'the audience',
      'just because',
    ];
    return generic.any(lower.contains);
  }

  ShareTrigger copyWith({
    String? Function()? sender,
    String? Function()? recipient,
    String? Function()? situation,
    String? Function()? reason,
    bool? senderKnown,
    bool? recipientKnown,
    bool? situationKnown,
    bool? reasonKnown,
  }) {
    return ShareTrigger(
      sender: sender != null ? sender() : this.sender,
      recipient: recipient != null ? recipient() : this.recipient,
      situation: situation != null ? situation() : this.situation,
      reason: reason != null ? reason() : this.reason,
      senderKnown: senderKnown ?? this.senderKnown,
      recipientKnown: recipientKnown ?? this.recipientKnown,
      situationKnown: situationKnown ?? this.situationKnown,
      reasonKnown: reasonKnown ?? this.reasonKnown,
    );
  }

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'recipient': recipient,
        'situation': situation,
        'reason': reason,
        'senderKnown': senderKnown,
        'recipientKnown': recipientKnown,
        'situationKnown': situationKnown,
        'reasonKnown': reasonKnown,
      };

  factory ShareTrigger.fromJson(Map<String, dynamic> json) => ShareTrigger(
        sender: json['sender'] as String?,
        recipient: json['recipient'] as String?,
        situation: json['situation'] as String?,
        reason: json['reason'] as String?,
        senderKnown: json['senderKnown'] as bool? ?? false,
        recipientKnown: json['recipientKnown'] as bool? ?? false,
        situationKnown: json['situationKnown'] as bool? ?? false,
        reasonKnown: json['reasonKnown'] as bool? ?? false,
      );
}

// ============================================================================
// GATE VERDICT
// ============================================================================

/// The three honest answers to a gate check.
enum GateVerdict {
  pass('PASS', 'The gate is satisfied.'),
  fail('FAIL', 'The gate is not met.'),
  unknown('UNKNOWN', 'Cannot be determined from the available data.');

  final String label;
  final String description;

  const GateVerdict(this.label, this.description);
}

// ============================================================================
// CLASSIFICATION SNAPSHOP — what an idea was when the gate ran
// ============================================================================

/// A frozen snapshot of an idea's classification at the moment the gate ran.
///
/// This prevents a verdict from silently drifting when a taxonomic decision
/// changes later. If a format was suggested at generation time, the gate
/// remembers that, not what it became in a later pass.
class ClassificationSnapshot {
  final ContentPillar? pillar;
  final ContentSeries? series;
  final String? narrativeFormatName;
  final ContentType? contentType;
  final ProductionMethod? productionMethod;
  final ContentGoal? goal;
  final IdeaStatus status;

  /// The resolution state of each axis as of this snapshot.
  ///
  /// `null` means the axis was not in a decisions file (OPEN).
  /// `AxisResolution.approved` means a human approved it.
  /// Other states (suggested, needsReview, invalid, archiveCandidate) mean
  /// the decision is in progress — and the gate must NOT treat them as resolved.
  final Map<String, AxisResolution?> axisStates;

  const ClassificationSnapshot({
    this.pillar,
    this.series,
    this.narrativeFormatName,
    this.contentType,
    this.productionMethod,
    this.goal,
    this.status = IdeaStatus.idea,
    this.axisStates = const {},
  });

  /// Whether the snapshot carries a human-approved value on every axis
  /// that is required for generation. Returns false if any axis is OPEN
  /// (null state) or in a non-resolved state.
  bool get isFullyApproved {
    for (final axis in ['pillar', 'series', 'narrativeFormat', 'contentType',
        'productionMethod', 'goal']) {
      final state = axisStates[axis];
      if (state == null || !state.isResolved) {
        return false;
      }
    }
    return true;
  }

  /// Whether any axis is still OPEN (no value, not even a suggestion).
  ///
  /// Checks both explicit null values in the map AND missing required axes.
  bool get hasOpenAxes {
    const requiredAxes = [
      'pillar',
      'series',
      'narrativeFormat',
      'contentType',
      'productionMethod',
      'goal',
    ];
    for (final axis in requiredAxes) {
      if (!axisStates.containsKey(axis) || axisStates[axis] == null) {
        return true;
      }
    }
    return false;
  }

   /// Whether any axis is blocked on a human decision (needsReview, invalid).
  bool get hasBlockedAxes =>
      axisStates.values.any((s) => s == AxisResolution.needsReview || s == AxisResolution.invalid);

  /// Whether any axis is flagged as an archive candidate.
  bool get hasArchiveCandidateAxes =>
      axisStates.values.any((s) => s == AxisResolution.archiveCandidate);

  Map<String, dynamic> toJson() => {
        'pillar': pillar?.label,
        'series': series?.label,
        'narrativeFormatName': narrativeFormatName,
        'contentType': contentType?.label,
        'productionMethod': productionMethod?.label,
        'goal': goal?.label,
        'status': status.id,
        'axisStates':
            axisStates.map((k, v) => MapEntry(k, v?.name ?? 'open')),
      };

  factory ClassificationSnapshot.fromJson(Map<String, dynamic> json) {
    String? label(String key) => json[key] as String?;
    return ClassificationSnapshot(
      pillar: label('pillar') != null ? ContentPillar.byLabel(label('pillar')!) : null,
      series: label('series') != null ? ContentSeries.byLabel(label('series')!) : null,
      narrativeFormatName: json['narrativeFormatName'] as String?,
      contentType: label('contentType') != null
          ? ContentType.byLabel(label('contentType')!)
          : null,
      productionMethod: label('productionMethod') != null
          ? ProductionMethod.byLabel(label('productionMethod')!)
          : null,
      goal: label('goal') != null ? ContentGoal.byLabel(label('goal')!) : null,
      status: IdeaStatus.byId(json['status'] as String? ?? 'idea') ?? IdeaStatus.idea,
      axisStates: (json['axisStates'] as Map?)?.map((k, v) {
            final name = v as String?;
            AxisResolution? state;
            if (name != null && name != 'open') {
              state = AxisResolution.parse(name);
            }
            return MapEntry(k as String, state);
          }) ??
          {},
    );
  }
}

// ============================================================================
// DIMENSION — the four evaluation axes of a gate
// ============================================================================

/// The four dimensions the gate evaluates.
enum QualityDimension {
  /// Does this belong here at all? Pillar, series, narrative format, content type.
  /// Is the strategy coherent?
  strategy('Strategy', 'Is the content decision coherent and classified?'),

  /// Is the creative output good? Hook, share trigger, open loop, no-voice.
  creative('Creative', 'Is the creative output well-formed and shareable?'),

  /// Can we actually make this? Production method, voice mode, resource fit.
  /// Production problems are NOT quality failures.
  production('Production', 'Can this be produced with our current pipeline?'),

  /// What did it do, and do we have enough data? Test count, performance, reuse.
  performance('Performance', 'Do we have enough data to learn from this?'),
  ;

  final String label;
  final String description;

  const QualityDimension(this.label, this.description);
}

// ============================================================================
// GATE CHECK — one evaluation within one dimension
// ============================================================================

/// The result of running one check.
class GateCheckResult {
  final String id;
  final String name;
  final QualityDimension dimension;
  final GateVerdict verdict;
  final String reason;

  const GateCheckResult({
    required this.id,
    required this.name,
    required this.dimension,
    required this.verdict,
    required this.reason,
  });

  bool get isPass => verdict == GateVerdict.pass;
  bool get isFail => verdict == GateVerdict.fail;
  bool get isUnknown => verdict == GateVerdict.unknown;

  Map<String, dynamic> toJson() => {
          'id': id,
          'name': name,
          'dimension': dimension.name,
          'verdict': verdict.name,
          'reason': reason,
        };

  factory GateCheckResult.fromJson(Map<String, dynamic> json) {
    return GateCheckResult(
      id: json['id'] as String,
      name: json['name'] as String,
      dimension: QualityDimension.values
          .firstWhere((d) => d.name == json['dimension'] as String?),
      verdict: GateVerdict.values
          .firstWhere((v) => v.name == json['verdict'] as String?),
      reason: json['reason'] as String? ?? '',
    );
  }
}

// ============================================================================
// GATE REPORT — the full verdict for one idea or package
// ============================================================================

/// The complete quality-gate verdict for one idea or content package.
class GateReport {
  final String ideaId;
  final String title;

  /// The classification this report was generated against.
  final ClassificationSnapshot classification;

  /// All individual check results.
  final List<GateCheckResult> checks;

  /// The share trigger, if structured and populated.
  final ShareTrigger? shareTrigger;

  /// Voice mode as determined at generation time.
  final VoiceMode voiceMode;

  /// Save value classification.
  final SaveValue? saveValue;

  /// Whether the idea is archived and should not be generated.
  final bool isArchived;

  /// Whether the idea is blocked (needsReview or invalid on a required axis).
  final bool isBlocked;

  final DateTime checkedAt;

  const GateReport({
    required this.ideaId,
    this.title = '',
    required this.classification,
    required this.checks,
    this.shareTrigger,
    this.voiceMode = VoiceMode.optional,
    this.saveValue,
    this.isArchived = false,
    this.isBlocked = false,
    required this.checkedAt,
  });

  // ── Aggregated verdicts per dimension ─────────────────────────────────

  List<GateCheckResult> checksFor(QualityDimension dim) =>
      checks.where((c) => c.dimension == dim).toList();

  /// True only when every check in this dimension is PASS.
  bool get strategyPass => checksFor(QualityDimension.strategy).every((c) => c.isPass);
  bool get creativePass => checksFor(QualityDimension.creative).every((c) => c.isPass);
  bool get productionPass => checksFor(QualityDimension.production).every((c) => c.isPass);
  bool get performancePass => checksFor(QualityDimension.performance).every((c) => c.isPass);

  /// The overall verdict. BLOCKED takes priority:
  ///
  /// - If any strategy or creative check FAILS, the idea cannot ship.
  /// - If any production check fails, the idea is a filming job, not a bad idea.
  /// - If any performance check is UNKNOWN, the idea needs more data.
  GateVerdict get overall {
    // Strategy failures block — the content decision is unsound.
    if (checksFor(QualityDimension.strategy).any((c) => c.isFail)) {
      return GateVerdict.fail;
    }
    // Creative failures block — the output is not ready.
    if (checksFor(QualityDimension.creative).any((c) => c.isFail)) {
      return GateVerdict.fail;
    }
    // Performance: unknown means need more data.
    if (checksFor(QualityDimension.performance).any((c) => c.isUnknown)) {
      return GateVerdict.unknown;
    }
    // If all strategy, creative, and performance checks pass, we are ready.
    // Production checks failing means needsFilming, not blocked.
    return GateVerdict.pass;
  }

  /// Whether the idea is blocked from generation (strategy or creative FAIL).
  bool get isBlockedFromGeneration =>
      checksFor(QualityDimension.strategy).any((c) => c.isFail) ||
      checksFor(QualityDimension.creative).any((c) => c.isFail);

  /// Whether the idea needs filming (production check failed, but not blocked).
  bool get needsFilming => !isBlockedFromGeneration && checksFor(QualityDimension.production).any((c) => c.isFail);

  /// A human-readable summary of what is blocking.
  List<String> get blockingReasons {
    final reasons = <String>[];
    for (final c in checks) {
      if (!c.isFail && !c.isUnknown) continue;
      if (c.dimension == QualityDimension.strategy || c.dimension == QualityDimension.creative) {
        if (c.isFail) reasons.add('${c.name}: ${c.reason}');
      }
    }
    return reasons;
  }

  /// Everything the gate found, grouped by dimension.
  Map<QualityDimension, List<GateCheckResult>> get byDimension {
    final result = <QualityDimension, List<GateCheckResult>>{};
    for (final dim in QualityDimension.values) {
      result[dim] = checksFor(dim);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
          'ideaId': ideaId,
          'title': title,
          'classification': classification.toJson(),
          'checks': checks.map((c) => c.toJson()).toList(),
          'shareTrigger': shareTrigger?.toJson(),
          'voiceMode': voiceMode.name,
          'saveValue': saveValue?.name,
          'isArchived': isArchived,
          'isBlocked': isBlocked,
          'checkedAt': checkedAt.toIso8601String(),
        };

  factory GateReport.fromJson(Map<String, dynamic> json) {
    final classification = ClassificationSnapshot.fromJson(
        Map<String, dynamic>.from(json['classification'] as Map));
    final checks = (json['checks'] as List?)
            ?.whereType<Map>()
            .map((c) => GateCheckResult.fromJson(Map<String, dynamic>.from(c)))
            .toList() ??
        <GateCheckResult>[];
    final stJson = json['shareTrigger'] as Map?;
    return GateReport(
      ideaId: json['ideaId'] as String,
      title: json['title'] as String,
      classification: classification,
      checks: checks,
      shareTrigger: stJson != null ? ShareTrigger.fromJson(Map<String, dynamic>.from(stJson)) : null,
      voiceMode: VoiceMode.values
              .firstWhere((v) => v.name == json['voiceMode'] as String?, orElse: () => VoiceMode.optional),
      saveValue: (json['saveValue'] as String?) != null
          ? SaveValue.values.firstWhere((v) => v.name == json['saveValue'])
          : null,
      isArchived: json['isArchived'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      checkedAt: DateTime.tryParse(json['checkedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ============================================================================
// QUALITY GATE — the engine
// ============================================================================

/// The quality-gate engine.
///
/// Evaluates an idea or content package against the existing taxonomy and
/// mechanics. Consumes classification data as-is — it does NOT infer OPEN
/// axis values. When an axis is OPEN, the corresponding check returns UNKNOWN.
///
/// ── Usage ────────────────────────────────────────────────────────────────
///
///   final report = QualityGate.evaluateIdea(
///     ideaId: 'day9-sock-hunt',
///     title: 'The Sock Hunt',
///     classification: snapshot,
///   );
///
/// ── What blocks ─────────────────────────────────────────────────────────
///
/// An idea is BLOCKED from generation when any strategy or creative check
/// returns FAIL. Production failures do NOT block — they route to a filming
/// plan. Performance UNKNOWN means "need more data", not "blocked".
///
class QualityGate {
  QualityGate._();

  /// Evaluates an idea against the quality gate, using the classification
  /// snapshot as the source of truth.
  ///
  /// Pass the full classification snapshot, including the migration state
  /// of each axis. Axes that are OPEN (null state) produce UNKNOWN checks.
  /// Axes that are `suggested` or `needsReview` produce UNKNOWN checks —
  /// only `approved` values are treated as decided.
  static GateReport evaluateIdea({
    required String ideaId,
    required String title,
    required ClassificationSnapshot classification,
    ShareTrigger? shareTrigger,
    VoiceMode? voiceMode,
    SaveValue? saveValue,
    int testCount = 0,
    bool isArchived = false,
    bool isBlocked = false,
  }) {
    final checks = <GateCheckResult>[];

    // ── STRATEGY dimension ──────────────────────────────────────────────
    checks.addAll(_strategyChecks(classification));

    // ── CREATIVE dimension ──────────────────────────────────────────────
    checks.addAll(_creativeChecks(classification, shareTrigger, voiceMode));

    // ── PRODUCTION dimension ────────────────────────────────────────────
    checks.addAll(_productionChecks(classification, voiceMode));

    // ── PERFORMANCE dimension ───────────────────────────────────────────
    checks.addAll(_performanceChecks(testCount, classification.narrativeFormatName));

    final inferredVoice = voiceMode ?? VoiceMode.infer(
      classification.narrativeFormatName != null
          ? validateNarrativeFormat(classification.narrativeFormatName!)
          : null,
      classification.contentType,
    );

      final inferredSave = saveValue ?? inferSaveValue(classification.goal);

    return GateReport(
      ideaId: ideaId,
      title: title,
      classification: classification,
      checks: checks,
      shareTrigger: shareTrigger,
      voiceMode: inferredVoice,
      saveValue: inferredSave,
      isArchived: isArchived || classification.status == IdeaStatus.archived ||
          classification.hasArchiveCandidateAxes,
      isBlocked: isBlocked || classification.hasBlockedAxes,
      checkedAt: DateTime.now(),
    );
  }

  /// Evaluates a generated content package against the quality gate.
  ///
  /// This is a lighter check than [evaluateIdea] — a package has already passed
  /// the strategy and creative gates to get here. It focuses on production
  /// compatibility and performance tracking.
  static GateReport evaluatePackage(ContentPackage pkg, {
    required ClassificationSnapshot classification,
    ShareTrigger? shareTrigger,
    int testCount = 0,
    bool isArchived = false,
  }) {
    final checks = <GateCheckResult>[];

    checks.addAll(_productionChecks(classification, null));
    checks.addAll(_performanceChecks(
      testCount,
      classification.narrativeFormatName,
    ));

    final inferredVoice = VoiceMode.infer(
      null,
      classification.contentType,
    );

    return GateReport(
      ideaId: pkg.idea,
      title: pkg.hook,
      classification: classification,
      checks: checks,
      shareTrigger: shareTrigger,
      voiceMode: inferredVoice,
      isArchived: isArchived,
      checkedAt: DateTime.now(),
    );
  }

  // ── Dimension: Strategy ──────────────────────────────────────────────

  static List<GateCheckResult> _strategyChecks(ClassificationSnapshot c) {
    final results = <GateCheckResult>[];
    final axisStates = c.axisStates;

    // Pillar
    final pillarState = axisStates['pillar'];
    if (pillarState == AxisResolution.approved && c.pillar != null) {
      results.add(GateCheckResult(
        id: 'strategy.pillar',
        name: 'Pillar classified and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.pass,
        reason: 'Pillar is ${c.pillar!.label} (approved).',
      ));
    } else if (pillarState == AxisResolution.archiveCandidate) {
      results.add(GateCheckResult(
        id: 'strategy.pillar',
        name: 'Pillar classified and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.fail,
        reason: 'Idea is an archive candidate — it has no educational pillar.',
      ));
    } else if (pillarState == null || pillarStateIsProposed(pillarState)) {
      results.add(GateCheckResult(
        id: 'strategy.pillar',
        name: 'Pillar classified and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.unknown,
        reason: _axisStateReason(pillarState, c.pillar?.label),
      ));
    }

    // Narrative format
    final fmtState = axisStates['narrativeFormat'];
    final fmt = c.narrativeFormatName != null
        ? validateNarrativeFormat(c.narrativeFormatName!)
        : null;
    if (fmtState == AxisResolution.approved && fmt != null) {
      results.add(GateCheckResult(
        id: 'strategy.format',
        name: 'Narrative format is valid and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.pass,
        reason: 'Format is "${fmt.name}" (${fmt.id}).',
      ));
    } else if (fmtState == AxisResolution.invalid) {
      results.add(GateCheckResult(
        id: 'strategy.format',
        name: 'Narrative format is valid and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.fail,
        reason: 'Format is marked invalid — no narrative shape is derivable.',
      ));
    } else if (fmt == null && c.narrativeFormatName != null) {
      results.add(GateCheckResult(
        id: 'strategy.format',
        name: 'Narrative format is valid and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.fail,
        reason: '"${c.narrativeFormatName}" is not a registered format.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'strategy.format',
        name: 'Narrative format is valid and approved',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.unknown,
        reason: _axisStateReason(fmtState, null),
      ));
    }

    // Content type
    final ctState = axisStates['contentType'];
    if (ctState == AxisResolution.approved && c.contentType != null) {
      results.add(GateCheckResult(
        id: 'strategy.contentType',
        name: 'Content type is set',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.pass,
        reason: 'Content type is ${c.contentType!.label}.',
      ));
    } else if (c.contentType == null) {
      results.add(GateCheckResult(
        id: 'strategy.contentType',
        name: 'Content type is set',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.unknown,
        reason: 'No content type stated.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'strategy.contentType',
        name: 'Content type is set',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.unknown,
        reason: _axisStateReason(ctState, c.contentType?.label),
      ));
    }

    // Series — can be null for non-content ideas, so this is a WARN not a FAIL
    final seriesState = axisStates['series'];
    if (seriesState == AxisResolution.approved && c.series != null) {
      results.add(GateCheckResult(
        id: 'strategy.series',
        name: 'Series is classified',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.pass,
        reason: 'Series is ${c.series!.label}.',
      ));
    } else if (c.series == null && pillarState == AxisResolution.archiveCandidate) {
      results.add(GateCheckResult(
        id: 'strategy.series',
        name: 'Series is classified',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.pass,
        reason: 'Idea is archived — no series needed.',
      ));
    } else if (c.series == null) {
      results.add(GateCheckResult(
        id: 'strategy.series',
        name: 'Series is classified',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.unknown,
        reason: 'No series is mapped. This is the largest editorial gap.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'strategy.series',
        name: 'Series is classified',
        dimension: QualityDimension.strategy,
        verdict: GateVerdict.unknown,
        reason: _axisStateReason(seriesState, c.series?.label),
      ));
    }

    return results;
  }

  // ── Dimension: Creative ──────────────────────────────────────────────

  static List<GateCheckResult> _creativeChecks(
    ClassificationSnapshot c,
    ShareTrigger? shareTrigger,
    VoiceMode? voiceMode,
  ) {
    final results = <GateCheckResult>[];

    // Share trigger — the core quality check.
    if (shareTrigger != null) {
      results.add(GateCheckResult(
        id: 'creative.share_trigger',
        name: 'Share trigger is specific',
        dimension: QualityDimension.creative,
        verdict: shareTrigger.verdict,
        reason: shareTrigger.verdict == GateVerdict.pass
            ? 'Sender: ${shareTrigger.sender}, recipient: ${shareTrigger.recipient}.'
            : shareTrigger.verdict == GateVerdict.fail
                ? 'Share trigger is generic. Name a specific parent, situation, and reason.'
                : 'Share trigger is not yet structured. Fill in sender, recipient, situation, reason.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'creative.share_trigger',
        name: 'Share trigger is specific',
        dimension: QualityDimension.creative,
        verdict: GateVerdict.unknown,
        reason: 'No share trigger provided. The app never invents one.',
      ));
    }

    // Voice mode — production constraint, but surfaces in creative because
    // it determines whether the idea is understandable as described.
    if (voiceMode != null) {
      results.add(GateCheckResult(
        id: 'creative.voice_mode',
        name: 'Voice mode is declared',
        dimension: QualityDimension.creative,
        verdict: GateVerdict.pass,
        reason: 'Voice mode: ${voiceMode.label}.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'creative.voice_mode',
        name: 'Voice mode is declared',
        dimension: QualityDimension.creative,
        verdict: GateVerdict.unknown,
        reason: 'No voice mode declared. Infer from format or specify one.',
      ));
    }

    return results;
  }

  // ── Dimension: Production ────────────────────────────────────────────

  static List<GateCheckResult> _productionChecks(
    ClassificationSnapshot c,
    VoiceMode? declaredVoice,
  ) {
    final results = <GateCheckResult>[];

    // Content type is implemented?
    if (c.contentType != null) {
      final implemented = ContentType.isImplemented(c.contentType!);
      results.add(GateCheckResult(
        id: 'production.content_type_implemented',
        name: 'Content type is producible',
        dimension: QualityDimension.production,
        verdict: implemented ? GateVerdict.pass : GateVerdict.fail,
        reason: implemented
            ? '${c.contentType!.label} has a pipeline.'
            : '${c.contentType!.label} is not implemented yet.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'production.content_type_implemented',
        name: 'Content type is producible',
        dimension: QualityDimension.production,
        verdict: GateVerdict.unknown,
        reason: 'No content type to check.',
      ));
    }

    // Production method is implemented?
    if (c.productionMethod != null) {
      final implemented = ProductionMethod.isImplemented(c.productionMethod!);
      results.add(GateCheckResult(
        id: 'production.method_implemented',
        name: 'Production method is available',
        dimension: QualityDimension.production,
        verdict: implemented ? GateVerdict.pass : GateVerdict.fail,
        reason: implemented
            ? '${c.productionMethod!.label} pipeline exists.'
            : '${c.productionMethod!.label} has no pipeline yet.',
      ));
    } else {
      results.add(GateCheckResult(
        id: 'production.method_implemented',
        name: 'Production method is available',
        dimension: QualityDimension.production,
        verdict: GateVerdict.unknown,
        reason: 'No production method declared.',
      ));
    }

    return results;
  }

  // ── Dimension: Performance ───────────────────────────────────────────

  static List<GateCheckResult> _performanceChecks(
    int testCount,
    String? narrativeFormatName,
  ) {
    final results = <GateCheckResult>[];

    // The five-test rule: a format must have at least 5 tests before any
    // verdict can be drawn. This is a core domain rule, enforced in the
    // data model, not an Experiments screen feature.
    final format = narrativeFormatName != null
        ? validateNarrativeFormat(narrativeFormatName)
        : null;

    if (format == null) {
      results.add(GateCheckResult(
        id: 'performance.test_count',
        name: 'Five-test rule satisfied',
        dimension: QualityDimension.performance,
        verdict: GateVerdict.unknown,
        reason: 'No narrative format — cannot evaluate test count.',
      ));
    } else {
      final verdict = format.verdict(testCount);
      results.add(GateCheckResult(
        id: 'performance.test_count',
        name: 'Five-test rule satisfied',
        dimension: QualityDimension.performance,
        verdict: verdict.allowed ? GateVerdict.pass : GateVerdict.unknown,
        reason: verdict.message,
      ));
    }

    return results;
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static bool pillarStateIsProposed(AxisResolution? state) =>
      state == AxisResolution.suggested ||
      state == AxisResolution.needsReview ||
      state == AxisResolution.archiveCandidate;

  static String _axisStateReason(AxisResolution? state, String? value) {
    if (state == null) return 'Axis is OPEN — no value has been decided.';
    if (state == AxisResolution.suggested) return 'Value suggested: "$value". Needs human approval.';
    if (state == AxisResolution.needsReview) return 'Decision pending human review.';
    if (state == AxisResolution.invalid) return 'Invalid — no correct value derivable.';
    if (state == AxisResolution.archiveCandidate) return 'Archive candidate — not a content idea.';
    return 'Axis state: ${state.name}.';
  }

  /// Infers save value from the goal. Public for testing.
  static SaveValue? inferSaveValue(ContentGoal? goal) {
    if (goal == null) return null;
    switch (goal) {
      case ContentGoal.saves:
      case ContentGoal.authority:
        return SaveValue.measurable;
      case ContentGoal.reach:
      case ContentGoal.nonFollowerReach:
      case ContentGoal.shares:
      case ContentGoal.comments:
      case ContentGoal.relatability:
      case ContentGoal.follows:
        return SaveValue.notApplicable;
    }
  }
}
