import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_generator.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/format_handbook.dart';

void main() {
  // ── Helpers ──────────────────────────────────────────────────────

  ClassificationSnapshot snapshot({
    ContentPillar? pillar,
    ContentSeries? series,
    String? narrativeFormatName,
    ContentType? contentType,
    ProductionMethod? productionMethod,
    ContentGoal? goal,
    IdeaStatus status = IdeaStatus.idea,
    Map<String, AxisResolution?>? axisStates,
  }) {
    return ClassificationSnapshot(
      pillar: pillar,
      series: series,
      narrativeFormatName: narrativeFormatName,
      contentType: contentType,
      productionMethod: productionMethod,
      goal: goal,
      status: status,
      axisStates: axisStates ?? {},
    );
  }

  ClassificationSnapshot fullyApproved({
    ContentPillar pillar = ContentPillar.doIt,
    ContentSeries series = ContentSeries.tryThisAtHome,
    String narrativeFormatName = 'problemFix',
    ContentType contentType = ContentType.reel,
    ProductionMethod productionMethod = ProductionMethod.characterImages,
    ContentGoal goal = ContentGoal.reach,
    IdeaStatus status = IdeaStatus.idea,
  }) {
    return snapshot(
      pillar: pillar,
      series: series,
      narrativeFormatName: narrativeFormatName,
      contentType: contentType,
      productionMethod: productionMethod,
      goal: goal,
      status: status,
      axisStates: {
        'pillar': AxisResolution.approved,
        'series': AxisResolution.approved,
        'narrativeFormat': AxisResolution.approved,
        'contentType': AxisResolution.approved,
        'productionMethod': AxisResolution.approved,
        'goal': AxisResolution.approved,
      },
    );
  }

  // ── ShareTrigger ─────────────────────────────────────────────────

  group('ShareTrigger', () {
    test('an empty trigger is UNKNOWN, not PASS', () {
      const trigger = ShareTrigger();
      expect(trigger.verdict, GateVerdict.unknown);
    });

    test('a fully populated specific trigger is PASS', () {
      final trigger = ShareTrigger.filled(
        sender: 'Parent of a 2-year-old',
        recipient: 'Another parent whose child refuses vegetables',
        situation: 'Child rejects vegetables without tasting them',
        reason: 'This is exactly what happens at our dinner table',
      );
      expect(trigger.verdict, GateVerdict.pass);
    });

    test('a generic trigger is FAIL, not PASS', () {
      final trigger = ShareTrigger.filled(
        sender: 'Parents',
        recipient: 'Parents',
        situation: 'Relatable',
        reason: 'Parents will share this',
      );
      expect(trigger.verdict, GateVerdict.fail);
    });

    test('a partially populated trigger is UNKNOWN', () {
      final trigger = ShareTrigger.filled(
        sender: 'Parent of a 2-year-old',
        recipient: 'Another parent',
        situation: 'Dinner battle',
        reason: '',
      );
      expect(trigger.verdict, GateVerdict.unknown);
    });

    test('round-trips through JSON', () {
      final trigger = ShareTrigger.filled(
        sender: 'Parent of a 2-year-old',
        recipient: 'Another parent',
        situation: 'Dinner battle',
        reason: 'Exact same thing at our table',
      );
      final restored = ShareTrigger.fromJson(trigger.toJson());
      expect(restored.verdict, GateVerdict.pass);
      expect(restored.sender, trigger.sender);
      expect(restored.recipient, trigger.recipient);
    });
  });

  // ── OpenLoop ───────────────────────────────────────────────────────

  group('OpenLoop', () {
    test('an empty open loop is UNKNOWN, not PASS', () {
      const loop = OpenLoop();
      expect(loop.verdict, OpenLoopVerdict.unknown);
    });

    test('a fully populated specific open loop is PASS for formats that need it', () {
      final loop = OpenLoop.filled(
        withheld: 'Why the toddler refuses the carrot',
        promise: 'The simple kitchen swap that changes everything',
        mechanic: 'reveal',
        payoff: 'Grated carrot in the pancake batter',
        formatName: 'problemFix',
      );
      expect(loop.verdict, OpenLoopVerdict.pass);
    });

    test('a generic open loop is FAIL, not PASS', () {
      final loop = OpenLoop.filled(
        withheld: 'the answer',
        promise: 'what happens next',
        mechanic: 'cliffhanger',
        payoff: 'watch to see',
        formatName: 'problemFix',
      );
      expect(loop.verdict, OpenLoopVerdict.fail);
    });

    test('a partially populated open loop is UNKNOWN', () {
      final loop = OpenLoop.filled(
        withheld: 'Why the toddler refuses',
        promise: 'The simple swap',
        mechanic: 'reveal',
        payoff: '',
        formatName: 'problemFix',
      );
      expect(loop.verdict, OpenLoopVerdict.unknown);
    });

    test('format that does not need open loop returns NOT_REQUIRED', () {
      final loop = OpenLoop.filled(
        withheld: 'Why',
        promise: 'The answer',
        mechanic: 'reveal',
        payoff: 'The reveal',
        formatName: 'saveThisList',
      );
      expect(loop.verdict, OpenLoopVerdict.notRequired);
    });

    test('format explicitly without open loop returns NOT_REQUIRED', () {
      final loop = OpenLoop.filled(
        withheld: 'Why',
        promise: 'The answer',
        mechanic: 'reveal',
        payoff: 'The reveal',
        formatName: 'pov',
      );
      expect(loop.verdict, OpenLoopVerdict.notRequired);
    });

    test('unknown format with open loop is UNKNOWN (conservative)', () {
      final loop = OpenLoop.filled(
        withheld: 'Why the toddler refuses',
        promise: 'The simple swap',
        mechanic: 'reveal',
        payoff: 'Grated carrot in batter',
        formatName: 'unknownFormat',
      );
      expect(loop.verdict, OpenLoopVerdict.unknown);
    });

    test('no format specified with open loop is UNKNOWN', () {
      final loop = OpenLoop.filled(
        withheld: 'Why the toddler refuses',
        promise: 'The simple swap',
        mechanic: 'reveal',
        payoff: 'Grated carrot in batter',
      );
      expect(loop.verdict, OpenLoopVerdict.unknown);
    });

    test('round-trips through JSON', () {
      final loop = OpenLoop.filled(
        withheld: 'Why the toddler refuses',
        promise: 'The simple swap',
        mechanic: 'reveal',
        payoff: 'Grated carrot in batter',
        formatName: 'problemFix',
      );
      final restored = OpenLoop.fromJson(loop.toJson());
      expect(restored.verdict, OpenLoopVerdict.pass);
      expect(restored.withheld, loop.withheld);
      expect(restored.mechanic, loop.mechanic);
    });

    test('formatNeedsOpenLoop recognizes problemFix', () {
      expect(OpenLoop.formatNeedsOpenLoop('problemFix'), isTrue);
      expect(OpenLoop.formatNeedsOpenLoop('miniStory'), isTrue);
      expect(OpenLoop.formatNeedsOpenLoop('thisOrThat'), isTrue);
    });

    test('formatDoesNotNeedOpenLoop recognizes saveThisList', () {
      expect(OpenLoop.formatDoesNotNeedOpenLoop('saveThisList'), isTrue);
      expect(OpenLoop.formatDoesNotNeedOpenLoop('pov'), isTrue);
      expect(OpenLoop.formatDoesNotNeedOpenLoop('numberedFramework'), isTrue);
    });
  });

  // ── VoiceMode ────────────────────────────────────────────────────

  group('VoiceMode', () {
    test('infers none for visual-first formats', () {
      expect(VoiceMode.infer(FormatLibrary.pov, ContentType.reel),
          VoiceMode.none);
      expect(VoiceMode.infer(FormatLibrary.quickTip, ContentType.reel),
          VoiceMode.none);
    });

    test('infers required for dialogue-heavy formats', () {
      expect(VoiceMode.infer(FormatLibrary.miniStory, ContentType.reel),
          VoiceMode.required);
      expect(
          VoiceMode.infer(FormatLibrary.expectationReality, ContentType.reel),
          VoiceMode.required);
    });

    test('infers optional for everything else', () {
      expect(VoiceMode.infer(FormatLibrary.problemFix, ContentType.reel),
          VoiceMode.optional);
    });

    test('a null format is optional, not a crash', () {
      expect(VoiceMode.infer(null, null), VoiceMode.optional);
    });
  });

  // ── SaveValue ────────────────────────────────────────────────────

  group('SaveValue', () {
    test('saves and authority goals are measurable', () {
      expect(QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(goal: ContentGoal.saves),
      ).saveValue, SaveValue.measurable);

      expect(QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(goal: ContentGoal.authority),
      ).saveValue, SaveValue.measurable);
    });

    test('reach and shares goals are N/A, not unknown', () {
      expect(QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(goal: ContentGoal.reach),
      ).saveValue, SaveValue.notApplicable);

      expect(QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(goal: ContentGoal.shares),
      ).saveValue, SaveValue.notApplicable);
    });
  });

  // ── ClassificationSnapshot ───────────────────────────────────────

  group('ClassificationSnapshot', () {
    test('isFullyApproved is true only when every axis is approved', () {
      final s = fullyApproved();
      expect(s.isFullyApproved, isTrue);
      expect(s.hasOpenAxes, isFalse);
      expect(s.hasBlockedAxes, isFalse);
    });

    test('a suggested value is not resolved', () {
      final s = fullyApproved();
      final withSuggestion = ClassificationSnapshot(
        pillar: s.pillar,
        series: s.series,
        narrativeFormatName: s.narrativeFormatName,
        contentType: s.contentType,
        productionMethod: s.productionMethod,
        goal: s.goal,
        axisStates: {
          'pillar': AxisResolution.suggested,
          'series': AxisResolution.approved,
          'narrativeFormat': AxisResolution.approved,
          'contentType': AxisResolution.approved,
          'productionMethod': AxisResolution.approved,
          'goal': AxisResolution.approved,
        },
      );
      expect(withSuggestion.isFullyApproved, isFalse);
    });

    test('hasOpenAxes is true when an axis has no state', () {
      final s = snapshot(
        pillar: ContentPillar.doIt,
        axisStates: {'pillar': AxisResolution.approved},
      );
      expect(s.hasOpenAxes, isTrue);
    });

    test('hasBlockedAxes is true for needsReview or invalid', () {
      final s = snapshot(
        pillar: ContentPillar.doIt,
        axisStates: {'pillar': AxisResolution.needsReview},
      );
      expect(s.hasBlockedAxes, isTrue);
    });

    test('round-trips through JSON', () {
      final s = fullyApproved();
      final restored =
          ClassificationSnapshot.fromJson(s.toJson());
      expect(restored.pillar, s.pillar);
      expect(restored.series, s.series);
      expect(restored.narrativeFormatName, s.narrativeFormatName);
      expect(restored.isFullyApproved, isTrue);
    });
  });

  // ── QualityGate.evaluateIdea ─────────────────────────────────────

  group('QualityGate.evaluateIdea', () {
    test('a fully approved idea with a specific share trigger passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'idea_100',
        title: 'The Sock Hunt',
        classification: fullyApproved(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parent of a toddler',
          recipient: 'Another parent with a toddler',
          situation: 'Clean laundry and no free time',
          reason: 'This is exactly our morning',
        ),
        testCount: 5,
      );
      expect(report.overall, GateVerdict.pass);
      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.needsFilming, isFalse);
    });

    test('an OPEN pillar produces UNKNOWN, not an inferred value', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: snapshot(
          pillar: null,
          series: ContentSeries.tryThisAtHome,
          narrativeFormatName: 'problemFix',
          contentType: ContentType.reel,
          productionMethod: ProductionMethod.characterImages,
          goal: ContentGoal.reach,
          axisStates: {
            'pillar': null,
            'series': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
      );
      final pillarCheck = report.checks
          .firstWhere((c) => c.id == 'strategy.pillar');
      expect(pillarCheck.verdict, GateVerdict.unknown);
      expect(pillarCheck.reason, contains('OPEN'));
    });

    test('a suggested pillar produces UNKNOWN, not PASS', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: snapshot(
          pillar: ContentPillar.doIt,
          series: ContentSeries.tryThisAtHome,
          narrativeFormatName: 'problemFix',
          contentType: ContentType.reel,
          productionMethod: ProductionMethod.characterImages,
          goal: ContentGoal.reach,
          axisStates: {
            'pillar': AxisResolution.suggested,
            'series': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
      );
      final pillarCheck = report.checks
          .firstWhere((c) => c.id == 'strategy.pillar');
      expect(pillarCheck.verdict, GateVerdict.unknown);
      expect(pillarCheck.reason, contains('suggested'));
    });

    test('an invalid narrative format FAILS the strategy gate', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: snapshot(
          pillar: ContentPillar.doIt,
          series: ContentSeries.tryThisAtHome,
          narrativeFormatName: 'notARealFormat',
          contentType: ContentType.reel,
          productionMethod: ProductionMethod.characterImages,
          goal: ContentGoal.reach,
          axisStates: {
            'pillar': AxisResolution.approved,
            'series': AxisResolution.approved,
            'narrativeFormat': AxisResolution.invalid,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
      );
      final fmtCheck = report.checks
          .firstWhere((c) => c.id == 'strategy.format');
      expect(fmtCheck.verdict, GateVerdict.fail);
      expect(report.isBlockedFromGeneration, isTrue);
    });

    test('an unregistered narrative format name FAILS', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(narrativeFormatName: 'madeUpFormat'),
      );
      final fmtCheck = report.checks
          .firstWhere((c) => c.id == 'strategy.format');
      expect(fmtCheck.verdict, GateVerdict.fail);
      expect(fmtCheck.reason, contains('not a registered format'));
    });

    test('an archive candidate FAILS the pillar check', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: snapshot(
          pillar: null,
          series: null,
          narrativeFormatName: 'thisOrThat',
          contentType: ContentType.staticImage,
          productionMethod: ProductionMethod.textBased,
          goal: ContentGoal.comments,
          axisStates: {
            'pillar': AxisResolution.archiveCandidate,
            'series': null,
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
      );
      final pillarCheck = report.checks
          .firstWhere((c) => c.id == 'strategy.pillar');
      expect(pillarCheck.verdict, GateVerdict.fail);
      expect(pillarCheck.reason, contains('archive candidate'));
    });

    test('an unimplemented content type FAILS production but does not block',
        () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.story,
        ),
      );
      final ctCheck = report.checks
          .firstWhere((c) => c.id == 'production.content_type_implemented');
      expect(ctCheck.verdict, GateVerdict.fail);
      // Production failures do NOT block generation — they are filming jobs.
      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.needsFilming, isTrue);
    });

    test('an unimplemented production method FAILS production but does not block',
        () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          productionMethod: ProductionMethod.mixed,
        ),
      );
      final pmCheck = report.checks
          .firstWhere((c) => c.id == 'production.method_implemented');
      expect(pmCheck.verdict, GateVerdict.fail);
      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.needsFilming, isTrue);
    });

    test('a missing share trigger is UNKNOWN, not PASS', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
      );
      final stCheck = report.checks
          .firstWhere((c) => c.id == 'creative.share_trigger');
      expect(stCheck.verdict, GateVerdict.unknown);
      expect(stCheck.reason, contains('never invents'));
    });

    test('a generic share trigger FAILS the creative gate', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parents',
          recipient: 'Parents',
          situation: 'Relatable',
          reason: 'Parents will share this',
        ),
      );
      final stCheck = report.checks
          .firstWhere((c) => c.id == 'creative.share_trigger');
      expect(stCheck.verdict, GateVerdict.fail);
      expect(report.isBlockedFromGeneration, isTrue);
    });

    test('an open loop missing for a format that needs it is UNKNOWN', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(narrativeFormatName: 'problemFix'),
      );
      final olCheck = report.checks
          .firstWhere((c) => c.id == 'creative.open_loop');
      expect(olCheck.verdict, GateVerdict.unknown);
      expect(olCheck.reason, contains('benefits from an open loop'));
    });

    test('an open loop provided for a format that needs it is PASS', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(narrativeFormatName: 'problemFix'),
        openLoop: OpenLoop.filled(
          withheld: 'Why the toddler refuses the carrot',
          promise: 'The simple kitchen swap that changes everything',
          mechanic: 'reveal',
          payoff: 'Grated carrot in the pancake batter',
          formatName: 'problemFix',
        ),
      );
      final olCheck = report.checks
          .firstWhere((c) => c.id == 'creative.open_loop');
      expect(olCheck.verdict, GateVerdict.pass);
      expect(report.isBlockedFromGeneration, isFalse);
    });

    test('a generic open loop FAILS the creative gate', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(narrativeFormatName: 'problemFix'),
        openLoop: OpenLoop.filled(
          withheld: 'the answer',
          promise: 'what happens next',
          mechanic: 'cliffhanger',
          payoff: 'watch to see',
          formatName: 'problemFix',
        ),
      );
      final olCheck = report.checks
          .firstWhere((c) => c.id == 'creative.open_loop');
      expect(olCheck.verdict, GateVerdict.fail);
      expect(report.isBlockedFromGeneration, isTrue);
    });

    test('a format that does not need open loop gets PASS automatically', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(narrativeFormatName: 'saveThisList'),
      );
      final olCheck = report.checks
          .firstWhere((c) => c.id == 'creative.open_loop');
      expect(olCheck.verdict, GateVerdict.pass);
      expect(olCheck.reason, contains('does not require'));
    });

    test('an explicitly provided open loop for a format that does not need it is PASS', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(narrativeFormatName: 'pov'),
        openLoop: OpenLoop.filled(
          withheld: 'Why',
          promise: 'The answer',
          mechanic: 'reveal',
          payoff: 'The reveal',
          formatName: 'pov',
        ),
      );
      final olCheck = report.checks
          .firstWhere((c) => c.id == 'creative.open_loop');
      expect(olCheck.verdict, GateVerdict.pass);
      expect(olCheck.reason, contains('does not require'));
    });

    test('the five-test rule produces UNKNOWN below five tests', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
        testCount: 1,
      );
      final tcCheck = report.checks
          .firstWhere((c) => c.id == 'performance.test_count');
      expect(tcCheck.verdict, GateVerdict.unknown);
      expect(tcCheck.reason, contains('1/5'));
      expect(tcCheck.reason, contains('4 more tests'));
      expect(report.overall, GateVerdict.unknown);
    });

    test('the five-test rule produces PASS at five tests', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
        testCount: 5,
      );
      final tcCheck = report.checks
          .firstWhere((c) => c.id == 'performance.test_count');
      expect(tcCheck.verdict, GateVerdict.pass);
      expect(tcCheck.reason, contains('5/5'));
    });

    test('an archived idea is flagged', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(status: IdeaStatus.archived),
        isArchived: true,
      );
      expect(report.isArchived, isTrue);
    });

    test('a blocked idea is flagged', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
        isBlocked: true,
      );
      expect(report.isBlocked, isTrue);
    });

    test('blocked ideas are reported with blocking reasons', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parents',
          recipient: 'Parents',
          situation: 'Relatable',
          reason: 'Parents will share this',
        ),
      );
      expect(report.blockingReasons, isNotEmpty);
      expect(report.blockingReasons.first, contains('Share trigger'));
    });

    test('the report round-trips through JSON', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'idea_100',
        title: 'The Sock Hunt',
        classification: fullyApproved(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parent of a toddler',
          recipient: 'Another parent',
          situation: 'Clean laundry',
          reason: 'Exactly our morning',
        ),
        testCount: 5,
      );
      final restored = GateReport.fromJson(report.toJson());
      expect(restored.ideaId, report.ideaId);
      expect(restored.overall, report.overall);
      expect(restored.classification.pillar, report.classification.pillar);
      expect(restored.shareTrigger?.verdict, GateVerdict.pass);
      expect(restored.checks.length, report.checks.length);
    });
  });

  // ── QualityGate.evaluatePackage ──────────────────────────────────

   group('QualityGate.evaluatePackage', () {
    test('evaluates a package with production and performance checks', () {
      final report = QualityGate.evaluatePackage(
        'test idea',
        'test hook',
        classification: fullyApproved(),
        testCount: 5,
      );
      expect(report.ideaId, 'test idea');
      expect(report.checks, isNotEmpty);
      // Production checks should pass for a fully approved classification.
      expect(report.productionPass, isTrue);
      expect(report.performancePass, isTrue);
    });
  });

  // ── Design invariants ────────────────────────────────────────────

  group('design invariants', () {
    test('production failures never block generation', () {
      // An idea that needs real-life video is a filming job, not a bad idea.
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          productionMethod: ProductionMethod.realLifeVideo,
        ),
      );
      // Real-life video IS implemented, so this passes. But the invariant
      // is that even when production fails, it does not block.
      expect(report.isBlockedFromGeneration, isFalse);
    });

    test('strategy and creative failures block generation', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parents',
          recipient: 'Parents',
          situation: 'Relatable',
          reason: 'Parents will share this',
        ),
      );
      expect(report.isBlockedFromGeneration, isTrue);
    });

    test('every check carries a dimension', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
      );
      for (final c in report.checks) {
        expect(c.dimension, isNotNull);
        expect(c.verdict, isNotNull);
      }
    });

    test('the four dimensions are all represented', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(),
      );
      final dimensions = report.checks.map((c) => c.dimension).toSet();
      for (final dim in QualityDimension.values) {
        expect(dimensions.contains(dim), isTrue,
            reason: 'missing checks for ${dim.name}');
      }
    });
  });

  // ── Reel Quality Gate Checks ─────────────────────────────────────

  group('Reel quality gate checks', () {
    test('hook clarity: specific hook with short scene passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          hook: 'Toddler refuses carrots because of texture — here\'s the '
              'one swap that works',
          firstSceneDurationSeconds: 2,
          voiceMode: VoiceMode.none,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.pass);
    });

    test('hook clarity: generic hook fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          hook: 'You won\'t believe what happens next',
          firstSceneDurationSeconds: 2,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.fail);
    });

    test('hook clarity: no hook data returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.unknown);
      expect(hookCheck.reason, contains('No hook text'));
    });

    test('hook clarity: non-Reel returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.carousel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          hook: 'Some hook',
          firstSceneDurationSeconds: 2,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.unknown);
      expect(hookCheck.reason, contains('Not a Reel'));
    });

    test('hook clarity: generic hook but first scene > 3s fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          hook: 'Here\'s the thing about parenting',
          firstSceneDurationSeconds: 5,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.fail);
      expect(hookCheck.reason, contains('Here\'s the thing'));
    });

    test('hook clarity: specific hook with scene > 3s fails on duration', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          hook: 'Swap almond butter for peanut butter to avoid nut allergies',
          firstSceneDurationSeconds: 6,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.fail);
      expect(hookCheck.reason, contains('6s'));
    });

    test('sound-off: voiceMode none with overlay text passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          voiceMode: VoiceMode.none,
          sceneOverlayTexts: ['Tip: Use the back of a spoon'],
          caption: 'Full caption explaining the technique',
        ),
      );
      final soundOffCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.sound_off_readability');
      expect(soundOffCheck.verdict, GateVerdict.pass);
    });

    test('sound-off: voiceMode none without text fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          voiceMode: VoiceMode.none,
          hook: 'Some hook',
        ),
      );
      final soundOffCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.sound_off_readability');
      expect(soundOffCheck.verdict, GateVerdict.fail);
      expect(soundOffCheck.reason, contains('no overlay text or caption'));
    });

    test('sound-off: voiceMode optional without text is unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          voiceMode: VoiceMode.optional,
          hook: 'Some hook',
        ),
      );
      final soundOffCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.sound_off_readability');
      expect(soundOffCheck.verdict, GateVerdict.unknown);
    });

    test('sound-off: voiceMode required passes (voice-dependent)', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          voiceMode: VoiceMode.required,
          hook: 'Some hook',
        ),
      );
      final soundOffCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.sound_off_readability');
      expect(soundOffCheck.verdict, GateVerdict.pass);
      expect(soundOffCheck.reason, contains('not applicable'));
    });

    test('sound-off: voiceMode optional with caption passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          voiceMode: VoiceMode.optional,
          caption: 'Caption explaining everything',
        ),
      );
      final soundOffCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.sound_off_readability');
      expect(soundOffCheck.verdict, GateVerdict.pass);
    });

    test('character consistency: correct names pass', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria tries to put on her shoes. Rio helps her. '
              'Cuty watches quietly.',
        ),
      );
      final charCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.character_consistency');
      expect(charCheck.verdict, GateVerdict.pass);
      expect(charCheck.reason, contains('Ria'));
      expect(charCheck.reason, contains('Rio'));
      expect(charCheck.reason, contains('Cuty'));
    });

    test('character consistency: misspelling fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Riaa tries to put on her shoes. Rio helps her.',
        ),
      );
      final charCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.character_consistency');
      expect(charCheck.verdict, GateVerdict.fail);
      expect(charCheck.reason, contains('Riaa'));
    });

    test('character consistency: generic reference fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'The girl tries to put on her shoes. The boy helps her.',
        ),
      );
      final charCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.character_consistency');
      expect(charCheck.verdict, GateVerdict.fail);
    });

    test('character consistency: no character text returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
        ),
      );
      final charCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.character_consistency');
      expect(charCheck.verdict, GateVerdict.unknown);
      expect(charCheck.reason, contains('No script'));
    });

    test('character consistency: non-Reel returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.carousel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria does something',
        ),
      );
      final charCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.character_consistency');
      expect(charCheck.verdict, GateVerdict.unknown);
      expect(charCheck.reason, contains('Not a Reel'));
    });

    test('evaluatePackage with ReelCheckData runs reel checks', () {
      final report = QualityGate.evaluatePackage(
        'test', 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          hook: 'Specific and clear hook about toddler tantrums',
          firstSceneDurationSeconds: 2,
          voiceMode: VoiceMode.none,
          sceneOverlayTexts: ['Overlay tip text'],
          script: 'Ria has a tantrum. Rio comforts her. Cuty nuzzles.',
        ),
      );
       final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.pass);
    });

