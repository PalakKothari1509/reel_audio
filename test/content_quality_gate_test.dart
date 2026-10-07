import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/format_handbook.dart';

void main() {
  group('ShareTrigger', () {
    test('empty trigger verdicts UNKNOWN', () {
      const t = ShareTrigger();
      expect(t.verdict, GateVerdict.unknown);
      expect(t.senderKnown, isFalse);
      expect(t.recipientKnown, isFalse);
      expect(t.situationKnown, isFalse);
      expect(t.reasonKnown, isFalse);
    });

    test('fully populated trigger with specific text verdicts PASS', () {
      final t = ShareTrigger(
        sender: 'Parent of a 2-4 year old',
        recipient: 'Another parent whose toddler refuses vegetables',
        situation: 'Child rejects vegetables without even tasting them',
        reason: 'This is exactly what happens at our dinner table',
        senderKnown: true,
        recipientKnown: true,
        situationKnown: true,
        reasonKnown: true,
      );
      expect(t.verdict, GateVerdict.pass);
    });

    test('fully populated but generic trigger verdicts FAIL', () {
      final t = ShareTrigger(
        sender: 'parents',
        recipient: 'moms',
        situation: 'toddler behaviour',
        reason: 'this is relatable',
        senderKnown: true,
        recipientKnown: true,
        situationKnown: true,
        reasonKnown: true,
      );
      expect(t.verdict, GateVerdict.fail);
      expect(t.senderKnown, isTrue);
    });

    test('partial trigger verdicts UNKNOWN', () {
      const t = ShareTrigger(
        sender: 'Parent of a 2-4 year old',
        recipientKnown: false,
        situationKnown: false,
        reasonKnown: false,
      );
      expect(t.verdict, GateVerdict.unknown);
    });

    test('serialization round-trips', () {
      final t = ShareTrigger(
        sender: 'Parent',
        recipient: 'Friend',
        situation: 'Bedtime refusal',
        reason: 'Same thing happens here',
        senderKnown: true,
        recipientKnown: true,
        situationKnown: true,
        reasonKnown: true,
      );
      final json = t.toJson();
      final restored = ShareTrigger.fromJson(json);
      expect(restored.verdict, GateVerdict.pass);
      expect(restored.sender, 'Parent');
      expect(restored.reason, 'Same thing happens here');
    });
  });

  group('VoiceMode', () {
    test('none for visual-first formats', () {
      expect(VoiceMode.infer(FormatLibrary.pov, ContentType.reel), VoiceMode.none);
      expect(VoiceMode.infer(FormatLibrary.quickTip, ContentType.trialReel),
          VoiceMode.none);
      expect(VoiceMode.infer(FormatLibrary.doThisNotThat, ContentType.carousel),
          VoiceMode.none);
    });

    test('required for dialogue-dependent formats', () {
      expect(VoiceMode.infer(FormatLibrary.miniStory, ContentType.reel),
          VoiceMode.required);
      expect(
          VoiceMode.infer(FormatLibrary.expectationReality, ContentType.trialReel),
          VoiceMode.required);
    });

    test('optional for mixed formats', () {
      expect(VoiceMode.infer(FormatLibrary.questionAnswer, ContentType.carousel),
          VoiceMode.optional);
    });

    test('optional when format is null', () {
      expect(VoiceMode.infer(null, ContentType.reel), VoiceMode.optional);
    });
  });

  group('SaveValue', () {
    test('inferred from goal', () {
      expect(QualityGate.inferSaveValue(ContentGoal.saves),
          SaveValue.measurable);
      expect(QualityGate.inferSaveValue(ContentGoal.authority),
          SaveValue.measurable);
      expect(QualityGate.inferSaveValue(ContentGoal.reach),
          SaveValue.notApplicable);
      expect(QualityGate.inferSaveValue(ContentGoal.shares),
          SaveValue.notApplicable);
    });
  });

  group('ClassificationSnapshot', () {
    test('OPEN axis produces unknown, not a guess', () {
      const snapshot = ClassificationSnapshot(
        axisStates: {
          'pillar': null,
          'series': null,
          'narrativeFormat': null,
          'contentType': null,
          'productionMethod': null,
          'goal': null,
        },
      );
      expect(snapshot.hasOpenAxes, isTrue);
      expect(snapshot.isFullyApproved, isFalse);
    });

    test('approved axis is resolved', () {
      const snapshot = ClassificationSnapshot(
        pillar: ContentPillar.doIt,
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': null,
        },
      );
      expect(snapshot.isFullyApproved, isFalse);
      expect(snapshot.hasOpenAxes, isTrue);
    });

    test('suggested is not resolved', () {
      const snapshot = ClassificationSnapshot(
        pillar: ContentPillar.doIt,
        axisStates: {
          'pillar': AxisResolution.suggested,
        },
      );
      expect(snapshot.isFullyApproved, isFalse);
      expect(snapshot.hasOpenAxes, isFalse);
    });

    test('serialization round-trips', () {
      const snapshot = ClassificationSnapshot(
        pillar: ContentPillar.doIt,
        series: ContentSeries.jugaaduMummy,
        narrativeFormatName: 'problemFix',
        contentType: ContentType.reel,
        productionMethod: ProductionMethod.characterImages,
        goal: ContentGoal.reach,
        status: IdeaStatus.approved,
        axisStates: {
          'pillar': AxisResolution.approved,
          'narrativeFormat': AxisResolution.approved,
        },
      );
      final json = snapshot.toJson();
      final restored = ClassificationSnapshot.fromJson(json);
      expect(restored.pillar, ContentPillar.doIt);
      expect(restored.series, ContentSeries.jugaaduMummy);
      expect(restored.contentType, ContentType.reel);
      expect(restored.productionMethod, ProductionMethod.characterImages);
      expect(restored.goal, ContentGoal.reach);
      expect(restored.status, IdeaStatus.approved);
    });
  });

  group('QualityGate', () {
    test('an idea with all axes approved and no share trigger is UNKNOWN, not BLOCKED', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: const ClassificationSnapshot(
          pillar: ContentPillar.doIt,
          series: ContentSeries.tryThisAtHome,
          narrativeFormatName: 'problemFix',
          contentType: ContentType.reel,
          productionMethod: ProductionMethod.characterImages,
          goal: ContentGoal.reach,
          status: IdeaStatus.idea,
          axisStates: {
            'pillar': AxisResolution.approved,
            'series': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
      );

      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.creativePass, isFalse);
      expect(report.overall, GateVerdict.unknown);
      expect(report.isArchived, isFalse);
      expect(report.needsFilming, isFalse);
    });

    test('an idea with all axes approved and a valid share trigger is READY', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: const ClassificationSnapshot(
          pillar: ContentPillar.doIt,
          series: ContentSeries.tryThisAtHome,
          narrativeFormatName: 'problemFix',
          contentType: ContentType.reel,
          productionMethod: ProductionMethod.characterImages,
          goal: ContentGoal.reach,
          status: IdeaStatus.idea,
          axisStates: {
            'pillar': AxisResolution.approved,
            'series': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
        shareTrigger: const ShareTrigger(
          sender: 'Parent of a 2-4 year old',
          recipient: 'Another parent whose toddler refuses vegetables',
          situation: 'Child rejects vegetables without even tasting them',
          reason: 'This is exactly what happens at our dinner table',
        ),
        voiceMode: VoiceMode.required,
      );

      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.creativePass, isTrue);
      expect(report.strategyPass, isTrue);
      expect(report.overall, GateVerdict.pass);
    });

    test('an idea with OPEN pillar is UNKNOWN, not BLOCKED', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day5-ask-tonight',
        title: 'Ask Your Child This Tonight',
        classification: const ClassificationSnapshot(
          axisStates: {
            'pillar': null,
            'series': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
          series: ContentSeries.lifeWithRiaRio,
          narrativeFormatName: 'questionAnswer',
          contentType: ContentType.carousel,
          productionMethod: ProductionMethod.carousel,
          goal: ContentGoal.saves,
        ),
      );

      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.overall, GateVerdict.unknown);
    });

    test('an invalid narrative format is BLOCKED', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'lp-kitchen-counting',
        title: 'Kitchen Counting Game',
        classification: const ClassificationSnapshot(
          narrativeFormatName: 'notARealFormat',
          axisStates: {
            'narrativeFormat': AxisResolution.invalid,
          },
        ),
      );

      expect(report.isBlockedFromGeneration, isTrue);
      expect(report.overall, GateVerdict.fail);
    });

    test('a production-incompatible content type is NOT blocked, just needsFilming', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'st-rio-bored-2-min',
        title: 'Rio Gets Bored After Two Minutes',
        classification: const ClassificationSnapshot(
          contentType: ContentType.imageSlideshowReel,
          axisStates: {
            'contentType': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'pillor': AxisResolution.approved,
          },
        ),
      );

      expect(report.isBlockedFromGeneration, isFalse);
      expect(report.needsFilming, isTrue);
    });

    test('the five-test rule is enforced as UNKNOWN, not PASS, when under-tested', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'quick-tip-test',
        title: 'A Quick Tip',
        classification: const ClassificationSnapshot(
          narrativeFormatName: 'quickTip',
          axisStates: {
            'narrativeFormat': AxisResolution.approved,
          },
        ),
        testCount: 1,
      );

      final perf = report.checksFor(QualityDimension.performance);
      expect(perf, isNotEmpty);
      expect(perf.first.verdict, GateVerdict.unknown);
      expect(perf.first.reason, contains('1/5'));
    });

    test('the five-test rule permits PASS at 5 tests', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'quick-tip-test',
        title: 'A Quick Tip',
        classification: const ClassificationSnapshot(
          narrativeFormatName: 'quickTip',
          axisStates: {
            'narrativeFormat': AxisResolution.approved,
          },
        ),
        testCount: 5,
      );

      final perf = report.checksFor(QualityDimension.performance);
      expect(perf.first.verdict, GateVerdict.pass);
    });

    test('saveValue N/A for reach goals', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: const ClassificationSnapshot(
          goal: ContentGoal.reach,
        ),
      );

      expect(report.saveValue, SaveValue.notApplicable);
    });

    test('saveValue measurable for save goals', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day2-which-doesnt-belong',
        title: 'Which One Doesn\'t Belong?',
        classification: const ClassificationSnapshot(
          goal: ContentGoal.saves,
        ),
      );

      expect(report.saveValue, SaveValue.measurable);
    });

    test('archive candidate is flagged and blocked', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day14-favorite-format',
        title: 'Which New Format Was Your Favorite?',
        classification: const ClassificationSnapshot(
          axisStates: {
            'pillar': AxisResolution.archiveCandidate,
          },
        ),
      );

      expect(report.isArchived, isTrue);
      expect(report.isBlockedFromGeneration, isTrue);
    });
  });

  group('GateReport serialization', () {
    test('round-trips through JSON', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: const ClassificationSnapshot(
          pillar: ContentPillar.doIt,
          series: ContentSeries.tryThisAtHome,
          narrativeFormatName: 'problemFix',
          contentType: ContentType.reel,
          productionMethod: ProductionMethod.characterImages,
          goal: ContentGoal.reach,
          axisStates: {
            'pillar': AxisResolution.approved,
          },
        ),
        shareTrigger: const ShareTrigger(
          sender: 'Parent',
          recipient: 'Friend',
          situation: 'Sock refusal',
          reason: 'Same thing happens',
        ),
        voiceMode: VoiceMode.required,
        testCount: 5,
      );

      final json = report.toJson();
      final restored = GateReport.fromJson(json);

      expect(restored.ideaId, 'day9-sock-hunt');
      expect(restored.title, 'The Sock Hunt');
      expect(restored.voiceMode, VoiceMode.required);
      expect(restored.saveValue, SaveValue.notApplicable);
      expect(restored.shareTrigger!.sender, 'Parent');
      expect(restored.checks.length, report.checks.length);
    });
  });
}
