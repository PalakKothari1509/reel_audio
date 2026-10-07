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
// OPEN LOOP — structured
// ============================================================================
//
// An open loop is something withheld that gives the viewer a reason to stay
// (watch to the end, comment, rewatch). It is NOT required for every format.
// Formats that benefit from open loops: Mini Story, Problem → Fix, Expectation
// vs Reality, This or That. Formats that don't: Save This List, Quick Tip,
// POV, Three Examples, Numbered Framework.

/// The honest verdict for the open loop as a whole.
enum OpenLoopVerdict {
  pass('PASS', 'An open loop is present and specific.'),
  fail('FAIL', 'Open loop claimed but is generic/vague.'),
  unknown('UNKNOWN', 'Not provided or cannot be determined.'),
  notRequired('NOT_REQUIRED', 'Format does not require an open loop.');

  final String label;
  final String description;

  const OpenLoopVerdict(this.label, this.description);
}

/// A structured open loop with the pattern that creates retention.
///
/// The structure mirrors what makes content binge-worthy:
/// - `withheld`: what is withheld from the viewer (the question, the reveal)
/// - `promise`: what the viewer gets if they stay (the answer, the payoff)
/// - `mechanic`: how it's delivered (cliffhanger, puzzle, twist, reveal)
/// - `payoff`: the specific outcome (the answer, the resolution)
///
/// Each field defaults to UNKNOWN until a human provides a concrete answer.
class OpenLoop {
  /// What is withheld? Must be specific, not "the answer".
  final String? withheld;
  final bool withheldKnown;

  /// What does the viewer get if they stay?
  final String? promise;
  final bool promiseKnown;

  /// How is it delivered? (cliffhanger, puzzle, twist, reveal, question)
  final String? mechanic;
  final bool mechanicKnown;

  /// What is the specific payoff?
  final String? payoff;
  final bool payoffKnown;

  /// Which format is this for? Some formats don't need open loops.
  final String? formatName;

  const OpenLoop({
    this.withheld,
    this.promise,
    this.mechanic,
    this.payoff,
    this.formatName,
    this.withheldKnown = false,
    this.promiseKnown = false,
    this.mechanicKnown = false,
    this.payoffKnown = false,
  });

  /// Creates a fully-populated open loop.
  OpenLoop.filled({
    required String this.withheld,
    required String this.promise,
    required String this.mechanic,
    required String this.payoff,
    this.formatName,
  })  : withheldKnown = true,
        promiseKnown = true,
        mechanicKnown = true,
        payoffKnown = true;

  /// Formats that benefit from open loops (from reach_mechanics and format handbook).
  static const _formatsWithOpenLoop = {
    'ministory',
    'problemfix',
    'expectationreality',
    'thisorthat',
    'personalmistake',
    'unpopularopinion',
    'beforeyou',
    'questionanswer',
    'quicktip',
  };

  /// Formats that explicitly do NOT need open loops.
  static const _formatsWithoutOpenLoop = {
    'savethislist',
    'pov',
    'numberedframework',
    'threeexamples',
    'dothisnotthat',
    'mistakeslist',
    'exactscript',
  };

  /// Whether the given format name benefits from an open loop.
  static bool formatNeedsOpenLoop(String? formatName) {
    if (formatName == null) return false;
    final lower = formatName.toLowerCase();
    return _formatsWithOpenLoop.contains(lower);
  }

  /// Whether the given format explicitly does not need an open loop.
  static bool formatDoesNotNeedOpenLoop(String? formatName) {
    if (formatName == null) return false;
    final lower = formatName.toLowerCase();
    return _formatsWithoutOpenLoop.contains(lower);
  }