test('evaluatePackage without ReelCheckData skips reel checks gracefully', () {
      final report = QualityGate.evaluatePackage(
        'test', 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
      );
      final hookCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.hook_clarity');
      expect(hookCheck.verdict, GateVerdict.unknown);
    });

    // ── Banned Phrases Check ──────────────────────────────────────

    test('banned phrases: AI fingerprint phrase fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Sharing is caring and that is the magic of childhood.',
          narration: 'A beautiful bond forms.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.fail);
      expect(bannedCheck.reason, contains('sharing is caring'));
      expect(bannedCheck.reason, contains('the magic of'));
    });

    test('banned phrases: no banned phrases passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria grabs the red car. Rio screams. Mumma counts to five.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass);
    });

    test('banned phrases: non-Reel returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.carousel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Sharing is caring.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.unknown);
      expect(bannedCheck.reason, contains('Not a Reel'));
    });

    test('banned phrases: case-insensitive matching detects uppercase', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'SHARING IS CARING — this is the magic of childhood.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.fail);
    });

    test('banned phrases: normal Hinglish dialogue passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria kehta hai: "Mujhe neend nahi!" Mumma gently tucks her in.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass);
    });

    test('known bad tokens: detects typos', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria plays with wieder toys all day.',
        ),
      );
      final tokenCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_tokens', orElse: () {
        return GateCheckResult(
          id: 'not_found',
          name: 'not_found',
          dimension: QualityDimension.creative,
          verdict: GateVerdict.fail,
          reason: 'banned_tokens check not found',
        );
      });
      expect(tokenCheck.verdict, GateVerdict.fail);
      expect(tokenCheck.reason, contains('wieder'));
    });

    test('known bad tokens: normal text passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria and Rio play with their toys.',
        ),
      );
      // No banned tokens found — the pass result uses the phrases check ID
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass);
    });

    // ── Feelings in Dialogue Check ────────────────────────────────

    test('feelings in dialogue: explicit naming fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          dialogue: 'Ria: "I feel sad because Rio took my car."',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.fail);
      expect(feelingsCheck.reason, contains('i feel sad'));
    });

    test('feelings in dialogue: I am angry fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          dialogue: 'Rio: "I am angry! Give it back!"',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.fail);
      expect(feelingsCheck.reason, contains('i am angry'));
    });

    test('feelings in dialogue: I\'m frustrated fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          dialogue: 'Ria: "I\'m frustrated with this puzzle."',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.fail);
      expect(feelingsCheck.reason, contains("i'm frustrated"));
    });

    test('feelings in dialogue: third person naming fails', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          dialogue: 'Mumma: "He feels jealous of his brother."',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.fail);
      expect(feelingsCheck.reason, contains('he feels jealous'));
    });

    test('feelings in dialogue: no explicit naming passes', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          dialogue: 'Ria: "Mumma, bas ek aur chips!" Rio: "Mera car. Abhi."',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.pass);
    });

    test('feelings in dialogue: non-Reel returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.carousel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          dialogue: 'I feel sad.',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.unknown);
      expect(feelingsCheck.reason, contains('Not a Reel'));
    });

    test('feelings in dialogue: no dialogue returns unknown', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Ria grabs the car.',
        ),
      );
      final feelingsCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.feelings_in_dialogue');
      expect(feelingsCheck.verdict, GateVerdict.unknown);
      expect(feelingsCheck.reason, contains('No dialogue'));
    });

    // ── Banned Phrases Word Boundaries (False Positives) ─────────────

    test('banned phrases: word boundaries prevent false positive "accomplished" in "unaccomplished"', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'The task was unaccomplished and frustrating.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass,
          reason: 'Should not match "accomplished" inside "unaccomplished"');
    });

    test('banned phrases: word boundaries prevent false positive "sharing" in "unsharing"', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'The child was unsharing about the toys.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass,
          reason: 'Should not match "sharing" inside "unsharing"');
    });

    test('banned phrases: word boundaries prevent false positive "caring" in "uncaring"', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'That was an uncaring remark from the sibling.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass,
          reason: 'Should not match "caring" inside "uncaring"');
    });

    test('banned phrases: "mission complete" word boundary works', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'The mission completed successfully.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.pass,
          reason: 'Should not match "completed" as "mission complete"');
    });

    test('banned phrases: exact phrase with punctuation still matches', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'test',
        title: 'test',
        classification: fullyApproved(
          contentType: ContentType.reel,
        ),
        reelData: ReelCheckData(
          isReel: true,
          script: 'Sharing is caring! That is the magic of parenting.',
        ),
      );
      final bannedCheck = report.checks
          .firstWhere((c) => c.id == 'creative.reel.banned_phrases');
      expect(bannedCheck.verdict, GateVerdict.fail);
      expect(bannedCheck.reason, contains('sharing is caring'));
      expect(bannedCheck.reason, contains('the magic of'));
    });
  });
}
