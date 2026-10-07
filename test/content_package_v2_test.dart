import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_package_v2.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/format_handbook.dart';

void main() {
  group('ClassificationSnapshot', () {
    test('isFullyApproved returns true for fully approved snapshot', () {
      final snapshot = ClassificationSnapshot(
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': AxisResolution.approved,
          'narrativeFormat': AxisResolution.approved,
          'contentType': AxisResolution.approved,
          'productionMethod': AxisResolution.approved,
          'goal': AxisResolution.approved,
        },
        shareTrigger: ShareTrigger.filled(
          sender: 'test',
          recipient: 'test',
          situation: 'test',
          reason: 'test',
        ),
        openLoop: OpenLoop.filled(
          withheld: 'test',
          promise: 'test',
          mechanic: 'test',
          payoff: 'test',
          formatName: 'miniStory',
        ),
      );
      expect(snapshot.isFullyApproved, isTrue);
    });

    test('isFullyApproved returns false when an axis is OPEN', () {
      final snapshot = ClassificationSnapshot(
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': null,
          'narrativeFormat': AxisResolution.approved,
          'contentType': AxisResolution.approved,
          'productionMethod': AxisResolution.approved,
          'goal': AxisResolution.approved,
        },
      );
      expect(snapshot.isFullyApproved, isFalse);
      expect(snapshot.hasOpenAxes, isTrue);
    });

    test('hasBlockedAxes is true for needsReview axes', () {
      final snapshot = ClassificationSnapshot(
        axisStates: {
          'narrativeFormat': AxisResolution.needsReview,
        },
      );
      expect(snapshot.hasBlockedAxes, isTrue);
    });
  });

  group('ClassificationSnapshotV2', () {
    test('isFullyApproved is true when all axes are approved', () {
      final snapshot = ClassificationSnapshotV2(
        status: IdeaStatus.approved,
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': AxisResolution.approved,
          'narrativeFormat': AxisResolution.approved,
          'contentType': AxisResolution.approved,
          'productionMethod': AxisResolution.approved,
          'goal': AxisResolution.approved,
        },
        capturedAt: DateTime(2026, 1, 1),
      );
      expect(snapshot.isFullyApproved, isTrue);
      expect(snapshot.hasOpenAxes, isFalse);
    });

    test('isFullyApproved is false when an axis is OPEN (null)', () {
      final snapshot = ClassificationSnapshotV2(
        status: IdeaStatus.approved,
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': null,
        },
        capturedAt: DateTime(2026, 1, 1),
      );
      expect(snapshot.isFullyApproved, isFalse);
      expect(snapshot.hasOpenAxes, isTrue);
    });

    test('round-trips through JSON with OPEN axes', () {
      final snapshot = ClassificationSnapshotV2(
        pillar: ContentPillar.doIt,
        status: IdeaStatus.approved,
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': null,
        },
        capturedAt: DateTime(2026, 1, 1),
      );
      final json = snapshot.toJson();
      final restored = ClassificationSnapshotV2.fromJson(json);
      expect(restored.pillar, ContentPillar.doIt);
      expect(restored.axisStates['series'], isNull);
      expect(restored.hasOpenAxes, isTrue);
      expect(restored.isFullyApproved, isFalse);
    });
  });

  group('ContentPackageV2 gate integration', () {
    ClassificationSnapshot fullyApprovedSnapshot() {
      return ClassificationSnapshot(
        pillar: ContentPillar.doIt,
        series: ContentSeries.tryThisAtHome,
        narrativeFormatName: 'problemFix',
        contentType: ContentType.reel,
        productionMethod: ProductionMethod.characterImages,
        goal: ContentGoal.reach,
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

    test('fromGateReport creates a package with the gate report attached', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: fullyApprovedSnapshot(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parent of a toddler',
          recipient: 'Another parent',
          situation: 'Sock refusal at cleanup',
          reason: 'This is exactly our evening',
        ),
        voiceMode: VoiceMode.required,
        testCount: 5,
      );

      final pkg = ContentPackageV2Factory.fromGateReport(
        id: 'pkg-1',
        ideaId: 'day9-sock-hunt',
        report: report,
        hook: 'The Sock Hunt',
      );

      expect(pkg.gateReport, isNotNull);
      expect(pkg.gateReport!.ideaId, 'day9-sock-hunt');
      expect(pkg.canGenerate, isTrue);
      expect(pkg.isReadyToGenerate, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
      expect(pkg.needsFilming, isFalse);
    });

    test('a PASS package is ready and not blocked', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: fullyApprovedSnapshot(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parent',
          recipient: 'Friend',
          situation: 'Situation',
          reason: 'Reason',
        ),
        voiceMode: VoiceMode.required,
        testCount: 5,
      );

      final pkg = ContentPackageV2Factory.fromGateReport(
        id: 'pkg-1',
        ideaId: 'day9-sock-hunt',
        report: report,
      );

      expect(pkg.isReadyToGenerate, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
      expect(pkg.canGenerate, isTrue);
    });

    test('a BLOCKED package (invalid format) cannot generate', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'bad-format',
        title: 'Bad Format Idea',
        classification: ClassificationSnapshot(
          narrativeFormatName: 'notARealFormat',
          axisStates: {
            'narrativeFormat': AxisResolution.invalid,
          },
        ),
      );

      final pkg = ContentPackageV2Factory.fromGateReport(
        id: 'pkg-2',
        ideaId: 'bad-format',
        report: report,
      );

      expect(pkg.isBlockedByGate, isTrue);
      expect(pkg.canGenerate, isFalse);
      expect(pkg.isReadyToGenerate, isFalse);
      expect(pkg.blockingReasons, isNotEmpty);
    });

    test('a package with OPEN axes is UNKNOWN, not blocked', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'open-pillar',
        title: 'Missing Pillar',
        classification: ClassificationSnapshot(
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

      final pkg = ContentPackageV2Factory.fromGateReport(
        id: 'pkg-3',
        ideaId: 'open-pillar',
        report: report,
      );

      expect(pkg.isNotReady, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
      expect(pkg.canGenerate, isTrue);
      expect(pkg.isReadyToGenerate, isFalse);
    });

    test('a production-incompatible package can still generate (needsFilming)', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'film-this',
        title: 'Filming Required',
        classification: ClassificationSnapshot(
          narrativeFormatName: 'problemFix',
          contentType: ContentType.imageSlideshowReel,
          axisStates: {
            'contentType': AxisResolution.approved,
            'narrativeFormat': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'pillar': AxisResolution.approved,
            'series': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
        testCount: 5,
      );

      final pkg = ContentPackageV2Factory.fromGateReport(
        id: 'pkg-4',
        ideaId: 'film-this',
        report: report,
      );

      expect(pkg.needsFilming, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
      expect(pkg.canGenerate, isTrue);
      expect(pkg.isReadyToGenerate, isTrue);
      expect(pkg.isReadyAndProducible, isFalse);
    });

    test('missing gate report means not ready to generate', () {
      final pkg = ContentPackageV2(
        id: 'pkg-5',
        ideaId: 'no-gate',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        classification: ClassificationSnapshotV2(
          status: IdeaStatus.approved,
          axisStates: {},
          capturedAt: DateTime.now(),
        ),
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

      expect(pkg.isReadyToGenerate, isFalse);
      expect(pkg.canGenerate, isFalse);
      expect(pkg.isBlockedByGate, isFalse);
      expect(pkg.blockingReasons, isEmpty);
    });

    test('full package round-trips through JSON with gate report', () {
      final report = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: fullyApprovedSnapshot(),
        shareTrigger: ShareTrigger.filled(
          sender: 'Parent',
          recipient: 'Friend',
          situation: 'Sock refusal',
          reason: 'Same thing',
        ),
        voiceMode: VoiceMode.required,
        testCount: 5,
      );

      final pkg = ContentPackageV2Factory.fromGateReport(
        id: 'pkg-6',
        ideaId: 'day9-sock-hunt',
        report: report,
      );

      final json = pkg.toJson();
      final restored = ContentPackageV2.fromJson(json);

      expect(restored.id, 'pkg-6');
      expect(restored.ideaId, 'day9-sock-hunt');
      expect(restored.gateReport, isNotNull);
      expect(restored.gateReport!.ideaId, 'day9-sock-hunt');
      expect(restored.canGenerate, isTrue);
      expect(restored.isReadyToGenerate, isTrue);
    });
  });
}