  /// The honest verdict for the open loop as a whole.
  ///
  /// Returns 'pass' only when all four components are populated with
  /// non-empty, specific text AND the format benefits from open loops.
  /// Returns 'fail' when there is text but it is generic/vague.
  /// Returns 'notRequired' when the format doesn't need open loops.
  /// Returns 'unknown' when the fields are empty, absent, or not all known.
  OpenLoopVerdict get verdict {
    // If format doesn't need open loops, return notRequired (not a failure).
    if (formatName != null && OpenLoop.formatDoesNotNeedOpenLoop(formatName)) {
      return OpenLoopVerdict.notRequired;
    }

    // If any field is not known (not even provided), it's UNKNOWN.
    if (!withheldKnown || !promiseKnown || !mechanicKnown || !payoffKnown) {
      return OpenLoopVerdict.unknown;
    }

    // All four are marked as known — but if any is empty, it's still UNKNOWN.
    if (withheld == null ||
        withheld!.trim().isEmpty ||
        promise == null ||
        promise!.trim().isEmpty ||
        mechanic == null ||
        mechanic!.trim().isEmpty ||
        payoff == null ||
        payoff!.trim().isEmpty) {
      return OpenLoopVerdict.unknown;
    }

    // All four are populated — check for genericness.
    if (_isGeneric(withheld!) ||
        _isGeneric(promise!) ||
        _isGeneric(mechanic!) ||
        _isGeneric(payoff!)) {
      return OpenLoopVerdict.fail;
    }

    // Format benefits from open loops and all fields are specific.
    if (formatName != null && OpenLoop.formatNeedsOpenLoop(formatName)) {
      return OpenLoopVerdict.pass;
    }

    // Format is not in the known lists — be conservative.
    return OpenLoopVerdict.unknown;
  }

  static bool _isGeneric(String? s) {
    if (s == null || s.trim().isEmpty) return true;
    final lower = s.toLowerCase();
    final generic = [
      'the answer',
      'the reveal',
      'what happens',
      'find out',
      'watch to see',
      'stay tuned',
      'you will see',
      'cliffhanger',
    ];
    return generic.any(lower.contains);
  }

  OpenLoop copyWith({
    String? Function()? withheld,
    String? Function()? promise,
    String? Function()? mechanic,
    String? Function()? payoff,
    String? Function()? formatName,
    bool? withheldKnown,
    bool? promiseKnown,
    bool? mechanicKnown,
    bool? payoffKnown,
  }) {
    return OpenLoop(
      withheld: withheld != null ? withheld() : this.withheld,
      promise: promise != null ? promise() : this.promise,
      mechanic: mechanic != null ? mechanic() : this.mechanic,
      payoff: payoff != null ? payoff() : this.payoff,
      formatName: formatName != null ? formatName() : this.formatName,
      withheldKnown: withheldKnown ?? this.withheldKnown,
      promiseKnown: promiseKnown ?? this.promiseKnown,
      mechanicKnown: mechanicKnown ?? this.mechanicKnown,
      payoffKnown: payoffKnown ?? this.payoffKnown,
    );
  }

  Map<String, dynamic> toJson() => {
        'withheld': withheld,
        'promise': promise,
        'mechanic': mechanic,
        'payoff': payoff,
        'formatName': formatName,
        'withheldKnown': withheldKnown,
        'promiseKnown': promiseKnown,
        'mechanicKnown': mechanicKnown,
        'payoffKnown': payoffKnown,
      };

  factory OpenLoop.fromJson(Map<String, dynamic> json) => OpenLoop(
        withheld: json['withheld'] as String?,
        promise: json['promise'] as String?,
        mechanic: json['mechanic'] as String?,
        payoff: json['payoff'] as String?,
        formatName: json['formatName'] as String?,
        withheldKnown: json['withheldKnown'] as bool? ?? false,
        promiseKnown: json['promiseKnown'] as bool? ?? false,
        mechanicKnown: json['mechanicKnown'] as bool? ?? false,
        payoffKnown: json['payoffKnown'] as bool? ?? false,
      );
}

/// The three honest answers to a gate check.
enum GateVerdict {
  pass('PASS', 'The gate is satisfied.'),
  fail('FAIL', 'The gate is not met.'),
  unknown('UNKNOWN', 'Cannot be determined from the available data.');

  final String label;
  final String description;

  const GateVerdict(this.label, this.description);
}

/// The three honest answers to the Ready-to-Generate gate.
enum ReadyToGenerateVerdict {
  pass('PASS', 'All requirements met — safe to generate.'),
  fail('FAIL', 'Critical requirements missing — cannot generate.'),
  unknown('UNKNOWN', 'Insufficient information to determine readiness.');

  final String label;
  final String description;

  const ReadyToGenerateVerdict(this.label, this.description);
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

  final ShareTrigger shareTrigger;
  final OpenLoop openLoop;

  const ClassificationSnapshot({
    this.pillar,
    this.series,
    this.narrativeFormatName,
    this.contentType,
    this.productionMethod,
    this.goal,
    this.status = IdeaStatus.idea,
    this.axisStates = const {},
    this.shareTrigger = const ShareTrigger(),
    this.openLoop = const OpenLoop(),
  });

  /// Whether the snapshot carries a human-approved value on every axis
  /// that is required for generation. Returns false if any axis is OPEN
  /// (null state) or in a non-resolved state.
  bool get isFullyApproved {
    for (final axis in [
      'pillar',
      'series',
      'narrativeFormat',
      'contentType',
      'productionMethod',
      'goal'
    ]) {
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

/// The result of the Ready-to-Generate gate.
///
/// This is a separate gate from the quality gate — it answers only:
/// "Is this idea complete and safe enough to send to AI for generation?"
/// It does NOT generate missing values; it only validates.
class ReadyToGenerateReport {
  final String ideaId;
  final String title;
  final ReadyToGenerateVerdict verdict;
  final List<ReadyCheck> checks;
  final DateTime checkedAt;

  const ReadyToGenerateReport({
    required this.ideaId,
    this.title = '',
    required this.verdict,
    required this.checks,
    required this.checkedAt,
  });

  /// True when every individual check is PASS.
  bool get isReady => checks.every((c) => c.isPass);

  /// True when any check is FAIL (cannot proceed).
  bool get isBlocked => checks.any((c) => c.isFail);

  /// True when any check is UNKNOWN (needs review).
  bool get needsReview => checks.any((c) => c.isUnknown);

  Map<String, dynamic> toJson() => {
        'ideaId': ideaId,
        'title': title,
        'verdict': verdict.name,
        'checks': checks.map((c) => c.toJson()).toList(),
        'checkedAt': checkedAt.toIso8601String(),
      };

  factory ReadyToGenerateReport.fromJson(Map<String, dynamic> json) {
    return ReadyToGenerateReport(
      ideaId: json['ideaId'] as String,
      title: json['title'] as String? ?? '',
      verdict: ReadyToGenerateVerdict.values
          .firstWhere((v) => v.name == json['verdict'] as String?),
      checks: (json['checks'] as List?)
              ?.whereType<Map>()
              .map((c) => ReadyCheck.fromJson(Map<String, dynamic>.from(c)))
              .toList() ??
          <ReadyCheck>[],
      checkedAt: DateTime.tryParse(json['checkedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// One check within the Ready-to-Generate gate.
class ReadyCheck {
  final String id;
  final String name;
  final ReadyToGenerateVerdict verdict;
  final String reason;

  const ReadyCheck({
    required this.id,
    required this.name,
    required this.verdict,
    required this.reason,
  });

  bool get isPass => verdict == ReadyToGenerateVerdict.pass;
  bool get isFail => verdict == ReadyToGenerateVerdict.fail;
  bool get isUnknown => verdict == ReadyToGenerateVerdict.unknown;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'verdict': verdict.name,
        'reason': reason,
      };

  factory ReadyCheck.fromJson(Map<String, dynamic> json) => ReadyCheck(
        id: json['id'] as String,
        name: json['name'] as String,
        verdict: ReadyToGenerateVerdict.values
            .firstWhere((v) => v.name == json['verdict'] as String?),
        reason: json['reason'] as String? ?? '',
      );
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
    OpenLoop? openLoop,
    SaveValue? saveValue,
    int testCount = 0,
    bool isArchived = false,
    bool isBlocked = false,
  }) {
    final checks = <GateCheckResult>[];

    // ── STRATEGY dimension ──────────────────────────────────────────────
    checks.addAll(_strategyChecks(classification));

    // ── CREATIVE dimension ──────────────────────────────────────────────
    checks.addAll(_creativeChecks(classification, shareTrigger, voiceMode, openLoop));

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
  ///
  /// Takes [ideaId] and [title] directly rather than a ContentPackage to avoid
  /// pulling Flutter dependencies into the gate library.
  static GateReport evaluatePackage(String ideaId, String title, {
    required ClassificationSnapshot classification,
    ShareTrigger? shareTrigger,
    OpenLoop? openLoop,
    int testCount = 0,
    bool isArchived = false,
  }) {
    final checks = <GateCheckResult>[];

    // Packages have already passed strategy/creative, but we check production
    // and performance, plus verify creative elements still hold.
    checks.addAll(_productionChecks(classification, null));
    checks.addAll(_creativeChecks(classification, shareTrigger, null, openLoop));
    checks.addAll(_performanceChecks(
      testCount,
      classification.narrativeFormatName,
    ));

    final inferredVoice = VoiceMode.infer(
      null,
      classification.contentType,
    );

    return GateReport(
      ideaId: ideaId,
      title: title,
      classification: classification,
      checks: checks,
      shareTrigger: shareTrigger,
      voiceMode: inferredVoice,
      isArchived: isArchived,
      checkedAt: DateTime.now(),
    );
  }

  /// Evaluates whether an idea is ready for AI generation.
  ///
  /// This is the **Ready-to-Generate gate** — it answers only:
  /// "Is this idea complete and safe enough to send to AI for ContentPackageV2 generation?"
  /// It does NOT generate missing values; it only validates.
  ///
  /// Returns PASS only when ALL checks pass.
  /// Returns FAIL when any critical requirement is missing.
  /// Returns UNKNOWN when information is insufficient to decide.
  static ReadyToGenerateReport evaluateReadyToGenerate({
    required String ideaId,
    required String title,
    required ClassificationSnapshot classification,
    ShareTrigger? shareTrigger,
    OpenLoop? openLoop,
    VoiceMode? voiceMode,
    int testCount = 0,
    bool isArchived = false,
  }) {
    final checks = <ReadyCheck>[];

    // 1. Classification: all 7 axes must be resolved (approved in decisions)
    checks.add(_checkClassificationComplete(classification));

    // 2. Share Trigger: must be PASS
    checks.add(_checkShareTriggerReady(shareTrigger, classification));

    // 3. Open Loop: must be PASS or NOT_REQUIRED
    checks.add(_checkOpenLoopReady(openLoop, classification));

    // 4. Voice Mode: must be declared
    checks.add(_checkVoiceModeReady(voiceMode, classification));

    // 5. Production Method: must be resolved
    checks.add(_checkProductionMethodReady(classification));

    // 6. Goal: must be resolved
    checks.add(_checkGoalReady(classification));

    // 7. Content Type: must be resolved
    checks.add(_checkContentTypeReady(classification));

    // 8. Narrative Format: must be resolved
    checks.add(_checkNarrativeFormatReady(classification));

    // 9. Source content: enough information to generate
    checks.add(_checkSourceContentSufficient(classification));

    // 10. Status: appropriate pre-generation status
    checks.add(_checkStatusReady(classification, isArchived));

    // Determine overall verdict
    final hasFail = checks.any((c) => c.isFail);
    final hasUnknown = checks.any((c) => c.isUnknown);

    ReadyToGenerateVerdict verdict;
    if (hasFail) {
      verdict = ReadyToGenerateVerdict.fail;
    } else if (hasUnknown) {
      verdict = ReadyToGenerateVerdict.unknown;
    } else {
      verdict = ReadyToGenerateVerdict.pass;
    }

    return ReadyToGenerateReport(
      ideaId: ideaId,
      title: title,
      verdict: verdict,
      checks: checks,
      checkedAt: DateTime.now(),
    );
  }

  // ── Ready-to-Generate Checks ───────────────────────────────────────────

  static ReadyCheck _checkClassificationComplete(ClassificationSnapshot c) {
    // All 7 axes must have approved values
    const requiredAxes = [
      'pillar',
      'series',
      'narrativeFormat',
      'contentType',
      'productionMethod',
      'goal',
      'status',
    ];
    final missing = <String>[];
    for (final axis in requiredAxes) {
      final state = c.axisStates[axis];
      if (state == null || state != AxisResolution.approved) {
        missing.add(axis);
      }
    }
    if (missing.isEmpty) {
      return ReadyCheck(
        id: 'ready.classification',
        name: 'All 7 axes resolved',
        verdict: ReadyToGenerateVerdict.pass,
        reason: 'All 7 axes (pillar, series, narrativeFormat, contentType, productionMethod, goal, status) are approved.',
      );
    } else {
      return ReadyCheck(
        id: 'ready.classification',
        name: 'All 7 axes resolved',
        verdict: ReadyToGenerateVerdict.fail,
        reason: 'Missing approved decisions for: ${missing.join(', ')}.',
      );
    }
  }

  static ReadyCheck _checkShareTriggerReady(ShareTrigger? st, ClassificationSnapshot c) {
    if (st == null) {
      return ReadyCheck(
        id: 'ready.share_trigger',
        name: 'Share trigger is PASS',
        verdict: ReadyToGenerateVerdict.unknown,
        reason: 'No share trigger provided. The app never invents one.',
      );
    }
    if (st.verdict == GateVerdict.pass) {
      return ReadyCheck(
        id: 'ready.share_trigger',
        name: 'Share trigger is PASS',
        verdict: ReadyToGenerateVerdict.pass,
        reason: 'Share trigger is specific: ${st.sender} → ${st.recipient}.',
      );
    }
    if (st.verdict == GateVerdict.fail) {
      return ReadyCheck(
        id: 'ready.share_trigger',
        name: 'Share trigger is PASS',
        verdict: ReadyToGenerateVerdict.fail,
        reason: 'Share trigger is generic. Must name specific sender, recipient, situation, and reason.',
      );
    }
    return ReadyCheck(
      id: 'ready.share_trigger',
      name: 'Share trigger is PASS',
      verdict: ReadyToGenerateVerdict.unknown,
      reason: 'Share trigger not yet structured. Fill in sender, recipient, situation, reason.',
    );
  }

  static ReadyCheck _checkOpenLoopReady(OpenLoop? ol, ClassificationSnapshot c) {
    if (ol == null) {
      // Check if format needs open loop
      final formatName = c.narrativeFormatName;
      if (formatName != null && OpenLoop.formatNeedsOpenLoop(formatName)) {
        return ReadyCheck(
          id: 'ready.open_loop',
          name: 'Open loop is PASS or NOT_REQUIRED',
          verdict: ReadyToGenerateVerdict.unknown,
          reason: 'Format "$formatName" benefits from an open loop, but none was provided.',
        );
      } else {
        return ReadyCheck(
          id: 'ready.open_loop',
          name: 'Open loop is PASS or NOT_REQUIRED',
          verdict: ReadyToGenerateVerdict.pass,
          reason: 'Format does not require an open loop (or no format specified).',
        );
      }
    }
    final olVerdict = ol.verdict;
    if (olVerdict == OpenLoopVerdict.pass || olVerdict == OpenLoopVerdict.notRequired) {
      return ReadyCheck(
        id: 'ready.open_loop',
        name: 'Open loop is PASS or NOT_REQUIRED',
        verdict: ReadyToGenerateVerdict.pass,
        reason: olVerdict == OpenLoopVerdict.notRequired
            ? 'Format "${ol.formatName}" does not require an open loop.'
            : 'Open loop is specific: withheld="${ol.withheld}", mechanic="${ol.mechanic}".',
      );
    }
    if (olVerdict == OpenLoopVerdict.fail) {
      return ReadyCheck(
        id: 'ready.open_loop',
        name: 'Open loop is PASS or NOT_REQUIRED',
        verdict: ReadyToGenerateVerdict.fail,
        reason: 'Open loop is generic. Must name specific withheld element, promise, mechanic, and payoff.',
      );
    }
    return ReadyCheck(
      id: 'ready.open_loop',
      name: 'Open loop is PASS or NOT_REQUIRED',
      verdict: ReadyToGenerateVerdict.unknown,
      reason: 'Open loop not yet structured. Fill in withheld, promise, mechanic, payoff.',
    );
  }

  static ReadyCheck _checkVoiceModeReady(VoiceMode? vm, ClassificationSnapshot c) {
    if (vm != null) {
      return ReadyCheck(
        id: 'ready.voice_mode',
        name: 'Voice mode is declared',
        verdict: ReadyToGenerateVerdict.pass,
        reason: 'Voice mode: ${vm.label}.',
      );
    }
    // Can infer from format
    final fmt = c.narrativeFormatName != null
        ? validateNarrativeFormat(c.narrativeFormatName!)
        : null;
    final inferred = VoiceMode.infer(fmt, c.contentType);
    if (inferred != VoiceMode.optional) {
      // Inferrable with confidence
      return ReadyCheck(
        id: 'ready.voice_mode',
        name: 'Voice mode is declared',
        verdict: ReadyToGenerateVerdict.pass,
        reason: 'Voice mode inferred from format: ${inferred.label}.',
      );
    }
    return ReadyCheck(
      id: 'ready.voice_mode',
      name: 'Voice mode is declared',
      verdict: ReadyToGenerateVerdict.unknown,
      reason: 'No voice mode declared. Cannot infer from format; specify one.',
    );
  }

  static ReadyCheck _checkProductionMethodReady(ClassificationSnapshot c) {
    if (c.productionMethod != null) {
      final state = c.axisStates['productionMethod'];
      if (state == AxisResolution.approved) {
        return ReadyCheck(
          id: 'ready.production_method',
          name: 'Production method is resolved',
          verdict: ReadyToGenerateVerdict.pass,
          reason: 'Production method is ${c.productionMethod!.label} (approved).',
        );
      }
    }
    return ReadyCheck(
      id: 'ready.production_method',
      name: 'Production method is resolved',
      verdict: ReadyToGenerateVerdict.fail,
      reason: 'Production method is not approved in decisions.',
    );
  }

  static ReadyCheck _checkGoalReady(ClassificationSnapshot c) {
    if (c.goal != null) {
      final state = c.axisStates['goal'];
      if (state == AxisResolution.approved) {
        return ReadyCheck(
          id: 'ready.goal',
          name: 'Goal is resolved',
          verdict: ReadyToGenerateVerdict.pass,
          reason: 'Goal is ${c.goal!.label} (approved).',
        );
      }
    }
    return ReadyCheck(
      id: 'ready.goal',
      name: 'Goal is resolved',
      verdict: ReadyToGenerateVerdict.fail,
      reason: 'Goal is not approved in decisions.',
    );
  }

  static ReadyCheck _checkContentTypeReady(ClassificationSnapshot c) {
    if (c.contentType != null) {
      final state = c.axisStates['contentType'];
      if (state == AxisResolution.approved) {
        return ReadyCheck(
          id: 'ready.content_type',
          name: 'Content type is resolved',
          verdict: ReadyToGenerateVerdict.pass,
          reason: 'Content type is ${c.contentType!.label} (approved).',
        );
      }
    }
    return ReadyCheck(
      id: 'ready.content_type',
      name: 'Content type is resolved',
      verdict: ReadyToGenerateVerdict.fail,
      reason: 'Content type is not approved in decisions.',
    );
  }

  static ReadyCheck _checkNarrativeFormatReady(ClassificationSnapshot c) {
    if (c.narrativeFormatName != null) {
      final state = c.axisStates['narrativeFormat'];
      final fmt = validateNarrativeFormat(c.narrativeFormatName!);
      if (state == AxisResolution.approved && fmt != null) {
        return ReadyCheck(
          id: 'ready.narrative_format',
          name: 'Narrative format is resolved',
          verdict: ReadyToGenerateVerdict.pass,
          reason: 'Format is "${fmt.name}" (${fmt.id}) (approved).',
        );
      }
      if (state == AxisResolution.invalid) {
        return ReadyCheck(
          id: 'ready.narrative_format',
          name: 'Narrative format is resolved',
          verdict: ReadyToGenerateVerdict.fail,
          reason: 'Format is marked invalid — no narrative shape is derivable.',
        );
      }
      if (fmt == null) {
        return ReadyCheck(
          id: 'ready.narrative_format',
          name: 'Narrative format is resolved',
          verdict: ReadyToGenerateVerdict.fail,
          reason: '"${c.narrativeFormatName}" is not a registered format.',
        );
      }
    }
    return ReadyCheck(
      id: 'ready.narrative_format',
      name: 'Narrative format is resolved',
      verdict: ReadyToGenerateVerdict.fail,
      reason: 'Narrative format is not approved in decisions.',
    );
  }

  static ReadyCheck _checkSourceContentSufficient(ClassificationSnapshot c) {
    // Check if the idea has enough source content (topic, problem, lesson)
    // This is a proxy — in practice the idea object would have these fields
    // For now we check if classification has at least some axes resolved
    final resolvedCount = c.axisStates.values.where((s) => s == AxisResolution.approved).length;
    if (resolvedCount >= 5) {
      return ReadyCheck(
        id: 'ready.source_content',
        name: 'Source content is sufficient',
        verdict: ReadyToGenerateVerdict.pass,
        reason: '$resolvedCount/7 axes have approved decisions.',
      );
    }
    return ReadyCheck(
      id: 'ready.source_content',
      name: 'Source content is sufficient',
      verdict: ReadyToGenerateVerdict.unknown,
      reason: 'Only $resolvedCount/7 axes have approved decisions. May need more source detail.',
    );
  }

  static ReadyCheck _checkStatusReady(ClassificationSnapshot c, bool isArchived) {
    if (isArchived || c.status == IdeaStatus.archived) {
      return ReadyCheck(
        id: 'ready.status',
        name: 'Status is pre-generation',
        verdict: ReadyToGenerateVerdict.fail,
        reason: 'Idea is archived and cannot be generated.',
      );
    }
    // Accept idea, approved, scripted as pre-generation statuses
    const allowed = [IdeaStatus.idea, IdeaStatus.approved, IdeaStatus.scripted];
    if (allowed.contains(c.status)) {
      return ReadyCheck(
        id: 'ready.status',
        name: 'Status is pre-generation',
        verdict: ReadyToGenerateVerdict.pass,
        reason: 'Status is ${c.status.name} — appropriate for generation.',
      );
    }
    return ReadyCheck(
      id: 'ready.status',
      name: 'Status is pre-generation',
      verdict: ReadyToGenerateVerdict.unknown,
      reason: 'Status is ${c.status.name} — may not be ready for generation.',
    );
  }

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
    OpenLoop? openLoop,
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

    // Open loop — retention mechanic, only required for formats that benefit.
    // Formats that don't need open loops get NOT_REQUIRED (not a failure).
    if (openLoop != null) {
      final olVerdict = openLoop.verdict;
      results.add(GateCheckResult(
        id: 'creative.open_loop',
        name: 'Open loop is specific and retained',
        dimension: QualityDimension.creative,
        verdict: _mapOpenLoopVerdict(olVerdict),
        reason: olVerdict == OpenLoopVerdict.pass
            ? 'Withheld: ${openLoop.withheld}, mechanic: ${openLoop.mechanic}.'
            : olVerdict == OpenLoopVerdict.fail
                ? 'Open loop is generic. Name the specific withheld element, promise, and payoff.'
                : olVerdict == OpenLoopVerdict.notRequired
                    ? 'Format "${openLoop.formatName}" does not require an open loop.'
                    : 'Open loop not yet structured. Fill in withheld, promise, mechanic, payoff.',
      ));
    } else {
      // No open loop provided — check if format needs one.
      final formatName = c.narrativeFormatName;
      if (formatName != null && OpenLoop.formatNeedsOpenLoop(formatName)) {
        results.add(GateCheckResult(
          id: 'creative.open_loop',
          name: 'Open loop is specific and retained',
          dimension: QualityDimension.creative,
          verdict: GateVerdict.unknown,
          reason: 'Format "$formatName" benefits from an open loop, but none was provided.',
        ));
      } else {
        results.add(GateCheckResult(
          id: 'creative.open_loop',
          name: 'Open loop is specific and retained',
          dimension: QualityDimension.creative,
          verdict: GateVerdict.pass,
          reason: 'Format does not require an open loop (or no format specified).',
        ));
      }
    }

    return results;
  }

  /// Maps OpenLoopVerdict to GateVerdict for the gate report.
  /// NOT_REQUIRED becomes PASS (not a failure).
  static GateVerdict _mapOpenLoopVerdict(OpenLoopVerdict v) {
    switch (v) {
      case OpenLoopVerdict.pass:
        return GateVerdict.pass;
      case OpenLoopVerdict.fail:
        return GateVerdict.fail;
      case OpenLoopVerdict.unknown:
        return GateVerdict.unknown;
      case OpenLoopVerdict.notRequired:
        return GateVerdict.pass;
    }
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